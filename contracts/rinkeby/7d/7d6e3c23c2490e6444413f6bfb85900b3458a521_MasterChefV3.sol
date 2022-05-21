/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

/** 
 *  SourceUnit: c:\Projects\ibl\sc-capital-dao\contracts\staking\MasterChefV3.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
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
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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




/** 
 *  SourceUnit: c:\Projects\ibl\sc-capital-dao\contracts\staking\MasterChefV3.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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




/** 
 *  SourceUnit: c:\Projects\ibl\sc-capital-dao\contracts\staking\MasterChefV3.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}




/** 
 *  SourceUnit: c:\Projects\ibl\sc-capital-dao\contracts\staking\MasterChefV3.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "../IERC20.sol";
////import "../../../utils/Address.sol";

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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




/** 
 *  SourceUnit: c:\Projects\ibl\sc-capital-dao\contracts\staking\MasterChefV3.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;
////import "../proxy/utils/Initializable.sol";

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




/** 
 *  SourceUnit: c:\Projects\ibl\sc-capital-dao\contracts\staking\MasterChefV3.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;
////import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}


/** 
 *  SourceUnit: c:\Projects\ibl\sc-capital-dao\contracts\staking\MasterChefV3.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

////import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

////import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
////import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IRole {

    function isAdmin(address _account) external view returns (bool);
    function isOperator(address _account) external view returns (bool);

}

interface IStakingRewardVault {

    function transfer(address _token, address _receiver, uint256 _amount) external;
    function getBalance(address _token) external view returns (uint256);

}

contract MasterChefV3 is ContextUpgradeable, ReentrancyGuardUpgradeable {

    using SafeERC20 for IERC20;

    uint256 internal constant REWARD_PER_SHARE_MULTIPLIER = 1e12;

    uint256 internal constant ONE_HUNDRED_PERCENT = 10000; // 100%

    struct User {
        uint256 amount;
        uint256[] rewardDebts;
    }

    struct Pool {
        address stakingToken;
        address[] rewardTokens;
        uint256[] rewardPerBlocks;
        uint256[] rewardPerShares;
        uint256[] totalRewards;
        uint128 lastRewardBlock;
        uint128 depositFeePercent;
        uint128 startBlock;
        uint128 endBlock;
        uint256 totalStaked;
        uint128 enable;
        uint128 started;
    }

    IRole public role;

    IStakingRewardVault public vault;

    mapping(uint256 => Pool) private _pools;

    mapping(uint256 => mapping(address => User)) private _users;

    address public treasury;

    event TreasuryUpdated(address treasury);

    event PoolCreated(uint256 id, address stakingToken, address[2] rewardTokens, uint256[2] totalRewards, uint128 startBlock, uint128 endBlock, uint256[2] rewardPerBlocks, uint128 depositFeePercent);
    event PoolUpdated(uint256 id, address stakingToken, address[2] rewardTokens, uint256[2] totalRewards, uint128 startBlock, uint128 endBlock, uint256[2] rewardPerBlocks, uint128 depositFeePercent);
    event PoolEnabled(uint256 id);
    event PoolDisabled(uint256 id);

    event Staked(address user, uint256 pid, uint256 amount);
    event Unstaked(address user, uint256 pid, uint256 amount);

    event EmergencyWithdraw(address user, uint256 pid, uint256 amount);

    modifier onlyAdmin() {
        require(role.isAdmin(_msgSender()), "MasterChef: caller is not admin");
        _;
    }

    modifier onlyOperator() {
        require(role.isOperator(_msgSender()), "MasterChef: caller is not operator");
        _;
    }

    modifier poolNotExist(uint256 _id) {
        require(_pools[_id].startBlock == 0, "MasterChef: pool exists");
        _;
    }

    modifier poolExist(uint256 _id) {
        require(_pools[_id].startBlock > 0, "MasterChef: pool does not exist");
        _;
    }

    modifier poolNotPause(uint256 _id) {
        require(_pools[_id].enable > 0, "MasterChef: pool was disabled");
        _;
    }

    function initialize(IRole _role, IStakingRewardVault _vault)
        public
        initializer
    {
        __Context_init();
        __ReentrancyGuard_init();

        role = _role;
        vault = _vault;

        treasury = _msgSender();
    }

    function getPool(uint256 _id)
        public
        view
        returns(address, address[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint128, uint128, uint128, uint128, uint256, bool)
    {
        Pool memory pool = _pools[_id];

        return (pool.stakingToken, pool.rewardTokens, pool.rewardPerBlocks, pool.rewardPerShares, pool.totalRewards, pool.lastRewardBlock, pool.depositFeePercent, pool.startBlock, pool.endBlock, pool.totalStaked, pool.enable > 0 ? true : false);
    }

    function getUser(uint256 _pid, address _account)
        public
        view
        returns(uint256, uint256[] memory)
    {
        User memory user = _users[_pid][_account];

        return (user.amount, user.rewardDebts);
    }

    function setTreasury(address _treasury)
        public
        onlyAdmin
    {
        require(_treasury != address(0), "MasterChef: address is invalid");

        treasury = _treasury;

        emit TreasuryUpdated(_treasury);
    }

    function _checkPoolParams(address _stakingToken, address[2] memory _rewardTokens, uint256[2] memory _totalRewards, uint128 _startBlock, uint128 _endBlock, uint256[2] memory _rewardPerBlocks, uint128 _depositFeePercent)
        internal
        pure
    {
        require(_stakingToken != address(0), "MasterChef: staking token is invalid");

        require(_rewardTokens[0] != address(0), "MasterChef: reward token is invalid");

        require(_totalRewards[0] > 0, "MasterChef: total reward is invalid");

        require(_startBlock > 0 && _startBlock < _endBlock, "MasterChef: start block or end block is invalid");

        require(_rewardPerBlocks[0] > 0, "MasterChef: reward per block is invalid");

        require(_depositFeePercent <= ONE_HUNDRED_PERCENT, "MasterChef: percent is invalid");
    }

    function createPool(uint256 _id, address _stakingToken, address[2] memory _rewardTokens, uint256[2] memory _totalRewards, uint128 _startBlock, uint128 _endBlock, uint256[2] memory _rewardPerBlocks, uint128 _depositFeePercent)
        public
        onlyOperator
        poolNotExist(_id)
    {
        _checkPoolParams(_stakingToken, _rewardTokens, _totalRewards, _startBlock, _endBlock, _rewardPerBlocks, _depositFeePercent);

        Pool storage pool = _pools[_id];

        pool.stakingToken = _stakingToken;
        pool.lastRewardBlock = block.number > _startBlock ? uint128(block.number) : _startBlock;
        pool.depositFeePercent = _depositFeePercent;
        pool.startBlock = _startBlock;
        pool.endBlock = _endBlock;
        pool.enable = 1;

        for (uint256 i = 0; i < 2; i++) {
            pool.rewardTokens.push(_rewardTokens[i]);
            pool.rewardPerBlocks.push(_rewardPerBlocks[i]);
            pool.rewardPerShares.push(0);
            pool.totalRewards.push(_totalRewards[i]);
        }

        emit PoolCreated(_id, _stakingToken, _rewardTokens, _totalRewards, _startBlock, _endBlock, _rewardPerBlocks, _depositFeePercent);
    }

    function updatePool(uint256 _id, address _stakingToken, address[2] memory _rewardTokens, uint256[2] memory _totalRewards, uint128 _startBlock, uint128 _endBlock, uint256[2] memory _rewardPerBlocks, uint128 _depositFeePercent)
        public
        onlyOperator
        poolExist(_id)
    {
        _checkPoolParams(_stakingToken, _rewardTokens, _totalRewards, _startBlock, _endBlock, _rewardPerBlocks, _depositFeePercent);

        Pool storage pool = _pools[_id];

        bool started = pool.started > 0 ? true : false;

        if (started) {
            _updatePool(_id);
        }

        if (pool.stakingToken != _stakingToken) {
            require(!started, "MasterChef: can not update 'staking token'");

            pool.stakingToken = _stakingToken;
        }

        if (pool.depositFeePercent != _depositFeePercent) {
            pool.depositFeePercent = _depositFeePercent;
        }

        if (pool.startBlock != _startBlock) {
            require(!started, "MasterChef: can not update 'start block'");

            pool.startBlock = _startBlock;
            pool.lastRewardBlock = block.number > _startBlock ? uint128(block.number) : _startBlock;
        }

        if (pool.endBlock != _endBlock) {
            require(!started, "MasterChef: can not update 'end block'");

            pool.endBlock = _endBlock;
        }

        for (uint256 i = 0; i < 2; i++) {
            if (pool.rewardTokens[i] != _rewardTokens[i]) {
                require(!started, "MasterChef: can not update 'reward token");

                pool.rewardTokens[i] = _rewardTokens[i];
            }

            if (pool.rewardPerBlocks[i] != _rewardPerBlocks[i]) {
                pool.rewardPerBlocks[i] = _rewardPerBlocks[i];
            }

            if (pool.totalRewards[i] != _totalRewards[i]) {
                require(!started, "MasterChef: can not update 'total reward");

                pool.totalRewards[i] = _totalRewards[i];
            }
        }

        emit PoolUpdated(_id, _stakingToken, _rewardTokens, _totalRewards, _startBlock, _endBlock, _rewardPerBlocks, _depositFeePercent);
    }

    function enablePool(uint256 _id)
        public
        onlyOperator
        poolExist(_id)
    {
        _pools[_id].enable = 1;

        emit PoolEnabled(_id);
    }

    function disablePool(uint256 _id)
        public
        onlyOperator
        poolExist(_id)
    {
        _pools[_id].enable = 0;

        emit PoolDisabled(_id);
    }

    function rewardToShare(uint256 _reward, uint256 _rewardPerShare) public pure returns (uint256) {
        return (_reward * REWARD_PER_SHARE_MULTIPLIER) / _rewardPerShare;
    }

    function shareToReward(uint256 _share, uint256 _rewardPerShare) public pure returns (uint256) {
        return (_share * _rewardPerShare) / REWARD_PER_SHARE_MULTIPLIER;
    }

    function pendingReward(uint256 _pid, address _account) public view returns (uint256[2] memory pendings) {
        Pool memory pool = _pools[_pid];

        User memory user = _users[_pid][_account];

        if (pool.startBlock == 0 || user.rewardDebts.length == 0) {
            return pendings;
        }

        uint128 blockNumber = block.number > pool.endBlock ? pool.endBlock : uint128(block.number);

        bool flg = blockNumber > pool.lastRewardBlock && pool.totalStaked > 0;

        for (uint256 i = 0; i < 2; i++) {
            uint256 rewardPerShare = pool.rewardPerShares[i];

            if (flg) {
                uint256 reward = (blockNumber - pool.lastRewardBlock) * pool.rewardPerBlocks[i];

                uint256 remaining = vault.getBalance(pool.rewardTokens[i]);

                if (remaining > pool.totalRewards[i]) {
                    remaining = pool.totalRewards[i];
                }

                if (reward > remaining) {
                    reward = remaining;
                }

                if (reward > 0) {
                    rewardPerShare += rewardToShare(reward, pool.totalStaked);
                }
            }

            pendings[i] = shareToReward(user.amount, rewardPerShare) - user.rewardDebts[i];
        }
    }

    function _updatePool(uint256 _id)
        internal
        nonReentrant
    {
        Pool storage pool = _pools[_id];

        uint128 blockNumber = block.number > pool.endBlock ? pool.endBlock : uint128(block.number);

        if (blockNumber <= pool.lastRewardBlock) {
            return;
        }

        if (pool.totalStaked == 0) {
            pool.lastRewardBlock = blockNumber;
            return;
        }

        for (uint256 i = 0; i < 2; i++) {
            uint256 reward = (blockNumber - pool.lastRewardBlock) * pool.rewardPerBlocks[i];

            uint256 remaining = vault.getBalance(pool.rewardTokens[i]);

            if (remaining > pool.totalRewards[i]) {
                remaining = pool.totalRewards[i];
            }

            if (reward > remaining) {
                reward = remaining;
            }

            if (reward > 0) {
                vault.transfer(pool.rewardTokens[i], address(this), reward);

                pool.totalRewards[i] -= reward;
                pool.rewardPerShares[i] += rewardToShare(reward, pool.totalStaked);
            }
        }

        pool.lastRewardBlock = blockNumber;
    }

    function stake(uint256 _pid, uint256 _amount)
        public
        poolNotPause(_pid)
    {
        _updatePool(_pid);

        address msgSender = _msgSender();

        Pool storage pool = _pools[_pid];

        User storage user = _users[_pid][msgSender];

        if (user.amount > 0) {
            for (uint256 i = 0; i < 2; i++) {
                uint256 pending = shareToReward(user.amount, pool.rewardPerShares[i]) - user.rewardDebts[i];

                if (pending > 0) {
                    IERC20(pool.rewardTokens[i]).safeTransfer(msgSender, pending);
                }
            }
        }

        if (_amount > 0) {
            if (pool.started == 0) {
                pool.started = 1;
            }

            IERC20(pool.stakingToken).safeTransferFrom(msgSender, address(this), _amount);

            if (pool.depositFeePercent > 0) {
                uint256 depositFee = (_amount * pool.depositFeePercent) / ONE_HUNDRED_PERCENT;

                IERC20(pool.stakingToken).safeTransfer(treasury, depositFee);

                user.amount += (_amount - depositFee);

                pool.totalStaked += (_amount - depositFee);

            } else {
                user.amount += _amount;

                pool.totalStaked += _amount;
            }
        }

        if (user.rewardDebts.length == 0) {
            for (uint256 i = 0; i < 2; i++) {
                user.rewardDebts.push(shareToReward(user.amount, pool.rewardPerShares[i]));
            }

        } else {
            for (uint256 i = 0; i < 2; i++) {
                user.rewardDebts[i] = shareToReward(user.amount, pool.rewardPerShares[i]);
            }
        }

        emit Staked(msgSender, _pid, _amount);
    }

    function unstake(uint256 _pid, uint256 _amount)
        public
        poolNotPause(_pid)
    {
        _updatePool(_pid);

        address msgSender = _msgSender();

        Pool storage pool = _pools[_pid];

        User storage user = _users[_pid][msgSender];

        require(user.amount >= _amount, "MasterChef: amount exceeds stake");

        for (uint256 i = 0; i < 2; i++) {
            uint256 pending = shareToReward(user.amount, pool.rewardPerShares[i]) - user.rewardDebts[i];

            if (pending > 0) {
                IERC20(pool.rewardTokens[i]).safeTransfer(msgSender, pending);
            }
        }

        if (_amount > 0) {
            user.amount -= _amount;

            pool.totalStaked -= _amount;

            IERC20(pool.stakingToken).safeTransfer(msgSender, _amount);
        }

        for (uint256 i = 0; i < 2; i++) {
            user.rewardDebts[i] = shareToReward(user.amount, pool.rewardPerShares[i]);
        }

        emit Unstaked(msgSender, _pid, _amount);
    }

    // Unstaked without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid)
        public
        poolExist(_pid)
        nonReentrant
    {
        address msgSender = _msgSender();

        Pool storage pool = _pools[_pid];

        User storage user = _users[_pid][msgSender];

        IERC20(pool.stakingToken).safeTransfer(msgSender, user.amount);

        emit EmergencyWithdraw(msgSender, _pid, user.amount);

        pool.totalStaked -= user.amount;

        user.amount = 0;

        for (uint256 i = 0; i < 2; i++) {
            user.rewardDebts[i] = 0;
        }
    }

    function getStakedPools(address _account, uint256 _pidFrom, uint256 _pidTo)
        public
        view
        returns(uint256[] memory pools)
    {
        uint256 cnt = 0;

        uint256[] memory ids = new uint256[](_pidTo - _pidFrom + 1);

        for (uint256 i = _pidFrom; i <= _pidTo; i++) {
            if (_users[i][_account].amount > 0) {
                ids[cnt++] = i;
            }
        }

        pools = new uint256[](cnt);

        for (uint256 i = 0; i < cnt; i++) {
            pools[i] = ids[i];
        }
    }

}