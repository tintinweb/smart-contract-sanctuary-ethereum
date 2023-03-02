pragma solidity ^0.8.0;

import {ClonesWithImmutableArgs} from "clones-with-immutable-args/ClonesWithImmutableArgs.sol";
import {IERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IVestingVaultFactory} from "vesting/interfaces/IVestingVaultFactory.sol";
import {ECOxCliffLockup} from "./ECOxCliffLockup.sol";

contract ECOxCliffLockupFactory is IVestingVaultFactory {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ClonesWithImmutableArgs for address;

    address public immutable implementation;

    address public immutable token;

    address public immutable staking;

    constructor(
        address _implementation,
        address _token,
        address _staking
    ) {
        implementation = _implementation;
        token = _token;
        staking = _staking;
    }

    /**
     * @notice Creates a new vesting vault
     * @param beneficiary The address who will receive tokens over time
     * @param admin The address that can claw back unvested funds
     * @param timestamp The cliff timestamp at which tokens vest
     * @return The address of the ECOxCliffLockup contract created
     */

    function createVault(
        address beneficiary,
        address admin,
        uint256 timestamp
    ) public returns (address) {
        uint256 len = 1;
        bytes memory data = abi.encodePacked(
            token,
            beneficiary,
            len,
            [0],
            [timestamp]
        );
        ECOxCliffLockup clone = ECOxCliffLockup(implementation.clone(data));

        clone.initialize(admin, staking);
        emit VaultCreated(token, beneficiary, address(clone));
        return address(clone);
    }
}

// SPDX-License-Identifier: BSD

pragma solidity ^0.8.4;

/// @title ClonesWithImmutableArgs
/// @author wighawag, zefram.eth
/// @notice Enables creating clone contracts with immutable args
library ClonesWithImmutableArgs {
    error CreateFail();

    /// @notice Creates a clone proxy of the implementation contract, with immutable args
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param data Encoded immutable args
    /// @return instance The address of the created clone
    function clone(address implementation, bytes memory data)
        internal
        returns (address payable instance)
    {
        // unrealistic for memory ptr or data length to exceed 256 bits
        unchecked {
            uint256 extraLength = data.length + 2; // +2 bytes for telling how much data there is appended to the call
            uint256 creationSize = 0x41 + extraLength;
            uint256 runSize = creationSize - 10;
            uint256 dataPtr;
            uint256 ptr;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                ptr := mload(0x40)

                // -------------------------------------------------------------------------------------------------------------
                // CREATION (10 bytes)
                // -------------------------------------------------------------------------------------------------------------

                // 61 runtime  | PUSH2 runtime (r)     | r                       | –
                mstore(
                    ptr,
                    0x6100000000000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x01), shl(240, runSize)) // size of the contract running bytecode (16 bits)

                // creation size = 0a
                // 3d          | RETURNDATASIZE        | 0 r                     | –
                // 81          | DUP2                  | r 0 r                   | –
                // 60 creation | PUSH1 creation (c)    | c r 0 r                 | –
                // 3d          | RETURNDATASIZE        | 0 c r 0 r               | –
                // 39          | CODECOPY              | 0 r                     | [0-runSize): runtime code
                // f3          | RETURN                |                         | [0-runSize): runtime code

                // -------------------------------------------------------------------------------------------------------------
                // RUNTIME (55 bytes + extraLength)
                // -------------------------------------------------------------------------------------------------------------

                // 3d          | RETURNDATASIZE        | 0                       | –
                // 3d          | RETURNDATASIZE        | 0 0                     | –
                // 3d          | RETURNDATASIZE        | 0 0 0                   | –
                // 3d          | RETURNDATASIZE        | 0 0 0 0                 | –
                // 36          | CALLDATASIZE          | cds 0 0 0 0             | –
                // 3d          | RETURNDATASIZE        | 0 cds 0 0 0 0           | –
                // 3d          | RETURNDATASIZE        | 0 0 cds 0 0 0 0         | –
                // 37          | CALLDATACOPY          | 0 0 0 0                 | [0, cds) = calldata
                // 61          | PUSH2 extra           | extra 0 0 0 0           | [0, cds) = calldata
                mstore(
                    add(ptr, 0x03),
                    0x3d81600a3d39f33d3d3d3d363d3d376100000000000000000000000000000000
                )
                mstore(add(ptr, 0x13), shl(240, extraLength))

                // 60 0x37     | PUSH1 0x37            | 0x37 extra 0 0 0 0      | [0, cds) = calldata // 0x37 (55) is runtime size - data
                // 36          | CALLDATASIZE          | cds 0x37 extra 0 0 0 0  | [0, cds) = calldata
                // 39          | CODECOPY              | 0 0 0 0                 | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 36          | CALLDATASIZE          | cds 0 0 0 0             | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 61 extra    | PUSH2 extra           | extra cds 0 0 0 0       | [0, cds) = calldata, [cds, cds+0x37) = extraData
                mstore(
                    add(ptr, 0x15),
                    0x6037363936610000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x1b), shl(240, extraLength))

                // 01          | ADD                   | cds+extra 0 0 0 0       | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 3d          | RETURNDATASIZE        | 0 cds 0 0 0 0           | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 73 addr     | PUSH20 0x123…         | addr 0 cds 0 0 0 0      | [0, cds) = calldata, [cds, cds+0x37) = extraData
                mstore(
                    add(ptr, 0x1d),
                    0x013d730000000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x20), shl(0x60, implementation))

                // 5a          | GAS                   | gas addr 0 cds 0 0 0 0  | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // f4          | DELEGATECALL          | success 0 0             | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 3d          | RETURNDATASIZE        | rds success 0 0         | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 3d          | RETURNDATASIZE        | rds rds success 0 0     | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 93          | SWAP4                 | 0 rds success 0 rds     | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 80          | DUP1                  | 0 0 rds success 0 rds   | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 3e          | RETURNDATACOPY        | success 0 rds           | [0, rds) = return data (there might be some irrelevant leftovers in memory [rds, cds+0x37) when rds < cds+0x37)
                // 60 0x35     | PUSH1 0x35            | 0x35 sucess 0 rds       | [0, rds) = return data
                // 57          | JUMPI                 | 0 rds                   | [0, rds) = return data
                // fd          | REVERT                | –                       | [0, rds) = return data
                // 5b          | JUMPDEST              | 0 rds                   | [0, rds) = return data
                // f3          | RETURN                | –                       | [0, rds) = return data
                mstore(
                    add(ptr, 0x34),
                    0x5af43d3d93803e603557fd5bf300000000000000000000000000000000000000
                )
            }

            // -------------------------------------------------------------------------------------------------------------
            // APPENDED DATA (Accessible from extcodecopy)
            // (but also send as appended data to the delegatecall)
            // -------------------------------------------------------------------------------------------------------------

            extraLength -= 2;
            uint256 counter = extraLength;
            uint256 copyPtr = ptr + 0x41;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                dataPtr := add(data, 32)
            }
            for (; counter >= 32; counter -= 32) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    mstore(copyPtr, mload(dataPtr))
                }

                copyPtr += 32;
                dataPtr += 32;
            }
            uint256 mask = ~(256**(32 - counter) - 1);
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(copyPtr, and(mload(dataPtr), mask))
            }
            copyPtr += counter;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(copyPtr, shl(240, extraLength))
            }
            // solhint-disable-next-line no-inline-assembly
            assembly {
                instance := create(0, ptr, creationSize)
            }
            if (instance == address(0)) {
                revert CreateFail();
            }
        }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @notice Interface for VestingVault factory contracts
 * vault creation function will have different signature for
 * different vaults given varying parameters
 * so this interface just specifies events, errors, and common
 * functions
 */
interface IVestingVaultFactory {
    event VaultCreated(address indexed token, address indexed beneficiary, address indexed vault);

    /// @notice Some parameters are invalid
    error InvalidParams();
}

pragma solidity 0.8.15;

import {ECOxChunkedLockup} from "./ECOxChunkedLockup.sol";
import {IECOx} from "./interfaces/IECOx.sol";
import {IERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import {ChunkedVestingVault} from "vesting/ChunkedVestingVault.sol";
import {IECOxStaking} from "./interfaces/IECOxStaking.sol";

/**
 * @notice ECOxCliffLockup contract is funded regularly with ECOx. Until a cliff date has passed,
 * the funds cannot be removed, but otherwise there is no unlock schedule and payout is determined by
 * the funding schedule instead. It is initialized with only one timestamp (cliff date) and an initial
 * token amount of zero. The methods found in ChunkedVestingVaultArgs will not provide useful information
 * and any methods referring to amounts, instead the vault is intended to be emptyable at will by the
 * beneficiary after the cliff date.
 *
 * Due to the vault being funded multiple times over its lifetime, primary delegation must be used.
 */
contract ECOxCliffLockup is ECOxChunkedLockup {
    function initialize(address admin, address staking)
        public
        override
        initializer
    {
        ChunkedVestingVault._initialize(admin);

        address _stakedToken = staking;
        if (_stakedToken == address(0)) revert InvalidLockup();
        stakedToken = _stakedToken;
    }

    /**
     * @notice calculates tokens vested at a given timestamp
     * @param timestamp The time for which vested tokens are being calculated
     * @return amount of tokens vested at timestamp
     */
    function vestedOn(uint256 timestamp)
        public
        view
        override
        returns (uint256 amount)
    {
        return
            timestamp >= this.timestampAtIndex(0)
                ? token().balanceOf(address(this)) +
                    IERC20Upgradeable(stakedToken).balanceOf(address(this))
                : 0;
    }

    /**
     * @notice Delegates staked ECOx to a chosen recipient
     * @param who The address to delegate to
     */
    function _delegate(address who) internal override {
        IECOxStaking(stakedToken).delegate(who);
        currentDelegate = who;
    }

    /**
     * @notice helper function unstaking required tokens before they are claimed
     * @param amount amount of vested tokens being claimed
     */
    function onClaim(uint256 amount) internal override {
        uint256 balance = token().balanceOf(address(this));
        if (balance < amount) {
            _unstake(amount - balance);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC1820RegistryUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/utils/introspection/IERC1820RegistryUpgradeable.sol";
import {IERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ClawbackVestingVault} from "vesting/ClawbackVestingVault.sol";
import {ChunkedVestingVault} from "vesting/ChunkedVestingVault.sol";
import {VestingVault} from "vesting/VestingVault.sol";
import {IECOx} from "./interfaces/IECOx.sol";
import {IECOxStaking} from "./interfaces/IECOxStaking.sol";

/**
 * @notice ECOxChunkedLockup contract implements ChunkedVestingVault for the ECOx currency.
 * This contract is funded entirely on creation and follows the same rules as a standard ChunkedVestingVault.
 * The addition is that it is able to stake all funds in ECOxStaking and delegate them to the beneficiary.
 * Then, when vested, funds are undelegated and withdrawn from the ECOxStaking contract before allowing the
 * inherited chunked vault logic to kick in.
 *
 * Due to the vault being completely funded on instantiation, it is able to use delegation by amount.
 */
contract ECOxChunkedLockup is ChunkedVestingVault {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice Lockup address is invalid
    error InvalidLockup();

    /// @notice Invalid staked amount
    error InvalidAmount();

    event Unstaked(uint256 amount);
    event Staked(uint256 amount);

    IERC1820RegistryUpgradeable internal constant ERC1820 =
        IERC1820RegistryUpgradeable(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 internal constant LOCKUP_HASH =
        keccak256(abi.encodePacked("ECOxStaking"));

    address public stakedToken;

    address public currentDelegate;

    uint256 public delegatedAmount;

    /**
     * @notice Initializes the lockup vault
     * @dev this pulls in the required ERC20 tokens from the sender to setup
     */
    function initialize(address admin, address staking)
        public
        virtual
        initializer
    {
        ChunkedVestingVault._initialize(admin);

        address _lockup = staking;
        if (_lockup == address(0)) revert InvalidLockup();
        stakedToken = _lockup;

        _stake(token().balanceOf(address(this)));
        _delegate(beneficiary());
    }

    /**
     * @inheritdoc ChunkedVestingVault
     */
    function onClaim(uint256 amount) internal virtual override {
        uint256 balance = token().balanceOf(address(this));
        if (balance < amount) {
            _unstake(amount - balance);
        }
        super.onClaim(amount);
    }

    /**
     * @notice Stakes ECOx in the lockup contract
     * @param amount The amount of ECOx to stake
     */
    function stake(uint256 amount) external {
        if (msg.sender != beneficiary()) revert Unauthorized();
        if (amount > token().balanceOf(address(this))) revert InvalidAmount();
        _stake(amount);
    }

    /**
     * @notice Stakes ECOx in the lockup contract
     * @param amount The amount of ECOx to stake
     */
    function _stake(uint256 amount) internal {
        address _lockup = stakedToken;
        token().approve(_lockup, amount);
        IECOxStaking(_lockup).deposit(amount);
        emit Staked(amount);
    }

    /**
     * @notice Delegates staked ECOx to a chosen recipient
     * @param who The address to delegate to
     */
    function delegate(address who) external {
        if (msg.sender != beneficiary()) revert Unauthorized();
        _delegate(who);
    }

    /**
     * @notice Delegates staked ECOx to a chosen recipient
     * @param who The address to delegate to
     */
    function _delegate(address who) internal virtual {
        uint256 amount = IERC20Upgradeable(stakedToken).balanceOf(
            address(this)
        );
        if (currentDelegate != address(0)) {
            _undelegate(delegatedAmount);
        }
        IECOxStaking(stakedToken).delegateAmount(who, amount);
        currentDelegate = who;
        delegatedAmount = amount;
    }

    function _undelegate(uint256 amount) internal {
        IECOxStaking(stakedToken).undelegateAmountFromAddress(
            currentDelegate,
            amount
        );
        delegatedAmount -= amount;
    }

    /**
     * @notice Unstakes any lockedup staked ECOx that hasn't already been unstaked
     * @dev this allows users to vote with released tokens while still
     * being able to claim lockedup tokens
     * @return The amount of ECOx unstaked
     */
    function unstake(uint256 amount) external returns (uint256) {
        if (msg.sender != beneficiary()) revert Unauthorized();
        return _unstake(amount);
    }

    /**
     * @notice Unstakes any lockedup staked ECOx that hasn't already been unstaked
     * @dev this allows users to vote with released tokens while still
     * being able to claim lockedup tokens
     * @return The amount of ECOx unstaked
     */
    function _unstake(uint256 amount) internal returns (uint256) {
        uint256 totalStake = IERC20Upgradeable(stakedToken).balanceOf(
            address(this)
        );
        if (amount > totalStake) revert InvalidAmount();
        uint256 undelegatedStake = totalStake - delegatedAmount;
        if (undelegatedStake < amount) {
            _undelegate(amount - undelegatedStake);
        }
        IECOxStaking(stakedToken).withdraw(amount);
        emit Unstaked(amount);
        return amount;
    }

    /**
     * @inheritdoc ClawbackVestingVault
     */
    function clawback() public override onlyOwner {
        uint256 _unstaked = IERC20Upgradeable(stakedToken).balanceOf(
            address(this)
        );
        uint256 _unvested = unvested();
        _unstake(_unstaked < _unvested ? _unstaked : _unvested);
        return super.clawback();
    }

    /**
     * @inheritdoc VestingVault
     */
    function unvested() public view override returns (uint256) {
        return
            IERC20Upgradeable(stakedToken).balanceOf(address(this)) +
            token().balanceOf(address(this)) -
            vested();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

interface IECOx {
    function policy() external returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {VestingVault} from "./VestingVault.sol";
import {ClawbackVestingVault} from "./ClawbackVestingVault.sol";
import {ChunkedVestingVaultArgs} from "./helpers/ChunkedVestingVaultArgs.sol";

/**
 * @notice VestingVault contract for a series of chunked token releases
 * @dev immutable args:
 * - slot 0 - address token (20 bytes) (in VestingVault)
 * - slot 1 - address beneficiary (20 bytes) (in VestingVault)
 * - slot 2 - uint256 vestingPeriods
 * - slot 3-x - uint256[] amounts
 * - slot x-y - uint256[] timestamps
 */
contract ChunkedVestingVault is ClawbackVestingVault, ChunkedVestingVaultArgs {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice The number of vesting chunks used up so far
    uint256 public vestedChunks;

    /**
     * @notice Initializes the vesting vault
     * @dev this is separate from initialize() so an inheritor can
     * override the initializer without breaking the reentrancy protection in
     * `initializer`. for more info read
     * https://github.com/OpenZeppelin/openzeppelin-contracts/commit/553c8fdec708ea10dd5f4a2977364af7a562566f
     * @param admin The address which can clawback unvested tokens
     */
    function initialize(address admin) public virtual initializer {
        _initialize(admin);
    }

    /**
     * @notice Initializes the vesting vault
     * @dev this pulls in the required ERC20 tokens from the sender to setup
     * @param admin The address which can clawback unvested tokens
     */
    function _initialize(address admin) internal onlyInitializing {
        // calculate total amount of tokens over the lifetime of the vault
        (uint256 amount, uint256 chunks) =
            getVestedAmountAndChunks(type(uint256).max);
        if (chunks != vestingPeriods()) {
            revert InvalidParams();
        }

        ClawbackVestingVault.initialize(amount, admin);
    }

    /**
     * @inheritdoc VestingVault
     */
    function vestedOn(uint256 timestamp)
        public
        view
        override
        virtual
        returns (uint256 amount)
    {
        (amount,) = getVestedAmountAndChunks(timestamp);
    }

    /**
     * @inheritdoc VestingVault
     */
    function onClaim(uint256 amount) internal virtual override {
        (uint256 total, uint256 chunks) = getNextChunkForAmount(amount);
        if (total != amount) {
            revert InvalidClaim();
        }
        vestedChunks = chunks;
    }

    /**
     * @notice helper function to get the currently vested amount of tokens
     * and the total number of vesting chunks that have been used so far
     * @param timestamp The time for which vested tokens are being calculated
     * @return amount The amount of tokens currently vested
     * @return chunks The total number of chunks used so far
     */
    function getVestedAmountAndChunks(uint256 timestamp)
        internal
        view
        returns (uint256 amount, uint256 chunks)
    {
        uint256 total;
        for (uint256 i = vestedChunks; i < vestingPeriods(); i++) {
            if (timestamp >= timestampAtIndex(i)) {
                // then we have vested this chunk
                total += amountAtIndex(i);
            } else {
                // return early because we haven't gotten this far in the vesting cycle yet
                return (total, i);
            }
        }
        return (total, vestingPeriods());
    }

    /**
     * @notice helper function to get the next chunk index after the given amount
     * @param amount The amount of tokens to get chunk index for
     * @return total The total amount vested from last vest to the given index
     * @return chunks The total number of chunks used so far
     */
    function getNextChunkForAmount(uint256 amount)
        internal
        view
        returns (uint256 total, uint256 chunks)
    {
        for (uint256 i = vestedChunks; i < vestingPeriods(); i++) {
            total += amountAtIndex(i);
            if (total >= amount) {
                return (total, i + 1);
            }
        }
        return (total, vestingPeriods());
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

interface IECOxStaking {
    function deposit(uint256 _amount) external;

    function delegate(address delegatee) external;

    function delegateAmount(address delegatee, uint256 amount) external;

    function withdraw(uint256 _amount) external;

    function undelegate() external;

    function undelegateAmountFromAddress(address delegatee, uint256 amount)
        external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/introspection/IERC1820Registry.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820RegistryUpgradeable {
    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);

    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(
        address account,
        bytes32 _interfaceHash,
        address implementer
    ) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     * @param account Address of the contract for which to update the cache.
     * @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not.
     * If the result is not cached a direct lookup on the contract address is performed.
     * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     * {updateERC165Cache} with the contract address.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using or updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ReentrancyGuardUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import {OwnableUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {SafeERC20Upgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC20Upgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import {Clone} from "clones-with-immutable-args/Clone.sol";
import {VestingVault} from "./VestingVault.sol";

/**
 * @notice Generic VestingVault contract allowing for an admin to claw back unvested funds
 */
abstract contract ClawbackVestingVault is VestingVault, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event Clawback(uint256 amount);

    uint256 public clawbackTimestamp;

    /**
     * @notice Initializes the vesting vault
     * @param amount The amount of the ERC20 token to vest for the beneficiary in total
     * @param admin The address which can clawback unvested tokens
     * @dev this contract should have been deployed with ClonesWithImmutableArgs in order to
     * properly set up the immutable token and beneficiary args
     */
    function initialize(uint256 amount, address admin)
        internal
        onlyInitializing
    {
        __Ownable_init_unchained();
        _transferOwnership(admin);
        VestingVault.initialize(amount);
    }

    /**
     * @notice return all unvested tokens to the admin
     */
    function clawback() public virtual onlyOwner {
        clawbackTimestamp = block.timestamp;
        uint256 amount = unvested();
        token().safeTransfer(msg.sender, amount);
        emit Clawback(amount);
    }

    /**
     * @inheritdoc VestingVault
     */
    function vested() public view virtual override returns (uint256) {
        uint256 _clawbackTimestamp = clawbackTimestamp;
        if (_clawbackTimestamp != 0) {
            return vestedOn(_clawbackTimestamp);
        } else {
            return vestedOn(block.timestamp);
        }
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * @param newOwner The address to transfer ownership to
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        _transferOwnership(newOwner);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ReentrancyGuardUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import {SafeERC20Upgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC20Upgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import {Clone} from "clones-with-immutable-args/Clone.sol";
import {IVestingVault} from "./interfaces/IVestingVault.sol";

/**
 * @notice Generic VestingVault contract which handles storage and claiming of vesting tokens
 * @dev This contract is meant to be extended with handling for vesting schedules
 * @dev immutable args:
 * - slot 0 - address token (20 bytes)
 * - slot 1 - address beneficiary (20 bytes)
 */
abstract contract VestingVault is
    Clone,
    ReentrancyGuardUpgradeable,
    IVestingVault
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @inheritdoc IVestingVault
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return the token which is being vested
     */
    function token() public pure returns (IERC20Upgradeable) {
        return IERC20Upgradeable(_getArgAddress(0));
    }

    /**
     * @inheritdoc IVestingVault
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The beneficiary address
     */
    function beneficiary() public pure returns (address) {
        return _getArgAddress(20);
    }

    modifier onlyBeneficiary() {
        if (msg.sender != beneficiary()) {
            revert Unauthorized();
        }
        _;
    }

    /**
     * @notice Initializes the vesting vault
     * @param amount The amount of the ERC20 token to vest for the beneficiary in total
     * @dev this contract should have been deployed with ClonesWithImmutableArgs in order to
     * properly set up the immutable token and beneficiary args
     */
    function initialize(uint256 amount) internal virtual onlyInitializing {
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        if (address(token()) == address(0)) {
            revert InvalidParams();
        }
        if (beneficiary() == address(0)) {
            revert InvalidParams();
        }

        IERC20Upgradeable(token()).safeTransferFrom(
            msg.sender, address(this), amount
        );
    }

    /**
     * @inheritdoc IVestingVault
     */
    function claim() external nonReentrant onlyBeneficiary {
        uint256 vestedAmount = vested();
        if (vestedAmount == 0) {
            revert NotVested();
        }

        onClaim(vestedAmount);
        token().safeTransfer(beneficiary(), vestedAmount);
        emit Claimed(beneficiary(), address(token()), vestedAmount);
    }

    /**
     * @inheritdoc IVestingVault
     */
    function vested() public view virtual returns (uint256) {
        return vestedOn(block.timestamp);
    }

    /**
     * @inheritdoc IVestingVault
     */
    function unvested() public view virtual returns (uint256) {
        return token().balanceOf(address(this)) - vested();
    }

    /**
     * @inheritdoc IVestingVault
     */
    function vestedOn(uint256 timestamp)
        public
        view
        virtual
        returns (uint256);

    /**
     * @notice hook for downstream contracts to update vesting schedule based on a claim
     * @param amount The amount of token() which were claimed
     */
    function onClaim(uint256 amount) internal virtual;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Clone} from "clones-with-immutable-args/Clone.sol";

/**
 * @notice helpers for the immutable args
 * stored by ChunkedVestingVault
 */
contract ChunkedVestingVaultArgs is Clone {
    /**
     * @notice The token which is being vested
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return the token which is being vested
     */
    function vestingPeriods() public pure returns (uint256) {
        // starts at 40 because of the parent VestingVault uses bytes 0-39 for token and beneficiary
        return _getArgUint256(40);
    }

    /**
     * @notice The array of chunked amounts to be vested
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return the array of chunked amounts to be vested
     */
    function amounts() public pure returns (uint256[] memory) {
        return _getArgUint256Array(72, uint64(vestingPeriods()));
    }

    /**
     * @notice The array of timestamps at which chunks of tokens are vested
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @dev These are expected to be already sorted in timestamp order
     * @return the timestamps at which chunks of tokens are vested
     */
    function timestamps() public pure returns (uint256[] memory) {
        return _getArgUint256Array(
            72 + (32 * vestingPeriods()), uint64(vestingPeriods())
        );
    }

    /**
     * @notice The amount to be vested at the given index
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return the amount to be vested at the given index
     */
    function amountAtIndex(uint256 index) public pure returns (uint256) {
        return _getArgUint256(72 + (32 * index));
    }

    /**
     * @notice The timestamp at which the given index chunk is vested
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return the timestamp at which the given index chunk is vested
     */
    function timestampAtIndex(uint256 index) public pure returns (uint256) {
        return _getArgUint256(72 + (32 * vestingPeriods()) + (32 * index));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: BSD
pragma solidity ^0.8.4;

/// @title Clone
/// @author zefram.eth
/// @notice Provides helper functions for reading immutable args from calldata
contract Clone {
    /// @notice Reads an immutable arg with type address
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgAddress(uint256 argOffset)
        internal
        pure
        returns (address arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0x60, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint256
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint256(uint256 argOffset)
        internal
        pure
        returns (uint256 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := calldataload(add(offset, argOffset))
        }
    }

    /// @notice Reads a uint256 array stored in the immutable args.
    /// @param argOffset The offset of the arg in the packed data
    /// @param arrLen Number of elements in the array
    /// @return arr The array
    function _getArgUint256Array(uint256 argOffset, uint64 arrLen)
        internal
        pure
      returns (uint256[] memory arr)
    {
      uint256 offset = _getImmutableArgsOffset();
      uint256 el;
      arr = new uint256[](arrLen);
      for (uint64 i = 0; i < arrLen; i++) {
        assembly {
          // solhint-disable-next-line no-inline-assembly
          el := calldataload(add(add(offset, argOffset), mul(i, 32)))
        }
        arr[i] = el;
      }
      return arr;
    }

    /// @notice Reads an immutable arg with type uint64
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint64(uint256 argOffset)
        internal
        pure
        returns (uint64 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xc0, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint8
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint8(uint256 argOffset) internal pure returns (uint8 arg) {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xf8, calldataload(add(offset, argOffset)))
        }
    }

    /// @return offset The offset of the packed immutable args in calldata
    function _getImmutableArgsOffset() internal pure returns (uint256 offset) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            offset := sub(
                calldatasize(),
                add(shr(240, calldataload(sub(calldatasize(), 2))), 2)
            )
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ReentrancyGuardUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import {SafeERC20Upgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC20Upgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import {Clone} from "clones-with-immutable-args/Clone.sol";

/**
 * @notice Interface for VestingVault contracts
 */
interface IVestingVault {
    event Claimed(address beneficiary, address token, uint256 amount);

    /// @notice Some parameters are invalid
    error InvalidParams();

    /// @notice A function is called by an unauthorized participant
    error Unauthorized();

    /// @notice No tokens are currently vested
    error NotVested();

    /// @notice attempts to claim an invalid amount
    error InvalidClaim();

    /**
     * @notice The token which is being vested
     */
    function token() external pure returns (IERC20Upgradeable);

    /**
     * @notice The address who the tokens are being vested to
     */
    function beneficiary() external pure returns (address);

    /**
     * @notice Claims any currently vested tokens to the beneficiary
     */
    function claim() external;

    /**
     * @notice Returns the amount of tokens that are currently vested
     * @return amount of tokens that are currently vested
     */
    function vested() external view returns (uint256);

    /**
     * @notice Returns the amount of tokens that are currently unvested
     * @return amount of tokens that the are currently unvested
     */
    function unvested() external view returns (uint256);

    /**
     * @notice Returns the amount of tokens that the beneficiary will have vested by the given timestamp
     * @param timestamp The timestamp to check vested amount on
     * @return amount of tokens that the beneficiary will have vested
     */
    function vestedOn(uint256 timestamp) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}