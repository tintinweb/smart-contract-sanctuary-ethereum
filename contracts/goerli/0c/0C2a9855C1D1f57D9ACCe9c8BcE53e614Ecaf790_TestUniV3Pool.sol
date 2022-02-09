pragma solidity >=0.8.4 <0.9.0;

import '../interfaces/testnets/ITestUniV3Pool.sol';

contract TestUniV3Pool is ITestUniV3Pool {
  uint24 public override fee;
  address public override token0;
  address public override token1;

  uint256 public override burnAmount0;
  uint256 public override burnAmount1;

  uint128 public override collectAmount0;
  uint128 public override collectAmount1;

  uint128 public override positionLiquidity;
  uint256 public override positionFeeGrowthInside0LastX128;
  uint256 public override positionFeeGrowthInside1LastX128;
  uint128 public override positionTokensOwed0;
  uint128 public override positionTokensOwed1;

  uint160 public override slot0SqrtPriceX96;

  uint256 public override mintAmount0;
  uint256 public override mintAmount1;

  int56 public override desiredTwap;

  function burn(
    int24 _tickLower,
    int24 _tickUper,
    uint128 _amount
  ) public override returns (uint256 _amount0, uint256 _amount1) {
    _amount0 = burnAmount0;
    _amount1 = burnAmount1;
  }

  function collect(
    address _recipient,
    int24 _tickLower,
    int24 _tickUpper,
    uint128 _amount0Requested,
    uint128 _amount1Requested
  ) public override returns (uint128 _amount0, uint128 _amount1) {
    _amount0 = collectAmount0;
    _amount1 = collectAmount1;
  }

  function positions(bytes32 _data)
    public
    view
    override
    returns (
      uint128 liquidity,
      uint256 feeGrowthInside0LastX128,
      uint256 feeGrowthInside1LastX128,
      uint128 tokensOwed0,
      uint128 tokensOwed1
    )
  {
    liquidity = positionLiquidity;
    feeGrowthInside0LastX128 = positionFeeGrowthInside0LastX128;
    feeGrowthInside1LastX128 = positionFeeGrowthInside1LastX128;
    tokensOwed0 = positionTokensOwed0;
    tokensOwed1 = positionTokensOwed1;
  }

  function slot0()
    public
    override
    returns (
      uint160 _sqrtPriceX96,
      int24 _tick,
      uint16 _observationIndex,
      uint16 _observationCardinality,
      uint16 _observationCardinalityNext,
      uint8 _feeProtocol,
      bool _locked
    )
  {
    _sqrtPriceX96 = slot0SqrtPriceX96;
    _tick = 0;
    _observationIndex = 0;
    _observationCardinality = 0;
    _observationCardinalityNext = 0;
    _feeProtocol = 0;
    _locked = false;
  }

  function mint(
    address _recipient,
    int24 _tickLower,
    int24 _tickUpper,
    uint128 _amount,
    bytes calldata _data
  ) external override returns (uint256 _amount0, uint256 _amount1) {
    _amount0 = mintAmount0;
    _amount1 = mintAmount1;
  }

  function observe(uint32[] memory _secondsAgo) public view override {}

  function setFee(uint24 _fee) external override {
    fee = _fee;
  }

  function setToken0(address _token0) external override {
    token0 = _token0;
  }

  function setToken1(address _token1) external override {
    token1 = _token1;
  }

  function setBurnAmount0(uint256 _burnAmount0) external override {
    burnAmount0 = _burnAmount0;
  }

  function setBurnAmount1(uint256 _burnAmount1) external override {
    burnAmount1 = _burnAmount1;
  }

  function setCollectAmount0(uint128 _collectAmount0) external override {
    collectAmount0 = _collectAmount0;
  }

  function setCollectAmount1(uint128 _collectAmount1) external override {
    collectAmount1 = _collectAmount1;
  }

  function setPositionLiquidity(uint128 _positionLiquidity) external override {
    positionLiquidity = _positionLiquidity;
  }

  function setPositionFeeGrowthInside0LastX128(uint256 _positionFeeGrowthInside0LastX128) external override {
    positionFeeGrowthInside0LastX128 = _positionFeeGrowthInside0LastX128;
  }

  function setPositionFeeGrowthInside1LastX128(uint256 _positionFeeGrowthInside1LastX128) external override {
    positionFeeGrowthInside1LastX128 = _positionFeeGrowthInside1LastX128;
  }

  function setPositionTokensOwed0(uint128 _positionTokensOwed0) external override {
    positionTokensOwed0 = _positionTokensOwed0;
  }

  function setPositionTokensOwed1(uint128 _positionTokensOwed1) external override {
    positionTokensOwed1 = _positionTokensOwed1;
  }

  function setSlot0SqrtPriceX96(uint160 _slot0SqrtPriceX96) external override {
    slot0SqrtPriceX96 = _slot0SqrtPriceX96;
  }

  function setMintAmount0(uint256 _mintAmount0) external override {
    mintAmount0 = _mintAmount0;
  }

  function setMintAmount1(uint256 _mintAmount1) external override {
    mintAmount1 = _mintAmount1;
  }

  function setDesiredTwap(int56 _desiredTwap) external override {
    desiredTwap = _desiredTwap;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '../peripherals/IGovernable.sol';

interface ITestUniV3Pool {
  // Variables
  function fee() external view returns (uint24 _fee);

  function token0() external view returns (address _token0);

  function token1() external view returns (address _token1);

  function burnAmount0() external view returns (uint256 _burnAmount0);

  function burnAmount1() external view returns (uint256 _burnAmount1);

  function collectAmount0() external view returns (uint128 _collectAmount0);

  function collectAmount1() external view returns (uint128 _collectAmount1);

  function positionLiquidity() external view returns (uint128 _positionLiquidity);

  function positionFeeGrowthInside0LastX128() external view returns (uint256 _positionFeeGrowthInside0LastX128);

  function positionFeeGrowthInside1LastX128() external view returns (uint256 _positionFeeGrowthInside1LastX128);

  function positionTokensOwed0() external view returns (uint128 _positionTokensOwed0);

  function positionTokensOwed1() external view returns (uint128 _positionTokensOwed1);

  function slot0SqrtPriceX96() external view returns (uint160 _slot0SqrtPriceX96);

  function mintAmount0() external view returns (uint256 _mintAmount0);

  function mintAmount1() external view returns (uint256 _mintAmount1);

  function desiredTwap() external view returns (int56 _desiredTwap);

  // Methods

  function burn(
    int24 _tickLower,
    int24 _tickUper,
    uint128 _amount
  ) external returns (uint256 _amount0, uint256 _amount1);

  function collect(
    address _recipient,
    int24 _tickLower,
    int24 _tickUpper,
    uint128 _amount0Requested,
    uint128 _amount1Requested
  ) external returns (uint128 _amount0, uint128 _amount1);

  function positions(bytes32 _data)
    external
    view
    returns (
      uint128 liquidity,
      uint256 feeGrowthInside0LastX128,
      uint256 feeGrowthInside1LastX128,
      uint128 tokensOwed0,
      uint128 tokensOwed1
    );

  function slot0()
    external
    returns (
      uint160 _sqrtPriceX96,
      int24 _tick,
      uint16 _observationIndex,
      uint16 _observationCardinality,
      uint16 _observationCardinalityNext,
      uint8 _feeProtocol,
      bool _unlocked
    );

  function mint(
    address _recipient,
    int24 _tickLower,
    int24 _tickUpper,
    uint128 _amount,
    bytes calldata _data
  ) external returns (uint256 _amount0, uint256 _amount1);

  function observe(uint32[] memory _secondsAgo) external view;

  function setFee(uint24 _fee) external;

  function setToken0(address _token0) external;

  function setToken1(address _token1) external;

  function setBurnAmount0(uint256 _burnAmount0) external;

  function setBurnAmount1(uint256 _burnAmount1) external;

  function setCollectAmount0(uint128 _collectAmount0) external;

  function setCollectAmount1(uint128 _collectAmount1) external;

  function setPositionLiquidity(uint128 _positionLiquidity) external;

  function setPositionFeeGrowthInside0LastX128(uint256 _positionFeeGrowthInside0LastX128) external;

  function setPositionFeeGrowthInside1LastX128(uint256 _positionFeeGrowthInside1LastX128) external;

  function setPositionTokensOwed0(uint128 _positionTokensOwed0) external;

  function setPositionTokensOwed1(uint128 _positionTokensOwed1) external;

  function setSlot0SqrtPriceX96(uint160 _slot0SqrtPriceX96) external;

  function setMintAmount0(uint256 _mintAmount0) external;

  function setMintAmount1(uint256 _mintAmount1) external;

  function setDesiredTwap(int56 _desiredTwap) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

/// @title Governable contract
/// @notice Manages the governance role
interface IGovernable {
  // Events

  /// @notice Emitted when pendingGovernance accepts to be governance
  /// @param _governance Address of the new governance
  event GovernanceSet(address _governance);

  /// @notice Emitted when a new governance is proposed
  /// @param _pendingGovernance Address that is proposed to be the new governance
  event GovernanceProposal(address _pendingGovernance);

  // Errors

  /// @notice Throws if the caller of the function is not governance
  error OnlyGovernance();

  /// @notice Throws if the caller of the function is not pendingGovernance
  error OnlyPendingGovernance();

  /// @notice Throws if trying to set governance to zero address
  error NoGovernanceZeroAddress();

  // Variables

  /// @notice Stores the governance address
  /// @return _governance The governance addresss
  function governance() external view returns (address _governance);

  /// @notice Stores the pendingGovernance address
  /// @return _pendingGovernance The pendingGovernance addresss
  function pendingGovernance() external view returns (address _pendingGovernance);

  // Methods

  /// @notice Proposes a new address to be governance
  /// @param _governance The address being proposed as the new governance
  function setGovernance(address _governance) external;

  /// @notice Changes the governance from the current governance to the previously proposed address
  function acceptGovernance() external;
}