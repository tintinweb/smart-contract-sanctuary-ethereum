// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Counters.sol";

contract DClinic {
    using Counters for Counters.Counter;
    Counters.Counter private _patientIds;
    Counters.Counter private _doctorIds;

    event patientCreated(
        uint256 patientId,
        address patientAddress,
        string name,
        string age,
        string dob,
        string gender,
        string p_address
    );

    event doctorCreated(
        uint256 doctorId,
        address doctorAddress,
        string name,
        string age,
        string gender,
        string d_address,
        string specialization,
        string consultanceFee,
        string duration
    );

    event appointmentCreated(
        uint256 patientId,
        uint256 doctorId,
        address patientAddress,
        address doctorAddress,
        string symptoms,
        string pastMedHistory,
        string appointmentDate,
        string appointmentTime
    );

    event prescriptionAdded(
        uint256 patientId,
        uint256 doctorId,
        address doctorAddress,
        address patientAddress,
        string prescriptions
    );

    function createPatient(
        string memory name,
        string memory age,
        string memory dob,
        string memory gender,
        string memory p_address
    ) public {
        uint256 patiendId = _patientIds.current();
        emit patientCreated(patiendId, msg.sender, name, age, dob, gender, p_address);
        _patientIds.increment();
    }

    function createDoctor(
        string memory name,
        string memory age,
        string memory gender,
        string memory d_address,
        string memory specialization,
        string memory consultanceFee,
        string memory duration
    ) public {
        uint256 doctorId = _doctorIds.current();
        emit doctorCreated(
            doctorId,
            msg.sender,
            name,
            age,
            gender,
            d_address,
            specialization,
            consultanceFee,
            duration
        );
        _doctorIds.increment();
    }

    function createAppointment(
        uint256 patientId,
        uint256 doctorId,
        address doctorAddress,
        string memory symptoms,
        string memory pastMedHistory,
        string memory appointmentDate,
        string memory appointmentTime
    ) public {
        emit appointmentCreated(
            patientId,
            doctorId,
            msg.sender,
            doctorAddress,
            symptoms,
            pastMedHistory,
            appointmentDate,
            appointmentTime
        );
    }

    function addPrescription(
        uint256 patientId,
        uint256 doctorId,
        address patientAddress,
        string memory prescriptions
    ) public {
        emit prescriptionAdded(patientId, doctorId, msg.sender, patientAddress, prescriptions);
    }

    function getPatientCount() public view returns (uint256) {
        return _patientIds.current();
    }

    function getDoctorCount() public view returns (uint256) {
        return _doctorIds.current();
    }
}