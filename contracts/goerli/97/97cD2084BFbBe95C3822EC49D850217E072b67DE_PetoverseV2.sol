/**
 *Submitted for verification at BscScan.com on 2022-02-18
 */

// SPDX-License-Identifier: Unlicensed
//
// PETOVERSE PROTOCOL COPYRIGHT (C) 2022

pragma solidity ^0.7.4;

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);

        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IPancakeSwapPair {
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
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
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

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

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

interface IPancakeSwapRouter {
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

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

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

interface IPancakeSwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
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
}

contract Vault {}

contract LiquidityFeeHolder {}

contract PetoverseV2 is ERC20Detailed, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    event LogRebase(uint256 indexed block, uint256 totalSupply);
    event RewardClaim(address indexed account, uint256 amount, uint256 block, uint256 nextClaim);

    string public _name = "PetoverseV2";
    string public _symbol = "PETO";
    uint8 public _decimals = 5;

    IPancakeSwapPair public pairContract;
    mapping(address => bool) _isFeeExempt;

    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }

    uint256 public constant DECIMALS = 5;
    uint256 public constant MAX_UINT256 = ~uint256(0);

    // Fee
    // buy = 0, sell = 1, p2p = 2
    uint256[] public liquidityFee;
    uint256[] public treasuryFee;
    uint256[] public insuranceFee;
    uint256[] public infernoPitFee;
    uint256 public feeDenominator = 1000;

    uint256 liquidityFeeCollected;
    uint256 treasuryFeeCollected;
    uint256 insuranceFeeCollected;

    //addresses
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address public liquidityFeeHolder;
    address public treasuryReceiver;
    address public insuranceReceiver;
    address public infernoPit;

    // liqudity settings
    bool public _autoAddLiquidity;
    uint256 public _minAmountBeforeLiq = 1e5;
    uint256 public _lastAddLiquidityTime;

    // rebase settings
    bool public _autoRebase;
    uint256 public _lastRebaseBlock;
    uint256 public _rebaseAmount;

    // swap settings
    bool public swapEnabled = true;
    IPancakeSwapRouter public router;
    address public pair;
    bool inSwap = false;

    // reward settings
    mapping(address => uint256) public nextAvailableClaimDate;
    uint256 public rewardCycleInterval;
    uint256 public rewardPerCycle;
    address public vault;

    // sell limit settings
    mapping(address => uint256) public userSells;
    mapping(address => uint256) public userSellCycleStart;
    uint256 public sellPercentAllow = 30;
    bool public sellLimitEnabled = true;

    mapping(address => bool) public blacklist;

    uint256 public _totalSupply;
    uint256 private _gonsPerFragment;

    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 1_000_000 * 10**DECIMALS;
    uint256 private constant MAX_SUPPLY = 10_000_000_000 * 10**DECIMALS;

    mapping(address => uint256) private _gonBalances;
    mapping(address => mapping(address => uint256)) private _allowedFragments;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(
        address _router,
        address _owner,
        address _treasuryReceiver,
        address _insuranceReceiver
    ) ERC20Detailed(_name, _symbol, uint8(DECIMALS)) Ownable() {
        router = IPancakeSwapRouter(_router);
        pair = IPancakeSwapFactory(router.factory()).createPair(router.WETH(), address(this));

        treasuryReceiver = _treasuryReceiver;
        insuranceReceiver = _insuranceReceiver;
        infernoPit = DEAD;

        liquidityFeeHolder = address(new LiquidityFeeHolder());
        vault = address(new Vault());

        _allowedFragments[address(this)][address(router)] = uint256(-1);
        pairContract = IPancakeSwapPair(pair);

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[_owner] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        _lastRebaseBlock = block.timestamp;
        _autoRebase = false;
        _rebaseAmount = 960000; // 10,000 % APY

        _autoAddLiquidity = true;
        _isFeeExempt[_owner] = true;
        _isFeeExempt[address(this)] = true;
        _isFeeExempt[treasuryReceiver] = true;
        _isFeeExempt[insuranceReceiver] = true;
        _isFeeExempt[infernoPit] = true;
        _isFeeExempt[liquidityFeeHolder] = true;
        _isFeeExempt[vault] = true;

        // initialize fee
        liquidityFee.push(20);
        liquidityFee.push(30);
        liquidityFee.push(0);

        treasuryFee.push(0);
        treasuryFee.push(50);
        treasuryFee.push(0);

        insuranceFee.push(0);
        insuranceFee.push(40);
        insuranceFee.push(0);

        infernoPitFee.push(30);
        infernoPitFee.push(30);
        infernoPitFee.push(0);

        _transferOwnership(_owner);

        emit Transfer(address(0x0), _owner, _totalSupply);
    }

    function rebase() internal {
        if (inSwap) return;
        uint256 blockCount = block.number.sub(_lastRebaseBlock);

        _totalSupply = _totalSupply.add(blockCount.mul(_rebaseAmount));
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        _lastRebaseBlock = block.timestamp;

        pairContract.skim(DEAD);

        emit LogRebase(block.timestamp, _totalSupply);
    }

    function transfer(address to, uint256 value) external override validRecipient(to) returns (bool) {
        _transferFrom(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override validRecipient(to) returns (bool) {
        if (_allowedFragments[from][msg.sender] != uint256(-1)) {
            _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(
                value,
                "Insufficient Allowance"
            );
        }
        _transferFrom(from, to, value);
        return true;
    }

    function _basicTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        uint256 gonAmount = amount.mul(_gonsPerFragment);
        _gonBalances[from] = _gonBalances[from].sub(gonAmount);
        _gonBalances[to] = _gonBalances[to].add(gonAmount);
        return true;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(!blacklist[sender] && !blacklist[recipient], "in_blacklist");

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (recipient == pair) {
            validateSell(sender, amount);
        }

        if (shouldRebase()) {
            rebase();
        }

        if (shouldAddLiquidity()) {
            addLiquidity();
        }

        if (shouldSwapBack()) {
            swapBack();
        }

        topUpClaimCycleAfterTransfer(sender, recipient, amount);

        uint256 gonAmount = amount.mul(_gonsPerFragment);
        _gonBalances[sender] = _gonBalances[sender].sub(gonAmount);
        uint256 gonAmountReceived = shouldTakeFee(sender, recipient)
            ? takeFee(sender, recipient, gonAmount)
            : gonAmount;
        _gonBalances[recipient] = _gonBalances[recipient].add(gonAmountReceived);

        emit Transfer(sender, recipient, gonAmountReceived.div(_gonsPerFragment));
        return true;
    }

    function validateSell(address account, uint256 amount) private {
        if (!sellLimitEnabled || _isFeeExempt[account]) return;

        if (userSellCycleStart[account] + 1 days < block.timestamp) {
            userSellCycleStart[account] = block.timestamp;
            userSells[account] = 0;
        }

        uint256 userBalance = balanceOf(account);
        userSells[account] = userSells[account].add(amount);

        require(
            userBalance.mul(sellPercentAllow).div(feeDenominator) > userSells[account],
            "Cannot sell this many tokens"
        );
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 gonAmount
    ) internal returns (uint256) {
        uint256 feeIndex = sender == pair ? 0 : recipient == pair ? 1 : 2;
        uint256 _liquidityFee = liquidityFee[feeIndex];
        uint256 _treasuryFee = treasuryFee[feeIndex];
        uint256 _insuranceFee = insuranceFee[feeIndex];
        uint256 _infernoPitFee = infernoPitFee[feeIndex];

        uint256 _totalFee = _liquidityFee.add(_treasuryFee);
        uint256 feeAmount = gonAmount.div(feeDenominator).mul(_totalFee);

        treasuryFeeCollected = _treasuryFee;
        insuranceFeeCollected = _insuranceFee;

        uint256 pitFee = gonAmount.div(feeDenominator).mul(_infernoPitFee);
        _gonBalances[infernoPit] = _gonBalances[infernoPit].add(pitFee);
        _gonBalances[address(this)] = _gonBalances[address(this)].add(
            gonAmount.div(feeDenominator).mul(_treasuryFee.add(_insuranceFee))
        );
        _gonBalances[liquidityFeeHolder] = _gonBalances[liquidityFeeHolder].add(
            gonAmount.div(feeDenominator).mul(_liquidityFee)
        );

        emit Transfer(sender, address(this), feeAmount.div(_gonsPerFragment));
        emit Transfer(sender, infernoPit, pitFee.div(_gonsPerFragment));
        return gonAmount.sub(feeAmount);
    }

    function addLiquidity() internal swapping {
        uint256 autoLiquidityAmount = _gonBalances[liquidityFeeHolder].div(_gonsPerFragment);
        _gonBalances[address(this)] = _gonBalances[address(this)].add(_gonBalances[liquidityFeeHolder]);
        _gonBalances[liquidityFeeHolder] = 0;
        uint256 amountToLiquify = autoLiquidityAmount.div(2);
        uint256 amountToSwap = autoLiquidityAmount.sub(amountToLiquify);

        if (amountToSwap == 0 || _minAmountBeforeLiq > autoLiquidityAmount) {
            return;
        }
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETHLiquidity = address(this).balance.sub(balanceBefore);

        if (amountToLiquify > 0 && amountETHLiquidity > 0) {
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                DEAD,
                block.timestamp
            );
        }
        _lastAddLiquidityTime = block.timestamp;
    }

    function swapBack() internal swapping {
        uint256 amountToSwap = _gonBalances[address(this)].div(_gonsPerFragment);

        if (amountToSwap == 0) {
            return;
        }

        uint256 balanceBefore = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 ethSwaped = address(this).balance.sub(balanceBefore);

        (bool success, ) = payable(treasuryReceiver).call{
            value: ethSwaped.mul(treasuryFeeCollected).div(treasuryFeeCollected.add(insuranceFeeCollected)),
            gas: 30000
        }("");
        (success, ) = payable(insuranceReceiver).call{
            value: ethSwaped.mul(insuranceFeeCollected).div(treasuryFeeCollected.add(insuranceFeeCollected)),
            gas: 30000
        }("");
    }

    function calculateReward(address account) public view returns (uint256) {
        uint256 _circulatingSupply = _totalSupply
            .sub(balanceOf(address(this)))
            .sub(balanceOf(pair))
            .sub(balanceOf(owner()))
            .sub(balanceOf(vault))
            .sub(balanceOf(DEAD))
            .sub(balanceOf(address(0)));

        uint256 currentBalance = balanceOf(address(account));
        uint256 reward = rewardPerCycle.mul(currentBalance).div(_circulatingSupply);

        return reward;
    }

    function claimReward() public {
        require(nextAvailableClaimDate[msg.sender] <= block.timestamp, "Error: Reward Claim unavailable!");
        require(balanceOf(msg.sender) >= 0, "Error: Must be a holder to claim  rewards!");

        uint256 reward = calculateReward(msg.sender);
        nextAvailableClaimDate[msg.sender] = block.timestamp + rewardCycleInterval;
        _basicTransfer(vault, msg.sender, reward);

        emit RewardClaim(msg.sender, reward, block.timestamp, nextAvailableClaimDate[msg.sender]);
    }

    function topUpClaimCycleAfterTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        uint256 currentSenderBalance = balanceOf(sender);

        if (recipient == pair && currentSenderBalance == amount) {
            nextAvailableClaimDate[sender] = 0;
        } else {
            nextAvailableClaimDate[recipient] = block.timestamp + rewardCycleInterval;
        }
    }

    function shouldTakeFee(address from, address to) internal view returns (bool) {
        return (pair == from || pair == to) && !_isFeeExempt[from] && !_isFeeExempt[to];
    }

    function shouldRebase() internal view returns (bool) {
        return _autoRebase && (_totalSupply < MAX_SUPPLY) && msg.sender != pair && !inSwap;
    }

    function shouldAddLiquidity() internal view returns (bool) {
        return
            _autoAddLiquidity && !inSwap && msg.sender != pair && block.timestamp >= (_lastAddLiquidityTime + 48 hours);
    }

    function shouldSwapBack() internal view returns (bool) {
        return !inSwap && msg.sender != pair;
    }

    function setAutoRebase(bool _flag) external onlyOwner {
        if (_flag) {
            _autoRebase = _flag;
            _lastRebaseBlock = block.number;
        } else {
            _autoRebase = _flag;
        }
    }

    function setAutoAddLiquidity(bool _flag) external onlyOwner {
        if (_flag) {
            _autoAddLiquidity = _flag;
            _lastAddLiquidityTime = block.timestamp;
        } else {
            _autoAddLiquidity = _flag;
        }
    }

    function setMinAmountBeforeLiq(uint256 _amount) external onlyOwner {
        _minAmountBeforeLiq = _amount;
    }

    function allowance(address owner_, address spender) external view override returns (uint256) {
        return _allowedFragments[owner_][spender];
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    function approve(address spender, uint256 value) external override returns (bool) {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function checkFeeExempt(address _addr) external view returns (bool) {
        return _isFeeExempt[_addr];
    }

    function isNotInSwap() external view returns (bool) {
        return !inSwap;
    }

    function setFeeReceivers(
        address _treasuryReceiver,
        address _insuranceReceiver,
        address _infernoPit
    ) external onlyOwner {
        treasuryReceiver = _treasuryReceiver;
        insuranceReceiver = _insuranceReceiver;
        infernoPit = _infernoPit;
    }

    function setRewardCycle(uint256 _interval, uint256 _rewardPerCycle) external onlyOwner {
        rewardCycleInterval = _interval;
        rewardPerCycle = _rewardPerCycle;
    }

    function setFee(
        uint256 _feeIndex,
        uint256 _liquidityFee,
        uint256 _treasuryFee,
        uint256 _insuranceFee,
        uint256 _infernoPitFee
    ) external onlyOwner {
        liquidityFee[_feeIndex] = _liquidityFee;
        treasuryFee[_feeIndex] = _treasuryFee;
        insuranceFee[_feeIndex] = _insuranceFee;
        infernoPitFee[_feeIndex] = _infernoPitFee;

        uint256 totalFee = _liquidityFee.add(_treasuryFee).add(_insuranceFee).add(_infernoPitFee);
        require(totalFee <= 250, "Fee too high!");
    }

    function setSellSettings(uint256 _sellPercentAllow, bool _sellLimitEnabled) external onlyOwner {
        sellPercentAllow = _sellPercentAllow;
        sellLimitEnabled = _sellLimitEnabled;
    }

    function setWhitelist(address _addr) external onlyOwner {
        _isFeeExempt[_addr] = true;
    }

    function setBotBlacklist(address _botAddress, bool _flag) external onlyOwner {
        require(isContract(_botAddress), "only contract address, not allowed exteranlly owned account");
        blacklist[_botAddress] = _flag;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address who) public view override returns (uint256) {
        return _gonBalances[who].div(_gonsPerFragment);
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    receive() external payable {}
}