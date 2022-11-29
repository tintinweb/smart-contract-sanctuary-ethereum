//SPDX-License-Identifier:  MIT
pragma solidity ^0.8.16;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract $PRESALE {

 IERC20 token1;
 IERC20 token2;
 IERC20 token3;

 bool public open = false;
 address payable public _wallet = payable (0x0000000000000000000000000000000000000123); //Replace your address here
 
 address public admin;
 mapping(address => uint256) public payment;
 uint256 public mincap = 0.1 ether;
 uint256 public maxcap = 10 ether;
 uint256 public hardcap = 500 ether;
 uint256 public saleEth = 0;                  
 uint256 public rate = 10000; //10000 TOKENS PER ETH
 
 
 constructor () {
     token1 = IERC20(0xC3b2C181dFa09db953F91E00540f1cc7Ad67b1c9); //replace with SHEN address
     token2 = IERC20(0xC3b2C181dFa09db953F91E00540f1cc7Ad67b1c9); //replace with RYSHEN address
     token3 = IERC20(0xC3b2C181dFa09db953F91E00540f1cc7Ad67b1c9); //replace with DOSHEN address
     admin = msg.sender;
 }

 bool internal locked;
 modifier preventReentrancy {
    require (!locked, "preventing: reentrancy attempt");
    locked = true;
    _;
    locked = false;
 }
 
 modifier onlyOwner() {
    require(msg.sender == admin);
    _;
 }

 function changeAdmin(address _Admin) external onlyOwner {
     admin = _Admin;
 }

 function changePaymentWallet (address payable wallet) external onlyOwner {
    _wallet = wallet;
 }
 
 function opensale() public onlyOwner {
     open = true;
 }
 
 function closesale() public onlyOwner {
     open = false;
 }
 
 function buytokens() public payable preventReentrancy {
     require(saleEth <= hardcap, "Hardcap Reached");
     require(open == true, "Sale is not Open");
     uint256 cnt = msg.value * rate;
     require(token1.balanceOf(address(this)) >= cnt, "Contract has less than requested SHEN");
     require(token2.balanceOf(address(this)) >= cnt, "Contract has less than requested RYSHEN");
     require(token3.balanceOf(address(this)) >= cnt, "Contract has less than requested DOSHEN");

     require(payment[msg.sender]+msg.value >= mincap && payment[msg.sender]+msg.value <= maxcap, "Not in between min Cap and max Cap per wallet"); 
     airdropTokens(cnt, msg.value);
 }
 
 function returntoken() external onlyOwner returns(bool success){
     token1.transfer(admin,token1.balanceOf(address(this)));
     token2.transfer(admin,token2.balanceOf(address(this)));
     token3.transfer(admin,token3.balanceOf(address(this)));
     

     return true;
 }
 
 function airdropTokens(uint256 cnt, uint256 _payment) internal returns (bool success){
    payment[msg.sender] += _payment;
   (bool sent,) =  _wallet.call{value:_payment}("");
    require (sent, "eth transfer failed");
    saleEth += _payment;
    token1.transfer(msg.sender,cnt);
    token2.transfer(msg.sender,cnt);
    token3.transfer(msg.sender,cnt);
    return true;
 }
 
 receive() payable external {
     buytokens();
 }

 function setRate ( uint256 Rate) external onlyOwner {
  rate = Rate;
 }

 function setTokens(IERC20 tok1, IERC20 tok2, IERC20 tok3) external onlyOwner {
     token1 = tok1;
     token2 = tok2;
     token3 = tok3;
 }

 function setHardcap (uint256 amount) external onlyOwner {
    hardcap = amount;
 }

 function setMinAndMaxCap (uint256 _min, uint256 _max) external onlyOwner {
    mincap = _min;
    maxcap = _max;
 }
 
}