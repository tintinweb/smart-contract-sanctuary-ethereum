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

    address public USDC_ADDRESS = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
    address public AIRDROP_ADDRESS = 0x67a24CE4321aB3aF51c2D0a4801c3E111D88C9d9;
    address public ARB_ADDRESS = 0x0e33571A5086510e7C865f67709999f2824fB138;

    address public FEE_1 = 0xb0336AF5941588dF1F8C746e393eAb2c05039b28;
    address public FEE_2 = 0xB4575b33c42Ce8489C44A4Cb5c1BE795fc361a2e;

    //Max and min costs to prevent over/under paying mistakes.
    uint256 public MAX_COST = 2000000; //Max of 2 USDC
    uint256 public MIN_COST = 300000; //Min of 30c USDC

    bool public OFFERS_EXPIRED = false;
    bool public EMERGENCY_WITHDRAWL = false;

    mapping(address => uint256) public offeredArb;

    mapping(address => uint256) public USDCDeposited;

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


    /// @notice Allows a user to create a trade offer
    /// @dev Requires the user to lock 25% of the total cost as collateral
    /// @param _costPerToken The cost per token in USDC
    /// @param _tokens The number of tokens offered in the trade
    function createOffer(uint256 _costPerToken, uint256 _tokens) public nonReentrant {

        _tokens = _tokens / 1 ether;

        require(_costPerToken >= MIN_COST, "Below min cost");
        require(_costPerToken <= MAX_COST, "Above max cost");
        require(_tokens > 0, "Non zero value");
        require(!OFFERS_EXPIRED, "Offers not allowed");
        require(tx.origin == msg.sender, "EOA only");
        require(!EMERGENCY_WITHDRAWL, "Emergency withdrawl enabled");

        //uint256 claimable = TokenDistributor(AIRDROP_ADDRESS).claimableTokens(msg.sender);

        uint256 claimable = 100000 ether;

        claimable -= offeredArb[msg.sender];

        require(claimable / 1 ether >= _tokens, "You don't have that amount of tokens to claim");

        uint256 collateral = ((_costPerToken * _tokens) * 25 / 100);

        USDCDeposited[msg.sender] += collateral;

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

        offeredArb[msg.sender] += _tokens * 1 ether;

        tradeOffers.push(newOffer);
    }

    /// @notice Allows the creator of a trade offer to cancel it
    /// @dev Returns the collateral locked by the creator and marks the offer as inactive
    /// @param tradeId The ID of the trade offer to cancel
    function cancelOffer(uint256 tradeId) public nonReentrant {
        TradeOffer storage offer = tradeOffers[tradeId];
        require(offer.active, "Offer accepted or cancelled");
        require(offer.creator == msg.sender, "Not your offer");
        require(tx.origin == msg.sender, "EOA only");
        require(!EMERGENCY_WITHDRAWL, "Emergency withdrawl enabled");
        
        uint256 collateral = ((offer.costPerToken * offer.tokens) * 25 / 100);

        offer.active = false;
        
        offeredArb[msg.sender] -= offer.tokens * 1 ether;

        USDCDeposited[msg.sender] -= collateral;

        IERC20(USDC_ADDRESS).transfer(
            msg.sender,
            collateral
        );
        

        emit TradeOfferCancelled(tradeId);
    }

    /// @notice Allows a user to accept an existing trade offer
    /// @dev The buyer pays the full cost of the tokens and the offer is marked as inactive
    /// @param tradeId The ID of the trade offer to accept
    function acceptOffer(uint256 tradeId) public nonReentrant {
        TradeOffer storage offer = tradeOffers[tradeId];
        require(offer.active, "Offer accepted or cancelled");
        require(msg.sender != offer.creator, "Can't accept own offer");
        require(tx.origin == msg.sender, "EOA only");
        require(!EMERGENCY_WITHDRAWL, "Emergency withdrawl enabled");

        uint256 cost = offer.costPerToken * offer.tokens;

        USDCDeposited[msg.sender] += cost;

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

    /// @notice Allows the seller of an agreement to fulfill it
    /// @dev The seller receives the payment minus a 5% fee, and the collateral is returned
    /// @param agreementId The ID of the agreement to fulfill
    function fulfilOffer(uint256 agreementId) public nonReentrant {
        Agreement storage agreement = agreements[agreementId];
        require(agreement.active, "Not active");
        require(msg.sender == agreement.seller, "Not seller");
        require(tx.origin == msg.sender, "EOA only");
        require(!EMERGENCY_WITHDRAWL, "Emergency withdrawl enabled");

        agreement.active = false;

        uint256 arbToSend = agreement.tokens * 1 ether;

        offeredArb[agreement.seller] -= arbToSend;

        IERC20(ARB_ADDRESS).transferFrom(
            msg.sender,
            agreement.buyer,
            arbToSend
        );

        uint256 cost = agreement.costPerToken * agreement.tokens;
        uint256 fee = cost * 5 / 100;

        USDCDeposited[agreement.buyer] -= cost;

        IERC20(USDC_ADDRESS).transfer(
            msg.sender,
            cost - fee
        );
        

        IERC20(USDC_ADDRESS).transfer(
            FEE_1,
            fee / 2
        );

        IERC20(USDC_ADDRESS).transfer(
            FEE_2,
            fee / 2
        );


        //Return collateral.
        uint256 collateral = ((agreement.costPerToken * agreement.tokens) * 25 / 100);

        
        USDCDeposited[msg.sender] -= collateral;

        IERC20(USDC_ADDRESS).transfer(
            msg.sender,
            collateral
        );

        emit AgreementFulfilled(agreementId);
    }

    /// @notice Allows the buyer of an agreement to claim the collateral if the agreement has not been fulfilled after the expiration time
    /// @dev The buyer receives the collateral minus a 5% fee
    /// @param agreementId The ID of the agreement to claim the collateral for
    function claimCollateral(uint256 agreementId) public nonReentrant {
        Agreement storage agreement = agreements[agreementId];
        require(msg.sender == agreement.buyer, "Not buyer");
        require(OFFERS_EXPIRED, "Agreement not expired yet");
        require(agreement.active, "Agreement not active");
        require(tx.origin == msg.sender, "EOA only");
        require(!EMERGENCY_WITHDRAWL, "Emergency withdrawl enabled");

        uint256 cost = agreement.costPerToken * agreement.tokens;

        uint256 collateral = ((cost) * 25 / 100);
        uint256 fee = collateral * 5 / 100;

        agreement.active = false;
        
        USDCDeposited[agreement.seller] -= collateral;
        USDCDeposited[msg.sender] -= cost;

        IERC20(USDC_ADDRESS).transfer(
            msg.sender,
            cost + collateral - fee
        );

        IERC20(USDC_ADDRESS).transfer(
            FEE_1,
            fee / 2
        );

        IERC20(USDC_ADDRESS).transfer(
            FEE_2,
            fee / 2
        );
    }

     /// @notice Allows users to withdraw their deposited USDC in case of an emergency.
     /// @dev Resets the USDC deposited amount for the user after the withdrawal.
    function emergencyWithdraw() public {
        require(tx.origin == msg.sender, "EOA only");
        require(EMERGENCY_WITHDRAWL, "Emergency not active");
        require(USDCDeposited[msg.sender] > 0, "No funds available to withdraw");

        uint256 amountDeposited = USDCDeposited[msg.sender];

        USDCDeposited[msg.sender] = 0;

        require(IERC20(USDC_ADDRESS).transfer(msg.sender, amountDeposited));
    }

    /// @notice Returns an array of trade offers within the specified range
    /// @dev Pagination is used to fetch trade offers in smaller chunks
    /// @param startIndex The start index of the trade offers to fetch
    /// @param endIndex The end index of the trade offers to fetch
    /// @return offers An array of TradeOffer structs within the specified range
    function getOffers(uint256 startIndex, uint256 endIndex) public view returns (TradeOffer[] memory) {
        require(startIndex < endIndex, "Invalid range");

        if(endIndex > tradeOffers.length) endIndex = tradeOffers.length;

        uint256 length = endIndex - startIndex;
        TradeOffer[] memory offers = new TradeOffer[](length);

        for (uint256 i = startIndex; i < endIndex; i++) {
            offers[i - startIndex] = tradeOffers[i];
        }

        return offers;
    }

    /// @notice Returns an array of agreements within the specified range
    /// @dev Pagination is used to fetch agreements in smaller chunks
    /// @param startIndex The start index of the agreements to fetch
    /// @param endIndex The end index of the agreements to fetch
    /// @return agmts An array of Agreement structs within the specified range
    function getAgreements(uint256 startIndex, uint256 endIndex) public view returns (Agreement[] memory) {
        require(startIndex < endIndex, "Invalid range");

        if(endIndex > agreements.length) endIndex = agreements.length;

        uint256 length = endIndex - startIndex;
        Agreement[] memory agmts = new Agreement[](length);

        for (uint256 i = startIndex; i < endIndex; i++) {
            agmts[i - startIndex] = agreements[i];
        }

        return agmts;
    }

    /// @notice Allows the contract owner to set the addresses for USDC, ARB, and AIRDROP tokens
    /// @dev This function is restricted to the contract owner
    /// @param _USDC The address of the USDC token
    /// @param _ARB The address of the ARB token
    /// @param _AIRDROP The address of the AIRDROP token
    function setAddresses(address _USDC, address _ARB, address _AIRDROP) public onlyOwner {
        USDC_ADDRESS = _USDC;
        ARB_ADDRESS = _ARB;
        AIRDROP_ADDRESS = _AIRDROP;
    }

    /// @notice Allows the contract owner to set the maximum and minimum acceptable costs per token
    /// @dev This function is restricted to the contract owner
    /// @param _min The minimum acceptable cost per token in USDC
    /// @param _max The maximum acceptable cost per token in USDC
    function setMaxAndMin(uint256 _min, uint256 _max) public onlyOwner {
        MIN_COST = _min;
        MAX_COST = _max;
    }

    /// @notice Expires all offers 3 days after the airdrop opens.
    /// @dev Can only be called by the contract owner.
    /// Incentive to let offers expire is a 5% fee on any buyers gained 
    function expireOffers() public onlyOwner {
        OFFERS_EXPIRED = true;
    }

    /// @notice Enables emergency withdrawals for users.
    /// @dev Can only be called by the contract owner.
    function triggerEmergencyWithdrawls() public onlyOwner {
        EMERGENCY_WITHDRAWL = true;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
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