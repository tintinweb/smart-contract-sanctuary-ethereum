// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
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
    function transferFrom(
        address sender,
        address recipient,
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
pragma solidity 0.8.17;

import { IERC2612RouterFacet } from "./../interfaces/facets/IERC2612RouterFacet.sol";
import { IERC20PermitA } from "./../interfaces/tokens/IERC20PermitA.sol";
import { IERC20PermitB } from "./../interfaces/tokens/IERC20PermitB.sol";
import { IERC20PermitC } from "./../interfaces/tokens/IERC20PermitC.sol";


/**
 * @title ERC2612RouterFacet
 * @author Hysland Finance
 * @notice A diamond facet for calling `ERC2612 permit()` on `ERC20` tokens.
 *
 * `ERC20` tokens with the `ERC2612` extension can be permitted via [`erc2612Permit()`](#erc2612permit). Allowances will always be made from `msg.sender` to this contract.
 * Multiple different implementations of `permit()` were deployed to production networks before the standard was finalized. Be sure to use the correct one for each token.
 *
 * Security warning: Assuming that a token does not support `ERC2612`, in most cases the call will revert. However there are cases in which the token has a fallback function (like WETH) and will NOOP instead. If your integration relies on the call either failing or reverting, use either a precheck (supports permit) or postcheck (allowance was set).
 */
contract ERC2612RouterFacet is IERC2612RouterFacet {

    /***************************************
    EXTERNAL MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Sets the amount of an `ERC20` token that this contract is allowed to transfer from `msg.sender` using `EIP2612`.
     * @param token The address of the token to permit.
     * @param amount The amount of the token to permit.
     * @param deadline The timestamp that the transaction must go through before.
     * @param v secp256k1 signature
     * @param r secp256k1 signature
     * @param s secp256k1 signature
     */
    function erc2612Permit(address token, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external payable override {
        IERC20PermitA(token).permit(msg.sender, address(this), amount, deadline, v, r, s);
    }

    /**
     * @notice Sets the amount of an `ERC20` token that this contract is allowed to transfer from `msg.sender` using a modified version of `EIP2612`.
     * @param token The address of the token to permit.
     * @param amount The amount of the token to permit.
     * @param deadline The timestamp that the transaction must go through before.
     * @param signature secp256k1 signature
     */
    function erc2612Permit(address token, uint256 amount, uint256 deadline, bytes calldata signature) external payable override {
        IERC20PermitB(token).permit(msg.sender, address(this), amount, deadline, signature);
    }

    /**
     * @notice Sets the amount of an `ERC20` token that this contract is allowed to transfer from `msg.sender` using an old version of `EIP2612`.
     * @param token The address of the token to permit.
     * @param nonce Deduplicates permit transactions.
     * @param expiry The timestamp that the transaction must go through before.
     * @param allowed True to allow all, false to allow zero.
     * @param v secp256k1 signature
     * @param r secp256k1 signature
     * @param s secp256k1 signature
     */
    function erc2612Permit(address token, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) external payable override {
        IERC20PermitC(token).permit(msg.sender, address(this), nonce, expiry, allowed, v, r, s);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


/**
 * @title IERC2612RouterFacet
 * @author Hysland Finance
 * @notice A diamond facet for calling `ERC2612 permit()` on `ERC20` tokens.
 *
 * `ERC20` tokens with the `ERC2612` extension can be permitted via [`erc2612Permit()`](#erc2612permit). Allowances will always be made from `msg.sender` to this contract.
 * Multiple different implementations of `permit()` were deployed to production networks before the standard was finalized. Be sure to use the correct one for each token.
 *
 * Security warning: Assuming that a token does not support `ERC2612`, in most cases the call will revert. However there are cases in which the token has a fallback function (like WETH) and will NOOP instead. If your integration relies on the call either failing or reverting, use either a precheck (supports permit) or postcheck (allowance was set).
 */
interface IERC2612RouterFacet {

    /**
     * @notice Sets the amount of an `ERC20` token that this contract is allowed to transfer from `msg.sender` using `EIP2612`.
     * @param token The address of the token to permit.
     * @param amount The amount of the token to permit.
     * @param deadline The timestamp that the transaction must go through before.
     * @param v secp256k1 signature
     * @param r secp256k1 signature
     * @param s secp256k1 signature
     */
    function erc2612Permit(address token, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external payable;

    /**
     * @notice Sets the amount of an `ERC20` token that this contract is allowed to transfer from `msg.sender` using a modified version of `EIP2612`.
     * @param token The address of the token to permit.
     * @param amount The amount of the token to permit.
     * @param deadline The timestamp that the transaction must go through before.
     * @param signature secp256k1 signature
     */
    function erc2612Permit(address token, uint256 amount, uint256 deadline, bytes calldata signature) external payable;

    /**
     * @notice Sets the amount of an `ERC20` token that this contract is allowed to transfer from `msg.sender` using an old version of `EIP2612`.
     * @param token The address of the token to permit.
     * @param nonce Deduplicates permit transactions.
     * @param expiry The timestamp that the transaction must go through before.
     * @param allowed True to allow all, false to allow zero.
     * @param v secp256k1 signature
     * @param r secp256k1 signature
     * @param s secp256k1 signature
     */
    function erc2612Permit(address token, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";


/**
 * @title IERC20PermitA
 * @author Hysland Finance
 * @notice An `ERC20` token that also has the `ERC2612` permit extension.
 *
 * Multiple different implementations of `permit()` were deployed to production networks before the standard was finalized. This is the finalized version.
 */
interface IERC20PermitA is IERC20Metadata {

    /**
     * @notice Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for `permit`.
     *
     * Every successful call to `permit` increases `owner`'s nonce by one. This
     * prevents a signature from being used multiple times.
     * @return nonce The current nonce for `owner`.
     */
    function nonces(address owner) external view returns (uint256 nonce);

    /**
     * @notice Returns the domain separator used in the encoding of the signature for `permit`, as defined by `EIP712`.
     * @return sep The domain separator.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32 sep);

    /**
     * @notice Sets the allowance of `spender` over `owner`'s tokens given `owner`'s signed approval.
     * @param owner The account that holds the tokens.
     * @param spender The account that spends the tokens.
     * @param value The amount of the token to permit.
     * @param deadline The timestamp that the transaction must go through before.
     * @param v secp256k1 signature
     * @param r secp256k1 signature
     * @param s secp256k1 signature
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
}

// SPDX-License-Identifier: MIT
// code borrowed from https://etherscan.io/address/0x3B27F92C0e212C671EA351827EDF93DB27cc0c65#code
pragma solidity 0.8.17;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";


/**
 * @title IERC20PermitB
 * @author Hysland Finance
 * @notice An `ERC20` token that also has the `ERC2612` permit extension.
 *
 * Multiple different implementations of `permit()` were deployed to production networks before the standard was finalized. This is NOT the finalized version.
 */
interface IERC20PermitB is IERC20Metadata {

    /**
     * @notice Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for `permit`.
     *
     * Every successful call to `permit` increases `owner`'s nonce by one. This
     * prevents a signature from being used multiple times.
     * @return nonce The current nonce for `owner`.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @notice Returns the domain separator used in the encoding of the signature for `permit`, as defined by `EIP712`.
     * @return sep The domain separator.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32 sep);

    /**
     * @notice Sets the allowance of `spender` over `owner`'s tokens given `owner`'s signed approval.
     * @param owner The account that holds the tokens.
     * @param spender The account that spends the tokens.
     * @param value The amount of the token to permit.
     * @param deadline The timestamp that the transaction must go through before.
     * @param signature secp256k1 signature
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        bytes calldata signature
    ) external;
}

// SPDX-License-Identifier: MIT
// code borrowed from https://etherscan.io/address/0x6b175474e89094c44da98b954eedeac495271d0f#code
pragma solidity 0.8.17;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";


/**
 * @title IERC20PermitC
 * @author Hysland Finance
 * @notice An `ERC20` token that also has the `ERC2612` permit extension.
 *
 * Multiple different implementations of `permit()` were deployed to production networks before the standard was finalized. This is NOT the finalized version.
 */
interface IERC20PermitC is IERC20Metadata {

    /**
     * @notice Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for `permit`.
     *
     * Every successful call to `permit` increases `owner`'s nonce by one. This
     * prevents a signature from being used multiple times.
     * @return nonce The current nonce for `owner`.
     */
    function nonces(address owner) external view returns (uint256 nonce);

    /**
     * @notice Returns the domain separator used in the encoding of the signature for `permit`, as defined by `EIP712`.
     * @return sep The domain separator.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32 sep);

    /**
     * @notice Sets the allowance of `spender` over `holder`'s tokens given `holder`'s signed approval.
     * @param holder The account that holds the tokens.
     * @param spender The account that spends the tokens.
     * @param nonce Deduplicates permit transactions.
     * @param expiry The timestamp that the transaction must go through before or zero for never expires.
     * @param allowed True to allow all, false to allow zero.
     * @param v secp256k1 signature
     * @param r secp256k1 signature
     * @param s secp256k1 signature
     */
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}