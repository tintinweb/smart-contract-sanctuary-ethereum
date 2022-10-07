/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

// SPDX-License-Identifier: MIT
/*
https://www.youtube.com/watch?v=cZYNADOHhVY
https://twitter.com/VitalikButerin
It relates the misery inflicted by a dragon-tyrant (a personification of the ageing process and death), 
who demands a tribute of thousands of people's lives per day and the actions of the people, including the king, who come together to fight back, eventually killing the dragon-tyrant.
*/

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
library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }
    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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
interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint256);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);
    function MINIMUM_LIQUIDITY() external pure returns (uint256);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function kLast() external view returns (uint256);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}

contract TYRANT is Context, IERC20, ERC20Ownable {
    using SafeMath for uint256;
    using Address for address;

    string private constant tokenName = "Fable of the Dragon";
    string private constant tokenSymbol = "TYRANT";
    uint8 private constant tokenDecimal = 18;
    uint256 private constant tokenSupply = 1e12 * 10**tokenDecimal;

    mapping(address => mapping(address => uint256)) private tokenAllowances;
    mapping(address => uint256) private tokenBalance;
    mapping(address => bool) private isContractsExcluded;
    mapping(address => bool) private isMaxWalletExcluded;
    mapping(address => bool) private isTaxExcluded;
    mapping(address => bool) public isSniper;
    mapping(address => bool) public isBot;

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
	uint256 private totalBurnedTokens;

    uint256 private marketingTax;
    uint256 private liquidityTax;
    uint256 private divForSplitTax;
    uint256 private taxBuyMarketing;
    uint256 private taxBuyLiquidity;
    uint256 private taxSellMarketing;
    uint256 private taxSellTreasury;
    uint256 private taxSellLiquidity;

    uint256 public activeTradingBlock;
    uint256 public sniperPenaltyEnd;

    bool public limitsOn = false;
    bool public maxWalletOn = false;
    bool public live = false;
    bool public contractBlocker = false;
    bool inSwapAndLiquify;
    bool private swapAndLiquifyStatus = false;
    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    constructor() payable {
        tokenBalance[address(this)] = tokenSupply;
        maxWallet = tokenSupply.mul(4).div(100);
        minTaxSwap = tokenSupply.mul(5).div(10000);

        marketingAddress = payable(0xd02b2269319e2c3C10cd35b42936bE5A5df75600);
        devAddress = payable(0xd02b2269319e2c3C10cd35b42936bE5A5df75600);

        liquidityAddress = payable(owner()); //LEAVE AS OWNER

        taxBuyMarketing = 25;
        taxBuyLiquidity = 0;
        taxSellMarketing = 25;
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
        
        emit Transfer(address(0), address(this), tokenSupply);
    }
    receive() external payable {}
    function name() external pure override returns (string memory) {
        return tokenName;
    }
    function symbol() external pure override returns (string memory) {
        return tokenSymbol;
    }
    function decimals() external pure override returns (uint8) {
        return tokenDecimal;
    }
    function totalSupply() external pure override returns (uint256) {
        return tokenSupply;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return tokenBalance[account];
    }
    function allowance(address owner, address spender) external view override returns (uint256) {
        return tokenAllowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        require(_msgSender() != address(0), "ERC20: Can not approve from zero address");
        require(spender != address(0), "ERC20: Can not approve to zero address");
        tokenAllowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }
    function internalApprove(address owner,address spender,uint256 amount) internal {
        require(owner != address(0), "ERC20: Can not approve from zero address");
        require(spender != address(0), "ERC20: Can not approve to zero address");
        tokenAllowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        internalTransfer(_msgSender(), recipient, amount);
        return true;
    }
    function transferFrom(address sender,address recipient,uint256 amount) external override returns (bool) {
        internalTransfer(sender, recipient, amount);
        internalApprove(sender,_msgSender(),
        tokenAllowances[sender][_msgSender()].sub(amount, "ERC20: Can not transfer. Amount exceeds allowance"));
        return true;
    }
    function AirDrop(address[] memory wallets, uint256[] memory percent) external onlyOwner{
        require(wallets.length < 100, "Can only airdrop 100 wallets per txn due to gas limits");
        for(uint256 i = 0; i < wallets.length; i++){
            address wallet = wallets[i];
            uint256 amount = tokenSupply.mul(percent[i]).div(100);
            internalTransfer(_msgSender(), wallet, amount);
        }
    }
    function GoLive() external onlyOwner returns (bool){
        require(!live, "ERC20: Trades already Live!");
        activeTradingBlock = block.number;
        sniperPenaltyEnd = block.timestamp.add(2 days);
        IUniswapV2Router02 _uniV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniV2Router = _uniV2Router;
        uniV3Router = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
        isContractsExcluded[address(uniV2Router)] = true;
        isContractsExcluded[address(uniV3Router)] = true;
        isMaxWalletExcluded[address(uniV2Router)] = true;
        internalApprove(address(this), address(uniV2Router), tokenSupply);
        uniV2Pair = IUniswapV2Factory(_uniV2Router.factory()).createPair(address(this), _uniV2Router.WETH());
        isContractsExcluded[address(uniV2Pair)] = true;
        isMaxWalletExcluded[address(uniV2Pair)] = true;
        require(address(this).balance > 0, "ERC20: Must have ETH on contract to Go Live!");
        addLiquidity(balanceOf(address(this)), address(this).balance);
        launchSetLiquidityAddress(dead);
        maxWalletOn = true;
        swapAndLiquifyStatus = true;
        limitsOn = true;
        live = true;
        return true;
    }
    function internalTransfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: Transfer amount must be greater than zero");
        require(!isBot[from], "ERC20: Can not transfer from BOT");
        if(!live){
            require(isTaxExcluded[from] || isTaxExcluded[to], "ERC20: Trading Is Not Live!");
        }
        if (maxWalletOn == true && ! isMaxWalletExcluded[to]) {
            require(balanceOf(to).add(amount) <= maxWallet, "ERC20: Max amount of tokens for wallet reached");
        }
        if(limitsOn){
            if (from != owner() && to != owner() && to != address(0) && to != dead && to != uniV2Pair) {
                for (uint x = 0; x < 3; x++) {
                    if(block.number == activeTradingBlock.add(x)) {
                        isSniper[to] = true;
                    }
                }
            }
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
                if(isSniper[from] && sniperPenaltyEnd >= block.timestamp){
                    marketingTax = 85;
                    liquidityTax = 10;
                    divForSplitTax = marketingTax.add(liquidityTax);
                }
            }else {
                require(!isSniper[from] || sniperPenaltyEnd <= block.timestamp, "ERC20: Snipers can not transfer till penalty time is over");
                marketingTax = 0;
                liquidityTax = 0;
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
            tokenBalance[sender] -= amount;
            tokenBalance[recipient] += transferTokens;
            tokenBalance[address(this)] += taxTokens;
            emit Transfer(sender, recipient, transferTokens);
        }else{
            tokenBalance[sender] -= amount;
            tokenBalance[recipient] += amount;
            emit Transfer(sender, recipient, amount);
        }
    }
    function launchSetLiquidityAddress(address LPAddress) internal {
        liquidityAddress = payable(LPAddress);
        isTaxExcluded[liquidityAddress] = true;
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
        (success,) = address(owner()).call{value: address(this).balance}("");
    }
    function withdrawStuckTokens(uint256 percent) external onlyOwner {
        internalTransfer(address(this), owner(), tokenSupply*percent/100);
    }
    function manualBurnTokensFromLP(uint256 percent) external onlyOwner returns (bool){
        require(percent <= 10, "ERC20: May not nuke more than 10% of tokens in LP");
        uint256 liquidityPairBalance = this.balanceOf(uniV2Pair);
        uint256 amountToBurn = liquidityPairBalance.mul(percent).div(10**2);
        if (amountToBurn > 0){
            internalTransfer(uniV2Pair, dead, amountToBurn);
        }
        totalBurnedTokens = balanceOf(dead);
        require(totalBurnedTokens <= tokenSupply * 50 / 10**2, "ERC20: Can not burn more then 50% of supply");
        IUniswapV2Pair pair = IUniswapV2Pair(uniV2Pair);
        pair.sync();
        return true;
    }
    function manualSwapTax() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        require(contractBalance >= tokenSupply.mul(5).div(10000), "ERC20: Can only swap back if more than 0.05% of tokens stuck on contract");
        taxTokenSwap();
    }
    function addBot(address account) external onlyOwner {
        require(!isBot[account], "ERC20: Account already added");
        isBot[account] = true;
    }
	function removeBot(address account) external onlyOwner {
        require(isBot[account], "ERC20: Account is not bot");
        isBot[account] = false;
    }
	function removeSniper(address account) external onlyOwner {
        require(isSniper[account], "ERC20: Account is not sniper");
        isSniper[account] = false;
    }
    function setExcludedContractAccount(address account, bool trueORfalse) external onlyOwner {
        isContractsExcluded[address(account)] = trueORfalse;
    }
    function setExcludedFromTax(address account, bool trueORfalse) external onlyOwner {
        isTaxExcluded[address(account)] = trueORfalse;
    }
    function setExcludedFromMaxWallet(address account, bool trueORfalse) external onlyOwner {
        isMaxWalletExcluded[address(account)] = trueORfalse;
    }
    function setMaxWalletAmount(uint256 percent, uint256 divider) external onlyOwner {
        maxWallet = tokenSupply.mul(percent).div(divider);
        require(maxWallet <=tokenSupply.mul(100).div(100), "ERC20: Can not set max wallet more than 4%");
    }
    function setStatusLimits(bool trueORfalse) external onlyOwner {
        limitsOn = trueORfalse;
    }
    function setStatusMaxWallet(bool trueORfalse) external onlyOwner {
       maxWalletOn = trueORfalse;
    }
    function setStatusContractBlocker(bool trueORfalse) external onlyOwner {
        contractBlocker = trueORfalse;
    }
    function setSwapAndLiquifyStatus(bool trueORfalse) external onlyOwner {
        swapAndLiquifyStatus = trueORfalse;
    }
    function setTaxes(uint256 buyMarketingTax, uint256 buyLiquidityTax, uint256 sellMarketingTax, uint256 sellLiquidityTax) external onlyOwner {
        taxBuyMarketing = buyMarketingTax;
        taxBuyLiquidity = buyLiquidityTax;
        taxSellMarketing = sellMarketingTax;
        taxSellLiquidity = sellLiquidityTax;
    }
    function viewTaxes() public view returns(uint256 marketingBuy, uint256 liquidityBuy, uint256 marketingSell, uint256 liquiditySell) {
        return(taxBuyMarketing,taxBuyLiquidity,taxSellMarketing,taxSellLiquidity);
    }
}