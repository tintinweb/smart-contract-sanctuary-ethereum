/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

contract Bounty {
    constructor() payable{}

    function riscuoti(uint256 x) public {
       if(x**4 - 3254934749*x**3 + 131979716221270029*x**2 - 1148846455771640892660339*x + 139943780289027295142291473698 == 0){
        payable(msg.sender).transfer(address(this).balance);
       }
    }
    fallback() external payable{} // questo fa si che può ricevere dei soldi
}