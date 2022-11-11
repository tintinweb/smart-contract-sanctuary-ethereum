// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
     __        __   ___  __   __   ___  __        __       ___  __  
    /__` |  | |__) |__  |__) |  \ |__  |__) |    /  \ \ / |__  |__) 
    .__/ \__/ |    |___ |  \ |__/ |___ |    |___ \__/  |  |___ |  \ 

    SuperDeployer by SuperCollectiv

    ABOUT
    This contract allows anyone to deploy a contract to a precalculated address 
    using CREATE2, such as a vanity address. We recommend using ERADICATE2 to 
    generate salts. Better GPU = faster results. A good GPU can check 1B+ 
    addresses per second. More efficient programs may be created in the future.
    Use this contract's address as the deployer. Each consecutive character takes
    approximately 16x longer to get. Frontrunning is possible but very unlikely.

    CAUTION
    Contracts that contain selfdestruct, delegatecall, or callcode can be deleted 
    and all ETH on the contract will be sent to the deleter. Additionally, the
    contract can be redeployed to the same address using the same bytecode and
    salt. We do not recommend using contracts that can be deleted.
    
    FORMULAS
    addresses to check on avg = 16**number of vanity chars at a specific location
    seconds to brute-force on avg = addresses to check on avg / checks per sec
    probability of brute-forcing in X seconds (%) = (seconds of brute-forcing / (addresses to check on avg / checks per sec)) * 100
    
    EXAMPLES
    1 address out of 1,099,511,627,776 addresses have 10 leading zeros.
    It takes 18.3 mins on average to brute-force a 10-leading zero address at 1 billion checks per sec.
    1 address out of 72,057,594,037,927,936 addresses have 14 leading zeros.
    It takes 834 days on average to brute-force a 14-leading zero address at 1 billion checks per sec (0.005%/hour).

    Method IDs (function hashes):
    "38cb7245": "calculateAddress(bytes,bytes32)",
    "bd66e436": "deploy(bytes,bytes32,address)",
    "c54a9588": "deployedContracts()",
    "06b4f17f": "deployedContractsByIndex(uint256)"

    Event topics:
    "0x8c4c8a0d966c8774c5bc4b0617f6a415e717af1a4f351fd0d6b5d50d916204b3": "Deploy(uint256,address,address,address,uint256)"

*/

/**
    @title SuperDeployer
    @author SuperCollectiv
    @notice CREATE2 contract deployer.
 */
contract SuperDeployer {
    
    // Topic: 0x8c4c8a0d966c8774c5bc4b0617f6a415e717af1a4f351fd0d6b5d50d916204b3
    event Deploy(
        uint256 index,
        address indexed txOrigin,
        address indexed msgSender,
        address indexed deployedAddress,
        uint256 timestamp
    );

    /**
        @notice All deployed contracts by index.
    */
    address[] public deployedContractsByIndex;

    /**
        @notice Returns an array of all deployed contracts in the order they were deployed.
        @dev Anyone can deploy a contract using SuperDeployer.
        @return contracts Addresses of all deployed contracts.
    */
    function deployedContracts() public view returns (address[] memory contracts) {
        contracts = new address[](deployedContractsByIndex.length);
        for (uint256 i; i < deployedContractsByIndex.length; i++) contracts[i] = deployedContractsByIndex[i];
        return contracts;
    }

    /**
        @notice Calculate a contract address deployed from this contract using the bytecode and salt.
        @param bytecode The contract bytecode (starting with '0x').
        @param salt The salt used when deploying the contract with CREATE2 (starting with '0x').
        @return calculatedAddress Address of the contract that will be deployed using `bytecode` and `salt`.
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
        @param salt The salt used when deploying the contract with CREATE2 (starting with '0x').
        @param anticipatedAddress The address you are expecting the contract to be deployed at.
        @return deployedAddress Address of the deployed contract.
    */
    function deploy(
        bytes memory bytecode,
        bytes32 salt,
        address anticipatedAddress
    ) public payable returns (address deployedAddress) {

        // Revert if a contract already exists at the address.
        if (anticipatedAddress.code.length > 0) revert CONTRACT_EXISTS_AT_THIS_ADDRESS(anticipatedAddress);

        // Calculate the contract address and ensure it matches. Checked prior to deploying to save gas.
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

        // Revert if deployed address does not match.
        if (anticipatedAddress != deployedAddress) revert DEPLOYED_ADDRESS_DOES_NOT_MATCH(anticipatedAddress, deployedAddress);

        // Deploy event.
        emit Deploy(                            // 0x8c4c8a0d966c8774c5bc4b0617f6a415e717af1a4f351fd0d6b5d50d916204b3
            deployedContractsByIndex.length,    // uint256 index
            tx.origin,                          // address indexed txOrigin
            msg.sender,                         // address indexed msgSender
            deployedAddress,                    // address indexed deployedAddress
            block.timestamp                     // uint256 timestamp
        );

        // Add to array of deployed contracts.
        deployedContractsByIndex.push(deployedAddress);

        return deployedAddress;
    }
}

/// @notice Contract exists at this address.
error CONTRACT_EXISTS_AT_THIS_ADDRESS(address anticipated);

/// @notice Calculated addresss does not match.
error CALCULATED_ADDRESS_DOES_NOT_MATCH(address anticipated, address calculated);

/// @notice Deployed addresss does not match.
error DEPLOYED_ADDRESS_DOES_NOT_MATCH(address anticipated, address deployed);