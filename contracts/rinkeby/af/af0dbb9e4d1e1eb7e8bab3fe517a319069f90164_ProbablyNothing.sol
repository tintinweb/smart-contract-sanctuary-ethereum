// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract ProbablyNothing is ERC721A, Ownable, ReentrancyGuard {
    string public baseURI;
    uint256 public maxSupply;
    bytes32 public merkleRoot;

    bool alOnly;
    bool mintOpen;

    mapping(address => bool) public hasMinted;
    mapping(address => uint256) public numOfMints;

    event minted(address minter, uint256 id);
    event burned(address from, address to, uint256 id);

    constructor(
        string memory name,
        string memory symbol,
        uint256 _maxSupply
    ) ERC721A(name, symbol, 100, _maxSupply) {
        maxSupply = _maxSupply;
        alOnly = true;
        mintOpen = false;
        baseURI = "https://ipfs.io/ipfs/QmcQj3Yi1PtytJJ9iepD3awgVLSNzTZB6YMLBFEdrz559F";
    }

    function mint(uint256 _amount, bytes32[] calldata _merkleProof) external nonReentrant {
        require(totalSupply() + _amount <= maxSupply, "Exceeds max supply");
        require(_amount + numOfMints[_msgSender()] <= 2, "Max two per wallet");
        require(mintOpen, "Minting is paused");

        numOfMints[_msgSender()] += _amount;

        if(isAllowListed(_msgSender(), _merkleProof) && !hasMinted[_msgSender()]) {
            if(numOfMints[_msgSender()] == 2){
                hasMinted[_msgSender()] = true;
            }
        } else {
            require(!alOnly, "Only allow listed addresses can mint");
        }

        _safeMint(_msgSender(), _amount);
        emit minted(_msgSender(), totalSupply());
    }

    function ownerMint(address _recipient, uint256 _amount) external onlyOwner {
        require(totalSupply() + _amount <= maxSupply, "Exceeds max supply");
        _safeMint(_recipient, _amount);
        emit minted(_recipient, totalSupply());
    }

    function isAllowListed(address _recipient, bytes32[] calldata _merkleProof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_recipient));
        bool isal = MerkleProof.verify(_merkleProof, merkleRoot, leaf);
        return isal;
    }

    function setRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return baseURI;
    }

    function burn(uint256 tokenId) external {
        transferFrom(_msgSender(), address(0), tokenId);
        emit burned(_msgSender(), address(0), tokenId);
    }

    function changeURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function flipMintState() external onlyOwner {
        mintOpen = !mintOpen;
    }

    function flipALState() external onlyOwner {
        alOnly = !alOnly;
    }

    function withdraw() public onlyOwner {
        (bool success,) = owner().call{value: address(this).balance}("");
        require(success, "Transfer fail");
    }
}