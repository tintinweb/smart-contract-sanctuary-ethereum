/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery {
    address public admin;
    bool isDone =false;
    uint public ticketAmount = 100000; //wei == 0.00001 eth
    uint winNumber;
    mapping(address => uint) public balance;

    struct participantsDetails {
        string name;
        address addr;
        uint ltrNumber;
        uint balance;
    }

    struct ltrExistList {
        address adr;
        bool isValue;
    }

    // constructor(address _address) {
    //     admin = _address;
    // }
    constructor() {
        admin = msg.sender;
    }

    receive()external payable {}
    mapping(address => participantsDetails) private allDetails;
    mapping(uint => ltrExistList) private ltrNumList;

    participantsDetails[] public userList;

    modifier checkAmount() {
        require(
            msg.value >= ticketAmount,
            "invaid amount for buy ticket please add 100000 wei"
        );
        _;
    }

    modifier onlyForUser() {
        require(msg.sender != admin, "only user can use this function");
        _;
    }
    modifier onlyForAdmin() {
        require(msg.sender == admin, "only admin can use this function");
        _;
    }

    modifier userExiest(address _addr) {
        bool res = true;
        if (allDetails[_addr].addr == _addr) {
            res = false;
        }
        require(res == true, "User already exist");
        _;
    }

    modifier lottaryExist(uint _numb) {
        bool res1 = true;
        if (ltrNumList[_numb].isValue) {
            res1 = false;
        }
        require(res1 == true, "lottry number already exist");
        _;
    }
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    function buyNumber(string memory _name, uint _ltrnumber) public payable onlyForUser checkAmount
        userExiest(msg.sender) lottaryExist(_ltrnumber) 
    {
        participantsDetails memory tempObje;
        balance[msg.sender] = msg.value;
        tempObje.addr = msg.sender;
        tempObje.name = _name;
        tempObje.ltrNumber = _ltrnumber;
        tempObje.balance = msg.value;
        userList.push(tempObje);
        allDetails[msg.sender] = tempObje;
        ltrExistList memory ltx;
        ltx.adr = msg.sender;
        ltx.isValue = true;
        ltrNumList[_ltrnumber] = ltx;
    }

    modifier lottaryNoValidate(uint _numb) {
        bool res1 = false;
        if (ltrNumList[_numb].isValue) {
            res1 = true;
        }
        require(res1 == true, "number dose not exist");
        _;
    }
    modifier checkIsDoneLottry(){
        require(isDone == false, "number has been set");
        _;
    }
    

    function setNumber(uint _num) public onlyForAdmin checkIsDoneLottry lottaryNoValidate(_num){        
        winNumber = _num;        
    }

    function getWiningNumber() public view onlyForAdmin returns (uint) {
        return winNumber;
    }

    function getUserDetail(address _addr) public view returns (participantsDetails memory){
        return allDetails[_addr];
    }
    function clameAmount() public onlyForUser payable{
        if(allDetails[msg.sender].ltrNumber == winNumber){
            (bool status,)=(msg.sender).call{value:getBalance()}("");
            isDone=true;
            require(status,"ether status");
        }
    }

    function getUserListCount() public view returns (uint) {
        return userList.length;
    }
}