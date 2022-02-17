// SPDX-License-Identifier: MIT
// Audit on 5-Jan-2021 by Keno and BoringCrypto

// P1 - P3: OK
pragma solidity 0.6.12;

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

// T1 - T4: OK
contract BoringOwnableData {
    // V1 - V5: OK
    address public owner;
    // V1 - V5: OK
    address public pendingOwner;
}

// T1 - T4: OK
contract BoringOwnable is BoringOwnableData {
    // E1: OK
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function transferOwnership(address newOwner, bool direct, bool renounce) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;
        
        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    // M1 - M5: OK
    // C1 - C21: OK
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // EIP 2612
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "../interfaces/IERC20.sol";

library BoringERC20 {
    function safeSymbol(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x95d89b41));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeName(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x06fdde03));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x313ce567));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
// a library for performing overflow-safe math, updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math)
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {require(b == 0 || (c = a * b)/b == a, "BoringMath: Mul Overflow");}
    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "BoringMath: uint128 Overflow");
        c = uint128(a);
    }
    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= uint64(-1), "BoringMath: uint64 Overflow");
        c = uint64(a);
    }
    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= uint32(-1), "BoringMath: uint32 Overflow");
        c = uint32(a);
    }
}

library BoringMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
}

library BoringMath64 {
    function add(uint64 a, uint64 b) internal pure returns (uint64 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint64 a, uint64 b) internal pure returns (uint64 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
}

library BoringMath32 {
    function add(uint32 a, uint32 b) internal pure returns (uint32 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity-e06e943/contracts/libraries/BoringERC20.sol";

interface IRewarder {
    using BoringERC20 for IERC20;

    function onSaddleReward(
        uint256 pid,
        address user,
        address recipient,
        uint256 saddleAmount,
        uint256 newLpAmount
    ) external;

    function pendingTokens(
        uint256 pid,
        address user,
        uint256 saddleAmount
    ) external view returns (IERC20[] memory, uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@boringcrypto/boring-solidity-e06e943/contracts/libraries/BoringERC20.sol";
import "@boringcrypto/boring-solidity-e06e943/contracts/libraries/BoringMath.sol";
import "@boringcrypto/boring-solidity-e06e943/contracts/BoringOwnable.sol";
import "../interfaces/IRewarder.sol";

interface IMiniChef {
    function lpToken(uint256 pid) external view returns (IERC20 _lpToken);
}

/**
 * @title SimpleRewarder
 * @notice Rewarder contract that can add one additional reward token to a specific PID in MiniChef.
 * Emission rate is controlled by the owner of this contract, independently from MiniChef's owner.
 * @author @0xKeno @weeb_mcgee
 */
contract SimpleRewarder is IRewarder, BoringOwnable {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using BoringERC20 for IERC20;

    uint256 private constant ACC_TOKEN_PRECISION = 1e12;

    /// @notice Info of each Rewarder user.
    /// `amount` LP token amount the user has provided.
    /// `rewardDebt` The amount of Reward Token entitled to the user.
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    /// @notice Info of the rewarder pool
    struct PoolInfo {
        uint128 accToken1PerShare;
        uint64 lastRewardTime;
    }

    /// @notice Address of the token that should be given out as rewards.
    IERC20 public rewardToken;

    /// @notice Var to track the rewarder pool.
    PoolInfo public poolInfo;

    /// @notice Info of each user that stakes LP tokens.
    mapping(address => UserInfo) public userInfo;

    /// @notice Total emission rate of the reward token per second
    uint256 public rewardPerSecond;
    /// @notice Address of the lp token that should be incentivized
    IERC20 public masterLpToken;
    /// @notice PID in MiniChef that corresponds to masterLpToken
    uint256 public pid;

    /// @notice MiniChef contract that will call this contract's callback function
    address public immutable MINICHEF;

    event LogOnReward(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        address indexed to
    );
    event LogUpdatePool(
        uint256 indexed pid,
        uint64 lastRewardTime,
        uint256 lpSupply,
        uint256 accToken1PerShare
    );
    event LogRewardPerSecond(uint256 rewardPerSecond);
    event LogInit(
        IERC20 indexed rewardToken,
        address owner,
        uint256 rewardPerSecond,
        IERC20 indexed masterLpToken
    );

    /**
     * @notice Deploys this contract and sets immutable MiniChef address.
     */
    constructor(address _MINICHEF) public {
        MINICHEF = _MINICHEF;
    }

    /**
     * @notice Modifier to restrict caller to be only MiniChef
     */
    modifier onlyMiniChef() {
        require(msg.sender == MINICHEF, "Rewarder: caller is not MiniChef");
        _;
    }

    /**
     * @notice Serves as the constructor for clones, as clones can't have a regular constructor.
     * Initializes state varialbes with the given parameter.
     * @param data abi encoded data in format of (IERC20 rewardToken, address owner, uint256 rewardPerSecond, IERC20 masterLpToken, uint256 pid).
     */
    function init(bytes calldata data) public payable {
        require(rewardToken == IERC20(0), "Rewarder: already initialized");
        address _owner;
        (rewardToken, _owner, rewardPerSecond, masterLpToken, pid) = abi.decode(
            data,
            (IERC20, address, uint256, IERC20, uint256)
        );
        require(rewardToken != IERC20(0), "Rewarder: bad rewardToken");
        require(
            IMiniChef(MINICHEF).lpToken(pid) == masterLpToken,
            "Rewarder: bad pid or masterLpToken"
        );
        transferOwnership(_owner, true, false);
        emit LogInit(rewardToken, _owner, rewardPerSecond, masterLpToken);
    }

    /**
     * @notice Callback function for when the user claims via the MiniChef contract.
     * @param _pid PID of the pool it was called for
     * @param _user address of the user who is claiming rewards
     * @param to address to send the reward token to
     * @param lpTokenAmount amount of total lp tokens that the user has it staked
     */
    function onSaddleReward(
        uint256 _pid,
        address _user,
        address to,
        uint256,
        uint256 lpTokenAmount
    ) external override onlyMiniChef {
        require(pid == _pid, "Rewarder: bad pid init");

        PoolInfo memory pool = updatePool();
        UserInfo storage user = userInfo[_user];
        uint256 pending;
        if (user.amount > 0) {
            pending = (user.amount.mul(pool.accToken1PerShare) /
                ACC_TOKEN_PRECISION).sub(user.rewardDebt);
            rewardToken.safeTransfer(to, pending);
        }
        user.amount = lpTokenAmount;
        user.rewardDebt =
            lpTokenAmount.mul(pool.accToken1PerShare) /
            ACC_TOKEN_PRECISION;
        emit LogOnReward(_user, pid, pending, to);
    }

    /**
     * @notice Sets the reward token per second to be distributed. Can only be called by the owner.
     * @param _rewardPerSecond The amount of reward token to be distributed per second.
     */
    function setRewardPerSecond(uint256 _rewardPerSecond) public onlyOwner {
        rewardPerSecond = _rewardPerSecond;
        emit LogRewardPerSecond(_rewardPerSecond);
    }

    /**
     * @notice View function to see pending rewards for given address
     * @param _user Address of user.
     * @return pending reward for a given user.
     */
    function pendingToken(address _user) public view returns (uint256 pending) {
        PoolInfo memory pool = poolInfo;
        UserInfo storage user = userInfo[_user];
        uint256 accToken1PerShare = pool.accToken1PerShare;
        uint256 lpSupply = IMiniChef(MINICHEF).lpToken(pid).balanceOf(MINICHEF);
        if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
            uint256 time = block.timestamp.sub(pool.lastRewardTime);
            uint256 reward = time.mul(rewardPerSecond);
            accToken1PerShare = accToken1PerShare.add(
                reward.mul(ACC_TOKEN_PRECISION) / lpSupply
            );
        }
        pending = (user.amount.mul(accToken1PerShare) / ACC_TOKEN_PRECISION)
            .sub(user.rewardDebt);
    }

    /**
     * @notice Returns pending reward tokens addresses and reward amounts for given address,
     * @dev Since SimpleRewarder supports only one additional reward, the returning arrays will only have one element.
     * @param user address of the user
     * @return rewardTokens array of reward tokens' addresses
     * @return rewardAmounts array of reward tokens' amounts
     */
    function pendingTokens(
        uint256,
        address user,
        uint256
    )
        external
        view
        override
        returns (IERC20[] memory rewardTokens, uint256[] memory rewardAmounts)
    {
        IERC20[] memory _rewardTokens = new IERC20[](1);
        _rewardTokens[0] = (rewardToken);
        uint256[] memory _rewardAmounts = new uint256[](1);
        _rewardAmounts[0] = pendingToken(user);
        return (_rewardTokens, _rewardAmounts);
    }

    /**
     * @notice Updates the stored rate of emission per share since the last time this function was called.
     * @dev This is called whenever `onSaddleReward` is called to ensure the rewards are given out with the
     * correct emission rate.
     */
    function updatePool() public returns (PoolInfo memory pool) {
        pool = poolInfo;
        if (block.timestamp > pool.lastRewardTime) {
            uint256 lpSupply = IMiniChef(MINICHEF).lpToken(pid).balanceOf(
                MINICHEF
            );

            if (lpSupply > 0) {
                uint256 time = block.timestamp.sub(pool.lastRewardTime);
                uint256 reward = time.mul(rewardPerSecond);
                pool.accToken1PerShare = pool.accToken1PerShare.add(
                    (reward.mul(ACC_TOKEN_PRECISION) / lpSupply).to128()
                );
            }
            pool.lastRewardTime = block.timestamp.to64();
            poolInfo = pool;
            emit LogUpdatePool(
                pid,
                pool.lastRewardTime,
                lpSupply,
                pool.accToken1PerShare
            );
        }
    }
}