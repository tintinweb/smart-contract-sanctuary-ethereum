// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol"
// import "hardhat/console.sol";

interface ERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;

    function approve(address to, uint256 tokenId) external payable;
}

contract Bridge {
    address public owner;
    ERC721 nftContract;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    event lockNFT(
        address _from,
        address tokenContractAddress,
        uint256 _tokenId
    );

    event unLockNFT(
        address _to,
        address tokenContractAddress,
        uint256 _tokenId
    );

    // lock user's NFT to locking pool, user calls
    function lock(address tokenContractAddress, uint256 tokenId) public {
        nftContract = ERC721(tokenContractAddress);
        require(
            nftContract.ownerOf(tokenId) == msg.sender,
            "You should be owner of the NFT"
        );
        nftContract.transferFrom(msg.sender, address(this), tokenId);
        emit lockNFT(msg.sender, tokenContractAddress, tokenId);
    }

    // unlock user's NFT to user, relay service calls
    function unlock(
        address tokenContractAddress,
        uint256 tokenId,
        address _to
    ) public onlyOwner {
        // TODO: need to verify relay service's address
        nftContract = ERC721(tokenContractAddress);

        nftContract.approve(_to, tokenId);
        nftContract.transferFrom(address(this), _to, tokenId);
        emit unLockNFT(_to, tokenContractAddress, tokenId);
    }
}