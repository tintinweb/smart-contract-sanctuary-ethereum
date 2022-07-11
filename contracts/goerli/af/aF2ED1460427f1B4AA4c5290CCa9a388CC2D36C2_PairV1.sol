// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@rari-capital/solmate/src/tokens/ERC20.sol";
import "./interfaces/IFactoryV1.sol";
import {Observation} from "./interfaces/IPairV1.sol";
import "./interfaces/ICalleeV1.sol";
import "./libraries/Math.sol";
import "./libraries/TransferHelper.sol";
import "./FeesV1.sol";
import "./ReentrancyGuard.sol";

// The base pair of pools, either stable or volatile
// solhint-disable not-rely-on-time /*
contract PairV1 is ERC20, ReentrancyGuard {
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
    event SwapFeeSet(uint256 swapFee);
    event ReserveFeeSet(uint256 reserveFee);

    uint256 private constant MAX_FEE = 10_000;
    // Swap fees
    uint256 private constant MAX_SWAP_FEE = 1000;
    uint256 private constant DEFAULT_STABLE_SWAP_FEE = 1;
    uint256 private constant DEFAULT_VOLATILE_SWAP_FEE = 30;
    // Reserve fees
    uint256 private constant MAX_RESERVE_FEE = 10_000;
    uint256 private constant DEFAULT_RESERVE_FEE = 2000;
    uint256 private constant MINIMUM_LIQUIDITY = 1000;
    // Capture oracle reading every 30 minutes
    uint256 private constant PERIOD_SIZE = 1800;

    // Used to denote stable or volatile pair
    bool public immutable stable;
    address public immutable token0;
    address public immutable token1;
    uint256 private immutable decimals0;
    uint256 private immutable decimals1;
    address public immutable fees;
    address public immutable factory;

    Observation[] public observations;

    uint256 public reserve0;
    uint256 public reserve1;
    uint256 public blockTimestampLast;

    uint256 public reserve0CumulativeLast;
    uint256 public reserve1CumulativeLast;

    // index0 and index1 are used to accumulate fees,
    // this is split out from normal trades to keep the swap "clean"
    // this further allows LP holders to easily claim fees for tokens they have/staked
    // index0 = cumulative of token 0 fee / totalSupply
    uint256 public index0;
    // index1 = cumulative of token 1 fee / totalSupply
    uint256 public index1;

    // position assigned to each LP to track their current index0 & index1 vs the global position
    mapping(address => uint256) public supplyIndex0;
    mapping(address => uint256) public supplyIndex1;

    // tracks the amount of unclaimed, but claimable tokens off of fees for token0 and token1
    mapping(address => uint256) public claimable0;
    mapping(address => uint256) public claimable1;

    uint256 public swapFee;
    uint256 public reserveFee;

    modifier onlyFactoryOwner() {
        require(msg.sender == IFactoryV1(factory).owner(), "not owner");
        _;
    }

    // placeholder name and symbol
    constructor() ERC20("", "", 18) {
        factory = msg.sender;
        (address _token0, address _token1, bool _stable) = IFactoryV1(
            msg.sender
        ).getConstructorArgs();
        (token0, token1, stable) = (_token0, _token1, _stable);

        swapFee = _stable ? DEFAULT_STABLE_SWAP_FEE : DEFAULT_VOLATILE_SWAP_FEE;
        reserveFee = DEFAULT_RESERVE_FEE;

        fees = address(new FeesV1(_token0, _token1));

        if (_stable) {
            name = string(
                abi.encodePacked(
                    "StableV1 HALO AMM - ",
                    IERC20Metadata(_token0).symbol(),
                    "/",
                    IERC20Metadata(_token1).symbol()
                )
            );
            symbol = string(
                abi.encodePacked(
                    "sHAMM-",
                    IERC20Metadata(_token0).symbol(),
                    "/",
                    IERC20Metadata(_token1).symbol()
                )
            );
        } else {
            name = string(
                abi.encodePacked(
                    "VolatileV1 HALO AMM - ",
                    IERC20Metadata(_token0).symbol(),
                    "/",
                    IERC20Metadata(_token1).symbol()
                )
            );
            symbol = string(
                abi.encodePacked(
                    "vHAMM-",
                    IERC20Metadata(_token0).symbol(),
                    "/",
                    IERC20Metadata(_token1).symbol()
                )
            );
        }

        decimals0 = 10**IERC20Metadata(_token0).decimals();
        decimals1 = 10**IERC20Metadata(_token1).decimals();

        observations.push(Observation(block.timestamp, 0, 0));
    }

    function setSwapFee(uint256 _swapFee) external onlyFactoryOwner {
        require(_swapFee <= MAX_SWAP_FEE, "fee > max");
        swapFee = _swapFee;
        emit SwapFeeSet(_swapFee);
    }

    function setReserveFee(uint256 _reserveFee) external onlyFactoryOwner {
        require(_reserveFee <= MAX_RESERVE_FEE, "fee > max");
        reserveFee = _reserveFee;
        emit ReserveFeeSet(_reserveFee);
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
            address t1
        )
    {
        return (
            decimals0,
            decimals1,
            reserve0,
            reserve1,
            stable,
            token0,
            token1
        );
    }

    function tokens() external view returns (address, address) {
        return (token0, token1);
    }

    function getObservationCount() external view returns (uint256) {
        return observations.length;
    }

    function getReserveCumulatives() external view returns (uint256, uint256) {
        return (reserve0CumulativeLast, reserve1CumulativeLast);
    }

    function getReserves()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (reserve0, reserve1, blockTimestampLast);
    }

    // Accrue fees on token0
    function _update0(uint256 amount) private {
        TransferHelper.safeTransfer(token0, fees, amount);
        // 1e18 adjustment is removed during claim
        uint256 ratio = (amount * 1e18) / totalSupply;
        if (ratio > 0) {
            index0 += ratio;
        }
        emit Fees(msg.sender, amount, 0);
    }

    // Accrue fees on token1
    function _update1(uint256 amount) private {
        TransferHelper.safeTransfer(token1, fees, amount);
        // 1e18 adjustment is removed during claim
        uint256 ratio = (amount * 1e18) / totalSupply;
        if (ratio > 0) {
            index1 += ratio;
        }
        emit Fees(msg.sender, 0, amount);
    }

    // This function MUST be called on any balance changes, otherwise can be
    // used to infinitely claim fees.
    // Fees are segregated from core funds, so fees can never put liquidity at risk
    function _updateFor(address recipient) private {
        /*
        How is fee calculated?

        let
        si = shares an user has at time t = i
        Ti = total shares at t = i
        fi = token fee generated at t = i

        f = total token fee claimable by the user from t = 0 to n
        f = s0 / T0 * f0 + ... + sn / Tn * fn

        Let's say user mints s shares for the first time at t = i
        then s0, ..., s(i-1) = 0
        and si, ..., sn = s

        therefore

        f = s * (fi / Ti + ... + fn / Tn)
          = s * ((f0 / T0 + ... fn / Tn) - (f0 + ... + f(i-1) / T(i - 1)))
          = s * (index0 - supplyIndex0[user])
        */
        uint256 supplied = balanceOf[recipient];
        if (supplied > 0) {
            // get last adjusted index0 for recipient
            uint256 s0 = supplyIndex0[recipient];
            uint256 s1 = supplyIndex1[recipient];
            // get global index0 for accumulated fees
            uint256 i0 = index0;
            uint256 i1 = index1;
            // update user current position to global position
            supplyIndex0[recipient] = i0;
            supplyIndex1[recipient] = i1;
            // see if there is any difference that need to be accrued
            uint256 delta0 = i0 - s0;
            uint256 delta1 = i1 - s1;
            // add accrued difference for each supplied token
            if (delta0 > 0) {
                claimable0[recipient] += (supplied * delta0) / 1e18;
            }
            if (delta1 > 0) {
                claimable1[recipient] += (supplied * delta1) / 1e18;
            }
        } else {
            // new users are set to the default global state
            supplyIndex0[recipient] = index0;
            supplyIndex1[recipient] = index1;
        }
    }

    // claim accumulated but unclaimed fees
    function claimFees() external returns (uint256 claimed0, uint256 claimed1) {
        _updateFor(msg.sender);

        claimed0 = claimable0[msg.sender];
        claimed1 = claimable1[msg.sender];

        if (claimed0 > 0 || claimed1 > 0) {
            claimable0[msg.sender] = 0;
            claimable1[msg.sender] = 0;

            FeesV1(fees).claimFeesFor(msg.sender, claimed0, claimed1);

            emit Claim(msg.sender, msg.sender, claimed0, claimed1);
        }
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(
        uint256 _balance0,
        uint256 _balance1,
        uint256 _reserve0,
        uint256 _reserve1
    ) private {
        // first call to block, update reserve cumulatives
        uint256 timeElapsed = block.timestamp - blockTimestampLast;
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            reserve0CumulativeLast += _reserve0 * timeElapsed;
            reserve1CumulativeLast += _reserve1 * timeElapsed;
        }

        Observation memory point = observations[observations.length - 1];
        // compare the last observation with current timestamp,
        // if greater than 30 minutes, record a new event
        timeElapsed = block.timestamp - point.timestamp;
        if (timeElapsed > PERIOD_SIZE) {
            observations.push(
                Observation(
                    block.timestamp,
                    reserve0CumulativeLast,
                    reserve1CumulativeLast
                )
            );
        }

        reserve0 = _balance0;
        reserve1 = _balance1;
        blockTimestampLast = block.timestamp;
        emit Sync(_balance0, _balance1);
    }

    function mint(address to) external lock returns (uint256 liquidity) {
        (uint256 res0, uint256 res1) = (reserve0, reserve1);
        uint256 bal0 = IERC20(token0).balanceOf(address(this));
        uint256 bal1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = bal0 - res0;
        uint256 amount1 = bal1 - res1;

        // gas savings, must be defined here since totalSupply can update in _mintFee
        uint256 _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            // permanently lock the first MINIMUM_LIQUIDITY tokens
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min(
                (amount0 * _totalSupply) / res0,
                (amount1 * _totalSupply) / res1
            );
        }
        require(liquidity > 0, "liquidity = 0");

        _mint(to, liquidity);
        _update(bal0, bal1, res0, res1);

        emit Mint(msg.sender, amount0, amount1);
    }

    function burn(address to)
        external
        lock
        returns (uint256 amount0, uint256 amount1)
    {
        (uint256 res0, uint256 res1) = (reserve0, reserve1);
        uint256 bal0 = IERC20(token0).balanceOf(address(this));
        uint256 bal1 = IERC20(token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];

        uint256 _totalSupply = totalSupply;
        amount0 = (liquidity * bal0) / _totalSupply;
        amount1 = (liquidity * bal1) / _totalSupply;
        require(amount0 > 0 && amount1 > 0, "insufficient liquidity burnt");

        _burn(address(this), liquidity);

        TransferHelper.safeTransfer(token0, to, amount0);
        TransferHelper.safeTransfer(token1, to, amount1);

        bal0 = IERC20(token0).balanceOf(address(this));
        bal1 = IERC20(token1).balanceOf(address(this));

        _update(bal0, bal1, res0, res1);

        emit Burn(msg.sender, amount0, amount1, to);
    }

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external lock {
        require(amount0Out > 0 || amount1Out > 0, "amounts out = 0");
        (uint256 res0, uint256 res1) = (reserve0, reserve1);
        require(
            amount0Out < res0 && amount1Out < res1,
            "amounts out >= reserve"
        );

        require(to != token0 && to != token1, "invalid to address");
        if (amount0Out > 0) TransferHelper.safeTransfer(token0, to, amount0Out);
        if (amount1Out > 0) TransferHelper.safeTransfer(token1, to, amount1Out);
        if (data.length > 0)
            ICalleeV1(to).hook(msg.sender, amount0Out, amount1Out, data);

        uint256 bal0 = IERC20(token0).balanceOf(address(this));
        uint256 bal1 = IERC20(token1).balanceOf(address(this));

        uint256 amount0In = bal0 > res0 - amount0Out
            ? bal0 - (res0 - amount0Out)
            : 0;
        uint256 amount1In = bal1 > res1 - amount1Out
            ? bal1 - (res1 - amount1Out)
            : 0;
        require(amount0In > 0 || amount1In > 0, "amount in = 0");
        {
            // avoids stack too deep errors
            address reserve = IFactoryV1(factory).reserves(address(this));

            if (amount0In > 0) {
                uint256 fee0 = (amount0In * swapFee) / MAX_FEE;

                if (reserve != address(0)) {
                    uint256 toReserve = (fee0 * reserveFee) / MAX_FEE;
                    if (toReserve != 0) {
                        fee0 -= toReserve;
                        TransferHelper.safeTransfer(token0, reserve, toReserve);
                    }
                }

                _update0(fee0);
            }

            if (amount1In > 0) {
                uint256 fee1 = (amount1In * swapFee) / MAX_FEE;

                if (reserve != address(0)) {
                    uint256 toReserve = (fee1 * reserveFee) / MAX_FEE;
                    if (toReserve != 0) {
                        fee1 -= toReserve;
                        TransferHelper.safeTransfer(token1, reserve, toReserve);
                    }
                }

                _update1(fee1);
            }

            bal0 = IERC20(token0).balanceOf(address(this));
            bal1 = IERC20(token1).balanceOf(address(this));
            require(_k(bal0, bal1) >= _k(res0, res1), "K");
        }

        _update(bal0, bal1, res0, res1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // f(x, y) = xy^3 + x^3y
    function _f(uint256 x0, uint256 y) private pure returns (uint256) {
        // x0 * y^3 + x0^3 * y
        return
            (x0 * ((((y * y) / 1e18) * y) / 1e18)) /
            1e18 +
            (((((x0 * x0) / 1e18) * x0) / 1e18) * y) /
            1e18;
    }

    // derivative of f, df/dy = 3xy^2 + x^3
    function _d(uint256 x0, uint256 y) private pure returns (uint256) {
        // 3x0 * y^2 + x0^3
        return
            (3 * x0 * ((y * y) / 1e18)) /
            1e18 +
            ((((x0 * x0) / 1e18) * x0) / 1e18);
    }

    function _getY(
        uint256 x0,
        // _k(reserve0 reserve1)
        uint256 k0,
        uint256 y
    ) private pure returns (uint256) {
        // Find y where F(y) = xy^3 + x^3y - K = 0
        // using Newton's method
        // y_(n+1) = y_n - F(y_n) / F'(y_n)
        // y = y - (xy^3 + x^3y - K) / (3xy^2 + x^3)
        for (uint256 i = 0; i < 255; ++i) {
            uint256 yPrev = y;
            // x0 * y^3 + x0^3 * y
            uint256 k = _f(x0, y);
            if (k < k0) {
                y += ((k0 - k) * 1e18) / _d(x0, y);
            } else {
                y -= ((k - k0) * 1e18) / _d(x0, y);
            }
            if (Math.abs(y, yPrev) <= 1) {
                return y;
            }
        }
        return y;
    }

    function _k(uint256 x, uint256 y) private view returns (uint256) {
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

    function _calcAmountOut(
        uint256 amountIn,
        address tokenIn,
        uint256 _reserve0,
        uint256 _reserve1
    ) private view returns (uint256) {
        if (stable) {
            bool isToken0 = tokenIn == token0;

            uint256 k0 = _k(_reserve0, _reserve1);
            _reserve0 = (_reserve0 * 1e18) / decimals0;
            _reserve1 = (_reserve1 * 1e18) / decimals1;
            (uint256 reserveA, uint256 reserveB) = isToken0
                ? (_reserve0, _reserve1)
                : (_reserve1, _reserve0);
            amountIn = isToken0
                ? (amountIn * 1e18) / decimals0
                : (amountIn * 1e18) / decimals1;
            uint256 y = reserveB - _getY(amountIn + reserveA, k0, reserveB);
            return (y * (isToken0 ? decimals1 : decimals0)) / 1e18;
        } else {
            (uint256 reserveA, uint256 reserveB) = tokenIn == token0
                ? (_reserve0, _reserve1)
                : (_reserve1, _reserve0);
            return (amountIn * reserveB) / (reserveA + amountIn);
        }
    }

    function calcAmountOut(
        uint256 amountIn,
        address tokenIn,
        uint256 _reserve0,
        uint256 _reserve1
    ) external view returns (uint256) {
        return _calcAmountOut(amountIn, tokenIn, _reserve0, _reserve1);
    }

    function getAmountOut(uint256 amountIn, address tokenIn)
        external
        view
        returns (uint256)
    {
        amountIn -= (amountIn * swapFee) / MAX_FEE; // remove fee from amount received
        return _calcAmountOut(amountIn, tokenIn, reserve0, reserve1);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        TransferHelper.safeTransfer(
            token0,
            to,
            IERC20(token0).balanceOf(address(this)) - reserve0
        );
        TransferHelper.safeTransfer(
            token1,
            to,
            IERC20(token1).balanceOf(address(this)) - reserve1
        );
    }

    // force reserves to match balances
    function sync() external lock {
        _update(
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this)),
            reserve0,
            reserve1
        );
    }

    function _mint(address dst, uint256 amount) internal override {
        _updateFor(dst); // balances must be updated on mint/burn/transfer
        super._mint(dst, amount);
    }

    function _burn(address dst, uint256 amount) internal override {
        _updateFor(dst);
        super._burn(dst, amount);
    }

    function transfer(address dst, uint256 amount)
        public
        override
        returns (bool)
    {
        _updateFor(msg.sender);
        _updateFor(dst);
        super.transfer(dst, amount);
        return true;
    }

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) public override returns (bool) {
        _updateFor(src);
        _updateFor(dst);
        super.transferFrom(src, dst, amount);
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IFactoryV1 {
    function owner() external view returns (address);

    function numPairs() external view returns (uint256);

    function isPair(address pair) external view returns (bool);

    function getPair(
        address tokenA,
        address token,
        bool stable
    ) external view returns (address pair);

    function calculatePairAddress(
        address tokenA,
        address token,
        bool stable
    ) external view returns (address pair);

    function getConstructorArgs()
        external
        view
        returns (
            address,
            address,
            bool
        );

    function createPair(
        address tokenA,
        address tokenB,
        bool stable
    ) external returns (address pair);

    function reserves(address pair) external view returns (address reserve);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// Structure to capture time period obervations every 30 minutes, used for local oracles
struct Observation {
    uint256 timestamp;
    uint256 reserve0Cumulative;
    uint256 reserve1Cumulative;
}

interface IPairV1 is IERC20Metadata {
    // IERC20
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    // PairV1
    function claimFees() external returns (uint256, uint256);

    function tokens() external returns (address, address);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function mint(address to) external returns (uint256 liquidity);

    function getReserves()
        external
        view
        returns (
            uint256 _reserve0,
            uint256 _reserve1,
            uint256 _blockTimestampLast
        );

    function getReserveCumulatives() external view returns (uint256, uint256);

    function getObservationCount() external view returns (uint256);

    function observations(uint256 i) external view returns (Observation memory);

    function getAmountOut(uint256 amountIn, address tokenIn)
        external
        view
        returns (uint256 amountOut);

    function calcAmountOut(
        uint256 amountIn,
        address tokenIn,
        uint256 _reserve0,
        uint256 _reserve1
    ) external view returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ICalleeV1 {
    function hook(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function abs(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a - b : b - a;
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library TransferHelper {
    error EthTransferFailed();
    error Erc20TransferFailed();
    error Erc20ApproveFailed();

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        if (!success) {
            revert EthTransferFailed();
        }
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        // !success -> error
        // success and data = 0 -> ok
        // success and data = false -> error
        // success and data = true -> ok
        if (!success || (data.length > 0 && !abi.decode(data, (bool)))) {
            revert Erc20TransferFailed();
        }
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                value
            )
        );
        if (!success || (data.length > 0 && !abi.decode(data, (bool)))) {
            revert Erc20TransferFailed();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./libraries/TransferHelper.sol";

// Base V1 Fees contract is used as a 1:1 pair relationship to split out fees,
// this ensures that the curve does not need to be modified for LP shares
contract FeesV1 {
    error NotAuthorized();

    address private immutable pair;
    address private immutable token0;
    address private immutable token1;

    constructor(address _token0, address _token1) {
        pair = msg.sender;
        token0 = _token0;
        token1 = _token1;
    }

    /**
     * @notice Allow the pair to transfer fees to users
     * @param recipient Address of fee receiver
     * @param amount0 token0 amount
     * @param amount1 token1 amount
     */
    function claimFeesFor(
        address recipient,
        uint256 amount0,
        uint256 amount1
    ) external {
        if (msg.sender != pair) {
            revert NotAuthorized();
        }

        if (amount0 > 0)
            TransferHelper.safeTransfer(token0, recipient, amount0);
        if (amount1 > 0)
            TransferHelper.safeTransfer(token1, recipient, amount1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

abstract contract ReentrancyGuard {
    // simple re-entrancy check
    uint256 internal _unlocked = 1;

    modifier lock() {
        // solhint-disable-next-line
        require(_unlocked == 1, "reentrant");
        _unlocked = 2;
        _;
        _unlocked = 1;
    }
}