/**
 *Submitted for verification at BscScan.com on 2022-03-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Burn(address indexed from, uint256 value);
}

contract Janex is IERC20 {
    uint256 private constant eighteen_decimals_value =
        1_000_000_000_000_000_000;
    // ERC20 variables
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply = 1_000_000_000 * eighteen_decimals_value;

    // General variables
    string public constant name = "Janex";
    string public constant symbol = "JNX";
    uint8 public constant decimals = 18;
    address public _admin;
    address public _valid;
    // Utility variables
    bool public _isPaused;
    mapping(address => bool) public _isPausedAddress;

    constructor() {
        _admin = msg.sender;
        _balances[address(this)] = _totalSupply;
        _initialTransfer();
    }

    function _initialTransfer() private {
        _transfer(
            address(this),
            0x71E21D04AD441eB55dB77E7a55Bc86401042A1A0,
            50_000_000 * eighteen_decimals_value
        ); // Marketing
        _transfer(
            address(this),
            0x229A4F87Da4E2aE17508294fE745C3FA68c20E18,
            50_000_000 * eighteen_decimals_value
        ); // Token allocation for tax/fee
        _transfer(
            address(this),
            0x73a05c21AF2Dcf0B2a69b6FBAB2A2e8F8aAdD31e,
            130_000_000 * eighteen_decimals_value
        ); // Development
        _transfer(
            address(this),
            0xAf1A5B49A286b373c8cf932F0F6F63842030a164,
            500_000_000 * eighteen_decimals_value
        ); // Public Sale

        _transfer(
            address(this),
            0xaa00d9C068B5f806d03b2D29A650CB80b6Bf5C6a,
            20_000_000 * eighteen_decimals_value
        ); // Team
        _transfer(
            address(this),
            0x9e89cC968f10C6D25152CA9256a1dB2af87F2277,
            250_000_000 * eighteen_decimals_value
        ); // Private Sale
    }

    /**
     * Modifiers
     */
    modifier onlyAdmin() {
        // Is Admin?
        require(_admin == msg.sender);
        _;
    }

    modifier whenPaused() {
        // Is pause?
        require(_isPaused, "Pausable: not paused Erc20");
        _;
    }

    modifier whenNotPaused() {
        // Is not pause?
        require(!_isPaused, "Pausable: paused Erc20");
        _;
    }

    // Transfer ownernship
    function transferOwnership(address payable admin) external onlyAdmin {
        require(admin != address(0), "Zero address");
        _admin = admin;
    }

    /**
     * ERC20 functions
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] - subtractedValue
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(!_isPaused, "ERC20Pausable: token transfer while paused");
        require(
            !_isPausedAddress[sender],
            "ERC20Pausable: token transfer while paused on address"
        );
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(
            recipient != address(this),
            "ERC20: transfer to the token contract address"
        );

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function pause() external onlyAdmin whenNotPaused {
        _isPaused = true;
    }

    function unpause() external onlyAdmin whenPaused {
        _isPaused = false;
    }

    function pausedAddress(address sender) external onlyAdmin {
        _isPausedAddress[sender] = true;
    }

    function unPausedAddress(address sender) external onlyAdmin {
        _isPausedAddress[sender] = false;
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public onlyAdmin returns (bool success) {
        require(_balances[address(this)] >= _value);
        _balances[address(this)] -= _value;
        _totalSupply -= _value;
        emit Burn(address(this), _value);
        return true;
    }

    /**
     * Destroy tokens ( wallet )
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burnWallet(uint256 _value) public returns (bool success) {
        require(_balances[msg.sender] >= _value);
        _balances[msg.sender] -= _value;
        _totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    receive() external payable {
        revert();
    }
}