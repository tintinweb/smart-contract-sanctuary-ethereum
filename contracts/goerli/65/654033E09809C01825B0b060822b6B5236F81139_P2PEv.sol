// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract P2PEv {
	// The type of EV
    string public m_strType = '';

    // The serial of EV
    string public m_strSerial = '';

    // The generating amount of energy per hour
    uint256 public m_nGenerateUnit;

    // The consuming amount of energy per hour
    uint256 public m_nConsumeUnit;

    // The charging amount of energy per hour
    uint256 public m_nChargeUnit;

    // The charging capacity of EV (or battery)
    uint256 public m_nChargeCapacity;

    // The driving range of EV
    uint256 public m_nDrivingRange;

    // The driving state
    bool public m_bDrivingState = false;  // (driving : true, resting: false)
	
    constructor() public {
    }

    // set EV type
    function setType(string memory _type) public {
        m_strType = _type;
    }

    // set EV serial
    function setSerial(string memory serial) public {
        m_strSerial = serial;
    }

    // set Generate Unit
    function setGenerateUnit(uint256 unit) public {
        m_nGenerateUnit = unit;
    }

    // set Consume Unit
    function setConsumeUnit(uint256 unit) public {
        m_nConsumeUnit = unit;
    }

    // set Charge Unit
    function setChargeUnit(uint256 unit) public {
        m_nChargeUnit = unit;
    }

    // set Charge Capacity
    function setChargeCapacity(uint256 capacity) public {
        m_nChargeCapacity = capacity;
    }

    // set Driving Range
    function setDrivingRange(uint256 range) public {
        m_nDrivingRange = range;
    }

    // set Driving State
    function setDrivingState(bool state) public {
        m_bDrivingState = state;
    }
}