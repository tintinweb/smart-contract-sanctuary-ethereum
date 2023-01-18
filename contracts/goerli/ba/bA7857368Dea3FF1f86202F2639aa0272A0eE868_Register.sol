/**
 *Submitted for verification at Etherscan.io on 2023-01-18
*/

//0xbA7857368Dea3FF1f86202F2639aa0272A0eE868
//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
 
contract Register {
        string private info;
   
        function getInfo() public view returns (string memory) {
            return info;
        }
 
        function setInfo(string memory _info) public {
            info = _info;
        }
}