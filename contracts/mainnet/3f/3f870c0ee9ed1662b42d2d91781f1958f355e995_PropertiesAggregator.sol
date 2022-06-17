/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract PropertiesAggregator {
    /**
     * @notice Fetches a single property from the target contract, assuming no arguments are used for the property
     * @param target The contract to perform the query on
     * @param name The name of the property to query
     * @return The raw data of the output of the call, not yet decoded
     */
    function getProperty(address target, string calldata name)
        public
        view
        returns (bytes memory)
    {
        string memory methodSignature = string(abi.encodePacked(name, "()"));
        (bool success, bytes memory result) = target.staticcall(
            abi.encodeWithSignature(methodSignature)
        );
        
        require(success, "Must succeed");
        return result;
    }

    /**
     * @notice Simultaneously fetches multiple properties from the target contract, assuming no arguments are used for each property
     * @param target The contract to perform the query on
     * @param names The names of the properties to query
     * @return An array of the raw data of the output of each property query, not yet decoded
     */
    function getProperties(address target, string[] calldata names)
        external
        view
        returns (bytes[] memory)
    {
        uint256 namesLength = names.length;
        bytes[] memory result = new bytes[](namesLength);
        for (uint256 i; i < namesLength; i++) {
            bytes memory propertyData = this.getProperty(target, names[i]);
            result[i] = propertyData;
        }
        return result;
    }
}