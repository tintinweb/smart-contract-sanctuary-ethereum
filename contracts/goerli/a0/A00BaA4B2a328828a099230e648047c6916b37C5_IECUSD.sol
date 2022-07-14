//SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "./IERC20.sol";

contract IECUSD is IERC20 {

    // total supply
    uint256 private _totalSupply;

    // token data
    string private constant _name = "IECUSD";
    string private constant _symbol = "IUSD";
    uint8  private constant _decimals = 4;

    // balances
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    // locking
    mapping ( address => bool ) public isLocked;

    // Governance
    address public governor;

    /**
        Ensures Caller Is Authorized To Call Restricted Functions
     */
    modifier onlyAuthorized() {
        require(
            msg.sender == governor,
            'Not Authorized To Call'
        );
        _;
    }

    // Events
    event Lock(address account);
    event Unlock(address account);
    event Minted(address account, uint256 amount);
    event Burned(address account, uint256 amount);
    event ChangedGovernor(address newGovernor);

    constructor() {

        // instantiate governance
        governor = msg.sender;

        // emit event for etherscan tracking
        emit Transfer(address(0), msg.sender, 0);
    }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    
    function name() public pure override returns (string memory) {
        return _name;
    }

    function symbol() public pure override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /** Transfer Function */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    /** Transfer Function */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(
            _allowances[sender][msg.sender] >= amount,
            'Insuffucient Allowance'
        );
        _allowances[sender][msg.sender] -= amount;
        return _transferFrom(sender, recipient, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) external {
        require(
            _allowances[account][msg.sender] >= amount,
            'Insuffucient Allowance'
        );
        _allowances[account][msg.sender] -= amount;
        _burn(account, amount);
    }

    function burn(address account, uint256 amount) external onlyAuthorized {
        _burn(account, amount);
    }

    function mint(address to, uint256 amount) external onlyAuthorized {
        require(
            to != address(0),
            'Zero Address'
        );
        _balances[to] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), to, amount);
        emit Minted(to, amount);
    }

    function setGovernor(address governor_) external onlyAuthorized {
        governor = governor_;
        emit ChangedGovernor(governor_);
    }

    function lock(address account) external onlyAuthorized {
        isLocked[account] = true;
        emit Lock(account);
    }

    function unlock(address account) external onlyAuthorized {
        isLocked[account] = false;
        emit Unlock(account);
    }
    
    /** Internal Transfer */
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(
            recipient != address(0),
            'Zero Address'
        );
        require(
            amount <= _balances[sender],
            'Insufficient Balance'
        );
        require(
            amount > 0,
            'Zero Transfer Amount'
        );
        require(
            isLocked[sender] == false,
            'Sender Is Locked'
        );

        // Reallocate Balances
        _balances[sender] -= amount;
        _balances[recipient] += amount;

        // emit transfer
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _burn(address account, uint256 amount) internal {
        require(
            _balances[account] >= amount,
            'Insufficient Balance'
        );
        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        emit Burned(account, amount);
    }
}

//SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

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