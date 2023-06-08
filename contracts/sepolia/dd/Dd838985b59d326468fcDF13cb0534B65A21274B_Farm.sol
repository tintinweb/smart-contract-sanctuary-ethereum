pragma solidity 0.8.17;

// SPDX-License-Identifier: AGPL-3.0

import "interfaces/IAgency.sol";
import "interfaces/IERC20Mintable.sol";
import "interfaces/IGauge.sol";
import "./ABDKMath64x64.sol";
import "./TransferHelper.sol";

/// @title Contract for Dyson user to earn extra rewards.
/// A DysonPair and a Gauge contract together form a pool.
/// This contract will record reward related info about each pools.
/// Each DysonPair will trigger `Farm.grantAP` upon user deposit,
/// it will add to user's AP balance.
/// User can call `Farm.swap` to swap AP token to gov token, i.e., Dyson token.
contract Farm {
    using ABDKMath64x64 for *;
    using TransferHelper for address;

    int128 private constant MAX_AP_RATIO = 2**64;
    uint private constant BONUS_BASE_UNIT = 1e18;
    /// @notice Cooldown before user can swap his AP to gov token
    uint private constant CD = 6000;
    IAgency public immutable agency;
    /// @notice Governance token, i.e., Dyson token
    IERC20Mintable public immutable gov;

    address public owner;

    /// @member weight A parameter in the exchange formula when converting localAP to globalAP or converting globalAP to Dyson.
    /// The higher the weight, the lower the reward
    /// @member rewardRate Pool reward rate. The higher the rate, the faster the reserve grows
    /// @member lastUpdateTime Last time the pool reserve is updated
    /// @member lastReserve The pool reserve amount when last updated
    /// @member gauge Gauge contract of the pool which records the pool's weight and rewardRate
    struct Pool {
        uint weight;
        uint rewardRate;
        uint lastUpdateTime;
        uint lastReserve;
        address gauge;
    }

    /// @notice The special pool for gov token
    Pool public globalPool;

    /// Param poolId Id of the pool. Note that pool id is the address of DysonPair contract
    mapping(address => Pool) public pools;
    /// @notice User's AP balance
    mapping(address => uint) public balanceOf;
    /// @notice Timestamp when user's cooldown ends
    mapping(address => uint) public cooldown;

    event TransferOwnership(address newOwner);
    event RateUpdated(address indexed poolId, uint rewardRate, uint weight);
    event GrantAP(address indexed user, address indexed poolId, uint amountIn, uint amountOut);
    event Swap(address indexed user, address indexed parent, uint amountIn, uint amountOut);

    constructor(address _owner, address _agency, address _gov) {
        require(_owner != address(0), "OWNER_CANNOT_BE_ZERO");
        owner = _owner;
        agency = IAgency(_agency);
        gov = IERC20Mintable(_gov);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "FORBIDDEN");
        _;
    }

    function transferOwnership(address _owner) external onlyOwner {
        require(_owner != address(0), "OWNER_CANNOT_BE_ZERO");
        owner = _owner;

        emit TransferOwnership(_owner);
    }

    /// @notice rescue token stucked in this contract
    /// @param tokenAddress Address of token to be rescued
    /// @param to Address that will receive token
    /// @param amount Amount of token to be rescued
    function rescueERC20(address tokenAddress, address to, uint256 amount) onlyOwner external {
        tokenAddress.safeTransfer(to, amount);
    }

    /// @dev Set the Gauge contract for given pool
    /// @param poolId Pool Id, i.e., address of the DysonPair contract
    /// @param gauge address of the Gauge contract
    function setPool(address poolId, address gauge) external onlyOwner {
        Pool storage pool = pools[poolId];
        pool.gauge = gauge;
        pool.lastReserve = getCurrentPoolReserve(poolId);
        pool.lastUpdateTime = block.timestamp;
        pool.rewardRate = IGauge(gauge).nextRewardRate();
        pool.weight = IGauge(gauge).weight();
        emit RateUpdated(poolId, pool.rewardRate, pool.weight);
    }

    /// @dev Update given pool's `weight` and `rewardRate`, triggered by the pool's Gauge contract
    /// @param poolId Pool Id, i.e., address of the DysonPair contract
    /// @param rewardRate New `rewardRate`
    /// @param weight New `weight`
    function setPoolRewardRate(address poolId, uint rewardRate, uint weight) external {
        Pool storage pool = pools[poolId];
        require(pool.gauge == msg.sender, "NOT GAUGE");
        pool.lastReserve = getCurrentPoolReserve(poolId);
        pool.lastUpdateTime = block.timestamp;
        pool.rewardRate = rewardRate;
        pool.weight = weight;
        emit RateUpdated(poolId, rewardRate, weight);
    }

    /// @notice Update gov token pool's `rewardRate` and `weight`
    /// @param rewardRate New `rewardRate`
    /// @param weight New `weight`
    function setGlobalRewardRate(uint rewardRate, uint weight) external onlyOwner {
        globalPool.lastReserve = getCurrentGlobalReserve();
        globalPool.lastUpdateTime = block.timestamp;
        globalPool.rewardRate = rewardRate;
        globalPool.weight = weight;
        emit RateUpdated(address(this), rewardRate, weight);
    }

    /// @notice Get current reserve amount of given pool
    /// @param poolId Pool Id, i.e., address of the DysonPair contract
    /// @return reserve Current reserve amount
    function getCurrentPoolReserve(address poolId) public view returns (uint reserve) {
        Pool storage pool = pools[poolId];
        reserve = (block.timestamp - pool.lastUpdateTime) * pool.rewardRate + pool.lastReserve;
    }

    /// @notice Get current reserve amount of gov token pool
    /// @return reserve Current reserve amount
    function getCurrentGlobalReserve() public view returns (uint reserve) {
        reserve = (block.timestamp - globalPool.lastUpdateTime) * globalPool.rewardRate + globalPool.lastReserve;
    }

    /// @dev Calculate reward amount with given amount, reserve amount and weight:
    /// reward = reserve * (1 - 2^(-amount/w))
    /// @param _reserve Reserve amount
    /// @param _amount LocalAP or GlobalAP amount
    /// @param _w Weight
    /// @return reward Reward amount in either globalAP or gov token
    function _calcRewardAmount(uint _reserve, uint _amount, uint _w) internal pure returns (uint reward) {
        int128 r = _amount.divu(_w);
        int128 e = (-r).exp_2();
        reward = (MAX_AP_RATIO - e).mulu(_reserve);
    }

    /// @notice Triggered by DysonPair contract to grant user AP upon user deposit
    /// If user also stake his sGov token, i.e., sDyson token in the pool's Gauge contract, he will receive bouns localAP.
    /// @dev The pool's `lastReserve` and `lastUpdateTime` are updated each time `grantAP` is triggered 
    /// @param to User's address
    /// @param amount Amount of localAP
    function grantAP(address to, uint amount) external {
        if(agency.whois(to) == 0) return;
        Pool storage pool = pools[msg.sender];
        // check pool bonus
        uint bonus = IGauge(pool.gauge).bonus(to);
        if (bonus > 0) amount = amount * (bonus + BONUS_BASE_UNIT) / BONUS_BASE_UNIT;
        // swap localAP to globalAP
        uint reserve = getCurrentPoolReserve(msg.sender);
        uint APAmount = _calcRewardAmount(reserve, amount, pool.weight);

        pool.lastReserve = reserve - APAmount;
        pool.lastUpdateTime = block.timestamp;
        balanceOf[to] += APAmount;
        emit GrantAP(to, msg.sender, amount, APAmount);
    }

    /// @notice Swap given `user`'s AP to gov token.
    /// This can be done by a third party.
    /// User can only swap if his cooldown has ended. Cooldown time depends on user's generation in the referral system.
    /// User need to register in the referral system to be able to swap.
    /// User's referrer will receive 1/3 of user's AP upon swap.
    function swap(address user) external returns (uint amountOut) {
        require(block.timestamp > cooldown[user], "CD");
        if(agency.whois(user) == 0) return 0;
        (address ref, uint gen) = agency.userInfo(user);
        cooldown[user] = block.timestamp + (gen + 1) * CD;

        // swap ap to token
        uint reserve = getCurrentGlobalReserve();

        uint amountIn = balanceOf[user];
        balanceOf[user] = 0;
        require(amountIn > 0 ,"NO AP");

        amountOut = _calcRewardAmount(reserve, amountIn, globalPool.weight);

        globalPool.lastReserve = reserve - amountOut;
        globalPool.lastUpdateTime = block.timestamp;
        // referral
        balanceOf[ref] += amountIn / 3;
        // mint token
        gov.mint(user, amountOut);
        emit Swap(user, ref, amountIn, amountOut);
    }

}

pragma solidity >=0.8.0;

// SPDX-License-Identifier: MIT

interface IAgency {
    function whois(address agent) external view returns (uint);
    function userInfo(address agent) external view returns (address ref, uint gen);
    function transfer(address from, address to, uint id) external returns (bool);
    function totalSupply() external view returns (uint);
    function getAgent(uint id) external view returns (address, uint, uint, uint, uint[] memory);
    function adminAdd(address newUser) external returns (uint id);
}

pragma solidity >=0.8.0;

// SPDX-License-Identifier: MIT

interface IERC20Mintable {
    function mint(address to, uint amount) external returns (bool);
}

pragma solidity >=0.8.0;

// SPDX-License-Identifier: MIT

interface IGauge {
    function bonus(address) external view returns (uint);
    function nextRewardRate() external view returns (uint);
    function weight() external view returns (uint);
    function balanceOfAt(address account, uint week) external view returns (uint);
    function totalSupplyAt(uint week) external view returns (uint);
    function genesis() external view returns (uint);
}

pragma solidity 0.8.17;

// SPDX-License-Identifier: AGPL-3.0

library ABDKMath64x64 {
    /*
     * Minimum value signed 64.64-bit fixed point number may have.
     * -2^127
     */
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

    /*
     * Maximum value signed 64.64-bit fixed point number may have.
     * 2^127-1
     */
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /**
     * Calculate x * y rounding down, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y unsigned 256-bit integer number
     * @return unsigned 256-bit integer number
     */
    function mulu (int128 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            if (y == 0) return 0;

            require (x >= 0);

            uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
            uint256 hi = uint256 (int256 (x)) * (y >> 128);

            require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            hi <<= 64;

            require (hi <=
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
            return hi + lo;
        }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divu (uint256 x, uint256 y) internal pure returns (int128) {
        unchecked {
            require (y != 0);
            uint128 result = divuu (x, y);
            require (result <= uint128 (MAX_64x64));
            return int128 (result);
        }
    }

    /**
     * Calculate binary exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp_2 (int128 x) internal pure returns (int128) {
        unchecked {
            require (x < 0x400000000000000000); // Overflow

            if (x < -0x400000000000000000) return 0; // Underflow

            uint256 result = 0x80000000000000000000000000000000;

            if (x & 0x8000000000000000 > 0)
                result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
            if (x & 0x4000000000000000 > 0)
                result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
            if (x & 0x2000000000000000 > 0)
                result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
            if (x & 0x1000000000000000 > 0)
                result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
            if (x & 0x800000000000000 > 0)
                result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
            if (x & 0x400000000000000 > 0)
                result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
            if (x & 0x200000000000000 > 0)
                result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
            if (x & 0x100000000000000 > 0)
                result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
            if (x & 0x80000000000000 > 0)
                result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
            if (x & 0x40000000000000 > 0)
                result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
            if (x & 0x20000000000000 > 0)
                result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
            if (x & 0x10000000000000 > 0)
                result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
            if (x & 0x8000000000000 > 0)
                result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
            if (x & 0x4000000000000 > 0)
                result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
            if (x & 0x2000000000000 > 0)
                result = result * 0x1000162E525EE054754457D5995292026 >> 128;
            if (x & 0x1000000000000 > 0)
                result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
            if (x & 0x800000000000 > 0)
                result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
            if (x & 0x400000000000 > 0)
                result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
            if (x & 0x200000000000 > 0)
                result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
            if (x & 0x100000000000 > 0)
                result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
            if (x & 0x80000000000 > 0)
                result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
            if (x & 0x40000000000 > 0)
                result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
            if (x & 0x20000000000 > 0)
                result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
            if (x & 0x10000000000 > 0)
                result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
            if (x & 0x8000000000 > 0)
                result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
            if (x & 0x4000000000 > 0)
                result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
            if (x & 0x2000000000 > 0)
                result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
            if (x & 0x1000000000 > 0)
                result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
            if (x & 0x800000000 > 0)
                result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
            if (x & 0x400000000 > 0)
                result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
            if (x & 0x200000000 > 0)
                result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
            if (x & 0x100000000 > 0)
                result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
            if (x & 0x80000000 > 0)
                result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
            if (x & 0x40000000 > 0)
                result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
            if (x & 0x20000000 > 0)
                result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
            if (x & 0x10000000 > 0)
                result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
            if (x & 0x8000000 > 0)
                result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
            if (x & 0x4000000 > 0)
                result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
            if (x & 0x2000000 > 0)
                result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
            if (x & 0x1000000 > 0)
                result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
            if (x & 0x800000 > 0)
                result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
            if (x & 0x400000 > 0)
                result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
            if (x & 0x200000 > 0)
                result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
            if (x & 0x100000 > 0)
                result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
            if (x & 0x80000 > 0)
                result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
            if (x & 0x40000 > 0)
                result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
            if (x & 0x20000 > 0)
                result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
            if (x & 0x10000 > 0)
                result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
            if (x & 0x8000 > 0)
                result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
            if (x & 0x4000 > 0)
                result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
            if (x & 0x2000 > 0)
                result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
            if (x & 0x1000 > 0)
                result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
            if (x & 0x800 > 0)
                result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
            if (x & 0x400 > 0)
                result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
            if (x & 0x200 > 0)
                result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
            if (x & 0x100 > 0)
                result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
            if (x & 0x80 > 0)
                result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
            if (x & 0x40 > 0)
                result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
            if (x & 0x20 > 0)
                result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
            if (x & 0x10 > 0)
                result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
            if (x & 0x8 > 0)
                result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
            if (x & 0x4 > 0)
                result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
            if (x & 0x2 > 0)
                result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
            if (x & 0x1 > 0)
                result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

            result >>= uint256 (int256 (63 - (x >> 64)));
            require (result <= uint256 (int256 (MAX_64x64)));

            return int128 (int256 (result));
        }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return unsigned 64.64-bit fixed point number
     */
    function divuu (uint256 x, uint256 y) private pure returns (uint128) {
        unchecked {
            require (y != 0);

            uint256 result;

            if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                result = (x << 64) / y;
            else {
                uint256 msb = 192;
                uint256 xc = x >> 192;
                if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
                if (xc >= 0x10000) { xc >>= 16; msb += 16; }
                if (xc >= 0x100) { xc >>= 8; msb += 8; }
                if (xc >= 0x10) { xc >>= 4; msb += 4; }
                if (xc >= 0x4) { xc >>= 2; msb += 2; }
                if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

                result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
                require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

                uint256 hi = result * (y >> 128);
                uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

                uint256 xh = x >> 192;
                uint256 xl = x << 64;

                if (xl < lo) xh -= 1;
                xl -= lo; // We rely on overflow behavior here
                lo = hi << 128;
                if (xl < lo) xh -= 1;
                xl -= lo; // We rely on overflow behavior here

                assert (xh == hi >> 128);

                result += xl / y;
            }

            require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return uint128 (result);
        }
    }
}

pragma solidity 0.8.17;

// SPDX-License-Identifier: AGPL-3.0

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
}