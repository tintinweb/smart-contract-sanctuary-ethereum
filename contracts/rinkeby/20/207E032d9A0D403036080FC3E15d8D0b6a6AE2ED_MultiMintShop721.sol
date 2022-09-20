// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/IComposite721.sol";

// Errors
error CannotBuyZeroItems();
error CannotExceedCap();
error CollectionNotSet();
error RefundFailed();
error UnderpaidMint();
error SweepFailed();

contract MultiMintShop721 is Ownable, ReentrancyGuard {
    /**
       @param price the price of each item in the collection
       @param cap the total number of items this shop can sell
       @param sellCount the current count of items sold from this collection
       @param collection the contract address of the collection
     */
    struct Pool {
        uint256 price;
        uint256 cap;
        uint256 sellCount;
        address collection;
    }

    /// A mapping to look up collection details for a given pool.
    mapping ( uint256 => Pool ) public pools;

    /// The current count of collections for sale
    uint256 public poolCount;

    /**
       Mint an item from a collection
       @param _amount the amount of items to mint
       @param _poolId the pool from which to mint
    */
    function mint ( 
        uint256 _amount,
        uint256 _poolId
    ) external payable nonReentrant {
        // Reject purchases for no items.
        if (_amount < 1) { revert CannotBuyZeroItems(); }

        Pool memory pool = pools[_poolId];

        // Reject empty collection
        if(pool.collection == address(0)){
            revert CollectionNotSet();
        }

        // Sold out
        if (pool.sellCount + _amount > pool.cap) {
            revert CannotExceedCap();
        }

        // Reject under paid mints
        uint256 totalCost = pool.price * _amount;
        if(msg.value < totalCost){
            revert UnderpaidMint();
        }

        // Refund over paid mints
        if (msg.value > totalCost) {
            uint256 excess = msg.value - totalCost;
            (bool returned, ) = payable(msg.sender).call{ value: excess }("");
            if (!returned) { revert RefundFailed(); }
        }

        // Update sell count
        pool.sellCount = pool.sellCount + _amount;

        // Mint items to user
        IComposite721(pool.collection).mint(msg.sender, _amount);
    }

    /**
       Set the data for multiple pools
       @param _pools the array of pool data to update
    */
    function setPools (
        Pool[] memory _pools
    ) external onlyOwner {
        for(uint i; i < _pools.length; ++i){
            if(pools[i].collection == address(0)){
                ++poolCount;
            }

            pools[i] = _pools[i];
        }
    }

    /**
       Set the data for a single pool
       @param _poolId the id of the pool to update
       @param _poolData the data to update
    */
    function setPool ( 
        uint256 _poolId,
        Pool memory _poolData
    ) external onlyOwner {
        if(pools[_poolId].collection == address(0)){
            ++poolCount;
        }
        pools[_poolId] = _poolData;

    }

    /**
        Allow the owner to sweep either Ether from the contract and send it to 
        another address. This allows the owner of the shop to withdraw their 
        funds after the sale is completed.

        @param _amount The amount of token to sweep.
        @param _destination The address to send the swept tokens to.
    */
    function sweep (
        address _destination,
        uint256 _amount
    ) external onlyOwner nonReentrant {
        (bool success, ) = payable(_destination).call{ value: _amount }("");
        if (!success) { revert SweepFailed(); }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

/**
  @title A minimalistic, gas-efficient ERC-721 implementation forked from the
    `Super721` ERC-721 implementation used by SuperFarm.
  @author Tim Clancy
  @author 0xthrpw
  @author Qazawat Zirak
  @author Rostislav Khlebnikov

  Compared to the original `Super721` implementation that this contract forked
  from, this is a very pared-down contract that includes simple delegated
  minting and transfer locks.

  This contract includes the gas efficiency techniques graciously shared with
  the world in the specific ERC-721 implementation by Chiru Labs that is being
  called "ERC-721A" (https://github.com/chiru-labs/ERC721A). We have validated
  this contract against their test cases.

  February 8th, 2022.
*/
interface IComposite721 {

  /**
    This function allows permissioned minters of this contract to mint one or
    more tokens dictated by the `_amount` parameter. Any minted tokens are sent
    to the `_recipient` address.

    Note that tokens are always minted sequentially starting at one. That is,
    the list of token IDs is always increasing and looks like [ 1, 2, 3... ].
    Also note that per our use cases the intended recipient of these minted
    items will always be externally-owned accounts and not other contracts. As a
    result there is no safety check on whether or not the mint destination can
    actually correctly handle an ERC-721 token.

    @param _recipient The recipient of the tokens being minted.
    @param _amount The amount of tokens to mint.
  */
  function mint (
    address _recipient,
    uint256 _amount
  ) external;


  function balanceOf ( address _owner ) external returns ( uint256 );

  function ownerOf ( uint256 id ) external returns ( address );

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