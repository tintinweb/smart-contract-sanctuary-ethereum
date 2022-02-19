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
     * @param erc20 is the address of the erc20 contract (optional)
     */
    function transfer(address payable recipient, uint amount,address payable erc20) public {
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
        // native token
        if(erc20==address(0)){
            (bool success, ) =recipient.call{value: amount}("");
            require(success, "Failed to send native tokens");
        }else {
            // erc20 token
            IERC20(erc20).transferFrom(address(this), recipient, amount);
        }
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
    function deposit(uint256 amount) payable public {
        require(msg.value == amount);
        totaldeposit+=msg.value;
    }
    fallback() external payable {
        totaldeposit+=msg.value;
    }
    receive() external payable {
        totaldeposit+=msg.value;
    }
    //function to send back the balance
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
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}