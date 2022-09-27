/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// This factory can be publicly used to deploy a contract using create2.

// How to use:
// Bruteforce salt using a generator, such as ERADICATE2. https://github.com/johguse/ERADICATE2
// Use this contract's address for the deployer address when generating salt.
// Before deploying, calculate the address using {calculateAddress} to ensure it's correct.
// Deploy your contract with {deployContract}.

// Additional notes:
// This contract will be the msg.sender when deploying.
// Your contract's constructor must be payable to forward ETH to the deploying contract.
// Ensure the checksummed address is what you want before deploying.
// You can't deploy a contract at an address where one already exists.
// You can redeploy a contract at an address if the contract has been deleted via selfdestruct.
// You can choose if you want your self destructible contract to be redeployable.
// You can call this contract using another contract to deploy a new contract using an interface or call().
// If you use call() to deploy a contract, you can use {toBytes} to generate bytes to send with the call.
// Someone can 'steal' your anticipated address if their transaction processes before yours, 
// but the bytecode and salt must match yours. This is unlikely because there's no benefit for doing this.

/**
    @notice Simple create2 contract factory. Optional nonredeployable.
 */
contract Create2ContractFactory {

    // Contracts that can't be redeployed.
    mapping (address => bool) internal _isNonredeployable;

    /**
        @notice If an address has enabled nonredeployability.
        @param account Address to check.
        @return nonredeployable If the account is nonredeployable.
    */
    function isNonredeployable(address account) public view returns (bool nonredeployable) {
        return _isNonredeployable[account];
    }

    /**
        @notice If an address is a contract past contruction.
        @dev Returns FALSE if {isContract} is accessed in a constructor.
        @param account Address to check.
        @param status If the account is a contract past construction.
    */
    function isContract(address account) public view returns (bool status) {
        return account.code.length > 0;
    }

    /**
        @notice Calculate a contract address deployed from an address using the bytecode and salt.
        @param bytecode The contract bytecode (starting with '0x').
        @param salt The salt used when deploying the contract with create2 (starting with '0x').
        @param deployer The address of the deployer. If you're using this contract to deploy, this contract's address is the deployer.
        @return calculatedAddress Address of the contract that will be deployed using `salt` and `bytecode`.
    */
    function calculateAddress(
        bytes memory bytecode,
        bytes32 salt,
        address deployer
    ) public pure returns (address calculatedAddress) {
        return address(
                    uint160(
                        uint256(
                            keccak256(
                                abi.encodePacked(
                                    bytes1(0xff),
                                    deployer, // this contract is the deployer
                                    salt,
                                    keccak256(abi.encodePacked(bytecode))
                                )
                            )
                        )
                    )
                );
    }

    /**
        @notice Deploy a contract using create2.
        @dev Can't deploy a contract at an address where one already exists unless it has been self destructed.
        @dev If your contract is large and fails when you try to deploy it, use {deployLargeContract}.
        @param bytecode The contract bytecode (starting with '0x').
        @param salt The salt used when deploying the contract with create2 (starting with '0x').
        @param anticipatedAddress The address you are expecting the contract to be deployed at.
        @param nonredeployable Disable redeployability if this contract is deleted. Can be 'false' and save gas if the contract can't be deleted.
        @return deployedAddress Address of contract deployed.
    */
    function deployContract(
        bytes memory bytecode,
        bytes32 salt,
        address anticipatedAddress,
        bool nonredeployable
    ) public payable returns (address deployedAddress) {

        // Revert if a contract already exists at the address.
        if (isContract(anticipatedAddress)) revert CONTRACT_EXISTS_AT_THIS_ADDRESS(anticipatedAddress);

        // Revert if contract is nonredeployable.
        if (isNonredeployable(anticipatedAddress)) revert CONTRACT_CANT_BE_REDEPLOYED(anticipatedAddress);

        // Calculate the contract address and ensure it matches. Checked prior to deploying to save gas.
        address calculatedAddress = calculateAddress(bytecode, salt, address(this));
        if (anticipatedAddress != calculatedAddress) revert CALCULATED_ADDRESS_DOES_NOT_MATCH(anticipatedAddress, calculatedAddress);

        // Deploy contract using create2.
        assembly {
            deployedAddress := create2(
                callvalue(),         // forward ETH
                add(bytecode, 0x20),    // bytecode
                mload(bytecode),        // bytecode length
                salt                    // salt
            )
        }

        // Revert if deployed address doesn't match.
        // Unsure if it's possible for the address from {calculateAddress} and create2 can be different, so we check again.
        if (anticipatedAddress != deployedAddress) revert DEPLOYED_ADDRESS_DOES_NOT_MATCH(anticipatedAddress, deployedAddress);
        
        // Prevent this contract from being redeployed if it's deleted.
        // `nonredeployable` does not need to be true if the contract can't be deleted.
        // Contract can only be deleted if it includes selfdestruct, delegatecall, and/or callcode.
        _isNonredeployable[deployedAddress] = nonredeployable;

        // An event is not emitted to save gas.

        return deployedAddress;
    }

    /**
        @notice Calculates bytes to send to this address when using call() from another contract. Ignore this if you're not using call().
        @param anticipatedAddress The address you are expecting the contract to be deployed at.
        @param bytecode The contract bytecode (starting with '0x').
        @param salt The salt used when deploying the contract with create2 (starting with '0x').
        @param nonredeployable Disable redeployability if this contract is deleted. Can be 'false' and save gas if the contract can't be deleted.
        @return data Bytes to send to this contract.
    */
    function toBytes(
        bytes memory bytecode,
        bytes32 salt,
        address anticipatedAddress,
        bool nonredeployable
    ) public pure returns (bytes memory data) {
        return abi.encodeWithSignature("deployContract(bytes,bytes32,address,bool)", bytecode, salt, anticipatedAddress, nonredeployable);
    }

    /**
        @notice Deploy a contract using create2 using an alternative method.
        @dev If your wallet states that gas can't be estimated, try again or try other salts.
        @param bytecode The contract bytecode (starting with '0x').
        @param salt The salt used when deploying the contract with create2 (starting with '0x').
        @param anticipatedAddress The address you are expecting the contract to be deployed at.
        @param nonredeployable Disable redeployability if this contract is deleted. Can be 'false' and save gas if the contract can't be deleted.
        @return deployedAddress Address of contract deployed.
    */
    function deployLargeContract(
        bytes memory bytecode,
        bytes32 salt,
        address anticipatedAddress,
        bool nonredeployable
    ) public payable returns (address deployedAddress) {
        // Deploy and return address.
        return 
            address(
                uint160(
                    uint256(
                        bytes32(
                            interaction(
                                payable(address(this)),     // Address to call.
                                toBytes(                    // Get data to send in the call.
                                    bytecode, 
                                    salt, 
                                    anticipatedAddress, 
                                    nonredeployable
                                )
                            )
                        )
                    )
                )
            );
    }

    /**
        @notice Allows anyone to interact with any contract (including this one) using this contract as the msg.sender.
    */
    function interaction(
        address payable account, 
        bytes memory data
    ) public payable returns (bytes memory reason) {
        (bool success, bytes memory _reason) = account.call{value: msg.value}(data); // Call/send to account.
        if (!success) { // If not successful.
            if (reason.length == 0) { // If no reason.
                revert UNABLE_TO_INTERACT_WITH_THE_CONTRACT(account); // Generic error.
            } else {
                assembly {
                    revert(add(32, reason), mload(reason)) // Error returned from contract.
                }
            }
        }
        return _reason;
    }

}

/// @notice Unable to interact with the contract.
error UNABLE_TO_INTERACT_WITH_THE_CONTRACT(address account);

/// @notice Contract can't be redeployed.
error CONTRACT_CANT_BE_REDEPLOYED(address anticipated);

/// @notice Contract exists at this address.
error CONTRACT_EXISTS_AT_THIS_ADDRESS(address anticipated);

/// @notice Calculated addresss does not match.
error CALCULATED_ADDRESS_DOES_NOT_MATCH(address anticipated, address calculated);

/// @notice Deployed addresss does not match.
error DEPLOYED_ADDRESS_DOES_NOT_MATCH(address anticipated, address deployed);