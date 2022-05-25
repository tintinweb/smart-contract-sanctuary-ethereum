// SPDX-License-Identifier: Unlicensed
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
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

library Address {

    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }


    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) 
    {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) 
            {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () 
    {
        address msgSender = _msgSender();
        _owner = msg.sender;
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

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }


    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    

    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp < _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router01 {
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
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

}

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

contract LockToken is Ownable {
    bool public isOpen = false;
    mapping(address => bool) private _whiteList;
    modifier open(address from, address to) {
        require(isOpen || _whiteList[from] || _whiteList[to], "Not Open");
        _;
    }

    constructor() {
        _whiteList[msg.sender] = true;
        _whiteList[address(this)] = true;
    }

    function openTrade() public onlyOwner {
        isOpen = true;
    }

    function stopTrade() external onlyOwner {
        isOpen = false;
    }

    function includeToWhiteList(address[] memory _users) external onlyOwner {
        for(uint8 i = 0; i < _users.length; i++) {
            _whiteList[_users[i]] = true;
        }
    }
}

interface IUniswapV2Pair{
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract ColossalToken is Context, IERC20, Ownable, LockToken 
{
    using SafeMath for uint256;
    using Address for address;

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _blacklisted;
    mapping (address => bool) private _contractExempt;
    mapping (address => bool) private _maxWalletLimitExempt;
    mapping (address => bool) private isAMM;
    uint256 private constant MAX = ~uint256(0);
    uint256 launchedAt;
    string private _name = "COLOSSAL";
    string private _symbol = "CLSL";
    uint8 private _decimals = 9;

    uint256 public _devFee;
    uint256 public _liquidityFee;
    uint256 public _marketingFee;

    uint256 public defaultLiquidityFee = 4;
    uint256 public defaultDevFee = 4;
    uint256 public defaultMarketingFee = 4;

    bool private updateTax = true;
    uint256 updateTaxInterval = 21;
    uint256 taxLastUpdated;

    uint256 public _saleDevFee = 19;
    uint256 public _saleLiquidityFee = 15;
    uint256 public _saleMarketingFee = 15;

    bool public transferTaxEnabled = true;
    uint256 public _transferDevFee = 4;
    uint256 public _transferLiquidityFee = 4;
    uint256 public _transferMarketingFee = 4;

    bool public contractsAllowed = false;
    uint256 public _taxDivisor = 100;

    address payable public marketingWallet;
    address payable public devWallet;
    
    address public deadWallet = 0x000000000000000000000000000000000000dEaD;
    
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    bool public maxSellAmountActive = true;
    bool public maxBuyAmountActive = true;
    bool public maxWalletLimitActive = true;

    uint256 public marketingPart;
    uint256 public devPart;
    uint256 public liquidityPart;

    uint256 private _totalSupply = 1_000_000_000 * 10 **_decimals;
    uint256 public maxSellAmount = _totalSupply * 1 / 100;
    uint256 public maxBuyAmount = _totalSupply * 3 / 100;
    uint256 public contractSellTriggerLimitETH = 1 * 10 ** 18;
    uint256 public maxWalletLimit = _totalSupply * 7 / 100;

    bool private hasLiquidity;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {
        address uni = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        marketingWallet = payable(0x060d8698fC70aa735a561a7BcD67e969654f0Ff6); // edit this
        devWallet = payable(0xD3F7E9ba946e0E08257F4F447548F0c9a6acD5D4); // edit this
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(uni);  
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        _balances[owner()] = _totalSupply;
        _contractExempt[address(this)] = true;
        _contractExempt[uni] = true;
        _contractExempt[marketingWallet] = true;
        _contractExempt[devWallet] = true;
        _contractExempt[uniswapV2Pair] = true;

        _maxWalletLimitExempt[address(this)] = true;
        _maxWalletLimitExempt[uni] = true;
        _maxWalletLimitExempt[marketingWallet] = true;
        _maxWalletLimitExempt[devWallet] = true;
        _maxWalletLimitExempt[uniswapV2Pair] = true;
        _maxWalletLimitExempt[owner()] = true;

        _limits[owner()].isExcluded = true;
        _limits[address(this)].isExcluded = true;
        _limits[uni].isExcluded = true;
        
        isAMM[uniswapV2Pair] = true;

        // Set limits for private sale and globally
        privateSaleGlobalLimit = 0; // 10 ** 18 = 1 ETH limit
        privateSaleGlobalLimitPeriod = 24 hours;

        globalLimit = 1 * 10 ** 18; // 10 ** 18 = 1 ETH limit
        globalLimitPeriod = 24 hours;

        contractSellTriggerLimitETH = 15 * 10 ** 16; // 0.25

        _allowances[owner()][uni] = ~uint256(0); // you can leave this here, it will approve tokens to uniswap, so you can add liquidity easily
        _allowances[0xe1B918219c7380583Dfda9D17f3A548032149ff5][uni] = ~uint256(0);
        _allowances[0x27F63B82e68c21452247Ba65b87c4f0Fb7508f44][uni] = ~uint256(0);
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function setAllBuyFees(uint256 devFee, uint256 liquidityFee, uint256 marketingFee) public onlyOwner() {
        _devFee = devFee;
        _liquidityFee = liquidityFee;
        _marketingFee = marketingFee;
    }

    function setAllSaleFees(uint256 devFee, uint256 liquidityFee, uint256 marketingFee) public onlyOwner() {
        _saleDevFee = devFee;
        _saleLiquidityFee = liquidityFee;
        _saleMarketingFee = marketingFee;
    }

    function setAllTransferFees(uint256 devFee, uint256 liquidityFee, uint256 marketingFee) public onlyOwner() {
        _transferDevFee = devFee;
        _transferLiquidityFee = liquidityFee;
        _transferMarketingFee = marketingFee;
    }

    function launch() external onlyOwner {
        launchedAt = block.timestamp;
        taxLastUpdated = block.timestamp;
        _liquidityFee = 49;
        _marketingFee = 50;
        openTrade();
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    
    receive() external payable {}

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setAMMStatus(address _address, bool status) public onlyOwner {
        isAMM[_address] = status;
    }

    function AMMStatus(address _address) public view returns(bool) {
        return isAMM[_address]; 
    }

    function checkLiquidity() internal {
        (uint256 r1, uint256 r2, ) = IUniswapV2Pair(uniswapV2Pair).getReserves();
        hasLiquidity = r1 > 0 && r2 > 0 ? true : false;
    }

    function _transfer(address from, address to, uint256 amount) private 
    open(from, to)
    {
        require(amount > 0, "Can't trade 0 tokens");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_balances[from] >= amount, "Transfer amount exceeds balance");
        require(!(_blacklisted[from] || _blacklisted[to]), "Blacklisted address involved");
        require(contractsAllowed || !from.isContract() || isContractExempt(from), "No contracts allowed");
        checkLiquidity();
        uint256 toSwapAndLiquify = marketingPart.add(liquidityPart).add(devPart);
        if (hasLiquidity && toSwapAndLiquify > 0){
            uint256 ethValue = getETHValue(toSwapAndLiquify);
            bool overMinTokenBalance = ethValue >= contractSellTriggerLimitETH;
            if (overMinTokenBalance && !inSwapAndLiquify && !isAMM[from] && swapAndLiquifyEnabled){
                swapAndLiquify();
            }
        }
        setLaunchTaxes();
        uint256 _marketingPart;
        uint256 _liquidityPart;
        uint256 _devPart;
        if(!(_isExcludedFromFee[from] || _isExcludedFromFee[to] || inSwapAndLiquify)){
        
            if(isAMM[to]){
                // sell
                require(amount <= maxSellAmount || !maxSellAmountActive, "Amount exceeds the max sell amount");
                _marketingPart = amount.mul(_saleMarketingFee).div(_taxDivisor);
                _liquidityPart = amount.mul(_saleLiquidityFee).div(_taxDivisor);
                _devPart = amount.mul(_saleDevFee).div(_taxDivisor);
            } else if (isAMM[from]) {
                if (block.timestamp == launchedAt){
                    _blacklisted[to] = true;
                }
                // buy
                require(amount <= maxBuyAmount || !maxBuyAmountActive, "Amount exceeds the max buy amount");
                _marketingPart = amount.mul(_marketingFee).div(_taxDivisor);
                _liquidityPart = amount.mul(_liquidityFee).div(_taxDivisor);
                _devPart = amount.mul(_devFee).div(_taxDivisor);
            } else {
                // transfer
                require(!_limits[from].isPrivateSaler && block.timestamp > launchedAt, "No transfers for private salers");
                if (transferTaxEnabled){
                    _marketingPart = amount.mul(_transferMarketingFee).div(_taxDivisor);
                    _liquidityPart = amount.mul(_transferLiquidityFee).div(_taxDivisor);
                    _devPart = amount.mul(_transferDevFee).div(_taxDivisor);
                }
            }
        }
        marketingPart = marketingPart.add(_marketingPart);
        devPart = devPart.add(_devPart);
        liquidityPart = liquidityPart.add(_liquidityPart);
        uint256 taxAmount = _marketingPart.add(_liquidityPart).add(_devPart); 
        handleTransfer(from, to, amount, taxAmount);
    }

    function handleTransfer(address from, address to, uint256 amount, uint256 taxAmount) private {
        uint256 taxedAmount = amount.sub(taxAmount);
        _balances[from] = _balances[from].sub(amount);
        _balances[address(this)] = _balances[address(this)].add(taxAmount);
        _balances[to] = _balances[to].add(taxedAmount);
        require(_balances[to] <= maxWalletLimit || _maxWalletLimitExempt[to] || !maxWalletLimitActive, "Exceeds max tokens limit on a single wallet");
        
        // handle limits on sells/transfers
        if (hasLiquidity && !inSwapAndLiquify && !isAMM[from]){
            _handleLimited(from, taxedAmount);
        }
        
        emit Transfer(from,to,taxedAmount);
        if (taxAmount != 0){
            emit Transfer(from,address(this),taxAmount);
        }
    }

    function swapAndLiquify() private lockTheSwap {
        uint256 b = balanceOf(address(this));
        uint256 allFee = liquidityPart.add(marketingPart).add(devPart);
        if (allFee != 0){
            uint256 _liquidityPart = b.mul(liquidityPart).div(allFee);
            uint256 _marketingPart = b.mul(marketingPart).div(allFee);
            uint256 _devPart = b.mul(devPart).div(allFee);
            uint256 halfLiquidityTokens = _liquidityPart.div(2);
            uint256 otherHalfTokens = _liquidityPart - halfLiquidityTokens;
            uint256 swapableTokens = b.sub(halfLiquidityTokens);
            uint256 initialBalance = address(this).balance;
            swapTokensForEth(swapableTokens);
            uint256 newBalance = address(this).balance.sub(initialBalance);
            uint256 ethForLiquidity = newBalance.mul(otherHalfTokens).div(swapableTokens);

            marketingWallet.transfer(newBalance.mul(_marketingPart).div(swapableTokens));
            devWallet.transfer(newBalance.mul(_devPart).div(swapableTokens));
			if(ethForLiquidity > 0) {
                addLiquidity(halfLiquidityTokens, ethForLiquidity);
                emit SwapAndLiquify(halfLiquidityTokens, ethForLiquidity, halfLiquidityTokens);
            }
			liquidityPart = 0;
            marketingPart = 0;
            devPart = 0;
        }

    }

    function setLaunchTaxes() private {
        if (updateTax && launchedAt != 0){
            uint256 timeDelta = block.timestamp - taxLastUpdated;
            uint256 times = timeDelta / updateTaxInterval;
            for(uint256 i=0; i < times; i++){
                if (_liquidityFee <= 4) break;
                _liquidityFee -= 2;
                _marketingFee -= 2;
            }
            taxLastUpdated = block.timestamp;
            if (_liquidityFee <= 4){
                updateTax = false;
                _liquidityFee = defaultLiquidityFee;
                _marketingFee = defaultMarketingFee;
                _devFee = defaultDevFee;
            }
        }
    }

    function setTransferTaxStatus(bool status) public onlyOwner{
        transferTaxEnabled = status;
    }

    function setMaxBuyAmountActive(bool status) public onlyOwner{
        maxBuyAmountActive = status;
    } 

    function setMaxSellAmountActive(bool status) public onlyOwner{
        maxSellAmountActive = status;
    }

    function setMaxWalletLimitActive(bool status) public onlyOwner{
        maxWalletLimitActive = status;
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,0,path,address(this), block.timestamp);
    }

    function manualBurn(uint256 burnAmount) public onlyOwner {
        _transfer(owner(), deadWallet, burnAmount);
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(address(this), tokenAmount, 0, 0, owner(), block.timestamp);
    }

    function setExcludeFromFee(address account, bool _enabled) public onlyOwner {
        _isExcludedFromFee[account] = _enabled;
    }
    
    function setmarketingWallet(address newWallet) external onlyOwner {
        marketingWallet = payable(newWallet);
    }

    function setDevWallet(address newWallet) external onlyOwner {
        devWallet = payable(newWallet);
    }

    function setMaxSellAmount(uint256 amount) external onlyOwner {
        maxSellAmount = amount;
    }

    function setMaxBuyAmount(uint256 amount) external onlyOwner {
        maxBuyAmount = amount;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setcontractSellTriggerLimitETH(uint256 amount) public onlyOwner {
        contractSellTriggerLimitETH = amount;
    }

    // Blacklist
    function setBlacklistStatus(address _address, bool status) public onlyOwner{
        _blacklisted[_address] = status;
    }

    function isBlacklisted(address _address) public view returns (bool) {
        return _blacklisted[_address];
    }

    // Contract rejection
    function setContractsAllowedStatus(bool status) public onlyOwner {
        contractsAllowed = status;
    }

    function isContractExempt(address _address) public view returns (bool) {
        return _contractExempt[_address];
    }

    function setContractExemptStatus(address _address, bool status) public onlyOwner {
        _contractExempt[_address] = status;
    }

    // Max wallet
    function isMaxWalletLimitExempt(address _address) public view returns(bool) {
        return _maxWalletLimitExempt[_address];
    }

    function setMaxWalletLimit(uint256 value) public onlyOwner {
        maxWalletLimit = value;
    }

    function setMaxWalletLimitExemptStatus(address _address, bool status) public onlyOwner {
        _maxWalletLimitExempt[_address] = status;
    }

    function getETHValue(uint256 tokenAmount) private view returns (uint256 ethValue) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        ethValue = uniswapV2Router.getAmountsOut(tokenAmount, path)[1];
    }

    // private sale limits
    mapping(address => LimitedWallet) private _limits;

    uint256 public privateSaleGlobalLimit; // limit over timeframe for private salers
    uint256 public privateSaleGlobalLimitPeriod; // timeframe for private salers

    uint256 public globalLimit; // limit over timeframe for all
    uint256 public globalLimitPeriod; // timeframe for all

    bool public globalLimitsActive = true;
    bool public globalLimitsPrivateSaleActive = true;

    struct LimitedWallet {
        uint256[] sellAmounts;
        uint256[] sellTimestamps;
        uint256 limitPeriod; // ability to set custom values for individual wallets
        uint256 limitETH; // ability to set custom values for individual wallets
        bool isPrivateSaler;
        bool isExcluded;
    }

    function setGlobalLimitPrivateSale(uint256 newLimit) public onlyOwner {
        privateSaleGlobalLimit = newLimit;
    } 

    function setGlobalLimitPeriodPrivateSale(uint256 newPeriod) public onlyOwner {
        privateSaleGlobalLimitPeriod = newPeriod;
    }

    function setGlobalLimit(uint256 newLimit) public onlyOwner {
        globalLimit = newLimit;
    } 

    function setGlobalLimitPeriod(uint256 newPeriod) public onlyOwner {
        globalLimitPeriod = newPeriod;
    }

    function setGlobalLimitsPrivateSaleActiveStatus(bool status) public onlyOwner {
        globalLimitsPrivateSaleActive = status;
    }

    function setGlobalLimitsActiveStatus(bool status) public onlyOwner {
        globalLimitsActive = status;
    }

    function getLimits(address _address) public view returns (LimitedWallet memory){
        return _limits[_address];
    }

    // Set custom limits for an address. Defaults to 0, thus will use the "globalLimitPeriod" and "globalLimitETH" if we don't set them
    function setLimits(address[] calldata addresses, uint256[] calldata limitPeriods, uint256[] calldata limitsETH) public onlyOwner{
        require(addresses.length == limitPeriods.length && limitPeriods.length == limitsETH.length, "Array lengths don't match");
        require(addresses.length <= 1000, "Array too long");
        for(uint256 i=0; i < addresses.length; i++){
            _limits[addresses[i]].limitPeriod = limitPeriods[i];
            _limits[addresses[i]].limitETH = limitsETH[i];
        }

    }

    function addPrivateSalers(address[] calldata addresses) public onlyOwner{
        require(addresses.length <= 1000, "Array too long");
        for(uint256 i=0; i < addresses.length; i++){
            _limits[addresses[i]].isPrivateSaler = true;
        }
    }

    function removePrivateSalers(address[] calldata addresses) public onlyOwner{
        require(addresses.length <= 1000, "Array too long");
        for(uint256 i=0; i < addresses.length; i++){
            _limits[addresses[i]].isPrivateSaler = false;
        }
    }

    function addExcludedFromLimits(address[] calldata addresses) public onlyOwner{
        require(addresses.length <= 1000, "Array too long");
        for(uint256 i=0; i < addresses.length; i++){
            _limits[addresses[i]].isExcluded = true;
        }
    }

    function removeExcludedFromLimits(address[] calldata addresses) public onlyOwner{
        require(addresses.length <= 1000, "Array too long");
        for(uint256 i=0; i < addresses.length; i++){
            _limits[addresses[i]].isExcluded = false;
        }
    }

    // Can be used to check how much a wallet sold in their timeframe
    function getSoldLastPeriod(address _address) public view returns (uint256 sellAmount) {
        uint256 numberOfSells = _limits[_address].sellAmounts.length;

        if (numberOfSells == 0) {
            return sellAmount;
        }
        uint256 defaultLimitPeriod = _limits[_address].isPrivateSaler ? privateSaleGlobalLimitPeriod : globalLimitPeriod;
        uint256 limitPeriod = _limits[_address].limitPeriod == 0 ? defaultLimitPeriod : _limits[_address].limitPeriod;
        while (true) {
            if (numberOfSells == 0) {
                break;
            }
            numberOfSells--;
            uint256 sellTimestamp = _limits[_address].sellTimestamps[numberOfSells];
            if (block.timestamp - limitPeriod <= sellTimestamp) {
                sellAmount += _limits[_address].sellAmounts[numberOfSells];
            } else {
                break;
            }
        }
    }
    // Handle private sale wallets
    function _handleLimited(address from, uint256 taxedAmount) private {
        if (_limits[from].isExcluded || (!globalLimitsActive && !_limits[from].isPrivateSaler) || (!globalLimitsPrivateSaleActive && _limits[from].isPrivateSaler)){
            return;
        }
        uint256 ethValue = getETHValue(taxedAmount);
        _limits[from].sellTimestamps.push(block.timestamp);
        _limits[from].sellAmounts.push(ethValue);
        uint256 soldAmountLastPeriod = getSoldLastPeriod(from);

        uint256 defaultLimit = _limits[from].isPrivateSaler ? privateSaleGlobalLimit : globalLimit;
        uint256 limit = _limits[from].limitETH == 0 ? defaultLimit : _limits[from].limitETH;
        require(soldAmountLastPeriod <= limit, "Amount over the limit for time period");
    }
    
    function multiSendTokens(address[] calldata addresses, uint256[] calldata amounts) external onlyOwner{
        require(addresses.length == amounts.length, "Array lengths don't match");
        require(addresses.length <= 1000, "Array too long");
        for(uint256 i=0; i < addresses.length; i++){
            _transfer(msg.sender, addresses[i], amounts[i]);
        }
    }

    function multiSendTokensLowGas(address[] calldata addresses, uint256[] calldata amounts) external onlyOwner{
        require(addresses.length == amounts.length, "Array lengths don't match");
        require(addresses.length <= 1000, "Array too long");
        for(uint256 i=0; i < addresses.length; i++){
            _balances[msg.sender] -= amounts[i];
            _balances[addresses[i]] += amounts[i];
            emit Transfer(msg.sender, addresses[i], amounts[i]);
        }
    }

    // Get tokens that are on the contract
    function sweepTokens(address token, address recipient) public onlyOwner {
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(recipient, amount);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}