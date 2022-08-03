/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IERC20 {
 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);

  
    function balanceOf(address account) external view returns (uint256);

  
    function transfer(address to, uint256 amount) external returns (bool);

  
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
interface ICoin{

  
    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
contract Escrow
{
    ICoin coin;
    IERC20 token;
    address payable public escrowOwner;
    uint256 TotalTokens;
    uint256 public totalCoins;
    uint256 public token_per_user;
    address payable claimer;
    uint256 _coin = 300;
    bool sendtokensescrow ;
       mapping(address => bool) result;
    modifier onlyowner{
      require (msg.sender == escrowOwner);
      _;
  }
      modifier onlyclaimer{
      require (msg.sender == claimer);
      _;
  }

           function claimtoken() external onlyclaimer {
      


        require(result[msg.sender] == true, "you have already taken");
 
             token.transferFrom(address(this), msg.sender,token_per_user);
                    result[msg.sender] = false;


      }
      function update_Coins(uint256 coins)external onlyowner 
      {
          totalCoins = coins;
      }
      function update_token_PerUser(uint256 newTokens)external onlyowner 
      {
            token_per_user = newTokens;
      }
      function claimCoin()  public onlyowner 
    {


           coin.transferFrom(address(this),msg.sender, totalCoins);
    }}