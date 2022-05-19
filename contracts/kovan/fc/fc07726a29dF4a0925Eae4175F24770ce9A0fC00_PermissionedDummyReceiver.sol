// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import '../../interfaces/xapps/IDataStruct.sol';
import '../../interfaces/external/IConnextHandler.sol';
import '../../interfaces/external/IExecutor.sol';

contract PermissionedDummyReceiver {
  address[] public receivedAddress;
  bool[] public receivedPrevious;
  uint256[] public receivedTimestamp;
  int56[] public receivedPrevTick;
  int56[] public receivedCurrentTick;

  address public originContract;
  uint32 public originDomain;
  address public executor;

  event DataReceived(IDataStruct.PoolData _data);

  constructor(uint32 _originDomain, address payable _connext) {
    originDomain = _originDomain;
    executor = IConnextHandler(_connext).getExecutor();
  }

  function setOriginContract(address _originContract) public {
    originContract = _originContract;
  }

  function storeReceivedData(IDataStruct.PoolData[] calldata _data) public onlyExecutor {
    uint256 _dataLength = _data.length;

    for (uint256 i = 0; i < _dataLength; ) {
      receivedAddress.push(_data[i].poolAddress);
      receivedPrevious.push(_data[i].hasPrevious);
      receivedTimestamp.push(_data[i].observedAt);
      receivedPrevTick.push(_data[i].previousTick);
      receivedCurrentTick.push(_data[i].currentTick);
      emit DataReceived(_data[i]);
      unchecked {
        i++;
      }
    }
  }

  modifier onlyExecutor() {
    require(
      IExecutor(msg.sender).originSender() == originContract && IExecutor(msg.sender).origin() == originDomain && msg.sender == executor,
      'Expected origin contract on origin domain called by Executor'
    );
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface IDataStruct {
  // Structs
  struct PoolData {
    address poolAddress;
    bool hasPrevious;
    uint256 observedAt;
    int56 previousTick;
    int56 currentTick;
  }

  // Events
  // TODO: Do we ever emit this event?
  /// @notice Emitted when the pool data is decoded
  /// @param _data The decoded pool data
  event DecodedData(PoolData[] _data);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

// TODO: fix this
// import '../nomad-xapps/contracts/connext/ConnextMessage.sol';

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
   * @param callback - The address on the origin domain of the callback contract
   * @param callbackFee - The relayer fee to execute the callback
   * @param forceSlow - If true, will take slow liquidity path even if it is not a permissioned call
   * @param receiveLocal - If true, will use the local nomad asset on the destination instead of adopted.
   */
  struct CallParams {
    address to;
    bytes callData;
    uint32 originDomain;
    uint32 destinationDomain;
    bool forceSlow;
    bool receiveLocal;
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
    address _relayerFeeRouter,
    address payable _promiseRouter
  ) external;

  function setupRouter(
    address router,
    address owner,
    address recipient
  ) external;

  function removeRouter(address router) external;

  // function addStableSwapPool(ConnextMessage.TokenId calldata canonical, address stableSwapPool) external;

  // function setupAsset(
  //   ConnextMessage.TokenId calldata canonical,
  //   address adoptedAssetId,
  //   address stableSwapPool
  // ) external;

  function removeAssetId(bytes32 canonicalId, address adoptedAssetId) external;

  function setMaxRoutersPerTransfer(uint256 newMaxRouters) external;

  function addRelayer(address relayer) external;

  function removeRelayer(address relayer) external;

  // ============ Public Functions ===========

  function getExecutor() external returns (address);

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

  function isApprovedRelayer(address _relayer) external view returns (bool);
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

  function amount() external returns (uint256);

  function execute(
    bytes32 _transferId,
    uint256 _amount,
    address payable _to,
    address _assetId,
    bytes memory _properties,
    bytes calldata _callData
  ) external payable returns (bool success, bytes memory returnData);
}