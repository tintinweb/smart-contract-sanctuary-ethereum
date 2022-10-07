/**
 *Submitted for verification at Etherscan.io on 2022-10-03
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

contract testcontract {
   
    address public owner;

    uint256 public TotalInvested;
    uint256 public Totalwithdrawn;
   
   
    constructor() {
        owner = msg.sender;
    }

    function deposit() external payable {

        require(msg.value >= 0.01 ether, "Minimum deposit amount is 0.01 ETH");
        TotalInvested += msg.value;
    }
    
    function withdraw(uint _amount) external payable {
    
        Totalwithdrawn += _amount;

        payable(msg.sender).transfer(_amount);
        
    }


    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn) {
        return (TotalInvested, Totalwithdrawn);
    }

}