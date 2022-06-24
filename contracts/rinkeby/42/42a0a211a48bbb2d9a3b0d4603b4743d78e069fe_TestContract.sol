/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract TestContract {

    uint256 developmentPoints = 0;
    string text = "Farmland For The Win!!!";

    function farmlandFtw() public view returns (string memory) {
        return text;
    }

    function retrieveDp() public view returns (uint256) {
        return developmentPoints;
    }

    function increaseDp(uint256 val) public {
        developmentPoints += val;
    }
}