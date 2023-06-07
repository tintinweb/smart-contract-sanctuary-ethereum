//SPDX-License-Identifier: UNLICENSED
pragma solidity >0.8.0;

import {IEAS} from "./IEAS.sol";
import {IChainlinkFunctionsClient} from "./IChainlinkFunctionsClient.sol";

contract FunctionClient {
  enum Location {
    Inline,
    Remote
  }

  enum CodeLanguage {
    JavaScript
  }

  struct Request {
    Location codeLocation;
    Location secretsLocation;
    CodeLanguage language;
    string source;
    bytes secrets;
    string[] args;
  }

  struct Schema {
    address wallet;
    address burnedTokenAddress;
    uint256 burnedAmount;
  }

  IEAS public eas;
  bytes32 public schema;

  mapping(address => bool) public isUserWhitelisted;

  constructor(IEAS _eas, bytes32 _schema) {
    schema = _schema;
    eas = _eas;
  }

  function whitelistUser(address user) external {
    isUserWhitelisted[user] = true;
  }

  function revokeUser(address user) external {
    isUserWhitelisted[user] = false;
  }

  function getRegistry() external view returns (address) {
    return address(eas);
  }

  function sendRequest(
    uint64 subscriptionId,
    bytes calldata data,
    uint32 gasLimit,
    address phoenix
  ) external returns (bytes32) {
    Request memory request = abi.decode(data, (Request));

    address user = address(bytes20(bytes(request.args[0])));
    address token = address(bytes20(bytes(request.args[1])));
    // uint256 amount = abi.decode(bytes(request.args[2]), (uint256));
    uint256 amount = 100;

    Schema memory schemaData = Schema({wallet: user, burnedTokenAddress: token, burnedAmount: amount});

    if (isUserWhitelisted[user]) {
      IEAS.AttestationRequest memory attestationRequest = IEAS.AttestationRequest({
        schema: schema,
        data: IEAS.AttestationRequestData({
          recipient: user,
          expirationTime: 0,
          revocable: false,
          refUID: 0,
          data: abi.encode(schemaData),
          value: 0
        })
      });

      eas.attest(attestationRequest);

      IChainlinkFunctionsClient(msg.sender).fulfillRequest(0, "", "", phoenix, user);
    }

    return 0;
  }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >0.8.0;

interface IChainlinkFunctionsClient {
  function sendBurnProofRequest(
    address _user,
    address _burnedTokenAddress,
    uint256 _validFrom,
    uint256 _validUntil,
    string memory _transactionHash
  ) external;

  function fulfillRequest(
    bytes32 requestId,
    bytes memory response,
    bytes memory err,
    address callbackContract,
    address user
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEAS {
  struct AttestationRequestData {
    address recipient;
    uint64 expirationTime;
    bool revocable;
    bytes32 refUID;
    bytes data;
    uint256 value;
  }

  struct AttestationRequest {
    bytes32 schema;
    AttestationRequestData data;
  }

  function attest(AttestationRequest calldata request) external payable returns (bytes32);
}