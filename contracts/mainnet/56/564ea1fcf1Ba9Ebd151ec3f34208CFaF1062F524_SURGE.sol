/**
 *Submitted for verification at Etherscan.io on 2023-01-07
*/

//SPDX-License-Identifier: MIT

/** 
 * Contract: Surge Token
 * Developed by: Heisenman
 * Team: t.me/ALBINO_RHINOOO, t.me/Heisenman, t.me/STFGNZ 
 * Trade without dex fees. $SURGE is the inception of the next generation of decentralized protocols.
 * Socials:
 * TG: https://t.me/SURGEPROTOCOL
 * Website: https://surgeprotocol.io/
 * Twitter: https://twitter.com/SURGEPROTOCOL
 */

pragma solidity ^0.8.17;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

interface IPancakePair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract SURGE is IERC20, Context, Ownable, ReentrancyGuard {

    event Bought(address indexed from, address indexed to,uint256 tokens, uint256 beans,uint256 dollarBuy);
    event Sold(address indexed from, address indexed to,uint256 tokens, uint256 beans,uint256 dollarSell);

    // token data
    string constant private _name = "SURGE";
    string constant private  _symbol = "SURGE";
    uint8 constant private _decimals = 9;
    uint256 constant private _decMultiplier = 10**_decimals;

    // Total Supply
    uint256 public _totalSupply = 10**8*_decMultiplier;

    // balances
    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;

    //Fees
    mapping (address => bool) public isFeeExempt;
    uint256 public sellMul = 95;
    uint256 public buyMul = 95;
    uint256 public constant DIVISOR = 100;

    //Max bag requirements
    mapping (address => bool) public isTxLimitExempt;
    uint256 public maxBag = _totalSupply/100;
    
    //Tax collection
    uint256 public taxBalance = 0;

    //Tax wallets
    address public teamWallet = 0xDa17D158bC42f9C29E626b836d9231bB173bab06;
    address public treasuryWallet = 0xF526A924c406D31d16a844FF04810b79E71804Ef ;

    // Tax Split
    uint256 public teamShare = 40;
    uint256 public treasuryShare = 60;
    uint256 public shareDIVISOR = 100;

    //Known Wallets
    address constant private DEAD = 0x000000000000000000000000000000000000dEaD;

    //trading parameters
    uint256 public liquidity = 4 ether;
    uint256 public liqConst= liquidity*_totalSupply;
    uint256 public tradeOpenTime = 1673125200;

    //volume trackers
    mapping (address => uint256) public indVol;
    mapping (uint256 => uint256) public tVol;
    uint256 public totalVolume = 0;

    //candlestick data
    uint256 public totalTx;
    mapping(uint256 => uint256) public txTimeStamp;

    struct candleStick{ 
        uint256 time;
        uint256 open;
        uint256 close;
        uint256 high;
        uint256 low;
    }

    mapping(uint256 => candleStick) public candleStickData;

    //Frontrun Gaurd
    mapping(address => uint256) private lastBuyBlock;

    // initialize supply
    constructor(
    ) {
        _balances[address(this)] = _totalSupply;

        isFeeExempt[msg.sender] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[address(0)] = true;

        emit Transfer(address(0), address(this), _totalSupply);
    }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint).max);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply-_balances[DEAD];
    }

    function changeWalletLimit(uint256 newLimit) external onlyOwner {
        require(newLimit >= _totalSupply/100);
        maxBag  = newLimit;
    }
    
    function changeIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function changeIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    /** Transfer Function */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    /** Transfer Function */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(sender == msg.sender);
        return _transferFrom(sender, recipient, amount);
    }
    
    /** Internal Transfer */
    function _transferFrom(address sender, address recipient, uint256 amount) internal nonReentrant returns (bool) {
        // make standard checks
        require(recipient != address(0) && recipient != address(this), "transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(isTxLimitExempt[recipient]||_balances[recipient] + amount <= maxBag);
        // subtract from sender
        _balances[sender] = _balances[sender] - amount;
        // give reduced amount to receiver
        _balances[recipient] = _balances[recipient] + amount;
        // Transfer Event
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    //tx timeout modifier
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, "Deadline EXPIRED");
        _;
    }

    /** Purchases SURGE Tokens and Deposits Them in Sender's Address*/
    function _buy(uint256 minTokenOut, uint256 deadline) public nonReentrant ensure(deadline) payable returns (bool) {
        lastBuyBlock[msg.sender]=block.number;

        // liquidity is set and trade is open
        require(liquidity > 0 && block.timestamp>= tradeOpenTime, "The token has no liquidity or trading not open");
     
        //remove the buy tax
        uint256 bnbAmount = isFeeExempt[msg.sender] ? msg.value : msg.value * buyMul / DIVISOR;
        
        // how much they should purchase?
        uint256 tokensToSend = _balances[address(this)]-(liqConst/(bnbAmount+liquidity));
        
        //revert for max bag
        require(_balances[msg.sender] + tokensToSend <= maxBag || isTxLimitExempt[msg.sender],"Max wallet exceeded");

        // revert if under 1
        require(tokensToSend > 1,'Must Buy more than 1 decimal of Surge');

        // revert for slippage
        require(tokensToSend >= minTokenOut,'INSUFFICIENT OUTPUT AMOUNT');

        // transfer the tokens from CA to the buyer
        buy(msg.sender, tokensToSend);

        //update available tax to extract and Liquidity
        uint256 taxAmount = msg.value - bnbAmount;
        taxBalance = taxBalance + taxAmount;
        liquidity = liquidity + bnbAmount;

        //update volume
        uint cTime = block.timestamp;
        uint dollarBuy = msg.value*getBNBPrice();
        totalVolume += dollarBuy;
        indVol[msg.sender]+= dollarBuy;
        tVol[cTime]+=dollarBuy;

        //update candleStickData
        totalTx+=1;
        txTimeStamp[totalTx]= cTime;
        uint cPrice = calculatePrice()*getBNBPrice();
        candleStickData[cTime].time= cTime;
        if(candleStickData[cTime].open == 0){
            if(totalTx==1)
            {
            candleStickData[cTime].open = (liquidity-bnbAmount)/(_totalSupply)*getBNBPrice();
            }
            else {candleStickData[cTime].open = candleStickData[txTimeStamp[totalTx-1]].close;}
        }
        candleStickData[cTime].close = cPrice;
        
        if(candleStickData[cTime].high < cPrice || candleStickData[cTime].high==0){
            candleStickData[cTime].high = cPrice;
        }

          if(candleStickData[cTime].low > cPrice || candleStickData[cTime].low==0){
            candleStickData[cTime].low = cPrice;
        }

        //emit transfer and buy events
        emit Transfer(address(this), msg.sender, tokensToSend);
        emit Bought(msg.sender, address(this), tokensToSend, msg.value,bnbAmount*getBNBPrice());
        return true;
    }
    
    /** Sends Tokens to the buyer Address */
    function buy(address receiver, uint amount) internal {
        _balances[receiver] = _balances[receiver] + amount;
        _balances[address(this)] = _balances[address(this)] - amount;
    }

    /** Sells SURGE Tokens And Deposits the BNB into Seller's Address */
    function _sell(uint256 tokenAmount, uint256 deadline, uint256 minBNBOut) public nonReentrant ensure(deadline) payable returns (bool) {
        require(lastBuyBlock[msg.sender]!=block.number);
        require(msg.value == 0);
        
        address seller = msg.sender;
        
        // make sure seller has this balance
        require(_balances[seller] >= tokenAmount, 'cannot sell above token amount');
        
        // get how much beans are the tokens worth
        uint256 amountBNB = liquidity - (liqConst/(_balances[address(this)]+tokenAmount));
        uint256 amountTax = amountBNB * (DIVISOR - sellMul)/DIVISOR;
        uint256 BNBToSend = amountBNB - amountTax;
        
        //slippage revert
        require(amountBNB >= minBNBOut);

        // send BNB to Seller
        (bool successful,) = isFeeExempt[msg.sender] ? payable(seller).call{value: amountBNB, gas:40000}(""): payable(seller).call{value: BNBToSend, gas:40000}(""); 
        require(successful);

        // subtract full amount from sender
        _balances[seller] = _balances[seller] - tokenAmount;

        //add tax allowance to be withdrawn and remove from liq the amount of beans taken by the seller
        taxBalance = isFeeExempt[msg.sender] ? taxBalance : taxBalance + amountTax;
        liquidity = liquidity - amountBNB;

        // add tokens back into the contract
        _balances[address(this)]=_balances[address(this)]+ tokenAmount;

        //update volume
        uint cTime = block.timestamp;
        uint dollarSell= amountBNB*getBNBPrice();
        totalVolume += dollarSell;
        indVol[msg.sender]+= dollarSell;
        tVol[cTime]+=dollarSell;

        //update candleStickData
        totalTx+=1;
        txTimeStamp[totalTx]= cTime;
        uint cPrice = calculatePrice()*getBNBPrice();
        candleStickData[cTime].time= cTime;
        if(candleStickData[cTime].open == 0){
            candleStickData[cTime].open = candleStickData[txTimeStamp[totalTx-1]].close;
        }
        candleStickData[cTime].close = cPrice;
        
        if(candleStickData[cTime].high < cPrice || candleStickData[cTime].high==0){
            candleStickData[cTime].high = cPrice;
        }

          if(candleStickData[cTime].low > cPrice || candleStickData[cTime].low==0){
            candleStickData[cTime].low = cPrice;
        }

        // emit transfer and sell events
        emit Transfer(seller, address(this), tokenAmount);
        if(isFeeExempt[msg.sender]){
            emit Sold(address(this), msg.sender,tokenAmount,amountBNB,dollarSell);
        }
        
        else{ emit Sold(address(this), msg.sender,tokenAmount,BNBToSend,BNBToSend*getBNBPrice());}
        return true;
    }
    
    /** Amount of BNB in Contract */
    function getLiquidity() public view returns(uint256){
        return liquidity;
    }

    /** Returns the value of your holdings before the sell fee */
    function getValueOfHoldings(address holder) public view returns(uint256) {
        return _balances[holder]*liquidity/_balances[address(this)]*getBNBPrice();
    }

    function changeFees(uint256 newbuyMul, uint256 newsellMul) external onlyOwner {
        require( newbuyMul >= 90 && newsellMul >= 90 && newbuyMul <=100 && newsellMul<= 100, 'Fees are too high');

        buyMul = newbuyMul;
        sellMul = newsellMul;
    }

    function changeTaxDistribution(uint newteamShare, uint newtreasuryShare) external onlyOwner {
        require(newteamShare + newtreasuryShare == 100);

        teamShare = newteamShare;
        treasuryShare = newtreasuryShare;
    }

    function changeFeeReceivers(address newTeamWallet, address newTreasuryWallet) external onlyOwner {
        teamWallet = newTeamWallet;
        treasuryWallet = newTreasuryWallet;
    }

    function withdrawTaxBalance() external nonReentrant() payable onlyOwner {
        (bool temp1,)= payable(teamWallet).call{value:taxBalance*teamShare/shareDIVISOR}("");
        (bool temp2,)= payable(treasuryWallet).call{value:taxBalance*treasuryShare/shareDIVISOR}("");
        assert(temp1 && temp2);
        taxBalance = 0; 
    }

    function getTokenAmountOut(uint256 amountBNBIn) external view returns (uint256) {
        uint256 amountAfter = liqConst/(liquidity-amountBNBIn);
        uint256 amountBefore = liqConst/liquidity;
        return amountAfter-amountBefore;
    }

    function getBNBAmountOut(uint256 amountIn) public view returns (uint256) {
        uint256 beansBefore = liqConst / _balances[address(this)];
        uint256 beansAfter = liqConst / (_balances[address(this)] + amountIn);
        return beansBefore-beansAfter;
    }

    function addLiquidity() external onlyOwner payable {
        uint256 tokensToAdd= _balances[address(this)]*msg.value/liquidity;
        require(_balances[msg.sender]>= tokensToAdd);

        uint256 oldLiq = liquidity;
        liquidity = liquidity+msg.value;
        _balances[address(this)]+= tokensToAdd;
        _balances[msg.sender]-= tokensToAdd;
        liqConst= liqConst*liquidity/oldLiq;

        emit Transfer(msg.sender, address(this),tokensToAdd);
    }

    function getMarketCap() external view returns(uint256){
        return (getCirculatingSupply()*calculatePrice()*getBNBPrice());
    }

    address private stablePairAddress = 0x7BeA39867e4169DBe237d55C8242a8f2fcDcc387;
    address private stableAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    function changeStablePair(address newStablePair, address newStableAddress) external{
        stablePairAddress = newStablePair;
        stableAddress = newStableAddress;
    }

   // calculate price based on pair reserves
   function getBNBPrice() public view returns(uint)
   {
    IPancakePair pair = IPancakePair(stablePairAddress);
    IERC20 token1 = pair.token0() == stableAddress? IERC20(pair.token1()):IERC20(pair.token0()); 
    
    (uint Res0, uint Res1,) = pair.getReserves();

    if(pair.token0() != stableAddress){(Res1,Res0,) = pair.getReserves();}
    uint res0 = Res0*10**token1.decimals();
    return(res0/Res1); // return amount of token0 needed to buy token1
   }

    // Returns the Current Price of the Token in beans
    function calculatePrice() public view returns (uint256) {
        require(liquidity>0,'No Liquidity');
        return liquidity/_balances[address(this)];
    }
}