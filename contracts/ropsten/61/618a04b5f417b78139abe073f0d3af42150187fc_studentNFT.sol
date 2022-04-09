/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

pragma solidity ^0.5.13;

contract studentNFT {
    /*define contract variables*/
    address public hofstra_wallet_address;
    address public student_wallet_address;
    string public student_full_name;
    uint public _700_number;
    string public student_major;

     /*get values*/
    event get_student_name(string student_full_name);


    /*set values*/
    function set_hofstra_wallet(address _public_hofstra_address) public {
        hofstra_wallet_address = _public_hofstra_address;
    }

    function set_student_wallet(address _public_student_address) public {
        student_wallet_address = _public_student_address;
    }

    function set_student_name(string memory _student_name) public {
        student_full_name = _student_name;
        emit get_student_name(student_full_name);
    }

    function set_700_number (uint h_number) public{
        _700_number = h_number;
    }

    function set_student_major (string memory _student_major) public {
        student_major = _student_major;
    }

    function get_student_major() external view returns (string memory){
        return student_major;
    }

}