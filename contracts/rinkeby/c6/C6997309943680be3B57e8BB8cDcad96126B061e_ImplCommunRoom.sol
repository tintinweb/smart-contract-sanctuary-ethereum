// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.0 <0.9.0;

import "./CommunRoom.sol";
import "./Connection.sol";

/// @title ImplCommunRoom
/// @author Youssef Chiguer
/// @notice This is the contract implementation for a chat Commun Room
/// @dev No fallback function was implemented

contract ImplCommunRoom is CommunRoom {
    // Unit Price for messages in wei
    uint256 private constant UPRICE = 100000000000000;

    // Connection mapping betweeen owners and connections
    mapping(address => Connection) private _connections;

    function connect() external payable override {
        _connect(msg.sender);
    }

    function connect(address _owner) external payable override {
        _connect(_owner);
    }

    function send(string calldata _message)
        external
        override
        onlyConnected
        returns (bytes32)
    {
        Connection _connection = _connections[msg.sender];

        require(
            _connection.credit() >= UPRICE,
            "The value is too low, must be more than or equal to 100000000000000 wei"
        );

        _connection.payUp(UPRICE);

        emit MsgSent(msg.sender, _message);

        return _hash(_message, address(_connection));
    }

    function fillUp() external payable override onlyConnected {
        require(msg.value > 0, "The value is too low, must be more than 0 wei");

        _connections[msg.sender].fillUp(msg.value);
    }

    function transferConnection(address _newOwner)
        external
        override
        onlyConnected
    {
        require(
            _newOwner != msg.sender,
            "The new owner is the same as the sender"
        );
        require(
            address(_connections[_newOwner]) == address(0),
            "The new owner already has a connection"
        );
        require(_newOwner != address(0), "The new owner is not valid");

        _connections[_newOwner] = _connections[msg.sender];
        delete _connections[msg.sender];
    }

    function credit() external view override onlyConnected returns (uint256) {
        return _connections[msg.sender].credit();
    }

    function _connect(address _owner) private {
        // Only one connection can be owned
        require(
            address(_connections[_owner]) == address(0),
            "A connection has been created by this address before"
        );

        // To ensure that the owner will contribute to the Commun Room
        require(
            msg.value >= UPRICE,
            "The value is too low, must be more than or equal to 100000000000000 wei"
        );

        // Create a new connection
        Connection connection = new Connection(msg.value);
        _connections[_owner] = connection;

        emit Connected(_owner);
    }

    function _hash(string calldata _message, address _connection)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_message, _connection));
    }

    modifier onlyConnected() {
        require(
            address(_connections[msg.sender]) != address(0),
            "No connection is made for this address"
        );
        _;
    }
}