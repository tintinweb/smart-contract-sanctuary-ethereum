// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./context/context.sol";

error BQtoken_cannotBeTheZeroAddress();
error BQtoken_NotEnoughBalance();

contract BQtoken is Context {
    string private _name;
    string private _symbol;
    uint private _totalSupply;
    uint32 private _decimals = 18;

    mapping(address => uint) private balanceOf;
    mapping(address => mapping(address => uint)) private _allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    event tokenMinted(address indexed Account, uint indexed AmountedMinted);

    constructor() {
        _name = "BeuniQue";
        _symbol = "BQT";
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint) {
        return _decimals;
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        _approve(msg.sender, _spender, _value);
        return true;
    }

    /* 
    1. the owner and spender should not be the zero address
    2. check if the owner has more than the approved funds
    3. update the allowance of the spender
    */

    function _approve(address owner, address spender, uint amount) internal {
        owner = Owner();
        if (owner == address(0)) revert BQtoken_cannotBeTheZeroAddress();
        if (spender == address(0)) revert BQtoken_cannotBeTheZeroAddress();
        if (balanceOf[owner] <= amount) revert BQtoken_NotEnoughBalance();
        _allowance[owner][spender] += amount;
        emit Approval(owner, spender, amount);
    }

    function allowance(
        address _owner,
        address _spender
    ) public view returns (uint256) {
        return _allowance[_owner][_spender];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /* 
    1. the owner and to cant be the zero address
    2. check if the owner have enough to transfer
    3. subtract from the amount from the owner balance
    4. Add the amount to to TO balance
    */
    function _transfer(address _owner, address _to, uint amount) internal {
        _owner = Owner();

        if (_owner == address(0)) revert BQtoken_cannotBeTheZeroAddress();
        if (_to == address(0)) revert BQtoken_cannotBeTheZeroAddress();

        uint ownerBalance = balanceOf[_owner];
        if (ownerBalance <= amount) revert BQtoken_NotEnoughBalance();
        balanceOf[_owner] -= amount;
        balanceOf[_to] += amount;

        emit Transfer(_owner, _to, amount);
    }

    /* 
    1. Check if the owner is enough to transfer to the spender
    2. Address cannot be the zero address. already in the _transfer logic
    3. check if the current allowance is enough to transferFrom
    4. we transfer using the _transfer logic 
    5. and we will also update Approve using the _approve logic and subtract the Value from the spenders approved funds
    */
    function transferFrom(
        address _owner,
        address _spender,
        uint256 _value
    ) public returns (bool) {
        uint currentAllowance = _allowance[_owner][_spender];

        if (currentAllowance != type(uint256).max) {
            if (currentAllowance <= _value) revert BQtoken_NotEnoughBalance();
            _approve(_owner, _spender, currentAllowance - _value);
        }
        _transfer(_owner, _spender, _value);
        return true;
    }

    /* 
    1. make sure the accountMinting is the msg.sender
    2. the account must not be the zero address
    3. add the amount minted to our total supply
    4. add the amount minted to the senders address
    5. emit event
    
    */
    function mint(address account, uint amount) private {
        account = Owner();
        if (account == address(0)) revert BQtoken_cannotBeTheZeroAddress();
        _totalSupply += amount;
        balanceOf[account] += amount;
        emit tokenMinted(account, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

abstract contract Context {
    function Owner() internal view virtual returns (address) {
        return msg.sender;
    }
}