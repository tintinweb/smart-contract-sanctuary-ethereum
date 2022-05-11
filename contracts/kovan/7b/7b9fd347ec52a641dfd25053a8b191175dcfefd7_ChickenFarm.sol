/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

// SPDX-License-Identifier: MIT
// @author ZeroBlock Studio https://zero-block-studio.com/ - blockchain development team for your startups

/**
 *Submitted for verification at polygonscan.com on 2022-05-10
 **/

/** 
 - Contract have not a centralized owner.
 - Fee is charged only when buying chickens.
 - You can't buy a fractional number of chickens. Fractional parts trancated, capitalized on
the contract and go to feed all the chickens.
 - Every tenth chicken goes to the the referrer.
 - If you haven't a referrer, it will be the Developer.
 - 100 chickens produce 4 eggs per day.
 - You can't see a fractional number of eggs on your balance, but they are.
 - Eggs cost depends on supply and demand.
 - You can sell eggs daily or incubate - hatch your eggs into new chickens.
 - You can not unstake; only withdraw earnings - you can sell the eggs your hens lay, but you can't sell the hens themselves.
**/

pragma solidity ^0.8.13;

contract ChickenFarm {
    bool public initialized = false;
    uint256 public marketEggs;
    uint256 public oneEggCost;

    uint256 private immutable DAY_IN_SECONDS = 3600;
    //uint256 private immutable DAY_IN_SECONDS = 86400; //for final version should be seconds in a day
    uint256 private immutable OneEggInitialCost = 0.0004 ether; //for final version should be 0.04 ether (0.04 MATIK)
    uint256 private immutable EggsInitialQuantity = 1000000;
    uint8 private immutable DeveloversFeePercent = 4;
    uint8 private immutable ReferralsFeePercent = 10;
    uint8 private immutable DailyEggsPersent = 4;
    uint8 private immutable MinEggsAmountToBuy = 10;

    address payable private Developer;
    mapping(address => uint256) private Chickens;
    mapping(address => uint256) private lastHarvest;
    mapping(address => address) private referrals;

    mapping(address => uint256) public MyRefferalsQuantity;
    mapping(address => uint256) public MyIncomeFromRefferals;

    //event for referrals payments info
    event NewIncomeFromRefferals(address indexed referal, address indexed refer, uint256 amountOfChickens);

    constructor() {
        Developer = payable(msg.sender);
        marketEggs = EggsInitialQuantity;
        oneEggCost = OneEggInitialCost;
    }


    function buyChickens(address ref) external payable {
        require(initialized);

        uint256 DeveloversFee = (msg.value * DeveloversFeePercent) / 100;
        uint256 clearValue = msg.value - DeveloversFee;
        uint256 chickenBought = (clearValue / oneEggCost);

        require(chickenBought >= MinEggsAmountToBuy, "It makes no sense to buy less than 10 eggs - a lot of commission losses!");
        require(marketEggs >= chickenBought, "All eggs are sold! Come back tomorrow!");

        //Perhaps this is not the first purchase of this user. 
        //If he has eggs on the balance, hatch them before buying new chickens.
        doIncubateEggs();

        //referrer is the one who brought the referral to buy for the first time
        //if the user buys for the second time, no matter whose link he came again - his referrer should not change
        address checkedRef=checkReffer(ref);

        //send 10% (only from the number of newly purchased) chickens to referrer.
        //fractional parts of chickens are trancated,
        //capitalized on the contract balance and divided in this way between all participants.
        Chickens[checkedRef] = Chickens[checkedRef] + (chickenBought * ReferralsFeePercent) / 100;
        MyIncomeFromRefferals[checkedRef] = MyIncomeFromRefferals[checkedRef] + (chickenBought * ReferralsFeePercent) / 100;
        emit NewIncomeFromRefferals(msg.sender, checkedRef, (chickenBought * ReferralsFeePercent) / 100);

        //We add to the buyer his chickens minus those that gone to the referrer
        Chickens[msg.sender] = Chickens[msg.sender] + (chickenBought * (100 - ReferralsFeePercent)) / 100;

        //after someone buys, the price goes up
        //in proportion to the volume of purchase
        priceUp(chickenBought);
        
        //Pay fee for developer
        Developer.transfer(DeveloversFee);
    }

    function sellEggs() external {
        require(initialized);

        uint256 hasEggs = getMyEggsForSale(msg.sender);
        require(hasEggs > 0, "You have not eggs for sale!");

        uint256 eggValue = hasEggs * oneEggCost;
        lastHarvest[msg.sender] = block.timestamp;
        require(
            address(this).balance >= eggValue,
            "Not enough egg buyers! Try to invite new farmers to the farm."
        );

        //after someone sells, the price goes down
        //in proportion to the volume of purchase
        priceDown(hasEggs);

        //paying money to someone who sold their eggs
        payable(msg.sender).transfer(eggValue);
    }

    function getMyEggsForSale(address adr) public view returns (uint256) {
        // 100 chickens produce 4 eggs per day
        uint256 amount = (Chickens[adr] * DailyEggsPersent * (block.timestamp - lastHarvest[adr])) / (DAY_IN_SECONDS * 100);
        return amount;
    }

    function getMyChickens(address adr) public view returns (uint256) {
        return Chickens[adr];
    }

    function doIncubateEggs() public{
        require(initialized);
        uint256 hasEggs = getMyEggsForSale(msg.sender);
        if (hasEggs > 0) { 
            Chickens[msg.sender] = Chickens[msg.sender] + hasEggs; 
            }
        lastHarvest[msg.sender] = block.timestamp;
    }

    function checkReffer(address _ref) private returns(address){
        address new_ref=_ref;
        if (new_ref == msg.sender || new_ref == address(0)) {
            new_ref = Developer;
        }
        if (referrals[msg.sender] == address(0)) {
            referrals[msg.sender] = new_ref;
            MyRefferalsQuantity[new_ref]=MyRefferalsQuantity[new_ref]+1;
        }
        return referrals[msg.sender];
    }

    function priceUp(uint256 _eggsBought) private{
        if(marketEggs>0){
            oneEggCost = (oneEggCost * (marketEggs - _eggsBought)) / marketEggs;
        }
        marketEggs = marketEggs - _eggsBought;
    }

    function priceDown(uint256 _eggsSold) private{
        if(marketEggs>0){
            oneEggCost = (oneEggCost * (marketEggs + _eggsSold)) / marketEggs;
        }
        marketEggs = marketEggs + _eggsSold;
    }

    modifier onlyDeveloper() {
        require(msg.sender == Developer);
        _;
    }

    function startFarming() external onlyDeveloper {
        initialized = true;
    }

    receive() external payable {}
}