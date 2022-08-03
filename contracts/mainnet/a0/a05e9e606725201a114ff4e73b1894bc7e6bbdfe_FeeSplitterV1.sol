/**
 *Submitted for verification at Etherscan.io on 2022-08-02
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract FeeSplitterV1 {
    //Basic Parameters
    address payable public addr1;
    address payable public addr2;
    uint split1;

    modifier OnlyParticipants {
        require ((msg.sender == addr1) || (msg.sender == addr2));
        _;
    }

    constructor(address payable _addr1, uint _split1, address payable _addr2) {
        require(_split1 <= 100);

        addr1 = _addr1;
        addr2 = _addr2;
        split1 = _split1;
    }

    receive() external payable {
        //Accept Ether Deposits, tracked by contract balance
    }

    fallback() external payable {
        //Accept Ether Deposits, tracked by contract balance
    }

    //Withdraw Function
    function Withdraw() public OnlyParticipants {
        uint bal = address(this).balance;
        uint v1 = bal * split1 / 100;
        uint v2 = bal - v1;
        addr1.transfer(v1);
        addr2.transfer(v2);
    }

    //Change Address Functions
    function ChangeAddress1(address payable _addr1) public {
        require (msg.sender == addr1);
        addr1 = _addr1;
    }

    function ChangeAddress2(address payable _addr2) public {
        require (msg.sender == addr2);
        addr2 = _addr2;
    }

    //View Functions
    function GetSplitPct1() public view returns (uint) {
        return split1;
    }

    function GetSplitPct2() public view returns (uint) {
        return 100 - split1;
    }

    function GetWithdrawable1() public view returns (uint) {
        return address(this).balance * split1 / 100;
    }

    function GetWithdrawable2() public view returns (uint) {
        return address(this).balance - GetWithdrawable1();
    }
}