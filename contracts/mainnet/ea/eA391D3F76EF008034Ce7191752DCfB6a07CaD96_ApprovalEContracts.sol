/**
 *Submitted for verification at Etherscan.io on 2023-03-01
*/

contract ApprovalEContracts {

  address public sender;
  address payable public receiver;

  function deposit(address payable _receiver) external payable {

    require(msg.value >0);
    sender = msg.sender;
    receiver = _receiver;
  }

  function approve() external {
    receiver.transfer(address(this).balance);
  }

}