// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';

import {IYieldToken} from '../../interfaces/core/IYieldToken.sol';
import {VaultShareManager} from './VaultShareManager.sol';
import {VaultStrategyManager} from './VaultStrategyManager.sol';

import {IDetailedERC20} from '../../interfaces/IDetailedERC20.sol';
import {ICommonHealthCheck} from '../../interfaces/periphery/ICommonHealthCheck.sol';
import {IVault} from '../../interfaces/core/Vault/IVault.sol';

/**
    *  @title Yearn Token Vault
    * @author yearn.finance
    * @notice
    Yearn Token Vault. Holds an underlying token, and allows users to interact
    with the Yearn ecosystem through Strategies connected to the Vault.
    Vaults are not limited to a single Strategy, they can have as many Strategies
    as can be designed (however the withdrawal queue is capped at 20.)

    Deposited funds are moved into the most impactful strategy that has not
    already reached its limit for assets under management, regardless of which
    Strategy a user's funds end up in, they receive their portion of yields
    generated across all Strategies.

    When a user withdraws, if there are no funds sitting undeployed in the
    Vault, the Vault withdraws funds from Strategies in the order of least
    impact. (Funds are taken from the Strategy that will disturb everyone's
    gains the least, then the next least, etc.) In order to achieve this, the
    withdrawal queue's order must be properly set and managed by the community
    (through governance).

    Vault Strategies are parameterized to pursue the highest risk-adjusted yield.

    There is an "Emergency Shutdown" mode. When the Vault is put into emergency
    shutdown, assets will be recalled from the Strategies as quickly as is
    practical (given on-chain conditions), minimizing loss. Deposits are
    halted, new Strategies may not be added, and each Strategy exits with the
    minimum possible damage to position, while opening up deposits to be
    withdrawn by users. There are no restrictions on withdrawals above what is
    expected under Normal Operation.

    For further details, please refer to the specification:
    https://github.com/iearn-finance/yearn-vaults/blob/main/SPECIFICATION.md
 */
contract Vault is IVault, VaultShareManager, VaultStrategyManager {
  using SafeERC20 for IERC20;

  // end of Events

  // Storage

  // `nonces` track `permit` approvals with signature.

  // end of Storage
  /***
    @notice
        Initializes the Vault, this is called only once, when the contract is
        deployed.
        The performance fee is set to 10% of yield, per Strategy.
        The management fee is set to 2%, per year.
        The initial deposit limit is set to 0 (deposits disabled); it must be
        updated after initialization.
    @dev
        If `nameOverride` is not specified, the name will be 'yearn'
        combined with the name of `token`.

        If `symbolOverride` is not specified, the symbol will be 'yv'
        combined with the symbol of `token`.

        The token used by the vault should not change balances outside transfers and
        it must transfer the exact amount requested. Fee on transfer and rebasing are not supported.
    @param yieldToken, The yield token that this Vault will use, it represent ownership in the vault.
    @param token The token that may be deposited into this Vault.
    @param governance The address authorized for governance interactions.
    @param rewards The address to distribute rewards to.
    @param management The address of the vault manager.
    @param nameOverride Specify a custom Vault name. Leave empty for default choice.
    @param symbolOverride Specify a custom Vault symbol name. Leave empty for default choice.
    @param guardian The address authorized for guardian interactions. Defaults to caller.
    **/
  function initialize(VaultInitializeParameters calldata _initParams) external initializer {
    yieldToken = _initParams._yieldToken;
    token = _initParams._token;

    {
      // block scope to avoid stack too deep errors
      bytes32 emptyString = keccak256(abi.encodePacked(''));
      string memory tokenSymbol = IDetailedERC20(_initParams._token).symbol();

      if (keccak256(abi.encodePacked(_initParams._nameOverride)) == emptyString) {
        // Maybe check length instead.
        name = string(abi.encodePacked(tokenSymbol, ' yVault'));
      } else {
        name = _initParams._nameOverride;
      }
      if (keccak256(abi.encodePacked(_initParams._symbolOverride)) == emptyString) {
        symbol = string(abi.encodePacked('yv', tokenSymbol));
      } else {
        symbol = _initParams._symbolOverride;
      }
    }

    rewardsRecipient = _initParams._rewardsRecipient;

    performanceFee = 1000; // 10% of yield (per Strategy) // TODO Remove

    // managementFee = 200; // 2% per year

    healthCheck = _initParams._healthCheck;

    lastReport = block.timestamp;
    __VaultAccessControl_init(_initParams._governance, _initParams._guardian, _initParams._management);

    // TODO
    // EIP-712
    // DOMAIN_SEPARATOR = keccak256(
    //   abi.encodePacked(
    //     DOMAIN_TYPE_HASH,
    //     keccak256('Yearn Vault'),
    //     keccak256(abi.encode(API_VERSION)),
    //     bytes32(block.chainid),
    //     bytes32(uint256(uint160(address(this))))
    //   )
    // );

    VaultParameters memory _vaultParameters = VaultParameters(
      _initParams._yieldToken,
      _initParams._token,
      _initParams._governance,
      _initParams._rewardsRecipient,
      _initParams._nameOverride,
      _initParams._symbolOverride,
      _initParams._guardian,
      _initParams._management,
      _initParams._healthCheck,
      performanceFee,
      lastReport
    );
    emit VaultInitialized(_vaultParameters);
  }

  function sweep(address _token) external onlyRole(GOVERNANCE) returns (uint256 _amount) {
    /**
    @notice
        Removes tokens from this Vault that are not the type of token managed
        by this Vault. This may be used if the wrong kind of token was sent to
        this vault.

        If the token being swept is the token being managed by this vault, only
        tokens in excess of the amount managed by this vault will be swept.

        Sweep will always sweep the entire balance that is in excess.

        Tokens will be sent to `governance`.

        This may only be called by governance.
    @param _token The token to transfer out of this vault.
    @return _amount The amount of tokens transferred out of the vault.
    */
    if (_token == token) {
      _amount = IERC20(_token).balanceOf(address(this)) - totalIdle;
      if (_amount == 0) revert NoDust();
    } else {
      _amount = IERC20(_token).balanceOf(address(this));
    }
    IERC20(_token).safeTransfer(msg.sender, _amount);
    emit Sweep(_token, _amount);
  }

  // // TODO might change on withdrawal queue deprecation
  // function maxAvailableShares() external view returns (uint256) {
  //   /**
  //       @notice
  //           Determines the maximum quantity of shares this Vault can facilitate a
  //           withdrawal for, factoring in assets currently residing in the Vault,
  //           as well as those deployed to strategies on the Vault's balance sheet.
  //       @dev
  //           Regarding how shares are calculated, see dev note on `deposit`.

  //           If you want to calculated the maximum a user could withdraw up to,
  //           you want to use this function.

  //           Note that the amount provided by this function is the theoretical
  //           maximum possible from withdrawing, the real amount depends on the
  //           realized losses incurred during withdrawal.
  //       @return The total quantity of shares this Vault can provide.
  //       */
  //   uint256 shares = _sharesForAmount(totalIdle);

  //   for (uint256 i = 0; i < MAXIMUM_STRATEGIES; i++) {
  //     if (withdrawalQueue[i] == address(0x0)) {
  //       break;
  //     }
  //     shares += _sharesForAmount(_strategies[withdrawalQueue[i]].totalDebt);
  //   }
  //   return shares;
  // }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4 <0.9.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';

interface IYieldToken is IERC20Upgradeable {
  struct YieldTokenInitializeParameters {
    string _name;
    string _symbol;
    address _underlyingToken;
    address _vault;
    address _masterAdmin;
  }

  error NotVault();

  error AlreadyMigrated();

  error SameVault();

  event YieldTokenInitialized(string name, string symbol, address underlyingToken, address vault);

  event MigrateVault(address indexed oldVault, address indexed newVault);

  event Sweep(address indexed token, uint256 amount);

  event TransferOwnership(address indexed oldVault, address indexed newVault);

  function initialize(YieldTokenInitializeParameters calldata _initParams) external;

  function MASTER_ADMIN() external view returns (bytes32 _masterAdmin);

  function VAULT_MIGRATOR() external view returns (bytes32 _vaultMigrator);

  function VAULT_MIGRATOR_ADMIN() external view returns (bytes32 _vaultMigratorAdmin);

  function vault() external view returns (address _vault);

  function underlyingToken() external view returns (address _underlyingToken);

  function mint(address _account, uint256 _amount) external;

  function burn(address _from, uint256 _amount) external;

  function transferOwnership(address _newVault) external;

  function migrateVault(address _newVault) external;

  function sweep(address _token) external returns (uint256 _amount);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4 <0.9.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';

import {IYieldToken} from '../../interfaces/core/IYieldToken.sol';
import {VaultParameters} from './VaultParameters.sol';

import {IBaseStrategy} from '../../interfaces/core/IBaseStrategy.sol';
import {IWithdrawalQueue} from '../../interfaces/periphery/IWithdrawalQueue.sol';
import {IDetailedERC20} from '../../interfaces/IDetailedERC20.sol';
import {IVaultShareManager} from '../../interfaces/core/Vault/IVaultShareManager.sol';

abstract contract VaultShareManager is
  IVaultShareManager,
  // VaultAccessControl,
  VaultParameters
{
  using SafeERC20 for IERC20;

  function pricePerShare() external view returns (uint256) {
    /**
    @notice Gives the price for a single Vault share.
    @dev See dev note on `withdraw`.
    @return The value of a single share.
     */
    return _shareValue(10**IDetailedERC20(token).decimals());
  }

  function totalAssets() external view returns (uint256) {
    /**
    @notice
        Returns the total quantity of all assets under control of this
        Vault, whether they're loaned out to a Strategy, or currently held in
        the Vault.
    @return The total assets under control of this Vault.
     */
    return _totalAssets();
  }

  function _sharesForAmount(uint256 _amount) internal view returns (uint256) {
    // Determines how many shares `_amount` of token would receive.
    // See dev note on `deposit`.
    uint256 totalFundsMinusProfitLock = _totalFundsMinusProfitLock();
    if (totalFundsMinusProfitLock > 0) {
      // NOTE: if sqrt(token.totalSupply()) > 1e37, this could potentially revert
      return ((_amount * IYieldToken(yieldToken).totalSupply()) / totalFundsMinusProfitLock);
    } else {
      // TODO I find this path unnecessary. when would this happen?
      return 0;
    }
  }

  function _shareValue(uint256 _shares) internal view returns (uint256) {
    // Returns price = 1:1 if vault is empty
    if (IYieldToken(yieldToken).totalSupply() == 0) {
      return _shares;
    }
    // Determines the current value of `_shares`.
    // NOTE: if sqrt(Vault.totalAssets()) >>> 1e39, this could potentially revert
    return ((_shares * _totalFundsMinusProfitLock()) / IYieldToken(yieldToken).totalSupply());
  }

  function _totalFundsMinusProfitLock() internal view returns (uint256) {
    return _totalAssets() - _calculateLockedProfit();
  }

  function _calculateLockedProfit() internal view returns (uint256) {
    /*
    @notice
        Returns time adjusted locked profits depending on the current time delta and
        the previous harvest time delta.
    @return The time adjusted locked profits due to pps increase spread
    */
    uint256 currentTimeDelta = block.timestamp - lastReport;

    if (currentTimeDelta < previousHarvestTimeDelta) {
      return lockedProfit - ((lockedProfit * currentTimeDelta) / previousHarvestTimeDelta);
    } else {
      return 0;
    }
  }

  function _issueSharesForAmount(address _to, uint256 _amount) internal returns (uint256) {
    // Issues `amount` Vault shares to `to`.
    // Shares must be issued prior to taking on new collateral, or
    // calculation will be wrong. This means that only *trusted* tokens
    // (with no capability for exploitative behavior) can be used.
    uint256 shares = 0;
    // HACK: Saves 2 SLOADs (~200 gas, post-Berlin)
    uint256 _totalSupply = IYieldToken(yieldToken).totalSupply();
    if (_totalSupply > 0) {
      // Mint amount of shares based on what the Vault is managing overall
      // NOTE: if sqrt(token.totalSupply()) > 1e39, this could potentially revert
      shares = (_amount * _totalSupply) / _totalFundsMinusProfitLock(); // dev: no free funds
    } else {
      // No existing shares, so mint 1:1
      shares = _amount;
    }
    assert(shares != 0); // dev: division rounding resulted in zero

    // Mint new shares
    IYieldToken(yieldToken).mint(_to, shares);
    return shares;
  }

  // Asset accounting
  function _totalAssets() internal view returns (uint256) {
    // See note on `totalAssets()`.
    return totalIdle + totalDebt;
  }

  //TODO: @nonreentrant("withdraw")
  function withdraw(
    uint256 _maxShares,
    address _recipient,
    address[] memory _withdrawableStrategies
  ) public returns (uint256 _tokenAmount) {
    /**
    @notice
        Withdraws the calling account's tokens from this Vault, redeeming
        amount `_shares` for an appropriate amount of tokens.

        See note on `setWithdrawalQueue` for further details of withdrawal
        ordering and behavior.
    @dev
        Measuring the value of shares is based on the total outstanding debt
        that this contract has ("expected value") instead of the total balance
        sheet it has ("estimated value") has important security considerations,
        and is done intentionally. If this value were measured against external
        systems, it could be purposely manipulated by an attacker to withdraw
        more assets than they otherwise should be able to claim by redeeming
        their shares.

        On withdrawal, this means that shares are redeemed against the total
        amount that the deposited capital had "realized" since the point it
        was deposited, up until the point it was withdrawn. If that number
        were to be higher than the "expected value" at some future point,
        withdrawing shares via this method could entitle the depositor to
        *more* than the expected value once the "realized value" is updated
        from further reports by the Strategies to the Vaults.

        Under exceptional scenarios, this could cause earlier withdrawals to
        earn "more" of the underlying assets than Users might otherwise be
        entitled to, if the Vault's estimated value were otherwise measured
        through external means, accounting for whatever exceptional scenarios
        exist for the Vault (that aren't covered by the Vault's own design.)

        In the situation where a large withdrawal happens, it can empty the
        vault balance and the strategies in the withdrawal queue.
        Strategies not in the withdrawal queue will have to be harvested to
        rebalance the funds and make the funds available again to withdraw.
    @param _maxShares
        How many shares to try and redeem for tokens, defaults to all.
    @param _recipient
        The address to issue the shares in this Vault to. Defaults to the
        caller's address.
    @return The quantity of tokens redeemed for `_shares`.
     */
    uint256 shares = _maxShares; // May reduce this number below

    // If _shares not specified, transfer full share balance
    if (shares == type(uint256).max) {
      shares = IERC20(yieldToken).balanceOf(msg.sender);
    } else {
      // Limit to only the shares they own
      if (shares > IERC20(yieldToken).balanceOf(msg.sender)) revert SharesExceedSenderYieldTokenBalance();
    }

    // Ensure we are withdrawing something
    if (shares == 0) revert ZeroAmount();

    // See @dev note, above.
    _tokenAmount = _shareValue(shares);

    // memory load to save gas
    uint256 newTotalIdle = totalIdle;
    uint256 newTotalDebt = totalDebt;

    if (_tokenAmount > newTotalIdle) {
      // We need to go get some from our strategies in the specified queue
      // NOTE: This performs withdrawals from each Strategy.

      // Moved outside for gas efficiency
      uint256 amountNeeded = _tokenAmount - newTotalIdle;
      uint256 amountToWithdraw;
      address _strategy;
      for (uint256 i = 0; i < _withdrawableStrategies.length; i++) {
        _strategy = _withdrawableStrategies[i];
        if (_strategies[_strategy].activation == 0) revert InvalidStrategy();

        amountToWithdraw = Math.min(amountNeeded, IBaseStrategy(_strategy).withdrawable());
        if (amountToWithdraw == 0) {
          continue; // Nothing to withdraw from this Strategy, try the next one
        }
        // NOTE Withdrawing without accounting for profits can lead to innacurate (high) APY reporting on the strategy.
        // i.e. strategy holds 100k, makes 1k profit (1%), user withdraws 90k, strategy reports 1k profit on 10k debt (10%).
        // This should not affect anything besides offchain metrics.
        IBaseStrategy(_strategy).freeFunds(amountToWithdraw);
        IERC20(token).transferFrom(_strategy, address(this), amountToWithdraw);
        newTotalIdle += amountToWithdraw;
        newTotalDebt -= amountToWithdraw;
        _strategies[_strategy].totalDebt -= amountToWithdraw;

        if (_tokenAmount <= newTotalIdle) {
          break; // We're done withdrawing
        }
        // else, we update amount needed and go to next strategy in the queue
        amountNeeded -= amountToWithdraw;
      }
      // NOTE: We have withdrawn everything possible out of the withdrawal queue
      //       but we still don't have enough to fully pay them back, so we revert
      if (_tokenAmount > newTotalIdle) revert NotEnoughIdleTokens();
    }
    // Burn shares (full value of what is being withdrawn)
    IYieldToken(yieldToken).burn(msg.sender, shares);

    // save memory into storage (already updated)
    totalIdle = newTotalIdle - _tokenAmount;
    totalDebt = newTotalDebt;
    IERC20(token).safeTransfer(_recipient, _tokenAmount);

    emit Withdraw(_recipient, shares, _tokenAmount);

    return _tokenAmount;
  }

  function availableDepositLimit() external view returns (uint256) {
    if (depositLimit > _totalAssets()) {
      return depositLimit - _totalAssets();
    } else {
      return 0;
    }
  }

  function deposit() external returns (uint256 _shares) {
    return deposit(type(uint256).max, msg.sender);
  }

  function deposit(uint256 _amount) external returns (uint256 _shares) {
    return deposit(_amount, msg.sender);
  }

  // TODO: nonreentrant("withdraw")
  function deposit(uint256 _amount, address _recipient) public returns (uint256 _shares) {
    /**
    @notice
        Deposits `_amount` `token`, issuing shares to `recipient`. If the
        Vault is in Emergency Shutdown, deposits will not be accepted and this
        call will fail.
    @dev
        Measuring quantity of shares to issues is based on the total
        outstanding debt that this contract has ("expected value") instead
        of the total balance sheet it has ("estimated value") has important
        security considerations, and is done intentionally. If this value were
        measured against external systems, it could be purposely manipulated by
        an attacker to withdraw more assets than they otherwise should be able
        to claim by redeeming their shares.

        On deposit, this means that shares are issued against the total amount
        that the deposited capital can be given in service of the debt that
        Strategies assume. If that number were to be lower than the "expected
        value" at some future point, depositing shares via this method could
        entitle the depositor to *less* than the deposited value once the
        "realized value" is updated from further reports by the Strategies
        to the Vaults.

        Care should be taken by integrators to account for this discrepancy,
        by using the view-only methods of this contract (both off-chain and
        on-chain) to determine if depositing into the Vault is a "good idea".
    @param _amount The quantity of tokens to deposit, defaults to all.
    @param _recipient
        The address to issue the shares in this Vault to. Defaults to the
        caller's address.
    @return The issued Vault shares.
    */
    if (emergencyShutdown) revert NoDepositOnEmergencyShutdown();
    if (_recipient == address(this) || _recipient == address(0x0)) revert InvalidRecipient();
    uint256 amount = _amount;

    // If _amount not specified, transfer the full token balance,
    // up to deposit limit
    if (amount == type(uint256).max) {
      amount = Math.min(
        depositLimit - _totalAssets(),
        Math.min(IERC20(token).allowance(msg.sender, address(this)), IERC20(token).balanceOf(msg.sender))
      );
    } else {
      if (_totalAssets() + amount > depositLimit) revert ExceededDepositAmount();
    }
    // Ensure we are depositing something
    if (amount == 0) revert ZeroAmount();
    // Issue new shares (needs to be done before taking deposit to be accurate)
    // Shares are issued to _recipient (may be different from msg.sender)
    // See @dev note, above.
    _shares = _issueSharesForAmount(_recipient, amount);

    // Tokens are transferred from msg.sender (may be different from _recipient)
    IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    totalIdle += amount;

    emit Deposit(_recipient, _shares, amount);

    return _shares; // Just in case someone wants them
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4 <0.9.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';

import {VaultParameters} from './VaultParameters.sol';
import {VaultAccessControl} from './VaultAccessControl.sol';
import {VaultShareManager} from './VaultShareManager.sol';
import {IDebtAllocator} from '../../interfaces/periphery/IDebtAllocator.sol';
import {IFeeManager} from '../../interfaces/periphery/IFeeManager.sol';
import {IBaseStrategy} from '../../interfaces/core/IBaseStrategy.sol';
import {ICommonHealthCheck} from '../../interfaces/periphery/ICommonHealthCheck.sol';
import {IVaultStrategyManager} from '../../interfaces/core/Vault/IVaultStrategyManager.sol';

abstract contract VaultStrategyManager is IVaultStrategyManager, VaultParameters, VaultShareManager {
  using SafeERC20 for IERC20;

  function addStrategy(address _strategy) external onlyRole(STRATEGY_MANAGER) {
    // Check calling conditions
    if (emergencyShutdown) revert StrategyShutdown();

    // Check strategy configuration
    if (_strategy == address(0x0)) revert ZeroAddress();
    if (_strategies[_strategy].activation != 0) revert InvalidStrategy();
    if (address(this) != IBaseStrategy(_strategy).vault()) revert InvalidVault();
    if (address(token) != IBaseStrategy(_strategy).want()) revert InvalidWantToken();

    // Add strategy to approved strategies
    _strategies[_strategy] = StrategyParams({
      activation: block.timestamp,
      lastReport: block.timestamp,
      totalDebt: 0,
      totalGain: 0,
      totalLoss: 0
    });
    emit StrategyAdded(_strategy);
  }

  function migrateStrategy(address _oldVersion, address _newVersion) external onlyRole(STRATEGY_MANAGER) {
    /**
    @notice
        Migrates a Strategy, including all assets from `oldVersion` to
        `newVersion`.

        This may only be called by governance.
    @dev
        Strategy must successfully migrate all capital and positions to new
        Strategy, or else this will upset the balance of the Vault.

        The new Strategy should be "empty" e.g. have no prior commitments to
        this Vault, otherwise it could have issues.
    @param _oldVersion The existing Strategy to migrate from.
    @param _newVersion The new Strategy to migrate to.
    */
    if (_newVersion == address(0x0)) revert ZeroAddress();
    if (_strategies[_oldVersion].activation == 0 || _strategies[_newVersion].activation != 0) {
      revert InvalidStrategy();
    }

    StrategyParams memory strategy = _strategies[_oldVersion];

    _revokeStrategy(_oldVersion);
    // Debt is migrated to new strategy
    _strategies[_oldVersion].totalDebt = 0;

    _strategies[_newVersion] = StrategyParams({
      activation: strategy.lastReport, // NOTE: use last report for activation time, so E[R] calc works
      lastReport: strategy.lastReport,
      totalDebt: strategy.totalDebt,
      totalGain: 0,
      totalLoss: 0
    });

    IBaseStrategy(_oldVersion).migrate(_newVersion);
    emit StrategyMigrated(_oldVersion, _newVersion);
  }

  function revokeStrategy() external override {
    revokeStrategy(msg.sender);
  }

  function revokeStrategy(address _strategy) public onlyRole(STRATEGY_MANAGER) {
    /**
    @notice
        Revoke a Strategy, setting its debt limit to 0 and preventing any
        future deposits.

        This function should only be used in the scenario where the Strategy is
        being retired but no migration of the positions are possible, or in the
        extreme scenario that the Strategy needs to be put into "Emergency Exit"
        mode in order for it to exit as quickly as possible. The latter scenario
        could be for any reason that is considered "critical" that the Strategy
        exits its position as fast as possible, such as a sudden change in market
        conditions leading to losses, or an imminent failure in an external
        dependency.

        This may only be called by governance, the guardian, or the Strategy
        it Note that a Strategy will only revoke itself. during emergency
        shutdown.
    @param _strategy The Strategy to revoke.
     */
    // NOTE: Revoking a strategy will leave the debt behind !!
    _updateDebtEmergency(_strategy);
    _revokeStrategy(_strategy);
  }

  function _revokeStrategy(address _strategy) internal {
    // TODO: test this
    totalDebt -= _strategies[_strategy].totalDebt;
    // NOTE: this will make the vault forget about this strategy (which means could be readded later)
    delete _strategies[_strategy];
    emit StrategyRevoked(_strategy);
  }

  function updateDebtEmergency(address _strategy) external onlyRole(DEBT_OPERATOR) returns (uint256 _newDebt) {
    // TODO: should this be for GOVERNANCE / GUARDIAN / other more powerful rol?
    return _updateDebtEmergency(_strategy);
  }

  function _updateDebtEmergency(address _strategy) internal returns (uint256 _newDebt) {
    // TODO: add tests for this
    uint256 _currentDebt = _strategies[_strategy].totalDebt;
    // NOTE: this means the strategy will try everything to withdraw from the underlying protocol. This includes paying withdrawal fees / unlocking fees / leaving rewards behind / selling at bad prices / ... or any other actions that should only be done under an emergency
    IBaseStrategy(_strategy).emergencyFreeFunds(_currentDebt);
    uint256 availableFundsInStrategy = IERC20(token).balanceOf(_strategy);
    IERC20(token).transferFrom(_strategy, address(this), availableFundsInStrategy);
    _newDebt = _currentDebt - availableFundsInStrategy;
    totalIdle += availableFundsInStrategy;
    totalDebt -= availableFundsInStrategy;
    _strategies[_strategy].totalDebt = _newDebt;
    emit DebtUpdated(_strategy, _currentDebt, _newDebt);
  }

  function updateDebt(address _strategy) external onlyRole(DEBT_OPERATOR) returns (uint256 _newDebt) {
    // TODO should take emergencyShutdown into account if assigning more debt?

    if (_strategies[_strategy].activation == 0) revert InvalidStrategy();

    // check current strategy debt
    uint256 _currentDebt = _strategies[_strategy].totalDebt;

    (uint256 _minDesiredDebt, uint256 _maxDesiredDebt) = IBaseStrategy(_strategy).investable();

    address _debtAllocator = debtAllocator;
    // NOTE: if debt allocator is set to 0, the vault will always try to recover all funds from strategies
    // as _newDebt will be implicitely set to 0
    if (_debtAllocator != address(0x0)) {
      _newDebt = IDebtAllocator(_debtAllocator).maxDebt(_strategy);
    }
    // check desired/max/target debt with strategy: maxDebt(address strategy) will be implemented in DebtAllocator
    // NOTE: only applies if debt is growing. If we are reducing debt, we don't care what the strategy thinks
    if (_newDebt < _minDesiredDebt && _newDebt > _currentDebt) revert LessThanMinDebt();

    if (_newDebt > _maxDesiredDebt) _newDebt = _maxDesiredDebt;

    if (_currentDebt == _newDebt) revert SameDebt();

    // if current > target:
    if (_currentDebt > _newDebt) {
      uint256 _amountToWithdraw = _currentDebt - _newDebt;
      // check withdrawable amount
      uint256 _withdrawable = IBaseStrategy(_strategy).withdrawable();
      if (_withdrawable == 0) revert NothingToWithdraw();
      // if the strategy does not have enough to withdraw, only recude _newDebt by new amount to withdraw
      if (_withdrawable < _amountToWithdraw) {
        _amountToWithdraw = _withdrawable;
        _newDebt = _currentDebt - _amountToWithdraw;
      }
      // call withdraw and recover funds
      IBaseStrategy(_strategy).freeFunds(_amountToWithdraw);
      IERC20(token).transferFrom(_strategy, address(this), _amountToWithdraw);
      totalIdle += _amountToWithdraw;
      totalDebt -= _amountToWithdraw;
    } else {
      // if target > current:
      uint256 _amountToTransfer = _newDebt - _currentDebt;
      if (_amountToTransfer > totalIdle) {
        _amountToTransfer = totalIdle;
        _newDebt = _currentDebt + _amountToTransfer;
      }
      // send funds to strategy
      IERC20(token).transfer(_strategy, _amountToTransfer);
      totalIdle -= _amountToTransfer;
      totalDebt += _amountToTransfer;
    }
    _strategies[_strategy].totalDebt = _newDebt;

    emit DebtUpdated(_strategy, _currentDebt, _newDebt);
  }

  function processStrategyReport(address _strategy) public override onlyRole(STRATEGY_REPORTER) returns (uint256 _gain, uint256 _loss) {
    // Only approved strategies
    if (_strategies[_strategy].activation == 0) revert InvalidStrategy();

    // TODO Do report/profits need to be tied to obtaining the profit (+debt) back?
    //    ^ This creates an attack vector in which a bad strategy can report extreme profits and mis-inflate pps
    uint256 _strategyTotalAssets = IBaseStrategy(_strategy).totalAssets();
    //   get strategy’s totalDebt
    uint256 _totalDebt = _strategies[_strategy].totalDebt;
    //   if totalAssets > totalDebt:
    if (_strategyTotalAssets == _totalDebt) {
      revert NoChangeInDebt();
    } else if (_strategyTotalAssets > _totalDebt) {
      _gain = _strategyTotalAssets - _totalDebt;
    } else if (_strategyTotalAssets < _totalDebt) {
      _loss = _totalDebt - _strategyTotalAssets;
    }

    address _healthCheck = healthCheck;
    // Check report is within healthy ranges
    if (_healthCheck != address(0x0) && !ICommonHealthCheck(_healthCheck).check(_strategy, _gain, _loss, _totalDebt))
      revert UnhealthyStrategy(_strategy, _gain, _loss, _totalDebt);

    // We have a loss to report, do it before the rest of the calculations
    if (_loss > 0) {
      _strategies[_strategy].totalLoss += _loss;
      _strategies[_strategy].totalDebt = _totalDebt - _loss;
      totalDebt -= _loss;

      // Profit is locked and gradually released per block
      // NOTE: compute current locked profit and replace with sum of current and new
      uint256 lockedProfitBeforeLoss = _calculateLockedProfit();
      if (lockedProfitBeforeLoss > _loss) {
        lockedProfit = lockedProfitBeforeLoss - _loss;
      } else {
        lockedProfit = 0;
      }
    }

    uint256 totalFees;
    if (_gain > 0) {
      // Assess both management fee and performance fee, and issue both as shares of the vault
      address _feeManager = feeManager;
      // NOTE: if feeManager is not set, fees are 0
      if (_feeManager != address(0x0)) {
        totalFees = IFeeManager(_feeManager).assessFees(_strategy, _gain);
        // TODO: should we leave freedom to the feeManager smart module ?
        if (totalFees > _gain) {
          totalFees = _gain;
        }
        // NOTE: feeManager needs to handle the right distribution of fees
        _issueSharesForAmount(_feeManager, totalFees);
      }
      // Returns are always "realized gains"
      _strategies[_strategy].totalGain += _gain;
      _strategies[_strategy].totalDebt += _gain;
      totalDebt += _gain;
      lockedProfit = _calculateLockedProfit() + _gain - totalFees;
    }

    // Update reporting time
    _strategies[_strategy].lastReport = block.timestamp;
    _updateReportTimestamps();

    emit StrategyReported(
      _strategy,
      _gain,
      _loss,
      _strategies[_strategy].totalGain,
      _strategies[_strategy].totalLoss,
      _strategies[_strategy].totalDebt,
      totalFees
    );
  }

  function processStrategyReportForced(
    address _strategy,
    uint256 _expectedGain,
    uint256 _expectedLoss
  ) external override onlyRole(STRATEGY_REPORTER) {
    address _healthCheck = healthCheck;
    delete healthCheck;
    (uint256 _gain, uint256 _loss) = processStrategyReport(_strategy);
    if (_expectedGain != _gain || _expectedLoss != _loss) revert InvalidReport(_expectedGain, _gain, _expectedLoss, _loss);
    healthCheck = _healthCheck;
  }

  function _updateReportTimestamps() internal {
    // maintains longer (fairer) harvest periods on close timed harvests
    // NOTE: correctly adjust time delta to avoid reducing locked-until time
    //       all following examples have previousHarvestTimeDelta = 10 set at h2 and used on h3
    //       if new time delta reduces previous locked-until, keep locked-until and adjust remaining time
    //       h1 = t0, h2 = t10 and h3 = t13 =>
    //           currentTimeDelta = 3, (new)previousHarvestTimeDelta = 7 (10-3), locked until t20
    //       h1 = t0, h2 = t10 and h3 = t14 =>
    //           currentTimeDelta = 4, (new)previousHarvestTimeDelta = 6 (10-4), locked until t20
    //       on 2nd example: h2 is getting carried into h3 (minus time delta 4) since it was previously trying to reach t20.
    //       so it continues to spread the lock up to that point, and thus avoids reducing the previous distribution time.
    //
    //       if locked-until is unchanged, to avoid extra storage read and subtraction cost [behaves as examples below]
    //       h1 = t0, h2 = t10 and h3 = t15 =>
    //           currentTimeDelta = 5, (new)previousHarvestTimeDelta = 5 locked until t20
    //
    //       if next total time delta is higher than previous period remaining, locked-until will increase
    //       h1 = t0, h2 = t10 and h3 = t16 =>
    //           currentTimeDelta = 6, (new)previousHarvestTimeDelta = 6 locked until t22
    //       h1 = t0, h2 = t10 and h3 = t17 =>
    //           currentTimeDelta = 7, (new)previousHarvestTimeDelta = 7 locked until t24
    //
    //       currentTimeDelta is the time delta between now and lastReport.
    //       previousHarvestTimeDelta is the time delta between lastReport and the previous lastReport
    //       previousHarvestTimeDelta is assigned the higher value between currentTimeDelta and (previousHarvestTimeDelta - currentTimeDelta)

    // TODO check how to solve deposit sniping for very profitable and unfrequend strategy reports
    // when there are also other more frequent strategies reducing time delta.
    // (need to add time delta per strategy + accumulator)
    uint256 currentTimeDelta = block.timestamp - lastReport;
    if (previousHarvestTimeDelta > currentTimeDelta * 2) {
      previousHarvestTimeDelta = previousHarvestTimeDelta - currentTimeDelta;
    } else {
      previousHarvestTimeDelta = currentTimeDelta;
    }
    lastReport = block.timestamp;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4 <0.9.0;

interface IDetailedERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4 <0.9.0;

interface ICommonHealthCheck {
  function check(
    address _strategy,
    uint256 _gain,
    uint256 _loss,
    uint256 _totalDebt
  ) external view returns (bool);

  function doHealthCheck(address) external view returns (bool);

  function enableCheck(address) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface IVault {
  struct VaultInitializeParameters {
    address _yieldToken;
    address _token;
    address _governance;
    address _rewardsRecipient;
    string _nameOverride;
    string _symbolOverride;
    address _guardian;
    address _management;
    address _healthCheck;
  }

  struct VaultParameters {
    address yieldToken;
    address token;
    address governance;
    address rewardsRecipient;
    string nameOverride;
    string symbolOverride;
    address guardian;
    address management;
    address healthCheck;
    uint256 performanceFee;
    uint256 lastReport;
  }

  error NoDust();

  event Sweep(address indexed token, uint256 amount);

  event VaultInitialized(VaultParameters _vaultParameters);

  function initialize(VaultInitializeParameters calldata _vaultInitializeParameters) external;

  function sweep(address _token) external returns (uint256 _amount);
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4 <0.9.0;

import {VaultAccessControl} from './VaultAccessControl.sol';
import {IVaultStrategyManager} from '../../interfaces/core/Vault/IVaultStrategyManager.sol';
import {IYieldToken} from '../../interfaces/core/IYieldToken.sol';
import {IVaultParameters} from '../../interfaces/core/Vault/IVaultParameters.sol';

abstract contract VaultParameters is IVaultParameters, VaultAccessControl {
  string public constant API_VERSION = '0.5.0';

  uint256 public constant MAX_BPS = 10_000; // 100%, or 10k basis points

  uint256 public depositLimit; // Limit for totalAssets the Vault can hold
  uint256 public totalDebt; // Amount of tokens that all strategies have borrowed
  uint256 public totalIdle; // Amount of tokens that are on the vault
  uint256 public lastReport; // block.timestamp of last report
  uint256 public lockedProfit; // how much profit is locked and cant be withdrawn
  uint256 public previousHarvestTimeDelta; // how much time elapsed between last and previous report

  address public yieldToken;
  address public token;

  address public debtAllocator;
  address public healthCheck;
  address public feeManager;

  string public name;
  string public symbol;

  // Governance Fee for performance of Vault (given to `rewards`)
  uint256 public performanceFee;

  bool public emergencyShutdown;

  mapping(address => StrategyParams) internal _strategies;

  function strategies(address _strategy) external view override returns (StrategyParams memory) {
    return _strategies[_strategy];
  }

  function setHealthCheck(address _healthCheck) external onlyRole(GOVERNANCE) {
    emit UpdateHealthCheck(_healthCheck);
    healthCheck = _healthCheck;
  }

  function setDebtAllocator(address _debtAllocator) external onlyRole(GOVERNANCE) {
    debtAllocator = _debtAllocator;
  }

  function setRewards(address _rewardsRecipient) external onlyRole(GOVERNANCE) {
    /**
    @notice
        Changes the rewardsRecipient address. Any distributed rewards
        will cease flowing to the old address and begin flowing
        to this address once the change is in effect.

        This will not change any Strategy reports in progress, only
        new reports made after this change goes into effect.

        This may only be called by governance.
    @param rewardsRecipient The address to use for collecting rewardsRecipient.
    */
    if (_rewardsRecipient == address(this) || _rewardsRecipient == address(0x0)) revert InvalidRewardsRecipient();
    rewardsRecipient = _rewardsRecipient;
    emit UpdateRewardsRecipient(rewardsRecipient);
  }

  function apiVersion() external pure returns (string memory) {
    /**
    @notice
        Used to track the deployed version of this contract. In practice you
        can use this version number to compare with Yearn's GitHub and
        determine which version of the source matches this deployed contract.
    @dev
        All strategies must have an `apiVersion()` that matches the Vault's
        `API_VERSION`.
    @return API_VERSION which holds the current version of this contract.
     */
    return API_VERSION;
  }

  function setPerformanceFee(uint256 _fee) external onlyRole(GOVERNANCE) {
    /**
    @notice
        Used to change the value of `performanceFee`.

        Should set this value below the maximum strategist performance fee.

        This may only be called by governance.
    @param fee The new performance fee to use.
    */
    if (_fee > performanceFeeThreshold()) revert PerformanceFeeExceedThreshold();

    performanceFee = _fee;
    emit UpdatePerformanceFee(_fee);
  }

  function setDepositLimit(uint256 _limit) external onlyRole(GOVERNANCE) {
    /**
    @notice
        Changes the maximum amount of tokens that can be deposited in this Vault.

        Note, this is not how much may be deposited by a single depositor,
        but the maximum amount that may be deposited across all depositors.

        This may only be called by governance.
    @param limit The new deposit limit to use.
    */
    depositLimit = _limit;
    emit UpdateDepositLimit(_limit);
  }

  // TODO moving global managementFee to per strategy
  // function setManagementFee(uint256 _fee) external {
  //   /**
  //   @notice
  //       Used to change the value of `managementFee`.

  //       This may only be called by governance.
  //   @param fee The new management fee to use.
  //    */
  //   if (!hasRole(GOVERNANCE, msg.sender)) revert NoAccess();
  //   assert(_fee <= MAX_BPS);
  //   managementFee = _fee;
  //   emit UpdateManagementFee(_fee);
  // }

  function setEmergencyShutdown(bool _active) external onlyRole(SHUTDOWN_MANAGER) {
    /**
    @notice
        Activates or deactivates Vault mode where all Strategies go into full
        withdrawal.

        During Emergency Shutdown:
        1. No Users may deposit into the Vault (but may withdraw as usual.)
        2. Governance may not add new Strategies.
        3. Each Strategy must pay back their debt as quickly as reasonable to
            minimally affect their position.
        4. Only Governance may undo Emergency Shutdown.

        See contract level note for further details.

        This may only be called by governance or the guardian.
    @param active
        If true, the Vault goes into Emergency Shutdown. If false, the Vault
        goes back into Normal Operation.
     */
    if (!_active && !hasRole(GOVERNANCE, msg.sender)) revert OnlyGovernanceCanUndoShutdown();
    emergencyShutdown = _active;
    emit EmergencyShutdown(_active);
  }

  function performanceFeeThreshold() public pure returns (uint256) {
    return MAX_BPS / 2;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4 <0.9.0;

interface IBaseStrategy {
  // So indexers can keep track of this
  // ****** EVENTS ******

  error NoAccess();

  error ProtectedToken(address token);

  error StrategyAlreadyInitialized();

  /**
   * @notice This Strategy's name.
   * @dev
   *  You can use this field to manage the 'version' of this Strategy, e.g.
   *  `StrategySomethingOrOtherV1`. However, 'API Version' is managed by
   *  `apiVersion()` function above.
   * @return _name This Strategy's name.
   */
  function name() external view returns (string memory _name);

  function apiVersion() external pure returns (uint256);

  function want() external view returns (address _want);

  function vault() external view returns (address _vault);

  function harvestTrigger() external view returns (bool);

  function harvest() external;

  // - `withdrawable() -> uint256`: returns amount of funds that can be freed
  function withdrawable() external view returns (uint256 _withdrawable);

  // - manual: called by governance or guard, behaves similarly to freeFunds but can incur in losses.
  // - vault: called by vault.updateDebt if vault is on emergencyFreeFunds mode.
  function emergencyFreeFunds(uint256 _amountToWithdraw) external;

  // - `investable() -> uint256`: returns _minDebt, _maxDebt with the min and max amounts that a strategy can invest in the underlying protocol.
  function investable() external view returns (uint256 _minDebt, uint256 _maxDebt);

  // TODO Discuss (mix of totalDebt + freeFunds? kinda)
  function totalAssets() external view returns (uint256 _totalAssets);

  // - `investTrigger() -> bool`: returns true when the strategy has available funds to invest and space for them.
  function investTrigger() external view returns (bool);

  // - `invest()`: strategy will invest loose funds into the strategy. only callable by keepers
  function invest() external;

  // - `freeFunds(uint256 _amount)`: strategy will free/unlocked funds from the underlying protocol and leave them idle. (called by vault on updateDebt)
  function freeFunds(uint256 _amount) external returns (uint256 _freeFunds);

  // TODO: do we really need delegatedAssets? most strategies won't use it...
  function delegatedAssets() external view returns (uint256 _delegatedAssets);

  function migrate(address) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4 <0.9.0;

interface IWithdrawalQueue {
  event StrategyRemovedFromQueue(
    address indexed strategy // Address of the strategy that is removed from the withdrawal queue
  );

  event StrategyAddedToQueue(
    address indexed strategy // Address of the strategy that is added to the withdrawal queue
  );

  function getQueue() external view returns (address[] calldata _queue);

  function addStrategyToQueue(address _strategy) external;

  function removeStrategyFromQueue(address _strategy) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4 <0.9.0;

interface IVaultShareManager {
  event Deposit(address indexed recipient, uint256 shares, uint256 amount);
  event Withdraw(address indexed recipient, uint256 shares, uint256 amount);

  error NoDepositOnEmergencyShutdown();
  error InvalidRecipient();
  error ExceededDepositAmount();
  error TokenAmountLessThanExpected();
  error SharesExceedSenderYieldTokenBalance();
  error InvalidStrategy();
  error NotEnoughIdleTokens();

  function pricePerShare() external view returns (uint256 _pricecPerShare);

  function totalAssets() external view returns (uint256 _totalAssets);

  function withdraw(
    uint256 _maxShares,
    address _recipient,
    address[] memory _withdrawableStrategies
  ) external returns (uint256 _tokenAmount);

  function availableDepositLimit() external view returns (uint256 _availableDepositLimit);

  function deposit() external returns (uint256 _shares);

  function deposit(uint256 _amount) external returns (uint256 _shares);

  function deposit(uint256 _amount, address _recipient) external returns (uint256 _shares);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4 <0.9.0;

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import {IVaultAccessControl} from '../../interfaces/core/Vault/IVaultAccessControl.sol';

abstract contract VaultAccessControl is IVaultAccessControl, AccessControlUpgradeable {
  bytes32 public constant MASTER_ADMIN = keccak256('MASTER_ADMIN');
  bytes32 public constant GOVERNANCE = keccak256('GOVERNANCE');
  bytes32 public constant MANAGEMENT = keccak256('MANAGEMENT');
  bytes32 public constant GUARDIAN = keccak256('GUARDIAN');
  bytes32 public constant DEBT_OPERATOR = keccak256('DEBT_OPERATOR');
  bytes32 public constant STRATEGY_MANAGER = keccak256('STRATEGY_MANAGER');
  bytes32 public constant STRATEGY_REPORTER = keccak256('STRATEGY_REPORTER');
  bytes32 public constant SHUTDOWN_MANAGER = keccak256('SHUTDOWN_MANAGER');

  address public rewardsRecipient; // Rewards contract where Governance fees are sent to

  function __VaultAccessControl_init(
    address _masterAdmin,
    address _guardian,
    address _management
  ) internal onlyInitializing {
    _setRoleAdmin(MASTER_ADMIN, MASTER_ADMIN);
    _setRoleAdmin(GOVERNANCE, GOVERNANCE); // NOTE should governance be it's own admin?
    _setupRole(MASTER_ADMIN, _masterAdmin);
    _setupRole(GOVERNANCE, _masterAdmin);
    _setupRole(GUARDIAN, _guardian);
    _setupRole(SHUTDOWN_MANAGER, _masterAdmin);
    _setupRole(SHUTDOWN_MANAGER, _guardian);
    _setupRole(MANAGEMENT, _management);
    _setupRole(STRATEGY_MANAGER, _masterAdmin);
    _setupRole(STRATEGY_REPORTER, _masterAdmin);

    _setRoleAdmin(GOVERNANCE, GOVERNANCE); // NOTE should governance be it's own admin?
    _setRoleAdmin(GUARDIAN, GOVERNANCE);
    _setRoleAdmin(MANAGEMENT, GOVERNANCE);
    _setRoleAdmin(SHUTDOWN_MANAGER, MASTER_ADMIN);

    // the following roles are not set by default. should we set them?
    _setRoleAdmin(DEBT_OPERATOR, MASTER_ADMIN);
    _setRoleAdmin(STRATEGY_MANAGER, MASTER_ADMIN);
    _setRoleAdmin(STRATEGY_REPORTER, STRATEGY_MANAGER);
    // TODO Set proper role admins
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4 <0.9.0;

interface IVaultStrategyManager {
  error UnhealthyStrategy(address strategy, uint256 gain, uint256 loss, uint256 totalDebt);

  error InvalidReport(uint256 expectedGain, uint256 gain, uint256 expectedLoss, uint256 loss);

  error NoChangeInDebt();

  error InvalidWantToken();

  error InvalidVault();

  error LessThanMinDebt();

  error SameDebt();

  error NothingToWithdraw();

  // TODO (Yao): this can be a common error shared across contracts
  error ZeroAddress();

  // TODO (Yao): this can be a common error shared across strategy contracts
  error StrategyShutdown();

  event DebtUpdated(address strategy, uint256 oldDebt, uint256 newDebt);

  event StrategyAdded(address indexed strategy);

  event StrategyMigrated(
    address indexed oldVersion, // Old version of the strategy to be migrated
    address indexed newVersion // New version of the strategy
  );

  event StrategyRevoked(
    address indexed strategy // Address of the strategy that is revoked
  );

  // TODO General: TWAP Oracle Module
  event StrategyReported(
    address indexed strategy,
    uint256 gain,
    uint256 loss,
    uint256 totalGain,
    uint256 totalLoss,
    uint256 totalDebt,
    uint256 totalFees
  );

  function addStrategy(address _strategy) external;

  function migrateStrategy(address _oldVersion, address _newVersion) external;

  function revokeStrategy() external;

  function revokeStrategy(address _strategy) external;

  function updateDebt(address _strategy) external returns (uint256 _newDebt);

  function processStrategyReport(address _strategy) external returns (uint256 _profit, uint256 _loss);

  function processStrategyReportForced(
    address _strategy,
    uint256 _expectedGain,
    uint256 _expectedLoss
  ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4 <0.9.0;

interface IVaultParameters {
  struct StrategyParams {
    uint256 activation; // Activation block.timestamp
    uint256 lastReport; // block.timestamp of the last time a report occured
    uint256 totalDebt; // Total outstanding debt that Strategy has
    uint256 totalGain; // Total returns that Strategy has realized for Vault
    uint256 totalLoss; // Total losses that Strategy has realized for Vault
    // TODO Add withdrawable flag bool withdrawable;
  }

  event UpdateDepositLimit(uint256 depositLimit); // New active deposit limit

  event UpdatePerformanceFee(uint256 performanceFee); //New active performance fee

  event EmergencyShutdown(bool active); //New emergency shutdown state (if false, normal operation enabled);

  error OnlyGovernanceCanUndoShutdown();

  event UpdateHealthCheck(address healthcheck);

  event StrategyUpdatePerformanceFee(
    address indexed strategy, // Address of the strategy for the performance fee adjustment
    uint256 performanceFee // The new performance fee for the strategy
  );

  error ZeroAmount();

  error PerformanceFeeExceedThreshold();

  function strategies(address _strategy) external view returns (StrategyParams memory);

  function setDebtAllocator(address _debtAllocator) external;

  function setHealthCheck(address _healthCheck) external;

  function depositLimit() external view returns (uint256 _depositLimit);

  function totalDebt() external view returns (uint256 _totalDebt);

  function totalIdle() external view returns (uint256 _totalIdle);

  function lastReport() external view returns (uint256 _lastReport);

  function lockedProfit() external view returns (uint256 _lockedProfit);

  function previousHarvestTimeDelta() external view returns (uint256 _previousHarvestTimeDelta);

  function yieldToken() external view returns (address _yieldToken);

  function token() external view returns (address _token);

  function name() external view returns (string calldata _name);

  function symbol() external view returns (string calldata _symbol);

  function performanceFee() external view returns (uint256 _performanceFee);

  function emergencyShutdown() external view returns (bool _emergencyShutdown);

  function apiVersion() external pure returns (string memory);

  function setPerformanceFee(uint256 _fee) external;

  function setDepositLimit(uint256 _limit) external;

  function setEmergencyShutdown(bool _active) external;

  function performanceFeeThreshold() external view returns (uint256);

  function debtAllocator() external view returns (address _debtAllocator);

  function healthCheck() external view returns (address _healthCheck);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4 <0.9.0;

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

interface IVaultAccessControl is IAccessControlUpgradeable {
  error InvalidRewardsRecipient();

  event UpdateRewardsRecipient(address rewardsRecipient); // New active rewards recipient

  function MASTER_ADMIN() external view returns (bytes32 _masterAdmin);

  function GOVERNANCE() external view returns (bytes32 _governance);

  function MANAGEMENT() external view returns (bytes32 _management);

  function GUARDIAN() external view returns (bytes32 _guardian);

  function DEBT_OPERATOR() external view returns (bytes32 _debtOperator);

  function STRATEGY_MANAGER() external view returns (bytes32 _strategyManager);

  function STRATEGY_REPORTER() external view returns (bytes32 _strategyReporter);

  function rewardsRecipient() external view returns (address _rewardsRecipient);

  function setRewards(address _rewardsRecipient) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4 <0.9.0;

interface IDebtAllocator {
  function maxDebt(address _strategy) external view returns (uint256 _maxDebt);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4 <0.9.0;

interface IFeeManager {
  function assessFees(address _strategy, uint256 _gain) external returns (uint256 totalFeesAmount);
}