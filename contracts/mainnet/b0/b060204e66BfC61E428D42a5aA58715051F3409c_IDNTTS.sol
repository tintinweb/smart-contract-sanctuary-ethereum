/*

█ ██ |██|█ |█| █
█ ██ |██|█ |█| █
█ ██ |██|█ |█| █
     IDNTTS

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721S/ERC721SLockablePermittable.sol";
import "./ERC2981/ERC2981ContractWideRoyalties.sol";
import "./Base64.sol";

/// @title IDNTTS Project. Featuring Lockable extension by IDNTTS Labs
/// @dev   Check https://github.com/filmakarov/erc721s for details on Lockable NFTs        
/// @author of the contract filio.eth (twitter.com/filmakarov)

contract IDNTTS is ERC721SLockablePermittable, Ownable, ERC2981ContractWideRoyalties {  

    using Strings for uint256;

    /*///////////////////////////////////////////////////////////////
                                GENERAL STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public constant MAX_ITEMS = 10000;

    address private minterAddress;
    
    mapping (bool => string) private baseURI;
    string private unrevealedURI;
    string private metadataExtension = ".json";

    string public provenanceHash;

    bool public revealState;

    constructor(string memory _myBaseUnlocked, string memory _myBaseLocked, string memory _unrevBase) ERC721S("IDNTTS", "IDS") {
            baseURI[true] = _myBaseUnlocked;
            baseURI[false] = _myBaseLocked; 
            unrevealedURI = _unrevBase;    
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721SLockablePermittable, ERC2981ContractWideRoyalties)
        returns (bool)
    {
        return ERC721SLockablePermittable.supportsInterface(interfaceId) || 
               ERC2981ContractWideRoyalties.supportsInterface(interfaceId);
    }

    /*///////////////////////////////////////////////////////////////
                        MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function mint(address to, uint256 qty) public {
        require (msg.sender == minterAddress, "Not allowed to mint");
        require(totalMinted() + qty <= MAX_ITEMS, ">MaxSupply");

        _safeMint(to, qty);
    }

    /*///////////////////////////////////////////////////////////////
                       PUBLIC VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the link to the metadata for the token
    /// @param tokenId token ID
    /// @return string with the link
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "NOT_EXISTS");
        if (revealState) {
            return string(abi.encodePacked(baseURI[getLocked(tokenId) == address(0)], tokenId.toString(), metadataExtension));
        } else {
            string memory json = string(abi.encodePacked('{"name": "IDNTTS #', tokenId.toString(), '", "description": "IDNTTS is the only 10k free mint with real utility. Artistic & technological innovation. We are crazy but free!", "image": "',unrevealedURI,'","attributes": [{"trait_type": "Revealed", "value": "No"}]}'));
            return string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(json))));
        }
    }

    /// @notice Iterates over all the exisitng tokens and checks if they belong to the user
    /// This function uses very much resources.
    /// !!! NEVER USE this function with write transactions DIRECTLY. 
    /// Only read from it and then pass data to the write tx
    /// @param tokenOwner user to get tokens of
    /// @return the array of token IDs 
    function tokensOfOwner(address tokenOwner) external view returns(uint256[] memory) {
        uint256 tokenCount = _balanceOf[tokenOwner];
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 resultIndex = 0;
            uint256 NFTId;
            for (NFTId = _startTokenIndex(); NFTId < nextTokenIndex; NFTId++) { 
                if (_exists(NFTId)&&(ownerOf(NFTId) == tokenOwner)) {  
                    result[resultIndex] = NFTId;
                    resultIndex++;
                } 
            }     
            return result;
        }
    }

    function unclaimedSupply() public view returns (uint256) {
        return MAX_ITEMS - totalMinted();
    }

    function getTokenTimestamp(uint256 tokenId) public view returns (uint256) {
        return uint256(_packedOwnerships[tokenId] >> 160);
    }

    /*///////////////////////////////////////////////////////////////
                       CUSTOM LOCKING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Can not lock tokens before the reveal
    function lock(address unlocker, uint256 id) public override {
        require(revealState, "CANT_LOCK_BEFORE_REVEAL");
        ERC721SLockable.lock(unlocker, id);
    }

    /*///////////////////////////////////////////////////////////////
                       ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setMinter(address _newMinter) public onlyOwner {
        minterAddress = _newMinter;
    }

    function setRevealState(bool _revealState) public onlyOwner {
        revealState = _revealState;
    }
    
    function setBaseURI(string memory _newBaseUnlocked, string memory _newBaseLocked) public onlyOwner {
        baseURI[true] = _newBaseUnlocked;
        baseURI[false] = _newBaseLocked;
    }

    function setUnrevURI(string memory _newUnrevURI) public onlyOwner {
        unrevealedURI = _newUnrevURI;
    }

    function setMetadataExtension(string memory _newMDExt) public onlyOwner {
        metadataExtension = _newMDExt;
    }

    function setProvenanceHash(string memory _newPH) public onlyOwner {
        if (bytes(provenanceHash).length == 0) {
            provenanceHash = _newPH;
        } else {
            revert("Provenance hash already set");
        }
    }

    /// @notice Allows to set the royalties on the contract
    /// @dev See ERC2981ContractWideRoyalties.sol
    /// @param recipient the royalties recipient
    /// @param value royalties value (between 0 and 10000)
    function setRoyalties(address recipient, uint256 value) public onlyOwner {
        _setRoyalties(recipient, value);
    }

}

//   That's all, folks!

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "./ERC721SLockable.sol";

/// @title ERC721S Extension with EIP2612-like permits
/// @dev   Implements EIP4494 and additionally permitAll

abstract contract ERC721SLockablePermittable is ERC721SLockable {  

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == 0x5604e225 ||           // _INTERFACE_ID_ERC4494 = 0x5604e225
            super.supportsInterface(interfaceId);
    }

    /*///////////////////////////////////////////////////////////////
                            EIP-2612-LIKE STORAGE
    //////////////////////////////////////////////////////////////*/
    
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");

    bytes32 public constant PERMIT_ALL_TYPEHASH = 
        keccak256("Permit(address operator,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(uint256 => uint256) public nonces;

    mapping(address => mapping(address => uint256)) public noncesForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();      
    }

    /*///////////////////////////////////////////////////////////////
                            EIP-2612-LIKE LOGIC
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @dev Uses the permit to approve one token for spender
     */

    function permit(
        address signer,
        address spender,
        uint256 tokenId,
        uint256 deadline,
        bytes memory sig
    ) public virtual {
        require(block.timestamp <= deadline, "PERMIT_DEADLINE_EXPIRED");
        
        address ownerOfToken = ownerOf(tokenId);
        
        // Unchecked because the only math done is incrementing
        // the nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, spender, tokenId, nonces[tokenId]++, deadline))
                )
            );

            require(SignatureChecker.isValidSignatureNow(signer, digest, sig), "INVALID_SIGNATURE");

            // Signature is good, now should check if signer had rights to approve this token
            // Like, only owner or operator can user approve functions, 
            // only owner or operator can sign permits for approval. 
            require(signer == ownerOfToken || isApprovedForAll(ownerOfToken, signer), "INVALID_SIGNER"); 
        }
        
        _tokenApprovals[tokenId] = spender;

        emit Approval(ownerOfToken, spender, tokenId);
    }

    /**
     * @dev Uses the permit to approve all the tokens owned by signer for the operator
     * 
     * Having permit for all can make purchases cheaper for buyers in future, when marketplace can consume only one 
     * permitAll from buyer to all the tokens from given collection, and all next orders won't need to call permit() 
     * for every new token purchase, so buyers won't pay gas for that call
     * this can be more dangerous for seller btw, to approve All of his tokens to the marketplace instead of per token approvals
     */
     
    function permitAll(
        address signer,
        address operator,
        uint256 deadline,
        bytes memory sig
    ) public virtual {
        require(block.timestamp <= deadline, "PERMIT_DEADLINE_EXPIRED");
        
        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_ALL_TYPEHASH, operator, noncesForAll[signer][operator]++, deadline))
                )
            );

            require(SignatureChecker.isValidSignatureNow(signer, digest, sig), "INVALID_SIGNATURE");
        }
        
        // no need to check any kind of ownerships because we always approve operator on behalf of signer,
        // not on behalf of any other owner
        // that does not allow current operators to make isApprovedForAll[owner][one_more_operator] = true
        // but current operator can still aprove explicit tokens with permit(), that is enough I guess
        // and better for security
        _operatorApprovals[signer][operator] = true;

        emit ApprovalForAll(signer, operator, true);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32 domainSeparator) {
        domainSeparator = block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32 domainSeparator) {
        domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

}

//   That's all, folks!

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import './IERC2981Royalties.sol';

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
/// @dev This implementation has the same royalties for each and every tokens
abstract contract ERC2981ContractWideRoyalties is IERC2981Royalties {

    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Royalties).interfaceId;
    }

    RoyaltyInfo private _royalties;

    /// @dev Sets token royalties
    /// @param recipient recipient of the royalties
    /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function _setRoyalties(address recipient, uint256 value) internal {
        require(value <= 10000, 'ERC2981Royalties: Too high');
        _royalties = RoyaltyInfo(recipient, uint24(value));
    }

    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalties = _royalties;
        receiver = royalties.recipient;
        royaltyAmount = (value * royalties.amount) / 10000;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import './ERC721S.sol';
import './IERC721Lockable.sol';

/// @title Lockable Extension for ERC721S implementation of ERC721 Standard
/// @author filio.eth (https://twitter.com/filmakarov)
/// @dev Check the repo and readme at https://github.com/filmakarov/erc721s 

abstract contract ERC721SLockable is ERC721S, IERC721Lockable {

    /*///////////////////////////////////////////////////////////////
                            LOCKABLE EXTENSION STORAGE                        
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal unlockers;

    /*///////////////////////////////////////////////////////////////
                              LOCKABLE LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Public function to lock the token. Verifies if the msg.sender is the owner
     *      or approved party.
     */

    function lock(address unlocker, uint256 id) public virtual {
        address tokenOwner = ownerOf(id);
        require(msg.sender == tokenOwner || isApprovedForAll(tokenOwner, msg.sender)
        , "Locking: not auhorized to lock");
        require(unlockers[id] == address(0), "Locking: Token is already locked"); 
        unlockers[id] = unlocker;
        super.approve(unlocker, id); //approve unlocker, so unlocker will be able to transfer
    }

    /**
     * @dev Public function to unlock the token. Only the unlocker (stated at the time of locking) can unlock
     */
    function unlock(uint256 id) public virtual {
        require(msg.sender == unlockers[id], "Locking: Not allowed to unlock");
        unlockers[id] = address(0);
    }

    /**
     * @dev Returns the unlocker for the tokenId
     *      address(0) means token is not locked
     *      reverts if token does not exist
     */
    function getLocked(uint256 tokenId) public virtual view returns (address) {
        require(_exists(tokenId), "Lockable: locking query for nonexistent token");
        return unlockers[tokenId];
    }

    /**
     * @dev Locks the token
     */
    function _lock(address unlocker, uint256 id) internal virtual {
        unlockers[id] = unlocker;
    }

    /**
     * @dev Unlocks the token
     */
    function _unlock(uint256 id) internal virtual {
        unlockers[id] = address(0);
    }

    /*///////////////////////////////////////////////////////////////
                              OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function approve(address to, uint256 tokenId) public virtual override {
        require (getLocked(tokenId) == address(0), "Can not approve locked token"); // so the unlocker stays approved
        super.approve(to, tokenId);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        // if it is a Transfer or Burn, we always deal with one token, that is startTokenId
        if (from != address(0)) { 
            // token should not be locked or msg.sender should be unlocker to do that
            require(getLocked(startTokenId) == address(0) || msg.sender == getLocked(startTokenId), "Lockable: token is locked");
        }
    }

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        // if it is a Transfer or Burn, we always deal with one token, that is startTokenId
        if (from != address(0)) { 
            // clear locks
            delete unlockers[startTokenId];
        }
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721Lockable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title ERC721s
/// @notice Custom ERC721. Batch minting. Timestamps for ownerships. 
///         Inspiration: ERC721A by Chiru Labs, Solmate by Rari Capital
/// @author filio.eth (https://twitter.com/filmakarov)
/// @dev Check the repo and readme at https://github.com/filmakarov/erc721s 

abstract contract ERC721S {

    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _id);

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

    uint256 public nextTokenIndex;
    mapping(uint256 => uint256) internal _packedOwnerships;
    mapping(uint256 => address) internal _tokenApprovals;
    mapping(address => mapping(address => bool)) internal _operatorApprovals;
    mapping(address => uint256) internal _balanceOf;
    mapping(uint256 => bool) public isBurned;
    uint256 public burnedCounter;

    uint256 private constant ADDRESS_BITMASK = (1 << 160) - 1;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        nextTokenIndex = _startTokenIndex();
    }

    /*///////////////////////////////////////////////////////////////
                              APPROVALS LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf(id);
        require(msg.sender == owner || _operatorApprovals[owner][msg.sender], "ERC721S: Not authorized to approve");
        _tokenApprovals[id] = spender;
        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenId) public view virtual returns (address) {
        require(_exists(tokenId), "ERC721S: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /*///////////////////////////////////////////////////////////////
                              OWNERSHIPS
    //////////////////////////////////////////////////////////////*/

    function _exists(uint256 id) internal view returns (bool) {
        return (id < nextTokenIndex && !isBurned[id] && id >= _startTokenIndex());
    }

    function ownerOf(uint256 id) public view returns (address) {
        return address(uint160( _packedOwnershipOf(id) ));
    }

    function _packedOwnershipOf(uint256 id) internal view returns (uint256) {
        if (id >= _startTokenIndex()) {
            if (id<nextTokenIndex) {
                if (!isBurned[id]) { 
                    uint256 curr = id;
                    unchecked {
                        uint256 packed = _packedOwnerships[curr];
                        
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
            }
        }
        revert('ERC721S: Token does not exist');
    }

    function _packOwnership(address owner) internal virtual returns (uint256 result) {
        assembly {
            owner := and(owner, ADDRESS_BITMASK)
            result := or(owner, shl(160, timestamp()))
        }
    }

    /*///////////////////////////////////////////////////////////////
                              TRANSFERS LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {

        uint256 prevOwnership = _packedOwnershipOf(id);
        
        require(from == address(uint160(prevOwnership)), "ERC721S: From is not the owner");
        require(to != address(0), "ERC721S: Can not transfer to 0 address");

        // msg.sender should be authorized to transfer
        // i.e. msg.sender should be owner, approved or unlocker
        require(
            msg.sender == from || 
            msg.sender == getApproved(id) || isApprovedForAll(from, msg.sender), 
            "ERC721S: Not authorized to transfer"
        );

        _beforeTokenTransfers(from, to, id, 1);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;
            _balanceOf[to]++;
        }

        _packedOwnerships[id] = _packOwnership(to);

        uint256 nextId = id+1;

        if (_exists(nextId)) {
            // _packedOwnerships[nextId] == 0 is true only if the token ownership has not been initialized
            // burned token has non-zero ownership and if it was burned, the next token after burned one
            // was initialized 
            if (_packedOwnerships[nextId] == 0) {
                _packedOwnerships[nextId] = prevOwnership;
            }
        }     

        delete _tokenApprovals[id];

        emit Transfer(from, to, id);
        _afterTokenTransfers(from, to, id, 1);
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
            "ERC721S: Transfer to unsafe recepient"
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
            "ERC721S: Transfer to unsafe recepient"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              Views
    //////////////////////////////////////////////////////////////*/

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ERC721S: BalanceOf query for zero address");
        return _balanceOf[owner];
    }

    function totalSupply() public view returns (uint256) {
        return totalMinted() - burnedCounter;
    }

    function totalMinted() public view returns (uint256) {
        return nextTokenIndex - _startTokenIndex();
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     * Inspired by ERC721A
     */
    function _startTokenIndex() internal view virtual returns (uint256) {
        return 0;
    }

    function _mint(address to, uint256 qty) internal virtual {
        require(to != address(0), "ERC721S: Can not mint to 0 address");
        require(qty != 0, "ERC721S: Can not mint 0 tokens");

        uint256 startTokenIndex = nextTokenIndex;

        _beforeTokenTransfers(address(0), to, startTokenIndex, qty);

        // put just the first owner in the batch
        _packedOwnerships[nextTokenIndex] = _packOwnership(to);

        // Counter overflow is incredibly unrealistic here.
        unchecked {
                nextTokenIndex += qty;
            }
          
        //balanceOf change thru assembly
        assembly {
            mstore(0, to)
            mstore(32, _balanceOf.slot)
            let hash := keccak256(0, 64)
            sstore(hash, add(sload(hash), qty))
        } 

        for (uint256 i=startTokenIndex; i<nextTokenIndex; i++) {
            emit Transfer(address(0), to, i);
        }

        _afterTokenTransfers(address(0), to, startTokenIndex, qty);
        
    }

    function _safeMint(address to, uint256 qty) internal virtual {
        _mint(to, qty);
        
        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), nextTokenIndex-qty, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "ERC721S: Mint to unsafe recepient"
        );
    }

    function _safeMint(
        address to,
        uint256 qty,
        bytes memory data
    ) internal virtual {
        _mint(to, qty);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), nextTokenIndex-qty, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "ERC721S: Mint to unsafe recepient"
        );
    }

    /*///////////////////////////////////////////////////////////////
                       BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _burn(uint256 id) internal virtual {
        
        address owner = ownerOf(id);
        uint256 prevOwnership = _packedOwnershipOf(id);

        _beforeTokenTransfers(owner, address(0), id, 1);

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }
        
        _packedOwnerships[id] = _packOwnership(address(0)); // thus we have time of burning the token

        isBurned[id] = true;
        burnedCounter++;

        uint256 nextId = id+1;
        if (_packedOwnerships[nextId] == 0) {  //if that was not the last token of batch
            if (_exists(nextId)) { //and the next token exists (was minted) and has not been burned
                _packedOwnerships[nextId] = prevOwnership; //explicitly set the owner for that token
            }
        }
        
        delete _tokenApprovals[id];

        emit Transfer(owner, address(0), id);
        _afterTokenTransfers(owner, address(0), id, 1);
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                              HOOKS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

}

/*///////////////////////////////////////////////////////////////
                              TOKEN RECEIVER
//////////////////////////////////////////////////////////////*/

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title ILockable
/// @dev Interface for the Lockable extension
/// @author filio.eth 

interface IERC721Lockable {

    /**
     * @dev Emitted when `id` token is locked, and `unlocker` is stated as unlocking wallet.
     */
    event Lock (address indexed unlocker, uint256 indexed id);

    /**
     * @dev Emitted when `id` token is unlocked.
     */
    event Unlock (uint256 indexed id);

    /**
     * @dev Locks the `id` token and states `unlocker` wallet as unlocker.
     */
    function lock(address unlocker, uint256 id) external;

    /**
     * @dev Unlocks the `id` token.
     */
    function unlock(uint256 id) external;

    /**
     * @dev Returns the wallet, that is stated as unlocking wallet for the `tokenId` token.
     * If address(0) returned, that means token is not locked. Any other result means token is locked.
     */
    function getLocked(uint256 tokenId) external view returns (address);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
}