/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title ERC20 interface
 *
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address _owner) external view returns (uint256 balance);

  function transfer(address _to, uint256 _value) external returns (bool success);

  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

  function approve(address _spender, uint256 _value) external returns (bool success);

  function allowance(address _owner, address _spender) external view returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 */
contract Token is IERC20 {
    event Withdraw(address indexed _owner, address indexed _spender, uint256 _value);

    address public _owner;
    uint256 public price;

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;
    uint256 private _totalSupply;

    modifier onlyOwner {
      require(msg.sender == _owner, "Only the owner of the contract can withdraw its funds");
      _;
    }

    constructor () {
        _totalSupply = 2000;
        balances[address(this)] = _totalSupply;
        _owner = msg.sender;
        price = 5;
    }

    /**
    * 
    * ERC20 METHODS
    *
    */

    /**
    * @dev Total number of tokens in existence
    *
    * @return uint256 representing the total suppply.
    */
    function totalSupply() override external view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    *
    * @param owner address The address to query the balance of.
    *
    * @return uint256 representing the amount owned by the address.
    */
    function balanceOf(address owner) override external view returns (uint256) {
        return balances[owner];
    }

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    *
    * @param owner address The address which owns the funds.
    * @param spender address The address which will spend the funds.
    *
    * @return uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(address owner, address spender) override external view returns (uint256) {
        return allowed[owner][spender];
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    *
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729 - Not addressed in this exercise
    *
    * @param spender address The address which will spend the funds.
    * @param value uint256 The amount of tokens to be spent.
    *
    * @return bool.
    */
    function approve(address spender, uint256 value) override external returns (bool) {
        _assertIsNotZeroAddress(spender);

        allowed[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    /**
    * @dev Transfer tokens from one address to another
    *
    * @param from address The address which you want to send tokens from
    * @param to address The address which you want to transfer to
    * @param value uint256 the amount of tokens to be transferred
    *
    * @return bool.
    */
    function transferFrom(address from, address to, uint256 value) override external returns (bool) {
        _assertItCanMove(from, to, value);
        _assertItHasEnoughAllowance(from, value);
        
        _move(from, to, value);
        allowed[from][msg.sender] -= value;

        emit Transfer(from, to, value);

        return true;
    }

    /**
    * @dev Transfer token for a specified address
    *
    * @param to address The address to transfer to.
    * @param value uint256 The amount to be transferred.
    *
    * @return bool.
    */
    function transfer(address to, uint256 value) override external returns (bool) {
        _assertItCanMove(msg.sender, to, value);

        _move(msg.sender, to, value);

        emit Transfer(msg.sender, to, value);

        return true;
    }

    /**
    * @dev Buy a certain amount of tokens
    *
    * @param amount uint256 The amount of tokens to be bought
    *
    * @return bool.
    */
    function buy(uint256 amount) external payable returns (bool){
        _assertPaymentIsEnough(amount);
        _assertItCanMove(address(this), msg.sender, amount);

        _move(address(this), msg.sender, amount);

        emit Transfer(address(this), msg.sender, amount);

        return true;
    }

    /**
    * @dev Sell a certain amount of tokens
    *
    * @param amount uint256 The amount of tokens to sell
    *
    * @return bool.
    */
    function sell(uint256 amount) external returns (bool){
        _assertItCanMove(msg.sender, address(this), amount);

        _move(msg.sender, address(this), amount);

        emit Transfer(msg.sender, address(this), amount);

        payable(msg.sender).transfer(amount * price);

        return true;
    }

    /**
    * @dev Withdraw all eth stored in contract
    *
    * @return bool.
    */
    function withdraw() onlyOwner external returns (bool){
        payable(msg.sender).transfer(address(this).balance);

        emit Withdraw(address(this), msg.sender, address(this).balance);

        return true;
    }
    
    /**
    * 
    * PRIVATE
    *
    */

    /**
    * @dev Performs an assertion that revert the tx if it is the zero address
    *
    * @param account address The address to verify
    */
    function _assertIsNotZeroAddress(address account) private pure {
        require(account != address(0), "ERC20: is zero address");
    }

    /**
    * @dev Performs an assertion that revert the tx if it one does not have enough allowance
    *
    * @param from address The address to verify
    * @param amount uint256 The allowed amount
    */
    function _assertItHasEnoughAllowance(address from, uint256 amount) private view {
        require(allowed[from][msg.sender] >= amount, "Not enough allowance");
    }

    /**
    * @dev Performs an assertion that revert the tx if zero address is provided or if a certain address does not have enough balance
    *
    * @param from address The account to verify
    * @param to address The account to verify
    * @param amount uint256 The amount to be transfered
    */
    function _assertItCanMove(address from, address to, uint256 amount) private view {
        _assertIsNotZeroAddress(from);
        _assertIsNotZeroAddress(to);
        require(balances[from] >= amount, "Source account does not have enough tokens");
    }

    /**
    * @dev Performs an assertion that revert the tx if payment is not enough for the amount of tokens to be bought
    *
    * @param amount uint256 The amount of tokens to be bought
    */
    function _assertPaymentIsEnough(uint256 amount) private view {
        require(msg.value == amount * price, "Need to send exact amount of wei");
    }

    /**
    * @dev Performs a debit and credit operation between two addresses
    *
    * @param from address The address to debit
    * @param to address The address to credit
    * @param amount uint256 The amount to be transfered
    */
    function _move(address from, address to, uint256 amount) private {
        balances[from] -= amount;
        balances[to] += amount;
    }
}