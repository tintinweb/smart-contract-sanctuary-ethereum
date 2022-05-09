/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

// SPDX-License-Identifier: MIT

/**
 *Submitted for verification at polygonscan.com on 2022-05-08
**/

/** 
- Contract have not a centralized owner.
- Commission is charged only when buying eggs.
- You can't buy a fractional number of eggs. 
- Fractional parts discarded in the calculations are capitalized on the contract and 
used to pay interest to all participants.
- Eggs you buoght immediately hatch into chickens.
- 100 chickens lay 4 eggs per day.
- You can't see a fractional number of eggs on your balance, but they are.
- Eggs cost depends on supply and demand.
- You can sell eggs daily or reinvest - hatch your eggs into new chickens.
- You can not unstake; only withdraw earnings
**/

pragma solidity ^0.8.13;

contract ChickenFarm {
    bool public initialized = false;
    uint256 public InnerBalance;
    uint256 public marketEggs;
    uint256 public oneEggCost;

    uint256 private immutable DAY_IN_SECONDS=60;
    //uint256 private immutable DAY_IN_SECONDS = 86400; //for final version should be seconds in a day
    uint256 private immutable OneEggInitialCost=0.004 ether;// for final version should be 0.04 
    uint256 private immutable EggsInitialQuantity=10000000;
    uint8 private immutable DeveloversFeePercent=3;
    uint8 private immutable ReferralsFeePercent=10;
    
    address payable private Developer;
    mapping(address => uint256) private Chickens;
    mapping(address => uint256) private lastHarvest;
    mapping(address => address) private referrals;
    
    constructor() {
        Developer = payable(msg.sender);
        InnerBalance=OneEggInitialCost*EggsInitialQuantity;
        marketEggs = EggsInitialQuantity;
        oneEggCost = OneEggInitialCost;
    }

    function buyEggs(address ref) external payable {
        require(initialized);
        uint256 DeveloversFee = (msg.value*DeveloversFeePercent)/100;
        uint256 clearValue=msg.value-DeveloversFee;
        uint256 eggsBought = (clearValue/oneEggCost);
        require(marketEggs>=eggsBought,"All eggs are sold! Come back tomorrow!");

        //if it is reinvest, your accumulated eggs hatch
        uint256 hasEggs = getMyEggsForSale(msg.sender);
        if (hasEggs>0){
            Chickens[msg.sender] = Chickens[msg.sender]+hasEggs;
        }
        lastHarvest[msg.sender] = block.timestamp;

        marketEggs=marketEggs-eggsBought;
        //purchased eggs immediately hatch into chickens
        Chickens[msg.sender] = Chickens[msg.sender]+eggsBought*(100-ReferralsFeePercent)/100; //10% for ref

        if (ref == msg.sender || ref==address(0)) {
            ref = Developer;
        }
        if (referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        //send 10% (only from the number of newly purchased) chickens to ref.
        //fractional parts of chickens are discarded, 
        //capitalized on the contract balance and divided in this way between all participants.
        Chickens[referrals[msg.sender]] = Chickens[referrals[msg.sender]]+eggsBought*ReferralsFeePercent/100;

        //after someone buys, the price goes up
        oneEggCost=oneEggCost*(InnerBalance+clearValue)/InnerBalance;
        InnerBalance=InnerBalance+clearValue;

        Developer.transfer(DeveloversFee);
    }

    function sellEggs() external {
        require(initialized);
        uint256 hasEggs = getMyEggsForSale(msg.sender);
        require(hasEggs>0,"You have not eggs for sale!");

        //when someone sells, the price goes down
        oneEggCost=oneEggCost*(marketEggs+hasEggs)/marketEggs;
        marketEggs = marketEggs+hasEggs;

        uint256 eggValue = hasEggs*oneEggCost;
        lastHarvest[msg.sender] = block.timestamp;
        InnerBalance=InnerBalance-eggValue;
        require(address(this).balance>=eggValue,
        "No egg buyers! Try to invite new farmers to the farm.");

        payable(msg.sender).transfer(eggValue);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    modifier onlyDeveloper {
        require(msg.sender == Developer);
        _;
    }

    function startFarming() external onlyDeveloper {
        initialized = true;
    }

    

    function getMyEggsForSale(address adr) public view returns (uint256) {
        // 100 chickens lay 4 eggs per day
        uint256 amount = (Chickens[adr] * 4 * (block.timestamp - lastHarvest[adr])) / (DAY_IN_SECONDS*100);
        return amount;
    }

    function getMyChickens(address adr) public view returns (uint256) {
        return Chickens[adr];
    }

    receive() external payable{

    }

}