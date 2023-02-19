// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";


contract TokenTimeLock{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public admin;
    IERC20Upgradeable public feeToken;
    address public stakingPoolAddress;

    uint256 public stakingPoolFee;
    uint256 public adminWalletFee;


    uint256[] AllAmountLocked;
    address[] AllTokensLocked;

    mapping(address => address[]) public allTokens;
    mapping(address => uint[]) public allAmount;


    
    struct Locks {
        
        uint id;
        address owner;
        address Token;
        address Beneficiary;
        uint256 amount;
        uint256 releaseTime;
        bool Claimed;
    }

    Locks[] public Alllocked;

    mapping(address => Locks[]) public LockingDetails;
    // mapping(address => mapping(uint => Locks[])) public LockingDetails2;

    struct inputs{
        address Token;
        address Beneficiary;
        uint256 amount;
        bool Vesting;
        uint256 FirstPercent;
        uint256 firstReleaseTime;
        uint256 cyclePercent;
        uint256 cyclereleaseTime;
        uint256 cycleCount;
    }
    
    
    mapping(address => mapping(uint => mapping (uint => Locks))) public LockedTokens;
    mapping(address => uint) personalLockedCount;
    mapping(address => mapping (uint => uint)) cycleCountPerID;
    mapping(address => mapping (uint => uint)) claimCycleCountPerID;

    constructor() {
        admin = msg.sender;
        stakingPoolAddress = msg.sender;
    }


    function makeInput(inputs calldata Inputs) internal pure returns(inputs memory){
        inputs memory A = inputs(
            Inputs.Token,
            Inputs.Beneficiary,
            Inputs.amount,
            Inputs.Vesting,
            Inputs.FirstPercent,
            Inputs.firstReleaseTime,
            Inputs.cyclePercent,
            Inputs.cyclereleaseTime,
            Inputs.cycleCount

        );

        return A;
    }


    function Lock(inputs calldata Inputs) external{
        uint count = Inputs.cycleCount; 

        personalLockedCount[msg.sender] +=1;

        IERC20Upgradeable(Inputs.Token).safeTransferFrom(msg.sender, address(this), Inputs.amount);
        
        // if(adminWalletFee > 0){
        //     IERC20Upgradeable(feeToken).safeTransferFrom(msg.sender, admin, adminWalletFee);
        // }
        
        // if(stakingPoolFee > 0){
        //     IERC20Upgradeable(feeToken).safeTransferFrom(msg.sender, stakingPoolAddress, stakingPoolFee);
        // }
        

        uint percentAmount = Inputs.amount /10000 * Inputs.cyclePercent;

        uint firstAmount = Inputs.amount /10000 * Inputs.FirstPercent;

        uint checkAmount = (percentAmount * (count - 1)) + firstAmount;

        require(checkAmount <= Inputs.amount, "Final Amount Exceeds Sent Amount");



        LockedTokens[msg.sender][personalLockedCount[msg.sender]][1] = Locks ({
            owner : msg.sender,
            id : personalLockedCount[msg.sender],
            Token :Inputs.Token,
            Beneficiary : Inputs.Beneficiary,
            amount : firstAmount,
            releaseTime: Inputs.firstReleaseTime,
            Claimed : false

        });

        LockingDetails[msg.sender].push(LockedTokens[msg.sender][personalLockedCount[msg.sender]][1]);
        // LockingDetails2[msg.sender][personalLockedCount[msg.sender] ].push(LockedTokens[msg.sender][personalLockedCount[msg.sender]][1]);

        Alllocked.push(LockedTokens[msg.sender][personalLockedCount[msg.sender]][1]);

        uint lastTime = block.timestamp;

        if(Inputs.Vesting){
            for(uint i = 2; i <= count; i++){
                lastTime += Inputs.cyclereleaseTime;

                        LockedTokens[msg.sender][personalLockedCount[msg.sender]][i] = Locks ({
                        owner : msg.sender,
                        id : personalLockedCount[msg.sender],
                        Token :Inputs.Token,
                        Beneficiary : Inputs.Beneficiary,
                        amount : percentAmount,
                        releaseTime: lastTime,
                        Claimed : false

                    });

                    LockingDetails[msg.sender].push(LockedTokens[msg.sender][personalLockedCount[msg.sender]][i]);
                    // LockingDetails2[msg.sender][personalLockedCount[msg.sender] ].push(LockedTokens[msg.sender][personalLockedCount[msg.sender]][i]);

                    Alllocked.push(LockedTokens[msg.sender][personalLockedCount[msg.sender]][i]);

                }

                

        }


        cycleCountPerID[msg.sender][personalLockedCount[msg.sender]] = count;
        
        allTokens[msg.sender].push(Inputs.Token);
        allAmount[msg.sender].push(Inputs.amount);

        AllAmountLocked.push(Inputs.amount);
        AllTokensLocked.push(Inputs.Token);


    }



    function Release(uint id) external{

        claimCycleCountPerID[msg.sender][id] ++;

        uint claimCount = claimCycleCountPerID[msg.sender][id];

        require(cycleCountPerID[msg.sender][id] > 0, "Fully Claimed Already");
        require(block.timestamp > LockedTokens[msg.sender][id][claimCount].releaseTime, "Time not reached for release");
        require(!LockedTokens[msg.sender][id][claimCount].Claimed, "Already Claimed for the index");

        uint Amount = LockedTokens[msg.sender][id][claimCount].amount;
        address _token = LockedTokens[msg.sender][id][claimCount].Token;
        address _beneficiary = LockedTokens[msg.sender][id][claimCount].Beneficiary;

        LockedTokens[msg.sender][id][claimCount].Claimed = true;


        IERC20Upgradeable(_token).safeTransfer(_beneficiary, Amount);
        

        cycleCountPerID[msg.sender][id]--;

    }


    
    function getTransaction(address owner_, uint id, uint256 index) external view returns(Locks memory){
        return LockedTokens[owner_][id][index];
    }

    function getLockedTokenDetails(address owner) external view returns(Locks[] memory){
        return LockingDetails[owner];
    }

    // function getLockedTokenDetailsWithIndex(address owner, uint id) external view returns(Locks[] memory){
    //     return LockingDetails2[owner][id];
    // }

  function getAllLockedDetailsInContract() external view returns(Locks[] memory){
      return Alllocked;
  }


    function updateWalletAddress(address _newAdminWallet, address _newStakingWallet) external{
        require(msg.sender == admin, "Not Admin");
        admin = _newAdminWallet;
        stakingPoolAddress = _newStakingWallet;
    }

    function updateFee(uint256 adminWalletFee_, uint256 stakingPoolFee_) external {
        require(msg.sender == admin, "Not Admin");
        adminWalletFee = adminWalletFee_;
        stakingPoolFee = stakingPoolFee_;

    }
    
    function token(address owner_, uint id, uint index) external view returns (address) {
        return LockedTokens[owner_][id][index].Token;
    }

    function beneficiary(address owner_, uint id, uint index) external view returns (address) {
        return LockedTokens[owner_][id][index].Beneficiary;
    }

    function releaseTime(address owner_, uint id, uint index) external view returns (uint256) {
        return LockedTokens[owner_][id][index].releaseTime;
    }

    function amount(address owner_, uint id, uint index) external view returns(uint256){
        return LockedTokens[owner_][id][index].amount;
    }

    function getClaimed(address owner_, uint id, uint index) external view returns(bool){
        return LockedTokens[owner_][id][index].Claimed;
    }
    function getAllTokensAndAmountForUser(address user) external view returns(address[] memory, uint256[] memory){
        return (allTokens[user], allAmount[user]);

    }
    function getAllTokensAndAmountInContract() external view returns(address[] memory, uint256[] memory){
        return (AllTokensLocked, AllAmountLocked);

    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
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

    function safePermit(
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
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