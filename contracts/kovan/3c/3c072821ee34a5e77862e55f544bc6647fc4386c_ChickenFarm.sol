/**
 *Submitted for verification at Etherscan.io on 2022-05-15
*/

// SPDX-License-Identifier: MIT

/**
 *Submitted for verification at polygonscan.com on 2022-05-15
 **/

/** 
- Contract has not a centralized owner.
- Fee is charged only when selling eggs.
- Every tenth chicken goes to the the referrer.
- If you haven't a referrer, the developer will be your referrer.
- 100 chickens (hens) produce 5 eggs per day.
- Eggs cost slowly decreases over time.
- You can sell eggs daily or incubate your eggs into new chickens.
- You can not unstake - only withdraw earnings.
**/

pragma solidity ^0.8.13;

contract ChickenFarm {
    bool public initialized = false;
    uint256 public marketEggs;
    uint256 public oneEggCost;

    uint256 private immutable DAY_IN_SECONDS = 86400; //for final version should be seconds in a day
    uint256 private immutable OneChickenCost = 0.05 ether; //for final version should be 0.05 ether (0.05 MATIK)
    uint256 private immutable OneEggInitialCost = 0.05 ether; //for final version should be 0.05 ether (0.05 MATIK)
    uint256 private immutable EggsInitialQuantity = 1000000;//for final version should be 1000000
    uint8 private immutable developersFeePercent = 5;
    uint8 private immutable ReferralsFeePercent = 10;
    uint8 private immutable DailyEggsPersent = 5;

    address payable private developer;
    mapping(address => uint256) private Chickens;
    mapping(address => uint256) private lastHarvest;
    mapping(address => address) private referrals;

    mapping(address => uint256) public MyReferralsQuantity;
    mapping(address => uint256) public MyIncomeFromReferrals;

    event NewIncomeFromRefferals(address indexed referal, address indexed refer, uint256 amountOfChickens);
    event OneEggPriceHasChanged(uint256 indexed oldPrice, uint256 newPrice, uint256 eggsOnMarket);

    constructor() {
        developer = payable(msg.sender);
        marketEggs = EggsInitialQuantity;
        oneEggCost = OneEggInitialCost;
    }

    function buyChickens(address _ref) external payable {
        require(initialized);
        require(msg.value >= OneChickenCost, "It makes no sense to buy less than 1 chicken!");
        //Perhaps this is not the first purchase of this user. 
        //If user has eggs on the balance, hatch them before buying new chickens.
        doIncubateEggs();
        //referrer is the one who brought the referal to buy for the first time
        //if the user buys for the second time, no matter whose link he came again - his referrer should not change
        address checkedRef=checkReferrer(_ref);
        //send 10% (only from the number of newly purchased) chickens to referrer.
        Chickens[checkedRef] = Chickens[checkedRef] + (msg.value * ReferralsFeePercent) / 100;
        MyIncomeFromReferrals[checkedRef] = MyIncomeFromReferrals[checkedRef] + (msg.value * ReferralsFeePercent) / 100;
        emit NewIncomeFromRefferals(msg.sender, checkedRef, (msg.value * ReferralsFeePercent) / 100);
        //add to the buyer his chickens minus those that gone to the referrer
        Chickens[msg.sender] = Chickens[msg.sender] + (msg.value * (100 - ReferralsFeePercent)) / 100;
    }

    function sellEggs() external {
        require(initialized);

        uint256 hasEggs = getMyEggsForSale(msg.sender);
        require(hasEggs > 0, "You have not eggs for sale!");

        uint256 eggValue = hasEggs * oneEggCost;
        uint256 developersFee = (eggValue * developersFeePercent) / 100;
        uint256 clearValue = eggValue - developersFee;
        
        lastHarvest[msg.sender] = block.timestamp;
        require(
            address(this).balance >= clearValue,
            "Not enough egg buyers! Try to invite new farmers to the farm."
        );

        //after someone sells eggs, eggs price goes down
        //in proportion to the volume of purchase
        marketEggs = marketEggs + hasEggs;
        priceChange();

        //pay fee for developer
        developer.transfer(developersFee);
        //paying money to someone who sold their eggs
        payable(msg.sender).transfer(clearValue);
    }

    function getMyChickens(address _adr) public view returns (uint256) {
        return Chickens[_adr]/OneChickenCost;
    }

    function doIncubateEggs() public{
        require(initialized);
        uint256 hasEggs = getMyEggsForSale(msg.sender);
        if (hasEggs > 0) { 
            Chickens[msg.sender] = Chickens[msg.sender] + hasEggs*oneEggCost; 
            }
        lastHarvest[msg.sender] = block.timestamp;
    }

    function getMyEggsForSale(address _adr) public view returns (uint256) {
        // 100 chickens produce 4 eggs per day
        uint256 amount = (Chickens[_adr] * DailyEggsPersent 
                        * (block.timestamp - lastHarvest[_adr])) 
                        / (OneChickenCost * DAY_IN_SECONDS * 100);
        return amount;
    }

    //if user has no refferer, then referrer is Develover
    //if user alredy have referrer, referrer shoul no changing
    function checkReferrer(address _ref) private returns(address){
        address new_ref=_ref;
        if (new_ref == msg.sender || new_ref == address(0)) {
            new_ref = developer;
        }
        if (referrals[msg.sender] == address(0)) {
            referrals[msg.sender] = new_ref;
            MyReferralsQuantity[new_ref]=MyReferralsQuantity[new_ref]+1;
        }
        if (lastHarvest[referrals[msg.sender]]==0){
            lastHarvest[referrals[msg.sender]]=block.timestamp;
        }
        return referrals[msg.sender];
    }

    function getReferrer(address _referal) public view returns(address refer){
        return referrals[_referal];
    }

    function priceChange() private{
        if (marketEggs>0){
            uint256 oldPrice=oneEggCost;
            oneEggCost = oneEggCost * EggsInitialQuantity/marketEggs; 
            uint256 newPrice=oneEggCost;
            emit OneEggPriceHasChanged(oldPrice, newPrice, marketEggs);
        }
    }

    modifier onlydeveloper() {
        require(msg.sender == developer);
        _;
    }

    function startFarming() external onlydeveloper {
        initialized = true;
    }

    receive() external payable {}
}