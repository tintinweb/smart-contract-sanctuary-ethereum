// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";

contract Ocean is ERC721 { 
    uint private constant TOKEN_LIMIT = 101;
    string private constant SCRIPT = "let hor = []; for (let i = 2; i < 34; i+=4) { hor.push(hashString.slice(i, i+4)); } let ver = []; for (let i = 34; i < 66; i+=4) { ver.push(hashString.slice(i, i+4)); } let horLines = hor.map(x => parseInt(x, 16)); let verLines = ver.map(x => parseInt(x, 16)); let mask = 0xFF; let backgroundIndex; let backgroundArray = [255,200,100,50,0]; let outPadding = 40; let inPadding = 15; let size = 25; let scale; let dim; function setup() { dim = (72 * (size + inPadding)); let screen = Math.min(window.innerWidth, window.innerHeight) - 16; scale = screen/(dim + (outPadding * 2)); createCanvas(screen, screen); colorMode(RGB, 256,1,1,255); backgroundIndex = (horLines[0] & mask) < 26 ? 4 : 0; } function drawLines(line, i, extPadding, pos, horizontal) { let verVal = (line >> i) & mask; if (verVal < size) { verVal += size; } else if (verVal > (72*2)) { drawLine(extPadding, pos, verVal / 2.85, horizontal); drawLine(extPadding, pos, verVal / 2.05, horizontal); drawLine(extPadding, pos, verVal / 1.70, horizontal); verVal /= 1.25; } else if (verVal > 72) { drawLine(extPadding, pos, verVal / 2.25, horizontal); verVal /= 1.5; } drawLine(extPadding, pos, verVal, horizontal); } function drawLine(extPadding, start, value, horizontal) { let item = outPadding + extPadding + (((dim - (extPadding * 2)) - 256) / 72) * (value % 72); if (horizontal) { line(item * scale, start * scale, (item + value) * scale, start * scale); } else { line(start * scale, item * scale, start * scale, (item + value) * scale); } } function keyPressed() { if (keyCode === 32) { if (backgroundIndex < backgroundArray.length - 1) { backgroundIndex++; } else { backgroundIndex = 0; } } } function draw() { background(backgroundArray[backgroundIndex]); strokeWeight(size * scale); strokeCap(SQUARE); stroke(255-backgroundArray[backgroundIndex], 255-backgroundArray[backgroundIndex], 255-backgroundArray[backgroundIndex]); let item = 0; for (let o = 0; o < 8; o++) { for (var i = 0; i < 9; i++) { let extPadding = item < 18 ? (dim / 54) * (18 - item) : item >= 54 ? (dim / 54) * ( item - 54) : 0; let pos = (item * (size + inPadding)) + outPadding; drawLines(verLines[o], i, extPadding, pos, false); drawLines(horLines[o], i, extPadding, pos, true); item++; } } }";
    uint private _tokenPrice = 44000000000000000;
    address private _platform;
    uint private _numSamples;
    uint private _numTokens = 0;
    mapping (uint => uint) private _idToSeed;
    string private _imageBaseUrl;
    string private _imageBaseExtension;
    string private _generatedBaseUrl;
    bool private _paused = true;
    
    constructor() ERC721("OCEAN", "OCEAN") {
        _platform = msg.sender;
        _imageBaseUrl = 'http://ocean.myartcontract.com/';
        _imageBaseExtension = '.svg';
        _generatedBaseUrl = 'http://project.myartcontract.com/image.html?contract=';
        _numSamples = 3;
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
            return StrUtil.strConcat('data:application/json,{"name":"OCEAN %23', Strings.toString(tokenId), '","description":"The My Art Contract Genesis collection inpired by the work of Piet Mondriaan that captures the pier and the ocean.",', _urls, '"interaction":"Space bar changes the canvas color"}');
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