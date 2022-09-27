/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract nombreContrato{
    uint256 public cont;
    address dir_actual = address(this);
    address payable dir_dest;
    address payable dir_dev;

    function Inicialized(address payable dest, address payable dest_not ) public {
        cont = 0;
        dir_dest = dest;
        dir_dev = dest_not;
    } 

    function Send() public payable{
        cont = cont + 1;
        if(cont == 3){
            if (dir_actual.balance >= 50000000000000000){
                dir_dest.transfer(dir_actual.balance);
                cont = 0;
            }else{
                dir_dev.transfer(dir_actual.balance);
                cont = 0;
            }
        }else{

        }
    }
}