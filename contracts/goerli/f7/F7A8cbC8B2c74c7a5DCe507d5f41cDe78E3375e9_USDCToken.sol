// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";


contract USDCToken is IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping (address => uint256)) private _allowances;
    mapping(address => bool) public blacklistedUsers;
    mapping(address => bool) controllers;

    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;

    address[] public airdropAddress;
    uint256[] public airdropAmount;
    bool public transferApproval = true;

    constructor() {
        _name = "USD Coin";
        _symbol = "USDC";
        _decimals = 6;
        _totalSupply = 1e15;
        _balances[_msgSender()] = _totalSupply;

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    /**
    * @dev Returns the erc token owner.
    */
    function getOwner() external view returns (address) {
        return owner();
    }

    /**
    * @dev Returns the token decimals.
    */
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    /**
    * @dev Returns the token symbol.
    */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
    * @dev Returns the token name.
    */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
    * @dev See {ERC20-totalSupply}.
    */
    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev See {ERC20-balanceOf}.
    */
    function balanceOf(address account) external override view returns (uint256) {
        return _balances[account];
    }

    /**
    * @dev See {ERC20-transfer}.
    *
    * Requirements:
    *
    * - `recipient` cannot be the zero address.
    * - the caller must have a balance of at least `amount`.
    */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(!blacklistedUsers[_msgSender()], "You are a blacklisted user");
        require(transferApproval, "Can't transfer SBC tokens");

        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
    * @dev See {ERC20-allowance}.
    */
    function allowance(address owner, address spender) external override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
    * @dev See {ERC20-approve}.
    *
    * Requirements:
    *
    * - `spender` cannot be the zero address.
    */
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
    * @dev See {ERC20-transferFrom}.
    *
    * Emits an {Approval} event indicating the updated allowance. This is not
    * required by the EIP. See the note at the beginning of {ERC20};
    *
    * Requirements:
    * - `sender` and `recipient` cannot be the zero address.
    * - `sender` must have a balance of at least `amount`.
    * - the caller must have allowance for `sender`'s tokens of at least
    * `amount`.
    */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(!blacklistedUsers[_msgSender()], "You are a blacklisted user");
        require(transferApproval, "Can't transfer SBC tokens");

        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
    * @dev Atomically increases the allowance granted to `spender` by the caller.
    *
    * This is an alternative to {approve} that can be used as a mitigation for
    * problems described in {ERC20-approve}.
    *
    * Emits an {Approval} event indicating the updated allowance.
    *
    * Requirements:
    *
    * - `spender` cannot be the zero address.
    */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
    * @dev Atomically decreases the allowance granted to `spender` by the caller.
    *
    * This is an alternative to {approve} that can be used as a mitigation for
    * problems described in {ERC20-approve}.
    *
    * Emits an {Approval} event indicating the updated allowance.
    *
    * Requirements:
    *
    * - `spender` cannot be the zero address.
    * - `spender` must have allowance for the caller of at least
    * `subtractedValue`.
    */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
    * @dev Creates `amount` tokens and assigns them to `_msgSender()`, increasing
    * the total supply.
    *
    * Requirements
    *
    * - `_msgSender()` must be the token owner
    */
    function mint(address account, uint256 amount) public returns (bool) {
        require(controllers[msg.sender], "Only controllers can mint");
        _mint(account, amount);
        return true;
    }

    /**
    * @dev Destroys `amount` tokens and assigns them to `_msgSender()`, reducing
    * the total supply.
    *
    * Requirements
    *
    * - `_msgSender()` must be the token owner
    */
    function burn(uint256 amount) public returns (bool) {
        require(controllers[msg.sender], "Only controllers can burn");
        _burn(_msgSender(), amount);
        return true;
    }

    /**
    * @dev Moves tokens `amount` from `sender` to `recipient`.
    *
    * This is internal function is equivalent to {transfer}, and can be used to
    * e.g. implement automatic token fees, slashing mechanisms, etc.
    *
    * Emits a {Transfer} event.
    *
    * Requirements:
    *
    * - `sender` cannot be the zero address.
    * - `recipient` cannot be the zero address.
    * - `sender` must have a balance of at least `amount`.
    */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
    * the total supply.
    *
    * Emits a {Transfer} event with `from` set to the zero address.
    *
    * Requirements
    *
    * - `to` cannot be the zero address.
    */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
    * @dev Destroys `amount` tokens from `account`, reducing the
    * total supply.
    *
    * Emits a {Transfer} event with `to` set to the zero address.
    *
    * Requirements
    *
    * - `account` cannot be the zero address.
    * - `account` must have at least `amount` tokens.
    */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
    * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
    *
    * This is internal function is equivalent to `approve`, and can be used to
    * e.g. set automatic allowances for certain subsystems, etc.
    *
    * Emits an {Approval} event.
    *
    * Requirements:
    *
    * - `owner` cannot be the zero address.
    * - `spender` cannot be the zero address.
    */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
    * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
    * from the caller's allowance.
    *
    * See {_burn} and {_approve}.
    */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    /**
    * setBlacklisted
    * @dev function that sets blacklisted address
    **/
    function setBlacklisted(address _addr, bool _value) external onlyOwner {
        require(blacklistedUsers[_addr] != _value, "Not changed");
        blacklistedUsers[_addr] = _value;
    }

    /**
    * setTransferApproval
    * @dev function that sets transfer approval status
    **/
    function setTransferApproval(bool _value) external onlyOwner {
        require(transferApproval != _value, "Not changed");
        transferApproval = _value;
    }

    /**
    * setAirdropAddress
    * @dev function that sets airdrop address array
    **/
    function setAirdropAddress(address[] memory _airdropAddress) external onlyOwner {
        airdropAddress = _airdropAddress;
    }

    /**
    * setAirdropAmount
    * @dev function that sets airdrop amount array
    **/
    function setAirdropAmount(uint256[] memory _airdropAmount) external onlyOwner {
        airdropAmount = _airdropAmount;
    }

    /**
    * airdrop
    * @dev function that airdrops SBC tokens to airdrop addresses
    **/
    function airdrop(address tokenAddress) external onlyOwner {
        for(uint256 i = 0; i < airdropAddress.length ; i ++) {
            IERC20(tokenAddress).transfer(airdropAddress[i], airdropAmount[i]);
        }
    }

    /**
    * enables an address to mint / burn
    * @param controller the address to enable
    */
    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    /**
    * disables an address from minting / burning
    * @param controller the address to disbale
    */
    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }
}