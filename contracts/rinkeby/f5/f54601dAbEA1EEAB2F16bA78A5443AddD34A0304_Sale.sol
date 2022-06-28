//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./libraries/Helper.sol";
import "./interfaces/IDistribution.sol";
import "./interfaces/IProject.sol";
import "./interfaces/IOSB721.sol";
import "./interfaces/IOSB1155.sol";
import "./interfaces/ISale.sol";
import "./interfaces/INFTChecker.sol";

contract Sale is ReentrancyGuardUpgradeable, ERC721HolderUpgradeable, ERC1155HolderUpgradeable, OwnableUpgradeable {
    uint256  public constant WEIGHT_DECIMAL = 1e6;
    uint256  public lastedId;
    IProject public project;
    IDistribution public distribution;
	INFTChecker private nftChecker;

    mapping(uint256 => mapping(address => bool)) public winners;
    mapping(uint256 => SaleInfo) private sales;
    mapping(uint256 => uint256[]) private saleIdsOfProject;
    mapping(address => bool) public controllers;

    event Creates(uint256 indexed projectId, SaleInfo[] sales);
    event Close(uint256 indexed projectId, uint256[] saleIds);
    event BidSingleProjectAdmin(address indexed buyer, uint256 indexed saleId, uint256 indexed tokenId, uint256 royaltyFee, uint256 value);
    event BidSingleProjectUser(address indexed buyer, uint256 indexed saleId, uint256 indexed tokenId, uint256 percentAdminFee, uint256 adminFee, uint256 royaltyFee, uint256 valueForUser);
    event BidMultiProjectAdmin(address indexed buyer, uint256 indexed saleId, uint256 indexed tokenId, uint256 amount, uint256 royaltyFee, uint256 value);
    event BidMultiProjectUser(address indexed buyer, uint256 indexed saleId, uint256 indexed tokenId, uint256 amount, uint256 percentAdminFee, uint256 adminFee, uint256 royaltyFee, uint256 valueForUser);
    event SetWinners(uint256 indexed saleId, address[] accounts, bool isWinner);

    modifier onlyWinner(uint256 saleId) {
        require(winners[saleId][_msgSender()], "caller is not the winner");
        _;
    }

    modifier onlyAdmin() {
        require(_msgSender() == project.getSuperAdmin() || project.isAdmin(_msgSender()), "caller is not the admin");
        _;
    }

    modifier onlyController() {
        require(controllers[_msgSender()], "caller is not the controller");
        _;
    }

    modifier onlyManagerWithSaleId(uint256 saleId) {
        if (project.getProject(sales[saleId].projectId).isCreatedByAdmin) {
            require(_msgSender() == project.getSuperAdmin() || project.isAdmin(_msgSender()) || _msgSender() == project.getManager(sales[saleId].projectId), "caller is not the manager");
        } else {
            require(_msgSender() == project.getManager(sales[saleId].projectId), "caller is not the manager");
        }
        _;
    }

    modifier onlyManagerWithProjectId(uint256 projectId) {
        if (project.getProject(projectId).isCreatedByAdmin) {
            require(_msgSender() == project.getSuperAdmin() || project.isAdmin(_msgSender()) || _msgSender() == project.getManager(projectId), "caller is not the manager");
        } else {
            require(_msgSender() == project.getManager(projectId), "caller is not the manager");
        }
        _;
    }

    modifier accountsNotEmpty(address[] memory account) {
        require(account.length > 0, "Accounts empty");
        _;
    }

    modifier onSale(uint256 _saleId) {
        require(_saleId > 0 && _saleId <= lastedId, "Invalid sale id");

        SaleInfo memory sale = sales[_saleId];
        require(!sale.isSoldOut, "bid: sold out");

        ProjectInfo memory _project = project.getProject(sale.projectId); 
        uint64 timestamp = uint64(block.timestamp);

        require(_project.status == ProjectStatus.STARTED, "bid: project inactive");
        require(timestamp >= _project.saleStart, "bid: sale is not start");
        require(timestamp <= _project.saleEnd, "bid: sale end");
        _;
    }

    function initialize(address _nftChecker) external initializer {
        require(_nftChecker != address(0), "nftChecker is zero address");
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        OwnableUpgradeable.__Ownable_init();
        ERC721HolderUpgradeable.__ERC721Holder_init();
        ERC1155HolderUpgradeable.__ERC1155Holder_init();
        nftChecker = INFTChecker(_nftChecker);
    }

    function setContracts(address _project, address _distribution) external {
        require(_project != address(0) && _distribution != address(0), "Invalid param");
        require(address(project) == address(0) && address(distribution) == address(0), "Address Project or Distribution is already set");
        project = IProject(_project);
        distribution = IDistribution(_distribution);
    }

    function setControllers(address[] memory _accounts, bool _allow) external onlyAdmin {
        for (uint256 i; i < _accounts.length; i++) {
            require(_accounts[i] != address(0), "account is zero address");
            controllers[_accounts[i]] = _allow;
        }
    }

    function setWinners(uint256 _saleId, address[] memory _accounts, bool _isWinner) external onlyController accountsNotEmpty(_accounts) {
        require(_saleId > 0 && _saleId <= lastedId, "Invalid sale id");

        for (uint256 i; i < _accounts.length; i++) {
            require(_accounts[i] != address(0), "account is zero address");
            winners[_saleId][_accounts[i]] = _isWinner;
        }
        emit SetWinners(_saleId, _accounts, _isWinner);
    }

    function createRaiseSingle(uint256 _projectId, uint256[] memory _tokenIds, uint256[] memory _raisePrices) external payable onlyManagerWithProjectId(_projectId) {
        require(_tokenIds.length > 0 && _tokenIds.length == _raisePrices.length, "create: invalid param");
        ProjectInfo memory _project = project.getProject(_projectId);
        require(_project.id > 0, "create: invalid project");
        require(_project.status != ProjectStatus.STARTED, "project started");
        require(_project.isSingle, "create: token is not single version");
        require(_project.isRaise, "create: project is not a raise auction");

        SaleInfo[] memory _sales = new SaleInfo[](_tokenIds.length);
        uint256 _id = lastedId;

        for (uint256 i; i < _tokenIds.length; i++) {
            ++_id;
            _sales[i] = _createSale(_id, _project, _tokenIds[i], 0, _raisePrices[i], 0, 0, 0);
        }

        lastedId = _id;
        emit Creates(_projectId, _sales);
    }

    function createDutchSingle(uint256 _projectId, uint256[] memory _tokenIds, uint256[] memory _maxPrices, uint256[] memory _minPrices, uint256[] memory _priceDecrementAmts) external onlyManagerWithProjectId(_projectId) {
        require(_tokenIds.length > 0 && _tokenIds.length == _maxPrices.length && _tokenIds.length == _minPrices.length && _tokenIds.length == _priceDecrementAmts.length, "invalid param");
        ProjectInfo memory _project = project.getProject(_projectId);
        require(_project.id > 0, "create: invalid project");
        require(_project.status != ProjectStatus.STARTED, "project started");
        require(_project.isSingle, "create: token is not single version");
        require(!_project.isRaise, "create: project is not a dutch auction");

        SaleInfo[] memory _sales = new SaleInfo[](_tokenIds.length);
        uint256 _id = lastedId;

        for (uint256 i; i < _tokenIds.length; i++) {
            ++_id;
            _sales[i] = _createSale(_id, _project, _tokenIds[i], 0, 0, _maxPrices[i], _minPrices[i], _priceDecrementAmts[i]);
        }

        lastedId = _id;
        emit Creates(_projectId, _sales);
    }

    function createRaiseMulti(uint256 _projectId, uint256[] memory _tokenIds, uint256[] memory _amounts, uint256[] memory _raisePrices) external onlyManagerWithProjectId(_projectId) {
        require(_tokenIds.length > 0 && _tokenIds.length == _amounts.length && _tokenIds.length == _raisePrices.length, "create: invalid param");
        ProjectInfo memory _project = project.getProject(_projectId); 
        require(_project.id > 0, "create: invalid project");
        require(_project.status != ProjectStatus.STARTED, "project started");
        require(!_project.isSingle, "create: token is not multi version");
        require(_project.isRaise, "create: project is not a raise auction");

        SaleInfo[] memory _sales = new SaleInfo[](_tokenIds.length);
        uint256 _id = lastedId;

        for (uint256 i; i < _tokenIds.length; i++) {
            ++_id;
            _sales[i] =  _createSale(_id, _project, _tokenIds[i], _amounts[i], _raisePrices[i], 0, 0, 0);
        }

        lastedId = _id;
        emit Creates(_projectId, _sales);
    }

    function createDutchMulti(uint256 _projectId, uint256[] memory _tokenIds, uint256[] memory _amounts, uint256[] memory _maxPrices, uint256[] memory _minPrices, uint256[] memory _priceDecrementAmts) external onlyManagerWithProjectId(_projectId) {
        require(_tokenIds.length > 0 && _tokenIds.length == _amounts.length && _tokenIds.length == _maxPrices.length && _tokenIds.length == _minPrices.length && _tokenIds.length == _priceDecrementAmts.length, "invalid param");
        ProjectInfo memory _project = project.getProject(_projectId); 
        require(_project.id > 0, "Invalid project id");
        require(_project.status != ProjectStatus.STARTED, "project started");
        require(!_project.isSingle, "create: token is not multi version");
        require(!_project.isRaise, "create: project is not a dutch auction");

        SaleInfo[] memory _sales = new SaleInfo[](_tokenIds.length);
        uint256 _id = lastedId;

        for (uint256 i; i < _tokenIds.length; i++) {
            ++_id;
            _sales[i] = _createSale(_id, _project, _tokenIds[i], _amounts[i], 0, _maxPrices[i], _minPrices[i], _priceDecrementAmts[i]);
        }

        lastedId = _id;
        emit Creates(_projectId, _sales);
    }

    function _createSale(uint256 saleId, ProjectInfo memory _project, uint256 tokenId, uint256 amount, uint256 raisePrice, uint256 maxPrice, uint256 minPrice, uint256 priceDecrementAmt) private returns(SaleInfo memory) {
        if (!_project.isSingle) {
            require(amount > 0, "create: amount is 0");
        }
        if (_project.isRaise) {
            require(raisePrice > 0, "create: invalid price");
        } else {
            require(maxPrice > minPrice && minPrice > 0, "create: invalid price");
            require(priceDecrementAmt > 0 && priceDecrementAmt <= maxPrice - minPrice, "create: invalid Price Decrement Amt");
        }
        
        SaleInfo storage sale  = sales[saleId];
        sale.id                = saleId;
        sale.projectId         = _project.id;
        sale.tokenId           = tokenId;
        sale.amount            = amount;
        sale.dutchMaxPrice     = maxPrice; 
        sale.dutchMinPrice     = minPrice;
        sale.priceDecrementAmt = priceDecrementAmt;
        sale.raisePrice        = raisePrice;
        saleIdsOfProject[_project.id].push(saleId);

        if (_project.isSingle) {
            IOSB721(_project.token).safeTransferFrom(_msgSender(), address(this), tokenId);
        } else {
            IOSB1155(_project.token).safeTransferFrom(_msgSender(), address(this), tokenId, amount, "");
        }
        return sale;
    }

    function bidSingle(uint256 _saleId) external payable onlyWinner(_saleId) onSale(_saleId) {
        SaleInfo storage sale = sales[_saleId];
        ProjectInfo memory _project = project.getProject(sale.projectId); 

        require(_project.isSingle, "bid: token not is single version");
        require(_project.isRaise ? msg.value == sale.raisePrice : msg.value >= currentDutchPrice(_saleId), "bid: invalid value");

        sale.isSoldOut = true;

        _sharing(_project, sale, 0);

        distribution.setSale(_saleId, _msgSender(), 0);
        
        IOSB721(_project.token).safeTransferFrom(address(this), address(distribution), sale.tokenId);
    }

    function bidMulti(uint256 _saleId, uint256 _amount) external payable onlyWinner(_saleId) onSale(_saleId) {
        SaleInfo storage sale = sales[_saleId];
        ProjectInfo memory _project = project.getProject(sale.projectId);

        require(_amount > 0 && _amount <= sale.amount, "bid: invalid amount");
        require(!_project.isSingle, "bid: token not is multi version");
        require(_project.isRaise ? msg.value == sale.raisePrice * _amount : msg.value >= currentDutchPrice(_saleId) * _amount, "bid: invalid value");

        sale.amount -= _amount;
        sale.isSoldOut = sale.amount == 0;

        _sharing(_project, sale, _amount);

        distribution.setSale(_saleId, _msgSender(), _amount);

        IOSB1155(_project.token).safeTransferFrom(address(this), address(distribution), sale.tokenId, _amount, "");
    }

    function _sharing(ProjectInfo memory _project, SaleInfo memory _sale, uint256 _amount) private {
        uint256 adminFee;
        uint256 percentAdminFee;
        uint256 remainingProfit;

        // Calculate royal fee
        (address royaltyReceiver, uint256 royaltyFee) = getRoyaltyInfo(_project.id, _sale.tokenId, msg.value);
        uint256 royaltyFeeAble = royaltyFee;

        // Calculate fee and profit
        if (_project.isCreatedByAdmin) {
            remainingProfit = msg.value - royaltyFee;
        } else {
            ApprovalInfo memory approval = project.getApproval(_project.id);
            percentAdminFee = approval.percent;
            adminFee = _getAdminFee(msg.value, approval.percent);

            remainingProfit = msg.value - adminFee;
            if (royaltyFee > remainingProfit) royaltyFeeAble = remainingProfit;

            remainingProfit = remainingProfit - royaltyFeeAble;            
        }

        // Transfer fee and profit
        if (royaltyFeeAble > 0) {
            Helper.safeTransferNative(royaltyReceiver, royaltyFeeAble);
        }

        if (adminFee > 0) {
            Helper.safeTransferNative(project.getSuperAdmin(), adminFee);
        }

        if (remainingProfit > 0) {
            Helper.safeTransferNative(project.getManager(_project.id), remainingProfit);
        }

        // Emit event
        if (_project.isSingle) {
            if (_project.isCreatedByAdmin) {
                emit BidSingleProjectAdmin(_msgSender(), _sale.id, _sale.tokenId, royaltyFee, remainingProfit);
            } else {
                emit BidSingleProjectUser(_msgSender(), _sale.id, _sale.tokenId, percentAdminFee, adminFee, royaltyFee, remainingProfit);
            }

            if (_project.isCreatedByAdmin) {
                emit BidMultiProjectAdmin(_msgSender(),_sale.id, _sale.tokenId, _amount, royaltyFee, remainingProfit);
            } else {
                emit BidMultiProjectUser(_msgSender(), _sale.id, _sale.tokenId, _amount, percentAdminFee, adminFee, royaltyFee, remainingProfit);
            }
        }
    }

    function close(uint256 _projectId, uint256[] memory _saleIds) external onlyManagerWithProjectId(_projectId) nonReentrant {
        require(_saleIds.length > 0, "close: invalid sale ids");
        ProjectInfo memory _project = project.getProject(_projectId); 
        require(_project.id > 0, "create: invalid project");
        require(block.timestamp > _project.saleEnd, "close: sale live");

        if (_project.isSingle) {
            for(uint256 i; i < _saleIds.length; i++) {
                SaleInfo storage saleInfo = sales[_saleIds[i]];
                require(saleInfo.id > 0, "Invalid sale");
                require(!saleInfo.isSoldOut, "Sale has sold out");

                saleInfo.isSoldOut = true;

                IOSB721(_project.token).safeTransferFrom(address(this), _project.manager, saleInfo.tokenId);
            }
        } else {
            for(uint256 i; i < _saleIds.length; i++) {
                SaleInfo storage saleInfo = sales[_saleIds[i]];
                require(saleInfo.id > 0, "Invalid sale");
                require(!saleInfo.isSoldOut, "Sale has sold out");

                saleInfo.isSoldOut = true;

                IOSB1155(_project.token).safeTransferFrom(address(this), _project.manager, saleInfo.tokenId, saleInfo.amount, "");
            }
        }

        emit Close(_projectId, _saleIds);
    }

    function currentDutchPrice(uint256 _saleId) public view returns (uint256) {
        if (_saleId == 0 || _saleId > lastedId) return 0;
        
        SaleInfo memory sale = sales[_saleId];
        ProjectInfo memory _project = project.getProject(sale.projectId); 
        uint256 decrement = (sale.dutchMaxPrice - sale.dutchMinPrice) / sale.priceDecrementAmt;
        uint256 timeToDecrementPrice = (_project.saleEnd - _project.saleStart) / decrement;

        uint256 currentTimestamp = block.timestamp;
        if (currentTimestamp <= _project.saleStart) {
            return sale.dutchMaxPrice;
        }

        uint256 numDecrements = (currentTimestamp - _project.saleStart) / timeToDecrementPrice;
        uint256 decrementAmt = sale.priceDecrementAmt * numDecrements;

        if (decrementAmt > sale.dutchMaxPrice || sale.dutchMaxPrice - decrementAmt <= sale.dutchMinPrice) {
            return sale.dutchMinPrice;
        }

        return sale.dutchMaxPrice - decrementAmt;
    }

	function getSale(uint256 _saleId) external view returns (SaleInfo memory) {
		return sales[_saleId];
	}

    function getSalesProject(uint256 _projectId) external view returns (SaleInfo[] memory) {
        uint256[] memory saleIds = saleIdsOfProject[_projectId];
        SaleInfo[] memory sales_ = new SaleInfo[](saleIds.length);
        for(uint256 i; i < saleIds.length; i++) {
            sales_[i] = sales[saleIds[i]];
        }
        return sales_;
    }

	function getRoyaltyInfo(uint256 _projectId, uint256 _tokenId, uint256 _salePrice) public view returns (address, uint256) { 
        ProjectInfo memory _project = project.getProject(_projectId);
        if (nftChecker.isImplementRoyalty(_project.token)) {
            (address receiver, uint256 amount) = _project.isSingle ? IOSB721(_project.token).royaltyInfo(_tokenId, _salePrice) : IOSB1155(_project.token).royaltyInfo(_tokenId, _salePrice);

            if (receiver == address(0)) return (address(0), 0);
            return (receiver, amount);
        } 
		return (address(0), 0);
	}
 
    function getTotalRoyalFee(uint256 _projectId, uint256[] memory _tokenIds, uint256[] memory _salePrices) public view returns (uint256) {
		uint256 total;
		ProjectInfo memory _project = project.getProject(_projectId);
        if (_project.id == 0) return 0;

        if (_project.isSingle) { 
            for (uint256 i; i < _tokenIds.length; i++) {
                (, uint256 royaltyAmount) = IOSB721(_project.token).royaltyInfo(_tokenIds[i], _salePrices[i]);
                total += royaltyAmount;
            }
        } else {
            for (uint256 i; i < _tokenIds.length; i++) {           
                (, uint256 royaltyAmount) = IOSB1155(_project.token).royaltyInfo(_tokenIds[i], _salePrices[i]);
                total += royaltyAmount;
            }
        }
		return total;
	}

    function _getAdminFee(uint256 _amount, uint256 _percent) private pure returns (uint256) {
        return (_amount * _percent) / (100 * WEIGHT_DECIMAL);
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

library Helper {
	function safeTransferNative(
		address to,
		uint256 value
	) internal {
		(bool success, ) = to.call{ value: value }(new bytes(0));
		require(success, "SafeTransferNative: transfer failed");
	}
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IDistribution {
    function setSale(uint256 saleId, address buyer, uint256 amount) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IProject {
    function latestId() external returns(uint256);

    function getSuperAdmin() external view returns (address);

    function getProject(uint256 _projectId) external view returns(ProjectInfo memory);

    function isAdmin(address _account) external view returns(bool);

    function getManager(uint256 _projectId) external view returns(address);

    function getApproval(uint256 _projectId) external view returns(ApprovalInfo memory);
}

struct ProjectInfo {
    uint256 id;
    bool isCreatedByAdmin;
    bool isSingle;
    bool isRaise;
    address token;
    address manager;
    uint256 joinStart;
    uint256 joinEnd;
    uint256 saleStart;
    uint256 saleEnd;
    uint256 distributionStart;
    ProjectStatus status;
}

struct ApprovalInfo {
    uint256 projectId;
    uint256 percent;
    bool isApproved;
}

enum ProjectStatus {
    INACTIVE,
    STARTED,
    ENDED
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IOSB721 is IERC721Upgradeable {
    function setBaseURI(string memory newUri) external;

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IOSB1155 is IERC1155Upgradeable {
    function mintBatch(uint256[] memory amounts) external returns (uint256[] memory);

    function setBaseURI(string memory newUri) external;

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ISale {
    function getSale(uint256 saleId) external view returns (SaleInfo memory);

    function getSalesProject(uint256 projectId) external view returns (SaleInfo[] memory);
}

struct SaleInfo {
    uint256 id;
    uint256 projectId;
    address token;
    uint256 tokenId;
    uint256 raisePrice;
    uint256 dutchMaxPrice;
    uint256 dutchMinPrice;
    uint256 priceDecrementAmt;
    uint256 amount;
    bool isSoldOut;
}

// SPDX-License-Identifier: MIT 
pragma solidity 0.8.9; 

interface INFTChecker { 
    function isERC1155(address nftAddress) external view returns (bool); 

    function isERC721(address nftAddress) external view returns (bool); 

    function isImplementRoyalty(address nftAddress) external view returns (bool);
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

    function $__Ownable_init() external {
        return super.__Ownable_init();
    }

    function $__Ownable_init_unchained() external {
        return super.__Ownable_init_unchained();
    }

    function $_transferOwnership(address newOwner) external {
        return super._transferOwnership(newOwner);
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
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/IDistribution.sol";

abstract contract $IDistribution is IDistribution {
    constructor() {}
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

import "../../contracts/interfaces/ISale.sol";

abstract contract $ISale is ISale {
    constructor() {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/libraries/Helper.sol";

contract $Helper {
    constructor() {}

    function $safeTransferNative(address to,uint256 value) external {
        return Helper.safeTransferNative(to,value);
    }
}