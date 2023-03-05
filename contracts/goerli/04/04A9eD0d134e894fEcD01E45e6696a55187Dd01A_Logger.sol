/**
 *Submitted for verification at Etherscan.io on 2023-03-05
*/

contract Logger {
  struct Message {
    address sender;
    uint256 amount;
    string note;
  }

  Message[] History;
  Message public LastLine;

  function LogTransfer(address _sender, uint256 _amount, string memory _note) public {
    LastLine.sender = _sender;
    LastLine.amount = _amount;
    LastLine.note = _note;
    History.push(LastLine);
  }
}