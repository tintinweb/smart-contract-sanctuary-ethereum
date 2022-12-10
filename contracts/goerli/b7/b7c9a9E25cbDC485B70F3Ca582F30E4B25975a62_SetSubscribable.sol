// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct SubscriptionSpans {
    uint256 one;
    uint256 three;
    uint256 six;
    uint256 twelve;
}

struct FeeStructure {
    uint256 baseMultiplier;
    uint256 baseDiscount;
    uint256 annual;
}

struct PromoDiscount {
    uint256 amount;
    uint256 commission;
    address partner;
}

struct SubscribableData { 
    // day number to rate
    // mapping(uint256 => RateStructure) spanToRate;
    // tokenId to expiration
    mapping(uint256 => uint256) subscriptions;
    mapping(string => PromoDiscount) promoDiscounts;
    SubscriptionSpans subscriptionSpans;
    FeeStructure feeStructure;
}    

error InvalidNumberOfDays(uint256 numberOfDays);
error InvalidAmountForDays(uint256 numberOfDays, uint256 amount, uint256 required);
error DiscountIsInvalid(string discountCode);


string constant blank = "";

library SetSubscribable {
    function setSpans(SubscribableData storage self, uint256 one, uint256 three, uint256 six, uint256 twelve) internal {
        self.subscriptionSpans = SubscriptionSpans(one,three,six,twelve);
    }

    function setFeeStructure(SubscribableData storage self, uint256 multiplier, uint256 discount, uint256 annual) internal {
        self.feeStructure =  FeeStructure(multiplier,discount,annual);                
    }    

    // function setRates(SubscribableData storage self) internal {     
        
    //     self.spanToRate[self.subscriptionSpans.one] = RateStructure(
    //         self.feeStructure.baseMultiplier/self.feeStructure.annual*(1 ether),
    //         self.subscriptionSpans.one/7);
    //     self.spanToRate[self.subscriptionSpans.three] = RateStructure(
    //         (self.feeStructure.baseMultiplier-self.feeStructure.baseDiscount)/self.feeStructure.annual*(1 ether),
    //         self.subscriptionSpans.three/7);
    //     self.spanToRate[self.subscriptionSpans.six] = RateStructure(
    //         (self.feeStructure.baseMultiplier-(self.feeStructure.baseDiscount*2))/self.feeStructure.annual*(1 ether),
    //         self.subscriptionSpans.six/7);
    //     self.spanToRate[self.subscriptionSpans.twelve] = RateStructure(
    //         (self.feeStructure.baseMultiplier-(self.feeStructure.baseDiscount*3))/self.feeStructure.annual*(1 ether),
    //         self.subscriptionSpans.twelve/7);
    // }        
    
    function calculateExpiration(SubscribableData storage self, uint256 tokenId, uint256 numberOfDays) public view returns (uint256) {
        if (block.timestamp > self.subscriptions[tokenId]) {
            return block.timestamp + numberOfDays * 1 days;
        } 
        return self.subscriptions[tokenId] + numberOfDays * 1 days;                     
    }

    function calculateBaseRate(SubscribableData storage self, uint256 numberOfDays) public view returns (uint256) {
        uint256 discountMultiplier = numberOfDays == self.subscriptionSpans.one ? 0 :
        numberOfDays == self.subscriptionSpans.three ? 1 :
        numberOfDays == self.subscriptionSpans.six ? 2 :
        3;

        uint256 spans = numberOfDays / 7;

        uint256 periodDiscount = discountMultiplier * self.feeStructure.baseDiscount * (1 ether);

        return ((self.feeStructure.baseMultiplier * 100 * (1 ether)) - periodDiscount) / 100 / self.feeStructure.annual * spans;
    } 

    function calculateDiscount(uint256 promoDiscount) public pure returns (uint256) {
        return 100-promoDiscount;
    }         

    function calculateFee(SubscribableData storage self, uint256 numberOfDays) public view returns (uint256) {    
        return calculateFee(self, numberOfDays, blank);                                           
    }   

    function calculateFee(SubscribableData storage self, uint256 numberOfDays, string memory discountCode) public view returns (uint256) {

        validateDays(self,numberOfDays);        

        uint256 baseRate = calculateBaseRate(self,numberOfDays);

        uint256 discount = calculateDiscount(self.promoDiscounts[discountCode].amount);

        baseRate = baseRate * discount / 100;

        return floor(baseRate);        
    }       
    function calculateCommission(SubscribableData storage self, uint256 originalAmount, string memory discountCode) public view returns (uint256) {
        uint256 commissionRate = self.promoDiscounts[discountCode].commission > 0 ? 10000/self.promoDiscounts[discountCode].commission : 0;
        
        uint256 commission = 0;
        if (commissionRate >= 1) {
            commission = originalAmount / commissionRate * 100;            
        }     

        return commission;      
    }           
    function validateDays(SubscribableData storage self, uint256 numberOfDays) public view {
        if (numberOfDays != self.subscriptionSpans.one &&
            numberOfDays != self.subscriptionSpans.three && 
            numberOfDays != self.subscriptionSpans.six && 
            numberOfDays != self.subscriptionSpans.twelve ) {
            revert InvalidNumberOfDays(numberOfDays);
        }
    }

    function validatePayment(SubscribableData storage self, uint256 numberOfDays, string memory promoDiscount) public view {        
        uint256 cost = calculateFee(self, numberOfDays, promoDiscount);
        
        if (msg.value != cost) {
            revert InvalidAmountForDays(numberOfDays, msg.value, cost);
        }
    }

    function validateSubscription(SubscribableData storage self, uint256 numberOfDays, string calldata discountCode) public view {
        validateDays(self,numberOfDays);
        validatePayment(self,numberOfDays,discountCode);
    }    

    function validateSubscription(SubscribableData storage self, uint256 numberOfDays) public view {
        validateDays(self,numberOfDays);
        validatePayment(self,numberOfDays,"");
    }     

    function floor(uint256 amount) internal pure returns (uint256) {        
        return amount - (amount % 10000000000000000);
    }

    function expiresAt(SubscribableData storage self, uint256 tokenId) public view returns(uint256) {
        return self.subscriptions[tokenId];
    }

}