// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract EtherDisperser is Ownable {
  /// @notice The total amount of ether that was rewarded since the start of the MAJR contests
  uint256 public totalEtherRewarded;

  /// @notice The amount of ether that's left to be claimed by the current contest winners
  uint256 public leftToBeClaimed;

  /// @notice Mapping from address to amount of ether they can claim
  mapping(address => uint256) public balances;

  /// @notice An event emitted when ether gets deposited to the contract
  event Deposit(address indexed sender, uint256 amount);

  /// @notice An event emitted when the balance for a particular address is set
  event SetBalance(address indexed target, uint256 balance);

  /// @notice An event emitted when a particular address claims their ether rewards
  event Claim(address indexed target, uint256 amount);

  constructor() {}

  receive() external payable {
    emit Deposit(msg.sender, msg.value);
  }

  /**
   * @notice Sets the claimable ETH balances of the contest winners and makes sure that the contract has enough ether to support all the claims by the contest winners
   * @param _targets address[] calldata
   * @param _amounts uint256[] calldata
   * @dev Only owner can call it
   */
  function addBalances(address[] calldata _targets, uint256[] calldata _amounts) external payable onlyOwner {
    require(_targets.length == _amounts.length, "EtherDisperser: Targets and amounts must be the same length.");
    require(_targets.length > 0, "EtherDisperser: Targets must be non-empty.");
    require(msg.value == _getTotalEtherAmount(_amounts), "EtherDisperser: Not enough ether sent for the contest winners to be claimed.");

    totalEtherRewarded += msg.value;
    leftToBeClaimed += msg.value;

    emit Deposit(msg.sender, msg.value);

    for (uint256 i = 0; i < _targets.length; i++) {
      balances[_targets[i]] += _amounts[i];
      emit SetBalance(_targets[i], balances[_targets[i]]);
    }
  }

  /**
   * @notice Sets the claimable balances of the addresses added by mistake to 0 and returns their ether claimable balance back to the admin
   * @param _targets address[] calldata
   * @dev Only owner can call it
   */
  function removeBalances(address[] calldata _targets) external onlyOwner {
    require(_targets.length > 0, "EtherDisperser: Targets must be non-empty.");

    for (uint256 i = 0; i < _targets.length; i++) {
      uint256 _balance = balances[_targets[i]];

      totalEtherRewarded -= _balance;
      leftToBeClaimed -= _balance;

      (bool sent, ) = owner().call{value: _balance}("");
      require(sent, "EtherDisperser: Couldn't send ether to you.");

      balances[_targets[i]] = 0;
      emit SetBalance(_targets[i], 0);
    }
  }

  /**
   * @notice Allows users to claim their ETH rewards
   * @dev Only users that won rewards can claim them
   */
  function claim() external {
    uint256 userBalance = balances[msg.sender];
    require(userBalance > 0, "EtherDisperser: You have no ether to claim.");

    balances[msg.sender] = 0;
    leftToBeClaimed -= userBalance;

    (bool sent, ) = msg.sender.call{value: userBalance}("");
    require(sent, "EtherDisperser: Could not send ether to you.");

    emit Claim(msg.sender, userBalance);
  }
  
  /**
   * @notice Added to support recovering the excess ether trapped in the contract (i.e. ether not awarded to any contest winner)
   * @dev Only owner can call it
   */
  function recoverEther() external onlyOwner {
    uint256 _amount = address(this).balance - leftToBeClaimed;
    require(_amount > 0, "EtherDisperser: No ether to recover.");

    (bool sent, ) = owner().call{value: _amount}("");
    require(sent, "EtherDisperser: Couldn't send ether to you.");
  }

  /**
   * @notice Gets the total amount from the array of different amounts
   * @param _amounts uint256[] calldata
   * @return uint256
   * @dev Internal utility function used in updateBalances and appendBalances methods
   */
  function _getTotalEtherAmount(uint256[] calldata _amounts) internal pure returns (uint256) {
    uint256 total;

    for (uint256 i = 0; i < _amounts.length; i++) {
      total += _amounts[i];
    }

    return total;
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