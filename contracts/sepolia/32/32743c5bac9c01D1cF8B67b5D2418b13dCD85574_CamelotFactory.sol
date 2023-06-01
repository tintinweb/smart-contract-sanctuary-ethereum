pragma solidity =0.5.16;

import "./interfaces/CamelotFactory/ICamelotFactory.sol";
import "./CamelotPair.sol";

contract CamelotFactory is ICamelotFactory {
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(CamelotPair).creationCode));
    address public owner;
    address public feePercentOwner;
    address public setStableOwner;
    address public feeTo;

    //uint public constant FEE_DENOMINATOR = 100000;
    uint public constant OWNER_FEE_SHARE_MAX = 100000; // 100%
    uint public ownerFeeShare = 50000; // default value = 50%

    uint public constant REFERER_FEE_SHARE_MAX = 20000; // 20%
    mapping(address => uint) public referrersFeeShare; // fees are taken from the user input

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event FeeToTransferred(address indexed prevFeeTo, address indexed newFeeTo);
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint length
    );
    event OwnerFeeShareUpdated(uint prevOwnerFeeShare, uint ownerFeeShare);
    event OwnershipTransferred(
        address indexed prevOwner,
        address indexed newOwner
    );
    event FeePercentOwnershipTransferred(
        address indexed prevOwner,
        address indexed newOwner
    );
    event SetStableOwnershipTransferred(
        address indexed prevOwner,
        address indexed newOwner
    );
    event ReferrerFeeShareUpdated(
        address referrer,
        uint prevReferrerFeeShare,
        uint referrerFeeShare
    );

    constructor(address feeTo_) public {
        owner = msg.sender;
        feePercentOwner = msg.sender;
        setStableOwner = msg.sender;
        feeTo = feeTo_;

        emit OwnershipTransferred(address(0), msg.sender);
        emit FeePercentOwnershipTransferred(address(0), msg.sender);
        emit SetStableOwnershipTransferred(address(0), msg.sender);
        emit FeeToTransferred(address(0), feeTo_);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "CamelotFactory: caller is not the owner");
        _;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair)
    {
        require(tokenA != tokenB, "CamelotFactory: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "CamelotFactory: ZERO_ADDRESS");
        require(
            getPair[token0][token1] == address(0),
            "CamelotFactory: PAIR_EXISTS"
        ); // single check is sufficient
        bytes memory bytecode = type(CamelotPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        require(pair != address(0), "CamelotFactory: FAILED");
        CamelotPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setOwner(address _owner) external onlyOwner {
        require(_owner != address(0), "CamelotFactory: zero address");
        emit OwnershipTransferred(owner, _owner);
        owner = _owner;
    }

    function setFeePercentOwner(address _feePercentOwner) external onlyOwner {
        require(_feePercentOwner != address(0), "CamelotFactory: zero address");
        emit FeePercentOwnershipTransferred(feePercentOwner, _feePercentOwner);
        feePercentOwner = _feePercentOwner;
    }

    function setSetStableOwner(address _setStableOwner) external {
        require(
            msg.sender == setStableOwner,
            "CamelotFactory: not setStableOwner"
        );
        require(_setStableOwner != address(0), "CamelotFactory: zero address");
        emit SetStableOwnershipTransferred(setStableOwner, _setStableOwner);
        setStableOwner = _setStableOwner;
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        emit FeeToTransferred(feeTo, _feeTo);
        feeTo = _feeTo;
    }

    /**
     * @dev Updates the share of fees attributed to the owner
     *
     * Must only be called by owner
     */
    function setOwnerFeeShare(uint newOwnerFeeShare) external onlyOwner {
        require(
            newOwnerFeeShare > 0,
            "CamelotFactory: ownerFeeShare mustn't exceed minimum"
        );
        require(
            newOwnerFeeShare <= OWNER_FEE_SHARE_MAX,
            "CamelotFactory: ownerFeeShare mustn't exceed maximum"
        );
        emit OwnerFeeShareUpdated(ownerFeeShare, newOwnerFeeShare);
        ownerFeeShare = newOwnerFeeShare;
    }

    /**
     * @dev Updates the share of fees attributed to the given referrer when a swap went through him
     *
     * Must only be called by owner
     */
    function setReferrerFeeShare(address referrer, uint referrerFeeShare)
        external
        onlyOwner
    {
        require(referrer != address(0), "CamelotFactory: zero address");
        require(
            referrerFeeShare <= REFERER_FEE_SHARE_MAX,
            "CamelotFactory: referrerFeeShare mustn't exceed maximum"
        );
        emit ReferrerFeeShareUpdated(
            referrer,
            referrersFeeShare[referrer],
            referrerFeeShare
        );
        referrersFeeShare[referrer] = referrerFeeShare;
    }

    function feeInfo()
        external
        view
        returns (uint _ownerFeeShare, address _feeTo)
    {
        _ownerFeeShare = ownerFeeShare;
        _feeTo = feeTo;
    }
}

pragma solidity =0.5.16;

import './interfaces/CamelotFactory/ICamelotPair.sol';
import './UniswapV2ERC20.sol';
import './libraries/CamelotFactory/Math.sol';
import './interfaces/CamelotFactory/IERC20.sol';
import './interfaces/CamelotFactory/ICamelotFactory.sol';
import './interfaces/CamelotFactory/IUniswapV2Callee.sol';

contract CamelotPair is ICamelotPair, UniswapV2ERC20 {
 using SafeMath for uint;

 uint public constant MINIMUM_LIQUIDITY = 10 ** 3;
 bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

 address public factory;
 address public token0;
 address public token1;

 bool public initialized;

 uint public constant FEE_DENOMINATOR = 100000;
 uint public constant MAX_FEE_PERCENT = 2000; // = 2%

 uint112 private reserve0; // uses single storage slot, accessible via getReserves
 uint112 private reserve1; // uses single storage slot, accessible via getReserves
 uint16 public token0FeePercent = 300; // default = 0.3% // uses single storage slot, accessible via getReserves
 uint16 public token1FeePercent = 300; // default = 0.3% // uses single storage slot, accessible via getReserves

 uint public precisionMultiplier0;
 uint public precisionMultiplier1;

 uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

 bool public stableSwap; // if set to true, defines pair type as stable
 bool public pairTypeImmutable; // if set to true, stableSwap states cannot be updated anymore

 uint private unlocked = 1;
 modifier lock() {
 require(unlocked == 1, 'CamelotPair: LOCKED');
 unlocked = 0;
 _;
 unlocked = 1;
 }

 function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint16 _token0FeePercent, uint16 _token1FeePercent) {
 _reserve0 = reserve0;
 _reserve1 = reserve1;
 _token0FeePercent = token0FeePercent;
 _token1FeePercent = token1FeePercent;
 }

 function _safeTransfer(address token, address to, uint value) private {
 (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
 require(success && (data.length == 0 || abi.decode(data, (bool))), 'CamelotPair: TRANSFER_FAILED');
 }

 event DrainWrongToken(address indexed token, address to);
 event FeePercentUpdated(uint16 token0FeePercent, uint16 token1FeePercent);
 event SetStableSwap(bool prevStableSwap, bool stableSwap);
 event SetPairTypeImmutable();
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
 event Skim();

 constructor() public {
 factory = msg.sender;
 }

 // called once by the factory at time of deployment
 function initialize(address _token0, address _token1) external {
 require(msg.sender == factory && !initialized, 'CamelotPair: FORBIDDEN');
 // sufficient check
 token0 = _token0;
 token1 = _token1;

 precisionMultiplier0 = 10 ** uint(IERC20(_token0).decimals());
 precisionMultiplier1 = 10 ** uint(IERC20(_token1).decimals());

 initialized = true;
 }

 /**
 * @dev Updates the swap fees percent
 *
 * Can only be called by the factory's feeAmountOwner
 */
 function setFeePercent(uint16 newToken0FeePercent, uint16 newToken1FeePercent) external lock {
 require(msg.sender == ICamelotFactory(factory).feePercentOwner(), "CamelotPair: only factory's feeAmountOwner");
 require(newToken0FeePercent <= MAX_FEE_PERCENT && newToken1FeePercent <= MAX_FEE_PERCENT, "CamelotPair: feePercent mustn't exceed the maximum");
 require(newToken0FeePercent > 0 && newToken1FeePercent > 0, "CamelotPair: feePercent mustn't exceed the minimum");
 token0FeePercent = newToken0FeePercent;
 token1FeePercent = newToken1FeePercent;
 emit FeePercentUpdated(newToken0FeePercent, newToken1FeePercent);
 }

 function setStableSwap(bool stable, uint112 expectedReserve0, uint112 expectedReserve1) external lock {
 require(msg.sender == ICamelotFactory(factory).setStableOwner(), "CamelotPair: only factory's setStableOwner");
 require(!pairTypeImmutable, "CamelotPair: immutable");

 require(stable != stableSwap, "CamelotPair: no update");
 require(expectedReserve0 == reserve0 && expectedReserve1 == reserve1, "CamelotPair: failed");

 bool feeOn = _mintFee(reserve0, reserve1);

 emit SetStableSwap(stableSwap, stable);
 stableSwap = stable;
 kLast = (stable && feeOn) ? _k(uint(reserve0), uint(reserve1)) : 0;
 }

 function setPairTypeImmutable() external lock {
 require(msg.sender == ICamelotFactory(factory).owner(), "CamelotPair: only factory's owner");
 require(!pairTypeImmutable, "CamelotPair: already immutable");

 pairTypeImmutable = true;
 emit SetPairTypeImmutable();
 }

 // update reserves
 function _update(uint balance0, uint balance1) private {
 require(balance0 <= uint112(- 1) && balance1 <= uint112(- 1), 'CamelotPair: OVERFLOW');

 reserve0 = uint112(balance0);
 reserve1 = uint112(balance1);
 emit Sync(uint112(balance0), uint112(balance1));
 }

 // if fee is on, mint liquidity equivalent to "factory.ownerFeeShare()" of the growth in sqrt(k)
 // only for uni configuration
 function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
 if(stableSwap) return false;

 (uint ownerFeeShare, address feeTo) = ICamelotFactory(factory).feeInfo();
 feeOn = feeTo != address(0);
 uint _kLast = kLast;
 // gas savings
 if (feeOn) {
 if (_kLast != 0) {
 uint rootK = Math.sqrt(_k(uint(_reserve0), uint(_reserve1)));
 uint rootKLast = Math.sqrt(_kLast);
 if (rootK > rootKLast) {
 uint d = (FEE_DENOMINATOR.mul(100) / ownerFeeShare).sub(100);
 uint numerator = totalSupply.mul(rootK.sub(rootKLast)).mul(100);
 uint denominator = rootK.mul(d).add(rootKLast.mul(100));
 uint liquidity = numerator / denominator;
 if (liquidity > 0) _mint(feeTo, liquidity);
 }
 }
 } else if (_kLast != 0) {
 kLast = 0;
 }
 }

 // this low-level function should be called from a contract which performs important safety checks
 function mint(address to) external lock returns (uint liquidity) {
 (uint112 _reserve0, uint112 _reserve1,,) = getReserves();
 // gas savings
 uint balance0 = IERC20(token0).balanceOf(address(this));
 uint balance1 = IERC20(token1).balanceOf(address(this));
 uint amount0 = balance0.sub(_reserve0);
 uint amount1 = balance1.sub(_reserve1);

 bool feeOn = _mintFee(_reserve0, _reserve1);
 uint _totalSupply = totalSupply;
 // gas savings, must be defined here since totalSupply can update in _mintFee
 if (_totalSupply == 0) {
 liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
 _mint(address(0), MINIMUM_LIQUIDITY);
 // permanently lock the first MINIMUM_LIQUIDITY tokens
 } else {
 liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
 }
 require(liquidity > 0, 'CamelotPair: INSUFFICIENT_LIQUIDITY_MINTED');
 _mint(to, liquidity);

 _update(balance0, balance1);
 if (feeOn) kLast = _k(uint(reserve0), uint(reserve1));
 // reserve0 and reserve1 are up-to-date
 emit Mint(msg.sender, amount0, amount1);
 }

 // this low-level function should be called from a contract which performs important safety checks
 function burn(address to) external lock returns (uint amount0, uint amount1) {
 (uint112 _reserve0, uint112 _reserve1,,) = getReserves(); // gas savings
 address _token0 = token0; // gas savings
 address _token1 = token1; // gas savings
 uint balance0 = IERC20(_token0).balanceOf(address(this));
 uint balance1 = IERC20(_token1).balanceOf(address(this));
 uint liquidity = balanceOf[address(this)];

 bool feeOn = _mintFee(_reserve0, _reserve1);
 uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
 amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
 amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
 require(amount0 > 0 && amount1 > 0, 'CamelotPair: INSUFFICIENT_LIQUIDITY_BURNED');
 _burn(address(this), liquidity);
 _safeTransfer(_token0, to, amount0);
 _safeTransfer(_token1, to, amount1);
 balance0 = IERC20(_token0).balanceOf(address(this));
 balance1 = IERC20(_token1).balanceOf(address(this));

 _update(balance0, balance1);
 if (feeOn) kLast = _k(uint(reserve0), uint(reserve1)); // reserve0 and reserve1 are up-to-date
 emit Burn(msg.sender, amount0, amount1, to);
 }

 struct TokensData {
 address token0;
 address token1;
 uint amount0Out;
 uint amount1Out;
 uint balance0;
 uint balance1;
 uint remainingFee0;
 uint remainingFee1;
 }

 // this low-level function should be called from a contract which performs important safety checks
 function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external {
 TokensData memory tokensData = TokensData({
 token0: token0,
 token1: token1,
 amount0Out: amount0Out,
 amount1Out: amount1Out,
 balance0: 0,
 balance1: 0,
 remainingFee0: 0,
 remainingFee1: 0
 });
 _swap(tokensData, to, data, address(0));
 }

 // this low-level function should be called from a contract which performs important safety checks
 function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data, address referrer) external {
 TokensData memory tokensData = TokensData({
 token0: token0,
 token1: token1,
  amount0Out: amount0Out,
 amount1Out: amount1Out,
 balance0: 0,
 balance1: 0,
 remainingFee0: 0,
 remainingFee1: 0
 });
 _swap(tokensData, to, data, referrer);
 }


 function _swap(TokensData memory tokensData, address to, bytes memory data, address referrer) internal lock {
 require(tokensData.amount0Out > 0 || tokensData.amount1Out > 0, 'CamelotPair: INSUFFICIENT_OUTPUT_AMOUNT');

 (uint112 _reserve0, uint112 _reserve1, uint16 _token0FeePercent, uint16 _token1FeePercent) = getReserves();
 require(tokensData.amount0Out < _reserve0 && tokensData.amount1Out < _reserve1, 'CamelotPair: INSUFFICIENT_LIQUIDITY');


 {
 require(to != tokensData.token0 && to != tokensData.token1, 'CamelotPair: INVALID_TO');
 // optimistically transfer tokens
 if (tokensData.amount0Out > 0) _safeTransfer(tokensData.token0, to, tokensData.amount0Out);
 // optimistically transfer tokens
 if (tokensData.amount1Out > 0) _safeTransfer(tokensData.token1, to, tokensData.amount1Out);
 if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, tokensData.amount0Out, tokensData.amount1Out, data);
 tokensData.balance0 = IERC20(tokensData.token0).balanceOf(address(this));
 tokensData.balance1 = IERC20(tokensData.token1).balanceOf(address(this));
 }

 uint amount0In = tokensData.balance0 > _reserve0 - tokensData.amount0Out ? tokensData.balance0 - (_reserve0 - tokensData.amount0Out) : 0;
 uint amount1In = tokensData.balance1 > _reserve1 - tokensData.amount1Out ? tokensData.balance1 - (_reserve1 - tokensData.amount1Out) : 0;
 require(amount0In > 0 || amount1In > 0, 'CamelotPair: INSUFFICIENT_INPUT_AMOUNT');

 tokensData.remainingFee0 = amount0In.mul(_token0FeePercent) / FEE_DENOMINATOR;
 tokensData.remainingFee1 = amount1In.mul(_token1FeePercent) / FEE_DENOMINATOR;

 {// scope for referer/stable fees management
 uint fee = 0;

 uint referrerInputFeeShare = referrer != address(0) ? ICamelotFactory(factory).referrersFeeShare(referrer) : 0;
 if (referrerInputFeeShare > 0) {
 if (amount0In > 0) {
 fee = amount0In.mul(referrerInputFeeShare).mul(_token0FeePercent) / (FEE_DENOMINATOR ** 2);
 tokensData.remainingFee0 = tokensData.remainingFee0.sub(fee);
 _safeTransfer(tokensData.token0, referrer, fee);
 }
 if (amount1In > 0) {
 fee = amount1In.mul(referrerInputFeeShare).mul(_token1FeePercent) / (FEE_DENOMINATOR ** 2);
 tokensData.remainingFee1 = tokensData.remainingFee1.sub(fee);
 _safeTransfer(tokensData.token1, referrer, fee);
 }
 }

 if(stableSwap){
 (uint ownerFeeShare, address feeTo) = ICamelotFactory(factory).feeInfo();
 if(feeTo != address(0)) {
 ownerFeeShare = FEE_DENOMINATOR.sub(referrerInputFeeShare).mul(ownerFeeShare);
 if (amount0In > 0) {
 fee = amount0In.mul(ownerFeeShare).mul(_token0FeePercent) / (FEE_DENOMINATOR ** 3);
 tokensData.remainingFee0 = tokensData.remainingFee0.sub(fee);
 _safeTransfer(tokensData.token0, feeTo, fee);
 }
 if (amount1In > 0) {
 fee = amount1In.mul(ownerFeeShare).mul(_token1FeePercent) / (FEE_DENOMINATOR ** 3);
 tokensData.remainingFee1 = tokensData.remainingFee1.sub(fee);
 _safeTransfer(tokensData.token1, feeTo, fee);
 }
 }
 }
 // readjust tokens balance
 if (amount0In > 0) tokensData.balance0 = IERC20(tokensData.token0).balanceOf(address(this));
 if (amount1In > 0) tokensData.balance1 = IERC20(tokensData.token1).balanceOf(address(this));
 }
 {// scope for reserve{0,1}Adjusted, avoids stack too deep errors
 uint balance0Adjusted = tokensData.balance0.sub(tokensData.remainingFee0);
 uint balance1Adjusted = tokensData.balance1.sub(tokensData.remainingFee1);
 require(_k(balance0Adjusted, balance1Adjusted) >= _k(uint(_reserve0), uint(_reserve1)), 'CamelotPair: K');
 }
 _update(tokensData.balance0, tokensData.balance1);
 emit Swap(msg.sender, amount0In, amount1In, tokensData.amount0Out, tokensData.amount1Out, to);
 }

 function _k(uint balance0, uint balance1) internal view returns (uint) {
 if (stableSwap) {
 uint _x = balance0.mul(1e18) / precisionMultiplier0;
 uint _y = balance1.mul(1e18) / precisionMultiplier1;
 uint _a = (_x.mul(_y)) / 1e18;
 uint _b = (_x.mul(_x) / 1e18).add(_y.mul(_y) / 1e18);
 return _a.mul(_b) / 1e18; // x3y+y3x >= k
 }
 return balance0.mul(balance1);
 }

 function _get_y(uint x0, uint xy, uint y) internal pure returns (uint) {
 for (uint i = 0; i < 255; i++) {
 uint y_prev = y;
 uint k = _f(x0, y);
 if (k < xy) {
 uint dy = (xy - k) * 1e18 / _d(x0, y);
 y = y + dy;
 } else {
 uint dy = (k - xy) * 1e18 / _d(x0, y);
 y = y - dy;
 }
 if (y > y_prev) {
 if (y - y_prev <= 1) {
 return y;
 }
 } else {
 if (y_prev - y <= 1) {
 return y;
 }
 }
 }
 return y;
 }

 function _f(uint x0, uint y) internal pure returns (uint) {
 return x0 * (y * y / 1e18 * y / 1e18) / 1e18 + (x0 * x0 / 1e18 * x0 / 1e18) * y / 1e18;
 }

 function _d(uint x0, uint y) internal pure returns (uint) {
 return 3 * x0 * (y * y / 1e18) / 1e18 + (x0 * x0 / 1e18 * x0 / 1e18);
 }

 function getAmountOut(uint amountIn, address tokenIn) external view returns (uint) {
 uint16 feePercent = tokenIn == token0 ? token0FeePercent : token1FeePercent;
 return _getAmountOut(amountIn, tokenIn, uint(reserve0), uint(reserve1), feePercent);
 }

 function _getAmountOut(uint amountIn, address tokenIn, uint _reserve0, uint _reserve1, uint feePercent) internal view returns (uint) {
 if (stableSwap) {
 amountIn = amountIn.sub(amountIn.mul(feePercent) / FEE_DENOMINATOR); // remove fee from amount received
 uint xy = _k(_reserve0, _reserve1);
 _reserve0 = _reserve0 * 1e18 / precisionMultiplier0;
 _reserve1 = _reserve1 * 1e18 / precisionMultiplier1;

 (uint reserveA, uint reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
 amountIn = tokenIn == token0 ? amountIn * 1e18 / precisionMultiplier0 : amountIn * 1e18 / precisionMultiplier1;
 uint y = reserveB - _get_y(amountIn + reserveA, xy, reserveB);
 return y * (tokenIn == token0 ? precisionMultiplier1 : precisionMultiplier0) / 1e18;

 } else {
 (uint reserveA, uint reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
 amountIn = amountIn.mul(FEE_DENOMINATOR.sub(feePercent));
 return (amountIn.mul(reserveB)) / (reserveA.mul(FEE_DENOMINATOR).add(amountIn));
 }
 }

 // force balances to match reserves
 function skim(address to) external lock {
 address _token0 = token0;
 // gas savings
 address _token1 = token1;
 // gas savings
 _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
 _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
 emit Skim();
 }

 // force reserves to match balances
 function sync() external lock {
 uint token0Balance = IERC20(token0).balanceOf(address(this));
 uint token1Balance = IERC20(token1).balanceOf(address(this));
 require(token0Balance != 0 && token1Balance != 0, "CamelotPair: liquidity ratio not initialized");
 _update(token0Balance, token1Balance);
 }

 /**
 * @dev Allow to recover token sent here by mistake
 *
 * Can only be called by factory's owner
 */
 function drainWrongToken(address token, address to) external lock {
 require(msg.sender == ICamelotFactory(factory).owner(), "CamelotPair: only factory's owner");
 require(token != token0 && token != token1, "CamelotPair: invalid token");
 _safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
 emit DrainWrongToken(token, to);
 }
}

pragma solidity >=0.5.0;

interface ICamelotFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function owner() external view returns (address);
    function feePercentOwner() external view returns (address);
    function setStableOwner() external view returns (address);
    function feeTo() external view returns (address);

    function ownerFeeShare() external view returns (uint256);
    function referrersFeeShare(address) external view returns (uint256);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function feeInfo() external view returns (uint _ownerFeeShare, address _feeTo);
}

pragma solidity >=0.5.0;

interface ICamelotPair {
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
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint16 token0feePercent, uint16 token1FeePercent);
    function getAmountOut(uint amountIn, address tokenIn) external view returns (uint);
    function kLast() external view returns (uint);

    function setFeePercent(uint16 token0FeePercent, uint16 token1FeePercent) external;
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data, address referrer) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

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

pragma solidity >=0.5.0;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2ERC20 {
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
}

pragma solidity =0.5.16;

// a library for performing various math operations

library Math {
 function min(uint x, uint y) internal pure returns (uint z) {
 z = x < y ? x : y;
 }

 // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
 function sqrt(uint y) internal pure returns (uint z) {
 if (y > 3) {
 z = y;
 uint x = y / 2 + 1;
 while (x < z) {
 z = x;
 x = (y / x + x) / 2;
 }
 } else if (y != 0) {
 z = 1;
 }
 }
}

pragma solidity =0.5.16;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

pragma solidity =0.5.16;

import './interfaces/CamelotFactory/IUniswapV2ERC20.sol';
import './libraries/CamelotFactory/SafeMath.sol';

contract UniswapV2ERC20 is IUniswapV2ERC20 {
 using SafeMath for uint;

 string public constant name = 'Camelot LP';
 string public constant symbol = 'CMLT-LP';
 uint8 public constant decimals = 18;
 uint public totalSupply;
 mapping(address => uint) public balanceOf;
 mapping(address => mapping(address => uint)) public allowance;

 bytes32 public DOMAIN_SEPARATOR;
 // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
 bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
 mapping(address => uint) public nonces;

 event Approval(address indexed owner, address indexed spender, uint value);
 event Transfer(address indexed from, address indexed to, uint value);

 constructor() public {
 uint chainId;
 assembly {
 chainId := chainid
 }
 DOMAIN_SEPARATOR = keccak256(
 abi.encode(
 keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
 keccak256(bytes(name)),
 keccak256(bytes('1')),
 chainId,
 address(this)
 )
 );
 }

 function _mint(address to, uint value) internal {
 totalSupply = totalSupply.add(value);
 balanceOf[to] = balanceOf[to].add(value);
 emit Transfer(address(0), to, value);
 }

 function _burn(address from, uint value) internal {
 balanceOf[from] = balanceOf[from].sub(value);
 totalSupply = totalSupply.sub(value);
 emit Transfer(from, address(0), value);
 }

 function _approve(address owner, address spender, uint value) private {
 allowance[owner][spender] = value;
 emit Approval(owner, spender, value);
 }

 function _transfer(address from, address to, uint value) private {
 balanceOf[from] = balanceOf[from].sub(value);
 balanceOf[to] = balanceOf[to].add(value);
 emit Transfer(from, to, value);
 }

 function approve(address spender, uint value) external returns (bool) {
 _approve(msg.sender, spender, value);
 return true;
 }

 function transfer(address to, uint value) external returns (bool) {
 _transfer(msg.sender, to, value);
 return true;
 }

 function transferFrom(address from, address to, uint value) external returns (bool) {
 if (allowance[from][msg.sender] != uint(-1)) {
 uint remaining = allowance[from][msg.sender].sub(value);
 allowance[from][msg.sender] = remaining;
 emit Approval(from, msg.sender, remaining);
 }
 _transfer(from, to, value);
 return true;
 }

 function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
 require(deadline >= block.timestamp, 'UniswapV2: EXPIRED');
 bytes32 digest = keccak256(
 abi.encodePacked(
 '\x19\x01',
 DOMAIN_SEPARATOR,
 keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
 )
 );
 address recoveredAddress = ecrecover(digest, v, r, s);
 require(recoveredAddress != address(0) && recoveredAddress == owner, 'UniswapV2: INVALID_SIGNATURE');
 _approve(owner, spender, value);
 }
}