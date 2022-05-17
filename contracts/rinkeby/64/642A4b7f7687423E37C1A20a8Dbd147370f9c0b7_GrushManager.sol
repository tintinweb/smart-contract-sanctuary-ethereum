/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// File @openzeppelin/contracts/utils/math/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

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
// File @openzeppelin/contracts/access/[email protected]

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

contract RewardPool is Ownable {
    using SafeMath for uint256;

    address public token;

	mapping(address => bool) public managers;

    modifier onlyManager() {
        require(managers[msg.sender] == true, "Only managers can call this function");
        _;
    }

    constructor () {
		managers[msg.sender] = true;
    }

	function addManager(address manager) external onlyOwner {
		managers[manager] = true;
	}

	function removeManager(address manager) external onlyOwner {
		managers[manager] = false;
	}

    function setTokenAddress(address _address) external onlyOwner {
        require(_address != address(0), "Zero Address");
        token = _address;
    }

    function rewardTo(address _account, uint256 _rewardAmount) external onlyManager {
        require(IERC20(token).balanceOf(address(this)) > _rewardAmount, "Insufficient Balance");
        IERC20(token).transfer(_account, _rewardAmount);
    }

    function withdrawToken(address _account) external onlyManager {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require (balance > 0, "Insufficient Balance");
        IERC20(token).transfer(_account, balance);
    }
}

contract GrushManager {
    using SafeMath for uint256;

    struct Digger {
        string name; 
        uint lastClaimTime;
        uint creationDate;
        uint rewardRate;
        uint level;
    }

    IERC20 public token; 
    address owner;

    uint256 public totalDiggers;
    uint public maxDiggersPerUser;

    // uint claimFee = 1*10**18;
    
    mapping(address => Digger[]) public diggersOwned;
    mapping(address => uint) public totalClaimed;
    mapping(address => bool) public blacklist;

    // CHANGE THIS 
    address private TREASURY;
    address private REWARDS; 
    address private LIQUIDITY;
    address private PROJECT_DEVELOPMENT = 0x43db4fc2e4ed1B10A7d18F7DA503042Ed129E7fA;

    event DiggerCreated(address indexed _owner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner can Access!");
        _;
    }
    modifier NotBlacklist() {
        require(blacklist[msg.sender] == false, "You are BlackListed!");
        _;
    }

    constructor(address _token) {
        token = IERC20(_token);
        owner = msg.sender;
    }

    function addBlacklist(address _user) external onlyOwner {
        blacklist[_user] = true;
    }
    function removeBlacklist(address _user) external onlyOwner {
        blacklist[_user] = false;
    }

    // CREATE DIGGER
    function createArgonautDigger() external NotBlacklist {
        require(diggersOwned[msg.sender].length < maxDiggersPerUser, "You have reached the maximum amount of diggers!");
        require(msg.sender != TREASURY && msg.sender != REWARDS, "Treasury and Reward pools cannot create diggers!");
        // require(token.balanceOf(msg.sender) >= costPerDigger, "Not enough tokens to create Digger!");
        uint _cost = 110*1e18;
        token.transferFrom(msg.sender, address(this), _cost);
        buyingFees(_cost);
        Digger memory newDigger = Digger("Argonaut", block.timestamp, block.timestamp, 2.21*1e18, 0);
        diggersOwned[msg.sender].push(newDigger);
        totalDiggers++;
        emit DiggerCreated(msg.sender);
    }
    function createApacheDigger() external NotBlacklist {
        require(diggersOwned[msg.sender].length < maxDiggersPerUser, "You have reached the maximum amount of diggers!");
        require(msg.sender != TREASURY && msg.sender != REWARDS, "Treasury and Reward pools cannot create diggers!");
        // require(token.balanceOf(msg.sender) >= costPerDigger, "Not enough tokens to create Digger!");
        uint _cost = 50*1e18;
        token.transferFrom(msg.sender, address(this), _cost);
        buyingFees(_cost);
        Digger memory newDigger = Digger("Apache", block.timestamp, block.timestamp, 0.96*1e18, 0);
        diggersOwned[msg.sender].push(newDigger);
        totalDiggers++;
        emit DiggerCreated(msg.sender);
    }
    function createTraperDigger() external NotBlacklist {
        require(diggersOwned[msg.sender].length < maxDiggersPerUser, "You have reached the maximum amount of diggers!");
        require(msg.sender != TREASURY && msg.sender != REWARDS, "Treasury and Reward pools cannot create diggers!");
        // require(token.balanceOf(msg.sender) >= costPerDigger, "Not enough tokens to create Digger!");
        uint _cost = 24*1e18;
        token.transferFrom(msg.sender, address(this), _cost);
        buyingFees(_cost);
        Digger memory newDigger = Digger("Traper", block.timestamp, block.timestamp, 0.44*1e18, 0);
        diggersOwned[msg.sender].push(newDigger);
        totalDiggers++;
        emit DiggerCreated(msg.sender);
    }
    function createJaneDigger() external NotBlacklist {
        require(diggersOwned[msg.sender].length < maxDiggersPerUser, "You have reached the maximum amount of diggers!");
        require(msg.sender != TREASURY && msg.sender != REWARDS, "Treasury and Reward pools cannot create diggers!");
        // require(token.balanceOf(msg.sender) >= costPerDigger, "Not enough tokens to create Digger!");
        uint _cost = 12*1e18;
        token.transferFrom(msg.sender, address(this), _cost);
        buyingFees(_cost);
        Digger memory newDigger = Digger("Jane", block.timestamp, block.timestamp, 0.21*1e18, 0);
        diggersOwned[msg.sender].push(newDigger);
        totalDiggers++;
        emit DiggerCreated(msg.sender);
    }
    function createFallenBankerDigger() external NotBlacklist {
        require(diggersOwned[msg.sender].length < maxDiggersPerUser, "You have reached the maximum amount of diggers!");
        require(msg.sender != TREASURY && msg.sender != REWARDS, "Treasury and Reward pools cannot create diggers!");
        // require(token.balanceOf(msg.sender) >= costPerDigger, "Not enough tokens to create Digger!");
        uint _cost = 6*1e18;
        token.transferFrom(msg.sender, address(this), _cost);
        buyingFees(_cost);
        Digger memory newDigger = Digger("FallenBanker", block.timestamp, block.timestamp, 0.1*1e18, 0);
        diggersOwned[msg.sender].push(newDigger);
        totalDiggers++;
        emit DiggerCreated(msg.sender);
    }

    // Buying Fees
    function buyingFees(uint _cost) internal {
        uint _development = _cost * 23 / 100;
        uint _liquidity = _cost * 10 / 100;
        uint _reward = _cost * 67 / 100;
        token.transfer(LIQUIDITY, _liquidity);  
        token.transfer(REWARDS, _reward); 
        token.transfer(PROJECT_DEVELOPMENT, _development);
    }

    // Rewards
    function calculateRewards(address _user) public view returns(uint) {
        require(diggersOwned[_user].length > 0, "You own no diggers!");
        uint _totalRewards = 0;
        for (uint i=0; i<diggersOwned[_user].length; i++) {
            uint epochsPassed = (block.timestamp - diggersOwned[_user][i].lastClaimTime) / 1 days;
            _totalRewards += epochsPassed * diggersOwned[_user][i].rewardRate;
        }
        return _totalRewards;
    }
    // Claim Fee
    // function calculateClaimFee(address _user) internal view returns(uint) {
    //     uint _totalFee = 0;
    //     for (uint i=0; i<diggersOwned[_user].length; i++) {
    //         uint epochsPassed = (block.timestamp - diggersOwned[_user][i].lastClaimTime) / 1 days;
    //         if(epochsPassed > 0) _totalFee += claimFee;
    //     }
    //     return _totalFee;
    // }

    // Claim
    function claimRewards() external NotBlacklist {
        uint _rewards = calculateRewards(msg.sender);
        // uint _claimFees = calculateClaimFee(msg.sender);
        // require(token.balanceOf(msg.sender) >= _claimFees, "You don't have enough Tokens for Claim Fee!");
        RewardPool(REWARDS).rewardTo(msg.sender, _rewards);
        // token.transferFrom(msg.sender, PROJECT_DEVELOPMENT, _claimFees);
        token.transfer(msg.sender, _rewards);
        // Set new Claim Time
        for (uint i=0; i<diggersOwned[msg.sender].length; i++) {
            diggersOwned[msg.sender][i].lastClaimTime = block.timestamp;
        }
        totalClaimed[msg.sender] += _rewards;
    }

    // level up the digger as well as his reward rate
    function levelUpDigger(address _user, uint _diggerOwnedID) external NotBlacklist {
        require (diggersOwned[_user][_diggerOwnedID].level < 3, "Digger already at Max Level!");
        if (keccak256(bytes(diggersOwned[_user][_diggerOwnedID].name)) == keccak256(bytes("Argonaut"))) {
            if (diggersOwned[_user][_diggerOwnedID].level == 0) {
                uint _cost = 15*1e18;
                token.transferFrom(msg.sender, address(this), _cost);
                buyingFees(_cost);
                diggersOwned[_user][_diggerOwnedID].level++;
                diggersOwned[_user][_diggerOwnedID].rewardRate = 2.56*1e18; 
            }
            else if (diggersOwned[_user][_diggerOwnedID].level == 1) {
                uint _cost = 20*1e18;
                token.transferFrom(msg.sender, address(this), _cost);
                buyingFees(_cost);
                diggersOwned[_user][_diggerOwnedID].level++;
                diggersOwned[_user][_diggerOwnedID].rewardRate = 3.06*1e18; 
            }
            if (diggersOwned[_user][_diggerOwnedID].level == 2) {
                uint _cost = 30*1e18;
                token.transferFrom(msg.sender, address(this), _cost);
                buyingFees(_cost);
                diggersOwned[_user][_diggerOwnedID].level++;
                diggersOwned[_user][_diggerOwnedID].rewardRate = 3.84*1e18; 
            }
        }
        
    }


    // SETTERS
    function setMaxDiggersPerUser(uint _max) external onlyOwner {
        maxDiggersPerUser = _max;
    }
    // function setClaimFee(uint _claimFee) external onlyOwner {
    //     claimFee = _claimFee;
    // }
    function setRewardsAddress(address _address) external onlyOwner {
        REWARDS = _address;
    }
    function setLiquidityAddress(address _address) external onlyOwner {
        LIQUIDITY = _address;
    }
    function setTreasuryAddress(address _address) external onlyOwner {
        TREASURY = _address;
    }
    function setDevelopmentCostAddress(address _address) external onlyOwner {
        PROJECT_DEVELOPMENT = _address;
    }

    // GETTERS
    function getOwnedDiggersInfo(address _user) external view returns (Digger[] memory){
        return diggersOwned[_user];
    }

    // Recover tokens that were accidentally sent to this address 
    function recoverTokens(IERC20 _erc20, address _to) public onlyOwner {
        require(address(_erc20) != address(token), "You can't recover default token");
        uint256 _balance = _erc20.balanceOf(address(this));
        _erc20.transfer(_to, _balance);
    }

    // Withdraw Reward Pool
    function withdrawRewardPool() external onlyOwner() {
        RewardPool(REWARDS).withdrawToken(address(this));
    }

}