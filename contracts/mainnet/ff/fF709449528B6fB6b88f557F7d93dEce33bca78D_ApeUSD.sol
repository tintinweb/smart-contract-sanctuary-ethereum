// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IApeFinance {
    function mint(address minter, uint256 mintAmount)
        external
        returns (uint256);
    function redeem(
        address payable redeemer,
        uint256 redeemTokens,
        uint256 redeemAmount
    ) external returns (uint256);
    function exchangeRateStored() external view returns (uint);
    function balanceOf(address) external view returns (uint);
}

contract ApeUSD {
    string public constant name = "ApeUSD";
    string public constant symbol = "ApeUSD";
    uint8 public constant decimals = 18;

    IApeFinance public apefi;
    address public gov;
    address public nextgov;
    uint public commitgov;
    uint public constant delay = 1 days;

    uint public liquidity;

    constructor() {
        gov = msg.sender;
    }

    modifier g() {
        require(msg.sender == gov);
        _;
    }

    function setApefi(address _apefi) external g {
        require(address(apefi) == address(0), 'apefi address already set');
        apefi = IApeFinance(_apefi);
    }

    function setGov(address _gov) external g {
        nextgov = _gov;
        commitgov = block.timestamp + delay;
    }

    function acceptGov() external {
        require(msg.sender == nextgov && commitgov < block.timestamp);
        gov = nextgov;
    }

    function balanceApeFi() public view returns (uint) {
        return apefi.balanceOf(address(this));
    }

    function balanceUnderlying() public view returns (uint) {
        uint256 _b = balanceApeFi();
        if (_b > 0) {
            return _b * apefi.exchangeRateStored() / 1e18;
        }
        return 0;
    }

    function _redeem(uint amount) internal {
        require(apefi.redeem(payable(address(this)), 0, amount) == 0, "apefi: withdraw failed");
    }

    function profit() external {
        uint _profit = balanceUnderlying() - liquidity;
        _redeem(_profit);
        _transferTokens(address(this), gov, _profit);
    }

    function withdraw(uint amount) external g {
        liquidity -= amount;
        _redeem(amount);
        _burn(amount);
    }

    function deposit() external {
        uint _amount = balances[address(this)];
        allowances[address(this)][address(apefi)] = _amount;
        liquidity += _amount;
        require(apefi.mint(address(this), _amount) == 0, "apefi: supply failed");
    }

    /// @notice Total number of tokens in circulation
    uint public totalSupply = 0;

    mapping(address => mapping (address => uint)) internal allowances;
    mapping(address => uint) internal balances;

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);

    function mint(uint amount) external g {
        // mint the amount
        totalSupply += amount;
        // transfer the amount to the recipient
        balances[address(this)] += amount;
        emit Transfer(address(0), address(this), amount);
    }

    function burn(uint amount) external g {
        _burn(amount);
    }

    function _burn(uint amount) internal {
        // burn the amount
        totalSupply -= amount;
        // transfer the amount from the recipient
        balances[address(this)] -= amount;
        emit Transfer(address(this), address(0), amount);
    }

    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

    function transfer(address dst, uint amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(address src, address dst, uint amount) external returns (bool) {
        address spender = msg.sender;
        uint spenderAllowance = allowances[src][spender];

        if (spender != src && spenderAllowance != type(uint).max) {
            uint newAllowance = spenderAllowance - amount;
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(address src, address dst, uint amount) internal {
        balances[src] -= amount;
        balances[dst] += amount;

        emit Transfer(src, dst, amount);
    }
}