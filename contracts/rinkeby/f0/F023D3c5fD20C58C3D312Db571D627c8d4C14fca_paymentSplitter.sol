// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract paymentSplitter{
    address private admin;
    address[] private recievers;

    uint256 public Ethtotal;
    uint256 public Ethsent;

    mapping(address=> uint) private shares;
    mapping (address => mapping (uint => bool)) public sharesPaid;
    mapping (address => bool) public sharesExisting;


    event SharesAdded(uint share, address indexed Collector);
    event SharesUpdated(uint oldshare,uint256 newShare, address indexed collector);
    event Paid(address indexed collector, uint share);
    event Deposited(address indexed depositor, uint amount);
    event PaymentReset(address indexed collector, uint256 amount);
    event shareRemoved(address indexed collector, uint256 amount);


    constructor(){
        admin = payable(msg.sender);
    }   


    receive() external payable{
        Ethtotal += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    fallback() external payable{
         Ethtotal += msg.value;
        emit Deposited(msg.sender, msg.value);
    }


    modifier onlyAdmin{
        require(admin == msg.sender, "You are not the admin");
        _;
    }

    modifier enoughShares(uint amount){
        require(amount * 10000/10000 == amount , "the basis points is too small");
        require(amount <= 10000, "The share is more than 100 Percent");
        _;
    }

    modifier notAddresszero(address collector){
        require(collector != address(0), "Not a valid address");
        _;
    }

    modifier hasPayment(address collector){
        require(shares[collector] != 0, "This account has no balance");
        _;
    }

    modifier alreadyFalse(address collector){
        require(sharesPaid[collector][shares[collector]], "The payment has alredy been set to false");
        _;
    }

    modifier alreadyPaid(address collector){
        require(!sharesPaid[collector][shares[collector]],"This address has already been paid, reset to pay again");
        _;
    
    }

    modifier existingShares(address collector){
        require(!sharesExisting[collector],"Adress already has a percentage, Update instead");
        _;
    }


    function addShare(address collector, uint256 share) external
    onlyAdmin 
    enoughShares(share) 
    notAddresszero(collector) 
    existingShares(collector){

        shares[collector] = share * address(this).balance/10000;
        recievers.push(collector);
        sharesExisting[collector] = true;

        emit SharesAdded(share, collector);

    }


    function getShare(address collector) external view returns(uint){
        return shares[collector];
    }


    function removeShare(address collector) public onlyAdmin{
        uint256 oldshare = shares[collector];
        delete shares[collector];
        emit shareRemoved(collector, oldshare);
    }


    function updateShare(address collector, uint256 share) public onlyAdmin{
        uint oldshare = shares[collector];
        removeShare(collector);

        shares[collector] = share * address(this).balance/10000;

        uint256 newshare = shares[collector];

        emit SharesUpdated(oldshare, newshare, collector);
    }


    function getBalance() external view returns(uint){
        return address(this).balance;
    }


    function payment(address payable collector) external payable 
    onlyAdmin 
    hasPayment(collector) 
    alreadyPaid(collector){

        require(shares[collector] <= address(this).balance);
        uint256 debit = shares[collector];
        

        require(address(this).balance >= debit, "Address: insufficient balance");

        (bool success, ) = collector.call{value: debit}("");
        require(success, "Address: unable to send value, recipient may have reverted");

        sharesPaid[collector][debit] = true;
        
        Ethsent +=debit;

        emit Paid(collector, debit);
    }


    function resetPayment(address collector, uint amount) external 
    onlyAdmin 
    alreadyFalse(collector){ 

        sharesPaid[collector][shares[collector]] = false;

        updateShare(collector, amount);
        emit PaymentReset(collector, shares[collector]);
    }
    


}