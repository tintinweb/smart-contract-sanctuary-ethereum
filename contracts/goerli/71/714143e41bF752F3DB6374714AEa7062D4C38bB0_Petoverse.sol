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

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    modifier isHuman() {
        require(tx.origin == msg.sender, "sorry humans only");
        _;
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

contract Petoverse is ERC20Detailed, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    event RewardClaimedSuccessfully(
        address indexed recipient,
        uint256 reward,
        uint256 nextAvailableClaimDate,
        uint256 timestamp
    );

    string public _name = "Petoverse";
    string public _symbol = "PETO";
    uint8 public _decimals = 5;

    IPancakeSwapPair public pairContract;
    IERC20 public petoverseV1;
    uint256 public RATE = 1 ; // V2 token rate
    mapping(address => bool) _isFeeExempt;

    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }

    uint256 public constant DECIMALS = 5;
    uint256 public constant MAX_UINT256 = ~uint256(0);
    uint8 public constant RATE_DECIMALS = 7;

    //Reward settings
    mapping(address => uint256) public nextAvailableClaimDate;
    uint256 public rewardCycleInterval;

    //Buy fee
    uint256 public liquidityFee = 30;
    uint256 public gameTreasuryFee = 30;
    uint256 public atlasFarmFee = 20;
    uint256 public burnFee = 20;
    uint256 public infernoPitFee = 80;
    uint256 public totalFee = liquidityFee.add(gameTreasuryFee).add(atlasFarmFee).add(infernoPitFee).add(burnFee);

    //Sell fee
    uint256 public sellLiquidityFee = 40;
    uint256 public sellGameTreasuryFee = 50;
    uint256 public sellAtlasFarmFee = 40;
    uint256 public sellBurnFee = 20;
    uint256 public sellInfernoPitFee = 30;
    uint256 public sellTotalFee =
        sellLiquidityFee.add(sellGameTreasuryFee).add(sellAtlasFarmFee).add(sellBurnFee).add(sellInfernoPitFee);

    uint256 public sellFee = 20;
    uint256 public feeDenominator = 1000;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    address public autoLiquidityReceiver;
    address public gameTreasuryReceiver;
    address public petoInsuranceFundReceiver;
    address public infernoPit;
    address public pairAddress;
    bool public swapEnabled = true;
    IPancakeSwapRouter public router;
    address public pair;
    bool inSwap = false;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 800_000 * 10**DECIMALS;
    uint256 private constant MAX_SUPPLY = 800_000_000 * 10**DECIMALS;

    bool public _autoRebase;
    bool public _autoAddLiquidity;

    uint256 public claimTokensReserves;
    uint256 public _initRebaseStartTime;
    uint256 public _lastRebasedTime;
    uint256 public _lastAddLiquidityTime;
    uint256 public _totalSupply;
    uint256 private _gonsPerFragment;

    uint256 public rebaseInterval = 15 minutes;

    mapping(address => uint256) private _gonBalances;
    mapping(address => mapping(address => uint256)) private _allowedFragments;
    mapping(address => bool) public blacklist;

    constructor(
        address _router,
        address _owner,
        address _gameTreasuryReceiver,
        address _petoInsuranceFundReceiver,
        address _petoverseV1,
        uint256 _claimTokensReserves
    ) ERC20Detailed(_name, _symbol, uint8(DECIMALS)) Ownable() {
        router = IPancakeSwapRouter(_router);
        pair = IPancakeSwapFactory(router.factory()).createPair(router.WETH(), address(this));

        autoLiquidityReceiver = DEAD;
        gameTreasuryReceiver = _gameTreasuryReceiver;
        petoInsuranceFundReceiver = _petoInsuranceFundReceiver;
        infernoPit = ZERO;

        _allowedFragments[address(this)][address(router)] = uint256(-1);
        pairAddress = pair;
        pairContract = IPancakeSwapPair(pair);
        petoverseV1 = IERC20(_petoverseV1);

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;

        _gonBalances[_owner] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        _initRebaseStartTime = block.timestamp;
        _lastRebasedTime = block.timestamp;
        _autoRebase = false;
        _autoAddLiquidity = true;
        _isFeeExempt[_owner] = true;
        _isFeeExempt[address(this)] = true;

        //token transfer to calim reserves
        claimTokensReserves = _claimTokensReserves;

        uint256 gonAmount = _claimTokensReserves.mul(_gonsPerFragment);
        _gonBalances[_owner] = _gonBalances[_owner].sub(gonAmount);
        _gonBalances[address(this)] = _gonBalances[address(this)].add(gonAmount);

        _transferOwnership(_owner);

        emit Transfer(address(0x0), _owner, _totalSupply.sub(_claimTokensReserves.div(_gonsPerFragment)));
        emit Transfer(_owner, address(this), _claimTokensReserves.div(_gonsPerFragment));
    }

    function rebase() internal {
        if (inSwap) return;
        uint256 rebaseRate;
        uint256 deltaTimeFromInit = block.timestamp - _initRebaseStartTime;
        uint256 deltaTime = block.timestamp - _lastRebasedTime;
        uint256 times = deltaTime.div(rebaseInterval);
        uint256 epoch = times.mul(15);
        uint256 _lastContractBalance = balanceOf(address(this));

        if (deltaTimeFromInit < (365 days)) {
            rebaseRate = 2838;
        } else if (deltaTimeFromInit >= (365 days)) {
            rebaseRate = 211;
        } else if (deltaTimeFromInit >= ((15 * 365 days) / 10)) {
            rebaseRate = 14;
        } else if (deltaTimeFromInit >= (7 * 365 days)) {
            rebaseRate = 2;
        }

        for (uint256 i = 0; i < times; i++) {
            _totalSupply = _totalSupply.mul((10**RATE_DECIMALS).add(rebaseRate)).div(10**RATE_DECIMALS);
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        _lastRebasedTime = _lastRebasedTime.add(times.mul(rebaseInterval));

        uint256 _contractBalance = balanceOf(address(this));

        _basicTransfer(address(this), DEAD, _contractBalance.sub(_lastContractBalance));
        pairContract.skim(DEAD);

        emit LogRebase(epoch, _totalSupply);
    }

    function transfer(address to, uint256 value) external override validRecipient(to) returns (bool) {
        _transferFrom(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override validRecipient(to) returns (bool) {
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

        if (recipient != pair && sender != pair) 
            return _basicTransfer(sender, recipient, amount);

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
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

        uint256 gonAmount = amount.mul(_gonsPerFragment);
        _gonBalances[sender] = _gonBalances[sender].sub(gonAmount);

        if (recipient == pair) {
            uint256 sellgonAmountReceived = shouldTakeFee(sender, recipient)
                ? sellTakeFee(sender, gonAmount)
                : gonAmount;
            _gonBalances[recipient] = _gonBalances[recipient].add(sellgonAmountReceived);

            emit Transfer(sender, recipient, sellgonAmountReceived.div(_gonsPerFragment));
            return true;
        }

        uint256 gonAmountReceived = shouldTakeFee(sender, recipient)
            ? takeFee(sender, gonAmount)
            : gonAmount;
        _gonBalances[recipient] = _gonBalances[recipient].add(gonAmountReceived);

        emit Transfer(sender, recipient, gonAmountReceived.div(_gonsPerFragment));
        return true;
    }

    function sellTakeFee(
        address sender,
        uint256 gonAmount
    ) internal returns (uint256) {
        uint256 _totalFee = sellTotalFee;
        uint256 _gameTreasuryFee = sellGameTreasuryFee;

        uint256 feeAmount = gonAmount.div(feeDenominator).mul(_totalFee);

        _gonBalances[infernoPit] = _gonBalances[infernoPit].add(gonAmount.div(feeDenominator).mul(infernoPitFee));
        _gonBalances[address(this)] = _gonBalances[address(this)].add(
            gonAmount.div(feeDenominator).mul(_gameTreasuryFee.add(atlasFarmFee))
        );
        _gonBalances[autoLiquidityReceiver] = _gonBalances[autoLiquidityReceiver].add(
            gonAmount.div(feeDenominator).mul(liquidityFee)
        );

        emit Transfer(sender, address(this), feeAmount.div(_gonsPerFragment));
        emit Transfer(sender, infernoPit, infernoPitFee.div(_gonsPerFragment));
        return gonAmount.sub(feeAmount);
    }

    function takeFee(
        address sender,
        uint256 gonAmount
    ) internal returns (uint256) {
        uint256 _totalFee = totalFee;
        uint256 _gameTreasuryFee = gameTreasuryFee;

        uint256 feeAmount = gonAmount.div(feeDenominator).mul(_totalFee);

        _gonBalances[infernoPit] = _gonBalances[infernoPit].add(gonAmount.div(feeDenominator).mul(infernoPitFee));
        _gonBalances[address(this)] = _gonBalances[address(this)].add(
            gonAmount.div(feeDenominator).mul(_gameTreasuryFee.add(atlasFarmFee))
        );
        _gonBalances[autoLiquidityReceiver] = _gonBalances[autoLiquidityReceiver].add(
            gonAmount.div(feeDenominator).mul(liquidityFee)
        );

        emit Transfer(sender, address(this), feeAmount.div(_gonsPerFragment));
        emit Transfer(sender, infernoPit, infernoPitFee.div(_gonsPerFragment));
        return gonAmount.sub(feeAmount);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address who) public view override returns (uint256) {
        return _gonBalances[who].div(_gonsPerFragment);
    }

    function addLiquidity() internal swapping {
        uint256 autoLiquidityAmount = _gonBalances[autoLiquidityReceiver].div(_gonsPerFragment);
        _gonBalances[address(this)] = _gonBalances[address(this)].add(_gonBalances[autoLiquidityReceiver]);
        _gonBalances[autoLiquidityReceiver] = 0;
        uint256 amountToLiquify = autoLiquidityAmount.div(2);
        uint256 amountToSwap = autoLiquidityAmount.sub(amountToLiquify);

        if (amountToSwap == 0) {
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

        uint256 amountETHTogameTreasuryAndSIF = address(this).balance.sub(balanceBefore);

        (bool success, ) = payable(gameTreasuryReceiver).call{
            value: amountETHTogameTreasuryAndSIF.mul(gameTreasuryFee).div(gameTreasuryFee.add(atlasFarmFee)),
            gas: 30000
        }("");
        (success, ) = payable(petoInsuranceFundReceiver).call{
            value: amountETHTogameTreasuryAndSIF.mul(atlasFarmFee).div(gameTreasuryFee.add(atlasFarmFee)),
            gas: 30000
        }("");
    }

    function withdrawAllTogameTreasury() external swapping onlyOwner {
        uint256 amountToSwap = _gonBalances[address(this)].div(_gonsPerFragment);
        require(amountToSwap > 0, "There is no token deposited in token contract");
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            gameTreasuryReceiver,
            block.timestamp
        );
    }

    function shouldTakeFee(address from, address to) internal view returns (bool) {
        return (pair == from || pair == to) && !_isFeeExempt[from] && !_isFeeExempt[to];
    }

    function shouldRebase() internal view returns (bool) {
        return
            _autoRebase &&
            (_totalSupply < MAX_SUPPLY) &&
            msg.sender != pair &&
            !inSwap &&
            block.timestamp >= (_lastRebasedTime + rebaseInterval);
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
            _lastRebasedTime = block.timestamp;
        } else {
            _autoRebase = _flag;
        }
    }

    function calculateReward(address account) public view returns (uint256) {
        uint256 currentBalance = balanceOf(address(account));

        uint256 reward = claimTokensReserves.mul(currentBalance).div(_totalSupply);
    
        return reward;
    }

    function claimReward() public isHuman nonReentrant swapping {
        require(nextAvailableClaimDate[msg.sender] <= block.timestamp, "Error: Reward Claim unavailable!");
        require(balanceOf(msg.sender) >= 0, "Error: Must be a holder to claim  rewards!");
        require(claimTokensReserves >= 0, "Error: Not enough tokens for rewards");

        uint256 reward = calculateReward(msg.sender);

        // update rewardCycleBlock
        nextAvailableClaimDate[msg.sender] = block.timestamp + rewardCycleInterval;
        claimTokensReserves = claimTokensReserves.sub(reward);
        _basicTransfer(address(this),msg.sender, reward);

        emit RewardClaimedSuccessfully(msg.sender, reward, nextAvailableClaimDate[msg.sender], block.timestamp);
    }


    function claimV2Tokens() public isHuman nonReentrant {
        require(petoverseV1.balanceOf(msg.sender) > 0,"Error: Not enough V1 tokens");
        uint256 _userbalance = petoverseV1.balanceOf(msg.sender);
        uint256 _amount = _userbalance * RATE;
        petoverseV1.transferFrom(owner(), DEAD, _userbalance);
        transferFrom(owner(), msg.sender, _amount);
    }

    function setAutoAddLiquidity(bool _flag) external onlyOwner {
        if (_flag) {
            _autoAddLiquidity = _flag;
            _lastAddLiquidityTime = block.timestamp;
        } else {
            _autoAddLiquidity = _flag;
        }
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

    function approve(address spender, uint256 value) public override returns (bool) {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function checkFeeExempt(address _addr) external view returns (bool) {
        return _isFeeExempt[_addr];
    }

    function getCirculatingSupply() public view returns (uint256) {
        return (TOTAL_GONS.sub(_gonBalances[DEAD]).sub(_gonBalances[ZERO])).div(_gonsPerFragment);
    }

    function isNotInSwap() external view returns (bool) {
        return !inSwap;
    }

    function manualSync() external {
        IPancakeSwapPair(pair).sync();
    }

    function setFeeReceivers(
        address _gameTreasuryReceiver,
        address _petoInsuranceFundReceiver,
        address _infernoPit
    ) external onlyOwner {
        gameTreasuryReceiver = _gameTreasuryReceiver;
        petoInsuranceFundReceiver = _petoInsuranceFundReceiver;
        infernoPit = _infernoPit;
    }

    function setBuyFee(
        uint256 _liquidityFee,
        uint256 _gameTreasuryFee,
        uint256 _petoInsuranceFundFee,
        uint256 _infernoPitFee,
        uint256 _burnFee
    ) external onlyOwner {
        liquidityFee = _liquidityFee;
        gameTreasuryFee = _gameTreasuryFee;
        atlasFarmFee = _petoInsuranceFundFee;
        infernoPitFee = _infernoPitFee;
        burnFee = _burnFee;
        totalFee = liquidityFee.add(gameTreasuryFee).add(atlasFarmFee).add(infernoPitFee).add(_burnFee);

        require(totalFee <= 250, "Fee too high!");
    }

    function setSellFee(
        uint256 _liquidityFee,
        uint256 _gameTreasuryFee,
        uint256 _petoInsuranceFundFee,
        uint256 _infernoPitFee,
        uint256 _burnFee
    ) external onlyOwner {
        sellLiquidityFee = _liquidityFee;
        sellGameTreasuryFee = _gameTreasuryFee;
        sellAtlasFarmFee = _petoInsuranceFundFee;
        sellInfernoPitFee = _infernoPitFee;
        sellBurnFee = _burnFee;

        sellTotalFee = liquidityFee.add(gameTreasuryFee).add(atlasFarmFee).add(infernoPitFee).add(_burnFee);

        require(sellTotalFee <= 250, "Fee too high!");
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        uint256 liquidityBalance = _gonBalances[pair].div(_gonsPerFragment);
        return accuracy.mul(liquidityBalance.mul(2)).div(getCirculatingSupply());
    }

    function setWhitelist(address _addr) external onlyOwner {
        _isFeeExempt[_addr] = true;
    }

    function setRate(uint256 _rate) external onlyOwner {
        RATE = _rate;
    }

    function setBotBlacklist(address _botAddress, bool _flag) external onlyOwner {
        require(isContract(_botAddress), "only contract address, not allowed exteranlly owned account");
        blacklist[_botAddress] = _flag;
    }

    function setRewardCycleInterval(uint256 interval) external onlyOwner {
        rewardCycleInterval = interval;
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