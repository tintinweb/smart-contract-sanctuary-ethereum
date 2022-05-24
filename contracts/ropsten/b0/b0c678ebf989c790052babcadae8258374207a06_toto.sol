/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

pragma solidity ^0.8.7;


contract toto {
    mapping(address => uint256) balances;

    constructor() public {
        balances[msg.sender] = 1000 ether;
        balances[address(this)] = 999000 ether;
    }

    function rand(string memory _password, address sender, uint256 timestamp, uint256 difficulty, uint256 vipPass) public returns (uint256) {
        return uint(keccak256(abi.encodePacked(
        sender,
        timestamp,
        difficulty,
        vipPass,
        balances[address(this)],
        _password)));

    }

    

    
}