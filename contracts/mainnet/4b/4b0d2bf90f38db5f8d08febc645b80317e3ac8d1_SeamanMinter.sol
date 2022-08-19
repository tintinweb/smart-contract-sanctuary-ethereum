/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/MerkleProof.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
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
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
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
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
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
     * @dev Calldata version of {processMultiProof}
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

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


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

// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/SeamanMinter.sol


pragma solidity ^0.8.7;



interface SeamanNFT {
    function mint(address to, uint256 quantity) external;
    function numberMinted(address one) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract SeamanMinter is Ownable {

    struct InvitationRecord {
        uint256 NumMinted;    // 
        uint256 NumAssisted;  // 
        uint256 NumInvited;   // 
        uint256 NumSecondaryInvited; // 
        uint256 ProfitAmount; // 
        address InvitedBy;    // 
    }

    SeamanNFT private _seamanNFT;                      // 

    address private _beneficiary;                      // 
    uint256 private _profitAmount;                     // 

    mapping(address => InvitationRecord) private _invitation; // 

    // claimed profit
    mapping(address => uint256) private claimedProfit;

    uint256 private _ratioA = 2000;                    // 20%
    uint256 private _ratioB = 1000;                    // 10%

    uint256 private _priceA = 0.03 ether;              // public mint price
    uint256 private _priceB = 0.02 ether;              // wlmint , invitemint price

    uint256 private _maxQuantity = 10;                 // 
    uint256 private _maxNumMinted = 40;                // 

    bytes32 private _merkleTreeRoot;                   // “0” - wlmint false

    bool private _openToPublic = false;                // false - wlmint begin

    event claimed(address indexed wallet, uint256 indexed val);
    
    event mintedWithProof(
        address indexed wallet,
        uint256 indexed quantity,
        uint256 indexed price
    );

    event minted(
        address indexed wallet,
        uint256 indexed quantity,
        uint256 indexed price
    );

    event mintedWithCode(
        address indexed wallet,
        uint256 quantity,
        uint256 price,
        uint256 code,
        address indexed rewardeeA,
        uint256 rewardA,
        address indexed rewardeeB,
        uint256 rewardB
    );

    /**
     * 
     *
     * `seamanAddress` ERC721
     */
    constructor(address seamanContract) {
        _seamanNFT = SeamanNFT(seamanContract);
        _beneficiary = msg.sender;
    }

    /**
     * airdrop
     *
     * `users`      
     * `quantities` 
     */
    function airdrop(address[] calldata users, uint256[] calldata quantities) public onlyOwner {
        require(users.length > 0 && users.length == quantities.length, "Parameters error");
        for (uint256 i = 0; i < users.length; i++) {
            if (quantities[i] == 0) {
                continue;
            }
            _seamanNFT.mint(users[i], quantities[i]);
        }
    }

    /**
     * 
     *
     * `proof`    
     * `quantity` 
     */
    function mintWhitelist(bytes32[] calldata proof, uint256 quantity) public payable {
        require(_merkleTreeRoot != bytes32(0), "Whitelist sale is not live");
        require(MerkleProof.verify(proof, _merkleTreeRoot, keccak256(abi.encodePacked(msg.sender))), "Invalid proof");
        require(quantity > 0 && quantity <= _maxQuantity, "Wrong quantity");
        require(_seamanNFT.numberMinted(msg.sender) + quantity <= _maxNumMinted, "Exceeds max per address");
        require(msg.value >= _priceB * quantity, "Not enough ETH sent for selected amount");
        _profitAmount += msg.value;
        _seamanNFT.mint(msg.sender, quantity);
        emit mintedWithProof(msg.sender, quantity, _priceB);
    }

    /**
     * 
     *
     * `quantity` 
     */
    function mint(uint256 quantity) public payable {
        require(_openToPublic, "Sale is not live");
        require(quantity > 0 && quantity <= _maxQuantity, "Wrong quantity");
        require(_seamanNFT.numberMinted(msg.sender) + quantity <= _maxNumMinted, "Exceeds max per address");
        require(msg.value >= _priceA * quantity, "Not enough ETH sent for selected amount");
        _profitAmount += msg.value;
        _seamanNFT.mint(msg.sender, quantity);
        emit minted(msg.sender, quantity, _priceA);
    }

    /**
     * 
     *
     * `code`    TokenID
     * `quantity` 
     */
    function mintWithCode(uint256 code, uint256 quantity) public payable {
        address rewardeeA = _seamanNFT.ownerOf(code);
        require(rewardeeA != address(0) && rewardeeA != msg.sender, "Invalid code");
        require(_openToPublic, "Sale is not live");
        require(quantity > 0 && quantity <= _maxQuantity, "Wrong quantity");
        require(_seamanNFT.numberMinted(msg.sender) + quantity <= _maxNumMinted, "Exceeds max per address");
        uint256 total = _priceB * quantity;
        require(msg.value >= total, "Not enough ETH sent for selected amount");

        _seamanNFT.mint(msg.sender, quantity);
        _invitation[msg.sender].InvitedBy = rewardeeA;
        _invitation[msg.sender].NumMinted += quantity;
        _invitation[rewardeeA].NumAssisted += quantity;
        _invitation[rewardeeA].NumInvited += 1;

        unchecked {
            uint256 rewardA = total / 10000 * _ratioA;
            uint256 rewardB = total / 10000 * _ratioB;
            _profitAmount += (msg.value - rewardA - rewardB);
            address rewardeeB = _invitation[rewardeeA].InvitedBy;
            if (rewardeeB == address(0)) {
                _profitAmount += rewardB;
                rewardB = 0;
            } else {
                _invitation[rewardeeB].ProfitAmount += rewardB;
                _invitation[rewardeeB].NumSecondaryInvited += 1;
            }
            _invitation[rewardeeA].ProfitAmount += rewardA;
            
            emit mintedWithCode(msg.sender, quantity, _priceB, code, rewardeeA, rewardA, rewardeeB, rewardB);
        }
    }

    /**
     * 
     */
    function profitAmount() public view returns (uint256) {
        return _profitAmount;
    }

   
    function withdraw() public onlyOwner {
        require(_beneficiary != address(0), "Beneficiary is zero");
        require(_profitAmount > 0, "Profit is zero");
        uint256 profit = _profitAmount;
        _profitAmount = 0;
        payable(_beneficiary).transfer(profit);
    }


    function withdrawAll() public onlyOwner {
        require(_beneficiary != address(0), "Beneficiary is zero");
        uint256 balance = address(this).balance;
        require(balance > 0, "balance is zero");
        payable(_beneficiary).transfer(balance);
    }


    function invitationRecord(address one) public view returns (InvitationRecord memory) {
        return _invitation[one];
    }

    /**
     * 
     */
    function rewardAmount() public view returns (uint256) {
        return _invitation[msg.sender].ProfitAmount;
    }

    /**
     * 
     */
    function claimedAmount() public view returns (uint256) {
        return claimedProfit[msg.sender];
    }

    /**
     * 
     */
    function claim() public {
        uint val = _invitation[msg.sender].ProfitAmount;
        require(val > 0, "Reward is zero");
        _invitation[msg.sender].ProfitAmount = 0;
        claimedProfit[msg.sender] = claimedProfit[msg.sender] + val;
        payable(msg.sender).transfer(val);
        emit claimed(msg.sender, val);
    }

    /* -------------------- config -------------------- */

    function seaman() public view returns(address) {
        return address(_seamanNFT);
    }

    function setSeaman(address nftContract) public onlyOwner {
        _seamanNFT = SeamanNFT(nftContract);
    }

    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    function setBeneficiary(address one) public onlyOwner {
        require(one != address(0));
        _beneficiary = one;
    }

    function ratios() public view returns (uint256, uint256) {
        return (_ratioA, _ratioB);
    }

    function setRatios(uint256 ratioA, uint256 ratioB) public onlyOwner {
        require(ratioA + ratioB <= 10000);
        _ratioA = ratioA;
        _ratioB = ratioB;
    }

    function prices() public view returns (uint256, uint256) {
        return (_priceA, _priceB);
    }

    function setPrices(uint256 priceA, uint256 priceB) public onlyOwner {
        require(priceA >= priceB);
        _priceA = priceA;
        _priceB = priceB;
    }

    function mintLimits() public view returns (uint256, uint256) {
        return (_maxQuantity, _maxNumMinted);
    }

    function setMintLimits(uint256 maxQuantity, uint256 maxNumMinted) public onlyOwner {
        require(maxQuantity * maxNumMinted > 0);
        _maxQuantity = maxQuantity;
        _maxNumMinted = maxNumMinted;
    }

    function merkleTreeRoot() public view returns (bytes32) {
        return _merkleTreeRoot;
    }

    function setMerkleTreeRoot(bytes32 root) public onlyOwner {
        _merkleTreeRoot = root;
    }

    function openToPublic() public view returns (bool) {
        return _openToPublic;
    }

    function setOpenToPublic(bool bln) public onlyOwner {
        _openToPublic = bln;
    }

    /**
     * receive ETH
     */
    receive() external payable {
        payable(owner()).transfer(msg.value);
    }

}