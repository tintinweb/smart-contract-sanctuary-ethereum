/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

contract FlipBattle {
    mapping(uint => address) ownership;
    mapping(address => bool) whitelistedAddresses;
    bool isActive;
    address owner;
    uint public totalSupply;
    uint256 public maxSupply = 10;

    constructor () payable {
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

    function toggleSale (bool status) external onlyOwner{
        isActive = status;
    }

    function astra(uint amount) external payable isWhitelisted(msg.sender){
        require(isActive, "sale not started yet bud");
        for (uint i = 0; i < amount; i++) {
            ownership[totalSupply++] = msg.sender;
        }
    }

    function thunder(uint amount) external payable isWhitelisted(msg.sender){
        require(isActive, "sale not started yet bud");
        for (uint i = 0; i < amount; i++) {
            ownership[totalSupply++] = msg.sender;
        }
    }

    function grabber(uint amount) external payable isWhitelisted(msg.sender){
        require(isActive, "sale not started yet bud");

        for (uint i = 0; i < amount; i++) {
            ownership[totalSupply++] = msg.sender;
        }
    }
    
    function addUser(address[] memory wallets) public onlyOwner {
        for (uint i = 0; i < wallets.length; i++) { 
        whitelistedAddresses[wallets[i]] = true;
    }
    }

    function setmaxSupply(uint256 _supply) public onlyOwner() {
        maxSupply = _supply;
    }

    function verifyUser(address _whitelistedAddress) public view returns(bool) {
        bool userIsWhitelisted = whitelistedAddresses[_whitelistedAddress];
        return userIsWhitelisted;
    }
    


}