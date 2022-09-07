// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

/**
 @author Tellor Inc.
 @title QueryDataStorage
 @dev This contract is used for storing query data
*/
contract QueryDataStorage {
    mapping(bytes32 => bytes) public queryData; // queryId => queryData

    event QueryDataStored(bytes32 _queryId);

    /**
     * @dev Stores query data in a mapping from queryId
     * @param _queryData The query data
     */
    function storeData(bytes memory _queryData) external {
        bytes32 _queryId = keccak256(_queryData);
        if (queryData[_queryId].length == 0) {
            queryData[_queryId] = _queryData;
            emit QueryDataStored(_queryId);
        }
    }

    /**
     * @dev Retrieves query data
     * @param _queryId Unique identifier for the query
     * @return _queryData Stored query data
     */
    function getQueryData(bytes32 _queryId)
        public
        view
        returns (bytes memory _queryData)
    {
        return queryData[_queryId];
    }
}