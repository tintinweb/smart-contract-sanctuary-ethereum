/**
 *Submitted for verification at Etherscan.io on 2022-07-03
*/

// SPDX-License-Identifier: NOLICENSE

/**
FOR PINKSALE AND COOKIESALE TESTING

DREAMCATION CLUB
Dreamcation Club is the FIRST progressive deflationary token with a Travel & Tours use cased that benefits the 
holder by giving free dream vacation, lifetime destination experience & YOLO activity bucket list. 
With us you can explore the world both Domestic & International Travel. We are the next level of AIRBNB that 
revolutionize tourism and preserving wonders of nature.  

By simply holding the required $Dreamcation Club you will get exclusive access to world class travel & destination
experiences through premium rewards, discounts and giveaways.


TOKEN DISTRIBUTION:
MAX SUPPLY: 10,000,000,000
90% of the supply sent to burn prior to launch
10% is the actual circulation supply. 

$DREAMCATION CLUB TAXES: 
11% BUY TAX, 11% SELL TAX AND 11% TRANSFER TAX
 
TOKENOMICS:
1% AUTOBURN - 1% of Token will be burn automatically in every buy, sell and transfer transactions
3% Club Treasury Reward – This is for our mission wallet for the sustainability of the dream destination experiences.
3% Liquidity – This will be automatically pooled to our Liquidity Locked Mission.
2% Marketing – To onboard world class partnerships and influencers. This will keep us go farther with our CEX listings. 
2% Development – To keep us going with our roadmap & actual utility deliverables. 

Official Website: https://dreamcationclub.com/

Official Social Media Accounts: 
     Telegram https://t.me/dreamcationclub
     Twitter https://twitter.com/DreamcationClub
*/

pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}

contract BazSmartContract is Context, IERC20, Ownable {
    
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) lpPairs;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromMaxWalletSize;
    
    bool public swapEnabled;
    bool private swapping;

    IRouter public router;
    address public pair;

    uint8 private constant _decimals = 9;
    uint256 private _tTotal = 10000000000 * 10**_decimals; //10B
    uint256 public swapThreshold = 100001 * 10**_decimals; //100k
    uint256 public swapAmount = 1000001 * 10**_decimals; //1m
    uint256 public maxWalletSize = 10000001 * 10**9; //10m

    bool private _isTradingState = true;

    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address private routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; 

    string private constant _name = "DREAMCATION CLUB";
    string private constant _symbol = "DRMCLUB";

    struct Fees {
        uint burn;
        uint16 liquidity;
        uint16 reward;
        uint16 marketing;
        uint16 dev;
        uint16 totalSwap;
    }

    struct Ratios {
        uint burn;
        uint16 liquidity;
        uint16 reward;
        uint16 marketing;
        uint16 dev;
        uint16 total;
    }

    Fees public _buyTaxes = Fees({
        burn: 100,
        liquidity: 300,
        reward: 300,
        marketing: 200,
        dev: 200,
        totalSwap: 1100
        });

    Fees public _sellTaxes = Fees({
        burn: 100,
        liquidity: 300,
        reward: 300,
        marketing: 200,
        dev: 200,
        totalSwap: 1100
        });    

    Fees public _transferTaxes = Fees({
        burn: 100,
        liquidity: 300,
        reward: 300,
        marketing: 200,
        dev: 200,
        totalSwap: 1100
        });    

    Ratios public _ratios = Ratios({
        burn: 2,
        liquidity: 6,
        reward: 6,
        marketing: 4,
        dev: 4,
        total: 21
        });

    uint256 constant public maxBuyTaxes = 1200;
    uint256 constant public maxSellTaxes = 1200;
    uint256 constant public maxTransferTaxes = 1200;
    uint256 constant masterTaxDivisor = 10000;
   
    struct TaxWallets {
        address payable reward;
        address payable marketing;
        address payable dev;
    }
     
    TaxWallets public _taxWallets = TaxWallets({
        reward: payable(0xfE4B28b8b70A19F5734f4E936EAfbFD3950672ec),
        marketing: payable(0x8feE4D0beE0526ABd0c0134b559f17d813ff2432),
        dev: payable(0x6217704264DE84dD00AaBb56d783ee891A9DED32)
    });
    
    event UpdatedRouter(address oldRouter, address newRouter); 
    event AutoLiquify(uint256 amountCurrency, uint256 amountTokens);
    
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor () {
        IRouter _router = IRouter(routerAddress);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router;
        pair = _pair;
    
        _tOwned[owner()] = _tTotal;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallets.reward] = true;
        _isExcludedFromFee[_taxWallets.marketing] = true;
        _isExcludedFromFee[_taxWallets.dev] = true;
        _isExcludedFromFee[DEAD] = true;

        _isExcludedFromMaxWalletSize[owner()] = true;
        _isExcludedFromMaxWalletSize[address(this)] = true;
        _isExcludedFromMaxWalletSize[_taxWallets.reward] = true;
        _isExcludedFromMaxWalletSize[_taxWallets.marketing] = true;
        _isExcludedFromMaxWalletSize[_taxWallets.dev] = true;
        _isExcludedFromMaxWalletSize[DEAD] = true;

        _isTradingState = true;
        swapEnabled = true;

        emit Transfer(address(0), owner(), _tTotal);
    }

    function name() public pure returns (string memory) { return _name; }
    function symbol() public pure returns (string memory) { return _symbol; }
    function decimals() public pure returns (uint8) { return _decimals; }
    function totalSupply() public view override returns (uint256) {return _tTotal; }
    function balanceOf(address account) public view override returns (uint256) { return _tOwned[account]; }
      
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(_isTradingState == true, "Trading is currently disabled.");
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function tradingEnabled() public view returns (bool) {
        return _isTradingState;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    function multiSendTokens(address[] memory accounts, uint256[] memory amounts) external {
        require(accounts.length == amounts.length, "Lengths do not match.");
        for (uint8 i = 0; i < accounts.length; i++) {
            require(balanceOf(msg.sender) >= amounts[i]);
            _transfer(msg.sender, accounts[i], amounts[i]*10**_decimals);
        }
    }

   function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function setTaxesBuy(uint16 burn, uint16 liquidity, uint16 reward, uint16 marketing, uint16 dev) external onlyOwner {
        uint16 check = burn + liquidity + reward + marketing + dev;
        require(check <= maxBuyTaxes);
        _buyTaxes.burn = burn;
        _buyTaxes.liquidity = liquidity;
        _buyTaxes.reward = reward;
        _buyTaxes.marketing = marketing;
        _buyTaxes.dev = dev;
        _buyTaxes.totalSwap = check;
    }

    function setTaxesSell(uint16 burn, uint16 liquidity, uint16 reward, uint16 marketing, uint16 dev) external onlyOwner {
        uint16 check = burn + liquidity + reward + marketing + dev;
        require(check <= maxSellTaxes);
        _sellTaxes.burn = burn;
        _sellTaxes.liquidity = liquidity;
        _sellTaxes.reward = reward;
        _sellTaxes.marketing = marketing;
        _sellTaxes.dev = dev;
        _sellTaxes.totalSwap = check;
    }

    function setTaxesTransfer(uint16 burn, uint16 liquidity, uint16 reward, uint16 marketing, uint16 dev) external onlyOwner {
        uint16 check = burn + liquidity + reward + marketing + dev;
        require(check <= maxTransferTaxes);
        _transferTaxes.burn = burn;
        _transferTaxes.liquidity = liquidity;
        _transferTaxes.reward = reward;
        _transferTaxes.marketing = marketing;
        _transferTaxes.dev = dev;
        _transferTaxes.totalSwap = check;
    }

    function setRatios(uint16 burn, uint16 liquidity, uint16 reward, uint16 marketing, uint16 dev) external onlyOwner {
        _ratios.burn = burn;
        _ratios.liquidity = liquidity;
        _ratios.reward = reward;
        _ratios.marketing = marketing;
        _ratios.dev = dev;
        _ratios.total = liquidity + reward + marketing + dev;
    }
      
    function setWallets(address payable reward, address payable marketing, address payable dev) external onlyOwner {
        _taxWallets.reward = payable(reward);
        _taxWallets.marketing = payable(marketing);        
        _taxWallets.dev = payable(dev);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balanceOf(from),"You are trying to transfer more than your balance");    

        if (to != pair && !_isExcludedFromMaxWalletSize[to]) {
                require(amount + balanceOf(to) <= maxWalletSize, "Recipient exceeds max wallet size.");
        }
              
        uint256 contractTokenBalance = balanceOf(address(this));
        if(!swapping && swapEnabled && from != pair && !_isExcludedFromFee[from] && !_isExcludedFromFee[to] ){
            if (contractTokenBalance >= swapThreshold) {
                    if(contractTokenBalance >= swapAmount) { 
                        contractTokenBalance = swapAmount; }
                contractSwap(contractTokenBalance);
            }
        }
    
        _tokenTransfer(from, to, amount, !(_isExcludedFromFee[from] || _isExcludedFromFee[to]));
    }

    function contractSwap(uint256 tokens) private lockTheSwap{
        Ratios memory ratios = _ratios;
        if (ratios.total == 0) {
            return;
        }

        uint256 toLiquify = ((tokens * _ratios.liquidity) / _ratios.total) / 2;
        uint256 toSwapForEth = tokens - toLiquify;
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokens);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            toSwapForEth, //swapamount
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

        uint256 amtBalance = address(this).balance;
        uint256 liquidityBalance = (amtBalance * toLiquify) / toSwapForEth;
        if (toLiquify > 0) {
            router.addLiquidityETH{value: liquidityBalance}(
                address(this),
                toLiquify,
                0,
                0,
                owner(),
                block.timestamp
            );
            emit AutoLiquify(liquidityBalance, toLiquify);
        }
        ratios.total -= ratios.liquidity;
        amtBalance -= liquidityBalance;

        uint256 rewardBalance = (amtBalance * ratios.reward) / ratios.total;
        uint256 devBalance = (amtBalance * ratios.dev) / ratios.total;
        uint256 marketingBalance = amtBalance - (rewardBalance +  devBalance);
 
        if (ratios.reward > 0) {
            _taxWallets.reward.transfer(rewardBalance);
        }
        if (ratios.dev > 0) {
            _taxWallets.dev.transfer(devBalance);
        }
        if (ratios.marketing > 0) {
            _taxWallets.marketing.transfer(marketingBalance);
        }
   }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        _tOwned[sender] -= amount;
        uint256 amountReceived = (takeFee) ? takeTaxes(sender, recipient, amount) : amount;  

        _tOwned[recipient] += amountReceived;
        emit Transfer(sender, recipient, amountReceived);
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(router), tokenAmount);

        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function takeTaxes(address from, address to, uint256 amount) internal returns (uint256) {
        uint256 currentFee;
        uint256 currentBurn;

         if (lpPairs[from]) {
            currentBurn = _buyTaxes.burn;
            currentFee = _buyTaxes.totalSwap - _buyTaxes.burn ;
         } else if (lpPairs[to]) {
            currentBurn = _sellTaxes.burn;
            currentFee = _sellTaxes.totalSwap - _sellTaxes.burn;    
         } else {
            currentBurn = _transferTaxes.burn;
            currentFee = _transferTaxes.totalSwap - _transferTaxes.burn;           
         }
        
        uint256 burnAmount = amount * currentBurn / masterTaxDivisor;
        _tOwned[DEAD] += burnAmount;
        emit Transfer(from, DEAD, burnAmount);

    
        uint256 feesubAmount =  amount * currentFee / masterTaxDivisor;
        _tOwned[address(this)] += feesubAmount;
        emit Transfer(from, address(this), feesubAmount);

        uint256 feeAmount = feesubAmount + burnAmount;
        return amount - feeAmount;

    }

    function updateWallets(address payable reward, address payable marketing, address payable dev) external onlyOwner {
        _taxWallets.reward = payable(reward);
        _taxWallets.marketing = payable(marketing);        
        _taxWallets.dev = payable(dev);
    }

    function updateMaxWalletSize(uint256 amount) external onlyOwner {
        maxWalletSize = amount * 10 **_decimals;
    }

    function updateswapThreshold(uint256 amount) external onlyOwner{
        swapThreshold = amount * 10 **_decimals;
    }

    function updateswapAmount(uint256 amount) external onlyOwner{
        swapAmount = amount * 10 **_decimals;
    }

    function updateSwapEnabled(bool _enabled) external onlyOwner{
        swapEnabled = _enabled;
    }

    function updateRouterAndPair(address newRouter, address newPair) external onlyOwner{
        router = IRouter(newRouter);
        pair = newPair;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function excludeFromMaxWalletLimit(address account) public onlyOwner {
		_isExcludedFromMaxWalletSize[account] = true;
	}

    function includeInMaxWalletLimit(address account) public onlyOwner {
		_isExcludedFromMaxWalletSize[account] = false;
	}
    
    function rescueETH(uint256 weiAmount) external onlyOwner{
        require(address(this).balance >= weiAmount, "insufficient ETH balance");
        payable(msg.sender).transfer(weiAmount);
    }
    
    function rescueAnyERC20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {
        IERC20(_tokenAddr).transfer(_to, _amount);
    }

    receive() external payable{
    }
}