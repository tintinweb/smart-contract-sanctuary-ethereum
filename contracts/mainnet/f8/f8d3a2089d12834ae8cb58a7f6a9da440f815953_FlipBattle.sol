/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

//they lucky eslamaio aint in this omm or we takin all stock
contract FlipBattle {
    mapping(address => bool) blacklistedAddresses;
    address owner;

    uint256 public maxSupply = 0;
    uint public totalMinted = 0;
    uint public mintedAstra = 0;
    uint public mintedThunder = 0;
    uint public mintedGrabber = 0;
    uint public mintedCustom = 0;
    uint public mintedSensei = 0;
    uint public mintedMS = 0;
    uint public mintedMintech = 0;


    constructor () payable {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "it seems you are not eslam");
        _;
    }

    modifier isBlacklisted(address _address) {
        require(!blacklistedAddresses[_address], "not allowed to test");
        _;
    }

    function mintAstra() external isBlacklisted(msg.sender){
        require(totalMinted++ < maxSupply, "youre too slow");
        mintedAstra++;
    }

    function mintCustom() external isBlacklisted(msg.sender){
        require(totalMinted++ < maxSupply, "youre too slow");
        mintedCustom++;
    }

    function mintSensei() external isBlacklisted(msg.sender){
        require(totalMinted++ < maxSupply, "youre too slow");
        mintedSensei++;
    }

    function startRound() public onlyOwner{
        maxSupply = maxSupply+10;
    }


    function mintThunder() external isBlacklisted(msg.sender){
        require(totalMinted++ < maxSupply, "youre too slow");
        mintedThunder++;
    }

    function mintGrabber() external isBlacklisted(msg.sender){
        require(totalMinted++ < maxSupply, "youre too slow");
        mintedGrabber++;
    }

    function mintMS() external isBlacklisted(msg.sender){
        require(totalMinted++ < maxSupply, "youre too slow");
        mintedMS++;
    }
    
    function mintMintech() external isBlacklisted(msg.sender){
        require(totalMinted++ < maxSupply, "youre too slow");
        mintedMintech++;
    }
    
    function addBadPeople(address[] memory wallets) public onlyOwner {
        for (uint i = 0; i < wallets.length; i++) { 
        blacklistedAddresses[wallets[i]] = true;
    }
    }

    function isBadPerson(address wallet) public view returns(bool) {
        bool userisBlacklisted = blacklistedAddresses[wallet];
        return userisBlacklisted;
    }
}