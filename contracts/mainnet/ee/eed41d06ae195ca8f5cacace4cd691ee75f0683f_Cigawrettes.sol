// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./MerkleProof.sol";

contract Cigawrettes is ERC721A, Ownable {
    using ECDSA for bytes32;

    uint256 constant AMOUNT = 1;
    uint256 constant MAX = 20;
    uint256 constant CIG_MAX = 9999;
    uint256 constant RESERVE_MAX = 500;
    uint256 constant PRICE = 0.0333 ether;
    uint256 constant EARLY_PRICE = 0.0111 ether;
    uint256 constant EARLY_DATE = 1664596800;
    uint256 constant PRESALE_DATE = 1663945200;
    uint256 private _reserveMinted = 0;
    bytes32 private _merkleRoot;
    string private _baseTokenURI;

    constructor(string memory baseURI) ERC721A("Cigawrettes", "CIG") {
        _baseTokenURI = baseURI;
    }

    modifier callerIsUser() {
        require(
            tx.origin == msg.sender,
            "Are you who you say you are?"
        );
        _;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function getPrice(uint256 quantity) internal view returns (uint256) {
        uint256 unit = ((block.timestamp > EARLY_DATE) ? PRICE : EARLY_PRICE);
        if(quantity >= 5 && quantity < 11) {
            return unit * quantity * 90 / 100;
        } else if (quantity >= 11) {
            return unit * quantity * 81 / 100;
        } else {
            return unit * quantity;
        }
    }

    function mint(uint256 quantity) external callerIsUser payable {
        require(block.timestamp > PRESALE_DATE, "Still in presale, try again Sept 23th @ 11am EST!");
        require(_totalMinted() + quantity < CIG_MAX, "Not enough Cigawrettes left.");
        require(msg.value >= getPrice(quantity), "Not enough eth");
        require(balanceOf(msg.sender) + quantity < 20, "Can't buy more than 20 Packs.");
        _safeMint(msg.sender, quantity);
    }

    function freeMint(uint256 quantity, bytes32[] memory proof) external callerIsUser payable {
        require(_merkleRoot != "", "Free Mint merkle tree not set");
        require(
            MerkleProof.verify(
                proof,
                _merkleRoot,
                keccak256(abi.encodePacked(msg.sender, AMOUNT))
            ),
            "I'm sorry you're not on the presale list"
        );
        require(_totalMinted() + quantity < CIG_MAX, "Not enough Cigawrettes left.");
        require(msg.value >= (getPrice(balanceOf(msg.sender) < 1 ? quantity - 1 : quantity)), "Not enough eth");
        require(balanceOf(msg.sender) + quantity < 20, "Can't buy more than 20 Packs.");
        _safeMint(msg.sender, quantity);
    }

    function reserveMint(address[] memory to) external onlyOwner {
        require(_totalMinted() + to.length < CIG_MAX, "Not enough Cigawrettes left.");
        require(_reserveMinted + to.length < RESERVE_MAX, "Too many reserves, not allowed.");
        _reserveMinted += to.length;
        for (uint i=0; i<to.length; i++) {
            _safeMint(to[i], AMOUNT);
        }
    }

    function setMerkleRoot(bytes32 newMerkleRoot_) external onlyOwner {
        _merkleRoot = newMerkleRoot_;
    }

    function withdraw(address payable to) external onlyOwner {
        require(to != address(0));
        to.transfer(address(this).balance);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, "/", _toString(tokenId), ".json")) : '';
    }
}