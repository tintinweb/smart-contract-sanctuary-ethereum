// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "solmate/tokens/ERC721.sol";
import "solmate/auth/Owned.sol";
import "strings/StringsMinified.sol";

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   ███████╗ ██╗   ██╗ ██████╗  ██████╗  ███████╗  █████╗  ██╗        //
//   ██╔════╝ ██║   ██║ ██╔══██╗ ██╔══██╗ ██╔════╝ ██╔══██╗ ██║        //
//   ███████╗ ██║   ██║ ██████╔╝ ██████╔╝ █████╗   ███████║ ██║        //
//   ╚════██║ ██║   ██║ ██╔══██╗ ██╔══██╗ ██╔══╝   ██╔══██║ ██║        //
//   ███████║ ╚██████╔╝ ██║  ██║ ██║  ██║ ███████╗ ██║  ██║ ███████╗   //
//   ╚══════╝  ╚═════╝  ╚═╝  ╚═╝ ╚═╝  ╚═╝ ╚══════╝ ╚═╝  ╚═╝ ╚══════╝   //
//                                                                     //
//                              surr.app                               //
//                   A magic bag for your web3 loot                    //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

contract SurrealDisplays is ERC721, Owned {

    using Strings for uint256;

    //// UNCHANGEABLE ////

    uint256[10] _displayTotalSupply;

    //// PRIVATE STORAGE ////

    string private _baseURI;
    // Setting individualTraits will cause returning _baseURI + id instead of  _baseURI + displayType from getURI(id)
    bool private _individualTraits;
    address private _operator;

    //// PUBLIC STORAGE ////

    uint256 public totalMinted;
    uint256[10] public totalMintedByType;
    mapping(uint256 => uint256) public idToDisplayType;
    mapping(address => uint256) public mintedTo;

    //// CONSTRUCTOR ////

    constructor(string memory baseURI, address operator, address owner)
        ERC721("Surreal Displays", "SDSP")
        Owned(owner) {

        _baseURI = baseURI;
        _operator = operator;

        _displayTotalSupply[0] = 99;
        _displayTotalSupply[1] = 152;
        _displayTotalSupply[2] = 42;
        _displayTotalSupply[3] = 88;
        _displayTotalSupply[4] = 142;
        _displayTotalSupply[5] = 111;
        _displayTotalSupply[6] = 77;
        _displayTotalSupply[7] = 168;
        _displayTotalSupply[8] = 90;
        _displayTotalSupply[9] = 142;
    }

    //// MINTER ////

    function mint(
        address to,
        uint256 displayType,
        bytes32 operatorMessageHash,
        bytes memory operatorSignature)
    payable public {

        require(displayType < _displayTotalSupply.length, "SurrealDisplays: Invalid displayType");
        require(totalMintedByType[displayType] < _displayTotalSupply[displayType], "SurrealDisplays: Exceeds total supply for displayType");
        require(mintedTo[to] == 0, "SurrealDisplays: Not eligible for mint");

        if(msg.value == 0) {
            verifyFreeMintSignature(operatorMessageHash, operatorSignature);
        } else {
            require(msg.value == 1000000000000000, "SurrealDisplays: Not enough Eth provided for the mint");
        }

        uint256 totalMinted_ = totalMinted + 1;

        totalMintedByType[displayType]++;
        idToDisplayType[totalMinted_] = displayType;
        mintedTo[to] == totalMinted_;
        totalMinted = totalMinted_;

        _mint(to, totalMinted_);
    }

    //// URI GETTER ////

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(id > 0 && id <= totalMinted, "SurrealDisplays: Nonexistent Display");

        if(_individualTraits) return string.concat(_baseURI, id.toString());
        return string.concat(_baseURI, idToDisplayType[id].toString());
    }

    //// OWNER ONLY ////

    function withdraw() onlyOwner external {
        (bool sent,) = owner.call{value: address(this).balance}("");
        require(sent, "SurrealDisplays: Withdrawal error");
    }

    function updateBaseURI(string memory baseURI, bool individualTraits) onlyOwner external {
        _individualTraits = individualTraits;
        _baseURI = baseURI;
    }

    function updateOperator(address operator) onlyOwner external {
        _operator = operator;
    }

    //// PRIVATE ////

    function verifyFreeMintSignature(bytes32 hash, bytes memory signature) private view {
        require(signature.length == 65, "SurrealDisplays: Invalid signature - invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := and(mload(add(signature, 65)), 255)
        }

        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "SurrealDisplays: Invalid signature - invalid S parameter");
        require(v == 27 || v == 28, "SurrealDisplays: Invalid signature - invalid V parameter");

        require(ecrecover(hash, v, r, s) == _operator, "SurrealDisplays: Invalid signature - signer is not Operator");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity 0.8.15;

import "math/MathMinified.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";

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

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity 0.8.15;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {

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

}