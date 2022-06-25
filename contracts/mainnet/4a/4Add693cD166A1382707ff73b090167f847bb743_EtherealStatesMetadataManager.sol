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
pragma solidity ^0.8.12;

import {OwnableOperators} from '../utils/OwnableOperators.sol';

import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';

contract EtherealStatesMetadataManager is OwnableOperators {
    struct GroupURI {
        uint256 upTo;
        string uri;
    }

    /// @notice group of tokens revealed
    mapping(uint256 => GroupURI) public groups;

    /// @notice for token ids with a very specific uri
    mapping(uint256 => string) public tokenURIs;

    /// @notice next group id
    uint256 public nextGroupId;

    /// @notice unrevealed uri
    string private _unrevealedURI;

    /// @notice concat unrevealed uri
    bool private _concatUnrevealed;

    function tokenURI(uint256 tokenId) public view returns (string memory uri) {
        uri = tokenURIs[tokenId];

        if (bytes(uri).length == 0) {
            // find token id group
            uri = groupForTokenId(tokenId).uri;
            if (bytes(uri).length != 0) {
                uri = string.concat(uri, Strings.toString(tokenId), '.json');
            } else {
                // no group? unrevealed
                if (_concatUnrevealed) {
                    uri = string.concat(
                        unrevealedURI(),
                        Strings.toString(tokenId),
                        '.json'
                    );
                } else {
                    uri = unrevealedURI();
                }
            }
        }
    }

    function unrevealedURI() public view returns (string memory uri) {
        uri = _unrevealedURI;
        if (bytes(uri).length == 0) {
            uri = 'ipfs://QmeDgTDx5Lhxt4x5ttmHgk8o7Lfr73DfbcRmtXqvadCMD7/';
        }
    }

    function groupForTokenId(uint256 tokenId)
        public
        view
        returns (GroupURI memory group)
    {
        uint256 lastGroupId = nextGroupId;
        for (uint256 i; i <= lastGroupId; i++) {
            group = groups[i];
            if (group.upTo >= tokenId) {
                break;
            }
        }
    }

    /////////////////////////////////////////////////////////
    // Gated Operator                                      //
    /////////////////////////////////////////////////////////

    /// @notice allows an operator to set the tokenURI for a token, for reasons
    /// @param tokenId the token id
    /// @param uri the uri
    function setTokenURI(uint256 tokenId, string calldata uri)
        external
        onlyOperator
    {
        tokenURIs[tokenId] = uri;
    }

    /////////////////////////////////////////////////////////
    // Gated Owner                                         //
    /////////////////////////////////////////////////////////

    /// @notice allows owner to set the next group data
    /// @param group the group data
    function nextGroup(GroupURI calldata group) external onlyOwner {
        setGroup(nextGroupId++, group);
    }

    /// @notice allows owner to set the group data for given groupId
    /// @param groupId the group id
    /// @param group the group data
    function setGroup(uint256 groupId, GroupURI calldata group)
        public
        onlyOwner
    {
        groups[groupId] = group;
    }

    /// @notice allows owner to set the unrevealed URI
    /// @param newUnrevealedURI the new unrevealed URI
    function setUnrevealedURI(string calldata newUnrevealedURI)
        public
        onlyOwner
    {
        _unrevealedURI = newUnrevealedURI;
    }

    /// @notice allows owner to change the way unrevealed are build
    /// @param newConcatUnrevealed the new concat unrevealed config
    function setConcatUnrevealed(bool newConcatUnrevealed) public onlyOwner {
        _concatUnrevealed = newConcatUnrevealed;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title Operators
/// @author Simon Fremaux (@dievardump)
contract Operators {
    error NotAuthorized();
    error InvalidAddress(address invalid);

    mapping(address => bool) public operators;

    modifier onlyOperator() virtual {
        if (!isOperator(msg.sender)) revert NotAuthorized();
        _;
    }

    /// @notice tells if an account is an operator or not
    /// @param account the address to check
    function isOperator(address account) public view virtual returns (bool) {
        return operators[account];
    }

    /// @dev set operator state to `isOperator` for ops[]
    function _editOperators(address[] memory ops, bool isOperatorRole)
        internal
    {
        for (uint256 i; i < ops.length; i++) {
            if (ops[i] == address(0)) revert InvalidAddress(ops[i]);
            operators[ops[i]] = isOperatorRole;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';

import './Operators.sol';

/// @title OwnableOperators
/// @author Simon Fremaux (@dievardump)
contract OwnableOperators is Ownable, Operators {
    ////////////////////////////////////////////
    // Only Owner                             //
    ////////////////////////////////////////////

    /// @notice add new operators
    /// @param ops the list of operators to add
    function addOperators(address[] memory ops) external onlyOwner {
        _editOperators(ops, true);
    }

    /// @notice add a new operator
    /// @param operator the operator to add
    function addOperator(address operator) external onlyOwner {
        address[] memory ops = new address[](1);
        ops[0] = operator;
        _editOperators(ops, true);
    }

    /// @notice remove operators
    /// @param ops the list of operators to remove
    function removeOperators(address[] memory ops) external onlyOwner {
        _editOperators(ops, false);
    }

    /// @notice remove an operator
    /// @param operator the operator to remove
    function removeOperator(address operator) external onlyOwner {
        address[] memory ops = new address[](1);
        ops[0] = operator;
        _editOperators(ops, false);
    }
}