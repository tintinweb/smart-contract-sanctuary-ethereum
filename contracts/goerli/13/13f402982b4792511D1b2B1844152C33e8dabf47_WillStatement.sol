/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract WillStatement{
    address public immutable owner;
    address public trustedParty;
    address payable[] public familyWallet;

    uint public  assets;
    uint public timeLock;

    bool public paidOut;
    bool public deceased;
    bool public finalized;
    mapping(address => uint) public inheritance;

    modifier onlyOwner(){
        require(msg.sender != address(0) && trustedParty != address(0));
        require(msg.sender == owner || msg.sender == trustedParty);
        _;
    }
    modifier mustBeDeceased(){
        require(deceased == true);
        _;
    }
    modifier notFinalize() {
        require(!finalized, "Inheritance allocations have been finalized, cannot be modified");
        _;
    }
    modifier validAddress(address wallet) {
        require(wallet != address(0), "Invalid Address");
        require(wallet != owner, "Owner can not own Inheritance");
        _;
    }

    constructor() payable {
        require(msg.value > 0, "Send Ether to the contract");
        owner = msg.sender;
        trustedParty = msg.sender;
        assets = msg.value;
    }

    function setInheritance(address payable wallet, uint amount)public onlyOwner notFinalize
    validAddress(wallet)
    {
        require(amount <= assets, "Amount cannot be greater than total assets");
        require(inheritance[wallet] == 0, "This address has an inheritance");
        assets -= amount;
        inheritance[wallet] = amount;
        familyWallet.push(wallet);
    }

    function findAddress(address wallet) private view returns(uint) {
        bool findMember;
        uint indexedMember;
        for(uint i = 0; i < familyWallet.length; i++){
            if(wallet == familyWallet[i]){
                findMember = true;
                indexedMember = i;
                break;
            }
        }
        require(findMember, "Not an member of the wallet");
        return indexedMember;
    }

    function incrementInheritance(address payable wallet, uint amount) payable public onlyOwner 
    notFinalize
    validAddress(wallet) 
    {
        require(amount > 0, "Insufficient Balance");
        require(amount <= assets, "Amount cannot be greater than total assets");
        uint index = findAddress(wallet);
        assets -= amount;
        inheritance[familyWallet[index]] += amount;
    }

    function decrementInheritance(address payable wallet, uint amount) payable public onlyOwner 
    notFinalize
    validAddress(wallet) 
    {
        require(amount > 0, "Insufficient Balance");
        uint index = findAddress(wallet);

        require(amount < inheritance[familyWallet[index]], "Amount > balanceOfWallet");
        assets += amount;
        inheritance[familyWallet[index]] -= amount;
    }

    function removeInheritance(address wallet) public onlyOwner notFinalize
    validAddress(wallet)
    {
        uint index = findAddress(wallet);
        uint bal = inheritance[familyWallet[index]];
        assets += bal;
        inheritance[familyWallet[index]] = 0;
        familyWallet[index] = familyWallet[familyWallet.length - 1];
        familyWallet.pop();
    }

    function finalizeInheritance() public onlyOwner notFinalize {
        require(assets == 0, "Distribute all assets");
        require(familyWallet.length > 0, "Can not finalize an empty array");
        finalized = true;
    }

    function setTimeLock(uint _timeLock) public onlyOwner {
        require(_timeLock > 0);
        timeLock = _timeLock;
    }

    function payOut() private mustBeDeceased {
        require(!paidOut, "Payout has been distrubted");
        require(deceased, "Owner is still alive");
        require(finalized, "Inheritance allocations have not been finalized");
        require(address(this).balance >= assets);
        require(block.timestamp > timeLock);
        for(uint i = 0; i < familyWallet.length; i++){
            familyWallet[i].transfer(inheritance[familyWallet[i]]);
        }
        paidOut = true;
    }

    function setTrustedParty(address _trustedParty) public onlyOwner {
        trustedParty = _trustedParty;
    }

    function isDeceased() payable external onlyOwner {
        deceased = true;
        payOut();
    }

    function getRemainingAssets() external view returns(uint){
        return assets;
    }

    function getTotalAssets() external view returns(uint){
        return address(this).balance;
    }

    receive() payable external {
        require(msg.value > 0, "Insufficient Balance");
        assets += msg.value;
    }
}