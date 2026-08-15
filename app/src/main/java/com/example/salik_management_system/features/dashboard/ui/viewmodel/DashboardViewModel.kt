package com.example.salik_management_system.features.dashboard.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.salik_management_system.auth.data.AuthRepository
import com.example.salik_management_system.auth.domain.UserSession
import com.example.salik_management_system.core.utils.AccessControl
import com.example.salik_management_system.features.saliks.data.repository.AreaRepository
import com.example.salik_management_system.features.saliks.data.repository.SalikRepository
import com.example.salik_management_system.features.saliks.domain.model.Bazam
import com.example.salik_management_system.features.saliks.domain.model.Salik
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.stateIn
import javax.inject.Inject

data class DashboardStats(
    val total: Int = 0,
    val maleCount: Int = 0,
    val femaleCount: Int = 0,
    val nafiAsbatCount: Int = 0,
    val sahibMehfilCount: Int = 0,
)

data class BazamCount(
    val bazamId: String,
    val bazamName: String,
    val count: Int,
)

data class DashboardUiState(
    val session: UserSession? = null,
    val stats: DashboardStats = DashboardStats(),
    val bazamCounts: List<BazamCount> = emptyList(),
    val pendingCount: Int = 0,
    val canCreate: Boolean = false,
    val canViewPending: Boolean = false,
)

@OptIn(ExperimentalCoroutinesApi::class)
@HiltViewModel
class DashboardViewModel @Inject constructor(
    authRepository: AuthRepository,
    salikRepository: SalikRepository,
    areaRepository: AreaRepository,
) : ViewModel() {
    val uiState: StateFlow<DashboardUiState> = authRepository.session
        .flatMapLatest { session ->
            combine(
                salikRepository.watchApproved(session),
                salikRepository.watchPending(session),
                areaRepository.watchBazams(),
            ) { approved, pending, bazams ->
                buildState(session, approved, pending, bazams)
            }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), DashboardUiState())

    private fun buildState(
        session: UserSession?,
        approved: List<Salik>,
        pending: List<Salik>,
        bazams: List<Bazam>,
    ): DashboardUiState {
        val stats = DashboardStats(
            total = approved.size,
            maleCount = approved.count { it.genderId.equals("Male", true) },
            femaleCount = approved.count { it.genderId.equals("Female", true) },
            nafiAsbatCount = approved.count { it.isNafiAsbat },
            sahibMehfilCount = approved.count { it.isSahibEMehfil },
        )
        val bazamCounts = bazams.map { bazam ->
            BazamCount(
                bazamId = bazam.bazamId,
                bazamName = bazam.bazamName,
                count = approved.count {
                    it.bazamId == bazam.bazamId ||
                        (it.bazamId.isEmpty() && bazam.bazamId == "i-10")
                },
            )
        }
        return DashboardUiState(
            session = session,
            stats = stats,
            bazamCounts = bazamCounts,
            pendingCount = pending.count { it.isPending },
            canCreate = session != null && AccessControl.canCreate(session.role),
            canViewPending = session != null && AccessControl.canViewPending(session.role),
        )
    }
}
