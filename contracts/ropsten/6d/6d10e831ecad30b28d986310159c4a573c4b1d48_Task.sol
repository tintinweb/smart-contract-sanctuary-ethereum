/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

pragma solidity ^0.8.0;

contract Task {

    struct person {
        string nickname;
        string start_date;
        string end_date;
        uint kilometers;
    }

    person user;

    address smartTrackerTeam;
    address user_address;

    uint64 days_count;
    uint64 count = 0;
    int target;
    int passed;
    uint public balanceRecived;
    address payable myAddress;
    address payable personal_address;

    //rrk 16.05

    modifier onlySmartTrackerTeam(){
        require(msg.sender==smartTrackerTeam);
        _;
    }

    modifier userOrSmartTrackerTeam(){
        require(msg.sender==user_address||msg.sender==smartTrackerTeam);
        _;
    }


    constructor() public {
        //push here
        //user = person("bob2005","05.05.2022","15.05.2022",5);
    }


    function showPerson() public view returns (person memory) {
        return user;
    }

    function editName(string memory newName) public onlySmartTrackerTeam {
        user.nickname = newName;
    }

    //

    function receiveMoney() public payable {
        balanceRecived += msg.value;
    }

    function addAim(int _target) public {
        target = _target;
    }

    function addPassed(int _passed) public {
        passed = _passed;
    }

    function addDays(uint32 _days_count) public {
        days_count = _days_count;
    }

    function addPersonAddress(address payable _address) public {
        personal_address = _address;
    }

    /* Функция для отправки средств на определенный адрес
        function withdrawMoneyTo(address payable _to) public {
            _to.transfer(getBalance());
        }
    */

    function getBalance() public view returns(uint) {
        return address (this).balance;
    }

    function destroySmartContract(address payable _to) private {
        selfdestruct(_to);
    }

    function checkRes() public {
        if (target <= passed) {
            count += 1;
            target = 0;
            passed = 0;
            if (count == days_count) {
                destroySmartContract(personal_address);
            }
        }

        else {
            destroySmartContract(myAddress);
        }
    }

}