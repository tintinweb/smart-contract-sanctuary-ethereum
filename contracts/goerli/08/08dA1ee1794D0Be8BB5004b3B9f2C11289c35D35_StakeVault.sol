// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract StakeVault is Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    
    struct StakeInfo {
        uint256 id;
        uint256 dealId;
        address staker;
        uint256 amount;
        uint256 restAmount;
        bool isClaimed;
    }

    struct DealPrice {
        uint256 price;
        uint256 startDate;
        uint256 updateDate;
    }

    struct LeadInvestor {
        address investor;
        bool isStaked;
    }

    struct DealAmount {
        uint256 preSale;
        uint256 minSale;
        uint256 maxSale;
    }

    struct StakeLimit {
        uint256 min;
        uint256 max;
    }

    struct DealBonus {
        uint256 start;
        uint256 end;
    }

    struct DealInfo {
        string name;
        string url;
        address sponsor;
        address stakingToken;
        uint256 offerPeriod;
        uint256[] stakeIds;
        uint256 totalStaked;
        DealBonus bonus;
        DealAmount amount;
        StakeLimit limit;
        LeadInvestor lead;
        DealPrice dealPrice;
        DealStatus status;
    }

    bool public closeAll = false;
    uint256[] private dealIds; 
    enum DealStatus { NotDisplaying, Staking, Offering, Delivering, Claiming, Closed }
    enum DisplayStatus { All, List, Item }

    Counters.Counter private _dealIds;
    Counters.Counter private _stakeIds;

    mapping (uint256 => StakeInfo) public stakeInfo;
    mapping (uint256 => DealInfo) public dealInfo;
    mapping (address => bool) public allowedTokenList;
    mapping (address => uint256[]) private stakesByInvestor;
    mapping (address => uint256[]) private dealsBySponsor;

    event AddDeal(uint256 indexed dealId, address sponsor);
    event UpdateDeal(uint256 indexed dealId, address sponsor);
    event SetDealPrice(uint256 indexed dealId, address sponsor);
    event UpdateDealPrice(uint256 indexed dealId, address sponsor);
    event Deposit(uint256 indexed stakeId, uint256 amount, address investor);
    event Withdraw(uint256 indexed stakeId, uint256 amount, address investor);
    event Claim(uint256 indexed dealId, uint256 amount, address sponsor);

    constructor(address _token) {
        allowedTokenList[_token] = true;
    }

    modifier allowedToken(address _token) {
        require(allowedTokenList[_token], "Not Allowed.");
        _;
    }

    modifier existDeal(uint256 _dealId) {
        require(_dealId <= _dealIds.current(), "Not Exist.");
        _;
    }

    function addDeal(
        string memory _name,
        string memory _url,
        address _leadInvestor,
        uint256 _startBonus,
        uint256 _endBonus,
        uint256 _preSaleAmount,
        uint256 _minSaleAmount,
        uint256 _maxSaleAmount,
        uint256[] memory _stakeLimit,
        uint256 _offerPeriod,
        address _stakingToken
    ) external allowedToken(_stakingToken) {
        require(!closeAll, "Closed.");
        _dealIds.increment();
        uint256 dealId = _dealIds.current();
        dealIds.push(dealId);
        dealsBySponsor[msg.sender].push(dealId);
        DealInfo storage deal = dealInfo[dealId];
        deal.name = _name;
        deal.url = _url;
        deal.lead.investor = _leadInvestor;
        deal.bonus.start = _startBonus;
        deal.bonus.end = _endBonus;
        deal.amount.preSale = _preSaleAmount;
        deal.amount.minSale = _minSaleAmount;
        deal.amount.maxSale = _maxSaleAmount;
        deal.limit.min = _stakeLimit[0];
        deal.limit.max = _stakeLimit[1];
        deal.offerPeriod = _offerPeriod;
        deal.sponsor = msg.sender;
        deal.stakingToken = _stakingToken;

        if(_leadInvestor != address(0)) {
            deal.status = DealStatus.NotDisplaying;
        } else {
            deal.status = DealStatus.Staking;
        }

        emit AddDeal(dealId, msg.sender);
    }

    function updateDeal(
        uint256 _dealId,
        address _leadInvestor,
        uint256 _startBonus,
        uint256 _endBonus,
        uint256 _preSaleAmount,
        uint256[] memory _stakeLimit,
        address _stakingToken
    ) external allowedToken(_stakingToken) {
        require(!closeAll, "Closed.");
        DealInfo storage deal = dealInfo[_dealId];
        require(deal.sponsor == msg.sender, "Must Sponsor.");
        require(deal.status == DealStatus.NotDisplaying || deal.status == DealStatus.Staking, "Wrong Status.");
        require(deal.stakeIds.length < 1, "Stake Exist.");
        deal.lead.investor = _leadInvestor;
        deal.bonus.start = _startBonus;
        deal.bonus.end = _endBonus;
        deal.amount.preSale = _preSaleAmount;
        deal.limit.min = _stakeLimit[0];
        deal.limit.max = _stakeLimit[1];
        deal.stakingToken = _stakingToken;

        if(_leadInvestor != address(0)) {
            if(deal.status != DealStatus.NotDisplaying) {
                deal.status = DealStatus.NotDisplaying;
            }
        } else {
            if(deal.status != DealStatus.Staking) {
                deal.status = DealStatus.Staking;
            }
        }

        emit UpdateDeal(_dealId, msg.sender);
    }

    function updateDealStatus(
        uint256 _dealId,
        DealStatus _status
    ) external {
        require(!closeAll, "Closed.");
        DealInfo storage deal = dealInfo[_dealId];
        require(deal.sponsor == msg.sender || owner() == msg.sender, "No Permission.");
        require(deal.status != DealStatus.Closed, "Wrong Status.");

        if(_status == DealStatus.NotDisplaying) {
            require(deal.stakeIds.length < 1, "Stake Exist.");
        } else if(_status == DealStatus.Staking) {
            require(deal.status < DealStatus.Delivering, "Wrong Status.");
        } else if(_status == DealStatus.Offering) {
            require(deal.status < DealStatus.Offering, "Wrong Status.");
        } else if(_status == DealStatus.Delivering) {
            require(deal.status == DealStatus.Offering, "Wrong Status.");
            require(deal.amount.minSale <= deal.totalStaked, "Not Enough.");

            if(owner() != msg.sender) {
                require(deal.dealPrice.startDate.add(deal.offerPeriod) < block.timestamp, "Period Error.");
            }
        } else if(_status == DealStatus.Claiming) {
            require(owner() == msg.sender && deal.status == DealStatus.Delivering, "Error.");
        } else if(_status != DealStatus.Closed) {
            revert("Can't change.");
        }
        
        deal.status = _status;
    }

    function checkDealStatus(
        uint256 _dealId,
        DealStatus _status
    ) public view existDeal(_dealId) returns(bool) {
        DealInfo memory deal = dealInfo[_dealId];
        return deal.status == _status;
    }

    function setDealPrice(
        uint256 _dealId,
        uint256 _price
    ) external existDeal(_dealId) {
        require(!closeAll, "Closed.");
        DealInfo storage deal = dealInfo[_dealId];
        require(deal.sponsor == msg.sender, "Must Sponsor.");
        deal.dealPrice.price = _price;
        deal.dealPrice.startDate = block.timestamp;
        deal.status = DealStatus.Offering;

        emit SetDealPrice(_dealId, msg.sender);
    }

    function updateDealPrice(
        uint256 _dealId,
        uint256 _price
    ) external existDeal(_dealId) {
        require(!closeAll, "Closed.");
        DealInfo storage deal = dealInfo[_dealId];
        require(deal.sponsor == msg.sender, "Must Sponsor.");
        require(deal.status == DealStatus.Offering, "Wrong Status.");
        deal.dealPrice.updateDate = block.timestamp;
        deal.dealPrice.price = _price;

        emit UpdateDealPrice(_dealId, msg.sender);
    }

    function deposit(
        uint256 _dealId,
        uint256 _amount
    ) external existDeal(_dealId) {
        require(!closeAll, "Closed.");
        require(checkDealStatus(_dealId, DealStatus.NotDisplaying) || checkDealStatus(_dealId, DealStatus.Staking) || checkDealStatus(_dealId, DealStatus.Offering), "Wrong Status.");
        DealInfo storage deal = dealInfo[_dealId];
        require(deal.limit.min <= _amount && _amount <= deal.limit.max, "Wrong Amount.");

        if(deal.lead.investor != address(0)) {
            if(deal.lead.investor != msg.sender) {
                require(deal.lead.isStaked, "Can't Stake.");
            } else {
                deal.lead.isStaked = true;
            }
            if(deal.stakeIds.length < 1) {
                deal.status = DealStatus.Staking;
            }
        }

        _stakeIds.increment();
        uint256 stakeId = _stakeIds.current();
        address staker = msg.sender;
        StakeInfo storage stake = stakeInfo[stakeId];
        stake.id = stakeId;
        stake.dealId = _dealId;
        stake.staker = staker;
        stake.amount = _amount;
        stakesByInvestor[staker].push(stakeId);
        deal.stakeIds.push(stakeId);
        deal.totalStaked = deal.totalStaked.add(_amount);
        IERC20(deal.stakingToken).transferFrom(staker, address(this), _amount);

        emit Deposit(_dealId, _amount, staker);
    }

    function withdraw(
        uint256 _stakeId
    ) external {
        StakeInfo storage stake = stakeInfo[_stakeId];
        uint256 _dealId = stake.dealId;
        require(stake.staker == msg.sender, "Must Staker.");

        if(!closeAll) {
            require(!(checkDealStatus(_dealId, DealStatus.Delivering) && checkDealStatus(_dealId, DealStatus.Claiming)), "Wrong Status.");
        }
        
        DealInfo storage deal = dealInfo[_dealId];
        uint256 _amount = stake.amount;
        stake.amount = 0;
        deal.totalStaked = deal.totalStaked.sub(_amount);
        IERC20(deal.stakingToken).transfer(msg.sender, _amount);

        emit Withdraw(_stakeId, _amount, msg.sender);
    }

    function claim(
        uint256 _dealId
    ) external {
        require(!closeAll, "Closed.");
        require(checkDealStatus(_dealId, DealStatus.Claiming), "Wrong Status.");
        DealInfo storage deal = dealInfo[_dealId];
        require(deal.sponsor == msg.sender, "Must Sponsor.");
        deal.status = DealStatus.Closed;
        
        uint256[] memory stakeIds = deal.stakeIds;
        uint256 claimAmount;
        
        for(uint256 i=0; i<stakeIds.length; i++) {
            StakeInfo storage stake = stakeInfo[stakeIds[i]];
            
            if(!stake.isClaimed) {
                claimAmount = claimAmount.add(stake.amount);
                stake.isClaimed = true;

                if(claimAmount > deal.amount.maxSale) {
                    uint256 diffAmount = claimAmount.sub(deal.amount.maxSale);
                    stake.restAmount = diffAmount;
                    stake.amount = stake.amount.sub(diffAmount);
                    claimAmount = deal.amount.maxSale;
                    break;
                } else {
                    stake.amount = 0;
                }
            }
        }
        
        deal.totalStaked = deal.totalStaked.sub(claimAmount);
        IERC20(deal.stakingToken).transfer(msg.sender, claimAmount);

        emit Claim(_dealId, claimAmount, msg.sender);
    }

    function sendBack(
        uint256 _stakeId
    ) external {
        StakeInfo storage stake = stakeInfo[_stakeId];
        DealInfo storage deal = dealInfo[stake.dealId];
        require(deal.sponsor == msg.sender || owner() == msg.sender, "No Permission.");

        if(!closeAll) {
            require(deal.status == DealStatus.Closed, "Wrong Status.");
        }
        
        uint256 _amount = stake.amount;
        stake.amount = 0;
        deal.totalStaked = deal.totalStaked.sub(_amount);
        IERC20(deal.stakingToken).transfer(stake.staker, _amount);
    }

    function getDealIds(DisplayStatus _displayStatus, DealStatus _dealStatus) external view returns(uint256[] memory) {
        uint256[] memory filterDealIds = new uint256[](dealIds.length);
        uint256 index = 0;
        
        if(_displayStatus == DisplayStatus.All) {
            return dealIds;
        } else {
            for(uint256 id=1; id<=dealIds.length; id++) {
                DealInfo memory deal = dealInfo[id];
                if(_displayStatus == DisplayStatus.List) {
                    if(deal.status != DealStatus.NotDisplaying && deal.status != DealStatus.Closed) {
                        filterDealIds[index] = id;
                        index ++;
                    } 
                } else if(_displayStatus == DisplayStatus.Item) {
                    if(deal.status == _dealStatus) {
                        filterDealIds[index] = id;
                        index ++;
                    } 
                }
            }
        }

        uint256[] memory tmp = new uint256[](index);
        for(uint256 i=0; i<index; i++) {
            tmp[i] = filterDealIds[i];
        }
        return tmp;
    } 

    function addAllowedToken(address _token) external onlyOwner {
        allowedTokenList[_token] = true;
    }

    function toggleClose() external onlyOwner {
        closeAll = !closeAll;
    }

    function getStakeIds (uint256 _dealId) external view returns(uint256 [] memory) {
        DealInfo memory deal = dealInfo[_dealId];
        return deal.stakeIds;
    }
    
    function getInvetorStakes (address _investor) external view returns(uint256 [] memory) {
        return stakesByInvestor[_investor];
    }
    
    function getSponsorDeals (address _sponsor) external view returns(uint256 [] memory) {
        return dealsBySponsor[_sponsor];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}