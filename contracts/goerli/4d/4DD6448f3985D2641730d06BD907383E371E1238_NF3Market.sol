// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "./Interfaces/INF3Market.sol";
import "./Interfaces/ISwap.sol";
import "./Interfaces/IReserve.sol";

/// @title NF3 Market
/// @author Jack Jin
/// @author Priyam Anand
/// @notice This contract inherits from INF3Market interface.
/// @dev This most of the functions in this contract are public callable.
/// @dev This contract has all the public facing functions. This contract is used as the implementation address at NF3Proxy contract.

contract NF3Market is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    ERC2771ContextUpgradeable,
    INF3Market
{
    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    /// @notice Vault contract address
    address public vaultAddress;

    /// @notice Swap contract address
    address public swapAddress;

    /// @notice Reserve contract address
    address public reserveAddress;

    /* ===== INIT ===== */

    /// @dev Constructor
    /// NOTE : Only meant for trusted forwarer address because this address is immutable and
    ///        is not stored in the storage.
    constructor(address trustedForwarder)
        ERC2771ContextUpgradeable(trustedForwarder)
    {
        _disableInitializers();
    }

    /// @dev Initialize
    function initialize() public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    /// -----------------------------------------------------------------------
    /// Cancel Actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from ISwap
    function cancelListing(Listing calldata _listing, bytes memory _signature)
        external
        whenNotPaused
        nonReentrant
    {
        // Call core contract.
        ISwap(swapAddress).cancelListing(_listing, _signature, _msgSender());
    }

    /// @notice Inherit from ISwap
    function cancelSwapOffer(SwapOffer calldata _offer, bytes memory _signature)
        external
        whenNotPaused
        nonReentrant
    {
        // Call core contract.
        ISwap(swapAddress).cancelSwapOffer(_offer, _signature, _msgSender());
    }

    /// @notice Inherit from ISwap
    function cancelCollectionSwapOffer(
        CollectionSwapOffer calldata _offer,
        bytes memory _signature
    ) external whenNotPaused nonReentrant {
        // Call core contract.
        ISwap(swapAddress).cancelCollectionSwapOffer(
            _offer,
            _signature,
            _msgSender()
        );
    }

    /// @notice Inherit from IReserve
    function cancelReserveOffer(
        ReserveOffer calldata _offer,
        bytes memory _signature
    ) external whenNotPaused nonReentrant {
        // Call core contract.
        IReserve(reserveAddress).cancelReserveOffer(
            _offer,
            _signature,
            _msgSender()
        );
    }

    function cancelCollectionReserveOffer(
        CollectionReserveOffer calldata _offer,
        bytes memory _signature
    ) external whenNotPaused nonReentrant {
        // Call core contract.
        IReserve(reserveAddress).cancelCollectionReserveOffer(
            _offer,
            _signature,
            _msgSender()
        );
    }

    /// -----------------------------------------------------------------------
    /// Direct Swap actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from ISwap
    function directSwap(
        Listing calldata _listing,
        bytes memory _signature,
        uint256 _swapId,
        address[] memory _tokens,
        uint256[] memory _tokenIds,
        bytes32[][] memory _proofs,
        Royalty calldata _royalty
    ) external payable whenNotPaused nonReentrant {
        // Check the length of tokens must be same as tokenIds.
        equalLength(_tokens, _tokenIds);

        // Transfer eth to the vault.
        (bool success, ) = payable(vaultAddress).call{value: msg.value}("");
        if (!success)
            revert NF3MarketError(NF3MarketErrorCodes.FAILED_TO_SEND_ETH);

        // Call core contract.
        ISwap(swapAddress).directSwap(
            _listing,
            _signature,
            _swapId,
            _msgSender(),
            _tokens,
            _tokenIds,
            _proofs,
            msg.value,
            _royalty
        );
    }

    /// @notice Inherit from INF3Market
    function acceptUnlistedDirectSwapOffer(
        SwapOffer calldata _offer,
        bytes memory _signature,
        Assets calldata _consideration,
        bytes32[] calldata _proof,
        Royalty calldata _royalty
    ) external payable whenNotPaused nonReentrant {
        // Transfer eth to the vault.
        (bool success, ) = payable(vaultAddress).call{value: msg.value}("");
        if (!success)
            revert NF3MarketError(NF3MarketErrorCodes.FAILED_TO_SEND_ETH);

        // Call core contract.
        ISwap(swapAddress).acceptUnlistedDirectSwapOffer(
            _offer,
            _signature,
            _consideration,
            _proof,
            _msgSender(),
            msg.value,
            _royalty
        );
    }

    /// @notice Inherit from INF3Market
    function acceptListedDirectSwapOffer(
        Listing calldata _listing,
        bytes memory _listingSignature,
        SwapOffer calldata _offer,
        bytes memory _offerSignature,
        bytes32[] calldata _proof
    ) external whenNotPaused nonReentrant {
        // Call core contract.
        ISwap(swapAddress).acceptListedDirectSwapOffer(
            _listing,
            _listingSignature,
            _offer,
            _offerSignature,
            _proof,
            _msgSender()
        );
    }

    /// @notice Inherit from ISwap
    function acceptCollectionOffer(
        CollectionSwapOffer calldata _offer,
        bytes memory _signature,
        address[] memory _tokens,
        uint256[] memory _tokenIds,
        bytes32[][] memory _proofs,
        Royalty calldata _royalty
    ) external payable whenNotPaused nonReentrant {
        // Check the length of tokens must be same as tokenIds.
        equalLength(_tokens, _tokenIds);

        // Transfer eth to the vault.
        (bool success, ) = payable(vaultAddress).call{value: msg.value}("");
        if (!success)
            revert NF3MarketError(NF3MarketErrorCodes.FAILED_TO_SEND_ETH);

        // Call core contract.
        ISwap(swapAddress).acceptCollectionOffer(
            _offer,
            _signature,
            _tokens,
            _tokenIds,
            _proofs,
            _msgSender(),
            msg.value,
            _royalty
        );
    }

    /// -----------------------------------------------------------------------
    /// Reserve actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from IReserve
    function reserveDeposit(
        Listing calldata _listing,
        bytes memory _listingSignature,
        uint256 _reserveId
    ) external payable whenNotPaused nonReentrant {
        // Transfer eth to the vault.
        (bool success, ) = payable(vaultAddress).call{value: msg.value}("");
        if (!success)
            revert NF3MarketError(NF3MarketErrorCodes.FAILED_TO_SEND_ETH);

        // Call core contract.
        IReserve(reserveAddress).reserveDeposit(
            _listing,
            _listingSignature,
            _reserveId,
            _msgSender(),
            msg.value
        );
    }

    /// @notice Inherit from IReserve
    function acceptUnlistedReserveOffer(
        ReserveOffer calldata _offer,
        bytes memory _offerSignature,
        Assets calldata _consideration,
        bytes32[] calldata _proof,
        Royalty calldata _royalty
    ) external payable whenNotPaused nonReentrant {
        // Transfer eth to the vault.
        (bool success, ) = payable(vaultAddress).call{value: msg.value}("");
        if (!success)
            revert NF3MarketError(NF3MarketErrorCodes.FAILED_TO_SEND_ETH);

        //  Call core contract
        IReserve(reserveAddress).acceptUnlistedReserveOffer(
            _offer,
            _offerSignature,
            _consideration,
            _proof,
            _msgSender(),
            msg.value,
            _royalty
        );
    }

    /// @notice Inherit from IReserve
    function acceptListedReserveOffer(
        Listing calldata _listing,
        bytes memory _listingSignature,
        ReserveOffer calldata _offer,
        bytes memory _offerSignature,
        bytes32[] memory _proof
    ) external whenNotPaused nonReentrant {
        // Call core contract.
        IReserve(reserveAddress).acceptListedReserveOffer(
            _listing,
            _listingSignature,
            _offer,
            _offerSignature,
            _proof,
            _msgSender()
        );
    }

    function acceptCollectionReserveOffer(
        CollectionReserveOffer calldata _offer,
        bytes memory _signature,
        address[] memory _tokens,
        uint256[] memory _tokenIds,
        bytes32[][] memory _proofs,
        Royalty calldata _royalty
    ) external payable whenNotPaused nonReentrant {
        // Transfer eth to the vault.
        (bool success, ) = payable(vaultAddress).call{value: msg.value}("");
        if (!success)
            revert NF3MarketError(NF3MarketErrorCodes.FAILED_TO_SEND_ETH);

        // Call core contract.
        IReserve(reserveAddress).acceptCollectionReserveOffer(
            _offer,
            _signature,
            _tokens,
            _tokenIds,
            _proofs,
            _msgSender(),
            msg.value,
            _royalty
        );
    }

    /// @notice Inherit from IReserve
    function payRemains(
        Reservation calldata _reservation,
        uint256 _positionTokenId,
        Royalty calldata _royalty
    ) external payable nonReentrant {
        // Transfer eth to the vault.
        (bool success, ) = payable(vaultAddress).call{value: msg.value}("");
        if (!success)
            revert NF3MarketError(NF3MarketErrorCodes.FAILED_TO_SEND_ETH);

        // Call core contract.
        IReserve(reserveAddress).payRemains(
            _reservation,
            _positionTokenId,
            _msgSender(),
            msg.value,
            _royalty
        );
    }

    /// @notice Inherit from IReserve
    function claimDefaulted(
        Reservation calldata _reservation,
        uint256 _positionTokenId
    ) external whenNotPaused nonReentrant {
        // Call core contract.
        IReserve(reserveAddress).claimDefaulted(
            _reservation,
            _positionTokenId,
            _msgSender()
        );
    }

    /// @notice Inherit from IReserve
    function claimAirdrop(
        Reservation calldata _reservation,
        uint256 _positionTokenId,
        address _airdropContract,
        bytes calldata _data
    ) external whenNotPaused nonReentrant {
        // Call core contracts
        IReserve(reserveAddress).claimAirdrop(
            _reservation,
            _positionTokenId,
            _airdropContract,
            _data,
            _msgSender()
        );
    }

    /// -----------------------------------------------------------------------
    /// Owner actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from INF3Market
    function setSwap(address _swapAddress) external override onlyOwner {
        if (_swapAddress == address(0)) {
            revert NF3MarketError(NF3MarketErrorCodes.INVALID_ADDRESS);
        }
        emit SwapSet(swapAddress, _swapAddress);

        swapAddress = _swapAddress;
    }

    /// @notice Inherit from INF3Market
    function setReserve(address _reserveAddress) external override onlyOwner {
        if (_reserveAddress == address(0)) {
            revert NF3MarketError(NF3MarketErrorCodes.INVALID_ADDRESS);
        }
        emit ReserveSet(reserveAddress, _reserveAddress);

        reserveAddress = _reserveAddress;
    }

    /// @notice Inherit from INF3Market
    function setVault(address _vaultAddress) external override onlyOwner {
        if (_vaultAddress == address(0)) {
            revert NF3MarketError(NF3MarketErrorCodes.INVALID_ADDRESS);
        }
        emit VaultSet(vaultAddress, _vaultAddress);

        vaultAddress = _vaultAddress;
    }

    /// @notice Inherit from INF3Market
    function setPause(bool _setPause) external override onlyOwner {
        if (_setPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    /// -----------------------------------------------------------------------
    /// Interal functions
    /// -----------------------------------------------------------------------

    /// @dev Compare the length of arraies.
    /// @param _addr NFT token address array
    /// @param _ids NFT token id array
    function equalLength(address[] memory _addr, uint256[] memory _ids)
        internal
        pure
    {
        if (_addr.length != _ids.length) {
            revert NF3MarketError(NF3MarketErrorCodes.LENGTH_NOT_EQUAL);
        }
    }

    /// -----------------------------------------------------------------------
    /// EIP-2771 Actions
    /// -----------------------------------------------------------------------

    function _msgSender()
        internal
        view
        override(ERC2771ContextUpgradeable, ContextUpgradeable)
        returns (address)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        override(ERC2771ContextUpgradeable, ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }

    /// @dev This empty reserved space is put in place to allow future versions to add new
    /// variables without shifting down storage in the inheritance chain.
    /// See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771ContextUpgradeable is Initializable, ContextUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// @title NF3 Market Interface
/// @author Jack Jin
/// @author Priyam Anand
/// @dev This interface defines the functions related to public interaction and proxy interaction of the system.

interface INF3Market {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    enum NF3MarketErrorCodes {
        FAILED_TO_SEND_ETH,
        LENGTH_NOT_EQUAL,
        INVALID_ADDRESS
    }

    error NF3MarketError(NF3MarketErrorCodes code);

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /// @dev Emits when new swap address has set.
    /// @param oldSwapAddress Previous swap contract address
    /// @param newSwapAddress New swap contract address
    event SwapSet(address oldSwapAddress, address newSwapAddress);

    /// @dev Emits when new reserve address has set.
    /// @param oldReserveAddress Previous reserve contract address
    /// @param newReserveAddress New reserve contract address
    event ReserveSet(address oldReserveAddress, address newReserveAddress);

    /// @dev Emits when new vault address has set.
    /// @param oldVaultAddress Previous vault contract address
    /// @param newVaultAddress New vault contract address
    event VaultSet(address oldVaultAddress, address newVaultAddress);

    /// -----------------------------------------------------------------------
    /// Owner actions
    /// -----------------------------------------------------------------------

    /// @dev Set Swap contract address.
    /// @param swapAddress Swap contract address
    function setSwap(address swapAddress) external;

    /// @dev Set Reserve contract address.
    /// @param reserveAddress Reserve contract address
    function setReserve(address reserveAddress) external;

    /// @dev Set Vault contract address.
    /// @param vaultAddress Vault contract address
    function setVault(address vaultAddress) external;

    /// @dev Set pause state of the contract.
    /// @param _setPause Boolean value of the pause state
    function setPause(bool _setPause) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../../utils/DataTypes.sol";

/// @title NF3 Swap Interface
/// @author Jack Jin
/// @author Priyam Anand
/// @dev This interface defines all the functions related to swap features of the platform.

interface ISwap {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    enum SwapErrorCodes {
        NOT_MARKET,
        CALLER_NOT_APPROVED,
        INVALID_NONCE,
        ITEM_EXPIRED,
        OPTION_DOES_NOT_EXIST,
        INTENDED_FOR_PEER_TO_PEER_TRADE,
        INVALID_ADDRESS
    }

    error SwapError(SwapErrorCodes code);

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /// @dev Emits when listing has cancelled.
    /// @param listing Listing assets, details and seller's info
    event ListingCancelled(Listing listing);

    /// @dev Emits when swap offer has cancelled.
    /// @param offer Offer information
    event SwapOfferCancelled(SwapOffer offer);

    /// @dev Emits when collection offer has cancelled.
    /// @param offer Offer information
    event CollectionSwapOfferCancelled(CollectionSwapOffer offer);

    /// @dev Emits when direct swap has happened.
    /// @param listing Listing assets, details and seller's info
    /// @param offeredAssets Assets offered by the buyer
    /// @param swapId Swap id
    /// @param user Address of the buyer
    event DirectSwapped(
        Listing listing,
        Assets offeredAssets,
        uint256 swapId,
        address indexed user
    );

    /// @dev Emits when swap offer has been accepted by the user.
    /// @param offer Swap offer assets and details
    /// @param considerationItems Assets given by the user
    /// @param user Address of the user who accepted the offer
    event UnlistedSwapOfferAccepted(
        SwapOffer offer,
        Assets considerationItems,
        address indexed user
    );

    /// @dev Emits when swap offer has been accepted by a listing owner.
    /// @param listing Listing assets info
    /// @param offer Swap offer info
    /// @param user Listing owner
    event ListedSwapOfferAccepted(
        Listing listing,
        SwapOffer offer,
        address indexed user
    );

    /// @dev Emits when collection swap offer has accepted by the seller.
    /// @param offer Collection offer assets and details
    /// @param considerationItems Assets given by the seller
    /// @param user Address of the buyer
    event CollectionSwapOfferAccepted(
        CollectionSwapOffer offer,
        Assets considerationItems,
        address indexed user
    );

    /// @dev Emits when status has changed.
    /// @param oldStatus Previous status
    /// @param newStatus New status
    event NonceSet(Status oldStatus, Status newStatus);

    /// @dev Emits when new market address has set.
    /// @param oldMarketAddress Previous market contract address
    /// @param newMarketAddress New market contract address
    event MarketSet(address oldMarketAddress, address newMarketAddress);

    /// @dev Emits when new reserve address has set.
    /// @param oldVaultAddress Previous vault contract address
    /// @param newVaultAddress New vault contract address
    event VaultSet(address oldVaultAddress, address newVaultAddress);

    /// @dev Emits when new reserve address has set.
    /// @param oldReserveAddress Previous reserve contract address
    /// @param newReserveAddress New reserve contract address
    event ReserveSet(address oldReserveAddress, address newReserveAddress);

    /// -----------------------------------------------------------------------
    /// Cancel Actions
    /// -----------------------------------------------------------------------

    /// @dev Cancel listing.
    /// @param listing Listing parameters
    /// @param signature Signature of the listing parameters
    /// @param user Listing owner
    function cancelListing(
        Listing calldata listing,
        bytes memory signature,
        address user
    ) external;

    /// @dev Cancel Swap offer.
    /// @param offer Collection offer patameter
    /// @param signature Signature of the offer patameters
    /// @param user Collection offer owner
    function cancelSwapOffer(
        SwapOffer calldata offer,
        bytes memory signature,
        address user
    ) external;

    /// @dev Cancel collection level offer.
    /// @param offer Collection offer patameter
    /// @param signature Signature of the offer patameters
    /// @param user Collection offer owner
    function cancelCollectionSwapOffer(
        CollectionSwapOffer calldata offer,
        bytes memory signature,
        address user
    ) external;

    /// -----------------------------------------------------------------------
    /// Swap Actions
    /// -----------------------------------------------------------------------

    /// @dev Direct swap of bundle of NFTs + FTs with other bundles.
    /// @param listing Listing assets and details
    /// @param signature Signature as a proof of listing
    /// @param swapId Index of swap option being used
    /// @param tokens NFT addresses being offered
    /// @param tokenIds Token ids of NFT being offered
    /// @param value Eth value sent in the function call
    /// @param royalty Buyer's royalty info
    function directSwap(
        Listing calldata listing,
        bytes memory signature,
        uint256 swapId,
        address user,
        address[] memory tokens,
        uint256[] memory tokenIds,
        bytes32[][] memory proofs,
        uint256 value,
        Royalty calldata royalty
    ) external;

    /// @dev Accpet unlisted direct swap offer.
    /// @dev User should see the swap offer and accpet that offer.
    /// @param offer Multi offer assets and details
    /// @param signature Signature as a proof of offer
    /// @param consideration Consideration assets been provided by the user
    /// @param proof Merkle proof that the considerationItems is valid
    /// @param user Address of the user who accepted this offer
    /// @param royalty Seller's royalty info
    function acceptUnlistedDirectSwapOffer(
        SwapOffer calldata offer,
        bytes memory signature,
        Assets calldata consideration,
        bytes32[] calldata proof,
        address user,
        uint256 value,
        Royalty calldata royalty
    ) external;

    /// @dev Accept listed direct swap offer.
    /// @dev Only listing owner should accept that offer.
    /// @param listing Listing assets and parameters
    /// @param listingSignature Signature as a proof of listing
    /// @param offer Offering assets and parameters
    /// @param offerSignature Signature as a proof of offer
    /// @param proof Mekrle proof that the listed assets are valid
    /// @param user Listing owner
    function acceptListedDirectSwapOffer(
        Listing calldata listing,
        bytes memory listingSignature,
        SwapOffer calldata offer,
        bytes memory offerSignature,
        bytes32[] calldata proof,
        address user
    ) external;

    /// @dev Accept collection offer.
    /// @dev Anyone who holds the consideration assets can accpet this offer.
    /// @param offer Collection offer assets and details
    /// @param signature Signature as a proof of offer
    /// @param tokens NFT addresses being offered
    /// @param tokenIds Token ids of NFT being offered
    /// @param user Seller address
    /// @param value Eth value send in the function call
    /// @param royalty Seller's royalty info
    function acceptCollectionOffer(
        CollectionSwapOffer memory offer,
        bytes memory signature,
        address[] memory tokens,
        uint256[] memory tokenIds,
        bytes32[][] memory proofs,
        address user,
        uint256 value,
        Royalty calldata royalty
    ) external;

    /// -----------------------------------------------------------------------
    /// Storage Actions
    /// -----------------------------------------------------------------------

    /// @dev Set the nonce value of a user. Can only be called by reserve contract.
    /// @param _owner Address of the user
    /// @param _nonce Nonce value of the user
    /// @param _status Status to be set
    function setNonce(
        address _owner,
        uint256 _nonce,
        Status _status
    ) external;

    /// -----------------------------------------------------------------------
    /// View actions
    /// -----------------------------------------------------------------------

    /// @dev Check if the nonce is in correct status.
    /// @param owner Owner address
    /// @param nonce Nonce value
    /// @param status Status of nonce
    function checkNonce(
        address owner,
        uint256 nonce,
        Status status
    ) external view;

    /// -----------------------------------------------------------------------
    /// Owner actions
    /// -----------------------------------------------------------------------

    /// @dev Set Market contract address.
    /// @param _marketAddress Market contract address
    function setMarket(address _marketAddress) external;

    /// @dev Set Vault contract address.
    /// @param _vaultAddress Vault contract address
    function setVault(address _vaultAddress) external;

    /// @dev Set Reserve contract address.
    /// @param _reserveAddress Reserve contract address
    function setReserve(address _reserveAddress) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../../utils/DataTypes.sol";

/// @title NF3 Reserve Interface
/// @author Jack Jin
/// @author Priyam Anand
/// @dev This interface defines all the functions related to reservation swap features of the platform.

interface IReserve {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    enum ReserveErrorCodes {
        NOT_MARKET,
        TIME_OVERFLOW,
        NOT_POSITION_TOKEN_OWNER,
        NOT_TIME_TO_CLAIM,
        OPTION_DOES_NOT_EXIST,
        INVALID_POSITION_TOKEN,
        INTENDED_FOR_PEER_TO_PEER_TRADE,
        INVALID_USER,
        INVALID_RESERVATION_DURATION,
        INVALID_ADDRESS
    }

    error ReserveError(ReserveErrorCodes code);

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /// @dev Emits when the offer has cancelled.
    /// @param offer Reservation offer info
    event ReserveOfferCancelled(ReserveOffer offer);

    /// @dev Emits when the collectoin offer has been cancelled
    /// @param offer Collection reserve offer info
    event CollectionReserveOfferCancelled(CollectionReserveOffer offer);

    /// @dev Emits when the buyer has deposited reserve assets.
    /// @param listing Listing info
    /// @param reservation Reservation info
    /// @param reserveId Reserve id
    /// @param positionTokenId Token if of the position token
    /// @param user Buyer address
    event ReserveDeposited(
        Listing listing,
        Reservation reservation,
        uint256 reserveId,
        uint256 positionTokenId,
        address indexed user
    );

    /// @dev Emits when the seller has accepted listed reservation offer.
    /// @param reservation Reservation info
    /// @param positionTokenId Token if of the position token
    /// @param user Listing owner
    event ListedReserveOfferAccepted(
        Listing listing,
        ReserveOffer offer,
        Reservation reservation,
        uint256 positionTokenId,
        address indexed user
    );

    /// @dev Emits when the offer has been accepted
    /// @param offer Reservation offer accepted
    /// @param reservation Reservation info
    /// @param considerationItems Assets given by the user
    /// @param positionTokenId Token id of the position token
    /// @param user Asset owner
    event UnlistedReserveOfferAccepted(
        ReserveOffer offer,
        Reservation reservation,
        Assets considerationItems,
        uint256 positionTokenId,
        address indexed user
    );

    /// @dev Emits when the collection offer has been accepted
    /// @param offer Reservation collection offer that is accepted
    /// @param considerationItem Assets given by the user
    /// @param reservation Reservation info
    /// @param positionTokenId TokenId of the position token for this trade
    /// @param user Assets owner
    event CollectionReserveOfferAccepted(
        CollectionReserveOffer offer,
        Assets considerationItem,
        Reservation reservation,
        uint256 positionTokenId,
        address indexed user
    );

    /// @dev Emits when the buyer has paid remaining reserve assets.
    /// @param reservation Reservation info
    /// @param positionTokenId Position token id
    /// @param user Buyer address
    event RemainsPaid(
        Reservation reservation,
        uint256 positionTokenId,
        address indexed user
    );

    /// @dev Emits when the seller has claimed locked assets.
    /// @param reservation Reservation info
    /// @param positionTokenId Position token id
    /// @param user Seller address
    event Claimed(
        Reservation reservation,
        uint256 positionTokenId,
        address user
    );

    /// @dev Emits when new market address has set.
    /// @param oldMarketAddress Previous market contract address
    /// @param newMarketAddress New market contract address
    event MarketSet(address oldMarketAddress, address newMarketAddress);

    /// @dev Emits when new swap address has set.
    /// @param oldSwapAddress Previous swap contract address
    /// @param newSwapAddress New swap contract address
    event SwapSet(address oldSwapAddress, address newSwapAddress);

    /// @dev Emits when new vault address has set.
    /// @param oldVaultAddress Previous vault contract address
    /// @param newVaultAddress New vault contract address
    event VaultSet(address oldVaultAddress, address newVaultAddress);

    /// @dev Emits when new position token address has set.
    /// @param oldPositionTokenAddress Previous position token contract address
    /// @param newPositionTokenAddress New position token contract address
    event PositionTokenSet(
        address oldPositionTokenAddress,
        address newPositionTokenAddress
    );

    /// @dev Emits when new whitelist contract address has set
    /// @param oldWhitelistAddress Previous whitelist contract address
    /// @param newWhitelistAddress New whitelist contract address
    event WhitelistSet(
        address oldWhitelistAddress,
        address newWhitelistAddress
    );

    /// @dev Emits when minimum reservation duration is updated
    /// @param oldMinimumReservationDuration Previous minimum reservation duration
    /// @param newMinimumReservationDuration New minimum reservation duration
    event MinimumReservationDurationSet(
        uint256 oldMinimumReservationDuration,
        uint256 newMinimumReservationDuration
    );

    /// @dev Emits when airdrop claim implementation address is set
    /// @param oldAirdropClaimImplementation Previous air drop claim implementation address
    /// @param newAirdropClaimImplementation New air drop claim implementation address
    event AirdropClaimImplementationSet(
        address oldAirdropClaimImplementation,
        address newAirdropClaimImplementation
    );

    /// -----------------------------------------------------------------------
    /// Cancel Actions
    /// -----------------------------------------------------------------------

    /// @dev Cancel reserve offer.
    /// @param offer Reserve offer info
    /// @param offerSignature Signature of the offer info
    /// @param user Offer owner
    function cancelReserveOffer(
        ReserveOffer calldata offer,
        bytes memory offerSignature,
        address user
    ) external;

    /// @dev Cancel collection reservation offer
    /// @param offer Collection reserve offer info
    /// @param signature Signature of the offer
    /// @param user Offer owner
    function cancelCollectionReserveOffer(
        CollectionReserveOffer calldata offer,
        bytes memory signature,
        address user
    ) external;

    /// -----------------------------------------------------------------------
    /// Reserve swap Actions
    /// -----------------------------------------------------------------------

    /// @dev Deposit reservation assets.
    /// @param listing Listing info
    /// @param listingSignature Signature of listing info
    /// @param reserveId Listing reserve id
    /// @param user Buyer address
    /// @param value Deposit Eth amount of buyer
    function reserveDeposit(
        Listing calldata listing,
        bytes memory listingSignature,
        uint256 reserveId,
        address user,
        uint256 value
    ) external;

    /// @dev Accept reservation offer using a listing.
    /// @param listing Listing info
    /// @param listingSignature Signature of listing info
    /// @param offer Reservation offer info
    /// @param offerSignature Signature of offer info
    /// @param user Listing owner address
    function acceptListedReserveOffer(
        Listing calldata listing,
        bytes memory listingSignature,
        ReserveOffer calldata offer,
        bytes memory offerSignature,
        bytes32[] calldata proof,
        address user
    ) external;

    /// @dev Accept reservation offer without listing
    /// @param offer Reservation offer info
    /// @param offerSignature Signature of offer info
    /// @param consideration Consideration assets provided for the offer
    /// @param proof merkle proof of the consideration assets
    /// @param user Listing owner address
    /// @param value Eth value sent along with the function call
    /// @param royalty Royalty offered by the user
    function acceptUnlistedReserveOffer(
        ReserveOffer calldata offer,
        bytes memory offerSignature,
        Assets calldata consideration,
        bytes32[] calldata proof,
        address user,
        uint256 value,
        Royalty calldata royalty
    ) external;

    /// @dev Accept resevation collection offer
    /// @param offer collection reserve offer
    /// @param signature Signature of the offer
    /// @param tokens Tokens begin offered
    /// @param tokenIds NFT Ids being offered
    /// @param proofs merkle proof that the tokenIds are valid
    /// @param user Address which accepted the offer
    /// @param value Eth value sent along
    /// @param royalty Seller's royalty info
    function acceptCollectionReserveOffer(
        CollectionReserveOffer calldata offer,
        bytes memory signature,
        address[] memory tokens,
        uint256[] memory tokenIds,
        bytes32[][] memory proofs,
        address user,
        uint256 value,
        Royalty calldata royalty
    ) external;

    /// @dev Pay remaining amount.
    /// @param reservation Reservation details
    /// @param positionTokenId Position token id
    /// @param user Buyer address
    /// @param value Remaining Eth amount of buyer
    /// @param royalty Buyer's royalty info
    function payRemains(
        Reservation calldata reservation,
        uint256 positionTokenId,
        address user,
        uint256 value,
        Royalty calldata royalty
    ) external;

    /// @dev Claim the seller's locked assets from the vault when the time is over.
    /// @param reservation Reservation details
    /// @param positionTokenId Position token id
    /// @param user Buyer address
    function claimDefaulted(
        Reservation calldata reservation,
        uint256 positionTokenId,
        address user
    ) external;

    /// @dev Claim ongoing airdrops using the reserved assets
    /// @param reservation Reservation details
    /// @param positionTokenId Position token id
    /// @param airdropContract Address of the air drop contract
    /// @param data Data to pass in the call, ie. ABI encoded function signature with params
    /// @param user function caller's address
    function claimAirdrop(
        Reservation calldata reservation,
        uint256 positionTokenId,
        address airdropContract,
        bytes calldata data,
        address user
    ) external;

    /// -----------------------------------------------------------------------
    /// Owner actions
    /// -----------------------------------------------------------------------

    /// @dev Set Market contract address.
    /// @param marketAddress Market contract address
    function setMarket(address marketAddress) external;

    /// @dev Set Swap contract address.
    /// @param swapAddress Swap contract address
    function setSwap(address swapAddress) external;

    /// @dev Set Vault contract address.
    /// @param vaultAddress Vault contract address
    function setVault(address vaultAddress) external;

    /// @dev Set Position token contract address.
    /// @param positionTokenAddress Position token contract address
    function setPositionToken(address positionTokenAddress) external;

    /// @dev Set Whitelist contract address.
    /// @param whitelistAddress Whitelist contract address
    function setWhitelist(address whitelistAddress) external;

    /// @dev Set air drop claim contract implementation address
    /// @param airdropClaimImplementation Airdrop claim contract address
    function setAirdropClaimImplementation(address airdropClaimImplementation)
        external;

    /// @dev Set minimum reservation duration
    /// @param minimumReservationDuration Minimum reservation duration
    function setMinimumReservationDuration(uint256 minimumReservationDuration)
        external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// @dev Royalties for collection creators and platform fee for platform manager.
///      to[0] is platform owner address.
/// @param to Creators and platform manager address array
/// @param percentage Royalty percentage based on the listed FT
struct Royalty {
    address[] to;
    uint256[] percentage;
}

/// @dev Common Assets type, packing bundle of NFTs and FTs.
/// @param tokens NFT asset address
/// @param tokenIds NFT token id
/// @param paymentTokens FT asset address
/// @param amounts FT token amount
struct Assets {
    address[] tokens;
    uint256[] tokenIds;
    address[] paymentTokens;
    uint256[] amounts;
}

/// @dev Common SwapAssets type, packing Bundle of NFTs and FTs. Notice tokenIds is a 2d array.
///      Each collection address ie. tokens[i] will have an array tokenIds[i] corrosponding to it.
///      This is used to select particular tokenId in corrospoding collection. If tokenIds[i]
///      is empty, this means the entire collection is considered valid.
/// @param tokens NFT asset address
/// @param roots Merkle roots of the criterias. NOTE: bytes32(0) represents the entire collection
/// @param paymentTokens FT asset address
/// @param amounts FT token amount
struct SwapAssets {
    address[] tokens;
    bytes32[] roots;
    address[] paymentTokens;
    uint256[] amounts;
}

/// @dev Common Reserve type, packing data related to reserve listing and reserve offer.
/// @param deposit Assets considered as initial deposit
/// @param remaining Assets considered as due amount
/// @param duration Duration of reserve now swap later
struct ReserveInfo {
    Assets deposit;
    Assets remaining;
    uint256 duration;
}

/// @dev All the reservation details that are stored in the position token
/// @param reservedAssets Assets that were reserved as a part of the reservation
/// @param reservedAssestsRoyalty Royalty offered by the assets owner
/// @param reserveInfo Deposit, remainig and time duriation details of the reservation
/// @param assetOwner Original owner of the reserved assets
struct Reservation {
    Assets reservedAssets;
    Royalty reservedAssetsRoyalty;
    ReserveInfo reserveInfo;
    address assetOwner;
}

/// @dev Listing type, packing the assets being listed, listing parameters, listing owner
///      and users's nonce.
/// @param listingAssets All the assets listed
/// @param directSwaps List of options for direct swap
/// @param reserves List of options for reserve now swap later
/// @param royalty Listing royalty and platform fee info
/// @param timePeriod Time period of listing
/// @param owner Owner's address
/// @param nonce User's nonce
struct Listing {
    Assets listingAssets;
    SwapAssets[] directSwaps;
    ReserveInfo[] reserves;
    Royalty royalty;
    address tradeIntendedFor;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

/// @dev Listing type of special NF3 banner listing
/// @param token address of collection
/// @param tokenId token id being listed
/// @param editions number of tokenIds being distributed
/// @param gateCollectionsRoot merkle root for eligible collections
/// @param timePeriod timePeriod of listing
/// @param owner owner of listing
struct NF3GatedListing {
    address token;
    uint256 tokenId;
    uint256 editions;
    bytes32 gatedCollectionsRoot;
    uint256 timePeriod;
    address owner;
}

/// @dev Swap Offer type info.
/// @param offeringItems Assets being offered
/// @param royalty Swap offer royalty info
/// @param considerationRoot Assets to which this offer is made
/// @param timePeriod Time period of offer
/// @param owner Offer owner
/// @param nonce Offer nonce
struct SwapOffer {
    Assets offeringItems;
    Royalty royalty;
    bytes32 considerationRoot;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

/// @dev Reserve now swap later type offer info.
/// @param reserveDetails Reservation scheme begin offered
/// @param considerationRoot Assets to which this offer is made
/// @param royalty Reserve offer royalty info
/// @param timePeriod Time period of offer
/// @param owner Offer owner
/// @param nonce Offer nonce
struct ReserveOffer {
    ReserveInfo reserveDetails;
    bytes32 considerationRoot;
    Royalty royalty;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

/// @dev Collection offer type info.
/// @param offeringItems Assets being offered
/// @param considerationItems Assets to which this offer is made
/// @param royalty Collection offer royalty info
/// @param timePeriod Time period of offer
/// @param owner Offer owner
/// @param nonce Offer nonce
struct CollectionSwapOffer {
    Assets offeringItems;
    SwapAssets considerationItems;
    Royalty royalty;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

/// @dev Collection Reserve type offer info.
/// @param reserveDetails Reservation scheme begin offered
/// @param considerationItems Assets to which this offer is made
/// @param royalty Reserve offer royalty info
/// @param timePeriod Time period of offer
/// @param owner Offer owner
/// @param nonce Offer nonce
struct CollectionReserveOffer {
    ReserveInfo reserveDetails;
    SwapAssets considerationItems;
    Royalty royalty;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

enum Status {
    AVAILABLE,
    EXHAUSTED
}

enum AssetType {
    INVALID,
    ETH,
    ERC_20,
    ERC_721,
    ERC_1155,
    KITTIES,
    PUNK
}