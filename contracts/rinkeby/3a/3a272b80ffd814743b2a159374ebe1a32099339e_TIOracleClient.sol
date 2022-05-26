/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IOracleCallbackInterface {
   
    function rawFulfillOracleRequest(
        bytes32 requestId,
        int256 price,
        uint256 updatedAt
    ) external returns (bool);
}
abstract contract ConsumerBase is IOracleCallbackInterface {
    address private immutable aggregator;

    constructor(address _aggregator) {
        aggregator = _aggregator;
    }

    function fulfillOracleRequest(
        bytes32 requestId,
        int256 price,
        uint256 updatedAt
    ) internal virtual;

    function rawFulfillOracleRequest(
        bytes32 requestId,
        int256 price,
        uint256 updatedAt
    ) external override returns (bool) {
        require(msg.sender == aggregator, "sender is not aggregator");
        //TODO gas
        fulfillOracleRequest(requestId, price, updatedAt);
        return true;
    }
}


interface IAggregatorInterface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function payToken() external view returns (address);

    function latestData()
        external
        view
        returns (int256 price, uint256 updatedAt);

}


interface IOracleRequestInterface {
    function oracleRequest(address callbackAddress) external returns (bytes32);

    function oracleRequestFree(address callbackAddress)
        external
        returns (bytes32);

    function fulfillOracleRequest(
        bytes32 requestId,
        int256 price,
        uint256 updatedAt
    ) external returns (bool);
}


contract TIOracleClient is ConsumerBase {
  
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }
    uint256 public price;
    uint256 public updateTime;
    IAggregatorInterface priceAggregator;
    IOracleRequestInterface oracleRequest;
    bytes32 public rid;
    address aggregatorAddress = 0xF788D705d26a0637b5dA16fD18c3b67DFA4047bA;
    constructor()  ConsumerBase(aggregatorAddress) {
        oracleRequest = IOracleRequestInterface(aggregatorAddress);
        priceAggregator = IAggregatorInterface(aggregatorAddress);
        safeApprove(priceAggregator.payToken(), aggregatorAddress, type(uint256).max);
    }

    function fulfillOracleRequest(
        bytes32 requestId,
        int256 priceResult,
        uint256 updatedAt
    ) internal override {
        price = uint256(priceResult);
        updateTime = updatedAt;
      requestId;
    }

    function sendQuery() external {
        rid = oracleRequest.oracleRequestFree(address(this));
    }
}