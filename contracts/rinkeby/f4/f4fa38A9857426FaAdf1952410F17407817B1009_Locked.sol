// I'm a comment!
// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

// pragma solidity ^0.8.0;
// pragma solidity >=0.8.0 <0.9.0;

contract Locked{


    function payEth() public payable {

    }
    function getBal () public view returns (uint){
        return address(this).balance;
    }

    function senEth(address Address_Id,uint ethers) public {
         address payable user = payable(Address_Id);
        user.transfer(ethers*1000000000000000000);
    }
}