/**
 *Submitted for verification at Etherscan.io on 2022-02-19
*/

// SPDX-License-Identifier: MIT
// contract to manage the Bitgreen-Bridge
// A contract to deposit funds and get Shopping Vouchers of different amount.
pragma solidity ^0.8.11;
contract ShoppingVouchers {
    //Storage Declaration
    // address of the owner of the contract (the one allowed to change the settings)
    address payable public owner;
    // lockdown flag
    bool public lockdown;
     // settings storage
    address [5] keepers;
    address [3] watchdogs;
    // current balance of the deposi
    uint256 public totaldeposit;
     // % of deposit fees (18 decimals)
    uint256 public depositfees;
    // minimum amount of deposit fees (18 decimals)
    uint256 public minimumdepositfees;
    // maximum amount of deposit fees (18 decimals)
    uint256 public maximumdepositfees;
    // balance of withdrawal fees
    uint256 public balancedepositfees;
    /** Allowed only to Owner or Keepers
     * @dev transfer native tokens to a recipient or ERC20
     * @param recipient is a payable address
     * @param amount is a payable amount
     */
    function transfer(address payable recipient, uint amount) public {
        // check for lockdown
        require(lockdown==false,"contract in lockdown, please try later");
        // check for signer not empty
        require(msg.sender!=address(0),"Signer cannot be empty");
        bool execute=false;
        uint8 i;
        // check for owner
        if (msg.sender == owner){
            execute=true;
        }
        // check for keepers
        for(i=0;i<5;i++) {
            if(keepers[i]==msg.sender){
                execute=true;
                break;
            }
        }
        require(execute==true,"Only Keepers account can access this function");
        // check for recipient account
        require(recipient!=address(0),"Recipient cannot be empty");
        // check for amount
        require(amount>0,"Amount cannot be zero");
        uint256 wdf=0;
        if(depositfees>0){
            wdf=amount*depositfees/100000000000000000000;
            if (wdf<minimumdepositfees && minimumdepositfees>0) {
                wdf=minimumdepositfees;
            }
            if (wdf>maximumdepositfees && maximumdepositfees>0) {
                wdf=maximumdepositfees;
            }
            //increase the total deposit fees
            balancedepositfees=balancedepositfees+wdf;
        }
        // native token transfer
        (bool success, ) =recipient.call{value: amount}("");
        require(success, "Failed to send native tokens");
    }

    // set the owner to the creator of the contract, ownership can be changed calling transferOwnership()
    constructor() payable {
          owner = payable(msg.sender);
          lockdown=false;
    }
    /**
     * @dev set lockdown of the operation, enabled for watchdogs and owner
     */
    function setLockdown() public {
        bool execute=false;
        // check for owner
        if (msg.sender == owner){
            execute=true;
        }
        uint8 i;
        // check for watchdogs
        for(i=0;i<3;i++) {
            if(watchdogs[i]==msg.sender){
                execute=true;
            }
        }
        require(execute==true,"Function accessible only to owner or watchdogs");
        lockdown=true;
    }
    /**
     * @dev unset lockdown of the operation, enabled for owner only
     */
    function unsetLockdown() public {
        // check for owner
        require (msg.sender == owner,"Function accessible only to owner");
        // unset the lockdown 
        lockdown=false;
    }
    /**
     * @dev return the status of the lookdown true/false
     */
    function getLockdown() public view returns(bool){
        return lockdown;
    }
    // functiont to receive deposit of native token
    function deposit() payable public {
        totaldeposit+=msg.value;
    }
    fallback() external payable {
        totaldeposit+=msg.value;
    }
    receive() external payable {
        totaldeposit+=msg.value;
    }
    //function to return the balance
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    /**
     * @dev transfer ownership
     * @param newOwner is the address wished as new owner
     */
    function transferOwnership(address payable newOwner) public {
        require(msg.sender == owner);
        require(lockdown==false,"contract in lockdown, please try later");
        owner = newOwner;
    }
    /**
     * @dev store configuration of the  withdrawal fees
     * @param Depositfees are the % fees computed on the deposit
     */
    function setDepositFees(uint256 Depositfees) public {
        require(msg.sender == owner,"Function accessible only to owner");
        depositfees=Depositfees;
    }
    /**
     * @dev store configuration of the minimum withdrawal fees
     * @param Minimumdepositfees is the minimum amount of deposit fees
     */
    function setMinimumWDepositFees(uint256 Minimumdepositfees) public {
        require(msg.sender == owner,"Function accessible only to owner");
        minimumdepositfees=Minimumdepositfees;
    }
    /** 
     * @dev store configuration of the maximum withdrawal fees
     * @param Maximumdepositfees is the maximum allowed to be ketp as deposit fees
     */
    function setMaxmimumDepositFees(uint256 Maximumdepositfees) public {
        require(msg.sender == owner,"Function accessible only to owner");
        maximumdepositfees=Maximumdepositfees;
    }
}