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

import { IYearnRouterFacet } from "./../interfaces/facets/IYearnRouterFacet.sol";
import { IYearnVault } from "./../interfaces/external/yearn/IYearnVault.sol";
import { Constants } from "./../libraries/Constants.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @title YearnRouterFacet
 * @author Hysland Finance
 * @notice A diamond facet for a variety of functions involving Yearn Vault tokens.
 *
 * Each Yearn Vault reinvests an underlying `ERC20` and issues its own `ERC20` as a receipt of deposit. The underlying token can be deposited via [`yearnDeposit()`](#yearndeposit). The vault token can be redeemed for the underlying token via [`yearnWithdraw()`](#yearnwithdraw).
 *
 * The underlying or vault token must be in this contract before the deposit or withdraw call is made. For security consider combining these calls with calls to [`ERC20RouterFacet`](./ERC20RouterFacet) via `multicall()`.
 */
contract YearnRouterFacet is IYearnRouterFacet {

    /***************************************
    EXTERNAL MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Deposits some underlying `ERC20` into a Yearn Vault.
     * @param yearnVault The address of the Yearn Vault.
     * @param uAmount The amount of the underlying token to deposit or max uint for entire balance.
     * @param receiver The address to receive the Vault shares or address(0x02) to not send.
     * @return yAmount The issued Vault shares.
     */
    function yearnDeposit(address yearnVault, uint256 uAmount, address receiver) external payable override returns (uint256 yAmount) {
        IYearnVault vault = IYearnVault(yearnVault);
        if(uAmount == Constants.CONTRACT_BALANCE) uAmount = IERC20(vault.token()).balanceOf(address(this));
        if(receiver == Constants.MSG_SENDER) receiver = msg.sender;
        else if(receiver == Constants.ADDRESS_THIS) receiver = address(this);
        yAmount = vault.deposit(uAmount, receiver);
    }

    /**
     * @notice Withdraws some `ERC20` from a Yearn Vault.
     * @dev This version of `withdraw()` is available on all Yearn Vaults.
     * @param yearnVault The address of the Yearn Vault.
     * @param yAmount The amount of shares to redeem or max uint for entire balance.
     * @param receiver The address to receive the underlying token or address(0x02) to not send.
     * @return uAmount The amount of the underlying token returned from the Vault.
     */
    function yearnWithdraw(address yearnVault, uint256 yAmount, address receiver) external payable override returns (uint256 uAmount) {
        IYearnVault vault = IYearnVault(yearnVault);
        if(yAmount == Constants.CONTRACT_BALANCE) yAmount = vault.balanceOf(address(this));
        if(receiver == Constants.MSG_SENDER) receiver = msg.sender;
        else if(receiver == Constants.ADDRESS_THIS) receiver = address(this);
        uAmount = vault.withdraw(yAmount, receiver);
    }

    /**
     * @notice Withdraws some `ERC20` from a Yearn Vault.
     * @dev This version of `withdraw()` is available on Vaults with api version >= 0.3.0.
     * @param yearnVault The address of the Yearn Vault.
     * @param yAmount The amount of shares to redeem or max uint for entire balance.
     * @param receiver The address to receive the underlying token or address(0x02) to not send.
     * @param maxLoss The maximum acceptable loss to sustain on withdrawal.
     * @return uAmount The amount of the underlying token returned from the Vault.
     */
    function yearnWithdraw(address yearnVault, uint256 yAmount, address receiver, uint256 maxLoss) external payable override returns (uint256 uAmount) {
        IYearnVault vault = IYearnVault(yearnVault);
        if(yAmount == Constants.CONTRACT_BALANCE) yAmount = vault.balanceOf(address(this));
        if(receiver == Constants.MSG_SENDER) receiver = msg.sender;
        else if(receiver == Constants.ADDRESS_THIS) receiver = address(this);
        uAmount = vault.withdraw(yAmount, receiver, maxLoss);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IERC20PermitB } from "./../../tokens/IERC20PermitB.sol";


/**
 * @title IYearnVault
 * @author Hysland Finance
 * @notice Yearn Token Vault. Holds an underlying token, and allows users to interact with the Yearn ecosystem through Strategies connected to the Vault. Vaults are not limited to a single Strategy, they can have as many Strategies as can be designed (however the withdrawal queue is capped at 20.)
 *
 * Deposited funds are moved into the most impactful strategy that has not already reached its limit for assets under management, regardless of which Strategy a user's funds end up in, they receive their portion of yields generated across all Strategies.
 *
 * When a user withdraws, if there are no funds sitting undeployed in the Vault, the Vault withdraws funds from Strategies in the order of least impact. (Funds are taken from the Strategy that will disturb everyone's gains the least, then the next least, etc.) In order to achieve this, the withdrawal queue's order must be properly set and managed by the community (through governance).
 *
 * Vault Strategies are parameterized to pursue the highest risk-adjusted yield.
 *
 * There is an "Emergency Shutdown" mode. When the Vault is put into emergency shutdown, assets will be recalled from the Strategies as quickly as is practical (given on-chain conditions), minimizing loss. Deposits are halted, new Strategies may not be added, and each Strategy exits with the minimum possible damage to position, while opening up deposits to be withdrawn by users. There are no restrictions on withdrawals above what is expected under Normal Operation.
 *
 * For further details, please refer to the specification:
 * https://github.com/iearn-finance/yearn-vaults/blob/main/SPECIFICATION.md
 */
interface IYearnVault is IERC20PermitB {

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice The token that may be deposited into this Vault.
     * @return tkn The token that may be deposited into this Vault.
     */
    function token() external view returns (address tkn);

    /**
     * @notice Gives the price for a single Vault share.
     * @dev See dev note on `withdraw`.
     * @return pps The value of a single share.
     */
    function pricePerShare() external view returns (uint256 pps);

    /**
     * @notice The amount of the underlying token that still may be deposited into this contract.
     * @return uAmount The amount in the same decimals as uToken.
     */
    function availableDepositLimit() external view returns (uint256 uAmount);

    /**
     * @notice Returns true if the Vault is in the emergency shutdown state. TLDR: no deposits.
     * @return shutdown True if the Vault is shutdown, otherwise false.
     */
    function emergencyShutdown() external view returns (bool shutdown);

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Deposits `uAmount` `token`, issuing shares to `recipient`. If the Vault is in Emergency Shutdown, deposits will not be accepted and this call will fail.
     * @dev Measuring quantity of shares to issues is based on the total outstanding debt that this contract has ("expected value") instead of the total balance sheet it has ("estimated value") has important security considerations, and is done intentionally. If this value were measured against external systems, it could be purposely manipulated by an attacker to withdraw more assets than they otherwise should be able to claim by redeeming their shares. On deposit, this means that shares are issued against the total amount that the deposited capital can be given in service of the debt that Strategies assume. If that number were to be lower than the "expected value" at some future point, depositing shares via this method could entitle the depositor to *less* than the deposited value once the "realized value" is updated from further reports by the Strategies to the Vaults. Care should be taken by integrators to account for this discrepancy, by using the view-only methods of this contract (both off-chain and on-chain) to determine if depositing into the Vault is a "good idea".
     * @param uAmount The quantity of tokens to deposit.
     * @param recipient The address to issue the shares in this Vault to.
     * @return yAmount The issued Vault shares.
     */
    function deposit(uint256 uAmount, address recipient) external returns (uint256 yAmount);

    /**
     * @notice Withdraws the calling account's tokens from this Vault, redeeming amount `yAmount` for an appropriate amount of tokens. See note on `setWithdrawalQueue` for further details of withdrawal ordering and behavior.
     * @dev This version of `withdraw()` is available on Vaults with api version <= 0.2.2.
     * @dev Measuring the value of shares is based on the total outstanding debt that this contract has ("expected value") instead of the total balance sheet it has ("estimated value") has important security considerations, and is done intentionally. If this value were measured against external systems, it could be purposely manipulated by an attacker to withdraw more assets than they otherwise should be able to claim by redeeming their shares. On withdrawal, this means that shares are redeemed against the total amount that the deposited capital had "realized" since the point it was deposited, up until the point it was withdrawn. If that number were to be higher than the "expected value" at some future point, withdrawing shares via this method could entitle the depositor to *more* than the expected value once the "realized value" is updated from further reports by the Strategies to the Vaults. Under exceptional scenarios, this could cause earlier withdrawals to earn "more" of the underlying assets than Users might otherwise be entitled to, if the Vault's estimated value were otherwise measured through external means, accounting for whatever exceptional scenarios exist for the Vault (that aren't covered by the Vault's own design.) In the situation where a large withdrawal happens, it can empty the vault balance and the strategies in the withdrawal queue. Strategies not in the withdrawal queue will have to be harvested to rebalance the funds and make the funds available again to withdraw.
     * @param yAmount How many shares to try and redeem for tokens.
     * @param recipient The address to transfer the underlying tokens in this Vault to.
     * @return uAmount The quantity of tokens redeemed for `yAmount`.
     */
    function withdraw(uint256 yAmount, address recipient) external returns (uint256 uAmount);

    /**
     * @notice Withdraws the calling account's tokens from this Vault, redeeming amount `yAmount` for an appropriate amount of tokens. See note on `setWithdrawalQueue` for further details of withdrawal ordering and behavior.
     * @dev This version of `withdraw()` is available on Vaults with api version >= 0.3.0.
     * @dev Measuring the value of shares is based on the total outstanding debt that this contract has ("expected value") instead of the total balance sheet it has ("estimated value") has important security considerations, and is done intentionally. If this value were measured against external systems, it could be purposely manipulated by an attacker to withdraw more assets than they otherwise should be able to claim by redeeming their shares. On withdrawal, this means that shares are redeemed against the total amount that the deposited capital had "realized" since the point it was deposited, up until the point it was withdrawn. If that number were to be higher than the "expected value" at some future point, withdrawing shares via this method could entitle the depositor to *more* than the expected value once the "realized value" is updated from further reports by the Strategies to the Vaults. Under exceptional scenarios, this could cause earlier withdrawals to earn "more" of the underlying assets than Users might otherwise be entitled to, if the Vault's estimated value were otherwise measured through external means, accounting for whatever exceptional scenarios exist for the Vault (that aren't covered by the Vault's own design.) In the situation where a large withdrawal happens, it can empty the vault balance and the strategies in the withdrawal queue. Strategies not in the withdrawal queue will have to be harvested to rebalance the funds and make the funds available again to withdraw.
     * @param yAmount How many shares to try and redeem for tokens.
     * @param recipient The address to transfer the underlying tokens in this Vault to.
     * @param maxLoss The maximum acceptable loss to sustain on withdrawal. Up to that amount of shares may be burnt to cover losses on withdrawal.
     * @return uAmount The quantity of tokens redeemed for `yAmount`.
     */
    function withdraw(uint256 yAmount, address recipient, uint256 maxLoss) external returns (uint256 uAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


/**
 * @title IYearnRouterFacet
 * @author Hysland Finance
 * @notice A diamond facet for a variety of functions involving Yearn Vault tokens.
 *
 * Each Yearn Vault reinvests an underlying `ERC20` and issues its own `ERC20` as a receipt of deposit. The underlying token can be deposited via [`yearnDeposit()`](#yearndeposit). The vault token can be redeemed for the underlying token via [`yearnWithdraw()`](#yearnwithdraw).
 *
 * The underlying or vault token must be in this contract before the deposit or withdraw call is made. For security consider combining these calls with calls to [`ERC20RouterFacet`](./IERC20RouterFacet) via `multicall()`.
 */
interface IYearnRouterFacet {

    /**
     * @notice Deposits some underlying `ERC20` into a Yearn Vault.
     * @param yearnVault The address of the Yearn Vault.
     * @param uAmount The amount of the underlying token to deposit or max uint for entire balance.
     * @param receiver The address to receive the Vault shares or address(0x02) to not send.
     * @return yAmount The issued Vault shares.
     */
    function yearnDeposit(address yearnVault, uint256 uAmount, address receiver) external payable returns (uint256 yAmount);

    /**
     * @notice Withdraws some `ERC20` from a Yearn Vault.
     * @dev This version of `withdraw()` is available on all Yearn Vaults.
     * @param yearnVault The address of the Yearn Vault.
     * @param yAmount The amount of shares to redeem or max uint for entire balance.
     * @param receiver The address to receive the underlying token or address(0x02) to not send.
     * @return uAmount The amount of the underlying token returned from the Vault.
     */
    function yearnWithdraw(address yearnVault, uint256 yAmount, address receiver) external payable returns (uint256 uAmount);

    /**
     * @notice Withdraws some `ERC20` from a Yearn Vault.
     * @dev This version of `withdraw()` is available on Vaults with api version >= 0.3.0.
     * @param yearnVault The address of the Yearn Vault.
     * @param yAmount The amount of shares to redeem or max uint for entire balance.
     * @param receiver The address to receive the underlying token or address(0x02) to not send.
     * @param maxLoss The maximum acceptable loss to sustain on withdrawal.
     * @return uAmount The amount of the underlying token returned from the Vault.
     */
    function yearnWithdraw(address yearnVault, uint256 yAmount, address receiver, uint256 maxLoss) external payable returns (uint256 uAmount);
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
    address internal constant MSG_SENDER = address(1);

    /// @notice Used as a flag for identifying address(this), saves gas by sending more 0 bytes.
    address internal constant ADDRESS_THIS = address(2);
}