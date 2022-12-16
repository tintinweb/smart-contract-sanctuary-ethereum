/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

contract Just_a_funny_idea{

    uint count = 5;
    string count_1 = "I died thinking about it";
    uint count_2 = 3;

    function Number_machine_Genesis() public view returns(uint){
        return count;
    }
    function Number_machine_Genesis(uint) public{
        count = count * 2;
    }
    function Number_machine_Genesis2(uint) public{
        count = count * 0;
    }
    function Number_machine_second() public view returns(string memory){
        return count_1;
    }
    function Number_machine_second(string memory txt) public{
        count_1 = string.concat(count_1, " ", txt);
    }
    function Number_machine_third() public view returns(uint){
        return count_2;
    }
    function Number_machine_third(uint) public{
        count_2 = count_2 + 10;
        count_2 = count_2 * 5;
        count_2 = count_2 / 2;
    }
}