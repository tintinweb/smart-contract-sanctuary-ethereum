// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Address.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./Ownable.sol";

import "./console.sol";

contract EggNft is ERC721, Ownable {
    event Received(address, uint256);
    event Fallback(address, uint256);

    event SetTotalSupply(address addr, uint256 _totalSupply);
    event SetOgPrice(address addr, uint256 _price);
    event SetWlPrice(address addr, uint256 _price);
    event SetPlPrice(address addr, uint256 _price);

    event SetOgLimit(address addr, uint256 _count);
    event SetWlLimit(address addr, uint256 _count);
    event SetPlLimit(address addr, uint256 _count);

    event WithdrawAll(address addr, uint256 cro);

    event SetBaseURI(string baseURI);
    event SetGoldenList(address _user);
    event SetOgList(address _user);
    event SetWlList(address _user);
    event SetPlList(address _user);

    using Strings for uint256;

    uint256 private TOTAL_SUPPLY = 7799;

    uint256 private MAX_MINT_AMOUNT = 20;

    uint256 private MAX_GOLDEN_COUNT = 7;
    uint256 private MAX_GOOD_OR_EVIL_COUNT = 4500;

    uint256 private ogPrice = 0.1 * 10**18;
    uint256 private wlPrice = 0.2 * 10**18;
    uint256 private plPrice = 0.3 * 10**18;

    uint256 private ogLimit = 100;
    uint256 private wlLimit = 200;
    uint256 private plLimit = 700;

    uint256 private _nftMintedCount;
    uint256 private _goldenNftMintedCount;
    uint256 private _goodNftMintedCount;
    uint256 private _evilNftMintedCount;

    string private _baseURIExtended;
    string private _baseExtension;
    bool private revealed;
    string private notRevealedUri;
    bool private paused;

    mapping(address => bool) _goldenList;
    mapping(address => bool) _ogList;
    mapping(address => bool) _wlList;
    mapping(address => bool) _plList;

    mapping(address => uint256) _ogMintedCountList;
    mapping(address => uint256) _wlMintedCountList;
    mapping(address => uint256) _plMintedCountList;

    constructor() ERC721("Egg NFT", "Egg") {
        _baseURIExtended = "https://ipfs.infura.io/";
        _baseExtension = ".json";
        _nftMintedCount = 0;
        _goldenNftMintedCount = 0;
        _goodNftMintedCount = 0;
        _evilNftMintedCount = 0;
        paused = false;
    }

    //only owner
    function reveal() external onlyOwner {
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI)
        external
        onlyOwner
    {
        notRevealedUri = _notRevealedURI;
    }

    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    fallback() external payable {
        emit Fallback(msg.sender, msg.value);
    }

    function setGoldenList(address _user) external onlyOwner {
        _goldenList[_user] = true;
        emit SetGoldenList(_user);
    }

    function setOgList(address _user) external onlyOwner {
        _ogList[_user] = true;
        emit SetOgList(_user);
    }

    function setWlList(address _user) external onlyOwner {
        _wlList[_user] = true;
        emit SetWlList(_user);
    }

    function setPlList(address _user) external onlyOwner {
        _plList[_user] = true;
        emit SetPlList(_user);
    }

    //Set, Get Price Func
    function setOgLimit(uint256 _count) external onlyOwner {
        ogLimit = _count;
        emit SetOgLimit(msg.sender, _count);
    }

    function getOgLimit() external view returns (uint256) {
        return ogLimit;
    }

    function setOgPrice(uint256 _price) external onlyOwner {
        ogPrice = _price;
        emit SetOgPrice(msg.sender, _price);
    }

    function getOgPrice() external view returns (uint256) {
        return ogPrice;
    }

    function setWlLimit(uint256 _count) external onlyOwner {
        wlLimit = _count;
        emit SetWlLimit(msg.sender, _count);
    }

    function getWlLimit() external view returns (uint256) {
        return wlLimit;
    }

    function setWlPrice(uint256 _price) external onlyOwner {
        wlPrice = _price;
        emit SetWlPrice(msg.sender, _price);
    }

    function getWlPrice() external view returns (uint256) {
        return wlPrice;
    }

    function setPlPrice(uint256 _price) external onlyOwner {
        plPrice = _price;
        emit SetPlPrice(msg.sender, _price);
    }

    function getPlPrice() external view returns (uint256) {
        return plPrice;
    }

    function setPlLimit(uint256 _count) external onlyOwner {
        wlLimit = _count;
        emit SetPlLimit(msg.sender, _count);
    }

    function getPlLimit() external view returns (uint256) {
        return plLimit;
    }

    function setTotalSupply(uint256 _totalSupply) external onlyOwner {
        TOTAL_SUPPLY = _totalSupply;
        emit SetTotalSupply(msg.sender, _totalSupply);
    }

    function getTotalSupply() external view returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseURIExtended = baseURI;
        emit SetBaseURI(baseURI);
    }

    function getBaseURI() external view returns (string memory) {
        return _baseURIExtended;
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
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

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        _baseExtension
                    )
                )
                : "";
    }

    function withdrawAll() external onlyOwner {
        address payable mine = payable(msg.sender);
        uint256 balance = address(this).balance;

        if (balance > 0) {
            mine.transfer(address(this).balance);
        }

        emit WithdrawAll(msg.sender, balance);
    }

    /**
     * @dev Mint NFT by customer
     */
    function mint(uint256 _mintAmount, uint8 _nftType) external payable {
        require(!paused, "The contract is paused");

        uint256 currentPrice;

        require(
            _nftMintedCount + _mintAmount < TOTAL_SUPPLY,
            "Already Finished Minting"
        );
        require(_mintAmount > 0, "mintAmount must be bigger than 0");
        require(_mintAmount <= MAX_MINT_AMOUNT, "Can't mint over 20 at once");

        require(_goldenList[msg.sender] == true || owner() == msg.sender || _ogList[msg.sender] == true || _wlList[msg.sender] == true || _plList[msg.sender] == true, "Invalid user");

        if (_nftType == 0) {
            // golden egg
            require(_goldenList[msg.sender] == true || owner() == msg.sender, "Only Golden Users can mint");
            require(
                _goldenNftMintedCount + _mintAmount <= MAX_GOLDEN_COUNT,
                "Overflow of golden eggs"
            );
            _goldenNftMintedCount += _mintAmount;
        } else {
            require(
                _goodNftMintedCount + _evilNftMintedCount + _mintAmount <= (TOTAL_SUPPLY - MAX_GOLDEN_COUNT),
                "Overflow of total of the golden or evil eggs"
            );
            if (_nftType == 1) {
                // good egg
                require(
                    _goodNftMintedCount + _mintAmount <= MAX_GOOD_OR_EVIL_COUNT || _evilNftMintedCount <= MAX_GOOD_OR_EVIL_COUNT,
                    "Overflow of 4500 good eggs"
                );
                _goodNftMintedCount += _mintAmount;
            } else {
                // evil egg
                require(
                    _evilNftMintedCount + _mintAmount <= MAX_GOOD_OR_EVIL_COUNT || _goodNftMintedCount <= MAX_GOOD_OR_EVIL_COUNT,
                    "Overflow of 4500 good eggs"
                );
                _evilNftMintedCount += _mintAmount;
            }
        }

        if ( _ogList[msg.sender] == true ) {
            require(
                _ogMintedCountList[msg.sender] + _mintAmount <= ogLimit,
                "Overflow of your eggs"
            );
            currentPrice = ogPrice;
            _ogMintedCountList[msg.sender] += _mintAmount;
        } else if ( _wlList[msg.sender] == true ) {
            require(
                _wlMintedCountList[msg.sender] + _mintAmount <= wlLimit,
                "Overflow of your eggs"
            );
            currentPrice = wlPrice;
            _wlMintedCountList[msg.sender] += _mintAmount;
        } else {
            require(
                _plMintedCountList[msg.sender] + _mintAmount <= plLimit,
                "Overflow of your eggs"
            );
            currentPrice = plPrice;
            _plMintedCountList[msg.sender] += _mintAmount;
        }

        currentPrice = currentPrice * _mintAmount;

        console.log('currentPrice: ', currentPrice, msg.value);

        require(msg.value >= currentPrice, "Not Enough Money");

        uint256 idx;

        for (idx = 0; idx < _mintAmount; idx++) {
            _safeMint(msg.sender, _nftMintedCount);
            _nftMintedCount++;
        }
    }

    function getMintedCount() external view returns (uint256) {
        return _nftMintedCount;
    }
    function getGoodMintedCount() external view returns (uint256) {
        return _goodNftMintedCount;
    }
    function getEvilMintedCount() external view returns (uint256) {
        return _evilNftMintedCount;
    }

    function getPrice() external view returns (uint256) {
        uint256 currentPrice = 0;
        if ( _ogList[msg.sender] == true ) {
            currentPrice = ogPrice;
        } else if ( _wlList[msg.sender] == true ) {
            currentPrice = wlPrice;
        } else {
            currentPrice = plPrice;
        }
        return currentPrice;
    }
}