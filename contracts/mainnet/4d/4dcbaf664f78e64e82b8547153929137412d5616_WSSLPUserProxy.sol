// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2022 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol"; // have to use OZ safemath since it is used in WSSLP

import "../../interfaces/wrapped-assets/ITopDog.sol";
import "../../helpers/TransferHelper.sol";


/**
 * @title WSSLPUserProxy
 **/
contract WSSLPUserProxy {
    using SafeMath for uint256;

    address public immutable manager;

    ITopDog public immutable topDog;
    uint256 public immutable topDogPoolId;
    IERC20 public immutable boneToken;

    modifier onlyManager() {
        require(msg.sender == manager, "Unit Protocol Wrapped Assets: AUTH_FAILED");
        _;
    }

    constructor(ITopDog _topDog, uint256 _topDogPoolId) {
        manager = msg.sender;

        topDog = _topDog;
        topDogPoolId = _topDogPoolId;

        boneToken = _topDog.bone();
    }

    /**
     * @dev in case of change sslp
     */
    function approveSslpToTopDog(IERC20 _sslpToken) public onlyManager {
        TransferHelper.safeApprove(address(_sslpToken), address(topDog), type(uint256).max);
    }

    function deposit(uint256 _amount) public onlyManager {
        topDog.deposit(topDogPoolId, _amount);
    }

    function withdraw(IERC20 _sslpToken, uint256 _amount, address _sentTokensTo) public onlyManager {
        topDog.withdraw(topDogPoolId, _amount);
        TransferHelper.safeTransfer(address(_sslpToken), _sentTokensTo, _amount);
    }

    function pendingReward(address _feeReceiver, uint8 _feePercent) public view returns (uint) {
        uint balance = boneToken.balanceOf(address(this));
        uint pending = topDog.pendingBone(topDogPoolId, address(this)).mul(topDog.rewardMintPercent()).div(100);

        (uint amountWithoutFee, ) = _calcFee(balance.add(pending), _feeReceiver, _feePercent);
        return amountWithoutFee;
    }

    function claimReward(address _user, address _feeReceiver, uint8 _feePercent) public onlyManager {
        topDog.deposit(topDogPoolId, 0); // get current reward (no separate methods)

        _sendAllBonesToUser(_user, _feeReceiver, _feePercent);
    }

    function _calcFee(uint _amount, address _feeReceiver, uint8 _feePercent) internal pure returns (uint amountWithoutFee, uint fee) {
        if (_feePercent == 0 || _feeReceiver == address(0)) {
            return (_amount, 0);
        }

        fee = _amount.mul(_feePercent).div(100);
        return (_amount.sub(fee), fee);
    }

    function _sendAllBonesToUser(address _user, address _feeReceiver, uint8 _feePercent) internal {
        uint balance = boneToken.balanceOf(address(this));

        _sendBonesToUser(_user, balance, _feeReceiver, _feePercent);
    }

    function _sendBonesToUser(address _user, uint _amount, address _feeReceiver, uint8 _feePercent) internal {
        (uint amountWithoutFee, uint fee) = _calcFee(_amount, _feeReceiver, _feePercent);

        if (fee > 0) {
            TransferHelper.safeTransfer(address(boneToken), _feeReceiver, fee);
        }
        TransferHelper.safeTransfer(address(boneToken), _user, amountWithoutFee);
    }

    function getClaimableRewardFromBoneLocker(IBoneLocker _boneLocker, address _feeReceiver, uint8 _feePercent) public view returns (uint) {
        if (address(_boneLocker) == address(0)) {
            _boneLocker = topDog.boneLocker();
        }

        (uint amountWithoutFee, ) = _calcFee(_boneLocker.getClaimableAmount(address(this)), _feeReceiver, _feePercent);
        return amountWithoutFee;
    }

    function claimRewardFromBoneLocker(address _user, IBoneLocker _boneLocker, uint256 _maxBoneLockerRewardsAtOneClaim, address _feeReceiver, uint8 _feePercent) public onlyManager {
        if (address(_boneLocker) == address(0)) {
            _boneLocker = topDog.boneLocker();
        }

        (uint256 left, uint256 right) = _boneLocker.getLeftRightCounters(address(this));
        if (right <= left) {
            return;
        }

        if (_maxBoneLockerRewardsAtOneClaim > 0 && right - left > _maxBoneLockerRewardsAtOneClaim) {
            right = left + _maxBoneLockerRewardsAtOneClaim;
        }
        _boneLocker.claimAll(right);

        _sendAllBonesToUser(_user, _feeReceiver, _feePercent);
    }

    function emergencyWithdraw() public onlyManager {
        topDog.emergencyWithdraw(topDogPoolId);
    }

    function withdrawToken(address _token, address _user, uint _amount, address _feeReceiver, uint8 _feePercent) public onlyManager {
        if (_token == address(boneToken)) {
            _sendBonesToUser(_user, _amount, _feeReceiver, _feePercent);
        } else {
            TransferHelper.safeTransfer(_token, _user, _amount);
        }
    }

    function readBoneLocker(address _boneLocker, bytes calldata _callData) public view returns (bool success, bytes memory data) {
        (success, data) = _boneLocker.staticcall(_callData);
    }

    function callBoneLocker(address _boneLocker, bytes calldata _callData) public onlyManager returns (bool success, bytes memory data) {
        (success, data) = _boneLocker.call(_callData);
    }

    function getDepositedAmount() public view returns (uint amount) {
        (amount, ) = topDog.userInfo(topDogPoolId, address (this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
library SafeMath {
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

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2021 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IBoneLocker.sol";
import "./IBoneToken.sol";

/**
 * See https://etherscan.io/address/0x94235659cf8b805b2c658f9ea2d6d6ddbb17c8d7#code
 */
interface ITopDog  {

    function bone() external view returns (IBoneToken);
    function boneLocker() external view returns (IBoneLocker);
    function poolInfo(uint256) external view returns (IERC20, uint256, uint256, uint256);
    function poolLength() external view returns (uint256);
    function userInfo(uint256, address) external view returns (uint256, uint256);

    function rewardMintPercent() external view returns (uint256);
    function pendingBone(uint256 _pid, address _user) external view returns (uint256);
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2021 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;

/**
 * @dev BoneToken locker contract interface
 */
interface IBoneLocker {

    function lockInfoByUser(address, uint256) external view returns (uint256, uint256, bool);

    function lockingPeriod() external view returns (uint256);

    // function to claim all the tokens locked for a user, after the locking period
    function claimAllForUser(uint256 r, address user) external;

    // function to claim all the tokens locked by user, after the locking period
    function claimAll(uint256 r) external;

    // function to get claimable amount for any user
    function getClaimableAmount(address _user) external view returns(uint256);

    // get the left and right headers for a user, left header is the index counter till which we have already iterated, right header is basically the length of user's lockInfo array
    function getLeftRightCounters(address _user) external view returns(uint256, uint256);

    function lock(address _holder, uint256 _amount, bool _isDev) external;
    function setLockingPeriod(uint256 _newLockingPeriod, uint256 _newDevLockingPeriod) external;
    function emergencyWithdrawOwner(address _to) external;
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2021 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBoneToken is IERC20 {
    function mint(address _to, uint256 _amount) external;
}