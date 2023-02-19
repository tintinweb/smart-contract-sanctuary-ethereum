//ignant.sol
//.___ ._____  .______  .______  .______  _____._
//: __|:_ ___\ :      \ :      \ :      \ \__ _:|
//| : ||   |___|       ||   .   ||       |  |  :|
//|   ||   /  ||   |   ||   :   ||   |   |  |   |
//|   ||. __  ||___|   ||___|   ||___|   |  |   |
//|___| :/ |. |    |___|    |___|    |___|  |___|
//      :   :/                                   
//    
// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


////////////////////////////////////////////////
////////////////////EVENTS/////////////////////
//////////////////////////////////////////////

contract TokenEvents {
    
    //when a user stakes AIG
    event TokenStake(
        address indexed user,
        uint value
    );

    //when a user unstakes AIG
    event TokenUnstake(
        address indexed user,
        uint value
    );
    
    //when a user burns tokens
    event TokenBurn(
        address indexed user,
        uint value
    );
    
}

//////////////////////////////////////
////////// TOKEN CONTRACT////////
////////////////////////////////////
contract IGNANT is IERC20, TokenEvents {

    using SafeMath for uint256;
    using SafeMath for uint64;
    using SafeMath for uint32;
    using SafeMath for uint16;
    using SafeMath for uint8;

    using SafeERC20 for IGNANT;
    
    
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    //stake setup
    address constant AIGADDRESS = 0x6e9513330fe54AD5a793908dFE5676596394534a;
    uint256 constant internal MINUTESECONDS = 60;
    uint256 constant internal DAYSECONDS = 86400;
    uint256 constant internal MINSTAKEDAYLENGTH = 3;
    uint256 internal deploymentTime;
    uint256 public totalStaked;
    
    //tokenomics
    uint256 internal _totalSupply;
    string public constant name = "Ignant";
    string public constant symbol = "IGNANT";
    uint8 public constant decimals = 18;

    //staker
    bool private sync;
    mapping (address => Staker) public staker;
    
    struct Staker{
        uint256 stakedBalance;
        uint256 stakeStartTimestamp;
        uint256 totalStakingInterest;
        uint256 totalBurnt;
    }
    
    //protects against potential reentrancy
    modifier synchronized {
        require(!sync, "Sync lock");
        sync = true;
        _;
        sync = false;
    }

    constructor() {
    deploymentTime = block.timestamp;
    _mint(msg.sender, 100000000000000000000000000000000);
    }
    
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
     
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply unless mintBLock is true
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        uint256 amt = amount;
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amt);
        _balances[account] = _balances[account].add(amt);
        emit Transfer(address(0), account, amt);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    ////////////////////////////////////////////////////////
    /////////////////PUBLIC FACING - IGNANT CONTROL//////////
    //////////////////////////////////////////////////////
    
    
    ////////STAKING FUNCTIONS/////////
    
    //stake AIG tokens to contract and claims any accrued IGNANT interest
    function StakeTokens(uint amt)
        external
        synchronized
    {
        require(amt > 0, "zero input");
        require(IERC20(AIGADDRESS).allowance(msg.sender, address(this)) >= amt, "Error: not approved");//ensure user has approved funds
        require(IERC20(AIGADDRESS).balanceOf(msg.sender) >= amt, "Error: insufficient balance");//ensure user has enough funds
        //claim any accrued interest
        claimInterest();
        //update balances
        staker[msg.sender].stakedBalance = staker[msg.sender].stakedBalance.add(amt);
        totalStaked = totalStaked.add(amt);
        IERC20(AIGADDRESS).transferFrom(msg.sender, address(this), amt);//make transfer
        emit TokenStake(msg.sender, amt);
    }
    
    //unstake AIG tokens from contract and claims any accrued IGNANT interest
    function UnstakeTokens()
        external
        synchronized
    {
        require(staker[msg.sender].stakedBalance > 0,"Error: unsufficient staked balance");//ensure user has enough staked funds
        require(isStakeFinished(msg.sender), "tokens cannot be unstaked yet. min 3 day stake");
        uint amt = staker[msg.sender].stakedBalance;
        //claim any accrued interest
        claimInterest();
        //zero out staking timestamp
        staker[msg.sender].stakeStartTimestamp = 0;
        staker[msg.sender].stakedBalance = 0;
        totalStaked = totalStaked.sub(amt);
        IERC20(AIGADDRESS).transfer(msg.sender, amt);//make transfer
        emit TokenUnstake(msg.sender, amt);
    }
    
    //claim any accrued interest
    function ClaimStakeInterest()
        external
        synchronized
    {
        require(staker[msg.sender].stakedBalance > 0, "you have no staked balance");
        claimInterest();
    }
    
    function claimInterest()
        internal
    {
        //calculate staking interest
        uint256 interest = calcStakingRewards(msg.sender);
        //reset staking timestamp
        staker[msg.sender].stakeStartTimestamp = block.timestamp;
        //mint interest if any
        if(interest > 0){
            _mint(msg.sender, interest);
            staker[msg.sender].totalStakingInterest += interest;
        }
    }

    function BurnIgnant(uint amt)
        external
        synchronized
    {
        require(amt > 0, "value must be greater than 0");
        require(balanceOf(msg.sender) >= amt, "balance too low");
        claimInterest();
        //burn tokens of user
        _burn(msg.sender, amt);
        staker[msg.sender].totalBurnt += amt;
        emit TokenBurn(msg.sender, amt);
    }

    ///////////////////////////////
    ////////VIEW ONLY//////////////
    ///////////////////////////////

    // returns staking rewards in IGNANT based on AIG staked
    function calcStakingRewards(address _user)
        public
        view
        returns(uint)
    {
        // Stake AIG for minimum 10.01% APY paid in IGNANT tokens
        // APY boost adjustments up to a max of 10010% APY via burning of IGNANT.
        // Maximum APY achievable by burning IGNANT diminishes daily for 100 days, from 10,000% to 100% APY.
        uint ignantBurnt = staker[_user].totalBurnt; // Total IGNANT burn
        uint aigStaked = staker[_user].stakedBalance; // Total AIG staked
        uint apyAdjust = 10000; // 10.01% min APY
        uint maxApyAdjust = 10; // 10010% max APY on day 1
        // e.g. day 2 @ ~5000%, day 4 @ ~2500%, day 8 @ ~1250% , day 16 @ ~625%, day 50 @ ~200%, day 75 @ ~133%, day 100 @ ~100%
        uint maxApyAdjustAfterPeriod = 1000;// 100 days after contract deployment, ~100% APY is the highest achievable for all users.

        //has user burnt?
        if(ignantBurnt > 0){
            //has user burnt amount for max APY? 100% of staked balance
            if(ignantBurnt >= aigStaked)
            {
                apyAdjust = maxApyAdjust.add(daysSinceDeployment().mul(10));
                //limit max APY when high inflationary period finished
                if(daysSinceDeployment() >= 100){
                    apyAdjust = maxApyAdjustAfterPeriod;
                }
            }
            else{
                uint burntPercentage = (ignantBurnt.mul(100) / aigStaked);
                uint v = (apyAdjust * burntPercentage) / 100;
                apyAdjust = apyAdjust.sub(v);
                if(apyAdjust < maxApyAdjust.add(daysSinceDeployment().mul(10))){
                    apyAdjust = maxApyAdjust.add(daysSinceDeployment().mul(10));
                    //limit max APY when high inflationary period finished
                    if(daysSinceDeployment() >= 100){
                        apyAdjust = (10000 - v);
                        if(apyAdjust < maxApyAdjustAfterPeriod)
                        {
                            apyAdjust = maxApyAdjustAfterPeriod;
                        }
                    }
                }
            }
        }
        return (aigStaked.mul(minsPastStakeTime(_user)).div(apyAdjust).div(525));
    }

    //returns amount of days elapsed since contract deployment
    function daysSinceDeployment()
        public
        view
        returns(uint)
    {
            return block.timestamp.sub(deploymentTime).div(1 days);
    }

    //returns amount of minutes past since stake start
    function minsPastStakeTime(address _user)
        public
        view
        returns(uint)
    {
        if(staker[_user].stakeStartTimestamp == 0){
            return 0;
        }
        uint minsPast = block.timestamp.sub(staker[_user].stakeStartTimestamp).div(MINUTESECONDS);
        if(minsPast >= 1){
            return minsPast;// returns 0 if under 1 min passed
        }
        else{
            return 0;
        }
    }
    
    //check is stake finished, min 3 days
    function isStakeFinished(address _user)
        public
        view
        returns(bool)
    {
        if(staker[_user].stakeStartTimestamp == 0){
            return false;
        }
        else{
            return staker[_user].stakeStartTimestamp.add((DAYSECONDS).mul(MINSTAKEDAYLENGTH)) <= block.timestamp;
        }
    }

}