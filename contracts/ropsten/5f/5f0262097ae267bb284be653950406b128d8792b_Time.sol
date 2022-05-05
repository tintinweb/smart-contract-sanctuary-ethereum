/**
 *Submitted for verification at Etherscan.io on 2022-05-05
*/

//SPDX-License-Identifier:MIT
pragma solidity^0.8.0;
contract Time{
function getTime(uint time ) public view returns(uint){
if( block.timestamp<time) return(time+4830);
else return 0;  }
}