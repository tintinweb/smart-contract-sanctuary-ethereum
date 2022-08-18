// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract Bitstreet is ERC721A, Ownable, ReentrancyGuard {
    uint256 public maxSupply;
    bytes32 public merkleRoot = 0x00314e565e0574cb412563df634608d76f5c59d9f817e85966100ec1d48005c0;

    uint256 public state;

    uint256 public maxPerWallet = 10;
    uint256 public maxPerTX = 10;

    mapping(address => uint256) public numOfMints;

    event minted(address minter, uint256 amount);
    event burned(address from, address to, uint256 id);
    event saleStateChanged(uint256 state);
    event maxPerTXChanged(uint256 max);
    event maxPerWalletChanged(uint256 max);

    constructor() 
    ERC721A(
        "Bitstreet", 
        "BITST", 
        100, 
        10001
    ) {
        maxSupply = 10001;
        state = 0;
        URI = "";
    }

    function mint(uint256 _amount, bytes32[] calldata _merkleProof) external nonReentrant {
        require(totalSupply() + _amount <= maxSupply, "Exceeds max supply");
        require(_amount <= maxPerTX, "Exceeds max per tx");
        require(_amount + numOfMints[_msgSender()] <= maxPerWallet, "Exceeds max per wallet");
        require(state != 0, "Minting is closed");

        numOfMints[_msgSender()] += _amount;

        if(state == 1) {
            require(isAllowListed(_msgSender(), _merkleProof), "allow list only");
        }

        _safeMint(_msgSender(), _amount);
        emit minted(_msgSender(), _amount);
    }

    function ownerMint(address _recipient, uint256 _amount) external onlyOwner {
        require(totalSupply() + _amount <= maxSupply, "Exceeds max supply");
        _safeMint(_recipient, _amount);
        emit minted(_recipient, _amount);
    }

    function isAllowListed(address _recipient, bytes32[] calldata _merkleProof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_recipient));
        bool isal = MerkleProof.verify(_merkleProof, merkleRoot, leaf);
        return isal;
    }

    function setRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function burn(uint256 tokenId) external {
        transferFrom(_msgSender(), address(0), tokenId);
        emit burned(_msgSender(), address(0), tokenId);
    }

    function setURI(string memory _URI) external onlyOwner {
        URI = _URI;
    }

    function setState(uint256 _state) external onlyOwner{
        state = _state;
        emit saleStateChanged(state);
    }

    function setMaxPerTX(uint256 _maxPerTX) external onlyOwner {
        maxPerTX = _maxPerTX;
        emit maxPerTXChanged(maxPerTX);
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
        emit maxPerWalletChanged(maxPerWallet);
    }

    function withdraw() public onlyOwner {
        (bool success,) = owner().call{value: address(this).balance}("");
        require(success, "Transfer fail");
    }
}