/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);
}

contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        owner = newOwner;
    }
}

contract TimeLock is Ownable {

    uint256 constant DAY=86400;

    uint256 public expireDate=0;

    modifier expireCheck() {
        require(block.timestamp>=expireDate,"time is not due");
        _;
    }

    function extensionbyDays(uint _day)public onlyOwner expireCheck{
         expireDate=block.timestamp+DAY*_day;
    }

    function withdrawNativeCoin(uint256 amount) public onlyOwner expireCheck{
        payable(msg.sender).transfer(amount);
    }

    function withdrawToken(address token,uint256 amount) public onlyOwner expireCheck{
        IERC20 erc20=IERC20(token);
        erc20.transfer(msg.sender,amount);
    }

    receive() external payable{

    }

    function deposit() public payable {

    }
}