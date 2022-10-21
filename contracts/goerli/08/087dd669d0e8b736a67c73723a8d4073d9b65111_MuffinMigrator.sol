// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {IManagerMinimal} from "./interfaces/muffin/IManagerMinimal.sol";
import {INonfungiblePositionManagerMinimal} from "./interfaces/uniswap/INonfungiblePositionManagerMinimal.sol";

contract MuffinMigrator is ReentrancyGuard {
    address public immutable weth;
    IManagerMinimal public immutable muffinManager;
    INonfungiblePositionManagerMinimal public immutable uniV3PositionManager;

    struct PermitUniV3Params {
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct MintParams {
        bool needCreatePool;
        bool needAddTier;
        uint128 sqrtPrice;
        uint24 sqrtGamma;
        uint8 tierId;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
    }

    constructor(address muffinManager_, address uniV3PositionManager_) {
        muffinManager = IManagerMinimal(muffinManager_);
        uniV3PositionManager = INonfungiblePositionManagerMinimal(uniV3PositionManager_);
        weth = muffinManager.WETH9();
    }

    // only receive from WETH contract for refund
    receive() external payable {
        require(weth == msg.sender, "WETH only");
    }

    /// @notice Migrate Uniswap V3 position to Muffin position
    /// @dev Only the tokens withdrew during the decrease liquidity will be collected,
    /// i.e. fees are remaining inside the Uniswap's position.
    /// @param permitParams subset of paramenters for Uniswap's `NonfungiblePositionManager.permit`
    /// @param removeParams paramenters for Uniswap's `INonfungiblePositionManager.decreaseLiquidity`
    /// @param mintParams needCreatePool indicate the need of creating new Muffin's pool,
    /// the amount of both burnt tokens need to exceed certain amount for creation.
    /// needAddTier indicate the need of adding new fee tier to the Muffin's pool,
    /// the amount of both burnt tokens need to exceed certain amount for addition.
    /// sqrtPrice the sqrt price value for creating new Muffin's pool.
    /// sqrtGamma the sqrt gamma value for adding new fee tier.
    /// ...others are subset of paramenters for Muffin's `Manager.mint`
    /// @param refundAsETH `true` for refund WETH as ETH
    function migrateFromUniV3WithPermit(
        PermitUniV3Params calldata permitParams,
        INonfungiblePositionManagerMinimal.DecreaseLiquidityParams calldata removeParams,
        MintParams calldata mintParams,
        bool refundAsETH
    ) external nonReentrant {
        // permit this contract to access the Uniswap V3 position
        // also act as token owner validation
        uniV3PositionManager.permit(
            address(this),
            removeParams.tokenId,
            permitParams.deadline,
            permitParams.v,
            permitParams.r,
            permitParams.s
        );

        // get uniswap position info
        (address token0, address token1) = _getUniV3PositionTokenPair(removeParams.tokenId);

        // record the current balance of tokens
        uint256 balance0 = ERC20(token0).balanceOf(address(this));
        uint256 balance1 = ERC20(token1).balanceOf(address(this));

        // remove and collect Uniswap V3 position
        (uint256 amount0, uint256 amount1) = _removeAndCollectUniV3Position(removeParams);

        // allow muffin manager to use the tokens
        _approveTokenToMuffinManager(token0, amount0);
        _approveTokenToMuffinManager(token1, amount1);

        // mint muffin position
        _mintPosition(token0, token1, mintParams);

        // calculate the remaining tokens, need underflow to check if over-used
        balance0 = ERC20(token0).balanceOf(address(this)) - balance0;
        balance1 = ERC20(token1).balanceOf(address(this)) - balance1;

        // refund remaining tokens to recipient's wallet
        _refund(token0, mintParams.recipient, balance0, refundAsETH);
        _refund(token1, mintParams.recipient, balance1, refundAsETH);
    }

    function _getUniV3PositionTokenPair(uint256 tokenId)
        internal
        view
        returns (address token0, address token1)
    {
        (
            ,
            ,
            token0,
            token1,
            ,
            ,
            ,
            ,
            ,
            ,
            ,
        ) = uniV3PositionManager.positions(tokenId);
    }

    function _removeAndCollectUniV3Position(
        INonfungiblePositionManagerMinimal.DecreaseLiquidityParams calldata removeParams
    ) internal returns (
        uint256 amount0,
        uint256 amount1
    ) {
        (
            uint256 burntAmount0,
            uint256 burntAmount1
        ) = uniV3PositionManager.decreaseLiquidity(removeParams);

        // collect only the burnt amount, i.e. the fee will be left in the position
        (amount0, amount1) = uniV3PositionManager.collect(
            INonfungiblePositionManagerMinimal.CollectParams({
                tokenId: removeParams.tokenId,
                recipient: address(this),
                // Uniswap assumed all token balances < 2^128
                // See https://github.com/Uniswap/v3-core/blob/main/bug-bounty.md#assumptions
                amount0Max: uint128(burntAmount0),
                amount1Max: uint128(burntAmount1)
            })
        );
    }

    /// @notice Safe approve ERC20 token.
    /// @dev Modified from solmate's `SafeTransferLib`.
    /// It returns the success flag instead of revert it immediately.
    function _trySafeApprove(ERC20 token, address to, uint256 amount) internal returns (bool success) {
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
    }

    function _approveTokenToMuffinManager(address token, uint256 amount) internal {
        uint256 allowance = ERC20(token).allowance(address(this), address(muffinManager));
        if (allowance >= amount) return;

        // revoke allowance before setting a new one, revert if unable to reset
        if (allowance != 0) SafeTransferLib.safeApprove(ERC20(token), address(muffinManager), 0);

        // first try allow max amount
        if (!_trySafeApprove(ERC20(token), address(muffinManager), type(uint256).max)) {
            // if failed, allow only exact amount
            SafeTransferLib.safeApprove(ERC20(token), address(muffinManager), amount);
        }
    }

    function _mintPosition(address token0, address token1, MintParams calldata mintParams) internal {
        if (mintParams.needCreatePool) {
            muffinManager.createPool(token0, token1, mintParams.sqrtGamma, mintParams.sqrtPrice, false);
        } else if (mintParams.needAddTier) {
            muffinManager.addTier(token0, token1, mintParams.sqrtGamma, false, mintParams.tierId);
        }

        muffinManager.mint(
            IManagerMinimal.MintParams({
                token0: token0,
                token1: token1,
                tierId: mintParams.tierId,
                tickLower: mintParams.tickLower,
                tickUpper: mintParams.tickUpper,
                amount0Desired: mintParams.amount0Desired,
                amount1Desired: mintParams.amount1Desired,
                amount0Min: mintParams.amount0Min,
                amount1Min: mintParams.amount1Min,
                recipient: mintParams.recipient,
                useAccount: false
            })
        );
    }

    function _refund(address token, address to, uint256 amount, bool refundAsETH) internal {
        if (amount == 0) return;
        if (token == weth && refundAsETH) {
            WETH(payable(weth)).withdraw(amount);
            SafeTransferLib.safeTransferETH(to, amount);
            return;
        }
        SafeTransferLib.safeTransfer(ERC20(token), to, amount);
    }
}

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

import {ERC20} from "./ERC20.sol";

import {SafeTransferLib} from "../utils/SafeTransferLib.sol";

/// @notice Minimalist and modern Wrapped Ether implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/WETH.sol)
/// @author Inspired by WETH9 (https://github.com/dapphub/ds-weth/blob/master/src/weth9.sol)
contract WETH is ERC20("Wrapped Ether", "WETH", 18) {
    using SafeTransferLib for address;

    event Deposit(address indexed from, uint256 amount);

    event Withdrawal(address indexed to, uint256 amount);

    function deposit() public payable virtual {
        _mint(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public virtual {
        _burn(msg.sender, amount);

        emit Withdrawal(msg.sender, amount);

        msg.sender.safeTransferETH(amount);
    }

    receive() external payable virtual {
        deposit();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IManagerMinimal {
    function WETH9() external view returns (address);

    /// @notice             Create a pool for token0 and token1 if it hasn't been created
    /// @dev                DO NOT create pool with rebasing tokens or multiple-address tokens as it will cause loss of funds
    /// @param token0       Address of token0 of the pool
    /// @param token1       Address of token1 of the pool
    /// @param sqrtGamma    Sqrt of (1 - percentage swap fee of the 1st tier)
    /// @param sqrtPrice    Sqrt price of token0 denominated in token1
    function createPool(
        address token0,
        address token1,
        uint24 sqrtGamma,
        uint128 sqrtPrice,
        bool useAccount
    ) external payable;

    /// @notice             Add a tier to a pool
    /// @dev                This function is subject to sandwitch attack which costs more tokens to add a tier, but the extra cost
    ///                     should be small in common token pairs. Also, users can multicall with "mint" to do slippage check.
    /// @param token0       Address of token0 of the pool
    /// @param token1       Address of token1 of the pool
    /// @param sqrtGamma    Sqrt of (1 - percentage swap fee of the 1st tier)
    /// @param expectedTierId Expected id of the new tier. Revert if unmatched. Set to type(uint8).max for skipping the check.
    function addTier(
        address token0,
        address token1,
        uint24 sqrtGamma,
        bool useAccount,
        uint8 expectedTierId
    ) external payable;

    /**
     * @notice                  Parameters for the mint function
     * @param token0            Address of token0 of the pool
     * @param token1            Address of token1 of the pool
     * @param tierId            Position's tier index
     * @param tickLower         Position's lower tick boundary
     * @param tickUpper         Position's upper tick boundary
     * @param amount0Desired    Desired token0 amount to add to the pool
     * @param amount1Desired    Desired token1 amount to add to the pool
     * @param amount0Min        Minimum token0 amount
     * @param amount1Min        Minimum token1 amount
     * @param recipient         Recipient of the position token
     * @param useAccount        Use sender's internal account to pay
     */
    struct MintParams {
        address token0;
        address token1;
        uint8 tierId;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        bool useAccount;
    }

    /**
     * @notice              Mint a position NFT
     * @param params        MintParams struct
     * @return tokenId      Id of the NFT
     * @return liquidityD8  Amount of liquidity added (divided by 2^8)
     * @return amount0      Token0 amount paid
     * @return amount1      Token1 amount paid
     */
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint96 liquidityD8,
            uint256 amount0,
            uint256 amount1
        );
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

/// @title Minimal interface of Non-fungible token for Uniswap V3 positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManagerMinimal {
    /// @notice Approve of a specific token ID for spending by spender via signature
    /// @param spender The account that is being approved
    /// @param tokenId The ID of the token that is being approved for spending
    /// @param deadline The deadline timestamp by which the call must be mined for the approve to work
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);
}