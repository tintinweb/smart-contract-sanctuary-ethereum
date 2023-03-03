pragma solidity 0.8.18;

interface IRewardVesting {
    function numVestingEntries(address account) external view returns (uint);
    function getVestingEntryClaimable(address account, uint256 entryID) external view returns (uint);
    function accountVestingEntryIDs(address account, uint256 entryIndex) external view returns (uint);
}

contract RewardVestingHelper {
    IRewardVesting immutable rewardVesting;
    
    constructor(IRewardVesting _rewardVesting) {
        rewardVesting = _rewardVesting;
    }

    function getTotalClaimable(address account) external view returns (uint total){
        uint numEntries = rewardVesting.numVestingEntries(account);

        for(uint entryIndex; entryIndex < numEntries; ++entryIndex) {
            uint entryId = rewardVesting.accountVestingEntryIDs(account, entryIndex);
            total += rewardVesting.getVestingEntryClaimable(account, entryId);
        }
    }
}