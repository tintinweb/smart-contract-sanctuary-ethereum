/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;


contract getdata {
    //uint counter
    address public trainer_add;
    //uint public accuracy

    function get_trainer_add(address  A) public {
        trainer_add = A;
    }

    function get_trainer_add() public view returns (address ) {
        return trainer_add;
    }
}