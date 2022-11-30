/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

// SPDX-License-Identifier: MIT
/* Smartcontract author: @TonyBoyDeFi
Genesis project contract on Ethereum blockchain */

pragma solidity 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

interface IUniswapV3Pair {
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

interface IUniswapV3Factory {
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

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
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

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _createInitialSupply(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds your balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// Uniswap & Pancakeswap Router

interface IUniswapV3Router01 {
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV3Router02 is IUniswapV3Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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

contract AGEN is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV3Router02 public uniswapV3Router;
    address public uniswapV3Pair;
    bool private swapping;

    address public marketingWallet;
    address public expensesWallet;

    uint256 public percentForMarketing = 50;
    bool public buyBackEnabled = true;

    uint256 public swapTokensAtAmount;

    uint256 private liquidityActiveBlock = 0;
    uint256 private tradingActiveBlock = 0;

    bool public tradingActive = true;
    bool public swapEnabled = true;

    address private presaleAddress;
    address private presaleRouterAddress;

    uint256 public feeDivisor = 100;

    uint256 public totalSellFees;
    uint256 public marketingSellFee;
    uint256 public expensesSellFee;

    uint256 public totalBuyFees;
    uint256 public marketingBuyFee;
    uint256 public expensesBuyFee;

    uint256 private tokensForMarketing;
    uint256 private tokensForExpenses;

    mapping (address => bool) private _isExcludedFromFees;

    mapping (address => bool) public automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event marketingWalletUpdated(address indexed newWallet, address indexed oldWallet);
    event expensesWalletUpdated(address indexed newWallet, address indexed oldWallet);



    constructor() ERC20("Alpha Genesis", "AGEN"){

        address newOwner = address(0x6Ad3855Fb29303a7c3B6a00D55422cad817119D7);

        // Total Supply minted once during deployment and never minted again | Set number in tokens
        uint256 totalSupply = 500000000 * (10**18);

        // Tokens for SwapAndLiquify and automated BuyBack | Set number in tokens
        swapTokensAtAmount = 7500 * (10**18);

        // Contracts Sell fees
        marketingSellFee = 3;
        expensesSellFee = 4;
        totalSellFees = marketingSellFee + expensesSellFee;

        // Contracts Buy fees
        marketingBuyFee = 2;
        expensesBuyFee = 2;
        totalBuyFees = marketingBuyFee + expensesBuyFee;

        // Project Marketing Wallet | Updateable at a later point if necessary
        marketingWallet = address(0x94E709272FA55BB86e61C1Ec829Ba04f61128578);

        // Project Expenses Wallet | Updateable at a later point if necessary
        expensesWallet = address(0xbCCA432372F1967B75B2acFCB2bfCe8F3C5EF629);

        // Router settings for Binance Smart Chain:
        // Pancakeswap testnet: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        // Pancakeswap mainnet: 0x10ED43C718714eb63d5aA57B78B54704E256024E

        // Router settings for Ethereum:
        // Uniswap V3 mainnet: 0xE592427A0AEce92De3Edee1F18E0157C05861564
        // Uniswap V2 testnet: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        // Uniswap V2 mainnet: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D

        IUniswapV3Router02 _uniswapV3Router = IUniswapV3Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        address _uniswapV3Pair = IUniswapV3Factory(_uniswapV3Router.factory())
            .createPair(address(this), _uniswapV3Router.WETH());

        uniswapV3Router = _uniswapV3Router;
        uniswapV3Pair = _uniswapV3Pair;

        _setAutomatedMarketMakerPair(_uniswapV3Pair, true);

        excludeFromFees(newOwner, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        _createInitialSupply(address(newOwner), totalSupply);
        transferOwnership(newOwner);
    }

    receive() external payable {

      }

    // Change SwapAndLiquidy token swap amounts | Set number in exact tokens
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool){
          swapTokensAtAmount = newAmount * (10**18);
          return true;
      }


    // Exclude a wallet from all fees | Only for presale addresses, presale router and the deployer of the contract
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    // Exclude multiple wallets from all fees | Only for presale addresses, presale router and the deployer of the contract
    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV3Pair, "The UniSwap pair cannot be removed from AutomatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    // Set a new project marketing wallet | Wallet name can be changed to whatever suites the best
    function updateMarketingWallet(address newMarketingWallet) external onlyOwner {
        require(newMarketingWallet != address(0), "cannot set to 0 address");
        excludeFromFees(newMarketingWallet, true);
        emit marketingWalletUpdated(newMarketingWallet, marketingWallet);
        marketingWallet = newMarketingWallet;
    }

    // Set a new expenses wallet | Wallet name can be changed to whatever suites the best
    function updateExpensesWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "cannot set to 0 address");
        excludeFromFees(newWallet, true);
        emit expensesWalletUpdated(newWallet, expensesWallet);
        expensesWallet = newWallet;
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
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

        if(!tradingActive || tradingActiveBlock + 2 >= block.number){
            require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is always active after deployment");
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        bool takeFee = !swapping;


        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;


        if(takeFee){

            // Assets selling process
            if (automatedMarketMakerPairs[to] && totalSellFees > 0){
                fees = amount.mul(totalSellFees).div(feeDivisor);
                tokensForMarketing += fees * marketingSellFee / totalSellFees;
                tokensForExpenses += fees * expensesSellFee / totalSellFees;
            }
            // Assets buying process
            else if(automatedMarketMakerPairs[from] && totalBuyFees > 0) {
                fees = amount.mul(totalBuyFees).div(feeDivisor);
                tokensForMarketing += fees * marketingBuyFee / totalBuyFees;
                tokensForExpenses += fees * expensesBuyFee / totalBuyFees;

                }


            if(fees > 0){
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);

    }

    function swapEthForNativeToken(uint256 ethAmount) private {
        if(ethAmount > 0){
            address[] memory path = new address[](2);
            path[0] = uniswapV3Router.WETH();
            path[1] = address(this);

            uniswapV3Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
                0,
                path,
                address(marketingWallet),
                block.timestamp
            );
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV3Router.WETH();

        _approve(address(this), address(uniswapV3Router), tokenAmount);

        uniswapV3Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        _approve(address(this), address(uniswapV3Router), tokenAmount);


        uniswapV3Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(0xdead),
            block.timestamp
        );

    }

    // Automated buyback to fight sell pressure

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForMarketing + tokensForExpenses;

        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        bool success;

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(contractBalance);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForMarketing = ethBalance.mul(tokensForMarketing).div(totalTokensToSwap);
        uint256 ethForExpenses= ethBalance.mul(tokensForExpenses).div(totalTokensToSwap);

        (success,) = address(expensesWallet).call{value: ethForExpenses}("");

        if(buyBackEnabled){
            (success,) = address(marketingWallet).call{value: ethForMarketing * percentForMarketing / 100}("Automated BuyBack completed");
            swapEthForNativeToken(address(this).balance);
        } else {
            (success,) = address(marketingWallet).call{value: address(this).balance}("Success");
        }
    }

    // Recovery functions for stuck native balances and accidentally sent ERC20 tokens

    // Function to recover stuck ETH from the contract address. Only callable by the owner
    function recoverContractETH() external onlyOwner {
        (bool success,) = address(msg.sender).call{value: address(this).balance}("Stuck ETH balance from contract address recovered");
        require(success, "Failed. Either caller is not the owner or address is not the contract address");
    }

    // Function to recover stuck or accidentaly sent ERC20 tokens from the contract
    function recoverERC20Token(address tokenAddress, uint256 tokens) external onlyOwner returns (bool success){
    return ERC20(tokenAddress).transfer(msg.sender, tokens);
    }

    //Function for automated buyback settings. Set in percentages for example: 50% = 50% to buyback and 50% to marketing wallet
    function marketingBuyBackSettings(bool _buyBackEnabled, uint256 _percentForMarketing) external onlyOwner {
        require(_percentForMarketing <= 100, "Must be set below 100%");
        percentForMarketing = _percentForMarketing;
        buyBackEnabled = _buyBackEnabled;
    }
}