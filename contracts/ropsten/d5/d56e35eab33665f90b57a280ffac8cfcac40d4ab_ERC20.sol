/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;


contract ERC20 {
    
    //stores current balances
    mapping(address => uint256) private _balances;
    //stores current approvals
    mapping(address => mapping(address => uint256)) private _allowances;
    //current total supply of token
    uint256 private _totalSupply;
    //current token metadata
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    /**
     * @dev Emitted when `amount` tokens are moved from one account (`payerId`) to another (`payeeId`).
     *
     * Note that `amount` may be zero.
     */
    event Transfer(address indexed payerId, address indexed payeeId, uint256 amount);

    /**
     * @dev Emitted when the allowance of a `payeeId` for an `payerId` is set by
     * a call to {approve}. `amount` is the new allowance.
     */
    event Approval(address indexed payerId, address indexed payeeId, uint256 amount);

    /**
     * @dev Sets the values for {_name}, {_symbol}, {_decimals}, {_totalSupply}.
     * Additionally, all of the supply is initially given to the address corresponding to {giveSupplyTo_}
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 supply_, address giveSupplyTo_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = supply_;
        _balances[giveSupplyTo_] = supply_;
        
    }


    /**
     * @dev Moves `amount` tokens from the caller's account to `payeeId`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address payeeId, uint256 amount) external returns (bool) {
        _transfer(msg.sender, payeeId, amount);
        return true;
    }

    /**
     * @dev Sets `amount` as the allowance of `payeeId` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * The if statement makes sure that this contract's approval system is not 
     * vulnerable to the race condition (where a payee spends the previous
     * and new allowance)
     *
     * Emits an {Approval} event.
     */
    function approve(address payeeId, uint256 amount) external returns (bool) {
        if (_allowances[msg.sender][payeeId] > 0){
            require(amount == 0, "ERC20: approve call vulnerable to race condition");            
        }
        _approve(msg.sender, payeeId, amount);
        return true;
    }

    /**
     * @dev Moves `amount` tokens from `payerId` to `payeeId` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address payerId, address payeeId, uint256 amount) external returns (bool) {

        uint256 currentAllowance = _allowances[payerId][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _transfer(payerId, payeeId, amount);
        unchecked {
            _approve(payerId, msg.sender, currentAllowance - amount);
        }

        return true;
    }


    /**
     * @dev Moves `amount` of tokens from `payerId` to `payeeId`.
     *
     * This internal function is equivalent to {transfer}.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `payerId` cannot be the zero address.
     * - `payeeId` cannot be the zero address.
     * - `payerId` must have a balance of at least `amount`.
     */
    function _transfer(address payerId, address payeeId, uint256 amount) internal {
        require(payerId != address(0), "ERC20: transfer from the zero address");
        require(payeeId != address(0), "ERC20: transfer to the zero address");
        require(payeeId != address(this), "ERC20: transfer to the contract address");

        uint256 senderBalance = _balances[payerId];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[payerId] = senderBalance - amount;
        }
        _balances[payeeId] += amount;

        emit Transfer(payerId, payeeId, amount);

    }

    /**
     * @dev Sets `amount` as the allowance of `payeeId` over the `payerId` s tokens.
     *
     * This internal function is equivalent to {approve}.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `payerId` cannot be the zero address.
     * - `payeeId` cannot be the zero address.
     */
    function _approve(address payerId, address payeeId, uint256 amount) internal {
        require(payerId != address(0), "ERC20: approve from the zero address");
        require(payeeId != address(0), "ERC20: approve to the zero address");

        _allowances[payerId][payeeId] = amount;
        emit Approval(payerId, payeeId, amount);
    }

    /**
     * @dev Returns the name of the token.
     */
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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for display purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {balanceOf} and {transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

     /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the amount of tokens owned by `ownerAccountId`.
     */
    function balanceOf(address accountId) public view returns (uint256) {
        return _balances[accountId];
    }

    /**
     * @dev Returns the remaining number of tokens that `payeeId` will be
     * allowed to spend on behalf of `payerId` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address payerId, address payeeId) public view returns (uint256) {
        return _allowances[payerId][payeeId];
    }

}