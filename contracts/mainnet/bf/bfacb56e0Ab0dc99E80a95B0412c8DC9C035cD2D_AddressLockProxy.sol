// SPDX-License-Identifier: GNU-GPL
pragma solidity >=0.8.0;

import "./interfaces/IAddressLock.sol";
import "./interfaces/IResonate.sol";
import "./interfaces/IERC4626.sol";
import "./interfaces/IERC20Detailed.sol";
import "./interfaces/IMetadataHandler.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

/** @title Address Lock Proxy. */
contract AddressLockProxy is Ownable, IAddressLock, ERC165 {

    /// IResonate variable
    IResonate public resonate;

    /// Metadata handler address
    address public metadataHandler;

    /// Precision for calculating rates
    uint public constant PRECISION = 1 ether;
    /// Whether Resonate is set or not
    bool private _resonateSet;

    
    /**
     * @notice Constructor for AddressLockProxy
     */
    constructor() {}

    /**
     * @notice the functions that determines when a fixed-return lock can unlock
     * @param fnftId the ID of the FNFT to check
     * @return whether or not this FNFT is ready to be unlocked
     * @dev if the residual is greater than zero, we know the lock is already unlocked
     */
    function isUnlockable(uint fnftId, uint) external view returns (bool) {
        uint residual = resonate.residuals(fnftId);

        if(residual > 0) {
            return true;
        }

        uint index = resonate.fnftIdToIndex(fnftId);
        (,, uint sharesAtDeposit, bytes32 poolId) = resonate.activated(index);
        (,,address vaultAdapter,,uint128 rate, uint128 addInterestRate, uint256 packetSize)= resonate.pools(poolId);

        uint128 expectedReturn = rate + addInterestRate; //1E18
        uint tokensExpectedPerPacket = packetSize * expectedReturn / PRECISION;

       
        uint previewRedemption = IERC4626(vaultAdapter).previewRedeem(sharesAtDeposit / PRECISION);
        uint tokensAccumulatedPerPacket;
        if (previewRedemption < packetSize) {
            return false;
        } else {
            tokensAccumulatedPerPacket =  previewRedemption - packetSize;
        }

        return tokensAccumulatedPerPacket >= tokensExpectedPerPacket;
    }

    function getDisplayValues(uint fnftId, uint lockId) external view override returns (bytes memory output) {
        return IMetadataHandler(metadataHandler).getAddressLockBytes(fnftId, lockId);
    }
    
    function getMetadata() external view override returns (string memory) {
        return IMetadataHandler(metadataHandler).getAddressLockURL();
    }

    function needsUpdate() external pure returns (bool) {
        return false;
    }

    function supportsInterface(bytes4 interfaceId) public view override (ERC165, IERC165) returns (bool) {
        return  interfaceId == type(IAddressLock).interfaceId
                || super.supportsInterface(interfaceId);
    }

    function setResonate(address _resonate) external onlyOwner {
        require(!_resonateSet, 'ER031');
        _resonateSet = true;
        resonate = IResonate(_resonate);
    }

    function setMetadataHandler(address _metadata) external onlyOwner {
        metadataHandler = _metadata;
    }

    function getAddressRegistry() external view returns (address) {
        return resonate.REGISTRY_ADDRESS();
    }
    

    ///
    /// Interface-mandated functions
    ///

    function createLock(uint fnftId, uint lockId, bytes memory arguments) external {}
    function updateLock(uint fnftId, uint lockId, bytes memory arguments) external {}
    function setAddressRegistry(address revest) external {}
    
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC4626 is IERC20 {


    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    
    event Deposit(address indexed caller, address indexed owner, uint256 amountUnderlying, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 amountUnderlying,
        uint256 shares
    );

    /// Transactional Functions

    function deposit(uint amountUnderlying, address receiver) external returns (uint shares);

    function mint(uint shares, address receiver) external returns (uint amountUnderlying);

    function withdraw(uint amountUnderlying, address receiver, address owner) external returns (uint shares);

    function redeem(uint shares, address receiver, address owner) external returns (uint amountUnderlying);


    /// View Functions

    function asset() external view returns (address assetTokenAddress);

    // Total assets held within
    function totalAssets() external view returns (uint totalManagedAssets);

    function convertToShares(uint amountUnderlying) external view returns (uint shares);

    function convertToAssets(uint shares) external view returns (uint amountUnderlying);

    function maxDeposit(address receiver) external view returns (uint maxAssets);

    function previewDeposit(uint amountUnderlying) external view returns (uint shares);

    function maxMint(address receiver) external view returns (uint maxShares);

    function previewMint(uint shares) external view returns (uint amountUnderlying);

    function maxWithdraw(address owner) external view returns (uint maxAssets);

    function previewWithdraw(uint amountUnderlying) external view returns (uint shares);

    function maxRedeem(address owner) external view returns (uint maxShares);

    function previewRedeem(uint shares) external view returns (uint amountUnderlying);

    /// IERC20 View Methods

    /**
     * @dev Returns the amount of shares in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of shares owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the remaining number of shares that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Returns the name of the vault shares.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the vault shares.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the vault shares.
     */
    function decimals() external view returns (uint8);

    
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

interface IMetadataHandler {
    
    function getOutputReceiverURL() external view returns (string memory);

    function getAddressLockURL() external view returns (string memory);

    function getOutputReceiverBytes(uint fnftId) external view returns (bytes memory output);

    function getAddressLockBytes(uint fnftId, uint) external view returns (bytes memory output);
    
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

library Bytes32Conversion {
    function toAddress(bytes32 b32) internal pure returns (address) {
        return address(uint160(bytes20(b32)));
    }
}

interface IResonate {

        // Uses 3 storage slots
    struct PoolConfig {
        address asset; // 20
        address vault; // 20 
        address adapter; // 20
        uint32  lockupPeriod; // 4
        uint128  rate; // 16
        uint128  addInterestRate; //Amount additional (10% on top of the 30%) - If not a bond then just zero // 16
        uint256 packetSize; // 32
    }

    // Uses 1 storage slot
    struct PoolQueue {
        uint64 providerHead;
        uint64 providerTail;
        uint64 consumerHead;
        uint64 consumerTail;
    }

    // Uses 3 storage slot
    struct Order {
        uint256 packetsRemaining;
        uint256 depositedShares;
        bytes32 owner;
    }

    struct ParamPacker {
        Order consumerOrder;
        Order producerOrder;
        bool isProducerNew;
        bool isCrossAsset;
        uint quantityPackets; 
        uint currentExchangeRate;
        PoolConfig pool;
        address adapter;
        bytes32 poolId;
    }

    /// Uses 4 storage slots
    /// Stores information on activated positions
    struct Active {
        // The ID of the associated Principal FNFT
        // Interest FNFT will be this +1
        uint256 principalId; 
        // Set at the time you last claim interest
        // Current state of interest - current shares per asset
        uint256 sharesPerPacket; 
        // Zero measurement point at pool creation
        // Left as zero if Type0
        uint256 startingSharesPerPacket; 
        bytes32 poolId;
    }

    ///
    /// Events
    ///

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event PoolCreated(bytes32 indexed poolId, address indexed asset, address indexed vault, address payoutAsset, uint128 rate, uint128 addInterestRate, uint32 lockupPeriod, uint256 packetSize, bool isFixedTerm, string poolName, address creator);

    event EnqueueProvider(bytes32 indexed poolId, address indexed addr, uint64 indexed position, bool shouldFarm, Order order);
    event EnqueueConsumer(bytes32 indexed poolId, address indexed addr, uint64 indexed position, bool shouldFarm, Order order);

    event DequeueProvider(bytes32 indexed poolId, address indexed dequeuer, address indexed owner, uint64 position, Order order);
    event DequeueConsumer(bytes32 indexed poolId, address indexed dequeuer, address indexed owner, uint64 position, Order order);

    event OracleRegistered(address indexed vaultAsset, address indexed paymentAsset, address indexed oracleDispatch);

    event VaultAdapterRegistered(address indexed underlyingVault, address indexed vaultAdapter, address indexed vaultAsset);

    event CapitalActivated(bytes32 indexed poolId, uint numPackets, uint indexed principalFNFT);
    
    event OrderWithdrawal(bytes32 indexed poolId, uint amountPackets, bool fullyWithdrawn, address owner);

    event FNFTCreation(bytes32 indexed poolId, bool indexed isPrincipal, uint indexed fnftId, uint quantityFNFTs);
    event FNFTRedeemed(bytes32 indexed poolId, bool indexed isPrincipal, uint indexed fnftId, uint quantityFNFTs);

    event FeeCollection(bytes32 indexed poolId, uint amountTokens);

    event InterestClaimed(bytes32 indexed poolId, uint indexed fnftId, address indexed claimer, uint amount);
    event BatchInterestClaimed(bytes32 indexed poolId, uint[] fnftIds, address indexed claimer, uint amountInterest);
    
    event DepositERC20OutputReceiver(address indexed mintTo, address indexed token, uint amountTokens, uint indexed fnftId, bytes extraData);
    event WithdrawERC20OutputReceiver(address indexed caller, address indexed token, uint amountTokens, uint indexed fnftId, bytes extraData);

    function residuals(uint fnftId) external view returns (uint residual);
    function RESONATE_HELPER() external view returns (address resonateHelper);

    function queueMarkers(bytes32 poolId) external view returns (uint64 a, uint64 b, uint64 c, uint64 d);
    function providerQueue(bytes32 poolId, uint256 providerHead) external view returns (uint packetsRemaining, uint depositedShares, bytes32 owner);
    function consumerQueue(bytes32 poolId, uint256 consumerHead) external view returns (uint packetsRemaining, uint depositedShares, bytes32 owner);
    function activated(uint fnftId) external view returns (uint principalId, uint sharesPerPacket, uint startingSharesPerPacket, bytes32 poolId);
    function pools(bytes32 poolId) external view returns (address asset, address vault, address adapter, uint32 lockupPeriod, uint128 rate, uint128 addInterestRate, uint256 packetSize);
    function vaultAdapters(address vault) external view returns (address vaultAdapter);
    function fnftIdToIndex(uint fnftId) external view returns (uint index);
    function REGISTRY_ADDRESS() external view returns (address registry);

    function receiveRevestOutput(
        uint fnftId,
        address,
        address payable owner,
        uint quantity
    ) external;

    function claimInterest(uint fnftId, address recipient) external;
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

interface IERC20Detailed {

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "./IRegistryProvider.sol";
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

/**
 * @title Provider interface for Revest FNFTs
 * @dev Address locks MUST be non-upgradeable to be considered for trusted status
 * @author Revest
 */
interface IAddressLock is IERC165, IRegistryProvider {

    /// Creates a lock to the specified lockID
    /// @param fnftId the fnftId to map this lock to. Not recommended for typical locks, as it will break on splitting
    /// @param lockId the lockId to map this lock to. Recommended uint for storing references to lock configurations
    /// @param arguments an abi.encode() bytes array. Allows frontend to encode and pass in an arbitrary set of parameters
    /// @dev creates a lock for the specified lockId. Will be called during the creation process for address locks when the address
    ///      of a contract implementing this interface is passed in as the "trigger" address for minting an address lock. The bytes
    ///      representing any parameters this lock requires are passed through to this method, where abi.decode must be call on them
    function createLock(uint fnftId, uint lockId, bytes memory arguments) external;

    /// Updates a lock at the specified lockId
    /// @param fnftId the fnftId that can map to a lock config stored in implementing contracts. Not recommended, as it will break on splitting
    /// @param lockId the lockId that maps to the lock config which should be updated. Recommended for retrieving references to lock configurations
    /// @param arguments an abi.encode() bytes array. Allows frontend to encode and pass in an arbitrary set of parameters
    /// @dev updates a lock for the specified lockId. Will be called by the frontend from the information section if an update is requested
    ///      can further accept and decode parameters to use in modifying the lock's config or triggering other actions
    ///      such as triggering an on-chain oracle to update
    function updateLock(uint fnftId, uint lockId, bytes memory arguments) external;

    /// Whether or not the lock can be unlocked
    /// @param fnftId the fnftId that can map to a lock config stored in implementing contracts. Not recommended, as it will break on splitting
    /// @param lockId the lockId that maps to the lock config which should be updated. Recommended for retrieving references to lock configurations
    /// @dev this method is called during the unlocking and withdrawal processes by the Revest contract - it is also used by the frontend
    ///      if this method is returning true and someone attempts to unlock or withdraw from an FNFT attached to the requested lock, the request will succeed
    /// @return whether or not this lock may be unlocked
    function isUnlockable(uint fnftId, uint lockId) external view returns (bool);

    /// Provides an encoded bytes arary that represents values this lock wants to display on the info screen
    /// Info to decode these values is provided in the metadata file
    /// @param fnftId the fnftId that can map to a lock config stored in implementing contracts. Not recommended, as it will break on splitting
    /// @param lockId the lockId that maps to the lock config which should be updated. Recommended for retrieving references to lock configurations
    /// @dev used by the frontend to fetch on-chain data on the state of any given lock
    /// @return a bytes array that represents the result of calling abi.encode on values which the developer wants to appear on the frontend
    function getDisplayValues(uint fnftId, uint lockId) external view returns (bytes memory);

    /// Maps to a URL, typically IPFS-based, that contains information on how to encode and decode paramters sent to and from this lock
    /// Please see additional documentation for JSON config info
    /// @dev this method will be called by the frontend only but is crucial to properly implement for proper minting and information workflows
    /// @return a URL to the JSON file containing this lock's metadata schema
    function getMetadata() external view returns (string memory);

    /// Whether or not this lock will need updates and should display the option for them
    /// @dev this will be called by the frontend to determine if update inputs and buttons should be displayed
    /// @return whether or not the locks created by this contract will need updates
    function needsUpdate() external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

interface IRegistryProvider {
    function setAddressRegistry(address revest) external;

    function getAddressRegistry() external view returns (address);
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