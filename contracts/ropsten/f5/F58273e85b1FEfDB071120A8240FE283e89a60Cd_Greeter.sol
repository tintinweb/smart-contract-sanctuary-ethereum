/**
 *Submitted for verification at Etherscan.io on 2022-03-10
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract Greeter {
    address public minter;
    string name;
    mapping(address => uint256) public balances;

    event sent(address from, address to, uint256 amount);

    constructor(string memory _greeting) {
        minter = msg.sender;
        name = _greeting;
    }

    function mint(address receiver, uint256 amount) public {
        require(msg.sender == minter, "You not a admin. Can't mint");
        balances[receiver] += amount;
    }

    function send(
        address _from,
        address _to,
        uint256 amount
    ) public {
        require(amount <= balances[msg.sender], "You don't have enought coin");
        balances[msg.sender] -= amount;
        balances[_to] += amount;
        emit sent(_from, _to, amount);
    }
}