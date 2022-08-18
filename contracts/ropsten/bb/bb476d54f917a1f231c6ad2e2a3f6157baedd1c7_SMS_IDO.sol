/**
 *Submitted for verification at Etherscan.io on 2022-08-16
*/

// SPDX-License-Identifier: MIT 
pragma solidity ^0.8;

/**
 *Submitted for verification at BscScan.com on 2021-06-28
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-28
*/

interface IBEP20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract SMS_IDO {
    using SafeMath for uint256;

    IBEP20 SMS;
    IBEP20 busd;
    address payable public  owner;
    uint256 public rate;
    uint256 public percentage;
    mapping(address=>address) alladdress;
    

   event TransferBUSD(address indexed from, address indexed to, uint256 value ,uint256 time);

    event TransferSMT(address indexed owner, address indexed spender, uint256 value,uint256 time);
    
    constructor(IBEP20 _SMS,IBEP20 _busd){
        SMS=_SMS;
        busd = _busd;
//        owner=msg.sender;
    }
    
    modifier onlyOwner{
        require(msg.sender==owner);
        _;
    }
    
    function buyTokens(uint256 _busdAmount) public 
    {
    
        require(busd.balanceOf(msg.sender) >= _busdAmount,"User Have not BUSD.");
        
        require(_busdAmount >= 50*10**18,"min 50 busd.");
        busd.transferFrom(msg.sender,address(this),_busdAmount);
        uint256 tokens = _getTokenAmount(_busdAmount);
        require(SMS.balanceOf(address(this)) >= tokens,"contract Have not SMS");
        SMS.transfer(msg.sender, tokens);
        
        emit TransferBUSD(msg.sender,address(this),_busdAmount , block.timestamp);
        emit TransferSMT(address(this),msg.sender,tokens, block.timestamp);
    }
    
    function _getTokenAmount(uint256 _busdAmount)public view returns (uint256){
         uint256 calTokens=_busdAmount/rate;
        uint256 reward=calTokens*percentage/100;
        uint256 totalAmount= (calTokens+reward)*10*8;
        return totalAmount;
    }
    
    function setRate(uint256 _Rate)public onlyOwner{
        rate=_Rate;
    }
    
    function setPercentage(uint256 _Percentage)public onlyOwner{
        percentage=_Percentage;
    }
    function withDrawBUsd(uint256 _amount)onlyOwner public{
        busd.transfer(msg.sender, _amount*10**18);
    }
    function withDrawSMS(uint256 _amount)onlyOwner public{
        SMS.transfer(msg.sender, _amount*10**18);
    }
    




    function getaddresses(address _user) public view returns(address,address,address){
    
    //    (uint256 a, uint256 b, uint256 c) = getaddress(amount1);
       address add1;
       address add2;
       address add3;
        for(uint256 i=0; i<3; i++){
             add1 = getaddress(_user);
          //  token.transferFrom(address(this),add1,a);
             add2 = getaddress(add1);
             add3 = getaddress(add2);
          //  payable(add3).transfer(1);
        }
        return(add1,add2,add3);
    }

    function getaddress(address _user) public view returns(address){
        return alladdress[_user];
    }

function BuyToken(address referredBy) public payable{
    require(msg.value>=1 ether,"Value should be more than 1 ether");
//    require(referredBy==address(0),"Please add a valid referred address");
    
         alladdress[referredBy]=msg.sender;
         (uint256 refr1, uint256 refr2, uint256 refr3) = getValues(msg.value);
         (address refrelAdd1, address refrelAdd2, address refrelAdd3) = getaddresses(referredBy);
         payable(refrelAdd1).transfer(refr1);
         payable(refrelAdd2).transfer(refr2);
         payable(refrelAdd3).transfer(refr3);



    }
    function getValues(uint256 _amount) public pure returns(uint256,uint256,uint256)
    {
        uint256 amount = _amount; 
        uint256 for1 = amount.mul(30).div(100);
        uint256 for2 =  amount.mul(10).div(100);
        uint256 for3 =  amount.mul(10).div(100);

            return(for1,for2,for3);
    }
}