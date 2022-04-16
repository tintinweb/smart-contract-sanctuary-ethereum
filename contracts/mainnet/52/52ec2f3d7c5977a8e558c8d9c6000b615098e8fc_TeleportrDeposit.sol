// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TeleportrDeposit
 *
 * Shout out to 0xclem for providing the inspiration for this contract:
 * https://github.com/0xclem/teleportr/blob/main/contracts/BridgeDeposit.sol
 */
contract TeleportrDeposit is Ownable {
    /// The minimum amount that be deposited in a receive.
    uint256 public minDepositAmount;
    /// The maximum amount that be deposited in a receive.
    uint256 public maxDepositAmount;
    /// The maximum balance the contract can hold after a receive.
    uint256 public maxBalance;
    /// The total number of successful deposits received.
    uint256 public totalDeposits;

    /**
     * @notice Emitted any time the minimum deposit amount is set.
     * @param previousAmount The previous minimum deposit amount.
     * @param newAmount The new minimum deposit amount.
     */
    event MinDepositAmountSet(uint256 previousAmount, uint256 newAmount);

    /**
     * @notice Emitted any time the maximum deposit amount is set.
     * @param previousAmount The previous maximum deposit amount.
     * @param newAmount The new maximum deposit amount.
     */
    event MaxDepositAmountSet(uint256 previousAmount, uint256 newAmount);

    /**
     * @notice Emitted any time the contract maximum balance is set.
     * @param previousBalance The previous maximum contract balance.
     * @param newBalance The new maximum contract balance.
     */
    event MaxBalanceSet(uint256 previousBalance, uint256 newBalance);

    /**
     * @notice Emitted any time the balance is withdrawn by the owner.
     * @param owner The current owner and recipient of the funds.
     * @param balance The current contract balance paid to the owner.
     */
    event BalanceWithdrawn(address indexed owner, uint256 balance);

    /**
     * @notice Emitted any time a successful deposit is received.
     * @param depositId A unique sequencer number identifying the deposit.
     * @param emitter The sending address of the payer.
     * @param amount The amount deposited by the payer.
     */
    event EtherReceived(uint256 indexed depositId, address indexed emitter, uint256 indexed amount);

    /**
     * @notice Initializes a new TeleportrDeposit contract.
     * @param _minDepositAmount The initial minimum deposit amount.
     * @param _maxDepositAmount The initial maximum deposit amount.
     * @param _maxBalance The initial maximum contract balance.
     */
    constructor(
        uint256 _minDepositAmount,
        uint256 _maxDepositAmount,
        uint256 _maxBalance
    ) {
        minDepositAmount = _minDepositAmount;
        maxDepositAmount = _maxDepositAmount;
        maxBalance = _maxBalance;
        totalDeposits = 0;
        emit MinDepositAmountSet(0, _minDepositAmount);
        emit MaxDepositAmountSet(0, _maxDepositAmount);
        emit MaxBalanceSet(0, _maxBalance);
    }

    /**
     * @notice Accepts deposits that will be disbursed to the sender's address on L2.
     * The method reverts if the amount is less than the current
     * minDepositAmount, the amount is greater than the current
     * maxDepositAmount, or the amount causes the contract to exceed its maximum
     * allowed balance.
     */
    receive() external payable {
        require(msg.value >= minDepositAmount, "Deposit amount is too small");
        require(msg.value <= maxDepositAmount, "Deposit amount is too big");
        require(address(this).balance <= maxBalance, "Contract max balance exceeded");

        emit EtherReceived(totalDeposits, msg.sender, msg.value);
        unchecked {
            totalDeposits += 1;
        }
    }

    /**
     * @notice Sends the contract's current balance to the owner.
     */
    function withdrawBalance() external onlyOwner {
        address _owner = owner();
        uint256 _balance = address(this).balance;
        emit BalanceWithdrawn(_owner, _balance);
        payable(_owner).transfer(_balance);
    }

    /**
     * @notice Sets the minimum amount that can be deposited in a receive.
     * @param _minDepositAmount The new minimum deposit amount.
     */
    function setMinAmount(uint256 _minDepositAmount) external onlyOwner {
        emit MinDepositAmountSet(minDepositAmount, _minDepositAmount);
        minDepositAmount = _minDepositAmount;
    }

    /**
     * @notice Sets the maximum amount that can be deposited in a receive.
     * @param _maxDepositAmount The new maximum deposit amount.
     */
    function setMaxAmount(uint256 _maxDepositAmount) external onlyOwner {
        emit MaxDepositAmountSet(maxDepositAmount, _maxDepositAmount);
        maxDepositAmount = _maxDepositAmount;
    }

    /**
     * @notice Sets the maximum balance the contract can hold after a receive.
     * @param _maxBalance The new maximum contract balance.
     */
    function setMaxBalance(uint256 _maxBalance) external onlyOwner {
        emit MaxBalanceSet(maxBalance, _maxBalance);
        maxBalance = _maxBalance;
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