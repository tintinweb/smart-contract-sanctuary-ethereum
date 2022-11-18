// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {IEmergencyRegistry, CrossChainUtils} from './interfaces/IEmergencyRegistry.sol';

/**
 * @dev Registry smart contract, to be used by the Aave Governance through one of its Executors to signal if an emergency mode should be triggered on a different network
 */
contract EmergencyRegistry is IEmergencyRegistry, Ownable {
  mapping(CrossChainUtils.Chains => int256) internal _emergencyStateByNetwork;

  /// @inheritdoc IEmergencyRegistry
  function getNetworkEmergencyCount(CrossChainUtils.Chains chainId)
  external
  view
  returns (int256)
  {
    return _emergencyStateByNetwork[chainId];
  }

  /// @inheritdoc IEmergencyRegistry
  function setEmergency(CrossChainUtils.Chains[] memory emergencyChains)
  external
  onlyOwner
  {
    for (uint256 i = 0; i < emergencyChains.length; i++) {
      unchecked {
        _emergencyStateByNetwork[emergencyChains[i]]++;
      }

      emit NetworkEmergencyStateUpdated(
        emergencyChains[i],
        _emergencyStateByNetwork[emergencyChains[i]]
      );
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CrossChainUtils} from "ghost-crosschain-infra/contracts/CrossChainUtils.sol";

interface IEmergencyRegistry {
  /**
   * @dev emitted when there is a change of the emergency state of a network
   * @param chainId id of the network updated
   * @param emergencyNumber indicates the emergency number for network chainId
   */
  event NetworkEmergencyStateUpdated(
    CrossChainUtils.Chains indexed chainId,
    int256 emergencyNumber
  );

  /**
   * @dev method to get the current state of emergency for a network
   * @param chainId id of the network to check
   * @return bool indicating if a network is in emergency state
   */
  function getNetworkEmergencyCount(CrossChainUtils.Chains chainId)
  external
  view
  returns (int256);

  /**
   * @dev sets the state of emergency for determined networks
   * @param emergencyChains list of chains which will move to emergency mode
   */
  function setEmergency(CrossChainUtils.Chains[] memory emergencyChains)
  external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library CrossChainUtils {
  enum Chains {
    Null_network, // to not use 0
    EthMainnet,
    Polygon,
    Avalanche,
    Harmony,
    Arbitrum,
    Fantom,
    Optimism,
    Goerli,
    AvalancheFuji,
    OptimismGoerli,
    PolygonMumbai,
    ArbitrumGoerli,
    FantomTestnet,
    HarmonyTestnet
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/8b778fa20d6d76340c5fac1ed66c80273f05b95a

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/8b778fa20d6d76340c5fac1ed66c80273f05b95a

pragma solidity ^0.8.0;

import './Context.sol';

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
    require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
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