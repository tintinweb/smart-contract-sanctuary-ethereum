/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/**
 * @title RoleBasedAccess
 * @dev Implementation of a role-based access control mechanisms.
 * Roles are referred to by their bytes32 identifier.
 */
contract RoleBasedAccess {
    /**
     * @dev Structure to map members.
     */
    struct RoleData {
        mapping(address => bool) members;
    }

    mapping(bytes32 => RoleData) private _roles;

    /**
     * @dev A bytes32 representing the 'ADMIN' role
     */
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

    /**
     * @dev A bytes32 representing the 'MINTER' role
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");

    /**
     * @dev Emitted when `account` is granted `role`. `sender` is the caller account.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`. `sender` is the caller account.
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Grants the 'ADMIN' and 'MINTER' roles to deployer by default.
     */
    constructor() {
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    /**
     * @dev Requires that caller has 'ADMIN' role.
     */
    modifier onlyAdmin() {
        require(_hasRole(ADMIN_ROLE, msg.sender), "RoleBasedAccess: caller does not have the ADMIN role");
        _;
    }

    /**
     * @dev Requires that caller has 'MINTER' role.
     */
    modifier onlyMinter() {
        require(_hasRole(MINTER_ROLE, msg.sender), "RoleBasedAccess: caller does not have the MINTER role");
        _;
    }

    /**
     * @dev Grants `role` to `account`.
     * This can only be executed by callers with 'ADMIN' role.
     * If `account` had not been already granted `role`, emits a 'RoleGranted' event.
     */
    function grantRole(bytes32 role, address account) external onlyAdmin {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     * This can only be executed by callers with 'ADMIN' role.
     * If `account` had been granted `role`, emits a 'RoleRevoked' event.
     */
    function revokeRole(bytes32 role, address account) external onlyAdmin {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     * If the calling account had been granted `role`, emits a 'RoleRevoked' event.
     */
    function renounceRole(bytes32 role) external {
        _revokeRole(role, msg.sender);
    }

    /**
     * @dev Returns a boolean value indicating whether `account` has the role `role` or not.
     */
    function hasRole(bytes32 role, address account) external view returns (bool) {
        return _hasRole(role, account);
    }

    /**
     * @dev This internal function handles the grantRole behavior.
     */
    function _grantRole(bytes32 role, address account) internal {
        if (!_hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    /**
     * @dev This internal function handles the revokeRole behavior.
     */
    function _revokeRole(bytes32 role, address account) internal {
        if (_hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }

    /**
     * @dev This internal function handles the hasRole behavior.
     */
    function _hasRole(bytes32 role, address account) internal view returns (bool) {
        return _roles[role].members[account];
    }
}

pragma solidity 0.8.19;

/**
 * @title CHFPToken
 * @dev Implementation of the 'Swiss Franc and Properties' token.
 */
contract CHFPToken is RoleBasedAccess {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    bool private _mintingFinished = false;

    string private constant _NAME = "Swiss Franc and Properties";
    string private constant _SYMBOL = "CHFP";
    uint8 private constant _DECIMALS = 8;

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Emitted when minting new tokens is disabled.
     */
    event MintFinished();

    /**
     * @dev Requires that minting is not finished.
     */
    modifier canMint() {
        require(!_mintingFinished, "CHFP: minting is finished");
        _;
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     * Emits a 'Transfer' event.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the allowance mechanism.
     * `amount` is then deducted from the caller's allowance.
     * Emits a 'Transfer' event.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(_allowances[from][msg.sender] >= amount, "CHFP: insufficient allowance");
        _allowances[from][msg.sender] -= amount;
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     * Emits an 'Approval' event.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     * Emits an 'Approval' event.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     * Emits an 'Approval' event.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        require(_allowances[msg.sender][spender] >= subtractedValue, "CHFP: decreased allowance below zero");
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing the total supply.
     * This can only be executed by callers with 'MINTER' role.
     * Emits a 'Transfer' event.
     */
    function mint(address account, uint256 amount) external onlyMinter canMint {
        _mint(account, amount);
    }

    /**
     * @dev Disable the ability to mint new tokens.
     * This can only be executed by callers with 'ADMIN' role.
     * Emits a 'MintFinished' event.
     */
    function finishMinting() external onlyAdmin canMint {
        _mintingFinished = true;
        emit MintFinished();
    }

    /**
     * @dev Destroys `amount` tokens from caller, reducing the total supply.
     * Emits a 'Transfer' event.
     */
    function burn(uint256 amount) external {
        require(_balances[msg.sender] >= amount, "CHFP: burn amount exceeds balance");
        _balances[msg.sender] -= amount;
        _totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

    /**
     * @dev Returns the amount which `spender` is still allowed to withdraw from `owner`.
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external pure returns (string memory) {
        return _NAME;
    }

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external pure returns (string memory) {
        return _SYMBOL;
    }

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external pure returns (uint8) {
        return _DECIMALS;
    }

    /**
     * @dev Returns the total existent token supply.
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Returns a boolean value indicating whether the minting is finished or not.
     */
    function mintingFinished() external view returns (bool) {
        return _mintingFinished;
    }

    /**
     * @dev This internal function handles the transfer behavior.
     */
    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "CHFP: transfer to the zero address");
        require(_balances[from] >= amount, "CHFP: transfer amount exceeds balance");
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    /**
     * @dev This internal function handles the approve behavior.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(spender != address(0), "CHFP: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev This internal function handles the mint behavior.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "CHFP: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
}