// SwiftUI framework - Latest
import SwiftUI

/// Human Tasks:
/// 1. Verify proper keyboard handling on different device sizes
/// 2. Test VoiceOver navigation flow with accessibility team
/// 3. Validate form validation error messages with UX team
/// 4. Review image compression settings for different network conditions
/// 5. Test AI recognition accuracy with various furniture types

/// Main view for creating new furniture listings with Material Design 3 styling
/// Requirements addressed:
/// - AI-powered furniture recognition (1.2): Implements furniture recognition
/// - Location-based discovery (1.2): Integrates location services
/// - Visual Hierarchy (3.1.1): Follows Material Design 3 guidelines
@MainActor
struct CreateListingView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel: CreateListingViewModel
    @State private var showingPhotoPicker = false
    @State private var photoSource: PhotoPickerSource = .camera
    @State private var showingCategoryPicker = false
    @State private var showingConditionPicker = false
    @State private var showingErrorAlert = false
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initialization
    
    init(viewModel: CreateListingViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    photoSelectionSection
                    listingDetailsSection
                    submitButton
                }
                .padding()
            }
            .navigationTitle("Create Listing")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.error?.localizedDescription ?? "An error occurred")
            }
        }
    }
    
    // MARK: - Photo Selection Section
    
    private var photoSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Photos")
                .font(FounditureTypography.dynamicFont(style: .headline, size: .medium))
            
            if !viewModel.selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.selectedImages.indices, id: \.self) { index in
                            Image(uiImage: viewModel.selectedImages[index])
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    Button {
                                        viewModel.removeImage(at: index)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white)
                                            .background(Circle().fill(Color.black.opacity(0.5)))
                                    }
                                    .padding(4),
                                    alignment: .topTrailing
                                )
                                .accessibilityLabel("Photo \(index + 1)")
                                .accessibilityAddTraits(.isImage)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            FounditureButton(
                title: "Add Photo",
                style: .secondary,
                action: {
                    showingPhotoPicker = true
                }
            )
            .actionSheet(isPresented: $showingPhotoPicker) {
                ActionSheet(
                    title: Text("Add Photo"),
                    buttons: [
                        .default(Text("Take Photo")) {
                            photoSource = .camera
                            showingPhotoPicker = true
                        },
                        .default(Text("Choose from Library")) {
                            photoSource = .photoLibrary
                            showingPhotoPicker = true
                        },
                        .cancel()
                    ]
                )
            }
            
            if let category = viewModel.recognizedCategory {
                Text("AI recognized this as: \(category.rawValue.capitalized)")
                    .font(FounditureTypography.dynamicFont(style: .subheadline, size: .medium))
                    .foregroundColor(FounditureColors.secondary)
            }
        }
    }
    
    // MARK: - Listing Details Section
    
    private var listingDetailsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            FounditureTextField(
                text: $viewModel.title,
                placeholder: "Title",
                style: .outlined,
                validationRules: [{ !$0.isEmpty }]
            )
            
            FounditureTextField(
                text: $viewModel.description,
                placeholder: "Description",
                style: .outlined,
                validationRules: [{ !$0.isEmpty }]
            )
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(FounditureTypography.dynamicFont(style: .subheadline, size: .medium))
                
                Button {
                    showingCategoryPicker = true
                } label: {
                    HStack {
                        Text(viewModel.category.rawValue.capitalized)
                            .foregroundColor(FounditureColors.onSurface)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(FounditureColors.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(FounditureColors.primary, lineWidth: 1)
                    )
                }
            }
            .sheet(isPresented: $showingCategoryPicker) {
                NavigationView {
                    List(FurnitureCategory.allCases, id: \.self) { category in
                        Button {
                            viewModel.category = category
                            showingCategoryPicker = false
                        } label: {
                            Text(category.rawValue.capitalized)
                                .foregroundColor(FounditureColors.onSurface)
                        }
                    }
                    .navigationTitle("Select Category")
                    .navigationBarItems(trailing: Button("Done") {
                        showingCategoryPicker = false
                    })
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Condition")
                    .font(FounditureTypography.dynamicFont(style: .subheadline, size: .medium))
                
                Button {
                    showingConditionPicker = true
                } label: {
                    HStack {
                        Text(viewModel.condition.rawValue.capitalized)
                            .foregroundColor(FounditureColors.onSurface)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(FounditureColors.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(FounditureColors.primary, lineWidth: 1)
                    )
                }
            }
            .sheet(isPresented: $showingConditionPicker) {
                NavigationView {
                    List(FurnitureCondition.allCases, id: \.self) { condition in
                        Button {
                            viewModel.condition = condition
                            showingConditionPicker = false
                        } label: {
                            Text(condition.rawValue.capitalized)
                                .foregroundColor(FounditureColors.onSurface)
                        }
                    }
                    .navigationTitle("Select Condition")
                    .navigationBarItems(trailing: Button("Done") {
                        showingConditionPicker = false
                    })
                }
            }
        }
    }
    
    // MARK: - Submit Button
    
    private var submitButton: some View {
        FounditureButton(
            title: "Create Listing",
            style: .primary,
            isEnabled: !viewModel.title.isEmpty && !viewModel.description.isEmpty && !viewModel.selectedImages.isEmpty,
            isLoading: viewModel.isLoading,
            action: handleSubmit
        )
    }
    
    // MARK: - Actions
    
    private func handleSubmit() {
        Task {
            do {
                try await viewModel.createListing()
                dismiss()
            } catch {
                showingErrorAlert = true
            }
        }
    }
}

// MARK: - Preview Provider

#if DEBUG
struct CreateListingView_Previews: PreviewProvider {
    static var previews: some View {
        CreateListingView(viewModel: CreateListingViewModel(
            listingService: ListingService(apiClient: APIClient()),
            imageProcessor: ImageProcessor(apiClient: APIClient())
        ))
    }
}
#endif