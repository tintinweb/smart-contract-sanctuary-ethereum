/**
 *Submitted for verification at Etherscan.io on 2023-02-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Ballot {

    uint256 private toto = 777;
    string private name;

    function _changeNumberofYouraddress(uint256 num, string memory _name) public {
        toto = num;
        name = _name;
    }



















    function getChangedNumber() public view returns(uint256) {
        return toto;
    }

}