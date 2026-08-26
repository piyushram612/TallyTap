package com.waypointlattice.tripl.ui.components.core

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Backspace
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.waypointlattice.tripl.ui.theme.LocalTriplColors
import com.waypointlattice.tripl.utils.MathEvaluator

@Composable
fun CalculatorKeypadSheet(
    initialExpression: String,
    currency: String,
    onDismiss: () -> Unit,
    onSetAmount: (String) -> Unit
) {
    val theme = LocalTriplColors.current
    val haptic = LocalHapticFeedback.current

    val greenPrimary = theme.primaryAccent
    val cardBg = theme.cardBg
    val borderDark = theme.cardBorder
    val textPrimary = theme.textPrimary
    val textMuted = theme.textMuted
    val ctaTextColor = if (theme.isLight) Color.White else theme.bgBase

    var expr by remember { mutableStateOf(initialExpression.trim()) }

    val evaluated = remember(expr) {
        if (MathEvaluator.hasOperator(expr)) MathEvaluator.evaluate(expr) else null
    }
    val evaluatedStr = remember(evaluated) {
        evaluated?.let { MathEvaluator.formatResult(it) }
    }

    fun handleSetAmount() {
        haptic.performHapticFeedback(HapticFeedbackType.LongPress)
        var finalAmount = expr.trim()
        if (MathEvaluator.hasOperator(finalAmount)) {
            val eval = MathEvaluator.evaluate(finalAmount)
            if (eval != null) {
                finalAmount = MathEvaluator.formatResult(eval)
            }
        }
        onSetAmount(finalAmount)
        onDismiss()
    }

    fun onKeyPress(key: String) {
        haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)

        when (key) {
            "C" -> expr = ""
            "⌫" -> {
                if (expr.isNotEmpty()) {
                    expr = expr.substring(0, expr.length - 1).trimEnd()
                }
            }
            "=" -> {
                if (evaluatedStr != null) {
                    expr = evaluatedStr
                } else if (expr.isNotEmpty()) {
                    handleSetAmount()
                }
            }
            "+", "-", "×", "÷" -> {
                if (expr.isNotEmpty() && !expr.endsWith(" ")) {
                    expr = "$expr $key "
                }
            }
            else -> {
                expr += key
            }
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.65f))
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null
            ) { onDismiss() },
        contentAlignment = Alignment.BottomCenter
    ) {
        Surface(
            modifier = Modifier
                .fillMaxWidth()
                .wrapContentHeight()
                .navigationBarsPadding()
                .clickable(
                    interactionSource = remember { MutableInteractionSource() },
                    indication = null
                ) { /* Catch inner clicks */ },
            shape = RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp),
            color = cardBg,
            border = BorderStroke(1.5.dp, borderDark)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 16.dp)
                    .verticalScroll(rememberScrollState()),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // Drag handle
                Box(
                    modifier = Modifier
                        .width(36.dp)
                        .height(4.dp)
                        .background(textMuted.copy(alpha = 0.35f), CircleShape)
                )

                Spacer(modifier = Modifier.height(16.dp))

                // Header Row: "Enter Amount" & Live Display
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Enter Amount",
                        style = TextStyle(
                            fontSize = 20.sp,
                            fontWeight = FontWeight.W900,
                            color = textPrimary
                        )
                    )
                    Column(
                        horizontalAlignment = Alignment.End,
                        modifier = Modifier.weight(1f)
                    ) {
                        Text(
                            text = if (expr.isEmpty()) "$currency 0" else "$currency $expr",
                            style = TextStyle(
                                fontSize = 26.sp,
                                fontWeight = FontWeight.W900,
                                color = textPrimary
                            ),
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                        if (evaluatedStr != null) {
                            Spacer(modifier = Modifier.height(2.dp))
                            Text(
                                text = "= $currency $evaluatedStr",
                                style = TextStyle(
                                    fontSize = 14.sp,
                                    fontWeight = FontWeight.W800,
                                    color = greenPrimary
                                )
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(18.dp))

                // Keypad Obsidian Card Container
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(24.dp),
                    colors = CardDefaults.cardColors(containerColor = cardBg),
                    border = BorderStroke(1.dp, borderDark)
                ) {
                    Column(
                        modifier = Modifier.padding(12.dp),
                        verticalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        KeypadRow(listOf("C", "(", ")", "÷"), greenPrimary, cardBg, borderDark, textPrimary, textMuted, ::onKeyPress)
                        KeypadRow(listOf("7", "8", "9", "×"), greenPrimary, cardBg, borderDark, textPrimary, textMuted, ::onKeyPress)
                        KeypadRow(listOf("4", "5", "6", "-"), greenPrimary, cardBg, borderDark, textPrimary, textMuted, ::onKeyPress)
                        KeypadRow(listOf("1", "2", "3", "+"), greenPrimary, cardBg, borderDark, textPrimary, textMuted, ::onKeyPress)
                        KeypadRow(listOf("0", ".", "⌫", "="), greenPrimary, cardBg, borderDark, textPrimary, textMuted, ::onKeyPress)
                    }
                }

                Spacer(modifier = Modifier.height(20.dp))

                // SET AMOUNT Action Button
                Button(
                    onClick = ::handleSetAmount,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(52.dp),
                    shape = RoundedCornerShape(20.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = greenPrimary,
                        contentColor = ctaTextColor
                    ),
                    elevation = ButtonDefaults.buttonElevation(0.dp, 0.dp)
                ) {
                    Text(
                        text = if (evaluatedStr != null) "SET AMOUNT (= $evaluatedStr)" else "SET AMOUNT",
                        style = TextStyle(
                            fontSize = 15.sp,
                            fontWeight = FontWeight.W900,
                            letterSpacing = 0.5.sp
                        )
                    )
                }

                Spacer(modifier = Modifier.height(8.dp))
            }
        }
    }
}

// Alias for backwards compatibility
@Composable
fun CalculatorKeypadDialog(
    initialExpression: String,
    currency: String,
    onDismiss: () -> Unit,
    onSetAmount: (String) -> Unit
) {
    CalculatorKeypadSheet(
        initialExpression = initialExpression,
        currency = currency,
        onDismiss = onDismiss,
        onSetAmount = onSetAmount
    )
}

@Composable
private fun KeypadRow(
    keys: List<String>,
    accentColor: Color,
    cardBg: Color,
    borderDark: Color,
    textPrimary: Color,
    textMuted: Color,
    onKeyPress: (String) -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        keys.forEach { key ->
            KeypadButton(
                key = key,
                accentColor = accentColor,
                cardBg = cardBg,
                borderDark = borderDark,
                textPrimary = textPrimary,
                textMuted = textMuted,
                onClick = { onKeyPress(key) },
                modifier = Modifier.weight(1f)
            )
        }
    }
}

@Composable
private fun KeypadButton(
    key: String,
    accentColor: Color,
    cardBg: Color,
    borderDark: Color,
    textPrimary: Color,
    textMuted: Color,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val isOperator = key == "+" || key == "-" || key == "×" || key == "÷" || key == "="
    val isClear = key == "C"
    val isBack = key == "⌫"

    val keyBg = when {
        isClear -> Color(0xFFEF4444).copy(alpha = 0.15f)
        isOperator -> accentColor.copy(alpha = 0.15f)
        else -> cardBg
    }

    val keyBorder = when {
        isClear -> Color(0xFFEF4444).copy(alpha = 0.4f)
        isOperator -> accentColor.copy(alpha = 0.4f)
        else -> borderDark
    }

    val keyTextColor = when {
        isClear -> Color(0xFFEF4444)
        isOperator -> accentColor
        else -> textPrimary
    }

    Box(
        modifier = modifier
            .height(52.dp)
            .clip(RoundedCornerShape(14.dp))
            .background(keyBg)
            .border(1.dp, keyBorder, RoundedCornerShape(14.dp))
            .clickable { onClick() },
        contentAlignment = Alignment.Center
    ) {
        if (isBack) {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.Backspace,
                contentDescription = "Backspace",
                tint = textMuted,
                modifier = Modifier.size(20.dp)
            )
        } else {
            Text(
                text = key,
                style = TextStyle(
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                    color = keyTextColor
                )
            )
        }
    }
}
