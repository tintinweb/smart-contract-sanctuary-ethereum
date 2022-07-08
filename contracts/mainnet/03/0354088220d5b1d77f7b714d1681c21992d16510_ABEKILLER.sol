// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC2981.sol";
import "./Address.sol";
import "./Strings.sol";
import "./ERC721AQueryable.sol";

contract ABEKILLER is ERC2981, ERC721AQueryable, Ownable {
    using Address for address payable;
    using Strings for uint256;

    event LuckyBoy(address minter, uint32 amount);

    bytes32 public immutable _lotterySalt;
    uint256 public immutable _price;
    uint32 public immutable _maxSupply;
    uint32 public immutable _teamSupply;
    uint32 public immutable _instantFreeSupply;
    uint32 public immutable _randomFreeSupply;
    uint32 public immutable _instantFreeWalletLimit;
    uint32 public immutable _walletLimit;

    uint32 public _teamMinted;
    uint32 public _randomFreeMinted;
    uint32 public _instantFreeMinted;
    uint32 public _maxMintAmount;
    bool public _started;
    string public _metadataURI = "https://gateway.pinata.cloud/ipfs/Qme7b3NyZsqoxevtcAoH5dYGQ3WkD4YtdoUoRYbUDM2q3K/";
    struct Status {
        // config
        uint256 price;
        uint32 maxSupply;
        uint32 publicSupply;
        uint32 instantFreeSupply;
        uint32 randomFreeSupply;
        uint32 instantFreeWalletLimit;
        uint32 walletLimit;

        // state
        uint32 publicMinted;
        uint32 instantFreeMintLeft;
        uint32 randomFreeMintLeft;
        uint32 userMinted;
        bool soldout;
        bool started;
    }

    constructor(
        uint256 price, 
        uint32 maxSupply, 
        uint32 teamSupply, 
        uint32 instantFreeSupply, 
        uint32 randomFreeSupply, 
        uint32 instantFreeWalletLimit, 
        uint32 maxMintAmount, 
        uint32 walletLimit 
    ) ERC721A("ABE KILLER", "ABE") {
        require(maxSupply >= teamSupply + instantFreeSupply);
        require(maxSupply - teamSupply - instantFreeSupply >= randomFreeSupply);

        _lotterySalt = keccak256(abi.encodePacked(address(this), block.timestamp));
        _price = price;
        _maxSupply = maxSupply;
        _teamSupply = teamSupply;
        _instantFreeSupply = instantFreeSupply;
        _instantFreeWalletLimit = instantFreeWalletLimit;
        _randomFreeSupply = randomFreeSupply;
        _walletLimit = walletLimit;
        _maxMintAmount = maxMintAmount;

        setFeeNumerator(750);
    }

    function mint(uint32 amount) external payable {
        require(_started, "ABE : Sale is not started");
        require(_maxMintAmount >= amount, "ABE : Mint Number too large");

        uint32 publicMinted = _publicMinted();
        uint32 publicSupply = _publicSupply();
        require(amount + publicMinted <= _publicSupply(), "ABE : Exceed max supply");

        uint32 minted = uint32(_numberMinted(msg.sender));
        require(amount + minted <= _walletLimit, "ABE : Exceed wallet limit");

        uint32 instantFreeWalletLimit = _instantFreeWalletLimit;
        uint32 freeAmount = 0;

        if (minted < instantFreeWalletLimit) {
            uint32 quota = instantFreeWalletLimit - minted;
            freeAmount += quota > amount ? amount : quota;
        }

        if (minted + amount > instantFreeWalletLimit) {
            uint32 enterLotteryAmount = amount - instantFreeWalletLimit;
            uint32 randomFreeAmount = 0;
            uint32 randomFreeMinted = _randomFreeMinted;
            uint32 quota = _randomFreeSupply - randomFreeMinted;

            if (quota > 0) {
                uint256 randomSeed = uint256(keccak256(abi.encodePacked(
                    msg.sender,
                    publicMinted,
                    block.difficulty,
                    _lotterySalt)));

                for (uint256 i = 0; i < enterLotteryAmount && quota > 0; ) {
                    if (uint16((randomSeed & 0xFFFF) % publicSupply) < quota) {
                        randomFreeAmount += 1;
                        quota -= 1;
                    }

                    unchecked {
                        i++;
                        randomSeed = randomSeed >> 16;
                    }
                }

                if (randomFreeAmount > 0) {
                    freeAmount += randomFreeAmount;
                    _randomFreeMinted += randomFreeAmount;
                    emit LuckyBoy(msg.sender, randomFreeAmount);
                }
            }
        }

        uint256 requiredValue = (amount - freeAmount) * _price;
        require(msg.value >= requiredValue, "ABE : Insufficient fund");

        _safeMint(msg.sender, amount);
        if (msg.value > requiredValue) {
            payable(msg.sender).sendValue(msg.value - requiredValue);
        }
    }

    function _publicMinted() public view returns (uint32) {
        return uint32(_totalMinted()) - _teamMinted;
    }

    function _publicSupply() public view returns (uint32) {
        return _maxSupply - _teamSupply;
    }

    function _status(address minter) external view returns (Status memory) {
        uint32 publicSupply = _maxSupply - _teamSupply;
        uint32 publicMinted = uint32(ERC721A._totalMinted()) - _teamMinted;

        return Status({
            // config
            price: _price,
            maxSupply: _maxSupply,
            publicSupply:publicSupply,
            instantFreeSupply: _instantFreeSupply,
            randomFreeSupply: _randomFreeSupply,
            instantFreeWalletLimit: _instantFreeWalletLimit,
            walletLimit: _walletLimit,

            // state
            publicMinted: publicMinted,
            instantFreeMintLeft: _instantFreeSupply - _instantFreeMinted,
            randomFreeMintLeft: _randomFreeSupply - _randomFreeMinted,
            soldout:  publicMinted >= publicSupply,
            userMinted: uint32(_numberMinted(minter)),
            started: _started
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
        require(_teamMinted <= _teamSupply, "ABE : Exceed max supply");
        _safeMint(to, amount);
    }

    function setFeeNumerator(uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(owner(), feeNumerator);
    }

    function setStarted(bool started) external onlyOwner {
        _started = started;
    }

    function setMetadataURI(string memory uri) external onlyOwner {
        _metadataURI = uri;
    }

    function setMaxMintAmount(uint32 amount) external onlyOwner {
        _maxMintAmount = amount;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).sendValue(address(this).balance);
    }

}