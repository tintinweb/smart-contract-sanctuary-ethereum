/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint remaining);
    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);  
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);

}
contract ERC20Basic is IERC20 {

    string public constant name = "ABCToken";
    string public constant symbol = "ABC";
    uint8 public constant decimals = 18;


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    // uint256 totalSupply_ = 10 ether;
     uint256 totalSupply_ = 1000000 wei;   
    uint256 tokensPerEth = 0.00005 ether;

   constructor() {
    balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public override view returns (uint256) {
    return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function buyTokens(uint NumberOfToken, uint price) public payable returns (uint256){
    uint256 amountToBuy =  tokensPerEth;
        emit BuyTokens(msg.sender, msg.value, amountToBuy); 
        return amountToBuy;
    }


//   function buyTokens() public payable returns (uint256 tokenAmount) {
//     require(msg.value > 0, "You need to send some  to proceed");
//     uint256 amountToBuy = msg.value * tokensPerEth;

//     uint256 vendorBalance = balanceOf(address(this));
//     require(vendorBalance >= amountToBuy, "Vendor has insufficient tokens");

//     (bool sent) = transfer(msg.sender, amountToBuy);
//     require(sent, "Failed to transfer token to user");

//     emit BuyTokens(msg.sender, msg.value, amountToBuy);
//     return amountToBuy;
//   }

    function transfer(address receiver, uint256 numTokens) public  returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender]-numTokens;
        balances[receiver] = balances[receiver]+numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function allowance(address owner, address spender)public view override returns (uint remaining){
        return allowed[owner][spender];
    }
   
    function approve(address spender, uint256 amount) public override returns (bool){
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

//     function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
//     require(numTokens <= balances[owner]);
//     require(numTokens <= allowed[owner][msg.sender]);
//     balances[owner] -= numTokens;
//     allowed[owner][msg.sender] -= numTokens;
//     balances[buyer] += numTokens;
//     emit Transfer(owner, buyer, numTokens);
//     return true;
// }

    function transferFrom(address from,  address to, uint value) public returns (bool) {
    require(value <= balances[from]);
    require(value <= allowed[from][msg.sender]);
    balances[from] -= value;
    allowed[from][msg.sender] -= value;
    balances[ to] += value;
    emit Transfer(from,  to, value);
    return true;
}

    
//     function transferFrom(address from, address to, uint256 value) public returns (bool) {
//     require(value <= allowed[from][msg.sender], "Not allowed!");
//            value <= allowed[from][msg.sender] =-(allowed[from][msg.sender], value);

//   }

}