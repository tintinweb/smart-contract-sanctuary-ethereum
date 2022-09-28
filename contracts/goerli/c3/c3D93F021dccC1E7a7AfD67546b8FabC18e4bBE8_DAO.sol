// SPDX-License-Identifier: NO LISENCE
pragma solidity ^0.8.9;

contract DAO {
    mapping(address => uint256) public balances;

    //存入任意金额
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        require(balances[msg.sender] > 0, "no balance");
        (bool sent, ) = msg.sender.call{value: balances[msg.sender]}("");
        require(sent, "withdraw failed");
        balances[msg.sender] = 0;
    }
}