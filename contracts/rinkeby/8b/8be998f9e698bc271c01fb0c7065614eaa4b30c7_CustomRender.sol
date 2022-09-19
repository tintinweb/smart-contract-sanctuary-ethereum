// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import './Base64.sol';

// import 'hardhat/console.sol';

contract Html {
  function data() public pure returns (string memory) {}
}

contract CustomRender is Ownable {
  string private baseUri;
  bool public showHtml = false;
  string public randomKey;

  Html model1;
  Html model2;
  Html model3;
  Html library4;
  Html shaders5;
  Html builder6;

  function setBaseURI(string memory _baseURI) public onlyOwner {
    baseUri = _baseURI;
  }

  function setConnections(
    address _html1Address,
    address _html2Address,
    address _html3Address,
    address _html4Address,
    address _html5Address,
    address _html6Address
  ) public onlyOwner {
    model1 = Html(_html1Address);
    model2 = Html(_html2Address);
    model3 = Html(_html3Address);
    library4 = Html(_html4Address);
    shaders5 = Html(_html5Address);
    builder6 = Html(_html6Address);
  }

  ///////////////// reveal /////////////////
  function setRandom(string memory _randomKey) public onlyOwner {
    randomKey = _randomKey;
  }

  function setShowHtml(bool _html) public onlyOwner {
    showHtml = _html;
  }

  ///////////////// art /////////////////

  function htmlData(string memory seed) public view returns (string memory) {
    string memory htmlPrefix = string(
      abi.encodePacked(
        '<!doctype html><html><head><meta charset="UTF-8"/><meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1"/><meta name="viewport" content="width=device-width,minimal-ui,viewport-fit=cover,initial-scale=1,maximum-scale=1,minimum-scale=1,user-scalable=no"/><title>Tickle Beach</title><style>:root{overflow: hidden; height: 100%}body{margin: 0}</style></head><body><script defer="defer">window.seed="',
        seed,
        '";</script>'
      )
    );

    string memory html = string(
      abi.encodePacked(
        htmlPrefix,
        model1.data(),
        model2.data(),
        model3.data(),
        library4.data(),
        shaders5.data(),
        builder6.data(),
        '</body></html>'
      )
    );
    return html;
  }

  function htmlForToken(uint256 tokenId) public view returns (string memory) {
    string memory html = htmlData(
      toString(
        uint256(keccak256(abi.encodePacked(toString(tokenId), randomKey)))
      )
    );
    return html;
  }

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    string memory stringTokenId = toString(tokenId);
    string memory html = '<html not set>';

    if (showHtml == true) {
      html = htmlForToken(tokenId);
    }

    string memory imageUrl = string(
      abi.encodePacked(baseUri, '/preview/', stringTokenId, '.png')
    );

    string memory animationUrl = string(
      abi.encodePacked(baseUri, '/animation/', stringTokenId, '.html')
    );

    string memory externalUrl = string(
      abi.encodePacked(baseUri, '/gallery/', stringTokenId)
    );

    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "Tickle Beach #',
            stringTokenId,
            '", "image": "',
            imageUrl,
            '", "animation_url": "',
            animationUrl,
            '", "external_url": "',
            externalUrl,
            '", "description": "Tickle Beach loves you.',
            '", "forever3d_html": "data:text/html;base64,',
            Base64.encode(bytes(html)),
            '"}'
          )
        )
      )
    );

    return string(abi.encodePacked('data:application/json;base64,', json));
  }

  // ///////////////// utils /////////////////

  // Inspired by OraclizeAPI's implementation - MIT license
  // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
  function toString(uint256 value) internal pure returns (string memory) {
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

/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>

pragma solidity ^0.8.4;

library Base64 {
  bytes internal constant TABLE =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

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