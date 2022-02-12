/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract payment{
    address owner;
    uint amount = 10 ether;
    address B_payeer = 0x1DFC6D2909373f971f5Df0F7679B0A268F77a1cd; //receiver
    address referee = 0x1DFC6D2909373f971f5Df0F7679B0A268F77a1cd;
    address guardian = 0xdA390008Fe664680C8fa75ccA3D2Db0Fb6D2681A;
    uint256 EndDate = 1644623940;
    
    function invest() external payable{
        require(msg.value + address(this).balance <= amount, "High Balance:");
    }

    function balanceOf() external view returns(uint){
        return address(this).balance;
    
    }
    

    
    function TipJar() external view returns(uint) {  // contract's constructor function
        //owner = msg.sender;
        return block.timestamp;
    }

    function recover(address _to) external payable {
        uint256 balance = address(this).balance;
        require(msg.sender == guardian && block.timestamp >  EndDate, "Invalid guardian or Date error");
        withdraw(_to, balance);
    }

    function sendtoReceiver() public {
        uint256 balance = address(this).balance;
        require(msg.sender == referee, "Invalid referre");
        withdraw(B_payeer, balance);
    }

    function withdraw(address _to, uint _amount) private {
       (bool sent, ) = _to.call{value: _amount}("");
       require(sent, "Failed to send Ether");
        
    }
}