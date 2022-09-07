// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IEmergencyRegistry, CrosschainUtils} from '../interfaces/IEmergencyRegistry.sol';

contract EmergencyInitiatorMock {
  IEmergencyRegistry public immutable EMERGENCY_REGISTRY;

  constructor(address emergencyRegistry) {
    EMERGENCY_REGISTRY = IEmergencyRegistry(emergencyRegistry);
  }

  function startEmergencyOnChain(CrosschainUtils.Chains chainId) external {
    CrosschainUtils.Chains[] memory chains = new CrosschainUtils.Chains[](1);
    chains[0] = chainId;

    EMERGENCY_REGISTRY.setEmergency(chains);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CrosschainUtils} from '../CrosschainUtils.sol';

interface IEmergencyRegistry {
  /**
   * @dev emitted when there is a change of the emergency state of a network
   * @param chainId id of the network updated
   * @param emergencyNumber indicates the emergency number for network chainId
   */
  event NetworkEmergencyStateUpdated(
    CrosschainUtils.Chains indexed chainId,
    int256 emergencyNumber
  );

  /**
   * @dev method to get the current state of emergency for a network
   * @param chainId id of the network to check
   * @return bool indicating if a network is in emergency state
   */
  function getNetworkEmergencyCount(CrosschainUtils.Chains chainId)
  external
  view
  returns (int256);

  /**
   * @dev sets the state of emergency for determined networks
   * @param emergencyChains list of chains which will move to emergency mode
   */
  function setEmergency(CrosschainUtils.Chains[] memory emergencyChains)
  external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library CrosschainUtils {
  enum Chains {
    Null_network, // to not use 0
    EthMainnet,
    Polygon,
    Avalanche,
    Harmony,
    Arbitrum,
    Phantom
  }
  enum AccessControl {
    Level_null, // to not use 0
    Level_1, // LEVEL_1 - short executor before, listing assets, changes of assets params, updates of the protocol etc
    Level_2 // LEVEL_2 - long executor before, mandate provider updates
  }
  // should fit into uint256 imo
  struct Payload {
    // our own id for the chain, rationality is optimize the space, because chainId by the standard can be uint256,
    //TODO: the limit of enum is 256, should we care about it, or we will never reach this point?
    Chains chain;
    AccessControl accessLevel;
    address mandateProvider; // address which holds the logic to execute after success proposal voting
    uint40 payloadId; // number of the payload placed to mandateProvider, max is: ~10¹²
    uint40 __RESERVED; // reserved for some future needs
  }
}