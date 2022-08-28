/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

pragma solidity >=0.4.20;
// pragma solidity 0.8.2;

contract TodoList{
    uint public numUsers = 0;
    
    struct userAddr {
        string street1;
        string street2;
        string county;
        string state; 
        int256 zipcode;
    }

    // struct userImage{
    //     string base64imagetext;
    // }

    // struct loanDetails{
        // loanAmt;
        // loan_roi;
        // loan_tenure;
        // loan_emi;
    // }

    struct signinInfo {
        uint ssn;
        string fname;
        string lname;
        string email_id;
        uint phone_num;
        uint dob;
        string password;
        bool exists;
    }

    mapping(uint => signinInfo) public userData;

    constructor() public {
        createUser(99999, "dummy", "dummy", "[email protected]", 9999999999, 999999, "dummy");
    }

    function userExists(uint _ssn) public view returns (bool){
        if(userData[_ssn].exists){
            return true;
        }
        else{
            return false;
        }
    }

    function createUser(uint _ssn, string memory _fname, string memory _lname, string memory _email_id, uint _phone_num, uint _dob, string memory _password) public {
        require(userData[_ssn].exists == false);
        numUsers++;
        userData[_ssn] = signinInfo(_ssn, _fname, _lname, _email_id, _phone_num, _dob, _password, true);
    }

    function getUser(uint _ssn) public view returns (uint ssn, string memory fname, string memory lname, string memory email_id, uint phone_num, uint dob, string memory pass){
        if (userData[_ssn].exists){
            ssn = userData[_ssn].ssn;
            fname = userData[_ssn].fname;
            lname = userData[_ssn].lname;
            email_id = userData[_ssn].email_id;
            phone_num = userData[_ssn].phone_num;
            dob = userData[_ssn].dob;
            pass = userData[_ssn].password;
        }
        else{
            ssn = userData[99999].ssn;
            fname = userData[99999].fname;
            lname = userData[99999].lname;
            email_id = userData[99999].email_id;
            phone_num = userData[99999].phone_num;
            dob = userData[99999].dob;
            pass = userData[99999].password;
        }
    }

    // function updateUserData(uint _ssn, string memory state, string memory county, string )
}