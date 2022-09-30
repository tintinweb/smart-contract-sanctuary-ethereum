/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

//they lucky eslamaio aint in this omm or we takin all stock
contract FlipBattle {
    mapping(address => bool) whitelistedAddresses;
    address owner;
    uint256 public maxSupply = 0;
    uint public totalMinted = 0;
    uint public mintedAstra = 0;
    uint public mintedThunder = 0;
    uint public mintedGrabber = 0;
    uint public mintedCustom = 0;

    constructor () payable {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "it seems you are not eslam");
        _;
    }

    modifier isWhitelisted(address _address) {
        require(whitelistedAddresses[_address], "not allowed to test");
        _;
    }

    function mintAstra() external isWhitelisted(msg.sender){
        require(totalMinted++ < maxSupply, "youre too slow");
        mintedAstra++;
    }

    function mintCustom() external isWhitelisted(msg.sender){
        require(totalMinted++ < maxSupply, "youre too slow");
        mintedCustom++;
    }


    function mintThunder() external isWhitelisted(msg.sender){
        require(totalMinted++ < maxSupply, "youre too slow");
        mintedThunder++;
    }

    function mintGrabber() external isWhitelisted(msg.sender){
        require(totalMinted++ < maxSupply, "youre too slow");
        mintedGrabber++;
    }
    
    function addTesters(address[] memory wallets) public onlyOwner {
        for (uint i = 0; i < wallets.length; i++) { 
        whitelistedAddresses[wallets[i]] = true;
    }
    }

    function setSupply(uint256 _supply) public onlyOwner{
        maxSupply = _supply;
    }

    function isTester(address wallet) public view returns(bool) {
        bool userIsWhitelisted = whitelistedAddresses[wallet];
        return userIsWhitelisted;
    }
}