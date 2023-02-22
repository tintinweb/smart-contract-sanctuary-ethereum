/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 * ----------------------------------------------------------------------------
 * @title RetroZone token contract
 * Name         : RetroZone ($RZT)
 * dApp         : app.retrozonetoken.com
 * Telegram     : t.me/RetroZoneSecretLink
 * Medium       : medium.com/@retrozonetoken
 * Whitepaper   : retrozonetoken.gitbook.io/retro-zone
 * Twitter      : twitter.com/RZArcadeManager
 * Console      : console.retrozonetoken.com
 * ----------------------------------------------------------------------------
 * Website      : https://www.retrozonetoken.com
 * Author/Dev   : @ArcadeManager
 * ----------------------------------------------------------------------------
 *    $$$$$$$\            $$\                         
 *    $$  __$$\           $$ |                        
 *    $$ |  $$ | $$$$$$\$$$$$$\    $$$$$$\   $$$$$$\  
 *    $$$$$$$  |$$  __$$\_$$  _|  $$  __$$\ $$  __$$\ 
 *    $$  __$$< $$$$$$$$ |$$ |    $$ |  \__|$$ /  $$ |
 *    $$ |  $$ |$$   ____|$$ |$$\ $$ |      $$ |  $$ |
 *    $$ |  $$ |\$$$$$$$\ \$$$$  |$$ |      \$$$$$$  |
 *    \__|  \__| \_______| \____/ \__|       \______/ 
 *    $$$$$$$$\                                       
 *    \____$$  |                                      
 *        $$  /$$$$$$\  $$$$$$$\   $$$$$$\            
 *       $$  /$$  __$$\ $$  __$$\ $$  __$$\           
 *      $$  / $$ /  $$ |$$ |  $$ |$$$$$$$$ |          
 *     $$  /  $$ |  $$ |$$ |  $$ |$$   ____|          
 *    $$$$$$$$\$$$$$$  |$$ |  $$ |\$$$$$$$\           
 *    \________\______/ \__|  \__| \_______|          
 *                                                                                                   
 */


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
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
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

//  Author/Dev   : @ArcadeManager

contract RetroZone is Ownable, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping(address => mapping(address => uint256)) private _allowances;

    string constant private _name = "RetroZone";
    string constant private _symbol = "RTZ";
    uint8  constant private _decimal = 10;
    uint256 private _totalSupply = 100000000 * (10 ** _decimal);
    uint256 constant public _taxBurn = 20; // 2% 
    uint256 constant public _taxLiquidity = 10; // 1%
    address public teamWallet; // 0x46f95C2752E64354eb6BAf0a2a9cEb018a1C2005
    uint256 public toBurnAmount = 0;

    event teamWalletChanged(address oldWalletAddress, address newWalletAddress);
    event feeCollected(address teamWallet, uint256 amount);
    event excludingAddressFromFee(address account);
    event includingAddressInFee(address account);

    modifier onlyTeamWallet() {
        require(teamWallet == _msgSender(), "Caller is not the teamwallet");
        _;
    }

    constructor(address _teamWallet) {
        require(_teamWallet!=address(0), "Cannot set teamwallet as zero address");
        _balances[_msgSender()] = _totalSupply;
        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_teamWallet] = true;
        teamWallet = _teamWallet;  
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }
    
    function name() external view virtual override returns (string memory) {
        return _name;
    }

    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }
    
    function decimals() external view virtual override returns (uint8) {
        return _decimal;
    }
    
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) external view virtual override returns (uint256) {
        return _balances[account];
    }
    
    function collectedFees() external view returns (uint256) {
        return _balances[address(this)];
    }

    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function excludeFromFee(address account) external onlyOwner {
        require(account!=address(0), "Excluding for the zero address");
        _isExcludedFromFee[account] = true;
        emit excludingAddressFromFee(account);
    }

    function isExcludedFromFee(address account) external view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function includeInFee(address account) external onlyOwner {
        require(account!=address(0), "Including for the zero address");
        _isExcludedFromFee[account] = false;
        emit includingAddressInFee(account);
    }

    function collectFees() external onlyOwner {
        uint256 fees = _balances[address(this)];
        _transfer(address(this), teamWallet, _balances[address(this)]);
        emit feeCollected(teamWallet, fees);
    }

    function burnCollectedFees() external onlyTeamWallet {
        require(_balances[teamWallet] >= toBurnAmount, "Does not have the required amount of tokens to burn");
        _transfer(teamWallet, address(0), toBurnAmount);
        _totalSupply -= toBurnAmount;
        toBurnAmount = 0;
        emit feeCollected(address(0), toBurnAmount);
    }

    function updateTeamWallet(address _teamWallet) external onlyOwner {
        require(_teamWallet!=address(0), "Cannot set teamwallet as zero address");
        address oldWallet = teamWallet;
        teamWallet =  _teamWallet;
        _isExcludedFromFee[_teamWallet] = true;
        _isExcludedFromFee[oldWallet] = false;
        emit teamWalletChanged(oldWallet,_teamWallet);
    }
    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        require(spender!=address(0), "Increasing allowance for zero address");
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        require(spender!=address(0), "Decreasing allowance for zero address");
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
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        if(_isExcludedFromFee[sender]) {
            unchecked {//condititon to exclude
                _balances[recipient] += amount;
            }
        }else{ 
            unchecked {
                uint256 burnFee =  (amount * _taxBurn) / 1000;
                uint256 tFee = (amount * (_taxBurn + _taxLiquidity)) / 1000;
                amount = amount - tFee;
                _balances[recipient] += amount;
                _balances[address(this)] +=  tFee;
                toBurnAmount += burnFee;
            }
        }
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
}

 // dApp         : app.retrozonetoken.com