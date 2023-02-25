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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Plundr
/// @author Joss Duff, Hudson Pavia, Kenneth Cho
/// @notice to be used with Plundr back-end
contract Plundr is Ownable { 

  /// @notice emit when an address makes a contribution
  /// @param user address of the user making the contribution
  /// @param amountContributed amount that the user is depositing into the contract
  event UserContribution(address user, uint amountContributed);

  /// @notice emit when a round is over an winner is selected
  /// @param winner address of the creator of the post with the most votes
  /// @param amount amount the winner was paid out
  /// @param isBust true if there were no contributions during the round
  /// @param feeTaken amount the protocol receives
  event Payout(address winner, uint amount, bool isBust, uint feeTaken);

  /// @notice tracks amount of Ether contributed by each address
  mapping(address => uint) public contributions;

  /// @notice address array of all contributors
  address[] public contributors;

  /// @notice tracks total contributions over all time
  /// @dev not used in contract, used in plundr backend
  uint public totalContributions;

  /// @notice minimum amount to contribute.
  /// @dev prevents one actor contributing with a small amount of eth over many wallets
  uint public minContribution;

  /// @notice percent fee taken by protocol.
  uint public fee;

  /// @notice amount paid out to winner if there were no contributions during the round
  uint public bust;

  /// @notice keeps track of contract balance
  /// @dev anyone can forcibly send ether to any contract.  We need to keep track of only ether
  /// sent in via "contribute" function
  uint public contractBal;

  /// @param newFee default fee amount
  /// @param newBust default bust amount
  constructor(uint newFee, uint newBust, uint newMinContribution){
    require(newFee > 0 && newFee < 100, "Fee must be greater than 0 and less than 100");
    fee = newFee;

    require(newBust > 0, "Bust amount must be greater than 0");
    bust = newBust;

    require(newMinContribution > 0, "minContribution must be greater than 0");
    minContribution = newMinContribution;
  }

  /// @notice A user wishes to contribute currency to the protocol to be able to vote and have a chance of being selected
  function contribute() payable external {
    require(msg.value >= minContribution, "Contribution must be greater than minContribution");

    // If caller hasn't contributed before, add them to contributors array
    if (contributions[msg.sender] == 0){
      contributors.push(msg.sender);
    }

    // Increment mapping of addresses to contributions by amount deposited
    contributions[msg.sender] += msg.value;

    // Increment totalContributions by amount deposited
    totalContributions += msg.value;
    // Increment contract balance
    contractBal += msg.value;

    emit UserContribution(msg.sender, msg.value);
  }

  /// @notice return the entire contributors array
  /// @dev used in plundr backend
  function getContributors() external view returns (address[] memory) {
    return contributors;
  }

  /// @notice for protocol to set minimum contribution amount
  /// @param newMinContribution new minimum amount of currency deposited to count as a contribution
  function setMinContribution(uint newMinContribution) external onlyOwner {
    require(newMinContribution > 0, "minContribution must be greater than 0");
    minContribution = newMinContribution;
  }

  /// @notice for protocol to set bust amount
  /// @param newBust new bust amount to be paid out to winner of a round in which there was no contributions
  function setBust(uint newBust) external onlyOwner{
    require(newBust > 0, "Bust amount must be greater than 0");
    bust = newBust;
  }

  /// @notice for protocol to set its fee
  /// @param newFee new percent of winnings to send to protocol
  function setFee(uint newFee) external onlyOwner {
    require(newFee > 0 && newFee < 100, "Fee must be greater than 0 and less than 100");
    fee = newFee;
  }

  /// @notice protocol calls to pay out winner of a round
  /// @param winner the address whos post has the most votes.  Determined in plundr backend.
  function payoutWinner(address winner) external payable onlyOwner returns(uint){
    // Must send enough currency to cover a bust round
    require(msg.value == bust, "ether sent =/= bust amount");

    //if round was a bust
    if (contractBal == 0){
      // send bust amount to the winner
      bool success = payable(winner).send(msg.value);
      require(success, "payment to winner failed");

      emit Payout(winner, bust, true, 0);

      return bust;
    }
    // round not a bust
    else{
      // calculate amount to send to protocol
      uint feeAmt = (contractBal * fee)/100;
      // send fee amount to protocol.  Also send msg.value since it is only used to cover the case of bust
      bool success = payable(owner()).send(feeAmt + msg.value);
      require(success, "payment to owner failed");

      // decrease contractBal by feeAmt
      contractBal -= feeAmt;

      // send the remaining balance in the contract to the winner
      // this amount is the total contributions made since last round's winner was paid out
      uint payout = contractBal;
      success = payable(winner).send(payout);
      require(success, "payment to winner failed");

      // reset contract balance since it was all just sent to winner
      contractBal = 0;

      emit Payout(winner, payout, false, feeAmt);

      return payout;
    }
  }

}