// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface TokenDistributor {
    function claimableTokens(address wallet) external returns (uint256);
}


contract ArbOtc is Ownable, ReentrancyGuard {

    event TradeOfferCreated(uint256 tradeId, address creator, uint256 costPerToken, uint256 tokens);
    event TradeOfferCancelled(uint256 tradeId);
    event TradeOfferAccepted(uint256 tradeId);
    event AgreementFulfilled(uint256 agreementId);

    address public USDC_ADDRESS = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB; //link
    address public AIRDROP_ADDRESS = 0x67a24CE4321aB3aF51c2D0a4801c3E111D88C9d9;
    address public ARB_ADDRESS = 0x912CE59144191C1204E64559FE8253a0e49E6548;

    //Max and min costs to prevent over/under paying mistakes.
    uint256 public MAX_COST = 900000; //Max of 90c USDC
    uint256 public MIN_COST = 600000; //Min of 60c USDC

    uint256 airdropStart = 18208000;
    uint256 collateralLostAt = airdropStart + 3 days;

    mapping(address => uint256) public offeredArb;

    TradeOffer[] public tradeOffers;
    Agreement[] public agreements;
    
    struct TradeOffer {
        address creator;
        uint256 tokens;
        uint256 costPerToken;
        bool active;
    }

    struct Agreement {
        address seller;
        address buyer;
        uint256 tokens;
        uint256 costPerToken;
        bool active;
    }

    function createOffer(uint256 _costPerToken, uint256 _tokens) public nonReentrant {
        require(_costPerToken >= MIN_COST, "Below min cost");
        require(_costPerToken <= MAX_COST, "Above max cost");
        require(_tokens > 0, "Non zero value");
        // require(block.timestamp < airdropStart, "Airdrop already finished");

        uint256 claimable = TokenDistributor(AIRDROP_ADDRESS).claimableTokens(msg.sender);

        claimable -= offeredArb[msg.sender];

        require(claimable >= _tokens, "You don't have that amount of tokens to claim");

        uint256 collateral = ((_costPerToken * _tokens) * 25 / 100);

        IERC20(USDC_ADDRESS).transferFrom(
            msg.sender,
            address(this),
            collateral
        );

        TradeOffer memory newOffer = TradeOffer({
            creator: msg.sender,
            tokens: _tokens,
            costPerToken: _costPerToken,
            active: true
        });

        offeredArb[msg.sender] += _tokens;

        tradeOffers.push(newOffer);
    }

    function cancelOffer(uint256 tradeId) public nonReentrant {
        TradeOffer storage offer = tradeOffers[tradeId];
        require(offer.active, "Offer accepted or cancelled");
        
        uint256 collateral = ((offer.costPerToken * offer.tokens) * 25 / 100);

        offer.active = false;
        offeredArb[msg.sender] -= offer.tokens;

        IERC20(USDC_ADDRESS).transfer(
            msg.sender,
            collateral
        );

        emit TradeOfferCancelled(tradeId);
    }

    function acceptOffer(uint256 tradeId) public nonReentrant {
        TradeOffer storage offer = tradeOffers[tradeId];
        require(offer.active, "Offer accepted or cancelled");

        uint256 cost = offer.costPerToken * offer.tokens;

        IERC20(USDC_ADDRESS).transferFrom(
            msg.sender,
            address(this),
            cost
        );

        offer.active = false;

        Agreement memory newAgreement = Agreement({
            seller: offer.creator,
            buyer: msg.sender,
            tokens: offer.tokens,
            costPerToken: offer.costPerToken,
            active: true
        });

        agreements.push(newAgreement);

        emit TradeOfferAccepted(tradeId);
    }

    function fufilOffer(uint256 agreementId) public nonReentrant {
        Agreement storage agreement = agreements[agreementId];
        require(agreement.active, "Not active");
        require(msg.sender == agreement.seller, "Not seller");

        agreement.active = false;
        offeredArb[agreement.seller] -= agreement.tokens;

        IERC20(ARB_ADDRESS).transferFrom(
            msg.sender,
            agreement.buyer,
            agreement.tokens
        );

        uint256 cost = agreement.costPerToken * agreement.tokens;
        uint256 fee = cost * 5 / 100;

        IERC20(USDC_ADDRESS).transfer(
            msg.sender,
            cost - fee
        );

        IERC20(USDC_ADDRESS).transfer(
            owner(),
            fee
        );


        //Return collateral.
        uint256 collateral = ((agreement.costPerToken * agreement.tokens) * 25 / 100);

        IERC20(USDC_ADDRESS).transfer(
            msg.sender,
            collateral
        );

        emit AgreementFulfilled(agreementId);
    }

    function claimCollateral(uint256 agreementId) public nonReentrant {
        Agreement storage agreement = agreements[agreementId];
        require(msg.sender == agreement.buyer, "Not buyer");
        require(block.timestamp >= collateralLostAt, "Agreement not expired yet");
        require(agreement.active, "Agreement not active");

        uint256 collateral = ((agreement.costPerToken * agreement.tokens) * 25 / 100);
        uint256 fee = collateral * 5 / 100;

        agreement.active = false;

        IERC20(USDC_ADDRESS).transfer(
            msg.sender,
            collateral - fee
        );

        IERC20(USDC_ADDRESS).transfer(
            owner(),
            fee
        );
    }

    function getOffers(uint256 startIndex, uint256 endIndex) public view returns (TradeOffer[] memory) {
        require(startIndex < endIndex, "Invalid range");
        require(endIndex <= tradeOffers.length, "End index out of bounds");

        uint256 length = endIndex - startIndex;
        TradeOffer[] memory offers = new TradeOffer[](length);

        for (uint256 i = startIndex; i < endIndex; i++) {
            offers[i - startIndex] = tradeOffers[i];
        }

        return offers;
    }

    function getAgreements(uint256 startIndex, uint256 endIndex) public view returns (Agreement[] memory) {
        require(startIndex < endIndex, "Invalid range");
        require(endIndex <= agreements.length, "End index out of bounds");

        uint256 length = endIndex - startIndex;
        Agreement[] memory agmts = new Agreement[](length);

        for (uint256 i = startIndex; i < endIndex; i++) {
            agmts[i - startIndex] = agreements[i];
        }

        return agmts;
    }

    function setAddresses(address _USDC, address _ARB, address _AIRDROP) public onlyOwner {
        USDC_ADDRESS = _USDC;
        ARB_ADDRESS = _ARB;
        AIRDROP_ADDRESS = _AIRDROP;
    }

    function setMaxAndMin(uint256 _min, uint256 _max) public onlyOwner {
        MIN_COST = _min;
        MAX_COST = _max;
    }

    function setAirdropStart(uint256 startTimestamp) public onlyOwner {
        airdropStart = startTimestamp;
        collateralLostAt = airdropStart + 3 days;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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