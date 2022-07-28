// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import {IExecutor} from "../Interfaces/ExternalInterfaces/IExecutor.sol";
import {IConnextHandler} from "../Interfaces/ExternalInterfaces/IConnextHandler.sol";

/**
 * @title Target
 * @notice A contrived example target contract.
 */
contract Target {
  event UpdateCompleted(address sender, uint256 newValue, bool authenticated);

  uint256 public value;

  // The address of Source.sol
  address public originContract;

  // The origin Domain ID
  uint32 public originDomain;

  // The address of the Connext Executor contract
  IExecutor public executor;

  // A modifier for authenticated function calls.
  // Note: This is an important security consideration. If your target
  //       contract function is meant to be authenticated, it must check
  //       that the originating call is from the correct domain and contract.
  //       Also, check that the msg.sender is the Connext Executor address.
  modifier onlyExecutor() {
    require(
      IExecutor(msg.sender).originSender() == originContract &&
        IExecutor(msg.sender).origin() == originDomain &&
        msg.sender == address(executor),
      "Expected origin contract on origin domain called by Executor"
    );
    _;
  }

  constructor(
    address _originContract,
    uint32 _originDomain,
    IConnextHandler _connext
  ) {
    originContract = _originContract;
    originDomain = _originDomain;
    executor = _connext.executor();
  }

  // Unauthenticated function
  function updateValueUnauthenticated(uint256 newValue) 
    external 
    returns (uint256)
  {
    value = newValue;

    emit UpdateCompleted(msg.sender, newValue, false);
    return newValue;
  }

  // Authenticated function
  function updateValueAuthenticated(uint256 newValue) 
    external onlyExecutor 
    returns (uint256)
  {
    value = newValue;

    emit UpdateCompleted(msg.sender, newValue, true);
    return newValue;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

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

  function originSender() external returns (address);
  function origin() external returns (uint32);
  function execute(ExecutorArgs calldata _args) external payable returns (bool success, bytes memory returnData);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {XCallArgs} from "../../libraries/LibConnextStorage.sol";
import {IExecutor} from "./IExecutor.sol";

interface IConnextHandler {
  function xcall(XCallArgs calldata _args) external payable returns (bytes32);
  function executor() external view returns(IExecutor);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

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