/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

pragma solidity ^0.4.23;

contract NewImplementation {
    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor(address _owner) public {
        owner = _owner;
    }

    function withdrawTrappedEther() public onlyOwner {
        owner.transfer(address(this).balance);
    }
}