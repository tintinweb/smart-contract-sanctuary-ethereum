// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";

library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }

    
}

contract re4min is ERC721A, Ownable {

    uint256 private _currentTokenId = 0;

    uint256 public MAX_SUPPLY = 4800;
    string public baseTokenURI;
    uint256 public publicSaleTime = 1600;
    uint256 public basePrice = .2 ether;
    mapping(uint256 => bytes8) public note2status;

    enum MusicalInstruments {
        Drum,
        Lead,
        Synth,
        Bass,
        Pad
    }

    constructor(
        string memory _uri
    ) ERC721A("re4min", "re4min") {
        baseTokenURI = _uri;
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param to address of the future owner of the token
     */
    function mintByOwner(address to) public onlyOwner {
        _safeMint(to, 1);
    }

    function mintNote(uint256 num) public payable {
        require(block.timestamp >= publicSaleTime, "It's not time yet");
        require(num > 0 && num <= 10);
        require(msg.value == num * basePrice);
        _safeMint(_msgSender(), num);
    }

    function editMusic(uint256[] memory tokenIds, bytes8[] memory positions)
        external
    {
        // require(tokenIds.length == positions.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _editMusic(tokenIds[i], positions[i]);
        }
    }

    function _editMusic(uint256 _tokenId, bytes8 _position) internal {
        require(
            ownerOf(_tokenId) == msg.sender,
            "MetaSong: this note is not yours"
        );
        for (uint8 i = 0; i < 8; i++) {
            require(_position[i] <= 0x01, "MetaSong: some thing wrong");
        }
        note2status[_tokenId] = _position;
        emit MusicEditRecord(_tokenId, msg.sender, _position);
    }

    function getNoteInfo(uint256 tokenId)
        external
        view
        returns (
            uint256 column,
            uint256 row,
            MusicalInstruments ntype,
            bytes8 status
        )
    {
        column = (tokenId - 1) / 10 + 1;
        row = ((tokenId - 1) % 10) + 1;
        status = note2status[tokenId];
        uint256 num = (tokenId - 1) % 10;
        ntype = MusicalInstruments(num);
    }

    function getMetaSong(uint256 fromId, uint256 toId)
        external
        view
        returns (bytes memory song)
    {
        for (uint256 i = fromId; i <= toId; i += 1) {
            song = bytes.concat(song, note2status[i]);
        }
    }

    function getBlockOfUser(address user)
        external
        view
        returns (uint256[] memory)
    {
        uint256 balance = balanceOf(user);
        uint256[] memory res = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            res[i] = tokenOfOwnerByIndex(user, i);
        }
        return res;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)));
    }

    /**
     * @dev
     */
    function _incrementTokenId() private {
        require(_currentTokenId < MAX_SUPPLY);
        _currentTokenId++;
    }

    /**
     * @dev
     */
    function setBasePrice(uint256 price) external onlyOwner {
        basePrice = price;
    }

    /**
     * @dev
     */
    function setPublicSaleTime(uint256 time) external onlyOwner {
        publicSaleTime = time;
    }

    /**
     * @dev
     */
    function setBaseUri(string memory _uri) external onlyOwner {
        baseTokenURI = _uri;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    event MusicEditRecord(
        uint256 indexed tokenId,
        address indexed user,
        bytes8 status
    );
}