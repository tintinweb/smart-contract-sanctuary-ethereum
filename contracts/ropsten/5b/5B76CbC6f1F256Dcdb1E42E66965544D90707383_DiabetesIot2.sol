/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

//SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.0;

contract DiabetesIot2 {
	string public message;
	
	constructor(string memory initMessage) {
		message = initMessage;
	}
		
	event NewTreatmentSubPlan(uint time, string message);
	
	struct Patient {
		mapping(DrugSubplans => DrugSubplan) hasPart;
		mapping(DiabetesPhysicalExaminations => DiabetesPhysicalExamination) hasPhysicalExamination;
		mapping(PatientDemographics => PatientDemographic) hasDemographic;
		mapping(DiabetesLaboratoryTests => DiabetesLaboratoryTest) hasLabTest;
		bool exists;
	}
	
	enum DiabetesPhysicalExaminations{ 
        BabyDeliveredWeighingMoreThan4pt5Kg, 
        Bmi, 
        DrinkingAlcohol, 
        EyeExam, 
        FamilyHistoryOfGestationalDiabetesMellitus, 
        FamilyHistoryOfHemochromatosis, 
        FamilyHistoryOfType1DiabetesMellitus, 
        FamilyHistoryOfType2DiabetesMellitus, 
        FirstDegreeRelativeWithDiabetes, 
        HighRiskPopulation, 
        HistoryOfGestationalDiabetes, 
        HistoryOfPrediabetes,
        LostFootSensation, 
        OralExam, 
        PersonalHistoryOfHemochromatosis, 
        PhysicallyInactive, 
        Smoking, 
        ThyroidFunction, 
        VitalSign, 
        WaistCircumference}
	
	struct DiabetesPhysicalExamination {
		DiabetesPhysicalExaminations hasType;
		int hasQuantitativeValue;
		bool exists;
	}
	
	enum PatientDemographics{ 
        Residence, 
        BreastFeeding, 
        MaritalStatus, 
        Weight, 
        LevelOfEducation, 
        Height, 
        Gender, 
        ActivityLevel, 
        Age, 
        ObeseClassI, 
        PregnancyState, 
        Job }
	
	struct PatientDemographic {
		PatientDemographics hasType;
		int hasQuantitativeValue;
		bool exists;
	}
	
	enum DrugSubplans{ MonotherapyPlan, DualTherapyPlan }
	
	struct DrugSubplan {
		DiabetesDrug hasDrugParticipant;
		DrugSubplans hasType;
		bool exists;
        string label;
	}
	
	enum DiabetesDrugs{ 
        DopamineAgonist, 
        OtherDrug, 
        CombinedDrug, 
        Insulin, 
        Thiazolidinedione, 
        Sulfonylurea, 
        Incretin, 
        Meglitinide, 
        AlphaGlucosidaseInhibitor, 
        Metformin }
	
	struct DiabetesDrug {
		DiabetesDrugs hasType;
		bool exists;
	}
	
	enum DiabetesLaboratoryTests{ 
        BloodKetone, 
        PlasmaBicarbonate, 
        BloodGlucoseTest, 
        LipidProfile, 
        SerumFetuinA, 
        SerumOsmolality, 
        Autoantibody, 
        SerumAdiponectin, 
        HematologicalProfile, 
        InsulinMeasurement, 
        KidneyFunctionTest, 
        TumorMarker, 
        UrineAnalysis, 
        PlasmaCreatinine, 
        LiverFunctionTest, 
        Hba1c, 
        Fpg }
	
	struct DiabetesLaboratoryTest {
		DiabetesLaboratoryTests hasType;
		int hasQuantitativeValue;
		bool exists;
	}
		
	mapping(address => Patient) patients;
	
	function execute(DiabetesPhysicalExamination memory exam, DiabetesLaboratoryTest memory labtest, DiabetesPhysicalExamination memory history, PatientDemographic memory demographic) public {
		
        Patient storage patient = patients[msg.sender];

        patient.hasPhysicalExamination[exam.hasType].exists = true; 
        patient.hasPhysicalExamination[exam.hasType].hasQuantitativeValue = exam.hasQuantitativeValue;

        patient.hasLabTest[labtest.hasType].exists = true;
        patient.hasLabTest[labtest.hasType].hasQuantitativeValue = labtest.hasQuantitativeValue;

        patient.hasPhysicalExamination[history.hasType].exists = true;
        patient.hasPhysicalExamination[history.hasType].hasQuantitativeValue = history.hasQuantitativeValue;

        patient.hasDemographic[demographic.hasType].exists = true;
        patient.hasDemographic[demographic.hasType].hasQuantitativeValue = demographic.hasQuantitativeValue;

		if (patient.hasPhysicalExamination[DiabetesPhysicalExaminations.Bmi].exists
			&& patient.hasPhysicalExamination[DiabetesPhysicalExaminations.Bmi].hasQuantitativeValue >= 30) {
		
			PatientDemographic memory v2 = PatientDemographic({ hasType: PatientDemographics.ObeseClassI, hasQuantitativeValue: 0, exists: true });
			patient.hasDemographic[v2.hasType] = v2;
		}
		
		if (patient.hasLabTest[DiabetesLaboratoryTests.Hba1c].exists
			&& patient.hasLabTest[DiabetesLaboratoryTests.Hba1c].hasQuantitativeValue >= 6
			&& patient.hasPhysicalExamination[DiabetesPhysicalExaminations.HistoryOfPrediabetes].exists
			&& patient.hasDemographic[PatientDemographics.Age].exists
			&& patient.hasDemographic[PatientDemographics.Age].hasQuantitativeValue >= 25
			&& patient.hasDemographic[PatientDemographics.Age].hasQuantitativeValue <= 59
			&& patient.hasLabTest[DiabetesLaboratoryTests.Fpg].exists
			&& patient.hasLabTest[DiabetesLaboratoryTests.Fpg].hasQuantitativeValue >= 110
			&& patient.hasDemographic[PatientDemographics.ObeseClassI].exists) {
		
            DiabetesDrug memory diabetesDrug = DiabetesDrug({hasType: DiabetesDrugs.Metformin, exists: true });

			DrugSubplan memory v3 = DrugSubplan({ hasDrugParticipant: diabetesDrug, hasType: DrugSubplans.MonotherapyPlan, exists: true, label: "Metformin therapy for prevention of type 2 diabetes should be considered" });
			patient.hasPart[v3.hasType] = v3;
		
			emit NewTreatmentSubPlan(block.timestamp, v3.label);
		}
	}
	
}