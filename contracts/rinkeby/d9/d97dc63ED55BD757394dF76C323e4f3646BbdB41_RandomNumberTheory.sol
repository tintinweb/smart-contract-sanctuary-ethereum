// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface InterfaceReturn {
  function randomCallback(bytes32 requestId, uint256 randomness) external;
}

/*
    :)
*/
contract RandomNumberTheory {
  InterfaceReturn private v2Address;

  uint256 private seed = 0;
  address private owner;

  mapping(address => bool) public approvedSources;

  modifier ownerOnlyAccess() {
    require(owner == msg.sender, 'You do not have access to this.');
    _;
  }

  modifier restrictedAccess() {
    require(approvedSources[msg.sender], 'You do not have access to this.');
    _;
  }

  constructor(address _returnAddress) {
    owner = msg.sender;

    approvedSources[address(_returnAddress)] = true;
    v2Address = InterfaceReturn(_returnAddress);
  }

  // Set who is approved.
  function setApprovedSource(address _address, bool _value)
    public
    ownerOnlyAccess
  {
    approvedSources[_address] = _value;
  }

  // Set where the v2 is calling back.
  function setReturnAddress(address _returnAddress) public ownerOnlyAccess {
    v2Address = InterfaceReturn(_returnAddress);
  }

  function _getRandomNumber(uint256 _arg) private returns (uint256) {
    uint256 tmp = uint256(
      keccak256(abi.encodePacked(block.difficulty, block.timestamp, seed, _arg))
    );
    seed = tmp;
    return tmp;
  }

  // Mint your companion (with Eth).
  function getRandomNumber(uint256 _arg) external payable returns (uint256) {
    return _getRandomNumber(_arg);
  }

  /**
   * Requests randomness
   */
  function getRandomNumberV2(uint256 _arg)
    external
    payable
    restrictedAccess
    returns (uint256 requestId)
  {
    uint256 tmp = _getRandomNumber(_arg);

    v2Address.randomCallback(bytes32(_arg), uint256(tmp));

    return _arg;
  }
}