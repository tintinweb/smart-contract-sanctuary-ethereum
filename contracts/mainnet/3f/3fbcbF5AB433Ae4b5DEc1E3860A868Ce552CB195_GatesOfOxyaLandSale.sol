/**
 *Submitted for verification at Etherscan.io on 2022-10-09
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: contracts/sale.sol



pragma solidity ^0.8.14;





interface ITestNFT {
    function totalSupply() external view returns (uint);
    function MAX_SUPPLY() external returns (uint);
    function startingIndex() external returns (uint);
    function mintBySaleContract(address _addressBuyer, uint _quantity) external;
    function stakeNFT(uint tokenId) external;
    function unstakeNFT(uint[] memory tokenId, address _to) external;
    function ownerOf(uint tokenId) external view returns (address owner);
}

interface ILotteryContractInterface {
  function requestRandomWords() external;
  function returnLotteryRandomNumber() external view returns(uint);
  function returnStartIndexRandomNumber(uint _SaleSupply) external view returns(uint);
}

contract GatesOfOxyaLandSale is Ownable, ReentrancyGuard {

    event SaleStarted(uint _session);
    event RoundTimeUpdated(uint _time);
    event RandomResult(uint _number);
    event IsWinner(bool _winner);
    event StartIndex(uint startIndex);

    // Merklee Tree root
    bytes32 public root;
    bytes32 public freeMintRoot;

    // Is the sales initialized?
    bool public initialized;

    // Timestamp when a new round start
    uint public startTime;

    // Number of the round & Duration of rounds
    uint public dutchRoundNumber;
    mapping(uint => uint) dutchDurationPerRound; // Time rleft until next round

    // Potential winning percentage per address
    mapping(address => mapping(uint => uint)) public chanceToWinPerAddress;

    // Potential winning percentage per address whitelisted
    mapping(address => mapping(uint => uint)) public chanceToWinPerAddressWhitelist;

    // Mapping to follow the freemint used
    mapping(uint => mapping(address => uint)) public freeMintsUsed;

    // Mapping to follow the number of token by wallet
     mapping(uint => mapping(address => uint)) public tokenPerWallet;

     // Starting index of the metadata attribution
    uint public startingIndex;

    // Dutch auction mecanisms
    uint public constant DUTCH_PRICE_START = 0.6 ether;
    uint public constant DUTCH_PRICE_END = 0.2 ether;
    uint public constant FIRST_DUTCH_DROPPING_STEP = 0.1 ether;
    uint public constant DUTCH_DROPPING_STEP = 0.05 ether;
    uint public constant DUTCH_ROUND_DURATION = 15*60 seconds;
    uint public constant DUTCH_ROUND_MAX_DURATION = 15*60 seconds;
    uint public constant DUTCH_AUCTION_MAX_DURATION = 1440*60 seconds;
    uint public constant DUTCH_AUCTION_MAX_ROUND = 7; // Round start to 0, there is 8
    uint public session;

    // Address of the NFT contract
    address public oxyalandsNFTAddress;

    // Address of the Lottery Contract
    address public lotteryAddress;

    // Sales status
    bool public isActive;
    bool public isFreeMintActive;

    // Lottery status
    bool public isLotteryActive;

    // Max supply for current sale
    uint public maxSupplySale = 3244;
    uint public countMintedBySale;
    uint public maxSupplyFreeMint = 1400;
    uint public countMintedByFreeMint;

    uint64 public REWARD=3 ether;

    uint8[6] public PUBLIC_PERCENTAGE = [50,25,13,7,3,2];
    uint8[6] public WHITELIST_PERCENTAGE = [100,50,25,13,7,3];

    constructor(address _lotteryAddress, address _oxyalandsNFTAddress) {
        lotteryAddress = _lotteryAddress;
        oxyalandsNFTAddress = _oxyalandsNFTAddress;
    }

    modifier isInitialized {
        require(initialized, "Sale has not started");
        _;
    }

    modifier isPublicSaleActive {
        require(isActive == true, "Sale has not started");
        _;
    }

    function setMerkleRoot(bytes32 _root) public onlyOwner {
        root = _root;
    }

    function setFreeMintMerkleRoot(bytes32 _root) public onlyOwner {
        freeMintRoot = _root;
    }

    function setIsActive() external onlyOwner {
        isActive = !isActive;
    }

    function setIsFreeMintActive() external onlyOwner {
        isFreeMintActive = !isFreeMintActive;
    }

    function setIsLotteryActive() external onlyOwner {
        isLotteryActive = !isLotteryActive;
    }

    /*
     * Sale supply
     * function to change SaleSupply
     */
    function setSaleSupply(uint _newSaleSupply) external onlyOwner {
        require(_newSaleSupply > countMintedBySale, "supply minimum reached");
        require(_newSaleSupply <= ITestNFT(oxyalandsNFTAddress).MAX_SUPPLY() - ITestNFT(oxyalandsNFTAddress).totalSupply(), "Max supply reached");
        maxSupplySale = _newSaleSupply;
    }

    /*
     * FreeMint supply
     * function to change FreeMintSupply
     */
    function setFreeMintSupply(uint _newFreeMintSupply) external onlyOwner {
        require(_newFreeMintSupply > countMintedByFreeMint, "supply minimum reached");
        require(_newFreeMintSupply <= ITestNFT(oxyalandsNFTAddress).MAX_SUPPLY() - ITestNFT(oxyalandsNFTAddress).totalSupply(), "Max supply reached");
        maxSupplyFreeMint = _newFreeMintSupply;
    }

    /*
     * Time mecanism
     * Time remaining in seconds for the active round
     */
    function getRoundRemainingTime() public view returns(uint) {
        uint activeRound = getRound();
        if(activeRound == DUTCH_AUCTION_MAX_ROUND){
            return block.timestamp;
        }
        return getRoundEndingUTC() - block.timestamp;
    }

    /*
     *  Returns active round ending time in utc seconds.
     *  This will be used front end to display new round before blockhain knows it,
     *  when we are between two blockchain blocks
     */
    function getRoundEndingUTC() public view returns(uint) {
        uint activeRound = getRound();
        uint sum = startTime + dutchDurationPerRound[dutchRoundNumber];

        for (uint i=dutchRoundNumber + 1; i < activeRound + 1; i++) {
             sum+= DUTCH_ROUND_DURATION;
        }
        return sum;
    }

    /*
     * Round mecanism
     */
    function getRound() public view returns(uint) {
        if((startTime + dutchDurationPerRound[dutchRoundNumber]) > block.timestamp) { 
            return dutchRoundNumber;
        }
        else {
            uint round = dutchRoundNumber + (block.timestamp - (startTime + dutchDurationPerRound[dutchRoundNumber])) / DUTCH_ROUND_DURATION + 1;
            if(round < DUTCH_AUCTION_MAX_ROUND){
                return round;
            } else {
                return DUTCH_AUCTION_MAX_ROUND;
            }
        }
       }

    /*
     * Price mecanisms
     */
    function getPrice() public view returns(uint) {
        if(block.timestamp < startTime){
          return DUTCH_PRICE_START;
       }
        uint currentRound = getRound();
        if(block.timestamp - startTime >= DUTCH_AUCTION_MAX_DURATION || currentRound >= DUTCH_AUCTION_MAX_ROUND  ) {
         return DUTCH_PRICE_END;
        }
        else if(currentRound == 0 || currentRound == 1 ){
            return DUTCH_PRICE_START - ( currentRound * FIRST_DUTCH_DROPPING_STEP);
        }
        else {
         return DUTCH_PRICE_START - FIRST_DUTCH_DROPPING_STEP - ((currentRound - 1) * DUTCH_DROPPING_STEP);
        }
     }
     
    /*
     * Initialize the sale
     */
    function initialize() external onlyOwner {
        initialized = true;
        dutchRoundNumber = 0;
        dutchDurationPerRound[0] = DUTCH_ROUND_DURATION;
        for (uint i = 1; i < DUTCH_AUCTION_MAX_ROUND + 1; i++) {
            dutchDurationPerRound[i] = 0;
        }
        startTime = block.timestamp;
        session += 1;
        emit SaleStarted(session);
    }

    /*
     * Function to mint freeMints
     */
    function freeMint(uint _quantity, uint count, bytes32[] calldata proof) external isInitialized  nonReentrant {
        require(!isActive == true, "Sale is still running");
        require(isFreeMintActive == true, "Free mint is not started");
        require(
                MerkleProof.verify(
                    proof,
                    freeMintRoot,
                    keccak256(abi.encode(msg.sender, count))
                ),
                "!proof"
            );
        require(countMintedByFreeMint + _quantity <= maxSupplyFreeMint , 'Max supply freemint reached');
        require(freeMintsUsed[session][msg.sender] + _quantity <= count, 'Not allowed to freemint this quantity');
        countMintedByFreeMint += _quantity;
        freeMintsUsed[session][msg.sender]+= _quantity;
        ITestNFT(oxyalandsNFTAddress).mintBySaleContract(msg.sender, _quantity);  
    }
    
    /*
     * Mint function
     * Basic mint function for the dutch auction
     */
    function mint(uint _quantity, address _to, uint maxTokenPerWallet) private isInitialized isPublicSaleActive   {
        uint price = getPrice();
        require(msg.value >= price * _quantity, "Not enough ETH");
        require(countMintedBySale + _quantity <= maxSupplySale, "Max supply for this sale reached");
        require(tokenPerWallet[session][_to] + _quantity <= maxTokenPerWallet, "Max tokens per wallet reached");
        tokenPerWallet[session][_to] += _quantity;
        countMintedBySale += _quantity;
        uint roundRemainingTime = getRoundRemainingTime();
        uint currentRound = getRound();

        if((startTime + dutchDurationPerRound[dutchRoundNumber]) > block.timestamp && dutchDurationPerRound[dutchRoundNumber] < DUTCH_ROUND_MAX_DURATION && currentRound != DUTCH_AUCTION_MAX_ROUND) {
            if (roundRemainingTime >= 60) {
                dutchDurationPerRound[dutchRoundNumber] += 20 seconds;
                emit RoundTimeUpdated(getRoundEndingUTC());
            }
        }
        if(currentRound > dutchRoundNumber && dutchRoundNumber < DUTCH_AUCTION_MAX_ROUND && currentRound != DUTCH_AUCTION_MAX_ROUND) {
            startTime = block.timestamp - (DUTCH_ROUND_DURATION - roundRemainingTime);
            dutchRoundNumber = currentRound;
            
            if (roundRemainingTime >= 60) {
                dutchDurationPerRound[dutchRoundNumber] = DUTCH_ROUND_DURATION + 20 seconds;
            } else {
                dutchDurationPerRound[dutchRoundNumber] = DUTCH_ROUND_DURATION;
            }
            emit RoundTimeUpdated(getRoundEndingUTC());
        }

         if(currentRound == DUTCH_AUCTION_MAX_ROUND){
            dutchRoundNumber = DUTCH_AUCTION_MAX_ROUND;
        }
        emit RoundTimeUpdated(getRoundEndingUTC());

        ITestNFT(oxyalandsNFTAddress).mintBySaleContract(_to, _quantity);
    }

    /*
     * Public Mint function
     * function without automatic staking 
     */
    function publicMint(uint _quantity, address _to) public payable nonReentrant {
        mint(_quantity, _to, 4);
    }

    /*
     * Public Mint Staking function
     * function with automatic staking 
     */
    function publicMintStake(uint _quantity) external payable nonReentrant {
        uint totalSupply=ITestNFT(oxyalandsNFTAddress).totalSupply();
        mint(_quantity, msg.sender, 4);
        
        if(dutchRoundNumber < 6){
            chanceToWinPerAddress[msg.sender][dutchRoundNumber] += _quantity;
        }

        for(uint i=0; i < _quantity; i++){
        stake(totalSupply + i, msg.sender);
    }         
    }

    /*
     * Whitelist Mint Staking function
     * function without automatic staking 
     */
    function whitelistMint(uint _quantity, bytes32[] memory proof, address _to, uint maxPerWallet) public payable nonReentrant  {
        require(MerkleProof.verify(proof, root, keccak256(abi.encode(_to, maxPerWallet))), "You're not in the whitelist");
        mint(_quantity, _to, maxPerWallet);
    }

    /*
     * Whitelist Mint Staking function
     * function with automatic staking 
     */
    function whitelistMintStake(uint _quantity, bytes32[] memory proof, uint maxPerWallet) external payable nonReentrant  {
        require(MerkleProof.verify(proof, root, keccak256(abi.encode(msg.sender, maxPerWallet))), "You're not in the whitelist");
        uint totalSupply=ITestNFT(oxyalandsNFTAddress).totalSupply();
        mint(_quantity, msg.sender, maxPerWallet);

        if(dutchRoundNumber < 6)
            chanceToWinPerAddressWhitelist[msg.sender][dutchRoundNumber] += _quantity;
  
        for(uint i=0; i < _quantity; i++){
            stake(totalSupply + i, msg.sender);
        }   
    }

    /*
     * Lottery function
     * function that sends rewards if the lottery ticket is a winner based on Chainlink VRF
     */
    function lottery() external isInitialized nonReentrant {
        require(!isActive, "Sale isn't over");
        require(isLotteryActive, "Lottery is not active");
        require(tx.origin == msg.sender, "Cannot be called by contract account");

        if(chanceToWinPerAddress[msg.sender][0] + chanceToWinPerAddress[msg.sender][1] + chanceToWinPerAddress[msg.sender][2] + chanceToWinPerAddress[msg.sender][3] + chanceToWinPerAddress[msg.sender][4] + chanceToWinPerAddress[msg.sender][5] > 0) {
            ILotteryContractInterface(lotteryAddress).requestRandomWords();
            uint randomNumber = ILotteryContractInterface(lotteryAddress).returnLotteryRandomNumber();
            for(uint i = 0; i < 6; i++) {
                uint count = chanceToWinPerAddress[msg.sender][i];
                if(count != 0){
                    for(uint j = 0; j < count ; j++) {
                        //should call VRF
                        uint randomNumberFinal = uint(keccak256(abi.encodePacked(randomNumber,i, j))) % 1000;
                        emit RandomResult(randomNumberFinal);
                        bool hasWin =  randomNumberFinal < PUBLIC_PERCENTAGE[i];
                        chanceToWinPerAddress[msg.sender][i]-=1;

                        emit IsWinner(hasWin);
                    
                        if(hasWin==true){
                            //send Rewards
                            (bool success, ) = payable(msg.sender).call{value: REWARD}(
                                ""
                            );
                            require(success, "!transfer");
                        }
                    } 
                 }     
            }
        }
        if(chanceToWinPerAddressWhitelist[msg.sender][0] + chanceToWinPerAddressWhitelist[msg.sender][1] + chanceToWinPerAddressWhitelist[msg.sender][2] + chanceToWinPerAddressWhitelist[msg.sender][3] + chanceToWinPerAddressWhitelist[msg.sender][4] + chanceToWinPerAddressWhitelist[msg.sender][5] > 0) {
            ILotteryContractInterface(lotteryAddress).requestRandomWords();
            uint randomNumber = ILotteryContractInterface(lotteryAddress).returnLotteryRandomNumber();
            for(uint i = 0; i < 6; i++) {
                uint count = chanceToWinPerAddressWhitelist[msg.sender][i];
                 if(count != 0){
                    for(uint j = 0; j < count ; j++) {
                        //should call VRF
                        uint randomNumberFinal = uint(keccak256(abi.encodePacked(randomNumber,i, j))) % 1000;
                        emit RandomResult(randomNumberFinal);
                        bool hasWin =  randomNumberFinal < WHITELIST_PERCENTAGE[i];
                        chanceToWinPerAddressWhitelist[msg.sender][i] -= 1;

                        emit IsWinner(hasWin);
                    
                        if(hasWin==true){
                            //send Rewards
                            (bool success, ) = payable(msg.sender).call{value: REWARD}(
                                ""
                            );
                            require(success, "!transfer");
                        }
                    }
                }
            }
        }
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "!transfer");
    }
    
    /*
     * Staking function
     * private function that stakes NFT
     */
    function stake(uint _tokenId, address _to) private {
        require(ITestNFT(oxyalandsNFTAddress).ownerOf(_tokenId) == _to, "not your nft");
        ITestNFT(oxyalandsNFTAddress).stakeNFT(_tokenId);
    }

    /*
     * Unstaking function
     * function that unstakes NFT and delete any chances for the lottery
     */
    function unstake(uint[] memory _tokenId) external {
        address to = msg.sender;
        ITestNFT(oxyalandsNFTAddress).unstakeNFT(_tokenId, to);
        
         for(uint i = 0; i < 6; i++) {
                uint count = chanceToWinPerAddressWhitelist[to][i];

                if(count != 0){
                    chanceToWinPerAddressWhitelist[to][i] -= count;
                    return;
                }
         }
           for(uint i = 0; i < 6; i++) {
                uint count = chanceToWinPerAddress[to][i];

                if(count != 0){
                    chanceToWinPerAddress[to][i] -= count;
                    return;
                }
         }
    }

    /*
     * Starting index function
     * function that gets random starting index for metadata attribution
     */
    function getStartingIndex() external isInitialized onlyOwner {
        require(!isActive, "Sale isn't over");
        ILotteryContractInterface(lotteryAddress).requestRandomWords();
        uint randomNumber = ILotteryContractInterface(lotteryAddress).returnStartIndexRandomNumber(countMintedBySale + countMintedByFreeMint);
        startingIndex = randomNumber;
        emit StartIndex(randomNumber);
    }
}