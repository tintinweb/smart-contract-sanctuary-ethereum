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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// ERC721 Interface
interface IERC721 {
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function ownerOf(uint256 _tokenId) external view returns (address);
}

contract StakingStart is ERC721Holder, Ownable, ReentrancyGuard {

    IERC721 private immutable nft;

    uint256 public nextPoolId;
    uint256 public stakingUnlock = 60; // 60 seconds

    bool public stakingPaused = true;

    struct Pool {
        uint256 firstTokenAllowed;
        uint256 limitPool;
        uint256 costElectricity;
        uint256 lifeTime;
        string typeMachine;
        string area;
        mapping(uint256 => ItemInfo) tokensPool;
        uint256[] ownedTokensPool;
    }

    struct ItemInfo {
        address owner;
        uint256 poolId;
        uint256 timestamp;
        string addressBTC;
    }

    struct Staker {
        mapping(uint256 => ItemInfo) tokensStaker;
        uint256[] ownedTokensStaker;
    }

    /// @notice mapping of a pool to an id.
    mapping(uint256 => Pool) public poolInfos;

    /// @notice mapping of a staker to its wallet.
    mapping(address => Staker) private stakers;


    /* ********************************** */
    /*             Events                 */
    /* ********************************** */

    event Staked721(address indexed owner, uint256 itemId, uint256 poolId);    /// @notice event emitted when a user has staked a nft.
    event Unstaked721(address indexed owner, uint256 itemId, uint256 poolId);    /// @notice event emitted when a user has unstaked a nft.
    event UnlockPeriodUpdated(uint256 period);    /// @notice event emitted when the unlock period is updated.
    event PauseUpdated(bool notPaused);    /// @notice event emitted when the pause is updated.
    event PoolInformationsUpdated(uint256 poolId, uint256 firstTokenAllowed, uint256 limitPool, uint256 costElectricity, string area); /// @notice event emitted when the informations in a pool has been updated.
    event PoolCreated(uint256 nextPoolId, uint256 firstTokenAllowed, uint256 limitPool, uint256 costElectricity, uint256 lifeTime, string typeMachine, string area); /// @notice event emitted when a pool has been created.

    /* ********************************** */
    /*             Constructor            */
    /* ********************************** */

    /*
    * @notice Constructor of the contract Staking.
    * @param IERC721 _nft : Address of the mint contract.
    */
    constructor(IERC721 _nft) {
        nft = _nft;
        nextPoolId++;
        poolInfos[nextPoolId].firstTokenAllowed = 1;
        poolInfos[nextPoolId].limitPool = 200;
        poolInfos[nextPoolId].costElectricity = 50;
        poolInfos[nextPoolId].lifeTime = 1722079628;
        poolInfos[nextPoolId].typeMachine = "Infra";
        poolInfos[nextPoolId].area = "Bordeaux";
    }

    /* ********************************** */
    /*             Modifier               */
    /* ********************************** */

    /*
    * @notice Safety checks common to each stake function.
    * @param uint256 _poolId : Id of the pool where to stake.
    * @param string calldata _addressBTC : BTC address that will receive the rewards.
    */
    modifier stakeModifier(uint256 _poolId, string calldata _addressBTC) {
        require(!stakingPaused, "Staking unavailable for the moment");
        require(_poolId > 0 && _poolId <= nextPoolId, "Pool doesn't exist");

        require(
            poolInfos[_poolId].ownedTokensPool.length <
            poolInfos[_poolId].limitPool,
            "Pool limit exceeded"
        );
        _;
    }

    /* ********************************** */
    /*              Pools                 */
    /* ********************************** */

    /*
    * @notice Allows to create a new pool.
    * @param uint256 _firstTokenAllowed : First NFT accepted, only ids greater than or equal to this value will be accepted.
    * @param uint256 _limitPool : Maximum amount of NFT stakable in the pool.
    * @param uint256 _costElectricity : The average cost of electricity.
    * @param uint256 _lifeTime : The life time of the machine.
    * @param string calldata _typeMachine : The type of machine.
    * @param string calldata _area : The area where the machine is located.
    */
    function createPool(uint256 _firstTokenAllowed, uint256 _limitPool, uint256 _costElectricity, uint256 _lifeTime, string calldata _typeMachine, string calldata _area) external onlyOwner {
        nextPoolId++;
        poolInfos[nextPoolId].firstTokenAllowed = _firstTokenAllowed;
        poolInfos[nextPoolId].limitPool = _limitPool;
        poolInfos[nextPoolId].costElectricity = _costElectricity;
        poolInfos[nextPoolId].lifeTime = _lifeTime;
        poolInfos[nextPoolId].typeMachine = _typeMachine;
        poolInfos[nextPoolId].area = _area;
        emit PoolCreated(nextPoolId, _firstTokenAllowed, _limitPool, _costElectricity, _lifeTime, _typeMachine, _area);
    }

    /*
    * @notice Change the one pool information's.
    * @param uint256 _poolId : Id of the pool.
    * @param uint256 _firstTokenAllowed : First NFT accepted, only ids greater than or equal to this value will be accepted.
    * @param uint256 _limitPool : Maximum amount of NFT stakable in the pool.
    * @param uint256 _costElectricity : The average cost of electricity.
    * @param string calldata _area : The area where the machine is located.
    */
    function setPoolInformation(uint256 _poolId, uint256 _firstTokenAllowed, uint256 _limitPool, uint256 _costElectricity, string calldata _area) external onlyOwner {
        require(_poolId > 0 && _poolId <= nextPoolId, "Pool doesn't exist");
        poolInfos[_poolId].firstTokenAllowed = _firstTokenAllowed;
        poolInfos[_poolId].limitPool = _limitPool;
        poolInfos[_poolId].costElectricity = _costElectricity;
        poolInfos[_poolId].area = _area;
        emit PoolInformationsUpdated(_poolId, _firstTokenAllowed, _limitPool, _costElectricity, _area);
    }

    /* ********************************** */
    /*              Staking               */
    /* ********************************** */

    /*
    * @notice Private function used in stakeERC721.
    * @param uint256 _poolId : Id of the pool where to stake.
    * @param uint256 _tokenId : Id of the token to stake.
    * @param string calldata : _addressBTC BTC address that will receive the rewards.
    */
    function _stakeERC721(uint256 _poolId, uint256 _tokenId, string calldata _addressBTC) private {
        require(_tokenId >= poolInfos[_poolId].firstTokenAllowed, "NFT can't be staked in this pool");
        require(nft.ownerOf(_tokenId) == msg.sender, "Not owner");
        nft.safeTransferFrom(msg.sender, address(this), _tokenId);
        Staker storage staker = stakers[msg.sender];
        Pool storage pool = poolInfos[_poolId];
        ItemInfo memory info = ItemInfo(
            msg.sender,
            _poolId,
            block.timestamp,
            _addressBTC
        );
        staker.tokensStaker[_tokenId] = info;
        staker.ownedTokensStaker.push(_tokenId);
        pool.tokensPool[_tokenId] = info;
        pool.ownedTokensPool.push(_tokenId);
        emit Staked721(msg.sender, _tokenId, _poolId);
    }

    /*
    * @notice Allows to stake an NFT in the desired quantity.
    * @param uint256 _poolId : Id of the pool where to stake.
    * @param uint256 _tokenId : Id of the token to stake.
    * @param string calldata _addressBTC : BTC address that will receive the rewards.
    */
    function stakeERC721(uint256 _poolId, uint256 _tokenId, string calldata _addressBTC) external nonReentrant stakeModifier(_poolId, _addressBTC) {
        _stakeERC721(_poolId, _tokenId, _addressBTC);
    }

    /*
    * @notice Allows to stake several NFT in the desired quantity.
    * @param uint256 _poolId : Id of the pool where to stake.
    * @param uint256[] _tokenIds : List of IDs of the tokens to stake.
    * @param string calldata _addressBTC : BTC address that will receive the rewards.
    */
    function batchStakeERC721(uint256 _poolId, uint256[] calldata _tokenIds, string calldata _addressBTC) external nonReentrant stakeModifier(_poolId, _addressBTC) {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _stakeERC721(_poolId, _tokenIds[i], _addressBTC);
        }
    }

    /*
    * @notice Changes the minimum period before it's possible to unstake.
    * @param uint256 _period : New minimum period before being able to unstake.
    */
    function setUnlockPeriod(uint256 _period) external onlyOwner {
        stakingUnlock = _period;
        emit UnlockPeriodUpdated(stakingUnlock);
    }

    /* ********************************** */
    /*              Unstaking             */
    /* ********************************** */

    /*
    * @notice Private function used in unstakeERC721.
    * @param uint256 _tokenId : Id of the token to unstake.
    */
    function _unstakeERC721(uint256 _tokenId) private {
        require(stakers[msg.sender].tokensStaker[_tokenId].timestamp != 0, "No NFT staked");
        uint256 elapsedTime = block.timestamp - stakers[msg.sender].tokensStaker[_tokenId].timestamp;
        require(stakingUnlock < elapsedTime, "Unable to unstake before the minimum period");
        Staker storage staker = stakers[msg.sender];
        uint256 poolId = staker.tokensStaker[_tokenId].poolId;
        Pool storage pool = poolInfos[poolId];

        delete staker.tokensStaker[_tokenId];
        delete pool.tokensPool[_tokenId];

        for (uint256 i = 0; i < staker.ownedTokensStaker.length; i++) {
            if (staker.ownedTokensStaker[i] == _tokenId) {
                staker.ownedTokensStaker[i] = staker.ownedTokensStaker[
                staker.ownedTokensStaker.length - 1
                ];
                staker.ownedTokensStaker.pop();
                break;
            }
        }

        for (uint256 i = 0; i < pool.ownedTokensPool.length; i++) {
            if (pool.ownedTokensPool[i] == _tokenId) {
                pool.ownedTokensPool[i] = pool.ownedTokensPool[
                pool.ownedTokensPool.length - 1
                ];
                pool.ownedTokensPool.pop();
                break;
            }
        }

        nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        emit Unstaked721(msg.sender, _tokenId, poolId);
    }


    /*
    * @notice Allows you to unstake an NFT staked.
    * @param uint256 _tokenId : Id of the token to unstake.
    */
    function unstakeERC721(uint256 _tokenId) external nonReentrant {
        _unstakeERC721(_tokenId);
    }

    /*
    * @notice Allows you to unstake several NFT staked.
    * @param uint256[] _tokenIds : Ids of the token to unstake.
    */
    function batchUnstakeERC721(uint256[] calldata _tokenIds) external nonReentrant {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _unstakeERC721(_tokenIds[i]);
        }
    }

    /* ********************************** */
    /*              Getters               */
    /* ********************************** */


    /*
    * @notice Returns the ItemInfo of a specific NFT staked by a user.
    * @param address _user : Address of the user.
    * @param uint256 : _tokenId Id of the token.
    * @return ItemInfo memory : Details of tokenId.
    */
    function getStakedERC721(address _user, uint256 _tokenId) external view returns (ItemInfo memory) {
        return stakers[_user].tokensStaker[_tokenId];
    }

    /*
    * @notice Returns the list of NFT staked by a user.
    * @param address _user : Address of the user.
    * @return uint256[] : List of tokenIds.
    */
    function getAllStakedERC721(address _user) external view returns (uint256[] memory) {
        return stakers[_user].ownedTokensStaker;
    }

    /*
    * @notice Returns the ItemInfo of a specific NFT staked in a pool.
    * @param uint256 _poolId : Id of the pool.
    * @param uint256 _tokenId : Id of the token.
    * @return ItemInfo : Details of tokenId.
    */
    function getStakedERC721Pool(uint256 _poolId, uint256 _tokenId)
    external
    view
    returns (ItemInfo memory)
    {
        return poolInfos[_poolId].tokensPool[_tokenId];
    }


    /*
    * @notice Returns the list of NFT staked in a pool.
    * @param uint256 _poolId : Id of the pool.
    * @return uint256[] : List of tokenIds.
    */
    function getAllStakedERC721Pool(uint256 _poolId) external view returns (uint256[] memory) {
        return poolInfos[_poolId].ownedTokensPool;
    }

    /* ********************************** */
    /*               Pauser               */
    /* ********************************** */

    /*
    * @notice Changes the variable notPaused to allow or not the staking.
    */
    function toggleStakingPaused() external onlyOwner {
        stakingPaused = !stakingPaused;
        emit PauseUpdated(stakingPaused);
    }

}