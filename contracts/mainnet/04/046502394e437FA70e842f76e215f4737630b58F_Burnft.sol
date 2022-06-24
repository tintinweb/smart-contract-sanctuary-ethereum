// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";
import "./IERC721.sol";

contract Burnft is ERC721A, Ownable {

    uint256 public maxSupply = 777;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    bytes32 public root;
    string private baseURI;

    constructor() ERC721A("Burnft", "BURNFT") {
        _safeMint(msg.sender, 10);
    }

    modifier mintableSupply(uint256 _quantity) {
        require(
            totalSupply() + _quantity <= maxSupply,
            "Exceeds the total supply."
        );
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata merkleProof) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "The address is not on the whitelist."
        );
        _;
    }

    function checkWhitelist(bytes32[] calldata merkleProof)
        external
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            );
    }

    function isContains(address[] memory _addresses)
        internal
        pure
        returns (bool contains)
    {
        contains = false;
        for (uint256 i = 0; i < _addresses.length; i++) {
            for (uint256 j = i + 1; j < _addresses.length; j++) {
                if (_addresses[j] == _addresses[i]) {
                    contains = true;
                    return contains;
                }
            }
        }
    }

    function burnToMint(
        address[] memory _nftAddresses,
        uint256[] memory tokenIds,
        bytes32[] calldata merkleProof
    ) external mintableSupply(1) isValidMerkleProof(merkleProof){
       
        require(!isContains(_nftAddresses), "Invalid params.");
        for (uint256 i = 0; i < _nftAddresses.length; i++) {
            require(
                IERC721(_nftAddresses[i]).ownerOf(tokenIds[i]) == msg.sender,
                "You must be the owner of NFTs."
            );
        }

        for (uint256 i = 0; i < _nftAddresses.length; i++) {
            IERC721(_nftAddresses[i]).transferFrom(
                msg.sender,
                burnAddress,
                tokenIds[i]
            );
        }

        _safeMint(msg.sender, 1);
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }


    /**
     * @dev Allows owner to adjust the merkle root hash.
     */
    function setMerkleRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }
   
}