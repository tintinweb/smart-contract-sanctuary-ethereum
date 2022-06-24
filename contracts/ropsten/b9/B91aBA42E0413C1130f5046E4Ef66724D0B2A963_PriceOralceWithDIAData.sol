pragma solidity ^0.8.0;

import "./PriceOracle.sol";

// compiled using solidity 0.7.4

contract DIANFTOracle {
    struct Values {
        uint256 value0;
        uint256 value1;
    }
    mapping(string => Values) public values;
    address oracleUpdater;

    event OracleUpdate(
        string key,
        uint64 value0,
        uint64 value1,
        uint64 value2,
        uint64 value3,
        uint64 value4,
        uint64 timestamp
    );
    event UpdaterAddressChange(address newUpdater);

    constructor() {
        oracleUpdater = msg.sender;
    }

    function setValue(
        string memory key,
        uint64 value0,
        uint64 value1,
        uint64 value2,
        uint64 value3,
        uint64 value4,
        uint64 timestamp
    ) public {
        require(msg.sender == oracleUpdater);
        uint256 cValue0 = (((uint256)(value0)) << 192) +
            (((uint256)(value1)) << 128) +
            (((uint256)(value2)) << 64);
        uint256 cValue1 = (((uint256)(value3)) << 192) +
            (((uint256)(value4)) << 128) +
            (((uint256)(timestamp)) << 64);
        Values storage cStruct = values[key];
        cStruct.value0 = cValue0;
        cStruct.value1 = cValue1;
        emit OracleUpdate(
            key,
            value0,
            value1,
            value2,
            value3,
            value4,
            timestamp
        );
    }

    function getValue(string memory key)
        external
        view
        returns (
            uint64,
            uint64,
            uint64,
            uint64,
            uint64,
            uint64
        )
    {
        Values storage cStruct = values[key];
        uint64 rValue0 = (uint64)(cStruct.value0 >> 192);
        uint64 rValue1 = (uint64)((cStruct.value0 >> 128) % 2**64);
        uint64 rValue2 = (uint64)((cStruct.value0 >> 64) % 2**64);
        uint64 rValue3 = (uint64)(cStruct.value1 >> 192);
        uint64 rValue4 = (uint64)((cStruct.value1 >> 128) % 2**64);
        uint64 timestamp = (uint64)((cStruct.value1 >> 64) % 2**64);
        return (rValue0, rValue1, rValue2, rValue3, rValue4, timestamp);
    }

    function updateOracleUpdaterAddress(address newOracleUpdaterAddress)
        public
    {
        require(msg.sender == oracleUpdater);
        oracleUpdater = newOracleUpdaterAddress;
        emit UpdaterAddressChange(newOracleUpdaterAddress);
    }
}

contract PriceOralceWithDIAData is PriceOracle {
    DIANFTOracle DIAPriceOracle =
        DIANFTOracle(0x7626aF7Eb13580193D2c1d6dD12D96bF1E924764);
    mapping(string => address) nameToAddress;

    constructor(
        address zBAYC,
        address zDoodle,
        address zMAYC,
        address zMeebits,
        address zOtherside,
        address zBondETHBAYC,
        address zBondETHMAYC,
        address zBondETHDoodle,
        address zBondETHMeebits,
        address zBondETHOtherside

    ) {
        nameToAddress["zBAYC"] = zBAYC;
        nameToAddress["zDoodle"] = zDoodle;
        nameToAddress["zMAYC"] = zMAYC;
        nameToAddress["zMeebits"] = zMeebits;
        nameToAddress["zOtherside"] = zOtherside;
        nameToAddress["zETHBAYC"] = zBondETHBAYC;
        nameToAddress["zETHMAYC"] = zBondETHMAYC;
        nameToAddress["zETHMeebits"] = zBondETHDoodle;
        nameToAddress["zETHDoodle"] = zBondETHMeebits;
        nameToAddress["zETHOtherside"] = zBondETHOtherside;
    }

    /**
     * @notice Get the underlying price of a asset asset
     * @param asset The asset to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     */

    function getUnderlyingPrice(address asset)
        external
        view
        override
        returns (uint256)
    {
        if (asset == nameToAddress["zBAYC"]) {
            // BAYC
            (uint256 floor, uint256 MA30, , , , ) = DIAPriceOracle.getValue(
                "Ethereum-0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D"
            );
            return MA30 * 1e10;
        } else if (asset == nameToAddress["zDoodle"]) {
            //Doodle
            (uint256 floor, uint256 MA30, , , , ) = DIAPriceOracle.getValue(
                "Ethereum-0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e"
            );
            return MA30 * 1e10;
        } else if (asset == nameToAddress["zMAYC"]) {
            //MAYC
            (uint256 floor, uint256 MA30, , , , ) = DIAPriceOracle.getValue(
                "Ethereum-0x60E4d786628Fea6478F785A6d7e704777c86a7c6"
            );
            return MA30 * 1e10;
        } else if (asset == nameToAddress["zMeebits"]) {
            //MEEbits
            (uint256 floor, uint256 MA30, , , , ) = DIAPriceOracle.getValue(
                "Ethereum-0x7Bd29408f11D2bFC23c34f18275bBf23bB716Bc7"
            );
            return MA30 * 1e10;
        } else if (asset == nameToAddress["zOtherside"]) {
            (uint256 floor, uint256 MA30, , , , ) = DIAPriceOracle.getValue(
                "Ethereum-0x34d85c9CDeB23FA97cb08333b511ac86E1C4E258"
            );
            return MA30 * 1e10;

        } else if (
            asset == nameToAddress["zETHBAYC"] ||
            asset == nameToAddress["zETHMAYC"] ||
            asset == nameToAddress["zETHMeebits"] ||
            asset == nameToAddress["zETHDoodle"] ||
            asset == nameToAddress["zETHOtherside"]
        ) {
            //ETH
            return 1e18;
        } else {
            revert("Price not set for this asset");
        }
    }
}

pragma solidity ^0.8.0;

abstract contract PriceOracle {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    /**
     * @notice Get the underlying price of a cToken asset
     * @param asset The asset to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPrice(address asset)
        external
        view
        virtual
        returns (uint256);
}