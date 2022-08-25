/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {
  address private owner;

  // event for EVM logging
  event OwnerSet(address indexed oldOwner, address indexed newOwner);

  // modifier to check if caller is owner
  modifier isOwner() {
    // If the first argument of 'require' evaluates to 'false', execution terminates and all
    // changes to the state and to Ether balances are reverted.
    // This used to consume all gas in old EVM versions, but not anymore.
    // It is often a good idea to use 'require' to check if functions are called correctly.
    // As a second argument, you can also provide an explanation about what went wrong.
    require(msg.sender == owner, "Caller is not owner");
    _;
  }

  /**
   * @dev Set contract deployer as owner
   */
  constructor() {
    owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
    emit OwnerSet(address(0), owner);
  }

  /**
   * @dev Change owner
   * @param newOwner address of new owner
   */
  function changeOwner(address newOwner) public isOwner {
    emit OwnerSet(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Return owner address
   * @return address of owner
   */
  function getOwner() external view returns (address) {
    return owner;
  }
}

pragma solidity >=0.8.14;

contract Oracle is Owner {
  struct ExchangeRate {
    uint256 fromChainId;
    address fromToken;
    uint256 toChainId;
    address toToken;
    string roundId;
    uint256 rate;
  }

  event ExchangeRateEvent(
    uint256 fromChainId,
    address indexed fromToken,
    uint256 toChainId,
    address indexed toToken,
    string roundId,
    uint256 rate
  );

  mapping(bytes32 => ExchangeRate) booking;
  mapping(bytes32 => ExchangeRate[]) history;

  constructor(address owner) {
    changeOwner(owner);
  }

  function setExchangeRate(
    uint256 fromChainId,
    address fromToken,
    uint256 toChainId,
    address toToken,
    string memory roundId,
    uint256 rate
  ) public isOwner {
    bytes32 key = getKey(fromChainId, fromToken, toChainId, toToken);
    booking[key] = ExchangeRate(
      fromChainId,
      fromToken,
      toChainId,
      toToken,
      roundId,
      rate
    );
    history[key].push(booking[key]);
    emit ExchangeRateEvent(
      fromChainId,
      fromToken,
      toChainId,
      toToken,
      roundId,
      rate
    );
  }

  function getExchangeRate(
    uint256 fromChainId,
    address fromToken,
    uint256 toChainId,
    address toToken
  ) public view returns (ExchangeRate memory) {
    bytes32 key = getKey(fromChainId, fromToken, toChainId, toToken);
    return booking[key];
  }

  function getHistoricalExchangeRates(
    uint256 fromChainId,
    address fromToken,
    uint256 toChainId,
    address toToken
  ) public view returns (ExchangeRate[] memory) {
    bytes32 key = getKey(fromChainId, fromToken, toChainId, toToken);
    return history[key];
  }

  function getKey(
    uint256 fromChainId,
    address fromToken,
    uint256 toChainId,
    address toToken
  ) public pure returns (bytes32) {
    return
      keccak256(abi.encodePacked(fromChainId, fromToken, toChainId, toToken));
  }
}