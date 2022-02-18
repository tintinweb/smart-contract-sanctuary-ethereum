// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./RequestInfo.sol";
import "./Treatment.sol";

contract Main is TreatmentModule, RequestInfo {
    address owner;

    constructor() {
        owner = msg.sender;
    }

    function showDataRequestAfterApproved(uint256 requestId)
        public
        view
        returns (
            Treatment[] memory,
            Medicine[] memory,
            Lab[] memory,
            MedicalProcedure[] memory
        )
    {
        require(requestExist[requestId] == true, "404"); // checked request.
        RequestStuct memory _request = requestAccess[requestId];

        Medicine[] memory _medicineInfo = new Medicine[](
            patientMedicineCount[_request.patientId]
        );
        Lab[] memory _lapsInfo = new Lab[](
            patientlabsCount[_request.patientId]
        );

        require(_request.approved == 1, "403");

        MedicalProcedure[] memory _medicalProcedures = new MedicalProcedure[](
            patientMedicalProcedureCount[_request.patientId]
        );

        Treatment[] memory _treatments = new Treatment[](
            treatmentPatient[_request.patientId].length
        );

        if (_request.history == true && _request.approved == 1) {
            for (
                uint256 i = 0;
                i < treatmentPatient[_request.patientId].length;
                i++
            ) {
                // treatment
                _treatments[i] = treatment[
                    treatmentPatient[_request.patientId][i]
                ];

                // medicines info
                Medicine[] memory _getMedicines = getMedicines(
                    treatmentPatient[_request.patientId][i]
                );

                for (uint256 c = 0; c < _getMedicines.length; c++) {
                    _medicineInfo[c] = _getMedicines[c];
                }
                // end medicine;

                // laps
                Lab[] memory _getLabs = getLabs(
                    treatmentPatient[_request.patientId][i]
                );
                for (uint256 l = 0; l < _getLabs.length; l++) {
                    _lapsInfo[l] = _getLabs[l];
                }

                // medical procedure
                MedicalProcedure[] memory _getMedocal = getMedicalProcedure(
                    treatmentPatient[_request.patientId][i]
                );
                for (uint256 md = 0; md < _getMedocal.length; md++) {
                    _medicalProcedures[md] = _getMedocal[md];
                }
            }
        }

        return (_treatments, _medicineInfo, _lapsInfo, _medicalProcedures);
    }
}