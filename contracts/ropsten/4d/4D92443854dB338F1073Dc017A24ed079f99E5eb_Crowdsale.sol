/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

pragma solidity ^0.5.17;
// from youtube https://www.youtube.com/watch?v=X_jFaBi9c9M&list=PLL5pYVd8AWtTCwvXKE14pBIhPWLfDBajA&index=8

interface token {
    function transfer (address reciever, uint256 amount) external;
}

contract Crowdsale {
    address public beneficiary;
    uint256 public fundingGoal;
    uint256 public amountRaised;
    uint256 public deadline;
    uint256 public price;
    token public tokenReward;

    mapping (address=>uint256) public balanceOf;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;

    event GoalReached(address recipient, uint256 totalAmountRaised);
    event FundTransfer(address backer, uint256 amount, bool isContribution);

    constructor (
        address ifSuccessfulSendTo,
        uint256 fundingGoalInEthers,
        uint256 durationInMinutes,
        uint256 etherCostforEachToken,
        address addressOfTokenUsedAsReward
    ) public {
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = durationInMinutes * 1 minutes;
        price = etherCostforEachToken * 1 ether;
        tokenReward = token(addressOfTokenUsedAsReward);
        
    }

    function() external payable {
        require(!crowdsaleClosed, "Crowdsale is closed");
        uint256 amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transfer(msg.sender, amount/price);

        emit FundTransfer(msg.sender, amount, true);
    }

    modifier afterDeadline() {
        if (now > deadline) _;
    }

    function checkGoalReached() public afterDeadline {
        if (amountRaised >= fundingGoal) {
            fundingGoalReached = true;
            emit GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }

    function saveWithDraw() public afterDeadline {
        if (!fundingGoalReached) {  // Refund token
            uint256 amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if(amount > 0) {
                if(msg.sender.send(amount)) {
                    emit FundTransfer(msg.sender, amount, false);
                } else {
                    balanceOf[msg.sender] = amount;
                }
            }
        }

        if (fundingGoalReached && beneficiary == msg.sender) {
            address payable beneficiaryPay = address(uint256(beneficiary));
            if (beneficiaryPay.send(amountRaised)) {
                emit FundTransfer(beneficiaryPay, amountRaised, false);
            } else {
                fundingGoalReached = false;
            }
        }
    }

    function checkIcoClosed() public view returns(bool isCrowdsaleClosed) {
        return crowdsaleClosed;
    }

    function remaingtimeIcoClosed() public view returns(uint256 remainingTime) {
        return now - deadline;
    }

    function checkBalanceOf(address addr) public view returns(uint256) {
        require(addr != address(0), "require address");
        return balanceOf[addr];
    }
    
}