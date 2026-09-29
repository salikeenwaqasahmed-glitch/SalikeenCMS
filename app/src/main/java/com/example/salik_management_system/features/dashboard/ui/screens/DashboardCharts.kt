package com.example.salik_management_system.features.dashboard.ui.screens

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.salik_management_system.features.dashboard.ui.viewmodel.BazamCount
import com.example.salik_management_system.ui.theme.Brand
import com.example.salik_management_system.ui.theme.Dimens

@Composable
fun BazamBarChart(
    counts: List<BazamCount>,
    modifier: Modifier = Modifier,
    onBazamClick: (String) -> Unit = {}
) {
    val maxCount = counts.maxOfOrNull { it.count } ?: 1
    val barColor = Brand.Green

    Column(modifier = modifier.fillMaxWidth()) {
        counts.take(5).forEach { bazam ->
            val fraction = bazam.count.toFloat() / maxCount.toFloat()
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { onBazamClick(bazam.bazamId) }
                    .padding(vertical = 6.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    text = bazam.bazamName,
                    style = MaterialTheme.typography.labelSmall,
                    modifier = Modifier.width(60.dp),
                    maxLines = 1
                )
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .height(12.dp)
                        .clip(CircleShape)
                ) {
                    Canvas(modifier = Modifier.fillMaxWidth()) {
                        drawRoundRect(
                            color = barColor.copy(alpha = 0.1f),
                            size = size
                        )
                        drawRoundRect(
                            color = barColor,
                            size = Size(width = size.width * fraction, height = size.height)
                        )
                    }
                }
                Text(
                    text = "${bazam.count}",
                    style = MaterialTheme.typography.labelSmall,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}

@Composable
fun GenderDonutChart(
    male: Int,
    female: Int,
    modifier: Modifier = Modifier
) {
    val total = (male + female).coerceAtLeast(1)
    val maleAngle = (male.toFloat() / total) * 360f
    val femaleAngle = (female.toFloat() / total) * 360f

    val maleColor = Brand.Green
    val femaleColor = Brand.Gold

    Row(
        modifier = modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Center
    ) {
        Box(contentAlignment = Alignment.Center, modifier = Modifier.size(100.dp)) {
            Canvas(modifier = Modifier.size(80.dp)) {
                drawArc(
                    color = maleColor,
                    startAngle = -90f,
                    sweepAngle = maleAngle,
                    useCenter = false,
                    style = Stroke(width = 24f)
                )
                drawArc(
                    color = femaleColor,
                    startAngle = -90f + maleAngle,
                    sweepAngle = femaleAngle,
                    useCenter = false,
                    style = Stroke(width = 24f)
                )
            }
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = "$total",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "Total",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
        
        Spacer(modifier = Modifier.width(32.dp))
        
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            ChartLegendItem(color = maleColor, label = "Male", count = male)
            ChartLegendItem(color = femaleColor, label = "Female", count = female)
        }
    }
}

@Composable
private fun ChartLegendItem(color: Color, label: String, count: Int) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Box(modifier = Modifier.size(12.dp).clip(CircleShape).background(color))
        Spacer(modifier = Modifier.width(8.dp))
        Text(text = label, style = MaterialTheme.typography.bodySmall)
        Spacer(modifier = Modifier.width(4.dp))
        Text(text = "($count)", style = MaterialTheme.typography.labelSmall, fontWeight = FontWeight.Bold)
    }
}
