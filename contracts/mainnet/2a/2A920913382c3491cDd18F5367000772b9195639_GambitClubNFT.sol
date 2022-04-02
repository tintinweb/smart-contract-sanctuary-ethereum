//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 *   _____ _             ____                 _     _ _      ____ _       _
 *  |_   _| |__   ___   / ___| __ _ _ __ ___ | |__ (_) |_   / ___| |_   _| |__
 *    | | | '_ \ / _ \ | |  _ / _` | '_ ` _ \| '_ \| | __| | |   | | | | | '_ \
 *    | | | | | |  __/ | |_| | (_| | | | | | | |_) | | |_  | |___| | |_| | |_) |
 *    |_| |_| |_|\___|  \____|\__,_|_| |_| |_|_.__/|_|\__|  \____|_|\__,_|_.__/
 */

import "./IGambitClubNFT.sol";
import "./token/ERC721Enumerable.sol";
import "./token/ERC2981ContractWideRoyalties.sol";
import "./token/TokenRescuer.sol";
import "./utils/MerkleProof.sol";

/// @title The Gambit Club
/// @author Aaron Hanson <[email protected]> @CoffeeConverter
contract GambitClubNFT is
    IGambitClubNFT,
    ERC721Enumerable,
    ERC2981ContractWideRoyalties,
    TokenRescuer
{
    /// The maximum token supply.
    uint256 public constant MAX_SUPPLY = 3200;

    /// The maximum number of token mints per transaction.
    uint256 public constant MAX_MINT_PER_TX = 25;

    /// The maximum number of presale+whitelist token mints per address.
    uint256 public constant MAX_PRESALE_PER_ADDRESS = 5;

    /// The price per token mint.
    uint256 public constant PRICE = 0.08 ether;

    /// The maximum ERC-2981 royalties percentage (two decimals).
    uint256 public constant MAX_ROYALTIES_PCT = 1000; // 10%

    /// The base URI for token metadata.
    string public baseURI;

    /// The contract URI for contract-level metadata.
    string public contractURI;

    /// The provenance hash summarizing token order and content.
    bytes32 public provenanceHash;

    /// Whether the provenance hash has been locked forever.
    bool public provenanceIsLocked;

    /// Whether the tokenURI() method returns fully revealed tokenURIs
    bool public isRevealed;

    /// The token sale state (0=Paused, 1=Whitelist, 2=Presale, 3=Public).
    SaleState public saleState;

    /// The address of the OpenSea proxy registry contract.
    address public proxyRegistry;

    /// The merkle root summarizing all whitelisted addresses.
    bytes32 public whitelistMerkleRoot;

    /// The merkle root summarizing all presale addresses.
    bytes32 public presaleMerkleRoot;

    /// Whether an address has revoked the automatic OpenSea proxy approval.
    mapping(address => bool) public userRevokedRegistryApproval;

    /// Whether a project proxy contract has been granted automatic approval.
    mapping(address => bool) public projectProxy;

    /// The total tokens minted by an address in presale and whitelist phases.
    mapping(address => uint256) public presaleMinted;

    /// Reverts if the current sale state is not `_saleState`.
    modifier onlyInSaleState(SaleState _saleState) {
        if (saleState != _saleState) revert SalePhaseNotActive();
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _startingTokenID,
        string memory _contractURI,
        string memory _baseURI,
        bytes32 _provenanceHash,
        bytes32 _whitelistMerkleRoot,
        bytes32 _presaleMerkleRoot,
        address _proxyRegistry
    )
        ERC721(_name, _symbol, _startingTokenID)
    {
        contractURI = _contractURI;
        baseURI = _baseURI;
        provenanceHash = _provenanceHash;
        whitelistMerkleRoot = _whitelistMerkleRoot;
        presaleMerkleRoot = _presaleMerkleRoot;
        proxyRegistry = _proxyRegistry;
    }

    /// @notice Mints a single token to the caller if the proof is valid.
    /// @param _proof The caller's whitelist merkle proof.
    function mintWhitelist(
        bytes32[] calldata _proof
    )
        external
        payable
        onlyInSaleState(SaleState.Whitelist)
    {
        if (!isValidMerkleProof(_proof, whitelistMerkleRoot, _msgSender()))
            revert InvalidMerkleProof();

        if (msg.value != PRICE)
            revert IncorrectPaymentAmount();

        if (presaleMinted[_msgSender()] != 0)
            revert ExceedsMintPhaseAllocation();

        uint256 totalSupply = _owners.length;

        if (totalSupply == MAX_SUPPLY)
            revert ExceedsMaxSupply();

        presaleMinted[_msgSender()] = 1;
        _mint(_msgSender(), totalSupply);
    }

    /// @notice Mints `_mintAmount` tokens to the caller if the proof is valid.
    /// @param _mintAmount The number of tokens to mint (1-5).
    /// @param _proof The caller's presale merkle proof.
    function mintPresale(
        uint256 _mintAmount,
        bytes32[] calldata _proof
    )
        external
        payable
        onlyInSaleState(SaleState.Presale)
    {
        if (!isValidMerkleProof(_proof, presaleMerkleRoot, _msgSender()))
            revert InvalidMerkleProof();

        uint256 totalSupply = _owners.length;

        unchecked {
            if (totalSupply + _mintAmount > MAX_SUPPLY)
                revert ExceedsMaxSupply();

            if (msg.value != _mintAmount * PRICE)
                revert IncorrectPaymentAmount();

            presaleMinted[_msgSender()] += _mintAmount;

            if (presaleMinted[_msgSender()] > MAX_PRESALE_PER_ADDRESS)
                revert ExceedsMintPhaseAllocation();

            for(uint256 i; i < _mintAmount; i++) {
                _mint(_msgSender(), totalSupply + i);
            }
        }
    }

    /// @notice Mints `_mintAmount` tokens to the caller.
    /// @param _mintAmount The number of tokens to mint (1-25).
    function mintPublic(
        uint256 _mintAmount
    )
        external
        payable
        onlyInSaleState(SaleState.Public)
    {
        if (_mintAmount > MAX_MINT_PER_TX)
            revert ExceedsMaxMintPerTransaction();

        uint256 totalSupply = _owners.length;

        unchecked {
            if (totalSupply + _mintAmount > MAX_SUPPLY)
                revert ExceedsMaxSupply();

            if (msg.value != _mintAmount * PRICE)
                revert IncorrectPaymentAmount();

            for(uint256 i; i < _mintAmount; i++) {
                _mint(_msgSender(), totalSupply + i);
            }
        }
    }

    /// @notice Revokes the automatic approval of the caller's OpenSea proxy.
    function revokeRegistryApproval()
        external
    {
        if (userRevokedRegistryApproval[_msgSender()] == true)
            revert AlreadyRevokedRegistryApproval();

        userRevokedRegistryApproval[_msgSender()] = true;
    }

    /// @notice (only owner) Mints `_mintAmount` free tokens to the caller.
    /// @param _mintAmount The number of tokens to mint.
    function mintPromo(
        uint256 _mintAmount
    )
        external
        onlyOwner
    {
        uint256 totalSupply = _owners.length;

        if (totalSupply + _mintAmount > MAX_SUPPLY)
            revert ExceedsMaxSupply();

        unchecked {
            for(uint256 i; i < _mintAmount; i++) {
                _mint(_msgSender(), totalSupply + i);
            }
        }
    }

    /// @notice (only owner) Sets the saleState to `_newSaleState`.
    /// @param _newSaleState The new sale state
    /// (0=Paused, 1=Whitelist, 2=Presale, 3=Public).
    function setSaleState(
        SaleState _newSaleState
    )
        external
        onlyOwner
    {
        saleState = _newSaleState;
        emit SaleStateChanged(_newSaleState);
    }

    /// @notice (only owner) Sets the OpenSea proxy registry contract address.
    /// @param _newProxyRegistry The OpenSea proxy registry contract address.
    function setProxyRegistry(
        address _newProxyRegistry
    )
        external
        onlyOwner
    {
        proxyRegistry = _newProxyRegistry;
    }

    /// @notice (only owner) Toggles the state of a project proxy address.
    /// @param _proxy The project proxy address to toggle true/false.
    function toggleProjectProxy(
        address _proxy
    )
        external
        onlyOwner
    {
        projectProxy[_proxy] = !projectProxy[_proxy];
    }

    /// @notice (only owner) Sets the whitelist merkle root.
    /// @param _newMerkleRoot The new whitelist merkle root.
    function setWhitelistMerkleRoot(
        bytes32 _newMerkleRoot
    )
        external
        onlyOwner
    {
        whitelistMerkleRoot = _newMerkleRoot;
    }

    /// @notice (only owner) Sets the presale merkle root.
    /// @param _newMerkleRoot The new presale merkle root.
    function setPresaleMerkleRoot(
        bytes32 _newMerkleRoot
    )
        external
        onlyOwner
    {
        presaleMerkleRoot = _newMerkleRoot;
    }

    /// @notice (only owner) Sets the contract URI for contract metadata.
    /// @param _newContractURI The new contract URI.
    function setContractURI(
        string calldata _newContractURI
    )
        external
        onlyOwner
    {
        contractURI = _newContractURI;
    }

    /// @notice (only owner) Sets the base URI for token metadata.
    /// @param _newBaseURI The new base URI.
    /// @param _doReveal If true, this reveals the full tokenURIs.
    function setBaseURI(
        string calldata _newBaseURI,
        bool _doReveal
    )
        external
        onlyOwner
    {
        baseURI = _newBaseURI;
        isRevealed = _doReveal;
    }

    /// @notice (only owner) Sets the provenance hash, optionally locking it.
    /// @param _newProvenanceHash The new provenance hash.
    /// @param _lockForever Whether to lock this new provenance hash forever.
    function setProvenanceHash(
        bytes32 _newProvenanceHash,
        bool _lockForever
    )
        external
        onlyOwner
    {
        if (provenanceIsLocked) revert ProvenanceHashAlreadyLocked();

        provenanceHash = _newProvenanceHash;
        if (_lockForever) provenanceIsLocked = true;
    }

    /// @notice (only owner) Withdraws `_weiAmount` wei to the caller.
    /// @param _weiAmount The amount of ether (in wei) to withdraw.
    function withdraw(
        uint256 _weiAmount
    )
        external
        onlyOwner
    {
        withdrawTo(_weiAmount, payable(_msgSender()));
    }

    /// @notice (only owner) Withdraws `_weiAmount` wei to `_to`.
    /// @param _weiAmount The amount of ether (in wei) to withdraw.
    /// @param _to The address to which to withdraw ether.
    function withdrawTo(
        uint256 _weiAmount,
        address payable _to
    )
        public
        onlyOwner
    {
        (bool success, ) = _to.call{value: _weiAmount}("");
        if (!success) revert FailedToWithdraw();
    }

    /// @notice (only owner) Sets ERC-2981 royalties recipient and percentage.
    /// @param _recipient The address to which to send royalties.
    /// @param _value The royalties percentage (two decimals, e.g. 1000 = 10%).
    function setRoyalties(
        address _recipient,
        uint256 _value
    )
        external
        onlyOwner
    {
        if(_value > MAX_ROYALTIES_PCT) revert ExceedsMaxRoyaltiesPercentage();

        _setRoyalties(
            _recipient,
            _value
        );
    }

    /// @notice Transfers multiple tokens from `_from` to `_to`.
    /// @param _from The address from which to transfer tokens.
    /// @param _to The address to which to transfer tokens.
    /// @param _tokenIDs An array of token IDs to transfer.
    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _tokenIDs
    )
        external
    {
        unchecked {
            for (uint256 i = 0; i < _tokenIDs.length; i++) {
                transferFrom(_from, _to, _tokenIDs[i]);
            }
        }
    }

    /// @notice Safely transfers multiple tokens from `_from` to `_to`.
    /// @param _from The address from which to transfer tokens.
    /// @param _to The address to which to transfer tokens.
    /// @param _tokenIDs An array of token IDs to transfer.
    function batchSafeTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _tokenIDs,
        bytes calldata _data
    )
        external
    {
        unchecked {
            for (uint256 i = 0; i < _tokenIDs.length; i++) {
                safeTransferFrom(_from, _to, _tokenIDs[i], _data);
            }
        }
    }

    /// @notice Determines whether `_account` owns all token IDs `_tokenIDs`.
    /// @param _account The account to be checked for token ownership.
    /// @param _tokenIDs An array of token IDs to be checked for ownership.
    /// @return True if `_account` owns all token IDs `_tokenIDs`, else false.
    function isOwnerOf(
        address _account,
        uint256[] calldata _tokenIDs
    )
        external
        view
        returns (bool)
    {
        unchecked {
            for (uint256 i; i < _tokenIDs.length; ++i) {
                if (ownerOf(_tokenIDs[i]) != _account)
                    return false;
            }
        }

        return true;
    }

    /// @notice Returns an array of all token IDs owned by `_owner`.
    /// @param _owner The address for which to return all owned token IDs.
    /// @return An array of all token IDs owned by `_owner`.
    function walletOfOwner(
        address _owner
    )
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokenIDs = new uint256[](tokenCount);
        unchecked {
            for (uint256 i; i < tokenCount; i++) {
                tokenIDs[i] = tokenOfOwnerByIndex(_owner, i);
            }
        }
        return tokenIDs;
    }

    /// @notice Checks if `_operator` can transfer tokens owned by `_owner`.
    /// @param _owner The address that may own tokens.
    /// @param _operator The address that may be able to transfer tokens of `_owner`.
    /// @return True if `_operator` can transfer tokens of `_owner`, else false.
    function isApprovedForAll(
        address _owner,
        address _operator
    )
        public
        view
        override (ERC721, IERC721)
        returns (bool)
    {
        if (projectProxy[_operator]) return true;

        if (!userRevokedRegistryApproval[_owner]) {
            OpenSeaProxyRegistry registry = OpenSeaProxyRegistry(proxyRegistry);
            if (address(registry.proxies(_owner)) == _operator) return true;
        }

        return super.isApprovedForAll(_owner, _operator);
    }

    /// @notice Returns the token metadata URI for token ID `_tokenID`.
    /// @param _tokenID The token ID whose metadata URI should be returned.
    /// @return The metadata URI for token ID `_tokenID`.
    function tokenURI(
        uint256 _tokenID
    )
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(_tokenID)) revert TokenDoesNotExist();
        if (!isRevealed) return baseURI;
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenID), ".json"));
    }

    /// @inheritdoc ERC165
    function supportsInterface(
        bytes4 _interfaceId
    )
        public
        view
        override (ERC721Enumerable, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    /// @notice Checks whether the merkle proof `_proof` is valid for `_sender`.
    /// @param _proof The merkle proof.
    /// @param _root The merkle root.
    /// @param _sender The sender address for which to validate the proof/root.
    /// @return True if the proof is valid for the sender/root, else false.
    function isValidMerkleProof(
        bytes32[] calldata _proof,
        bytes32 _root,
        address _sender
    )
        public
        pure
        returns (bool)
    {
        bytes32 leaf;
        bytes20 addr = bytes20(_sender);
        assembly {
            mstore(0x00, addr)
            leaf := keccak256(0x00, 0x14)
        }
        return MerkleProof.verify(
            _proof,
            _root,
            leaf
        );
    }

    /// @notice Mints internal token ID `_tokenID` to `_to`, emits actual token ID.
    /// @dev Must be a sequential mint starting at internal token ID 0.
    function _mint(
        address _to,
        uint256 _tokenID
    )
        internal
        override
    {
        _owners.push(_to);
        emit Transfer(address(0), _to, _startingTokenID + _tokenID);
    }
}

/// Stub for OpenSea's per-user-address proxy contract.
contract OwnableDelegateProxy {}

/// Stub for OpenSea's proxy registry contract.
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IGambitClubNFT {
    enum SaleState {
        Paused,    // 0
        Whitelist, // 1
        Presale,   // 2
        Public     // 3
    }

    event SaleStateChanged(
        SaleState newSaleState
    );

    error SalePhaseNotActive();
    error InvalidMerkleProof();
    error IncorrectPaymentAmount();
    error ExceedsMintPhaseAllocation();
    error ExceedsMaxSupply();
    error ExceedsMaxMintPerTransaction();
    error FailedToWithdraw();
    error TokenDoesNotExist();
    error AlreadyRevokedRegistryApproval();
    error ExceedsMaxRoyaltiesPercentage();
    error ProvenanceHashAlreadyLocked();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(IERC165, ERC721)
        returns (bool)
    {
        return interfaceId == type(IERC721Enumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply()
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _owners.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(
        uint256 index
    )
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < _owners.length,
            "ERC721Enumerable: global index out of bounds"
        );
        return index + _startingTokenID;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    )
        public
        view
        virtual
        override
        returns (uint256 tokenId)
    {
        require(
            index < balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );

        uint count;
        unchecked {
            for (uint i; i < _owners.length; i++) {
                if (owner == _owners[i]) {
                    if (count == index) return _startingTokenID + i;
                    else count++;
                }
            }
        }

        revert("ERC721Enumerable: owner index out of bounds");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./ERC2981Base.sol";

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
/// @dev This implementation has the same royalties for each and every tokens
abstract contract ERC2981ContractWideRoyalties is ERC2981Base {
	RoyaltyInfo private _royalties;

	/// @dev Sets token royalties
	/// @param _recipient recipient of the royalties
	/// @param _value percentage (using 2 decimals - 10000 = 100, 0 = 0)
	function _setRoyalties(
		address _recipient,
		uint256 _value
	)
		internal
	{
		// unneeded since the derived contract has a lower _value limit
		// require(_value <= 10000, "ERC2981Royalties: Too high");
		_royalties = RoyaltyInfo(_recipient, uint24(_value));
	}

	/// @inheritdoc	IERC2981Royalties
	function royaltyInfo(
		uint256,
		uint256 _value
	)
		external
		view
		override
		returns (address receiver, uint256 royaltyAmount)
	{
		RoyaltyInfo memory royalties = _royalties;
		receiver = royalties.recipient;
		royaltyAmount = (_value * royalties.amount) / 10000;
	}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./IStuckTokens.sol";
import "./SafeERC20.sol";
import "../utils/Ownable.sol";

error ArrayLengthMismatch();

contract TokenRescuer is Ownable {
    using SafeERC20 for IStuckERC20;

    function rescueBatchERC20(
        address _token,
        address[] calldata _receivers,
        uint256[] calldata _amounts
    )
        external
        onlyOwner
    {
        if (_receivers.length != _amounts.length) revert ArrayLengthMismatch();
        unchecked {
            for (uint i; i < _receivers.length; i += 1) {
                _rescueERC20(_token, _receivers[i], _amounts[i]);
            }
        }
    }

    function rescueERC20(
        address _token,
        address _receiver,
        uint256 _amount
    )
        external
        onlyOwner
    {
        _rescueERC20(_token, _receiver, _amount);
    }

    function rescueBatchERC721(
        address _token,
        address[] calldata _receivers,
        uint256[][] calldata _tokenIDs
    )
        external
        onlyOwner
    {
        if (_receivers.length != _tokenIDs.length) revert ArrayLengthMismatch();
        unchecked {
            for (uint i; i < _receivers.length; i += 1) {
                uint256[] memory tokenIDs = _tokenIDs[i];
                for (uint j; j < tokenIDs.length; j += 1) {
                    _rescueERC721(_token, _receivers[i], tokenIDs[j]);
                }
            }
        }
    }

    function rescueERC721(
        address _token,
        address _receiver,
        uint256 _tokenID
    )
        external
        onlyOwner
    {
        _rescueERC721(_token, _receiver, _tokenID);
    }

    function _rescueERC20(
        address _token,
        address _receiver,
        uint256 _amount
    )
        private
    {
        IStuckERC20(_token).safeTransfer(_receiver, _amount);
    }

    function _rescueERC721(
        address _token,
        address _receiver,
        uint256 _tokenID
    )
        private
    {
        IStuckERC721(_token).safeTransferFrom(
            address(this),
            _receiver,
            _tokenID
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../utils/Context.sol";
import "../utils/Address.sol";

abstract contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    string private _name;
    string private _symbol;
    uint256 internal immutable _startingTokenID;

    // Mapping from token ID to owner address
    address[] internal _owners;

    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 startingTokenID_
    ) {
        _name = name_;
        _symbol = symbol_;
        _startingTokenID = startingTokenID_;
    }

    function _internalTokenID(
        uint256 externalTokenID_
    )
        private
        view
        returns (uint256)
    {
        require(
            externalTokenID_ >= _startingTokenID,
            "ERC721: owner query for nonexistent token"
        );

        unchecked {
            return externalTokenID_ - _startingTokenID;
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint)
    {
        require(owner != address(0), "ERC721: balance query for the zero address");

        uint count;
        for(uint i; i < _owners.length; ++i) {
            if(owner == _owners[i]) ++count;
        }
        return count;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[_internalTokenID(tokenId)];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        if (tokenId < _startingTokenID) return false;

        uint256 internalID = _internalTokenID(tokenId);
        return internalID < _owners.length && _owners[internalID] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
        getApproved(tokenId) == spender ||
        isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);
        _owners.push(to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);
        _owners[_internalTokenID(tokenId)] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        _owners[_internalTokenID(tokenId)] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
            IERC721Receiver(to).onERC721Received(
                _msgSender(),
                from,
                tokenId,
                _data
            )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                    "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address /*from*/,
        address /*to*/,
        uint256 /*tokenId*/
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IERC2981Royalties.sol";

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
abstract contract ERC2981Base is ERC165, IERC2981Royalties {
	struct RoyaltyInfo {
		address recipient;
		uint24 amount;
	}

	/// @inheritdoc	ERC165
	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override
		returns (bool)
	{
		return
			interfaceId == type(IERC2981Royalties).interfaceId ||
			super.supportsInterface(interfaceId);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {
	/// @notice Called with the sale price to determine how much royalty
	///         is owed and to whom.
	/// @param _tokenId - the NFT asset queried for royalty information
	/// @param _value - the sale price of the NFT asset specified by _tokenId
	/// @return _receiver - address of who should be sent the royalty payment
	/// @return _royaltyAmount - the royalty payment amount for value sale price
	function royaltyInfo(uint256 _tokenId, uint256 _value)
		external
		view
		returns (address _receiver, uint256 _royaltyAmount);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IStuckERC20 {
    function transfer(
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IStuckERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "./IStuckTokens.sol";
import "./../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IStuckERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IStuckERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// Based on OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
// With renounceOwnership() removed

pragma solidity ^0.8.12;

import "./Context.sol";

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