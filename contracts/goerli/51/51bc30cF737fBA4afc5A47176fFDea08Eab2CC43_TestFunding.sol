/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

// SPDX-License-Identifier: MIT

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

    //mapping(address => uint) public users;
    mapping(address=>bool) public OpKeys;
    mapping(address=>bool) public AuthToken;

    address public owner;
    //address public u_server;

   // uint public minimumDeposit;

    //uint public totalDeposit;

    //uint public noOfUsers;

    event MoneySent(address indexed _from, uint256 indexed uid,uint256 _amount);

    constructor(){
        owner = msg.sender;
    }
    
    
    function depositToken(address _token,uint256 _amount,uint256 user_id) public {
        require(AuthToken[_token],"Not Supported Token");
        //IERC20(_token).approve(address(this), _amount);
        IERC20(_token).transferFrom(msg.sender,address(this),_amount);
        emit MoneySent(msg.sender,user_id,_amount);
    }
    
   //    function depositToken2(address _token,uint _amount) public {
//
     //   IERC20(_token).transfer(address(this), _amount);
    //}
    
    
    //function getUserBalance() public view returns(uint)
    //{
    // return users[msg.sender];   
    //}
    
    //function getCurrentBalance(address _token) public view returns(uint)
    //{
    // return IERC20(_token).balanceOf(address(this)) ; 
   // }
    
    //function getTokenBalance(address _token,address _account) public view returns(uint)
    //{
    // return IERC20(_token).balanceOf(_account) ; 
    //}
    
    function insertOpkey(address _account) public
    {
        require(msg.sender==owner,"Not Authorized");
        OpKeys[_account]=true;
    }
    function InsertToken(address _account) public
    {
        require(msg.sender==owner, "Not Authorized");
        AuthToken[_account]=true;
    }
    function deleteOpkey(address _account) public
    {
        require(msg.sender==owner && OpKeys[_account]==true,"Not Authorized");
        OpKeys[_account]=false;
    }
    
    function withdrawToken(address _token,uint _amount) public
    {
    require (AuthToken[_token],"Not Supported Token");
    require(msg.sender==owner || OpKeys[msg.sender]==true,"Not Authorized");
    //IERC20(_token).approve(msg.sender, _amount);
    IERC20(_token).transfer(msg.sender,_amount);
    }
    
}