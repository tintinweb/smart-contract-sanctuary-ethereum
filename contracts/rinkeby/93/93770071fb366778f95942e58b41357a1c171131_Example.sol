/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Example {
    constructor() public {
        owner = msg.sender;
    }
    address[] private investorList;
    address private owner;

    //investorList.push(msg.sender);

    mapping(address=>uint) balances;

    function invest() external payable{
        balances[msg.sender] += msg.value;
        bool inside = false;
        if (investorList.length>0){
            for (uint i=0; i < investorList.length; i++) {
                if (msg.sender == investorList[i]) {
                    inside = true;
                }
            }
            if (inside == false){
                investorList.push(msg.sender);
            }
        } else{
            investorList.push(msg.sender);
        }
        
    }

    function balanceOf() external view returns(uint){
        return address(this).balance;
    }
    function sendMoney(address to, uint value) public {
    require(msg.sender==owner);
    address payable receiver = payable(to);
    receiver.transfer(value);
    }

    function showInvestors() public view returns (address[] memory) {
        return investorList;
    }

    function showAllInvestementsByAddress(address investor) external view returns(uint){
        return balances[investor];
    }

    }