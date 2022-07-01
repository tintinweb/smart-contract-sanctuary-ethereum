// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC2981.sol";
import "./Address.sol";
import "./Strings.sol";
import "./ERC721AQueryable.sol";

enum MintStatus {
    NotStarted,
    WhiteList,
    Publicsale
}

contract MoonMosquito is ERC2981, ERC721AQueryable, Ownable {
    using Address for address payable;
    using Strings for uint256;

    event LOG(uint32);

    bytes32 public immutable _lotterySalt;
    uint256 public immutable _price;
    uint32 public immutable _maxSupply;
    uint32 public immutable _teamSupply;
    uint32 public  _instantFreeSupply;
    uint32 public immutable _instantFreeWalletLimit;
    uint32 public immutable _walletLimit;

    uint32 public _teamMinted;
    uint32 public _instantFreeMinted;
    uint32 public _maxMintAmount;

    MintStatus public _mintStatus = MintStatus.NotStarted;
    mapping(address => bool) private _whiteList;
    string public _metadataURI = "https://gateway.pinata.cloud/ipfs/QmdxuUPbmYJRndHD74SCjtZdWuNCHSRjVMqHQCqJ9TrncH/";

    struct Status {
        // config
        uint256 price;
        uint32 maxSupply;
        uint32 publicSupply;
        uint32 instantFreeSupply;
        uint32 instantFreeWalletLimit;
        uint32 walletLimit;

        // state
        uint32 publicMinted;
        uint32 instantFreeMintLeft;
        uint32 userMinted;
        bool soldout;
        // bool started;
        MintStatus mintStatus;
    }

    constructor(
        uint256 price,
        uint32 maxSupply,
        uint32 teamSupply,
        uint32 instantFreeWalletLimit,
        uint32 maxMintAmount,
        uint32 walletLimit
    ) ERC721A("Moon Mosquito", "MM") {
       
        _lotterySalt = keccak256(abi.encodePacked(address(this), block.timestamp));
        _price = price;
        _maxSupply = maxSupply;
        _teamSupply = teamSupply;
        _instantFreeWalletLimit = instantFreeWalletLimit;
        _walletLimit = walletLimit;
        _maxMintAmount = maxMintAmount;

        setFeeNumerator(750);
    }

    function mint(uint32 amount) external payable {
        require(_mintStatus == MintStatus.Publicsale, "Moon Mosquito  : Public sale is not started yet");
        require(_maxMintAmount >= amount, "Moon Mosquito : Mint Number too large");
        uint32 publicMinted = _publicMinted();
        uint32 publicSupply = _publicSupply();
        require(amount + publicMinted <= publicSupply, "Moon Mosquito: Exceed max supply");
        uint32 minted = uint32(_numberMinted(msg.sender));
        emit LOG(minted);
        require(amount + minted <= _walletLimit, "Moon Mosquito: Exceed wallet limit");
        require(msg.value >= amount * _price, "Moon Mosquito: Insufficient fund");
        _safeMint(msg.sender, amount);
    }

    function _whiteListMint() external payable {
        require(_mintStatus == MintStatus.WhiteList, "Moon Mosquito: WhiteList sale is not started yet");
        require(_whiteList[msg.sender],"Moon Mosquito: No whitelist eligibility");
        uint32 instantFreeWalletLimit = _instantFreeWalletLimit;
        uint32 minted = uint32(_numberMinted(msg.sender));
        require(_instantFreeMinted + instantFreeWalletLimit < _instantFreeSupply,"Moon Mosquito: Exceed WhiteList max supply");
        require(minted < instantFreeWalletLimit, "Moon Mosquito: Lucky Baby You don't stand a chance");
        uint32 amount = minted == 0 ? (instantFreeWalletLimit) : (instantFreeWalletLimit - minted);
        _instantFreeMinted += instantFreeWalletLimit;
        _safeMint(msg.sender, amount);
    }

    function _publicMinted() public view returns (uint32) {
        return uint32(_totalMinted()) - _teamMinted - _instantFreeMinted;
    }

    function _publicSupply() public view returns (uint32) {
        return _maxSupply - _teamSupply - _instantFreeSupply;
    }
    //["0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2","0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db","0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB"]
    function _status(address minter) external view returns (Status memory) {
        uint32 publicSupply = _maxSupply - _teamSupply - _instantFreeSupply;
        uint32 publicMinted = uint32(ERC721A._totalMinted()) - _teamMinted -_instantFreeMinted;

        return Status({
            // config
            price: _price,
            maxSupply: _maxSupply,
            publicSupply:publicSupply,
            instantFreeSupply: _instantFreeSupply,
            instantFreeWalletLimit: _instantFreeWalletLimit,
            walletLimit: _walletLimit,

            // state
            publicMinted: publicMinted,
            instantFreeMintLeft: _instantFreeSupply - _instantFreeMinted,
            soldout:  publicMinted >= publicSupply,
            userMinted: uint32(_numberMinted(minter)),
            mintStatus: _mintStatus
        });
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _metadataURI;
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function devMint(address to, uint32 amount) external onlyOwner {
        _teamMinted += amount;
        require(_teamMinted <= _teamSupply, "Moon Mosquito: Exceed max supply");
        _safeMint(to, amount);
    }

    function setFeeNumerator(uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(owner(), feeNumerator);
    }

    function setMetadataURI(string memory uri) external onlyOwner {
        _metadataURI = uri;
    }

    function setMaxMintAmount(uint32 amount) external onlyOwner {
        _maxMintAmount = amount;
    }

    function setMintStatus(MintStatus status) external onlyOwner {
        _mintStatus = status;
        if(_mintStatus == MintStatus.Publicsale) {
            _setLuckyBabyQuantity();
        }
    }

    function _setLuckyBabyQuantity() internal {
        _instantFreeSupply = _instantFreeMinted < _instantFreeSupply ? (_instantFreeMinted) : (_instantFreeSupply);
    }

    function addLuckyBaby(address[] memory _address) public onlyOwner {
       require(_address.length > 0,"Moon Mosquito: Invalid address");
       for (uint256 i = 0; i < _address.length; i++) {
           address currentAddress = _address[i];
           _whiteList[currentAddress] = true;
           _instantFreeSupply += _instantFreeWalletLimit;
       }
    }

    function removeUnfortunatMan(address[] memory _address) public onlyOwner {
        require(_address.length > 0,"Moon Mosquito: Invalid address");
        for (uint256 i = 0; i < _address.length; i++) {
           address currentAddress = _address[i];
           _whiteList[currentAddress] = false;
           _instantFreeSupply -= _instantFreeWalletLimit;
       }
    }
    
    function inquiryLuckyBaby(address _address) public view returns(bool) {
        return _whiteList[_address] ? (true) : (false);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).sendValue(address(this).balance);
    }

}