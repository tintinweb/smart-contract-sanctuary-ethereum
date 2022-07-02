pragma solidity 0.8.8;
import './TutorialERC20.sol';
import './Ownable.sol';

contract Crowdsale {
    
    uint256 _unitPrice;
    TutorialERC20 _token;

    constructor(TutorialERC20 token, uint256 unitPrice)
    {
        _token = token;
        _unitPrice = unitPrice;
    }

    event Buy(address buyer, uint256 amount);

    function buy(uint256 amount) public payable{
        require(msg.value >= _unitPrice * amount, "Insufficient payment");
        address buyer = msg.sender;
        _token.mint(buyer, amount);
        emit Buy(buyer, amount);
    }

}

pragma solidity 0.8.8;
import './MintableERC20.sol';
import './Ownable.sol';

contract TutorialERC20 is MintableERC20, Ownable {

    constructor(string memory name_, string memory symbol_, address owner_) 
        MintableERC20(name_,symbol_)
        Ownable(owner_)
    {

    }

    function mint(address to, uint256 amount) override
    onlyOwner
    public 
    {
        _totalSupply += amount;
        _balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

}

pragma solidity 0.8.8;

contract Ownable {
    address private _owner;

    constructor(address owner_) {
        _owner=owner_;
    }


    function owner() external view returns(address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

}

pragma solidity 0.8.8;
import './ERC20.sol';

contract MintableERC20 is ERC20 {

    constructor(string memory name_, string memory symbol_) 
        ERC20(name_,symbol_,0,address(0)) 
    {
    }

    function mint(address to, uint256 amount) virtual
    public 
    {
        _totalSupply += amount;
        _balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

}

pragma solidity 0.8.8;

contract ERC20 {

    string                                      _name;
    string                                      _symbol;
    uint256                                     _totalSupply;
    mapping(address=>uint256)                   _balanceOf;
    mapping(address=>mapping(address=>uint256)) _allowance;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    constructor(string memory name_, string memory symbol_, uint256 totalSupply_, address owner)
    {
        _name=name_;
        _symbol=symbol_;
        _balanceOf[owner]=totalSupply_;
    }


    function name() public view returns (string memory)
    {
        return _name;
    }
    function symbol() public view returns (string memory)
    {
        return _symbol;
    }
    function decimals() public pure returns (uint8)
    {
        return 18;
    }
    function totalSupply() public view returns (uint256)
    {
        return _totalSupply;
    }
    function balanceOf(address _owner) public view returns (uint256 balance)
    {
        return _balanceOf[_owner];
    }
    function allowance(address _owner, address _spender) public view returns (uint256 remaining)
    {
        return _allowance[_owner][_spender];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        uint256 fromBalance = _balanceOf[msg.sender];
        require(fromBalance >= _value, "Insufficient balance");
        _balanceOf[msg.sender] = fromBalance - _value;
        _balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        address owner = msg.sender;
        _allowance[owner][_spender] = _value;
        emit Approval(owner, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        address spender = msg.sender;

        uint256 currentAllowance = _allowance[_from][spender];
        require(currentAllowance >= _value, "Insufficient allowance");
        _allowance[_from][spender] = currentAllowance - _value;

        uint256 fromBalance = _balanceOf[_from];
        require(fromBalance >= _value, "Insufficient balance");
        _balanceOf[_from] = fromBalance - _value;
        _balanceOf[_to] += _value;
      
        emit Transfer(_from, _to, _value);
        return true;
    }

}