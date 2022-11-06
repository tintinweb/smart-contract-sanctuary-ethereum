pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./ERC721AQueryable.sol";
import "./MerkleProof.sol";

contract WOJ is Ownable, ERC721A, ERC721AQueryable {
    // ----------------- MODIFIERS -----------------
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // ----------------- VARAIBLES -----------------
    uint256 public immutable mintStartTime;
    bytes32 public immutable merkleRoot;
    uint256 public constant maxBatchNumber = 10;
    uint256 public constant maxMintNumber = 10000;
    uint256 public constant selfKeepNumber = 150;
    uint256 public constant maxFreeMintNumber = 434;
    uint256 public constant freeMintTimeRange = 172800;
    uint256 public publicPrice = 0.018 ether;

    uint256 public freeMintCount = 0;

    mapping(address => bool) public whitelistClaimed;

    constructor(uint256 _mintStartTime, bytes32 _merkleRoot) ERC721A("Wojak V0.2", "Wojak V0.2") {
        mintStartTime = _mintStartTime;
        merkleRoot = _merkleRoot;
    }

    function contractURI() public pure returns (string memory) {
        return "https://ipfs.filebase.io/ipfs/QmYLzjurMBpsDvhecLSWAFKxKWzchb45bmpWVNBvDXUf8o";
    }

    function airdrop(address _to, uint256 _quantity) external onlyOwner {
        require(
            _quantity + totalSupply() <= maxMintNumber,
            "Doge Club: Mint is not started"
        );
        _mint(_to, _quantity);
    }

    function canFreeMint(address _sender, bytes32[] calldata _merkleProof) public view returns (bool){
        if (whitelistClaimed[_sender]) {
            return false;
        }
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (MerkleProof.verify(_merkleProof, merkleRoot, leaf)) {
            return true;
        }
        return false;
    }

    function whiteListMint(uint256 quantity, bytes32[] calldata _merkleProof) external payable callerIsUser {
        require(block.timestamp >= mintStartTime, "Doge Club: Mint has not started");
        require(
            block.timestamp <= mintStartTime + freeMintTimeRange,
            "Doge Club: Free mint has closed"
        );
        require(quantity <= maxBatchNumber, "Doge Club: Exceeded max number in one tx");
        require(
            quantity + totalSupply() <= maxMintNumber - selfKeepNumber,
            "Doge Club: Sold out"
        );
        require(
            canFreeMint(msg.sender, _merkleProof),
            "Doge Club: Address is not whitelisted or already free minted"
        );
        require(
            msg.value == publicPrice * (quantity - 1),
            "Doge Club: Wrong ETH amount"
        );
        whitelistClaimed[msg.sender] = true;
        freeMintCount = freeMintCount + 1;
        _mint(msg.sender, quantity);
    }

    function mint(uint256 quantity) external payable callerIsUser {
        require(
            block.timestamp >= mintStartTime,
            "Doge Club: Mint has not started"
        );
        require(
            quantity <= maxBatchNumber,
            "Doge Club: Exceeded max number in one tx"
        );
        require(
            msg.value == publicPrice * quantity,
            "Doge Club: Wrong ETH amount"
        );
        if (block.timestamp <= mintStartTime + freeMintTimeRange) {
            if (quantity + totalSupply() > maxMintNumber - selfKeepNumber - maxFreeMintNumber + freeMintCount)
                revert("Doge Club: Sold out");
            _mint(msg.sender, quantity);
        } else {
            if (quantity + totalSupply() > maxMintNumber - selfKeepNumber)
                revert("Doge Club: Sold out");
            _mint(msg.sender, quantity);
        }
    }

    function setNewPrice(uint256 _price) external onlyOwner {
        publicPrice = _price;
    }

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}