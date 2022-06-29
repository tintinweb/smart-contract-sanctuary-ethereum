// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@solidstate/contracts/utils/AddressUtils.sol';
import '@solidstate/contracts/utils/UintUtils.sol';
import "../1_ERC721SolidState/base/ERC721BaseInternal.sol";
import "../2_accounting/AccountingInternal.sol";
import "../3_register/RegisterInternal.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./utils/UintToFloatString.sol";

contract OnchainMetadata is ERC721BaseInternal, RegisterInternal, AccountingInternal {
    using AddressUtils for address;
    using UintUtils for uint;
    using UintToFloatString for uint;
    using ERC721BaseStorage for ERC721BaseStorage.Layout;

    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        require(ERC721BaseStorage.layout().exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        bool isContract = _ownerOf(tokenId).isContract();
        bool delegated = (_getApproved(tokenId) != address(0));

        string memory charName = _charName(tokenId);
        string memory charInfo = _charInfo(tokenId);
        string memory credit = _balanceInWei(tokenId).floatString(18, 3);

        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(abi.encodePacked(
            '{',
                '"name": "', charName, '", ',
                '"description": "', charInfo, '", ',
                '"image": "', _image(charName, credit, isContract, delegated), '"', 
            '}'
            ))
        )); 
    }

    function _image(
        string memory charName,
        string memory credit,
        bool isContract,
        bool delegated
    ) internal pure returns(string memory) {
        return string.concat(
            'data:image/svg+xml;base64,', Base64.encode(abi.encodePacked(
                '<svg width="560" height="687" xmlns="http://www.w3.org/2000/svg" fill="none"><defs><clipPath id="a"><rect id="svg_1" rx="40" height="687" width="560" fill="#fff"/></clipPath><clipPath id="e"><path id="svg_2" fill="#fff" d="m170,32l58,0l0,51l-58,0l0,-51z"/></clipPath><radialGradient gradientUnits="userSpaceOnUse" gradientTransform="rotate(90 -32 312) scale(372.991)" r="1" cy="0" cx="0" id="b"><stop stop-opacity="0" stop-color="#fff" offset="0.46"/><stop stop-color="#fff" offset="1"/></radialGradient><radialGradient gradientUnits="userSpaceOnUse" gradientTransform="rotate(90 -32 311.5) scale(603.5)" r="1" cy="0" cx="0" id="c"><stop stop-opacity="0" stop-color="#fff" offset="0.46"/><stop stop-color="#fff" offset="1"/></radialGradient><filter height="200%" width="200%" y="-50%" x="-50%" id="svg_18_blur"><feGaussianBlur stdDeviation="4.9" in="SourceGraphic"/></filter></defs><g><title>Layer 1</title><g id="svg_3" clip-path="url(#a)"><rect id="svg_4" rx="40" height="687" width="560" fill="#8247E5"/><g id="svg_5" opacity="0.1" fill-opacity="0.44"><circle id="svg_6" r="372.99" cy="343.99" cx="279.99" fill="url(#b)"/><circle id="svg_7" r="603.5" cy="343.5" cx="279.5" fill="url(#c)"/></g><path id="svg_9" fill="#000" d="m0,0l560,0l0,116l-560,0l0,-116z"/><g id="svg_10" clip-path="url(#e)"><path id="svg_11" fill="#8247E5" d="m213.8,47.53a3.82,3.82 0 0 0 -3.62,0l-8.46,5.02l-5.74,3.2l-8.3,5.02a3.83,3.83 0 0 1 -3.63,0l-6.5,-3.96a3.72,3.72 0 0 1 -1.81,-3.2l0,-7.61c0,-1.25 0.6,-2.47 1.8,-3.2l6.5,-3.8c1.06,-0.6 2.42,-0.6 3.63,0l6.5,3.97a3.72,3.72 0 0 1 1.8,3.2l0,5.02l5.75,-3.35l0,-5.17c0,-1.22 -0.6,-2.44 -1.81,-3.2l-12.09,-7.16a3.82,3.82 0 0 0 -3.62,0l-12.39,7.3a3.35,3.35 0 0 0 -1.8,3.06l0,14.3c0,1.23 0.6,2.44 1.8,3.2l12.24,7.16c1.05,0.6 2.41,0.6 3.62,0l8.3,-4.87l5.75,-3.35l8.3,-4.87a3.83,3.83 0 0 1 3.63,0l6.5,3.8a3.72,3.72 0 0 1 1.8,3.2l0,7.6c0,1.23 -0.6,2.45 -1.8,3.2l-6.35,3.8a3.8,3.8 0 0 1 -3.62,0l-6.5,-3.8a3.72,3.72 0 0 1 -1.8,-3.2l0,-4.86l-5.75,3.35l0,5.02c0,1.22 0.6,2.44 1.81,3.2l12.24,7.16c1.05,0.6 2.41,0.6 3.62,0l12.24,-7.16a3.72,3.72 0 0 0 1.8,-3.2l0,-14.47c0,-1.22 -0.6,-2.44 -1.8,-3.2l-12.24,-7.15z"/></g><path id="svg_12" fill="#000" d="m0,572l560,0l0,115l-560,0l0,-115z"/></g><ellipse filter="url(#svg_18_blur)" stroke="null" opacity="0.31" ry="37.34304" rx="367.10096" id="svg_18" cy="497.66758" cx="305.95017" stroke-width="0" fill="#9569e0"/><text id="svg_14" text-anchor="start" font-weight="bold" font-size="48" font-family="Lexend" stroke-width="0" y="238.5" x="65.4" xml:space="preserve"',
                isContract ? ' fill="#ee3030">' : ' fill="#333">',
                charName,
                '</text><text transform="matrix(1.45223 0 0 1.45223 -229.949 -118.83)" stroke="null" id="svg_15" text-anchor="start" font-size="16" font-family="Lexend" stroke-width="0" y="278.63839" x="451.43951" fill="#333" xml:space="preserve">',
                delegated ? 'delegated' :'@polygon',
                '</text><text id="svg_16" text-anchor="start" font-size="24" font-family="Lexend" stroke-width="0" y="632.5" x="80.88" fill="#5e5e5e" xml:space="preserve">',
                credit,
                '</text><text id="svg_17" text-anchor="start" font-weight="bold" font-size="40" font-family="Lexend" stroke-width="0" y="71.5" x="240" fill="#fff" xml:space="preserve">',
                'Character Card',
                '</text></g></svg>'
            ))
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        require(success, 'AddressUtils: failed to send value');
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            'AddressUtils: insufficient balance for call'
        );
        return _functionCallWithValue(target, data, value, error);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        require(
            isContract(target),
            'AddressUtils: function call to non-contract'
        );

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        require(value == 0, 'UintUtils: hex length insufficient');

        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AddressUtils } from '@solidstate/contracts/utils/AddressUtils.sol';
import { EnumerableMap } from '@solidstate/contracts/utils/EnumerableMap.sol';
import { EnumerableSet } from '@solidstate/contracts/utils/EnumerableSet.sol';
import { IERC721Internal } from '../IERC721Internal.sol';
import { IERC721Receiver } from '../IERC721Receiver.sol';
import { ERC721BaseStorage } from './ERC721BaseStorage.sol';

/**
 * @title Base ERC721 internal functions
 */
abstract contract ERC721BaseInternal is IERC721Internal {
    using ERC721BaseStorage for ERC721BaseStorage.Layout;
    using AddressUtils for address;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using EnumerableSet for EnumerableSet.UintSet;

    function _balanceOf(address account) internal view returns (uint256) {
        require(
            account != address(0),
            'ERC721: balance query for the zero address'
        );
        return ERC721BaseStorage.layout().holderTokens[account].length();
    }

    function _ownerOf(uint256 tokenId) internal view returns (address) {
        address owner = ERC721BaseStorage.layout().tokenOwners.get(tokenId);
        require(owner != address(0), 'ERC721: invalid owner');
        return owner;
    }

    function _getApproved(uint256 tokenId) internal view returns (address) {
        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();

        require(
            l.exists(tokenId),
            'ERC721: approved query for nonexistent token'
        );

        return l.tokenApprovals[tokenId];
    }

    function _isApprovedForAll(address account, address operator)
        internal
        view
        returns (bool)
    {
        return ERC721BaseStorage.layout().operatorApprovals[account][operator];
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        require(
            ERC721BaseStorage.layout().exists(tokenId),
            'ERC721: query for nonexistent token'
        );

        address owner = _ownerOf(tokenId);

        return (spender == owner ||
            _getApproved(tokenId) == spender ||
            _isApprovedForAll(owner, spender));
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), 'ERC721: mint to the zero address');

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();

        require(!l.exists(tokenId), 'ERC721: token already minted');

        _beforeTokenTransfer(address(0), to, tokenId);

        l.holderTokens[to].add(tokenId);
        l.tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, '');
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            'ERC721: transfer to non ERC721Receiver implementer'
        );
    }

    function _burn(uint256 tokenId) internal {
        address owner = _ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        _approve(address(0), tokenId);

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();
        l.holderTokens[owner].remove(tokenId);
        l.tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(
            _ownerOf(tokenId) == from,
            'ERC721: transfer of token that is not own'
        );
        require(to != address(0), 'ERC721: transfer to the zero address');

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();
        l.holderTokens[from].remove(tokenId);
        l.holderTokens[to].add(tokenId);
        l.tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            'ERC721: transfer to non ERC721Receiver implementer'
        );
    }

    function _approve(address operator, uint256 tokenId) internal {
        ERC721BaseStorage.layout().tokenApprovals[tokenId] = operator;
        emit Approval(_ownerOf(tokenId), operator, tokenId);
    }

    function _setApprovalForAll(address holder, address operator, bool status) internal {
        require(operator != holder, 'ERC721: approve to caller');
        ERC721BaseStorage.layout().operatorApprovals[holder][
            operator
        ] = status;
        emit ApprovalForAll(holder, operator, status);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }

        bytes memory returnData = to.functionCall(
            abi.encodeWithSelector(
                IERC721Receiver(to).onERC721Received.selector,
                msg.sender,
                from,
                tokenId,
                data
            ),
            'ERC721: transfer to non ERC721Receiver implementer'
        );

        bytes4 returnValue = abi.decode(returnData, (bytes4));
        return returnValue == type(IERC721Receiver).interfaceId;
    }

    /**
     * @notice ERC721 hook, called before externally called approvals for processing of included message value
     * @param operator beneficiary of approval
     * @param tokenId id of transferred token
     * @param value message value
     */
    function _handleApproveMessageValue(
        address operator,
        uint256 tokenId,
        uint256 value
    ) internal virtual {}

    /**
     * @notice ERC721 hook, called before externally called transfers for processing of included message value
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId id of transferred token
     * @param value message value
     */
    function _handleTransferMessageValue(
        address from,
        address to,
        uint256 tokenId,
        uint256 value
    ) internal virtual {}

    /**
     * @notice ERC721 hook, called before all transfers including mint and burn
     * @dev function should be overridden and new implementation must call super
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId id of transferred token
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./AccountingSafeStorage.sol";

abstract contract AccountingInternal {
    using AccountingSafeStorage for AccountingSafeStorage.Layout;

    event TransferBalance(uint256 fromAccountId, uint256 toAccountId, uint256 amount, string memo);
    event Deposit(address from, uint256 toAccountId, uint256 amount, string memo);
    event Withdraw(uint256 fromAccountId, address to, uint256 amount, string memo);

    function _balanceInWei(uint256 accountId) internal view returns(uint256) {
        return AccountingSafeStorage.layout().credit(accountId);
    }

    function _deposit(
        address from,
        uint256 toAccountId,
        uint256 amount,
        string memory memo
    ) internal {
        AccountingSafeStorage.layout().add(toAccountId, amount);
        emit Deposit(from, toAccountId,  amount, memo);
    }

    function _withdraw(
        uint256 fromAccountId,
        address payable to,
        uint256 amount,
        string memory memo
    ) internal {
        AccountingSafeStorage.layout().sub(fromAccountId, amount);
        to.transfer(amount);
        emit Withdraw(fromAccountId, to, amount, memo);
    }

    function _transferBalance(
        uint256 fromAccountId,
        uint256 toAccountId,
        uint256 amount,
        string memory memo
    ) internal {
        AccountingSafeStorage.layout().sub(fromAccountId, amount);
        AccountingSafeStorage.layout().add(toAccountId, amount);
        emit TransferBalance(fromAccountId, toAccountId, amount, memo);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./RegisterStorage.sol";
import "./utils/StringToUint256Hash.sol";
import "./utils/LiteralRegex.sol";

abstract contract RegisterInternal {
    using RegisterStorage for RegisterStorage.Layout;
    using StringToUint256Hash for string;
    using LiteralRegex for string;


    event AssignCharName(uint256 _Id, string _username);

    function _charId(string memory charName_) internal pure returns(uint256) {
        return charName_.uint256Hash();
    }

    function _charName(uint256 charId_) internal view returns(string memory) {
        return RegisterStorage.layout().charNames[charId_];
    }

    function _refId(uint256 charId_) internal view returns(uint256) {
        return RegisterStorage.layout().referrals[charId_];
    }

    function _charInfo(uint256 charId_) internal view returns(string memory) {
       return RegisterStorage.layout().charInfos[charId_]; 
    }


    /**
     * @dev assigns a username to an Id if it is correct.
     */
    function _assignCharName(
        uint256 charId_,
        string memory charName_
    ) internal {
        require(bytes(charName_).length > 0, "empty charName");
        require(
            charName_.isLiteral(),
            "you can just use numbers(0-9) letters(a-zA-Z) and signs(-._)"
        );
        if(
            ! RegisterStorage.layout().assigned(charId_)
        ) {
            RegisterStorage.layout().charNames[charId_] = charName_;
            emit AssignCharName(charId_, charName_);
        }
    }

    function _setCharInfo(
        uint256 charId_,
        string memory charInfo_
    ) internal {
        RegisterStorage.layout().charInfos[charId_] = charInfo_;
    }

    function _setReferral(uint256 charId_, uint256 refId_) internal {
        if(refId_ != 0 && RegisterStorage.layout().referrals[charId_] == 0) {
            RegisterStorage.layout().referrals[charId_] = refId_;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@solidstate/contracts/utils/UintUtils.sol';

/**
 * @author https://www.linkedin.com/in/renope/
 */
library UintToFloatString {
    using UintUtils for uint;

    function floatString(
        uint256 number, 
        uint8 inDecimals,
        uint8 outDecimals
    ) internal pure returns(string memory h) {
        h = string.concat(
            (number / 10 ** inDecimals).toString(),
            outDecimals > 0 ? '.': ''
        );
        while(outDecimals > 0){
            h = string.concat(
                h,
                inDecimals > 0 ?
                (number % 10 ** (inDecimals--) / 10 ** (inDecimals-1)).toString()
                : '0'
            );
            outDecimals--;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Map implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableMap {
    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        MapEntry[] _entries;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct AddressToAddressMap {
        Map _inner;
    }

    struct UintToAddressMap {
        Map _inner;
    }

    function at(AddressToAddressMap storage map, uint256 index)
        internal
        view
        returns (address, address)
    {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        address addressKey;
        assembly {
            addressKey := mload(add(key, 20))
        }
        return (addressKey, address(uint160(uint256(value))));
    }

    function at(UintToAddressMap storage map, uint256 index)
        internal
        view
        returns (uint256, address)
    {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    function contains(AddressToAddressMap storage map, address key)
        internal
        view
        returns (bool)
    {
        return _contains(map._inner, bytes32(uint256(uint160(key))));
    }

    function contains(UintToAddressMap storage map, uint256 key)
        internal
        view
        returns (bool)
    {
        return _contains(map._inner, bytes32(key));
    }

    function length(AddressToAddressMap storage map)
        internal
        view
        returns (uint256)
    {
        return _length(map._inner);
    }

    function length(UintToAddressMap storage map)
        internal
        view
        returns (uint256)
    {
        return _length(map._inner);
    }

    function get(AddressToAddressMap storage map, address key)
        internal
        view
        returns (address)
    {
        return
            address(
                uint160(
                    uint256(_get(map._inner, bytes32(uint256(uint160(key)))))
                )
            );
    }

    function get(UintToAddressMap storage map, uint256 key)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    function set(
        AddressToAddressMap storage map,
        address key,
        address value
    ) internal returns (bool) {
        return
            _set(
                map._inner,
                bytes32(uint256(uint160(key))),
                bytes32(uint256(uint160(value)))
            );
    }

    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    function remove(AddressToAddressMap storage map, address key)
        internal
        returns (bool)
    {
        return _remove(map._inner, bytes32(uint256(uint160(key))));
    }

    function remove(UintToAddressMap storage map, uint256 key)
        internal
        returns (bool)
    {
        return _remove(map._inner, bytes32(key));
    }

    function _at(Map storage map, uint256 index)
        private
        view
        returns (bytes32, bytes32)
    {
        require(
            map._entries.length > index,
            'EnumerableMap: index out of bounds'
        );

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    function _contains(Map storage map, bytes32 key)
        private
        view
        returns (bool)
    {
        return map._indexes[key] != 0;
    }

    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, 'EnumerableMap: nonexistent key');
        unchecked {
            return map._entries[keyIndex - 1]._value;
        }
    }

    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) {
            map._entries.push(MapEntry({ _key: key, _value: value }));
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            unchecked {
                map._entries[keyIndex - 1]._value = value;
            }
            return false;
        }
    }

    function _remove(Map storage map, bytes32 key) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) {
            unchecked {
                MapEntry storage last = map._entries[map._entries.length - 1];

                // move last entry to now-vacant index
                map._entries[keyIndex - 1] = last;
                map._indexes[last._key] = keyIndex;
            }

            // clear last index
            map._entries.pop();
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, value);
    }

    function indexOf(AddressSet storage set, address value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(UintSet storage set, uint256 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            'EnumerableSet: index out of bounds'
        );
        return set._values[index];
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _indexOf(Set storage set, bytes32 value)
        private
        view
        returns (uint256)
    {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            unchecked {
                bytes32 last = set._values[set._values.length - 1];

                // move last value to now-vacant index

                set._values[valueIndex - 1] = last;
                set._indexes[last] = valueIndex;
            }
            // clear last index

            set._values.pop();
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial ERC721 interface needed by internal functions
 */
interface IERC721Internal {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed operator,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableMap } from '@solidstate/contracts/utils/EnumerableMap.sol';
import { EnumerableSet } from '@solidstate/contracts/utils/EnumerableSet.sol';

library ERC721BaseStorage {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC721Base');

    struct Layout {
        EnumerableMap.UintToAddressMap tokenOwners;
        mapping(address => EnumerableSet.UintSet) holderTokens;
        mapping(uint256 => address) tokenApprovals;
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function exists(Layout storage l, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        return l.tokenOwners.contains(tokenId);
    }

    function totalSupply(Layout storage l) internal view returns (uint256) {
        return l.tokenOwners.length();
    }

    function tokenOfOwnerByIndex(
        Layout storage l,
        address owner,
        uint256 index
    ) internal view returns (uint256) {
        return l.holderTokens[owner].at(index);
    }

    function tokenByIndex(Layout storage l, uint256 index)
        internal
        view
        returns (uint256)
    {
        (uint256 tokenId, ) = l.tokenOwners.at(index);
        return tokenId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


library AccountingSafeStorage {

    bytes32 constant ACCOUNTING_SAFE_STORAGE_POSITION = keccak256("ACCOUNTING_SAFE_STORAGE_POSITION");

    struct Account {
        uint256 _credit; // default: 0
    }

    struct Layout {
        mapping(uint256 => Account) accounts;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = ACCOUNTING_SAFE_STORAGE_POSITION;
        assembly {
            l.slot := slot
        }
    }


    function credit(Layout storage l, uint256 accountId) internal view returns(uint256) {
        return l.accounts[accountId]._credit;
    }

    function add(Layout storage l, uint256 accountId, uint256 amount) internal {
        unchecked{
            l.accounts[accountId]._credit += amount;
        }
    }

    function sub(Layout storage l, uint256 accountId, uint256 amount) internal {
        assert(amount <= l.accounts[accountId]._credit);
        unchecked{
            l.accounts[accountId]._credit -= amount;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


library RegisterStorage {

    bytes32 constant REGISTER_STORAGE_POSITION = keccak256("REGISTER_STORAGE_POSITION");

    struct Layout {
        mapping(uint256 => string) charNames;
        mapping(uint256 => string) charInfos;
        mapping(uint256 => uint256) referrals;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = REGISTER_STORAGE_POSITION;
        assembly {
            l.slot := slot
        }
    }

    function assigned(Layout storage l, uint256 charId_)
        internal
        view
        returns (bool)
    {
        return bytes(l.charNames[charId_]).length != 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


library StringToUint256Hash {

    /**
     * StringToUint256Hash
     * 
     * Converts a string to its corresponding uint256 hash.
     * not case sensetive.
     *
     * @return uint256 
     */
    function uint256Hash(string memory input)
        internal
        pure
        returns(uint256)
    {
        return uint256(keccak256(abi.encodePacked(lower(input))));
    }

    /**
     * Lower
     * 
     * Converts all the values of a string to their corresponding lower case
     * value.
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to lower case
     * @return string 
     */
    function lower(string memory _base)
        internal
        pure
        returns (string memory) 
    {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _lower(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Lower
     * 
     * Convert an alphabetic character to lower case and return the original
     * value when not alphabetic
     * 
     * @param _b1 The byte to be converted to lower case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a upper case otherwise returns the original value
     */
    function _lower(bytes1 _b1)
        private
        pure
        returns (bytes1) 
    {
        if (_b1 >= 0x41 && _b1 <= 0x5A) {
            return bytes1(uint8(_b1) + 32);
        }

        return _b1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library LiteralRegex {

    string constant regex = "[a-zA-Z0-9-._]";

    function isLiteral(string memory text) internal pure returns(bool) {
        bytes memory t = bytes(text);
        for (uint i = 0; i < t.length; i++) {
            if(!_isLiteral(t[i])) {return false;}
        }
        return true;
    }

    function _isLiteral(bytes1 char) private pure returns(bool status) {
        if (  
            char >= 0x30 && char <= 0x39 // `0-9`
            ||
            char >= 0x41 && char <= 0x5a // `A-Z`
            ||
            char >= 0x61 && char <= 0x7a // `a-z`
            ||
            char == 0x2d                 // `-`
            ||
            char == 0x2e                 // `.`
            ||
            char == 0x5f                 // `_`
        ) {
            status = true;
        }
    }
}