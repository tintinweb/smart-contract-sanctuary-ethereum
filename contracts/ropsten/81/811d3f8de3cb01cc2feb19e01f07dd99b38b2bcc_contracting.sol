/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

// SPDX-License-Identifier: MIT License
pragma solidity 0.8.15;
contract contracting{
    address public Owner;
    uint PercentageOfOwner;
    constructor(uint _PercentageOfOwner){
        Owner = msg.sender;
        PercentageOfOwner = _PercentageOfOwner;
    }
    uint ContractId;
    enum Status{
        notstarted,paid,started,finished,suspended,failed
    }
    struct Contract{
    uint StartDayOfProject;
    uint16 LengthOfProject;
    uint CostOfProject;
    uint CostOfLoss;
    address payable Employer;
    address payable Employee;
    address payable judge;
    Status CurrentStatus ;
    uint PercentageOfJudge;
    }
    mapping (uint => Contract) ContractIdentify;
    Contract [] Contracts;
    event SignedContract (uint _ContractId , address indexed _AddressOfEmployer , address indexed _AddressOfEmployee , address indexed _AddressOfJudge , uint _CostOfProject , uint _CostOfLoss , uint _StartDayOfProject ,uint _LenghtOfProject , uint _PercentageOfOwner , uint _PercentageOfJudge );
    function StartContract (address payable _Employer , address payable _Employee , address payable _judge , uint16 _LenghtOfProject , uint _CostOfProject , uint _CostOfLoss , uint _PercentageOfJudge) public returns(string memory , uint YourContractId){
        ContractId ++;
        Contracts.push(Contract({StartDayOfProject:block.timestamp , LengthOfProject:_LenghtOfProject , CostOfProject :_CostOfProject , CostOfLoss : _CostOfLoss , Employer:_Employer , Employee:_Employee , judge:_judge , CurrentStatus : Status.notstarted , PercentageOfJudge : _PercentageOfJudge }));
        ContractIdentify[ContractId]=Contract(block.timestamp,_LenghtOfProject,_CostOfProject,_CostOfLoss,_Employer,_Employee,_judge , Status.notstarted , _PercentageOfJudge);
        emit SignedContract(ContractId,_Employer , _Employee , _judge , _CostOfProject , _CostOfLoss , block.timestamp , _LenghtOfProject , PercentageOfOwner , _PercentageOfJudge );
        return ("Your Contract Signed Successfully!",ContractId);
    }
    function pay(uint _ContractId) public payable returns(string memory){
        require (msg.sender==ContractIdentify[_ContractId].Employer , "You Are Not The Employer Of The Contract!");
        require (msg.value==ContractIdentify[_ContractId].CostOfProject , "The Value Is Not Equal With The Cost Of The Project.");
        require (ContractIdentify[_ContractId].CurrentStatus == Status.notstarted , "The Project Is Paid Or Started , And You Cant Pay Again!" );
        ContractIdentify[_ContractId].CurrentStatus = Status.paid;
        return "Cost Of Project Paid Successfully";
    }
    function start(uint _ContractId) public payable returns(string memory){
        require (msg.sender==ContractIdentify[_ContractId].Employee , "You Are Not The Employee Of The Contract!");
        require (msg.value==ContractIdentify[_ContractId].CostOfLoss , "The Value Is Not Equal With The Cost Of Failing The Project.");
        require (ContractIdentify[_ContractId].CurrentStatus == Status.paid , "The Project Is Not Paid Yet , Please Tell Employer To Pay The Cost Of The Project.");
        ContractIdentify[_ContractId].CurrentStatus = Status.started;
        ContractIdentify[_ContractId].StartDayOfProject = block.timestamp;
        return "Cost Of Project Loss Paid Successfully";
    }
    function ConfirmProject (uint _ContractId , bool confirm) public returns(string memory){
        require (msg.sender==ContractIdentify[_ContractId].Employer , "You Are Not The Employer Of The Contract!");
        require (ContractIdentify[_ContractId].CurrentStatus == Status.started,"The Project Is Not Started Yet , Please Tell Employee To Pay The Cost Of Failing The Project.");    
        if (block.timestamp >= ContractIdentify[_ContractId].StartDayOfProject - (ContractIdentify[_ContractId].LengthOfProject*2) ){
            if (confirm == true){
                ContractIdentify[_ContractId].CurrentStatus = Status.finished;
                payable(Owner).transfer(((ContractIdentify[_ContractId].CostOfProject + ContractIdentify[_ContractId].CostOfLoss)/100)*PercentageOfOwner);
                (ContractIdentify[_ContractId].judge).transfer(((ContractIdentify[_ContractId].CostOfProject + ContractIdentify[_ContractId].CostOfLoss)/100)*(ContractIdentify[_ContractId].PercentageOfJudge));
                (ContractIdentify[_ContractId].Employee).transfer((ContractIdentify[_ContractId].CostOfProject + ContractIdentify[_ContractId].CostOfLoss)-(((ContractIdentify[_ContractId].CostOfProject + ContractIdentify[_ContractId].CostOfLoss)/100)*(PercentageOfOwner+ContractIdentify[_ContractId].PercentageOfJudge)));
                return "Project Status Updated Successfully , Contract Is Finished Now!";
            }
            else{
                ContractIdentify[_ContractId].CurrentStatus = Status.suspended;
                return "Project Status Updated Successfully , Wait For Judgment!";
            }
        }
            else{
                return "DeadLine Is Not Over!";
            }
    }
   function Judgement (uint _ContractId , bool JudgeComment) public returns(string memory){
       if (msg.sender==ContractIdentify[_ContractId].judge && ContractIdentify[_ContractId].CurrentStatus == Status.suspended ){
        if (JudgeComment == true){
                ContractIdentify[_ContractId].CurrentStatus = Status.finished;
                payable(Owner).transfer(((ContractIdentify[_ContractId].CostOfProject + ContractIdentify[_ContractId].CostOfLoss)/100)*PercentageOfOwner);
                (ContractIdentify[_ContractId].judge).transfer(((ContractIdentify[_ContractId].CostOfProject + ContractIdentify[_ContractId].CostOfLoss)/100)*(ContractIdentify[_ContractId].PercentageOfJudge));
                (ContractIdentify[_ContractId].Employee).transfer((ContractIdentify[_ContractId].CostOfProject + ContractIdentify[_ContractId].CostOfLoss)-(((ContractIdentify[_ContractId].CostOfProject + ContractIdentify[_ContractId].CostOfLoss)/100)*(PercentageOfOwner+ContractIdentify[_ContractId].PercentageOfJudge)));
                return "Judged Successfully ! The Employee Is Win .";
            }
        else{
                ContractIdentify[_ContractId].CurrentStatus = Status.finished;
                payable(Owner).transfer(((ContractIdentify[_ContractId].CostOfProject + ContractIdentify[_ContractId].CostOfLoss)/100)*PercentageOfOwner);
                (ContractIdentify[_ContractId].judge).transfer(((ContractIdentify[_ContractId].CostOfProject + ContractIdentify[_ContractId].CostOfLoss)/100)*(ContractIdentify[_ContractId].PercentageOfJudge));
                (ContractIdentify[_ContractId].Employer).transfer((ContractIdentify[_ContractId].CostOfProject + ContractIdentify[_ContractId].CostOfLoss)-(((ContractIdentify[_ContractId].CostOfProject + ContractIdentify[_ContractId].CostOfLoss)/100)*(PercentageOfOwner+ContractIdentify[_ContractId].PercentageOfJudge)));
                return "Judged Successfully ! The Employer Is Win .";
            }
       }
       else{
                return "You Are Not The Judge Or The Contract Not Submitted For Judgement!";
       }
    }
    function getstutus (uint _ContractId) public view returns(Status){
        return ContractIdentify[_ContractId].CurrentStatus;
    }
    function ShowAllContracts () public view returns(Contract [] memory){
        return Contracts;
    }
    function ShowMyContract(uint _ContractId) public view returns(Contract memory){
        return ContractIdentify[_ContractId];
    }
}