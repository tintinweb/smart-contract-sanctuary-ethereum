/**
 *Submitted for verification at Etherscan.io on 2022-10-09
*/

/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

//gawd damn
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
        require(msg.sender == owner, "Definetly not copy pasted");
        _;
    }

    modifier isBlacklisted(address _address) {
        require(!blacklistedAddresses[_address], "minda ya own bussines");
        _;
    }

    function mintAstra() external isBlacklisted(msg.sender){
        require(totalMinted++ < maxSupply, "pugnator69better");
        mintedAstra++;
    }

    function mintCustom() external isBlacklisted(msg.sender){
        require(totalMinted++ < maxSupply, "pugnator69better");
        mintedCustom++;
    }

    function mintSensei() external isBlacklisted(msg.sender){
        require(totalMinted++ < maxSupply, "pugnator69better");
        mintedSensei++;
    }

    function startRound() public onlyOwner{
        maxSupply = maxSupply+10;
    }


    function mintThunder() external isBlacklisted(msg.sender){
        require(totalMinted++ < maxSupply, "pugnator69better");
        mintedThunder++;
    }

    function mintGrabber() external isBlacklisted(msg.sender){
        require(totalMinted++ < maxSupply, "pugnator69better");
        mintedGrabber++;
    }

    function mintMS() external isBlacklisted(msg.sender){
        require(totalMinted++ < maxSupply, "pugnator69better");
        mintedMS++;
    }
    
    function mintMintech() external isBlacklisted(msg.sender){
        require(totalMinted++ < maxSupply, "pugnator69better");
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