/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/Chat.sol


pragma solidity ^0.8.6;


/**
 * @title Chat
 * @author erhant
 * @dev A chat contract that allows users to send messages via their addresses. Messages are stored as events. 
 * For UI purposes, users can give themselves aliases.
 */
contract Chat is Ownable {
  /**
   * @dev MessageSent event is emitted when `from` sends `text` to `to`.
   */
  event MessageSent(address indexed _from, address indexed _to, string _text);

  /**
   * @dev AliasSet is emitted when `_user` sets their alias to `_alias`. Resetting an alias can be done by setting the alias to empty string.
   */
  event AliasSet(address indexed _user, string _alias);

  /**
   * @dev Entry fee to interact with the contract.
   */
  uint256 public entryFee = 0.001 ether;
 
  /**
   * @dev Mapping to keep track of which users have paid the entry fee.
   */
  mapping(address => bool) public hasPaidFee; 

  /**
   * @dev Modifier to allow users to interact only if they have paid the entry fee.
   */
  modifier onlyFeePaid() {
    require(hasPaidFee[msg.sender], "User did not pay the entry fee.");
    _;
  }

  /**
   * @dev Emits a MessageSent event. The caller must have paid the entry fee.
   */
  function sendMessage(string calldata _text, address _to) external onlyFeePaid { 
    emit MessageSent(msg.sender, _to, _text);
  }

  /**
   * @notice The alias can't be more than 30 bytes.
   * @dev Emits an AliasSet event. The caller must have paid the entry fee.
   */
  function setAlias(string calldata _alias) external onlyFeePaid {
    require(bytes(_alias).length < 30, "Alias too long!");
    emit AliasSet(msg.sender, _alias);
  }
 
  /**
   * @notice If the owner changes the entry fee while someone is paying the entry fee, that could lead to a slight change in the paid fee.
   * If the fee is lower, the user will probably get paid back more than what they have sent. If higher, the user will pay the prior amount.
   * @dev User pays the entry fee. The amount can be more than entry fee, in which case the extra amont is sent back to the user.
   */
  function payEntryFee() external payable {
    require(!hasPaidFee[msg.sender], "User has already paid the entry fee.");
    require(msg.value >= entryFee, "Insufficient amount for the entry fee!");
    
    hasPaidFee[msg.sender] = true;

    // send the extra back
    if (msg.value > entryFee) {
      payable(msg.sender).transfer(msg.value - entryFee);
    }
  }

  /**
   * @dev Change the entry fee (in case ether goes up!)
   */
  function changeEntryFee(uint256 amount) external onlyOwner {
    entryFee = amount;
  }

  /**
   * @dev Withdraw contract funds.
   */
  function withdraw() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  receive() external payable {}
  fallback() external payable {}
}