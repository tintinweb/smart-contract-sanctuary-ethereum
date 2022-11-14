// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
     __        __   ___  __   __   ___  __        __       ___  __  
    /__` |  | |__) |__  |__) |  \ |__  |__) |    /  \ \ / |__  |__) 
    .__/ \__/ |    |___ |  \ |__/ |___ |    |___ \__/  |  |___ |  \ 

    SuperDeployer by SuperCollectiv

    ABOUT
    SuperDeployer is a simple CREATE2 contract deployer, which allows anyone
    to deploy a contract to a precalculated addess, such as a vanity address. 
    We recommend using ERADICATE2 to generate salts. A good GPU can check 1B+ 
    addresses/sec. Use this contract's address as the deployer.

    CAUTION
    It is not recommended to use contracts that can be deleted (contains
    selfdestruct, delegatecall, or callcode). Deleted contracts can be 
    redeployed to the same address using the same salt and bytecode.
    
    FORMULAS
    addresses to check on avg = 16**number of vanity chars at a specific location
    seconds to brute-force on avg = addresses to check on avg / checks per sec
    probability of brute-forcing in X seconds (%) = (seconds of brute-forcing / (addresses to check on avg / checks per sec)) * 100
    
    EXAMPLES
    1 out of 1,099,511,627,776 addresses have 10 leading zeros.
    A 10-leading zero address takes 18.3 mins to brute-force at 1B checks/sec.
    A 12-leading zero address takes 256x longer (3.3 days).
    A 14-leading zero address takes 65536x longer (834 days).

    Method IDs (function hashes):
    "38cb7245": "calculateAddress(bytes,bytes32)"
    "bd66e436": "deploy(bytes,bytes32,address)"

*/

/**
    @title SuperDeployer
    @author SuperCollectiv
    @notice CREATE2 contract deployer.
 */
contract SuperDeployer {

    /**
        @notice Calculate a contract address deployed from this contract using the bytecode and salt.
        @param bytecode The contract bytecode (starting with '0x').
        @param salt The salt to use (starting with '0x').
        @return calculatedAddress The address of the contract that will be deployed.
    */
    function calculateAddress(
        bytes memory bytecode,
        bytes32 salt
    ) public view returns (address calculatedAddress) {
        return address(
                    uint160(
                        uint256(
                            keccak256(
                                abi.encodePacked(
                                    bytes1(0xff),
                                    address(this), // This contract is the deployer.
                                    salt,
                                    keccak256(abi.encodePacked(bytecode))
                                )
                            )
                        )
                    )
                );
    }

    /**
        @notice Deploy a contract using CREATE2.
        @dev Cannot deploy a contract at an address where one already exists unless it has been deleted.
        @param bytecode The contract bytecode (starting with '0x').
        @param salt The salt to use (starting with '0x').
        @param anticipatedAddress The address you are expecting the contract to be.
        @return deployedAddress The address of the deployed contract.
    */
    function deploy(
        bytes memory bytecode,
        bytes32 salt,
        address anticipatedAddress
    ) public payable returns (address deployedAddress) {

        // Revert if a contract exists at the address.
        if (anticipatedAddress.code.length > 0) revert CONTRACT_EXISTS_AT_THIS_ADDRESS(anticipatedAddress);

        // Ensure the anticipated address matches the calculated address.
        address calculatedAddress = calculateAddress(bytecode, salt);
        if (anticipatedAddress != calculatedAddress) revert CALCULATED_ADDRESS_DOES_NOT_MATCH(anticipatedAddress, calculatedAddress);

        // Deploy contract using CREATE2.
        assembly {
            deployedAddress := create2(
                callvalue(),                    // forward ETH (constructor must be payable if >0)
                add(bytecode, 0x20),            // bytecode
                mload(bytecode),                // bytecode length
                salt                            // salt
            )
        }

        // Ensure the anticipated address matches the deployed address.
        if (anticipatedAddress != deployedAddress) revert DEPLOYED_ADDRESS_DOES_NOT_MATCH(anticipatedAddress, deployedAddress);

        return deployedAddress;
    }
}

/// @notice Contract exists at this address.
error CONTRACT_EXISTS_AT_THIS_ADDRESS(address anticipated);
/// @notice Calculated addresss does not match.
error CALCULATED_ADDRESS_DOES_NOT_MATCH(address anticipated, address calculated);
/// @notice Deployed addresss does not match.
error DEPLOYED_ADDRESS_DOES_NOT_MATCH(address anticipated, address deployed);