// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IERC20.sol";

error DinhToken__NotEnoughApprovedAmount();
error DinhToken__NotEnoughBalance();
error DinhToken__InvalidAmount();
error DinhToken__WrongPassword();
error DinhToken__NotTheOnwer();
error DinhToken__InvalidAddressZero();
error DinhToken__OwnerOutOfToken();

contract DinhToken is IERC20 {
    string constant PASSWORD = "Djnh sju ka^p vjp pr0";

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address private _owner;

    modifier onlyOwner() {
        if (msg.sender != _owner) revert DinhToken__NotTheOnwer();
        _;
    }

    constructor(
        uint256 totalSupply_,
        string memory name_,
        string memory symbol_
    ) {
        _totalSupply = totalSupply_;
        _owner = msg.sender;
        _balances[msg.sender] = totalSupply_;
        _name = name_;
        _symbol = symbol_;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address to, uint256 amount)
        external
        override
        returns (bool)
    {
        if (amount <= 0) revert DinhToken__InvalidAmount();
        if (_balances[msg.sender] < amount)
            revert DinhToken__NotEnoughBalance();
        if (to == address(0)) revert DinhToken__InvalidAddressZero();
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner_, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner_][spender];
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[from][msg.sender] < amount)
            revert DinhToken__NotEnoughApprovedAmount();
        if (_balances[from] < amount) revert DinhToken__NotEnoughBalance();
        if (amount <= 0) revert DinhToken__InvalidAmount();
        if (to == address(0)) revert DinhToken__InvalidAddressZero();
        _balances[from] -= amount;
        _allowances[from][msg.sender] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function getOneTokenFree(string memory password_) external {
        if (_balances[_owner] < 1) revert DinhToken__OwnerOutOfToken();
        if (
            keccak256(abi.encodePacked(password_)) !=
            keccak256(abi.encodePacked(PASSWORD))
        ) revert DinhToken__WrongPassword();
        _balances[_owner] -= 1;
        _balances[msg.sender] += 1;
        emit Transfer(_owner, msg.sender, 1);
    }

    function mint(address receiver, uint256 amount) external onlyOwner {
        if (amount <= 0) revert DinhToken__InvalidAmount();
        if (receiver == address(0)) revert DinhToken__InvalidAddressZero();
        _totalSupply += amount;
        _balances[receiver] += amount;
        emit Transfer(address(0), receiver, amount);
    }

    function burn(uint256 amount) external {
        if (amount > _balances[msg.sender])
            revert DinhToken__NotEnoughBalance();
        if (amount <= 0) revert DinhToken__InvalidAmount();
        _balances[msg.sender] -= amount;
        _totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

    function owner() public view returns (address) {
        return _owner;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}