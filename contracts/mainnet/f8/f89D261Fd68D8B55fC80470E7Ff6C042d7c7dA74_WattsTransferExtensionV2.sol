// SPDX-License-Identifier: MIT
// Developed by KG Technologies (https://kgtechnologies.io)

pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract IBreedingContract {
    /**
     * @notice function to set the merkle root for breeding.
     *
     * @param _merkleRoot. The new merkle root to set.
     */
    function setMerkleRoot(bytes32 _merkleRoot) external {}

    /**
     * @notice function to turn on/off breeding.
     *
     * @param _status. The new state of the breeding.
     */
    function setBreedingStatus(bool _status) external {}    

    /**
     * @notice function to set the maximum amount of juniors that can be bred.
     *
     * @param max. The new maximum.
     */
    function setMaxBreedableJuniors(uint256 max) external {}

    /**
     * @notice function to set the cooldown period for breeding a slotie.
     *
     * @param coolDown. The new cooldown period.
     */
    function setBreedCoolDown(uint256 coolDown) external {}

    /**
     * @notice function to set the watts price for breeding two sloties.
     *
     * @param price. The new watts price.
     */
    function setBreedPice(uint256 price) external {}

    /**
     * @dev WATTS OWNER
     */

    function WATTSOWNER_TransferOwnership(address newOwner) external {}

    function WATTSOWNER_SetSlotieNFT(address newSlotie) external {}

    function WATTSOWNER_SetLockPeriod(uint256 newLockPeriod) external {}

    function WATTSOWNER_SetIsBlackListed(address _set, bool _is) external {}

    function WATTSOWNER_seeClaimableBalanceOfUser(address user) external view returns (uint256) {}

    function WATTSOWNER_seeClaimableTotalSupply() external view returns (uint256) {}

    function transferOwnership(address newOwner) public {}
}

abstract contract IWatts is IERC20 {
    function burn(address _from, uint256 _amount) external {}
    function seeClaimableBalanceOfUser(address user) external view returns(uint256) {}
    function seeClaimableTotalSupply() external view returns(uint256) {}
    function burnClaimable(address _from, uint256 _amount) public {}
    function mintClaimable(address _to, uint256 _amount) public {}
    function transferOwnership(address newOwner) public {}
    function setSlotieNFT(address newSlotieNFT) external {}
    function setLockPeriod(uint256 newLockPeriod) external {}
    function setIsBlackListed(address _address, bool _isBlackListed) external {}
}

abstract contract ISlotie is IERC721 {
    function nextTokenId() external view returns(uint256){}
}

/**
 * @title WattsTransferExtensionV2.
 *
 * @author KG Technologies (https://kgtechnologies.io).
 *
 * @notice This Smart Contract extends on the WATTS ERC-20 token with transfer functionality.
 *
 */
contract WattsTransferExtensionV2 is Ownable {

    /** 
     * @notice The Smart Contract of Watts.
     * @dev ERC-20 Smart Contract 
     */
    IWatts public watts;

    /** 
     * @notice The Breeding Contract.
     * @dev Breeding Smart Contract 
     */
    IBreedingContract public breeding;

    /** 
     * @notice The Slotie Contract.
     * @dev Slotie Smart Contract 
     */
    ISlotie public slotie;

    mapping(address => bool) public blackListedRecipients;

    /**
     * @dev Events
     */
    
    event transferFromExtension(address indexed sender, address indexed recipient, uint256 claimableTransfered, uint256 balanceTransfered);
    event blackListRecipientEvent(address indexed recipient, bool indexed shouldBlackList);
    event ReceivedEther(address indexed sender, uint256 indexed amount);
    event WithdrawAllEvent(address indexed recipient, uint256 amount);

    constructor(
        address slotieAddress,
        address wattsAddress,
        address breedingAddress
    ) Ownable() {
        slotie = ISlotie(slotieAddress);
        watts = IWatts(wattsAddress);
        breeding = IBreedingContract(breedingAddress);

        blackListedRecipients[0x1C075F1c3083F67add5FFAb240DE1f604F978E83] = true; // Sushiswap WETH-WATTS LP Pair
    }
 
    /**
     * @dev TRANSFER
     */

    /**
     * @dev Allows users to transfer accumulated watts
     * to other addresses.
     */
    function transfer(
        uint256 amount,
        address recipient
    ) external {
        require(address(watts) != address(0), "WATTS ADDRESS NOT SET");
        require(watts.balanceOf(msg.sender) >= amount, "TRANSFER EXCEEDS BALANCE");
        require(amount > 0, "CANNOT TRANSFER 0");
        require(!blackListedRecipients[recipient], "RECIPIENT BLACKLISTED");
        
        uint256 claimableBalance = breeding.WATTSOWNER_seeClaimableBalanceOfUser(msg.sender);
        uint256 transferFromClaimable = claimableBalance >= amount ? amount : claimableBalance;
        uint256 transferFromBalance = claimableBalance >= amount ? 0 : amount - claimableBalance;

        require(watts.allowance(msg.sender, address(this)) >= transferFromBalance, "AMOUNT EXCEEDS ALLOWANCE");

        if (claimableBalance > 0) {
            watts.burnClaimable(msg.sender, transferFromClaimable);
            watts.mintClaimable(recipient, transferFromClaimable);
        }
        
        if (transferFromBalance > 0) {
            watts.transferFrom(msg.sender, recipient, transferFromBalance);
        }

        emit transferFromExtension(msg.sender, recipient, transferFromClaimable, transferFromBalance);
    }  

    /**
     * @dev SLOTIE ENUMERABLE EXTENSION
     */
    function slotieWalletOfOwner(address owner) external view returns (uint256[] memory) {
        uint256 _balance = slotie.balanceOf(owner);
        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;
        uint256 _loopThrough = slotie.nextTokenId();
        for (uint i = 1; i < _loopThrough; i++) {
            if (slotie.ownerOf(i) == address(0x0) && _tokens[_balance - 1] == 0) {
                _loopThrough++;
            }
            if (slotie.ownerOf(i) == owner) {
                _tokens[_index] = i;
                _index++;
            }
        }
        return _tokens;
    }

    /** 
     * @dev OWNER ONLY 
     */

    /**
     * @dev Method to blacklist or whitelist
     * an address from receiving WATTS
     */
    function blackListRecipient(address recipient, bool shouldBlackList) external onlyOwner {
        blackListedRecipients[recipient] = shouldBlackList;
        emit blackListRecipientEvent(recipient, shouldBlackList);
    }

    /**
     * @notice function to set the merkle root for breeding.
     *
     * @param _merkleRoot. The new merkle root to set.
     */
    function BREEDOWNER_setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        breeding.setMerkleRoot(_merkleRoot);
    }

    /**
     * @notice function to turn on/off breeding.
     *
     * @param _status. The new state of the breeding.
     */
    function BREEDOWNER_setBreedingStatus(bool _status) external onlyOwner {
        breeding.setBreedingStatus(_status);
    }    

    /**
     * @notice function to set the maximum amount of juniors that can be bred.
     *
     * @param max. The new maximum.
     */
    function BREEDOWNER_setMaxBreedableJuniors(uint256 max) external onlyOwner {
        breeding.setMaxBreedableJuniors(max);
    }

    /**
     * @notice function to set the cooldown period for breeding a slotie.
     *
     * @param coolDown. The new cooldown period.
     */
    function BREEDOWNER_setBreedCoolDown(uint256 coolDown) external onlyOwner {
        breeding.setBreedCoolDown(coolDown);
    }

    /**
     * @notice function to set the watts price for breeding two sloties.
     *
     * @param price. The new watts price.
     */
    function BREEDOWNER_setBreedPice(uint256 price) external onlyOwner {
        breeding.setBreedPice(price);
    }

    function BREEDOWNER_TransferOwnership(address newOwner) external onlyOwner {
        breeding.transferOwnership(newOwner);   
    }

    /**
     * @dev WATTS OWNER
     */


    function WATTSOWNER_TransferOwnership(address newOwner) external onlyOwner {
        breeding.WATTSOWNER_TransferOwnership(newOwner);
    }

    function WATTSOWNER_SetSlotieNFT(address newSlotie) external onlyOwner {
        breeding.WATTSOWNER_SetSlotieNFT(newSlotie);
    }

    function WATTSOWNER_SetLockPeriod(uint256 newLockPeriod) external onlyOwner {
        breeding.WATTSOWNER_SetLockPeriod(newLockPeriod);
    }

    function WATTSOWNER_SetIsBlackListed(address _set, bool _is) external onlyOwner {
        breeding.WATTSOWNER_SetIsBlackListed(_set, _is);
    }

    function WATTSOWNER_seeClaimableBalanceOfUser(address user) external view returns (uint256) {
        return breeding.WATTSOWNER_seeClaimableBalanceOfUser(user);
    }

    function WATTSOWNER_seeClaimableTotalSupply() external view returns (uint256) {
        return breeding.WATTSOWNER_seeClaimableTotalSupply();
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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