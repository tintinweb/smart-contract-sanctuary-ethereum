/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

//SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.0;

contract DiabetesIot4 {
	string public message;
	
	constructor(string memory initMessage) {
		message = initMessage;
	}
	
	
	event RecommendDiabetesScreening(uint time);
	
	
	struct Patient {
		mapping(Recommendations => Recommendation) recommendTest;
		Ethnicity hasEthnicity;
		PatientProfile hasPatientProfile;
		mapping(DiabetesPhysicalExaminations => DiabetesPhysicalExamination) hasPhysicalExamination;
		mapping(PatientDemographics => PatientDemographic) hasDemographic;
		bool exists;
	}
	
	enum DiabetesPhysicalExaminations{ Bmi, FamilyHistoryOfType1DiabetesMellitus, Smoking, PersonalHistoryOfHemochromatosis, FamilyHistoryOfType2DiabetesMellitus, OralExam, EyeExam, VitalSign, ThyroidFunction, BabyDeliveredWeighingMoreThan4pt5Kg, LostFootSensation, FirstDegreeRelativeWithDiabetes, HistoryOfGestationalDiabetes, HighRiskPopulation, WaistCircumference, FamilyHistoryOfHemochromatosis, PhysicallyInactive, DrinkingAlcohol, FamilyHistoryOfGestationalDiabetesMellitus, HistoryOfPrediabetes }
	
	struct DiabetesPhysicalExamination {
		DiabetesPhysicalExaminations hasType;
		int hasQuantitativeValue;
		bool exists;
	}
	
	enum Ethnicities{ HighRiskEthnicity, PacificIslander, AfricanAmerican, AsianAmerican, Latino, NativeAmerican }
	
	struct Ethnicity {
		Ethnicities hasType;
		bool exists;
	}
	
	enum PatientDemographics{ Residence, BreastFeeding, MaritalStatus, Weight, LevelOfEducation, Overweight, Height, Gender, ActivityLevel, Age, PregnancyState, Job }
	
	struct PatientDemographic {
		PatientDemographics hasType;
		bool exists;
	}
	
	struct PatientProfile {
		Ethnicity hasEthnicity;
		bool exists;
	}
	
	enum Recommendations{ DiabetesScreening }
	
	struct Recommendation {
		Recommendations hasType;
		bool exists;
	}
	
	
	mapping(address => Patient) patients;
	
	function execute() public {
		Patient storage patient = patients[msg.sender];
	
		if (patient.hasPhysicalExamination[DiabetesPhysicalExaminations.Bmi].exists
			&& patient.hasPhysicalExamination[DiabetesPhysicalExaminations.Bmi].hasQuantitativeValue >= 25
			&& patient.hasEthnicity.exists
			&& patient.hasEthnicity.hasType != Ethnicities.AsianAmerican) {
		
			PatientDemographic memory v6 = PatientDemographic({ hasType: PatientDemographics.Overweight, exists: true });
			patient.hasDemographic[v6.hasType] = v6;
		}
		
		if (patient.hasPhysicalExamination[DiabetesPhysicalExaminations.Bmi].exists
			&& patient.hasPhysicalExamination[DiabetesPhysicalExaminations.Bmi].hasQuantitativeValue >= 23
			&& patient.hasEthnicity.hasType == Ethnicities.AsianAmerican) {
		
			PatientDemographic memory v7 = PatientDemographic({ hasType: PatientDemographics.Overweight, exists: true });
			patient.hasDemographic[v7.hasType] = v7;
		}
		
		if (patient.hasPatientProfile.exists
			&& patient.hasPatientProfile.hasEthnicity.exists
			&& (patient.hasPatientProfile.hasEthnicity.hasType == Ethnicities.AfricanAmerican
			|| patient.hasPatientProfile.hasEthnicity.hasType == Ethnicities.Latino
			|| patient.hasPatientProfile.hasEthnicity.hasType == Ethnicities.NativeAmerican
			|| patient.hasPatientProfile.hasEthnicity.hasType == Ethnicities.AsianAmerican
			|| patient.hasPatientProfile.hasEthnicity.hasType == Ethnicities.PacificIslander)) {
		
			patient.hasPatientProfile.hasEthnicity.hasType = Ethnicities.HighRiskEthnicity;
		}
		
		if (patient.hasDemographic[PatientDemographics.Overweight].exists
			&& patient.hasEthnicity.hasType == Ethnicities.HighRiskEthnicity) {
		
			Recommendation memory v8 = Recommendation({ hasType: Recommendations.DiabetesScreening, exists: true });
			patient.recommendTest[v8.hasType] = v8;
		
			emit RecommendDiabetesScreening(block.timestamp);
		}
	}
	
	function update(string memory newMessage) public {
		message = newMessage;
	}}