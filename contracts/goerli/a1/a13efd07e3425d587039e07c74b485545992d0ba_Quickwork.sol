/**
 *Submitted for verification at Etherscan.io on 2022-11-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Quickwork
 * @dev Implements a quickwork contract
 */
interface USDCToken {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Quickwork{
    // MAJORITY refers to >50% of number of Signers
    enum ApprovalType {
        ALL,
        MAJORITY
    }

    struct Deliverable {
        string task;
        ApprovalType approvalType;
        bool completed;
        uint256 taskBounty; //usdc
    }

    mapping(uint => Deliverable) public deliverables;
    mapping(address => bool) public allowedSigners;
    mapping(uint => mapping(address => bool)) public deliverableToApprovalMapping;
    mapping(uint => uint) public taskToSignerCountMapping;
    mapping (uint => bool) public deliverableToPaidMapping;
    address payable public receiver;
    address payable public withdrawAddr;
    uint256 public totalReceived;
    uint public numberOfSigners;
    uint public agreementEndDate;
    uint public totalUSDCPayable = 0;
    bool private ended;
    USDCToken public usdcToken;

    event DeliverableSigned(uint indexed id, address signer);
    event DeliverableCompleted(uint indexed id);
    event DeliverablePaidOut(uint indexed id);



    //instantiate agreement details
    constructor(Deliverable[] memory deliverableList, address[] memory signerList,
        address payable receiverAddr, uint finalDate, address payable withdrawalAddr) {


        for (uint i = 0; i < deliverableList.length; i++) {
            deliverables[i] = deliverableList[i];
            totalUSDCPayable += deliverableList[i].taskBounty;
        }
        for (uint i = 0; i < signerList.length; i++) {
            allowedSigners[signerList[i]] = true;
        }
        numberOfSigners = signerList.length;
        receiver = receiverAddr;
        withdrawAddr = withdrawalAddr;
        agreementEndDate = finalDate;
        ended = false;
        usdcToken = USDCToken(0x07865c6E87B9F70255377e024ace6630C1Eaa37F);

    }

    receive() payable external {
        totalReceived += msg.value;
    }

    function checkPastEndDate() private {
        if (block.timestamp > agreementEndDate){
            ended = true;
        }
    }

    function getUSDBalance() public view returns (uint256) {
        return usdcToken.balanceOf(address(this));
    }

    function withdrawAll() payable public {
        checkPastEndDate();
        require(ended, "Agreement has not ended yet");
        require(msg.sender == withdrawAddr, "Only the withdrawal address can initiate a withdrawal of funds");
        withdrawAddr.transfer(address(this).balance);
        usdcToken.transfer(msg.sender, usdcToken.balanceOf(address(this)));
    }

    function signDeliverable(uint deliverableNo) public {
        require(allowedSigners[msg.sender], "User not allowed to sign"); 
        require(!signerHasApproved(deliverableNo, msg.sender), "User has already signed this task");
        deliverableToApprovalMapping[deliverableNo][msg.sender] = true;
        taskToSignerCountMapping[deliverableNo] += 1;
        emit DeliverableSigned(deliverableNo, msg.sender);
        checkApproval(deliverableNo);
    }
    
    function signerHasApproved(uint deliverableNo, address signer) private view returns (bool) {
        return deliverableToApprovalMapping[deliverableNo][signer];
    }

    function checkApproval(uint deliverableNo) private {
        Deliverable storage task = deliverables[deliverableNo];
        if (!task.completed) {
            ApprovalType requirement = task.approvalType;
            uint signed = taskToSignerCountMapping[deliverableNo];
            if (requirement == ApprovalType.ALL) {
                if (signed == numberOfSigners) {
                    task.completed = true;
                    emit DeliverableCompleted(deliverableNo);
                }
            } else {
                uint signersRequired = numberOfSigners / 2;
                if (signed > signersRequired) {
                    task.completed = true;
                    emit DeliverableCompleted(deliverableNo);
                }
            }   
        }
    }

    function releaseDeliverableSpecificFund(uint deliverableNo) public payable {
        Deliverable storage deliverable = deliverables[deliverableNo];
        require(!deliverableToPaidMapping[deliverableNo], "Bounty has already been paid");
        require(address(this).balance >= deliverable.taskBounty, "Not enough balance in contract");
        checkApproval(deliverableNo);
        require(deliverable.completed, "Approval conditions has not been met");
        usdcToken.transfer(receiver, deliverable.taskBounty);
        deliverableToPaidMapping[deliverableNo] = true;
        emit DeliverablePaidOut(deliverableNo);     
    }
}