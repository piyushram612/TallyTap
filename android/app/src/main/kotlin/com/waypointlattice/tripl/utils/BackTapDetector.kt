package com.waypointlattice.tripl.utils

import android.util.Log
import com.waypointlattice.tripl.MainActivity

class BackTapDetector(private val onTripleTapTriggered: (recommendedForce: Float, recommendedJerk: Float) -> Unit) {
    private var lastTapTime = 0L
    private var tapCount = 0
    private var lastLinearZ = 0f
    private var isQuietBetweenTaps = true
    private var quietSamplesCount = 0
    
    // Calibration tracking arrays
    private val calibForces = FloatArray(3)
    private val calibJerks = FloatArray(3)
    
    // Gravity low-pass filter
    private val gravity = FloatArray(3)
    private var isGravityInitialized = false

    // Configurable thresholds (mutable, updated live or loaded from prefs)
    var tapThreshold = 2.5f
    var jerkThreshold = 2.0f
    
    private val debounceWindowMs = 80L
    private val tapWindowMinMs = 100L
    var tapWindowMaxMs = 400L // Configurable via sensitivity slider

    // ── Upgraded tracking variables ──
    private var lastTimestamp = 0L
    private var cooldownLockoutTime = 0L
    private var lastNegativeSpikeTime = 0L
    private var runningNoise = 0f
    private val spikeHistory = mutableListOf<Long>()

    fun processSensorEvent(xValue: Float, yValue: Float, zValue: Float) {
        val currentTime = System.currentTimeMillis()

        // ── Step 0: Cooldown Gating ──
        if (currentTime < cooldownLockoutTime) {
            return
        }

        // Initialize lastTimestamp if 0
        if (lastTimestamp == 0L) {
            lastTimestamp = currentTime
        }
        val dt = (currentTime - lastTimestamp) / 1000f
        lastTimestamp = currentTime
        if (dt <= 0f) return

        // ── Step 1: Time-Invariant Gravity Separation & Orientation Gating ──
        // Time constant of 0.1s (100ms)
        val timeConstant = 0.1f
        val alpha = timeConstant / (timeConstant + dt)

        if (!isGravityInitialized) {
            gravity[0] = xValue
            gravity[1] = yValue
            gravity[2] = zValue
            isGravityInitialized = true
        } else {
            gravity[0] = alpha * gravity[0] + (1 - alpha) * xValue
            gravity[1] = alpha * gravity[1] + (1 - alpha) * yValue
            gravity[2] = alpha * gravity[2] + (1 - alpha) * zValue
        }

        // Physics-based landscape check: gravity X vs Y
        val isCalib = MainActivity.calibrationMode
        val isLandscape = Math.abs(gravity[0]) > Math.abs(gravity[1])
        if (isLandscape && !isCalib) {
            return
        }

        // Linear acceleration (high-pass filter to remove gravity)
        val linearX = xValue - gravity[0]
        val linearY = yValue - gravity[1]
        val linearZ = zValue - gravity[2]

        val absZ = Math.abs(linearZ)
        val absX = Math.abs(linearX)
        val absY = Math.abs(linearY)

        // ── Step 2: Dynamic Background Noise Estimation ──
        val totalLinearMotion = absX + absY + absZ
        // Cap the motion contribution to prevent tap spikes from desensitizing the detector
        val noiseInput = totalLinearMotion.coerceAtMost(3.0f)
        val noiseDecay = 0.98f
        runningNoise = noiseDecay * runningNoise + (1 - noiseDecay) * noiseInput

        // Dynamic Threshold Scaling - raising baseline floor to 1.5f and reducing slope to 0.5f
        val noiseMultiplier = if (runningNoise > 1.5f) {
            1.0f + (runningNoise - 1.5f) * 0.5f
        } else {
            1.0f
        }

        val currentForceThreshold = (if (isCalib) 1.5f else tapThreshold) * noiseMultiplier
        
        // Time-invariant Jerk check normalized to a 10ms frame
        val normalizedJerkZ = Math.abs(linearZ - lastLinearZ) * (0.01f / dt)
        lastLinearZ = linearZ

        // Check if the sensor has settled down (quiet window)
        // Make the quiet threshold dynamic based on environmental noise floor, with a baseline of 2.0 m/s^2
        val activeQuietThreshold = Math.max(2.0f, runningNoise * 1.2f)
        if (absZ < activeQuietThreshold) {
            quietSamplesCount++
            if (quietSamplesCount >= 2) {
                isQuietBetweenTaps = true
            }
        } else {
            quietSamplesCount = 0
        }

        // ── Step 3: Violent Impact Rejection (Drop Filter) ──
        if (linearZ >= 25.0f) {
            Log.d("BackTapDetector", "Violent impact detected (linearZ: ${String.format("%.2f", linearZ)} >= 25.0). Activating 800ms cooldown.")
            cooldownLockoutTime = currentTime + 800L
            tapCount = 0
            lastTapTime = 0L
            isQuietBetweenTaps = true
            quietSamplesCount = 0
            return
        }

        // Record negative Z excursions for screen tap recoil check
        if (linearZ < -2.0f) {
            lastNegativeSpikeTime = currentTime
        }

        // ── Step 4: Screen Tap Filtering (Polarity Check) ──
        if (linearZ > currentForceThreshold) {
            // ── Step 5: Screen Tap Recoil Suppression ──
            if (currentTime - lastNegativeSpikeTime < 60L) {
                Log.d("BackTapDetector", "Spike ignored: classified as screen tap recoil.")
                return
            }

            // ── Step 6: Rotation & Cross-Axis Rejection ──
            if (linearZ > (absX + absY) * 1.2f) {
                
                // ── Step 7: Jerk Verification (Sharpness Check) ──
                val currentJerkThreshold = (if (isCalib) 1.5f else jerkThreshold) * noiseMultiplier
                if (normalizedJerkZ > currentJerkThreshold) {
                    val timeDiff = currentTime - lastTapTime
                    
                    // ── Step 8: Timing & Cadence Checks ──
                    if (timeDiff > debounceWindowMs) {
                        
                        // Quiet Window Check: Reject continuous vibration
                        if (tapCount == 0 || isQuietBetweenTaps) {
                            Log.d("BackTapDetector", "VALID TAP SPIKE! linearZ: ${String.format("%.2f", linearZ)}, timeDiff: ${timeDiff}ms, Jerk: ${String.format("%.2f", normalizedJerkZ)}")
        
                            if (timeDiff in tapWindowMinMs..tapWindowMaxMs) {
                                // Store calibration data
                                if (tapCount in 0..2) {
                                    calibForces[tapCount] = linearZ
                                    calibJerks[tapCount] = normalizedJerkZ
                                }
                                
                                // ── Step 9: Multi-Spike Density Filter ──
                                // Prune spike history dynamically based on sensitivity tap window
                                val historyWindow = tapWindowMaxMs * 2 + 200L
                                spikeHistory.removeAll { currentTime - it > historyWindow }
                                spikeHistory.add(currentTime)
                                
                                if (spikeHistory.size > 3) {
                                    Log.d("BackTapDetector", "Gesture suppressed: continuous activity detected (${spikeHistory.size} spikes in ${historyWindow}ms)")
                                    tapCount = 0
                                    lastTapTime = 0L
                                    isQuietBetweenTaps = true
                                    quietSamplesCount = 0
                                    return
                                }

                                tapCount++
                                isQuietBetweenTaps = false
                                quietSamplesCount = 0
                                
                                // ── Step 10: Force Consistency Check ──
                                if (tapCount >= 3) {
                                    val f1 = calibForces[0]
                                    val f2 = calibForces[1]
                                    val f3 = calibForces[2]
                                    
                                    val maxForce = maxOf(f1, maxOf(f2, f3))
                                    val minForce = minOf(f1, minOf(f2, f3))
                                    
                                    val ratioLimit = (4.5f - 0.5f * (tapThreshold - 2.2f)).coerceIn(3.0f, 4.5f)
                                    val actualRatio = maxForce / minForce
                                    if (maxForce <= minForce * ratioLimit) {
                                        // Calculate calibrated values (60% of average)
                                        val avgForce = (f1 + f2 + f3) / 3f
                                        val avgJerk = (calibJerks[0] + calibJerks[1] + calibJerks[2]) / 3f
                                        
                                        val recommendedForce = (avgForce * 0.60f).coerceIn(2.2f, 4.5f)
                                        val recommendedJerk = (avgJerk * 0.50f).coerceIn(1.5f, 2.2f)
                                        
                                        // ── Step 11: Triple-Tap Completion ──
                                        Log.d("BackTapDetector", "🏆 TRIPLE BACK TAP DETECTED! Calibrated Force: $recommendedForce, Calibrated Jerk: $recommendedJerk (Ratio: ${String.format("%.2f", actualRatio)} <= Limit: ${String.format("%.2f", ratioLimit)})")
                                        onTripleTapTriggered(recommendedForce, recommendedJerk)
                                        
                                        // Reset
                                        lastTapTime = 0L
                                        tapCount = 0
                                        isQuietBetweenTaps = true
                                        quietSamplesCount = 0
                                        spikeHistory.clear()
                                    } else {
                                        Log.d("BackTapDetector", "Tap sequence rejected: force inconsistent (Max: ${String.format("%.2f", maxForce)}, Min: ${String.format("%.2f", minForce)}, Ratio: ${String.format("%.2f", actualRatio)} > Limit: ${String.format("%.2f", ratioLimit)})")
                                        // Reset
                                        lastTapTime = 0L
                                        tapCount = 0
                                        isQuietBetweenTaps = true
                                        quietSamplesCount = 0
                                    }
                                } else {
                                    lastTapTime = currentTime
                                }
                            } else {
                                // Start of a new tap sequence
                                tapCount = 1
                                calibForces[0] = linearZ
                                calibJerks[0] = normalizedJerkZ
                                isQuietBetweenTaps = false
                                quietSamplesCount = 0
                                lastTapTime = currentTime
                                
                                // Reset spike history for new sequence
                                spikeHistory.clear()
                                spikeHistory.add(currentTime)
                            }
                        } else {
                            Log.d("BackTapDetector", "Tap ignored: Continuous vibration/noise (not quiet between taps)")
                        }
                    } else {
                        Log.d("BackTapDetector", "Tap ignored: debounced (timeDiff: ${timeDiff}ms <= ${debounceWindowMs}ms)")
                    }
                } else {
                    Log.d("BackTapDetector", "Tap ignored: Low Jerk (smooth movement). Jerk:$normalizedJerkZ < $currentJerkThreshold")
                }
            } else {
                Log.d("BackTapDetector", "Tap ignored: Cross-axis rejection. Too much X/Y movement. Z:$linearZ, X:$absX, Y:$absY")
            }
        }
    }

    fun resetState() {
        tapCount = 0
        lastTapTime = 0L
        isQuietBetweenTaps = true
        quietSamplesCount = 0
        cooldownLockoutTime = 0L
        lastNegativeSpikeTime = 0L
        spikeHistory.clear()
        runningNoise = 0f
        Log.d("BackTapDetector", "Detector state reset successfully.")
    }
}
