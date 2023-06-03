// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

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

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
}

interface IGemAntiBot {
    function setTokenOwner(address owner) external;

    function onPreTransferCheck(
        address from,
        address to,
        uint256 amount
    ) external;
}

interface IUniswapV2Caller {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        address router,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) external;
}
interface IFee {
    function payFee(
        uint256 _tokenType
    ) external payable;
}
contract UltimateTokenWithAntibot is IERC20, Ownable {
    using SafeERC20 for IERC20;
    IUniswapV2Caller public constant uniswapV2Caller =
        IUniswapV2Caller(0x1CcFE8c40eF259566433716002E379dFfFbf5a3e);
    IFee public constant feeContract = IFee(0xfd6439AEfF9d2389856B7486b9e74a6DacaDcDCe);
    address public gemAntiBot;
    bool public antiBotEnabled;
    address public baseTokenForPair;
    uint8 private _decimals;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcluded;
    address[] private _excluded;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;
    string private _name;
    string private _symbol;

    uint256 private _rewardFee;
    uint256 private _previousRewardFee;

    uint256 private _liquidityFee;
    uint256 private _previousLiquidityFee;

    uint256 private _marketingFee;
    uint256 private _previousMarketingFee;

    uint256 private _treasuryFee;
    uint256 private _previousTreasuryFee;

    uint256 private _burnFee;
    uint256 private _previousBurnFee;

    bool private inSwapAndLiquify;
    uint16 public sellRewardFee;
    uint16 public buyRewardFee;
    uint16 public sellLiquidityFee;
    uint16 public buyLiquidityFee;

    uint16 public sellMarketingFee;
    uint16 public buyMarketingFee;

    uint16 public sellTreasuryFee;
    uint16 public buyTreasuryFee;

    uint16 public sellBurnFee;
    uint16 public buyBurnFee;

    address public marketingWallet;
    bool public isMarketingFeeBaseToken;
    address public treasuryWallet;



    uint256 public minAmountToTakeFee;
    uint256 public maxWallet;
    uint256 public maxTransactionAmount;


    IUniswapV2Router02 public mainRouter;
    address public mainPair;

    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public isExcludedFromMaxTransactionAmount;
    mapping(address => bool) public automatedMarketMakerPairs;

    uint256 private _liquidityFeeTokens;
    uint256 private _marketingFeeTokens;
    uint256 private _treasuryFeeTokens;

    event UpdateLiquidityFee(
        uint16 newSellLiquidityFee,
        uint16 newBuyLiquidityFee,
        uint16 oldSellLiquidityFee,
        uint16 oldBuyLiquidityFee
    );
    event UpdateMarketingFee(
        uint16 newSellMarketingFee,
        uint16 newBuyMarketingFee,
        uint16 oldSellMarketingFee,
        uint16 oldBuyMarketingFee
    );
    event UpdateTreasuryFee(
        uint16 newSellTreasuryFee,
        uint16 newBuyTreasuryFee,
        uint16 oldSellTreasuryFee,
        uint16 oldBuyTreasuryFee
    );
    event UpdateBurnFee(
        uint16 newSellBurnFee,
        uint16 newBuyBurnFee,
        uint16 oldSellBurnFee,
        uint16 oldBuyBurnFee
    );
    event UpdateRewardFee(
        uint16 newSellRewardFee,
        uint16 newBuyRewardFee,
        uint16 oldSellRewardFee,
        uint16 oldBuyRewardFee
    );  
    event UpdateMarketingWallet(
        address indexed newMarketingWallet,
        bool newIsMarketingFeeBaseToken,
        address indexed oldMarketingWallet,
        bool oldIsMarketingFeeBaseToken
    );
    event UpdateTreasuryWallet(
        address indexed newTreasuryWallet,
        address indexed oldTreasuryWallet
    );

    event UpdateMinAmountToTakeFee(uint256 newMinAmountToTakeFee, uint256 oldMinAmountToTakeFee);
    event SetAutomatedMarketMakerPair(address indexed pair, bool value);
    event ExcludedFromFee(address indexed account, bool isEx);
    event SwapAndLiquify(uint256 tokensForLiquidity, uint256 baseTokenForLiquidity);
    event MarketingFeeTaken(
        uint256 marketingFeeTokens,
        uint256 marketingFeeBaseTokenSwapped
    );
    event TreasuryFeeTaken(
        uint256 amount
    );
    event ExcludedFromMaxTransactionAmount(address indexed account, bool isExcluded);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldRouter);
    event UpdateMaxWallet(uint256 newMaxWallet, uint256 oldMaxWallet);
    event UpdateMaxTransactionAmount(uint256 newMaxTransactionAmount, uint256 oldMaxTransactionAmount);
    constructor(
        string memory __name,
        string memory __symbol,
        uint8 __decimals,
        uint256 _totalSupply,
        uint256 _maxWallet,
        uint256 _maxTransactionAmount,
        address[5] memory _accounts,
        bool _isMarketingFeeBaseToken,
        uint16[10] memory _fees
    ) payable {
        feeContract.payFee{value: msg.value}(4);   
        baseTokenForPair=_accounts[2];
        _decimals = __decimals;
        _name = __name;
        _symbol = __symbol;
        _tTotal = _totalSupply ;
        _rTotal = (MAX - (MAX % _tTotal));
        _rOwned[_msgSender()] = _rTotal;
        require(_accounts[0] != address(0), "marketing wallet can not be 0");
        require(_accounts[1] != address(0), "Router address can not be 0");
        require(_accounts[3] != address(0), "Treasury wallet can not be 0");
        require(_accounts[3] != _accounts[0], "Treasury wallet can not be same with marketing wallet");
        require(_fees[0]+(_fees[2])+(_fees[4]) + _fees[6] + _fees[8] <= 300, "sell total fee <= 30%");
        require(_fees[1]+(_fees[3])+(_fees[5]) + _fees[7] + _fees[9] <= 300, "buy total fee <= 30%");
        require(_fees[0] < 150, "each fee < 15%");
        require(_fees[1] < 150, "each fee < 15%");
        require(_fees[2] < 150, "each fee < 15%");
        require(_fees[3] < 150, "each fee < 15%");
        require(_fees[4] < 150, "each fee < 15%");
        require(_fees[5] < 150, "each fee < 15%");
        require(_fees[6] < 150, "each fee < 15%");
        require(_fees[7] < 150, "each fee < 15%");
        require(_fees[8] < 150, "each fee < 15%");
        require(_fees[9] < 150, "each fee < 15%");
        gemAntiBot = _accounts[4];
        IGemAntiBot(gemAntiBot).setTokenOwner(msg.sender);
        antiBotEnabled = true;
        marketingWallet = _accounts[0];
        treasuryWallet = _accounts[3];
        isMarketingFeeBaseToken = _isMarketingFeeBaseToken;
        emit UpdateMarketingWallet(
            marketingWallet,
            isMarketingFeeBaseToken,
            address(0),
            false
        );
        emit UpdateTreasuryWallet(
            treasuryWallet,
            address(0)
        );
        mainRouter = IUniswapV2Router02(_accounts[1]);
        if(baseTokenForPair != mainRouter.WETH()){            
            IERC20(baseTokenForPair).approve(address(mainRouter), MAX);            
        }
        _approve(address(this), address(uniswapV2Caller), MAX);
        _approve(address(this), address(mainRouter), MAX);
        emit UpdateUniswapV2Router(address(mainRouter), address(0));
        mainPair = IUniswapV2Factory(mainRouter.factory()).createPair(
            address(this),
            baseTokenForPair
        );
        
        sellLiquidityFee = _fees[0];
        buyLiquidityFee = _fees[1];
        emit UpdateLiquidityFee(
            sellLiquidityFee,
            buyLiquidityFee,
            0,
            0
        );
        sellMarketingFee = _fees[2];
        buyMarketingFee = _fees[3];
        emit UpdateMarketingFee(
            sellMarketingFee,
            buyMarketingFee,
            0,
            0
        );
        sellTreasuryFee = _fees[6];
        buyTreasuryFee = _fees[7];
        emit UpdateTreasuryFee(
            sellTreasuryFee,
            buyTreasuryFee,
            0,
            0
        );
        sellBurnFee = _fees[8];
        buyBurnFee = _fees[9];
        emit UpdateBurnFee(
            sellBurnFee,
            buyBurnFee,
            0,
            0
        );
        sellRewardFee = _fees[4];
        buyRewardFee = _fees[5];
        emit UpdateRewardFee(
            sellRewardFee,
            buyRewardFee,
            0,
            0
        );
        minAmountToTakeFee = _totalSupply/(10000);
        emit UpdateMinAmountToTakeFee(minAmountToTakeFee, 0);
        require(_maxTransactionAmount>=_totalSupply / 10000, "maxTransactionAmount >= total supply / 10000");
        require(_maxWallet>=_totalSupply / 10000, "maxWallet >= total supply / 10000");
        maxWallet=_maxWallet;
        emit UpdateMaxWallet(maxWallet, 0);
        maxTransactionAmount=_maxTransactionAmount;
        emit UpdateMaxTransactionAmount(maxTransactionAmount, 0);
        _isExcluded[address(0xdead)] = true;
        _excluded.push(address(0xdead));
        _isExcluded[address(this)] = true;
        _excluded.push(address(this));

        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[marketingWallet] = true;
        isExcludedFromFee[treasuryWallet] = true;
        isExcludedFromFee[_msgSender()] = true;
        isExcludedFromFee[address(0xdead)] = true;
        isExcludedFromMaxTransactionAmount[address(0xdead)]=true;
        isExcludedFromMaxTransactionAmount[address(this)]=true;
        isExcludedFromMaxTransactionAmount[marketingWallet]=true;
        isExcludedFromMaxTransactionAmount[treasuryWallet]=true;
        isExcludedFromMaxTransactionAmount[_msgSender()]=true;
        _setAutomatedMarketMakerPair(mainPair, true);
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }
    function setUsingAntiBot(bool enabled_) external onlyOwner {
        antiBotEnabled = enabled_;
    }
    function updateUniswapV2Pair(address _baseTokenForPair) external onlyOwner
    {
        require(
            _baseTokenForPair != baseTokenForPair,
            "The baseTokenForPair already has that address"
        );
        baseTokenForPair=_baseTokenForPair;
        mainPair = IUniswapV2Factory(mainRouter.factory()).createPair(
            address(this),
            baseTokenForPair
        );
        if(baseTokenForPair != mainRouter.WETH()){
            IERC20(baseTokenForPair).approve(address(mainRouter), MAX);            
        }
        _setAutomatedMarketMakerPair(mainPair, true);
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(
            newAddress != address(mainRouter),
            "The router already has that address"
        );
        emit UpdateUniswapV2Router(newAddress, address(mainRouter));
        mainRouter = IUniswapV2Router02(newAddress);
        address _mainPair = IUniswapV2Factory(mainRouter.factory())
            .createPair(address(this), baseTokenForPair);
        mainPair = _mainPair;
        _approve(address(this), address(mainRouter), MAX);
        if(baseTokenForPair != mainRouter.WETH()){
            IERC20(baseTokenForPair).approve(address(mainRouter), MAX);            
        }   
        _setAutomatedMarketMakerPair(mainPair, true);
    }
  
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        (           
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tMarketing,
            uint256 tTreasury,
            uint256 tBurn
        ) = _getTValues(amount);
        uint256 currentRate = _getRate();
        {
            //burn
            _tTotal = _tTotal - tBurn;
            _rTotal = _rTotal - tBurn*currentRate;
            emit Transfer(sender, address(0), tBurn);
        }
        {
            //marketing & liquidity & treasury burn fee collected in the token contract
            _liquidityFeeTokens = _liquidityFeeTokens+tLiquidity;
            _marketingFeeTokens = _marketingFeeTokens+tMarketing;
            _treasuryFeeTokens = _treasuryFeeTokens+tTreasury;
            uint256 tTotalFee = tLiquidity+tMarketing+tTreasury;
            _rOwned[address(this)] = _rOwned[address(this)]+tTotalFee * currentRate;
            if (_isExcluded[address(this)])
                _tOwned[address(this)] = _tOwned[address(this)]+tTotalFee;
        }
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _tOwned[sender] = _tOwned[sender]-amount;
            _rOwned[sender] = _rOwned[sender]-amount*currentRate;
            _rOwned[recipient] = _rOwned[recipient]+tTransferAmount*currentRate;
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _rOwned[sender] = _rOwned[sender]-amount*currentRate;
            _tOwned[recipient] = _tOwned[recipient]+tTransferAmount;
            _rOwned[recipient] = _rOwned[recipient]+tTransferAmount*currentRate;
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _tOwned[sender] = _tOwned[sender]-amount;
            _rOwned[sender] = _rOwned[sender]-amount*currentRate;
            _tOwned[recipient] = _tOwned[recipient]+tTransferAmount;
            _rOwned[recipient] = _rOwned[recipient]+tTransferAmount*currentRate;
        } else {
            _rOwned[sender] = _rOwned[sender]-amount*currentRate;
            _rOwned[recipient] = _rOwned[recipient]+tTransferAmount*currentRate;
        }
        _reflectFee(tFee*currentRate, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }


    function updateMaxWallet(uint256 _maxWallet) external onlyOwner {
        require(_maxWallet>=_tTotal / 10000, "maxWallet >= total supply / 10000");
        emit UpdateMaxWallet(_maxWallet, maxWallet);
        maxWallet = _maxWallet;
    }

    function updateMaxTransactionAmount(uint256 _maxTransactionAmount)
        external
        onlyOwner
    {
        require(_maxTransactionAmount>=_tTotal / 10000, "maxTransactionAmount >= total supply / 10000");  
        emit UpdateMaxTransactionAmount(_maxTransactionAmount, maxTransactionAmount);
        maxTransactionAmount = _maxTransactionAmount;
    }   
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal-(rFee);
        _tFeeTotal = _tFeeTotal+(tFee);
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = calculateRewardFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tMarketing = calculateMarketingFee(tAmount);
        uint256 tTreasury = calculateTreasuryFee(tAmount);
        uint256 tBurn = calculateBurnFee(tAmount);
        uint256 tTransferAmount = calculateTransferAmount(tAmount);
        return (tTransferAmount, tFee, tLiquidity, tMarketing, tTreasury, tBurn);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply/(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply-(_rOwned[_excluded[i]]);
            tSupply = tSupply-(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal/(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function removeAllFee() private {
        _previousRewardFee = _rewardFee;
        _previousLiquidityFee = _liquidityFee;
        _previousMarketingFee = _marketingFee;
        _previousTreasuryFee = _treasuryFee;
        _previousBurnFee = _burnFee;

        _burnFee = 0;
        _treasuryFee = 0;
        _marketingFee = 0;
        _rewardFee = 0;
        _liquidityFee = 0;
    }

    function restoreAllFee() private {
        _burnFee = _previousBurnFee;
        _treasuryFee = _previousTreasuryFee;
        _rewardFee = _previousRewardFee;
        _liquidityFee = _previousLiquidityFee;
        _marketingFee = _previousMarketingFee;
    }

    function calculateRewardFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount*(_rewardFee)/(10**3);
    }

    function calculateLiquidityFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount*(_liquidityFee)/(10**3);
    }

    function calculateMarketingFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount*(_marketingFee)/(10**3);
    }

    function calculateTreasuryFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount*(_treasuryFee)/(10**3);
    }

    function calculateBurnFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount*(_burnFee)/(10**3);
    }
    function calculateTransferAmount(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount*(1000 - _burnFee - _treasuryFee - _rewardFee - _liquidityFee - _marketingFee)/(10**3);
    }
    
    /////////////////////////////////////////////////////////////////////////////////
    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()]-amount
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender]+(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender]-(
                subtractedValue
            )
        );
        return true;
    }

    function isExcludedFromReward(address account)
        external
        view
        returns (bool)
    {
        return _isExcluded[account];
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        external
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        uint256 currentRate = _getRate();
        if (!deductTransferFee) {            
            uint256 rAmount = tAmount*currentRate;
            return rAmount;
        } else {
            (           
                uint256 tTransferAmount,
                ,
                ,
                ,
                ,               
            ) = _getTValues(tAmount);
            uint256 rTransferAmount = tTransferAmount * currentRate;
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount/(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        require(
            _excluded.length + 1 <= 50,
            "Cannot exclude more than 50 accounts.  Include a previously excluded address."
        );
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) public onlyOwner {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                uint256 prev_rOwned=_rOwned[account];
                _rOwned[account]=_tOwned[account]*_getRate();
                _rTotal=_rTotal-prev_rOwned+_rOwned[account];
                _isExcluded[account] = false;
                _excluded[i] = _excluded[_excluded.length - 1];
                _excluded.pop();
                break;
            }
        }
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    function updateLiquidityFee(
        uint16 _sellLiquidityFee,
        uint16 _buyLiquidityFee
    ) external onlyOwner {
        require(
            _sellLiquidityFee+(sellMarketingFee)+(sellRewardFee) + sellTreasuryFee + sellBurnFee <= 300,
            "sell total fee <= 30%"
        );
        require(
            _buyLiquidityFee+(buyMarketingFee)+(buyRewardFee) + buyTreasuryFee + buyBurnFee <= 300,
            "buy total fee <= 30%"
        );
        require(_sellLiquidityFee<= 150, "sell fee <= 15%");
        require(_buyLiquidityFee<= 150, "buy fee <= 15%");
        emit UpdateLiquidityFee(
            _sellLiquidityFee,
            _buyLiquidityFee,
            sellLiquidityFee,
            buyLiquidityFee
        );
        sellLiquidityFee = _sellLiquidityFee;
        buyLiquidityFee = _buyLiquidityFee;        
    }

    function updateMarketingFee(
        uint16 _sellMarketingFee,
        uint16 _buyMarketingFee
    ) external onlyOwner {
        require(
            _sellMarketingFee+(sellLiquidityFee)+(sellRewardFee) + sellTreasuryFee + sellBurnFee <= 300,
            "sell total fee <= 30%"
        );
        require(
            _buyMarketingFee+(buyLiquidityFee)+(buyRewardFee) + buyTreasuryFee + buyBurnFee <= 300,
            "buy total fee <= 30%"
        );
        require(_sellMarketingFee<= 150, "sell fee <= 15%");
        require(_buyMarketingFee<= 150, "buy fee <= 15%");
        emit UpdateMarketingFee(
            _sellMarketingFee,
            _buyMarketingFee,
            sellMarketingFee,
            buyMarketingFee
        );
        sellMarketingFee = _sellMarketingFee;
        buyMarketingFee = _buyMarketingFee;        
    }

    function updateRewardFee(
        uint16 _sellRewardFee,
        uint16 _buyRewardFee
    ) external onlyOwner {
        require(
            _sellRewardFee+(sellLiquidityFee)+(sellMarketingFee) + sellTreasuryFee + sellBurnFee <= 300,
            "sell total fee <= 30%"
        );
        require(
            _buyRewardFee+(buyLiquidityFee)+(buyMarketingFee) + buyTreasuryFee + buyBurnFee <= 300,
            "buy total fee <= 30%"
        );
        require(_sellRewardFee<= 150, "sell fee <= 15%");
        require(_buyRewardFee<= 150, "buy fee <= 15%");
        emit UpdateRewardFee(
            _sellRewardFee, 
            _buyRewardFee,
            sellRewardFee, 
            buyRewardFee
        );
        sellRewardFee = _sellRewardFee;
        buyRewardFee = _buyRewardFee;        
    }

    function updateTreasuryFee(
        uint16 _sellTreasuryFee,
        uint16 _buyTreasuryFee
    ) external onlyOwner {
        require(
            _sellTreasuryFee+(sellLiquidityFee)+(sellMarketingFee) + sellRewardFee + sellBurnFee <= 300,
            "sell total fee <= 30%"
        );
        require(
            _buyTreasuryFee+(buyLiquidityFee)+(buyMarketingFee) + buyRewardFee + buyBurnFee <= 300,
            "buy total fee <= 30%"
        );
        require(_sellTreasuryFee<= 150, "sell fee <= 15%");
        require(_buyTreasuryFee<= 150, "buy fee <= 15%");
        emit UpdateTreasuryFee(
            _sellTreasuryFee, 
            _buyTreasuryFee,
            sellTreasuryFee, 
            buyTreasuryFee
        );
        sellTreasuryFee = _sellTreasuryFee;
        buyTreasuryFee = _buyTreasuryFee;        
    }

    function updateBurnFee(
        uint16 _sellBurnFee,
        uint16 _buyBurnFee
    ) external onlyOwner {
        require(
            _sellBurnFee+(sellLiquidityFee)+(sellMarketingFee) + sellTreasuryFee + sellRewardFee <= 300,
            "sell total fee <= 30%"
        );
        require(
            _buyBurnFee+(buyLiquidityFee)+(buyMarketingFee) + buyTreasuryFee + buyRewardFee <= 300,
            "buy total fee <= 30%"
        );
        require(_sellBurnFee<= 150, "sell fee <= 15%");
        require(_buyBurnFee<= 150, "buy fee <= 15%");
        emit UpdateBurnFee(
            _sellBurnFee, 
            _buyBurnFee,
            sellBurnFee, 
            buyBurnFee
        );
        sellBurnFee = _sellBurnFee;
        buyBurnFee = _buyBurnFee;        
    }

    function updateMarketingWallet(
        address _marketingWallet,
        bool _isMarketingFeeBaseToken
    ) external onlyOwner {
        require(_marketingWallet != address(0), "marketing wallet can't be 0");
        require(_marketingWallet != treasuryWallet, "marketing wallet can't be same with Treasury wallet");
        emit UpdateMarketingWallet(_marketingWallet, _isMarketingFeeBaseToken,
            marketingWallet, isMarketingFeeBaseToken);
        marketingWallet = _marketingWallet;
        isMarketingFeeBaseToken = _isMarketingFeeBaseToken;
        isExcludedFromFee[_marketingWallet] = true;    
        isExcludedFromMaxTransactionAmount[_marketingWallet]=true;    
    }

    function updateTreasuryWallet(
        address _treasuryWallet
    ) external onlyOwner {
        require(_treasuryWallet != address(0), "Treasury wallet can't be 0");
        require(marketingWallet != _treasuryWallet, "marketing wallet can't be same with Treasury wallet");
        emit UpdateTreasuryWallet(_treasuryWallet,
            treasuryWallet);
        treasuryWallet = _treasuryWallet;
        isExcludedFromFee[_treasuryWallet] = true;    
        isExcludedFromMaxTransactionAmount[_treasuryWallet]=true;           
    }

    function updateMinAmountToTakeFee(uint256 _minAmountToTakeFee)
        external
        onlyOwner
    {
        require(_minAmountToTakeFee > 0, "minAmountToTakeFee > 0");
        emit UpdateMinAmountToTakeFee(_minAmountToTakeFee, minAmountToTakeFee);
        minAmountToTakeFee = _minAmountToTakeFee;        
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;
        if (value) excludeFromReward(pair);
        else includeInReward(pair);
        isExcludedFromMaxTransactionAmount[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }


    function excludeFromFee(address account, bool isEx) external onlyOwner {
        require(isExcludedFromFee[account] != isEx, "already");
        isExcludedFromFee[account] = isEx;
        emit ExcludedFromFee(account, isEx);
    }

    function excludeFromMaxTransactionAmount(address account, bool isEx)
        external
        onlyOwner
    {
        require(isExcludedFromMaxTransactionAmount[account]!=isEx, "already");
        isExcludedFromMaxTransactionAmount[account] = isEx;
        emit ExcludedFromMaxTransactionAmount(account, isEx);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");       
        if (!inSwapAndLiquify && antiBotEnabled && !isExcludedFromFee[from] && !isExcludedFromFee[to]) {
            IGemAntiBot(gemAntiBot).onPreTransferCheck(from, to, amount);
        }  
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >=
            minAmountToTakeFee;

        // Take Fee
        if (
            !inSwapAndLiquify &&
            overMinimumTokenBalance &&
            balanceOf(mainPair) > 0 &&
            automatedMarketMakerPairs[to]
        ) {
            takeFee();
        }
        removeAllFee();

        // If any account belongs to isExcludedFromFee account then remove the fee
        if (
            !inSwapAndLiquify &&
            !isExcludedFromFee[from] &&
            !isExcludedFromFee[to]
        ) {
            // Buy
            if (automatedMarketMakerPairs[from]) {
                _rewardFee = buyRewardFee;
                _liquidityFee = buyLiquidityFee;
                _marketingFee = buyMarketingFee;
                _treasuryFee = buyTreasuryFee;
                _burnFee = buyBurnFee;
            }
            // Sell
            else if (automatedMarketMakerPairs[to]) {
                _rewardFee = sellRewardFee;
                _liquidityFee = sellLiquidityFee;
                _marketingFee = sellMarketingFee;
                _treasuryFee = sellTreasuryFee;
                _burnFee = sellBurnFee;
            }
        }
        _tokenTransfer(from, to, amount);
        restoreAllFee();
        if (!inSwapAndLiquify) {
            if (!isExcludedFromMaxTransactionAmount[from]) {
                require(
                    amount < maxTransactionAmount,
                    "ERC20: exceeds transfer limit"
                );
            }
            if (!isExcludedFromMaxTransactionAmount[to]) {
                require(
                    balanceOf(to) < maxWallet,
                    "ERC20: exceeds max wallet limit"
                );
            }
        }
    }

    function takeFee() private lockTheSwap {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensTaken = _liquidityFeeTokens + _marketingFeeTokens + _treasuryFeeTokens;
        if (totalTokensTaken == 0 || contractBalance < totalTokensTaken) {
            return;
        }

        // Halve the amount of liquidity tokens
        uint256 tokensForLiquidity = _liquidityFeeTokens / 2;
        uint256 initialBaseTokenBalance = baseTokenForPair==mainRouter.WETH() ? address(this).balance
            : IERC20(baseTokenForPair).balanceOf(address(this));
        uint256 baseTokenForLiquidity;
        uint256 baseTokenForTreasury;
        if (isMarketingFeeBaseToken) {
            uint256 tokensForSwap=tokensForLiquidity+_marketingFeeTokens + _treasuryFeeTokens;
            if(tokensForSwap>0)
                swapTokensForBaseToken(tokensForSwap);
            uint256 baseTokenBalance = baseTokenForPair==mainRouter.WETH() ? address(this).balance-initialBaseTokenBalance
                : IERC20(baseTokenForPair).balanceOf(address(this))-initialBaseTokenBalance;
            uint256 baseTokenForMarketing = baseTokenBalance*_marketingFeeTokens/tokensForSwap;
            baseTokenForLiquidity = baseTokenBalance*tokensForLiquidity/tokensForSwap;
            baseTokenForTreasury = baseTokenBalance - baseTokenForMarketing - baseTokenForLiquidity;
            if(baseTokenForMarketing>0){
                if(baseTokenForPair==mainRouter.WETH()){
                    (bool success, )=address(marketingWallet).call{value: baseTokenForMarketing}("");
                    if(success){
                        emit MarketingFeeTaken(0, baseTokenForMarketing);
                    }
                }else{
                    IERC20(baseTokenForPair).safeTransfer(marketingWallet, baseTokenForMarketing);
                    emit MarketingFeeTaken(0, baseTokenForMarketing);
                }       
            }            
        } else {
            uint256 tokensForSwap=tokensForLiquidity + _treasuryFeeTokens;
            if(tokensForSwap>0)
                swapTokensForBaseToken(tokensForSwap);
            uint256 baseTokenBalance = baseTokenForPair==mainRouter.WETH() ? address(this).balance-initialBaseTokenBalance
                : IERC20(baseTokenForPair).balanceOf(address(this))-initialBaseTokenBalance;
            baseTokenForLiquidity = baseTokenBalance*tokensForLiquidity/tokensForSwap;
            baseTokenForTreasury = baseTokenBalance - baseTokenForLiquidity;
            
            if(_marketingFeeTokens>0){
                _transfer(address(this), marketingWallet, _marketingFeeTokens);
                emit MarketingFeeTaken(_marketingFeeTokens, 0);
            }            
        }

        if (tokensForLiquidity > 0 && baseTokenForLiquidity > 0) {
            addLiquidity(tokensForLiquidity, baseTokenForLiquidity);
            emit SwapAndLiquify(tokensForLiquidity, baseTokenForLiquidity);
        }
        if(baseTokenForTreasury>0){
            if(baseTokenForPair==mainRouter.WETH()){
                (bool success, )=address(treasuryWallet).call{value: baseTokenForTreasury}("");
                if(success){
                    emit TreasuryFeeTaken(baseTokenForTreasury);
                }
            }else{
                IERC20(baseTokenForPair).safeTransfer(treasuryWallet, baseTokenForTreasury);
                emit TreasuryFeeTaken(baseTokenForTreasury);
            }       
        }
        _marketingFeeTokens = 0;
        _treasuryFeeTokens = 0;
        _liquidityFeeTokens = 0;
        _transfer(address(this), owner(), balanceOf(address(this)));  
    }
    
    function swapTokensForBaseToken(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = baseTokenForPair;
        if (path[1] == mainRouter.WETH()){
            mainRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0, // accept any amount of BaseToken
                path,
                address(this),
                block.timestamp
            );
        }else{
            uniswapV2Caller.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    address(mainRouter),
                    tokenAmount,
                    0, // accept any amount of BaseToken
                    path,
                    block.timestamp
                );
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 baseTokenAmount) private {  
        if (baseTokenForPair == mainRouter.WETH()) 
            mainRouter.addLiquidityETH{value: baseTokenAmount}(
                address(this),
                tokenAmount,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                address(0xdead),
                block.timestamp
            );
        else
            mainRouter.addLiquidity(
                address(this),
                baseTokenForPair,
                tokenAmount,
                baseTokenAmount,
                0,
                0,
                address(0xdead),
                block.timestamp
            );
    }
    function treasuryBurn() payable external{
        address[] memory path = new address[](2);
        path[0] = baseTokenForPair;
        path[1] = address(this);
        
        if (path[0] == mainRouter.WETH()){
            mainRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value:msg.value}(
                0, // accept any amount of BaseToken
                path,
                address(0xdead),
                block.timestamp
            );
        }else{
            uint256 amount = IERC20(baseTokenForPair).balanceOf(_msgSender());
            IERC20(baseTokenForPair).safeTransferFrom(_msgSender(), address(this), amount);
            mainRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amount,
                0, // accept any amount of BaseToken
                path,
                address(0xdead),
                block.timestamp
            );
        }      
        {
            //burn
            _tTotal = _tTotal - _tOwned[address(0xdead)];
            _rTotal = _rTotal - _rOwned[address(0xdead)];
            emit Transfer(address(0xdead), address(0), _tOwned[address(0xdead)]);
            _rOwned[address(0xdead)] = 0;
            _tOwned[address(0xdead)] = 0;            
        }
    }
    function withdrawETH() external onlyOwner {
        (bool success, )=address(owner()).call{value: address(this).balance}("");
        require(success, "Failed in withdrawal");
    }
    function withdrawToken(address token) external onlyOwner{
        require(address(this) != token, "Not allowed");
        IERC20(token).safeTransfer(owner(), IERC20(token).balanceOf(address(this)));
    }
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}