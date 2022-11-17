/**
 *Submitted for verification at Etherscan.io on 2022-11-17
*/

// File contracts/Create3Factory.sol

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

/**
 * @title A library for deploying contracts EIP-3171 style.
 * @author Agustin Aguilar <[email protected]>
 */
contract Create3Factory {
    /**
     * @notice The bytecode for a contract that proxies the creation of another contract
     * @dev If this code is deployed using CREATE2 it can be used to decouple `creationCode` from the child contract
     * address 0x67363d3d37363d34f03d5260086018f3:
     *
     * 0x00  0x67  0x67XXXXXXXXXXXXXXXX  PUSH8 bytecode  0x363d3d37363d34f0
     * 0x01  0x3d  0x3d                  RETURNDATASIZE  0 0x363d3d37363d34f0
     * 0x02  0x52  0x52                  MSTORE
     * 0x03  0x60  0x6008                PUSH1 08        8
     * 0x04  0x60  0x6018                PUSH1 18        24 8
     * 0x05  0xf3  0xf3                  RETURN
     *
     * 0x363d3d37363d34f0:
     *
     * 0x00  0x36  0x36                  CALLDATASIZE    cds
     * 0x01  0x3d  0x3d                  RETURNDATASIZE  0 cds
     * 0x02  0x3d  0x3d                  RETURNDATASIZE  0 0 cds
     * 0x03  0x37  0x37                  CALLDATACOPY
     * 0x04  0x36  0x36                  CALLDATASIZE    cds
     * 0x05  0x3d  0x3d                  RETURNDATASIZE  0 cds
     * 0x06  0x34  0x34                  CALLVALUE       val 0 cds
     * 0x07  0xf0  0xf0                  CREATE          addr
     */
    bytes public constant PROXY_CHILD_BYTECODE = hex'67_36_3d_3d_37_36_3d_34_f0_3d_52_60_08_60_18_f3';

    // KECCAK_PROXY_BYTECODE = keccak256(PROXY_CHILD_BYTECODE);
    bytes32 public constant KECCAK_PROXY_BYTECODE = 0x21c35dbe1b344a2488cf3321d6ce542f8e9f305544ff09e4993a62319a497c1f;

    /**
     * @notice Creates a new contract with given `_creationCode` and `_salt`
     * @param _salt Salt of the contract creation, resulting address will be derivated from this value only
     * @param _creationCode Creation code (constructor) of the contract to be deployed, this value doesn't affect the resulting address
     * @return addr of the deployed contract, reverts on error
     */
    function create3(bytes32 _salt, bytes memory _creationCode) external returns (address addr) {
        return create3WithValue(_salt, _creationCode, 0);
    }

    /**
     * @notice Creates a new contract with given `_creationCode` and `_salt`
     * @param _salt Salt of the contract creation, resulting address will be derivated from this value only
     * @param _creationCode Creation code (constructor) of the contract to be deployed, this value doesn't affect the resulting address
     * @param _value In WEI of ETH to be forwarded to child contract
     * @return addr of the deployed contract, reverts on error
     */
    function create3WithValue(bytes32 _salt, bytes memory _creationCode, uint256 _value) public returns (address addr) {
        // Creation code
        bytes memory creationCode = PROXY_CHILD_BYTECODE;

        // Get target final address
        addr = addressOf(_salt);
        require(codeSize(addr) == 0, 'CREATE3_TARGET_ALREADY_EXISTS');

        // Create CREATE2 proxy
        address proxy;
        assembly {
            proxy := create2(0, add(creationCode, 32), mload(creationCode), _salt)
        }
        require(proxy != address(0), 'CREATE3_ERROR_CREATING_PROXY');

        // Call proxy with final init code
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = proxy.call{ value: _value }(_creationCode);
        require(success && codeSize(addr) > 0, 'CREATE3_ERROR_CREATING_CONTRACT');
    }

    /**
     * @notice Computes the resulting address of a contract deployed using address(this) and the given `_salt`
     * @param _salt Salt of the contract creation, resulting address will be derivated from this value only
     * @return addr of the deployed contract, reverts on error
     * @dev The address creation formula is: keccak256(rlp([keccak256(0xff ++ address(this) ++ _salt ++ keccak256(childBytecode))[12:], 0x01]))
     */
    function addressOf(bytes32 _salt) public view returns (address) {
        bytes32 addr = keccak256(abi.encodePacked(hex'ff', address(this), _salt, KECCAK_PROXY_BYTECODE));
        address proxy = address(uint160(uint256(addr)));
        return address(uint160(uint256(keccak256(abi.encodePacked(hex'd6_94', proxy, hex'01')))));
    }

    /**
     * @notice Returns the size of the code on a given address
     * @param _addr Address that may or may not contain code
     * @return size of the code on the given `_addr`
     */
    function codeSize(address _addr) internal view returns (uint256 size) {
        assembly {
            size := extcodesize(_addr)
        }
    }
}