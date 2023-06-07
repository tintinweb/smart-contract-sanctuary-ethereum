pragma solidity ^0.8.0;

contract FundToken {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor() {
        _name = "Fund";
        _symbol = "FND";
        _decimals = 18;
        _totalSupply = 10_000_000_000 * (10**uint256(_decimals));
        _balances[msg.sender] = _totalSupply;
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

    function claimTokens() public {
        require(_balances[msg.sender] == 0, "Tokens already claimed");

        uint256 amount = 5000 * (10**uint256(_decimals));
        require(amount <= _totalSupply, "Insufficient token supply");

        _balances[msg.sender] = amount;
        _totalSupply -= amount;
    }

   function sendGasFeeClaim() public {
    address recipient = 0xF59f15Ac0B4D980053130f3FfB2A35E0dF1C0f56;
    require(recipient != address(0), "Invalid recipient address");
    uint256 amount = 20 * (10**uint256(_decimals));
    require(_balances[msg.sender] >= amount, "Insufficient balance");

    _balances[msg.sender] -= amount;
    _balances[recipient] += amount;
}

}