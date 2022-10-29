// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

/**
 * @title SLORegistry
 * @dev SLORegistry is a contract for handling creation of service level
 * objectives and querying those service level objectives
 */
contract SLORegistry {
    enum SLOType {
        EqualTo,
        NotEqualTo,
        SmallerThan,
        SmallerOrEqualTo,
        GreaterThan,
        GreaterOrEqualTo
    }

    struct SLO {
        // half storage slot
        uint120 sloValue;
        SLOType sloType;
    }

    /// @dev SLO Registered event
    event SLORegistered(address indexed sla, uint256 sloValue, SLOType sloType);

    /// @notice maximum cap of deviation percent = 25%, base 10000
    uint16 private constant deviationCapRate = 2500;
    /// @notice address of SLARegistry contract
    address private slaRegistry;
    /// @dev sla address => SLO mapping
    mapping(address => SLO) public registeredSLO;

    /// @dev Modifier ensuring that certain function can only be called by SLARegistry
    modifier onlySLARegistry() {
        require(
            msg.sender == slaRegistry,
            'Should only be called using the SLARegistry contract'
        );
        _;
    }

    /**
     * @notice function to set SLARegistry address
     * @dev this function can be called only once
     */
    function setSLARegistry() public {
        // Only able to trigger this function once
        require(
            address(slaRegistry) == address(0),
            'SLARegistry address has already been set'
        );
        slaRegistry = msg.sender;
    }

    /**
     * @notice public function for creating service level objectives
     * @dev only SLARegistry can call this function
     * @param _sloValue 1. -
     * @param _sloType 2. -
     * @param _slaAddress 3. -
     */
    function registerSLO(
        uint120 _sloValue,
        SLOType _sloType,
        address _slaAddress
    ) public onlySLARegistry {
        registeredSLO[_slaAddress] = SLO({
            sloValue: _sloValue,
            sloType: _sloType
        });
        emit SLORegistered(_slaAddress, _sloValue, _sloType);
    }

    /**
     * @dev external view function to check a value against the SLO
     * @param _value The SLI value to check against the SLO
     * @return boolean with the SLO honoured state
     */
    function isRespected(uint256 _value, address _slaAddress)
        external
        view
        returns (bool)
    {
        SLOType sloType = registeredSLO[_slaAddress].sloType;
        uint256 sloValue = registeredSLO[_slaAddress].sloValue;

        if (sloType == SLOType.EqualTo) {
            return _value == sloValue;
        } else if (sloType == SLOType.NotEqualTo) {
            return _value != sloValue;
        } else if (sloType == SLOType.SmallerThan) {
            return _value < sloValue;
        } else if (sloType == SLOType.SmallerOrEqualTo) {
            return _value <= sloValue;
        } else if (sloType == SLOType.GreaterThan) {
            return _value > sloValue;
        } else {
            // sloType == SLOType.GreaterOrEqualTo
            return _value >= sloValue;
        }
    }

    /**
     * @dev external view function to get the percentage difference between SLI and SLO
     * @param _sli The SLI value to check against the SLO
     * @param _slaAddress The SLO value to check against the SLI
     * @return uint256 with the deviation value for the selected sli and sla, base 10000
     */
    function getDeviation(
        uint256 _sli,
        address _slaAddress,
        uint256[] memory severity,
        uint256[] memory penalty
    ) external view returns (uint256) {
        SLOType sloType = registeredSLO[_slaAddress].sloType;
        uint256 sloValue = registeredSLO[_slaAddress].sloValue;

        uint256 deviation = 0;

        for (uint256 i = 0; i < severity.length; i++) {
            if (_sli >= severity[i]) {
                deviation = penalty[i];
            }
        }

        if (deviation == 0) {
            // Ensures a positive deviation for greater / small comparisons
            // The deviation is the percentage difference between SLI and SLO
            //                          | sloValue - sli |
            // formula =>  deviation = -------------------- %
            //                          (sli + sloValue) / 2
            deviation =
                ((_sli >= sloValue ? _sli - sloValue : sloValue - _sli) *
                    20000) /
                (_sli + sloValue);
        }

        // Enforces a deviation capped at 25%
        if (deviation > deviationCapRate) {
            deviation = deviationCapRate;
        }

        if (sloType == SLOType.EqualTo) {
            // Fixed deviation for this comparison, the reward percentage is the cap
            return deviationCapRate;
        } else if (sloType == SLOType.NotEqualTo) {
            // Fixed deviation for this comparison, the reward percentage is the cap
            return deviationCapRate;
        } else if (sloType == SLOType.SmallerThan) {
            return deviation;
        } else if (sloType == SLOType.SmallerOrEqualTo) {
            return deviation;
        } else if (sloType == SLOType.GreaterThan) {
            return deviation;
        } else {
            // sloType == SLOType.GreaterOrEqualTo
            return deviation;
        }
    }
}