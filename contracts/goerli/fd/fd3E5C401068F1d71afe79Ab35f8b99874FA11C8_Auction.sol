// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./Auth.sol";
import "./SafeMath.sol";

contract AuctionFactory {
    Auction[] public auctions;

    function createAuction(
        string memory _title,
        uint _startPrice,
        string memory _description,
        string memory _itemIpfs
    ) public {
        // set the new instance
        Auction newAuction = new Auction(
            payable(msg.sender),
            _title,
            _startPrice,
            _description,
            _itemIpfs
        );
        // push the auction address to auctions array
        auctions.push(newAuction);
    }

    function returnAllAuctions() public view returns (Auction[] memory) {
        return auctions;
    }
}

contract Auction is Auth {
    using SafeMath for uint256;

    address payable private owner;
    string title;
    uint startPrice;
    string description;
    string itemIpfs;
    uint count;

    struct Buyer {
        address buyerAddress;
        uint256 price;
        string item;
    }

    Buyer[] public buyer;

    enum State {
        Default,
        Running,
        Finalized
    }
    State public auctionState;

    uint public highestPrice;
    address payable public highestBidder;
    mapping(address => uint) public bids;

    /** @dev constructor to creat an auction
     * @param _owner who call createAuction() in AuctionFactory contract
     * @param _title the title of the auction
     * @param _startPrice the start price of the auction
     * @param _description the description of the auction
     */

    constructor(
        address payable _owner,
        string memory _title,
        uint _startPrice,
        string memory _description,
        string memory _itemIpfs
    ) {
        // initialize auction
        owner = _owner;
        title = _title;
        startPrice = _startPrice;
        description = _description;
        itemIpfs = _itemIpfs;
        auctionState = State.Running;
    }

    modifier notOwner() {
        require(msg.sender != owner);
        _;
    }

    /** @dev Function to place a bid
     * @return true
     */

    function placeBid(address _addr) public payable notOwner returns (bool) {
        require(
            checkIsUserLogged(_addr) == true,
            "You need to be sign in before bidding!"
        );
        require(auctionState == State.Running);
        require(msg.value > 0);
        // update the current bid
        // uint currentBid = bids[msg.sender] + msg.value;
        uint currentBid = bids[msg.sender].add(msg.value);

        require(currentBid > highestPrice);
        // set the currentBid links with msg.sender
        bids[msg.sender] = currentBid;
        // update the highest price
        highestPrice = currentBid;
        highestBidder = payable(msg.sender);

        return true;
    }

    function finalizeAuction() public {
        //the owner can finalize the auction.
        require(msg.sender == owner);

        address payable recipiant;
        uint value;

        // owner can get highestPrice
        if (msg.sender == owner) {
            recipiant = owner;
            value = highestPrice;
        }
        // highestBidder can get no money
        else if (msg.sender == highestBidder) {
            recipiant = highestBidder;
            buyer[count].buyerAddress = recipiant;
            buyer[count].price = value;
            buyer[count].item = itemIpfs;
            itemIpfs = "0";
            value = 0;
            count++;
        }
        // Other bidders can get back the money
        else {
            recipiant = payable(msg.sender);
            value = bids[msg.sender];
        }
        // initialize the value
        bids[msg.sender] = 0;
        recipiant.transfer(value);
        auctionState = State.Finalized;
    }

    /** @dev Function to return the contents od the auction
     * @return the title of the auction
     * @return the start price of the auction
     * @return the description of the auction
     * @return the state of the auction
     */

    function returnContents()
        public
        view
        returns (string memory, uint, string memory, Buyer[] memory)
    {
        return (title, startPrice, description, buyer);
    }

    function returnWinners() public view returns (Buyer[] memory) {
        return (buyer);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.17;

contract Auth {
    struct UserDetail {
        address addr;
        string name;
        string password;
        bool isUserLoggedIn;
    }

    mapping(address => UserDetail) user;

    // user registration function
    function register(
        address _address,
        string memory _name,
        string memory _password
    ) public returns (bool) {
        require(user[_address].addr != msg.sender);
        user[_address].addr = _address;
        user[_address].name = _name;
        user[_address].password = _password;
        user[_address].isUserLoggedIn = false;
        return true;
    }

    // user login function
    function login(
        address _address,
        string memory _password
    ) public returns (bool) {
        if (
            keccak256(abi.encodePacked(user[_address].password)) ==
            keccak256(abi.encodePacked(_password))
        ) {
            user[_address].isUserLoggedIn = true;
            return user[_address].isUserLoggedIn;
        } else {
            return false;
        }
    }

    // check the user logged In or not
    function checkIsUserLogged(address _address) public view returns (bool) {
        return (user[_address].isUserLoggedIn);
    }

    // logout the user
    function logout(address _address) public {
        user[_address].isUserLoggedIn = false;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

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
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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