/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0;

pragma solidity 0.8;
 
/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
 
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
 
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
 
contract ERC20 is Context,IERC20{
    mapping(address => uint256) private _balances;
 
    mapping(address => mapping(address => uint256)) private _allowances;
 
    uint256 private _totalSupply;
 
    string private _name;
    string private _symbol;
 
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
 
    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }
 
    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
 
    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }
 
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
 
    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
 
    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
 
    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
 
    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
 
    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
 
        _transfer(sender, recipient, amount);
 
        return true;
    }
 
    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
 
    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
 
        return true;
    }
 
    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
 
        _beforeTokenTransfer(sender, recipient, amount);
 
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
 
        emit Transfer(sender, recipient, amount);
 
        _afterTokenTransfer(sender, recipient, amount);
    }
 
    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
 
        _beforeTokenTransfer(address(0), account, amount);
 
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
 
        _afterTokenTransfer(address(0), account, amount);
    }
 
    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
 
        _beforeTokenTransfer(account, address(0), amount);
 
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
 
        emit Transfer(account, address(0), amount);
 
        _afterTokenTransfer(account, address(0), amount);
    }
 
    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
 
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
 
    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
 
    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}
 
interface IRebase {
    function totalSupply() external view returns(uint);
} 

contract MRTEST is ERC20 {
 
    constructor (string memory name, string memory symbol) ERC20(name, symbol) {
  //  uint256 public constant decimals = 18;
    uint TotalTokenSupply=60000000000000000000000000;
        _mint(msg.sender, TotalTokenSupply);
    }
}


contract MoonRabbitCryptoPrediction {

    address public owner;
    MRTEST public token_address;
    address rebaseCaller;
    uint256 public poolId ;
    uint256 public rebaseSessionId;
    uint256 lastpoolcreated;
    uint256 public lastRebaseCreated;
    uint256 public lastTotalSupply;
    address public megaPool;


    struct Pool{
        uint[15] prices; // TokenIndex to CurrentPrice 
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

    struct User {
        string user_name;
        bool isActive;
        mapping(uint => bool) participatedPools;
        mapping(uint => mapping(uint => bool)) betInPool; // Poolid to TokenIndex to Bool
        mapping(uint => mapping(uint => uint)) bettedAmount; //Poolid to Tokenindex to Amount 
        mapping(uint => mapping(uint => uint)) tokenPriceAtBet; //Poolid to Tokenindex to Price
        mapping(uint => bool) isClaimedReward; //Poolid to Bool
        mapping(uint => uint) stakedAmountInPool; // Poolid to Amount
        uint tokenBalance;
        uint claimableReward;
        uint total_pool_counter;
        uint total_staked;
    }

    mapping(uint => Pool) public betPool;
    mapping(address => User) public user;
    mapping(uint => Rebase) public rebaseTracer;
    mapping(uint => uint)  isRebaseNegative;

    constructor(address token_address_,address megaPool_) {
        owner = msg.sender;
        token_address = MRTEST(token_address_);
        megaPool = megaPool_;
    }
    
    function Register(string memory user_name_) public returns(bool) {
        user[msg.sender].user_name = user_name_;
        user[msg.sender].isActive = true;
        user[msg.sender].tokenBalance = token_address.balanceOf(msg.sender);

        return true;
    }

    function createPool(uint[15] memory prices_) public returns(bool) {
        lastpoolcreated = block.timestamp;
        betPool[poolId].prices = prices_;
        betPool[poolId].startime = block.timestamp;
        betPool[poolId].stakingends = block.timestamp + 2 minutes;
        betPool[poolId].endtime = block.timestamp + 5 minutes;
        poolId += 1;

        return true;
    }

    function PlaceBet(uint256 index,uint256 _prices,uint256 _poolId,uint256 _amount) public returns(bool) {
        user[msg.sender].participatedPools[_poolId] = true;
        user[msg.sender].betInPool[_poolId][index] = true;
        user[msg.sender].bettedAmount[_poolId][index] = _amount;
        user[msg.sender].tokenPriceAtBet[_poolId][index] = _prices;
        user[msg.sender].tokenBalance -= _amount;
        user[msg.sender].stakedAmountInPool[poolId] += _amount;
        user[msg.sender].total_pool_counter += 1;
        user[msg.sender].total_staked += _amount;
        token_address.transferFrom(msg.sender,address(this),_amount);

        return true;
    }

    function setRebaseCaller(address _setRebaseCaller) public returns(bool) {
        rebaseCaller = _setRebaseCaller;

        return true;
    }

    function createRebaseSession() public returns(bool) {
        uint temp = rebaseTracer[rebaseSessionId].numberOfNegativeDates;
        if(temp >= 15) {
            uint temp_ = token_address.balanceOf(address(this));
            token_address.transfer(megaPool,temp_);
        }
        lastRebaseCreated = block.timestamp;
        rebaseTracer[rebaseSessionId].createdTime = block.timestamp;
        rebaseTracer[rebaseSessionId].endingTime = block.timestamp + 30 minutes;
        rebaseSessionId += 1;

        return true;
    }

    function setRebaseStatus() public returns (uint) {
        require(msg.sender == owner, "Not Owner");
        uint tempStatus_ = IRebase(rebaseCaller).totalSupply();
        uint status_;
        if(tempStatus_ > lastTotalSupply) {
            status_ = 1;
            isRebaseNegative[poolId] = 1;
        } else if(tempStatus_ == lastTotalSupply) {
            status_ = 2;
            isRebaseNegative[poolId] = 2;           
        } else {
            status_ = 3;
            isRebaseNegative[poolId] = 3;
        }
        lastTotalSupply = tempStatus_;
        rebaseTracer[rebaseSessionId].NumberOfOccurances += 1;
        if(status_ == 3){
            rebaseTracer[rebaseSessionId].numberOfNegativeDates += 1;
        }
        return status_;
    }

    function updatebal(address _user,uint256 _poolId,uint256 _reward,bool _isPositive) public returns(bool){
        uint rstatus_ = isRebaseNegative[poolId];
        uint staked_ = user[_user].stakedAmountInPool[_poolId];
        if(_isPositive) {
            if(rstatus_ == 1) {
                uint reward_percentage = _reward / 10 ** 5; 
                uint final_reward_calculation_temp = staked_ * reward_percentage;
                uint final_reward = staked_ + final_reward_calculation_temp;
                uint final_calculated_reward = final_reward / 10 ** 3;
                uint temp = final_calculated_reward*12;
                uint pout_ = temp + _reward;
                user[_user].claimableReward += pout_/1e2;
                user[_user].isClaimedReward[_poolId] = true;
            } else if(rstatus_ == 3) {
                uint reward_percentage = _reward / 10 ** 5; 
                uint final_reward_calculation_temp = staked_ * reward_percentage;
                uint final_reward = staked_ + final_reward_calculation_temp;
                uint final_calculated_reward = final_reward / 10 ** 3;
                uint temp = final_calculated_reward*12;
                uint pout_ = temp - _reward;
                user[_user].claimableReward += pout_/1e2;
                user[_user].isClaimedReward[_poolId] = true;
            } else {
                uint reward_percentage = _reward / 10 ** 5; 
                uint final_reward_calculation_temp = staked_ * reward_percentage;
                uint final_reward = staked_ + final_reward_calculation_temp;
                uint final_calculated_reward = final_reward / 10 ** 3;
                user[_user].claimableReward += final_calculated_reward;
                user[_user].isClaimedReward[_poolId] = true;
            }
        } else {
                if(rstatus_ == 1 || rstatus_ == 3) {
                    uint reward_percentage = _reward / 10 ** 5; 
                    uint final_reward_calculation_temp = staked_ * reward_percentage;
                    uint final_reward = staked_ - final_reward_calculation_temp;
                    uint final_calculated_reward = final_reward / 10 ** 3;
                    uint temp = final_calculated_reward*12;
                    uint pout_ = temp - _reward;
                    user[_user].claimableReward += pout_/1e2;
                    user[_user].isClaimedReward[_poolId] = true;
                } else {
                    uint reward_percentage = _reward / 10 ** 5; 
                    uint final_reward_calculation_temp = staked_ * reward_percentage;
                    uint final_reward = staked_ - final_reward_calculation_temp;
                    uint final_calculated_reward = final_reward / 10 ** 3;
                    user[_user].claimableReward += final_calculated_reward;
                    user[_user].isClaimedReward[_poolId] = true;
                }
        }

        return true;
    }

    function withdrawReward() public returns(bool) {
        uint temp = user[msg.sender].claimableReward;
        token_address.transfer(msg.sender,temp);

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
        uint temp_ = IERC20(megaPool).balanceOf(megaPool);
        address winner_ = rebaseTracer[rebasePoolId_].winner;
        IERC20(megaPool).transferFrom(megaPool,winner_,temp_);

        return winner_;
    }

    function fetchPoolDetails(uint poolId_) public view returns(uint256[15] memory _prices,uint256 _start,uint256 _end,uint256 _staking_ends) {
        Pool storage b = betPool[poolId_];

        return(b.prices,b.startime,b.endtime,b.stakingends);
    }

    function fetchUserBets(uint poolId_,address _user,uint tokenIndex_) public view returns(bool) {
        User storage u = user[_user];
        
        return (u.betInPool[poolId_][tokenIndex_]);
    }

    function fetchUserStaked(uint poolId_,address _user) public view returns(uint) {
        User storage u = user[_user];

        return u.stakedAmountInPool[poolId_];

    }

    function fetchRebasePool(uint _rebasePoolId) public view returns( uint _NumberOfOccurances, uint _numberOfNegativeDates, uint _createdTime, uint _endingTime) {
        Rebase storage r = rebaseTracer[_rebasePoolId];

        return(r.NumberOfOccurances, r.numberOfNegativeDates, r.createdTime, r.endingTime);        
    }

    function fetchUser(address _user) public view returns(uint total_pool_counter_,string memory username,uint256 claimable,uint256 staked_balance, bool active) {
        User storage us = user[_user];

        return(us.total_pool_counter,us.user_name,us.claimableReward,us.total_staked,us.isActive);        
    }

}