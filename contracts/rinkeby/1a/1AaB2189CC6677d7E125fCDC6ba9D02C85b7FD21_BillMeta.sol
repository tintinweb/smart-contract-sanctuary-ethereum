/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see ERC20_infos.
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

/**
 * @dev Optional functions from the ERC20 standard.
 */
abstract contract ERC20_infos is IERC20 {
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;


    constructor (string memory name, string memory symbol, uint8 decimals) {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    } 

    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}


abstract contract Governance {

    address public governance;

    constructor() {
        governance = tx.origin;
    }

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyGovernance {
        require(msg.sender == governance, "Sender not governance");
        _;
    }

    function setGovernance(address _governance)  public  onlyGovernance
    {
        require(_governance != address(0), "new governance the zero address");
        emit GovernanceTransferred(governance, _governance);
        governance = _governance;
    }

}


contract BillMeta is Governance, ERC20_infos{

    using SafeMath for uint256;

    address public _daoPool = address(0x0);
    address public _rewardPool =  address(0x0);
    
    uint256 internal _totalSupply;
    uint256 public  _maxSupply = 0;
    bool public _openTransfer = false;

    uint256 public constant _maxGovernValueRate = 2000;
    uint256 public constant _minGovernValueRate = 10; 
    uint256 public constant _rateBase = 10000; 

    uint256 public  _daoRate = 0;       
    uint256 public  _rewardRate = 0;   
    uint256 public  _totalDaoToken = 0;
    uint256 public  _totalRewardToken = 0;


    event SetRate(uint256 dao_rate, uint256 reward_rate);
    event RewardPool(address rewardPool);
    event DaoPool(address daoPool);
    event Transferto(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed from, address indexed to, uint256 value);
    event Approvalto(address indexed owner, address indexed spender, uint256 value);

    mapping (address => bool) public _minters;
    mapping(address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) public _allowances;
    
    constructor () ERC20_infos("BillMeta", "BMT", 18) {
   // constructor () {
         _maxSupply = 6660000 * (10**18);
          _name = "BillMeta";
          _symbol = "BMT";
          _decimals = 18;
    }
    

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param spender The address which will spend the funds.
    * @param amount The amount of tokens to be spent.
    */
    function approve(address spender, uint256 amount) external override 
    returns (bool) 
    {
        require(msg.sender != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[msg.sender][spender] = amount;
        emit Approvalto(msg.sender, spender, amount);

        return true;
    }

    /**
    * @dev Function to check the amount of tokens than an owner _allowed to a spender.
    * @param owner address The address which owns the funds.
    * @param spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(address owner, address spender) external override view 
    returns (uint256) 
    {
        return _allowances[owner][spender];
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) external override view 
    returns (uint256) 
    {
        return _balances[owner];
    }

    /**
    * @dev the token starting to transfer
    */
    function enableOpenTransfer() public onlyGovernance  
    {
        _openTransfer = true;
    }
    
    /**
    * @dev return the token total supply
    */
    function totalSupply() external override view 
    returns (uint256) 
    {
        return _totalSupply;
    }

    /**
    * @dev return the token maximum limit supply
    */
    function maxLimitSupply() external view 
    returns (uint256) 
    {
        return _maxSupply;
    }
    
    /**
    * @dev for mint function
    */
    function mint(address account, uint256 amount) external 
    {
        require(account != address(0), "ERC20: mint to the zero address");
        require(_minters[msg.sender], "!minter");

        uint256 curMintSupply = _totalSupply.add(_totalDaoToken);
        uint256 newMintSupply = curMintSupply.add(amount);
        require( newMintSupply <= _maxSupply,"supply is max!");
      
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);

        emit Mint(address(0), account, amount);
        emit Transferto(address(0), account, amount);
    }

    function addMinter(address _minter) public onlyGovernance 
    {
        _minters[_minter] = true;
    }
    
    function removeMinter(address _minter) public onlyGovernance 
    {
        _minters[_minter] = false;
    }
    

    function setRate(uint256 dao_rate, uint256 reward_rate) public 
        onlyGovernance 
    {
        
        require(_maxGovernValueRate >= dao_rate && dao_rate >= _minGovernValueRate,"invalid dao rate");
        require(_maxGovernValueRate >= reward_rate && reward_rate >= _minGovernValueRate,"invalid reward rate");

        _daoRate = dao_rate;
        _rewardRate = reward_rate;

        emit SetRate(dao_rate, reward_rate);
    }

    /**
    * @dev for set reward pool
    */
    function setRewardPool(address rewardPool) public 
        onlyGovernance 
    {
        require(rewardPool != address(0x0));

        _rewardPool = rewardPool;

        emit RewardPool(_rewardPool);
    }

    /**
    * @dev for set dao pool
    */
    function setDaoPool(address daoPool) public 
        onlyGovernance 
    {
        require(daoPool != address(0x0));

        _daoPool = daoPool;

        emit DaoPool(_daoPool);
    }

    /**
    * @dev transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
   function transfer(address to, uint256 value) external override 
   returns (bool)  
   {
        return _transfer(msg.sender,to,value);
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param from address The address which you want to send tokens from
    * @param to address The address which you want to transfer to
    * @param value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address from, address to, uint256 value) external override 
    returns (bool) 
    {
        uint256 allow = _allowances[from][msg.sender];
        _allowances[from][msg.sender] = allow.sub(value);
        
        return _transfer(from,to,value);
    }

 
    /**
    * @dev Transfer tokens with fee
    * @param from address The address which you want to send tokens from
    * @param to address The address which you want to transfer to
    * @param value uint256s the amount of tokens to be transferred
    */
    function _transfer(address from, address to, uint256 value) internal 
    returns (bool) 
    {
        require(_openTransfer || from == governance, "The transfer closed");

        require(from != address(0), "Invalid: transfer from the 0 address");
        require(to != address(0), "Invalid: transfer to the 0 address");

        uint256 sendAmount = value;
        uint256 daoFee = (value.mul(_daoRate)).div(_rateBase);
        if (daoFee > 0) {
            
            _balances[_daoPool] = _balances[_daoPool].add(daoFee);
            _totalSupply = _totalSupply.sub(daoFee);
            sendAmount = sendAmount.sub(daoFee);

            _totalDaoToken = _totalDaoToken.add(daoFee);

            emit Transfer(from, _daoPool, daoFee);
        }

        uint256 rewardFee = (value.mul(_rewardRate)).div(_rateBase);
        if (rewardFee > 0) {
           
            _balances[_rewardPool] = _balances[_rewardPool].add(rewardFee);
            sendAmount = sendAmount.sub(rewardFee);

            _totalRewardToken = _totalRewardToken.add(rewardFee);

            emit Transfer(from, _rewardPool, rewardFee);
        }

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(sendAmount);

        emit Transfer(from, to, sendAmount);

        return true;
    }

    function calcSendamount(uint256 value) view external returns (uint256)  
    {
        uint256 sendAmount = value;
        uint256 daoFee = (value.mul(_daoRate)).div(_rateBase);
        if (daoFee > 0) {
           sendAmount = sendAmount.sub(daoFee);    
        }
        uint256 rewardFee = (value.mul(_rewardRate)).div(_rateBase);
        if (rewardFee > 0) {
           sendAmount = sendAmount.sub(rewardFee);    
        }
        return sendAmount;
    }    

    function getdaoRate() view external returns (uint256)  
    {
         return _daoRate;
    }

    function getrewardRate() view external returns (uint256)  
    {
         return _rewardRate;
    }  

    function totalDao() view external returns (uint256)  
    {
         return _totalDaoToken;
    }  
    
    function totalReward() view external returns (uint256)  
    {
         return _totalRewardToken;
    }  
    
    fallback() external payable {
        revert();
    }
    receive() external payable {
        revert();
    }
}