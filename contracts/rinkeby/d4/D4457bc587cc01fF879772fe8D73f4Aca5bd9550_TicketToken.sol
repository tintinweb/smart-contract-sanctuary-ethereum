//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract TicketToken is IERC20 {
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowed;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint private _totalSupply;

    modifier emptyAddress(address _addr) {
        require(address(_addr) != address(0), "Address is empty");
        _;
    }

    constructor(string memory _nm, string memory _sbl, uint _initialBalace, uint _total) {
        _name = _nm;
        _symbol = _sbl;
        _decimals = 18;
        _balances[msg.sender] = _initialBalace;
        _totalSupply = _total;
    }

    function name() external override view returns(string memory) {
        return _name;
    }

    function symbol() external override view returns(string memory) {
        return _symbol;
    }

    function decimals() external override view returns(uint) {
        return _decimals;
    }

    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _account) external override view returns (uint256) {
        return _balances[_account];
    }

    function transfer(address _to, uint _amount) external emptyAddress(_to) override returns (bool) {
        require(_balances[msg.sender] >= _amount, "not enough coins");
        unchecked {
            _balances[msg.sender] -= _amount;
            _balances[_to] += _amount;
        }
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) external override view returns (uint256) {
        return _allowed[_owner][_spender];
    }

    function approve(address _spender, uint _amount) external emptyAddress(_spender) override returns (bool) {
        _allowed[msg.sender][_spender] = _amount;
        return true;
    }

    function burn(uint _amount) external override returns (bool) {
        require(_balances[msg.sender] >= _amount, "much to burn");
        unchecked {
            _balances[msg.sender] -= _amount;
        }
        _totalSupply -= _amount;
        return true;
    }

    function mint(uint _amount) external override returns (bool) {
        unchecked {
            _balances[msg.sender] += _amount;
        }
        _totalSupply += _amount;
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external emptyAddress(_from) emptyAddress(_to) override returns (bool) {
        uint allowanceValue = _allowed[_from][msg.sender];
        require(allowanceValue >= _amount, "invalid quantity");
        require(_balances[_from] >= _amount, "not enough coins");
        unchecked {
            _balances[_from] -= _amount;
            _balances[_to] += _amount;
        }
        emit Transfer(_from, _to, _amount);
        return true;
    }
}