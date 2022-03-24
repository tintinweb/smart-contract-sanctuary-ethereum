pragma solidity ^0.8.0;

contract SimpleFactory {

    /**
    * @dev Deploys any contract using create2 asm opcode creating the same address for same bytecode
     * @param bytecode - bytecode packed with params to deploy
     * @param constructorParams - ctor params encoded with abi.encode
     * @param salt - salt required by create2
     */
    function deployCreate2WithParams(bytes memory bytecode, bytes memory constructorParams, bytes32 salt) public returns(address) {
        return deployCreate2(abi.encodePacked(bytecode, constructorParams), salt);
    }

    /**
    * @dev Deploys any contract using create2 asm opcode creating the same address for same bytecode
     * @param bytecode - bytecode packed with params to deploy
     * @param salt - salt required by create2
     */
    function deployCreate2(bytes memory bytecode, bytes32 salt) public returns(address) {
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
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}