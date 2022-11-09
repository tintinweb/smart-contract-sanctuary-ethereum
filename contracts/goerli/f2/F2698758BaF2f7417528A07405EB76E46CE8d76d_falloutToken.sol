/**
 *Submitted for verification at Etherscan.io on 2022-11-09
*/

// File: contracts/falloutToken.sol



pragma solidity >=0.7.0 <0.9.0;


interface IERC20{
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}
contract falloutToken is IERC20{

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    address private _owner;
    mapping(address=>uint256) private _balances;

    mapping(address=>mapping(address=>uint256)) private _allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor(uint256 _initSupply){
        _name="Fallout Token";
        _symbol="FOT";
        _decimals=18;
        _owner=msg.sender;
        _mint(msg.sender,_initSupply);
    }

    function name() public override view returns (string memory){
        return _name;
    }
    function owner() public view returns (address){
        return _owner;
    }
    function symbol() public override view returns (string memory){
        return _symbol;
    }
    function decimals() public override view returns (uint8){
        return _decimals;
    }
    function totalSupply() public override view returns (uint256){
        return _totalSupply;
    }
    function balanceOf(address _account) public override view returns (uint256 balance){
        return _balances[_account];
    }
    function allowance(address _account, address _spender) public override view returns (uint256 remaining){
        return _allowed[_account][_spender];
    }

    function transfer(address _to, uint256 _value) public override returns (bool success){
        require(_balances[msg.sender]>=_value,"Fallout: Insufficient Fund");
        require(_to != address(0),"Fallout: Address can't be null");

        _balances[msg.sender]-=_value;
        _balances[_to]+=_value;
        emit Transfer(msg.sender,_to,_value);
        return true;
    }

    function approve(address _spender, uint256 _value) public override returns (bool success){
        require(_spender != address(0),"Fallout: Address can't be null");

        _allowed[msg.sender][_spender]=_value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success){
        require(_balances[_from]>=_value,"Fallout: Insufficient Fund");
        require(_allowed[_from][msg.sender]>=_value,"Fallout: Not enough allowance");
        require(_to != address(0),"Fallout: Address can't be null");

        _balances[_from]-=_value;
        _balances[_to]+=_value;
        _allowed[_from][msg.sender]-=_value;
        emit Transfer(_from,_to,_value);
        return true;
    }

    function increaseAllowance(address _spender,uint256 _addedValue) public returns (bool){
        require(_spender != address(0),"Fallout: Address can't be null");

        _allowed[msg.sender][_spender] += _addedValue;
        emit Approval(msg.sender, _spender, _allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseAllowance(address _spender,uint256 _subtractedValue) public returns (bool){
        require(_spender != address(0),"Fallout: Address can't be null");

        _allowed[msg.sender][_spender] -= _subtractedValue;
        emit Approval(msg.sender, _spender, _allowed[msg.sender][_spender]);
        return true;
    }

    function _burn(address _account, uint256 _amount) internal {
        require(_account != address(0),"Fallout: Address can't be null");
        require(_balances[_account]<=_amount,"Fallout: Insufficient Fund");

        _totalSupply -= _amount;
        _balances[_account] -= _amount;
        emit Transfer(_account, address(0), _amount);
    }

    function _burnFrom(address _account, uint256 _amount) internal {
        require(_allowed[_account][msg.sender]<=_amount,"Fallout: Not enough allowance");

        _allowed[_account][msg.sender] -= _amount;
        _burn(_account, _amount);
  }
 
    function mint(address _to, uint256 _value) public mustBeOwner(msg.sender) returns (bool success){
        _mint(_to,_value);
        return true;
    }

    function _mint(address _to, uint256 _value) private{
        _balances[_to]+=_value;
        _totalSupply+=_value;
        emit Transfer(address(0),_to,_value);
    }
    
    modifier mustBeOwner(address _account){
        require(_owner==_account, "Fallout: caller must be a owner");
        _;
    }
}