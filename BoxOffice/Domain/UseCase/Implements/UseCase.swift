
import Foundation

final class BoxOfficeUseCase: BoxOfficeUseCaseProtocol {
    
    private let moviesRepository: MovieRepositoryProtocol
    
    init(moviesRepository: MovieRepositoryProtocol) {
        self.moviesRepository = moviesRepository
    }
    
    func fetchBoxOfficeData() async -> Result<[BoxOfficeMovie], DomainError> {
        let result = await moviesRepository.getBoxofficeData()
        switch result {
        case .success(let data):
            let movies = data.boxOfficeResult.dailyBoxOfficeList.map { $0.toEntity() }
            return .success(movies)
        case .failure(let networkError):
            return .failure(DomainError(from: networkError))
        }
    }
}

