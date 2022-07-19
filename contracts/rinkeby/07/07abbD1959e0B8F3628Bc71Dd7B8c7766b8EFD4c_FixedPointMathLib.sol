/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

//  ██████╗ ███████╗███╗   ███╗███████╗██╗    ██╗ █████╗ ██████╗
// ██╔════╝ ██╔════╝████╗ ████║██╔════╝██║    ██║██╔══██╗██╔══██╗
// ██║  ███╗█████╗  ██╔████╔██║███████╗██║ █╗ ██║███████║██████╔╝
// ██║   ██║██╔══╝  ██║╚██╔╝██║╚════██║██║███╗██║██╔══██║██╔═══╝
// ╚██████╔╝███████╗██║ ╚═╝ ██║███████║╚███╔███╔╝██║  ██║██║
//  ╚═════╝ ╚══════╝╚═╝     ╚═╝╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*///////////////////////////////////////////////////////////////
                            COMMON BASE UNITS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant YAD = 1e8;
    uint256 internal constant WAD = 1e18;
    uint256 internal constant RAY = 1e27;
    uint256 internal constant RAD = 1e45;

    /*///////////////////////////////////////////////////////////////
                         FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function fmul(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(x == 0 || (x * y) / x == y)
            if iszero(or(iszero(x), eq(div(z, x), y))) {
                revert(0, 0)
            }

            // If baseUnit is zero this will return zero instead of reverting.
            z := div(z, baseUnit)
        }
    }

    function fdiv(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * baseUnit in z for now.
            z := mul(x, baseUnit)

            // Equivalent to require(y != 0 && (x == 0 || (x * baseUnit) / x == baseUnit))
            if iszero(and(iszero(iszero(y)), or(iszero(x), eq(div(z, x), baseUnit)))) {
                revert(0, 0)
            }

            // We ensure y is not zero above, so there is never division by zero here.
            z := div(z, y)
        }
    }

    function fpow(
        uint256 x,
        uint256 n,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := baseUnit
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store baseUnit in z for now.
                    z := baseUnit
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, baseUnit)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, baseUnit)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, baseUnit)
                    }
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z)
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z)
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z)
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z)
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z)
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z)
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
abstract contract GemswapERC20 {

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* -------------------------------------------------------------------------- */
    /*                                 ERC20 LOGIC                                */
    /* -------------------------------------------------------------------------- */

    string public constant name = 'Concave LP';
    string public constant symbol = 'CNV-LP';
    uint8 public constant decimals = 18;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    /* -------------------------------------------------------------------------- */
    /*                              EIP-2612 STORAGE                              */
    /* -------------------------------------------------------------------------- */

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    /* -------------------------------------------------------------------------- */
    /*                                 ERC20 LOGIC                                */
    /* -------------------------------------------------------------------------- */

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;
        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked { balanceOf[to] += amount; }
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;
        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked { totalSupply -= amount; }
        emit Transfer(from, address(0), amount);
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;
        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked { balanceOf[to] += amount; }
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
        unchecked { balanceOf[to] += amount; }
        emit Transfer(from, to, amount);
        return true;
    }

    /* -------------------------------------------------------------------------- */
    /*                               EIP-2612 LOGIC                               */
    /* -------------------------------------------------------------------------- */

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline, uint8 v, bytes32 r, bytes32 s
    ) external {
        require(deadline >= block.timestamp, 'UniswapV2: EXPIRED');
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    '\x19\x01',
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'UniswapV2: INVALID_SIGNATURE');
        }
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                block.chainid,
                address(this)
            )
        );
    }
}
contract GemswapPair is GemswapERC20 {

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    event Mint(address indexed sender, uint256 baseAmount, uint256 quoteAmount);
    event Burn(address indexed sender, uint256 baseAmount, uint256 quoteAmount, address indexed to);

    event Swap(
        address indexed sender,
        uint256 baseAmountIn,
        uint256 quoteAmountIn,
        uint256 baseAmountOut,
        uint256 quoteAmountOut,
        address indexed to
    );

    event Sync(uint112 reserve0, uint112 reserve1);

    /* -------------------------------------------------------------------------- */
    /*                                  CONSTANTS                                 */
    /* -------------------------------------------------------------------------- */

    // To avoid division by zero, there is a minimum number of liquidity tokens that always
    // exist (but are owned by account zero). That number is BIPS_DIVISOR, ten thousand.
    uint256 internal constant PRECISION = 112;
    uint256 internal constant BIPS_DIVISOR = 10_000;

    /* -------------------------------------------------------------------------- */
    /*                                MUTABLE STATE                               */
    /* -------------------------------------------------------------------------- */

    address public token0;
    address public token1;

    uint256 public swapFee;
    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;

    uint112 private reserve0;
    uint112 private reserve1;
    uint32  private blockTimestampLast;

    function getReserves() public view returns (uint112 _baseReserves, uint112 _quoteReserves, uint32 _lastUpdate) {
        (_baseReserves, _quoteReserves, _lastUpdate) = (reserve0, reserve1, blockTimestampLast);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  MODIFIERS                                 */
    /* -------------------------------------------------------------------------- */

    uint256 private reentrancyStatus;

    modifier nonReentrant() {
        require(reentrancyStatus == 1, "REENTRANCY");
        reentrancyStatus = 2;
        _;
        reentrancyStatus = 1;
    }

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */

    error INITIALIZED();

    // called once by the factory at time of deployment
    function initialize(
        address _base,
        address _quote,
        uint256 _swapFee
    ) external {
        if (swapFee > 0) revert INITIALIZED();
        (token0, token1, swapFee) = (_base, _quote, _swapFee);
        reentrancyStatus = 1; // init reentrance lock
    }

    error BALANCE_OVERFLOW();

    /// @notice update reserves and, on the first call per block, price accumulators
    function _update(
        uint256 baseBalance,
        uint256 quoteBalance,
        uint112 _baseReserves,
        uint112 _quoteReserves
    ) private {
        unchecked {
            // revert if either balance is greater than 2**112
            if (baseBalance > type(uint112).max || quoteBalance > type(uint112).max) revert BALANCE_OVERFLOW();
            // store current time in memory (mod 2**32 to prevent DoS in 20 years)
            uint32 timestampAdjusted = uint32(block.timestamp % 2**32);
            // store elapsed time since last update
            uint256 timeElapsed = timestampAdjusted - blockTimestampLast;

            // if oracle info hasn"t been updated this block, and there's liquidity, update TWAP variables
            if (timeElapsed > 0 && _baseReserves != 0 && _quoteReserves != 0) {
                price0CumulativeLast += ((uint256(_quoteReserves) << PRECISION) / _baseReserves) * timeElapsed;
                price1CumulativeLast += ((uint256(_baseReserves) << PRECISION) / _quoteReserves) * timeElapsed;
            }

            // sync reserves (make them match balances)
            (reserve0, reserve1, blockTimestampLast) = (uint112(baseBalance), uint112(quoteBalance), timestampAdjusted);
            // emit event since mutable storage was updated
            emit Sync(reserve0, reserve1);
        }
    }

    error INSUFFICIENT_LIQUIDITY_MINTED();

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external nonReentrant returns (uint256 liquidity) {
        // store any variables used more than once in memory to avoid SLOAD"s
        (uint112 _baseReserves, uint112 _quoteReserves,) = getReserves();
        uint256 baseBalance = GemswapERC20(token0).balanceOf(address(this));
        uint256 quoteBalance = GemswapERC20(token1).balanceOf(address(this));

        uint256 baseAmount = baseBalance - _baseReserves;
        uint256 quoteAmount = quoteBalance - _quoteReserves;


        uint256 _totalSupply = totalSupply;
        // if lp token total supply is equal to BIPS_DIVISOR (1,000 wei),
        // amountOut (liquidity) is equal to the root of k minus BIPS_DIVISOR
        if (_totalSupply == 0) {
            liquidity = FixedPointMathLib.sqrt(baseAmount * quoteAmount) - BIPS_DIVISOR;
            _mint(address(0), BIPS_DIVISOR);
        } else {
            liquidity = min(uDiv(baseAmount * _totalSupply, _baseReserves), uDiv(quoteAmount * _totalSupply, _quoteReserves));
        }
        // revert if Lp tokens out is equal to zero
        if (liquidity == 0) revert INSUFFICIENT_LIQUIDITY_MINTED();
        // mint liquidity providers LP tokens
        _mint(to, liquidity);
        // update mutable storage (reserves + cumulative oracle prices)
        _update(baseBalance, quoteBalance, _baseReserves, _quoteReserves);
        // emit event since mutable storage was updated
        emit Mint(msg.sender, baseAmount, quoteAmount);
    }

    error INSUFFICIENT_LIQUIDITY_BURNED();

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external nonReentrant returns (uint256 baseAmount, uint256 quoteAmount) {
        // store any variables used more than once in memory to avoid SLOAD"s
        (uint112 _baseReserves, uint112 _quoteReserves,) = getReserves();
        address _base = token0;
        address _quote = token1;
        uint256 baseBalance = GemswapERC20(_base).balanceOf(address(this));
        uint256 quoteBalance = GemswapERC20(_quote).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];
        uint256 _totalSupply = totalSupply;
        // division was originally unchecked, using balances ensures pro-rata distribution
        baseAmount = uDiv(liquidity * baseBalance, _totalSupply);
        quoteAmount = uDiv(liquidity * quoteBalance, _totalSupply);
        // revert if amountOuts are both equal to zero
        if (baseAmount == 0 && quoteAmount == 0) revert INSUFFICIENT_LIQUIDITY_BURNED();
        // burn LP tokens from this contract"s balance
        _burn(address(this), liquidity);
        // return liquidity providers underlying tokens
        TransferHelper.safeTransfer(_base, to, baseAmount);
        TransferHelper.safeTransfer(_quote, to, quoteAmount);
        // update mutable storage (reserves + cumulative oracle prices)
        _update(
            GemswapERC20(_base).balanceOf(address(this)),
            GemswapERC20(_quote).balanceOf(address(this)),
            _baseReserves,
            _quoteReserves
        );
        // emit event since mutable storage was updated
        emit Burn(msg.sender, baseAmount, quoteAmount, to);
    }

    error INSUFFICIENT_OUTPUT_AMOUNT();
    error INSUFFICIENT_LIQUIDITY();
    error INSUFFICIENT_INPUT_AMOUNT();
    error INSUFFICIENT_INVARIANT();
    error INAVLID_TO();

    /// @notice Optimistically swap tokens, will revert if K is not satisfied
    /// @param baseAmountOut - amount of token0 tokens user wants to receive
    /// @param quoteAmountOut - amount of token1 tokens user wants to receive
    /// @param to - recipient of 'output' tokens
    /// @param data - arbitrary data used during flashswaps
    function swap(
        uint256 baseAmountOut,
        uint256 quoteAmountOut,
        address to,
        bytes calldata data
    ) external nonReentrant {
        // revert if both amounts out are zero
        if (baseAmountOut == 0 && quoteAmountOut == 0) revert INSUFFICIENT_OUTPUT_AMOUNT();
        // store reserves in memory to avoid SLOAD"s
        (uint112 _baseReserves, uint112 _quoteReserves,) = getReserves();
        // revert if both amounts out
        if (baseAmountOut > _baseReserves || quoteAmountOut >=_quoteReserves) revert INSUFFICIENT_LIQUIDITY();
        // store any other variables used more than once in memory to avoid SLOAD"s & stack too deep errors
        uint256 baseAmountIn;
        uint256 quoteAmountIn;
        uint256 baseBalance;
        uint256 quoteBalance;

        {
        address _base = token0;
        address _quote = token1;
        // make sure not to send tokens to token contracts
        if (to == _base || to == _quote) revert INAVLID_TO();
        // optimistically transfer "to" token0 tokens
        // optimistically transfer "to" token1 tokens
        if (baseAmountOut > 0) TransferHelper.safeTransfer(_base, to, baseAmountOut);
        if (quoteAmountOut > 0) TransferHelper.safeTransfer(_quote, to, quoteAmountOut);
        // if data length is greater than 0, initiate flashswap
        if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, baseAmountOut, quoteAmountOut, data);
        // store token0 token balance of contract in memory
        // store token1 token balance of contract in memory
        baseBalance = GemswapERC20(_base).balanceOf(address(this));
        quoteBalance = GemswapERC20(_quote).balanceOf(address(this));
        }

        // Math was originally unchecked here
        unchecked {
            // calculate baseAmountIn by comparing contracts balance to last known reserve
            // calculate quoteAmountIn by comparing contracts balance to last known reserve
            if (baseBalance > _baseReserves - baseAmountOut) baseAmountIn = baseBalance - (_baseReserves - baseAmountOut);
            if (quoteBalance > _quoteReserves - quoteAmountOut) quoteAmountIn = quoteBalance - (_quoteReserves - quoteAmountOut);
        }
        // revert if user hasn't sent any tokens to the contract
        if (baseAmountIn == 0 && quoteAmountIn == 0) revert INSUFFICIENT_INPUT_AMOUNT();

        {
        // store swap fee in memory to save SLOAD
        uint256 _swapFee = swapFee;
        // calculate x, y adjusted to account for swap fees
        // revert if adjusted k (invariant) is less than old k
        uint256 baseBalanceAdjusted = baseBalance * BIPS_DIVISOR - baseAmountIn * _swapFee;
        uint256 quoteBalanceAdjusted = quoteBalance * BIPS_DIVISOR - quoteAmountIn * _swapFee;
        if (baseBalanceAdjusted * quoteBalanceAdjusted < uint256(_baseReserves) * _quoteReserves * 1e8) revert INSUFFICIENT_INVARIANT();
        }

        // update mutable storage (reserves + cumulative oracle prices first tx per block)
        _update(baseBalance, quoteBalance, _baseReserves, _quoteReserves);
        // emit event since mutable storage was updated
        emit Swap(msg.sender, baseAmountIn, quoteAmountIn, baseAmountOut, quoteAmountOut, to);
    }

    // force balances to match reserves
    function skim(address to) external nonReentrant {
        // store any variables used more than once in memory to avoid SLOAD"s
        address _base = token0;
        address _quote = token1;
        // transfer unaccounted reserves -> "to"
        TransferHelper.safeTransfer(_base, to, GemswapERC20(_base).balanceOf(address(this)) - reserve0);
        TransferHelper.safeTransfer(_quote, to, GemswapERC20(_quote).balanceOf(address(this)) - reserve1);
    }

    // force reserves to match balances
    function sync() external nonReentrant {
        _update(
            GemswapERC20(token0).balanceOf(address(this)),
            GemswapERC20(token1).balanceOf(address(this)),
            reserve0,
            reserve1
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                              INTERNAL HELPERS                              */
    /* -------------------------------------------------------------------------- */

    // unchecked division
    function uDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {assembly {z := div(x, y)}}

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {z = x < y ? x : y;}
}

// naming left for old contract support
interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external;
}