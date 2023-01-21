/**
 *Submitted for verification at Etherscan.io on 2023-01-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

//import "../utils/Context.sol";
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


//import "@openzeppelin/contracts/access/Ownable.sol";
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
    constructor(address initialOwner) {
        _transferOwnership(initialOwner);
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


//import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


//import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
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

//import "./Common/IMintable.sol";
//--------------------------------------------
// Mintable intterface
//--------------------------------------------
interface IMintable {
    //----------------
    // write
    //----------------
    function mintByMinter( address to, uint256 tokenId ) external;
}


//------------------------------------------------------------
// Vendor
//------------------------------------------------------------
contract Vendor is Ownable, ReentrancyGuard {
    //--------------------------------------------------------
    // constant
    //--------------------------------------------------------
/*
    //-------------------
    // mainnet
    //-------------------
    address constant private OWNER_ADDRESS = 0x0000000000000000000000000000000000000000;
    address constant private TOKEN_ADDRESS = 0x0000000000000000000000000000000000000000;    

    address constant private CREATOR_ADDRESS_0 = 0x0000000000000000000000000000000000000000;
    uint256 constant private CREATOR_FEE_WEIGHT_0 = 875;    // 87.5%

    address constant private CREATOR_ADDRESS_1 = 0x0000000000000000000000000000000000000000;
    uint256 constant private CREATOR_FEE_WEIGHT_1 = 125;    // 12.5%
*/

    //-------------------
    // testnet
    //-------------------
    address constant private OWNER_ADDRESS = 0xf7831EA80Fc5179f86f82Af3aedDF2b7a2Ce13Df;
    address constant private TOKEN_ADDRESS = 0x2d540881446e0Bc8AAfDd3d29C7638a62C2431B7;

    address constant private CREATOR_ADDRESS_0 = 0xf7831EA80Fc5179f86f82Af3aedDF2b7a2Ce13Df;
    uint256 constant private CREATOR_FEE_WEIGHT_0 = 875;    // 87.5%

    address constant private CREATOR_ADDRESS_1 = 0x89Dac91B2c548D625e4982f07eD36950bB8caEd0;
    uint256 constant private CREATOR_FEE_WEIGHT_1 = 125;    // 12.5%

    uint256 constant private COLOR_NUM = 10;
    uint256 constant private BLOCK_SEC_MARGIN = 30;

    // enum
    uint256 constant private INFO_SALE_SUSPENDED = 0;
    uint256 constant private INFO_SALE_START = 1;
    uint256 constant private INFO_SALE_END = 2;
    uint256 constant private INFO_SALE_PRICE = 3;
    uint256 constant private INFO_SALE_WHITELISTED = 4;
    uint256 constant private INFO_SALE_USER_MINTABLE = 5;
    uint256 constant private INFO_SALE_USER_MINTED = 6;
    uint256 constant private INFO_SALE_USER_LIMIT = 7;
    uint256 constant private INFO_MAX = 8;

    uint256 constant private USER_INFO_SALE_TYPE = INFO_MAX;
    uint256 constant private USER_INFO_MINTABLE = INFO_MAX + 1;
    uint256 constant private USER_INFO_MINTED = INFO_MAX + 2;
    uint256 constant private USER_INFO_TOKEN_MAX = INFO_MAX + 3;
    uint256 constant private USER_INFO_TOTAL_MINTED = INFO_MAX + 4;
    uint256 constant private USER_INFO_TOKEN_MAX_PER_COLOR = INFO_MAX + 5;
    uint256 constant private USER_INFO_COLOR_MINTED = INFO_MAX + 6;
    uint256 constant private USER_INFO_MAX = USER_INFO_COLOR_MINTED + COLOR_NUM;

    //--------------------------------------------------------
    // storage
    //--------------------------------------------------------
    address private _manager;

    IMintable private _token;
    uint256 private _token_id_ofs;
    uint256 private _token_max;
    uint256 private _token_max_per_color;
    uint256 private _token_max_per_user;
    uint256 private _token_reserved;

    uint256 private _total_minted;
    uint256[COLOR_NUM] private _arr_color_minted;

    //*** PRIVATE(whitelist) ***
    bool private _PRIVATE_is_suspended;
    uint256 private _PRIVATE_start;
    uint256 private _PRIVATE_end;
    uint256 private _PRIVATE_price;
    bytes32 private _PRIVATE_merkle_root;
    mapping( address => uint256 ) private _PRIVATE_map_user_minted;

    //~~~ PARTNER(whitelist) ~~~
    bool private _PARTNER_is_suspended;
    uint256 private _PARTNER_start;
    uint256 private _PARTNER_end;
    uint256 private _PARTNER_price;
    bytes32 private _PARTNER_merkle_root;
    mapping( address => uint256 ) private _PARTNER_map_user_minted;

    //=== PUBLIC ===
    bool private _PUBLIC_is_suspended;
    uint256 private _PUBLIC_start;
    uint256 private _PUBLIC_end;
    uint256 private _PUBLIC_price;
    mapping( address => uint256 ) private _PUBLIC_map_user_minted;

    //+++ CREATOR +++
    address[] private _arr_creator;
    uint256[] private _arr_creator_fee_weight;

    //--------------------------------------------------------
    // [modifier] onlyOwnerOrManager
    //--------------------------------------------------------
    modifier onlyOwnerOrManager() {
        require( msg.sender == owner() || msg.sender == manager(), "caller is not the owner neither manager" );
        _;
    }

    //--------------------------------------------------------
    // constructor
    //--------------------------------------------------------
    constructor() Ownable( OWNER_ADDRESS ) {
        _manager = msg.sender;

        _token = IMintable(TOKEN_ADDRESS);

        _arr_creator.push( CREATOR_ADDRESS_0 );
        _arr_creator_fee_weight.push( CREATOR_FEE_WEIGHT_0 );

        _arr_creator.push( CREATOR_ADDRESS_1 );
        _arr_creator_fee_weight.push( CREATOR_FEE_WEIGHT_1 );

/*
        //-----------------------
        // mainnet
        //-----------------------
        _token_id_ofs = 1;
        _token_max = 5000;
        _token_max_per_color = 500;
        _token_max_per_user = 5;
        _token_reserved = 500;
*/

        //-----------------------
        // testnet
        //-----------------------
        _token_id_ofs = 1;
        _token_max = 50;
        _token_max_per_color = 5;
        _token_max_per_user = 5;
        _token_reserved = 10;

        //***********************
        // PRIVATE(whitelist)
        //***********************
        _PRIVATE_start = 1674264600;               // test 2023-01-21 10:30:00(JST)
        _PRIVATE_end   = 1674266400;               // test 2023-01-21 11:00:00(JST)
        _PRIVATE_price = 10000000000000000;        // 0.01 ETH
        _PRIVATE_merkle_root = 0xb8e78e479e04a0bab61fa4fd4a277b937ff4fd440f0361d6fc6d792398e8a2e9;
        
        //~~~~~~~~~~~~~~~~~~~~~~~
        // PARTNER(whitelist)
        //~~~~~~~~~~~~~~~~~~~~~~~
        _PARTNER_start = 1674266400;               // test 2023-01-21 11:00:00(JST)
        _PARTNER_end   = 1674268200;               // test 2023-01-21 11:30:00(JST)
        _PARTNER_price = 12000000000000000;        // 0.012 ETH
        _PARTNER_merkle_root = 0x4fb2fe950ed62376c2367e151301990772b2ea59da55b9efe34a1fc16dd0fd3d;

        //=======================
        // PUBLIC
        //=======================
        _PUBLIC_start = 1674268200;               // test 2023-01-21 11:30:00(JST)
        _PUBLIC_end   = 0;                        // test endless
        _PUBLIC_price = 15000000000000000;        // 0.015 ETH

    }

    //--------------------------------------------------------
    // [public] manager
    //--------------------------------------------------------
    function manager() public view returns (address) {
        return( _manager );
    }

    //--------------------------------------------------------
    // [external/onlyOwner] setManager
    //--------------------------------------------------------
    function setManager( address target ) external onlyOwner {
        _manager = target;
    }

    //--------------------------------------------------------
    // [external] get
    //--------------------------------------------------------
    function token() external view returns (address) { return( address(_token) ); }
    function tokenIdOfs() external view returns (uint256) { return( _token_id_ofs ); }
    function tokenMax() external view returns (uint256) { return( _token_max ); }
    function tokenMaxPerColor() external view returns (uint256) { return( _token_max_per_color ); }
    function tokenMaxPerUser() external view returns (uint256) { return( _token_max_per_user ); }
    function tokenReserved() external view returns (uint256) { return( _token_reserved ); }

    function totalMinted() external view returns (uint256) { return( _total_minted ); }
    function colorMintedAt( uint256 colorId ) external view returns (uint256) { return( _arr_color_minted[colorId] ); }
    function userMinted( address target ) external view returns (uint256) { return( _getUserMinted( target ) ); }

    //--------------------------------------------------------
    // [external/onlyOwnerOrManager] set
    //--------------------------------------------------------
    function setToken( address target ) external onlyOwnerOrManager { _token = IMintable(target); }
    function setTokenIdOfs( uint256 ofs ) external onlyOwnerOrManager { _token_id_ofs = ofs; }
    function setTokenMax( uint256 max ) external onlyOwnerOrManager { _token_max = max; }
    function setTokenMaxPerColor( uint256 max ) external onlyOwnerOrManager { _token_max_per_color = max; }
    function setTokenMaxPerUser( uint256 max ) external onlyOwnerOrManager { _token_max_per_user = max; }
    function setTokenReserved( uint256 reserved ) external onlyOwnerOrManager { _token_reserved = reserved; }

    //***********************************************************
    // [public] getInfo - PRIVATE(whitelist)
    //***********************************************************
    function PRIVATE_getInfo( address target, uint256 amount, bytes32[] calldata merkleProof ) public view returns (uint256[INFO_MAX] memory) {
        uint256[INFO_MAX] memory arrRet;

        if( _PRIVATE_is_suspended ){ arrRet[INFO_SALE_SUSPENDED] = 1; }
        arrRet[INFO_SALE_START] = _PRIVATE_start;
        arrRet[INFO_SALE_END] = _PRIVATE_end;
        arrRet[INFO_SALE_PRICE] = _PRIVATE_price;
        if( _checkWhitelisted( _PRIVATE_merkle_root, target, amount, merkleProof ) ){
            arrRet[INFO_SALE_WHITELISTED] = 1;
            arrRet[INFO_SALE_USER_MINTABLE] = amount;
        }
        arrRet[INFO_SALE_USER_MINTED] = _PRIVATE_map_user_minted[target];
        arrRet[INFO_SALE_USER_LIMIT] = _checkUserLimit( target, arrRet[INFO_SALE_USER_MINTABLE] );

        return( arrRet );
    }

    //***********************************************************
    // [external/onlyOwnerOrManager] write - PRIVATE(whitelist)
    //***********************************************************
    function PRIVATE_suspend( bool flag ) external onlyOwnerOrManager { _PRIVATE_is_suspended = flag; }
    function PRIVATE_setStartEnd( uint256 start, uint256 end ) external onlyOwnerOrManager { _PRIVATE_start = start; _PRIVATE_end = end; }
    function PRIVATE_setPrice( uint256 price ) external onlyOwnerOrManager { _PRIVATE_price = price; }
    function PRIVATE_setMerkleRoot( bytes32 root ) external onlyOwnerOrManager { _PRIVATE_merkle_root = root; }

    //***********************************************************
    // [external/payable/nonReentrant] mint - PRIVATE(whitelist)
    //***********************************************************
    function PRIVATE_mint( uint256[] calldata colorIds, uint256[] calldata nums, uint256 amount, bytes32[] calldata merkleProof ) external payable nonReentrant {
        require( _total_minted >= _token_reserved, "PRIVATE SALE: reservation not finished" );

        uint256[INFO_MAX] memory arrInfo = PRIVATE_getInfo( msg.sender, amount, merkleProof );
        require( arrInfo[INFO_SALE_SUSPENDED] == 0, "PRIVATE SALE: suspended" );
        require( arrInfo[INFO_SALE_START] == 0 || arrInfo[INFO_SALE_START] <= (block.timestamp+BLOCK_SEC_MARGIN), "PRIVATE SALE: not opend" );
        require( arrInfo[INFO_SALE_END] == 0 || (arrInfo[INFO_SALE_END]+BLOCK_SEC_MARGIN) > block.timestamp, "PRIVATE SALE: finished" );
        require( arrInfo[INFO_SALE_WHITELISTED] == 1, "PRIVATE SALE: not whitelisted" );

        require( colorIds.length == nums.length, "PRIVATE SALE: invalid array sizes" );
        uint256 num;
        for( uint256 i=0; i<nums.length; i++ ){ num += nums[i]; }
        require( arrInfo[INFO_SALE_USER_MINTABLE] >= (arrInfo[INFO_SALE_USER_MINTED]+num), "PRIVATE SALE: reached the sale limit" );
        require( arrInfo[INFO_SALE_USER_LIMIT] >= num, "PRIVATE SALE: reached the user limit" );

        _checkPayment( msg.sender, arrInfo[INFO_SALE_PRICE]*num, msg.value );

        for( uint256 i=0; i<colorIds.length; i++ ){
            _mintTokens( msg.sender, colorIds[i], nums[i] );
        }

        _PRIVATE_map_user_minted[msg.sender] += num;
    }

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // [public] getInfo - PARTNER
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    function PARTNER_getInfo( address target, uint256 amount, bytes32[] calldata merkleProof ) public view returns (uint256[INFO_MAX] memory) {
        uint256[INFO_MAX] memory arrRet;

        if( _PARTNER_is_suspended ){ arrRet[INFO_SALE_SUSPENDED] = 1; }
        arrRet[INFO_SALE_START] = _PARTNER_start;
        arrRet[INFO_SALE_END] = _PARTNER_end;
        arrRet[INFO_SALE_PRICE] = _PARTNER_price;
        if( _checkWhitelisted( _PARTNER_merkle_root, target, amount, merkleProof ) ){
            arrRet[INFO_SALE_WHITELISTED] = 1;
            arrRet[INFO_SALE_USER_MINTABLE] = amount;
        }
        arrRet[INFO_SALE_USER_MINTED] = _PARTNER_map_user_minted[target];
        arrRet[INFO_SALE_USER_LIMIT] = _checkUserLimit( target, arrRet[INFO_SALE_USER_MINTABLE] );

        return( arrRet );
    }

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // [external/onlyOwnerOrManager] write - PARTNER
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    function PARTNER_suspend( bool flag ) external onlyOwnerOrManager { _PARTNER_is_suspended = flag; }
    function PARTNER_setStartEnd( uint256 start, uint256 end ) external onlyOwnerOrManager { _PARTNER_start = start; _PARTNER_end = end; }
    function PARTNER_setPrice( uint256 price ) external onlyOwnerOrManager { _PARTNER_price = price; }
    function PARTNER_setMerkleRoot( bytes32 root ) external onlyOwnerOrManager { _PARTNER_merkle_root = root; }

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // [external/payable/nonReentrant] mint - PARTNER(whitelist)
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    function PARTNER_mint( uint256[] calldata colorIds, uint256[] calldata nums, uint256 amount, bytes32[] calldata merkleProof ) external payable nonReentrant {
        require( _total_minted >= _token_reserved, "PARTNER SALE: reservation not finished" );

        uint256[INFO_MAX] memory arrInfo = PARTNER_getInfo( msg.sender, amount, merkleProof );
        require( arrInfo[INFO_SALE_SUSPENDED] == 0, "PARTNER SALE: suspended" );
        require( arrInfo[INFO_SALE_START] == 0 || arrInfo[INFO_SALE_START] <= (block.timestamp+BLOCK_SEC_MARGIN), "PARTNER SALE: not opend" );
        require( arrInfo[INFO_SALE_END] == 0 || (arrInfo[INFO_SALE_END]+BLOCK_SEC_MARGIN) > block.timestamp, "PARTNER SALE: finished" );
        require( arrInfo[INFO_SALE_WHITELISTED] == 1, "PARTNER SALE: not whitelisted" );

        require( colorIds.length == nums.length, "PARTNER SALE: invalid array sizes" );
        uint256 num;
        for( uint256 i=0; i<nums.length; i++ ){ num += nums[i]; }
        require( arrInfo[INFO_SALE_USER_MINTABLE] >= (arrInfo[INFO_SALE_USER_MINTED]+num), "PARTNER SALE: reached the sale limit" );
        require( arrInfo[INFO_SALE_USER_LIMIT] >= num, "PARTNER SALE: reached the user limit" );

        _checkPayment( msg.sender, arrInfo[INFO_SALE_PRICE]*num, msg.value );

        for( uint256 i=0; i<colorIds.length; i++ ){
            _mintTokens( msg.sender, colorIds[i], nums[i] );
        }

        _PARTNER_map_user_minted[msg.sender] += num;
    }

    //===========================================================
    // [public] getInfo - PUBLIC
    //===========================================================
    function PUBLIC_getInfo( address target ) public view returns (uint256[INFO_MAX] memory) {
        uint256[INFO_MAX] memory arrRet;

        if( _PUBLIC_is_suspended ){ arrRet[INFO_SALE_SUSPENDED] = 1; }
        arrRet[INFO_SALE_START] = _PUBLIC_start;
        arrRet[INFO_SALE_END] = _PUBLIC_end;
        arrRet[INFO_SALE_PRICE] = _PUBLIC_price;
        arrRet[INFO_SALE_WHITELISTED] = 1;
        arrRet[INFO_SALE_USER_MINTABLE] = _token_max_per_user;
        arrRet[INFO_SALE_USER_MINTED] = _PUBLIC_map_user_minted[target];
        arrRet[INFO_SALE_USER_LIMIT] = _checkUserLimit( target, arrRet[INFO_SALE_USER_MINTABLE] );

        return( arrRet );
    }

    //===========================================================
    // [external/onlyOwnerOrManager] write - PUBLIC
    //===========================================================
    function PUBLIC_suspend( bool flag ) external onlyOwnerOrManager { _PUBLIC_is_suspended = flag; }
    function PUBLIC_setStartEnd( uint256 start, uint256 end ) external onlyOwnerOrManager { _PUBLIC_start = start; _PUBLIC_end = end; }
    function PUBLIC_setPrice( uint256 price ) external onlyOwnerOrManager { _PUBLIC_price = price; }

    //===========================================================
    // [external/payable/nonReentrant] mint - PUBLIC
    //===========================================================
    function PUBLIC_mint( uint256[] calldata colorIds, uint256[] calldata nums ) external payable nonReentrant {
        require( _total_minted >= _token_reserved, "PUBLIC SALE: reservation not finished" );

        uint256[INFO_MAX] memory arrInfo = PUBLIC_getInfo( msg.sender );
        require( arrInfo[INFO_SALE_SUSPENDED] == 0, "PUBLIC SALE: suspended" );
        require( arrInfo[INFO_SALE_START] == 0 || arrInfo[INFO_SALE_START] <= (block.timestamp+BLOCK_SEC_MARGIN), "PUBLIC SALE: not opend" );
        require( arrInfo[INFO_SALE_END] == 0 || (arrInfo[INFO_SALE_END]+BLOCK_SEC_MARGIN) > block.timestamp, "PUBLIC SALE: finished" );


        require( colorIds.length == nums.length, "PUBLIC SALE: invalid array sizes" );
        uint256 num;
        for( uint256 i=0; i<nums.length; i++ ){ num += nums[i]; }
        require( arrInfo[INFO_SALE_USER_MINTABLE] >= (arrInfo[INFO_SALE_USER_MINTED]+num), "PUBLIC SALE: reached the sale limit" );
        require( arrInfo[INFO_SALE_USER_LIMIT] >= num, "PUBLIC SALE: reached the user limit" );

        _checkPayment( msg.sender, arrInfo[INFO_SALE_PRICE]*num, msg.value );

        for( uint256 i=0; i<colorIds.length; i++ ){
            _mintTokens( msg.sender, colorIds[i], nums[i] );
        }

        _PUBLIC_map_user_minted[msg.sender] += num;
    }

    //--------------------------------------------------------
    // [internal] _getUserMinted
    //--------------------------------------------------------
    function _getUserMinted( address target ) internal view returns (uint256) {
        uint256 total;
        total += _PRIVATE_map_user_minted[target];
        total += _PARTNER_map_user_minted[target];
        total += _PUBLIC_map_user_minted[target];
        return( total );
    }

    //--------------------------------------------------------
    // [internal] _checkUserLimit
    //--------------------------------------------------------
    function _checkUserLimit( address target, uint256 num ) internal view returns (uint256) {
        uint256 total = _getUserMinted( target );

        if( total >= _token_max_per_user ){
            return( 0 );
        }

        uint256 rest = _token_max_per_user - total;
        if( num > rest ){
            return( rest );
        }
        return( num );
    }    

    //--------------------------------------------------------
    // [internal] _checkWhitelisted
    //--------------------------------------------------------
    function _checkWhitelisted( bytes32 merkleRoot, address target, uint256 amount, bytes32[] calldata merkleProof ) internal pure returns (bool) {
        bytes32 node = keccak256( abi.encodePacked( target, amount ) );
        if( MerkleProof.verify( merkleProof, merkleRoot, node ) ){
            return( true );
        }
        return( false );
    }

    //--------------------------------------------------------
    // [internal] _checkPayment
    //--------------------------------------------------------
    function _checkPayment( address msgSender, uint256 price, uint256 payment ) internal {
        require( price <= payment, "insufficient value" );

        // refund if overpaymented
        if( price < payment ){
            uint256 change = payment - price;
            address payable target = payable( msgSender );
            target.transfer( change );
        }
    }

    //--------------------------------------------------------
    // [internal] _mintTokens
    //--------------------------------------------------------
    function _mintTokens( address to, uint256 colorId, uint256 num ) internal {
        require( colorId < COLOR_NUM, "_mintTokens: invalid colorId" );
        require( _token_max >= (_total_minted+num), "_mintTokens: reached the supply range" );
        require( _token_max_per_color >= (_arr_color_minted[colorId]+num), "_mintTokens: reached the color range" );

        uint256 tokenId = _token_id_ofs + colorId*_token_max_per_color + _arr_color_minted[colorId];
        for( uint256 i=0; i<num; i++ ){
            _token.mintByMinter( to, tokenId+i );
        }

        _total_minted += num;
        _arr_color_minted[colorId] += num;
    }

    //--------------------------------------------------------
    // [external/onlyOwnerOrManager] reserveTokens
    //--------------------------------------------------------
    function reserveTokens( uint256 num ) external onlyOwnerOrManager {
        require( _token_reserved >= (_total_minted+num), "reserveTokens: exceeded the reservation range" );

        uint256 mintPerColor = _token_reserved / COLOR_NUM;
        while( num > 0 ){
            uint256 colorId = _total_minted / mintPerColor;
            uint256 colorNum = mintPerColor - (_total_minted % mintPerColor);
            if( colorNum > num ){
                colorNum = num;
            }
 
            _mintTokens( owner(), colorId, colorNum );
            num -= colorNum;
        }
    }

    //--------------------------------------------------------
    // [external] getUserInfo
    //--------------------------------------------------------
    function getUserInfo( address target, uint256 amount0, bytes32[] calldata merkleProof0, uint256 amount1, bytes32[] calldata merkleProof1 ) external view returns (uint256[USER_INFO_MAX] memory) {
        uint256[USER_INFO_MAX] memory userInfo;
        uint256[INFO_MAX] memory info;

        // PRIVATE(whitelist)
        if( (_PRIVATE_end == 0 || _PRIVATE_end > (block.timestamp+BLOCK_SEC_MARGIN/2)) && _checkWhitelisted( _PRIVATE_merkle_root, target, amount0, merkleProof0 ) ){
            userInfo[USER_INFO_SALE_TYPE] = 1;
            info = PRIVATE_getInfo( target, amount0, merkleProof0 );
        }
        // PARTNER(whitelist)
        else if( (_PARTNER_end == 0 || _PARTNER_end > (block.timestamp+BLOCK_SEC_MARGIN/2)) && _checkWhitelisted( _PARTNER_merkle_root, target, amount1, merkleProof1 ) ){
            userInfo[USER_INFO_SALE_TYPE] = 2;
            info = PARTNER_getInfo( target, amount1, merkleProof1 );
        }
        // PUBLIC
        else{
            userInfo[USER_INFO_SALE_TYPE] = 3;
            info = PUBLIC_getInfo( target );            
        }

        for( uint256 i=0; i<INFO_MAX; i++ ){
            userInfo[i] = info[i];
        }

        userInfo[USER_INFO_MINTABLE] = _token_max_per_user;
        userInfo[USER_INFO_MINTED] = _getUserMinted( target );
        userInfo[USER_INFO_TOKEN_MAX] = _token_max;
        userInfo[USER_INFO_TOTAL_MINTED] = _total_minted;
        userInfo[USER_INFO_TOKEN_MAX_PER_COLOR] = _token_max_per_color;
        for( uint256 i=0; i<COLOR_NUM; i++ ){
            userInfo[USER_INFO_COLOR_MINTED+i] = _arr_color_minted[i];
        }

        return( userInfo );
    }

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // [external] getBalance
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    function getBalance() external view returns (uint256) {
        return( address(this).balance );
    }

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // [external] getCreatorInfo
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    function getCreatorInfo() external view returns (address[] memory, uint256[] memory) {
        return( _arr_creator, _arr_creator_fee_weight );
    }

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // [external/onlyOwnerOrManager] addCreator
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    function addCreator( address creator, uint256 weight ) external onlyOwnerOrManager {
        require( creator != address(0x0), "addCreator: invalid address" );
        require( weight > 0, "addCreator: invalid weight" );

        for( uint256 i=0; i<_arr_creator.length; i++ ){
            if( _arr_creator[i] == creator ){
                _arr_creator_fee_weight[i] = weight;
                return;
            }
        }

        _arr_creator.push( creator );
        _arr_creator_fee_weight.push( weight );
    }

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // [external/onlyOwnerOrManager] deleteCreator
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    function deleteCreator( address creator ) external onlyOwnerOrManager {
        for( uint256 i=0; i<_arr_creator.length; i++ ){
            if( _arr_creator[i] == creator ){
                for( uint256 j=i+1; j<_arr_creator.length; j++ ){
                    _arr_creator[j-1] = _arr_creator[j];
                    _arr_creator_fee_weight[j-1] = _arr_creator_fee_weight[j];
                }

                _arr_creator.pop();
                _arr_creator_fee_weight.pop();
            }
        }
    }

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // [external/onlyOwnerOrManager] withdraw
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    function withdraw( uint256 amount ) external onlyOwnerOrManager{
        require( amount <= address(this).balance, "withdraw: insufficient balance" );
        require( _arr_creator.length > 0, "withdraw: no creator" );

        uint256 total;
        for( uint256 i=0; i<_arr_creator.length; i++ ){
            total += _arr_creator_fee_weight[i];
        }

        address payable target;
        for( uint256 i=1; i<_arr_creator.length; i++ ){
            uint256 temp = amount * _arr_creator_fee_weight[i] / total;
            target = payable( _arr_creator[i] );
            target.transfer( temp );
            amount -= temp;
        }

        target = payable( _arr_creator[0] );
        target.transfer( amount );
    }

}