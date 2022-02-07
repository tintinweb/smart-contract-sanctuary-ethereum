// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "Ownable.sol";

contract Opers is Ownable {

    // Variables

    uint256 user_id_counter = 1062000;
    uint256 doc_id_counter = 1706200;
    uint256 appointment_id_counter = 15490;

    // Arrays

    // Mappings

    mapping(uint256 => User) public id_to_user;
    mapping(uint256 => string) public user_to_pbk;
    mapping(uint256 => string) public user_to_pvtk;
    mapping(uint256 => Doctor) public id_to_doc;
    mapping(uint256 => string) public doc_to_pbk;
    mapping(uint256 => string) public doc_to_pvtk;
    mapping(uint256 => Appointment) public id_to_appointment;
    mapping(uint256 => uint256[]) public user_all_appointment;
    mapping(uint256 => uint256[]) public doc_all_appointment;
    mapping(uint256 => mapping(uint256 => uint256[])) public user_to_appointment; // user => doc => app
    mapping(uint256 => mapping(uint256 => uint256[])) public doc_to_appointment; // doc => user => app
    mapping(uint256 => string[]) public appointment_to_documents;
    mapping(uint256 => string) public appointment_to_prescription;
    mapping(uint256 => string[]) public appointment_to_reports;
    mapping(uint256 => mapping(uint256 => string[])) public doc_to_sidenotes;

    // Structs

    struct User{
        uint256 user_id;
        address account_address;
        string email;
        uint256 phone_number;
        string name;
        uint256 age;
        string sex;
    }

    struct Doctor{
        uint256 doc_id;
        address doc_account_address;
        string doc_name;
        string doc_desc;
        string doc_speciality;
    }

    struct Appointment{
        uint256 appointment_id;
        uint256 user_id;
        uint256 doc_id;
        string sender_encryption_key;
        string receiver_encryption_key;
        string status;
    }


    // Events

    event Additions(
        string name,
        uint256 alloted_id
    );

    // Payable User Functions

    function addUser(address _account_address, string memory _pbk, string memory pvtk ,string memory _name, string memory _email, uint256 _phone_number, uint256 _age, string memory _sex) public onlyOwner{

        User memory new_user = User(user_id_counter, _account_address, _email, _phone_number, _name, _age, _sex);

        id_to_user[user_id_counter] = new_user;
        user_to_pbk[user_id_counter] = _pbk;
        user_to_pvtk[user_id_counter] = pvtk;

        emit Additions(_name, user_id_counter);

        user_id_counter++;

    }


    function takeAppointment(uint256 _user_id, uint256 _doctor_id, string 
    memory _sender_encryption_key, string 
    memory _receiver_encryption_key, string[] memory _document_links) public{

        require(msg.sender == id_to_user[_user_id].account_address, "User is not authorized");

        Appointment memory new_appointment = Appointment(appointment_id_counter, _user_id, _doctor_id, _sender_encryption_key, _receiver_encryption_key, "Pending");

        id_to_appointment[appointment_id_counter] = new_appointment;
        user_to_appointment[_user_id][_doctor_id].push(appointment_id_counter);
        doc_to_appointment[_user_id][_doctor_id].push(appointment_id_counter);
        user_all_appointment[_user_id].push(appointment_id_counter);
        doc_all_appointment[_doctor_id].push(appointment_id_counter);
        appointment_to_documents[appointment_id_counter] = _document_links;

        appointment_id_counter++;

    }



    // Payable Doctor Functions

    function addDoctor(address _account_address, string memory _pbk, string memory pvtk ,string memory _name, string memory _desc, string memory _speciality) public onlyOwner{
        
        Doctor memory new_doctor = Doctor(doc_id_counter, _account_address, _name, _desc, _speciality);

        id_to_doc[doc_id_counter] = new_doctor;
        doc_to_pbk[doc_id_counter] = _pbk;
        doc_to_pvtk[doc_id_counter] = pvtk;

        emit Additions(_name, doc_id_counter);

        doc_id_counter++;

    }


    function addPrescription(uint256 _doctor_id, uint256 _user_id, uint256 _appointment_id, string memory _prescription, string[] memory _reports) public {

        require(msg.sender == id_to_doc[id_to_appointment[_appointment_id].doc_id].doc_account_address, "User is not authorized");
        
        appointment_to_prescription[_appointment_id] = _prescription;
        appointment_to_reports[_appointment_id] = _reports;

        id_to_appointment[_appointment_id].status = "Completed";
    }


    function docSideNotes(uint256 _doctor_id, uint256 _user_id, string memory _notes) public{
        require(msg.sender == id_to_doc[_doctor_id].doc_account_address, "User is not authorized");
        doc_to_sidenotes[_doctor_id][_user_id].push(_notes);
    }


    // Get functions

    function getUserAllAppointments(uint256 _user_id) public returns(Appointment[] memory) {
        Appointment[] memory all_apts = new Appointment[](user_all_appointment[_user_id].length);
        for (uint256 index = 0; index < user_all_appointment[_user_id].length; index++) {
            all_apts[index] = id_to_appointment[user_all_appointment[_user_id][index]];
        }
        return all_apts;
    }

    function getDocAllAppointments(uint256 _doctor_id) public returns(Appointment[] memory) {
        Appointment[] memory all_apts = new Appointment[](doc_all_appointment[_doctor_id].length);
        for (uint256 index = 0; index < doc_all_appointment[_doctor_id].length; index++) {
            all_apts[index] = id_to_appointment[doc_all_appointment[_doctor_id][index]];
        }
        return all_apts;
    }


    function getUserSpecificAppointment(uint256 _doctor_id, uint256 _user_id) public returns(Appointment[] memory) {
        Appointment[] memory spec_apts = new Appointment[](doc_to_appointment[_doctor_id][_user_id].length);
        for (uint256 index = 0; index < doc_to_appointment[_doctor_id][_user_id].length; index++) {
            spec_apts[index] = id_to_appointment[doc_to_appointment[_doctor_id][_user_id][index]];
        }
        return spec_apts;
    }

    function getDoctorSpecificAppointment(uint256 _doctor_id, uint256 _user_id) public returns(Appointment[] memory) {
        Appointment[] memory spec_apts = new Appointment[](user_to_appointment[_user_id][_doctor_id].length);
        for (uint256 index = 0; index < user_to_appointment[_user_id][_doctor_id].length; index++) {
            spec_apts[index] = id_to_appointment[user_to_appointment[_user_id][_doctor_id][index]];
        }
        return spec_apts;
    }

    function getAppointmentDocs(uint256 _appointment_id) public returns(string[] memory){
        return appointment_to_documents[_appointment_id];
    }

    function getAppointmentReports(uint256 _appointment_id) public returns(string[] memory){
        return appointment_to_reports[_appointment_id];
    }

    function getDocNotes(uint256 _doctor_id, uint256 _user_id) public returns(string[] memory){
        return doc_to_sidenotes[_doctor_id][_user_id];
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}