/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

pragma solidity ^0.8.13;
// SPDX-License-Identifier: MIT

contract OriginstampContract {

    address public owner;

    event Submitted(bytes32 indexed pHash);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Originstamp() public {
	    owner = msg.sender;
    }

    function submitHash(bytes32 pHash) public onlyOwner() {
        emit Submitted(pHash);
    }
}