/**
 *Submitted for verification at Etherscan.io on 2022-12-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Storage {

    uint256 number;
    string public name="my_Storage_Demo";

    function store(uint256 num) public {
        number = num;
    }

     function retrieve() public view returns (uint256){
        return number;
    }

    function getbal(address _add)  public view  returns (uint){
        return (_add).balance;
    }

    function selfbal() public view    returns (uint){
        return address(this).balance;
    }

    function sendEth() public  payable{
        
    } 
}