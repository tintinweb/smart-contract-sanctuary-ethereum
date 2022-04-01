//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import 'base64-sol/base64.sol';

contract Egg is ERC721URIStorage, Ownable {
    
    uint256 public tokenCounter;
    bool public mintLive;
    
    mapping(uint256 => string) public tokenIdToEgg;
    mapping(uint256 => address) public tokenIdToOwner;

    
    event NewEgg(uint256 indexed tokenId);

    constructor() ERC721('EggNFT','EGG') {
        tokenCounter = 0;
        mintLive = true;
    }
    function withdraw() public payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function isItEasterYet(bool pause) external onlyOwner {
        if (pause == true) {
            mintLive = false;
        } else if (pause == false) {
            mintLive = true;
        }
    }

    function mintEgg() external payable {
        // require(bytes(word).length <= 19, 'max characters is 19');
        require(mintLive == true, 'minting is not live right now');
        require(msg.value >= 21400000000000000 wei, 'minting costs 0.0214 eth!');
        uint256 tokenId = tokenCounter;
        uint256 baseR = uint256(keccak256(abi.encodePacked(tokenId,msg.sender)));
        tokenCounter = tokenCounter + 1;
        tokenIdToOwner[tokenId] = msg.sender;
        _safeMint(msg.sender, tokenId);
        makeEgg(tokenId, baseR);
        payable(owner()).transfer(msg.value);
        emit NewEgg(tokenId);
    }

    function makeEgg(uint256 _tokenId, uint256 _baseR) private {
        string memory imageURI = svgComponents.eggGen(_tokenId, getColors(_baseR), getChoices(_baseR));
        string memory eggURI = string(abi.encodePacked('data:image/svg+xml;base64,',Base64.encode(bytes(abi.encodePacked(imageURI)))));
        tokenIdToEgg[_tokenId] = eggURI;
        _setTokenURI(_tokenId, eggURI);
    }

        //colors and variables
    function getColors(uint256 _baseR) private pure returns (string[5] memory colorArray) {
        string[20] memory pColors = ['#E0BBE4','#957DAD','#D291BC','#FEC8D8','#FFDFD3','#FF9AA2','#FFB7B2','#FFDAC1','#E2F0CB','#B5EAD7','#C7CEEA','#FFA6BE','#A9E0E7','#EEC5AC','#E9D6BA','#EAE2D3','#8AC7E1','#80ADE1','#DBC3E6','#FDA8C0'];
        uint256 tempNum = uint256(keccak256(abi.encodePacked(_baseR)));
        for (uint i = 0; i < 5; i++) {
            colorArray[i] = pColors[tempNum % 20];
            tempNum = uint256(keccak256(abi.encodePacked(tempNum)));
        }
    }
    function getChoices(uint256 _baseR) private pure returns (uint8[5] memory choices) {
        //need to get choices for:
        // patternchoice, choices[1], choices[2], choices[3], goldenegg
        uint8 gg;
        if (_baseR % 1000000 == 1) {
            gg = 1;
        } else {
            gg = 0;
        }
        choices = [uint8(_baseR % 14), uint8(_baseR % 6), uint8(_baseR % 5), uint8(_baseR % 7), gg];
    }

}


library svgComponents {
    //helper
    function addString(string memory s, string memory n1, string memory n2, string memory n3) private pure returns (string memory str) { 
        str = string(abi.encodePacked(s,n1,n2,n3));
    }
    function eggGen(uint256 _tokenId, string[5] memory colors, uint8[5] memory choices) external pure returns (string memory eggURI) {
        string memory pat;
        if (choices[0] !=3 && choices[0] !=4 && choices[0] <= 6) {
            pat = '<pattern id="';
        }
        (string memory defs, bytes32 atts) = getDefs(choices,[colors[0],colors[1]]);
        string memory finalSVG = addString('',string('<svg xmlns="http://www.w3.org/2000/svg" xmlns="http://www.w3.org/1999/xlink" version="1.1" height="500px" width="500px"><defs>'),pat,defs);
        delete pat;
        (string memory use, bytes32[3] memory ats) = getUse(colors,choices);
        finalSVG = addString(finalSVG,getGrad([colors[2],colors[3]]),string('<mask id="mask"><rect width="100%" height="100%" fill="white"/><path d="M 105 300 C 100 500, 400 500, 395 300C 380 -40, 120 -40, 105 300"fill="black"/></mask></defs><rect width="100%" height="100%" fill="url(#gd)"/>'),use);
        (string memory gEgg, bytes32 atss) = goldenEgg(choices[4]);
        bytes32[5] memory atrs = [atts,ats[0],ats[1],ats[2],atss];
        finalSVG = addString(finalSVG,gEgg,string(abi.encodePacked('<rect mask="url(#mask)" height="100%" width="100%" fill="',colors[4],'"/></svg>')),string(''));
        string memory cols = string(abi.encodePacked(string(colors[2]),string(colors[3])));
        eggURI = getJson(finalSVG, _tokenId, cols, atrs);
        delete atrs;
    }

    function getDefs(uint8[5] memory choices, string[2] memory cols) private pure returns (string memory defs, bytes32 atts) {
        bool noFore;
        if (choices[0] == 0) { 
            defs = string(abi.encodePacked(defs,p1(cols[0])));
            atts = "Triangle";
        } else if (choices[0] == 1) {
            defs = string(abi.encodePacked(defs,p2(cols[0])));
            atts = "Tiger";
        } else if (choices[0] == 2) {
            defs = string(abi.encodePacked(defs,p3(cols[0])));
            atts = "Swirly";
        } else if (choices[0] == 3) {
            defs = string(abi.encodePacked(defs,p4(cols)));
            atts = "Rainbow";
        } else if (choices[0] == 4) {
            defs = string(abi.encodePacked(defs,string('<g id="wav"><path d="M100 332c10 30,20 30,40 0s20 60,40 40s20 -65,40 -5s20 -75,50 -5s20 -75,55 -8s20 -90,60 -5s20 -200,20 0"/></g>')));
            atts = "Wavy";
            noFore = true;
        } else if (choices[0] == 5) {
            defs = string(abi.encodePacked(defs,p6(cols)));
            atts = "Cube";
            noFore = true;
        } else if (choices[0] == 6) {
            defs = string(abi.encodePacked(defs,p7(cols[0])));
            atts = "This Is Egg";
            noFore = true;
        } else if (choices[0] > 6) {
            atts = "None";
        }
        string[5] memory funcdMap;
        funcdMap[0] = string('<g id="d1"stroke-width="15"fill="none"><path d="M 80 350a340 350 0 0 0 340 0"/></g>');
        funcdMap[1] = string('<g id="d2"stroke-width="8"fill="none"><path d="M100 250c60 40,80 40,140 0s100 20, 120 20s90 -40, 100 -40"/></g>');
        funcdMap[2] = string('<g id="d3"><path d="M 100 150a250 450 0 0 0 250 0"/></g>');
        funcdMap[3] = string('<g id="wav"><path d="M100 332c10 30,20 30,40 0s20 60,40 40s20 -65,40 -5s20 -75,50 -5s20 -75,55 -8s20 -90,60 -5s20 -200,20 0"/></g>');
        funcdMap[4] = string('<g id="d5"stroke="none"><polygon points="250 200,285 310,190 245,310 245,215 310"/></g>');
        if (noFore == false) {
            if (choices[1] > 4) {
                choices[1] = choices[2];
            } 
            if (choices[3] > 4) {
                choices[3] = choices[2];
            }
            if (choices[1] == choices[2] && choices[1] == choices[3]) {
                defs = string(abi.encodePacked(defs, funcdMap[choices[1]]));
            } else if (choices[1] == choices[2] && choices[1] != choices[3]) {
                defs = addString(defs, funcdMap[choices[1]],funcdMap[choices[3]],string(''));
            } else if (choices[1] != choices[2] && choices[1] == choices[3]) {
                defs = addString(defs, funcdMap[choices[2]],funcdMap[choices[3]],string(''));
            } else if (choices[2] == choices[3] && choices[1] != choices[2]) {
                defs = addString(defs, funcdMap[choices[1]],funcdMap[choices[2]],string(''));
            } else if (choices[1] != choices[2] && choices[1] != choices[3] && choices[2] != choices[3]) {
                defs = addString(defs, funcdMap[choices[1]],funcdMap[choices[2]],funcdMap[choices[3]]);
            }
        }
    }

    function getUse(string[5] memory colors, uint8[5] memory choices) internal pure returns (string memory use, bytes32[3] memory ats) {
        bool noFore;
        string memory pU = string('<rect x="0"y="0"width="100%"height="100%"');
        if (choices[0] == 1) {
            pU = string(abi.encodePacked(pU,'transform="rotate(10)"fill="url(#p)"></rect>'));
            use = string(abi.encodePacked(use,pU));
        } else if (choices[0] == 3) {
            if (choices[3] < 5) {
                use = string('<use href="#d2"transform-origin="center"transform="translate(-100,30)rotate(-70)"/>');
            } else {
                use = string('<use href="#d2"transform-origin="center"transform="scale(1.4)translate(0,-90)"/>');
            }
        } else if (choices[0] == 4) {
            string[10] memory wavs = ['40','42','44','46','48','50','52','54','56','58'];
            for (uint i = 0; i<10; i++) {
                use = addString(use,'<use x="-100"y="-',string(abi.encodePacked(wavs[i],'0px"stroke="',colors[i%5])),'"stroke-width="5"fill="none"transform="scale(1.8)rotate(85)"href="#wav"/>');
            }
            noFore = true;
        } else if (choices[0] == 5 || choices[0] == 6) {
            noFore = true;
            use= string(abi.encodePacked(pU,'fill="url(#p)"></rect>'));
        } else if (choices[0] < 6) {
            use= string(abi.encodePacked(pU,'fill="url(#p)"></rect>'));
        }
        if (noFore == false) {
            string memory u1;
            string memory u2;
            string memory u3;
            (u1, ats[0]) = db([colors[1],colors[2]],choices[1]);
            (u2, ats[1]) = dm([colors[2],colors[3]],choices[2]);
            (u3, ats[2]) = dt([colors[3],colors[4]],choices[3]);
            use = addString(use,u1,u2,u3);
        }
    }

    //choicemaker
    function db(string[2] memory c, uint8 dbc) private pure returns (string memory use, bytes32 att) {
        if (dbc == 0) {
            use = string(abi.encodePacked('<use href="#d1"y="-30"stroke="',c[0],'"/><use href="#d1"y="20"stroke="',c[1],'"/>'));
            att = 'Line';
        } else if (dbc == 1) {
            use = string(abi.encodePacked(use,'<use href="#d2"x="30"y="100"stroke="',c[0],'"transform="scale(1.3)"transform-origin="center"/>'));
            use = string(abi.encodePacked(use,'<use href="#d2"x="30"y="100"stroke="',c[1],'"transform="scale(-1.3,1.3)"transform-origin="center"/>'));
            att = 'Wave';
        } else if (dbc == 2) {
            use = string(abi.encodePacked('<use href="#d3"x="-470" y="-600" fill="',c[0],'"transform="rotate(180)"/>'));
            att = 'Circle';
        } else if (dbc == 3) {
            use = string(abi.encodePacked('<use href="#wav"x="-50"y="-40"stroke="',c[0],'"stroke-width="10"fill="none"transform="scale(1.2)"/>'));
            att = 'Squiggle';
        } else if (dbc == 4) {
            use = string(abi.encodePacked('<use href="#d5"x="-80"y="110"fill="',c[0],'"transform="scale(1.2)rotate(-8)','skewX(-10)"transform-origin="center"/>'));
            use = string(abi.encodePacked(use,'<use href="#d5"x="80"y="110"fill="',c[1],'"transform="scale(1.2)rotate(8)skewX(10)"transform-origin="center"/>'));
            att = 'Star';
        } else if (dbc > 4) {
            att = 'None';
        }
    }

    function dm(string[2] memory c, uint8 dmc) private pure returns (string memory use, bytes32 att) {
        if (dmc == 0) {
            use = string(abi.encodePacked('<use href="#d1"y="-100"stroke="',c[0],'"transform="scale(.9,.7)"transform-origin="center"/>'));
            use = string(abi.encodePacked(use,'<use href="#d1"y="-160"stroke="',c[1],'"transform="scale(.9,.7)"transform-origin="center"/>'));
            att = 'Line';
        } else if (dmc == 1) {
            use = string(abi.encodePacked('<use href="#d2"x="30"y="-30"stroke="',c[0],'"transform="scale(1.3)"transform-origin="center"/>'));
            use = string(abi.encodePacked(use,'<use href="#d2"x="30"y="30"stroke="',c[1],'"transform="scale(-1.3,1.3)"transform-origin="center"/>'));
            att = 'Wave';
        } else if (dmc == 2) {
            use = string(abi.encodePacked('<use x="80"y="-100"fill="',c[0],'"transform="scale(0.8)"href="#d3"/>'));
            att = 'Circle';
        } else if (dmc == 3) {
            use = string(abi.encodePacked('<use href="#wav"x="-45"y="-150"stroke="',c[0],'"stroke-width="20"fill="none"transform="scale(1.2)"/>'));
            att = 'Squiggle';
        } else if (dmc == 4) {
            use = string(abi.encodePacked('<use href="#d5"x="-135"y="-8"fill="',c[0],'"transform="rotate(12)skewX(-10)"transform-origin="center"/>'));
            use = string(abi.encodePacked(use,'<use href="#d5"y="-20"fill="',c[1],'"transform="scale(1,1.1)"transform-origin="center"/>'));
            use = string(abi.encodePacked(use,'<use href="#d5"x="135"y="-8"fill="',c[0],'"transform="rotate(-12)skewX(10)"transform-origin="center"/>'));
            att = 'Star';
        }
    }

    function dt(string[2] memory c, uint8 dtc) private pure returns (string memory use, bytes32 att) {
        if (dtc == 0) {
            use = string(abi.encodePacked('<use href="#d1"y="-300"stroke="',c[0],'"transform="scale(.9,.7)"transform-origin="center"/>'));
            use = string(abi.encodePacked(use,'<use href="#d1"y="-360"stroke="',c[1],'"transform="scale(.9,.7)"transform-origin="center"/>'));
            att = 'Line';
        } else if (dtc == 1) {
            use = string(abi.encodePacked('<use href="#d2"x="30"y="-100"stroke="',c[0],'"transform="scale(1.5)"transform-origin="center"/>'));
            use = string(abi.encodePacked(use,'<use href="#d2"x="30"y="-100"stroke="',c[1],'"transform="scale(-1.5,1.5)"transform-origin="center"/>'));
            att = 'Wave';
        } else if (dtc == 2) {
            use = string(abi.encodePacked('<use x="-510"y="-50"fill="',c[0],'"transform="rotate(-90)"href="#d3"/>'));
            use = string(abi.encodePacked(use,'<use x="50"y="-550"fill="',c[1],'"transform="rotate(90)"href="#d3"/>'));
            att = 'Circle';
        } else if (dtc == 3) {
            use = string(abi.encodePacked('<use href="#wav"x="-45"y="-150"stroke="',c[0],'"stroke-width="20"fill="none"transform="scale(1.2)"/>'));
            att = 'Squiggle';
        } else if (dtc == 4) {
            use = string(abi.encodePacked('<use href="#d5"y="-265"fill="',c[0],'"transform="scale(1.4,.8)"transform-origin="center"/>'));
            att = 'Star';
        } else if (dtc > 4) {
            att = 'None';
        }
    }

    function p1(string memory c) private pure returns (string memory p) {
        p = string(abi.encodePacked('p"x="0"y="0"patternUnits="userSpaceOnUse"width="80"height="40"','viewBox="0 0 80 40"><path stroke-width="5"fill="none"stroke="',c,'"d="M0 0l40 40l40 -40"></path></pattern>'));
    }

    function p2(string memory c) private pure returns (string memory p) {
        p = string(abi.encodePacked('p"x="0"y="0"patternUnits="userSpaceOnUse"width="500"height="40"','viewBox="0 0 500 40"><path stroke-width="5"fill="none"stroke="',c,'"d="M0 0a500 350 0 0 0 500 0"/></pattern>'));
    }

    function p3(string memory c) private pure returns (string memory p) { 
        p = string(abi.encodePacked('p" x="0"y="0"patternUnits="userSpaceOnUse"width="500"height="80"','viewBox="0 0 500 40"><path stroke-width="15"fill="none"stroke="',c,'"d="M0 0a500 350 0 0 0 500 0"/></pattern>'));
    }

    function p4(string[2] memory c) private pure returns (string memory p) {
        p = string(abi.encodePacked('<g id="d2"stroke-width="60"fill="none"><path d="M 100 200a500 300 0 0 0 600 0"stroke="',c[0]));
        string[5] memory locs = ['260','320','380','440','500'];
        for (uint i = 0; i < 5; i++) {
            p = string(abi.encodePacked(p,'"/><path d="M100 ',locs[i],'a500 300 0 0 0 600 0"stroke="',c[i+1]));
        }
        p = string(abi.encodePacked(p,'"/></g>'));
    }

    function p6(string[2] memory c) private pure returns (string memory p) {
        p = string(abi.encodePacked('p"x="0"y="126"patternUnits="userSpaceOnUse"width="126"height="200"','viewBox="0 0 10 16"> <g id="cube"><path fill="',c[0]));
        p = string(abi.encodePacked(p,'"d="M0 0l5 3v5l-5 -3z"></path><path fill="',c[1],'"d="M10 0l-5 3v5l5 -3"></path></g><use x="5"y="8"xlink:href="#cube"></use><use x="-5"y="8"xlink:href="#cube"></use></pattern>'));
    }

    function p7(string memory c) private pure returns (string memory p) {
        p = string(abi.encodePacked('p"x="0"y="0"patternUnits="userSpaceOnUse"width="100"height="72"viewBox="0 0 320 100"fill="',c,'"><text font-size="72px"font-weight="900"x="0"y="0">this is egg</text><text font-size="72px"font-weight="900"x="0"y="76">this is egg</text><text font-size="72px" font-weight="900"x="0"y="152">this is egg</text>'));
        p = string(abi.encodePacked(p,'<text font-size="72px"font-weight="900"x="0"y="152">this is egg</text></pattern>'));
    }

    //gradient

    function getGrad(string[2] memory c) private pure returns (string memory grad) { 
        grad = string(abi.encodePacked('<radialGradient id="gd"cx="0.54"cy="0.75"fx="0.60"fy="0.80"spreadMethod="pad"><stop offset="0%"stop-color="',c[0],'"/><stop offset="100%"stop-color="',c[1],'"/></radialGradient>'));
    }

    function goldenEgg(uint8 choice) private pure returns (string memory gEgg, bytes32 ats) {
        if (choice == 1) {
            gEgg = string(abi.encodePacked('<text class="base" letter-spacing="10"><path id="cr" fill="none" stroke="none" d="M 140 250 a 280 130 0 0 0 280 -10"/><textPath xlink:href="#cr">golden egg</textPath></text>'));
            ats = 'Yes';
        } else {
            ats = 'No';
        }
    }

    function getJson(string memory _eggURI, uint256 _tokenId, string memory cols, bytes32[5] memory _atts) private pure returns (string memory) { 
        string memory baseURL = 'data:application/json;base64,';
        string memory name = string(abi.encodePacked('{"name": "egg #',uint2str(_tokenId),'",'));
        string memory tokenURI = string(abi.encodePacked(
                            name,
                            '"description": "Make eggs, dont break them. Get your own egg, hide it for a loved one, throw one at a friend. Images are randomly generated then built in SVG and will be stored forever on-chain.",',
                            '"attributes":[{"Colors":"',cols,'", "Pattern":"',_atts[0],'","Bottom Design":"',_atts[1],'","Middle Design":"',_atts[2],'","Top Design":"',_atts[3],'","Golden Egg":"',_atts[4],'"}],',
                            '"image_data":"',_eggURI,'"}'
                        ));
        return string(
            abi.encodePacked(
                baseURL,
                Base64.encode(
                    bytes(tokenURI)
                )
            )
        );
    }
    function uint2str(uint _i) private pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}