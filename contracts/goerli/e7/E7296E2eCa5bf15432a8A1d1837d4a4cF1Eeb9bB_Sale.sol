//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./libraries/Helper.sol";
import "./interfaces/ISetting.sol";
import "./interfaces/IProject.sol";
import "./interfaces/ISale.sol";
import "./interfaces/IOSB721.sol";
import "./interfaces/IOSB1155.sol";
import "./interfaces/INFTChecker.sol";
import "./interfaces/IRandomizer.sol";

contract Sale is ISale, ContextUpgradeable, ReentrancyGuardUpgradeable, ERC721HolderUpgradeable, ERC1155HolderUpgradeable {
    ISetting public setting;
    IProject public project;
    INFTChecker public nftChecker;
    IRandomizer public randomizer;

    uint256 public constant WEIGHT_DECIMAL = 1e6;

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter public lastId;

    /**
     * @dev Keep track of Sale from sale ID
     */
    mapping(uint256 => SaleInfo) public sales;

    /**
     * @dev Keep track of merkleRoot from sale ID
     */
    mapping(uint256 => bytes32) public merkleRoots;

    /**
     * @dev Keep track of saleIds of Project from project ID
     */
    mapping(uint256 => uint256[]) private saleIdsOfProject;

    /**
     * @dev Keep track of all buyers of Sale from sale ID
     */
    mapping(uint256 => address[]) private buyers;

    /**
     * @dev Keep track of buyers waiting distribution from sale ID
     */
    mapping(uint256 => address[]) private buyersWaitingDistributions;

    /**
     * @dev Check buyer was bought from sale ID and the buyer’s address
     */
    mapping(uint256 => mapping(address => bool)) private bought;

    /**
     * @dev Keep track of bill from saleId and buyer address
     */
    mapping(uint256 => mapping(address => Bill)) private bills;

    /**
     * @dev Keep track of list sales not close from project ID
     */
    mapping(uint256 => EnumerableSetUpgradeable.UintSet) private _saleIdNotCloseOfProject;

    /**
     * @dev Keep track of list current sales Ids in pack from project ID
     */
    mapping(uint256 => EnumerableSetUpgradeable.UintSet) private _currentSalesInPack;

    // ============ EVENTS ============

    /// @dev Emit an event when the contract is deployed
    event ContractDeployed(address indexed setting, address indexed nftChecker);

    /// @dev Emit an event when Project contract address is updated
    event SetProjectAddress(address indexed oldProjectAddress, address indexed newProjectAddress);

    /// @dev Emit an event when Randomizer contract address is updated
    event SetRandomizerAddress(address indexed oldRandomizerAddress, address indexed newRandomizerAddress);

    /// @dev Emit an event when created Sales
    event Creates(uint256 indexed projectId, SaleInfo[] sales);

    /// @dev Emit an event when bought
    event Buy(address indexed buyer, uint256 indexed saleId, uint256 indexed tokenId, uint256 amount, uint256 percentAdminFee, uint256 adminFee, uint256 royaltyFee, uint256 valueForUser);

    /// @dev Emit an event when the status close a Sale is updated
    event SetCloseSale(uint256 indexed saleId, bool status);

    /// @dev Emit an event when the amount a Sale is reset
    event ResetAmountSale(uint256 indexed saleId, uint256 indexed oldAmount);

    /// @dev Emit an event when the MerkleRoot a Sale is updated
    event SetMerkleRoot(uint256 indexed saleId, bytes32 rootHash);

    /**
     * @notice Setting states initial when deploy contract and only called once
     * @param _setting Setting contract address
     * @param _nftChecker NFTChecker contract address
     */
    function initialize(address _setting, address _nftChecker, address _randomizer) external initializer {
        require(_setting != address(0), "Invalid setting");
        require(_nftChecker != address(0), "Invalid nftChecker");
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        ERC721HolderUpgradeable.__ERC721Holder_init();
        ERC1155HolderUpgradeable.__ERC1155Holder_init();
        nftChecker = INFTChecker(_nftChecker);
        setting = ISetting(_setting);
        randomizer = IRandomizer(_randomizer);
        emit ContractDeployed(_setting, _nftChecker);
    }

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    /**
     * @dev To check caller is super admin
     */
    modifier onlySuperAdmin() {
        setting.checkOnlySuperAdmin(_msgSender());
        _;
    }

    /**
     * @dev To check caller is Project contract
     */
    modifier onlyProject() {
        require(_msgSender() == address(project), "Caller is not the Project");
        _;
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS =============

    /**
     * @notice
     * Set the new Project contract address
     * Caution need to discuss with the dev before updating the new state
     * 
     * @param _project Project contract address
     */
    function setProjectAddress(address _project) external onlySuperAdmin {
        require(_project != address(0), "Invalid Project address");
        address oldProjectAddress = address(project);
        project = IProject(_project);
        emit SetProjectAddress(oldProjectAddress, _project);
    }

    /**
     * @notice Set the new randomizer contract address
     * @param _randomizer The new contract address
     */
    function setRandomizerAddress(address _randomizer) external onlySuperAdmin {
        require(_randomizer != address(0), "Invalid randomizer address");
        address oldRandomizerAddress = address(randomizer);
        randomizer = IRandomizer(_randomizer);
        emit SetRandomizerAddress(oldRandomizerAddress, _randomizer);
    }

    // ============ PROJECT-ONLY FUNCTIONS =============

    /**
     * @notice Support create sale
     * @param _caller Address user request
     * @param _isCreateNewToken Is create new a token
     * @param _isSetRoyalty Is set royalty for token
     * @param _project Project info
     * @param _saleInput Sale input
     */
    function createSale(address _caller, bool _isCreateNewToken, bool _isSetRoyalty, ProjectInfo memory _project, SaleInput memory _saleInput) external nonReentrant onlyProject returns (uint256) {
        require(_project.isSingle ? _saleInput.amount == 1 : _saleInput.amount > 0, "Invalid amount");
        if (!_project.isFixed) {
            require(_saleInput.maxPrice > _saleInput.minPrice && _saleInput.minPrice > 0, "Invalid price");
            require(_saleInput.priceDecrementAmt > 0 && _saleInput.priceDecrementAmt <= _saleInput.maxPrice - _saleInput.minPrice, "Invalid price");
        }

        lastId.increment();
        uint256 _saleId = lastId.current();

        SaleInfo storage sale = sales[_saleId];
        sale.id = _saleId;
        sale.projectId = _project.id;
        sale.token = _project.token;
        sale.tokenId = _saleInput.tokenId;
        sale.amount = _saleInput.amount;
        sale.dutchMaxPrice = _saleInput.maxPrice;
        sale.dutchMinPrice = _saleInput.minPrice;
        sale.priceDecrementAmt = _saleInput.priceDecrementAmt;
        sale.fixedPrice = _saleInput.fixedPrice;

        if (_project.isPack) {
            //slither-disable-next-line unused-return
            _currentSalesInPack[_project.id].add(_saleId);
        }

        saleIdsOfProject[_project.id].push(_saleId);
        //slither-disable-next-line unused-return
        _saleIdNotCloseOfProject[_project.id].add(_saleId);

        if (_project.isSingle) {
            if (_isCreateNewToken) {
                sale.tokenId = _isSetRoyalty ? 
                IOSB721(_project.token).mintWithRoyalty(address(this), _saleInput.tokenUri, _saleInput.royaltyReceiver, _saleInput.royaltyFeeNumerator) : 
                IOSB721(_project.token).mint(address(this), _saleInput.tokenUri);
            } else {
                IOSB721(_project.token).safeTransferFrom(_caller, address(this), _saleInput.tokenId);
            }
        } else {
            if (_isCreateNewToken) {
                sale.tokenId = _isSetRoyalty ? 
                IOSB1155(_project.token).mintWithRoyalty(address(this), _saleInput.amount, _saleInput.tokenUri, _saleInput.royaltyReceiver, _saleInput.royaltyFeeNumerator) : 
                IOSB1155(_project.token).mint(address(this), _saleInput.amount, _saleInput.tokenUri);
            } else {
                IOSB1155(_project.token).safeTransferFrom(_caller, address(this), _saleInput.tokenId, _saleInput.amount, "");
            }
        }

        return _saleId;
    }

    /**
     * @notice Distribute NFTs to buyers waiting or transfer remaining NFTs to project owner and close sale
     * @param _closeLimit Loop limit
     * @param _project Project info
     * @param _sale Sale info
     * @param _totalBuyersWaitingDistribution Total buyers waiting distribution
     * @param _isGive NFTs is give
     */
    function close(uint256 _closeLimit, ProjectInfo memory _project, SaleInfo memory _sale, uint256 _totalBuyersWaitingDistribution, bool _isGive) external onlyProject nonReentrant returns (uint256) {
        address[] memory buyersWaiting = getBuyersWaitingDistribution(_sale.id);
        for (uint256 i = 0; i < buyersWaiting.length; i++) {
            _totalBuyersWaitingDistribution++;

            Bill memory billInfo = getBill(_sale.id, buyersWaiting[buyersWaiting.length - (i + 1)]);
            buyersWaitingDistributions[_sale.id].pop();
            if (getBuyersWaitingDistribution(_sale.id).length == 0) {
                _closeSale(_sale.id);
            }

            // transfer profits
            if (_isGive || _project.sold < _project.minSales) {
                Helper.safeTransferNative(billInfo.account, billInfo.royaltyFee + billInfo.superAdminFee + billInfo.sellerFee);
            } else {
                Helper.safeTransferNative(billInfo.royaltyReceiver, billInfo.royaltyFee);
                Helper.safeTransferNative(setting.getSuperAdmin(), billInfo.superAdminFee);
                Helper.safeTransferNative(project.getManager(_project.id), billInfo.sellerFee);
            }

            // Transfer tokens
            address receiver = (_project.minSales > 0 && _project.sold < _project.minSales && !_isGive) ? _project.manager : billInfo.account;
            _project.isSingle ? 
            IOSB721(_project.token).safeTransferFrom(address(this), receiver, _sale.tokenId) : 
            IOSB1155(_project.token).safeTransferFrom(address(this), receiver, _sale.tokenId, billInfo.amount, "");

            if (_totalBuyersWaitingDistribution == _closeLimit) break;
        }

        return _totalBuyersWaitingDistribution;
    }

    /**
     * @notice Set ended sale
     * @param _saleId From sale ID
     */
    function setCloseSale(uint256 _saleId) external onlyProject {
        _closeSale(_saleId);
        emit SetCloseSale(_saleId, true);
    }

    /**
     * @notice Reset amount NFTs from sale ID
     * @param _saleId From sale ID
     */
    function resetAmountSale(uint256 _saleId) external onlyProject {
        uint256 oldAmount = sales[_saleId].amount;
        sales[_saleId].amount = 0;
        emit ResetAmountSale(_saleId, oldAmount);
    }

    /**
     * @notice Only use for sale approve a certain token to Project
     * @param _token Address of NFT token
     */
    function approveForAll(address _token) external onlyProject {
        IOSB721(_token).setApprovalForAll(address(project), true);
    }

    // ============ FUND RECEIVER-ONLY FUNCTIONS =============

    /**
     * @notice Update new MerkleRoot from sale ID
     * @param _saleId From sale ID
     * @param _rootHash New MerkleRoot
     */
    function setMerkleRoot(uint256 _saleId, bytes32 _rootHash) external {
        require(_msgSender() == project.opFundReceiver(), "Caller is not the opFundReceiver");
        require(_saleId <= lastId.current(), "Invalid sale");
        merkleRoots[_saleId] = _rootHash;
        emit SetMerkleRoot(_saleId, _rootHash);
    }

    // ============ OTHER FUNCTIONS =============

    /**
     * @notice Show current dutch price
     * @param _startTime Sale start time
     * @param _endTime Sale end time
     * @param _maxPrice Max price for dutch auction
     * @param _minPrice Min price for dutch auction
     * @param _priceDecrementAmt Price decrement amt for dutch auction
     */ 
    function getCurrentDutchPrice(uint256 _startTime, uint256 _endTime, uint256 _maxPrice, uint256 _minPrice, uint256 _priceDecrementAmt) public view returns (uint256) {
        uint256 decrement = (_maxPrice - _minPrice) / _priceDecrementAmt;
        uint256 timeToDecrementPrice = (_endTime - _startTime) / decrement;

        uint256 currentTimestamp = block.timestamp;
        if (currentTimestamp <= _startTime) return _maxPrice;

        //slither-disable-next-line divide-before-multiply
        uint256 numDecrements = (currentTimestamp - _startTime) / timeToDecrementPrice;
        uint256 decrementAmt = _priceDecrementAmt * numDecrements;

        if (decrementAmt > _maxPrice || _maxPrice - decrementAmt <= _minPrice) {
            return _minPrice;
        }

        return _maxPrice - decrementAmt;
    }

    /**
     * @notice Show all sale IDs from project ID
     * @param _projectId From project ID
     */ 
    function getSaleIdsOfProject(uint256 _projectId) public view returns (uint256[] memory) {
        return saleIdsOfProject[_projectId];
    }

    /**
     * @notice Show all addresses of buyers waiting for distribution from sale ID
     * @param _saleId From sale ID
     */ 
    function getBuyersWaitingDistribution(uint256 _saleId) public view returns (address[] memory) {
        return buyersWaitingDistributions[_saleId];       
    }

    /**
     * @notice Show the bill info of the buyer
     * @param _saleId From sale ID
     * @param _buyer Buyer address
     */ 
    function getBill(uint256 _saleId, address _buyer) public view returns (Bill memory) {
        return bills[_saleId][_buyer];
    }

    /**
     * @notice Show royalty info on the token
     * @param _projectId From project ID
     * @param _tokenId Token ID
     * @param _salePrice Sale price
     */ 
    function getRoyaltyInfo(uint256 _projectId, uint256 _tokenId, uint256 _salePrice) public view returns (address, uint256) {
        ProjectInfo memory _project = project.getProject(_projectId);
        if (nftChecker.isImplementRoyalty(_project.token)) {
            (address receiver, uint256 amount) = _project.isSingle ? 
            IOSB721(_project.token).royaltyInfo(_tokenId, _salePrice) : 
            IOSB1155(_project.token).royaltyInfo(_tokenId, _salePrice);

            //slither-disable-next-line incorrect-equality
            if (receiver == address(0)) return (address(0), 0);
            return (receiver, amount);
        }
        return (address(0), 0);
    }
    
    /**
     * @notice Show royalty fee
     * @param _projectId From project ID
     * @param _tokenIds Foken ID
     * @param _salePrices Sales prices
     */ 
    function getTotalRoyalFee(uint256 _projectId, uint256[] memory _tokenIds, uint256[] memory _salePrices) public view returns (uint256) {
        uint256 total;
        ProjectInfo memory _project = project.getProject(_projectId);
        if (_project.id == 0) return 0;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            (, uint256 royaltyAmount) = _project.isSingle ? 
            IOSB721(_project.token).royaltyInfo(_tokenIds[i], _salePrices[i]) : 
            IOSB1155(_project.token).royaltyInfo(_tokenIds[i], _salePrices[i]);
            total += royaltyAmount;
        }
        return total;
    }

    /**
     * @notice Show sales info from project ID
     * @param _projectId From project ID
     */ 
    function getSalesProject(uint256 _projectId) external view returns (SaleInfo[] memory) {
        uint256[] memory saleIds = getSaleIdsOfProject(_projectId);
        SaleInfo[] memory sales_ = new SaleInfo[](saleIds.length);
        for (uint256 i = 0; i < saleIds.length; i++) {
            sales_[i] = sales[saleIds[i]];
        }
        return sales_;
    }

    /**
     * @notice Show all addresses buyers from sale ID
     * @param _saleId From sale ID
     */ 
    function getBuyers(uint256 _saleId) external view returns (address[] memory) {
        return buyers[_saleId];
    }

    /**
     * @notice Show sale info from sale ID
     * @param _saleId From sale ID
     */ 
    function getSaleById(uint256 _saleId) external view returns (SaleInfo memory) {
        return sales[_saleId];
    }

    /**
     * @notice Show length sale ids not close from project ID
     * @param _projectId From sale ID
     */
    function getSaleNotCloseLength(uint256 _projectId) external view returns (uint256) {
        return _saleIdNotCloseOfProject[_projectId].length();
    }

    /**
     * @notice Show sale ID not close by index from project ID
     * @param _projectId From sale ID
     * @param _index From sale ID
     */
    function getSaleIdNotCloseByIndex(uint256 _projectId, uint256 _index) public view returns (uint256) {
        return _saleIdNotCloseOfProject[_projectId].at(_index);
    }

    /**
     * @notice Get the list of sale ID in one pack
     * @param _projectId From sale ID
     */
    function currentSalesInPack(uint256 _projectId) public view returns (uint256[] memory) {
        return _currentSalesInPack[_projectId].values();
    }

    /**
     * @notice Buy NFT from sale ID
     * @param _saleId From sale ID
     * @param _merkleProof Merkle proof
     * @param _amount Token amount
     */
    function buy(uint256 _saleId, bytes32[] memory _merkleProof, uint256 _amount) external payable nonReentrant {
        SaleInfo storage saleInfo = sales[_saleId];
        require(project.isActiveProject(saleInfo.projectId), "Project is inactive");

        ProjectInfo memory projectInfo = project.getProject(saleInfo.projectId);
        require(!projectInfo.isPack, "Project is pack");
        require(MerkleProofUpgradeable.verify(_merkleProof, merkleRoots[_saleId], keccak256(abi.encodePacked(_msgSender()))), "Invalid winner");
        require(!sales[_saleId].isSoldOut, "Sold out");
        require(_amount > 0 && _amount <= saleInfo.amount, "Invalid amount");


        saleInfo.amount -= _amount;
        saleInfo.isSoldOut = saleInfo.amount == 0;
        projectInfo.sold += _amount;

        if (!bought[_saleId][_msgSender()]) {
            bought[_saleId][_msgSender()] = true;
            buyers[_saleId].push(_msgSender());
        }

        if (projectInfo.isInstantPayment) {
            if (saleInfo.isSoldOut) _closeSale(_saleId);
            if (projectInfo.sold == projectInfo.amount) project.end(projectInfo.id);
            projectInfo.isSingle ? IOSB721(projectInfo.token).safeTransferFrom(address(this), _msgSender(), saleInfo.tokenId) :
            IOSB1155(projectInfo.token).safeTransferFrom(address(this), _msgSender(), saleInfo.tokenId, _amount, "");
        }

        project.setSoldQuantityToProject(saleInfo.projectId, projectInfo.sold);
        (, uint256 total)= _calculateSale(saleInfo.projectId, _saleId, _amount);
        // Transfer residual paid token back to user
        if (msg.value > total) {
            Helper.safeTransferNative(_msgSender(), msg.value - (total));
        }
        _sharing(projectInfo, saleInfo, _amount, total);
    }

    /**
     * @notice Buy NFT from project ID
     * @param _projectId From project ID
     * @param _merkleProof Merkle proof
     * @param _amount Token amount
     */
    function buyPack(uint256 _projectId, bytes32[] memory _merkleProof, uint256 _amount) external payable nonReentrant {
        require(project.isActiveProject(_projectId), "Project is inactive");
        require(MerkleProofUpgradeable.verify(_merkleProof, project.getMerkleRoots(_projectId), keccak256(abi.encodePacked(_msgSender()))), "Invalid winner");

        ProjectInfo memory projectInfo = project.getProject(_projectId);
        require(projectInfo.isPack, "Project is not pack");

        uint256 available = _currentSalesInPack[_projectId].length();
        require(available > 0, "Sold out");
        require(_amount > 0 && _amount <= available, "Invalid amount");

        bool shouldRandom = _amount < available;
        (uint256 price, uint256 total) = _calculateSale(_projectId, _currentSalesInPack[_projectId].at(0), _amount);

        for (uint256 i = 0; i < _amount; i++) {
            uint256 selectedIndex = 0;
            if (shouldRandom) {
                //slither-disable-next-line reentrancy-no-eth,unused-return
                randomizer.getRandomNumber();
                selectedIndex = randomizer.random(i) % _currentSalesInPack[_projectId].length();
            }

            uint256 saleId = _currentSalesInPack[_projectId].at(selectedIndex);
            SaleInfo storage saleInfo = sales[saleId];
            
            //slither-disable-next-line unused-return 
            _currentSalesInPack[_projectId].remove(saleId);
            saleInfo.amount = 0;
            saleInfo.isSoldOut = true;

            bought[saleInfo.id][_msgSender()] = true;
            buyers[saleInfo.id].push(_msgSender());

            if (projectInfo.isInstantPayment) {
                _closeSale(saleInfo.id);
                IOSB721(projectInfo.token).safeTransferFrom(address(this), _msgSender(), saleInfo.tokenId);
            }

            _sharing(projectInfo, saleInfo, 1, price);
        }

        projectInfo.sold += _amount;
        project.setSoldQuantityToProject(_projectId, projectInfo.sold);
        if (projectInfo.isInstantPayment && projectInfo.sold == projectInfo.amount) project.end(_projectId);
        // Transfer residual paid token back to user
        if (msg.value > total) {
            Helper.safeTransferNative(_msgSender(), msg.value - (total));
        }
    }

    /**
     * @notice Calculate sale item price, total should pay and proccess residual amount
     * @param _projectId Project ID
     * @param _saleId Sale ID
     * @param _amount amount of token in each Sale or Pack
     */
    function _calculateSale(uint256 _projectId, uint256 _saleId, uint256 _amount) private returns (uint256, uint256) {
        ProjectInfo memory projectInfo = project.getProject(_projectId);
        SaleInfo memory saleInfo = sales[_saleId];

        uint256 price = 0;
        if (projectInfo.isFixed) {
            price = saleInfo.fixedPrice;
        } else {
            price = getCurrentDutchPrice(projectInfo.saleStart, projectInfo.saleEnd, saleInfo.dutchMaxPrice, saleInfo.dutchMinPrice, saleInfo.priceDecrementAmt);
        }


        uint256 total = price * _amount;
        //slither-disable-next-line incorrect-equality
        require(projectInfo.isFixed ? msg.value == total : msg.value >= total, "Invalid value");

        return (price, total);
    }

    /**
     * @notice Support sharing profit or log bill
     * @param _project Project info
     * @param _sale Sale info
     * @param _amount Token amount
     * @param _payAmount Minimum amount that pay for sale
     */ 
    function _sharing(ProjectInfo memory _project, SaleInfo memory _sale, uint256 _amount, uint256 _payAmount) private {
        uint256 supperAdminProfit = 0; 
        uint256 royaltyProfit = 0;
        uint256 sellerProfit = 0;

        // Calculate royal fee
        (address royaltyReceiver, uint256 royaltyFee) = getRoyaltyInfo(_project.id, _sale.tokenId, _payAmount);
        royaltyProfit = royaltyFee;

        // Calculate fee and profit
        if (_project.isCreatedByAdmin) {
            supperAdminProfit = _payAmount - royaltyProfit;
        } else {
            // admin fee
            supperAdminProfit = _getPriceToPercent(_payAmount, _project.profitShare);
            sellerProfit = _payAmount - supperAdminProfit;
            if (royaltyProfit > sellerProfit) royaltyProfit = sellerProfit;
            sellerProfit -= royaltyProfit;
        }

        // Transfer fee and profit
        if (_project.minSales == 0 && _project.isInstantPayment) {
            if (royaltyProfit > 0) Helper.safeTransferNative(royaltyReceiver, royaltyProfit);
            if (supperAdminProfit > 0) Helper.safeTransferNative(setting.getSuperAdmin(), supperAdminProfit);
            if (sellerProfit > 0) Helper.safeTransferNative(project.getManager(_project.id), sellerProfit);
        } else {
            Bill storage billInfo = bills[_sale.id][_msgSender()];
            billInfo.saleId = _sale.id;
            billInfo.amount += _amount;
            billInfo.royaltyReceiver = royaltyReceiver;
            billInfo.royaltyFee += royaltyProfit;
            billInfo.superAdminFee += supperAdminProfit;
            billInfo.sellerFee += sellerProfit;
            if (billInfo.account != _msgSender()) {
                billInfo.account = _msgSender();
                project.addTotalBuyersWaitingDistribution(_project.id);
                buyersWaitingDistributions[_sale.id].push(_msgSender());
            }
        }

        emit Buy(_msgSender(), _sale.id, _sale.tokenId, _amount, _project.profitShare, supperAdminProfit, royaltyProfit, sellerProfit);
    }

    /**
     * @notice Support calculate price to percent
     */
    function _getPriceToPercent(uint256 _price, uint256 _percent) private pure returns (uint256) {
        return (_price * _percent) / (100 * WEIGHT_DECIMAL);
    }

    /**
     * @notice Close sale
     * @param _saleId Sale ID
     */
    function _closeSale(uint256 _saleId) private {
        sales[_saleId].isClose = true;
        //slither-disable-next-line unused-return
        _saleIdNotCloseOfProject[sales[_saleId].projectId].remove(_saleId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal onlyInitializing {
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProofUpgradeable {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

library Helper {
	function safeTransferNative(address _to, uint256 _value) internal {
		(bool success, ) = _to.call { value: _value }(new bytes(0));
		require(success, "SafeTransferNative: transfer failed");
	}
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface ISetting {
    function checkOnlySuperAdmin(address _caller) external view;
    function checkOnlyAdmin(address _caller) external view;
    function checkOnlySuperAdminOrController(address _caller) external view;
    function checkOnlyController(address _caller) external view;
    function isAdmin(address _account) external view returns(bool);
    function isSuperAdmin(address _account) external view returns(bool);
    function getSuperAdmin() external view returns(address);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IProject {
    function isManager(uint256 _projectId, address _account) external view returns (bool);
    function opFundReceiver() external view returns (address);
    function getMerkleRoots(uint256 _projectId) external view returns (bytes32);
    function getProject(uint256 _projectId) external view returns (ProjectInfo memory);
    function getManager(uint256 _projectId) external view returns (address);
    function getTotalBuyersWaitingDistribution(uint256 _projectId) external view returns (uint256);
    function addTotalBuyersWaitingDistribution (uint256 _projectId) external;
    function setSoldQuantityToProject(uint256 _projectId, uint256 _quantity) external;
    function end(uint256 _projectId) external;
    function isActiveProject(uint256 _projectId) external view returns (bool);
}

struct ProjectInfo {
    uint256 id;
    bool isCreatedByAdmin;
    bool isInstantPayment;
    bool isPack;
    bool isSingle;
    bool isFixed;
    address manager;
    address token;
    uint256 amount;
    uint256 minSales;
    uint256 sold;
    uint256 profitShare;
    uint256 saleStart;
    uint256 saleEnd;
    ProjectStatus status;
}

struct InitializeInput {
    address setting;
    address nftChecker;
    address osbFactory;
    uint256 createProjectFee;
    uint256 activeProjectFee;
    uint256 saleCreateLimit;
    uint256 closeLimit;
    uint256 opFundLimit;
    address opFundReceiver;
}

struct ProjectInput {
    address token;
    string tokenName;
    string tokenSymbol;
    string uri;
    bool isPack;
    bool isSingle;
    bool isFixed;
    bool isInstantPayment;
    address royaltyReceiver;
    uint96 royaltyFeeNumerator;
    uint256 minSales;
    uint256 fixedPricePack;
    uint256 maxPricePack;
    uint256 minPricePack;
    uint256 priceDecrementAmtPack;
    uint256 saleStart;
    uint256 saleEnd;
}

enum ProjectStatus {
    INACTIVE,
    STARTED,
    ENDED
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./IProject.sol";

interface ISale {
    function getSalesProject(uint256 projectId) external view returns (SaleInfo[] memory);
    function getSaleIdsOfProject(uint256 _projectId) external view returns (uint256[] memory);
    function getBuyers(uint256 _saleId) external view returns (address[] memory);
    function setCloseSale(uint256 _saleId) external;
    function resetAmountSale(uint256 _saleId) external;
    function approveForAll(address _token) external;
    function close(uint256 closeLimit, ProjectInfo memory _project, SaleInfo memory _sale, uint256 _totalBuyersWaitingClose, bool _isGive) external returns (uint256);
    function createSale(address _caller, bool _isCreateNewToken, bool _isSetRoyalty, ProjectInfo memory _project, SaleInput memory _saleInput) external returns (uint256);
    function getSaleById(uint256 _saleId) external view returns (SaleInfo memory);
    function getSaleNotCloseLength(uint256 _projectId) external view returns (uint256);
    function getSaleIdNotCloseByIndex(uint256 _projectId, uint256 _index) external view returns (uint256);
}

struct SaleInfo {
    uint256 id;
    uint256 projectId;
    address token;
    uint256 tokenId;
    uint256 fixedPrice;
    uint256 dutchMaxPrice;
    uint256 dutchMinPrice;
    uint256 priceDecrementAmt;
    uint256 amount;
    bool isSoldOut;
    bool isClose;
}

struct Bill {
    uint256 saleId;
    address account;
    address royaltyReceiver;
    uint256 royaltyFee;
    uint256 superAdminFee;
    uint256 sellerFee;
    uint256 amount;
}

struct SaleInput {
    uint256 tokenId;
    uint256 amount;
    string  tokenUri;
    address royaltyReceiver;
    uint96  royaltyFeeNumerator;
    uint256 fixedPrice;
    uint256 maxPrice;
    uint256 minPrice;
    uint256 priceDecrementAmt;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IOSB721 is IERC721Upgradeable {
    function mint(address _to, string memory _tokenUri) external returns (uint256);
    function mintWithRoyalty(address _to, string memory _tokenUri, address _receiverRoyaltyFee, uint96 _percentageRoyaltyFee) external returns (uint256);
    function setController(address _account, bool _allow) external;
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IOSB1155 is IERC1155Upgradeable {
    function mint(address _to, uint256 _amount, string memory _tokenUri) external returns (uint256);
    function mintWithRoyalty(address _to, uint256 _amount, string memory _tokenUri, address _receiverRoyaltyFee, uint96 _percentageRoyaltyFee) external returns (uint256);
    function setController(address _account, bool _allow) external;
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256);
}

// SPDX-License-Identifier: MIT 
pragma solidity 0.8.16; 

interface INFTChecker { 
    function isERC1155(address nftAddress) external view returns (bool);
    function isERC721(address nftAddress) external view returns (bool);
    function isERC165(address nftAddress) external view returns (bool);
    function isNFT(address _contractAddr) external view returns (bool);
    function isImplementRoyalty(address nftAddress) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IRandomizer {
    // Returns a request ID for the random number. This should be kept and mapped to whatever the contract
    // is tracking randoms for.
    // Admin only.
    function getRandomNumber() external returns(bytes32);

    function random(uint256 _seed) external returns(uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/Sale.sol";

contract $Sale is Sale {
    constructor() {}

    function $__ERC1155Holder_init() external {
        return super.__ERC1155Holder_init();
    }

    function $__ERC1155Holder_init_unchained() external {
        return super.__ERC1155Holder_init_unchained();
    }

    function $__ERC1155Receiver_init() external {
        return super.__ERC1155Receiver_init();
    }

    function $__ERC1155Receiver_init_unchained() external {
        return super.__ERC1155Receiver_init_unchained();
    }

    function $__ERC165_init() external {
        return super.__ERC165_init();
    }

    function $__ERC165_init_unchained() external {
        return super.__ERC165_init_unchained();
    }

    function $__ERC721Holder_init() external {
        return super.__ERC721Holder_init();
    }

    function $__ERC721Holder_init_unchained() external {
        return super.__ERC721Holder_init_unchained();
    }

    function $__ReentrancyGuard_init() external {
        return super.__ReentrancyGuard_init();
    }

    function $__ReentrancyGuard_init_unchained() external {
        return super.__ReentrancyGuard_init_unchained();
    }

    function $__Context_init() external {
        return super.__Context_init();
    }

    function $__Context_init_unchained() external {
        return super.__Context_init_unchained();
    }

    function $_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function $_msgData() external view returns (bytes memory) {
        return super._msgData();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/INFTChecker.sol";

abstract contract $INFTChecker is INFTChecker {
    constructor() {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/IOSB1155.sol";

abstract contract $IOSB1155 is IOSB1155 {
    constructor() {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/IOSB721.sol";

abstract contract $IOSB721 is IOSB721 {
    constructor() {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/IProject.sol";

abstract contract $IProject is IProject {
    constructor() {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/IRandomizer.sol";

abstract contract $IRandomizer is IRandomizer {
    constructor() {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/ISale.sol";

abstract contract $ISale is ISale {
    constructor() {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/ISetting.sol";

abstract contract $ISetting is ISetting {
    constructor() {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/libraries/Helper.sol";

contract $Helper {
    constructor() {}

    function $safeTransferNative(address _to,uint256 _value) external {
        return Helper.safeTransferNative(_to,_value);
    }
}