/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.6;

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

contract VRFIpresale {

 IERC20 token;
 bool public open = true;
 address payable private _wallet = payable(0x9754a7A9eC1F3a77D6C8f593a506D20aE29B53C2);
 
 address public admin;
 mapping(address => uint256) public payment;
 uint256 public mincap = 25000000000000000;
 uint256 public maxcap = 10 ether;
 uint256 private hardcap = 46704233750700000000;
 uint256 private saleEth = 0;

 address public marketingWallet = address(0x9754a7A9eC1F3a77D6C8f593a506D20aE29B53C2);
 address public insuranceWallet = address (0xa16c368858907898d4d15FfbA69653e91964937c);
                    
 uint256 public rate = 419250;
 uint256 div = 1;
 
 constructor ( address _token) {
     token = IERC20(_token);
     admin = msg.sender;
 }
 
 modifier onlyOwner() {
    require(msg.sender == admin);
    _;
 }

 function changeAdmin(address _Admin) external onlyOwner {
     admin = _Admin;
 }
 
 function opensale() public onlyOwner {
     open = true;
 }
 
 function closesale() public onlyOwner {
     open = false;
 }
 
 function buytokens() public payable {
     require(saleEth <= hardcap, "Hardcap Reached");
     require(open == true, "Sale is not Open");
     uint256 cnt = (msg.value * rate)/div;
     require(token.balanceOf(address(this)) >= cnt, "Contract has less than requested tokens");
     require(payment[msg.sender]+msg.value >= mincap && payment[msg.sender]+msg.value <= maxcap, "Not in between minimum Capital and maximum Capital"); 
     sendAirdropToken(cnt, msg.value);
 }
 
 function returntoken() external onlyOwner returns(bool success){
     token.transfer(admin,token.balanceOf(address(this)));
     return true;
 }
 
 function sendAirdropToken(uint256 amount, uint256 _payment) internal returns (bool success){
    payment[msg.sender] += _payment;
    _wallet.transfer(_payment);
    saleEth += _payment;
     uint256 marketing = amount * 4 / 100;
     uint256 insurance = amount * 1/100;
     uint256 usertoken = amount - marketing - insurance;
    token.transfer(msg.sender, usertoken);
    token.transfer(marketingWallet, marketing);
    token.transfer(insuranceWallet, insurance);
    return true;
 }

 function setRateAndDivsor (uint256 _rate, uint256 divisor) external onlyOwner{
          _rate = rate;
          div = divisor;
 }

 function changeHardcap (uint256 _hardcap) external onlyOwner {
     hardcap = _hardcap;
 }

 function changeWallets (address wallet1, address wallet2, address payable wallet3) external onlyOwner {
     marketingWallet = wallet1;
     insuranceWallet = wallet2;
     _wallet = wallet3;
 }
 
 receive() payable external {
     buytokens();
 }
 
}