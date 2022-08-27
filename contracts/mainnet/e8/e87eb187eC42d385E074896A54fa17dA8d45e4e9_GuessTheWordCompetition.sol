/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

/*
 * @author: Amerjit Zini
 * @revised: 0x3.1.5
 * version 1.1.3
 * all code copyright ZEC STO commission
 * all rights reserved
 * in the event of any issues, no liability is assumed for anyone duplicating this code  

PHASE TWO
allow multiple owners
integrate with SCC DAPP
configure front end in line with DTA guidelines
--------------------------------------------------------------------------------------------- */

// SPDX-License-Identifier: NONE
pragma solidity ^0.8.15;

//======================================
contract WordGuessed {
//======================================
    string private wordtoguess = "VACCINE";
    address owner;

    event winnerfound(string e_wordtoguess, address addrSender, uint256 amount);
    event wrongguess(string e_wordtoguess, address addrSender, uint256 amount);

    constructor () payable {
        owner = msg.sender;    
    }

    // --- Function to compare strings using keccak256
    function equal(string memory p_wordtoguess, address p_addrSender, uint256 p_amount) public returns (bool) {
        bool blnReturn;

        if (keccak256(abi.encode(p_wordtoguess)) == keccak256(abi.encode(wordtoguess))) {
            blnReturn = true;
            emit winnerfound(p_wordtoguess, p_addrSender, p_amount);
        }
        else {
            blnReturn = false;
            emit wrongguess(p_wordtoguess, p_addrSender, p_amount);
        }
        return blnReturn;
    }
}
      
//======================================
contract GuessTheWordCompetition {
//======================================
    address payable public owner;
    address payable private FundBucket;
    address payable private addrThis;
    
    uint256 public StartDate;
    uint256 private FundBalance;
/*    uint256 public FundAtGuess1;
    uint256 public FundAtGuess2;
    uint256 public FundAtGuess3;
    uint256 public FundAtGuess4;*/
    
    uint256 WeiAmountToKeepInAccount = 20000000000000000;
    uint256 public MinimumDonation;

    WordGuessed l_WordGuessed;

    bool public blnCompClosed = false;
    bool private blnInGuessFunction = false;

    struct KeyDetails {
        address payable s_owner;
        address payable s_FundBucket;
        address payable s_addrThis;
    }

    event CompetitionClosed(uint256 uintTimestamp, uint256 uintBalance);

    constructor (uint256 _MinimumDonation, WordGuessed p_WordGuessed) payable { //,  address p_FundBucket) payable {
        require (msg.value >= 10000 wei, "minimum start fund required");
        
        owner = payable(msg.sender);    
        FundBucket = payable(owner);
        MinimumDonation = _MinimumDonation;

        StartDate = block.timestamp;

        l_WordGuessed = WordGuessed(p_WordGuessed);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Restricted to contract owner");
        _;
    }

    function guess(string memory p_guess) payable public returns (bool) {
        uint256 amount = msg.value;
        uint256 Prize;
        bool blnRet = false;

        require (!blnCompClosed, "competition now closed");

        if (msg.sender != owner){
            require (amount >= MinimumDonation, "below the minimum donation for organisations");
        }
        else { // testing phase
            require (amount >= 100000 wei, "minimum not paid");
        }

        require(!blnInGuessFunction, "already processing a guess");

        blnInGuessFunction = true;
//        FundBalance += amount;

        if (l_WordGuessed.equal(p_guess, msg.sender, amount)) { // if correct guess

            // calculate pay out, max 2 times amount
            if (GetBalance() >= 2 * amount) {
                Prize = 2 * amount;
            }
            else {
                Prize = GetBalance();// - 1 finney;
            }
            Prize = Prize - WeiAmountToKeepInAccount;
//            FundBalance -= Prize;
//            aMsgSender = payable(msg.sender);

            bool blnSent = payable (msg.sender).send(Prize);
            require (blnSent, "prize payment unsuccessful");

            blnCompClosed = true;
            blnRet = true;
        } 
        else {
            blnRet = false;
        }

        blnInGuessFunction = false;
        return blnRet;
    }

    function CloseCompetition() onlyOwner public {
        blnCompClosed = true;
        emit CompetitionClosed(block.timestamp, GetBalance());
        selfdestruct(FundBucket);
    }

    function Withdraw(uint256 amount) onlyOwner public returns (bool) {
        require(GetBalance() > WeiAmountToKeepInAccount, "balance too small for withdrawals");

        require(amount > WeiAmountToKeepInAccount, "larger amount should be withdrawn");

        // leave a small amount in account
        require(amount < GetBalance() - WeiAmountToKeepInAccount, "insufficient balance for amount requested");

        (bool blnSent, ) = FundBucket.call{value: amount}("");
        require (blnSent, "withdrawal unsuccessful");
//        FundBalance -= amount;

        return blnSent;
    }

    // --- set minimum deposit
    function SetMinimumDonation(uint256 _MinimumDonation) public onlyOwner {
        require (_MinimumDonation >= 100000000000000000, "a higher _MinimumDonation is needed");
        MinimumDonation = _MinimumDonation;
    }

    // --- show minimum deposit
/*    function GetMinimumDonation() public onlyOwner {
        ShowMinimumDonation = MinimumDonation;
    }
*/
    function GetBalance() view public returns (uint256) {
        return address(this).balance;
    }

    function GetThisBalance() view public returns (uint256) {
        return address(this).balance;
    }

    function GetFundBucket() view public onlyOwner returns (address) {
        return FundBucket;
    }

    function StartNewCompetition() public onlyOwner {
        blnCompClosed = false;
    }

}