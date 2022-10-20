// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/proxy/Clones.sol';
import './interfaces/ILiquidityGauge.sol';

///@notice Allows creating Liquidity gauges with a low cost
///@dev Anyone can create gauges, but only some are added to the GaugeController
contract GaugeFactory {
    // ==========
    // *DATA*
    // ==========

    /// @notice initial gauge reference that's being cloned
    address public gaugeReference;

    // ==========
    // *EVENTS*
    // ==========
    /// @notice emitted when a new gauge is created
    event GaugeCreated(address indexed _owner, address indexed _gauge);

    // ==========
    // * METHODS *
    // ==========

    ///@notice creates a new GaugeFactory contract
    ///@param _gaugeReference an existing gauge address
    constructor(address _gaugeReference) {
        require(_gaugeReference != address(0), 'gauge not valid');
        gaugeReference = _gaugeReference;
    }

    /// @notice clones the gauge reference and initializes it with the new values
    /// @dev the owner of the new gauge will be msg.sender
    /// @param _token deposit token address
    /// @param _reward reward token address
    /// @param _distributor the GaugeDistributor address
    function createGauge(address _token, address _reward, address _distributor) public returns (address newGauge) {
        newGauge = Clones.clone(gaugeReference);

        ILiquidityGauge(newGauge).init(_token, _reward, msg.sender, _distributor);
        emit GaugeCreated(msg.sender, newGauge);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Liquidity gauge interface
interface ILiquidityGauge {
    function init(
        address _token,
        address _reward,
        address _owner,
        address _distributor
    ) external;

    function addRewards(uint256 _amount) external;

    function deposit(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}