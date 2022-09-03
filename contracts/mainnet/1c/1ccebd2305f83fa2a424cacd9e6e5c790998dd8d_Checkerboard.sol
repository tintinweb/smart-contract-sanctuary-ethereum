// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";

contract Checkerboard is ERC721 {
    uint private constant TOKEN_LIMIT = 365;
    string private constant SCRIPT = "let b = []; for (let i = 2; i < 66; i += 4) { b.push(hashString.slice(i, i + 5)); } let decRows = b.map(x => parseInt(x, 16)); let mask = 0x1F; let light = (decRows[0] & mask) > 3; let grid = decRows[8] & mask; let items = grid < 7 || grid > 16 ? 16 : grid; let colorsR = light ? [180,110,220,180,110,220,210,200,170,220,180,150, 180,110,220,180,110,220,210,200,170,220,180,150,180,110,220,210,180,170,180,110] : [140,10,140,140,10,140,140,10,140,140,10,140,140,10,140,140,10,140,140,10,140,140,10,140,140,10,140,140,10,140,140,10]; let colorsG = light ? [110,140,200,110,140,200,210,200,170,220,180,150, 110,140,200,110,140,200,210,200,170,220,180,150,110,140,200,210,180,170,110,140] : [60,60,10,60,60,10,60,60,10,60,60,60,60,60,10,60,60,10,60,60,10,60,60,10,60,60,10,60,60,10,60,60]; let colorsB = light ? [120,200,130,120,200,130,220,210,180,230,190,160, 120,200,130,120,200,130,220,210,180,230,190,160,120,200,130,220,190,180,120,200] : [10,140,60,10,140,60,10,140,60,10,140,10,10,140,60,10,140,60,10,140,60,10,140,60,10,140,60,10,140,60,10,140]; let border = 2; let itemBorder = 1 + (decRows[10] & 0x3) * 0.25; let itemHeight = 20; let itemWidth = 25; let scale, dimHeight, dimWidth; function setup() { dimHeight = (border * 2) + (itemHeight * items); dimWidth = (border * 2) + (itemWidth * items); scale = Math.min(window.innerWidth/dimWidth, window.innerHeight/dimHeight); createCanvas(dimWidth * scale, dimHeight * scale); background(50); itemBorder *= scale; border *= scale; itemHeight *= scale; itemWidth *= scale; } function draw() { let i = 0; let row = 0; let maxWidth = (dimWidth * scale) - border; let maxHeight = (dimHeight * scale) - border; for (var y = border; (y + border) < maxHeight; y += itemHeight) { let rowValue = decRows[row % 16]; i = 0; for (var x = border; (x + border) < maxWidth; x += itemWidth) { let shifted = rowValue >> i; let colorIndex = (shifted & mask); fill(colorsR[colorIndex], colorsG[colorIndex], colorsB[colorIndex]); stroke(80); strokeWeight(itemBorder); rect(x, y, itemWidth, itemHeight); i++; } row++; } noLoop(); }";
    uint private _tokenPrice = 5000000000000000;
    address private _platform;
    uint private _numSamples;
    uint private _numTokens = 0;
    mapping (uint => uint) private _idToSeed;
    string private _imageBaseUrl;
    string private _imageBaseExtension;
    string private _generatedBaseUrl;
    bool private _paused = true;
    bool private _presale = false;
    address private _oceanAddress = 0xF00B550Ac2C9eF0eA74e01d41480444d45599d6E;
    mapping (uint => bool) private _presaleId;
    
    constructor() ERC721("Checkerboard", unicode"⚄") {
        _platform = msg.sender;
        _imageBaseUrl = 'http://grid.myartcontract.com/';
        _imageBaseExtension = '.svg';
        _generatedBaseUrl = 'https://myartcontract.com/project/image.html?contract=';
        _numSamples = 5;
    }
    
    function totalSupply() public pure returns (uint) {
        return TOKEN_LIMIT;
    }
    
    function price() public view returns (uint) {
        return _tokenPrice;
    }
    
    function created() public view returns (uint) {
        return _numTokens;
    }
    
    function createSamples(uint amount) external payable returns (uint) {
        require(msg.sender == _platform);
        require((_numTokens + amount) <= _numSamples);
        for (uint i = 0; i < amount; i++) {
            _create(msg.sender);
        }
        return amount;
    }

    function createForAddress(address receiver) external payable returns (uint) {
        require(msg.sender == _platform);
        require(_numTokens < totalSupply());
        uint _id = _create(receiver);
        return _id;
    }
    
    function create() external payable returns (uint) {
        require(this.canCreateArt());
        require(msg.value >= price());
        uint _id = _create(msg.sender);
        payable(_platform).transfer(msg.value);
        return _id;
    }

    function createPresale(uint oceanTokenId) external payable returns (uint) {
        require(_numTokens < totalSupply() && _presale);
        require(msg.value >= price());
        require(oceanTokenId > 0 && oceanTokenId <= 101);
        require(msg.sender == IERC721(_oceanAddress).ownerOf(oceanTokenId));
        require(!_presaleId[oceanTokenId]);
        _presaleId[oceanTokenId] = true;
        uint _id = _create(msg.sender);
        payable(_platform).transfer(msg.value);
        return _id;
    }

    function setPresale(bool presale) public {
        require(msg.sender == _platform);
        _presale = presale;
    }

    function isOceanTokenUsed(uint oceanTokenId) external view returns (bool) {
        return _presaleId[oceanTokenId];
    }

    function _create(address _creator) internal returns (uint) {
        require(_creator != address(0));
        _numTokens = _numTokens + 1;
        uint _id = _numTokens;
        uint _seed = hash(_id, _creator);
        _idToSeed[_id] = _seed;
        _safeMint(_creator, _id);
        return _id;
    }
    
    function canCreateArt() external view returns (bool) {
        return _numTokens >= _numSamples && _numTokens < totalSupply() && !_paused;
    }
    
    function hash(uint tokenId, address creator) private view returns (uint) {
        return uint(keccak256(abi.encodePacked(this.name(), tokenId, creator)));
    }
    
    function setPaused(bool paused) public {
        require(msg.sender == _platform);
        _paused = paused;
    }

    function setTokenPrice(uint tokenPrice) public {
        require(msg.sender == _platform);
        _tokenPrice = tokenPrice;
    }

    function setImageBase(string memory imageUrl, string memory imageExtension) public {
        require(msg.sender == _platform);
        _imageBaseUrl = imageUrl;
        _imageBaseExtension = imageExtension;
    }

    function setGeneratedBaseUrl(string memory url) public {
        require(msg.sender == _platform);
        _generatedBaseUrl = url;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (tokenId > 0 && tokenId <= _numTokens) {
            string memory _imageUrl = StrUtil.strConcat(_imageBaseUrl, Strings.toString(tokenId), _imageBaseExtension);
            string memory _generatedUrl = StrUtil.strConcat(_generatedBaseUrl, Strings.toHexString(uint256(uint160(address(this)))), '&id=', Strings.toString(tokenId));
            string memory _urls = StrUtil.strConcat('"image":"', _imageUrl, '","external_url":"https://www.myartcontract.com/","animation_url":"', _generatedUrl, '",');
            return StrUtil.strConcat('data:application/json,{"name":"Composition with grid No. ', Strings.toString(tokenId), '","description":"Piet Mondrian produced both Composition with grid 9: Checkerboard composition with bright colors and Composition with grid 8: Checkerboard composition with dark colors around 1919. Both art works are included in this generative art script on the Ethereum Blockchain. The dark colors represents a starry sky, while the bright colors show us the morning light. Every color on the grid is determined by a 5 bit value stored on-chain, all separated by strictly straight lines.",', _urls, '"interaction":"None"}');
        } else {
            return "";
        }
    }
    
    function script(uint tokenId) external view returns (string memory) {
        uint _seed = _idToSeed[tokenId];
        if (_seed > 0) {
            return StrUtil.strConcat("let hashString = '", Strings.toHexString(_seed), "'; ", SCRIPT);
        }
        return "";
    }
    
    function withdraw() public {
        require(msg.sender == _platform);
        require(address(this).balance > 0);
        payable(_platform).transfer(address(this).balance);
    }
}

library StrUtil {
    // https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, "", "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory _concatenatedString) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        uint i = 0;
        for (i = 0; i < _ba.length; i++) {
            babcde[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            babcde[k++] = _bb[i];
        }
        for (i = 0; i < _bc.length; i++) {
            babcde[k++] = _bc[i];
        }
        for (i = 0; i < _bd.length; i++) {
            babcde[k++] = _bd[i];
        }
        for (i = 0; i < _be.length; i++) {
            babcde[k++] = _be[i];
        }
        return string(babcde);
    }
}