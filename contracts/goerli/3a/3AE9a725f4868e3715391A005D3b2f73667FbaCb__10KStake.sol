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

contract _10KStake {
    address public stakeAddress;
    address public owner;
    mapping(uint256 => address) public stakeOwnerOf;
    event StakeEvent(address indexed from, uint256 indexed tokenId);
    event UnStakeEvent(address indexed to, uint256 indexed tokenId);

    constructor(address _stakeAddress) {
        stakeAddress = _stakeAddress;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function stake(uint256 _tokenId) public {
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
        emit StakeEvent(msg.sender, _tokenId);
    }

    function unStake(uint256 _tokenId) public {
        require(stakeOwnerOf[_tokenId] == msg.sender, "Not original owner");
        IERC721A(stakeAddress).transferFrom(
            address(this),
            msg.sender,
            _tokenId
        );
        stakeOwnerOf[_tokenId] = address(0);
        emit UnStakeEvent(msg.sender, _tokenId);
    }

    function batchStake(uint256[] memory _tokenIds) external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            stake(_tokenIds[i]);
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