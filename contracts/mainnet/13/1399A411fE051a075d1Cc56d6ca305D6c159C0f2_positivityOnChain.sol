// SPDX-License-Identifier: MIT
/*
    ____             _ __  _       _ __        ____        ________          _     
   / __ \____  _____(_) /_(_)   __(_) /___  __/ __ \____  / ____/ /_  ____ _(_)___ 
  / /_/ / __ \/ ___/ / __/ / | / / / __/ / / / / / / __ \/ /   / __ \/ __ `/ / __ \
 / ____/ /_/ (__  ) / /_/ /| |/ / / /_/ /_/ / /_/ / / / / /___/ / / / /_/ / / / / /
/_/    \____/____/_/\__/_/ |___/_/\__/\__, /\____/_/ /_/\____/_/ /_/\__,_/_/_/ /_/ 
                                     /____/                                        
*/

pragma solidity ^0.8.16;
 
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {Base64} from "./libraries/Base64.sol";
 
contract positivityOnChain is ERC721URIStorage, Ownable {
  uint256 private numClaimed = 0;
  
  struct Metadata {
    uint256 orig_score;
    uint256 orig_pos_neg;
    uint256 score;
    uint256 pos_neg;
    string username;
    address minter;
    string gradient;
    bool animated;
    string status;
    Color color;
    string attributesURI;
    string baseURI;
    string SVG;
  }

  struct Color {
    uint256 r1;
    uint256 g1;
    uint256 b1;
    uint256 r2;
    uint256 g2;
    uint256 b2;
  }

  struct Coupon {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  mapping(uint256 => Metadata) idToData;
  mapping(string => uint256) userToId;
  mapping(string => bool) alreadyMinted;
  mapping(uint256 => string) updatedURI;
  mapping(uint256 => bool) removed;
  
  string baseSvg1 = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 500"><defs><linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="0%"><stop offset="0%" style="stop-color:rgb(';
  string baseSvg2 = ');stop-opacity:1" /><stop offset="100%" style="stop-color:rgb(';
  string baseSvg3 = ');stop-opacity:1" />';
  string animate_Svg4 = '<animate attributeName="x2" values="100%;0%;100%" dur="10s" repeatCount="indefinite" />';
  string baseSvg5 = '</linearGradient></defs><rect width="100%" height="100%" fill="rgb(232,228,214)" rx="25"/><ellipse cx="175" cy="175" rx="150" ry="150" fill="white"/><ellipse cx="175" cy="175" rx="150" ry="150" fill="url(#grad1)" /><text fill="#ffffff" font-size="55" font-family="Trebuchet MS" x="50%" y="175" dominant-baseline="middle" text-anchor="middle">';

  string baseSvg1_2 = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 500"><defs><radialGradient id="grad1" cx="50%" cy="50%" r="50%" fx="50%" fy="50%"><stop offset="0%" style="stop-color:rgb(';
  string baseSvg2_2 = ');stop-opacity:0" /><stop offset="100%" style="stop-color:rgb(';
  string animate_Svg4_2 = '<animate attributeName="r" values="0%;100%;0%" dur="10s" repeatCount="indefinite" />';
  string baseSvg5_2 = '</radialGradient></defs><rect width="100%" height="100%" fill="rgb(232,228,214)" rx="25"/><ellipse cx="175" cy="175" rx="150" ry="150" fill="white"/><ellipse cx="175" cy="175" rx="150" ry="150" fill="url(#grad1)" /><text font-size="55" font-family="Trebuchet MS" x="50%" y="175" dominant-baseline="middle" text-anchor="middle">';
  
  string postScoreSvg = '</text><text font-size="45" font-family="Trebuchet MS" x="50%" y="80%" dominant-baseline="middle" text-anchor="middle">';

  string lockedSvg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 350 500"><rect width="100%" height="100%" fill="rgb(232,228,214)" rx="25" /><path transform="translate(130, 110)" d="M2.892,56.036h8.959v-1.075V37.117c0-10.205,4.177-19.484,10.898-26.207v-0.009 C29.473,4.177,38.754,0,48.966,0C59.17,0,68.449,4.177,75.173,10.901l0.01,0.009c6.721,6.723,10.898,16.002,10.898,26.207v17.844 v1.075h7.136c1.59,0,2.892,1.302,2.892,2.891v61.062c0,1.589-1.302,2.891-2.892,2.891H2.892c-1.59,0-2.892-1.302-2.892-2.891 V58.927C0,57.338,1.302,56.036,2.892,56.036L2.892,56.036z M26.271,56.036h45.387v-1.075V36.911c0-6.24-2.554-11.917-6.662-16.03 l-0.005,0.004c-4.111-4.114-9.787-6.669-16.025-6.669c-6.241,0-11.917,2.554-16.033,6.665c-4.109,4.113-6.662,9.79-6.662,16.03 v18.051V56.036L26.271,56.036z M49.149,89.448l4.581,21.139l-12.557,0.053l3.685-21.423c-3.431-1.1-5.918-4.315-5.918-8.111 c0-4.701,3.81-8.511,8.513-8.511c4.698,0,8.511,3.81,8.511,8.511C55.964,85.226,53.036,88.663,49.149,89.448L49.149,89.448z"/><text font-size="45" font-family="Trebuchet MS" x="50%" y="80%" dominant-baseline="middle" text-anchor="middle">Token Locked</text></svg>';
  
  address private adminSigner; 

  uint256 private mintPrice = 0.02 ether;
  uint256 private updatePrice = 0.01 ether;

  constructor(address _adminSigner) ERC721 ("PositivityOnChain", "POC") {
    adminSigner = _adminSigner;
  }

  function updateAdminSigner(address _new) public onlyOwner {
    adminSigner = _new;
  }

  function updateSVG(string memory _baseSvg1, string memory _baseSvg2, string memory _baseSvg3, string memory _animate_Svg4, string memory _baseSvg5, string memory _baseSvg1_2, string memory _baseSvg2_2, string memory _animate_Svg4_2, string memory _baseSvg5_2, string memory _postScoreSvg, string memory _lockedSvg) public onlyOwner {
    baseSvg1 = _baseSvg1;
    baseSvg2 = _baseSvg2;
    baseSvg3 = _baseSvg3;
    animate_Svg4 = _animate_Svg4;
    baseSvg5 = _baseSvg5;
    baseSvg1_2 = _baseSvg1_2;
    baseSvg2_2 = _baseSvg2_2;
    animate_Svg4_2 = _animate_Svg4_2;
    baseSvg5_2 = _baseSvg5_2;
    postScoreSvg = _postScoreSvg;
    lockedSvg = _lockedSvg;
  }

  function setColors(uint256 id) internal view returns (Color memory color) {
    uint256 pos_neg = idToData[id].pos_neg;
    uint256 score = idToData[id].score;
    if (pos_neg != 1) {
      if (score >= 500) {
        color.r1 = randRange(205,255,score,id);
        color.g1 = randRange(200,215,score,id);
        color.b1 = randRange(0,30,score,id);
        color.r2 = randRange(188,200,score,id);
        color.g2 = randRange(187,200,score,id);
        color.b2 = randRange(186,200,score,id);
      } else if (score > 200 && score < 500) {
          color.r1 = randRange(150,255,score,id);
          color.g1 = randRange(151,255,score,id);
          color.b1 = randRange(152,255,score,id);
          color.r2 = randRange(149,255,score,id);
          color.g2 = randRange(148,255,score,id);
          color.b2 = randRange(153,255,score,id);
      } else {
          color.r1 = randRange(51,150,score,id);
          color.g1 = randRange(49,149,score,id);
          color.b1 = randRange(52,148,score,id);
          color.r2 = randRange(53,147,score,id);
          color.g2 = randRange(48,146,score,id);
          color.b2 = randRange(57,145,score,id);
      }
    } else {
        if (score >= 200) { 
          color.r1 = randRange(0,5,score,id);
          color.g1 = randRange(1,6,score,id);
          color.b1 = randRange(0,9,score,id);
          color.r2 = randRange(125,150,score,id);
          color.g2 = randRange(0,5,score,id);
          color.b2 = randRange(0,9,score,id);
        } else if (score < 200 && score > 75) {
            color.r1 = randRange(0,50,score,id);
            color.g1 = randRange(1,49,score,id);
            color.b1 = randRange(2,48,score,id);
            color.r2 = randRange(3,47,score,id);
            color.g2 = randRange(4,46,score,id);
            color.b2 = randRange(5,45,score,id);
        } else {
            color.r1 = randRange(50,100,score,id);
            color.g1 = randRange(51,100,score,id);
            color.b1 = randRange(52,100,score,id);
            color.r2 = randRange(53,100,score,id);
            color.g2 = randRange(54,100,score,id);
            color.b2 = randRange(55,100,score,id);
        }
    }
  }
  
  function randRange(uint256 lowerBound, uint256 upperBound, uint256 score, uint256 id) internal view returns (uint256) {
    uint256 randomNumber = uint(keccak256(abi.encodePacked(this, id, score))) % (upperBound - lowerBound + 1);
    return randomNumber += lowerBound;
  }

  function updatePrices(uint256 _mintPrice, uint256 _updatePrice) public onlyOwner {
    mintPrice = _mintPrice;
    updatePrice = _updatePrice;
  }

  function purchase(uint256 score, uint256 pos_neg, string memory username, Coupon memory coupon) public payable {
    //pos_neg: 0 for positive, 1 for negative
    require(!alreadyMinted[username], "Already minted");
    require(msg.value >= mintPrice, "Not enough eth");

    bytes32 digest = keccak256(abi.encode(msg.sender,score,username,pos_neg));
    require(_isVerifiedCoupon(digest, coupon), "Invalid coupon");
    
    mintToken(msg.sender, score, pos_neg, username, msg.sender);
  }
  
  function mintToken(address _to, uint256 score, uint256 pos_neg, string memory username, address _minter) internal {
    uint256 tokenID = numClaimed + 1;
    idToData[tokenID].score = score;
    idToData[tokenID].orig_score = score;
    idToData[tokenID].orig_pos_neg = pos_neg;
    idToData[tokenID].pos_neg = pos_neg;
    idToData[tokenID].username = username;
    idToData[tokenID].minter = _minter;
    userToId[username] = tokenID;
    alreadyMinted[username] = true;
    _safeMint(_to, tokenID);
    numClaimed += 1;
  }

  function _isVerifiedCoupon(bytes32 digest, Coupon memory coupon) internal view returns (bool) {
    address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
    require(signer != address(0), "Invalid sig");
    return signer == adminSigner;
  }
  
  function airdrop(address _to, uint256 score, uint256 pos_neg, string memory username) public onlyOwner {
    require(!alreadyMinted[username], "Already minted");
    mintToken(_to, score, pos_neg, username, _to);
  }
  
  function updateToken(uint256 id, uint256 score, uint256 pos_neg, string memory username, Coupon memory coupon) public payable {
    require(msg.value >= updatePrice, "Not enough eth");
    require(ownerOf(id) == msg.sender, "You must currently own this token");
    require(idToData[id].minter == msg.sender, "Must use original minter address");

    bytes32 digest = keccak256(abi.encode(msg.sender,score,username,pos_neg));
    require(_isVerifiedCoupon(digest, coupon), "Invalid coupon");

    if (keccak256(abi.encodePacked((idToData[id].username))) != keccak256(abi.encodePacked((username)))) {
      userToId[idToData[id].username] = 0;
      alreadyMinted[idToData[id].username] = false;
      userToId[username] = id;
      idToData[id].username = username;
      alreadyMinted[username] = true;
    }

    idToData[id].score = score;
    idToData[id].pos_neg = pos_neg;
  }

  function toggleRemove(uint256 id) public onlyOwner {
    removed[id] = !removed[id];
  }

  function adminUpdate(uint256 id, uint256 score, uint256 pos_neg, string memory username, address _minter, uint256 orig_score, uint256 orig_pos_neg) public onlyOwner {
    idToData[id].score = score;
    idToData[id].orig_score = orig_score;
    idToData[id].orig_pos_neg = orig_pos_neg;
    idToData[id].pos_neg = pos_neg;
    idToData[id].minter = _minter;

    if (keccak256(abi.encodePacked((idToData[id].username))) != keccak256(abi.encodePacked((username)))) {
      userToId[idToData[id].username] = 0;
      alreadyMinted[idToData[id].username] = false;
      userToId[username] = id;
      idToData[id].username = username;
      alreadyMinted[username] = true;
    }
  }
  
  function removeUsername(string memory username) public onlyOwner {
    alreadyMinted[username] = false;
    userToId[username] = 0;
  }

  function checkUsername(string memory username) public view returns (bool) {
    return alreadyMinted[username];
  }

  function usernameToScore(string memory username) public view returns (string memory readable_score, uint256 score, uint256 pos_neg, uint256 tokenID) {
    require(userToId[username] > 0, "Username does not have a score");
    score = idToData[userToId[username]].score;
    pos_neg = idToData[userToId[username]].pos_neg;
    tokenID = userToId[username];
    if (pos_neg == 1) {
      readable_score = string.concat('-',Strings.toString(idToData[userToId[username]].score));
    } else {
      readable_score = Strings.toString(idToData[userToId[username]].score);
    }
  }

  function viewMetadata(uint256 id) public view returns (string memory username, string memory score, string memory original_score, address minter, string memory gradient, bool animated, string memory status, Color memory color) {
    require(id < numClaimed + 1 && id != 0, "Token does not exist");
    if (!removed[id]) {
      Metadata memory attributes = getAttributes(id);
      score = Strings.toString(idToData[id].score);
      original_score = Strings.toString(idToData[id].orig_score);
      if (idToData[id].pos_neg == 1) {
        score = string.concat('-',score);
      }
      if (idToData[id].orig_pos_neg == 1) {
        original_score = string.concat('-',original_score);
      }
      username = idToData[id].username;
      minter = idToData[id].minter;
      gradient = attributes.gradient;
      animated = attributes.animated;
      status = attributes.status;
      color = attributes.color;
    } else {
      username = "Token Locked";
    }
  }

  function viewSVG(uint256 id) public view returns (string memory) {
    require(id < numClaimed + 1 && id != 0, "Token does not exist");
    if (!removed[id]) {
      return getAttributes(id).SVG;
    } else {
      return "Token Locked";
    }
  }

  function getAttributes(uint256 id) internal view returns (Metadata memory attributes) {
    uint256 score = idToData[id].score;
    uint256 pos_neg = idToData[id].pos_neg;
    string memory sign = 'positive';
    attributes.gradient = 'linear';
    attributes.status = 'Neutral';
    string memory animate = 'false';
    string memory orig_str_score = Strings.toString(idToData[id].orig_score);
    if (idToData[id].orig_pos_neg == 1) {
      orig_str_score = string.concat('-',orig_str_score);
    }

    string memory str_score = Strings.toString(idToData[id].score);

    if (pos_neg == 0) {
      if (score > 25 && score <= 75) {
        attributes.status = 'Friendly';
      } else if (score > 75 && score <= 115) {
          attributes.status = 'Supportive';
      } else if (score > 115 && score <= 175) {
          attributes.status = 'Kindhearted';
      } else if (score > 175 && score <= 300) {
          attributes.status = 'Compassionate';
      } else if (score > 300 && score <= 500) {
          attributes.status = 'Altruistic';
      } else if (score > 500) {
          attributes.status = 'Loving';
      }
    } else {
      str_score = string.concat('-',str_score);
      sign = 'negative';
      if (score > 25 && score <= 75) {
        attributes.status = 'Stingy';
      } else if (score > 75 && score <= 115) {
          attributes.status = 'Heinous';
      } else if (score > 115 && score <= 175) {
          attributes.status = 'Spiteful';
      } else if (score > 175 && score <= 300) {
          attributes.status = 'Offensive';
      } else if (score > 300 && score <= 500) {
          attributes.status = 'Resentful';
      } else if (score > 500) {
          attributes.status = 'Evil';
      }
    }

    attributes.color = setColors(id);
    
    string memory color1 = string.concat(Strings.toString(attributes.color.r1),',',Strings.toString(attributes.color.g1),',',Strings.toString(attributes.color.b1));
    string memory color2 = string.concat(Strings.toString(attributes.color.r2),',',Strings.toString(attributes.color.g2),',',Strings.toString(attributes.color.b2));
  
    attributes.baseURI = string.concat(baseSvg1, color1, baseSvg2, color2, baseSvg3, baseSvg5);
  
    if (randRange(0,100,score,id) > 85) {
      attributes.baseURI = string.concat(baseSvg1_2, color1, baseSvg2_2, color2, baseSvg3, baseSvg5_2);
      attributes.gradient = 'radial';
      if (randRange(1,101,score,id) > 99) {
        attributes.baseURI = string.concat(baseSvg1_2, color1, baseSvg2_2, color2, baseSvg3, animate_Svg4_2, baseSvg5_2);
        attributes.animated = true;
        animate = 'true';
      }
    } else {
        if (randRange(2,100,score,id) > 97) {
          attributes.baseURI = string.concat(baseSvg1, color1, baseSvg2, color2, baseSvg3, animate_Svg4, baseSvg5);
          attributes.animated = true;
          animate = 'true';
        }
    }

    attributes.SVG = string(abi.encodePacked(attributes.baseURI, str_score, postScoreSvg, attributes.status, "</text></svg>"));

    attributes.attributesURI = string.concat(',"attributes":[{"trait_type":"gradient","value":"',attributes.gradient,'"},{"trait_type":"r1","value":"',Strings.toString(attributes.color.r1),'"},{"trait_type":"g1","value":"',
    Strings.toString(attributes.color.g1),'"},{"trait_type":"b1","value":"',Strings.toString(attributes.color.b1),'"},{"trait_type":"r2","value":"',Strings.toString(attributes.color.r2),'"},{"trait_type":"g2","value":"',
    Strings.toString(attributes.color.g2),'"},{"trait_type":"b2","value":"',Strings.toString(attributes.color.b2),'"},{"trait_type":"status","value":"',attributes.status,'"},{"trait_type":"animated","value":"',animate,'"},{"trait_type":"sign","value":"',sign,'"},{"trait_type":"score","value":"',str_score,'"},{"trait_type":"original score","value":"',orig_str_score,'"}]');
    return attributes;
  }
  
  function tokenURI(uint256 id) public view override returns (string memory) {
    require(id < numClaimed + 1 && id != 0, "Token does not exist");
    if (!removed[id]) {
      string memory user = idToData[id].username;

      Metadata memory attributes = getAttributes(id);
    
      string memory json = Base64.encode(
          bytes(
              string(
                  abi.encodePacked(
                      '{"name": "@',user,'", "description": "Positivity Score for @',user,'", "image": "data:image/svg+xml;base64,',
                      Base64.encode(bytes(attributes.SVG)),'"',attributes.attributesURI,'}'
                  )
              )
          )
      );
    
      return string(abi.encodePacked("data:application/json;base64,", json));
    }
    else {
      string memory json = Base64.encode(
          bytes(
              string(
                  abi.encodePacked(
                      '{"name": "Token Locked", "description": "Unfortunately, this token has been manually locked. Most likely due to a user maliciously trying to create a false score.", "image": "data:image/svg+xml;base64,',
                      Base64.encode(bytes(lockedSvg)),'"}'
                  )
              )
          )
      );
      return string(abi.encodePacked("data:application/json;base64,", json));
    }
  }

  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function totalSupply() public view returns(uint256) {
    return numClaimed;
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

pragma solidity ^0.8.0;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

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
     * by default, can be overridden in child contracts.
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
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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

        _afterTokenTransfer(address(0), to, tokenId);
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

        _afterTokenTransfer(owner, address(0), tokenId);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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