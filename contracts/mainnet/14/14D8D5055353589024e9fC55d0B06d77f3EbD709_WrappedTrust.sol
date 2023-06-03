/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: UNLICENSED

// Website: https://www.thetrustco.in/

pragma solidity 0.8.20;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
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

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

library Address {
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract WrappedTrust is ERC20, Ownable {
    IERC20 public trust;

    address public trustAddress = 0xD4074c1E48E11615fD1cfE8cbE691F5ab944aAa6;
    address public marketingWalet = 0x84874cD121274690D972137e65C8AcA0937d0Af6;
    address public devWallet = 0x25Eff24DF1D8C0F6f891AADcF4cdEc03529818D5;

    uint256 public randomNumberThreshold = 26;
    bool public wrapping;
    bool public unWrapping;

    event Wrapped(address indexed from, address indexed to, uint256 amount, uint256 feeCharged, uint256 time);
    event UnWrapped(address indexed from, address indexed to, uint256 amount, uint256 feeCharged, uint256 time);

    constructor() ERC20("Wrapped Trust", "WTRUST") Ownable() {
        trust = IERC20(trustAddress);
        wrapping = false;
        unWrapping = false;
        _mint(_msgSender(), 26e9 * 10 ** 18);
    }

    function random() public view returns (uint) {
        uint randomHash = uint(keccak256(abi.encodePacked(block.prevrandao, block.timestamp)));
        uint randamTax = randomHash % randomNumberThreshold;
        return randamTax;
    }

    function wrap(uint256 amount) public {
        require(trust.balanceOf(_msgSender()) >= amount, "ERORR: not enough balance");
        require(wrapping, "ERROR: wrapping is locked");
        require(trust.allowance(_msgSender(), address(this)) >= amount, "ERROR: tokens not approved");

        uint256 fee = random();
        uint256 feeAmount = (amount * fee) / 100;
        uint256 tokenAmount = amount - feeAmount;

        trust.transferFrom(_msgSender(), marketingWalet, feeAmount);
        trust.transferFrom(_msgSender(), devWallet, tokenAmount);

        _mint(_msgSender(), tokenAmount);
        _mint(address(this), feeAmount);

        emit Wrapped(address(this), _msgSender(), amount, fee, block.timestamp);
    }

    function unWrap(uint256 amount) public {
        require(balanceOf(_msgSender()) >= amount, "ERORR: not enough balance");
        require(unWrapping, "ERROR: unWrapping is locked");
        require(trust.allowance(devWallet, address(this)) >= amount, "ERROR: tokens not approved");

        uint256 fee = random();
        uint256 feeAmount = (amount * fee) / 100;
        uint256 tokenAmount = amount - feeAmount;

        _burn(_msgSender(), amount);

        trust.transferFrom(devWallet, marketingWalet, feeAmount);
        trust.transferFrom(devWallet, _msgSender(), tokenAmount);

        emit UnWrapped(_msgSender(), address(this), amount, fee, block.timestamp);
    }

    function devMint(uint256 amount) public onlyOwner {
        _mint(_msgSender(), amount);
    }

    function changeRandomNumberThreshold(uint256 _newValue) public onlyOwner {
        randomNumberThreshold = _newValue;
    }

    function startSale() public onlyOwner {
        wrapping = true;
        unWrapping = true;
    }

    function stopWrapping() public onlyOwner {
        wrapping = false;
    }

    function stopUnWrapping() public onlyOwner {
        unWrapping = false;
    }
}