/**
 *Submitted for verification at Etherscan.io on 2023-05-26
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Whitelist {
    address owner;
    uint256 lastRun;
    uint256 public totalSupply;
    event WhiteListed(address _addressToWhitelist);
    event Claimed(uint amount, address _ClaimedBy);

    constructor() {
        owner = msg.sender;
        whitelistedAddresses[owner] = true;
      }

    mapping(address => bool) public whitelistedAddresses;
    mapping (address => uint256) public _balances;

    function addUser(address _addressToWhitelist) public onlyOwner {
        require(whitelistedAddresses[_addressToWhitelist] == false,"Address already Whitelisted");
        whitelistedAddresses[_addressToWhitelist] = true;
        emit WhiteListed( _addressToWhitelist);  
    }

    function claimtokens( address _user) public OnlyWhitelisted{
        //require(block.timestamp - lastRun > 1 minutes, "wait for 1 min");
        _balances[_user] += 1 ether;
        totalSupply += 1 ether;
        lastRun = block.timestamp;
        emit Claimed(1 ether,_user);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the ownerr");
        _;
    }

    modifier OnlyWhitelisted() {
        require( whitelistedAddresses[msg.sender],"user is not whitelisted");
        _;
    }
    
}