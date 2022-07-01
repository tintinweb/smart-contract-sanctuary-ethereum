// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "./ERC721s.sol";
import "./SignedAllowance.sol";

/// @title Angry Dolphins Sea Genesis
/// @author of the contract filio.eth (twitter.com/filmakarov)

contract ADSG is ERC721s, Ownable, SignedAllowance {  

using Strings for uint256;

    /*///////////////////////////////////////////////////////////////
                            GENERAL STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 private constant MAX_ITEMS = 300;

    string public baseURI;
    string private unrevealedURI;

    bool public revealState;
    bool public mintState;

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

    constructor(string memory _myBase, string memory _unrevBase) ERC721s("ANGRYDOLPHGEN0", "AD0") {
        baseURI = _myBase; 
        unrevealedURI = _unrevBase;
        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();      
    }

    function _startTokenIndex() internal pure override returns (uint256) {
        return 1;
    }

    /*///////////////////////////////////////////////////////////////
                        MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    
    function mint(address to, uint256 nonce, bytes memory signature) public {
        require (mintState, "Mint not active");

        //_mintQty is stored in the right-most 128 bits of the nonce
        uint256 qty = uint256(uint128(nonce));
 
        require(totalMinted() + qty <= MAX_ITEMS, ">MaxSupply");
        
        // this will throw if the allowance has already been used or is not valid
        _useAllowance(to, nonce, signature);

        _safeMint(to, qty); 
    }

    function adminMint(address to, uint256 qty) public onlyOwner {
        require(totalMinted() + qty <= MAX_ITEMS, ">MaxSupply");
        _safeMint(to, qty);
    }

     /*///////////////////////////////////////////////////////////////
                       LOCKING LOGIC (ERC721S)
    //////////////////////////////////////////////////////////////*/
        
    function lock(address unlocker, uint256 id) public {
        address tokenOwner = ownerOf(id);
        require(msg.sender == tokenOwner || msg.sender == getApproved[id] || isApprovedForAll[tokenOwner][msg.sender]
        , "NOT_AUTHORIZED");
        require(getLocked[id] == address(0), "ALREADY_LOCKED"); 
        _lock(unlocker, id);
    }

    function unlock(uint256 id) public {
        require(msg.sender == getLocked[id], "NOT_UNLOCKER");
        _unlock(id);
    }

    /*///////////////////////////////////////////////////////////////
                            EIP-2612-LIKE LOGIC
    //////////////////////////////////////////////////////////////*/
    
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

            //signature is good, now should check if signer had rights to approve this token
            require(signer == ownerOfToken || isApprovedForAll[ownerOfToken][signer], "INVALID_SIGNER"); 
        }
        
        getApproved[tokenId] = spender;

        emit Approval(ownerOfToken, spender, tokenId);
    }

    // having permit for all can make purchases cheaper for buyers in future, when marketplace can consume only one 
    // permitAll from buyer to all the tokens from given collection, and all next orders won't need to call permit() 
    // for every new token purchase, so buyers won't pay gas for that call
    // this can be more dangerous for seller btw, to approve All of his tokens to the marketplace instead of per token approvals
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
        isApprovedForAll[signer][operator] = true;

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

    /*///////////////////////////////////////////////////////////////
                       PUBLIC METADATA VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the link to the metadata for the token
    /// @param tokenId token ID
    /// @return string with the link
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "NOT_EXISTS");
        if (revealState) {
            return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
        } else {
            return unrevealedURI;
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

    /*///////////////////////////////////////////////////////////////
                       ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function switchMintState() public onlyOwner {
        mintState = !mintState;
    }

    function setRevealState(bool _revealState) public onlyOwner {
        revealState = _revealState;
    }
    
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setUnrevURI(string memory _newUnrevURI) public onlyOwner {
        unrevealedURI = _newUnrevURI;
    }

    /// @notice sets allowance signer, this can be used to revoke all unused allowances already out there
    /// @param newSigner the new signer
    function setAllowancesSigner(address newSigner) external onlyOwner {
        _setAllowancesSigner(newSigner);
    }

    /*///////////////////////////////////////////////////////////////
                       ERC721Receiver interface compatibility
    //////////////////////////////////////////////////////////////*/

    function onERC721Received(
    address, 
    address, 
    uint256, 
    bytes calldata
    ) external pure returns(bytes4) {
        return bytes4(keccak256("I do not receive ERC721"));
    } 

}

//   That's all, folks!

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

/// @title ERC721s
/// @notice Improvement to ERC721 standard, that introduces lockable NFTs. 
/// @notice Based on Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @notice The concept of recording only the first owner for the batch taken from ERC721A standard by Chiru Labs
/// @author filio.eth (https://twitter.com/filmakarov)

abstract contract ERC721s {
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
    mapping(uint256 => address) public owners;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    mapping(uint256 => bool) public isBurned;
    uint256 public burnedCounter;

    mapping(address => uint256) internal _balanceOf;

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*///////////////////////////////////////////////////////////////
                            ERC721s STORAGE                        
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getLocked;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        nextTokenIndex = _startTokenIndex();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721s LOGIC
    //////////////////////////////////////////////////////////////*/
    
    function _lock(address unlocker, uint256 id) internal virtual {
        getLocked[id] = unlocker;
    }

    function _unlock(uint256 id) internal virtual {
        getLocked[id] = address(0);
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf(id);

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
        
        require(from == ownerOf(id), "WRONG_FROM");
        require(to != address(0), "INVALID_RECIPIENT");

        // token should not be locked or msg sender should be unlocker
        require(getLocked[id] == address(0) || msg.sender == getLocked[id], "LOCKED");

        // msg.sender should be authorized to transfer
        // i.e. msg.sender should be owner, approved or unlocker
        require(
            msg.sender == getLocked[id] || msg.sender == from || 
            msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender], 
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;
            _balanceOf[to]++;
        }

        owners[id] = to;
        uint256 nextId = id+1;

        //to prevent new owner to become the owner of next tokens in the batch 
        if (owners[nextId] == address(0)) {  //if that was not the last token of batch
            if (_exists(nextId)) { //and the next token exists (was minted) and has not been burned
                owners[nextId] = from; //explicitly set the owner for that token
            }
        }

        delete getApproved[id];
        delete getLocked[id];

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

    function _exists(uint256 id) internal view returns (bool) {
        return (id < nextTokenIndex && !isBurned[id] && id >= _startTokenIndex());
    }

    function totalSupply() public view returns (uint256) {
        return totalMinted() - burnedCounter;
    }

    function totalMinted() public view returns (uint256) {
        return nextTokenIndex - _startTokenIndex();
    }

    /*///////////////////////////////////////////////////////////////
                              CUSTOM OwnerOf FOR BATCH MINTING
    //////////////////////////////////////////////////////////////*/

    function ownerOf(uint256 id) public view returns (address) {
        require(_exists(id), "NOT_MINTED_YET_OR_BURNED");

        unchecked {
            for (uint256 curr = id; curr >=0; curr--) {
                if (owners[curr] != address(0)) {
                    return owners[curr];
                }
            }
        }

        revert('ERC721A: unable to determine the owner of token');
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

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     * Inspired by ERC721A
     */
    function _startTokenIndex() internal view virtual returns (uint256) {
        return 0;
    }

    function _mint(address to, uint256 qty) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");
        require(qty != 0, "CAN_NOT_MINT_0");

        uint256 startTokenIndex = nextTokenIndex;

        // put just the first owner in the batch
        owners[nextTokenIndex]=to;

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
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf(id);
        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }
        delete owners[id];
        isBurned[id] = true;
        burnedCounter++;

        uint256 nextId = id+1;
        if (owners[nextId] == address(0)) {  //if that was not the last token of batch
            if (_exists(nextId)) { //and the next token exists (was minted) and has not been burned
                owners[nextId] = owner; //explicitly set the owner for that token
            }
        }

        delete getApproved[id];
        delete getLocked[id];

        emit Transfer(owner, address(0), id);
    }
    

    /*///////////////////////////////////////////////////////////////
                       INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 qty) internal virtual {
        _mint(to, qty);
        
        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), nextTokenIndex-qty, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
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
            "UNSAFE_RECIPIENT"
        );
    }

}

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

/// @title SignedAllowance
/// @author Simon Fremaux (@dievardump)
contract SignedAllowance {
    using ECDSA for bytes32;

    // list of already used allowances
    mapping(bytes32 => bool) public usedAllowances;

    // address used to sign the allowances
    address private _allowancesSigner;

    /// @notice Helper to know allowancesSigner address
    /// @return the allowance signer address
    function allowancesSigner() public view virtual returns (address) {
        return _allowancesSigner;
    }

    /// @notice Helper that creates the message that signer needs to sign to allow a mint
    ///         this is usually also used when creating the allowances, to ensure "message"
    ///         is the same
    /// @param account the account to allow
    /// @param nonce the nonce
    /// @return the message to sign
    function createMessage(address account, uint256 nonce)
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encode(account, nonce, address(this)));
    }

    /// @notice Helper that creates a list of messages that signer needs to sign to allow mintings
    /// @param accounts the accounts to allow
    /// @param nonces the corresponding nonces
    /// @return messages the messages to sign
  /*  
    // function is commented out to save space in the contract
    // to batch create message will need to use for loop with the createMessage function

    function createMessages(address[] memory accounts, uint256[] memory nonces)
        external
        view
        returns (bytes32[] memory messages)
    {
        require(accounts.length == nonces.length, '!LENGTH_MISMATCH!');
        messages = new bytes32[](accounts.length);
        for (uint256 i; i < accounts.length; i++) {
            messages[i] = createMessage(accounts[i], nonces[i]);
        }
    } */

    /// @notice This function verifies that the current request is valid
    /// @dev It ensures that _allowancesSigner signed a message containing (account, nonce, address(this))
    ///      and that this message was not already used
    /// @param account the account the allowance is associated to
    /// @param nonce the nonce associated to this allowance
    /// @param signature the signature by the allowance signer wallet
    /// @return the message to mark as used
    function validateSignature(
        address account,
        uint256 nonce,
        bytes memory signature
    ) public view returns (bytes32) {
        return
            _validateSignature(account, nonce, signature, allowancesSigner());
    }

    /// @dev It ensures that signer signed a message containing (account, nonce, address(this))
    ///      and that this message was not already used
    /// @param account the account the allowance is associated to
    /// @param nonce the nonce associated to this allowance
    /// @param signature the signature by the allowance signer wallet
    /// @param signer the signer
    /// @return the message to mark as used
    function _validateSignature(
        address account,
        uint256 nonce,
        bytes memory signature,
        address signer
    ) internal view returns (bytes32) {
        bytes32 message = createMessage(account, nonce)
            .toEthSignedMessageHash();

        // verifies that the sha3(account, nonce, address(this)) has been signed by signer
        require(message.recover(signature) == signer, '!INVALID_SIGNATURE!');

        // verifies that the allowances was not already used
        require(usedAllowances[message] == false, '!ALREADY_USED!');

        return message;
    }

    /// @notice internal function that verifies an allowance and marks it as used
    ///         this function throws if signature is wrong or this nonce for this user has already been used
    /// @param account the account the allowance is associated to
    /// @param nonce the nonce
    /// @param signature the signature by the allowance wallet
    function _useAllowance(
        address account,
        uint256 nonce,
        bytes memory signature
    ) internal {
        bytes32 message = validateSignature(account, nonce, signature);
        usedAllowances[message] = true;
    }

    /// @notice Allows to change the allowance signer. This can be used to revoke any signed allowance not already used
    /// @param newSigner the new signer address
    function _setAllowancesSigner(address newSigner) internal {
        _allowancesSigner = newSigner;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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