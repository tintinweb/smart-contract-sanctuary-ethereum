/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

pragma solidity 0.8.1;

interface IERC20 { 
	
	function transfer(address to, uint256 amount) external returns (bool);

	function transferFrom(address from, address to, uint256 amount) external returns (bool);

	function balanceOf(address owner) external returns (uint256);

	function approve(address spender, uint256 amount) external;
	
}

interface ISablier { 
	
	function cancelStream(uint256 streamId) external returns (bool);

	function balanceOf(uint256 streamId, address who) external returns (uint256);

	function createStream(
		address recipent, 
		uint256 deposit, 
		address tokenAddress, 
		uint256 startTime, 
		uint256 stopTime
	) external  returns (uint256);

}	

contract Proposal  {

  function executeProposal() external {
    uint256 COMMUNITY_FUND_STREAM_ID = 103358;
    uint256 FISCAL_Q_DURATION = 91 days;

    uint256 RENUMERATION_START_TS = block.timestamp;
    uint256 RENUMERATION_AMOUNT = 10058 ether;
    uint256 RENUMERATION_NORMALISED_AMOUNT = RENUMERATION_AMOUNT - (RENUMERATION_AMOUNT % FISCAL_Q_DURATION);
    address RENUMERATION_ADDRESS = 0x40d16C473CB7bF5fAB9713b27A4562EAa6f915d1;

    address tokenAddress = 0x77777FeDdddFfC19Ff86DB637967013e6C6A116C;
    address sablierAddress = 0xCD18eAa163733Da39c232722cBC4E8940b1D8888;
    
    IERC20(tokenAddress).approve(sablierAddress, RENUMERATION_NORMALISED_AMOUNT);

    ISablier(sablierAddress).cancelStream(COMMUNITY_FUND_STREAM_ID);    
    ISablier(sablierAddress).createStream(
      RENUMERATION_ADDRESS,
      RENUMERATION_NORMALISED_AMOUNT,
      tokenAddress,
      RENUMERATION_START_TS,
      RENUMERATION_START_TS + FISCAL_Q_DURATION
    );
  }

}