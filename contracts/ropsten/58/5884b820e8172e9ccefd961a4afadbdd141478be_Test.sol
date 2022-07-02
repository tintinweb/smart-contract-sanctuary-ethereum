/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface NewFactorItf {
    // All the Factor should override the function
    function NewOneContract(bytes calldata args) external returns (address);
}

contract Test {
    string public name;
    string public symbol;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }
}

// inherit the erc20 contract
contract ERC20Factor is NewFactorItf {
    address[] test_contract_list;
    address[] all_contract_list;

    // global event
    event ENewContractGen(address indexed test_contract_address);

    // @notice !!! the args must contain the contract pargams

    function NewOneContract(bytes calldata args)
        external
        override
        returns (address test_contract_address)
    {
        // do new a erc20 contract;

        // step1 : get the creationcode;
        
        bytes memory code_byte = type(Test).creationCode;
        
        bytes memory bytecode = abi.encodePacked(code_byte, args);
        // step2 : use the arg. packed the arg : notice the args is the salt
        bytes32 salt = keccak256(abi.encodePacked(bytecode, block.timestamp));
        // step3 : concat the ERC20.creationCode + args for contract

        assembly {
            test_contract_address := create2(
                0,
                add(bytecode, 32),
                mload(bytecode),
                salt
            )
        }
        if (test_contract_address != address(0x0)) {
            // suc
            emit ENewContractGen(test_contract_address);
            test_contract_list.push(test_contract_address);
        }

        all_contract_list.push(test_contract_address);

        return test_contract_address;
    }

    function getAllContractList() public view returns(address[] memory) {
        return all_contract_list;
    }
}