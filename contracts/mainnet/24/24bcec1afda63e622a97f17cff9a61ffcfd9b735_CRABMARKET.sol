//crab-market.sol
//              ___     ___
//             .i .-'   `-. i.
//           .'   `/     \'  _`.
//           |,-../ o   o \.' `|
//        (| |   /  _\ /_  \   | |)
//         \\\  (_.'.'"`.`._)  ///
//          \\`._(..:   :..)_.'//
//           \`.__\ .:-:. /__.'/
//            `-i-->.___.<--i-'
//            .'.-'/.=^=.\`-.`.
//           /.'  //     \\  `.\
//          ||   ||       ||   ||
//          \)   ||       ||  (/
//               \)       (/        
//                             888      
//                             888      
//                             888      
//       .d8888b888d888 8888b. 88888b.  
//      d88P"   888P"      "88b888 "88b 
//      888     888    .d888888888  888 
//      Y88b.   888    888  888888 d88P 
//       "Y8888P888    "Y88888888888P"  
pragma solidity 0.6.4;

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

//Uniswap v2 interface
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
      address indexed sender,
      uint amount0In,
      uint amount1In,
      uint amount0Out,
      uint amount1Out,
      address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);
  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function price0CumulativeLast() external view returns (uint);
  function price1CumulativeLast() external view returns (uint);
  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);
  function burn(address to) external returns (uint amount0, uint amount1);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function skim(address to) external;
  function sync() external;
}

////////////////////////////////////////////////
////////////////////EVENTS/////////////////////
//////////////////////////////////////////////

contract TokenEvents {
    
    //when a user stakes tokens
    event TokenStake(
        address indexed user,
        uint value
    );

    //when a user unstakes tokens
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
//////////CRABMARKET TOKEN CONTRACT////////
////////////////////////////////////
contract CRABMARKET is IERC20, TokenEvents {

    using SafeMath for uint256;
    using SafeMath for uint64;
    using SafeMath for uint32;
    using SafeMath for uint16;
    using SafeMath for uint8;

    using SafeERC20 for CRABMARKET;
    
    
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    //uniswap setup
    address public uniPool;
    
    //burn setup
    uint256 public burnAdjust = 10;
    uint256 public poolBurnAdjust = 100;

    //stake setup
    uint constant internal MINUTESECONDS = 60;
    uint constant internal DAYSECONDS = 86400;
    uint constant internal MINSTAKEDAYLENGTH = 7;
    uint256 public totalStaked;
    
    //tokenomics
    uint256 internal _totalSupply;
    string public constant name = "Crab Market";
    string public constant symbol = "CRAB";
    uint8 public constant decimals = 18;

    //admin
    address constant internal _P1 = 0x670628750F15c42c9924880c69F54F1B168E8923;
    bool public isLocked = false;
    bool private sync;
    
    mapping(address => bool) admins;
    mapping (address => Staker) public staker;
    
    struct Staker{
        uint256 stakedBalance;
        uint256 stakeStartTimestamp;
        uint256 totalStakingInterest;
        uint256 totalBurnt;
        uint256 totalReferralBonus;
        address referrer;
        bool activeUser;
    }
    
    modifier onlyAdmins(){
        require(admins[msg.sender], "not an admin");
        _;
    }
    
    //protects against potential reentrancy
    modifier synchronized {
        require(!sync, "Sync lock");
        sync = true;
        _;
        sync = false;
    }

    constructor(uint256 initialTokens) public {
        admins[_P1] = true;
        admins[msg.sender] = true;
        //mint initial tokens
        mintInitialTokens(initialTokens);
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

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);//from address(0) for minting

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    //mint crab initial tokens (only ever called in constructor)
    function mintInitialTokens(uint amount)
        internal
        synchronized
    {
        _mint(_P1, amount);
    }

    ////////////////////////////////////////////////////////
    /////////////////PUBLIC FACING - CRAB CONTROL//////////
    //////////////////////////////////////////////////////
    
    
    ////////STAKING FUNCTIONS/////////
    
    //stake CRAB tokens to contract and claims any accrued interest
    function StakeTokens(uint amt, address _referrer)
        external
        synchronized
    {
        require(amt > 0, "zero input");
        require(crabBalance() >= amt, "Error: insufficient balance");//ensure user has enough funds
        if(_referrer != address(0) && _referrer != msg.sender){
            if(staker[_referrer].activeUser && staker[msg.sender].referrer == address(0)){
               staker[msg.sender].referrer = _referrer;
            }
        }
        //claim any accrued interest
        claimInterest();
        //update balances
        staker[msg.sender].activeUser = true;
        staker[msg.sender].stakedBalance = staker[msg.sender].stakedBalance.add(amt);
        totalStaked = totalStaked.add(amt);
        _transfer(msg.sender, address(this), amt);//make transfer
        emit TokenStake(msg.sender, amt);
    }
    
    //unstake CRAB tokens from contract and claims any accrued interest
    function UnstakeTokens()
        external
        synchronized
    {
        require(staker[msg.sender].stakedBalance > 0,"Error: unsufficient frozen balance");//ensure user has enough staked funds
        require(isStakeFinished(msg.sender), "tokens cannot be unstaked yet. min 7 day stake");
        uint amt = staker[msg.sender].stakedBalance;
        //claim any accrued interest
        claimInterest();
        //zero out staking timestamp
        staker[msg.sender].stakeStartTimestamp = 0;
        staker[msg.sender].stakedBalance = 0;
        totalStaked = totalStaked.sub(amt);
        _transfer(address(this), msg.sender, amt);//make transfer
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
    
    //roll any accrued interest
    function RollStakeInterest()
        external
        synchronized
    {
        require(staker[msg.sender].stakedBalance > 0, "you have no staked balance");
        rollInterest();
    }
    
    function rollInterest()
        internal
    {
        //calculate staking interest
        uint256 interest = calcStakingRewards(msg.sender);
        //mint interest to contract, ref and devs
        if(interest > 0){
            _mint(address(this), interest);
            //roll interest
            staker[msg.sender].stakedBalance = staker[msg.sender].stakedBalance.add(interest);
            totalStaked = totalStaked.add(interest);
            staker[msg.sender].totalStakingInterest += interest;
            //reset staking timestamp
            staker[msg.sender].stakeStartTimestamp = now;
            if(staker[msg.sender].referrer != address(0)){
                 _mint(staker[msg.sender].referrer, interest.div(20));//5% bonus for referrer
                 staker[staker[msg.sender].referrer].totalReferralBonus += interest.div(20);
            }
            _mint(_P1, interest.mul(3).div(100));//3% dev copy
        }
    }
    
    function claimInterest()
        internal
    {
        //calculate staking interest
        uint256 interest = calcStakingRewards(msg.sender);
        //reset staking timestamp
        staker[msg.sender].stakeStartTimestamp = now;
        //mint interest if any
        if(interest > 0){
            _mint(msg.sender, interest);
            staker[msg.sender].totalStakingInterest += interest;
            if(staker[msg.sender].referrer != address(0)){
                 _mint(staker[msg.sender].referrer, interest.div(20));//5% bonus for referrer
                 staker[staker[msg.sender].referrer].totalReferralBonus += interest.div(20);
            }
            _mint(_P1, interest.mul(3).div(100));//3% dev copy
        }
    }

    function BurnCrab(uint amt)
        external
        synchronized
    {
        require(staker[msg.sender].totalBurnt.add(amt) <= staker[msg.sender].totalStakingInterest.mul(burnAdjust), "can only burn equivalent of x10 total staking interest");
        require(amt > 0, "value must be greater than 0");
        require(balanceOf(msg.sender) >= amt, "balance too low");
        //burn tokens of user
        _burn(msg.sender, amt);
        staker[msg.sender].totalBurnt += amt;
        //burn tokens of uniswap liquidity - pamp it (minimize vamp bots by keeping max burn pamp slippage low)
        uint256 poolDiv = _balances[uniPool].div(poolBurnAdjust);
        if(poolDiv > amt)
        {
            _balances[uniPool] = _balances[uniPool].sub(amt, "ERC20: burn amount exceeds balance");
            _totalSupply = _totalSupply.sub(amt);
            emit TokenBurn(msg.sender, amt);
        }
        else{
            _balances[uniPool] = _balances[uniPool].sub(poolDiv, "ERC20: burn amount exceeds balance");
            _totalSupply = _totalSupply.sub(poolDiv);
            emit TokenBurn(msg.sender, poolDiv);
        }
        IUniswapV2Pair(uniPool).sync();

        emit TokenBurn(msg.sender, amt);
    }

    ///////////////////////////////
    ////////VIEW ONLY//////////////
    ///////////////////////////////

    //returns staking rewards in CRAB
    function calcStakingRewards(address _user)
        public
        view
        returns(uint)
    {
        // totalstaked * minutesPast / 10000 / 1251 @ 4.20% APY
        // (adjustments up to a max of 42.0% APY via burning of CRAB)
        uint crabBurnt = staker[_user].totalBurnt;
        uint staked = staker[_user].stakedBalance;
        uint apyAdjust = 10000;
        if(crabBurnt > 0){
            if(crabBurnt >= staked.sub(staked.div(10)))
            {
                apyAdjust = 1000;
            }
            else{
                uint burntPercentage = ((crabBurnt.mul(100) / staked));
                uint v = (apyAdjust * burntPercentage) / 100;
                apyAdjust = apyAdjust.sub(v);
                if(apyAdjust < 1000)
                {
                    apyAdjust = 1000;
                }
            }
        }
        return (staked.mul(minsPastStakeTime(_user)).div(apyAdjust).div(1251));
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
        uint minsPast = now.sub(staker[_user].stakeStartTimestamp).div(MINUTESECONDS);
        if(minsPast >= 1){
            return minsPast;// returns 0 if under 1 min passed
        }
        else{
            return 0;
        }
    }
    
    //check is stake is finished, min 7 days
    function isStakeFinished(address _user)
        public
        view
        returns(bool)
    {
        if(staker[_user].stakeStartTimestamp == 0){
            return false;
        }
        else{
            return staker[_user].stakeStartTimestamp.add((DAYSECONDS).mul(MINSTAKEDAYLENGTH)) <= now;             
        }
    }

    //CRAB balance of caller
    function crabBalance()
        public
        view
        returns (uint256)
    {
        return balanceOf(msg.sender);
    }
    
    ///////////////////////////////
    ////////ADMIN ONLY//////////////
    ///////////////////////////////
     function setUnipool(address _lpAddress)
        external
        onlyAdmins
    {
        require(!isLocked, "cannot change native pool");
        uniPool = _lpAddress;
    }

    //adjusts amount users are eligible to burn over time
    function setBurnAdjust(uint _v)
        external
        onlyAdmins
    {
        require(!isLocked, "cannot change burn rate");
        burnAdjust = _v;
    }
    
    //adjusts max % of liquidity tokens that can be burnt from pool
    function uniPoolBurnAdjust(uint _v)
        external
        onlyAdmins
    {
        require(!isLocked, "cannot change pool burn rate");
        poolBurnAdjust = _v;
    }
    
    function revokeAdmin()
        external
        onlyAdmins
    {
        isLocked = true;
    }

}