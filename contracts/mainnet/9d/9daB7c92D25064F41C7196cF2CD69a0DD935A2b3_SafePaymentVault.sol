/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

/*
This code is the property of CEO Solutions and is not for distribution to the general public.
No responsibility  will be accepted for any unauthorised use of this software and
permission is not granted for its use without authorisation.

DEVOPS: configure to run with KSD Dapp, discuss standards and schema with compliance dept. 
========================================================================================== */
// SPDX-License-Identifier: NONE
pragma solidity ^0.8.15;

contract SafePaymentVault { 
    mapping (address => bytes) public BranchTeamRegistered;
    mapping (address => uint256) public Deposits;

    address public addrThis;    
    address public owner;
    address payable WithdrawalAddress;
    uint256 public MinWeiDeposit;
    uint256 public MinimumAccountFunds;

    bool private CallBranchTeamFunction = true;
    string public RetailSite = "BRANCH0078";
    address public MsgSender;
    address public TXorigin;
    address public MakeDepositMsgSender;

    bytes public BranchTeamName;

    uint256 public TotalBalance;
    bool public RanMakeDeposit;
    uint256 public DepositTotalForOneBranch;
    bool public blnRec = false;

    event DepositMade(address, uint amount);

    enum BranchType {HQ, satellite, Retail, Investment}

    modifier onlyForOwner() {
        require(msg.sender == owner, "Restricted to contract owner");
        _;
    }

    constructor (uint256 _MinWeiDeposit) payable {
        owner =  msg.sender;
        addrThis = address(this);
        WithdrawalAddress = payable(owner);
        MinWeiDeposit = _MinWeiDeposit;
        MinimumAccountFunds = 20000000000000000;
    }

    // --- set minimum deposit
    function SetMinimumDeposit(uint256 _MinWeiDeposit) public onlyForOwner {
        require (_MinWeiDeposit >= 50000000000000000, "value too low");
        MinWeiDeposit = _MinWeiDeposit;
    }

    // --- accept branch deposits
    function MakeDeposit() payable public {
        require (msg.value >= MinWeiDeposit, "deposit is less than minimum");
        Deposits[msg.sender] += msg.value;
        MakeDepositMsgSender = msg.sender;
        RanMakeDeposit = true;
        TotalBalance =  address(this).balance;

        UpdateBranchName();

        emit DepositMade(msg.sender, msg.value);
    }

    // --- update branch name
    function UpdateBranchName() private  {
        // NOTE to devops: won't work if called by contract owner,
        // call from another smart contract
        if (msg.sender != owner){ 
            if (CallBranchTeamFunction) {
                (bool success, bytes memory data) = 
                        MakeDepositMsgSender.delegatecall( abi.encodeWithSignature("BranchTeamName()"));

                BranchTeamRegistered[msg.sender] = data;
                require(success, "external call failed");
            }
        }
        else { //  called by contract owner
//              BranchTeamRegistered[_branch] = _name;
        }
    }

    function GetDepositTotalForOneBranch(address _Branch) public onlyForOwner returns (uint256) {
        DepositTotalForOneBranch = Deposits[_Branch];
        return Deposits[_Branch];
    }

    function ConfirmBranchTeamName(address BranchAddress) public returns (bytes memory) {
        BranchTeamName = BranchTeamRegistered[BranchAddress];
        return BranchTeamName;
    }

    // --- withdraw funds to central clearing
    function Withdraw(uint256 amount) onlyForOwner public payable returns (bool) {
        require(GetTotalBalance() > MinimumAccountFunds, "balance too small for withdrawals");

        require(amount > MinimumAccountFunds, "larger amount should be withdrawn");

        // account must contain minimal amount
        require(amount < GetTotalBalance() - MinimumAccountFunds, "insufficient balance for amount requested");

        (bool blnSent, ) = WithdrawalAddress.call{value: amount}("");
        require (blnSent, "withdrawal unsuccessful");

        TotalBalance =  address(this).balance;

        return blnSent;
    }

    // --- devops: do not run without prior authorisation
    function EmptyAndCloseVault (uint256 ConfirmCode) public payable onlyForOwner {
        // safeguard with param to prevent accidental calling
        require (ConfirmCode == 123456, "must pass 123456 as parameter");
        selfdestruct (payable(owner));
    }

    // --- total fund for all branches
    function GetTotalBalance () public returns (uint256) {
        TotalBalance =  address(this).balance;
        return TotalBalance; //address(this).balance;
    }

    function GetMsgSender() public {
        MsgSender = msg.sender;
    }

    function GetTXorigin() public {
        TXorigin = tx.origin;
    }
}