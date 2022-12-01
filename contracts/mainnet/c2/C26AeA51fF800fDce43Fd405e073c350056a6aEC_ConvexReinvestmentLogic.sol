// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../../interfaces/convex/IConvexBooster.sol";
import "../../interfaces/convex/IConvexRewards.sol";
import "../../interfaces/IReinvestment.sol";
import "../../interfaces/convex/ICvx.sol";
import "../../libraries/math/MathUtils.sol";

contract ConvexReinvestmentLogic is Initializable, Ownable, IERC165, IReinvestmentLogic {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using MathUtils for uint256;

    struct UserReward {
        uint256 claimable;
        uint256 integral;
    }

    struct RewardConfig {
        uint256 pid;
        address asset;
        uint256 integral;
        uint256 remaining;
    }

    uint256 public constant VERSION = 1;

    bytes32 internal constant ASSET = 0x0bd4060688a1800ae986e4840aebc924bb40b5bf44de4583df2257220b54b77c; // keccak256(abi.encodePacked("asset"))
    bytes32 internal constant TREASURY = 0xcbd818ad4dd6f1ff9338c2bb62480241424dd9a65f9f3284101a01cd099ad8ac; // keccak256(abi.encodePacked("treasury"))
    bytes32 internal constant LEDGER = 0x2c0e8db8fb1343f00f1c6b57af1cf6bf785c6b487e5c99ae90a4e98907f27011; // keccak256(abi.encodePacked("ledger"))
    bytes32 internal constant FEE_MANTISSA = 0xb438cbc7dd7438566e91798623a0acb324f70180fcab8f4a7f87eec183969271; // keccak256(abi.encodePacked("feeMantissa"))
    bytes32 internal constant RECEIPT = 0x8ad7c532f0538a191f1e436b6ca6710d0a78a349291c8b8f31962a26fb22e7e8; // keccak256(abi.encodePacked("receipt"))
    bytes32 internal constant PLATFORM = 0x3cb058642d3f17bc460bdd6eab42c21564f6b5228beab6a905a2eb32727c49d1; // keccak256(abi.encodePacked("platform"))
    bytes32 internal constant REWARD_POOL = 0xc94c1dc95992436dc73507a124248f855bbb3eb7ba05c35a8968ee0032e7c010; // keccak256(abi.encodePacked("rewardPool"))
    bytes32 internal constant POOL_ID = 0x65c5f051c5b76a70f06341c7e1c7bd57f76bdd400b273318041f003789e75a58; // keccak256(abi.encodePacked("poolId"))
    bytes32 internal constant REWARD_LENGTH = 0x2a8d0d63b9cbf2fc91763d8e08f9093cd174394353698a9d10c9ac16f1471ba9; // keccak256(abi.encodePacked("rewardLength"))
    bytes32 internal constant EMPTY_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470; // keccak256(abi.encodePacked(""))

    ICvx public constant cvx = ICvx(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    address public constant CRV = address(0xD533a949740bb3306d119CC777fa900bA034cd52);

    // ====================== STORAGE ======================

    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;

    // ====================== STORAGE ======================

    /**
     * @notice Initialize
     * @param asset_ The asset address
     * @param receipt_ The receipt to receive after investing
     * @param platform_ The investing platform
     * @param rewards_ The side reward to be claim
     * @param treasury_ The protocol treasury
     * @param ledger_ The ledger
     * @param feeMantissa_ Fees applied after divesting
     * @param data Additional data for reinvestment
     **/
    function initialize(
        address asset_,
        address receipt_,
        address platform_,
        address[] memory rewards_,
        address treasury_,
        address ledger_,
        uint256 feeMantissa_,
        bytes memory data
    ) external initializer onlyOwner {
        addressStorage[ASSET] = asset_;
        addressStorage[TREASURY] = treasury_;
        addressStorage[LEDGER] = ledger_;
        uintStorage[FEE_MANTISSA] = feeMantissa_;
        addressStorage[RECEIPT] = receipt_;
        addressStorage[PLATFORM] = platform_;

        (uint256 poolId_, address rewardPool_) = abi.decode(data, (uint256, address));
        uintStorage[POOL_ID] = poolId_;
        addressStorage[REWARD_POOL] = rewardPool_;

        uintStorage[REWARD_LENGTH] = rewards_.length;

        for (uint256 i = 0; i < rewards_.length; i++) {
            setRewards(i, RewardConfig(i, rewards_[i], 0, 0));
        }
    }

    function setTreasury(address treasury_) external override onlyOwner {
        emit UpdatedTreasury(treasury(), treasury_);
        addressStorage[TREASURY] = treasury_;
    }

    function setFeeMantissa(uint256 feeMantissa_) external override onlyOwner {
        require(feeMantissa_ < 1e18, "invalid feeMantissa");
        emit UpdatedFeeMantissa(feeMantissa(), feeMantissa_);
        uintStorage[FEE_MANTISSA] = feeMantissa_;
    }

    /**
     * @notice invest
     * @param amount amount
     **/
    function invest(
        uint256 amount
    ) external override onlyLedger {
        IERC20Upgradeable(asset()).safeTransferFrom(msg.sender, address(this), amount);

        require(IERC20Upgradeable(asset()).balanceOf(address(this)) >= amount, "not enough underlying");

        IERC20Upgradeable(asset()).safeApprove(platform(), 0);
        IERC20Upgradeable(asset()).safeApprove(platform(), amount);
        IConvexBooster(platform()).deposit(poolId(), amount, true);
    }

    /**
     * @notice divest
     * @param amount amount
     **/
    function divest(
        uint256 amount
    ) external override onlyLedger {
        IConvexRewards(rewardPool()).withdraw(amount, true);

        bool successWithdraw = IConvexBooster(platform()).withdraw(poolId(), amount);

        require(successWithdraw, "issue withdrawing from convex");

        require(
            IERC20Upgradeable(asset()).balanceOf(address(this)) >= amount,
            "contract does not hold amount"
        );

        IERC20Upgradeable(asset()).safeTransfer(msg.sender, amount);
    }

    /**
     * @notice checkpoint
     * @param user user
     * @param currBalance currBalance
     **/
    function checkpoint(address user, uint256 currBalance) external override onlyLedger {
        _checkpoint(user, currBalance);
    }

    /**
     * @notice claim
     * @param user user
     * @param currBalance currBalance
     **/
    function claim(address user, uint256 currBalance) external override onlyLedger {
        _checkpointAndClaim(user, currBalance);
    }

    function _checkpoint(address user, uint256 currBalance) internal {
        IConvexRewards(rewardPool()).getReward(address(this), true);

        for (uint256 i = 0; i < rewardLength(); i++) {
            (
            RewardConfig memory reward,
            UserReward memory userReward
            ) = _calculateRewards(user, currBalance, rewards(i), rewardOfInternal(user, i), false);

            setRewards(i, reward);
            setRewardOf(user, i, userReward);
        }
    }

    function _checkpointAndClaim(address user, uint256 currBalance) internal {
        IConvexRewards(rewardPool()).getReward(address(this), true);

        for (uint256 i = 0; i < rewardLength(); i++) {
            (
            RewardConfig memory reward,
            UserReward memory userReward
            ) = _calculateRewards(user, currBalance, rewards(i), rewardOfInternal(user, i), true);

            setRewards(i, reward);
            setRewardOf(user, i, userReward);
        }
    }

    /**
     * @notice Calculate Rewards
     * @param user Address
     * @param currBalance currBalance
     * @param reward memory data
     * @param userReward memory data
     * @param isClaim isClaim
     * @return reward reward
    */
    function _calculateRewards(
        address user,
        uint256 currBalance,
        RewardConfig memory reward,
        UserReward memory userReward,
        bool isClaim
    ) internal returns (RewardConfig memory, UserReward memory) {
        uint256 accruedBalance = IERC20Upgradeable(reward.asset).balanceOf(address(this));

        if (totalSupply() > 0 && accruedBalance > reward.remaining) {
            reward.integral += (accruedBalance - reward.remaining) * 1e20 / totalSupply();
        }

        if (isClaim || reward.integral > userReward.integral) {
            uint256 receivable = (reward.integral - userReward.integral) * currBalance / 1e20;

            if (isClaim) {
                receivable += userReward.claimable;

                uint256 fee = receivable * feeMantissa() / 1e18;
                IERC20Upgradeable(reward.asset).safeTransfer(treasury(), fee);

                IERC20Upgradeable(reward.asset).safeTransfer(user, receivable - fee);
                userReward.claimable = 0;

                // receivable still has fee and reduced from accruedBalance
                accruedBalance -= receivable;
            } else {
                userReward.claimable += receivable;
            }
            userReward.integral = reward.integral;
        }

        if (accruedBalance != reward.remaining) {
            reward.remaining = accruedBalance;
        }

        return (reward, userReward);
    }

    function _calculateGlobalRewards(RewardConfig memory reward) internal view returns (RewardConfig memory) {
        uint256 accruedBalance = IERC20Upgradeable(reward.asset).balanceOf(address(this));

        if (totalSupply() > 0 && accruedBalance > reward.remaining) {
            reward.integral += (accruedBalance - reward.remaining) * 1e20 / totalSupply();
        }

        if (accruedBalance != reward.remaining) {
            reward.remaining = accruedBalance;
        }

        return reward;
    }

    function _convertCrvToCvx(uint256 _amount) internal view returns (uint256){
        uint256 supply = cvx.totalSupply();
        uint256 reductionPerCliff = cvx.reductionPerCliff();
        uint256 totalCliffs = cvx.totalCliffs();
        uint256 maxSupply = cvx.maxSupply();

        uint256 cliff = supply / reductionPerCliff;
        //mint if below total cliffs
        if (cliff < totalCliffs) {
            //for reduction% take inverse of current cliff
            uint256 reduction = totalCliffs - cliff;
            //reduce
            _amount = _amount * reduction / totalCliffs;

            //supply cap check
            uint256 amtTillMax = maxSupply - supply;
            if (_amount > amtTillMax) {
                _amount = amtTillMax;
            }

            //mint
            return _amount;
        }
        return 0;
    }

    /**
     * @return The underlying total supply
     */
    function totalSupply() public view override returns (uint256) {
        return IConvexRewards(rewardPool()).balanceOf(address(this));
    }

    /**
     * @notice rewardOf
     * @param user user
     * @param currBalance Current deposited balance
     * @return Reward[]
     **/
    function rewardOf(address user, uint256 currBalance) public view override returns (Reward[] memory) {
        uint256 supply = totalSupply();
        Reward[] memory _rewards = new Reward[](rewardLength());
        for (uint256 i = 0; i < rewardLength(); i++) {
            RewardConfig memory rewardConfig = rewards(i);
            UserReward memory reward = rewardOfInternal(user, i);

            uint256 totalRewards = IERC20Upgradeable(rewardConfig.asset).balanceOf(address(this));
            uint256 newRewards = totalRewards - rewardConfig.remaining;

            newRewards = newRewards + IConvexRewards(rewardPool()).earned(address(this));

            uint256 globalIntegral = rewardConfig.integral;
            if (supply > 0) globalIntegral = globalIntegral + ((newRewards * 1e20) / supply);
            uint256 newlyClaimable = (currBalance * (globalIntegral - reward.integral)) / 1e20;
            reward.claimable = reward.claimable + newlyClaimable;

            if (rewardConfig.asset == CRV) {
                reward.claimable = reward.claimable + _convertCrvToCvx(newlyClaimable);
            }

            _rewards[i] = Reward(rewardConfig.asset, reward.claimable);
        }
        return _rewards;
    }


    function rewardOfInternal(address user, uint256 index) internal view returns (UserReward memory userReward) {
        bytes memory encodedData = bytesStorage[keccak256(abi.encodePacked("rewardOf", user, index))];

        if (keccak256(encodedData) == EMPTY_HASH) {
            UserReward memory emptyUserReward;
            userReward = emptyUserReward;
        } else {
            (userReward) = abi.decode(encodedData, (UserReward));
        }
    }

    /**
     * @notice setRewardOf
     * @param user user
     * @param index index
     * @param userReward
     **/
    function setRewardOf(
        address user,
        uint256 index,
        UserReward memory userReward
    ) internal {
        bytesStorage[keccak256(abi.encodePacked("rewardOf", user, index))] = abi.encode(userReward);
    }

    /**
     * @notice rewards
     * @param index The index map of reward configuration
     * @return reward rewardConfig
     **/
    function rewards(uint256 index) public view returns (RewardConfig memory reward) {
        bytes memory encodedData = bytesStorage[keccak256(abi.encodePacked("rewards", index))];

        if (keccak256(encodedData) == EMPTY_HASH) {
            RewardConfig memory emptyReward;
            reward = emptyReward;
        } else {
            (reward) = abi.decode(encodedData, (RewardConfig));
        }
    }

    /**
     * @notice setRewards
     * @param index index
     * @param reward reward
     **/
    function setRewards(uint256 index, RewardConfig memory reward) internal {
        bytesStorage[keccak256(abi.encodePacked("rewards", index))] = abi.encode(reward);
    }

    /**
     * @notice rewardLength rewardLength
     * @return length of configured rewards array
     **/
    function rewardLength() public view override returns (uint256) {
        return uintStorage[REWARD_LENGTH];
    }

    /**
     * @notice setRewardLength
     * @param length length
     **/
    function setRewardLength(uint256 length) internal {
        uintStorage[REWARD_LENGTH] = length;
    }

    function asset() public view override returns (address) {
        return addressStorage[ASSET];
    }

    function treasury() public view override returns (address) {
        return addressStorage[TREASURY];
    }

    function ledger() public view override returns (address) {
        return addressStorage[LEDGER];
    }

    function feeMantissa() public view override returns (uint256) {
        return uintStorage[FEE_MANTISSA];
    }


    /**
     * @notice platform
     * @return address of platform (convex)
     **/
    function platform() public view override returns (address) {
        return addressStorage[PLATFORM];
    }

    /**
     * @notice poolId
     * @return configured pool ID
     **/
    function poolId() public view returns (uint256) {
        return uintStorage[POOL_ID];
    }

    /**
     * @notice rewardPool
     * @return address of rewardPool
     **/
    function rewardPool() public view returns (address) {
        return addressStorage[REWARD_POOL];
    }

    function receipt() public view override returns (address) {
        return addressStorage[RECEIPT];
    }

    /**
     * @notice supportsInterface
     * @param interfaceId interfaceId
     * @return whether it supports
     **/
    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(IReinvestmentLogic).interfaceId;
    }

    /**
     * @notice emergencyWithdraw
     * @return balance
     **/
    function emergencyWithdraw() external override onlyLedger returns (uint256) {
        // retrieve rewards [crv,cvx], transferred to this contract
        IConvexRewards(rewardPool()).getReward(address(this), true);

        // update rewards index
        for (uint256 i = 0; i < rewardLength(); i++) {
            (RewardConfig memory reward) = _calculateGlobalRewards(rewards(i));
            setRewards(i, reward);
        }

        uint256 receiptBalance = IConvexRewards(rewardPool()).balanceOf(address(this));
        IConvexRewards(rewardPool()).withdrawAndUnwrap(receiptBalance, true);

        uint256 balance = IERC20Upgradeable(asset()).balanceOf(address(this));
        IERC20Upgradeable(asset()).safeTransfer(msg.sender, balance);

        return balance;
    }

    /**
     * @notice sweep
     * @param otherAsset
     **/
    function sweep(address otherAsset) external override onlyTreasury {
        require(otherAsset != asset(), "cannot sweep registered asset");
        IERC20Upgradeable(otherAsset).safeTransfer(treasury(), IERC20Upgradeable(otherAsset).balanceOf(address(this)));
    }

    modifier onlyLedger() {
        require(ledger() == msg.sender, "only ledger");
        _;
    }

    modifier onlyTreasury() {
        require(treasury() == msg.sender, "only treasury");
        _;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
                version == 1 && !AddressUpgradeable.isContract(address(this)),
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IConvexBooster {
    struct PoolInfo {
        address lptoken;
        address token;
        address gauge;
        address crvRewards;
        address stash;
        bool shutdown;
    }

    //deposit into convex, receive a tokenized deposit.  parameter to stake immediately
    function deposit(uint256 _pid, uint256 _amount, bool _stake) external returns(bool);

    function depositAll(uint256 _pid, bool _stake) external returns(bool);
    //burn a tokenized deposit to receive curve lp tokens back
    function withdraw(uint256 _pid, uint256 _amount) external returns(bool);

    function withdrawAll(uint256 _pid) external returns(bool);

    function poolInfo(uint256 _pid) external view returns (PoolInfo memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

interface IConvexRewards {
    //get balance of an address
    function balanceOf(address _account) external view returns(uint256);
    //withdraw to a convex tokenized deposit
    function withdraw(uint256 _amount, bool _claim) external returns(bool);
    //withdraw directly to curve LP token
    function withdrawAndUnwrap(uint256 _amount, bool _claim) external returns(bool);
    //claim rewards
    function getReward() external returns(bool);
    //claim rewards with configurable address
    function getReward(address, bool) external returns(bool);
    //stake a convex tokenized deposit
    function stake(uint256 _amount) external returns(bool);
    //stake a convex tokenized deposit for another address(transfering ownership)
    function stakeFor(address _account,uint256 _amount) external returns(bool);

    function earned(address _account) external view returns(uint256);

    function extraRewards(uint256 _index) external returns(address);

    function extraRewardsLength() external returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IReinvestmentProxy {
    function owner() external view returns (address);

    function logic() external view returns (address);

    function setLogic() external view returns (address);

    function supportedInterfaceId() external view returns (bytes4);
}

interface IReinvestmentLogic {

    event UpdatedTreasury(address oldAddress, address newAddress);
    event UpdatedFeeMantissa(uint256 oldFee, uint256 newFee);

    struct Reward {
        address asset;
        uint256 claimable;
    }

    function setTreasury(address treasury_) external;

    function setFeeMantissa(uint256 feeMantissa_) external;

    function asset() external view returns (address);

    function treasury() external view returns (address);

    function ledger() external view returns (address);

    function feeMantissa() external view returns (uint256);

    function receipt() external view returns (address);

    function platform() external view returns (address);

    function rewardOf(address, uint256) external view returns (Reward[] memory);

    function rewardLength() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function claim(address, uint256) external;

    function checkpoint(address, uint256) external;

    function invest(uint256) external;

    function divest(uint256) external;

    function emergencyWithdraw() external returns (uint256);

    function sweep(address) external;
}

interface IReinvestment is IReinvestmentProxy, IReinvestmentLogic {}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ICvx {
    function reductionPerCliff() external view returns(uint256);
    function totalSupply() external view returns(uint256);
    function totalCliffs() external view returns(uint256);
    function maxSupply() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 **/
library MathUtils {
    uint256 public constant VERSION = 1;

    uint256 internal constant WAD_UNIT = 18;
    uint256 internal constant RAY_UNIT = 27;
    uint256 internal constant WAD_RAY_RATIO = 1e9;

    uint256 public constant WAD = 1e18;
    uint256 public constant RAY = 1e27;
    uint256 public constant HALF_WAD = WAD / 2;
    uint256 public constant HALF_RAY = RAY / 2;


    /**
     * @notice Multiplies two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a*b, in wad
     **/
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        require(a <= (type(uint256).max - HALF_WAD) / b, "MathUtils: overflow");

        return (a * b + HALF_WAD) / WAD;
    }

    /**
     * @notice Divides two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a/b, in wad
     **/
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "MathUtils: division by zero");
        uint256 halfB = b / 2;

        require(a <= (type(uint256).max - halfB) / WAD, "MathUtils: overflow");

        return (a * WAD + halfB) / b;
    }

    /**
     * @notice Multiplies two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a*b, in ray
     **/
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        require(a <= (type(uint256).max - HALF_RAY) / b, "MathUtils: overflow");

        return (a * b + HALF_RAY) / RAY;
    }

    /**
     * @notice Divides two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a/b, in ray
     **/
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "MathUtils: division by zero");
        uint256 halfB = b / 2;

        require(a <= (type(uint256).max - halfB) / RAY, "MathUtils: overflow");

        return (a * RAY + halfB) / b;
    }

    /**
     * @notice Casts ray down to wad
     * @param a Ray
     * @return a casted to wad, rounded half up to the nearest wad
     **/
    function rayToWad(uint256 a) internal pure returns (uint256) {
        uint256 halfRatio = WAD_RAY_RATIO / 2;
        uint256 result = halfRatio + a;
        require(result >= halfRatio, "MathUtils: overflow");

        return result / WAD_RAY_RATIO;
    }

    /**
     * @notice Converts wad up to ray
     * @param a Wad
     * @return a converted in ray
     **/
    function wadToRay(uint256 a) internal pure returns (uint256) {
        uint256 result = a * WAD_RAY_RATIO;
        require(result / WAD_RAY_RATIO == a, "MathUtils: overflow");
        return result;
    }

    /**
     * @notice Converts unit to wad
     * @param self Value
     * @param unit Value's unit
     * @return value converted in wad
     **/
    function unitToWad(uint256 self, uint256 unit) internal pure returns (uint256) {
        if (self == 0 || unit == WAD_UNIT) return self;

        if (unit < WAD_UNIT) {
            return self * 10**(WAD_UNIT - unit);
        } else {
            return self / 10**(unit - WAD_UNIT);
        }
    }

    /**
     * @notice Converts unit to ray
     * @param self Value
     * @param unit Value's unit
     * @return value converted in ray
     **/
    function unitToRay(uint256 self, uint256 unit) internal pure returns (uint256) {
        if (self == 0 || unit == RAY_UNIT) return self;

        if (unit < RAY_UNIT) {
            return self * 10**(RAY_UNIT -unit);
        } else {
            return self / 10**(unit - RAY_UNIT);
        }
    }

    /**
     * @notice Converts unit to ray
     * @param self Value
     * @param unit Value's unit
     * @return value converted in ray
     **/
    function unitToRay(int256 self, uint256 unit) internal pure returns (int256) {
        if (self == 0 || unit == RAY_UNIT) return self;

        if (unit < RAY_UNIT) {
            return self * int256(10**(RAY_UNIT -unit));
        } else {
            return self / int256(10**(unit - RAY_UNIT));
        }
    }

    /**
     * @notice Converts wad to unit
     * @param self Value
     * @param unit Value's unit
     * @return value converted in unit
     **/
    function wadToUnit(uint256 self, uint256 unit) internal pure returns (uint256) {
        if (self == 0 || unit == WAD) return self;

        if (unit < WAD_UNIT) {
            return self / 10**(WAD_UNIT - unit);
        } else {
            return self * 10**(unit - WAD_UNIT);
        }
    }

    /**
     * @notice Converts ray to unit
     * @param self Value
     * @param unit Value's unit
     * @return value converted in unit
     **/
    function rayToUnit(uint256 self, uint256 unit) internal pure returns (uint256) {
        if (self == 0 || unit == RAY_UNIT) return self;

        if (unit < RAY_UNIT) {
            return self / 10**(RAY_UNIT - unit);
        } else {
            return self * 10**(unit - RAY_UNIT);
        }
    }

    /**
     * @notice Converts ray to unit
     * @param self Value
     * @param unit Value's unit
     * @return value converted in unit
     **/
    function rayToUnit(int256 self, uint256 unit) internal pure returns (int256) {
        if (self == 0 || unit == RAY_UNIT) return self;

        if (unit < RAY_UNIT) {
            return self / int256(10**(RAY_UNIT - unit));
        } else {
            return self * int256(10**(unit - RAY_UNIT));
        }
    }

    function abs(int256 a) internal pure returns (uint256) {
        if (a < 0) {
            return uint256(a * (-1));
        } else {
            return uint256(a);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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