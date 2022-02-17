/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// File: https://github.com/giupt/BIMvalidation/blob/main/Ownable.sol

pragma solidity ^0.4.17;

//@title Ownable
//@dev The Ownable contract has an owner address, and provides basic authorization control
//functions, this simplifies the implementation of "user permissions"

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

//@dev The Ownable constructor sets the original `owner` of the contract to the sender

    constructor() public {
        owner = msg.sender;
    }


//@dev Throws if called by any account other than the owner
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


//@dev Allows the current owner to transfer control of the contract to a newOwner
//@param newOwner The address to transfer ownership to
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// File: IPFSupload.sol

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.4.17;


contract IPFSupload is Ownable {
    string public file = "IPFS_hash";
    

    uint public myUint; //number of delivery of the same type of file

    
    function setMyUint(uint _myUint) public {
        myUint = _myUint;
    }
    
    
    function setIPFShash(string memory _file) public { 
    file = _file;
    }
    
}