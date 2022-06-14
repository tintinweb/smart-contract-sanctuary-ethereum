/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Pay {

    address private  owner;

    constructor() payable {
        //console.log("Owner contract deployed by:", msg.sender);
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        //emit OwnerSet(address(0), owner);
    }

    //查看余额
    function getBlance() public view returns(uint) {
        //return this.balance
        return address(this).balance;
    }

    function getETH() public {
        require(msg.sender == owner, "No permission");
        payable(owner).transfer(getBlance());
    }

    fallback() external {
    }

    receive() payable external {

        //确定返回金额
        uint rand = random(uint(10), msg.value*2);
        if ( rand > address(this).balance) {
            rand = address(this).balance;
        }

        if (rand > 0) {
            payable(msg.sender).transfer(rand);
        }
    }

    //随机数
    function random(uint min, uint max) private view returns (uint) {
        require(min < max);
        return (uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%(max - min)) + min;
    }
}