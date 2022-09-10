// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Storage{


    struct RewardData{
        uint256 blockNumber;
        uint256 rewardRecieved;
        uint256 entryNumber;
        uint256 proposalIndex; //Used for lookup in the originating reward contract
        bytes32[] extraRewardData;
    }
    
    struct Post{
        uint256[] previousVersionIndexes;
        uint256 originIndex;
        uint16  postType; //interpretation of post type is determined by the reward contract
        address rewardee;
        address uploader;
        uint256 blockNumber;
        bytes32 IPFS_CID;
        bytes32[] extraData;

        mapping(address => mapping(uint256 => RewardData)) rewardData;
    }

    mapping(uint256 => Post) posts;
    uint256 private _postIndex;

    constructor(){
        _postIndex = 0;
    }

    function uploadPost
    (
        uint256[] memory previousVersionIndexes,
        uint16  postType,
        address rewardee,
        bytes32 IPFS_CID,
        bytes32[] memory extraData
    )
        public
        returns (uint256 postIndex)
    {
        _postIndex++;
        posts[_postIndex].previousVersionIndexes = previousVersionIndexes;
        posts[_postIndex].originIndex = getOriginIndex(previousVersionIndexes[0]);
        posts[_postIndex].postType = postType;
        posts[_postIndex].rewardee = rewardee;
        posts[_postIndex].uploader = msg.sender;
        posts[_postIndex].blockNumber = block.number;
        posts[_postIndex].IPFS_CID = IPFS_CID;
        posts[_postIndex].extraData = extraData;

        return postIndex;
    }

    function rewardPost
    (
        uint256 postIndex,
        uint256 identifier,
        uint256 proposalIndex,
        uint256 reward,
        bytes32[] memory extraRewardData
    )
        public
        returns (uint256 totalReward)
    {
        uint256[] memory previousVersionIndexes = getPreviousVersionIndexes(postIndex);

        posts[postIndex].rewardData[msg.sender][identifier].blockNumber = block.number;
        posts[postIndex].rewardData[msg.sender][identifier].rewardRecieved = reward;
        posts[postIndex].rewardData[msg.sender][identifier].proposalIndex = proposalIndex;
        posts[postIndex].rewardData[msg.sender][identifier].extraRewardData = extraRewardData;

        if(previousVersionIndexes[0] == 0){
            posts[postIndex].rewardData[msg.sender][identifier].entryNumber = 1;
        }else{
            posts[postIndex].rewardData[msg.sender][identifier].entryNumber = getEntryNumber(previousVersionIndexes[0], msg.sender, identifier);
        }

        return reward;
        
    }




    function getPreviousVersionIndexes(uint256 postIndex) public view returns (uint256[] memory){
        return posts[postIndex].previousVersionIndexes;
    }

    function getOriginIndex(uint256 postIndex) public view returns (uint256){
        return posts[postIndex].originIndex;
    }

    function getRewardee(uint256 postIndex) public view returns (address){
        return posts[postIndex].rewardee;
    }

    function getUploader(uint256 postIndex) public view returns (address){
        return posts[postIndex].uploader;
    }

    function getBlockNumber(uint256 postIndex) public view returns (uint256){
        return posts[postIndex].blockNumber;
    }

    function getIPFSCID(uint256 postIndex) public view returns (bytes32){
        return posts[postIndex].IPFS_CID;
    }

    function getExtraData(uint256 postIndex) public view returns (bytes32[] memory){
        return posts[postIndex].extraData;
    }

    function getExtraRewardData(uint256 postIndex, address uploader, uint256 identifier) public view returns (bytes32[] memory){
        return posts[postIndex].rewardData[uploader][identifier].extraRewardData;
    }

    function getRewardBlockNumber(uint256 postIndex, address uploader, uint256 identifier) public view returns (uint256){
        return posts[postIndex].rewardData[uploader][identifier].blockNumber;
    }

    function getReward(uint256 postIndex, address uploader, uint256 identifier) public view returns (uint256){
        return posts[postIndex].rewardData[uploader][identifier].rewardRecieved;
    }

    function getEntryNumber(uint256 postIndex, address uploader, uint256 identifier) public view returns (uint256){
        return posts[postIndex].rewardData[uploader][identifier].entryNumber;
    }

    function getProposalIndex(uint256 postIndex, address uploader, uint256 identifier) public view returns (uint256){
        return posts[postIndex].rewardData[uploader][identifier].proposalIndex;
    }

}