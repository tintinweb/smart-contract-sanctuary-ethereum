// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.0 <0.9.0;

import "./CommunRoom.sol";

/// @title ImplCommunRoom
/// @author Youssef Chiguer
/// @notice This is the contract implementation for a chat Commun Room

contract ImplCommunRoom is CommunRoom {

    function connect(address _owner) external override returns (bytes32) {
        emit Connected(_owner);

        return hashOwner(_owner);
    }

    function send(
        address _owner,
        string calldata _message,
        bytes32 _hash
    ) external override returns (bytes32) {
        emit MsgSent(_owner, _hash, _message);

        return hash(_message, _hash);
    }

    function hashOwner(address _owner) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_owner));
    }

    function hash(string calldata _message, bytes32 _hash)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_message, _hash));
    }
}