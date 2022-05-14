// SPDX-License-Identifier: No License

import "./Library.sol";

pragma solidity ^0.8.7;



//Fibonacci Token (FIB). An innovative token originally invented by @Nov

// t.me/FibonacciToken

/*                                               @@@@[email protected]@@[email protected]@@@                              
                                          @@[email protected]@                      
                                    @@[email protected]                
                               @@[email protected]             
                            @[email protected]          
                        @.[email protected]         
                     @......[email protected]       
                   @.........................................................................&     
                 @.............[email protected]    
              @.................[email protected]   
             @...................[email protected]  
           @......................[email protected] 
          @........................[email protected] 
        @..........................[email protected] 
       @...........................[email protected] 
      @.......................................................    @@@[email protected]@  ,,,,,,,,,,,,,,,,,,,,,,@ 
     @........................................................ @[email protected] @,,,,,,,,,,,,,,,,,,,,,,@ 
    @[email protected]@..,,, @,,,,,,,,,,,,,,,,,,,,,@  
   @[email protected][email protected]@,@  ,,,,,,,,,,,,,,,,,,,,@   
  @[email protected]........,,,,,,,,,,,,,,,,,,,@    
  @[email protected]........,,,,,,,,,,,,,,,,,@      
 @........................................................... @............,,,,,,,,,,,,,,,@        
 @...........................................................   @..........,,,,,,,,,,,,,@          
 @...........................................................      @.......,,,,,,,,@@              
 
 
 
 
 */

//Update this version also has increasing fees that resets in a certain amount of time (1 day default) from your last sell or tx.
                                                                                                    
//Fiobonacci Token is a token that does not let price drop below a certain point 0.618 ratio from ATH for default.
//Every new ATH sets the price floor a new high, So price will be lifted at all times.
//This is against BNB not any stable token is BNB price drops any chart indicator will show you price is dropped below the threshold, this is not the case 
//Please look BNB pairing for charts not USD if you wanna see the real movements against BNB.

//Also apart from that , there is increased tax for investors who sell at close or at ATH. (About %5 percent near ATH).

//From psychological point of view I concluded these results:

//Token is self "marketing" or "shilling" , If you bought this token and price is below a certain point you will need other people to invest to gain access to your funds.
//So , any normal investor would "shill" their token to others , this would create a snowball effect and cycle would repeat with more people everytime.
//Normally when a token's price crashes people would just accept it and move on , this is not the case here.

//Selling close to ATH is a %12.5 percent loss for the maker. So any logical person would wait others to drop the price %5 percent before selling
//But if most people thinks like that amount of sell pressure at ATH is lowered by a lot.



//There is classic reflection and liquidity and burn traits of token which you can see below ( default is %0.5 , %3 , %0.5)
//Max wallet is %1.
//I do have a small dev fee %0.5 , but can be increased to 1.5% if something happens and i need funds for the token , (Maybe a marketing , or a new liquidity for other DEX etc.);
//I cannot increase dev fees beyond 1.5% contract does not allow that.

//Invest only what you can afford to lose.
//Price might be mathematically set to increase , BUT IF NO ONE BUYS THE TOKEN IT WILL STUCK !!!! BE CAREFUL WITH YOUR INVESTMENTS!!!.

//This is an experiment on BSC.Lets see if it goes viral.

//Disclaimer: By acquiring this token , you accept your own risks.

contract Fibonacci is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;


    mapping(address => uint256) private _dumpTaxes;
    mapping(address => uint256) private _dumpTaxesBlockTime;


    uint256 private constant MAX_EXCLUDED = 1024;
    EnumerableSet.AddressSet private _isExcludedFromReward;
    EnumerableSet.AddressSet private _isExcludedFromFee;
    EnumerableSet.AddressSet private _isExcludedFromSwapAndLiquify;

    EnumerableSet.AddressSet private _isBlackListed;
    EnumerableSet.AddressSet private _isWhiteListed;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 100000000 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 private _tFeeTotal;
    uint256 private _tBurnTotal;

    string private constant _name = "Fibonacci";
    string private constant _symbol = "FIB";
    uint8 private constant _decimals = 18;

    uint256 public _taxFeeVariable = 0;
    uint256 public _liquidityFeeVariable = 0;
    uint256 public _devFeeVariable = 0;
    uint256 public _burnFeeVariable = 0;


    uint256 public _taxFee = 0;
    uint256 public _liquidityFee = 0;
    uint256 public _devFee = 0;
    uint256 public _burnFee = 0;
    
    uint256 public _maxWalletSize = (_tTotal * 1) / 100; 
    
    uint256 private constant TOTAL_FEES_LIMIT = 2000;
    
    uint256 private constant DEV_FEES_LIMIT = 150;  //If needed.

    uint256 private constant MIN_TX_LIMIT = 100;
    uint256 public _maxTxAmount = 100000000 * 10**18;
    uint256 public _numTokensSellToAddToLiquidity = 20000 * 10**18;

    uint256 private _totalDevFeesCollected = 0;

    //Fibonacci Variables
    //They are multipled by 4 adding for Liq , Reflection , Burn and Dev fee.

    uint256 private constant ATH_DUMPER_FEE_MIN_LIMIT = 250;
    uint256 private constant ATH_DUMPER_FEE_MAX_LIMIT = 550;
    uint256 public _ATHDumperBurnAdd = 350;
 
    //Activates ATH Burn (max 17.5 percent.)
    uint256 private constant MIN_PER_ATH_LIMIT = 835;
    uint256 private constant MAX_PER_ATH_LIMIT = 975; 
    uint256 public PER_ATH_BURN_ACTIVATE = 950;
    
    uint256 _ATHPriceINBNB = 1000;
    
    //CurrentPrice but multipled by 10**20
    uint256 PriceNow = 1;
    uint256 MultPrecision = 10**20;
    
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    
    //Golden ratio cannot be set higher than 619. MAX is just in case something fail, halves the floor price.
    //1/3 = 3.333 MAX so this token only can drop 66 percent at ALL costs. (Against BNB)
    
    
    uint256 private constant  GoldenRatioDMAX = 333;
    //1/1.618 = 0.618 (Math is interesting)
    uint256 public  GoldenRatioDivider = 618 ;
    //Cant be honeypot
    uint256 private constant GoldenRatioDMIN = 900;
    uint256 private RatioNow = 1000;

    // Liquidity
    bool public _swapAndLiquifyEnabled = true;
    bool private _inSwapAndLiquify;

    IUniswapV2Router02 public _uniswapV2Router;
    address public _uniswapV2Pair;
    IUniswapV2Pair public uniSwapV2PairContract;


    address public pancakeRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;//0x10ED43C718714eb63d5aA57B78B54704E256024E;
   

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqudity
    );
    event DevFeesCollected(uint256 bnbCollected);

    modifier lockTheSwap() {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    constructor(address cOwner) Ownable(cOwner) {
        _rOwned[cOwner] = _rTotal;

        // Create a uniswap pair for this new token
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(pancakeRouter);
        _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _uniswapV2Router = uniswapV2Router;

        // Exclude system addresses from fee
        
         IUniswapV2Pair pairContract = IUniswapV2Pair(_uniswapV2Pair);
         uniSwapV2PairContract = pairContract;
        
        _isExcludedFromFee.add(owner());
        _isExcludedFromFee.add(address(this));
        _isExcludedFromSwapAndLiquify.add(_uniswapV2Pair);

        _isWhiteListed.add(address(this));
        _isWhiteListed.add(_uniswapV2Pair);
        _isWhiteListed.add(owner());


        _taxesForEachSell[0] = 25;
        _taxesForEachSell[1] = 75;
        _taxesForEachSell[2] = 175;
        _taxesForEachSell[3] = 180;
        _taxesForEachSell[4] = 200;
        _taxesForEachSell[5] = 350;
        _taxesForEachSell[6] = 740;
        _taxesForEachSell[7] = 1180;
        _taxesForEachSell[8] = 2500;
        _taxesForEachSell[9] = 12500;

        emit Transfer(address(0), cOwner, _tTotal);
    }

    receive() external payable {}

    // BEP20
    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromReward.contains(account)) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }
    
    
    //Fibonacci Price Checker Future
    function setPriceOfTokenSellFuture(uint256 soldBNB,uint256 golden) internal returns (uint256){

        uint256 FibonacciSupply; uint256 WBNB;

        //For some reason this gets swapped at every added liq.
       (uint256 token0,uint256 token1, uint256 blocktimestamp) = uniSwapV2PairContract.getReserves();
        
       if(token0 > token1){
           FibonacciSupply = token0;
            WBNB = token1;

       }
         else{
        
        FibonacciSupply = token1;
            WBNB = token0;
        
        }

        FibonacciSupply = FibonacciSupply.add(golden);
        WBNB = WBNB.sub(soldBNB);
        //Lets not blow up.
        if(FibonacciSupply == 0){
            
            return 1;
        }
        
        //Multipled by 10**20 to make division right;
         uint256 priceINBNB = (WBNB.mul(MultPrecision)).div(FibonacciSupply);
         
         
         if(priceINBNB > _ATHPriceINBNB){
             _ATHPriceINBNB = priceINBNB;
         }
         
         
        RatioNow = (priceINBNB.mul(1000)).div(_ATHPriceINBNB);
         
        return priceINBNB;
         
    } 


      function setPriceOfTokenBoughtFuture(uint256 addedBNB,uint256 soldgolden) internal returns (uint256){
        uint256 FibonacciSupply; uint256 WBNB;
    
        //For some reason this gets swapped at every added liq.
       (uint256 token0,uint256 token1, uint256 blocktimestamp) = uniSwapV2PairContract.getReserves();
        
        
       if(token0 > token1){
           FibonacciSupply = token0;
            WBNB = token1;

       }
         else{
        
        FibonacciSupply = token1;
            WBNB = token0;
        
        }


       FibonacciSupply = FibonacciSupply.sub(soldgolden);
       WBNB = WBNB.add(addedBNB);
        //Lets not blow up.
        if(FibonacciSupply == 0){
            
            return 1;
        }
        
        //Multipled by 10**20 to make division right;
         uint256 priceINBNB = (WBNB.mul(MultPrecision)).div(FibonacciSupply);
         
         
         if(priceINBNB > _ATHPriceINBNB){
             _ATHPriceINBNB = priceINBNB;
         }
         
         
        RatioNow = (priceINBNB.mul(1000)).div(_ATHPriceINBNB);
         
        return priceINBNB;
         
    } 


    function getPriceOfTokenNow() public view returns (uint256,uint256){
        return (RatioNow,_ATHPriceINBNB);        
    } 
    
    function getPriceOfTokenFuture(uint256 substractedBNB,uint256 addedGoldenRatio) public view returns (uint256){
              uint256 FibonacciSupply; uint256 WBNB;

        //For some reason this gets swapped at every added liq.
       (uint256 token0,uint256 token1, uint256 blocktimestamp) = uniSwapV2PairContract.getReserves();
        
        
       if(token0 > token1){
           FibonacciSupply = token0;
            WBNB = token1;
       }
         else{
        FibonacciSupply = token1;
            WBNB = token0;
        }
        //Lets not blow up.
        if(FibonacciSupply == 0){
            
            return 1;
        }

        //Multipled by 10**20 to make division right;
        uint256 totalGNow = FibonacciSupply.add(addedGoldenRatio);
        uint256 priceINBNB = ((WBNB.sub(substractedBNB)).mul(MultPrecision)).div(totalGNow);

        return priceINBNB;

    } 


    //10 is 1 percent.
    function setMaxWalletSize(uint256 maxWallet) external onlyOwner{
        require(maxWallet >= 10 , "Can't decerease maxwallet more than that.");
        _maxWalletSize = (_tTotal * maxWallet) / 10000; 

    }
    
    function setGoldenRatio(uint256 ratio) external onlyOwner{
        require(ratio > GoldenRatioDMAX,"Fibonacci cannot be lower than this.");
        require(ratio <= GoldenRatioDMIN,"Fibonacci cannot be higher than this.");
        GoldenRatioDivider = ratio;       

    }
    function setATHDumperFee(uint256 fee) external onlyOwner {
        require(fee <= ATH_DUMPER_FEE_MAX_LIMIT,"I know you want to punish them , but they are human too.");
        require(fee >= ATH_DUMPER_FEE_MIN_LIMIT, "I ain't that merciful.");
         _ATHDumperBurnAdd = fee;
    }

    function setATHDumperMaxPercent(uint256 feePercent) external onlyOwner {
        require(feePercent <= MAX_PER_ATH_LIMIT,"Can't increase ATH sell tax percentage more than this.");
        require(feePercent >= MIN_PER_ATH_LIMIT, "Can't decrease ATH sell tax percentage more than this.");
         PER_ATH_BURN_ACTIVATE = feePercent;
    }
    
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "BEP20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }

    // REFLECTION
    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(
            !_isExcludedFromReward.contains(sender),
            "Excluded addresses cannot call this function"
        );

        (, uint256 tFee, uint256 tLiquidity, uint256 tBurn) = _getTValues(
            tAmount
        );
        uint256 currentRate = _getRate();
        (uint256 rAmount, , ) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            tBurn,
            currentRate
        );

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");

        if (!deductTransferFee) {
            (, uint256 tFee, uint256 tLiquidity, uint256 tBurn) = _getTValues(
                tAmount
            );
            uint256 currentRate = _getRate();
            (uint256 rAmount, , ) = _getRValues(
                tAmount,
                tFee,
                tLiquidity,
                tBurn,
                currentRate
            );

            return rAmount;
        } else {
            (, uint256 tFee, uint256 tLiquidity, uint256 tBurn) = _getTValues(
                tAmount
            );
            uint256 currentRate = _getRate();
            (, uint256 rTransferAmount, ) = _getRValues(
                tAmount,
                tFee,
                tLiquidity,
                tBurn,
                currentRate
            );

            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );

        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(
            !_isExcludedFromReward.contains(account),
            "Account is already excluded in reward"
        );
        require(
            _isExcludedFromReward.length() < MAX_EXCLUDED,
            "Excluded reward set reached maximum capacity"
        );

        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedFromReward.add(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(
            _isExcludedFromReward.contains(account),
            "Account is already included in reward"
        );

        _isExcludedFromReward.remove(account);
        _tOwned[account] = 0;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function totalBurn() public view returns (uint256) {
        return _tBurnTotal;
    }

    function devPercentageOfLiquidity() public view returns (uint256) {
        return (_devFee * 10000) / (_devFee.add(_liquidityFee));
    }

    /**
        @dev This is the portion of liquidity that will be sent to the uniswap router.
        Dev fees are considered part of the liquidity conversion.
     */
    function pureLiquidityPercentage() public view returns (uint256) {
        return (_liquidityFee * 10000) / (_devFee.add(_liquidityFee));
    }

    function totalDevFeesCollected() external view onlyDev returns (uint256) {
        return _totalDevFeesCollected;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee.add(account);
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee.remove(account);
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner {
        require(
            taxFee.add(_liquidityFee).add(_devFee).add(_burnFee) <=
                TOTAL_FEES_LIMIT,
            "Total fees can not exceed the declared limit"
        );
        _taxFee = taxFee;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
        require(
            _taxFee.add(liquidityFee).add(_devFee).add(_burnFee) <=
                TOTAL_FEES_LIMIT,
            "Total fees can not exceed the declared limit"
        );
        _liquidityFee = liquidityFee;
    }

    function setDevFeePercent(uint256 devFee) external onlyOwner {
        require(
            devFee <= DEV_FEES_LIMIT,
            "Dev fees can not exceed the declared limit"
        );
        require(
            _taxFee.add(_liquidityFee).add(devFee).add(_burnFee) <=
                TOTAL_FEES_LIMIT,
            "Total fees can not exceed the declared limit"
        );
        _devFee = devFee;
    }

    function setBurnFeePercent(uint256 burnFee) external onlyOwner {
        require(
            _taxFee.add(_liquidityFee).add(_devFee).add(burnFee) <=
                TOTAL_FEES_LIMIT,
            "Total fees can not exceed the declared limit"
        );
        _burnFee = burnFee;
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        require(
            maxTxPercent <= 10000,
            "Maximum transaction limit percentage can't be more than 100%"
        );
        require(
            maxTxPercent >= MIN_TX_LIMIT,
            "Maximum transaction limit can't be less than the declared limit"
        );
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(10000);
    }

    function setMinLiquidityPercent(uint256 minLiquidityPercent)
        external
        onlyOwner
    {
        require(
            minLiquidityPercent <= 10000,
            "Minimum liquidity percentage percentage can't be more than 100%"
        );
        require(
            minLiquidityPercent > 0,
            "Minimum liquidity percentage percentage can't be zero"
        );
        _numTokensSellToAddToLiquidity = _tTotal.mul(minLiquidityPercent).div(
            10000
        );
    }

    function setSwapAndLiquifyEnabled(bool enabled) public onlyOwner {
        _swapAndLiquifyEnabled = enabled;
        emit SwapAndLiquifyEnabledUpdated(enabled);
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee.contains(account);
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedFromReward.contains(account);
    }

    function setIsExcludedFromSwapAndLiquify(address a, bool b)
        external
        onlyOwner
    {
        if (b) {
            _isExcludedFromSwapAndLiquify.add(a);
        } else {
            _isExcludedFromSwapAndLiquify.remove(a);
        }
    }

    function setUniswapRouter(address r) external onlyOwner {
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(r);
        _uniswapV2Router = uniswapV2Router;
    }

    function setUniswapPair(address p) external onlyOwner {
        _uniswapV2Pair = p;
    }
    

    // TRANSFER
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(to != devWallet(), "Dev wallet address cannot receive tokens");
        require(from != devWallet(), "Dev wallet address cannot send tokens");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner()) {
            require(
                amount <= _maxTxAmount,
                "Transfer amount exceeds the maxTxAmount."
            );
        }

        /*
            - swapAndLiquify will be initiated when token balance of this contract
            has accumulated enough over the minimum number of tokens required.
            - don't get caught in a circular liquidity event.
            - don't swapAndLiquify if sender is uniswap pair.
        */

        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        bool isOverMinTokenBalance = contractTokenBalance >=
            _numTokensSellToAddToLiquidity;
        if (
            isOverMinTokenBalance &&
            !_inSwapAndLiquify &&
            !_isExcludedFromSwapAndLiquify.contains(from) &&
            _swapAndLiquifyEnabled
        ) {
            swapAndLiquify(_numTokensSellToAddToLiquidity);
        }

        bool takeFee = true;
        if (
            _isExcludedFromFee.contains(from) || _isExcludedFromFee.contains(to)
        ) {
            takeFee = false;
        }
        _tokenTransfer(from, to, amount, takeFee);
    }

    function collectDevFees() public onlyDev {
        _totalDevFeesCollected = _totalDevFeesCollected.add(
            address(this).balance
        );
        devWallet().transfer(address(this).balance);
        emit DevFeesCollected(address(this).balance);
    }

    function swapAndLiquify(uint256 tokenAmount) private lockTheSwap {
        // This variable holds the liquidity tokens that won't be converted
        uint256 liqTokens = tokenAmount.mul(pureLiquidityPercentage()).div(
            20000
        );
        // Everything else from the tokens should be converted
        uint256 tokensForBnbExchange = tokenAmount.sub(liqTokens);
        // This would be in the non-percentage form, 0 (0%) < devPortion < 10000 (100%)
        // The devPortion here indicates the portion of the converted tokens (BNB) that
        // would be assigned to the devWallet
        uint256 devPortion = tokenAmount.mul(devPercentageOfLiquidity()).div(
            tokensForBnbExchange
        );

        uint256 initialBalance = address(this).balance;

        swapTokensForBnb(tokensForBnbExchange);

        // How many BNBs did we gain after this conversion?
        uint256 gainedBnb = address(this).balance.sub(initialBalance);

        // Calculate the amount of BNB that's assigned to devWallet
        uint256 balanceToDev = (gainedBnb.mul(devPortion)).div(10000);
        // The leftover BNBs are purely for liquidity
        uint256 liqBnb = gainedBnb.sub(balanceToDev);

        addLiquidity(liqTokens, liqBnb);

        emit SwapAndLiquify(tokensForBnbExchange, liqBnb, liqTokens);
    }

    function swapTokensForBnb(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // Add the liquidity
        _uniswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            lockedLiquidity(),
            block.timestamp
        );
    }

    //These are required for adding Liq and potential save mechanism if something fails
    //When shutdowncancel activated Owner can no longer interfere.
    bool AthThingEnabled = true;

    function setFeesToZero() external onlyOwner{
        
        _taxFeeVariable = 0;
        _liquidityFeeVariable = 0;
        _devFeeVariable = 0;
        _burnFeeVariable = 0;

    }

    function setFeesBackToDefault() external onlyOwner{

        _taxFee = 50;
        _liquidityFee = 300;
        _devFee = 150;
        _burnFee = 50;
   

    }

    function setFeesBackToNormalInternal() internal {

        _taxFeeVariable = _taxFee;
        _liquidityFeeVariable = _liquidityFee;
        _devFeeVariable = _devFee;
        _burnFeeVariable = _burnFee;
   

    }

    function setATHthingEnabled(bool isit) external onlyOwner{
        AthThingEnabled = isit;
    }

    function setFeeResetTime(uint256 time) external onlyOwner{
        feeResetTime = time;
    }

    uint256 feeResetTime = 60*60*24*14; //2 Weeks
    bool cancelSellConstraints  = false;
    bool canCancel = true;

    function ShutDownCancel() external onlyOwner{
        cancelSellConstraints = true;
        canCancel = false;
    }
    function setSellContraints(bool what) external onlyOwner{
        if(canCancel){
            cancelSellConstraints = what;
        }
    }

    //Sets increasing tax enabled.
    bool private increasingTax = false;
    function setIncreasingTaxForSellsEnabled(bool what) external onlyOwner{
        if(canCancel){
        increasingTax = what;
        }
    }

    //If something fails and tax are getting added constantly this function will be activated.
    bool private setToNormalOnSomeError  = false;
        function setToNormalOnAnyError(bool what) external onlyOwner{
        setToNormalOnSomeError = what;
    }

    function addATHFees() internal returns (bool) {
        bool ATHsAdded = false;
        if(AthThingEnabled){
        if(RatioNow > PER_ATH_BURN_ACTIVATE){   
             ATHsAdded = true;            
             _liquidityFeeVariable += _ATHDumperBurnAdd;
             _burnFeeVariable += _ATHDumperBurnAdd;
             _taxFeeVariable += _ATHDumperBurnAdd;
             _devFeeVariable += _ATHDumperBurnAdd;
                }
              }
        return ATHsAdded;  
    
    }
    
    mapping(uint256 => uint256) private _taxesForEachSell;

    function setTaxesByAmount(uint256 taxnumber,uint256 tax) external onlyOwner{
        _taxesForEachSell[taxnumber] = tax; 
    }

    function setTaxesToDefaultForSellTaxes() external onlyOwner(){
        _taxesForEachSell[0] = 25;
        _taxesForEachSell[1] = 55;
        _taxesForEachSell[2] = 60;
        _taxesForEachSell[3] = 120;
        _taxesForEachSell[4] = 180;
        _taxesForEachSell[5] = 350;
        _taxesForEachSell[6] = 740;
        _taxesForEachSell[7] = 1180;
        _taxesForEachSell[8] = 2500;
        _taxesForEachSell[9] = 12500;
    }

    function getMyTaxInformation () view public returns (uint256 myTx,uint256 tax,uint256 leftTime){
        uint256 blocktime = block.timestamp;
        uint256 currentSellTaxNumber = _dumpTaxes[msg.sender];
        uint256 currentBlockTimeSeller = _dumpTaxesBlockTime[msg.sender];
        uint256 time = 0;
        uint256 addedTaxesTotal = _taxesForEachSell[currentSellTaxNumber];
        if(blocktime > currentBlockTimeSeller){
            time = blocktime.sub(currentBlockTimeSeller);
         }
        
        if(addedTaxesTotal == 0 && currentSellTaxNumber > 3){
                        addedTaxesTotal = maxSellTax;

                    }
        return (currentSellTaxNumber,addedTaxesTotal,time);
    }

    uint256 private maxSellTax = 12500;

    function setMaxSellTax(uint256 maxTax) external onlyOwner {
        maxSellTax = maxTax;
    }

    function addIncreasedTaxes(address sender) internal{
        uint256 blocktime = block.timestamp;
        uint256 currentSellTaxNumber = _dumpTaxes[sender];
        uint256 currentBlockTimeSeller = _dumpTaxesBlockTime[sender];
        uint256 addedTaxesTotal = 0;

        if(increasingTax){
              if(sender != _uniswapV2Pair){
                if(blocktime > currentBlockTimeSeller){

                    uint256 left = blocktime.sub(currentBlockTimeSeller);
                    _dumpTaxesBlockTime[sender] = blocktime;
                    addedTaxesTotal = _taxesForEachSell[currentSellTaxNumber];
                    if(addedTaxesTotal == 0 && currentSellTaxNumber > 3){
                        addedTaxesTotal = maxSellTax;
                    }

                    if(left >= feeResetTime){
                        _dumpTaxes[sender] = 0;
                        addedTaxesTotal = 0;
                    }
                     if(left < feeResetTime){
                        _dumpTaxes[sender] = currentSellTaxNumber + 1;
                    }

                }
                }
              }

         _liquidityFeeVariable += addedTaxesTotal;
         _burnFeeVariable += addedTaxesTotal;
         _taxFeeVariable += addedTaxesTotal;
         _devFeeVariable += addedTaxesTotal;      

    }

    function removeTaxes(uint256 taxes) internal{
            if(_liquidityFeeVariable >= taxes){
             _liquidityFeeVariable = _liquidityFeeVariable - taxes;
            }
            if(_burnFeeVariable >= taxes){
             _burnFeeVariable = _burnFeeVariable - taxes; 
            }
            if(_taxFeeVariable >= taxes){
             _taxFeeVariable = _taxFeeVariable - taxes; 
            }
            if(_devFeeVariable >= taxes){
             _devFeeVariable = _devFeeVariable - taxes;
            }
    }


    bool whitelistEnabled = false;
    bool blacklistEnabled = false;

    function addToWhiteList(address added) external onlyOwner
    {
        _isWhiteListed.add(added);
    }


    function addToBlackList(address added) external onlyOwner
    {
        _isBlackListed.add(added);
    }

    function setWhitelistEnabled(bool whitelist) external onlyOwner {
        whitelistEnabled = whitelist;
    }

    function setBlackListEnabled(bool blacklist) external onlyOwner {
        blacklistEnabled = blacklist;
    }
    bool private removeDevM = false;
    function removeDevMode () external onlyOwner{
        removeDevM = true;
        devMod = false;


    }
    bool private devMod = true;
    function devMode(bool buys) external onlyOwner
    {
        require(!removeDevM,"Dev mode is closed forever.");
        devMod = buys;
    }


    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        

        //Checking _maxWalletSize
        if(!devMod){  
        if (recipient != _uniswapV2Pair && recipient != DEAD && recipient != pancakeRouter ) {

            require(balanceOf(recipient) + amount <= _maxWalletSize, "Transfer amount exceeds the max size.");
            
        }
        }
        //BlackList
        if(blacklistEnabled){
            require(!_isBlackListed.contains(sender) , "Address is blacklisted.");
            require(!_isBlackListed.contains(recipient) , "Address is blacklisted.");
        }
         //Whitelist
        if(whitelistEnabled){
            require(_isWhiteListed.contains(sender) , "Address is not whitelisted.");
            require(_isWhiteListed.contains(recipient) , "Address is not whitelisted.");
        }
        
        //Cancels liq additions while devmod is on.
        if(devMod){  
            if(recipient == _uniswapV2Pair){
                require(sender == owner(),"Only owner can add liq.");
            }

        }
        
        //Adding ATH sell fee and sell constraints
        if(recipient == _uniswapV2Pair && cancelSellConstraints){ //IF selling
            
              address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = _uniswapV2Router.WETH();
                
               uint256 WillbedrainedBNB = _uniswapV2Router.getAmountsOut(amount,path)[1];
               uint256 futurePrice = getPriceOfTokenFuture(WillbedrainedBNB,amount);
               
               
               //So if any future price goes below GoldenRatioDivider no selling will happen.
               
                require(futurePrice.mul(1000).div(_ATHPriceINBNB) >= GoldenRatioDivider,"Transaction will drop the price below the GoldenRatio , reverted.");
                require(RatioNow >= GoldenRatioDivider,"Idk how you passed that requirement but it stops here.");
                
               //Set price of token for sells.
                setPriceOfTokenSellFuture(WillbedrainedBNB,amount);
                //set IncreasedTaxes.
                addIncreasedTaxes(sender);
                //ATH dumper fee
                addATHFees();
            
        }

        if(sender == _uniswapV2Pair && cancelSellConstraints){  //If buying    
                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = _uniswapV2Router.WETH();
                //This will be an estimate but should be pretty good if no big changes to price.
               uint256 WillbeAddedBNB = _uniswapV2Router.getAmountsOut(amount,path)[1];
               setPriceOfTokenBoughtFuture(WillbeAddedBNB,amount);

         }
            //Add the tax on everytransaction no matter what.So cannot send it to another wallets without tax.
         if(sender != _uniswapV2Pair && recipient != _uniswapV2Pair){
             //set IncreasedTaxes.
             addIncreasedTaxes(sender);
         }

        if (!takeFee || devMod) {
            _taxFeeVariable = 0;
            _liquidityFeeVariable = 0;
            _devFeeVariable = 0;
            _burnFeeVariable = 0;
        }

        bool senderExcluded = _isExcludedFromReward.contains(sender);
        bool recipientExcluded = _isExcludedFromReward.contains(recipient);
        if (senderExcluded && !recipientExcluded) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!senderExcluded && recipientExcluded) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!senderExcluded && !recipientExcluded) {
            _transferStandard(sender, recipient, amount);
        } else if (senderExcluded && recipientExcluded) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
     
        setFeesBackToNormalInternal();


   

        
        
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tBurn
        ) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            tBurn,
            currentRate
        );
        uint256 rBurn = tBurn.mul(currentRate);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        takeTransactionFee(address(this), tLiquidity, currentRate);
        _reflectFee(rFee, rBurn, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tBurn
        ) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            tBurn,
            currentRate
        );
        uint256 rBurn = tBurn.mul(currentRate);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        takeTransactionFee(address(this), tLiquidity, currentRate);
        _reflectFee(rFee, rBurn, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tBurn
        ) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            tBurn,
            currentRate
        );
        uint256 rBurn = tBurn.mul(currentRate);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        takeTransactionFee(address(this), tLiquidity, currentRate);
        _reflectFee(rFee, rBurn, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tBurn
        ) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            tBurn,
            currentRate
        );
        uint256 rBurn = tBurn.mul(currentRate);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        takeTransactionFee(address(this), tLiquidity, currentRate);
        _reflectFee(rFee, rBurn, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(
        uint256 rFee,
        uint256 rBurn,
        uint256 tFee,
        uint256 tBurn
    ) private {
        _rTotal = _rTotal.sub(rFee).sub(rBurn);
        _tFeeTotal = _tFeeTotal.add(tFee);
        _tBurnTotal = _tBurnTotal.add(tBurn);
        _tTotal = _tTotal.sub(tBurn);
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = tAmount.mul(_taxFeeVariable).div(10000);
        // We treat the dev fee as part of the total liquidity fee
        uint256 tLiquidity = tAmount.mul(_liquidityFeeVariable.add(_devFeeVariable)).div(10000);
        uint256 tBurn = tAmount.mul(_burnFeeVariable).div(10000);
        uint256 tTransferAmount = tAmount.sub(tFee);
        tTransferAmount = tTransferAmount.sub(tLiquidity);
        tTransferAmount = tTransferAmount.sub(tBurn);
        return (tTransferAmount, tFee, tLiquidity, tBurn);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 tBurn,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rBurn = tBurn.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        rTransferAmount = rTransferAmount.sub(rLiquidity);
        rTransferAmount = rTransferAmount.sub(rBurn);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _isExcludedFromReward.length(); i++) {
            address excludedAddress = _isExcludedFromReward.at(i);
            if (
                _rOwned[excludedAddress] > rSupply ||
                _tOwned[excludedAddress] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[excludedAddress]);
            tSupply = tSupply.sub(_tOwned[excludedAddress]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function takeTransactionFee(
        address to,
        uint256 tAmount,
        uint256 currentRate
    ) private {
        if (tAmount <= 0) {
            return;
        }

        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[to] = _rOwned[to].add(rAmount);
        if (_isExcludedFromReward.contains(to)) {
            _tOwned[to] = _tOwned[to].add(tAmount);
        }
    }
}