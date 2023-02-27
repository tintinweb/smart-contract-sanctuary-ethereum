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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IBulkMinting.sol";
import "./interfaces/IConverterLogic.sol";
import "./interfaces/IGenIIBrain.sol";

contract BulkMinting is IBulkMinting, Ownable, Pausable, ReentrancyGuard {
    IConverterLogic public energyConverter;
    IGenIIBrain public genIIBrain;

    address public clubVault;
    address public burningWallet;

    uint256 public maxMintQuantity;
    uint256 public energyPerBrain;

    constructor(
        address _energyConverter,
        address _genIIBrain,
        address _clubVault,
        address _burningWallet,
        uint256 _maxMintQuantity,
        uint256 _energyPerBrain
    ) {
        if (_energyConverter == address(0)) revert InvalidConverter();
        if (_genIIBrain == address(0)) revert InvalidBrain();
        if (_clubVault == address(0)) revert InvalidVault();
        if (_burningWallet == address(0)) revert InvalidBurningWallet();
        if (_maxMintQuantity == 0) revert InvalidMintLimit();
        if (_energyPerBrain == 0) revert InvalidBrainPrice();

        energyConverter = IConverterLogic(_energyConverter);
        genIIBrain = IGenIIBrain(_genIIBrain);
        clubVault = _clubVault;
        burningWallet = _burningWallet;
        maxMintQuantity = _maxMintQuantity;
        energyPerBrain = _energyPerBrain;

        _pause();
    }

    /**
     * @notice Use asto energy to mint gen II brains to the burning wallet
     * @dev Only callable when not paused and by owner
     * @param _hashes A list of IPFS Multihash digests. Each Gen II Brain should have an unique token hash
     */
    function mint(
        bytes32[] calldata _hashes
    ) external whenNotPaused nonReentrant onlyOwner {
        uint256 quantity = _hashes.length;

        if (quantity > maxMintQuantity)
            revert MaxQuantityExceeded(quantity, maxMintQuantity);

        uint256 periodId = energyConverter.getCurrentPeriodId();
        uint256 energyToUse = quantity * energyPerBrain;
        energyConverter.useEnergy(clubVault, periodId, energyToUse);

        genIIBrain.mint(burningWallet, _hashes);
    }

    /**
     * @notice Setter for energyConverter
     */
    function setEnergyConverter(address _addr) external onlyOwner whenPaused {
        if (_addr == address(0)) revert InvalidConverter();
        energyConverter = IConverterLogic(_addr);
        emit ConverterUpdated(msg.sender, _addr);
    }

    /**
     * @notice Setter for genIIBrain
     */
    function setGenIIBrain(address _addr) external onlyOwner whenPaused {
        if (_addr == address(0)) revert InvalidBrain();
        genIIBrain = IGenIIBrain(_addr);
        emit BrainUpdated(msg.sender, _addr);
    }

    /**
     * @notice Setter for clubVault
     */
    function setClubVault(address _wallet) external onlyOwner whenPaused {
        if (_wallet == address(0)) revert InvalidVault();
        clubVault = _wallet;
        emit VaultUpdated(msg.sender, _wallet);
    }

    /**
     * @notice Setter for burningWallet
     */
    function setBurningWallet(address _wallet) external onlyOwner whenPaused {
        if (_wallet == address(0)) revert InvalidBurningWallet();
        burningWallet = _wallet;
        emit BurningWalletUpdated(msg.sender, _wallet);
    }

    /**
     * @notice Setter for maxMintQuantity
     */
    function setMaxMintQuantity(uint256 _amount) external onlyOwner whenPaused {
        if (_amount == 0) revert InvalidMintLimit();
        maxMintQuantity = _amount;
        emit MaxMintQuantityUpdated(msg.sender, _amount);
    }

    /**
     * @notice Setter for energyPerBrain
     */
    function setEnergyPerBrain(uint256 _amount) external onlyOwner whenPaused {
        if (_amount == 0) revert InvalidBrainPrice();
        energyPerBrain = _amount;
        emit EnergyPriceUpdated(msg.sender, _amount);
    }

    /**
     * @notice Pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @dev Interface for BulkMinting
 */
interface IBulkMinting {
    event ConverterUpdated(address indexed operator, address converter);
    event BrainUpdated(address indexed operator, address brain);
    event VaultUpdated(address indexed operator, address vault);
    event BurningWalletUpdated(address indexed operator, address burningWallet);
    event MaxMintQuantityUpdated(address indexed operator, uint256 quantity);
    event EnergyPriceUpdated(address indexed operator, uint256 price);

    error InvalidConverter();
    error InvalidBrain();
    error InvalidVault();
    error InvalidBurningWallet();
    error InvalidMintLimit();
    error InvalidBrainPrice();

    error MaxQuantityExceeded(uint256 quantity, uint256 maxQuantity);
    error InsufficientEnergy(uint256 amount, uint256 remaining);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @dev Interface for Converter
 */
interface IConverterLogic {
    function getEnergy(
        address addr,
        uint256 periodId
    ) external view returns (uint256);

    function getCurrentPeriodId() external view returns (uint256);

    function useEnergy(address addr, uint256 periodId, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @dev Interface for ASMBrainGenII contract
 */
interface IGenIIBrain {
    /**
     * @notice Mint Gen II Brains to `recipient` with the IPFS hashes
     * @dev This function can only be called from contracts or wallets with MINTER_ROLE
     * @param recipient The wallet address used for minting
     * @param hashes A list of IPFS Multihash digests. Each Gen II Brain should have an unique token hash
     */
    function mint(address recipient, bytes32[] calldata hashes) external;
}