/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

pragma solidity ^0.4.25;

contract StorageStructure {
    address public implementation;
    address public owner;
    mapping (address => uint) internal points;
    uint internal totalPlayers;
}

contract ImplementationV1 is StorageStructure {modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }
 
    function addPlayer(address _player, uint _points) 
        public onlyOwner 
    {
        require (points[_player] == 0);
        points[_player] = _points;
    }
    function setPoints(address _player, uint _points) 
        public onlyOwner 
    {
        require (points[_player] != 0);
        points[_player] = _points;
    }
}