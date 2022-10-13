/**
 *Submitted for verification at Etherscan.io on 2022-10-12
*/

// SPDX-License-Identifier: GPL-3.0-or-later
// File: base64-sol/base64.sol
/**
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0kkkkkkkkkOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKko:,.. ......  ..':lkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKxo:,''',,,;;;;;;;;,,'....':d0WMMMMMMMMMMMMMWNKOkkxdooodxkOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXko:,,,;:ccccccccccccccccccc::;,';lxKXNMMMMWXOdl;,,''',,,,,,''';:lx0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOl,',;:cccccccccccccccccccc::::;;;;;,,'';oxxo:,'.',;::cccccccccccc:;,;coxKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk;..;:cccccccccc:::;,''''''.........           .;:cccccccccccccccc:::;,'.  .,lx0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk;..;:cccccccc:;,'......''',,,,,,,,'''''............',;:cccccccc:;,'....         .,cdOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc..;:ccccccc:;'...',;::cccccccccccccccccccccccc:::;,''...',::ccc:;,,,,,,,,,;;;,,,,,''',;:ldOXWMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMWk,.,:cccccc::,,,,;:ccccccccccccccccc:::;;;,,,,'',,,,,''...   ..,;:ccccccccccccccccc::;;,,..  ..;lx0NMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMXo..;cccccccc::;:ccccccccccccccc:;,''.....''''',,,,,;;;;;,,,,''.....';:ccccc::;,,'''''..............';lxKNMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMKc.':ccccccccccccccccccccccc::,'....'',;;;;;,,;;;::cllooollllc;;;;;,'....,,'....'',,,;;;;;;;;;;;;;;;;;;,,:ldkXWMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMK:.':cccccccccccccccccccc:;,''..',;::;;,,;:clodkO00KXXNNNNNNXXKkdl:....   ..',,;;,,,,,;:::cccccc::::;,''.',;;;lkNMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMWo.':ccccccccccccccccccccc:,,,;::;,,,:cox0KNWWMMMMMMMMMMMWWMMMMMMMMNKd;.  ..'';:lodxO0KXNNWWWWWWWWWWNNK0Oxoc;'...lNMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMM0,.;ccccccccccccccccccccc::;;,''';cdOXWMMMMMMMMMMMMMWKkoc::clxKWMMMMMMNO:.  .l0NWMMMMMMMMMMMMNOdlcccdONMMMMMN0d;..kWMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMx.':ccccccccccccccccc:;,,:::clox0NWMMMMMMMMMMMMMMNko:.        .cKMMMMMMMNd. ;KMMMMMMMMMMMMMWO;.      .:0WMMMMMMNx'lNMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMM0;.;cccccccccccccccccc;..oXNWWMMMMMMMMMMMMMMMMMMMKc.             ;KMMMMMMMWx..OMMMMMMMMMMMMNd.          .dNMMMMMMWd:0MMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMWk, .:cccccccccccccccccc:'.,cdOXWMMMMMMMMMMMMMMMMMX:        .,'.   .xWMMMMMMMNl.dWMMMMMMMMMMMk.            .xWMMMMMM0ckMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMXo...,:ccccccccccccccccccc::;,'.,l0WMMMMMMMMMMMMMMMx.       ;0NN0:. .dWMMMMMMMMx.cNMMMMMMMMMMWl      ,dkx:. .dWMMMMMMKcxWMMMMMMMMM
MMMMMMMMMMMMMMMMMMNk;',;::ccccccccccccccccccccccccc:,.'c0WMMMMMMMMMMMMWd.       :XMNk;  .xWMMMMMMMMx.,KMMMMMMMMMMWd.    .lKKOc. ;KMMMMMMM0;oWMMMMMMMMM
MMMMMMMMMMMMMMMMW0l;;:cccccccccccccccccccccccccccc::::;''l0WMMMMMMMMMMMO'       .;c;.   :KMMMMMMMMNl .oXMMMMMMMMMMXl.    ....  ,0WMMMMMMWx;kMMMMMMMMMM
MMMMMMMMMMMMMMMXd,,:cccccccccccccccccccccccccccccc:'.,::;',lONMMMMMMMMMWk,           .'oKMMMMMMMMWx.  .,o0NMMMMMMMMNOl,.......cKWMMMMMMM0ldNMMMMMMMMMM
MMMMMMMMMMMMMW0c';ccccccccccccccccccccccccccccccccc:,..,::;'.;oONWMMMMMMMXxoc,''',:ldOXWMMMMMMMMXd. .','',:ldOKNWMMMMWNXKK000XWMMMMMMWXx:dNMMMMMMMMMMM
MMMMMMMMMMMMM0;':cccccccccccccccccccccccccccccccccccc:,...,::,.',cdOKNWMMMMMWNNXNWWMMMMMMMMMMWKd,..  .,:c:;,'',;:cldxxkOO00KKKKKK0Oxo:..cNMMMMMMMMMMMM
MMMMMMMMMMMM0;.;ccccccccccccccccccccccccccccccccccccccc:;'..',;:;'''';:codkO0KXNNWWWWNNXX0kdl;.  .;;'...,::;,,,,,,,,,'''''''''''''''''';0MMMMMMMMMMMMM
MMMMMMMMMMMNc.,ccccccccccccccccccccccccccccccccccccccccccc:;,'''',;;:;,,'''',,;;ccllcc::;;''''..':ccc:,...';;;,,'''''''''''''',,,''';cxKWMMMMMMMMMMMMM
MMMMMMMMMMMO'.:ccccccccccccccccccccccccccccccccc:;'',::ccccccc::,''...',,;;:::::::::::::;;,'''';:cccccc:;'...,:ccc::;,,'...      .;oONWMMMMMMMMMMMMMMM
MMMMMMMMMMWo.':cccccccccccccccccccccccccccccccccc:,.....',;;::ccccc:;,''...................',:cccccccccccc;.. ..,;;::;;,''.      :KMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMWl.,cccccccccccccccccccccccccccccccccccccc:;,'.......'',,;;;;::;;,,,'..    ...,;:cccccccccccccccc:;.    ................:0WMMMMMMMMMMMMMMMMM
MMMMMMMMMMX:.;cccccccccccccccccccc::cccccccccccccccccccc:::;,,'...................',;::cccccccccccccccccccccc:,. ..',;:::::cccccc:,,dNMMMMMMMMMMMMMMMM
MMMMMMMMMMO'.:cccccccccccccccccc:,,:cccc:::cccccccccccccccccccccc:::::;;;;;;;:::ccccccccccccccccccccccccccccccc;..,:ccccccccccccccc;'c0WMMMMMMMMMMMMMM
MMMMMMMMMMk.':cccccccccccccccc:,..;cc:,'....',;::ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc:,,:cccccccccccccccc:.'dNMMMMMMMMMMMMM
MMMMMMMMMMx.'cccccccccccccccc:'.,:c:,..',,,,''...'',;::cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc, .cKWMMMMMMMMMMM
MMMMMMMMMWd.,cccccccccccccccc;,;cc:..,:::::::::;;,''....'',;::cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc:;'....:0MMMMMMMMMMM
MMMMMMMMMNl.,cccccccccccccccccccc:'.'::::::::::::::::;;,''.....'',;;::cccccccccccccccccccccccccccccccccccccccccccccccccccccccc:;,'...';:,.dWMMMMMMMMMM
MMMMMMMMMNl.;cccccccccccccccccccc:..,::::::;,,;;::::::::::::;;,''......'',,;;;::cccccccccccccccccccccccccccccccccccccc:::;,,'''..',;:::::dXMMMMMMMMMMM
MMMMMMMMMWo.;cccccccccccccccccccc:,.';:::::'. ....'',;::::::::::::::;;,,''''''''''',,,;;;::::::::::::::::::::;;;,,,'''''.''',,;:::::;;cdKWMMMMMMMMMMMM
MMMMMMMMMWo.;ccccccccccccccccccccc:,..;::::,...........'',,;;::::::::::::::::::;;,,''''''''''''''''''''''''..''''''',,;;::::::;,,',:lxKWMMMMMMMMMMMMMM
MMMMMMMMMWd.,ccccccccccccccccccccccc;'.';:::;'...',,'''........'',,;;:::::::::::::::::::::::;;;;;;;;;;;;;;;:::::::::::;;;,''....cx0XWMMMMMMMMMMMMMMMMM
MMMMMMMMMWo.,cccccccccccccccccccccccc:;..,;:::;,....'',,,,,'''.........''',,,;;;;::::::::::::::::::::::::;;;;,,''..............:KWMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMx..:ccccccccccccccccccccccccc:;'.,;::::;,....'',,,,,,,,,'''''....................................',,;;::ccc;'..,;:::;:lkXWMMMMMMMMMMMMMMMMMM
MMMMMMMMMMXl.':cccccccccccccccccccccccccc:;'.,;:::::;,.....'''''........''',,,''''''''.................. .ckOOOOO00O0Oko:'.';:::::lkNMMMMMMMMMMMMMMMMM
MMMMMMMMMMMNx,,:cc:cccccccccccccccccccccccc:;''';::::::;,'.....  ..............'',,,,,,',,,,,,,,,,,,,,''..'oO0OOOOOO0OO0Oxl'.';:::::l0WMMMMMMMMMMMMMMM
MMMMMMMMMMMMMKo,;:ccccccccccccccccccccccccccc:;,'',;:::::::;'.. .;okkkkxol:;;'.....''',,,,,,,,,,,,',,,,,'. .cO0OOOO0OOOOOO0kc..';:::,;OWMMMMMMMMMMMMMM
MMMMMMMMMMMMMMNk:,;:cccccccccccccccccccccccccccc:;''',;:::::::;,'',;coxOO00OOOxoc;......''',,',,,,,,,,,''. .:k0O0OO0OO00O000O:..,:::;.;KMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMNOoc;:cccccccccccccccccccccccccccc::,'.',;::::::::;,'.',;clodxOOOOko:'.  ....'''',,'''....'lkOOOOO00OO0OOkdo:..';:::;.;KMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMXOo:;:cccccccccccccccccccccccccccc:;'...,;:::::::::;,,'..'',;:codddo:'.   ........  .,okO0OOOOOkxdlc:;,''',;::::;';OMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMWKxc;;:cccccccccccccccccccccccccccc:;,'..',;::::::::::::;;,''.'''''..            .cdddolcc::;,,'''',;:::::::;,,oKWMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMNOo:;;:ccccccccccccccccccccccccccccc:,'...',;;:::::::::::::::;;,,,''''''''''''',;;;,,,,,;;:::::::::::;;,..c0WMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMWNOdc,,::cccccccccccccccccccccccccccc:;,'....',;::::::::::::::::::::::::::::::;;;;;;;,,''',,;;;,'.....'dNMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOo:,,;:ccccccccccccccccccccccccccccc:;,'.......',;;:::::::::::::;;,''..'',,,,;;;;,,,,;:::::,.  .lKWMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0dc;,,;:cccccccccccccccccccccccccccccc::;,,''.....''''',,'''.....',,;::cccccccccccccccc:,..;OWMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXko:,,,;:cccccccccccccccccccccccccccccccccc::;;,,''....',;;::ccccccccccccccccc::;,,'..;kNMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKxoc;,,;::ccccccccccccccccccccccccccccccccccccccc:ccccccccccccccccccc::,'....';:lkNMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOdlc;,,,;:::ccccccccccccccccccccccccccccccccccccccccccc::;;;;;,''',:ldk0XWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0xdllc:;;;,,,,;;;;;;;;;;;;;;;;;;:::::;;:;::;;;;;,,'...';:ldkKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWX000kddddolcc:::::::::::::clcc:::::::coxk000000KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM */



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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: contracts/strings.sol



/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 */

pragma solidity ^0.8.0;

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint _len) private pure {
        // Copy word-length chunks while possible
        for(; _len >= 32; _len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = type(uint).max;
        if (_len > 0) {
            mask = 256 ** (32 - _len) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (uint(self) & type(uint128).max == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (uint(self) & type(uint64).max == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (uint(self) & type(uint32).max == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (uint(self) & type(uint16).max == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (uint(self) & type(uint8).max == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-terminated utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) internal pure returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(slice memory self, slice memory other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint mask = type(uint).max; // 0xffff...
                if(shortest < 32) {
                  mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                unchecked {
                    uint diff = (a & mask) - (b & mask);
                    if (diff != 0)
                        return int(diff);
                }
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice memory self, slice memory other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
        // Load the first byte of the rune into the LSBs of b
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            l = 1;
        } else if(b < 0xE0) {
            l = 2;
        } else if(b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice memory self) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly { word:= mload(mload(add(self, 32))) }
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if(b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr)
                        return selfptr;
                    ptr--;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice memory self, slice memory needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            length += parts[i]._len;

        string memory ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(uint i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
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
        returns (string memory) {
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
        returns (bytes1) {

        if (_b1 >= 0x41 && _b1 <= 0x5A) {
            return bytes1(uint8(_b1) + 32);
        }

        return _b1;
    }
}

pragma solidity ^0.8.4;


contract PepeNameService is ERC721, Ownable, ReentrancyGuard {
  using strings for string;

  uint256 public price; // domain price
  bool public buyingEnabled; // buying domains enabled
  uint256 public referral = 1000; // share of each domain purchase (in bips) that goes to the referrer (referral fee)
  uint256 public totalSupply;
  uint256 public nameMaxLength = 100; // max length of a domain name
  string public description = "Pepe Name Service (PNS) is a cheap domain service, yours forever, 100% on-chain get yours at https://pepedomains.com/";

  struct Domain {
    string name; // domain name that goes before the TLD name; example: "Pepe" in "pepe.pepe"
    uint256 tokenId;
    address holder;
    string data; // stringified JSON object, example: {"description": "Some text", "twitter": "@Pepenameservice", "friends": ["0x123..."], "url": "https://pepedomains.com/"}
  }
  
  mapping (string => Domain) public domains; // mapping (domain name => Domain struct)
  mapping (uint256 => string) public domainIdsNames; // mapping (tokenId => domain name)
  mapping (address => string) public defaultNames; // user's default domain

  event DomainCreated(address indexed user, address indexed owner, string fullDomainName);
  event DefaultDomainChanged(address indexed user, string defaultDomain);
  event DataChanged(address indexed user);
  event TldPriceChanged(address indexed user, uint256 tldPrice);
  event ReferralFeeChanged(address indexed user, uint256 referralFee);
  event DomainBuyingToggle(address indexed user, bool domainBuyingToggle);

  constructor(
    string memory _name,
    string memory _symbol,
    address _tldOwner,
    uint256 _domainPrice,
    bool _buyingEnabled
  ) ERC721(_name, _symbol) {
    price = _domainPrice;
    buyingEnabled = _buyingEnabled;
    transferOwnership(_tldOwner);
  }

  // READ

  // Domain getters - you can also get all Domain data by calling the auto-generated domains(domainName) method
  function getDomainHolder(string calldata _domainName) public view returns(address) {
    return domains[strings.lower(_domainName)].holder;
  }

  function getDomainData(string calldata _domainName) public view returns(string memory) {
    return domains[strings.lower(_domainName)].data; // should be a JSON object
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    string memory fullDomainName = string(abi.encodePacked(domains[domainIdsNames[_tokenId]].name, name()));

    return string(
      abi.encodePacked("data:application/json;base64,",Base64.encode(bytes(abi.encodePacked(
        '{"name": "', fullDomainName, '", ',
        '"description": "', description, '", ',
        '"image": "', _getImage(fullDomainName), '"}'))))
    );
  }

  function _getImage(string memory _fullDomainName) internal pure returns (string memory) {
    string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 500 500" width="500" height="500"><defs><linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="0%"><stop offset="0%" style="stop-color:rgb(25, 151, 39);stop-opacity:1" /><stop offset="100%" style="stop-color:rgb(45, 207, 9);stop-opacity:1" /></linearGradient></defs><rect x="0" y="0" width="500" height="500" fill="url(#grad)"/><text x="50%" y="50%" dominant-baseline="middle" fill="white" text-anchor="middle" font-size="2.5rem">',
        _fullDomainName,'</text>',
        '<g transform="translate(-0.000000,100.000000) scale(0.050000,-0.050000)" fill="rgb(17, 116, 29)" stroke="none"><path d="M760 1936 c-81 -31 -185 -90 -226 -128 -61 -56 -131 -164 -145 -224 -18 -77 -32 -104 -94 -179 -73 -89 -102 -152 -116 -251 -14 -110 -13 -368 2 -396 28 -52 69 -94 163 -165 190 -142 378 -238 535 -270 92 -19 500 -24 631 -7 85 11 302 75 329 97 29 24 164 192 173 217 13 32 -27 113 -78 160 -19 17 -32 36 -28 42 4 5 26 19 50 30 50 22 114 83 114 109 0 9 -29 58 -65 107 -35 50 -66 95 -67 101 -2 5 16 22 40 38 34 22 49 41 69 88 13 33 28 73 32 90 9 41 -6 163 -27 205 -20 40 -85 78 -277 160 -66 29 -149 67 -184 86 -115 63 -215 65 -357 7 l-63 -26 -53 33 c-129 81 -137 84 -233 87 -58 2 -103 -2 -125 -11z m609 -323 c73 -37 113 -92 119 -166 5 -63 -20 -123 -65 -155 -134 -93 -460 -30 -567 110 -14 19 -49 47 -77 62 -64 35 -63 58 3 67 25 4 82 23 125 43 177 80 351 94 462 39z m593 -18 c26 -9 59 -30 73 -47 21 -25 25 -39 25 -99 0 -43 -6 -81 -15 -99 -31 -60 -113 -79 -261 -61 -119 14 -187 36 -227 71 -29 25 -34 37 -44 106 -7 50 -8 85 -2 96 8 16 70 39 139 52 57 11 266 -2 312 -19z m-155 -846 c63 -47 84 -82 62 -104 -22 -22 -185 -65 -269 -71 l-75 -6 41 39 c68 64 69 66 38 112 -15 23 -25 44 -22 46 8 8 89 23 132 24 31 1 50 -7 93 -40z m-691 -50 c65 -20 214 -94 214 -106 0 -10 -103 7 -170 27 -80 26 -180 70 -180 81 0 7 21 13 56 18 7 0 43 -8 80 -20z"/><path d="M1155 1551 c-79 -48 -97 -170 -32 -216 27 -19 97 -19 141 -1 49 20 66 51 66 119 0 51 -4 62 -29 88 -24 23 -38 29 -73 29 -24 0 -56 -8 -73 -19z m106 -91 c10 -6 19 -16 19 -22 0 -18 -32 -48 -51 -48 -23 0 -36 44 -19 65 15 18 25 19 51 5z"/><path d="M1755 1537 c-59 -59 -56 -151 7 -183 17 -9 48 -14 76 -12 46 3 47 4 76 60 l28 57 -26 46 c-30 51 -51 65 -96 65 -23 0 -42 -10 -65 -33z m109 -83 c35 -13 12 -54 -30 -54 -20 0 -29 27 -14 45 14 17 21 18 44 9z"/></g>',
        '<g transform="translate(390.000000,510.000000) scale(0.050000,-0.050000)" fill="rgb(17, 116, 29)" stroke="none"><path d="M1268 1937 c-20 -8 -69 -35 -109 -61 -40 -25 -76 -46 -81 -46 -5 0 -34 11 -66 24 -135 57 -239 55 -353 -8 -35 -19 -118 -57 -184 -86 -192 -82 -257 -120 -277 -160 -21 -42 -36 -164 -27 -205 4 -17 19 -57 32 -90 20 -47 35 -66 69 -88 24 -16 42 -33 40 -38 -1 -6 -32 -51 -67 -101 -36 -49 -65 -98 -65 -107 0 -26 64 -87 114 -109 24 -11 46 -25 50 -30 4 -6 -9 -25 -28 -42 -51 -47 -91 -128 -78 -160 9 -25 144 -193 173 -217 27 -22 244 -86 329 -97 131 -17 539 -12 631 7 157 32 345 128 535 270 94 71 135 113 163 165 15 28 16 286 2 396 -14 99 -43 162 -116 251 -62 75 -76 102 -94 179 -14 60 -84 168 -146 225 -25 23 -90 63 -143 89 -89 43 -103 47 -182 50 -53 1 -99 -3 -122 -11z m-68 -313 c35 -8 100 -31 143 -50 43 -20 100 -39 125 -43 66 -9 67 -32 3 -67 -28 -15 -63 -43 -77 -62 -107 -140 -433 -203 -567 -110 -73 51 -88 170 -31 250 70 101 208 129 404 82z m-523 -28 c29 -9 57 -25 62 -34 6 -11 5 -46 -2 -96 -10 -69 -15 -81 -44 -106 -40 -35 -108 -57 -227 -71 -148 -18 -230 1 -261 61 -9 18 -15 56 -15 99 0 101 29 130 165 165 42 11 271 -2 322 -18z m-67 -816 c30 -6 56 -12 58 -15 3 -2 -7 -23 -22 -46 -31 -46 -30 -48 38 -112 l41 -39 -75 6 c-82 6 -247 49 -269 70 -21 22 -4 54 57 102 62 48 80 51 172 34z m629 -66 c17 -4 31 -10 31 -14 0 -10 -101 -55 -180 -80 -66 -20 -170 -37 -170 -27 0 12 139 82 205 103 82 27 74 26 114 18z"/><path d="M949 1541 c-25 -26 -29 -37 -29 -88 0 -68 17 -99 66 -119 44 -18 114 -18 141 1 47 33 52 119 11 178 -45 63 -139 77 -189 28z m91 -86 c16 -20 4 -65 -17 -65 -20 0 -53 28 -53 46 0 14 27 33 46 34 6 0 17 -7 24 -15z"/><path d="M378 1559 c-10 -5 -29 -30 -44 -55 l-26 -45 28 -57 c29 -56 30 -57 76 -60 87 -6 138 46 123 125 -9 52 -63 103 -106 103 -19 0 -42 -5 -51 -11z m56 -121 c15 -24 -5 -42 -38 -34 -17 4 -26 13 -26 25 0 33 45 39 64 9z"/></g>',
        '</svg>'
    ))));

    return string(abi.encodePacked("data:image/svg+xml;base64,",svgBase64Encoded));
  }

  // WRITE
  function editDefaultDomain(string calldata _domainName) external {
    require(domains[_domainName].holder == msg.sender, "You do not own the selected domain");
    defaultNames[msg.sender] = _domainName;
    emit DefaultDomainChanged(msg.sender, _domainName);
  }

  /// @notice Edit domain custom data. Make sure to not accidentally delete previous data. Fetch previous data first.
  /// @param _domainName Only domain name, no TLD/extension.
  /// @param _data Custom data needs to be in a JSON object format.
  function editData(string calldata _domainName, string calldata _data) external {
    require(domains[_domainName].holder == msg.sender, "Only domain holder can edit their data");
    domains[_domainName].data = _data;
    emit DataChanged(msg.sender);
  }

  /// @notice Mint a new domain name as NFT (no dots and spaces allowed).
  /// @param _domainName Enter domain name without TLD and make sure letters are in lowercase form.
  /// @return token ID
  function mint(
    string memory _domainName,
    address _domainHolder,
    address _referrer
  ) external payable nonReentrant returns(uint256) {
    require(buyingEnabled || msg.sender == owner(), "Buying TLDs disabled");
    require(msg.value >= price, "Value below price");

    _sendPayment(msg.value, _referrer);

    return _mintDomain(_domainName, _domainHolder, "");
  }

  function _mintDomain(
    string memory _domainNameRaw, 
    address _domainHolder,
    string memory _data
  ) internal returns(uint256) {
    // convert domain name to lowercase (only works for ascii, clients should enforce ascii domains only)
    string memory _domainName = strings.lower(_domainNameRaw);

    require(strings.len(strings.toSlice(_domainName)) > 1, "Domain must be longer than 1 char");
    require(bytes(_domainName).length < nameMaxLength, "Domain name is too long");
    require(strings.count(strings.toSlice(_domainName), strings.toSlice(".")) == 0, "There should be no dots in the name");
    require(strings.count(strings.toSlice(_domainName), strings.toSlice(" ")) == 0, "There should be no spaces in the name");
    require(domains[_domainName].holder == address(0), "Domain with this name already exists");

    _safeMint(_domainHolder, totalSupply);

    Domain memory newDomain;
    
    // store data in Domain struct
    newDomain.name = _domainName;
    newDomain.tokenId = totalSupply;
    newDomain.holder = _domainHolder;
    newDomain.data = _data;

    // add to both mappings
    domains[_domainName] = newDomain;
    domainIdsNames[totalSupply] = _domainName;

    if (bytes(defaultNames[_domainHolder]).length == 0) {
      defaultNames[_domainHolder] = _domainName; // if default domain name is not set for that holder, set it now
    }
    
    emit DomainCreated(msg.sender, _domainHolder, string(abi.encodePacked(_domainName, name())));

    ++totalSupply;

    return totalSupply-1;
  }

  function _sendPayment(uint256 _paymentAmount, address _referrer) internal {

    if (_referrer != address(0) && referral > 0 && referral < 5000) {
      // send referral fee - must be less than 50% (5000 bips)
      (bool sentReferralFee, ) = payable(_referrer).call{value: ((_paymentAmount * referral) / 10000)}("");
      require(sentReferralFee, "Failed to send referral fee");
    }

    // send the rest to TLD owner
    (bool sent, ) = payable(owner()).call{value: address(this).balance}("");
    require(sent, "Failed to send domain payment to TLD owner");
  }

  ///@dev Hook that is called before any token transfer. This includes minting and burning.
  function _beforeTokenTransfer(address from,address to,uint256 tokenId) internal override virtual {

    if (from != address(0)) { // run on every transfer but not on mint
      domains[domainIdsNames[tokenId]].holder = to; // change holder address in Domain struct
      domains[domainIdsNames[tokenId]].data = ""; // reset custom data
      
      if (bytes(defaultNames[to]).length == 0) {
        defaultNames[to] = domains[domainIdsNames[tokenId]].name; // if default domain name is not set for that holder, set it now
      }

      if (strings.equals(strings.toSlice(domains[domainIdsNames[tokenId]].name), strings.toSlice(defaultNames[from]))) {
        defaultNames[from] = ""; // if previous owner had this domain name as default, unset it as default
      }
    }
  }

  // OWNER

  /// @notice Only TLD contract owner can call this function.
  function changeDescription(string calldata _description) external onlyOwner {
    description = _description;
  }

  /// @notice Only TLD contract owner can call this function.
  function changeNameMaxLength(uint256 _maxLength) external onlyOwner {
    nameMaxLength = _maxLength;
  }

  /// @notice Only TLD contract owner can call this function.
  function changePrice(uint256 _price) external onlyOwner {
    price = _price;
    emit TldPriceChanged(msg.sender, _price);
  }

  function withdraw() external onlyOwner{
    payable(msg.sender).transfer(address(this).balance);
  }

  /// @notice Only TLD contract owner can call this function.
  function changeReferralFee(uint256 _referral) external onlyOwner {
    require(_referral < 5000, "Referral fee cannot be 50% or higher");
    referral = _referral; // referral must be in bips
    emit ReferralFeeChanged(msg.sender, _referral);
  }

  /// @notice Only TLD contract owner can call this function.
  function toggleBuyingDomains() external onlyOwner {
    buyingEnabled = !buyingEnabled;
    emit DomainBuyingToggle(msg.sender, buyingEnabled);
  }
}