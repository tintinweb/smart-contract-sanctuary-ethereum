/**
 *Submitted for verification at Etherscan.io on 2022-12-28
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract ViceCrowdsale {
    // define if the ico is already completed or not
    bool public icoCompleted;
    // the ICO start time, which can be in timestamp or in block number
    uint256 public icoStartTime;
    // the ICO end time
    uint256 public icoEndTime;
    // the token price
    uint256 public tokenRate;
    // the funding goal in wei which is the smallest Ethereum unit
    uint256 public fundingGoal;
    // amount of tokens sold
    uint256 public tokensRaised;
    // amount of ether collected
    uint256 public etherRaised;
    // rate for goal 1
    uint256 public rateOne = 13333;
    // rate for goal 2
    uint256 public rateTwo = 10000;
    // rate for goal 3
    uint256 public rateThree = 6666;
    // rate for goal 4
    uint256 public rateFour = 5000;

    // The minimum amount of Wei you must pay to participate in the crowdsale
    uint256 public constant minPurchase = 0.016 ether; // 0.005 ether

    // The max amount of Wei that you can pay to participate in the crowdsale
    uint256 public constant maxPurchase = 10 ether;

    // You can only buy up to 50 M tokens during the ICO
    uint256 public constant maxTokensRaised = 6720000 * (10**18);

    // limit for each goal
    uint256 public limitGoalOne = 806400 * (10**18);
    uint256 public limitGoalTwo = 2016000 * (10**18);
    uint256 public limitGoalThree = 3897600 * (10**18);
    uint256 public limitGoalFour = 6720000 * (10**18);

    // The number of transactions
    uint256 public numberOfTransactions;

    // Payable address can receive Ether
    address payable public owner;

    // buyer info
    mapping(address => uint256) public tokensBought;
    mapping(address => uint256) public amountAlreadyClaimed;
    mapping(address => uint256) public etherPaid;

    constructor(
        uint256 _icoStart,
        uint256 _icoEnd,
        uint256 _tokenRate,
        // address _tokenAddress,
        uint256 _fundingGoal
    ) {
        require(
            _icoStart != 0 &&
                _icoEnd != 0 &&
                _icoStart < _icoEnd &&
                _tokenRate != 0 &&
                _fundingGoal != 0
            // _tokenAddress != address(0) &&
        );
        icoStartTime = _icoStart;
        icoEndTime = _icoEnd;
        tokenRate = _tokenRate;
        // tokenAddress = _tokenAddress;
        fundingGoal = _fundingGoal;
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier whenIcoCompleted() {
        require(icoCompleted);
        _;
    }

    function buy() public payable {
        _buy();
    }

    function _buy() public payable {
        require(validPurchase(), "ViceCrowdsale/NotValidPurchase");

        uint256 tokensToBuy;
        // get the value of ether sent by the user and calculate if there is a excess
        uint256 etherUsed = calculateExcessBalance();

        // If the tokens raised are less than 25 million with decimals, apply the first rate
        if (tokensRaised < limitGoalOne) {
            // tier 1
            tokensToBuy = etherUsed * rateOne;

            // If the amount of tokens that you want to buy gets out of this tier
            if (tokensRaised + tokensToBuy > limitGoalOne) {
                tokensToBuy = calculateExcessTokens(
                    etherUsed,
                    limitGoalOne,
                    1,
                    rateOne
                );
            }
        } else if (
            tokensRaised >= limitGoalOne && tokensRaised < limitGoalTwo
        ) {
            // Tier 2
            tokensToBuy = etherUsed * rateTwo;

            // If the amount of tokens that you want to buy gets out of this tier
            if (tokensRaised + tokensToBuy > limitGoalTwo) {
                tokensToBuy = calculateExcessTokens(
                    etherUsed,
                    limitGoalTwo,
                    2,
                    rateTwo
                );
            }
        } else if (
            tokensRaised >= limitGoalTwo && tokensRaised < limitGoalThree
        ) {
            // Tier 3
            tokensToBuy = etherUsed * rateThree;

            // If the amount of tokens that you want to buy gets out of this tier
            if (tokensRaised + tokensToBuy > limitGoalThree) {
                tokensToBuy = calculateExcessTokens(
                    etherUsed,
                    limitGoalThree,
                    3,
                    rateThree
                );
            }
        } else if (tokensRaised >= limitGoalThree) {
            // Tier 4
            tokensToBuy = etherUsed * rateFour;
        }

        // Store buyer info
        tokensBought[msg.sender] += tokensToBuy;
        amountAlreadyClaimed[msg.sender] = 0;
        numberOfTransactions = numberOfTransactions + 1;

        // Increase the tokens raised and ether raised state variables
        tokensRaised += tokensToBuy;
        etherRaised += etherUsed;
    }

    /// @notice Calculates how many ether will be used to generate the tokens in
    /// case the buyer sends more than the maximum balance but has some balance left
    /// and updates the balance of that buyer.
    /// For instance if he's 500 balance and he sends 1000, it will return 500
    /// and refund the other 500 ether
    function calculateExcessBalance() internal returns (uint256) {
        uint256 etherUsed = msg.value;
        uint256 differenceWei = 0;
        uint256 exceedingBalance = 0;

        // If we're in the last tier, check that the limit hasn't been reached
        // and if so, refund the difference and return what will be used to
        // buy the remaining tokens
        if (tokensRaised >= limitGoalThree) {
            uint256 addedTokens = tokensRaised + (etherUsed * rateFour);

            // If tokensRaised + what you paid converted to tokens is bigger than the max
            if (addedTokens > maxTokensRaised) {
                // Refund the difference
                uint256 difference = addedTokens - maxTokensRaised;
                differenceWei = difference / rateFour;
                etherUsed = etherUsed - differenceWei;
            }
        }

        uint256 addedEthPaid = etherPaid[msg.sender] + etherUsed;

        // Checking that the individual limit of 0.5 ETH per user is not reached
        if (addedEthPaid <= maxPurchase) {
            etherPaid[msg.sender] += etherUsed;
        } else {
            exceedingBalance = addedEthPaid - maxPurchase;
            etherUsed -= exceedingBalance;

            // Add that balance to the ethPaid
            etherPaid[msg.sender] += etherUsed;
        }

        // Make the transfers at the end of the function for security purposes
        if (differenceWei > 0) {
            (bool success, ) = msg.sender.call{value: differenceWei}("");
            require(success, "Failed to refund Ether");
        }

        if (exceedingBalance > 0) {
            // Return the exceeding balance to the buyer
            (bool success, ) = msg.sender.call{value: exceedingBalance}("");
            require(success, "Failed to refund Ether");
        }

        return etherUsed;
    }

    function calculateExcessTokens(
        uint256 _amount,
        uint256 _tokensThisGoal,
        uint256 _goalSelected,
        uint256 _rate
    ) public returns (uint256 totalTokens) {
        require(_amount > 0 && _tokensThisGoal > 0 && _rate > 0);
        require(_goalSelected >= 1 && _goalSelected <= 4);

        uint256 weiThisGoal = (_tokensThisGoal - tokensRaised) / _rate;
        uint256 weiNextGoal = _amount - weiThisGoal;
        uint256 tokensNextGoal = 0;
        bool returnTokens = false;

        // If there's excessive wei for the last tier, refund those
        if (_goalSelected != 4) {
            tokensNextGoal = calculateTokensGoal(
                weiNextGoal,
                _goalSelected + 1
            );
        } else {
            returnTokens = true;
        }

        totalTokens = _tokensThisGoal - tokensRaised + tokensNextGoal;

        // Do the transfer at the end
        if (returnTokens) {
            (bool success, ) = msg.sender.call{value: weiNextGoal}("");
            require(success, "Failed to refund Ether");
        }
    }

    function calculateTokensGoal(uint256 _weiPaid, uint256 _goalSelected)
        internal
        returns (uint256 calculatedTokens)
    {
        require(_weiPaid > 0);
        require(_goalSelected >= 1 && _goalSelected <= 4);

        if (_goalSelected == 1) calculatedTokens = _weiPaid * rateOne;
        else if (_goalSelected == 2) calculatedTokens = _weiPaid * rateTwo;
        else if (_goalSelected == 3) calculatedTokens = _weiPaid * rateThree;
        else calculatedTokens = _weiPaid * rateFour;
    }

    /// @notice Checks if a purchase is considered valid
    /// @return bool If the purchase is valid or not
    function validPurchase() internal returns (bool) {
        bool withinPeriod = block.timestamp >= icoStartTime &&
            block.timestamp <= icoEndTime;
        bool nonZeroPurchase = msg.value > 0;
        bool withinTokenLimit = tokensRaised < maxTokensRaised;
        bool minimumPurchase = msg.value >= minPurchase;
        bool hasBalanceAvailable = etherPaid[msg.sender] < maxPurchase;

        // We want to limit the gas to avoid giving priority to the biggest paying contributors
        //bool limitGas = tx.gasprice <= limitGasPrice;

        return
            withinPeriod &&
            nonZeroPurchase &&
            withinTokenLimit &&
            minimumPurchase &&
            hasBalanceAvailable;
    }

    // Set new ICO Start Time
    function setNewICOStartTime(uint256 _icoStartTime) public onlyOwner {
        icoStartTime = _icoStartTime;
    }

    // Set new ICO End Time
    function setNewICOEndTime(uint256 _icoEndTime) public onlyOwner {
        icoEndTime = _icoEndTime;
    }

    // The extractEther function can only be called if ICO has completed
    function extractEther() public onlyOwner {
        // get the amount of Ether stored in this contract
        uint256 amount = address(this).balance;

        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }
}