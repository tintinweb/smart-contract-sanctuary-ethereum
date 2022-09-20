/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

// SPDX-License-Identifier: All Rights Reserved
pragma solidity ^0.8.17;

contract BRBTokenTax {

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    mapping(address => uint) public tokenHolderTimestamp;

    string public name = "BRBToken";
    string public symbol = "BRB";
    uint public decimals = 18;
    uint public initialSupply = 1000000000 * (10 ** decimals);
    // founder tax percent
    uint public liquidityPoolTaxPercent = 1;
    // marketing tax percent
    uint public marketingTaxPercent = 1;
    // burn tax percent
    uint public burnTaxPercent = 1;
    // refections tax percent
    uint public reflectionsTaxPercent = 1;
    // amount of bonus tokens person entitled to per period
    uint public rewardPerPeriod = 500 * (10 ** decimals);
    // how often rewards are applied, in days
    uint public rewardPeriod = 30;
    // whether reward tokens are enabled or not
    bool rewardsEnabled;

    event Transfer(address from, address indexed to, uint value);
    event Approval(address owner, address indexed spender, uint value);

    address public contractOwner;
    address public liquidityPoolAccount;
    address public marketingAccount;
    address public burnAccount;
    address public reflectionsAccount;


    constructor(address _liquidityPoolAccount, address _marketingAccount, address _burnAccount, address _reflectionsAccount) {
        balances[msg.sender] = initialSupply;
        // here we set the owner variable to the contract deployer address
        contractOwner = msg.sender;
        liquidityPoolAccount = _liquidityPoolAccount;
        marketingAccount = _marketingAccount;
        burnAccount = _burnAccount;
        reflectionsAccount = _reflectionsAccount;
    }

    //modifier added that checks that the sender is the owner account
    modifier onlyOwner(){
        require(msg.sender == contractOwner);
        _;
    }

    //here we modify the balanceOf function so that a user's balance is increased
    //by 500 each month that has elapsed since their holding timstamp
    function balanceOf(address owner) public view returns(uint) {
        uint totalBalance;
        // if user has held tokens for >0 amount of time calculate rewards
        if (tokenHolderTimestamp[owner] != 0 && rewardsEnabled) {
            //calc amount of months tokens held
            uint periodsElapsed = (block.timestamp - tokenHolderTimestamp[owner])/(rewardPeriod * 1 days);
            //calc amount of reward tokens
            uint rewardTokens = rewardPerPeriod * periodsElapsed;
            //calc total balance
            totalBalance = balances[owner] + rewardTokens;
        //if token holder has no timestamp, return the raw balance
        } else {
            totalBalance = balances[owner];
        }
        return totalBalance;
    }

    function totalSupply() public view returns(uint) {
        return initialSupply;
    }

    function transfer(address to, uint value) public returns(bool) {

        require(balanceOf(msg.sender) >= value, 'balance too low');

        // calculate bonus allocation so we can prevent it from being deducted from balances mapping
        uint rewardTokens;

        // check if token holden timestamp is set, if it is then they have been holding tokens and are entitled to holding reward tokens
        if (tokenHolderTimestamp[msg.sender] != 0) {
            //calc amount of months tokens held
            uint periodsElapsed = (block.timestamp - tokenHolderTimestamp[msg.sender])/(30 days);
            //calc amount of reward tokens
            rewardTokens = rewardPerPeriod * periodsElapsed;
        //if token holder has no timestamp, return the raw balance
        } else if (tokenHolderTimestamp[msg.sender] == 0) {
            rewardTokens = 0;
        }

        // transfer amount - 2*5% = 90% to recipient
        uint transferAmount = value*(100 - liquidityPoolTaxPercent - marketingTaxPercent - burnTaxPercent - reflectionsTaxPercent)/100;
        balances[to] += transferAmount;

        //subtract full value from sender except reward tokens which aren't accounted for in the balances mapping
        balances[msg.sender] -= (value - rewardTokens);
        emit Transfer(msg.sender, to, transferAmount);

        // calculate liquidity pool tax
        uint liquidityPoolTaxAmount = value*(liquidityPoolTaxPercent)/100;

        // transfer 1% liquidity pool tax
        balances[liquidityPoolAccount] += liquidityPoolTaxAmount;
        emit Transfer(msg.sender, liquidityPoolAccount, liquidityPoolTaxAmount);

        // calculate marketing tax
        uint marketingTaxAmount = value*(marketingTaxPercent)/100;

        //transfer 1.5% to marketing
        balances[marketingAccount] += marketingTaxAmount;
        emit Transfer(msg.sender, marketingAccount, marketingTaxAmount);

        // calculate founder tax
        uint burnTaxAmount = value*(burnTaxPercent)/100;

        //tranfer 1% to founder
        balances[burnAccount] += burnTaxAmount;
        emit Transfer(msg.sender, burnAccount, burnTaxAmount);

        // calculate founder tax
        uint reflectionsTaxAmount = value*(reflectionsTaxPercent)/100;

        //tranfer 1% to founder
        balances[reflectionsAccount] += reflectionsTaxAmount;
        emit Transfer(msg.sender, reflectionsAccount, reflectionsTaxAmount);

        // set the time the the receiver gets their first token
        // (if they already have a tokenHolderTimestamp then they should keep it and we shouldn't overwrite it)
        if(tokenHolderTimestamp[to] == 0) {
            // save time when receiver recieves first token
            tokenHolderTimestamp[to] = block.timestamp;
        }

        // if sender sends all their tokens they should reset their holding timestamp
        if(balanceOf(msg.sender) == 0) {
            tokenHolderTimestamp[msg.sender] = 0;
        }

        return true;
    }

    function transferFrom(address from, address to, uint value) public returns(bool) {
        // check sending account has enough 
        require(balanceOf(from) >= value, 'balance too low');

        // check allowance is enough
        require(allowance[from][msg.sender] >= value, 'allowance too low');

        // calculate bonus allocation so we can prevent it from being deducted from balances mapping
        uint rewardTokens;
        if (tokenHolderTimestamp[from] != 0 && rewardsEnabled) {
            //calc amount of months tokens held
            uint periodsElapsed = (block.timestamp - tokenHolderTimestamp[from])/(rewardPeriod * 1 days);
            //calc amount of reward tokens
            rewardTokens = rewardPerPeriod * periodsElapsed;

        //if token holder has no timestamp, return the raw balance
        } else {
            rewardTokens = 0;
        }

        // subtract value from allowance
        allowance[from][msg.sender] -= value;

        // calculate transfer amount which is equal to value minus tax
        uint transferAmount = value*(100 - liquidityPoolTaxPercent - marketingTaxPercent - burnTaxPercent - reflectionsTaxPercent)/100;

        // transfer tokens to new account
        balances[to] += transferAmount;

        // subtract full amount from sender (not including rewards tokens which are not accounted for in balances mapping)
        balances[from] -= value;
        emit Transfer(from, to, transferAmount);

        // calculate liquidity pool tax
        uint liquidityPoolTaxAmount = value*(liquidityPoolTaxPercent)/100;

        //transfer tax to liquidity pool account
        balances[liquidityPoolAccount] += liquidityPoolTaxAmount;
        emit Transfer(from, liquidityPoolAccount, liquidityPoolTaxAmount);

        // calculate marketing tax
        uint marketingTaxAmount = value*(marketingTaxPercent)/100;

        //transfer tax to marketing account
        balances[marketingAccount] += marketingTaxAmount;
        emit Transfer(from, marketingAccount, marketingTaxAmount);

        // calculate burn tax
        uint burnTaxAmount = value*(burnTaxPercent)/100;

        //tranfer 1% to burn account
        balances[burnAccount] += burnTaxAmount;
        emit Transfer(from, burnAccount, burnTaxAmount);

        // calculate reflections tax
        uint reflectionsTaxAmount = value*(reflectionsTaxPercent)/100;

        //tranfer 1% to reflections account
        balances[reflectionsAccount] += reflectionsTaxAmount;
        emit Transfer(from, reflectionsAccount, reflectionsTaxAmount);

        // set the time the the receiver gets their first token
        // (if they already have a tokenHolderTimestamp then they should keep it and we shouldn't overwrite it)
        if(tokenHolderTimestamp[to] == 0) {
            // save time when receiver recieves first token
            tokenHolderTimestamp[to] = block.timestamp;
        }

        // if sender sends all their tokens they should reset their holding timestamp
        if(balanceOf(from) == 0) {
            tokenHolderTimestamp[from] = 0;
        }

        return true;
    }

    // function to liquidity pool alter tax
    function setLiquidityPoolTax(uint newLiquidityPoolTax) public onlyOwner {
        require(newLiquidityPoolTax <= 50);
        liquidityPoolTaxPercent = newLiquidityPoolTax;
    }


    // function to marketing alter tax
    // max tax is 50% as that would mean 100% of transfers go to founder and marketing (50% each)
    // onlyOwner added as check to ensure only the owner can call this function
    function setMarketingTax(uint newMarketingTax) public onlyOwner {
        require(newMarketingTax <= 50);
        marketingTaxPercent = newMarketingTax;
    }

    // function to burn alter tax
    // max tax is 50% as that would mean 100% of transfers go to founder and marketing (50% each)
    // onlyOwner added as check to ensure only the owner can call this function
    function setBurnTax(uint newBurnTax) public onlyOwner {
        require(newBurnTax <= 50);
        burnTaxPercent = newBurnTax;
    }

    // function to reflections alter tax
    function setReflectionsTax(uint newReflectionsTax) public onlyOwner {
        require(newReflectionsTax <= 50);
        reflectionsTaxPercent = newReflectionsTax;
    }

    // added function to alter reward
    // onlyOwner added as check to ensure only the owner can call this function
    function setReward(uint newReward) public onlyOwner {
        rewardPerPeriod = newReward;
    }

    // function to change contract owner account
    // onlyOwner added as check to ensure only the owner can call this function
    function changeOwner(address newOwner) public onlyOwner {
        contractOwner = newOwner;
    }

    // function to change contract liquidity pool account
    // onlyOwner added as check to ensure only the owner can call this function
    function changeLiquidityPoolAccount(address newLiquidityPoolAccount) public onlyOwner {
        liquidityPoolAccount = newLiquidityPoolAccount;
    }

    // function to change contract marketing account
    // onlyOwner added as check to ensure only the owner can call this function
    function changeMarketingAccount(address newMarketingAccount) public onlyOwner {
        marketingAccount = newMarketingAccount;
    }

    // function to change contract burn account
    // onlyOwner added as check to ensure only the owner can call this function
    function changeBurnAccount(address newBurnAccount) public onlyOwner {
        burnAccount = newBurnAccount;
    }

    // function to change contract burn account
    // onlyOwner added as check to ensure only the owner can call this function
    function changeReflectionsAccount(address newReflectionsAccount) public onlyOwner {
        reflectionsAccount = newReflectionsAccount;
    }


    

    function toggleRewards(bool rewardState) public returns (bool) {
        rewardsEnabled = rewardState;
        return true;
    }

    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}