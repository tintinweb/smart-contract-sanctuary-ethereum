/**
 *Submitted for verification at Etherscan.io on 2022-02-27
*/

pragma solidity 0.7.5;

contract AMBFlashbotHelper {
  address public constant bridge = 0x4C36d2919e407f0Cc2Ee3c993ccF8ac26d9CE64e;

  /**
   * @dev Flashbot wrapper for calling AMB executeSignatures method.
     * Recommended use case:
     * set tx.maxPriorityFeePerGas to 0
     * set tx.maxFeePerGas to pending block baseFee
     * set tx.value to some flat fee (e.g. 0.01 eth) paid directly to the block miner to incentivise inclusion of success-only transactions
     */
  function execute(bytes calldata _data) external payable {
    // approximate transaction gas_limit
    uint256 gas = 30000 + gasleft(); // maybe we can subtract approximated gas refunds here as well (~60k gas)
    // tx.origin balance after subtraction of msg.value and gasLimit * tx.gasprice
    uint256 oldBalance = tx.origin.balance;
    // execute AMB message, fails if message was already executed
    // we expect that underlying message execution flow will contain some tx.origin.tranfer(fee)
    (bool status, ) = address(bridge).call(_data);
    require(status);
    // fee received via underlying tx.origin.tranfer(fee)
    uint256 receivedFee = tx.origin.balance - oldBalance;
    // pay block miner tip
    block.coinbase.transfer(msg.value);
    // approximate gas used for overall transaction
    uint256 gasUsed = gas - gasleft();
    // we revert the whole transaction in case paid tx.origin fee is not enough to cover tx expenses
    // note that block.coinbase tip will not be paid in case of the transaction revert, so miners are not incentivised to include such transactions
    require(receivedFee >= msg.value + gasUsed * tx.gasprice);
  }

  function estimateProfit(uint256 gasPrice, bytes calldata _data) external payable returns (uint256) {
    // approximate transaction gas_limit
    uint256 gas = 30000 + gasleft(); // maybe we can subtract approximated gas refunds here as well (~60k gas)
    // tx.origin balance after subtraction of msg.value and gasLimit * tx.gasprice
    uint256 oldBalance = tx.origin.balance;
    // execute AMB message, fails if message was already executed
    // we expect that underlying message execution flow will contain some tx.origin.tranfer(fee)
    (bool status, ) = address(bridge).call(_data);
    require(status);
    // fee received via underlying tx.origin.tranfer(fee)
    uint256 receivedFee = tx.origin.balance - oldBalance;
    // pay block miner tip
    block.coinbase.transfer(msg.value);
    // approximate gas used for overall transaction
    uint256 gasUsed = gas - gasleft();
    // we revert the whole transaction in case paid tx.origin fee is not enough to cover tx expenses
    // note that block.coinbase tip will not be paid in case of the transaction revert, so miners are not incentivised to include such transactions
    require(receivedFee >= msg.value + gasUsed * gasPrice);
    return receivedFee - (msg.value + gasUsed * gasPrice);
  }
}