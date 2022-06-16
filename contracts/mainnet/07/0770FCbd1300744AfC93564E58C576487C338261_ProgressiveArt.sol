// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IPerlinNoise {
  function noise2d(int256, int256) external view returns (int256);
}

interface IMnemonic {
  function random(uint256, uint256) external view returns (string[] memory);
}

contract ProgressiveArt is Ownable {
  IPerlinNoise perlinNoise;
  IMnemonic mnemonic;

  string private _baseExternalURI;
  string private _metaDescription;

  uint256 private constant FIX = 2**16;
  uint256 private constant SIZE = 30;

  string[4] private MIX_MODES = [
    "multiply",
    "color-dodge",
    "soft-light",
    "hard-light"
  ];
  string[11] private FREQUENCIES = [
    "0.5",
    "0.3",
    "0.1",
    "0.08",
    "0.07",
    "0.06",
    "0.05",
    "0.04",
    "0.03",
    "0.02",
    "0.01"
  ];
  string[10] private BG_COLORS = [
    "FAFAFA",
    "F5F5F5",
    "EEEEEE",
    "E0E0E0",
    "BDBDBD",
    "9E9E9E",
    "757575",
    "616161",
    "424242",
    "212121"
  ];

  constructor(
    string memory metaDescription_,
    address noiseAddress_,
    address mnemonicAddress_
  ) {
    _metaDescription = metaDescription_;
    perlinNoise = IPerlinNoise(noiseAddress_);
    mnemonic = IMnemonic(mnemonicAddress_);
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

  function getBgColor(uint256 _seed) private view returns (string memory) {
    return BG_COLORS[random(_seed, "bg") % 10];
  }

  function getTitle(uint256 _seed) public view returns (string memory) {
    string[] memory words = mnemonic.random(_seed, 2);
    return string(abi.encodePacked(words[0], " ", words[1]));
  }

  function getColors(uint256 _seed)
    private
    pure
    returns (string[10] memory colors)
  {
    string memory key = string(abi.encodePacked(_seed, "c"));
    uint256 ct = random(_seed, "ct") % 3;
    uint256 light = 30 + (random(_seed, "cl") % 40);

    uint256 primary = random(0, key) % 361;
    uint256 step = 5 + (random(_seed, "cs") % 15);

    for (uint256 i = 0; i < 10; i++) {
      if (ct == 0) {
        colors[i] = string(
          abi.encodePacked(
            "hsl(",
            Strings.toString((primary + step * i) % 361),
            ",100%,",
            Strings.toString(light),
            "%)"
          )
        );
      } else if (ct == 1) {
        colors[i] = string(
          abi.encodePacked(
            "hsl(",
            Strings.toString(random(i, key) % 361),
            ",100%,",
            Strings.toString(light),
            "%)"
          )
        );
      } else {
        colors[i] = string(
          abi.encodePacked(
            "hsl(",
            Strings.toString(primary),
            ",100%,",
            Strings.toString(10 + i * 8),
            "%)"
          )
        );
      }
    }
  }

  function merge(string[SIZE] memory arr) private pure returns (string memory) {
    string[3] memory buffers;

    for (uint256 i; i < 3; i++) {
      buffers[i] = string(
        abi.encodePacked(
          arr[i * 10],
          arr[i * 10 + 1],
          arr[i * 10 + 2],
          arr[i * 10 + 3],
          arr[i * 10 + 4],
          arr[i * 10 + 5],
          arr[i * 10 + 6],
          arr[i * 10 + 7],
          arr[i * 10 + 8],
          arr[i * 10 + 9]
        )
      );
    }

    return string(abi.encodePacked(buffers[0], buffers[1], buffers[2]));
  }

  function map(bytes32 _rand)
    private
    view
    returns (
      int256[SIZE][SIZE] memory arr,
      int256 max,
      int256 min
    )
  {
    int256 n;
    uint256 step = 150 + (uint256(_rand) % 19850);
    _rand = keccak256(abi.encodePacked(_rand));
    uint256 xPos = uint256(_rand) % FIX;
    _rand = keccak256(abi.encodePacked(_rand));
    uint256 yPos = uint256(_rand) % FIX;
    for (uint256 x = 0; x < SIZE; x++) {
      for (uint256 y = 0; y < SIZE; y++) {
        n =
          (perlinNoise.noise2d(
            int256(xPos + x * step),
            int256(yPos + y * step)
          ) * 1000) /
          65536 +
          1000;
        if (max == 0 || n > max) max = n;
        if (min == 0 || n < min) min = n;
        arr[uint256(y)][uint256(x)] = n;
      }
    }
  }

  function dot(
    string memory sx,
    string memory sy,
    uint256 z,
    settingContext memory params
  ) private pure returns (string memory) {
    if (params.dotType == 0) {
      return
        string(
          abi.encodePacked(
            "<rect x='",
            sx,
            "' y='",
            sy,
            "' class='r c",
            Strings.toString(z),
            "'/>"
          )
        );
    } else {
      return
        string(
          abi.encodePacked(
            "<circle cx='",
            sx,
            "' cy='",
            sy,
            "' class='c c",
            Strings.toString(z),
            "'/>"
          )
        );
    }
  }

  struct plotContext {
    string sy;
    uint256 px;
    uint256 py;
    uint256 z;
    string[SIZE] rows;
    string[SIZE] cols;
  }

  function dots(
    int256[SIZE][SIZE] memory arr,
    int256 max,
    int256 min,
    settingContext memory params
  ) private pure returns (string memory) {
    plotContext memory plot;

    int256 s = (max - min) / 9;
    if (s == 0) {
      s = 1;
    }

    for (uint256 y = 0; y < SIZE; y++) {
      plot.sy = Strings.toString(uint256(y * 8));
      if (params.mirrorType == 1 && 14 < y) {
        plot.py = SIZE - 1 - y;
      } else {
        plot.py = uint256(y);
      }
      for (uint256 x = 0; x < SIZE; x++) {
        if ((params.mirrorType == 1 || params.mirrorType == 2) && 14 < x) {
          plot.px = SIZE - 1 - x;
        } else {
          plot.px = uint256(x);
        }

        {
          if (
            params.frameType == 1 &&
            (plot.py == 0 ||
              plot.py == SIZE - 1 ||
              plot.px == 0 ||
              plot.px == SIZE - 1)
          ) {
            plot.z = 0;
          } else {
            plot.z = uint256((arr[plot.px][plot.py] - min) / s);
          }
          if (plot.z < 0) {
            plot.z = 0;
          }
          if (9 < plot.z) {
            plot.z = 9;
          }
        }

        plot.cols[uint256(x)] = dot(
          Strings.toString(uint256(x * 8)),
          plot.sy,
          plot.z,
          params
        );
      }

      plot.rows[uint256(y)] = merge(plot.cols);
    }
    return merge(plot.rows);
  }

  function polygon(
    uint256 x,
    uint256 y,
    bool top,
    string memory bgColor
  ) private pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          "<polygon points='0,",
          Strings.toString((y + 1) * 8),
          " ",
          Strings.toString(x * 8),
          ",",
          Strings.toString((y + 1) * 8),
          " ",
          Strings.toString(x * 8),
          ",",
          Strings.toString(y * 8),
          " 240,",
          Strings.toString(y * 8),
          top ? " 240,0 0,0" : " 240,240 0,240",
          "' fill='#",
          bgColor,
          "' />"
        )
      );
  }

  struct settingContext {
    int256[SIZE][SIZE] arr;
    int256 max;
    int256 min;
    uint256 mirrorType;
    uint256 frameType;
    uint256 noiseType;
    uint256 filterType;
    uint256 filterMode;
    uint256 filterVolume;
    uint256 frequencyX;
    uint256 frequencyY;
    uint256 dotType;
    string[10] colors;
    string dotStr;
    string bgColor;
    uint256 p;
    uint256 pp;
    uint256 endBlur;
    uint256 endBlurX;
    uint256 endBlurY;
    uint256 endSharp;
    uint256 endSharpX;
    uint256 endSharpY;
    uint256 endBlurP;
    uint256 startSharpP;
  }

  function SVG(uint256 _time, uint256 _seed)
    public
    view
    returns (string memory)
  {
    settingContext memory params;

    bytes32 _rand = keccak256(abi.encodePacked("Progressive", _seed));
    _rand = keccak256(abi.encodePacked(_rand));

    params.endBlurP = 40 + (uint256(_rand) % 30);
    params.startSharpP = 20 + (uint256(_rand) % 20);

    params.p = toRate(_time);
    params.pp = SIZE * SIZE * params.p;
    params.endBlur = params.pp / params.endBlurP;
    params.endBlurX = params.endBlur % SIZE;
    params.endBlurY = params.endBlur / SIZE;
    params.p = params.p <= params.startSharpP
      ? 0
      : params.p - params.startSharpP;
    params.pp = SIZE * SIZE * params.p;
    params.endSharp = params.pp / (100 - params.startSharpP);
    params.endSharpX = params.endSharp % SIZE;
    params.endSharpY = params.endSharp / SIZE;

    _rand = keccak256(abi.encodePacked(_rand));
    params.mirrorType = uint256(_rand) % 3;
    _rand = keccak256(abi.encodePacked(_rand));
    params.frameType = uint256(_rand) % 2;
    params.frequencyX = uint256(_rand) % 11;
    _rand = keccak256(abi.encodePacked(_rand));
    params.dotType = uint256(_rand) % 5 == 0 ? 1 : 0;
    params.frequencyY = uint256(_rand) % 11;
    _rand = keccak256(abi.encodePacked(_rand));
    params.noiseType = uint256(_rand) % 4;
    _rand = keccak256(abi.encodePacked(_rand));
    params.filterType = uint256(_rand) % 3 == 0 ? 1 : 0;
    _rand = keccak256(abi.encodePacked(_rand));
    params.filterMode = uint256(_rand) % 2;
    _rand = keccak256(abi.encodePacked(_rand));
    params.filterVolume = params.filterType == 1 ? uint256(_rand) % 500 : 0;

    (params.arr, params.max, params.min) = map(_rand);
    params.colors = getColors(_seed);
    params.bgColor = getBgColor(_seed);
    params.dotStr = dots(params.arr, params.max, params.min, params);

    string memory pallete;
    {
      pallete = string(
        abi.encodePacked(
          ".c0{fill:",
          params.colors[0],
          "}.c1{fill:",
          params.colors[1],
          "}.c2{fill:",
          params.colors[2],
          "}.c3{fill:",
          params.colors[3],
          "}.c4{fill:",
          params.colors[4],
          "}.c5{fill:",
          params.colors[5],
          "}.c6{fill:",
          params.colors[6],
          "}.c7{fill:",
          params.colors[7],
          "}.c8{fill:",
          params.colors[8],
          "}.c9{fill:",
          params.colors[9],
          "}"
        )
      );
    }

    string memory filter;
    {
      filter = string(
        abi.encodePacked(
          "<filter id='s' class='m'><feTurbulence type='",
          params.filterMode == 0 ? "fractalNoise" : "turbulence",
          "' id='turbulence' baseFrequency='",
          FREQUENCIES[params.frequencyX],
          " ",
          FREQUENCIES[params.frequencyY],
          "' numOctaves='3' result='noise' seed='",
          Strings.toString(_seed % 1000),
          "' /><feDisplacementMap id='displacement' in='SourceGraphic' in2='noise' scale='",
          Strings.toString(params.filterVolume),
          "' /></filter>",
          "<filter id='b' x='0' y='0'><feGaussianBlur in='SourceGraphic' stdDeviation='4' result='smoothed' /></filter>",
          "<filter id='n'><feTurbulence baseFrequency='0.5' result='noise'/><feColorMatrix type='saturate' values='0.10'/><feBlend in='SourceGraphic' in2='noise' mode='multiply'/></filter>"
        )
      );
    }

    return
      string(
        abi.encodePacked(
          "<svg width='720' height='720' preserveAspectRatio='xMinYMin meet' fill='none' viewBox='0 0 240 240' version='1.1' xmlns='http://www.w3.org/2000/svg'>",
          "<style>.r{width:8px;height:8px}.c{width:8px;height:8px;transform:translate(4px,4px);r:4px}.f{filter: url(#n); mix-blend-mode:",
          MIX_MODES[params.noiseType],
          "; opacity:0.5}.fn{filter: url(#s)}.g{filter: url(#b)}.m{x:0;y:0;width:100%;height:100%}",
          pallete,
          "</style>",
          "<symbol id='dots' viewBox='0 0 240 240'>",
          params.dotStr,
          "</symbol>",
          filter,
          "<clipPath id='c'>",
          polygon(params.endSharpX, params.endSharpY, true, "000000"),
          "</clipPath><rect class='m' fill='",
          params.colors[0],
          "' /><g class='g'><g class='fn'>",
          "<use href='#dots' />",
          "</g></g><g clip-path='url(#c)'><rect class='m' fill='",
          params.colors[0],
          "' /><g class='fn'>",
          "<use href='#dots' />",
          "</g><rect class='m f'/></g>",
          polygon(params.endBlurX, params.endBlurY, false, params.bgColor),
          "</svg>"
        )
      );
  }

  struct stateContext {
    uint256 tokenId;
    string svg;
    uint256 progress;
    uint256 time;
    uint256 price;
  }

  function toRate(uint256 _time) private pure returns (uint256) {
    return _time >= 1 days ? 100 : (_time * 100) / 1 days;
  }

  function setMetaDescription(string memory description) external onlyOwner {
    _metaDescription = description;
  }

  function setBaseExternalURI(string memory URI) external onlyOwner {
    _baseExternalURI = URI;
  }

  function getMetaData(
    uint256 _tokenId,
    uint256 _time,
    uint256 _seed
  ) private view returns (string memory) {
    string memory bg = getBgColor(_seed);
    string memory rate = Strings.toString(toRate(_time));
    return
      string(
        abi.encodePacked(
          '{"name":"',
          getTitle(_seed),
          '","description":"',
          _metaDescription,
          '","image":"data:image/svg+xml;utf8,',
          SVG(_time, _seed),
          '","external_url":"',
          _baseExternalURI,
          Strings.toString(_tokenId),
          '","background_color":"',
          bg,
          '","attributes":[{"trait_type":"Time","value":',
          Strings.toString(_time),
          '},{"trait_type":"Progress","value":',
          rate,
          '},{"trait_type":"Background","value":"',
          bg,
          '"},{"trait_type":"Edition","value":"',
          Strings.toString(_tokenId),
          '"}]}'
        )
      );
  }

  function tokenURI(
    uint256 _tokenId,
    uint256 _time,
    uint256 _seed
  ) external view returns (string memory) {
    return
      string(
        abi.encodePacked(
          "data:application/json;utf8,",
          getMetaData(_tokenId, _time, _seed)
        )
      );
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