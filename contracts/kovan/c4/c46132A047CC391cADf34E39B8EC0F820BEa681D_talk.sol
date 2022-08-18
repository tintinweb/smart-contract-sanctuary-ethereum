// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";

contract talk is Ownable {
    struct client {
        address _address;
        bytes32 _name;
        bytes32 publicKey;
    }
    mapping(address => client) clients;
    address[] clientsArray;

    struct message {
        bytes32 date;
        bytes32 contentType;
        bytes32 content; // 32*8=256 bytes per message
    }
    struct message_history {
        address sender;
        address receiver;
        message[] message_sent;
    }

    // senderAddress => ( receiverAddress =>  message_history ))
    mapping(address => mapping(address => message_history)) private data;

    modifier registered() {
        require(
            clients[msg.sender]._address == msg.sender,
            "Client haven't registered!"
        );
        _;
    }

    modifier permitted(address sender, address receiver) {
        require(
            msg.sender == sender || msg.sender == receiver,
            "Not permitted"
        );
        _;
    }

    function addClient(bytes32 name) public {
        require(
            clients[msg.sender]._address == address(0),
            "Client already exits!"
        );
        clients[msg.sender]._address = msg.sender;
        clients[msg.sender]._name = name;
        clientsArray.push(msg.sender);
    }

    function delClient() public registered {
        require(
            clients[msg.sender]._address == msg.sender,
            "Permission denied!"
        );
        delete clients[msg.sender];
        for (
            uint256 clientIndex = 0;
            clientIndex < clientsArray.length;
            clientIndex++
        ) {
            if (clientsArray[clientIndex] == msg.sender) {
                clientsArray[clientIndex] = clientsArray[
                    clientsArray.length - 1
                ];
                clientsArray.pop();
            }
        }
    }

    function getClientsNumber() public view registered returns (uint256) {
        return clientsArray.length;
    }

    function getClient(uint256 index)
        public
        view
        registered
        returns (client memory)
    {
        return clients[clientsArray[index]];
    }

    function sendMessage(
        address receiver,
        bytes32 date,
        bytes32 contentType,
        bytes32 content
    ) public registered {
        if (data[msg.sender][receiver].sender == address(0)) {
            data[msg.sender][receiver].sender = msg.sender;
            data[msg.sender][receiver].receiver = receiver;
        }
        message memory new_message;
        new_message.date = date;
        new_message.contentType = contentType;
        new_message.content = content;
        data[msg.sender][receiver].message_sent.push(new_message);
    }

    function getMessageLength(address sender, address receiver)
        public
        view
        registered
        permitted(sender, receiver)
        returns (uint256)
    {
        return data[sender][receiver].message_sent.length;
    }

    function getMessage(
        address sender,
        address receiver,
        uint256 index
    )
        public
        view
        registered
        permitted(sender, receiver)
        returns (message memory)
    {
        return data[sender][receiver].message_sent[index];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

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

/*
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