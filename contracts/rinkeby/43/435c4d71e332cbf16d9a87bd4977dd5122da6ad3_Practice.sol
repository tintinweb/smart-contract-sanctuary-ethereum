/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

// SPDX-License-Identifier: MIT
// File: contracts/Practice.sol


pragma solidity ^0.8.0;

contract Practice{
    address owner;
    uint256 Data;
    uint256 Money;

    constructor(address init_owner,uint256 init_Data,uint256 init_Money){
        owner = init_owner;
        Data = init_Data;
        Money = init_Money;
    }

    function setData(uint256 new_Date) public{
        Data = new_Date;
    }
    function setMoney(uint256 new_Money) public{
        Money = new_Money;
    }
    function getData() public view returns(uint256){
        return Data;
    }
    function getMoney() public view returns(uint256){
        return Money;
    }

    receive() external payable{}
    
    function withdraw(address payable recipient) external{
        require(recipient == owner,"shi ben ren");
        uint256 bal = address(this).balance;
        (bool success,) = recipient.call{value:bal}("");
        require(success,"mei qian le");
    }
}