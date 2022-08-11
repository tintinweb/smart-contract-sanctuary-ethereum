/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool); 
}


contract CommunityChest { 
    address public owner;
    uint256 public unlockDate;
    mapping(address => uint256) other_assets_unlockDate;

    constructor() {
        owner = msg.sender;
        unlockDate = block.timestamp;
    }

    function setUnlockDate(uint256 timestamp) public{  
        require(msg.sender==owner,"owner required");
        unlockDate = timestamp;
    }

    function getUnlockDate(address asset)  public view returns (uint256){       
        return other_assets_unlockDate[asset] ;
    }

    function setUnlockDate(address asset,uint256 timestamp) public{  
        require(msg.sender==owner,"owner required");
        other_assets_unlockDate[asset] = timestamp;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function approveAsset(address asset,address addr,uint256 amount)  public{    
        require(msg.sender==owner,"owner required");
        IERC20(asset).approve(addr, amount);
    }

    function transferAsset(address asset,address newAccount,uint256 _value) public{
        require(msg.sender==owner,"owner required");
        require(block.timestamp >= other_assets_unlockDate[asset],"not unlocked yet");
        IERC20(asset).transferFrom(address(this),newAccount, _value);
    }  

    function withdraw(address to, uint256 amount) public {
        require(msg.sender==owner,"owner required");
        require(amount<= address(this).balance, " insufficient funds");
        require(block.timestamp >= unlockDate,"not unlocked yet");
        payable(to).transfer(amount);
    }

    function setOwner(address newOwner)  public{
        require(msg.sender==owner,"owner required");    
        owner = newOwner;
    }

    event LogDepositReceived(address indexed _from,  uint _value);

    fallback() external payable {
        require(msg.data.length == 0); emit LogDepositReceived(msg.sender,msg.value);
    }

    receive() external payable {
        emit LogDepositReceived(msg.sender,msg.value);
    }
}