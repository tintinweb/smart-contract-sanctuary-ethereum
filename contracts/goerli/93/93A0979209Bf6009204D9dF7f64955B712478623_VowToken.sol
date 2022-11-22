// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./BEP20.sol";

contract VowToken is BEP20 {
    address public marketingWallet = 0x95b44814F5522146171432672A85fE3E9C759293;

    bool tradingEnabled;

    uint256 public transferTax = 100;
    uint256 constant TAX_DENOMINATOR = 10000;

    uint256 totalTax = 0;

    constructor(address owner, address saleHost) BEP20(owner, saleHost) {
        _approve(address(this), saleHost, type(uint256).max);
    }

    // Override

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        uint256 amountAfterTaxes = _takeTax(sender, amount);
        super._transfer(sender, recipient, amountAfterTaxes);
    }

    // Public

    receive() external payable {}

    // Private
    function _takeTax(address sender, uint256 amount) private returns (uint256) {
        if (amount == 0) { return amount; }

        uint256 taxAmount = amount * transferTax / TAX_DENOMINATOR;
        if (taxAmount > 0) { 
            super._transfer(sender, address(this), taxAmount); 
            totalTax += taxAmount;
        }

        return amount - taxAmount;
    }

    // Owner
    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Trading is already enabled");
        tradingEnabled = true;
    }

    function stopTrading() external onlyOwner {
        require(tradingEnabled, "Trading is stopped already");
        tradingEnabled = false;
    }

    function setTransferTax(uint128 newTax) external onlyOwner {
        transferTax = newTax;
    }

    function setWithDrawWallet(address newWallet) external onlyOwner {
        marketingWallet = newWallet;
    }

    function withdraw() external onlyOwner {
        super.transferFrom(address(this), marketingWallet, totalTax);
        totalTax = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor(address newOwner) {
        _owner = newOwner;
        emit OwnershipTransferred(address(0), _owner);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function owner() internal view returns (address) {
        return _owner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IBEP20.sol";
import "./Ownable.sol";

contract BEP20 is IBEP20, Ownable {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    string private constant NAME = "V-DOLLAR";
    string private constant SYMBOL = "VD";
    uint8 private constant DECIMALS = 18;
    uint256 private constant TOTAL_SUPPLY = 10**9 * 10**DECIMALS;

    constructor(address owner, address recipient) Ownable(owner) {
        require(recipient != address(0), "Transfer to zero address");
        _balances[recipient] = TOTAL_SUPPLY;
        emit Transfer(address(0), recipient, TOTAL_SUPPLY);
    }

    function getOwner() override public view returns (address) {
        return owner();
    }

    function decimals() override public pure returns (uint8) {
        return DECIMALS;
    }

    function symbol() override external pure returns (string memory) {
        return SYMBOL;
    }

    function name() override external pure returns (string memory) {
        return NAME;
    }

    function totalSupply() override public pure returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function balanceOf(address account) override public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) override external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) override external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) override external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, msg.sender, currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}