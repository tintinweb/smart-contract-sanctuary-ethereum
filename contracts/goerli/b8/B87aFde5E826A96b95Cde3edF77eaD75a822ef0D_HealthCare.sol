// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HealthCare {
    //STRUCTS
    struct MedicalRecord {
        address id;
        address patient_id;
        address doctor_id;
        string file_name;
        string hospital;
        string details;
        uint256 time_added;
    }

    struct Patient {
        address id;
        string name;
        string surname;
        string date_of_birth;
        string email;
        string telephone;
        string zip_code;
        string city;
        string country;
        MedicalRecord[] medical_records;
    }

    struct Doctor {
        address id;
        string name;
        string surname;
        string date_of_birth;
        string email;
        string telephone;
        string zip_code;
        string city;
        string country;
        Patient[] patients;
    }
    // MAPPINGS
    mapping(address => Patient) public patient_mapping;
    mapping(address => Doctor) public doctor_mapping;
    mapping(address => MedicalRecord) public medical_record_mapping;
    // EVENTS
    event doctor_created(address _id, string _name, string _surname);
    event patient_created(address _id, string _name, string _surname);
    event info_doctor_updated(address _id, string _name, string _surname);
    event info_patient_updated(address _id, string _name, string _surname);
    event patient_added_on_list(address _patient_id);
    event patient_removed_from_list(address _patient_id);
    event medical_record_created(address _medical_record_id);
    event medical_record_deleted(address _medical_record_id);
    event medical_record_updated(address _medical_record_id);
    //MODIFIER
    modifier sender_is_doctor() {
        require(doctor_mapping[msg.sender].id == msg.sender);
        _;
    }
    modifier sender_is_patient() {
        require(patient_mapping[msg.sender].id == msg.sender);
        _;
    }
    modifier doctor_exists(address _doctor_id) {
        require(doctor_mapping[_doctor_id].id == _doctor_id);
        _;
    }
    modifier patient_exists(address _patient_id) {
        require(patient_mapping[_patient_id].id == _patient_id);
        _;
    }
    modifier medical_record_exists(address _medical_record_id) {
        require(
            medical_record_mapping[_medical_record_id].id == _medical_record_id
        );
        _;
    }

    // FUNCTIONS
    function create_doctor(
        string memory _name,
        string memory _surname,
        string memory _date_of_birth,
        string memory _email,
        string memory _telephone,
        string memory _zip_code,
        string memory _city,
        string memory _country
    ) public {
        require(
            doctor_mapping[msg.sender].id != msg.sender,
            "This Doctor already exists!"
        );
        require(
            patient_mapping[msg.sender].id != msg.sender,
            "You are, already, a patient"
        );
        doctor_mapping[msg.sender].id = msg.sender;
        doctor_mapping[msg.sender].name = _name;
        doctor_mapping[msg.sender].surname = _surname;
        doctor_mapping[msg.sender].date_of_birth = _date_of_birth;
        doctor_mapping[msg.sender].email = _email;
        doctor_mapping[msg.sender].telephone = _telephone;
        doctor_mapping[msg.sender].zip_code = _zip_code;
        doctor_mapping[msg.sender].city = _city;
        doctor_mapping[msg.sender].country = _country;

        emit doctor_created(msg.sender, _name, _surname);
    }

    function create_patient(
        string memory _name,
        string memory _surname,
        string memory _date_of_birth,
        string memory _email,
        string memory _telephone,
        string memory _zip_code,
        string memory _city,
        string memory _country
    ) public {
        require(
            patient_mapping[msg.sender].id != msg.sender,
            "This patient already exists!"
        );
        require(
            doctor_mapping[msg.sender].id != msg.sender,
            "You are, already, a Doctor"
        );
        patient_mapping[msg.sender].id = msg.sender;
        patient_mapping[msg.sender].name = _name;
        patient_mapping[msg.sender].surname = _surname;
        patient_mapping[msg.sender].date_of_birth = _date_of_birth;
        patient_mapping[msg.sender].email = _email;
        patient_mapping[msg.sender].zip_code = _telephone;
        patient_mapping[msg.sender].city = _zip_code;
        patient_mapping[msg.sender].city = _city;
        patient_mapping[msg.sender].country = _country;
        emit patient_created(msg.sender, _name, _surname);
    }

    function update_info_doctor(
        string memory _name,
        string memory _surname,
        string memory _date_of_birth,
        string memory _email,
        string memory _telephone,
        string memory _zip_code,
        string memory _city,
        string memory _country
    ) public sender_is_doctor doctor_exists(msg.sender) {
        doctor_mapping[msg.sender].name = _name;
        doctor_mapping[msg.sender].surname = _surname;
        doctor_mapping[msg.sender].date_of_birth = _date_of_birth;
        doctor_mapping[msg.sender].email = _email;
        doctor_mapping[msg.sender].telephone = _telephone;
        doctor_mapping[msg.sender].zip_code = _zip_code;
        doctor_mapping[msg.sender].city = _city;
        doctor_mapping[msg.sender].country = _country;

        emit info_doctor_updated(msg.sender, _name, _surname);
    }

    function update_info_patient(
        string memory _name,
        string memory _surname,
        string memory _date_of_birth,
        string memory _email,
        string memory _telephone,
        string memory _zip_code,
        string memory _city,
        string memory _country
    ) public sender_is_patient patient_exists(msg.sender) {
        patient_mapping[msg.sender].name = _name;
        patient_mapping[msg.sender].surname = _surname;
        patient_mapping[msg.sender].date_of_birth = _date_of_birth;
        patient_mapping[msg.sender].email = _email;
        patient_mapping[msg.sender].zip_code = _telephone;
        patient_mapping[msg.sender].city = _zip_code;
        patient_mapping[msg.sender].city = _city;
        patient_mapping[msg.sender].country = _country;

        emit info_patient_updated(msg.sender, _name, _surname);
    }

    function add_patient_on_list(address _patient_id)
        public
        patient_exists(_patient_id)
        sender_is_doctor
    {
        doctor_mapping[msg.sender].patients.push(patient_mapping[_patient_id]);
        emit patient_added_on_list(_patient_id);
    }

    function remove_patient_from_list(address _patient_id)
        public
        patient_exists(_patient_id)
        sender_is_doctor
    {
        for (
            uint256 i = 0;
            i < doctor_mapping[msg.sender].patients.length;
            i++
        ) {
            if (doctor_mapping[msg.sender].patients[i].id == _patient_id) {
                require(
                    doctor_mapping[msg.sender].patients[i].id == _patient_id
                );
                emit patient_removed_from_list(
                    doctor_mapping[msg.sender].patients[i].id
                );
                doctor_mapping[msg.sender].patients[i].id = address(0);
                doctor_mapping[msg.sender].patients[i].name = "";
                doctor_mapping[msg.sender].patients[i].surname = "";
                doctor_mapping[msg.sender].patients[i].date_of_birth = "";
                doctor_mapping[msg.sender].patients[i].email = "";
                doctor_mapping[msg.sender].patients[i].telephone = "";
                doctor_mapping[msg.sender].patients[i].zip_code = "";
                doctor_mapping[msg.sender].patients[i].city = "";
                doctor_mapping[msg.sender].patients[i].country = "";
            }
        }
    }

    function create_medical_record(
        address _patient_id,
        string memory _file_name,
        string memory _hospital,
        string memory _details
    ) public sender_is_doctor patient_exists(_patient_id) {
        address _medical_record_id = address(
            uint160(
                bytes20(
                    keccak256(abi.encodePacked(msg.sender, block.timestamp))
                )
            )
        );
        medical_record_mapping[_medical_record_id].id = _medical_record_id;
        medical_record_mapping[_medical_record_id].patient_id = _patient_id;
        medical_record_mapping[_medical_record_id].doctor_id = msg.sender;
        medical_record_mapping[_medical_record_id].file_name = _file_name;
        medical_record_mapping[_medical_record_id].hospital = _hospital;
        medical_record_mapping[_medical_record_id].details = _details;
        medical_record_mapping[_medical_record_id].time_added = block.timestamp;
        // add the record on Patient struct from mapping
        patient_mapping[_patient_id].medical_records.push(
            medical_record_mapping[_medical_record_id]
        );
        emit medical_record_created(_medical_record_id);
    }

    function delete_medical_record(address _medical_record_id)
        public
        medical_record_exists(_medical_record_id)
    {
        require(
            medical_record_mapping[_medical_record_id].patient_id ==
                msg.sender ||
                medical_record_mapping[_medical_record_id].doctor_id ==
                msg.sender
        );
        emit medical_record_deleted(_medical_record_id);
        medical_record_mapping[_medical_record_id].id = address(0);
        medical_record_mapping[_medical_record_id].patient_id = address(0);
        medical_record_mapping[_medical_record_id].doctor_id = address(0);
        medical_record_mapping[_medical_record_id].file_name = "";
        medical_record_mapping[_medical_record_id].hospital = "";
        medical_record_mapping[_medical_record_id].details = "";
        medical_record_mapping[_medical_record_id].time_added = 0;
    }

    function update_medical_record(
        address _medical_record_id,
        string memory _file_name,
        string memory _hospital,
        string memory _details
    ) public sender_is_doctor {
        medical_record_mapping[_medical_record_id].doctor_id = msg.sender;
        medical_record_mapping[_medical_record_id].file_name = _file_name;
        medical_record_mapping[_medical_record_id].hospital = _hospital;
        medical_record_mapping[_medical_record_id].details = _details;
        medical_record_mapping[_medical_record_id].time_added = block.timestamp;

        emit medical_record_updated(_medical_record_id);
    }

    function get_medical_record(address _medical_record_id)
        public
        view
        medical_record_exists(_medical_record_id)
        returns (MedicalRecord memory)
    {
        if (
            medical_record_mapping[_medical_record_id].patient_id == msg.sender
        ) {
            return medical_record_mapping[_medical_record_id];
        }

        if (doctor_mapping[msg.sender].id == msg.sender) {
            return medical_record_mapping[_medical_record_id];
        }
        revert("Not allowed");
    }

    function get_patient_data(address _patient_id)
        public
        view
        patient_exists(_patient_id)
        returns (Patient memory)
    {
        if (patient_mapping[_patient_id].id == msg.sender) {
            return patient_mapping[_patient_id];
        }
        if (doctor_mapping[msg.sender].id == msg.sender) {
            return patient_mapping[_patient_id];
        }
        revert("Not allowed");
    }

    function get_doctor_data(address _doctor_id)
        public
        view
        doctor_exists(_doctor_id)
        returns (
            string memory,
            string memory,
            string memory,
            string memory
        )
    {
        return (
            doctor_mapping[_doctor_id].name,
            doctor_mapping[_doctor_id].surname,
            doctor_mapping[_doctor_id].email,
            doctor_mapping[_doctor_id].telephone
        );
    }
}