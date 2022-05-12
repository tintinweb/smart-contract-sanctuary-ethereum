/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

pragma solidity ^0.4.26;

contract presell{

    address public owner;
    uint256 public totalPresell;
    uint256 public totalProject;
    uint256 public totalReferrals;
    mapping (address => uint256) public myPresell; 
    mapping (address => address) public referrals; 
  
    //event transfer(uint256 value);  
    event GetUsetInfo(address indexed  user, address referral,uint256 presell);
    event Transfer(address indexed  user, address project, address recommend, uint256 actual, uint256 fee, uint256 value);
    
    constructor() public{
        owner=msg.sender;
    }

    function getTotalPresell() public view returns(uint256){
        return totalPresell;
    }
     function getTotalProject() public view returns(uint256){
        return totalProject;
    }
     function getTotalReferrals() public view returns(uint256){
        return totalReferrals;
    }
     function getMyPresell(address user) public view returns(uint256){
        
        return myPresell[user];
    }
    function getReferrals(address user) public view returns(address){
        
        return referrals[user];
    }
    function buyPreSell(address project,address recommend) public payable{ 

        if(referrals[msg.sender] == address(0)){   
            if(recommend != address(0) && project !=recommend){
                referrals[msg.sender] = recommend;
            }
        }
        if(referrals[msg.sender] != address(0)){
            recommend=referrals[msg.sender];
        }else{
             recommend=project;
        }

        uint256 fee=devFee(msg.value);
        totalPresell=SafeMath.add(totalPresell,msg.value);
        totalProject=SafeMath.add(totalProject,SafeMath.sub(msg.value,fee));
        totalReferrals=SafeMath.add(totalReferrals,fee);
        myPresell[msg.sender]=SafeMath.add(myPresell[msg.sender],msg.value);

        project.transfer(SafeMath.sub(msg.value,fee));
        recommend.transfer(fee);
        
        emit Transfer(msg.sender,project,recommend,SafeMath.sub(msg.value,fee),fee, msg.value);
        emit GetUsetInfo(msg.sender,referrals[msg.sender],myPresell[msg.sender]);
    }

    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,20),100);
    }
}

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}