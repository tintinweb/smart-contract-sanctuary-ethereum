//SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

/**_ # OWNER # EMPLOYEES # LEVEL # RELATION CODE #ID
ONLY OWNER CAN ADD EMPLOYEE
MANAGER ID
EMPLOYEE CONFIRMATION OF JOINING TEAM REQUIRED
ACCESSIBLE TEAM DESGIN TO EMPLOYEE AND OWNER
_**/

contract teamDesign{
address public owner;
struct EmployeeData {
//employee id
uint256 employeeId;
//manager id
uint256 managerId;
//by owner
address employeeAddress;
//by owner
uint256 level;
//default false
bool joiningStatus;
}

    mapping(address => EmployeeData) private employeeMapData;
    mapping(address => address[]) private employeeMapTask;
    mapping(address => EmployeeData[]) public employeeMapTeam;
    mapping(uint256 => address) private employeeIdMapEmployee;
    //modifier
    modifier onlyOwner(){
        if(msg.sender != owner) revert("Unauthorized to Access !!");
        _;
    }
    modifier onlyTeam(){
        if(!employeeMapData[msg.sender].joiningStatus) revert("Join Team First");
        _;
    }
    modifier onlyEmployee(){
        if(employeeMapData[msg.sender].employeeAddress != msg.sender) revert("Unauthorized to Access !!");
        _;
    }

    //constructor set owner of team design contract
    constructor(){
        owner = msg.sender;
        setEmployeeData(10,0,owner,1);

    }
    //add employee data
    function setEmployeeData(uint256 _employeeId,uint256 _managerId,address _employeeAddress, uint256 _level) public onlyOwner {
        if(_employeeId==10){
            employeeMapData[owner] = EmployeeData(_employeeId,_managerId,_employeeAddress,_level,true);
            employeeIdMapEmployee[10] = msg.sender;
            employeeMapTeam[owner].push(employeeMapData[owner]);

        }else{
            employeeMapData[_employeeAddress] = EmployeeData(_employeeId,_managerId,_employeeAddress,_level,false);
            employeeIdMapEmployee[_employeeId] = _employeeAddress;
            employeeMapTeam[_employeeAddress].push(employeeMapData[_employeeAddress]);
            employeeMapTeam[_employeeAddress].push(employeeMapData[employeeIdMapEmployee[_managerId]]);
            employeeMapTeam[owner].push(employeeMapData[_employeeAddress]);
            teamDesignCreate(_employeeAddress);
        }
    }
    //get employee data
    function getEmployeeData(address _employeeAddress) public  view onlyTeam returns(uint256,uint256,address,uint256,bool){
        EmployeeData memory ed = employeeMapData[_employeeAddress];
        return (ed.employeeId,ed.managerId,ed.employeeAddress,ed.level,ed.joiningStatus);
    }
    //joining confirmation
    function setJoiningStatus(bool _status) public onlyEmployee{
        employeeMapData[msg.sender].joiningStatus = _status;
    }
    //add task
    function setTask(address _employeeAddress,address _taskAddress) public onlyTeam{
        if(employeeMapData[_employeeAddress].managerId == employeeMapData[msg.sender].employeeId){
            employeeMapTask[_employeeAddress].push(_taskAddress);
        }else{
            revert("Unauthorizerd to Assign Task");
        }
    }
    //get task
    function getTask(address _employeeAddress) public view onlyTeam returns( address  [] memory){
        return employeeMapTask[_employeeAddress];
    }
    //get team Design
    function getTeamDesign() public view onlyTeam returns(EmployeeData [] memory){
       return employeeMapTeam[employeeIdMapEmployee[employeeMapData[msg.sender].managerId]];
    }
    //team design
    function teamDesignCreate(address _employeeAddress) private {
        uint256 _managerId = employeeMapData[_employeeAddress].managerId;
        while(_managerId!=0){
            employeeMapTeam[employeeIdMapEmployee[_managerId]].push(employeeMapData[_employeeAddress]);
            _managerId = employeeMapData[employeeIdMapEmployee[_managerId]].managerId;
        }
    }

}