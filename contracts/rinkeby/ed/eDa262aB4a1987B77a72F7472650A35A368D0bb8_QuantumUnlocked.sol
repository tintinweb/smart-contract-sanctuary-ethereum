// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {ERC721 as ERC721S} from "@rari-capital/solmate/src/tokens/ERC721.sol";
import "@rari-capital/solmate/src/auth/Auth.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC2981V2.sol";


/// @title The Quantum Unlocked. Speciality drops for the quantum keys are released here
/// @author jcbdev
contract QuantumUnlocked is ERC721S, ERC2981, Auth {
    using Strings for uint256;
    using BitMaps for BitMaps.BitMap;

    /// >>>>>>>>>>>>>>>>>>>>>>>  EVENTS  <<<<<<<<<<<<<<<<<<<<<<<<<< ///

    event DropMint(address indexed to, uint256 indexed dropId, uint256 indexed variant, uint256 id);

    /// >>>>>>>>>>>>>>>>>>>>>>>  STATE  <<<<<<<<<<<<<<<<<<<<<<<<<< ///

    mapping (uint128 => string) public dropCID;
    mapping (uint128 => uint128) public dropSupply;
    mapping (uint256 => uint256) public tokenVariant;
    // mapping (uint256 => mapping(uint256 => uint256)) variantDropSupply;

    string private _baseURI = "https://core-api.quantum.art/v1/metadata/unlocked/";
    string private _ipfsURI = "ipfs://";
    address private _minter;

    /// >>>>>>>>>>>>>>>>>>>>>  CONSTRUCTOR  <<<<<<<<<<<<<<<<<<<<<< ///

	/// @notice Deploys QuantumUnlocked
    /// @dev Initiates the Auth module with no authority and the sender as the owner
    /// @param owner The owner of the contract
    /// @param authority address of the deployed authority
    constructor(address owner, address authority) ERC721S("QuantumUnlocked", "QKU") Auth(owner, Authority(authority)) {
        _baseURI = "https://core-api.quantum.art/v1/metadata/unlocked/";
        _ipfsURI = "ipfs://";
    }

    /// >>>>>>>>>>>>>>>>>>>>>  INTERNAL  <<<<<<<<<<<<<<<<<<<<<< ///
    /// @notice get the token id from the drop id and sequence number
    /// @param dropId The drop id
    /// @param sequence the sequence number of the minted token within the drop 
    /// @return tokenId the combined token id 
    function _tokenId(uint128 dropId, uint128 sequence) internal pure returns (uint256 tokenId) {
        tokenId |= uint256(dropId) << 128;
        tokenId |= uint256(sequence);
        return tokenId;
    }

    /// @notice extract the drop id and the sequence number from the token id
    /// @param tokenId The token id to extract the values from
    /// @return uint128 the drop id
    /// @return uint128 the sequence number
    function _splitTokenId(uint256 tokenId) internal pure returns (uint128, uint128) {
        return (uint128(tokenId >> 128), uint128(tokenId));
    }

    /// >>>>>>>>>>>>>>>>>>>>>  RESTRICTED  <<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice set address of the minter
    /// @param minter The address of the minter - should be Sales Platform
    function setMinter(address minter) public requiresAuth {
        _minter = minter;
    }

    /// @notice set the baseURI
    /// @param baseURI new base
    function setBaseURI(string calldata baseURI) public requiresAuth {
        _baseURI = baseURI;
    }

    /// @notice set the base ipfs URI
    /// @param ipfsURI new base
    function setIpfsURI(string calldata ipfsURI) public requiresAuth {
        _ipfsURI = ipfsURI;
    }

    /// @notice set the IPFS CID
    /// @param dropId The drop id
    /// @param cid cid
    function setCID(uint128 dropId, string calldata cid) public requiresAuth {
        dropCID[dropId] = cid;
    }

    /// @notice sets the recipient of the royalties
    /// @param recipient address of the recipient
    function setRoyaltyRecipient(address recipient) public requiresAuth {
        _royaltyRecipient = recipient;
    }

    /// @notice sets the fee of royalties
    /// @dev The fee denominator is 10000 in BPS.
    /// @param fee fee
    /*
        Example

        This would set the fee at 5%
        ```
        KeyUnlocks.setRoyaltyFee(500)
        ```
    */
    function setRoyaltyFee(uint256 fee) public requiresAuth {
        _royaltyFee = fee;
    }

    /// @notice Mints new tokens
    /// @dev there is no check regarding limiting supply
    /// @param to recipient of newly minted tokens
    /// @param dropId id of the key
    function mint(address to, uint128 dropId, uint256 variant) public returns (uint256) {
        require(msg.sender == owner || msg.sender == _minter, "NOT_AUTHORIZED");

        dropSupply[dropId] += 1;
        uint256 tokenId = _tokenId(dropId, uint128(dropSupply[dropId]));
        _safeMint(to, tokenId);
        if (variant > 0) {
            tokenVariant[tokenId] = variant;
            // variantDropSupply[variant][dropId]++;
        }
        emit DropMint(to, dropId, variant, tokenId);
        return tokenId;
    }

    /// @notice Burns token that has been redeemed for something else
    /// @dev Sales platform only
    /// @param tokenId id of the tokens
    function redeemBurn(uint256 tokenId) public requiresAuth {
        _burn(tokenId);
    }

    /// >>>>>>>>>>>>>>>>>>>>>  VIEW  <<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice Returns the URI of the token
    /// @param tokenId id of the token
    /// @return URI for the token ; expected to be ipfs://<cid>
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        (uint128 dropId, uint128 sequenceNumber) = _splitTokenId(tokenId);
        uint256 actualSequence = tokenVariant[tokenId] > 0 ? tokenVariant[tokenId] : sequenceNumber;
        if (bytes(dropCID[dropId]).length > 0)
            return string(abi.encodePacked(_ipfsURI, dropCID[dropId], "/" , actualSequence.toString()));
        else
            return string(abi.encodePacked(_baseURI, dropCID[dropId], "/" , actualSequence.toString()));
    }

    // function variantSupply(uint256 dropId, uint256 variant) public view returns (uint256) {
    //     return variantDropSupply[variant][dropId];
    // }

    /// >>>>>>>>>>>>>>>>>>>>>  EXTERNAL  <<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice Burns token
    /// @dev Can be called by the owner or approved operator
    /// @param tokenId id of the tokens
    function burn(uint256 tokenId) public {
        address owner = ownerOf[tokenId];
        require(
            msg.sender == owner || msg.sender == getApproved[tokenId] || isApprovedForAll[owner][msg.sender],
            "NOT_AUTHORIZED"
        );
        _burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual override(ERC721S, ERC2981) returns (bool) {
        return ERC721S.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
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

pragma solidity >=0.8.0;

/// @title Minimalist ERC2981 implementation.
/// @notice To be used within Quantum, as it was written for its needs.
/// @author exp.table
abstract contract ERC2981 {

    /// @dev one global fee for all royalties.
    uint256 internal _royaltyFee;
    /// @dev one global recipient for all royalties.
    address internal _royaltyRecipient;

    function royaltyInfo(uint256 tokenId, uint256 salePrice) public view virtual returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        receiver = _royaltyRecipient;
        royaltyAmount = (salePrice * _royaltyFee) / 10000;
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x2a55205a; // ERC165 Interface ID for ERC2981
    }

}