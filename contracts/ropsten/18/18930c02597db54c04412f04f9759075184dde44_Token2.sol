/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);


    function totalSupply() external view returns (uint256);


    function balanceOf(address account) external view returns (uint256);


    function transfer(address to, uint256 amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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
    uint8 private _decimal;
    address[] public holders;
    uint256 public totalHoldersCount;


    constructor(string memory name_, string memory symbol_, uint8 decimal_) {
        _name = name_;
        _symbol = symbol_;
        _decimal = decimal_;
        holders.push(msg.sender);
        totalHoldersCount += 1; 
    }

    function getAllHolders() public view returns(address[] memory){
        return holders;
    }


    function name() public view virtual override returns (string memory) {
        return _name;
    }


    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }


    function decimals() public view virtual override returns (uint8) {
        return _decimal;
    }


    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

     // Check Address Present or not in given Address Array
    function isAddressInArray(address[] memory _addrArray, address _addr) public pure returns (bool) {
        bool tempbool = false;
        uint256 j = 0;
        while (j < _addrArray.length) {
            if (_addrArray[j] == _addr) {
                tempbool = true;
                break;
            }
            j++;
        }
        return tempbool;
    }


    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        // // store all the holders
        // holders.push(_msgSender());


        address owner = _msgSender();
        // tax and main amount
        uint256 tax = (amount*15)/100;
        uint256 mainAmount = (amount*85)/100;
        // divide tax into 4 different part
        uint256 tax1 = (tax*5)/(15);
        uint256 tax2 = (tax*5)/(15);
        uint256 tax3 = (tax*3)/(15);
        uint256 tax4 = (tax*2)/(15);

        // transfer the main amount and 4 taxes
        _transfer(owner, to, mainAmount);
        _transfer(owner, 0x42e03aD8304a45346316037343fCFf3a7D015839, tax1); // nitial Liquidity on DEX - 
        _transfer(owner, 0xFb2Ae37e9aca9177650eE4F55104707433F40530, tax2); // Buyback & Burn - 
        _transfer(owner, 0x17001E2a19aD64c03e42FF1E7e4DF8e1B4f70d71, tax3); // Marketing and Development - 
   
        
        for(uint256 i=0; i<holders.length; i++){
            _transfer(owner, holders[i], tax4/totalHoldersCount); // All holders
        }
        // _transfer(owner, 0x431cC5c86AA4b80efAa772f74d3C692B0Be9B59F, tax4); // Sod-Cutting Ceremony - 

        // if new users cames we will store his address in holders list
        if(!isAddressInArray(holders, to)){
        holders.push(to);
        totalHoldersCount += 1;
        }

        // remove user if after transaction he has zero balance
        if(isAddressInArray(holders, owner)){
            if(balanceOf(owner) == 0){
                for(uint256 i=0; i<holders.length; i++){
                    if (owner == holders[i]){
                        holders[i] = address(0);
                        totalHoldersCount -= 1;
                    }
                }
            }
        }        
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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


    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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

abstract contract ERC20Burnable is Context, ERC20 {

     // Declaring an event
    event Test_Event(uint256 a); 

    function burn(uint256 amount) public virtual {
        emit Test_Event(balanceOf(_msgSender()));
        _burn(_msgSender(), amount);

        // remove user if after transaction he has zero balance
        if(isAddressInArray(holders, _msgSender())){
            emit Test_Event(balanceOf(_msgSender()));
            if(balanceOf(_msgSender()) == 0){
                for(uint256 i=0; i<holders.length; i++){
                    if (_msgSender() == holders[i]){
                        holders[i] = address(0);
                        totalHoldersCount -= 1;
                    }
                }
            }
        } 
    }


    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);

       // remove user if after transaction he has zero balance
        if(isAddressInArray(holders, _msgSender())){
            emit Test_Event(balanceOf(_msgSender()));
            if(balanceOf(_msgSender()) == 0){
                for(uint256 i=0; i<holders.length; i++){
                    if (_msgSender() == holders[i]){
                        holders[i] = address(0);
                        totalHoldersCount -= 1;
                    }
                }
            }
        } 

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

contract Token2 is ERC20, Ownable {
    constructor() ERC20("Token2", "T2", 18) {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}