import AppIntents

struct CategoryEntity: AppEntity {
    let id: String
    let name: String

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Category"
    static let defaultQuery = CategoryEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    init?(_ category: AutoCategoryElement) {
        guard let id = category.id, let name = category.name else { return nil }
        self.id = id
        self.name = name
    }
}

struct CategoryEntityQuery: EntityStringQuery {
    func entities(for identifiers: [CategoryEntity.ID]) async throws -> [CategoryEntity] {
        let wanted = Set(identifiers)
        return try await allCategories().filter { wanted.contains($0.id) }
    }

    func suggestedEntities() async throws -> [CategoryEntity] {
        try await allCategories()
    }

    func entities(matching string: String) async throws -> [CategoryEntity] {
        try await allCategories().filter { $0.name.localizedStandardContains(string) }
    }

    private func allCategories() async throws -> [CategoryEntity] {
        do {
            return try await fetchCategoriesAutocomplete().compactMap(CategoryEntity.init)
        } catch {
            throw AddTransactionIntentError.userFacing(error)
        }
    }
}
