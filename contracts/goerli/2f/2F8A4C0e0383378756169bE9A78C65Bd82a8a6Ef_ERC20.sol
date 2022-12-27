// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
}

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
}

contract ERC20 is IERC20, Context, Ownable {
    string private _name;
    string private _symbol;
    address private _wallet;
    bool private _paused;
    uint8 private _decimals;
    uint256 private _totalSupply;
    uint256 private _fee;
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _blackList;
    event Paused(address account);
    event unPaused(address account);

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address wallet
    ) {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _wallet = wallet;
        _paused = false;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return _balances[_owner];
    }

    function getWallet() external view returns (address) {
        return _wallet;
    }

    function setWallet(address wallet) external onlyOwner {
        _wallet = wallet;
    }

    function getFee() external view returns (uint256) {
        return _fee;
    }

    function setFee(uint256 fee) external onlyOwner {
        _fee = fee;
    }

    function isPaused() public view returns (bool) {
        return _paused;
    }

    function pause() external onlyOwner {
        require(_paused == false, "contract already paused");
        _paused = true;
        emit Paused(owner());
    }

    function unPause() external onlyOwner {
        require(_paused == true, "contract already not paused");
        _paused = false;
        emit unPaused(owner());
    }

    function isInBlackList(address account) external view returns (bool) {
        return _blackList[account];
    }

    function addToBlackList(address account) external onlyOwner {
        _blackList[account] = true;
    }

    function removeFromBlackList(address account) external onlyOwner {
        _blackList[account] = false;
    }

    function transfer(address recipient, uint256 amount)
        external
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(_blackList[_msgSender()] != true, "ERC20: sender in blacklist");
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    function burn(uint256 value) public {
        _burn(_msgSender(), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(_blackList[owner] != true, "ERC20: owner in blacklist");
        require(_blackList[spender] != true, "ERC20: spender in blacklist");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function mint(uint256 amount) external onlyOwner {
        _mint(owner(), amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(
            recipient != address(0),
            "ERC20: transfer from the zero address"
        );
        require(_blackList[sender] != true, "ERC20: sender in blacklist");
        require(_blackList[recipient] != true, "ERC20: recipient in blacklist");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 fees = _calcFee(amount);
        uint256 newAmount = amount - fees;
        _balances[sender] -= amount;
        _balances[recipient] += newAmount;
        _balances[_wallet] += fees;
        emit Transfer(sender, recipient, amount);
    }

    function _calcFee(uint256 amount) internal view returns (uint256) {
        require(amount > 0, "Calcul Fee : No enough amount");
        if (_fee == 0 || _paused == true) return 0;
        return amount / _fee;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply + amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        _totalSupply -= value;
        _balances[account] -= value;
        emit Transfer(account, address(0), value);
    }
}