/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

pragma solidity 0.8.17;

struct Template {
    address addrezz;
    uint128 version;
    uint256 id;
    string specification;
}


/// @title Base templates manager interface
/// @dev Interface for the base templates manager contract.
/// @author Federico Luzzi - <[email protected]>
interface IBaseTemplatesManager {
    function addTemplate(address _template, string calldata _specification)
        external;

    function removeTemplate(uint256 _id) external;

    function upgradeTemplate(
        uint256 _id,
        address _newTemplate,
        string calldata _newSpecification
    ) external;

    function updateTemplateSpecification(
        uint256 _id,
        string calldata _newSpecification
    ) external;

    function template(uint256 _id) external view returns (Template memory);

    function template(uint256 _id, uint128 _version)
        external
        view
        returns (Template memory);

    function exists(uint256 _id) external view returns (bool);

    function templatesAmount() external view returns (uint256);

    function enumerate(uint256 _fromIndex, uint256 _toIndex)
        external
        view
        returns (Template[] memory);
}


/// @title Oracles manager interface
/// @dev Interface for the oracles manager contract.
/// @author Federico Luzzi - <[email protected]>
interface IOraclesManager1 is IBaseTemplatesManager {
    function predictInstanceAddress(
        address _creator,
        uint256 _id,
        bytes memory _initializationData
    ) external view returns (address);

    function instantiate(
        address _creator,
        uint256 _id,
        bytes memory _initializationData
    ) external payable returns (address);
}


/// @title Types
/// @dev General collection of reusable types.
/// @author Federico Luzzi - <[email protected]>

struct TokenAmount {
    address token;
    uint256 amount;
}

struct InitializeKPITokenParams {
    address creator;
    address oraclesManager;
    address kpiTokensManager;
    address feeReceiver;
    uint256 kpiTokenTemplateId;
    uint128 kpiTokenTemplateVersion;
    string description;
    uint256 expiration;
    bytes kpiTokenData;
    bytes oraclesData;
}

struct InitializeOracleParams {
    address creator;
    address kpiToken;
    uint256 templateId;
    uint128 templateVersion;
    bytes data;
}


/// @title Oracle interface
/// @dev Oracle interface.
/// @author Federico Luzzi - <[email protected]>
interface IOracle {
    function initialize(InitializeOracleParams memory _params) external payable;

    function kpiToken() external returns (address);

    function template() external view returns (Template memory);

    function finalized() external returns (bool);

    function data() external view returns (bytes memory);
}


/// @title Uniswap v2 TWAP oracle template interface.
/// @dev Uniswap v2 TWAP oracle template interface.
/// @author Federico Luzzi - <[email protected]>
interface IUniswapV2TwapOracle is IOracle {
    function needsExecution() external view returns (bool, bytes memory);

    function execute() external;
}


/// @title Gelato ops interface.
/// @dev Gelato ops interface.
/// @author Federico Luzzi - <[email protected]>
interface IGelatoOps {
    function createTask(
        address _executionAddress,
        bytes4 _executionSelector,
        address _resolverAddress,
        bytes calldata _resolverData
    ) external returns (bytes32 task);

    function cancelTask(bytes32 _taskId) external;
}


/// @title Gelato task treasury interface.
/// @dev Gelato task treasury interface.
/// @author Federico Luzzi - <[email protected]>
interface IGelatoTaskTreasury {
    function depositFunds(
        address _receiver,
        address _token,
        uint256 _amount
    ) external payable;

    function withdrawFunds(
        address payable _receiver,
        address _token,
        uint256 _amount
    ) external;
}


/// @title Uniswap v2 fixed point library
/// @dev A library for handling binary fixed point numbers
/// (https://en.wikipedia.org/wiki/Q_(number_format)), taken
/// from Uniswap's code.
/// @author Uniswap Labs
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x)
        internal
        pure
        returns (uq112x112 memory)
    {
        require(x != 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y)
        internal
        pure
        returns (uq144x112 memory)
    {
        uint256 z;
        require(
            y == 0 || (z = uint256(self._x) * y) / y == uint256(self._x),
            "FixedPoint: MULTIPLICATION_OVERFLOW"
        );
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator)
        internal
        pure
        returns (uq112x112 memory)
    {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }
}


/// @title Uniswap v2 pair interface.
/// @dev Uniswap v2 pair interface.
/// @author Federico Luzzi - <[email protected]protonmail.com>
interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);
}


/// @title ERC20 token interface.
/// @dev ERC20 token interface.
/// @author Federico Luzzi - <[email protected]>
interface IERC20 {
    function decimals() external returns (uint256);
}


/// @title KPI tokens manager interface
/// @dev Interface for the KPI tokens manager contract.
/// @author Federico Luzzi - <[email protected]>
interface IKPITokensManager1 is IBaseTemplatesManager {
    function predictInstanceAddress(
        address _creator,
        uint256 _id,
        string memory _description,
        uint256 _expiration,
        bytes memory _initializationData,
        bytes memory _oraclesInitializationData
    ) external view returns (address);

    function instantiate(
        address _creator,
        uint256 _templateId,
        string memory _description,
        uint256 _expiration,
        bytes memory _initializationData,
        bytes memory _oraclesInitializationData
    ) external returns (address, uint128);
}


/// @title KPI token interface
/// @dev KPI token interface.
/// @author Federico Luzzi - <[email protected]>
interface IKPIToken {
    function initialize(InitializeKPITokenParams memory _params)
        external
        payable;

    function finalize(uint256 _result) external;

    function redeem(bytes memory _data) external;

    function owner() external view returns (address);

    function transferOwnership(address _newOwner) external;

    function template() external view returns (Template memory);

    function description() external view returns (string memory);

    function finalized() external view returns (bool);

    function expiration() external view returns (uint256);

    function data() external view returns (bytes memory);

    function oracles() external view returns (address[] memory);
}

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Uniswap v2 TWAP oracle template.
/// @dev Uniswap v2 TWAP oracle template.
/// @author Federico Luzzi - <[email protected]>
contract UniswapV2TwapOracle is IUniswapV2TwapOracle {
    using FixedPoint for *;

    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint32 internal firstObservationBlockTimestamp;
    uint32 internal startTime;
    uint32 internal endTime;
    address public kpiToken;
    address internal pair;
    address internal creator;
    bool internal token0;
    bool public finalized;
    address internal oraclesManager;
    uint128 internal templateVersion;
    uint256 internal templateId;
    uint256 internal firstObservationCumulativePrice;
    uint256 internal tokenUnit;
    bytes32 internal gelatoTaskId;

    error ZeroAddress();
    error NotEnoughValue();
    error InvalidStartTime();
    error NotOps();
    error NotNeeded();

    function initialize(InitializeOracleParams memory _params)
        external
        payable
        override
    {
        if (msg.value == 0) revert NotEnoughValue();

        oraclesManager = msg.sender;
        kpiToken = _params.kpiToken;
        templateId = _params.templateId;
        templateVersion = _params.templateVersion;

        (address _pair, bool _token0, uint32 _startTime, uint32 _endTime) = abi
            .decode(_params.data, (address, bool, uint32, uint32));

        if (_startTime < block.timestamp || _startTime > _endTime)
            revert InvalidStartTime();
        if (_pair == address(0)) revert ZeroAddress();

        // TODO: check if the pair is legit etc etc

        pair = _pair;
        token0 = _token0;
        startTime = _startTime;
        endTime = _endTime;

        address _token = _token0
            ? IUniswapV2Pair(_pair).token0()
            : IUniswapV2Pair(_pair).token0();
        tokenUnit = 10**IERC20(_token).decimals();

        IGelatoTaskTreasury(_gelatoTaskTreasury()).depositFunds(
            address(this),
            ETH,
            msg.value
        );
        gelatoTaskId = IGelatoOps(_gelatoOps()).createTask(
            address(this),
            this.execute.selector,
            address(this),
            abi.encodeWithSelector(this.needsExecution.selector)
        );
    }

    function _blockTimestamp32Bits() internal view returns (uint32) {
        return uint32(block.timestamp % 2**32);
    }

    function _currentCumulativePrice(uint32 _blockTimestamp)
        internal
        view
        returns (uint256)
    {
        address _pair = pair;
        bool _token0 = token0;

        uint256 _priceCumulative = _token0
            ? IUniswapV2Pair(_pair).price0CumulativeLast()
            : IUniswapV2Pair(_pair).price1CumulativeLast();

        (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        ) = IUniswapV2Pair(_pair).getReserves();
        if (_blockTimestampLast != _blockTimestamp) {
            unchecked {
                uint32 _timeElapsed = _blockTimestamp - _blockTimestampLast;
                _priceCumulative +=
                    uint256(
                        (
                            _token0
                                ? FixedPoint.fraction(_reserve1, _reserve0)
                                : FixedPoint.fraction(_reserve0, _reserve1)
                        )._x
                    ) *
                    _timeElapsed;
            }
        }

        return _priceCumulative;
    }

    function needsExecution() external view returns (bool, bytes memory) {
        return (
            !finalized &&
                ((block.timestamp >= startTime &&
                    firstObservationCumulativePrice == 0) ||
                    (block.timestamp >= endTime)),
            bytes("")
        );
    }

    function execute() external {
        address _gelatoOps = _gelatoOps();
        if (msg.sender != _gelatoOps) revert NotOps();
        if (finalized) revert NotNeeded();
        if (
            block.timestamp >= startTime && firstObservationCumulativePrice == 0
        ) {
            uint32 _blockTimestamp = _blockTimestamp32Bits();
            firstObservationCumulativePrice = _currentCumulativePrice(
                _blockTimestamp
            );
            firstObservationBlockTimestamp = _blockTimestamp;
            return;
        }
        if (block.timestamp > endTime) {
            uint32 _blockTimestamp = _blockTimestamp32Bits();
            uint256 _cumulativePrice = _currentCumulativePrice(_blockTimestamp);
            uint32 _timeElapsed;
            unchecked {
                _timeElapsed = _blockTimestamp - firstObservationBlockTimestamp;
            }
            uint256 _averagePriceInPeriod = FixedPoint
                .uq112x112(
                    uint224(
                        (_cumulativePrice - firstObservationCumulativePrice) /
                            _timeElapsed
                    )
                )
                .mul(tokenUnit)
                .decode144();
            IKPIToken(kpiToken).finalize(_averagePriceInPeriod);
            finalized = true;
            IGelatoOps(_gelatoOps).cancelTask(gelatoTaskId);

            // gas reimboursements
            delete firstObservationBlockTimestamp;
            delete firstObservationCumulativePrice;
            delete tokenUnit;
            delete gelatoTaskId;

            return;
        }
        revert NotNeeded();
    }

    function recoverUnusedFunds() external {
        IGelatoTaskTreasury(_gelatoTaskTreasury()).withdrawFunds(
            payable(IKPIToken(kpiToken).owner()),
            ETH,
            type(uint256).max
        );
    }

    function template() external view override returns (Template memory) {
        return
            IBaseTemplatesManager(oraclesManager).template(
                templateId,
                templateVersion
            );
    }

    function data() external view override returns (bytes memory) {
        return
            abi.encode(
                startTime,
                endTime,
                pair,
                token0,
                gelatoTaskId,
                _gelatoOps(),
                _gelatoTaskTreasury()
            );
    }

    function _gelatoOps() internal pure returns (address) {
        return address(0xc1C6805B857Bef1f412519C4A842522431aFed39);
    }

    function _gelatoTaskTreasury() internal pure returns (address) {
        return address(0xF381dfd7a139caaB83c26140e5595C0b85DDadCd);
    }
}