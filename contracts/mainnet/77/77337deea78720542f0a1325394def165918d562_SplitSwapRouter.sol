// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

/**
Optimal split order router for sushiswap, uni v2 (or fork) and uni v3 pools
*/

/// ============ Internal Imports ============
import "./interfaces/IWETH.sol";
import "./interfaces/IUniswapV3SwapCallback.sol";
import "./libraries/SplitSwapLibrary.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";

/// @title SplitSwapRouter
/// @author Sandy Bradley <@sandybradley>, ControlCplusControlV <@ControlCplusControlV>
/// @notice Splits swap order optimally across sushiswap, uniswap V2 and V3 (IUniswapV2Router compatible)
contract SplitSwapRouter is IUniswapV3SwapCallback {
    using SafeTransferLib for ERC20;

    // Custom errors save gas, encoding to 4 bytes
    error Expired();
    error InvalidPath();
    error InsufficientBAmount();
    error InsufficientAAmount();
    error TokenIsFeeOnTransfer();
    error ExcessiveInputAmount();
    error ExecuteNotAuthorized();
    error InsufficientOutputAmount();

    /// @dev UniswapV2 pool 4 byte swap selector
    bytes4 internal constant SWAP_SELECTOR = bytes4(keccak256("swap(uint256,uint256,address,bytes)"));
    /// @dev Governence for sweeping dust
    address internal GOV;
    /// @dev Wrapped native token address
    address internal immutable WETH09;
    /// @dev Sushiswap factory address
    address internal immutable SUSHI_FACTORY;
    /// @dev UniswapV2 factory address
    address internal immutable BACKUP_FACTORY; // uniswap v2 factory
    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
    /// @dev Sushiswap factory init pair code hash
    bytes32 internal immutable SUSHI_FACTORY_HASH;
    /// @dev UniswapV2 factory init pair code hash
    bytes32 internal immutable BACKUP_FACTORY_HASH;

    /// @notice constructor arguments for cross-chain deployment
    /// @param weth wrapped native token address (e.g. Eth mainnet: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2)
    /// @param sushiFactory Sushiswap factory address (e.g. Eth mainnet: 0xc35DADB65012eC5796536bD9864eD8773aBc74C4)
    /// @param backupFactory Uniswap V2 (or equiv.) (e.g. Eth mainnet: 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f)
    /// @param sushiFactoryHash Initial code hash of sushi factory (e.g. Eth mainnet: 0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303)SplitSwapRouter
    /// @param backupFactoryHash Initial code hash of backup (uniV2) factory (e.g. Eth mainnet: 0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f)SplitSwapRouter
    constructor(
        address weth,
        address sushiFactory,
        address backupFactory,
        bytes32 sushiFactoryHash,
        bytes32 backupFactoryHash
    ) {
        GOV = tx.origin;
        WETH09 = weth;
        SUSHI_FACTORY = sushiFactory;
        BACKUP_FACTORY = backupFactory;
        SUSHI_FACTORY_HASH = sushiFactoryHash;
        BACKUP_FACTORY_HASH = backupFactoryHash;
    }

    /// @notice reference sushi factory address (IUniswapV2Router compliance)
    function factory() external view returns (address) {
        return SUSHI_FACTORY;
    }

    /// @notice reference wrapped native token address (IUniswapV2Router compliance)
    function WETH() external view returns (address) {
        return WETH09;
    }

    /// @dev Callback for Uniswap V3 pool.
    /// @param amount0Delta amount of token0 (-ve indicates amountOut i.e. already transferred from v3 pool to here)
    /// @param amount1Delta amount of token0 (-ve indicates amountOut i.e. already transferred from v3 pool to here)
    /// @param data tokenIn,tokenOut and fee packed bytes
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override {
        address pool;
        address tokenIn;
        {
            uint24 fee;
            address tokenOut;
            (tokenIn, tokenOut, fee) = _decode(data); // custom decode packed (address, address, uint24)
            (address token0, address token1) = SplitSwapLibrary.sortTokens(tokenIn, tokenOut);
            pool = SplitSwapLibrary.uniswapV3PoolAddress(token0, token1, fee); // safest way to check pool address is valid and pool was the msg sender
        }
        if (msg.sender != pool) revert ExecuteNotAuthorized();
        // uni v3 optimistically sends tokenOut funds, then calls this function for the tokenIn amount
        if (amount0Delta > 0) ERC20(tokenIn).safeTransfer(msg.sender, uint256(amount0Delta));
        if (amount1Delta > 0) ERC20(tokenIn).safeTransfer(msg.sender, uint256(amount1Delta));
    }

    /// @notice Ensures deadline is not passed, otherwise revert.
    /// @dev Modifier has been replaced with a function for gas efficiency
    /// @param deadline Unix timestamp in seconds for transaction to execute before
    function ensure(uint256 deadline) internal view {
        if (deadline < block.timestamp) revert Expired();
    }

    /// @notice Checks amounts for token A and token B are balanced for pool. Creates a pair if none exists
    /// @dev Reverts with custom errors replace requires
    /// @param tokenA Token in pool
    /// @param tokenB Token in pool
    /// @param amountADesired Amount of token A desired to add to pool
    /// @param amountBDesired Amount of token B desired to add to pool
    /// @param amountAMin Minimum amount of token A, can be 0
    /// @param amountBMin Minimum amount of token B, can be 0
    /// @return amountA exact amount of token A to be added
    /// @return amountB exact amount of token B to be added
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn't exist yet
        address factory0 = SUSHI_FACTORY;
        if (IUniswapV2Factory(factory0).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(factory0).createPair(tokenA, tokenB);
        }
        (uint256 reserveA, uint256 reserveB) = SplitSwapLibrary.getReserves(
            factory0,
            tokenA,
            tokenB,
            SUSHI_FACTORY_HASH
        );
        if (_isZero(reserveA) && _isZero(reserveB)) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = SplitSwapLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal > amountBDesired) {
                uint256 amountAOptimal = SplitSwapLibrary.quote(amountBDesired, reserveB, reserveA);
                if (amountAOptimal > amountADesired) revert InsufficientAAmount();
                if (amountAOptimal < amountAMin) revert InsufficientAAmount();
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            } else {
                if (amountBOptimal < amountBMin) revert InsufficientBAmount();
                (amountA, amountB) = (amountADesired, amountBOptimal);
            }
        }
    }

    /// @notice Adds liquidity to an ERC-20⇄ERC-20 pool. msg.sender should have already given the router an allowance of at least amountADesired/amountBDesired on tokenA/tokenB
    /// @param tokenA Token in pool
    /// @param tokenB Token in pool
    /// @param amountADesired Amount of token A desired to add to pool
    /// @param amountBDesired Amount of token B desired to add to pool
    /// @param amountAMin Minimum amount of token A, can be 0
    /// @param amountBMin Minimum amount of token B, can be 0
    /// @param to Address to receive liquidity token
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amountA exact amount of token A added to pool
    /// @return amountB exact amount of token B added to pool
    /// @return liquidity amount of liquidity token received
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
        virtual
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        ensure(deadline);
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = SplitSwapLibrary.pairFor(SUSHI_FACTORY, tokenA, tokenB, SUSHI_FACTORY_HASH);
        ERC20(tokenA).safeTransferFrom(msg.sender, pair, amountA);
        ERC20(tokenB).safeTransferFrom(msg.sender, pair, amountB);
        liquidity = IUniswapV2Pair(pair).mint(to);
    }

    /// @notice Adds liquidity to an ERC-20⇄WETH pool with ETH. msg.sender should have already given the router an allowance of at least amountTokenDesired on token. msg.value is treated as a amountETHDesired. Leftover ETH, if any, is returned to msg.sender
    /// @param token Token in pool
    /// @param amountTokenDesired Amount of token desired to add to pool
    /// @param amountTokenMin Minimum amount of token, can be 0
    /// @param amountETHMin Minimum amount of ETH, can be 0
    /// @param to Address to receive liquidity token
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amountToken exact amount of token added to pool
    /// @return amountETH exact amount of ETH added to pool
    /// @return liquidity amount of liquidity token received
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
        virtual
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        ensure(deadline);
        address weth = WETH09;
        (amountToken, amountETH) = _addLiquidity(
            token,
            weth,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = SplitSwapLibrary.pairFor(SUSHI_FACTORY, token, weth, SUSHI_FACTORY_HASH);
        ERC20(token).safeTransferFrom(msg.sender, pair, amountToken);
        IWETH(weth).deposit{ value: amountETH }();
        ERC20(weth).safeTransfer(pair, amountETH);
        liquidity = IUniswapV2Pair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH && (msg.value - amountETH) > 21000 * block.basefee)
            SafeTransferLib.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    /// @notice Removes liquidity from an ERC-20⇄ERC-20 pool. msg.sender should have already given the router an allowance of at least liquidity on the pool.
    /// @param tokenA Token in pool
    /// @param tokenB Token in pool
    /// @param liquidity Amount of liquidity tokens to remove
    /// @param amountAMin Minimum amount of token A, can be 0
    /// @param amountBMin Minimum amount of token B, can be 0
    /// @param to Address to receive pool tokens
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amountA Amount of token A received
    /// @return amountB Amount of token B received
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public virtual returns (uint256 amountA, uint256 amountB) {
        ensure(deadline);
        address pair = SplitSwapLibrary.pairFor(SUSHI_FACTORY, tokenA, tokenB, SUSHI_FACTORY_HASH);
        ERC20(pair).safeTransferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint256 amount0, uint256 amount1) = IUniswapV2Pair(pair).burn(to);
        (address token0, ) = SplitSwapLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        if (amountA < amountAMin) revert InsufficientAAmount();
        if (amountB < amountBMin) revert InsufficientBAmount();
    }

    /// @notice Removes liquidity from an ERC-20⇄WETH pool and receive ETH. msg.sender should have already given the router an allowance of at least liquidity on the pool.
    /// @param token Token in pool
    /// @param liquidity Amount of liquidity tokens to remove
    /// @param amountTokenMin Minimum amount of token, can be 0
    /// @param amountETHMin Minimum amount of ETH, can be 0
    /// @param to Address to receive pool tokens
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amountToken Amount of token received
    /// @return amountETH Amount of ETH received
    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual returns (uint256 amountToken, uint256 amountETH) {
        address weth = WETH09;
        uint256 balanceBefore = ERC20(token).balanceOf(address(this));
        (amountToken, amountETH) = removeLiquidity(
            token,
            weth,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        // exploit check from fee-on-transfer tokens
        if (amountToken != ERC20(token).balanceOf(address(this)) - balanceBefore) revert TokenIsFeeOnTransfer();
        ERC20(token).safeTransfer(to, amountToken);
        IWETH(weth).withdraw(amountETH);
        SafeTransferLib.safeTransferETH(to, amountETH);
    }

    /// @notice Removes liquidity from an ERC-20⇄ERC-20 pool without pre-approval, thanks to permit.
    /// @param tokenA Token in pool
    /// @param tokenB Token in pool
    /// @param liquidity Amount of liquidity tokens to remove
    /// @param amountAMin Minimum amount of token A, can be 0
    /// @param amountBMin Minimum amount of token B, can be 0
    /// @param to Address to receive pool tokens
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @param approveMax Whether or not the approval amount in the signature is for liquidity or uint(-1)
    /// @param v The v component of the permit signature
    /// @param r The r component of the permit signature
    /// @param s The s component of the permit signature
    /// @return amountA Amount of token A received
    /// @return amountB Amount of token B received
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
    ) external virtual returns (uint256 amountA, uint256 amountB) {
        IUniswapV2Pair(SplitSwapLibrary.pairFor(SUSHI_FACTORY, tokenA, tokenB, SUSHI_FACTORY_HASH)).permit(
            msg.sender,
            address(this),
            approveMax ? type(uint256).max : liquidity,
            deadline,
            v,
            r,
            s
        );
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }

    /// @notice Removes liquidity from an ERC-20⇄WETTH pool and receive ETH without pre-approval, thanks to permit
    /// @param token Token in pool
    /// @param liquidity Amount of liquidity tokens to remove
    /// @param amountTokenMin Minimum amount of token, can be 0
    /// @param amountETHMin Minimum amount of ETH, can be 0
    /// @param to Address to receive pool tokens
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @param approveMax Whether or not the approval amount in the signature is for liquidity or uint(-1)
    /// @param v The v component of the permit signature
    /// @param r The r component of the permit signature
    /// @param s The s component of the permit signature
    /// @return amountToken Amount of token received
    /// @return amountETH Amount of ETH received
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
    ) external virtual returns (uint256 amountToken, uint256 amountETH) {
        IUniswapV2Pair(SplitSwapLibrary.pairFor(SUSHI_FACTORY, token, WETH09, SUSHI_FACTORY_HASH)).permit(
            msg.sender,
            address(this),
            approveMax ? type(uint256).max : liquidity,
            deadline,
            v,
            r,
            s
        );
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    /// @notice Identical to removeLiquidityETH, but succeeds for tokens that take a fee on transfer. msg.sender should have already given the router an allowance of at least liquidity on the pool.
    /// @param token Token in pool
    /// @param liquidity Amount of liquidity tokens to remove
    /// @param amountTokenMin Minimum amount of token, can be 0
    /// @param amountETHMin Minimum amount of ETH, can be 0
    /// @param to Address to receive pool tokens
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amountETH Amount of ETH received
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual returns (uint256 amountETH) {
        address weth = WETH09;
        uint256 balanceBefore = ERC20(token).balanceOf(address(this));
        (, amountETH) = removeLiquidity(token, weth, liquidity, amountTokenMin, amountETHMin, address(this), deadline);
        ERC20(token).safeTransfer(to, ERC20(token).balanceOf(address(this)) - balanceBefore);
        IWETH(weth).withdraw(amountETH);
        SafeTransferLib.safeTransferETH(to, amountETH);
    }

    /// @notice Identical to removeLiquidityETHWithPermit, but succeeds for tokens that take a fee on transfer.
    /// @param token Token in pool
    /// @param liquidity Amount of liquidity tokens to remove
    /// @param amountTokenMin Minimum amount of token, can be 0
    /// @param amountETHMin Minimum amount of ETH, can be 0
    /// @param to Address to receive pool tokens
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @param approveMax Whether or not the approval amount in the signature is for liquidity or uint(-1)
    /// @param v The v component of the permit signature
    /// @param r The r component of the permit signature
    /// @param s The s component of the permit signature
    /// @return amountETH Amount of ETH received
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
    ) external virtual returns (uint256 amountETH) {
        IUniswapV2Pair(SplitSwapLibrary.pairFor(SUSHI_FACTORY, token, WETH09, SUSHI_FACTORY_HASH)).permit(
            msg.sender,
            address(this),
            approveMax ? type(uint256).max : liquidity,
            deadline,
            v,
            r,
            s
        );
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }

    /// @dev single swap for uni v2 pair. Requires the initial amount to have already been sent to the first pair.
    /// @param isReverse true if token0 == tokenOut
    /// @param to swap recipient
    /// @param pair pair address
    /// @param amountOut expected amount out
    function _swapSingle(
        bool isReverse,
        address to,
        address pair,
        uint256 amountOut
    ) internal virtual {
        (uint256 amount0Out, uint256 amount1Out) = isReverse ? (amountOut, uint256(0)) : (uint256(0), amountOut);
        _asmSwap(pair, amount0Out, amount1Out, to);
    }

    /// @dev single swap for uni v3 pool
    /// @param isReverse true if token0 == tokenOut
    /// @param fee fee of pool as a ratio of 1000000
    /// @param to swap recipient
    /// @param tokenIn token in address
    /// @param tokenOut token out address
    /// @param pair pair address
    /// @param amountIn amount of tokenIn
    function _swapUniV3(
        bool isReverse,
        uint24 fee,
        address to,
        address tokenIn,
        address tokenOut,
        address pair,
        uint256 amountIn
    ) internal virtual returns (uint256 amountInActual, uint256 amountOut) {
        bytes memory data = abi.encodePacked(tokenIn, tokenOut, fee);
        uint160 sqrtPriceLimitX96 = isReverse ? MAX_SQRT_RATIO - 1 : MIN_SQRT_RATIO + 1;
        (int256 amount0, int256 amount1) = IUniswapV3Pool(pair).swap(
            to,
            !isReverse,
            int256(amountIn),
            sqrtPriceLimitX96,
            data
        );
        amountOut = isReverse ? uint256(-(amount0)) : uint256(-(amount1));
        amountInActual = isReverse ? uint256(amount1) : uint256(amount0);
    }

    /// @dev Internal core swap. Requires the initial amount to have already been sent to the first pair (for v2 pairs).
    /// @param _to Address of receiver
    /// @param swaps Array of user swap data
    function _swap(address _to, SplitSwapLibrary.Swap[] memory swaps)
        internal
        virtual
        returns (uint256[] memory amounts)
    {
        uint256 length = swaps.length;
        amounts = new uint256[](_inc(length));
        for (uint256 i; i < 5; i = _inc(i)) {
            amounts[0] = amounts[0] + swaps[0].pools[i].amountIn; // gather amounts in from each route
        }

        for (uint256 i; i < length; i = _inc(i)) {
            address to = i < _dec(length) ? address(this) : _to; // split route requires intermediate swaps route to this address
            // V2 swaps
            for (uint256 j; j < 2; j = _inc(j)) {
                if (_isNonZero(swaps[i].pools[j].amountIn)) {
                    // first v2 swap amountIn has been transfered to pair
                    // subseqent swaps will need to transfer to next pair
                    // uint256 balBefore = ERC20(swaps[i].tokenOut).balanceOf(to);
                    if (_isNonZero(i))
                        ERC20(swaps[i].tokenIn).safeTransfer(swaps[i].pools[j].pair, swaps[i].pools[j].amountIn);
                    _swapSingle(swaps[i].isReverse, to, swaps[i].pools[j].pair, swaps[i].pools[j].amountOut); // single v2 swap
                    amounts[_inc(i)] = amounts[_inc(i)] + swaps[i].pools[j].amountOut;
                    // amounts[_inc(i)] = amounts[_inc(i)] + ERC20(swaps[i].tokenOut).balanceOf(to) - balBefore;
                }
            }
            // V3 swaps
            for (uint256 j = 2; j < 5; j = _inc(j)) {
                if (_isNonZero(swaps[i].pools[j].amountIn)) {
                    (uint256 amountInActual, uint256 amountOut) = _swapUniV3(
                        swaps[i].isReverse,
                        uint24(SplitSwapLibrary.getFee(j)),
                        to,
                        swaps[i].tokenIn,
                        swaps[i].tokenOut,
                        swaps[i].pools[j].pair,
                        swaps[i].pools[j].amountIn
                    ); // single v3 swap
                    amounts[_inc(i)] = amounts[_inc(i)] + amountOut;
                    // Edge Case: adjust next swap amount in if less than expected returned
                    if (i < _dec(length) && amountOut < swaps[i].pools[j].amountOut) {
                        if (swaps[i].pools[j].amountIn > amountInActual) {
                            amounts[i] = amounts[i] + amountInActual - swaps[i].pools[j].amountIn;
                        }
                        for (uint256 k; k < 5; k = _inc(k)) {
                            if (
                                _isNonZero(swaps[_inc(i)].pools[k].amountIn) &&
                                swaps[_inc(i)].pools[k].amountIn > (swaps[i].pools[j].amountOut - amountOut)
                            ) {
                                swaps[_inc(i)].pools[k].amountIn =
                                    swaps[_inc(i)].pools[k].amountIn +
                                    amountOut -
                                    swaps[i].pools[j].amountOut;
                                break;
                            }
                        }
                    }
                }
            }
        }
    }

    /// @notice Swaps an exact amount of input tokens for as many output tokens as possible, along the route determined by the path. The first element of path is the input token, the last is the output token, and any intermediate elements represent intermediate pairs to trade through. msg.sender should have already given the router an allowance of at least amountIn on the input token.
    /// @dev Require has been replaced with revert for gas optimization. Fallback alternate router check for insufficient output amount. Attempt to back-run swaps.
    /// @param amountIn Amount of input tokens to send.
    /// @param amountOutMin Minimum amount of output tokens that must be received
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amounts Array of input token amount and all subsequent output token amounts
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual returns (uint256[] memory amounts) {
        ensure(deadline);
        SplitSwapLibrary.Swap[] memory swaps = SplitSwapLibrary.getSwapsOut(
            SUSHI_FACTORY,
            BACKUP_FACTORY,
            amountIn,
            SUSHI_FACTORY_HASH,
            BACKUP_FACTORY_HASH,
            path
        );
        for (uint256 i; i < 2; i = _inc(i)) {
            if (_isNonZero(swaps[0].pools[i].amountIn))
                ERC20(path[0]).safeTransferFrom(msg.sender, swaps[0].pools[i].pair, swaps[0].pools[i].amountIn);
        }
        uint256 amountInV3;
        for (uint256 i = 2; i < 5; i = _inc(i)) {
            if (_isNonZero(swaps[0].pools[i].amountIn)) amountInV3 = amountInV3 + swaps[0].pools[i].amountIn;
        }
        if (_isNonZero(amountInV3)) ERC20(path[0]).safeTransferFrom(msg.sender, address(this), amountInV3);
        amounts = _swap(to, swaps);
        if (amountOutMin > amounts[_dec(path.length)]) revert InsufficientOutputAmount();
        //  refund V3 dust if any
        if (amounts[0] < amountIn) ERC20(path[0]).safeTransfer(msg.sender, amountIn - amounts[0]);
    }

    /// @notice Receive an exact amount of output tokens for as few input tokens as possible, along the route determined by the path. msg.sender should have already given the router an allowance of at least amountInMax on the input token.
    /// @dev Require has been replaced with revert for gas optimization. Fallback alternate router check for insufficient output amount. Attempt to back-run swaps.
    /// @param amountOut Amount of output tokens to receive
    /// @param amountInMax Maximum amount of input tokens
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amounts Array of input token amount and all subsequent output token amounts
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual returns (uint256[] memory amounts) {
        ensure(deadline);

        SplitSwapLibrary.Swap[] memory swaps = SplitSwapLibrary.getSwapsIn(
            SUSHI_FACTORY,
            BACKUP_FACTORY,
            amountOut,
            SUSHI_FACTORY_HASH,
            BACKUP_FACTORY_HASH,
            path
        );
        uint256 amountIn;
        for (uint256 i = 2; i < 5; i = _inc(i)) {
            if (_isNonZero(swaps[0].pools[i].amountIn)) amountIn = amountIn + swaps[0].pools[i].amountIn;
        }

        if (_isNonZero(amountIn)) ERC20(path[0]).safeTransferFrom(msg.sender, address(this), amountIn);

        for (uint256 i; i < 2; i = _inc(i)) {
            if (_isNonZero(swaps[0].pools[i].amountIn)) {
                ERC20(path[0]).safeTransferFrom(msg.sender, swaps[0].pools[i].pair, swaps[0].pools[i].amountIn);
                amountIn = amountIn + swaps[0].pools[i].amountIn;
            }
        }
        amounts = _swap(to, swaps);
        if (amountInMax < amounts[0]) revert ExcessiveInputAmount();
        //  refund V3 dust if any
        if (amounts[0] < amountIn) ERC20(path[0]).safeTransfer(msg.sender, amountIn - amounts[0]);
    }

    /// @notice Swaps an exact amount of ETH for as many output tokens as possible, along the route determined by the path. The first element of path must be WETH, the last is the output token. amountIn = msg.value
    /// @dev Require has been replaced with revert for gas optimization. Fallback alternate router check for insufficient output amount. Attempt to back-run swaps.
    /// @param amountOutMin Minimum amount of output tokens that must be received
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amounts Array of input token amount and all subsequent output token amounts
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual returns (uint256[] memory amounts) {
        ensure(deadline);
        address weth = WETH09;
        if (path[0] != weth) revert InvalidPath();
        SplitSwapLibrary.Swap[] memory swaps = SplitSwapLibrary.getSwapsOut(
            SUSHI_FACTORY,
            BACKUP_FACTORY,
            msg.value,
            SUSHI_FACTORY_HASH,
            BACKUP_FACTORY_HASH,
            path
        );
        IWETH(weth).deposit{ value: msg.value }();
        for (uint256 i; i < 2; i = _inc(i)) {
            if (_isNonZero(swaps[0].pools[i].amountIn))
                ERC20(weth).safeTransfer(swaps[0].pools[i].pair, swaps[0].pools[i].amountIn);
        }
        amounts = _swap(to, swaps);
        if (amountOutMin > amounts[_dec(path.length)]) revert InsufficientOutputAmount();
        //  refund V3 dust if any
        if (amounts[0] < msg.value && (msg.value - amounts[0]) > 21000 * block.basefee) {
            IWETH(weth).withdraw(msg.value - amounts[0]);
            SafeTransferLib.safeTransferETH(msg.sender, msg.value - amounts[0]);
        }
    }

    /// @notice Receive an exact amount of ETH for as few input tokens as possible, along the route determined by the path. The first element of path is the input token, the last must be WETH. msg.sender should have already given the router an allowance of at least amountInMax on the input token.
    /// @dev Require has been replaced with revert for gas optimization. Fallback alternate router check for insufficient output amount. Attempt to back-run swaps.
    /// @param amountOut Amount of ETH to receive
    /// @param amountInMax Maximum amount of input tokens
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amounts Array of input token amount and all subsequent output token amounts
    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual returns (uint256[] memory amounts) {
        ensure(deadline);
        address weth = WETH09;
        if (path[_dec(path.length)] != weth) revert InvalidPath();
        SplitSwapLibrary.Swap[] memory swaps = SplitSwapLibrary.getSwapsIn(
            SUSHI_FACTORY,
            BACKUP_FACTORY,
            amountOut,
            SUSHI_FACTORY_HASH,
            BACKUP_FACTORY_HASH,
            path
        );
        for (uint256 i; i < 2; i = _inc(i)) {
            if (_isNonZero(swaps[0].pools[i].amountIn))
                ERC20(path[0]).safeTransferFrom(msg.sender, swaps[0].pools[i].pair, swaps[0].pools[i].amountIn);
        }
        uint256 amountIn;
        for (uint256 i = 2; i < 5; i = _inc(i)) {
            if (_isNonZero(swaps[0].pools[i].amountIn)) amountIn = amountIn + swaps[0].pools[i].amountIn;
        }
        if (_isNonZero(amountIn)) ERC20(path[0]).safeTransferFrom(msg.sender, address(this), amountIn);
        amounts = _swap(address(this), swaps);
        if (amountInMax < amounts[0]) revert ExcessiveInputAmount();
        IWETH(weth).withdraw(amounts[_dec(path.length)]);
        SafeTransferLib.safeTransferETH(to, amounts[_dec(path.length)]);
        //  refund V3 dust if any
        if (amounts[0] < amountIn) ERC20(path[0]).safeTransfer(msg.sender, amountIn - amounts[0]);
    }

    /// @notice Swaps an exact amount of tokens for as much ETH as possible, along the route determined by the path. The first element of path is the input token, the last must be WETH.
    /// @dev Require has been replaced with revert for gas optimization. Fallback alternate router check for insufficient output amount. Attempt to back-run swaps.
    /// @param amountIn Amount of input tokens to send.
    /// @param amountOutMin Minimum amount of ETH that must be received
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amounts Array of input token amount and all subsequent output token amounts
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual returns (uint256[] memory amounts) {
        ensure(deadline);
        address weth = WETH09;
        if (path[_dec(path.length)] != weth) revert InvalidPath();
        SplitSwapLibrary.Swap[] memory swaps = SplitSwapLibrary.getSwapsOut(
            SUSHI_FACTORY,
            BACKUP_FACTORY,
            amountIn,
            SUSHI_FACTORY_HASH,
            BACKUP_FACTORY_HASH,
            path
        );
        for (uint256 i; i < 2; i = _inc(i)) {
            if (_isNonZero(swaps[0].pools[i].amountIn))
                ERC20(path[0]).safeTransferFrom(msg.sender, swaps[0].pools[i].pair, swaps[0].pools[i].amountIn);
        }
        for (uint256 i = 2; i < 5; i = _inc(i)) {
            if (_isNonZero(swaps[0].pools[i].amountIn))
                ERC20(path[0]).safeTransferFrom(msg.sender, address(this), swaps[0].pools[i].amountIn);
        }
        amounts = _swap(address(this), swaps);
        uint256 amountOut = amounts[_dec(path.length)];
        if (amountOutMin > amountOut) revert InsufficientOutputAmount();
        IWETH(weth).withdraw(amountOut);
        SafeTransferLib.safeTransferETH(to, amountOut);
        //  refund V3 dust if any
        if (amounts[0] < amountIn) ERC20(path[0]).safeTransfer(msg.sender, amountIn - amounts[0]);
    }

    /// @notice Receive an exact amount of tokens for as little ETH as possible, along the route determined by the path. The first element of path must be WETH. Leftover ETH, if any, is returned to msg.sender. amountInMax = msg.value
    /// @dev Require has been replaced with revert for gas optimization. Fallback alternate router check for insufficient output amount. Attempt to back-run swaps.
    /// @param amountOut Amount of output tokens that must be received
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amounts Array of input token amount and all subsequent output token amounts
    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual returns (uint256[] memory amounts) {
        ensure(deadline);
        address weth = WETH09;
        if (path[0] != weth) revert InvalidPath();
        SplitSwapLibrary.Swap[] memory swaps = SplitSwapLibrary.getSwapsIn(
            SUSHI_FACTORY,
            BACKUP_FACTORY,
            amountOut,
            SUSHI_FACTORY_HASH,
            BACKUP_FACTORY_HASH,
            path
        );
        uint256 amountIn;
        for (uint256 i; i < 5; i = _inc(i)) {
            amountIn = amountIn + swaps[0].pools[i].amountIn;
        }
        if (msg.value < amountIn) revert ExcessiveInputAmount();
        IWETH(weth).deposit{ value: amountIn }();
        for (uint256 i; i < 2; i = _inc(i)) {
            if (_isNonZero(swaps[0].pools[i].amountIn))
                ERC20(weth).safeTransfer(swaps[0].pools[i].pair, swaps[0].pools[i].amountIn);
        }
        amounts = _swap(to, swaps);
        if (msg.value < amounts[0]) revert ExcessiveInputAmount();
        // refund dust eth, if any
        if (msg.value > amountIn && (msg.value - amountIn) > 21000 * block.basefee)
            SafeTransferLib.safeTransferETH(msg.sender, msg.value - amountIn);
    }

    function _swapSupportingFeeOnTransferTokens(address _to, SplitSwapLibrary.Swap[] memory swaps)
        internal
        virtual
        returns (uint256[] memory amounts)
    {
        uint256 length = swaps.length;
        amounts = new uint256[](_inc(length));
        for (uint256 i; i < 5; i = _inc(i)) {
            amounts[0] = amounts[0] + swaps[0].pools[i].amountIn; // gather amounts in from each route
        }

        for (uint256 i; i < length; i = _inc(i)) {
            address to = i < _dec(length) ? address(this) : _to; // split route requires intermediate swaps route to this address
            // V2 swaps
            for (uint256 j; j < 2; j = _inc(j)) {
                if (_isNonZero(swaps[i].pools[j].amountIn)) {
                    // first v2 swap amountIn has been transfered to pair
                    // subseqent swaps will need to transfer to next pair
                    uint256 balBefore = ERC20(swaps[i].tokenOut).balanceOf(to);
                    if (_isNonZero(i))
                        ERC20(swaps[i].tokenIn).safeTransfer(swaps[i].pools[j].pair, swaps[i].pools[j].amountIn);
                    uint256 amountOut;
                    {
                        (uint256 reserveIn, uint256 reserveOut, ) = IUniswapV2Pair(swaps[i].pools[j].pair)
                            .getReserves();
                        (reserveIn, reserveOut) = swaps[i].isReverse
                            ? (reserveOut, reserveIn)
                            : (reserveIn, reserveOut);
                        amountOut = SplitSwapLibrary.getAmountOut(
                            ERC20(swaps[i].tokenIn).balanceOf(swaps[i].pools[j].pair) - reserveIn,
                            reserveIn,
                            reserveOut
                        );
                    }
                    _swapSingle(swaps[i].isReverse, to, swaps[i].pools[j].pair, amountOut); // single v2 swap
                    amounts[_inc(i)] = amounts[_inc(i)] + ERC20(swaps[i].tokenOut).balanceOf(to) - balBefore;
                }
            }
            // V3 swaps
            for (uint256 j = 2; j < 5; j = _inc(j)) {
                uint24 fee = uint24(SplitSwapLibrary.getFee(j));
                if (_isNonZero(swaps[i].pools[j].amountIn)) {
                    (uint256 amountInActual, uint256 amountOut) = _swapUniV3(
                        swaps[i].isReverse,
                        fee,
                        to,
                        swaps[i].tokenIn,
                        swaps[i].tokenOut,
                        swaps[i].pools[j].pair,
                        swaps[i].pools[j].amountIn
                    ); // single v3 swap
                    amounts[_inc(i)] = amounts[_inc(i)] + amountOut;
                    // Edge Case: adjust next swap amount in if less than expected returned
                    if (i < _dec(length) && amountOut < swaps[i].pools[j].amountOut) {
                        if (swaps[i].pools[j].amountIn > amountInActual) {
                            amounts[i] = amounts[i] + amountInActual - swaps[i].pools[j].amountIn;
                        }
                        for (uint256 k; k < 5; k = _inc(k)) {
                            if (
                                _isNonZero(swaps[_inc(i)].pools[k].amountIn) &&
                                swaps[_inc(i)].pools[k].amountIn > (swaps[i].pools[j].amountOut - amountOut)
                            ) {
                                swaps[_inc(i)].pools[k].amountIn =
                                    swaps[_inc(i)].pools[k].amountIn +
                                    amountOut -
                                    swaps[i].pools[j].amountOut;
                                break;
                            }
                        }
                    }
                }
            }
        }
    }

    /// @notice Identical to swapExactTokensForTokens, but succeeds for tokens that take a fee on transfer. msg.sender should have already given the router an allowance of at least amountIn on the input token.
    /// @dev Require has been replaced with revert for gas optimization. Attempt to back-run swaps.
    /// @param amountIn Amount of input tokens to send.
    /// @param amountOutMin Minimum amount of output tokens that must be received
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual {
        ensure(deadline);
        SplitSwapLibrary.Swap[] memory swaps = SplitSwapLibrary.getSwapsOut(
            SUSHI_FACTORY,
            BACKUP_FACTORY,
            amountIn,
            SUSHI_FACTORY_HASH,
            BACKUP_FACTORY_HASH,
            path
        );
        for (uint256 i; i < 2; i = _inc(i)) {
            if (_isNonZero(swaps[0].pools[i].amountIn))
                ERC20(path[0]).safeTransferFrom(msg.sender, swaps[0].pools[i].pair, swaps[0].pools[i].amountIn);
        }
        for (uint256 i = 2; i < 5; i = _inc(i)) {
            if (_isNonZero(swaps[0].pools[i].amountIn))
                ERC20(path[0]).safeTransferFrom(msg.sender, address(this), swaps[0].pools[i].amountIn);
        }
        uint256[] memory amounts = _swapSupportingFeeOnTransferTokens(to, swaps);
        if (amountOutMin > amounts[_dec(path.length)]) revert InsufficientOutputAmount();
    }

    /// @notice Identical to swapExactETHForTokens, but succeeds for tokens that take a fee on transfer. amountIn = msg.value
    /// @dev Require has been replaced with revert for gas optimization. Attempt to back-run swaps.
    /// @param amountOutMin Minimum amount of output tokens that must be received
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual {
        ensure(deadline);
        address weth = WETH09;
        if (path[0] != weth) revert InvalidPath();
        SplitSwapLibrary.Swap[] memory swaps = SplitSwapLibrary.getSwapsOut(
            SUSHI_FACTORY,
            BACKUP_FACTORY,
            msg.value,
            SUSHI_FACTORY_HASH,
            BACKUP_FACTORY_HASH,
            path
        );
        IWETH(weth).deposit{ value: msg.value }();
        for (uint256 i; i < 2; i = _inc(i)) {
            if (_isNonZero(swaps[0].pools[i].amountIn))
                ERC20(weth).safeTransfer(swaps[0].pools[i].pair, swaps[0].pools[i].amountIn);
        }
        uint256[] memory amounts = _swapSupportingFeeOnTransferTokens(to, swaps);
        if (amountOutMin > amounts[_dec(path.length)]) revert InsufficientOutputAmount();
    }

    /// @notice Identical to swapExactTokensForETH, but succeeds for tokens that take a fee on transfer.
    /// @dev Require has been replaced with revert for gas optimization. Attempt to back-run swaps.
    /// @param amountIn Amount of input tokens to send.
    /// @param amountOutMin Minimum amount of ETH that must be received
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual {
        ensure(deadline);
        address weth = WETH09;
        if (path[_dec(path.length)] != weth) revert InvalidPath();
        SplitSwapLibrary.Swap[] memory swaps = SplitSwapLibrary.getSwapsOut(
            SUSHI_FACTORY,
            BACKUP_FACTORY,
            amountIn,
            SUSHI_FACTORY_HASH,
            BACKUP_FACTORY_HASH,
            path
        );
        for (uint256 i; i < 2; i = _inc(i)) {
            if (_isNonZero(swaps[0].pools[i].amountIn))
                ERC20(path[0]).safeTransferFrom(msg.sender, swaps[0].pools[i].pair, swaps[0].pools[i].amountIn);
        }
        for (uint256 i = 2; i < 5; i = _inc(i)) {
            if (_isNonZero(swaps[0].pools[i].amountIn))
                ERC20(path[0]).safeTransferFrom(msg.sender, address(this), swaps[0].pools[i].amountIn);
        }
        uint256[] memory amounts = _swapSupportingFeeOnTransferTokens(address(this), swaps);
        uint256 amountOut = amounts[_dec(path.length)];
        if (amountOutMin > amountOut) revert InsufficientOutputAmount();
        IWETH(weth).withdraw(amountOut);
        SafeTransferLib.safeTransferETH(to, amountOut);
    }

    /// @notice Zero fee quote
    /// @param amountA amount In
    /// @param reserveA reserve of tokenA
    /// @param reserveB reserve of tokenB
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure virtual returns (uint256 amountB) {
        return SplitSwapLibrary.quote(amountA, reserveA, reserveB);
    }

    /// @notice Exact amount out, from Sushiswap, at current state, accounting for fee and slippage
    /// @param amountIn amount In
    /// @param reserveIn reserve of tokenIn
    /// @param reserveOut reserve of tokenOut
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure virtual returns (uint256 amountOut) {
        return SplitSwapLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    /// @notice Exact amount in, from Sushiswap, at current state, accounting for fee and slippage
    /// @param amountOut amount Out
    /// @param reserveIn reserve of tokenIn
    /// @param reserveOut reserve of tokenOut
    /// @return amountIn
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure virtual returns (uint256 amountIn) {
        return SplitSwapLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    /// @notice Optimal Amounts out, from split swap, at current state, accounting for fees and slippage
    /// @param amountIn amount In
    /// @param path array of token addresses representing path of swap
    /// @return amounts array corresponding to path
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        virtual
        returns (uint256[] memory amounts)
    {
        SplitSwapLibrary.Swap[] memory swaps = SplitSwapLibrary.getSwapsOut(
            SUSHI_FACTORY,
            BACKUP_FACTORY,
            amountIn,
            SUSHI_FACTORY_HASH,
            BACKUP_FACTORY_HASH,
            path
        );
        uint256 length = swaps.length;
        amounts = new uint256[](_inc(length));
        for (uint256 i; i < length; i = _inc(i)) {
            for (uint256 j; j < 5; j = _inc(j)) {
                amounts[i] = amounts[i] + swaps[i].pools[j].amountIn;
                if (i == _dec(length)) amounts[_inc(i)] = amounts[_inc(i)] + swaps[i].pools[j].amountOut;
            }
        }
    }

    /// @notice Optimal Amounts in, from split swap, at current state, accounting for fees and slippage
    /// @param amountOut amount Out
    /// @param path array of token addresses representing path of swap
    /// @return amounts array corresponding to path
    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        virtual
        returns (uint256[] memory amounts)
    {
        SplitSwapLibrary.Swap[] memory swaps = SplitSwapLibrary.getSwapsIn(
            SUSHI_FACTORY,
            BACKUP_FACTORY,
            amountOut,
            SUSHI_FACTORY_HASH,
            BACKUP_FACTORY_HASH,
            path
        );
        uint256 length = swaps.length;
        amounts = new uint256[](_inc(length));
        for (uint256 i; i < length; i = _inc(i)) {
            for (uint256 j; j < 5; j = _inc(j)) {
                if (_isZero(i)) amounts[i] = amounts[i] + swaps[i].pools[j].amountIn;
                amounts[_inc(i)] = amounts[_inc(i)] + swaps[i].pools[j].amountOut;
            }
        }
    }

    /// @custom:assembly Efficient single swap call
    /// @notice Internal call to perform single swap
    /// @param pair Address of pair to swap in
    /// @param amount0Out AmountOut for token0 of pair
    /// @param amount1Out AmountOut for token1 of pair
    /// @param to Address of receiver
    function _asmSwap(
        address pair,
        uint256 amount0Out,
        uint256 amount1Out,
        address to
    ) internal {
        bytes4 selector = SWAP_SELECTOR;
        assembly ("memory-safe") {
            let ptr := mload(0x40) // get free memory pointer
            mstore(ptr, selector) // append 4 byte selector
            mstore(add(ptr, 0x04), amount0Out) // append amount0Out
            mstore(add(ptr, 0x24), amount1Out) // append amount1Out
            mstore(add(ptr, 0x44), to) // append to
            mstore(add(ptr, 0x64), 0x80) // append location of byte list
            mstore(add(ptr, 0x84), 0) // append 0 bytes data
            let success := call(
                gas(), // gas remaining
                pair, // destination address
                0, // 0 value
                ptr, // input buffer
                0xA4, // input length
                0, // output buffer
                0 // output length
            )

            if iszero(success) {
                // 0 size error is the cheapest, but mstore an error enum if you wish
                revert(0x0, 0x0)
            }
        }
    }

    /// @custom:assembly De-compresses 2 addresses and 1 uint24 from byte stream (len = 43)
    /// @notice De-compresses 2 addresses and 1 uint24 from byte stream (len = 43)
    /// @param data Compressed byte stream
    /// @return a Address of first param
    /// @return b Address of second param
    /// @return fee (0.3% => 3000 ...)
    function _decode(bytes memory data)
        internal
        pure
        returns (
            address a,
            address b,
            uint24 fee
        )
    {
        // MLOAD Only, so it's safe
        assembly ("memory-safe") {
            // first 32 bytes are reserved for bytes length
            a := mload(add(data, 20)) // load last 20 bytes of 32 + 20 (52-32=20)
            b := mload(add(data, 40)) // load last 20 bytes of 32 + 40 (72-32=40)
            fee := mload(add(data, 43)) // load last 3 bytes of 32 + 43 (75-32=43)
        }
    }

    /// @custom:gas Uint256 zero check gas saver
    /// @notice Uint256 zero check gas saver
    /// @param value Number to check
    function _isZero(uint256 value) internal pure returns (bool boolValue) {
        // Stack Only Safety
        assembly ("memory-safe") {
            boolValue := iszero(value)
        }
    }

    /// @custom:gas Uint256 not zero check gas saver
    /// @notice Uint256 not zero check gas saver
    /// @param value Number to check
    function _isNonZero(uint256 value) internal pure returns (bool boolValue) {
        // Stack Only Safety
        assembly ("memory-safe") {
            boolValue := iszero(iszero(value))
        }
    }

    /// @custom:gas Unchecked increment gas saver
    /// @notice Unchecked increment gas saver for loops
    /// @param i Number to increment
    function _inc(uint256 i) internal pure returns (uint256 result) {
        // Stack only safety
        assembly ("memory-safe") {
            result := add(i, 1)
        }
    }

    /// @custom:gas Unchecked decrement gas saver
    /// @notice Unchecked decrement gas saver for loops
    /// @param i Number to decrement
    function _dec(uint256 i) internal pure returns (uint256 result) {
        // Stack Only Safety
        assembly ("memory-safe") {
            result := sub(i, 1)
        }
    }

    /// @notice Function to receive Ether. msg.data must be empty
    receive() external payable {}

    /// @notice Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function changeGov(address newGov) external {
        if (msg.sender != GOV) revert ExecuteNotAuthorized();
        GOV = newGov;
    }

    /// @notice Sweep dust tokens and eth to recipient
    /// @param tokens Array of token addresses
    /// @param recipient Address of recipient
    function sweep(address[] calldata tokens, address recipient) external {
        if (msg.sender != GOV) revert ExecuteNotAuthorized();
        for (uint256 i; i < tokens.length; i++) {
            address token = tokens[i];
            ERC20(token).safeTransfer(recipient, ERC20(token).balanceOf(address(this)));
        }
        SafeTransferLib.safeTransferETH(recipient, address(this).balance);
    }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.13 <0.9.0;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function pairCodeHash() external pure returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.13 <0.9.0;

interface IUniswapV2Pair {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0() external view returns (uint160 sqrtPriceX96);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

/// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

library Babylonian {
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }
}

/// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

/**
Optimal split swap library to support SplitSwapRouter
Based on UniswapV2Library: https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
*/

import "../interfaces/IUniswapV3Pool.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "./Babylonian.sol";

/// @title SplitSwapLibrary
/// @author Sandy Bradley <@sandybradley>, ControlCplusControlV <@ControlCplusControlV>
/// @notice Optimal MEV library to support SplitSwapRouter
library SplitSwapLibrary {
    error Overflow();
    error ZeroAmount();
    error InvalidPath();
    error ZeroAddress();
    error IdenticalAddresses();
    error InsufficientLiquidity();

    /// @notice struct for pool reserves
    /// @param reserveIn amount of reserves (or virtual reserves) in pool for tokenIn
    /// @param reserveOut amount of reserves (or virtual reserves) in pool for tokenOut
    struct Reserve {
        uint256 reserveIn;
        uint256 reserveOut;
    }

    /// @notice struct for pool swap info
    /// @param pair pair / pool address (sushi, univ2, univ3 (3 pools))
    /// @param amountIn amount In for swap
    /// @param amountOut amount Out for swap
    struct Pool {
        address pair;
        uint256 amountIn;
        uint256 amountOut;
    }

    /// @notice struct for swap info
    /// @param isReverse true if token0 == tokenOut
    /// @param tokenIn address of token In
    /// @param tokenOut address of token Out
    /// @param pools 5 element array of pool split swap info
    struct Swap {
        bool isReverse;
        address tokenIn;
        address tokenOut;
        Pool[5] pools; // 5 pools (sushi, univ2, univ3 (3 pools))
    }

    /// @dev Minimum pool liquidity to interact with
    uint256 internal constant MINIMUM_LIQUIDITY = 1000;

    /// @dev calculate uinswap v3 pool address
    /// @param token0 address of token0
    /// @param token1 address of token1
    /// @param fee pool fee as ratio of 1000000
    function uniswapV3PoolAddress(
        address token0,
        address token1,
        uint24 fee
    ) internal pure returns (address pool) {
        // NB moving constants to here seems more gas efficient
        bytes32 POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;
        address UNIV3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
        bytes32 pubKey = keccak256(
            abi.encodePacked(hex"ff", UNIV3_FACTORY, keccak256(abi.encode(token0, token1, fee)), POOL_INIT_CODE_HASH)
        );

        //bytes32 to address:
        assembly ("memory-safe") {
            let ptr := mload(0x40) // get free memory pointer
            mstore(ptr, pubKey)
            pool := mload(ptr)
        }
    }

    /// @dev get fee for pool as a fraction of 1000000 (i.e. 0.3% -> 3000)
    /// @param index Reference order is hard coded as sushi, univ2, univ3 (0.3%), univ3 (0.05%), univ3 (1%)
    function getFee(uint256 index) internal pure returns (uint256) {
        if (index <= 2) return 3000;
        // sushi, univ2 and 0.3% univ3
        else if (index == 3) return 500;
        else return 10000;
    }

    /// @custom:assembly Sort tokens, zero address check
    /// @notice Returns sorted token addresses, used to handle return values from pairs sorted in this order
    /// @dev Require replaced with revert custom error
    /// @param tokenA Pool token
    /// @param tokenB Pool token
    /// @return token0 First token in pool pair
    /// @return token1 Second token in pool pair
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        if (tokenA == tokenB) revert IdenticalAddresses();
        bool isZeroAddress;

        assembly ("memory-safe") {
            switch lt(shl(96, tokenA), shl(96, tokenB)) // sort tokens
            case 0 {
                token0 := tokenB
                token1 := tokenA
            }
            default {
                token0 := tokenA
                token1 := tokenB
            }
            isZeroAddress := iszero(token0)
        }
        if (isZeroAddress) revert ZeroAddress();
    }

    /// @notice Calculates the CREATE2 address for a pair without making any external calls
    /// @dev Factory passed in directly because we have multiple factories. Format changes for new solidity spec.
    /// @param factory Factory address for dex
    /// @param tokenA Pool token
    /// @param tokenB Pool token
    /// @return pair Pair pool address
    function pairFor(
        address factory,
        address tokenA,
        address tokenB,
        bytes32 factoryHash
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = _asmPairFor(factory, token0, token1, factoryHash);
    }

    /// @custom:assembly Calculates the CREATE2 address for a pair without making any external calls from pre-sorted tokens
    /// @notice Calculates the CREATE2 address for a pair without making any external calls from pre-sorted tokens
    /// @dev Factory passed in directly because we have multiple factories. Format changes for new solidity spec.
    /// @param factory Factory address for dex
    /// @param token0 Pool token
    /// @param token1 Pool token
    /// @param factoryHash Init code hash for factory
    /// @return pair Pair pool address
    function _asmPairFor(
        address factory,
        address token0,
        address token1,
        bytes32 factoryHash
    ) internal pure returns (address pair) {
        // There is one contract for every combination of tokens,
        // which is deployed using CREATE2.
        // The derivation of this address is given by:
        //   address(keccak256(abi.encodePacked(
        //       bytes(0xFF),
        //       address(UNISWAP_FACTORY_ADDRESS),
        //       keccak256(abi.encodePacked(token0, token1)),
        //       bytes32(UNISWAP_PAIR_INIT_CODE_HASH),
        //   )));
        assembly ("memory-safe") {
            let ptr := mload(0x40) // get free memory pointer
            mstore(ptr, shl(96, token0))
            mstore(add(ptr, 0x14), shl(96, token1))
            let salt := keccak256(ptr, 0x28) // keccak256(token0, token1)
            mstore(ptr, 0xFF00000000000000000000000000000000000000000000000000000000000000) // buffered 0xFF prefix
            mstore(add(ptr, 0x01), shl(96, factory)) // factory address prefixed
            mstore(add(ptr, 0x15), salt)
            mstore(add(ptr, 0x35), factoryHash) // factory init code hash
            pair := keccak256(ptr, 0x55)
        }
    }

    /// @notice Fetches and sorts the reserves for a pair
    /// @param factory Factory address for dex
    /// @param tokenA Pool token
    /// @param tokenB Pool token
    /// @return reserveA Reserves for tokenA
    /// @return reserveB Reserves for tokenB
    function getReserves(
        address factory,
        address tokenA,
        address tokenB,
        bytes32 factoryHash
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(_asmPairFor(factory, token0, token1, factoryHash))
            .getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    /// @notice Given some asset amount and reserves, returns an amount of the other asset representing equivalent value
    /// @dev Require replaced with revert custom error
    /// @param amountA Amount of token A
    /// @param reserveA Reserves for tokenA
    /// @param reserveB Reserves for tokenB
    /// @return amountB Amount of token B returned
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        if (_isZero(amountA)) revert ZeroAmount();
        if (_isZero(reserveA) || _isZero(reserveB)) revert InsufficientLiquidity();
        amountB = (amountA * reserveB) / reserveA;
    }

    /// @notice Given an input asset amount, returns the maximum output amount of the other asset (accounting for fees) given reserves
    /// @dev Require replaced with revert custom error
    /// @param amountIn Amount of token in
    /// @param reserveIn Reserves for token in
    /// @param reserveOut Reserves for token out
    /// @return amountOut Amount of token out returned
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        if (_isZero(amountIn)) revert ZeroAmount();
        if (reserveIn < MINIMUM_LIQUIDITY || reserveOut < MINIMUM_LIQUIDITY) revert InsufficientLiquidity();
        // save gas, perform internal overflow check
        unchecked {
            uint256 amountInWithFee = amountIn * uint256(997);
            uint256 numerator = amountInWithFee * reserveOut;
            if (reserveOut != numerator / amountInWithFee) revert Overflow();
            uint256 denominator = (reserveIn * uint256(1000)) + amountInWithFee;
            amountOut = numerator / denominator;
        }
    }

    /// @notice Given an input asset amount, returns the maximum output amount of the other asset (accounting for fees) given reserves
    /// @dev Require replaced with revert custom error
    /// @param amountIn Amount of token in
    /// @param reserveIn Reserves for token in
    /// @param reserveOut Reserves for token out
    /// @return amountOut Amount of token out returned
    function getAmountOutFee(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 fee
    ) internal pure returns (uint256 amountOut) {
        if (_isZero(amountIn)) revert ZeroAmount();
        if (reserveIn < MINIMUM_LIQUIDITY || reserveOut < MINIMUM_LIQUIDITY) revert InsufficientLiquidity();
        // save gas, perform internal overflow check
        unchecked {
            uint256 amountInWithFee = amountIn * (1000000 - fee);
            uint256 numerator = amountInWithFee * reserveOut;
            if (reserveOut != numerator / amountInWithFee) revert Overflow();
            uint256 denominator = (reserveIn * 1000000) + amountInWithFee;
            amountOut = numerator / denominator;
        }
    }

    /// @notice Returns the minimum input asset amount required to buy the given output asset amount (accounting for fees) given reserves
    /// @dev Require replaced with revert custom error
    /// @param amountOut Amount of token out wanted
    /// @param reserveIn Reserves for token in
    /// @param reserveOut Reserves for token out
    /// @return amountIn Amount of token in required
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        if (_isZero(amountOut)) revert ZeroAmount();
        if (reserveIn < MINIMUM_LIQUIDITY || reserveOut < MINIMUM_LIQUIDITY || reserveOut <= amountOut)
            revert InsufficientLiquidity();
        // save gas, perform internal overflow check
        unchecked {
            uint256 numerator = reserveIn * amountOut * uint256(1000);
            if ((reserveIn * uint256(1000)) != numerator / amountOut) revert Overflow();
            uint256 denominator = (reserveOut - amountOut) * uint256(997);
            amountIn = (numerator / denominator) + 1;
        }
    }

    /// @notice Returns the minimum input asset amount required to buy the given output asset amount (accounting for fees) given reserves
    /// @dev Require replaced with revert custom error
    /// @param amountOut Amount of token out wanted
    /// @param reserveIn Reserves for token in
    /// @param reserveOut Reserves for token out
    /// @return amountIn Amount of token in required
    function getAmountInFee(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 fee
    ) internal pure returns (uint256 amountIn) {
        if (_isZero(amountOut)) revert ZeroAmount();
        if (reserveIn < MINIMUM_LIQUIDITY || reserveOut < MINIMUM_LIQUIDITY || reserveOut <= amountOut)
            revert InsufficientLiquidity();
        // save gas, perform internal overflow check
        unchecked {
            uint256 numerator = reserveIn * amountOut * uint256(1000000);
            if ((reserveIn * uint256(1000000)) != numerator / amountOut) revert Overflow();
            uint256 denominator = (reserveOut - amountOut) * (1000000 - fee);
            amountIn = (numerator / denominator) + 1;
        }
    }

    /// @dev checks codesize for contract existence
    /// @param _addr address of contract to check
    function isContract(address _addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (_isNonZero(size));
    }

    /// @dev populates and returns Reserve struct array for each pool address
    /// @param isReverse true if token0 == tokenOut
    /// @param pools 5 element array of Pool structs populated with pool addresses
    function _getReserves(bool isReverse, Pool[5] memory pools) internal view returns (Reserve[5] memory reserves) {
        // 2 V2 pools
        for (uint256 i; i < 2; i = _inc(i)) {
            if (!isContract(pools[i].pair)) continue;
            (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pools[i].pair).getReserves();
            (reserves[i].reserveIn, reserves[i].reserveOut) = isReverse ? (reserve1, reserve0) : (reserve0, reserve1);
        }
        // 4 V3 pools
        for (uint256 i = 2; i < 5; i = _inc(i)) {
            if (!isContract(pools[i].pair)) continue;
            uint160 sqrtPriceX96 = uint160(IUniswapV3Pool(pools[i].pair).slot0());
            uint256 liquidity = uint256(IUniswapV3Pool(pools[i].pair).liquidity());
            if (_isNonZero(liquidity) && _isNonZero(sqrtPriceX96)) {
                unchecked {
                    uint256 reserve0 = (liquidity * uint256(2**96)) / uint256(sqrtPriceX96);
                    uint256 reserve1 = (liquidity * uint256(sqrtPriceX96)) / uint256(2**96);
                    (reserves[i].reserveIn, reserves[i].reserveOut) = isReverse
                        ? (reserve1, reserve0)
                        : (reserve0, reserve1);
                }
            }
        }
    }

    /// @dev calculate pool addresses for token0/1 & factory/fee
    function _getPools(
        address factory0,
        address factory1,
        address token0,
        address token1,
        bytes32 factoryHash0,
        bytes32 factoryHash1
    ) internal pure returns (Pool[5] memory pools) {
        pools[0].pair = _asmPairFor(factory0, token0, token1, factoryHash0); // sushi
        pools[1].pair = _asmPairFor(factory1, token0, token1, factoryHash1); // univ2
        pools[2].pair = uniswapV3PoolAddress(token0, token1, 3000); // univ3 0.3 %
        pools[3].pair = uniswapV3PoolAddress(token0, token1, 500); // univ3 0.05 %
        pools[4].pair = uniswapV3PoolAddress(token0, token1, 10000); // univ3 1 %
    }

    /// @notice Fetches swap data for each pair and amounts given a desired output and path
    /// @param factory1 Backup Factory address for dex
    /// @param amountIn Amount in for first token in path
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @return swaps Array Swap data for each user swap in path
    function getSwapsOut(
        address factory0,
        address factory1,
        uint256 amountIn,
        bytes32 factoryHash0,
        bytes32 factoryHash1,
        address[] memory path
    ) internal view returns (Swap[] memory swaps) {
        uint256 length = path.length;
        if (length < 2) revert InvalidPath();
        swaps = new Swap[](_dec(length));
        for (uint256 i; i < _dec(length); i = _inc(i)) {
            if (_isNonZero(i)) {
                amountIn = 0; // reset amountIn
                for (uint256 j; j < 5; j = _inc(j)) {
                    amountIn = amountIn + swaps[_dec(i)].pools[j].amountOut;
                }
            }
            {
                (address token0, address token1) = sortTokens(path[i], path[_inc(i)]);
                swaps[i].pools = _getPools(factory0, factory1, token0, token1, factoryHash0, factoryHash1);
                swaps[i].isReverse = path[i] == token1;
            }
            swaps[i].tokenIn = path[i];
            swaps[i].tokenOut = path[_inc(i)];
            uint256[5] memory amountsIn;
            uint256[5] memory amountsOut;
            {
                Reserve[5] memory reserves = _getReserves(swaps[i].isReverse, swaps[i].pools);
                // find optimal route
                (amountsIn, amountsOut) = _optimalRouteOut(amountIn, reserves);
            }
            for (uint256 j; j < 5; j = _inc(j)) {
                swaps[i].pools[j].amountIn = amountsIn[j];
                swaps[i].pools[j].amountOut = amountsOut[j];
            }
        }
    }

    /// @dev sorts possible swaps by best price, then assigns optimal split
    function _optimalRouteOut(uint256 amountIn, Reserve[5] memory reserves)
        internal
        pure
        returns (uint256[5] memory amountsIn, uint256[5] memory amountsOut)
    {
        // calculate best rate for a single swap (i.e. no splitting)
        uint256[5] memory amountsOutSingleSwap;
        // first 3 pools have fee of 0.3%
        for (uint256 i; i < 3; i = _inc(i)) {
            if (reserves[i].reserveOut > MINIMUM_LIQUIDITY) {
                amountsOutSingleSwap[i] = getAmountOut(amountIn, reserves[i].reserveIn, reserves[i].reserveOut);
            }
        }
        // next 2 pools have variable rates
        for (uint256 i = 3; i < 5; i = _inc(i)) {
            if (reserves[i].reserveOut > MINIMUM_LIQUIDITY && reserves[i].reserveIn > amountIn) {
                amountsOutSingleSwap[i] = getAmountOutFee(
                    amountIn,
                    reserves[i].reserveIn,
                    reserves[i].reserveOut,
                    getFee(i)
                );
                if (i == 3 && _isNonZero(amountsOutSingleSwap[i])) {
                    // 0.05 % pool potentially crosses more ticks, lowering expected output (add margin of error 0.1%)
                    amountsOutSingleSwap[i] = amountsOutSingleSwap[i] - amountsOutSingleSwap[i] / 1000;
                }
            }
        }
        (amountsIn, amountsOut) = _splitSwapOut(amountIn, amountsOutSingleSwap, reserves);
    }

    /// @notice assigns optimal route for maximum amount out, given pool reserves
    function _splitSwapOut(
        uint256 amountIn,
        uint256[5] memory amountsOutSingleSwap,
        Reserve[5] memory reserves
    ) internal pure returns (uint256[5] memory amountsIn, uint256[5] memory amountsOut) {
        uint256[5] memory index = _sortArray(amountsOutSingleSwap); // sorts in ascending order (i.e. best price is last)
        if (_isNonZero(amountsOutSingleSwap[index[4]])) {
            amountsIn[index[4]] = amountIn; // set best price as default, before splitting
            amountsOut[index[4]] = amountsOutSingleSwap[index[4]];
            uint256 cumulativeAmount;
            uint256 cumulativeReserveIn = reserves[index[4]].reserveIn;
            uint256 cumulativeReserveOut = reserves[index[4]].reserveOut;
            uint256 numSplits;
            // calculate amount to sync prices cascading through each pool with best prices first, while cumulative amount < amountIn
            for (uint256 i = 4; _isNonZero(i); i = _dec(i)) {
                if (_isZero(amountsOutSingleSwap[index[_dec(i)]])) break;
                amountsOutSingleSwap[index[i]] = _amountToSyncPricesFee(
                    cumulativeReserveIn,
                    cumulativeReserveOut,
                    reserves[index[_dec(i)]].reserveIn,
                    reserves[index[_dec(i)]].reserveOut,
                    getFee(index[i])
                ); // re-assign var to amountsToSyncPrices
                if (_isZero(amountsOutSingleSwap[index[i]])) break; // skip edge case
                cumulativeAmount = cumulativeAmount + amountsOutSingleSwap[index[i]];
                if (amountIn <= cumulativeAmount) break; // keep prior setting and break loop
                numSplits = _inc(numSplits);
                cumulativeReserveOut =
                    cumulativeReserveOut +
                    reserves[index[_dec(i)]].reserveOut -
                    getAmountOut(amountsOutSingleSwap[index[i]], cumulativeReserveIn, cumulativeReserveOut);
                cumulativeReserveIn =
                    cumulativeReserveIn +
                    reserves[index[_dec(i)]].reserveIn +
                    amountsOutSingleSwap[index[i]];
            }
            // assign optimal route
            amountsIn[index[4 - numSplits]] = amountIn; // default
            for (uint256 i; i < numSplits; i = _inc(i)) {
                uint256 partAmountIn;
                cumulativeReserveOut = reserves[index[4]].reserveIn; // re-assign var to represent cumulative reserve in
                cumulativeAmount = 0;
                for (uint256 j; j < numSplits; j = _inc(j)) {
                    if (_isZero(amountsOutSingleSwap[index[4 - j]])) break;
                    if (j >= i)
                        partAmountIn =
                            partAmountIn +
                            (amountsOutSingleSwap[index[4 - j]] * (reserves[index[4 - i]].reserveIn + partAmountIn)) /
                            cumulativeReserveOut; // amounts to sync are routed consecutively by reserve ratios
                    cumulativeReserveOut =
                        cumulativeReserveOut +
                        amountsOutSingleSwap[index[4 - j]] +
                        reserves[index[3 - j]].reserveIn; // cumulative reserve in
                    cumulativeAmount = cumulativeAmount + amountsOutSingleSwap[index[4 - j]]; // accumulate amounts to sync to each price level
                }
                amountsIn[index[4 - i]] =
                    partAmountIn +
                    ((amountIn - cumulativeAmount) * (reserves[index[4 - i]].reserveIn + partAmountIn)) /
                    cumulativeReserveIn; // each new split is optimally routed by reserve ratio of new pool to cumulative reserves of prior pools
                amountsIn[index[4 - numSplits]] = amountsIn[index[4 - numSplits]] - amountsIn[index[4 - i]]; // assign last amountIn as remainder to account for rounding errors
            }
            for (uint256 i = 5; _isNonZero(i); i = _dec(i)) {
                if (_isZero(amountsIn[index[_dec(i)]])) break;
                amountsOut[index[_dec(i)]] = getAmountOutFee(
                    amountsIn[index[_dec(i)]],
                    reserves[index[_dec(i)]].reserveIn,
                    reserves[index[_dec(i)]].reserveOut,
                    getFee(index[_dec(i)])
                );
            }
        }
    }

    /// @notice Fetches swap data for each pair and amounts given a desired output and path
    /// @param factory1 Factory address for dex
    /// @param amountOut Amount out for last token in path
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @return swaps Array Swap data for each user swap in path
    function getSwapsIn(
        address factory0,
        address factory1,
        uint256 amountOut,
        bytes32 factoryHash0,
        bytes32 factoryHash1,
        address[] memory path
    ) internal view returns (Swap[] memory swaps) {
        uint256 length = path.length;
        if (length < 2) revert InvalidPath();
        swaps = new Swap[](_dec(length));
        for (uint256 i = _dec(length); _isNonZero(i); i = _dec(i)) {
            if (i < _dec(length)) {
                amountOut = 0;
                for (uint256 j; j < 5; j = _inc(j)) {
                    amountOut = amountOut + swaps[i].pools[j].amountIn;
                }
            }
            {
                (address token0, address token1) = sortTokens(path[_dec(i)], path[i]);
                swaps[_dec(i)].pools = _getPools(factory0, factory1, token0, token1, factoryHash0, factoryHash1);
                swaps[_dec(i)].isReverse = path[i] == token0;
            }
            swaps[_dec(i)].tokenIn = path[_dec(i)];
            swaps[_dec(i)].tokenOut = path[i];
            uint256[5] memory amountsIn;
            uint256[5] memory amountsOut;
            {
                Reserve[5] memory reserves = _getReserves(swaps[_dec(i)].isReverse, swaps[_dec(i)].pools);
                // find optimal route
                (amountsIn, amountsOut) = _optimalRouteIn(amountOut, reserves);
            }

            for (uint256 j; j < 5; j = _inc(j)) {
                swaps[_dec(i)].pools[j].amountIn = amountsIn[j];
                swaps[_dec(i)].pools[j].amountOut = amountsOut[j];
            }
        }
    }

    function _splitSwapIn(
        uint256 amountOut,
        uint256[5] memory amountsInSingleSwap,
        Reserve[5] memory reserves
    ) internal pure returns (uint256[5] memory amountsIn, uint256[5] memory amountsOut) {
        uint256[5] memory index = _sortArray(amountsInSingleSwap); // sorts in ascending order (i.e. best price is first)
        uint256 cumulativeAmount;
        uint256 cumulativeReserveIn;
        uint256 cumulativeReserveOut;
        uint256 prevAmountIn;
        uint256 numSplits;
        uint256 offset;
        // calculate amount to sync prices cascading through each pool with best prices first, while cumulative amount < amountIn
        for (uint256 i = 0; i < 4; i = _inc(i)) {
            if (_isZero(amountsInSingleSwap[index[i]])) continue;
            if (_isZero(prevAmountIn)) {
                prevAmountIn = amountsInSingleSwap[index[i]];
                cumulativeReserveOut = reserves[index[i]].reserveOut;
                cumulativeReserveIn = reserves[index[i]].reserveIn;
                amountsIn[index[i]] = prevAmountIn;
                amountsOut[index[i]] = amountOut;
                offset = i;
                break;
            }
        }
        for (uint256 i = offset; i < 4; i = _inc(i)) {
            amountsInSingleSwap[index[i]] = _amountToSyncPricesFee(
                cumulativeReserveIn,
                cumulativeReserveOut,
                reserves[index[_inc(i)]].reserveIn,
                reserves[index[_inc(i)]].reserveOut,
                getFee(index[i])
            );
            if (_isZero(amountsInSingleSwap[index[i]])) break; // skip edge case
            cumulativeAmount = cumulativeAmount + amountsInSingleSwap[index[i]];

            if (prevAmountIn <= cumulativeAmount) break; // keep prior setting and break loop
            numSplits = _inc(numSplits);
            cumulativeReserveOut =
                cumulativeReserveOut +
                reserves[index[_inc(i)]].reserveOut -
                getAmountOut(amountsInSingleSwap[index[i]], cumulativeReserveIn, cumulativeReserveOut);
            cumulativeReserveIn =
                cumulativeReserveIn +
                reserves[index[_inc(i)]].reserveIn +
                amountsInSingleSwap[index[i]];
        }
        // assign optimal route
        for (uint256 i; i < numSplits; i = _inc(i)) {
            uint256 partAmountIn;
            cumulativeReserveOut = reserves[index[offset]].reserveIn; // re-assign var
            cumulativeAmount = 0;
            for (uint256 j; j < numSplits; j = _inc(j)) {
                if (_isZero(amountsInSingleSwap[index[_inc(j + offset)]])) break;
                if (j >= i)
                    partAmountIn =
                        partAmountIn +
                        (amountsInSingleSwap[index[j + offset]] *
                            (reserves[index[i + offset]].reserveIn + partAmountIn)) /
                        cumulativeReserveOut;
                cumulativeReserveOut =
                    cumulativeReserveOut +
                    amountsInSingleSwap[index[j + offset]] +
                    reserves[index[_inc(j + offset)]].reserveIn;
                cumulativeAmount = cumulativeAmount + amountsInSingleSwap[index[j + offset]];
            }
            amountsIn[index[i + offset]] =
                partAmountIn +
                ((prevAmountIn - cumulativeAmount) * (reserves[index[i + offset]].reserveIn + partAmountIn)) /
                cumulativeReserveIn;
        }
        amountsOut[index[numSplits + offset]] = amountOut;
        for (uint256 i; i < numSplits; i = _inc(i)) {
            if (_isZero(amountsIn[index[i + offset]])) break;
            amountsOut[index[i + offset]] = getAmountOutFee(
                amountsIn[index[i + offset]],
                reserves[index[i + offset]].reserveIn,
                reserves[index[i + offset]].reserveOut,
                getFee(index[i + offset])
            );
            if (amountsOut[index[i + offset]] < amountsOut[index[numSplits + offset]])
                amountsOut[index[numSplits + offset]] =
                    amountsOut[index[numSplits + offset]] -
                    amountsOut[index[i + offset]];
            else amountsOut[index[numSplits + offset]] = 0;
        }
        if (_isNonZero(amountsOut[index[numSplits + offset]]))
            amountsIn[index[numSplits + offset]] = getAmountInFee(
                amountsOut[index[numSplits + offset]],
                reserves[index[numSplits + offset]].reserveIn,
                reserves[index[numSplits + offset]].reserveOut,
                getFee(index[numSplits + offset])
            );
    }

    /// @dev insert sorted index of amount array (in ascending order)
    function _sortArray(uint256[5] memory _data) internal pure returns (uint256[5] memory index) {
        uint256[5] memory data;
        for (uint256 i; i < 5; i++) {
            data[i] = _data[i];
        }
        index = [uint256(0), uint256(1), uint256(2), uint256(3), uint256(4)];
        for (uint256 i = 1; i < 5; i++) {
            uint256 key = data[i];
            uint256 keyIndex = index[i];
            uint256 j = i;
            while (_isNonZero(j) && (data[_dec(j)] > key)) {
                data[j] = data[_dec(j)];
                index[j] = index[_dec(j)];
                j = _dec(j);
            }
            data[j] = key;
            index[j] = keyIndex;
        }
    }

    /// @dev sorts possible swaps by best price, then assigns optimal split
    function _optimalRouteIn(uint256 amountOut, Reserve[5] memory reserves)
        internal
        pure
        returns (uint256[5] memory amountsIn, uint256[5] memory amountsOut)
    {
        uint256[5] memory amountsInSingleSwap;
        // first 3 pools have fee of 0.3%
        for (uint256 i; i < 3; i = _inc(i)) {
            if (reserves[i].reserveOut > amountOut && reserves[i].reserveIn > MINIMUM_LIQUIDITY) {
                amountsInSingleSwap[i] = getAmountIn(amountOut, reserves[i].reserveIn, reserves[i].reserveOut);
            }
        }
        // next 2 pools have variable rates
        for (uint256 i = 3; i < 5; i = _inc(i)) {
            if (reserves[i].reserveOut > amountOut && reserves[i].reserveIn > MINIMUM_LIQUIDITY) {
                amountsInSingleSwap[i] = getAmountInFee(
                    amountOut,
                    reserves[i].reserveIn,
                    reserves[i].reserveOut,
                    getFee(i)
                );
                if (i == 3 && _isNonZero(amountsInSingleSwap[i])) {
                    // 0.05 % pool potentially crosses more ticks, lowering expected output (add margin of error 0.01% of amountIn)
                    amountsInSingleSwap[i] = amountsInSingleSwap[i] + amountsInSingleSwap[i] / 1000;
                }
            }
        }

        (amountsIn, amountsOut) = _splitSwapIn(amountOut, amountsInSingleSwap, reserves);
    }

    /// @dev returns amount In of pool 1 required to sync prices with pool 2
    /// @param x1 reserveIn pool 1
    /// @param y1 reserveOut pool 1
    /// @param x2 reserveIn pool 2
    /// @param y2 reserveOut pool 2
    /// @param fee pool 1 fee
    function _amountToSyncPricesFee(
        uint256 x1,
        uint256 y1,
        uint256 x2,
        uint256 y2,
        uint256 fee
    ) internal pure returns (uint256) {
        unchecked {
            return
                (x1 *
                    (Babylonian.sqrt((fee * fee + (x2 * y1 * (4000000000000 - 4000000 * fee)) / (x1 * y2))) -
                        (2000000 - fee))) / (2 * (1000000 - fee));
        }
    }

    /// @custom:gas Uint256 zero check gas saver
    /// @dev Uint256 zero check gas saver
    /// @param value Number to check
    function _isZero(uint256 value) internal pure returns (bool boolValue) {
        assembly ("memory-safe") {
            boolValue := iszero(value)
        }
    }

    /// @custom:gas Uint256 not zero check gas saver
    /// @dev Uint256 not zero check gas saver
    /// @param value Number to check
    function _isNonZero(uint256 value) internal pure returns (bool boolValue) {
        assembly ("memory-safe") {
            boolValue := iszero(iszero(value))
        }
    }

    /// @custom:gas Unchecked increment gas saver
    /// @dev Unchecked increment gas saver for loops
    /// @param i Number to increment
    function _inc(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i + 1;
        }
    }

    /// @custom:gas Unchecked decrement gas saver
    /// @dev Unchecked decrement gas saver for loops
    /// @param i Number to decrement
    function _dec(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i - 1;
        }
    }
}