// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/**
 * @title Singleton Factory (EIP-2470)
 * @dev Extended version from EIP-2470 for testing purposes
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
 */
contract Create2Factory {
    event Deployed(address createdContract);

    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}. Note that
     * a contract cannot be deployed twice using the same salt.
     */
    function deploy(bytes memory bytecode, bytes32 salt)
        external
        returns (address)
    {
        address addr;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), 'Create2: Failed on deploy');
        emit Deployed(addr);
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the `bytecode`
     * or `salt` will result in a new destination address.
     */
    function computeAddress(bytes memory bytecode, bytes32 salt)
        external
        view
        returns (address)
    {
        return computeAddress(salt, bytecode, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes memory bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 bytecodeHashHash = keccak256(bytecodeHash);
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHashHash)
        );
        return address(bytes20(_data << 96));
    }
}