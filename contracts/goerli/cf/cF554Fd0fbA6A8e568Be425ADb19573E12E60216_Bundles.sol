// SPDX-License-Identifier: UNLICENSED

pragma solidity <=0.7.5;

import "../TokenMintERC20Token.sol";

interface IRebase {
   function totalSupply() external view returns(uint);
}

contract Bundles {
   uint256 public bundleId = 1;
   uint256 public rebaseSessionId = 1;
   address public owner;
   TokenMintERC20Token public bundle_address;

   uint256 public lastcreated;
   uint256 lastbundlecreated;
   uint public lastRebaseSessionCreated;

   uint256 public lastTotalSupply;
   address public megaPool;
   address public rebaseCaller;

   uint256 bundleDuration;
   uint256 bundleStakeDuration;

   struct UserPredictions{
       uint256[14] bundles;
       uint256[14] amounts;
       uint256[14] prices;
       bool predicted;
       uint256 balance;
       uint256 totalPredicted;
       bool claimed;
   }

   struct User{
       uint256[] bundles;
       string username;
       uint256 balance;
       uint256 freebal;
       bool active;
   }

   struct Bundle{
       uint256[14] prices;
       uint256 startime;
       uint256 stakingends;
       uint256 endtime;
   }

   struct Rebase {
       uint NumberOfOccurances;
       uint numberOfNegativeDates;
       uint createdTime;
       uint endingTime;
       mapping(uint => address) poolWinners;
       mapping(address => bool) poolWinnersWhitelistingStatus;
       uint user_counter;
       address winner;
   }

   mapping(address => mapping(uint256 => UserPredictions)) predictions;
   mapping(uint256 => Bundle) bundle;
   mapping(address => User) user;
   mapping(uint => Rebase) public rebaseTracer;
   mapping(uint => uint)  isRebaseNegative;

   constructor(address _bundle_address,address _mega_pool, address _rebase_caller) public {
       owner = msg.sender;
       bundle_address = TokenMintERC20Token(_bundle_address);
       lastcreated = block.timestamp;
       megaPool = _mega_pool;
       rebaseCaller = _rebase_caller;
   }

   function registrationStatus() public view returns(bool) {
       bool status_;
       User storage us = user[msg.sender];
       if(us.active) {
           status_ = true;
       } else {
           status_ = false;
       }
       return status_;
   }

   function Register(string memory _username) public returns(bool) {
       User storage us = user[msg.sender];
       require(us.active == false, "Existing User");
       us.active = true;
       us.username = _username;
       return true;
   }

   function isOwner() public view returns(bool) {
       bool status_;
       if(msg.sender == owner) {
           status_ = true;
       } else {
           status_ = false;
       }
       return status_;
   }

    function setBundleDuratuionAndStakePeriod(uint256 bundleStakeDuration_, uint256 bundleDuration_) external {
        require(msg.sender == owner, "Not owner");
        require(bundleStakeDuration_ < bundleDuration_, "Invalid values");

        bundleStakeDuration = bundleStakeDuration_;
        bundleDuration = bundleDuration_;
    }

   function setRebaseStatus() public returns (uint) {
       require(msg.sender == owner, "Not Owner");
       uint tempStatus_ = IRebase(rebaseCaller).totalSupply();
       uint status_;
       if(tempStatus_ > lastTotalSupply) {
           status_ = 1;
           isRebaseNegative[bundleId] = 1;
       } else if(tempStatus_ == lastTotalSupply) {
           status_ = 2;
           isRebaseNegative[bundleId] = 2;
       } else {
           status_ = 3;
           isRebaseNegative[bundleId] = 3;
       }
       lastTotalSupply = tempStatus_;
       rebaseTracer[rebaseSessionId].NumberOfOccurances += 1;
       if(status_ == 3){
           rebaseTracer[rebaseSessionId].numberOfNegativeDates += 1;
       }
       return status_;
   }

   function placePrediction(uint256 index,uint256 _prices,uint256 _percent,uint256 _bundleId,uint256 _amount) public returns(bool) {
       require(_bundleId <= bundleId, "Invalid Bundle");
       require(bundle_address.allowance(msg.sender,address(this))>=_amount, "Approval failed");
       Bundle storage b = bundle[_bundleId];
       require(b.stakingends >= block.timestamp, "Ended");
       User storage us = user[msg.sender];
       require(us.active == true, "Register to participate");
       UserPredictions storage u = predictions[msg.sender][_bundleId];
       require(u.bundles[index] == 0, "Already predicted");
       if(u.predicted == false){
           u.balance = bundle_address.balanceOf(msg.sender);
           u.predicted = true;
       }
       else{
           require(SafeMath.add(u.totalPredicted,_amount) <= u.balance, "Threshold Reached");
       }
       us.bundles.push(_bundleId);
       us.balance = SafeMath.add(us.balance,_amount);
       u.bundles[index] = _percent;
       u.prices[index] = _prices;
       u.amounts[index] = _amount;
       u.totalPredicted = u.totalPredicted + _amount;
       bundle_address.transferFrom(msg.sender,address(this),_amount);
       return true;
   }

   function updatebal(address _user, uint256 _bundleId, uint256 _reward, bool _isPositive) public returns (bool) {
       require(msg.sender == owner, "Not Owner");
       require(_reward <= 120000, "Invalid Reward Percent");
       User storage us = user[_user];
       require(us.active == true, "Invalid User");
       UserPredictions storage u = predictions[_user][_bundleId];
       require(u.claimed == false, "Already Claimed");
       uint256 a = SafeMath.mul(u.totalPredicted,_reward);
       uint256 b = SafeMath.div(a,10**6);
       if(_isPositive == true){
           uint256 c = SafeMath.add(u.totalPredicted,b);
           u.claimed = true;
           us.freebal = SafeMath.add(c,us.freebal);
           uint temp_1 = rebaseReward(_bundleId,us.freebal,_isPositive);
           us.freebal = temp_1;
           us.balance = SafeMath.sub(us.balance,u.totalPredicted);
       }
       else{
           uint256 c = SafeMath.sub(u.totalPredicted,b);
           u.claimed = true;
           us.freebal = SafeMath.add(c,us.freebal);
           uint temp_1 = rebaseReward(_bundleId,us.freebal,_isPositive);
           us.freebal = temp_1;
           us.balance = SafeMath.sub(us.balance,u.totalPredicted);
       }
       return true;
   }

   function rebaseReward(uint256 _poolId,uint _performance_reward,bool _performance_flag) public view returns(uint256) {
       require(msg.sender == owner, "Not Owner");
       uint rstatus_ = isRebaseNegative[_poolId];
       uint calculated_temp;
       if(rstatus_ == 1) {
           if(_performance_flag) {
               uint temp_1 = _performance_reward * 12;
               uint temp_2 = temp_1 / 1e2;
               calculated_temp = _performance_reward + temp_2;
           } else {
               uint temp_1 = _performance_reward * 12;
               uint temp_2 = temp_1 / 1e2;
               calculated_temp = _performance_reward - temp_2;
           }
       } else if(rstatus_ == 3) {
               uint temp_1 = _performance_reward * 12;
               uint temp_2 = temp_1 / 1e2;
               calculated_temp = _performance_reward - temp_2;
       } else {
           calculated_temp = _performance_reward;
       }

       return (calculated_temp);
   }

   function createBundle(uint256[14] memory _prices) public {
       require(msg.sender == owner, "Not owner");
       require(block.timestamp >= bundle[bundleId - 1].endtime, "Cannot Create");

       Bundle storage b = bundle[bundleId];
       b.prices = _prices;
       b.startime = block.timestamp;
       lastbundlecreated = block.timestamp;
       lastcreated = block.timestamp;
       b.endtime = SafeMath.add(block.timestamp, bundleDuration);
       b.stakingends = SafeMath.add(block.timestamp, bundleStakeDuration);
       bundleId = SafeMath.add(bundleId,1);
   }

   function updateowner(address new_owner) public returns(bool){
       require(msg.sender == owner, "Not an Owner");
       owner = new_owner;
       return true;
   }

   function updatetime(uint256 _timestamp) public returns(bool){
       require(msg.sender == owner, "Not an owner");
       lastcreated =  _timestamp;
   }

   event LastSessionData(uint);

   function createRebaseSession() public returns(bool) {
       uint temp = rebaseTracer[rebaseSessionId].numberOfNegativeDates;
       if(temp >= 5) {
           uint temp_ = IERC20(bundle_address).balanceOf(address(this));
           IERC20(bundle_address).transfer(megaPool,temp_);
       }
       lastRebaseSessionCreated = block.timestamp;
       rebaseTracer[rebaseSessionId].createdTime = block.timestamp;
       rebaseTracer[rebaseSessionId].endingTime = block.timestamp + 30 minutes;
       rebaseSessionId += 1;
       emit LastSessionData(temp);

       return true;
   }

   function participateForMegaPool(uint rebasePoolId_) public returns(bool) {
       uint temp = rebaseTracer[rebasePoolId_].user_counter;
       rebaseTracer[rebasePoolId_].poolWinners[temp] = msg.sender;
       rebaseTracer[rebasePoolId_].poolWinnersWhitelistingStatus[msg.sender] = true;
       rebaseTracer[rebasePoolId_].user_counter += 1;

       return true;
   }

   function guessWinnerFromMegaPool(uint rebasePoolId_) public returns (address) {
       uint _id = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)))%rebaseTracer[rebasePoolId_].user_counter;

       rebaseTracer[rebasePoolId_].winner = rebaseTracer[rebasePoolId_].poolWinners[_id];
       uint temp_ = IERC20(bundle_address).balanceOf(megaPool);
       address winner_ = rebaseTracer[rebasePoolId_].winner;
       IERC20(bundle_address).transferFrom(megaPool,winner_,temp_);

       return winner_;
   }

    function withdraw() external {
        uint256 bal_ = user[msg.sender].freebal;
        require(bal_ > 0, "No bal");
        require(user[msg.sender].active, "Invalid user");

        user[msg.sender].freebal = 0;
        bundle_address.transfer(msg.sender, bal_);
    }

   function fetchUser(address _user) public view returns(uint256[] memory _bundles,string memory username,uint256 claimable,uint256 staked_balance, bool active){
       User storage us = user[_user];
       return(us.bundles,us.username,us.freebal,us.balance,us.active);
   }

   function fetchBundle(uint256 _bundleId) public view returns(uint256[14] memory _prices,uint256 _start,uint256 _end,uint256 _staking_ends){
       Bundle storage b = bundle[_bundleId];
       return(b.prices,b.startime,b.endtime,b.stakingends);
   }

   function fetchUserPredictions(address _user, uint256 _bundleId) public view returns(uint256[14] memory _bundles,uint256[14] memory _prices,uint256[14] memory _amounts,uint256 balance,uint256 totalPredicted){
       UserPredictions storage u = predictions[_user][_bundleId];
       return (u.bundles,u.prices,u.amounts,u.balance,u.totalPredicted);
   }

   function drain() public returns(bool,uint256){
       require(msg.sender == owner, "Not Owner");
       uint256 amount = bundle_address.balanceOf(address(this));
       bundle_address.transfer(msg.sender,amount);
       return(true,amount);
   }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.5.0;

import "./ERC20.sol";

/**
* @title TokenMintERC20Token
* @author TokenMint (visit https://tokenmint.io)
*
* @dev Standard ERC20 token with burning and optional functions implemented.
* For full specification of ERC-20 standard see:
* https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
*/
contract TokenMintERC20Token is ERC20 {

   string private _name;
   string private _symbol;
   uint8 private _decimals;

   /**
    * @dev Constructor.
    * @param name name of the token
    * @param symbol symbol of the token, 3-4 chars is recommended
    * @param decimals number of decimal places of one token unit, 18 is widely used
    * @param totalSupply total supply of tokens in lowest units (depending on decimals)
    * @param tokenOwnerAddress address that gets 100% of token supply
    */
   constructor(string memory name, string memory symbol, uint8 decimals, uint256 totalSupply, address payable feeReceiver, address tokenOwnerAddress) public payable {
       _name = name;
       _symbol = symbol;
       _decimals = decimals;

       // set tokenOwnerAddress as owner of all tokens
       _mint(tokenOwnerAddress, totalSupply);

       // pay the service fee for contract deployment
       feeReceiver.transfer(msg.value);
   }

   /**
    * @dev Burns a specific amount of tokens.
    * @param value The amount of lowest token units to be burned.
    */
   function burn(uint256 value) public {
       _burn(msg.sender, value);
   }

   // optional functions from ERC20 stardard

   /**
    * @return the name of the token.
    */
   function name() public view returns (string memory) {
       return _name;
   }

   /**
    * @return the symbol of the token.
    */
   function symbol() public view returns (string memory) {
       return _symbol;
   }

   /**
    * @return the number of decimals of the token.
    */
   function decimals() public view returns (uint8) {
       return _decimals;
   }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.5.0;

import "./IERC20.sol";
import "./SafeMath.sol";

/**
* @dev Implementation of the `IERC20` interface.
*
* This implementation is agnostic to the way tokens are created. This means
* that a supply mechanism has to be added in a derived contract using `_mint`.
* For a generic mechanism see `ERC20Mintable`.
*
* *For a detailed writeup see our guide [How to implement supply
* mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
*
* We have followed general OpenZeppelin guidelines: functions revert instead
* of returning `false` on failure. This behavior is nonetheless conventional
* and does not conflict with the expectations of ERC20 applications.
*
* Additionally, an `Approval` event is emitted on calls to `transferFrom`.
* This allows applications to reconstruct the allowance for all accounts just
* by listening to said events. Other implementations of the EIP may not emit
* these events, as it isn't required by the specification.
*
* Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
* functions have been added to mitigate the well-known issues around setting
* allowances. See `IERC20.approve`.
*/
contract ERC20 is IERC20 {
   using SafeMath for uint256;

   mapping (address => uint256) private _balances;

   mapping (address => mapping (address => uint256)) private _allowances;

   uint256 private _totalSupply;

   /**
    * @dev See `IERC20.totalSupply`.
    */
   function totalSupply() public view returns (uint256) {
       return _totalSupply;
   }

   /**
    * @dev See `IERC20.balanceOf`.
    */
   function balanceOf(address account) public view returns (uint256) {
       return _balances[account];
   }

   /**
    * @dev See `IERC20.transfer`.
    *
    * Requirements:
    *
    * - `recipient` cannot be the zero address.
    * - the caller must have a balance of at least `amount`.
    */
   function transfer(address recipient, uint256 amount) public returns (bool) {
       _transfer(msg.sender, recipient, amount);
       return true;
   }

   /**
    * @dev See `IERC20.allowance`.
    */
   function allowance(address owner, address spender) public view returns (uint256) {
       return _allowances[owner][spender];
   }

   /**
    * @dev See `IERC20.approve`.
    *
    * Requirements:
    *
    * - `spender` cannot be the zero address.
    */
   function approve(address spender, uint256 value) public returns (bool) {
       _approve(msg.sender, spender, value);
       return true;
   }

   /**
    * @dev See `IERC20.transferFrom`.
    *
    * Emits an `Approval` event indicating the updated allowance. This is not
    * required by the EIP. See the note at the beginning of `ERC20`;
    *
    * Requirements:
    * - `sender` and `recipient` cannot be the zero address.
    * - `sender` must have a balance of at least `value`.
    * - the caller must have allowance for `sender`'s tokens of at least
    * `amount`.
    */
   function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
       _transfer(sender, recipient, amount);
       _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
       return true;
   }

   /**
    * @dev Atomically increases the allowance granted to `spender` by the caller.
    *
    * This is an alternative to `approve` that can be used as a mitigation for
    * problems described in `IERC20.approve`.
    *
    * Emits an `Approval` event indicating the updated allowance.
    *
    * Requirements:
    *
    * - `spender` cannot be the zero address.
    */
   function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
       _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
       return true;
   }

   /**
    * @dev Atomically decreases the allowance granted to `spender` by the caller.
    *
    * This is an alternative to `approve` that can be used as a mitigation for
    * problems described in `IERC20.approve`.
    *
    * Emits an `Approval` event indicating the updated allowance.
    *
    * Requirements:
    *
    * - `spender` cannot be the zero address.
    * - `spender` must have allowance for the caller of at least
    * `subtractedValue`.
    */
   function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
       _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
       return true;
   }

   /**
    * @dev Moves tokens `amount` from `sender` to `recipient`.
    *
    * This is internal function is equivalent to `transfer`, and can be used to
    * e.g. implement automatic token fees, slashing mechanisms, etc.
    *
    * Emits a `Transfer` event.
    *
    * Requirements:
    *
    * - `sender` cannot be the zero address.
    * - `recipient` cannot be the zero address.
    * - `sender` must have a balance of at least `amount`.
    */
   function _transfer(address sender, address recipient, uint256 amount) internal {
       require(sender != address(0), "ERC20: transfer from the zero address");
       require(recipient != address(0), "ERC20: transfer to the zero address");

       _balances[sender] = _balances[sender].sub(amount);
       _balances[recipient] = _balances[recipient].add(amount);
       emit Transfer(sender, recipient, amount);
   }

   /** @dev Creates `amount` tokens and assigns them to `account`, increasing
    * the total supply.
    *
    * Emits a `Transfer` event with `from` set to the zero address.
    *
    * Requirements
    *
    * - `to` cannot be the zero address.
    */
   function _mint(address account, uint256 amount) internal {
       require(account != address(0), "ERC20: mint to the zero address");

       _totalSupply = _totalSupply.add(amount);
       _balances[account] = _balances[account].add(amount);
       emit Transfer(address(0), account, amount);
   }

   /**
   * @dev Destroys `amount` tokens from `account`, reducing the
    * total supply.
    *
    * Emits a `Transfer` event with `to` set to the zero address.
    *
    * Requirements
    *
    * - `account` cannot be the zero address.
    * - `account` must have at least `amount` tokens.
    */
   function _burn(address account, uint256 value) internal {
       require(account != address(0), "ERC20: burn from the zero address");

       _totalSupply = _totalSupply.sub(value);
       _balances[account] = _balances[account].sub(value);
       emit Transfer(account, address(0), value);
   }

   /**
    * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
    *
    * This is internal function is equivalent to `approve`, and can be used to
    * e.g. set automatic allowances for certain subsystems, etc.
    *
    * Emits an `Approval` event.
    *
    * Requirements:
    *
    * - `owner` cannot be the zero address.
    * - `spender` cannot be the zero address.
    */
   function _approve(address owner, address spender, uint256 value) internal {
       require(owner != address(0), "ERC20: approve from the zero address");
       require(spender != address(0), "ERC20: approve to the zero address");

       _allowances[owner][spender] = value;
       emit Approval(owner, spender, value);
   }

   /**
    * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
    * from the caller's allowance.
    *
    * See `_burn` and `_approve`.
    */
   function _burnFrom(address account, uint256 amount) internal {
       _burn(account, amount);
       _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
   }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.5.0;

/**
* @dev Interface of the ERC20 standard as defined in the EIP. Does not include
* the optional functions; to access them see `ERC20Detailed`.
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
    * Emits a `Transfer` event.
    */
   function transfer(address recipient, uint256 amount) external returns (bool);

   /**
    * @dev Returns the remaining number of tokens that `spender` will be
    * allowed to spend on behalf of `owner` through `transferFrom`. This is
    * zero by default.
    *
    * This value changes when `approve` or `transferFrom` are called.
    */
   function allowance(address owner, address spender) external view returns (uint256);

   /**
    * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * > Beware that changing an allowance with this method brings the risk
    * that someone may use both the old and the new allowance by unfortunate
    * transaction ordering. One possible solution to mitigate this race
    * condition is to first reduce the spender's allowance to 0 and set the
    * desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    *
    * Emits an `Approval` event.
    */
   function approve(address spender, uint256 amount) external returns (bool);

   /**
    * @dev Moves `amount` tokens from `sender` to `recipient` using the
    * allowance mechanism. `amount` is then deducted from the caller's
    * allowance.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a `Transfer` event.
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
    * a call to `approve`. `value` is the new allowance.
    */
   event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.5.0;

/**
* @dev Wrappers over Solidity's arithmetic operations with added overflow
* checks.
*
* Arithmetic operations in Solidity wrap on overflow. This can easily result
* in bugs, because programmers usually assume that an overflow raises an
* error, which is the standard behavior in high level programming languages.
* `SafeMath` restores this intuition by reverting the transaction when an
* operation overflows.
*
* Using this library instead of the unchecked operations eliminates an entire
* class of bugs, so it's recommended to use it always.
*/
library SafeMath {
   /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
   function add(uint256 a, uint256 b) internal pure returns (uint256) {
       uint256 c = a + b;
       require(c >= a, "SafeMath: addition overflow");

       return c;
   }

   /**
    * @dev Returns the subtraction of two unsigned integers, reverting on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    * - Subtraction cannot overflow.
    */
   function sub(uint256 a, uint256 b) internal pure returns (uint256) {
       require(b <= a, "SafeMath: subtraction overflow");
       uint256 c = a - b;

       return c;
   }

   /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
   function mul(uint256 a, uint256 b) internal pure returns (uint256) {
       // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
       // benefit is lost if 'b' is also tested.
       // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
       if (a == 0) {
           return 0;
       }

       uint256 c = a * b;
       require(c / a == b, "SafeMath: multiplication overflow");

       return c;
   }

   /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
   function div(uint256 a, uint256 b) internal pure returns (uint256) {
       // Solidity only automatically asserts when dividing by 0
       require(b > 0, "SafeMath: division by zero");
       uint256 c = a / b;
       // assert(a == b * c + a % b); // There is no case in which this doesn't hold

       return c;
   }

   /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
   function mod(uint256 a, uint256 b) internal pure returns (uint256) {
       require(b != 0, "SafeMath: modulo by zero");
       return a % b;
   }
}