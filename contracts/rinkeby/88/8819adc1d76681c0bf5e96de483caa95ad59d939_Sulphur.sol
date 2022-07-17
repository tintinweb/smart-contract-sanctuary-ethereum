/**
 *Submitted for verification at Etherscan.io on 2022-07-17
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

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

    /*
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    */

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
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
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

    function transferFrom(address sender, address recipient, uint256 amount ) public virtual override returns (bool) {
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

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        
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

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract Sulphur is ERC20, Ownable {
    using SafeMath for uint256;

    address public ownerWallet;
    address public treasuryWallet;
    address public developmentWallet;
    address public poolWallet;

    uint256 public buyTreasuryFee;
    uint256 public buyDevelopmentFee;
    uint256 public buyTotalFees;
    
    uint256 public sellTreasuryFee;
    uint256 public sellDevelopmentFee;
    uint256 public sellTotalFees;

    uint256 public tokensForTreasury;
    uint256 public tokensForDevelopment;
    
    mapping (address => bool) public poolAddress;
    mapping (address => bool) public whitelist;

    mapping(address => uint256) balances;

    event eUpdateOwnerWallet(address indexed newWallet, address indexed oldWallet);
    event eUpdateTreasuryWallet(address indexed newWallet, address indexed oldWallet);
    event eUpdateDevelopmentWallet(address indexed newWallet,address indexed oldWallet);
    event eUpdatePoolWallet(address indexed newWallet, address indexed oldWallet);

    constructor() ERC20("Sulphur", "SLPHRXYZ") {
        ownerWallet = address(0x1B930861911E98A1Fe005fAc855C7973Be9fc8A3);
        treasuryWallet = address(0x9B86f9035B21aeFBd3344903ee276D6Dd3513E0D);
        developmentWallet = address(0xCd4f3C9E000cdB3baC72719CE67d46C488D924EF); 
        poolWallet = address(0);

        uint256 _buyTreasuryFee = 1;
        uint256 _buyDevelopmentFee = 2;

        uint256 _sellTreasuryFee = 3;
        uint256 _sellDevelopmentFee = 4;

        uint256 _totalSupply = 1_000_000  * 1e18;
        
        buyTreasuryFee = _buyTreasuryFee;
        buyDevelopmentFee = _buyDevelopmentFee;
        buyTotalFees = buyTreasuryFee + buyDevelopmentFee;

        sellTreasuryFee = _sellTreasuryFee;
        sellDevelopmentFee = _sellDevelopmentFee;
        sellTotalFees = sellTreasuryFee + sellDevelopmentFee;

        _mint(msg.sender, _totalSupply);
    }
   
    receive() external payable {}

    function updateOwnerWallet(address newOwnerWallet) external onlyOwner    {
        emit eUpdateOwnerWallet(newOwnerWallet, ownerWallet);
        ownerWallet = newOwnerWallet;
    }

    function updateTreasuryWallet(address newTreasuryWallet) external onlyOwner    {
        emit eUpdateTreasuryWallet(newTreasuryWallet, treasuryWallet);
        treasuryWallet = newTreasuryWallet;
    }

    function updateDevelopmentWallet(address newDevelopmentWallet) external onlyOwner {
        emit eUpdateDevelopmentWallet(newDevelopmentWallet, developmentWallet);
        developmentWallet = newDevelopmentWallet;
    }

    function updatePoolWallet(address newPoolWallet) external onlyOwner {
        emit eUpdatePoolWallet(newPoolWallet, poolWallet);
        poolWallet = newPoolWallet;
    }

    function updateBuyFee( uint256 _treasuryFee, uint256 _developmentFee) external onlyOwner {
        buyTreasuryFee = _treasuryFee;
        buyDevelopmentFee = _developmentFee;
        buyTotalFees = buyTreasuryFee + buyDevelopmentFee;
        require(buyTotalFees <= 25, "Buy tax is 25% or less");
    }

    function updateSellFee( uint256 _treasuryFee, uint256 _devFee) external onlyOwner {
        sellTreasuryFee = _treasuryFee;
        sellDevelopmentFee = _devFee;
        sellTotalFees = sellTreasuryFee + sellDevelopmentFee;
        require(sellTotalFees <= 50, "Sell tax is 50% or less");
    }
    
    function setPoolAddress(address a, bool b) public onlyOwner {
        poolAddress[a] = b;
    }

    function setWhitelist(address a, bool b) public onlyOwner {
        whitelist[a] = b;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
       
        bool boolFee = true;
        uint256 totalFee = 0;
       
        if (whitelist[from] || whitelist[to]) {
            boolFee = false;
        }
       
        if (boolFee) {
           if ((from == poolWallet) && buyTotalFees > 0) {
                totalFee = amount.mul(buyTotalFees).div(100);
                tokensForDevelopment += (totalFee * buyDevelopmentFee) / buyTotalFees;
                tokensForTreasury += (totalFee * buyTreasuryFee) / buyTotalFees;
            } 
            else if ((to == poolWallet) && sellTotalFees > 0) {
                totalFee = amount.mul(sellTotalFees).div(100);
                tokensForDevelopment += (totalFee * sellDevelopmentFee) / sellTotalFees;
                tokensForTreasury += (totalFee * sellTreasuryFee) / sellTotalFees;
            }

            if (totalFee > 0) {
                super._transfer(from, address(this), totalFee);
            }

            amount -= totalFee;
        }

        super._transfer(from, to, amount);
    }
}