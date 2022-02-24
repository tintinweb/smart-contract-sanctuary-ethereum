// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @dao: URN
/// @author: Wizard

import "./IMerge.sol";
import {Base64} from "./util/Base64.sol";

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IPMerge is IERC165 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function mint(address to) external returns (uint256);

    function burn(uint256 tokenId) external returns (bool);
}

contract Protect is IERC721Receiver {
    using Base64 for string;

    IMerge public merge;
    IPMerge public pMerge;
    uint256 public protectId;
    uint256 public mergeId;

    event Received(address from, uint256 tokenId, uint256 mass);

    constructor(address _merge, address _pmerge) {
        merge = IMerge(_merge);
        pMerge = IPMerge(_pmerge);
    }

    modifier holdsProtectedToken() {
        require(owner() == _msgSender(), "not owner of protected token");
        _;
    }

    function value() public view returns (uint256) {
        return merge.getValueOf(mergeId);
    }

    function mass() public view returns (uint256) {
        return merge.decodeMass(value());
    }

    function class() public view returns (uint256) {
        return merge.decodeClass(value());
    }

    function mergeCount() public view returns (uint256) {
        return merge.getMergeCount(value());
    }

    function tokenUri() public view returns (string memory) {
        return merge.tokenURI(mergeId);
    }

    function removeProtection(address to) public virtual holdsProtectedToken {
        uint256 _protectId = protectId;
        uint256 _mergeId = mergeId;
        protectId = 0;
        mergeId = 0;
        require(pMerge.burn(_protectId), "failed to burn wrapped merge");
        merge.transferFrom(address(this), to, _mergeId);
    }

    function owner() public view virtual returns (address) {
        return pMerge.ownerOf(protectId);
    }

    function onERC721Received(
        address _operator,
        address from,
        uint256 tokenId,
        bytes calldata _data
    ) public virtual override returns (bytes4) {
        // verify only merge tokens are sent
        require(msg.sender == address(merge), "only send merge");

        if (protectId == 0) {
            // if pmerge has not been minted, mint
            uint256 _protectId = pMerge.mint(from);
            protectId = _protectId;
        } else {
            // verify only the owner can send tokens to the contracts
            require(owner() == from, "only the owner can merge");
        }

        uint256 massSent = merge.massOf(tokenId);
        uint256 massCurrent = 0;

        if (mergeId > 0) {
            massCurrent = merge.massOf(mergeId);
        }

        if (massSent > massCurrent) {
            mergeId = tokenId;
        }

        emit Received(from, tokenId, massSent);
        return IERC721Receiver.onERC721Received.selector;
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IMerge is IERC165 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function massOf(uint256 tokenId) external view returns (uint256);

    function getValueOf(uint256 tokenId) external view returns (uint256 value);

    function decodeMass(uint256 value) external pure returns (uint256 mass);

    function decodeClass(uint256 value) external pure returns (uint256 class);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function getMergeCount(uint256 tokenId)
        external
        view
        returns (uint256 mergeCount);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    bytes internal constant TABLE_DECODE =
        hex"0000000000000000000000000000000000000000000000000000000000000000"
        hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
        hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
        hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

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
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
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
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 4 characters
                dataPtr := add(dataPtr, 4)
                let input := mload(dataPtr)

                // write 3 bytes
                let output := add(
                    add(
                        shl(
                            18,
                            and(
                                mload(add(tablePtr, and(shr(24, input), 0xFF))),
                                0xFF
                            )
                        ),
                        shl(
                            12,
                            and(
                                mload(add(tablePtr, and(shr(16, input), 0xFF))),
                                0xFF
                            )
                        )
                    ),
                    add(
                        shl(
                            6,
                            and(
                                mload(add(tablePtr, and(shr(8, input), 0xFF))),
                                0xFF
                            )
                        ),
                        and(mload(add(tablePtr, and(input, 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}