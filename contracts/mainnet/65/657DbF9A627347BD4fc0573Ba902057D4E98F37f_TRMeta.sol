// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import './Base64.sol';
import './TRScript.sol';
import './TRRolls.sol';

interface ITRMeta {

  function tokenURI(TRKeys.RuneCore memory core) external view returns (string memory);
  function tokenScript(TRKeys.RuneCore memory core) external view returns (string memory);
  function getElement(TRKeys.RuneCore memory core) external view returns (string memory);
  function getColorCount(TRKeys.RuneCore memory core) external view returns (uint256);
  function getColorByIndex(TRKeys.RuneCore memory core, uint256 index) external view returns (string memory);
  function getGrailId(TRKeys.RuneCore memory core) external view returns (uint256);
  function getMaxRelicLevel() external pure returns (uint8);

}

/// @notice The Reliquary Metadata v1
contract TRMeta is Ownable, ITRMeta {

  using Strings for uint256;

  string public imageURL = 'https://vibes.art/reliquary/png/';
  string public imageSuffix = '.png';
  string public animationURL = 'https://vibes.art/reliquary/html/';
  string public animationSuffix = '.html';
  address public rollsContract;
  mapping(string => string) public descriptionsByElement;
  mapping(string => string) public descriptionsByEssence;

  error RollsAreImmutable();

  constructor() Ownable() {}

  function tokenURI(TRKeys.RuneCore memory core)
    override
    external
    view
    returns (string memory)
  {
    TRRolls.RelicInfo memory info = ITRRolls(rollsContract).getRelicInfo(core);

    string memory json = string(abi.encodePacked(
      '{"name": "Relic 0x', TRUtils.toCapsHexString(core.runeCode),
      '", "description": "', tokenDescription(core, info),
      '", "image": "', tokenImage(core),
      '", "animation_url": "', tokenAnimation(core),
      '", "attributes": [{ "trait_type": "Element", "value": "', info.element
    ));

    json = string(abi.encodePacked(
      json,
      '" }, { "trait_type": "Type", "value": "', info.relicType,
      '" }, { "trait_type": "Essence", "value": "', info.essence,
      '" }, { "trait_type": "Palette", "value": "', info.palette,
      '" }, { "trait_type": "Style", "value": "', info.style
    ));

    json = string(abi.encodePacked(
      json,
      '" }, { "trait_type": "Speed", "value": "', info.speed,
      '" }, { "trait_type": "Glyph", "value": "', info.glyphType,
      '" }, { "trait_type": "Colors", "value": "', TRUtils.toString(info.colorCount),
      '" }, { "trait_type": "Level", "value": ', TRUtils.toString(core.level)
    ));

    json = string(abi.encodePacked(
      json,
      ' }, { "trait_type": "Mana", "value": ', TRUtils.toString(core.mana),
      ' }], "hidden": [{ "trait_type": "Runeflux", "value": ', TRUtils.toString(info.runeflux),
      ' }, { "trait_type": "Corruption", "value": ', TRUtils.toString(info.corruption),
      ' }, { "trait_type": "Grail", "value": ', TRUtils.toString(info.grailId),
      ' }]}'
    ));

    return string(abi.encodePacked(
      'data:application/json;base64,', Base64.encode(bytes(json))
    ));
  }

  function tokenScript(TRKeys.RuneCore memory core)
    override
    public
    view
    returns (string memory)
  {
    TRRolls.RelicInfo memory info = ITRRolls(rollsContract).getRelicInfo(core);
    string[] memory html = new string[](19);
    uint256[] memory glyph = core.glyph;

    if (info.grailId != TRKeys.GRAIL_ID_NONE) {
      glyph = info.grailGlyph;
    }

    html[0] = '<!doctype html><html><head><script>';
    html[1] = string(abi.encodePacked('var H="', core.runeHash, '";'));
    html[2] = string(abi.encodePacked('var N="', info.essence, '";'));
    html[3] = string(abi.encodePacked('var Y="', info.style, '";'));
    html[4] = string(abi.encodePacked('var E="', info.speed, '";'));
    html[5] = string(abi.encodePacked('var G="', info.gravity, '";'));
    html[6] = string(abi.encodePacked('var D="', info.display, '";'));
    html[7] = string(abi.encodePacked('var V=', TRUtils.toString(core.level), ';'));
    html[8] = string(abi.encodePacked('var F=', TRUtils.toString(info.runeflux), ';'));
    html[9] = string(abi.encodePacked('var C=', TRUtils.toString(info.corruption), ';'));

    string memory itemString;
    string memory partString;
    uint256 i;
    for (; i < TRKeys.RELIC_SIZE; i++) {
      if (i < glyph.length) {
        itemString = glyph[i].toString();
      } else {
        itemString = '0';
      }

      while (bytes(itemString).length < TRKeys.RELIC_SIZE) {
        itemString = string(abi.encodePacked('0', itemString));
      }

      if (i == 0) {
        itemString = string(abi.encodePacked('var L=["', itemString, '",'));
      } else if (i < TRKeys.RELIC_SIZE - 1) {
        itemString = string(abi.encodePacked('"', itemString, '",'));
      } else {
        itemString = string(abi.encodePacked('"', itemString, '"];'));
      }

      partString = string(abi.encodePacked(partString, itemString));
    }

    html[10] = partString;

    for (i = 0; i < 6; i++) {
      if (i < info.colorCount) {
        itemString = ITRRolls(rollsContract).getColorByIndex(core, i);
      } else {
        itemString = '';
      }

      if (i == 0) {
        partString = string(abi.encodePacked('var P=["', itemString, '",'));
      } else if (i < info.colorCount - 1) {
        partString = string(abi.encodePacked('"', itemString, '",'));
      } else if (i < info.colorCount) {
        partString = string(abi.encodePacked('"', itemString, '"];'));
      } else {
        partString = '';
      }

      html[11 + i] = partString;
    }

    html[17] = getScript();
    html[18] = '</script></head><body></body></html>';

    string memory output = string(abi.encodePacked(
      html[0], html[1], html[2], html[3], html[4], html[5], html[6], html[7], html[8]
    ));

    output = string(abi.encodePacked(
      output, html[9], html[10], html[11], html[12], html[13], html[14], html[15], html[16]
    ));

    return string(abi.encodePacked(
      output, html[17], html[18]
    ));
  }

  function tokenDescription(TRKeys.RuneCore memory core, TRRolls.RelicInfo memory info)
    public
    view
    returns (string memory)
  {
    string memory desc = string(abi.encodePacked(
      'Relic 0x', TRUtils.toCapsHexString(core.runeCode),
      '\\n\\n', info.essence, ' ', info.relicType, ' of ', info.element
    ));

    desc = string(abi.encodePacked(
      desc,
      '\\n\\nLevel: ', TRUtils.toString(core.level),
      '\\n\\nMana: ', TRUtils.toString(core.mana),
      '\\n\\nRuneflux: ', TRUtils.toString(info.runeflux),
      '\\n\\nCorruption: ', TRUtils.toString(info.corruption)
    ));

    if (core.credit != address(0)) {
      desc = string(abi.encodePacked(desc, '\\n\\nGlyph by: 0x', TRUtils.toAsciiString(core.credit)));
    }

    string memory additionalInfo = ITRRolls(rollsContract).getDescription(core);
    if (bytes(additionalInfo).length > 0) {
      desc = string(abi.encodePacked(desc, '\\n\\n', additionalInfo));
    }

    if (bytes(descriptionsByElement[info.element]).length > 0) {
      desc = string(abi.encodePacked(desc, '\\n\\n', descriptionsByElement[info.element]));
    }

    if (bytes(descriptionsByEssence[info.essence]).length > 0) {
      desc = string(abi.encodePacked(desc, '\\n\\n', descriptionsByEssence[info.essence]));
    }

    return desc;
  }

  function tokenImage(TRKeys.RuneCore memory core) public view returns (string memory) {
    if (bytes(imageSuffix).length > 0) {
      return string(abi.encodePacked(imageURL, TRUtils.toString(core.tokenId), imageSuffix));
    } else {
      return string(abi.encodePacked(imageURL, TRUtils.toString(core.tokenId)));
    }
  }

  function tokenAnimation(TRKeys.RuneCore memory core) public view returns (string memory) {
    if (bytes(animationURL).length == 0) {
      return string(abi.encodePacked(
        'data:text/html;base64,', Base64.encode(bytes(tokenScript(core)))
      ));
    } else {
      if (bytes(animationSuffix).length > 0) {
        return string(abi.encodePacked(animationURL, TRUtils.toString(core.tokenId), animationSuffix));
      } else {
        return string(abi.encodePacked(animationURL, TRUtils.toString(core.tokenId)));
      }
    }
  }

  function getElement(TRKeys.RuneCore memory core) override public view returns (string memory) {
    return ITRRolls(rollsContract).getElement(core);
  }

  function getPalette(TRKeys.RuneCore memory core) public view returns (string memory) {
    return ITRRolls(rollsContract).getPalette(core);
  }

  function getEssence(TRKeys.RuneCore memory core) public view returns (string memory) {
    return ITRRolls(rollsContract).getEssence(core);
  }

  function getStyle(TRKeys.RuneCore memory core) public view returns (string memory) {
    return ITRRolls(rollsContract).getStyle(core);
  }

  function getSpeed(TRKeys.RuneCore memory core) public view returns (string memory) {
    return ITRRolls(rollsContract).getSpeed(core);
  }

  function getGravity(TRKeys.RuneCore memory core) public view returns (string memory) {
    return ITRRolls(rollsContract).getGravity(core);
  }

  function getDisplay(TRKeys.RuneCore memory core) public view returns (string memory) {
    return ITRRolls(rollsContract).getDisplay(core);
  }

  function getColorCount(TRKeys.RuneCore memory core) override public view returns (uint256) {
    return ITRRolls(rollsContract).getColorCount(core);
  }

  function getColorByIndex(TRKeys.RuneCore memory core, uint256 index)
    override
    public
    view
    returns (string memory)
  {
    return ITRRolls(rollsContract).getColorByIndex(core, index);
  }

  function getRelicType(TRKeys.RuneCore memory core) public view returns (string memory) {
    return ITRRolls(rollsContract).getRelicType(core);
  }

  function getRuneflux(TRKeys.RuneCore memory core) public view returns (uint256) {
    return ITRRolls(rollsContract).getRuneflux(core);
  }

  function getCorruption(TRKeys.RuneCore memory core) public view returns (uint256) {
    return ITRRolls(rollsContract).getCorruption(core);
  }

  function getGrailId(TRKeys.RuneCore memory core) override public view returns (uint256) {
    return ITRRolls(rollsContract).getGrailId(core);
  }

  function getMaxRelicLevel() override public pure returns (uint8) {
    return 2;
  }

  function getScript() public pure returns (string memory) {
    return TRScript.getScript();
  }

  function setDescriptionForElement(string memory element, string memory desc) public onlyOwner {
    descriptionsByElement[element] = desc;
  }

  function setDescriptionForEssence(string memory essence, string memory desc) public onlyOwner {
    descriptionsByEssence[essence] = desc;
  }

  function setImageURL(string memory url) public onlyOwner {
    imageURL = url;
  }

  function setImageSuffix(string memory suffix) public onlyOwner {
    imageSuffix = suffix;
  }

  function setAnimationURL(string memory url) public onlyOwner {
    animationURL = url;
  }

  function setAnimationSuffix(string memory suffix) public onlyOwner {
    animationSuffix = suffix;
  }

  function setRollsContract(address rolls) public onlyOwner {
    if (rollsContract != address(0)) revert RollsAreImmutable();

    rollsContract = rolls;
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

/// SPDX-License-Identifier: MIT
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>

pragma solidity ^0.8.4;

library Base64 {
  bytes internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

  /// @notice Encodes some bytes to the base64 representation
  function encode(bytes memory data) internal pure returns (string memory) {
    uint256 len = data.length;
    if (len == 0) return '';

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
        out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
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

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

/// @notice The Reliquary Canvas App
library TRScript {

  string public constant SCRIPT = 'for(var TH="",i=0;8>i;i++)TH+=H.substr(2,6);H="0x"+TH;for(var HB=!1,PC=64,MT=50,PI=Math.PI,TAU=2*PI,abs=Math.abs,min=Math.min,max=Math.max,sin=Math.sin,cos=Math.cos,pow=Math.pow,sqrt=Math.sqrt,ceil=Math.ceil,floor=Math.floor,rm=null,wW=0,wH=0,cS=1,canvas=null,ctx=null,L2=1<V,BC2=[{x:.5,y:.5},{x:.75,y:0}],BC3=[{x:.65,y:.15},{x:.5,y:.5},{x:.75,y:.75}],BC4=[{x:.5,y:0},{x:0,y:.5},{x:.5,y:1},{x:1,y:.5}],BC5=[{x:.5,y:.5},{x:.5,y:0},{x:0,y:.5},{x:.5,y:1},{x:1,y:.5}],BC6=[{x:.5,y:.5},{x:.5,y:0},{x:1,y:0},{x:1,y:1},{x:0,y:1},{x:0,y:0}],BC=[,,BC2,BC3,BC4,BC5,BC6],gvy=null,pxS=C/1e3,TS=TAU/127.5,DLO=.5+.5*F/1e3,DMD=1e3+19e3*F/1e3,DHI=8+24*F/1e3,RFOP=800<=F?.5+.5*(F-800)/199:0,wST=0,wS=[],wSE=0,eL=[],cPC=P.length,cP=[],pI=0,plC=BC[cPC],iFR=!0,dt=0,pvT=0,iPs=!1,iPt=!1,iEs=!1,iBx=!1,bxS=null,pB=9,pP=Array(PC),x=0;x<PC;x++){pP[x]=Array(PC);for(var y=0;y<PC;y++)pP[x][y]=0}if(L&&L.length===PC)for(var y=0;y<PC;y++)for(var row,x=0;x<PC;x++)row=""+L[y],pP[x][y]=+row.charAt(x);var sp=0;"Zen"==E&&(sp=256),"Tranquil"==E&&(sp=64),"Normal"==E&&(sp=16),"Fast"==E&&(sp=4),"Swift"==E&&(sp=2),"Hyper"==E&&(sp=.5);var sM=SD,sV=-1,sSS=1/3;"Pajamas"==Y&&(sM=SS,sSS=1/99),"Silk"==Y&&(sM=SS,sSS=1/3),"Sketch"==Y&&(sM=SRS);function SD(c,a){return c.distance-a.distance}function SS(){var a=sV;return sV+=sSS,2<=sV&&(sV-=3),a}function SRS(){var a=sV;return sV+=1/(rm()*PC),2<=sV&&(sV-=3),a}var flipX=!("Mirrored"!=D&&"MirroredUpsideDown"!=D),flipY=!("UpsideDown"!=D&&"MirroredUpsideDown"!=D),gv=3;"Lunar"==G&&(gv=.5),"Atmospheric"==G&&(gv=1),"Low"==G&&(gv=2),"High"==G&&(gv=6),"Massive"==G&&(gv=9),"Stellar"==G&&(gv=12),"Galactic"==G&&(gv=24);var ess={l:[]};"Heavenly"==N&&(ess={c:{r:{o:64},g:{o:64},b:{o:32}},l:[{st:{x:.006},n:{s:.006,d:128,c:.024,xp:.5},op:.4},{st:{x:-.007},n:{s:.007,d:128,c:.022,xp:.5},op:.6},{st:{y:.008},n:{s:.008,d:128,c:.02,xp:.5},op:.8},{st:{y:-.009},n:{s:.009,d:128,c:.018,xp:.5},op:1}]}),"Fae"==N&&(ess={l:[{c:{a:{o:16,e:-96}},st:{x:.002,y:-.017},op:.75,sc:1},{c:{a:{o:-16,e:96}},st:{x:-.001,y:-.015},op:.9,sc:1},{c:{a:{o:52,e:8}},st:{x:-.01,y:-.03},op:.9,n:{s:.02,d:64,c:.015,xp:2}}]}),"Prismatic"==N&&(ess={l:[{c:{r:{o:-64,e:128},g:{o:-64,e:128},b:{o:-32,e:64}},op:.75,n:{s:.001,d:1024,c:.001,xp:1}},{c:{r:{o:-64,e:255},g:{o:-64,e:255},b:{o:-32,e:128}},op:.25,n:{s:.001,d:1024,c:.001,xp:1}}]}),"Radiant"==N&&(ess={c:{r:{o:60,e:80},g:{o:60,e:80},b:{o:40,e:60}},l:[{op:1,n:{s:3e-4,d:40,c:.0014,xp:1}}]}),"Photonic"==N&&(ess={c:{a:{o:-64,e:140}},l:[{op:1,n:{s:.01,d:9999,c:.001,xp:3}},{op:1,n:{s:.009,d:9999,c:.001,xp:3}},{op:1,n:{s:.008,d:9999,c:.001,xp:3}},{op:1,n:{s:.007,d:9999,c:.001,xp:3}},{op:1,n:{s:.006,d:9999,c:.001,xp:3}},{op:1,n:{s:.005,d:9999,c:.001,xp:3}}]}),"Forest"==N&&(ess={c:{r:{o:-16,e:96},g:{o:-16,e:96},b:{o:16,e:-96}},l:[{st:{x:.002,y:-.014},op:.4,sc:1},{st:{x:-.001,y:-.012},op:.4,sc:1},{c:{r:{o:96,e:8},g:{o:128,e:8},b:{o:32,e:8}},st:{y:-.05},op:.3,n:{s:.02,d:1024,c:.006,xp:1}}]}),"Life"==N&&(ess={st:{x:-.006},c:{r:{o:-6,e:12},g:{o:-48,e:128},b:{o:-6,e:12}},l:[{op:.1,n:{s:.06,d:32,c:.03,xp:1}},{op:.3,n:{s:.03,d:32,c:.05,xp:2}},{op:.5,n:{s:.02,d:32,c:.07,xp:3}}]}),"Swamp"==N&&(ess={l:[{c:{r:{o:-192},b:{o:32,e:128}},st:{x:.005,y:.005},op:.8,sc:1},{c:{r:{o:-128,e:-64},g:{o:-64,e:128},b:{o:-64,e:-64}},op:1,n:{s:0,d:256,c:.04,xp:2}}]}),"Wildblood"==N&&(ess={c:{r:{o:128,e:128},g:{o:-64,e:32},b:{o:-64,e:32}},l:[{op:.3,n:{s:.002,d:64,c:.075,xp:1}},{op:.3,n:{s:.003,d:64,c:.015,xp:2}},{op:.3,n:{s:.004,d:64,c:.0023,xp:3}}]}),"Soul"==N&&(ess={n:{s:.25,d:128,c:.01,xp:3},l:[{c:{r:{o:200},g:{o:-100},b:{o:-100}},st:{x:-.005,y:-.015},op:1/3},{c:{r:{o:-100},g:{o:200},b:{o:-100}},st:{x:.005,y:-.015},op:1/3},{c:{r:{o:-100},g:{o:-100},b:{o:200}},st:{x:0,y:-.03},op:1/3}]}),"Magic"==N&&(ess={n:{s:.05,d:128,c:.015,xp:.5},l:[{c:{r:{o:200},b:{o:-200}},st:{x:-.02},op:1/3},{c:{r:{o:-200},g:{o:200}},st:{y:-.02},op:1/3},{c:{g:{o:-200},b:{o:200}},st:{x:.02},op:1/3}]}),"Astral"==N&&(ess={c:{r:{o:-64,e:96},g:{o:-64,e:64},b:{o:-64,e:96}},l:[{op:.33,n:{s:.003,d:512,c:.003,xp:1}},{op:.33,n:{s:.003,d:512,c:.003,xp:1}},{op:.33,n:{s:.003,d:512,c:.003,xp:1}},{op:.33,n:{s:.003,d:512,c:.003,xp:1}},{op:.33,n:{s:.003,d:512,c:.003,xp:1}},{op:.33,n:{s:.003,d:512,c:.003,xp:1}}]}),"Forbidden"==N&&(ess={c:{r:{o:-64,e:32},g:{o:-64,e:32},b:{o:128,e:128}},l:[{op:.3,n:{s:.001,d:64,c:.1,xp:1}},{op:.3,n:{s:.002,d:64,c:.02,xp:2}},{op:.3,n:{s:.003,d:64,c:.003,xp:3}}]}),"Runic"==N&&(ess={st:{x:-.005,y:.025},c:{r:{o:-56,e:200},g:{o:-256},b:{o:200,e:56}},n:{noBlend:!0,s:.05,d:19,c:.019,xp:2},l:[{op:.9}]}),"Unknown"==N&&(ess={l:[{c:{a:{o:256}},st:{delay:2,x:.003},n:{s:.25,d:256,c:.01,xp:1},op:1},{c:{a:{o:-256}},st:{delay:1,y:-.006},n:{s:.5,d:256,c:.01,xp:1},op:1}]}),"Tidal"==N&&(ess={c:{r:{o:48},g:{o:48},b:{o:64}},l:[{st:{x:-.02,y:-.015},op:.25,n:{s:.025,d:44,c:.032,xp:2}},{st:{x:-.02,y:.015},op:.25,n:{s:.025,d:44,c:.032,xp:2}},{st:{x:-.04,y:-.03},op:.5,n:{s:.0125,d:44,c:.016,xp:1}},{st:{x:-.04,y:.03},op:.5,n:{s:.0125,d:44,c:.016,xp:1}}]}),"Arctic"==N&&(ess={c:{r:{o:-32,e:64},g:{o:-32,e:64},b:{o:64,e:196}},l:[{op:1,n:{s:2e-6,d:48,c:.0025,xp:1}},{op:.2,n:{s:1e-6,d:512,c:.0025,xp:1}}]}),"Storm"==N&&(ess={l:[{c:{b:{e:255}},st:{x:.04,y:.04},op:1,sc:1},{c:{b:{o:-64,e:128}},st:{x:.03,y:.03},op:1,sc:0},{c:{r:{o:64,e:8},g:{o:64,e:8},b:{o:96,e:8}},st:{x:.05,y:.05},op:.5,n:{s:.01,d:64,c:.008,xp:2}}]}),"Illuvial"==N&&(ess={c:{r:{o:48},g:{o:48},b:{o:64}},l:[{st:{x:.02,y:.025},op:.2,n:{s:.03,d:44,c:.096,xp:2}},{st:{x:.03,y:.025},op:.2,n:{s:.03,d:44,c:.096,xp:2}},{st:{x:.04,y:.05},op:.5,n:{s:.015,d:44,c:.048,xp:1}},{st:{x:.06,y:.05},op:.5,n:{s:.015,d:44,c:.048,xp:1}}]}),"Undine"==N&&(ess={l:[{c:{r:{e:64},g:{e:64},b:{o:32,e:64}},op:.5,n:{s:.01,d:4444,c:.001,xp:1}},{c:{r:{o:-16,e:-333},g:{o:-16,e:-333},b:{o:-16,e:-222}},op:1,n:{s:.008,d:222,c:1e-4,xp:3}}]}),"Mineral"==N&&(ess={l:[{c:{a:{o:-16,e:48}},op:1},{c:{a:{o:-8,e:24}},op:1}]}),"Craggy"==N&&(ess={c:{r:{o:-25,e:-45},g:{o:-35,e:-55},b:{o:-45,e:-65}},n:{s:0,d:240,c:.064,xp:.75},l:[{op:1}]}),"Dwarven"==N&&(ess={c:{r:{o:-75,e:-25},g:{o:-85,e:-35},b:{o:-95,e:-45}},n:{s:0,d:128,c:.016,xp:1},l:[{op:1}]}),"Gnomic"==N&&(ess={c:{r:{o:-25,e:-45},g:{o:-35,e:-55},b:{o:-45,e:-65}},n:{s:0,d:240,c:.0064,xp:.8},l:[{op:1}]}),"Crystal"==N&&(ess={c:{a:{o:-32,e:128}},l:[{op:1},{op:1}]}),"Sylphic"==N&&(ess={l:[{c:{a:{o:-48,e:96}},st:{x:.06},op:1},{c:{a:{o:-16,e:64}},st:{x:.03},op:1}]}),"Visceral"==N&&(ess={c:{r:{o:-48},g:{o:128},b:{o:-48}},l:[{st:{x:.09},op:.1,n:{s:.14,d:128,c:.02,xp:1}},{st:{x:.12},op:.1,n:{s:.16,d:256,c:.004,xp:2}},{st:{x:.15},op:.1,n:{s:.18,d:512,c:6e-4,xp:3}}]}),"Frosted"==N&&(ess={l:[{c:{a:{o:128}},st:{x:-.06,y:.01},op:.33},{c:{r:{o:128},g:{o:128},b:{o:255}},st:{x:-.04,y:.007},op:.33},{c:{a:{o:128,e:8}},st:{x:-.07,y:.015},op:.33,n:{s:.01,d:64,c:.008,xp:2}},{c:{a:{o:128,e:8}},st:{x:-.08,y:.016},op:.33,n:{s:.008,d:64,c:.008,xp:2}}]}),"Electric"==N&&(ess={st:{x:.002,y:-.01},c:{r:{o:-256},g:{o:200,e:56},b:{o:-56,e:200}},n:{noBlend:!0,s:.05,d:19,c:.019,xp:2},l:[{op:.9}]}),"Magnetic"==N&&(ess={l:[{c:{a:{o:-255}},st:{x:-.001,y:-.001},op:.5,n:{s:.0024,d:2,c:4,xp:6}},{c:{a:{o:255}},st:{x:.001,y:.001},op:.5,n:{s:.0018,d:2,c:4,xp:6}}]}),"Infernal"==N&&(ess={l:[{c:{r:{e:255}},st:{x:.006,y:-.03},op:1,sc:1},{c:{r:{o:-64,e:128}},st:{x:.003,y:-.015},op:1,sc:0}]}),"Molten"==N&&(ess={st:{x:.001,y:.001},c:{r:{o:200,e:56},g:{o:-128,e:256},b:{o:-256}},n:{noBlend:!0,s:0,d:20,c:.024,xp:1},l:[{op:.9}]}),"Ashen"==N&&(ess={l:[{c:{r:{o:256,e:256},g:{o:128,e:128}},op:1,n:{s:.004,d:64,c:.03,xp:4}},{c:{r:{o:-512,e:256},g:{o:-512},b:{o:-512}},op:1,n:{s:.004,d:256,c:.02,xp:1}}]}),"Draconic"==N&&(ess={st:{x:-.005,y:.025},c:{r:{o:200,e:56},g:{o:-56,e:200},b:{o:-256}},n:{noBlend:!0,s:.05,d:19,c:.019,xp:2},l:[{op:.9}]}),"Celestial"==N&&(ess={st:{x:.004,y:.002},c:{a:{o:224,e:64}},n:{s:.02,d:50,c:.032,xp:2},l:[{op:1}]}),"Night"==N&&(ess={c:{r:{o:64},g:{o:-128},b:{o:64}},l:[{st:{x:-.03},op:.4,n:{s:.03,d:256,c:.01,xp:1}},{st:{y:-.02},op:.5,n:{s:.02,d:256,c:.01,xp:1}},{st:{x:-.015},op:.6,n:{s:.015,d:256,c:.01,xp:1}}]}),"Forgotten"==N&&(ess={st:{x:.006,y:.006},c:{a:{o:-512}},n:{s:.06,d:256,c:.01,xp:1},l:[{op:1}]}),"Abyssal"==N&&(ess={c:{r:{o:32,e:-512},g:{e:-512},b:{o:96,e:-512}},l:[{st:{x:-.03},op:.8,n:{s:.03,d:32,c:.005,xp:1}},{st:{y:-.02},op:.6,n:{s:.02,d:32,c:.005,xp:1}},{st:{x:.015},op:.4,n:{s:.015,d:32,c:.005,xp:1}},{st:{y:.0125},op:.2,n:{s:.0125,d:32,c:.005,xp:1}}]}),"Evil"==N&&(ess={c:{r:{o:96,e:-512},g:{e:-512},b:{o:32,e:-512}},l:[{st:{x:.01},op:.2,n:{s:.01,d:60,c:.04,xp:1}},{st:{y:.011},op:.4,n:{s:.011,d:70,c:.03,xp:1}},{st:{x:-.012},op:.6,n:{s:.012,d:80,c:.02,xp:1}},{st:{y:-.013},op:.8,n:{s:.013,d:90,c:.01,xp:1}}]}),"Lost"==N&&(ess={c:{a:{e:-512}},l:[{st:{x:-.03},op:.5,n:{s:.03,d:200,c:.03,xp:1}},{st:{y:-.02},op:.5,n:{s:.02,d:200,c:.03,xp:1}},{st:{x:.015},op:.5,n:{s:.015,d:200,c:.03,xp:1}},{st:{y:.0125},op:.5,n:{s:.0125,d:200,c:.03,xp:1}}]}),window.onload=function(){init()};function gAD(){return{id:0,value:0,minValue:0,maxValue:1,target:1,duration:1,elapsed:0,direction:1,easing:lin,ease1:lin,ease2:lin,callback:null}}var animations=[];function animate(a){var b=a.value,c=a.target,d=a.duration,e=a.easing,f=a.callback;a.elapsed=0;var g=function(g){a.elapsed+=dt;var h=max(0,min(1,e(a.elapsed/d)));a.value=b+h*(c-b),a.elapsed>=d&&(animations.splice(g,1),f&&f())};animations.push(g)}function lin(a){return a}function eSin(a){return-(cos(PI*a)-1)/2}function rAL(a){a.direction=-a.direction,a.callback=function(){rAL(a)},0>a.direction?(a.easing=a.ease1,a.target=a.minValue):(a.easing=a.ease2,a.target=a.maxValue),animate(a)}function init(){sRO(),sS(),iD(),cEl(),rC(),lFI(),sR(),rAL(gvy),window.requestAnimationFrame(oAF)}function sRO(){HB=!!document.body;var a=HB?document.body:document.all[1];wW=max(a.clientWidth,window.innerWidth),wH=max(a.clientHeight,window.innerHeight);var b=wW>wH,c=b?wH:wW;cS=c/PC,sV=-1,pI=0,cP.length=0}function cEl(){var a=HB?document.body:document.all[1];canvas=HB?document.createElement("canvas"):document.getElementById("canvas"),ctx=canvas.getContext("2d"),HB&&a.appendChild(canvas);var b=floor(cS*PC),c=document.createElement("style");c.innerText=`canvas { width: ${b}px; height: ${b}px; image-rendering: -moz-crisp-edges; image-rendering: -webkit-crisp-edges; image-rendering: pixelated; image-rendering: crisp-edges; }`,a.appendChild(c)}function rC(){if(HB){var a=floor((wW-cS*PC)/2),b=floor((wH-cS*PC)/2);canvas.style.position="absolute",canvas.style.left=a+"px",canvas.style.top=b+"px"}canvas.width=PC,canvas.height=PC}function gC(a,b){var c=PC*cS,d=floor((b-cS*PC)/2),e=floor(PC*(a-d)/c);return e}function iVC(a){return 0<=a&&a<PC}function gX(a){return gC(a.x,wW)}function gY(a){return gC(a.y,wH)}function pFE(a){if(iPt){var b=gX(a),c=gY(a);if(iVC(b)&&iVC(c)){var d=iEs?0:pB;if(iBx&&bxS){var e=gX(bxS),f=gY(bxS);if(iVC(e)&&iVC(f)){for(var g=b<e?b:e,h=c<f?c:f,i=b<e?e:b,j=c<f?f:c,k=g;k<=i;k++)for(var l=h;l<=j;l++)pP[k][l]=d;return}}pP[b][c]=d}}}function lFI(){document.addEventListener("keydown",a=>{var b=a.key;"Shift"===b&&(iEs=!0)," "===b&&(iBx=!0)},!1),document.addEventListener("keyup",a=>{var b=a.key,c=+b,d=a.ctrlKey;if(!isNaN(c))if(d)for(var e=0;e<PC;e++)for(var f=0;f<PC;f++)pP[e][f]=c;else" "!==b&&(pB=c);"p"===b||"P"===b?iPs=!iPs:"l"===b||"L"===b?lPP():"Shift"===b?iEs=!1:" "===b?(iBx=!1,bxS=null):void 0},!1),window.addEventListener("mousedown",a=>{iPt=!0,iBx&&null===bxS&&(bxS=a)}),window.addEventListener("mousemove",a=>pFE(a)),window.addEventListener("mouseup",a=>{pFE(a),iPt=!1,bxS=null})}function lPP(){for(var a=[],b=0;b<PC;b++){for(var c=0;c<PC;c++)a.push(pP[c][b]);b<PC-1&&a.push(",")}var d="["+a.join("")+"]";console.log(d),cGD(d)}function cGD(a){var b=HB?document.body:document.all[1],c=document.createElement("input");c.className="clipboard",b.appendChild(c),c.value=a,c.select(),document.execCommand("copy"),b.removeChild(c)}function oAF(a){dt=a-pvT,dt>MT?dt=MT:0>dt&&(dt=0),iPs&&(dt=0),sV=-1,pI=0,cP.length=0,wSE+=dt,sS(),sR();for(var b=animations.length,c=b-1;0<=c;c--)animations[c](c);pvT=a,window.requestAnimationFrame(oAF)}function sS(){s=0,t=0;var a=Uint32Array.from([0,1,s=t=2,3].map(function(a){return parseInt(H.substr(11*a+2,11),16)}));rm=function(){return t=a[3],a[3]=a[2],a[2]=a[1],a[1]=s=a[0],t^=t<<11,a[0]^=t^t>>>8^s>>>19,a[0]/4294967296}}function iD(){null===gvy&&(gvy=gAD(),gvy.value=gv,gvy.minValue=gv/2,gvy.maxValue=2*gv,gvy.duration=1750*(sp+2),gvy.ease1=eSin,gvy.ease2=eSin)}function sCl(){var a=P.slice();wS.length=0,wST=0;for(var b=0;b<cPC;b++){var c=gCP(),d=a[b],e=parseInt(d,16);c.r=255&e>>16,c.g=255&e>>8,c.b=255&e,pPt(c),c.weight=pow(gvy.value,5-b),wS.push(c.weight),wST+=c.weight,cP.push(c)}var f=wS[cPC-1],g=2e3*sp;wST-=cPC*f;for(var b=0;b<cPC;b++){var c=cP[b],h=wSE+.5*g*b/(cPC-1),j=cos(TAU*(h%g)/g);c.weight=f+j*wST}if(2===cPC)for(var k=cP[0],l=cP[1];;){var m=l.y-k.y,n=l.x-k.x,o=m/(n||1);if(-1.2<=o&&-.8>=o)pI=0,pPt(k),pPt(l);else break}}var imgData=null,uD=Array(4*PC*PC);function sR(){iFR&&(imgData=ctx.getImageData(0,0,PC,PC),cID(imgData.data),cE());var a=imgData.data;sCl(),L2&&(cID(uD),aE(uD)),dCPG(a),0<RFOP&&aP(a,RFOP),L2?aUD(a):aE(a),aP(a,1),ctx.putImageData(imgData,0,0),iFR=!1}function cID(a){for(var b=a.length,c=0;c<b;c++)a[c]=0==(c+1)%4?255:0}function cE(){for(var c=ess.l,e=ess.st||{},f=ess.n,h=ess.c,k={o:0,e:0},l=0;l<c.length;l++){var o=c[l],p=o.st||e,q=o.n||f,u=o.c||h,v=o.op,w=u.a||k,a=u.r||w,r=u.g||w,g=u.b||w,b=a.o||0,z=a.e||0,A=r.o||0,B=r.e||0,I=g.o||0,J=g.e||0,K={oX:0,oY:0,nOf:0,data:null,nObj:null,nDp:null,config:o,nC:q,stC:p},M=4*PC*PC;if(q){M=PC*PC,p&&(0<p.x&&(K.oX=1e8),0<p.y&&(K.oY=1e8));var O=q.d;K.nObj=cN(q.c,q.xp),K.nDp=[];for(var d=0;d<O;d++){var Q;if(d<.5*O)Q=2*d/O;else{var R=d-.5*O;Q=1-2*R/O}K.nDp.push({r:b+rm()*z,g:A+rm()*B,b:I+rm()*J,a:v*Q})}}if(K.data=Array(M),q)for(var m=0;m<M;m++){var S=floor(m/PC),y=m-S*PC;K.data[m]=K.nObj.get(y,S)}else for(var m=0;m<M;m+=4)K.data[m+0]=rm()*(b+rm()*z),K.data[m+1]=rm()*(A+rm()*B),K.data[m+2]=rm()*(I+rm()*J);eL.push(K)}}function aE(a){for(var b=a.length,c=eL.length,e=0;e<c;e++){var f=eL[e],g=f.data,h=f.nObj,l=f.config,m=f.stC,n=m.x||0,o=m.y||0;if(f.oX-=dt*n,f.oY-=dt*o,h){var p=f.nC,q=f.nDp,r=p.d||2,d=p.s||0;f.nOf+=dt*d;var u=f.nOf;0>u?u=r+u%r:u>=r&&(u%=r);for(var v=0;v<b;v+=4){var w=floor(v/4),k=floor(w/PC),z=floor(w-k*PC)+f.oX;k+=f.oY;var x=h.get(z,k),A=r*x+u,B=ceil(A),I=floor(A),J=q[B%r],K=q[I%r],M=p.noBlend?1:1-(A-I),O=p.noBlend?0:1-M,Q=K.a,R=J.a;a[v]+=M*K.r*Q+O*J.r*R,a[v+1]+=M*K.g*Q+O*J.g*R,a[v+2]+=M*K.b*Q+O*J.b*R}}else{var S=f.oX,T=f.oY,U=l.op||1,W=l.sc||0,X=1-W,Z=floor(S),$=floor(T),_=ceil(S),aa=ceil(T),ba=4*Z,ca=4*PC*$,da=4*_,ea=4*PC*aa,fa=1-(S-Z),ga=1-(T-$),ha=1-fa,ia=1-ga,ja=fa*ga,ka=fa*ia,la=ha*ga,ma=ha*ia,na=ba+ca;0>na?na=b+na%b:na>=b&&(na%=b);var oa=ba+ea;0>oa?oa=b+oa%b:oa>=b&&(oa%=b);var pa=da+ca;0>pa?pa=b+pa%b:pa>=b&&(pa%=b);var qa=da+ea;0>qa?qa=b+qa%b:qa>=b&&(qa%=b);for(var v=0;v<b;v+=4){var ra=(v+na)%b,sa=(v+oa)%b,ta=(v+pa)%b,ua=(v+qa)%b,va=(X+W*rm())*U,wa=(X+W*rm())*U,xa=(X+W*rm())*U;a[v]+=va*(ja*g[ra]+ka*g[sa]+la*g[ta]+ma*g[ua]),a[v+1]+=wa*(ja*g[ra+1]+ka*g[sa+1]+la*g[ta+1]+ma*g[ua+1]),a[v+2]+=xa*(ja*g[ra+2]+ka*g[sa+2]+la*g[ta+2]+ma*g[ua+2])}}}}function aUD(a){for(var b=a.length,c=1-pxS,d=0;d<b;d+=4){var e=d,f=d+1,g=d+2;a[e]+=c*uD[e],a[f]+=c*uD[f],a[g]+=c*uD[g]}}function aP(a,c){for(var d=a.length,e=0;e<d;e+=4){var f=floor(e/4),h=floor(f/PC),i=floor(f-h*PC),j=+pP[i][h];if(j){var l=e,m=e+1,n=e+2,o=a[l],q=a[m],g=a[n],b=c*j/9,r=1-b;a[l]=r*o+b*(255-o),a[m]=r*q+b*(255-q),a[n]=r*g+b*(255-g)}}}function dCPG(a){for(var b=0,c=0;b<PC;){for(c=0;c<PC;)sGCFP(a,cP,b,c),c++;b++}}function gCP(){return{x:0,y:0,r:0,g:0,b:0,weight:1,distance:0}}function pPt(a){var b=plC[pI++];pI>=plC.length&&(pI=0);var c=-.125+.25*rm(),d=-.125+.25*rm();a.x=(b.x+c)*PC,a.y=(b.y+d)*PC}function sGCFP(a,b,d,e){sFCCP(b,d,e);for(var f=[],g=b.length,h=0;h<g;h+=2)h==g-1?f.push(b[h]):f.push(sC(b[h],b[h+1]));if(1===f.length){flipX&&(d=PC-d-1),flipY&&(e=PC-e-1);var j=4*d,k=4*(e*PC),l=k+j,m=f[0],c=l,n=l+1,o=l+2;if(L2){var p=pxS;0<+pP[d][e]&&(p=0);var q=1-p;a[c]=q*m.r+p*a[c],a[n]=q*m.g+p*a[n],a[o]=q*m.b+p*a[o]}else a[c]=m.r,a[n]=m.g,a[o]=m.b}else sGCFP(a,f,d,e)}function sFCCP(a,b,c){var d=a.length;if(L2){var e=b,f=c;flipX&&(e=PC-b-1),flipY&&(f=PC-c-1);var g=4*e,h=4*(f*PC),j=h+g,k=3,l=3,m=3,n=uD[j]-127.5,o=uD[j+1]-127.5,p=uD[j+2]-127.5;150>C?(n=abs(n)*n*DLO,o=abs(o)*o*DLO,p=abs(p)*p*DLO):850>C?(n=DMD*cos(TS*n),o=DMD*cos(TS*o),p=DMD*cos(TS*p)):(k=1+floor(abs((n+127.5)/DHI)),l=1+floor(abs((o+127.5)/DHI)),m=1+floor(abs((p+127.5)/DHI)),n=0,o=0,p=0);for(var q=0;q<d;q++){var r=a[q],u=r.x,v=r.y;r.distance=gDE(b,c,u,v,3),r.rd=gDE(b,c,u,v,k)+n,r.gd=gDE(b,c,u,v,l)+o,r.bd=gDE(b,c,u,v,m)+p}}else for(var r,q=0;q<d;q++)r=a[q],r.distance=gDE(b,c,r.x,r.y,3);a.sort(sM)}function gDE(a,b,c,d,e){return pow(c-a,e)+pow(d-b,e)}function sC(a,b){var c=gCP(),d=a.r,e=a.g,f=a.b,g=b.r,h=b.g,i=b.b,j=a.weight,k=b.weight,l=g-d,m=h-e,n=i-f;if(L2){var o=a.rd*j,p=b.rd*k,q=a.gd*j,r=b.gd*k,u=a.bd*j,v=b.bd*k;c.x=(a.x+b.x)/2,c.y=(a.y+b.y)/2,c.r=p/(o+p)*l+d,c.g=r/(q+r)*m+e,c.b=v/(u+v)*n+f,c.weight=(j+k)/2}else{var w=a.distance*j,x=b.distance*k,y=x/(w+x);c.x=(a.x+b.x)/2,c.y=(a.y+b.y)/2,c.r=y*l+d,c.g=y*m+e,c.b=y*n+f,c.weight=(j+k)/2}return c}function cN(a,b){a=a||1,b=b||1;for(var c=[],d=function(a,b,c){return b*a[0]+c*a[1]},e=sqrt(3),f=[[1,1,0],[-1,1,0],[1,-1,0],[-1,-1,0],[1,0,1],[-1,0,1],[1,0,-1],[-1,0,-1],[0,1,1],[0,-1,1],[0,1,-1],[0,-1,-1]],g=[],h=0;256>h;h++)g[h]=0|256*rm();for(var h=0;512>h;h++)c[h]=g[255&h];return{get:function(g,h){g*=a,h*=a;var k,l,m,n,o,p=(e-1)/2*(g+h),q=0|g+p,i=0|h+p,j=(3-e)/6,r=j*(q+i),u=g-(q-r),v=h-(i-r);u>v?(n=1,o=0):(n=0,o=1);var w=u-n+j,z=v-o+j,A=u-1+2*j,B=v-1+2*j,I=255&q,J=255&i,K=c[I+c[J]]%12,M=c[I+n+c[J+o]]%12,O=c[I+1+c[J+1]]%12,Q=.5-u*u-v*v;0>Q?k=0:(Q*=Q,k=Q*Q*d(f[K],u,v));var R=.5-w*w-z*z;0>R?l=0:(R*=R,l=R*R*d(f[M],w,z));var S=.5-A*A-B*B;0>S?m=0:(S*=S,m=S*S*d(f[O],A,B));var T=(70*(k+l+m)+1)/2;return 1!==b&&(T=pow(T,b)),T}}}';

  function getScript() public pure returns (string memory) {
      return SCRIPT;
  }

}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import './TRColors.sol';

interface ITRRolls {

  struct RelicInfo {
    string element;
    string palette;
    string essence;
    uint256 colorCount;
    string style;
    string speed;
    string gravity;
    string display;
    string relicType;
    string glyphType;
    uint256 runeflux;
    uint256 corruption;
    uint256 grailId;
    uint256[] grailGlyph;
  }

  function getRelicInfo(TRKeys.RuneCore memory core) external view returns (RelicInfo memory);
  function getElement(TRKeys.RuneCore memory core) external view returns (string memory);
  function getPalette(TRKeys.RuneCore memory core) external view returns (string memory);
  function getEssence(TRKeys.RuneCore memory core) external view returns (string memory);
  function getStyle(TRKeys.RuneCore memory core) external view returns (string memory);
  function getSpeed(TRKeys.RuneCore memory core) external view returns (string memory);
  function getGravity(TRKeys.RuneCore memory core) external view returns (string memory);
  function getDisplay(TRKeys.RuneCore memory core) external view returns (string memory);
  function getColorCount(TRKeys.RuneCore memory core) external view returns (uint256);
  function getColorByIndex(TRKeys.RuneCore memory core, uint256 index) external view returns (string memory);
  function getRelicType(TRKeys.RuneCore memory core) external view returns (string memory);
  function getGlyphType(TRKeys.RuneCore memory core) external view returns (string memory);
  function getRuneflux(TRKeys.RuneCore memory core) external view returns (uint256);
  function getCorruption(TRKeys.RuneCore memory core) external view returns (uint256);
  function getDescription(TRKeys.RuneCore memory core) external view returns (string memory);
  function getGrailId(TRKeys.RuneCore memory core) external pure returns (uint256);

}

/// @notice The Reliquary Rarity Distribution
contract TRRolls is Ownable, ITRRolls {

  mapping(uint256 => address) public grailContracts;

  error GrailsAreImmutable();

  constructor() Ownable() {}

  function getRelicInfo(TRKeys.RuneCore memory core)
    override
    public
    view
    returns (RelicInfo memory)
  {
    RelicInfo memory info;
    info.element = getElement(core);
    info.palette = getPalette(core);
    info.essence = getEssence(core);
    info.colorCount = getColorCount(core);
    info.style = getStyle(core);
    info.speed = getSpeed(core);
    info.gravity = getGravity(core);
    info.display = getDisplay(core);
    info.relicType = getRelicType(core);
    info.glyphType = getGlyphType(core);
    info.runeflux = getRuneflux(core);
    info.corruption = getCorruption(core);
    info.grailId = getGrailId(core);

    if (info.grailId != TRKeys.GRAIL_ID_NONE) {
      info.grailGlyph = Grail(grailContracts[info.grailId]).getGlyph();
    }

    return info;
  }

  function getElement(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getElement();
    }

    if (bytes(core.transmutation).length > 0) {
      return core.transmutation;
    }

    uint256 roll = roll1000(core, TRKeys.ROLL_ELEMENT);
    if (roll <= uint256(125)) {
      return TRKeys.ELEM_NATURE;
    } else if (roll <= uint256(250)) {
      return TRKeys.ELEM_LIGHT;
    } else if (roll <= uint256(375)) {
      return TRKeys.ELEM_WATER;
    } else if (roll <= uint256(500)) {
      return TRKeys.ELEM_EARTH;
    } else if (roll <= uint256(625)) {
      return TRKeys.ELEM_WIND;
    } else if (roll <= uint256(750)) {
      return TRKeys.ELEM_ARCANE;
    } else if (roll <= uint256(875)) {
      return TRKeys.ELEM_SHADOW;
    } else {
      return TRKeys.ELEM_FIRE;
    }
  }

  function getPalette(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getPalette();
    }

    if (core.colors.length > 0) {
      return TRKeys.ANY_PAL_CUSTOM;
    }

    string memory element = getElement(core);
    uint256 roll = roll1000(core, TRKeys.ROLL_PALETTE);
    if (TRUtils.compare(element, TRKeys.ELEM_NATURE)) {
      return getNaturePalette(roll);
    } else if (TRUtils.compare(element, TRKeys.ELEM_LIGHT)) {
      return getLightPalette(roll);
    } else if (TRUtils.compare(element, TRKeys.ELEM_WATER)) {
      return getWaterPalette(roll);
    } else if (TRUtils.compare(element, TRKeys.ELEM_EARTH)) {
      return getEarthPalette(roll);
    } else if (TRUtils.compare(element, TRKeys.ELEM_WIND)) {
      return getWindPalette(roll);
    } else if (TRUtils.compare(element, TRKeys.ELEM_ARCANE)) {
      return getArcanePalette(roll);
    } else if (TRUtils.compare(element, TRKeys.ELEM_SHADOW)) {
      return getShadowPalette(roll);
    } else {
      return getFirePalette(roll);
    }
  }

  function getNaturePalette(uint256 roll) public pure returns (string memory) {
    if (roll <= 600) {
      return TRKeys.NAT_PAL_JUNGLE;
    } else if (roll <= 900) {
      return TRKeys.NAT_PAL_CAMOUFLAGE;
    } else {
      return TRKeys.NAT_PAL_BIOLUMINESCENCE;
    }
  }

  function getLightPalette(uint256 roll) public pure returns (string memory) {
    if (roll <= 600) {
      return TRKeys.LIG_PAL_PASTEL;
    } else if (roll <= 900) {
      return TRKeys.LIG_PAL_INFRARED;
    } else {
      return TRKeys.LIG_PAL_ULTRAVIOLET;
    }
  }

  function getWaterPalette(uint256 roll) public pure returns (string memory) {
    if (roll <= 600) {
      return TRKeys.WAT_PAL_FROZEN;
    } else if (roll <= 900) {
      return TRKeys.WAT_PAL_DAWN;
    } else {
      return TRKeys.WAT_PAL_OPALESCENT;
    }
  }

  function getEarthPalette(uint256 roll) public pure returns (string memory) {
    if (roll <= 600) {
      return TRKeys.EAR_PAL_COAL;
    } else if (roll <= 900) {
      return TRKeys.EAR_PAL_SILVER;
    } else {
      return TRKeys.EAR_PAL_GOLD;
    }
  }

  function getWindPalette(uint256 roll) public pure returns (string memory) {
    if (roll <= 600) {
      return TRKeys.WIN_PAL_BERRY;
    } else if (roll <= 900) {
      return TRKeys.WIN_PAL_THUNDER;
    } else {
      return TRKeys.WIN_PAL_AERO;
    }
  }

  function getArcanePalette(uint256 roll) public pure returns (string memory) {
    if (roll <= 600) {
      return TRKeys.ARC_PAL_FROSTFIRE;
    } else if (roll <= 900) {
      return TRKeys.ARC_PAL_COSMIC;
    } else {
      return TRKeys.ARC_PAL_COLORLESS;
    }
  }

  function getShadowPalette(uint256 roll) public pure returns (string memory) {
    if (roll <= 600) {
      return TRKeys.SHA_PAL_DARKNESS;
    } else if (roll <= 900) {
      return TRKeys.SHA_PAL_VOID;
    } else {
      return TRKeys.SHA_PAL_UNDEAD;
    }
  }

  function getFirePalette(uint256 roll) public pure returns (string memory) {
    if (roll <= 600) {
      return TRKeys.FIR_PAL_HEAT;
    } else if (roll <= 900) {
      return TRKeys.FIR_PAL_EMBER;
    } else {
      return TRKeys.FIR_PAL_CORRUPTED;
    }
  }

  function getEssence(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getEssence();
    }

    string memory element = getElement(core);
    string memory relicType = getRelicType(core);
    if (TRUtils.compare(element, TRKeys.ELEM_NATURE)) {
      return getNatureEssence(relicType);
    } else if (TRUtils.compare(element, TRKeys.ELEM_LIGHT)) {
      return getLightEssence(relicType);
    } else if (TRUtils.compare(element, TRKeys.ELEM_WATER)) {
      return getWaterEssence(relicType);
    } else if (TRUtils.compare(element, TRKeys.ELEM_EARTH)) {
      return getEarthEssence(relicType);
    } else if (TRUtils.compare(element, TRKeys.ELEM_WIND)) {
      return getWindEssence(relicType);
    } else if (TRUtils.compare(element, TRKeys.ELEM_ARCANE)) {
      return getArcaneEssence(relicType);
    } else if (TRUtils.compare(element, TRKeys.ELEM_SHADOW)) {
      return getShadowEssence(relicType);
    } else {
      return getFireEssence(relicType);
    }
  }

  function getNatureEssence(string memory relicType) public pure returns (string memory) {
    if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TRINKET)) {
      return TRKeys.NAT_ESS_FOREST;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TALISMAN)) {
      return TRKeys.NAT_ESS_SWAMP;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_AMULET)) {
      return TRKeys.NAT_ESS_WILDBLOOD;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_FOCUS)) {
      return TRKeys.NAT_ESS_LIFE;
    } else {
      return TRKeys.NAT_ESS_SOUL;
    }
  }

  function getLightEssence(string memory relicType) public pure returns (string memory) {
    if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TRINKET)) {
      return TRKeys.LIG_ESS_HEAVENLY;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TALISMAN)) {
      return TRKeys.LIG_ESS_FAE;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_AMULET)) {
      return TRKeys.LIG_ESS_PRISMATIC;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_FOCUS)) {
      return TRKeys.LIG_ESS_RADIANT;
    } else {
      return TRKeys.LIG_ESS_PHOTONIC;
    }
  }

  function getWaterEssence(string memory relicType) public pure returns (string memory) {
    if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TRINKET)) {
      return TRKeys.WAT_ESS_TIDAL;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TALISMAN)) {
      return TRKeys.WAT_ESS_ARCTIC;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_AMULET)) {
      return TRKeys.WAT_ESS_STORM;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_FOCUS)) {
      return TRKeys.WAT_ESS_ILLUVIAL;
    } else {
      return TRKeys.WAT_ESS_UNDINE;
    }
  }

  function getEarthEssence(string memory relicType) public pure returns (string memory) {
    if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TRINKET)) {
      return TRKeys.EAR_ESS_MINERAL;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TALISMAN)) {
      return TRKeys.EAR_ESS_CRAGGY;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_AMULET)) {
      return TRKeys.EAR_ESS_DWARVEN;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_FOCUS)) {
      return TRKeys.EAR_ESS_GNOMIC;
    } else {
      return TRKeys.EAR_ESS_CRYSTAL;
    }
  }

  function getWindEssence(string memory relicType) public pure returns (string memory) {
    if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TRINKET)) {
      return TRKeys.WIN_ESS_SYLPHIC;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TALISMAN)) {
      return TRKeys.WIN_ESS_VISCERAL;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_AMULET)) {
      return TRKeys.WIN_ESS_FROSTED;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_FOCUS)) {
      return TRKeys.WIN_ESS_ELECTRIC;
    } else {
      return TRKeys.WIN_ESS_MAGNETIC;
    }
  }

  function getArcaneEssence(string memory relicType) public pure returns (string memory) {
    if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TRINKET)) {
      return TRKeys.ARC_ESS_MAGIC;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TALISMAN)) {
      return TRKeys.ARC_ESS_ASTRAL;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_AMULET)) {
      return TRKeys.ARC_ESS_FORBIDDEN;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_FOCUS)) {
      return TRKeys.ARC_ESS_RUNIC;
    } else {
      return TRKeys.ARC_ESS_UNKNOWN;
    }
  }

  function getShadowEssence(string memory relicType) public pure returns (string memory) {
    if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TRINKET)) {
      return TRKeys.SHA_ESS_NIGHT;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TALISMAN)) {
      return TRKeys.SHA_ESS_FORGOTTEN;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_AMULET)) {
      return TRKeys.SHA_ESS_ABYSSAL;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_FOCUS)) {
      return TRKeys.SHA_ESS_EVIL;
    } else {
      return TRKeys.SHA_ESS_LOST;
    }
  }

  function getFireEssence(string memory relicType) public pure returns (string memory) {
    if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TRINKET)) {
      return TRKeys.FIR_ESS_INFERNAL;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TALISMAN)) {
      return TRKeys.FIR_ESS_MOLTEN;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_AMULET)) {
      return TRKeys.FIR_ESS_ASHEN;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_FOCUS)) {
      return TRKeys.FIR_ESS_DRACONIC;
    } else {
      return TRKeys.FIR_ESS_CELESTIAL;
    }
  }

  function getStyle(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getStyle();
    }

    uint256 roll = roll1000(core, TRKeys.ROLL_STYLE);
    if (roll <= 760) {
      return TRKeys.STYLE_SMOOTH;
    } else if (roll <= 940) {
      return TRKeys.STYLE_SILK;
    } else if (roll <= 980) {
      return TRKeys.STYLE_PAJAMAS;
    } else {
      return TRKeys.STYLE_SKETCH;
    }
  }

  function getSpeed(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getSpeed();
    }

    uint256 roll = roll1000(core, TRKeys.ROLL_SPEED);
    if (roll <= 70) {
      return TRKeys.SPEED_ZEN;
    } else if (roll <= 260) {
      return TRKeys.SPEED_TRANQUIL;
    } else if (roll <= 760) {
      return TRKeys.SPEED_NORMAL;
    } else if (roll <= 890) {
      return TRKeys.SPEED_FAST;
    } else if (roll <= 960) {
      return TRKeys.SPEED_SWIFT;
    } else {
      return TRKeys.SPEED_HYPER;
    }
  }

  function getGravity(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getGravity();
    }

    uint256 roll = roll1000(core, TRKeys.ROLL_GRAVITY);
    if (roll <= 50) {
      return TRKeys.GRAV_LUNAR;
    } else if (roll <= 150) {
      return TRKeys.GRAV_ATMOSPHERIC;
    } else if (roll <= 340) {
      return TRKeys.GRAV_LOW;
    } else if (roll <= 730) {
      return TRKeys.GRAV_NORMAL;
    } else if (roll <= 920) {
      return TRKeys.GRAV_HIGH;
    } else if (roll <= 970) {
      return TRKeys.GRAV_MASSIVE;
    } else if (roll <= 995) {
      return TRKeys.GRAV_STELLAR;
    } else {
      return TRKeys.GRAV_GALACTIC;
    }
  }

  function getDisplay(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getDisplay();
    }

    uint256 roll = roll1000(core, TRKeys.ROLL_DISPLAY);
    if (roll <= 250) {
      return TRKeys.DISPLAY_NORMAL;
    } else if (roll <= 500) {
      return TRKeys.DISPLAY_MIRRORED;
    } else if (roll <= 750) {
      return TRKeys.DISPLAY_UPSIDEDOWN;
    } else {
      return TRKeys.DISPLAY_MIRROREDUPSIDEDOWN;
    }
  }

  function getColorCount(TRKeys.RuneCore memory core) override public view returns (uint256) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getColorCount();
    }

    string memory style = getStyle(core);
    if (TRUtils.compare(style, TRKeys.STYLE_SILK)) {
      return 5;
    } else if (TRUtils.compare(style, TRKeys.STYLE_PAJAMAS)) {
      return 5;
    } else if (TRUtils.compare(style, TRKeys.STYLE_SKETCH)) {
      return 4;
    }

    uint256 roll = roll1000(core, TRKeys.ROLL_COLORCOUNT);
    if (roll <= 400) {
      return 2;
    } else if (roll <= 750) {
      return 3;
    } else {
      return 4;
    }
  }

  function getColorByIndex(TRKeys.RuneCore memory core, uint256 index)
    override
    public
    view
    returns (string memory)
  {
    // if the requested index exceeds the color count, return empty string
    if (index >= getColorCount(core)) {
      return '';
    }

    // if we've imagined new colors, use them instead
    if (core.colors.length > index) {
      return TRUtils.getColorCode(core.colors[index]);
    }

    // fetch the color palette
    uint256[] memory colorInts;
    uint256 colorIntCount;
    (colorInts, colorIntCount) = TRColors.get(getPalette(core));

    // shuffle the color palette
    uint256 i;
    uint256 temp;
    uint256 count = colorIntCount;
    while (count > 0) {
      string memory rollKey = string(abi.encodePacked(
        TRKeys.ROLL_SHUFFLE,
        TRUtils.toString(count)
      ));

      i = roll1000(core, rollKey) % count;

      temp = colorInts[--count];
      colorInts[count] = colorInts[i];
      colorInts[i] = temp;
    }

    // slightly adjust the RGB channels of the color to make it unique
    temp = getWobbledColor(core, index, colorInts[index % colorIntCount]);

    // return a hex code (without the #)
    return TRUtils.getColorCode(temp);
  }

  function getWobbledColor(TRKeys.RuneCore memory core, uint256 index, uint256 color)
    public
    pure
    returns (uint256)
  {
    uint256 r = (color >> uint256(16)) & uint256(255);
    uint256 g = (color >> uint256(8)) & uint256(255);
    uint256 b = color & uint256(255);

    string memory k = TRUtils.toString(index);
    uint256 dr = rollMax(core, string(abi.encodePacked(TRKeys.ROLL_RED, k))) % 8;
    uint256 dg = rollMax(core, string(abi.encodePacked(TRKeys.ROLL_GREEN, k))) % 8;
    uint256 db = rollMax(core, string(abi.encodePacked(TRKeys.ROLL_BLUE, k))) % 8;
    uint256 rSign = rollMax(core, string(abi.encodePacked(TRKeys.ROLL_REDSIGN, k))) % 2;
    uint256 gSign = rollMax(core, string(abi.encodePacked(TRKeys.ROLL_GREENSIGN, k))) % 2;
    uint256 bSign = rollMax(core, string(abi.encodePacked(TRKeys.ROLL_BLUESIGN, k))) % 2;

    if (rSign == 0) {
      if (r > dr) {
        r -= dr;
      } else {
        r = 0;
      }
    } else {
      if (r + dr <= 255) {
        r += dr;
      } else {
        r = 255;
      }
    }

    if (gSign == 0) {
      if (g > dg) {
        g -= dg;
      } else {
        g = 0;
      }
    } else {
      if (g + dg <= 255) {
        g += dg;
      } else {
        g = 255;
      }
    }

    if (bSign == 0) {
      if (b > db) {
        b -= db;
      } else {
        b = 0;
      }
    } else {
      if (b + db <= 255) {
        b += db;
      } else {
        b = 255;
      }
    }

    return uint256((r << uint256(16)) | (g << uint256(8)) | b);
  }

  function getRelicType(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getRelicType();
    }

    if (core.isDivinityQuestLoot) {
      return TRKeys.RELIC_TYPE_CURIO;
    }

    uint256 roll = roll1000(core, TRKeys.ROLL_RELICTYPE);
    if (roll <= 360) {
      return TRKeys.RELIC_TYPE_TRINKET;
    } else if (roll <= 620) {
      return TRKeys.RELIC_TYPE_TALISMAN;
    } else if (roll <= 820) {
      return TRKeys.RELIC_TYPE_AMULET;
    } else if (roll <= 960) {
      return TRKeys.RELIC_TYPE_FOCUS;
    } else {
      return TRKeys.RELIC_TYPE_CURIO;
    }
  }

  function getGlyphType(TRKeys.RuneCore memory core) override public pure returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return TRKeys.GLYPH_TYPE_GRAIL;
    }

    if (core.glyph.length > 0) {
      return TRKeys.GLYPH_TYPE_CUSTOM;
    }

    return TRKeys.GLYPH_TYPE_NONE;
  }

  function getRuneflux(TRKeys.RuneCore memory core) override public view returns (uint256) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getRuneflux();
    }

    if (core.isDivinityQuestLoot) {
      return 700 + rollMax(core, TRKeys.ROLL_RUNEFLUX) % 300;
    }

    return roll1000(core, TRKeys.ROLL_RUNEFLUX) - 1;
  }

  function getCorruption(TRKeys.RuneCore memory core) override public view returns (uint256) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getCorruption();
    }

    if (core.isDivinityQuestLoot) {
      return 700 + rollMax(core, TRKeys.ROLL_CORRUPTION) % 300;
    }

    return roll1000(core, TRKeys.ROLL_CORRUPTION) - 1;
  }

  function getDescription(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getDescription();
    }

    return '';
  }

  function getGrailId(TRKeys.RuneCore memory core) override public pure returns (uint256) {
    uint256 grailId = TRKeys.GRAIL_ID_NONE;

    if (bytes(core.hiddenLeyLines).length > 0) {
      uint256 rollDist = TRUtils.random(core.hiddenLeyLines) ^ TRUtils.random(TRKeys.ROLL_GRAILS);
      uint256 digits = 1 + rollDist % TRKeys.GRAIL_DISTRIBUTION;
      for (uint256 i; i < TRKeys.GRAIL_COUNT; i++) {
        if (core.tokenId == digits + TRKeys.GRAIL_DISTRIBUTION * i) {
          uint256 rollShuf = TRUtils.random(core.hiddenLeyLines) ^ TRUtils.random(TRKeys.ROLL_ELEMENT);
          uint256 offset = rollShuf % TRKeys.GRAIL_COUNT;
          grailId = 1 + (i + offset) % TRKeys.GRAIL_COUNT;
          break;
        }
      }
    }

    return grailId;
  }

  function rollMax(TRKeys.RuneCore memory core, string memory key) internal pure returns (uint256) {
    string memory tokenKey = string(abi.encodePacked(key, TRUtils.toString(7 * core.tokenId)));
    return TRUtils.random(core.runeHash) ^ TRUtils.random(tokenKey);
  }

  function roll1000(TRKeys.RuneCore memory core, string memory key) internal pure returns (uint256) {
    return 1 + rollMax(core, key) % 1000;
  }

  function rollColor(TRKeys.RuneCore memory core, uint256 index) internal pure returns (uint256) {
    string memory k = TRUtils.toString(index);
    return rollMax(core, string(abi.encodePacked(TRKeys.ROLL_RANDOMCOLOR, k))) % 16777216;
  }

  function setGrailContract(uint256 grailId, address grailContract) public onlyOwner {
    if (grailContracts[grailId] != address(0)) revert GrailsAreImmutable();

    grailContracts[grailId] = grailContract;
  }

}



abstract contract Grail {
  function getElement() external pure virtual returns (string memory);
  function getPalette() external pure virtual returns (string memory);
  function getEssence() external pure virtual returns (string memory);
  function getStyle() external pure virtual returns (string memory);
  function getSpeed() external pure virtual returns (string memory);
  function getGravity() external pure virtual returns (string memory);
  function getDisplay() external pure virtual returns (string memory);
  function getColorCount() external pure virtual returns (uint256);
  function getRelicType() external pure virtual returns (string memory);
  function getRuneflux() external pure virtual returns (uint256);
  function getCorruption() external pure virtual returns (uint256);
  function getGlyph() external pure virtual returns (uint256[] memory);
  function getDescription() external pure virtual returns (string memory);
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

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './TRKeys.sol';

/// @notice The Reliquary Color Palettes
library TRColors {

  function get(string memory palette)
    public
    pure
    returns (uint256[] memory, uint256)
  {
    uint256[] memory colorInts = new uint256[](12);
    uint256 colorIntCount = 0;

    if (TRUtils.compare(palette, TRKeys.NAT_PAL_JUNGLE)) {
      colorInts[0] = uint256(3299866);
      colorInts[1] = uint256(1256965);
      colorInts[2] = uint256(2375731);
      colorInts[3] = uint256(67585);
      colorInts[4] = uint256(16749568);
      colorInts[5] = uint256(16776295);
      colorInts[6] = uint256(16748230);
      colorInts[7] = uint256(16749568);
      colorInts[8] = uint256(67585);
      colorInts[9] = uint256(2375731);
      colorIntCount = uint256(10);
    } else if (TRUtils.compare(palette, TRKeys.NAT_PAL_CAMOUFLAGE)) {
      colorInts[0] = uint256(10328673);
      colorInts[1] = uint256(6245168);
      colorInts[2] = uint256(2171169);
      colorInts[3] = uint256(4610624);
      colorInts[4] = uint256(5269320);
      colorInts[5] = uint256(4994846);
      colorIntCount = uint256(6);
    } else if (TRUtils.compare(palette, TRKeys.NAT_PAL_BIOLUMINESCENCE)) {
      colorInts[0] = uint256(2434341);
      colorInts[1] = uint256(4194315);
      colorInts[2] = uint256(6488209);
      colorInts[3] = uint256(7270568);
      colorInts[4] = uint256(9117400);
      colorInts[5] = uint256(1599944);
      colorIntCount = uint256(6);
    } else if (TRUtils.compare(palette, TRKeys.LIG_PAL_PASTEL)) {
      colorInts[0] = uint256(16761760);
      colorInts[1] = uint256(16756669);
      colorInts[2] = uint256(16636817);
      colorInts[3] = uint256(13762047);
      colorInts[4] = uint256(8714928);
      colorInts[5] = uint256(9425908);
      colorInts[6] = uint256(16499435);
      colorInts[7] = uint256(10587345);
      colorIntCount = uint256(8);
    } else if (TRUtils.compare(palette, TRKeys.LIG_PAL_INFRARED)) {
      colorInts[0] = uint256(16642938);
      colorInts[1] = uint256(16755712);
      colorInts[2] = uint256(15883521);
      colorInts[3] = uint256(13503623);
      colorInts[4] = uint256(8257951);
      colorInts[5] = uint256(327783);
      colorInts[6] = uint256(13503623);
      colorInts[7] = uint256(15883521);
      colorIntCount = uint256(8);
    } else if (TRUtils.compare(palette, TRKeys.LIG_PAL_ULTRAVIOLET)) {
      colorInts[0] = uint256(14200063);
      colorInts[1] = uint256(5046460);
      colorInts[2] = uint256(16775167);
      colorInts[3] = uint256(16024318);
      colorInts[4] = uint256(11665662);
      colorInts[5] = uint256(1507410);
      colorIntCount = uint256(6);
    } else if (TRUtils.compare(palette, TRKeys.WAT_PAL_FROZEN)) {
      colorInts[0] = uint256(13034750);
      colorInts[1] = uint256(4102128);
      colorInts[2] = uint256(826589);
      colorInts[3] = uint256(346764);
      colorInts[4] = uint256(6707);
      colorInts[5] = uint256(1277652);
      colorIntCount = uint256(6);
    } else if (TRUtils.compare(palette, TRKeys.WAT_PAL_DAWN)) {
      colorInts[0] = uint256(334699);
      colorInts[1] = uint256(610965);
      colorInts[2] = uint256(5408708);
      colorInts[3] = uint256(16755539);
      colorIntCount = uint256(4);
    } else if (TRUtils.compare(palette, TRKeys.WAT_PAL_OPALESCENT)) {
      colorInts[0] = uint256(15985337);
      colorInts[1] = uint256(15981758);
      colorInts[2] = uint256(15713994);
      colorInts[3] = uint256(13941977);
      colorInts[4] = uint256(8242919);
      colorInts[5] = uint256(15985337);
      colorInts[6] = uint256(15981758);
      colorInts[7] = uint256(15713994);
      colorInts[8] = uint256(13941977);
      colorInts[9] = uint256(8242919);
      colorIntCount = uint256(10);
    } else if (TRUtils.compare(palette, TRKeys.EAR_PAL_COAL)) {
      colorInts[0] = uint256(3613475);
      colorInts[1] = uint256(1577233);
      colorInts[2] = uint256(4407359);
      colorInts[3] = uint256(2894892);
      colorIntCount = uint256(4);
    } else if (TRUtils.compare(palette, TRKeys.EAR_PAL_SILVER)) {
      colorInts[0] = uint256(16053492);
      colorInts[1] = uint256(15329769);
      colorInts[2] = uint256(10132122);
      colorInts[3] = uint256(6776679);
      colorInts[4] = uint256(3881787);
      colorInts[5] = uint256(1579032);
      colorIntCount = uint256(6);
    } else if (TRUtils.compare(palette, TRKeys.EAR_PAL_GOLD)) {
      colorInts[0] = uint256(16373583);
      colorInts[1] = uint256(12152866);
      colorInts[2] = uint256(12806164);
      colorInts[3] = uint256(4725765);
      colorInts[4] = uint256(2557441);
      colorIntCount = uint256(5);
    } else if (TRUtils.compare(palette, TRKeys.WIN_PAL_BERRY)) {
      colorInts[0] = uint256(5428970);
      colorInts[1] = uint256(13323211);
      colorInts[2] = uint256(15385745);
      colorInts[3] = uint256(13355851);
      colorInts[4] = uint256(15356630);
      colorInts[5] = uint256(14903600);
      colorIntCount = uint256(6);
    } else if (TRUtils.compare(palette, TRKeys.WIN_PAL_THUNDER)) {
      colorInts[0] = uint256(924722);
      colorInts[1] = uint256(9464002);
      colorInts[2] = uint256(470093);
      colorInts[3] = uint256(6378394);
      colorInts[4] = uint256(16246484);
      colorInts[5] = uint256(12114921);
      colorIntCount = uint256(6);
    } else if (TRUtils.compare(palette, TRKeys.WIN_PAL_AERO)) {
      colorInts[0] = uint256(4609);
      colorInts[1] = uint256(803087);
      colorInts[2] = uint256(2062109);
      colorInts[3] = uint256(11009906);
      colorIntCount = uint256(4);
    } else if (TRUtils.compare(palette, TRKeys.ARC_PAL_FROSTFIRE)) {
      colorInts[0] = uint256(16772570);
      colorInts[1] = uint256(4043519);
      colorInts[2] = uint256(16758832);
      colorInts[3] = uint256(16720962);
      colorIntCount = uint256(4);
    } else if (TRUtils.compare(palette, TRKeys.ARC_PAL_COSMIC)) {
      colorInts[0] = uint256(1182264);
      colorInts[1] = uint256(10834562);
      colorInts[2] = uint256(4269159);
      colorInts[3] = uint256(16769495);
      colorInts[4] = uint256(3351916);
      colorInts[5] = uint256(12612224);
      colorIntCount = uint256(6);
    } else if (TRUtils.compare(palette, TRKeys.ARC_PAL_COLORLESS)) {
      colorInts[0] = uint256(1644825);
      colorInts[1] = uint256(15132390);
      colorIntCount = uint256(2);
    } else if (TRUtils.compare(palette, TRKeys.SHA_PAL_DARKNESS)) {
      colorInts[0] = uint256(2885188);
      colorInts[1] = uint256(1572943);
      colorInts[2] = uint256(1179979);
      colorInts[3] = uint256(657930);
      colorIntCount = uint256(4);
    } else if (TRUtils.compare(palette, TRKeys.SHA_PAL_VOID)) {
      colorInts[0] = uint256(1572943);
      colorInts[1] = uint256(4194415);
      colorInts[2] = uint256(6488209);
      colorInts[3] = uint256(13051525);
      colorInts[4] = uint256(657930);
      colorIntCount = uint256(5);
    } else if (TRUtils.compare(palette, TRKeys.SHA_PAL_UNDEAD)) {
      colorInts[0] = uint256(3546937);
      colorInts[1] = uint256(50595);
      colorInts[2] = uint256(7511983);
      colorInts[3] = uint256(7563923);
      colorInts[4] = uint256(10535352);
      colorIntCount = uint256(5);
    } else if (TRUtils.compare(palette, TRKeys.FIR_PAL_HEAT)) {
      colorInts[0] = uint256(590337);
      colorInts[1] = uint256(12141574);
      colorInts[2] = uint256(15908162);
      colorInts[3] = uint256(6886400);
      colorIntCount = uint256(4);
    } else if (TRUtils.compare(palette, TRKeys.FIR_PAL_EMBER)) {
      colorInts[0] = uint256(1180162);
      colorInts[1] = uint256(7929858);
      colorInts[2] = uint256(7012357);
      colorInts[3] = uint256(16744737);
      colorIntCount = uint256(4);
    } else {
      colorInts[0] = uint256(197391);
      colorInts[1] = uint256(3604610);
      colorInts[2] = uint256(6553778);
      colorInts[3] = uint256(14305728);
      colorIntCount = uint256(4);
    }

    return (colorInts, colorIntCount);
  }

}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import './TRUtils.sol';

/// @notice The Reliquary Constants
library TRKeys {

  struct RuneCore {
    uint256 tokenId;
    uint8 level;
    uint32 mana;
    bool isDivinityQuestLoot;
    bool isSecretDiscovered;
    uint8 secretsDiscovered;
    uint256 runeCode;
    string runeHash;
    string transmutation;
    address credit;
    uint256[] glyph;
    uint24[] colors;
    address metadataAddress;
    string hiddenLeyLines;
  }

  uint256 public constant FIRST_OPEN_VIBES_ID = 7778;
  address public constant VIBES_GENESIS = 0x6c7C97CaFf156473F6C9836522AE6e1d6448Abe7;
  address public constant VIBES_OPEN = 0xF3FCd0F025c21F087dbEB754516D2AD8279140Fc;

  uint8 public constant CURIO_SUPPLY = 64;
  uint256 public constant CURIO_TITHE = 80000000000000000; // 0.08 ETH

  uint32 public constant MANA_PER_YEAR = 100;
  uint32 public constant MANA_PER_YEAR_LV2 = 150;
  uint32 public constant SECONDS_PER_YEAR = 31536000;
  uint32 public constant MANA_FROM_REVELATION = 50;
  uint32 public constant MANA_FROM_DIVINATION = 50;
  uint32 public constant MANA_FROM_VIBRATION = 100;
  uint32 public constant MANA_COST_TO_UPGRADE = 150;

  uint256 public constant RELIC_SIZE = 64;
  uint256 public constant RELIC_SUPPLY = 1047;
  uint256 public constant TOTAL_SUPPLY = CURIO_SUPPLY + RELIC_SUPPLY;
  uint256 public constant RELIC_TITHE = 150000000000000000; // 0.15 ETH
  uint256 public constant INVENTORY_CAPACITY = 10;
  uint256 public constant BYTES_PER_RELICHASH = 3;
  uint256 public constant BYTES_PER_BLOCKHASH = 32;
  uint256 public constant HALF_POSSIBILITY_SPACE = (16**6) / 2;
  bytes32 public constant RELICHASH_MASK = 0x0000000000000000000000000000000000000000000000000000000000ffffff;
  uint256 public constant RELIC_DISCOUNT_GENESIS = 120000000000000000; // 0.12 ETH
  uint256 public constant RELIC_DISCOUNT_OPEN = 50000000000000000; // 0.05 ETH

  uint256 public constant RELIQUARY_CHAMBER_OUTSIDE = 0;
  uint256 public constant RELIQUARY_CHAMBER_GUARDIANS_HALL = 1;
  uint256 public constant RELIQUARY_CHAMBER_INNER_SANCTUM = 2;
  uint256 public constant RELIQUARY_CHAMBER_DIVINITYS_END = 3;
  uint256 public constant RELIQUARY_CHAMBER_CHAMPIONS_VAULT = 4;
  uint256 public constant ELEMENTAL_GUARDIAN_DNA = 88888888;
  uint256 public constant GRAIL_ID_NONE = 0;
  uint256 public constant GRAIL_ID_NATURE = 1;
  uint256 public constant GRAIL_ID_LIGHT = 2;
  uint256 public constant GRAIL_ID_WATER = 3;
  uint256 public constant GRAIL_ID_EARTH = 4;
  uint256 public constant GRAIL_ID_WIND = 5;
  uint256 public constant GRAIL_ID_ARCANE = 6;
  uint256 public constant GRAIL_ID_SHADOW = 7;
  uint256 public constant GRAIL_ID_FIRE = 8;
  uint256 public constant GRAIL_COUNT = 8;
  uint256 public constant GRAIL_DISTRIBUTION = 100;
  uint8 public constant SECRETS_OF_THE_GRAIL = 128;
  uint8 public constant MODE_TRANSMUTE_ELEMENT = 1;
  uint8 public constant MODE_CREATE_GLYPH = 2;
  uint8 public constant MODE_IMAGINE_COLORS = 3;

  uint256 public constant MAX_COLOR_INTS = 10;

  string public constant ROLL_ELEMENT = 'ELEMENT';
  string public constant ROLL_PALETTE = 'PALETTE';
  string public constant ROLL_SHUFFLE = 'SHUFFLE';
  string public constant ROLL_RED = 'RED';
  string public constant ROLL_GREEN = 'GREEN';
  string public constant ROLL_BLUE = 'BLUE';
  string public constant ROLL_REDSIGN = 'REDSIGN';
  string public constant ROLL_GREENSIGN = 'GREENSIGN';
  string public constant ROLL_BLUESIGN = 'BLUESIGN';
  string public constant ROLL_RANDOMCOLOR = 'RANDOMCOLOR';
  string public constant ROLL_RELICTYPE = 'RELICTYPE';
  string public constant ROLL_STYLE = 'STYLE';
  string public constant ROLL_COLORCOUNT = 'COLORCOUNT';
  string public constant ROLL_SPEED = 'SPEED';
  string public constant ROLL_GRAVITY = 'GRAVITY';
  string public constant ROLL_DISPLAY = 'DISPLAY';
  string public constant ROLL_GRAILS = 'GRAILS';
  string public constant ROLL_RUNEFLUX = 'RUNEFLUX';
  string public constant ROLL_CORRUPTION = 'CORRUPTION';

  string public constant RELIC_TYPE_GRAIL = 'Grail';
  string public constant RELIC_TYPE_CURIO = 'Curio';
  string public constant RELIC_TYPE_FOCUS = 'Focus';
  string public constant RELIC_TYPE_AMULET = 'Amulet';
  string public constant RELIC_TYPE_TALISMAN = 'Talisman';
  string public constant RELIC_TYPE_TRINKET = 'Trinket';

  string public constant GLYPH_TYPE_GRAIL = 'Origin';
  string public constant GLYPH_TYPE_CUSTOM = 'Divine';
  string public constant GLYPH_TYPE_NONE = 'None';

  string public constant ELEM_NATURE = 'Nature';
  string public constant ELEM_LIGHT = 'Light';
  string public constant ELEM_WATER = 'Water';
  string public constant ELEM_EARTH = 'Earth';
  string public constant ELEM_WIND = 'Wind';
  string public constant ELEM_ARCANE = 'Arcane';
  string public constant ELEM_SHADOW = 'Shadow';
  string public constant ELEM_FIRE = 'Fire';

  string public constant ANY_PAL_CUSTOM = 'Divine';

  string public constant NAT_PAL_JUNGLE = 'Jungle';
  string public constant NAT_PAL_CAMOUFLAGE = 'Camouflage';
  string public constant NAT_PAL_BIOLUMINESCENCE = 'Bioluminescence';

  string public constant NAT_ESS_FOREST = 'Forest';
  string public constant NAT_ESS_LIFE = 'Life';
  string public constant NAT_ESS_SWAMP = 'Swamp';
  string public constant NAT_ESS_WILDBLOOD = 'Wildblood';
  string public constant NAT_ESS_SOUL = 'Soul';

  string public constant LIG_PAL_PASTEL = 'Pastel';
  string public constant LIG_PAL_INFRARED = 'Infrared';
  string public constant LIG_PAL_ULTRAVIOLET = 'Ultraviolet';

  string public constant LIG_ESS_HEAVENLY = 'Heavenly';
  string public constant LIG_ESS_FAE = 'Fae';
  string public constant LIG_ESS_PRISMATIC = 'Prismatic';
  string public constant LIG_ESS_RADIANT = 'Radiant';
  string public constant LIG_ESS_PHOTONIC = 'Photonic';

  string public constant WAT_PAL_FROZEN = 'Frozen';
  string public constant WAT_PAL_DAWN = 'Dawn';
  string public constant WAT_PAL_OPALESCENT = 'Opalescent';

  string public constant WAT_ESS_TIDAL = 'Tidal';
  string public constant WAT_ESS_ARCTIC = 'Arctic';
  string public constant WAT_ESS_STORM = 'Storm';
  string public constant WAT_ESS_ILLUVIAL = 'Illuvial';
  string public constant WAT_ESS_UNDINE = 'Undine';

  string public constant EAR_PAL_COAL = 'Coal';
  string public constant EAR_PAL_SILVER = 'Silver';
  string public constant EAR_PAL_GOLD = 'Gold';

  string public constant EAR_ESS_MINERAL = 'Mineral';
  string public constant EAR_ESS_CRAGGY = 'Craggy';
  string public constant EAR_ESS_DWARVEN = 'Dwarven';
  string public constant EAR_ESS_GNOMIC = 'Gnomic';
  string public constant EAR_ESS_CRYSTAL = 'Crystal';

  string public constant WIN_PAL_BERRY = 'Berry';
  string public constant WIN_PAL_THUNDER = 'Thunder';
  string public constant WIN_PAL_AERO = 'Aero';

  string public constant WIN_ESS_SYLPHIC = 'Sylphic';
  string public constant WIN_ESS_VISCERAL = 'Visceral';
  string public constant WIN_ESS_FROSTED = 'Frosted';
  string public constant WIN_ESS_ELECTRIC = 'Electric';
  string public constant WIN_ESS_MAGNETIC = 'Magnetic';

  string public constant ARC_PAL_FROSTFIRE = 'Frostfire';
  string public constant ARC_PAL_COSMIC = 'Cosmic';
  string public constant ARC_PAL_COLORLESS = 'Colorless';

  string public constant ARC_ESS_MAGIC = 'Magic';
  string public constant ARC_ESS_ASTRAL = 'Astral';
  string public constant ARC_ESS_FORBIDDEN = 'Forbidden';
  string public constant ARC_ESS_RUNIC = 'Runic';
  string public constant ARC_ESS_UNKNOWN = 'Unknown';

  string public constant SHA_PAL_DARKNESS = 'Darkness';
  string public constant SHA_PAL_VOID = 'Void';
  string public constant SHA_PAL_UNDEAD = 'Undead';

  string public constant SHA_ESS_NIGHT = 'Night';
  string public constant SHA_ESS_FORGOTTEN = 'Forgotten';
  string public constant SHA_ESS_ABYSSAL = 'Abyssal';
  string public constant SHA_ESS_EVIL = 'Evil';
  string public constant SHA_ESS_LOST = 'Lost';

  string public constant FIR_PAL_HEAT = 'Heat';
  string public constant FIR_PAL_EMBER = 'Ember';
  string public constant FIR_PAL_CORRUPTED = 'Corrupted';

  string public constant FIR_ESS_INFERNAL = 'Infernal';
  string public constant FIR_ESS_MOLTEN = 'Molten';
  string public constant FIR_ESS_ASHEN = 'Ashen';
  string public constant FIR_ESS_DRACONIC = 'Draconic';
  string public constant FIR_ESS_CELESTIAL = 'Celestial';

  string public constant STYLE_SMOOTH = 'Smooth';
  string public constant STYLE_PAJAMAS = 'Pajamas';
  string public constant STYLE_SILK = 'Silk';
  string public constant STYLE_SKETCH = 'Sketch';

  string public constant SPEED_ZEN = 'Zen';
  string public constant SPEED_TRANQUIL = 'Tranquil';
  string public constant SPEED_NORMAL = 'Normal';
  string public constant SPEED_FAST = 'Fast';
  string public constant SPEED_SWIFT = 'Swift';
  string public constant SPEED_HYPER = 'Hyper';

  string public constant GRAV_LUNAR = 'Lunar';
  string public constant GRAV_ATMOSPHERIC = 'Atmospheric';
  string public constant GRAV_LOW = 'Low';
  string public constant GRAV_NORMAL = 'Normal';
  string public constant GRAV_HIGH = 'High';
  string public constant GRAV_MASSIVE = 'Massive';
  string public constant GRAV_STELLAR = 'Stellar';
  string public constant GRAV_GALACTIC = 'Galactic';

  string public constant DISPLAY_NORMAL = 'Normal';
  string public constant DISPLAY_MIRRORED = 'Mirrored';
  string public constant DISPLAY_UPSIDEDOWN = 'UpsideDown';
  string public constant DISPLAY_MIRROREDUPSIDEDOWN = 'MirroredUpsideDown';

}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

/// @notice The Reliquary Utility Methods
library TRUtils {

  function random(string memory input) public pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
  }

  function getColorCode(uint256 color) public pure returns (string memory) {
    bytes16 hexChars = '0123456789abcdef';
    uint256 r1 = (color >> uint256(20)) & uint256(15);
    uint256 r2 = (color >> uint256(16)) & uint256(15);
    uint256 g1 = (color >> uint256(12)) & uint256(15);
    uint256 g2 = (color >> uint256(8)) & uint256(15);
    uint256 b1 = (color >> uint256(4)) & uint256(15);
    uint256 b2 = color & uint256(15);
    bytes memory code = new bytes(6);
    code[0] = hexChars[r1];
    code[1] = hexChars[r2];
    code[2] = hexChars[g1];
    code[3] = hexChars[g2];
    code[4] = hexChars[b1];
    code[5] = hexChars[b2];
    return string(code);
  }

  function compare(string memory a, string memory b) public pure returns (bool) {
    if (bytes(a).length != bytes(b).length) {
      return false;
    } else {
      return keccak256(bytes(a)) == keccak256(bytes(b));
    }
  }

  function toString(uint256 value) public pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
      return '0';
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

  // https://ethereum.stackexchange.com/a/8447
  function toAsciiString(address x) public pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
      bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
      bytes1 hi = bytes1(uint8(b) / 16);
      bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
      s[2*i] = char(hi);
      s[2*i+1] = char(lo);
    }
    return string(s);
  }

  function char(bytes1 b) internal pure returns (bytes1 c) {
    if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    else return bytes1(uint8(b) + 0x57);
  }

  // https://stackoverflow.com/a/69302348/424107
  function toCapsHexString(uint256 i) internal pure returns (string memory) {
    if (i == 0) return '0';
    uint j = i;
    uint length;
    while (j != 0) {
      length++;
      j = j >> 4;
    }
    uint mask = 15;
    bytes memory bstr = new bytes(length);
    uint k = length;
    while (i != 0) {
      uint curr = (i & mask);
      bstr[--k] = curr > 9 ?
        bytes1(uint8(55 + curr)) :
        bytes1(uint8(48 + curr)); // 55 = 65 - 10
      i = i >> 4;
    }
    return string(bstr);
  }

}