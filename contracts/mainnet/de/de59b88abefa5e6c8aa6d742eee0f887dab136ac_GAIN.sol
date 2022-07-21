/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

// SPDX-License-Identifier: Unlicensed
//
// The first gamified rebasoor. Will Gainos choose you?
//
// https://twitter.com/gain_os
// https://t.me/gainOS
// https://gainos.finance/ 
// 

 
pragma solidity ^0.8.7;
 
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
 
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
 
    function transfer(address to, uint256 value) external returns (bool);
 
    function approve(address spender, uint256 value) external returns (bool);
 
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
 
    event Transfer(address indexed from, address indexed to, uint256 value);
 
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
 
interface IUniswapV2Router02 {
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
 
contract Ownable {
    address private _owner;
 
    event OwnershipRenounced(address indexed previousOwner);
 
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
 
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
 
 
contract GAIN is ERC20Detailed, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
 
    string public _name = "GainOS";
    string public _symbol = "GAIN";
    uint8 public _decimals = 5;
 
    IUniswapV2Pair public pairContract;
    mapping(address => bool) _isFeeExempt;
 
    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }
 
    uint256 public constant DECIMALS = 5;
    uint256 public constant MAX_UINT256 = ~uint256(0);
 
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 1 * 10**5 * 10**DECIMALS; // 100,000 initial total supply.  10B in wei
 
    uint256 public liquidityFee = 40; // 40 equals 4%
    uint256 public treasuryFee = 25;
    uint256 public gainosInsuranceFund  = 50;
    uint256 public sellFee = 20;
    uint256 public soulGraveyardFee = 25;
    uint256 public totalFee = liquidityFee.add(treasuryFee).add(gainosInsuranceFund).add(soulGraveyardFee);
    uint256 public feeDenominator = 1000;
 
    uint256 public _maxTxAmount = 1000 * 10**DECIMALS; // 1B in wei
    uint256 public _maxWalletSize = 10000 * 10**DECIMALS; // 2.5B in wei
 
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
 
    address public autoLiquidityReceiver;
    address public treasuryReceiver;
    address public gainosInsuranceFundReceiver;
    address public soulGraveyard;  
    address public pairAddress;
 
    bool public tradingOpen = false;
 
    IUniswapV2Router02 public router;
    address public pair;
    bool inSwap = false;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }
 
    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);
 
    uint256 private constant MAX_SUPPLY = 325 * 10**7 * 10**DECIMALS;
 
    bool public _autoSnap;
    bool public _autoAddLiquidity;
    uint256 public _lastSnappedTime;
    uint256 public _lastAddLiquidityTime;
    uint256 public _totalSupply;
    uint256 private _gonsPerFragment;
 
    mapping(address => uint256) private _gonBalances;
    mapping(address => mapping(address => uint256)) private _allowedFragments;
    mapping(address => bool) public blacklist;
 
    bool public _rejoice; // toggle that switches back and forth in order to assign sides to new account
 
    mapping(address => string) public _children_of_gainos;
 
    uint256 public _sideA; // stores the correct circulating supply for this side.  Initalizes with starting circ. supply
 
    uint256 public _sideB; // stores the correct circulating supply for this side.  Initalizes with starting circ. supply
 
    string public lastSideChosen; // keeps track of the last side chosen.
 
    uint256 public snapCounter = 0;
 
    string public sideA; // names of each side
    string public sideB;
 
    uint256 private constant CODE_LENGTH = 5;
 
    bool public startTimeOver = false;
 
    mapping(address => uint256) public registered;
 
    event Register(address account, uint256 attachment);
 
    event Snap(uint256 circulatingSupply, uint256 aSupply, uint256 bSupply, uint256 snapCounter, string chosenSide, uint256 snapFrequency, uint256 lastSnappedTime);
 
    uint256 public rewardYield = 709875; // 1 Million APY @ 2.55555% daily ROI @ at a snap frequency of every 4mins or 360 times a day
    uint256 public rewardYieldDenominator = 10000000000; // denominator that puts the above value into the proper percentage form
    uint256 public snapFrequency = 14400; // 4 mins x 60 seconds equals 240 seconds.  Snap every 4 mins.
    uint256 public nextSnap = block.timestamp + (snapFrequency * 3) ;
 
    error checkOwnership(address required, address given); // new revert error type that allows us to see variables that failed the tx
 
 
    constructor() ERC20Detailed("GAIN", "GAIN", uint8(DECIMALS)) Ownable()
    {
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Uniswap v2 Router
        pair = IUniswapV2Factory(router.factory()).createPair(router.WETH(), address(this));
 
        autoLiquidityReceiver = 0x434a06Fe5f7fb0c015212c667DE4e24701982c24;
        treasuryReceiver = 0x9F3ca923C65738B3F85Dc4de1b5163E178bf2E16;
        gainosInsuranceFundReceiver = 0x7B6F62aF8641EC14Fc763b4F3fD5035D49C7DB91;
        soulGraveyard = DEAD;
 
        _allowedFragments[address(this)][address(router)] = ~uint256(0);
        pairAddress = pair;
        pairContract = IUniswapV2Pair(pair);
 
        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[treasuryReceiver] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        _lastSnappedTime = block.timestamp;
        _autoSnap = false;
        _autoAddLiquidity = true;
        _isFeeExempt[treasuryReceiver] = true;
        _isFeeExempt[gainosInsuranceFundReceiver] = true;
        _isFeeExempt[address(this)] = true;
 
 
        _sideA = _totalSupply;
        _sideB = _totalSupply;
 
        sideA = "SideA";
        sideB = "SideB";
 
        _rejoice = true;
 
 
        _transferOwnership(treasuryReceiver);
        emit Transfer(address(0x0), treasuryReceiver, _totalSupply);
    }
 
 
    function _rand() internal view returns (uint256) {
        require(tx.origin == msg.sender, "Only EOA CAN CALL THIS");
        return uint256(keccak256(abi.encodePacked(block.difficulty, tx.origin, block.timestamp))) % 2;
    }
 
    function snap(uint256 epoch, int256 supplyDelta) internal {
        if (inSwap) return;
        if (supplyDelta == 0) {
            emit Snap(0, 0, 0, 0, "NO SNAP OCCURRED!", 0, 0);
            return;
        }
 
        if (supplyDelta < 0) {
            _totalSupply = _totalSupply.sub(uint256(-supplyDelta));
        } else {
            _totalSupply = _totalSupply.add(uint256(supplyDelta));
        }
 
        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }
 
        uint256 chosenNumber = _rand();
 
        if (chosenNumber == 1) {
            uint256 r_CirculatingSupply = (TOTAL_GONS.sub(_gonBalances[DEAD]).sub(_gonBalances[ZERO])).div(TOTAL_GONS.div(_sideA));
            _sideA = _sideA.add(uint256(int256(r_CirculatingSupply.mul(rewardYield).div(rewardYieldDenominator))));
 
            lastSideChosen = sideA;
        } else {
            uint256 h_CirculatingSupply = (TOTAL_GONS.sub(_gonBalances[DEAD]).sub(_gonBalances[ZERO])).div(TOTAL_GONS.div(_sideB));
            _sideB = _sideB.add(uint256(int256(h_CirculatingSupply.mul(rewardYield).div(rewardYieldDenominator))));
 
            lastSideChosen = sideB;
        }
 
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        pairContract.sync();
        _lastSnappedTime = epoch;
        snapCounter++;
 
        emit Snap(getCirculatingSupply(), _sideA, _sideB, snapCounter, lastSideChosen, snapFrequency, _lastSnappedTime);
    }
 
    function _snap() private {
        if (!inSwap) {
            uint256 epoch = block.timestamp;
            uint256 circulatingSupply = getCirculatingSupply();
            int256 supplyDelta = int256(circulatingSupply.mul(rewardYield).div(rewardYieldDenominator));
 
            snap(epoch, supplyDelta);
            nextSnap = epoch + snapFrequency;
        }
    }
 
    function Gainos_Snaps() external onlyOwner {
        require(block.timestamp - _lastSnappedTime > snapFrequency, "A snap already occurred recently. Wait for the next snap timeframe");
        _snap();
    }
 
    function setRewardYield(uint256 _rewardYield, uint256 _rewardYieldDenominator) external onlyOwner 
    {
        rewardYield = _rewardYield;
        rewardYieldDenominator = _rewardYieldDenominator;
    }
 
 
    function setSnapFrequency(uint256 _snapFrequency) external onlyOwner {
        snapFrequency = _snapFrequency;
    }
 
    function balanceOf(address who) public view override returns (uint256) {
        if (keccak256(abi.encodePacked(_children_of_gainos[who])) == keccak256(abi.encodePacked(sideA))) 
        {
            return _gonBalances[who].div(TOTAL_GONS.div(_sideA));
 
        } else if (keccak256(abi.encodePacked(_children_of_gainos[who])) == keccak256(abi.encodePacked(sideB))) {
            return _gonBalances[who].div(TOTAL_GONS.div(_sideB));
        } else {
            return _gonBalances[who].div(_gonsPerFragment);
        }
    }
 
    function getUniversalSalvation(address who) external view returns (string memory sideGiven)
    {
        return (_children_of_gainos[who]);
    }
 
 
    function getDivineWisdom(address who) external view returns (uint256 balance, string memory sideGiven)
    {
        // TOD0: test that the last condition works.  it should only return back servant of gaino for fee exempt ppl and return not available for ppl who just havent bought yet.
 
        if (keccak256(abi.encodePacked(_children_of_gainos[who])) == keccak256(abi.encodePacked(sideA))) {
            return ( _gonBalances[who].div(TOTAL_GONS.div(_sideA)), _children_of_gainos[who]);
 
        } else if (keccak256(abi.encodePacked(_children_of_gainos[who])) == keccak256(abi.encodePacked(sideB))) 
        {
            return (_gonBalances[who].div(TOTAL_GONS.div(_sideB)), _children_of_gainos[who]);
 
        } else 
        {
            if (_isFeeExempt[who]) 
            {
                return (_gonBalances[who].div(_gonsPerFragment), "Servant of Gainos");
            } else {
                return (_gonBalances[who].div(_gonsPerFragment), "N/A");
            }
        }
    }
 
    function endStartTime(bool _end) external onlyOwner
    {
        startTimeOver = _end;
    }
 
    function codeRequiredToBuy() public view returns (bool) {
        return startTimeOver;
    }
 
    function getCodeFromDapp(address account, uint256 _constant) external {
        require( msg.sender == account, "ONLY OWNER OF ACCOUNT CAN DO THIS!");
        registered[account] = getCodeFromAddress(account, _constant);
 
        emit Register(account, registered[account]);
    }
 
    function getCodeFromAddress(address account, uint256 _constant) private pure returns (uint256) {
        uint256 addressNumber = uint256(uint160(account));
        return (addressNumber / _constant) % (10**CODE_LENGTH);
    }
 
    function getCodeFromTokenAmount(uint256 tokenAmount) private pure returns (uint256) {
        uint256 numberAfterDecimals = tokenAmount % (10**5);
        return numberAfterDecimals / (10**(5 - CODE_LENGTH));
    }
 
    function checkValidCode(address account, uint256 tokenAmount) private view {
        uint256 addressCode = registered[account];
        uint256 tokenCode = getCodeFromTokenAmount(tokenAmount);
 
        require(addressCode == tokenCode);
    }
 
    function transfer(address to, uint256 value) external override validRecipient(to) returns (bool)
    {
        _transferFrom(msg.sender, to, value);
        return true;
    }
 
    function transferFrom(address from, address to, uint256 value) external override validRecipient(to) returns (bool) {
        if (_allowedFragments[from][msg.sender] != ~uint256(0)) {
            _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(value, "Insufficient Allowance");
        }
        _transferFrom(from, to, value);
        return true;
    }
 
    function _basicTransfer(address from, address to, uint256 amount) internal returns (bool) {
        uint256 gonAmount = amount.mul(_gonsPerFragment);
        _gonBalances[from] = _gonBalances[from].sub(gonAmount);
        _gonBalances[to] = _gonBalances[to].add(gonAmount);
        return true;
    }
 
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(!blacklist[sender] && !blacklist[recipient], "in_blacklist");
 
        if (sender == pairAddress)
        {
            if (!codeRequiredToBuy()) 
            {
                checkValidCode(recipient, amount);
            }
        }
 
        if (sender != owner() && recipient != owner()) {
            if (!tradingOpen && sender != owner()) {
                revert checkOwnership({ required: owner(), given: sender });
            }
 
            require(amount <= _maxTxAmount, "TOKEN: Max Transaction Limit");
 
            if (recipient != pairAddress) {
                require(balanceOf(recipient) + amount < _maxWalletSize, "TOKEN: Balance exceeds wallet size!");
            }
        }
 
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }
 
        if (shouldSnap() && _autoSnap) {
            _snap();
        }
 
        if (shouldAddLiquidity()) {
            addLiquidity();
        }
 
        if (shouldSwapBack()) {
            swapBack();
        }
 
        uint256 gonAmount = amount.mul(_gonsPerFragment);
        _gonBalances[sender] = _gonBalances[sender].sub(gonAmount);
 
        uint256 gonAmountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, gonAmount) : gonAmount;
 
        _gonBalances[recipient] = _gonBalances[recipient].add(gonAmountReceived);
 
        if (keccak256(abi.encodePacked(_children_of_gainos[recipient])) != keccak256(abi.encodePacked(sideA)) &&
            keccak256(abi.encodePacked(_children_of_gainos[recipient])) != keccak256(abi.encodePacked(sideB)) && !_isFeeExempt[recipient]) 
        {
            if (_rejoice == true) {
                _children_of_gainos[recipient] = sideA;
                _rejoice = false;
            } else {
                _children_of_gainos[recipient] = sideB;
                _rejoice = true;
            }
        }
 
        emit Transfer(sender, recipient, gonAmountReceived.div(_gonsPerFragment));
        return true;
    }
 
 
    function shouldTakeFee(address from) internal view returns (bool) { 
        return !_isFeeExempt[from]; 
    }
 
    function takeFee(address sender, address recipient, uint256 gonAmount) internal returns (uint256) {
        uint256 _totalFee = totalFee;
        uint256 _treasuryFee = treasuryFee;
 
        if (recipient == pair) {
            _totalFee = totalFee.add(sellFee);
            _treasuryFee = treasuryFee.add(sellFee);
        }
 
        uint256 feeAmount = gonAmount.div(feeDenominator).mul(_totalFee);
 
        _gonBalances[soulGraveyard] = _gonBalances[soulGraveyard].add(gonAmount.div(feeDenominator).mul(soulGraveyardFee));
        _gonBalances[address(this)] = _gonBalances[address(this)].add(gonAmount.div(feeDenominator).mul(_treasuryFee.add(gainosInsuranceFund)));
        _gonBalances[autoLiquidityReceiver] = _gonBalances[autoLiquidityReceiver].add(gonAmount.div(feeDenominator).mul(liquidityFee));
 
        emit Transfer(sender, address(this), feeAmount.div(_gonsPerFragment));
        return gonAmount.sub(feeAmount);
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
                autoLiquidityReceiver,
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
 
        uint256 amountETHToTreasuryAndGIF = address(this).balance.sub(balanceBefore);
 
        (bool success, ) = payable(treasuryReceiver).call{
            value: amountETHToTreasuryAndGIF.mul(treasuryFee).div(treasuryFee.add(gainosInsuranceFund)),
            gas: 30000
        }("");
        (success, ) = payable(gainosInsuranceFundReceiver).call{
            value: amountETHToTreasuryAndGIF.mul(gainosInsuranceFund).div(treasuryFee.add(gainosInsuranceFund)),
            gas: 30000
        }("");
    }
 
 
    function shouldSnap() internal view returns (bool) {
        return _autoSnap && (_totalSupply < MAX_SUPPLY) && msg.sender != pair && !inSwap && nextSnap < block.timestamp;
    }
 
    function shouldAddLiquidity() internal view returns (bool) {
        return  _autoAddLiquidity && !inSwap && msg.sender != pair && block.timestamp >= (_lastAddLiquidityTime + 2 days);
    }
 
    function shouldSwapBack() internal view returns (bool) {
        return !inSwap && msg.sender != pair;
    }
 
    function setNextSnap(uint256 _nextSnap) external onlyOwner {
        nextSnap = _nextSnap;
    }
 
    function setSideNames(string memory _sideAName, string memory _sideBName) external onlyOwner {
        sideA = _sideAName;
        sideB = _sideBName;
    }
 
    function setAutoSnap(bool _flag) external onlyOwner {
        if (_flag) {
            _autoSnap = _flag;
            _lastSnappedTime = block.timestamp;
        } else {
            _autoSnap = _flag;
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
 
    function allowance(address owner_, address spender) external view override returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }
 
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }
 
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool)
    {
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }
 
    function approve(address spender, uint256 value) external override returns (bool)
    {
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
 
    function manualSync() external {
        IUniswapV2Pair(pair).sync();
    }
 
    function getLiquidityBacking(uint256 accuracy) public view returns (uint256)
    {
        uint256 liquidityBalance = _gonBalances[pair].div(_gonsPerFragment);
        return accuracy.mul(liquidityBalance.mul(2)).div(getCirculatingSupply());
    }
 
    function setWhitelist(address _addr) external onlyOwner {
        _isFeeExempt[_addr] = true;
    }
 
    // single use
    function setBotBlacklist(address _botAddress, bool _flag) external onlyOwner
    {
        require(isContract(_botAddress), "only contract address, externally owned accounts not allowed ");
        blacklist[_botAddress] = _flag;
    }
 
    // multi use
    function blockBots(address[] memory bots_) external onlyOwner {
        for (uint256 i = 0; i < bots_.length; i++) {
            blacklist[bots_[i]] = true;
        }
    }
 
    function unblockBot(address notbot) external onlyOwner {
        blacklist[notbot] = false;
    }
 
    function setPairAddress(address _pairAddress) public onlyOwner {
        pairAddress = _pairAddress;
    }
 
    function setPairContract(address _address) external onlyOwner {
        pairContract = IUniswapV2Pair(_address);
    }
 
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
 
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
 
    //Set maximum transaction
    function setMaxTxnAmount(uint256 maxTxAmount) public onlyOwner {
        _maxTxAmount = maxTxAmount * 10**DECIMALS;
    }
 
    function setMaxWalletSize(uint256 maxWalletSize) public onlyOwner {
        _maxWalletSize = maxWalletSize * 10**DECIMALS;
    }
 
    function setTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
    }
 
    receive() external payable {}
}