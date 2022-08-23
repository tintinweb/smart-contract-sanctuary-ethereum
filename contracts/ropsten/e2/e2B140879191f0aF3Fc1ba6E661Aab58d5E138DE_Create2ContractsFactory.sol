//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "../interfaces/factory/ICreate2ContractsFactory.sol";

contract Create2ContractsFactory is ICreate2ContractsFactory {
    /**
     * @dev Deploys any contract using create2 asm opcode creating the same address for same bytecode
     * @param bytecode - bytecode packed with params to deploy
     * @param constructorParams - ctor params encoded with abi.encode
     * @param salt - salt required by create2
     */
    function deployCreate2WithParams(
        bytes memory bytecode,
        bytes memory constructorParams,
        bytes32 salt
    ) public virtual override returns (address) {
        address newContract = deployCreate2(
            abi.encodePacked(bytecode, constructorParams),
            salt
        );

        emit NewContractDeployed(
            newContract,
            bytecode,
            constructorParams,
            salt
        );

        return newContract;
    }

    /**
     * @dev Deploys any contract using create2 asm opcode creating the same address for same bytecode
     * @param bytecode - bytecode packed with params to deploy
     * @param salt - salt required by create2
     */
    function deployCreate2(bytes memory bytecode, bytes32 salt)
        public
        virtual
        override
        returns (address)
    {
        address newContract = _deployCreate2(bytecode, salt);
        emit NewContractDeployed(newContract, bytecode, "", salt);
        return newContract;
    }

    function _deployCreate2(bytes memory bytecode, bytes32 salt)
        public
        virtual
        returns (address)
    {
        address newContract;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            newContract := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        require(_isContract(newContract), "Deploy failed");

        return newContract;
    }

    /**
     * @dev Returns True if provided address is a contract
     * @param account Prospective contract address
     * @return True if there is a contract behind the provided address
     */
    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface ICreate2ContractsFactory {
    event NewContractDeployed(
        address indexed contractAddress,
        bytes bytecode,
        bytes constructorParams,
        bytes32 salt
    );

    function deployCreate2WithParams(
        bytes memory bytecode,
        bytes memory constructorParams,
        bytes32 salt
    ) external returns (address);

    function deployCreate2(bytes memory bytecode, bytes32 salt)
        external
        returns (address);
}