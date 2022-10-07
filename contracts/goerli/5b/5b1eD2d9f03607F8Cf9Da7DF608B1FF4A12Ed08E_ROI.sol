// SPDX-License-Identifier: GNU GPLv3

pragma solidity 0.8.17;

import "./Ownable.sol";
import "./SafeMathUpgradeable.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

import "./ITreasury.sol";
import "./IStabl3Staking.sol";

contract ROI is Ownable, ReentrancyGuard, IStabl3StakingStruct {
    using SafeMathUpgradeable for uint256;
    using SafeERC20 for IERC20;

    uint256 private immutable MAX_INT = 2 ** 256 - 1;

    uint8 private constant BUY_POOL = 0;

    uint8 private constant BOND_POOL = 1;

    uint8 private constant STAKE_POOL = 2;
    uint8 private constant STAKE_REWARD_POOL = 3;
    uint8 private constant LEND_POOL = 5;
    uint8 private constant LEND_REWARD_POOL = 6;

    ITreasury public treasury;

    IERC20 public stabl3;

    IERC20 public ucd;

    IStabl3Staking public stabl3Staking;
    uint256 public maxPoolPercentage;

    // mappings

    // contracts with permission to access ROI pool funds
    mapping (address => bool) public permitted;

    // events

    event UpdatedTreasury(address newTreasury, address oldTreasury);

    event UpdatedPermission(address contractAddress, bool state);

    event APR(uint256 APR, uint256 reserves, uint256 totalRewardDistributed, uint256 blockTimestampLast);

    // constructor

    constructor(ITreasury _treasury) {
        treasury = _treasury;

        stabl3 = IERC20(0xDf9c4990a8973b6cC069738592F27Ea54b27D569);

        maxPoolPercentage = 700;

        updatePermission(address(_treasury), true);
    }

    function updateTreasury(address _treasury) external onlyOwner {
        require(address(treasury) != _treasury, "ROI: Treasury is already this address");
        updatePermission(address(treasury), false);
        updatePermission(_treasury, true);
        emit UpdatedTreasury(_treasury, address(treasury));
        treasury = ITreasury(_treasury);
    }

    function initializeUCD(address _ucd) external onlyOwner {
        require(address(ucd) != _ucd, "ROI: UCD is already this address");
        ucd = IERC20(_ucd);
    }

    function updateStabl3Staking(address _stabl3Staking) external onlyOwner {
        require(address(stabl3Staking) != _stabl3Staking, "ROI: Stabl3 Staking is already this address");
        stabl3Staking = IStabl3Staking(_stabl3Staking);
    }

    function updateMaxPoolPercentage(uint256 _maxPoolPercentage) external onlyOwner {
        require(maxPoolPercentage != _maxPoolPercentage, "Stabl3Staking: Max Pool Percentage is already this value");
        maxPoolPercentage = _maxPoolPercentage;
    }

    function updatePermission(address _contractAddress, bool _state) public onlyOwner {
        require(permitted[_contractAddress] != _state, "ROI: Address is already of the value 'state'");
        permitted[_contractAddress] = _state;

        if (_state) {
            delegateApprove(stabl3, _contractAddress, true);

            // delegateApprove(ucd, _contractAddress, true);

            for (uint256 i = 0 ; i < treasury.allReservedTokensLength() ; i++) {
                delegateApprove(treasury.allReservedTokens(i), _contractAddress, true);
            }
        }
        else {
            delegateApprove(stabl3, _contractAddress, false);

            // delegateApprove(ucd, _contractAddress, false);

            for (uint256 i = 0 ; i < treasury.allReservedTokensLength() ; i++) {
                delegateApprove(treasury.allReservedTokens(i), _contractAddress, false);
            }
        }

        emit UpdatedPermission(_contractAddress, _state);
    }

    function getTotalRewardDistributed() public view returns (uint256) {
        uint256 totalRewardDistributed;

        for (uint256 i = 0 ; i < treasury.allReservedTokensLength() ; i++) {
            IERC20 reservedToken = treasury.allReservedTokens(i);

            if (treasury.isReservedToken(reservedToken)) {
                uint256 stakeRewardAmount = treasury.sumOfAllPools(STAKE_REWARD_POOL, reservedToken);
                uint256 lendRewardAmount = treasury.sumOfAllPools(LEND_REWARD_POOL, reservedToken);

                uint256 decimals = reservedToken.decimals();

                if (decimals < 18) {
                    stakeRewardAmount *= 10 ** (18 - decimals);
                    lendRewardAmount *= 10 ** (18 - decimals);
                }

                totalRewardDistributed += stakeRewardAmount + lendRewardAmount;
            }
        }

        return totalRewardDistributed;
    }

    function getReserves() public view returns (uint256) {
        uint256 totalReserves;

        for (uint256 i = 0 ; i < treasury.allReservedTokensLength() ; i++) {
            IERC20 reservedToken = treasury.allReservedTokens(i);

            if (treasury.isReservedToken(reservedToken)) {
                uint256 amount = reservedToken.balanceOf(address(this));

                uint256 decimals = reservedToken.decimals();

                if (decimals < 18) {
                    amount *= 10 ** (18 - decimals);
                }

                totalReserves += amount;
            }
        }

        return totalReserves;
    }

    // APR is in 18 decimals
    function getAPR() public view returns (uint256) {
        uint256 totalStakedAmount;
        uint256 totalLendedAmount;

        for (uint256 i = 0 ; i < treasury.allReservedTokensLength() ; i++) {
            IERC20 reservedToken = treasury.allReservedTokens(i);

            if (treasury.isReservedToken(reservedToken)) {
                // HQ Pool is included in the Treasury Pool since it earns APR, hence no need to it to either staked or lended amounts
                uint256 stakedAmount = treasury.getTreasuryPool(STAKE_POOL, reservedToken);
                stakedAmount += treasury.getROIPool(STAKE_POOL, reservedToken);                 // ROI Pool for staking is 0 by default
                uint256 lendedAmount = treasury.getTreasuryPool(LEND_POOL, reservedToken);
                lendedAmount += treasury.getROIPool(LEND_POOL, reservedToken);                  // ROI Pool for lending is 0 by default

                uint256 decimalsReservedToken = reservedToken.decimals();

                if (decimalsReservedToken < 18) {
                    stakedAmount *= 10 ** (18 - decimalsReservedToken);
                    lendedAmount *= 10 ** (18 - decimalsReservedToken);
                }

                totalStakedAmount += stakedAmount;
                totalLendedAmount += lendedAmount;
            }
        }

        uint256 totalROIReserves = getReserves();

        uint256 currentAPR;
        if (totalStakedAmount != 0 || totalLendedAmount != 0) {
            currentAPR = (totalROIReserves * (10 ** 18)) / (totalStakedAmount + totalLendedAmount);
        }

        return currentAPR;
    }

    function validatePool(
        IERC20 _token,
        uint256 _amountToken
    ) public view returns (uint256 maxPool, uint256 currentPool) {
        for (uint256 i = 0 ; i < treasury.allReservedTokensLength() ; i++) {
            IERC20 reservedToken = treasury.allReservedTokens(i);

            if (treasury.isReservedToken(reservedToken)) {
                uint256 boughtAmountReservedToken = treasury.getTreasuryPool(BUY_POOL, reservedToken);
                uint256 bondedAmountReservedToken = treasury.getTreasuryPool(BOND_POOL, reservedToken);

                uint256 stakedAmountReservedToken = treasury.getTreasuryPool(STAKE_POOL, reservedToken);
                stakedAmountReservedToken += treasury.getROIPool(STAKE_POOL, reservedToken);
                uint256 lendedAmountReservedToken = treasury.getTreasuryPool(LEND_POOL, reservedToken);
                lendedAmountReservedToken += treasury.getROIPool(LEND_POOL, reservedToken);

                uint256 decimalsReservedToken = reservedToken.decimals();

                if (decimalsReservedToken < 18) {
                    boughtAmountReservedToken = boughtAmountReservedToken * (10 ** (18 - decimalsReservedToken));
                    bondedAmountReservedToken = bondedAmountReservedToken * (10 ** (18 - decimalsReservedToken));
                    stakedAmountReservedToken = stakedAmountReservedToken * (10 ** (18 - decimalsReservedToken));
                    lendedAmountReservedToken = lendedAmountReservedToken * (10 ** (18 - decimalsReservedToken));
                }

                maxPool += boughtAmountReservedToken + bondedAmountReservedToken;
                currentPool += stakedAmountReservedToken + lendedAmountReservedToken;
            }
        }

        maxPool = maxPool.mul(maxPoolPercentage).div(1000);

        if (_token.decimals() < 18) {
            _amountToken *= 10 ** (18 - _token.decimals());
        }
 
        currentPool += _amountToken;

        uint256 amountUnlocked;

        for (uint256 i = 0 ; i < stabl3Staking.allStakersLength() ; i++) {
            address staker = stabl3Staking.allStakers(i);

            if (stabl3Staking.getStakers(staker)) {
                (Staking[] memory unlockedLending, , Staking[] memory unlockedStaking, ) = stabl3Staking.allStakings(staker, false);
                (, , Staking[] memory unlockedRealEstate, ) = stabl3Staking.allStakings(staker, true);

                uint256 maxLength = unlockedLending.length.max(unlockedStaking.length).max(unlockedRealEstate.length);

                for (uint256 j = 0 ; j < maxLength ; j++) {
                    if (j < unlockedLending.length) {
                        uint256 amountLendedUnlocked = unlockedLending[j].amountTokenStaked;

                        if (unlockedLending[j].token.decimals() < 18) {
                            amountLendedUnlocked *= 10 ** (18 - unlockedLending[j].token.decimals());
                        }

                        amountUnlocked += amountLendedUnlocked;
                    }

                    if (j < unlockedStaking.length) {
                        uint256 amountStakedUnlocked = unlockedStaking[j].amountTokenStaked;

                        if (unlockedStaking[j].token.decimals() < 18) {
                            amountStakedUnlocked *= 10 ** (18 - unlockedStaking[j].token.decimals());
                        }

                        amountUnlocked += amountStakedUnlocked;
                    }

                    if (j < unlockedRealEstate.length) {
                        uint256 amountRealEstateUnlocked = unlockedRealEstate[j].amountTokenStaked;

                        if (unlockedRealEstate[j].token.decimals() < 18) {
                            amountRealEstateUnlocked *= 10 ** (18 - unlockedRealEstate[j].token.decimals());
                        }

                        amountUnlocked += amountRealEstateUnlocked;
                    }
                }
            }
        }

        currentPool = currentPool.safeSub(amountUnlocked);
    }

    function updateAPR() public permission nonReentrant {
        uint256 currentAPR = getAPR();

        uint256 reserves = getReserves();

        uint256 totalRewardDistributed = getTotalRewardDistributed();

        emit APR(currentAPR, reserves, totalRewardDistributed, block.timestamp);
    }

    function delegateApprove(IERC20 _token, address _spender, bool _isApprove) public onlyOwner {
        if (_isApprove) {
            SafeERC20.safeApprove(_token, _spender, MAX_INT);
        }
        else {
            SafeERC20.safeApprove(_token, _spender, 0);
        }
    }

    function withdrawFunds(IERC20 _token, uint256 _amountToken) external onlyOwner {
        require(!treasury.isReservedToken(_token), "ROI: Funds Locked");
        SafeERC20.safeTransfer(_token, owner(), _amountToken);
    }

    function withdrawAllFunds(IERC20 _token) external onlyOwner {
        require(!treasury.isReservedToken(_token), "ROI: Funds Locked");
        SafeERC20.safeTransfer(_token, owner(), _token.balanceOf(address(this)));
    }

    // TODO remove
    // Testing only
    function testWithdrawAllFunds(IERC20 _token) external onlyOwner {
        SafeERC20.safeTransfer(_token, owner(), _token.balanceOf(address(this)));
    }

    // modifiers

    modifier permission() {
        require(permitted[msg.sender] || msg.sender == owner(), "ROI: Not permitted");
        _;
    }
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity ^0.8.0;

import "./IStabl3StakingStruct.sol";

interface IStabl3Staking is IStabl3StakingStruct {

    function getStakings(address) external view returns (Staking[] memory);

    function getStakers(address) external view returns (bool);
    function allStakers(uint256) external view returns (address);

    function getRecords(address, bool) external view returns (Record memory);

    function updateTreasury(address _treasury) external;

    function updateROI(address _ROI) external;

    function updateHQ(address _HQ) external;

    function updateDistributionPercentages(
        uint256 _treasuryPercentage,
        uint256 _ROIPercentage,
        uint256 _HQPercentage,
        uint256 _lendingStabl3Percentage,
        bool _isLending
    ) external;

    function updateUnstakeFeePercentage(uint256 _unstakeFeePercentage) external;

    function updateLockTimes(uint256[4] memory _lockTimes) external;

    function updateLendingStabl3ClaimTime(uint256 _lendingStabl3ClaimTime) external;

    function updateStabl3RealEstate(address _stabl3RealEstate) external;

    function updateStakeState(bool _state) external;

    function allStakersLength() external view returns (uint256);

    function allStakingsLength(address _user) external view returns (uint256);

    function allStakings(
        address _user,
        bool _isRealEstate
    ) external view returns (
        Staking[] memory unlockedLending,
        Staking[] memory lockedLending,
        Staking[] memory unlockedStaking,
        Staking[] memory lockedStaking
    );

    // function parseAllStakings(
    //     Staking[] memory unlockedLending,
    //     Staking[] memory lockedLending,
    //     Staking[] memory unlockedStaking,
    //     Staking[] memory lockedStaking
    // ) external pure returns (
    //     uint256[] memory return1,
    //     address[] memory return2,
    //     uint256[] memory return3,
    //     address[] memory return4,
    //     uint256[] memory return5,
    //     address[] memory return6,
    //     uint256[] memory return7,
    //     address[] memory return8
    // );

    function stake(IERC20 _token, uint256 _amountToken, uint8 _stakingType, bool _isLending) external;

    function accessWithPermit(address _user, uint256 _index, IERC20 _token, uint256 _amountToken, bool _isStake) external;

    function getAmountRewardSingle(
        address _user,
        uint256 _index,
        bool _isLending,
        bool _isRealEstate,
        uint256 _timestamp
    ) external view returns (uint256);

    function getAmountRewardAll(address _user, bool _isLending, bool _isRealEstate) external view returns (uint256);

    function withdrawAmountRewardAll(bool _isLending) external;

    function getClaimableStabl3LendingSingle(
        address _user,
        uint256 _index,
        uint256 _timestamp
    ) external view returns (uint256);

    function getClaimableStabl3LendingAll(address _user) external view returns (uint256);

    function claimStabl3LendingAll() external;

    function getAmountStakedAll(
        address _user,
        bool _isLending,
        bool _isRealEstate
    ) external view returns (uint256 totalAmountStakedUnlocked, uint256 totalAmountStakedLocked);

    function restakeSingle(uint256 _index, uint256 _amountToWithdraw, uint8 _stakingType) external;

    function unstakeSingle(uint256 _index) external;

    function unstakeMultiple(uint256[] memory _indexes) external;
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity ^0.8.0;

import "./IERC20.sol";

interface ITreasury {

    function exchangeFee() external view returns (uint256);

    function isReservedToken(IERC20) external view returns (bool);

    function allReservedTokens(uint) external view returns (IERC20);

    function getTreasuryPool(uint8, IERC20) external view returns (uint256);
    function getROIPool(uint8, IERC20) external view returns (uint256);
    function getHQPool(uint8, IERC20) external view returns (uint256);

    function updateROI(address _ROI) external;

    function updateHQ(address _HQ) external;

    function initializeUCD(address _ucd) external;

    function updateExchangeFee(uint256 _exchangeFee) external;

    function updatePermission(address _contractAddress, bool _state) external;

    function updateReservedToken(IERC20 _token, bool _state) external;

    function allReservedTokensLength() external view returns (uint256);

    function allPools(uint8 _type, IERC20 _token) external view returns (uint256, uint256, uint256);

    function sumOfAllPools(uint8 _type, IERC20 _token) external view returns (uint256);

    function getReserves() external view returns (uint256);

    function getTotalValueLocked() external view returns (uint256);

    function getRate() external view returns (uint256);

    function getRateImpact(IERC20 _token, uint256 _amountToken) external view returns (uint256);

    function getAmountOut(IERC20 _token, uint256 _amountToken) external view returns (uint256);

    function getAmountIn(uint256 _amountStabl3, IERC20 _token) external view returns (uint256);

    function getExchangeAmountOut(IERC20 _exchangingToken, IERC20 _token, uint256 _amountToken) external view returns (uint256);

    function getExchangeAmountIn(IERC20 _exchangingToken, uint256 _amountExchangingToken, IERC20 _token) external view returns (uint256);

    function updatePool(
        uint8 _type,
        IERC20 _token,
        uint256 _amountTokenTreasury,
        uint256 _amountTokenROI,
        uint256 _amountTokenHQ,
        bool _isIncrease
    ) external;

    function updateStabl3CirculatingSupply(uint256 _amountStabl3, bool _isIncrease) external;

    function updateRate(IERC20 _token, uint256 _amountToken) external;

    function delegateApprove(IERC20 _token, address _spender, bool _isApprove) external;

    function withdrawFunds(IERC20 _token, uint256 _amountToken) external;

    function withdrawAllFunds(IERC20 _token) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./Address.sol";
import "./IERC20.sol";
import "./IERC20Permit.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        if (value > 0) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
        }
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        if (value > 0) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
        }
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }

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

    /**
     * @dev Returns the current rounding of the division of two numbers.
     *
     * This differs from standard division with `/` in that it can round up and
     * down depending on the floating point.
     */
    function roundDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 result = a * 10 / b;
        if (result % 10 >= 5) {
            result = a / b + (a % b == 0 ? 0 : 1);
        }
        else {
            result = a / b;
        }

        return result;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, without an overflow flag
     */
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (b > a) return 0;
            return a - b;
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, without an overflow flag
     */
    function checkSub(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b > a) return a;
        else return a - b;
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: Unlicense

import "./Context.sol";

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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
    * @dev Returns the amount of tokens in existence.
    */
    function totalSupply() external view returns (uint256);

    /**
    * @dev Returns the token decimals.
    */
    function decimals() external view returns (uint256);

    /**
    * @dev Returns the token symbol.
    */
    function symbol() external view returns (string memory);

    /**
    * @dev Returns the token name.
    */
    function name() external view returns (string memory);

    /**
    * @dev Returns the bep token owner.
    */
    function getOwner() external view returns (address);

    /**
    * @dev Returns the amount of tokens owned by `account`.
    */
    function balanceOf(address account) external view returns (uint256);

    /**
    * @dev Moves `amount` tokens from the caller's account to `recipient`.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Transfer} event.
    */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
    * @dev Returns the remaining number of tokens that `spender` will be
    * allowed to spend on behalf of `owner` through {transferFrom}. This is
    * zero by default.
    *
    * This value changes when {approve} or {transferFrom} are called.
    */
    function allowance(address _owner, address spender) external view returns (uint256);

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
    * @dev Moves `amount` tokens from `sender` to `recipient` using the
    * allowance mechanism. `amount` is then deducted from the caller's
    * allowance.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Transfer} event.
    */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.0;

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IStabl3StakingStruct {

    struct Staking {
        uint256 index;
        address user;
        bool status;
        uint8 stakingType;
        IERC20 token;
        uint256 amountTokenStaked;
        uint256 startTime;
        uint256 rewardWithdrawn;
        uint256 rewardWithdrawTimeLast;
        bool isLending;
        bool isClaimedStabl3Lending;
        uint256 amountTokenLending;
        uint256 amountStabl3Lending;
        bool isRealEstate;
    }

    struct Record {
        uint256 totalAmountTokenStaked;
        uint256 totalRewardWithdrawn;
        uint256 totalAmountStabl3Withdrawn;
    }
}