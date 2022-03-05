//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract PiggyBankFundraise {

    event Deposit(uint _amount, address _depositer, uint _fundingGoal, bool _targetReached);
    event GoldenDonerSet(address goldenDoner);
    event WithdrawAll(uint amount);
    event CanWithdraw(bool donersRecoverFunds, bool contractRetrainFunds);

    address payable public owner; 
    uint public fundingGoal; 
    string public fundingSummary;
    address public goldenDoner; 
    bool public targetReached; 

    uint public immutable startAt; 
    uint public immutable recoverFundsAt;
    uint public immutable retainFundsAt; 

    bool public recoverFundsAvailable;
    bool public retrainFundsAvailable;

    mapping(address => uint) public addressToDonation; 

    constructor(uint _fundingGoal, string memory _fundingSummary, uint _getBackFundsMin, uint _clearContractMin){
        require(_clearContractMin > _getBackFundsMin, "clearContractMin has to be larger than the getBackFundsMin");
        owner = payable(msg.sender);
        fundingGoal = _fundingGoal;
        fundingSummary = _fundingSummary;
        startAt = block.timestamp;
        recoverFundsAt = startAt + _getBackFundsMin*60;
        retainFundsAt = startAt + _clearContractMin*60;
        recoverFundsAvailable = false;
        retrainFundsAvailable= false;
    }

    modifier fundingGoalNotMet(){
        require(!targetReached, "funding goal has been reached"); 
        _;
    }

    modifier getBackFundsTime(){
        require(block.timestamp >= recoverFundsAt && block.timestamp < retainFundsAt, "fund recovery period has not started");
      _;
    }

    modifier clearContractAvailable(){
        require(msg.sender == owner, "function access is only for owner"); 
        require(block.timestamp >= retainFundsAt, "retain funds period has not started");
        _;
    }

    function checkAvaialbleWithdrawMethods() public {
        if(block.timestamp >= recoverFundsAt && block.timestamp < retainFundsAt){
            recoverFundsAvailable = true;
        }
        if(block.timestamp >= retainFundsAt){
            retrainFundsAvailable = true;
        }
        emit CanWithdraw(recoverFundsAvailable, retrainFundsAvailable);
    }

    receive() external payable fundingGoalNotMet{
    addressToDonation[msg.sender] += msg.value;
    if(checkFundraisingTarget()){
        disburseFunds();
        goldenDoner = msg.sender;
        targetReached = true;
        emit GoldenDonerSet(msg.sender);
    }
    emit Deposit(msg.value, msg.sender, fundingGoal, targetReached);
    }

    function getBackFunds() external getBackFundsTime{
        uint donated = addressToDonation[msg.sender];
        payable(msg.sender).transfer(donated);
    }

    function getContractBalance() public view returns (uint256){
        checkFundraisingTarget();
        return address(this).balance; 
    }

    function withdrawAll() public clearContractAvailable {
        emit WithdrawAll(address(this).balance);
        selfdestruct(payable(msg.sender));
    }

    function disburseFunds() internal {
        owner.transfer(address(this).balance);
    }

    function checkFundraisingTarget() internal view returns (bool) {
        if (address(this).balance >= fundingGoal){
            targetReached == true;    
            return true;  
        }
        else{
            return false; 
        }    
    }  
}