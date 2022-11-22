// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Controllable} from "./abstract/Controllable.sol";
import {IRoyalties} from "./interfaces/IRoyalties.sol";
import {IControllable} from "./interfaces/IControllable.sol";
import {TokenData, TokenType} from "./structs/TokenData.sol";
import {RaiseData, TierType} from "./structs/RaiseData.sol";
import {RaiseToken} from "./libraries/RaiseToken.sol";

uint256 constant BPS_DENOMINATOR = 10_000;

/// @title Royalties - Royalty registry
/// @notice Calculates ERC-2981 token royalties.
contract Royalties is IRoyalties, Controllable {
    using RaiseToken for uint256;

    string public constant NAME = "Royalties";
    string public constant VERSION = "0.0.1";

    address public receiver;

    constructor(address _controller, address _receiver) Controllable(_controller) {
        if (_receiver == address(0)) revert ZeroAddress();
        receiver = _receiver;
    }

    /// @inheritdoc IRoyalties
    function royaltyInfo(uint256 tokenId, uint256 salePrice) public view override returns (address, uint256) {
        uint256 feeBps;

        (TokenData memory token, RaiseData memory raise) = tokenId.decode();
        if (token.tokenType == TokenType.Raise) {
            if (raise.tierType == TierType.Fan) {
                feeBps = 150;
            }
            if (raise.tierType == TierType.Brand) {
                feeBps = 1000;
            }
        }
        uint256 royalty = (feeBps * salePrice) / BPS_DENOMINATOR;
        return (receiver, royalty);
    }

    /// @inheritdoc IControllable
    function setDependency(bytes32 _name, address _contract)
        external
        override (Controllable, IControllable)
        onlyController
    {
        if (_contract == address(0)) revert ZeroAddress();
        else if (_name == "receiver") _setReceiver(_contract);
    }

    function _setReceiver(address _receiver) internal {
        emit SetReceiver(receiver, _receiver);
        receiver = _receiver;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IControllable} from "../interfaces/IControllable.sol";

/// @title Controllable - Controller management functions
/// @notice An abstract base contract for contracts managed by the Controller.
abstract contract Controllable is IControllable {
    address public controller;

    modifier onlyController() {
        if (msg.sender != controller) {
            revert Forbidden();
        }
        _;
    }

    constructor(address _controller) {
        if (_controller == address(0)) {
            revert ZeroAddress();
        }
        controller = _controller;
    }

    /// @inheritdoc IControllable
    function setDependency(bytes32 _name, address) external virtual onlyController {
        revert InvalidDependency(_name);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

uint256 constant ONE_BYTE = 0x8;
uint256 constant ONE_BYTE_MASK = type(uint8).max;

uint256 constant FOUR_BYTES = 0x20;
uint256 constant FOUR_BYTE_MASK = type(uint32).max;

uint256 constant THIRTY_BYTES = 0xf0;
uint256 constant THIRTY_BYTE_MASK = type(uint240).max;

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IAnnotated {
    /// @notice Get contract name.
    /// @return Contract name.
    function NAME() external returns (string memory);

    /// @notice Get contract version.
    /// @return Contract version.
    function VERSION() external returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICommonErrors {
    /// @notice The provided address is the zero address.
    error ZeroAddress();
    /// @notice The attempted action is not allowed.
    error Forbidden();
    /// @notice The requested entity cannot be found.
    error NotFound();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ICommonErrors} from "./ICommonErrors.sol";

interface IControllable is ICommonErrors {
    /// @notice The dependency with the given `name` is invalid.
    error InvalidDependency(bytes32 name);

    /// @notice Get controller address.
    /// @return Controller address.
    function controller() external returns (address);

    /// @notice Set a named dependency to the given contract address.
    /// @param _name bytes32 name of the dependency to set.
    /// @param _contract address of the dependency.
    function setDependency(bytes32 _name, address _contract) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IAnnotated} from "./IAnnotated.sol";
import {IControllable} from "./IControllable.sol";

interface IRoyalties is IControllable, IAnnotated {
    event SetReceiver(address oldReceiver, address newReceiver);

    /// @notice Returns how much royalty is owed and to whom, based on a sale
    /// price that may be denominated in any unit of exchange. The royalty
    /// amount is denominated and should be paid in the same unit of exchange.
    /// @param tokenId uint256 Token ID.
    /// @param salePrice uint256 Sale price (in any unit of exchange).[]
    /// @return receiver address of royalty recipient.
    /// @return royaltyAmount amount of royalty.
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {TokenCodec} from "./codecs/TokenCodec.sol";
import {RaiseCodec} from "./codecs/RaiseCodec.sol";
import {TokenData, TokenType} from "../structs/TokenData.sol";
import {RaiseData, TierType} from "../structs/RaiseData.sol";

//   |------------ Token data is encoded in 32 bytes ---------------|
// 0x0000000000000000000000000000000000000000000000000000000000000000
//   1 byte token type                                             tt
//   1 byte encoding version                                     vv
//   |------- Raise token data is encoded in 30 bytes ----------|
//   4 byte project ID                                   pppppppp
//   4 byte raise ID                             rrrrrrrr
//   4 byte tier ID                      tttttttt
//   1 byte tier type                  TT
//   |------- 17 empty bytes --------|

/// @title RaiseToken - Raise token encoder/decoder
/// @notice Converts numeric token IDs to TokenData/RaiseData structs.
library RaiseToken {
    function encode(TierType _tierType, uint32 _projectId, uint32 _raiseId, uint32 _tierId)
        internal
        pure
        returns (uint256)
    {
        RaiseData memory raiseData =
            RaiseData({tierType: _tierType, projectId: _projectId, raiseId: _raiseId, tierId: _tierId});
        TokenData memory tokenData =
            TokenData({tokenType: TokenType.Raise, encodingVersion: 0, data: RaiseCodec.encode(raiseData)});
        return TokenCodec.encode(tokenData);
    }

    function decode(uint256 tokenId) internal pure returns (TokenData memory, RaiseData memory) {
        TokenData memory token = TokenCodec.decode(tokenId);
        RaiseData memory raise = RaiseCodec.decode(token.data);
        return (token, raise);
    }

    function projectId(uint256 tokenId) internal pure returns (uint32) {
        (, RaiseData memory raise) = decode(tokenId);
        return raise.projectId;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {RaiseData, TierType} from "../../structs/RaiseData.sol";
import {ONE_BYTE, ONE_BYTE_MASK, FOUR_BYTES, FOUR_BYTE_MASK} from "../../constants/Codecs.sol";

// |-------- Raise token data is encoded in 30 bytes -----------|
// 0x000000000000000000000000000000000000000000000000000000000000
// 4 byte project ID                                     pppppppp
// 4 byte raise ID                               rrrrrrrr
// 4 byte tier ID                        tttttttt
// 1 byte tier type                    TT
//   ----------------------------------  17 empty bytes reserved

uint240 constant PROJECT_ID_SIZE = uint240(FOUR_BYTES);
uint240 constant RAISE_ID_SIZE = uint240(FOUR_BYTES);
uint240 constant TIER_ID_SIZE = uint240(FOUR_BYTES);
uint240 constant TIER_TYPE_SIZE = uint240(ONE_BYTE);

uint240 constant RAISE_ID_OFFSET = PROJECT_ID_SIZE;
uint240 constant TIER_ID_OFFSET = RAISE_ID_OFFSET + RAISE_ID_SIZE;
uint240 constant TIER_TYPE_OFFSET = TIER_ID_OFFSET + TIER_ID_SIZE;

uint240 constant PROJECT_ID_MASK = uint240(FOUR_BYTE_MASK);
uint240 constant RAISE_ID_MASK = uint240(FOUR_BYTE_MASK) << RAISE_ID_OFFSET;
uint240 constant TIER_ID_MASK = uint240(FOUR_BYTE_MASK) << TIER_ID_OFFSET;
uint240 constant TIER_TYPE_MASK = uint240(ONE_BYTE_MASK) << TIER_TYPE_OFFSET;

bytes17 constant RESERVED_REGION = 0x0;

/// @title RaiseCodec - Raise token encoder/decoder
/// @notice Converts between token data bytes and RaiseData struct.
library RaiseCodec {
    function encode(RaiseData memory raise) internal pure returns (bytes30) {
        bytes memory encoded =
            abi.encodePacked(RESERVED_REGION, raise.tierType, raise.tierId, raise.raiseId, raise.projectId);
        return bytes30(encoded);
    }

    function decode(bytes30 tokenData) internal pure returns (RaiseData memory) {
        uint240 bits = uint240(tokenData);

        uint32 projectId = uint32(bits & PROJECT_ID_MASK);
        uint32 raiseId = uint32((bits & RAISE_ID_MASK) >> RAISE_ID_OFFSET);
        uint32 tierId = uint32((bits & TIER_ID_MASK) >> TIER_ID_OFFSET);
        TierType tierType = TierType((bits & TIER_TYPE_MASK) >> TIER_TYPE_OFFSET);

        return RaiseData({tierType: tierType, tierId: tierId, raiseId: raiseId, projectId: projectId});
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {TokenData, TokenType} from "../../structs/TokenData.sol";
import {ONE_BYTE, ONE_BYTE_MASK, THIRTY_BYTE_MASK} from "../../constants/Codecs.sol";

//   |------------ Token data is encoded in 32 bytes ---------------|
// 0x0000000000000000000000000000000000000000000000000000000000000000
//   1 byte token type                                             tt
//   1 byte encoding version                                     vv
//   |------------------ 30 byte data region -------------------|

uint256 constant TOKEN_TYPE_SIZE = ONE_BYTE;
uint256 constant ENCODING_SIZE = ONE_BYTE;

uint256 constant ENCODING_OFFSET = TOKEN_TYPE_SIZE;
uint256 constant DATA_OFFSET = ENCODING_OFFSET + ENCODING_SIZE;

uint256 constant TOKEN_TYPE_MASK = ONE_BYTE_MASK;
uint256 constant ENCODING_VERSION_MASK = ONE_BYTE_MASK << ENCODING_OFFSET;
uint256 constant DATA_REGION_MASK = THIRTY_BYTE_MASK << DATA_OFFSET;

/// @title RaiseCodec - Token encoder/decoder
/// @notice Converts between token ID and TokenData struct.
library TokenCodec {
    function encode(TokenData memory token) internal pure returns (uint256) {
        bytes memory encoded = abi.encodePacked(token.data, token.encodingVersion, token.tokenType);
        return uint256(bytes32(encoded));
    }

    function decode(uint256 tokenId) internal pure returns (TokenData memory) {
        TokenType tokenType = TokenType(tokenId & TOKEN_TYPE_MASK);
        uint8 encodingVersion = uint8((tokenId & ENCODING_VERSION_MASK) >> ENCODING_OFFSET);
        bytes30 data = bytes30(uint240((tokenId & DATA_REGION_MASK) >> DATA_OFFSET));

        return TokenData({tokenType: tokenType, encodingVersion: encodingVersion, data: data});
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {TierType} from "./Tier.sol";

/// @param projectId Integer ID of the project associated with this raise token.
/// @param raiseId Integer ID of the raise associated with this raise token.
/// @param tierId Integer ID of the tier associated with this raise token.
/// @param tierType Enum indicating whether this is a "fan" or "brand" token.
struct RaiseData {
    uint32 projectId;
    uint32 raiseId;
    uint32 tierId;
    TierType tierType;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @notice Enum indicating whether a token is a "fan" or "brand" token. Fan
/// tokens are intended for purchase by project patrons and have a lower protocol
/// fee and royalties than brand tokens.
enum TierType {
    Fan,
    Brand
}

/// @param tierType Whether this tier is a "fan" or "brand" token.
/// @param supply Maximum token supply in this tier.
/// @param price Price per token.
/// @param limitPerAddress Maximum number of tokens that may be minted by address.
/// @param allowListRoot Merkle root of an allowlist for the presale phase.
struct TierParams {
    TierType tierType;
    uint256 supply;
    uint256 price;
    uint256 limitPerAddress;
    bytes32 allowListRoot;
}

/// @param tierType Whether this tier is a "fan" or "brand" token.
/// @param supply Maximum token supply in this tier.
/// @param price Price per token.
/// @param limitPerAddress Maximum number of tokens that may be minted by address.
/// @param allowListRoot Merkle root of an allowlist for the presale phase.
/// @param minted Total number of tokens minted in this tier.
struct Tier {
    TierType tierType;
    uint256 supply;
    uint256 price;
    uint256 limitPerAddress;
    bytes32 allowListRoot;
    uint256 minted;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @notice Enum representing token types. The V1 protocol supports only one
/// token type, "Raise," which represents a crowdfund contribution. However,
/// new token types may be added in the future.
enum TokenType {Raise}

/// @param data 30-byte data region containing encoded token data. The specific
/// format of this data depends on encoding version and token type.
/// @param encodingVersion Encoding version of this token.
/// @param tokenType Enum indicating type of this token. (e.g. Raise)
struct TokenData {
    bytes30 data;
    uint8 encodingVersion;
    TokenType tokenType;
}