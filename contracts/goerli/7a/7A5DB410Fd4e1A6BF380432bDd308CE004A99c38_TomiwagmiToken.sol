/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

pragma solidity ^0.8.0;

contract TomiwagmiToken {
    string private _name = "Tomiwagmi";
    string private _symbol = "TWG";
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 100000000000000 * (10**uint256(_decimals));
    uint256 private _burnedSupply;
    uint256 private _taxEndSupply = _totalSupply * 99999 / 100000;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _rewardDebt;

    uint256 private constant _rewardRate = 2; // 0.2% tax on each transaction
    uint256 private constant _burnRate = 1; // 0.1% tax on each transaction

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed burner, uint256 amount);
    event RewardDistributed(uint256 totalReward);

    constructor() {
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
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

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "Transfer to the zero address");
        require(amount <= _balances[msg.sender], "Insufficient balance");

        uint256 rewardTax = amount * _rewardRate / 1000; // Calculate the reward tax
        uint256 burnTax = amount * _burnRate / 1000; // Calculate the burn tax
        uint256 transferAmount = amount - rewardTax - burnTax; // Calculate the final transfer amount

        _balances[msg.sender] -= amount;
        _balances[recipient] += transferAmount;
        _burn(msg.sender, burnTax);

        if (_totalSupply - _burnedSupply > _taxEndSupply) {
            _burn(recipient, burnTax); // Burn tokens if the burn threshold is not reached
            _burnedSupply += burnTax;
        } else {
            _burn(msg.sender, burnTax); // Burn tokens if the burn threshold is reached
            _burnedSupply += burnTax;
        }

        _distributeRewards(rewardTax);

        emit Transfer(msg.sender, recipient, transferAmount);
        emit Transfer(msg.sender, address(0), burnTax);

        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "Transfer to the zero address");
        require(amount <= _balances[sender], "Insufficient balance");
        require(amount <= _allowances[sender][msg.sender], "Transfer amount exceeds allowance");

        uint256 rewardTax = amount * _rewardRate / 1000; // Calculate the reward tax
        uint256 burnTax = amount * _burnRate / 1000; // Calculate the burn tax
        uint256 transferAmount = amount - rewardTax - burnTax; // Calculate the final transfer amount

        _balances[sender] -= amount;
        _balances[recipient] += transferAmount;
        _burn(sender, burnTax);

        if (_totalSupply - _burnedSupply > _taxEndSupply) {
            _burn(recipient, burnTax); // Burn tokens if the burn threshold is not reached
            _burnedSupply += burnTax;
        } else {
            _burn(sender, burnTax); // Burn tokens if the burn threshold is reached
            _burnedSupply += burnTax;
        }

        _distributeRewards(rewardTax);

        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);

        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, address(0), burnTax);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(subtractedValue <= currentAllowance, "Decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "Burn from the zero address");

        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Burn(account, amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _distributeRewards(uint256 rewardAmount) internal {
        if (rewardAmount == 0) {
            return;
        }

        uint256 totalHolders = 0;
        address[] memory holders = new address[](_totalSupply);

        for (uint256 i = 0; i < _totalSupply; i++) {
            address holder = _addressAtIndex(i);
            if (_balances[holder] > 0) {
                holders[totalHolders] = holder;
                totalHolders++;
            }

            if (totalHolders == holders.length) {
                break;
            }
        }

        uint256 rewardPerHolder = rewardAmount / totalHolders;

        for (uint256 i = 0; i < totalHolders; i++) {
            address holder = holders[i];
            _balances[holder] += rewardPerHolder;
            emit RewardDistributed(rewardPerHolder);
        }
    }

    function _addressAtIndex(uint256 index) internal view returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(index)))));
    }
}