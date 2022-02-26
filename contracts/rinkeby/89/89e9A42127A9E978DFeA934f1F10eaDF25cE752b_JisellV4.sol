//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@opengsn/contracts/src/BaseRelayRecipient.sol";

contract JisellV4 is BaseRelayRecipient {
    struct Card {
        bytes32 id;
        address owner;
        uint256 balance;
        bytes32 retailer;
    }

    address forwarder;
    Card[] public cards;
    uint256 public totalFunded;
    uint256 public totalSpent;
    mapping(bytes32 => bool) private ids;
    mapping(bytes32 => uint256) private idToIndex;
    mapping(address => bytes32) public userToState;
    string public override versionRecipient = "2.2.0";

    event Mint(
        address indexed user,
        bytes32 indexed card,
        uint256 balance,
        bytes32 indexed retailer
    );
    event Spend(address indexed user, bytes32 indexed card, uint256 amount);
    event Fund(address indexed user, bytes32 indexed card, uint256 amount);
    event Transfer(address from, address to, bytes32 indexed card);
    event SetState(address indexed user, bytes32 state);

    constructor(address _forwarder) {
        forwarder = _forwarder;
    }

    function setState(address _user, bytes32 _state) public {
        require(_user == _msgSender(), "Unauthorized");
        userToState[_user] = _state;
        emit SetState(_user, _state);
    }

    function mint(
        address _user,
        bytes32 _id,
        uint256 _balance,
        bytes32 _retailer
    ) public {
        require(userToState[_user] != "", "User not found");
        require(_user == _msgSender(), "Unauthorized");
        require(ids[_id] == false, "Duplicate");
        Card memory card = Card(_id, _user, _balance, _retailer);
        idToIndex[_id] = cards.length;
        cards.push(card);
        ids[_id] = true;
        totalFunded += _balance;
        emit Mint(_user, _id, _balance, _retailer);
    }

    function spend(bytes32 _id, uint256 _amount) public {
        require(ids[_id] == true, "Card not found");
        Card storage card = cards[idToIndex[_id]];
        require(card.owner == _msgSender(), "Unauthorized");
        require(card.balance >= _amount, "Insufficient fund");
        card.balance -= _amount;
        totalSpent += _amount;
        emit Spend(_msgSender(), _id, _amount);
    }

    function fund(bytes32 _id, uint256 _amount) public {
        require(ids[_id] == true, "Card not found");
        Card storage card = cards[idToIndex[_id]];
        require(card.owner == _msgSender(), "Unauthorized");
        card.balance += _amount;
        totalFunded += _amount;
        emit Fund(_msgSender(), _id, _amount);
    }

    function transfer(bytes32 _id, address _to) public {
        Card storage card = cards[idToIndex[_id]];
        require(userToState[_to] != "", "User not found");
        require(ids[_id] == true, "Card not found");
        require(card.owner == _msgSender(), "Unauthorized");
        card.owner = _to;
        emit Transfer(_msgSender(), _to, _id);
    }

    function exists(bytes32 _id) public view returns (bool) {
        return ids[_id];
    }

    function getCard(bytes32 _id) public view returns (Card memory card) {
        require(ids[_id] == true, "Card not found");
        return cards[idToIndex[_id]];
    }

    function totalSupply() public view returns (uint256 count) {
        return cards.length;
    }

    function totalBalance() public view returns (uint256 count) {
        return totalFunded - totalSpent;
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    function trustedForwarder() public virtual view returns (address){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal virtual view returns (bytes calldata);

    function versionRecipient() external virtual view returns (string memory);
}