// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/proxy/Clones.sol';

interface ISeriesToken {
  function initialize(string memory name, string memory symbol) external;
  function mint(address to, uint256 amount) external;
  function transferOwnership(address newOwner) external;
}

interface IOtoCoGovernor {
  function initialize(
    address _token, 
    address _firstManager, 
    address[] calldata _allowed, 
    uint256 _votingPeriod, 
    string calldata _contractName
  ) external;
}

/**
 * Tokenized LLCs factory plugin
 */
contract GovernorInitializer {

    /**
    * Create a new Gnovernor instance contract and return it.
    *
    * @dev governorInstance the token instance to be cloned
    * @param pluginData Encoded parameters to create a new token.
     */
    function setup(address governorInstance, bytes calldata pluginData) 
      public payable returns (address governorProxy, address tokenProxy) 
    {
      (
        // Token and Governor name
        string memory name,				
        // Token Symbol
        string memory symbol,			
        address[] memory allowedContracts,
        // [0] Manager address
        // [1] Token Source to be Cloned
        // [2..n] Member Addresses
        address[] memory addresses,
        // [0] Members size,
        // [1] Voting period in days
        // [2..n] Member shares 
        uint256[] memory settings				
      ) = abi.decode(pluginData, (string, string, address[], address[], uint256[]));
      
      bytes32 salt = 
        keccak256(abi.encode(msg.sender, pluginData));
      
      ISeriesToken newToken = 
        ISeriesToken(Clones.cloneDeterministic(addresses[1], salt));
      IOtoCoGovernor newGovernor = 
        IOtoCoGovernor(Clones.cloneDeterministic(governorInstance, salt));
      
      // Initialize token
      newToken.initialize(name, symbol);
      
      // Count the amount of members to assign balances
      uint256 index = settings[0];
      while (index > 0) {
      	// Members start at addresses index 2
      	// Shares start at settings index 2
        newToken.mint(addresses[index+1], settings[index+1]);
        --index;
      }
      // Transfer ownership of the token to Governor contract
      newToken.transferOwnership(address(newGovernor));
      // Initialize governor
      newGovernor.initialize(
        address(newToken), 
        addresses[0], 
        allowedContracts, 
        settings[1], 
        name
      );
      
      governorProxy = address(newGovernor);
      tokenProxy = address(newToken);
    }
}