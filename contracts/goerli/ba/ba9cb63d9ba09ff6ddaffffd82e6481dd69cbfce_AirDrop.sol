/**
 *Submitted for verification at Etherscan.io on 2022-11-28
*/

pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external pure returns (uint8);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract AirDrop{
    address public owner;
    address public tokenAddress;
    uint256 public totalAmount;
    uint256 public totalClaimed;
    uint256 public totalUsers;
    uint256 public airDropMax;
    uint256 public totalAirDropClaimed;
    uint256 public airDropAmount;

    struct User{
        address userAddress;
        uint256 amount;
        bool claimed;
        bool isWhitelisted;
        bool airDropClaimed;
    }

    mapping(address => User) public users;

    constructor(address _tokenAddress){
        owner = msg.sender;
        tokenAddress = _tokenAddress;
        airDropMax = 100_000 * 10 ** IERC20(tokenAddress).decimals();
        airDropAmount = 100 * 10 ** IERC20(tokenAddress).decimals();
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function PrivateAirDrop(address[] memory _users, uint256[] memory _amounts) public onlyOwner{
        require(_users.length == _amounts.length, "Invalid data");
        for(uint256 i = 0; i < _users.length; i++){
              uint256 amount = _amounts[i] * 10 ** IERC20(tokenAddress).decimals();
                users[_users[i]].amount = amount;
                users[_users[i]].userAddress = _users[i];
                users[_users[i]].isWhitelisted = true;
                users[_users[i]].claimed = false;
                totalAmount += amount;
                totalUsers++;
            
        }
    }

    function PublicAirDrop() public{
        require(!users[msg.sender].airDropClaimed,"You have already claimed");
        require(totalAirDropClaimed + airDropAmount <= airDropMax,"Airdrop is over");
        users[msg.sender].airDropClaimed = true;
        totalAirDropClaimed += airDropAmount;
        IERC20(tokenAddress).transfer(msg.sender,airDropAmount);
    }

    function claim() public{
        require(users[msg.sender].isWhitelisted, "You are not whitelisted");
        require(!users[msg.sender].claimed, "You have already claimed");
        require(IERC20(tokenAddress).transfer(msg.sender, users[msg.sender].amount), "Transfer failed");
        users[msg.sender].claimed = true;
        totalClaimed += users[msg.sender].amount;
    }

    function withdraw(uint256 _amount,address _tokenAddress) external onlyOwner{
        require(IERC20(_tokenAddress).transfer(msg.sender, _amount), "Transfer failed");
    }

    function withdrawAll(address _tokenAddress) external onlyOwner{
        require(IERC20(_tokenAddress).transfer(msg.sender, IERC20(_tokenAddress).balanceOf(address(this))), "Transfer failed");
    }

    function setAirDropValues(uint256 _airDropMax, uint256 _airDropAmount) public onlyOwner{
        airDropMax = _airDropMax;
        airDropAmount = _airDropAmount;
    }

    function getContractTokenBalance()external view returns(uint256){
        return IERC20(tokenAddress).balanceOf(address(this));
    }

}