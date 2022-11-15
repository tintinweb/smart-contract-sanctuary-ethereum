// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {Clones} from "openzeppelin/proxy/Clones.sol";
import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin/token/ERC721/IERC721.sol";
import {IERC1155} from "openzeppelin/token/ERC1155/IERC1155.sol";
import {ECDSA} from "openzeppelin/utils/cryptography/ECDSA.sol";

import {Vault} from "./Vault.sol";

import {IRoyaltyEngine} from "./interfaces/external/IRoyaltyEngine.sol";
import {IConduitController} from "./interfaces/external/ISeaport.sol";
import {IOptOutList} from "./interfaces/IOptOutList.sol";
import {IPriceOracle} from "./interfaces/IPriceOracle.sol";
import {IWithdrawValidator} from "./interfaces/IWithdrawValidator.sol";

contract Forward is Ownable, ReentrancyGuard {
    using Clones for address;

    // Enums

    enum ItemKind {
        ERC721,
        ERC1155,
        ERC721_WITH_CRITERIA,
        ERC1155_WITH_CRITERIA
    }

    // Structs

    struct Order {
        ItemKind itemKind;
        address maker;
        address token;
        uint256 identifierOrCriteria;
        uint256 unitPrice;
        // The amount has a type of `uint128` instead of `uint256` so
        // that the order status can fit within a single storage slot
        uint128 amount;
        uint256 salt;
        uint256 expiration;
    }

    struct OrderStatus {
        bool cancelled;
        bool validated;
        uint128 filledAmount;
    }

    struct FillDetails {
        Order order;
        bytes signature;
        uint128 fillAmount;
    }

    // Errors

    error InvalidSeaportConduit();

    error OrderIsCancelled();
    error OrderIsExpired();
    error OrderIsInvalid();

    error VaultAlreadyExists();
    error VaultIsMissing();

    error InsufficientAmountAvailable();
    error InvalidCriteriaProof();
    error InvalidFillAmount();
    error InvalidSignature();

    error Unauthorized();

    // Events

    event OptOutListUpdated(address newOptOutList);
    event PriceOracleUpdated(address newPriceOracle);
    event RoyaltyEngineUpdated(address newRoyaltyEngine);
    event WithdrawValidatorUpdated(address newWithdrawValidator);

    event SoftWithdrawTimeLimitUpdated(uint256 newSoftWithdrawTimeLimit);
    event MinPriceBpsUpdated(uint256 newMinPriceBps);
    event SoftWithdrawMaxAgeUpdated(uint256 newSoftWithdrawMaxAge);
    event ForceWithdrawMaxAgeUpdated(uint256 newForceWithdrawMaxAge);
    event SeaportConduitUpdated(bytes32 newSeaportConduitKey);

    event VaultCreated(address owner, address vault);

    event CounterIncremented(address maker, uint256 newCounter);
    event OrderCancelled(bytes32 orderHash);
    event OrderFilled(
        bytes32 orderHash,
        address maker,
        address taker,
        address token,
        uint256 identifier,
        uint128 filledAmount,
        uint256 unitPrice
    );

    // Public constants

    IERC20 public constant WETH =
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    IConduitController public constant CONDUIT_CONTROLLER =
        IConduitController(0x00000000F9490004C11Cef243f5400493c00Ad63);

    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public immutable ORDER_TYPEHASH;

    Vault public immutable vaultImplementation;

    // Public fields

    IOptOutList public optOutList;
    IPriceOracle public priceOracle;
    IRoyaltyEngine public royaltyEngine;
    IWithdrawValidator public withdrawValidator;

    // There is a time limit for listing or accepting a bid directly from the
    // vault and once that passes the only way to withdraw a token is via the
    // force withdraw which requires royalties to get paid
    uint256 public softWithdrawTimeLimit;

    // To avoid the possbility of evading royalties (by withdrawing via
    // a private listing or bid to a different own wallet for a zero or
    // very low price), we enforce the price of every outgoing order to
    // be within a percentage from the actual token's price (determined
    // via a pricing oracle)
    uint256 public minPriceBps;

    // Depending on the action that is taken (force withdrawing or listing / accepting
    // a bid directly within the vault) there are different requirements regarding the
    // staleness of the oracle's price
    uint256 public softWithdrawMaxAge;
    uint256 public forceWithdrawMaxAge;

    // Conduit used for Seaport listings from the vaults
    bytes32 public seaportConduitKey;
    address public seaportConduit;

    // Mapping from order hash to order status
    mapping(bytes32 => OrderStatus) public orderStatuses;
    // Mapping from wallet to current counter
    mapping(address => uint256) public counters;
    // Mapping from wallet to vault
    mapping(address => Vault) public vaults;

    // Constructor

    constructor(
        address _optOutList,
        address _priceOracle,
        address _royaltyEngine
    ) {
        optOutList = IOptOutList(_optOutList);
        priceOracle = IPriceOracle(_priceOracle);
        royaltyEngine = IRoyaltyEngine(_royaltyEngine);

        softWithdrawTimeLimit = 30 days;
        minPriceBps = 8000;

        softWithdrawMaxAge = 1 days;
        forceWithdrawMaxAge = 30 minutes;

        // Use OpenSea's default conduit (so that Seaport listings are available on OpenSea)
        seaportConduitKey = 0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000;
        seaportConduit = 0x1E0049783F008A0085193E00003D00cd54003c71;

        // Deploy a `Vault` contract that all proxies will point to
        vaultImplementation = new Vault();

        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        // TODO: Pre-compute and store as a constant
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain("
                    "string name,"
                    "string version,"
                    "uint256 chainId,"
                    "address verifyingContract"
                    ")"
                ),
                keccak256("Forward"),
                keccak256("1.0"),
                chainId,
                address(this)
            )
        );

        // TODO: Pre-compute and store as a constant
        ORDER_TYPEHASH = keccak256(
            abi.encodePacked(
                "Order(",
                "uint8 itemKind,",
                "address maker,",
                "address token,",
                "uint256 identifierOrCriteria,",
                "uint256 unitPrice,",
                "uint128 amount,",
                "uint256 salt,",
                "uint256 expiration,",
                "uint256 counter",
                ")"
            )
        );
    }

    // Restricted methods

    function updateOptOutList(address newOptOutList) external onlyOwner {
        optOutList = IOptOutList(newOptOutList);
        emit OptOutListUpdated(newOptOutList);
    }

    function updatePriceOracle(address newPriceOracle) external onlyOwner {
        priceOracle = IPriceOracle(newPriceOracle);
        emit PriceOracleUpdated(newPriceOracle);
    }

    function updateRoyaltyEngine(address newRoyaltyEngine) external onlyOwner {
        royaltyEngine = IRoyaltyEngine(newRoyaltyEngine);
        emit RoyaltyEngineUpdated(newRoyaltyEngine);
    }

    function updateWithdrawValidator(address newWithdrawValidator)
        external
        onlyOwner
    {
        withdrawValidator = IWithdrawValidator(newWithdrawValidator);
        emit WithdrawValidatorUpdated(newWithdrawValidator);
    }

    function updateSoftWithdrawTimeLimit(uint256 newSoftWithdrawTimeLimit)
        external
        onlyOwner
    {
        softWithdrawTimeLimit = newSoftWithdrawTimeLimit;
        emit SoftWithdrawTimeLimitUpdated(newSoftWithdrawTimeLimit);
    }

    function updateMinPriceBps(uint256 newMinPriceBps) external onlyOwner {
        minPriceBps = newMinPriceBps;
        emit MinPriceBpsUpdated(newMinPriceBps);
    }

    function updateSoftWithdrawMaxAge(uint256 newSoftWithdrawMaxAge)
        external
        onlyOwner
    {
        softWithdrawMaxAge = newSoftWithdrawMaxAge;
        emit SoftWithdrawMaxAgeUpdated(newSoftWithdrawMaxAge);
    }

    function updateForceWithdrawMaxAge(uint256 newForceWithdrawMaxAge)
        external
        onlyOwner
    {
        forceWithdrawMaxAge = newForceWithdrawMaxAge;
        emit ForceWithdrawMaxAgeUpdated(newForceWithdrawMaxAge);
    }

    function updateSeaportConduit(bytes32 newSeaportConduitKey)
        external
        onlyOwner
    {
        (address newSeaportConduit, bool exists) = CONDUIT_CONTROLLER
            .getConduit(newSeaportConduitKey);
        if (!exists) {
            revert InvalidSeaportConduit();
        }

        seaportConduitKey = newSeaportConduitKey;
        seaportConduit = newSeaportConduit;
        emit SeaportConduitUpdated(newSeaportConduitKey);
    }

    // Public methods

    function createVault() external returns (Vault vault) {
        // Ensure the sender has no vault
        vault = vaults[msg.sender];
        if (address(vault) != address(0)) {
            revert VaultAlreadyExists();
        }

        // Deploy and initialize a vault using EIP1167
        vault = Vault(
            payable(
                address(vaultImplementation).cloneDeterministic(
                    keccak256(abi.encodePacked(msg.sender))
                )
            )
        );
        vault.initialize(address(this), msg.sender);

        // Associate the vault to the sender
        vaults[msg.sender] = vault;

        emit VaultCreated(msg.sender, address(vault));
    }

    function fillBid(FillDetails calldata details) external nonReentrant {
        // Ensure the order is non-criteria-based
        if (uint8(details.order.itemKind) > 1) {
            revert OrderIsInvalid();
        }

        _fillBid(details, details.order.identifierOrCriteria);
    }

    function fillBidWithCriteria(
        FillDetails calldata details,
        uint256 identifier,
        bytes32[] calldata criteriaProof
    ) external nonReentrant {
        // Ensure the order is criteria-based
        if (uint8(details.order.itemKind) < 2) {
            revert OrderIsInvalid();
        }

        // Ensure the provided identifier matches the order's criteria
        if (details.order.identifierOrCriteria != 0) {
            // The zero criteria will match any identifier
            _verifyCriteriaProof(
                identifier,
                details.order.identifierOrCriteria,
                criteriaProof
            );
        }

        _fillBid(details, identifier);
    }

    function cancel(Order[] calldata orders) external {
        uint256 length = orders.length;
        for (uint256 i = 0; i < length; ) {
            Order memory order = orders[i];

            // Only the order's maker can cancel
            if (order.maker != msg.sender) {
                revert Unauthorized();
            }

            // Mark the order as cancelled
            bytes32 orderHash = getOrderHash(order);
            orderStatuses[orderHash].cancelled = true;

            emit OrderCancelled(orderHash);

            unchecked {
                ++i;
            }
        }
    }

    function incrementCounter() external {
        // Similar to Seaport's implementation, incrementing the counter
        // will cancel any orders which were signed with a counter value
        // which is lower than the updated value
        uint256 newCounter;
        unchecked {
            newCounter = ++counters[msg.sender];
        }

        emit CounterIncremented(msg.sender, newCounter);
    }

    function getOrderHash(Order memory order)
        public
        view
        returns (bytes32 orderHash)
    {
        address maker = order.maker;

        // TODO: Optimize by using assembly
        orderHash = keccak256(
            abi.encode(
                ORDER_TYPEHASH,
                order.itemKind,
                maker,
                order.token,
                order.identifierOrCriteria,
                order.unitPrice,
                order.amount,
                order.salt,
                order.expiration,
                counters[maker]
            )
        );
    }

    // Internal methods

    function _fillBid(FillDetails memory details, uint256 identifier) internal {
        Order memory order = details.order;

        address token = order.token;
        address maker = order.maker;
        uint256 unitPrice = order.unitPrice;
        uint128 fillAmount = details.fillAmount;

        // Ensure the maker has initialized a vault
        Vault vault = vaults[maker];
        if (address(vault) == address(0)) {
            revert VaultIsMissing();
        }

        // Ensure the order is not expired
        if (order.expiration <= block.timestamp) {
            revert OrderIsExpired();
        }

        // Compute the order's hash and its EIP712 hash
        bytes32 orderHash = getOrderHash(order);
        bytes32 eip712Hash = _getEIP712Hash(orderHash);

        // Ensure the maker's signature is valid
        OrderStatus memory orderStatus = orderStatuses[orderHash];
        if (
            !orderStatus.validated &&
            ECDSA.recover(eip712Hash, details.signature) != maker
        ) {
            revert InvalidSignature();
        }

        // Ensure the order is not cancelled
        if (orderStatus.cancelled) {
            revert OrderIsCancelled();
        }
        // Ensure the order is fillable
        if (order.amount - orderStatus.filledAmount < fillAmount) {
            revert InsufficientAmountAvailable();
        }

        // Send the payment to the taker
        WETH.transferFrom(maker, msg.sender, unitPrice * fillAmount);

        if (uint8(order.itemKind) % 2 == 0) {
            if (fillAmount != 1) {
                revert InvalidFillAmount();
            }

            // Transfer the token to the maker's vault
            IERC721(token).safeTransferFrom(
                msg.sender,
                address(vault),
                identifier
            );
        } else {
            if (fillAmount < 1) {
                revert InvalidFillAmount();
            }

            // Transfer the token to the maker's vault
            IERC1155(token).safeTransferFrom(
                msg.sender,
                address(vault),
                identifier,
                fillAmount,
                ""
            );
        }

        // Update the order's validated status and filled amount
        orderStatus.validated = true;
        orderStatus.filledAmount += fillAmount;
        orderStatuses[orderHash] = orderStatus;

        emit OrderFilled(
            orderHash,
            maker,
            msg.sender,
            token,
            identifier,
            fillAmount,
            unitPrice
        );
    }

    function _getEIP712Hash(bytes32 structHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(hex"1901", DOMAIN_SEPARATOR, structHash)
            );
    }

    // Taken from:
    // https://github.com/ProjectOpenSea/seaport/blob/dfce06d02413636f324f73352b54a4497d63c310/contracts/lib/CriteriaResolution.sol#L243-L247
    function _verifyCriteriaProof(
        uint256 leaf,
        uint256 root,
        bytes32[] memory criteriaProof
    ) internal pure {
        bool isValid;

        assembly {
            // Store the leaf at the beginning of scratch space
            mstore(0, leaf)

            // Derive the hash of the leaf to use as the initial proof element
            let computedHash := keccak256(0, 0x20)
            // Get memory start location of the first element in proof array
            let data := add(criteriaProof, 0x20)

            for {
                // Left shift by 5 is equivalent to multiplying by 0x20
                let end := add(data, shl(5, mload(criteriaProof)))
            } lt(data, end) {
                // Increment by one word at a time
                data := add(data, 0x20)
            } {
                // Get the proof element
                let loadedData := mload(data)

                // Sort proof elements and place them in scratch space
                let scratch := shl(5, gt(computedHash, loadedData))
                mstore(scratch, computedHash)
                mstore(xor(scratch, 0x20), loadedData)

                // Derive the updated hash
                computedHash := keccak256(0, 0x40)
            }

            isValid := eq(computedHash, root)
        }

        if (!isValid) {
            revert InvalidCriteriaProof();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin/token/ERC721/IERC721.sol";
import {IERC1155} from "openzeppelin/token/ERC1155/IERC1155.sol";
import {ECDSA} from "openzeppelin/utils/cryptography/ECDSA.sol";

import {Forward} from "./Forward.sol";

import {ISeaport} from "./interfaces/external/ISeaport.sol";
import {IWithdrawValidator} from "./interfaces/IWithdrawValidator.sol";

contract Vault is ReentrancyGuard {
    // Structs

    struct ERC721Item {
        IERC721 token;
        uint256 identifier;
    }

    struct ERC1155Item {
        IERC1155 token;
        uint256 identifier;
        uint256 amount;
    }

    // Packed representation of a Seaport listing, with the following limitations:
    // - ETH-denominated
    // - fixed-price

    struct Payment {
        uint256 amount;
        address recipient;
    }

    struct SeaportListingDetails {
        ISeaport.ItemType itemType;
        address token;
        uint256 identifier;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        uint256 salt;
        Payment[] payments;
        bytes signature;
    }

    // Errors

    error AlreadyInitialized();

    error SeaportOrderIsInvalid();
    error SeaportOrderIsUnderpriced();
    error SeaportOrderRoyaltiesAreIncorrect();

    error CollectionOptedOut();
    error TokenDepositIsTooOld();

    error InvalidSignature();
    error Unauthorized();
    error UnsuccessfulPayment();

    // Events

    event RoyaltyPaid(
        address token,
        uint256 identifier,
        uint256 amount,
        uint256 price,
        uint256 royalty
    );

    // Public constants

    IERC20 public constant WETH =
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    ISeaport public constant SEAPORT =
        ISeaport(0x00000000006c3852cbEf3e08E8dF289169EdE581);

    bytes32 public constant SEAPORT_DOMAIN_SEPARATOR =
        0xb50c8913581289bd2e066aeef89fceb9615d490d673131fd1a7047436706834e;

    // Public fields

    Forward public forward;
    address public owner;

    // Mapping from item id to its time of deposit into the vault
    mapping(bytes32 => uint256) public depositTime;

    // Constructor

    function initialize(address _forward, address _owner) public {
        if (address(forward) != address(0)) {
            revert AlreadyInitialized();
        }

        forward = Forward(_forward);
        owner = _owner;
    }

    // Receive fallback

    receive() external payable {
        // Send proceeds from accepted Seaport listings directly to the owner
        _sendPayment(owner, msg.value);
    }

    // Permissioned methods

    function withdrawERC721s(
        ERC721Item[] calldata items,
        bytes[] calldata oracleData,
        address recipient
    ) external payable nonReentrant {
        // Only the owner can withdraw tokens
        if (msg.sender != owner) {
            revert Unauthorized();
        }

        // Cache the protocol address for gas-efficiency
        Forward protocol = forward;

        // Depending on the recipient, royalties might get skipped
        IWithdrawValidator withdrawValidator = protocol.withdrawValidator();
        bool skipRoyalties = address(withdrawValidator) != address(0) &&
            forward.withdrawValidator().canSkipRoyalties(msg.sender, recipient);

        uint256 itemsLength = items.length;
        for (uint256 i = 0; i < itemsLength; ) {
            IERC721 token = items[i].token;
            uint256 identifier = items[i].identifier;

            if (!skipRoyalties) {
                // Fetch the token's price
                uint256 price = protocol.priceOracle().getPrice(
                    address(token),
                    identifier,
                    protocol.forceWithdrawMaxAge(),
                    oracleData[i]
                );

                // Fetch the token's royalties (relative to the token's price)
                (
                    address[] memory royaltyRecipients,
                    uint256[] memory royaltyAmounts
                ) = protocol.royaltyEngine().getRoyaltyView(
                        address(token),
                        identifier,
                        price
                    );

                uint256 totalRoyaltyAmount;

                // Pay the royalties
                uint256 recipientsLength = royaltyRecipients.length;
                for (uint256 j = 0; j < recipientsLength; ) {
                    _sendPayment(royaltyRecipients[j], royaltyAmounts[j]);
                    totalRoyaltyAmount += royaltyAmounts[j];

                    unchecked {
                        ++j;
                    }
                }

                emit RoyaltyPaid(
                    address(token),
                    identifier,
                    1,
                    price,
                    totalRoyaltyAmount
                );
            }

            // Transfer the token out
            token.safeTransferFrom(address(this), recipient, identifier);

            unchecked {
                ++i;
            }
        }
    }

    function withdrawERC1155s(
        ERC1155Item[] calldata items,
        bytes[] calldata oracleData,
        address recipient
    ) external payable nonReentrant {
        // Only the owner can withdraw tokens
        if (msg.sender != owner) {
            revert Unauthorized();
        }

        // Cache the protocol address for gas-efficiency
        Forward protocol = forward;

        // Depending on the recipient, royalties might get skipped
        IWithdrawValidator withdrawValidator = protocol.withdrawValidator();
        bool skipRoyalties = address(withdrawValidator) != address(0) &&
            forward.withdrawValidator().canSkipRoyalties(msg.sender, recipient);

        uint256 itemsLength = items.length;
        for (uint256 i = 0; i < itemsLength; ) {
            IERC1155 token = items[i].token;
            uint256 identifier = items[i].identifier;
            uint256 amount = items[i].amount;

            if (!skipRoyalties) {
                // Fetch the token's price
                uint256 price = protocol.priceOracle().getPrice(
                    address(token),
                    identifier,
                    protocol.forceWithdrawMaxAge(),
                    oracleData[i]
                );

                // Fetch the token's royalties (relative to the token's price)
                (
                    address[] memory royaltyRecipients,
                    uint256[] memory royaltyAmounts
                ) = protocol.royaltyEngine().getRoyaltyView(
                        address(token),
                        identifier,
                        price * amount
                    );

                uint256 totalRoyaltyAmount;

                // Pay the royalties
                uint256 recipientsLength = royaltyRecipients.length;
                for (uint256 j = 0; j < recipientsLength; ) {
                    _sendPayment(royaltyRecipients[j], royaltyAmounts[j]);
                    totalRoyaltyAmount += royaltyAmounts[j];

                    unchecked {
                        ++j;
                    }
                }

                emit RoyaltyPaid(
                    address(token),
                    identifier,
                    amount,
                    price,
                    totalRoyaltyAmount
                );
            }

            // Transfer the token out
            token.safeTransferFrom(
                address(this),
                recipient,
                identifier,
                amount,
                ""
            );

            unchecked {
                ++i;
            }
        }
    }

    function acceptSeaportBid(
        ISeaport.AdvancedOrder calldata order,
        ISeaport.CriteriaResolver[] calldata criteriaResolvers,
        bytes calldata oracleData
    ) external nonReentrant {
        // Only the owner can accept bids
        if (msg.sender != owner) {
            revert Unauthorized();
        }

        if (criteriaResolvers.length > 1) {
            revert SeaportOrderIsInvalid();
        }

        // Validate the offer item
        ISeaport.OfferItem memory paymentItem = order.parameters.offer[0];
        if (
            order.parameters.offer.length != 1 ||
            paymentItem.itemType != ISeaport.ItemType.ERC20 ||
            paymentItem.token != address(WETH) ||
            paymentItem.startAmount != paymentItem.endAmount
        ) {
            revert SeaportOrderIsInvalid();
        }

        ISeaport.ConsiderationItem[] memory consideration = order
            .parameters
            .consideration;

        // Validate the first consideration item
        ISeaport.ConsiderationItem memory nftItem = consideration[0];
        if (
            uint8(nftItem.itemType) < 2 ||
            nftItem.startAmount != nftItem.endAmount
        ) {
            revert SeaportOrderIsInvalid();
        }

        // Validate the rest of consideration items
        uint256 considerationLength = consideration.length;
        for (uint256 i = 1; i < considerationLength; ) {
            ISeaport.ConsiderationItem memory item = consideration[i];
            if (
                item.itemType != ISeaport.ItemType.ERC20 ||
                item.token != address(WETH) ||
                item.startAmount != item.endAmount
            ) {
                revert SeaportOrderIsInvalid();
            }

            unchecked {
                ++i;
            }
        }

        // Cache some fields for gas-efficiency
        Forward protocol = forward;
        address token = nftItem.token;
        uint256 identifier = nftItem.identifierOrCriteria;

        // Properly set the identifier in case of criteria bids
        if (uint8(nftItem.itemType) > 3) {
            identifier = criteriaResolvers[0].identifier;
        }

        // Ensure the token's deposit time is not too far in the past
        bytes32 itemId = keccak256(abi.encode(token, identifier));
        uint256 timeOfDeposit = depositTime[itemId];
        if (
            block.timestamp - timeOfDeposit > protocol.softWithdrawTimeLimit()
        ) {
            revert TokenDepositIsTooOld();
        }

        // Adjust the price to the filled amount
        uint256 amount = (nftItem.endAmount * order.numerator) /
            order.denominator;
        uint256 totalPrice = (paymentItem.endAmount * order.numerator) /
            order.denominator;

        // Fetch the token's price
        uint256 price = protocol.priceOracle().getPrice(
            token,
            identifier,
            protocol.softWithdrawMaxAge(),
            oracleData
        );

        // Ensure the bid's price is within `minPriceBps` of the token's price
        if (totalPrice < (price * amount * protocol.minPriceBps()) / 10000) {
            revert SeaportOrderIsUnderpriced();
        }

        {
            // Fetch the token's royalties
            (
                address[] memory royaltyRecipients,
                uint256[] memory royaltyAmounts
            ) = protocol.royaltyEngine().getRoyaltyView(
                    token,
                    identifier,
                    totalPrice
                );

            // Ensure the royalties are present in the payment items
            // (ordering matters and should match the royalty engine)
            uint256 diff = considerationLength - royaltyAmounts.length;
            for (uint256 i = diff; i < considerationLength; ) {
                if (
                    consideration[i].recipient != royaltyRecipients[i - diff] ||
                    // The royalty should be AT LEAST what's returned by the royalty registry
                    consideration[i].endAmount < royaltyAmounts[i - diff]
                ) {
                    revert SeaportOrderRoyaltiesAreIncorrect();
                }

                unchecked {
                    ++i;
                }
            }
        }

        // An approval is needed for paying the royalties
        address conduit = forward.seaportConduit();
        uint256 allowance = WETH.allowance(address(this), conduit);
        if (allowance < type(uint256).max) {
            WETH.approve(conduit, type(uint256).max);
        }

        // Fulfill bid
        SEAPORT.fulfillAdvancedOrder(
            order,
            criteriaResolvers,
            forward.seaportConduitKey(),
            address(0)
        );

        // Forward any received WETH to the vault's owner
        WETH.transfer(msg.sender, WETH.balanceOf(address(this)));
    }

    // Internal methods

    function _sendPayment(address to, uint256 value) internal {
        (bool success, ) = payable(to).call{value: value}("");
        if (!success) {
            revert UnsuccessfulPayment();
        }
    }

    // ERC1271

    function isValidSignature(bytes32 digest, bytes memory signature)
        external
        view
        returns (bytes4)
    {
        // Ensure any Seaport order originating from this vault is a listing
        // in the native token which is paying out the correct royalties (as
        // specified via the royalty registry)

        (
            SeaportListingDetails memory listingDetails,
            bytes memory oracleData
        ) = abi.decode(signature, (SeaportListingDetails, bytes));

        // Cache the payments for gas-efficiency
        Payment[] memory payments = listingDetails.payments;
        uint256 paymentsLength = payments.length;

        // Keep track of the total payment amount
        uint256 totalPrice;

        // Construct the consideration items
        ISeaport.ConsiderationItem[]
            memory consideration = new ISeaport.ConsiderationItem[](
                paymentsLength
            );
        {
            for (uint256 i = 0; i < paymentsLength; ) {
                uint256 paymentAmount = payments[i].amount;
                totalPrice += paymentAmount;

                consideration[i] = ISeaport.ConsiderationItem({
                    itemType: ISeaport.ItemType.NATIVE,
                    token: address(0),
                    identifierOrCriteria: 0,
                    startAmount: paymentAmount,
                    endAmount: paymentAmount,
                    recipient: payments[i].recipient
                });

                unchecked {
                    ++i;
                }
            }
        }

        // Cache some fields for gas-efficiency
        Forward protocol = forward;
        address token = listingDetails.token;
        uint256 identifier = listingDetails.identifier;
        uint256 amount = listingDetails.amount;

        // Ensure the token's deposit time is not too far in the past
        bytes32 itemId = keccak256(abi.encode(token, identifier));
        uint256 timeOfDeposit = depositTime[itemId];
        if (
            block.timestamp - timeOfDeposit > protocol.softWithdrawTimeLimit()
        ) {
            revert TokenDepositIsTooOld();
        }

        // Ensure the listing's validity time is not more than the oracle's price max age
        uint256 oraclePriceListMaxAge = protocol.softWithdrawMaxAge();
        if (
            listingDetails.endTime - listingDetails.startTime >
            oraclePriceListMaxAge
        ) {
            revert SeaportOrderIsInvalid();
        }

        // Fetch the token's price
        uint256 price = protocol.priceOracle().getPrice(
            token,
            identifier,
            oraclePriceListMaxAge,
            oracleData
        );

        // Ensure the listing's price is within `minPriceBps` of the token's price
        if (totalPrice < (price * amount * protocol.minPriceBps()) / 10000) {
            revert SeaportOrderIsUnderpriced();
        }

        {
            // Fetch the token's royalties
            (
                address[] memory royaltyRecipients,
                uint256[] memory royaltyAmounts
            ) = protocol.royaltyEngine().getRoyaltyView(
                    token,
                    identifier,
                    totalPrice
                );

            // Ensure the royalties are present in the payment items
            // (ordering matters and should match the royalty engine)
            uint256 diff = paymentsLength - royaltyAmounts.length;
            for (uint256 i = diff; i < paymentsLength; ) {
                if (
                    payments[i].recipient != royaltyRecipients[i - diff] ||
                    // The royalty should be AT LEAST what's returned by the royalty registry
                    payments[i].amount < royaltyAmounts[i - diff]
                ) {
                    revert SeaportOrderRoyaltiesAreIncorrect();
                }

                unchecked {
                    ++i;
                }
            }
        }

        bytes32 orderHash;
        {
            // The listing should have a single offer item
            ISeaport.OfferItem[] memory offer = new ISeaport.OfferItem[](1);
            offer[0] = ISeaport.OfferItem({
                itemType: listingDetails.itemType,
                token: token,
                identifierOrCriteria: identifier,
                startAmount: amount,
                endAmount: amount
            });

            ISeaport.OrderComponents memory order;
            order.offerer = address(this);
            // order.zone = address(0);
            order.offer = offer;
            order.consideration = consideration;
            order.orderType = ISeaport.OrderType.PARTIAL_OPEN;
            order.startTime = listingDetails.startTime;
            order.endTime = listingDetails.endTime;
            // order.zoneHash = bytes32(0);
            order.salt = listingDetails.salt;
            order.conduitKey = protocol.seaportConduitKey();
            order.counter = SEAPORT.getCounter(address(this));

            orderHash = SEAPORT.getOrderHash(order);
        }

        // Ensure the order was properly constructed
        if (
            digest !=
            keccak256(
                abi.encodePacked(hex"1901", SEAPORT_DOMAIN_SEPARATOR, orderHash)
            )
        ) {
            revert SeaportOrderIsInvalid();
        }

        // Ensure the underlying order was signed by the vault's owner
        if (ECDSA.recover(digest, listingDetails.signature) != owner) {
            revert InvalidSignature();
        }

        return this.isValidSignature.selector;
    }

    // ERC721

    function onERC721Received(
        address, // operator
        address, // from
        uint256 tokenId,
        bytes calldata // data
    ) external returns (bytes4) {
        IERC721 token = IERC721(msg.sender);
        if (forward.optOutList().optedOut(address(token))) {
            revert CollectionOptedOut();
        }

        // Update the item's deposit time
        bytes32 itemId = keccak256(abi.encode(address(token), tokenId));
        depositTime[itemId] = block.timestamp;

        // Approve the token for listing if needed
        address conduit = forward.seaportConduit();
        bool isApproved = token.isApprovedForAll(address(this), conduit);
        if (!isApproved) {
            token.setApprovalForAll(conduit, true);
        }

        return this.onERC721Received.selector;
    }

    // ERC1155

    function onERC1155Received(
        address, // operator
        address, // from
        uint256 id,
        uint256, // value
        bytes calldata // data
    ) external returns (bytes4) {
        IERC1155 token = IERC1155(msg.sender);
        if (forward.optOutList().optedOut(address(token))) {
            revert CollectionOptedOut();
        }

        // Update the item's deposit time
        bytes32 itemId = keccak256(abi.encode(address(token), id));
        depositTime[itemId] = block.timestamp;

        // Approve the token for listing if needed
        address conduit = forward.seaportConduit();
        bool isApproved = token.isApprovedForAll(address(this), conduit);
        if (!isApproved) {
            token.setApprovalForAll(conduit, true);
        }

        return this.onERC1155Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IRoyaltyEngine {
    function getRoyaltyView(
        address collection,
        uint256 tokenId,
        uint256 value
    )
        external
        view
        returns (address[] memory recipients, uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ISeaport {
    enum ItemType {
        NATIVE,
        ERC20,
        ERC721,
        ERC1155,
        ERC721_WITH_CRITERIA,
        ERC1155_WITH_CRITERIA
    }

    enum OrderType {
        FULL_OPEN,
        PARTIAL_OPEN,
        FULL_RESTRICTED,
        PARTIAL_RESTRICTED
    }

    enum Side {
        OFFER,
        CONSIDERATION
    }

    struct OfferItem {
        ItemType itemType;
        address token;
        uint256 identifierOrCriteria;
        uint256 startAmount;
        uint256 endAmount;
    }

    struct ConsiderationItem {
        ItemType itemType;
        address token;
        uint256 identifierOrCriteria;
        uint256 startAmount;
        uint256 endAmount;
        address recipient;
    }

    struct OrderComponents {
        address offerer;
        address zone;
        OfferItem[] offer;
        ConsiderationItem[] consideration;
        OrderType orderType;
        uint256 startTime;
        uint256 endTime;
        bytes32 zoneHash;
        uint256 salt;
        bytes32 conduitKey;
        uint256 counter;
    }

    struct OrderParameters {
        address offerer;
        address zone;
        OfferItem[] offer;
        ConsiderationItem[] consideration;
        OrderType orderType;
        uint256 startTime;
        uint256 endTime;
        bytes32 zoneHash;
        uint256 salt;
        bytes32 conduitKey;
        uint256 totalOriginalConsiderationItems;
    }

    struct Order {
        OrderParameters parameters;
        bytes signature;
    }

    struct AdvancedOrder {
        OrderParameters parameters;
        uint120 numerator;
        uint120 denominator;
        bytes signature;
        bytes extraData;
    }

    struct CriteriaResolver {
        uint256 orderIndex;
        Side side;
        uint256 index;
        uint256 identifier;
        bytes32[] criteriaProof;
    }

    function information()
        external
        view
        returns (
            string memory version,
            bytes32 domainSeparator,
            IConduitController conduitController
        );

    function getCounter(address offerer)
        external
        view
        returns (uint256 counter);

    function getOrderHash(OrderComponents calldata order)
        external
        view
        returns (bytes32 orderHash);

    function fulfillOrder(Order calldata order, bytes32 fulfillerConduitKey)
        external
        payable
        returns (bool fulfilled);

    function fulfillAdvancedOrder(
        AdvancedOrder calldata advancedOrder,
        CriteriaResolver[] calldata criteriaResolvers,
        bytes32 fulfillerConduitKey,
        address recipient
    ) external payable returns (bool fulfilled);

    function cancel(ISeaport.OrderComponents[] calldata orders)
        external
        returns (bool cancelled);

    function incrementCounter() external returns (uint256 newCounter);
}

interface IConduitController {
    function getConduit(bytes32 conduitKey)
        external
        view
        returns (address conduit, bool exists);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IOptOutList {
    function optedOut(address token) external view returns (bool status);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IPriceOracle {
    function getPrice(
        address token,
        uint256 tokenId,
        uint256 maxAge,
        bytes calldata offChainData
    ) external view returns (uint256 price);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IWithdrawValidator {
    function canSkipRoyalties(address from, address to) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}