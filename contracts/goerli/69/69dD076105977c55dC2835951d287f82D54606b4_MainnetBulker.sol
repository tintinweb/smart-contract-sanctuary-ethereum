// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "./BaseBulker.sol";
import "../IWstETH.sol";

/**
 * @title Compound's Bulker contract for Ethereum mainnet
 * @notice Executes multiple Comet-related actions in a single transaction
 * @author Compound
 */
contract MainnetBulker is BaseBulker {
    /** General configuration constants **/

    /// @notice The address of Lido staked ETH
    address public immutable steth;

    /// @notice The address of Lido wrapped staked ETH
    address public immutable wsteth;

    /** Actions **/

    /// @notice The action for supplying staked ETH to Comet
    bytes32 public constant ACTION_SUPPLY_STETH = "ACTION_SUPPLY_STETH";

    /// @notice The action for withdrawing staked ETH from Comet
    bytes32 public constant ACTION_WITHDRAW_STETH = "ACTION_WITHDRAW_STETH";

    /** Custom errors **/

    error UnsupportedBaseAsset();

    /**
     * @notice Construct a new MainnetBulker instance
     * @param admin_ The admin of the Bulker contract
     * @param weth_ The address of wrapped ETH
     * @param wsteth_ The address of Lido wrapped staked ETH
     **/
    constructor(
        address admin_,
        address payable weth_,
        address wsteth_
    ) BaseBulker(admin_, weth_) {
        wsteth = wsteth_;
        steth = IWstETH(wsteth_).stETH();
    }

    /**
     * @notice Handles actions specific to the Ethereum mainnet version of Bulker, specifically supplying and withdrawing stETH
     */
    function handleAction(bytes32 action, bytes calldata data) override internal {
        if (action == ACTION_SUPPLY_STETH) {
            (address comet, address to, uint stETHAmount) = abi.decode(data, (address, address, uint));
            supplyStEthTo(comet, to, stETHAmount);
        } else if (action == ACTION_WITHDRAW_STETH) {
            (address comet, address to, uint wstETHAmount) = abi.decode(data, (address, address, uint));
            withdrawStEthTo(comet, to, wstETHAmount);
        } else {
            revert UnhandledAction();
        }
    }

    /**
     * @notice Wraps stETH to wstETH and supplies to a user in Comet
     * @dev Note: This contract must have permission to manage msg.sender's Comet account
     * @dev Note: Assumes wstETH is NOT the base asset
     */
    function supplyStEthTo(address comet, address to, uint stETHAmount) internal {
        if (CometInterface(comet).baseToken() == wsteth) revert UnsupportedBaseAsset();

        doTransferIn(steth, msg.sender, stETHAmount);
        ERC20(steth).approve(wsteth, stETHAmount);
        uint wstETHAmount = IWstETH(wsteth).wrap(stETHAmount);
        ERC20(wsteth).approve(comet, wstETHAmount);
        CometInterface(comet).supplyFrom(address(this), to, wsteth, wstETHAmount);
    }

    /**
     * @notice Withdraws wstETH from Comet, unwraps it to stETH, and transfers it to a user
     * @dev Note: This contract must have permission to manage msg.sender's Comet account
     * @dev Note: Assumes wstETH is NOT the base asset
     * @dev Note: Supports `amount` of `uint256.max` to withdraw all wstETH from Comet. Otherwise,
     *            there could be dust remaining due to loss of precision from exchange rate conversion
     */
    function withdrawStEthTo(address comet, address to, uint stETHAmount) internal {
        if (CometInterface(comet).baseToken() == wsteth) revert UnsupportedBaseAsset();

        uint wstETHAmount = stETHAmount == type(uint256).max
            ? CometInterface(comet).collateralBalanceOf(msg.sender, wsteth)
            : IWstETH(wsteth).getWstETHByStETH(stETHAmount);
        CometInterface(comet).withdrawFrom(msg.sender, address(this), wsteth, wstETHAmount);
        uint unwrappedStETHAmount = IWstETH(wsteth).unwrap(wstETHAmount);
        doTransferOut(steth, to, unwrappedStETHAmount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "./ERC20.sol";

/**
 * @dev Interface for interacting with WstETH contract
 * Note Not a comprehensive interface
 */
interface IWstETH is ERC20 {
    function stETH() external returns (address);

    function wrap(uint256 _stETHAmount) external returns (uint256);
    function unwrap(uint256 _wstETHAmount) external returns (uint256);

    function receive() external payable;

    function getWstETHByStETH(uint256 _stETHAmount) external view returns (uint256);
    function getStETHByWstETH(uint256 _wstETHAmount) external view returns (uint256);

    function stEthPerToken() external view returns (uint256);
    function tokensPerStEth() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "../CometInterface.sol";
import "../IERC20NonStandard.sol";
import "../IWETH9.sol";

/**
 * @dev Interface for claiming rewards from the CometRewards contract
 */
interface IClaimable {
    function claim(address comet, address src, bool shouldAccrue) external;

    function claimTo(address comet, address src, address to, bool shouldAccrue) external;
}

/**
 * @title Compound's Bulker contract
 * @notice Executes multiple Comet-related actions in a single transaction
 * @author Compound
 * @dev Note: Only intended to be used on EVM chains that have a native token and wrapped native token that implements the IWETH interface
 */
contract BaseBulker {
    /** Custom events **/

    event AdminTransferred(address indexed oldAdmin, address indexed newAdmin);

    /** General configuration constants **/

    /// @notice The admin of the Bulker contract
    address public admin;

    /// @notice The address of the wrapped representation of the chain's native asset
    address payable public immutable wrappedNativeToken;

    /** Actions **/

    /// @notice The action for supplying an asset to Comet
    bytes32 public constant ACTION_SUPPLY_ASSET = "ACTION_SUPPLY_ASSET";

    /// @notice The action for supplying a native asset (e.g. ETH on Ethereum mainnet) to Comet
    bytes32 public constant ACTION_SUPPLY_NATIVE_TOKEN = "ACTION_SUPPLY_NATIVE_TOKEN";

    /// @notice The action for transferring an asset within Comet
    bytes32 public constant ACTION_TRANSFER_ASSET = "ACTION_TRANSFER_ASSET";

    /// @notice The action for withdrawing an asset from Comet
    bytes32 public constant ACTION_WITHDRAW_ASSET = "ACTION_WITHDRAW_ASSET";

    /// @notice The action for withdrawing a native asset from Comet
    bytes32 public constant ACTION_WITHDRAW_NATIVE_TOKEN = "ACTION_WITHDRAW_NATIVE_TOKEN";

    /// @notice The action for claiming rewards from the Comet rewards contract
    bytes32 public constant ACTION_CLAIM_REWARD = "ACTION_CLAIM_REWARD";

    /** Custom errors **/

    error InvalidAddress();
    error InvalidArgument();
    error FailedToSendNativeToken();
    error TransferInFailed();
    error TransferOutFailed();
    error Unauthorized();
    error UnhandledAction();

    /**
     * @notice Construct a new BaseBulker instance
     * @param admin_ The admin of the Bulker contract
     * @param wrappedNativeToken_ The address of the wrapped representation of the chain's native asset
     **/
    constructor(address admin_, address payable wrappedNativeToken_) {
        admin = admin_;
        wrappedNativeToken = wrappedNativeToken_;
    }

    /**
     * @notice Fallback for receiving native token. Needed for ACTION_WITHDRAW_NATIVE_TOKEN
     */
    receive() external payable {}

    /**
     * @notice A public function to sweep accidental ERC-20 transfers to this contract
     * @dev Note: Make sure to check that the asset being swept out is not malicious
     * @param recipient The address that will receive the swept funds
     * @param asset The address of the ERC-20 token to sweep
     */
    function sweepToken(address recipient, address asset) external {
        if (msg.sender != admin) revert Unauthorized();

        uint256 balance = IERC20NonStandard(asset).balanceOf(address(this));
        doTransferOut(asset, recipient, balance);
    }

    /**
     * @notice A public function to sweep accidental native token transfers to this contract
     * @param recipient The address that will receive the swept funds
     */
    function sweepNativeToken(address recipient) external {
        if (msg.sender != admin) revert Unauthorized();

        uint256 balance = address(this).balance;
        (bool success, ) = recipient.call{ value: balance }("");
        if (!success) revert FailedToSendNativeToken();
    }

    /**
     * @notice Transfers the admin rights to a new address
     * @param newAdmin The address that will become the new admin
     */
    function transferAdmin(address newAdmin) external {
        if (msg.sender != admin) revert Unauthorized();
        if (newAdmin == address(0)) revert InvalidAddress();

        address oldAdmin = admin;
        admin = newAdmin;
        emit AdminTransferred(oldAdmin, newAdmin);
    }

    /**
     * @notice Executes a list of actions in order
     * @param actions The list of actions to execute in order
     * @param data The list of calldata to use for each action
     */
    function invoke(bytes32[] calldata actions, bytes[] calldata data) external payable {
        if (actions.length != data.length) revert InvalidArgument();

        uint unusedNativeToken = msg.value;
        for (uint i = 0; i < actions.length; ) {
            bytes32 action = actions[i];
            if (action == ACTION_SUPPLY_ASSET) {
                (address comet, address to, address asset, uint amount) = abi.decode(data[i], (address, address, address, uint));
                supplyTo(comet, to, asset, amount);
            } else if (action == ACTION_SUPPLY_NATIVE_TOKEN) {
                (address comet, address to, uint amount) = abi.decode(data[i], (address, address, uint));
                uint256 nativeTokenUsed = supplyNativeTokenTo(comet, to, amount);
                unusedNativeToken -= nativeTokenUsed;
            } else if (action == ACTION_TRANSFER_ASSET) {
                (address comet, address to, address asset, uint amount) = abi.decode(data[i], (address, address, address, uint));
                transferTo(comet, to, asset, amount);
            } else if (action == ACTION_WITHDRAW_ASSET) {
                (address comet, address to, address asset, uint amount) = abi.decode(data[i], (address, address, address, uint));
                withdrawTo(comet, to, asset, amount);
            } else if (action == ACTION_WITHDRAW_NATIVE_TOKEN) {
                (address comet, address to, uint amount) = abi.decode(data[i], (address, address, uint));
                withdrawNativeTokenTo(comet, to, amount);
            } else if (action == ACTION_CLAIM_REWARD) {
                (address comet, address rewards, address src, bool shouldAccrue) = abi.decode(data[i], (address, address, address, bool));
                claimReward(comet, rewards, src, shouldAccrue);
            } else {
                handleAction(action, data[i]);
            }
            unchecked { i++; }
        }

        // Refund unused native token back to msg.sender
        if (unusedNativeToken > 0) {
            (bool success, ) = msg.sender.call{ value: unusedNativeToken }("");
            if (!success) revert FailedToSendNativeToken();
        }
    }

    /**
     * @notice Handles any actions not handled by the BaseBulker implementation
     * @dev Note: Meant to be overridden by contracts that extend BaseBulker and want to support more actions
     */
    function handleAction(bytes32 action, bytes calldata data) virtual internal {
        revert UnhandledAction();
    }

    /**
     * @notice Supplies an asset to a user in Comet
     * @dev Note: This contract must have permission to manage msg.sender's Comet account
     */
    function supplyTo(address comet, address to, address asset, uint amount) internal {
        CometInterface(comet).supplyFrom(msg.sender, to, asset, amount);
    }

    /**
     * @notice Wraps the native token and supplies wrapped native token to a user in Comet
     * @return The amount of the native token wrapped and supplied to Comet
     * @dev Note: Supports `amount` of `uint256.max` only for the base asset. Should revert for a collateral asset
     */
    function supplyNativeTokenTo(address comet, address to, uint amount) internal returns (uint256) {
        uint256 supplyAmount = amount;
        if (wrappedNativeToken == CometInterface(comet).baseToken()) {
            if (amount == type(uint256).max)
                supplyAmount = CometInterface(comet).borrowBalanceOf(msg.sender);
        }
        IWETH9(wrappedNativeToken).deposit{ value: supplyAmount }();
        IWETH9(wrappedNativeToken).approve(comet, supplyAmount);
        CometInterface(comet).supplyFrom(address(this), to, wrappedNativeToken, supplyAmount);
        return supplyAmount;
    }

    /**
     * @notice Transfers an asset to a user in Comet
     * @dev Note: This contract must have permission to manage msg.sender's Comet account
     */
    function transferTo(address comet, address to, address asset, uint amount) internal {
        CometInterface(comet).transferAssetFrom(msg.sender, to, asset, amount);
    }

    /**
     * @notice Withdraws an asset to a user in Comet
     * @dev Note: This contract must have permission to manage msg.sender's Comet account
     */
    function withdrawTo(address comet, address to, address asset, uint amount) internal {
        CometInterface(comet).withdrawFrom(msg.sender, to, asset, amount);
    }

    /**
     * @notice Withdraws wrapped native token from Comet, unwraps it to the native token, and transfers it to a user
     * @dev Note: This contract must have permission to manage msg.sender's Comet account
     * @dev Note: Supports `amount` of `uint256.max` only for the base asset. Should revert for a collateral asset
     */
    function withdrawNativeTokenTo(address comet, address to, uint amount) internal {
        uint256 withdrawAmount = amount;
        if (wrappedNativeToken == CometInterface(comet).baseToken()) {
            if (amount == type(uint256).max)
                withdrawAmount = CometInterface(comet).balanceOf(msg.sender);
        }
        CometInterface(comet).withdrawFrom(msg.sender, address(this), wrappedNativeToken, withdrawAmount);
        IWETH9(wrappedNativeToken).withdraw(withdrawAmount);
        (bool success, ) = to.call{ value: withdrawAmount }("");
        if (!success) revert FailedToSendNativeToken();
    }

    /**
     * @notice Claims rewards for a user
     */
    function claimReward(address comet, address rewards, address src, bool shouldAccrue) internal {
        IClaimable(rewards).claim(comet, src, shouldAccrue);
    }

    /**
     * @notice Similar to ERC-20 transfer, except it properly handles `transferFrom` from non-standard ERC-20 tokens
     * @param asset The ERC-20 token to transfer in
     * @param from The address to transfer from
     * @param amount The amount of the token to transfer
     * @dev Note: This does not check that the amount transferred in is actually equals to the amount specified (e.g. fee tokens will not revert)
     * @dev Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value. See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferIn(address asset, address from, uint amount) internal {
        IERC20NonStandard(asset).transferFrom(from, address(this), amount);

        bool success;
        assembly {
            switch returndatasize()
                case 0 {                       // This is a non-standard ERC-20
                    success := not(0)          // set success to true
                }
                case 32 {                      // This is a compliant ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0)        // Set `success = returndata` of override external call
                }
                default {                      // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        if (!success) revert TransferInFailed();
    }

    /**
     * @notice Similar to ERC-20 transfer, except it properly handles `transfer` from non-standard ERC-20 tokens
     * @param asset The ERC-20 token to transfer out
     * @param to The recipient of the token transfer
     * @param amount The amount of the token to transfer
     * @dev Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value. See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferOut(address asset, address to, uint amount) internal {
        IERC20NonStandard(asset).transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
                case 0 {                      // This is a non-standard ERC-20
                    success := not(0)         // set success to true
                }
                case 32 {                     // This is a compliant ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0)       // Set `success = returndata` of override external call
                }
                default {                     // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        if (!success) revert TransferOutFailed();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface ERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /**
      * @notice Get the total number of tokens in circulation
      * @return The supply of tokens
      */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transfer(address dst, uint256 amount) external returns (bool);

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool);

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved (-1 means infinite)
      * @return Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return The number of tokens allowed to be spent (-1 means infinite)
      */
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

interface IWETH9 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint);

    function allowance(address, address) external view returns (uint);

    receive() external payable;

    function deposit() external payable;

    function withdraw(uint wad) external;

    function totalSupply() external view returns (uint);

    function approve(address guy, uint wad) external returns (bool);

    function transfer(address dst, uint wad) external returns (bool);

    function transferFrom(address src, address dst, uint wad)
    external
    returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "./CometMainInterface.sol";
import "./CometExtInterface.sol";

/**
 * @title Compound's Comet Interface
 * @notice An efficient monolithic money market protocol
 * @author Compound
 */
abstract contract CometInterface is CometMainInterface, CometExtInterface {}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @title IERC20NonStandard
 * @dev Version of ERC20 with no return values for `approve`, `transfer`, and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface IERC20NonStandard {
    function approve(address spender, uint256 amount) external;
    function transfer(address to, uint256 value) external;
    function transferFrom(address from, address to, uint256 value) external;
    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "./CometCore.sol";

/**
 * @title Compound's Comet Ext Interface
 * @notice An efficient monolithic money market protocol
 * @author Compound
 */
abstract contract CometExtInterface is CometCore {
    error BadAmount();
    error BadNonce();
    error BadSignatory();
    error InvalidValueS();
    error InvalidValueV();
    error SignatureExpired();

    function allow(address manager, bool isAllowed) virtual external;
    function allowBySig(address owner, address manager, bool isAllowed, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) virtual external;

    function collateralBalanceOf(address account, address asset) virtual external view returns (uint128);
    function baseTrackingAccrued(address account) virtual external view returns (uint64);

    function baseAccrualScale() virtual external view returns (uint64);
    function baseIndexScale() virtual external view returns (uint64);
    function factorScale() virtual external view returns (uint64);
    function priceScale() virtual external view returns (uint64);

    function maxAssets() virtual external view returns (uint8);

    function totalsBasic() virtual external view returns (TotalsBasic memory);

    function version() virtual external view returns (string memory);

    /**
      * ===== ERC20 interfaces =====
      * Does not include the following functions/events, which are defined in `CometMainInterface` instead:
      * - function decimals() virtual external view returns (uint8)
      * - function totalSupply() virtual external view returns (uint256)
      * - function transfer(address dst, uint amount) virtual external returns (bool)
      * - function transferFrom(address src, address dst, uint amount) virtual external returns (bool)
      * - function balanceOf(address owner) virtual external view returns (uint256)
      * - event Transfer(address indexed from, address indexed to, uint256 amount)
      */
    function name() virtual external view returns (string memory);
    function symbol() virtual external view returns (string memory);

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved (-1 means infinite)
      * @return Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) virtual external returns (bool);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return The number of tokens allowed to be spent (-1 means infinite)
      */
    function allowance(address owner, address spender) virtual external view returns (uint256);

    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "./CometCore.sol";

/**
 * @title Compound's Comet Main Interface (without Ext)
 * @notice An efficient monolithic money market protocol
 * @author Compound
 */
abstract contract CometMainInterface is CometCore {
    error Absurd();
    error AlreadyInitialized();
    error BadAsset();
    error BadDecimals();
    error BadDiscount();
    error BadMinimum();
    error BadPrice();
    error BorrowTooSmall();
    error BorrowCFTooLarge();
    error InsufficientReserves();
    error LiquidateCFTooLarge();
    error NoSelfTransfer();
    error NotCollateralized();
    error NotForSale();
    error NotLiquidatable();
    error Paused();
    error SupplyCapExceeded();
    error TimestampTooLarge();
    error TooManyAssets();
    error TooMuchSlippage();
    error TransferInFailed();
    error TransferOutFailed();
    error Unauthorized();

    event Supply(address indexed from, address indexed dst, uint amount);
    event Transfer(address indexed from, address indexed to, uint amount);
    event Withdraw(address indexed src, address indexed to, uint amount);

    event SupplyCollateral(address indexed from, address indexed dst, address indexed asset, uint amount);
    event TransferCollateral(address indexed from, address indexed to, address indexed asset, uint amount);
    event WithdrawCollateral(address indexed src, address indexed to, address indexed asset, uint amount);

    /// @notice Event emitted when a borrow position is absorbed by the protocol
    event AbsorbDebt(address indexed absorber, address indexed borrower, uint basePaidOut, uint usdValue);

    /// @notice Event emitted when a user's collateral is absorbed by the protocol
    event AbsorbCollateral(address indexed absorber, address indexed borrower, address indexed asset, uint collateralAbsorbed, uint usdValue);

    /// @notice Event emitted when a collateral asset is purchased from the protocol
    event BuyCollateral(address indexed buyer, address indexed asset, uint baseAmount, uint collateralAmount);

    /// @notice Event emitted when an action is paused/unpaused
    event PauseAction(bool supplyPaused, bool transferPaused, bool withdrawPaused, bool absorbPaused, bool buyPaused);

    /// @notice Event emitted when reserves are withdrawn by the governor
    event WithdrawReserves(address indexed to, uint amount);

    function supply(address asset, uint amount) virtual external;
    function supplyTo(address dst, address asset, uint amount) virtual external;
    function supplyFrom(address from, address dst, address asset, uint amount) virtual external;

    function transfer(address dst, uint amount) virtual external returns (bool);
    function transferFrom(address src, address dst, uint amount) virtual external returns (bool);

    function transferAsset(address dst, address asset, uint amount) virtual external;
    function transferAssetFrom(address src, address dst, address asset, uint amount) virtual external;

    function withdraw(address asset, uint amount) virtual external;
    function withdrawTo(address to, address asset, uint amount) virtual external;
    function withdrawFrom(address src, address to, address asset, uint amount) virtual external;

    function approveThis(address manager, address asset, uint amount) virtual external;
    function withdrawReserves(address to, uint amount) virtual external;

    function absorb(address absorber, address[] calldata accounts) virtual external;
    function buyCollateral(address asset, uint minAmount, uint baseAmount, address recipient) virtual external;
    function quoteCollateral(address asset, uint baseAmount) virtual public view returns (uint);

    function getAssetInfo(uint8 i) virtual public view returns (AssetInfo memory);
    function getAssetInfoByAddress(address asset) virtual public view returns (AssetInfo memory);
    function getCollateralReserves(address asset) virtual public view returns (uint);
    function getReserves() virtual public view returns (int);
    function getPrice(address priceFeed) virtual public view returns (uint);

    function isBorrowCollateralized(address account) virtual public view returns (bool);
    function isLiquidatable(address account) virtual public view returns (bool);

    function totalSupply() virtual external view returns (uint256);
    function totalBorrow() virtual external view returns (uint256);
    function balanceOf(address owner) virtual public view returns (uint256);
    function borrowBalanceOf(address account) virtual public view returns (uint256);

    function pause(bool supplyPaused, bool transferPaused, bool withdrawPaused, bool absorbPaused, bool buyPaused) virtual external;
    function isSupplyPaused() virtual public view returns (bool);
    function isTransferPaused() virtual public view returns (bool);
    function isWithdrawPaused() virtual public view returns (bool);
    function isAbsorbPaused() virtual public view returns (bool);
    function isBuyPaused() virtual public view returns (bool);

    function accrueAccount(address account) virtual external;
    function getSupplyRate(uint utilization) virtual public view returns (uint64);
    function getBorrowRate(uint utilization) virtual public view returns (uint64);
    function getUtilization() virtual public view returns (uint);

    function governor() virtual external view returns (address);
    function pauseGuardian() virtual external view returns (address);
    function baseToken() virtual external view returns (address);
    function baseTokenPriceFeed() virtual external view returns (address);
    function extensionDelegate() virtual external view returns (address);

    /// @dev uint64
    function supplyKink() virtual external view returns (uint);
    /// @dev uint64
    function supplyPerSecondInterestRateSlopeLow() virtual external view returns (uint);
    /// @dev uint64
    function supplyPerSecondInterestRateSlopeHigh() virtual external view returns (uint);
    /// @dev uint64
    function supplyPerSecondInterestRateBase() virtual external view returns (uint);
    /// @dev uint64
    function borrowKink() virtual external view returns (uint);
    /// @dev uint64
    function borrowPerSecondInterestRateSlopeLow() virtual external view returns (uint);
    /// @dev uint64
    function borrowPerSecondInterestRateSlopeHigh() virtual external view returns (uint);
    /// @dev uint64
    function borrowPerSecondInterestRateBase() virtual external view returns (uint);
    /// @dev uint64
    function storeFrontPriceFactor() virtual external view returns (uint);

    /// @dev uint64
    function baseScale() virtual external view returns (uint);
    /// @dev uint64
    function trackingIndexScale() virtual external view returns (uint);

    /// @dev uint64
    function baseTrackingSupplySpeed() virtual external view returns (uint);
    /// @dev uint64
    function baseTrackingBorrowSpeed() virtual external view returns (uint);
    /// @dev uint104
    function baseMinForRewards() virtual external view returns (uint);
    /// @dev uint104
    function baseBorrowMin() virtual external view returns (uint);
    /// @dev uint104
    function targetReserves() virtual external view returns (uint);

    function numAssets() virtual external view returns (uint8);
    function decimals() virtual external view returns (uint8);

    function initializeStorage() virtual external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "./CometConfiguration.sol";
import "./CometStorage.sol";
import "./CometMath.sol";

abstract contract CometCore is CometConfiguration, CometStorage, CometMath {
    struct AssetInfo {
        uint8 offset;
        address asset;
        address priceFeed;
        uint64 scale;
        uint64 borrowCollateralFactor;
        uint64 liquidateCollateralFactor;
        uint64 liquidationFactor;
        uint128 supplyCap;
    }

    /** Internal constants **/

    /// @dev The max number of assets this contract is hardcoded to support
    ///  Do not change this variable without updating all the fields throughout the contract,
    //    including the size of UserBasic.assetsIn and corresponding integer conversions.
    uint8 internal constant MAX_ASSETS = 15;

    /// @dev The max number of decimals base token can have
    ///  Note this cannot just be increased arbitrarily.
    uint8 internal constant MAX_BASE_DECIMALS = 18;

    /// @dev The max value for a collateral factor (1)
    uint64 internal constant MAX_COLLATERAL_FACTOR = FACTOR_SCALE;

    /// @dev Offsets for specific actions in the pause flag bit array
    uint8 internal constant PAUSE_SUPPLY_OFFSET = 0;
    uint8 internal constant PAUSE_TRANSFER_OFFSET = 1;
    uint8 internal constant PAUSE_WITHDRAW_OFFSET = 2;
    uint8 internal constant PAUSE_ABSORB_OFFSET = 3;
    uint8 internal constant PAUSE_BUY_OFFSET = 4;

    /// @dev The decimals required for a price feed
    uint8 internal constant PRICE_FEED_DECIMALS = 8;

    /// @dev 365 days * 24 hours * 60 minutes * 60 seconds
    uint64 internal constant SECONDS_PER_YEAR = 31_536_000;

    /// @dev The scale for base tracking accrual
    uint64 internal constant BASE_ACCRUAL_SCALE = 1e6;

    /// @dev The scale for base index (depends on time/rate scales, not base token)
    uint64 internal constant BASE_INDEX_SCALE = 1e15;

    /// @dev The scale for prices (in USD)
    uint64 internal constant PRICE_SCALE = uint64(10 ** PRICE_FEED_DECIMALS);

    /// @dev The scale for factors
    uint64 internal constant FACTOR_SCALE = 1e18;

    /**
     * @notice Determine if the manager has permission to act on behalf of the owner
     * @param owner The owner account
     * @param manager The manager account
     * @return Whether or not the manager has permission
     */
    function hasPermission(address owner, address manager) public view returns (bool) {
        return owner == manager || isAllowed[owner][manager];
    }

    /**
     * @dev The positive present supply balance if positive or the negative borrow balance if negative
     */
    function presentValue(int104 principalValue_) internal view returns (int256) {
        if (principalValue_ >= 0) {
            return signed256(presentValueSupply(baseSupplyIndex, uint104(principalValue_)));
        } else {
            return -signed256(presentValueBorrow(baseBorrowIndex, uint104(-principalValue_)));
        }
    }

    /**
     * @dev The principal amount projected forward by the supply index
     */
    function presentValueSupply(uint64 baseSupplyIndex_, uint104 principalValue_) internal pure returns (uint256) {
        return uint256(principalValue_) * baseSupplyIndex_ / BASE_INDEX_SCALE;
    }

    /**
     * @dev The principal amount projected forward by the borrow index
     */
    function presentValueBorrow(uint64 baseBorrowIndex_, uint104 principalValue_) internal pure returns (uint256) {
        return uint256(principalValue_) * baseBorrowIndex_ / BASE_INDEX_SCALE;
    }

    /**
     * @dev The positive principal if positive or the negative principal if negative
     */
    function principalValue(int256 presentValue_) internal view returns (int104) {
        if (presentValue_ >= 0) {
            return signed104(principalValueSupply(baseSupplyIndex, uint256(presentValue_)));
        } else {
            return -signed104(principalValueBorrow(baseBorrowIndex, uint256(-presentValue_)));
        }
    }

    /**
     * @dev The present value projected backward by the supply index (rounded down)
     *  Note: This will overflow (revert) at 2^104/1e18=~20 trillion principal for assets with 18 decimals.
     */
    function principalValueSupply(uint64 baseSupplyIndex_, uint256 presentValue_) internal pure returns (uint104) {
        return safe104((presentValue_ * BASE_INDEX_SCALE) / baseSupplyIndex_);
    }

    /**
     * @dev The present value projected backward by the borrow index (rounded up)
     *  Note: This will overflow (revert) at 2^104/1e18=~20 trillion principal for assets with 18 decimals.
     */
    function principalValueBorrow(uint64 baseBorrowIndex_, uint256 presentValue_) internal pure returns (uint104) {
        return safe104((presentValue_ * BASE_INDEX_SCALE + baseBorrowIndex_ - 1) / baseBorrowIndex_);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @title Compound's Comet Storage Interface
 * @dev Versions can enforce append-only storage slots via inheritance.
 * @author Compound
 */
contract CometStorage {
    // 512 bits total = 2 slots
    struct TotalsBasic {
        // 1st slot
        uint64 baseSupplyIndex;
        uint64 baseBorrowIndex;
        uint64 trackingSupplyIndex;
        uint64 trackingBorrowIndex;
        // 2nd slot
        uint104 totalSupplyBase;
        uint104 totalBorrowBase;
        uint40 lastAccrualTime;
        uint8 pauseFlags;
    }

    struct TotalsCollateral {
        uint128 totalSupplyAsset;
        uint128 _reserved;
    }

    struct UserBasic {
        int104 principal;
        uint64 baseTrackingIndex;
        uint64 baseTrackingAccrued;
        uint16 assetsIn;
        uint8 _reserved;
    }

    struct UserCollateral {
        uint128 balance;
        uint128 _reserved;
    }

    struct LiquidatorPoints {
        uint32 numAbsorbs;
        uint64 numAbsorbed;
        uint128 approxSpend;
        uint32 _reserved;
    }

    /// @dev Aggregate variables tracked for the entire market
    uint64 internal baseSupplyIndex;
    uint64 internal baseBorrowIndex;
    uint64 internal trackingSupplyIndex;
    uint64 internal trackingBorrowIndex;
    uint104 internal totalSupplyBase;
    uint104 internal totalBorrowBase;
    uint40 internal lastAccrualTime;
    uint8 internal pauseFlags;

    /// @notice Aggregate variables tracked for each collateral asset
    mapping(address => TotalsCollateral) public totalsCollateral;

    /// @notice Mapping of users to accounts which may be permitted to manage the user account
    mapping(address => mapping(address => bool)) public isAllowed;

    /// @notice The next expected nonce for an address, for validating authorizations via signature
    mapping(address => uint) public userNonce;

    /// @notice Mapping of users to base principal and other basic data
    mapping(address => UserBasic) public userBasic;

    /// @notice Mapping of users to collateral data per collateral asset
    mapping(address => mapping(address => UserCollateral)) public userCollateral;

    /// @notice Mapping of magic liquidator points
    mapping(address => LiquidatorPoints) public liquidatorPoints;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @title Compound's Comet Math Contract
 * @dev Pure math functions
 * @author Compound
 */
contract CometMath {
    /** Custom errors **/

    error InvalidUInt64();
    error InvalidUInt104();
    error InvalidUInt128();
    error InvalidInt104();
    error InvalidInt256();
    error NegativeNumber();

    function safe64(uint n) internal pure returns (uint64) {
        if (n > type(uint64).max) revert InvalidUInt64();
        return uint64(n);
    }

    function safe104(uint n) internal pure returns (uint104) {
        if (n > type(uint104).max) revert InvalidUInt104();
        return uint104(n);
    }

    function safe128(uint n) internal pure returns (uint128) {
        if (n > type(uint128).max) revert InvalidUInt128();
        return uint128(n);
    }

    function signed104(uint104 n) internal pure returns (int104) {
        if (n > uint104(type(int104).max)) revert InvalidInt104();
        return int104(n);
    }

    function signed256(uint256 n) internal pure returns (int256) {
        if (n > uint256(type(int256).max)) revert InvalidInt256();
        return int256(n);
    }

    function unsigned104(int104 n) internal pure returns (uint104) {
        if (n < 0) revert NegativeNumber();
        return uint104(n);
    }

    function unsigned256(int256 n) internal pure returns (uint256) {
        if (n < 0) revert NegativeNumber();
        return uint256(n);
    }

    function toUInt8(bool x) internal pure returns (uint8) {
        return x ? 1 : 0;
    }

    function toBool(uint8 x) internal pure returns (bool) {
        return x != 0;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @title Compound's Comet Configuration Interface
 * @author Compound
 */
contract CometConfiguration {
    struct ExtConfiguration {
        bytes32 name32;
        bytes32 symbol32;
    }

    struct Configuration {
        address governor;
        address pauseGuardian;
        address baseToken;
        address baseTokenPriceFeed;
        address extensionDelegate;

        uint64 supplyKink;
        uint64 supplyPerYearInterestRateSlopeLow;
        uint64 supplyPerYearInterestRateSlopeHigh;
        uint64 supplyPerYearInterestRateBase;
        uint64 borrowKink;
        uint64 borrowPerYearInterestRateSlopeLow;
        uint64 borrowPerYearInterestRateSlopeHigh;
        uint64 borrowPerYearInterestRateBase;
        uint64 storeFrontPriceFactor;
        uint64 trackingIndexScale;
        uint64 baseTrackingSupplySpeed;
        uint64 baseTrackingBorrowSpeed;
        uint104 baseMinForRewards;
        uint104 baseBorrowMin;
        uint104 targetReserves;

        AssetConfig[] assetConfigs;
    }

    struct AssetConfig {
        address asset;
        address priceFeed;
        uint8 decimals;
        uint64 borrowCollateralFactor;
        uint64 liquidateCollateralFactor;
        uint64 liquidationFactor;
        uint128 supplyCap;
    }
}