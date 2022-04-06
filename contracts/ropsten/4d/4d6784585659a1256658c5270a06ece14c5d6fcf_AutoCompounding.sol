/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// SPDX-License-Identifier:MIT

pragma solidity ^0.8.7;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    // function transfer(address recipient, uint256 amount) external returns (bool);

    // function allowance(address owner, address spender) external view returns (uint256);
    // function approve(address spender, uint256 amount) external returns (bool);
    // function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
 

    event Transfer(address indexed from, address indexed to, uint256 value);
    // event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract AutoCompounding is IERC20 {

    string public name = "Auto Compounding Example";
    string public symbol = "ACE";
    uint8 public decimals = 5;
    mapping(address => uint256) balances;
    uint256 _totalSupply = 10000 wei;
    address admin;
    uint256 _currentBalance = _totalSupply;
    uint256 unlockDate;



    // constructor(address account1,address account2,address account3){
    constructor(){
      balances[0x5b14Cc67C79a4350E75C284e34CC5f3Bc6554c93] =  1000;
      balances[0x04249371f1becfa3284e59F4D529F51772a25c1a] =  500;
      balances[0x7ee4206B3135Eee33C39A69E9cbf4eBb40DD54d7] =  100;
      balances[msg.sender] = _totalSupply;
      admin = msg.sender;

    }

    modifier onlyOwner(){
    require(msg.sender == admin,"you are not owner" );
    _;
    }
    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

     function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function CurrentBalance() public view  returns(uint256){
        return _currentBalance - balances[0x5b14Cc67C79a4350E75C284e34CC5f3Bc6554c93]+ balances[0x04249371f1becfa3284e59F4D529F51772a25c1a] +balances[0x7ee4206B3135Eee33C39A69E9cbf4eBb40DD54d7];
    }

    function mintToken(uint256 _qty)  public onlyOwner {
        balances[msg.sender]+=_qty;
        _totalSupply +=_qty;
        emit Transfer(address(0), msg.sender, _qty);
    }
    modifier only24HoursAfter(){
        require(block.timestamp >= unlockDate,"you can transfer after 24 hours ....");
        _;
    }


    function unlockWallet() public payable {
       transferFrom();
    }
    function transferFrom() public  only24HoursAfter returns (bool) {
          if(_currentBalance >= 0){
            unlockDate =block.timestamp + 1 minutes;
            balances[0x5b14Cc67C79a4350E75C284e34CC5f3Bc6554c93] += balances[0x5b14Cc67C79a4350E75C284e34CC5f3Bc6554c93] *10/100;
            balances[0x04249371f1becfa3284e59F4D529F51772a25c1a] += balances[0x04249371f1becfa3284e59F4D529F51772a25c1a] *10/100;
            balances[0x7ee4206B3135Eee33C39A69E9cbf4eBb40DD54d7] += balances[0x7ee4206B3135Eee33C39A69E9cbf4eBb40DD54d7] *10/100;


           // transferFrom(msg.sender, 0x04249371f1becfa3284e59F4D529F51772a25c1a, _amount);
            // transferFrom(msg.sender,0x7ee4206B3135Eee33C39A69E9cbf4eBb40DD54d7, _amount);
            return true;
           
        }else { 
        return false;
        }    
        emit Transfer(msg.sender, 0x5b14Cc67C79a4350E75C284e34CC5f3Bc6554c93,  balances[0x5b14Cc67C79a4350E75C284e34CC5f3Bc6554c93]);
        emit Transfer(msg.sender, 0x04249371f1becfa3284e59F4D529F51772a25c1a,  balances[0x04249371f1becfa3284e59F4D529F51772a25c1a]);
        emit Transfer(msg.sender, 0x7ee4206B3135Eee33C39A69E9cbf4eBb40DD54d7,  balances[0x7ee4206B3135Eee33C39A69E9cbf4eBb40DD54d7]);
        return true;
    }
    

}
// account 1  0x5b14Cc67C79a4350E75C284e34CC5f3Bc6554c93
// account 2  0x04249371f1becfa3284e59F4D529F51772a25c1a
// account 3  0x7ee4206B3135Eee33C39A69E9cbf4eBb40DD54d7