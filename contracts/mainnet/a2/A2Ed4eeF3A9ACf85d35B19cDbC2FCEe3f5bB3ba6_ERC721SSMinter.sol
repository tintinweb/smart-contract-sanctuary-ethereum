/**
 *Submitted for verification at Etherscan.io on 2023-03-21
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title ERC721SS (ERC721 Sumo Soul) Minter
 * @author 0xSumo
 */

interface IERC721 {
    function ownerOf(uint256 tokenId_) external view returns (address);
}

interface IERC721SS {
    function mint(uint256 tokenId_, address to_) external;
    function ownerOf(uint256 tokenId_) external view returns (address);
}

abstract contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    address public owner;
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "onlyOwner not owner!");_; } 
    function transferOwnership(address new_) external onlyOwner { address _old = owner; owner = new_; emit OwnershipTransferred(_old, new_); }
}

abstract contract MerkleProof {
    bytes32 internal _merkleRoot;
    function _setMerkleRoot(bytes32 merkleRoot_) internal virtual { _merkleRoot = merkleRoot_; }
    function isWhitelisted(address address_, bytes32[] memory proof_) public view returns (bool) {
        bytes32 _leaf = keccak256(abi.encodePacked(address_));
        for (uint256 i = 0; i < proof_.length; i++) {
            _leaf = _leaf < proof_[i] ? keccak256(abi.encodePacked(_leaf, proof_[i])) : keccak256(abi.encodePacked(proof_[i], _leaf));
        }
        return _leaf == _merkleRoot;
    }
}

contract ERC721SSMinter is Ownable, MerkleProof {

    IERC721SS public ERC721SS = IERC721SS(0x508c1CC6099F273A751386561e49Cf279571E716);
    IERC721 public ERC721 = IERC721(0xd2b14f166Daeb1Ec73a4901745DBE2199Db6B40C);
    uint256 public Ids = 334;
    uint256 public constant optionPrice = 0.01 ether;
    mapping(uint256 => string) public ADD;
    struct IdAndAdd { uint256 ids_; string add_; }
    mapping(address => uint256) internal minted;

    function setERC721SS(address _address) external onlyOwner { 
        ERC721SS = IERC721SS(_address); 
    }

    function setERC721(address _address) external onlyOwner { 
        ERC721 = IERC721(_address); 
    }

    function claimSBT(uint256 tokenId, string memory add) external payable {
            require(ERC721.ownerOf(tokenId) == msg.sender, "Not owner");
            require(msg.value == optionPrice, "Value sent is not correct");
            require(bytes(add).length > 0, "Give addy");
            ADD[tokenId] = add;
            ERC721SS.mint(tokenId, msg.sender);
    }

    function claimSBTFree(uint256 tokenId) external {
        require(ERC721.ownerOf(tokenId) == msg.sender, "Not owner");
        ERC721SS.mint(tokenId, msg.sender);
    }

    function mintSBT(bytes32[] memory proof_, string memory add) external payable {
        require(isWhitelisted(msg.sender, proof_), "You are not whitelisted!");
        require(msg.value == optionPrice, "Value sent is not correct");
        require(bytes(add).length > 0, "Give addy");
        require(Ids < 999, "No more");
        require(2 > minted[msg.sender], "You have no whitelistMint left");
        minted[msg.sender]++;
        ADD[Ids] = add;
        ERC721SS.mint(Ids, msg.sender);
        Ids++;
    }

    function mintSBTFree(bytes32[] memory proof_) external {
        require(isWhitelisted(msg.sender, proof_), "You are not whitelisted!");
        require(Ids < 999, "No more");
        require(2 > minted[msg.sender], "You have no whitelistMint left");
        minted[msg.sender]++;
        ERC721SS.mint(Ids, msg.sender);
        Ids++;
    }

    function changedMind(uint256 tokenId, string memory add) external payable {
        require(ERC721SS.ownerOf(tokenId) == msg.sender, "Not owner");
        require(msg.value == optionPrice, "Value sent is not correct");
        ADD[tokenId] = add;
    }

    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        _setMerkleRoot(merkleRoot_);
    }

    function getAllIdAndAdd(uint256 _startIndex, uint256 _count) external view returns (IdAndAdd[] memory) {
        IdAndAdd[] memory _IdAndAdd = new IdAndAdd[](_count);
        for (uint256 i = 0; i < _count; i++) {
            uint256 currentIndex = _startIndex + i;
            uint256 _ids = currentIndex;
            string memory _add  = ADD[currentIndex];
            _IdAndAdd[i] = IdAndAdd(_ids, _add);
        }
        return _IdAndAdd;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}