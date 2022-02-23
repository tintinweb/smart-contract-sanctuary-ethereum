/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.4.25;

contract StorageStructure {
    address public implementation;
    address public owner;
    mapping(address => uint256) public points;
    uint256 public totalPlayers;
}

contract ImplementationV1 is StorageStructure {
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function addPlayer(address _player, uint256 _points) public {
        require( points[_player] == 0 );
        points[_player] = _points;
        totalPlayers++;
    }

    function setPlayer(address _player, uint256 _points) public onlyOwner {
        require( points[_player] != 0 );
        points[_player] = _points;
        if(_points == 0) totalPlayers--;
    }
}