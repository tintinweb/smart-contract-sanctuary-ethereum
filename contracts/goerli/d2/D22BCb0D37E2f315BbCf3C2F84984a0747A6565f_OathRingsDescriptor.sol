// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import { Base64 } from 'base64-sol/base64.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract OathRingsDescriptor is Ownable {
    string[2] public __attributes = ['Role', 'Access Pass'];
    string public __collectionPrefix = 'Oath Ring #';

    string public councilImage = 'ipfs://bafybeiepqjxt5oneuao7ntzg74svotk4m455zugzsicjt4w3g2p6llhzc4';
    string public guildImage = 'ipfs://bafybeiepqjxt5oneuao7ntzg74svotk4m455zugzsicjt4w3g2p6llhzc4';
    string public councilAnimationUrl = 'ipfs://bafybeiepqjxt5oneuao7ntzg74svotk4m455zugzsicjt4w3g2p6llhzc4';
    string public guildAnimationUrl = 'ipfs://bafybeiepqjxt5oneuao7ntzg74svotk4m455zugzsicjt4w3g2p6llhzc4';
    string public councilPrefix = 'Council ';
    string public councilDetails =
        'funDAOmental is improving governance and helping people form reciprocal, cooperative communities.'
        'A Council Oath Ring provides access to '
        'funDAOmental governance and its reward pool, and VIP '
        'access to the team, community, releases and drops.';
    string public guildPrefix = 'Guild ';
    string public guildDetails =
        'funDAOmental is improving governance and helping people form reciprocal, cooperative communities. '
        'A Guild Oath Ring provides access to '
        'funDAOmental governance and its reward pool.';
    struct TokenURIParams {
        string name;
        string description;
        string[2] attributes;
        string[2] attributeValues;
        string image;
        string animationUrl;
    }

    /**
     * @notice Set the councilImage IPFS image.
     * @dev Only callable by the owner.
     */
    function setCouncilImage(string memory image_) external onlyOwner {
        councilImage = image_;
    }

    /**
     * @notice Set the councilImage IPFS image.
     * @dev Only callable by the owner.
     */
    function setCouncilAnimationUrl(string memory animationUrl_) external onlyOwner {
        councilAnimationUrl = animationUrl_;
    }

    /**
     * @notice Set the Image IPFS image.
     * @dev Only callable by the owner.
     */
    function setGuildImage(string memory image_) external onlyOwner {
        guildImage = image_;
    }

    /**
     * @notice Set the annimation ipfs.
     * @dev Only callable by the owner.
     */
    function setGuildAnimationUrl(string memory animationUrl_) external onlyOwner {
        guildAnimationUrl = animationUrl_;
    }

    /**
     * @notice Set the CouncilDetails text.
     * @dev Only callable by the owner.
     */
    function setCouncilDetails(string memory details_) external onlyOwner {
        councilDetails = details_;
    }

    /**
     * @notice Set the CouncilDetails text.
     * @dev Only callable by the owner.
     */
    function setGuildDetails(string memory details_) external onlyOwner {
        guildDetails = details_;
    }

    /**
     * @notice Set the CouncilPrefix.
     * @dev Only callable by the owner.
     */
    function setCouncilPrefix(string memory prefix_) external onlyOwner {
        councilPrefix = prefix_;
    }

    /**
     * @notice Set the GuildPrefix.
     * @dev Only callable by the owner.
     */
    function setGuildPrefix(string memory prefix_) external onlyOwner {
        guildPrefix = prefix_;
    }

    /**
     * @notice Construct an ERC721 token attributes.
     */
    function _generateAttributes(TokenURIParams memory params) internal pure returns (string memory attributes) {
        string memory _attributes = '[';
        if (params.attributes.length > 0) {
            string[2] memory att = params.attributes;
            string[2] memory attVal = params.attributeValues;
            for (uint256 i = 0; i < att.length; i++) {
                if (i == 0) {
                    _attributes = string(
                        abi.encodePacked(_attributes, '{"trait_type":"', att[i], '","value":"', attVal[i], '"}')
                    );
                } else {
                    _attributes = string(
                        abi.encodePacked(_attributes, ',{"trait_type":"', att[i], '","value":"', attVal[i], '"}')
                    );
                }
            }
            _attributes = string(abi.encodePacked(_attributes, ']'));
            return _attributes;
        }
        // empty array

        return string(abi.encodePacked(_attributes, ']'));
    }

    /**
     * @notice Construct an ERC721 token URI.
     */
    function constructTokenURI(TokenURIParams memory params) public pure returns (string memory) {
        string memory attributes = _generateAttributes(params);
        // prettier-ignore
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                        '{"name":"', params.name, '"',
                        ',"description":"', params.description, '"',
                        ',"attributes":', attributes,'',
                        ',"image":"', params.image, '"',
                        ',"animation_url":"', params.animationUrl, '"}')
                    )
                )
            )
        );
    }

    /**
     * @notice Given a name, description, and seed, construct a base64 encoded data URI.
     */
    function genericDataURI(string memory tokenId, bool isCouncil) external view returns (string memory) {
        return constructTokenURI(_getTokenURIParams(tokenId, isCouncil));
    }

    /**
     * @notice Given a name, description, and seed, construct a base64 encoded data URI.
     */
    function _getTokenURIParams(string memory tokenId, bool isCouncil) internal view returns (TokenURIParams memory) {
        string memory _prefix = guildPrefix;
        string memory _details = guildDetails;
        string memory _image = guildImage;
        string memory _annimationUrl = guildAnimationUrl;
        string[2] memory _attributeValues = ['Guild', 'False'];

        // overwrite for council role
        if (isCouncil) {
            _prefix = councilPrefix;
            _details = councilDetails;
            _image = councilImage;
            _attributeValues = ['Council', 'True'];
            _annimationUrl = councilAnimationUrl;
        }

        _prefix = string(abi.encodePacked(_prefix, __collectionPrefix, tokenId));
        return
            TokenURIParams({
                name: _prefix,
                description: _details,
                attributes: __attributes,
                attributeValues: _attributeValues,
                image: _image,
                animationUrl: _annimationUrl
            });
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