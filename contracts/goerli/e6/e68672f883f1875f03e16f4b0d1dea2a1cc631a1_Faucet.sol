/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Faucet {

    address public immutable owner;
    uint256 public amountAllowed = 100000000000000000;
    uint public epochInDay = 5760; 
    uint public currentEpoch;
    mapping(address => uint) public lastTime;

    event Deposit(address _address, uint256 amount);
    event Withdraw(address _address, uint256 amount);
    event Destroy(uint256 amount);

    receive() external payable {
        deposit();
    }

    constructor() {
        owner = msg.sender;
    }

    function withdraw() external{
        currentEpoch = block.number;
        require(lastTime[msg.sender] == 0 || lastTime[msg.sender] + epochInDay < currentEpoch, "Can't request multiple times");
        require(address(this).balance > amountAllowed, "fund is not enough");
        lastTime[msg.sender] = currentEpoch;
        payable(msg.sender).transfer(amountAllowed);
        emit Withdraw(msg.sender, address(this).balance);
    }

    function destroy() external{
        require(msg.sender == owner, "not owner address");
        selfdestruct(payable(msg.sender));
	}

    function deposit() public payable{
        emit Deposit(msg.sender, msg.value);
    }
}