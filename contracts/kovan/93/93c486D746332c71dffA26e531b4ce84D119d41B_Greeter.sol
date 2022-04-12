/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// SPDX-License-Identifier: MIT
pragma solidity^0.8.1;
contract Greeter{
    string s;
    function modify(string memory _s) public {
        require(msg.sender==tx.origin);
        s=_s;
    }
    function get() public view returns(string memory){
        require(msg.sender==tx.origin);
        return s;
    }
}