// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.10;

import { Owned } from  "solmate/auth/Owned.sol";
import { IAuthoriser, IRulesEngine } from "./IAuthoriser.sol";
import { BlobParser } from "./lib/BlobParser.sol";

interface IERC721 {
  function ownerOf(uint256 id) external view returns (address owner);
}

contract NftAuthoriser is IAuthoriser, IRulesEngine, Owned(msg.sender) {
  IERC721 public nft;

  mapping(string => uint256) public labelTokenId;

  constructor (address _nft) {
    nft = IERC721(_nft);
  }

  function canRegister (bytes32 _node, address _user, bytes[] memory blob) external view returns (bool) {
    require(blob.length == 1, "Only tokenId is required");

    uint256 tokenId = BlobParser.bytesToUint256(blob[0], 0);
    return nft.ownerOf(tokenId) == _user;
  }

  function isLabelValid (string memory label) external view returns (bool isValid) {
    uint256 maxLength = 3;
    uint256 len;
    uint256 i = 0;
    uint256 bytelength = bytes(label).length;
    isValid = false;

    for(len = 0; i < bytelength; len++) {
      if (len == maxLength) {
        isValid = true;
        break;
      }

      bytes1 b = bytes(label)[i];
      if(b < 0x80) {
        i += 1;
      } else if (b < 0xE0) {
        i += 2;
      } else if (b < 0xF0) {
        i += 3;
      } else if (b < 0xF8) {
        i += 4;
      } else if (b < 0xFC) {
        i += 5;
      } else {
        i += 6;
      }
    }

    return isValid;
  }

  /*
  function forEditing (address user, string memory label) external view returns (bool) {
    uint256 tokenId = labelTokenId[label];
    require(tokenId > 0, "Invalid tokenId");

  }
 */
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.10;

interface IAuthoriser {
  // function forEditing(address, string memory) external view returns (bool);
  function canRegister(bytes32 node, address sender, bytes[] memory blob) external view returns (bool);
}

interface IRulesEngine {
  function isLabelValid (string memory) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.10;

library BlobParser {
  function bytesToUint256(bytes memory bs, uint start) internal pure returns (uint256) {
    require(bs.length >= start + 32, "Slicing out of range");

    uint256 x;
    assembly { x := mload(add(bs, add(0x20, start))) }

    return x;
  }
}