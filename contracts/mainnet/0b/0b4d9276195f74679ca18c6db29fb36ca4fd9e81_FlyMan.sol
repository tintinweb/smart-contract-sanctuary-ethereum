// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC2981.sol";
import "./Address.sol";
import "./Strings.sol";
import "./ERC721AQueryable.sol";

enum Stage {
    NotStarted,
    Claim,
    Sale
}

contract FlyMan is ERC2981, ERC721AQueryable, Ownable {
    using Address for address payable;
    using Strings for uint256;

    address public constant BLACKHOLE = 0x000000000000000000000000000000000000dEaD;

    IERC721 public immutable _fly;

    uint256 public _price;
    uint32 public immutable _maxSupply;
    uint32 public immutable _holderSupply;
    uint32 public immutable _teamSupply;
    uint32 public immutable _walletLimit;

    uint32 public _teamMinted;
    uint32 public _holderClaimed;
    string public _metadataURI;
    string public _notRevealedUri = "ipfs://QmUQNKQ5RN9s7FDBzeeu3N7DxaAoHB8jr1caDueKpofhZ9";
    Stage public _stage = Stage.NotStarted;
    bool public _revealed = false;

    struct Status {
        uint256 price;
        uint32 maxSupply;
        uint32 publicSupply;
        uint32 walletLimit;
        uint32 publicMinted;
        uint32 userMinted;
        bool soldout;
        Stage stage;
    }

    constructor(
        address fly,
        uint256 price,
        uint32 maxSupply,
        uint32 holderSupply,
        uint32 teamSupply,
        uint32 walletLimit
    ) ERC721A("FLY MAN", "FLY") {
        require(fly != address(0));
        require(maxSupply >= holderSupply + teamSupply);

        _fly = IERC721(fly);
        _price = price;
        _maxSupply = maxSupply;
        _holderSupply = holderSupply;
        _teamSupply = teamSupply;
        _walletLimit = walletLimit;

        setFeeNumerator(750);
    }

    function claim(uint256[] memory tokenIds) external {
        require(_stage == Stage.Claim);
        require(tokenIds.length > 0 && tokenIds.length % 2 == 0);
        uint32 pairs = uint32(tokenIds.length / 2);
        require(pairs + _holderClaimed <= _holderSupply);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _fly.transferFrom(msg.sender, BLACKHOLE, tokenIds[i]);
            unchecked {
                i++;
            }
        }
        _setAux(msg.sender, _getAux(msg.sender) + pairs);
        _safeMint(msg.sender, pairs);
    }

    function mint(uint32 amount) external payable {
        require(_stage == Stage.Sale);
        require(amount + _publicMinted() <= _publicSupply());
        require(amount + uint32(_numberMinted(msg.sender)) - uint32(_getAux(msg.sender)) <= _walletLimit);
        require(msg.value == amount * _price);
        _safeMint(msg.sender, amount);
    }

    function _publicMinted() public view returns (uint32) {
        return uint32(_totalMinted()) - _teamMinted;
    }

    function _publicSupply() public view returns (uint32) {
        return _maxSupply - _teamSupply;
    }

    function _status(address minter) external view returns (Status memory) {
        uint32 publicSupply = _publicSupply();
        uint32 publicMinted = _publicMinted();
        return Status({
            price: _price,
            maxSupply: _maxSupply,
            publicSupply: publicSupply,
            walletLimit: _walletLimit,
            publicMinted: publicMinted,
            soldout: publicMinted >= publicSupply,
            userMinted: uint32(_numberMinted(minter)) - uint32(_getAux(msg.sender)),
            stage: _stage
        });
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if ( _revealed == false ) {
            return _notRevealedUri;
        }
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
        require(_teamMinted <= _teamSupply);
        _safeMint(to, amount);
    }

    function setFeeNumerator(uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(owner(), feeNumerator);
    }

    function setStage(Stage stage) external onlyOwner {
        _stage = stage;
    }

    function setPrice(uint256 price) external onlyOwner {
        _price = price;
    }

    function setMetadataURI(string memory uri) external onlyOwner {
        _metadataURI = uri;
    }

    function setNotRevealedURI( string memory notRevealedURI ) public onlyOwner {
        _notRevealedUri = notRevealedURI;
    }

    function setRevealed(bool revealed) public onlyOwner {
        _revealed = revealed;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).sendValue(address(this).balance);
    }

}