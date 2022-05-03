/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// interface IERC20{

//     function totalsupply() external view returns (uint256);
//     function balanceof(address account) external view returns (uint256);
//     function transfer(address recipient, uint256 amount) external returns (bool);

//     event Transfer(address indexed from, address indexed to, uint256 value);
// }

contract MyToken{

    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalsupplyyy;

    address admin;
   

    event Approval(address indexed tokenowner, address indexed spender, uint256 tokens);
    event Transfers(address indexed from, address indexed to, uint256 tokens);

    mapping(address => uint256) public balances;
    mapping (address => mapping(address => uint256) ) allowance;

    //we can hardcode total supply using this: 
    //  uint totalsupply_ = 1000 wei;

// else we can also take total supply from deployer
     constructor(uint256 _totalsupplyyy, string memory _name, string memory _symbol, uint256 _decimals ){
         //1000 tokens will be sent in wallet of deployer 
        
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
         totalsupplyyy = _totalsupplyyy;
         balances[msg.sender] = _totalsupplyyy ;
         
         //restricting admin as deployer or msg.sender
         admin = msg.sender;
      }
        
    //  function totalsupply() public override view returns (uint){
    //      return totalsupplyyy ;
    //  }

     //to check anyones balance we will enter address and it will return/show us balance of him
    // function balanceof(address tokenowner) public override view returns (uint256){
    //     return balances[tokenowner]; 
    //     }

//creating function to transfer money from one to another wallet

    function transfer(address _to, uint256 _amount) public returns  (bool success){
        //the amount which user needs must be less than amount which is in deployer's wallet
        //the program will execute further only if this require statement will be true
        require(balances[msg.sender] >= _amount, "Not enough ethers available");
        balances[msg.sender] -= _amount ;
        balances[_to] += _amount;
        //(from, to , amount)
        emit Transfers(msg.sender, _to, _amount);
        return true;
          }
//everyone can mint the coins thats why adding restriction through modifier
        modifier onlyAdmin{
            require (msg.sender == admin, "You Are Not Admin!!!" );
            _;
        }
          //start me supply dali but wo km thy and need barh gyi hai
          //or tokens add krny hai
          function mint(uint256 qty) public onlyAdmin returns (uint256) {
              totalsupplyyy += qty;
              balances[msg.sender] += qty;
              return totalsupplyyy;
          }
//to reduce quantity of tokens
           function burn(uint256 qty) public onlyAdmin returns (uint256) {
            require(balances[msg.sender] >= qty, "Ethers Are Less");
              totalsupplyyy -= qty;
              balances[msg.sender] -= qty;
              return totalsupplyyy;
          }
//if my friends wants to spend token from my wallet, we will give him allowance
//we will view remaining tokens through this function
    function showallowance (address _owner, address _spender) public view returns (uint256 remaining){
    return allowance [_owner][_spender];
}
//in approve function we are allowing who can spend and how much he can spend, so I'm owner and msg.sender
    function approve (address _spender, uint256 _value) public returns (bool){
        require(_spender != address(0));
        allowance [msg.sender][_spender] = _value ;
        emit Approval ( msg.sender, _spender, _value ) ;
        return true;
    }
//spender will run this function 
//Here, msg.sender is the one who is spending 
      function transferfrom(address _from, address _to, uint256 value) public returns  (bool){
          uint256 allowance1 = allowance [_from][msg.sender];
        require(balances[_from] >= value && allowance1 >= value , "Not enough ethers available");
        balances[_to] += value ;
        balances[_from] -= value ;
        allowance [_from][msg.sender] -= value;
        //(from, to , amount)
        emit Transfers(_from , _to , value );
        return true;
          }
}