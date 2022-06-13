/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

// File: contracts/testing.sol



pragma solidity ^0.8.10;

interface IERC20 
{

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);


}

contract TestFunding
{

    mapping(address => uint) public users;

    address public owner;

    uint public minimumDeposit;

    uint public totalDeposit;

    uint public noOfUsers;

    constructor(){
        owner = msg.sender;
    }
    
    function depositToken(address _token,uint _amount) public {
        
         IERC20(_token).approve(address(this), _amount);
        IERC20(_token).transferFrom(msg.sender,address(this),_amount);
    }
    
       function depositToken2(address _token,uint _amount) public {

        IERC20(_token).transfer(address(this), _amount);
    }
    
    
    function getUserBalance() public view returns(uint)
    {
     return users[msg.sender];   
    }
    
    function getCurrentBalance(address _token) public view returns(uint)
    {
     return IERC20(_token).balanceOf(address(this)) ; 
    }
    
    function getTokenBalance(address _token,address _account) public view returns(uint)
    {
     return IERC20(_token).balanceOf(_account) ; 
    }
    
    
    
    function withdrawToken(address _token,uint _amount) public
    {
    
    IERC20(_token).approve(msg.sender, _amount);
    IERC20(_token).transferFrom(address(this),msg.sender,_amount);
    
    }
    
}