// SPDX-License-Identifier: MIT
// Developed by KG Technologies (https://kgtechnologies.io)

pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @notice Represents Slotie Smart Contract
 */
contract ISlotie {
    /** 
     * @dev ERC-721 INTERFACE 
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {}

    /** 
     * @dev CUSTOM INTERFACE 
     */
    function mintTo(uint256 amount, address _to) external {}
}

contract ISlotieJr {
    /** 
     * @dev ERC-721 INTERFACE 
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {}
    function totalSupply() public view returns (uint256) {}

    /** 
     * @dev CUSTOM INTERFACE 
     */
    function mintTo(uint256 amount, address _to) external {}
    function maxMintPerTransaction() public returns (uint256) {}
}

abstract contract IWatts is IERC20 {
    function burn(address _from, uint256 _amount) external {}
    function seeClaimableBalanceOfUser(address user) external view returns(uint256) {}
    function seeClaimableTotalSupply() external view returns(uint256) {}
    function burnClaimable(address _from, uint256 _amount) public {}
    function transferOwnership(address newOwner) public {}
    function setSlotieNFT(address newSlotieNFT) external {}
    function setLockPeriod(uint256 newLockPeriod) external {}
    function setIsBlackListed(address _address, bool _isBlackListed) external {}
}

/**
 * @title SlotieJrBreeding.
 *
 * @author KG Technologies (https://kgtechnologies.io).
 *
 * @notice This Smart Contract can be used to breed Slotie NFTs.
 *
 * @dev The primary mode of verifying permissioned actions is through Merkle Proofs
 * which are generated off-chain.
 */
contract SlotieJrBreeding is Ownable {

    /** 
     * @notice The Smart Contract of Slotie
     * @dev ERC-721 Smart Contract 
     */
    ISlotie public immutable slotie;

    /** 
     * @notice The Smart Contract of Slotie Jr.
     * @dev ERC-721 Smart Contract 
     */
    ISlotieJr public immutable slotiejr;

    /** 
     * @notice The Smart Contract of Watts.
     * @dev ERC-20 Smart Contract 
     */
    IWatts public immutable watts;
    
    /** 
     * @dev BREED DATA 
     */
    uint256 public maxBreedableJuniors = 5000;
    bool public isBreedingStarted = false;
    uint256 public breedPrice = 1800 ether;    
    uint256 public breedCoolDown = 2 * 30 days;
    
    mapping(uint256 => uint256) public slotieToLastBreedTimeStamp;  

    bytes32 public merkleRoot = 0x92b34b7175c93f0db8f32e6996287e5d3141e4364dcc5f03e3f3b0454d999605;

    /**
     * @dev TRACKING DATA
     */
    uint256 public bornJuniors;

    /**
     * @dev Events
     */
    event ReceivedEther(address indexed sender, uint256 indexed amount);
    event Bred(address initiator, uint256 indexed father, uint256 indexed mother, uint256 indexed slotieJr);
    event setMerkleRootEvent(bytes32 indexed root);
    event setIsBreedingStartedEvent(bool indexed started);
    event setMaxBreedableJuniorsEvent(uint256 indexed maxMintable);
    event setBreedCoolDownEvent(uint256 indexed coolDown);
    event setBreedPriceEvent(uint256 indexed price);
    event WithdrawAllEvent(address indexed recipient, uint256 amount);

    constructor(
        address slotieAddress,
        address slotieJrAddress,
        address wattsAddress
    ) Ownable() {
        slotie = ISlotie(slotieAddress);
        slotiejr = ISlotieJr(slotieJrAddress);
        watts = IWatts(wattsAddress);
    }
 
    /**
     * @dev BREEDING
     */

    function breed(
        uint256 father, 
        uint256 mother, 
        uint256 fatherStart, 
        uint256 motherStart, 
        bytes32[] calldata fatherProof, 
        bytes32[] calldata motherProof
    ) external {
        require(isBreedingStarted, "BREEDING NOT STARTED");
        require(address(slotie) != address(0), "SLOTIE NFT NOT SET");
        require(address(slotiejr) != address(0), "SLOTIE JR NFT NOT SET");
        require(address(watts) != address(0), "WATTS NOT SET");
        require(bornJuniors < maxBreedableJuniors, "MAX JUNIORS HAVE BEEN BRED");
        require(father != mother, "CANNOT BREED THE SAME SLOTIE");
        require(slotie.ownerOf(father) == msg.sender, "SENDER NOT OWNER OF FATHER");    
        require(slotie.ownerOf(mother) == msg.sender, "SENDER NOT OWNER OF MOTHER");

        uint256 fatherLastBred = slotieToLastBreedTimeStamp[father];
        uint256 motherLastBred = slotieToLastBreedTimeStamp[mother];

        /**
         * @notice Check if father can breed based based on time logic
         *
         * @dev If father hasn't bred before we check the merkle proof to see
         * if it can breed already. If it has bred already we check if it's passed the
         * cooldown period.
         */ 
        if (fatherLastBred != 0) {
            require(block.timestamp >= fatherLastBred + breedCoolDown, "FATHER IS STILL IN COOLDOWN");
        }

        /// @dev see father.
        if (motherLastBred != 0) {
            require(block.timestamp >= motherLastBred + breedCoolDown, "MOTHER IS STILL IN COOLDOWN");
        }

        if (fatherLastBred == 0 || motherLastBred == 0) {
            bytes32 leafFather = keccak256(abi.encodePacked(father, fatherStart, fatherLastBred));
            bytes32 leafMother = keccak256(abi.encodePacked(mother, motherStart, motherLastBred));

            require(MerkleProof.verify(fatherProof, merkleRoot, leafFather), "INVALID PROOF FOR FATHER");
            require(MerkleProof.verify(motherProof, merkleRoot, leafMother), "INVALID PROOF FOR MOTHER"); 

            require(block.timestamp >= fatherStart || block.timestamp >= motherStart, "SLOTIES CANNOT CANNOT BREED YET");
        }

        slotieToLastBreedTimeStamp[father] = block.timestamp;
        slotieToLastBreedTimeStamp[mother] = block.timestamp;
        bornJuniors++;

        require(watts.balanceOf(msg.sender) >= breedPrice, "SENDER DOES NOT HAVE ENOUGH WATTS");

        uint256 claimableBalance = watts.seeClaimableBalanceOfUser(msg.sender);
        uint256 burnFromClaimable = claimableBalance >= breedPrice ? breedPrice : claimableBalance;
        uint256 burnFromBalance = claimableBalance >= breedPrice ? 0 : breedPrice - claimableBalance;

        if (claimableBalance > 0) {
            watts.burnClaimable(msg.sender, burnFromClaimable);
        }
        
        if (burnFromBalance > 0) {
            watts.burn(msg.sender, burnFromBalance);
        }

        slotiejr.mintTo(1, msg.sender);
        emit Bred(msg.sender, father, mother, slotiejr.totalSupply());
    }  

    /** 
     * @dev OWNER ONLY 
     */

    /**
     * @notice function to set the merkle root for breeding.
     *
     * @param _merkleRoot. The new merkle root to set.
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
        emit setMerkleRootEvent(_merkleRoot);
    }

    /**
     * @notice function to turn on/off breeding.
     *
     * @param _status. The new state of the breeding.
     */
    function setBreedingStatus(bool _status) external onlyOwner {
        isBreedingStarted = _status;
        emit setIsBreedingStartedEvent(_status);
    }    

    /**
     * @notice function to set the maximum amount of juniors that can be bred.
     *
     * @param max. The new maximum.
     */
    function setMaxBreedableJuniors(uint256 max) external onlyOwner {
        maxBreedableJuniors = max;
        emit setMaxBreedableJuniorsEvent(max);
    }

    /**
     * @notice function to set the cooldown period for breeding a slotie.
     *
     * @param coolDown. The new cooldown period.
     */
    function setBreedCoolDown(uint256 coolDown) external onlyOwner {
        breedCoolDown = coolDown;
        emit setBreedCoolDownEvent(coolDown);
    }

    /**
     * @notice function to set the watts price for breeding two sloties.
     *
     * @param price. The new watts price.
     */
    function setBreedPice(uint256 price) external onlyOwner {
        breedPrice = price;
        emit setBreedPriceEvent(price);
    }

    /**
     * @dev WATTS OWNER
     */

    function WATTSOWNER_TransferOwnership(address newOwner) external onlyOwner {
        watts.transferOwnership(newOwner);
    }

    function WATTSOWNER_SetSlotieNFT(address newSlotie) external onlyOwner {
        watts.setSlotieNFT(newSlotie);
    }

    function WATTSOWNER_SetLockPeriod(uint256 newLockPeriod) external onlyOwner {
        watts.setLockPeriod(newLockPeriod);
    }

    function WATTSOWNER_SetIsBlackListed(address _set, bool _is) external onlyOwner {
        watts.setIsBlackListed(_set, _is);
    }

    function WATTSOWNER_seeClaimableBalanceOfUser(address user) external view onlyOwner returns (uint256) {
        return watts.seeClaimableBalanceOfUser(user);
    }

    function WATTSOWNER_seeClaimableTotalSupply() external view onlyOwner returns (uint256) {
        return watts.seeClaimableTotalSupply();
    }
    

    /**
     * @dev FINANCE
     */

    /**
     * @notice Allows owner to withdraw funds generated from sale.
     *
     * @param _to. The address to send the funds to.
     */
    function withdrawAll(address _to) external onlyOwner {
        require(_to != address(0), "CANNOT WITHDRAW TO ZERO ADDRESS");

        uint256 contractBalance = address(this).balance;

        require(contractBalance > 0, "NO ETHER TO WITHDRAW");

        payable(_to).transfer(contractBalance);

        emit WithdrawAllEvent(_to, contractBalance);
    }

    /**
     * @dev Fallback function for receiving Ether
     */
    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/cryptography/MerkleProof.sol)

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
        bytes32[] memory proof,
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
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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