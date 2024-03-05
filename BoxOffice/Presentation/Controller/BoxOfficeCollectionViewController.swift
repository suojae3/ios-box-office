
import UIKit

class BoxOfficeCollectionViewController: UIViewController {
    
    var testData: [MovieListItem] = []
    
    lazy var items: [MovieListItem] = {
        return itemsInternal()
    }()
    
    private let usecase: BoxOfficeUseCaseProtocol
    private var boxOfficeTask: Task<Void, Never>?
    
    var collectionView: UICollectionView! = nil
    var dataSource: UICollectionViewDiffableDataSource<Section, MovieListItem>! = nil
    
    
    init(usecase: BoxOfficeUseCaseProtocol) {
        self.usecase = usecase
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        boxOfficeTask = Task {
            await fetchBoxOfficeData()
            await fetchDetailMovieData()
            print("동기동기동기동기동기")
            print(items)
           // applyInitialSnapshot()
        }
        
        // 컬렉션 뷰와 데이터 소스 구성
        configureCollectionView()
        configureDataSource()
    }
    
    deinit {
        boxOfficeTask?.cancel()
    }
}

// MARK: - 컬렉션 뷰
extension BoxOfficeCollectionViewController {
    func itemsInternal() -> [MovieListItem] {
        return testData
    }
    
    func configureCollectionView() {
        
        // 컬렉션 뷰의 레이아웃을 생성하고, 컬렉션 뷰 초기화
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // 컬렉션 뷰를 뷰 계층에 추가
        view.addSubview(collectionView)
        
        // 셀을 등록합니다. 셀의 재사용을 위해 필요
        collectionView.register(BoxOfficeMainListCell.self, forCellWithReuseIdentifier: BoxOfficeMainListCell.reuseIdentifier)
    }
    
    func createLayout() -> UICollectionViewLayout {
        let estimatedHeight = CGFloat(78)
        let layoutSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .estimated(estimatedHeight))
        let item = NSCollectionLayoutItem(layoutSize: layoutSize)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: layoutSize,
                                                       subitem: item,
                                                       count: 1)
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        section.interGroupSpacing = 0
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
    
    func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration
        <BoxOfficeMainListCell, MovieListItem> { (cell, indexPath, movieItem) in
            // Populate the cell with our item description.
            cell.movieNameLabel.text = movieItem.movieTitle
            cell.rankLabel.text = movieItem.rank
            cell.rankIntensityLabel.text = movieItem.rankIntensity
            cell.audienceAccountLabel.text = movieItem.audienceAccount
            cell.showsSeparator = indexPath.item != self.testData.count
        }
        
        // Diffable Data Source를 구성합니다. 셀을 구성하는 클로저를 정의
        dataSource = UICollectionViewDiffableDataSource<Section, MovieListItem>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell? in
            
            // "cell" 식별자를 사용하여 셀을 가져오기
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
    }
    
    func applyInitialSnapshot() {
        
        // 초기 스냅샷을 생성하고 적용 이 단계에서는 데이터 모델을 스냅샷에 추가
        var snapshot = NSDiffableDataSourceSnapshot<Section, MovieListItem>()
        
        // 스냅샷에 섹션을 추가
        snapshot.appendSections([.main])
        
        // 스냅샷에 아이템(데이터)을 추가
        snapshot.appendItems(testData)
        
        // 변경된 스냅샷을 데이터 소스에 적용 및 UI업데이트
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
}

extension BoxOfficeCollectionViewController {
    
    func fetchBoxOfficeData() async {
        let result = await usecase.fetchBoxOfficeData()
        switch result {
        case .success(let data):
            print("일일 박스오피스 조회")
            print(data)
            testData = data.map { 
                MovieListItem( rank: $0.rank,
                               rankIntensity: $0.rankIntensity,
                               rankOldAndNew: $0.rankOldandNew,
                               movieTitle: $0.movieTitle,
                               audienceCount: $0.audienceCount,
                               audienceAccount: $0.audienceAccount)
            }
            applyInitialSnapshot()
        case .failure(let error):
            presentError(error)
        }
    }
    
    func fetchDetailMovieData() async {
        let result = await usecase.fetchDetailMovieData()
        switch result {
        case .success(let data):
            print("영화 개별 상세 조회")
            print(data)
        case .failure(let error):
            presentError(error)
        }
    }
    
    func presentError(_ error: DomainError) {
        let message: String
        switch error {
        case .networkIssue:
            message = error.localizedDescription
        case .dataUnavailable:
            message = error.localizedDescription
        case .unknown:
            message = error.localizedDescription
        }
        
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }
}
