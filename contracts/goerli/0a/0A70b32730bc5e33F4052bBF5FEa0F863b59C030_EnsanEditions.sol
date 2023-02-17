// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./GsERC1155Merkle.sol";
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';

/**
 * @title ENSAN Editions tokens
 * @notice Can define new tokens on the GO and operate public and allow list gated mints
 * @author geeks.solutions  
*/
contract EnsanEditions is GsERC1155Merkle, DefaultOperatorFilterer {

    constructor() GsERC1155Merkle("Ensan Editions", "EES", "contractURI", msg.sender, 1000) DefaultOperatorFilterer() {} 

     /**
     * @notice Mints the given amount of token id to the specified receiver address
     * 
     * @param _token_id the token id to mint
     * @param _receiver the receiving wallet
     * @param _amount the amount of tokens to mint
     */
    function ownerMint(uint256 _token_id, address _receiver, uint256 _amount) external onlyOwner {
        require(_receiver != address(0), "Receiver is the zero address");
        super.elligible_mint(_token_id, _amount, false, false);

        _mint(_receiver, _token_id, _amount, "");        
    }      

    /**
    * @notice mint during public sale
    * 
    * @param _token_id the token id to mint
    * @param _amount the amount of tokens to mint
    */
    function publicMint(uint256 _token_id, uint256 _amount) external payable whenNotPaused whenPublicSaleIsActive(_token_id){
        (/*TokenData memory td*/, uint256 price, /*bool dynamicPrice*/) = super.elligible_mint(_token_id, _amount);

        require(msg.value >= (price * _amount), "Not enough ETH send to cover for the price");
        _mint(msg.sender, _token_id, _amount, "");
    }  

    /**
     * @notice Mints a token following a given whitelist conditions
     * 
     * @param token_id The token id to mint
     * @param wlIndex the index of the whitelist to use for this mint
     * @param amount the amount of tokens to mint
     * @param proof the proof to grant access to this whitelist
     */
    function specialMint(uint256 token_id, uint256 wlIndex, uint256 amount, bytes32[] calldata proof) external payable whenNotPaused {
        WhitelistData memory whitelist = super.elligible_claim(amount, token_id, wlIndex, proof);

        require(msg.value >= (whitelist.token_price * amount), "Not enough ETH send to cover for the price");
        _mint(msg.sender, token_id, amount, "");
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

/// @notice This contract adds a Merkle Tree based Whitelist to the GsERC1155 contract.
/// Multiple whitelists can exist for a given token ID
/// @author www.geeks.solutions
/// @dev You can use this contract as a parent for your collection and you can use
/// https://sections.geeks.solutions to get a ready frontend solution to run
/// your mint page that connects seamlessly to this contract
contract GsERC1155Merkle is GsERC1155 {
    struct WhitelistData {
        uint256 token_price;
        bool active;
        bytes32 merkle_root;
        uint8 max_per_wallet;
        bool use_dynamic_price;
    }

    // whitelist_datas[token_id][whitelist_index]
    mapping(uint256 => WhitelistData[]) internal whitelist_datas;

    /// @notice Builds a collection that can be whitelist gated
    constructor(string memory _name, string memory _symbol, string memory _contractURI, address _recipient, uint16 _royaltyShare) 
    GsERC1155(_name, _symbol, _contractURI, _recipient, _royaltyShare){}

    /// @notice Adds a new whitelist for a given token ID. The token must be defined. Whitelist index starts at 0
    /// 
    /// @param _token_id The Id of the token to create a whitelist for
    /// @param _wl_price_in_gwei The price in GWEI (https://eth-converter.com/) of the token when minting with this whitelist
    /// @param _merkle_root The merkle root to grant access to the whitelist
    /// @param _wl_max_per_wallet The maximum amount of tokens one can hold when minting using this whitelist
    /// @param _active Whether or not this whitelist is active and can be used to mint the token
    /// @param _use_dynamic_price a boolean to indicate if we should use the dynamic price or not
    /// @return whitelist_index
    function addNewWhitelist(uint256 _token_id, uint256 _wl_price_in_gwei, bytes32 _merkle_root, 
        uint8 _wl_max_per_wallet, bool _active, bool _use_dynamic_price) public onlyOwner
    returns(uint256 whitelist_index){
        require(token_datas[_token_id].exist, "This token ID is not defined");
        whitelist_datas[_token_id].push(
            WhitelistData({
                token_price: _wl_price_in_gwei * (1 gwei),
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
    /// @param _wl_price_in_gwei the price in GWEI (https://eth-converter.com/)
    /// @param _wl_max_per_wallet The maximum amount of tokens one can hold when minting using this whitelist
    /// @param _use_dynamic_price a boolean to indicate if we should use the dynamic price or not
    function editWhitelistFull(uint256 _whitelist_index, uint256 _token_id, uint256 _wl_price_in_gwei, bytes32 _merkle_root, 
        uint8 _wl_max_per_wallet, bool _active, bool _use_dynamic_price) public onlyOwner {
        require(_whitelist_index < whitelist_datas[_token_id].length, "This index does not exist");
        WhitelistData memory whitelist = whitelist_datas[_token_id][_whitelist_index];
        editWhitelist(whitelist, _token_id, _whitelist_index, _merkle_root, _active, _wl_price_in_gwei * (1 gwei), _wl_max_per_wallet, _use_dynamic_price);
        
    }

    /// @notice Partially edit the whitelist for a token id at a given index
    /// 
    /// @param _token_id The id of the token to edit the whitelist for
    /// @param _whitelist_index the index of the whitelist to edit
    /// @param _merkle_root the new merkle root to store for this whitelist
    /// @param _active  Whether or not this whitelist is active and can be used to mint the token
    function editWhitelistPartial(uint256 _whitelist_index, uint256 _token_id, bytes32 _merkle_root, bool _active, bool _use_dynamic_price) public onlyOwner {
        require(_whitelist_index < whitelist_datas[_token_id].length, "This index does not exist");
        WhitelistData memory whitelist = whitelist_datas[_token_id][_whitelist_index];
        editWhitelist(whitelist, _token_id, _whitelist_index, _merkle_root, _active, whitelist.token_price, whitelist.max_per_wallet, _use_dynamic_price);
    }

    function editWhitelist(WhitelistData memory _whitelist, uint256 _token_id, uint256 _whitelist_index, bytes32 _merkle_root, bool _active,
        uint256 _wl_price, uint8 _wl_max_per_wallet, bool _use_dynamic_price) internal {            
        require(_merkle_root != "", "the merkle root can't be empty");

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
    function getWhiteListAtIndex(uint256 _token_id, uint256 _whitelist_index) public view 
    returns(WhitelistData memory whitelist) {
        require(whitelist_datas[_token_id].length > _whitelist_index, "This whitelist index does not exist");
        return whitelist_datas[_token_id][_whitelist_index];
    }

    /// @notice Returns the number of whitelists defined for a given token id
    /// 
    /// @param _token_id The id of the token to get the count for
    /// @return length
    function getWhiteListLengthForToken(uint256 _token_id) public view returns(uint256 length) {
        return whitelist_datas[_token_id].length;
    }

    /// @notice Returns the price of a token based on its ID, the whitelist and the wallet requesting it
    /// price can be dynamic or static, whitelist can be set to override dynamic pricing
    /// 
    /// @param _token_id the token id to get the price for
    /// @param _whitelist_index the whitelist to check the price for
    /// @return isDynamicPrice
    /// @return price
    function getTokenPrice(uint256 _token_id, uint256 _whitelist_index) public view
    returns(bool, uint256) {
        WhitelistData memory _whitelist = getWhiteListAtIndex(_token_id, _whitelist_index); 
        if (!_whitelist.use_dynamic_price) return (false, _whitelist.token_price);
        else {
            (bool triggered, uint256 price) = super.getTokenPrice(_token_id);
            if (_whitelist.use_dynamic_price && triggered) { return (triggered, price); }
            else { return (false, _whitelist.token_price);}
        }
    }

    //************ SUPPORT FUNCTIONS ************//

    function elligible_claim(uint256 amount, uint256 _token_id, uint256 _whitelist_index, bytes32[] calldata _merkleProof, bytes32 _node) view internal 
    returns(WhitelistData memory whitelist){
        WhitelistData memory _whitelist = getWhiteListAtIndex(_token_id, _whitelist_index);
        (/* TokenData memory td */, uint256 userBalance, uint256 dynamicPrice, bool triggered) = super.elligible_mint(_token_id, amount, _whitelist.use_dynamic_price, false);
        if (_whitelist.use_dynamic_price && triggered) { _whitelist.token_price = dynamicPrice; }
        require(_whitelist.active, "This whitelist is not active");
        require(userBalance + amount <= _whitelist.max_per_wallet, "You have already claimed your allowance for this whitelist spot");
        require(MerkleProof.verifyCalldata(_merkleProof, _whitelist.merkle_root, _node), "Invalid Proof");
        return _whitelist;
    }

    /**
     * @notice This function checks for the elligibility for a user to mint a given amount of token id based on the proof
     * of a given whitelist index
     * @param _amount the amount of token to check mint elligibility for
     * @param _token_id the token id to check
     * @param _whitelist_index the whitelist index to check for
     * @param _merkleProof the proof of the Merkle tree provided by the user
     * @return whitelist
     */
    function elligible_claim(uint256 _amount, uint256 _token_id, uint256 _whitelist_index, bytes32[] calldata _merkleProof) view internal 
    returns(WhitelistData memory whitelist) {
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        return elligible_claim(_amount, _token_id, _whitelist_index, _merkleProof, node);
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
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import "./Libraries/GsDynamicPrice.sol";

/// @title A base class to create token IDs within an ERC1155 collection
/// @author www.geeks.solutions
/// @notice Each token definition carries a price, a max supply and certain mint rules
/// You can define as many tokens as you want. Once a token has been supplied the supply levels
/// and base prices are locked for this token ID.
/// You can also define pricing rules per token to have dynamic prices apply to tokens. 
/// pricing rules are based on ascending triggering values and can be based on 
/// token SUPPLY or wallet BALANCE or a combination of both
/// @dev You can define default values that will be used when creating new tokens
/// You can use this contract as a parent for your collection and you can use
/// https://sections.geeks.solutions to get a ready frontend solution to run
/// your mint page that connects seamlessly to this contract
contract GsERC1155 is ERC1155Supply, ERC1155Burnable, Ownable, Pausable, IERC2981 {
    
    enum PriceCondition{SUPPLY, BALANCE}

    string private name_;
    string private symbol_;
    string private contractURI_;   

    struct TokenData {
        uint256 base_price;
        uint16 royalty_share;
        bool public_sale;
        bool burnable;
        uint32 max_supply;
        uint8 max_per_wallet;
        bool exist;
        address royalty_recipient;
        string uri;
    }

    mapping(uint256 => TokenData) internal token_datas;
    mapping(uint256 => GsDynamicPrice.PriceRule[][]) internal price_conditions;
    
    TokenData private _default;
    PriceCondition[2] public price_condition_priority;

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
        _default.burnable = false;
        _default.max_supply = 1000;
        _default.max_per_wallet = 1;
        _default.exist = true;
        _default.royalty_recipient = _recipient;

        name_ = _name;
        symbol_ = _symbol;
        contractURI_ = _contractURI;

        price_condition_priority[0] = PriceCondition.SUPPLY;
        price_condition_priority[1] = PriceCondition.BALANCE;
    }

    function name() public view returns (string memory) {
        return name_;
    }

    function symbol() public view returns (string memory) {
        return symbol_;
    }  

    function contractURI() public view returns (string memory) {
        return contractURI_;
    }

    /// @notice Convenience function to update the URI of the contract metadata
    /// 
    /// @param _contractURI the new URI to set for your contract/collection metadata file
    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURI_ = _contractURI;
    }

    /// @notice This function is used to update a specific modifier for a given token id 
    /// @dev can only be called by the owner
    //
    /// @param _type the modifier to edit (1=public_sale, 2=burnable)
    /// @param _token_id The token ID to edit the modifier for
    /// @param _value the new modifier value
    function setModifier(uint32 _type, uint256 _token_id, bool _value) external onlyOwner {
        require(token_datas[_token_id].exist, "This token was not defined yet");
        if (_type == 1) {
            token_datas[_token_id].public_sale = _value;
        } else if (_type == 2) {
            token_datas[_token_id].burnable = _value;
        } else {
            revert("Unknown modifier type");
        }
    }

    modifier whenPublicSaleIsActive(uint256 _token_id) {
        require(
            token_datas[_token_id].public_sale, "Public sale is closed"
        );
        _;
    } 
    
    modifier whenBurnIsActive(uint256 _token_id) {
        require(
            token_datas[_token_id].burnable, "Token is not burnable"
        );
        _;
    } 

    modifier whenBurnIsActiveOnBatch(uint256[] memory _ids) {
        for(uint i = 0; i < _ids.length; i++) {
            require (
                token_datas[_ids[i]].burnable, "Token is not burnable"
            );
            
        }
        _;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /**
    * @notice returns the metadata uri for a given id
    * 
    * @param _token_id the token id to return metadata for
    */
    function uri(uint256 _token_id) public view override returns (string memory) {
        require(token_datas[_token_id].exist, "This token was not defined yet");
        return token_datas[_token_id].uri;
    } 

    /// @notice Updates the URI of a given token, can be called at any time (for simple reveals)
    /// 
    /// @param _token_id The id of the token to update
    /// @param _tokenURI The new URI to use for the token metadata (returned as is)
    function setURI(uint256 _token_id, string memory _tokenURI) external onlyOwner {
        require(token_datas[_token_id].exist, "This token was not defined yet");
        token_datas[_token_id].uri = _tokenURI;
    }

    function getDefaultTokenData() public view returns(TokenData memory) {
        return _default;
    }
    function setDefaultRoyalties(address _recipient, uint16 _share) public onlyOwner {
        _default.royalty_recipient = _recipient;
        _default.royalty_share = _share;
    }

    /// @notice this function updates the modifiers for the default values to use when creating new tokens
    //
    /// @param _publicSale the value to set for the public sale modifier
    /// @param _burnable the value to set for the burnable modifier
    function setDefaultModifiers(bool _publicSale, bool _burnable) public onlyOwner {
        _default.public_sale = _publicSale;
        _default.burnable = _burnable;
    }

    function setDefaultTokenMeta(uint32 _maxSupply, uint8 _maxPerWallet, uint256 _price_in_gwei) public onlyOwner {
        _default.max_supply = _maxSupply;
        _default.max_per_wallet = _maxPerWallet;
        _default.base_price = _price_in_gwei * (1 gwei);
    }

    /// @notice updates the default values to use when creating new tokens
    /// @dev can only be called by the owner 
    //
    /// @param _recipient the recipient address to receive royalties
    /// @param _share the share of royalties to distribute on each sale (1% = 100)
    /// @param _publicSale Enable public sale for new tokens as soon as they are defined
    /// @param _burnable Allow the tokens to be burned as soon as they are defined
    /// @param _maxSupply The maximum Supply for new token creations
    /// @param _maxPerWallet The maximum number of token a given wallet can hold when minting
    /// @param _price_in_gwei The token price in GWEI (check https://eth-converter.com/ for help)
    function setDefaults(address _recipient, uint16 _share,
        bool _publicSale, bool _burnable,
        uint32 _maxSupply, uint8 _maxPerWallet, uint256 _price_in_gwei) external onlyOwner {
            setDefaultRoyalties(_recipient, _share);
            setDefaultModifiers(_publicSale, _burnable);
            setDefaultTokenMeta(_maxSupply, _maxPerWallet, _price_in_gwei);
    }

    function getTokenData(uint256 id) public view returns(TokenData memory) {
        return token_datas[id];
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
    /// @param _tokenMaxPerWallet The maximum amount of token a wallet can hold when minting
    /// @param price_in_gwei The price of the token in Gwei (https://eth-converter.com/)
    /// @param _tokenRoyaltyShare The share of royalty to send to the recipient on each sale (1% = 100)
    /// @param _tokenRoyaltyRecipient The recipient address to receive royalties on each sale
    function addNewToken(uint256 _tokenId, 
        string memory _tokenUri, 
        bool _tokenPublicSale, 
        bool _tokenBurnable,
        uint32 _tokenMaxSupply,
        uint8 _tokenMaxPerWallet,
        uint256 price_in_gwei,
        uint16 _tokenRoyaltyShare,
        address _tokenRoyaltyRecipient) public onlyOwner {
            addToken(_tokenId, _tokenUri, _tokenPublicSale, _tokenBurnable, _tokenMaxSupply, 
            _tokenMaxPerWallet, price_in_gwei * (1 gwei), _tokenRoyaltyShare, _tokenRoyaltyRecipient);
    }

    /// @notice Adds a new token by using default token values
    /// Updates the token if it's been declared but not yet supplied. Rejects if the token id has been supplied already
    /// @dev Can only be called by the owner
    //
    /// @param _tokenId the ID to use for this token
    /// @param _tokenUri The URI for this token metadata (returned as is)
    function addNewTokenLight(uint256 _tokenId, string memory _tokenUri) public onlyOwner {
            addToken(_tokenId, _tokenUri, _default.public_sale, _default.burnable, _default.max_supply,
            _default.max_per_wallet, _default.base_price, _default.royalty_share, _default.royalty_recipient);
    }

    function addToken(uint256 _tokenId, 
        string memory _tokenUri, 
        bool _tokenPublicSale, 
        bool _tokenBurnable,
        uint32 _tokenMaxSupply,
        uint8 _tokenMaxPerWallet,
        uint256 _tokenPrice,
        uint16 _tokenRoyaltyShare,
        address _tokenRoyaltyRecipient) internal {
            require(!exists(_tokenId), "This token already exists");
            token_datas[_tokenId] = TokenData({
                base_price: _tokenPrice,
                royalty_share: _tokenRoyaltyShare,
                public_sale: _tokenPublicSale, 
                burnable: _tokenBurnable,
                max_supply: _tokenMaxSupply,
                max_per_wallet: _tokenMaxPerWallet,
                exist: true,
                royalty_recipient: _tokenRoyaltyRecipient,
                uri: _tokenUri
            });
    }

    /// @notice Updates a given token Supply and price only if it hasn't been supplied
    //
    /// @param _tokenId The token ID to update
    /// @param _maxSupply The new maximum Supply to define for this token
    /// @param _maxPerWallet The maximum 
    /// @param _price_in_gwei The new price in GWEI (https://eth-converter.com/)
    function editTokenMeta(uint256 _tokenId, uint32 _maxSupply, uint8 _maxPerWallet, uint64 _price_in_gwei) public onlyOwner {
        require(!exists(_tokenId), "token locked by supply");
        token_datas[_tokenId].max_supply = _maxSupply;
        token_datas[_tokenId].max_per_wallet = _maxPerWallet;
        token_datas[_tokenId].base_price = _price_in_gwei * (1 gwei);
    }

    /// @notice Returns the price of a token based on its ID and the wallet requesting it
    /// price can be dynamic or static
    //
    /// @param token_id the token id to get the price for
    /// @return isDynamicPrice 
    /// @return price 
    function getTokenPrice(uint256 token_id) public view returns(bool isDynamicPrice, uint256 price){
        TokenData memory td = token_datas[token_id];
        uint256 _totalSupply = totalSupply(token_id);
        uint256 userBalance = balanceOf(msg.sender, token_id);
        require(td.exist, "Token has not been defined yet");
        return extractDynamicPrice(token_id, td, _totalSupply, userBalance);
    }

    /// @notice Returns the Price condition type at priority index and the price rules associated for this token
    /// 
    /// @param _token_id the token id to get the price rules for
    /// @param _priority_index the priority index to return rules for
    function getPriceRules(uint256 _token_id, uint8 _priority_index) public view
     returns(PriceCondition, GsDynamicPrice.PriceRule[] memory){
        require(_priority_index < price_conditions[_token_id].length, "Priority Index is out of range");
        return (price_condition_priority[_priority_index], price_conditions[_token_id][_priority_index]);
    }

    /// @notice Reverse the order of priority between `SUPPLY` and `BALANCE`
    /// @dev this does not change the entries in the `price_conditions` map it only reassigns the value they compare against
    function reversePriceConditionPriority() public onlyOwner {
        PriceCondition[2] memory tmp = price_condition_priority;

        price_condition_priority[0] = tmp[1];
        price_condition_priority[1] = tmp[0];
    }

    /// @notice Add a price rule in the `price_conditions` map
    /// @dev the `price_conditions` map is as follows `price_conditions[uint256][priority_index][]`
    /// we need to iterate over the calldata array to manually convert to storage as calldata[] to storage conversion
    /// is not supported
    /// 
    /// @param _token_id the token id to add a price rule list for
    /// @param _ordered_rules the list of rules to add, has to be correctly formatted and in the right order
    function addPriceRules(uint256 _token_id, GsDynamicPrice.PriceRule[] calldata _ordered_rules) public onlyOwner {
        require(token_datas[_token_id].exist, "This token was not defined yet");
        require(GsDynamicPrice.checkValidRulesList(_ordered_rules), "Invalid ordered rules");
        uint256 new_index = price_conditions[_token_id].length;
        require(new_index < price_condition_priority.length, "Price Rules list is already full");
        price_conditions[_token_id].push();
        for(uint i = 0; i < _ordered_rules.length; i++) {
            price_conditions[_token_id][new_index].push(_ordered_rules[i]);
        }
    }

    /// @notice Update an existing price rule list
    /// @dev see `addPriceRules` for more details
    /// 
    /// @param _token_id the token id to update the price rules list for
    /// @param _priority_index the price rule index to update
    /// @param _ordered_rules the price rules list
    function updatePriceRules(uint256 _token_id, uint8 _priority_index, GsDynamicPrice.PriceRule[] calldata _ordered_rules) public onlyOwner {
        require(token_datas[_token_id].exist, "This token was not defined yet");
        require(_priority_index < price_conditions[_token_id].length, "Priority Index is out of range");
        require(GsDynamicPrice.checkValidRulesList(_ordered_rules), "Invalid ordered rules");
        
        for(uint i = 0; i < _ordered_rules.length; i++) {
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
        TokenData memory td = token_datas[_token_id];
        return (td.royalty_recipient, (_salePrice * td.royalty_share) / 10000);
    }

    /// @notice Updates the Royalty parameters for a given token
    /// 
    /// @param _token_id the id of the token to update royalty param for
    /// @param _newRecipient the new recipient address
    /// @param _newShare the new share to take from each sale (1% = 100)
    function setRoyalties(uint256 _token_id, address _newRecipient, uint8 _newShare) external onlyOwner {
        require(token_datas[_token_id].exist, "This token was not defined yet");
        require(_newRecipient != address(0), "Royalties: new recipient is the zero address");
        require(_newShare > 0 && _newShare < 10000, "Royalties: new share should be between 1 and 9999 basis points");
        token_datas[_token_id].royalty_recipient = _newRecipient;
        token_datas[_token_id].royalty_share = _newShare;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, IERC165) returns (bool) {
        return (interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId));
    }

    /** 
    * @notice Override ERC1155Burnable burn method to let the contract define the burnability of tokens
    * 
    * @param account the address to burn from 
    * @param id the id of the token to burn
    * @param amount the amount of tokens to burn
    */
    function burn(address account, uint256 id, uint256 amount) public whenNotPaused whenBurnIsActive(id) override(ERC1155Burnable){
        super.burn(account, id, amount);
    }

    /** 
    * @notice Override ERC1155Burnable burnBatch method to let the contract define the burnability of tokens
    * 
    * @param account the address to burn from 
    * @param ids an array of ids of tokens to burn
    * @param amounts an array of amounts of tokens to burn
    * 
    * ids and amounts must be of the same length
    */
    function burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) public whenNotPaused whenBurnIsActiveOnBatch(ids) override(ERC1155Burnable){
        super.burnBatch(account, ids, amounts);
    } 

    /// @notice Allow the owner to withdraw funds from the contract to the owner's wallet
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool succ,) = payable(msg.sender).call{
            value: balance
        }("");
        require(succ, "transfer failed");
    }       

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal whenNotPaused virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    } 

    //************ SUPPORT FUNCTIONS ************//

    function elligible_mint(uint256 id, uint256 amount) view internal 
    returns(TokenData memory, uint256, bool) {
        (TokenData memory td, /* uint256 userBalance */, uint256 dynamicPrice, bool triggered) = elligible_mint(id, amount, true, true);
        return (td, dynamicPrice, triggered);
    }

    /// @notice Verifies the elligibility for a mint by a given wallet
    /// 
    /// @param _token_id The id of the token to mint
    /// @param _amount The amount of tokens to mint
    /// @param _check_wallet_max Whether or not to check for the max_per_wallet condition
    function elligible_mint(uint256 _token_id, uint256 _amount, bool _load_dynamic_price, bool _check_wallet_max) view internal 
    returns(TokenData memory, uint256, uint256, bool) {
        TokenData memory td = token_datas[_token_id];
        uint256 _totalSupply = totalSupply(_token_id);
        uint256 userBalance = balanceOf(msg.sender, _token_id);
        require(tx.origin == msg.sender, "No contract minting");
        require(td.exist, "Token has not been defined yet");
        require(_totalSupply + _amount <= td.max_supply, "Max supply reached");
        if(_check_wallet_max) {
            require(userBalance + _amount <= td.max_per_wallet, "Max mint limit reached");
        }
        if (_load_dynamic_price) {
            (bool triggered, uint256 dynamicPrice) = extractDynamicPrice(_token_id, td, _totalSupply, userBalance);
            return (td, userBalance, dynamicPrice, triggered);
        } else {
            return (td, userBalance, td.base_price, false);
        }
    }

    function extractDynamicPrice(uint256 _token_id, TokenData memory _td, uint256 total_supply, uint256 balance) view private returns(bool, uint256) {
        uint256 value;
        for(uint i = 0; i < price_conditions[_token_id].length; i++) {
            if (price_condition_priority[i] == PriceCondition.SUPPLY) {
                value = total_supply;
            } else {
                value = balance;
            }

            (bool triggered, uint256 price) = GsDynamicPrice.extractPrice(price_conditions[_token_id][i], value, _td.base_price);
            if (triggered) { return (triggered, price); }
        }

        return (false, _td.base_price);
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
 * @author Geeks.solutions
 * @dev These functions helps to build a dynamic price based on a set of arbitrary conditions
 * It assumes the price rules list is sorted by ascending trigger values and provides a function
 * to check for the validity of a price rules list:
 *  - Makes sure the list is NOT empty
 *  - Makes sure the list sorted by ascending trigger values
 *  - Makes sure each entry contains a price that is >= 0
 * It also provides a function to extract the price from an ordered list of price rules and a value to pull the right trigger
 */
library GsDynamicPrice {
    struct PriceRule {
        uint256 trigger;
        uint256 price;
    }

    /**
     * @dev Extracts the price from the list of price rules, if no rule is triggered, it returns the default price
     * It also returns a boolean indicating if a rule has been triggered
     * 
     * @param ordered_rules a list of price rules that is sorted by ascending trigger values
     * @param value the value that should be over the rule trigger value to execute the rule
     * @param defaultPrice the default price value to return if no rule is triggered
     * @return triggered
     * @return price
     */
    function extractPrice(PriceRule[] memory ordered_rules, uint256 value, uint256 defaultPrice) internal pure 
    returns(bool triggered, uint256 price) {
        uint256 length = ordered_rules.length;
        if (length == 0) {
            return (false, defaultPrice);
        } else {
            PriceRule memory current_rule = ordered_rules[0];
            if (current_rule.trigger >= value) {
                // the current rule hasn't been triggered yet, no need to continue, we return the default price
                return (false, defaultPrice);
            } else {
                // The current rule is triggered, we check if there's a bigger trigger to execute
                return (true, recursiveExtract(ordered_rules, current_rule, value, defaultPrice, length, 1));
            }
        }
    }

    function recursiveExtract(
        PriceRule[] memory ordered_rules, 
        PriceRule memory current_rule,
        uint256 value, 
        uint256 defaultPrice, 
        uint256 length, 
        uint32 next_index) private pure returns(uint256) 
    {
        // We have a next rule
        if (next_index < length) {
            PriceRule memory next_rule = ordered_rules[next_index];
            if (next_rule.trigger >= value) { 
                // The next rule isn't triggered, the current one is the one to fire
                return current_rule.price;
            } else { 
                // the next rule is triggered too, we check if there's a bigger one to trigger instead
                return recursiveExtract(ordered_rules, next_rule, value, defaultPrice, length, next_index + 1);
            }
        } else { // we are checking the last rule in the list (biggest trigger)
            return current_rule.price;
        }
    }

    /**
     * @dev This function is to be invoked by the contract before storing the rules list to guarantee the rules list will be compatible
     * with the `extractPrice` function
     * 
     * @param ordered_rules a list of price rules to check for validity
     */
    function checkValidRulesList(PriceRule[] memory ordered_rules) internal pure returns(bool) {
        uint256 length = ordered_rules.length;
        if (length == 0) {return false;}

        uint256 trigger = 0;
        for (uint256 i = 0; i < length; i++) {
            if (trigger < ordered_rules[i].trigger && ordered_rules[i].price >= 0) { trigger = ordered_rules[i].trigger; }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burnBatch(account, ids, values);
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