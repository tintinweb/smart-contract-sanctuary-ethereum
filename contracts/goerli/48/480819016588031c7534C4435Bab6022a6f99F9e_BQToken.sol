// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <=0.9.0;
import "./context/context.sol";

error DNM_zeroAddress(string errorMessage);
error DNM_lowAllowance();
error DNM_lowFunds();

contract BQToken is Context {
    //Events
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _value
    );
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 indexed _value
    );

    mapping(address => uint256) private _balanceOf;
    mapping(address => mapping(address => uint256)) private _allowance;

    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    uint32 constant _decimals = 18;
    uint256 private ownerMintToken = 500000 * 10 ** 18;

    constructor() {
        _name = "BQToken";
        _symbol = "BQT";

        _mint(Owner(), ownerMintToken);
    }

    function name() public view returns (string memory tokenName) {
        tokenName = _name;
    }

    function symbol() public view returns (string memory tokenSymbol) {
        tokenSymbol = _symbol;
    }

    function decimals() public pure returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balanceOf[account];
    }

    function ownerAddress() public view returns (address) {
        return Owner();
    }

    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return _allowance[owner][spender];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        address owner = Owner();
        _transfer(owner, _to, _value);
        return true;
    }

    //_tranfer
    //Required Condition
    //1. from and to must not be the zero(0) account/address
    //2. from balance must be >= amount
    //3. subtract amount from `from` balance
    //4. add amount to `to` balance
    function _transfer(address from, address to, uint256 amount) internal {
        if (from == address(0)) revert DNM_zeroAddress("Zero Address Detected");
        if (to == address(0)) revert DNM_zeroAddress("Zero Address Detected");

        uint256 fromBalance = _balanceOf[from];
        if (fromBalance >= amount) revert DNM_lowFunds();
        unchecked {
            _balanceOf[from] = fromBalance - amount;
            _balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    function approve(
        address spender,
        uint256 approvedAmount
    ) public returns (bool) {
        address owner = Owner();
        _approve(owner, spender, approvedAmount);
        return true;
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _approvedAmount
    ) internal {
        if (_owner == address(0))
            revert DNM_zeroAddress("Zero Address Detected");
        if (_spender == address(0))
            revert DNM_zeroAddress("Zero Address Detected");
        _allowance[_owner][_spender] = _approvedAmount;

        emit Approval(_owner, _spender, _approvedAmount);
    }

    function transferFrom(
        address owner,
        address spender, //to address we are transfer to
        uint256 amount
    ) public returns (bool) {
        uint256 currentAllowance = _allowance[owner][spender];
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance >= amount) revert DNM_lowAllowance();
            _approve(owner, spender, currentAllowance - amount);
        }
        //make the transfers
        _transfer(owner, spender, amount);
        return true;
    }

    function _increaseAllowance(
        address _spender,
        uint256 _amount
    ) public returns (bool) {
        address owner = Owner();
        uint256 currentAllowance = allowance(owner, _spender);
        _approve(owner, _spender, currentAllowance + _amount);
        return true;
    }

    function _descreaseAllowance(
        address _spender,
        uint256 substractedValue
    ) public returns (bool) {
        address owner = Owner();
        uint256 currentAllowance = allowance(owner, _spender);
        if (currentAllowance >= substractedValue) revert DNM_lowAllowance();
        _approve(owner, _spender, currentAllowance - substractedValue);
        return true;
    }

    function _mint(address account, uint amount) private {
        account = Owner();
        amount = ownerMintToken;
        if (account == address(0))
            revert DNM_zeroAddress("Zero Address Detected");
        _totalSupply += amount;
        _balanceOf[account] += amount;
        emit Transfer(address(0), account, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

abstract contract Context {
    function Owner() internal view virtual returns (address) {
        return msg.sender;
    }
}