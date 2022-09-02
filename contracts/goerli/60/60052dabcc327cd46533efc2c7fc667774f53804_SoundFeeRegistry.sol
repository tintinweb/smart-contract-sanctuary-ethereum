// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.16;

import { Ownable } from "openzeppelin/access/Ownable.sol";
import { ISoundFeeRegistry } from "@core/interfaces/ISoundFeeRegistry.sol";

/**
 * @title SoundFeeRegistry
 * @author Sound.xyz
 */
contract SoundFeeRegistry is ISoundFeeRegistry, Ownable {
    // =============================================================
    //                           CONSTANTS
    // =============================================================

    /**
     * @dev This is the denominator, in basis points (BPS), for platform fees.
     */
    uint16 private constant _MAX_BPS = 10_000;

    // =============================================================
    //                            STORAGE
    // =============================================================

    /**
     * @dev The sound protocol's address that receives platform fees.
     */
    address public override soundFeeAddress;

    /**
     * @dev The numerator of the platform fee.
     */
    uint16 public override platformFeeBPS;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(address soundFeeAddress_, uint16 platformFeeBPS_)
        onlyValidSoundFeeAddress(soundFeeAddress_)
        onlyValidPlatformFeeBPS(platformFeeBPS_)
    {
        soundFeeAddress = soundFeeAddress_;
        platformFeeBPS = platformFeeBPS_;
    }

    // =============================================================
    //               PUBLIC / EXTERNAL WRITE FUNCTIONS
    // =============================================================

    /**
     * @inheritdoc ISoundFeeRegistry
     */
    function setSoundFeeAddress(address soundFeeAddress_)
        external
        onlyOwner
        onlyValidSoundFeeAddress(soundFeeAddress_)
    {
        soundFeeAddress = soundFeeAddress_;
        emit SoundFeeAddressSet(soundFeeAddress_);
    }

    /**
     * @inheritdoc ISoundFeeRegistry
     */
    function setPlatformFeeBPS(uint16 platformFeeBPS_) external onlyOwner onlyValidPlatformFeeBPS(platformFeeBPS_) {
        platformFeeBPS = platformFeeBPS_;
        emit PlatformFeeSet(platformFeeBPS_);
    }

    /**
     * @inheritdoc ISoundFeeRegistry
     */
    function platformFee(uint128 requiredEtherValue) external view returns (uint128 fee) {
        // Won't overflow, as `requiredEtherValue` is 128 bits, and `platformFeeBPS` is 16 bits.
        unchecked {
            fee = (requiredEtherValue * platformFeeBPS) / _MAX_BPS;
        }
    }

    // =============================================================
    //                  INTERNAL / PRIVATE HELPERS
    // =============================================================

    /**
     * @dev Restricts the sound fee address to be address(0).
     * @param soundFeeAddress_ The sound fee address.
     */
    modifier onlyValidSoundFeeAddress(address soundFeeAddress_) {
        if (soundFeeAddress_ == address(0)) revert InvalidSoundFeeAddress();
        _;
    }

    /**
     * @dev Restricts the platform fee numerator to not excced the `_MAX_BPS`.
     * @param platformFeeBPS_ Platform fee amount in bps (basis points).
     */
    modifier onlyValidPlatformFeeBPS(uint16 platformFeeBPS_) {
        if (platformFeeBPS_ > _MAX_BPS) revert InvalidPlatformFeeBPS();
        _;
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.16;

/**
 * @title ISoundFeeRegistry
 * @author Sound.xyz
 */
interface ISoundFeeRegistry {
    // =============================================================
    //                            EVENTS
    // =============================================================

    /**
     * @dev Emitted when the `soundFeeAddress` is changed.
     */
    event SoundFeeAddressSet(address soundFeeAddress);

    /**
     * @dev Emitted when the `platformFeeBPS` is changed.
     */
    event PlatformFeeSet(uint16 platformFeeBPS);

    // =============================================================
    //                             ERRORS
    // =============================================================

    /**
     * @dev The sound fee address must not be address(0).
     */
    error InvalidSoundFeeAddress();

    /**
     * @dev The platform fee numerator must not exceed `_MAX_BPS`.
     */
    error InvalidPlatformFeeBPS();

    // =============================================================
    //               PUBLIC / EXTERNAL WRITE FUNCTIONS
    // =============================================================

    /**
     * @dev Sets the `soundFeeAddress`.
     *
     * Calling conditions:
     * - The caller must be the owner of the contract.
     *
     * @param soundFeeAddress_ The sound fee address.
     */
    function setSoundFeeAddress(address soundFeeAddress_) external;

    /**
     * @dev Sets the `platformFeePBS`.
     *
     * Calling conditions:
     * - The caller must be the owner of the contract.
     *
     * @param platformFeeBPS_ Platform fee amount in bps (basis points).
     */
    function setPlatformFeeBPS(uint16 platformFeeBPS_) external;

    // =============================================================
    //               PUBLIC / EXTERNAL VIEW FUNCTIONS
    // =============================================================

    /**
     * @dev The sound protocol's address that receives platform fees.
     * @return The configured value.
     */
    function soundFeeAddress() external view returns (address);

    /**
     * @dev The numerator of the platform fee.
     * @return The configured value.
     */
    function platformFeeBPS() external view returns (uint16);

    /**
     * @dev The platform fee for `requiredEtherValue`.
     * @param requiredEtherValue The required Ether value for payment.
     * @return fee The computed value.
     */
    function platformFee(uint128 requiredEtherValue) external view returns (uint128 fee);
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