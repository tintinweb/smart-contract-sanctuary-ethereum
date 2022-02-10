//SPDX-License-Identifier: WTFPL

pragma solidity =0.8.11;

contract BadBank {
    mapping(address => uint256) balances;

    constructor() payable {
        require(msg.value == 5 ether);
    }

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        require(balances[msg.sender] != 0, "nothing to withdraw!");
        (bool success, ) = payable(msg.sender).call{
            value: balances[msg.sender]
        }("");
        balances[msg.sender] = 0;
        require(success, "oops, try again");
    }
}