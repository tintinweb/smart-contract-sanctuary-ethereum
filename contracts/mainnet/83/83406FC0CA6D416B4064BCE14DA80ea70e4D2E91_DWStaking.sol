// SPDX-License-Identifier: The MIT License (MIT)






//  __/\\\\\\\\\\\\_______/\\\\\\\\\______/\\\\\\\\\\\\\\\_____/\\\\\\\\\_____/\\\\____________/\\\\_        
//   _\/\\\////////\\\___/\\\///////\\\___\/\\\///////////____/\\\\\\\\\\\\\__\/\\\\\\________/\\\\\\_       
//    _\/\\\______\//\\\_\/\\\_____\/\\\___\/\\\______________/\\\/////////\\\_\/\\\//\\\____/\\\//\\\_      
//     _\/\\\_______\/\\\_\/\\\\\\\\\\\/____\/\\\\\\\\\\\_____\/\\\_______\/\\\_\/\\\\///\\\/\\\/_\/\\\_     
//      _\/\\\_______\/\\\_\/\\\//////\\\____\/\\\///////______\/\\\\\\\\\\\\\\\_\/\\\__\///\\\/___\/\\\_    
//       _\/\\\_______\/\\\_\/\\\____\//\\\___\/\\\_____________\/\\\/////////\\\_\/\\\____\///_____\/\\\_   
//        _\/\\\_______/\\\__\/\\\_____\//\\\__\/\\\_____________\/\\\_______\/\\\_\/\\\_____________\/\\\_  
//         _\/\\\\\\\\\\\\/___\/\\\______\//\\\_\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\_____________\/\\\_ 
//          _\////////////_____\///________\///__\///////////////__\///________\///__\///______________\///__
//  _____/\\\\\\\\\\\____/\\\\\\\\\\\\\\\_____/\\\\\\\\\_____/\\\________/\\\__/\\\\\\\\\\\\\\\_             
//   ___/\\\/////////\\\_\///////\\\/////____/\\\\\\\\\\\\\__\/\\\_____/\\\//__\/\\\///////////__            
//    __\//\\\______\///________\/\\\________/\\\/////////\\\_\/\\\__/\\\//_____\/\\\_____________           
//     ___\////\\\_______________\/\\\_______\/\\\_______\/\\\_\/\\\\\\//\\\_____\/\\\\\\\\\\\_____          
//      ______\////\\\____________\/\\\_______\/\\\\\\\\\\\\\\\_\/\\\//_\//\\\____\/\\\///////______         
//       _________\////\\\_________\/\\\_______\/\\\/////////\\\_\/\\\____\//\\\___\/\\\_____________        
//        __/\\\______\//\\\________\/\\\_______\/\\\_______\/\\\_\/\\\_____\//\\\__\/\\\_____________       
//         _\///\\\\\\\\\\\/_________\/\\\_______\/\\\_______\/\\\_\/\\\______\//\\\_\/\\\\\\\\\\\\\\\_      
//          ___\///////////___________\///________\///________\///__\///________\///__\///////////////__  





pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IToken {
    function mint(address to, uint256 amount) external;
}


/**
 * @title DreamWorld Staking
 * 
 * @notice The official Dream World NFT staking contract.
 * 
 * @author M. Burke
 * 
 * @custom:security-contact [email protected]
 */
contract DWStaking is Ownable, ReentrancyGuard {
    IToken immutable ZZZs;
    IERC721 immutable DWnft;
    uint256 immutable INITIAL_BLOCK;

    mapping(address => StakeCommitment[]) public commitments;

    event StakeNft(address indexed _staker, uint256 indexed _tokenId);
    event UnstakeNft(
        address indexed _staker,
        uint256 indexed _tokenId,
        uint256 _rewardTokens
    );

    /** 
     * @dev     blockStakedAdjusted will be updated as users withdraw rewards from staked nfts
     * 
     * @param   blockStakedAdjusted is the calculated value => block.number - INITIAL_BLOCK
     *           (which is set on deployment). This is allows the struct to use uint32
     *           rather than uint256.
     *
     * @param   tokenId is the token id from the Dream World NFT contract associated with the
     *           NFT to be staked.
     */
    struct StakeCommitment {
        uint32 blockStakedAdjusted;
        uint256 tokenId;
    }

    constructor(address _erc20Token, address _erc721Token) {
        ZZZs = IToken(_erc20Token);
        DWnft = IERC721(_erc721Token);
        INITIAL_BLOCK = block.number;
    }

    //------------------------------------USER FUNCS-------------------------------------------\\
    /** @dev     The use of safeTransferFrom ensures the caller either owns the NFT or has
     *           been approved.
     *
     *  @param   _tokenId is the token id from the Dream World NFT contract associated with the
     *           NFT to be staked.
     */
    function stakeNft(uint256 _tokenId) external {
        DWnft.safeTransferFrom(msg.sender, address(this), _tokenId);
    }

    /** 
     * @notice  'stakeMultipleNfts' is to be used only for staking multiple NFTs.
     *           While using it to stake one, is possible, unnecessary gas
     *           costs will occure.
     *
     * @param   _tokenIds is an array of Dream World NFT ids to be staked.
     */
    function stakeMultipleNfts(uint256[] memory _tokenIds) external {
        require(
            DWnft.isApprovedForAll(msg.sender, address(this)) == true,
            "DWStaking: Staking contract is not approved for all."
        );

        uint256 len = _tokenIds.length;

        for (uint256 i = 0; i < len; ) {
            DWnft.safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**  
     * @notice 'withdrawAvailableRewards' is to be called by user wishing to withdraw ZZZs.
     *
     * @dev    Note that 'blockStakedAdjusted' will be updated to reflect no available
     *          reward on withdraw.
     */
    function withdrawAvailableRewards() external nonReentrant {
        StakeCommitment[] memory commitmentsArr = commitments[msg.sender];
        uint256 availableRewards = _getAvailableRewards(msg.sender);
        uint256 currentAdjustedBlock = block.number - INITIAL_BLOCK;
        uint256 len = commitmentsArr.length;

        for (uint256 i = 0; i < len; ) {
            commitments[msg.sender][i].blockStakedAdjusted = uint32(
                currentAdjustedBlock
            );

            unchecked {
                ++i;
            }
        }

        _mintTo(msg.sender, availableRewards);
    }

    /** 
     * @notice  A variation of 'unstakeNft' is available below: 'unstakeNftOptions'.
     *           Calling `unstakeNft` with a single arg (_tokenId) assumes the caller is the owner
     *           and does not wish to specify an alternate beneficiary.
     *
     * @dev     Users can view an array of staked NFTs via `getStakingCommitments`.
     *
     * @param   _tokenId is the token id from the Dream World NFT contract associated with the
     *           NFT to be unstaked.
     */
    function unstakeNft(uint256 _tokenId) external nonReentrant {
        _unStakeNft(_tokenId, msg.sender, msg.sender);
    }

    /**
     * @notice  See function definition above for simple use case.
     *           Caling `unstakeNftOptions` with three args (_tokenId, _owner, _beneficiary)
     *           assumes the caller may not be the owner (an approvedForAll check will be made).
     *           It also gives the approved user or owner the opportunity to specify a beneficiary.
     *
     * @dev     User can view array of staked NFTs via `getStakingCommitments`.
     *
     * @param   _tokenId is the token id from the Dream World NFT contract associated with the
     *           NFT to be unstaked.
     *
     * @param  _owner The address of the Nft's owner at time of stkaing.
     *
     * @param  _beneficiary The address of an alternate wallet to send BOTH the ERC20 ZZZs
     *          staking rewards and the original ERC721 staked NFT.
     */
    function unstakeNftOptions(
        uint256 _tokenId,
        address _owner,
        address _beneficiary
    ) external nonReentrant {
        require(
            DWnft.isApprovedForAll(_owner, msg.sender),
            "Caller is not approved for all. See ERC721 spec."
        );
        _unStakeNft(_tokenId, _owner, _beneficiary);
    }

    /** 
     * @dev '_unStakeNft' may be called either `unstakeNft` or 'unstakeNftOptions'
     *   
     * @dev '_unStakeNft' will iterate through the array of an owners staked tokens. If 
     *       correct commitment is found, any commitsments following will be shifted down
     *       to overwrite and the last commitment will be zeroed out in O(n) time. 
     */
    function _unStakeNft(
        uint256 _tokenId,
        address _owner,
        address _beneficiary
    ) private {
        StakeCommitment[] memory existingCommitmentsArr = commitments[_owner];
        uint256 len = existingCommitmentsArr.length;
        uint256 rewardsAmount = 0;
        bool includesId = false;

        for (uint256 i = 0; i < len; ) {
            uint256 elTokenId = existingCommitmentsArr[i].tokenId;

            if (includesId == true && i < len-1) {
                commitments[_owner][i] = existingCommitmentsArr[i+1];
            }

            if (elTokenId == _tokenId) {
                includesId = true;
                rewardsAmount = _calculateRewards(existingCommitmentsArr[i].blockStakedAdjusted);

                if (i < len-1) {
                    commitments[_owner][i] = existingCommitmentsArr[i+1];
                }
            }

            unchecked {
                ++i;
            }
        }

        // Zero out last commitment
        require(includesId, "Token not found");

        delete commitments[_owner][len-1];
        _mintTo(_beneficiary, rewardsAmount);
        DWnft.safeTransferFrom(address(this), _beneficiary, _tokenId);

        emit UnstakeNft(_beneficiary, _tokenId, rewardsAmount);
    }

    //-----------------------------------------------------------------------------------------\\

    /**
     * @notice 'onERC721Received' will be called to validate the staking process
     *          (See ERC721 docs: `safeTransferFrom`).
     *
     * @dev    Business logic of staking is within 'onERC721Received'
     */
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) public returns (bytes4) {
        require(
            _operator == address(this),
            "Must transfer valid nft via stake function."
        );
        require(
            DWnft.ownerOf(_tokenId) == address(this),
            "Must transfer token from DW collection"
        );
        uint256 currentBlock = block.number;

        StakeCommitment memory newCommitment;
        newCommitment = StakeCommitment({
            blockStakedAdjusted: uint32(currentBlock - INITIAL_BLOCK),
            tokenId: _tokenId
        });

        uint256 numberOfCommits = commitments[_from].length;

        // If user previously unstaked a token, last el will have been zeroed out. 
        // This overwrites last el only in this situation.

        if (numberOfCommits == 0 || commitments[_from][numberOfCommits-1].blockStakedAdjusted != 0) {
            commitments[_from].push(newCommitment);
        } else if (commitments[_from][numberOfCommits-1].blockStakedAdjusted == 0) {
            commitments[_from][numberOfCommits-1] = newCommitment;
        }

        emit StakeNft(_from, _tokenId);

        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @notice `_getStakedIds` is used internally for fetching account data
     *          but it also made available for users.
     *
     * @dev    Returns an array of ERC721 token Ids that an
     *          account has staked.
     *
     * @param  _account is the wallet address of the user, who's data is to be fetched.
     */
    function _getStakedIds(address _account)
        public
        view
        returns (uint256[] memory)
    {
        StakeCommitment[] memory commitmentsArr = commitments[_account];
        uint256 len = commitmentsArr.length;
        uint256[] memory tokenIdArray = new uint256[](len);

        for (uint256 i = 0; i < len; ) {
            tokenIdArray[i] = commitmentsArr[i].tokenId;

            unchecked {
                ++i;
            }
        }

        return tokenIdArray;
    }

    /**
     * @notice `_getAvailableRewards` is used internally for fetching account data
     *          but it also made available for users.
     *
     * @dev    '_getAvailableRewards' will return the sum of available rewards.
     *
     * @param   _account is the wallet address of the user, who's data is to be fetched.
     */
    function _getAvailableRewards(address _account)
        public
        view
        returns (uint256)
    {
        StakeCommitment[] memory commitmentsArr = commitments[_account];
        uint256 len = commitmentsArr.length;
        uint256 rewards = 0;

        for (uint256 i = 0; i < len; ) {
            rewards += _calculateRewards(commitmentsArr[i].blockStakedAdjusted);

            unchecked {
                ++i;
            }
        }

        return rewards;
    }

    //------------------------------------UTILS------------------------------------------------\\

    /// @notice '_mintTo' is used internally for interfacing w/ the ERC20 ZZZs rewards token.
    function _mintTo(address _user, uint256 _amount) private {
        ZZZs.mint(_user, _amount);
    }

    /** 
     * @dev '_calculateRewards' is used in calculating the amount of ERC20 ZZZs rewards token
     *       to issue to the beneficiary durring the unstaking process.
     */
    function _calculateRewards(uint32 _stakedAtAdjusted)
        private
        view
        returns (uint256)
    {
        if (_stakedAtAdjusted == 0) {
            return 0;
        }

        uint256 availableBlocks = block.number - INITIAL_BLOCK;
        uint256 rewardBlocks = availableBlocks - _stakedAtAdjusted;

        // Where one token staked for one day should receive ~ 72 ZZZs
        return rewardBlocks * 10 ** 16 ;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
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