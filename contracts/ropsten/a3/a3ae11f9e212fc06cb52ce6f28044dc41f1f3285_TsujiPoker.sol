// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "base64-sol/base64.sol";
import "./Renderer.sol";

/// @title TsujiPoker
/// @author Shun Kakinoki
/// @notice Contract for certifying "poker bound" nfts
/// @notice Soulbount nft code is heavily taken from Miguel's awesome Souminter contracts: https://github.com/m1guelpf/soulminter-contracts
contract TsujiPoker is Renderer {
  error NotPlayer();
  error PokerBound();
  error NotEnoughEth();
  error TsujiNotBack();

  event Transfer(address indexed from, address indexed to, uint256 indexed id);

  string public constant symbol = "TSUJI";
  string public constant name = "Tsuji Poker NFT";
  uint256 public immutable quorum = 5;

  struct player {
    uint256 rank;
    string name;
    bool voted;
  }

  mapping(address => player) public playerOf;
  mapping(uint256 => address) public ownerOf;
  mapping(address => uint256) public balanceOf;

  // shugo.eth
  address payable internal immutable shugo =
    payable(address(0xE95330D7CDcd37bf0Ad875C29e2a2871FeFa3De8));
  uint256 internal nextTokenId = 1;
  uint256 public tsujiBackVote = 0;

  constructor() payable {
    // shugo.eth
    playerOf[shugo] = player(2, "shugo.eth", false);
    // tomona.eth
    playerOf[address(0x2aF8DDAb77A7c90a38CF26F29763365D0028cfEf)] = player(
      8,
      "mona.eth",
      false
    );
    // kaki.eth
    playerOf[address(0x4fd9D0eE6D6564E80A9Ee00c0163fC952d0A45Ed)] = player(
      9,
      "kaki.eth",
      false
    );
    // kohei.eth
    playerOf[address(0x5D025814b6a21Cd6fcb4112F40f88bC823e6A9ab)] = player(
      6,
      "kohei.eth",
      false
    );
    // datz.eth
    playerOf[address(0x1F80593194F5E71087cAfF5309e85Fe68292CB63)] = player(
      3,
      "datz.eth",
      false
    );
    // eisuke.eth
    playerOf[address(0x7E989e785d0836b509B814a7898356FdeAAAE889)] = player(
      5,
      "eisuke.eth",
      false
    );
    // thomaskobayashi.eth
    playerOf[address(0xD30Fb00c2796cBAD72f6B9C410830Dc4FF05bA71)] = player(
      7,
      "thomaskobayashi.eth",
      false
    );
    // inakazu
    playerOf[address(0x5dC79C9fB20B6A81588a32589cb8Ae8f4983DfBc)] = player(
      4,
      "inakazu",
      false
    );
    // futa
    playerOf[address(0xe7236c912945C8B915c7C60b55e330b959801B45)] = player(
      10,
      "futa",
      false
    );
    // oliver
    playerOf[address(0x70B122116b50178D881e74Ec97b89c67E90b4A7c)] = player(
      1,
      "oliver-diary.eth",
      false
    );
  }

  modifier onlyIfTsujiBack() {
    if (tsujiBackVote < quorum) revert TsujiNotBack();
    _;
  }

  modifier onlyIfPlayer() {
    if (playerOf[msg.sender].rank == 0) revert NotPlayer();
    _;
  }

  function approve(address, uint256) public virtual {
    revert PokerBound();
  }

  function isApprovedForAll(address, address) public pure {
    revert PokerBound();
  }

  function getApproved(uint256) public pure {
    revert PokerBound();
  }

  function setApprovalForAll(address, bool) public virtual {
    revert PokerBound();
  }

  function transferFrom(
    address,
    address,
    uint256
  ) public virtual {
    revert PokerBound();
  }

  function safeTransferFrom(
    address,
    address,
    uint256
  ) public virtual {
    revert PokerBound();
  }

  function safeTransferFrom(
    address,
    address,
    uint256,
    bytes calldata
  ) public virtual {
    revert PokerBound();
  }

  function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
    return
      interfaceId == 0x01ffc9a7 ||
      interfaceId == 0x80ac58cd ||
      interfaceId == 0x5b5e139f;
  }

  function mint() public payable onlyIfPlayer {
    if (msg.value < 0.01 ether) revert NotEnoughEth();
    if (balanceOf[msg.sender] > 0) revert PokerBound();

    unchecked {
      balanceOf[msg.sender]++;
    }

    ownerOf[nextTokenId] = msg.sender;
    emit Transfer(address(0), msg.sender, nextTokenId++);
  }

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            bytes(
              abi.encodePacked(
                '{"name":"Tsuji Poker",',
                '"image":"data:image/svg+xml;base64,',
                Base64.encode(
                  bytes(
                    render(
                      playerOf[ownerOf[tokenId]].name,
                      playerOf[ownerOf[tokenId]].rank
                    )
                  )
                ),
                '", "description": "Tsuji Poker Night in San Francisco on 2022/05/29"}'
              )
            )
          )
        )
      );
  }

  function rankOf(address _to) public view returns (uint256) {
    return playerOf[_to].rank;
  }

  function voterClaimOf(address _to) public view returns (bool) {
    return playerOf[_to].voted;
  }

  function vote() public onlyIfPlayer {
    if (balanceOf[msg.sender] == 0) revert PokerBound();
    if (playerOf[msg.sender].voted == true) revert PokerBound();

    unchecked {
      playerOf[msg.sender].voted = true;
      tsujiBackVote++;
    }
  }

  function withdraw() public onlyIfPlayer onlyIfTsujiBack {
    shugo.transfer(address(this).balance);
  }

  fallback() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

import { ENSNameResolver } from "./libs/ENSNameResolver.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
pragma solidity ^0.8.13;

contract Renderer is ENSNameResolver {
  using Strings for uint256;

  function render(string memory _owner, uint256 _rank)
    public
    pure
    returns (string memory)
  {
    string memory rankString = Strings.toString(_rank);

    return
      string.concat(
        '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">Tsuji Poker Night</text><text x="10" y="40" class="base">Player:</text><text x="10" y="60" class="base">',
        _owner,
        '</text><text x="10" y="80" class="base">Rank:</text><text x="10" y="100" class="base">',
        rankString,
        "</text></svg>"
      );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IReverseRegistrar {
  function node(address addr) external view returns (bytes32);
}

interface IReverseResolver {
  function name(bytes32 node) external view returns (string memory);
}

contract ENSNameResolver {
  IReverseRegistrar constant registrar =
    IReverseRegistrar(0x084b1c3C81545d370f3634392De611CaaBFf8148);
  IReverseResolver constant resolver =
    IReverseResolver(0xA2C122BE93b0074270ebeE7f6b7292C7deB45047);

  function getENSName(address addr) public view returns (string memory) {
    try resolver.name(registrar.node(addr)) {
      return resolver.name(registrar.node(addr));
    } catch {
      return "";
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