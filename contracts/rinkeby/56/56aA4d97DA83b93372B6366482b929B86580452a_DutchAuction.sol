/**
 *Submitted for verification at Etherscan.io on 2022-04-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;



// Part: IERC721

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external;

    function transferFrom(
        address,
        address,
        uint
    ) external;
}

// Part: SafeMath

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: DutchAuction.sol

/*
 * @title: DutchAuction Smart Contract.
 * @author: Anthony (fps) https://github.com/fps8k .
 * @dev: Reference [README.md].
 * @notice: Same as Auction [reference ./ Auction/Auction.sol] but with some differences.
*/

contract DutchAuction
{
    using SafeMath for uint256;

    // Creating necessary state variables.
    // Time of deployment and time span of the bidding and the time of the last depreciation.

    uint256 private deploy_time;
    uint64 private bid_time_span = 7 days;
    bool private still_bidding;
    uint private interval_for_depreciation;
    uint private last_depreciation;
    uint private price_gone;
    bool locked;
    


    // NFT Details for constructor.

    IERC721 private nft;
    uint256 private nft_id;
    uint256 private starting_bid;
    address private seller;
    uint private depreciation;


    constructor(address _nft_address, uint256 _nft_id) payable
    {
        nft = IERC721(_nft_address);
        nft_id = _nft_id;
        starting_bid = msg.value;
        seller = msg.sender;
        depreciation = 1_000_000 gwei;
        // interval_for_depreciation = 1 days;
        last_depreciation = block.timestamp;

        deploy_time = block.timestamp;
        still_bidding = true;
    }

    fallback() payable external {}
    receive() payable external {}


    /* 
    * @dev:
    * {bid()} function allows the caller to make a fresh bid.
    *
    * Conditions:
    * - Caller cannot be a 0 address.
    * - Caller cannot be the `seller` of the token.
    * - `msg.value` must be greater than the `starting_bid`.
    * - It must be still the validity of the bid.
    * - `msg.value` sent for the bid, must be unique.
    *
    * - If the new bid is higher than the current highest bid, then, it replaces the value.
    */
    // 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, 34

    function checkAddress() internal view returns(bool)
    {
        return (msg.sender != address(0)) && ((msg.sender != seller));
    }

    
    function getPrice() internal returns(uint256)
    {
        uint time_gone = block.timestamp - last_depreciation;

        price_gone = depreciation * (time_gone / interval_for_depreciation); // 10 gwei * (100secs/10secs)

        if(price_gone >= starting_bid)
        {
            starting_bid = 0;
        }
        else
        {
            starting_bid = starting_bid - price_gone;
        }

        last_depreciation = block.timestamp;
        
        return price_gone;
    }
    

    function buy() public payable
    {
        
        require(still_bidding, "Bid closed");

        uint price = getPrice(); // to renew prices;

        require(checkAddress(), "Bid cant be made by this address");
        require(msg.value >= price, "Bid < Starting bid.");

        nft.transferFrom(seller, msg.sender, nft_id);

        uint refund = msg.value - price;

        if(refund > 0)
        {
            payable(msg.sender).transfer(refund);
        }

        seller = address(0);
        nft_id = 0;
    }
}