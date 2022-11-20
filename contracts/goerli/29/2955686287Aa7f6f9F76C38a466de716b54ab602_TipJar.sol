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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title TipJar
/// @author conceptcodes.eth
/// @notice This contract allows users to send tips to the the owner
/// @dev This contract is used to collect crypto tips
/// @dev This contract allows the owner to withdraw the tips
contract TipJar is Ownable {
  // mapping to store tips and tipper
  mapping(address => uint256) public tips;

  // event to log tips collected
  event TipReceived(address indexed from, uint256 amount);

  // event to log tips withdrawn
  event TipsWithdrawn(address indexed to, uint256 amount);

  /// @notice constructor to initialize the total tips collected to 0
  constructor() payable { }

  /// @notice modifer to check if the tip amount is greater than 0
  /// @param _amount the tip amount to check
  modifier checkTipAmount(uint256 _amount) {
    require(_amount > 0, "TipJar: Tip amount must be greater than 0");
    _;
  }

  /// @notice fallback payable function to receive tips
  /// @dev this function is called when a user sends ether to this contract
  /// @dev we usee the checkTipAmount modifier to check if the tip amount is greater than 0
  receive() 
  external 
  payable 
  checkTipAmount(msg.value) {
    // update mapping of tips
    tips[msg.sender] += msg.value;

    // emit event to log tips collected
    emit TipReceived(msg.sender, msg.value);
  }

  /// @notice funtion to send tips to this contract
  function sendTip() 
  public 
  payable 
  checkTipAmount(msg.value) {
    (bool success, ) = payable(address(this)).call{value : msg.value}("");
    require(success == true, "TipJar: Transfer Failed"); 
  }

  /// @notice function to withdraw tips collected
  /// @dev uses the onlyOwner modifier from the Ownable contract
  function withdrawTips() 
  public 
  onlyOwner {
    // calculate the amount to withdraw
    uint256 amount = address(this).balance;

    require(address(this).balance > 0, "TipJar: Insufficient Balance");

    // transfer the amount to the owner
    payable(owner()).transfer(amount);

    // emit event to log tips withdrawn
    emit TipsWithdrawn(owner(), amount);
  }

  /// @notice function to show the contract balance
  /// @dev uses the onlyOwner modifier from the Ownable contract
  function getContractBalance() 
  public 
  view 
  onlyOwner 
  returns (uint256) {
    return address(this).balance;
  }

}