// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "../interfaces/kashi/IResolver.sol";

contract KashiExchangeRateResolver is IResolver {
    function updateExchangeRateForPairs(IKashiPair[] memory kashiPairs)
        external
    {
        for (uint256 i; i < kashiPairs.length; i++) {
            if (address(kashiPairs[i]) != address(0)) {
                kashiPairs[i].updateExchangeRate();
            }
        }
    }

    function checker(IKashiPair[] memory kashiPairs)
        external
        view
        override
        returns (bool canExec, bytes memory execPayload)
    {
        IKashiPair[] memory pairsToUpdate = new IKashiPair[](kashiPairs.length);

        for (uint256 i; i < kashiPairs.length; i++) {
            IOracle oracle = kashiPairs[i].oracle();
            bytes memory oracleData = kashiPairs[i].oracleData();
            uint256 lastExchangeRate = kashiPairs[i].exchangeRate();
            (bool updated, uint256 rate) = oracle.peek(oracleData);
            if (updated) {
                uint256 deviation = ((
                    lastExchangeRate > rate
                        ? lastExchangeRate - rate
                        : rate - lastExchangeRate
                ) * 100) / lastExchangeRate;
                if (deviation > 20) {
                    pairsToUpdate[i] = kashiPairs[i];
                    canExec = true;
                }
            }
        }

        if (canExec) {
            execPayload = abi.encodeWithSignature(
                "updateExchangeRateForPairs(address[])",
                pairsToUpdate
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./IKashiPair.sol";

interface IResolver {
    function updateExchangeRateForPairs(IKashiPair[] memory kashiPairs)
        external;

    function checker(IKashiPair[] memory kashiPairs)
        external
        view
        returns (bool canExec, bytes memory execPayload);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./IOracle.sol";

interface IKashiPair {
    function oracle() external view returns (IOracle);

    function oracleData() external view returns (bytes memory);

    function updateExchangeRate() external returns (bool updated, uint256 rate);

    function exchangeRate() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IOracle {
    /// @notice Get the latest exchange rate.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(bytes calldata data)
        external
        returns (bool success, uint256 rate);

    /// @notice Check the last exchange rate without any state changes.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(bytes calldata data)
        external
        view
        returns (bool success, uint256 rate);

    /// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(bytes calldata data) external view returns (uint256 rate);

    /// @notice Returns a human readable (short) name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable symbol name about this oracle.
    function symbol(bytes calldata data) external view returns (string memory);

    /// @notice Returns a human readable name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable name about this oracle.
    function name(bytes calldata data) external view returns (string memory);
}