/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Crowfunding{
    uint256 public global;
    address contract_dir = address(this);
    address payable dst;
    address payable src;


    function __init__(address payable dst1, address payable dst2 ) public payable {
        global = 0;
        dst = dst1;
        src = dst2;
    }
    function send() public payable{
        global += 1;
        if (global > 2){
            if(contract_dir.balance > 1000000000000000){
                dst.transfer(contract_dir.balance);
                global=0;
            }            
            else{
                src.transfer(contract_dir.balance);
                global=0;
            }
        }
        else{          
        }
    }

}