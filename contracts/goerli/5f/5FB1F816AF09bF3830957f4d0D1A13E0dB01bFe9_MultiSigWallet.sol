// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

contract MultiSigWallet{

    address[] public OwnerAddr;
    mapping(address=>bool) approval;
    mapping(address=>uint) public Owner;
    mapping(address=>uint) public Spend;
    bool internal transactionOn;
    uint public TransactionNo;
    uint votes;
    
    constructor() {

    transactionOn=false;
    votes=0;
    
    TransactionNo=0;

    }
    
    // struct Owner{
    //     address Address;
    //     uint amt;
    // }
    
    struct Transaction{
        address from;
        address payable to;
        uint amount;
        bool approved;
    }

    // Owner[] owners;
    Transaction[] public transactions;

    function deposit() external payable{

        require(msg.value>0,"Depositing zero amount is not allowed");
        
        if(Owner[msg.sender]>0){
            Owner[msg.sender]+=msg.value;
        }
        else{
            require(OwnerAddr.length+1<=3,"No more owners allowed for the wallet.");
            Owner[msg.sender]=msg.value;
            Spend[msg.sender]=0;
            OwnerAddr.push(msg.sender);
            approval[msg.sender]=false;
        }
    }
    
    function getBalance() public view returns(uint) {

        return(address(this).balance);

    }

    modifier isOwner(address _Address){
        require(OwnerAddr.length>0,"Sufficient no of wallet owners not available");
        bool isowner=false;
        
        for(uint i=0; i<OwnerAddr.length; i++){
            if(OwnerAddr[i]==_Address){
                isowner=true;
                break;
            }
            else{
                continue;
            }
        }
        
        require(isowner==true, "Not a owner"); 
        _;
    }



    function doTransaction(address payable transact_dest,uint transact_amount) public isOwner(msg.sender) {

       require(transactionOn==false,"One transaction is already going on");
       transactionOn=true;
       transactions.push(Transaction(msg.sender,transact_dest,transact_amount,false));
       
                 
    }


    function transactioncheck(address _from, address payable _to, uint _amount) internal  returns(bool) {

        if(_amount<getBalance()){
            _to.transfer(_amount);
            Spend[_from]+=_amount;
            transactions[TransactionNo].approved=true;
            return true;
        }
        else{
            return false;
        }
           
    }
    
    function isApproved() public isOwner(msg.sender){
        require(transactionOn==true, "No transaction is going on.");
        require(approval[msg.sender]==false, "You have already approved");
        approval[msg.sender]=true;
        votes++;
        if(votes==OwnerAddr.length){
            if(transactioncheck(transactions[TransactionNo].from,transactions[TransactionNo].to, transactions[TransactionNo].amount)){
                resetApproval();
        }

       } 
        
    }
    
    function resetApproval() private {
        transactionOn=false;
        votes=0;
        TransactionNo++;
        
        for(uint i=0;i<OwnerAddr.length;i++){

            approval[OwnerAddr[i]]=false;

        }

    }

    function leaveWallet() public isOwner(msg.sender){
        require(Owner[msg.sender]>=Spend[msg.sender], "You can only leave when your spend money is less than or equal to deposit money");
        address payable to = payable(msg.sender);
        uint amount = Owner[msg.sender]-Spend[msg.sender];
        to.transfer(amount);
        
        delete Owner[msg.sender];
        delete Spend[msg.sender];
        delete approval[msg.sender];
        for(uint i=0;i<OwnerAddr.length;i++){
            if(OwnerAddr[i]==to){
                delete OwnerAddr[i];
                OwnerAddr[i]=OwnerAddr[OwnerAddr.length-1];
                OwnerAddr.pop();
            }
        }
    }

}