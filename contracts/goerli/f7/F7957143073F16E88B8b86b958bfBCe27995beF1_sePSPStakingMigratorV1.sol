pragma solidity 0.8.19;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "./utils/Utils.sol";

interface I_sePSP2 is IERC20 {
    function depositPSPAndEth(
        uint256 pspAmount,
        uint256 minBptOut,
        bytes memory pspPermit
    ) external payable;

    function depositPSPAndWeth(
        uint256 pspAmount,
        uint256 wethAmount,
        uint256 minBptOut,
        bytes memory pspPermit
    ) external;
}

contract sePSPStakingMigratorV1 {
    IERC20 public immutable PSP;
    IERC20 public immutable WETH;

    IERC20 public immutable sePSP;
    I_sePSP2 public immutable sePSP2;

    address public immutable PSP_Supplier;

    constructor(
        IERC20 _PSP,
        IERC20 _WETH,
        IERC20 _sePSP,
        I_sePSP2 _sePSP2,
        address _PSP_Supplier
    ) {
        PSP = _PSP;
        WETH = _WETH;

        sePSP = _sePSP;
        sePSP2 = _sePSP2;

        PSP_Supplier = _PSP_Supplier;

        // pre-approve to save on gas
        PSP.approve(address(sePSP2), type(uint).max);
        WETH.approve(address(sePSP2), type(uint).max);
    }

    function migrateSePSP1AndWETHtoSePSP2(
        uint256 sePSP1Amount,
        uint256 wethAmount,
        uint256 minBptOut,
        bytes calldata sePSPPermit
    ) external {
        /**
        0.1 Migrator contract has allowance from DAO for some amount of PSP
        0.2 Migrator contract has allowance from user for some amount of WETH
        1. User gives allowance or permit for sePSP1 to Migrator contract
        2. sePSP1 is transferred to DAO
        3. equivalent PSP is transferred from DAO, and WETH from user
        4. PSP + WETH (from user) is deposited into Balancer Pool through sePSP2
        5. resulting sePSP2 is transferred to user
         */

        Utils.permit(sePSP, sePSPPermit);

        sePSP.transferFrom(msg.sender, address(this), sePSP1Amount);
        sePSP.transfer(PSP_Supplier, sePSP1Amount);

        WETH.transferFrom(msg.sender, address(this), wethAmount);
        PSP.transferFrom(PSP_Supplier, address(this), sePSP1Amount);

        // PSP.approve(address(sePSP2), sePSP1Amount);
        // WETH.approve(address(sePSP2), wethAmount);
        sePSP2.depositPSPAndWeth(sePSP1Amount, wethAmount, minBptOut, "");

        uint256 sePSP2Balance = sePSP2.balanceOf(address(this));
        sePSP2.transfer(msg.sender, sePSP2Balance);
    }

    function migrateSePSP1AndETHtoSePSP2(
        uint256 sePSP1Amount,
        uint256 minBptOut,
        bytes calldata sePSPPermit
    ) external payable {
        /**
        0. Migrator contract has allowance from DAO for some amount of PSP
        1. User gives allowance or permit for sePSP1 to Migrator contract
        2. sePSP1 is transferred to DAO
        3. equivalent PSP is transferred from DAO
        4. PSP + ETH (from user) is deposited into Balancer Pool through sePSP2
        5. resulting sePSP2 is transferred to user
         */

        Utils.permit(sePSP, sePSPPermit);

        sePSP.transferFrom(msg.sender, address(this), sePSP1Amount);
        sePSP.transfer(PSP_Supplier, sePSP1Amount);

        PSP.transferFrom(PSP_Supplier, address(this), sePSP1Amount);

        // PSP.approve(address(sePSP2), sePSP1Amount);
        sePSP2.depositPSPAndEth{ value: msg.value }(sePSP1Amount, minBptOut, "");

        uint256 sePSP2Balance = sePSP2.balanceOf(address(this));
        sePSP2.transfer(msg.sender, sePSP2Balance);
    }
}

pragma solidity ^0.8.6;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

error PermitFailed();
error TransferEthFailed();

library Utils {
    function permit(IERC20 token, bytes memory permit) internal {
        if (permit.length == 32 * 7) {
            (bool success, ) = address(token).call(abi.encodePacked(IERC20Permit.permit.selector, permit));
            if (!success) {
                revert PermitFailed();
            }
        }
    }

    function transferETH(address payable destination, uint256 amount) internal {
        if (amount > 0) {
            (bool result, ) = destination.call{ value: amount }("");
            if (!result) {
                revert TransferEthFailed();
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
interface IERC20 {
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