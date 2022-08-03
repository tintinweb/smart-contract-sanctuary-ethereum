/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

/**
Telegram: https://t.me/rollsroyceinu

Twitter: https://twitter.com/Rolls_Royce_Inu

*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
contract ERC20Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "ERC20Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "ERC20Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
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
interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
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

contract RollsRoyceInu is Context, IERC20, ERC20Ownable {
    using SafeMath for uint256;
    string private constant _Name = "RollsRoyceInu";
    string private constant _Symbol = "RRI";
    uint8 private constant _Decimal = 18;
    uint256 private constant _Supply = 1*1e12*10**_Decimal;
    mapping(address => mapping(address => uint256)) private _Allowances;
    mapping(address => uint256) private _Balance;
    mapping(address => bool) private isContractsExcluded;
    mapping(address => bool) private isMaxWalletExcluded;
    mapping(address => bool) private isTaxExcluded;
    address payable liquidityAddress;
    address payable marketingAddress;
    address payable devAddress;
    address dead = address(0xdead);
    address public uniV2Pair;
    IUniswapV2Router02 public uniV2Router;
    address public uniV3Router;
    uint256 private maxWallet;
    uint256 private minTaxSwap;
    uint256 private marketingTokens;
    uint256 private liquidityTokens;
    uint256 private marketingTax;
    uint256 private liquidityTax;
    uint256 private divForSplitTax;
    uint256 private taxBuyMarketing;
    uint256 private taxBuyLiquidity;
    uint256 private taxSellMarketing;
    uint256 private taxSellLiquidity;
    uint256 public activeTradingBlock;
    uint256 public sniperPenaltyEnd;
    bool public limitsOn = false;
    bool public maxWalletOn = false;
    bool public tradesOpen = false;
    bool public contractBlocker = false;
    bool inSwapAndLiquify;
    bool private swapAndLiquifyStatus = false;
    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    constructor() payable {
        _Balance[address(this)] = _Supply;
        maxWallet = _Supply.mul(2).div(100);
        minTaxSwap = _Supply.mul(5).div(10000);
        marketingAddress = payable(owner());
        devAddress = payable(owner());
        liquidityAddress = payable(owner());
        taxBuyMarketing = 0;
        taxBuyLiquidity = 0;
        taxSellMarketing = 0;
        taxSellLiquidity = 0;
        isContractsExcluded[address(this)] = true;
        isTaxExcluded[owner()] = true;
        isTaxExcluded[dead] = true;
        isTaxExcluded[address(this)] = true;
        isTaxExcluded[marketingAddress] = true;
        isTaxExcluded[liquidityAddress] = true;
        isMaxWalletExcluded[address(this)] = true;
        isMaxWalletExcluded[owner()] = true;
        isMaxWalletExcluded[marketingAddress] = true;
        isMaxWalletExcluded[liquidityAddress] = true;
        isMaxWalletExcluded[dead] = true;
        emit Transfer(address(0), address(this), _Supply);
    }
    receive() external payable {}
    function name() external pure override returns (string memory) {
        return _Name;
    }
    function symbol() external pure override returns (string memory) {
        return _Symbol;
    }
    function decimals() external pure override returns (uint8) {
        return _Decimal;
    }
    function totalSupply() external pure override returns (uint256) {
        return _Supply;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _Balance[account];
    }
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _Allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        require(_msgSender() != address(0), "ERC20: Can not approve from zero address");
        require(spender != address(0), "ERC20: Can not approve to zero address");
        _Allowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }
    function internalApprove(address owner,address spender,uint256 amount) internal {
        require(owner != address(0), "ERC20: Can not approve from zero address");
        require(spender != address(0), "ERC20: Can not approve to zero address");
        _Allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        internalTransfer(_msgSender(), recipient, amount);
        return true;
    }
    function transferFrom(address sender,address recipient,uint256 amount) external override returns (bool) {
        internalTransfer(sender, recipient, amount);
        internalApprove(sender,_msgSender(),
        _Allowances[sender][_msgSender()].sub(amount, "ERC20: Can not transfer. Amount exceeds allowance"));
        return true;
    }
    function OpenMarket() external onlyOwner returns (bool){
        require(!tradesOpen);
        activeTradingBlock = block.number;
        sniperPenaltyEnd = block.timestamp.add(2 days);
        IUniswapV2Router02 _uniV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniV2Router = _uniV2Router;
        uniV3Router = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
        isContractsExcluded[address(uniV2Router)] = true;
        isContractsExcluded[address(uniV3Router)] = true;
        internalApprove(address(this), address(uniV2Router), _Supply);
        uniV2Pair = IUniswapV2Factory(_uniV2Router.factory()).createPair(address(this), _uniV2Router.WETH());
        isContractsExcluded[address(uniV2Pair)] = true;
        isMaxWalletExcluded[address(uniV2Pair)] = true;
        require(address(this).balance > 0);
        addLiquidity(balanceOf(address(this)), address(this).balance);
        maxWalletOn = true;
        swapAndLiquifyStatus = true;
        limitsOn = true;
        tradesOpen = true;
        return true;
    }
    function internalTransfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: Transfer amount must be greater than zero");
        if(!tradesOpen){
            require(isTaxExcluded[from] || isTaxExcluded[to]);
        }
        if (maxWalletOn == true && ! isMaxWalletExcluded[to]) {
            require(balanceOf(to).add(amount) <= maxWallet);
        }
        if(contractBlocker) {
            require(
                !isContract(to) && isContractsExcluded[from] ||
                !isContract(from) && isContractsExcluded[to] || 
                isContract(from) && isContractsExcluded[to] || 
                isContract(to) && isContractsExcluded[from]
                );
        }
        uint256 totalTokensToSwap = liquidityTokens.add(marketingTokens);
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= minTaxSwap;
        if (!inSwapAndLiquify && swapAndLiquifyStatus && balanceOf(uniV2Pair) > 0 && totalTokensToSwap > 0 && !isTaxExcluded[to] && !isTaxExcluded[from] && to == uniV2Pair && overMinimumTokenBalance) {
            taxTokenSwap();
            }
        if (isTaxExcluded[from] || isTaxExcluded[to]) {
            marketingTax = 0;
            liquidityTax = 0;
            divForSplitTax = marketingTax.add(liquidityTax);
        } else {
            if (from == uniV2Pair) {
                marketingTax = taxBuyMarketing;
                liquidityTax = taxBuyLiquidity;
                divForSplitTax = taxBuyMarketing.add(taxBuyLiquidity);
            }else if (to == uniV2Pair) {
                marketingTax = taxSellMarketing;
                liquidityTax = taxSellLiquidity;
                divForSplitTax = taxSellMarketing.add(taxSellLiquidity);
            }else {
                marketingTax = 0;
                liquidityTax = 0;
                divForSplitTax = marketingTax.add(liquidityTax);
            }
        }
        tokenTransfer(from, to, amount);
    }
    function taxTokenSwap() internal lockTheSwap {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = marketingTokens.add(liquidityTokens);
        uint256 swapLiquidityTokens = liquidityTokens.div(2);
        uint256 amountToSwapForETH = contractBalance.sub(swapLiquidityTokens);
        uint256 initialETHBalance = address(this).balance;
        swapTokensForETH(amountToSwapForETH); 
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        uint256 ethForMarketing = ethBalance.mul(marketingTokens).div(totalTokensToSwap);
        uint256 ethForLiquidity = ethBalance.sub(ethForMarketing);
        marketingTokens = 0;
        liquidityTokens = 0;
        (bool success,) = address(marketingAddress).call{value: ethForMarketing}("");
        if(ethForLiquidity != 0 && swapLiquidityTokens != 0) {
            addLiquidity(swapLiquidityTokens, ethForLiquidity);
        }
        if(address(this).balance > 5 * 1e17){
            (success,) = address(devAddress).call{value: address(this).balance}("");
        }
    }
    function swapTokensForETH(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniV2Router.WETH();
        internalApprove(address(this), address(uniV2Router), tokenAmount);
        uniV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        internalApprove(address(this), address(uniV2Router), tokenAmount);
        uniV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidityAddress,
            block.timestamp
        );
    }
    function calculateTax(uint256 amount) internal view returns (uint256) {
        return amount.mul(marketingTax.add(liquidityTax)).div(100);
    }
    function splitTaxTokens(uint256 taxTokens) internal {
        marketingTokens += taxTokens.mul(marketingTax).div(divForSplitTax);
        liquidityTokens += taxTokens.mul(liquidityTax).div(divForSplitTax);
    }
    function tokenTransfer(address sender,address recipient,uint256 amount) internal {
        if(divForSplitTax != 0){
            uint256 taxTokens = calculateTax(amount);
            uint256 transferTokens = amount.sub(taxTokens);
            splitTaxTokens(taxTokens);
            _Balance[sender] -= amount;
            _Balance[recipient] += transferTokens;
            _Balance[address(this)] += taxTokens;
            emit Transfer(sender, recipient, transferTokens);
        }else{
            _Balance[sender] -= amount;
            _Balance[recipient] += amount;
            emit Transfer(sender, recipient, amount);
        }
    }
    function isContract(address account) public view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }
    function addRemoveContract(address account, bool trueORfalse) external onlyOwner {
        isContractsExcluded[account] = trueORfalse;
    }
    function isExcludedContract(address account) public view returns (bool) {
        return isContractsExcluded[account];
    }
    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = address(devAddress).call{value: address(this).balance}("");
    }
    function manualSwapTax() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        require(contractBalance >= _Supply.mul(5).div(10000), "ERC20: Can only swap back if more than 0.05% of tokens stuck on contract");
        taxTokenSwap();
    }
    function ExcludedContractAccount(address account, bool trueORfalse) external onlyOwner {
        isContractsExcluded[address(account)] = trueORfalse;
    }
    function ExcludedFromTax(address account, bool trueORfalse) external onlyOwner {
        isTaxExcluded[address(account)] = trueORfalse;
    }
    function ExcludedFromMaxWallet(address account, bool trueORfalse) external onlyOwner {
        isMaxWalletExcluded[address(account)] = trueORfalse;
    }
    function MaxWalletAmount(uint256 percent, uint256 divider) external onlyOwner {
        maxWallet = _Supply.mul(percent).div(divider);
        require(maxWallet <=_Supply.mul(4).div(100));
    }
    function StatusLimits(bool trueORfalse) external onlyOwner {
        limitsOn = trueORfalse;
    }
    function StatusMaxWallet(bool trueORfalse) external onlyOwner {
       maxWalletOn = trueORfalse;
    }
    function StatusContractBlocker(bool trueORfalse) external onlyOwner {
        contractBlocker = trueORfalse;
    }
    function SwapAndLiquifyStatus(bool trueORfalse) external onlyOwner {
        swapAndLiquifyStatus = trueORfalse;
    }
    function Taxes(uint256 buyMarketingTax, uint256 buyLiquidityTax, uint256 sellMarketingTax, uint256 sellLiquidityTax) external onlyOwner {
        taxBuyMarketing = buyMarketingTax;
        taxBuyLiquidity = buyLiquidityTax;
        taxSellMarketing = sellMarketingTax;
        taxSellLiquidity = sellLiquidityTax;
    }
}