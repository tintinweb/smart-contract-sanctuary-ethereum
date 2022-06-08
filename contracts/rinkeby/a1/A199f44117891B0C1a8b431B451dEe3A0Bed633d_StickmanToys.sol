// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract StickmanToys is ERC721A, Ownable, ReentrancyGuard {
    uint256 public maxSupply;
    bytes32 public merkleRoot = 0x00314e565e0574cb412563df634608d76f5c59d9f817e85966100ec1d48005c0;

    bool public alOnly;
    bool public mintOpen;

    uint256 public maxPerWallet = 2;
    uint256 public maxPerTX = 2;

    mapping(address => bool) public hasMinted;
    mapping(address => uint256) public numOfMints;

    event minted(address minter, uint256 amount);
    event burned(address from, address to, uint256 id);
    event alStateChanged(bool state);
    event saleStateChanged(bool state);
    event maxPerTXChanged(uint256 max);
    event maxPerALChanged(uint256 max);

    constructor(
        string memory name,     //Stickmen Toys
        string memory symbol,   // STICK
        uint256 _maxSupply      // 5000
    ) ERC721A(name, symbol, 100, _maxSupply) {
        maxSupply = _maxSupply;
        alOnly = true;
        mintOpen = false;
        URI = "";
    }

    function mint(uint256 _amount, bytes32[] calldata _merkleProof) external nonReentrant {
        require(totalSupply() + _amount <= maxSupply, "Exceeds max supply");
        require(_amount <= maxPerTX, "Exceeds max per tx");
        require(_amount + numOfMints[_msgSender()] <= maxPerWallet, "Exceeds max per allow list");
        require(mintOpen, "Minting is closed");

        numOfMints[_msgSender()] += _amount;

        if(isAllowListed(_msgSender(), _merkleProof) && !hasMinted[_msgSender()]) {
            if(numOfMints[_msgSender()] == maxPerWallet){
                hasMinted[_msgSender()] = true;
            }
        } else {
            require(!alOnly, "allow list only");
        }

        _safeMint(_msgSender(), _amount);
        emit minted(_msgSender(), totalSupply());
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

    function setURI(string memory _baseURI) external onlyOwner {
        URI = _baseURI;
    }

    function flipMintState() external onlyOwner {
        mintOpen = !mintOpen;
        emit saleStateChanged(mintOpen);
    }

    function flipALState() external onlyOwner {
        alOnly = !alOnly;
        emit alStateChanged(alOnly);
    }

    function setMaxPerTX(uint256 _maxPerTX) external onlyOwner {
        maxPerTX = _maxPerTX;
        emit maxPerTXChanged(maxPerTX);
    }

    function setMintsPerAL(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
        emit maxPerALChanged(maxPerWallet);
    }

    function withdraw() public onlyOwner {
        (bool success,) = owner().call{value: address(this).balance}("");
        require(success, "Transfer fail");
    }
}