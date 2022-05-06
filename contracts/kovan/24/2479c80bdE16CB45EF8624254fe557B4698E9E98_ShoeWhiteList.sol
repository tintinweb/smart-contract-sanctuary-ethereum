/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File contracts/lib/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File contracts/lib/access/Ownable.sol



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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File contracts/lib/security/Pausable.sol



pragma solidity ^0.8.0;

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
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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


// File contracts/lib/utils/introspection/IERC165.sol



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


// File contracts/lib/token/ERC721/IERC721.sol



pragma solidity ^0.8.0;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}


// File contracts/whitelist/RandomApplicable.sol



pragma solidity 0.8.8;

contract RandomApplicable {
    /**
     * @dev Get a random number from 0 to (max - 1)
     */
    function random(uint256 max, uint256 bonusNonce) external view returns (uint256) {
        uint256 newRandomNonce = block.number + bonusNonce;
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, newRandomNonce))) % max;
        return randomNumber;
    }

    /**
     * @dev Get a random number from (min) to (max - 1)
     */
    function randomBetween(uint256 min, uint256 max, uint256 bonusNonce) external view returns (uint256) {
        require(max > min, "Max must larger than min");
        uint256 newRandomNonce = block.number + bonusNonce;
        uint256 range = max - min;
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, newRandomNonce))) % range;
        return min + randomNumber;
    }
}

interface IRandomApplicable {
    /**
     * Get a random number from 0 to (max - 1)
     */
    function random(uint256 max, uint256 bonusNonce) external view returns(uint256);

    /**
     * Get a random number from (min) to (max - 1)
     */
    function randomBetween(uint256 min, uint256 max, uint256 bonusNonce) external view returns(uint256);
}


// File contracts/whitelist/IBEP20.sol



pragma solidity 0.8.8;

interface IBep20Token {
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


// File contracts/whitelist/IShoeWhiteList.sol



pragma solidity 0.8.8;

interface IShoeWhiteList {
    enum ShoeClass { CLASS_C, CLASS_D }
    enum ParticipantStatus { NOT_ALLOWED, ALLOWED, JOINED, REDEEMED }

    event JoinWhitelist(address indexed owner);
    event ClaimWhitelist(address indexed owner, ShoeClass shoeClass, uint256 tokenId);
    event UpdateVault(address indexed newVault);

    /// PARTICIPATING

    function updateWhiteList(address [] calldata whitelists_) external;

    function removeWhiteList(address [] calldata whitelists_) external;

    function join() external payable;

    function claim() external;

    /// CONDITIONAL CHECKS

    function isJoinable(address buyer) external view returns (bool);

    function isClaimable(address buyer) external view returns (bool);
}


// File contracts/whitelist/ShoeWhiteList.sol



pragma solidity 0.8.8;






contract ShoeWhiteList is IShoeWhiteList, Ownable, Pausable {
    IERC721 public nftContract;
    IRandomApplicable private _randomApplicable;

    uint256 constant MAX_JOINED = 5000;
    uint256 constant SALE_DURATION = 6 hours;
    uint256 constant CLAIM_AFTER = 1 hours;

    uint256 public nTotalJoined;
    mapping(address => ParticipantStatus) public eventWhiteLists;
    mapping(address => bool) private _authorizedAddresses;

    address public nftVault;
    mapping(ShoeClass => uint256[]) private _shoesLists;

    uint256 public boxPrice;
    uint256 public immutable tsJoin;
    uint256 public tsClaim;

    uint256 private _sequenceKey;

    modifier onlyAuthorizedAccount() {
		require(_authorizedAddresses[msg.sender] || owner() == msg.sender);
		_;
	}

    modifier isNotContract(address user) {
        require(_checkIsNotCallFromContract());
		require(_isNotContract(user));
		_;
	}

    modifier openToJoin() {
        require(block.timestamp >= tsJoin, "Whitelist::not join time yet");
        require(block.timestamp < tsJoin + SALE_DURATION, "Whitelist::closed to join");
        require(nTotalJoined < MAX_JOINED, "Whitelist::sold out");
        _;
        if (nTotalJoined == MAX_JOINED) {
            tsClaim = block.timestamp + CLAIM_AFTER;
        }
    }

    modifier openToClaim() {
        require (block.timestamp >= tsClaim, "Whitelist::not claim time yet");
        _;
    }

	constructor(address nftContract_, address randomApplicable_, uint256 boxPrice_, uint256 startTimestamp_) {
        nftContract = IERC721(nftContract_);
        _randomApplicable = IRandomApplicable(randomApplicable_);
        boxPrice = boxPrice_;
        tsJoin = startTimestamp_;
        tsClaim = tsJoin + SALE_DURATION + CLAIM_AFTER;
    }

    /// PARTICIPATING

    function updateWhiteList(address [] calldata whitelists_) external onlyAuthorizedAccount {
        for (uint i; i < whitelists_.length; i++) {
            eventWhiteLists[whitelists_[i]] = ParticipantStatus.ALLOWED;
        }
	}

    function removeWhiteList(address [] calldata whitelists_) external onlyAuthorizedAccount {
        for (uint i; i < whitelists_.length; i++) {
            eventWhiteLists[whitelists_[i]] = ParticipantStatus.NOT_ALLOWED;
        }
	}

    function join() external isNotContract(_msgSender()) openToJoin whenNotPaused payable {
        /* CONDITION */
        require (isJoinable(_msgSender()), "Whitelist::user not in whitelist");

        /* UPDATE */
        eventWhiteLists[_msgSender()] = ParticipantStatus.JOINED;
        nTotalJoined = nTotalJoined + 1;

        /* ACTION */
        require (msg.value == boxPrice, "Whitelist::transfer BNB failed");

        emit JoinWhitelist(msg.sender);
    }

    function claim() external isNotContract(_msgSender()) openToClaim whenNotPaused {
        /* CONDITION */
        require (isClaimable(_msgSender()), "Whitelist::user not joined");

        /* UPDATE */
        eventWhiteLists[_msgSender()] = ParticipantStatus.REDEEMED;
        
        /* ACTION */
        ShoeClass shoeClass = _generateShoeClass(msg.sender);
        uint256 nftId = _pickAndTransferShoe(_msgSender(), shoeClass);

        emit ClaimWhitelist(msg.sender, shoeClass, nftId);
    }

    /// ADMINISTATION

    function updateVaultAndList(address nftVault_, uint256[] calldata classCList_, uint256[] calldata classDList_) public onlyAuthorizedAccount {
        updateNftVault(nftVault_);
        updateShoeList(classCList_, classDList_);
    }

    function updateNftVault(address nftVault_) public onlyAuthorizedAccount {
        nftVault = nftVault_;
        emit UpdateVault(nftVault);
    }

    function updateShoeList(uint256[] calldata classCList_, uint256[] calldata classDList_) public onlyAuthorizedAccount {
        _shoesLists[ShoeClass.CLASS_C] = classCList_;
        _shoesLists[ShoeClass.CLASS_D] = classDList_;
    }

    function getShoeList(ShoeClass shoeClass_) external view returns (uint256[] memory) {
        return _shoesLists[shoeClass_];
    }

    function grantPermission(address account) external onlyOwner {
		require(account != address(0));
		_authorizedAddresses[account] = true;
	}

	function revokePermission(address account) external onlyOwner {
		require(account != address(0));
		_authorizedAddresses[account] = false;
	}

    function pause() external onlyAuthorizedAccount {
        _pause();
    }

    function unpause() external onlyAuthorizedAccount {
        _unpause();
    }

    function withdrawBalance() external onlyAuthorizedAccount {
        payable(msg.sender).transfer(address(this).balance);
    }

    /// CONDITIONAL CHECKS

    function isJoinable(address buyer) public view returns (bool) {
        return eventWhiteLists[buyer] == ParticipantStatus.ALLOWED; 
    }

    function isClaimable(address buyer) public view returns (bool) {
        return eventWhiteLists[buyer] == ParticipantStatus.JOINED; 
    }

    function _isNotContract(address _addr) internal view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size == 0);
    }

    function _checkIsNotCallFromContract() internal view returns (bool){
	    if (msg.sender == tx.origin){
		    return true;
	    } else{
	        return false;
	    }
	}

    /// INTERNAL FLOWS

    function _generateShoeClass(address buyer) internal returns (ShoeClass) {
        _sequenceKey = _sequenceKey + 1;
        uint256 result = _randomApplicable.randomBetween(0, 100, _sequenceKey + uint256(uint160(address(buyer))));

        if (result < 85) {
            return ShoeClass.CLASS_D;
        } else {
            return ShoeClass.CLASS_C;
        }
    }

    function _pickAndTransferShoe(address _buyer, ShoeClass _shoeClass) internal returns (uint256) {
        uint256 shoesListLength = _shoesLists[_shoeClass].length;
        require(shoesListLength > 0, "Whitelist::No NFT available.");
        uint256 shoesID = _shoesLists[_shoeClass][shoesListLength - 1];
        _shoesLists[_shoeClass].pop();

        nftContract.safeTransferFrom(nftVault, _buyer, shoesID);

        return shoesID;
    }
}