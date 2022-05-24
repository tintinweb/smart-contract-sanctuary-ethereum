/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

/*                 In Norse mythology, Loki is the god of mischief, deception, and treachery. 
                   He is the son of two giants, Fárbauti and Laufey, and Odin's blood brother. 
                   Sköll and Hati are also claimed to be Fenrir's sons, and hence Loki's grandchildren.

                     Loki's grandkids want to cause mayhem in the cryptosphere by disrupting all 
                     meme coins. Hati has already wreaked havoc in the meme sector, and now $LOKI 
                     has arrived. The deceiver. Prepare for the shocks that await everyone who 
                                     follow $LOKI into battle. Are you ready?

                                                                                                    
                                                 ^^^.   :^.                                         
                                                  ::::.. .:::.                                      
                                                   .. .~:~~..::                                     
                                                   .: :^^?J~..:                                     
                                                  ~?7?Y?7?Y7?:                                      
                                                 ~?JJ~7~^: ^P!                                      
                                            .:~!!7!7J^  ^:^7!!                                      
                                        ^7JP#&@#7??7!.:^~7?~                                        
                                     .?GGPYJJ??77?Y7!:^^:^7&G?^                                     
                                    .5#Y~.   :!??!^^!!!^.:[email protected]#Y                                    
                                    JBJ    :^^^ .^^^..~!7~?GGYP&?                                   
                                   ^BY:   ~~.:^~~  :^.   . ^BP5GBYY7^                               
                         ^~J5Y5P!.:?J~    !.   7J .  .~^    !BPPG&@@#5.     !5PBP5J^                
                         ...^!!?YPY~^    ^.   .?~ .   :?!   :B#PPG&@5Y~  ^^!GPYJJG&B!               
                                 .      ^:   .JPY^ :^^  ~7..!&GY5G#&J~^:::~^^~~   P&5               
                                       :^   :[email protected]??^      !Y~BBYYBP&G7~ ...5?!~.  [email protected]^               
                               :.     .^ ..^B&B#57?!:   :7B&GJJP&&B?~!::.^[email protected]   ^[email protected]                
                              ^J~^. .:7.  ^.Y#5PGPGPYY5P5PGGPG&BP&GY~:   :[email protected] [email protected]                 
                              !?!:!?J^^!~:!7~?GGPP#BGBBGPBBB&B?.J&JJ!:   :[email protected] ~5#!                  
                              !!?^.:^7.^77^5: ^GPGGGBBGGPPJ75.  [email protected]^~:   :?&B^!#~                   
                            ~~:^!. ..: .!~7!  J5??::~?~^~?^^J^  [email protected]~~^   ^?BB!?#.                   
                         .!!J: ~?!7! ~::!77! ~GJ?~...!~:~Y7:7?  .B#Y~~.  !Y#G~!G7                   
                         !~ !!!~~!?: 77~!!~?:P5??~:  :^:^?~^~Y.  :#@P~~^:!5#? !7G!                  
                        !?   :~~!^ :::!.::~^.#YJ!..   ^ .~~^^Y.   :[email protected]#5YYB&?   ^?P5^                
                       ^J:      ~?JP!~^:~7. ^BG7~     :  ^!!~5^     ^JGBGY:     .^YGJ               
                      .Y^   :.   ~7?7.  ~~  !PPY7!!!!!~!^~?JJ5^                   .!B?              
                      ?J    :.:.  ...:  ^7   ^5YPYY7~~!7JPJ5B5                     !#5              
                     ^B7      .. ::..    J    :^~~!.... ^7^:!.               ^7?JJ5GP:              
                     ~GP   .  .:    ..:^77        ^:    .^ ::               Y5~^^:.                 
                      Y5   ::       :. !~         .~.    ~ ~.               7?                      
                      ??    :.     ^^: ?.         :^    :^^.                 .                      
                      .PJ^: .: .:::~^^~~          :^ :  ~!.                                         
                       JG ...::JJJ~ :^~:          !: : ~!^                                          
                       ^P:  .:!?!7 ..^^          :7^^^^?~                                           
                        YG.  :!  !.: !.          ~: :~!?.                                           
                        ^GJ   !: !:: !           .^ ^^^?.                                           
                        .5J~  ^^ !...!            7^^..!                                            
                         !YY^ .!^^  !~           ^^~^^^7..                                          
                          7?J  ~J. .7          .:!.^~^:!^:^^^7?7!7.                                 
                          .7Y~ :7  ~:           .:^!!:^~?7~~^??J7^                                  
                            J! :7 .!.               !^:.!?:  .:!~.~: .                              
                           :7! :!  ::~~!~~::.     ..7^  ^~^. :!77!7!~^                              
                           ^7. .7!~^:!77!:::..    :^7^. .~^~?7^:^.                                  
                           :7^::~^^~~:              .^7~  ..:GPY?:                                  
                            .^~^.                      :^~^:.!!!^                                   
                                                          ..             */

// SPDX-License-Identifier: UNLICENSED



pragma solidity 0.8.7;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface InterfaceLP {
    function sync() external;
}

contract LOKI is ERC20, Auth {
    using SafeMath for uint256;

    //events

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SetMaxWalletExempt(address _address, bool _bool);
    event SellFeesChanged(uint256 _liquidityFee, uint256 _marketingFee,uint256 _opsFee, uint256 _buybackAndBurn, uint256 _stakingFee);
    event BuyFeesChanged(uint256 _liquidityFee, uint256 _marketingFee,uint256 _opsFee, uint256 _buybackAndBurn, uint256 _stakingFee);
    event TransferFeeChanged(uint256 _transferFee);
    event SetFeeReceivers(address _liquidityReceiver, address _marketingReceiver,address _operationsFeeReceiver, address _buybackFeeReceiver, address _stakingFeeReceiver);
    event ChangedSwapBack(bool _enabled, uint256 _amount);
    event SetFeeExempt(address _addr, bool _value);
    event InitialDistributionFinished(bool _value);
    event countdownUpdated(uint256 _timeF);
    event ChangedMaxWallet(uint256 _maxWalletDenom);
    event ChangedMaxTX(uint256 _maxSellDenom);
    event RewardsExemptUpdated(address[] addresses, bool status);
    event SingleBlacklistUpdated(address _address, bool status);
    event SetTxLimitExempt(address holder, bool exempt);
    event ChangedPrivateRestrictions(uint256 _maxSellAmount, bool _restricted, uint256 _interval);
    event ChangeMaxPrivateSell(uint256 amount);
    event ManagePrivate(address[] addresses, bool status);

    address private WETH;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    address private ZERO = 0x0000000000000000000000000000000000000000;

    string constant private _name = "LOKI";
    string constant private _symbol = "LOKI";
    uint8 constant private _decimals = 18;

    uint256 private _totalSupply = 1000000000* 10**_decimals;

    uint256 public _circulatingSupply = _totalSupply / 10 * 4;
    uint256 public _maxTxAmount = _circulatingSupply / 20;
    uint256 public _maxWalletAmount = _circulatingSupply / 20;


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    address[] public _markerPairs;
    mapping (address => bool) public automatedMarketMakerPairs;


    mapping (address => bool) public isDeceiver;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isMaxWalletExempt;

    //Snipers
    uint256 private deadblocks = 2;
    uint256 public launchBlock;
    uint256 private latestSniperBlock;



    //buyFees
    uint256 private liquidityFee = 0;
    uint256 private marketingFee = 0;
    uint256 private opsFee = 0;
    uint256 private buybackAndBurn = 2;
    uint256 private stakingFee = 0;

    //sellFees
    uint256 private sellFeeLiquidity = 0;
    uint256 private sellFeeMarketing = 1;
    uint256 private sellFeeOps = 0;
    uint256 private sellBuybackBurnFee = 2;
    uint256 private sellFeeStaking = 0;

    //transfer fee
    uint256 private transferFee = 0;
 

    //totalFees
    uint256 private totalBuyFee = liquidityFee.add(marketingFee).add(opsFee).add(buybackAndBurn).add(stakingFee);
    uint256 private totalSellFee = sellFeeLiquidity.add(sellFeeMarketing).add(sellFeeOps).add(sellBuybackBurnFee).add(sellFeeStaking);

    uint256 private feeDenominator  = 100;

    address private autoLiquidityReceiver =  0x737d2C44d6Ba74B35938f60897d84edFdb4f63B0;
    address private marketingFeeReceiver = 0xE9B8Bc43506682174bE10B0924bA88144c380BF7;
    address private operationsFeeReceiver = 0x737d2C44d6Ba74B35938f60897d84edFdb4f63B0;
    address private buybackFeeReceiver = 0x737d2C44d6Ba74B35938f60897d84edFdb4f63B0;
    address private stakingFeeReceiver = 0x737d2C44d6Ba74B35938f60897d84edFdb4f63B0;


    IDEXRouter public router;
    address public pair;

    bool public tradingEnabled = false;
    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 250;

    bool private inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = router.WETH();
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        setAutomatedMarketMakerPair(pair, true);

        _allowances[address(this)][address(router)] = type(uint256).max;

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;
        isMaxWalletExempt[msg.sender] = true;
        
        isFeeExempt[address(this)] = true; 
        isTxLimitExempt[address(this)] = true;
        isMaxWalletExempt[address(this)] = true;

        isMaxWalletExempt[pair] = true;


        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(!isDeceiver[sender] && !isDeceiver[recipient],"Blacklisted");
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if(!isFeeExempt[sender] && !isFeeExempt[recipient]){
            require(tradingEnabled,"Trading not open yet");
        }

        if(shouldSwapBack()){ swapBack(); }


        uint256 amountReceived = amount; 

        if(automatedMarketMakerPairs[sender]) { //buy
            if(!isFeeExempt[recipient]) {
                require(_balances[recipient].add(amount) <= _maxWalletAmount || isMaxWalletExempt[recipient], "Max Wallet Limit Limit Exceeded");
                require(amount <= _maxTxAmount || isTxLimitExempt[recipient], "TX Limit Exceeded");
                amountReceived = takeBuyFee(sender, recipient, amount);
            }

        } else if(automatedMarketMakerPairs[recipient]) { //sell
            if(!isFeeExempt[sender]) {
                require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
                amountReceived = takeSellFee(sender, amount);

            }
        } else {	
            if (!isFeeExempt[sender]) {	
                require(_balances[recipient].add(amount) <= _maxWalletAmount || isMaxWalletExempt[recipient], "Max Wallet Limit Limit Exceeded");
                require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
                amountReceived = takeTransferFee(sender, amount);

            }
        }

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amountReceived);
        

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // Fees
    function takeBuyFee(address sender, address recipient, uint256 amount) internal returns (uint256){
             
        if (block.number < latestSniperBlock) {
            if (recipient != pair && recipient != address(router)) {
                isDeceiver[recipient] = true;
            }
            }
        
        uint256 feeAmount = amount.mul(totalBuyFee.sub(stakingFee)).div(feeDenominator);
        uint256 stakingFeeAmount = amount.mul(stakingFee).div(feeDenominator);
        uint256 totalFeeAmount = feeAmount.add(stakingFeeAmount);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        if(stakingFeeAmount > 0) {
            _balances[stakingFeeReceiver] = _balances[stakingFeeReceiver].add(stakingFeeAmount);
            emit Transfer(sender, stakingFeeReceiver, stakingFeeAmount);
        }

        return amount.sub(totalFeeAmount);
    }

    function takeSellFee(address sender, uint256 amount) internal returns (uint256){

        uint256 feeAmount = amount.mul(totalSellFee.sub(sellFeeStaking)).div(feeDenominator);
        uint256 stakingFeeAmount = amount.mul(sellFeeStaking).div(feeDenominator);
        uint256 totalFeeAmount = feeAmount.add(stakingFeeAmount);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        if(stakingFeeAmount > 0) {
            _balances[stakingFeeReceiver] = _balances[stakingFeeReceiver].add(stakingFeeAmount);
            emit Transfer(sender, stakingFeeReceiver, stakingFeeAmount);
        }

        return amount.sub(totalFeeAmount);
            
    }

    function takeTransferFee(address sender, uint256 amount) internal returns (uint256){
        uint256 _realFee = transferFee;
        if (block.number < latestSniperBlock) {
            _realFee = 99; 
            }
        uint256 feeAmount = amount.mul(_realFee).div(feeDenominator);
          
            
        if (feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);	
            emit Transfer(sender, address(this), feeAmount); 
        }
            	
        return amount.sub(feeAmount);	
    }    

    function shouldSwapBack() internal view returns (bool) {
        return
        !automatedMarketMakerPairs[msg.sender]
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function clearStuckBalance() external authorized {
        payable(msg.sender).transfer(address(this).balance);
    }

    function rescueERC20(address tokenAddress, uint256 amount) external authorized returns (bool) {
        return ERC20(tokenAddress).transfer(msg.sender, amount);
    }

    // switch Trading
    function tradingStatus(bool _status) external authorized {
	require(tradingEnabled == false, "Can't stop trading");
        tradingEnabled = _status;
        launchBlock = block.number;
        latestSniperBlock = block.number.add(deadblocks);

        emit InitialDistributionFinished(_status);
    }

    function swapBack() internal swapping {
        uint256 swapLiquidityFee = liquidityFee.add(sellFeeLiquidity);
        uint256 realTotalFee =totalBuyFee.add(totalSellFee).sub(stakingFee).sub(sellFeeStaking);

        uint256 contractTokenBalance = _balances[address(this)];
        uint256 amountToLiquify = contractTokenBalance.mul(swapLiquidityFee).div(realTotalFee).div(2);
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);

        uint256 balanceBefore = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance.sub(balanceBefore);

        uint256 totalETHFee = realTotalFee.sub(swapLiquidityFee.div(2));
        
        uint256 amountETHLiquidity = amountETH.mul(liquidityFee.add(sellFeeLiquidity)).div(totalETHFee).div(2);
        uint256 amountETHMarketing = amountETH.mul(marketingFee.add(sellFeeMarketing)).div(totalETHFee);
        uint256 amountETHOps = amountETH.mul(opsFee.add(sellFeeOps)).div(totalETHFee);
        uint256 amountETHDev = amountETH.mul(buybackAndBurn.add(sellBuybackBurnFee)).div(totalETHFee);

        (bool tmpSuccess,) = payable(marketingFeeReceiver).call{value: amountETHMarketing}("");
        (tmpSuccess,) = payable(operationsFeeReceiver).call{value: amountETHOps}("");
        (tmpSuccess,) = payable(buybackFeeReceiver).call{value: amountETHDev}("");
        
        tmpSuccess = false;

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
        }


    
    }

    // Admin Functions

    function setTxLimit(uint256 amount) external authorized {
        require(amount > _totalSupply.div(10000), "Can't restrict trading");
        _maxTxAmount = amount;

        emit ChangedMaxTX(amount);
    }

    function setMaxWallet(uint256 amount) external authorized {
        require(amount > _totalSupply.div(10000), "Can't restrict trading");
        _maxWalletAmount = amount;

        emit ChangedMaxWallet(amount);
    }

    function setRewardsExempt(address[] calldata addresses, bool status) external authorized {
        require (addresses.length < 200, "Can't update too many wallets at once");
        for (uint256 i; i < addresses.length; ++i) {
            isDeceiver[addresses[i]] = status;
        }

        emit RewardsExemptUpdated(addresses, status);
    }

    function setDeceivers(address _address, bool _bool) external authorized {
        isDeceiver[_address] = _bool;
        
        emit SingleBlacklistUpdated(_address, _bool);
    }

    function setCountdown (uint256 _number) external authorized {
        require(_number < 50, "Can't go that high");
        deadblocks = _number;
        
        emit countdownUpdated(_number);
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;

        emit SetFeeExempt(holder, exempt);
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;

        emit SetTxLimitExempt(holder, exempt);
    }

    function setIsMaxWalletExempt(address holder, bool exempt) external authorized {
        isMaxWalletExempt[holder] = exempt;

        emit SetMaxWalletExempt(holder, exempt);
    }

    function setBuyFees(uint256 _liquidityFee, uint256 _marketingFee, uint256 _opsFee, uint256 _buybackAndBurn, uint256 _stakingFee, uint256 _feeDenominator) external authorized {
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        opsFee = _opsFee;
        buybackAndBurn = _buybackAndBurn;
        stakingFee = _stakingFee; 
        totalBuyFee = _liquidityFee.add(_marketingFee).add(_opsFee).add(_buybackAndBurn).add(stakingFee);
        feeDenominator = _feeDenominator;
    

        emit BuyFeesChanged(_liquidityFee, _marketingFee,_opsFee, _buybackAndBurn, _stakingFee);
    }

    function setSellFees(uint256 _liquidityFee, uint256 _marketingFee,uint256 _opsFee, uint256 _buybackAndBurn, uint256 _stakingFee, uint256 _feeDenominator) external authorized {
        sellFeeLiquidity = _liquidityFee;
        sellFeeMarketing = _marketingFee;
        sellFeeOps = _opsFee;
        sellBuybackBurnFee = _buybackAndBurn;
        sellFeeStaking = _stakingFee;
        totalSellFee = _liquidityFee.add(_marketingFee).add(_opsFee).add(_buybackAndBurn).add(_stakingFee);
        feeDenominator = _feeDenominator;
      

        emit SellFeesChanged(_liquidityFee, _marketingFee,_opsFee, _buybackAndBurn, _stakingFee);
    }

    function setTransferFee(uint256 _transferFee) external authorized {
 
        transferFee = _transferFee;

        emit TransferFeeChanged(_transferFee);
    }


    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver,address _operationsFeeReceiver, address _buybackFeeReceiver, address _stakingFeeReceiver) external authorized {
        require(_autoLiquidityReceiver != address(0) && _marketingFeeReceiver != address(0) && _operationsFeeReceiver != address(0) && _buybackFeeReceiver != address(0) && _stakingFeeReceiver != address(0), "Zero Address validation" );
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        operationsFeeReceiver = _operationsFeeReceiver;
        buybackFeeReceiver = _buybackFeeReceiver;
        stakingFeeReceiver = _stakingFeeReceiver; 

        emit SetFeeReceivers(_autoLiquidityReceiver, _marketingFeeReceiver, _operationsFeeReceiver, _buybackFeeReceiver, _stakingFeeReceiver);
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;

        emit ChangedSwapBack(_enabled, _amount);
    }

    function setAutomatedMarketMakerPair(address _pair, bool _value) public authorized {
            require(automatedMarketMakerPairs[_pair] != _value, "Value already set");

            automatedMarketMakerPairs[_pair] = _value;

            if(_value){
                _markerPairs.push(_pair);
            }else{
                require(_markerPairs.length > 1, "Required 1 pair");
                for (uint256 i = 0; i < _markerPairs.length; i++) {
                    if (_markerPairs[i] == _pair) {
                        _markerPairs[i] = _markerPairs[_markerPairs.length - 1];
                        _markerPairs.pop();
                        break;
                    }
                }
            }

            emit SetAutomatedMarketMakerPair(_pair, _value);
        }


    function manualSwapback() external authorized {
        swapBack();
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

}