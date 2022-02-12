/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

// SPDX-License-Identifier: NOLICENSE
// New3 dev marketing ctrbuyback and liquidity
pragma solidity ^0.8.9;

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
        function createPair(address tokenA, address tokenB) external returns (address lppair);
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

contract SmartContract is Context, IERC20, Ownable {
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) lpPairs;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    
    bool public swapEnabled;
    bool private swapping;

    IRouter public router;
    address public lpPair;

    uint8 private constant _decimals = 9;
    uint256 private _tTotal = 1000000000000000000 * 10**_decimals; //1Q
    uint256 public swapTokensAtAmount = 1000001 * 10**_decimals; //1M
    uint256 public maxTxAmount = 500000000000001 * 10**_decimals; //500T
    uint256 public maxWalletSize = 1000000000000001 * 10**9; //1Q

    uint[] public contractSwapDescription;
    uint[] public canSwapDescription;

    bool private _isTradingState = true;
    mapping (address => uint256) public lastTrade;
    mapping (address => uint256) public _lastTrade;
    bool public coolDownEnabled = true;
    uint256 public coolDownTime = 69 seconds;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address private routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;  //uniswap v2

    string private constant _name = "New6";
    string private constant _symbol = "New6";

    struct Fees {
        uint16 buyFee;
        uint16 sellFee;
        uint16 transferFee;
    }

    struct Ratios {
        uint16 liquidity;
        uint16 marketing;
        uint16 ctrbuyback;
        uint16 dev;
        uint16 total;
    }

    Fees public _taxRates = Fees({
        buyFee: 1200,
        sellFee: 1200,
        transferFee: 1200});

    Ratios public _ratios = Ratios({
        liquidity: 3,
        marketing: 3,
        ctrbuyback: 3,
        dev: 3,
        total: 12
        });

    uint256 constant public maxBuyTaxes = 2000;
    uint256 constant public maxSellTaxes = 2000;
    uint256 constant public maxTransferTaxes = 2000;
    uint256 constant masterTaxDivisor = 10000;
   
    struct TaxWallets {
        address payable marketing;
        address payable ctrbuyback;
        address payable dev;
    }

    TaxWallets public _taxWallets = TaxWallets({
        marketing: payable(0x3a2775eED458cef0f2C6cFa169Ff6f4E1ed17885),
        ctrbuyback: payable(0xB1e0f37eb4591221323a9f6bac7Ac694A9fE4786),
        dev: payable(0xe97C552e62D0E3129CC7E4E71853AA7B6FE384A8)
    });
    
    event UpdatedRouter(address oldRouter, address newRouter); // create function
    event AutoLiquify(uint256 amountCurrency, uint256 amountTokens);
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor () {
        IRouter _router = IRouter(routerAddress);
        lpPair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router;
        lpPairs[lpPair] = true;
    
        _tOwned[owner()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[DEAD] = true;

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

    function setTaxes(uint16 buyFee, uint16 sellFee, uint16 transferFee) external onlyOwner {
        require(buyFee <= maxBuyTaxes
                && sellFee <= maxSellTaxes
                && transferFee <= maxTransferTaxes,
                "Cannot exceed maximums.");
        _taxRates.buyFee = buyFee;
        _taxRates.sellFee = sellFee;
        _taxRates.transferFee = transferFee;
    }

      function setRatios(uint16 liquidity, uint16 marketing, uint16 ctrbuyback, uint16 dev) external onlyOwner {
        _ratios.liquidity = liquidity;
        _ratios.marketing = marketing;
        _ratios.ctrbuyback = ctrbuyback;
        _ratios.dev = dev;
        _ratios.total = liquidity + marketing + ctrbuyback + dev;
    }
      
    function setWallets(address payable marketing, address payable ctrbuyback, address payable dev) external onlyOwner {
        _taxWallets.marketing = payable(marketing);
        _taxWallets.ctrbuyback = payable(ctrbuyback);
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

        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to] && !swapping){
            require(amount <= maxTxAmount ,"Amount is exceeding maxTxAmount");

            if(from != lpPair && coolDownEnabled){
                uint256 timePassed = block.timestamp - _lastTrade[from];
                require(timePassed > coolDownTime, "You must wait coolDownTime");
                _lastTrade[from] = block.timestamp;
            }
            if(to != lpPair && coolDownEnabled){
                uint256 timePassed2 = block.timestamp - _lastTrade[to];
                require(timePassed2 > coolDownTime, "You must wait coolDownTime");
                _lastTrade[to] = block.timestamp;
            }
        }

        if (to != lpPair && !_isExcludedFromFee[to]) {
                require(amount + balanceOf(to) <= maxWalletSize, "Recipient exceeds max wallet size.");
        }
        
        if (lpPairs[to]) { 
            bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;
            if(!swapping && swapEnabled && canSwap && from != lpPair && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            contractSwap(swapTokensAtAmount);
            }
        }
        delete canSwapDescription;
        canSwapDescription.push(balanceOf(address(this)));
        canSwapDescription.push(swapTokensAtAmount);
        _tokenTransfer(from, to, amount, !(_isExcludedFromFee[from] || _isExcludedFromFee[to]));
        canSwapDescription.push(amount);
    }

    function showcanSwapDescription() public view returns(uint[] memory){        
        return canSwapDescription;
    }
    

    function contractSwap(uint256 tokens) private lockTheSwap{
        delete contractSwapDescription;
        Ratios memory ratios = _ratios;
        if (ratios.total == 0) {
            return;
        }

        uint256 toLiquify = ((tokens * _ratios.liquidity) / _ratios.total) / 2;
        contractSwapDescription.push(toLiquify);
        uint256 toSwapForEth = tokens - toLiquify;
        contractSwapDescription.push(toSwapForEth);

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
        contractSwapDescription.push(amtBalance);
        contractSwapDescription.push(liquidityBalance);
       if (toLiquify > 0) {
            router.addLiquidityETH{value: liquidityBalance}(
                address(this),
                toLiquify,
                0,
                0,
                DEAD,
                block.timestamp
            );
            emit AutoLiquify(liquidityBalance, toLiquify);
        }
        ratios.total -= ratios.liquidity;
        amtBalance -= liquidityBalance;

        uint256 ctrbuybackBalance = (amtBalance * ratios.ctrbuyback) / ratios.total;
        uint256 devBalance = (amtBalance * ratios.dev) / ratios.total;
        uint256 marketingBalance = amtBalance - (ctrbuybackBalance + devBalance);
        if (ratios.ctrbuyback > 0) {
            _taxWallets.ctrbuyback.transfer(ctrbuybackBalance);
        }
        contractSwapDescription.push(ctrbuybackBalance);
        if (ratios.dev > 0) {
            _taxWallets.dev.transfer(devBalance);
        }
        contractSwapDescription.push(devBalance);
        if (ratios.marketing > 0) {
            _taxWallets.marketing.transfer(marketingBalance);
        }
        contractSwapDescription.push(marketingBalance);          
    }

    function showContractSwapDescriptionDescription() public view returns(uint[] memory){        
        return contractSwapDescription;
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
        if (lpPairs[from]) {
            currentFee = _taxRates.buyFee;
        } else if (lpPairs[to]) {
            currentFee = _taxRates.sellFee;
        } else {
            currentFee = _taxRates.transferFee;
        }

        uint256 feeAmount = amount * currentFee / masterTaxDivisor;

        _tOwned[address(this)] += feeAmount;
        emit Transfer(from, address(this), feeAmount);

        return amount - feeAmount;
    }

    function updateWallets(address payable marketing, address payable ctrbuyback, address payable dev) external onlyOwner {
        _taxWallets.marketing = payable(marketing);
        _taxWallets.ctrbuyback = payable(ctrbuyback);
        _taxWallets.dev = payable(dev);
    }

    function updateMaxTxAmt(uint256 amount) external onlyOwner{
        maxTxAmount = amount * 10 **_decimals;
    }

    function updateMaxWalletSizeAmt(uint256 amount) external onlyOwner {
        maxWalletSize = amount * 10 **_decimals;
    }

    function updateSwapTokensAtAmount(uint256 amount) external onlyOwner{
        swapTokensAtAmount = amount * 10 **_decimals;
    }

    receive() external payable{
    }
}