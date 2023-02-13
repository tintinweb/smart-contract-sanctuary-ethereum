// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IGuardable.sol";

/**
* Abstract contract to be used with ERC1155 or ERC721 or their extensions.
* See ERC721Guardable or ERC1155Guardable for examples of how to overwrite
* setApprovalForAll and approve to be Guardable. Overwriting other functions
* is possible but not recommended.
*/
abstract contract Guardable is IGuardable {
  mapping(address => address) internal locks;

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IGuardable).interfaceId;
  }

  function setGuardian(address guardian) public {
    if (msg.sender == guardian || guardian == address(0)) {
      revert InvalidGuardian();
    }

    locks[msg.sender] = guardian;
    emit GuardianAdded(msg.sender, guardian);
  }

  function guardianOf(address tokenOwner) public view returns (address) {
    return locks[tokenOwner];
  }

  function removeGuardianOf(address tokenOwner) external {
    if (msg.sender != guardianOf(tokenOwner)) {
      revert CallerGuardianMismatch(msg.sender, guardianOf(tokenOwner));
    }
    delete locks[tokenOwner];
    emit GuardianRemoved(tokenOwner);
  }

  function _lockToSelf() internal virtual {
    locks[msg.sender] = msg.sender;
    emit GuardianAdded(msg.sender, msg.sender);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IGuardable is IERC165 {
  // Interface ID 0x126f5523

  error TokenIsLocked();
  error CallerGuardianMismatch(address caller, address guardian);
  error InvalidGuardian();

  event GuardianAdded(address indexed addressGuarded, address indexed guardian);
  event GuardianRemoved(address indexed addressGuarded);

  function setGuardian(address guardian) external;

  function removeGuardianOf(address tokenOwner) external;

  function guardianOf(address tokenOwner) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "solmate/tokens/ERC721.sol";
import "../Guardable.sol";

/**
 * @dev Contract module which provides added security functionality, where
 * where an account can assign a guardian to protect their NFTs. While a guardian
 * is assigned, setApprovalForAll and approve are both locked. New approvals cannot be set. There can
 * only ever be one guardian per account, and setting a new guardian will overwrite
 * any existing one.
 *
 * Existing approvals can still be leveraged as normal, and it is expected that this
 * functionality be used after a user has set the approvals they want to set. Approvals
 * can still be removed while a guardian is set.
 * 
 * Setting a guardian has no effect on transfers, so users can move assets to a new wallet
 * to effectively "clear" guardians if a guardian is maliciously set, or keys to a guardian
 * are lost.
 *
 * It is not recommended to use _lockToSelf, as removing this lock would be easily added to
 * a malicious workflow, whereas removing a traditional lock from a guardian account would
 * be sufficiently prohibitive.
 */

contract ERC721Guardable is ERC721, Guardable {
  string internal baseUri;

  constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

  function supportsInterface(bytes4 interfaceId) public view virtual override(Guardable, ERC721) returns (bool) {
    return Guardable.supportsInterface(interfaceId) || ERC721.supportsInterface(interfaceId);
  }

  function approve(address to, uint256 tokenId) public override {
    if (locks[msg.sender] != address(0)) {
      revert TokenIsLocked();
    }

    super.approve(to, tokenId);
  }

  function setApprovalForAll(address operator, bool approved) public override {
    if (locks[msg.sender] != address(0) && approved) {
      revert TokenIsLocked();
    }

    super.setApprovalForAll(operator, approved);
  }

  function tokenURI(uint256 id) public view virtual override returns (string memory) {
    return string(abi.encodePacked(baseUri, _toString(id)));
  }

  // From ERC721A
  /**
    * @dev Converts a uint256 to its ASCII string decimal representation.
  */
  function _toString(uint256 value) internal pure virtual returns (string memory str) {
      assembly {
          // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
          // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
          // We will need 1 word for the trailing zeros padding, 1 word for the length,
          // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
          let m := add(mload(0x40), 0xa0)
          // Update the free memory pointer to allocate.
          mstore(0x40, m)
          // Assign the `str` to the end.
          str := sub(m, 0x20)
          // Zeroize the slot after the string.
          mstore(str, 0)

          // Cache the end of the memory to calculate the length later.
          let end := str

          // We write the string from rightmost digit to leftmost digit.
          // The following is essentially a do-while loop that also handles the zero case.
          // prettier-ignore
          for { let temp := value } 1 {} {
              str := sub(str, 1)
              // Write the character to the pointer.
              // The ASCII index of the '0' character is 48.
              mstore8(str, add(48, mod(temp, 10)))
              // Keep dividing `temp` until zero.
              temp := div(temp, 10)
              // prettier-ignore
              if iszero(temp) { break }
          }

          let length := sub(end, str)
          // Move the pointer 32 bytes leftwards to make room for the length.
          str := sub(str, 0x20)
          // Store the length.
          mstore(str, length)
      }
  }
}

// SPDX-License-Identifier: MIT
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

import "Guardable/ERC721Guardable.sol";
import "solmate/auth/Owned.sol";
import "./lib/MarauderErrors.sol";
import "./lib/MarauderStructs.sol";
import "./interfaces/INuclearNerds.sol";

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract MaraudersOfTheAccidentalApocalypse is ERC721Guardable, Owned {
    address public immutable BOX_O_BAD_GUYS_CONTRACT_ADDRESS;
    address public immutable NERDS_CONTRACT_ADDRESS;
    INuclearNerds private immutable nerds;

    mapping(uint256 => bool) public nerdHasClaimed;
    mapping(uint256 => bool) public berserkersEligibleForClaim;

    ClaimableTokenDetails public raiderTokenDetails; // max supply 9043 (1:1 nerds + bonus for berserkers)
    MintableTokenDetails public enforcerTokenDetails; // max supply 5007 (enforced by BoxOBadGuys contract)
    MintableTokenDetails public warlordTokenDetails; // max supply 3038 (enforced by BoxOBadGuys contract)

    constructor(address _mintPassContractAddress, address _nerdsContractAddress, uint256[43] memory berserkerTokenIds) 
      ERC721Guardable("Marauders Of The Accidental Apocalypse", "MARAUDERS") 
        Owned(msg.sender) {
          BOX_O_BAD_GUYS_CONTRACT_ADDRESS = _mintPassContractAddress;
          NERDS_CONTRACT_ADDRESS = _nerdsContractAddress;
          nerds = INuclearNerds(NERDS_CONTRACT_ADDRESS);

          enforcerTokenDetails.startTokenId = enforcerTokenDetails.currentTokenId = 9043;
          warlordTokenDetails.startTokenId = warlordTokenDetails.currentTokenId = 14050;

          raiderTokenDetails.currentBonusTokenId = 9000;
          raiderTokenDetails.maxBonusTokenId = 9042;

          for (uint256 i = 0; i < berserkerTokenIds.length;) {
            berserkersEligibleForClaim[berserkerTokenIds[i]] = true;
            unchecked {++i;}
          }
        }

    function mintFromBox(address recipient, uint256 amount) external {
      if (msg.sender != BOX_O_BAD_GUYS_CONTRACT_ADDRESS) revert InvalidCaller();
      _mint(enforcerTokenDetails, amount * 2, recipient);
      _mint(warlordTokenDetails, amount, recipient);
    }

    function claimRaiders(uint256[] calldata _tokenIds) external {
      if (!nerds.isOwnerOf(msg.sender, _tokenIds)) revert MustOwnMatchingNerd(); // See if balanceOf() is cheaper in loop below
      for (uint256 i = 0; i < _tokenIds.length;) {
        uint256 tokenId = _tokenIds[i];

        if (nerdHasClaimed[tokenId]) revert AlreadyClaimed();
        nerdHasClaimed[tokenId] = true;
        _mint(msg.sender, tokenId);

        if (berserkersEligibleForClaim[tokenId]) { //mint extra for berserkers
          if (raiderTokenDetails.currentBonusTokenId > raiderTokenDetails.maxBonusTokenId) revert AllBerserkersMinted();
          _mint(msg.sender, raiderTokenDetails.currentBonusTokenId);
          unchecked { 
            ++raiderTokenDetails.currentBonusTokenId;
            ++raiderTokenDetails.totalSupply;
          }
        }

        unchecked { 
          ++i;
          ++raiderTokenDetails.totalSupply;
        }
      }
    }

    function mintEnforcer(address recipient, uint256 amount) external {
      if (msg.sender != BOX_O_BAD_GUYS_CONTRACT_ADDRESS) revert InvalidCaller();
      _mint(enforcerTokenDetails, amount, recipient);
    }

    function mintWarlord(address recipient, uint256 amount) external {
      if (msg.sender != BOX_O_BAD_GUYS_CONTRACT_ADDRESS) revert InvalidCaller();
      _mint(warlordTokenDetails, amount, recipient);
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
      return string(abi.encodePacked(baseUri, _toString(id)));
    }

    function totalRaiderSupply() public view returns (uint256) {
      return raiderTokenDetails.totalSupply;
    }

    function totalEnforcerSupply() public view returns (uint256) {
      return enforcerTokenDetails.currentTokenId - enforcerTokenDetails.startTokenId;
    }

    function totalWarlordSupply() public view returns (uint256) {
      return warlordTokenDetails.currentTokenId - warlordTokenDetails.startTokenId;
    }

    function totalSupply() public view returns (uint256) {
      return totalRaiderSupply() + totalEnforcerSupply() + totalWarlordSupply();
    }

    function burn(uint256[] calldata tokenIds) external {
      for (uint256 i = 0; i < tokenIds.length;) {
        address from = ownerOf(tokenIds[i]);

        if (msg.sender != from && !isApprovedForAll[from][msg.sender] && msg.sender != getApproved[tokenIds[i]]) {
          revert InvalidCaller();
        }

        _burn(tokenIds[i]);
        unchecked { ++i; }
      }
    }

    /* ADMIN FUNCTIONS */

    function setBaseURI(string memory _uri) external onlyOwner {
      baseUri = _uri;
    }

    /* INTERNAL HELPERS */

    function _mint(MintableTokenDetails storage tokenDetails, uint256 amount, address recipient) internal {
      for (uint256 i = 0; i < amount;) {
        _mint(recipient, tokenDetails.currentTokenId);
        unchecked { 
          ++tokenDetails.currentTokenId;
          ++i; 
        }
      }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface INuclearNerds {
  function isOwnerOf(address account, uint256[] calldata _tokenIds) external view returns (bool);
  function ownerOf(uint256 tokenid) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

error InvalidProof();
error WrongValueSent();
error ExceedMaxSupply();
error ContractsUnset();
error ContractsAlreadySet();
error InvalidCaller();
error WrongEtherValueSent();
error TokenTypeSoldOut();
error MustOwnMatchingNerd();
error AllBerserkersMinted();
error AlreadyClaimed();
error ConsumerAlreadySet();
error MismatchedArrays();
error SaleNotActive();
error ArrayLengthMismatch();

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct MintableTokenDetails {
  uint16 startTokenId;
  uint16 currentTokenId;
}

struct ClaimableTokenDetails {
  uint16 totalSupply;
  uint16 currentBonusTokenId;
  uint16 maxBonusTokenId;
}

struct PhaseDetails {
  bytes32 root;
  uint64 startTime;
}

struct ItemDetails {
  uint16 numUnitsSold;
  uint16 maxUnitsAllowed;
  uint112 price;
  uint112 discountedPrice;
}