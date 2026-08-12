package com.waypointlattice.tripl.ui.components.core

import androidx.compose.foundation.layout.*
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.waypointlattice.tripl.ui.theme.LocalTriplColors

@Composable
fun SectionHeader(
    text: String,
    modifier: Modifier = Modifier
) {
    val theme = LocalTriplColors.current
    Row(modifier = modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Start) {
        Text(
            text = text,
            style = TextStyle(
                fontSize = 11.sp,
                fontWeight = FontWeight.W800,
                letterSpacing = 1.0.sp,
                color = theme.primaryAccent.copy(alpha = 0.8f)
            )
        )
    }
    Spacer(modifier = Modifier.height(12.dp))
}
