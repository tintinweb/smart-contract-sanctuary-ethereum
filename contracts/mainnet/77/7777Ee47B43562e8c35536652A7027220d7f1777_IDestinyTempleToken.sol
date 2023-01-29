/**
 *Submitted for verification at Etherscan.io on 2023-01-29
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
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

// File: contracts/DestinyTemple_Token.sol
pragma solidity ^0.8.10;
/// @notice Main,Destiny Governance Token.
contract IDestinyTempleToken is IERC20{
    address constant private OWNER = address(0);
    string constant private NAME = "Destiny";
    string constant private SYMBOL = "DIY";
    uint constant private DECIMALS = 2;
    uint256 constant private TOTALSUPPLY = 1999999;
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) private  _balances;
    mapping (address => mapping (address => uint256)) private  _allowances;

    modifier msgSenderNotZero(){
        require(msg.sender != address(0), "ERC20: transfer from the zero address.");
        _;
    }
    modifier verifyBalance(address sender,uint256 value){
        require(_balances[sender] >= value,"ERC20: transfer amount exceeds balance.");
        _;
    }
    modifier verifyAllowance(uint256 _allowance,uint256 value){
        require(_allowance >= value,"ERC20: transfer amount exceeds allowance");
        _;
    }
    constructor(){            
        _balances[0x00001C1D6ab92F943eD4A31dA8F447Fd96589960] = TOTALSUPPLY;
    }
    function owner() external pure returns (address) {
        return OWNER;
    }
    function name() external pure returns (string memory) {
        return NAME;
    }
    function symbol() external pure returns (string memory) {
        return SYMBOL;
    }
    function decimals() external pure returns (uint) {
        return DECIMALS;
    }
    function totalSupply() external pure returns (uint256) {
        return TOTALSUPPLY;
    }
    function balanceOf(address _owner) external view returns (uint256) {
        return _balances[_owner];
    }
    function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
        return _allowances[_owner][_spender];
    }
    /// @notice Transfer _value amount of tokens to recipient;
    function transfer(address recipient, uint256 _value) external msgSenderNotZero verifyBalance(msg.sender,_value)  returns (bool) {
        _balances[msg.sender] -= _value;
        _balances[recipient] += _value;

        emit Transfer(msg.sender, recipient, _value);
        return true;
    }
    ///@notice Transfer _value tokens from the sender who has authorized you to the recipient.
    function transferFrom(address sender, address recipient, uint256 _value) external msgSenderNotZero verifyBalance(sender,_value) verifyAllowance(_allowances[sender][msg.sender],_value) returns (bool) {        
        _balances[sender] -= _value;
        _balances[recipient] += _value;
        if (_allowances[sender][msg.sender] < MAX_UINT256) {
            _allowances[sender][msg.sender] -= _value;
        }

        emit Transfer(sender, recipient, _value);
        return true;
    }
    /// @notice Grant _spender the right to control your _value amount of the token.
    function approve(address sender, uint256 _value) external  msgSenderNotZero returns (bool success) {
        _allowances[msg.sender][sender] = _value;

        emit Approval(msg.sender, sender, _value);
        return true;
    }
}