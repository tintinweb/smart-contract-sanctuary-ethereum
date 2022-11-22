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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MevRewardsSenseiStake is Ownable, ReentrancyGuard {
    
    /// @notice claimable eth per eoa or smart contract for external validators
    mapping(address => uint256) public balance;

    /// @notice senseistake tokenId mapping to owner
    /// @dev used for determining if there was a transfer made in senseistake contract
    /// if it was we need to assure that the balance has not an old owner balance
    mapping(uint256 => address) public nftOwner;

    /// @notice address used for senseinode fees
    address payable public immutable senseiRewards;

    /// @notice rewards struct for updating balance variable
    struct Reward {
        address to;
        uint256 amount;
    }

    /// @notice nft owner struct for updating nft ownership
    struct NFTOwner {
        uint256 tokenId;
        address owner;
    }

    event Claimed(address indexed owner, uint256 amount);

    error BalancesMismatch(uint256 expected, uint256 provided);
    error ErrorSendingETH();
    error InvalidAddress();
    error NotEnoughBalance();
    error NothingToDistribute();

    /// @notice receive callback
    receive() external payable {}

    /// @notice senseinode fee wallet address
    /// @param _senseiRewards address to send eth to
    constructor(address _senseiRewards) {
        if (_senseiRewards == address(0)) {
            revert InvalidAddress();
        }
        senseiRewards = payable(_senseiRewards);
    }

    /// @notice for checking real claimable amount of address
    /// @param owner address to check amount claimable
    function claimableAmount(address owner) external view returns (uint256) {
        uint256 fee = balance[owner] * 10 / 100;
        uint256 amount = balance[owner] - fee;
        return amount;
    }

    /// @notice allows eoa or contract to claim mev rewards
    function claim() external nonReentrant {
        uint256 fee = balance[msg.sender] * 10 / 100;
        uint256 amount = balance[msg.sender] - fee;
        if (amount == 0) {
            revert NotEnoughBalance();
        }
        balance[msg.sender] = 0;
        bool ok = payable(msg.sender).send(amount);
        if (!ok) {
            revert ErrorSendingETH();
        }
        bool ok_fee = senseiRewards.send(fee);
        if (!ok_fee) {
            revert ErrorSendingETH();
        }
        emit Claimed(msg.sender, amount);
    }

    /// @notice allows to claim mev rewards from another eoa or contract
    /// @param _owner eoa/contract address to whom send the rewards
    function claimTo(address _owner) external nonReentrant {
        if (_owner == address(0)) {
            revert InvalidAddress();
        }
        uint256 fee = balance[_owner] * 10 / 100;
        uint256 amount = balance[_owner] - fee;
        if (amount == 0) {
            revert NotEnoughBalance();
        }
        balance[_owner] = 0;
        bool ok = payable(_owner).send(amount);
        if (!ok) {
            revert ErrorSendingETH();
        }
        bool ok_fee = senseiRewards.send(fee);
        if (!ok_fee) {
            revert ErrorSendingETH();
        }
        emit Claimed(_owner, amount);
    }

    /// @notice function called to increase balance variable
    /// @dev it is used for distributing mev rewards into all eoas or contracts
    /// @param _rewards array of structs of rewards to be added to balances for current period
    /// @param _total the total amount of eth to distribute
    function distribute(Reward[] calldata _rewards, uint256 _total) external onlyOwner {
        if (_total == 0) {
            revert NothingToDistribute();
        }
        if (address(this).balance < _total) {
            revert BalancesMismatch({ expected: address(this).balance, provided: _total });
        }
        for (uint256 i = 0; i < _rewards.length; ) {
            balance[_rewards[i].to] = _rewards[i].amount;
            unchecked {
                ++i;
            }
        }
    }

    /// @notice function for adding current ownership status of senseistake tokenId
    /// @param _nftOwner struct array containig all ownsership updates
    function setNFTOwner(NFTOwner[] calldata _nftOwner) external onlyOwner {
        for (uint256 i = 0; i < _nftOwner.length; ) {
            nftOwner[_nftOwner[i].tokenId] = _nftOwner[i].owner;
            unchecked {
                ++i;
            }
        }
    }
}