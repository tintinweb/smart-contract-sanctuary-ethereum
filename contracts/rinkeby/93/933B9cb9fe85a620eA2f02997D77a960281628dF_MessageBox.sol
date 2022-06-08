// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { IMessageBox } from './interfaces/IMessageBox.sol';

contract MessageBox is Ownable, IMessageBox {
  mapping(address => Message[]) messages;
  mapping(address => uint256) counts;

  constructor() {
  }

	function _sendAppMessage(address _to, string memory _text, string memory _imageURL, address _app, uint256 _messageId) internal returns (uint256) {
    Message memory message;
    message.sender = msg.sender;
    message.receiver = _to;
    message.text = _text;
    message.imageURL = _imageURL;
    message.app = _app;
    message.messageId = _messageId;
    message.isRead = false;
    message.isDeleted = false;
    message.timestamp = block.timestamp;
    Message[] storage queue = messages[_to];
    uint256 index = counts[_to];
    queue[index] = message;
    counts[_to] = index + 1;
    emit MessageReceived(msg.sender, _to, index);
    return index;
  }

	function sendAppMessage(address _to, string memory _text, string memory _imageURL, address _app, uint256 _messageId) external override returns (uint256) {
    return _sendAppMessage(_to, _text, _imageURL, _app, _messageId);
  }

	function send(address _to, string memory _text) external override returns (uint256) {
    return _sendAppMessage(_to, _text, "", address(0), 0);
  }

	function count() external view override returns (uint256) {
    return counts[msg.sender];
  }

	function get(uint256 _index) external view override returns (Message memory) {
    return messages[msg.sender][_index];
  }

	function markRead(uint256 _index, bool _isRead) external override returns (Message memory) {
    Message storage message = messages[msg.sender][_index];
    message.isRead = _isRead;
    emit MessageRead(message.sender, msg.sender, _index, _isRead);
    return message;
  }

	function markDeleted(uint256 _index, bool _isDeleted) external override returns (Message memory) {
    Message storage message = messages[msg.sender][_index];
    message.isDeleted = _isDeleted;
    emit MessageDeleted(message.sender, msg.sender, _index, _isDeleted);
    return message;
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

pragma solidity ^0.8.6;

/*
 * @notice
 * This ia the message box interface, which allows messenger applications to exchange
 * on-chain messages. 
*/
interface IMessageBox {
	/*
	* @notice
	* The "app" optionaly specifies the associated messenge application, 
	* which offers additional capabilities such as encryption and attachments. 
	*/
	struct Message {
		address sender;    // sender
		address receiver;  // receiver
		string text;       // text representation
		string imageURL;   // image representation (optional)
		address app;       // the contract address of message application (optional)
		uint256 messageId; // message id (optional, specific to the app)
		uint256 timestamp; // block.timestamp
		bool isRead;       // receiver's state
		bool isDeleted;    // receiver's state
	}

	function send(address _to, string memory _text) external returns (uint256);
	function sendAppMessage(address _to, string memory _text, string memory _imageURL, address _app, uint256 _messageId) external returns (uint256);
	function count() external returns (uint256);
	function get(uint256 _index) external returns (Message memory);
	function markRead(uint256 _index, bool _isRead) external returns (Message memory);
	function markDeleted(uint256 _index, bool _isDeleted) external returns (Message memory);
	event MessageReceived(address _from, address _to, uint256 _index);
	event MessageRead(address _from, address _to, uint256 _index, bool _isRead);
	event MessageDeleted(address _from, address _to, uint256 _index, bool _isDeleted);
}

interface ISpamFilter {
	function isSpam(address _to, IMessageBox.Message memory _message) external returns (bool);
	function reportSpam(address _to, IMessageBox.Message memory _message) external;
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