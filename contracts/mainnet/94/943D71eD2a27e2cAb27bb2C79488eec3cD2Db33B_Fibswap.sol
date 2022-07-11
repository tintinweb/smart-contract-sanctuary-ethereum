// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "./interfaces/IWrapped.sol";
import "./interfaces/IFibswap.sol";
import "./interfaces/IERC20Extended.sol";

import {IExecutor, Executor} from "./interpreters/Executor.sol";
import {RouterPermissionsManager} from "./RouterPermissionsManager.sol";

import {FibswapUtils} from "./lib/Fibswap/FibswapUtils.sol";

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable, OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract Fibswap is
  Initializable,
  UUPSUpgradeable,
  ReentrancyGuardUpgradeable,
  OwnableUpgradeable,
  RouterPermissionsManager,
  IFibswap
{
  // ========== Custom Errors ===========

  error Fibswap__removeAssetId_notAdded();
  error Fibswap__removeLiquidity_recipientEmpty();
  error Fibswap__removeLiquidity_amountIsZero();
  error Fibswap__removeLiquidity_insufficientFunds();
  error Fibswap__xcall_notSupportedAsset();
  error Fibswap__xcall_wrongDomain();
  error Fibswap__xcall_emptyTo();
  error Fibswap__xcall_notGasFee();
  error Fibswap__xcall_notApprovedRouter();
  error Fibswap__xcall_invalidSwapRouer();
  error Fibswap__xcall_tooSmallLocalAmount();
  error Fibswap__xcall_tooBigSlippage();
  error Fibswap__execute_unapprovedRouter();
  error Fibswap__execute_invalidRouterSignature();
  error Fibswap__execute_alreadyExecuted();
  error Fibswap__execute_incorrectDestination();
  error Fibswap__addLiquidityForRouter_routerEmpty();
  error Fibswap__addLiquidityForRouter_amountIsZero();
  error Fibswap__addLiquidityForRouter_badRouter();
  error Fibswap__addLiquidityForRouter_badAsset();
  error Fibswap__addAssetId_alreadyAdded();
  error Fibswap__addAssetIds_invalidArgs();
  error Fibswap__decrementLiquidity_notEmpty();
  error Fibswap__addSwapRouter_invalidArgs();
  error Fibswap__addSwapRouter_invalidSwapRouterAddress();
  error Fibswap__addSwapRouter_alreadyApproved();
  error Fibswap__removeSwapRouter_invalidArgs();
  error Fibswap__removeSwapRouter_alreadyRemoved();

  // ============ Constants =============

  bytes32 internal constant EMPTY = hex"c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470";

  /// @dev Normal Service Fee percent
  uint256 public constant PERCENTS_DIVIDER = 10000;

  // ============ Properties ============

  uint256 public chainId;
  uint256 public nonce;
  uint256 public feePercent;

  IWrapped public wrapper;
  IExecutor public executor;

  // swap router address => approved?
  mapping(address => bool) public swapRouters;
  // local assetId => approved?
  mapping(address => bool) public approvedAssets;
  // rotuer address => local assetId => balance
  mapping(address => mapping(address => uint256)) public routerBalances;
  // transferId => processed?
  mapping(bytes32 => bool) public processed;

  // ============ Modifiers ============

  // ========== Initializer ============

  function initialize(
    uint256 _chainId,
    address _owner,
    address _wrapper
  ) public override initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    __RouterPermissionsManager_init();

    transferOwnership(_owner);

    nonce = 0;
    chainId = _chainId;
    wrapper = IWrapped(_wrapper);

    feePercent = 300; // 3%
    maxAllowSlippage = 300; // 3%
  }

  function _authorizeUpgrade(address) internal override onlyOwner {}

  // ============ Owner Functions ============
  /**
   * @notice Owner can set  normal fee percent
   * @param _percent normal fee percentage
   **/
  function setFeePercent(uint256 _percent) external onlyOwner {
    require(_percent < PERCENTS_DIVIDER / 5, "too big fee");

    feePercent = _percent;

    // Emit event
    emit NewFeePercent(_percent, msg.sender);
  }

  /**
   * @notice Owner can set max allowed slippage
   * @param _percent percentage
   **/
  function setMaxAllowSlippage(uint256 _percent) external onlyOwner {
    require(_percent < PERCENTS_DIVIDER / 5, "too big");

    maxAllowSlippage = _percent;

    // Emit event
    emit NewMaxAllowSlippage(_percent, msg.sender);
  }

  /**
   * @notice Owner can set  executor
   * @param _executor new executor address
   **/
  function setExecutor(address _executor) external onlyOwner {
    require(AddressUpgradeable.isContract(_executor), "!contract");

    executor = IExecutor(_executor);

    // Emit event
    emit NewExecutor(_executor, msg.sender);
  }

  /**
   * @notice Used to set router initial properties
   * @param router Router address to setup
   * @param owner Initial Owner of router
   * @param recipient Initial Recipient of router
   */
  function setupRouter(
    address router,
    address owner,
    address recipient
  ) external onlyOwner {
    _setupRouter(router, owner, recipient);
  }

  /**
   * @notice Used to remove routers that can transact crosschain
   * @param router Router address to remove
   */
  function removeRouter(address router) external override onlyOwner {
    _removeRouter(router);
  }

  /**
   * @notice set swap routers
   */
  function addSwapRouter(address[] memory routers) external onlyOwner {
    if (routers.length == 0) revert Fibswap__addSwapRouter_invalidArgs();
    for (uint256 i; i < routers.length; ) {
      _addSwapRouter(routers[i]);
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice remove swap router
   */
  function removeSwapRouter(address _swapRouter) external onlyOwner {
    if (_swapRouter == address(0)) revert Fibswap__removeSwapRouter_invalidArgs();
    if (!swapRouters[_swapRouter]) revert Fibswap__removeSwapRouter_alreadyRemoved();

    swapRouters[_swapRouter] = false;

    emit SwapRouterUpdated(_swapRouter, false, msg.sender);
  }

  /**
   * @notice Used to add supported assets. This is an admin only function
   * @param localAssets - The assets to add
   */
  function addAssetIds(address[] memory localAssets) external onlyOwner {
    if (localAssets.length == 0) revert Fibswap__addAssetIds_invalidArgs();
    for (uint256 i; i < localAssets.length; ) {
      _addAssetId(localAssets[i]);

      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice Used to remove assets from the whitelist
   * @param localAssetId - Corresponding local asset to remove
   */
  function removeAssetId(address localAssetId) external override onlyOwner {
    // Sanity check: already approval
    if (!approvedAssets[localAssetId]) revert Fibswap__removeAssetId_notAdded();

    // Update mapping
    delete approvedAssets[localAssetId];

    // Emit event
    emit AssetRemoved(localAssetId, msg.sender);
  }

  /**
   * @notice Used to update wapped token address
   * @param _wrapped - Wrapped asset address
   */
  function setWrapped(address _wrapped) external onlyOwner {
    if (!AddressUpgradeable.isContract(_wrapped)) revert();

    wrapper = IWrapped(_wrapped);
  }

  // ============ Public Functions ============

  /**
   * @notice This is used by anyone to increase a router's available liquidity for a given asset.
   * @param amount - The amount of liquidity to add for the router
   * @param local - The address of the asset you're adding liquidity for. If adding liquidity of the
   * native asset, routers may use `address(0)` or the wrapped asset
   * @param router The router you are adding liquidity on behalf of
   */
  function addLiquidityFor(
    uint256 amount,
    address local,
    address router
  ) external payable override nonReentrant {
    _addLiquidityForRouter(amount, local, router);
  }

  /**
   * @notice This is used by any router to increase their available liquidity for a given asset.
   * @param amount - The amount of liquidity to add for the router
   * @param local - The address of the asset you're adding liquidity for. If adding liquidity of the
   * native asset, routers may use `address(0)` or the wrapped asset
   */
  function addLiquidity(uint256 amount, address local) external payable override nonReentrant {
    _addLiquidityForRouter(amount, local, msg.sender);
  }

  /**
   * @notice This is used by any router to decrease their available liquidity for a given asset.
   * @param amount - The amount of liquidity to remove for the router
   * @param local - The address of the asset you're removing liquidity from. If removing liquidity of the
   * native asset, routers may use `address(0)` or the wrapped asset
   */
  function removeLiquidity(uint256 amount, address local) external override nonReentrant {
    // transfer to specicfied recipient IF recipient not set
    address _recipient = routerRecipients(msg.sender);

    // Sanity check: to is sensible
    if (_recipient == address(0)) revert Fibswap__removeLiquidity_recipientEmpty();

    // Sanity check: nonzero amounts
    if (amount == 0) revert Fibswap__removeLiquidity_amountIsZero();

    uint256 routerBalance = routerBalances[msg.sender][local];
    // Sanity check: amount can be deducted for the router
    if (routerBalance < amount) revert Fibswap__removeLiquidity_insufficientFunds();

    // Update router balances
    unchecked {
      routerBalances[msg.sender][local] = routerBalance - amount;
    }

    // Transfer from contract to specified to
    FibswapUtils.transferAssetFromContract(local, _recipient, amount, false, wrapper);

    // Emit event
    emit LiquidityRemoved(msg.sender, _recipient, local, amount, msg.sender);
  }

  /**
   * @notice This function is called by a user who is looking to bridge funds
   * @dev This contract must have approval to transfer the transacting assets. They are then swapped to
   * the local assets via the configured AMM and sent over the bridge router.
   * @param _args - The XCallArgs
   * @return The transfer id of the crosschain transfer
   */
  function xcall(XCallArgs calldata _args) external payable override returns (bytes32) {
    _xcallSanityChecks(_args);

    // Transfer funds to the contract
    (address _transactingAssetId, uint256 _amount) = FibswapUtils.handleIncomingAsset(
      _args.transactingAssetId,
      _args.amount,
      _args.relayerFee,
      _args.params.router,
      wrapper
    );

    // Swap to the local asset from the adopted
    address localAsset = _args.params.orgLocalAsset;
    if (localAsset != _transactingAssetId) {
      if (!swapRouters[_args.params.orgParam.to]) {
        revert Fibswap__xcall_invalidSwapRouer();
      }

      _amount = FibswapUtils.swapToLocalAssetIfNeeded(localAsset, _transactingAssetId, _amount, _args.params.orgParam);
    }

    // check min Local Amount without Fee
    uint256 localAmount = _args.localAmount;
    uint256 underlyingAmount = _handleIncomingAsset(_amount, localAmount, localAsset);

    // send fee
    FibswapUtils.transferAssetFromContract(
      localAsset,
      routerRecipients(_args.params.router),
      _amount - localAmount,
      true,
      wrapper
    );

    // increase router balance
    routerBalances[_args.params.router][localAsset] += localAmount;

    // Compute the transfer id
    bytes32 _transferId = FibswapUtils.getTransferId(nonce, msg.sender, _args.params, underlyingAmount);

    // Emit event
    emit XCalled(
      _transferId,
      _args.params,
      _transactingAssetId,
      localAsset,
      _args.amount,
      underlyingAmount,
      nonce,
      _args.relayerFee,
      msg.sender
    );

    // Update nonce
    nonce++;

    // Return the transfer id
    return _transferId;
  }

  /**
   * @notice This function is called by a user who is looking to bridge funds to estimate xcall
   * @dev This contract must have approval to transfer the transacting assets. They are then swapped to
   * the local assets via the configured AMM and sent over the bridge router.
   * @param _args - The XCallArgs
   * @return The underlying amount
   */
  function estimateXcall(XCallArgs calldata _args) external returns (uint256) {
    _xcallSanityChecks(_args);

    // Transfer funds to the contract
    (address _transactingAssetId, uint256 _amount) = FibswapUtils.handleIncomingAsset(
      _args.transactingAssetId,
      _args.amount,
      _args.relayerFee,
      _args.params.router,
      wrapper
    );

    // Swap to the local asset from the adopted
    address localAsset = _args.params.orgLocalAsset;
    if (localAsset != _transactingAssetId) {
      if (!swapRouters[_args.params.orgParam.to]) {
        revert Fibswap__xcall_invalidSwapRouer();
      }

      _amount = FibswapUtils.swapToLocalAssetIfNeeded(localAsset, _transactingAssetId, _amount, _args.params.orgParam);
    }

    // check min Local Amount without Fee
    uint256 localAmount = _args.localAmount;
    uint256 underlyingAmount = _handleIncomingAsset(_amount, localAmount, localAsset);

    return underlyingAmount;
  }

  /**
   * @notice This function is called on the destination chain when the bridged asset should be swapped
   * into the adopted asset and the external call executed. Can be used before reconcile (when providing
   * fast liquidity) or after reconcile (when using liquidity from the bridge)
   * @dev Will store the `ExecutedTransfer` if fast liquidity is provided, or assert the hash of the
   * `ReconciledTransfer` when using bridge liquidity
   * @param _args - The `ExecuteArgs` for the transfer
   * @return bytes32 The transfer id of the crosschain transfer
   */
  function execute(ExecuteArgs calldata _args) external override returns (bytes32) {
    // Calculate the transfer id
    (bytes32 _transferId, address localAsset, uint256 localAmount) = _executeSanityChecks(_args);

    processed[_transferId] = true;

    // Handle liquidity as needed
    _decrementLiquidity(localAmount, localAsset, _args.params.router);

    address transactingAsset = localAsset;
    if (keccak256(_args.params.dstParam.data) == EMPTY) {
      // Send funds to the user
      transactingAsset = FibswapUtils.transferAssetFromContract(
        localAsset,
        _args.params.dstParam.to,
        localAmount,
        _args.params.isEth,
        wrapper
      );
    } else {
      // Send funds to executor
      transactingAsset = FibswapUtils.transferAssetFromContract(
        localAsset,
        address(executor),
        localAmount,
        _args.params.isEth,
        wrapper
      );
      executor.execute(
        _transferId,
        localAmount,
        payable(_args.params.dstParam.to),
        payable(_args.params.recovery),
        transactingAsset,
        _args.params.dstParam.data
      );
    }

    // Emit event
    emit Executed(
      _transferId,
      _args.params,
      localAsset,
      transactingAsset,
      localAmount,
      _args.amount,
      _args.routerSignature,
      _args.originSender,
      _args.nonce,
      msg.sender
    );

    return _transferId;
  }

  // ============ Private functions ============

  /**
   * @notice Contains the logic to verify + increment a given routers liquidity
   * @dev The liquidity will be held in the local asset
   * @param _amount - The amount of liquidity to add for the router
   * @param _local - The address of the local asset
   * @param _router - The router you are adding liquidity on behalf of
   */
  function _addLiquidityForRouter(
    uint256 _amount,
    address _local,
    address _router
  ) internal {
    // Sanity check: router is sensible
    if (_router == address(0)) revert Fibswap__addLiquidityForRouter_routerEmpty();

    // Sanity check: nonzero amounts
    if (_amount == 0) revert Fibswap__addLiquidityForRouter_amountIsZero();

    // Router is approved
    if (!approvedRouters(_router)) revert Fibswap__addLiquidityForRouter_badRouter();

    // Transfer funds to coethWithErcTransferact
    (address _assetId, uint256 _received) = FibswapUtils.handleIncomingAsset(_local, _amount, 0, _router, wrapper);

    // Asset is approved
    if (!approvedAssets[_assetId]) revert Fibswap__addLiquidityForRouter_badAsset();

    // Update the router balances. Happens after pulling funds to account for
    // the fee on transfer tokens
    routerBalances[_router][_assetId] += _received;

    // Emit event
    emit LiquidityAdded(_router, _assetId, _received, msg.sender);
  }

  /**
   * @notice Used to add assets on same chain as contract that can be transferred.
   * @param _localAsset - The used asset id (i.e. USDC, USDT, WETH, ETH)
   */
  function _addAssetId(address _localAsset) internal {
    // Sanity check: needs approval
    if (approvedAssets[_localAsset]) revert Fibswap__addAssetId_alreadyAdded();

    // Update approved assets mapping
    approvedAssets[_localAsset] = true;

    // Emit event
    emit AssetAdded(_localAsset, msg.sender);
  }

  /**
   * @notice Used to add an AMM for assets
   * @param _swapRouter - The address of the amm to add
   */
  function _addSwapRouter(address _swapRouter) internal {
    if (!AddressUpgradeable.isContract(_swapRouter)) revert Fibswap__addSwapRouter_invalidSwapRouterAddress();
    if (swapRouters[_swapRouter]) revert Fibswap__addSwapRouter_alreadyApproved();

    swapRouters[_swapRouter] = true;

    emit SwapRouterUpdated(_swapRouter, true, msg.sender);
  }

  /**
   * @notice Calculates transfer amount without Fee.
   * @param _amount Transfer amount
   * @param _liquidityFeeNum Liquidity fee numerator
   * @param _liquidityFeeDen Liquidity fee denominator
   */
  function _getTransferAmountWithoutFee(
    uint256 _amount,
    uint256 _liquidityFeeNum,
    uint256 _liquidityFeeDen
  ) private pure returns (uint256) {
    return (_amount * _liquidityFeeNum) / _liquidityFeeDen;
  }

  function _handleIncomingAsset(
    uint256 _amount,
    uint256 _localAmount,
    address _localAsset
  ) internal view returns (uint256) {
    uint256 bridgedAmount = _getTransferAmountWithoutFee(_amount, PERCENTS_DIVIDER - feePercent, PERCENTS_DIVIDER);
    if (bridgedAmount < _localAmount) revert Fibswap__xcall_tooSmallLocalAmount();
    if (bridgedAmount >= (_localAmount * (maxAllowSlippage + PERCENTS_DIVIDER)) / PERCENTS_DIVIDER)
      revert Fibswap__xcall_tooBigSlippage();

    // underlying amount = localAmount * 10 ^ (36 - decimal of local asset)
    uint256 decimals = _localAsset == address(0) ? 18 : IERC20Extended(_localAsset).decimals();
    return _localAmount * (10**(36 - decimals));
  }

  /**
   * @notice Decrements router liquidity for the fast-liquidity case.
   * @dev Stores the router that supplied liquidity to credit on reconcile
   */
  function _decrementLiquidity(
    uint256 _amount,
    address _local,
    address _router
  ) internal {
    // Decrement liquidity
    routerBalances[_router][_local] -= _amount;
  }

  /**
   * @notice Performs some sanity checks for `xcall`
   * @dev Need this to prevent stack too deep
   */
  function _xcallSanityChecks(XCallArgs calldata _args) private view {
    if (!approvedRouters(_args.params.router)) revert Fibswap__xcall_notApprovedRouter();

    // ensure this is the right domain
    uint256 _chainId = getChainId();
    if (_args.params.origin != _chainId || _args.params.origin == _args.params.destination) {
      revert Fibswap__xcall_wrongDomain();
    }

    // ensure theres a recipient defined
    if (_args.params.dstParam.to == address(0)) {
      revert Fibswap__xcall_emptyTo();
    }

    if (!approvedAssets[_args.params.orgLocalAsset]) revert Fibswap__xcall_notSupportedAsset();

    if (_args.relayerFee == 0 || msg.value < _args.relayerFee) revert Fibswap__xcall_notGasFee();
  }

  /**
   * @notice Performs some sanity checks for `execute`
   * @dev Need this to prevent stack too deep
   */
  function _executeSanityChecks(ExecuteArgs calldata _args)
    private
    returns (
      bytes32,
      address,
      uint256
    )
  {
    // If the sender is not approved router, revert()
    if (!approvedRouters(msg.sender) || msg.sender != _args.params.router) {
      revert Fibswap__execute_unapprovedRouter();
    }

    if (_args.params.destination != getChainId()) revert Fibswap__execute_incorrectDestination();
    // get transfer id
    bytes32 transferId = FibswapUtils.getTransferId(_args.nonce, _args.originSender, _args.params, _args.amount);

    // get the payload the router should have signed
    bytes32 routerHash = keccak256(abi.encode(transferId));

    if (_args.params.router != _recoverSignature(routerHash, _args.routerSignature)) {
      revert Fibswap__execute_invalidRouterSignature();
    }

    // require this transfer has not already been executed
    if (processed[transferId]) {
      revert Fibswap__execute_alreadyExecuted();
    }

    address localAsset = _args.params.dstLocalAsset;
    uint256 decimals = (localAsset == address(0) ? 18 : IERC20Extended(localAsset).decimals());
    uint256 localAmount = _args.amount / (10**(36 - decimals));

    return (transferId, localAsset, localAmount);
  }

  /**
   * @notice Holds the logic to recover the signer from an encoded payload.
   * @dev Will hash and convert to an eth signed message.
   * @param _signed The hash that was signed
   * @param _sig The signature you are recovering the signer from
   */
  function _recoverSignature(bytes32 _signed, bytes calldata _sig) internal pure returns (address) {
    // Recover
    return ECDSAUpgradeable.recover(ECDSAUpgradeable.toEthSignedMessageHash(_signed), _sig);
  }

  /**
   * @notice Gets the chainId for this contract. If not specified during init
   *         will use the block.chainId
   */
  function getChainId() public view returns (uint256 _chainId) {
    // Hold in memory to reduce sload calls
    uint256 chain = chainId;
    if (chain == 0) {
      // If not provided, pull from block
      assembly {
        _chainId := chainid()
      }
    } else {
      // Use provided override
      _chainId = chain;
    }
  }

  receive() external payable {}

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[49] private __gap;

  // max allowed slippage
  uint256 public maxAllowSlippage;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

// TODO: need a correct interface here
interface IWrapped {
  function deposit() external payable;

  function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

interface IFibswap {
  // ============= Structs =============
  /**
   * @notice Contains the external call information
   * @dev Used to create a hash to pass the external call information through the bridge
   * @param to - The address that should receive the funds on the destination domain if no call is
   * specified, or the fallback if an external call fails
   * @param callData - The data to execute on the receiving chain
   */
  struct ExternalCall {
    address to;
    bytes data;
  }

  /**
   * @notice These are the call parameters that will remain constant between the
   * two chains. They are supplied on `xcall` and should be asserted on `execute`
   * @property to - The account that receives funds, in the event of a crosschain call,
   * will receive funds if the call fails.
   * @param to - The address you are sending funds (and potentially data) to
   * @param callData - The data to execute on the receiving chain. If no crosschain call is needed, then leave empty.
   * @param origin - The originating chainId (i.e. where `xcall` is called).
   * @param destination - The final chainId (i.e. where `execute` is called).
   */
  struct CallParams {
    address router;
    ExternalCall orgParam;
    ExternalCall dstParam;
    address recovery;
    uint32 origin;
    uint32 destination;
    address orgLocalAsset;
    address dstLocalAsset;
    bool isEth;
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
    address transactingAssetId; // Could be any token or native
    uint256 amount;
    uint256 localAmount;
    uint256 relayerFee;
    bool isExactInput;
  }

  /**
   * @notice
   * @param params - The CallParams. These are consistent across sending and receiving chains
   * @param local - The local asset for the transfer, will be swapped to the adopted asset if
   * appropriate
   * @param router - The router who you are sending the funds on behalf of
   * @param amount - The amount of liquidity the router provided or the bridge forwarded, depending on
   * if fast liquidity was used
   * @param feePercentage - The amount over the BASEFEE to tip the relayer
   */
  struct ExecuteArgs {
    CallParams params;
    address transactingAssetId;
    uint256 amount;
    uint256 nonce;
    bytes routerSignature;
    address originSender;
  }
  // ============ Events ============

  event NewExecutor(address executor, address caller);

  event NewFeePercent(uint256 feePercent, address caller);

  event NewMaxAllowSlippage(uint256 percent, address caller);
  /**
   * @notice Emitted when a new swap AMM is added
   * @param swapRouter - The address of the AMM
   * @param approved - approved or removed
   * @param caller - The account that called the function
   */
  event SwapRouterUpdated(address swapRouter, bool approved, address caller);

  /**
   * @notice Emitted when a new asset is added
   * @param localAsset - The address of the local asset (USDC, USDT, WETH)
   * @param caller - The account that called the function
   */
  event AssetAdded(address localAsset, address caller);

  /**
   * @notice Emitted when an asset is removed from whitelists
   * @param localAsset - The address of the local asset (USDC, USDT, WETH)
   * @param caller - The account that called the function
   */
  event AssetRemoved(address localAsset, address caller);

  /**
   * @notice Emitted when a router withdraws liquidity from the contract
   * @param router - The router you are removing liquidity from
   * @param to - The address the funds were withdrawn to
   * @param local - The address of the token withdrawn
   * @param amount - The amount of liquidity withdrawn
   * @param caller - The account that called the function
   */
  event LiquidityRemoved(address indexed router, address to, address local, uint256 amount, address caller);

  /**
   * @notice Emitted when a router adds liquidity to the contract
   * @param router - The address of the router the funds were credited to
   * @param local - The address of the token added (all liquidity held in local asset)
   * @param amount - The amount of liquidity added
   * @param caller - The account that called the function
   */
  event LiquidityAdded(address indexed router, address local, uint256 amount, address caller);

  /**
   * @notice Emitted when `xcall` is called on the origin domain
   * @param transferId - The unique identifier of the crosschain transfer
   * @param params - The CallParams provided to the function
   * @param transactingAsset - The asset the caller sent with the transfer. Can be the adopted, canonical,
   * or the representational asset
   * @param localAsset - The asset sent over the bridge. Will be the local asset of nomad that corresponds
   * to the provided `transactingAsset`
   * @param transactingAmount - The amount of transferring asset the tx xcalled with
   * @param localAmount - The amount sent over the bridge (initialAmount with slippage) // underlying amount = localAmount * 10 ** (36 - decimals)
   * @param nonce - The nonce of the origin domain contract. Used to create the unique identifier
   * for the transfer
   * @param caller - The account that called the function
   */
  event XCalled(
    bytes32 indexed transferId,
    CallParams params,
    address transactingAsset,
    address localAsset,
    uint256 transactingAmount,
    uint256 localAmount,
    uint256 nonce,
    uint256 relayerFee,
    address caller
  );

  /**
   * @notice Emitted when `execute` is called on the destination chain
   * @dev `execute` may be called when providing fast liquidity *or* when processing a reconciled transfer
   * @param transferId - The unique identifier of the crosschain transfer
   * @param params - The CallParams provided to the function
   * @param localAsset - The asset that was provided by the bridge
   * @param transactingAsset - The asset the to gets or the external call is executed with. Should be the
   * adopted asset on that chain.
   * @param localAmount - The amount that was provided by the bridge
   * @param transactingAmount - The amount of transferring asset the to address receives or the external call is
   * executed with
   * @param caller - The account that called the function
   */
  event Executed(
    bytes32 indexed transferId,
    CallParams params,
    address localAsset,
    address transactingAsset,
    uint256 localAmount,
    uint256 transactingAmount,
    bytes routerSignature,
    address originSender,
    uint256 nonce,
    address caller
  );

  // ============ Admin Functions ============

  function initialize(
    uint256 chainId,
    address owner,
    address wrapper
  ) external;

  function setupRouter(
    address router,
    address owner,
    address recipient
  ) external;

  function removeRouter(address router) external;

  function removeAssetId(address localAsset) external;

  // ============ Public Functions ===========

  function addLiquidityFor(
    uint256 amount,
    address local,
    address router
  ) external payable;

  function addLiquidity(uint256 amount, address local) external payable;

  function removeLiquidity(uint256 amount, address local) external;

  function xcall(XCallArgs calldata _args) external payable returns (bytes32);

  function execute(ExecuteArgs calldata _args) external returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Extended {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the token name.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "../interfaces/IExecutor.sol";

import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @title Executor
 * @author Connext <[email protected]>
 * @notice This library contains an `execute` function that is callabale by
 * an associated Connext contract. This is used to execute
 * arbitrary calldata on a receiving chain.
 */
contract Executor is IExecutor {
  // ============ Properties =============

  address private immutable fibswap;

  // ============ Constructor =============

  constructor(address _fibswap) {
    fibswap = _fibswap;
  }

  // ============ Modifiers =============

  /**
   * @notice Errors if the sender is not Connext
   */
  modifier onlyFibswap() {
    require(msg.sender == fibswap, "!fibswap");
    _;
  }

  // ============ Public Functions =============

  /**
   * @notice Returns the connext contract address (only address that can
   * call the `execute` function)
   * @return The address of the associated connext contract
   */
  function getFibswap() external view override returns (address) {
    return fibswap;
  }

  /**
   * @notice Executes some arbitrary call data on a given address. The
   * call data executes can be payable, and will have `amount` sent
   * along with the function (or approved to the contract). If the
   * call fails, rather than reverting, funds are sent directly to
   * some provided fallback address
   * @param _transferId Unique identifier of transaction id that necessitated
   * calldata execution
   * @param _amount The amount to approve or send with the call
   * @param _to The address to execute the calldata on
   * @param _assetId The assetId of the funds to approve to the contract or
   * send along with the call
   * @param _callData The data to execute
   */
  function execute(
    bytes32 _transferId,
    uint256 _amount,
    address payable _to,
    address payable _recovery,
    address _assetId,
    bytes calldata _callData
  ) external payable override onlyFibswap returns (bool) {
    // If it is not ether, approve the callTo
    // We approve here rather than transfer since many external contracts
    // simply require an approval, and it is unclear if they can handle
    // funds transferred directly to them (i.e. Uniswap)
    bool isNative = _assetId == address(0);

    // Check if the callTo is a contract
    bool success;
    if (!AddressUpgradeable.isContract(_to)) {
      _handleFailure(isNative, false, _assetId, _to, _recovery, _amount);
      // Emit event
      emit Executed(_transferId, _to, _recovery, _assetId, _amount, _callData, success);
      return success;
    }

    if (!isNative) {
      SafeERC20Upgradeable.safeIncreaseAllowance(IERC20Upgradeable(_assetId), _to, _amount);
    }

    // Try to execute the callData
    // the low level call will return `false` if its execution reverts
    (success, ) = _to.call{value: isNative ? _amount : 0}(_callData);

    // Handle failure cases
    if (!success) {
      _handleFailure(isNative, true, _assetId, _to, _recovery, _amount);
    }

    // Emit event
    emit Executed(_transferId, _to, _recovery, _assetId, _amount, _callData, success);
    return success;
  }

  function _handleFailure(
    bool isNative,
    bool hasIncreased,
    address _assetId,
    address payable _to,
    address payable _recovery,
    uint256 _amount
  ) private {
    if (!isNative) {
      // Decrease allowance
      if (hasIncreased) {
        SafeERC20Upgradeable.safeDecreaseAllowance(IERC20Upgradeable(_assetId), _to, _amount);
      }
      // Transfer funds
      SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(_assetId), _recovery, _amount);
    } else {
      // Transfer funds
      AddressUpgradeable.sendValue(_recovery, _amount);
    }
  }

  receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {RouterPermissionsLogic, RouterPermissionsInfo} from "./lib/Fibswap/RouterPermissionsLogic.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @notice
 * This contract is designed to manage router access, meaning it maintains the
 * router recipients, owners, and the router whitelist itself. It does *not* manage router balances
 * as asset management is out of scope of this contract.
 *
 * As a router, there are three important permissions:
 * `router` - this is the address that will sign bids sent to the sequencer
 * `routerRecipient` - this is the address that receives funds when liquidity is withdrawn
 * `routerOwner` - this is the address permitted to update recipients and propose new owners
 *
 * In cases where the owner is not set, the caller should be the `router` itself. In cases where the
 * `routerRecipient` is not set, the funds can be removed to anywhere.
 *
 * When setting a new `routerOwner`, the current owner (or router) must create a proposal, which
 * can be accepted by the proposed owner after the delay period. If the proposed owner is the empty
 * address, then it must be accepted by the current owner.
 */
abstract contract RouterPermissionsManager is Initializable {
  // ============ Private storage =============

  uint256 private _delay;

  // ============ Public Storage =============

  RouterPermissionsInfo internal routerInfo;

  // ============ Initialize =============

  /**
   * @dev Initializes the contract setting the deployer as the initial
   */
  function __RouterPermissionsManager_init() internal onlyInitializing {
    __RouterPermissionsManager_init_unchained();
  }

  function __RouterPermissionsManager_init_unchained() internal onlyInitializing {
    _delay = 7 days;
  }

  // ============ Public methods =============

  function approvedRouters(address _router) public view returns (bool) {
    return routerInfo.approvedRouters[_router];
  }

  function routerRecipients(address _router) public view returns (address) {
    return routerInfo.routerRecipients[_router] == address(0) ? _router : routerInfo.routerRecipients[_router];
  }

  function routerOwners(address _router) public view returns (address) {
    return routerInfo.routerOwners[_router] == address(0) ? _router : routerInfo.routerOwners[_router];
  }

  /**
   * @notice Sets the designated recipient for a router
   * @dev Router should only be able to set this once otherwise if router key compromised,
   * no problem is solved since attacker could just update recipient
   * @param router Router address to set recipient
   * @param recipient Recipient Address to set to router
   */
  function setRouterRecipient(address router, address recipient) external {
    RouterPermissionsLogic.setRouterRecipient(router, recipient, routerInfo);
  }

  /**
   * @notice Current owner or router may propose a new router owner
   * @param router Router address to set recipient
   * @param owner Proposed owner Address to set to router
   */
  function setRouterOwner(address router, address owner) external {
    RouterPermissionsLogic.setRouterOwner(router, owner, routerInfo);
  }

  // ============ Private methods =============

  /**
   * @notice Used to set router initial properties
   * @param router Router address to setup
   * @param owner Initial Owner of router
   * @param recipient Initial Recipient of router
   */
  function _setupRouter(
    address router,
    address owner,
    address recipient
  ) internal {
    RouterPermissionsLogic.setupRouter(router, owner, recipient, routerInfo);
  }

  /**
   * @notice Used to remove routers that can transact crosschain
   * @param router Router address to remove
   */
  function _removeRouter(address router) internal {
    RouterPermissionsLogic.removeRouter(router, routerInfo);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {IFibswap} from "../../interfaces/IFibswap.sol";
import {IWrapped} from "../../interfaces/IWrapped.sol";

import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {SafeERC20Upgradeable, IERC20Upgradeable, AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

library FibswapUtils {
  error FibswapUtils__handleIncomingAsset_notAmount();
  error FibswapUtils__handleIncomingAsset_ethWithErcTransfer();
  error FibswapUtils__transferAssetFromContract_notNative();

  /**
   * @notice Gets unique identifier from nonce + domain
   * @param _nonce - The nonce of the contract
   * @param _params - The call params of the transfer
   * @return The transfer id
   */
  function getTransferId(
    uint256 _nonce,
    address _sender,
    IFibswap.CallParams calldata _params,
    uint256 _amount
  ) internal pure returns (bytes32) {
    return keccak256(abi.encode(_nonce, _sender, _params, _amount));
  }

  /**
   * @notice Holds the logic to recover the signer from an encoded payload.
   * @dev Will hash and convert to an eth signed message.
   * @param _encoded The payload that was signed
   * @param _sig The signature you are recovering the signer from
   */
  function recoverSignature(bytes memory _encoded, bytes calldata _sig) internal pure returns (address) {
    // Recover
    return ECDSAUpgradeable.recover(ECDSAUpgradeable.toEthSignedMessageHash(keccak256(_encoded)), _sig);
  }

  /**
   * @notice Handles transferring funds from msg.sender to the Connext contract.
   * @dev If using the native asset, will automatically wrap
   * @param _assetId - The address to transfer
   * @param _assetAmount - The specified amount to transfer. May not be the
   * actual amount transferred (i.e. fee on transfer tokens)
   * @param _relayerFee - The fee amount in native asset included as part of the transaction that
   * should not be considered for the transfer amount.
   * @return The assetId of the transferred asset
   * @return The amount of the asset that was seen by the contract (may not be the specifiedAmount
   * if the token is a fee-on-transfer token)
   */
  function handleIncomingAsset(
    address _assetId,
    uint256 _assetAmount,
    uint256 _relayerFee,
    address _router,
    IWrapped _wrapper
  ) internal returns (address, uint256) {
    uint256 trueAmount = _assetAmount;

    if (_assetId == address(0)) {
      if (msg.value != _assetAmount + _relayerFee) revert FibswapUtils__handleIncomingAsset_notAmount();

      // When transferring native asset to the contract, always make sure that the
      // asset is properly wrapped
      _wrapper.deposit{value: _assetAmount}();
      _assetId = address(_wrapper);
    } else {
      if (msg.value != _relayerFee) revert FibswapUtils__handleIncomingAsset_ethWithErcTransfer();

      // Transfer asset to contract
      trueAmount = transferAssetToContract(_assetId, _assetAmount);
    }

    if (_relayerFee > 0) {
      AddressUpgradeable.sendValue(payable(_router), _relayerFee);
    }

    return (_assetId, trueAmount);
  }

  /**
   * @notice Handles transferring funds from msg.sender to the Connext contract.
   * @dev If using the native asset, will automatically wrap
   * @param _assetId - The address to transfer
   * @param _specifiedAmount - The specified amount to transfer. May not be the
   * actual amount transferred (i.e. fee on transfer tokens)
   * @return The amount of the asset that was seen by the contract (may not be the specifiedAmount
   * if the token is a fee-on-transfer token)
   */
  function transferAssetToContract(address _assetId, uint256 _specifiedAmount) internal returns (uint256) {
    // Validate correct amounts are transferred
    uint256 starting = IERC20Upgradeable(_assetId).balanceOf(address(this));
    SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(_assetId), msg.sender, address(this), _specifiedAmount);
    // Calculate the *actual* amount that was sent here
    uint256 trueAmount = IERC20Upgradeable(_assetId).balanceOf(address(this)) - starting;

    return trueAmount;
  }

  /**
   * @notice Handles transferring funds from msg.sender to the Connext contract.
   * @dev If using the native asset, will automatically unwrap
   * @param _assetId - The address to transfer
   * @param _to - The account that will receive the withdrawn funds
   * @param _amount - The amount to withdraw from contract
   * @param _wrapper - The address of the wrapper for the native asset on this domain
   * @return The address of asset received post-swap
   */
  function transferAssetFromContract(
    address _assetId,
    address _to,
    uint256 _amount,
    bool _convertToEth,
    IWrapped _wrapper
  ) internal returns (address) {
    // No native assets should ever be stored on this contract
    if (_assetId == address(0)) revert FibswapUtils__transferAssetFromContract_notNative();

    if (_assetId == address(_wrapper) && _convertToEth) {
      // If dealing with wrapped assets, make sure they are properly unwrapped
      // before sending from contract
      _wrapper.withdraw(_amount);
      AddressUpgradeable.sendValue(payable(_to), _amount);
      return address(0);
    } else {
      // Transfer ERC20 asset
      SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(_assetId), _to, _amount);
      return _assetId;
    }
  }

  /**
   * @notice Swaps an adopted asset to the local (representation or canonical) nomad asset
   * @dev Will not swap if the asset passed in is the local asset
   * @param _asset - The address of the adopted asset to swap into the local asset
   * @param _amount - The amount of the adopted asset to swap
   * @return The amount of local asset received from swap
   */
  function swapToLocalAssetIfNeeded(
    address _local,
    address _asset,
    uint256 _amount,
    IFibswap.ExternalCall calldata _callParam
  ) internal returns (uint256) {
    if (_local == _asset) {
      return _amount;
    }

    // Approve pool
    SafeERC20Upgradeable.safeApprove(IERC20Upgradeable(_asset), _callParam.to, _amount);

    // Swap the asset to the proper local asset
    IERC20Upgradeable Transit = IERC20Upgradeable(_local);

    uint256 balanceBefore = Transit.balanceOf(address(this));
    AddressUpgradeable.functionCall(_callParam.to, _callParam.data);

    uint256 balanceDif = Transit.balanceOf(address(this)) - balanceBefore;

    return balanceDif;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
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
pragma solidity 0.8.11;

interface IExecutor {
  event Executed(
    bytes32 indexed transferId,
    address indexed to,
    address recovery,
    address assetId,
    uint256 amount,
    bytes callData,
    bool success
  );

  function getFibswap() external returns (address);

  function execute(
    bytes32 _transferId,
    uint256 _amount,
    address payable _to,
    address payable _recovery,
    address _assetId,
    bytes calldata _callData
  ) external payable returns (bool success);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

/**
 * @notice Contains RouterPermissions related state
 * @param approvedRouters - Mapping of whitelisted router addresses
 * @param routerRecipients - Mapping of router withdraw recipient addresses.
 * If set, all liquidity is withdrawn only to this address. Must be set by routerOwner
 * (if configured) or the router itself
 * @param routerOwners - Mapping of router owners
 */
struct RouterPermissionsInfo {
  mapping(address => bool) approvedRouters;
  mapping(address => address) routerRecipients;
  mapping(address => address) routerOwners;
}

library RouterPermissionsLogic {
  // ========== Custom Errors ===========
  error RouterPermissionsLogic__setRouterRecipient_notNewRecipient();
  error RouterPermissionsLogic__onlyRouterOwner_notRouterOwner();
  error RouterPermissionsLogic__removeRouter_routerEmpty();
  error RouterPermissionsLogic__removeRouter_notAdded();
  error RouterPermissionsLogic__setupRouter_routerEmpty();
  error RouterPermissionsLogic__setupRouter_alreadyApproved();
  error RouterPermissionsLogic__setRouterOwner_notNewOwner();

  /**
   * @notice Emitted when a new router is added
   * @param router - The address of the added router
   * @param caller - The account that called the function
   */
  event RouterAdded(address indexed router, address caller);

  /**
   * @notice Emitted when an existing router is removed
   * @param router - The address of the removed router
   * @param caller - The account that called the function
   */
  event RouterRemoved(address indexed router, address caller);

  /**
   * @notice Emitted when the recipient of router is updated
   * @param router - The address of the added router
   * @param prevRecipient  - The address of the previous recipient of the router
   * @param newRecipient  - The address of the new recipient of the router
   */
  event RouterRecipientSet(address indexed router, address indexed prevRecipient, address indexed newRecipient);

  /**
   * @notice Emitted when the owner of router is accepted
   * @param router - The address of the added router
   * @param prevOwner  - The address of the previous owner of the router
   * @param newOwner  - The address of the new owner of the router
   */
  event RouterOwnerUpdated(address indexed router, address indexed prevOwner, address indexed newOwner);

  /**
   * @notice Asserts caller is the router owner (if set) or the router itself
   */
  function _onlyRouterOwner(address _router, address _owner) internal view {
    if (!((_owner == address(0) && msg.sender == _router) || _owner == msg.sender))
      revert RouterPermissionsLogic__onlyRouterOwner_notRouterOwner();
  }

  // ============ Public methods =============

  /**
   * @notice Sets the designated recipient for a router
   * @dev Router should only be able to set this once otherwise if router key compromised,
   * no problem is solved since attacker could just update recipient
   * @param router Router address to set recipient
   * @param recipient Recipient Address to set to router
   */
  function setRouterRecipient(
    address router,
    address recipient,
    RouterPermissionsInfo storage routerInfo
  ) internal {
    _onlyRouterOwner(router, routerInfo.routerOwners[router]);

    // Check recipient is changing
    address _prevRecipient = routerInfo.routerRecipients[router];
    if (_prevRecipient == recipient) revert RouterPermissionsLogic__setRouterRecipient_notNewRecipient();

    // Set new recipient
    routerInfo.routerRecipients[router] = recipient;

    // Emit event
    emit RouterRecipientSet(router, _prevRecipient, recipient);
  }

  /**
   * @notice Current owner or router may propose a new router owner
   * @param router Router address to set recipient
   * @param owner Owner Address to set to router
   */
  function setRouterOwner(
    address router,
    address owner,
    RouterPermissionsInfo storage routerInfo
  ) internal {
    _onlyRouterOwner(router, routerInfo.routerOwners[router]);

    // Check that proposed is different than current owner
    if (_getRouterOwner(router, routerInfo.routerOwners) == owner)
      revert RouterPermissionsLogic__setRouterOwner_notNewOwner();

    // Emit event
    emit RouterOwnerUpdated(router, routerInfo.routerOwners[router], owner);

    // Update the current owner
    routerInfo.routerOwners[router] = owner;
  }

  /**
   * @notice Used to set router initial properties
   * @param router Router address to setup
   * @param owner Initial Owner of router
   * @param recipient Initial Recipient of router
   */
  function setupRouter(
    address router,
    address owner,
    address recipient,
    RouterPermissionsInfo storage routerInfo
  ) internal {
    // Sanity check: not empty
    if (router == address(0)) revert RouterPermissionsLogic__setupRouter_routerEmpty();

    // Sanity check: needs approval
    if (routerInfo.approvedRouters[router]) revert RouterPermissionsLogic__setupRouter_alreadyApproved();

    // Approve router
    routerInfo.approvedRouters[router] = true;

    // Emit event
    emit RouterAdded(router, msg.sender);

    // Update routerOwner (zero address possible)
    if (owner != address(0)) {
      routerInfo.routerOwners[router] = owner;
      emit RouterOwnerUpdated(router, address(0), owner);
    }

    // Update router recipient
    if (recipient != address(0)) {
      routerInfo.routerRecipients[router] = recipient;
      emit RouterRecipientSet(router, address(0), recipient);
    }
  }

  /**
   * @notice Used to remove routers that can transact crosschain
   * @param router Router address to remove
   */
  function removeRouter(address router, RouterPermissionsInfo storage routerInfo) internal {
    // Sanity check: not empty
    if (router == address(0)) revert RouterPermissionsLogic__removeRouter_routerEmpty();

    // Sanity check: needs removal
    if (!routerInfo.approvedRouters[router]) revert RouterPermissionsLogic__removeRouter_notAdded();

    // Update mapping
    routerInfo.approvedRouters[router] = false;

    // Emit event
    emit RouterRemoved(router, msg.sender);

    // Remove router owner
    address _owner = routerInfo.routerOwners[router];
    if (_owner != address(0)) {
      emit RouterOwnerUpdated(router, _owner, address(0));
      routerInfo.routerOwners[router] = address(0);
    }

    // Remove router recipient
    address _recipient = routerInfo.routerRecipients[router];
    if (_recipient != address(0)) {
      emit RouterRecipientSet(router, _recipient, address(0));
      routerInfo.routerRecipients[router] = address(0);
    }
  }

  /**
   * @notice Returns the router owner if it is set, or the router itself if not
   */
  function _getRouterOwner(address router, mapping(address => address) storage _routerOwners)
    internal
    view
    returns (address)
  {
    address _owner = _routerOwners[router];
    return _owner == address(0) ? router : _owner;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
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