pragma solidity ^0.8.0;
import "./IERC20.sol";
contract Timelock {
  uint public constant duration = 1 days;
  uint public end;
  address payable public immutable owner;

  constructor(address payable _owner) {
    end = block.timestamp + duration;
    owner = _owner;
  }

  receive() external payable {}

  /**
   * @notice transfer the tokens to a owner
   */
  function withdraw(address token, uint amount) external {
    require(msg.sender == owner, 'only owner');
    require(block.timestamp >= end, 'too early');
    IERC20(token).transfer(owner, amount);
  }
  
  /**
   * @notice set a new blocking time period
   */
  function incrementLock() external {
    require(msg.sender == owner, 'only owner');
    end = block.timestamp + duration;
  }
  
  /**
   * @notice transfer the eth to a owner
   */
  function withdrawEth(uint amount) external {
    require(msg.sender == owner, 'only owner');
    require(block.timestamp >= end, 'too early');
      owner.transfer(amount);
  }
}