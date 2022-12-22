// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

import "./ProxyPattern/SolidlyFactory.sol";
import "./ProxyPattern/SolidlyChildImplementation.sol";

interface erc20 {
    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function balanceOf(address) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);
}

library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

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

interface IBaseV2Callee {
    function hook(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

interface IBaseV2Voter {
    function feeDists(address pool) external view returns (address);

    function generalFees() external view returns (address);
}

// Base V2 Fees contract is used as a 1:1 pair relationship to split out fees, this ensures that the curve does not need to be modified for LP shares
/**
 * @dev Changelog:
 *      - Deprecate constructor for initialize()
 *      - Immutable storage slots became mutable but made sure nothing changes them after initialize()
 */
contract BaseV2Fees is SolidlyChildImplementation {
    address pair; // The pair it is bonded to
    address token0; // token0 of pair, saved localy and statically for gas optimization
    address token1; // Token1 of pair, saved localy and statically for gas optimization
    uint256 lastDistributed0; // last time fee0 was distributed towards bribe
    uint256 lastDistributed1; // last time fee1 was distributed towards bribe

    function initialize(address _pair) external onlyFactory notInitialized {
        pair = _pair;
        token0 = BaseV2Pair(_pair).token0();
        token1 = BaseV2Pair(_pair).token1();
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        require(token.code.length > 0, "!contract");
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(erc20.transfer.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: safeTransfer low-level call failed"
        );
    }

    // Allow the pair to transfer fees to gauges
    function claimFeesFor(
        address recipient,
        uint256 amount0,
        uint256 amount1
    ) external {
        require(msg.sender == pair, "Only pair");
        if (amount0 > 0) {
            _safeTransfer(token0, recipient, amount0);
            lastDistributed0 = block.timestamp;
        }
        if (amount1 > 0) {
            _safeTransfer(token1, recipient, amount1);
            lastDistributed1 = block.timestamp;
        }
    }
}

// The base pair of pools, either stable or volatile
/**
 * @dev Changelog:
 *      - Deprecate constructor for initialize()
 *      - Immutable storage slots became mutable but made sure nothing changes them after initialize()
 *      - Trading fees go back to the protocol
 *      - Deprecate _updateFor(), index0, index1 because fees go back to the protocol
 */
contract BaseV2Pair is SolidlyChildImplementation {
    uint8 public constant decimals = 18;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 internal constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    uint256 internal constant MINIMUM_LIQUIDITY = 10**3;
    uint256 internal constant feeDivider = 1e6;

    /**
     * @dev storage slots start here
     */

    // simple re-entrancy check
    uint256 internal _unlocked = 1;

    string public name;
    string public symbol;

    // Used to denote stable or volatile pair,
    bool public stable;
    uint256 public feeRatio;

    uint256 public totalSupply = 0;

    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public balanceOf;

    bytes32 internal DOMAIN_SEPARATOR;
    mapping(address => uint256) public nonces;

    address public token0;
    address public token1;
    address public fees;
    address factory;

    // Structure to capture time period obervations every 30 minutes, used for local oracles
    struct Observation {
        uint256 timestamp;
        uint256 reserve0Cumulative;
        uint256 reserve1Cumulative;
    }

    // Capture oracle reading every 30 minutes
    uint256 constant periodSize = 1800;

    Observation[] public observations;

    uint256 internal decimals0;
    uint256 internal decimals1;

    uint256 public reserve0;
    uint256 public reserve1;
    uint256 public blockTimestampLast;

    uint256 public reserve0CumulativeLast;
    uint256 public reserve1CumulativeLast;

    event Fees(address indexed sender, uint256 amount0, uint256 amount1);
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
    event Sync(uint256 reserve0, uint256 reserve1);
    event Claim(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1
    );

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    // simple re-entrancy check
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    function initialize(
        address _token0,
        address _token1,
        bool _stable
    ) external onlyFactory notInitialized {
        _unlocked = 1;
        factory = msg.sender;
        (token0, token1, stable) = (_token0, _token1, _stable);
        fees = BaseV2Factory(msg.sender).createFees();
        if (_stable) {
            name = string(
                abi.encodePacked(
                    "StableV2 AMM - ",
                    erc20(_token0).symbol(),
                    "/",
                    erc20(_token1).symbol()
                )
            );
            symbol = string(
                abi.encodePacked(
                    "sAMM-",
                    erc20(_token0).symbol(),
                    "/",
                    erc20(_token1).symbol()
                )
            );
        } else {
            name = string(
                abi.encodePacked(
                    "VolatileV2 AMM - ",
                    erc20(_token0).symbol(),
                    "/",
                    erc20(_token1).symbol()
                )
            );
            symbol = string(
                abi.encodePacked(
                    "vAMM-",
                    erc20(_token0).symbol(),
                    "/",
                    erc20(_token1).symbol()
                )
            );
        }

        decimals0 = 10**erc20(_token0).decimals();
        decimals1 = 10**erc20(_token1).decimals();

        observations.push(Observation(block.timestamp, 0, 0));

        syncFees();
    }

    function observationLength() external view returns (uint256) {
        return observations.length;
    }

    function lastObservation() public view returns (Observation memory) {
        return observations[observations.length - 1];
    }

    function metadata()
        external
        view
        returns (
            uint256 dec0,
            uint256 dec1,
            uint256 r0,
            uint256 r1,
            bool st,
            address t0,
            address t1,
            uint256 _feeRatio
        )
    {
        return (
            decimals0,
            decimals1,
            reserve0,
            reserve1,
            stable,
            token0,
            token1,
            feeRatio
        );
    }

    function tokens() external view returns (address, address) {
        return (token0, token1);
    }

    /**
     * @notice directs the fees toward the gauge if it exists, goes to common pool if not
     */
    function claimFees() external returns (uint256 claimed0, uint256 claimed1) {
        // Determine whether gauge exists
        IBaseV2Voter voter = IBaseV2Voter(BaseV2Factory(factory).voter());
        address feeDistAddress = voter.feeDists(address(this));
        bool gaugeExists = feeDistAddress != address(0);

        if (!gaugeExists) {
            feeDistAddress = voter.generalFees();
        }

        require(
            msg.sender == feeDistAddress,
            "Only feeDist or only general fees if gauge doesn't exist"
        );

        // Sending directly instead of calling notifyRewardAmount(),
        // relying on the assumption that this method is only callable by feeDists and generalFees
        // and that those contracts will deal with the accounting properly
        address _fees = fees;
        claimed0 = erc20(token0).balanceOf(_fees);
        claimed1 = erc20(token1).balanceOf(_fees);
        BaseV2Fees(_fees).claimFeesFor(msg.sender, claimed0, claimed1);

        emit Claim(msg.sender, msg.sender, claimed0, claimed1);
    }

    /**
     * @notice Accrue fees on token0
     * @dev v2 does not record indexes since all fees go back to the protocol
     */
    function _update0(uint256 amount) internal {
        _safeTransfer(token0, fees, amount); // transfer the fees out to BaseV2Fees
        emit Fees(msg.sender, amount, 0);
    }

    /**
     * @notice Accrue fees on token1
     * @dev v2 does not record indexes since all fees go back to the protocol
     */
    function _update1(uint256 amount) internal {
        _safeTransfer(token1, fees, amount); // transfer the fees out to BaseV2Fees
        emit Fees(msg.sender, amount, 0);
    }

    function getReserves()
        public
        view
        returns (
            uint256 _reserve0,
            uint256 _reserve1,
            uint256 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(
        uint256 balance0,
        uint256 balance1,
        uint256 _reserve0,
        uint256 _reserve1
    ) internal {
        uint256 blockTimestamp = block.timestamp;
        uint256 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            reserve0CumulativeLast += _reserve0 * timeElapsed;
            reserve1CumulativeLast += _reserve1 * timeElapsed;
        }

        Observation memory _point = lastObservation();
        timeElapsed = blockTimestamp - _point.timestamp; // compare the last observation with current timestamp, if greater than 30 minutes, record a new event
        if (timeElapsed > periodSize) {
            observations.push(
                Observation(
                    blockTimestamp,
                    reserve0CumulativeLast,
                    reserve1CumulativeLast
                )
            );
        }
        reserve0 = balance0;
        reserve1 = balance1;
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices()
        public
        view
        returns (
            uint256 reserve0Cumulative,
            uint256 reserve1Cumulative,
            uint256 blockTimestamp
        )
    {
        blockTimestamp = block.timestamp;
        reserve0Cumulative = reserve0CumulativeLast;
        reserve1Cumulative = reserve1CumulativeLast;

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (
            uint256 _reserve0,
            uint256 _reserve1,
            uint256 _blockTimestampLast
        ) = getReserves();
        if (_blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint256 timeElapsed = blockTimestamp - _blockTimestampLast;
            reserve0Cumulative += _reserve0 * timeElapsed;
            reserve1Cumulative += _reserve1 * timeElapsed;
        }
    }

    // gives the current twap price measured from amountIn * tokenIn gives amountOut
    function current(address tokenIn, uint256 amountIn)
        external
        view
        returns (uint256 amountOut)
    {
        Observation memory _observation = lastObservation();
        (
            uint256 reserve0Cumulative,
            uint256 reserve1Cumulative,

        ) = currentCumulativePrices();
        if (block.timestamp == _observation.timestamp) {
            _observation = observations[observations.length - 2];
        }

        uint256 timeElapsed = block.timestamp - _observation.timestamp;
        uint256 _reserve0 = (reserve0Cumulative -
            _observation.reserve0Cumulative) / timeElapsed;
        uint256 _reserve1 = (reserve1Cumulative -
            _observation.reserve1Cumulative) / timeElapsed;
        amountOut = _getAmountOut(amountIn, tokenIn, _reserve0, _reserve1);
    }

    // as per `current`, however allows user configured granularity, up to the full window size
    function quote(
        address tokenIn,
        uint256 amountIn,
        uint256 granularity
    ) external view returns (uint256 amountOut) {
        uint256[] memory _prices = sample(tokenIn, amountIn, granularity, 1);
        uint256 priceAverageCumulative;
        for (uint256 i = 0; i < _prices.length; i++) {
            priceAverageCumulative += _prices[i];
        }
        return priceAverageCumulative / granularity;
    }

    // returns a memory set of twap prices
    function prices(
        address tokenIn,
        uint256 amountIn,
        uint256 points
    ) external view returns (uint256[] memory) {
        return sample(tokenIn, amountIn, points, 1);
    }

    function sample(
        address tokenIn,
        uint256 amountIn,
        uint256 points,
        uint256 window
    ) public view returns (uint256[] memory) {
        uint256[] memory _prices = new uint256[](points);

        uint256 length = observations.length - 1;
        uint256 i = length - (points * window);
        uint256 nextIndex = 0;
        uint256 index = 0;

        for (; i < length; i += window) {
            nextIndex = i + window;
            uint256 timeElapsed = observations[nextIndex].timestamp -
                observations[i].timestamp;
            uint256 _reserve0 = (observations[nextIndex].reserve0Cumulative -
                observations[i].reserve0Cumulative) / timeElapsed;
            uint256 _reserve1 = (observations[nextIndex].reserve1Cumulative -
                observations[i].reserve1Cumulative) / timeElapsed;
            _prices[index] = _getAmountOut(
                amountIn,
                tokenIn,
                _reserve0,
                _reserve1
            );
            index = index + 1;
        }
        return _prices;
    }

    // this low-level function should be called from a contract which performs important safety checks
    // standard uniswap v2 implementation
    function mint(address to) external lock returns (uint256 liquidity) {
        (uint256 _reserve0, uint256 _reserve1) = (reserve0, reserve1);
        uint256 _balance0 = erc20(token0).balanceOf(address(this));
        uint256 _balance1 = erc20(token1).balanceOf(address(this));
        uint256 _amount0 = _balance0 - _reserve0;
        uint256 _amount1 = _balance1 - _reserve1;

        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(_amount0 * _amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(
                (_amount0 * _totalSupply) / _reserve0,
                (_amount1 * _totalSupply) / _reserve1
            );
        }
        require(liquidity > 0, "ILM"); // BaseV2: INSUFFICIENT_LIQUIDITY_MINTED
        _mint(to, liquidity);

        _update(_balance0, _balance1, _reserve0, _reserve1);
        emit Mint(msg.sender, _amount0, _amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    // standard uniswap v2 implementation
    function burn(address to)
        external
        lock
        returns (uint256 amount0, uint256 amount1)
    {
        (uint256 _reserve0, uint256 _reserve1) = (reserve0, reserve1);
        (address _token0, address _token1) = (token0, token1);
        uint256 _balance0 = erc20(_token0).balanceOf(address(this));
        uint256 _balance1 = erc20(_token1).balanceOf(address(this));
        uint256 _liquidity = balanceOf[address(this)];

        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = (_liquidity * _balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = (_liquidity * _balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, "ILB"); // BaseV2: INSUFFICIENT_LIQUIDITY_BURNED
        _burn(address(this), _liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        _balance0 = erc20(_token0).balanceOf(address(this));
        _balance1 = erc20(_token1).balanceOf(address(this));

        _update(_balance0, _balance1, _reserve0, _reserve1);
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external lock {
        require(!BaseV2Factory(factory).isPaused(), "Paused");
        require(amount0Out > 0 || amount1Out > 0, "IOA"); // BaseV2: INSUFFICIENT_OUTPUT_AMOUNT
        (uint256 _reserve0, uint256 _reserve1) = (reserve0, reserve1);
        require(amount0Out < _reserve0 && amount1Out < _reserve1, "IL"); // BaseV2: INSUFFICIENT_LIQUIDITY

        uint256 _balance0;
        uint256 _balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            (address _token0, address _token1) = (token0, token1);
            require(to != _token0 && to != _token1, "IT"); // BaseV2: INVALID_TO
            if (amount0Out > 0) {
                _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            }
            if (amount1Out > 0) {
                _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            }
            if (data.length > 0) {
                IBaseV2Callee(to).hook(
                    msg.sender,
                    amount0Out,
                    amount1Out,
                    data
                ); // callback, used for flash loans
            }
            _balance0 = erc20(_token0).balanceOf(address(this));
            _balance1 = erc20(_token1).balanceOf(address(this));
        }
        uint256 amount0In = _balance0 > _reserve0 - amount0Out
            ? _balance0 - (_reserve0 - amount0Out)
            : 0;
        uint256 amount1In = _balance1 > _reserve1 - amount1Out
            ? _balance1 - (_reserve1 - amount1Out)
            : 0;
        require(amount0In > 0 || amount1In > 0, "IIA"); // BaseV2: INSUFFICIENT_INPUT_AMOUNT
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            (address _token0, address _token1) = (token0, token1);
            /**
             * @dev uses gasleft() as a pseudo-random number. Deterministic behaviour here is actually
             *      good, since it means gas usage won't flucuate with time or blocknumber/hash
             */
            // if (gasleft() % 250 == 0) {
            //     syncFees();
            // }
            if (amount0In > 0) {
                _update0((amount0In * feeRatio) / feeDivider); // accrue fees for token0 and move them out of pool
            }
            if (amount1In > 0) {
                _update1((amount1In * feeRatio) / feeDivider); // accrue fees for token1 and move them out of pool
            }
            _balance0 = erc20(_token0).balanceOf(address(this)); // since we removed tokens, we need to reconfirm balances, can also simply use previous balance - fee, but doing balanceOf again as safety check
            _balance1 = erc20(_token1).balanceOf(address(this));
            // The curve, either x3y+y3x for stable pools, or x*y for volatile pools
            require(_k(_balance0, _balance1) >= _k(_reserve0, _reserve1), "K"); // BaseV2: K
        }

        _update(_balance0, _balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    /**
     * @notice Syncs fees from pair factory
     */
    function syncFees() public {
        feeRatio = BaseV2Factory(factory).poolFees(address(this));
    }

    // force balances to match reserves
    function skim(address to) external lock {
        (address _token0, address _token1) = (token0, token1);
        _safeTransfer(
            _token0,
            to,
            erc20(_token0).balanceOf(address(this)) - (reserve0)
        );
        _safeTransfer(
            _token1,
            to,
            erc20(_token1).balanceOf(address(this)) - (reserve1)
        );
    }

    // force reserves to match balances
    function sync() external lock {
        _update(
            erc20(token0).balanceOf(address(this)),
            erc20(token1).balanceOf(address(this)),
            reserve0,
            reserve1
        );
    }

    function _f(uint256 x0, uint256 y) internal pure returns (uint256) {
        return
            (x0 * ((((y * y) / 1e18) * y) / 1e18)) /
            1e18 +
            (((((x0 * x0) / 1e18) * x0) / 1e18) * y) /
            1e18;
    }

    function _d(uint256 x0, uint256 y) internal pure returns (uint256) {
        return
            (3 * x0 * ((y * y) / 1e18)) /
            1e18 +
            ((((x0 * x0) / 1e18) * x0) / 1e18);
    }

    function _get_y(
        uint256 x0,
        uint256 xy,
        uint256 y
    ) internal pure returns (uint256) {
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

    function getAmountOut(uint256 amountIn, address tokenIn)
        external
        view
        returns (uint256)
    {
        (uint256 _reserve0, uint256 _reserve1) = (reserve0, reserve1);
        amountIn -= (amountIn * feeRatio) / feeDivider; // remove fee from amount received

        return _getAmountOut(amountIn, tokenIn, _reserve0, _reserve1);
    }

    function _getAmountOut(
        uint256 amountIn,
        address tokenIn,
        uint256 _reserve0,
        uint256 _reserve1
    ) internal view returns (uint256) {
        if (stable) {
            uint256 xy = _k(_reserve0, _reserve1);
            _reserve0 = (_reserve0 * 1e18) / decimals0;
            _reserve1 = (_reserve1 * 1e18) / decimals1;
            (uint256 reserveA, uint256 reserveB) = tokenIn == token0
                ? (_reserve0, _reserve1)
                : (_reserve1, _reserve0);
            amountIn = tokenIn == token0
                ? (amountIn * 1e18) / decimals0
                : (amountIn * 1e18) / decimals1;
            uint256 y = reserveB - _get_y(amountIn + reserveA, xy, reserveB);
            return (y * (tokenIn == token0 ? decimals1 : decimals0)) / 1e18;
        } else {
            (uint256 reserveA, uint256 reserveB) = tokenIn == token0
                ? (_reserve0, _reserve1)
                : (_reserve1, _reserve0);
            return (amountIn * reserveB) / (reserveA + amountIn);
        }
    }

    function _k(uint256 x, uint256 y) internal view returns (uint256) {
        if (stable) {
            uint256 _x = (x * 1e18) / decimals0;
            uint256 _y = (y * 1e18) / decimals1;
            uint256 _a = (_x * _y) / 1e18;
            uint256 _b = ((_x * _x) / 1e18 + (_y * _y) / 1e18);
            return (_a * _b) / 1e18; // x3y+y3x >= k
        } else {
            return x * y; // xy >= k
        }
    }

    function _mint(address dst, uint256 amount) internal {
        totalSupply += amount;
        balanceOf[dst] += amount;
        emit Transfer(address(0), dst, amount);
    }

    function _burn(address dst, uint256 amount) internal {
        totalSupply -= amount;
        balanceOf[dst] -= amount;
        emit Transfer(dst, address(0), amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "BaseV2: EXPIRED");
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "BaseV2: INVALID_SIGNATURE"
        );
        allowance[owner][spender] = value;

        emit Approval(owner, spender, value);
    }

    function transfer(address dst, uint256 amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = allowance[src][spender];

        if (spender != src && spenderAllowance != type(uint256).max) {
            uint256 newAllowance = spenderAllowance - amount;
            allowance[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(
        address src,
        address dst,
        uint256 amount
    ) internal {
        balanceOf[src] -= amount;
        balanceOf[dst] += amount;

        emit Transfer(src, dst, amount);
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        require(token.code.length > 0, "!contract");
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(erc20.transfer.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: safeTransfer low-level call failed"
        );
    }
}

/**
 * @dev Changelog:
 *      - Deprecate constructor with initialize()
 *      - Deprecate pauser role with onlyGovernance
 *      - Deprecate _temp, _temp0, _temp1, and getInitializable()
 *      - Split out feesFactory for subimplementation proxy pattern
 *      - Added records for feesFactory and voter
 *      - Added stable, volatile fees and setter methods
 */
contract BaseV2Factory is SolidlyFactory {
    bool public isPaused;

    address public feesFactory;
    address public voter;

    mapping(address => mapping(address => mapping(bool => address)))
        public getPair;
    address[] public allPairs;
    mapping(address => bool) public isPair; // simplified check if its a pair, given that `stable` flag might not be available in peripherals

    uint256 public maxFees; // 1_000_000 = 100%
    uint256 public stableFees;
    uint256 public volatileFees;
    mapping(address => bool) public poolSpecificFeesEnabled;
    mapping(address => uint256) public poolSpecificFees;

    mapping(address => bool) public isOperator;

    /**************************************** 
                      Events
     ****************************************/

    event OperatorStatus(address indexed operator, bool state);

    event PairCreated(
        address indexed token0,
        address indexed token1,
        bool stable,
        address pair,
        uint256
    );

    /**************************************** 
                    Modifiers
     ****************************************/

    modifier onlyGovernanceOrOperator() {
        require(isOperator[msg.sender] || msg.sender == governanceAddress());
        _;
    }

    /**************************************** 
                    Initialize
     ****************************************/

    function initialize(address _feesFactory, address _voter)
        external
        onlyGovernance
        notInitialized
    {
        feesFactory = _feesFactory;
        voter = _voter;
        stableFees = 200; // 0.02%
        volatileFees = 2000; // 0.20%
        maxFees = 30000; // 3%
    }

    /**************************************** 
                Restricted Methods
     ****************************************/

    /**
     * @notice Sets operator status
     * @dev Operators are allowed to pause and set pool fees
     */
    function setOperator(address operator, bool state) external onlyGovernance {
        if (isOperator[operator] != state) {
            isOperator[operator] = state;
            emit OperatorStatus(operator, state);
        }
    }

    function setPause(bool _state) external onlyGovernanceOrOperator {
        isPaused = _state;
    }

    function setMaxFees(uint256 _maxFees) external onlyGovernance {
        require(_maxFees <= 1e6, "Over 100%");
        maxFees = _maxFees;
    }

    function setStableFees(uint256 _stableFees)
        external
        onlyGovernanceOrOperator
    {
        require(_stableFees < maxFees, "Over max fees");
        stableFees = _stableFees;
    }

    function setVolatileFees(uint256 _volatileFees)
        external
        onlyGovernanceOrOperator
    {
        require(_volatileFees < maxFees, "Over max fees");
        volatileFees = _volatileFees;
    }

    /**
     * @notice Sets specific pool's fees
     * @dev _enabled needs to be set to true, to differentiate between
     *      pools with 0% fees and pools without specific fees
     */
    function setPoolSpecificFees(
        address _pool,
        uint256 _fees,
        bool _enabled
    ) external onlyGovernanceOrOperator {
        require(_fees < maxFees, "Over max fees");
        poolSpecificFeesEnabled[_pool] = _enabled;
        poolSpecificFees[_pool] = _fees;

        // Sync pool's fees
        BaseV2Pair(_pool).syncFees();
    }

    /**************************************** 
                   View Methods
     ****************************************/

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function pairCodeHash() external pure returns (bytes32) {
        return keccak256(type(SolidlyChildProxy).creationCode);
    }

    /**
     * @notice Returns fee in basis points for a pool
     */
    function poolFees(address pool) external view returns (uint256) {
        // Return pool specific fees if enabled
        if (poolSpecificFeesEnabled[pool]) {
            return poolSpecificFees[pool];
        }

        // Return volatile fees if not stable
        if (!BaseV2Pair(pool).stable()) {
            return volatileFees;
        }

        // Return stable fees otherwise
        return stableFees;
    }

    /**************************************** 
                User Interaction
     ****************************************/

    function createPair(
        address tokenA,
        address tokenB,
        bool stable
    ) external returns (address pair) {
        require(tokenA != tokenB, "IA"); // BaseV2: IDENTICAL_ADDRESSES
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "ZA"); // BaseV2: ZERO_ADDRESS
        require(getPair[token0][token1][stable] == address(0), "PE"); // BaseV2: PAIR_EXISTS - single check is sufficient
        bytes32 salt = keccak256(abi.encodePacked(token0, token1, stable)); // notice salt includes stable as well, 3 parameters
        pair = _deployChildProxyWithSalt(salt);
        BaseV2Pair(pair).initialize(token0, token1, stable);
        getPair[token0][token1][stable] = pair;
        getPair[token1][token0][stable] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        isPair[pair] = true;
        emit PairCreated(token0, token1, stable, pair, allPairs.length);
    }

    function createFees() external returns (address fees) {
        fees = BaseV2FeesFactory(feesFactory).createFees(msg.sender);
    }
}

/**
 * @dev Introduced in v2 so each factory only need to carry one set of interface and subimplementation
 */
contract BaseV2FeesFactory is SolidlyFactory {
    function createFees(address _pair) external returns (address fees) {
        fees = _deployChildProxy();
        BaseV2Fees(fees).initialize(_pair);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IFactory {
    function governanceAddress() external view returns (address);

    function childSubImplementationAddress() external view returns (address);

    function childInterfaceAddress() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;
import "./SolidlyImplementation.sol";
import "./interfaces/IFactory.sol";

contract SolidlyChildImplementation is SolidlyImplementation {
    bytes32 constant FACTORY_SLOT =
        0x547b500e425d72fd0723933cceefc203cef652b4736fd04250c3369b3e1a0a72; // keccak256('FACTORY') - 1

    modifier onlyFactory() {
        require(msg.sender == factoryAddress(), "only Factory");
        _;
    }

    /****************************************
                  VIEW METHODS 
     ****************************************/

    /**
     * @notice Fetch current governance address from factory
     * @return _governanceAddress Returns current governance address
     */
    function governanceAddress()
        public
        view
        override
        returns (address _governanceAddress)
    {
        return IFactory(factoryAddress()).governanceAddress();
    }

    function factoryAddress() public view returns (address _factory) {
        assembly {
            _factory := sload(FACTORY_SLOT)
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;
import "./SolidlyProxy.sol";
import "./interfaces/IFactory.sol";

/**
 * @notice Child Proxy deployed by factories for pairs, fees, gauges, and bribes. Calls back to the factory to fetch proxy implementation.
 */
contract SolidlyChildProxy is SolidlyProxy {
    bytes32 constant FACTORY_SLOT =
        0x547b500e425d72fd0723933cceefc203cef652b4736fd04250c3369b3e1a0a72; // keccak256('FACTORY') - 1

    modifier onlyFactory() {
        require(msg.sender == factoryAddress(), "only Factory");
        _;
    }

    /**
     * @notice Records factory address and current interface implementation
     */
    constructor() {
        address _factory = msg.sender;
        address _interface = IFactory(msg.sender).childInterfaceAddress();
        assembly {
            sstore(FACTORY_SLOT, _factory)
            sstore(IMPLEMENTATION_SLOT, _interface) // Storing the interface into EIP-1967's implementation slot so Etherscan picks up the interface
        }
    }

    /****************************************
                    SETTINGS
     ****************************************/

    /**
     * @notice Governance callable method to update the Factory address
     */
    function updateFactoryAddress(address _factory) external onlyGovernance {
        assembly {
            sstore(FACTORY_SLOT, _factory)
        }
    }

    /**
     * @notice Publically callable function to sync proxy interface with the one recorded in the factory
     */
    function updateInterfaceAddress() external {
        address _newInterfaceAddress = IFactory(factoryAddress())
            .childInterfaceAddress();
        require(
            implementationAddress() != _newInterfaceAddress,
            "Nothing to update"
        );
        assembly {
            sstore(IMPLEMENTATION_SLOT, _newInterfaceAddress)
        }
    }

    /****************************************
                  VIEW METHODS 
     ****************************************/

    /**
     * @notice Fetch current governance address from factory
     * @return _governanceAddress Returns current governance address
     */
    function governanceAddress()
        public
        view
        override
        returns (address _governanceAddress)
    {
        return IFactory(factoryAddress()).governanceAddress();
    }

    function factoryAddress() public view returns (address _factory) {
        assembly {
            _factory := sload(FACTORY_SLOT)
        }
    }

    /**
     *@notice Fetch address where actual contract logic is at
     */
    function subImplementationAddress()
        public
        view
        returns (address _subimplementation)
    {
        return IFactory(factoryAddress()).childSubImplementationAddress();
    }

    /**
     * @notice Fetch address where the interface for the contract is
     */
    function interfaceAddress()
        public
        view
        override
        returns (address _interface)
    {
        assembly {
            _interface := sload(IMPLEMENTATION_SLOT)
        }
    }

    /****************************************
                  FALLBACK METHODS 
     ****************************************/

    /**
     * @notice Fallback function that delegatecalls the subimplementation instead of what's in the IMPLEMENTATION_SLOT
     */
    function _delegateCallSubimplmentation() internal override {
        address contractLogic = IFactory(factoryAddress())
            .childSubImplementationAddress();
        assembly {
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(
                gas(),
                contractLogic,
                0x0,
                calldatasize(),
                0,
                0
            )
            let returnDataSize := returndatasize()
            returndatacopy(0, 0, returnDataSize)
            switch success
            case 0 {
                revert(0, returnDataSize)
            }
            default {
                return(0, returnDataSize)
            }
        }
    }

    fallback() external payable override {
        _delegateCallSubimplmentation();
    }

    receive() external payable override {
        _delegateCallSubimplmentation();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;
import "./SolidlyImplementation.sol";
import "./SolidlyChildProxy.sol";

contract SolidlyFactory is SolidlyImplementation {
    bytes32 constant CHILD_SUBIMPLEMENTATION_SLOT =
        0xa7461aa7cde97eb2572f8234e341359c6baae47e1feeb3c235edffe5f0fc089d; // keccak256('CHILD_SUBIMPLEMENTATION') - 1
    bytes32 constant CHILD_INTERFACE_SLOT =
        0x23762bb6469fe7a7bd6609262f442817ed09ca1f07add24ef069610d59c90649; // keccak256('CHILD_INTERFACE') - 1
    bytes32 constant SUBIMPLEMENTATION_SLOT =
        0xa1056f3ed783ff191ada02861fcb19d9ae3a8f50b739813a127951ef5290458d; // keccak256('SUBIMPLEMENTATION') - 1
    bytes32 constant INTERFACE_SLOT =
        0x4a9bf2931aa5eae439c602abae4bd662e7919244decac463e2e35fc862c5fb98; // keccak256('INTERFACE') - 1

    address public interfaceSourceAddress;

    function _deployChildProxy() internal returns (address) {
        address addr = address(new SolidlyChildProxy());

        return addr;
    }

    function _deployChildProxyWithSalt(bytes32 salt)
        internal
        returns (address)
    {
        address addr = address(new SolidlyChildProxy{salt: salt}());

        return addr;
    }

    function updateChildSubImplementationAddress(
        address _childSubImplementationAddress
    ) external onlyGovernance {
        assembly {
            sstore(CHILD_SUBIMPLEMENTATION_SLOT, _childSubImplementationAddress)
        }
    }

    function updateChildInterfaceAddress(address _childInterfaceAddress)
        external
        onlyGovernance
    {
        assembly {
            sstore(CHILD_INTERFACE_SLOT, _childInterfaceAddress)
        }
    }

    function childSubImplementationAddress()
        external
        view
        returns (address _childSubImplementation)
    {
        assembly {
            _childSubImplementation := sload(CHILD_SUBIMPLEMENTATION_SLOT)
        }
    }

    function childInterfaceAddress()
        external
        view
        returns (address _childInterface)
    {
        assembly {
            _childInterface := sload(CHILD_INTERFACE_SLOT)
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

/**
 * @title Solidly+ Implementation
 * @author Solidly+
 * @notice Governable implementation that relies on governance slot to be set by the proxy
 */
contract SolidlyImplementation {
    bytes32 constant GOVERNANCE_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103; // keccak256('eip1967.proxy.admin')
    bytes32 constant INITIALIZED_SLOT =
        0x834ce84547018237034401a09067277cdcbe7bbf7d7d30f6b382b0a102b7b4a3; // keccak256('eip1967.proxy.initialized')

    /**
     * @notice Reverts if msg.sender is not governance
     */
    modifier onlyGovernance() {
        require(msg.sender == governanceAddress(), "Only governance");
        _;
    }

    /**
     * @notice Reverts if contract is already initialized
     * @dev U4sed by implementations to ensure initialize() is only called once
     */
    modifier notInitialized() {
        bool initialized;
        assembly {
            initialized := sload(INITIALIZED_SLOT)
            if eq(initialized, 1) {
                revert(0, 0)
            }
        }
        _;
    }

    /**
     * @notice Fetch current governance address
     * @return _governanceAddress Returns current governance address
     */
    function governanceAddress()
        public
        view
        virtual
        returns (address _governanceAddress)
    {
        assembly {
            _governanceAddress := sload(GOVERNANCE_SLOT)
        }
    }
}

// SPDX-License-Identifier: BUSL
pragma solidity 0.8.11;

/**
 * @title Solidly+ governance killable proxy
 * @author Solidly+
 * @notice EIP-1967 upgradeable proxy with the ability to kill governance and render the contract immutable
 */
contract SolidlyProxy {
    bytes32 constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc; // keccak256('eip1967.proxy.implementation'), actually used for interface so etherscan picks up the interface
    bytes32 constant LOGIC_SLOT =
        0x5942be825425c77e56e4bce97986794ab0f100954e40fc1390ae0e003710a3ab; // keccak256('LOGIC') - 1, actual logic implementation
    bytes32 constant GOVERNANCE_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103; // keccak256('eip1967.proxy.admin')
    bytes32 constant INITIALIZED_SLOT =
        0x834ce84547018237034401a09067277cdcbe7bbf7d7d30f6b382b0a102b7b4a3; // keccak256('eip1967.proxy.initialized')

    /**
     * @notice Reverts if msg.sender is not governance
     */
    modifier onlyGovernance() {
        require(msg.sender == governanceAddress(), "Only governance");
        _;
    }

    /**
     * @notice Reverts if contract is already initialized
     * @dev Used by implementations to ensure initialize() is only called once
     */
    modifier notInitialized() {
        bool initialized;
        assembly {
            initialized := sload(INITIALIZED_SLOT)
            if eq(initialized, 1) {
                revert(0, 0)
            }
            sstore(INITIALIZED_SLOT, 1)
        }
        _;
    }

    /**
     * @notice Sets up deployer as a proxy governance
     */
    constructor() {
        address _governanceAddress = msg.sender;
        assembly {
            sstore(GOVERNANCE_SLOT, _governanceAddress)
        }
    }

    /**
     * @notice Detect whether or not governance is killed
     * @return Return true if governance is killed, false if not
     * @dev If governance is killed this contract becomes immutable
     */
    function governanceIsKilled() public view returns (bool) {
        return governanceAddress() == address(0);
    }

    /**
     * @notice Kill governance, making this contract immutable
     * @dev Only governance can kil governance
     */
    function killGovernance() external onlyGovernance {
        updateGovernanceAddress(address(0));
    }

    /**
     * @notice Update implementation address
     * @param _interfaceAddress Address of the new interface
     * @dev Only governance can update implementation
     */
    function updateInterfaceAddress(address _interfaceAddress)
        external
        onlyGovernance
    {
        assembly {
            sstore(IMPLEMENTATION_SLOT, _interfaceAddress)
        }
    }

    /**
     * @notice Actually updates interface, kept for etherscan pattern recognition
     * @param _implementationAddress Address of the new implementation
     * @dev Only governance can update implementation
     */
    function updateImplementationAddress(address _implementationAddress)
        external
        onlyGovernance
    {
        assembly {
            sstore(IMPLEMENTATION_SLOT, _implementationAddress)
        }
    }

    /**
     * @notice Update implementation address
     * @param _logicAddress Address of the new implementation
     * @dev Only governance can update implementation
     */
    function updateLogicAddress(address _logicAddress) external onlyGovernance {
        assembly {
            sstore(LOGIC_SLOT, _logicAddress)
        }
    }

    /**
     * @notice Update governance address
     * @param _governanceAddress New governance address
     * @dev Only governance can update governance
     */
    function updateGovernanceAddress(address _governanceAddress)
        public
        onlyGovernance
    {
        assembly {
            sstore(GOVERNANCE_SLOT, _governanceAddress)
        }
    }

    /**
     * @notice Fetch the current implementation address
     * @return _implementationAddress Returns the current implementation address
     */
    function implementationAddress()
        public
        view
        returns (address _implementationAddress)
    {
        assembly {
            _implementationAddress := sload(IMPLEMENTATION_SLOT)
        }
    }

    /**
     * @notice Fetch the current implementation address
     * @return _interfaceAddress Returns the current implementation address
     */
    function interfaceAddress()
        public
        view
        virtual
        returns (address _interfaceAddress)
    {
        assembly {
            _interfaceAddress := sload(IMPLEMENTATION_SLOT)
        }
    }

    /**
     * @notice Fetch the current implementation address
     * @return _logicAddress Returns the current implementation address
     */
    function logicAddress()
        public
        view
        virtual
        returns (address _logicAddress)
    {
        assembly {
            _logicAddress := sload(LOGIC_SLOT)
        }
    }

    /**
     * @notice Fetch current governance address
     * @return _governanceAddress Returns current governance address
     */
    function governanceAddress()
        public
        view
        virtual
        returns (address _governanceAddress)
    {
        assembly {
            _governanceAddress := sload(GOVERNANCE_SLOT)
        }
    }

    /**
     * @notice Fallback function that delegatecalls the subimplementation instead of what's in the IMPLEMENTATION_SLOT
     */
    function _delegateCallSubimplmentation() internal virtual {
        assembly {
            let contractLogic := sload(LOGIC_SLOT)
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(
                gas(),
                contractLogic,
                0x0,
                calldatasize(),
                0,
                0
            )
            let returnDataSize := returndatasize()
            returndatacopy(0, 0, returnDataSize)
            switch success
            case 0 {
                revert(0, returnDataSize)
            }
            default {
                return(0, returnDataSize)
            }
        }
    }

    /**
     * @notice Delegatecall fallback proxy
     */
    fallback() external payable virtual {
        _delegateCallSubimplmentation();
    }

    receive() external payable virtual {
        _delegateCallSubimplmentation();
    }
}