// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";

contract MyGMFriends is ERC721A, Ownable {
    uint256 public whitelistMintPrice = 0.033 ether;
    uint256 public mintPrice = 0.0433 ether;
    uint256 public maxPerWallet = 10;
    uint256 public whitelistMaxPerWallet = 3;
    uint256 public maxSupply = 3333;
    uint256 public totalAirdropNum;
    uint256 public totalAirdrop = 33;
    uint256 public whitelistSaleStartTime = 1651154400;
    uint256 public publicSaleStartTime = 1651240800;
    bytes32 public root;

    constructor() ERC721A("My GM Friends", "MGMF") {}

    modifier withinMintableSupply(uint256 _quantity) {
        require(
            totalSupply() + _quantity + totalAirdropNum <= maxSupply,
            "Surpasses supply"
        );
        _;
    }

    modifier withinMaxPerWallet(uint256 _quantity, uint256 _limits) {
        require(
            _quantity > 0 &&  _quantity <= _limits,
            "Minting above allocation"
        );
        _;
    }

    modifier publicSaleActive() {
        require(
            publicSaleStartTime <= block.timestamp,
            "Public sale not started."
        );
        _;
    }

    modifier whitelistSaleActive() {
        require(
            whitelistSaleStartTime <= block.timestamp && block.timestamp < publicSaleStartTime,
            "Whitelist sale not started."
        );
        _;
    }

    function setPublicSaleTime(uint256 _time) external onlyOwner {
        publicSaleStartTime = _time;
    }

    function setWhitelistSaleTime(uint256 _time) external onlyOwner {
        whitelistSaleStartTime = _time;
    }

    /**
     * @dev Public minting functionality
     */
    function mintPublic(uint256 _quantity)
        external
        payable
        publicSaleActive
        withinMintableSupply(_quantity)
        withinMaxPerWallet(_quantity, maxPerWallet)
    {
        require(msg.value >= mintPrice * _quantity, "Insufficent funds.");
        
        _safeMint(msg.sender, _quantity);
    }

    modifier hasValidMerkleProof(bytes32[] calldata merkleProof) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address not whitelisted."
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

    function mintWhitelist(uint256 _quantity, bytes32[] calldata merkleProof)
        external
        payable
        whitelistSaleActive
        hasValidMerkleProof(merkleProof)
        withinMintableSupply(_quantity)
        withinMaxPerWallet(_quantity, whitelistMaxPerWallet)
    {
        require(
            msg.value >= whitelistMintPrice * _quantity,
            "Insufficent funds."
        );
        
        _safeMint(msg.sender, _quantity);
    }

    function airdrop(address[] memory _recipients, uint8[] memory _quantity)
        external
        onlyOwner
    {
        uint256 _airdropNum;

        for (uint256 i = 0; i < _recipients.length; i++) {
            _airdropNum += _quantity[i];
        }
        require(
            totalAirdropNum + _airdropNum <= totalAirdrop,
            "We've reached the maximum of airdrop limits."
        );

        require(totalSupply() + _airdropNum <= maxSupply, "Surpasses supply.");

        for (uint256 i = 0; i < _recipients.length; i++) {
            _safeMint(_recipients[i], _quantity[i]);
        }
        totalAirdropNum += _airdropNum;
    }

    /**
     * @dev Allows owner to adjust the mint price (in wei)
     */
    function setMerkleRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    /**
     * @dev Allows owner to adjust the mint price (in wei)
     */
    function setMintPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
    }

    
    /**
     * @dev Allows owner to adjust the mint price (in wei)
     */
    function setWhitelistMintPrice(uint256 _price) external onlyOwner {
        whitelistMintPrice = _price;
    }


    /**
     * @dev Base URI for the NFT
     */
    string private baseURI;

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}