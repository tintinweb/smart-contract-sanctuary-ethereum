// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract P2PHomeowner {
	// The type of Solar
    string public m_strType = '';

    // The serial of Solar
    string public m_strSerial = '';

    // The generating amount of energy per hour
    uint256 public m_nGenerateUnit;

    // The consuming amount of energy per hour
    uint256 public m_nConsumeUnit;

    // The charging amount of energy per hour
    uint256 public m_nChargeUnit;

    // The charging capacity of battery
    uint256 public m_nChargeCapacity;

    // The available energy amount for sale
    uint256 public m_nAvailableAmount;

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

    // runtime calculate available amount
    function calculateAvailableAmount() public {
        
    }
}