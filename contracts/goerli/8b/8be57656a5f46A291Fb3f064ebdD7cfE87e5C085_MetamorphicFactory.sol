//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

// source code from https://ethereum-blockchain-developer.com/110-upgrade-smart-contracts/12-metamorphosis-create2/

// I replaced the CREATE2 address calculation with the OpenZeppelin library for readability

contract MetamorphicFactory {
    mapping(address => address) _implementations;

    event Deployed(address _addr);

    // simple deploy
    function deploy(uint256 salt, bytes calldata bytecode) public {
        bytes memory implInitCode = bytecode;

        // assign the initialization code for the metamorphic contract.
        bytes memory metamorphicCode = (
            hex"5860208158601c335a63aaf10f428752fa158151803b80938091923cf3"
        );

        // determine the address of the metamorphic contract.
        address metamorphicContractAddress = _getMetamorphicContractAddress(
            salt,
            metamorphicCode
        );

        // declare a variable for the address of the implementation contract.
        address implementationContract;

        // load implementation init code and length, then deploy via CREATE.
        /* solhint-disable no-inline-assembly */
        assembly {
            let encoded_data := add(0x20, implInitCode) // load initialization code.
            let encoded_size := mload(implInitCode) // load init code's length.
            implementationContract := create(
                // call CREATE with 3 arguments.
                0, // do not forward any endowment.
                encoded_data, // pass in initialization code.
                encoded_size // pass in init code's length.
            )
        } /* solhint-enable no-inline-assembly */

        //first we deploy the code we want to deploy on a separate address
        // store the implementation to be retrieved by the metamorphic contract.
        _implementations[metamorphicContractAddress] = implementationContract;

        address addr;
        assembly {
            let encoded_data := add(0x20, metamorphicCode) // load initialization code.
            let encoded_size := mload(metamorphicCode) // load init code's length.
            addr := create2(0, encoded_data, encoded_size, salt)
        }

        require(
            addr == metamorphicContractAddress,
            "Failed to deploy the new metamorphic contract."
        );

        emit Deployed(addr);
    }

    /**
     * @dev Internal view function for calculating a metamorphic contract address
     * given a particular salt.
     */
    function _getMetamorphicContractAddress(
        uint256 salt,
        bytes memory metamorphicCode
    ) internal view returns (address) {
        return
            Create2.computeAddress(
                bytes32(salt),
                keccak256(abi.encodePacked(metamorphicCode)),
                address(this)
            );
    }

    function getMetamorphicContractAddress(uint256 salt)
        external
        view
        returns (address)
    {
        bytes memory mmCode = (
            hex"5860208158601c335a63aaf10f428752fa158151803b80938091923cf3"
        );
        return
            Create2.computeAddress(
                bytes32(salt),
                keccak256(abi.encodePacked(mmCode)),
                address(this)
            );
    }

    //those two functions are getting called by the metamorphic Contract
    function getImplementation()
        external
        view
        returns (address implementation)
    {
        return _implementations[msg.sender];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}