/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0;

/**
 * @dev this contract will be a fallback contract
 * to provide the full collection and functionality
 * of the GoE contract collections.
 */
contract Beta {

    enum Operation {
        Call,
        DelegateCall
    }

    function execute(address to, uint256 value, bytes memory data, Operation operation, uint256 txGas) internal returns (bool success){
        if (operation == Operation.Call)
            success = executeCall(to, value, data, txGas);
        else if (operation == Operation.DelegateCall)
            success = executeDelegateCall(to, data, txGas);
        else
            success = false;
    }

    function executeCall(address to, uint256 value, bytes memory data, uint256 txGas)internal returns (bool success){
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
        }
    }

    function executeDelegateCall(address to, bytes memory data, uint256 txGas) internal returns (bool success){
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := delegatecall(txGas, to, add(data, 0x20), mload(data), 0, 0)
        }
    }

    function execTransactionFromModule(address to, uint256 value, bytes memory data, Operation operation) public returns (bool success){
        // Execute transaction without further confirmations.
        success = execute(to, value, data, operation, gasleft());
    }
    
    function execTransactionFromModuleReturnData(address to, uint256 value, bytes memory data, Operation operation) public returns (bool success, bytes memory returnData){
        success = execTransactionFromModule(to, value, data, operation);
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            // Load free memory location
            let ptr := mload(0x40)
            // We allocate memory for the return data by setting the free memory location to
            // current free memory location + data size + 32 bytes for data size value
            mstore(0x40, add(ptr, add(returndatasize(), 0x20)))
            // Store the size
            mstore(ptr, returndatasize())
            // Store the data
            returndatacopy(add(ptr, 0x20), 0, returndatasize())
            // Point the return data to the correct memory location
            returnData := ptr
        }
    }

    function depositETH() public payable {
        //pass
    }
	

}