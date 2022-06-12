/**
 *Submitted for verification at Etherscan.io on 2022-06-11
*/

pragma solidity ^0.8.14;
contract Enum{
    // enum Days{
    //     sun,//0
    //     mon,//1
    //     tue,//2
    //     wed,//3
    //     thur,//4
    //     fri,
    //     sat
    // }


    // Days public day = Days.mon;

    enum Status{
        Pending,//0
        Shipped,//1
        Accepted,//2
        Rejected//3
    }


    Status private status;

    function getStatus()view external returns(Status){
        return status;
    }
    function Ship()public{
        status = Status.Shipped;
    }
    function Accepted()public{
        status = Status.Accepted;
    }
    function Rejected()public{
        status = Status.Rejected;
    }


}