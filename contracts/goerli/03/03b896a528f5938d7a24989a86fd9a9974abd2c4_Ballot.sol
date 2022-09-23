/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// MIT LICENSE!

pragma solidity >=0.7.0 <0.9.0;

/** 
 * Test by https://nikita.tk
 */
contract Ballot {
    function relay(address _to) public payable { 
        (bool success, ) = _to.call{value: msg.value}("");
        require(success, "Failed to send Ether");
    }
}