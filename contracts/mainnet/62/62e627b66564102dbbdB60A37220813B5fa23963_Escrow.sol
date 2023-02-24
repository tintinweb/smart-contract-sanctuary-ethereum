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

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Custom Offer Escrow Contract V2
 * @author Noman Aziz
 */
contract Escrow is ReentrancyGuard, Ownable {
    // State Variables
    address public escAcc;
    uint256 public escFee;
    uint256 public totalOffers = 0;
    uint256 public totalDelivered = 0;
    uint256 public totalWithdrawed = 0;
    address public constant IDEA_TOKEN_ADDRESS =
        0x5d3a4F62124498092Ce665f865E0b38fF6F5FbEa;

    mapping(uint256 => OfferStruct) private offers;
    mapping(address => OfferStruct[]) private offersOf;
    mapping(uint256 => address) public creatorOf;

    mapping(address => bool) public acceptedTokens;

    enum Status {
        PENDING,
        DELIVERED,
        DISPUTED,
        REFUNDED,
        WITHDRAWED
    }

    struct OfferStruct {
        uint256 offerId;
        string serviceType;
        uint256 amount;
        address paymentToken;
        uint256 timestamp;
        address creator;
        address acceptor;
        Status status;
    }

    event Action(
        uint256 offerId,
        string actionType,
        Status status,
        address indexed executor
    );

    /**
     * Constructor
     * By Default, IDEA token is supported
     * @param _escFee is the escrow fee cut percentage
     * @param _tokenAddresses addresses of supported ERC20 tokens
     * @param _numberOfTokens length of array of token addresses
     */
    constructor(
        uint256 _escFee,
        address[] memory _tokenAddresses,
        uint256 _numberOfTokens
    ) {
        escAcc = msg.sender;
        escFee = _escFee;

        for (uint256 i = 0; i < _numberOfTokens; i++) {
            acceptedTokens[_tokenAddresses[i]] = true;
        }

        acceptedTokens[IDEA_TOKEN_ADDRESS] = true;
    }

    /**
     * Used to create an Escrow Offer
     * @param _serviceType service title of the offer
     * @param _acceptor address of the party accepting the offer
     * @param _token ERC20 token address which will be used for payment (should be in supported tokens)
     * @param _amount Amount of payable ERC20 tokens
     */
    function createOffer(
        string memory _serviceType,
        address _acceptor,
        address _token,
        uint256 _amount
    ) external payable returns (bool) {
        require(bytes(_serviceType).length > 0, "Service Type cannot be empty");
        require(acceptedTokens[_token], "Payment Token not supported");

        IERC20 token = IERC20(_token);

        require(
            token.allowance(msg.sender, address(this)) >= _amount,
            "Payable amount is greater than allowance"
        );

        uint256 offerId = totalOffers++;
        OfferStruct memory offer;

        offer.offerId = offerId;
        offer.serviceType = _serviceType;
        offer.amount = _amount;
        offer.paymentToken = _token;
        offer.timestamp = block.timestamp;
        offer.creator = msg.sender;
        offer.acceptor = _acceptor;
        offer.status = Status.PENDING;

        offers[offerId] = offer;
        offersOf[msg.sender].push(offer);
        creatorOf[offerId] = msg.sender;

        bool receipt = token.transferFrom(msg.sender, address(this), _amount);

        emit Action(offerId, "OFFER CREATED", Status.PENDING, msg.sender);

        return receipt;
    }

    /**
     * Returns all the offers created
     */
    function getOffers() external view returns (OfferStruct[] memory props) {
        props = new OfferStruct[](totalOffers);

        for (uint256 i = 0; i < totalOffers; i++) {
            props[i] = offers[i];
        }
    }

    /**
     * Returns an offer struct based on offer id
     * @param offerId offer id
     */
    function getOffer(
        uint256 offerId
    ) external view returns (OfferStruct memory) {
        return offers[offerId];
    }

    /**
     * Only returns all the created offers of the sender
     */
    function myOffers() external view returns (OfferStruct[] memory) {
        return offersOf[msg.sender];
    }

    /**
     * Used to complete or refund the offer
     * No escrow fee deducted on using IDEA token
     * @param offerId id of the offer
     * @param completed whether it is completed or refunded
     */
    function confirmDelivery(
        uint256 offerId,
        bool completed
    ) external returns (bool) {
        require(msg.sender == creatorOf[offerId], "Only creator allowed");
        require(
            offers[offerId].status == Status.PENDING,
            "Already delivered or withdrawed, create a new Offer"
        );

        if (completed) {
            uint256 fee;

            if (offers[offerId].paymentToken == IDEA_TOKEN_ADDRESS) {
                fee = 0;
            } else {
                fee = (offers[offerId].amount * escFee) / 100;
            }

            IERC20 token = IERC20(offers[offerId].paymentToken);
            token.transfer(
                offers[offerId].acceptor,
                offers[offerId].amount - fee
            );

            offers[offerId].status = Status.DELIVERED;
            totalDelivered++;

            emit Action(offerId, "DELIVERED", Status.DELIVERED, msg.sender);
        } else {
            IERC20 token = IERC20(offers[offerId].paymentToken);
            token.transfer(offers[offerId].creator, offers[offerId].amount);

            offers[offerId].status = Status.REFUNDED;
            totalWithdrawed++;

            emit Action(offerId, "REFUNDED", Status.REFUNDED, msg.sender);
        }

        return true;
    }

    /**
     * Used to withdraw any ETH present in the contract
     * @param to address of the recipient
     * @param amount amount to send
     */
    function withdrawETH(
        address payable to,
        uint256 amount
    ) external onlyOwner returns (bool) {
        to.transfer(amount);

        emit Action(
            block.timestamp,
            "WITHDRAWED",
            Status.WITHDRAWED,
            msg.sender
        );

        return true;
    }

    /**
     * Used to transfer ERC20 tokens from the contract to any account
     * @param to Recipient account address
     * @param _token address of the ERC20 token
     * @param amount amount of tokens to send
     */
    function withdrawERC20Token(
        address to,
        address _token,
        uint256 amount
    ) external onlyOwner {
        require(acceptedTokens[_token], "Payment Token not supported");
        IERC20 token = IERC20(_token);
        token.transfer(to, amount);
    }

    /**
     * Used to add further supported ERC20 tokens
     * @param _tokenAddress address of the ERC20 token
     */
    function addSupportedToken(
        address _tokenAddress
    ) external onlyOwner returns (bool) {
        acceptedTokens[_tokenAddress] = true;
        return true;
    }

    /**
     * Used to update the current escrow fee
     * @param _escFee is the escrow fee cut percentage
     */
    function updateEscrowFee(
        uint256 _escFee
    ) external onlyOwner returns (bool) {
        escFee = _escFee;
        return true;
    }
}