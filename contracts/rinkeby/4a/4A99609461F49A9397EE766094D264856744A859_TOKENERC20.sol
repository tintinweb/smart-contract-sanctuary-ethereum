/**
 *Submitted for verification at Etherscan.io on 2022-08-31
*/

/**
 *Submitted for verification at BscScan.com on 2022-07-27
*/

pragma solidity ^0.5.0;

library SafeMath{
     
     function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
}

contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner,"BEP20: Required Owner !");
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require (newOwner != address(0),"BEP20 New Owner cannot be zero address");
        owner = newOwner;
    }
}

interface tokenRecipient {  function receiveApproval(address _from, uint256 _value, address _token, bytes calldata  _extraData) external ; }

contract TOKENERC20 {
    
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals = 18;
  
    uint256 public totalSupply;

   

   event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  
        balanceOf[msg.sender] = totalSupply;                
        name = tokenName;                                
        symbol = tokenSymbol;                               
    }
   
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) private _allowance;
    mapping (address => bool) public LockList;
    mapping (address => uint256) public LockedTokens;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);


    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint256 _value) internal {
        uint256 stage;
        
        require(_from != address(0), "BEP20: transfer from the zero address");
        require(_to != address(0), "BEP20: transfer to the zero address");       

        require (LockList[msg.sender] == false,"BEP20: Caller Locked !");          
        require (LockList[_from] == false, "BEP20: Sender Locked !");
        require (LockList[_to] == false,"BEP20: Receipient Locked !");

       
        stage=balanceOf[_from].sub(_value, "BEP20: transfer amount exceeds balance");
        require (stage >= LockedTokens[_from],"BEP20: transfer amount exceeds Senders Locked Amount");
        
       
        balanceOf[_from]=stage;
        balanceOf[_to]=balanceOf[_to].add(_value,"BEP20: Addition overflow");

        emit Transfer(_from, _to, _value);

    }
    
    function _approve(address owner, address _spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(_spender != address(0), "BEP20: approve to the zero address");

        _allowance[owner][_spender] = amount;
        emit Approval(owner, _spender, amount);
    }

   
    function transfer(address _to, uint256 _value) public returns(bool){
        _transfer(msg.sender, _to, _value);
        return true;
    }


    function burn(uint256 _value) public returns(bool){
        require (LockList[msg.sender] == false,"BEP20: User Locked !");    
        
        uint256 stage;
        stage=balanceOf[msg.sender].sub(_value, "BEP20: transfer amount exceeds balance");
        require (stage >= LockedTokens[msg.sender],"BEP20: transfer amount exceeds Senders Locked Amount");
        
        balanceOf[msg.sender]=balanceOf[msg.sender].sub(_value,"BEP20: Burn amount exceeds balance.");
        totalSupply=totalSupply.sub(_value,"BEP20: Burn amount exceeds total supply");
        
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);

        return true;
    }
    
     
    function burnFrom(address Account, uint256 _value) public returns (bool success) {
        require (LockList[msg.sender] == false,"BEP20: User Locked !");    
        require (LockList[Account] == false,"BEP20: Owner Locked !");    
        uint256 stage;
        require(Account != address(0), "BEP20: Burn from the zero address");
        
        
        _approve(Account, msg.sender, _allowance[Account][msg.sender].sub(_value,"BEP20: burn amount exceeds allowance"));
        
       
        stage=balanceOf[Account].sub(_value,"BEP20: Transfer amount exceeds allowance");
        require(stage>=LockedTokens[Account],"BEP20: Burn amount exceeds accounts locked amount");
        balanceOf[Account] =stage ;            // Subtract from the sender
        
        totalSupply=totalSupply.sub(_value,"BEP20: Burn Amount exceeds totalSupply");
       
        emit Burn(Account, _value);
        emit Transfer(Account, address(0), _value);

        return true;
    }
    
    
 
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        
        _transfer(_from, _to, _value);
        _approve(_from,msg.sender,_allowance[_from][msg.sender].sub(_value,"BEP20: transfer amount exceeds allowance"));
        
        return true;
    }


    
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        uint256 unapprovbal;

        // Do not allow approval if amount exceeds locked amount
        unapprovbal=balanceOf[msg.sender].sub(_value,"BEP20: Allowance exceeds balance of approver");
        require(unapprovbal>=LockedTokens[msg.sender],"BEP20: Approval amount exceeds locked amount ");
       
       
        _allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }
    
    function allowance(address _owner,address _spender) public view returns(uint256){
        return _allowance[_owner][_spender];
    }
   
}



contract myecosouk is owned, TOKENERC20 {

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor () TOKENERC20(
        1000000000 * 1 ** uint256(decimals),
    "My Eco Souk",
    "MES") public {
    }
    
   
    
    function UserLock(address Account, bool mode) onlyOwner public {
        LockList[Account] = mode;
    }
    
   function LockTokens(address Account, uint256 amount) onlyOwner public{
       LockedTokens[Account]=amount;
   }
   
    function UnLockTokens(address Account) onlyOwner public{
       LockedTokens[Account]=0;
   }
   

}