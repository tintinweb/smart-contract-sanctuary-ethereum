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
    uint256 timesUsed;
    uint256 expires;
    address partner;
    bool exists;
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

address constant defaultPayable = 0x5aE09f46967A92f3cF976e98f82B6FDd00784815;
string constant blank = " ";
uint256 constant never = 9999999999999999999999999999;

library SetSubscribable {

    event SubscriptionUpdate(uint256 indexed tokenId, uint256 expiration);
       
    function initialize(SubscribableData storage self) public {
        setSpans(self, 4 * 7, 12 * 7, 24 * 7, 48 * 7); // 4 weeks, 12 weeks, 24 weeks, 48 weeks
        setFeeStructure(self,4, 25, 52); // base multiplier, base discount, annual period
        self.promoDiscounts[blank] = PromoDiscount(0,0,0,never,defaultPayable,true);
    }

    function setSpans(SubscribableData storage self, uint256 one, uint256 three, uint256 six, uint256 twelve) public {
        self.subscriptionSpans = SubscriptionSpans(one,three,six,twelve);
    }

    function setFeeStructure(SubscribableData storage self, uint256 multiplier, uint256 discount, uint256 annual) public {
        self.feeStructure =  FeeStructure(multiplier,discount,annual);                
    }    

    function setRateParams(SubscribableData storage self, uint256 multiplier, uint256 discount) public {
        setSpans(self,28, 84, 168, 336);
        setFeeStructure(self,multiplier, discount, 52);
    }

    function establishSubscription(SubscribableData storage self, uint256 tokenId, uint256 numberOfDays) public {
        uint256 expiration;
        if (block.timestamp > self.subscriptions[tokenId]) {
            expiration = block.timestamp + numberOfDays * 1 days;
        } else {
            expiration = self.subscriptions[tokenId] + numberOfDays * 1 days;
        }        
        self.subscriptions[tokenId] = expiration;
        emit SubscriptionUpdate(tokenId, expiration);
    }      
    
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
        if (numberOfDays != self.subscriptionSpans.one ) {
            if (numberOfDays != self.subscriptionSpans.three) {
                if (numberOfDays != self.subscriptionSpans.six) {
                    if (numberOfDays != self.subscriptionSpans.twelve) {
                        revert InvalidNumberOfDays(numberOfDays);
                    }   
                }                    
            }            
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
        validatePayment(self,numberOfDays,blank);
    }     

    function floor(uint256 amount) public pure returns (uint256) {        
        return amount - (amount % 10000000000000000);
    }

    function expiresAt(SubscribableData storage self, uint256 tokenId) public view returns(uint256) {
        return self.subscriptions[tokenId];
    }

}