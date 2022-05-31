/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract SponsorContract{

    address public owner;
    uint total;

    constructor(address _owner) {
        owner = _owner;
        total = 0;
    }
    struct Campain{
        address owner;
        uint lowPrice;
        uint startReg;
        uint startCharity;
        uint startApprove;
        uint startDisbur;
        uint accept;
        uint total;
    }

    struct Charity{
        address owner;
        uint count;
    }

    struct ActiveCampain{
        bool reg;
        bool charity;
        bool approve;
        bool disbur;
    }

    struct Form{
        address owner;
        string pdf;
        uint accept;
    }

    struct AcceptOwner{
        uint charity;
        bool accept;
    }

    struct Censor{
        address owner;
        bool approve;
    }

        struct User{
        uint balance;
        bool isValue;
    }

    Campain[] campain;
    mapping(uint=>ActiveCampain) activeCampain;
    mapping(uint=>Charity[]) charity;
    mapping(uint=>Form[]) form;
    mapping(uint=>mapping(uint=>Censor[])) censor;
    mapping(uint=>mapping(uint=>AcceptOwner[])) acceptOwner;
    mapping(address=>User) user;

    // Event
    event createLaunch(address owner,uint index);
    event startCharity(address owner,uint index);
    event startApprove(address owner,uint index);
    event startDisbur(address owner,uint index);

     // emit createLaunch(msg.sender,campain.length-1);
    function launch(uint _lowPrice,uint _startReg,uint _startCharity,uint _startAprove,uint _startDisbur) public {
        Campain memory camp = Campain(msg.sender,_lowPrice,_startReg,_startCharity,_startAprove,_startDisbur,0,0);
        campain.push(camp);
        activeCampain[campain.length-1] = ActiveCampain(true,false,false,false);
    }

    function transferTo(address to) public payable{
       require(msg.sender==owner,"Not owner");
        payable(to).transfer(msg.value);
    }

    function getAllLaunch() public view returns(Campain[] memory camp){
        return campain;
    }

    function getLaunch(uint index) public view returns(Campain memory camp){
        return campain[index];
    }

    function createUser() public{
        require(!user[msg.sender].isValue,"user is exist");
        user[msg.sender] = User(0,true);
    }
function mintVND(address _to,uint balance) public{
        require(msg.sender==owner,"Not owner");
        require(user[_to].isValue,"Not user");
        user[_to].balance += balance;
    }

    function getBalanceVND(address _to) public view returns(uint balance){
        return user[_to].balance;
    }

    // function getActiveCampain(uint index) public view returns(ActiveCampain memory active){
    //     return activeCampain[index];
    // }

    // function nextLevelCampain(uint index) public {
    //     require(msg.sender == owner,"Not Owner");
    //     if (!activeCampain[index].charity){
    //         require(block.timestamp>=campain[index].startCharity,"Time startCharity bad");
    //         require(campain[index].startDisbur>=block.timestamp," startDisbur bad");
    //         activeCampain[index].charity = true;
    //         emit startCharity(campain[index].owner,campain.length-1,campain[index].name);
    //     } else {
    //         if (!activeCampain[index].approve){
    //             require(block.timestamp>=campain[index].startApprove,"Time startApprove bad");
    //             require(campain[index].startDisbur>=block.timestamp," startDisbur bad");
    //             activeCampain[index].approve = true;
    //             emit startApprove(campain[index].owner,campain.length-1,campain[index].name);
    //         } else{
    //             require(!activeCampain[index].disbur,"not disbur");
    //             require(block.timestamp>=campain[index].startDisbur,"Time disbur bad");
    //            activeCampain[index].disbur = true;
    //             emit startDisbur(campain[index].owner,campain.length-1,campain[index].name);
    //         }
    //     }
    // }

    function registration(uint index,string memory pdf) public {
        require(activeCampain[index].reg,"Time bad");
        for (uint i=0;i<form[index].length;i++){
            if (form[index][i].owner == msg.sender){
                revert("user is exists!");
            }
        }
        Form memory f = Form(msg.sender,pdf,0);
        form[index].push(f);
    }

    function getAllRegistration(uint index) public view returns(Form[] memory f){
        return form[index];
    }

    function getRegistration(uint iCampain,uint iForm) public view returns(Form memory f){
        return form[iCampain][iForm];
    }

    function getBlockTime() public view returns(uint){
        return block.timestamp;
    }

 function support(uint index,uint balance) public  {
        //require(activeCampain[index].charity,"Time Charity Bad");
        require(user[msg.sender].balance>=balance,"Balance not accept");
        bool isExist =false;
        for (uint i = 0;i<charity[index].length;i++){
            if (charity[index][i].owner == msg.sender){
                charity[index][i].count += balance;
                isExist = true;
            }
        }
        if (!isExist){
            Charity memory c = Charity(msg.sender,balance);
            charity[index].push(c);
        }
        total += balance;
        campain[index].total += balance;
        user[msg.sender].balance -= balance;
    }
    function getSupport(uint index) public view returns(Charity[] memory sup){
        return charity[index];
    }

    // function randomCensor(uint iCampain,address[] memory _censor) public{
    //     require(msg.sender==owner,"Not Owner");
    //     require(activeCampain[iCampain].approve,"Time Bad");
    //     if (_censor.length<10){
    //         for (uint i = 0;i<form[iCampain].length;i++){
    //             for (uint k = 0;k<_censor.length;k++){
    //                 censor[iCampain][i][k] = Censor(_censor[k],false);
    //             }
    //         }
    //     } else {
    //         for (uint i = 0;i<form[iCampain].length;i++){
    //             address[] memory arr = _censor;
    //             for (uint k = 0;k<10;k++){
    //                 uint rand = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender))) % arr.length;
    //                 censor[iCampain][i][k] = Censor(_censor[rand],false);
    //                 delete arr[rand];
    //             }
    //         }
    //     }
    // }

    // function getCensor(uint iCampain,uint iForm) public view returns(Censor[] memory cen){
    //     return censor[iCampain][iForm];
    // }

    function disbur(uint index) public{
        require(msg.sender==owner,"Not owner");
        uint totalRelease = campain[index].total / form[index].length;
        for (uint i=0;i<form[index].length;i++){
            user[form[index][i].owner].balance += totalRelease;

            campain[index].total -= totalRelease;
        }
    }

    function withDraw(address _to,uint balance) public{
        require(msg.sender==owner,"Not owner");
        require(balance<=user[_to].balance,"Balance not accept");
        user[_to].balance -= balance;
    }

    // function approveForm(uint iCampain,uint iForm,bool accept) public payable{
    //     uint index;
    //     for (uint i = 0;i<charity[iCampain].length;i++){
    //         if (charity[iCampain][i].owner==msg.sender){
    //             index = i;
    //         } else if (charity[iCampain].length-1==i){
    //             revert("user is not exists!");
    //         }
    //     }
    //     for (uint i = 0;i<acceptOwner[iCampain][iForm].length;i++){
    //         if (acceptOwner[iCampain][iForm][i].charity==index){
    //             revert("user is accept!");
    //         }
    //     }
    //     AcceptOwner memory acc = AcceptOwner(index,accept);
    //     acceptOwner[iCampain][iForm].push(acc);
    // }
}