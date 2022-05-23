// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract FlowerShoppe is ERC721A, Ownable, ReentrancyGuard {

    IERC721 public Photosynthesis;
    using Strings for uint256;

    uint256 public maxPerTx;

    event gifted(address from, address to, uint256 amount, uint256 flowerIndex);
    event typeAdded(string name, string uri, uint256 index, uint256 maxSupply, uint256 price, bool PSOnly, bool hasEP, address exclusiveProject);
    event burned(address from, address to, uint256 id);

    struct FlowerTypes {
        string name;
        string URI;
        uint256 count;
        uint256 maxSupply;
        uint256 price;
        bool isActive;
        bool PSOnly;
        bool hasEP;
        address exclusiveProject;
    }
    FlowerTypes[] public flowertypes;

    string flowerURI = "";

    mapping(uint256 => uint256) tokenToType;
    constructor(
      string memory name,       // Flower Shoppe
      string memory symbol,     // FLWRSHP
      uint256 maxSupply,        // 115792089237316195423570985008687907853269984665640564039457584007913129639935
      uint256 _maxPerTx,        // 1
      address PS                // 0x366e3b64ef9060eb4b2b0908d7cd165c26312a23
      )
      ERC721A
      (
        name,
        symbol,
        100,
        maxSupply
        )
        {
        Photosynthesis = IERC721(PS);
        maxPerTx = _maxPerTx;
    }

    function gift(address recipient, uint256 amount, uint256 flowertype) external payable nonReentrant{
        require(flowertype < flowertypes.length, "Flower does not exist");
        require(flowertypes[flowertype].count + amount <= flowertypes[flowertype].maxSupply, "Exceeds max supply of flower type");
        require(flowertypes[flowertype].isActive, "Flower is not in season");
        require(msg.value == flowertypes[flowertype].price * amount, "Incorrect amount of ETH sent");
        require(amount <= maxPerTx, "Exceeds maximum per transaction");

        if(flowertypes[flowertype].PSOnly) {
            require(Photosynthesis.balanceOf(_msgSender()) > 0, "Sender must hold a Photosynthesis NFT");
        }

        if(flowertypes[flowertype].hasEP){
            IERC721 EP;
            EP = IERC721(flowertypes[flowertype].exclusiveProject);
            require(EP.balanceOf(_msgSender()) > 0, "Sender must hold a specific NFT to mint this flower");
        }

        flowertypes[flowertype].count += amount;

        _safeMint(recipient, amount);
        emit gifted(_msgSender(), recipient, amount, flowertype);
    }

    function burn(uint256 tokenId) external {
        transferFrom(_msgSender(), address(0), tokenId);
        emit burned(_msgSender(), address(0), tokenId);
    }

    function addFlower(string memory _name, string memory uri, uint256 maxSupply, uint256 _price, bool _PSOnly, bool _hasEP, address _exclusiveProject) external onlyOwner {
        flowertypes.push(FlowerTypes(_name, uri, 0, maxSupply, _price, true, _PSOnly, _hasEP, _exclusiveProject));
        emit typeAdded(_name, uri, flowertypes.length - 1, maxSupply, _price, _PSOnly, _hasEP,  _exclusiveProject);
    }

    function flowerState(uint256 flowerIndex, bool _isActive) external onlyOwner {
        flowertypes[flowerIndex].isActive = _isActive;
    }

    function changeUri(uint256 index, string memory newuri) external onlyOwner {
        flowertypes[index].URI = newuri;
    }

    function changeSupply(uint256 index, uint256 newSupply) external onlyOwner {
        flowertypes[index].maxSupply = newSupply;
    }

    function changePrice(uint256 index, uint256 _price) external onlyOwner {
        flowertypes[index].price = _price;
    }

    function changePSOnly(uint256 index, bool _PSOnly) external onlyOwner {
        flowertypes[index].PSOnly = _PSOnly;
    }

    function changeMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function setURI(string memory _uri) external onlyOwner {
        URI = _uri;
    }

    function setPS(address _ps) external onlyOwner {
        Photosynthesis = ERC721A(_ps);
    }

    function changeEP(uint256 index, bool _hasEP, address _ep) external onlyOwner {
        flowertypes[index].hasEP = _hasEP;
        flowertypes[index].exclusiveProject = _ep;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success,) = _msgSender().call{value: balance}("");
        require(success, "Transfer fail");
    }

}