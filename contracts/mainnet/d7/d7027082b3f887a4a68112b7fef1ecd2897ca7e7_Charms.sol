// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract Charms is ERC721A, Ownable, ReentrancyGuard {

    IERC721 public PN;
    bytes32 public root;

    // Max Per TX
    uint256 public maxPerTx;

    // Mint Count Mapping
    mapping(address => mapping(uint256=>uint256)) public mints;

    // Events
    event minted(address minter, uint256 price, address recipient, uint256 index, uint256 amount);
    event burned(address from, address to, uint256 id);
    event charmAdded(string name, uint256 max, uint256 currentAmount, uint256 price, uint256 maxPerWallet, string uri, bool PNOnly, bool alOnly, bool hasEP, address exclusiveProject, bool isActive, uint256 index);
    event charmChanged(string name, uint256 max, uint256 currentAmount, uint256 price, string uri, uint256 index);

    // Struct with charm types
    struct Charm {
        string name;
        uint256 max;
        uint256 currentAmount;
        uint256 price;
        uint256 maxPerWallet;
        string uri;
        bool PNOnly;
        bool alOnly;
        bool hasEP;
        address exclusiveProject;
        bool isActive;
    }
    Charm[] public charms;

    constructor(
        string memory name,     // Probably Nothing Genesis Charms
        string memory symbol,   // PNCHRM
        uint256 _maxSupply     // 115792089237316195423570985008687907853269984665640564039457584007913129639935
    ) 
    ERC721A(name, symbol, 100, _maxSupply) 
    {
        maxPerTx = 1;
        URI =  "https://us-central1-photosynthesis2.cloudfunctions.net/charm-uri?token_id=";
        PN = IERC721(0xB9aEcB63908c13b6167aD2eab9bAcD7e0DaBa78A);
    }

    function isAllowListed(address _recipient, bytes32[] calldata _merkleProof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_recipient));
        bool isal = MerkleProof.verify(_merkleProof, root, leaf);
        return isal;
    }
    
    function mint(uint256 index, uint256 amount, bytes32[] calldata merkleProof) external payable nonReentrant {
        require(index < charms.length, "Charm does not exist");
        require(charms[index].currentAmount + amount <= charms[index].max, "Exceeds max supply of charm type");
        require(charms[index].isActive, "Charm is not in season");
        require(msg.value == charms[index].price * amount, "Incorrect amount of ETH sent");
        require(amount <= maxPerTx, "Exceeds maximum per transaction");
        require(mints[_msgSender()][index] + amount <= charms[index].maxPerWallet, "Exceeds max per wallet");

        mints[_msgSender()][index] += amount;
        if(charms[index].alOnly) {
            bool isAL = isAllowListed(_msgSender(), merkleProof);
            require(isAL, "Not allow listed for this charm");
        }

        if(charms[index].PNOnly) {
            require(PN.balanceOf(_msgSender()) > 0, "Sender must hold a Probably Nothing NFT");
        }

        if(charms[index].hasEP){
            IERC721 EP;
            EP = IERC721(charms[index].exclusiveProject);
            require(EP.balanceOf(_msgSender()) > 0, "Sender must hold a specific NFT to mint this charm");
        }

        charms[index].currentAmount += amount;

        _safeMint(_msgSender(), amount);
        emit minted(_msgSender(), charms[index].price * amount, _msgSender(), index, amount);
    }

    function addCharm(string memory _name, uint256 _maxSupply, uint256 _price, uint256 _maxPerWallet, string memory _uri, bool alOnly, bool _PNOnly, bool _hasEP, address exclusiveProject) external onlyOwner {
        uint256 index = charms.length;
        charms.push(Charm(_name, _maxSupply, 0, _price, _maxPerWallet, _uri, _PNOnly, alOnly, _hasEP, exclusiveProject, true));
        emit charmAdded(_name, _maxSupply, 0, _price, _maxPerWallet, _uri, _PNOnly, alOnly, _hasEP, exclusiveProject, true, index);
    }

    function burn(uint256 tokenId) external {
        transferFrom(_msgSender(), address(0), tokenId);
        emit burned(_msgSender(), address(0), tokenId);
    }

    function ownerMint(uint256 index, uint256 amount, address _recipient) external onlyOwner {
        require(charms[index].currentAmount + amount <= charms[index].max, "Not enough left to mint");
        _safeMint(_recipient, amount);
        emit minted(_msgSender(), 0, _recipient, index, amount);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success,) = _msgSender().call{value: balance}("");
        require(success, "Transfer fail");
    }

    function changeMax(uint256 index, uint256 max) external onlyOwner {
        charms[index].max = max;
    }

    function setURI(uint256 index,string memory _uri) external onlyOwner {
        charms[index].uri = _uri;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        URI = _uri;
    }

    function setPrice(uint256 index, uint256 _price) external onlyOwner {
        charms[index].price = _price;
    }

    function setMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function setMaxPerWallet(uint256 index, uint256 _amount) external onlyOwner {
        charms[index].maxPerWallet = _amount;
    }

    function flipHasEP(uint256 index) external onlyOwner {
        charms[index].hasEP = !charms[index].hasEP;
    }

    function setEP(uint256 index, address exclusiveProject) external onlyOwner {
        charms[index].exclusiveProject = exclusiveProject;
    }

    function flipActive(uint256 index) external onlyOwner {
        charms[index].isActive = !charms[index].isActive;
    }

    function flipPNOnly(uint256 index) external onlyOwner {
        charms[index].PNOnly = !charms[index].PNOnly;
    }

    function setPN(address _PN) external onlyOwner {
        PN = IERC721(_PN);
    }

    function flipALOnly(uint256 index) external onlyOwner {
        charms[index].alOnly = !charms[index].alOnly;
    }

    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function pay() external payable {

    }

}