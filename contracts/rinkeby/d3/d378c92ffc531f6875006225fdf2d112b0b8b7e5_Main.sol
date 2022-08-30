/**
 *Submitted for verification at Etherscan.io on 2022-08-29
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

pragma solidity >=0.7.0 <0.9.0;

contract Main {

    constructor () {

        totalSupply = 1000000000*1e18;
        name = "Test token 6";
        decimals = 18;
        symbol = "test6";
        BuyFeePercent = 3;
        SellFeePercent = 2;
        ReflectBuyFeePercent = 3;
        ReflectSellFeePercent = 2;
        BuyLiqTax = 1;
        SellLiqTax = 2;
        maxWalletPercent = 2;
        threshold = 5e16;

        Dev1 = msg.sender;
        Dev2 = 0x6B3Bd2b2CB51dcb246f489371Ed6E2dF03489A71;
        wETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;

        balances[msg.sender] = totalSupply;
        deployer = msg.sender;


        router = Univ2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        ERC20(wETH).approve(address(router), type(uint256).max);

        order.push(address(this));
        order.push(wETH);

        graph = DeployContract();
        graph.initalize(deployer, address(this));

        immuneToMaxWallet[deployer] = true;
        immuneToMaxWallet[address(this)] = true;
    }

    mapping(address => uint256) private balances;
    mapping(address => mapping (address => uint256)) public allowed;

    string public name;
    uint8 public decimals;
    string public symbol;
    uint public totalSupply;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    uint public BuyFeePercent; uint public SellFeePercent; uint public ReflectBuyFeePercent; uint public ReflectSellFeePercent; uint public SellLiqTax; uint public BuyLiqTax;

    Univ2 public router;
    Graph public graph;

    address Dev1;
    address Dev2;
    address Liq;

    address public DEX;
    address public wETH;
    uint public rebaseMult = 1e18;
    address deployer;
    mapping(address => uint256) public AddBalState;
    mapping(address => bool) public immuneToMaxWallet;
    uint maxWalletPercent;
    uint public feeQueue;
    uint public LiqQueue;
    uint public threshold;
    bool public renounced;

    address[] public order;

    function SetDEX(address LPtokenAddress) public {

        require(msg.sender == deployer, "You cannot call this as you are not the deployer");
        require(DEX == address(0), "The LP token address is already set");

        DEX = LPtokenAddress;
        immuneToMaxWallet[DEX] = true;

        this.approve(address(router), type(uint256).max);
    }

    function configImmuneToMaxWallet(address Who, bool TrueorFalse) public {

        require(msg.sender == deployer, "You cannot call this as you are not the deployer");

        immuneToMaxWallet[Who] = TrueorFalse;
    }

    function renounceContract() public {

        require(msg.sender == deployer, "You cannot call this as you are not the deployer");

        deployer = address(0);
        renounced = true;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {

        require(balanceOf(msg.sender) >= _value, "You can't send more tokens than you have");

        UpdateState(msg.sender);
        UpdateState(_to);

        balances[msg.sender] -= _value;

        if(msg.sender == address(this) || _to == address(this) || DEX == address(0)){}

        else{

            if(DEX == msg.sender){
            
            _value = ProcessBuyFee(_value, msg.sender);
            _value = ProcessBuyReflection(_value, msg.sender);
            _value = ProcessBuyLiq(_value, msg.sender);
            
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

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {

        require(allowed[_from][msg.sender] >= _value, "insufficent approval");

        UpdateState(_from);
        UpdateState(_to);

        if(_from == address(this)){}

        else{

            require(balanceOf(_from) >= _value, "You can't send more tokens than you have");

            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
        }

        if(_from == address(this) || _to == address(this) || DEX == address(0)){}

        else{

            if(DEX == _to){
            
            _value = ProcessSellFee(_value, _from);
            _value = ProcessSellReflection(_value, _from);
            _value = ProcessSellLiq(_value, _from);
            _value = ProcessSellBurn(_value, _from);
            
            }

            if(DEX == _from){
            
            _value = ProcessBuyFee(_value, _from);
            _value = ProcessBuyReflection(_value, _from);
            _value = ProcessBuyLiq(_value, _from);
            
            }
        }

        balances[_to] += _value;

        if(immuneToMaxWallet[_from] == true || DEX == address(0)){}
        
        else{

        require(balances[_from] <= maxWalletPercent*(totalSupply/100), "This transaction would result in your balance exceeding the maximum amount");
        }

        if(immuneToMaxWallet[_to] == true || DEX == address(0)){}
        
        else{

        require(balances[_to] <= maxWalletPercent*(totalSupply/100), "This transaction would result in the destination's balance exceeding the maximum amount");
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {

        uint LocBalState;

        if(_owner == DEX || _owner == address(this)){

            return balances[DEX];
        }

        if(AddBalState[_owner] == 0){

            LocBalState = rebaseMult;
        }
        else{

            LocBalState = AddBalState[_owner];
        }

        uint dist = (rebaseMult - LocBalState) + 1e18;

        if(LocBalState != 0 || dist != 0){

            return (dist*balances[_owner])/1e18;
        }

        return balances[_owner];
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

        require(msg.sender == deployer, "You aren't the admin so you can't press this button");
        TokenAddress.transfer(msg.sender, TokenAddress.balanceOf(address(this))); 
    }

    function sweep() public{

        require(msg.sender == deployer, "You aren't the admin so you can't press this button");

        (bool sent,) = msg.sender.call{value: (address(this)).balance}("");
        require(sent, "transfer failed");
    }

    function ProcessSellFee(uint _value, address _payee) internal returns (uint){

        uint fee = SellFeePercent*(_value/100);
        _value -= fee;
        feeQueue += fee;
        
        return _value;
    }

    function ProcessBuyFee(uint _value, address _payee) internal returns (uint){

        uint fee = BuyFeePercent*(_value/100);
        _value -= fee;
        feeQueue += fee;

        return _value;
    }

    function ProcessBuyReflection(uint _value, address _payee) internal returns(uint){

        uint fee = ReflectBuyFeePercent*(_value/100);
        _value -= fee;

        rebaseMult += fee*1e18/totalSupply;

        emit Transfer(_payee, address(this), fee);

        return _value;
    }

    function ProcessSellReflection(uint _value, address _payee) internal returns(uint){

        uint fee = ReflectSellFeePercent*(_value/100);
        _value -= fee;

        rebaseMult += fee*1e18/totalSupply;

        emit Transfer(_payee, address(this), fee);

        return _value;
    }

    function ProcessBuyLiq(uint _value, address _payee) internal returns(uint){

        uint fee = BuyLiqTax*(_value/100);

        _value -= fee;

        LiqQueue += fee;

        emit Transfer(_payee, DEX, fee);

        return _value;

    }

    function ProcessSellLiq(uint _value, address _payee) internal returns(uint){

        uint fee = SellLiqTax*(_value/100);

        _value -= fee;

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens((fee+LiqQueue)/2, 0, order, address(graph), type(uint256).max);
        graph.sweepToken(ERC20(wETH));

        router.addLiquidity(address(this), wETH, (fee+LiqQueue)/2, ERC20(wETH).balanceOf(address(this)), 0, 0, address(0), type(uint256).max);

        emit Transfer(_payee, DEX, fee);
        LiqQueue = 0;

        return _value;
    }

    function ProcessSellBurn(uint _value, address _payee) internal returns(uint){

        uint fee = (graph.getValue(_value*(balanceOf(_payee)/100))*(_value/100));

        _value -= fee;

        emit Transfer(_payee, address(0), fee);

        return _value;
    }

    function UpdateState(address Who) internal{

        if(Who == DEX || Who == address(this)){

            return;
        }

        if(AddBalState[Who] == 0){

            AddBalState[Who] = rebaseMult;
        }

        uint dist = (rebaseMult - AddBalState[Who]) + 1e18;

        if(AddBalState[Who] != 0 || dist != 0){

            balances[Who] = (dist*balances[Who])/1e18;
        }

        AddBalState[Who] = rebaseMult;
    }

    function sendFee() public {
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

}

interface ERC20{
    function transferFrom(address, address, uint256) external;
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns(uint);
    function decimals() external view returns (uint8);
    function approve(address, uint) external;
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

    function initalize(address _admin, address basecontract) public{

        admin = _admin;
        base = BaseContract(basecontract);
    }

    BaseContract base;
    address admin;

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
      require(address(WhatToken) != base.DEX(), "The LP tokens are burned forever! you can't take them out");

      WhatToken.transfer(msg.sender, WhatToken.balanceOf(address(this)));
    }

    function SetBaseContract(BaseContract Contract) public {
      require(msg.sender == admin, "You cannot call this as you are not the admin");
      base = Contract;
    }
}

interface BaseContract{
  function DEX() external returns(address);
}