/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

pragma solidity >=0.5.0 <0.7.0;


// Defines that a contract that is owned by the deployer, a modifier to be use
// downstream, and a function to get the owner.
contract Owned {
    address payable owner;

    constructor() public {
        owner = msg.sender;
    }

    // Get the owner of the contract.
    function getOwner() public view returns (address) {
        return owner;
    }

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function."
        );
        _;
    }
}