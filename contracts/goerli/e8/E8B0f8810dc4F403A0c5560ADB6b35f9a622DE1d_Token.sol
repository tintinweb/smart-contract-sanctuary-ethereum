/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

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

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }


    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }


    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

   
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

}
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}





contract Token is ERC20, Ownable, ReentrancyGuard {
    uint256 private _tax;

    uint256 private immutable _slope;

    uint256 private _loss_fee_percentage = 1000;

    uint256 private mintCap = 100;
    uint256 private supplyCap = 1000000000;

    event tokensBought(address indexed buyer, uint amount, uint total_supply, uint newPrice);
    event tokensSold(address indexed seller, uint amount, uint total_supply, uint newPrice);
    event withdrawn(address from, address to, uint amount, uint time);

    constructor () ERC20("DSS", "SSD") {
        _slope = 1;
        supplyCap = 100000000000;
    }

    function buy(uint256 _amount) external nonReentrant payable {
        require(totalSupply() + _amount <= supplyCap, "Exceeds supply cap");
        uint price = _calculatePriceForBuy(_amount);
        require(msg.value>=price,"Send Price is low");
        require(_amount <= mintCap , "Value Exceed MintCap");
        _mint(msg.sender, _amount);
        
        (bool sent,) = payable(msg.sender).call{value: msg.value - price}("");
        require(sent, "Failed to send Ether");

        emit tokensBought(msg.sender, _amount, totalSupply(), getCurrentPrice());
    }

    function sell(uint256 _amount) external nonReentrant {
        require(balanceOf(msg.sender) >= _amount,"Not enough tokens");
        uint256 _price = _calculatePriceForSell(_amount);
        uint tax = _calculateLoss(_price);
        _burn(msg.sender, _amount);
        _tax += tax;

        (bool sent,) = payable(msg.sender).call{value: _price - tax}("");
        require(sent, "Failed to send Ether");

        emit tokensSold(msg.sender, _amount, totalSupply(), getCurrentPrice());
    }

    function withdraw() external onlyOwner nonReentrant {
        
        require(_tax > 0,"Low On Ether");
        uint amount = _tax;
        _tax = 0;
        
        (bool sent,) = payable(owner()).call{value: amount}("");
        require(sent, "Failed to send Ether");

        emit withdrawn (address(this), msg.sender, amount, block.timestamp);
    }

    function getCurrentPrice() public view returns (uint) {
        return _calculatePriceForBuy(1);
    }

    function calculatePriceForBuy(
        uint256 _tokensToBuy
    ) external view returns (uint256) {
        return _calculatePriceForBuy(_tokensToBuy);
    }

    function calculatePriceForSell(
        uint256 _tokensToSell
    ) external view returns (uint256) {
        return _calculatePriceForSell(_tokensToSell);
    }

    function _calculatePriceForBuy(
        uint256 _tokensToBuy
    ) private view returns (uint256) {
        uint ts = totalSupply();
        uint tsa = ts + _tokensToBuy;
        return area_under_the_curve(tsa) - area_under_the_curve(ts);
    }

    function _calculatePriceForSell(
        uint256 _tokensToSell
    ) private view returns (uint256) {
        uint ts = totalSupply();
        uint tsa = ts - _tokensToSell;
        return area_under_the_curve(ts) - area_under_the_curve(tsa);
    }

    function area_under_the_curve(uint x) internal view returns (uint256) {
        return (_slope * (x ** 2)) / 2 ;
    }

    function _calculateLoss(uint256 amount) private view returns (uint256) {
        return (amount * _loss_fee_percentage) / (1E4);
    }

    function viewTax() external view onlyOwner returns (uint256) {
        
        return _tax;
    }

    function setLoss(uint _loss) external onlyOwner returns (uint256) {
        
        require(_loss_fee_percentage < 5000, "require loss to be >= 1000 & < 5000");
        _loss_fee_percentage = _loss;
        return _loss_fee_percentage;
    }

    function setMintCap(uint _mintCap) external onlyOwner returns (uint256) {
        
        require(mintCap >= 10, "value should be greater than 10");
        mintCap = _mintCap;
        return mintCap;
    }

    function setSupplyCap(uint _cap) external onlyOwner returns (uint256) {
        
        require(_cap >= totalSupply(), "value cannot be less than total supply");
        supplyCap = _cap;
        return supplyCap;
    }

    

    function builtwith() external pure returns(string memory){
        return "BuildMyToken_v2.0";
    }
}