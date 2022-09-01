// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./IChatroomEngine.sol";
import "./ChatroomFactory.sol";

/// @title ChatroomEngine
/// @author [email protected]
contract ChatroomEngine is IChatroomEngine {
    address[] private chatrooms;
    uint256 public cost = 0.01 ether;

    function create() external payable {
        require(cost == msg.value, "Cost to create chatroom not met.");
        ChatroomFactory chatroom = new ChatroomFactory(msg.sender);
        chatrooms.push(address(chatroom));
    }

    function getAllChatrooms() public view returns (address[] memory) {
        return chatrooms;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

/// @title IChatroomEngine
/// @author [email protected]
interface IChatroomEngine {
    // create new chatroom
    function create() external payable;

    //  get all chatrooms created
    function getAllChatrooms() external returns (address[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./IChatroomFactory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title ChatroomFactory
/// @author [email protected]
contract ChatroomFactory is IChatroomFactory, Ownable {
    mapping(address => ParticipantStruct) public participantList;
    MessageStruct[] private messages;

    constructor(address _caller) {
        initialize(_caller);
    }

    function initialize(address _caller) private {
        _transferOwnership(_caller);
        participantList[_caller] = ParticipantStruct(
            _caller,
            "owner",
            block.timestamp
        );
    }

    function checkIsParticipant(address _addr) public view returns (bool) {
        return participantList[_addr].addr != address(0);
    }

    function addParticipant(address _addr, string calldata _identifier)
        public
        onlyOwner
    {
        require(checkIsParticipant(_addr), "Address is participant.");
        ParticipantStruct memory p = ParticipantStruct(
            _addr,
            _identifier,
            block.timestamp
        );
        emit NewParticipantAdded(p);
        participantList[_addr] = p;
    }

    function sendMessage(string calldata _msg) external {
        require(checkIsParticipant(msg.sender), "Not a participant");
        ParticipantStruct memory p = participantList[msg.sender];
        MessageStruct memory newMsg = MessageStruct(p, block.timestamp, _msg);
        emit NewMessage(newMsg);
        messages.push(newMsg);
    }

    function getAllMessages() external view returns (MessageStruct[] memory) {
        return messages;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

/// @title IChatroomFactory
/// @author [email protected]
interface IChatroomFactory {
    // individual participant data
    struct ParticipantStruct {
        address addr;
        string identifier;
        uint256 joined;
    }

    // message data
    struct MessageStruct {
        ParticipantStruct participant;
        uint256 timestamp;
        string msg;
    }

    // A participant added
    event NewParticipantAdded(ParticipantStruct);

    // A new message added
    event NewMessage(MessageStruct);

    // ---
    // READ
    // ---

    // check is address a participant to the chatroom
    function checkIsParticipant(address _addr) external view returns (bool);

    // returns all messages from the list
    function getAllMessages() external view returns (MessageStruct[] memory);

    // ---
    // WRITE
    // ---

    // add address to the participant list. Must be owner
    function addParticipant(address _addr, string calldata _identifier)
        external;

    // add message to the messages list. Must be participant
    function sendMessage(string calldata _msg) external;
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