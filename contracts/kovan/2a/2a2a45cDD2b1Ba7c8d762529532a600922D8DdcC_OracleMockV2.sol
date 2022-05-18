/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

pragma solidity ^0.8.0;


// SPDX-License-Identifier: MIT
interface IOracle {
    /// @notice Get the latest exchange rate.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(bytes calldata data) external returns (bool success, uint256 rate);

    /// @notice Check the last exchange rate without any state changes.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(bytes calldata data) external view returns (bool success, uint256 rate);

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

// WARNING: This oracle is only for testing, please use PeggedOracle for a fixed value oracle
contract OracleMockV2 is IOracle {
    bool public testMode; // true return the rate ,false return the oracle value
    uint256 public rate;
    bool public success;
    IOracle public oracle;

    constructor() {
        success = true;
    }

    function set(uint256 rate_) public {
        // The rate can be updated.
        rate = rate_;
    }

    function setSuccess(bool val) public {
        success = val;
    }

    function setTestMode(bool val) public {
        testMode = val;
    }

    function getDataParameter() public pure returns (bytes memory) {
        return abi.encode("0x0");
    }

    // Get the latest exchange rate
    function get(bytes calldata data) public override returns (bool, uint256) {
        if (!testMode) {
            return oracle.get(data);
        }
        return (success, rate);
    }

    // Check the last exchange rate without any state changes
    function peek(bytes calldata data)
        public
        view
        override
        returns (bool, uint256)
    {
        if (!testMode) {
            return oracle.peek(data);
        }
        return (success, rate);
    }

    function peekSpot(bytes calldata data)
        public
        view
        override
        returns (uint256)
    {
        if (!testMode) {
            return oracle.peekSpot(data);
        }
        return rate;
    }

    function setOracle(address _oracle) public {
        // The rate can be updated.
        oracle = IOracle(_oracle);
    }

    function name(bytes calldata) public view override returns (string memory) {
        return "Test";
    }

    function symbol(bytes calldata)
        public
        view
        override
        returns (string memory)
    {
        return "TEST";
    }
}