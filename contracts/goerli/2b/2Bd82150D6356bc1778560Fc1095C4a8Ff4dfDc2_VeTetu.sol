// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IControllable {

  function isController(address _contract) external view returns (bool);

  function isGovernance(address _contract) external view returns (bool);

  function created() external view returns (uint256);

  function createdBlock() external view returns (uint256);

  function controller() external view returns (address);

  function increaseRevision(address oldLogic) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IController {

  // --- DEPENDENCY ADDRESSES
  function governance() external view returns (address);

  function voter() external view returns (address);

  function liquidator() external view returns (address);

  function forwarder() external view returns (address);

  function investFund() external view returns (address);

  function veDistributor() external view returns (address);

  function platformVoter() external view returns (address);

  // --- VAULTS

  function vaults(uint id) external view returns (address);

  function vaultsList() external view returns (address[] memory);

  function vaultsListLength() external view returns (uint);

  function isValidVault(address _vault) external view returns (bool);

  // --- restrictions

  function isOperator(address _adr) external view returns (bool);


}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

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

pragma solidity 0.8.17;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint);

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
  function approve(address spender, uint amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity 0.8.17;

import "./IERC20.sol";

/**
 * https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/release-v4.6/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity 0.8.17;

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

pragma solidity 0.8.17;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
  /**
   * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
   */
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

  /**
   * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
   */
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

  /**
   * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
   */
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  /**
   * @dev Returns the number of tokens in ``owner``'s account.
   */
  function balanceOf(address owner) external view returns (uint256 balance);

  /**
   * @dev Returns the owner of the `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function ownerOf(uint256 tokenId) external view returns (address owner);

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  /**
   * @dev Transfers `tokenId` token from `from` to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  /**
   * @dev Gives permission to `to` to transfer `tokenId` token to another account.
   * The approval is cleared when the token is transferred.
   *
   * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
   *
   * Requirements:
   *
   * - The caller must own the token or be an approved operator.
   * - `tokenId` must exist.
   *
   * Emits an {Approval} event.
   */
  function approve(address to, uint256 tokenId) external;

  /**
   * @dev Returns the account approved for `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function getApproved(uint256 tokenId) external view returns (address operator);

  /**
   * @dev Approve or remove `operator` as an operator for the caller.
   * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
   *
   * Requirements:
   *
   * - The `operator` cannot be the caller.
   *
   * Emits an {ApprovalForAll} event.
   */
  function setApprovalForAll(address operator, bool _approved) external;

  /**
   * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
   *
   * See {setApprovalForAll}
   */
  function isApprovedForAll(address owner, address operator) external view returns (bool);

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IERC721.sol";

/**
* @title ERC-721 Non-Fungible Token Standard, optional metadata extension
* @dev See https://eips.ethereum.org/EIPS/eip-721
*/
interface IERC721Metadata is IERC721 {
  /**
  * @dev Returns the token collection name.
  */
  function name() external view returns (string memory);

  /**
  * @dev Returns the token collection symbol.
  */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
  */
  function tokenURI(uint tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
  /**
   * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
   * by `operator` from `from`, this function is called.
   *
   * It must return its Solidity selector to confirm the token transfer.
   * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
   *
   * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
   */
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IPlatformVoter {

  enum AttributeType {
    UNKNOWN,
    INVEST_FUND_RATIO,
    GAUGE_RATIO,
    STRATEGY_COMPOUND
  }

  struct Vote {
    AttributeType _type;
    address target;
    uint weight;
    uint weightedValue;
    uint timestamp;
  }

  function detachTokenFromAll(uint tokenId, address owner) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IVeTetu {

  enum DepositType {
    DEPOSIT_FOR_TYPE,
    CREATE_LOCK_TYPE,
    INCREASE_LOCK_AMOUNT,
    INCREASE_UNLOCK_TIME,
    MERGE_TYPE
  }

  struct Point {
    int128 bias;
    int128 slope; // # -dweight / dt
    uint ts;
    uint blk; // block
  }
  /* We cannot really do block numbers per se b/c slope is per time, not per block
  * and per block could be fairly bad b/c Ethereum changes blocktimes.
  * What we can do is to extrapolate ***At functions */

  function attachments(uint tokenId) external view returns (uint);

  function lockedAmounts(uint veId, address stakingToken) external view returns (uint);

  function lockedDerivedAmount(uint veId) external view returns (uint);

  function lockedEnd(uint veId) external view returns (uint);

  function voted(uint tokenId) external view returns (uint);

  function tokens(uint idx) external view returns (address);

  function balanceOfNFT(uint) external view returns (uint);

  function isApprovedOrOwner(address, uint) external view returns (bool);

  function createLockFor(address _token, uint _value, uint _lockDuration, address _to) external returns (uint);

  function userPointEpoch(uint tokenId) external view returns (uint);

  function epoch() external view returns (uint);

  function userPointHistory(uint tokenId, uint loc) external view returns (Point memory);

  function pointHistory(uint loc) external view returns (Point memory);

  function checkpoint() external;

  function increaseAmount(address _token, uint _tokenId, uint _value) external;

  function attachToken(uint tokenId) external;

  function detachToken(uint tokenId) external;

  function voting(uint tokenId) external;

  function abstain(uint tokenId) external;

  function totalSupplyAt(uint _block) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IVoter {

  function ve() external view returns (address);

  function attachTokenToGauge(address stakingToken, uint _tokenId, address account) external;

  function detachTokenFromGauge(address stakingToken, uint _tokenId, address account) external;

  function distribute(address stakingToken) external;

  function notifyRewardAmount(uint amount) external;

  function detachTokenFromAll(uint tokenId, address account) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
  bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  /// @notice Encodes some bytes to the base64 representation
  function encode(bytes memory data) internal pure returns (string memory) {
    uint len = data.length;
    if (len == 0) return "";

    // multiply by 4/3 rounded up
    uint encodedLen = 4 * ((len + 2) / 3);

    // Add some extra buffer at the end
    bytes memory result = new bytes(encodedLen + 32);

    bytes memory table = TABLE;

    assembly {
      let tablePtr := add(table, 1)
      let resultPtr := add(result, 32)

      for {
        let i := 0
      } lt(i, len) {

      } {
        i := add(i, 3)
        let input := and(mload(add(data, i)), 0xffffff)

        let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
        out := shl(224, out)

        mstore(resultPtr, out)

        resultPtr := add(resultPtr, 4)
      }

      switch mod(len, 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }

      mstore(result, encodedLen)
    }

    return string(result);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
  /*//////////////////////////////////////////////////////////////
  //SIMPLIFIED FIXED POINT OPERATIONS
  //////////////////////////////////////////////////////////////*/

  uint internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

  function mulWadDown(uint x, uint y) internal pure returns (uint) {
    return mulDivDown(x, y, WAD);
    // Equivalent to (x * y) / WAD rounded down.
  }

  function mulWadUp(uint x, uint y) internal pure returns (uint) {
    return mulDivUp(x, y, WAD);
    // Equivalent to (x * y) / WAD rounded up.
  }

  function divWadDown(uint x, uint y) internal pure returns (uint) {
    return mulDivDown(x, WAD, y);
    // Equivalent to (x * WAD) / y rounded down.
  }

  function divWadUp(uint x, uint y) internal pure returns (uint) {
    return mulDivUp(x, WAD, y);
    // Equivalent to (x * WAD) / y rounded up.
  }

  function positiveInt128(int128 value) internal pure returns (int128) {
    return value < 0 ? int128(0) : value;
  }

  /*//////////////////////////////////////////////////////////////
  //LOW LEVEL FIXED POINT OPERATIONS
  //////////////////////////////////////////////////////////////*/

  function mulDivDown(
    uint x,
    uint y,
    uint denominator
  ) internal pure returns (uint z) {
    assembly {
    // Store x * y in z for now.
      z := mul(x, y)

    // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
      if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
        revert(0, 0)
      }

    // Divide z by the denominator.
      z := div(z, denominator)
    }
  }

  function mulDivUp(
    uint x,
    uint y,
    uint denominator
  ) internal pure returns (uint z) {
    assembly {
    // Store x * y in z for now.
      z := mul(x, y)

    // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
      if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
        revert(0, 0)
      }

    // First, divide z - 1 by the denominator and add 1.
    // We allow z - 1 to underflow if z is 0, because we multiply the
    // end result by 0 if z is zero, ensuring we return 0 if z is zero.
      z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
    }
  }

  function rpow(
    uint x,
    uint n,
    uint scalar
  ) internal pure returns (uint z) {
    assembly {
      switch x
      case 0 {
        switch n
        case 0 {
        // 0 ** 0 = 1
          z := scalar
        }
        default {
        // 0 ** n = 0
          z := 0
        }
      }
      default {
        switch mod(n, 2)
        case 0 {
        // If n is even, store scalar in z for now.
          z := scalar
        }
        default {
        // If n is odd, store x in z for now.
          z := x
        }

      // Shifting right by 1 is like dividing by 2.
        let half := shr(1, scalar)

        for {
        // Shift n right by 1 before looping to halve it.
          n := shr(1, n)
        } n {
        // Shift n right by 1 each iteration to halve it.
          n := shr(1, n)
        } {
        // Revert immediately if x ** 2 would overflow.
        // Equivalent to iszero(eq(div(xx, x), x)) here.
          if shr(128, x) {
            revert(0, 0)
          }

        // Store x squared.
          let xx := mul(x, x)

        // Round to the nearest number.
          let xxRound := add(xx, half)

        // Revert if xx + half overflowed.
          if lt(xxRound, xx) {
            revert(0, 0)
          }

        // Set x to scaled xxRound.
          x := div(xxRound, scalar)

        // If n is even:
          if mod(n, 2) {
          // Compute z * x.
            let zx := mul(z, x)

          // If z * x overflowed:
            if iszero(eq(div(zx, x), z)) {
            // Revert if x is non-zero.
              if iszero(iszero(x)) {
                revert(0, 0)
              }
            }

          // Round to the nearest number.
            let zxRound := add(zx, half)

          // Revert if zx + half overflowed.
            if lt(zxRound, zx) {
              revert(0, 0)
            }

          // Return properly scaled zxRound.
            z := div(zxRound, scalar)
          }
        }
      }
    }
  }

  /*//////////////////////////////////////////////////////////////
  // GENERAL NUMBER UTILITIES
  //////////////////////////////////////////////////////////////*/

  function sqrt(uint x) internal pure returns (uint z) {
    assembly {
    // Start off with z at 1.
      z := 1

    // Used below to help find a nearby power of 2.
      let y := x

    // Find the lowest power of 2 that is at least sqrt(x).
      if iszero(lt(y, 0x100000000000000000000000000000000)) {
        y := shr(128, y) // Like dividing by 2 ** 128.
        z := shl(64, z) // Like multiplying by 2 ** 64.
      }
      if iszero(lt(y, 0x10000000000000000)) {
        y := shr(64, y) // Like dividing by 2 ** 64.
        z := shl(32, z) // Like multiplying by 2 ** 32.
      }
      if iszero(lt(y, 0x100000000)) {
        y := shr(32, y) // Like dividing by 2 ** 32.
        z := shl(16, z) // Like multiplying by 2 ** 16.
      }
      if iszero(lt(y, 0x10000)) {
        y := shr(16, y) // Like dividing by 2 ** 16.
        z := shl(8, z) // Like multiplying by 2 ** 8.
      }
      if iszero(lt(y, 0x100)) {
        y := shr(8, y) // Like dividing by 2 ** 8.
        z := shl(4, z) // Like multiplying by 2 ** 4.
      }
      if iszero(lt(y, 0x10)) {
        y := shr(4, y) // Like dividing by 2 ** 4.
        z := shl(2, z) // Like multiplying by 2 ** 2.
      }
      if iszero(lt(y, 0x8)) {
      // Equivalent to 2 ** z.
        z := shl(1, z)
      }

    // Shifting right by 1 is like dividing by 2.
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))

    // Compute a rounded down version of z.
      let zRoundDown := div(x, z)

    // If zRoundDown is smaller, use it.
      if lt(zRoundDown, z) {
        z := zRoundDown
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @title Library for interface IDs
/// @author bogdoslav
library InterfaceIds {

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant INTERFACE_IDS_LIB_VERSION = "1.0.0";

  /// default notation:
  /// bytes4 public constant I_VOTER = type(IVoter).interfaceId;

  /// As type({Interface}).interfaceId can be changed,
  /// when some functions changed at the interface,
  /// so used hardcoded interface identifiers

  bytes4 public constant I_VOTER = bytes4(keccak256("IVoter"));
  bytes4 public constant I_BRIBE = bytes4(keccak256("IBribe"));
  bytes4 public constant I_GAUGE = bytes4(keccak256("IGauge"));
  bytes4 public constant I_VE_TETU = bytes4(keccak256("IVeTetu"));
  bytes4 public constant I_SPLITTER = bytes4(keccak256("ISplitter"));
  bytes4 public constant I_FORWARDER = bytes4(keccak256("IForwarder"));
  bytes4 public constant I_MULTI_POOL = bytes4(keccak256("IMultiPool"));
  bytes4 public constant I_CONTROLLER = bytes4(keccak256("IController"));
  bytes4 public constant I_TETU_ERC165 = bytes4(keccak256("ITetuERC165"));
  bytes4 public constant I_STRATEGY_V2 = bytes4(keccak256("IStrategyV2"));
  bytes4 public constant I_CONTROLLABLE = bytes4(keccak256("IControllable"));
  bytes4 public constant I_TETU_VAULT_V2 = bytes4(keccak256("ITetuVaultV2"));
  bytes4 public constant I_PLATFORM_VOTER = bytes4(keccak256("IPlatformVoter"));
  bytes4 public constant I_VE_DISTRIBUTOR = bytes4(keccak256("IVeDistributor"));
  bytes4 public constant I_TETU_CONVERTER = bytes4(keccak256("ITetuConverter"));
  bytes4 public constant I_VAULT_INSURANCE = bytes4(keccak256("IVaultInsurance"));

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @title Library for setting / getting slot variables (used in upgradable proxy contracts)
/// @author bogdoslav
library SlotsLib {

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant SLOT_LIB_VERSION = "1.0.0";

  // ************* GETTERS *******************

  /// @dev Gets a slot as bytes32
  function getBytes32(bytes32 slot) internal view returns (bytes32 result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot as an address
  function getAddress(bytes32 slot) internal view returns (address result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot as uint256
  function getUint(bytes32 slot) internal view returns (uint result) {
    assembly {
      result := sload(slot)
    }
  }

  // ************* ARRAY GETTERS *******************

  /// @dev Gets an array length
  function arrayLength(bytes32 slot) internal view returns (uint result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot array by index as address
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function addressAt(bytes32 slot, uint index) internal view returns (address result) {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      result := sload(pointer)
    }
  }

  /// @dev Gets a slot array by index as uint
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function uintAt(bytes32 slot, uint index) internal view returns (uint result) {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      result := sload(pointer)
    }
  }

  // ************* SETTERS *******************

  /// @dev Sets a slot with bytes32
  /// @notice Check address for 0 at the setter
  function set(bytes32 slot, bytes32 value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  /// @dev Sets a slot with address
  /// @notice Check address for 0 at the setter
  function set(bytes32 slot, address value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  /// @dev Sets a slot with uint
  function set(bytes32 slot, uint value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  // ************* ARRAY SETTERS *******************

  /// @dev Sets a slot array at index with address
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function setAt(bytes32 slot, uint index, address value) internal {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      sstore(pointer, value)
    }
  }

  /// @dev Sets a slot array at index with uint
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function setAt(bytes32 slot, uint index, uint value) internal {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      sstore(pointer, value)
    }
  }

  /// @dev Sets an array length
  function setLength(bytes32 slot, uint length) internal {
    assembly {
      sstore(slot, length)
    }
  }

  /// @dev Pushes an address to the array
  function push(bytes32 slot, address value) internal {
    uint length = arrayLength(slot);
    setAt(slot, length, value);
    setLength(slot, length + 1);
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity 0.8.17;

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity 0.8.17;

import "../interfaces/IERC165.sol";

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
abstract contract ERC165 is IERC165 {
  /**
   * @dev See {IERC165-supportsInterface}.
     */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC165).interfaceId;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity 0.8.17;

import "./Address.sol";

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
      (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
    if (_initialized != type(uint8).max) {
      _initialized = type(uint8).max;
      emit Initialized(type(uint8).max);
    }
  }

  /**
   * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
  function _getInitializedVersion() internal view returns (uint8) {
    return _initialized;
  }

  /**
   * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
  function _isInitializing() internal view returns (bool) {
    return _initializing;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity 0.8.17;

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
   * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
  function _reentrancyGuardEntered() internal view returns (bool) {
    return _status == _ENTERED;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity 0.8.17;

import "../interfaces/IERC20.sol";
import "../interfaces/IERC20Permit.sol";
import "./Address.sol";

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

pragma solidity 0.8.17;

import "../openzeppelin/Initializable.sol";
import "../tools/TetuERC165.sol";
import "../interfaces/IControllable.sol";
import "../interfaces/IController.sol";
import "../lib/SlotsLib.sol";
import "../lib/InterfaceIds.sol";

/// @title Implement basic functionality for any contract that require strict control
/// @dev Can be used with upgradeable pattern.
///      Require call __Controllable_init() in any case.
/// @author belbix
abstract contract ControllableV3 is Initializable, TetuERC165, IControllable {
  using SlotsLib for bytes32;

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant CONTROLLABLE_VERSION = "3.0.0";

  bytes32 internal constant _CONTROLLER_SLOT = bytes32(uint256(keccak256("eip1967.controllable.controller")) - 1);
  bytes32 internal constant _CREATED_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created")) - 1);
  bytes32 internal constant _CREATED_BLOCK_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created_block")) - 1);
  bytes32 internal constant _REVISION_SLOT = bytes32(uint256(keccak256("eip1967.controllable.revision")) - 1);
  bytes32 internal constant _PREVIOUS_LOGIC_SLOT = bytes32(uint256(keccak256("eip1967.controllable.prev_logic")) - 1);

  event ContractInitialized(address controller, uint ts, uint block);
  event RevisionIncreased(uint value, address oldLogic);

  /// @dev Prevent implementation init
  constructor() {
    _disableInitializers();
  }

  /// @notice Initialize contract after setup it as proxy implementation
  ///         Save block.timestamp in the "created" variable
  /// @dev Use it only once after first logic setup
  /// @param controller_ Controller address
  function __Controllable_init(address controller_) internal onlyInitializing {
    require(controller_ != address(0), "Zero controller");
    _requireInterface(controller_, InterfaceIds.I_CONTROLLER);
    require(IController(controller_).governance() != address(0), "Zero governance");
    _CONTROLLER_SLOT.set(controller_);
    _CREATED_SLOT.set(block.timestamp);
    _CREATED_BLOCK_SLOT.set(block.number);
    emit ContractInitialized(controller_, block.timestamp, block.number);
  }

  /// @dev Return true if given address is controller
  function isController(address _value) public override view returns (bool) {
    return _value == controller();
  }

  /// @notice Return true if given address is setup as governance in Controller
  function isGovernance(address _value) public override view returns (bool) {
    return IController(controller()).governance() == _value;
  }

  /// @dev Contract upgrade counter
  function revision() external view returns (uint){
    return _REVISION_SLOT.getUint();
  }

  /// @dev Previous logic implementation
  function previousImplementation() external view returns (address){
    return _PREVIOUS_LOGIC_SLOT.getAddress();
  }

  /// @dev See {IERC165-supportsInterface}.
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == InterfaceIds.I_CONTROLLABLE || super.supportsInterface(interfaceId);
  }

  // ************* SETTERS/GETTERS *******************

  /// @notice Return controller address saved in the contract slot
  function controller() public view override returns (address) {
    return _CONTROLLER_SLOT.getAddress();
  }

  /// @notice Return creation timestamp
  /// @return Creation timestamp
  function created() external view override returns (uint256) {
    return _CREATED_SLOT.getUint();
  }

  /// @notice Return creation block number
  /// @return Creation block number
  function createdBlock() external override view returns (uint256) {
    return _CREATED_BLOCK_SLOT.getUint();
  }

  /// @dev Revision should be increased on each contract upgrade
  function increaseRevision(address oldLogic) external override {
    require(msg.sender == address(this), "Increase revision forbidden");
    uint r = _REVISION_SLOT.getUint() + 1;
    _REVISION_SLOT.set(r);
    _PREVIOUS_LOGIC_SLOT.set(oldLogic);
    emit RevisionIncreased(r, oldLogic);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../openzeppelin/ERC165.sol";
import "../interfaces/IERC20.sol";
import "../lib/InterfaceIds.sol";

/// @dev Tetu Implementation of the {IERC165} interface extended with helper functions.
/// @author bogdoslav
abstract contract TetuERC165 is ERC165 {

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == InterfaceIds.I_TETU_ERC165 || super.supportsInterface(interfaceId);
  }

  // *************************************************************
  //                        HELPER FUNCTIONS
  // *************************************************************
  /// @author bogdoslav

  /// @dev Checks what interface with id is supported by contract.
  /// @return bool. Do not throws
  function _isInterfaceSupported(address contractAddress, bytes4 interfaceId) internal view returns (bool) {
    require(contractAddress != address(0), "Zero address");
    // check what address is contract
    uint codeSize;
    assembly {
      codeSize := extcodesize(contractAddress)
    }
    if (codeSize == 0) return false;

    try IERC165(contractAddress).supportsInterface(interfaceId) returns (bool isSupported) {
      return isSupported;
    } catch {
    }
    return false;
  }

  /// @dev Checks what interface with id is supported by contract and reverts otherwise
  function _requireInterface(address contractAddress, bytes4 interfaceId) internal view {
    require(_isInterfaceSupported(contractAddress, interfaceId), "Interface is not supported");
  }

  /// @dev Checks what address is ERC20.
  /// @return bool. Do not throws
  function _isERC20(address contractAddress) internal view returns (bool) {
    require(contractAddress != address(0), "Zero address");
    // check what address is contract
    uint codeSize;
    assembly {
      codeSize := extcodesize(contractAddress)
    }
    if (codeSize == 0) return false;

    bool totalSupplySupported;
    try IERC20(contractAddress).totalSupply() returns (uint) {
      totalSupplySupported = true;
    } catch {
    }

    bool balanceSupported;
    try IERC20(contractAddress).balanceOf(address(this)) returns (uint) {
      balanceSupported = true;
    } catch {
    }

    return totalSupplySupported && balanceSupported;
  }


  /// @dev Checks what interface with id is supported by contract and reverts otherwise
  function _requireERC20(address contractAddress) internal view {
    require(_isERC20(contractAddress), "Not ERC20");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../openzeppelin/ReentrancyGuard.sol";
import "../openzeppelin/SafeERC20.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC20Metadata.sol";
import "../interfaces/IERC721Metadata.sol";
import "../interfaces/IVeTetu.sol";
import "../interfaces/IERC721Receiver.sol";
import "../interfaces/IController.sol";
import "../interfaces/IVoter.sol";
import "../interfaces/IPlatformVoter.sol";
import "../lib/FixedPointMathLib.sol";
import "../proxy/ControllableV3.sol";
import "./VeTetuLogo.sol";

/// @title Voting escrow NFT for multiple underlying tokens.
///        Based on Curve/Solidly contract.
/// @author belbix
contract VeTetu is ControllableV3, ReentrancyGuard, IERC721, IERC721Metadata, IVeTetu {
  using SafeERC20 for IERC20;
  using FixedPointMathLib for uint;
  using FixedPointMathLib for int128;

  // Only for internal usage
  struct DepositInfo {
    address stakingToken;
    uint tokenId;
    uint value;
    uint unlockTime;
    uint lockedAmount;
    uint lockedDerivedAmount;
    uint lockedEnd;
    DepositType depositType;
  }

  // Only for internal usage
  struct CheckpointInfo {
    uint tokenId;
    uint oldDerivedAmount;
    uint newDerivedAmount;
    uint oldEnd;
    uint newEnd;
  }

  // *************************************************************
  //                          ERRORS
  // *************************************************************
  // we do not use custom errors (yet) for the reason of lack support from off-chain frameworks

  string internal constant WRONG_INPUT = "WRONG_INPUT";
  string internal constant WRONG_DECIMALS = "WRONG_DECIMALS";
  string internal constant NOT_GOVERNANCE = "NOT_GOVERNANCE";
  string internal constant NOT_VOTER = "NOT_VOTER";
  string internal constant TOO_MANY_ATTACHMENTS = "TOO_MANY_ATTACHMENTS";
  string internal constant NOT_OWNER = "NOT_OWNER";
  string internal constant FORBIDDEN = "FORBIDDEN";
  string internal constant IDENTICAL_ADDRESS = "IDENTICAL_ADDRESS";
  string internal constant LOW_LOCK_PERIOD = "LOW_LOCK_PERIOD";
  string internal constant HIGH_LOCK_PERIOD = "HIGH_LOCK_PERIOD";
  string internal constant INVALID_TOKEN = "INVALID_TOKEN";
  string internal constant NFT_WITHOUT_POWER = "NFT_WITHOUT_POWER";
  string internal constant EXPIRED = "EXPIRED";
  string internal constant LOW_UNLOCK_TIME = "LOW_UNLOCK_TIME";
  string internal constant ATTACHED = "ATTACHED";
  string internal constant LOW_PERCENT = "LOW_PERCENT";
  string internal constant NOT_EXPIRED = "NOT_EXPIRED";
  string internal constant ZERO_LOCKED = "ZERO_LOCKED";
  string internal constant TOKEN_NOT_EXIST = "TOKEN_NOT_EXIST";

  // *************************************************************
  //                        CONSTANTS
  // *************************************************************

  /// @dev Version of this contract. Adjust manually on each code modification.
  string public constant VE_VERSION = "1.0.0";
  uint internal constant WEEK = 1 weeks;
  uint internal constant MAX_TIME = 16 weeks;
  int128 internal constant I_MAX_TIME = 16 weeks;
  uint internal constant MULTIPLIER = 1 ether;
  uint internal constant WEIGHT_DENOMINATOR = 100e18;
  uint public constant MAX_ATTACHMENTS = 1;

  string constant public override name = "veTETU";
  string constant public override symbol = "veTETU";

  /// @dev ERC165 interface ID of ERC165
  bytes4 internal constant _ERC165_INTERFACE_ID = 0x01ffc9a7;
  /// @dev ERC165 interface ID of ERC721
  bytes4 internal constant _ERC721_INTERFACE_ID = 0x80ac58cd;
  /// @dev ERC165 interface ID of ERC721Metadata
  bytes4 internal constant _ERC721_METADATA_INTERFACE_ID = 0x5b5e139f;

  // *************************************************************
  //                        VARIABLES
  //                Keep names and ordering!
  //                 Add only in the bottom.
  // *************************************************************

  /// @dev Underlying tokens info
  address[] public override tokens;
  /// @dev token => weight
  mapping(address => uint) public tokenWeights;
  /// @dev token => is allowed for deposits
  mapping(address => bool) public isValidToken;
  /// @dev Current count of token
  uint public tokenId;
  /// @dev veId => stakingToken => Locked amount
  mapping(uint => mapping(address => uint)) public override lockedAmounts;
  /// @dev veId => Amount based on weights aka power
  mapping(uint => uint) public override lockedDerivedAmount;
  /// @dev veId => Lock end timestamp
  mapping(uint => uint) public override lockedEnd;

  // --- CHECKPOINTS LOGIC

  /// @dev Epoch counter. Update each week.
  uint public override epoch;
  /// @dev epoch -> unsigned point
  mapping(uint => Point) internal _pointHistory;
  /// @dev user -> Point[userEpoch]
  mapping(uint => Point[1000000000]) internal _userPointHistory;
  /// @dev veId -> Personal epoch counter
  mapping(uint => uint) public override userPointEpoch;
  /// @dev time -> signed slope change
  mapping(uint => int128) public slopeChanges;

  // --- LOCK

  /// @dev veId -> Attachments counter. With positive counter user unable to transfer NFT
  mapping(uint => uint) public override attachments;
  /// @dev veId -> votes counter. With votes NFT unable to transfer
  mapping(uint => uint) public override voted;

  // --- STATISTICS

  /// @dev veId -> Block number when last time NFT owner changed
  mapping(uint => uint) public ownershipChange;
  /// @dev Mapping from NFT ID to the address that owns it.
  mapping(uint => address) internal _idToOwner;
  /// @dev Mapping from NFT ID to approved address.
  mapping(uint => address) internal _idToApprovals;
  /// @dev Mapping from owner address to count of his tokens.
  mapping(address => uint) internal _ownerToNFTokenCount;
  /// @dev Mapping from owner address to mapping of index to tokenIds
  mapping(address => mapping(uint => uint)) internal _ownerToNFTokenIdList;
  /// @dev Mapping from NFT ID to index of owner
  mapping(uint => uint) public tokenToOwnerIndex;
  /// @dev Mapping from owner address to mapping of operator addresses.
  mapping(address => mapping(address => bool)) public ownerToOperators;

  /// @dev Mapping of interface id to bool about whether or not it's supported
  mapping(bytes4 => bool) internal _supportedInterfaces;

  // --- PERMISSIONS

  /// @dev Whitelisted contracts will be able to transfer NFTs
  mapping(address => bool) public isWhitelistedTransfer;

  // *************************************************************
  //                        EVENTS
  // *************************************************************

  event Deposit(
    address indexed stakingToken,
    address indexed provider,
    uint tokenId,
    uint value,
    uint indexed locktime,
    DepositType depositType,
    uint ts
  );
  event Withdraw(address indexed stakingToken, address indexed provider, uint tokenId, uint value, uint ts);
  event Merged(address indexed stakingToken, address indexed provider, uint from, uint to);
  event Split(uint parentTokenId, uint newTokenId, uint percent);
  event TransferWhitelisted(address value);

  // *************************************************************
  //                        INIT
  // *************************************************************

  /// @dev Proxy initialization. Call it after contract deploy.
  /// @param token_ Underlying ERC20 token
  /// @param controller_ Central contract of the protocol
  function init(address token_, uint weight, address controller_) external initializer {
    __Controllable_init(controller_);

    // the first token should have 18 decimals
    require(IERC20Metadata(token_).decimals() == uint8(18), WRONG_DECIMALS);
    _addToken(token_, weight);

    _pointHistory[0].blk = block.number;
    _pointHistory[0].ts = block.timestamp;

    _supportedInterfaces[_ERC165_INTERFACE_ID] = true;
    _supportedInterfaces[_ERC721_INTERFACE_ID] = true;
    _supportedInterfaces[_ERC721_METADATA_INTERFACE_ID] = true;

    // mint-ish
    emit Transfer(address(0), address(this), 0);
    // burn-ish
    emit Transfer(address(this), address(0), 0);
  }

  // *************************************************************
  //                        GOVERNANCE ACTIONS
  // *************************************************************

  /// @dev Whitelist address for transfers. Removing from whitelist should be forbidden.
  function whitelistTransferFor(address value) external {
    require(isGovernance(msg.sender), NOT_GOVERNANCE);
    require(value != address(0), WRONG_INPUT);
    isWhitelistedTransfer[value] = true;
    emit TransferWhitelisted(value);
  }

  function addToken(address token, uint weight) external {
    require(isGovernance(msg.sender), NOT_GOVERNANCE);
    _addToken(token, weight);
  }

  function _addToken(address token, uint weight) internal {
    require(token != address(0) && weight != 0, WRONG_INPUT);
    _requireERC20(token);

    tokens.push(token);
    tokenWeights[token] = weight;
    isValidToken[token] = true;
  }

  // *************************************************************
  //                        VIEWS
  // *************************************************************

  /// @dev Return length of staking tokens.
  function tokensLength() external view returns (uint) {
    return tokens.length;
  }

  /// @dev Current block timestamp
  function blockTimestamp() external view returns (uint) {
    return block.timestamp;
  }

  /// @dev Voter should handle attach/detach and vote actions
  function voter() public view returns (address) {
    return IController(controller()).voter();
  }

  /// @dev Specific voter for control platform attributes.
  function platformVoter() public view returns (address) {
    return IController(controller()).platformVoter();
  }

  /// @dev Interface identification is specified in ERC-165.
  /// @param _interfaceID Id of the interface
  function supportsInterface(bytes4 _interfaceID) public view override(ControllableV3, IERC165) returns (bool) {
    return _supportedInterfaces[_interfaceID]
    || _interfaceID == InterfaceIds.I_VE_TETU
    || super.supportsInterface(_interfaceID);
  }

  /// @notice Get the most recently recorded rate of voting power decrease for `_tokenId`
  /// @param _tokenId token of the NFT
  /// @return Value of the slope
  function getLastUserSlope(uint _tokenId) external view returns (int128) {
    uint uEpoch = userPointEpoch[_tokenId];
    return _userPointHistory[_tokenId][uEpoch].slope;
  }

  /// @notice Get the timestamp for checkpoint `_idx` for `_tokenId`
  /// @param _tokenId token of the NFT
  /// @param _idx User epoch number
  /// @return Epoch time of the checkpoint
  function userPointHistoryTs(uint _tokenId, uint _idx) external view returns (uint) {
    return _userPointHistory[_tokenId][_idx].ts;
  }

  /// @dev Returns the number of NFTs owned by `_owner`.
  ///      Throws if `_owner` is the zero address. NFTs assigned to the zero address are considered invalid.
  /// @param _owner Address for whom to query the balance.
  function _balance(address _owner) internal view returns (uint) {
    return _ownerToNFTokenCount[_owner];
  }

  /// @dev Returns the number of NFTs owned by `_owner`.
  ///      Throws if `_owner` is the zero address. NFTs assigned to the zero address are considered invalid.
  /// @param _owner Address for whom to query the balance.
  function balanceOf(address _owner) external view override returns (uint) {
    return _balance(_owner);
  }

  /// @dev Returns the address of the owner of the NFT.
  /// @param _tokenId The identifier for an NFT.
  function ownerOf(uint _tokenId) public view override returns (address) {
    return _idToOwner[_tokenId];
  }

  /// @dev Get the approved address for a single NFT.
  /// @param _tokenId ID of the NFT to query the approval of.
  function getApproved(uint _tokenId) external view override returns (address) {
    return _idToApprovals[_tokenId];
  }

  /// @dev Checks if `_operator` is an approved operator for `_owner`.
  /// @param _owner The address that owns the NFTs.
  /// @param _operator The address that acts on behalf of the owner.
  function isApprovedForAll(address _owner, address _operator) external view override returns (bool) {
    return (ownerToOperators[_owner])[_operator];
  }

  /// @dev  Get token by index
  function tokenOfOwnerByIndex(address _owner, uint _tokenIndex) external view returns (uint) {
    return _ownerToNFTokenIdList[_owner][_tokenIndex];
  }

  /// @dev Returns whether the given spender can transfer a given token ID
  /// @param _spender address of the spender to query
  /// @param _tokenId uint ID of the token to be transferred
  /// @return bool whether the msg.sender is approved for the given token ID,
  ///              is an operator of the owner, or is the owner of the token
  function isApprovedOrOwner(address _spender, uint _tokenId) public view override returns (bool) {
    address owner = _idToOwner[_tokenId];
    bool spenderIsOwner = owner == _spender;
    bool spenderIsApproved = _spender == _idToApprovals[_tokenId];
    bool spenderIsApprovedForAll = (ownerToOperators[owner])[_spender];
    return spenderIsOwner || spenderIsApproved || spenderIsApprovedForAll;
  }

  function balanceOfNFT(uint _tokenId) public view override returns (uint) {
    // flash NFT protection
    if (ownershipChange[_tokenId] == block.number) {
      return 0;
    }
    return _balanceOfNFT(_tokenId, block.timestamp);
  }

  function balanceOfNFTAt(uint _tokenId, uint _t) external view returns (uint) {
    return _balanceOfNFT(_tokenId, _t);
  }

  function totalSupply() external view returns (uint) {
    return totalSupplyAtT(block.timestamp);
  }

  function balanceOfAtNFT(uint _tokenId, uint _block) external view returns (uint) {
    return _balanceOfAtNFT(_tokenId, _block);
  }

  function userPointHistory(uint _tokenId, uint _loc) external view override returns (Point memory) {
    return _userPointHistory[_tokenId][_loc];
  }

  function pointHistory(uint _loc) external view override returns (Point memory) {
    return _pointHistory[_loc];
  }

  // *************************************************************
  //                        VOTER ACTIONS
  // *************************************************************

  function _onlyVoters() internal view {
    require(msg.sender == voter() || msg.sender == platformVoter(), NOT_VOTER);
  }

  /// @dev Increment the votes counter.
  ///      Should be called only once per any amount of votes from 1 voter contract.
  function voting(uint _tokenId) external override {
    _onlyVoters();

    // counter reflects only amount of voter contracts
    // restrictions for votes should be implemented on voter side
    voted[_tokenId]++;
  }

  /// @dev Decrement the votes counter. Call only once per voter.
  function abstain(uint _tokenId) external override {
    _onlyVoters();

    voted[_tokenId]--;
  }

  /// @dev Increment attach counter. Call it for each boosted gauge position.
  function attachToken(uint _tokenId) external override {
    // only central voter
    require(msg.sender == voter(), NOT_VOTER);

    uint count = attachments[_tokenId];
    require(count < MAX_ATTACHMENTS, TOO_MANY_ATTACHMENTS);
    attachments[_tokenId] = count + 1;
  }

  /// @dev Decrement attach counter. Call it for each boosted gauge position.
  function detachToken(uint _tokenId) external override {
    // only central voter
    require(msg.sender == voter(), NOT_VOTER);

    attachments[_tokenId] = attachments[_tokenId] - 1;
  }

  /// @dev Remove all votes/attachments for given veID.
  function _detachAll(uint _tokenId, address owner) internal {
    IVoter(voter()).detachTokenFromAll(_tokenId, owner);
    IPlatformVoter(platformVoter()).detachTokenFromAll(_tokenId, owner);
  }

  // *************************************************************
  //                        NFT LOGIC
  // *************************************************************

  /// @dev Add a NFT to an index mapping to a given address
  /// @param _to address of the receiver
  /// @param _tokenId uint ID Of the token to be added
  function _addTokenToOwnerList(address _to, uint _tokenId) internal {
    uint currentCount = _balance(_to);

    _ownerToNFTokenIdList[_to][currentCount] = _tokenId;
    tokenToOwnerIndex[_tokenId] = currentCount;
  }

  /// @dev Remove a NFT from an index mapping to a given address
  /// @param _from address of the sender
  /// @param _tokenId uint ID Of the token to be removed
  function _removeTokenFromOwnerList(address _from, uint _tokenId) internal {
    // Delete
    uint currentCount = _balance(_from) - 1;
    uint currentIndex = tokenToOwnerIndex[_tokenId];

    if (currentCount == currentIndex) {
      // update ownerToNFTokenIdList
      _ownerToNFTokenIdList[_from][currentCount] = 0;
      // update tokenToOwnerIndex
      tokenToOwnerIndex[_tokenId] = 0;
    } else {
      uint lastTokenId = _ownerToNFTokenIdList[_from][currentCount];

      // Add
      // update ownerToNFTokenIdList
      _ownerToNFTokenIdList[_from][currentIndex] = lastTokenId;
      // update tokenToOwnerIndex
      tokenToOwnerIndex[lastTokenId] = currentIndex;

      // Delete
      // update ownerToNFTokenIdList
      _ownerToNFTokenIdList[_from][currentCount] = 0;
      // update tokenToOwnerIndex
      tokenToOwnerIndex[_tokenId] = 0;
    }
  }

  /// @dev Add a NFT to a given address
  ///      Throws if `_tokenId` is owned by someone.
  function _addTokenTo(address _to, uint _tokenId) internal {
    // assume always call on new tokenId or after _removeTokenFrom() call
    // Change the owner
    _idToOwner[_tokenId] = _to;
    // Update owner token index tracking
    _addTokenToOwnerList(_to, _tokenId);
    // Change count tracking
    _ownerToNFTokenCount[_to] += 1;
  }

  /// @dev Remove a NFT from a given address
  ///      Throws if `_from` is not the current owner.
  function _removeTokenFrom(address _from, uint _tokenId) internal {
    require(_idToOwner[_tokenId] == _from, NOT_OWNER);
    // Change the owner
    _idToOwner[_tokenId] = address(0);
    // Update owner token index tracking
    _removeTokenFromOwnerList(_from, _tokenId);
    // Change count tracking
    _ownerToNFTokenCount[_from] -= 1;
  }

  /// @dev Execute transfer of a NFT.
  ///      Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
  ///      address for this NFT. (NOTE: `msg.sender` not allowed in internal function so pass `_sender`.)
  ///      Throws if `_to` is the zero address.
  ///      Throws if `_from` is not the current owner.
  ///      Throws if `_tokenId` is not a valid NFT.
  function _transferFrom(
    address _from,
    address _to,
    uint _tokenId,
    address _sender
  ) internal {
    require(isApprovedOrOwner(_sender, _tokenId), NOT_OWNER);
    require(_to != address(0), WRONG_INPUT);
    // from address will be checked in _removeTokenFrom()

    if (attachments[_tokenId] != 0 || voted[_tokenId] != 0) {
      _detachAll(_tokenId, _from);
    }

    if (_idToApprovals[_tokenId] != address(0)) {
      // Reset approvals
      _idToApprovals[_tokenId] = address(0);
    }
    _removeTokenFrom(_from, _tokenId);
    _addTokenTo(_to, _tokenId);
    // Set the block of ownership transfer (for Flash NFT protection)
    ownershipChange[_tokenId] = block.number;
    // Log the transfer
    emit Transfer(_from, _to, _tokenId);
  }

  /// @dev Transfers forbidden for veTETU
  function transferFrom(
    address,
    address,
    uint
  ) external pure override {
    revert(FORBIDDEN);
    //    _transferFrom(_from, _to, _tokenId, msg.sender);
  }

  function _isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.
    uint size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  /// @dev Transfers the ownership of an NFT from one address to another address.
  ///      Throws unless `msg.sender` is the current owner, an authorized operator, or the
  ///      approved address for this NFT.
  ///      Throws if `_from` is not the current owner.
  ///      Throws if `_to` is the zero address.
  ///      Throws if `_tokenId` is not a valid NFT.
  ///      If `_to` is a smart contract, it calls `onERC721Received` on `_to` and throws if
  ///      the return value is not `bytes4(keccak256("onERC721Received(address,address,uint,bytes)"))`.
  /// @param _from The current owner of the NFT.
  /// @param _to The new owner.
  /// @param _tokenId The NFT to transfer.
  /// @param _data Additional data with no specified format, sent in call to `_to`.
  function safeTransferFrom(
    address _from,
    address _to,
    uint _tokenId,
    bytes memory _data
  ) public override {
    require(isWhitelistedTransfer[_to] || isWhitelistedTransfer[_from], FORBIDDEN);

    _transferFrom(_from, _to, _tokenId, msg.sender);

    if (_isContract(_to)) {
      // Throws if transfer destination is a contract which does not implement 'onERC721Received'
      try IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) returns (bytes4) {} catch (
        bytes memory reason
      ) {
        if (reason.length == 0) {
          revert("ERC721: transfer to non ERC721Receiver implementer");
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    }
  }

  /// @dev Transfers the ownership of an NFT from one address to another address.
  ///      Throws unless `msg.sender` is the current owner, an authorized operator, or the
  ///      approved address for this NFT.
  ///      Throws if `_from` is not the current owner.
  ///      Throws if `_to` is the zero address.
  ///      Throws if `_tokenId` is not a valid NFT.
  ///      If `_to` is a smart contract, it calls `onERC721Received` on `_to` and throws if
  ///      the return value is not `bytes4(keccak256("onERC721Received(address,address,uint,bytes)"))`.
  /// @param _from The current owner of the NFT.
  /// @param _to The new owner.
  /// @param _tokenId The NFT to transfer.
  function safeTransferFrom(
    address _from,
    address _to,
    uint _tokenId
  ) external override {
    safeTransferFrom(_from, _to, _tokenId, "");
  }

  /// @dev Set or reaffirm the approved address for an NFT. The zero address indicates there is no approved address.
  ///      Throws unless `msg.sender` is the current NFT owner, or an authorized operator of the current owner.
  ///      Throws if `_tokenId` is not a valid NFT. (NOTE: This is not written the EIP)
  ///      Throws if `_approved` is the current owner. (NOTE: This is not written the EIP)
  /// @param _approved Address to be approved for the given NFT ID.
  /// @param _tokenId ID of the token to be approved.
  function approve(address _approved, uint _tokenId) public override {
    address owner = _idToOwner[_tokenId];
    // Throws if `_tokenId` is not a valid NFT
    require(owner != address(0), WRONG_INPUT);
    // Throws if `_approved` is the current owner
    require(_approved != owner, IDENTICAL_ADDRESS);
    // Check requirements
    bool senderIsOwner = (owner == msg.sender);
    bool senderIsApprovedForAll = (ownerToOperators[owner])[msg.sender];
    require(senderIsOwner || senderIsApprovedForAll, NOT_OWNER);
    // Set the approval
    _idToApprovals[_tokenId] = _approved;
    emit Approval(owner, _approved, _tokenId);
  }

  /// @dev Enables or disables approval for a third party ("operator") to manage all of
  ///      `msg.sender`'s assets. It also emits the ApprovalForAll event.
  ///      Throws if `_operator` is the `msg.sender`. (NOTE: This is not written the EIP)
  /// @notice This works even if sender doesn't own any tokens at the time.
  /// @param _operator Address to add to the set of authorized operators.
  /// @param _approved True if the operators is approved, false to revoke approval.
  function setApprovalForAll(address _operator, bool _approved) external override {
    // Throws if `_operator` is the `msg.sender`
    require(_operator != msg.sender, IDENTICAL_ADDRESS);
    ownerToOperators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  /// @dev Function to mint tokens
  ///      Throws if `_to` is zero address.
  ///      Throws if `_tokenId` is owned by someone.
  /// @param _to The address that will receive the minted tokens.
  /// @param _tokenId The token id to mint.
  /// @return A boolean that indicates if the operation was successful.
  function _mint(address _to, uint _tokenId) internal returns (bool) {
    // Throws if `_to` is zero address
    require(_to != address(0), WRONG_INPUT);
    // Add NFT. Throws if `_tokenId` is owned by someone
    _addTokenTo(_to, _tokenId);
    emit Transfer(address(0), _to, _tokenId);
    return true;
  }

  /// @notice Record global and per-user data to checkpoint
  function _checkpoint(CheckpointInfo memory info) internal {
    Point memory uOld;
    Point memory uNew;
    int128 oldDSlope = 0;
    int128 newDSlope = 0;
    uint _epoch = epoch;

    if (info.tokenId != 0) {
      // Calculate slopes and biases
      // Kept at zero when they have to
      if (info.oldEnd > block.timestamp && info.oldDerivedAmount > 0) {
        uOld.slope = int128(uint128(info.oldDerivedAmount)) / I_MAX_TIME;
        uOld.bias = uOld.slope * int128(int256(info.oldEnd - block.timestamp));
      }
      if (info.newEnd > block.timestamp && info.newDerivedAmount > 0) {
        uNew.slope = int128(uint128(info.newDerivedAmount)) / I_MAX_TIME;
        uNew.bias = uNew.slope * int128(int256(info.newEnd - block.timestamp));
      }

      // Read values of scheduled changes in the slope
      // oldLocked.end can be in the past and in the future
      // newLocked.end can ONLY by in the FUTURE unless everything expired: than zeros
      oldDSlope = slopeChanges[info.oldEnd];
      if (info.newEnd != 0) {
        if (info.newEnd == info.oldEnd) {
          newDSlope = oldDSlope;
        } else {
          newDSlope = slopeChanges[info.newEnd];
        }
      }
    }

    Point memory lastPoint = Point({bias : 0, slope : 0, ts : block.timestamp, blk : block.number});
    if (_epoch > 0) {
      lastPoint = _pointHistory[_epoch];
    }
    uint lastCheckpoint = lastPoint.ts;
    // initialLastPoint is used for extrapolation to calculate block number
    // (approximately, for *At methods) and save them
    // as we cannot figure that out exactly from inside the contract
    Point memory initialLastPoint = lastPoint;
    uint blockSlope = 0;
    // dblock/dt
    if (block.timestamp > lastPoint.ts) {
      blockSlope = (MULTIPLIER * (block.number - lastPoint.blk)) / (block.timestamp - lastPoint.ts);
    }
    // If last point is already recorded in this block, slope=0
    // But that's ok b/c we know the block in such case

    // Go over weeks to fill history and calculate what the current point is
    {
      uint ti = (lastCheckpoint / WEEK) * WEEK;
      // Hopefully it won't happen that this won't get used in 5 years!
      // If it does, users will be able to withdraw but vote weight will be broken
      for (uint i = 0; i < 255; ++i) {
        ti += WEEK;
        int128 dSlope = 0;
        if (ti > block.timestamp) {
          ti = block.timestamp;
        } else {
          dSlope = slopeChanges[ti];
        }
        lastPoint.bias = (lastPoint.bias - lastPoint.slope * int128(int256(ti - lastCheckpoint))).positiveInt128();
        lastPoint.slope = (lastPoint.slope + dSlope).positiveInt128();
        lastCheckpoint = ti;
        lastPoint.ts = ti;
        lastPoint.blk = initialLastPoint.blk + (blockSlope * (ti - initialLastPoint.ts)) / MULTIPLIER;
        _epoch += 1;
        if (ti == block.timestamp) {
          lastPoint.blk = block.number;
          break;
        } else {
          _pointHistory[_epoch] = lastPoint;
        }
      }
    }

    epoch = _epoch;
    // Now pointHistory is filled until t=now

    if (info.tokenId != 0) {
      // If last point was in this block, the slope change has been applied already
      // But in such case we have 0 slope(s)
      lastPoint.slope = (lastPoint.slope + (uNew.slope - uOld.slope)).positiveInt128();
      lastPoint.bias = (lastPoint.bias + (uNew.bias - uOld.bias)).positiveInt128();
    }

    // Record the changed point into history
    _pointHistory[_epoch] = lastPoint;

    if (info.tokenId != 0) {
      // Schedule the slope changes (slope is going down)
      // We subtract newUserSlope from [newLocked.end]
      // and add old_user_slope to [old_locked.end]
      if (info.oldEnd > block.timestamp) {
        // old_dslope was <something> - u_old.slope, so we cancel that
        oldDSlope += uOld.slope;
        if (info.newEnd == info.oldEnd) {
          oldDSlope -= uNew.slope;
          // It was a new deposit, not extension
        }
        slopeChanges[info.oldEnd] = oldDSlope;
      }

      if (info.newEnd > block.timestamp) {
        if (info.newEnd > info.oldEnd) {
          newDSlope -= uNew.slope;
          // old slope disappeared at this point
          slopeChanges[info.newEnd] = newDSlope;
        }
        // else: we recorded it already in oldDSlope
      }
      // Now handle user history
      uint userEpoch = userPointEpoch[info.tokenId] + 1;

      userPointEpoch[info.tokenId] = userEpoch;
      uNew.ts = block.timestamp;
      uNew.blk = block.number;
      _userPointHistory[info.tokenId][userEpoch] = uNew;
    }
  }

  // *************************************************************
  //                  DEPOSIT/WITHDRAW LOGIC
  // *************************************************************

  /// @notice Deposit and lock tokens for a user
  function _depositFor(DepositInfo memory info) internal {

    uint newLockedDerivedAmount = info.lockedDerivedAmount;
    if (info.value != 0) {

      // calculate new amounts
      uint newAmount = info.lockedAmount + info.value;
      newLockedDerivedAmount = _calculateDerivedAmount(
        info.lockedAmount,
        info.lockedDerivedAmount,
        newAmount,
        tokenWeights[info.stakingToken],
        IERC20Metadata(info.stakingToken).decimals()
      );
      // update chain info
      lockedAmounts[info.tokenId][info.stakingToken] = newAmount;
      lockedDerivedAmount[info.tokenId] = newLockedDerivedAmount;
    }

    // Adding to existing lock, or if a lock is expired - creating a new one
    uint newLockedEnd = info.lockedEnd;
    if (info.unlockTime != 0) {
      lockedEnd[info.tokenId] = info.unlockTime;
      newLockedEnd = info.unlockTime;
    }

    // update checkpoint
    _checkpoint(CheckpointInfo(
        info.tokenId,
        info.lockedDerivedAmount,
        newLockedDerivedAmount,
        info.lockedEnd,
        newLockedEnd
      ));

    // move tokens to this contract, if necessary
    address from = msg.sender;
    if (info.value != 0 && info.depositType != DepositType.MERGE_TYPE) {
      IERC20(info.stakingToken).safeTransferFrom(from, address(this), info.value);
    }

    emit Deposit(info.stakingToken, from, info.tokenId, info.value, newLockedEnd, info.depositType, block.timestamp);
  }

  function _calculateDerivedAmount(
    uint currentAmount,
    uint oldDerivedAmount,
    uint newAmount,
    uint weight,
    uint8 decimals
  ) internal pure returns (uint) {
    // subtract current derived balance
    // rounded to UP for subtracting closer to 0 value
    if (oldDerivedAmount != 0 && currentAmount != 0) {
      currentAmount = currentAmount.divWadUp(10 ** decimals);
      uint currentDerivedAmount = currentAmount.mulDivUp(weight, WEIGHT_DENOMINATOR);
      if (oldDerivedAmount > currentDerivedAmount) {
        oldDerivedAmount -= currentDerivedAmount;
      } else {
        // in case of wrong rounding better to set to zero than revert
        oldDerivedAmount = 0;
      }
    }

    // recalculate derived amount with new amount
    // rounded to DOWN
    // normalize decimals to 18
    newAmount = newAmount.divWadDown(10 ** decimals);
    // calculate the final amount based on the weight
    newAmount = newAmount.mulDivDown(weight, WEIGHT_DENOMINATOR);
    return oldDerivedAmount + newAmount;
  }

  /// @notice Record global data to checkpoint
  function checkpoint() external override {
    _checkpoint(CheckpointInfo(0, 0, 0, 0, 0));
  }

  function _lockInfo(address stakingToken, uint veId) internal view returns (
    uint _lockedAmount,
    uint _lockedDerivedAmount,
    uint _lockedEnd
  ) {
    _lockedAmount = lockedAmounts[veId][stakingToken];
    _lockedDerivedAmount = lockedDerivedAmount[veId];
    _lockedEnd = lockedEnd[veId];
  }

  function _incrementTokenIdAndGet() internal returns (uint){
    uint current = tokenId;
    tokenId = current + 1;
    return current + 1;
  }

  /// @notice Deposit `_value` tokens for `_to` and lock for `_lock_duration`
  /// @param _token Token for deposit. Should be whitelisted in this contract.
  /// @param _value Amount to deposit
  /// @param _lockDuration Number of seconds to lock tokens for (rounded down to nearest week)
  /// @param _to Address to deposit
  function _createLock(address _token, uint _value, uint _lockDuration, address _to) internal returns (uint) {
    require(_value > 0, WRONG_INPUT);
    // Lock time is rounded down to weeks
    uint unlockTime = (block.timestamp + _lockDuration) / WEEK * WEEK;
    require(unlockTime > block.timestamp, LOW_LOCK_PERIOD);
    require(unlockTime <= block.timestamp + MAX_TIME, HIGH_LOCK_PERIOD);
    require(isValidToken[_token], INVALID_TOKEN);

    uint _tokenId = _incrementTokenIdAndGet();
    _mint(_to, _tokenId);

    _depositFor(DepositInfo({
    stakingToken : _token,
    tokenId : _tokenId,
    value : _value,
    unlockTime : unlockTime,
    lockedAmount : 0,
    lockedDerivedAmount : 0,
    lockedEnd : 0,
    depositType : DepositType.CREATE_LOCK_TYPE
    }));
    return _tokenId;
  }

  /// @notice Deposit `_value` tokens for `_to` and lock for `_lock_duration`
  /// @param _token Token for deposit. Should be whitelisted in this contract.
  /// @param _value Amount to deposit
  /// @param _lockDuration Number of seconds to lock tokens for (rounded down to nearest week)
  /// @param _to Address to deposit
  function createLockFor(address _token, uint _value, uint _lockDuration, address _to)
  external nonReentrant override returns (uint) {
    return _createLock(_token, _value, _lockDuration, _to);
  }

  /// @notice Deposit `_value` tokens for `msg.sender` and lock for `_lock_duration`
  /// @param _value Amount to deposit
  /// @param _lockDuration Number of seconds to lock tokens for (rounded down to nearest week)
  function createLock(address _token, uint _value, uint _lockDuration) external nonReentrant returns (uint) {
    return _createLock(_token, _value, _lockDuration, msg.sender);
  }

  /// @notice Deposit `_value` additional tokens for `_tokenId` without modifying the unlock time
  /// @dev Anyone (even a smart contract) can deposit for someone else, but
  ///      cannot extend their locktime and deposit for a brand new user
  /// @param _token Token for deposit. Should be whitelisted in this contract.
  /// @param _tokenId ve token ID
  /// @param _value Amount of tokens to deposit and add to the lock
  function increaseAmount(address _token, uint _tokenId, uint _value) external nonReentrant override {
    require(_value > 0, WRONG_INPUT);
    (uint _lockedAmount, uint _lockedDerivedAmount, uint _lockedEnd) = _lockInfo(_token, _tokenId);

    require(_lockedDerivedAmount > 0, NFT_WITHOUT_POWER);
    require(_lockedEnd > block.timestamp, EXPIRED);
    require(isValidToken[_token], INVALID_TOKEN);

    _depositFor(DepositInfo({
    stakingToken : _token,
    tokenId : _tokenId,
    value : _value,
    unlockTime : 0,
    lockedAmount : _lockedAmount,
    lockedDerivedAmount : _lockedDerivedAmount,
    lockedEnd : _lockedEnd,
    depositType : DepositType.INCREASE_LOCK_AMOUNT
    }));
  }

  /// @notice Extend the unlock time for `_tokenId`
  /// @param _tokenId ve token ID
  /// @param _lockDuration New number of seconds until tokens unlock
  function increaseUnlockTime(uint _tokenId, uint _lockDuration) external nonReentrant returns (
    uint power,
    uint unlockDate
  )  {
    uint _lockedDerivedAmount = lockedDerivedAmount[_tokenId];
    uint _lockedEnd = lockedEnd[_tokenId];
    // Lock time is rounded down to weeks
    uint unlockTime = (block.timestamp + _lockDuration) / WEEK * WEEK;
    require(_lockedDerivedAmount > 0, NFT_WITHOUT_POWER);
    require(_lockedEnd > block.timestamp, EXPIRED);
    require(unlockTime > _lockedEnd, LOW_UNLOCK_TIME);
    require(unlockTime <= block.timestamp + MAX_TIME, HIGH_LOCK_PERIOD);
    require(isApprovedOrOwner(msg.sender, _tokenId), NOT_OWNER);

    _depositFor(DepositInfo({
    stakingToken : address(0),
    tokenId : _tokenId,
    value : 0,
    unlockTime : unlockTime,
    lockedAmount : 0,
    lockedDerivedAmount : _lockedDerivedAmount,
    lockedEnd : _lockedEnd,
    depositType : DepositType.INCREASE_UNLOCK_TIME
    }));

    power = balanceOfNFT(_tokenId);
    unlockDate = lockedEnd[_tokenId];
  }

  /// @dev Merge two NFTs union their balances and keep the biggest lock time.
  function merge(uint _from, uint _to) external nonReentrant {
    require(attachments[_from] == 0 && voted[_from] == 0, ATTACHED);
    require(_from != _to, IDENTICAL_ADDRESS);
    require(_idToOwner[_from] == msg.sender && _idToOwner[_to] == msg.sender, NOT_OWNER);

    uint lockedEndFrom = lockedEnd[_from];
    uint lockedEndTo = lockedEnd[_to];
    uint end = lockedEndFrom >= lockedEndTo ? lockedEndFrom : lockedEndTo;
    uint oldDerivedAmount = lockedDerivedAmount[_from];

    uint length = tokens.length;
    for (uint i; i < length; i++) {
      address stakingToken = tokens[i];
      uint _lockedAmountFrom = lockedAmounts[_from][stakingToken];
      lockedAmounts[_from][stakingToken] = 0;

      _depositFor(DepositInfo({
      stakingToken : stakingToken,
      tokenId : _to,
      value : _lockedAmountFrom,
      unlockTime : end,
      lockedAmount : lockedAmounts[_to][stakingToken],
      lockedDerivedAmount : lockedDerivedAmount[_to],
      lockedEnd : end,
      depositType : DepositType.MERGE_TYPE
      }));

      emit Merged(stakingToken, msg.sender, _from, _to);
    }

    lockedDerivedAmount[_from] = 0;
    lockedEnd[_from] = 0;

    // update checkpoint
    _checkpoint(CheckpointInfo(
        _from,
        oldDerivedAmount,
        0,
        lockedEndFrom,
        lockedEndFrom
      ));

    _burn(_from);
  }

  /// @dev Split given veNFT. A new NFT will have a given percent of underlying tokens.
  /// @param _tokenId ve token ID
  /// @param percent percent of underlying tokens for new NFT with denominator 1e18 (1-(100e18-1)).
  function split(uint _tokenId, uint percent) external nonReentrant {
    require(attachments[_tokenId] == 0 && voted[_tokenId] == 0, ATTACHED);
    require(_idToOwner[_tokenId] == msg.sender, NOT_OWNER);
    require(percent != 0 && percent < 100e18, WRONG_INPUT);

    uint _lockedDerivedAmount = lockedDerivedAmount[_tokenId];
    uint oldLockedDerivedAmount = _lockedDerivedAmount;
    uint _lockedEnd = lockedEnd[_tokenId];

    require(_lockedEnd > block.timestamp, EXPIRED);

    // crete new NFT
    uint _newTokenId = _incrementTokenIdAndGet();
    _mint(msg.sender, _newTokenId);

    // migrate percent of locked tokens to the new NFT
    uint length = tokens.length;
    for (uint i; i < length; ++i) {
      address stakingToken = tokens[i];
      uint _lockedAmount = lockedAmounts[_tokenId][stakingToken];
      uint amountForNewNFT = _lockedAmount * percent / 100e18;
      require(amountForNewNFT != 0, LOW_PERCENT);

      uint newLockedDerivedAmount = _calculateDerivedAmount(
        _lockedAmount,
        _lockedDerivedAmount,
        _lockedAmount - amountForNewNFT,
        tokenWeights[stakingToken],
        IERC20Metadata(stakingToken).decimals()
      );

      _lockedDerivedAmount = newLockedDerivedAmount;

      lockedAmounts[_tokenId][stakingToken] = _lockedAmount - amountForNewNFT;

      // increase values for new NFT
      _depositFor(DepositInfo({
      stakingToken : stakingToken,
      tokenId : _newTokenId,
      value : amountForNewNFT,
      unlockTime : _lockedEnd,
      lockedAmount : 0,
      lockedDerivedAmount : lockedDerivedAmount[_newTokenId],
      lockedEnd : _lockedEnd,
      depositType : DepositType.MERGE_TYPE
      }));
    }

    // update derived amount
    lockedDerivedAmount[_tokenId] = _lockedDerivedAmount;

    // update checkpoint
    _checkpoint(CheckpointInfo(
        _tokenId,
        oldLockedDerivedAmount,
        _lockedDerivedAmount,
        _lockedEnd,
        _lockedEnd
      ));

    emit Split(_tokenId, _newTokenId, percent);
  }

  /// @notice Withdraw all staking tokens for `_tokenId`
  /// @dev Only possible if the lock has expired
  function withdrawAll(uint _tokenId) external {
    uint length = tokens.length;
    for (uint i; i < length; ++i) {
      withdraw(tokens[i], _tokenId);
    }
  }

  /// @notice Withdraw given staking token for `_tokenId`
  /// @dev Only possible if the lock has expired
  function withdraw(address stakingToken, uint _tokenId) public nonReentrant {
    require(isApprovedOrOwner(msg.sender, _tokenId), NOT_OWNER);
    require(attachments[_tokenId] == 0 && voted[_tokenId] == 0, ATTACHED);

    (uint oldLockedAmount, uint oldLockedDerivedAmount, uint oldLockedEnd) =
    _lockInfo(stakingToken, _tokenId);
    require(block.timestamp >= oldLockedEnd, NOT_EXPIRED);
    require(oldLockedAmount > 0, ZERO_LOCKED);


    uint newLockedDerivedAmount = _calculateDerivedAmount(
      oldLockedAmount,
      oldLockedDerivedAmount,
      0,
      tokenWeights[stakingToken],
      IERC20Metadata(stakingToken).decimals()
    );

    // if no tokens set lock to zero
    uint newLockEnd = oldLockedEnd;
    if (newLockedDerivedAmount == 0) {
      lockedEnd[_tokenId] = 0;
      newLockEnd = 0;
    }

    // update derived amount
    lockedDerivedAmount[_tokenId] = newLockedDerivedAmount;

    // set locked amount to zero, we will withdraw all
    lockedAmounts[_tokenId][stakingToken] = 0;

    // update checkpoint
    _checkpoint(CheckpointInfo(
        _tokenId,
        oldLockedDerivedAmount,
        newLockedDerivedAmount,
        oldLockedEnd,
        newLockEnd
      ));

    // Burn the NFT
    if (newLockedDerivedAmount == 0) {
      _burn(_tokenId);
    }

    IERC20(stakingToken).safeTransfer(msg.sender, oldLockedAmount);


    emit Withdraw(stakingToken, msg.sender, _tokenId, oldLockedAmount, block.timestamp);
  }

  // The following ERC20/minime-compatible methods are not real balanceOf and supply!
  // They measure the weights for the purpose of voting, so they don't represent
  // real coins.

  /// @notice Binary search to estimate timestamp for block number
  /// @param _block Block to find
  /// @param maxEpoch Don't go beyond this epoch
  /// @return Approximate timestamp for block
  function _findBlockEpoch(uint _block, uint maxEpoch) internal view returns (uint) {
    // Binary search
    uint _min = 0;
    uint _max = maxEpoch;
    for (uint i = 0; i < 128; ++i) {
      // Will be always enough for 128-bit numbers
      if (_min >= _max) {
        break;
      }
      uint _mid = (_min + _max + 1) / 2;
      if (_pointHistory[_mid].blk <= _block) {
        _min = _mid;
      } else {
        _max = _mid - 1;
      }
    }
    return _min;
  }

  /// @notice Get the current voting power for `_tokenId`
  /// @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
  /// @param _tokenId NFT for lock
  /// @param _t Epoch time to return voting power at
  /// @return User voting power
  function _balanceOfNFT(uint _tokenId, uint _t) internal view returns (uint) {
    uint _epoch = userPointEpoch[_tokenId];
    if (_epoch == 0) {
      return 0;
    } else {
      Point memory lastPoint = _userPointHistory[_tokenId][_epoch];
      lastPoint.bias -= lastPoint.slope * int128(int256(_t) - int256(lastPoint.ts));
      if (lastPoint.bias < 0) {
        lastPoint.bias = 0;
      }
      return uint(int256(lastPoint.bias));
    }
  }

  /// @dev Returns current token URI metadata
  /// @param _tokenId Token ID to fetch URI for.
  function tokenURI(uint _tokenId) external view override returns (string memory) {
    require(_idToOwner[_tokenId] != address(0), TOKEN_NOT_EXIST);

    uint _lockedEnd = lockedEnd[_tokenId];
    return
    VeTetuLogo.tokenURI(
      _tokenId,
      _balanceOfNFT(_tokenId, block.timestamp),
      block.timestamp > _lockedEnd ? block.timestamp - _lockedEnd : 0,
      uint(int256(lockedDerivedAmount[_tokenId]))
    );
  }

  /// @notice Measure voting power of `_tokenId` at block height `_block`
  /// @dev Adheres to MiniMe `balanceOfAt` interface: https://github.com/Giveth/minime
  /// @param _tokenId User's wallet NFT
  /// @param _block Block to calculate the voting power at
  /// @return Voting power
  function _balanceOfAtNFT(uint _tokenId, uint _block) internal view returns (uint) {
    // Copying and pasting totalSupply code because Vyper cannot pass by
    // reference yet
    require(_block <= block.number, WRONG_INPUT);

    // Binary search
    uint _min = 0;
    uint _max = userPointEpoch[_tokenId];
    for (uint i = 0; i < 128; ++i) {
      // Will be always enough for 128-bit numbers
      if (_min >= _max) {
        break;
      }
      uint _mid = (_min + _max + 1) / 2;
      if (_userPointHistory[_tokenId][_mid].blk <= _block) {
        _min = _mid;
      } else {
        _max = _mid - 1;
      }
    }

    Point memory uPoint = _userPointHistory[_tokenId][_min];

    uint maxEpoch = epoch;
    uint _epoch = _findBlockEpoch(_block, maxEpoch);
    Point memory point0 = _pointHistory[_epoch];
    uint dBlock = 0;
    uint dt = 0;
    if (_epoch < maxEpoch) {
      Point memory point1 = _pointHistory[_epoch + 1];
      dBlock = point1.blk - point0.blk;
      dt = point1.ts - point0.ts;
    } else {
      dBlock = block.number - point0.blk;
      dt = block.timestamp - point0.ts;
    }
    uint blockTime = point0.ts;
    if (dBlock != 0 && _block > point0.blk) {
      blockTime += (dt * (_block - point0.blk)) / dBlock;
    }

    uPoint.bias -= uPoint.slope * int128(int256(blockTime - uPoint.ts));
    return uint(uint128(uPoint.bias.positiveInt128()));
  }



  /// @notice Calculate total voting power at some point in the past
  /// @param point The point (bias/slope) to start search from
  /// @param t Time to calculate the total voting power at
  /// @return Total voting power at that time
  function _supplyAt(Point memory point, uint t) internal view returns (uint) {
    Point memory lastPoint = point;
    uint ti = (lastPoint.ts / WEEK) * WEEK;
    for (uint i = 0; i < 255; ++i) {
      ti += WEEK;
      int128 dSlope = 0;
      if (ti > t) {
        ti = t;
      } else {
        dSlope = slopeChanges[ti];
      }
      lastPoint.bias -= lastPoint.slope * int128(int256(ti - lastPoint.ts));
      if (ti == t) {
        break;
      }
      lastPoint.slope += dSlope;
      lastPoint.ts = ti;
    }
    return uint(uint128(lastPoint.bias.positiveInt128()));
  }

  /// @notice Calculate total voting power
  /// @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
  /// @return Total voting power
  function totalSupplyAtT(uint t) public view returns (uint) {
    uint _epoch = epoch;
    Point memory lastPoint = _pointHistory[_epoch];
    return _supplyAt(lastPoint, t);
  }

  /// @notice Calculate total voting power at some point in the past
  /// @param _block Block to calculate the total voting power at
  /// @return Total voting power at `_block`
  function totalSupplyAt(uint _block) external view override returns (uint) {
    require(_block <= block.number, WRONG_INPUT);
    uint _epoch = epoch;
    uint targetEpoch = _findBlockEpoch(_block, _epoch);

    Point memory point = _pointHistory[targetEpoch];
    // it is possible only for a block before the launch
    // return 0 as more clear answer than revert
    if (point.blk > _block) {
      return 0;
    }
    uint dt = 0;
    if (targetEpoch < _epoch) {
      Point memory pointNext = _pointHistory[targetEpoch + 1];
      // next point block can not be the same or lower
      dt = ((_block - point.blk) * (pointNext.ts - point.ts)) / (pointNext.blk - point.blk);
    } else {
      if (point.blk != block.number) {
        dt = ((_block - point.blk) * (block.timestamp - point.ts)) / (block.number - point.blk);
      }
    }
    // Now dt contains info on how far are we beyond point
    return _supplyAt(point, point.ts + dt);
  }

  function _burn(uint _tokenId) internal {
    address owner = ownerOf(_tokenId);
    // Clear approval
    approve(address(0), _tokenId);
    // Remove token
    _removeTokenFrom(owner, _tokenId);
    emit Transfer(owner, address(0), _tokenId);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../lib/Base64.sol";

/// @title Library for storing SVG image of veNFT.
/// @author belbix
library VeTetuLogo {

  /// @dev Return SVG logo of veTETU.
  function tokenURI(uint _tokenId, uint _balanceOf, uint untilEnd, uint _value) public pure returns (string memory output) {
    output = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 900"><style>.base{font-size:40px;}</style><rect fill="#193180" width="600" height="900"/><path fill="#4899F8" d="M0,900h600V522.2C454.4,517.2,107.4,456.8,60.2,0H0V900z"/><circle fill="#1B184E" cx="385" cy="212" r="180"/><circle fill="#04A8F0" cx="385" cy="142" r="42"/><path fill-rule="evenodd" clip-rule="evenodd" fill="#686DF1" d="M385.6,208.8c43.1,0,78-34.9,78-78c-1.8-21.1,16.2-21.1,21.1-15.4c0.4,0.3,0.7,0.7,1.1,1.2c16.7,21.5,26.6,48.4,26.6,77.7c0,25.8-24.4,42.2-50.2,42.2H309c-25.8,0-50.2-16.4-50.2-42.2c0-29.3,9.9-56.3,26.6-77.7c0.3-0.4,0.7-0.8,1.1-1.2c4.9-5.7,22.9-5.7,21.1,15.4l0,0C307.6,173.9,342.5,208.8,385.6,208.8z"/><path fill="#04A8F0" d="M372.3,335.9l-35.5-51.2c-7.5-10.8,0.2-25.5,13.3-25.5h35.5h35.5c13.1,0,20.8,14.7,13.3,25.5l-35.5,51.2C392.5,345.2,378.7,345.2,372.3,335.9z"/>';
    output = string(abi.encodePacked(output, '<text transform="matrix(1 0 0 1 50 464)" fill="#EAECFE" class="base">ID:</text><text transform="matrix(1 0 0 1 50 506)" fill="#97D0FF" class="base">', _toString(_tokenId), '</text>'));
    output = string(abi.encodePacked(output, '<text transform="matrix(1 0 0 1 50 579)" fill="#EAECFE" class="base">Balance:</text><text transform="matrix(1 0 0 1 50 621)" fill="#97D0FF" class="base">', _toString(_balanceOf / 1e18), '</text>'));
    output = string(abi.encodePacked(output, '<text transform="matrix(1 0 0 1 50 695)" fill="#EAECFE" class="base">Until unlock:</text><text transform="matrix(1 0 0 1 50 737)" fill="#97D0FF" class="base">', _toString(untilEnd / 60 / 60 / 24), ' days</text>'));
    output = string(abi.encodePacked(output, '<text transform="matrix(1 0 0 1 50 811)" fill="#EAECFE" class="base">Power:</text><text transform="matrix(1 0 0 1 50 853)" fill="#97D0FF" class="base">', _toString(_value / 1e18), '</text></svg>'));

    string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "veTETU #', _toString(_tokenId), '", "description": "Locked TETU tokens", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
    output = string(abi.encodePacked('data:application/json;base64,', json));
  }

  /// @dev Inspired by OraclizeAPI's implementation - MIT license
  ///      https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
  function _toString(uint value) internal pure returns (string memory) {
    if (value == 0) {
      return "0";
    }
    uint temp = value;
    uint digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }
}