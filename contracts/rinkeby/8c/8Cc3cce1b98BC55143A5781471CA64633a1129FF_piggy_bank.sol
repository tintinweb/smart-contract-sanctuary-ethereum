/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.13;

contract piggy_bank {

    address owner;
    struct People {
        address addr;
        uint withdrawPerTime;
    }

    People Betty;

    modifier onlyBetty() {
        require(Betty.addr == msg.sender," not the owner:Betty");
        _;
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender," not the owner:Andrew");
        _;
    }

    constructor(address _child) {
        owner = msg.sender; // init the msg.sender is Andrew;
        Betty.addr = _child;
    }

    function setWithDraw(uint _withdrawPerTime) public onlyOwner {
        Betty.withdrawPerTime = _withdrawPerTime;
    }

    function withdraw() public onlyBetty {
        require(Betty.withdrawPerTime < address(this).balance,"not enough funds" );

        (bool success,)  = payable(msg.sender).call{value: Betty.withdrawPerTime}("");
        require(success,"Failed to send Ether");
    }

   function deposit() payable public {
   
    }


}