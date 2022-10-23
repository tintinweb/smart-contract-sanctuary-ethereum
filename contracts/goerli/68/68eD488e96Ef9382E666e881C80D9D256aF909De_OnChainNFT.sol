// SPDX-License-Identifier: MIT


pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Base64.sol";

contract OnChainNFT is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;
  Counters.Counter public weaponCount;
  
  uint256 public cost = 0.0001 ether;
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmountPerTx = 5;

  bool public paused = false;
  bool public revealed = false;

  mapping(uint256 => Attr) private character;
  mapping(uint256 => Weapon) private weapons;

  struct Weapon {
    string name;
    string code;
    string class;
    uint256 incStr;
    uint256 incAgi;
    uint256 incVit;
  }

  struct Attr {
    string name;
    string class;
    uint256 level;
    uint256 strength;
    uint256 agility;
    uint256 vitality; 
  }

  constructor() ERC721("On Chain NFT", "OCN") {
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function compareStrings(string memory _a, string memory _b) private pure returns (bool) {
    if (keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b))) {
      return true;
    } else {
      return false;
    }
  }

  function getBaseModel(string memory _class) public view returns (string memory) {
    bool pirate = compareStrings(_class, "Pirate");
    bool mage = compareStrings(_class, "Mage");
    bool lox = compareStrings(_class, "Lox");
    if (pirate) {
      string memory svg = Base64.encode(
        bytes(string(
          abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:svgjs="http://svgjs.dev/svgjs" viewBox="0 0 800 800">',
            Pirate,
            '</svg>'
          )
        ))
      );
      return string(abi.encodePacked('data:image/svg+xml;base64,', svg));
    } else if (mage) {
      string memory svg = Base64.encode(
        bytes(string(
          abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:svgjs="http://svgjs.dev/svgjs" viewBox="0 0 800 800">',
            Mage,
            '</svg>'
          )
        ))
      );
      return string(abi.encodePacked('data:image/svg+xml;base64,', svg));
    } else if (lox) {
      string memory svg = Base64.encode(
        bytes(string(
          abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:svgjs="http://svgjs.dev/svgjs" viewBox="0 0 800 800">',
            Lox,
            '</svg>'
          )
        ))
      );
      return string(abi.encodePacked('data:image/svg+xml;base64,', svg));
    } else {
      revert("Class does not exist.");
    }
  }

  function createCharacter(uint256 token, string memory _name, string memory _class) private {
    bool pirate = compareStrings(_class, "Pirate");
    bool mage = compareStrings(_class, "Mage");
    bool lox = compareStrings(_class, "Lox");
    if (pirate) {
      character[token] = Attr(_name, _class, 1, 50, 25, 25);
    } else if (mage) {
      character[token] = Attr(_name, _class, 1, 25, 50, 25);
    } else if (lox) {
      character[token] = Attr(_name, _class, 1, 10, 10, 10);
    } else {
      revert("Class does not exist.");
    }
  }

  function mintCharacter(string memory _name, string memory _class) public payable {
    require(!paused, "The contract is paused!");
    require(msg.value >= cost, "Insufficient funds!");

    supply.increment();
    uint256 token = supply.current();
    _safeMint(msg.sender, token);
    createCharacter(token, _name, _class);
  }
  
  function mintForAddress(address _receiver, string memory _name, string memory _class) public onlyOwner {
    supply.increment();
    uint256 token = supply.current();
    _safeMint(_receiver, token);
    createCharacter(token, _name, _class);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 tokenId) override(ERC721) public view returns (string memory) {
    string memory json = Base64.encode(
      bytes(string(
        abi.encodePacked(
          '{"name": "', character[tokenId].name, '",',
          '"image": "', getBaseModel(character[tokenId].class), '",',
          '"attributes": [{"trait_type": "Class", "value": "', character[tokenId].class, '"},',
          '{"display_type": "number", "trait_type": "Level", "value": ', character[tokenId].level.toString(), '},',
          '{"trait_type": "Strength", "value": ', character[tokenId].strength.toString(), '},',
          '{"trait_type": "Agility", "value": ', character[tokenId].agility.toString(), '},',
          '{"trait_type": "Vitality", "value": ', character[tokenId].vitality.toString(), '}',
          ']}'
        )
      ))
    );
    return string(abi.encodePacked('data:application/json;base64,', json));
  }

  /* EDIT STATS */

  function levelUp(uint256 tokenId, uint256 levels) public {
    require(msg.sender == ownerOf(tokenId), "Token owner access only.");
    character[tokenId].level += levels;
  }

  function addStrength(uint256 tokenId, uint256 amount) public {
    require(msg.sender == ownerOf(tokenId), "Token owner access only.");
    character[tokenId].strength += amount;
  }

  function addAgility(uint256 tokenId, uint256 amount) public {
    require(msg.sender == ownerOf(tokenId), "Token owner access only.");
    character[tokenId].agility += amount;
  }

  function addVitality(uint256 tokenId, uint256 amount) public {
    require(msg.sender == ownerOf(tokenId), "Token owner access only.");
    character[tokenId].vitality += amount;
  }


  /* ASSETS */

  function addWeapon(string memory _name, string memory _code, string memory _class, uint256 _str, uint256 _agi, uint256 _vit) public onlyOwner {
    uint256 id = weaponCount.current();
    weapons[id].name = _name;
    weapons[id].code = _code;
    weapons[id].class = _class;
    weapons[id].incStr = _str;
    weapons[id].incAgi = _agi;
    weapons[id].incVit = _vit;
    weaponCount.increment();
  }

  function getWeapon(uint256 _id) public view returns (Weapon memory) {
    require(_id >= 0, "No ID provided");
    return weapons[_id];
  }

  /* OWNER FUNCTIONS */

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }


  /* BASE MODELS */

  string Pirate = '<defs><radialGradient id="ccclaymoji-grad-dark" r="93%" cx="20%" cy="20%"><stop offset="70%" stop-color="hsl(41, 100%, 67%)" stop-opacity="0" /><stop offset="97%" stop-color="#c89924" stop-opacity="1" /></radialGradient><radialGradient id="ccclaymoji-grad-light" r="65%" cx="28%" cy="20%">  <stop offset="0%" stop-color="#fffd88" stop-opacity="0.75" />  <stop offset="100%" stop-color="hsl(41, 100%, 67%)" stop-opacity="0" /></radialGradient><filter id="ccclaymoji-blur" x="-100%" y="-100%" width="400%" height="400%" filterUnits="objectBoundingBox" primitiveUnits="userSpaceOnUse" color-interpolation-filters="sRGB">  <feGaussianBlur stdDeviation="30" x="0%" y="0%" width="100%" height="100%" in="SourceGraphic" edgeMode="none" result="blur" /></filter><filter id="inner-blur" x="-100%" y="-100%" width="400%" height="400%" filterUnits="objectBoundingBox" primitiveUnits="userSpaceOnUse" color-interpolation-filters="sRGB">  <feGaussianBlur stdDeviation="2" x="0%" y="0%" width="100%" height="100%" in="SourceGraphic" edgeMode="none" result="blur" /></filter><filter id="eye-shadow" x="-100%" y="-100%" width="400%" height="400%" filterUnits="objectBoundingBox" primitiveUnits="userSpaceOnUse" color-interpolation-filters="sRGB">  <feDropShadow stdDeviation="10" dx="10" dy="10" flood-color="#000000" flood-opacity="0.2" x="0%" y="0%" width="100%" height="100%" result="dropShadow" /></filter><linearGradient gradientTransform="rotate(-25)" id="eye-light" x1="50%" y1="0%" x2="50%" y2="100%">  <stop offset="20%" stop-color="#555555" stop-opacity="1" />  <stop offset="100%" stop-color="black" stop-opacity="0" /></linearGradient><linearGradient id="mouth-light" x1="50%" y1="0%" x2="50%" y2="100%">  <stop offset="0%" stop-color="#ff9667" stop-opacity="1" />  <stop offset="100%" stop-color="hsl(3, 100%, 51%)" stop-opacity="0" /></linearGradient><filter id="mouth-shadow" x="-100%" y="-100%" width="400%" height="400%" filterUnits="objectBoundingBox" primitiveUnits="userSpaceOnUse" color-interpolation-filters="sRGB">  <feDropShadow stdDeviation="10" dx="10" dy="10" flood-color="#c20000" flood-opacity="0.2" x="0%" y="0%" width="100%" height="100%" result="dropShadow" /></filter></defs><g stroke-linecap="round" transform="rotate(360, 400, 400)"><path d="M595 449.99999728549847C595 569.3074096844203 519.3074123989218 666.0242560456063 400 666.0242560456063C280.6931132075472 666.0242560456063 205 569.3074096844203 205 449.99999728549847C205 330.69311049304565 280.6931132075472 233.97573852539062 400 233.97573852539062C519.3074123989218 233.97573852539062 595 330.69311049304565 595 449.99999728549847Z " fill="#c89924" opacity="0.25" filter="url(#ccclaymoji-blur)" /><path d="M595 399.99999828289845C595 513.2047297406989 513.2047314578006 604.9744228353281 400 604.9744228353281C286.79576726342714 604.9744228353281 205 513.2047297406989 205 399.99999828289845C205 286.7957655463255 286.79576726342714 195.02557373046875 400 195.02557373046875C513.2047314578006 195.02557373046875 595 286.7957655463255 595 399.99999828289845Z " fill="hsl(41, 100%, 67%)" /><path d="M595 399.99999828289845C595 513.2047297406989 513.2047314578006 604.9744228353281 400 604.9744228353281C286.79576726342714 604.9744228353281 205 513.2047297406989 205 399.99999828289845C205 286.7957655463255 286.79576726342714 195.02557373046875 400 195.02557373046875C513.2047314578006 195.02557373046875 595 286.7957655463255 595 399.99999828289845Z " fill="url(#ccclaymoji-grad-dark)" /><path d="M595 399.99999828289845C595 513.2047297406989 513.2047314578006 604.9744228353281 400 604.9744228353281C286.79576726342714 604.9744228353281 205 513.2047297406989 205 399.99999828289845C205 286.7957655463255 286.79576726342714 195.02557373046875 400 195.02557373046875C513.2047314578006 195.02557373046875 595 286.7957655463255 595 399.99999828289845Z " fill="url(#ccclaymoji-grad-light)" /><ellipse rx="49" ry="25" cx="350" cy="375" fill="black" filter="url(#eye-shadow)" /><ellipse rx="49" ry="25" cx="350" cy="375" fill="url(#eye-light)" filter="url(#inner-blur)" /><ellipse rx="23.5" ry="49.5" cx="450" cy="375" fill="black" filter="url(#eye-shadow)" /><ellipse rx="23.5" ry="49.5" cx="450" cy="375" fill="url(#eye-light)" filter="url(#inner-blur)" /><path d="M350 512.5Q400 562.5 450 512.5 " stroke-width="23" stroke="hsl(3, 100%, 51%)" fill="none" filter="url(#mouth-shadow)" transform="rotate(19, 400, 400)" /><path d="M350 512.5Q400 562.5 450 512.5 " stroke-width="7.666666666666667" stroke="url(#mouth-light)" fill="none" filter="url(#inner-blur)" transform="rotate(19, 400, 400)" /></g>';

  string Mage = '<defs><radialGradient id=\"ccclaymoji-grad-dark\" r=\"93%\" cx=\"20%\" cy=\"20%\">\r\n      <stop offset=\"70%\" stop-color=\"hsl(205, 69%, 50%)\" stop-opacity=\"0\"></stop>\r\n      <stop offset=\"97%\" stop-color=\"#0061a5\" stop-opacity=\"1\"></stop>\r\n    </radialGradient><radialGradient id=\"ccclaymoji-grad-light\" r=\"65%\" cx=\"28%\" cy=\"20%\">\r\n    <stop offset=\"0%\" stop-color=\"#6bbeff\" stop-opacity=\"0.75\"></stop>\r\n    <stop offset=\"100%\" stop-color=\"hsl(205, 69%, 50%)\" stop-opacity=\"0\"></stop>\r\n  </radialGradient><filter id=\"ccclaymoji-blur\" x=\"-100%\" y=\"-100%\" width=\"400%\" height=\"400%\" filterUnits=\"objectBoundingBox\" primitiveUnits=\"userSpaceOnUse\" color-interpolation-filters=\"sRGB\">\r\n\t<feGaussianBlur stdDeviation=\"30\" x=\"0%\" y=\"0%\" width=\"100%\" height=\"100%\" in=\"SourceGraphic\" edgeMode=\"none\" result=\"blur\"></feGaussianBlur></filter><filter id=\"inner-blur\" x=\"-100%\" y=\"-100%\" width=\"400%\" height=\"400%\" filterUnits=\"objectBoundingBox\" primitiveUnits=\"userSpaceOnUse\" color-interpolation-filters=\"sRGB\">\r\n\t<feGaussianBlur stdDeviation=\"2\" x=\"0%\" y=\"0%\" width=\"100%\" height=\"100%\" in=\"SourceGraphic\" edgeMode=\"none\" result=\"blur\"></feGaussianBlur></filter><filter id=\"eye-shadow\" x=\"-100%\" y=\"-100%\" width=\"400%\" height=\"400%\" filterUnits=\"objectBoundingBox\" primitiveUnits=\"userSpaceOnUse\" color-interpolation-filters=\"sRGB\">\r\n\t<feDropShadow stdDeviation=\"10\" dx=\"10\" dy=\"10\" flood-color=\"#000000\" flood-opacity=\"0.2\" x=\"0%\" y=\"0%\" width=\"100%\" height=\"100%\" result=\"dropShadow\"></feDropShadow>\r\n</filter><linearGradient id=\"eye-light\" x1=\"50%\" y1=\"0%\" x2=\"50%\" y2=\"100%\">\r\n      <stop offset=\"0%\" stop-color=\"#555555\" stop-opacity=\"1\"></stop>\r\n      <stop offset=\"100%\" stop-color=\"black\" stop-opacity=\"0\"></stop>\r\n    </linearGradient><linearGradient id=\"mouth-light\" x1=\"50%\" y1=\"0%\" x2=\"50%\" y2=\"100%\">\r\n    <stop offset=\"0%\" stop-color=\"#ff9667\" stop-opacity=\"1\"></stop>\r\n    <stop offset=\"100%\" stop-color=\"hsl(3, 100%, 51%)\" stop-opacity=\"0\"></stop>\r\n  </linearGradient><filter id=\"mouth-shadow\" x=\"-100%\" y=\"-100%\" width=\"400%\" height=\"400%\" filterUnits=\"objectBoundingBox\" primitiveUnits=\"userSpaceOnUse\" color-interpolation-filters=\"sRGB\">\r\n\t<feDropShadow stdDeviation=\"10\" dx=\"10\" dy=\"10\" flood-color=\"#c20000\" flood-opacity=\"0.2\" x=\"0%\" y=\"0%\" width=\"100%\" height=\"100%\" result=\"dropShadow\"></feDropShadow>\r\n</filter></defs><g stroke-linecap=\"round\"><path d=\"M650 449.99998478233977C650 602.9582058065985 552.9582210242588 726.9541626799139 400 726.9541626799139C247.04245283018867 726.9541626799139 150 602.9582058065985 150 449.99998478233977C150 297.04243761252843 247.04245283018867 173.04580688476562 400 173.04580688476562C552.9582210242588 173.04580688476562 650 297.04243761252843 650 449.99998478233977Z \" fill=\"#0061a5\" opacity=\"0.25\" filter=\"url(#ccclaymoji-blur)\"></path><path d=\"M650 399.99999613096236C650 561.6737853047515 561.6737891737891 635.7549818859482 400 635.7549818859482C238.3269230769231 635.7549818859482 150 561.6737853047515 150 399.99999613096236C150 238.3269192078854 238.3269230769231 164.24501037597656 400 164.24501037597656C561.6737891737891 164.24501037597656 650 238.3269192078854 650 399.99999613096236Z \" fill=\"hsl(205, 69%, 50%)\"></path><path d=\"M650 399.99999613096236C650 561.6737853047515 561.6737891737891 635.7549818859482 400 635.7549818859482C238.3269230769231 635.7549818859482 150 561.6737853047515 150 399.99999613096236C150 238.3269192078854 238.3269230769231 164.24501037597656 400 164.24501037597656C561.6737891737891 164.24501037597656 650 238.3269192078854 650 399.99999613096236Z \" fill=\"url(#ccclaymoji-grad-dark)\"></path><path d=\"M650 399.99999613096236C650 561.6737853047515 561.6737891737891 635.7549818859482 400 635.7549818859482C238.3269230769231 635.7549818859482 150 561.6737853047515 150 399.99999613096236C150 238.3269192078854 238.3269230769231 164.24501037597656 400 164.24501037597656C561.6737891737891 164.24501037597656 650 238.3269192078854 650 399.99999613096236Z \" fill=\"url(#ccclaymoji-grad-light)\"></path><path d=\"M325 362.5Q375 412.5 375 362.5 \" stroke-width=\"20\" stroke=\"black\" fill=\"none\" filter=\"url(#eye-shadow)\"></path><path d=\"M325 362.5Q375 412.5 375 362.5 \" stroke-width=\"6.666666666666667\" stroke=\"url(#eye-light)\" fill=\"none\" filter=\"url(#inner-blur)\"></path><path d=\"M425 362.5Q475 412.5 475 362.5 \" stroke-width=\"20\" stroke=\"black\" fill=\"none\" filter=\"url(#eye-shadow)\"></path><path d=\"M425 362.5Q475 412.5 475 362.5 \" stroke-width=\"6.666666666666667\" stroke=\"url(#eye-light)\" fill=\"none\" filter=\"url(#inner-blur)\"></path><path d=\"M350 512.5Q400 562.5 450 512.5 \" stroke-width=\"20\" stroke=\"hsl(3, 100%, 51%)\" fill=\"none\" filter=\"url(#mouth-shadow)\"></path><path d=\"M350 512.5Q400 562.5 450 512.5 \" stroke-width=\"6.666666666666667\" stroke=\"url(#mouth-light)\" fill=\"none\" filter=\"url(#inner-blur)\"></path></g>';

  string Lox = '<defs><radialGradient id=\"ccclaymoji-grad-dark\" r=\"93%\" cx=\"20%\" cy=\"20%\">\r\n      <stop offset=\"70%\" stop-color=\"hsl(10, 75%, 40%)\" stop-opacity=\"0\"></stop>\r\n      <stop offset=\"97%\" stop-color=\"#7c0000\" stop-opacity=\"1\"></stop>\r\n    </radialGradient><radialGradient id=\"ccclaymoji-grad-light\" r=\"65%\" cx=\"28%\" cy=\"20%\">\r\n    <stop offset=\"0%\" stop-color=\"#eb6443\" stop-opacity=\"0.75\"></stop>\r\n    <stop offset=\"100%\" stop-color=\"hsl(10, 75%, 40%)\" stop-opacity=\"0\"></stop>\r\n  </radialGradient><filter id=\"ccclaymoji-blur\" x=\"-100%\" y=\"-100%\" width=\"400%\" height=\"400%\" filterUnits=\"objectBoundingBox\" primitiveUnits=\"userSpaceOnUse\" color-interpolation-filters=\"sRGB\">\r\n\t<feGaussianBlur stdDeviation=\"30\" x=\"0%\" y=\"0%\" width=\"100%\" height=\"100%\" in=\"SourceGraphic\" edgeMode=\"none\" result=\"blur\"></feGaussianBlur></filter><filter id=\"inner-blur\" x=\"-100%\" y=\"-100%\" width=\"400%\" height=\"400%\" filterUnits=\"objectBoundingBox\" primitiveUnits=\"userSpaceOnUse\" color-interpolation-filters=\"sRGB\">\r\n\t<feGaussianBlur stdDeviation=\"2\" x=\"0%\" y=\"0%\" width=\"100%\" height=\"100%\" in=\"SourceGraphic\" edgeMode=\"none\" result=\"blur\"></feGaussianBlur></filter><filter id=\"eye-shadow\" x=\"-100%\" y=\"-100%\" width=\"400%\" height=\"400%\" filterUnits=\"objectBoundingBox\" primitiveUnits=\"userSpaceOnUse\" color-interpolation-filters=\"sRGB\">\r\n\t<feDropShadow stdDeviation=\"10\" dx=\"10\" dy=\"10\" flood-color=\"#000000\" flood-opacity=\"0.2\" x=\"0%\" y=\"0%\" width=\"100%\" height=\"100%\" result=\"dropShadow\"></feDropShadow>\r\n</filter><linearGradient gradientTransform=\"rotate(-25)\" id=\"eye-light\" x1=\"50%\" y1=\"0%\" x2=\"50%\" y2=\"100%\">\r\n      <stop offset=\"20%\" stop-color=\"#555555\" stop-opacity=\"1\"></stop>\r\n      <stop offset=\"100%\" stop-color=\"black\" stop-opacity=\"0\"></stop>\r\n    </linearGradient><linearGradient id=\"mouth-light\" x1=\"50%\" y1=\"0%\" x2=\"50%\" y2=\"100%\">\r\n    <stop offset=\"0%\" stop-color=\"#ff9667\" stop-opacity=\"1\"></stop>\r\n    <stop offset=\"100%\" stop-color=\"hsl(3, 100%, 51%)\" stop-opacity=\"0\"></stop>\r\n  </linearGradient><filter id=\"mouth-shadow\" x=\"-100%\" y=\"-100%\" width=\"400%\" height=\"400%\" filterUnits=\"objectBoundingBox\" primitiveUnits=\"userSpaceOnUse\" color-interpolation-filters=\"sRGB\">\r\n\t<feDropShadow stdDeviation=\"10\" dx=\"10\" dy=\"10\" flood-color=\"#c20000\" flood-opacity=\"0.2\" x=\"0%\" y=\"0%\" width=\"100%\" height=\"100%\" result=\"dropShadow\"></feDropShadow>\r\n</filter></defs><g stroke-linecap=\"round\"><path d=\"M650 449.99998478233977C650 602.9582058065985 552.9582210242588 726.9541626799139 400 726.9541626799139C247.04245283018867 726.9541626799139 150 602.9582058065985 150 449.99998478233977C150 297.04243761252843 247.04245283018867 173.04580688476562 400 173.04580688476562C552.9582210242588 173.04580688476562 650 297.04243761252843 650 449.99998478233977Z \" fill=\"#7c0000\" opacity=\"0.25\" filter=\"url(#ccclaymoji-blur)\"></path><path d=\"M650 399.999996348324C650 561.6737855221131 561.6737891737891 692.7350390833667 400 692.7350390833667C238.3269230769231 692.7350390833667 150 561.6737855221131 150 399.999996348324C150 238.32691942524704 238.3269230769231 107.26495361328125 400 107.26495361328125C561.6737891737891 107.26495361328125 650 238.32691942524704 650 399.999996348324Z \" fill=\"hsl(10, 75%, 40%)\"></path><path d=\"M650 399.999996348324C650 561.6737855221131 561.6737891737891 692.7350390833667 400 692.7350390833667C238.3269230769231 692.7350390833667 150 561.6737855221131 150 399.999996348324C150 238.32691942524704 238.3269230769231 107.26495361328125 400 107.26495361328125C561.6737891737891 107.26495361328125 650 238.32691942524704 650 399.999996348324Z \" fill=\"url(#ccclaymoji-grad-dark)\"></path><path d=\"M650 399.999996348324C650 561.6737855221131 561.6737891737891 692.7350390833667 400 692.7350390833667C238.3269230769231 692.7350390833667 150 561.6737855221131 150 399.999996348324C150 238.32691942524704 238.3269230769231 107.26495361328125 400 107.26495361328125C561.6737891737891 107.26495361328125 650 238.32691942524704 650 399.999996348324Z \" fill=\"url(#ccclaymoji-grad-light)\"></path><ellipse rx=\"23.5\" ry=\"25\" cx=\"350\" cy=\"328\" fill=\"black\" filter=\"url(#eye-shadow)\"></ellipse><ellipse rx=\"23.5\" ry=\"25\" cx=\"350\" cy=\"328\" fill=\"url(#eye-light)\" filter=\"url(#inner-blur)\"></ellipse><ellipse rx=\"23.5\" ry=\"25\" cx=\"450\" cy=\"375\" fill=\"black\" filter=\"url(#eye-shadow)\"></ellipse><ellipse rx=\"23.5\" ry=\"25\" cx=\"450\" cy=\"375\" fill=\"url(#eye-light)\" filter=\"url(#inner-blur)\"></ellipse><path d=\"M350 512.5Q400 562.5 450 512.5 \" fill=\"hsl(3, 100%, 51%)\" filter=\"url(#mouth-shadow)\"></path><path d=\"M350 512.5Q400 562.5 450 512.5 \" fill=\"url(#mouth-light)\" filter=\"url(#inner-blur)\"></path></g>';
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

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
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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