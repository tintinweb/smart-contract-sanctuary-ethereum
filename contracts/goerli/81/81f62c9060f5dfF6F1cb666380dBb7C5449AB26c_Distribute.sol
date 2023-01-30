pragma solidity ^0.8.0;

contract Distribute {
  address payable[] public recipients;
  uint[] public amounts;

  constructor() public {
  }

  function distribute(address payable[] memory _recipients, uint[] memory _amounts) public {
    require(_recipients.length == _amounts.length, "Invalid recipient/amount data");
    recipients = _recipients;
    amounts = _amounts;
    for (uint i = 0; i < recipients.length; i++) {
      recipients[i].transfer(amounts[i]);
    }
  }
}