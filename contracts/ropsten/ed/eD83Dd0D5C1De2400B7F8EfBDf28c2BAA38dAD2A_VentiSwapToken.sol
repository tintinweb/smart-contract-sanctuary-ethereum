// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract VentiSwapToken is Context {

    // Standard ERC20 Information
    string private constant NAME = "VentiSwap Token";
    string private constant SYMBOL = "VST";
    uint256 private constant TOTAL_SUPPLY = 100000000000000000000000000;

    // Balances and allowances
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    // Blacklist and exemption lists
    mapping (address => bool) private _blacklist;
    mapping (address => bool) private _exemptFromLimits;

    // Management information
    address public owner;
    uint256 public transferLimit = 10000 * 10**18;

    constructor() {
        address sender = _msgSender();
        _balances[sender] = TOTAL_SUPPLY;
        owner = sender;
        _exemptFromLimits[sender];
    }

    // Owner only function modifier

    modifier onlyOwner {
        require(_msgSender() == owner, "Caller must be owner");
        _;
    }

    // ERC20 View Functions

    function name() external pure returns (string memory)
    {
        return NAME;
    }

    function symbol() external pure returns (string memory)
    {
        return SYMBOL;
    }

    function decimals() external pure returns (uint256)
    {
        return 18;
    }

    function totalSupply() external pure returns (uint256)
    {
        return TOTAL_SUPPLY;
    }

    function balanceOf(address account) external view returns (uint256)
    {
        return _balances[account];
    }

    function allowance(address account, address spender) external view returns (uint256)
    {
        return _allowances[account][spender];
    }

    // ERC20 Management View Functions

    /**
     * @dev Returns true if account is added to blacklist mapping.
     *
     * @notice Address will not be able to transfer tokens
     *
     * @return bool showing whether account is in blacklist or not
     */
    function isBlacklisted(address account) external view returns (bool)
    {
        return _blacklist[account];
    }

    /**
     * @dev Returns true if account is exempt from limits
     *
     * @notice This is to be used for funding contracts, exchange addresses, etc.
     *
     * @return bool showing whether account is exempt from limits or not
     */
    function isExemptFromLimit(address account) external view returns (bool)
    {
        return _exemptFromLimits[account];
    }

    // ERC20 Public Mutative Functions

    function approve(address to, uint256 amount) external returns (bool)
    {
        _approve(_msgSender(), to, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool)
    {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool)
    {
        _transfer(_msgSender(), to, amount);
        uint256 currentAllowance = _allowances[from][_msgSender()];
        require(currentAllowance >= amount, "ERC20: Transfer exceeds allowance");
        unchecked {
            _approve(from, _msgSender(), currentAllowance - amount);
        }
        return true;
    }

    // ERC20 Management Mutative Functions

    /**
     * @dev Add account to blacklist
     *
     * @notice Account will no longer be able to send or receive
     *
     * @param account the account to add to list
     */
    function addToBlacklist(address account) external onlyOwner
    {
        _blacklist[account] = true;
    }

    /**
     * @dev Remove account from blacklist
     *
     * @notice Account will be able to send and receive again
     *
     * @param account the account to remove from list
     */
    function removeFromBlacklist(address account) external onlyOwner
    {
        _blacklist[account] = false;
    }

    /**
     * @dev Add account to exemption list
     *
     * @notice Account will not be subject to transfer limits
     *
     * @param account the account to exempt
     */
    function addExemption(address account) external onlyOwner
    {
        _exemptFromLimits[account] = true;
    }

    /**
     * @dev Remove account from exemption list
     *
     * @notice Account will again be subject to transfer limits
     *
     * @param account the account to remove
     */
    function removeExemption(address account) external onlyOwner
    {
        _exemptFromLimits[account] = false;
    }

    /**
     * @dev Change transfer limit amount
     *
     * @notice To remove all limits, set newLimit to total supply
     *
     * @param newLimit the new transfer limit to implement
     */
    function adjustTransferLimit(uint256 newLimit) external onlyOwner
    {
        require(newLimit > 0, "Limit cannot be 0");
        require(newLimit <= TOTAL_SUPPLY, "Amount cannot be greater than supply");
        transferLimit = newLimit;
    }

    /**
     * @dev Transfer ownership to other account
     */
    function transferOwnership(address newOwner) external onlyOwner
    {
        require(newOwner != address(0), "Cannot set owner as 0 addr");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Renounce ownership
     *
     * @notice This is a one way function. There is no way to return ownership.
     */
    function renounceOwnership() external onlyOwner
    {
        _transferOwnership(address(0));
    }

    /**
     * @dev Internal ownership transfer function
     *
     * @notice Logs an event of old and new owners
     */
    function _transferOwnership(address newOwner) private
    {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    // ERC20 Private Mutative Functions

    function _approve(address sender, address spender, uint256 amount) private
    {
        require(sender != address(0), "Cannot approve 0 addr");
        require(spender != address(0), "Cannot approve 0 addr");

        _allowances[sender][spender] = amount;

        emit Approval(sender, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private
    {
        require(from != address(0), "ERC20: Cannot send from 0 addr");
        require(to != address(0), "ERC20: Cannot send to 0 addr");

        _beforeTokenTransfer(from, to, amount);

        uint256 senderBalance = _balances[from];
        require(senderBalance >= amount, "ERC20: Amount exceeds balance");
        unchecked {
            _balances[from] = senderBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) private view {
        require(!_blacklist[from], "Sending account is blacklisted");
        require(!_blacklist[to], "Receiving account is blacklisted");

        if (!_exemptFromLimits[from]) {
            require(amount <= transferLimit, "Amount exceeds transfer limit");
        }
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) private {}

    // ERC20 Events

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

    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
}