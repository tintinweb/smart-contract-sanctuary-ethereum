// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IERC721A.sol";

contract _10KStakeLast {
    address public owner;
    address public stakeAddress;
    mapping(uint256 => address) public stakeOwnerOf;
    mapping(uint256 => uint256) public stakeTime;

    enum StakeLockedDays {
        NowDays,
        ThirtyDays,
        SixtyDays,
        NinetyDays
    }

    event StakeEvent(
        address indexed from,
        uint256 indexed tokenId,
        StakeLockedDays indexed stakeLockedDays,
        uint256 timestamp
    );

    event UnStakeEvent(
        address indexed to,
        uint256 indexed tokenId,
        uint256 indexed timestamp
    );

    constructor(address _stakeAddress) {
        stakeAddress = _stakeAddress;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function stake(uint256 _tokenId, StakeLockedDays stakeLockedDays) public {
        require(
            IERC721A(stakeAddress).ownerOf(_tokenId) == msg.sender &&
                stakeOwnerOf[_tokenId] == address(0),
            "You must own the NFT."
        );
        IERC721A(stakeAddress).transferFrom(
            msg.sender,
            address(this),
            _tokenId
        );
        stakeOwnerOf[_tokenId] = msg.sender;
        uint256 currentTimestamp = block.timestamp;

        if (stakeLockedDays == StakeLockedDays.ThirtyDays) {
            stakeTime[_tokenId] = currentTimestamp + 30 days;
        } else if (stakeLockedDays == StakeLockedDays.SixtyDays) {
            stakeTime[_tokenId] = currentTimestamp + 60 days;
        } else if (stakeLockedDays == StakeLockedDays.NinetyDays) {
            stakeTime[_tokenId] = currentTimestamp + 90 days;
        } else {
            stakeTime[_tokenId] = currentTimestamp;
        }
        emit StakeEvent(
            msg.sender,
            _tokenId,
            stakeLockedDays,
            currentTimestamp
        );
    }

    function unStake(uint256 _tokenId) public {
        require(stakeOwnerOf[_tokenId] == msg.sender, "Not original owner");
        require(block.timestamp > stakeTime[_tokenId], "Not time to unstake");
        IERC721A(stakeAddress).transferFrom(
            address(this),
            msg.sender,
            _tokenId
        );
        stakeOwnerOf[_tokenId] = address(0);
        stakeTime[_tokenId] = uint256(0);
        emit UnStakeEvent(msg.sender, _tokenId, block.timestamp);
    }

    function batchStake(
        uint256[] memory _tokenIds,
        StakeLockedDays stakeLockedDays
    ) external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            stake(_tokenIds[i], stakeLockedDays);
        }
    }

    function batchUnStake(uint256[] memory _tokenIds) external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            unStake(_tokenIds[i]);
        }
    }

    function setStakeAddress(address _stakeAddress) external onlyOwner {
        stakeAddress = _stakeAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC721A {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);
}