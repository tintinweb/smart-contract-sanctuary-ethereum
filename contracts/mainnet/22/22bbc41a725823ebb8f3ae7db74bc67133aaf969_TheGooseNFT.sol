// THE GOOSE NFT
// https://twitter.com/goosenftxyz
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    /@@.&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&   @@@@@@ #&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& @@@@@@@@@@@@@@@ %&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&/@[email protected]@@@@@@@/@@@@@@@@@ @ &&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&& @ @((@@@@@@@ @@@ %%%#@   &&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@[email protected]  @@@@@@@ @@*% %%% @@,&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&#&&&&&&&&&&&&&&&&&&&#@@ @@@@@@@@ @@ %%%%%% @ &&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&& @@@@@#  %@@@@@%%%%%%%% %&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@(((%%%%%%%%% &&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&& @@@@@@@@@@@@@@& %(((((((( &&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& @@@@@@@@@@@@@&&&&& &&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& @@@@@@@@@@@@@@@@ &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& &&&&&&&&&&&&&& &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&% &&&&&&&&&&&&&@ &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*@@@@@@@@@@@@@@@@@@@ &&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@/&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&& @@@@@@@%@@@@@@@@@@@@@@@ &&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&,@@@@@@@@ @@@@ @@@@@@@@@@@@%&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&   /  &&&@@@@@@@@@@@@@@@@@@ &&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&& @%@&&&&@@@@@@@@@@@@@&@ &&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&/  .,. @&&    &&&&&@  &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& ##&&&((&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&   && ((/   &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&%%%%%%%%%%/###/.%% %%%%%%%%&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%%%%%% %%%%%%%%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./ERC721A.sol";
import "./Ownable.sol";

contract TheGooseNFT is ERC721A, Ownable {
    using Strings for uint256;
    uint256 public maxSupply = 5555;
    uint256 public publicMintPrice = 0.0069 ether;
    uint256 public freeAmount = 1;
    uint256 public ogFreeAmount = 2;
    uint256 public maxPerWallet = 5;
    uint256 public teamReserve = 100;
    uint256 public teamMinted = 0;
    bool public enabledMint = false;
    bool public enableOgMint = false;
    bool public revealed = false;
    string public baseURI;
    string public unRevealedURI;
    mapping(address => bool) private _OGList;
    mapping(address => uint256) private _mintedFreeAmount;

    constructor() ERC721A("The Goose NFT", "Goose") {}

    function publicMint(uint256 amount) external payable {
        require(enabledMint, "Minting is not live");
        require(totalSupply() + amount < maxSupply + 1, "No more");
        require(amount < maxPerWallet + 1, "5 max per TX");
        require(
            _numberMinted(msg.sender) + amount < maxPerWallet + 1,
            "5 max per wallet"
        );
        bool isOG = _OGList[msg.sender];
        uint256 freeMintAmount = 0;
        uint256 roleFreeAmount = isOG ? ogFreeAmount : freeAmount;
        uint256 freeMinted = _mintedFreeAmount[msg.sender];
        if (roleFreeAmount > freeMinted) {
            uint256 leftFreeAmount = roleFreeAmount - freeMinted;
            freeMintAmount = leftFreeAmount > amount ? amount : leftFreeAmount;
        }

        _mintedFreeAmount[msg.sender] = freeMinted + freeMintAmount;
        uint256 payAmount = amount - freeMintAmount;

        require(
            msg.value >= payAmount * publicMintPrice,
            "Please send the exact amount."
        );

        _safeMint(msg.sender, amount);
    }

    function ogMint(uint256 amount) external payable {
        require(enableOgMint, "Minting is not live");
        require(_OGList[msg.sender], "Not OG");
        require(totalSupply() + amount < maxSupply + 1, "No more");
        require(amount < maxPerWallet + 1, "5 max per TX");
        require(
            _numberMinted(msg.sender) + amount < maxPerWallet + 1,
            "5 max per wallet"
        );
        bool isOG = _OGList[msg.sender];
        uint256 freeMintAmount = 0;
        uint256 roleFreeAmount = isOG ? ogFreeAmount : freeAmount;
        uint256 freeMinted = _mintedFreeAmount[msg.sender];
        if (roleFreeAmount > freeMinted) {
            uint256 leftFreeAmount = roleFreeAmount - freeMinted;
            freeMintAmount = leftFreeAmount > amount ? amount : leftFreeAmount;
        }

        _mintedFreeAmount[msg.sender] = freeMinted + freeMintAmount;
        uint256 payAmount = amount - freeMintAmount;

        require(
            msg.value >= payAmount * publicMintPrice,
            "Please send the exact amount."
        );

        _safeMint(msg.sender, amount);
    }

    function teamMint(uint256 amount) external onlyOwner {
        require(totalSupply() + amount < maxSupply + 1, "No more");
        require(teamMinted + amount < teamReserve + 1, "No more reserve");
        _safeMint(msg.sender, amount);
    }

    function addOG(address[] calldata addressList) external onlyOwner {
        for (uint256 i = 0; i < addressList.length; i++) {
            _OGList[addressList[i]] = true;
        }
    }

    function isOGFn(address addr) public view virtual returns (bool) {
        return _OGList[addr];
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            revealed
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : unRevealedURI;
    }

    function setUnRevealedURI(string memory uri) public onlyOwner {
        unRevealedURI = uri;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setPublicPrice(uint256 _newPrice) external onlyOwner {
        publicMintPrice = _newPrice;
    }

    function setMaxPerWallet(uint256 _amount) external onlyOwner {
        maxPerWallet = _amount;
    }

    function flipMint() external onlyOwner {
        enabledMint = !enabledMint;
    }

    function flipOgMint() external onlyOwner {
        enableOgMint = !enableOgMint;
    }

    function flipReveal() external onlyOwner {
        revealed = !revealed;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}