// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IReceiverToken {
  function balanceOf(address _owner, uint _tokenId) external returns(uint);
 }

 interface IRelayerToken {
  function balanceOf(address _owner, uint _tokenId) external returns(uint);
 }

contract Messenger is Ownable {

  event NewMessage(address indexed from, uint tokenId, uint timestamp, string message);
  event NewRelayedMessage(address indexed from, uint srcChainId, uint tokenId, uint timestamp, string message);
  event NewReply(address indexed from, string messageId, uint timestamp, string message);
  event NewRelayedReply(address indexed from, uint srcChainId, string messageId, uint timestamp, string message);

  // uint replyMessagePrice = 1000000000000000; // 0.001 eth
  uint replyMessagePrice = 0; // free just pay gas

  IReceiverToken receiverContract;
  IRelayerToken relayerContract;

  /* ========== MUTATIVE FUNCTIONS ========== */

  // sending a message from base chain
  function sendMessage(uint _tokenId, string calldata _content) public {
    // require sender to hold relayer NFT first
    require ((relayerContract.balanceOf(msg.sender, _tokenId) > 0), "Error: must hold correct relayer NFT!");

    emit NewMessage(msg.sender, _tokenId, block.timestamp, _content);
  }

  // sending a message from another chain/network
  function sendRelayedMessage(address _from, uint _srcChainId, uint _tokenId, string calldata _content) public {
    // require sender to hold sender NFT first
    require ((relayerContract.balanceOf(_from, _tokenId) > 0), "Error: must hold reciprocal Sender NFT!");

    emit NewRelayedMessage(_from, _srcChainId, _tokenId, block.timestamp, _content);
  }

  // sending a reply from base chain
  function replyMessage(string memory _messageId, string calldata _content) public payable {
    require ((msg.value >= replyMessagePrice), "not enought eth sent");

    emit NewReply(msg.sender, _messageId, block.timestamp, _content);
  }

  // sending a reply from another chain/network
  function sendRelayedReply(address _from, uint _srcChainId, string memory _messageId, string calldata _content) public payable {
    require ((msg.value >= replyMessagePrice), "not enought eth sent");

    emit NewRelayedReply(_from, _srcChainId, _messageId, block.timestamp, _content);
  }

  /* ========== RESTRICTED  FUNCTIONS ========== */

  function setReceiverContractAddress(address _address) external onlyOwner {
    receiverContract = IReceiverToken(_address);
  }

  function setRelayerContractAddress(address _address) external onlyOwner {
    relayerContract = IRelayerToken(_address);
  }

  function setReplyMessagePrice(uint _price) external onlyOwner {
    replyMessagePrice = _price;
  }

  function withdraw() public payable onlyOwner {
    (bool os,)= payable(owner()).call{value:address(this).balance}("");
    require(os);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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