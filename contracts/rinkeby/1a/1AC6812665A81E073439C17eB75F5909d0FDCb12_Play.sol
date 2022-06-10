//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

contract Play {
  address public owner;
  string private notetext;

  event Receive(address _sender, uint256 _value, uint256 _timestamp);
  event Fallback(address _sender, uint256 _value, uint256 _timestamp);

  modifier onlyOwner() {
    require(msg.sender == owner, "onlyOwner");
    _;
  }

  constructor(string memory _notetext) {
    owner = msg.sender;
    notetext = _notetext;
  }

  function note() public view returns (string memory) {
    return notetext;
  }

  function setNotetext(string memory _notetext) public {
    notetext = _notetext;
  }

  //   提取合约内资金
  function withdraw() public onlyOwner {
    // payable(msg.sender).transfer(address(this).balance);

    (bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
    require(success);
  }

  // 销毁
  function destroy() public {
    // 销毁合约之前, 需要把合约里的钱转出
    // myToken.transfer(owner, myToken.balanceOf(address(this)));

    withdraw();
    selfdestruct(payable(owner));
  }

  receive() external payable {
    emit Receive(msg.sender, msg.value, block.timestamp);
  }

  fallback() external payable {
    emit Fallback(msg.sender, msg.value, block.timestamp);
  }
}