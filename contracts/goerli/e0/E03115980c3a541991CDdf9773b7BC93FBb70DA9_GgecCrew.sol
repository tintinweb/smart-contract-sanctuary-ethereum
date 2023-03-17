/**
 *Submitted for verification at Etherscan.io on 2023-03-17
*/

// File: Ggec.sol


pragma solidity 0.8.17;




contract GgecCrew{
    struct Data{
        string name;
        uint Id;
        uint age;        string gender;
        bool status;
    }
    mapping (address => Data) public data;
    Data[] public lists;
    address[] _studentState;

    address Admin;
    uint ID;



    constructor(){
        Admin = msg.sender;

    }

    modifier onlyOwner(){
        require(msg.sender == Admin, "Not Admin");
        _;

    }


    function registerStudent(string calldata _name, address student, uint8 _age, string calldata _gender) public{
        ID++;
        Data storage _data = data[student];
        require(_data.status == false, "Student already exist");
        _data.name = _name;
        _data.age = _age;
        _data.gender = _gender;
        _data.Id = ID;
        _data.status = true;
        _studentState.push(student);

       


    }


    function getStudent(address student) public view returns(Data memory _data){
        _data = data[student];
    }

    



    function studentsDetails() external view returns(Data[] memory list){
        uint size = _studentState.length;
        address[] memory  studentMemory = new address[](size);
        list = new Data[](size);
        studentMemory = _studentState;
        for(uint i =0; i < size; i++){
            Data storage _data = data[studentMemory[i]];
            list[i] = _data;
            list[i] =  data[studentMemory[i]]; 
        }

    }


    function DeleteStudent(address student) external onlyOwner{
        Data storage _data = data[student];
        require(_data.status == true, "Not student");
        _data.name = "";
        _data.age = 0;
        _data.Id =  0;
        _data.gender = "";
        _data.status = false;
        uint size = _studentState.length;
        address[] memory  studentMemory = new address[](size);
        studentMemory = _studentState;

        for (uint i = 0; i < size; i++){
            if(student == studentMemory[i]){
                studentMemory[i] = studentMemory[size - 1];
                _studentState = studentMemory;
                break;

            }
        }
        _studentState.pop();

    }


    function changeAdmin(address _newAdmin) external onlyOwner{
        Admin = _newAdmin;


    }




}