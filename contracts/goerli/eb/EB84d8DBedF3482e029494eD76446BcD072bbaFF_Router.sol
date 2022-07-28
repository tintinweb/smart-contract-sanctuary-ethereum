// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

import "./interfaces/connext/IConnext.sol";
import "./interfaces/connext/IExecutor.sol";
import "./interfaces/IVault.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Testnet only: mapper of equivalent assets on destination chain.
import "./mocks/TestnetMapper.sol";

// Testnet only
interface IERC20Mintable is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;
}

contract Router {
    struct VaultParams {
        address asset;
        address debtAsset;
    }

    mapping(uint256 => address) public routerByDomain;

    IConnext public connext; // TODO SECURITY make immutable
    address public promiseRouter; // TODO SECURITY make immutable
    IExecutor public executor; // The address of the Connext Executor contract

    mapping(IVault => VaultParams) public registeredVaults;

    // Testnet only: dummy test token for required connext argument.
    address public connextTestToken;
    // Testnet only: dummy wallet that receives token dump during testing.
    address public DUMMY_WALLET = 0x3b51Bc41C9Eda453aa50b6Bc43D48e0795Ce52f2;
    // Testnet only: tesnet mapper for aave asset addresses at destination chain.
    ITestnetMapper public tesnetMapper;

    // A modifier for permissioning the callback.
    // Note: This is an important security consideration. Only the PromiseRouter (the
    //       Connext contract that executes the callback function) should be able to
    //       call the callback function.
    modifier onlyPromiseRouter() {
        require(msg.sender == address(promiseRouter), "Expected PromiseRouter");
        _;
    }

    // A modifier for permissioned function calls.
    // Note: This is an important security consideration. If your target
    //       contract function is meant to be permissioned, it must check
    //       that the originating call is from the correct domain and contract.
    //       Also, check that the msg.sender is the Connext Executor address.
    modifier onlyConnextExecutor(uint32 originDomain) {
        require(
            IExecutor(msg.sender).originSender() ==
                routerByDomain[originDomain] &&
                IExecutor(msg.sender).origin() == originDomain &&
                msg.sender == address(executor),
            "Expected origin contract on origin domain called by Executor"
        );
        _;
    }

    constructor(
        IConnext connext_,
        address promiseRouter_,
        address connextTestToken_,
        IVault vault_,
        address tesnetMapper_
    ) {
        connext = connext_;
        promiseRouter = promiseRouter_;
        executor = connext.executor();

        registerVault(vault_);

        connextTestToken = connextTestToken_;
        tesnetMapper = ITestnetMapper(tesnetMapper_);
    }

    function depositBorrow(
        IVault vault,
        uint256 assets,
        uint256 debt,
        address owner
    ) public {
        _depositBorrow(vault, assets, debt, msg.sender, msg.sender, owner);
    }

    function depositBorrowAndBridgeTestnet(
        IVault vault,
        uint256 assets,
        uint256 debt,
        address owner,
        uint32 destDomain
    ) external {
        // Testnet only: send testnet token to DUMMY_WALLET, mint collateral assets
        // Required: since Connext doesnt support bridging of Aave asset types.
        _beforeDepositBorrowTestnetHook(vault, assets);

        _depositBorrowTestnet(vault, assets, debt, address(this), owner); // Testnet only:

        // Testnet only: send borrowed tokens to DUMMY_WALLET, and mint debt as testnet token
        // Required: since Connext doesnt support bridging of Aave asset types.
        _afterDepositBorrowTestnetHook(vault, debt);

        // Testnet only: disburseTestnet() needs to be called on dest chain since connext doesnt support bridging of Aave asset types.
        address mapped = tesnetMapper.getMapping(
            registeredVaults[vault].debtAsset,
            destDomain
        );

        uint32 originDomain = uint32(connext.domain());

        bytes memory callData = abi.encodeWithSelector(
            Router.disburseTestnet.selector,
            debt,
            owner,
            mapped,
            originDomain
        );

        IConnext.CallParams memory callParams = IConnext.CallParams({
            to: routerByDomain[destDomain],
            callData: callData,
            originDomain: originDomain,
            destinationDomain: destDomain,
            agent: routerByDomain[destDomain], // address allowed to transaction on destination side in addition to relayers
            recovery: routerByDomain[destDomain], // fallback address to send funds to if execution fails on destination side
            forceSlow: true, // option to force Nomad slow path (~30 mins) instead of paying 0.05% fee
            receiveLocal: false, // option to receive the local Nomad-flavored asset instead of the adopted asset
            callback: address(0), // this contract implements the callback
            callbackFee: 0, // fee paid to relayers; relayers don't take any fees on testnet
            relayerFee: 0, // fee paid to relayers; relayers don't take any fees on testnet
            slippageTol: 9995 // tolerate .05% slippage
        });

        IConnext.XCallArgs memory xcallArgs = IConnext.XCallArgs({
            params: callParams,
            transactingAssetId: connextTestToken,
            amount: debt
        });

        connext.xcall(xcallArgs);
    }

    function _depositBorrow(
        IVault vault,
        uint256 assets,
        uint256 debt,
        address caller,
        address receiver,
        address owner
    ) internal {
        // TODO SECURITY permit operation for borrowing on-behalf the owner!!!!
        address asset = registeredVaults[vault].asset;
        require(asset != address(0), "Not registered!");
        SafeERC20.safeTransferFrom(
            IERC20(asset),
            caller,
            address(this),
            assets
        );
        vault.deposit(assets, owner);
        vault.borrow(debt, receiver, owner);
    }

    function _depositBorrowTestnet(
        IVault vault,
        uint256 assets,
        uint256 debt,
        address receiver,
        address owner
    ) internal {
        // TODO SECURITY permit operation for borrowing on-behalf the owner!!!!
        address asset = registeredVaults[vault].asset;
        require(asset != address(0), "Not registered!");
        vault.deposit(assets, owner);
        vault.borrow(debt, receiver, owner);
    }

    // Testnet only: send testnet token to DUMMY_WALLET, mint collateral assets
    // Required: since Connext doesn't support bridging of Aave asset types.
    function _beforeDepositBorrowTestnetHook(IVault vault, uint256 assets)
        internal
    {
        SafeERC20.safeTransferFrom(
            IERC20(connextTestToken),
            msg.sender,
            DUMMY_WALLET,
            assets
        );
        address asset = registeredVaults[vault].asset;
        IERC20Mintable(asset).mint(address(this), assets); // Minting weth collateral accepted in AaveV3.
    }

    // Testnet only: send borrowed tokens to DUMMY_WALLET, and mint debt as testnet token
    // Required: since Connext doesnt support bridging of Aave asset types.
    function _afterDepositBorrowTestnetHook(IVault vault, uint256 debt)
        internal
    {
        address debtAsset = registeredVaults[vault].debtAsset;
        SafeERC20.safeTransfer(IERC20(debtAsset), DUMMY_WALLET, debt);
        IERC20Mintable(connextTestToken).mint(address(this), debt);
        SafeERC20.safeApprove(IERC20(connextTestToken), address(connext), debt); // Removing Connext Test Token
    }

    // Testnet only: mint debt asset on destination chain since connext doesnt support bridging of Aave specific asset types.
    function disburseTestnet(
        uint256 amount,
        address owner,
        address mapped,
        uint32 originDomain
    ) external onlyConnextExecutor(originDomain) {
        SafeERC20.safeTransferFrom(
            IERC20(connextTestToken),
            msg.sender,
            DUMMY_WALLET,
            amount
        );
        IERC20Mintable(mapped).mint(owner, amount);
    }

    ///////////////////////
    /// Admin functions ///
    ///////////////////////

    // Testnet only: needed as argument to make xCalls at ConnextHandler
    function setConnextTestToken(address addr_) external {
        connextTestToken = addr_;
    }

    // Testnet only: needed since connext doesnt support bridging of Aave specific asset types.
    function setTestnetMapper(address addr_) external {
        tesnetMapper = ITestnetMapper(addr_);
    }

    function setRouter(uint32 domain, address router) external {
        // TODO SECURITY restrict this function
        routerByDomain[domain] = router;
        // TODO emit an event
    }

    function setConnextHandler(address addr_) external {
        // TODO SECURITY remove this setter function.
        connext = IConnext(addr_);
    }

    function setPromiseRouter(address addr_) external {
        // TODO SECURITY remove this setter function.
        promiseRouter = addr_;
    }

    function registerVault(IVault vault) public {
        // TODO SECURITY restrict this function
        VaultParams memory params;
        address asset = vault.asset();
        params.asset = asset;
        SafeERC20.safeApprove(IERC20(asset), address(vault), type(uint256).max);
        try vault.debtAsset() {
            address debtAsset = vault.debtAsset();
            params.debtAsset = debtAsset;
            SafeERC20.safeApprove(
                IERC20(debtAsset),
                address(vault),
                type(uint256).max
            );
        } catch {
            params.debtAsset = address(0);
        }
        registeredVaults[vault] = params;
        // TODO emit an event
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

import "./IExecutor.sol";

/**
 * @title IConnextHandler interface stripped down version.
 * @author fujidao Labs
 */
interface IConnext {
  // ============= Structs =============

  /**
  * @notice These are the call parameters that will remain constant between the
  * two chains. They are supplied on `xcall` and should be asserted on `execute`
  * @property to - The account that receives funds, in the event of a crosschain call,
  * will receive funds if the call fails.
  * @param to - The address you are sending funds (and potentially data) to
  * @param callData - The data to execute on the receiving chain. If no crosschain call is needed, then leave empty.
  * @param originDomain - The originating domain (i.e. where `xcall` is called). Must match nomad domain schema
  * @param destinationDomain - The final domain (i.e. where `execute` / `reconcile` are called). Must match nomad domain schema
  * @param agent - An address who can execute txs on behalf of `to`, in addition to allowing relayers
  * @param recovery - The address to send funds to if your `Executor.execute call` fails
  * @param callback - The address on the origin domain of the callback contract
  * @param callbackFee - The relayer fee to execute the callback
  * @param forceSlow - If true, will take slow liquidity path even if it is not a permissioned call
  * @param receiveLocal - If true, will use the local nomad asset on the destination instead of adopted.
  * @param relayerFee - The amount of relayer fee the tx called xcall with
  * @param slippageTol - Max bps of original due to slippage (i.e. would be 9995 to tolerate .05% slippage)
  */
  struct CallParams {
    address to;
    bytes callData;
    uint32 originDomain;
    uint32 destinationDomain;
    address agent;
    address recovery;
    bool forceSlow;
    bool receiveLocal;
    address callback;
    uint256 callbackFee;
    uint256 relayerFee;
    uint256 slippageTol;
  }

  /**
  * @notice The arguments you supply to the `xcall` function called by user on origin domain
  * @param params - The CallParams. These are consistent across sending and receiving chains
  * @param transactingAssetId - The asset the caller sent with the transfer. Can be the adopted, canonical,
  * or the representational asset
  * @param amount - The amount of transferring asset the tx called xcall with
  */
  struct XCallArgs {
    CallParams params;
    address transactingAssetId; // Could be adopted, local, or wrapped
    uint256 amount;
  }

  function domain() external view returns (uint256);

  function xcall(XCallArgs calldata _args) external payable returns (bytes32);

  function executor() external view returns (IExecutor);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IExecutor {
  /**
   * @param _transferId Unique identifier of transaction id that necessitated
   * calldata execution
   * @param _amount The amount to approve or send with the call
   * @param _to The address to execute the calldata on
   * @param _assetId The assetId of the funds to approve to the contract or
   * send along with the call
   * @param _properties The origin properties
   * @param _callData The data to execute
   */
  struct ExecutorArgs {
    bytes32 transferId;
    uint256 amount;
    address to;
    address recovery;
    address assetId;
    bytes properties;
    bytes callData;
  }

  event Executed(
    bytes32 indexed transferId,
    address indexed to,
    address indexed recovery,
    address assetId,
    uint256 amount,
    bytes _properties,
    bytes callData,
    bytes returnData,
    bool success
  );

  function getConnext() external returns (address);

  function originSender() external returns (address);

  function origin() external returns (uint32);

  function amount() external returns (uint256);

  function execute(ExecutorArgs calldata _args) external payable returns (bool success, bytes memory returnData);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

/**
 * @title Vault interface.
 * @author fujidao Labs
 * @notice  Defines the interface for vault operations extending from IERC4326.
 */

import "@openzeppelin/contracts/interfaces/IERC4626.sol";

interface IVault is IERC4626 {

  /**
  * @dev Returns the address of the debt underlying token used for the Vault for borrowing and payback accounting.
  *
  * - MUST be an ERC-20 token contract.
  * - MUST NOT revert.
  */
  function debtAsset() external view returns (address);

  /**
  * @dev Mints debtShares to onBehalf by taking a loan of exact amount of underlying tokens.
  *
  * - MUST emit the Borrow event.
  * - MUST revert if owner does not own sufficient collateral to back debt.
  * - MUST revert if caller is not onBehalf or permission to act onBehalf.
  *
  */
  function borrow(uint256 debt, address receiver, address owner) external returns (uint256);

  /**
  * @dev burns debtShares to onBehalf by paying back loan with exact amount of underlying tokens.
  *
  * - MUST emit the Payback event.
  *
  * NOTE: most implementations will require pre-erc20-approval of the underlying asset token.
  */
  function payback(uint256 debt, address owner) external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Contract that stores and returns addresses mappings
 * Required for getting contract addresses for some providers and flashloan providers
 */
interface ITestnetMapper {
    function getMapping(address originAsset, uint32 destDomain)
        external
        view
        returns (address);
}

contract TesnetMapper is Ownable {
    // Origin chain asset => destination domain => equivalent chain asset
    mapping(address => mapping(uint32 => address)) private _addrMapping;

    function getMapping(address originAsset, uint32 destDomain)
        public
        view
        returns (address)
    {
        return _addrMapping[originAsset][destDomain];
    }

    function setMappings(
        uint32 destDomain,
        address[] memory originAddr_,
        address[] memory destAddr_
    ) public onlyOwner {
        uint256 olenght = originAddr_.length;
        require(olenght == destAddr_.length, "Invalid inputs!");
        for (uint256 i = 0; i < olenght; ) {
            _addrMapping[originAddr_[i]][destDomain] = destAddr_[i];
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";
import "../token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}