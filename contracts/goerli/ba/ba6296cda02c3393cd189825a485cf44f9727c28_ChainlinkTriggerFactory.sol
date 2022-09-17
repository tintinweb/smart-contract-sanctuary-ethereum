// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

// import "chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// import "src/interfaces/IChainlinkTriggerFactoryEvents.sol";
// import "src/interfaces/IManager.sol";
// import "src/ChainlinkTrigger.sol";
// import "src/FixedPriceAggregator.sol";

/**
 * @notice Deploys Chainlink triggers that ensure two oracles stay within the given price
 * tolerance. It also supports creating a fixed price oracle to use as the truth oracle, useful
 * for e.g. ensuring stablecoins maintain their peg.
 */
contract ChainlinkTriggerFactory {
  /// @notice The manager of the Cozy protocol.
  address public immutable manager;

  /// @notice Maps the triggerConfigId to the number of triggers created with those configs.
  mapping(bytes32 => uint256) public triggerCount;

  // We use a fixed salt because:
  //   (a) FixedPriceAggregators are just static, owner-less contracts,
  //   (b) there are no risks of bad actors taking them over on other chains,
  //   (c) it would be nice to have these aggregators deployed to the same
  //       address on each chain, and
  //   (d) it saves gas.
  // This is just the 32 bytes you get when you keccak256(abi.encode(42)).
  bytes32 internal constant FIXED_PRICE_ORACLE_SALT = 0xbeced09521047d05b8960b7e7bcc1d1292cf3e4b2a6b63f48335cbde5f7545d2;

  /// @param _manager Address of the Cozy protocol manager.
  constructor(address _manager) {
    manager = _manager;
  }

  /// @dev Thrown when the truthOracle and trackingOracle prices cannot be directly compared.
  error InvalidOraclePair();

  /// @notice Call this function to deploy a ChainlinkTrigger.
  /// @param _truthOracle The address of the desired truthOracle for the trigger.
  /// @param _trackingOracle The address of the desired trackingOracle for the trigger.
  /// @param _priceTolerance The priceTolerance that the deployed trigger will
  /// have. See ChainlinkTrigger.priceTolerance() for more information.
  /// @param _truthFrequencyTolerance The frequency tolerance that the deployed trigger will
  /// have for the truth oracle. See ChainlinkTrigger.truthFrequencyTolerance() for more information.
  /// @param _trackingFrequencyTolerance The frequency tolerance that the deployed trigger will
  /// have for the tracking oracle. See ChainlinkTrigger.trackingFrequencyTolerance() for more information.
  function deployTrigger(
    address _truthOracle, // AggregatorV3Interface _truthOracle,
    address _trackingOracle, // AggregatorV3Interface _trackingOracle,
    uint256 _priceTolerance,
    uint256 _truthFrequencyTolerance,
    uint256 _trackingFrequencyTolerance
  ) public returns (address _trigger) {
    // if (_truthOracle.decimals() != _trackingOracle.decimals()) revert InvalidOraclePair();

    bytes32 _configId = triggerConfigId(
      _truthOracle,
      _trackingOracle,
      _priceTolerance,
      _truthFrequencyTolerance,
      _trackingFrequencyTolerance
    );

    uint256 _triggerCount = triggerCount[_configId];
    bytes32 _salt = keccak256(abi.encode(_triggerCount, block.chainid));

    // _trigger = address(new ChainlinkTrigger{salt: _salt}(
    //   manager,
    //   _truthOracle,
    //   _trackingOracle,
    //   _priceTolerance,
    //   _truthFrequencyTolerance,
    //   _trackingFrequencyTolerance
    // ));

    triggerCount[_configId] += 1;

    // emit TriggerDeployed(
    //   address(_trigger),
    //   _configId,
    //   address(_truthOracle),
    //   address(_trackingOracle),
    //   _priceTolerance,
    //   _truthFrequencyTolerance,
    //   _trackingFrequencyTolerance
    // );
  }

  /// @notice Call this function to deploy a ChainlinkTrigger with a
  /// FixedPriceAggregator as its truthOracle. This is useful if you were
  /// building a market in which you wanted to track whether or not a stablecoin
  /// asset had become depegged.
  /// @param _price The fixed price, or peg, with which to compare the trackingOracle price.
  /// @param _decimals The number of decimals of the fixed price. This should
  /// match the number of decimals used by the desired _trackingOracle.
  /// @param _trackingOracle The address of the desired trackingOracle for the trigger.
  /// @param _priceTolerance The priceTolerance that the deployed trigger will
  /// have. See ChainlinkTrigger.priceTolerance() for more information.
  /// @param _frequencyTolerance The frequency tolerance that the deployed trigger will
  /// have for the tracking oracle. See ChainlinkTrigger.trackingFrequencyTolerance() for more information.
  function deployTrigger(
    int256 _price,
    uint8 _decimals,
    address _trackingOracle, // AggregatorV3Interface _trackingOracle,
    uint256 _priceTolerance,
    uint256 _frequencyTolerance
  ) public returns (address _trigger) {
    address _truthOracle = deployFixedPriceAggregator(_price, _decimals);

    // For the truth FixedPriceAggregator peg oracle, we use a frequency tolerance of 0 since it should always return
    // block.timestamp as the updatedAt timestamp.
    return deployTrigger(_truthOracle, _trackingOracle, _priceTolerance, 0, _frequencyTolerance);
  }

  /// @notice Call this function to determine the address at which a trigger
  /// with the supplied configuration would be deployed.
  /// @param _truthOracle The address of the desired truthOracle for the trigger.
  /// @param _trackingOracle The address of the desired trackingOracle for the trigger.
  /// @param _priceTolerance The priceTolerance that the deployed trigger would
  /// have. See ChainlinkTrigger.priceTolerance() for more information.
  /// @param _truthFrequencyTolerance The frequency tolerance that the deployed trigger would
  /// have for the truth oracle. See ChainlinkTrigger.truthFrequencyTolerance() for more information.
  /// @param _trackingFrequencyTolerance The frequency tolerance that the deployed trigger would
  /// have for the tracking oracle. See ChainlinkTrigger.trackingFrequencyTolerance() for more information.
  /// @param _triggerCount The zero-indexed ordinal of the trigger with respect to its
  /// configuration, e.g. if this were to be the fifth trigger deployed with
  /// these configs, then _triggerCount should be 4.
  function computeTriggerAddress(
    address _truthOracle, // AggregatorV3Interface _truthOracle,
    address _trackingOracle, // AggregatorV3Interface _trackingOracle,
    uint256 _priceTolerance,
    uint256 _truthFrequencyTolerance,
    uint256 _trackingFrequencyTolerance,
    uint256 _triggerCount
  ) public view returns(address _address) {
    bytes memory _triggerConstructorArgs = abi.encode(
      manager,
      _truthOracle,
      _trackingOracle,
      _priceTolerance,
      _truthFrequencyTolerance,
      _trackingFrequencyTolerance
    );

    // https://eips.ethereum.org/EIPS/eip-1014
    bytes32 _bytecodeHash = keccak256(
      bytes.concat(
        bytes(""),
        // type(ChainlinkTrigger).creationCode,
        _triggerConstructorArgs
      )
    );
    bytes32 _salt = keccak256(abi.encode(_triggerCount, block.chainid));
    bytes32 _data = keccak256(bytes.concat(bytes1(0xff), bytes20(address(this)), _salt, _bytecodeHash));
    _address = address(uint160(uint256(_data)));
  }

  /// @notice Call this function to find triggers with the specified
  /// configurations that can be used for new markets in Sets.
  /// @dev If this function returns the zero address, that means that an
  /// available trigger was not found with the supplied configuration. Use
  /// `deployTrigger` to deploy a new one.
  /// @param _truthOracle The address of the desired truthOracle for the trigger.
  /// @param _trackingOracle The address of the desired trackingOracle for the trigger.
  /// @param _priceTolerance The priceTolerance that the deployed trigger will
  /// have. See ChainlinkTrigger.priceTolerance() for more information.
  /// @param _truthFrequencyTolerance The frequency tolerance that the deployed trigger will
  /// have for the truth oracle. See ChainlinkTrigger.truthFrequencyTolerance() for more information.
  /// @param _trackingFrequencyTolerance The frequency tolerance that the deployed trigger will
  /// have for the tracking oracle. See ChainlinkTrigger.trackingFrequencyTolerance() for more information.
  function findAvailableTrigger(
    address _truthOracle,
    address _trackingOracle,
    uint256 _priceTolerance,
    uint256 _truthFrequencyTolerance,
    uint256 _trackingFrequencyTolerance
  ) public view returns(address) {

    bytes32 _counterId = triggerConfigId(
      _truthOracle,
      _trackingOracle,
      _priceTolerance,
      _truthFrequencyTolerance,
      _trackingFrequencyTolerance
    );
    uint256 _triggerCount = triggerCount[_counterId];

    for (uint256 i = 0; i < _triggerCount; i++) {
      address _computedAddr = computeTriggerAddress(
        _truthOracle,
        _trackingOracle,
        _priceTolerance,
        _truthFrequencyTolerance,
        _trackingFrequencyTolerance,
        i
      );

      // ChainlinkTrigger _trigger = ChainlinkTrigger(_computedAddr);
      // if (_trigger.getSetsLength() < _trigger.MAX_SET_LENGTH()) {
      //   return _computedAddr;
      // }
    }

    return address(0); // If none is found, return zero address.
  }

  /// @notice Call this function to determine the identifier of the supplied trigger
  /// configuration. This identifier is used both to track the number of
  /// triggers deployed with this configuration (see `triggerCount`) and is
  /// emitted at the time triggers with that configuration are deployed.
  /// @param _truthOracle The address of the desired truthOracle for the trigger.
  /// @param _trackingOracle The address of the desired trackingOracle for the trigger.
  /// @param _priceTolerance The priceTolerance that the deployed trigger will
  /// have. See ChainlinkTrigger.priceTolerance() for more information.
  /// @param _truthFrequencyTolerance The frequency tolerance that the deployed trigger will
  /// have for the truth oracle. See ChainlinkTrigger.truthFrequencyTolerance() for more information.
  /// @param _trackingFrequencyTolerance The frequency tolerance that the deployed trigger will
  /// have for the tracking oracle. See ChainlinkTrigger.trackingFrequencyTolerance() for more information.
  function triggerConfigId(
    address _truthOracle,
    address _trackingOracle,
    uint256 _priceTolerance,
    uint256 _truthFrequencyTolerance,
    uint256 _trackingFrequencyTolerance
  ) public view returns (bytes32) {
    bytes memory _triggerConstructorArgs = abi.encode(
      manager,
      _truthOracle,
      _trackingOracle,
      _priceTolerance,
      _truthFrequencyTolerance,
      _trackingFrequencyTolerance
    );
    return keccak256(_triggerConstructorArgs);
  }

  /// @notice Call this function to deploy a FixedPriceAggregator contract,
  /// which behaves like a Chainlink oracle except that it always returns the
  /// same price.
  /// @dev If the specified contract is already deployed, we return it's address
  /// instead of reverting to avoid duplicate aggregators
  /// @param _price The fixed price, in the decimals indicated, returned by the deployed oracle.
  /// @param _decimals The number of decimals of the fixed price.
  function deployFixedPriceAggregator(
    int256 _price, // An int (instead of uint256) because that's what's used by Chainlink.
    uint8 _decimals
  ) public returns (address) {
    address _oracleAddress = computeFixedPriceAggregatorAddress(_price, _decimals);
    if (_oracleAddress.code.length > 0) return _oracleAddress;
    // return address(new FixedPriceAggregator{salt: FIXED_PRICE_ORACLE_SALT}(_decimals, _price));
  }

  /// @notice Call this function to compute the address that a
  /// FixedPriceAggregator contract would be deployed to with the provided args.
  /// @param _price The fixed price, in the decimals indicated, returned by the deployed oracle.
  /// @param _decimals The number of decimals of the fixed price.
  function computeFixedPriceAggregatorAddress(
    int256 _price, // An int (instead of uint256) because that's what's used by Chainlink.
    uint8 _decimals
  ) public view returns (address) {
    bytes memory _aggregatorConstructorArgs = abi.encode(_decimals, _price);
    bytes32 _bytecodeHash = keccak256(
      bytes.concat(
        bytes(""),
        // type(FixedPriceAggregator).creationCode,
        _aggregatorConstructorArgs
      )
    );
    bytes32 _data = keccak256(
      bytes.concat(
        bytes1(0xff),
        bytes20(address(this)),
        FIXED_PRICE_ORACLE_SALT,
        _bytecodeHash
      )
    );
    return address(uint160(uint256(_data)));
  }
}