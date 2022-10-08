/**
 *Submitted for verification at Etherscan.io on 2022-10-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Root{
    address public owner;
    mapping(address=>bool) ownerContract;

    constructor(address _owner) {
        owner = _owner;
    }
    struct Campaign{
        address owner;
        uint lowPrice;
        uint startReg;
        uint startCharity;
        uint startApprove;
        uint startDisbur;
        uint total;
        bool isDisbur;
    }
    
    struct Donate{
        address owner;
        uint amount;
    }
     struct Form{
        address owner;
        uint amount;
    }
    Campaign[] campaign;
    mapping(uint=>Donate[]) donate;
    mapping(uint=>Form[]) form;

    // Create campaign
    function createCampaign(address _owner,
        uint _lowPrice,
        uint _startReg,
        uint _startCharity,
        uint _startApprove,
        uint _startDisbur,
        uint _total) external {
        require(ownerContract[msg.sender],"Not Approve");
        Campaign memory camp = Campaign(_owner,_lowPrice,_startReg,_startCharity,_startApprove,_startDisbur,_total,false);
        campaign.push(camp);
    }
    function removeCampaign(address _owner,uint i) external {
        require(ownerContract[msg.sender],"Not Approve");
        require(campaign[i].owner==_owner,"Not Owner");
        delete campaign[i];
    }
    function pushTotal(uint index,uint _total) external {
        require(ownerContract[msg.sender],"Not Approve");
         campaign[index].total = _total;
    }
    function editCampaign(uint index,bool disbur) external {
        require(ownerContract[msg.sender],"Not Approve");
        campaign[index].isDisbur = disbur;
    }
    function addAction(address _address) public{
        require(msg.sender==owner,"Not Owner");
        ownerContract[_address] = true;
    }
    function removeAction(address _address) public{
        require(msg.sender==owner,"Not Owner");
        ownerContract[_address] = true;
    }
    function getAllCampaign() public view returns(Campaign[] memory camp){
        return campaign;
    }
    function getCampaign(uint index) public view returns(Campaign memory camp){
        return campaign[index];
    }
    // Sign up form
    function addForm(address from,uint index,uint amount) public {
        require(ownerContract[msg.sender],"Not Approve");
        Form memory f = Form(from,amount);
        form[index].push(f);
    }
    function editForm(uint iCampaign,uint index,uint _amount) public {
        require(ownerContract[msg.sender],"Not Approve");
        form[iCampaign][index].amount = _amount;
    }
    function getAllFormCampaign() public view returns(uint){
       uint count = 0;
        for (uint i= 0;i<campaign.length;i++){
            count += form[i].length;
        }
        return count;
    }

    function getAllForm(uint index) public view returns(Form[] memory f){
        return form[index];
    }


    function getForm(uint iCampain,uint iForm) public view returns(Form memory f){
        return form[iCampain][iForm];
    }

    function addDonate(address _owner,uint _amount,uint index) public {
        require(ownerContract[msg.sender],"Not Approve");
        Donate memory d = Donate(_owner,_amount);
        donate[index].push(d);
    }
    function getAllDonateCampaign() public view returns(uint){
       uint count = 0;
        for (uint i= 0;i<campaign.length;i++){
            count += donate[i].length;
        }
        return count;
    }
    function getAllDonate(uint index) public view returns(Donate[] memory sup){
        return donate[index];
    }

    function getDonate(uint iCampain,uint iDonate) public view returns(Donate memory d){
        return donate[iCampain][iDonate];
    }
}