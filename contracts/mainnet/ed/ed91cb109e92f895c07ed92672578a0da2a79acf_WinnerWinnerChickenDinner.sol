//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;


contract WinnerWinnerChickenDinner {
    mapping(address => bool) blacklistedAddresses;
    address owner;

    uint256 public maxSupply = 0;
    uint public totalMinted = 0;
    uint public MS = 0;
    uint public MA = 0;
    uint public MT = 0;
    uint public MG = 0;
    uint public MC = 0;
    uint public MMS = 0;
    uint public MMINT = 0;


    constructor () payable {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "no chicken for you");
        _;
    }

    modifier isBlacklisted(address _address) {
        require(!blacklistedAddresses[_address], "you cooked it to much");
        _;
    }

    function mintAstra() external isBlacklisted(msg.sender){
        require(totalMinted++ < maxSupply, "nonono");
        MA++;
    }

    function mintC() external isBlacklisted(msg.sender){
        require(totalMinted++ < maxSupply, "try again");
        MC++;
    }

    function mintS() external isBlacklisted(msg.sender){
        require(totalMinted++ < maxSupply, "aww maybe next time");
        MS++;
    }

    function startRound(uint256 amount) public onlyOwner{
        maxSupply = maxSupply+amount;
    }

    function mintT() external isBlacklisted(msg.sender){
        require(totalMinted++ < maxSupply, "mmmmmmmmmmm");
        MT++;
    }

    function mintG() external isBlacklisted(msg.sender){
        require(totalMinted++ < maxSupply, "nope");
        MG++;
    }

    function mintMS() external isBlacklisted(msg.sender){
        require(totalMinted++ < maxSupply, "youre too slow");
        MMS++;
    }
    
    function mintMINT() external isBlacklisted(msg.sender){
        require(totalMinted++ < maxSupply, "no no no");
        MMINT++;
    }
    
    function addBlacklist(address[] memory wallets) public onlyOwner {
        for (uint i = 0; i < wallets.length; i++) { 
        blacklistedAddresses[wallets[i]] = true;
    }
    }

    function isBlacklistedCheck(address wallet) public view returns(bool) {
        bool userisBlacklisted = blacklistedAddresses[wallet];
        return userisBlacklisted;
    }
}