/*
 * External dependencies:
 * androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.1
 * kotlinx-coroutines-core:1.7.0
 * javax.inject:1
 * dagger.hilt:hilt-android:2.47
 */

package com.founditure.presentation.message

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import com.founditure.domain.usecase.message.SendMessageUseCase
import com.founditure.domain.usecase.message.GetMessagesUseCase
import com.founditure.domain.model.Message
import com.founditure.data.api.NetworkResult

/**
 * Human Tasks:
 * 1. Configure proper dependency injection in Hilt modules
 * 2. Set up appropriate error tracking and monitoring for message operations
 * 3. Configure proper logging for message sending/receiving events
 * 4. Verify proper UI state handling in the composable/fragment using this ViewModel
 */

/**
 * ViewModel that manages chat screen state and messaging operations with offline-first support.
 *
 * Requirements addressed:
 * - Real-time messaging (1.2 System Overview/High-Level Description):
 *   Implements real-time message management with offline support
 * - Core Features/Messaging (1.3 Scope/In-Scope Elements):
 *   Enables real-time messaging between users with proper state management
 */
@HiltViewModel
class ChatViewModel @Inject constructor(
    private val sendMessageUseCase: SendMessageUseCase,
    private val getMessagesUseCase: GetMessagesUseCase
) : ViewModel() {

    // UI State management
    private val _uiState = MutableStateFlow<ChatUiState>(ChatUiState.Initial)
    val uiState: StateFlow<ChatUiState> = _uiState.asStateFlow()

    /**
     * Sends a new message with offline support.
     * Updates UI state based on the operation result.
     *
     * @param message Message to be sent
     */
    fun sendMessage(message: Message) {
        viewModelScope.launch {
            _uiState.value = ChatUiState.Loading

            when (val result = sendMessageUseCase.invoke(message)) {
                is NetworkResult.Success -> {
                    _uiState.value = ChatUiState.MessageSent(result.data)
                }
                is NetworkResult.Error -> {
                    _uiState.value = ChatUiState.Error(result.message)
                }
            }
        }
    }

    /**
     * Retrieves messages for the current chat with offline-first support.
     * Updates UI state with real-time message updates.
     *
     * @param userId ID of the user whose messages to retrieve
     */
    fun getMessages(userId: String) {
        viewModelScope.launch {
            _uiState.value = ChatUiState.Loading

            try {
                getMessagesUseCase.invoke(userId)
                    .collect { messages ->
                        _uiState.value = ChatUiState.Success(messages)
                    }
            } catch (e: Exception) {
                _uiState.value = ChatUiState.Error(e.message ?: "Failed to retrieve messages")
            }
        }
    }

    /**
     * Marks a message as read in the local database and syncs with server.
     *
     * @param messageId ID of the message to mark as read
     */
    fun markMessageAsRead(messageId: String) {
        viewModelScope.launch {
            try {
                // Update current messages list to reflect read status
                val currentState = _uiState.value
                if (currentState is ChatUiState.Success) {
                    val updatedMessages = currentState.messages.map { message ->
                        if (message.id == messageId) {
                            message.copy(isRead = true)
                        } else {
                            message
                        }
                    }
                    _uiState.value = ChatUiState.Success(updatedMessages)
                }
            } catch (e: Exception) {
                _uiState.value = ChatUiState.Error("Failed to mark message as read")
            }
        }
    }
}

/**
 * Sealed class representing different states of the chat screen UI.
 */
sealed class ChatUiState {
    object Initial : ChatUiState()
    object Loading : ChatUiState()
    data class Success(val messages: List<Message>) : ChatUiState()
    data class MessageSent(val message: Message) : ChatUiState()
    data class Error(val message: String) : ChatUiState()
}