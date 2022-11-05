// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error NotAllowed();
error InvalidAddress();
error WhiteHatOnly();

error NotWithinLockPeriod();
error NotAfterLockExpires();

error AlreadyLocked();
error ContractLocked();

contract HTLCLocked is Ownable, ReentrancyGuard {
    uint256 public constant LOCK_TIME = 43200 seconds; // 12 hours

    // Indicates the start of the lock period (the most recent fund time).
    uint256 public startTime;

    // The current bounty amount (independent of contract balance).
    uint256 public amount;

    // The white hat determines which address the bounty will be paid out to.
    address payable public whiteHat = payable(0x1a38e21bE7768201D3feD2FA54f3BFBdC6056096);
    // The NFT contract which will have its ownership transferred
    address public constant NFT_CONTRACT = 0x40f5434cbED8ac30a0A477a7aFc569041B3d2012;
    // The new owner of the NFT contract
    address public newOwner = 0xB48495B000e82bF4bCbDEe17997a70146964d601;

    // If the HTLC contract has been permanently locked.
    bool public IS_LOCKED;

    // Prevent HTLC ownership transfers.
    function renounceOwnership() public override onlyOwner {
        revert NotAllowed();
    }
    function transferOwnership(address) public override onlyOwner nonReentrant {
        revert NotAllowed();
    }

    // 1) Team calls to fund bounty, this sets the start of the time lock period.
    function fund() external payable onlyOwner nonReentrant {
        if (IS_LOCKED) {
            revert ContractLocked();
        }

        startTime = block.timestamp;
        amount += msg.value;
    }

    // 2) White hat transfers ownership of NFT contract to HTLC contract
    // 3) White hat calls withdraw() to withdraw bounty
    function withdraw(address recipient) external nonReentrant {
        if (IS_LOCKED) {
            revert ContractLocked();
        }

        // Make sure only the white hat can call within the lock period
        if (msg.sender != whiteHat) {
            revert WhiteHatOnly();
        }
        if (
            block.timestamp < startTime ||
            block.timestamp > (startTime + LOCK_TIME)
        ) {
            revert NotWithinLockPeriod();
        }

        // Transfer ownership to new owner before bounty
        Ownable(NFT_CONTRACT).transferOwnership(newOwner);
        // Pay out bounty to the white hat's designated recipient.
        payable(recipient).transfer(amount);

        // Reset
        _resetContract();
    }

    // Reset / refund mechanisms if time lock expires
    function refund() external onlyOwner nonReentrant {
        if (block.timestamp < (startTime + LOCK_TIME)) {
            revert NotAfterLockExpires();
        }

        // Reset
        _resetContract();
    }
    function resetContractOwnerAndRefund() external onlyOwner nonReentrant {
        if (IS_LOCKED) {
            revert ContractLocked();
        }
        if (block.timestamp < (startTime + LOCK_TIME)) {
            revert NotAfterLockExpires();
        }

        // Transfer ownership
        Ownable(NFT_CONTRACT).transferOwnership(newOwner);

        // Reset
        _resetContract();
    }

    // Setters
    function setWhiteHat(address _whiteHat) external onlyOwner nonReentrant {
        // Make sure the white hat is a valid and unique address
        if (
            _whiteHat == address(0) ||
            _whiteHat == address(this) ||
            _whiteHat == whiteHat ||
            _whiteHat == newOwner ||
            _whiteHat == NFT_CONTRACT
        ) {
            revert InvalidAddress();
        }

        whiteHat = payable(_whiteHat);
    }
    function setNewOwner(address _newOwner) external onlyOwner nonReentrant {
        // Make sure the new owner is a valid and unique address
        if (
            _newOwner == address(0) ||
            _newOwner == address(this) ||
            _newOwner == whiteHat ||
            _newOwner == newOwner ||
            _newOwner == NFT_CONTRACT
        ) {
            revert InvalidAddress();
        }

        newOwner = _newOwner;
    }

    // Reset and drain contract.
    // Can only be called if time lock expires or as part of normal bounty mechanism.
    function _resetContract() internal {
        if (address(this).balance > 0) {
            payable(owner()).transfer(address(this).balance);
        }

        amount = 0;
        startTime = 0;
    }

    // Permanently lock the HTLC contract.
    function lockContract() external onlyOwner nonReentrant {
        if (IS_LOCKED) {
            revert AlreadyLocked();
        }

        IS_LOCKED = true;
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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