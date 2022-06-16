//SPDX-License-Identifier:UNLICENSED
/*
SafeSend V2
Decentralized Simple Payment Service
Compiler Version: 0.8.14
*/

pragma solidity ^0.8.0;

import "abc.sol";

contract safesend is abc {

    uint256 public mode=2; // 0:disabled; 1:claim only; 2:create and claim;
    
    uint256 public fee=0.0006 ether; // to be split between owner and maintainer (creator)

    uint256 public minParentBal=1000000000; // 100,000 +4 decimals; for zero fees

    mapping(address => uint256) public balances; // for revenue only

    uint256 public totalRevenue=0; // BNB

    address public PARENT_CA=0xa5Ea2F2578D03333cb49e5e06238e2B04a9776c3; // specified by owner

    struct envelope{
        uint256 status; // 0:cancelled; 1:holding; 2:claimed/released;
        address sender;
        address receiver;
        address token;
        uint256 amount;
        uint256 claimableAmount;
        uint256 created;
        uint256 holdTimeSec;
        uint256 closed;
    }

    uint256 public txcount=1000;

    mapping(address => bool) public feeWhitelisted;

    mapping(address => uint256[]) public userTxns;

    mapping(uint256 => envelope) public envelopes;

    mapping(address => mapping(uint256 => uint256)) public frontendStatus;

    constructor() {
        address _owner=0x1884377d1FeB3d3089884cE0947C2bf1675bf052; // owner specified
        setOriginalOwner(_owner);
        feeWhitelisted[_owner]=true;
        feeWhitelisted[msg.sender]=true;
    }

    ////////////////////////////////////////////////////////////////////////////////////

    // ADMIN FUNCTIONS

    function setMode(uint256 _mode) external adminOnly {
        mode=_mode;
    }

    function setFee(uint256 _fee) external adminOnly {
        fee=_fee;
    }

    function setMinParentBal(uint256 _minParentBal) external adminOnly {
        minParentBal=_minParentBal;
    }

    function setPARENT_CA(address _PARENT_CA) external adminOnly {
        PARENT_CA=_PARENT_CA;
    }

    function addToFeeWhitelist(address _account) external adminOnly {
        feeWhitelisted[_account]=true;
    }

    function removeFromFeeWhitelist(address _account) external adminOnly {
        feeWhitelisted[_account]=false;
    }

    ////////////////////////////////////////////////////////////////////////////////////

    // CORE FUNCTIONS

    function sendEnvelope(address receiver,address token,uint256 amount,uint256 holdTimeSec,uint256 frontendID) external payable{
        // check mode
        require(mode==2,"System is paused.");

        // get a new txid
        txcount=math.add(txcount,1);
        uint256 txid=txcount;

        // re-entrancy guard
        require(frontendStatus[msg.sender][frontendID]==0,"Transaction already executed once.");
        frontendStatus[msg.sender][frontendID]=txid; // after this line re-entry will fail at previous line

        // determine fee
        uint256 finalFee=fee;
        if(PARENT_CA!=address(0x0)){
            if(IERC20(PARENT_CA).balanceOf(msg.sender)>=minParentBal){
                finalFee=math.div(fee,2);
            }
        }

        if(feeWhitelisted[msg.sender]){
            finalFee=0;
        }

        if(finalFee>0){
            uint256 feeShare=math.div(finalFee,2);
            balances[ownerAddress]=math.add(balances[ownerAddress],feeShare);
            balances[creatorAddress]=math.add(balances[creatorAddress],feeShare);
            totalRevenue=math.add(totalRevenue,finalFee);
        }

        // to send ETH supply the contract's own address as token
        bool isETH=token==address(this)?true:false;

        // Sending ETH
        if(isETH){
            require(msg.value==amount+finalFee,"Insufficient value"); // fee and amount must be paid
        }

        // Sending Tokens
        if(!isETH){
            require(msg.value==finalFee,"Insufficient fee"); // fee must be paid
            require(IERC20(token).allowance(msg.sender,address(this))>=amount,"Insufficient allowance"); // must have sufficient allowance
            require(IERC20(token).balanceOf(msg.sender)>=amount,"Insufficient balance"); // must have sufficient token balance
        }

        // transfer the token amount to this contract
        if(!isETH){
            require(IERC20(token).transferFrom(msg.sender,address(this),amount),"Transfer failed.");
        }
       
        // create the envelope
        /*
            IMPORTANT AUDIT NOTE REGARDING block.timestamp:
            Developers are aware of the variability of block.timestamp.
            The DApp interface allows users to set the time period in seconds,
            hours, days, months, and years. Users are informed that using longer time
            periods make the variability of block.timestamp negligible.
        */
        envelopes[txid]=envelope(1,msg.sender,receiver,token,amount,amount,block.timestamp,holdTimeSec,0);

        // add txid to user's transaction list
        userTxns[msg.sender].push(txid);
        if(msg.sender!=receiver)
            userTxns[receiver].push(txid);
    }

    function openEnvelope(uint256 txid,uint256 returnToSender) external {    
        // check mode
        require(mode>0,"System is paused.");

        // check valid parties
        require(msg.sender==envelopes[txid].sender || msg.sender==envelopes[txid].receiver,"Not allowed");

        // check if already claimed or cancelled
        require(envelopes[txid].claimableAmount==envelopes[txid].amount && envelopes[txid].status==1,"Claimed, cancelled, or expired");

        // check if ready for claiming; otherwise sender can still release it
        /*
            IMPORTANT AUDIT NOTE REGARDING block.timestamp:
            Developers are aware of the variability of block.timestamp.
            The DApp interface allows users to set the time period in seconds,
            hours, days, months, and years. Users are informed that using longer time
            periods make the variability of block.timestamp negligible.
        */
        require((block.timestamp>envelopes[txid].created+envelopes[txid].holdTimeSec)||(msg.sender==envelopes[txid].sender),"Still in holding period");

        // ensure contract has balance
        bool isETH=envelopes[txid].token==address(this)?true:false;
        if(isETH)
            require(address(this).balance>=envelopes[txid].amount,"Insufficient contract balance");
        if(!isETH)
            require(IERC20(envelopes[txid].token).balanceOf(address(this))>=envelopes[txid].amount,"Insufficient token balance in contract");

        // re-entrancy guard
        // AUDIT NOTE: see third require statment in this function
        envelopes[txid].claimableAmount=0; // zero-out claimable
        if(returnToSender==1)
            envelopes[txid].status=0; // set cancelled status
        else
            envelopes[txid].status=2; // set sent status

        // release/return the funds
        if(isETH){
            address payable pDest=payable(envelopes[txid].receiver);
            if(returnToSender==1) pDest=payable(envelopes[txid].sender);
            pDest.transfer(envelopes[txid].amount);
        }
        if(!isETH){
            if(returnToSender==1)
                require(IERC20(envelopes[txid].token).transfer(envelopes[txid].sender,envelopes[txid].amount),"Transfer failed.");            
            else
                require(IERC20(envelopes[txid].token).transfer(envelopes[txid].receiver,envelopes[txid].amount),"Transfer failed.");            
        }
        
        // set date closed
        envelopes[txid].closed=block.timestamp;
    }

    ////////////////////////////////////////////////////////////////////////////////////

    function withdraw() external adminOnly{
        require(balances[msg.sender]>0,"No balance");
        uint256 bal=balances[msg.sender];
        balances[msg.sender]=0; // re-entrancy guard: zero-out variable before transferring
        address payable pAddress=payable(msg.sender);
        pAddress.transfer(bal);
    }

    ////////////////////////////////////////////////////////////////////////////////////

    function getFee(address account) external view returns (uint256){
        uint256 finalFee=fee;
        if(PARENT_CA!=address(0x0)){
            if(IERC20(PARENT_CA).balanceOf(account)>=minParentBal){
                finalFee=math.div(fee,2);
            }
        }
        if(feeWhitelisted[account]){
            finalFee=0;
        }

        return finalFee;
    }

    function countRecords(address account) external view returns (uint256){
        return userTxns[account].length;
    }

    function getRecordByIndex(address account,uint256 index) external view returns (uint256 _txid,address sender,address receiver,uint256 status,address token,uint256 amount,uint256 claimableAmount,uint256 created,uint256 holdTimeSec,uint256 closed,bool isClaimable){
        uint256 txid=userTxns[account][index];
        return getRecordByTxid(txid);
    }

    function getRecordByTxid(uint256 txid) public view returns (uint256 _txid,address sender,address receiver,uint256 status,address token,uint256 amount,uint256 claimableAmount,uint256 created,uint256 holdTimeSec,uint256 closed,bool isClaimable){
        envelope memory e=envelopes[txid];
        isClaimable=(block.timestamp>e.created+e.holdTimeSec)&&(e.status==1)?true:false;
        return(txid,e.sender,e.receiver,e.status,e.token,e.amount,e.claimableAmount,e.created,e.holdTimeSec,e.closed,isClaimable);
    }

    function allowance(address token,address owner) external view returns (uint256){
        return IERC20(token).allowance(owner,address(this));
    }

    function contractBalance(address token) external view returns (uint256){
        if(token==address(this)){
            return address(this).balance;
        }
        else{
            return IERC20(token).balanceOf(address(this));
        }
    }
}