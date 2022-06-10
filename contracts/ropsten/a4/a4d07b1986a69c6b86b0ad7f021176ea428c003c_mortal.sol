/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

pragma solidity ^0.4.22;

contract owned {
    address owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the ownder of the contract can call this");
    _;
    }
}

contract mortal is owned {
    function destroy() public onlyOwner {
        selfdestruct(owner);
    }
}