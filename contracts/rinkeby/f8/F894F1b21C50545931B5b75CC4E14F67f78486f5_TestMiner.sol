pragma solidity >=0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TestMiner is Context, Ownable {
    using SafeMath for uint256;

    uint256 private constant DEPOSIT_MAX_AMOUNT = 50*10e3 ether;
    uint256 private MINING_STEP = 1080000;
    uint256 private TAX_PERCENT = 2;
    uint256 private BOOST_PERCENT = 20;
    uint256 private BOOST_CHANCE = 35;
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;

    //fishingPower rubyMiners
    mapping(address => uint256) private cronosMiners;

    //claimedRuby // fishPool 
    mapping(address => uint256) private claimedCronos;

    mapping(address => uint256) private lastMining;
    mapping(address => address) private referrals;
    address payable private devAdd;
    address payable private marketingAdd;
    address payable private teamAdd;
    uint256 private participants;
    uint256 private minersHired;
    uint256 private marketCronos;
    bool private startExtracting = false;

    event RewardsBoosted(address indexed adr, uint256 boosted);


    constructor() {
        devAdd = payable(msg.sender);
        marketingAdd = payable(msg.sender);
        teamAdd = payable(msg.sender);
    }

    function handleHire(address ref, bool isRehire) private {
        uint256 userCronos = getMyCronos(msg.sender);
        uint256 newMiningPower = SafeMath.div(userCronos, MINING_STEP);
        if (isRehire && random(msg.sender) <= BOOST_CHANCE) {
            uint256 boosted = getBoost(newMiningPower);
            newMiningPower = SafeMath.add(newMiningPower, boosted);
            emit RewardsBoosted(msg.sender, boosted);
        }

        cronosMiners[msg.sender] = SafeMath.add(cronosMiners[msg.sender], newMiningPower);
        claimedCronos[msg.sender] = 0;
        lastMining[msg.sender] = block.timestamp;

        if (ref == msg.sender) {
            ref = address(0);
        }
        if (referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        claimedCronos[referrals[msg.sender]] = SafeMath.add(claimedCronos[referrals[msg.sender]], SafeMath.div(userCronos, 8));

        minersHired++;
        marketCronos = SafeMath.add(marketCronos, SafeMath.div(userCronos, 5));
    }

    function hireMiners(address ref) public payable {
        require(startExtracting, 'Cronos mine not started to extract yet');
        require(msg.value <= DEPOSIT_MAX_AMOUNT, 'Maximum deposit amount is 50 000 CRONOS max');
        uint256 amount = calculateBuy(msg.value, SafeMath.sub(address(this).balance, msg.value));
        amount = SafeMath.sub(amount, getTax(amount));

        uint256 marketingTax = getTax(msg.value);
        uint256 devTax = getTax(msg.value);
        uint256 teamTax = getTax(msg.value);
        marketingAdd.transfer(marketingTax);
        devAdd.transfer(devTax);
        teamAdd.transfer(teamTax);

        if (cronosMiners[msg.sender] == 0) {
            participants++;
        }

        claimedCronos[msg.sender] = SafeMath.add(claimedCronos[msg.sender], amount);
        handleHire(ref, false);
    }

    function rehireMiners(address ref) public {
        require(startExtracting, 'Cronos mine not started to extract yet');
        handleHire(ref, true);
    }

    function sellCronos() public {
        require(startExtracting, 'Cronos mine not started to extract yet');
        uint256 userCronos = getMyCronos(msg.sender);
        uint256 sellRewards = calculateSell(userCronos);
        claimedCronos[msg.sender] = 0;
        lastMining[msg.sender] = block.timestamp;
        marketCronos = SafeMath.add(marketCronos, userCronos);
        uint256 marketingTax = getTax(sellRewards);
        uint256 devTax = getTax(sellRewards);
        uint256 teamTax = getTax(sellRewards);
        uint256 totalTax = SafeMath.add(marketingTax, devTax).add(teamTax);
        marketingAdd.transfer(marketingTax);
        devAdd.transfer(devTax);
        teamAdd.transfer(teamTax);
        payable(msg.sender).transfer(SafeMath.sub(sellRewards, totalTax));
    }

    //checked
    function calculateTrade(
        uint256 rt,
        uint256 rs,
        uint256 bs
    ) private view returns (uint256) {
        return SafeMath.div(SafeMath.mul(PSN, bs), SafeMath.add(PSNH, SafeMath.div(SafeMath.add(SafeMath.mul(PSN, rs), SafeMath.mul(PSNH, rt)), rt)));
    }

    function calculateSell(uint256 fish) public view returns (uint256) {
        return calculateTrade(fish, marketCronos, address(this).balance);
    }

    function calculateBuy(uint256 eth, uint256 contractBalance) public view returns (uint256) {
        return calculateTrade(eth, contractBalance, marketCronos);
    }

    function calculateBuySimple(uint256 eth) public view returns(uint256) {
        return calculateBuy(eth,address(this).balance);
    }

    function getProjectBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getProjectStats()
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (address(this).balance, participants, minersHired);
    }

    function getMyCronos(address adr) public view returns (uint256) {
        return SafeMath.add(claimedCronos[adr], getCronosSinceLastHarvest(adr));
    }

    function getCronosSinceLastHarvest(address adr) public view returns (uint256) {
        uint256 secondsPassed = min(MINING_STEP, SafeMath.sub(block.timestamp, lastMining[adr]));
        return SafeMath.mul(secondsPassed, cronosMiners[adr]);
    }

    function getUserRewards(address adr) public view returns (uint256) {
        uint256 sellRewards = 0;
        uint256 userCronos = getMyCronos(adr);
        if (userCronos > 0) {
            sellRewards = calculateSell(userCronos);
        }
        return sellRewards;
    }

    function getUserMining(address adr) public view returns (uint256) {
        return cronosMiners[adr];
    }

    function getUserStats(address adr) public view returns (uint256, uint256) {
        return (getUserRewards(adr), cronosMiners[adr]);
    }

    function getTax(uint256 amount) private view returns (uint256) {
        return SafeMath.div(SafeMath.mul(amount, TAX_PERCENT), 100);
    }

    function getBoost(uint256 amount) private view returns (uint256) {
        return SafeMath.div(SafeMath.mul(amount, BOOST_PERCENT), 100);
    }

    function seedMarket() public payable onlyOwner {
        require(marketCronos == 0);
        startExtracting = true;
        marketCronos = 108000000000;
    }

    function random(address adr) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, cronosMiners[adr], minersHired))) % 100;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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