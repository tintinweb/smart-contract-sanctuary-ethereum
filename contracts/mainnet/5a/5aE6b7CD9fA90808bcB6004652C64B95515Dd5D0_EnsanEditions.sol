// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./GsERC1155Merkle.sol";
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';

/**
 * @title ENSAN Editions tokens
 * @notice Can define new tokens on the GO and operate public and allow list gated mints
 * @author www.geeks.solutions  
*/
contract EnsanEditions is GsERC1155Merkle, DefaultOperatorFilterer {

    constructor() GsERC1155Merkle("Ensan Editions", "EES", "https://oxqme47eeycnsnbntin5otag4dgrsqd3alyb4b4lgcbkme4wkeca.arweave.net/deDCc-QmBNk0LZob10wG4M0ZQHsC8B4HizCCphOWUQQ", msg.sender, 1000) DefaultOperatorFilterer() {} 

     /**
     * @notice Mints the given amount of token id to the specified receiver address
     * 
     * @param _token_id the token id to mint
     * @param _receiver the receiving wallet
     * @param _amount the amount of tokens to mint
     */
    function oMint(uint256 _token_id, address _receiver, uint256 _amount) external onlyOwner {
        if(_receiver == address(0)) revert ZeroAddress();

        ReturnData memory rd = getTokenData(_token_id);
        if(rd.total_supply + _amount > rd.max_supply) revert MaxSupply();

        _mint(_receiver, _token_id, _amount, "");        
    }      

    /**
    * @notice mint during public sale
    * 
    * @param _token_id the token id to mint
    * @param _amount the amount of tokens to mint
    */
    function mint(uint256 _token_id, uint256 _amount) external payable whenNotPaused whenPublicSaleIsActive(_token_id){
        if(msg.value < super.elligible_mint(_token_id, _amount)) revert InsufficentFunds();
        _mint(_msgSender(), _token_id, _amount, "");
    }  

    /**
     * @notice Mints a token following a given whitelist conditions
     * 
     * @param token_id The token id to mint
     * @param wlIndex the index of the whitelist to use for this mint
     * @param amount the amount of tokens to mint
     * @param proof the proof to grant access to this whitelist
     */
    function wlMint(uint256 token_id, uint256 wlIndex, uint256 amount, bytes32[] calldata proof) external payable whenNotPaused {
         if(msg.value < super.elligible_claim(amount, token_id, wlIndex, proof)) revert InsufficentFunds();
        _mint(_msgSender(), token_id, amount, "");
    } 

    /**
    * @notice Open Sea filterer to blacklist Marketplace which are not enforcing Royalty payments
    */
    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) 
    {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFilterer} from "./OperatorFilterer.sol";
import {CANONICAL_CORI_SUBSCRIPTION} from "./lib/Constants.sol";
/**
 * @title  DefaultOperatorFilterer
 * @notice Inherits from OperatorFilterer and automatically subscribes to the default OpenSea subscription.
 * @dev    Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 */

abstract contract DefaultOperatorFilterer is OperatorFilterer {
    /// @dev The constructor that is called when the contract is being deployed.
    constructor() OperatorFilterer(CANONICAL_CORI_SUBSCRIPTION, true) {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./GsERC1155.sol";
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

error WrongRoot();
error InactiveWhitelist();
error InvalidProof();

/// @notice This contract adds a Merkle Tree based Whitelist to the GsERC1155 contract.
/// Multiple whitelists can exist for a given token ID
/// @author www.geeks.solutions
/// @dev You can use this contract as a parent for your collection and you can use
/// https://sections.geeks.solutions to get a ready frontend solution to run
/// your mint page that connects seamlessly to this contract
contract GsERC1155Merkle is GsERC1155 {
    struct WhitelistData {
        bytes32 merkle_root;
        uint128 token_price;
        uint8 max_per_wallet;
        bool active;
        bool use_dynamic_price;
    }

    // whitelist_datas[token_id][whitelist_index]
    mapping(uint256 => WhitelistData[]) internal whitelist_datas;

    /// @notice Builds a collection that can be whitelist gated
    constructor(string memory _name, string memory _symbol, string memory _contractURI, address _recipient, uint16 _royaltyShare) 
    GsERC1155(_name, _symbol, _contractURI, _recipient, _royaltyShare){}

    modifier whitelistExist(uint256 whitelistIndex, uint256 tokenId) {
        _whiteListExist(whitelistIndex, tokenId);
        _;
    }

    function _whiteListExist(uint256 whitelistIndex, uint256 tokenId) internal view virtual {
        if(whitelistIndex >= whitelist_datas[tokenId].length) revert IndexOutOfRange();
    }

    /// @notice Adds a new whitelist for a given token ID. The token must be defined. Whitelist index starts at 0
    /// 
    /// @param _token_id The Id of the token to create a whitelist for
    /// @param _wl_price_in_wei The price in GWEI (https://eth-converter.com/) of the token when minting with this whitelist
    /// @param _merkle_root The merkle root to grant access to the whitelist
    /// @param _wl_max_per_wallet The maximum amount of tokens one can hold to mint using this whitelist
    /// @param _active Whether or not this whitelist is active and can be used to mint the token
    /// @param _use_dynamic_price a boolean to indicate if we should use the dynamic price or not
    /// @return whitelist_index
    function addNewWhitelist(uint256 _token_id, uint128 _wl_price_in_wei, bytes32 _merkle_root, 
        uint8 _wl_max_per_wallet, bool _active, bool _use_dynamic_price) external editors tokenExist(_token_id)
    returns(uint256){
        whitelist_datas[_token_id].push(
            WhitelistData({
                token_price: _wl_price_in_wei,
                active: _active,
                merkle_root: _merkle_root,
                max_per_wallet: _wl_max_per_wallet,
                use_dynamic_price: _use_dynamic_price
            }));
        return whitelist_datas[_token_id].length - 1;
    }

    /// @notice Fully edit the whitelist for a token id at a given index
    /// 
    /// @param _token_id The id of the token to update the whitelist for
    /// @param _whitelist_index The index of the whitelist to edit
    /// @param _merkle_root The new merkle root to store for this whitelist
    /// @param _active  Whether or not this whitelist is active and can be used to mint the token
    /// @param _wl_price_in_wei the price in GWEI (https://eth-converter.com/)
    /// @param _wl_max_per_wallet The maximum amount of tokens one can hold to mint using this whitelist
    /// @param _use_dynamic_price a boolean to indicate if we should use the dynamic price or not
    function editWhitelistFull(uint256 _whitelist_index, uint256 _token_id, uint128 _wl_price_in_wei, bytes32 _merkle_root, 
        uint8 _wl_max_per_wallet, bool _active, bool _use_dynamic_price) external editors whitelistExist(_whitelist_index, _token_id) {
        editWhitelist(whitelist_datas[_token_id][_whitelist_index], _token_id, _whitelist_index, _merkle_root, _active, _wl_price_in_wei, _wl_max_per_wallet, _use_dynamic_price);
        
    }

    /// @notice Partially edit the whitelist for a token id at a given index
    /// 
    /// @param _token_id The id of the token to edit the whitelist for
    /// @param _whitelist_index the index of the whitelist to edit
    /// @param _merkle_root the new merkle root to store for this whitelist
    /// @param _active  Whether or not this whitelist is active and can be used to mint the token
    /// @param _use_dynamic_price Whether or not to use dynamic price for the whitelist
    function editWhitelistPartial(uint256 _whitelist_index, uint256 _token_id, bytes32 _merkle_root, bool _active, bool _use_dynamic_price) external editors whitelistExist(_whitelist_index, _token_id) {
        WhitelistData memory whitelist = whitelist_datas[_token_id][_whitelist_index];
        editWhitelist(whitelist, _token_id, _whitelist_index, _merkle_root, _active, whitelist.token_price, whitelist.max_per_wallet, _use_dynamic_price);
    }

    function editWhitelist(WhitelistData memory _whitelist, uint256 _token_id, uint256 _whitelist_index, bytes32 _merkle_root, bool _active,
        uint128 _wl_price, uint8 _wl_max_per_wallet, bool _use_dynamic_price) internal {            
        if(_merkle_root == "") revert WrongRoot();

        _whitelist.merkle_root = _merkle_root;
        _whitelist.active = _active;
        _whitelist.token_price = _wl_price;
        _whitelist.max_per_wallet = _wl_max_per_wallet;
        _whitelist.use_dynamic_price = _use_dynamic_price;

        whitelist_datas[_token_id][_whitelist_index] = _whitelist;
    }

    /// @notice Gets a white for token id at a specific index
    /// 
    /// @param _token_id the id of the token to get the whitelist for
    /// @param _whitelist_index the index of the whitelist to get
    /// @return whitelist
    function getWhiteListAtIndex(uint256 _token_id, uint256 _whitelist_index) public view whitelistExist(_whitelist_index, _token_id)
    returns(WhitelistData memory) {
        return whitelist_datas[_token_id][_whitelist_index];
    }

    /// @notice Returns the number of whitelists defined for a given token id
    /// 
    /// @param _token_id The id of the token to get the count for
    /// @return length
    function getWhiteListLengthForToken(uint256 _token_id) external view returns(uint256) {
        return whitelist_datas[_token_id].length;
    }

    /// @notice Returns the total price for a mint based on a token ID the amount of token, 
    /// the whitelist and the wallet requesting it. Price can be dynamic or static,
    /// whitelist can be set to override dynamic pricing
    /// 
    /// @param account the address to compute the price for
    /// @param token_id the token id to get the price for
    /// @param whitelist_index the whitelist to check the price for
    /// @param amount the amount of token to compute the price for
    ///
    /// @return price
    function getMintTotalPrice(address account, uint256 token_id, uint256 whitelist_index, uint256 amount) external view whitelistExist(whitelist_index, token_id) 
    returns(uint256 price) {
        WhitelistData memory _whitelist = getWhiteListAtIndex(token_id, whitelist_index); 
        if (_whitelist.use_dynamic_price) {
            return super.extractTotalPrice(token_id, _whitelist.token_price, token_datas[token_id].total_supply, token_datas[token_id].mints_count[account], amount);
        }
        return _whitelist.token_price * amount;
    }

    function initFront(address account, uint256 token_id, uint256 whitelist_index) public view whitelistExist(whitelist_index, token_id)
     returns(ReturnData memory rd){
       rd = super.initFront(account, token_id);
        // whitelist overriding
        WhitelistData memory wl = getWhiteListAtIndex(token_id, whitelist_index);
       rd.max_per_wallet = wl.max_per_wallet;
       rd.base_price = wl.token_price;
       rd.active = wl.active;
       rd.use_dynamic_price = wl.use_dynamic_price;
    }

    //************ SUPPORT FUNCTIONS ************//
    /**
     * @notice This function checks for the elligibility for a user to mint a given amount of token id based on the proof
     * of a given whitelist index
     * @param _amount the amount of token to check mint elligibility for
     * @param _token_id the token id to check
     * @param _whitelist_index the whitelist index to check for
     * @param _merkleProof the proof of the Merkle tree provided by the user
     * @return total
     */
    function elligible_claim(uint256 _amount, uint256 _token_id, uint256 _whitelist_index, bytes32[] calldata _merkleProof) view internal 
    returns(uint256 total) {
        WhitelistData storage whitelist = whitelist_datas[_token_id][_whitelist_index];
        if(!whitelist.active) revert InactiveWhitelist();
        if(!MerkleProof.verifyCalldata(_merkleProof, whitelist.merkle_root, keccak256(abi.encodePacked(msg.sender)))) revert InvalidProof();
        return super.elligible_mint(_token_id, _amount, whitelist.use_dynamic_price, whitelist.max_per_wallet, whitelist.token_price);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

address constant CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS = 0x000000000000AAeB6D7670E522A718067333cd4E;
address constant CANONICAL_CORI_SUBSCRIPTION = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";
import {CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS} from "./lib/Constants.sol";
/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 *         Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 */

abstract contract OperatorFilterer {
    /// @dev Emitted when an operator is not allowed.
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS);

    /// @dev The constructor that is called when the contract is being deployed.
    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (subscribe) {
                OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    OPERATOR_FILTER_REGISTRY.register(address(this));
                }
            }
        }
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /**
     * @dev A helper function to check if an operator approval is allowed.
     */
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            // under normal circumstances, this function will revert rather than return false, but inheriting contracts
            // may specify their own OperatorFilterRegistry implementations, which may behave differently
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import "./libraries/GsDynamicPrice.sol";

error UnknownModifier();
error Unauthorized(address user);
error TokenNotFound();
error Unburnable();
error SaleClosed();
error ExistingToken();
error TokenLockedBySupply();
error IndexOutOfRange();
error ListFull();
error InvalidRoyaltyShare();
error TransferFailed();
error ContractMint();
error MaxSupply();
error MaxCount();
error ZeroAddress();
error NotTokenOwnerOrAuthorised();

// For convenience to inheriting contracts
error InsufficentFunds();

/// @title A base class to create token IDs within an ERC1155 collection
/// @author www.geeks.solutions
/// @notice Each token definition carries a price, a max supply and certain mint rules
/// You can define as many tokens as you want. Once a token has been supplied the supply levels
/// and base prices are locked for this token ID.
/// You can also define pricing rules per token to have dynamic prices apply to tokens. 
/// pricing rules are based on ascending triggering values and can be based on 
/// token SUPPLY or wallet MINTS or a combination of both
/// @dev You can define default values that will be used when creating new tokens
/// You can use this contract as a parent for your collection and you can use
/// https://sections.geeks.solutions to get a ready frontend solution to run
/// your mint page that connects seamlessly to this contract
contract GsERC1155 is ERC1155, Ownable, Pausable, IERC2981 {
    
    enum PriceCondition{SUPPLY, MINTS}

    string public name;
    string public symbol;
    string public contractURI;  

    TokenData internal _default;
    PriceCondition[2] public price_condition_priority; 

    struct ReturnData {
        uint128 base_price;
        uint16 royalty_share;
        bool active;
        bool burnable;
        bool use_dynamic_price;
        bool isPaused;
        uint32 max_supply;
        uint32 total_supply;
        uint16 max_per_wallet;
        address royalty_recipient;
        string uri;
        uint256 mints_count;
    }

    struct TokenData {
        mapping(address => uint256) mints_count;
        uint128 base_price;
        uint16 royalty_share;
        bool public_sale;
        bool burnable;
        uint32 max_supply;
        uint32 total_supply;
        uint16 max_per_wallet;
        bool exist;
        bool use_dynamic_price;
        address royalty_recipient;
        string uri;
    }
    mapping(address => bool) private _editors;
    mapping(uint256 => TokenData) internal token_datas;
    mapping(uint256 => GsDynamicPrice.PriceRule[][]) internal price_conditions;

    /// @notice constructor to instantiate GsERC1155 contract
    /// @dev The params provided to this function will define the default Token Data to use for Tokens creation
    //
    /// @param _name the name of this collection
    /// @param _symbol the symbol to use for this collection
    /// @param _contractURI the URI pointing to the metadata describing your contract/collection (https://docs.opensea.io/docs/contract-level-metadata)
    /// @param _recipient the default royalty recipient for tokens to be created
    /// @param _royaltyShare the share of each sale (1% = 100) to distribute to the royalty recipient
    constructor(string memory _name, string memory _symbol, string memory _contractURI, address _recipient, uint16 _royaltyShare) ERC1155("https://geeks.solutions") {
        _default.base_price = 0.05 ether;
        _default.royalty_share = _royaltyShare;
        _default.public_sale = true;
        //_default.burnable = false;
        _default.max_supply = 1000;
        _default.max_per_wallet = 1;
        _default.exist = true;
        _default.royalty_recipient = _recipient;
        //_default.use_dynamic_price = false;

        name = _name;
        symbol = _symbol;
        contractURI = _contractURI;

        price_condition_priority[0] = PriceCondition.SUPPLY;
        price_condition_priority[1] = PriceCondition.MINTS;
    }

    /// @notice Convenience function to update the URI of the contract metadata
    /// 
    /// @param _contractURI the new URI to set for your contract/collection metadata file
    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    /// @notice This function is used to update a specific modifier for a given token id 
    /// @dev can only be called by the owner or editors
    //
    /// @param _token_id The token ID to edit the modifier for
    /// @param _type the modifier to edit (1=public_sale, 2=burnable, 3=use_dynamic_price)
    /// @param _value the new modifier value
    function setModifier(uint256 _token_id, uint32 _type, bool _value) external editors tokenExist(_token_id) {
        if (_type == 1) {
            token_datas[_token_id].public_sale = _value;
        } else if (_type == 2) {
            token_datas[_token_id].burnable = _value;
        } else if (_type == 3) {
            token_datas[_token_id].use_dynamic_price = _value;
        } else {
            revert UnknownModifier();
        }
    }

    modifier whenPublicSaleIsActive(uint256 _token_id) {
       if(!token_datas[_token_id].public_sale) revert SaleClosed();
        _;
    } 

    modifier tokenExist(uint256 tokenId) {
        _tokenExist(tokenId);
        _;
    }

    function _tokenExist(uint256 tokenId) internal view virtual {
        if (!token_datas[tokenId].exist) revert TokenNotFound();
    }

    modifier editors() {
        _checkEditors();
        _;
    }

    function _checkEditors() internal view virtual {
        if (!((owner() == _msgSender()) || _editors[_msgSender()])) revert Unauthorized(_msgSender());
    }

    function enableEditor(address editor) external onlyOwner {
        _editors[editor] = true;
    }

    function disableEditor(address editor) external onlyOwner {
        _editors[editor] = false;
    }

    /**
     * @dev Total amount of tokens minted with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint32) {
        return token_datas[id].total_supply;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
    * @notice returns the metadata uri for a given id
    * 
    * @param _token_id the token id to return metadata for
    */
    function uri(uint256 _token_id) public view override tokenExist(_token_id) returns (string memory) {
        return token_datas[_token_id].uri;
    } 

    /// @notice Updates the URI of a given token, can be called at any time (for simple reveals)
    /// 
    /// @param _token_id The id of the token to update
    /// @param _tokenURI The new URI to use for the token metadata (returned as is)
    function setURI(uint256 _token_id, string memory _tokenURI) external editors tokenExist(_token_id) {
        token_datas[_token_id].uri = _tokenURI;
    }

    function getDefaultTokenData() external view returns(ReturnData memory) {
        return ReturnData({
            base_price: _default.base_price, 
            royalty_share: _default.royalty_share,
            royalty_recipient: _default.royalty_recipient,
            active: _default.public_sale, 
            burnable: _default.burnable,
            max_supply: _default.max_supply,
            total_supply: _default.total_supply,
            max_per_wallet: _default.max_per_wallet,
            use_dynamic_price: _default.use_dynamic_price,
            uri: _default.uri,
            mints_count: 0,
            isPaused: super.paused()
        });
    }

    function setDefaultRoyalties(address _recipient, uint16 _share) public onlyOwner {
        _default.royalty_recipient = _recipient;
        _default.royalty_share = _share;
    }

    /// @notice this function updates the modifiers for the default values to use when creating new tokens
    //
    /// @param _publicSale the value to set for the public sale modifier
    /// @param _burnable the value to set for the burnable modifier
    function setDefaultModifiers(bool _publicSale, bool _burnable, bool _use_dynamic_price) public onlyOwner {
        _default.public_sale = _publicSale;
        _default.burnable = _burnable;
        _default.use_dynamic_price = _use_dynamic_price;
    }

    function setDefaultTokenMeta(uint32 _maxSupply, uint8 _maxPerWallet, uint128 _price_in_wei) public onlyOwner {
        _default.max_supply = _maxSupply;
        _default.max_per_wallet = _maxPerWallet;
        _default.base_price = _price_in_wei;
    }

    /// @notice updates the default values to use when creating new tokens
    /// @dev can only be called by the owner 
    //
    /// @param _recipient the recipient address to receive royalties
    /// @param _share the share of royalties to distribute on each sale (1% = 100)
    /// @param _publicSale Enable public sale for new tokens as soon as they are defined
    /// @param _burnable Allow the tokens to be burned as soon as they are defined
    /// @param _maxSupply The maximum Supply for new token creations
    /// @param _maxMintsPerWallet The maximum number of token a given wallet can mint
    /// @param _price_in_wei The token price in WEI (check https://eth-converter.com/ for help)
    function setDefaults(address _recipient, uint16 _share,
        bool _publicSale, bool _burnable, bool _use_dynamic_price,
        uint32 _maxSupply, uint8 _maxMintsPerWallet, uint128 _price_in_wei) external onlyOwner {
            setDefaultRoyalties(_recipient, _share);
            setDefaultModifiers(_publicSale, _burnable, _use_dynamic_price);
            setDefaultTokenMeta(_maxSupply, _maxMintsPerWallet, _price_in_wei);
    }

    function getTokenData(uint256 id) public view tokenExist(id)
      returns(ReturnData memory) {
        TokenData storage td = token_datas[id];
        return ReturnData({
            base_price: td.base_price, 
            royalty_share: td.royalty_share,
            active: td.public_sale, 
            burnable: td.burnable, 
            max_supply: td.max_supply,
            total_supply: td.total_supply,
            max_per_wallet: td.max_per_wallet, 
            use_dynamic_price: td.use_dynamic_price,
            royalty_recipient: td.royalty_recipient,
            uri: td.uri,
            isPaused: super.paused(),
            mints_count: 0
        }
        );
    }

    /// @notice Adds a new token without reading default token values
    /// Updates the token if it's been declared but not yet supplied. Rejects if the token id has been supplied already
    /// @dev can only be called by the owner.
    //
    /// @param _tokenId The ID to use for the new token to create
    /// @param _tokenUri The URI to use for the token metadata (returned as is)
    /// @param _tokenPublicSale Allow the token to be publicly minted
    /// @param _tokenBurnable Allow the token to be burned by its holder
    /// @param _tokenMaxSupply The maximum Supply for this token
    /// @param _tokenMaxMintsPerWallet The maximum amount of token a wallet can hold to mint more
    /// @param price_in_wei The price of the token in wei (https://eth-converter.com/)
    /// @param _tokenRoyaltyShare The share of royalty to send to the recipient on each sale (1% = 100)
    /// @param _tokenRoyaltyRecipient The recipient address to receive royalties on each sale
    function addNewToken(uint256 _tokenId, 
        string calldata _tokenUri, 
        bool _tokenPublicSale, 
        bool _tokenBurnable,
        uint32 _tokenMaxSupply,
        uint16 _tokenMaxMintsPerWallet,
        uint128 price_in_wei,
        uint16 _tokenRoyaltyShare,
        address _tokenRoyaltyRecipient,
        bool _use_dynamic_price) external editors {
            addToken(_tokenId, _tokenUri, _tokenPublicSale, _tokenBurnable, _tokenMaxSupply, 
            _tokenMaxMintsPerWallet, price_in_wei, _tokenRoyaltyShare, _tokenRoyaltyRecipient, _use_dynamic_price);
    }

    /// @notice Adds a new token by using default token values
    /// Updates the token if it's been declared but not yet supplied. Rejects if the token id has been supplied already
    /// @dev Can only be called by the owner
    //
    /// @param _tokenId the ID to use for this token
    /// @param _tokenUri The URI for this token metadata (returned as is)
    function addNewTokenLight(uint256 _tokenId, string calldata _tokenUri) external editors {
            addToken(_tokenId, _tokenUri, _default.public_sale, _default.burnable, _default.max_supply, _default.max_per_wallet, 
            _default.base_price, _default.royalty_share, _default.royalty_recipient, _default.use_dynamic_price);
    }

    function addToken(uint256 _tokenId, 
        string calldata _tokenUri, 
        bool _tokenPublicSale, 
        bool _tokenBurnable,
        uint32 _tokenMaxSupply,
        uint16 _tokenMaxPerWallet,
        uint128 _tokenPrice,
        uint16 _tokenRoyaltyShare,
        address _tokenRoyaltyRecipient,
        bool _use_dynamic_price) internal {
            if(token_datas[_tokenId].total_supply > 0) revert ExistingToken();
            TokenData storage td = token_datas[_tokenId];
            td.base_price = _tokenPrice;
            td.royalty_share = _tokenRoyaltyShare;
            td.public_sale = _tokenPublicSale;
            td.burnable = _tokenBurnable;
            td.max_supply = _tokenMaxSupply;
            td.max_per_wallet = _tokenMaxPerWallet;
            td.exist = true;
            td.royalty_recipient = _tokenRoyaltyRecipient;
            td.uri = _tokenUri;
            td.use_dynamic_price = _use_dynamic_price;
    }

    /// @notice Updates a given token Supply and price only if it hasn't been supplied
    //
    /// @param _tokenId The token ID to update
    /// @param _maxSupply The new maximum Supply to define for this token
    /// @param _maxPerWallet The maximum number of token a wallet can mint
    /// @param _price_in_wei The new price in GWEI (https://eth-converter.com/)
    function editTokenMeta(uint256 _tokenId, uint32 _maxSupply, uint16 _maxPerWallet, uint128 _price_in_wei) external editors {
        if(token_datas[_tokenId].total_supply > 0) revert TokenLockedBySupply();
        token_datas[_tokenId].max_supply = _maxSupply;
        token_datas[_tokenId].max_per_wallet = _maxPerWallet;
        token_datas[_tokenId].base_price = _price_in_wei;
    }

    function getMintTotalPrice(address account, uint256 token_id, uint256 amount) external view tokenExist(token_id) 
    returns(uint256 price) {
        TokenData storage td = token_datas[token_id];
        if (td.use_dynamic_price) {
            return extractTotalPrice(token_id, td.base_price, td.total_supply, td.mints_count[account], amount);
        }
        return td.base_price * amount;
    }

    function initFront(address account, uint256 token_id) public view virtual tokenExist(token_id)
    returns(ReturnData memory) {
        TokenData storage td = token_datas[token_id];
        return ReturnData({
            base_price: td.base_price, 
            royalty_share: td.royalty_share,
            active: td.public_sale, 
            burnable: td.burnable, 
            max_supply: td.max_supply,
            total_supply: td.total_supply,
            max_per_wallet: td.max_per_wallet, 
            use_dynamic_price: td.use_dynamic_price,
            royalty_recipient: td.royalty_recipient,
            uri: td.uri,
            isPaused: super.paused(),
            mints_count: td.mints_count[account]
        });
    }

    /// @notice Returns the Price condition type at priority index and the price rules associated for this token
    /// 
    /// @param _token_id the token id to get the price rules for
    /// @param _priority_index the priority index to return rules for
    function getPriceRules(uint256 _token_id, uint8 _priority_index) external view
     returns(PriceCondition, GsDynamicPrice.PriceRule[] memory){
        if(_priority_index >= price_conditions[_token_id].length) revert IndexOutOfRange();
        return (price_condition_priority[_priority_index], price_conditions[_token_id][_priority_index]);
    }

    /// @notice Reverse the order of priority between `SUPPLY` and `BALANCE`
    /// @dev this does not change the entries in the `price_conditions` map it only reassigns the value they compare against
    function reversePriceConditionPriority() external onlyOwner {
        PriceCondition[2] memory tmp = price_condition_priority;

        price_condition_priority[0] = tmp[1];
        price_condition_priority[1] = tmp[0];
    }

    /// @notice Add a list of price rules in the `price_conditions` map
    /// @dev the `price_conditions` map is as follows `price_conditions[uint256][priority_index][]`
    /// the list of price rules should contain a tuple for the trigger and the price value
    /// [[{trigger},{price in wei}],...] ie [[10,20000000000000000],[15,25000000000000000]]
    /// we need to iterate over the calldata array to manually convert to storage as calldata[] to storage conversion
    /// is not supported
    /// 
    /// @param _token_id the token id to add a price rule list for
    /// @param _ordered_rules the list of rules to add, has to be correctly formatted and in the right order
    function addPriceRules(uint256 _token_id, GsDynamicPrice.PriceRule[] calldata _ordered_rules) external editors tokenExist(_token_id) {
        if(!GsDynamicPrice.checkValidRulesList(_ordered_rules)) revert GsDynamicPrice.InvalidRule();
       
        uint256 new_index = price_conditions[_token_id].length;
        if(new_index >= price_condition_priority.length) revert ListFull();

        price_conditions[_token_id].push();
        for(uint8 i = 0; i < _ordered_rules.length; i++) {
            price_conditions[_token_id][new_index].push(_ordered_rules[i]);
        }
    }

    /// @notice Update an existing price rule list
    /// @dev see `addPriceRules` for more details
    /// 
    /// @param _token_id the token id to update the price rules list for
    /// @param _priority_index the price rule index to update
    /// @param _ordered_rules the price rules list
    function updatePriceRules(uint256 _token_id, uint8 _priority_index, GsDynamicPrice.PriceRule[] calldata _ordered_rules) external editors tokenExist(_token_id) {
        if(_priority_index >= price_conditions[_token_id].length) revert IndexOutOfRange();
        if(!GsDynamicPrice.checkValidRulesList(_ordered_rules)) revert GsDynamicPrice.InvalidRule();

        delete price_conditions[_token_id][_priority_index];
        
        for(uint8 i = 0; i < _ordered_rules.length; i++) {
            price_conditions[_token_id][_priority_index].push(_ordered_rules[i]);
        }
    }

    /// @notice Calculates the amount of royalty to send to the recipient based on the sale price
    /// 
    /// @param _token_id the Id of the token to compute royalty for
    /// @param _salePrice the price the token was sold for
    /// @return receiver
    /// @return royaltyAmount 
    function royaltyInfo(uint256 _token_id, uint256 _salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        return (token_datas[_token_id].royalty_recipient, (_salePrice * token_datas[_token_id].royalty_share) / 10000);
    }

    /// @notice Updates the Royalty parameters for a given token
    /// 
    /// @param _token_id the id of the token to update royalty param for
    /// @param _newRecipient the new recipient address
    /// @param _newShare the new share to take from each sale (1% = 100) should be between 1 and 9999 basis points
    function setRoyalties(uint256 _token_id, address _newRecipient, uint8 _newShare) external onlyOwner tokenExist(_token_id) {
        if(_newRecipient == address(0)) revert ZeroAddress();
        if(_newShare > 9999) revert InvalidRoyaltyShare();
        token_datas[_token_id].royalty_recipient = _newRecipient;
        token_datas[_token_id].royalty_share = _newShare;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, IERC165) returns (bool) {
        return (interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId));
    }

    /** 
    * @notice Taken from ERC1155Burnable burn method to let the contract define the burnability of tokens
    * 
    * @param account the address to burn from 
    * @param id the id of the token to burn
    * @param amount the amount of tokens to burn
    */
    function burn(address account, uint256 id, uint256 amount) public virtual whenNotPaused{
        if (!token_datas[id].burnable) revert Unburnable();
        if (!(account == _msgSender() || isApprovedForAll(account, _msgSender()))) revert NotTokenOwnerOrAuthorised();

        _burn(account, id, amount);
    }

    /** 
    * @notice Taken from ERC1155Burnable burnBatch method to let the contract define the burnability of tokens
    * 
    * @param account the address to burn from 
    * @param ids an array of ids of tokens to burn
    * @param amounts an array of amounts of tokens to burn
    * 
    * ids and amounts must be of the same length
    */
    function burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) public virtual whenNotPaused{
        for(uint i = 0; i < ids.length; i++) {
            if(!token_datas[ids[i]].burnable) revert Unburnable();            
        }
        if (!(account == _msgSender() || isApprovedForAll(account, _msgSender()))) revert NotTokenOwnerOrAuthorised();
        _burnBatch(account, ids, amounts);
    } 

    /// @notice Allow the owner to withdraw funds from the contract to the owner's wallet
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool succ,) = payable(msg.sender).call{
            value: balance
        }("");
        if(!succ) revert TransferFailed();
    }       

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal whenNotPaused virtual override(ERC1155) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        
        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                unchecked{
                    token_datas[ids[i]].mints_count[to] += amounts[i];
                    // MaxSupply is uint32 so this cast is safe
                    token_datas[ids[i]].total_supply += uint32(amounts[i]);
                }
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint32 amount = uint32(amounts[i]);
                uint32 supply = token_datas[id].total_supply;
                if(amount > supply) revert MaxSupply();
                unchecked {
                    token_datas[id].total_supply = supply - amount;
                }
            }
        }
    } 

    //************ SUPPORT FUNCTIONS ************//

    function elligible_mint(uint256 id, uint256 amount) view internal 
    returns(uint256 dynamicPrice) {
        TokenData storage td = token_datas[id];
        return elligible_mint(td, id, amount, td.use_dynamic_price, td.max_per_wallet, td.base_price);
    }

    function elligible_mint(uint256 _token_id, uint256 _amount, bool _load_dynamic_price, uint _wallet_max, uint _default_price) view internal 
    returns(uint256 dynamicPrice) {
        TokenData storage td =  token_datas[_token_id];  
        return elligible_mint(td, _token_id, _amount, _load_dynamic_price, _wallet_max, _default_price);
    }

    /// @notice Verifies the elligibility for a mint by a given wallet
    /// 
    /// @param td the inital token data
    /// @param _token_id The id of the token to mint
    /// @param _amount The amount of tokens to mint
    /// @param _load_dynamic_price whether or not it is necessary to compute a dynamic price or simply return the standard price
    /// @param _wallet_max the max_per_wallet condition to check (could come from a whitelist entry)
    /// @param _default_price the price to apply in case no dynamic price were found or it is disabled
    function elligible_mint(TokenData storage td, uint256 _token_id, uint256 _amount, bool _load_dynamic_price, uint _wallet_max, uint _default_price) view private tokenExist(_token_id)
    returns(uint256 dynamicPrice) {    
        uint32 _totalSupply = td.total_supply;
        if(_totalSupply + _amount > td.max_supply) revert MaxSupply();
        
        uint256 mintsCount = td.mints_count[_msgSender()];
        if(mintsCount + _amount > _wallet_max) revert MaxCount();

        if(tx.origin != _msgSender()) revert ContractMint();
        
        if (_load_dynamic_price) {
            return extractTotalPrice(_token_id, _default_price, _totalSupply, mintsCount, _amount);
        } else {
            return _default_price * _amount;
        }
    }

    function extractTotalPrice(uint256 _token_id, uint256 _base_price, uint32 total_supply, uint256 mintsCount, uint256 amount) view internal 
    returns(uint256) {
        uint256 value;
        for(uint i = 0; i < price_conditions[_token_id].length; i++) {
            if (price_condition_priority[i] == PriceCondition.SUPPLY) {
                value = total_supply;
            } else {
                value = mintsCount;
            }
            (bool triggered, uint256 price) = GsDynamicPrice.extractPrice(price_conditions[_token_id][i], value, _base_price, amount);
            if (triggered) return price;
        }

        return _base_price * amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    /**
     * @notice Returns true if operator is not filtered for a given token, either by address or codeHash. Also returns
     *         true if supplied registrant address is not registered.
     */
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);

    /**
     * @notice Registers an address with the registry. May be called by address itself or by EIP-173 owner.
     */
    function register(address registrant) external;

    /**
     * @notice Registers an address with the registry and "subscribes" to another address's filtered operators and codeHashes.
     */
    function registerAndSubscribe(address registrant, address subscription) external;

    /**
     * @notice Registers an address with the registry and copies the filtered operators and codeHashes from another
     *         address without subscribing.
     */
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;

    /**
     * @notice Unregisters an address with the registry and removes its subscription. May be called by address itself or by EIP-173 owner.
     *         Note that this does not remove any filtered addresses or codeHashes.
     *         Also note that any subscriptions to this registrant will still be active and follow the existing filtered addresses and codehashes.
     */
    function unregister(address addr) external;

    /**
     * @notice Update an operator address for a registered address - when filtered is true, the operator is filtered.
     */
    function updateOperator(address registrant, address operator, bool filtered) external;

    /**
     * @notice Update multiple operators for a registered address - when filtered is true, the operators will be filtered. Reverts on duplicates.
     */
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;

    /**
     * @notice Update a codeHash for a registered address - when filtered is true, the codeHash is filtered.
     */
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;

    /**
     * @notice Update multiple codeHashes for a registered address - when filtered is true, the codeHashes will be filtered. Reverts on duplicates.
     */
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;

    /**
     * @notice Subscribe an address to another registrant's filtered operators and codeHashes. Will remove previous
     *         subscription if present.
     *         Note that accounts with subscriptions may go on to subscribe to other accounts - in this case,
     *         subscriptions will not be forwarded. Instead the former subscription's existing entries will still be
     *         used.
     */
    function subscribe(address registrant, address registrantToSubscribe) external;

    /**
     * @notice Unsubscribe an address from its current subscribed registrant, and optionally copy its filtered operators and codeHashes.
     */
    function unsubscribe(address registrant, bool copyExistingEntries) external;

    /**
     * @notice Get the subscription address of a given registrant, if any.
     */
    function subscriptionOf(address addr) external returns (address registrant);

    /**
     * @notice Get the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscribers(address registrant) external returns (address[] memory);

    /**
     * @notice Get the subscriber at a given index in the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscriberAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Copy filtered operators and codeHashes from a different registrantToCopy to addr.
     */
    function copyEntriesOf(address registrant, address registrantToCopy) external;

    /**
     * @notice Returns true if operator is filtered by a given address or its subscription.
     */
    function isOperatorFiltered(address registrant, address operator) external returns (bool);

    /**
     * @notice Returns true if the hash of an address's code is filtered by a given address or its subscription.
     */
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);

    /**
     * @notice Returns true if a codeHash is filtered by a given address or its subscription.
     */
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);

    /**
     * @notice Returns a list of filtered operators for a given address or its subscription.
     */
    function filteredOperators(address addr) external returns (address[] memory);

    /**
     * @notice Returns the set of filtered codeHashes for a given address or its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);

    /**
     * @notice Returns the filtered operator at the given index of the set of filtered operators for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Returns the filtered codeHash at the given index of the list of filtered codeHashes for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);

    /**
     * @notice Returns true if an address has registered
     */
    function isRegistered(address addr) external returns (bool);

    /**
     * @dev Convenience method to compute the code hash of an arbitrary contract
     */
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;
/**
 * @title GS Dynamic Price 
 * @author www.geeks.solutions
 * @dev These functions helps to build a dynamic price based on a set of arbitrary conditions
 * It assumes the price rules list is sorted by ascending trigger values and provides a function
 * to check for the validity of a price rules list:
 *  - Makes sure the list is NOT empty
 *  - Makes sure the list sorted by ascending trigger values
 *  - Makes sure each entry contains a price that is >= 0
 * It also provides a function to extract the total price to charge based on an ordered list of price rules, a value and an amount
 * of tokens to mint to pull the right triggers
 */
library GsDynamicPrice {
    error InvalidRule();
    
    struct PriceRule {
        uint128 trigger;
        uint128 priceInWei;
    }

    /**
     * @dev Extracts the price from the list of price rules, if no rule is triggered, it returns the default price
     * It also returns a boolean indicating if a rule has been triggered
     * 
     * @param ordered_rules a list of price rules that is sorted by ascending trigger values
     * @param value the value that should be over the rule trigger value to execute the rule
     * @param defaultPrice the default price value to return in wei if no rule is triggered
     * @param amount the amount of tokens to be minted
     * @return triggered
     * @return price
     */
    function extractPrice(PriceRule[] storage ordered_rules, uint value, uint defaultPrice, uint amount) internal view 
    returns (bool triggered, uint price){
        uint length = ordered_rules.length;
        if (length == 0) { 
            // we have no rules to apply
            return (false, amount * defaultPrice);
        }
        bool value_found;
        bool value_before_first_rule;
        price = 0;
        PriceRule storage rule = ordered_rules[0];
        if (value < rule.trigger + 1) {
            value_before_first_rule = value_found = true;
            if (value + amount < rule.trigger + 1) {
                return (false, amount * defaultPrice);
            } else {
                unchecked {
                    price += (rule.trigger - value) * defaultPrice;
                }
            }
        }
        
        uint32 value_index = 0;
        for (uint32 i = 0; i < length; i++) {
            rule = ordered_rules[i];
            if (!value_found) {
                // Last rule in the list, we trigger if the value is >= to trigger in this case only as no rule exists above
                if (i == length - 1 && rule.trigger <= value) {
                    // The value triggers this rule and no rule after
                    return (true, amount * rule.priceInWei);
                } else if (rule.trigger < value && i < length - 1 &&  ordered_rules[i + 1].trigger > value) {
                    // the value triggers this rule and not the one above
                    value_found = true;
                    value_index = i; 
                } else if (rule.trigger < value && i < length - 1 &&  ordered_rules[i + 1].trigger < value) {
                    // the value is next
                    continue;
                }  
            }

            if (rule.trigger < value + amount  && 
                (i == length - 1 || (i < length - 1 && ordered_rules[i + 1].trigger + 1 > value + amount))) {
                // the total triggers this index and no rule after
                if (value_index == i && !value_before_first_rule) {
                    unchecked {
                        price += amount * rule.priceInWei;
                    }
                } else {
                    unchecked {
                        price += (value + amount - rule.trigger) * rule.priceInWei;
                    }
                }
                // we found the total in the current rule we return
                return (true, price);
            } else if (rule.trigger < value + amount && i < length - 1 && ordered_rules[i + 1].trigger < value + amount) {
                if (value_index == i && !value_before_first_rule) {
                    unchecked {
                        price += (ordered_rules[i + 1].trigger - value) * rule.priceInWei;
                    }
                } else {
                    unchecked {
                        price += (ordered_rules[i + 1].trigger - rule.trigger) * rule.priceInWei;
                    }
                }
                continue;
            } else if (value + amount < rule.trigger) {
                unchecked {
                    price += (value + amount - ordered_rules[i - 1].trigger) * ordered_rules[i - 1].priceInWei;
                }
                return (true, price);
            }
        }
    }

    /**
     * @dev This function is to be invoked by the contract before storing the rules list to guarantee the rules list will be compatible
     * with the `extractPrice` function
     * 
     * @param ordered_rules a list of price rules to check for validity
     */
    function checkValidRulesList(PriceRule[] calldata ordered_rules) internal pure returns(bool) {
        uint length = ordered_rules.length;
        if (length == 0) {return false;}

        uint trigger = 0;
        for (uint i = 0; i < length; i++) {
            if (trigger < ordered_rules[i].trigger && ordered_rules[i].priceInWei >= 0) { trigger = ordered_rules[i].trigger; }
            else { return false; }
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
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
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

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

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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