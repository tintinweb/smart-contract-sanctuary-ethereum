pragma solidity >=0.8.4;
//SPDX-License-Identifier: MIT

interface ISimpleStream {
  function streamDeposit(string memory reason) external payable;
}

// custom errors to save gas
error NO_STREAMS();
error AMOUNT_TOO_LOW();
error NOT_AUSTIN();
error INVALID_ARRAY_INPUT();
error ETH_TRANSFER_FAILURE();

contract StreamMultiFunder {
  address public constant buidlGuidl = 0x97843608a00e2bbc75ab0C1911387E002565DEDE;
  address public constant austinGriffith = 0x34aA3F359A9D614239015126635CE7732c18fDF3;

  event MultiFundStreams(address indexed sender, address[] streams, uint256[] amounts, string[] reasons);

  function fundStreams(address[] memory streams, uint256[] memory amounts, string[] memory reasons) public payable {
    if (streams.length == 0) {
      revert NO_STREAMS();
    }
    if (msg.value <= 0.001 ether) {
      revert AMOUNT_TOO_LOW();
    }
    if (streams.length != amounts.length) {
      revert INVALID_ARRAY_INPUT();
    }
    if (streams.length != reasons.length) {
      revert INVALID_ARRAY_INPUT();
    }

    for (uint8 i = 0; i < streams.length;) {
        ISimpleStream thisStream = ISimpleStream(streams[i]);
        thisStream.streamDeposit{value: amounts[i]}(reasons[i]);
        unchecked {
          ++ i;
        }
    }

    emit MultiFundStreams(msg.sender, streams, amounts, reasons);
  }

  function austinCanCleanUpDust() public {
    if (msg.sender != austinGriffith) {
      revert NOT_AUSTIN();
    }
    (bool sent,) = buidlGuidl.call{value: address(this).balance}("");
    if (!sent) {
      revert ETH_TRANSFER_FAILURE();
    }
  }
}