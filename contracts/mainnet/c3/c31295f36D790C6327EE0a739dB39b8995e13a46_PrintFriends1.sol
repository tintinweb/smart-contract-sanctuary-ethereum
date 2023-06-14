/**
 *Submitted for verification at Etherscan.io on 2023-06-14
*/

//SPDX-License-Identifier: Unlicensed


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// File: PrintFriends/PrintFriends1.sol

/**
   /\\\\\\\\\\\\\\\\     /////////////////    
   /                /    /                                    
   /                /    /                                  
   /                /    /////////////////                 
   //////////////////    /                                
   /                     /                                 
   /                     /                                
   /                    
*/


pragma solidity ^0.8.0;

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

/**
 * ERC20 standard interface.
 */
interface IERC20 {
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
 abstract contract Context {
     function _msgSender() internal view virtual returns (address) {
         return msg.sender;
     }
     function _msgdata() internal pure returns (bytes calldata) {
         return msg.data;
     }
 }
 
 contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
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
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

     function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
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

  interface IDividendDistributor {
    function setShare(address shareholder, uint256 amount) external;
    function deposit(uint256 amount) external;
    function claimDividend(address shareholder) external;
    function getDividendsClaimedOf (address shareholder) external returns (uint256);
}

 contract PrintFriends1DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address public _token;
    address public _owner;

    address public immutable PEPE = address(0x6982508145454Ce325dDbE47a25d4ec3d2311933); //UNI
    address public immutable FLOKI = address(0xcf0C122c6b73ff809C693DB761e7BaeBe62b6a2E); //UNI

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalClaimed;
    }

    address[] private shareholders;
    mapping (address => uint256) private shareholderIndexes;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalClaimed;
    uint256 public dividendsPerShare;
    uint256 private dividendsPerShareAccuracyFactor = 10 ** 36;

    modifier onlyToken() {
        require(msg.sender == _token || msg.sender == _owner, "Unauthorized"); _;
    }
    
     modifier onlyOwner() {
        require(msg.sender == _owner, "Unauthorized"); _;
    }
 
     constructor (address owner) {
        _owner = owner;
    }
    receive() external payable { }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit(uint256 amount) external override onlyToken {
        
        if (amount > 0) {        
            totalDividends = totalDividends.add(amount);
            dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
        }
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getClaimableDividendOf(shareholder);
        if(amount > 0){
            totalClaimed = totalClaimed.add(amount);
            shares[shareholder].totalClaimed = shares[shareholder].totalClaimed.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            IERC20(FLOKI).transfer(shareholder, amount);
            IERC20(PEPE).transfer(shareholder, amount);
        }
    }

    function claimDividend(address shareholder) external override onlyToken {
        distributeDividend(shareholder);
    }

    function getClaimableDividendOf(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
    
    function manualSend(uint256 amount, address holder) external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        payable(holder).transfer(amount > 0 ? amount : contractETHBalance);
    }


    function getDividendsClaimedOf (address shareholder) external view returns (uint256) {
        require (shares[shareholder].amount > 0, "You're not a PRINTER shareholder!");
        return shares[shareholder].totalClaimed;
    }

    }
  contract PrintFriends1 is Context, IERC20, Ownable {
    using SafeMath for uint256;

    address private WETH;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    address private ZERO = 0x0000000000000000000000000000000000000000;

    address public immutable PEPE = address(0x6982508145454Ce325dDbE47a25d4ec3d2311933); //UNI
    address public immutable FLOKI = address(0xcf0C122c6b73ff809C693DB761e7BaeBe62b6a2E); //UNI

    string public constant  _name = "PrintFriends1";
    string public constant _symbol = "PF1";
    uint8 public constant _decimals = 18;

    uint256 public _totalSupply = 4444444 * (10 ** _decimals);
    uint256 public _maxTxAmountBuy = 100000 * (10 ** _decimals);
    

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private cooldown;

    mapping (address => bool) private isFeeExempt;
    mapping (address => bool) private isDividendExempt;
    mapping (address => bool) private isBot;

    uint256 private constant totalFee = 10;
    uint256 private constant feeDenominator = 100;


    uint256 private liquidityPercentage = 1;
    uint256 private marketingPercentage = 1;
    uint256 private rewardPercentage = 4; // 2% PEPE + 2% FLOKI
    uint256 private buybackandburnsPercentage = 4;
    uint256 private _maxGiveawayAmount = 1000 * (10 ** _decimals);
    uint256 private _giveawayPoolAmount = 888888 *(10 ** _decimals);

    uint256 private _marketingAllocation = 44444;  // marketingAllocation is 44,444 tokens
    uint256 private _teamAllocation = 44444;  // teamAllocation is 44,444 tokens


    address private _giveawayWallet;
    
    
    address payable public marketingWallet = payable(0xE32D8dc8057F238B15DE67866254F1f7f3dc30BB);
    address payable public teamWallet = payable(0x2D174793b82Dc8B28Ba5d5317690B23A172C229A);

    IUniswapV2Router02 public router;
    address public pair;

    uint256 public launchedAt;
    bool private tradingOpen;
    bool private buyLimit = true;
    uint256 private maxBuy = _maxTxAmountBuy ;
    uint256 public numTokensSellToAddToLiquidity = 444444.4 * 10** 18;
    
    address private _owner;
    PrintFriends1DividendDistributor private distributor;    
    
    bool public blacklistEnabled = false;
    bool private inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

   
  constructor () {

                 _owner = address(0x2fCeB44c65CaaB50Ca367bCF1B18D9bDbdC8dCc6);

        _uniswapContract = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //uniswap contract address
        
        router = IUniswapV2Router02(_uniswapContract);
            
        WETH = router.WETH();
        
        _allowances[address(this)][address(router)] = type(uint256).max;

        distributor = new PrintFriends1DividendDistributor(_owner);

        isFeeExempt[_owner] = true;
        isFeeExempt[marketingWallet] = true;             
              
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;        

        _balances[_owner] = _totalSupply;
    
        emit Transfer(address(0), _owner, _totalSupply);

      
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return _owner; }
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
        if (sender!= _owner && recipient!= _owner) require(tradingOpen, "Trading not yet enabled."); //transfers disabled before openTrading
        if (blacklistEnabled) {
            require (!isBot[sender] && !isBot[recipient], "Bot!");
        }
        if (buyLimit) { 
            if (sender!= _owner && recipient!= _owner) require (amount<=maxBuy, "Too much ");        
        }

        if (sender == pair && recipient != address(router) && !isFeeExempt[recipient]) {
            require (cooldown[recipient] < block.timestamp);
            cooldown[recipient] = block.timestamp + 60 seconds; 
        }
       
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }      

        uint256 contractTokenBalance = balanceOf(address(this));

        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
    
        bool shouldSwapBack = (overMinTokenBalance && recipient==pair && balanceOf(address(this)) > 0);
        if(shouldSwapBack){ swapBack(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, amount) : amount;
        
        _balances[recipient] = _balances[recipient].add(amountReceived);

        if(sender != pair && !isDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(recipient != pair && !isDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

 
    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return ( !(isFeeExempt[sender] || isFeeExempt[recipient]) &&  (sender == pair || recipient == pair) );
   }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount;
        feeAmount = amount.mul(totalFee).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);   

        return amount.sub(feeAmount);
    }

    function executeswap() internal swapping {

        uint256 amountToSwap = balanceOf(address(this));        

        swapTokensForEth(amountToSwap.div(2));
        swapTokensForFLOKI(amountToSwap.div(2));

        uint256 dividends = IERC20(FLOKI).balanceOf(address(this));
        
        bool success = IERC20(FLOKI).transfer(address(distributor), dividends);
        
        if (success) {
            distributor.deposit(dividends);            
        }
             
        payable(marketingWallet).transfer(address(this).balance);        
    }
    function swapBack() internal swapping {

        uint256 amountToSwap = balanceOf(address(this));        

        swapTokensForEth(amountToSwap.div(2));
        swapTokensForPEPE(amountToSwap.div(2));

        uint256 dividends = IERC20(PEPE).balanceOf(address(this));
        
        bool success = IERC20(PEPE).transfer(address(distributor), dividends);
        
        if (success) {
            distributor.deposit(dividends);            
        }
             
        payable(marketingWallet).transfer(address(this).balance);        
    }
    

    
       //SWAP AND SEND PEPE
    function swapTokensForPEPE(uint256 tokenAmount) private {

        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = WETH;
        path[2] = PEPE;
        

        // make the swap
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    
    }
    //SWAP AND SEND FLOKI
    function swapTokensForFLOKI(uint256 tokenAmount) private {

        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = WETH;
        path[2] = FLOKI;
        

        // make the swap
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }


    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        
        // add the liquidity
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            10, // slippage is unavoidable
            10, // slippage is unavoidable
            _owner,
            block.timestamp
        );
    }

    
    function openTrading() external onlyOwner {
        launchedAt = block.number;
        tradingOpen = true;
    }    
  
    
    function setBot(address _address, bool toggle) external onlyOwner {
        isBot[_address] = toggle;
        _setIsDividendExempt(_address, toggle);
    }
    
    
    function _setIsDividendExempt(address holder, bool exempt) internal {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        _setIsDividendExempt(holder, exempt);
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setFee (uint256 _fee) external view onlyOwner {
        require (_fee <= 10, "Fee can't exceed 10%");
    }
  
    function manualSend() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        payable(marketingWallet).transfer(contractETHBalance);
    }

    function claimDividend() external {
        distributor.claimDividend(msg.sender);
    }
    
    function claimDividend(address holder) external onlyOwner {
        distributor.claimDividend(holder);
    }
    
    function getClaimableDividendOf(address shareholder) public view returns (uint256) {
        return distributor.getClaimableDividendOf(shareholder);
    }
 
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function setMarketingWallet(address _marketingWallet) external onlyOwner {
        marketingWallet = payable(_marketingWallet);
    } 

    function setTeamWallet(address _teamWallet) external onlyOwner {
    teamWallet = payable(_teamWallet);
   }

   function setAllocationAmounts(uint marketingAllocation, uint teamAllocation) external onlyOwner {
    _marketingAllocation = marketingAllocation;
    _teamAllocation = teamAllocation;
}

  function distributeAllocations() external onlyOwner {
    require(_marketingAllocation > 0, "Marketing allocation not set");
    require(_teamAllocation > 0, "Team allocation not set");

    require(address(this).balance >= _marketingAllocation + _teamAllocation, "Insufficient contract balance");

    // Transfer marketing allocation to the marketing wallet
    payable(marketingWallet).transfer(_marketingAllocation);

    // Transfer team allocation to the team wallet
    payable(teamWallet).transfer(_teamAllocation);
}

    function getTotalDividends() external view returns (uint256) {
        return distributor.totalDividends();
    }    

    function getTotalClaimed() external view returns (uint256) {
        return distributor.totalClaimed();
    }

     function getDividendsClaimedOf (address shareholder) external view returns (uint256) {
        return distributor.getDividendsClaimedOf(shareholder);
    }

    function removeBuyLimit() external onlyOwner {
        buyLimit = false;
    }

    function checkBot(address account) public view returns (bool) {
        return isBot[account];
    }

    function setBlacklistEnabled() external view onlyOwner {
        require (!blacklistEnabled, "can only be called once");
    }

    function setSwapThresholdAmount (uint256 amount) external onlyOwner {
        require (amount <= _totalSupply.div(100), "can't exceed 1%");
        numTokensSellToAddToLiquidity = amount * 10 ** 18 ;
    } 

  function _burn(address account, uint256 amount) internal {
    require(amount > 0, "Amount must be greater than zero");
    require(balanceOf(account) >= amount, "Insufficient balance");

    _totalSupply -= amount;
    _balances[account] -= amount;
    emit _Burn(account, amount);
    }

   //BURN EVENT
   event _Burn(address indexed burner, uint256 amount);

   address private _uniswapContract;
   uint256 private _burnRate;
   uint256 private _startTime;

   //Calculate daily burn amount based on the balance in the uniswap contract address
   function calculateDailyBurnAmount() public view returns (uint256) {
    require(block.timestamp >= _startTime, "Burn period has not started yet");

    uint256 uniswapBalance = IERC20(_uniswapContract).balanceOf(address(this));
    uint256 dailyBurnAmount = (uniswapBalance * _burnRate) / 100;

    if (dailyBurnAmount > uniswapBalance) {
        return uniswapBalance;  // Burn the remaining balance if daily burn amount exceeds the balance
    } else {
        return dailyBurnAmount;
    }
}
   //Executes burn mechanism daily
   function executeDailyBurn() public {
    uint256 dailyBurnAmount = calculateDailyBurnAmount();
    require(dailyBurnAmount > 0, "No burn amount for today");

    emit _Burn(_uniswapContract, dailyBurnAmount);
}

   //giveawayconditions
   //using chainlink oracle to check if price of PF1 is < $50
    function getPrice() public view returns (uint256) {
        //ABI
        //Address 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
         AggregatorV3Interface priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
         
     (,int256 answer,,,) = priceFeed.latestRoundData();
     //Typecasting
     return uint256(answer * 1e10);
}
     function getversion() public view returns (uint256) {
         AggregatorV3Interface priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
         return priceFeed.version();
     }
    function getConversionRate(uint256 ethAmount) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = (ethPrice * ethAmount)/1e10;

        return ethAmountInUSD;

    }
    //GIVEAWAY 
    uint256 private constant _giveawayAmount = 100100 * (10 ** _decimals); // 1001 tokens to be given away
    uint256 private constant _giveawayAmountPerAddress = 200200 * (10 ** _decimals); // 200.2 tokens per address
    uint256 private constant _giveawayFrequency = 1 days; // Giveaway everyday
    uint256 private constant _giveawayDuration = 888 days; // Total giveaway duration
    uint256 private constant _maxgiveawayPercentofLiquidity = 1; // 1.0% of liquidity
    uint256 private constant _maxgiveawayPercentofBuyback= 3; // 3% of PF buyback amount
    uint256 private constant _minPF1amountinUniswapWallet = 30000 *(10 ** _decimals); // 3% of buyback amount
    uint256 private constant _reflectionsPercentage = 4; // 4% reflections for pepe & floki wallets
   
   mapping(uint256 => address[]) private giveawayAddresses;
   uint256 private giveawayIndex;
 

  function startGiveaway() external  {
      require(giveawayIndex == 0, "Giveaway already started");

      //Calculate total giveaway amount
      uint256 totalAmount = _giveawayAmount * _giveawayDuration;

      //Check conditions
      require(totalAmount < (_totalSupply * 1) / 100, "Giveaway exceeds 1% of liquidity");
      require(totalAmount < (_totalSupply * 3) / 100, "Giveaway exceeds 3% of token buyback amount");

      //Check token price
      require(getPrice() < 50 ether, "Token price is not less than $50");

     _giveawayWallet = 0xAf142c957dfdB0023f99f4D7b6B7651cfF4ee954;

      // Generate random addresses
        for (uint256 i = 0; i < _giveawayDuration; i++) {
            address[] memory addresses = new address[](5);
            for (uint256 j = 0; j < 5; j++) {
                addresses[j] = address(uint160(uint256(keccak256(abi.encodePacked(giveawayIndex, i, j)))));
            }
            giveawayAddresses[giveawayIndex] = addresses;
            giveawayIndex++;


        }
  }
        function claimGiveaway() external {
    require(giveawayIndex > 0, "Giveaway not started");
    require(giveawayIndex <= _giveawayDuration, "Giveaway completed");

    address[] storage addresses = giveawayAddresses[giveawayIndex - 1];
    require(addresses.length > 0, "No addresses available for the current day");

    for (uint256 i = 0; i < addresses.length; i++) {
        uint256 amount = _giveawayAmount; // Adjust the amount if needed

        // Transfer tokens from the giveaway wallet to the recipient
        _transferFrom(_giveawayWallet, addresses[i], amount);
    }

    giveawayIndex++;
}

    
}