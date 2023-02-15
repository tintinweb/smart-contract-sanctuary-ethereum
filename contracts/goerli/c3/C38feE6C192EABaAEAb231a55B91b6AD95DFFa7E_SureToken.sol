// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface Isuretoken {
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
    function buyToken() external payable;
    function approve(address spender, uint256 amount) external returns (bool);
    function burnToken(uint256 _amount) external;
    function burnTokenFor(address _owner, uint256 _amount) external;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Isuretoken} from "./interfaces/Isuretoken.sol";

contract SureToken is Isuretoken {
    ///
    /// @param _name  The name of the token
    /// @param _symbol The symbol of the token
    /// @param _decimal The decimal of the token
    /// @param _totalSupply The total supply of the token
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimal,
        uint256 _totalSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimal = _decimal;
        totalSupply_ = _totalSupply;
    }

    string public name;
    string public symbol;
    uint8 public decimal;
    uint256 private totalSupply_;
    mapping(address => uint256) private balanceOf_; // creates a balance for each address
    mapping(address => mapping(address => uint256)) private allowance_; //adress of token owner, address of spender, amount of token allowed to spend

    function totalSupply() external view returns (uint256) {
        return totalSupply_; /// @notice This function returns the total supply of the token
    }

    function balanceOf(address _owner) external view returns (uint256) {
        return balanceOf_[_owner]; /// @param _owner This is owner of a balance requested
    }

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 _remaining)
    {
        _remaining = allowance_[_owner][_spender];
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        _transferToken(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        allowance_[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool) {
        require(
            allowance_[_from][msg.sender] >= _value,
            "Insuficient Allowance"
        );
        _transferToken(_from, _to, _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function _transferToken(
        address _from,
        address _to,
        uint256 _value
    ) private {
        require(balanceOf_[_from] >= _value, "Insufficient Token");
        balanceOf_[_from] -= _value;
        balanceOf_[_to] += _value;
    }

    function buyToken() external payable {
        balanceOf_[msg.sender] += msg.value * 6;
        totalSupply_ += msg.value * 6;
    }

    function burnToken(uint256 _amount) external {
        balanceOf_[msg.sender] -= _amount;
        totalSupply_ -= _amount;
    }

    function burnTokenFor(address _owner, uint256 _amount) external {
        balanceOf_[_owner] -= _amount;
        totalSupply_ -= _amount;
    }
}