/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

//SPDX-License-Identifier:MIT
pragma solidity >0.8.0 <=0.9.0;

library SafeMath{
    function sub(uint256 a, uint256 b)internal pure returns(uint256){
        assert(b<=a);
        return a-b ; 
    }
    function add(uint256 a ,uint256 b)internal pure returns(uint256){
        uint256 c = a+b;
        assert(c >=a );
        return c ; 
    }
}

interface IERC20{
    function getAddress() external view returns(address);
    function totalSupply()external view returns(uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner , address spender) external view returns (uint256);

    function transfer(address recipient , uint256 amount) external returns(bool);
    function approve(address owner,address spender , uint256 amount)external returns(bool);
    function transferFrom(address sender , address recipient , uint256 amount) external returns(bool);

    event Transfer(address indexed from, address indexed to ,uint256 value);
    event Approval(address indexed owner, address indexed spender , uint256 value);
}

contract ERC20Basic is IERC20 {
    string public constant name = "ERC20-BrianChain";
    string public constant symbol = "ERC-BRC";
    uint8 public constant decimals = 18 ; 

    mapping(address=>uint256) balances ;
    mapping(address=>mapping(address=>uint256)) allowed ; 

    uint256 totalSupply_ = 10000000000000000000 ; 

    using SafeMath for uint256;

    constructor(){
        balances[msg.sender] = totalSupply_ ; 
    }

    function getAddress() public override view returns (address){
        return address(this);
    }

    function totalSupply() public override view returns (uint256){
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns(uint256){
        return balances[tokenOwner];
    }

    function transfer(address receiver , uint256 numTokens) public override returns(bool){
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens) ; 
        balances[receiver] = balances[receiver].add(numTokens) ; 
        emit Transfer(msg.sender , receiver , numTokens);
        return true ; 
    }

    function approve( address owner , address delegate , uint256 numTokens) public override returns (bool){
        allowed[owner][delegate] = numTokens ; 
        emit Approval(owner , delegate , numTokens);
        return true ; 
    }

    function allowance(address owner , address delegate) public override view returns (uint){
        return allowed[owner][delegate];
    }

    function transferFrom(address owner , address buyer , uint256 numTokens) public override returns(bool){
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);

        return true;
    }

}

contract DEX{
    event Bought(uint256 amount);
    event Sold(uint256 amount) ; 

    IERC20 public token ;

    constructor(){
        token = new ERC20Basic();
    }

    function buy() payable public{
        uint256 amountTobuy = msg.value ;
        uint256 dexBalance = token.balanceOf(address(this));
        require( amountTobuy > 0 , "You need to buy more Ether");
        require( amountTobuy <= dexBalance , "Not enough tokens in the reserve");
        token.transfer(msg.sender , amountTobuy) ; 
        emit Bought(amountTobuy);
    }

    function sell (uint256 amount) public {
        require(amount > 0 , "You need to sell at least some tokens");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require( allowance >= amount , "Check the allowance");
        token.transferFrom(msg.sender , address(this),amount);

        emit Sold(amount);
    }

    function getDexBalance() public view returns(uint256){
        return token.balanceOf(address(this));
    }

    function getOwnerBalance() public view returns (uint256){
        return token.balanceOf(msg.sender);
    }

    function getAddress() public view returns(address){
        return address(this);
    }

    function getTokenAddress() public view returns(address){
        return address(token);
        // return token.getAddress();
    }

    function getTotalSupply() public view returns (uint256){
        return token.totalSupply();
    }

    function gerSenderAddress() public view returns (address){
        return address(msg.sender);
        // return msg.sender ; 
    }

    function getAllowance() public view returns(uint256){
        return token.allowance(msg.sender, address(this));
    }

    function approve(uint amount) public returns (bool){
        bool isApproval = token.approve(msg.sender , address(this), amount);
        return isApproval ; 
    }
}