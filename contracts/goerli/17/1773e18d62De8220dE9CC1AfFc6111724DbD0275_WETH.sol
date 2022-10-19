// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import "./ERC20.sol";
contract WETH is ERC20("Wrapped Ether", "WETH") {
    function deposit() public payable {
        mint(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public {
        burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract ERC20 {
    /**
     * **** PRIVATE STATE VARIABLES ****
     */
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    uint256 private _decimals = 18;
    address private _contractOwner;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    /**
     * **** EVENTS ****
     */
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
    event Approval(address indexed owner, address indexed spender, uint256 _value);



    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _contractOwner = payable(msg.sender);
        _totalSupply = 1000000000000000000000000000000000;
        _balances[_contractOwner] = _totalSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == _contractOwner, "Access restricted to only owner");
        _;
    }
    /**
    * **** PUBLIC VIEW FUNCIONS *****
    */

    /**
    * @dev Returns the name of the token.
    */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
    * @dev Returns the symbol of the token,
    */
    function symbol() public view returns (string memory) {
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
     */

    function decimals() public view returns (uint256) {
        return _decimals;
    }
     /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the amount of tokens owned by given `account`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     *
     * @param _owner contracts address
     * @param _spender spenders addres
     *
     * @return an uint256 token value indicating the allowance granted
     */

    function allowance(address _owner, address _spender) public view returns (uint256){
        return _allowances[_owner][_spender];
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
    function mint(address account, uint256 amount) public onlyOwner returns (bool){
        require(account != address(0), "ERC20: mint to the zero address");

        _balances[account] += amount;
        _totalSupply += amount;

    emit Transfer(account, address(0), amount);
    return true;
    }

    /***
     * Destroy tokens
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _account the account address which tokens will be deleted from
     * @param _amount the amount of money to burn
     */
    function burn(address account, uint256 amount)
        public
        onlyOwner
        returns (bool)
    {
        require(
            _balances[account] >= amount,
            "The balance is less than burning amount"
        );

        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);

        return true;
    }


    /***
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * @param _to receipent address
     * @param _amount _amount to be transfered
     *
     * @return a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(
            _balances[msg.sender] >= _value,
            "Sender does not have enough money"
        );
        require(_to != address(0), "Address is required");

        _balances[msg.sender] -= _value;
        _balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    /***
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _amount the amount to send
     *
     * @return bool if succeded
     *
     * Emits a {Transfer} event.
     */

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        require(_balances[_from] > _value, "Sender balance is too low");
        require(
            _allowances[_from][msg.sender] >= _value,
            "Sender allowance is below the value needed"
        );

        _allowances[_from][msg.sender] -= _value;
        _balances[_from] -= _value;
        _balances[_to] += _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Set allowance for other address
     *
     * @dev Allows `_spender` `_amount` of tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _amount the max amount they can spend
     *
     * Emits a {Approval} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function approve(address _spender, uint256 _amount) external returns (bool) {
        require(_spender != address(0), "ERC20: zero address");
        _allowances[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    /***
     * @dev Increase allowance for a given address
     *
     * @dev Allows `_spender` to spend no more than `_amount` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _amount the max amount they can spend
     *
     * Emits a {Approval} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */

    function increaseAllowance(address _spender, uint256 _amount) public returns (bool){
        _approve(
            msg.sender,
            _spender,
            _allowances[msg.sender][_spender] + _amount
        );

        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool){
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );

        _approve(msg.sender, spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Set allowance for other address
     *
     * @dev Allows `_spender` to spend no more than `_amount` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _amount the max amount they can spend
     *
     * Emits a {Approval} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */

    function _approve(address _owner, address _spender, uint256 _amount) internal {
        require(_spender != address(0), "ERC20: zero address");
        _allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }
}