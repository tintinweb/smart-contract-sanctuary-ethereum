/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

// File: bsc_shitcoin/YogiWolF.sol


pragma solidity ^ 0.8.13;



contract YogiWolf{
    uint     private _maxSupply = 100000 * 10**18;
    uint     private _decimals  = 18;
    string   private _name;
    string   private _symbol;
  address    public _owner;

    mapping(address => uint ) private _balances ;
    mapping(address => mapping(address => uint)) private _allowances;

    event Transfer(address indexed from,address indexed to ,uint amount);
    event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );
    event TransferFrom(address indexed owner,address indexed spender ,address indexed to , uint amount);
    event Approval(address indexed owner,address indexed spender ,uint amount);
    // event Deployed( uint block.timestamp);
    

    constructor(string memory name_,string memory symbol_){
        _name = name_;
        _symbol = symbol_;
        _owner = msg.sender;
        
        
        emit OwnershipTransferred(address(0),_owner);



    }

    function balanceOf(address account) public view returns(uint){
       return _balances[account];
    }
    function name() public view returns(string memory){
        return _name;
    }
    function symbol() public view returns(string memory){
        return _symbol;
    }
    function decimals() public view returns (uint){
        return _decimals;
    }
    function totalSupply () public view returns(uint){
        return _maxSupply;
    }


    function transfer(address to ,uint amount) public returns(bool){
        _transfer(msg.sender,to,amount);
        
        return true;
    }
    function _transfer(address from ,address to , uint amount) internal virtual {
        require(from != address(0), "Mint:The sender is address zero") ;
        require(to != address(0),    "Burn: The recipient is address zero");
        require (_balances[from]>= amount,"The requested amount is greater than balance" );

        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from,to,amount);

    }
    function approve (address spender , uint amount) public {
        _approve(spender,amount);
    }


    function _approve(address spender , uint amount ) internal virtual {
       
        require(spender != address(0),    "Invalid: The spender is address zero");
        require (_balances[msg.sender]>= amount,"The  amount to be approved  is greater than balance" );

        _allowances[msg.sender][spender] += amount;
        
       

        emit Approval(msg.sender ,spender,amount );
        
    }
    function transferFrom(address owner,address to , uint amount) public  returns(bool){
        _transferFrom(owner,to,amount);
        emit TransferFrom(owner,msg.sender,to,amount);
        return true;
    }

    function _transferFrom(address owner,address to , uint amount) internal virtual {
         require(owner != address(0), "Invalid:The approver is address zero") ;
         require (msg.sender != address(0));
         require(to != address(0),    "Burn: The recipient is address zero");
         uint approvedAllowance = _allowances[owner][msg.sender];
         require(amount <= approvedAllowance, "The amount you are about to send is greater than your approved allowance");

        _allowances[owner][msg.sender] -= amount;
        _balances[to] +=amount;
        _balances[owner] -= amount;

        






    }




    
}