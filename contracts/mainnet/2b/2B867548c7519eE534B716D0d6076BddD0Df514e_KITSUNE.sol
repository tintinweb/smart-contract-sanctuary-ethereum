/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

/*
"We dare not forget today that we are the heirs of that first revolution.
Let the word go forth from this time and place, to friend and foe alike,
that the torch has been passed to a new generation.”

https://twitter.com/KitsuneERC20

snipers will be reduced to nothing
*/



// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract KITSUNE is Context, IERC20, Ownable {
    using Address for address;

    string private _name = "Kitsune";
    string private _symbol = "SUNE";
    uint8 private _decimals = 9;
    uint256 private initialsupply = 1_000_000_000;
    uint256 private _tTotal = initialsupply * 10**_decimals;

    address payable public marketingWallet;
    address public liquidityWallet;

    mapping(address => uint256) private _tOwned;
    mapping(address => uint256) private buycooldown;
    mapping(address => uint256) private sellcooldown;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public isBlacklisted;

    struct Icooldown {
        bool buycooldownEnabled;
        bool sellcooldownEnabled;
        uint256 cooldown;
        uint256 cooldownLimit;
    }
    Icooldown public cooldownInfo =
        Icooldown({
            buycooldownEnabled: true,
            sellcooldownEnabled: true,
            cooldown: 30 seconds,
            cooldownLimit: 60 seconds
        });
    struct ILaunch {
        uint256 launchedAt;
        bool launched;
        bool launchProtection;
    }
    ILaunch public wenLaunch =
        ILaunch({
            launchedAt: 0, 
            launched: false, 
            launchProtection: true
        });

    struct ItxSettings {
        uint256 maxTxAmount;
        uint256 maxWalletAmount;
        uint256 numTokensToSwap;
        bool limited;
    }

    ItxSettings public txSettings;

    uint256 public _transferLiquidityFee;
    uint256 public _transferMarketingFee;
    uint256 public _transferBurnFee;

    uint256 public _buyLiquidityFee;
    uint256 public _buyMarketingFee;
    uint256 public _buyBurnFee;

    uint256 public _sellLiquidityFee;
    uint256 public _sellMarketingFee;
    uint256 public _sellBurnFee;

    uint256 public lpFeeAccumulated;

    uint256 public antiBlocks = 3;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled;

    bool public tradeEnabled;
    mapping(address => bool) public tradeAllowedList;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    event SniperStatus(address account, bool blacklisted);
    event ToMarketing(uint256 marketingBalance);
    event SwapAndLiquify(uint256 liquidityTokens, uint256 liquidityFees);
    event Launch();

    constructor(address _marketingWallet) {        
        marketingWallet = payable(_marketingWallet);
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // bsc pancake router 
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); //bsc test net router kiem
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //eth unisawp router

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        _approve(_msgSender(), address(_uniswapV2Router), type(uint256).max);
        _approve(address(this), address(_uniswapV2Router), type(uint256).max);

        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;

        setSellFee(10,50, 0);
        setBuyFee(10,50, 0);
        setTransferFee(10,30, 0);

        setTxSettings(1,100,2,100,1,1000,true);

        _tOwned[_msgSender()] = _tTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);

        tradeEnabled = false;
        tradeAllowedList[owner()] = true;
        tradeAllowedList[address(this)] = true;

        liquidityWallet = _msgSender();
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
        return _tTotal;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function setSellFee(uint256 liquidityFee, uint256 marketingFee, uint256 burnFee) public onlyOwner {
        require(liquidityFee + marketingFee + burnFee <= 250);
        _sellLiquidityFee = liquidityFee;
        _sellMarketingFee = marketingFee;
        _sellBurnFee = burnFee;
    }

    function setBuyFee(uint256 liquidityFee, uint256 marketingFee, uint256 burnFee) public onlyOwner {
        require(liquidityFee + marketingFee + burnFee <= 250);
        _buyMarketingFee = marketingFee;
        _buyLiquidityFee = liquidityFee;
        _buyBurnFee = burnFee;
    }

    function setTransferFee(uint256 liquidityFee, uint256 marketingFee, uint256 burnFee) public onlyOwner {
        require(liquidityFee + marketingFee + burnFee <= 250);
        _transferLiquidityFee = liquidityFee;
        _transferMarketingFee = marketingFee;
        _transferBurnFee = burnFee;
    }

    function setLiquidityFees(uint256 newTransfer, uint256 newBuy, uint256 newSell) public onlyOwner {
        _transferLiquidityFee = newTransfer;
        _buyLiquidityFee = newBuy;
        _sellLiquidityFee = newSell;
    }

    function setMarketingFees(uint256 newTransfer, uint256 newBuy, uint256 newSell) public onlyOwner {
        _transferMarketingFee = newTransfer;
        _buyMarketingFee = newBuy;
        _sellMarketingFee = newSell;
    }

    function setBurnFees(uint256 newTransfer, uint256 newBuy, uint256 newSell) public onlyOwner {
        _transferBurnFee = newTransfer;
        _buyBurnFee = newBuy;
        _sellBurnFee = newSell;
    }

    function setCooldown(uint256 amount) external onlyOwner {
        require(amount <= cooldownInfo.cooldownLimit);
        cooldownInfo.cooldown = amount;
    }

    function setMarketingWallet(address payable newMarketingWallet) external onlyOwner {
        marketingWallet = payable(newMarketingWallet);
    }

    function setLiquidityWallet(address newLpWallet) external onlyOwner {
        liquidityWallet = newLpWallet;
    }

    function setTxSettings(uint256 txp, uint256 txd, uint256 mwp, uint256 mwd, uint256 sp, uint256 sd, bool limiter) public onlyOwner {
        require((_tTotal * txp) / txd >= (_tTotal / 1000), "Max Transaction must be above 0.1% of total supply.");
        require((_tTotal * mwp) / mwd >= (_tTotal / 1000), "Max Wallet must be above 0.1% of total supply.");
        uint256 newTx = (_tTotal * txp) / (txd);
        uint256 newMw = (_tTotal * mwp) / mwd;
        uint256 swapAmount = (_tTotal * sp) / (sd);
        txSettings = ItxSettings ({
            numTokensToSwap: swapAmount,
            maxTxAmount: newTx,
            maxWalletAmount: newMw,
            limited: limiter
        });
    }

    function setTradeEnabled(bool onoff) external onlyOwner {
        if (!wenLaunch.launched) {
            wenLaunch.launchedAt = block.number;
            wenLaunch.launched = true;
            swapAndLiquifyEnabled = true;
        }

        tradeEnabled = onoff;

        if (!wenLaunch.launched) {
            emit Launch();
        }
    }

    function setAntiBlocks(uint256 _block) external onlyOwner {
        antiBlocks = _block;
    }

    function setTradeAllowedAddress(address who, bool status) external onlyOwner {
        tradeAllowedList[who] = status;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool){
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + (addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] - (subtractedValue)
        );
        return true;
    }

    function setBlacklistStatus(address account, bool blacklisted) external onlyOwner {
        if(account == uniswapV2Pair || account == address(this) || account == address(uniswapV2Router)) {revert();}
        
        isBlacklisted[account] = blacklisted;
    }

    function Ox5n1p3r(address [] calldata accounts, bool blacklisted) external onlyOwner {
        for (uint256 i; i < accounts.length; i++) {
            address account = accounts[i];
            if(account != uniswapV2Pair && account != address(this) && account != address(uniswapV2Router)) {
                isBlacklisted[account] = blacklisted;
            }
        }
    }
    
    function setSniperStatus(address account, bool blacklisted) private{
        if(account == uniswapV2Pair || account == address(this) || account == address(uniswapV2Router)) {revert();}
        
        if (blacklisted == true) {
            isBlacklisted[account] = true;
            emit SniperStatus(account, blacklisted);
        } 
    }

    function limits(bool onoff) public onlyOwner {
        txSettings.limited = onoff;
    }

    function excludeFromFee(address account) public onlyOwner {
        isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        isExcludedFromFee[account] = false;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
    }

    //to receive ETH from uniswapV2Router when swapping
    receive() external payable {}

    function _approve(address owner,address spender,uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function swapAndLiquify(uint256 tokenBalance) private lockTheSwap {
        uint256 initialBalance = address(this).balance;
        uint256 tokensToSwap = tokenBalance / 2;
        uint256 liquidityTokens = tokenBalance - tokensToSwap;

        if (tokensToSwap > 0) {
            swapTokensForEth(tokensToSwap);
        }

        uint256 newBalance = address(this).balance;
        uint256 liquidityBalance = uint256(newBalance - initialBalance);

        if (liquidityTokens > 0 && liquidityBalance > 0) {
            addLiquidity(liquidityTokens, liquidityBalance);
            emit SwapAndLiquify(liquidityTokens, liquidityBalance);
        }

        lpFeeAccumulated -= tokenBalance;
    }

    function swapAndMarketing(uint256 tokenBalance) private lockTheSwap {
        if (tokenBalance > 0) {
            swapTokensForEth(tokenBalance);
        }

        uint256 marketingBalance = address(this).balance;
        if (marketingBalance > 0) {
            marketingWallet.transfer(marketingBalance);
            emit ToMarketing(marketingBalance);
        }
    }

    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
        require(amountPercentage <= 100);
        uint256 amountETH = address(this).balance;
        payable(marketingWallet).transfer(
            (amountETH * (amountPercentage)) / (100)
        );
    }

    function clearStuckToken(address to) external onlyOwner {
        uint256 _balance = balanceOf(address(this));
        lpFeeAccumulated = 0;
        _transfer(address(this), to, _balance);        
    }

    function clearStuckTokens(address _token, address _to) external onlyOwner returns (bool _sent) {
        require(_token != address(0));
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        if(_allowances[address(this)][address(uniswapV2Router)] < tokenAmount) {
            _approve(address(this), address(uniswapV2Router), type(uint256).max);
        }

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        if(_allowances[address(this)][address(uniswapV2Router)] < tokenAmount) {
            _approve(address(this), address(uniswapV2Router), type(uint256).max);
        }

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );
    }

    function transferFrom(address sender,address recipient,uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - (
                amount
            )
        );
        return true;
    }    

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(isBlacklisted[from] == false, "Hehe");
        require(isBlacklisted[to] == false, "Hehe");

        if (!tradeEnabled) {
            require(tradeAllowedList[from] || tradeAllowedList[to], "Transfer: not allowed");
            require(balanceOf(uniswapV2Pair) == 0 || to != uniswapV2Pair, "Transfer: no body can sell now");
        }

        if (txSettings.limited) {
            if(from != owner() && to != owner() || to != address(0xdead) && to != address(0)) 
            {
                if (from == uniswapV2Pair || to == uniswapV2Pair
                ) {
                    if(!isExcludedFromFee[to] && !isExcludedFromFee[from]) {
                        require(amount <= txSettings.maxTxAmount);
                    }
                }
                if(to != address(uniswapV2Router) && to != uniswapV2Pair) {
                    if(!isExcludedFromFee[to]) {
                        require(balanceOf(to) + amount <= txSettings.maxWalletAmount);
                    }
                }
            }
        }

        if (from == uniswapV2Pair && to != address(uniswapV2Router) && !isExcludedFromFee[to]
            ) {
                if (cooldownInfo.buycooldownEnabled) {
                    require(buycooldown[to] < block.timestamp);
                    buycooldown[to] = block.timestamp + (cooldownInfo.cooldown);
                }
            } else if (from != uniswapV2Pair && !isExcludedFromFee[from]){
                if (cooldownInfo.sellcooldownEnabled) {
                    require(sellcooldown[from] <= block.timestamp);
                    sellcooldown[from] = block.timestamp + (cooldownInfo.cooldown);
                }
            }

        if (
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            uint256 contractTokenBalance = balanceOf(address(this));

            if (contractTokenBalance > txSettings.numTokensToSwap) {
                if (lpFeeAccumulated > txSettings.numTokensToSwap) {
                    swapAndLiquify(txSettings.numTokensToSwap);
                } else if ((_transferMarketingFee + _buyMarketingFee + _sellMarketingFee) > 0) {
                    swapAndMarketing(txSettings.numTokensToSwap);
                }
            }
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to isExcludedFromFee account then remove the fee
        if (isExcludedFromFee[from] || isExcludedFromFee[to]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, marketing, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender,address recipient,uint256 amount,bool takeFee) private {
        uint256 liquidityFee;
        uint256 marketingFee;
        uint256 burnFee;

        uint256 liquidityFeeAmount = 0;
        uint256 marketingFeeAmount = 0;
        uint256 burnFeeAmount = 0;
        uint256 feeAmount = 0;

        bool highFee = false;

        if (wenLaunch.launchProtection) {
            if (wenLaunch.launched && wenLaunch.launchedAt > 0 && block.number > (wenLaunch.launchedAt + antiBlocks)) {
                wenLaunch.launchProtection = false;
            } else {
                if (
                    sender == uniswapV2Pair &&
                    recipient != address(uniswapV2Router) &&
                    !isExcludedFromFee[recipient]
                ) {
                    setSniperStatus(recipient, true); 
                    highFee = true;
                }
            }
        }

        if (takeFee) {
            if (sender == uniswapV2Pair) {
                liquidityFee = _buyLiquidityFee;
                marketingFee = _buyMarketingFee;
                burnFee = _buyBurnFee;                
            } else if (recipient == uniswapV2Pair) {
                liquidityFee = _sellLiquidityFee;
                marketingFee = _sellMarketingFee;
                burnFee = _sellBurnFee;
            } else {
                liquidityFee = _transferLiquidityFee;
                marketingFee = _transferMarketingFee;
                burnFee = _transferBurnFee;
            }

            if (highFee) {
                liquidityFee = 950;
                marketingFee = 0;
                burnFee = 0;
            }

            feeAmount = (amount * (liquidityFee + marketingFee + burnFee)) / (1000);

            if ((liquidityFee + marketingFee + burnFee) > 0) {                
                liquidityFeeAmount = feeAmount * liquidityFee / (liquidityFee + marketingFee + burnFee);
                marketingFeeAmount = feeAmount * marketingFee / (liquidityFee + marketingFee + burnFee);
                burnFeeAmount = feeAmount * burnFee / (liquidityFee + marketingFee + burnFee);
            }

            lpFeeAccumulated += liquidityFeeAmount;
        }
        
        uint256 tAmount = amount - (liquidityFeeAmount + marketingFeeAmount + burnFeeAmount);
        _tOwned[sender] -= amount;
        _tOwned[address(this)] += (liquidityFeeAmount + marketingFeeAmount);
        emit Transfer(sender, address(this), (liquidityFeeAmount + marketingFeeAmount));
        _tOwned[recipient] += tAmount;
        emit Transfer(sender, recipient, tAmount);
        if (burnFeeAmount > 0) {
            _tOwned[address(0xdead)] += burnFeeAmount;
            emit Transfer(sender, address(0xdead), burnFeeAmount);
        }        
    }

    function setCooldownEnabled(bool onoff, bool offon) external onlyOwner {
        cooldownInfo.buycooldownEnabled = onoff;
        cooldownInfo.sellcooldownEnabled = offon;
    }
}