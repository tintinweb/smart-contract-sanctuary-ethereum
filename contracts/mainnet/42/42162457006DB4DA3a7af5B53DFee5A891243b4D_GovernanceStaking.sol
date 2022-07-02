// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "../shared/interfaces/IMgcCampaign.sol";
import "../shared/interfaces/IMgc.sol";
import "../shared/libraries/SafeERC20.sol";
import "../shared/libraries/SafeMath.sol";
import "../shared/types/MetaVaultAC.sol";
import "../shared/interfaces/IgMVD.sol";
import "../shared/interfaces/IMVD.sol";
import "../shared/interfaces/IStaking.sol";

contract GovernanceStaking is IMgcCampaign, MetaVaultAC {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    IMgc public mgc;

    struct UserInfo {
        uint256 staked;
        uint256 depositTime;
        uint256 nextClaimNumber;
    }

    struct Epoch {
        uint256 length; // in seconds
        uint256 number; // since inception
        uint256 endTime; // timestamp
        uint256 rewardRate; // amount
    }

    Epoch public epoch;

    uint256 public minLockTime;
    uint256 public penaltyPercent; // 30% = * 30 / 100
    uint256 public rebasePeriod;
    uint256 public rebaseRewards; // Token (DAI, MATIC, or others) amount distributed each reabse

    bool public emergencyWithdrawEnabled;

    uint256 public campaignEndTime;

    uint256 public PRECISION = 1000000000;

    mapping(address => UserInfo) public userInfo;
    mapping(uint256 => uint256) public rebases;

    address public mvd;
    address public gmvd;

    event ClaimReward(address indexed user, uint256 amount, bool stake);

    constructor(
        IMgc _mgc,
        uint256 _minLockTime,
        uint256 _penaltyPercent,
        uint256 _epochLength,
        uint256 _rebaseRewards,
        uint256 _campaignEndTime,
        address _authority
    ) MetaVaultAC(IMetaVaultAuthority(_authority)) {
        mgc = _mgc;
        minLockTime = _minLockTime;
        penaltyPercent = _penaltyPercent;
        rebaseRewards = _rebaseRewards;
        campaignEndTime = _campaignEndTime;
        epoch = Epoch({length: _epochLength, number: 0, endTime: block.timestamp.add(_epochLength), rewardRate: 0});
    }

    function setParam(
        uint256 _minLockTime,
        uint256 _penaltyPercent,
        uint256 _rebaseRewards,
        uint256 _campaignEndTime
    ) external onlyGovernor {
        minLockTime = _minLockTime;
        penaltyPercent = _penaltyPercent;
        rebaseRewards = _rebaseRewards;
        campaignEndTime = _campaignEndTime;
    }

    function setTokens(
        IMgc _mgc,
        address _mvd,
        address _gmvd
    ) external onlyGovernor {
        require(_mvd != address(0), "MVD invalid address");
        require(_gmvd != address(0), "gMVD invalid address");
        mgc = _mgc;

        mvd = _mvd;
        gmvd = _gmvd;
    }

    function setPrecision(uint256 _precision) external onlyGovernor {
        PRECISION = _precision;
    }

    function setEmergencyWithdraw(bool en) external onlyGovernor {
        emergencyWithdrawEnabled = en;
    }

    function isActive() external view returns (bool) {
        return block.timestamp < campaignEndTime;
    }

    function rebase() public {
        if (epoch.endTime < block.timestamp) {
            uint256 totalStaked = mgc.totalStaked();
            uint256 rewardRate = totalStaked > 0 ? rebaseRewards.mul(PRECISION).div(totalStaked) : 0;
            epoch.rewardRate = rewardRate;
            epoch.endTime = epoch.endTime.add(epoch.length);
            epoch.number++;
            rebases[epoch.number] = rewardRate;
            rebase();
        }
    }

    function getUnlockTime(address user) public view returns (uint256) {
        return userInfo[user].depositTime + minLockTime;
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "MGC: invalid deposit amount");
        require(campaignEndTime > block.timestamp, "MGC: ended");
        claim();

        IERC20(mgc.mvd()).safeTransferFrom(msg.sender, address(this), amount);

        _deposit(amount);
    }

    function _deposit(uint256 amount) private {
        UserInfo storage user = userInfo[msg.sender];
        user.depositTime = block.timestamp;
        user.nextClaimNumber = epoch.number + 1;
        user.staked += amount;

        mgc.updateDeposit(amount);
        IgMVD(gmvd).mint(msg.sender, amount);
        emit Deposit(msg.sender, amount);
    }

    function withdraw() external {
        require(userInfo[msg.sender].staked > 0, "MGC: nothing to withdraw");
        UserInfo storage user = userInfo[msg.sender];
        rebase();
        mgc.updateWithdraw(user.staked);

        if (getUnlockTime(msg.sender) < block.timestamp) {
            claim();
        } else {
            user.nextClaimNumber = epoch.number + 1;
            uint256 penalty = user.staked.mul(penaltyPercent).div(100);

            IMVD(mvd).burn(penalty);
            IgMVD(gmvd).burn(msg.sender, penalty);

            user.staked = user.staked.sub(penalty);
        }

        IERC20(mgc.mvd()).safeTransfer(msg.sender, user.staked);
        IgMVD(gmvd).burn(msg.sender, user.staked);

        emit Withdraw(msg.sender, user.staked);
        user.staked = 0;
    }

    function emergencyWithdraw() external {
        require(emergencyWithdrawEnabled, "MGC: emergencyWithdraw is unavailable");
        uint256 staked = userInfo[msg.sender].staked;
        IERC20(mgc.mvd()).safeTransfer(msg.sender, staked);
        userInfo[msg.sender].staked = 0;
        emit Withdraw(msg.sender, staked);
    }

    function getReward(address user) public view returns (uint256, uint256) {
        uint256 staked = userInfo[user].staked;
        uint256 nextClaimNumber = userInfo[user].nextClaimNumber;
        if (staked == 0) {
            return (0, nextClaimNumber);
        }
        uint256 currentBlock = block.timestamp > campaignEndTime ? campaignEndTime : block.timestamp;
        if (nextClaimNumber > currentBlock) {
            return (0, nextClaimNumber);
        }

        uint256 _totalReward;
        for (uint256 index = nextClaimNumber; index <= epoch.number; index++) {
            uint256 _rewardRate = rebases[index];
            uint256 _reward = _rewardRate.mul(staked).div(PRECISION);
            _totalReward = _totalReward.add(_reward);
        }

        return (_totalReward, epoch.number + 1);
    }

    function claim() public {
        rebase();
        (uint256 reward, uint256 nextClaimNumber) = getReward(msg.sender);
        if (reward > 0) {
            userInfo[msg.sender].nextClaimNumber = nextClaimNumber;
            mgc.sendReward(msg.sender, msg.sender, reward);
            emit ClaimReward(msg.sender, reward, false);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

interface IMgcCampaign {
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

interface IMgc {
    function principle() external view returns (address);

    function mvd() external view returns (address);

    function totalStaked() external view returns (uint256);

    function updateDeposit(uint256 value) external;

    function updateWithdraw(uint256 value) external;

    function sendReward(
        address receiver,
        address user,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "./SafeMath.sol";
import "./Address.sol";
import "../interfaces/IERC20.sol";

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }

    function percentageAmount( uint256 total_, uint8 percentage_ ) internal pure returns ( uint256 percentAmount_ ) {
        return div( mul( total_, percentage_ ), 1000 );
    }

    function substractPercentage( uint256 total_, uint8 percentageToSub_ ) internal pure returns ( uint256 result_ ) {
        return sub( total_, div( mul( total_, percentageToSub_ ), 1000 ) );
    }

    function percentageOfTotal( uint256 part_, uint256 total_ ) internal pure returns ( uint256 percent_ ) {
        return div( mul(part_, 100) , total_ );
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    function quadraticPricing( uint256 payment_, uint256 multiplier_ ) internal pure returns (uint256) {
        return sqrrt( mul( multiplier_, payment_ ) );
    }

  function bondingCurve( uint256 supply_, uint256 multiplier_ ) internal pure returns (uint256) {
      return mul( multiplier_, supply_ );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "../interfaces/IMetaVaultAuthority.sol";

abstract contract MetaVaultAC {
    IMetaVaultAuthority public authority;

    event AuthorityUpdated(IMetaVaultAuthority indexed authority);

    constructor(IMetaVaultAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), "MetavaultAC: caller is not the Governer");
        _;
    }

    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), "MetavaultAC: caller is not the Policy");
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), "MetavaultAC: caller is not the Vault");
        _;
    }

    function setAuthority(IMetaVaultAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "./IERC20.sol";

interface IgMVD is IERC20 {
    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    function index() external view returns (uint256);

    function balanceFrom(uint256 _amount) external view returns (uint256);

    function balanceTo(uint256 _amount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "./IERC20.sol";

interface IMVD is IERC20 {
    function mint(address account_, uint256 amount_) external;

    function burn(uint256 amount) external;

    function burnFrom(address account_, uint256 amount_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

interface IStaking {
    function stake(uint256 _amount, address _recipient) external returns (bool);

    function claim(address _recipient) external;

    function rebase() external;

    function epoch()
        external
        view
        returns (
            uint256 length,
            uint256 number,
            uint256 endBlock,
            uint256 distribute
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
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
        (bool success, ) = recipient.call{value: amount}("");
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    // function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
    //     require(address(this).balance >= value, "Address: insufficient balance for call");
    //     return _functionCallWithValue(target, data, value, errorMessage);
    // }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

    function addressToString(address _address) internal pure returns (string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _addr = new bytes(42);

        _addr[0] = "0";
        _addr[1] = "x";

        for (uint256 i = 0; i < 20; i++) {
            _addr[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _addr[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }

        return string(_addr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

interface IERC20 {

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

interface IMetaVaultAuthority {
    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event GovernorPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    function governor() external view returns (address);

    function policy() external view returns (address);

    function vault() external view returns (address);
}