// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../dev/VRFV2WrapperConsumerBase.sol";

contract VRFV2WrapperConsumerExample is VRFV2WrapperConsumerBase {
  struct RequestStatus {
    uint256[] randomWords;
    uint256 paid;
  }
  mapping(uint256 => RequestStatus) /* requestId */ /* requestStatus */
    public s_requests;

  constructor(address link, address vrfV2Wrapper) VRFV2WrapperConsumerBase(link, vrfV2Wrapper) {}

  function request(
    uint32 callbackGasLimit,
    uint16 requestConfirmations,
    uint32 numWords
  ) external returns (uint256 requestId) {
    requestId = requestRandomness(callbackGasLimit, requestConfirmations, numWords);
    s_requests[requestId] = RequestStatus({
      randomWords: new uint256[](0),
      paid: VRF_V2_WRAPPER.calculatePrice(callbackGasLimit)
    });
    return requestId;
  }

  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
    require(s_requests[requestId].paid > 0, "request not found");
    s_requests[requestId].randomWords = randomWords;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/LinkTokenInterface.sol";
import "./VRFV2WrapperInterface.sol";

abstract contract VRFV2WrapperConsumerBase {
  LinkTokenInterface internal immutable LINK;
  VRFV2WrapperInterface internal immutable VRF_V2_WRAPPER;

  constructor(address link, address vrfV2Wrapper) {
    LINK = LinkTokenInterface(link);
    VRF_V2_WRAPPER = VRFV2WrapperInterface(vrfV2Wrapper);
  }

  function requestRandomness(
    uint32 callbackGasLimit,
    uint16 requestConfirmations,
    uint32 numWords
  ) internal returns (uint256 requestId) {
    LINK.transferAndCall(
      address(VRF_V2_WRAPPER),
      VRF_V2_WRAPPER.calculatePrice(callbackGasLimit),
      abi.encode(callbackGasLimit, requestConfirmations, numWords)
    );
    return VRF_V2_WRAPPER.lastRequestId();
  }

  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    require(msg.sender == address(VRF_V2_WRAPPER), "only VRF V2 wrapper can fulfill");
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFV2WrapperInterface {
  function lastRequestId() external view returns (uint256);

  function calculatePrice(uint32 callbackGasLimit) external view returns (uint256);
}