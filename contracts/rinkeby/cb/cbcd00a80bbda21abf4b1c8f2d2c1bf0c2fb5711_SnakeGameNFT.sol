// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract SnakeGameNFT is ERC721A, Ownable {

    string public baseURI = "https://gateway.pinata.cloud/ipfs/QmUrAWK1SixdKdACo61yjzuDS12hk2bo78zhzsU9XGchPV";
    string public constant baseExtension = ".json";
    uint256 public constant MAX_FREE = 1;
    uint256 public constant MAX_PER_TX = 10;
    uint256 public constant MAX_SUPPLY = 800;
    uint256 public price = 0.005 ether;

    bool public paused = true;

    constructor() ERC721A("Snake Game NFT", "SnakeGameNFT") {}

    function mint(uint256 _amount) external payable {
        address _caller = _msgSender();
        require(!paused, "Paused");
        require(MAX_SUPPLY >= totalSupply() + _amount, "Exceeds max supply");
        require(_amount > 0, "No 0 mints");
        require(tx.origin == _caller, "No contracts");
        require(MAX_PER_TX >= _amount , "Excess max per paid tx");
        require(_amount * price == msg.value, "Invalid funds provided");

        _safeMint(_caller, _amount);
    }

    function freeMint() external payable {
        address _caller = _msgSender();
        require(!paused, "Paused");
        require(MAX_SUPPLY >= totalSupply() + 1, "Exceeds max supply");
        require(tx.origin == _caller, "No contracts");
        require(MAX_FREE >= uint256(_getAux(_caller)) + 1, "Excess max per free wallet");

        _setAux(_caller, 1);
        _safeMint(_caller, 1);
    }

    function _startTokenId() internal override view virtual returns (uint256) {
        return 1;
    }

    function minted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = _msgSender().call{value: balance}("");
        require(success, "Failed to send");
    }

    function teamMint(uint256 _number) external onlyOwner {
        _safeMint(_msgSender(), _number);
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
              baseURI,
              Strings.toString(_tokenId),
              baseExtension
            )
        ) : "";
    }
}