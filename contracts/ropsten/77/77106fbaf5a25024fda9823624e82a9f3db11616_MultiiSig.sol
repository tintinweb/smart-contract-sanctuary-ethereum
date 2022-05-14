/**
 *Submitted for verification at Etherscan.io on 2022-05-14
*/

// File: multisig.sol

pragma solidity 0.8.7;

contract MultiiSig {
    
    address mainOwner;
    address[] walletowners;
    uint limit;
    uint depositId = 0;
    uint withdrawalId = 0;
   
    
    constructor() {
        
        mainOwner = msg.sender;
        walletowners.push(mainOwner);
        limit = walletowners.length - 1;
    }
    
    mapping(address => uint) balance;
   
    
    
    event walletOwnerAdded(address addedBy, address ownerAdded, uint timeOfTransaction);
    event walletOwnerRemoved(address removedBy, address ownerRemoved, uint timeOfTransaction);
    event fundsDeposited(address sender, uint amount, uint depositId, uint timeOfTransaction);
    event fundsWithdrawed(address sender, uint amount, uint withdrawalId, uint timeOfTransaction);
    
    modifier onlyowners() {
        
       bool isOwner = false;
       for (uint i = 0; i< walletowners.length; i++) {
           
           if (walletowners[i] == msg.sender) {
               
               isOwner = true;
               break;
           }
       }
       
       require(isOwner == true, "only wallet owners can call this function");
       _;
        
    }
   
    
    function addWalletOwner(address owner) public onlyowners {
        
        
       for (uint i = 0; i < walletowners.length; i++) {
           
           if(walletowners[i] == owner) {
               
               revert("cannot add duplicate owners");
           }
       }
        
        walletowners.push(owner);
        limit = walletowners.length - 1;
        
        emit walletOwnerAdded(msg.sender, owner, block.timestamp);
    }
    
    
    function removeWalletOwner(address owner) public onlyowners {
        
        bool hasBeenFound = false;
        uint ownerIndex;
        for (uint i = 0; i < walletowners.length; i++) {
            
            if(walletowners[i] == owner) {
                
                hasBeenFound = true;
                ownerIndex = i;
                break;
            }
        }
        
        require(hasBeenFound == true, "wallet owner not detected");
        
        walletowners[ownerIndex] = walletowners[walletowners.length - 1];
        walletowners.pop();
        limit = walletowners.length - 1;
        
         emit walletOwnerRemoved(msg.sender, owner, block.timestamp);
       
    }
    
    function deposit() public payable onlyowners {
        
        require(balance[msg.sender] >= 0, "cannot deposiit a calue of 0");
        
        balance[msg.sender] = msg.value;
        
        emit fundsDeposited(msg.sender, msg.value, depositId, block.timestamp);
        depositId++;
        
    } 
    
    function withdraw(uint amount) public onlyowners {
        
        require(balance[msg.sender] >= amount);
        
        balance[msg.sender] -= amount;
        
        payable(msg.sender).transfer(amount);
        
        emit fundsWithdrawed(msg.sender, amount, withdrawalId, block.timestamp);
         withdrawalId++;
        
    }
    
    function getWalletOners() public view returns(address[] memory) {
        
        return walletowners;
    }
    
    
    function getBalance() public view returns(uint) {
        
        return balance[msg.sender];
    }
    
    
    
     function getContractBalance() public view returns(uint) {
        
        return address(this).balance;
    }
    
   
    
    
}