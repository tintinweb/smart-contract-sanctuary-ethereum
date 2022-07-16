// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './interface/IYoMinter.sol';
import './interface/ERC1238/ERC1238.sol';
import './interface/ERC1238/extensions/ERC1238URIStorage.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@appliedzkp/semaphore-contracts/base/SemaphoreCore.sol';
import '@appliedzkp/semaphore-contracts/interfaces/IVerifier.sol';


/// @title YoNFTMinter
contract YoMinter is IYoMinter, SemaphoreCore, ERC1238, ERC1238URIStorage, Ownable {

    /************************************************
     *  Library & Variables  
     ***********************************************/
  
    using Counters for Counters.Counter;

    IVerifier private verifier;
    Counters.Counter private supplyCounter;


    /************************************************
     *  Constructor
     ***********************************************/

    constructor(address verifierAddress, string memory baseURI_) ERC1238(baseURI_) {
        verifier = IVerifier(verifierAddress);
    }

    /************************************************
     *  NFT OPERATIONS
     ***********************************************/

    function totalSupply() public view returns (uint256) {
        return supplyCounter.current();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1238, ERC1238URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _setBaseURI(newBaseURI);
    }

    /************************************************
     *  Mint NFT
     ***********************************************/
    
    /// @dev See {IContinuum-mint}.
    function mint(
        uint256 root,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof,
        string memory tokenURI,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes memory data
    ) external override {
        bytes32 signal = bytes32('continuum');
        _verifyProof(signal, root, nullifierHash, externalNullifier, proof, verifier);

        // Prevent double-signaling (nullifierHash = hash(groupId + identityNullifier)).
        _saveNullifierHash(nullifierHash);

        emit ProofVerified(signal);

        // _mint(msg.sender, totalSupply());
        _mintToEOA(msg.sender, totalSupply(), 1, v, r, s, data);
        _setTokenURI(totalSupply(), tokenURI);

        emit Minted(totalSupply(), msg.sender);

        supplyCounter.increment();
    }

    /************************************************
     *  Burn NFT
     ***********************************************/
    function burn(
        address from,
        uint256 id,
        uint256 amount,
        bool deleteURI
    ) external onlyOwner {
        if (deleteURI) {
            _burnAndDeleteURI(from, id, amount);
        } else {
            _burn(from, id, amount);
        }
    }

    function _burnAndDeleteURI(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        super._burn(from, id, amount);

        _deleteTokenURI(id);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
/// @title YoMinter interface.
/// @dev Interface of a YoMinter contract.
interface IYoMinter {

    event ProofVerified(bytes32 signal);
    event Minted(uint256 tokenId, address to);

    function mint(
        uint256 root,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof,
        string memory tokenURI,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './IERC1238.sol';
import './ERC1238Approval.sol';
import './IERC1238Receiver.sol';
import '../../utils/AddressMinimal.sol';
import '../../utils/ERC165.sol';

/**
 * @dev Implementation proposal for non-transferable (Badge) tokens
 * See https://github.com/ethereum/EIPs/issues/1238
 */
contract ERC1238 is ERC165, IERC1238, ERC1238Approval {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) internal _balances;

    // Used as the URI by default for all token types by relying on ID substitution,
    // e.g. https://token-cdn-domain/{id}.json
    string private baseURI;

    /**
     * @dev Initializes the contract by setting a `baseURI`.
     * See {_setBaseURI}
     */
    constructor(string memory baseURI_) {
        _setBaseURI(baseURI_);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1238).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism as in EIP-1155:
     * https://eips.ethereum.org/EIPS/eip-1155#metadata
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }

    /**
     * @dev See {IERC1238-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), 'ERC1238: balance query for the zero address');
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1238-balanceOfBatch}.
     *
     */
    function balanceOfBatch(address account, uint256[] memory ids) public view virtual override returns (uint256[] memory) {
        uint256[] memory batchBalances = new uint256[](ids.length);

        uint256 length = ids.length;
        for (uint256 i = 0; i < length; ++i) {
            batchBalances[i] = balanceOf(account, ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1238-balanceOfBundle}.
     *
     */
    function balanceOfBundle(address[] memory accounts, uint256[][] memory ids) public view virtual override returns (uint256[][] memory) {
        uint256[][] memory bundleBalances = new uint256[][](accounts.length);

        uint256 length = accounts.length;
        for (uint256 i = 0; i < length; ++i) {
            bundleBalances[i] = balanceOfBatch(accounts[i], ids[i]);
        }

        return bundleBalances;
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism as in EIP-1155
     * https://eips.ethereum.org/EIPS/eip-1155#metadata
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setBaseURI(string memory newBaseURI) internal virtual {
        baseURI = newBaseURI;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to a smart contract (to).
     *
     *
     * Requirements:
     * - `to` must be a smart contract and must implement {IERC1238Receiver-onERC1238BatchMint} and return the
     * acceptance magic value.
     *
     * Emits a {MintSingle} event.
     */
    function _mintToContract(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to.isContract(), 'ERC1238: Recipient is not a contract');

        _mint(to, id, amount, data);

        _doSafeMintAcceptanceCheck(msg.sender, to, id, amount, data);
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to the
     * Externally Owned Account (to).
     *
     * Requirements:
     *
     * - `v`, `r` and `s` must be a EIP712 signature from `to` as defined by ERC1238Approval to
     * approve the minting transaction.
     *
     * Emits a {MintSingle} event.
     */
    function _mintToEOA(
        address to,
        uint256 id,
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes memory data
    ) internal virtual {
        //
        bytes32 messageHash = _getMintApprovalMessageHash(to, id, amount);
        _verifyMintingApproval(to, messageHash, v, r, s);

        _mint(to, id, amount, data);
    }

    /**
     * @dev [Batched] version of {_mintToContract}. A batch specifies an array of token `id` and
     * the amount of tokens for each.
     *
     * Requirements:
     * - `to` must be a smart contract and must implement {IERC1238Receiver-onERC1238BatchMint} and return the
     * acceptance magic value.
     * - `ids` and `amounts` must have the same length.
     *
     * Emits a {MintBatch} event.
     */
    function _mintBatchToContract(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to.isContract(), 'ERC1238: Recipient is not a contract');

        _mintBatch(to, ids, amounts, data);

        _doSafeBatchMintAcceptanceCheck(msg.sender, to, ids, amounts, data);
    }

    /**
     * @dev [Batched] version of {_mintToEOA}. A batch specifies an array of token `id` and
     * the amount of tokens for each.
     *
     * Requirements:
     * - `v`, `r` and `s` must be a EIP712 signature from `to` as defined by ERC1238Approval to
     * approve the batch minting transaction.
     *
     * Emits a {MintBatch} event.
     */
    function _mintBatchToEOA(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes memory data
    ) internal virtual {
        bytes32 messageHash = _getMintBatchApprovalMessageHash(to, ids, amounts);
        _verifyMintingApproval(to, messageHash, v, r, s);

        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev Mints a bundle, which can be viewed as minting several batches
     * to an array of addresses in one transaction.
     *
     * Requirements:
     * - `to` can be a combination of smart contract addresses and EOAs.
     * - If `to` is not a contract, an EIP712 signature from `to` as defined by ERC1238Approval
     * must be passed at the right index in `data`.
     *
     * Emits multiple {MintBatch} events.
     */
    function _mintBundle(
        address[] memory to,
        uint256[][] memory ids,
        uint256[][] memory amounts,
        bytes[] memory data
    ) internal virtual {
        for (uint256 i = 0; i < to.length; i++) {
            if (to[i].isContract()) {
                _mintBatchToContract(to[i], ids[i], amounts[i], data[i]);
            } else {
                (bytes32 r, bytes32 s, uint8 v) = splitSignature(data[i]);
                _mintBatchToEOA(to[i], ids[i], amounts[i], v, r, s, data[i]);
            }
        }
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {MintSingle} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1238Receiver-onERC1238Mint} and return the
     * acceptance magic value.
     *
     * Emits a {MintSingle} event.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        address minter = msg.sender;

        _beforeMint(minter, to, id, amount, data);

        _balances[id][to] += amount;

        emit MintSingle(minter, to, id, amount);
    }

    /**
     * @dev [Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     *
     * Emits a {MintBatch} event.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        require(ids.length == amounts.length, 'ERC1238: ids and amounts length mismatch');

        address minter = msg.sender;

        for (uint256 i = 0; i < ids.length; i++) {
            _beforeMint(minter, to, ids[i], amounts[i], data);

            _balances[ids[i]][to] += amounts[i];
        }

        emit MintBatch(minter, to, ids, amounts);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     *
     * Emits a {BurnSingle} event.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), 'ERC1238: burn from the zero address');

        address burner = msg.sender;

        _beforeBurn(burner, from, id, amount);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, 'ERC1238: burn amount exceeds balance');
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit BurnSingle(burner, from, id, amount);
    }

    /**
     * @dev [Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     *
     * Emits a {BurnBatch} event.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), 'ERC1238: burn from the zero address');
        require(ids.length == amounts.length, 'ERC1238: ids and amounts length mismatch');

        address burner = msg.sender;

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _beforeBurn(burner, from, id, amount);

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, 'ERC1238: burn amount exceeds balance');
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit BurnBatch(burner, from, ids, amounts);
    }

    /**
     * @dev Hook that is called before an `amount` of tokens are minted.
     *
     * Calling conditions:
     * - `minter` and `to` cannot be the zero address
     *
     */
    function _beforeMint(
        address minter,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called before an `amount` of tokens are burned.
     *
     * Calling conditions:
     * - `burner` and `from` cannot be the zero address
     *
     */
    function _beforeBurn(
        address burner,
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {}

    function _doSafeMintAcceptanceCheck(
        address minter,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        try IERC1238Receiver(to).onERC1238Mint(minter, id, amount, data) returns (bytes4 response) {
            if (response != IERC1238Receiver.onERC1238Mint.selector) {
                revert('ERC1238: ERC1238Receiver rejected tokens');
            }
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert('ERC1238: transfer to non ERC1238Receiver implementer');
        }
    }

    function _doSafeBatchMintAcceptanceCheck(
        address minter,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        try IERC1238Receiver(to).onERC1238BatchMint(minter, ids, amounts, data) returns (bytes4 response) {
            if (response != IERC1238Receiver.onERC1238BatchMint.selector) {
                revert('ERC1238: ERC1238Receiver rejected tokens');
            }
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert('ERC1238: transfer to non ERC1238Receiver implementer');
        }
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, 'invalid signature length');

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '../ERC1238.sol';
import './IERC1238URIStorage.sol';
import '../../../utils/ERC165.sol';

/**
 * @dev Proposal for ERC1238 token with storage based token URI management.
 */
abstract contract ERC1238URIStorage is ERC165, IERC1238URIStorage, ERC1238 {
    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1238, ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1238URIStorage).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1238URIStorage-tokenURI}.
     */
    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        string memory _tokenURI = _tokenURIs[id];

        // Returns the token URI if there is a specific one set that overrides the base URI
        if (_isTokenURISet(id)) {
            return _tokenURI;
        }

        string memory base = _baseURI();

        return base;
    }

    /**
     * @dev Sets `_tokenURI` as the token URI for the tokens of type `id`.
     *
     */
    function _setTokenURI(uint256 id, string memory _tokenURI) internal virtual {
        _tokenURIs[id] = _tokenURI;

        emit URI(id, _tokenURI);
    }

    /**
     * @dev [Batched] version of {_setTokenURI}.
     *
     */
    function _setBatchTokenURI(uint256[] memory ids, string[] memory tokenURIs) internal {
        require(ids.length == tokenURIs.length, 'ERC1238Storage: ids and token URIs length mismatch');

        for (uint256 i = 0; i < ids.length; i++) {
            _setTokenURI(ids[i], tokenURIs[i]);
        }
    }

    /**
     * @dev Deletes the tokenURI for the tokens of type `id`.
     *
     * Requirements:
     *  - A token URI must be set.
     *
     *  Possible improvement:
     *  - The URI can only be deleted if all tokens of type `id` have been burned.
     */
    function _deleteTokenURI(uint256 id) internal virtual {
        if (_isTokenURISet(id)) {
            delete _tokenURIs[id];
        }
    }

    /**
     * @dev Returns whether a tokenURI is set or not for a specific `id` token type.
     *
     */
    function _isTokenURISet(uint256 id) private view returns (bool) {
        return bytes(_tokenURIs[id]).length > 0;
    }
}

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/ISemaphoreCore.sol";
import "../interfaces/IVerifier.sol";

/// @title Semaphore core contract.
/// @notice Minimal code to allow users to signal their endorsement of an arbitrary string.
/// @dev The following code verifies that the proof is correct and saves the hash of the
/// nullifier to prevent double-signaling. External nullifier and Merkle trees (i.e. groups) must be
/// managed externally.
contract SemaphoreCore is ISemaphoreCore {
  /// @dev Gets a nullifier hash and returns true or false.
  /// It is used to prevent double-signaling.
  mapping(uint256 => bool) internal nullifierHashes;

  /// @dev Asserts that no nullifier already exists and if the zero-knowledge proof is valid.
  /// Otherwise it reverts.
  /// @param signal: Semaphore signal.
  /// @param root: Root of the Merkle tree.
  /// @param nullifierHash: Nullifier hash.
  /// @param externalNullifier: External nullifier.
  /// @param proof: Zero-knowledge proof.
  /// @param verifier: Verifier address.
  function _verifyProof(
    bytes32 signal,
    uint256 root,
    uint256 nullifierHash,
    uint256 externalNullifier,
    uint256[8] calldata proof,
    IVerifier verifier
  ) internal view {
    require(!nullifierHashes[nullifierHash], "SemaphoreCore: you cannot use the same nullifier twice");

    uint256 signalHash = _hashSignal(signal);

    verifier.verifyProof(
      [proof[0], proof[1]],
      [[proof[2], proof[3]], [proof[4], proof[5]]],
      [proof[6], proof[7]],
      [root, nullifierHash, signalHash, externalNullifier]
    );
  }

  /// @dev Stores the nullifier hash to prevent double-signaling.
  /// Attention! Remember to call it when you verify a proof if you
  /// need to prevent double-signaling.
  /// @param nullifierHash: Semaphore nullifier hash.
  function _saveNullifierHash(uint256 nullifierHash) internal {
    nullifierHashes[nullifierHash] = true;
  }

  /// @dev Creates a keccak256 hash of the signal.
  /// @param signal: Semaphore signal.
  /// @return Hash of the signal.
  function _hashSignal(bytes32 signal) private pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(signal))) >> 8;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title Verifier interface.
/// @dev Interface of Verifier contract.
interface IVerifier {
  function verifyProof(
    uint256[2] memory a,
    uint256[2][2] memory b,
    uint256[2] memory c,
    uint256[4] memory input
  ) external view;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '../../utils/IERC165.sol';

/**
 * @dev Interface proposal for Badge tokens
 * See https://github.com/ethereum/EIPs/issues/1238
 */
interface IERC1238 is IERC165 {
    /**
     * @dev Emitted when `amount` tokens of token type `id` are minted to `to` by `minter`.
     */
    event MintSingle(address indexed minter, address indexed to, uint256 indexed id, uint256 amount);

    /**
     * @dev Equivalent to multiple {MintSingle} events, where `minter` and `to` is the same for all token types
     */
    event MintBatch(address indexed minter, address indexed to, uint256[] ids, uint256[] amounts);

    /**
     * @dev Emitted when `amount` tokens of token type `id` owned by `owner` are burned by `burner`.
     */
    event BurnSingle(address indexed burner, address indexed owner, uint256 indexed id, uint256 amount);

    /**
     * @dev Equivalent to multiple {BurnSingle} events, where `owner` and `burner` is the same for all token types
     */
    event BurnBatch(address indexed burner, address indexed owner, uint256[] ids, uint256[] amounts);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev Returns the balance of `account` for a batch of token `ids`
     *
     */
    function balanceOfBatch(address account, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Returns the balance of multiple `accounts` for a batch of token `ids`.
     * This is equivalent to calling {balanceOfBatch} for several accounts in just one call.
     *
     * Reuirements:
     * - `accounts` and `ids` must have the same length.
     *
     */
    function balanceOfBundle(address[] calldata accounts, uint256[][] calldata ids) external view returns (uint256[][] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
}

// Typed data of a Mint Batch transaction
// needing to be approved by `recipient`.
struct MintBatchApproval {
    address recipient;
    uint256[] ids;
    uint256[] amounts;
}

// Typed data of a Mint transaction
// needing to be approved by `recipient`.
struct MintApproval {
    address recipient;
    uint256 id;
    uint256 amount;
}

/**
 * ERC1238 tokens can only be minted to an EOA by providing a message signed by the recipient to
 * approve the minting, or batch minting, of tokens.
 *
 * This contract contains the logic around generating and verifiying these signed messages.
 *
 * @dev The implementation is based on EIP-712, a standard for typed structured data hashing and signing.
 * The standard defines the `hashtruct` function where structs are encoded with their typeHash
 * (a constant defining their type) and hashed.
 * See https://eips.ethereum.org/EIPS/eip-712
 *
 */
contract ERC1238Approval {
    bytes32 private constant EIP712DOMAIN_TYPEHASH = keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');

    bytes32 private constant MINT_APPROVAL_TYPEHASH = keccak256('MintApproval(address recipient,uint256 id,uint256 amount)');

    bytes32 private constant MINT_BATCH_APPROVAL_TYPEHASH = keccak256('MintBatchApproval(address recipient,uint256[] ids,uint256[] amounts)');

    // Domain Separator, as defined by EIP-712 (`hashstruct(eip712Domain)`)
    bytes32 public DOMAIN_SEPARATOR;

    constructor() {
        // The EIP712Domain shares the same name for all ERC128Approval contracts
        // but the unique address of this contract as `verifiyingContract`
        EIP712Domain memory eip712Domain = EIP712Domain({name: 'ERC1238 Mint Approval', version: '1', chainId: block.chainid, verifyingContract: address(this)});

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(EIP712DOMAIN_TYPEHASH, keccak256(bytes(eip712Domain.name)), keccak256(bytes(eip712Domain.version)), eip712Domain.chainId, eip712Domain.verifyingContract)
        );
    }

    /**
     * @dev Returns a MintApprovalMessageHash which is the result of `hashstruct(MintApproval)`.
     * To verify that `recipient` approved a mint transaction, the hash returned
     * must be passed to _verifyMintingApproval as `mintApprovalHash`.
     *
     */
    function _getMintApprovalMessageHash(
        address recipient,
        uint256 id,
        uint256 amount
    ) internal pure returns (bytes32) {
        MintApproval memory mintApproval = MintApproval({recipient: recipient, id: id, amount: amount});
        return keccak256(abi.encode(MINT_APPROVAL_TYPEHASH, mintApproval.recipient, mintApproval.id, mintApproval.amount));
    }

    /**
     * @dev Returns a MintBatchApprovalMessageHash which is the result of `hashstruct(MintBatchApproval)`.
     * To verify that `recipient` approved a mint batch transaction, the hash returned
     * must be passed to _verifyMintingApproval as `mintApprovalHash`.
     *
     */
    function _getMintBatchApprovalMessageHash(
        address recipient,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal pure returns (bytes32) {
        MintBatchApproval memory mintBatchApproval = MintBatchApproval({recipient: recipient, ids: ids, amounts: amounts});

        return
            keccak256(
                abi.encode(MINT_BATCH_APPROVAL_TYPEHASH, mintBatchApproval.recipient, keccak256(abi.encodePacked(mintBatchApproval.ids)), keccak256(abi.encodePacked(mintBatchApproval.amounts)))
            );
    }

    /**
     * @dev Given a mintApprovalHash (either MintApprovalMessageHash or MintBatchApprovalMessageHash),
     * this function verifies if the signature (v, r, and s) was signed by `recipient` based on the
     * EIP712Domain of this contract, and otherwise reverts.
     */
    function _verifyMintingApproval(
        address recipient,
        bytes32 mintApprovalHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view {
        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR, mintApprovalHash));

        require(ecrecover(digest, v, r, s) == recipient, 'ERC1238: Approval verification failed');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '../../utils/IERC165.sol';

/**
 * Interface for smart contracts wishing to receive ownership of ERC1238 tokens.
 */
interface IERC1238Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1238 token type.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1238Mint(address,address,uint256,uint256,bytes)"))`
     *
     * @param minter The address which initiated minting (i.e. msg.sender)
     * @param id The ID of the token being transferred
     * @param amount The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1238Mint(address,uint256,uint256,bytes)"))` if minting is allowed
     */
    function onERC1238Mint(
        address minter,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of multiple ERC1238 token types.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1238BatchMint(address,address,uint256[],uint256[],bytes)"))`
     *
     * @param minter The address which initiated minting (i.e. msg.sender)
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param amounts An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1238BatchMint(address,uint256[],uint256[],bytes)"))` if minting is allowed
     */
    function onERC1238BatchMint(
        address minter,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        return account.code.length > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.4;

import './IERC165.sol';

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.4;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '../IERC1238.sol';
import '../../../utils/IERC165.sol';

/**
 * @dev Proposal of an interface for ERC1238 token with storage based token URI management.
 */
interface IERC1238URIStorage is IERC1238 {
    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     */
    event URI(uint256 indexed id, string value);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `id` token.
     */
    function tokenURI(uint256 id) external view returns (string memory);
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title SemaphoreCore interface.
/// @dev Interface of SemaphoreCore contract.
interface ISemaphoreCore {
  /// @notice Emitted when a proof is verified correctly and a new nullifier hash is added.
  /// @param nullifierHash: Hash of external and identity nullifiers.
  event NullifierHashAdded(uint256 nullifierHash);
}