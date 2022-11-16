pragma solidity 0.8.13;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Verse payments capturer
 * @author Verse
 * @notice This contract allows to capture ETH payments from private wallets that will be picked up by Verse platform.
 */
interface IVersePayments {
    /**
     * @dev Payment event is emitted when user pays to the contract, where `metadata` is used to identify the payment.
     */
    event Payment(string metadata, uint256 amount, address indexed buyer, bytes32 hash);

    /**
     * @dev Refund event is emited during refund, where `metadata` is used to identify the payment.
     */
    event Refund(string metadata);

    /**
     * @notice Pay method collects user payment for the item, where `metadata` is used to identify the payment and emits {Payment} event.
     */
    function pay(string calldata metadata) external payable;

    /**
     * @dev Refund method transfers user ETH and emits {Refund} event.
     */
    function refund(
        string calldata metadata,
        uint256 amount,
        address buyer
    ) external;

    /**
     * @dev Withdraw method transfers all collected ETH to the treasury wallet.
     */
    function withdraw() external;
}

/**
 * @title Verse payments capturer
 * @author Verse
 * @notice This contract allows to capture ETH payments from private wallets that will be picked up by Verse platform.
 */
contract VersePayments is Ownable, IVersePayments {
    address public treasury;
    address public refundsManager;
    uint256 public paymentNumber = 0;

    constructor(address treasury_, address refundsManager_) {
        treasury = treasury_;
        refundsManager = refundsManager_;
    }

    /**
     * @notice Pay method collects user payment for the item, where `metadata` is used to identify the payment and emits {Payment} event.
     */
    function pay(string calldata metadata) public payable {
        paymentNumber = paymentNumber + 1;
        bytes32 hash = keccak256(
            abi.encodePacked(
                paymentNumber,
                block.number,
                blockhash(block.number - 1),
                address(this).balance,
                keccak256(abi.encodePacked(block.number, blockhash(block.number - 2), block.timestamp, (block.timestamp % 200) + 1))
            )
        );
        emit Payment(metadata, msg.value, msg.sender, hash);
    }

    /**
     * @dev Refund method transfers user ETH and emits {Refund} event.
     */
    function refund(
        string calldata metadata,
        uint256 amount,
        address buyer
    ) public onlyRefundsManager {
        (bool sent, ) = buyer.call{value: amount}("");
        require(sent, "Failed to send Ether");
        emit Refund(metadata);
    }

    /**
     * @dev Withdraw method transfers all collected ETH to the treasury wallet.
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool sent, ) = treasury.call{value: balance}("");
        require(sent, "Failed to send Ether");
    }

    /**
     * @dev modifier to only
     */
    modifier onlyRefundsManager() {
        require(msg.sender == refundsManager);
        _;
    }

    /**
     * @dev Sets new refunds manager for the contract.
     *
     */
    function setRefundsManager(address refundsManager_) public onlyOwner {
        refundsManager = refundsManager_;
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