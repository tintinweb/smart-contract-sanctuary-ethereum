/**
 *Submitted for verification at Etherscan.io on 2022-09-24
*/

// File: ev_flat_flat.sol


// File: ev_flat.sol


// File: contracts/ev.sol

//SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
contract EV{
    bool condition;
    address Owner;

     // traking history of users
    struct EVInfo{
        uint RegistrationNo;
        string EvName;
    }
    mapping(address=>EVInfo) public  Info;
    function StoreData(uint _registrationNo, string memory _Evname) public{
        Info[msg.sender]=  EVInfo(_registrationNo,_Evname);
    }
    struct data {
        uint256 energyAmount;
        uint256 from_time;
        uint256 to_time;
        uint256 price;
    }
    event Submit(address indexed from, uint energyAmaount);
    
        mapping(address=> data) public history;
        data[] public TotalHistory;

    constructor(){
        Owner=msg.sender;
    }

    function start() public {
        require(!condition);
        data storage temp = history[msg.sender];
        temp.from_time = block.timestamp;
        condition=true;
    }

    function stop() public {
        require(condition,"first start .. charging");
        data storage temp = history[msg.sender];
        temp.to_time = block.timestamp;
    }

    function submit(uint256 _energyAmount) public {
        data storage temp = history[msg.sender];
        uint256 calculation = (temp.to_time - temp.from_time)*_energyAmount *10;
        temp.price = calculation;
        temp.energyAmount=_energyAmount;
        emit Submit(msg.sender,_energyAmount);
        TotalHistory.push(data(_energyAmount,temp.from_time, temp.to_time,calculation));

    }

    function UsersHidstory() public view returns(data[] memory){
        return TotalHistory;
    }

}