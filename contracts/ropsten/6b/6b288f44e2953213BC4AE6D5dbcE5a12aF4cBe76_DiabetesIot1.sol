/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

//SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.0;

contract DiabetesIot1 {
	string public message;
	
	constructor(string memory initMessage) {
		message = initMessage;
	}
	
	event NewTreatmentSubPlan(uint time);
		
	struct Patient {
		mapping(TreatmentSubplans => TreatmentSubplan) hasPart;
		mapping(PatientDemographics => PatientDemographic) hasDemographic;
		DiabetesDiagnosis hasDiagnosis;
		bool exists;
	}
	
	enum PatientDemographics{ Residence, BreastFeeding, MaritalStatus, Weight, LevelOfEducation, Overweight, Height, Gender, ActivityLevel, Age, PregnancyState, Job }
	
	struct PatientDemographic {
		PatientDemographics hasType;
		bool exists;
	}
	
	enum DiabetesPhysicalExaminations{ Bmi, FamilyHistoryOfType1DiabetesMellitus, Smoking, PersonalHistoryOfHemochromatosis, FamilyHistoryOfType2DiabetesMellitus, OralExam, EyeExam, VitalSign, ThyroidFunction, BabyDeliveredWeighingMoreThan4pt5Kg, LostFootSensation, FirstDegreeRelativeWithDiabetes, HistoryOfGestationalDiabetes, HighRiskPopulation, WaistCircumference, FamilyHistoryOfHemochromatosis, PhysicallyInactive, DrinkingAlcohol, FamilyHistoryOfGestationalDiabetesMellitus, HistoryOfPrediabetes }
	
	struct DiabetesPhysicalExamination {
		DiabetesPhysicalExaminations hasType;
		int hasQuantitativeValue;
		bool exists;
	}
	
	enum TreatmentSubplans{ LifestyleSubplan, EducationSubplan, DrugSubplan }
	
	struct TreatmentSubplan {
		string label;
		TreatmentSubplans hasType;
		bool exists;
	}
	
	struct DiabetesDiagnosis {
		DiabetesMellitus hasDiabetesType;
		bool exists;
	}
	
	enum DiabetesMellituses{ DiabetesMellitusDuringPregnancyandChildbirthAndThePuerperium, DiabetesMellitusWithoutComplication, Type2DiabetesMellitus }
	
	struct DiabetesMellitus {
		DiabetesMellituses hasType;
		bool exists;
	}
	
	mapping(address => Patient) patients;
	
	function execute(DiabetesPhysicalExamination memory exam) public {
        
        Patient storage patient = patients[msg.sender];
   

		if (exam.hasType == DiabetesPhysicalExaminations.Bmi
			&& exam.hasQuantitativeValue >= 25) {
		
			PatientDemographic memory v0 = PatientDemographic({ hasType: PatientDemographics.Overweight, exists: true });
            patient.hasDemographic[PatientDemographics.Overweight].exists = true;
			patient.hasDemographic[v0.hasType] = v0;
            patient.hasDiagnosis.exists = true;
            patient.hasDiagnosis.hasDiabetesType.exists = true;
            patient.hasDiagnosis.hasDiabetesType.hasType = DiabetesMellituses.Type2DiabetesMellitus;
		}
		
		if (patient.hasDiagnosis.exists
			&& patient.hasDiagnosis.hasDiabetesType.exists
			&& patient.hasDiagnosis.hasDiabetesType.hasType == DiabetesMellituses.Type2DiabetesMellitus
			&& patient.hasDemographic[PatientDemographics.Overweight].exists) {
		
			TreatmentSubplan memory v1 = TreatmentSubplan({ hasType: TreatmentSubplans.LifestyleSubplan, label: "Management and reduction of weight is important", exists: true });
			patient.hasPart[v1.hasType] = v1;

			emit NewTreatmentSubPlan(block.timestamp);

		}
	}
	
}