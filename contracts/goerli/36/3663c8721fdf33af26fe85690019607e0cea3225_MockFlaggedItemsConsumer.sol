/**
 *Submitted for verification at Etherscan.io on 2022-11-17
*/

pragma solidity ^0.8.17;


/// @title IFlaggedItemConsumer interface
/// @notice Interface for the flagged items consumer
interface IFlaggedItemConsumer {
    /// @dev The function is called by the VRF provider in order to deliver results to the consumer.
    /// @param timestamp The unix timestamp when the request is resolved on Bandchain.
    /// @param collection The address of the collection.
    /// @param itemIds The token ids from the collection.
    /// @param flaggedStatus The list of flagged status according to the given itemIds.
    function submitFlaggedItems(
        uint256 timestamp,
        address collection,
        uint256[] calldata itemIds,
        bool[] calldata flaggedStatus
    ) external;
}


contract MockFlaggedItemsConsumer is IFlaggedItemConsumer {

    struct SavedResult {
        uint256 timestamp;
        address collection;
        uint256[] itemIds;
        bool[] flaggedStatus;
    }

    SavedResult public latestSavedResult;

    function submitFlaggedItems(
        uint256 timestamp,
        address collection,
        uint256[] calldata itemIds,
        bool[] calldata flaggedStatus
    ) external {
        latestSavedResult.timestamp = timestamp;
        latestSavedResult.collection = collection;
        latestSavedResult.itemIds = itemIds;
        latestSavedResult.flaggedStatus = flaggedStatus;
    }

}