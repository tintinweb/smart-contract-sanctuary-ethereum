/**
 *Submitted for verification at Etherscan.io on 2022-03-04
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                           EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= amount;
        }

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
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
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);
            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_PERMIT_SIGNATURE");

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
                    keccak256(bytes("1")),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
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

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}
library PackedUint144 {

    uint256 private constant MAX_UINT24 = type(uint24).max;
    uint256 private constant MAX_UINT48 = type(uint48).max;
    uint256 private constant MAX_UINT72 = type(uint72).max;
    uint256 private constant MAX_UINT96 = type(uint96).max;
    uint256 private constant MAX_UINT120 = type(uint120).max;
    uint256 private constant MAX_UINT144 = type(uint144).max;

    error NonZero();
    error FullyPacked();

    function pushUint24Value(uint144 packedUint144, uint24 value) internal pure returns (uint144) {
        if (value == 0) revert NonZero(); // Not strictly necessairy for our use-case since value (incentiveId) can't be 0.
        if (packedUint144 > MAX_UINT120) revert FullyPacked();
        return (packedUint144 << 24) + value;
    }

    function countStoredUint24Values(uint144 packedUint144) internal pure returns (uint256) {
        if (packedUint144 == 0) return 0;
        if (packedUint144 <= MAX_UINT24) return 1;
        if (packedUint144 <= MAX_UINT48) return 2;
        if (packedUint144 <= MAX_UINT72) return 3;
        if (packedUint144 <= MAX_UINT96) return 4;
        if (packedUint144 <= MAX_UINT120) return 5;
        return 6;
    }

    function getUint24ValueAt(uint144 packedUint144, uint256 i) internal pure returns (uint24) {
        return uint24(packedUint144 >> (i * 24));
    }

    function removeUint24ValueAt(uint144 packedUint144, uint256 i) internal pure returns (uint144) {
        if (i > 5) return packedUint144;
        uint256 rightMask = MAX_UINT144 >> (24 * (6 - i));
        uint256 leftMask = (~rightMask) << 24;
        uint256 left = packedUint144 & leftMask;
        uint256 right = packedUint144 & rightMask;
        return uint144((left >> 24) | right);
    }

}
/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
/// @dev Adapted to pragma solidity 0.8 from https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/FullMath.sol
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (0 - denominator) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

/* 
    Permissionless staking contract that allows any number of incentives to be running for any token (erc20).
    Incentives can be created by anyone, the total reward amount must be sent at creation.
    Incentives can be updated (change reward rate / duration).
    Users can deposit their assets into the contract and then subscribe to any of the available incentives, up to 6 per token.
 */

contract StakingContractMainnet {

    using SafeTransferLib for ERC20;
    using PackedUint144 for uint144;

    struct Incentive {
        address creator;            // 1st slot
        address token;              // 2nd slot
        address rewardToken;        // 3rd slot
        uint32 endTime;             // 3rd slot
        uint256 rewardPerLiquidity; // 4th slot
        uint32 lastRewardTime;      // 5th slot
        uint112 rewardRemaining;    // 5th slot
        uint112 liquidityStaked;    // 5th slot
    }

    uint256 public incentiveCount;

    // Starts with 1. Zero is an invalid incentive.
    mapping(uint256 => Incentive) public incentives;

    /// @dev rewardPerLiquidityLast[user][incentiveId]
    /// @dev Semantic overload: if value is zero user isn't subscribed to the incentive.
    mapping(address => mapping(uint256 => uint256)) public rewardPerLiquidityLast;

    /// @dev userStakes[user][stakedToken]
    mapping(address => mapping(address => UserStake)) public userStakes;

    // Incentive count won't be greater than type(uint24).max on mainnet.
    // This means we can use uint24 vlaues to identify incentives.
    struct UserStake {
        uint112 liquidity;
        uint144 subscribedIncentiveIds; // Six packed uint24 values.
    }

    error InvalidTimeFrame();
    error IncentiveOverflow();
    error AlreadySubscribed();
    error AlreadyUnsubscribed();
    error NotSubscribed();
    error OnlyCreator();
    error NoToken();

    event IncentiveCreated(address indexed token, address indexed rewardToken, address indexed creator, uint256 id, uint256 amount, uint256 startTime, uint256 endTime);
    event IncentiveUpdated(uint256 indexed id, int256 changeAmount, uint256 newStartTime, uint256 newEndTime);
    event Stake(address indexed token, address indexed user, uint256 amount);
    event Unstake(address indexed token, address indexed user, uint256 amount);
    event Subscribe(uint256 indexed id, address indexed user);
    event Unsubscribe(uint256 indexed id, address indexed user);
    event Claim(uint256 indexed id, address indexed user, uint256 amount);

    function createIncentive(
        address token,
        address rewardToken,
        uint112 rewardAmount,
        uint32 startTime,
        uint32 endTime
    ) external returns (uint256 incentiveId) {

        if (startTime < block.timestamp) startTime = uint32(block.timestamp);

        if (startTime >= endTime) revert InvalidTimeFrame();

        unchecked { incentiveId = ++incentiveCount; }

        if (incentiveId > type(uint24).max) revert IncentiveOverflow();

        _saferTransferFrom(rewardToken, rewardAmount);

        incentives[incentiveId] = Incentive({
            creator: msg.sender,
            token: token,
            rewardToken: rewardToken,
            lastRewardTime: startTime,
            endTime: endTime,
            rewardRemaining: rewardAmount,
            liquidityStaked: 0,
            // Initial value of rewardPerLiquidity can be arbitrarily set to a non-zero value.
            rewardPerLiquidity: type(uint256).max / 2
        });

        emit IncentiveCreated(token, rewardToken, msg.sender, incentiveId, rewardAmount, startTime, endTime);

    }

    function updateIncentive(
        uint256 incentiveId,
        int112 changeAmount,
        uint32 newStartTime,
        uint32 newEndTime
    ) external {

        Incentive storage incentive = incentives[incentiveId];

        if (msg.sender != incentive.creator) revert OnlyCreator();

        _accrueRewards(incentive);

        if (newStartTime != 0) {

            if (newStartTime < block.timestamp) newStartTime = uint32(block.timestamp);

            incentive.lastRewardTime = newStartTime;

        }

        if (newEndTime != 0) {

            if (newEndTime < block.timestamp) newEndTime = uint32(block.timestamp);

            incentive.endTime = newEndTime;

        }

        if (incentive.lastRewardTime >= incentive.endTime) revert InvalidTimeFrame();

        if (changeAmount > 0) {
            
            incentive.rewardRemaining += uint112(changeAmount);

            ERC20(incentive.rewardToken).safeTransferFrom(msg.sender, address(this), uint112(changeAmount));

        } else if (changeAmount < 0) {

            uint112 transferOut = uint112(-changeAmount);

            if (transferOut > incentive.rewardRemaining) transferOut = incentive.rewardRemaining;

            unchecked { incentive.rewardRemaining -= transferOut; }

            ERC20(incentive.rewardToken).safeTransfer(msg.sender, transferOut);

        }

        emit IncentiveUpdated(incentiveId, changeAmount, incentive.lastRewardTime, incentive.endTime);

    }

    function stakeAndSubscribeToIncentives(
        address token,
        uint112 amount,
        uint256[] memory incentiveIds,
        bool transferExistingRewards
    ) external {

        stakeToken(token, amount, transferExistingRewards);

        uint256 n = incentiveIds.length;

        for (uint256 i = 0; i < n; i = _increment(i)) {

            subscribeToIncentive(incentiveIds[i]);

        }

    }

    function stakeToken(address token, uint112 amount, bool transferExistingRewards) public {

        _saferTransferFrom(token, amount);

        UserStake storage userStake = userStakes[msg.sender][token];

        uint112 previousLiquidity = userStake.liquidity;

        userStake.liquidity += amount;

        uint256 n = userStake.subscribedIncentiveIds.countStoredUint24Values();

        for (uint256 i = 0; i < n; i = _increment(i)) { // Loop through already subscribed incentives.

            uint256 incentiveId = userStake.subscribedIncentiveIds.getUint24ValueAt(i);

            Incentive storage incentive = incentives[incentiveId];

            _accrueRewards(incentive);

            if (transferExistingRewards) {

                _claimReward(incentive, incentiveId, previousLiquidity);

            } else {

                _saveReward(incentive, incentiveId, previousLiquidity, userStake.liquidity);

            }

            incentive.liquidityStaked += amount;

        }

        emit Stake(token, msg.sender, amount);

    }

    function unstakeToken(address token, uint112 amount, bool transferExistingRewards) external {

        UserStake storage userStake = userStakes[msg.sender][token];

        uint112 previousLiquidity = userStake.liquidity;

        userStake.liquidity -= amount;

        uint256 n = userStake.subscribedIncentiveIds.countStoredUint24Values();

        for (uint256 i = 0; i < n; i = _increment(i)) {

            uint256 incentiveId = userStake.subscribedIncentiveIds.getUint24ValueAt(i);

            Incentive storage incentive = incentives[incentiveId];

            _accrueRewards(incentive);

            if (transferExistingRewards || userStake.liquidity == 0) {

                _claimReward(incentive, incentiveId, previousLiquidity);

            } else {

                _saveReward(incentive, incentiveId, previousLiquidity, userStake.liquidity);

            }

            unchecked { incentive.liquidityStaked -= amount; }

        }

        ERC20(token).safeTransfer(msg.sender, amount);

        emit Unstake(token, msg.sender, amount);

    }

    function subscribeToIncentive(uint256 incentiveId) public {

        if (rewardPerLiquidityLast[msg.sender][incentiveId] != 0) revert AlreadySubscribed();

        Incentive storage incentive = incentives[incentiveId];

        _accrueRewards(incentive);

        rewardPerLiquidityLast[msg.sender][incentiveId] = incentive.rewardPerLiquidity;

        UserStake storage userStake = userStakes[msg.sender][incentive.token];

        userStake.subscribedIncentiveIds = userStake.subscribedIncentiveIds.pushUint24Value(uint24(incentiveId));

        incentive.liquidityStaked += userStake.liquidity;

        emit Subscribe(incentiveId, msg.sender);

    }

    /// @param incentiveIndex ∈ [0,5]
    function unsubscribeFromIncentive(address token, uint256 incentiveIndex, bool ignoreRewards) external {

        UserStake storage userStake = userStakes[msg.sender][token];

        uint256 incentiveId = userStake.subscribedIncentiveIds.getUint24ValueAt(incentiveIndex);

        if (rewardPerLiquidityLast[msg.sender][incentiveId] == 0) revert AlreadyUnsubscribed();
        
        Incentive storage incentive = incentives[incentiveId];

        _accrueRewards(incentive);

        /// In case there is a token specific issue we can ignore rewards.
        if (!ignoreRewards) _claimReward(incentive, incentiveId, userStake.liquidity);

        rewardPerLiquidityLast[msg.sender][incentiveId] = 0;

        unchecked { incentive.liquidityStaked -= userStake.liquidity; }

        userStake.subscribedIncentiveIds = userStake.subscribedIncentiveIds.removeUint24ValueAt(incentiveIndex);

        emit Unsubscribe(incentiveId, msg.sender);

    }

    function accrueRewards(uint256 incentiveId) external {

        _accrueRewards(incentives[incentiveId]);

    }

    function claimRewards(uint256[] calldata incentiveIds) external returns (uint256[] memory rewards) {

        uint256 n = incentiveIds.length;

        rewards = new uint256[](n);

        for(uint256 i = 0; i < n; i = _increment(i)) {

            Incentive storage incentive = incentives[incentiveIds[i]];

            _accrueRewards(incentive);

            rewards[i] = _claimReward(incentive, incentiveIds[i], userStakes[msg.sender][incentive.token].liquidity);

        }

    }

    function _accrueRewards(Incentive storage incentive) internal {

        unchecked {

            uint256 maxTime = block.timestamp < incentive.endTime ? block.timestamp : incentive.endTime;

            if (incentive.liquidityStaked > 0 && incentive.lastRewardTime < maxTime) {
                
                uint256 totalTime = incentive.endTime - incentive.lastRewardTime;

                uint256 passedTime = maxTime - incentive.lastRewardTime;

                uint256 reward = uint256(incentive.rewardRemaining) * passedTime / totalTime;

                // Increments of less than type(uint224).max - overflow is unrealistic.
                incentive.rewardPerLiquidity += reward * type(uint112).max / incentive.liquidityStaked;

                incentive.rewardRemaining -= uint112(reward);

                incentive.lastRewardTime = uint32(maxTime);

            } else if (incentive.liquidityStaked == 0) {
                
                incentive.lastRewardTime = uint32(maxTime);

            }

        }

    }

    function _claimReward(Incentive storage incentive, uint256 incentiveId, uint112 usersLiquidity) internal returns (uint256 reward) {

        reward = _calculateReward(incentive, incentiveId, usersLiquidity);

        rewardPerLiquidityLast[msg.sender][incentiveId] = incentive.rewardPerLiquidity;

        ERC20(incentive.rewardToken).safeTransfer(msg.sender, reward);

        emit Claim(incentiveId, msg.sender, reward);

    }

    // We offset the rewardPerLiquidityLast snapshot so that the current reward is included next time we call _claimReward.
    function _saveReward(Incentive storage incentive, uint256 incentiveId, uint112 usersLiquidity, uint112 newLiquidity) internal returns (uint256 reward) {

        reward = _calculateReward(incentive, incentiveId, usersLiquidity);

        uint256 rewardPerLiquidityDelta = reward * type(uint112).max / newLiquidity;

        rewardPerLiquidityLast[msg.sender][incentiveId] = incentive.rewardPerLiquidity - rewardPerLiquidityDelta;

    }

    function _calculateReward(Incentive storage incentive, uint256 incentiveId, uint112 usersLiquidity) internal view returns (uint256 reward) {

        if (rewardPerLiquidityLast[msg.sender][incentiveId] == 0) revert NotSubscribed();

        uint256 rewardPerLiquidityDelta;

        unchecked { rewardPerLiquidityDelta = incentive.rewardPerLiquidity - rewardPerLiquidityLast[msg.sender][incentiveId]; }

        reward = FullMath.mulDiv(rewardPerLiquidityDelta, usersLiquidity, type(uint112).max);

    }

    function _saferTransferFrom(address token, uint256 amount) internal {

        if (token.code.length == 0) revert NoToken();

        ERC20(token).safeTransferFrom(msg.sender, address(this), amount);

    }

    function _increment(uint256 i) internal pure returns (uint256) {

        unchecked { return i + 1; }

    }

    function batch(bytes[] calldata datas) external {

        uint256 n = datas.length;

        for (uint256 i = 0; i < n; i = _increment(i)) {

            (bool success, bytes memory result) = address(this).delegatecall(datas[i]);

            if (!success) {

                if (result.length < 68) revert();

                assembly {

                    result := add(result, 0x04)

                }
 
                revert(abi.decode(result, (string)));
 
            }
 
        }

    }

}