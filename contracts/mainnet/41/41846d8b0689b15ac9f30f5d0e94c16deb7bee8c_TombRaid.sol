/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: Season5.sol


pragma solidity 0.8.14;


interface IBoneheadz {
    function ownerOf(uint256 tokenId) external view returns (address);

    function totalSupply() external view returns (uint256);
}

contract TombRaid is Ownable {
    IBoneheadz public Boneheadz; 

    bool public raidActive = false;

    mapping(uint256 => uint256) public tokenTiers;
    mapping(uint256 => bool) public isLocked;

    uint256 public raidPrice = 0.05 ether;

    uint256 public constant SEASON = 5;
    uint256 public constant MAX_TIER = 3;

    // raid 1: 70% chance of success
    // raid 2: 50% chance of success
    // raid 3: 30% chance of success
    uint256[3] public CUTOFFS = [7, 5, 3];

    event Locked(uint256 indexed tokenId);
    event TierUpdated(uint256 indexed tokenId, uint256 tier);

    constructor(address boneheadz) {
        Boneheadz = IBoneheadz(boneheadz);
    }

    // OWNER FUNCTIONS

    function flipRaidStatus() external onlyOwner {
        raidActive = !raidActive;
    }

    function setRaidPrice(uint256 price) external onlyOwner {
        raidPrice = price;
    }

    function flipLockStatuses(uint256[] calldata tokenIds) public onlyOwner {
        uint256 numIds = tokenIds.length;
        for (uint256 i; i < numIds; i++) {
            isLocked[tokenIds[i]] = !isLocked[tokenIds[i]];
        }
    }

    function withdraw(address recipient) external onlyOwner {
        (bool success, ) = recipient.call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    // RAID FUNCTIONS

    function raid(uint256[] calldata tokenIds) public payable {
        require(msg.sender == tx.origin, "Caller not allowed");
        require(raidActive, "Raiding not active");

        uint256 numIds = tokenIds.length;
        require(msg.value == numIds * raidPrice, "Not enough ETH sent");

        for (uint256 i; i < numIds; i++) {
            uint256 tokenId = tokenIds[i];
            require(msg.sender == Boneheadz.ownerOf(tokenId), "Caller is not the token owner");
            require(!isLocked[tokenId], "Bonehead is locked");
            require(tokenTiers[tokenId] < MAX_TIER, "Already max tier");

            uint256 pseudoRandomNumber = _genPseudoRandomNumber(tokenId);
            uint256 currentTier = tokenTiers[tokenId];
            if (pseudoRandomNumber < CUTOFFS[currentTier]) {
                tokenTiers[tokenId]++;
                emit TierUpdated(tokenId, tokenTiers[tokenId]);
            } else {
                isLocked[tokenId] = true;
                emit Locked(tokenId);
            }
        }
    }

    // VIEW FUNCTIONS

    function numPerTier() public view returns (uint256[] memory) {
        uint256[] memory counts = new uint256[](MAX_TIER + 1);
        for (uint256 tier; tier <= MAX_TIER; tier++) {
            uint256 numAtTier = 0;
            uint256 totalSupply = Boneheadz.totalSupply();
            for (uint256 id; id < totalSupply; id++) {
                if (tokenTiers[id] == tier) {
                    numAtTier++;
                }
            }
            counts[tier] = numAtTier;
        }
        return counts;
    }

    function numLockedPerTier() public view returns (uint256[] memory) {
        uint256[] memory counts = new uint256[](MAX_TIER + 1);
        for (uint256 tier; tier <= MAX_TIER; tier++) {
            uint256 numLockedAtTier = 0;
            uint256 totalSupply = Boneheadz.totalSupply();
            for (uint256 id; id < totalSupply; id++) {
                if (tokenTiers[id] == tier && isLocked[id]) {
                    numLockedAtTier++;
                }
            }
            counts[tier] = numLockedAtTier;
        }
        return counts;
    }

    function _genPseudoRandomNumber(uint256 tokenId) private view returns (uint256) {
        uint256 pseudoRandomHash = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, tokenId)));
        return pseudoRandomHash % 10;
    }
}