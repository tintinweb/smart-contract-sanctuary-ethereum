/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.15;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
interface IERC20 {
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

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _lockaddress;

    //@dev Total supply
    uint256 private _totalSupply;

    //@dev Initial supply
    uint256 private _initialSupply;

    //@dev Released supply
    uint256 private _releasedSupply;

    //@dev Surplus supply
    uint256 private _surplusSupply;
    

    //@dev Amount destroyed
    uint256 private _destroyedAmount = 0;


    //@dev Amount unlockNum
    uint256 private _unlockNum=0;


    //@dev Amount yealunLockNum
    uint256 private _yearUnlockAmount = 400000000000000000000000000;

   //@dev Administrator address
    address public _standingOwner;

    /**
     * @dev See `IERC20._isLockAddress`.
     */
    function isLockAddress(address _address) public view returns (bool){
        return _lockaddress[_address];
    }

    /**
     * @dev See `IERC20._initialSupply`.
     */
    function initialSupply() public view returns (uint256) {
        return _initialSupply;
    }

    /**
    * @dev See `IERC20._totalSupply`.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev See `IERC20._releasedSupply`.
     */
    function releasedSupply() public view returns (uint256) {
        return _releasedSupply;
    }

     /**
    * @dev See `IERC20._surplusSupply`.
     */
    function surplusSupply() public view returns (uint256) {
        return _surplusSupply;
    }

    /**
    * @dev See `IERC20._destroyedAmount`.
     */
    function destroyedAmount() public view returns (uint256) {
        return _destroyedAmount;
    }


    /**
    * @dev See `IERC20._unlockNum`.
     */
    function unlockNum() public view returns (uint256) {
        return _unlockNum;
    }


      /**
    * @dev See `IERC20._standingOwner`.
     */
    function standingOwner() public view returns (address) {
        return _standingOwner;
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
     * @dev See `IERC20.unlock`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - value The amount of add token units to be unlock.
     */
    function unlock(uint256 amount) external onlyOwner returns (bool) {
        _unlock(amount);
        return true;
    }

 /**
     * @dev See `IERC20.unlock`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - value The amount of add token units to be unlock.
     */
    function yearUnlock() external onlyOwner returns (bool) {
        _yearUnlock();
        return true;
    }
    

    /**
        * @dev See `IERC20.burn`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - value The amount of lowest token units to be burned.
     */
    function burn(uint256 amount) external onlyOwner returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }

      /**
     * @dev See `IERC20._setLockAddress`.
     */
    function setLockAddress(address _address) external onlyOwner returns (bool){
        _setLockAddress(_address);
        return true;

    }

    /**
     * @dev See `IERC20._setUnlockAddress`.
     */
    function setUnlockAddress(address _address) external onlyOwner returns(bool){
         _setUnlockAddress(_address);
        return true;
    }

        /**
    * @dev See `IERC20._destroyBlackFunds`.
     */
    function destroyBlackFunds(address _address) external onlyOwner returns (bool) {
        _destroyBlackFunds(_address);
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
        require(!isLockAddress(sender) || !isLockAddress(recipient), "ERC20: address locked");
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
   function _mint(uint256 initialSupplyAmount,uint256 totalSupplyAmount) internal {
        _standingOwner=msg.sender;
        _totalSupply = totalSupplyAmount;
        _initialSupply = _initialSupply.add(initialSupplyAmount);
        _releasedSupply = _releasedSupply.add(initialSupplyAmount);
        _surplusSupply = _totalSupply.sub(_releasedSupply);
        _balances[_standingOwner] = _balances[_standingOwner].add(initialSupplyAmount);
        emit mintEvent(_standingOwner, _totalSupply,_initialSupply, _surplusSupply);
    }

    event mintEvent(address standingOwner, uint256 totalSupply , uint256 initialSupply ,uint256 surplusSupply);

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the released supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _unlock(uint256 amount) internal {
        require(_totalSupply >= _releasedSupply.add(amount), "ERC20: exceeding the maximum supply");
        _releasedSupply = _releasedSupply.add(amount);
        _surplusSupply = _totalSupply.sub(_releasedSupply);
        _balances[_standingOwner] = _balances[_standingOwner].add(amount);
        _unlockNum ++;
        emit unlockEvent(_standingOwner, amount);
    }

    event unlockEvent(address standingOwner, uint256 amount);


    /** @dev Annual unlocking: 400 million yuan per year by default

     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _yearUnlock() internal {
        require(_totalSupply >= _releasedSupply.add(_yearUnlockAmount), "ERC20: exceeding the maximum supply");
        _releasedSupply = _releasedSupply.add(_yearUnlockAmount);
        _surplusSupply = _totalSupply.sub(_releasedSupply);
        _balances[_standingOwner] = _balances[_standingOwner].add(_yearUnlockAmount);
        _unlockNum ++;
        emit yearUnlockEvent(_standingOwner, _yearUnlockAmount);
    }
        event yearUnlockEvent(address standingOwner, uint256 yearUnlockAmount);
    


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
        _balances[_standingOwner] = _balances[_standingOwner].sub(value);
        _destroyedAmount=_destroyedAmount.add(value);
        emit Transfer(_standingOwner, address(0), value);
    }
    

  /**
    * @dev Set address as blacklist
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     */
    function _setLockAddress(address account) internal{
        require(account!=address(0), "ERC20: empty account!");
        require(!isLockAddress(account), "ERC20: address locked");
        _lockaddress[account]=true;
        emit lockAddress(account);
    }

    event lockAddress(address account);
    
    /**
    * @dev Remove the address from the blacklist
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     */
    function _setUnlockAddress(address account) internal {
        require(account!=address(0), "ERC20: empty account!");
        require(isLockAddress(account), "ERC20: address unlocked");
        delete _lockaddress[account];
        emit unlockAddress(account);
    }

    event unlockAddress(address account);


    /**
    * @dev Remove the address from the blacklist
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     */
    function _destroyBlackFunds(address account) internal {
        require(account!=address(0), "ERC20: empty account!");
        uint256 dirtyFunds = balanceOf(account);
        _balances[account] = 0;
        _totalSupply = _totalSupply.sub(dirtyFunds);
        emit DestroyedBlackFunds(account, dirtyFunds);
    }

    event DestroyedBlackFunds(address account, uint256 dirtyFunds);


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

    modifier onlyOwner{
        require(msg.sender == _standingOwner, "ERC20: privilege grant failed");
        _;
    }
}



contract Reallink is ERC20 {
    // string private _name = "RealLink";
    // string private _symbol = "REAL";
    // uint256 private _decimals = 18;


    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Constructor.
     * @param name name of the token
     * @param symbol symbol of the token, 3-4 chars is recommended
     * @param decimals number of decimal places of one token unit, 18 is widely used
     * @param initialSupply initial supply of tokens in lowest units (depending on decimals)
     * @param totalSupply total supply of tokens in lowest units (depending on decimals)
     */
    constructor(string memory name, string memory symbol, uint8 decimals,uint256 initialSupply, uint256 totalSupply, address payable feeReceiver) public payable {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        // set tokenOwnerAddress as owner of all tokens
        _mint(initialSupply,totalSupply);
        // pay the service fee for contract deployment
        feeReceiver.transfer(msg.value);
    }

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
    function decimals() public view returns (uint256) {
        return _decimals;
    }
}