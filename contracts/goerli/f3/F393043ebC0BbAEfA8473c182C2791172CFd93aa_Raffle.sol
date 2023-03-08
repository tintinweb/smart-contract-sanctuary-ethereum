/**
 *Submitted for verification at Etherscan.io on 2023-03-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title BridgeNFT_Invest_Refund
 * @dev Implements voting process along with vote delegation
 */
contract Raffle {
    
    // Stores investors list with their investment amount against wallet address
    mapping (address => uint) public investorsList;
    
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function sendMoney() public payable {
        investorsList[msg.sender] += msg.value;
    }

    function withdrawMoney(address payable _to, uint _amount) public {
        require(address(this).balance >= _amount, "Not Enough Funds!");
        investorsList[msg.sender] -= _amount;
        _to.transfer(_amount);
    }

}