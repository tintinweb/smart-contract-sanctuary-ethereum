//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./interfaces/ISetting.sol";
import "./interfaces/INFTChecker.sol";
import "./interfaces/IOSBFactory.sol";
import "./interfaces/ISale.sol";
import "./interfaces/IProject.sol";
import "./interfaces/IOSB721.sol";
import "./interfaces/IOSB1155.sol";
import "./interfaces/IOSBSoul.sol";
import "./libraries/Helper.sol";

contract Project is IProject, ContextUpgradeable, ReentrancyGuardUpgradeable {
    ISale public sale;
    ISetting public setting;
    INFTChecker public nftChecker;
    IOSBFactory public osbFactory;
    IOSBSoul public osbSoul;

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter public lastId;

    uint256 public createProjectFee;    /// Fee for publish project 
    uint256 public opFundLimit;         /// Limit balance for OpReceiver 
    uint256 public saleCreateLimit;     /// Limit create sales when publish the project
    uint256 public profitShareMinimum;  /// Profit sharing on each product sale batch of the end-users
    uint256 public closeLimit;          /// Limit loop counted when close project
    address public opFundReceiver;      /// Address receive a portion of the suport projects funds work
    address public serviceFundReceiver; /// Address receive funds from publish or allow the active project

    /**
     * @dev Keep track of project from projectId
     */
    mapping(uint256 => ProjectInfo) private projects;

    /**
     * @dev Keep track of total Buyers waiting for distribution from projectId
     */
    mapping(uint256 => uint256) private totalBuyersWaitingDistributions;

    /**
     * @dev Keep track of merkleRoot from project ID
     */
    mapping(uint256 => bytes32) private merkleRoots;

    // ============ EVENTS ============

    /// @dev Emit an event when the contract is deployed
    event ContractDeployed(address indexed serviceFundReceiver, InitializeInput input);

    /// @dev Emit an event when Sale contract address is updated
    event SetSaleAddress(address indexed oldSaleAddress, address indexed newSaleAddress);

    /// @dev Emit an event when createProjectFee is updated
    event SetCreateProjectFee(uint256 indexed oldFee, uint256 indexed newFee);
    
    /// @dev Emit an event when serviceFundReceiver is updated
    event SetServiceFundReceiver(address indexed oldReceiver, address indexed newReceiver);
    
    /// @dev Emit an event when opFundReceiver is updated
    event SetOpFundReceiver(address indexed oldReceiver, address indexed newReceiver);
    
    /// @dev Emit an event when opFundLimit is updated
    event SetOpFundLimit(uint256 indexed oldLimit, uint256 indexed newLimit);
    
    /// @dev Emit an event when closeLimit is updated
    event SetCloseLimit(uint256 indexed oldLimit, uint256 indexed newLimit);

    /// @dev Emit an event when saleCreateLimit is updated
    event SetSaleCreateLimit(uint256 indexed oldLimit, uint256 indexed newLimit);

    /// @dev Emit an event when profitShareMinimum is updated
    event SetProfitShareMinimum(uint256 indexed oldValue, uint256 indexed newValue);

    /// @dev Emit an event when the manager root for a project is updated
    event SetManager(uint256 indexed projectId, address indexed oldManager, address indexed newManager);

    /// @dev Emit an event when the totalBuyersWaitingDistribution for a project is updated
    event SetTotalBuyersWaitingDistribution(uint256 indexed projectId, uint256 indexed oldTotal, uint256 indexed newTotal);

    /// @dev Emit an event when the quantity sold Sale from the project is updated
    event SetSoldQuantityToProject(uint256 indexed projectId, uint256 indexed oldQuantity, uint256 indexed newQuantity);
    
    /// @dev Emit an event when the totalSalesNotClose for a project is updated
    event SetTotalSalesNotClose(uint256 indexed projectId, uint256 indexed oldTotal, uint256 indexed newTotal);

    /// @dev Emit an event when a project is published
    event Publish(uint256 indexed projectId, bool indexed isCreatedByAdmin, address indexed token, string name, string symbol, uint256[] saleIds);
    
    /// @dev Emit an event when the status of a project is updated to ENDED
    event End(uint256 indexed projectId, ProjectStatus status);
    
    /// @dev Emit an event when the project is closed
    event CloseProject(uint256 indexed projectId, bool isGive, ProjectStatus status);
    
    /// @dev Emit an event when withdrawn fund
    event WithdrawnFund(address indexed serviceFundReceiver, uint256 indexed value);

    /// @dev Emit an event when the MerkleRoot a Project is updated
    event SetMerkleRoot(uint256 indexed projectId, bytes32 rootHash);

    /// @dev Emit an event when adding Sales to the Project available
    event AddSales(uint256 indexed projectId, uint256[] saleIds);
    
    /**
     * @notice Setting states initial when deploy contract and only called once
     * @param _input.setting            -> Setting contract address
     * @param _input.nftChecker         -> NftChecker contract address
     * @param _input.osbFactory         -> OsbFactory contract address
     * @param _input.osbSoul            -> OSBSoul contract address
     * @param _input.createProjectFee   -> Create project fee
     * @param _input.profitShareMinimum -> Profit sharing on each product sale batch of the end-users
     * @param _input.saleCreateLimit    -> Limit create sales when publish the project
     * @param _input.closeLimit         -> Limit counted loop when close project
     * @param _input.opFundLimit        -> Limit balance OpReceiver
     * @param _input.opFundReceiver     -> OpReceiver address
     */
    function initialize(InitializeInput memory _input) external initializer {
        require(_input.setting != address(0), "Invalid setting");
        require(_input.nftChecker != address(0), "Invalid nftChecker");
        require(_input.osbFactory != address(0), "Invalid osbFactory");
        require(_input.osbSoul != address(0), "Invalid osbSoul");
        require(_input.opFundReceiver != address(0), "Invalid opFundReceiver");
        require(_input.saleCreateLimit > 0, "Invalid saleCreateLimit");
        require(_input.closeLimit > 0, "Invalid closeLimit");
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        setting = ISetting(_input.setting);
        nftChecker = INFTChecker(_input.nftChecker);
        osbFactory = IOSBFactory(_input.osbFactory);
        osbSoul = IOSBSoul(_input.osbSoul);
        createProjectFee = _input.createProjectFee;
        profitShareMinimum = _input.profitShareMinimum;
        saleCreateLimit = _input.saleCreateLimit;
        closeLimit = _input.closeLimit;
        opFundLimit = _input.opFundLimit;
        opFundReceiver = _input.opFundReceiver;
        serviceFundReceiver = setting.getSuperAdmin();
        emit ContractDeployed(serviceFundReceiver, _input);
    }

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    /**
     * @dev To check the project is valid
     */
    modifier projectIsValid(uint256 _projectId) {
        require(_projectId == projects[_projectId].id, "Invalid project");
        _;
    }

    /**
     * @dev To check caller is super admin
     */
    modifier onlySuperAdmin() {
        setting.checkOnlySuperAdmin(_msgSender());
        _;
    }

    /**
     * @dev To check caller is admin
     */
    modifier onlyAdmin() {
        setting.checkOnlyAdmin(_msgSender());
        _;
    }

    /**
     * @dev To check caller is manager
     */
    modifier onlyManager(uint256 _projectId) {
        require(isManager(_projectId, _msgSender()), "Caller is not the manager");
        _;
    }

    /**
     * @dev To check caller is Sale contract
     */
    modifier onlySale() {
        require(_msgSender() == address(sale), "Caller is not the sale");
        _;
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS =============

    /**
     * @notice 
     * Set the new Sale contract address
     * Caution need to discuss with the dev before updating the new state
     * 
     * @param _sale New Sale contract address
     */
    function setSaleAddress(address _sale) external onlySuperAdmin {
        require(_sale != address(0), "Invalid Sale address");
        address oldSaleAddress = address(sale);
        sale = ISale(_sale);
        emit SetSaleAddress(oldSaleAddress, _sale);
    }

    /**
     * @notice Set the new receiver to receive funds from publish or allow the active project
     * @param _account New receiver
     */
    function setServiceFundReceiver(address _account) external onlySuperAdmin {
        require(_account != address(0), "Invalid account");
        address oldReceiver = serviceFundReceiver;
        serviceFundReceiver = _account;
        emit SetServiceFundReceiver(oldReceiver, _account);
    }

    /**
     * @notice Set the new receiver to receive a portion of the publishing projects funds for the set Merkle Root gas fee
     * @param _account New receiver
     */
    function setOpFundReceiver(address _account) external onlySuperAdmin {
        require(_account != address(0), "Invalid account");
        address oldReceiver = opFundReceiver;
        opFundReceiver = _account;
        emit SetOpFundReceiver(oldReceiver, _account);
    }

    /**
     * @notice Set the new publish project fee
     * @param _fee New fee
     */
    function setCreateProjectFee(uint256 _fee) external onlySuperAdmin {
        require(_fee > 0, "Invalid fee");
        uint256 oldFee = createProjectFee;
        createProjectFee = _fee;
        emit SetCreateProjectFee(oldFee, _fee);
    }

    /**
     * @notice Set the new limit balance for OpReceiver 
     * @param _limit New limit
     */
    function setOpFundLimit(uint256 _limit) external onlySuperAdmin {
        require(_limit > 0, "Invalid limit");
        uint256 oldLimit = opFundLimit;
        opFundLimit = _limit;
        emit SetOpFundLimit(oldLimit, _limit);
    }

    /**
     * @notice Set the new saleCreateLimit
     * @param _limit New limit
     */
    function setSaleCreateLimit(uint256 _limit) external onlySuperAdmin {
        require(_limit > 0, "Invalid limit");
        uint256 oldLimit = saleCreateLimit;
        saleCreateLimit = _limit;
        emit SetSaleCreateLimit(oldLimit, _limit);
    }

    /**
     * @notice Set the new profitShareMinimum
     * @param _minimum New minimum value
     */
    function setProfitShareMinimum(uint256 _minimum) external onlySuperAdmin {
        uint256 oldValue = profitShareMinimum;
        profitShareMinimum = _minimum;
        emit SetProfitShareMinimum(oldValue, _minimum);
    }

    // ============ ADMIN-ONLY FUNCTIONS =============

    /**
     * @notice Set the new loop limit counted when close project
     * @param _limit New limit
     */
    function setCloseLimit(uint256 _limit) external onlyAdmin {
        require(_limit > 0, "Invalid limit");
        uint256 oldLimit = closeLimit;
        closeLimit = _limit;
        emit SetCloseLimit(oldLimit, _limit);
    }

    /**
     * @notice Set the new manager for project
     * @param _projectId Project ID
     * @param _account New manager
     */
    function setManager(uint256 _projectId, address _account) external projectIsValid(_projectId) onlyAdmin {
        require(_account != address(0), "Invalid account");
        require(_account != projects[_projectId].manager, "Account already exists");
        address oldManager = projects[_projectId].manager;
        projects[_projectId].manager = _account;
        emit SetManager(_projectId, oldManager, _account);
    }

    // ============ MANAGER-ONLY FUNCTIONS =============

    /**
     * @notice Distribute NFTs to buyers waiting or transfer remaining NFTs to project owner and close the project
     * @param _projectId From project ID
     * @param _saleIds List sale IDs to need close
     * @param _isGive NFTs is give
     */
    function closeProject(uint256 _projectId, uint256[] memory _saleIds, bool _isGive) external nonReentrant onlyManager(_projectId) {
        uint256 totalBuyersWaitingDistribution;
        uint256 loopCounted = totalBuyersWaitingDistributions[_projectId] + _saleIds.length;
        uint256 _closeLimit = loopCounted > closeLimit ? closeLimit : loopCounted;
        ProjectInfo memory _project = projects[_projectId];
        if (_project.isInstantPayment) require(!_isGive, "Invalid softCap");
        require(block.timestamp > _project.saleEnd && _project.status != ProjectStatus.ENDED, "Invalid project");

        uint256 _count = 0;
        for (uint256 i = 0; i < _saleIds.length; i++) {
            if (totalBuyersWaitingDistribution + _count >= _closeLimit) break;

            SaleInfo memory saleInfo = sale.getSaleById(_saleIds[i]);
            require(saleInfo.projectId == _projectId && !saleInfo.isClose, "Invalid sale id");

            if (sale.getBuyers(saleInfo.id).length == 0) {
                _count++;
                sale.setCloseSale(saleInfo.id);
                _project.isSingle ? IOSB721(_project.token).safeTransferFrom(address(sale), _project.manager, saleInfo.tokenId) :
                IOSB1155(_project.token).safeTransferFrom(address(sale), _project.manager, saleInfo.tokenId, saleInfo.amount, "");
                continue;
            } else if (!_project.isSingle && saleInfo.amount > 0) {
                IOSB1155(_project.token).safeTransferFrom(address(sale), _project.manager, saleInfo.tokenId, saleInfo.amount, "");
                sale.resetAmountSale(saleInfo.id);
            }

            if (_project.isInstantPayment) {
                _count++;
                sale.setCloseSale(saleInfo.id);
                continue;
            }
            
            totalBuyersWaitingDistribution = sale.close(_closeLimit - _count, _project, saleInfo, totalBuyersWaitingDistribution, _isGive);
        }
        totalBuyersWaitingDistributions[_projectId] -= totalBuyersWaitingDistribution;
        if (sale.getSaleNotCloseLength(_projectId) == 0) projects[_projectId].status = ProjectStatus.ENDED;
        
        emit CloseProject(_projectId, _isGive, projects[_projectId].status);
    }

    // ============ SALE-ONLY FUNCTIONS =============

    /**
     * @notice Set the new quantity sold Sale from the project 
     * @param _projectId Project ID
     * @param _quantity New quantity
     */
    function setSoldQuantityToProject(uint256 _projectId, uint256 _quantity) external projectIsValid(_projectId) onlySale {
        uint256 oldQuantiry = projects[_projectId].sold;
        projects[_projectId].sold = _quantity;
        emit SetSoldQuantityToProject(_projectId, oldQuantiry, _quantity);
    }

    /**
     * @notice Set the new total buyers waiting distribution from the project
     * @param _projectId Project ID
     */
    function addTotalBuyersWaitingDistribution(uint256 _projectId) external projectIsValid(_projectId) onlySale {
        totalBuyersWaitingDistributions[_projectId]++;
    }

    /**
     * @notice Set ENDED status for project
     * @param _projectId Project ID
     */
    function end(uint256 _projectId) external projectIsValid(_projectId) onlySale {
        projects[_projectId].status = ProjectStatus.ENDED;
        emit End(_projectId, ProjectStatus.ENDED);
    }

    // ============ FUND RECEIVER-ONLY FUNCTIONS =============

    /**
     * @notice Update new MerkleRoot from project ID
     * @param _projectId From project ID
     * @param _rootHash New MerkleRoot
     */
    function setMerkleRoot(uint256 _projectId, bytes32 _rootHash) external {
        require(_msgSender() == opFundReceiver, "Caller is not the opFundReceiver");
        require(_projectId <= lastId.current(), "Invalid project");
        merkleRoots[_projectId] = _rootHash;
        emit SetMerkleRoot(_projectId, _rootHash);
    }

    // ============ OTHER FUNCTIONS =============

    /**
     * @notice Check account is manager of project
     * @param _projectId From project ID
     * @param _account Account need check
     */
    function isManager(uint256 _projectId, address _account) public view returns (bool) {
        if (projects[_projectId].isCreatedByAdmin) {
            return setting.isSuperAdmin(_account) || setting.isAdmin(_account) || _account == projects[_projectId].manager;
        } else {
            return _account == projects[_projectId].manager;
        }
    }
    
    /**
     * @notice Show project info
     * @param _projectId From project ID
     */ 
    function getProject(uint256 _projectId) external view returns (ProjectInfo memory) {
        return projects[_projectId];
    }

    /**
     * @notice Show current address manager of project 
     * @param _projectId From project ID
     */
    function getManager(uint256 _projectId) external view returns (address) {
        return projects[_projectId].manager;
    }

    /**
     * @notice Show total buyers waiting distribution of project
     * @param _projectId From project ID
     */
    function getTotalBuyersWaitingDistribution(uint256 _projectId) external view returns (uint256) {
        return totalBuyersWaitingDistributions[_projectId];
    }

    /**
     * @notice Show merkleRoot of project
     * @param _projectId From project ID
     */
    function getMerkleRoots(uint256 _projectId) external view returns (bytes32) {
        return merkleRoots[_projectId];
    }

    /**
     * @notice Publish a project including its Sales
     * @param _projectInput.token                 -> Token address (default zero address if not have token available)
     * @param _projectInput.tokenName             -> Token name (default "" if have token available)
     * @param _projectInput.tokenSymbol           -> Token symbol (default "" if have token available)
     * @param _projectInput.uri                   -> URI metadata (default "" if have token available)
     * @param _projectInput.isPack                -> Set true if sale with pack type
     * @param _projectInput.isSingle              -> True if token is ERC721 type else is ERC1155 type
     * @param _projectInput.isFixed               -> True if sale with Fixed price else is a Dutch price
     * @param _projectInput.isInstantPayment      -> True if when buy not waiting for distribution
     * @param _projectInput.royaltyReceiver       -> Address royalty receiver default for token (default zero address if not have token available or not create token with royalty)
     * @param _projectInput.royaltyFeeNumerator   -> Royalty percent default for token
     * @param _projectInput.minSales              -> Minimum sold (default 0 if off softcap)
     * @param _projectInput.fixedPricePack        -> Fixed price for pack
     * @param _projectInput.maxPricePack          -> Max price for dutch auction pack
     * @param _projectInput.minPricePack          -> Min price for dutch auction pack
     * @param _projectInput.priceDecrementAmtPack -> Price decrement amt for dutch auction pack
     * @param _projectInput.saleStart             -> Sale start time (default 0 if publish by end-user)
     * @param _projectInput.saleEnd               -> Sale end time (default 0 if publish by end-user)
     * @param _projectInput.profitShare           -> Profit sharing on each product sale batch of the end-users
     * @param _saleInputs.tokenId                 -> Token ID (default 0 if not have token available)
     * @param _saleInputs.amount                  -> Token amount
     * @param _saleInputs.royaltyReceiver         -> Address royalty receiver by token ID (if equal zero address will get default value)
     * @param _saleInputs.royaltyFeeNumerator     -> Royalty percent by token ID
     * @param _saleInputs.fixedPrice              -> Fixed price (default 0 if sale by Dutch type)
     * @param _saleInputs.maxPrice                -> Max price for dutch auction (default 0 if sale by Fixed type)
     * @param _saleInputs.minPrice                -> Min price for dutch auction (default 0 if sale by Fixed type)
     * @param _saleInputs.priceDecrementAmt       -> Price decrement amt for dutch auction (default 0 if sale by Fixed type)
     */
    function publish(ProjectInput memory _projectInput, SaleInput[] memory _saleInputs) external payable nonReentrant {
        address token = _projectInput.token;
        bool isCreatedByAdmin = setting.isAdmin(_msgSender());
        bool isCreateNewToken = token == address(0);
        bool isSetRoyalty = _projectInput.royaltyReceiver != address(0);

        if (!isCreatedByAdmin) {
            require(osbSoul.balanceOf(_msgSender()) > 0, "Invalid member");
        }

        require(_saleInputs.length > 0, "Sales is empty");
        require(_saleInputs.length <= saleCreateLimit, "Reached sale create Limit");
        require(msg.value == createProjectFee, "Invalid create fee");
        require(isCreatedByAdmin ? _projectInput.profitShare == 0 : _projectInput.profitShare >= profitShareMinimum, "Invalid profitShare");
        require(_projectInput.saleStart >= block.timestamp && _projectInput.saleStart < _projectInput.saleEnd, "Invalid sale time");

        if (_projectInput.minSales > 0) {
            require(!_projectInput.isInstantPayment, "Invalid isInstantPayment");
        }

        if (_projectInput.isPack) {
            require(_projectInput.isSingle, "Only single token for pack");
        }

        if (isCreateNewToken) {
            //slither-disable-next-line reentrancy-no-eth
            token = osbFactory.create(_projectInput.isSingle, _msgSender(), address(sale), _projectInput.uri, _projectInput.tokenName, _projectInput.tokenSymbol, _projectInput.royaltyReceiver, _projectInput.royaltyFeeNumerator);
        } else {
            require(_projectInput.isSingle ? nftChecker.isERC721(token) : nftChecker.isERC1155(token), "Invalid token");
        }
        
        lastId.increment();
        ProjectInfo storage project = projects[lastId.current()];
        project.id = lastId.current();
        project.isCreatedByAdmin = isCreatedByAdmin;
        project.manager = _msgSender();
        project.token = token;
        project.isSingle = nftChecker.isERC721(token);
        project.isFixed = _projectInput.isFixed;
        project.isInstantPayment = _projectInput.isInstantPayment;
        project.saleStart = _projectInput.saleStart;
        project.saleEnd = _projectInput.saleEnd;
        project.status = ProjectStatus.STARTED;
        project.minSales = _projectInput.minSales;
        project.isPack = _projectInput.isPack;
        project.profitShare = _projectInput.profitShare;

        // Create sales
        for (uint256 i = 0; i < _saleInputs.length; i++) {
            if (_projectInput.isPack) {
                if (_projectInput.isFixed) {
                    _saleInputs[i].fixedPrice = _projectInput.fixedPricePack;
                } else {
                    _saleInputs[i].maxPrice = _projectInput.maxPricePack;
                    _saleInputs[i].minPrice = _projectInput.minPricePack;
                    _saleInputs[i].priceDecrementAmt = _projectInput.priceDecrementAmtPack;
                }
            }

            project.amount += _saleInputs[i].amount;
            sale.createSale(_msgSender(), isCreateNewToken, isSetRoyalty, project, _saleInputs[i]);
        }

        require(_projectInput.minSales <= project.amount, "Invalid minSales");

        sale.approveForAll(token);
        if (address(opFundReceiver).balance < opFundLimit) Helper.safeTransferNative(opFundReceiver, msg.value);

        emit Publish(project.id, isCreatedByAdmin, project.token, _projectInput.tokenName, _projectInput.tokenSymbol, sale.getSaleIdsOfProject(project.id));
    }

    /**
     * @notice Add Sales to Project available
     * @param _projectId From project ID
     * @param _isMint If it's set to true, tokens will be minted; if it's set to false, tokens will be transferred.
     * @param _minSales Minimum sold (default 0 if off softcap)
     * @param _saleInputs.tokenId             -> Token ID (default 0 if _isMint set true)
     * @param _saleInputs.amount              -> Token amount
     * @param _saleInputs.royaltyReceiver     -> Address royalty receiver by token ID (if equal zero address will get default value)
     * @param _saleInputs.royaltyFeeNumerator -> Royalty percent by token ID
     * @param _saleInputs.fixedPrice          -> Fixed price (default 0 if sale by Dutch type)
     * @param _saleInputs.maxPrice            -> Max price for dutch auction (default 0 if sale by Fixed type)
     * @param _saleInputs.minPrice            -> Min price for dutch auction (default 0 if sale by Fixed type)
     * @param _saleInputs.priceDecrementAmt   -> Price decrement amt for dutch auction (default 0 if sale by Fixed type)
     */
    function addSales(uint256 _projectId, bool _isMint, uint256 _minSales, SaleInput[] memory _saleInputs) external projectIsValid(_projectId) onlyManager(_projectId) {
        ProjectInfo storage projectInfo = projects[_projectId];
        require(block.timestamp < projectInfo.saleStart, "Project is live");
        require(_saleInputs.length <= saleCreateLimit, "Reached sale create Limit");
        uint256[] memory saleIds = new uint256[](_saleInputs.length);

        SaleInfo memory salePackInfo;
        if (projectInfo.isPack) {
            salePackInfo = sale.getSaleById(sale.getSaleIdsOfProject(_projectId)[0]);
        }

        for (uint256 i = 0; i < _saleInputs.length; i++) {
            if (projectInfo.isPack) {
                if (projectInfo.isFixed) {
                    _saleInputs[i].fixedPrice = salePackInfo.fixedPrice;
                } else {
                    _saleInputs[i].maxPrice = salePackInfo.dutchMaxPrice;
                    _saleInputs[i].minPrice = salePackInfo.dutchMinPrice;
                    _saleInputs[i].priceDecrementAmt = salePackInfo.priceDecrementAmt;
                }
            }
            bool isSetRoyalty = _isMint && _saleInputs[i].royaltyReceiver != address(0);

            projectInfo.amount += _saleInputs[i].amount;
            saleIds[i] = sale.createSale(_msgSender(), _isMint, isSetRoyalty, projectInfo, _saleInputs[i]);
        }

        if (!projectInfo.isInstantPayment) {
            require(_minSales <= projectInfo.amount, "Invalid minSales");
            projectInfo.minSales = _minSales;
        }

        emit AddSales(_projectId, saleIds);
    }

    /**
     * @notice Withdraw all funds from the contract
     */
    function withdrawFund() external nonReentrant {
        uint256 withdrawable = address(this).balance;
        require(withdrawable > 0, "Amount exceeds balance");
        Helper.safeTransferNative(serviceFundReceiver, withdrawable);
        emit WithdrawnFund(serviceFundReceiver, withdrawable);
    }
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

// SPDX-License-Identifier: MIT 
pragma solidity 0.8.16; 

interface INFTChecker { 
    function isERC1155(address nftAddress) external view returns (bool);
    function isERC721(address nftAddress) external view returns (bool);
    function isERC165(address nftAddress) external view returns (bool);
    function isNFT(address _contractAddr) external view returns (bool);
    function isImplementRoyalty(address nftAddress) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IOSBFactory {
    function create(bool _isSingle, address _owner, address _controller, string memory _uri, string memory _name, string memory _symbol, address _defaultReceiverRoyalty, uint96 _defaultPercentageRoyalty) external returns (address);
}

struct TokenInfo {
    address owner;
    address token;
    address defaultReceiverRoyalty;
    uint96 defaultPercentageRoyalty;
    string uri;
    string name;
    string symbol;
    bool isSingle;
}

struct TokenInput {
    string name;
    string symbol;
    string uri;
}

struct RoyaltyInput {
    address receiver;
    uint96 percentage;
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
    address osbSoul;
    uint256 createProjectFee;
    uint256 profitShareMinimum;
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
    uint256 profitShare;
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

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IOSB721 is IERC721Upgradeable {
    function mint(address _to, string memory _tokenUri) external returns (uint256);
    function mintWithRoyalty(address _to, string memory _tokenUri, address _receiverRoyalty, uint96 _percentageRoyalty) external returns (uint256);
    function setController(address _account, bool _allow) external;
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IOSB1155 is IERC1155Upgradeable {
    function mint(address _to, uint256 _amount, string memory _tokenUri) external returns (uint256);
    function mintWithRoyalty(address _to, uint256 _amount, string memory _tokenUri, address _receiverRoyalty, uint96 _percentageRoyalty) external returns (uint256);
    function setController(address _account, bool _allow) external;
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IOSBSoul {
    function balanceOf(address _address) external view returns(uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

library Helper {
	function safeTransferNative(address _to, uint256 _value) internal {
		(bool success, ) = _to.call { value: _value }(new bytes(0));
		require(success, "SafeTransferNative: transfer failed");
	}
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

import "../contracts/Project.sol";

contract $Project is Project {
    constructor() {}

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

import "../../contracts/interfaces/IOSBFactory.sol";

abstract contract $IOSBFactory is IOSBFactory {
    constructor() {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/IOSBSoul.sol";

abstract contract $IOSBSoul is IOSBSoul {
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