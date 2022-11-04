// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

// Errors
error Payroll__InvalidPaymentData(
    address recipient,
    uint256 amount,
    uint256 interval
);
error Payroll__RecipientAlreadyExists(address recipient);
error Payroll__WithdrawalFailed();
error Payroll__PaymentWithdrawalFailed();

/// @title A smart contract payroll
/// @dev It uses Chainlink Automation to send ETH to recipients
contract Payroll is Ownable, AutomationCompatibleInterface {
    struct PaymentSchedule {
        uint256 amount;
        uint256 interval; // seconds
        uint256 lastTimestamp; // seconds
    }

    address[] private s_recipients;
    mapping(address => PaymentSchedule) private s_paymentSchedules;
    mapping(address => uint256) private s_balances;

    // Events
    event RecipientAdded(
        address indexed recipient,
        uint256 indexed amount,
        uint256 indexed interval
    );
    event RecipientRemoved(address indexed recipient);
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed amount
    );
    event PaymentDone(address indexed recipient, uint256 indexed amount);
    event InsufficientBalance(
        address indexed recipient,
        uint256 indexed requiredAmount,
        uint256 indexed contractBalance
    );

    /// Add funds to the contract.
    receive() external payable {}

    /// Add a recipient.
    /// @param recipient the address of the recipient
    /// @param amount the wei amount the recipient will receive
    /// @param interval how often in seconds the recipient will receive the amount
    /// @dev stores the recipient in `s_recipients` and the PaymentSchedule in `s_paymentSchedules`
    function addRecipient(
        address recipient,
        uint256 amount,
        uint256 interval
    ) public onlyOwner {
        if (amount == 0 || interval == 0) {
            revert Payroll__InvalidPaymentData(recipient, amount, interval);
        }
        if (s_paymentSchedules[recipient].amount > 0) {
            revert Payroll__RecipientAlreadyExists(recipient);
        }
        PaymentSchedule memory paymentSchedule = PaymentSchedule(
            amount,
            interval,
            block.timestamp
        );
        s_recipients.push(recipient);
        s_paymentSchedules[recipient] = paymentSchedule;
        emit RecipientAdded(recipient, amount, interval);
    }

    /// Remove a recipient.
    /// @param recipient the address of the recipient to remove
    /// @dev removes the recipient from `s_recipients` by shifting the array
    /// and from `s_recipientsPayments` by deleting the recipient
    function removeRecipient(address recipient) public onlyOwner {
        for (uint256 i = 0; i < s_recipients.length; ++i) {
            // find the recipient's index
            if (s_recipients[i] == recipient) {
                if (i < s_recipients.length - 1) {
                    // shift the array's elements
                    for (uint256 j = i; j < s_recipients.length - 1; ++j) {
                        s_recipients[j] = s_recipients[j + 1];
                    }
                }
                s_recipients.pop();
                delete s_paymentSchedules[recipient];
                emit RecipientRemoved(recipient);
                break;
            }
        }
    }

    /// Send ETH.
    /// @param recipient the recipient
    /// @param amount the wei amount to send
    function sendEth(address payable recipient, uint256 amount)
        private
        returns (bool succes, bytes memory)
    {
        if (recipient == owner() || s_paymentSchedules[recipient].amount > 0) {
            return recipient.call{value: amount}("");
        } else {
            return (false, "0x");
        }
    }

    /// Withdraw the contract funds.
    function withdraw() public onlyOwner {
        (bool success, ) = sendEth(payable(msg.sender), address(this).balance);
        if (!success) {
            revert Payroll__WithdrawalFailed();
        }
    }

    /// Withdraw a recipient's payments.
    function withdrawPayments() public {
        if (s_balances[msg.sender] > 0) {
            uint256 recipientBalance = s_balances[msg.sender];
            if (s_balances[msg.sender] > address(this).balance) {
                emit InsufficientBalance(
                    msg.sender,
                    recipientBalance,
                    address(this).balance
                );
            } else {
                s_balances[msg.sender] = 0;
                (bool success, ) = sendEth(
                    payable(msg.sender),
                    recipientBalance
                );
                if (success) {
                    emit Transfer(address(this), msg.sender, recipientBalance);
                } else {
                    s_balances[msg.sender] = recipientBalance;
                    revert Payroll__PaymentWithdrawalFailed();
                }
            }
        }
    }

    /// Check if a payment is due.
    /// @param `paymentSchedule` the payment schedule to check
    /// @return true if a payment is due
    function paymentDue(PaymentSchedule memory paymentSchedule)
        private
        view
        returns (bool)
    {
        return (paymentSchedule.amount > 0 &&
            paymentSchedule.interval > 0 &&
            block.timestamp - paymentSchedule.lastTimestamp >
            paymentSchedule.interval);
    }

    /// @dev This function is called off-chain by Chainlink Automation nodes.
    /// `upkeepNeeded` must be true when a payment is due for at least one recipient
    /// @return upkeepNeeded boolean to indicate if performUpkeep should be called
    /// @return performData the recipients for which a payment is due
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        address[] memory recipientsToPay = new address[](s_recipients.length);
        upkeepNeeded = false;
        uint256 recipientToPayIndex = 0;

        // check the payment interval of each recipient
        PaymentSchedule memory paymentSchedule;
        for (uint256 i = 0; i < s_recipients.length; ++i) {
            paymentSchedule = s_paymentSchedules[s_recipients[i]];
            if (paymentDue(paymentSchedule)) {
                recipientsToPay[recipientToPayIndex] = s_recipients[i];
                ++recipientToPayIndex;
                upkeepNeeded = true;
            }
        }

        if (recipientToPayIndex > 0) {
            // copy the recipients to pay
            address[] memory performDataToEncode = new address[](
                recipientToPayIndex
            );
            for (uint256 i = 0; i < performDataToEncode.length; ++i) {
                performDataToEncode[i] = recipientsToPay[i];
            }
            performData = abi.encode(performDataToEncode);
        } else {
            address[] memory performDataToEncode;
            performData = abi.encode(performDataToEncode);
        }

        return (upkeepNeeded, performData);
    }

    /// @dev This function is called on-chain when `upkeepNeeded` is true.
    /// @param performData the recipients for which a payment is due
    function performUpkeep(bytes calldata performData) external override {
        address[] memory recipientsToPay = abi.decode(performData, (address[]));
        PaymentSchedule memory paymentSchedule;
        for (uint256 i = 0; i < recipientsToPay.length; ++i) {
            paymentSchedule = s_paymentSchedules[recipientsToPay[i]];
            if (paymentDue(paymentSchedule)) {
                // update the recipient's timestamp and balance
                paymentSchedule.lastTimestamp = block.timestamp;
                s_paymentSchedules[recipientsToPay[i]] = paymentSchedule;
                s_balances[recipientsToPay[i]] += paymentSchedule.amount;
                emit PaymentDone(recipientsToPay[i], paymentSchedule.amount);
            }
        }
    }

    /// Return a recipient's payment schedule.
    /// @param recipient the address of the recipient
    /// @dev retrieves the recipient's PaymentSchedule from `s_paymentSchedules`
    /// @return the recipient's PaymentSchedule
    function getPaymentSchedule(address recipient)
        public
        view
        returns (PaymentSchedule memory)
    {
        return s_paymentSchedules[recipient];
    }

    /// Return the recipients.
    /// @return the recipients
    function getRecipients() public view returns (address[] memory) {
        return s_recipients;
    }

    /// Return a recipient's payment balance.
    /// @return the payment balance of a recipient
    function balanceOf(address recipient) public view returns (uint256) {
        return s_balances[recipient];
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
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

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
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}