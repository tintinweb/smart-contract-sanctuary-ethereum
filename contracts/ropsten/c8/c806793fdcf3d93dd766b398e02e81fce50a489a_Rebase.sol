/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _status = _ENTERED;

        _;
        _status = _NOT_ENTERED;
    }
}


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IStaking {
    function stake(uint256 _poolId,uint256 _amount,uint256 _amountGon,address _user) external returns (bool);
    function withdraw(uint256 _poolId, address _user) external returns (uint256);
    function moveToHigherPool(uint256 _currentPoolId,uint256 _newPoolId,address _user) external;
    function withdrawEarly( address _user) external returns (uint256, uint256);
    function addToRewardPool(uint256 reward) external;
}

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
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function sync() external;
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to,uint256 value) external returns (bool);
    function getReserves() external view returns (uint112 reserve0,uint112 reserve1,uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function kLast() external view returns (uint256);
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0,address indexed token1,address pair,uint256);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

contract Rebase is IERC20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    bool public tokenLaunched = false;
    bool public swapEnabled = true;
    bool public autoRebase = true;
    bool public stakingEnabled = false;
    bool inSwap;

    string constant _name = 'RebaseToken';
    string constant _symbol = 'RebaseToken';
    uint8 constant _decimals = 18;

    uint256 private constant MAX_UINT256 = type(uint256).max;
    uint256 private constant DECIMALS = 18;
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 550000 ether; // 550,000
    uint256 private constant MAX_SUPPLY = 5500000000 ether; // 5,550,000,000
    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    uint256 private gonSwapThreshold = (TOTAL_GONS * 10) / 10000;

    uint256 private constant MAX_REBASE_FREQUENCY = 1800;
    uint256 public rebaseFrequencySeconds = 900;
    uint256 public nextRebase = block.timestamp + rebaseFrequencySeconds;
    uint256 public rewardYield = 239;
    uint256 public rewardYieldDenominator = 1000000;

    uint256 public maxSellTransactionAmount = 10000 * 10**18;
    uint256 public targetLiquidity = 50;
    uint256 public targetLiquidityDenominator = 100;

    uint256 public constant MAX_FEE_RATE = 25;
    uint256 public liquidityFee = 3;
    uint256 public burnFee = 2;
    uint256 public buyFeeTreasury = 3;
    uint256 public buyFeeInsuranceFund = 3;
    uint256 public buyFeeStaking = 2;
    uint256 public totalBuyFee = 13;

    uint256 public sellFeeTreasury = 7;
    uint256 public sellFeeInsuranceFund = 4;
    uint256 public sellFeeStaking = 4;
    uint256 public totalSellFee = 20;
    uint256 public feeDenominator = 100;

    uint256 public launchTime;
    uint256 public day = 86400;
    uint256 public stabilityPeriod;


    mapping(address => bool) internal blacklist;
    mapping(address => bool) internal isFeeExempt;
    mapping(address => bool) public isCorePair;

    mapping(address => uint256) private _gonBalances;
    mapping(address => uint256) private _lockedBalances;
    mapping(address => mapping(address => uint256)) private _allowedFragments;

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;
    address public treasuryFeeReceiver;
    address public liquidityTokensReceiver;
    address public insuranceFeeReceiver;
    address public stakingFeeReceiver;

    address[] public corePairs;

    IUniswapV2Pair public immutable stableLiquidityPair;
    address public immutable stableCoinAddress;
    IUniswapV2Router02 public router;
    IStaking public staking;


    constructor(address _routerAddress, address _stableCoinAddress, address _treasuryFeeReceiver, address _insuranceFeeReceiver, address _liquityTokensReceiver, address _stakingContractAddress) {
        require(_routerAddress != address(0));
        require(_stableCoinAddress != address(0));
        if (_stakingContractAddress != address(0)) {
            staking = IStaking(_stakingContractAddress);
            stakingEnabled = true;
            isFeeExempt[_stakingContractAddress] = true;
        }

        router = IUniswapV2Router02(_routerAddress);
        address _stableLiquidityPairAddress = IUniswapV2Factory(router.factory()).createPair(address(this), _stableCoinAddress);

        stableCoinAddress = _stableCoinAddress;
        stableLiquidityPair = IUniswapV2Pair(_stableLiquidityPairAddress);

        setAutomatedMarketMakerPair(_stableLiquidityPairAddress, true);

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[msg.sender] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        treasuryFeeReceiver = _treasuryFeeReceiver;
        insuranceFeeReceiver = _insuranceFeeReceiver;
        stakingFeeReceiver = _stakingContractAddress;
        liquidityTokensReceiver = _liquityTokensReceiver;

        isFeeExempt[treasuryFeeReceiver] = true;
        isFeeExempt[insuranceFeeReceiver] = true;
        isFeeExempt[stakingFeeReceiver] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[msg.sender] = true;

        IERC20(_stableCoinAddress).approve(address(router), type(uint256).max);
        IERC20(_stableCoinAddress).approve(address(_stableLiquidityPairAddress),type(uint256).max);
        IERC20(_stableCoinAddress).approve(address(this), type(uint256).max);

        _allowedFragments[address(this)][address(router)] = type(uint256).max;
        _allowedFragments[address(this)][address(this)] = type(uint256).max;
        _allowedFragments[address(this)][_stableLiquidityPairAddress] = type(uint256).max;

        emit Transfer(address(0x0), _treasuryFeeReceiver, _totalSupply);
    }

    function decimals() public pure override returns (uint8) { return _decimals; }
    function symbol() public pure override returns (string memory) { return _symbol; }
    function name() public pure override returns (string memory) { return _name; }

    modifier notBlacklisted(address _account) {
        require(blacklist[_account] == false);
        _;
    }

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier validRecipient(address to) {
        require(to != address(0x0), "Sending to zero address");
        _;
    }

    function finishLaunch() external onlyOwner {
        require(!tokenLaunched);
        tokenLaunched = true;
	launchTime = block.timestamp;
	stabilityPeriod = block.timestamp + 3 weeks;
    }

    function checkFeeExempt(address _addr) external view returns (bool) {
        return isFeeExempt[_addr];
    }

    function setFeeExempt(address _addr, bool _value) external onlyOwner {
        isFeeExempt[_addr] = _value;
    }

    function updateBlacklist(address _address, bool _value) external onlyOwner {
        blacklist[_address] = _value;
    }

    function setFeeReceivers(address _treasuryReceiver,address _insuranceFundReceiver,address _stakingFeeReceiver) external onlyOwner {
        require(_treasuryReceiver != address(0) && _insuranceFundReceiver != address(0) && _stakingFeeReceiver != address(0));
        treasuryFeeReceiver = _treasuryReceiver;
        insuranceFeeReceiver = _insuranceFundReceiver;
        stakingFeeReceiver = _stakingFeeReceiver;
        isFeeExempt[treasuryFeeReceiver] = true;
        isFeeExempt[insuranceFeeReceiver] = true;
        isFeeExempt[stakingFeeReceiver] = true;
        emit UpdatFeeReceivers(_treasuryReceiver,_insuranceFundReceiver,_stakingFeeReceiver);
    }

    function setFees(
        uint256 _liquidityFee,
        uint256 _burnFee,
        uint256 _buyFeeInsuranceFund,
        uint256 _buyFeeTreasury,
        uint256 _buyFeeStaking,
        uint256 _sellFeeTreasury,
        uint256 _sellFeeInsuranceFund,
        uint256 _sellFeeStakers,
        uint256 _sellFeeStaking,
        uint256 _feeDenominator
    ) external onlyOwner {
        require(
            _liquidityFee <= MAX_FEE_RATE &&
                _burnFee <= MAX_FEE_RATE &&
                _buyFeeInsuranceFund <= MAX_FEE_RATE &&
                _buyFeeTreasury <= MAX_FEE_RATE &&
                _buyFeeStaking <= MAX_FEE_RATE &&
                _sellFeeTreasury <= MAX_FEE_RATE &&
                _sellFeeInsuranceFund <= MAX_FEE_RATE &&
                _sellFeeStakers <= MAX_FEE_RATE,
            "TEST: Max fee exceeded"
        );

        liquidityFee = _liquidityFee;

        buyFeeTreasury = _buyFeeTreasury;
        buyFeeInsuranceFund = _buyFeeInsuranceFund;
        buyFeeStaking = _buyFeeStaking;

        sellFeeTreasury = _sellFeeTreasury;
        sellFeeInsuranceFund = _sellFeeInsuranceFund;
        sellFeeStaking = _sellFeeStaking;

        totalBuyFee = liquidityFee
            .add(burnFee)
            .add(buyFeeTreasury)
            .add(buyFeeInsuranceFund)
            .add(buyFeeStaking);

        totalSellFee = totalBuyFee
            .add(sellFeeTreasury)
            .add(sellFeeInsuranceFund)
            .add(sellFeeStaking);

        feeDenominator = _feeDenominator;

        require(
            totalBuyFee < feeDenominator / 2,
            "TEST: New totalBuyFee is > feeDenominator / 2"
        );
    }

    receive() external payable {}

    function shouldRebase() internal view returns (bool) {
        return nextRebase <= block.timestamp;
    }

    function _rebase() private {
        if (!inSwap) {
            coreRebase(getSupplyDelta());
        }
    }

    function coreRebase(uint256 _supplyDelta) private returns (uint256) {
        uint256 epoch = block.timestamp;

        if (_supplyDelta == 0) {
            emit LogRebase(epoch, _totalSupply);
            return _totalSupply;
        } else {
            _totalSupply = _totalSupply.add(uint256(_supplyDelta));
        }

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        nextRebase = epoch + rebaseFrequencySeconds;

        emit LogRebase(epoch, _totalSupply);

        return _totalSupply;
    }


    function shouldSwapBack() internal view returns (bool) {
        return
            !isCorePair[msg.sender] &&
            !inSwap &&
            swapEnabled &&
            totalBuyFee.add(totalSellFee) > 0 &&
            _gonBalances[address(this)] >= gonSwapThreshold;
    }

    function takeFee(address _sender, address _recipient, uint256 _gonAmount) internal returns (uint256) {
        uint256 realFee = isCorePair[_recipient] ? totalSellFee : totalBuyFee;
	if(inStabilityPeriod() && isCorePair[_recipient]){
		realFee = (totalSellFee.mul(300)).div(200);
	}
        uint256 feeAmount = _gonAmount.mul(realFee).div(feeDenominator);
        _gonBalances[address(this)] = _gonBalances[address(this)].add(feeAmount);
        emit Transfer(_sender, address(this), feeAmount.div(_gonsPerFragment));
        return _gonAmount.sub(feeAmount);
    }


    function getSupplyDelta() public view returns (uint256 supplyDelta) {
        supplyDelta = getCirculatingSupply().mul(rewardYield).div(rewardYieldDenominator);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return (TOTAL_GONS.sub(_gonBalances[DEAD]).sub(_gonBalances[ZERO])).div(_gonsPerFragment);
    }


    function _transferFrom(address _sender,address _recipient,uint256 _amount) internal notBlacklisted(msg.sender) returns (bool) {
        if (inSwap||isFeeExempt[_sender] || isFeeExempt[_recipient]) {
            return _basicTransfer(_sender, _recipient, _amount);
        }
	    require(tokenLaunched);
	    if (isCorePair[_recipient]){require(_amount <=maxSellTransactionAmount);}
        uint256 gonAmount = _amount.mul(_gonsPerFragment);

        if (shouldSwapBack()) {
            swapBack();
        }

        _gonBalances[_sender] = _gonBalances[_sender].sub(gonAmount);
        uint256 gonAmountReceived = takeFee(_sender, _recipient, gonAmount);

        _gonBalances[_recipient] = _gonBalances[_recipient].add(gonAmountReceived);

        emit Transfer(_sender, _recipient, gonAmountReceived.div(_gonsPerFragment));

        if (_totalSupply != MAX_SUPPLY && shouldRebase() && autoRebase) {
            _rebase();
            if (!isCorePair[_sender] && !isCorePair[_recipient]) {
                manualSyncPairs();
            }
        }

        return true;
    }

    function transfer(address _to, uint256 _amount) external override validRecipient(_to) returns (bool) {
        _transferFrom(msg.sender, _to, _amount);
        return true;
    }


    function _basicTransfer(address _from, address _to, uint256 _amount) internal returns (bool) {
        uint256 gonAmount = _amount.mul(_gonsPerFragment);
        _gonBalances[_from] = _gonBalances[_from].sub(gonAmount);
        _gonBalances[_to] = _gonBalances[_to].add(gonAmount);
        emit Transfer(_from, _to, _amount);
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) external override validRecipient(_to) returns (bool) {
        if (_allowedFragments[_from][msg.sender] != type(uint256).max) {
            _allowedFragments[_from][msg.sender] = _allowedFragments[_from][msg.sender].sub(_value, "Insufficient Allowance");
        }
        _transferFrom(_from, _to, _value);
        return true;
    }

    function initialSupply() public pure returns (uint256) {
        return INITIAL_FRAGMENTS_SUPPLY;
    }

    function maxSupply() public pure returns (uint256) {
        return MAX_SUPPLY;
    }

    function totalGons() public pure returns (uint256) {
        return TOTAL_GONS;
    }

    function gonsPerFragment() public view returns (uint256) {
        return _gonsPerFragment;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function allowance(address _owner, address _spender) external view override returns (uint256) {
        return _allowedFragments[_owner][_spender];
    }

    function balanceOf(address _who) public view override returns (uint256) {
        return _gonBalances[_who].div(_gonsPerFragment);
    }

    function lockedBalanceOf(address _who) public view returns (uint256) {
        return _lockedBalances[_who].div(_gonsPerFragment);
    }

    function decreaseAllowance(address _spender, uint256 _subtractedValue) external returns (bool) {
        uint256 oldValue = _allowedFragments[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][_spender] = 0;
        } else {
            _allowedFragments[msg.sender][_spender] = oldValue.sub(
                _subtractedValue
            );
        }
        emit Approval(msg.sender,_spender,_allowedFragments[msg.sender][_spender]);
        return true;
    }

    function increaseAllowance(address _spender, uint256 _addedValue) external returns (bool){
        _allowedFragments[msg.sender][_spender] = _allowedFragments[msg.sender][_spender].add(_addedValue);

        emit Approval(msg.sender, _spender, _allowedFragments[msg.sender][_spender]);
        return true;
    }


    function approve(address spender, uint256 value) external override returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function stake(uint256 _poolId, uint256 _amount) external nonReentrant notBlacklisted(msg.sender){
        require(_amount > 0, "Can not stake zero");
        require(balanceOf(msg.sender) >= _amount,"TEST: Insufficient balance");

        uint256 gonamount = _amount.mul(_gonsPerFragment);
        _gonBalances[msg.sender] = _gonBalances[msg.sender].sub(gonamount);
        _lockedBalances[msg.sender] = _lockedBalances[msg.sender].add(gonamount);
        staking.stake(_poolId, _amount, gonamount, msg.sender);
    }

    function withdrawStakingEarly() external nonReentrant notBlacklisted(msg.sender) {
        (uint256 amountUnlocked, uint256 originalStakedAmount) = staking.withdrawEarly(msg.sender);
        uint256 currentBalance = _gonBalances[msg.sender];
        uint256 fee = originalStakedAmount.sub(amountUnlocked);
        _gonBalances[DEAD] += fee;
        delete _lockedBalances[msg.sender];
        _gonBalances[msg.sender] = currentBalance.add(amountUnlocked);
        emit Transfer(msg.sender, DEAD, originalStakedAmount.div(_gonsPerFragment));
        emit Transfer(msg.sender, DEAD, currentBalance.div(_gonsPerFragment));
        emit Transfer(DEAD,msg.sender, _gonBalances[msg.sender].div(_gonsPerFragment));
    }

    function withdrawStaking(uint256 _poolId) external nonReentrant notBlacklisted(msg.sender) {
        uint256 amountUnlocked = staking.withdraw(_poolId, msg.sender);
        _lockedBalances[msg.sender] = _lockedBalances[msg.sender].sub(amountUnlocked);
        _gonBalances[msg.sender] = _gonBalances[msg.sender].add(amountUnlocked);
    }

    function moveToHigherPool(uint256 _currentPoolId, uint256 _newPoolId) external notBlacklisted(msg.sender) nonReentrant {
        staking.moveToHigherPool(_currentPoolId, _newPoolId, msg.sender);
    }


    function stakeForUser(uint256 _poolId, address _forUser, uint256 _amount ) external  onlyOwner {
        require(_amount > 0, "TEST: Can not stake zero");
        require(balanceOf(treasuryFeeReceiver) >= _amount, "TEST: Treasury has insufficient balance");

        uint256 gonamount = _amount.mul(_gonsPerFragment);
        _gonBalances[treasuryFeeReceiver] = _gonBalances[treasuryFeeReceiver].sub(_amount);
        _lockedBalances[_forUser] = _lockedBalances[_forUser].add(_amount);
        staking.stake(_poolId, _amount, gonamount, _forUser );
    }


    function _swapAndLiquify(uint256 _contractTokenAmount) private {
        uint256 half = _contractTokenAmount.div(2);
        uint256 otherHalf = _contractTokenAmount.sub(half);

        uint256 stableBalanceBefore = IERC20(stableCoinAddress).balanceOf(address(this));
        _swapTokensForStable(half, address(this));

        uint256 stableBalanceAfter = IERC20(stableCoinAddress).balanceOf(address(this)).sub(stableBalanceBefore);
        _addLiquidityStable(otherHalf, stableBalanceAfter);
        emit SwapAndLiquifyStable(half, stableBalanceAfter, otherHalf);
    }

    function _addLiquidityStable(uint256 _tokenAmount, uint256 _stableAmount) private {
        router.addLiquidity(
            address(this),
            stableCoinAddress,
            _tokenAmount,
            _stableAmount,
            0,
            0,
            liquidityTokensReceiver,
            block.timestamp
        );
    }

    function _swapTokensForStable(uint256 _tokenAmount, address _receiver) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        path[2] = stableCoinAddress;

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _tokenAmount,
            0,
            path,
            _receiver,
            block.timestamp
        );
    }

    function _convert(uint256 _contractTokenAmount) private {
        uint256 stableBalanceBefore = IERC20(stableCoinAddress).balanceOf(address(this));
        _swapTokensForStable(_contractTokenAmount, address(this));
        uint256 stableBalanceAfter = IERC20(stableCoinAddress).balanceOf(address(this)).sub(stableBalanceBefore);
	    staking.addToRewardPool(stableBalanceAfter);
    }

    function swapBack() internal swapping {
        uint256 realTotalFee = totalBuyFee.add(totalSellFee);
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity,targetLiquidityDenominator) ? 0: liquidityFee;

        uint256 contractTokenBalance = contractBalance();
        uint256 amountToLiquify = contractTokenBalance.mul(dynamicLiquidityFee.mul(2)).div(realTotalFee);
        uint256 amountToInsuranceFund = contractTokenBalance.mul(buyFeeInsuranceFund.mul(2).add(sellFeeInsuranceFund)).div(realTotalFee);
        uint256 amountToStakers = contractTokenBalance.mul(buyFeeStaking.mul(2).add(sellFeeStaking)).div(realTotalFee);
        uint256 amountToBurn = contractTokenBalance.mul(burnFee.mul(2)).div(realTotalFee);
        uint256 amountToTreasury = contractTokenBalance.sub(amountToLiquify).sub(amountToInsuranceFund).sub(amountToStakers).sub(amountToBurn);

        if (amountToLiquify > 0) {_swapAndLiquify(amountToLiquify);}
        if (amountToInsuranceFund > 0) {_swapTokensForStable(amountToInsuranceFund, insuranceFeeReceiver);}
        if (amountToTreasury > 0) {_swapTokensForStable(amountToTreasury, treasuryFeeReceiver);}
        if (amountToStakers > 0) {_convert(amountToStakers);}
        if (amountToBurn > 0) {_basicTransfer(address(this), DEAD, amountToBurn);}

        emit SwapBack(contractTokenBalance, amountToLiquify, amountToInsuranceFund, amountToTreasury);
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool){
        return getLiquidityBacking(accuracy) > target;
    }

    function getLiquidityBacking(uint256 _accuracy) public view returns (uint256){
        uint256 liquidityBalance = 0;
        uint256 divisor = 10**9;
        for (uint256 i = 0; i < corePairs.length; i++) {
            uint256 pairBalanceDivided = balanceOf(corePairs[i]).div(divisor);
            liquidityBalance.add(pairBalanceDivided);
        }
        uint256 circulatingDivided = getCirculatingSupply().div(divisor);
        return _accuracy.mul(liquidityBalance.mul(2)).div(circulatingDivided);
    }

    function checkSwapThreshold() external view returns (uint256) {
        return gonSwapThreshold.div(_gonsPerFragment);
    }

    function manualSyncPairs() public {
        for (uint256 i = 0; i < corePairs.length; i++) {
            IUniswapV2Pair(corePairs[i]).sync();
        }
    }

    function setStaking(address _stakingContractAddress) external onlyOwner {
        require(_stakingContractAddress != address(0),"Cannot be Null address");
        staking = IStaking(_stakingContractAddress);
        stakingEnabled = true;
        isFeeExempt[_stakingContractAddress] = true;
        IERC20(stableCoinAddress).approve(_stakingContractAddress,type(uint256).max);
    }

    function toggleStakingEnabled(bool _enabled) external onlyOwner {
        require(stakingEnabled != _enabled);
        stakingEnabled = _enabled;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external onlyOwner {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setSwapBackSettings(bool _enabled, uint256 _numerator, uint256 _denomominator) external onlyOwner {
        swapEnabled = _enabled;
        gonSwapThreshold = TOTAL_GONS.mul(_numerator).div(_denomominator);
    }


    function clearStuckBalance(address _receiver) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_receiver).transfer(balance);
    }

    function inStabilityPeriod() internal view returns(bool) {
        return block.timestamp > stabilityPeriod;
    }

    function rescueToken(address _tokenAddress, uint256 _amount) external onlyOwner returns (bool success) {
        return IERC20(_tokenAddress).transfer(msg.sender, _amount);
    }

    function setAutoRebase(bool _autoRebase) external onlyOwner {
        require(autoRebase != _autoRebase, "Value not changed");
        autoRebase = _autoRebase;
    }

    function setRebaseFrequencySeconds(uint256 _rebaseFrequencySeconds) external onlyOwner {
        require(_rebaseFrequencySeconds <= MAX_REBASE_FREQUENCY,"TEST: Rebase frequencey too high");
        rebaseFrequencySeconds = _rebaseFrequencySeconds;
    }

    function setRewardYield(uint256 _rewardYield, uint256 _rewardYieldDenominator) external onlyOwner {
        rewardYield = _rewardYield;
        rewardYieldDenominator = _rewardYieldDenominator;
    }

    function setNextRebase(uint256 _nextRebase) external onlyOwner {
        nextRebase = _nextRebase;
    }

    function setMaxSellTransaction(uint256 _maxTxn) external onlyOwner {
        maxSellTransactionAmount = _maxTxn;
    }

    function setAutomatedMarketMakerPair(address _pair, bool _value) public onlyOwner {
        require(isCorePair[_pair] != _value, "Value already set");
        isCorePair[_pair] = _value;
        if (_value) {
            corePairs.push(_pair);
        } else {
            require(corePairs.length > 1, "Required at 1 pair in corePairs");

            for (uint256 i = 0; i < corePairs.length; i++) {
                if (corePairs[i] == _pair) {
                    corePairs[i] = corePairs[corePairs.length - 1];
                    corePairs.pop();
                    break;
                }
            }
        }

        emit SetAutomatedMarketMakerPair(_pair, _value);
    }

    function manualRebase() external onlyOwner {
        require(nextRebase <= block.timestamp, "TEST: Next rebase already passed");
        coreRebase(getSupplyDelta());
        manualSyncPairs();
    }


    function contractBalance() public view returns (uint256) {
        return balanceOf(address(this));
    }


    /* ================== EVENTS ==================== */

    event SwapBack(uint256 contractTokenBalance, uint256 amountToLiquify, uint256 amountToInsurance, uint256 amountToTreasury);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 nativeReceived, uint256 tokensIntoLiqudity);
    event SwapAndLiquifyStable(uint256 tokensSwapped,uint256 stableReceived,uint256 tokensIntoLiqudity);
    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event UpdatFeeOnNormalTransferse(bool indexed setTo);
    event UpdatFeeReceivers(address treasuryReceiver, address insuranceFundReceiver, address stakingFeeReceiver);

}