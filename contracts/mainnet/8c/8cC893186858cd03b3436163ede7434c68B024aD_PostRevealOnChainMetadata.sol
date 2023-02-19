// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// ownable
import "@openzeppelin/contracts/access/Ownable.sol";

import "./IOnChainMetadata.sol";
import "./MetadataUtils.sol";

interface WithTokenTypes {
    function tokenTypes(uint256 tokenId) external view returns (uint256);
}

interface WithRandom {
    function randomNumber() external view returns (uint256);

    function generateBase64(uint256 tokenId)
        external
        view
        returns (string memory);
}

contract PostRevealOnChainMetadata is IOnChainMetadata, Ownable {
    using Strings for uint256;

    string internal _glitchedBase64Data;
    string internal _name;
    string internal _description;
    string internal _external_url;
    string internal _background_color;

    WithRandom internal randomContract;

    constructor(
        string memory glitchedBase64Data_,
        string memory name_,
        string memory description_,
        string memory external_url_,
        string memory background_color_,
        WithRandom randomContract_
    ) {
        _glitchedBase64Data = glitchedBase64Data_;
        _name = name_;
        _description = description_;
        _external_url = external_url_;
        _background_color = background_color_;

        randomContract = randomContract_;
    }

    function generateBase64() public view returns (string memory) {
        return randomContract.generateBase64(0);
    }

    function generateBase64Glitched() external view returns (string memory) {
        return _glitchedBase64Data;
    }

    function tokenImageDataURI(uint256 tokenId, uint256 tokenType)
        public
        view
        returns (string memory)
    {
        if (isGlitched(tokenId, tokenType))
            return
                string(
                    abi.encodePacked(
                        "data:image/svg+xml;base64,",
                        _glitchedBase64Data
                    )
                );
        return
            string(
                abi.encodePacked("data:image/svg+xml;base64,", generateBase64())
            );
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        string memory dataURI = MetadataUtils.tokenMetadataToString(
            TokenMetadata(
                _name,
                _description,
                tokenImageDataURI(
                    tokenId,
                    WithTokenTypes(msg.sender).tokenTypes(tokenId)
                ),
                _external_url,
                _background_color,
                getAttributes(
                    tokenId,
                    WithTokenTypes(msg.sender).tokenTypes(tokenId)
                )
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(dataURI))
                )
            );
    }

    function getAttributes(uint256 tokenId, uint256 tokenType)
        internal
        view
        returns (Attribute[] memory attributes)
    {
        bool glitched = isGlitched(tokenId, tokenType);

        if (glitched) {
            attributes = new Attribute[](2);
            if (tokenType == 0) {
                attributes = new Attribute[](0);
            } else if (tokenType == 1) {
                attributes[0] = Attribute("Class", "The Chosen One");
                attributes[1] = Attribute("State ", "Corrupted");
            } else if (tokenType == 2) {
                attributes[0] = Attribute("Class", "Free Mintooor");
                attributes[1] = Attribute("State ", "Corrupted");
            } else if (tokenType == 3) {
                attributes[0] = Attribute("Class", "Big Money Spendooor");
                attributes[1] = Attribute("State ", "Corrupted");
            }
        } else {
            attributes = new Attribute[](2);
            if (tokenType == 0) {
                attributes = new Attribute[](0);
            } else if (tokenType == 1) {
                attributes[0] = Attribute("Class", "The Chosen One");
                attributes[1] = Attribute("State ", "Rugged");
            } else if (tokenType == 2) {
                attributes[0] = Attribute("Class", "Free Mintooor");
                attributes[1] = Attribute("State ", "Rugged");
            } else if (tokenType == 3) {
                attributes[0] = Attribute("Class", "Big Money Spendooor");
                attributes[1] = Attribute("State ", "Rugged");
            }
        }
    }

    function randomNumber() public view returns (uint256) {
        return randomContract.randomNumber();
    }

    function isGlitched(uint256 tokenId, uint256 tokenType)
        internal
        view
        returns (bool)
    {
        require(randomNumber() != 0, "Random number not yet generated");
        return
            (tokenId == 0)
                ? true
                : uint256(
                    keccak256(
                        abi.encodePacked(tokenId, tokenType, randomNumber())
                    )
                ) %
                    100 ==
                    0;
    }

    function setName(string memory name_) external onlyOwner {
        _name = name_;
    }

    function setDescription(string memory description_) external onlyOwner {
        _description = description_;
    }

    function setbackground_color(string memory background_color_)
        external
        onlyOwner
    {
        _background_color = background_color_;
    }

    function setExternalUrl(string memory external_url_) external onlyOwner {
        _external_url = external_url_;
    }

    function setGlitchedBase64Data(string memory glitchedBase64Data_)
        external
        onlyOwner
    {
        _glitchedBase64Data = glitchedBase64Data_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

struct TokenMetadata {
  string name;
  string description;
  string image;
  string external_url;
  string background_color;
  Attribute[] attributes;
}

struct Attribute {
  string trait_type;
  string value;
}

library MetadataUtils {
  function tokenMetadataToString(
    TokenMetadata memory metadata
  ) internal pure returns (string memory) {
    bytes memory output = abi.encodePacked(
      "{",
      '"name": "',
      metadata.name,
      '",',
      '"description": "',
      metadata.description,
      '",',
      '"image": "',
      metadata.image,
      '",'
    );

    output = abi.encodePacked(
      output,
      '"external_url": "',
      metadata.external_url,
      '",',
      '"background_color": "',
      metadata.background_color,
      '",',
      '"attributes": ['
    );

    return string(abi.encodePacked(output, attributesToString(metadata.attributes), "]", "}"));
  }

  function attributesToString(Attribute[] memory attributes) internal pure returns (string memory) {
    string memory output = "";
    for (uint256 i = 0; i < attributes.length; i++) {
      output = string(
        abi.encodePacked(
          output,
          "{",
          '"trait_type": "',
          attributes[i].trait_type,
          '",',
          '"value": "',
          attributes[i].value,
          '"',
          "}"
        )
      );
      if (i != attributes.length - 1) {
        output = string(abi.encodePacked(output, ","));
      }
    }
    return output;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IOnChainMetadata {
    /**
     * Mint new tokens.
     */
    function tokenURI(uint256 tokenId_) external view returns (string memory);
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

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

        /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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