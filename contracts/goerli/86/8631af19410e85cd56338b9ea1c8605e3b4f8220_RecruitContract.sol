/**
 *Submitted for verification at Etherscan.io on 2022-12-01
*/

// SPDX-License-Identifier:MIT
pragma solidity >=0.8.0;

contract RecruitContract {
    struct Patient {
        address patientAddress;
        uint256 timeStamp;
        string isFiltered;
        AuditSignature auditSignatures;

        string patientName; 
        uint256 patientAge;
        string patientGender;
        string patientNational;
        uint256 patientHeight;
        string patientProfessional;
    }

    struct MedicalHistory {
        address patientAddress;
        string diagnosisOfPathology;
        string dateOfFirstPathology;
        string methodsObtainPathlogyTissue;
        bool isSurgicalTreatment;

        string abnormalSituationDescription;
        string dateOfStart;
        bool isLast;
        string dateOfEnd;
        bool isTreatment;
    }

    struct SurgicalTreatmentHistory {
        address patientAddress;
        string dateOfOperation;
        string indicationsOfSurgery;
        string descriptionOfSurgicalTreatment;
        string dateOfInspection;
        string generalCondition;
        string generalConditionExceptionDescription;
    }

    struct VitalSigns {
        address patientAddress;
        string dateOfInspection;
        uint256 bodyTemperature;
        uint256 pulse;
        uint256 breath;
        uint256 systolicBloodPressure;
        uint256 iastolicBloodPressure;

        string dateOfSampling;
        uint256 RBC;
        uint256 Hb;
        uint256 WBC;
    }

    struct AuditSignature {
        address auditAddress1;
        string auditResult1;
        address auditAddress2;
        string auditResult2;
        address auditAddress3;
        string auditResult3;
    }

    //入排标准
    struct VitalSignsEntryCriteria {
        uint256 minBodyTemperature;
        uint256 maxBodyTemperature;
        uint256 minPulse;
        uint256 maxPulse;
        uint256 minBreath;
        uint256 maxBreath;
        uint256 minSystolicBloodPressure;
        uint256 maxSystolicBloodPressure;
        uint256 minIastolicBloodPressure;
        uint256 maxIastolicBloodPressure;
    }

    struct BloodRoutineEntryCriteria {
        uint256 minRBC;
        uint256 maxRBC;
        uint256 minHb;
        uint256 maxHb;
        uint256 minWBC;
        uint256 maxWBC;
    }

    Patient[] public patients;
    MedicalHistory[] public patientsMedicalHistory;
    SurgicalTreatmentHistory[] public patientsSurgicalTreatmentHistory;
    VitalSigns[] public patientsVitalSigns;

    address public recruitContractCreator;

    string public clinicalTrialNum;
    string public basicInforPubKey;
    string public medicalInforPubKey;

    VitalSignsEntryCriteria public vitalSignsEntryCriteria;
    BloodRoutineEntryCriteria public bloodRoutineEntryCriteria;
    string public withdrawCriteria;
    string public informedConsent;

    string[] public informedConsentSignatures;


    event constructorLog(address recruitContractCreator);

    constructor() {
        recruitContractCreator = msg.sender;
        emit constructorLog(recruitContractCreator);
    }

    function informationSetting(
        string memory _clinicalTrialNum,
        string memory _basicInforPubKey,
        string memory _medicalInforPubKey,
        string memory _withdrawCriteria,
        string memory _informedConsent
    ) external {
        clinicalTrialNum = _clinicalTrialNum;
        basicInforPubKey = _basicInforPubKey;
        medicalInforPubKey = _medicalInforPubKey;
        withdrawCriteria = _withdrawCriteria;
        informedConsent = _informedConsent;
    }

    function vitalSignsEntryCriteriaSetting(
        uint256 _minBodyTemperature,
        uint256 _maxBodyTemperature,
        uint256 _minPulse,
        uint256 _maxPulse,
        uint256 _minBreath,
        uint256 _maxBreath,
        uint256 _minSystolicBloodPressure,
        uint256 _maxSystolicBloodPressure,
        uint256 _minIastolicBloodPressure,
        uint256 _maxIastolicBloodPressure
    ) external {
        VitalSignsEntryCriteria memory singleVitalSignsEntryCriteria;
        singleVitalSignsEntryCriteria.minBodyTemperature = _minBodyTemperature;
        singleVitalSignsEntryCriteria.maxBodyTemperature = _maxBodyTemperature;
        singleVitalSignsEntryCriteria.minPulse = _minPulse;
        singleVitalSignsEntryCriteria.maxPulse = _maxPulse;
        singleVitalSignsEntryCriteria.minBreath = _minBreath;
        singleVitalSignsEntryCriteria.maxBreath = _maxBreath;
        singleVitalSignsEntryCriteria
            .minSystolicBloodPressure = _minSystolicBloodPressure;
        singleVitalSignsEntryCriteria
            .maxSystolicBloodPressure = _maxSystolicBloodPressure;
        singleVitalSignsEntryCriteria
            .minIastolicBloodPressure = _minIastolicBloodPressure;
        singleVitalSignsEntryCriteria
            .maxIastolicBloodPressure = _maxIastolicBloodPressure;

        vitalSignsEntryCriteria = singleVitalSignsEntryCriteria;
    }

    function bloodRoutineEntryCriteriaSetting(
        uint256 _minRBC,
        uint256 _maxRBC,
        uint256 _minHb,
        uint256 _maxHb,
        uint256 _minWBC,
        uint256 _maxWBC
    ) external {
        BloodRoutineEntryCriteria memory singleBloodRoutineEntryCriteria;
        singleBloodRoutineEntryCriteria.minRBC = _minRBC;
        singleBloodRoutineEntryCriteria.maxRBC = _maxRBC;
        singleBloodRoutineEntryCriteria.minHb = _minHb;
        singleBloodRoutineEntryCriteria.maxHb = _maxHb;
        singleBloodRoutineEntryCriteria.minWBC = _minWBC;
        singleBloodRoutineEntryCriteria.maxWBC = _maxWBC;

        bloodRoutineEntryCriteria = singleBloodRoutineEntryCriteria;
    }

    function addPatient(
        string memory _patientName,
        uint256 _patientAge,
        string memory _patientGender,
        string memory _patientNational,
        uint256 _patientHeight,
        string memory _patientProfessional
    ) public {
        Patient memory singlePatient;
        singlePatient.patientAddress = msg.sender;
        singlePatient.timeStamp = block.timestamp;
        singlePatient.isFiltered = "false";
        singlePatient
            .auditSignatures
            .auditAddress1 = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
        singlePatient.auditSignatures.auditResult1 = "false";
        singlePatient
            .auditSignatures
            .auditAddress2 = 0x583031D1113aD414F02576BD6afaBfb302140225;
        singlePatient.auditSignatures.auditResult2 = "false";
        singlePatient
            .auditSignatures
            .auditAddress3 = 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB;
        singlePatient.auditSignatures.auditResult3 = "false";

        singlePatient.patientName = _patientName;
        singlePatient.patientAge = _patientAge;
        singlePatient.patientGender = _patientGender;
        singlePatient.patientNational = _patientNational;
        singlePatient.patientHeight = _patientHeight;
        singlePatient.patientProfessional = _patientProfessional;

        patients.push(singlePatient);
    }

    //添加报名者病史
    function addPatientsMedicalHistory(
        string memory _abnormalSituationDescription,
        string memory _dateOfStart,
        bool _isLast,
        string memory _dateOfEnd,
        bool _isTreatment,
        string memory _diagnosisOfPathology,
        string memory _dateOfFirstPathology,
        string memory _methodsObtainPathlogyTissue,
        bool _isSurgicalTreatment
    ) external {
        MedicalHistory memory singleMedicalHistory;
        singleMedicalHistory.patientAddress = msg.sender;
        singleMedicalHistory.diagnosisOfPathology = _diagnosisOfPathology;
        singleMedicalHistory.dateOfFirstPathology = _dateOfFirstPathology;
        singleMedicalHistory
            .methodsObtainPathlogyTissue = _methodsObtainPathlogyTissue;
        singleMedicalHistory.isSurgicalTreatment = _isSurgicalTreatment;
        singleMedicalHistory
            .abnormalSituationDescription = _abnormalSituationDescription;
        singleMedicalHistory.dateOfStart = _dateOfStart;
        singleMedicalHistory.isLast = _isLast;
        singleMedicalHistory.dateOfEnd = _dateOfEnd;
        singleMedicalHistory.isTreatment = _isTreatment;

        patientsMedicalHistory.push(singleMedicalHistory);
    }

    function addPatientsSurgicalTreatmentHistory(
        string memory _dateOfOperation,
        string memory _indicationsOfSurgery,
        string memory _descriptionOfSurgicalTreatment,
        string memory _dateOfInspection,
        string memory _generalCondition,
        string memory _generalConditionExceptionDescription
    ) external {
        SurgicalTreatmentHistory memory singleSurgicalTreatmentHistory;
        singleSurgicalTreatmentHistory.patientAddress = msg.sender;
        singleSurgicalTreatmentHistory.dateOfOperation = _dateOfOperation;
        singleSurgicalTreatmentHistory
            .indicationsOfSurgery = _indicationsOfSurgery;
        singleSurgicalTreatmentHistory
            .descriptionOfSurgicalTreatment = _descriptionOfSurgicalTreatment;
        singleSurgicalTreatmentHistory.dateOfInspection = _dateOfInspection;
        singleSurgicalTreatmentHistory.generalCondition = _generalCondition;
        singleSurgicalTreatmentHistory
            .generalConditionExceptionDescription = _generalConditionExceptionDescription;

        patientsSurgicalTreatmentHistory.push(singleSurgicalTreatmentHistory);
    }

    function addPatientsVitalSigns(
        string memory _dateOfInspection,
        uint256 _bodyTemperature,
        uint256 _pulse,
        uint256 _breath,
        uint256 _systolicBloodPressure,
        uint256 _iastolicBloodPressure,
        string memory _dateOfSampling,
        uint256 _RBC,
        uint256 _Hb,
        uint256 _WBC
    ) external {
        VitalSigns memory singleVitalSigns;
        singleVitalSigns.patientAddress = msg.sender;
        singleVitalSigns.dateOfInspection = _dateOfInspection;
        singleVitalSigns.bodyTemperature = _bodyTemperature;
        singleVitalSigns.pulse = _pulse;
        singleVitalSigns.breath = _breath;
        singleVitalSigns.systolicBloodPressure = _systolicBloodPressure;
        singleVitalSigns.iastolicBloodPressure = _iastolicBloodPressure;
        singleVitalSigns.dateOfSampling = _dateOfSampling;
        singleVitalSigns.RBC = _RBC;
        singleVitalSigns.Hb = _Hb;
        singleVitalSigns.WBC = _WBC;

        patientsVitalSigns.push(singleVitalSigns);
    }

    function getInformation()
        external
        view
        returns (
            string memory,
            string memory,
            string memory,
            VitalSignsEntryCriteria memory,
            BloodRoutineEntryCriteria memory,
            string memory,
            string memory
        )
    {
        return (
            clinicalTrialNum,
            basicInforPubKey,
            medicalInforPubKey,
            vitalSignsEntryCriteria,
            bloodRoutineEntryCriteria,
            withdrawCriteria,
            informedConsent
        );
    }

    function clearPatient() external {
        if (patients.length == 1) {
            patients.pop();
            patientsVitalSigns.pop();
            patientsMedicalHistory.pop();
            patientsSurgicalTreatmentHistory.pop();
        } else if (patients.length > 1) {
            for (uint256 i = 0; i < patients.length; i++) {
                patients.pop();
                patientsVitalSigns.pop();
                patientsMedicalHistory.pop();
                patientsSurgicalTreatmentHistory.pop();
            }
            patients.pop();
            patientsVitalSigns.pop();
            patientsMedicalHistory.pop();
            patientsSurgicalTreatmentHistory.pop();
        }
    }
    //根据入排标准进行初步筛选
    function filterPatients() external {
        if (patients.length > 1) {
            for (uint256 i = 0; i < patients.length; i++) {
                patients.pop();
                patientsMedicalHistory.pop();
                patientsSurgicalTreatmentHistory.pop();
                patientsVitalSigns.pop();
            }
            patients.pop();
            patientsMedicalHistory.pop();
            patientsSurgicalTreatmentHistory.pop();
            patientsVitalSigns.pop();
        } else if (patients.length == 1) {
            patients.pop();
            patientsMedicalHistory.pop();
            patientsSurgicalTreatmentHistory.pop();
            patientsVitalSigns.pop();
        }

        for (uint256 i = 0; i < patients.length; i++) {
            if (
                vitalSignsEntryCriteria.minBodyTemperature <
                patientsVitalSigns[i].bodyTemperature &&
                patientsVitalSigns[i].bodyTemperature <
                vitalSignsEntryCriteria.maxBodyTemperature &&
                vitalSignsEntryCriteria.minPulse <
                patientsVitalSigns[i].pulse &&
                patientsVitalSigns[i].pulse <
                vitalSignsEntryCriteria.maxPulse &&
                vitalSignsEntryCriteria.minBreath <
                patientsVitalSigns[i].breath &&
                patientsVitalSigns[i].breath <
                vitalSignsEntryCriteria.maxBreath &&
                vitalSignsEntryCriteria.minSystolicBloodPressure <
                patientsVitalSigns[i].systolicBloodPressure &&
                patientsVitalSigns[i].systolicBloodPressure <
                vitalSignsEntryCriteria.maxSystolicBloodPressure &&
                vitalSignsEntryCriteria.minIastolicBloodPressure <
                patientsVitalSigns[i].iastolicBloodPressure &&
                patientsVitalSigns[i].iastolicBloodPressure <
                vitalSignsEntryCriteria.maxIastolicBloodPressure &&
                bloodRoutineEntryCriteria.minRBC <
                patientsVitalSigns[i].RBC &&
                patientsVitalSigns[i].RBC <
                bloodRoutineEntryCriteria.maxRBC &&
                bloodRoutineEntryCriteria.minHb < patientsVitalSigns[i].Hb &&
                patientsVitalSigns[i].Hb < bloodRoutineEntryCriteria.maxHb &&
                bloodRoutineEntryCriteria.minWBC <
                patientsVitalSigns[i].WBC &&
                patientsVitalSigns[i].WBC < bloodRoutineEntryCriteria.maxWBC
            ) {
                patients[i].isFiltered = "true";
            }
        }
    }

    // //获取数据
    // function getPatientsAbnormalSituation()
    //     public
    //     view
    //     returns (
    //         Patient[] memory
    //     )
    // {
    //     return (
    //         patients
    //     );
    // }

    function auditSign(address _patientAddress, string memory _auditResult)
        external
    {
        for (uint256 i = 0; i < patients.length; i++) {
            if (patients[i].patientAddress == _patientAddress) {
                if (patients[i].auditSignatures.auditAddress1 == msg.sender) {
                    patients[i].auditSignatures.auditResult1 = _auditResult;
                } else if (
                    patients[i].auditSignatures.auditAddress2 == msg.sender
                ) {
                    patients[i].auditSignatures.auditResult2 = _auditResult;
                } else if (
                    patients[i].auditSignatures.auditAddress3 == msg.sender
                ) {
                    patients[i].auditSignatures.auditResult3 = _auditResult;
                }
            }
        }
    }
}