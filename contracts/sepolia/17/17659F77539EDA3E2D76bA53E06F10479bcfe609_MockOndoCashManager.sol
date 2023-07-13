pragma solidity ^0.8.0;

contract MockOndoCashManager {
    
    // ERC20 related variables
    string public name;
    string public symbol;
    uint8 public decimals;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        name = "Mock OUSG 18 decimals";
        symbol = "OUSG";
        decimals = 18;
    }

    function cash() external view returns (address) {
        return address(this);
    }

    function requestMint(uint256 collateralAmountIn) external {
        mint(msg.sender, collateralAmountIn);
    }

    function requestRedemption(uint256 amountCashToRedeem) external {
        burn(msg.sender, amountCashToRedeem);
    }

    // Below are ERC20 functions

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        require(balances[from] >= amount, "Insufficient balance");
        balances[from] -= amount;
        balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        uint256 allowed_from = allowance[_from][msg.sender];
        if (allowed_from != type(uint).max) {
            allowance[_from][msg.sender] -= _value;
        }
        return _transfer(_from, _to, _value);
    }

    function mint(address to, uint256 value) public {
        _mint(to, value);
        emit Transfer(address(0), to, value);
    }

    function burn(address from, uint256 value) public {
        _burn(from, value);
        emit Transfer(from, address(0), value);
    }

    function _mint(address to, uint256 amount) internal {
        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balances[to] += amount;
        }
    }

    function _burn(address from, uint256 amount) internal {
        balances[from] -= amount;
    }
}