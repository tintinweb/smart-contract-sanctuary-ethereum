// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

import "contracts/interfaces/IReceipt.sol";
import "contracts/libraries/NFTSVG.sol";

library NFTDescriptor {
    function constructTokenURI(IReceipt.Receipt memory receipt)
        external
        view
        returns (string memory)
    {
        string memory amount = NFTSVG.parseAmount(
            receipt.token,
            receipt.amount
        );

        string memory description = string.concat(
            "Receipt from ",
            NFTSVG.generatePerson(receipt.payerName, receipt.payer),
            " for the amount of ",
            amount,
            " ",
            IERC20Metadata(receipt.token).symbol(),
            " tokens",
            " to ",
            NFTSVG.generatePerson(receipt.recipientName, receipt.recipient)
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"Receipt number ',
                                Strings.toString(receipt.nonce),
                                '", "description":"',
                                description,
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                NFTSVG.constructImage(receipt),
                                '"}'
                            )
                        )
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
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
pragma solidity 0.8.16;

interface IReceipt {
    struct Receipt {
        uint256 amount;
        uint96 timestamp;
        address token;
        uint96 nonce;
        address payer;
        address recipient;
        string payerName;
        string recipientName;
    }

    event Payed(
        address payer,
        address recipient,
        uint256 amount,
        uint256 surcharge,
        address token,
        uint256 receiptId,
        uint256 mintedNftId
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

import "contracts/interfaces/IReceipt.sol";

library NFTSVG {
    enum Template {
        NN, // there is no name of either the payer or the recipient
        PN, // there is only payer name
        RN, // there is only recipient name
        PNRN // there is both payer and recipient names
    }

    // height of the base image with minium number of fields
    uint256 constant BASE_IMAGE_HEIGHT = 427;
    // height of a field in the template
    uint256 constant FIELD_HEIGHT = 52;

    function constructImage(IReceipt.Receipt memory receipt)
        internal
        view
        returns (string memory)
    {
        Template template = determineTemplate(receipt);

        return
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '<svg font-family="Arial" font-size="20" viewBox="0 0 591 ',
                        Strings.toString(
                            BASE_IMAGE_HEIGHT + findBodyIncrementByY(template)
                        ),
                        '" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                        drawBackground(template),
                        '<text y="133" x="96">',
                        Strings.toString(receipt.timestamp),
                        "</text>",
                        '<text y="133" x="419">',
                        Strings.toString(receipt.nonce),
                        "</text>",
                        '<text font-size="17.5" y="201" x="126">',
                        Strings.toHexString(
                            uint256(uint160(receipt.payer)),
                            20
                        ),
                        "</text>",
                        '<text font-size="17.5" y="',
                        Strings.toString(
                            253 + findRecipientInrementByY(template)
                        ),
                        '" x="141">',
                        Strings.toHexString(
                            uint256(uint160(receipt.recipient)),
                            20
                        ),
                        "</text>",
                        '<text y="253" x="177">',
                        receipt.payerName,
                        "</text>",
                        '<text y="',
                        Strings.toString(
                            305 + findRecipientInrementByY(template)
                        ),
                        '" x="191">',
                        receipt.recipientName,
                        "</text>",
                        generateBottom(template, receipt),
                        "</svg>"
                    )
                )
            );
    }

    function determineTemplate(IReceipt.Receipt memory _receipt)
        internal
        pure
        returns (Template)
    {
        bool phn = bytes(_receipt.payerName).length > 0;
        bool rhn = bytes(_receipt.recipientName).length > 0;

        return
            phn
                ? (rhn ? Template.PNRN : Template.PN)
                : (rhn ? Template.RN : Template.NN);
    }

    function drawBackground(Template _t) internal pure returns (string memory) {
        return
            string.concat(
                '<g fill="#F5F5FC">',
                '<rect fill="#2372F1" height="',
                Strings.toString(427 + findBodyIncrementByY(_t)),
                '" width="591" rx="16"/>',
                '<rect height="53" width="527" x="32" y="32" rx="16"/>=',
                '<text fill="#2372F1" x="223" y="69.5" letter-spacing="0.04em" font-weight="700" font-size="32">RECEIPT</text>',
                '<rect height="53" width="255.5" x="32" y="101" rx="16"/>',
                '<rect height="53" width="255.5" x="303.5" y="101" rx="16"/>',
                '<text fill="#2372F1" x="48" y="133" font-size="16">TIME:</text>',
                '<text fill="#2372F1" x="319.5" y="133" font-size="16">RECEIPT ID:</text>',
                '<rect height="',
                Strings.toString(156 + findBodyIncrementByY(_t)),
                '" width="527" x="32" y="169" rx="16"/>',
                drawStrokes(_t),
                drawPayerTitle(_t),
                drawRecipientTitle(_t),
                drawBottom(_t),
                "</g>"
            );
    }

    function drawStrokes(Template _t) internal pure returns (string memory) {
        string memory additionalStrokes = _t == Template.NN
            ? ""
            : '<line x1="48" x2="546" y1="325" y2="325" stroke="#2372F1" stroke-width="2" stroke-linecap="square" stroke-dasharray="0.5, 4.5"/>';
        if (_t == Template.PNRN)
            additionalStrokes = string.concat(
                additionalStrokes,
                '<line x1="48" x2="546" y1="377" y2="377" stroke="#2372F1" stroke-width="2" stroke-linecap="square" stroke-dasharray="0.5, 4.5"/>'
            );

        return
            string.concat(
                '<line x1="48" x2="546" y1="221" y2="221" stroke="#2372F1" stroke-width="2" stroke-linecap="square" stroke-dasharray="0.5, 4.5"/>',
                '<line x1="48" x2="546" y1="273" y2="273" stroke="#2372F1" stroke-width="2" stroke-linecap="square" stroke-dasharray="0.5, 4.5"/>',
                additionalStrokes
            );
    }

    function drawPayerTitle(Template _t) internal pure returns (string memory) {
        string memory name = _t == Template.PN || _t == Template.PNRN
            ? '<text fill="#2372F1" x="48" y="253" font-size="16">SENDER NAME:</text>'
            : "";
        return
            string.concat(
                '<text fill="#2372F1" x="48" y="201" font-size="16">SENDER:</text>',
                name
            );
    }

    function drawRecipientTitle(Template _t)
        internal
        pure
        returns (string memory)
    {
        string memory name = _t == Template.RN || _t == Template.PNRN
            ? string.concat(
                '<text fill="#2372F1" x="48" y="',
                Strings.toString(305 + findRecipientInrementByY(_t)),
                '" font-size="16">RECEIVER NAME:</text>'
            )
            : "";
        return
            string.concat(
                '<text fill="#2372F1" x="48" y="',
                Strings.toString(253 + findRecipientInrementByY(_t)),
                '" font-size="16">RECEIVER:</text>',
                name
            );
    }

    function drawBottom(Template _t) internal pure returns (string memory) {
        string memory rect = string.concat(
            '<rect height="53" width="255.5" x="32" y="',
            Strings.toString(341 + findBodyIncrementByY(_t)),
            '" rx="16"/>',
            '<rect height="53" width="255.5" x="303.5" y="',
            Strings.toString(341 + findBodyIncrementByY(_t)),
            '" rx="16"/>'
        );
        return
            string.concat(
                rect,
                '<text fill="#2372F1" x="48" y="',
                Strings.toString(305 + findBodyIncrementByY(_t)),
                '" font-size="16">AMOUNT:</text>',
                '<text fill="#2372F1" x="48" y="',
                Strings.toString(373 + findBodyIncrementByY(_t)),
                '" font-size="16">TOKEN:</text>',
                '<text fill="#2372F1" x="319.5" y="',
                Strings.toString(373 + findBodyIncrementByY(_t)),
                '" font-size="16">CHAIN ID:</text>'
            );
    }

    function findBodyIncrementByY(Template _t)
        internal
        pure
        returns (uint256 h_)
    {
        if (_t == Template.NN) return 0;
        else if (_t == Template.PN) return FIELD_HEIGHT;
        else if (_t == Template.RN) return FIELD_HEIGHT;
        else return FIELD_HEIGHT * 2;
    }

    function findRecipientInrementByY(Template _t)
        internal
        pure
        returns (uint256)
    {
        if (_t == Template.NN) return 0;
        else if (_t == Template.PN) return FIELD_HEIGHT;
        else if (_t == Template.RN) return 0;
        else return FIELD_HEIGHT;
    }

    function generateBottom(Template _t, IReceipt.Receipt memory _receipt)
        internal
        view
        returns (string memory)
    {
        string memory amount = parseAmount(_receipt.token, _receipt.amount);
        return
            string.concat(
                '<text y="',
                Strings.toString(305 + findBottomIncrementByY(_t)),
                '" x="127">',
                amount,
                "</text>",
                '<text y="',
                Strings.toString(373 + findBottomIncrementByY(_t)),
                '" x="114">',
                IERC20Metadata(_receipt.token).symbol(),
                "</text>",
                '<text y="',
                Strings.toString(373 + findBottomIncrementByY(_t)),
                '" x="401">',
                Strings.toString(block.chainid),
                "</text>"
            );
    }

    function findBottomIncrementByY(Template _t)
        internal
        pure
        returns (uint256)
    {
        if (_t == Template.NN) return 0;
        else if (_t == Template.PN) return FIELD_HEIGHT;
        else if (_t == Template.RN) return FIELD_HEIGHT;
        else return FIELD_HEIGHT * 2;
    }

    function generatePerson(string memory _name, address _address)
        internal
        pure
        returns (string memory)
    {
        string memory personAddress = Strings.toHexString(
            uint256(uint160(_address)),
            20
        );
        return
            bytes(_name).length > 0
                ? string.concat(_name, "(", personAddress, ")")
                : personAddress;
    }

    function parseAmount(address _token, uint256 _amount)
        internal
        view
        returns (string memory)
    {
        uint256 decimals = IERC20Metadata(_token).decimals();

        uint256 whole = _amount / 10**decimals;
        uint256 fraction = parseFraction(
            (_amount % 10**decimals) / 10**(decimals - 6)
        );

        if (fraction > 0)
            return
                string.concat(
                    Strings.toString(whole),
                    ",",
                    Strings.toString(fraction)
                );
        else return Strings.toString(whole);
    }

    function parseFraction(uint256 _fraction) internal view returns (uint256) {
        if (_fraction != 0 && _fraction % 10 == 0)
            return parseFraction(_fraction / 10);
        else return _fraction;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}