/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC721 {
    function ownerOf(uint256) external view returns (address);

    function safeTransferFrom(
        address,
        address,
        uint256
    ) external;
}

contract EtherPOAPStaking {
    //EtherPOAP contract address
    ERC721 constant EtherPOAP = ERC721(0x98C7FA114b2FE921Ba97f628e9dCb72890491721);
    struct StakeInfo {
        uint48 startTime;
        uint48 stakeTime;
        address staker;
    }
    //tokenId to accumulated staked time
    mapping(uint256 => uint256) public totalStakedTime;
    //tokenId to token stake information
    mapping(uint256 => StakeInfo) _stakeInfoMap;

    event StakeNFT(
        address indexed staker,
        uint256 indexed tokenId,
        uint256 stakeTime
    );

    event UnstakeNFT(
        address indexed staker,
        uint256 indexed tokenId,
        uint256 startTime,
        uint256 presetDuration
    );

    function stake(uint256 tokenId, uint48 _stakeTime) public {
        require(
            msg.sender == EtherPOAP.ownerOf(tokenId),
            "you are not the owner of this NFT"
        );
        _stakeInfoMap[tokenId].startTime = uint48(block.timestamp);
        _stakeInfoMap[tokenId].stakeTime = _stakeTime;
        _stakeInfoMap[tokenId].staker = msg.sender;
        EtherPOAP.safeTransferFrom(msg.sender, address(this), tokenId);
        emit StakeNFT(msg.sender, tokenId, _stakeTime);
    }

    function unstake(uint256 tokenId) public {
        require(
            _stakeInfoMap[tokenId].staker == msg.sender && unlockTime(tokenId) <= block.timestamp,
            "wrong tokenId or still in locked time"
        );
        emit UnstakeNFT(
            msg.sender,
            tokenId,
            _stakeInfoMap[tokenId].startTime,
            _stakeInfoMap[tokenId].stakeTime
        );
        totalStakedTime[tokenId] += block.timestamp - _stakeInfoMap[tokenId].startTime;
        delete _stakeInfoMap[tokenId];
        EtherPOAP.safeTransferFrom(address(this), msg.sender, tokenId);
    }

    function batchStake(uint256[] memory tokenIds, uint48 _stakeTime) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            stake(tokenIds[i], _stakeTime);
        }
    }

    function batchUnstake(uint256[] memory tokenIds) public {
        require(tokenIds.length > 0, "Empty tokenIds input");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            unstake(tokenIds[i]);
        }
    }

    function unlockTime(uint256 tokenId) public view returns (uint256) {
        return
            uint256(_stakeInfoMap[tokenId].startTime + _stakeInfoMap[tokenId].stakeTime);
    }

    function stakeInfoMap(uint256 tokenId) public view returns (uint48 startTime, uint48 stakeTime, address staker) {
        return (
            _stakeInfoMap[tokenId].startTime,
            _stakeInfoMap[tokenId].stakeTime,
            _stakeInfoMap[tokenId].staker
        );
    }

    function stakedTokens(address user) public view returns (string memory) {
        string memory res;
        for (uint256 i = 0; i < 10000; i++) {
            if (_stakeInfoMap[i].staker == user) {
                if (bytes(res).length == 0) {
                    res = _uint2str(i);
                } else {
                    res = string(abi.encodePacked(res, ", ", _uint2str(i)));
                }
            }
        }
        return res;
    }

    function _uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bStr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bStr[k] = b1;
            _i /= 10;
        }
        return string(bStr);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}