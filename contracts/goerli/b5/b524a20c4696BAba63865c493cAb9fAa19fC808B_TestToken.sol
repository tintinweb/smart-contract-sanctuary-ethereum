// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;

import "../interfaces/IERC20.sol";

/**
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract TestToken is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 internal _totalSupply;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowed;

    constructor () public {
        _name = 'token';
        _symbol = 't';
        _decimals = 18;
        _mint(msg.sender, 1000 ether);
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param user The address to query the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address user) external view override returns (uint256) {
        return _balances[user];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param user address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address user, address spender) external view override returns (uint256) {
        return _allowed[user][spender];
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) external override returns  (bool) {
        require(spender != address(0));
        require(msg.sender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);

        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool)
    {
        require(spender != address(0), 'Spender zero address prohibited');
        require(msg.sender != address(0), 'Zero address could not call method');

        _allowed[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);

        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external returns (bool)
    {
        require(spender != address(0), 'Spender zero address prohibited');
        require(msg.sender != address(0), 'Zero address could not call method');

        _allowed[msg.sender][spender] -= subtractedValue;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);

        return true;
    }

    function transferFrom(address from, address to, uint256 value) external override returns (bool) {
        require(value <= _allowed[from][msg.sender], 'Not allowed to spend');
        _transfer(from, to, value);
        _allowed[from][msg.sender] -= value;

        return true;
    }

    function transfer(address to, uint256 value) external override returns (bool) {
        _transfer(msg.sender, to, value);

        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0), 'Zero address con not be receiver');

        _balances[from] -= value;
        _balances[to] += value;
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply += value;
        _balances[account] += value;
        emit Transfer(address(0), account, value);
    }

    /**
 * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external virtual {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply -= value;
        _balances[account] -= value;
        emit Transfer(account, address(0), value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address user, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
}