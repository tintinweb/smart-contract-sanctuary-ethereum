/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;


contract ERC20token4{

    string internal token4Name; 
    string internal token4Symbol; 
    uint256 internal token4TotalSupply;
    uint256 internal  token4decimals; 
    address internal owner;

    mapping(address => uint256) balances;
    mapping(address => bool) minters;

    constructor(string memory _n, string memory _s){
        token4Name = _n;
        token4Symbol = _s;
        token4decimals = 18;
        token4TotalSupply = token4TotalSupply*(10**uint256(token4decimals));//100 * 10^18//18
        minters[msg.sender]= true;
        owner = msg.sender;
    }

     modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this method");
        _;
    }

    modifier onlyminetrs() {//it will check whether the address is true
        require(minters[msg.sender]);
        _;
    }

     function name()  public view returns(string memory) {
         return token4Name;
        }

    function symbol() public view returns(string memory) { 
        return token4Symbol;
        }

    function token4totalSupply() public view returns(uint256) { 
        return token4TotalSupply;
        }

    function addMinters() public {
        minters[msg.sender]= false;

    }

    function checkstatus() public view returns(bool){
        return minters[msg.sender];
    }

    function approveMinter(address _minter) public onlyOwner{//if its true, then only the minter is able to mint tokens. 
        if(!minters[_minter]){//onlyowner can execute this function
            minters[_minter]=true;
        }
    }

    function totalSupply()  public view returns(uint256) { 
        return token4TotalSupply;
        }

    function balanceof(address tokenOwner)  public view returns(uint256) { 
        return balances[tokenOwner];
        }

    function mint(address to, uint _tokens) public onlyminetrs returns(bool) {
        token4TotalSupply += _tokens*(10**uint256(token4decimals));
        balances[msg.sender] += _tokens;
        return true;
    }

    function transfer(address to, uint token)  public  returns(bool){
        require(balances[msg.sender] >= token, "you should have some token");
        balances[msg.sender] -= token;//or balances[msg.sender] - tokens;
        balances[to] += token;//or balances[to] + tokens;
        return true;
    }

    function burn(uint _tokens) public onlyOwner returns(bool) {
     token4TotalSupply -= _tokens*(10**uint256(token4decimals));
     balances[msg.sender] -= _tokens;
     return true;
    }
}