// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBTokenUriResolver.sol";
import "@jbx-protocol/juice-721-delegate/contracts/libraries/JBIpfsDecoder.sol";
import "lib/base64/base64.sol";
import "./interfaces/IDefifaDelegate.sol";
import "./interfaces/IDefifaTokenUriResolver.sol";
import "./libraries/DefifaFontImporter.sol";
import "./libraries/DefifaPercentFormatter.sol";

/**
 * @title
 *   DefifaDelegate
 * 
 *   @notice
 *   Defifa default 721 token URI resolver.
 * 
 *   @dev
 *   Adheres to -
 *   IDefifaTokenUriResolver: General interface for the methods in this contract that interact with the blockchain's state according to the protocol's rules.
 *   IJBTokenUriResolver: Interface to ensure compatibility with 721Delegates.
 */
contract DefifaTokenUriResolver is IDefifaTokenUriResolver, IJBTokenUriResolver {
    using Strings for uint256;

    //*********************************************************************//
    // -------------------- private constant properties ------------------ //
    //*********************************************************************//

    /**
     * @notice
     * The fidelity of the decimal returned in the NFT image.
     */
    uint256 private constant _IMG_DECIMAL_FIDELITY = 5;

    //*********************************************************************//
    // --------------------- private stored properties ------------------- //
    //*********************************************************************//

    /**
     * @notice
     * The names of each tier.
     * 
     * @dev _tierId The ID of the tier to get a name for.
     */
    mapping(uint256 => string) private _tierNameOf;

    //*********************************************************************//
    // --------------- public immutable stored properties ---------------- //
    //*********************************************************************//

    /**
     * @notice
     * The address of the origin 'DefifaGovernor', used to check in the init if the contract is the original or not
     */
    address public immutable override codeOrigin;

    /**
     * @notice
     * The typeface of the SVGs.
     */
    ITypeface public immutable override typeface;

    //*********************************************************************//
    // -------------------- public stored properties --------------------- //
    //*********************************************************************//

    /**
     * @notice
     * The delegate being shown.
     */
    IDefifaDelegate public override delegate;

    //*********************************************************************//
    // ------------------------- external views -------------------------- //
    //*********************************************************************//

    /**
     * @notice
     * The name of the tier with the specified ID.
     * 
     * @param _tierId The ID of the tier to get the name of.
     * 
     * @return The tier's name.
     */
    function tierNameOf(uint256 _tierId) external view override returns (string memory) {
        return _tierNameOf[_tierId];
    }

    //*********************************************************************//
    // -------------------------- constructor ---------------------------- //
    //*********************************************************************//

    constructor(ITypeface _typeface) {
        codeOrigin = address(this);
        typeface = _typeface;
    }

    //*********************************************************************//
    // ---------------------- external transactions ---------------------- //
    //*********************************************************************//

    /**
     * @notice
     * Initializes the contract.
     * 
     * @param _delegate The Defifa delegate contract that this contract is showing.
     * @param _tierNames The names of each tier.
     */
    function initialize(IDefifaDelegate _delegate, string[] memory _tierNames) public virtual override {
        // Make the original un-initializable.
        if (address(this) == codeOrigin) revert();

        // Stop re-initialization.
        if (address(delegate) != address(0)) revert();

        delegate = _delegate;

        // Keep a reference to the number of tier names.
        uint256 _numberOfTierNames = _tierNames.length;

        // Set the name for each tier.
        for (uint256 _i; _i < _numberOfTierNames;) {
            // Set the tier name.
            _tierNameOf[_i + 1] = _tierNames[_i];

            unchecked {
                ++_i;
            }
        }
    }

    /**
     * @notice
     * The metadata URI of the provided token ID.
     * 
     * @dev
     * Defer to the token's tier IPFS URI if set.
     * 
     * @param _tokenId The ID of the token to get the tier URI for.
     * 
     * @return The token URI corresponding with the tier.
     */
    function getUri(uint256 _tokenId) external view override returns (string memory) {
        // Keep a reference to the delegate.
        IDefifaDelegate _delegate = delegate;

        // Get the game ID.
        uint256 _gameId = _delegate.projectId();

        // Keep a reference to the game phase text.
        string memory _gamePhaseText;

        // Keep a reference to the rarity text;
        string memory _rarityText;

        // Keep a reference to the game's name.
        string memory _title = _delegate.name();

        // Keep a reference to the tier's name.
        string memory _team;

        // Keep a reference to the SVG parts.
        string[] memory parts = new string[](4);

        {
            // Get a reference to the tier.
            JB721Tier memory _tier = _delegate.store().tierOfTokenId(address(_delegate), _tokenId, false);

            // Set the tier's name.
            _team = _tierNameOf[_tier.id];

            // Check to see if the tier has a URI. Return it if it does.
            if (_tier.encodedIPFSUri != bytes32(0)) {
                return JBIpfsDecoder.decode(_delegate.baseURI(), _tier.encodedIPFSUri);
            }

            parts[0] = string("data:application/json;base64,");

            parts[1] = string(
                abi.encodePacked(
                    '{"name":"',
                    _team,
                    '", "id": "',
                    _tier.id.toString(),
                    '","description":"Team: ',
                    _team,
                    ", ID: ",
                    _tier.id.toString(),
                    '.","image":"data:image/svg+xml;base64,'
                )
            );

            {
                // Get a reference to the game phase.
                DefifaGamePhase _gamePhase = delegate.gamePhaseReporter().currentGamePhaseOf(_gameId);

                if (_gamePhase == DefifaGamePhase.NO_CONTEST) {
                    _gamePhaseText = "No contest. Refunds open.";
                } else if (_gamePhase == DefifaGamePhase.NO_CONTEST_INEVITABLE) {
                    _gamePhaseText = "No contest inevitable. Refunds open.";
                } else if (_gamePhase == DefifaGamePhase.COUNTDOWN) {
                    _gamePhaseText = "Minting starts soon.";
                } else if (_gamePhase == DefifaGamePhase.MINT) {
                    _gamePhaseText = "Minting and refunds are open. Game starts soon.";
                } else if (_gamePhase == DefifaGamePhase.REFUND) {
                    _gamePhaseText = "Game starting, minting closed. Last chance for refunds.";
                } else if (_gamePhase == DefifaGamePhase.SCORING && !_delegate.redemptionWeightIsSet()) {
                    _gamePhaseText = "Awaiting approved scorecard.";
                } else {
                    string memory _percentOfPot = DefifaPercentFormatter.getFormattedPercentageOfRedemptionWeight(
                        _delegate.redemptionWeightOf(_tokenId),
                        _delegate.TOTAL_REDEMPTION_WEIGHT(),
                        _IMG_DECIMAL_FIDELITY
                    );
                    
                    _gamePhaseText =
                        string(abi.encodePacked("Scorecard approved. Redeem for ~", _percentOfPot, " of pot."));
                }

                uint256 _totalMinted = _tier.initialQuantity - _tier.remainingQuantity;
                if (_gamePhase == DefifaGamePhase.MINT) {
                    _rarityText = string(abi.encodePacked(_totalMinted.toString(), " minted so far"));
                } else {
                    _rarityText = string(abi.encodePacked(_totalMinted.toString(), " in existence"));
                }
            }
        }
        parts[2] = Base64.encode(
            abi.encodePacked(
                '<svg viewBox="0 0 500 500" xmlns="http://www.w3.org/2000/svg">',
                '<style>@font-face{font-family:"Capsules-500";src:url(data:font/truetype;charset=utf-8;base64,',
                DefifaFontImporter.getSkinnyFontSource(typeface),
                ');format("opentype");}',
                '@font-face{font-family:"Capsules-700";src:url(data:font/truetype;charset=utf-8;base64,',
                DefifaFontImporter.getBeefyFontSource(typeface),
                ');format("opentype");}',
                "text{white-space:pre-wrap; width:100%; }</style>",
                '<rect width="100%" height="100%" fill="#181424"/>',
                '<text x="10" y="30" style="font-size:16px; font-family: Capsules-500; font-weight:500; fill: #c0b3f1;">GAME ID: ',
                _gameId.toString(),
                "</text>",
                '<text x="10" y="50" style="font-size:16px; font-family: Capsules-500; font-weight:500; fill: #ed017c;">',
                _gamePhaseText,
                "</text>",
                '<text x="10" y="80" style="font-size:26px; font-family: Capsules-500; font-weight:500; fill: #c0b3f1;">',
                _getSubstring(_title, 0, 30),
                "</text>",
                '<text x="10" y="115" style="font-size:26px; font-family: Capsules-500; font-weight:500; fill: #c0b3f1;">',
                _getSubstring(_title, 30, 60),
                "</text>",
                '<text x="10" y="150" style="font-size:26px; font-family: Capsules-500; font-weight:500; fill: #c0b3f1;">',
                _getSubstring(_title, 60, 90),
                "</text>",
                '<text x="10" y="230" style="font-size:80px; font-family: Capsules-700; font-weight:700; fill: #fea282;">',
                bytes(_getSubstring(_team, 20, 30)).length != 0 && bytes(_getSubstring(_team, 10, 20)).length != 0 ? _getSubstring(_team, 0, 10) : "",
                "</text>",
                '<text x="10" y="320" style="font-size:80px; font-family: Capsules-700; font-weight:700; fill: #fea282;">',
                bytes(_getSubstring(_team, 20, 30)).length != 0 ? _getSubstring(_team, 10, 20) : bytes(_getSubstring(_team, 10, 20)).length != 0 ? _getSubstring(_team, 0, 10) : "",
                "</text>",
                '<text x="10" y="410" style="font-size:80px; font-family: Capsules-700; font-weight:700; fill: #fea282;">',
                bytes(_getSubstring(_team, 20, 30)).length != 0 ? _getSubstring(_team, 20, 30) : bytes(_getSubstring(_team, 10, 20)).length != 0 ? _getSubstring(_team, 10, 20) : _getSubstring(_team, 0, 10),
                "</text>",
                '<text x="10" y="455" style="font-size:16px; font-family: Capsules-500; font-weight:500; fill: #c0b3f1;">TOKEN ID: ',
                _tokenId.toString(),
                "</text>",
                '<text x="10" y="480" style="font-size:16px; font-family: Capsules-500; font-weight:500; fill: #c0b3f1;">RARITY: ',
                _rarityText,
                "</text>",
                "</svg>"
            )
        );
        parts[3] = string('"}');
        return string.concat(parts[0], Base64.encode(abi.encodePacked(parts[1], parts[2], parts[3])));
    }

    function _getSubstring(string memory _str, uint256 _startIndex, uint256 _endIndex) internal pure returns (string memory substring) {
        bytes memory _strBytes = bytes(_str);
        _startIndex = _strBytes[_startIndex] == bytes1(0x20) ? _startIndex + 1 : _startIndex;
        if(_startIndex >= _strBytes.length) return "";
        if(_endIndex > _strBytes.length) _endIndex = _strBytes.length;
        if(_startIndex >= _endIndex) return "";
        bytes memory _result = new bytes(_endIndex-_startIndex);
        for(uint256 _i = _startIndex; _i < _endIndex;) {
            _result[_i-_startIndex] = _strBytes[_i];
            unchecked {
              ++_i;
            }
        }
        return string(_result);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
pragma solidity ^0.8.0;

interface IJBTokenUriResolver {
  function getUri(uint256 _projectId) external view returns (string memory tokenUri);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
  
  @notice
  Utilities to decode an IPFS hash.

  @dev
  This is fairly gas intensive, due to multiple nested loops, onchain 
  IPFS hash decoding is therefore not advised (storing them as a string,
  in that use-case, *might* be more efficient).

*/
library JBIpfsDecoder {
  //*********************************************************************//
  // ------------------- internal constant properties ------------------ //
  //*********************************************************************//

  /**
    @notice
    Just a kind reminder to our readers

    @dev
    Used in base58ToString
  */
  bytes internal constant _ALPHABET = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

  function decode(
    string memory _baseUri,
    bytes32 _hexString
  ) internal pure returns (string memory) {
    // Concatenate the hex string with the fixed IPFS hash part (0x12 and 0x20)
    bytes memory completeHexString = abi.encodePacked(bytes2(0x1220), _hexString);

    // Convert the hex string to a hash
    string memory ipfsHash = _toBase58(completeHexString);

    // Concatenate with the base URI
    return string(abi.encodePacked(_baseUri, ipfsHash));
  }

  /**
    @notice
    Convert a hex string to base58

    @notice 
    Written by Martin Ludfall - Licence: MIT
  */
  function _toBase58(bytes memory _source) private pure returns (string memory) {
    if (_source.length == 0) return new string(0);

    uint8[] memory digits = new uint8[](46); // hash size with the prefix

    digits[0] = 0;

    uint8 digitlength = 1;
    uint256 _sourceLength = _source.length;

    for (uint256 i; i < _sourceLength; ) {
      uint256 carry = uint8(_source[i]);

      for (uint256 j; j < digitlength; ) {
        carry += uint256(digits[j]) << 8; // mul 256
        digits[j] = uint8(carry % 58);
        carry = carry / 58;

        unchecked {
          ++j;
        }
      }

      while (carry > 0) {
        digits[digitlength] = uint8(carry % 58);
        unchecked {
          ++digitlength;
        }
        carry = carry / 58;
      }

      unchecked {
        ++i;
      }
    }
    return string(_toAlphabet(_reverse(_truncate(digits, digitlength))));
  }

  function _truncate(uint8[] memory _array, uint8 _length) private pure returns (uint8[] memory) {
    uint8[] memory output = new uint8[](_length);
    for (uint256 i; i < _length; ) {
      output[i] = _array[i];

      unchecked {
        ++i;
      }
    }
    return output;
  }

  function _reverse(uint8[] memory _input) private pure returns (uint8[] memory) {
    uint256 _inputLength = _input.length;
    uint8[] memory output = new uint8[](_inputLength);
    for (uint256 i; i < _inputLength; ) {
      unchecked {
        output[i] = _input[_input.length - 1 - i];
        ++i;
      }
    }
    return output;
  }

  function _toAlphabet(uint8[] memory _indices) private pure returns (bytes memory) {
    uint256 _indicesLength = _indices.length;
    bytes memory output = new bytes(_indicesLength);
    for (uint256 i; i < _indicesLength; ) {
      output[i] = _ALPHABET[_indices[i]];

      unchecked {
        ++i;
      }
    }
    return output;
  }
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
pragma solidity ^0.8.16;

import "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPrices.sol";
import "@jbx-protocol/juice-721-delegate/contracts/interfaces/IJB721Delegate.sol";
import "@jbx-protocol/juice-721-delegate/contracts/interfaces/IJBTiered721DelegateStore.sol";
import "@jbx-protocol/juice-721-delegate/contracts/structs/JB721TierParams.sol";
import "@jbx-protocol/juice-721-delegate/contracts/structs/JBTiered721SetTierDelegatesData.sol";
import "@jbx-protocol/juice-721-delegate/contracts/structs/JBTiered721MintReservesForTiersData.sol";
import "@jbx-protocol/juice-721-delegate/contracts/structs/JBTiered721MintForTiersData.sol";
import "@jbx-protocol/juice-721-delegate/contracts/structs/JB721PricingParams.sol";
import "./../structs/DefifaTierRedemptionWeight.sol";
import "./IDefifaGamePhaseReporter.sol";

interface IDefifaDelegate is IJB721Delegate {
    event Mint(
        uint256 indexed tokenId,
        uint256 indexed tierId,
        address indexed beneficiary,
        uint256 totalAmountContributed,
        address caller
    );

    event MintReservedToken(
        uint256 indexed tokenId, uint256 indexed tierId, address indexed beneficiary, address caller
    );

    event TierDelegateVotesChanged(
        address indexed delegate, uint256 indexed tierId, uint256 previousBalance, uint256 newBalance, address caller
    );

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    function TOTAL_REDEMPTION_WEIGHT() external view returns (uint256);

    function name() external view returns (string memory);

    function redemptionWeightOf(uint256 _tokenId) external view returns (uint256);

    function tierRedemptionWeights() external view returns (uint256[128] memory);

    function codeOrigin() external view returns (address);

    function redemptionWeightIsSet() external view returns (bool);

    function store() external view returns (IJBTiered721DelegateStore);

    function fundingCycleStore() external view returns (IJBFundingCycleStore);

    function gamePhaseReporter() external view returns (IDefifaGamePhaseReporter);

    function pricingCurrency() external view returns (uint256);

    function firstOwnerOf(uint256 _tokenId) external view returns (address);

    function baseURI() external view returns (string memory);

    function contractURI() external view returns (string memory);

    function defaultVotingDelegate() external view returns (address);

    function getTierDelegate(address _account, uint256 _tier) external view returns (address);

    function getTierVotes(address _account, uint256 _tier) external view returns (uint256);

    function getPastTierVotes(address _account, uint256 _tier, uint256 _blockNumber) external view returns (uint256);

    function getTierTotalVotes(uint256 _tier) external view returns (uint256);

    function getPastTierTotalVotes(uint256 _tier, uint256 _blockNumber) external view returns (uint256);

    function setTierDelegate(address _delegatee, uint256 _tierId) external;

    function setTierDelegates(JBTiered721SetTierDelegatesData[] memory _setTierDelegatesData) external;

    function setTierRedemptionWeights(DefifaTierRedemptionWeight[] memory _tierWeights) external;

    function mintReservesFor(JBTiered721MintReservesForTiersData[] memory _mintReservesForTiersData) external;

    function mintReservesFor(uint256 _tierId, uint256 _count) external;

    function initialize(
        uint256 _gameId,
        IJBDirectory _directory,
        string memory _name,
        string memory _symbol,
        IJBFundingCycleStore _fundingCycleStore,
        string memory _baseUri,
        IJBTokenUriResolver _tokenUriResolver,
        string memory _contractUri,
        JB721TierParams[] memory _tiers,
        uint48 _currency,
        IJBTiered721DelegateStore _store,
        JBTiered721Flags memory _flags,
        IDefifaGamePhaseReporter _gamePhaseReporter,
        address _defaultVotingDelegate
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/typeface/contracts/interfaces/ITypeface.sol";
import "./IDefifaDelegate.sol";
import "./IDefifaGamePhaseReporter.sol";

interface IDefifaTokenUriResolver {
    function codeOrigin() external view returns (address);

    function typeface() external view returns (ITypeface);

    function delegate() external view returns (IDefifaDelegate);

    function tierNameOf(uint256 _tierId) external view returns (string memory);

    function initialize(IDefifaDelegate _delegate, string[] memory _tierNames) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "lib/typeface/contracts/interfaces/ITypeface.sol";

library DefifaFontImporter {
    // @notice Gets the Base64 encoded Capsules-500.otf typeface
    /// @return The Base64 encoded font file
    function getSkinnyFontSource(ITypeface _typeface) internal view returns (bytes memory) {
        return _typeface.sourceOf(Font(500, "normal")); // Capsules font source
    }

    // @notice Gets the Base64 encoded Capsules-500.otf typeface
    /// @return The Base64 encoded font file
    function getBeefyFontSource(ITypeface _typeface) internal view returns (bytes memory) {
        return _typeface.sourceOf(Font(700, "normal")); // Capsules font source
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/Strings.sol";

library DefifaPercentFormatter {
    using Strings for uint256;

    /**
     * @notice
     * A string representation of the percent of the given value to the total redemption weight.
     * 
     * @param _value The value to convert into a percentage of the total redemption weight.
     * 
     * @return The formatted percent string.
     */
    function getFormattedPercentageOfRedemptionWeight(uint256 _value, uint256 _total, uint256 _decimalFidelity)
        internal
        pure
        returns (string memory)
    {
        uint256 quotient = (_value * _total * (10 ^ _decimalFidelity)) / _total; // Multiply to the order of _IMG_DECIMAL_FIDELITY for extra decimal place precision)
        uint256 integerPart = quotient / 10000; // Extract the integer part
        uint256 decimalPart = quotient % 10000; // Extract the decimal part

        // Concatenate the integer and decimal parts with a decimal point
        return string(
            abi.encodePacked(integerPart.toString(), ".", _formatDecimalPart(decimalPart, _decimalFidelity), "%")
        );
    }

    /**
     * @notice
     * A formatted decimal component to a number.
     * 
     * @param _value The decimal value to format.
     * 
     * @return strValue The formatted string.
     */
    function _formatDecimalPart(uint256 _value, uint256 _decimalFidelity)
        private
        pure
        returns (string memory strValue)
    {
        strValue = _value.toString();
        // Add leading zeros if necessary
        for (uint256 i = bytes(strValue).length; i < _decimalFidelity; i++) {
            strValue = string(abi.encodePacked("0", strValue));
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IJBPriceFeed.sol';

interface IJBPrices {
  event AddFeed(uint256 indexed currency, uint256 indexed base, IJBPriceFeed feed);

  function feedFor(uint256 _currency, uint256 _base) external view returns (IJBPriceFeed);

  function priceFor(
    uint256 _currency,
    uint256 _base,
    uint256 _decimals
  ) external view returns (uint256);

  function addFeedFor(
    uint256 _currency,
    uint256 _base,
    IJBPriceFeed _priceFeed
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBTokenUriResolver.sol';

interface IJB721Delegate {
  function projectId() external view returns (uint256);

  function directory() external view returns (IJBDirectory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBTokenUriResolver.sol';
import './../structs/JB721TierParams.sol';
import './../structs/JB721Tier.sol';
import './../structs/JBTiered721Flags.sol';

interface IJBTiered721DelegateStore {
  event CleanTiers(address indexed nft, address caller);

  function totalSupply(address _nft) external view returns (uint256);

  function balanceOf(address _nft, address _owner) external view returns (uint256);

  function maxTierIdOf(address _nft) external view returns (uint256);

  function tiersOf(
    address _nft,
    uint256[] calldata _categories,
    bool _includeResolvedUri,
    uint256 _startingSortIndex,
    uint256 _size
  ) external view returns (JB721Tier[] memory tiers);

  function tierOf(
    address _nft,
    uint256 _id,
    bool _includeResolvedUri
  ) external view returns (JB721Tier memory tier);

  function tierBalanceOf(
    address _nft,
    address _owner,
    uint256 _tier
  ) external view returns (uint256);

  function tierOfTokenId(
    address _nft,
    uint256 _tokenId,
    bool _includeResolvedUri
  ) external view returns (JB721Tier memory tier);

  function tierIdOfToken(uint256 _tokenId) external pure returns (uint256);

  function encodedIPFSUriOf(address _nft, uint256 _tierId) external view returns (bytes32);

  // function firstOwnerOf(address _nft, uint256 _tokenId) external view returns (address);

  function redemptionWeightOf(
    address _nft,
    uint256[] memory _tokenIds
  ) external view returns (uint256 weight);

  function totalRedemptionWeight(address _nft) external view returns (uint256 weight);

  function numberOfReservedTokensOutstandingFor(
    address _nft,
    uint256 _tierId
  ) external view returns (uint256);

  function numberOfReservesMintedFor(address _nft, uint256 _tierId) external view returns (uint256);

  function numberOfBurnedFor(address _nft, uint256 _tierId) external view returns (uint256);

  function isTierRemoved(address _nft, uint256 _tierId) external view returns (bool);

  function flagsOf(address _nft) external view returns (JBTiered721Flags memory);

  function votingUnitsOf(address _nft, address _account) external view returns (uint256 units);

  function tierVotingUnitsOf(
    address _nft,
    address _account,
    uint256 _tierId
  ) external view returns (uint256 units);

  function defaultReservedTokenBeneficiaryOf(address _nft) external view returns (address);

  function reservedTokenBeneficiaryOf(
    address _nft,
    uint256 _tierId
  ) external view returns (address);

  function tokenUriResolverOf(address _nft) external view returns (IJBTokenUriResolver);

  function encodedTierIPFSUriOf(address _nft, uint256 _tokenId) external view returns (bytes32);

  function recordAddTiers(
    JB721TierParams[] memory _tierData
  ) external returns (uint256[] memory tierIds);

  function recordMintReservesFor(
    uint256 _tierId,
    uint256 _count
  ) external returns (uint256[] memory tokenIds);

  function recordBurn(uint256[] memory _tokenIds) external;

  function recordMint(
    uint256 _amount,
    uint16[] calldata _tierIds,
    bool _isManualMint
  ) external returns (uint256[] memory tokenIds, uint256 leftoverAmount);

  function recordTransferForTier(uint256 _tierId, address _from, address _to) external;

  function recordRemoveTierIds(uint256[] memory _tierIds) external;

  function recordSetTokenUriResolver(IJBTokenUriResolver _resolver) external;

  function recordSetEncodedIPFSUriOf(uint256 _tierId, bytes32 _encodedIPFSUri) external;

  function recordFlags(JBTiered721Flags calldata _flag) external;

  function cleanTiers(address _nft) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
  @member price The minimum contribution to qualify for this tier.
  @member initialQuantity The initial `remainingAllowance` value when the tier was set.
  @member votingUnits The amount of voting significance to give this tier compared to others.
  @member reservedRate The number of minted tokens needed in the tier to allow for minting another reserved token.
  @member reservedRateBeneficiary The beneificary of the reserved tokens for this tier.
  @member encodedIPFSUri The URI to use for each token within the tier.
  @member category A category to group NFT tiers by.
  @member allowManualMint A flag indicating if the contract's owner can mint from this tier on demand.
  @member shouldUseReservedRateBeneficiaryAsDefault A flag indicating if the `reservedTokenBeneficiary` should be stored as the default beneficiary for all tiers.
  @member transfersPausable A flag indicating if transfers from this tier can be pausable. 
  @member useVotingUnits A flag indicating if the voting units override should be used over the price as the tier's voting units.
*/
struct JB721TierParams {
  uint104 price;
  uint32 initialQuantity;
  uint32 votingUnits;
  uint16 reservedRate;
  address reservedTokenBeneficiary;
  bytes32 encodedIPFSUri;
  uint24 category;
  bool allowManualMint;
  bool shouldUseReservedTokenBeneficiaryAsDefault;
  bool transfersPausable;
  bool useVotingUnits;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
  @member delegatee The account to delegate tier voting units to.
  @member tierId The ID of the tier to delegate voting units for.
*/
struct JBTiered721SetTierDelegatesData {
  address delegatee;
  uint256 tierId;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
  @member tierId The ID of the tier to mint within.
  @member count The number of reserved tokens to mint. 
*/
struct JBTiered721MintReservesForTiersData {
  uint256 tierId;
  uint256 count;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
  @member tierIds The IDs of the tier to mint within.
  @member beneficiary The beneficiary to mint for. 
*/
struct JBTiered721MintForTiersData {
  uint16[] tierIds;
  address beneficiary;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPrices.sol';
import './JB721TierParams.sol';

/**
  @member tiers The tiers to set.
  @member currency The currency that the tier contribution floors are denoted in.
  @member decimals The number of decimals included in the tier contribution floor fixed point numbers.
  @member prices A contract that exposes price feeds that can be used to resolved the value of a contributions that are sent in different currencies. Set to the zero address if payments must be made in `currency`.
*/
struct JB721PricingParams {
  JB721TierParams[] tiers;
  uint48 currency;
  uint48 decimals;
  IJBPrices prices;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @member id The tier's ID.
 *   @member redemptionWeight the weight that each token of this tier can redeem for
 */
struct DefifaTierRedemptionWeight {
    uint256 id;
    uint256 redemptionWeight;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./../enums/DefifaGamePhase.sol";

interface IDefifaGamePhaseReporter {
    function currentGamePhaseOf(uint256 _gameId) external view returns (DefifaGamePhase);
}

// SPDX-License-Identifier: MIT

/**
  @title ITypeface

  @author peri

  @notice Interface for Typeface contract
 */

pragma solidity ^0.8.8;

struct Font {
    uint256 weight;
    string style;
}

interface ITypeface {
    /// @notice Emitted when the source is set for a font.
    /// @param font The font the source has been set for.
    event SetSource(Font font);

    /// @notice Emitted when the source hash is set for a font.
    /// @param font The font the source hash has been set for.
    /// @param sourceHash The source hash that was set.
    event SetSourceHash(Font font, bytes32 sourceHash);

    /// @notice Emitted when the donation address is set.
    /// @param donationAddress New donation address.
    event SetDonationAddress(address donationAddress);

    /// @notice Returns the typeface name.
    function name() external view returns (string memory);

    /// @notice Check if typeface includes a glyph for a specific character code point.
    /// @dev 3 bytes supports all possible unicodes.
    /// @param codePoint Character code point.
    /// @return true True if supported.
    function supportsCodePoint(bytes3 codePoint) external view returns (bool);

    /// @notice Return source data of Font.
    /// @param font Font to return source data for.
    /// @return source Source data of font.
    function sourceOf(Font memory font) external view returns (bytes memory);

    /// @notice Checks if source data has been stored for font.
    /// @param font Font to check if source data exists for.
    /// @return true True if source exists.
    function hasSource(Font memory font) external view returns (bool);

    /// @notice Stores source data for a font.
    /// @param font Font to store source data for.
    /// @param source Source data of font.
    function setSource(Font memory font, bytes memory source) external;

    /// @notice Sets a new donation address.
    /// @param donationAddress New donation address.
    function setDonationAddress(address donationAddress) external;

    /// @notice Returns donation address
    /// @return donationAddress Donation address.
    function donationAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBPriceFeed {
  function currentPrice(uint256 _targetDecimals) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IJBFundingCycleStore.sol';
import './IJBPaymentTerminal.sol';
import './IJBProjects.sol';

interface IJBDirectory {
  event SetController(uint256 indexed projectId, address indexed controller, address caller);

  event AddTerminal(uint256 indexed projectId, IJBPaymentTerminal indexed terminal, address caller);

  event SetTerminals(uint256 indexed projectId, IJBPaymentTerminal[] terminals, address caller);

  event SetPrimaryTerminal(
    uint256 indexed projectId,
    address indexed token,
    IJBPaymentTerminal indexed terminal,
    address caller
  );

  event SetIsAllowedToSetFirstController(address indexed addr, bool indexed flag, address caller);

  function projects() external view returns (IJBProjects);

  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function controllerOf(uint256 _projectId) external view returns (address);

  function isAllowedToSetFirstController(address _address) external view returns (bool);

  function terminalsOf(uint256 _projectId) external view returns (IJBPaymentTerminal[] memory);

  function isTerminalOf(uint256 _projectId, IJBPaymentTerminal _terminal)
    external
    view
    returns (bool);

  function primaryTerminalOf(uint256 _projectId, address _token)
    external
    view
    returns (IJBPaymentTerminal);

  function setControllerOf(uint256 _projectId, address _controller) external;

  function setTerminalsOf(uint256 _projectId, IJBPaymentTerminal[] calldata _terminals) external;

  function setPrimaryTerminalOf(
    uint256 _projectId,
    address _token,
    IJBPaymentTerminal _terminal
  ) external;

  function setIsAllowedToSetFirstController(address _address, bool _flag) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
  @member id The tier's ID.
  @member price The price that must be paid to qualify for this tier.
  @member remainingQuantity Remaining number of tokens in this tier. Together with idCeiling this enables for consecutive, increasing token ids to be issued to contributors.
  @member initialQuantity The initial `remainingAllowance` value when the tier was set.
  @member votingUnits The amount of voting significance to give this tier compared to others.
  @member reservedRate The number of minted tokens needed in the tier to allow for minting another reserved token.
  @member reservedRateBeneficiary The beneificary of the reserved tokens for this tier.
  @member encodedIPFSUri The URI to use for each token within the tier.
  @member category A category to group NFT tiers by.
  @member allowManualMint A flag indicating if the contract's owner can mint from this tier on demand.
  @member transfersPausable A flag indicating if transfers from this tier can be pausable. 
  @member resolvedTokenUri A resolved token URI if a resolver is included for the NFT to which this tier belongs.
*/
struct JB721Tier {
  uint256 id;
  uint256 price;
  uint256 remainingQuantity;
  uint256 initialQuantity;
  uint256 votingUnits;
  uint256 reservedRate;
  address reservedTokenBeneficiary;
  bytes32 encodedIPFSUri;
  uint256 category;
  bool allowManualMint;
  bool transfersPausable;
  string resolvedUri;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
  @member lockReservedTokenChanges A flag indicating if reserved tokens can change over time by adding new tiers with a reserved rate.
  @member lockVotingUnitChanges A flag indicating if voting unit expectations can change over time by adding new tiers with voting units.
  @member lockManualMintingChanges A flag indicating if manual minting expectations can change over time by adding new tiers with manual minting.
  @member preventOverspending A flag indicating if payments sending more than the value the NFTs being minted are worth should be reverted. 
*/
struct JBTiered721Flags {
  bool lockReservedTokenChanges;
  bool lockVotingUnitChanges;
  bool lockManualMintingChanges;
  bool preventOverspending;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum DefifaGamePhase {
    COUNTDOWN,
    MINT,
    REFUND,
    SCORING,
    NO_CONTEST_INEVITABLE,
    NO_CONTEST
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../enums/JBBallotState.sol';
import './../structs/JBFundingCycle.sol';
import './../structs/JBFundingCycleData.sol';

interface IJBFundingCycleStore {
  event Configure(
    uint256 indexed configuration,
    uint256 indexed projectId,
    JBFundingCycleData data,
    uint256 metadata,
    uint256 mustStartAtOrAfter,
    address caller
  );

  event Init(uint256 indexed configuration, uint256 indexed projectId, uint256 indexed basedOn);

  function latestConfigurationOf(uint256 _projectId) external view returns (uint256);

  function get(uint256 _projectId, uint256 _configuration)
    external
    view
    returns (JBFundingCycle memory);

  function latestConfiguredOf(uint256 _projectId)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBBallotState ballotState);

  function queuedOf(uint256 _projectId) external view returns (JBFundingCycle memory fundingCycle);

  function currentOf(uint256 _projectId) external view returns (JBFundingCycle memory fundingCycle);

  function currentBallotStateOf(uint256 _projectId) external view returns (JBBallotState);

  function configureFor(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    uint256 _metadata,
    uint256 _mustStartAtOrAfter
  ) external returns (JBFundingCycle memory fundingCycle);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

interface IJBPaymentTerminal is IERC165 {
  function acceptsToken(address _token, uint256 _projectId) external view returns (bool);

  function currencyForToken(address _token) external view returns (uint256);

  function decimalsForToken(address _token) external view returns (uint256);

  // Return value must be a fixed point number with 18 decimals.
  function currentEthOverflowOf(uint256 _projectId) external view returns (uint256);

  function pay(
    uint256 _projectId,
    uint256 _amount,
    address _token,
    address _beneficiary,
    uint256 _minReturnedTokens,
    bool _preferClaimedTokens,
    string calldata _memo,
    bytes calldata _metadata
  ) external payable returns (uint256 beneficiaryTokenCount);

  function addToBalanceOf(
    uint256 _projectId,
    uint256 _amount,
    address _token,
    string calldata _memo,
    bytes calldata _metadata
  ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './../structs/JBProjectMetadata.sol';
import './IJBTokenUriResolver.sol';

interface IJBProjects is IERC721 {
  event Create(
    uint256 indexed projectId,
    address indexed owner,
    JBProjectMetadata metadata,
    address caller
  );

  event SetMetadata(uint256 indexed projectId, JBProjectMetadata metadata, address caller);

  event SetTokenUriResolver(IJBTokenUriResolver indexed resolver, address caller);

  function count() external view returns (uint256);

  function metadataContentOf(uint256 _projectId, uint256 _domain)
    external
    view
    returns (string memory);

  function tokenUriResolver() external view returns (IJBTokenUriResolver);

  function createFor(address _owner, JBProjectMetadata calldata _metadata)
    external
    returns (uint256 projectId);

  function setMetadataOf(uint256 _projectId, JBProjectMetadata calldata _metadata) external;

  function setTokenUriResolver(IJBTokenUriResolver _newResolver) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum JBBallotState {
  Active,
  Approved,
  Failed
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../interfaces/IJBFundingCycleBallot.sol';

/** 
  @member number The funding cycle number for the cycle's project. Each funding cycle has a number that is an increment of the cycle that directly preceded it. Each project's first funding cycle has a number of 1.
  @member configuration The timestamp when the parameters for this funding cycle were configured. This value will stay the same for subsequent funding cycles that roll over from an originally configured cycle.
  @member basedOn The `configuration` of the funding cycle that was active when this cycle was created.
  @member start The timestamp marking the moment from which the funding cycle is considered active. It is a unix timestamp measured in seconds.
  @member duration The number of seconds the funding cycle lasts for, after which a new funding cycle will start. A duration of 0 means that the funding cycle will stay active until the project owner explicitly issues a reconfiguration, at which point a new funding cycle will immediately start with the updated properties. If the duration is greater than 0, a project owner cannot make changes to a funding cycle's parameters while it is active – any proposed changes will apply to the subsequent cycle. If no changes are proposed, a funding cycle rolls over to another one with the same properties but new `start` timestamp and a discounted `weight`.
  @member weight A fixed point number with 18 decimals that contracts can use to base arbitrary calculations on. For example, payment terminals can use this to determine how many tokens should be minted when a payment is received.
  @member discountRate A percent by how much the `weight` of the subsequent funding cycle should be reduced, if the project owner hasn't configured the subsequent funding cycle with an explicit `weight`. If it's 0, each funding cycle will have equal weight. If the number is 90%, the next funding cycle will have a 10% smaller weight. This weight is out of `JBConstants.MAX_DISCOUNT_RATE`.
  @member ballot An address of a contract that says whether a proposed reconfiguration should be accepted or rejected. It can be used to create rules around how a project owner can change funding cycle parameters over time.
  @member metadata Extra data that can be associated with a funding cycle.
*/
struct JBFundingCycle {
  uint256 number;
  uint256 configuration;
  uint256 basedOn;
  uint256 start;
  uint256 duration;
  uint256 weight;
  uint256 discountRate;
  IJBFundingCycleBallot ballot;
  uint256 metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../interfaces/IJBFundingCycleBallot.sol';

/** 
  @member duration The number of seconds the funding cycle lasts for, after which a new funding cycle will start. A duration of 0 means that the funding cycle will stay active until the project owner explicitly issues a reconfiguration, at which point a new funding cycle will immediately start with the updated properties. If the duration is greater than 0, a project owner cannot make changes to a funding cycle's parameters while it is active – any proposed changes will apply to the subsequent cycle. If no changes are proposed, a funding cycle rolls over to another one with the same properties but new `start` timestamp and a discounted `weight`.
  @member weight A fixed point number with 18 decimals that contracts can use to base arbitrary calculations on. For example, payment terminals can use this to determine how many tokens should be minted when a payment is received.
  @member discountRate A percent by how much the `weight` of the subsequent funding cycle should be reduced, if the project owner hasn't configured the subsequent funding cycle with an explicit `weight`. If it's 0, each funding cycle will have equal weight. If the number is 90%, the next funding cycle will have a 10% smaller weight. This weight is out of `JBConstants.MAX_DISCOUNT_RATE`.
  @member ballot An address of a contract that says whether a proposed reconfiguration should be accepted or rejected. It can be used to create rules around how a project owner can change funding cycle parameters over time.
*/
struct JBFundingCycleData {
  uint256 duration;
  uint256 weight;
  uint256 discountRate;
  IJBFundingCycleBallot ballot;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
pragma solidity ^0.8.0;

/** 
  @member content The metadata content.
  @member domain The domain within which the metadata applies.
*/
struct JBProjectMetadata {
  string content;
  uint256 domain;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../enums/JBBallotState.sol';

interface IJBFundingCycleBallot is IERC165 {
  function duration() external view returns (uint256);

  function stateOf(
    uint256 _projectId,
    uint256 _configuration,
    uint256 _start
  ) external view returns (JBBallotState);
}