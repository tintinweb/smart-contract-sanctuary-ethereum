//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface iUSDc {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint);
}

interface iDai {
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
}

interface iUSDt {
    function transferFrom(address _from, address _to, uint256 _value) external;
    function balanceOf(address who) external view returns (uint);
}

contract Subscription {
    using SafeMath for uint256;

    mapping(uint256 => uint256) public subscriptionPrices;
    uint256 public numSubscriptionLevels;
    bool public renewalsEnabled = true;
    string public name;
    address public owner;
  
    // these 2 mappings are the MAIN features for FE. user's address can be easily taken from FE.
    // expiryTime -> determines whether user's subscription is still valid
    // subscriptionLevel -> determines the features user can access on FE
    mapping(address => uint256) public expiryTime;
    mapping(address => uint256) public userSubscriptionLevel;

    event renewed(address _addr, uint256 _expiryTime, uint256 _level);

    iUSDc public USDc;
    iDai public Dai;
    iUSDt public USDt;

    constructor(uint256[] memory _price, string memory _name, address _owner) {
        for(uint256 i; i < _price.length; i++){
            subscriptionPrices[i] = _price[i] * 1e18;
        }            
        numSubscriptionLevels = _price.length;
        name = _name;
        owner = _owner;

        // addresses of most common stablecoins.
        USDc = iUSDc(0x07865c6E87B9F70255377e024ace6630C1Eaa37F);
        Dai = iDai(0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844);
        USDt = iUSDt(0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "you are not the owner");
        _;
    }

    // need to approve from FE first. _stablesId refers to which stablecoin is used for payment
    function renewalStables(address _addr, uint256 _stablesId, uint256 _level) public {
        require(renewalsEnabled, "Renewals are currently disabled");
        require(_stablesId <= 2);
        require(_level <= numSubscriptionLevels);
        uint256 _currentexpiryTime = expiryTime[_addr];

        if (_stablesId == 0) {
            //usdc
            require(USDc.balanceOf(msg.sender) >= subscriptionPrices[_level]);
            USDc.transferFrom(msg.sender, address(this), subscriptionPrices[_level]);
        } else if (_stablesId == 1) {
            //dai
            require(Dai.balanceOf(msg.sender) >= subscriptionPrices[_level]);
            Dai.transferFrom(msg.sender, address(this), subscriptionPrices[_level]);
        } else {
            //usdt
            require(USDt.balanceOf(msg.sender) >= subscriptionPrices[_level]);
            USDt.transferFrom(msg.sender, address(this), subscriptionPrices[_level]);
        }

        if (block.timestamp > _currentexpiryTime) {
            expiryTime[_addr] = block.timestamp + 30 days;
        } else {
            expiryTime[_addr] += 30 days;
        }

        userSubscriptionLevel[_addr] = _level;
        emit renewed(_addr, expiryTime[_addr], _level);
    }

    // renewal via eth. may not be ideal due to continuous price fluctuations.
    // fixed price would work best, else the use of oracles to get eth/usd is required.
    // since this is payable by eth, no approval is needed.
    function renewalEth(address _addr, uint256 _level) public payable{
        require(msg.value >= subscriptionPrices[_level], "Incorrect amount of ether sent.");
        require(renewalsEnabled, "Renewals are currently disabled");

        uint256 _currentexpiryTime = expiryTime[_addr];

        if (block.timestamp > _currentexpiryTime) {
            expiryTime[_addr] = block.timestamp + 30 days;
        } else {
            expiryTime[_addr] += 30 days;
        }

        userSubscriptionLevel[_addr] = _level;
        emit renewed(_addr, expiryTime[_addr], _level);
    }
    
    function toggleRenewalsActive(bool _state) external onlyOwner {
        renewalsEnabled = _state;
    }

    // to counter inflation
    function updateSubscriptionPrice(uint256[] memory _newPrices) external onlyOwner {
        for(uint256 i; i < _newPrices.length; i++){
            subscriptionPrices[i] = _newPrices[i] * 1e18;
        }    
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;    
    }

    // this can be improved on to only call transferfrom for cryptos that balance is >0
    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance >= 0, "No ether left to withdraw");
        (bool success, ) = (msg.sender).call{value: balance}("");
        USDc.transferFrom(address(this), msg.sender, USDc.balanceOf(address(this)));
        Dai.transferFrom(address(this), msg.sender, Dai.balanceOf(address(this)));
        USDt.transferFrom(address(this), msg.sender, USDt.balanceOf(address(this)));
        require(success, "Transfer failed.");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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