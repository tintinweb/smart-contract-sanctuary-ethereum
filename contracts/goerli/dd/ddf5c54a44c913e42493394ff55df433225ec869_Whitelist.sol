/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

pragma solidity 0.6.1;

contract Transfernewowner {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  
   // Sets the new owner of the NFT if valid
   
  constructor() public{
    owner = msg.sender;
  }
   
   // Validates that the new owner is the rightful owner according to the whitelist
   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
   // Transfers ownership to a new owner
    
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract Whitelist is Transfernewowner {
    mapping(address => bool) whitelist;
    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    // Function to add accounts to whitelist

    function add(address _address) public onlyOwner {
        whitelist[_address] = true;
        emit AddedToWhitelist(_address);
    }

    // Function to remove accounts from whitelist

    function remove(address _address) public onlyOwner {
        whitelist[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

   // Function to check whether account is on the whitelist

    function isWhitelisted(address _address) public view returns(bool) {
        return whitelist[_address];
    }
}