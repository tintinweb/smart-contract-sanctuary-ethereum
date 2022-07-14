// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error NotApprovedCollection();
error PercentageIsLessThan35();
error Address0();
error PermissionDenied();
error CannotUnstakeBeforeEnd();

/**
    @title MeetsMeta Staking contract
    @author ^M
 */
contract MMStaking_Base is Ownable, ReentrancyGuard {
    /**
    @dev struct for stakes info
     */
    struct StakeInfo {
        address player;
        address holder;
        address collection;
        uint256 tokenId;
        uint256 percentage;
        uint256 stakedDate;
        uint256 lockingPeriod;
        uint256 id;
    }

    /**
    @dev in this array we hold all of stakes information
     */
    StakeInfo[] public allStakes;
    /**
    @dev holders mapping to an array of indexes of their staked passports
     */
    mapping(address => uint256[]) private holders;
    /**
    @dev players mapping to an array of indexes of their assigned passports
     */
    mapping(address => uint256[]) private players;
    /**
    @dev list of all approved collections
    @notice its updatable
     */
    mapping(address => bool) private approvedCollections;
    // Fires when an staking happen
    event Staked(
        address indexed holder,
        address indexed player,
        address collection,
        uint256 tokenId
    );
    // withdrawing any amount of token/ETH/NFT from the contract
    event withdraw_event(address token_address);

    /**
    @dev stake function
    @param _player address
    @param _collection address
    @param _tokenId in the collection
    @param _percentage of earnings which holder will share with the player. **should be multiplied by 100 before passing**
     */

    function stake(
        address _player,
        address _collection,
        uint256 _tokenId,
        uint256 _percentage,
        uint256 _lockingPeriod
    ) public nonReentrant {
        if (!approvedCollections[_collection]) {
            revert NotApprovedCollection();
        }
        if (_percentage < 3500) {
            revert PercentageIsLessThan35();
        }
        if (_player == address(0)) {
            revert Address0();
        }

        IERC721(_collection).transferFrom(
            _msgSender(),
            address(this),
            _tokenId
        );

        allStakes.push(
            StakeInfo(
                _player,
                _msgSender(),
                _collection,
                _tokenId,
                _percentage,
                block.timestamp,
                _lockingPeriod,
                allStakes.length
            )
        );
        holders[_msgSender()].push(allStakes.length - 1);
        players[_player].push(allStakes.length - 1);

        emit Staked(_msgSender(), _player, _collection, _tokenId);
    }

    event Unstaked(
        address indexed holder,
        address indexed player,
        address indexed collection,
        uint256 tokenId
    );

    /**
    @dev unstake function
    @param _stakeId of the item. this is the index of the item in allStakes array
    */
    function unstake(uint256 _stakeId) public nonReentrant {
        if (
            _stakeId >= allStakes.length ||
            ((allStakes[_stakeId].holder != _msgSender()) &&
                _msgSender() != owner())
        ) {
            revert PermissionDenied();
        }

        StakeInfo memory _stake = allStakes[_stakeId];
        if (_stake.player == address(0)) {
            revert Address0();
        }
        if (
            (_stake.stakedDate + _stake.lockingPeriod) > block.timestamp &&
            _msgSender() != owner()
        ) {
            revert CannotUnstakeBeforeEnd();
        }

        // deleting all the info before transfering the NFT
        uint256 i = 0;
        for (i = 0; i < holders[_stake.holder].length; i++) {
            if (holders[_stake.holder][i] == _stakeId) {
                delete holders[_stake.holder][i];
                break;
            }
        }
        for (i = 0; i < players[_stake.player].length; i++) {
            if (players[_stake.player][i] == _stakeId) {
                delete players[_stake.player][i];
                break;
            }
        }
        delete allStakes[_stakeId];

        IERC721(_stake.collection).transferFrom(
            address(this),
            _stake.holder,
            _stake.tokenId
        );

        emit Unstaked(
            _stake.holder,
            _stake.player,
            _stake.collection,
            _stake.tokenId
        );
    }

    event addApproved(address _newCollecction);

    /**
    @dev adding a new collection address to the list of approved collections
    @param _newCollection address
     */
    function addApprovedCollection(address _newCollection) public onlyOwner {
        approvedCollections[_newCollection] = true;
        emit addApproved(_newCollection);
    }

    /**
    @dev getting the player info
    @param _player address
    @return an array of players assigned passports
     */
    function getPlayerInfo(address _player)
        public
        view
        returns (StakeInfo[] memory)
    {
        uint256[] memory playerIds = players[_player];
        if (playerIds.length == 0) {
            return new StakeInfo[](1);
        } else {
            StakeInfo[] memory _results = new StakeInfo[](playerIds.length);
            for (uint256 i = 0; i < playerIds.length; i++) {
                _results[i] = allStakes[playerIds[i]];
            }
            return _results;
        }
    }

    /**
    @dev getting holders info
    @param _holder address
    @return holders all staked passports info
     */
    function getHolderInfo(address _holder)
        public
        view
        returns (StakeInfo[] memory)
    {
        uint256[] memory holderIds = holders[_holder];
        if (holderIds.length == 0) {
            return new StakeInfo[](1);
        } else {
            StakeInfo[] memory _results = new StakeInfo[](holderIds.length);
            for (uint256 i = 0; i < holderIds.length; i++) {
                _results[i] = allStakes[holderIds[i]];
            }
            return _results;
        }
    }

    /**
    @dev all staked info
    @return a list of stakes info
     */
    function getAllInfo() public view returns (StakeInfo[] memory) {
        return allStakes;
    }

    /**
    @dev withdraw all the ETH holdings to the beneficiary address 
    */
    function withdraw() public onlyOwner nonReentrant {
        payable(owner()).transfer(address(this).balance);
        emit withdraw_event(address(0));
    }

    /** 
    @dev this is a withdrawal in case of any ERC20 mistake deposit
    @param contract_address is the token contract address
    @notice this function withdraw all holdings of the token to the beneficiarys' address
    */
    function withdraw_erc20(address contract_address)
        public
        onlyOwner
        nonReentrant
    {
        IERC20(contract_address).transfer(
            owner(),
            IERC20(contract_address).balanceOf(address(this))
        );
        emit withdraw_event(contract_address);
    }

    /** 
    @dev this is a withdrawal in case of any ERC721 mistake deposit
    @param contract_address is the token contract address
    @param tokenID of the ERC721 item
    @notice this function withdraw the ERC721 token to the beneficiarys' address
    */
    function withdraw_erc721(address contract_address, uint256 tokenID)
        public
        onlyOwner
        nonReentrant
    {
        // checking the NFT is not from an approved collection to prevent any incident
        if (approvedCollections[contract_address]) {
            revert PermissionDenied();
        }
        IERC721(contract_address).transferFrom(address(this), owner(), tokenID);
        emit withdraw_event(contract_address);
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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