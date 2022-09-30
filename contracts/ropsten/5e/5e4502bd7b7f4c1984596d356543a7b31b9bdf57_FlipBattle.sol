/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;


//they lucky eslamaio aint in this omm
contract FlipBattle {
    mapping(address => bool) whitelistedAddresses;
    bool isActive;
    address owner;
    uint256 public maxSupply = 10;
    uint public totalMinted = 0;
    uint public astraMinted = 0;
    uint public thunderMinted = 0;
    uint public grabberMinted = 0;
    string public symbol;
    string public name;


    constructor () payable {
        symbol = "FLIP";
        name = "Flip Battle";
        isActive = false;
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

    function astra() external payable isWhitelisted(msg.sender){
        require(isActive, "sale not started yet bud");
        require(totalMinted++ < maxSupply, "youre too slow");
        astraMinted++;
        totalMinted++;
    }

    function thunder() external payable isWhitelisted(msg.sender){
        require(isActive, "sale not started yet bud");
        require(totalMinted++ < maxSupply, "youre too slow");
        thunderMinted++;
        totalMinted++;
    }

    function grabber() external payable isWhitelisted(msg.sender){
        require(isActive, "sale not started yet bud");
        require(totalMinted++ < maxSupply, "youre too slow");
        grabberMinted++;
        totalMinted++;
    }
    
    function addUser(address[] memory wallets) public onlyOwner {
        for (uint i = 0; i < wallets.length; i++) { 
        whitelistedAddresses[wallets[i]] = true;
    }
    }

    function setmaxSupply(uint256 _supply) public onlyOwner() {
        maxSupply = _supply;
    }

    function isTester(address wallet) public view returns(bool) {
        bool userIsWhitelisted = whitelistedAddresses[wallet];
        return userIsWhitelisted;
    }

    function toggleSale (bool status) external onlyOwner{
        isActive = status;
    }
}