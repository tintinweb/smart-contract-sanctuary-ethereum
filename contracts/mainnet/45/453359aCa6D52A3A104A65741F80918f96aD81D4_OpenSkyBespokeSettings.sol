// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/access/Ownable.sol';

import '../interfaces/IACLManager.sol';
import './interfaces/IOpenSkyBespokeSettings.sol';
import './libraries/BespokeTypes.sol';

contract OpenSkyBespokeSettings is Ownable, IOpenSkyBespokeSettings {
    uint256 public constant MAX_RESERVE_FACTOR = 3000;

    address public immutable ACLManagerAddress;

    // nft whitelist
    bool public override isWhitelistOn = false;
    // nftAddress=>data
    mapping(address => BespokeTypes.WhitelistInfo) internal _whitelist;

    // currency whitelist
    mapping(address => bool) public _currencyWhitelist;

    // one-time initialization
    address public override marketAddress;
    address public override borrowLoanAddress;
    address public override lendLoanAddress;

    // governance factors
    uint256 public override reserveFactor = 2000;
    uint256 public override overdueLoanFeeFactor = 100;

    uint256 public override minBorrowDuration = 30 minutes;
    uint256 public override maxBorrowDuration = 60 days;
    uint256 public override overdueDuration = 2 days;

    modifier onlyGovernance() {
        IACLManager ACLManager = IACLManager(ACLManagerAddress);
        require(ACLManager.isGovernance(_msgSender()), 'BM_ACL_ONLY_GOVERNANCE_CAN_CALL');
        _;
    }
    modifier onlyWhenNotInitialized(address address_) {
        require(address_ == address(0));
        _;
    }

    constructor(address _ACLManagerAddress) Ownable() {
        ACLManagerAddress = _ACLManagerAddress;
    }

    // OpenSkyBespokeMarket address
    function initMarketAddress(address address_) external onlyOwner onlyWhenNotInitialized(marketAddress) {
        require(address_ != address(0));
        marketAddress = address_;
        emit InitMarketAddress(msg.sender, address_);
    }

    function initLoanAddress(address borrowLoanAddress_, address lendLoanAddress_)
        external
        onlyOwner
        onlyWhenNotInitialized(borrowLoanAddress)
        onlyWhenNotInitialized(lendLoanAddress)
    {
        require(borrowLoanAddress_ != address(0) && lendLoanAddress_ != address(0));
        borrowLoanAddress = borrowLoanAddress_;
        lendLoanAddress = lendLoanAddress_;
        emit InitLoanAddress(msg.sender, borrowLoanAddress_, lendLoanAddress_);
    }
    
    function setMinBorrowDuration(uint256 factor) external onlyGovernance {
        require(minBorrowDuration > 0);
        minBorrowDuration = factor;
        emit SetMinBorrowDuration(msg.sender, factor);
    }

    function setMaxBorrowDuration(uint256 factor) external onlyGovernance {
        require(maxBorrowDuration > 0);
        maxBorrowDuration = factor;
        emit SetMaxBorrowDuration(msg.sender, factor);
    }

    function setOverdueDuration(uint256 factor) external onlyGovernance {
        overdueDuration = factor;
        emit SetOverdueDuration(msg.sender, factor);
    }

    function setReserveFactor(uint256 factor) external onlyGovernance {
        require(factor <= MAX_RESERVE_FACTOR);
        reserveFactor = factor;
        emit SetReserveFactor(msg.sender, factor);
    }

    function setOverdueLoanFeeFactor(uint256 factor) external onlyGovernance {
        overdueLoanFeeFactor = factor;
        emit SetOverdueLoanFeeFactor(msg.sender, factor);
    }

    function openWhitelist() external onlyGovernance {
        isWhitelistOn = true;
        emit OpenWhitelist(msg.sender);
    }

    function closeWhitelist() external onlyGovernance {
        isWhitelistOn = false;
        emit CloseWhitelist(msg.sender);
    }

    function addToWhitelist(
        address nft,
        uint256 minBorrowDuration,
        uint256 maxBorrowDuration,
        uint256 overdueDuration
    ) external onlyGovernance {
        require(nft != address(0));
        require(minBorrowDuration <= maxBorrowDuration);
        _whitelist[nft] = BespokeTypes.WhitelistInfo({
            enabled: true,
            minBorrowDuration: minBorrowDuration,
            maxBorrowDuration: maxBorrowDuration,
            overdueDuration: overdueDuration
        });
        emit AddToWhitelist(msg.sender, nft);
    }

    function removeFromWhitelist(address nft) external onlyGovernance {
        if (_whitelist[nft].enabled) {
            _whitelist[nft].enabled = false;
            emit RemoveFromWhitelist(msg.sender, nft);
        }
    }

    function inWhitelist(address nft) public view override returns (bool) {
        require(nft != address(0));
        return !isWhitelistOn || _whitelist[nft].enabled;
    }

    function getWhitelistDetail(address nft) public view override returns (BespokeTypes.WhitelistInfo memory) {
        return _whitelist[nft];
    }

    function getBorrowDurationConfig(address nftAddress)
        public
        view
        override
        returns (
            uint256 minBorrowDuration_,
            uint256 maxBorrowDuration_,
            uint256 overdueDuration_
        )
    {
        if (isWhitelistOn && inWhitelist(nftAddress)) {
            BespokeTypes.WhitelistInfo memory info = getWhitelistDetail(nftAddress);
            minBorrowDuration_ = info.minBorrowDuration;
            maxBorrowDuration_ = info.maxBorrowDuration;
            overdueDuration_ = info.overdueDuration;
        } else {
            minBorrowDuration_ = minBorrowDuration;
            maxBorrowDuration_ = maxBorrowDuration;
            overdueDuration_ = overdueDuration;
        }
    }

    // currency whitelist
    function addCurrency(address currency) external onlyGovernance {
        require(currency != address(0));
        if (_currencyWhitelist[currency] != true) {
            _currencyWhitelist[currency] = true;
        }
        emit AddCurrency(msg.sender, currency);
    }

    function removeCurrency(address currency) external onlyGovernance {
        require(currency != address(0));
        delete _currencyWhitelist[currency];
        emit RemoveCurrency(msg.sender, currency);
    }

    function isCurrencyWhitelisted(address currency) external view override returns (bool) {
        return _currencyWhitelist[currency];
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IACLManager {
    function addEmergencyAdmin(address admin) external;
    
    function isEmergencyAdmin(address admin) external view returns (bool);
    
    function removeEmergencyAdmin(address admin) external;
    
    function addGovernance(address admin) external;
    
    function isGovernance(address admin) external view returns (bool);

    function removeGovernance(address admin) external;

    function addPoolAdmin(address admin) external;

    function isPoolAdmin(address admin) external view returns (bool);

    function removePoolAdmin(address admin) external;

    function addLiquidationOperator(address address_) external;

    function isLiquidationOperator(address address_) external view returns (bool);

    function removeLiquidationOperator(address address_) external;

    function addAirdropOperator(address address_) external;

    function isAirdropOperator(address address_) external view returns (bool);

    function removeAirdropOperator(address address_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import '../libraries/BespokeTypes.sol';

interface IOpenSkyBespokeSettings {
    event InitLoanAddress(address operator, address borrowLoanAddress, address lendLoanAddress);
    event InitMarketAddress(address operator, address address_);

    event SetReserveFactor(address operator, uint256 factor);
    event SetOverdueLoanFeeFactor(address operator, uint256 factor);

    event SetMinBorrowDuration(address operator, uint256 factor);
    event SetMaxBorrowDuration(address operator, uint256 factor);
    event SetOverdueDuration(address operator, uint256 factor);

    event OpenWhitelist(address operator);
    event CloseWhitelist(address operator);
    event AddToWhitelist(address operator, address nft);
    event RemoveFromWhitelist(address operator, address nft);

    event AddCurrency(address operator, address currency);
    event RemoveCurrency(address operator, address currency);

    function marketAddress() external view returns (address);

    function borrowLoanAddress() external view returns (address);

    function lendLoanAddress() external view returns (address);


    function minBorrowDuration() external view returns (uint256);

    function maxBorrowDuration() external view returns (uint256);

    function overdueDuration() external view returns (uint256);

    function reserveFactor() external view returns (uint256);

    function MAX_RESERVE_FACTOR() external view returns (uint256);

    function overdueLoanFeeFactor() external view returns (uint256);

    function isWhitelistOn() external view returns (bool);

    function inWhitelist(address nft) external view returns (bool);

    function getWhitelistDetail(address nft) external view returns (BespokeTypes.WhitelistInfo memory);

    function getBorrowDurationConfig(address nftAddress)
        external
        view
        returns (
            uint256 minBorrowDuration,
            uint256 maxBorrowDuration,
            uint256 overdueDuration
        );

    function isCurrencyWhitelisted(address currency) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library BespokeTypes {
    struct BorrowOffer {
        uint256 reserveId;
        address nftAddress;
        uint256 tokenId;
        uint256 tokenAmount; // 1 for ERC721, 1+ for ERC1155
        address borrower;
        uint256 borrowAmountMin;
        uint256 borrowAmountMax;
        uint40 borrowDurationMin;
        uint40 borrowDurationMax;
        uint128 borrowRate;
        address currency;
        uint256 nonce;
        uint256 deadline;
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    struct LoanData {
        uint256 reserveId;
        address nftAddress;
        uint256 tokenId;
        uint256 tokenAmount; // 1 for ERC721, 1+ for ERC1155
        address borrower;
        uint256 amount;
        uint128 borrowRate;
        uint128 interestPerSecond;
        address currency;
        uint40 borrowDuration;
        // after take offer
        uint40 borrowBegin;
        uint40 borrowOverdueTime;
        uint40 liquidatableTime;
        address lender;
        LoanStatus status;
    }

    enum LoanStatus {
        NONE,
        BORROWING,
        OVERDUE,
        LIQUIDATABLE
    }

    struct WhitelistInfo {
        bool enabled;
        uint256 minBorrowDuration;
        uint256 maxBorrowDuration;
        uint256 overdueDuration;
    }
}

// SPDX-License-Identifier: MIT

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