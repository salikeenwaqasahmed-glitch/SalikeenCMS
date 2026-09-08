package com.example.salik_management_system.ui.components

import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.text.font.FontWeight
import com.example.salik_management_system.features.saliks.domain.model.ApprovalStatus
import com.example.salik_management_system.ui.theme.Dimens
import com.example.salik_management_system.ui.theme.StatusApprovedContainer
import com.example.salik_management_system.ui.theme.StatusApprovedContainerDark
import com.example.salik_management_system.ui.theme.StatusApprovedOnContainer
import com.example.salik_management_system.ui.theme.StatusApprovedOnContainerDark
import com.example.salik_management_system.ui.theme.StatusPendingContainer
import com.example.salik_management_system.ui.theme.StatusPendingContainerDark
import com.example.salik_management_system.ui.theme.StatusPendingOnContainer
import com.example.salik_management_system.ui.theme.StatusPendingOnContainerDark
import com.example.salik_management_system.ui.theme.StatusRejectedContainer
import com.example.salik_management_system.ui.theme.StatusRejectedContainerDark
import com.example.salik_management_system.ui.theme.StatusRejectedOnContainer
import com.example.salik_management_system.ui.theme.StatusRejectedOnContainerDark

@Composable
fun StatusBadge(
    status: ApprovalStatus,
    modifier: Modifier = Modifier,
) {
    val isDarkTheme = MaterialTheme.colorScheme.background.luminance() < 0.5f
    val (containerColor, contentColor) = when (status) {
        ApprovalStatus.Pending -> if (isDarkTheme) {
            StatusPendingContainerDark to StatusPendingOnContainerDark
        } else {
            StatusPendingContainer to StatusPendingOnContainer
        }
        ApprovalStatus.Approved -> if (isDarkTheme) {
            StatusApprovedContainerDark to StatusApprovedOnContainerDark
        } else {
            StatusApprovedContainer to StatusApprovedOnContainer
        }
        ApprovalStatus.Rejected -> if (isDarkTheme) {
            StatusRejectedContainerDark to StatusRejectedOnContainerDark
        } else {
            StatusRejectedContainer to StatusRejectedOnContainer
        }
    }

    Surface(
        modifier = modifier,
        shape = RoundedCornerShape(Dimens.filterChipRadius),
        color = containerColor,
    ) {
        Text(
            text = status.name,
            modifier = Modifier.padding(horizontal = Dimens.space12, vertical = Dimens.space4),
            style = MaterialTheme.typography.labelSmall,
            fontWeight = FontWeight.SemiBold,
            color = contentColor,
        )
    }
}
