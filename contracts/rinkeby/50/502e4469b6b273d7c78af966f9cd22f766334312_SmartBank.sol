/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SmartBank
{

    mapping (address => bool) Registered; 
    mapping (address => uint) private AccountBalance;
    mapping (address => uint) withdrawlog;

    address owner;
    uint withdrawFee = 0.01 ether;
    uint duedate = (259200)/60/60/24;

    struct loan{
        uint LoanAmount;
        uint loanbalance;
        uint timeOfLoanTaking;
        uint timeOfLoanpayment;
        uint collateral;
    }   

    mapping(address => loan) public BorrowerDetails;

    modifier isValidAddress{
        require(msg.sender != address(0),"Invalid Address");
        _;
    }

    modifier isRegistered(){
        require(!Registered[msg.sender],"already registered");
        _;
    }

    modifier isOwner(){
            require((msg.sender == owner),"only owner can modify the Withdraw fee");
            _;
        }

    modifier isRequiredWithdrawFee(uint amountWithdrawn){
            require((amountWithdrawn >= withdrawFee),"amount must include Withdraw fee as required");
            _;
        }
    
    modifier isNotRegistered(){
            require(Registered[msg.sender],"Not registered");
            _;
        }

    event loanApproved(
            address Borrower
        );

    event liquidated(
            address liquidatedAddress
        );

    
    constructor(){
        owner = msg.sender;
       
        }


  
    function ModifyWithdrawFee(uint ChangedFee) external isOwner {
        withdrawFee = ChangedFee;
    }


    function Modifyduedate(uint Changedduedate) external isOwner {
        duedate = Changedduedate;
    }


    function register() external isRegistered isValidAddress {
        Registered[msg.sender]= true;
    }


    modifier isEligibleForLoan() {
        require((BorrowerDetails[msg.sender].loanbalance==0),"not eligible for loan");
        emit loanApproved(msg.sender);
        _;
    }

    function deposit() public isNotRegistered payable {
        require(msg.value>0, "Value for deposit is Zero");
        AccountBalance[msg.sender] += msg.value;
    }
    
    modifier isminBalance(){
        require(AccountBalance[msg.sender]>= BorrowerDetails[msg.sender].collateral, "you are not eligible for withdrawl");
        _;
    }

    // modifier hasBeen1week(){
    //     require(withdrawlog[msg.sender]-(block.timestamp/60/60/24) <= 7, "");
    //     _;
    // }


    function withdraw(uint withdrawAmount) public payable 
    
    isNotRegistered 
    isminBalance  
    isRequiredWithdrawFee(withdrawAmount)  
    
    returns (uint remainingBal) {
    
        require(withdrawAmount>0, "Enter non-zero value for withdrawal");
        // if(withdrawlog[msg.sender]-(block.timestamp/60/60/24) <= 7)
        
        if ((withdrawAmount)<= AccountBalance[msg.sender]) {
            payable(msg.sender).transfer(withdrawAmount);
            AccountBalance[msg.sender] -= withdrawAmount ;
            withdrawlog[msg.sender]=block.timestamp/60/60/24;
        }
        //lenders intrest
        uint inactiveTime=withdrawlog[msg.sender]-(block.timestamp/60/60/24);
        if(inactiveTime >= 7 && (AccountBalance[msg.sender]> 0))
        {
           AccountBalance[msg.sender] += (AccountBalance[msg.sender] *8* inactiveTime)/100;
        }
        return AccountBalance[msg.sender];
    }

    //to get account balance of user
    function getAccountbalance() public view isNotRegistered returns (uint) {
        return AccountBalance[msg.sender];
    }

    //to close account
    function close() public isNotRegistered
    {
        uint remainingBal = AccountBalance[msg.sender];
        payable(msg.sender).transfer(remainingBal);
        delete Registered[msg.sender];
        delete AccountBalance[msg.sender];
    
    }

    //to take loan
    function takeloan(uint LoanAmt) public isNotRegistered isEligibleForLoan
    {  
        require(LoanAmt< 0.05 ether,"the limit is 0.05 ETH");
        uint collateral = LoanAmt + ((LoanAmt *12* duedate )/100); 
        require(AccountBalance[msg.sender]>= collateral, " balance not enough");
        loan memory user = loan(
                                    LoanAmt,
                                    collateral,
                                    block.timestamp,
                                    0,
                                    collateral         );

        
        BorrowerDetails[msg.sender] = user;
        payable(msg.sender).transfer( LoanAmt );
       
    }

   //to check liquidate by the owner
    function liquidation(address toLiquidate) public isOwner 
    {
        require(BorrowerDetails[toLiquidate].loanbalance == 0,
        "User has not taken any previous Loan"
        );

    if (BorrowerDetails[toLiquidate].timeOfLoanTaking + duedate >= block.timestamp)
        {
           
            //to liquidate
            uint timeleft= BorrowerDetails[toLiquidate].timeOfLoanTaking + duedate - block.timestamp;
            uint SI=((BorrowerDetails[toLiquidate].loanbalance *12* timeleft)/100);
            if(BorrowerDetails[toLiquidate].timeOfLoanTaking + duedate == block.timestamp)
            {
                AccountBalance[toLiquidate]=BorrowerDetails[toLiquidate].loanbalance;
            }
            AccountBalance[toLiquidate]-= BorrowerDetails[toLiquidate].loanbalance + SI ;
            
        }
        emit liquidated(toLiquidate);

}
    // modifier canbeliquidated() 
    //     {
    //         require(BorrowerDetails[msg.sender].timeOfLoanTaking + duedate>= block.timestamp,"time limit exceeded");
    //         _;
    //     }
    
    //to pay loan
    function loanPay()
    
     public
     payable

     isNotRegistered
     

    {  
            require(
            BorrowerDetails[msg.sender].loanbalance > 0, 
            "No loan amount to clear"
        );
        
        require(
            !(msg.value ==0),
            "Enter valid Amount"
            );

        require(
            msg.value >= BorrowerDetails[msg.sender].loanbalance,
            "amount Entered is larger than loanAmount"
            );
       
 

        BorrowerDetails[msg.sender].timeOfLoanpayment=block.timestamp;
        uint time =( block.timestamp - BorrowerDetails[msg.sender].timeOfLoanTaking)/60/60/24;
        uint SI=((msg.value *12* time)/100);
        BorrowerDetails[msg.sender].loanbalance -= (msg.value - SI) ;
    }

    //to get contract balance
    function getContractBalance() external view isNotRegistered returns(uint)
    {
        return address(this).balance;
    }
}