// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MarqueeArt is Ownable {
  string public baseMQEAnimationURI;
  string public baseCSSAnimationURI;
  string public baseExternalURI;
  string private _metaDescription;
  string public font;
  bool private _useOnChainAnimation;

  constructor(
    string memory _baseMQEAnimationURI,
    string memory _baseCSSAnimationURI,
    string memory metaDescription_,
    string memory _font
  ) {
    setBaseAnimationURI(Mode.Marquee, _baseMQEAnimationURI);
    setBaseAnimationURI(Mode.CSS, _baseCSSAnimationURI);
    setMetaDescription(metaDescription_);
    setFont(_font);
  }

  enum Mode {
    Marquee,
    CSS
  }
  // name, base, sky, border, cloud1, cloud2, grass
  string[7][8] private palettes = [
    ["Morning", "#CF9", "#6CF", "#000", "#FFF", "#CCC", "#0C0"],
    ["Noon", "#6F9", "#6FF", "#000", "#FFF", "#CCC", "#063"],
    ["Afternoon", "#CC6", "#F96", "#000", "#FFF", "#CCC", "#363"],
    ["Evening", "#3C9", "#36C", "#000", "#FFF", "#CCC", "#390"],
    ["Night", "#066", "#33C", "#000", "#FF0", "#FFC", "#993"],
    ["Midnight", "#393", "#006", "#000", "#FF0", "#FFC", "#363"],
    ["Cyber", "#000", "#000", "#096", "#096", "#096", "#096"],
    ["Terminal", "#000", "#000", "#FFF", "#FFF", "#FFF", "#FFF"]
  ];

  uint8[18] private paletteIndices = [
    0,
    0,
    0,
    0,
    1,
    1,
    1,
    1,
    2,
    2,
    3,
    3,
    4,
    4,
    5,
    5,
    6,
    7
  ];

  string[5] private flowerColors = ["#FC3", "#F36", "#F9C", "#99C", "#36C"];

  string[10] private dogColors = [
    "#000",
    "#666",
    "#999",
    "#FFF",
    "#FCC",
    "#C96",
    "#633",
    "#933",
    "#C93",
    "#633"
  ];

  uint8[5] private speeds = [2, 3, 4, 5, 6];

  string[10] private heads = [
    unicode"▲ ▲ ",
    unicode"▼ ▼ ",
    "v v ",
    "^ ^ ",
    "/|/|",
    "|\\|\\",
    "|\\/|",
    "/)(\\",
    "(\\/)",
    "U U "
  ];

  string[5] private noses = ["o", ".", "@", "*", unicode"ω"];

  string[13] private eyes = [
    "-^^",
    "-66",
    "-99",
    "[email protected]@",
    "-++",
    "-==",
    "-''",
    unicode"-‘‘",
    unicode"-’’",
    unicode"-■■",
    unicode"-▼▼",
    unicode"-○○",
    unicode"-●●"
  ];

  uint8[24] private eyesIndices = [
    0,
    0,
    0,
    1,
    1,
    2,
    2,
    3,
    3,
    4,
    4,
    5,
    5,
    6,
    6,
    6,
    7,
    7,
    8,
    8,
    9,
    10,
    11,
    12
  ];

  string[2] private faces = [" )", "))"];
  string[6] private tails = ["o", "p", "(", ")", "/", unicode"」"];
  string[4] private mice = [" --", ' ""', " ^-", " `-"];
  string[6] private necks = ["-  ", "__/", "\\  ", ";  ", ")  ", ",  "];
  string[3] private bodies = ["       )", "))))))))", "# # # #)"];
  uint8[8] private bodiesIndices = [0, 0, 0, 0, 0, 0, 1, 2];
  string[4] private legs = [
    "(_)_)-(_)_)",
    "|_|_|-|_|_|",
    "/_/_/-\\_\\_\\",
    "(_(_/-\\_)_)"
  ];

  function setFont(string memory base64) public onlyOwner {
    font = base64;
  }

  function setMetaDescription(string memory description) public onlyOwner {
    _metaDescription = description;
  }

  function setBaseExternalURI(string memory URI) public onlyOwner {
    baseExternalURI = URI;
  }

  function setBaseAnimationURI(Mode mode, string memory URI) public onlyOwner {
    if (mode == Mode.Marquee) {
      baseMQEAnimationURI = URI;
    } else {
      baseCSSAnimationURI = URI;
    }
  }

  function setUseOnChainAnimation(bool value) public onlyOwner {
    _useOnChainAnimation = value;
  }

  // @dev name, base, sky, border, cloud1, cloud2, grass, flower1, flower2, dog
  function getPalette(uint256 _tokenId)
    public
    view
    returns (string[10] memory palette)
  {
    uint256 rand = random(_tokenId, "PLT");
    uint8 index = paletteIndices[rand % paletteIndices.length];

    for (uint8 i; i < 7; i++) {
      palette[i] = palettes[index][i];
    }

    // flower1, flower2, dog
    if (index == 6 || index == 7) {
      palette[7] = palette[3];
      palette[8] = palette[3];
      palette[9] = palette[3];
    } else {
      palette[7] = flowerColors[random(_tokenId, "FC") % flowerColors.length];
      palette[8] = flowerColors[
        random(_tokenId + 1, "FC") % flowerColors.length
      ];
      palette[9] = dogColors[random(_tokenId, "DGC") % dogColors.length];
    }
  }

  function random(uint256 tokenId, string memory keyPrefix)
    internal
    pure
    returns (uint256)
  {
    return
      uint256(
        keccak256(abi.encodePacked(keyPrefix, Strings.toString(tokenId)))
      );
  }

  function getDogStringRaw(uint256 _tokenId, Mode mode)
    public
    view
    returns (string[5] memory)
  {
    string[5] memory texts;
    texts[0] = mode == Mode.CSS ? unicode"   ⊂⊃" : "";
    texts[1] = string(
      abi.encodePacked("  ", heads[random(_tokenId, "HEAD") % heads.length])
    );
    texts[2] = string(
      abi.encodePacked(
        noses[random(_tokenId, "NOSE") % noses.length],
        eyes[eyesIndices[random(_tokenId, "EYE") % eyesIndices.length]],
        faces[random(_tokenId, "FACE") % faces.length],
        "_______",
        tails[random(_tokenId, "TAIL") % tails.length]
      )
    );
    texts[3] = string(
      abi.encodePacked(
        mice[random(_tokenId, "MOUCE") % mice.length],
        necks[random(_tokenId, "NECK") % necks.length],
        bodies[bodiesIndices[random(_tokenId, "BODY") % bodiesIndices.length]]
      )
    );
    texts[4] = string(
      abi.encodePacked("   ", legs[random(_tokenId, "LEG") % legs.length])
    );
    return texts;
  }

  function getDogString(uint256 _tokenId, Mode mode)
    public
    view
    returns (string memory)
  {
    string[5] memory texts = getDogStringRaw(_tokenId, mode);
    return
      string(
        abi.encodePacked(
          texts[0],
          "\n",
          texts[1],
          "\n",
          texts[2],
          "\n",
          texts[3],
          "\n",
          texts[4]
        )
      );
  }

  function getCloud(
    uint256 _tokenId,
    uint8 index,
    Mode mode
  ) private view returns (string memory) {
    uint256 rand = random(_tokenId * index, "Cloud");
    string[10] memory palette = getPalette(_tokenId);
    uint8 d = [0, 1, 2][rand % 3]; // left, right, bounce
    string memory c = [palette[4], palette[5]][rand % 2];
    string memory t = [
      "This text will scroll from right to left",
      "This text will scroll from left to right",
      "This text will bounce"
    ][d];
    t = rand % 600 == 0 ? "Good boy!" : t;
    uint8 s = speeds[rand % speeds.length];
    return
      string(
        abi.encodePacked(
          '<div style="height:23.5px;margin-bottom:1px;color:',
          c,
          '">',
          getMarqueeStart(d, mode, 500, 0, s, 0),
          t,
          getMarqueeEnd(d, mode),
          "</div>"
        )
      );
  }

  function getMarqueeStart(
    uint8 direction,
    Mode mode,
    uint32 width,
    uint32 height,
    uint8 speedX,
    uint8 speedY
  ) private pure returns (string memory) {
    if (mode == Mode.Marquee) {
      if (direction == 0 || direction == 1) {
        string memory c = ["left", "right"][direction];
        return
          string(
            abi.encodePacked(
              '<marquee height="100%" direction="',
              c,
              '" scrollamount="',
              Strings.toString(speedX),
              '">'
            )
          );
      } else if (direction == 2) {
        return
          string(
            abi.encodePacked(
              '<marquee height="100%" behavior="alternate" scrollamount="',
              Strings.toString(speedX),
              '">'
            )
          );
      } else {
        return
          string(
            abi.encodePacked(
              '<marquee height="100%" direction="down" behavior="alternate" scrollamount="',
              Strings.toString(speedY),
              '"><marquee direction="right" behavior="alternate" scrollamount="',
              Strings.toString(speedX),
              '">'
            )
          );
      }
    } else {
      if (direction == 0 || direction == 1) {
        string memory s = Strings.toString((width * 1000) / (speedX * 8));
        string memory c = ["rtl", "ltr"][direction];
        return
          string(
            abi.encodePacked(
              '<div class="',
              c,
              '" style="animation-duration:',
              s,
              'ms;">'
            )
          );
      } else if (direction == 2) {
        string memory s = Strings.toString((width * 1000) / (speedX * 24));
        return
          string(
            abi.encodePacked(
              '<div class="bh" style="animation-duration:',
              s,
              'ms"><div class="bhi"  style="animation-duration:',
              s,
              'ms">'
            )
          );
      } else {
        string memory sx = Strings.toString((width * 1000) / (speedX * 24));
        string memory sy = Strings.toString((height * 1000) / (speedY * 24));
        return
          string(
            abi.encodePacked(
              '<div class="bv" style="animation-duration:',
              sy,
              'ms;width:100%;height:100%"><div class="bh" style="animation-duration:',
              sx,
              'ms"><div class="bvi" style="animation-duration:',
              sy,
              'ms"><div class="bhi" style="animation-duration:',
              sx,
              'ms">'
            )
          );
      }
    }
  }

  function getMarqueeEnd(uint8 direction, Mode mode)
    private
    pure
    returns (string memory)
  {
    if (mode == Mode.Marquee) {
      return direction == 3 ? "</marquee></marquee>" : "</marquee>";
    } else {
      return
        (direction == 0 || direction == 1) ? "</div>" : (direction == 2)
          ? "</div></div>"
          : "</div></div></div></div>";
    }
  }

  function getFlower(
    uint256 _tokenId,
    Mode mode,
    uint256 index,
    uint8 speed
  ) private view returns (string memory) {
    string[10] memory palette = getPalette(_tokenId);

    return
      string(
        abi.encodePacked(
          '<div style="font-size:16px;padding:2% 0">',
          getMarqueeStart(1, mode, 500, 0, speed, 0),
          '<pre><span style="color:',
          index == 1 ? palette[7] : palette[8],
          '">       *                 *                 *</span>\n',
          '<span style="color:',
          palette[6],
          '">,;,   \\|/   ,;,   ,;,   \\|/   ,;,   ,;,   \\|/   ,;,</span></pre>',
          getMarqueeEnd(1, mode),
          "</div>"
        )
      );
  }

  function fontFamily() private view returns (string memory) {
    return
      string(
        abi.encodePacked(
          "@font-face {font-family:'MARQ';font-display:fallback;src:url(data:application/font-woff2;charset=utf-8;base64,",
          font,
          ") format('woff2');}"
          '*{font-family: "MARQ", Menlo, Monaco, Consolas, "Roboto Mono", "Ubuntu Mono", "Liberation Mono", monospace;}'
        )
      );
  }

  function htmlWrapper(string memory body, Mode mode)
    private
    view
    returns (string memory)
  {
    string memory cssModeStyle = string(
      abi.encodePacked(
        ".rtl{display:inline-block;padding-left:100%;white-space: nowrap;animation:rtl 5s linear infinite;}",
        "@keyframes rtl{from{transform:translateX(0%);}to{transform:translateX(-100%);}}",
        ".ltr{display:inline-block;padding-left:100%;white-space:nowrap;animation:ltr 5s linear infinite;}",
        "@keyframes ltr{from{transform:translateX(-100%);}to{transform:translateX(0%);}}",
        ".bh{display:inline-block;width:100%;white-space:nowrap;animation:bh 2s linear infinite alternate;}",
        "@keyframes bh{0%{transform:translateX(100%);}100%{transform:translateX(0%);}}",
        ".bhi{display:inline-block;animation:bhi 2s linear infinite alternate;}",
        "@keyframes bhi{0%{transform:translateX(-100%);}100%{transform: translateX(0%);}}",
        ".bv{display:inline-block;animation:bv 3s linear infinite alternate;}",
        "@keyframes bv{0%{transform:translateY(100%);}100%{transform:translateY(0%);}}",
        ".bvi{display:inline-block;animation:bvi 3s linear infinite alternate}",
        "@keyframes bvi{0%{transform:translateY(-100%);}100% {transform:translateY(0%);}}"
      )
    );

    return
      string(
        abi.encodePacked(
          '<!DOCTYPE html><html lang="en"><head><meta charset="utf-8" /><title>Marquee</title><meta name="viewport" content="width=device-width,initial-scale=1"><style>',
          fontFamily(),
          "*,*::before,*::after{box-sizing:border-box}*{margin:0;line-height:1}html,body{height:100%;background:#000}",
          mode == Mode.CSS ? cssModeStyle : "",
          "</style>",
          "</head>",
          "<body>",
          '<div style="position:relative;display:flex;align-items:center;justify-content:center;width:100%;height:100%;">',
          body,
          "</div><script>",
          'var r = function() {var w = document.body.clientWidth;var h = document.body.clientHeight;var s = w > h ? h : w;document.getElementById("c").style.transform = "scale(" + s / 500 + ")";};setInterval(r,1000);window.onload = r;window.onresize = r;',
          "</script></body></html>"
        )
      );
  }

  function getDogSpeed(uint256 _tokenId) public view returns (uint8, uint8) {
    uint256 rand1 = random(_tokenId, "DS1");
    uint256 rand2 = random(_tokenId, "DS2");
    return (speeds[rand1 % speeds.length], speeds[rand2 % speeds.length]);
  }

  function tokenBODY(
    uint256 _tokenId,
    Mode mode,
    Mode dogMode
  ) private view returns (string memory) {
    string[10] memory palette = getPalette(_tokenId);
    (uint8 ds1, uint8 ds2) = getDogSpeed(_tokenId);
    string memory clouds;
    string memory dog;
    string memory top;

    {
      string[6] memory ca;
      for (uint8 i = 0; i < 6; i++) {
        ca[i] = getCloud(_tokenId, i + 1, mode);
      }
      clouds = string(
        abi.encodePacked(ca[0], ca[1], ca[2], ca[3], ca[4], ca[5])
      );
    }
    {
      string[5] memory dgs = getDogStringRaw(_tokenId, dogMode);
      string memory ls;
      {
        ls = string(
          abi.encodePacked(
            '<div style="width:208px">',
            getMarqueeStart(2, mode, 13, 0, 1, 1),
            '<pre style="width:202px">',
            dgs[4],
            "</pre>",
            getMarqueeEnd(2, mode),
            "</div>"
          )
        );
      }
      string memory bs;
      {
        bs = string(
          abi.encodePacked(
            "<pre>",
            dgs[0],
            "\n",
            dgs[1],
            "\n",
            dgs[2],
            "\n",
            dgs[3],
            ls,
            "</pre>"
          )
        );
      }
      dog = string(
        abi.encodePacked(
          getMarqueeStart(3, mode, 500, 270, ds1, ds2),
          bs,
          getMarqueeEnd(3, mode)
        )
      );
    }
    {
      top = string(
        abi.encodePacked(
          '<div id="c" style="width:500px;height:500px;font-size:24px;background-color:',
          palette[1],
          ';"><div style="overflow:hidden;width:500px;height:500px">',
          '<div style="background-color:',
          palette[2],
          ";width:100%;height:30%;font-size:21px;border-bottom:2px ",
          palette[3],
          ' solid;">',
          clouds,
          "</div>"
        )
      );
    }

    return
      string(
        abi.encodePacked(
          top,
          '<div style="height:70%">',
          getFlower(_tokenId, mode, 1, 2),
          '<div style="height:69%;color:',
          palette[9],
          '">',
          dog,
          "</div>",
          getFlower(_tokenId, mode, 2, 3),
          "</div></div></div>"
        )
      );
  }

  function tokenHTML(uint256 _tokenId, Mode mode)
    public
    view
    returns (string memory)
  {
    return htmlWrapper(tokenBODY(_tokenId, mode, mode), mode);
  }

  function tokenSVG(uint256 _tokenId, Mode mode)
    public
    view
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          '<svg width="500" height="500" preserveAspectRatio="xMinYMin meet" viewBox="0 0 500 500" version="1.1" xmlns="http://www.w3.org/2000/svg"><style>',
          fontFamily(),
          "*,*::before,*::after{box-sizing:border-box}*{margin:0;line-height:1}html,body{height:100%;background:#000}",
          ".rtl,.ltr,.bh,.bhi,.bv,.bvi{display:inline-block;white-space: nowrap;display:flex}",
          ".rtl{justify-content:flex-end}.ltr{justify-content:flex-start}.bh,.bv{justify-content:center;align-items:center}",
          "</style>",
          '<foreignObject x="0" y="0" width="500" height="500"><div style="width:100%;height:100%;" xmlns="http://www.w3.org/1999/xhtml">',
          tokenBODY(_tokenId, Mode.CSS, mode),
          "</div></foreignObject></svg>"
        )
      );
  }

  function getMetaData(
    uint256 _tokenId,
    Mode mode,
    uint256 resDate
  ) private view returns (string memory) {
    string[10] memory palette = getPalette(_tokenId);
    (uint8 ds1, uint8 ds2) = getDogSpeed(_tokenId);

    string memory rescue;
    {
      rescue = resDate > 0
        ? string(
          abi.encodePacked(
            ',{"display_type": "date","trait_type":"Rescued day","value":',
            Strings.toString(resDate),
            "}"
          )
        )
        : "";
    }

    string memory animationURI;
    {
      animationURI = mode == Mode.Marquee
        ? baseMQEAnimationURI
        : baseCSSAnimationURI;
    }

    string memory resurrection = mode == Mode.CSS ? "YES" : "NO";

    string memory _animationUrl;
    {
      if (_useOnChainAnimation) {
        _animationUrl = string(
          abi.encodePacked(
            "data:text/html;base64,",
            Base64.encode(bytes(tokenHTML(_tokenId, mode)))
          )
        );
      } else {
        _animationUrl = string(
          abi.encodePacked(animationURI, Strings.toString(_tokenId))
        );
      }
    }

    string memory _externalUrl;
    {
      _externalUrl = string(
        abi.encodePacked(baseExternalURI, Strings.toString(_tokenId))
      );
    }

    return
      string(
        abi.encodePacked(
          '{"name":"',
          string(abi.encodePacked("<marquee/> #", Strings.toString(_tokenId))),
          '","description":"',
          _metaDescription,
          '","image":"data:image/svg+xml;base64,',
          Base64.encode(bytes(tokenSVG(_tokenId, mode))),
          '","animation_url":"',
          _animationUrl,
          '","external_url":"',
          _externalUrl,
          '","attributes": [{"trait_type":"Palette","value":"',
          palette[0],
          '"},{"trait_type":"Dog Color","value":"',
          palette[9],
          '"},{"trait_type":"Dog Speed X","value":',
          Strings.toString(ds1),
          '},{"trait_type":"Dog Speed Y","value":',
          Strings.toString(ds2),
          '},{"trait_type":"Resurrection","value":"',
          resurrection,
          '"}',
          rescue,
          "]}"
        )
      );
  }

  function tokenURI(
    uint256 _tokenId,
    Mode mode,
    uint256 resDate
  ) external view returns (string memory) {
    string memory json = Base64.encode(
      bytes(getMetaData(_tokenId, mode, resDate))
    );
    return string(abi.encodePacked("data:application/json;base64,", json));
  }
}

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

library Strings {
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
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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