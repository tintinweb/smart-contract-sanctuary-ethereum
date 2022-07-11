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

contract LunaticsFlies is ERC2981, ERC721AQueryable, Ownable {
    using Address for address payable;
    using Strings for uint256;

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
    string public _metadataURI;

    struct Status {
        // config
        uint256 price;      // 价格
        uint32 maxSupply;   // 总量
        uint32 publicSupply;  // 公共轮总量
        uint32 instantFreeSupply; // 白名单总量张
        uint32 instantFreeWalletLimit; // 白名单mint数量
        uint32 walletLimit; // 钱包总量

        // state
        uint32 publicMinted;    // 公共mint数量
        uint32 instantFreeMintLeft; // 当前白名单剩余mint数量
        uint32 userMinted; // 当前用户mint数量
        bool soldout; // 是否卖光
        uint32 totalSupply; //当前nft mint 数量
        MintStatus mintStatus; // mint 状态
    }

    constructor(
        uint256 price,
        uint32 maxSupply,
        uint32 teamSupply,
        uint32 instantFreeWalletLimit,
        uint32 maxMintAmount,
        uint32 walletLimit,
        string memory metadataURI
    ) ERC721A("Lunatics Flies", "LF") {
       
        _price = price;
        _maxSupply = maxSupply;
        _teamSupply = teamSupply;
        _instantFreeWalletLimit = instantFreeWalletLimit;
        _walletLimit = walletLimit;
        _maxMintAmount = maxMintAmount;
        _metadataURI = metadataURI;
        setFeeNumerator(700);
    }

    function _mint(uint32 amount) external payable {
        require(_mintStatus == MintStatus.Publicsale, "LF  : Public sale is not started yet");
        require(_maxMintAmount >= amount, "LF : Mint Number too large");
        uint32 publicMinted = _publicMinted();
        uint32 publicSupply = _publicSupply();
        require(amount + publicMinted <= publicSupply, "LF : Exceed max supply");
        uint32 minted = uint32(_numberMinted(msg.sender));
        require(amount + minted <= _walletLimit, "LF : Exceed wallet limit");
        require(msg.value >= amount * _price, "LF: Insufficient fund");
        _safeMint(msg.sender, amount);
    }

    function _mintWhiteListed() external payable {
        require(_mintStatus == MintStatus.WhiteList, "LF: WhiteList sale is not started yet");
        require(_whiteList[msg.sender],"LF: No whitelist eligibility");
        uint32 instantFreeWalletLimit = _instantFreeWalletLimit;
        uint32 minted = uint32(_numberMinted(msg.sender));
        require(_instantFreeMinted + instantFreeWalletLimit <= _instantFreeSupply,"LF: Exceed WhiteList max supply");
        require(minted < instantFreeWalletLimit, "LF: Lucky Baby You don't stand a chance");
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
            totalSupply: uint32(totalSupply()),
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
        require(_teamMinted <= _teamSupply, "LF: Exceed max supply");
        _teamMinted += amount;
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
       require(_address.length > 0,"LF: Invalid address");
       for (uint256 i = 0; i < _address.length; i++) {
           address currentAddress = _address[i];
           _whiteList[currentAddress] = true;
           _instantFreeSupply += _instantFreeWalletLimit;
       }
    }

    function removeUnfortunatMan(address[] memory _address) public onlyOwner {
        require(_address.length > 0,"LF : Invalid address");
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