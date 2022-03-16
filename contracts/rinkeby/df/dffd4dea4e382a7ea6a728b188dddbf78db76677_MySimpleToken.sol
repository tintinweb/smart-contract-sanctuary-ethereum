/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    /**
     * @dev Burns the `amount` of tokens from the caller's address
     */
    function burn(uint256 amount) external;

    /**
     * @dev Transfers `tokens` amount of tokens to address `to` and fires the Transfer event.
     * Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.
     */
    function transfer(address to, uint tokens) external returns (bool);

    /**
     * @dev Allows `spender` to withdraw from your account multiple times, up to the `tokens` amount.
     * If this function is called again it overwrites the current allowance with `tokens`
     */
    function approve(address spender, uint tokens) external returns (bool);

    /**
     * @dev Transfers `tokens` amount of tokens from address `from` to address `to` and fires the Transfer event.
     * Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.
     */
    function transferFrom(address from, address to, uint tokens) external returns (bool);

    /**
     * @dev Emits the `amount` of tokens to the `to` address
     */
    function mint(address recipient, uint256 amount) external;

    /**
     * @dev Returns the amount which `spender` is still allowed to withdraw from `tokenOwner`.
     */
    function allowance(address tokenOwner, address spender) external view returns (uint);

    /**
     * @dev Returns the owner of the contract instance
     */
    function minter() external view returns (address);

    /**
     * @dev Returns the total token supply.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the account balance of another account with address `tokenOwner`.
     */
    function balanceOf(address tokenOwner) external view returns (uint);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the number of decimals the token uses - e.g. 8, means to divide the token amount by 100000000 to get its user representation.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev MUST trigger on any successful call to approve function
     */
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    /**
     * @dev MUST trigger when tokens are transferred, including zero value transfers.
     */
    event Transfer(address indexed from, address indexed to, uint tokens);
}

contract MySimpleToken is IERC20 {

    address private _minter;

    string private _name;

    string private _symbol;

    uint8 private _decimals;

    uint256 private _totalSupply;

    mapping(address => uint256) private balances;

    /**
     * @dev X => Y => A means that the X has allowed the Y to transfer the A amount of the X's tokens
     */
    mapping(address => mapping (address => uint256)) private _allowance;

    modifier onlyMinter() {
        require(msg.sender == _minter, 'Only the minter is allowed to perform that operation');
        _;
    }

    constructor(uint256 initialSupply) {
        _name = "MySimpleToken";
        _symbol = "MST";
        _decimals = 18; //industry standard
        _minter = msg.sender;
        mint(msg.sender, initialSupply);
    }

    function burn(uint256 amount) external override {
        require(balances[msg.sender] >= amount, 'The caller does not hold sufficient amount of tokens');

        balances[msg.sender] -= amount;
        _totalSupply -= amount;

        emit Transfer(msg.sender, address(0), amount);
    }

    function transfer(address to, uint tokens) public override returns (bool) {
        require(to != address(0), "Transfer to the zero address is not allowed");
        require(balances[msg.sender] >= tokens, 'Sender account does not hold sufficient balance');

        balances[msg.sender] -= tokens;
        balances[to] += tokens;

        emit Transfer(msg.sender, to, tokens);

        return true;
    }

    function approve(address spender, uint tokens) public override returns (bool) {
        _allowance[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);

        return true;
    }

    function transferFrom(address from, address to, uint tokens) public override returns (bool) {
        require(to != address(0), "Transfer to the zero address is not allowed");
        require(balances[from] >= tokens, 'Source address does not hold sufficient balance');
        require(_allowance[from][msg.sender] >= tokens, 'The caller is not allowed to transfer that amount of tokens');

        balances[from] -= tokens;
        _allowance[from][msg.sender] -= tokens;
        balances[to] += tokens;

        emit Transfer(from, to, tokens);

        return true;
    }

    function mint(address to, uint256 amount) public override onlyMinter {
        require(to != address(0), "Minting to zero address is not allowed");

        _totalSupply += amount;
        balances[to] += amount;

        emit Transfer(address(0), to, amount);
    }

    function allowance(address tokenOwner, address spender) public override view returns (uint) {
        return _allowance[tokenOwner][spender];
    }

    function minter() public override view returns (address) {
        return _minter;
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public override view returns (uint) {
        return balances[tokenOwner];
    }

    function name() public override view returns (string memory) {
        return _name;
    }

    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    function decimals() public override view returns (uint8) {
        return _decimals;
    }
}