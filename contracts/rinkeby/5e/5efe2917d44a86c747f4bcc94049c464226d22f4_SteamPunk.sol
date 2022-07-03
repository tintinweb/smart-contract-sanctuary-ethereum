// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC2981.sol";
import "./Address.sol";
import "./Strings.sol";
import "./ERC721AQueryable.sol";

contract SteamPunk is ERC2981, ERC721AQueryable, Ownable {
    using Address for address payable;
    using Strings for uint256;

    uint256 public price = 0.005 ether;
    uint256 public maxSupply = 5000;
    uint256 public walletLimit = 10;

    uint256 public publicSupply = 1500;
    uint256 public publicMinted = 0;

    bool public _started = true;
    string public baseURI =
        "ipfs://QmdHbZpMy6cnW5vhPSU9m8zRkJ1ZoynDwaYDJSGSsjLgfh/";
    address private _devWallet = 0xcbA6A9B901F44bc9B7cD9546d25041b814088D99;

    mapping(address => uint256) public walletMinted;
    mapping(address => uint256) public WhiteListMinted;

    constructor() ERC721A("SteamPunk", "SP") {}

    function mint(uint32 amount) external payable {
        require(_started, "Sale is not started");
        require(amount + totalSupply() <= maxSupply, "Exceed max supply"); 
        require(amount + publicMinted <= publicSupply, "Exceed max supply"); 
        publicMinted = publicMinted + amount;

        require(
            amount + walletMinted[msg.sender] <= walletLimit,
            " Exceed wallet limit"
        );
        walletMinted[msg.sender] = walletMinted[msg.sender] + amount; 

        require(msg.value >= amount * price, "Insufficient fund"); 
        payable(_devWallet).sendValue(address(this).balance);
        _safeMint(msg.sender, amount);
    }

    function WhiteListMint(uint32 amount) external {
        require(totalSupply() + amount <= maxSupply, "Exceed max supply");
        require(
            amount <= WhiteListMinted[msg.sender],
            "Exceed max whitelist supply"
        );
        WhiteListMinted[msg.sender] = WhiteListMinted[msg.sender] - amount;
        _safeMint(msg.sender, amount);
    }

    function setWhiteList(
        address[] memory _whiteList,
        uint256[] memory _whiteListNum
    ) external onlyOwner {
        uint256 len = _whiteList.length;
        for (uint256 i = 0; i < len; i++) {
            WhiteListMinted[_whiteList[i]] = _whiteListNum[i];
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC721A)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function setStarted(bool started) external onlyOwner {
        _started = started;
    }

    function setMetadataURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).sendValue(address(this).balance);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    // function setParam
}