// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Address.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract EggNft is ERC721, Ownable {
    event Received(address, uint256);
    event Fallback(address, uint256);

    event SetTotalSupply(address addr, uint256 _maxSupply);
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
    event EggType(string _eggtype, address addr);
    event SetPlList(address _user);

    using Strings for uint256;

    uint256 private MAX_SUPPLY = 7799;

    uint256 private MAX_MINT_AMOUNT = 3;

    uint256 private MAX_GOOD_OR_EVIL_COUNT = 4500;

    uint256 private ogPrice = 0.001 ether;
    uint256 private wlPrice = 0.0015 ether;
    uint256 private plPrice = 0.002 ether;

    uint256 private ogLimit = 3;
    uint256 private wlLimit = 3;
    uint256 private plLimit = 3;

    uint256 private _nftMintedCount;
    uint256 private _goodNftMintedCount;
    uint256 private _evilNftMintedCount;
    uint256 private mintType = 0;
    string private _baseURIExtended;
    string private _baseExtension;
    bool private revealed;
    string private notRevealedGoodEggUri;
    string private notRevealedEvilEggUri;

    
    bool private paused;

    mapping(address => uint256) _ogMintedCountList;
    mapping(address => uint256) _wlMintedCountList;
    mapping(address => uint256) _plMintedCountList;
    mapping(uint256 => uint256) _uriToTokenId;

    bytes32 private merkleOgListRoot =
        0xc72d2373ed597cc1eccd45955203671adfd9ffe47c2050a819670fc66635011c;
    bytes32 private merkleWlListRoot =
        0xc72d2373ed597cc1eccd45955203671adfd9ffe47c2050a819670fc66635011c;

    constructor() ERC721("Aibo Adventures", "AA") {
        _baseURIExtended = "https://ipfs.infura.io/";
        _baseExtension = ".json";
        _nftMintedCount = 0;
        _goodNftMintedCount = 0;
        _evilNftMintedCount = 0;
        paused = true;
        revealed = false;
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function setOGMerkleRoot(bytes32 root) external onlyOwner {
        merkleOgListRoot = root;
    }

    function setWLMerkleRoot(bytes32 root) external onlyOwner {
        merkleWlListRoot = root;
    }

    function setNotRevealedURI(string memory _gooduri, string memory _eviluri)
        external
        onlyOwner
    {
        notRevealedGoodEggUri = _gooduri;
        notRevealedEvilEggUri = _eviluri;
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

    function setMintType(uint256 nftMintType) external onlyOwner {
        mintType = nftMintType;
    }

    function getNftMintPrice(uint256 amount) external view returns (uint256) {
        if (mintType == 0) {
            return amount * ogPrice;
        } else if (mintType == 1) {
            return amount * wlPrice;
        } else {
            return amount * plPrice;
        }
    }

    function getUserWhiteListed(bytes32[] calldata _merkleProof)
        external
        view
        returns (uint256)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        uint256 value;
        if (mintType == 0) {
            require(
                MerkleProof.verify(_merkleProof, merkleOgListRoot, leaf) ==
                    true,
                "Not registered at og"
            );
            value = 1;
        } else if (mintType == 1) {
            require(
                MerkleProof.verify(_merkleProof, merkleWlListRoot, leaf) ==
                    true,
                "Not registered at wl"
            );
            value = 2;
        } else {
            value = 3;
        }
        return value;
    }

    function setOgLimit(uint256 _count) external onlyOwner {
        ogLimit = _count;
        emit SetOgLimit(msg.sender, _count);
    }

    function getMintType() external view returns (uint256) {
        return mintType;
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

    function getOgMintedCountList() external view returns (uint256) {
        return _ogMintedCountList[msg.sender];
    }

    function getWlMintedCountList() external view returns (uint256) {
        return _wlMintedCountList[msg.sender];
    }

    function getPlMintedCountList() external view returns (uint256) {
        return _plMintedCountList[msg.sender];
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

    function setTotalSupply(uint256 _maxSupply) external onlyOwner {
        MAX_SUPPLY = _maxSupply;
        emit SetTotalSupply(msg.sender, _maxSupply);
    }

    function totalSupply() external view returns (uint256) {
        return _nftMintedCount;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseURIExtended = baseURI;
        emit SetBaseURI(baseURI);
    }

    function getBaseURI() external view returns (string memory) {
        return _baseURIExtended;
    }

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
            if (_uriToTokenId[tokenId] <= MAX_GOOD_OR_EVIL_COUNT) {
                return notRevealedGoodEggUri;
            } else {
                return notRevealedEvilEggUri;
            }
        } else {
            string memory currentBaseURI = _baseURI();
            return
                bytes(currentBaseURI).length > 0
                    ? string(
                        abi.encodePacked(
                            currentBaseURI,
                            _uriToTokenId[tokenId].toString(),
                            _baseExtension
                        )
                    )
                    : "";
        }
    }

    function withdrawAll() external onlyOwner {
        address payable mine = payable(msg.sender);
        uint256 balance = address(this).balance;

        if (balance > 0) {
            mine.transfer(address(this).balance);
        }

        emit WithdrawAll(msg.sender, balance);
    }

    function mint(
        uint256 _mintAmount,
        bytes32[] calldata _merkleProof,
        uint256 _nftType
    ) external payable {
        require(!paused, "The contract is paused");
        require(
            _nftMintedCount + _mintAmount <= MAX_SUPPLY,
            "Already Finished Minting"
        );
        require(_mintAmount > 0, "mintAmount must be bigger than 0");
        if (msg.sender != owner()) {
            require(
                _mintAmount <= MAX_MINT_AMOUNT,
                "Can't mint over 20 at once"
            );
        }

        uint256 currentPrice;
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (mintType == 0) {
            require(
                MerkleProof.verify(_merkleProof, merkleOgListRoot, leaf) ==
                    true,
                "Not registered at og"
            );
            require(
                _ogMintedCountList[msg.sender] + _mintAmount <= ogLimit,
                "Overflow of your eggs"
            );
            currentPrice = ogPrice;
            _ogMintedCountList[msg.sender] += _mintAmount;
        } else if (mintType == 1) {
            require(
                MerkleProof.verify(_merkleProof, merkleWlListRoot, leaf) ==
                    true,
                "Not registered at wl"
            );
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
        require(currentPrice <= msg.value, "Not Enough Money");

        if (_nftType == 1) {
            require(
                _goodNftMintedCount + _mintAmount <= MAX_GOOD_OR_EVIL_COUNT,
                "Overflow of MAX good eggs"
            );

            require(
                _goodNftMintedCount + _evilNftMintedCount + _mintAmount <=
                    MAX_SUPPLY,
                "Overflow of MAX_SUPPLY"
            );
            emit EggType("GoodEgg", msg.sender);

            uint256 idx;
            for (idx = 0; idx < _mintAmount; idx++) {
                _nftMintedCount++;
                _goodNftMintedCount++;
                _uriToTokenId[_nftMintedCount + idx] = _goodNftMintedCount;
                _safeMint(msg.sender, _nftMintedCount);
            }
        } else {
            require(
                _evilNftMintedCount + _mintAmount <= MAX_GOOD_OR_EVIL_COUNT,
                "Overflow of MAX evil eggs"
            );

            require(
                _goodNftMintedCount + _evilNftMintedCount + _mintAmount <=
                    MAX_SUPPLY,
                "Overflow of MAX_SUPPLY"
            );
            emit EggType("EvilEgg", msg.sender);

            uint256 idx;
            for (idx = 0; idx < _mintAmount; idx++) {
                _nftMintedCount++;
                _evilNftMintedCount++;
                _uriToTokenId[_nftMintedCount + idx] =
                    MAX_GOOD_OR_EVIL_COUNT +
                    _evilNftMintedCount;
                _safeMint(msg.sender, _nftMintedCount);
            }
        }
    }

    function getMaxSupply() external view returns (uint256) {
        return MAX_SUPPLY;
    }

    function getGoodMintedCount() external view returns (uint256) {
        return _goodNftMintedCount;
    }

    function getEvilMintedCount() external view returns (uint256) {
        return _evilNftMintedCount;
    }
}