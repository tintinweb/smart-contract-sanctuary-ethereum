/**
 *Submitted for verification at Etherscan.io on 2022-09-04
*/

// SPDX-License-Identifier: CC-BY-SA 4.0
//https://creativecommons.org/licenses/by-sa/4.0/

// TL;DR: The creator of this contract (@LogETH) is not liable for any damages associated with using the following code
// This contract must be deployed with credits toward the original creator, @LogETH.
// You must indicate if changes were made in a reasonable manner, but not in any way that suggests I endorse you or your use.
// If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.
// You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.
// This TL;DR is solely an explaination and is not a representation of the license.

// By deploying this contract, you agree to the license above and the terms and conditions that come with it.

pragma solidity >=0.8.0 <0.9.0;

//// What is this contract? 

//// This contract is a specific custom ERC20 token, with a gas friendly reflection system I designed myself
//// Most of my contracts have an admin, this contract does not as it is automatically renounced when deployed

//// Unlike traditional fee contracts, this contract broadcasts the fee and the sent amount in the transaction data.
//// The broadcast is supported by ethereum explorers like etherscan and makes accounting much easier.

    // How to Setup:

    // Step 1: Change the values in the constructor to the ones you want (make sure to double check as they cannot be changed)
    // Step 2: Deploy the contract
    // Step 3: Go to https://app.gelato.network/ and create a new task that executes "sendFee()" when it is available
    // Step 4: Gelato should already tell you this, but make sure you put enough ETH in the vault to activate the function when needed.
    // Step 5: Create a market using https://app.uniswap.org/#/add/v2/ETH, and grab the LP token address in the transaction receipt
    // Step 6: Call "setDEX()" with the LP token address you got from the tx receipt to enable the fee and max wallet limit
    // Step 7: It should be ready to use from there, all inital tokens are sent to the wallet of the deployer

//// Commissioned by a bird I met on a walk on 8/5/2022

contract SpecERC20 {

//// The constructor, this is where you change settings before deploying
//// make sure to change these parameters to what you want

    constructor () {

        totalSupply = 2000000*1e18;         // The amount of tokens in the inital supply, you need to multiply it by 1e18 as there are 18 decimals
        name = "Test LOG token";            // The name of the token
        decimals = 18;                      // The amount of decimals in the token, usually its 18, so its 18 here
        symbol = "tLOG";                    // The ticker of the token
        BuyFeePercent = 3;                  // The % fee that is sent to the dev on a buy transaction
        SellFeePercent = 2;                 // The % fee that is sent to the dev on a sell transaction
        ReflectBuyFeePercent = 3;           // The % fee that is reflected on a buy transaction
        ReflectSellFeePercent = 2;          // The % fee that is reflected on a sell transaction
        BuyLiqTax = 1;                      // The % fee that is sent to liquidity on a buy
        SellLiqTax = 2;                     // The % fee that is sent to liquidity on a sell
        maxWalletPercent = 2;               // The maximum amount a wallet can hold, in percent of the total supply.
        threshold = 1e15;                   // When enough fees have accumulated, send this amount of wETH to the dev addresses.

        Dev1 = msg.sender;
        Dev2 = 0x6B3Bd2b2CB51dcb246f489371Ed6E2dF03489A71;
        wETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;

        balances[msg.sender] = totalSupply; // a statement that gives the deployer of the contract the entire supply.
        deployer = msg.sender;              // a statement that marks the deployer of the contract so they can set the liquidity pool address


        router = Univ2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);  // The address of the uniswap v2 router
        ERC20(wETH).approve(address(router), type(uint256).max); // Approves infinite wETH for use on uniswap v2 (For adding liquidity)

        order.push(address(this));
        order.push(wETH);

        graph = DeployContract();
        graph.initalize(deployer, address(this));

        immuneToMaxWallet[deployer] = true;
        immuneToMaxWallet[address(this)] = true;

        _status = _NOT_ENTERED;
    }

//////////////////////////                                                          /////////////////////////
/////////////////////////                                                          //////////////////////////
////////////////////////            Variables that this contract has:             ///////////////////////////
///////////////////////                                                          ////////////////////////////
//////////////////////                                                          /////////////////////////////

//// Variables that make this contract ERC20 compatible (with metamask, uniswap, trustwallet, etc)

    mapping(address => uint256) private balances;
    mapping(address => mapping (address => uint256)) public allowed;

    string public name;
    uint8 public decimals;
    string public symbol;
    uint public totalSupply;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

//// Tax variables, I already explained them in the contstructor, so go look there

    uint public BuyFeePercent; uint public SellFeePercent; uint public ReflectBuyFeePercent; uint public ReflectSellFeePercent; uint public SellLiqTax; uint public BuyLiqTax;

//// Variables that make the internal parts of this contract work, I explained them the best I could

    Univ2 public router;                           // The address of the uniswap router that swaps your tokens
    Graph public graph;                            // The address of the graph contract that grabs a number from a graph

    address Dev1;                           // Already explained in the constructor, go look there
    address Dev2;                           // ^
    address Dev3;                           // ^
    address Dev4;                           // ^
    address Liq;                            // ^

    address public DEX;                     // The address of the LP token that is the pool where the LP is stored
    address public wETH;                    // The address of wrapped ethereum
    uint public rebaseMult = 1e18;          // The base rebase, it always starts at 1e18
    address deployer;                       // The address of the person that deployted this contract, allows them to set the LP token, only once.
    address deployerALT;
    mapping(address => uint256) public AddBalState; // A variable that keeps track of everyone's rebase and makes sure it is done correctly
    mapping(address => bool) public immuneToMaxWallet; // A variable that keeps track if a wallet is immune to the max wallet limit or not.
    uint maxWalletPercent;
    uint public feeQueue;
    uint public LiqQueue;
    uint public threshold;
    bool public renounced;

    address[] public order;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    modifier nonReentrant(address _to, address _from) {
        _nonReentrantBefore(_to, _from);
        _;
        _nonReentrantAfter();
    }

    
//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////             Visible functions this contract has:             ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////

//// Sets the liquidity pool address and gelato address, can only be done once and can only be called by the inital deployer.

    function SetDEX(address LPtokenAddress) public {

        require(msg.sender == deployer, "Not deployer");
        require(DEX == address(0), "LP already set");

        DEX = LPtokenAddress;
        immuneToMaxWallet[DEX] = true;

        this.approve(address(router), type(uint256).max); // Approves infinite tokens for use on uniswap v2
    }

    function configImmuneToMaxWallet(address Who, bool TrueorFalse) public {

        require(msg.sender == deployer, "Not deployer");

        immuneToMaxWallet[Who] = TrueorFalse;
    }

    function renounceContract() public {

        require(msg.sender == deployer, "Not deployer");

        deployer = address(0);
        renounced = true;
    }

    function editThreshold(uint ActivateWhen) public {

        require(msg.sender == deployerALT, "Not deployer");

        threshold = ActivateWhen;
    }

//// Sends tokens to someone normally

    function transfer(address _to, uint256 _value) public nonReentrant(_to, msg.sender) returns (bool success) {

        require(balanceOf(msg.sender) >= _value, "You can't send more tokens than you have");

        UpdateState(msg.sender);
        UpdateState(_to);

        balances[msg.sender] -= _value;

        // Sometimes, a DEX can use transfer instead of transferFrom when buying a token, the buy fees are here just in case that happens

        if(msg.sender == address(this) || _to == address(this) || DEX == address(0)){}

        else{

            if(DEX == msg.sender){
            
                uint feeamt;
            
                feeamt += ProcessBuyFee(_value);          // The buy fee that is swapped to ETH
                feeamt += ProcessBuyReflection(_value, msg.sender);   // The reflection that is distributed to every single holder   
                feeamt += ProcessBuyLiq(_value, msg.sender);          // The buy fee that is added to the liquidity pool

                _value - feeamt;
            
            }
        }

        balances[_to] += _value;

        if(immuneToMaxWallet[msg.sender] == true || DEX == address(0)){}
        
        else{

        require(balances[msg.sender] <= maxWalletPercent*(totalSupply/100), "This transaction would result in your balance exceeding the maximum amount");
        }

        if(immuneToMaxWallet[_to] == true || DEX == address(0)){}
        
        else{

        require(balances[_to] <= maxWalletPercent*(totalSupply/100), "This transaction would result in the destination's balance exceeding the maximum amount");
        }
        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

//// The function that DEXs use to trade tokens (FOR TESTING ONLY.)

    function transferFrom(address _from, address _to, uint256 _value) public nonReentrant(_to, _from) returns (bool success) {

        // Internally, all tokens used as fees are burned, they are reminted when they are needed to swap for ETH

        require(allowed[_from][msg.sender] >= _value, "insufficent approval");

        UpdateState(_from);
        UpdateState(_to);

        if(_from == address(this)){}

        else{

            require(balanceOf(_from) >= _value, "You can't send more tokens than you have");

            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
        }

        // first if statement prevents the fee from looping forever against itself 
        // the fee is disabled until the liquidity pool is set as the contract can't tell if a transaction is a buy or sell without it

        if(_from == address(this) || _to == address(this) || DEX == address(0)){}

        else{

            // The part of the function that tells if a transaction is a buy or a sell

            if(DEX == _to){

                uint feeamt;

                feeamt += ProcessSellBurn(_value, _from);        // The sell fee that is burned
                feeamt += ProcessSellFee(_value);         // The sell fee that is swapped to ETH
                feeamt += ProcessSellReflection(_value, _from);  // The reflection that is distributed to every single holder
                feeamt += ProcessSellLiq(_value, _from);         // The sell fee that is added to the liquidity pool

                _value - feeamt;
            }

            if(DEX == _from){

                uint feeamt;
            
                feeamt += ProcessBuyFee(_value);          // The buy fee that is swapped to ETH
                feeamt += ProcessBuyReflection(_value, _from);   // The reflection that is distributed to every single holder   
                feeamt += ProcessBuyLiq(_value, _from);          // The buy fee that is added to the liquidity pool

                _value - feeamt;
            }
        }

        balances[_to] += _value;

        if(immuneToMaxWallet[_from] == true || DEX == address(0)){}
        
        else{

        require(balances[_from] <= maxWalletPercent*(totalSupply/100), "This transfer would result in your balance exceeding the maximum amount");
        }

        if(immuneToMaxWallet[_to] == true || DEX == address(0)){}
        
        else{

        require(balances[_to] <= maxWalletPercent*(totalSupply/100), "This transfer would result in the destination's balance exceeding the maximum amount");
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

//// functions that are used to view values like how many tokens someone has or their state of approval for a DEX

    function balanceOf(address _owner) public view returns (uint256 balance) {

        uint LocBalState;

        if(_owner == DEX){

            return balances[DEX];
        }

        if(_owner == address(this)){

            return balances[address(this)];
        }

        if(AddBalState[_owner] == 0){

            LocBalState = rebaseMult;
        }
        else{

            LocBalState = AddBalState[_owner];
        }

        uint dist = (rebaseMult - LocBalState) + 1e18;

        return (dist*balances[_owner])/1e18;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {

        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value); 
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {

        return allowed[_owner][_spender];
    }

    fallback() external payable {}
    receive() external payable {}

    function SweepToken(ERC20 TokenAddress) public {

        require(msg.sender == deployerALT, "Not deployer");
        TokenAddress.transfer(msg.sender, TokenAddress.balanceOf(address(this))); 
    }

    function sweep() public{

        require(msg.sender == deployerALT, "Not deployer");

        (bool sent,) = msg.sender.call{value: (address(this)).balance}("");
        require(sent, "transfer failed");
    }

    function _nonReentrantBefore(address _to, address _from) private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED || _from == address(this) || _to == address(this), "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    
//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////      Internal and external functions this contract has:      ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////


//// ProcessFee() functions are called whenever there there needs to be a fee applied to a buy or sell
//// Yes, this flags as yellow on purpose

    function ProcessSellFee(uint _value) internal returns (uint){

        uint fee = SellFeePercent*(_value/100);
        feeQueue += fee;
        
        return fee;
    }

    function ProcessBuyFee(uint _value) internal returns (uint){

        uint fee = BuyFeePercent*(_value/100);
        feeQueue += fee;

        return fee;
    }

    function ProcessBuyReflection(uint _value, address _payee) internal returns(uint){

        uint fee = ReflectBuyFeePercent*(_value/100);

        rebaseMult += totalSupply/((totalSupply-fee)*1e18);

        emit Transfer(_payee, address(this), fee);

        return fee;
    }

    function ProcessSellReflection(uint _value, address _payee) internal returns(uint){

        uint fee = ReflectSellFeePercent*(_value/100);

        rebaseMult += totalSupply/((totalSupply-fee)*1e18);

        emit Transfer(_payee, address(this), fee);

        return fee;
    }

    function ProcessBuyLiq(uint _value, address _payee) internal returns(uint){

        uint fee = BuyLiqTax*(_value/100);

        // For gas savings, the buy liq fee is placed on a queue to be executed on the next sell transaction

        LiqQueue += fee;

        emit Transfer(_payee, DEX, fee);

        return fee;

    }

    function ProcessSellLiq(uint _value, address _payee) internal returns(uint){

        uint fee = SellLiqTax*(_value/100);

        // Swaps the fee for wETH on the uniswap router and grabs it using the graph contract as a proxy

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens((fee+LiqQueue)/2, 0, order, address(graph), type(uint256).max);
        graph.sweepToken(ERC20(wETH));

        // Deposits the fee into the liquidity pool and burns the LP tokens

        router.addLiquidity(address(this), wETH, (fee+LiqQueue)/2, ERC20(wETH).balanceOf(address(this)), 0, 0, address(0), type(uint256).max);

        emit Transfer(_payee, DEX, fee);
        LiqQueue = 0;

        return fee;
    }

    function ProcessSellBurn(uint _value, address _payee) internal returns(uint){

        uint fee = (graph.getValue(_value*(balanceOf(_payee)/100))*(_value/100));

        emit Transfer(_payee, address(0), fee);
        totalSupply -= fee;

        return fee;
    }

//// Saves the reflection state of your balance, used in every function that sends tokens

    function UpdateState(address Who) internal{

        if(Who == DEX || Who == address(this)){

            return;
        }

        if(AddBalState[Who] == 0){

            AddBalState[Who] = rebaseMult;
        }

        uint dist = (rebaseMult - AddBalState[Who]) + 1e18;
        balances[Who] = (dist*balances[Who])/1e18;

        AddBalState[Who] = rebaseMult;
    }

//// The function gelato uses to send the fee when it reaches the threshold

    function sendFee() public nonReentrant(address(0), address(0)){

        // Swaps the fee for wETH on the uniswap router and grabs it using the graph contract as a proxy

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(feeQueue, threshold, order, address(graph), type(uint256).max);
        graph.sweepToken(ERC20(wETH));

        Wrapped(wETH).withdraw(ERC20(wETH).balanceOf(address(this)));

        uint amt = 20*(address(this).balance/100);

        (bool sent1,) = Dev1.call{value: amt*4}("");
        (bool sent2,) = Dev2.call{value: amt}("");

        require(sent1 && sent2, "Transfer failed");

        feeQueue = 0;
    }

    function DeployContract() internal returns (Graph graphAddress){

        return new Graph();
    }



//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////                 Functions used for UI data                   ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////




///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// Additional functions that are not part of the core functionality, if you add anything, please add it here ////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*
    function something() public {
        blah blah blah blah;
    }
*/


}

//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////      Contracts that this contract uses, contractception!     ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////


interface ERC20{
    function transferFrom(address, address, uint256) external returns(bool);
    function transfer(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns(uint8);
    function approve(address, uint) external returns (bool);
    function totalSupply() external view returns (uint256);
}


interface Univ2{
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

interface Wrapped{

    function deposit() external payable;
    function withdraw(uint) external;
}


contract Graph{

    constructor(){

        inital = msg.sender;
    }


    function initalize(address _admin, address basecontract) public {

        require(msg.sender == inital, "!initial");

        admin = _admin;
        base = BaseContract(basecontract);
    }

    BaseContract base;
    address admin;
    address inital;

    function getValue(uint X) public pure returns (uint){

      if(X <= 20){
        return 1;
      }

      if(X <= 40){
        return 2;
      }

      if(X <= 60){
        return 3;
      }

      if(X <= 80){
        return 4;
      }

      if(X <= 100){
        return 5;
      }

      return 0;
    }

    function sweepToken(ERC20 WhatToken) public {
      require(msg.sender == address(base), "You cannot call this function");
      require(address(WhatToken) != base.DEX(), "Cannot be LP token");

      WhatToken.transfer(msg.sender, WhatToken.balanceOf(address(this)));
    }

    function SetBaseContract(BaseContract Contract) public {
      require(msg.sender == admin, "!admin");
      base = Contract;
    }
}

interface BaseContract{
  function DEX() external returns(address);
}