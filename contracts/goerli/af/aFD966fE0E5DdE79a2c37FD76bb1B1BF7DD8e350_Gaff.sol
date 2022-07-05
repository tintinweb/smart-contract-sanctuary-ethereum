// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

import {ERC721} from "@rari-capital/solmate/src/tokens/ERC721.sol";
import {GaffMetadata} from "./GaffMetadata.sol";
import {Auth} from "../utils/Auth.sol";

contract Gaff is ERC721, Auth, GaffMetadata {
  //Current gaffId count
  uint256 private _gaffIdCounter = 0;

  constructor(string memory baseUri_) ERC721("Gaff", "GAFF") {
    setBaseUri(baseUri_);
  }

  function totalSupply() public view returns (uint256) {
    return _gaffIdCounter;
  }

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory gaffIds
  ) external {
    for (uint256 i = 0; i < gaffIds.length; ) {
      safeTransferFrom(from, to, gaffIds[i]);
      unchecked {
        i++;
      }
    }
  }

  function mint(address to, uint256 gaffType) external onlyRole("MINTER") {
    uint256 gaffId = _gaffIdCounter;

    unchecked {
      _gaffIdCounter++;
    }

    _mint(to, gaffId, gaffType);
  }

  function batchMint(address to, uint256[] memory gaffTypes) external onlyRole("MINTER") {
    uint256 gaffId = _gaffIdCounter;

    for (uint256 i = 0; i < gaffTypes.length; ) {
      _mint(to, gaffId, gaffTypes[i]);

      unchecked {
        gaffId++;
        i++;
      }
    }

    _gaffIdCounter = gaffId;
  }

  function _mint(
    address to,
    uint256 gaffId,
    uint256 gaffType
  ) private {
    _safeMint(to, gaffId);
    _setGaffType(gaffId, gaffType);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

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
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

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
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            balanceOf[owner]--;
        }

        delete ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
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
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

import {ERC721} from "@rari-capital/solmate/src/tokens/ERC721.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Auth} from "../utils/Auth.sol";

abstract contract GaffMetadata is ERC721, Auth {
  using Strings for uint256;

  //Gaff metadata base uri
  string private _baseUri;
  //Maps gaff id to gaff types
  mapping(uint256 => uint256) private _gaffTypes;

  //Fires when base uri is updated
  event UpdateBaseUri(string baseUri);
  //Fires when gaff type is set
  event GaffTypeSet(uint256 indexed gaffId, uint256 gaffType);

  function gaffTypes(uint256 gaffId) public view returns (uint256) {
    require(_exists(gaffId), "Query for nonexistent gaff");
    return _gaffTypes[gaffId];
  }

  function tokenURI(uint256 gaffId) public view override returns (string memory) {
    require(_exists(gaffId), "Query for nonexistent gaff");
    return string(abi.encodePacked(_baseUri, gaffId.toString()));
  }

  function setBaseUri(string memory newUri) public onlyOwner {
    _baseUri = newUri;
    emit UpdateBaseUri(newUri);
  }

  function _setGaffType(uint256 gaffId, uint256 gaffType) internal {
    _gaffTypes[gaffId] = gaffType;
    emit GaffTypeSet(gaffId, gaffType);
  }

  function _exists(uint256 tokenId) internal view returns (bool) {
    return ownerOf[tokenId] != address(0);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

library Strings {
  function toBytes32(string memory text) internal pure returns (bytes32) {
    return bytes32(bytes(text));
  }

  function toString(bytes32 text) internal pure returns (string memory) {
    return string(abi.encodePacked(text));
  }
}

contract Auth {
  //Address of current owner
  address public owner;
  //Address of new owner (Note: new owner must pull to be an owner)
  address public newOwner;
  //If paused or not
  uint256 private _paused;
  //Roles mapping (role => address => has role)
  mapping(bytes32 => mapping(address => bool)) private _roles;

  //Fires when a new owner is pushed
  event OwnerPushed(address indexed pushedOwner);
  //Fires when new owner pulled
  event OwnerPulled(address indexed previousOwner, address indexed newOwner);
  //Fires when account is granted role
  event RoleGranted(string indexed role, address indexed account, address indexed sender);
  //Fires when accoount is revoked role
  event RoleRevoked(string indexed role, address indexed account, address indexed sender);
  //Fires when pause is triggered by account
  event Paused(address account);
  //Fires when pause is lifted by account
  event Unpaused(address account);

  error Unauthorized(string role, address user);
  error IsPaused();
  error NotPaused();

  constructor() {
    owner = msg.sender;
    emit OwnerPulled(address(0), msg.sender);
  }

  modifier whenNotPaused() {
    if (paused()) revert IsPaused();
    _;
  }

  modifier whenPaused() {
    if (!paused()) revert NotPaused();
    _;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) revert Unauthorized("OWNER", msg.sender);
    _;
  }

  modifier onlyRole(string memory role) {
    if (!hasRole(role, msg.sender)) revert Unauthorized(role, msg.sender);
    _;
  }

  function hasRole(string memory role, address account) public view virtual returns (bool) {
    return _roles[Strings.toBytes32(role)][account];
  }

  function paused() public view virtual returns (bool) {
    return _paused == 1 ? true : false;
  }

  function pushOwner(address account) public virtual onlyOwner {
    require(account != address(0), "No address(0)");
    require(account != owner, "Only new owner");
    newOwner = account;
    emit OwnerPushed(account);
  }

  function pullOwner() public virtual {
    if (msg.sender != newOwner) revert Unauthorized("NEW_OWNER", msg.sender);
    address oldOwner = owner;
    owner = msg.sender;
    emit OwnerPulled(oldOwner, msg.sender);
  }

  function grantRole(string memory role, address account) public virtual onlyOwner {
    require(bytes(role).length > 0, "Role not given");
    require(account != address(0), "No address(0)");
    _grantRole(role, account);
  }

  function revokeRole(string memory role, address account) public virtual onlyOwner {
    require(hasRole(role, account), "Role not granted");
    _revokeRole(role, account);
  }

  function renounceRole(string memory role) public virtual {
    require(hasRole(role, msg.sender), "Role not granted");
    _revokeRole(role, msg.sender);
  }

  function pause() public virtual onlyRole("PAUSER") whenNotPaused {
    _paused = 1;
    emit Paused(msg.sender);
  }

  function unpause() public virtual onlyRole("PAUSER") whenPaused {
    _paused = 0;
    emit Unpaused(msg.sender);
  }

  function _grantRole(string memory role, address account) internal virtual {
    if (!hasRole(role, account)) {
      bytes32 encodedRole = Strings.toBytes32(role);
      _roles[encodedRole][account] = true;
      emit RoleGranted(role, account, msg.sender);
    }
  }

  function _revokeRole(string memory role, address account) internal virtual {
    bytes32 encodedRole = Strings.toBytes32(role);
    _roles[encodedRole][account] = false;
    emit RoleRevoked(role, account, msg.sender);
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