/**
 *Submitted for verification at Etherscan.io on 2022-12-22
*/

// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract WhiteList {
    address public owner;
    address[] whitelist;
    uint maxWhiteListedAddresses = 10;
    mapping(address => bool) whitelistedAddresses;

    constructor () {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    function getWhitelistedAddresses() public view returns(address[] memory){
        return whitelist;
    }

    function getWhitelistedAddressNum() public view returns(uint256){
        return whitelist.length;
    }

    function verifyUser(address _addr) public view returns(bool){
        bool result=false;
        for(uint8 i=0; i<whitelist.length; i++ ) {
            if(whitelist[i] == _addr) {
                result=true;
                break;
            }
        }
        return result;
    }

    // Only Owner

    function ChangeWhitelistAmount(uint256 _newAmount) public onlyOwner{
        maxWhiteListedAddresses = _newAmount;
    }

    function addToWhitelistForOwner(address[] memory _addr) public onlyOwner {
        for(uint8 i =0; i<_addr.length;i++){
            whitelist.push(_addr[i]);
        }
        
    }

    function removeFromWhitelistForOwner(address _addr) public onlyOwner {
        for(uint8 i=0; i<whitelist.length; i++ ) {
            if(whitelist[i] == _addr) {
                whitelist[i] = whitelist[whitelist.length -1];
                whitelist.pop;
                break;
            }
        }
        
    }


}