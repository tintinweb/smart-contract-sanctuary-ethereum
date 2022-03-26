/**
 *Submitted for verification at Etherscan.io on 2022-03-26
*/

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// File: contracts/NFTStaking.sol



pragma solidity ^0.8.7;





interface IERC20 {
    function mint(address to, uint256 amount) external; 
}

contract NFTStaking is Ownable {

    using Counters for Counters.Counter;

    Counters.Counter private _stakeIds;

    struct stake {
        uint256 tokenId;
        uint256 startTimestamp;
    }

    mapping(uint256 => address) public stakeOwner;
    mapping(uint256 => stake) public stakes;
    mapping(uint256 => bool) public isActive;
    mapping(address => uint256) public activeStakes;

    mapping(uint256 => uint256) public tokenTrack;

    mapping(uint256 => uint256) public rewardMultiplier;

    uint256 public rewardPerDay;
    address public nftContract;
    address public rewardContract;
    uint256 public unstakingTax;

    uint256 public minStakingDuration;
    uint256 public maxStakingDuration;
    uint256 public maxStakes;




    constructor (uint256 _rewardPerDay, address _nftContract, address _rewardContract, uint256 _minStakingDuration, uint256 _maxStakingDuration, uint256 _maxStakes, uint256 _unstakingTax) {

        rewardPerDay = _rewardPerDay;
        nftContract = _nftContract;
        rewardContract = _rewardContract;
        minStakingDuration = _minStakingDuration;
        maxStakingDuration = _maxStakingDuration;
        maxStakes = _maxStakes;
        unstakingTax = _unstakingTax;
       
        
    }

    function enterStaking(uint256 _tokenID) public returns (uint256 _stakeId) {
        _stakeIds.increment();
        uint256 stakeId = _stakeIds.current();
        stakeOwner[stakeId] = _msgSender();
        stakes[stakeId] = stake(_tokenID, block.timestamp);
        isActive[stakeId] = true;
        IERC721(nftContract).safeTransferFrom(_msgSender(), address(this), _tokenID);
        activeStakes[_msgSender()] = activeStakes[_msgSender()] + 1;

        require(activeStakes[_msgSender()] <= maxStakes, "Max Active Stakes Reached");

        tokenTrack[_tokenID] = stakeId;

        return stakeId;
    }

    function leaveStaking(uint256 _stakeId) public payable {

        require(_msgSender() == stakeOwner[_stakeId], "Invalid Stake ID");
        require(msg.value == unstakingTax, "Tax unpaid");
        require(isActive[_stakeId] == true , "Staking Inactive");

        isActive[_stakeId] = false;

        uint256 daysCount = (block.timestamp - stakes[_stakeId].startTimestamp) / 86400;

        require(daysCount >= minStakingDuration, "Staking Duration have not reached minimum");

        if(daysCount > maxStakingDuration) {
            daysCount = maxStakingDuration;
        }

        uint256 tokenId = stakes[_stakeId].tokenId;

        uint256 rewardMulti = 1;

        if(rewardMultiplier[tokenId] > 0){
            rewardMulti = rewardMultiplier[tokenId];
        }

        uint256 totalReward = daysCount * rewardMulti * rewardPerDay;
        
        activeStakes[_msgSender()] = activeStakes[_msgSender()] - 1;

        tokenTrack[tokenId] = 0;

        IERC20(rewardContract).mint(_msgSender(), totalReward);
        IERC721(nftContract).safeTransferFrom(address(this), _msgSender(), tokenId);
        payable(owner()).transfer(msg.value);
    }

    function emergencyWithdraw(uint256 _stakeId) public {
        
        require(_msgSender() == stakeOwner[_stakeId], "Invalid Stake ID");
        require(isActive[_stakeId] == true , "Staking Inactive");

        isActive[_stakeId] = false;
        uint256 tokenId = stakes[_stakeId].tokenId;
        IERC721(nftContract).safeTransferFrom(address(this), _msgSender(), tokenId);
    }
    
    function updateRewardMultiplier(uint256 _tokenId, uint256 _multiplier) public onlyOwner {
        rewardMultiplier[_tokenId] = _multiplier;
    }

     function onERC721Received(address, address, uint256, bytes memory) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function getUserStakesByIndex(address _user, uint256 _index) public view returns (uint256 stakeNumber, uint256 tokenNumber, uint256 startTimestamp, uint256 dayReward) {
        
        uint256 totalStakes = _stakeIds.current() + 1;
        for(uint256 i=0; i < totalStakes; i++ ){
            if(stakeOwner[i] == _user) {
                if(_index == 0){
                    uint256 rewardMulti = 1;
                    if(rewardMultiplier[stakes[i].tokenId] > 0){
                        rewardMulti = rewardMultiplier[stakes[i].tokenId];
                    }
                    return (i, stakes[i].tokenId, stakes[i].startTimestamp, rewardMulti * rewardPerDay);
                }
                _index = _index - 1;
            }
        }
    }

}