package com.waypointlattice.tripl.ui.components.core

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.waypointlattice.tripl.ui.components.outerGlow
import com.waypointlattice.tripl.ui.theme.LocalTriplColors

@Composable
fun ScrollableCategoryCapsule(
    label: String,
    isSelected: Boolean,
    onClick: () -> Unit,
    accentColor: Color? = null
) {
    val theme = LocalTriplColors.current
    val resolvedAccent = accentColor ?: theme.primaryAccent
    val inactiveBg = if (theme.isLight) theme.cardBorder.copy(alpha = 0.5f) else theme.cardBorder.copy(alpha = 0.3f)
    val inactiveText = theme.textPrimary.copy(alpha = 0.85f)

    Box(
        modifier = Modifier
            .height(42.dp)
            .then(if (isSelected) Modifier.outerGlow(color = resolvedAccent, radius = 12.dp, alpha = 0.35f, cornerRadius = 100.dp) else Modifier)
            .clip(RoundedCornerShape(100.dp))
            .background(if (isSelected) resolvedAccent.copy(alpha = 0.15f) else inactiveBg)
            .border(
                width = 1.0.dp,
                color = if (isSelected) resolvedAccent else Color.Transparent,
                shape = RoundedCornerShape(100.dp)
            )
            .clickable { onClick() }
            .padding(horizontal = 20.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = label,
            style = TextStyle(
                fontSize = 13.sp,
                fontWeight = FontWeight.W700,
                color = if (isSelected) resolvedAccent.ensureLegibleText(theme.isLight) else inactiveText
            ),
            maxLines = 1
        )
    }
}

private fun Color.ensureLegibleText(isLight: Boolean): Color {
    if (!isLight) {
        val r = (this.red + 1.0f) / 2.0f
        val g = (this.green + 1.0f) / 2.0f
        val b = (this.blue + 1.0f) / 2.0f
        return Color(r, g, b, this.alpha)
    } else {
        val r = this.red * 0.45f
        val g = this.green * 0.45f
        val b = this.blue * 0.45f
        return Color(r, g, b, this.alpha)
    }
}
