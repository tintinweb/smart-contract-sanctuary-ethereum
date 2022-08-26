/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

pragma solidity ^0.8.9;
//只有指定数量的人同意才能交易
contract MultiSigWallet{
     struct Transaction{
        address to;
        uint amount;
        //bytes data;
        bool executed;
        uint confirmCount;
    }
    bool initializeFlag;

    uint public leastConfirmedCount;
    address[] public owners;
    //判断某个address是否为owner之一
    mapping(address=>bool) public ownerMap;
    Transaction[] public transactions;
    //某个index的transaction是否被某个owner确认
    mapping(uint=>mapping(address=>bool)) public txConfirmMap;
    modifier onlyOwner(){
        require(ownerMap[msg.sender],"not owner");
        _;
    }
    modifier txExist(uint index){
        require(index<transactions.length,"tx index out of bount");
        _;
    }
    modifier notConfirmed(uint index){
        require(!txConfirmMap[index][msg.sender],"tx confirmed");
        _;
    }
    modifier notExecuted(uint index){
        require(!transactions[index].executed,"tx is already executed");
        _;
    }
    modifier initialized(){
        require(initializeFlag,"wallet has not been initialized");
        _;
    }

    event depositEvent(address sender,uint amount,uint balance);
    event submitTransactionEvent(address owner,uint index,address to,uint amount);
    event confirmTransactionEvent(address owner,uint txIndex);
    event executeTransactionEvent(address owner,uint txIndex);
    event revokeConfirmationEvent(address owner,uint txIndex);
    event checkOwner(address addr,bool res);
    event checkConfirm(address addr,bool res);

    constructor(){
        //0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
        //0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
        //0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
        //require(_owners.length>0,"owners required");
        //require(confirmRequired>0&&confirmRequired<=_owners.length,"Invalid num of required confirm");
        // address[3] memory _owners=[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
        // 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
        // 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db];
        // uint confirmRequired=2;
        // for(uint i=0;i<_owners.length;i++){
        //     address owner=_owners[i];
        //     //不能有重复的owner
        //     require(owner!=address(0),"owner is invalid");
        //     require(!ownerMap[owner],"owner is duplicated");
        //     owners.push(owner);
        //     ownerMap[owner]=true;
        // }
        // leastConfirmedCount=confirmRequired;
    }
    function initialize(address[] memory signers,uint confirmNeed) external{
        require(!initializeFlag,"wallet has been initialized");
        require(signers.length>0,"owners required");
        require(confirmNeed>0&&confirmNeed<=signers.length,"Invalid num of required confirm,first check");
        initializeFlag=true;
        for(uint i=0;i<signers.length;i++){
            address owner=signers[i];
            //不能有重复的owner
            require(owner!=address(0),"owner is invalid");
            require(!ownerMap[owner],"owner is duplicated");
            owners.push(owner);
            ownerMap[owner]=true;
        }
        require(confirmNeed<=owners.length,"Invalid num of required confirm,second check");
        leastConfirmedCount=confirmNeed;
    }

    //用于收款
    receive() payable external{
        emit depositEvent(msg.sender,msg.value,address(this).balance);
    }
   
    function submitTransaction1(address to,uint amount) initialized onlyOwner public{
        uint index=transactions.length;
        transactions.push(Transaction(to,amount,false,0));         
        emit submitTransactionEvent(msg.sender,index,to,amount);
    }
    function submitTransaction(address to,uint amount) initialized onlyOwner public{
        emit checkOwner(msg.sender, ownerMap[msg.sender]);
        uint index=transactions.length;
        transactions.push(Transaction(to,amount,false,0));         
        emit submitTransactionEvent(msg.sender,index,to,amount);
    }
    function confirmTransaction1(uint txIndex) initialized onlyOwner txExist(txIndex) notConfirmed(txIndex) notExecuted(txIndex)  public{
        Transaction storage tmpTx=transactions[txIndex];
        txConfirmMap[txIndex][msg.sender]=true;
        tmpTx.confirmCount+=1;
        emit confirmTransactionEvent(msg.sender,txIndex);
    }
    function confirmTransaction(uint txIndex) public{
        emit checkConfirm(msg.sender, txConfirmMap[txIndex][msg.sender]);
        Transaction storage tmpTx=transactions[txIndex];
        txConfirmMap[txIndex][msg.sender]=true;
        tmpTx.confirmCount+=1;
        emit confirmTransactionEvent(msg.sender,txIndex);
    }
    function executeTransaction(uint txIndex) initialized onlyOwner txExist(txIndex) notExecuted(txIndex) public{
        Transaction storage tmpTx=transactions[txIndex];
        require(tmpTx.confirmCount>=leastConfirmedCount,"confirm count not enough");
        tmpTx.executed=true;
        (bool success,)=tmpTx.to.call{value:tmpTx.amount}("");
        require(success,"execute fail");
        emit executeTransactionEvent(msg.sender,txIndex);
    }
    function revokeTransaction(uint txIndex) initialized onlyOwner txExist(txIndex) notExecuted(txIndex) public{
        Transaction storage tmpTx=transactions[txIndex];
        require(txConfirmMap[txIndex][msg.sender],"you havent confirm");
        tmpTx.confirmCount-=1;
        txConfirmMap[txIndex][msg.sender]=false;
        emit revokeConfirmationEvent(msg.sender,txIndex);
    }

    function getOwners() public view returns(address[] memory){
        return owners;
    }
    function getOwner(uint index) public view returns(address){
        require(index<owners.length,"index out of bound");
        return owners[index];
    }
    function isOwner(address addr) public view returns(bool){
        return ownerMap[addr];
    }
    function getTransactionCount() public view returns(uint){
        return transactions.length;
    }
    function getTransaction(uint index)  view txExist(index) public returns(address,uint,bool,uint){
        Transaction storage transaction=transactions[index];
        return (transaction.to,transaction.amount,transaction.executed,transaction.confirmCount);
    }
    function getBalance() view public returns(uint){
        return address(this).balance;
    }
}