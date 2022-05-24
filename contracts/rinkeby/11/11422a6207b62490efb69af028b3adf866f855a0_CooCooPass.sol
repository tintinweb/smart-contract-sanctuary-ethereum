// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC1155.sol";

contract CooCooPass is ERC1155, Ownable {

    uint256 public constant count = 1;

    bool public saleOn;
    bool public presaleOn;
    uint256 public immutable maxSupply;
    uint256 _totalSupply;
    uint256 public price = 0.03 ether;

    mapping(address => bool) public claimed;
    bytes32 public whitelistMerkleRoot = 0x0;

    constructor(
        string memory baseTokenURI_,
        uint256 maxSupply_
    ) ERC1155(baseTokenURI_) {
        maxSupply = maxSupply_;
    }

    function mint() external payable {
        require(saleOn, "Sale inactive");
        require(_totalSupply + 1 <= maxSupply, "Mint exceed max supply");
        require(!claimed[msg.sender], "Max mint exceeded");
        require(price == msg.value, "Value sent is incorrect");

        _totalSupply += 1;
        claimed[msg.sender] = true;
        _mint(msg.sender, count, 1, "");
    }

    function mintPresale(bytes32[] calldata _merkleProof) external payable {
        require(presaleOn, "Presale inactive");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf), "Not whitelisted");
        require(_totalSupply + 1 <= maxSupply, "Mint exceed max supply");
        require(!claimed[msg.sender], "Max mint exceeded");
        require(price == msg.value, "Value sent is incorrect");

        _totalSupply += 1;
        claimed[msg.sender] = true;
        _mint(msg.sender, count, 1, "");
    }

    /// @notice Check if someone is whitelisted
    function isWhitelisted(bytes32[] calldata _merkleProof, address _address) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf);
    }

    /// toggle the main sale on or off
    function toggleSale() external onlyOwner {
        saleOn = !saleOn;
    }

    /// @notice toggle the presale on or off
    function togglePresale() external onlyOwner {
        presaleOn = !presaleOn;
    }

    /// set the base URI of the NFT
    function setBaseURI(
        string calldata _baseTokenURI
    ) external onlyOwner {
        _setURI(_baseTokenURI);
    }

    /// @notice for marketing / team
    /// @param _quantity Amount to mint
    function reserve(uint256 _quantity) external onlyOwner {
        require(_totalSupply + _quantity <= maxSupply, "Mint exceed max supply");
        _mint(msg.sender, count, _quantity, "");
    }

    /// @notice set the merkle hash root for whitelist check
    /// @param _merkleRoot The root hash
    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function withdraw() public onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }
}