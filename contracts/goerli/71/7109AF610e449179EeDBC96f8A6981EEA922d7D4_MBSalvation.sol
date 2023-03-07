// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./MerkleProof.sol";

contract MBSalvation is Ownable, ReentrancyGuard, ERC721Enumerable {
    using Strings for uint256;

    string public baseTokenURI;
    bool public isPaused = false;
  
    bytes32 public merkleRoot = 0x41af4fe12579f8262837f3f4ec2acd5273d82f97763aa4721a10fbeb7b5f8864;
    
    uint256 public startTime = 1676904445;
    uint256 public endTime = 1679334827;
    uint256 public lastMint = 1676904445;

    uint8[] public rarityList;
    mapping(uint256 => uint8) public tokenRarityList;
    mapping(uint8 => uint256) public tokenRarityCount;

    struct rarities {
        uint8 level;
        uint8 rarity;
    }
    
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC721(_name, _symbol) {
        baseTokenURI = _uri;
    }

    function freeMint(bytes32[] calldata _merkleProof)
        external
        onlyUser
        nonReentrant
    {
        require(!isPaused, "MBS: currently paused");
        require(
            block.timestamp >= startTime,
            "MBS: Free mint is not started yet"
        );

        require(
            block.timestamp < endTime,
            "MBS: Free mint is ended"
        );

        require(verifyAddress(_merkleProof), 
            "MBS: You are not allow to mint"
        );

        uint256 curTokenId = totalSupply() + 1;

        _safeMint(_msgSender(), curTokenId);
        uint256 rarity = ((block.timestamp - lastMint) % 600) / 30;
        tokenRarityList[curTokenId] = rarityList[rarity];
        tokenRarityCount[rarityList[rarity]]++;
        lastMint = block.timestamp;
    }

    function ownerMInt(address _addr) external onlyOwner {
        uint256 curTokenId = totalSupply() + 1;
        _safeMint(_addr, curTokenId);

        uint256 rarity = ((block.timestamp - lastMint) % 600) / 30;
        tokenRarityList[curTokenId] = rarityList[rarity];
        tokenRarityCount[rarityList[rarity]]++;
        lastMint = block.timestamp;            
    }

    modifier onlyUser() {
        require(_msgSender() == tx.origin, "MBS: no contract mint");
        _;
    }

    function verifyAddress(bytes32[] calldata _merkleProof) public view returns (bool) {
        if(balanceOf(_msgSender()) > 0){
            return true;
        }else{
            bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));        
            return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
        }        
    }

    function verifyWalletAddress(bytes32[] calldata _merkleProof, address _addr) public view returns (bool) {
        if(balanceOf(_addr) > 0){
            return true;
        }else{
            bytes32 leaf = keccak256(abi.encodePacked(_addr));        
            return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
        }        
    }

    function setMerkleRoot(bytes32 _merkleRootHash) external onlyOwner
    {
        merkleRoot = _merkleRootHash;
    }

    function setRarityList(uint8[] memory _rarities) external onlyOwner
    {
        delete rarityList;
        for (uint8 i = 0; i < _rarities.length; i++) {
            rarityList.push(_rarities[i]);
        }
    }

    function setStartTime(uint256 _time) external onlyOwner {
        startTime = _time;
    }

    function setEndTime(uint256 _time) external onlyOwner {
        endTime = _time;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseTokenURI = _baseURI;
    }

    function setPause(bool _isPaused) external onlyOwner returns (bool) {
        isPaused = _isPaused;
        return isPaused;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(
                    abi.encodePacked(
                        baseTokenURI,                        
                        Strings.toString(tokenRarityList[_tokenId]),
                        ".json"
                    )
                );
    }
}