pragma solidity =0.5.16;

import "./interfaces/IBrewlabsFactory.sol";
import "./interfaces/IBrewlabsSwapFeeManager.sol";
import "./BrewlabsPair.sol";

contract BrewlabsFactory is IBrewlabsFactory {
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(BrewlabsPair).creationCode));
    address public owner;
    address public feePercentOwner;
    address public setStableOwner;
    address public feeTo;
    address public feeManager;

    uint256 public constant MAX_OWNER_FEE = 1000000; // 100%
    uint256 public ownerFee = 1000000; // default value = 100%

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint256 length);
    event FeeToTransferred(address indexed prevFeeTo, address indexed newFeeTo);
    event FeeManagerChanged(address indexed prevFeeMgr, address indexed newFeeMgr);
    event FeePercentOwnershipTransferred(address indexed prevOwner, address indexed newOwner);
    event OwnerFeeUpdated(uint256 prevOwnerFee, uint256 ownerFee);
    event OwnershipTransferred(address indexed prevOwner, address indexed newOwner);
    event SetStableOwnershipTransferred(address indexed prevOwner, address indexed newOwner);

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
        require(owner == msg.sender, "Brewlabs: caller is not the owner");
        _;
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, "Brewlabs: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "Brewlabs: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "Brewlabs: PAIR_EXISTS"); // single check is sufficient
        bytes memory bytecode = type(BrewlabsPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        require(pair != address(0), "Brewlabs: FAILED");
        BrewlabsPair(pair).initialize(token0, token1);
        if (feeManager != address(0)) {
            IBrewlabsSwapFeeManager(feeManager).createPool(token0, token1);
        }
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setOwner(address _owner) external onlyOwner {
        require(_owner != address(0), "Brewlabs: zero address");
        emit OwnershipTransferred(owner, _owner);
        owner = _owner;
    }

    function setFeePercentOwner(address _feePercentOwner) external onlyOwner {
        require(_feePercentOwner != address(0), "Brewlabs: zero address");
        emit FeePercentOwnershipTransferred(feePercentOwner, _feePercentOwner);
        feePercentOwner = _feePercentOwner;
    }

    function setSetStableOwner(address _setStableOwner) external {
        require(msg.sender == setStableOwner, "Brewlabs: not setStableOwner");
        require(_setStableOwner != address(0), "Brewlabs: zero address");
        emit SetStableOwnershipTransferred(setStableOwner, _setStableOwner);
        setStableOwner = _setStableOwner;
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        require(_feeTo != address(0), "Brewlabs: zero address");
        emit FeeToTransferred(feeTo, _feeTo);
        feeTo = _feeTo;
    }

    function setFeeManager(address _feeManager) external onlyOwner {
        feeManager = _feeManager;
        emit FeeManagerChanged(feeManager, _feeManager);
    }
    /**
     * @dev Updates the share of fees attributed to the owner
     *
     * Must only be called by owner
     */

    function setOwnerFee(uint256 newOwnerFee) external onlyOwner {
        require(newOwnerFee > 0, "Brewlabs: ownerFee mustn't exceed minimum");
        require(newOwnerFee <= MAX_OWNER_FEE, "Brewlabs: ownerFee mustn't exceed maximum");
        emit OwnerFeeUpdated(ownerFee, newOwnerFee);
        ownerFee = newOwnerFee;
    }

    function feeInfo() external view returns (uint256, address) {
        return (ownerFee, feeTo);
    }
}

pragma solidity =0.5.16;

import "./interfaces/IBrewlabsERC20.sol";
import "./libraries/SafeMath.sol";

contract BrewlabsERC20 is IBrewlabsERC20 {
    using SafeMath for uint256;

    string public constant name = "Brewswap LP";
    string public constant symbol = "BREWSWAP-LP";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        if (allowance[from][msg.sender] != uint256(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
    {
        require(deadline >= block.timestamp, "Brewlabs: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "Brewlabs: INVALID_SIGNATURE");
        _approve(owner, spender, value);
    }
}

pragma solidity =0.5.16;

import "./interfaces/IBrewlabsPair.sol";
import "./interfaces/IBrewlabsSwapFeeManager.sol";
import "./BrewlabsERC20.sol";
import "./libraries/Math.sol";
import "./libraries/SafeMath.sol";
import "./libraries/UQ112x112.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IBrewlabsFactory.sol";
import "./interfaces/IBrewlabsCallee.sol";

contract BrewlabsPair is IBrewlabsPair, BrewlabsERC20 {
    using SafeMath for uint256;
    using UQ112x112 for uint224;

    uint256 public constant MINIMUM_LIQUIDITY = 10 ** 3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));

    address public factory;
    address public token0;
    address public token1;
    address public stakingPool;

    bool public initialized;

    uint256 public constant FEE_DENOMINATOR = 1000000;
    uint256 public constant DISCOUNT_MAX = 10000;
    uint256 public constant MAX_FEE_PERCENT = 20000; // = 2%

    uint16 public feePercent = 3000; // default = 0.3%  // uses single storage slot, accessible via getReserves

    uint256 public precisionMultiplier0;
    uint256 public precisionMultiplier1;

    uint112 private reserve0; // uses single storage slot, accessible via getReserves
    uint112 private reserve1; // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint256 public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    bool public stableSwap; // if set to true, defines pair type as stable
    bool public pairTypeImmutable; // if set to true, stableSwap states cannot be updated anymore

    uint256 private unlocked = 1;

    struct SwapFeeConstraint {
        uint256 realFee;
        uint256 operationFee;
        uint256 remainingFee;
    }

    modifier lock() {
        require(unlocked == 1, "Brewlabs: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves()
        public
        view
        returns (uint112 _reserve0, uint112 _reserve1, uint16 _feePercent, uint32 _blockTimestampLast)
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _feePercent = feePercent;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "Brewlabs: TRANSFER_FAILED");
    }

    event RescueWrongToken(address indexed token, address to);
    event SetFeePercent(uint16 feePercent);
    event SetStableSwap(bool prevStableSwap, bool stableSwap);
    event SetPairTypeImmutable();
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
    event Skim();

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory && !initialized, "Brewlabs: FORBIDDEN");
        // sufficient check
        token0 = _token0;
        token1 = _token1;

        precisionMultiplier0 = 10 ** uint256(IERC20(_token0).decimals());
        precisionMultiplier1 = 10 ** uint256(IERC20(_token1).decimals());

        initialized = true;
    }

    // update reserves
    function _update(uint256 balance0, uint256 balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), "Brewlabs: OVERFLOW");
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(uint112(balance0), uint112(balance1));
    }

    // if fee is on, mint liquidity equivalent to "factory.ownerFee()" of the growth in sqrt(k)
    // only for uni configuration
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        (uint256 ownerFee, address feeTo) = IBrewlabsFactory(factory).feeInfo();
        feeOn = feeTo != address(0);
        uint256 _kLast = kLast;
        // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(_k(uint256(_reserve0), uint256(_reserve1)));
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 d = (FEE_DENOMINATOR.mul(100) / ownerFee).sub(100);
                    uint256 numerator = totalSupply.mul(rootK.sub(rootKLast)).mul(100);
                    uint256 denominator = rootK.mul(d).add(rootKLast.mul(100));
                    uint256 liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    function _transfer(address from, address to, uint256 value) internal {
        super._transfer(from, to, value);

        address feeMgr = IBrewlabsFactory(factory).feeManager();
        if (feeMgr != address(0x0)) {
            IBrewlabsSwapFeeManager(feeMgr).lpTransferred(from, to, token0, token1, address(this));
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1,,) = getReserves(); // gas savings
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0.sub(_reserve0);
        uint256 amount1 = balance1.sub(_reserve1);

        _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY);
            // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, "Brewlabs: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        address feeMgr = IBrewlabsFactory(factory).feeManager();
        if (feeMgr != address(0x0)) {
            IBrewlabsSwapFeeManager(feeMgr).lpMinted(to, token0, token1, address(this));
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        kLast = _k(uint256(reserve0), uint256(reserve1));
        // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint256 amount0, uint256 amount1) {
        (uint112 _reserve0, uint112 _reserve1,,) = getReserves(); // gas savings
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];

        _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, "Brewlabs: INSUFFICIENT_LIQUIDITY_BURNED");
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);

        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        address feeMgr = IBrewlabsFactory(factory).feeManager();
        if (feeMgr != address(0x0)) {
            IBrewlabsSwapFeeManager(feeMgr).lpBurned(to, token0, token1, address(this));
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        kLast = _k(uint256(reserve0), uint256(reserve1)); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint256 amount0Out, uint256 amount1Out, address to, uint256 discount, bytes calldata data) external {
        require(amount0Out > 0 || amount1Out > 0, "Brewlabs: INSUFFICIENT_OUTPUT_AMOUNT");
        require(to != token0 && to != token1, "Brewlabs: INVALID_TO");

        (uint112 _reserve0, uint112 _reserve1, uint16 _feePercent,) = getReserves();
        require(amount0Out < _reserve0 && amount1Out < _reserve1, "Brewlabs: INSUFFICIENT_LIQUIDITY");

        // optimistically transfer tokens
        if (amount0Out > 0) _safeTransfer(token0, to, amount0Out);
        if (amount1Out > 0) _safeTransfer(token1, to, amount1Out);
        if (data.length > 0) {
            IBrewlabsCallee(to).brewlabsCall(msg.sender, amount0Out, amount1Out, data);
        }
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 amount0In = balance0 > _reserve0 ? balance0 - _reserve0 : 0;
        uint256 amount1In = balance1 > _reserve1 ? balance1 - _reserve1 : 0;

        SwapFeeConstraint memory constraint;
        require(amount0In > 0 || amount1In > 0, "Brewlabs: INSUFFICIENT_INPUT_AMOUNT");
        {
            // scope for fee management
            constraint.realFee = uint256(_feePercent).mul(DISCOUNT_MAX.sub(discount)).div(DISCOUNT_MAX);
            (constraint.remainingFee, constraint.operationFee) =
                _distributeFees(amount0Out, amount1Out, constraint.realFee);
        }
        // readjust tokens balance
        if (amount0Out > 0) balance0 = IERC20(token0).balanceOf(address(this));
        if (amount1Out > 0) balance1 = IERC20(token1).balanceOf(address(this));
        {
            uint256 _amount0Out = amount0Out;
            uint256 _amount1Out = amount1Out;
            uint256 balance0Adjusted = balance0.mul(FEE_DENOMINATOR).sub(
                _amount0Out.mul(FEE_DENOMINATOR).div(FEE_DENOMINATOR - constraint.realFee).mul(constraint.realFee).mul(
                    constraint.remainingFee
                ).div(constraint.operationFee)
            );
            uint256 balance1Adjusted = balance1.mul(FEE_DENOMINATOR).sub(
                _amount1Out.mul(FEE_DENOMINATOR).div(FEE_DENOMINATOR - constraint.realFee).mul(constraint.realFee).mul(
                    constraint.remainingFee
                ).div(constraint.operationFee)
            );
            require(
                _k(balance0Adjusted, balance1Adjusted)
                    >= _k(uint256(_reserve0), uint256(_reserve1)).mul(FEE_DENOMINATOR ** 2),
                "Brewlabs: K"
            );
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        {
            // scope for _amountOut{0,1}, avoids stack too deep errors
            uint256 _amount0Out = amount0Out;
            uint256 _amount1Out = amount1Out;
            emit Swap(msg.sender, amount0In, amount1In, _amount0Out, _amount1Out, to);
        }
    }

    function _distributeFees(uint256 amount0Out, uint256 amount1Out, uint256 realFee)
        internal
        returns (uint256, uint256)
    {
        address feeMgr = IBrewlabsFactory(factory).feeManager();
        if (feeMgr == address(0)) return (0, 1);

        (uint256 operationFee,, uint256 brewlabsFee,, uint256 stakingFee,) =
            IBrewlabsSwapFeeManager(feeMgr).getFeeDistribution(address(this));
        uint256 remainingFee = brewlabsFee + stakingFee;
        uint256 fee = 0;
        {
            uint256 _amount0Out = amount0Out;
            if (_amount0Out > 0) {
                fee = _amount0Out.mul(operationFee.sub(remainingFee)).div(operationFee).mul(realFee)
                    / (FEE_DENOMINATOR - realFee);
                IERC20(token0).approve(feeMgr, fee);
                IBrewlabsSwapFeeManager(feeMgr).notifyRewardAmount(address(this), token0, fee);
                // staking fee distribution
                if (stakingFee > 0 && stakingPool != address(0)) {
                    fee = _amount0Out.mul(stakingFee).div(operationFee).mul(realFee) / (FEE_DENOMINATOR - realFee);
                    _safeTransfer(token0, stakingPool, fee);
                    remainingFee = remainingFee - stakingFee;
                }
            }
        }
        {
            uint256 _amount1Out = amount1Out;
            if (_amount1Out > 0) {
                fee = _amount1Out.mul(operationFee.sub(remainingFee)).div(operationFee).mul(realFee)
                    / (FEE_DENOMINATOR - realFee);
                IERC20(token1).approve(feeMgr, fee);
                IBrewlabsSwapFeeManager(feeMgr).notifyRewardAmount(address(this), token1, fee);
                // staking fee distribution
                if (stakingFee > 0 && stakingPool != address(0)) {
                    fee = _amount1Out.mul(stakingFee).div(operationFee).mul(realFee) / (FEE_DENOMINATOR - realFee);
                    _safeTransfer(token1, stakingPool, fee);
                    remainingFee = remainingFee - stakingFee;
                }
            }
        }
        return (remainingFee, operationFee);
    }

    function _k(uint256 balance0, uint256 balance1) internal view returns (uint256) {
        if (stableSwap) {
            uint256 _x = balance0.mul(1e18) / precisionMultiplier0;
            uint256 _y = balance1.mul(1e18) / precisionMultiplier1;
            uint256 _a = (_x.mul(_y)) / 1e18;
            uint256 _b = (_x.mul(_x) / 1e18).add(_y.mul(_y) / 1e18);
            return _a.mul(_b) / 1e18; // x3y+y3x >= k
        }
        return balance0.mul(balance1);
    }

    function _get_x(uint256 x, uint256 xy, uint256 y0) internal pure returns (uint256) {
        for (uint256 i = 0; i < 255; i++) {
            uint256 x_prev = x;
            uint256 k = _f(x, y0);
            if (k < xy) {
                uint256 dx = ((xy - k) * 1e18) / _d(y0, x);
                x = x + dx;
            } else {
                uint256 dx = ((k - xy) * 1e18) / _d(y0, x);
                x = x - dx;
            }
            if (x > x_prev) {
                if (x - x_prev <= 1) {
                    return x;
                }
            } else {
                if (x_prev - x <= 1) {
                    return x;
                }
            }
        }
        return x;
    }

    function _get_y(uint256 x0, uint256 xy, uint256 y) internal pure returns (uint256) {
        for (uint256 i = 0; i < 255; i++) {
            uint256 y_prev = y;
            uint256 k = _f(x0, y);
            if (k < xy) {
                uint256 dy = ((xy - k) * 1e18) / _d(x0, y);
                y = y + dy;
            } else {
                uint256 dy = ((k - xy) * 1e18) / _d(x0, y);
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

    function _f(uint256 x0, uint256 y) internal pure returns (uint256) {
        return (x0 * ((((y * y) / 1e18) * y) / 1e18)) / 1e18 + (((((x0 * x0) / 1e18) * x0) / 1e18) * y) / 1e18;
    }

    function _d(uint256 x0, uint256 y) internal pure returns (uint256) {
        return (3 * x0 * ((y * y) / 1e18)) / 1e18 + ((((x0 * x0) / 1e18) * x0) / 1e18);
    }

    function getAmountOut(uint256 amountIn, address tokenIn, uint256 discount) external view returns (uint256) {
        require(amountIn > 0, "Brewlabs: INSUFFICIENT_INPUT_AMOUNT");
        require(reserve0 > 0 && reserve1 > 0, "Brewlabs: INSUFFICIENT_LIQUIDITY");
        return _getAmountOut(
            amountIn,
            tokenIn,
            uint256(reserve0),
            uint256(reserve1),
            uint256(feePercent).mul(DISCOUNT_MAX.sub(discount)).div(DISCOUNT_MAX)
        );
    }

    function getAmountIn(uint256 amountOut, address tokenIn, uint256 discount) external view returns (uint256) {
        require(amountOut > 0, "Brewlabs: INSUFFICIENT_INPUT_AMOUNT");
        require(reserve0 > 0 && reserve1 > 0, "Brewlabs: INSUFFICIENT_LIQUIDITY");
        return _getAmountIn(
            amountOut,
            tokenIn,
            uint256(reserve0),
            uint256(reserve1),
            uint256(feePercent).mul(DISCOUNT_MAX.sub(discount)).div(DISCOUNT_MAX)
        );
    }

    function _getAmountOut(uint256 amountIn, address tokenIn, uint256 _reserve0, uint256 _reserve1, uint256 _feePercent)
        internal
        view
        returns (uint256)
    {
        if (stableSwap) {
            uint256 xy = _k(_reserve0, _reserve1);
            _reserve0 = (_reserve0 * 1e18) / precisionMultiplier0;
            _reserve1 = (_reserve1 * 1e18) / precisionMultiplier1;

            (uint256 reserveIn, uint256 reserveOut) =
                tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
            amountIn =
                tokenIn == token0 ? (amountIn * 1e18) / precisionMultiplier0 : (amountIn * 1e18) / precisionMultiplier1;

            uint256 y = reserveOut - _get_y(amountIn + reserveIn, xy, reserveOut);
            return ((y * (tokenIn == token0 ? precisionMultiplier1 : precisionMultiplier0)) / 1e18).mul(
                FEE_DENOMINATOR.sub(_feePercent)
            ).div(FEE_DENOMINATOR);
        } else {
            (uint256 reserveIn, uint256 reserveOut) =
                tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
            uint256 numerator = reserveOut.mul(amountIn).mul(FEE_DENOMINATOR.sub(_feePercent));
            uint256 denominator = reserveIn.add(amountIn).mul(FEE_DENOMINATOR);
            return numerator / denominator;
        }
    }

    function _getAmountIn(uint256 amountOut, address tokenIn, uint256 _reserve0, uint256 _reserve1, uint256 _feePercent)
        internal
        view
        returns (uint256)
    {
        if (stableSwap) {
            uint256 xy = _k(_reserve0, _reserve1);
            _reserve0 = (_reserve0 * 1e18) / precisionMultiplier0;
            _reserve1 = (_reserve1 * 1e18) / precisionMultiplier1;

            (uint256 reserveIn, uint256 reserveOut) =
                tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
            amountOut = tokenIn == token0
                ? (amountOut * 1e18) / precisionMultiplier0
                : (amountOut * 1e18) / precisionMultiplier1;
            amountOut = amountOut.mul(FEE_DENOMINATOR).div(FEE_DENOMINATOR.sub(_feePercent));
            uint256 x = _get_x(reserveIn, xy, reserveOut - amountOut) - reserveIn;
            return (x * (tokenIn == token0 ? precisionMultiplier0 : precisionMultiplier1)) / 1e18;
        } else {
            (uint256 reserveIn, uint256 reserveOut) =
                tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
            uint256 numerator = reserveIn.mul(amountOut).mul(FEE_DENOMINATOR);
            uint256 denominator = reserveOut.mul(FEE_DENOMINATOR - _feePercent).sub(amountOut.mul(FEE_DENOMINATOR));
            return numerator / denominator;
        }
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
        emit Skim();
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    /**
     * @dev Updates the swap fees percent
     * Can only be called by the factory's feePercentOwner
     */
    function setFeePercent(uint16 newfeePercent) external lock {
        require(msg.sender == IBrewlabsFactory(factory).feePercentOwner(), "Brewlabs: only factory's feePercentOwner");
        require(newfeePercent <= MAX_FEE_PERCENT, "Brewlabs: feePercent mustn't exceed the maximum");
        require(newfeePercent > 0, "Brewlabs: feePercent mustn't exceed the minimum");
        feePercent = newfeePercent;
        emit SetFeePercent(newfeePercent);
    }

    function setStableSwap(bool stable, uint112 expectedReserve0, uint112 expectedReserve1) external lock {
        require(msg.sender == IBrewlabsFactory(factory).setStableOwner(), "Brewlabs: only factory's setStableOwner");
        require(!pairTypeImmutable, "Brewlabs: immutable");

        require(stable != stableSwap, "Brewlabs: no update");
        require(expectedReserve0 == reserve0 && expectedReserve1 == reserve1, "Brewlabs: failed");

        emit SetStableSwap(stableSwap, stable);
        stableSwap = stable;
        kLast = _k(uint256(reserve0), uint256(reserve1));
    }

    function setStakingPool(address _stakingPool) external lock {
        require(msg.sender == IBrewlabsFactory(factory).owner(), "Brewlabs: only factory's owner");
        require(_stakingPool != address(0), "Brewlabs: invalid staking pool address");
        stakingPool = _stakingPool;
    }

    function setPairTypeImmutable() external lock {
        require(msg.sender == IBrewlabsFactory(factory).owner(), "Brewlabs: only factory's owner");
        require(!pairTypeImmutable, "Brewlabs: already immutable");

        pairTypeImmutable = true;
        emit SetPairTypeImmutable();
    }

    /**
     * @dev Allow to recover token sent here by mistake
     * Can only be called by factory's owner
     */
    function rescueWrongToken(address token, address to) external lock {
        require(msg.sender == IBrewlabsFactory(factory).owner(), "Brewlabs: only factory's owner");
        require(token != token0 && token != token1, "Brewlabs: invalid token");
        _safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        emit RescueWrongToken(token, to);
    }
}

pragma solidity >=0.5.0;

interface IBrewlabsCallee {
    function brewlabsCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external;
}

pragma solidity >=0.5.0;

interface IBrewlabsERC20 {
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

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;
}

pragma solidity >=0.5.0;

interface IBrewlabsFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function owner() external view returns (address);
    function feePercentOwner() external view returns (address);
    function setStableOwner() external view returns (address);
    function feeTo() external view returns (address);
    function feeManager() external view returns (address);

    function ownerFee() external view returns (uint256);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function feeInfo() external view returns (uint256 _ownerFee, address _feeTo);
}

pragma solidity >=0.5.0;

interface IBrewlabsPair {
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

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

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
    function getAmountIn(uint256 amountOut, address tokenIn, uint256 discount) external view returns (uint256);
    function getAmountOut(uint256 amountIn, address tokenIn, uint256 discount) external view returns (uint256);
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint16 feePercent, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function kLast() external view returns (uint256);

    function setFeePercent(uint16 feePercent) external;
    function mint(address to) external returns (uint256 liquidity);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, uint256 discount, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IBrewlabsSwapFeeManager {
    event Claimed(address indexed to, address indexed pair, uint256 amount0, uint256 amount1);

    function getFeeDistribution(address pair)
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256);
    function pendingLPRewards(address pair, address staker) external view returns (uint256, uint256);
    function createPool(address token0, address token1) external;
    function claim(address pair) external;
    function claimAll(address[] calldata pairs) external;
    function lpMinted(address to, address token0, address token1, address pair) external;
    function lpBurned(address from, address token0, address token1, address pair) external;
    function lpTransferred(address from, address to, address token0, address token1, address pair) external;
    function notifyRewardAmount(address pair, address token, uint256 amount) external;
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

pragma solidity =0.5.16;

// a library for performing various math operations

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

pragma solidity >=0.5.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y > 0, "ds-math-div-by-zero");
        z = x / y;
    }
}

pragma solidity =0.5.16;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2 ** 112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}