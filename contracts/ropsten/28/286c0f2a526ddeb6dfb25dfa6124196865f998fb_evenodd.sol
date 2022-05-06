/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

//SPDX-License-Identifier:MIT
pragma solidity^0.8.7;
contract evenodd{
    function check(uint n)public pure returns(string memory){
        if(n%2==0){
            return("even number");
        }
        else {return("odd number");}
    }
}