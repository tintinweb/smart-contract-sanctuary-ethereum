//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IDistribution.sol";
import "./interfaces/IProject.sol";
import "./interfaces/IOSB721.sol";
import "./interfaces/IOSB1155.sol";
import "./interfaces/ISale.sol";
import "./utils/NFTChecker.sol";

contract Sale is ERC721Holder, ERC1155Holder, Ownable, Initializable {
    using SafeMath for uint256;

    uint256  public constant WEIGHT_DECIMAL = 1e6;
    uint256  public lastedId;
    IProject public project;
    IDistribution public distribution;
	NFTChecker private nftChecker;

    mapping(uint256 => mapping(address => bool)) public winners;
    mapping(uint256 => SaleInfo) private sales;
    mapping(uint256 => uint256[]) private saleIdsOfProject;
    mapping(address => bool) public controllers;

    event Creates(uint256 indexed projectId, SaleInfo[] sales);
    event Close(uint256 indexed projectId, uint256[] saleIds);
    event BidSingleProjectAdmin(address indexed buyer, uint256 indexed saleId, uint256 indexed tokenId, uint256 value);
    event BidSingleProjectUser(address indexed buyer, uint256 indexed saleId, uint256 indexed tokenId, uint256 percent, uint256 valueForAdmin, uint256 valueForUser);
    event BidMultiProjectAdmin(address indexed buyer, uint256 indexed saleId, uint256 indexed tokenId, uint256 amount, uint256 value);
    event BidMultiProjectUser(address indexed buyer, uint256 indexed saleId, uint256 indexed tokenId, uint256 amount, uint256 percent, uint256 valueForAdmin, uint256 valueForUser);
    event AddWinners(uint256 indexed saleId, address[] accounts);
    event RemoveWinners(uint256 indexed saleId, address[] accounts);

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

    modifier idValid(uint256 id) {
        require(id > 0, "invalid id");
        _;
    }

    function initializable(address _project, address _distribution, address _nftChecker) external initializer {
        require(_project != address(0), "initializable: project is zero address");
        require(_distribution != address(0), "initializable: distribution is zero address");
        project = IProject(_project);
        distribution = IDistribution(_distribution);
        nftChecker = NFTChecker(_nftChecker);
    }

    function addControllers(address[] memory _accounts) external onlyAdmin {
        _setControllers(_accounts, true);
    }

    function removeControllers(address[] memory _accounts) external onlyAdmin {
        _setControllers(_accounts, false);
    }

    function _setControllers(address[] memory accounts, bool isAdd) private {
        for (uint256 i; i < accounts.length; i++) {
            require(accounts[i] != address(0), "account is zero address");
            controllers[accounts[i]] = isAdd;
        }
    }

    function addWinners(uint256 _saleId, address[] memory _accounts) external onlyController accountsNotEmpty(_accounts) {
        _setWinners(_saleId, _accounts, true);
        emit AddWinners(_saleId, _accounts);
    }

    function removeWinners(uint256 _saleId, address[] memory _accounts) external onlyController accountsNotEmpty(_accounts) {
        _setWinners(_saleId, _accounts, false);
        emit RemoveWinners(_saleId, _accounts);
    }

    function _setWinners(uint256 saleId, address[] memory accounts, bool isAdd) private {
        for (uint256 i; i < accounts.length; i++) {
            require(accounts[i] != address(0), "account is zero address");
            winners[saleId][accounts[i]] = isAdd;
        }
    }
		
    function createRaiseSingle(uint256 _projectId, uint256[] memory _tokenIds, uint256[] memory _raisePrices) external payable idValid(_projectId) onlyManagerWithProjectId(_projectId) {
        require(_tokenIds.length > 0 && _tokenIds.length == _raisePrices.length, "create: invalid param");
        ProjectInfo memory _project = project.getProject(_projectId);
        require(_project.status != ProjectStatus.STARTED, "project started");
        require(_project.isSingle, "create: token is not single version");
        require(_project.isRaise, "create: project is not a raise auction");

        SaleInfo[] memory _sales = new SaleInfo[](_tokenIds.length);
        uint256 _id = lastedId;

        for (uint256 i; i < _tokenIds.length; i++) {
            SaleInfo storage sale = sales[++_id];
            sale.id               = _id;
            sale.projectId        = _projectId;
            sale.token            = _project.token;
            sale.tokenId          = _tokenIds[i];
            sale.raisePrice       = _raisePrices[i];
            _sales[i]             = sale;
            saleIdsOfProject[_projectId].push(_id);
            IOSB721(_project.token).safeTransferFrom(_msgSender(), address(this), _tokenIds[i]);
        }

        lastedId = _id;
        emit Creates(_projectId, _sales);
    }

    function createDutchSingle(uint256 _projectId, uint256[] memory _tokenIds, uint256[] memory _maxPrices, uint256[] memory _minPrices, uint256[] memory _priceDecrementAmts) external idValid(_projectId) onlyManagerWithProjectId(_projectId) {
        require(_tokenIds.length > 0 && _tokenIds.length == _maxPrices.length && _tokenIds.length == _minPrices.length && _tokenIds.length == _priceDecrementAmts.length, "invalid param");
        ProjectInfo memory _project = project.getProject(_projectId);
        require(_project.status != ProjectStatus.STARTED, "project started");
        require(_project.isSingle, "create: token is not single version");
        require(!_project.isRaise, "create: project is not a dutch auction");

        SaleInfo[] memory _sales = new SaleInfo[](_tokenIds.length);
        uint256 _id = lastedId;

        for (uint256 i; i < _tokenIds.length; i++) {
            SaleInfo storage sale = sales[++_id];
            sale.id           = _id;
            sale.projectId    = _projectId;
            sale.token        = _project.token;
            sale.tokenId      = _tokenIds[i];
            sale.dutchMaxPrice     = _maxPrices[i];
            sale.dutchMinPrice     = _minPrices[i];
            sale.priceDecrementAmt = _priceDecrementAmts[i];
            _sales[i]              = sale;
            saleIdsOfProject[_projectId].push(_id);
            IOSB721(_project.token).safeTransferFrom(_msgSender(), address(this), _tokenIds[i]);
        }

        lastedId = _id;
        emit Creates(_projectId, _sales);
    }

    function createRaiseMulti(uint256 _projectId, uint256[] memory _tokenIds, uint256[] memory _amounts, uint256[] memory _raisePrices) external idValid(_projectId) onlyManagerWithProjectId(_projectId) {
        require(_tokenIds.length > 0 && _tokenIds.length == _amounts.length && _tokenIds.length == _raisePrices.length, "create: invalid param");
        ProjectInfo memory _project = project.getProject(_projectId); 
        require(_project.status != ProjectStatus.STARTED, "project started");
        require(!_project.isSingle, "create: token is not multi version");
        require(_project.isRaise, "create: project is not a raise auction");

        SaleInfo[] memory _sales = new SaleInfo[](_tokenIds.length);
        uint256 _id = lastedId;

        for (uint256 i; i < _tokenIds.length; i++) {
            require(_amounts[i] > 0, "create: amount is 0");
            SaleInfo storage sale = sales[++_id];
            sale.id               = _id;
            sale.projectId        = _projectId;
            sale.tokenId          = _tokenIds[i];
            sale.amount           = _amounts[i];
            sale.raisePrice       = _raisePrices[i];
            _sales[i]             = sale;
            saleIdsOfProject[_projectId].push(_id);
            IOSB1155(_project.token).safeTransferFrom(_msgSender(), address(this), _tokenIds[i], _amounts[i], "");
        }

        lastedId = _id;
        emit Creates(_projectId, _sales);
    }

    function createDutchMulti(uint256 _projectId, uint256[] memory _tokenIds, uint256[] memory _amounts, uint256[] memory _maxPrices, uint256[] memory _minPrices, uint256[] memory _priceDecrementAmts) external idValid(_projectId) onlyManagerWithProjectId(_projectId) {
        require(_tokenIds.length > 0 && _tokenIds.length == _amounts.length && _tokenIds.length == _maxPrices.length && _tokenIds.length == _minPrices.length && _tokenIds.length == _priceDecrementAmts.length, "invalid param");
        ProjectInfo memory _project = project.getProject(_projectId); 
        require(_project.status != ProjectStatus.STARTED, "project started");
        require(!_project.isSingle, "create: token is not multi version");
        require(!_project.isRaise, "create: project is not a dutch auction");

        SaleInfo[] memory _sales = new SaleInfo[](_tokenIds.length);
        uint256 _id = lastedId;

        for (uint256 i; i < _tokenIds.length; i++) {
            require(_amounts[i] > 0, "create: amount is 0");
            SaleInfo storage sale  = sales[++_id];
            sale.id                = _id;
            sale.projectId         = _projectId;
            sale.tokenId           = _tokenIds[i];
            sale.amount            = _amounts[i];
            sale.dutchMaxPrice     = _maxPrices[i];
            sale.dutchMinPrice     = _minPrices[i];
            sale.priceDecrementAmt = _priceDecrementAmts[i];
            _sales[i]              = sale;
            saleIdsOfProject[_projectId].push(_id);
            IOSB1155(_project.token).safeTransferFrom(_msgSender(), address(this), _tokenIds[i], _amounts[i], "");
        }

        lastedId = _id;
        emit Creates(_projectId, _sales);
    }

    function bidSingle(uint256 _saleId) external payable onlyWinner(_saleId) idValid(_saleId) {
        SaleInfo storage sale = sales[_saleId];
        require(!sale.isSoldOut, "bid: sold out");
        ProjectInfo memory _project = project.getProject(sale.projectId); 
        uint64 timestamp = uint64(block.timestamp);

        require(_project.status == ProjectStatus.STARTED, "bid: project inactive");
        require(_project.isSingle, "bid: token not is single version");
        require(timestamp >= _project.saleStart, "bid: sale is not start");
        require(timestamp <= _project.saleEnd, "bid: sale end");
        require(_project.isRaise ? msg.value == sale.raisePrice : msg.value >= currentPriceToMint(_saleId), "bid: invalid value");

        distribution.setSale(_saleId, _msgSender(), 0);
        sale.isSoldOut = true;

        (uint256 percent, uint256 profitShare, uint256 remainingProfit) = _sharing(_project.isCreatedByAdmin, _project.id, sale.tokenId);
        if (_project.isCreatedByAdmin) {
            emit BidSingleProjectAdmin(_msgSender(), _saleId, sale.tokenId, msg.value);
        } else {
            emit BidSingleProjectUser(_msgSender(), _saleId, sale.tokenId, percent, profitShare, remainingProfit);
        }
        IOSB721(_project.token).safeTransferFrom(address(this), address(distribution), sale.tokenId);
    }

    function bidMulti(uint256 _saleId, uint256 _amount) external payable onlyWinner(_saleId) idValid(_saleId) {
        require(_amount > 0, "bid: invalid amount");

        uint64 timestamp = uint64(block.timestamp);
        SaleInfo storage sale = sales[_saleId];
        require(!sale.isSoldOut, "bid: sold out");
        ProjectInfo memory _project = project.getProject(sale.projectId);

        require(_project.status == ProjectStatus.STARTED, "bid: project inactive");
        require(!_project.isSingle, "bid: token not is multi version");
        require(_amount <= sale.amount, "bid: exceed the current amount");
        require(timestamp >= _project.saleStart, "bid: sale is not start");
        require(timestamp <= _project.saleEnd, "bid: sale end");
        require(_project.isRaise ? msg.value == sale.raisePrice * _amount : msg.value >= currentPriceToMint(_saleId) * _amount, "bid: invalid value");

        sale.amount -= _amount;
        sale.isSoldOut = sale.amount == 0;
        distribution.setSale(_saleId, _msgSender(), _amount);

        (uint256 percent, uint256 profitShare, uint256 remainingProfit) = _sharing(_project.isCreatedByAdmin, _project.id, sale.tokenId);
        if (_project.isCreatedByAdmin) {
            emit BidMultiProjectAdmin(_msgSender(), _saleId, sale.tokenId, _amount, msg.value);
        } else {
            emit BidMultiProjectUser(_msgSender(), _saleId, sale.tokenId, _amount, percent, profitShare, remainingProfit);
        }
        IOSB1155(_project.token).safeTransferFrom(address(this), address(distribution), sale.tokenId, _amount, "");
    }

    function _sharing(bool isAdmin, uint256 projectId, uint256 tokenId) private returns(uint256, uint256, uint256) {
        address royaltyReceiver;
        uint256 royaltyFee;
        uint256 adminFee;
        uint256 amount;
        uint256 percentAdminFee;

        if (isAdmin) {
            (royaltyReceiver, royaltyFee) = getRoyaltyInfo(projectId, tokenId, msg.value);
            if(royaltyReceiver != address(0) && royaltyFee > 0) payable(royaltyReceiver).transfer(royaltyFee);

            amount = msg.value.sub(royaltyFee);
            payable(project.getSuperAdmin()).transfer(amount);
        } else {
            ApprovalInfo memory approval = project.getApproval(projectId);
            percentAdminFee = approval.percent;

            (royaltyReceiver, royaltyFee) = getRoyaltyInfo(projectId, tokenId, msg.value);
            if(royaltyReceiver != address(0) && royaltyFee > 0) payable(royaltyReceiver).transfer(royaltyFee);

            adminFee = _getAdminFee(msg.value, percentAdminFee);
            amount   = msg.value.sub(adminFee).sub(royaltyFee);

            payable(project.getSuperAdmin()).transfer(adminFee);
            payable(project.getManager(projectId)).transfer(amount);
        }
        return (percentAdminFee, adminFee, amount);
    }

    function close(uint256 _projectId, uint256[] memory _saleIds) external idValid(_projectId) onlyManagerWithProjectId(_projectId) {
        require(_saleIds.length > 0, "close: invalid sale ids");
        ProjectInfo memory _project = project.getProject(_projectId); 
        require(block.timestamp > _project.saleEnd, "close: sale live");

        if (_project.isSingle) {
            for(uint256 i; i < _saleIds.length; i++) {
               IOSB721(_project.token).safeTransferFrom(address(this), _project.manager, sales[_saleIds[i]].tokenId);
               sales[_saleIds[i]].isSoldOut = true;
            }
        } else {
            for(uint256 i; i < _saleIds.length; i++) {
               IOSB1155(_project.token).safeTransferFrom(address(this), _project.manager, sales[_saleIds[i]].tokenId, sales[_saleIds[i]].amount, "");
               sales[_saleIds[i]].isSoldOut = true;
            }
        }

        emit Close(_projectId, _saleIds);
    }

    function currentPriceToMint(uint256 _saleId) public view returns (uint256) {
        SaleInfo memory sale = sales[_saleId];
        ProjectInfo memory _project = project.getProject(sale.projectId); 
        uint256 decrement = (sale.dutchMaxPrice - sale.dutchMinPrice) / sale.priceDecrementAmt;
        uint256 timeToDecrementPrice = (_project.saleEnd - _project.saleStart) / decrement;
        uint256 numDecrements = (block.timestamp - _project.saleStart) / timeToDecrementPrice;
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
        if (nftChecker.isImplementRoyalty(_project.token) && _project.isSingle) {
            return IOSB721(_project.token).royaltyInfo(_tokenId, _salePrice);
        } else if (nftChecker.isImplementRoyalty(_project.token) && !_project.isSingle) {
            return IOSB1155(_project.token).royaltyInfo(_tokenId, _salePrice);
        } else {
		    return (address(0), 0);
        }
	}
 
    function getTotalRoyalFee(uint256 _projectId, uint256[] memory _tokenIds, uint256[] memory _salePrices) public view returns (uint256) {
		uint256 total;
		ProjectInfo memory _project = project.getProject(_projectId);
		for (uint256 i; i < _tokenIds.length; i++) {
			if (_project.isSingle) {
				(, uint256 royaltyAmount) = IOSB721(_project.token).royaltyInfo(_tokenIds[i], _salePrices[i]);
				total += royaltyAmount;
			} else {
			    (, uint256 royaltyAmount) = IOSB1155(_project.token).royaltyInfo(_tokenIds[i], _salePrices[i]);
			    total += royaltyAmount;
			}
		}
		return total;
	}

    function _getAdminFee(uint256 _amount, uint256 _percent) private pure returns (uint256) {
        return _amount.mul(_percent).div(100 * WEIGHT_DECIMAL);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

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
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IOSB721 is IERC721 {
    function setBaseURI(string memory newUri) external;

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IOSB1155 is IERC1155 {
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
import "@openzeppelin/contracts/utils/introspection/IERC165.sol"; 
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol"; 
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; 
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol"; 
import "../interfaces/INFTChecker.sol";

contract NFTChecker is INFTChecker, IERC165 { 
    using ERC165Checker for address; 
    bytes4 public constant IID_INFTCHECKER = type(INFTChecker).interfaceId; 
    bytes4 public constant IID_IERC165     = type(IERC165).interfaceId; 
    bytes4 public constant IID_IERC1155    = type(IERC1155).interfaceId; 
    bytes4 public constant IID_IERC721     = type(IERC721).interfaceId; 
    bytes4 public constant IID_IERC2981    = type(IERC2981).interfaceId; 
     
    function isERC1155(address _contractAddr) public view override returns (bool) { 
        return _contractAddr.supportsInterface(IID_IERC1155); 
    }     
     
    function isERC721(address _contractAddr) public view override returns (bool) { 
        return _contractAddr.supportsInterface(IID_IERC721); 
    }

    function isImplementRoyalty(address _contractAddr) public view override returns (bool) { 
        return _contractAddr.supportsInterface(IID_IERC2981); 
    } 
     
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) { 
        return interfaceId == IID_INFTCHECKER || interfaceId == IID_IERC165; 
    } 
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
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

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
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

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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
interface IERC165 {
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

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT 
pragma solidity 0.8.9; 

interface INFTChecker { 
    function isERC1155(address nftAddress) external returns (bool); 

    function isERC721(address nftAddress) external returns (bool); 

    function isImplementRoyalty(address nftAddress) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/Sale.sol";

contract $Sale is Sale {
    constructor() {}

    function $_transferOwnership(address newOwner) external {
        return super._transferOwnership(newOwner);
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

import "../../contracts/utils/NFTChecker.sol";

contract $NFTChecker is NFTChecker {
    constructor() {}
}