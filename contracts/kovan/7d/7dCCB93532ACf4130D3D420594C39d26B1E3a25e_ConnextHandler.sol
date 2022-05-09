// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

// ============ Imports ============
// TODO: import from nomad, summa packages
import {TypedMemView} from "../../../nomad-core/libs/TypedMemView.sol";
import {Home} from "../../../nomad-core/contracts/Home.sol";
import {RelayerFeeRouter} from "../../../nomad-xapps/contracts/relayer-fee-router/RelayerFeeRouter.sol";
import {Router} from "../Router.sol";

import {ConnextMessage} from "./ConnextMessage.sol";

import {ConnextLogic} from "../../../lib/Connext/ConnextLogic.sol";

import {ITokenRegistry} from "../../interfaces/bridge/ITokenRegistry.sol";
import {IWrapped} from "../../../interfaces/IWrapped.sol";
import {IConnextHandler} from "../../../interfaces/IConnextHandler.sol";
import {IExecutor} from "../../../interfaces/IExecutor.sol";
import {IStableSwap} from "../../../interfaces/IStableSwap.sol";

import {Executor} from "../../../interpreters/Executor.sol";
import {RouterPermissionsManager} from "../../../RouterPermissionsManager.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @title ConnextHandler
 * @author Connext Labs
 * @notice Contains logic to facilitate bridging via nomad, including the provision of
 * fast liquidity
 * @dev This contract primarily contains the storage used by the functions within the
 * `ConnextLogic` contract, which contains the meaningful logic
 */
contract ConnextHandler is
  Initializable,
  ReentrancyGuardUpgradeable,
  Router,
  RouterPermissionsManager,
  IConnextHandler
{
  // ============ Libraries ============

  using SafeERC20Upgradeable for IERC20Upgradeable;

  // ============ Constants ============

  // TODO: enable setting these constants via admin fn
  uint256 public LIQUIDITY_FEE_NUMERATOR;
  uint256 public LIQUIDITY_FEE_DENOMINATOR;

  /**
   * @notice Contains hash of empty bytes
   */
  bytes32 internal EMPTY;

  // ============ Private storage ============
  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[49] private __gap;

  // ============ Public storage ============

  /**
   * @notice The local nomad relayer fee router
   */
  RelayerFeeRouter public relayerFeeRouter;

  /**
   * @notice The address of the wrapper for the native asset on this domain
   * @dev Needed because the nomad only handles ERC20 assets
   */
  IWrapped public wrapper;

  /**
   * @notice Nonce for the contract, used to keep unique transfer ids.
   * @dev Assigned at first interaction (xcall on origin domain);
   */
  uint256 public nonce;

  /**
   * @notice The external contract that will execute crosschain calldata
   */
  IExecutor public executor;

  /**
   * @notice The domain this contract exists on
   * @dev Must match the nomad domain, which is distinct from the "chainId"
   */
  uint256 public domain;

  /**
   * @notice The local nomad token registry
   */
  ITokenRegistry public tokenRegistry;

  /**
   * @notice Mapping holding the AMMs for swapping in and out of local assets
   * @dev Swaps for an adopted asset <> nomad local asset (i.e. POS USDC <> madUSDC on polygon)
   */
  mapping(bytes32 => IStableSwap) public adoptedToLocalPools;

  /**
   * @notice Mapping of whitelisted assets on same domain as contract
   * @dev Mapping is keyed on the canonical token identifier matching what is stored in the token
   * registry
   */
  mapping(bytes32 => bool) public approvedAssets;

  /**
   * @notice Mapping of canonical to adopted assets on this domain
   * @dev If the adopted asset is the native asset, the keyed address will
   * be the wrapped asset address
   */
  mapping(address => ConnextMessage.TokenId) public adoptedToCanonical;

  /**
   * @notice Mapping of adopted to canonical on this domain
   * @dev If the adopted asset is the native asset, the stored address will be the
   * wrapped asset address
   */
  mapping(bytes32 => address) public canonicalToAdopted;

  /**
   * @notice Mapping to determine if transfer is reconciled
   */
  mapping(bytes32 => bool) public reconciledTransfers;

  /**
   * @notice Mapping holding router address that provided fast liquidity
   */
  mapping(bytes32 => address[]) public routedTransfers;

  /**
   * @notice Mapping of router to available balance of an asset
   * @dev Routers should always store liquidity that they can expect to receive via the bridge on
   * this domain (the nomad local asset)
   */
  mapping(address => mapping(address => uint256)) public routerBalances;

  /**
   * @notice Mapping of approved relayers
   * @dev Send relayer fee if msg.sender is approvedRelayer. otherwise revert()
   */
  mapping(address => bool) public approvedRelayers;

  /**
   * @notice Stores the relayer fee for a transfer. Updated on origin domain when a user calls xcall or bump
   * @dev This will track all of the relayer fees assigned to a transfer by id, including any bumps made by the relayer
   */
  mapping(bytes32 => uint256) public relayerFees;

  /**
   * @notice Stores the relayer of a transfer. Updated on the destination domain when a relayer calls execute
   * for transfer
   * @dev When relayer claims, must check that the msg.sender has forwarded transfer
   */
  mapping(bytes32 => address) public transferRelayer;

  /**
   * @notice The max amount of routers a payment can be routed through
   */
  uint256 public maxRoutersPerTransfer;

  // ============ Errors ============

  error ConnextHandler__addLiquidityForRouter_routerEmpty();
  error ConnextHandler__addLiquidityForRouter_amountIsZero();
  error ConnextHandler__addLiquidityForRouter_badRouter();
  error ConnextHandler__addLiquidityForRouter_badAsset();
  error ConnextHandler__setMaxRoutersPerTransfer_invalidMaxRoutersPerTransfer();
  error ConnextHandler__onlyRelayerFeeRouter_notRelayerFeeRouter();
  error ConnextHandler__bumpTransfer_valueIsZero();
  error ConnextHandler__execute_unapprovedRelayer();

  // ============ Modifiers ============

  /**
   * @notice Restricts the caller to the local relayer fee router
   */
  modifier onlyRelayerFeeRouter() {
    if (msg.sender != address(relayerFeeRouter)) revert ConnextHandler__onlyRelayerFeeRouter_notRelayerFeeRouter();
    _;
  }

  // ========== Initializer ============

  function initialize(
    uint256 _domain,
    address _xAppConnectionManager,
    address _tokenRegistry, // Nomad token registry
    address _wrappedNative,
    address _relayerFeeRouter
  ) public override initializer {
    __XAppConnectionClient_initialize(_xAppConnectionManager);
    __ReentrancyGuard_init();
    __RouterPermissionsManager_init();

    nonce = 0;
    domain = _domain;
    relayerFeeRouter = RelayerFeeRouter(_relayerFeeRouter);
    executor = new Executor(address(this));
    tokenRegistry = ITokenRegistry(_tokenRegistry);
    wrapper = IWrapped(_wrappedNative);
    EMPTY = hex"c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470";
    LIQUIDITY_FEE_NUMERATOR = 9995;
    LIQUIDITY_FEE_DENOMINATOR = 10000;
    maxRoutersPerTransfer = 5;
  }

  // ============ Owner Functions ============

  /**
   * @notice Used to set router initial properties
   * @param _router Router address to setup
   * @param _owner Initial Owner of router
   * @param _recipient Initial Recipient of router
   */
  function setupRouter(
    address _router,
    address _owner,
    address _recipient
  ) external onlyOwner {
    _setupRouter(_router, _owner, _recipient);
  }

  /**
   * @notice Used to remove routers that can transact crosschain
   * @param _router Router address to remove
   */
  function removeRouter(address _router) external override onlyOwner {
    _removeRouter(_router);
  }

  /**
   * @notice Adds a stable swap pool for the local <> adopted asset.
   */
  function addStableSwapPool(ConnextMessage.TokenId calldata _canonical, address _stableSwapPool)
    external
    override
    onlyOwner
  {
    ConnextLogic.addStableSwapPool(_canonical, _stableSwapPool, adoptedToLocalPools);
  }

  /**
   * @notice Used to add supported assets. This is an admin only function
   * @dev When whitelisting the canonical asset, all representational assets would be
   * whitelisted as well. In the event you have a different adopted asset (i.e. PoS USDC
   * on polygon), you should *not* whitelist the adopted asset. The stable swap pool
   * address used should allow you to swap between the local <> adopted asset
   * @param _canonical - The canonical asset to add by id and domain. All representations
   * will be whitelisted as well
   * @param _adoptedAssetId - The used asset id for this domain (i.e. PoS USDC for
   * polygon)
   */
  function setupAsset(
    ConnextMessage.TokenId calldata _canonical,
    address _adoptedAssetId,
    address _stableSwapPool
  ) external override onlyOwner {
    // Add the asset
    ConnextLogic.addAssetId(
      _canonical,
      _adoptedAssetId,
      address(wrapper),
      approvedAssets,
      adoptedToCanonical,
      canonicalToAdopted
    );

    // Add the swap pool
    ConnextLogic.addStableSwapPool(_canonical, _stableSwapPool, adoptedToLocalPools);
  }

  /**
   * @notice Used to remove assets from the whitelist
   * @param _canonicalId - Token id to remove
   * @param _adoptedAssetId - Corresponding adopted asset to remove
   */
  function removeAssetId(bytes32 _canonicalId, address _adoptedAssetId) external override onlyOwner {
    ConnextLogic.removeAssetId(
      _canonicalId,
      _adoptedAssetId,
      address(wrapper),
      approvedAssets,
      adoptedToLocalPools,
      adoptedToCanonical
    );
  }

  /**
   * @notice Used to add approved relayer
   * @param _relayer - The relayer address to add
   */
  function addRelayer(address _relayer) external override onlyOwner {
    ConnextLogic.addRelayer(_relayer, approvedRelayers);
  }

  /**
   * @notice Used to remove approved relayer
   * @param _relayer - The relayer address to remove
   */
  function removeRelayer(address _relayer) external override onlyOwner {
    ConnextLogic.removeRelayer(_relayer, approvedRelayers);
  }

  /**
   * @notice Used to set the max amount of routers a payment can be routed through
   * @param _newMaxRouters The new max amount of routers
   */
  function setMaxRoutersPerTransfer(uint256 _newMaxRouters) external override onlyOwner {
    ConnextLogic.setMaxRoutersPerTransfer(_newMaxRouters, maxRoutersPerTransfer);

    maxRoutersPerTransfer = _newMaxRouters;
  }

  // ============ External functions ============

  receive() external payable {}

  /**
   * @notice This is used by anyone to increase a router's available liquidity for a given asset.
   * @dev The liquidity will be held in the local asset, which is the representation if you
   * are *not* on the canonical domain, and the canonical asset otherwise.
   * @param _amount - The amount of liquidity to add for the router
   * @param _local - The address of the asset you're adding liquidity for. If adding liquidity of the
   * native asset, routers may use `address(0)` or the wrapped asset
   * @param _router The router you are adding liquidity on behalf of
   */
  function addLiquidityFor(
    uint256 _amount,
    address _local,
    address _router
  ) external payable override nonReentrant {
    _addLiquidityForRouter(_amount, _local, _router);
  }

  /**
   * @notice This is used by any router to increase their available liquidity for a given asset.
   * @dev The liquidity will be held in the local asset, which is the representation if you
   * are *not* on the canonical domain, and the canonical asset otherwise.
   * @param _amount - The amount of liquidity to add for the router
   * @param _local - The address of the asset you're adding liquidity for. If adding liquidity of the
   * native asset, routers may use `address(0)` or the wrapped asset
   */
  function addLiquidity(uint256 _amount, address _local) external payable override nonReentrant {
    _addLiquidityForRouter(_amount, _local, msg.sender);
  }

  /**
   * @notice This is used by any router to decrease their available liquidity for a given asset.
   * @param _amount - The amount of liquidity to remove for the router
   * @param _local - The address of the asset you're removing liquidity from. If removing liquidity of the
   * native asset, routers may use `address(0)` or the wrapped asset
   * @param _to The address that will receive the liquidity being removed
   */
  function removeLiquidity(
    uint256 _amount,
    address _local,
    address payable _to
  ) external override nonReentrant {
    // transfer to specicfied recipient IF recipient not set
    address recipient = getRouterRecipient(msg.sender);
    recipient = recipient == address(0) ? _to : recipient;

    ConnextLogic.removeLiquidity(_amount, _local, recipient, routerBalances, wrapper);
  }

  /**
   * @notice This function is called by a user who is looking to bridge funds
   * @dev This contract must have approval to transfer the adopted assets. They are then swapped to
   * the local nomad assets via the configured AMM and sent over the bridge router.
   * @param _args - The XCallArgs
   * @return The transfer id of the crosschain transfer
   */
  function xcall(XCallArgs calldata _args) external payable override returns (bytes32) {
    // get remote BridgeRouter address; revert if not found
    bytes32 remote = _mustHaveRemote(_args.params.destinationDomain);

    ConnextLogic.XCallLibArgs memory libArgs = ConnextLogic.XCallLibArgs({
      xCallArgs: _args,
      wrapper: wrapper,
      nonce: nonce,
      tokenRegistry: tokenRegistry,
      domain: domain,
      home: xAppConnectionManager.home(),
      remote: remote
    });

    (bytes32 transferId, uint256 newNonce) = ConnextLogic.xcall(
      libArgs,
      adoptedToCanonical,
      adoptedToLocalPools,
      relayerFees
    );

    nonce = newNonce;

    return transferId;
  }

  /**
   * @notice Handles an incoming message
   * @dev This function relies on nomad relayers and should not consume arbitrary amounts of
   * gas
   * @param _origin The origin domain
   * @param _nonce The unique identifier for the message from origin to destination
   * @param _sender The sender address
   * @param _message The message
   */
  function handle(
    uint32 _origin,
    uint32 _nonce,
    bytes32 _sender,
    bytes memory _message
  ) external override onlyReplica onlyRemoteRouter(_origin, _sender) {
    // handle the action
    ConnextLogic.reconcile(_origin, _message, reconciledTransfers, tokenRegistry, routedTransfers, routerBalances);
  }

  /**
   * @notice Called on the destination domain to disburse correct assets to end recipient
   * and execute any included calldata
   * @dev Can be called prior to or after `handle`, depending if fast liquidity is being
   * used.
   */
  function execute(ExecuteArgs calldata _args) external override returns (bytes32 transferId) {
    // If the sender is not approved relayer, revert()
    if (!approvedRelayers[msg.sender]) {
      revert ConnextHandler__execute_unapprovedRelayer();
    }

    ConnextLogic.ExecuteLibArgs memory libArgs = ConnextLogic.ExecuteLibArgs({
      executeArgs: _args,
      isRouterOwnershipRenounced: isRouterOwnershipRenounced(),
      maxRoutersPerTransfer: maxRoutersPerTransfer,
      tokenRegistry: tokenRegistry,
      wrapper: wrapper,
      executor: executor,
      liquidityFeeNumerator: LIQUIDITY_FEE_NUMERATOR,
      liquidityFeeDenominator: LIQUIDITY_FEE_DENOMINATOR
    });

    return
      ConnextLogic.execute(
        libArgs,
        routedTransfers,
        reconciledTransfers,
        routerBalances,
        adoptedToLocalPools,
        canonicalToAdopted,
        routerInfo,
        transferRelayer
      );
  }

  /**
   * @notice Anyone can call this function on the origin domain to increase the relayer fee for a transfer.
   * @param _transferId - The unique identifier of the crosschain transaction
   */
  function bumpTransfer(bytes32 _transferId) external payable {
    ConnextLogic.bumpTransfer(_transferId, relayerFees);
  }

  /**
   * @notice Called by relayer when they want to claim owed funds on a given domain
   * @dev Domain should be the origin domain of all the transfer ids
   * @param _recipient - address on origin chain to send claimed funds to
   * @param _domain - domain to claim funds on
   * @param _transferIds - transferIds to claim
   */
  function initiateClaim(
    uint32 _domain,
    address _recipient,
    bytes32[] calldata _transferIds
  ) external override {
    ConnextLogic.initiateClaim(_domain, _recipient, _transferIds, relayerFeeRouter, transferRelayer);
  }

  /**
   * @notice Pays out a relayer for the given fees
   * @dev Called by the RelayerFeeRouter.handle message. The validity of the transferIds is
   * asserted before dispatching the message.
   * @param _recipient - address on origin chain to send claimed funds to
   * @param _transferIds - transferIds to claim
   */
  function claim(address _recipient, bytes32[] calldata _transferIds) external override onlyRelayerFeeRouter {
    ConnextLogic.claim(_recipient, _transferIds, relayerFees);
  }

  // ============ Internal functions ============

  /**
   * @notice Contains the logic to verify + increment a given routers liquidity
   * @dev The liquidity will be held in the local asset, which is the representation if you
   * are *not* on the canonical domain, and the canonical asset otherwise.
   * @param _amount - The amount of liquidity to add for the router
   * @param _local - The address of the nomad representation of the asset
   * @param _router - The router you are adding liquidity on behalf of
   */
  function _addLiquidityForRouter(
    uint256 _amount,
    address _local,
    address _router
  ) internal {
    // Sanity check: router is sensible
    if (_router == address(0)) revert ConnextHandler__addLiquidityForRouter_routerEmpty();

    // Sanity check: nonzero amounts
    if (_amount == 0) revert ConnextHandler__addLiquidityForRouter_amountIsZero();

    // Get the canonical asset id from the representation
    (, bytes32 id) = tokenRegistry.getTokenId(_local == address(0) ? address(wrapper) : _local);

    // Router is approved
    if (!isRouterOwnershipRenounced() && !getRouterApproval(_router))
      revert ConnextHandler__addLiquidityForRouter_badRouter();

    // Asset is approved
    if (!isAssetOwnershipRenounced() && !approvedAssets[id]) revert ConnextHandler__addLiquidityForRouter_badAsset();

    ConnextLogic.addLiquidityForRouter(_amount, _local, _router, routerBalances, id, wrapper);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.11;

library TypedMemView {
  // Why does this exist?
  // the solidity `bytes memory` type has a few weaknesses.
  // 1. You can't index ranges effectively
  // 2. You can't slice without copying
  // 3. The underlying data may represent any type
  // 4. Solidity never deallocates memory, and memory costs grow
  //    superlinearly

  // By using a memory view instead of a `bytes memory` we get the following
  // advantages:
  // 1. Slices are done on the stack, by manipulating the pointer
  // 2. We can index arbitrary ranges and quickly convert them to stack types
  // 3. We can insert type info into the pointer, and typecheck at runtime

  // This makes `TypedMemView` a useful tool for efficient zero-copy
  // algorithms.

  // Why bytes29?
  // We want to avoid confusion between views, digests, and other common
  // types so we chose a large and uncommonly used odd number of bytes
  //
  // Note that while bytes are left-aligned in a word, integers and addresses
  // are right-aligned. This means when working in assembly we have to
  // account for the 3 unused bytes on the righthand side
  //
  // First 5 bytes are a type flag.
  // - ff_ffff_fffe is reserved for unknown type.
  // - ff_ffff_ffff is reserved for invalid types/errors.
  // next 12 are memory address
  // next 12 are len
  // bottom 3 bytes are empty

  // Assumptions:
  // - non-modification of memory.
  // - No Solidity updates
  // - - wrt free mem point
  // - - wrt bytes representation in memory
  // - - wrt memory addressing in general

  // Usage:
  // - create type constants
  // - use `assertType` for runtime type assertions
  // - - unfortunately we can't do this at compile time yet :(
  // - recommended: implement modifiers that perform type checking
  // - - e.g.
  // - - `uint40 constant MY_TYPE = 3;`
  // - - ` modifer onlyMyType(bytes29 myView) { myView.assertType(MY_TYPE); }`
  // - instantiate a typed view from a bytearray using `ref`
  // - use `index` to inspect the contents of the view
  // - use `slice` to create smaller views into the same memory
  // - - `slice` can increase the offset
  // - - `slice can decrease the length`
  // - - must specify the output type of `slice`
  // - - `slice` will return a null view if you try to overrun
  // - - make sure to explicitly check for this with `notNull` or `assertType`
  // - use `equal` for typed comparisons.

  // The null view
  bytes29 public constant NULL = hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
  uint256 constant LOW_12_MASK = 0xffffffffffffffffffffffff;
  uint8 constant TWELVE_BYTES = 96;

  /**
   * @notice      Returns the encoded hex character that represents the lower 4 bits of the argument.
   * @param _b    The byte
   * @return      char - The encoded hex character
   */
  function nibbleHex(uint8 _b) internal pure returns (uint8 char) {
    // This can probably be done more efficiently, but it's only in error
    // paths, so we don't really care :)
    uint8 _nibble = _b | 0xf0; // set top 4, keep bottom 4
    if (_nibble == 0xf0) {
      return 0x30;
    } // 0
    if (_nibble == 0xf1) {
      return 0x31;
    } // 1
    if (_nibble == 0xf2) {
      return 0x32;
    } // 2
    if (_nibble == 0xf3) {
      return 0x33;
    } // 3
    if (_nibble == 0xf4) {
      return 0x34;
    } // 4
    if (_nibble == 0xf5) {
      return 0x35;
    } // 5
    if (_nibble == 0xf6) {
      return 0x36;
    } // 6
    if (_nibble == 0xf7) {
      return 0x37;
    } // 7
    if (_nibble == 0xf8) {
      return 0x38;
    } // 8
    if (_nibble == 0xf9) {
      return 0x39;
    } // 9
    if (_nibble == 0xfa) {
      return 0x61;
    } // a
    if (_nibble == 0xfb) {
      return 0x62;
    } // b
    if (_nibble == 0xfc) {
      return 0x63;
    } // c
    if (_nibble == 0xfd) {
      return 0x64;
    } // d
    if (_nibble == 0xfe) {
      return 0x65;
    } // e
    if (_nibble == 0xff) {
      return 0x66;
    } // f
  }

  /**
   * @notice      Returns a uint16 containing the hex-encoded byte.
   * @param _b    The byte
   * @return      encoded - The hex-encoded byte
   */
  function byteHex(uint8 _b) internal pure returns (uint16 encoded) {
    encoded |= nibbleHex(_b >> 4); // top 4 bits
    encoded <<= 8;
    encoded |= nibbleHex(_b); // lower 4 bits
  }

  /**
   * @notice      Encodes the uint256 to hex. `first` contains the encoded top 16 bytes.
   *              `second` contains the encoded lower 16 bytes.
   *
   * @param _b    The 32 bytes as uint256
   * @return      first - The top 16 bytes
   * @return      second - The bottom 16 bytes
   */
  function encodeHex(uint256 _b) internal pure returns (uint256 first, uint256 second) {
    for (uint8 i = 31; i > 15; ) {
      uint8 _byte = uint8(_b >> (i * 8));
      first |= byteHex(_byte);
      if (i != 16) {
        first <<= 16;
      }
      unchecked {
        i -= 1;
      }
    }

    // abusing underflow here =_=
    for (uint8 i = 15; i < 255; ) {
      uint8 _byte = uint8(_b >> (i * 8));
      second |= byteHex(_byte);
      if (i != 0) {
        second <<= 16;
      }
      unchecked {
        i -= 1;
      }
    }
  }

  /**
   * @notice          Changes the endianness of a uint256.
   * @dev             https://graphics.stanford.edu/~seander/bithacks.html#ReverseParallel
   * @param _b        The unsigned integer to reverse
   * @return          v - The reversed value
   */
  function reverseUint256(uint256 _b) internal pure returns (uint256 v) {
    v = _b;

    // swap bytes
    v =
      ((v >> 8) & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) |
      ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);
    // swap 2-byte long pairs
    v =
      ((v >> 16) & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) |
      ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);
    // swap 4-byte long pairs
    v =
      ((v >> 32) & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) |
      ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);
    // swap 8-byte long pairs
    v =
      ((v >> 64) & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) |
      ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);
    // swap 16-byte long pairs
    v = (v >> 128) | (v << 128);
  }

  /**
   * @notice      Create a mask with the highest `_len` bits set.
   * @param _len  The length
   * @return      mask - The mask
   */
  function leftMask(uint8 _len) private pure returns (uint256 mask) {
    // ugly. redo without assembly?
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      mask := sar(sub(_len, 1), 0x8000000000000000000000000000000000000000000000000000000000000000)
    }
  }

  /**
   * @notice      Return the null view.
   * @return      bytes29 - The null view
   */
  function nullView() internal pure returns (bytes29) {
    return NULL;
  }

  /**
   * @notice      Check if the view is null.
   * @return      bool - True if the view is null
   */
  function isNull(bytes29 memView) internal pure returns (bool) {
    return memView == NULL;
  }

  /**
   * @notice      Check if the view is not null.
   * @return      bool - True if the view is not null
   */
  function notNull(bytes29 memView) internal pure returns (bool) {
    return !isNull(memView);
  }

  /**
   * @notice          Check if the view is of a valid type and points to a valid location
   *                  in memory.
   * @dev             We perform this check by examining solidity's unallocated memory
   *                  pointer and ensuring that the view's upper bound is less than that.
   * @param memView   The view
   * @return          ret - True if the view is valid
   */
  function isValid(bytes29 memView) internal pure returns (bool ret) {
    if (typeOf(memView) == 0xffffffffff) {
      return false;
    }
    uint256 _end = end(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ret := not(gt(_end, mload(0x40)))
    }
  }

  /**
   * @notice          Require that a typed memory view be valid.
   * @dev             Returns the view for easy chaining.
   * @param memView   The view
   * @return          bytes29 - The validated view
   */
  function assertValid(bytes29 memView) internal pure returns (bytes29) {
    require(isValid(memView), "Validity assertion failed");
    return memView;
  }

  /**
   * @notice          Return true if the memview is of the expected type. Otherwise false.
   * @param memView   The view
   * @param _expected The expected type
   * @return          bool - True if the memview is of the expected type
   */
  function isType(bytes29 memView, uint40 _expected) internal pure returns (bool) {
    return typeOf(memView) == _expected;
  }

  /**
   * @notice          Require that a typed memory view has a specific type.
   * @dev             Returns the view for easy chaining.
   * @param memView   The view
   * @param _expected The expected type
   * @return          bytes29 - The view with validated type
   */
  function assertType(bytes29 memView, uint40 _expected) internal pure returns (bytes29) {
    if (!isType(memView, _expected)) {
      (, uint256 g) = encodeHex(uint256(typeOf(memView)));
      (, uint256 e) = encodeHex(uint256(_expected));
      string memory err = string(
        abi.encodePacked("Type assertion failed. Got 0x", uint80(g), ". Expected 0x", uint80(e))
      );
      revert(err);
    }
    return memView;
  }

  /**
   * @notice          Return an identical view with a different type.
   * @param memView   The view
   * @param _newType  The new type
   * @return          newView - The new view with the specified type
   */
  function castTo(bytes29 memView, uint40 _newType) internal pure returns (bytes29 newView) {
    // then | in the new type
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      // shift off the top 5 bytes
      newView := or(newView, shr(40, shl(40, memView)))
      newView := or(newView, shl(216, _newType))
    }
  }

  /**
   * @notice          Unsafe raw pointer construction. This should generally not be called
   *                  directly. Prefer `ref` wherever possible.
   * @dev             Unsafe raw pointer construction. This should generally not be called
   *                  directly. Prefer `ref` wherever possible.
   * @param _type     The type
   * @param _loc      The memory address
   * @param _len      The length
   * @return          newView - The new view with the specified type, location and length
   */
  function unsafeBuildUnchecked(
    uint256 _type,
    uint256 _loc,
    uint256 _len
  ) private pure returns (bytes29 newView) {
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      newView := shl(96, or(newView, _type)) // insert type
      newView := shl(96, or(newView, _loc)) // insert loc
      newView := shl(24, or(newView, _len)) // empty bottom 3 bytes
    }
  }

  /**
   * @notice          Instantiate a new memory view. This should generally not be called
   *                  directly. Prefer `ref` wherever possible.
   * @dev             Instantiate a new memory view. This should generally not be called
   *                  directly. Prefer `ref` wherever possible.
   * @param _type     The type
   * @param _loc      The memory address
   * @param _len      The length
   * @return          newView - The new view with the specified type, location and length
   */
  function build(
    uint256 _type,
    uint256 _loc,
    uint256 _len
  ) internal pure returns (bytes29 newView) {
    uint256 _end = _loc + _len;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      if gt(_end, mload(0x40)) {
        _end := 0
      }
    }
    if (_end == 0) {
      return NULL;
    }
    newView = unsafeBuildUnchecked(_type, _loc, _len);
  }

  /**
   * @notice          Instantiate a memory view from a byte array.
   * @dev             Note that due to Solidity memory representation, it is not possible to
   *                  implement a deref, as the `bytes` type stores its len in memory.
   * @param arr       The byte array
   * @param newType   The type
   * @return          bytes29 - The memory view
   */
  function ref(bytes memory arr, uint40 newType) internal pure returns (bytes29) {
    uint256 _len = arr.length;

    uint256 _loc;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      _loc := add(arr, 0x20) // our view is of the data, not the struct
    }

    return build(newType, _loc, _len);
  }

  /**
   * @notice          Return the associated type information.
   * @param memView   The memory view
   * @return          _type - The type associated with the view
   */
  function typeOf(bytes29 memView) internal pure returns (uint40 _type) {
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      // 216 == 256 - 40
      _type := shr(216, memView) // shift out lower 24 bytes
    }
  }

  /**
   * @notice          Optimized type comparison. Checks that the 5-byte type flag is equal.
   * @param left      The first view
   * @param right     The second view
   * @return          bool - True if the 5-byte type flag is equal
   */
  function sameType(bytes29 left, bytes29 right) internal pure returns (bool) {
    return (left ^ right) >> (2 * TWELVE_BYTES) == 0;
  }

  /**
   * @notice          Return the memory address of the underlying bytes.
   * @param memView   The view
   * @return          _loc - The memory address
   */
  function loc(bytes29 memView) internal pure returns (uint96 _loc) {
    uint256 _mask = LOW_12_MASK; // assembly can't use globals
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      // 120 bits = 12 bytes (the encoded loc) + 3 bytes (empty low space)
      _loc := and(shr(120, memView), _mask)
    }
  }

  /**
   * @notice          The number of memory words this memory view occupies, rounded up.
   * @param memView   The view
   * @return          uint256 - The number of memory words
   */
  function words(bytes29 memView) internal pure returns (uint256) {
    return (uint256(len(memView)) + 32) / 32;
  }

  /**
   * @notice          The in-memory footprint of a fresh copy of the view.
   * @param memView   The view
   * @return          uint256 - The in-memory footprint of a fresh copy of the view.
   */
  function footprint(bytes29 memView) internal pure returns (uint256) {
    return words(memView) * 32;
  }

  /**
   * @notice          The number of bytes of the view.
   * @param memView   The view
   * @return          _len - The length of the view
   */
  function len(bytes29 memView) internal pure returns (uint96 _len) {
    uint256 _mask = LOW_12_MASK; // assembly can't use globals
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      _len := and(shr(24, memView), _mask)
    }
  }

  /**
   * @notice          Returns the endpoint of `memView`.
   * @param memView   The view
   * @return          uint256 - The endpoint of `memView`
   */
  function end(bytes29 memView) internal pure returns (uint256) {
    unchecked {
      return loc(memView) + len(memView);
    }
  }

  /**
   * @notice          Safe slicing without memory modification.
   * @param memView   The view
   * @param _index    The start index
   * @param _len      The length
   * @param newType   The new type
   * @return          bytes29 - The new view
   */
  function slice(
    bytes29 memView,
    uint256 _index,
    uint256 _len,
    uint40 newType
  ) internal pure returns (bytes29) {
    uint256 _loc = loc(memView);

    // Ensure it doesn't overrun the view
    if (_loc + _index + _len > end(memView)) {
      return NULL;
    }

    _loc = _loc + _index;
    return build(newType, _loc, _len);
  }

  /**
   * @notice          Shortcut to `slice`. Gets a view representing the first `_len` bytes.
   * @param memView   The view
   * @param _len      The length
   * @param newType   The new type
   * @return          bytes29 - The new view
   */
  function prefix(
    bytes29 memView,
    uint256 _len,
    uint40 newType
  ) internal pure returns (bytes29) {
    return slice(memView, 0, _len, newType);
  }

  /**
   * @notice          Shortcut to `slice`. Gets a view representing the last `_len` byte.
   * @param memView   The view
   * @param _len      The length
   * @param newType   The new type
   * @return          bytes29 - The new view
   */
  function postfix(
    bytes29 memView,
    uint256 _len,
    uint40 newType
  ) internal pure returns (bytes29) {
    return slice(memView, uint256(len(memView)) - _len, _len, newType);
  }

  /**
   * @notice          Construct an error message for an indexing overrun.
   * @param _loc      The memory address
   * @param _len      The length
   * @param _index    The index
   * @param _slice    The slice where the overrun occurred
   * @return          err - The err
   */
  function indexErrOverrun(
    uint256 _loc,
    uint256 _len,
    uint256 _index,
    uint256 _slice
  ) internal pure returns (string memory err) {
    (, uint256 a) = encodeHex(_loc);
    (, uint256 b) = encodeHex(_len);
    (, uint256 c) = encodeHex(_index);
    (, uint256 d) = encodeHex(_slice);
    err = string(
      abi.encodePacked(
        "TypedMemView/index - Overran the view. Slice is at 0x",
        uint48(a),
        " with length 0x",
        uint48(b),
        ". Attempted to index at offset 0x",
        uint48(c),
        " with length 0x",
        uint48(d),
        "."
      )
    );
  }

  /**
   * @notice          Load up to 32 bytes from the view onto the stack.
   * @dev             Returns a bytes32 with only the `_bytes` highest bytes set.
   *                  This can be immediately cast to a smaller fixed-length byte array.
   *                  To automatically cast to an integer, use `indexUint`.
   * @param memView   The view
   * @param _index    The index
   * @param _bytes    The bytes
   * @return          result - The 32 byte result
   */
  function index(
    bytes29 memView,
    uint256 _index,
    uint8 _bytes
  ) internal pure returns (bytes32 result) {
    if (_bytes == 0) {
      return bytes32(0);
    }
    if (_index + _bytes > len(memView)) {
      revert(indexErrOverrun(loc(memView), len(memView), _index, uint256(_bytes)));
    }
    require(_bytes <= 32, "TypedMemView/index - Attempted to index more than 32 bytes");

    uint8 bitLength;
    unchecked {
      bitLength = _bytes * 8;
    }
    uint256 _loc = loc(memView);
    uint256 _mask = leftMask(bitLength);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      result := and(mload(add(_loc, _index)), _mask)
    }
  }

  /**
   * @notice          Parse an unsigned integer from the view at `_index`.
   * @dev             Requires that the view have >= `_bytes` bytes following that index.
   * @param memView   The view
   * @param _index    The index
   * @param _bytes    The bytes
   * @return          result - The unsigned integer
   */
  function indexUint(
    bytes29 memView,
    uint256 _index,
    uint8 _bytes
  ) internal pure returns (uint256 result) {
    return uint256(index(memView, _index, _bytes)) >> ((32 - _bytes) * 8);
  }

  /**
   * @notice          Parse an unsigned integer from LE bytes.
   * @param memView   The view
   * @param _index    The index
   * @param _bytes    The bytes
   * @return          result - The unsigned integer
   */
  function indexLEUint(
    bytes29 memView,
    uint256 _index,
    uint8 _bytes
  ) internal pure returns (uint256 result) {
    return reverseUint256(uint256(index(memView, _index, _bytes)));
  }

  /**
   * @notice          Parse an address from the view at `_index`. Requires that the view have >= 20 bytes
   *                  following that index.
   * @param memView   The view
   * @param _index    The index
   * @return          address - The address
   */
  function indexAddress(bytes29 memView, uint256 _index) internal pure returns (address) {
    return address(uint160(indexUint(memView, _index, 20)));
  }

  /**
   * @notice          Return the keccak256 hash of the underlying memory
   * @param memView   The view
   * @return          digest - The keccak256 hash of the underlying memory
   */
  function keccak(bytes29 memView) internal pure returns (bytes32 digest) {
    uint256 _loc = loc(memView);
    uint256 _len = len(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      digest := keccak256(_loc, _len)
    }
  }

  /**
   * @notice          Return the sha2 digest of the underlying memory.
   * @dev             We explicitly deallocate memory afterwards.
   * @param memView   The view
   * @return          digest - The sha2 hash of the underlying memory
   */
  function sha2(bytes29 memView) internal view returns (bytes32 digest) {
    uint256 _loc = loc(memView);
    uint256 _len = len(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      let ptr := mload(0x40)
      pop(staticcall(gas(), 2, _loc, _len, ptr, 0x20)) // sha2 #1
      digest := mload(ptr)
    }
  }

  /**
   * @notice          Implements bitcoin's hash160 (rmd160(sha2()))
   * @param memView   The pre-image
   * @return          digest - the Digest
   */
  function hash160(bytes29 memView) internal view returns (bytes20 digest) {
    uint256 _loc = loc(memView);
    uint256 _len = len(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      let ptr := mload(0x40)
      pop(staticcall(gas(), 2, _loc, _len, ptr, 0x20)) // sha2
      pop(staticcall(gas(), 3, ptr, 0x20, ptr, 0x20)) // rmd160
      digest := mload(add(ptr, 0xc)) // return value is 0-prefixed.
    }
  }

  /**
   * @notice          Implements bitcoin's hash256 (double sha2)
   * @param memView   A view of the preimage
   * @return          digest - the Digest
   */
  function hash256(bytes29 memView) internal view returns (bytes32 digest) {
    uint256 _loc = loc(memView);
    uint256 _len = len(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      let ptr := mload(0x40)
      pop(staticcall(gas(), 2, _loc, _len, ptr, 0x20)) // sha2 #1
      pop(staticcall(gas(), 2, ptr, 0x20, ptr, 0x20)) // sha2 #2
      digest := mload(ptr)
    }
  }

  /**
   * @notice          Return true if the underlying memory is equal. Else false.
   * @param left      The first view
   * @param right     The second view
   * @return          bool - True if the underlying memory is equal
   */
  function untypedEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
    return (loc(left) == loc(right) && len(left) == len(right)) || keccak(left) == keccak(right);
  }

  /**
   * @notice          Return false if the underlying memory is equal. Else true.
   * @param left      The first view
   * @param right     The second view
   * @return          bool - False if the underlying memory is equal
   */
  function untypedNotEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
    return !untypedEqual(left, right);
  }

  /**
   * @notice          Compares type equality.
   * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
   * @param left      The first view
   * @param right     The second view
   * @return          bool - True if the types are the same
   */
  function equal(bytes29 left, bytes29 right) internal pure returns (bool) {
    return left == right || (typeOf(left) == typeOf(right) && keccak(left) == keccak(right));
  }

  /**
   * @notice          Compares type inequality.
   * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
   * @param left      The first view
   * @param right     The second view
   * @return          bool - True if the types are not the same
   */
  function notEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
    return !equal(left, right);
  }

  /**
   * @notice          Copy the view to a location, return an unsafe memory reference
   * @dev             Super Dangerous direct memory access.
   *
   *                  This reference can be overwritten if anything else modifies memory (!!!).
   *                  As such it MUST be consumed IMMEDIATELY.
   *                  This function is private to prevent unsafe usage by callers.
   * @param memView   The view
   * @param _newLoc   The new location
   * @return          written - the unsafe memory reference
   */
  function unsafeCopyTo(bytes29 memView, uint256 _newLoc) private view returns (bytes29 written) {
    require(notNull(memView), "TypedMemView/copyTo - Null pointer deref");
    require(isValid(memView), "TypedMemView/copyTo - Invalid pointer deref");
    uint256 _len = len(memView);
    uint256 _oldLoc = loc(memView);

    uint256 ptr;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ptr := mload(0x40)
      // revert if we're writing in occupied memory
      if gt(ptr, _newLoc) {
        revert(0x60, 0x20) // empty revert message
      }

      // use the identity precompile to copy
      // guaranteed not to fail, so pop the success
      pop(staticcall(gas(), 4, _oldLoc, _len, _newLoc, _len))
    }

    written = unsafeBuildUnchecked(typeOf(memView), _newLoc, _len);
  }

  /**
   * @notice          Copies the referenced memory to a new loc in memory, returning a `bytes` pointing to
   *                  the new memory
   * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
   * @param memView   The view
   * @return          ret - The view pointing to the new memory
   */
  function clone(bytes29 memView) internal view returns (bytes memory ret) {
    uint256 ptr;
    uint256 _len = len(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ptr := mload(0x40) // load unused memory pointer
      ret := ptr
    }
    unchecked {
      unsafeCopyTo(memView, ptr + 0x20);
    }
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      mstore(0x40, add(add(ptr, _len), 0x20)) // write new unused pointer
      mstore(ptr, _len) // write len of new array (in bytes)
    }
  }

  /**
   * @notice          Join the views in memory, return an unsafe reference to the memory.
   * @dev             Super Dangerous direct memory access.
   *
   *                  This reference can be overwritten if anything else modifies memory (!!!).
   *                  As such it MUST be consumed IMMEDIATELY.
   *                  This function is private to prevent unsafe usage by callers.
   * @param memViews  The views
   * @return          unsafeView - The conjoined view pointing to the new memory
   */
  function unsafeJoin(bytes29[] memory memViews, uint256 _location) private view returns (bytes29 unsafeView) {
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      let ptr := mload(0x40)
      // revert if we're writing in occupied memory
      if gt(ptr, _location) {
        revert(0x60, 0x20) // empty revert message
      }
    }

    uint256 _offset = 0;
    for (uint256 i = 0; i < memViews.length; i++) {
      bytes29 memView = memViews[i];
      unchecked {
        unsafeCopyTo(memView, _location + _offset);
        _offset += len(memView);
      }
    }
    unsafeView = unsafeBuildUnchecked(0, _location, _offset);
  }

  /**
   * @notice          Produce the keccak256 digest of the concatenated contents of multiple views.
   * @param memViews  The views
   * @return          bytes32 - The keccak256 digest
   */
  function joinKeccak(bytes29[] memory memViews) internal view returns (bytes32) {
    uint256 ptr;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ptr := mload(0x40) // load unused memory pointer
    }
    return keccak(unsafeJoin(memViews, ptr));
  }

  /**
   * @notice          Produce the sha256 digest of the concatenated contents of multiple views.
   * @param memViews  The views
   * @return          bytes32 - The sha256 digest
   */
  function joinSha2(bytes29[] memory memViews) internal view returns (bytes32) {
    uint256 ptr;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ptr := mload(0x40) // load unused memory pointer
    }
    return sha2(unsafeJoin(memViews, ptr));
  }

  /**
   * @notice          copies all views, joins them into a new bytearray.
   * @param memViews  The views
   * @return          ret - The new byte array
   */
  function join(bytes29[] memory memViews) internal view returns (bytes memory ret) {
    uint256 ptr;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ptr := mload(0x40) // load unused memory pointer
    }

    bytes29 _newView;
    unchecked {
      _newView = unsafeJoin(memViews, ptr + 0x20);
    }
    uint256 _written = len(_newView);
    uint256 _footprint = footprint(_newView);

    assembly {
      // solhint-disable-previous-line no-inline-assembly
      // store the legnth
      mstore(ptr, _written)
      // new pointer is old + 0x20 + the footprint of the body
      mstore(0x40, add(add(ptr, _footprint), 0x20))
      ret := ptr
    }
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import {Version0} from "./Version0.sol";
import {NomadBase} from "./NomadBase.sol";
import {QueueLib} from "../libs/Queue.sol";
import {MerkleLib} from "../libs/Merkle.sol";
import {Message} from "../libs/Message.sol";
import {MerkleTreeManager} from "./Merkle.sol";
import {QueueManager} from "./Queue.sol";
import {IUpdaterManager} from "../interfaces/IUpdaterManager.sol";
// ============ External Imports ============
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Home
 * @author Illusory Systems Inc.
 * @notice Accepts messages to be dispatched to remote chains,
 * constructs a Merkle tree of the messages,
 * and accepts signatures from a bonded Updater
 * which notarize the Merkle tree roots.
 * Accepts submissions of fraudulent signatures
 * by the Updater and slashes the Updater in this case.
 */
contract Home is Version0, QueueManager, MerkleTreeManager, NomadBase {
  // ============ Libraries ============

  using QueueLib for QueueLib.Queue;
  using MerkleLib for MerkleLib.Tree;

  // ============ Constants ============

  // Maximum bytes per message = 2 KiB
  // (somewhat arbitrarily set to begin)
  uint256 public constant MAX_MESSAGE_BODY_BYTES = 2 * 2**10;

  // ============ Public Storage Variables ============

  // domain => next available nonce for the domain
  mapping(uint32 => uint32) public nonces;
  // contract responsible for Updater bonding, slashing and rotation
  IUpdaterManager public updaterManager;

  // ============ Upgrade Gap ============

  // gap for upgrade safety
  uint256[48] private __GAP;

  // ============ Events ============

  /**
   * @notice Emitted when a new message is dispatched via Nomad
   * @param leafIndex Index of message's leaf in merkle tree
   * @param destinationAndNonce Destination and destination-specific
   * nonce combined in single field ((destination << 32) & nonce)
   * @param messageHash Hash of message; the leaf inserted to the Merkle tree for the message
   * @param committedRoot the latest notarized root submitted in the last signed Update
   * @param message Raw bytes of message
   */
  event Dispatch(
    bytes32 indexed messageHash,
    uint256 indexed leafIndex,
    uint64 indexed destinationAndNonce,
    bytes32 committedRoot,
    bytes message
  );

  /**
   * @notice Emitted when proof of an improper update is submitted,
   * which sets the contract to FAILED state
   * @param oldRoot Old root of the improper update
   * @param newRoot New root of the improper update
   * @param signature Signature on `oldRoot` and `newRoot
   */
  event ImproperUpdate(bytes32 oldRoot, bytes32 newRoot, bytes signature);

  /**
   * @notice Emitted when the Updater is slashed
   * (should be paired with ImproperUpdater or DoubleUpdate event)
   * @param updater The address of the updater
   * @param reporter The address of the entity that reported the updater misbehavior
   */
  event UpdaterSlashed(address indexed updater, address indexed reporter);

  /**
   * @notice Emitted when the UpdaterManager contract is changed
   * @param updaterManager The address of the new updaterManager
   */
  event NewUpdaterManager(address updaterManager);

  // ============ Constructor ============

  constructor(uint32 _localDomain) NomadBase(_localDomain) {} // solhint-disable-line no-empty-blocks

  // ============ Initializer ============

  function initialize(IUpdaterManager _updaterManager) public initializer {
    // initialize queue, set Updater Manager, and initialize
    __QueueManager_initialize();
    _setUpdaterManager(_updaterManager);
    __NomadBase_initialize(updaterManager.updater());
  }

  // ============ Modifiers ============

  /**
   * @notice Ensures that function is called by the UpdaterManager contract
   */
  modifier onlyUpdaterManager() {
    require(msg.sender == address(updaterManager), "!updaterManager");
    _;
  }

  // ============ External: Updater & UpdaterManager Configuration  ============

  /**
   * @notice Set a new Updater
   * @param _updater the new Updater
   */
  function setUpdater(address _updater) external onlyUpdaterManager {
    _setUpdater(_updater);
  }

  /**
   * @notice Set a new UpdaterManager contract
   * @dev Home(s) will initially be initialized using a trusted UpdaterManager contract;
   * we will progressively decentralize by swapping the trusted contract with a new implementation
   * that implements Updater bonding & slashing, and rules for Updater selection & rotation
   * @param _updaterManager the new UpdaterManager contract
   */
  function setUpdaterManager(address _updaterManager) external onlyOwner {
    _setUpdaterManager(IUpdaterManager(_updaterManager));
  }

  // ============ External Functions  ============

  /**
   * @notice Dispatch the message it to the destination domain & recipient
   * @dev Format the message, insert its hash into Merkle tree,
   * enqueue the new Merkle root, and emit `Dispatch` event with message information.
   * @param _destinationDomain Domain of destination chain
   * @param _recipientAddress Address of recipient on destination chain as bytes32
   * @param _messageBody Raw bytes content of message
   */
  function dispatch(
    uint32 _destinationDomain,
    bytes32 _recipientAddress,
    bytes memory _messageBody
  ) external notFailed {
    require(_messageBody.length <= MAX_MESSAGE_BODY_BYTES, "msg too long");
    // get the next nonce for the destination domain, then increment it
    uint32 _nonce = nonces[_destinationDomain];
    nonces[_destinationDomain] = _nonce + 1;
    // format the message into packed bytes
    bytes memory _message = Message.formatMessage(
      localDomain,
      bytes32(uint256(uint160(msg.sender))),
      _nonce,
      _destinationDomain,
      _recipientAddress,
      _messageBody
    );
    // insert the hashed message into the Merkle tree
    bytes32 _messageHash = keccak256(_message);
    tree.insert(_messageHash);
    // enqueue the new Merkle root after inserting the message
    queue.enqueue(root());
    // Emit Dispatch event with message information
    // note: leafIndex is count() - 1 since new leaf has already been inserted
    emit Dispatch(_messageHash, count() - 1, _destinationAndNonce(_destinationDomain, _nonce), committedRoot, _message);
  }

  /**
   * @notice Submit a signature from the Updater "notarizing" a root,
   * which updates the Home contract's `committedRoot`,
   * and publishes the signature which will be relayed to Replica contracts
   * @dev emits Update event
   * @dev If _newRoot is not contained in the queue,
   * the Update is a fraudulent Improper Update, so
   * the Updater is slashed & Home is set to FAILED state
   * @param _committedRoot Current updated merkle root which the update is building off of
   * @param _newRoot New merkle root to update the contract state to
   * @param _signature Updater signature on `_committedRoot` and `_newRoot`
   */
  function update(
    bytes32 _committedRoot,
    bytes32 _newRoot,
    bytes memory _signature
  ) external notFailed {
    // check that the update is not fraudulent;
    // if fraud is detected, Updater is slashed & Home is set to FAILED state
    if (improperUpdate(_committedRoot, _newRoot, _signature)) return;
    // clear all of the intermediate roots contained in this update from the queue
    while (true) {
      bytes32 _next = queue.dequeue();
      if (_next == _newRoot) break;
    }
    // update the Home state with the latest signed root & emit event
    committedRoot = _newRoot;
    emit Update(localDomain, _committedRoot, _newRoot, _signature);
  }

  /**
   * @notice Suggest an update for the Updater to sign and submit.
   * @dev If queue is empty, null bytes returned for both
   * (No update is necessary because no messages have been dispatched since the last update)
   * @return _committedRoot Latest root signed by the Updater
   * @return _new Latest enqueued Merkle root
   */
  function suggestUpdate() external view returns (bytes32 _committedRoot, bytes32 _new) {
    if (queue.length() != 0) {
      _committedRoot = committedRoot;
      _new = queue.lastItem();
    }
  }

  // ============ Public Functions  ============

  /**
   * @notice Hash of Home domain concatenated with "NOMAD"
   */
  function homeDomainHash() public view override returns (bytes32) {
    return _homeDomainHash(localDomain);
  }

  /**
   * @notice Check if an Update is an Improper Update;
   * if so, slash the Updater and set the contract to FAILED state.
   *
   * An Improper Update is an update building off of the Home's `committedRoot`
   * for which the `_newRoot` does not currently exist in the Home's queue.
   * This would mean that message(s) that were not truly
   * dispatched on Home were falsely included in the signed root.
   *
   * An Improper Update will only be accepted as valid by the Replica
   * If an Improper Update is attempted on Home,
   * the Updater will be slashed immediately.
   * If an Improper Update is submitted to the Replica,
   * it should be relayed to the Home contract using this function
   * in order to slash the Updater with an Improper Update.
   *
   * An Improper Update submitted to the Replica is only valid
   * while the `_oldRoot` is still equal to the `committedRoot` on Home;
   * if the `committedRoot` on Home has already been updated with a valid Update,
   * then the Updater should be slashed with a Double Update.
   * @dev Reverts (and doesn't slash updater) if signature is invalid or
   * update not current
   * @param _oldRoot Old merkle tree root (should equal home's committedRoot)
   * @param _newRoot New merkle tree root
   * @param _signature Updater signature on `_oldRoot` and `_newRoot`
   * @return TRUE if update was an Improper Update (implying Updater was slashed)
   */
  function improperUpdate(
    bytes32 _oldRoot,
    bytes32 _newRoot,
    bytes memory _signature
  ) public notFailed returns (bool) {
    require(_isUpdaterSignature(_oldRoot, _newRoot, _signature), "!updater sig");
    require(_oldRoot == committedRoot, "not a current update");
    // if the _newRoot is not currently contained in the queue,
    // slash the Updater and set the contract to FAILED state
    if (!queue.contains(_newRoot)) {
      _fail();
      emit ImproperUpdate(_oldRoot, _newRoot, _signature);
      return true;
    }
    // if the _newRoot is contained in the queue,
    // this is not an improper update
    return false;
  }

  // ============ Internal Functions  ============

  /**
   * @notice Set the UpdaterManager
   * @param _updaterManager Address of the UpdaterManager
   */
  function _setUpdaterManager(IUpdaterManager _updaterManager) internal {
    require(Address.isContract(address(_updaterManager)), "!contract updaterManager");
    updaterManager = IUpdaterManager(_updaterManager);
    emit NewUpdaterManager(address(_updaterManager));
  }

  /**
   * @notice Slash the Updater and set contract state to FAILED
   * @dev Called when fraud is proven (Improper Update or Double Update)
   */
  function _fail() internal override {
    // set contract to FAILED
    _setFailed();
    // slash Updater
    updaterManager.slashUpdater(payable(msg.sender));
    emit UpdaterSlashed(updater, msg.sender);
  }

  /**
   * @notice Internal utility function that combines
   * `_destination` and `_nonce`.
   * @dev Both destination and nonce should be less than 2^32 - 1
   * @param _destination Domain of destination chain
   * @param _nonce Current nonce for given destination chain
   * @return Returns (`_destination` << 32) & `_nonce`
   */
  function _destinationAndNonce(uint32 _destination, uint32 _nonce) internal pure returns (uint64) {
    return (uint64(_destination) << 32) | _nonce;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.11;

// ============ Internal Imports ============
import {IConnextHandler} from "../../../interfaces/IConnextHandler.sol";
import {Router} from "../Router.sol";
import {XAppConnectionClient} from "../XAppConnectionClient.sol";
import {RelayerFeeMessage} from "./RelayerFeeMessage.sol";
import {IBridgeToken} from "../../interfaces/bridge/IBridgeToken.sol";

// ============ External Imports ============
import {Home} from "../../../nomad-core/contracts/Home.sol";
import {Version0} from "../../../nomad-core/contracts/Version0.sol";
import {TypedMemView} from "../../../nomad-core/libs/TypedMemView.sol";

/**
 * @title RelayerFeeRouter
 */
contract RelayerFeeRouter is Version0, Router {
  // ============ Libraries ============

  using TypedMemView for bytes;
  using TypedMemView for bytes29;
  using RelayerFeeMessage for bytes29;

  // ========== Custom Errors ===========

  error RelayerFeeRouter__onlyConnext_notConnext();
  error RelayerFeeRouter__send_claimEmpty();
  error RelayerFeeRouter__send_recipientEmpty();

  // ============ Public Storage ============

  IConnextHandler public connext;

  // ============ Upgrade Gap ============

  // gap for upgrade safety
  uint256[49] private __GAP;

  // ======== Events =========

  /**
   * @notice Emitted when a fees claim has been initialized in this domain
   * @param domain The domain where to claim the fees
   * @param recipient The address of the relayer
   * @param transferIds A group of transaction ids to claim for fee bumps
   * @param remote Remote RelayerFeeRouter address
   * @param message The message sent to the destination domain
   */
  event Send(uint32 domain, address recipient, bytes32[] transferIds, bytes32 remote, bytes message);

  /**
   * @notice Emitted when the a fees claim message has arrived to this domain
   * @param originAndNonce Domain where the transfer originated and the unique identifier
   * for the message from origin to destination, combined in a single field ((origin << 32) & nonce)
   * @param origin Domain where the transfer originated
   * @param recipient The address of the relayer
   * @param transferIds A group of transaction ids to claim for fee bumps
   */
  event Receive(uint64 indexed originAndNonce, uint32 indexed origin, address indexed recipient, bytes32[] transferIds);

  /**
   * @notice Emitted when a new Connext address is set
   * @param connext The new connext address
   */
  event SetConnext(address indexed connext);

  // ============ Modifiers ============

  /**
   * @notice Restricts the caller to the local bridge router
   */
  modifier onlyConnext() {
    if (msg.sender != address(connext)) revert RelayerFeeRouter__onlyConnext_notConnext();
    _;
  }

  // ======== Initializer ========

  function initialize(address _xAppConnectionManager) public initializer {
    __XAppConnectionClient_initialize(_xAppConnectionManager);
  }

  /**
   * @notice Sets the Connext.
   * @dev Connext and relayer fee router store references to each other
   * @param _connext The address of the Connext implementation
   */
  function setConnext(address _connext) external onlyOwner {
    connext = IConnextHandler(_connext);
    emit SetConnext(_connext);
  }

  // ======== External: Send Claim =========

  /**
   * @notice Sends a request to claim the fees in the originated domain
   * @param _domain The domain where to claim the fees
   * @param _recipient The address of the relayer
   * @param _transferIds A group of transfer ids to claim for fee bumps
   */
  function send(
    uint32 _domain,
    address _recipient,
    bytes32[] calldata _transferIds
  ) external onlyConnext {
    if (_transferIds.length == 0) revert RelayerFeeRouter__send_claimEmpty();
    if (_recipient == address(0)) revert RelayerFeeRouter__send_recipientEmpty();

    // get remote RelayerFeeRouter address; revert if not found
    bytes32 remote = _mustHaveRemote(_domain);

    bytes memory message = RelayerFeeMessage.formatClaimFees(_recipient, _transferIds);

    xAppConnectionManager.home().dispatch(_domain, remote, message);

    // emit Send event
    emit Send(_domain, _recipient, _transferIds, remote, message);
  }

  // ======== External: Handle =========

  /**
   * @notice Handles an incoming message
   * @param _origin The origin domain
   * @param _nonce The unique identifier for the message from origin to destination
   * @param _sender The sender address
   * @param _message The message
   */
  function handle(
    uint32 _origin,
    uint32 _nonce,
    bytes32 _sender,
    bytes memory _message
  ) external override onlyReplica onlyRemoteRouter(_origin, _sender) {
    // parse recipient and transferIds from message
    bytes29 _msg = _message.ref(0).mustBeClaimFees();

    address recipient = _msg.recipient();
    bytes32[] memory transferIds = _msg.transferIds();

    connext.claim(recipient, transferIds);

    // emit Receive event
    emit Receive(_originAndNonce(_origin, _nonce), _origin, recipient, transferIds);
  }

  /**
   * @dev explicit override for compiler inheritance
   * @dev explicit override for compiler inheritance
   * @return domain of chain on which the contract is deployed
   */
  function _localDomain() internal view override(XAppConnectionClient) returns (uint32) {
    return XAppConnectionClient._localDomain();
  }

  /**
   * @notice Internal utility function that combines
   * `_origin` and `_nonce`.
   * @dev Both origin and nonce should be less than 2^32 - 1
   * @param _origin Domain of chain where the transfer originated
   * @param _nonce The unique identifier for the message from origin to destination
   * @return Returns (`_origin` << 32) & `_nonce`
   */
  function _originAndNonce(uint32 _origin, uint32 _nonce) internal pure returns (uint64) {
    return (uint64(_origin) << 32) | _nonce;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import {XAppConnectionClient} from "./XAppConnectionClient.sol";
// ============ External Imports ============
import {IMessageRecipient} from "../../nomad-core/interfaces/IMessageRecipient.sol";

abstract contract Router is XAppConnectionClient, IMessageRecipient {
  // ============ Mutable Storage ============

  mapping(uint32 => bytes32) public remotes;
  uint256[49] private __GAP; // gap for upgrade safety

  // ============ Modifiers ============

  /**
   * @notice Only accept messages from a remote Router contract
   * @param _origin The domain the message is coming from
   * @param _router The address the message is coming from
   */
  modifier onlyRemoteRouter(uint32 _origin, bytes32 _router) {
    require(_isRemoteRouter(_origin, _router), "!remote router");
    _;
  }

  // ============ External functions ============

  /**
   * @notice Register the address of a Router contract for the same xApp on a remote chain
   * @param _domain The domain of the remote xApp Router
   * @param _router The address of the remote xApp Router
   */
  function enrollRemoteRouter(uint32 _domain, bytes32 _router) external onlyOwner {
    remotes[_domain] = _router;
  }

  // ============ Virtual functions ============

  function handle(
    uint32 _origin,
    uint32 _nonce,
    bytes32 _sender,
    bytes memory _message
  ) external virtual override;

  // ============ Internal functions ============
  /**
   * @notice Return true if the given domain / router is the address of a remote xApp Router
   * @param _domain The domain of the potential remote xApp Router
   * @param _router The address of the potential remote xApp Router
   */
  function _isRemoteRouter(uint32 _domain, bytes32 _router) internal view returns (bool) {
    return remotes[_domain] == _router;
  }

  /**
   * @notice Assert that the given domain has a xApp Router registered and return its address
   * @param _domain The domain of the chain for which to get the xApp Router
   * @return _remote The address of the remote xApp Router on _domain
   */
  function _mustHaveRemote(uint32 _domain) internal view returns (bytes32 _remote) {
    _remote = remotes[_domain];
    require(_remote != bytes32(0), "!remote");
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

// TODO: replace with nomad import
import {TypedMemView} from "../../../nomad-core/libs/TypedMemView.sol";

library ConnextMessage {
  // ============ Libraries ============

  using TypedMemView for bytes;
  using TypedMemView for bytes29;

  // ============ Enums ============

  // WARNING: do NOT re-write the numbers / order
  // of message types in an upgrade;
  // will cause in-flight messages to be mis-interpreted
  enum Types {
    Invalid, // 0
    TokenId, // 1
    Message, // 2
    Transfer // 3
  }

  // ============ Structs ============

  // Tokens are identified by a TokenId:
  // domain - 4 byte chain ID of the chain from which the token originates
  // id - 32 byte identifier of the token address on the origin chain, in that chain's address format
  struct TokenId {
    uint32 domain;
    bytes32 id;
  }

  // ============ Constants ============

  uint256 private constant TOKEN_ID_LEN = 36; // 4 bytes domain + 32 bytes id
  uint256 private constant IDENTIFIER_LEN = 1;
  uint256 private constant TRANSFER_LEN = 129;
  // 1 byte identifier + 32 bytes recipient + 32 bytes amount + 32 bytes detailsHash + 32 bytes external hash

  // ============ Modifiers ============

  /**
   * @notice Asserts a message is of type `_t`
   * @param _view The message
   * @param _t The expected type
   */
  modifier typeAssert(bytes29 _view, Types _t) {
    _view.assertType(uint40(_t));
    _;
  }

  // ============ Internal Functions: Validation ============

  /**
   * @notice Checks that Action is valid type
   * @param _action The action
   * @return TRUE if action is valid
   */
  function isValidAction(bytes29 _action) internal pure returns (bool) {
    return isTransfer(_action);
  }

  /**
   * @notice Checks that the message is of the specified type
   * @param _type the type to check for
   * @param _action The message
   * @return True if the message is of the specified type
   */
  function isType(bytes29 _action, Types _type) internal pure returns (bool) {
    return actionType(_action) == uint8(_type) && messageType(_action) == _type;
  }

  /**
   * @notice Checks that the message is of type Transfer
   * @param _action The message
   * @return True if the message is of type Transfer
   */
  function isTransfer(bytes29 _action) internal pure returns (bool) {
    return isType(_action, Types.Transfer);
  }

  /**
   * @notice Checks that view is a valid message length
   * @param _view The bytes string
   * @return TRUE if message is valid
   */
  function isValidMessageLength(bytes29 _view) internal pure returns (bool) {
    uint256 _len = _view.len();
    return _len == TOKEN_ID_LEN + TRANSFER_LEN;
  }

  /**
   * @notice Asserts that the message is of type Message
   * @param _view The message
   * @return The message
   */
  function mustBeMessage(bytes29 _view) internal pure returns (bytes29) {
    return tryAsMessage(_view).assertValid();
  }

  // ============ Internal Functions: Formatting ============

  /**
   * @notice Formats an action message
   * @param _tokenId The token ID
   * @param _action The action
   * @return The formatted message
   */
  function formatMessage(bytes29 _tokenId, bytes29 _action)
    internal
    view
    typeAssert(_tokenId, Types.TokenId)
    returns (bytes memory)
  {
    require(isValidAction(_action), "!action");
    bytes29[] memory _views = new bytes29[](2);
    _views[0] = _tokenId;
    _views[1] = _action;
    return TypedMemView.join(_views);
  }

  /**
   * @notice Formats Transfer
   * @param _to The recipient address as bytes32
   * @param _amnt The transfer amount
   * @param _detailsHash The token details hash
   * @param _transferId Unique identifier for transfer
   * @return
   */
  function formatTransfer(
    bytes32 _to,
    uint256 _amnt,
    bytes32 _detailsHash,
    bytes32 _transferId
  ) internal pure returns (bytes29) {
    return
      abi.encodePacked(Types.Transfer, _to, _amnt, _detailsHash, _transferId).ref(0).castTo(uint40(Types.Transfer));
  }

  /**
   * @notice Serializes a Token ID struct
   * @param _tokenId The token id struct
   * @return The formatted Token ID
   */
  function formatTokenId(TokenId memory _tokenId) internal pure returns (bytes29) {
    return formatTokenId(_tokenId.domain, _tokenId.id);
  }

  /**
   * @notice Creates a serialized Token ID from components
   * @param _domain The domain
   * @param _id The ID
   * @return The formatted Token ID
   */
  function formatTokenId(uint32 _domain, bytes32 _id) internal pure returns (bytes29) {
    return abi.encodePacked(_domain, _id).ref(0).castTo(uint40(Types.TokenId));
  }

  /**
   * @notice Formats the keccak256 hash of the token details
   * Token Details Format:
   *      length of name cast to bytes - 32 bytes
   *      name - x bytes (variable)
   *      length of symbol cast to bytes - 32 bytes
   *      symbol - x bytes (variable)
   *      decimals - 1 byte
   * @param _name The name
   * @param _symbol The symbol
   * @param _decimals The decimals
   * @return The Details message
   */
  function formatDetailsHash(
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(bytes(_name).length, _name, bytes(_symbol).length, _symbol, _decimals));
  }

  /**
   * @notice Converts to a Message
   * @param _message The message
   * @return The newly typed message
   */
  function tryAsMessage(bytes29 _message) internal pure returns (bytes29) {
    if (isValidMessageLength(_message)) {
      return _message.castTo(uint40(Types.Message));
    }
    return TypedMemView.nullView();
  }

  // ============ Internal Functions: Parsing msg ============

  /**
   * @notice Returns the type of the message
   * @param _view The message
   * @return The type of the message
   */
  function messageType(bytes29 _view) internal pure returns (Types) {
    return Types(uint8(_view.typeOf()));
  }

  /**
   * @notice Retrieves the token ID from a Message
   * @param _message The message
   * @return The ID
   */
  function tokenId(bytes29 _message) internal pure typeAssert(_message, Types.Message) returns (bytes29) {
    return _message.slice(0, TOKEN_ID_LEN, uint40(Types.TokenId));
  }

  /**
   * @notice Retrieves the action data from a Message
   * @param _message The message
   * @return The action
   */
  function action(bytes29 _message) internal pure typeAssert(_message, Types.Message) returns (bytes29) {
    uint256 _actionLen = _message.len() - TOKEN_ID_LEN;
    uint40 _type = uint40(msgType(_message));
    return _message.slice(TOKEN_ID_LEN, _actionLen, _type);
  }

  // ============ Internal Functions: Parsing tokenId ============

  /**
   * @notice Retrieves the domain from a TokenID
   * @param _tokenId The message
   * @return The domain
   */
  function domain(bytes29 _tokenId) internal pure typeAssert(_tokenId, Types.TokenId) returns (uint32) {
    return uint32(_tokenId.indexUint(0, 4));
  }

  /**
   * @notice Retrieves the ID from a TokenID
   * @param _tokenId The message
   * @return The ID
   */
  function id(bytes29 _tokenId) internal pure typeAssert(_tokenId, Types.TokenId) returns (bytes32) {
    // before = 4 bytes domain
    return _tokenId.index(4, 32);
  }

  /**
   * @notice Retrieves the EVM ID
   * @param _tokenId The message
   * @return The EVM ID
   */
  function evmId(bytes29 _tokenId) internal pure typeAssert(_tokenId, Types.TokenId) returns (address) {
    // before = 4 bytes domain + 12 bytes empty to trim for address
    return _tokenId.indexAddress(16);
  }

  // ============ Internal Functions: Parsing action ============

  /**
   * @notice Retrieves the action identifier from message
   * @param _message The action
   * @return The message type
   */
  function msgType(bytes29 _message) internal pure returns (uint8) {
    return uint8(_message.indexUint(TOKEN_ID_LEN, 1));
  }

  /**
   * @notice Retrieves the identifier from action
   * @param _action The action
   * @return The action type
   */
  function actionType(bytes29 _action) internal pure returns (uint8) {
    return uint8(_action.indexUint(0, 1));
  }

  /**
   * @notice Retrieves the recipient from a Transfer
   * @param _transferAction The message
   * @return The recipient address as bytes32
   */
  function recipient(bytes29 _transferAction) internal pure returns (bytes32) {
    // before = 1 byte identifier
    return _transferAction.index(1, 32);
  }

  /**
   * @notice Retrieves the EVM Recipient from a Transfer
   * @param _transferAction The message
   * @return The EVM Recipient
   */
  function evmRecipient(bytes29 _transferAction) internal pure returns (address) {
    // before = 1 byte identifier + 12 bytes empty to trim for address = 13 bytes
    return _transferAction.indexAddress(13);
  }

  /**
   * @notice Retrieves the amount from a Transfer
   * @param _transferAction The message
   * @return The amount
   */
  function amnt(bytes29 _transferAction) internal pure returns (uint256) {
    // before = 1 byte identifier + 32 bytes ID = 33 bytes
    return _transferAction.indexUint(33, 32);
  }

  /**
   * @notice Retrieves the unique identifier from a Transfer
   * @param _transferAction The message
   * @return The amount
   */
  function transferId(bytes29 _transferAction) internal pure returns (bytes32) {
    // before = 1 byte identifier + 32 bytes ID + 32 bytes amount + 32 bytes detailsHash = 97 bytes
    return _transferAction.index(97, 32);
  }

  /**
   * @notice Retrieves the detailsHash from a Transfer
   * @param _transferAction The message
   * @return The detailsHash
   */
  function detailsHash(bytes29 _transferAction) internal pure returns (bytes32) {
    // before = 1 byte identifier + 32 bytes ID + 32 bytes amount = 65 bytes
    return _transferAction.index(65, 32);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {IConnextHandler} from "../../interfaces/IConnextHandler.sol";
import {IStableSwap} from "../../interfaces/IStableSwap.sol";
import {IWrapped} from "../../interfaces/IWrapped.sol";
import {IExecutor} from "../../interfaces/IExecutor.sol";
import {LibCrossDomainProperty} from "../LibCrossDomainProperty.sol";
import {RouterPermissionsManagerInfo} from "./RouterPermissionsManagerLogic.sol";
import {AssetLogic} from "./AssetLogic.sol";

import {RelayerFeeRouter} from "../../nomad-xapps/contracts/relayer-fee-router/RelayerFeeRouter.sol";
import {ITokenRegistry, IBridgeToken} from "../../nomad-xapps/interfaces/bridge/ITokenRegistry.sol";
import {ConnextMessage} from "../../nomad-xapps/contracts/connext/ConnextMessage.sol";
import {TypedMemView} from "../../nomad-core/libs/TypedMemView.sol";
import {TypeCasts} from "../../nomad-core/contracts/XAppConnectionManager.sol";
import {Home} from "../../nomad-core/contracts/Home.sol";

import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {SafeERC20Upgradeable, AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

library ConnextLogic {
  // ============ Libraries ============
  using TypedMemView for bytes;
  using TypedMemView for bytes29;
  using ConnextMessage for bytes29;

  bytes32 internal constant EMPTY = hex"c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470";

  // ============ Errors ============

  error ConnextLogic__addAssetId_alreadyAdded();
  error ConnextLogic__removeAssetId_notAdded();
  error ConnextLogic__addRelayer_alreadyApproved();
  error ConnextLogic__removeRelayer_notApproved();
  error ConnextLogic__setMaxRoutersPerTransfer_invalidMaxRoutersPerTransfer();
  error ConnextLogic__reconcile_invalidAction();
  error ConnextLogic__reconcile_alreadyReconciled();
  error ConnextLogic__removeLiquidity_recipientEmpty();
  error ConnextLogic__removeLiquidity_amountIsZero();
  error ConnextLogic__removeLiquidity_insufficientFunds();
  error ConnextLogic__xcall_wrongDomain();
  error ConnextLogic__xcall_emptyTo();
  error ConnextLogic__xcall_notSupportedAsset();
  error ConnextLogic__xcall_relayerFeeIsZero();
  error ConnextLogic__execute_unapprovedRelayer();
  error ConnextLogic__execute_maxRoutersExceeded();
  error ConnextLogic__execute_alreadyExecuted();
  error ConnextLogic__execute_notSupportedRouter();
  error ConnextLogic__execute_invalidRouterSignature();
  error ConnextLogic__initiateClaim_notRelayer(bytes32 transferId);
  error ConnextLogic__bumpTransfer_invalidTransfer();
  error ConnextLogic__bumpTransfer_valueIsZero();

  // ============ Structs ============

  struct XCallLibArgs {
    IConnextHandler.XCallArgs xCallArgs;
    IWrapped wrapper;
    uint256 nonce;
    ITokenRegistry tokenRegistry;
    uint256 domain;
    Home home;
    bytes32 remote;
  }

  struct XCalledEventArgs {
    address transactingAssetId;
    uint256 amount;
    uint256 bridgedAmt;
    address bridged;
  }

  struct ExecuteLibArgs {
    IConnextHandler.ExecuteArgs executeArgs;
    bool isRouterOwnershipRenounced;
    uint256 maxRoutersPerTransfer;
    ITokenRegistry tokenRegistry;
    IWrapped wrapper;
    IExecutor executor;
    uint256 liquidityFeeNumerator;
    uint256 liquidityFeeDenominator;
  }

  // ============ Events ============

  /**
   * @notice Emitted when a new stable-swap AMM is added for the local <> adopted token
   * @param canonicalId - The canonical identifier of the token the local <> adopted AMM is for
   * @param domain - The domain of the canonical token for the local <> adopted amm
   * @param swapPool - The address of the AMM
   * @param caller - The account that called the function
   */
  event StableSwapAdded(bytes32 canonicalId, uint32 domain, address swapPool, address caller);

  /**
   * @notice Emitted when a new asset is added
   * @param canonicalId - The canonical identifier of the token the local <> adopted AMM is for
   * @param domain - The domain of the canonical token for the local <> adopted amm
   * @param adoptedAsset - The address of the adopted (user-expected) asset
   * @param supportedAsset - The address of the whitelisted asset. If the native asset is to be whitelisted,
   * the address of the wrapped version will be stored
   * @param caller - The account that called the function
   */
  event AssetAdded(bytes32 canonicalId, uint32 domain, address adoptedAsset, address supportedAsset, address caller);

  /**
   * @notice Emitted when an asset is removed from whitelists
   * @param canonicalId - The canonical identifier of the token removed
   * @param caller - The account that called the function
   */
  event AssetRemoved(bytes32 canonicalId, address caller);

  /**
   * @notice Emitted when a rlayer is added or removed from whitelists
   * @param relayer - The relayer address to be added or removed
   * @param caller - The account that called the function
   */
  event RelayerAdded(address relayer, address caller);

  /**
   * @notice Emitted when a rlayer is added or removed from whitelists
   * @param relayer - The relayer address to be added or removed
   * @param caller - The account that called the function
   */
  event RelayerRemoved(address relayer, address caller);

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
  event LiquidityAdded(address indexed router, address local, bytes32 canonicalId, uint256 amount, address caller);

  /**
   * @notice Emitted when the maxRoutersPerTransfer variable is updated
   * @param maxRoutersPerTransfer - The maxRoutersPerTransfer new value
   * @param caller - The account that called the function
   */
  event MaxRoutersPerTransferUpdated(uint256 maxRoutersPerTransfer, address caller);

  /**
   * @notice Emitted when `xcall` is called on the origin domain
   */
  event XCalled(
    bytes32 indexed transferId,
    IConnextHandler.XCallArgs xcallArgs,
    XCalledEventArgs args,
    uint256 nonce,
    bytes message,
    address caller
  );

  /**
   * @notice Emitted when `execute` is called on the destination chain
   * @dev `execute` may be called when providing fast liquidity *or* when processing a reconciled transfer
   * @param transferId - The unique identifier of the crosschain transfer
   * @param to - The CallParams.to provided, created as indexed parameter
   * @param args - The ExecuteArgs provided to the function
   * @param transactingAsset - The asset the to gets or the external call is executed with. Should be the
   * adopted asset on that chain.
   * @param transactingAmount - The amount of transferring asset the to address receives or the external call is
   * executed with
   * @param caller - The account that called the function
   */
  event Executed(
    bytes32 indexed transferId,
    address indexed to,
    IConnextHandler.ExecuteArgs args,
    address transactingAsset,
    uint256 transactingAmount,
    address caller
  );

  /**
   * @notice Emitted when `reconciled` is called by the bridge on the destination domain
   * @param transferId - The unique identifier of the crosschain transaction
   * @param origin - The origin domain of the transfer
   * @param routers - The CallParams.recipient provided, created as indexed parameter
   * @param asset - The asset that was provided by the bridge
   * @param amount - The amount that was provided by the bridge
   * @param caller - The account that called the function
   */
  event Reconciled(
    bytes32 indexed transferId,
    uint32 indexed origin,
    address[] routers,
    address asset,
    uint256 amount,
    address caller
  );

  /**
   * @notice Emitted when `bumpTransfer` is called by an user on the origin domain
   * @param transferId - The unique identifier of the crosschain transaction
   * @param relayerFee - The updated amount of relayer fee in native asset
   * @param caller - The account that called the function
   */
  event TransferRelayerFeesUpdated(bytes32 indexed transferId, uint256 relayerFee, address caller);

  /**
   * @notice Emitted when `initiateClaim` is called on the destination chain
   * @param domain - Domain to claim funds on
   * @param recipient - Address on origin chain to send claimed funds to
   * @param caller - The account that called the function
   * @param transferIds - TransferIds to claim
   */
  event InitiatedClaim(uint32 indexed domain, address indexed recipient, address caller, bytes32[] transferIds);

  /**
   * @notice Emitted when `claim` is called on the origin domain
   * @param recipient - Address on origin chain to send claimed funds to
   * @param total - Total amount claimed
   * @param transferIds - TransferIds to claim
   */
  event Claimed(address indexed recipient, uint256 total, bytes32[] transferIds);

  // ============ Admin Functions ============

  /**
   * @notice Used to add an AMM for adopted <> local assets
   * @param _canonical - The canonical TokenId to add (domain and id)
   * @param _stableSwap - The address of the amm to add
   */
  function addStableSwapPool(
    ConnextMessage.TokenId calldata _canonical,
    address _stableSwap,
    mapping(bytes32 => IStableSwap) storage _adoptedToLocalPools
  ) external {
    // Update the pool mapping
    _adoptedToLocalPools[_canonical.id] = IStableSwap(_stableSwap);

    emit StableSwapAdded(_canonical.id, _canonical.domain, _stableSwap, msg.sender);
  }

  /**
   * @notice Used to add assets on same chain as contract that can be transferred.
   * @param _canonical - The canonical TokenId to add (domain and id)
   * @param _adoptedAssetId - The used asset id for this domain (i.e. PoS USDC for
   * polygon)
   */
  function addAssetId(
    ConnextMessage.TokenId calldata _canonical,
    address _adoptedAssetId,
    address _wrapper,
    mapping(bytes32 => bool) storage _approvedAssets,
    mapping(address => ConnextMessage.TokenId) storage _adoptedToCanonical,
    mapping(bytes32 => address) storage _canonicalToAdopted
  ) external {
    // Sanity check: needs approval
    if (_approvedAssets[_canonical.id]) revert ConnextLogic__addAssetId_alreadyAdded();

    // Update approved assets mapping
    _approvedAssets[_canonical.id] = true;

    address supported = _adoptedAssetId == address(0) ? _wrapper : _adoptedAssetId;

    // Update the adopted mapping
    _adoptedToCanonical[supported] = _canonical;

    // Update the canonical mapping
    _canonicalToAdopted[_canonical.id] = supported;

    // Emit event
    emit AssetAdded(_canonical.id, _canonical.domain, _adoptedAssetId, supported, msg.sender);
  }

  /**
   * @notice Used to remove assets from the whitelist
   * @param _canonicalId - Token id to remove
   * @param _adoptedAssetId - Corresponding adopted asset to remove
   */
  function removeAssetId(
    bytes32 _canonicalId,
    address _adoptedAssetId,
    address _wrapper,
    mapping(bytes32 => bool) storage _approvedAssets,
    mapping(bytes32 => IStableSwap) storage _adoptedToLocalPools,
    mapping(address => ConnextMessage.TokenId) storage _adoptedToCanonical
  ) external {
    // Sanity check: already approval
    if (!_approvedAssets[_canonicalId]) revert ConnextLogic__removeAssetId_notAdded();

    // Update mapping
    delete _approvedAssets[_canonicalId];

    // Update pools
    delete _adoptedToLocalPools[_canonicalId];

    // Update adopted mapping
    delete _adoptedToCanonical[_adoptedAssetId == address(0) ? _wrapper : _adoptedAssetId];

    // Emit event
    emit AssetRemoved(_canonicalId, msg.sender);
  }

  /**
   * @notice Used to add approved relayer
   * @param _relayer - The relayer address to add
   */
  function addRelayer(address _relayer, mapping(address => bool) storage _approvedRelayers) external {
    if (_approvedRelayers[_relayer]) revert ConnextLogic__addRelayer_alreadyApproved();
    _approvedRelayers[_relayer] = true;

    emit RelayerAdded(_relayer, msg.sender);
  }

  /**
   * @notice Used to remove approved relayer
   * @param _relayer - The relayer address to remove
   */
  function removeRelayer(address _relayer, mapping(address => bool) storage _approvedRelayers) external {
    if (!_approvedRelayers[_relayer]) revert ConnextLogic__removeRelayer_notApproved();
    delete _approvedRelayers[_relayer];

    emit RelayerRemoved(_relayer, msg.sender);
  }

  /**
   * @notice Used to set the max amount of routers a payment can be routed through
   * @param _newMax The new max amount of routers
   */
  function setMaxRoutersPerTransfer(uint256 _newMax, uint256 _currentMax) external {
    if (_newMax == 0 || _newMax == _currentMax)
      revert ConnextLogic__setMaxRoutersPerTransfer_invalidMaxRoutersPerTransfer();

    emit MaxRoutersPerTransferUpdated(_newMax, msg.sender);
  }

  // ============ Functions ============

  /**
   * @notice Contains the logic to verify + increment a given routers liquidity
   * @dev The liquidity will be held in the local asset, which is the representation if you
   * are *not* on the canonical domain, and the canonical asset otherwise.
   * @param _amount - The amount of liquidity to add for the router
   * @param _local - The address of the nomad representation of the asset
   * @param _router - The router you are adding liquidity on behalf of
   * @param _canonicalId - Canonical asset id from the representation
   */
  function addLiquidityForRouter(
    uint256 _amount,
    address _local,
    address _router,
    mapping(address => mapping(address => uint256)) storage _routerBalances,
    bytes32 _canonicalId,
    IWrapped _wrapper
  ) external {
    // Transfer funds to contract
    (address asset, uint256 received) = AssetLogic.handleIncomingAsset(_local, _amount, 0, _wrapper);

    // Update the router balances. Happens after pulling funds to account for
    // the fee on transfer tokens
    _routerBalances[_router][asset] += received;

    // Emit event
    emit LiquidityAdded(_router, asset, _canonicalId, received, msg.sender);
  }

  /**
   * @notice This is used by any router to decrease their available liquidity for a given asset.
   * @param _amount - The amount of liquidity to remove for the router
   * @param _local - The address of the asset you're removing liquidity from. If removing liquidity of the
   * native asset, routers may use `address(0)` or the wrapped asset
   * @param _recipient The address that will receive the liquidity being removed
   */
  function removeLiquidity(
    uint256 _amount,
    address _local,
    address _recipient,
    mapping(address => mapping(address => uint256)) storage _routerBalances,
    IWrapped _wrapper
  ) external {
    // Sanity check: to is sensible
    if (_recipient == address(0)) revert ConnextLogic__removeLiquidity_recipientEmpty();

    // Sanity check: nonzero amounts
    if (_amount == 0) revert ConnextLogic__removeLiquidity_amountIsZero();

    uint256 routerBalance = _routerBalances[msg.sender][_local];
    // Sanity check: amount can be deducted for the router
    if (routerBalance < _amount) revert ConnextLogic__removeLiquidity_insufficientFunds();

    // Update router balances
    unchecked {
      _routerBalances[msg.sender][_local] = routerBalance - _amount;
    }

    // Transfer from contract to specified to
    AssetLogic.transferAssetFromContract(_local, _recipient, _amount, _wrapper);

    // Emit event
    emit LiquidityRemoved(msg.sender, _recipient, _local, _amount, msg.sender);
  }

  /**
   * @notice This function is called ConnextHandler when a user who is looking to bridge funds
   * @param _args - The XCallArgs
   * @param _adoptedToCanonical - Mapping of canonical to adopted assets on this domain
   * @param _adoptedToLocalPools - Mapping holding the AMMs for swapping in and out of local assets
   * @param _relayerFees - Mapping of relayer fee for a transfer
   * @return The transfer id of the crosschain transfer
   */
  function xcall(
    XCallLibArgs calldata _args,
    mapping(address => ConnextMessage.TokenId) storage _adoptedToCanonical,
    mapping(bytes32 => IStableSwap) storage _adoptedToLocalPools,
    mapping(bytes32 => uint256) storage _relayerFees
  ) external returns (bytes32, uint256) {
    _xcallSanityChecks(_args);

    // get the true transacting asset id (using wrapped native instead native)
    (bytes32 transferId, bytes memory message, XCalledEventArgs memory eventArgs) = _xcallProcess(
      _args,
      _adoptedToCanonical,
      _adoptedToLocalPools
    );

    // Store the relayer fee
    _relayerFees[transferId] = _args.xCallArgs.relayerFee;

    // emit event
    emit XCalled(transferId, _args.xCallArgs, eventArgs, _args.nonce, message, msg.sender);

    return (transferId, _args.nonce + 1);
  }

  /**
   * @notice Called via `handle` to manage funds associated with a transaction
   * @dev Will either (a) credit router or (b) make funds available for execution. Don't
   * include execution here
   */
  function reconcile(
    uint32 _origin,
    bytes memory _message,
    mapping(bytes32 => bool) storage _reconciledTransfers,
    ITokenRegistry _tokenRegistry,
    mapping(bytes32 => address[]) storage _routedTransfers,
    mapping(address => mapping(address => uint256)) storage _routerBalances
  ) external {
    // parse tokenId and action from message
    bytes29 msg_ = _message.ref(0).mustBeMessage();
    bytes29 tokenId = msg_.tokenId();
    bytes29 action = msg_.action();

    // assert the action is valid
    if (!action.isTransfer()) {
      revert ConnextLogic__reconcile_invalidAction();
    }

    // load the transferId
    bytes32 transferId = action.transferId();

    // ensure the transaction has not been handled
    if (_reconciledTransfers[transferId]) {
      revert ConnextLogic__reconcile_alreadyReconciled();
    }

    // get the token contract for the given tokenId on this chain
    // (if the token is of remote origin and there is
    // no existing representation token contract, the TokenRegistry will
    // deploy a new one)
    address token = _tokenRegistry.ensureLocalToken(tokenId.domain(), tokenId.id());

    // load amount once
    uint256 amount = action.amnt();

    // NOTE: tokenId + amount must be in plaintext in message so funds can
    // *only* be minted by `handle`. They are still used in the generation of
    // the transferId so routers must provide them correctly to be reimbursed

    // TODO: do we need to keep this
    bytes32 details = action.detailsHash();

    // if the token is of remote origin, mint the tokens. will either
    // - be credited to router (fast liquidity)
    // - be reserved for execution (slow liquidity)
    if (!_tokenRegistry.isLocalOrigin(token)) {
      IBridgeToken(token).mint(address(this), amount);
      // Tell the token what its detailsHash is
      IBridgeToken(token).setDetailsHash(details);
    }
    // NOTE: if the token is of local origin, it means it was escrowed
    // in this contract at xcall

    // mark the transfer as reconciled
    _reconciledTransfers[transferId] = true;

    // get the transfer
    address[] storage routers = _routedTransfers[transferId];

    uint256 pathLen = routers.length;
    if (pathLen != 0) {
      // fast liquidity path
      // credit the router the asset
      uint256 routerAmt = amount / pathLen;
      for (uint256 i; i < pathLen; ) {
        _routerBalances[routers[i]][token] += routerAmt;
        unchecked {
          i++;
        }
      }
    }

    emit Reconciled(transferId, _origin, routers, token, amount, msg.sender);
  }

  /**
   * @notice Called on the destination domain to disburse correct assets to end recipient
   * and execute any included calldata
   * @dev Can be called prior to or after `handle`, depending if fast liquidity is being
   * used.
   */
  function execute(
    ExecuteLibArgs calldata _args,
    mapping(bytes32 => address[]) storage _routedTransfers,
    mapping(bytes32 => bool) storage _reconciledTransfers,
    mapping(address => mapping(address => uint256)) storage _routerBalances,
    mapping(bytes32 => IStableSwap) storage _adoptedToLocalPools,
    mapping(bytes32 => address) storage _canonicalToAdopted,
    RouterPermissionsManagerInfo storage _routerInfo,
    mapping(bytes32 => address) storage _transferRelayer
  ) external returns (bytes32) {
    (bytes32 transferId, bool reconciled) = _executeSanityChecks(
      _args,
      _transferRelayer,
      _reconciledTransfers,
      _routerInfo.approvedRouters
    );

    // execute router liquidity when this is a fast transfer
    (uint256 amount, address adopted) = _handleExecuteLiquidity(
      transferId,
      !reconciled,
      _args,
      _routedTransfers,
      _routerBalances,
      _adoptedToLocalPools,
      _canonicalToAdopted
    );

    // execute the transaction
    _handleExecuteTransaction(_args, amount, adopted, transferId, reconciled);

    // Set the relayer for this transaction to allow for future claim
    _transferRelayer[transferId] = msg.sender;

    // emit event
    emit Executed(transferId, _args.executeArgs.params.to, _args.executeArgs, adopted, amount, msg.sender);

    return transferId;
  }

  /**
   * @notice Called by relayer when they want to claim owed funds on a given domain
   * @dev Domain should be the origin domain of all the transfer ids
   * @param _domain - domain to claim funds on
   * @param _recipient - address on origin chain to send claimed funds to
   * @param _transferIds - transferIds to claim
   * @param _relayerFeeRouter - The local nomad relayer fee router
   * @param _transferRelayer - Mapping of transactionIds to relayer
   */
  function initiateClaim(
    uint32 _domain,
    address _recipient,
    bytes32[] calldata _transferIds,
    RelayerFeeRouter _relayerFeeRouter,
    mapping(bytes32 => address) storage _transferRelayer
  ) external {
    // Ensure the relayer can claim all transfers specified
    for (uint256 i; i < _transferIds.length; ) {
      if (_transferRelayer[_transferIds[i]] != msg.sender)
        revert ConnextLogic__initiateClaim_notRelayer(_transferIds[i]);
      unchecked {
        i++;
      }
    }

    // Send transferIds via nomad
    _relayerFeeRouter.send(_domain, _recipient, _transferIds);

    emit InitiatedClaim(_domain, _recipient, msg.sender, _transferIds);
  }

  /**
   * @notice Pays out a relayer for the given fees
   * @dev Called by the RelayerFeeRouter.handle message. The validity of the transferIds is
   * asserted before dispatching the message.
   * @param _recipient - address on origin chain to send claimed funds to
   * @param _transferIds - transferIds to claim
   * @param _relayerFees - Mapping of transactionIds to fee
   */
  function claim(
    address _recipient,
    bytes32[] calldata _transferIds,
    mapping(bytes32 => uint256) storage _relayerFees
  ) external {
    // Tally amounts owed
    uint256 total;
    for (uint256 i; i < _transferIds.length; ) {
      total += _relayerFees[_transferIds[i]];
      _relayerFees[_transferIds[i]] = 0;
      unchecked {
        i++;
      }
    }

    AddressUpgradeable.sendValue(payable(_recipient), total);

    emit Claimed(_recipient, total, _transferIds);
  }

  /**
   * @notice Anyone can call this function on the origin domain to increase the relayer fee for a transfer.
   * @param _transferId - The unique identifier of the crosschain transaction
   */
  function bumpTransfer(bytes32 _transferId, mapping(bytes32 => uint256) storage relayerFees) external {
    if (msg.value == 0) revert ConnextLogic__bumpTransfer_valueIsZero();

    relayerFees[_transferId] += msg.value;

    emit TransferRelayerFeesUpdated(_transferId, relayerFees[_transferId], msg.sender);
  }

  // ============ Private Functions ============

  /**
   * @notice Performs some sanity checks for `execute`
   * @dev Need this to prevent stack too deep
   */
  function _executeSanityChecks(
    ExecuteLibArgs calldata _args,
    mapping(bytes32 => address) storage _transferRelayer,
    mapping(bytes32 => bool) storage _reconciledTransfers,
    mapping(address => bool) storage _approvedRouters
  ) private returns (bytes32, bool) {
    // get number of facilitating routers
    uint256 pathLength = _args.executeArgs.routers.length;

    // make sure number of routers is valid
    if (pathLength > _args.maxRoutersPerTransfer) revert ConnextLogic__execute_maxRoutersExceeded();

    // get transfer id
    bytes32 transferId = _getTransferId(_args);

    // get the payload the router should have signed
    bytes32 routerHash = keccak256(abi.encode(transferId, pathLength));

    // make sure routers are all approved if needed
    for (uint256 i; i < pathLength; ) {
      if (!_args.isRouterOwnershipRenounced && !_approvedRouters[_args.executeArgs.routers[i]]) {
        revert ConnextLogic__execute_notSupportedRouter();
      }
      if (_args.executeArgs.routers[i] != _recoverSignature(routerHash, _args.executeArgs.routerSignatures[i])) {
        revert ConnextLogic__execute_invalidRouterSignature();
      }
      unchecked {
        i++;
      }
    }

    // require this transfer has not already been executed
    if (_transferRelayer[transferId] != address(0)) {
      revert ConnextLogic__execute_alreadyExecuted();
    }

    // get reconciled record
    bool reconciled = _reconciledTransfers[transferId];

    return (transferId, reconciled);
  }

  /**
   * @notice Calculates fast transfer amount.
   * @param _amount Transfer amount
   * @param _liquidityFeeNum Liquidity fee numerator
   * @param _liquidityFeeDen Liquidity fee denominator
   */
  function _getFastTransferAmount(
    uint256 _amount,
    uint256 _liquidityFeeNum,
    uint256 _liquidityFeeDen
  ) private pure returns (uint256) {
    return (_amount * _liquidityFeeNum) / _liquidityFeeDen;
  }

  /**
   * @notice Performs some sanity checks for `xcall`
   * @dev Need this to prevent stack too deep
   */
  function _xcallSanityChecks(XCallLibArgs calldata _args) private {
    // ensure this is the right domain
    if (_args.xCallArgs.params.originDomain != _args.domain) {
      revert ConnextLogic__xcall_wrongDomain();
    }

    // ensure theres a recipient defined
    if (_args.xCallArgs.params.to == address(0)) {
      revert ConnextLogic__xcall_emptyTo();
    }
  }

  /**
   * @notice Processes an `xcall`
   * @dev Need this to prevent stack too deep
   */
  function _xcallProcess(
    XCallLibArgs calldata _args,
    mapping(address => ConnextMessage.TokenId) storage _adoptedToCanonical,
    mapping(bytes32 => IStableSwap) storage _adoptedToLocalPools
  )
    private
    returns (
      bytes32,
      bytes memory,
      XCalledEventArgs memory
    )
  {
    address transactingAssetId = _args.xCallArgs.transactingAssetId == address(0)
      ? address(_args.wrapper)
      : _args.xCallArgs.transactingAssetId;

    // check that the asset is supported -- can be either adopted or local
    ConnextMessage.TokenId memory canonical = _adoptedToCanonical[transactingAssetId];
    if (canonical.id == bytes32(0)) {
      revert ConnextLogic__xcall_notSupportedAsset();
    }

    // transfer funds of transacting asset to the contract from user
    // NOTE: will wrap any native asset transferred to wrapped-native automatically
    (, uint256 amount) = AssetLogic.handleIncomingAsset(
      _args.xCallArgs.transactingAssetId,
      _args.xCallArgs.amount,
      _args.xCallArgs.relayerFee,
      _args.wrapper
    );

    // swap to the local asset from adopted
    (uint256 bridgedAmt, address bridged) = AssetLogic.swapToLocalAssetIfNeeded(
      canonical,
      _adoptedToLocalPools[canonical.id],
      _args.tokenRegistry,
      transactingAssetId,
      amount
    );

    bytes32 transferId = _getTransferId(_args, canonical);

    bytes memory message = _formatMessage(_args, bridged, transferId, bridgedAmt);
    _args.home.dispatch(_args.xCallArgs.params.destinationDomain, _args.remote, message);

    return (
      transferId,
      message,
      XCalledEventArgs({
        transactingAssetId: transactingAssetId,
        amount: amount,
        bridgedAmt: bridgedAmt,
        bridged: bridged
      })
    );
  }

  /**
   * @notice Calculates a transferId based on `execute` arguments
   * @dev Need this to prevent stack too deep
   */
  function _getTransferId(ExecuteLibArgs calldata _args) private view returns (bytes32) {
    (uint32 tokenDomain, bytes32 tokenId) = _args.tokenRegistry.getTokenId(_args.executeArgs.local);

    return
      keccak256(
        abi.encode(
          _args.executeArgs.nonce,
          _args.executeArgs.params,
          _args.executeArgs.originSender,
          tokenId,
          tokenDomain,
          _args.executeArgs.amount
        )
      );
  }

  /**
   * @notice Calculates a transferId based on `xcall` arguments
   * @dev Need this to prevent stack too deep
   */
  function _getTransferId(XCallLibArgs calldata _args, ConnextMessage.TokenId memory _canonical)
    private
    view
    returns (bytes32)
  {
    return
      keccak256(
        abi.encode(
          _args.nonce,
          _args.xCallArgs.params,
          msg.sender,
          _canonical.id,
          _canonical.domain,
          _args.xCallArgs.amount
        )
      );
  }

  /**
   * @notice Formats a nomad message generated by `xcall`
   * @dev Need this to prevent stack too deep
   */
  function _formatMessage(
    XCallLibArgs calldata _args,
    address _asset,
    bytes32 _transferId,
    uint256 _amount
  ) private returns (bytes memory) {
    // get token
    IBridgeToken token = IBridgeToken(_asset);

    // declare details
    bytes32 detailsHash;

    if (_args.tokenRegistry.isLocalOrigin(_asset)) {
      // TODO: do we want to store a mapping of custodied token balances here?

      // token is local, custody token on this chain
      // query token contract for details and calculate detailsHash
      detailsHash = ConnextMessage.formatDetailsHash(token.name(), token.symbol(), token.decimals());
    } else {
      // if the token originates on a remote chain,
      // burn the representation tokens on this chain
      if (_amount > 0) {
        token.burn(msg.sender, _amount);
      }
      detailsHash = token.detailsHash();
    }

    // format action
    bytes29 action = ConnextMessage.formatTransfer(
      TypeCasts.addressToBytes32(_args.xCallArgs.params.to),
      _amount,
      detailsHash,
      _transferId
    );

    // get the tokenID
    (uint32 domain, bytes32 id) = _args.tokenRegistry.getTokenId(_asset);

    // format token id
    bytes29 tokenId = ConnextMessage.formatTokenId(domain, id);

    // send message
    return ConnextMessage.formatMessage(tokenId, action);
  }

  /**
   * @notice Process the transfer, and calldata if needed, when calling `execute`
   * @dev Need this to prevent stack too deep
   */
  function _handleExecuteTransaction(
    ExecuteLibArgs calldata _args,
    uint256 _amount,
    address _adopted,
    bytes32 _transferId,
    bool _reconciled
  ) private {
    // execute the the transaction
    if (keccak256(_args.executeArgs.params.callData) == EMPTY) {
      // no call data, send funds to the user
      AssetLogic.transferAssetFromContract(_adopted, _args.executeArgs.params.to, _amount, _args.wrapper);
    } else {
      // execute calldata w/funds
      AssetLogic.transferAssetFromContract(_adopted, address(_args.executor), _amount, _args.wrapper);
      _args.executor.execute(
        _transferId,
        _amount,
        payable(_args.executeArgs.params.to),
        _adopted,
        _reconciled
          ? LibCrossDomainProperty.formatDomainAndSenderBytes(
            _args.executeArgs.params.originDomain,
            _args.executeArgs.originSender
          )
          : LibCrossDomainProperty.EMPTY_BYTES,
        _args.executeArgs.params.callData
      );
    }
  }

  /**
   * @notice Execute liquidity process used when calling `execute`
   * @dev Need this to prevent stack too deep
   */
  function _handleExecuteLiquidity(
    bytes32 _transferId,
    bool _isFast,
    ExecuteLibArgs calldata _args,
    mapping(bytes32 => address[]) storage _routedTransfers,
    mapping(address => mapping(address => uint256)) storage _routerBalances,
    mapping(bytes32 => IStableSwap) storage _adoptedToLocalPools,
    mapping(bytes32 => address) storage _canonicalToAdopted
  ) private returns (uint256, address) {
    uint256 toSwap = _args.executeArgs.amount;
    uint256 pathLen = _args.executeArgs.routers.length;
    if (_isFast) {
      // this is the fast liquidity path
      // ensure the router is whitelisted

      // calculate amount with fast liquidity fee
      toSwap = _getFastTransferAmount(
        _args.executeArgs.amount,
        _args.liquidityFeeNumerator,
        _args.liquidityFeeDenominator
      );

      // TODO: validate routers signature on path / transferId

      // store the routers address
      _routedTransfers[_transferId] = _args.executeArgs.routers;

      // for each router, assert they are approved, and deduct liquidity
      uint256 routerAmount = toSwap / pathLen;
      for (uint256 i; i < pathLen; ) {
        // decrement routers liquidity
        _routerBalances[_args.executeArgs.routers[i]][_args.executeArgs.local] -= routerAmount;

        unchecked {
          i++;
        }
      }
    }

    // swap out of mad* asset into adopted asset if needed
    return
      AssetLogic.swapFromLocalAssetIfNeeded(
        _canonicalToAdopted,
        _adoptedToLocalPools,
        _args.tokenRegistry,
        _args.executeArgs.local,
        toSwap
      );
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
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import {IBridgeToken} from "./IBridgeToken.sol";

// ============ External Imports ============
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITokenRegistry {
  function isLocalOrigin(address _token) external view returns (bool);

  function ensureLocalToken(uint32 _domain, bytes32 _id) external returns (address _local);

  function mustHaveLocalToken(uint32 _domain, bytes32 _id) external view returns (IERC20);

  function getLocalAddress(uint32 _domain, bytes32 _id) external view returns (address _local);

  function getTokenId(address _token) external view returns (uint32, bytes32);

  function enrollCustom(
    uint32 _domain,
    bytes32 _id,
    address _custom
  ) external;

  function oldReprToCurrentRepr(address _oldRepr) external view returns (address _currentRepr);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

// TODO: need a correct interface here
interface IWrapped {
  function deposit() external payable;

  function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "../nomad-xapps/contracts/connext/ConnextMessage.sol";

interface IConnextHandler {
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
   */
  struct CallParams {
    address to;
    bytes callData;
    uint32 originDomain;
    uint32 destinationDomain;
  }

  /**
   * @notice The arguments you supply to the `xcall` function called by user on origin domain
   * @param params - The CallParams. These are consistent across sending and receiving chains
   * @param transactingAssetId - The asset the caller sent with the transfer. Can be the adopted, canonical,
   * or the representational asset
   * @param amount - The amount of transferring asset the tx called xcall with
   * @param relayerFee - The amount of relayer fee the tx called xcall with
   */
  struct XCallArgs {
    CallParams params;
    address transactingAssetId; // Could be adopted, local, or wrapped
    uint256 amount;
    uint256 relayerFee;
  }

  /**
   * @notice
   * @param params - The CallParams. These are consistent across sending and receiving chains
   * @param local - The local asset for the transfer, will be swapped to the adopted asset if
   * appropriate
   * @param routers - The routers who you are sending the funds on behalf of
   * @param amount - The amount of liquidity the router provided or the bridge forwarded, depending on
   * if fast liquidity was used
   * @param nonce - The nonce used to generate transfer id
   * @param originSender - The msg.sender of the xcall on origin domain
   */
  struct ExecuteArgs {
    CallParams params;
    address local; // local representation of canonical token
    address[] routers;
    bytes[] routerSignatures;
    uint256 amount;
    uint256 nonce;
    address originSender;
  }

  // ============ Admin Functions ============

  function initialize(
    uint256 _domain,
    address _xAppConnectionManager,
    address _tokenRegistry, // Nomad token registry
    address _wrappedNative,
    address _relayerFeeRouter
  ) external;

  function setupRouter(
    address router,
    address owner,
    address recipient
  ) external;

  function removeRouter(address router) external;

  function addStableSwapPool(ConnextMessage.TokenId calldata canonical, address stableSwapPool) external;

  function setupAsset(
    ConnextMessage.TokenId calldata canonical,
    address adoptedAssetId,
    address stableSwapPool
  ) external;

  function removeAssetId(bytes32 canonicalId, address adoptedAssetId) external;

  function setMaxRoutersPerTransfer(uint256 newMaxRouters) external;

  function addRelayer(address relayer) external;

  function removeRelayer(address relayer) external;

  // ============ Public Functions ===========

  function addLiquidityFor(
    uint256 amount,
    address local,
    address router
  ) external payable;

  function addLiquidity(uint256 amount, address local) external payable;

  function removeLiquidity(
    uint256 amount,
    address local,
    address payable to
  ) external;

  function xcall(XCallArgs calldata _args) external payable returns (bytes32);

  function execute(ExecuteArgs calldata _args) external returns (bytes32);

  function initiateClaim(
    uint32 _domain,
    address _recipient,
    bytes32[] calldata _transferIds
  ) external;

  function claim(address _recipient, bytes32[] calldata _transferIds) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

interface IExecutor {
  event Executed(
    bytes32 indexed transferId,
    address indexed to,
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

  function execute(
    bytes32 _transferId,
    uint256 _amount,
    address payable _to,
    address _assetId,
    bytes memory _properties,
    bytes calldata _callData
  ) external payable returns (bool success, bytes memory returnData);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStableSwap {
  /*** EVENTS ***/

  // events replicated from SwapUtils to make the ABI easier for dumb
  // clients
  event TokenSwap(address indexed buyer, uint256 tokensSold, uint256 tokensBought, uint128 soldId, uint128 boughtId);
  event AddLiquidity(
    address indexed provider,
    uint256[] tokenAmounts,
    uint256[] fees,
    uint256 invariant,
    uint256 lpTokenSupply
  );
  event RemoveLiquidity(address indexed provider, uint256[] tokenAmounts, uint256 lpTokenSupply);
  event RemoveLiquidityOne(
    address indexed provider,
    uint256 lpTokenAmount,
    uint256 lpTokenSupply,
    uint256 boughtId,
    uint256 tokensBought
  );
  event RemoveLiquidityImbalance(
    address indexed provider,
    uint256[] tokenAmounts,
    uint256[] fees,
    uint256 invariant,
    uint256 lpTokenSupply
  );
  event NewAdminFee(uint256 newAdminFee);
  event NewSwapFee(uint256 newSwapFee);
  event NewWithdrawFee(uint256 newWithdrawFee);
  event RampA(uint256 oldA, uint256 newA, uint256 initialTime, uint256 futureTime);
  event StopRampA(uint256 currentA, uint256 time);

  function swapExact(
    uint256 amountIn,
    address assetIn,
    address assetOut
  ) external payable returns (uint256);

  function getA() external view returns (uint256);

  function getToken(uint8 index) external view returns (IERC20);

  function getTokenIndex(address tokenAddress) external view returns (uint8);

  function getTokenBalance(uint8 index) external view returns (uint256);

  function getVirtualPrice() external view returns (uint256);

  // min return calculation functions
  function calculateSwap(
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx
  ) external view returns (uint256);

  function calculateTokenAmount(uint256[] calldata amounts, bool deposit) external view returns (uint256);

  function calculateRemoveLiquidity(uint256 amount) external view returns (uint256[] memory);

  function calculateRemoveLiquidityOneToken(uint256 tokenAmount, uint8 tokenIndex)
    external
    view
    returns (uint256 availableTokenAmount);

  // state modifying functions
  function initialize(
    IERC20[] memory pooledTokens,
    uint8[] memory decimals,
    string memory lpTokenName,
    string memory lpTokenSymbol,
    uint256 a,
    uint256 fee,
    uint256 adminFee,
    address lpTokenTargetAddress
  ) external;

  function swap(
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx,
    uint256 minDy,
    uint256 deadline
  ) external returns (uint256);

  function addLiquidity(
    uint256[] calldata amounts,
    uint256 minToMint,
    uint256 deadline
  ) external returns (uint256);

  function removeLiquidity(
    uint256 amount,
    uint256[] calldata minAmounts,
    uint256 deadline
  ) external returns (uint256[] memory);

  function removeLiquidityOneToken(
    uint256 tokenAmount,
    uint8 tokenIndex,
    uint256 minAmount,
    uint256 deadline
  ) external returns (uint256);

  function removeLiquidityImbalance(
    uint256[] calldata amounts,
    uint256 maxBurnAmount,
    uint256 deadline
  ) external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {IExecutor} from "../interfaces/IExecutor.sol";

import {LibCrossDomainProperty, TypedMemView} from "../lib/LibCrossDomainProperty.sol";

import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {SafeERC20Upgradeable, IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @title Executor
 * @author Connext <[email protected]>
 * @notice This library contains an `execute` function that is callabale by
 * an associated Connext contract. This is used to execute
 * arbitrary calldata on a receiving chain.
 */
contract Executor is IExecutor {
  // ============ Libraries =============

  using TypedMemView for bytes29;
  using TypedMemView for bytes;

  // ============ Properties =============

  address private immutable connext;
  bytes private properties = LibCrossDomainProperty.EMPTY_BYTES;

  // ============ Constructor =============

  constructor(address _connext) {
    connext = _connext;
  }

  // ============ Modifiers =============

  /**
   * @notice Errors if the sender is not Connext
   */
  modifier onlyConnext() {
    require(msg.sender == connext, "#OC:027");
    _;
  }

  // ============ Public Functions =============

  /**
   * @notice Returns the connext contract address (only address that can
   * call the `execute` function)
   * @return The address of the associated connext contract
   */
  function getConnext() external view override returns (address) {
    return connext;
  }

  /**
   * @notice Allows a `_to` contract to access origin domain sender (i.e. msg.sender of `xcall`)
   * @dev These properties are set via reentrancy a la L2CrossDomainMessenger from
   * optimism
   */
  function originSender() external view override returns (address) {
    // The following will revert if it is empty
    bytes29 _parsed = LibCrossDomainProperty.parseDomainAndSenderBytes(properties);
    return LibCrossDomainProperty.sender(_parsed);
  }

  /**
   * @notice Allows a `_to` contract to access origin domain (i.e. domain of `xcall`)
   * @dev These properties are set via reentrancy a la L2CrossDomainMessenger from
   * optimism
   */
  function origin() external view override returns (uint32) {
    // The following will revert if it is empty
    bytes29 _parsed = LibCrossDomainProperty.parseDomainAndSenderBytes(properties);
    return LibCrossDomainProperty.domain(_parsed);
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
   * @param _properties The origin properties
   * @param _callData The data to execute
   */
  function execute(
    bytes32 _transferId,
    uint256 _amount,
    address payable _to,
    address _assetId,
    bytes memory _properties,
    bytes calldata _callData
  ) external payable override onlyConnext returns (bool, bytes memory) {
    // If it is not ether, approve the callTo
    // We approve here rather than transfer since many external contracts
    // simply require an approval, and it is unclear if they can handle
    // funds transferred directly to them (i.e. Uniswap)
    bool isNative = _assetId == address(0);
    if (!isNative) {
      SafeERC20Upgradeable.safeIncreaseAllowance(IERC20Upgradeable(_assetId), _to, _amount);
    }

    // Check if the callTo is a contract
    bool success;
    bytes memory returnData;
    require(AddressUpgradeable.isContract(_to), "!contract");

    // If it should set the properties, set them.
    // NOTE: safe to set the properties always because modifier will revert if
    // it is the wrong type on conversion, and revert occurs with empty type as
    // well
    properties = _properties;

    // Try to execute the callData
    // the low level call will return `false` if its execution reverts
    (success, returnData) = _to.call{value: isNative ? _amount : 0}(_callData);

    // Unset properties
    properties = LibCrossDomainProperty.EMPTY_BYTES;

    // Handle failure cases
    if (!success && !isNative) {
      // Decrease allowance
      SafeERC20Upgradeable.safeDecreaseAllowance(IERC20Upgradeable(_assetId), _to, _amount);
    }

    // Emit event
    emit Executed(_transferId, _to, _assetId, _amount, _properties, _callData, returnData, success);
    return (success, returnData);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {RouterPermissionsManagerLogic, RouterPermissionsManagerInfo} from "./lib/Connext/RouterPermissionsManagerLogic.sol";

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

  // ============ Public storage =============

  RouterPermissionsManagerInfo internal routerInfo;

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

  // ============ Public methods ==============

  /**
   * @notice Returns the approved router for the given router address
   * @param _router The relevant router address
   */
  function getRouterApproval(address _router) public view returns (bool) {
    return routerInfo.approvedRouters[_router];
  }

  /**
   * @notice Returns the recipient for the specified router
   * @dev The recipient (if set) receives all funds when router liquidity is removed
   * @param _router The relevant router address
   */
  function getRouterRecipient(address _router) public view returns (address) {
    return routerInfo.routerRecipients[_router];
  }

  /**
   * @notice Returns the router owner if it is set, or the router itself if not
   * @dev Uses logic function here to handle the case where router owner is not set.
   * Other getters within this interface use explicitly the stored value
   * @param _router The relevant router address
   */
  function getRouterOwner(address _router) public view returns (address) {
    return RouterPermissionsManagerLogic.getRouterOwner(_router, routerInfo.routerOwners);
  }

  /**
   * @notice Returns the currently proposed router owner
   * @dev All routers must wait for the delay timeout before accepting a new owner
   * @param _router The relevant router address
   */
  function getProposedRouterOwner(address _router) public view returns (address) {
    return routerInfo.proposedRouterOwners[_router];
  }

  /**
   * @notice Returns the currently proposed router owner timestamp
   * @dev All routers must wait for the delay timeout before accepting a new owner
   * @param _router The relevant router address
   */
  function getProposedRouterOwnerTimestamp(address _router) public view returns (uint256) {
    return routerInfo.proposedRouterTimestamp[_router];
  }

  /**
   * @notice Sets the designated recipient for a router
   * @dev Router should only be able to set this once otherwise if router key compromised,
   * no problem is solved since attacker could just update recipient
   * @param router Router address to set recipient
   * @param recipient Recipient Address to set to router
   */
  function setRouterRecipient(address router, address recipient) external {
    RouterPermissionsManagerLogic.setRouterRecipient(router, recipient, routerInfo);
  }

  /**
   * @notice Current owner or router may propose a new router owner
   * @param router Router address to set recipient
   * @param proposed Proposed owner Address to set to router
   */
  function proposeRouterOwner(address router, address proposed) external {
    RouterPermissionsManagerLogic.proposeRouterOwner(router, proposed, routerInfo);
  }

  /**
   * @notice New router owner must accept role, or previous if proposed is 0x0
   * @param router Router address to set recipient
   */
  function acceptProposedRouterOwner(address router) external {
    RouterPermissionsManagerLogic.acceptProposedRouterOwner(router, _delay, routerInfo);
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
    RouterPermissionsManagerLogic.setupRouter(router, owner, recipient, routerInfo);
  }

  /**
   * @notice Used to remove routers that can transact crosschain
   * @param router Router address to remove
   */
  function _removeRouter(address router) internal {
    RouterPermissionsManagerLogic.removeRouter(router, routerInfo);
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

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

/**
 * @title Version0
 * @notice Version getter for contracts
 **/
contract Version0 {
  uint8 public constant VERSION = 0;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import {Message} from "../libs/Message.sol";
// ============ External Imports ============
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title NomadBase
 * @author Illusory Systems Inc.
 * @notice Shared utilities between Home and Replica.
 */
abstract contract NomadBase is Initializable, OwnableUpgradeable {
  // ============ Enums ============

  // States:
  //   0 - UnInitialized - before initialize function is called
  //   note: the contract is initialized at deploy time, so it should never be in this state
  //   1 - Active - as long as the contract has not become fraudulent
  //   2 - Failed - after a valid fraud proof has been submitted;
  //   contract will no longer accept updates or new messages
  enum States {
    UnInitialized,
    Active,
    Failed
  }

  // ============ Immutable Variables ============

  // Domain of chain on which the contract is deployed
  uint32 public immutable localDomain;

  // ============ Public Variables ============

  // Address of bonded Updater
  address public updater;
  // Current state of contract
  States public state;
  // The latest root that has been signed by the Updater
  bytes32 public committedRoot;

  // ============ Upgrade Gap ============

  // gap for upgrade safety
  uint256[47] private __GAP;

  // ============ Events ============

  /**
   * @notice Emitted when update is made on Home
   * or unconfirmed update root is submitted on Replica
   * @param homeDomain Domain of home contract
   * @param oldRoot Old merkle root
   * @param newRoot New merkle root
   * @param signature Updater's signature on `oldRoot` and `newRoot`
   */
  event Update(uint32 indexed homeDomain, bytes32 indexed oldRoot, bytes32 indexed newRoot, bytes signature);

  /**
   * @notice Emitted when proof of a double update is submitted,
   * which sets the contract to FAILED state
   * @param oldRoot Old root shared between two conflicting updates
   * @param newRoot Array containing two conflicting new roots
   * @param signature Signature on `oldRoot` and `newRoot`[0]
   * @param signature2 Signature on `oldRoot` and `newRoot`[1]
   */
  event DoubleUpdate(bytes32 oldRoot, bytes32[2] newRoot, bytes signature, bytes signature2);

  /**
   * @notice Emitted when Updater is rotated
   * @param oldUpdater The address of the old updater
   * @param newUpdater The address of the new updater
   */
  event NewUpdater(address oldUpdater, address newUpdater);

  // ============ Modifiers ============

  /**
   * @notice Ensures that contract state != FAILED when the function is called
   */
  modifier notFailed() {
    require(state != States.Failed, "failed state");
    _;
  }

  // ============ Constructor ============

  constructor(uint32 _localDomain) {
    localDomain = _localDomain;
  }

  // ============ Initializer ============

  function __NomadBase_initialize(address _updater) internal initializer {
    __Ownable_init();
    _setUpdater(_updater);
    state = States.Active;
  }

  // ============ External Functions ============

  /**
   * @notice Called by external agent. Checks that signatures on two sets of
   * roots are valid and that the new roots conflict with each other. If both
   * cases hold true, the contract is failed and a `DoubleUpdate` event is
   * emitted.
   * @dev When `fail()` is called on Home, updater is slashed.
   * @param _oldRoot Old root shared between two conflicting updates
   * @param _newRoot Array containing two conflicting new roots
   * @param _signature Signature on `_oldRoot` and `_newRoot`[0]
   * @param _signature2 Signature on `_oldRoot` and `_newRoot`[1]
   */
  function doubleUpdate(
    bytes32 _oldRoot,
    bytes32[2] calldata _newRoot,
    bytes calldata _signature,
    bytes calldata _signature2
  ) external notFailed {
    if (
      NomadBase._isUpdaterSignature(_oldRoot, _newRoot[0], _signature) &&
      NomadBase._isUpdaterSignature(_oldRoot, _newRoot[1], _signature2) &&
      _newRoot[0] != _newRoot[1]
    ) {
      _fail();
      emit DoubleUpdate(_oldRoot, _newRoot, _signature, _signature2);
    }
  }

  // ============ Public Functions ============

  /**
   * @notice Hash of Home domain concatenated with "NOMAD"
   */
  function homeDomainHash() public view virtual returns (bytes32);

  // ============ Internal Functions ============

  /**
   * @notice Hash of Home domain concatenated with "NOMAD"
   * @param _homeDomain the Home domain to hash
   */
  function _homeDomainHash(uint32 _homeDomain) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_homeDomain, "NOMAD"));
  }

  /**
   * @notice Set contract state to FAILED
   * @dev Called when a valid fraud proof is submitted
   */
  function _setFailed() internal {
    state = States.Failed;
  }

  /**
   * @notice Moves the contract into failed state
   * @dev Called when fraud is proven
   * (Double Update is submitted on Home or Replica,
   * or Improper Update is submitted on Home)
   */
  function _fail() internal virtual;

  /**
   * @notice Set the Updater
   * @param _newUpdater Address of the new Updater
   */
  function _setUpdater(address _newUpdater) internal {
    address _oldUpdater = updater;
    updater = _newUpdater;
    emit NewUpdater(_oldUpdater, _newUpdater);
  }

  /**
   * @notice Checks that signature was signed by Updater
   * @param _oldRoot Old merkle root
   * @param _newRoot New merkle root
   * @param _signature Signature on `_oldRoot` and `_newRoot`
   * @return TRUE iff signature is valid signed by updater
   **/
  function _isUpdaterSignature(
    bytes32 _oldRoot,
    bytes32 _newRoot,
    bytes memory _signature
  ) internal view returns (bool) {
    bytes32 _digest = keccak256(abi.encodePacked(homeDomainHash(), _oldRoot, _newRoot));
    _digest = ECDSA.toEthSignedMessageHash(_digest);
    return (ECDSA.recover(_digest, _signature) == updater);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

/**
 * @title QueueLib
 * @author Illusory Systems Inc.
 * @notice Library containing queue struct and operations for queue used by
 * Home and Replica.
 **/
library QueueLib {
  /**
   * @notice Queue struct
   * @dev Internally keeps track of the `first` and `last` elements through
   * indices and a mapping of indices to enqueued elements.
   **/
  struct Queue {
    uint128 first;
    uint128 last;
    mapping(uint256 => bytes32) queue;
  }

  /**
   * @notice Initializes the queue
   * @dev Empty state denoted by _q.first > q._last. Queue initialized
   * with _q.first = 1 and _q.last = 0.
   **/
  function initialize(Queue storage _q) internal {
    if (_q.first == 0) {
      _q.first = 1;
    }
  }

  /**
   * @notice Enqueues a single new element
   * @param _item New element to be enqueued
   * @return _last Index of newly enqueued element
   **/
  function enqueue(Queue storage _q, bytes32 _item) internal returns (uint128 _last) {
    _last = _q.last + 1;
    _q.last = _last;
    if (_item != bytes32(0)) {
      // saves gas if we're queueing 0
      _q.queue[_last] = _item;
    }
  }

  /**
   * @notice Dequeues element at front of queue
   * @dev Removes dequeued element from storage
   * @return _item Dequeued element
   **/
  function dequeue(Queue storage _q) internal returns (bytes32 _item) {
    uint128 _last = _q.last;
    uint128 _first = _q.first;
    require(_length(_last, _first) != 0, "Empty");
    _item = _q.queue[_first];
    if (_item != bytes32(0)) {
      // saves gas if we're dequeuing 0
      delete _q.queue[_first];
    }
    _q.first = _first + 1;
  }

  /**
   * @notice Batch enqueues several elements
   * @param _items Array of elements to be enqueued
   * @return _last Index of last enqueued element
   **/
  function enqueue(Queue storage _q, bytes32[] memory _items) internal returns (uint128 _last) {
    _last = _q.last;
    for (uint256 i = 0; i < _items.length; i += 1) {
      _last += 1;
      bytes32 _item = _items[i];
      if (_item != bytes32(0)) {
        _q.queue[_last] = _item;
      }
    }
    _q.last = _last;
  }

  /**
   * @notice Batch dequeues `_number` elements
   * @dev Reverts if `_number` > queue length
   * @param _number Number of elements to dequeue
   * @return Array of dequeued elements
   **/
  function dequeue(Queue storage _q, uint256 _number) internal returns (bytes32[] memory) {
    uint128 _last = _q.last;
    uint128 _first = _q.first;
    // Cannot underflow unless state is corrupted
    require(_length(_last, _first) >= _number, "Insufficient");

    bytes32[] memory _items = new bytes32[](_number);

    for (uint256 i = 0; i < _number; i++) {
      _items[i] = _q.queue[_first];
      delete _q.queue[_first];
      _first++;
    }
    _q.first = _first;
    return _items;
  }

  /**
   * @notice Returns true if `_item` is in the queue and false if otherwise
   * @dev Linearly scans from _q.first to _q.last looking for `_item`
   * @param _item Item being searched for in queue
   * @return True if `_item` currently exists in queue, false if otherwise
   **/
  function contains(Queue storage _q, bytes32 _item) internal view returns (bool) {
    for (uint256 i = _q.first; i <= _q.last; i++) {
      if (_q.queue[i] == _item) {
        return true;
      }
    }
    return false;
  }

  /// @notice Returns last item in queue
  /// @dev Returns bytes32(0) if queue empty
  function lastItem(Queue storage _q) internal view returns (bytes32) {
    return _q.queue[_q.last];
  }

  /// @notice Returns element at front of queue without removing element
  /// @dev Reverts if queue is empty
  function peek(Queue storage _q) internal view returns (bytes32 _item) {
    require(!isEmpty(_q), "Empty");
    _item = _q.queue[_q.first];
  }

  /// @notice Returns true if queue is empty and false if otherwise
  function isEmpty(Queue storage _q) internal view returns (bool) {
    return _q.last < _q.first;
  }

  /// @notice Returns number of elements in queue
  function length(Queue storage _q) internal view returns (uint256) {
    uint128 _last = _q.last;
    uint128 _first = _q.first;
    // Cannot underflow unless state is corrupted
    return _length(_last, _first);
  }

  /// @notice Returns number of elements between `_last` and `_first` (used internally)
  function _length(uint128 _last, uint128 _first) internal pure returns (uint256) {
    return uint256(_last + 1 - _first);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// work based on eth2 deposit contract, which is used under CC0-1.0

/**
 * @title MerkleLib
 * @author Illusory Systems Inc.
 * @notice An incremental merkle tree modeled on the eth2 deposit contract.
 **/
library MerkleLib {
  uint256 internal constant TREE_DEPTH = 32;
  uint256 internal constant MAX_LEAVES = 2**TREE_DEPTH - 1;

  /**
   * @notice Struct representing incremental merkle tree. Contains current
   * branch and the number of inserted leaves in the tree.
   **/
  struct Tree {
    bytes32[TREE_DEPTH] branch;
    uint256 count;
  }

  /**
   * @notice Inserts `_node` into merkle tree
   * @dev Reverts if tree is full
   * @param _node Element to insert into tree
   **/
  function insert(Tree storage _tree, bytes32 _node) internal {
    require(_tree.count < MAX_LEAVES, "merkle tree full");

    _tree.count += 1;
    uint256 size = _tree.count;
    for (uint256 i = 0; i < TREE_DEPTH; i++) {
      if ((size & 1) == 1) {
        _tree.branch[i] = _node;
        return;
      }
      _node = keccak256(abi.encodePacked(_tree.branch[i], _node));
      size /= 2;
    }
    // As the loop should always end prematurely with the `return` statement,
    // this code should be unreachable. We assert `false` just to be safe.
    assert(false);
  }

  /**
   * @notice Calculates and returns`_tree`'s current root given array of zero
   * hashes
   * @param _zeroes Array of zero hashes
   * @return _current Calculated root of `_tree`
   **/
  function rootWithCtx(Tree storage _tree, bytes32[TREE_DEPTH] memory _zeroes)
    internal
    view
    returns (bytes32 _current)
  {
    uint256 _index = _tree.count;

    for (uint256 i = 0; i < TREE_DEPTH; i++) {
      uint256 _ithBit = (_index >> i) & 0x01;
      bytes32 _next = _tree.branch[i];
      if (_ithBit == 1) {
        _current = keccak256(abi.encodePacked(_next, _current));
      } else {
        _current = keccak256(abi.encodePacked(_current, _zeroes[i]));
      }
    }
  }

  /// @notice Calculates and returns`_tree`'s current root
  function root(Tree storage _tree) internal view returns (bytes32) {
    return rootWithCtx(_tree, zeroHashes());
  }

  /// @notice Returns array of TREE_DEPTH zero hashes
  /// @return _zeroes Array of TREE_DEPTH zero hashes
  function zeroHashes() internal pure returns (bytes32[TREE_DEPTH] memory _zeroes) {
    _zeroes[0] = Z_0;
    _zeroes[1] = Z_1;
    _zeroes[2] = Z_2;
    _zeroes[3] = Z_3;
    _zeroes[4] = Z_4;
    _zeroes[5] = Z_5;
    _zeroes[6] = Z_6;
    _zeroes[7] = Z_7;
    _zeroes[8] = Z_8;
    _zeroes[9] = Z_9;
    _zeroes[10] = Z_10;
    _zeroes[11] = Z_11;
    _zeroes[12] = Z_12;
    _zeroes[13] = Z_13;
    _zeroes[14] = Z_14;
    _zeroes[15] = Z_15;
    _zeroes[16] = Z_16;
    _zeroes[17] = Z_17;
    _zeroes[18] = Z_18;
    _zeroes[19] = Z_19;
    _zeroes[20] = Z_20;
    _zeroes[21] = Z_21;
    _zeroes[22] = Z_22;
    _zeroes[23] = Z_23;
    _zeroes[24] = Z_24;
    _zeroes[25] = Z_25;
    _zeroes[26] = Z_26;
    _zeroes[27] = Z_27;
    _zeroes[28] = Z_28;
    _zeroes[29] = Z_29;
    _zeroes[30] = Z_30;
    _zeroes[31] = Z_31;
  }

  /**
   * @notice Calculates and returns the merkle root for the given leaf
   * `_item`, a merkle branch, and the index of `_item` in the tree.
   * @param _item Merkle leaf
   * @param _branch Merkle proof
   * @param _index Index of `_item` in tree
   * @return _current Calculated merkle root
   **/
  function branchRoot(
    bytes32 _item,
    bytes32[TREE_DEPTH] memory _branch,
    uint256 _index
  ) internal pure returns (bytes32 _current) {
    _current = _item;

    for (uint256 i = 0; i < TREE_DEPTH; i++) {
      uint256 _ithBit = (_index >> i) & 0x01;
      bytes32 _next = _branch[i];
      if (_ithBit == 1) {
        _current = keccak256(abi.encodePacked(_next, _current));
      } else {
        _current = keccak256(abi.encodePacked(_current, _next));
      }
    }
  }

  // keccak256 zero hashes
  bytes32 internal constant Z_0 = hex"0000000000000000000000000000000000000000000000000000000000000000";
  bytes32 internal constant Z_1 = hex"ad3228b676f7d3cd4284a5443f17f1962b36e491b30a40b2405849e597ba5fb5";
  bytes32 internal constant Z_2 = hex"b4c11951957c6f8f642c4af61cd6b24640fec6dc7fc607ee8206a99e92410d30";
  bytes32 internal constant Z_3 = hex"21ddb9a356815c3fac1026b6dec5df3124afbadb485c9ba5a3e3398a04b7ba85";
  bytes32 internal constant Z_4 = hex"e58769b32a1beaf1ea27375a44095a0d1fb664ce2dd358e7fcbfb78c26a19344";
  bytes32 internal constant Z_5 = hex"0eb01ebfc9ed27500cd4dfc979272d1f0913cc9f66540d7e8005811109e1cf2d";
  bytes32 internal constant Z_6 = hex"887c22bd8750d34016ac3c66b5ff102dacdd73f6b014e710b51e8022af9a1968";
  bytes32 internal constant Z_7 = hex"ffd70157e48063fc33c97a050f7f640233bf646cc98d9524c6b92bcf3ab56f83";
  bytes32 internal constant Z_8 = hex"9867cc5f7f196b93bae1e27e6320742445d290f2263827498b54fec539f756af";
  bytes32 internal constant Z_9 = hex"cefad4e508c098b9a7e1d8feb19955fb02ba9675585078710969d3440f5054e0";
  bytes32 internal constant Z_10 = hex"f9dc3e7fe016e050eff260334f18a5d4fe391d82092319f5964f2e2eb7c1c3a5";
  bytes32 internal constant Z_11 = hex"f8b13a49e282f609c317a833fb8d976d11517c571d1221a265d25af778ecf892";
  bytes32 internal constant Z_12 = hex"3490c6ceeb450aecdc82e28293031d10c7d73bf85e57bf041a97360aa2c5d99c";
  bytes32 internal constant Z_13 = hex"c1df82d9c4b87413eae2ef048f94b4d3554cea73d92b0f7af96e0271c691e2bb";
  bytes32 internal constant Z_14 = hex"5c67add7c6caf302256adedf7ab114da0acfe870d449a3a489f781d659e8becc";
  bytes32 internal constant Z_15 = hex"da7bce9f4e8618b6bd2f4132ce798cdc7a60e7e1460a7299e3c6342a579626d2";
  bytes32 internal constant Z_16 = hex"2733e50f526ec2fa19a22b31e8ed50f23cd1fdf94c9154ed3a7609a2f1ff981f";
  bytes32 internal constant Z_17 = hex"e1d3b5c807b281e4683cc6d6315cf95b9ade8641defcb32372f1c126e398ef7a";
  bytes32 internal constant Z_18 = hex"5a2dce0a8a7f68bb74560f8f71837c2c2ebbcbf7fffb42ae1896f13f7c7479a0";
  bytes32 internal constant Z_19 = hex"b46a28b6f55540f89444f63de0378e3d121be09e06cc9ded1c20e65876d36aa0";
  bytes32 internal constant Z_20 = hex"c65e9645644786b620e2dd2ad648ddfcbf4a7e5b1a3a4ecfe7f64667a3f0b7e2";
  bytes32 internal constant Z_21 = hex"f4418588ed35a2458cffeb39b93d26f18d2ab13bdce6aee58e7b99359ec2dfd9";
  bytes32 internal constant Z_22 = hex"5a9c16dc00d6ef18b7933a6f8dc65ccb55667138776f7dea101070dc8796e377";
  bytes32 internal constant Z_23 = hex"4df84f40ae0c8229d0d6069e5c8f39a7c299677a09d367fc7b05e3bc380ee652";
  bytes32 internal constant Z_24 = hex"cdc72595f74c7b1043d0e1ffbab734648c838dfb0527d971b602bc216c9619ef";
  bytes32 internal constant Z_25 = hex"0abf5ac974a1ed57f4050aa510dd9c74f508277b39d7973bb2dfccc5eeb0618d";
  bytes32 internal constant Z_26 = hex"b8cd74046ff337f0a7bf2c8e03e10f642c1886798d71806ab1e888d9e5ee87d0";
  bytes32 internal constant Z_27 = hex"838c5655cb21c6cb83313b5a631175dff4963772cce9108188b34ac87c81c41e";
  bytes32 internal constant Z_28 = hex"662ee4dd2dd7b2bc707961b1e646c4047669dcb6584f0d8d770daf5d7e7deb2e";
  bytes32 internal constant Z_29 = hex"388ab20e2573d171a88108e79d820e98f26c0b84aa8b2f4aa4968dbb818ea322";
  bytes32 internal constant Z_30 = hex"93237c50ba75ee485f4c22adf2f741400bdf8d6a9cc7df7ecae576221665d735";
  bytes32 internal constant Z_31 = hex"8448818bb4ae4562849e949e17ac16e0be16688e156b5cf15e098c627c0056a9";
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// import "@summa-tx/memview-sol/contracts/TypedMemView.sol";

import "./TypedMemView.sol";

import {TypeCasts} from "./TypeCasts.sol";

/**
 * @title Message Library
 * @author Illusory Systems Inc.
 * @notice Library for formatted messages used by Home and Replica.
 **/
library Message {
  using TypedMemView for bytes;
  using TypedMemView for bytes29;

  // Number of bytes in formatted message before `body` field
  uint256 internal constant PREFIX_LENGTH = 76;

  /**
   * @notice Returns formatted (packed) message with provided fields
   * @param _originDomain Domain of home chain
   * @param _sender Address of sender as bytes32
   * @param _nonce Destination-specific nonce
   * @param _destinationDomain Domain of destination chain
   * @param _recipient Address of recipient on destination chain as bytes32
   * @param _messageBody Raw bytes of message body
   * @return Formatted message
   **/
  function formatMessage(
    uint32 _originDomain,
    bytes32 _sender,
    uint32 _nonce,
    uint32 _destinationDomain,
    bytes32 _recipient,
    bytes memory _messageBody
  ) internal pure returns (bytes memory) {
    return abi.encodePacked(_originDomain, _sender, _nonce, _destinationDomain, _recipient, _messageBody);
  }

  /**
   * @notice Returns leaf of formatted message with provided fields.
   * @param _origin Domain of home chain
   * @param _sender Address of sender as bytes32
   * @param _nonce Destination-specific nonce number
   * @param _destination Domain of destination chain
   * @param _recipient Address of recipient on destination chain as bytes32
   * @param _body Raw bytes of message body
   * @return Leaf (hash) of formatted message
   **/
  function messageHash(
    uint32 _origin,
    bytes32 _sender,
    uint32 _nonce,
    uint32 _destination,
    bytes32 _recipient,
    bytes memory _body
  ) internal pure returns (bytes32) {
    return keccak256(formatMessage(_origin, _sender, _nonce, _destination, _recipient, _body));
  }

  /// @notice Returns message's origin field
  function origin(bytes29 _message) internal pure returns (uint32) {
    return uint32(_message.indexUint(0, 4));
  }

  /// @notice Returns message's sender field
  function sender(bytes29 _message) internal pure returns (bytes32) {
    return _message.index(4, 32);
  }

  /// @notice Returns message's nonce field
  function nonce(bytes29 _message) internal pure returns (uint32) {
    return uint32(_message.indexUint(36, 4));
  }

  /// @notice Returns message's destination field
  function destination(bytes29 _message) internal pure returns (uint32) {
    return uint32(_message.indexUint(40, 4));
  }

  /// @notice Returns message's recipient field as bytes32
  function recipient(bytes29 _message) internal pure returns (bytes32) {
    return _message.index(44, 32);
  }

  /// @notice Returns message's recipient field as an address
  function recipientAddress(bytes29 _message) internal pure returns (address) {
    return TypeCasts.bytes32ToAddress(recipient(_message));
  }

  /// @notice Returns message's body field as bytes29 (refer to TypedMemView library for details on bytes29 type)
  function body(bytes29 _message) internal pure returns (bytes29) {
    return _message.slice(PREFIX_LENGTH, _message.len() - PREFIX_LENGTH, 0);
  }

  function leaf(bytes29 _message) internal view returns (bytes32) {
    return
      messageHash(
        origin(_message),
        sender(_message),
        nonce(_message),
        destination(_message),
        recipient(_message),
        TypedMemView.clone(body(_message))
      );
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import {MerkleLib} from "../libs/Merkle.sol";

/**
 * @title MerkleTreeManager
 * @author Illusory Systems Inc.
 * @notice Contains a Merkle tree instance and
 * exposes view functions for the tree.
 */
contract MerkleTreeManager {
  // ============ Libraries ============

  using MerkleLib for MerkleLib.Tree;
  MerkleLib.Tree public tree;

  // ============ Upgrade Gap ============

  // gap for upgrade safety
  uint256[49] private __GAP;

  // ============ Public Functions ============

  /**
   * @notice Calculates and returns tree's current root
   */
  function root() public view returns (bytes32) {
    return tree.root();
  }

  /**
   * @notice Returns the number of inserted leaves in the tree (current index)
   */
  function count() public view returns (uint256) {
    return tree.count;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import {QueueLib} from "../libs/Queue.sol";
// ============ External Imports ============
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title QueueManager
 * @author Illusory Systems Inc.
 * @notice Contains a queue instance and
 * exposes view functions for the queue.
 **/
contract QueueManager is Initializable {
  // ============ Libraries ============

  using QueueLib for QueueLib.Queue;
  QueueLib.Queue internal queue;

  // ============ Upgrade Gap ============

  // gap for upgrade safety
  uint256[49] private __GAP;

  // ============ Initializer ============

  function __QueueManager_initialize() internal initializer {
    queue.initialize();
  }

  // ============ Public Functions ============

  /**
   * @notice Returns number of elements in queue
   */
  function queueLength() external view returns (uint256) {
    return queue.length();
  }

  /**
   * @notice Returns TRUE iff `_item` is in the queue
   */
  function queueContains(bytes32 _item) external view returns (bool) {
    return queue.contains(_item);
  }

  /**
   * @notice Returns last item enqueued to the queue
   */
  function queueEnd() external view returns (bytes32) {
    return queue.lastItem();
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

interface IUpdaterManager {
  function slashUpdater(address payable _reporter) external;

  function updater() external view returns (address);
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

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// import "@summa-tx/memview-sol/contracts/TypedMemView.sol";
import "./TypedMemView.sol";

library TypeCasts {
  using TypedMemView for bytes;
  using TypedMemView for bytes29;

  function coerceBytes32(string memory _s) internal pure returns (bytes32 _b) {
    _b = bytes(_s).ref(0).index(0, uint8(bytes(_s).length));
  }

  // treat it as a null-terminated string of max 32 bytes
  function coerceString(bytes32 _buf) internal pure returns (string memory _newStr) {
    uint8 _slen = 0;
    while (_slen < 32 && _buf[_slen] != 0) {
      _slen++;
    }

    // solhint-disable-next-line no-inline-assembly
    assembly {
      _newStr := mload(0x40)
      mstore(0x40, add(_newStr, 0x40)) // may end up with extra
      mstore(_newStr, _slen)
      mstore(add(_newStr, 0x20), _buf)
    }
  }

  // alignment preserving cast
  function addressToBytes32(address _addr) internal pure returns (bytes32) {
    return bytes32(uint256(uint160(_addr)));
  }

  // alignment preserving cast
  function bytes32ToAddress(bytes32 _buf) internal pure returns (address) {
    return address(uint160(uint256(_buf)));
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

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ External Imports ============
// import {Home} from "../../../../nomad-core-sol/contracts/Home.sol";
import {Home} from "../../nomad-core/contracts/Home.sol";
import {XAppConnectionManager} from "../../nomad-core/contracts/XAppConnectionManager.sol";

// TODO: refactor proposed ownable to be one basic + one router/asset
import {ProposedOwnableUpgradeable} from "../../ProposedOwnableUpgradeable.sol";

abstract contract XAppConnectionClient is ProposedOwnableUpgradeable {
  // ============ Mutable Storage ============

  XAppConnectionManager public xAppConnectionManager;
  uint256[49] private __GAP; // gap for upgrade safety

  // ============ Modifiers ============

  /**
   * @notice Only accept messages from an Nomad Replica contract
   */
  modifier onlyReplica() {
    require(_isReplica(msg.sender), "!replica");
    _;
  }

  // ======== Initializer =========

  function __XAppConnectionClient_initialize(address _xAppConnectionManager) internal initializer {
    xAppConnectionManager = XAppConnectionManager(_xAppConnectionManager);
    __ProposedOwnable_init();
  }

  // ============ External functions ============

  /**
   * @notice Modify the contract the xApp uses to validate Replica contracts
   * @param _xAppConnectionManager The address of the xAppConnectionManager contract
   */
  function setXAppConnectionManager(address _xAppConnectionManager) external onlyOwner {
    xAppConnectionManager = XAppConnectionManager(_xAppConnectionManager);
  }

  // ============ Internal functions ============

  /**
   * @notice Get the local Home contract from the xAppConnectionManager
   * @return The local Home contract
   */
  function _home() internal view returns (Home) {
    return xAppConnectionManager.home();
  }

  /**
   * @notice Determine whether _potentialReplcia is an enrolled Replica from the xAppConnectionManager
   * @return True if _potentialReplica is an enrolled Replica
   */
  function _isReplica(address _potentialReplica) internal view returns (bool) {
    return xAppConnectionManager.isReplica(_potentialReplica);
  }

  /**
   * @notice Get the local domain from the xAppConnectionManager
   * @return The local domain
   */
  function _localDomain() internal view virtual returns (uint32) {
    return xAppConnectionManager.localDomain();
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.11;

// ============ External Imports ============
import {TypedMemView} from "../../../nomad-core/libs/TypedMemView.sol";

library RelayerFeeMessage {
  // ============ Libraries ============

  using TypedMemView for bytes;
  using TypedMemView for bytes29;

  // ============ Enums ============

  // WARNING: do NOT re-write the numbers / order
  // of message types in an upgrade;
  // will cause in-flight messages to be mis-interpreted
  enum Types {
    Invalid, // 0
    ClaimFees // 1
  }

  // ============ Constants ============

  // before: 1 byte identifier + 20 bytes recipient + 32 bytes length + 32 bytes 1 transfer id = 85 bytes
  uint256 private constant MIN_CLAIM_LEN = 85;
  // before: 1 byte identifier + 20 bytes recipient = 21 bytes
  uint256 private constant LENGTH_ID_START = 21;
  uint8 private constant LENGTH_ID_LEN = 32;
  // before: 1 byte identifier
  uint256 private constant RECIPIENT_START = 1;
  // before: 1 byte identifier + 20 bytes recipient + 32 bytes length = 53 bytes
  uint256 private constant TRANSFER_IDS_START = 53;
  uint8 private constant TRANSFER_ID_LEN = 32;

  // ============ Modifiers ============

  /**
   * @notice Asserts a message is of type `_t`
   * @param _view The message
   * @param _t The expected type
   */
  modifier typeAssert(bytes29 _view, Types _t) {
    _view.assertType(uint40(_t));
    _;
  }

  // ============ Formatters ============

  /**
   * @notice Formats an claim fees message
   * @param _recipient The address of the relayer
   * @param _transferIds A group of transfers ids to claim for fee bumps
   * @return The formatted message
   */
  function formatClaimFees(address _recipient, bytes32[] calldata _transferIds) internal pure returns (bytes memory) {
    return abi.encodePacked(uint8(Types.ClaimFees), _recipient, _transferIds.length, _transferIds);
  }

  // ============ Getters ============

  /**
   * @notice Parse the recipient address of the fees
   * @param _view The message
   * @return The recipient address
   */
  function recipient(bytes29 _view) internal pure typeAssert(_view, Types.ClaimFees) returns (address) {
    // before = 1 byte identifier
    return _view.indexAddress(1);
  }

  /**
   * @notice Parse The group of transfers ids to claim for fee bumps
   * @param _view The message
   * @return The group of transfers ids to claim for fee bumps
   */
  function transferIds(bytes29 _view) internal pure typeAssert(_view, Types.ClaimFees) returns (bytes32[] memory) {
    uint256 length = _view.indexUint(LENGTH_ID_START, LENGTH_ID_LEN);

    bytes32[] memory ids = new bytes32[](length);
    for (uint256 i = 0; i < length; ) {
      ids[i] = _view.index(TRANSFER_IDS_START + i * TRANSFER_ID_LEN, TRANSFER_ID_LEN);

      unchecked {
        i++;
      }
    }
    return ids;
  }

  /**
   * @notice Checks that view is a valid message length
   * @param _view The bytes string
   * @return TRUE if message is valid
   */
  function isValidClaimFeesLength(bytes29 _view) internal pure returns (bool) {
    uint256 _len = _view.len();
    // at least 1 transfer id where the excess is multiplier of transfer id length
    return _len >= MIN_CLAIM_LEN && (_len - TRANSFER_IDS_START) % TRANSFER_ID_LEN == 0;
  }

  /**
   * @notice Converts to a ClaimFees
   * @param _view The message
   * @return The newly typed message
   */
  function tryAsClaimFees(bytes29 _view) internal pure returns (bytes29) {
    if (isValidClaimFeesLength(_view)) {
      return _view.castTo(uint40(Types.ClaimFees));
    }
    return TypedMemView.nullView();
  }

  /**
   * @notice Asserts that the message is of type ClaimFees
   * @param _view The message
   * @return The message
   */
  function mustBeClaimFees(bytes29 _view) internal pure returns (bytes29) {
    return tryAsClaimFees(_view).assertValid();
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

interface IBridgeToken {
  function initialize() external;

  function name() external returns (string memory);

  function balanceOf(address _account) external view returns (uint256);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function detailsHash() external view returns (bytes32);

  function burn(address _from, uint256 _amnt) external;

  function mint(address _to, uint256 _amnt) external;

  function setDetailsHash(bytes32 _detailsHash) external;

  function setDetails(
    string calldata _name,
    string calldata _symbol,
    uint8 _decimals
  ) external;

  // inherited from ownable
  function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

interface IMessageRecipient {
  function handle(
    uint32 _origin,
    uint32 _nonce,
    bytes32 _sender,
    bytes memory _message
  ) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import {Home} from "./Home.sol";
import {Replica} from "./Replica.sol";
import {TypeCasts} from "../libs/TypeCasts.sol";
// ============ External Imports ============
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title XAppConnectionManager
 * @author Illusory Systems Inc.
 * @notice Manages a registry of local Replica contracts
 * for remote Home domains. Accepts Watcher signatures
 * to un-enroll Replicas attached to fraudulent remote Homes
 */
contract XAppConnectionManager is Ownable {
  // ============ Public Storage ============

  // Home contract
  Home public home;
  // local Replica address => remote Home domain
  mapping(address => uint32) public replicaToDomain;
  // remote Home domain => local Replica address
  mapping(uint32 => address) public domainToReplica;
  // watcher address => replica remote domain => has/doesn't have permission
  mapping(address => mapping(uint32 => bool)) private watcherPermissions;

  // ============ Events ============

  /**
   * @notice Emitted when a new Replica is enrolled / added
   * @param domain the remote domain of the Home contract for the Replica
   * @param replica the address of the Replica
   */
  event ReplicaEnrolled(uint32 indexed domain, address replica);

  /**
   * @notice Emitted when a new Replica is un-enrolled / removed
   * @param domain the remote domain of the Home contract for the Replica
   * @param replica the address of the Replica
   */
  event ReplicaUnenrolled(uint32 indexed domain, address replica);

  /**
   * @notice Emitted when Watcher permissions are changed
   * @param domain the remote domain of the Home contract for the Replica
   * @param watcher the address of the Watcher
   * @param access TRUE if the Watcher was given permissions, FALSE if permissions were removed
   */
  event WatcherPermissionSet(uint32 indexed domain, address watcher, bool access);

  // ============ Modifiers ============

  modifier onlyReplica() {
    require(isReplica(msg.sender), "!replica");
    _;
  }

  // ============ Constructor ============

  // solhint-disable-next-line no-empty-blocks
  constructor() Ownable() {}

  // ============ External Functions ============

  /**
   * @notice Un-Enroll a replica contract
   * in the case that fraud was detected on the Home
   * @dev in the future, if fraud occurs on the Home contract,
   * the Watcher will submit their signature directly to the Home
   * and it can be relayed to all remote chains to un-enroll the Replicas
   * @param _domain the remote domain of the Home contract for the Replica
   * @param _updater the address of the Updater for the Home contract (also stored on Replica)
   * @param _signature signature of watcher on (domain, replica address, updater address)
   */
  function unenrollReplica(
    uint32 _domain,
    bytes32 _updater,
    bytes memory _signature
  ) external {
    // ensure that the replica is currently set
    address _replica = domainToReplica[_domain];
    require(_replica != address(0), "!replica exists");
    // ensure that the signature is on the proper updater
    require(Replica(_replica).updater() == TypeCasts.bytes32ToAddress(_updater), "!current updater");
    // get the watcher address from the signature
    // and ensure that the watcher has permission to un-enroll this replica
    address _watcher = _recoverWatcherFromSig(_domain, TypeCasts.addressToBytes32(_replica), _updater, _signature);
    require(watcherPermissions[_watcher][_domain], "!valid watcher");
    // remove the replica from mappings
    _unenrollReplica(_replica);
  }

  /**
   * @notice Set the address of the local Home contract
   * @param _home the address of the local Home contract
   */
  function setHome(address _home) external onlyOwner {
    home = Home(_home);
  }

  /**
   * @notice Allow Owner to enroll Replica contract
   * @param _replica the address of the Replica
   * @param _domain the remote domain of the Home contract for the Replica
   */
  function ownerEnrollReplica(address _replica, uint32 _domain) external onlyOwner {
    // un-enroll any existing replica
    _unenrollReplica(_replica);
    // add replica and domain to two-way mapping
    replicaToDomain[_replica] = _domain;
    domainToReplica[_domain] = _replica;
    emit ReplicaEnrolled(_domain, _replica);
  }

  /**
   * @notice Allow Owner to un-enroll Replica contract
   * @param _replica the address of the Replica
   */
  function ownerUnenrollReplica(address _replica) external onlyOwner {
    _unenrollReplica(_replica);
  }

  /**
   * @notice Allow Owner to set Watcher permissions for a Replica
   * @param _watcher the address of the Watcher
   * @param _domain the remote domain of the Home contract for the Replica
   * @param _access TRUE to give the Watcher permissions, FALSE to remove permissions
   */
  function setWatcherPermission(
    address _watcher,
    uint32 _domain,
    bool _access
  ) external onlyOwner {
    watcherPermissions[_watcher][_domain] = _access;
    emit WatcherPermissionSet(_domain, _watcher, _access);
  }

  /**
   * @notice Query local domain from Home
   * @return local domain
   */
  function localDomain() external view returns (uint32) {
    return home.localDomain();
  }

  /**
   * @notice Get access permissions for the watcher on the domain
   * @param _watcher the address of the watcher
   * @param _domain the domain to check for watcher permissions
   * @return TRUE iff _watcher has permission to un-enroll replicas on _domain
   */
  function watcherPermission(address _watcher, uint32 _domain) external view returns (bool) {
    return watcherPermissions[_watcher][_domain];
  }

  // ============ Public Functions ============

  /**
   * @notice Check whether _replica is enrolled
   * @param _replica the replica to check for enrollment
   * @return TRUE iff _replica is enrolled
   */
  function isReplica(address _replica) public view returns (bool) {
    return replicaToDomain[_replica] != 0;
  }

  // ============ Internal Functions ============

  /**
   * @notice Remove the replica from the two-way mappings
   * @param _replica replica to un-enroll
   */
  function _unenrollReplica(address _replica) internal {
    uint32 _currentDomain = replicaToDomain[_replica];
    domainToReplica[_currentDomain] = address(0);
    replicaToDomain[_replica] = 0;
    emit ReplicaUnenrolled(_currentDomain, _replica);
  }

  /**
   * @notice Get the Watcher address from the provided signature
   * @return address of watcher that signed
   */
  function _recoverWatcherFromSig(
    uint32 _domain,
    bytes32 _replica,
    bytes32 _updater,
    bytes memory _signature
  ) internal view returns (address) {
    bytes32 _homeDomainHash = Replica(TypeCasts.bytes32ToAddress(_replica)).homeDomainHash();
    bytes32 _digest = keccak256(abi.encodePacked(_homeDomainHash, _domain, _updater));
    _digest = ECDSA.toEthSignedMessageHash(_digest);
    return ECDSA.recover(_digest, _signature);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title ProposedOwnable
 * @notice Contract module which provides a basic access control mechanism,
 * where there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed via a two step process:
 * 1. Call `proposeOwner`
 * 2. Wait out the delay period
 * 3. Call `acceptOwner`
 *
 * @dev This module is used through inheritance. It will make available the
 * modifier `onlyOwner`, which can be applied to your functions to restrict
 * their use to the owner.
 *
 * @dev The majority of this code was taken from the openzeppelin Ownable
 * contract
 *
 */
abstract contract ProposedOwnableUpgradeable is Initializable {
  // ========== Custom Errors ===========

  error ProposedOwnableUpgradeable__onlyOwner_notOwner();
  error ProposedOwnableUpgradeable__onlyProposed_notProposedOwner();
  error ProposedOwnableUpgradeable__proposeRouterOwnershipRenunciation_noOwnershipChange();
  error ProposedOwnableUpgradeable__renounceRouterOwnership_noOwnershipChange();
  error ProposedOwnableUpgradeable__renounceRouterOwnership_noProposal();
  error ProposedOwnableUpgradeable__renounceRouterOwnership_delayNotElapsed();
  error ProposedOwnableUpgradeable__proposeAssetOwnershipRenunciation_noOwnershipChange();
  error ProposedOwnableUpgradeable__renounceAssetOwnership_noOwnershipChange();
  error ProposedOwnableUpgradeable__renounceAssetOwnership_noProposal();
  error ProposedOwnableUpgradeable__renounceAssetOwnership_delayNotElapsed();
  error ProposedOwnableUpgradeable__proposeNewOwner_invalidProposal();
  error ProposedOwnableUpgradeable__proposeNewOwner_noOwnershipChange();
  error ProposedOwnableUpgradeable__renounceOwnership_noProposal();
  error ProposedOwnableUpgradeable__renounceOwnership_delayNotElapsed();
  error ProposedOwnableUpgradeable__renounceOwnership_invalidProposal();
  error ProposedOwnableUpgradeable__acceptProposedOwner_noOwnershipChange();
  error ProposedOwnableUpgradeable__acceptProposedOwner_delayNotElapsed();

  // ============ Properties ============

  address private _owner;

  address private _proposed;
  uint256 private _proposedOwnershipTimestamp;

  bool private _routerOwnershipRenounced;
  uint256 private _routerOwnershipTimestamp;

  bool private _assetOwnershipRenounced;
  uint256 private _assetOwnershipTimestamp;

  uint256 private constant _delay = 7 days;

  event RouterOwnershipRenunciationProposed(uint256 timestamp);

  event RouterOwnershipRenounced(bool renounced);

  event AssetOwnershipRenunciationProposed(uint256 timestamp);

  event AssetOwnershipRenounced(bool renounced);

  event OwnershipProposed(address indexed proposedOwner);

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial
   */
  function __ProposedOwnable_init() internal onlyInitializing {
    __ProposedOwnable_init_unchained();
  }

  function __ProposedOwnable_init_unchained() internal onlyInitializing {
    _setOwner(msg.sender);
  }

  /**
   * @notice Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @notice Returns the address of the proposed owner.
   */
  function proposed() public view virtual returns (address) {
    return _proposed;
  }

  /**
   * @notice Returns the address of the proposed owner.
   */
  function proposedTimestamp() public view virtual returns (uint256) {
    return _proposedOwnershipTimestamp;
  }

  /**
   * @notice Returns the timestamp when router ownership was last proposed to be renounced
   */
  function routerOwnershipTimestamp() public view virtual returns (uint256) {
    return _routerOwnershipTimestamp;
  }

  /**
   * @notice Returns the timestamp when asset ownership was last proposed to be renounced
   */
  function assetOwnershipTimestamp() public view virtual returns (uint256) {
    return _assetOwnershipTimestamp;
  }

  /**
   * @notice Returns the delay period before a new owner can be accepted.
   */
  function delay() public view virtual returns (uint256) {
    return _delay;
  }

  /**
   * @notice Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    if (_owner != msg.sender) revert ProposedOwnableUpgradeable__onlyOwner_notOwner();
    _;
  }

  /**
   * @notice Throws if called by any account other than the proposed owner.
   */
  modifier onlyProposed() {
    if (_proposed != msg.sender) revert ProposedOwnableUpgradeable__onlyProposed_notProposedOwner();
    _;
  }

  /**
   * @notice Indicates if the ownership of the router whitelist has
   * been renounced
   */
  function isRouterOwnershipRenounced() public view returns (bool) {
    return _owner == address(0) || _routerOwnershipRenounced;
  }

  /**
   * @notice Indicates if the ownership of the router whitelist has
   * been renounced
   */
  function proposeRouterOwnershipRenunciation() public virtual onlyOwner {
    // Use contract as source of truth
    // Will fail if all ownership is renounced by modifier
    if (_routerOwnershipRenounced)
      revert ProposedOwnableUpgradeable__proposeRouterOwnershipRenunciation_noOwnershipChange();

    // Begin delay, emit event
    _setRouterOwnershipTimestamp();
  }

  /**
   * @notice Indicates if the ownership of the asset whitelist has
   * been renounced
   */
  function renounceRouterOwnership() public virtual onlyOwner {
    // Contract as sournce of truth
    // Will fail if all ownership is renounced by modifier
    if (_routerOwnershipRenounced) revert ProposedOwnableUpgradeable__renounceRouterOwnership_noOwnershipChange();

    // Ensure there has been a proposal cycle started
    if (_routerOwnershipTimestamp == 0) revert ProposedOwnableUpgradeable__renounceRouterOwnership_noProposal();

    // Delay has elapsed
    if ((block.timestamp - _routerOwnershipTimestamp) <= _delay)
      revert ProposedOwnableUpgradeable__renounceRouterOwnership_delayNotElapsed();

    // Set renounced, emit event, reset timestamp to 0
    _setRouterOwnership(true);
  }

  /**
   * @notice Indicates if the ownership of the asset whitelist has
   * been renounced
   */
  function isAssetOwnershipRenounced() public view returns (bool) {
    return _owner == address(0) || _assetOwnershipRenounced;
  }

  /**
   * @notice Indicates if the ownership of the asset whitelist has
   * been renounced
   */
  function proposeAssetOwnershipRenunciation() public virtual onlyOwner {
    // Contract as sournce of truth
    // Will fail if all ownership is renounced by modifier
    if (_assetOwnershipRenounced)
      revert ProposedOwnableUpgradeable__proposeAssetOwnershipRenunciation_noOwnershipChange();

    // Start cycle, emit event
    _setAssetOwnershipTimestamp();
  }

  /**
   * @notice Indicates if the ownership of the asset whitelist has
   * been renounced
   */
  function renounceAssetOwnership() public virtual onlyOwner {
    // Contract as sournce of truth
    // Will fail if all ownership is renounced by modifier
    if (_assetOwnershipRenounced) revert ProposedOwnableUpgradeable__renounceAssetOwnership_noOwnershipChange();

    // Ensure there has been a proposal cycle started
    if (_assetOwnershipTimestamp == 0) revert ProposedOwnableUpgradeable__renounceAssetOwnership_noProposal();

    // Ensure delay has elapsed
    if ((block.timestamp - _assetOwnershipTimestamp) <= _delay)
      revert ProposedOwnableUpgradeable__renounceAssetOwnership_delayNotElapsed();

    // Set ownership, reset timestamp, emit event
    _setAssetOwnership(true);
  }

  /**
   * @notice Indicates if the ownership has been renounced() by
   * checking if current owner is address(0)
   */
  function renounced() public view returns (bool) {
    return _owner == address(0);
  }

  /**
   * @notice Sets the timestamp for an owner to be proposed, and sets the
   * newly proposed owner as step 1 in a 2-step process
   */
  function proposeNewOwner(address newlyProposed) public virtual onlyOwner {
    // Contract as source of truth
    if (_proposed == newlyProposed && newlyProposed != address(0))
      revert ProposedOwnableUpgradeable__proposeNewOwner_invalidProposal();

    // Sanity check: reasonable proposal
    if (_owner == newlyProposed) revert ProposedOwnableUpgradeable__proposeNewOwner_noOwnershipChange();

    _setProposed(newlyProposed);
  }

  /**
   * @notice Renounces ownership of the contract after a delay
   */
  function renounceOwnership() public virtual onlyOwner {
    // Ensure there has been a proposal cycle started
    if (_proposedOwnershipTimestamp == 0) revert ProposedOwnableUpgradeable__renounceOwnership_noProposal();

    // Ensure delay has elapsed
    if ((block.timestamp - _proposedOwnershipTimestamp) <= _delay)
      revert ProposedOwnableUpgradeable__renounceOwnership_delayNotElapsed();

    // Require proposed is set to 0
    if (_proposed != address(0)) revert ProposedOwnableUpgradeable__renounceOwnership_invalidProposal();

    // Emit event, set new owner, reset timestamp
    _setOwner(_proposed);
  }

  /**
   * @notice Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function acceptProposedOwner() public virtual onlyProposed {
    // Contract as source of truth
    if (_owner == _proposed) revert ProposedOwnableUpgradeable__acceptProposedOwner_noOwnershipChange();

    // NOTE: no need to check if _proposedOwnershipTimestamp > 0 because
    // the only time this would happen is if the _proposed was never
    // set (will fail from modifier) or if the owner == _proposed (checked
    // above)

    // Ensure delay has elapsed
    if ((block.timestamp - _proposedOwnershipTimestamp) <= _delay)
      revert ProposedOwnableUpgradeable__acceptProposedOwner_delayNotElapsed();

    // Emit event, set new owner, reset timestamp
    _setOwner(_proposed);
  }

  ////// INTERNAL //////

  function _setRouterOwnershipTimestamp() private {
    _routerOwnershipTimestamp = block.timestamp;
    emit RouterOwnershipRenunciationProposed(_routerOwnershipTimestamp);
  }

  function _setRouterOwnership(bool value) private {
    _routerOwnershipRenounced = value;
    _routerOwnershipTimestamp = 0;
    emit RouterOwnershipRenounced(value);
  }

  function _setAssetOwnershipTimestamp() private {
    _assetOwnershipTimestamp = block.timestamp;
    emit AssetOwnershipRenunciationProposed(_assetOwnershipTimestamp);
  }

  function _setAssetOwnership(bool value) private {
    _assetOwnershipRenounced = value;
    _assetOwnershipTimestamp = 0;
    emit AssetOwnershipRenounced(value);
  }

  function _setOwner(address newOwner) private {
    address oldOwner = _owner;
    _owner = newOwner;
    _proposedOwnershipTimestamp = 0;
    emit OwnershipTransferred(oldOwner, newOwner);
  }

  function _setProposed(address newlyProposed) private {
    _proposedOwnershipTimestamp = block.timestamp;
    _proposed = newlyProposed;
    emit OwnershipProposed(_proposed);
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import {Version0} from "./Version0.sol";
import {NomadBase} from "./NomadBase.sol";
import {MerkleLib} from "../libs/Merkle.sol";
import {Message} from "../libs/Message.sol";
// ============ External Imports ============
// import {TypedMemView} from "@summa-tx/memview-sol/contracts/TypedMemView.sol";
import {TypedMemView} from "../libs/TypedMemView.sol";

/**
 * @title Replica
 * @author Illusory Systems Inc.
 * @notice Track root updates on Home,
 * prove and dispatch messages to end recipients.
 */
contract Replica is Version0, NomadBase {
  // ============ Libraries ============

  using MerkleLib for MerkleLib.Tree;
  using TypedMemView for bytes;
  using TypedMemView for bytes29;
  using Message for bytes29;

  // ============ Enums ============

  // Status of Message:
  //   0 - None - message has not been proven or processed
  //   1 - Proven - message inclusion proof has been validated
  //   2 - Processed - message has been dispatched to recipient
  enum MessageStatus {
    None,
    Proven,
    Processed
  }

  // ============ Immutables ============

  // Minimum gas for message processing
  uint256 public immutable PROCESS_GAS;
  // Reserved gas (to ensure tx completes in case message processing runs out)
  uint256 public immutable RESERVE_GAS;

  // ============ Public Storage ============

  // Domain of home chain
  uint32 public remoteDomain;
  // Number of seconds to wait before root becomes confirmable
  uint256 public optimisticSeconds;
  // re-entrancy guard
  uint8 private entered;
  // Mapping of roots to allowable confirmation times
  mapping(bytes32 => uint256) public confirmAt;
  // Mapping of message leaves to MessageStatus
  mapping(bytes32 => MessageStatus) public messages;

  // ============ Upgrade Gap ============

  // gap for upgrade safety
  uint256[45] private __GAP;

  // ============ Events ============

  /**
   * @notice Emitted when message is processed
   * @param messageHash Hash of message that failed to process
   * @param success TRUE if the call was executed successfully, FALSE if the call reverted
   * @param returnData the return data from the external call
   */
  event Process(bytes32 indexed messageHash, bool indexed success, bytes indexed returnData);

  /**
   * @notice Emitted when the value for optimisticTimeout is set
   * @param timeout The new value for optimistic timeout
   */
  event SetOptimisticTimeout(uint256 timeout);

  /**
   * @notice Emitted when a root's confirmation is modified by governance
   * @param root The root for which confirmAt has been set
   * @param previousConfirmAt The previous value of confirmAt
   * @param newConfirmAt The new value of confirmAt
   */
  event SetConfirmation(bytes32 indexed root, uint256 previousConfirmAt, uint256 newConfirmAt);

  // ============ Constructor ============

  // solhint-disable-next-line no-empty-blocks
  constructor(
    uint32 _localDomain,
    uint256 _processGas,
    uint256 _reserveGas
  ) NomadBase(_localDomain) {
    require(_processGas >= 850_000, "!process gas");
    require(_reserveGas >= 15_000, "!reserve gas");
    PROCESS_GAS = _processGas;
    RESERVE_GAS = _reserveGas;
  }

  // ============ Initializer ============

  function initialize(
    uint32 _remoteDomain,
    address _updater,
    bytes32 _committedRoot,
    uint256 _optimisticSeconds
  ) public initializer {
    __NomadBase_initialize(_updater);
    // set storage variables
    entered = 1;
    remoteDomain = _remoteDomain;
    committedRoot = _committedRoot;
    confirmAt[_committedRoot] = 1;
    optimisticSeconds = _optimisticSeconds;
    emit SetOptimisticTimeout(_optimisticSeconds);
  }

  // ============ External Functions ============

  /**
   * @notice Called by external agent. Submits the signed update's new root,
   * marks root's allowable confirmation time, and emits an `Update` event.
   * @dev Reverts if update doesn't build off latest committedRoot
   * or if signature is invalid.
   * @param _oldRoot Old merkle root
   * @param _newRoot New merkle root
   * @param _signature Updater's signature on `_oldRoot` and `_newRoot`
   */
  function update(
    bytes32 _oldRoot,
    bytes32 _newRoot,
    bytes memory _signature
  ) external notFailed {
    // ensure that update is building off the last submitted root
    require(_oldRoot == committedRoot, "not current update");
    // validate updater signature
    require(_isUpdaterSignature(_oldRoot, _newRoot, _signature), "!updater sig");
    // Hook for future use
    _beforeUpdate();
    // set the new root's confirmation timer
    confirmAt[_newRoot] = block.timestamp + optimisticSeconds;
    // update committedRoot
    committedRoot = _newRoot;
    emit Update(remoteDomain, _oldRoot, _newRoot, _signature);
  }

  /**
   * @notice First attempts to prove the validity of provided formatted
   * `message`. If the message is successfully proven, then tries to process
   * message.
   * @dev Reverts if `prove` call returns false
   * @param _message Formatted message (refer to NomadBase.sol Message library)
   * @param _proof Merkle proof of inclusion for message's leaf
   * @param _index Index of leaf in home's merkle tree
   */
  function proveAndProcess(
    bytes memory _message,
    bytes32[32] calldata _proof,
    uint256 _index
  ) external {
    require(prove(keccak256(_message), _proof, _index), "!prove");
    process(_message);
  }

  /**
   * @notice Given formatted message, attempts to dispatch
   * message payload to end recipient.
   * @dev Recipient must implement a `handle` method (refer to IMessageRecipient.sol)
   * Reverts if formatted message's destination domain is not the Replica's domain,
   * if message has not been proven,
   * or if not enough gas is provided for the dispatch transaction.
   * @param _message Formatted message
   * @return _success TRUE iff dispatch transaction succeeded
   */
  function process(bytes memory _message) public returns (bool _success) {
    bytes29 _m = _message.ref(0);
    // ensure message was meant for this domain
    require(_m.destination() == localDomain, "!destination");
    // ensure message has been proven
    bytes32 _messageHash = _m.keccak();
    require(messages[_messageHash] == MessageStatus.Proven, "!proven");
    // check re-entrancy guard
    require(entered == 1, "!reentrant");
    entered = 0;
    // update message status as processed
    messages[_messageHash] = MessageStatus.Processed;
    // A call running out of gas TYPICALLY errors the whole tx. We want to
    // a) ensure the call has a sufficient amount of gas to make a
    //    meaningful state change.
    // b) ensure that if the subcall runs out of gas, that the tx as a whole
    //    does not revert (i.e. we still mark the message processed)
    // To do this, we require that we have enough gas to process
    // and still return. We then delegate only the minimum processing gas.
    require(gasleft() >= PROCESS_GAS + RESERVE_GAS, "!gas");
    // get the message recipient
    address _recipient = _m.recipientAddress();
    // set up for assembly call
    uint256 _toCopy;
    uint256 _maxCopy = 256;
    uint256 _gas = PROCESS_GAS;
    // allocate memory for returndata
    bytes memory _returnData = new bytes(_maxCopy);
    bytes memory _calldata = abi.encodeWithSignature(
      "handle(uint32,uint32,bytes32,bytes)",
      _m.origin(),
      _m.nonce(),
      _m.sender(),
      _m.body().clone()
    );
    // dispatch message to recipient
    // by assembly calling "handle" function
    // we call via assembly to avoid memcopying a very large returndata
    // returned by a malicious contract
    assembly {
      _success := call(
        _gas, // gas
        _recipient, // recipient
        0, // ether value
        add(_calldata, 0x20), // inloc
        mload(_calldata), // inlen
        0, // outloc
        0 // outlen
      )
      // limit our copy to 256 bytes
      _toCopy := returndatasize()
      if gt(_toCopy, _maxCopy) {
        _toCopy := _maxCopy
      }
      // Store the length of the copied bytes
      mstore(_returnData, _toCopy)
      // copy the bytes from returndata[0:_toCopy]
      returndatacopy(add(_returnData, 0x20), 0, _toCopy)
    }
    // emit process results
    emit Process(_messageHash, _success, _returnData);
    // reset re-entrancy guard
    entered = 1;
  }

  // ============ External Owner Functions ============

  /**
   * @notice Set optimistic timeout period for new roots
   * @dev Only callable by owner (Governance)
   * @param _optimisticSeconds New optimistic timeout period
   */
  function setOptimisticTimeout(uint256 _optimisticSeconds) external onlyOwner {
    optimisticSeconds = _optimisticSeconds;
    emit SetOptimisticTimeout(_optimisticSeconds);
  }

  /**
   * @notice Set Updater role
   * @dev MUST ensure that all roots signed by previous Updater have
   * been relayed before calling. Only callable by owner (Governance)
   * @param _updater New Updater
   */
  function setUpdater(address _updater) external onlyOwner {
    _setUpdater(_updater);
  }

  /**
   * @notice Set confirmAt for a given root
   * @dev To be used if in the case that fraud is proven
   * and roots need to be deleted / added. Only callable by owner (Governance)
   * @param _root The root for which to modify confirm time
   * @param _confirmAt The new confirmation time. Set to 0 to "delete" a root.
   */
  function setConfirmation(bytes32 _root, uint256 _confirmAt) external onlyOwner {
    uint256 _previousConfirmAt = confirmAt[_root];
    confirmAt[_root] = _confirmAt;
    emit SetConfirmation(_root, _previousConfirmAt, _confirmAt);
  }

  // ============ Public Functions ============

  /**
   * @notice Check that the root has been submitted
   * and that the optimistic timeout period has expired,
   * meaning the root can be processed
   * @param _root the Merkle root, submitted in an update, to check
   * @return TRUE iff root has been submitted & timeout has expired
   */
  function acceptableRoot(bytes32 _root) public view returns (bool) {
    uint256 _time = confirmAt[_root];
    if (_time == 0) {
      return false;
    }
    return block.timestamp >= _time;
  }

  /**
   * @notice Attempts to prove the validity of message given its leaf, the
   * merkle proof of inclusion for the leaf, and the index of the leaf.
   * @dev Reverts if message's MessageStatus != None (i.e. if message was
   * already proven or processed)
   * @dev For convenience, we allow proving against any previous root.
   * This means that witnesses never need to be updated for the new root
   * @param _leaf Leaf of message to prove
   * @param _proof Merkle proof of inclusion for leaf
   * @param _index Index of leaf in home's merkle tree
   * @return Returns true if proof was valid and `prove` call succeeded
   **/
  function prove(
    bytes32 _leaf,
    bytes32[32] calldata _proof,
    uint256 _index
  ) public returns (bool) {
    // ensure that message has not been proven or processed
    require(messages[_leaf] == MessageStatus.None, "!MessageStatus.None");
    // calculate the expected root based on the proof
    bytes32 _calculatedRoot = MerkleLib.branchRoot(_leaf, _proof, _index);
    // if the root is valid, change status to Proven
    if (acceptableRoot(_calculatedRoot)) {
      messages[_leaf] = MessageStatus.Proven;
      return true;
    }
    return false;
  }

  /**
   * @notice Hash of Home domain concatenated with "NOMAD"
   */
  function homeDomainHash() public view override returns (bytes32) {
    return _homeDomainHash(remoteDomain);
  }

  // ============ Internal Functions ============

  /**
   * @notice Moves the contract into failed state
   * @dev Called when a Double Update is submitted
   */
  function _fail() internal override {
    _setFailed();
  }

  /// @notice Hook for potential future use
  // solhint-disable-next-line no-empty-blocks
  function _beforeUpdate() internal {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {TypedMemView} from "../nomad-core/libs/TypedMemView.sol";

library LibCrossDomainProperty {
  // ============ Libraries ============

  using TypedMemView for bytes29;
  using TypedMemView for bytes;

  // ============ Enums ============

  /**
   * Contains information so the properties can be type-checked properly
   */
  enum Types {
    Invalid, // 0
    DomainAndSender // 1
  }

  // ============ Structs ============

  /**
   * Struct containing the domain and an address of the caller of a function on that
   * domain.
   */
  struct DomainAndSender {
    uint32 domain;
    address sender;
  }

  // ============ Constants ============

  uint256 private constant PROPERTY_LEN = 25; // 1 byte identifer + 4 bytes domain + 20 bytes address
  // default value is the TypedMemView null view
  bytes29 public constant EMPTY = hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
  bytes public constant EMPTY_BYTES = hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";

  // ============ Modifiers ============

  /**
   * @notice Asserts a property is of type `_t`
   * @param _view The stored property
   * @param _t The expected type
   */
  modifier typeAssert(bytes29 _view, Types _t) {
    _view.assertType(uint40(_t));
    _;
  }

  // ============ Internal Functions ============

  /**
   * @notice Checks that view is a valid property length
   * @param _view The bytes string
   * @return TRUE if length is valid
   */
  function isValidPropertyLength(bytes29 _view) internal pure returns (bool) {
    uint256 _len = _view.len();
    return _len == PROPERTY_LEN;
  }

  /**
   * @notice Checks that the property is of the specified type
   * @param _type the type to check for
   * @param _property The property
   * @return True if the property is of the specified type
   */
  function isType(bytes29 _property, Types _type) internal pure returns (bool) {
    return propertyType(_property) == uint8(_type);
  }

  /**
   * @notice Checks that the property is of type DomainAndSender
   * @param _property The property
   * @return True if the property is of type DomainAndSender
   */
  function isDomainAndSender(bytes29 _property) internal pure returns (bool) {
    return isValidPropertyLength(_property) && isType(_property, Types.DomainAndSender);
  }

  /**
   * @notice Retrieves the identifier from property
   * @param _property The property
   * @return The property type
   */
  function propertyType(bytes29 _property) internal pure returns (uint8) {
    return uint8(_property.indexUint(0, 1));
  }

  /**
   * @notice Converts to a Property
   * @param _view The property
   * @return The newly typed property
   */
  function tryAsProperty(bytes29 _view) internal pure returns (bytes29) {
    if (isValidPropertyLength(_view)) {
      return _view.castTo(uint40(Types.DomainAndSender));
    }
    return TypedMemView.nullView();
  }

  /**
   * @notice Asserts that the property is of type DomainAndSender
   * @param _view The property
   * @return The property
   */
  function mustBeProperty(bytes29 _view) internal pure returns (bytes29) {
    return tryAsProperty(_view).assertValid();
  }

  /**
   * @notice Retrieves the sender from a property
   * @param _property The property
   * @return The sender address
   */
  function sender(bytes29 _property) internal pure typeAssert(_property, Types.DomainAndSender) returns (address) {
    // before = 1 byte id + 4 bytes domain = 5 bytes
    return _property.indexAddress(5);
  }

  /**
   * @notice Retrieves the domain from a property
   * @param _property The property
   * @return The sender address
   */
  function domain(bytes29 _property) internal pure typeAssert(_property, Types.DomainAndSender) returns (uint32) {
    // before = 1 byte identifier = 1 byte
    return uint32(_property.indexUint(1, 4));
  }

  /**
   * @notice Creates a serialized property from components
   * @param _domain The domain
   * @param _sender The sender
   * @return The formatted view
   */
  function formatDomainAndSender(uint32 _domain, address _sender) internal pure returns (bytes29) {
    return abi.encodePacked(Types.DomainAndSender, _domain, _sender).ref(0).castTo(uint40(Types.DomainAndSender));
  }

  /**
   * @notice Creates a serialized property from components
   * @param _domain The domain
   * @param _sender The sender
   * @return The formatted view
   */
  function formatDomainAndSenderBytes(uint32 _domain, address _sender) internal pure returns (bytes memory) {
    return abi.encodePacked(Types.DomainAndSender, _domain, _sender);
  }

  /**
   * @notice Creates a serialized property from components
   * @param _property The bytes representation of the property
   */
  function parseDomainAndSenderBytes(bytes memory _property) internal pure returns (bytes29) {
    return mustBeProperty(_property.ref(0));
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

/**
 * @notice Contains RouterPermissionsManager related state
 * @param approvedRouters - Mapping of whitelisted router addresses
 * @param routerRecipients - Mapping of router withdraw recipient addresses.
 * If set, all liquidity is withdrawn only to this address. Must be set by routerOwner
 * (if configured) or the router itself
 * @param routerOwners - Mapping of router owners
 * If set, can update the routerRecipient
 * @param proposedRouterOwners - Mapping of proposed router owners
 * Must wait timeout to set the
 * @param proposedRouterTimestamp - Mapping of proposed router owners timestamps
 * When accepting a proposed owner, must wait for delay to elapse
 */
struct RouterPermissionsManagerInfo {
  mapping(address => bool) approvedRouters;
  mapping(address => address) routerRecipients;
  mapping(address => address) routerOwners;
  mapping(address => address) proposedRouterOwners;
  mapping(address => uint256) proposedRouterTimestamp;
}

library RouterPermissionsManagerLogic {
  // ========== Custom Errors ===========
  error RouterPermissionsManagerLogic__acceptProposedRouterOwner_notElapsed();
  error RouterPermissionsManagerLogic__setRouterRecipient_notNewRecipient();
  error RouterPermissionsManagerLogic__onlyRouterOwner_notRouterOwner();
  error RouterPermissionsManagerLogic__onlyProposedRouterOwner_notRouterOwner();
  error RouterPermissionsManagerLogic__onlyProposedRouterOwner_notProposedRouterOwner();
  error RouterPermissionsManagerLogic__removeRouter_routerEmpty();
  error RouterPermissionsManagerLogic__removeRouter_notAdded();
  error RouterPermissionsManagerLogic__setupRouter_routerEmpty();
  error RouterPermissionsManagerLogic__setupRouter_amountIsZero();
  error RouterPermissionsManagerLogic__proposeRouterOwner_notNewOwner();
  error RouterPermissionsManagerLogic__proposeRouterOwner_badRouter();

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
   * @notice Emitted when the owner of router is proposed
   * @param router - The address of the added router
   * @param prevProposed  - The address of the previous proposed
   * @param newProposed  - The address of the new proposed
   */
  event RouterOwnerProposed(address indexed router, address indexed prevProposed, address indexed newProposed);

  /**
   * @notice Emitted when the owner of router is accepted
   * @param router - The address of the added router
   * @param prevOwner  - The address of the previous owner of the router
   * @param newOwner  - The address of the new owner of the router
   */
  event RouterOwnerAccepted(address indexed router, address indexed prevOwner, address indexed newOwner);

  /**
   * @notice Asserts caller is the router owner (if set) or the router itself
   */
  function _onlyRouterOwner(address _router, address _owner) internal view {
    if (!((_owner == address(0) && msg.sender == _router) || _owner == msg.sender))
      revert RouterPermissionsManagerLogic__onlyRouterOwner_notRouterOwner();
  }

  /**
   * @notice Asserts caller is the proposed router. If proposed router is address(0), then asserts
   * the owner is calling the function (if set), or the router itself is calling the function
   */
  function _onlyProposedRouterOwner(
    address _router,
    address _owner,
    address _proposed
  ) internal view {
    if (_proposed == address(0)) {
      if (!((_owner == address(0) && msg.sender == _router) || _owner == msg.sender))
        revert RouterPermissionsManagerLogic__onlyProposedRouterOwner_notRouterOwner();
    } else {
      if (msg.sender != _proposed)
        revert RouterPermissionsManagerLogic__onlyProposedRouterOwner_notProposedRouterOwner();
    }
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
    RouterPermissionsManagerInfo storage routerInfo // mapping(address => address) storage routerOwners, // mapping(address => address) storage routerRecipients
  ) external {
    _onlyRouterOwner(router, routerInfo.routerOwners[router]);

    // Check recipient is changing
    address _prevRecipient = routerInfo.routerRecipients[router];
    if (_prevRecipient == recipient) revert RouterPermissionsManagerLogic__setRouterRecipient_notNewRecipient();

    // Set new recipient
    routerInfo.routerRecipients[router] = recipient;

    // Emit event
    emit RouterRecipientSet(router, _prevRecipient, recipient);
  }

  /**
   * @notice Current owner or router may propose a new router owner
   * @param router Router address to set recipient
   * @param proposed Proposed owner Address to set to router
   */
  function proposeRouterOwner(
    address router,
    address proposed,
    RouterPermissionsManagerInfo storage routerInfo
  ) external {
    _onlyRouterOwner(router, routerInfo.routerOwners[router]);

    // Check that proposed is different than current owner
    if (getRouterOwner(router, routerInfo.routerOwners) == proposed)
      revert RouterPermissionsManagerLogic__proposeRouterOwner_notNewOwner();

    // Check that proposed is different than current proposed
    address _currentProposed = routerInfo.proposedRouterOwners[router];
    if (_currentProposed == proposed) revert RouterPermissionsManagerLogic__proposeRouterOwner_badRouter();

    // Set proposed owner + timestamp
    routerInfo.proposedRouterOwners[router] = proposed;
    routerInfo.proposedRouterTimestamp[router] = block.timestamp;

    // Emit event
    emit RouterOwnerProposed(router, _currentProposed, proposed);
  }

  /**
   * @notice New router owner must accept role, or previous if proposed is 0x0
   * @param router Router address to set recipient
   */
  function acceptProposedRouterOwner(
    address router,
    uint256 _delay,
    RouterPermissionsManagerInfo storage routerInfo
  ) external {
    _onlyProposedRouterOwner(router, routerInfo.routerOwners[router], routerInfo.proposedRouterOwners[router]);

    address owner = getRouterOwner(router, routerInfo.routerOwners);

    // Check timestamp has passed
    if (block.timestamp - routerInfo.proposedRouterTimestamp[router] <= _delay)
      revert RouterPermissionsManagerLogic__acceptProposedRouterOwner_notElapsed();

    // Get current owner + proposed
    address _proposed = routerInfo.proposedRouterOwners[router];

    // Update the current owner
    routerInfo.routerOwners[router] = _proposed;

    // Reset proposal + timestamp
    if (_proposed != address(0)) {
      // delete proposedRouterOwners[router];
      routerInfo.proposedRouterOwners[router] = address(0);
    }
    routerInfo.proposedRouterTimestamp[router] = 0;

    // Emit event
    emit RouterOwnerAccepted(router, owner, _proposed);
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
    RouterPermissionsManagerInfo storage routerInfo
  ) internal {
    // Sanity check: not empty
    if (router == address(0)) revert RouterPermissionsManagerLogic__setupRouter_routerEmpty();

    // Sanity check: needs approval
    if (routerInfo.approvedRouters[router]) revert RouterPermissionsManagerLogic__setupRouter_amountIsZero();

    // Approve router
    routerInfo.approvedRouters[router] = true;

    // Emit event
    emit RouterAdded(router, msg.sender);

    // Update routerOwner (zero address possible)
    if (owner != address(0)) {
      routerInfo.routerOwners[router] = owner;
      emit RouterOwnerAccepted(router, address(0), owner);
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
  function removeRouter(address router, RouterPermissionsManagerInfo storage routerInfo) external {
    // Sanity check: not empty
    if (router == address(0)) revert RouterPermissionsManagerLogic__removeRouter_routerEmpty();

    // Sanity check: needs removal
    if (!routerInfo.approvedRouters[router]) revert RouterPermissionsManagerLogic__removeRouter_notAdded();

    // Update mapping
    routerInfo.approvedRouters[router] = false;

    // Emit event
    emit RouterRemoved(router, msg.sender);

    // Remove router owner
    address _owner = routerInfo.routerOwners[router];
    if (_owner != address(0)) {
      emit RouterOwnerAccepted(router, _owner, address(0));
      // delete routerOwners[router];
      routerInfo.routerOwners[router] = address(0);
    }

    // Remove router recipient
    address _recipient = routerInfo.routerRecipients[router];
    if (_recipient != address(0)) {
      emit RouterRecipientSet(router, _recipient, address(0));
      // delete routerRecipients[router];
      routerInfo.routerRecipients[router] = address(0);
    }
  }

  /**
   * @notice Returns the router owner if it is set, or the router itself if not
   * @dev Router owners have the ability to propose new owners and set recipients
   * @param _router The relevant router address
   * @param _routerOwners The mapping of owners for routers
   */
  function getRouterOwner(address _router, mapping(address => address) storage _routerOwners)
    internal
    view
    returns (address)
  {
    address _owner = _routerOwners[_router];
    return _owner == address(0) ? _router : _owner;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {IWrapped} from "../../interfaces/IWrapped.sol";
import {IStableSwap} from "../../interfaces/IStableSwap.sol";
import {ConnextMessage} from "../../nomad-xapps/contracts/connext/ConnextMessage.sol";
import {ITokenRegistry} from "../../nomad-xapps/interfaces/bridge/ITokenRegistry.sol";

import {SafeERC20Upgradeable, IERC20Upgradeable, AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

library AssetLogic {
  error AssetLogic__handleIncomingAsset_notAmount();
  error AssetLogic__handleIncomingAsset_ethWithErcTransfer();
  error AssetLogic__transferAssetFromContract_notNative();

  /**
   * @notice Handles transferring funds from msg.sender to the Connext contract.
   * @dev If using the native asset, will automatically wrap
   * @param _assetId - The address to transfer
   * @param _assetAmount - The specified amount to transfer. May not be the
   * actual amount transferred (i.e. fee on transfer tokens)
   * @param _fee - The fee amount in native asset included as part of the transaction that
   * should not be considered for the transfer amount.
   * @param _wrapper - The address of the wrapper for the native asset on this domain
   * @return The assetId of the transferred asset
   * @return The amount of the asset that was seen by the contract (may not be the specifiedAmount
   * if the token is a fee-on-transfer token)
   */
  function handleIncomingAsset(
    address _assetId,
    uint256 _assetAmount,
    uint256 _fee,
    IWrapped _wrapper
  ) internal returns (address, uint256) {
    uint256 trueAmount = _assetAmount;

    if (_assetId == address(0)) {
      if (msg.value != _assetAmount + _fee) revert AssetLogic__handleIncomingAsset_notAmount();

      // When transferring native asset to the contract, always make sure that the
      // asset is properly wrapped
      wrapNativeAsset(_assetAmount, _wrapper);
      _assetId = address(_wrapper);
    } else {
      if (msg.value != _fee) revert AssetLogic__handleIncomingAsset_ethWithErcTransfer();

      // Transfer asset to contract
      trueAmount = transferAssetToContract(_assetId, _assetAmount);
    }

    return (_assetId, trueAmount);
  }

  /**
   * @notice Wrap the native asset
   * @param _amount - The specified amount to wrap
   * @param _wrapper - The address of the wrapper for the native asset on this domain
   */
  function wrapNativeAsset(uint256 _amount, IWrapped _wrapper) internal {
    _wrapper.deposit{value: _amount}();
  }

  /**
   * @notice Transfer asset funds from msg.sender to the Connext contract.
   * @param _assetId - The address to transfer
   * @param _amount - The specified amount to transfer
   * @return The amount of the asset that was seen by the contract
   */
  function transferAssetToContract(address _assetId, uint256 _amount) internal returns (uint256) {
    // Validate correct amounts are transferred
    uint256 starting = IERC20Upgradeable(_assetId).balanceOf(address(this));

    SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(_assetId), msg.sender, address(this), _amount);
    // Calculate the *actual* amount that was sent here
    return IERC20Upgradeable(_assetId).balanceOf(address(this)) - starting;
  }

  /**
   * @notice Handles transferring funds from msg.sender to the Connext contract.
   * @dev If using the native asset, will automatically unwrap
   * @param _assetId - The address to transfer
   * @param _to - The account that will receive the withdrawn funds
   * @param _amount - The amount to withdraw from contract
   * @param _wrapper - The address of the wrapper for the native asset on this domain
   */
  function transferAssetFromContract(
    address _assetId,
    address _to,
    uint256 _amount,
    IWrapped _wrapper
  ) internal {
    // No native assets should ever be stored on this contract
    if (_assetId == address(0)) revert AssetLogic__transferAssetFromContract_notNative();

    if (_assetId == address(_wrapper)) {
      // If dealing with wrapped assets, make sure they are properly unwrapped
      // before sending from contract
      _wrapper.withdraw(_amount);
      AddressUpgradeable.sendValue(payable(_to), _amount);
    } else {
      // Transfer ERC20 asset
      SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(_assetId), _to, _amount);
    }
  }

  /**
   * @notice Swaps an adopted asset to the local (representation or canonical) nomad asset
   * @dev Will not swap if the asset passed in is the local asset
   * @param _canonical - The canonical token
   * @param _pool - The StableSwap pool
   * @param _tokenRegistry - The local nomad token registry
   * @param _asset - The address of the adopted asset to swap into the local asset
   * @param _amount - The amount of the adopted asset to swap
   * @return The amount of local asset received from swap
   * @return The address of asset received post-swap
   */
  function swapToLocalAssetIfNeeded(
    ConnextMessage.TokenId memory _canonical,
    IStableSwap _pool,
    ITokenRegistry _tokenRegistry,
    address _asset,
    uint256 _amount
  ) internal returns (uint256, address) {
    // Check to see if the asset must be swapped because it is not the local asset
    if (_canonical.id == bytes32(0)) {
      // This is *not* the adopted asset, meaning it must be the local asset
      return (_amount, _asset);
    }

    // Get the local token for this domain (may return canonical or representation)
    address local = _tokenRegistry.getLocalAddress(_canonical.domain, _canonical.id);

    // if theres no amount, no need to swap
    if (_amount == 0) {
      return (_amount, local);
    }

    // Check the case where the adopted asset *is* the local asset
    if (local == _asset) {
      // No need to swap
      return (_amount, _asset);
    }

    // Approve pool
    SafeERC20Upgradeable.safeApprove(IERC20Upgradeable(_asset), address(_pool), _amount);

    // Swap the asset to the proper local asset
    return (_pool.swapExact(_amount, _asset, local), local);
  }

  /**
   * @notice Swaps a local nomad asset for the adopted asset using the stored stable swap
   * @dev Will not swap if the asset passed in is the adopted asset
   * @param _canonicalToAdopted - Mapping of adopted to canonical on this domain
   * @param _adoptedToLocalPools - Mapping holding the AMMs for swapping in and out of local assets
   * @param _tokenRegistry - The local nomad token registry
   * @param _asset - The address of the local asset to swap into the adopted asset
   * @param _amount - The amount of the local asset to swap
   * @return The amount of adopted asset received from swap
   * @return The address of asset received post-swap
   */
  function swapFromLocalAssetIfNeeded(
    mapping(bytes32 => address) storage _canonicalToAdopted,
    mapping(bytes32 => IStableSwap) storage _adoptedToLocalPools,
    ITokenRegistry _tokenRegistry,
    address _asset,
    uint256 _amount
  ) internal returns (uint256, address) {
    // Get the token id
    (, bytes32 id) = _tokenRegistry.getTokenId(_asset);

    // If the adopted asset is the local asset, no need to swap
    address adopted = _canonicalToAdopted[id];
    if (adopted == _asset) {
      return (_amount, _asset);
    }

    // Approve pool
    IStableSwap pool = _adoptedToLocalPools[id];
    SafeERC20Upgradeable.safeApprove(IERC20Upgradeable(_asset), address(pool), _amount);

    // Otherwise, swap to adopted asset
    return (pool.swapExact(_amount, _asset, adopted), adopted);
  }
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