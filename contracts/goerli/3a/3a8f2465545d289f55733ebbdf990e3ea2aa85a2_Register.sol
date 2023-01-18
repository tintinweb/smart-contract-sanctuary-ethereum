/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

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