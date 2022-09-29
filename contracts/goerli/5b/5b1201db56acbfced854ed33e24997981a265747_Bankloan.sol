/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Bankloan {

    uint public total = 0;
    LoanTerm[] loanList;
    mapping(uint => LenderTerm[]) lenderListMap;

    mapping(address => uint[]) userLoans;
    mapping(address => uint[]) userLenders;

    struct LoanTerm {
        address issuer;
        uint maxAmount;
        uint rate;
        uint terms;
        uint amount;
        uint payRound;
    }

    struct LenderTerm {
        uint loanId;
        address lender;
        uint amount;
    }

    event NewLoan(uint indexed loanId,address indexed issuer, uint maxAmount, uint rate, uint terms);
    event PrincipalPay(uint indexed loanId,uint amount);
    event PrincipalReceive(address indexed to,uint indexed loanId,uint amount);

    event InterestPay(uint indexed loanId,uint amount, uint payRound);
    event InterestReceive(address indexed to,uint indexed loanId,uint amount,uint payRound);

    constructor() {
    }

    function registerLoan(uint maxAmount, uint rate, uint terms) public returns (uint) {
        LoanTerm memory loan = LoanTerm(msg.sender,maxAmount,rate,terms, 0,0);
        loanList.push(loan);

        total++;
        return total;
    }

    function takeLoan(uint loanId, uint amount) public {
        require(loanId<total,"out_of_index");
        require(amount > 0,"!zero_input");
        LoanTerm storage loan = loanList[loanId];
        uint leftAmount = loan.maxAmount - loan.amount;
        require(amount <= leftAmount,"!out_of_max");

        LenderTerm memory lender = LenderTerm(loanId, msg.sender, amount);
        lenderListMap[loanId].push(lender);
        loan.amount = loan.amount + amount;
        //todo send token
    }

    function makePrincipalPayment(uint loanId) public {
        require(loanId<total,"out_of_index");
        LoanTerm memory loan = loanList[loanId];
        require(loan.payRound == loan.terms,"!Interest_done");
        require(msg.sender == loan.issuer,"!issuer");
        LenderTerm[] memory lenders =  lenderListMap[loanId];
        uint len = lenders.length;
        require(len>0,"no_lender");
        for (uint i = 0; i < len; i++) {
            LenderTerm memory lender = lenders[i];
            //send
            emit PrincipalReceive(lender.lender, loanId, lender.amount);
        }
        emit PrincipalPay(loanId,loan.amount);
    }


    function makeInterestPayment(uint loanId) public {
        require(loanId<total,"out_of_index");
        LoanTerm storage loan = loanList[loanId];
        require(msg.sender == loan.issuer,"!issuer");
        LenderTerm[] memory lenders =  lenderListMap[loanId];
        uint len = lenders.length;
        require(len>0,"no_lender");

        require(loan.payRound == 0,"loanActived");
        require(loan.payRound < loan.terms,"loanClosed");

        uint amount = loan.amount;
        uint principal = amount*loan.rate/10000/loan.terms;
        uint payedPrinc = 0;
        for (uint i = 0; i < len-1; i++) {
            LenderTerm memory lender = lenders[i];
            uint cPrincipal = principal * lender.amount/amount;
            //send
            emit InterestReceive(lender.lender, loanId, cPrincipal,loan.payRound);
            payedPrinc = payedPrinc + cPrincipal;
        }

        LenderTerm memory lastLender = lenders[len-1];
        loan.payRound = loan.payRound +1;
        //send
        emit InterestReceive(lastLender.lender, loanId, principal-payedPrinc,loan.payRound);
        emit InterestPay(loanId,amount,loan.payRound);
    }

    function getLoans() public view returns (LoanTerm[] memory){
        return loanList;
    }


}