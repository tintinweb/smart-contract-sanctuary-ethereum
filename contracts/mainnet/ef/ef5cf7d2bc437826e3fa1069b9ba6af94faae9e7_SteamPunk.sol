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

    bool public started = false;
    string public baseURI =
        "ipfs://QmSJ5QBNEsdcL3swFpNDkgrYNHq9KiFcwK735RBDtS9juC/";
    address private _devWallet = 0x1a93694Ce4D1c0F18cBcf7e5491656C77Bcd86dE;

    mapping(address => uint256) public walletMinted;
    mapping(address => uint256) public WhiteListMinted;

    constructor() ERC721A("SteamPunk Hunter", "SPH") {}

    function mint(uint32 amount) external payable {
        require(started, "Sale is not started");
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

    function Freemint(uint32 amount) external {
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

    function setStarted(bool _started) external onlyOwner {
        started = _started;
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
}