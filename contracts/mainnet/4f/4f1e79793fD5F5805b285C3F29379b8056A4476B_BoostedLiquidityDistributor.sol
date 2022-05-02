// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";

/// @notice Distributes rewards to LP providers.
/// @author Nation3 (https://github.com/nation3/app/blob/main/contracts/src/distributors/BoostedLiquidityDistributor.sol).
/// @dev Inspired by Rari-Capital rewards distributor (https://github.com/Rari-Capital/rari-governance-contracts/blob/master/contracts/RariGovernanceTokenUniswapDistributor.sol).
/// @dev Implemented boosted rewards mechanics from Curve Finance (https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/gauges/LiquidityGauge.vy)
contract BoostedLiquidityDistributor is Initializable, Ownable {
    /*///////////////////////////////////////////////////////////////
                               LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using SafeTransferLib for ERC20;

    /*///////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidStartBlock();
    error InvalidEndBlock();
    error InvalidRewardsAmount();
    error InsufficientDepositBalance();
    error InsufficientRewardsBalance();
    error KickNotAllowed();

    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event RewardsSet(uint256 amount, uint256 startBlock, uint256 endBlock);
    event Claim(address indexed user, uint256 rewards);
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event UpdatedBalances(address account, uint256 balance, uint256 totalBalance);

    /*///////////////////////////////////////////////////////////////
                        INMUTABLES / CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @dev % of the user deposited tokens that counts for working balance without boost
    uint256 internal constant BOOSTLESS_PRODUCTION = 40; // %
    /// @dev Used to correct precision errors on divisions.
    uint256 internal constant PRECISION = 1e30;

    /*///////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The token rewarded to LP providers.
    ERC20 public rewardsToken;
    /// @notice The LP token accepted to deposit by the contract.
    ERC20 public lpToken;
    /// @notice The token used to boost rewards.
    ERC20 public boostToken;

    /// @notice First block to distribute rewards.
    uint256 public startBlock;
    /// @notice Last block to distribute rewards.
    uint256 public endBlock;
    /// @notice Total LP tokens deposited by users.
    uint256 public totalDeposit;
    /// @notice Total balance of the contract after boosts.
    uint256 public totalBalance;
    /// @notice Total rewards beeing distributed.
    uint256 public totalRewards;
    /// @notice Total rewards already distributed to users.
    uint256 public distributedRewards;

    /// @dev Rewards per block on current rewards period.
    /// @dev Only changes on total rewards update.
    /// @dev Precision correction will be applied.
    uint256 internal _blockRewards;
    /// @dev Rewards per LP deposited token at last distribution.
    uint256 internal _rewardsRate;
    /// @dev Last block in which rewards have been distributed.
    uint256 internal _lastDistributedBlock;

    /// @dev Amount of LP tokens deposited by user.
    mapping(address => uint256) public userDeposit;
    /// @dev Balance of user deposit after boost
    mapping(address => uint256) public userBalance;

    /// @dev Rewards per LP token deposited at last user deposit.
    mapping(address => uint256) internal _userRatedRewards;
    /// @dev Distributed rewards to the user at last distribution.
    mapping(address => uint256) internal _userDistributedRewards;
    /// @dev Rewards claimed by user.
    mapping(address => uint256) internal _userClaimedRewards;

    /*///////////////////////////////////////////////////////////////
                             INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    /// @dev Sets both rewards, LP & boost token.
    /// @param _rewardsToken The contract of the rewards token.
    /// @param _lpToken The contract of the liquidity pool tokens.
    /// @param _boostToken The contract of boosting power balance.
    function initialize(
        ERC20 _rewardsToken,
        ERC20 _lpToken,
        address _boostToken
    ) external initializer {
        rewardsToken = _rewardsToken;
        lpToken = _lpToken;
        boostToken = ERC20(_boostToken);
    }

    /*///////////////////////////////////////////////////////////////
                              ADMIN ACTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Set rewards amount & rewards period duration, can be used to update rewards destribution anytime in the future.
    /// @param amount The amount of reward tokens to set as rewards, it expects this amount to be already transferred to the contract.
    /// @param _startBlock Initial block of the rewards distribution.
    /// @param _endBlock Final block of the rewards distribution.
    /// @dev If the rewardsToken contract has not been verified before this could lead to a reentrancy attack
    function setRewards(
        uint256 amount,
        uint256 _startBlock,
        uint256 _endBlock
    ) external virtual onlyOwner {
        if (_startBlock < block.number) revert InvalidStartBlock();
        if (_endBlock <= _startBlock) revert InvalidEndBlock();

        // Distribute possible pending rewards
        _updateRewardsdistribution();

        uint256 _distributedRewards = distributedRewards; // Gas savings
        if (amount <= _distributedRewards) revert InvalidRewardsAmount();
        if (amount - distributedRewards > rewardsToken.balanceOf(address(this))) revert InsufficientRewardsBalance();

        // Set / reset variables
        totalRewards = amount;
        startBlock = _startBlock;
        endBlock = _endBlock;
        // Compute rewards that must be distributed each block, precision correction applied.
        _blockRewards = ((amount - _distributedRewards) * PRECISION) / (_endBlock - _startBlock);

        emit RewardsSet(amount, _startBlock, _endBlock);
    }

    /// @notice Allow the owner to withdraw any ERC20 sent to the contract.
    /// @param token Token to withdraw.
    /// @param to Recipient address of the tokens.
    function recoverTokens(ERC20 token, address to) external virtual onlyOwner returns (uint256 amount) {
        amount = token.balanceOf(address(this));
        if (token == lpToken) {
            amount = amount - totalDeposit;
        } else if (token == rewardsToken) {
            amount = amount - totalRewards;
        }

        token.safeTransfer(to, amount);
    }

    /*///////////////////////////////////////////////////////////////
                                USER ACTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the quantity of unclaimed rewards earned by `account`.
    /// @param account The account of deposited LP tokens.
    /// @return The quantity of unclaimed rewards tokens.
    function getUnclaimedRewards(address account) external view virtual returns (uint256) {
        return _userDistributedRewards[account] - _userClaimedRewards[account];
    }

    /// @notice Kick an account for abusing the boost.
    /// @param account The account to update balances.
    /// @dev Only if their boost power expired.
    function kick(address account) external virtual {
        uint256 _userDeposit = userDeposit[account];
        if (userBalance[account] <= (_userDeposit * BOOSTLESS_PRODUCTION) / 100) revert KickNotAllowed();
        if (boostToken.balanceOf(account) > 0) revert KickNotAllowed();

        _distributeRewards(account);
        _updateBalances(account, _userDeposit, totalDeposit);
    }

    /// @notice Deposits `amount` of LP tokens from sender to this contract.
    /// @param amount The amount ot LP tokens to deposit.
    function deposit(uint256 amount) external virtual {
        // Transfer LP token from sender
        lpToken.safeTransferFrom(msg.sender, address(this), amount);
        uint256 _userDeposit = userDeposit[msg.sender];

        if (block.number > startBlock) {
            if (_userDeposit > 0) {
                // Distribute rewards until this point and update snapshot of rewards per LP Token
                _distributeRewards(msg.sender);
            } else {
                // On first deposit update distribution and set initial user snapshot of rewards per LP Token
                _updateRewardsdistribution();
                _userRatedRewards[msg.sender] = _rewardsRate;
            }
        }

        // Add to staking balance
        _userDeposit = _userDeposit + amount;
        userDeposit[msg.sender] = _userDeposit;
        totalDeposit = totalDeposit + amount;

        _updateBalances(msg.sender, _userDeposit, totalDeposit);

        emit Deposit(msg.sender, amount);
    }

    /// @notice Withdraws `amount` of LP tokens from this contract to sender.
    /// @param amount The amount of LP tokens to withdraw.
    function withdraw(uint256 amount) external virtual {
        uint256 _userDeposit = userDeposit[msg.sender];

        if (amount > _userDeposit) revert InsufficientDepositBalance();
        if (block.number > startBlock) _distributeRewards(msg.sender);

        // Substract from staking balance
        _userDeposit = _userDeposit - amount;
        userDeposit[msg.sender] = _userDeposit;
        totalDeposit = totalDeposit - amount;

        _updateBalances(msg.sender, _userDeposit, totalDeposit);

        // Transfer out to sender
        lpToken.safeTransfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount);
    }

    /// @notice Claims all of `msg.sender` unclaimed rewards.
    /// @return The quantity of rewards tokens claimed.
    function claimRewards() external virtual returns (uint256) {
        // Distribute rewards to account
        if (block.number > startBlock) _distributeRewards(msg.sender);

        // Get unclaimed rewards
        uint256 unclaimedRewards = _userDistributedRewards[msg.sender] - _userClaimedRewards[msg.sender];
        if (unclaimedRewards <= 0) revert InsufficientRewardsBalance();

        // Register claimed rewards and transfer out
        _userClaimedRewards[msg.sender] = _userClaimedRewards[msg.sender] + unclaimedRewards;

        _updateBalances(msg.sender, userDeposit[msg.sender], totalDeposit);

        rewardsToken.safeTransfer(msg.sender, unclaimedRewards);

        emit Claim(msg.sender, unclaimedRewards);

        return unclaimedRewards;
    }

    /// @notice Withdraw all LP tokens and unclaimed rewards to sender.
    /// @return withdrawAmount The staking amount drained.
    /// @return unclaimedRewards The quantity of rewards tokens claimed.
    function withdrawAndClaim() external virtual returns (uint256 withdrawAmount, uint256 unclaimedRewards) {
        // Distribute rewards to account
        if (block.number > startBlock) _distributeRewards(msg.sender);

        withdrawAmount = userDeposit[msg.sender];
        unclaimedRewards = _userDistributedRewards[msg.sender] - _userClaimedRewards[msg.sender];

        // Drain account staking and update claimed rewards
        userDeposit[msg.sender] = 0;
        totalDeposit = totalDeposit - withdrawAmount;
        _userClaimedRewards[msg.sender] = _userClaimedRewards[msg.sender] + unclaimedRewards;

        _updateBalances(msg.sender, 0, totalDeposit);

        // Transfer out LP tokens & rewards
        lpToken.safeTransfer(msg.sender, withdrawAmount);
        rewardsToken.safeTransfer(msg.sender, unclaimedRewards);

        emit Withdraw(msg.sender, withdrawAmount);
        emit Claim(msg.sender, unclaimedRewards);
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL DISTRIBUTION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Update user balance & total balance after boosts.
    /// @param account The LP token depositor whose balance is being updated.
    /// @param _userDeposit LP tokens deposited by the user to use as base balance.
    /// @param _totalDeposit Total LP tokens deposited in the contract.
    /// @dev If the boostToken contract hasn't been verified before this could lead to a reentrancy attack.
    function _updateBalances(
        address account,
        uint256 _userDeposit,
        uint256 _totalDeposit
    ) internal virtual {
        uint256 userPower = boostToken.balanceOf(account);
        uint256 totalPower = boostToken.totalSupply();

        // Calculate user balance after boost
        // min((userDeposit * 0.4) + (totalDeposit * userVotingPower / totalVotingPower * 0.6), (userDeposit * 0.4))
        uint256 workingBalance = (_userDeposit * BOOSTLESS_PRODUCTION) / 100;
        if (totalPower > 0) {
            workingBalance += (_totalDeposit * userPower * (100 - BOOSTLESS_PRODUCTION)) / (totalPower * 100);
        }
        workingBalance = Math.min(_userDeposit, workingBalance);

        // Update boosted balances
        uint256 lastUserBalance = userBalance[account];
        userBalance[account] = workingBalance;
        totalBalance = totalBalance + workingBalance - lastUserBalance;

        emit UpdatedBalances(account, workingBalance, totalBalance);
    }

    /// @dev Distributes all undistributed rewards earned by `account`.
    /// @dev Do not reverts if there is no rewards to distribute.
    /// @param account The LP Token depositor whose rewards are to be distributed.
    /// @return The quantity of rewards distributed.
    function _distributeRewards(address account) internal virtual returns (uint256) {
        uint256 _userBalance = userBalance[account];
        if (_userBalance <= 0) return 0;

        _updateRewardsdistribution();

        // Compute undistributed rewards from the delta in rewardsRate since the user deposited
        uint256 undistributedRewards = (_userBalance * (_rewardsRate - _userRatedRewards[account])) / PRECISION;
        if (undistributedRewards <= 0) return 0;

        _userRatedRewards[account] = _rewardsRate;
        _userDistributedRewards[account] = _userDistributedRewards[account] + undistributedRewards;

        return undistributedRewards;
    }

    /// @dev Updates rewards distribution values.
    /// Distributes rewards in all blocks, including empty staking ones.
    function _updateRewardsdistribution() internal virtual {
        if (totalRewards <= 0) return;
        if (endBlock <= _lastDistributedBlock) return;
        if (_lastDistributedBlock < startBlock) _lastDistributedBlock = startBlock;

        uint256 blocksToDistribute;
        if (block.number <= endBlock) {
            blocksToDistribute = block.number - _lastDistributedBlock;
        } else {
            blocksToDistribute = endBlock - _lastDistributedBlock;
        }

        uint256 rewardsToDistribute = _blockRewards * blocksToDistribute;

        if (rewardsToDistribute <= 0) return;

        _lastDistributedBlock = block.number;

        // Update rewards per LP token only if there are deposited tokens
        if (totalBalance > 0) {
            distributedRewards = distributedRewards + rewardsToDistribute / PRECISION;
            _rewardsRate = _rewardsRate + rewardsToDistribute / totalBalance;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !Address.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}