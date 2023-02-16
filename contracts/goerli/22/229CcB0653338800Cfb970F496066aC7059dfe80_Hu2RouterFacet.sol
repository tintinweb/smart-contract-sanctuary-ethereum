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

import { IHu2RouterFacet } from "./../interfaces/facets/IHu2RouterFacet.sol";
import { IHu2Token } from "./../interfaces/external/hyswap-vault-wrappers/IHu2Token.sol";
import { Constants } from "./../libraries/Constants.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @title Hu2RouterFacet
 * @author Hysland Finance
 * @notice A diamond facet for a variety of functions involving Hu2 tokens.
 *
 *
 */
contract Hu2RouterFacet is IHu2RouterFacet {

    /***************************************
    DEPOSIT FUNCTIONS
    ***************************************/

    /**
     * @notice Deposit the base token to mint the hu2 token.
     * @param hu2Token The address of the hu2 token to deposit into.
     * @param baseAmount The amount of the base token to deposit or max uint for entire balance.
     * @param receiver The receiver of the newly minted hu2 tokens or address(0x02) to not send.
     * @return hu2Amount The amount of hu2 token minted.
     */
    function hu2DepositBaseToken(address hu2Token, uint256 baseAmount, address receiver) external payable override returns (uint256 hu2Amount) {
        if(baseAmount == Constants.CONTRACT_BALANCE) baseAmount = IERC20(IHu2Token(hu2Token).baseToken()).balanceOf(address(this));
        if(receiver == Constants.MSG_SENDER) receiver = msg.sender;
        else if(receiver == Constants.ADDRESS_THIS) receiver = address(this);
        hu2Amount = IHu2Token(hu2Token).depositBaseToken(baseAmount, receiver);
    }

    /**
     * @notice Deposit the vault token to mint the hu2 token.
     * @param hu2Token The address of the hu2 token to deposit into.
     * @param vaultAmount The amount of the vault token to deposit or max uint for entire balance.
     * @param receiver The receiver of the newly minted hu2 tokens or address(0x02) to not send.
     * @return hu2Amount The amount of hu2 token minted.
     */
    function hu2DepositVaultToken(address hu2Token, uint256 vaultAmount, address receiver) external payable override returns (uint256 hu2Amount) {
        if(vaultAmount == Constants.CONTRACT_BALANCE) vaultAmount = IERC20(IHu2Token(hu2Token).vaultToken()).balanceOf(address(this));
        if(receiver == Constants.MSG_SENDER) receiver = msg.sender;
        else if(receiver == Constants.ADDRESS_THIS) receiver = address(this);
        hu2Amount = IHu2Token(hu2Token).depositVaultToken(vaultAmount, receiver);
    }

    /***************************************
    WITHDRAW FUNCTIONS
    ***************************************/

    /**
     * @notice Burn the hu2 token to withdraw the base token.
     * @param hu2Token The address of the hu2 token to deposit into.
     * @param hu2Amount The amount of the hu2 token to burn or max uint for entire balance including interest.
     * @param receiver The receiver of the base token or address(0x02) to not send.
     * @return baseAmount The amount of base token withdrawn.
     */
    function hu2WithdrawBaseToken(address hu2Token, uint256 hu2Amount, address receiver) external payable override returns (uint256 baseAmount) {
        // hu2 tokens have a very similar mechanism with max uint and balance
        // pass the hu2Amount without modification
        if(receiver == Constants.MSG_SENDER) receiver = msg.sender;
        else if(receiver == Constants.ADDRESS_THIS) receiver = address(this);
        baseAmount = IHu2Token(hu2Token).withdrawBaseToken(hu2Amount, receiver);
    }

    /**
     * @notice Burn the hu2 token to withdraw the vault token.
     * @param hu2Token The address of the hu2 token to deposit into.
     * @param hu2Amount The amount of the hu2 token to burn or max uint for entire balance.
     * @param receiver The receiver of the vault token or address(0x02) to not send.
     * @return vaultAmount The amount of vault token withdrawn.
     */
    function hu2WithdrawVaultToken(address hu2Token, uint256 hu2Amount, address receiver) external payable override returns (uint256 vaultAmount) {
        // hu2 tokens have a very similar mechanism with max uint and balance
        // pass the hu2Amount without modification
        if(receiver == Constants.MSG_SENDER) receiver = msg.sender;
        else if(receiver == Constants.ADDRESS_THIS) receiver = address(this);
        vaultAmount = IHu2Token(hu2Token).withdrawVaultToken(hu2Amount, receiver);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IHwTokenBase } from "./IHwTokenBase.sol";


/**
 * @title IHu2Token
 * @author Hysland Finance
 * @notice An interest bearing token designed to be used in Uniswap V2 pools.
 *
 * Most liquidity pools were designed to work with "standard" ERC20 tokens. The vault tokens of some interest bearing protocols may not work well with some liquidity pools. Hyswap vault wrappers are ERC20 tokens around these vaults that help them work better in liquidity pools. Liquidity providers of Hyswap pools will earn from both swap fees and interest from vaults.
 *
 * ```
 * ------------------------
 * | hyswap wrapper token | eg hu2yvDAI
 * | -------------------- |
 * | |   vault token    | | eg yvDAI
 * | | ---------------- | |
 * | | |  base token  | | | eg DAI
 * | | ---------------- | |
 * | -------------------- |
 * ------------------------
 * ```
 *
 * This is the base type of hwTokens that are designed for use in Uniswap V2, called Hyswap Uniswap V2 Vault Wrappers.
 *
 * Interest will accrue over time. This will increase each accounts [`interestOf()`](#interestof) and [`balancePlusInterestOf()`](#balanceplusinterestof) but not their `balanceOf()`. Users can move this amount to their `balanceOf()` via [`accrueInterest()`](#accrueinterest). The [`interestDistributor()`](#interestdistributor) can accrue the interest of a Uniswap V2 pool via [`distributeInterestToPool()`](#distributeinteresttopool). For accounting purposes, [`accrueInterestMultiple()`](#accrueinterestmultiple) and `transfer()` will also accrue interest, but this amount won't be added to the accounts `balanceOf()` until a call to [`accrueInterest()`](#accrueinterest) or [`distributeInterestToPool()`](#distributeinteresttopool).
 *
 * Most users won't hold this token and can largely ignore that it exists. If you see it in a Uniswap V2 pool, you can think of it as the base token. Integrators should perform the routing for you. Regular users should hold the base token for regular use, the vault token to earn interest, or the LP token to earn interest plus swap fees. High frequency traders may hold the Hu2Token for reduced gas fees.
 *
 * A portion of the interest earned may be redirected to the Hyswap treasury and integrators. The percentage can be viewed via [`interestShare()`](#interestshare) and the receiver can be viewed via [`treasury()`](#treasury).
 */
interface IHu2Token is IHwTokenBase {

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Returns the address of the base token.
     * @return token The base token.
     */
    function baseToken() external view returns (address token);

    /**
     * @notice Returns the address of the vault token.
     * @return token The vault token.
     */
    function vaultToken() external view returns (address token);

    /**
     * @notice Returns the amount of interest claimable by `account`.
     * @param account The account to query interest of.
     * @return interest The account's accrued interest.
     */
    function interestOf(address account) external view returns (uint256 interest);

    /**
     * @notice Returns the balance of an account after adding interest.
     * @param account The account to query interest of.
     * @return balance The account's new balance.
     */
    function balancePlusInterestOf(address account) external view returns (uint256 balance);

    /**
     * @notice The percent of interest from reinvestments that are directed towards holders (namely liquidity pools and liquidity providers). The rest goes to the treasury and integrators. Has 18 decimals of precision.
     * @return interestShare_ The interest share with 18 decimals of precision.
     */
    function interestShare() external view returns (uint256 interestShare_);

    /**
     * @notice The address to receive the interest not directed towards holders. Can be modified in each hu2token instance.
     * @return treasury_ The treasury address.
     */
    function treasury() external view returns (address treasury_);

    /**
     * @notice The address of the [`Hu2InterestDistributor`](./IHu2InterestDistributor).
     * @return distributor_ The distributor.
     */
    function interestDistributor() external view returns (address distributor_);

    /***************************************
    DEPOSIT FUNCTIONS
    ***************************************/

    /**
     * @notice Deposit the base token to mint the hu2 token.
     * @param baseAmount The amount of the base token to deposit.
     * @param receiver The receiver of the newly minted hu2 tokens.
     * @return hu2Amount The amount of hu2 token minted.
     */
    function depositBaseToken(uint256 baseAmount, address receiver) external returns (uint256 hu2Amount);

    /**
     * @notice Deposit the vault token to mint the hu2 token.
     * @param vaultAmount The amount of the vault token to deposit.
     * @param receiver The receiver of the newly minted hu2 tokens.
     * @return hu2Amount The amount of hu2 token minted.
     */
    function depositVaultToken(uint256 vaultAmount, address receiver) external returns (uint256 hu2Amount);

    /***************************************
    WITHDRAW FUNCTIONS
    ***************************************/

    /**
     * @notice Burn the hu2 token to withdraw the base token.
     * @param hu2Amount The amount of the hu2 token to burn or max uint for entire balance including interest.
     * @param receiver The receiver of the base token.
     * @return baseAmount The amount of base token withdrawn.
     */
    function withdrawBaseToken(uint256 hu2Amount, address receiver) external returns (uint256 baseAmount);

    /**
     * @notice Burn the hu2 token to withdraw the vault token.
     * @param hu2Amount The amount of the hu2 token to burn or max uint for entire balance including interest.
     * @param receiver The receiver of the vault token.
     * @return vaultAmount The amount of vault token withdrawn.
     */
    function withdrawVaultToken(uint256 hu2Amount, address receiver) external returns (uint256 vaultAmount);

    /***************************************
    INTEREST ACCRUAL FUNCTIONS
    ***************************************/

    /**
     * @notice Accrues the interest owed to `msg.sender` and adds it to their balance.
     */
    function accrueInterest() external;

    /**
     * @notice Accrues the interest owed to multiple accounts and adds it to their unpaid interest.
     * @param accounts The list of accouunts to accrue interest for.
     */
    function accrueInterestMultiple(address[] calldata accounts) external;

    /**
     * @notice Distributes interest earned by a Uniswap V2 pool to its reserves.
     * Can only be called by the [`Hu2InterestDistributor`](./IHu2InterestDistributor).
     * @param pool The address of the Uniswap V2 pool to distribute interest to.
     */
    function distributeInterestToPool(address pool) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


/**
 * @title IHwTokenBase
 * @author Hysland Finance
 * @notice A custom implementation of an ERC20 token with the metadata and permit extensions.
 *
 * This was forked from OpenZeppelin's implementation with a few key differences:
 * - It uses an initialzer instead of a constructor, allowing for easier use in factory patterns.
 * - State variables are declared as internal instead of private, allowing use by child contracts.
 * - Minor efficiency improvements. Removed zero address checks, context, shorter revert strings.
 */
interface IHwTokenBase {

    /***************************************
    EVENTS
    ***************************************/

    /**
     * @notice Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @notice Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to [`approve()`](#approve). `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Returns the name of the token.
     * @return name_ The name of the token.
     */
    function name() external view returns (string memory name_);

    /**
     * @notice Returns the symbol of the token.
     * @return symbol_ The symbol of the token.
     */
    function symbol() external view returns (string memory symbol_);

    /**
     * @notice Returns the decimals places of the token.
     * @return decimals_ The decimals of the token.
     */
    function decimals() external view returns (uint8 decimals_);

    /**
     * @notice Returns the amount of tokens in existence.
     * @return supply The amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256 supply);

    /**
     * @notice Returns the amount of tokens owned by `account`.
     * @param account The account to query balance of.
     * @return balance The account's balance.
     */
    function balanceOf(address account) external view returns (uint256 balance);

    /**
     * @notice Returns the remaining number of tokens that `spender` is
     * allowed to spend on behalf of `owner` through [`transferFrom()`](#transferfrom). This is
     * zero by default.
     *
     * This value changes when [`approve()`](#approve), [`transferFrom()`](#transferfrom),
     * or [`permit()`](#permit) are called.
     *
     * @param owner The owner of tokens.
     * @param spender The spender of tokens.
     * @return allowance_ The amount of `owner`'s tokens that `spender` can spend.
     */
    function allowance(address owner, address spender) external view returns (uint256 allowance_);

    /**
     * @notice Returns the current nonce for `owner`. This value must be included whenever a signature is generated for [`permit()`](#permit).
     * @param owner The owner of tokens.
     * @return nonce_ The owner's nonce.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @notice Returns the domain separator used in the encoding of the signature for [`permit()`](#permit), as defined by EIP712.
     * @return separator The domain separator.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32 separator);

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - the caller must have a balance of at least `amount`.
     *
     * @param recipient The recipient of the tokens.
     * @param amount The amount of tokens to transfer.
     * @return success True on success, false otherwise.
     */
    function transfer(address recipient, uint256 amount) external returns (bool success);

    /**
     * @notice Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     *
     * @param sender The sender of the tokens.
     * @param recipient The recipient of the tokens.
     * @param amount The amount of tokens to transfer.
     * @return success True on success, false otherwise.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool success);

    /**
     * @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
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
     * Emits an `Approval` event.
     *
     * @param spender The account to allow to spend `msg.sender`'s tokens.
     * @param amount The amount of tokens to allow to spend.
     * @return success True on success, false otherwise.
     */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
     * @notice Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to [`approve()`](#approve) that can be used as a mitigation for
     * problems described in [`approve()`](#approve).
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * @param spender The account to allow to spend `msg.sender`'s tokens.
     * @param addedValue The amount to increase allowance.
     * @return success True on success, false otherwise.
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool success);

    /**
     * @notice Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to [`approve()`](#approve) that can be used as a mitigation for
     * problems described in [`approve()`](#approve).
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     *
     * @param spender The account to allow to spend `msg.sender`'s tokens.
     * @param subtractedValue The amount to decrease allowance.
     * @return success True on success, false otherwise.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool success);

    /**
     * @notice Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues [`approve()`](#approve) has related to transaction
     * ordering also apply here.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use `owner`'s current nonce (see [`nonces()`](#nonces)).
     *
     * For more information on the signature format, see
     * [EIP2612](https://eips.ethereum.org/EIPS/eip-2612#specification).
     *
     * @param owner The owner of the tokens.
     * @param spender The spender of the tokens.
     * @param value The amount to approve.
     * @param deadline The timestamp that `permit()` must go through before.
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
pragma solidity 0.8.17;


/**
 * @title IHu2RouterFacet
 * @author Hysland Finance
 * @notice A diamond facet for a variety of functions involving Hu2 tokens.
 *
 *
 */
interface IHu2RouterFacet {

    /***************************************
    DEPOSIT FUNCTIONS
    ***************************************/

    /**
     * @notice Deposit the base token to mint the hu2 token.
     * @param hu2Token The address of the hu2 token to deposit into.
     * @param baseAmount The amount of the base token to deposit or max uint for entire balance.
     * @param receiver The receiver of the newly minted hu2 tokens or address(0x02) to not send.
     * @return hu2Amount The amount of hu2 token minted.
     */
    function hu2DepositBaseToken(address hu2Token, uint256 baseAmount, address receiver) external payable returns (uint256 hu2Amount);

    /**
     * @notice Deposit the vault token to mint the hu2 token.
     * @param hu2Token The address of the hu2 token to deposit into.
     * @param vaultAmount The amount of the vault token to deposit or max uint for entire balance.
     * @param receiver The receiver of the newly minted hu2 tokens or address(0x02) to not send.
     * @return hu2Amount The amount of hu2 token minted.
     */
    function hu2DepositVaultToken(address hu2Token, uint256 vaultAmount, address receiver) external payable returns (uint256 hu2Amount);

    /***************************************
    WITHDRAW FUNCTIONS
    ***************************************/

    /**
     * @notice Burn the hu2 token to withdraw the base token.
     * @param hu2Token The address of the hu2 token to deposit into.
     * @param hu2Amount The amount of the hu2 token to burn or max uint for entire balance including interest.
     * @param receiver The receiver of the base token or address(0x02) to not send.
     * @return baseAmount The amount of base token withdrawn.
     */
    function hu2WithdrawBaseToken(address hu2Token, uint256 hu2Amount, address receiver) external payable returns (uint256 baseAmount);

    /**
     * @notice Burn the hu2 token to withdraw the vault token.
     * @param hu2Token The address of the hu2 token to deposit into.
     * @param hu2Amount The amount of the hu2 token to burn or max uint for entire balance.
     * @param receiver The receiver of the vault token or address(0x02) to not send.
     * @return vaultAmount The amount of vault token withdrawn.
     */
    function hu2WithdrawVaultToken(address hu2Token, uint256 hu2Amount, address receiver) external payable returns (uint256 vaultAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Constants
 * @author Hysland Finance
 * @notice A library of constant values.
 */
library Constants {
    /// @notice Used for identifying cases when this contract's balance of a token is to be used.
    uint256 internal constant CONTRACT_BALANCE = type(uint256).max;

    /// @notice Used as a flag for identifying msg.sender, saves gas by sending more 0 bytes.
    address internal constant MSG_SENDER = address(0x0000000000000000000000000000000000000001);

    /// @notice Used as a flag for identifying address(this), saves gas by sending more 0 bytes.
    address internal constant ADDRESS_THIS = address(0x0000000000000000000000000000000000000002);
}