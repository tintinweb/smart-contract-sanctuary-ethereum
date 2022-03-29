// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "../interfaces/ILendingMarket.sol";
import "../interfaces/ISupplyBooster.sol";
import "../interfaces/IConvexRewardPool.sol";
import "../interfaces/ILendFlareVault.sol";
import "../interfaces/ILendFlareCRV.sol";
import "../interfaces/IConvexBooster.sol";
import "../interfaces/IConvexBasicRewards.sol";
import "../interfaces/IConvexCRVDepositor.sol";
import "../interfaces/ICurveFactoryPool.sol";
import "../interfaces/IZap.sol";

// solhint-disable no-empty-blocks, reason-string
contract LendFlareVault is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    ILendFlareVault
{
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address payable;

    struct PoolInfo {
        uint256 lendingMarketPid;
        uint128 totalUnderlying;
        uint128 totalShare;
        uint256 accRewardPerShare;
        uint256 convexPoolId;
        address lpToken;
        bool pauseDeposit;
        bool pauseWithdraw;
    }

    struct UserInfo {
        uint128 shares;
        uint128 rewards;
        uint256 rewardPerSharePaid;
        uint256 lendingIndex;
        uint256 lendingLocked;
    }

    struct Lending {
        uint256 pid;
        uint256 lendingIndex;
        address user;
        uint256 lendingMarketPid;
        uint256 token0;
    }

    uint256 private constant PRECISION = 1e18;

    address private constant ZERO_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant CVXCRV =
        0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7;
    address private constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant BOOSTER =
        0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address private constant CURVE_CVXCRV_CRV_POOL =
        0x9D0464996170c6B9e75eED71c68B99dDEDf279e8;
    address private constant CRV_DEPOSITOR =
        0x8014595F2AB54cD7c604B00E9fb932176fDc86Ae;

    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(uint256 => mapping(address => mapping(uint256 => bytes32)))
        public userLendings; // pid => (user => (lendingIndex => UserLending))
    mapping(bytes32 => Lending) public lendings;
    mapping(uint256 => mapping(address => uint256)) public lendingLocked; // pid => (user => locked amount)

    address public lendingMarket;
    address public lendFlareCRV;
    address public zap;

    function initialize(
        address _lendingMarket,
        address _lendFlareCRV,
        address _zap
    ) external initializer {
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

        require(
            _lendFlareCRV != address(0),
            "LendFlareVault: zero acrv address"
        );
        require(_zap != address(0), "LendFlareVault: zero zap address");

        lendingMarket = _lendingMarket;
        lendFlareCRV = _lendFlareCRV;
        zap = _zap;
    }

    /********************************** View Functions **********************************/

    function poolLength() public view returns (uint256 pools) {
        pools = poolInfo.length;
    }

    function pendingReward(uint256 _pid, address _account)
        public
        view
        returns (uint256)
    {
        PoolInfo storage _pool = poolInfo[_pid];
        UserInfo storage _userInfo = userInfo[_pid][_account];
        return
            uint256(_userInfo.rewards).add(
                _pool
                    .accRewardPerShare
                    .sub(_userInfo.rewardPerSharePaid)
                    .mul(_userInfo.shares)
                    .div(PRECISION)
            );
    }

    function pendingRewardAll(address _account)
        external
        view
        returns (uint256)
    {
        uint256 _pending;

        for (uint256 i = 0; i < poolInfo.length; i++) {
            _pending = _pending.add(pendingReward(i, _account));
        }

        return _pending;
    }

    /********************************** Mutated Functions **********************************/
    function deposit(uint256 _pid, uint256 _amount)
        public
        nonReentrant
        returns (uint256 share)
    {
        require(_amount > 0, "LendFlareVault: zero amount deposit");
        require(_pid < poolInfo.length, "LendFlareVault: invalid pool");

        // 1. update rewards
        PoolInfo storage _pool = poolInfo[_pid];
        require(!_pool.pauseDeposit, "LendFlareVault: pool paused");

        _updateRewards(_pid, msg.sender);

        // 2. transfer user token
        address _lpToken = _pool.lpToken;
        {
            uint256 _before = IERC20Upgradeable(_lpToken).balanceOf(
                address(this)
            );
            IERC20Upgradeable(_lpToken).safeTransferFrom(
                msg.sender,
                address(this),
                _amount
            );
            _amount = IERC20Upgradeable(_lpToken).balanceOf(address(this)).sub(
                _before
            );
        }

        // 3. deposit
        _approve(_lpToken, lendingMarket, _amount);
        ILendingMarket(lendingMarket).deposit(_pool.lendingMarketPid, _amount);

        uint256 _totalShare = _pool.totalShare;
        uint256 _totalUnderlying = _pool.totalUnderlying;
        uint256 _shares;
        if (_totalShare == 0) {
            _shares = _amount;
        } else {
            _shares = _amount.mul(_totalShare).div(_totalUnderlying);
        }
        _pool.totalShare = _toU128(_totalShare.add(_shares));
        _pool.totalUnderlying = _toU128(_totalUnderlying.add(_amount));

        UserInfo storage _userInfo = userInfo[_pid][msg.sender];
        _userInfo.shares = _toU128(_shares.add(_userInfo.shares));

        // emit Deposit(_pid, msg.sender, _amount);
        return _shares;
    }

    function depositAll(uint256 _pid) external returns (uint256 share) {
        PoolInfo storage _pool = poolInfo[_pid];

        uint256 _balance = IERC20Upgradeable(_pool.lpToken).balanceOf(
            msg.sender
        );

        return deposit(_pid, _balance);
    }

    function borrowForDeposit(
        uint256 _pid,
        uint256 _token0,
        uint256 _borrowBlock,
        uint256 _supportPid
    ) public payable nonReentrant {
        require(msg.value == 0.1 ether, "!borrowForDeposit");

        PoolInfo storage _pool = poolInfo[_pid];

        ILendingMarket(lendingMarket).borrowForDeposit{value: msg.value}(
            _pool.lendingMarketPid,
            _token0,
            _borrowBlock,
            _supportPid
        );

        ILendingMarket.UserLending[]
            memory lendingMarketUserLendings = ILendingMarket(lendingMarket)
                .userLendings(address(this));

        UserInfo storage _userInfo = userInfo[_pid][msg.sender];
        _userInfo.lendingIndex++;

        bytes32 lendingId = lendingMarketUserLendings[
            lendingMarketUserLendings.length - 1
        ].lendingId;

        userLendings[_pid][msg.sender][_userInfo.lendingIndex] = lendingId;

        lendings[lendingId] = Lending({
            pid: _pid,
            user: msg.sender,
            lendingIndex: _userInfo.lendingIndex,
            lendingMarketPid: _pool.lendingMarketPid,
            token0: _token0
        });

        lendingLocked[_pid][msg.sender] = lendingLocked[_pid][msg.sender].add(
            _token0
        );

        address underlyToken = ISupplyBooster(
            ILendingMarket(lendingMarket).supplyBooster()
        ).getLendingUnderlyToken(lendingId);

        if (underlyToken != ZERO_ADDRESS) {
            IERC20Upgradeable(underlyToken).safeTransfer(
                msg.sender,
                IERC20Upgradeable(underlyToken).balanceOf(address(this))
            );
        } else {
            payable(msg.sender).sendValue(address(this).balance);
        }
    }

    function repayBorrow(bytes32 _lendingId) public payable nonReentrant {
        Lending storage lending = lendings[_lendingId];

        PoolInfo storage _pool = poolInfo[lending.pid];
        UserInfo storage _userInfo = userInfo[lending.pid][lending.user];

        uint256 _before = IERC20Upgradeable(_pool.lpToken).balanceOf(
            address(this)
        );

        ILendingMarket(lendingMarket).repayBorrow{value: msg.value}(_lendingId);

        _userInfo.lendingLocked = _userInfo.lendingLocked.sub(lending.token0);

        // pay back 0.1 ether
        payable(lending.user).transfer(0.1 ether);

        uint256 _amount = IERC20Upgradeable(_pool.lpToken)
            .balanceOf(address(this))
            .sub(_before);

        IERC20Upgradeable(_pool.lpToken).safeTransfer(lending.user, _amount);
    }

    function repayBorrowERC20(bytes32 _lendingId, uint256 _amount)
        public
        nonReentrant
    {
        Lending storage lending = lendings[_lendingId];

        PoolInfo storage _pool = poolInfo[lending.pid];
        UserInfo storage _userInfo = userInfo[lending.pid][lending.user];

        address underlyToken = ISupplyBooster(
            ILendingMarket(lendingMarket).supplyBooster()
        ).getLendingUnderlyToken(_lendingId);

        _approve(underlyToken, lendingMarket, _amount);

        uint256 _before = IERC20Upgradeable(_pool.lpToken).balanceOf(
            address(this)
        );

        IERC20Upgradeable(_pool.lpToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        ILendingMarket(lendingMarket).repayBorrowERC20(_lendingId, _amount);

        _userInfo.lendingLocked = _userInfo.lendingLocked.sub(lending.token0);

        // pay back 0.1 ether
        payable(lending.user).transfer(0.1 ether);

        _amount = IERC20Upgradeable(_pool.lpToken).balanceOf(address(this)).sub(
                _before
            );

        IERC20Upgradeable(_pool.lpToken).safeTransfer(lending.user, _amount);
    }

    function withdraw(
        uint256 _pid,
        uint256 _shares,
        uint256 _minOut,
        ClaimOption _option
    ) public nonReentrant returns (uint256, uint256) {
        require(_shares > 0, "LendFlareVault: zero share withdraw");
        require(_pid < poolInfo.length, "LendFlareVault: invalid pool");

        // 1. update rewards
        PoolInfo storage _pool = poolInfo[_pid];
        require(!_pool.pauseWithdraw, "LendFlareVault: pool paused");
        _updateRewards(_pid, msg.sender);

        // 2. withdraw lp token
        UserInfo storage _userInfo = userInfo[_pid][msg.sender];
        require(
            _shares <= _userInfo.shares,
            "LendFlareVault: shares not enough"
        );

        uint256 _totalShare = _pool.totalShare;
        uint256 _totalUnderlying = _pool.totalUnderlying;
        uint256 _withdrawable;

        if (_shares == _totalShare) {
            _withdrawable = _totalUnderlying;
        } else {
            _withdrawable = _shares.mul(_totalUnderlying).div(_totalShare);
        }

        require(_withdrawable <= _userInfo.lendingLocked, "!_withdrawable");

        _pool.totalShare = _toU128(_totalShare.sub(_shares));
        _pool.totalUnderlying = _toU128(_totalUnderlying.sub(_withdrawable));
        _userInfo.shares = _toU128(uint256(_userInfo.shares).sub(_shares));

        ILendingMarket(lendingMarket).withdraw(
            _pool.lendingMarketPid,
            _withdrawable
        );

        IERC20Upgradeable(_pool.lpToken).safeTransfer(
            msg.sender,
            _withdrawable
        );

        if (_option == ClaimOption.None) {
            return (_withdrawable, 0);
        } else {
            uint256 _rewards = _userInfo.rewards;
            _userInfo.rewards = 0;

            // emit Claim(msg.sender, _rewards, _option);
            _rewards = _claim(_rewards, _minOut, _option);

            return (_withdrawable, _rewards);
        }
    }

    function claim(
        uint256 _pid,
        uint256 _minOut,
        ClaimOption _option
    ) public nonReentrant returns (uint256 claimed) {
        require(_pid < poolInfo.length, "LendFlareVault: invalid pool");

        PoolInfo storage _pool = poolInfo[_pid];
        require(!_pool.pauseWithdraw, "LendFlareVault: pool paused");
        _updateRewards(_pid, msg.sender);

        UserInfo storage _userInfo = userInfo[_pid][msg.sender];
        uint256 _rewards = _userInfo.rewards;
        _userInfo.rewards = 0;

        // emit Claim(msg.sender, _rewards, _option);
        _rewards = _claim(_rewards, _minOut, _option);
        return _rewards;
    }

    function harvest(uint256 _pid, uint256 _minimumOut) public nonReentrant {
        require(_pid < poolInfo.length, "LendFlareVault: invalid pool");

        PoolInfo storage _pool = poolInfo[_pid];

        IConvexBooster(ILendingMarket(lendingMarket).convexBooster())
            .getRewards(_pool.convexPoolId);

        // swap all rewards token to CRV
        address rewardCrvPool = IConvexBooster(
            ILendingMarket(lendingMarket).convexBooster()
        ).poolInfo(_pool.convexPoolId).rewardCrvPool;

        uint256 _amount = address(this).balance;

        for (
            uint256 i = 0;
            i < IConvexRewardPool(rewardCrvPool).extraRewardsLength();
            i++
        ) {
            address extraRewardPool = IConvexRewardPool(rewardCrvPool)
                .extraRewards(i);

            address rewardToken = IConvexRewardPool(extraRewardPool)
                .rewardToken();

            if (rewardToken != CRV) {
                uint256 rewardTokenBal = IERC20Upgradeable(rewardToken)
                    .balanceOf(address(this));

                if (rewardTokenBal > 0) {
                    // saving gas
                    IERC20Upgradeable(rewardToken).safeTransfer(
                        zap,
                        rewardTokenBal
                    );
                    _amount = _amount.add(
                        IZap(zap).zap(rewardToken, rewardTokenBal, WETH, 0)
                    );
                }
            }
        }

        if (_amount > 0) {
            IZap(zap).zap{value: _amount}(WETH, _amount, CRV, 0);
        }

        _amount = IERC20Upgradeable(CRV).balanceOf(address(this));
        _amount = _swapCRVToCvxCRV(_amount, _minimumOut);

        _approve(CVXCRV, lendFlareCRV, _amount);

        uint256 _rewards = ILendFlareCRV(lendFlareCRV).deposit(
            address(this),
            _amount
        );

        _pool.accRewardPerShare = _pool.accRewardPerShare.add(
            _rewards.mul(PRECISION).div(_pool.totalShare)
        );
    }

    /********************************** Restricted Functions **********************************/
    function updateZap(address _zap) external onlyOwner {
        require(_zap != address(0), "LendFlareVault: zero zap address");
        zap = _zap;

        // emit UpdateZap(_zap);
    }

    function addPoolTest(uint256 _lendingMarketPid)
        external
        view
        returns (ILendingMarket.PoolInfo memory)
    {
        ILendingMarket.PoolInfo memory _lendingMarketPool = ILendingMarket(
            lendingMarket
        ).poolInfo(_lendingMarketPid);

        return _lendingMarketPool;
    }

    function addPool(uint256 _lendingMarketPid) external onlyOwner {
        ILendingMarket.PoolInfo memory _lendingMarketPool = ILendingMarket(
            lendingMarket
        ).poolInfo(_lendingMarketPid);

        for (uint256 i = 0; i < poolInfo.length; i++) {
            require(
                poolInfo[i].convexPoolId != _lendingMarketPool.convexPid,
                "LendFlareVault: duplicate pool"
            );
        }

        IConvexBooster.PoolInfo memory _convexBoosterPool = IConvexBooster(
            BOOSTER
        ).poolInfo(_lendingMarketPool.convexPid);

        poolInfo.push(
            PoolInfo({
                lendingMarketPid: _lendingMarketPid,
                totalUnderlying: 0,
                totalShare: 0,
                accRewardPerShare: 0,
                convexPoolId: _lendingMarketPool.convexPid,
                lpToken: _convexBoosterPool.lpToken,
                pauseDeposit: false,
                pauseWithdraw: false
            })
        );

        // emit AddPool(poolInfo.length - 1, _convexPid, _rewardTokens);
    }

    function pausePoolWithdraw(uint256 _pid, bool _status) external onlyOwner {
        require(_pid < poolInfo.length, "LendFlareVault: invalid pool");

        poolInfo[_pid].pauseWithdraw = _status;

        // emit PausePoolWithdraw(_pid, _status);
    }

    function pausePoolDeposit(uint256 _pid, bool _status) external onlyOwner {
        require(_pid < poolInfo.length, "LendFlareVault: invalid pool");

        poolInfo[_pid].pauseDeposit = _status;

        // emit PausePoolDeposit(_pid, _status);
    }

    /********************************** Internal Functions **********************************/

    function _updateRewards(uint256 _pid, address _account) internal {
        uint256 _rewards = pendingReward(_pid, _account);
        PoolInfo storage _pool = poolInfo[_pid];
        UserInfo storage _userInfo = userInfo[_pid][_account];

        _userInfo.rewards = _toU128(_rewards);
        _userInfo.rewardPerSharePaid = _pool.accRewardPerShare;
    }

    function _claim(
        uint256 _amount,
        uint256 _minOut,
        ClaimOption _option
    ) internal returns (uint256) {
        if (_amount == 0) return _amount;

        ILendFlareCRV.WithdrawOption _withdrawOption;

        if (_option == ClaimOption.Claim) {
            require(_amount >= _minOut, "LendFlareVault: insufficient output");
            IERC20Upgradeable(lendFlareCRV).safeTransfer(msg.sender, _amount);

            return _amount;
        } else if (_option == ClaimOption.ClaimAsCvxCRV) {
            _withdrawOption = ILendFlareCRV.WithdrawOption.Withdraw;
        } else if (_option == ClaimOption.ClaimAsCRV) {
            _withdrawOption = ILendFlareCRV.WithdrawOption.WithdrawAsCRV;
        } else if (_option == ClaimOption.ClaimAsCVX) {
            _withdrawOption = ILendFlareCRV.WithdrawOption.WithdrawAsCVX;
        } else if (_option == ClaimOption.ClaimAsETH) {
            _withdrawOption = ILendFlareCRV.WithdrawOption.WithdrawAsETH;
        } else {
            revert("LendFlareVault: invalid claim option");
        }

        return
            ILendFlareCRV(lendFlareCRV).withdraw(
                msg.sender,
                _amount,
                _minOut,
                _withdrawOption
            );
    }

    function _toU128(uint256 _value) internal pure returns (uint128) {
        require(
            _value < 340282366920938463463374607431768211456,
            "LendFlareVault: overflow"
        );
        return uint128(_value);
    }

    function _swapCRVToCvxCRV(uint256 _amountIn, uint256 _minOut)
        internal
        returns (uint256)
    {
        // CRV swap to CVXCRV or stake to CVXCRV
        // CRV swap to CVXCRV or stake to CVXCRV
        uint256 _amountOut = ICurveFactoryPool(CURVE_CVXCRV_CRV_POOL).get_dy(
            0,
            1,
            _amountIn
        );
        bool useCurve = _amountOut > _amountIn;
        require(
            _amountOut >= _minOut || _amountIn >= _minOut,
            "lendFlareCRVZap: insufficient output"
        );

        if (useCurve) {
            _approve(CRV, CURVE_CVXCRV_CRV_POOL, _amountIn);
            _amountOut = ICurveFactoryPool(CURVE_CVXCRV_CRV_POOL).exchange(
                0,
                1,
                _amountIn,
                0,
                address(this)
            );
        } else {
            _approve(CRV, CRV_DEPOSITOR, _amountIn);
            uint256 _lockIncentive = IConvexCRVDepositor(CRV_DEPOSITOR)
                .lockIncentive();
            // if use `lock = false`, will possible take fee
            // if use `lock = true`, some incentive will be given
            _amountOut = IERC20Upgradeable(CVXCRV).balanceOf(address(this));
            if (_lockIncentive == 0) {
                // no lock incentive, use `lock = false`
                IConvexCRVDepositor(CRV_DEPOSITOR).deposit(
                    _amountIn,
                    false,
                    address(0)
                );
            } else {
                // no lock incentive, use `lock = true`
                IConvexCRVDepositor(CRV_DEPOSITOR).deposit(
                    _amountIn,
                    true,
                    address(0)
                );
            }
            _amountOut = IERC20Upgradeable(CVXCRV).balanceOf(address(this)).sub(
                    _amountOut
                ); // never overflow here
        }
        return _amountOut;
    }

    function _approve(
        address _token,
        address _spender,
        uint256 _amount
    ) internal {
        IERC20Upgradeable(_token).safeApprove(_spender, 0);
        IERC20Upgradeable(_token).safeApprove(_spender, _amount);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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

pragma solidity ^0.7.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

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
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
import "../proxy/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

interface ILendingMarket {
    struct PoolInfo {
        uint256 convexPid;
        uint256[] supportPids;
        int128[] curveCoinIds;
        uint256 lendingThreshold;
        uint256 liquidateThreshold;
        uint256 borrowIndex;
    }

    struct UserLending {
        bytes32 lendingId;
        uint256 token0;
        uint256 token0Price;
        uint256 lendingAmount;
        uint256 borrowAmount;
        uint256 borrowInterest;
        uint256 supportPid;
        int128 curveCoinId;
        uint256 borrowNumbers;
    }

    function deposit(uint256 _pid, uint256 _token0) external;

    function supplyBooster() external returns (address);

    function convexBooster() external returns (address);

    function borrowForDeposit(
        uint256 _pid,
        uint256 _token0,
        uint256 _borrowBlock,
        uint256 _supportPid
    ) external payable;

    function borrow(
        uint256 _pid,
        uint256 _token0,
        uint256 _borrowBlock,
        uint256 _supportPid
    ) external payable;

    function userLendings(address) external view returns (UserLending[] memory);

    function repayBorrow(bytes32 _lendingId) external payable;

    function repayBorrowERC20(bytes32 _lendingId, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _token0) external;

    function poolInfo(uint256 _pid) external view returns (PoolInfo memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface ISupplyBooster {
  function getLendingUnderlyToken(bytes32 _lendingId) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IConvexRewardPool {
    function earned(address account) external view returns (uint256);
    function stake(address _for) external;
    function withdraw(address _for) external;
    function getReward(address _for) external;
    function notifyRewardAmount(uint256 reward) external;
    function rewardToken() external returns(address);

    function extraRewards(uint256 _idx) external view returns (address);
    function extraRewardsLength() external view returns (uint256);
    function addExtraReward(address _reward) external returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface ILendFlareVault {
  enum ClaimOption {
    None,
    Claim,
    ClaimAsCvxCRV,
    ClaimAsCRV,
    ClaimAsCVX,
    ClaimAsETH
  }

  // event Deposit(uint256 indexed _pid, address indexed _sender, uint256 _amount);
  // event Withdraw(uint256 indexed _pid, address indexed _sender, uint256 _shares);
  // event Claim(address indexed _sender, uint256 _reward, ClaimOption _option);

  // event UpdateWithdrawalFeePercentage(uint256 indexed _pid, uint256 _feePercentage);
  // event UpdatePlatformFeePercentage(uint256 indexed _pid, uint256 _feePercentage);
  // event UpdateHarvestBountyPercentage(uint256 indexed _pid, uint256 _percentage);
  // event UpdatePlatform(address indexed _platform);
  // event UpdateZap(address indexed _zap);
  // event UpdatePoolRewardTokens(uint256 indexed _pid, address[] _rewardTokens);
  // event AddPool(uint256 indexed _pid, uint256 _convexPid, address[] _rewardTokens);
  // event PausePoolDeposit(uint256 indexed _pid, bool _status);
  // event PausePoolWithdraw(uint256 indexed _pid, bool _status);

  // function pendingReward(uint256 _pid, address _account) external view returns (uint256);

  // function pendingRewardAll(address _account) external view returns (uint256);

  // function deposit(uint256 _pid, uint256 _amount) external returns (uint256);

  // function depositAll(uint256 _pid) external returns (uint256);

  // function withdrawAndClaim(
  //   uint256 _pid,
  //   uint256 _shares,
  //   uint256 _minOut,
  //   ClaimOption _option
  // ) external returns (uint256, uint256);

  // function withdrawAllAndClaim(
  //   uint256 _pid,
  //   uint256 _minOut,
  //   ClaimOption _option
  // ) external returns (uint256, uint256);

  // function claim(
  //   uint256 _pid,
  //   uint256 _minOut,
  //   ClaimOption _option
  // ) external returns (uint256);

  // function claimAll(uint256 _minOut, ClaimOption _option) external returns (uint256);

  // function harvest(
  //   uint256 _pid,
  //   address _recipient,
  //   uint256 _minimumOut
  // ) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ILendFlareCRV is IERC20Upgradeable {
  event Harvest(address indexed _caller, uint256 _amount);
  event Deposit(address indexed _sender, address indexed _recipient, uint256 _amount);
  event Withdraw(
    address indexed _sender,
    address indexed _recipient,
    uint256 _shares,
    ILendFlareCRV.WithdrawOption _option
  );

  event UpdateWithdrawalFeePercentage(uint256 _feePercentage);
  event UpdatePlatformFeePercentage(uint256 _feePercentage);
  event UpdateHarvestBountyPercentage(uint256 _percentage);
  event UpdatePlatform(address indexed _platform);
  event UpdateZap(address indexed _zap);

  enum WithdrawOption {
    Withdraw,
    WithdrawAndStake,
    WithdrawAsCRV,
    WithdrawAsCVX,
    WithdrawAsETH
  }

  /// @dev return the total amount of cvxCRV staked.
  function totalUnderlying() external view returns (uint256);

  /// @dev return the amount of cvxCRV staked for user
  function balanceOfUnderlying(address _user) external view returns (uint256);

  function deposit(address _recipient, uint256 _amount) external returns (uint256);

  function depositAll(address _recipient) external returns (uint256);

  function depositWithCRV(address _recipient, uint256 _amount) external returns (uint256);

  function depositAllWithCRV(address _recipient) external returns (uint256);

  function withdraw(
    address _recipient,
    uint256 _shares,
    uint256 _minimumOut,
    WithdrawOption _option
  ) external returns (uint256);

  function withdrawAll(
    address _recipient,
    uint256 _minimumOut,
    WithdrawOption _option
  ) external returns (uint256);

  function harvest(address _recipient, uint256 _minimumOut) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

interface IConvexBooster {
  struct PoolInfo {
    uint256 originConvexPid;
    address curveSwapAddress; /* like 3pool https://github.com/curvefi/curve-js/blob/master/src/constants/abis/abis-ethereum.ts */
    address lpToken;
    address originCrvRewards;
    address originStash;
    address virtualBalance;
    address rewardCrvPool;
    address rewardCvxPool;
    bool shutdown;
  }

  function poolInfo(uint256 _pid) external view returns (PoolInfo memory);

  function depositAll(uint256 _pid, bool _stake) external returns (bool);

  function deposit(
    uint256 _pid,
    uint256 _amount,
    bool _stake
  ) external returns (bool);

  function getRewards(uint256 _pid) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IConvexBasicRewards {
  function stakeFor(address, uint256) external returns (bool);

  function balanceOf(address) external view returns (uint256);

  function earned(address) external view returns (uint256);

  function withdrawAll(bool) external returns (bool);

  function withdraw(uint256, bool) external returns (bool);

  function withdrawAndUnwrap(uint256, bool) external returns (bool);

  function getReward() external returns (bool);

  function stake(uint256) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IConvexCRVDepositor {
  function deposit(
    uint256 _amount,
    bool _lock,
    address _stakeAddress
  ) external;

  function deposit(uint256 _amount, bool _lock) external;

  function lockIncentive() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

// solhint-disable var-name-mixedcase, func-name-mixedcase
interface ICurveFactoryPool {
  function get_dy(
    int128 i,
    int128 j,
    uint256 dx
  ) external view returns (uint256);

  function exchange(
    int128 i,
    int128 j,
    uint256 _dx,
    uint256 _min_dy,
    address _receiver
  ) external returns (uint256);

  function coins(uint256 index) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IZap {
  function zap(
    address _fromToken,
    uint256 _amountIn,
    address _toToken,
    uint256 _minOut
  ) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}