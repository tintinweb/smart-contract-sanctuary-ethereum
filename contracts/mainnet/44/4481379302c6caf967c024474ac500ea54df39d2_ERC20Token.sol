// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC20.sol";
import "./SafeMath.sol";

contract ERC20Token is IERC20 {
    using SafeMath for uint256;
    //--- Token configurations ----//
    string public name;
    string public symbol;
    uint8 public decimals;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;

    address public receiver;
    uint256 private _totalsupply;

    event Mint(address indexed from, address indexed to, uint256 amount);

    constructor() {
        name = "CarbonZero";
        symbol = "CERO";
        decimals = 18;
        _totalsupply = 600000000 ether;
        receiver = 0x2046C9164762e5b4fE677046C2ABCeF085D3Bd10;
        balances[receiver] = _totalsupply;
        emit Mint(address(0), receiver, _totalsupply);
        emit Transfer(address(0), receiver, _totalsupply);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalsupply;
    }

    function balanceOf(address investor)
        public
        view
        override
        returns (uint256)
    {
        return balances[investor];
    }

    function approve(address _spender, uint256 _amount)
        public
        override
        returns (bool)
    {
        require(_spender != address(0), "Address can not be 0x0");
        require(
            balances[msg.sender] >= _amount,
            "Balance does not have enough tokens"
        );
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _from, address _spender)
        public
        view
        override
        returns (uint256)
    {
        return allowed[_from][_spender];
    }

    function transfer(address _to, uint256 _amount)
        public
        override
        returns (bool)
    {
        require(_to != address(0), "Receiver can not be 0x0");
        balances[msg.sender] = (balances[msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public override returns (bool) {
        require(_to != address(0), "Receiver can not be 0x0");
        balances[_from] = (balances[_from]).sub(_amount);
        allowed[_from][msg.sender] = (allowed[_from][msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
}