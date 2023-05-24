// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract DigiMonkzStaking {
    struct NftInfo {
        uint256 artifact;
        uint256 stakedAt;
        uint256 lastClaimedAt;
    }
    mapping(uint16 => NftInfo) public artifactPerGen1Nft;
    mapping(uint16 => NftInfo) public artifactPerGen2Nft;
    mapping(address => uint256) public artifactPerStaker;
    mapping(address => uint16[]) public gen1InfoPerStaker;
    mapping(address => uint16[]) public gen2InfoPerStaker;

    event Gen1Staked(address indexed staker, uint16 tokenId, uint256 stakedAt);
    event Gen2Staked(address indexed staker, uint16 tokenId, uint256 stakedAt);
    event Gen1Unstaked(
        address indexed unstaker,
        uint16 tokenId,
        uint256 unstakedAt
    );
    event Gen2Unstaked(
        address indexed unstaker,
        uint16 tokenId,
        uint256 unstakedAt
    );

    constructor() {}

    function gen1Stake(uint16 _tokenId) external returns (bool) {
        uint256 len = gen1InfoPerStaker[msg.sender].length;
        bool flag;
        for (uint256 i = 0; i < len; i++) {
            if (gen1InfoPerStaker[msg.sender][i] == _tokenId) {
                flag = true;
            }
        }
        require(flag == false);

        if (artifactPerGen1Nft[_tokenId].artifact != 0) {
            artifactPerGen1Nft[_tokenId].stakedAt = block.timestamp;
        } else {
            NftInfo memory stakingNft = NftInfo(0, block.timestamp, 0);
            artifactPerGen1Nft[_tokenId] = stakingNft;
        }

        gen1InfoPerStaker[msg.sender].push(_tokenId);

        emit Gen1Staked(msg.sender, _tokenId, block.timestamp);

        return true;
    }

    function gen2Stake(uint16 _tokenId) external returns (bool) {
        uint256 len = gen2InfoPerStaker[msg.sender].length;
        bool flag;
        for (uint256 i = 0; i < len; i++) {
            if (gen2InfoPerStaker[msg.sender][i] == _tokenId) {
                flag = true;
            }
        }
        require(flag == false);

        if (artifactPerGen2Nft[_tokenId].artifact != 0) {
            artifactPerGen2Nft[_tokenId].stakedAt = block.timestamp;
        } else {
            NftInfo memory stakingNft = NftInfo(0, block.timestamp, 0);
            artifactPerGen2Nft[_tokenId] = stakingNft;
        }
        gen2InfoPerStaker[msg.sender].push(_tokenId);

        emit Gen2Staked(msg.sender, _tokenId, block.timestamp);

        return true;
    }

    function gen1Unstake(uint16 _tokenId) external returns (bool) {
        uint256 len = gen1InfoPerStaker[msg.sender].length;
        require(len != 0);

        uint256 idx = len;
        for (uint256 i = 0; i < len; i++) {
            if (gen1InfoPerStaker[msg.sender][i] == _tokenId) {
                idx = i;
            }
        }
        require(idx != len);

        uint256 artifact = getArtifactForGen1(_tokenId);
        artifactPerStaker[msg.sender] -= artifact;

        if (idx != len - 1) {
            gen1InfoPerStaker[msg.sender][idx] = gen1InfoPerStaker[msg.sender][
                len - 1
            ];
        }
        gen1InfoPerStaker[msg.sender].pop();
        artifactPerGen1Nft[_tokenId].stakedAt = 0;

        emit Gen1Unstaked(msg.sender, _tokenId, block.timestamp);

        return true;
    }

    function gen2Unstake(uint16 _tokenId) external returns (bool) {
        uint256 len = gen2InfoPerStaker[msg.sender].length;
        require(len != 0);

        uint256 idx = len;
        for (uint256 i = 0; i < len; i++) {
            if (gen2InfoPerStaker[msg.sender][i] == _tokenId) {
                idx = i;
            }
        }
        require(idx != len);

        uint256 artifact = getArtifactForGen2(_tokenId);
        artifactPerStaker[msg.sender] -= artifact;

        if (idx != len - 1) {
            gen2InfoPerStaker[msg.sender][idx] = gen2InfoPerStaker[msg.sender][
                len - 1
            ];
        }
        gen2InfoPerStaker[msg.sender].pop();
        artifactPerGen2Nft[_tokenId].stakedAt = 0;

        emit Gen2Unstaked(msg.sender, _tokenId, block.timestamp);

        return true;
    }

    function getArtifactForGen1(uint16 _tokenId) public returns (uint256) {
        //check either msg.sender is the owner of the NFT or not
        uint256 stakedTime = artifactPerGen1Nft[_tokenId].stakedAt;
        uint256 lastClaimedTime = artifactPerGen1Nft[_tokenId].lastClaimedAt;
        uint256 numMonth;
        uint256 artifact;

        if (lastClaimedTime >= stakedTime) {
            numMonth =
                ((block.timestamp - stakedTime) / 30 days) -
                ((lastClaimedTime - stakedTime) / 30 days);
        } else {
            numMonth = (block.timestamp - stakedTime) / 30 days;
        }
        require(numMonth > 0);

        if (_tokenId >= 0 && _tokenId <= 10) {
            artifact = 25 * numMonth;
        } else if (_tokenId >= 11 && _tokenId <= 111) {
            artifact = 20 * numMonth;
        }

        artifactPerGen1Nft[_tokenId].artifact += artifact;
        artifactPerStaker[msg.sender] += artifact;

        return artifact;
    }

    function getArtifactForGen2(uint16 _tokenId) public returns (uint256) {
        uint256 stakedTime = artifactPerGen2Nft[_tokenId].stakedAt;
        uint256 lastClaimedTime = artifactPerGen2Nft[_tokenId].lastClaimedAt;
        uint256 numMonth;
        uint256 artifact;

        if (lastClaimedTime >= stakedTime) {
            numMonth =
                ((block.timestamp - stakedTime) / 30 days) -
                ((lastClaimedTime - stakedTime) / 30 days);
        } else {
            numMonth = (block.timestamp - stakedTime) / 30 days;
        }
        require(numMonth > 0);

        if (_tokenId >= 1 && _tokenId <= 11) {
            artifact = 15 * numMonth;
        } else {
            artifact = 10 * numMonth;
        }

        artifactPerGen2Nft[_tokenId].artifact += artifact;
        artifactPerStaker[msg.sender] += artifact;

        return artifact;
    }

    function claimReward(uint256 _numArtifact) external returns (bool) {
        require(artifactPerStaker[msg.sender] >= _numArtifact);

        //Do something here...
        artifactPerStaker[msg.sender] -= _numArtifact;

        return true;
    }
}