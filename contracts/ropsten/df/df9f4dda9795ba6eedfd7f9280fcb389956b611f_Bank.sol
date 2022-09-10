/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

pragma solidity >=0.7.0 <0.9.0;

contract Bank {
	address owner;
    mapping(address => uint256) public balances;
	
    constructor() {
        owner = msg.sender;
    }

	function deposite() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount);
        msg.sender.call{value: 10}("");
        balances[msg.sender] -= amount;
    }
}