// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract REContract {
    address internal owner;
    uint256[] ContractID;
    mapping(uint256 => ContractInfo) Contracts;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    enum Role {
        None,
        BUYER,
        SELLER,
        CONSULT,
        BBANK,
        SBANK
    }

    struct ContractInfo {
        string ContractName;
        string ContractingInfo;
        uint256 PenaltyPymentBase;
        uint256[3] ContractPenalty;
        uint256[6] ContractDelivery;
        uint256[] ContractPayments;
        uint256[] ContractPaymentsDates;
        address[5] ContractAddresses;
        string[5] ContractBody;
        uint256[6] Contract_Sign_Time;
    }

    function NewContract(ContractInfo[] memory _ContractInfo) public onlyOwner {
        for (uint256 i = 0; i < _ContractInfo.length; i++) {
            require(
                _ContractInfo[i].ContractPayments.length ==
                    _ContractInfo[i].ContractPaymentsDates.length,
                "Please check the payments and the dates!"
            );
            ContractInfo storage newCont = Contracts[ContractID.length];
            newCont.ContractName = _ContractInfo[i].ContractName;
            newCont.ContractingInfo = _ContractInfo[i].ContractingInfo;
            newCont.PenaltyPymentBase = _ContractInfo[i].PenaltyPymentBase;
            newCont.ContractPenalty = _ContractInfo[i].ContractPenalty;
            newCont.ContractDelivery = _ContractInfo[i].ContractDelivery;
            newCont.ContractPayments = _ContractInfo[i].ContractPayments;
            newCont.ContractPaymentsDates = _ContractInfo[i]
                .ContractPaymentsDates;
            newCont.ContractAddresses = _ContractInfo[i].ContractAddresses;
            newCont.ContractBody = _ContractInfo[i].ContractBody;
            newCont.Contract_Sign_Time = [block.timestamp, 0, 0, 0, 0, 0];
            ContractID.push(ContractID.length);
        }
    }

    function GetContract(uint256 _ContractID)
        public
        view
        returns (
            string memory _ContractName,
            string memory _ContractingInfo,
            uint256 _PenaltyPymentBase,
            uint256[3] memory _ContractPenalty,
            uint256[6] memory _ContractDelivery,
            uint256[] memory _ContractPayments,
            uint256[] memory _ContractPaymentsDates,
            address[5] memory _ContractAddresses,
            string[5] memory _ContractBody,
            uint256[6] memory _Contract_Sign_Time
        )
    {
        ContractInfo memory ReqContract = Contracts[_ContractID];
        return (
            ReqContract.ContractName,
            ReqContract.ContractingInfo,
            ReqContract.PenaltyPymentBase,
            ReqContract.ContractPenalty,
            ReqContract.ContractDelivery,
            ReqContract.ContractPayments,
            ReqContract.ContractPaymentsDates,
            ReqContract.ContractAddresses,
            ReqContract.ContractBody,
            ReqContract.Contract_Sign_Time
        );
    }

    function TestValues(uint256 _testVal)
        public
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 test = _testVal;
        uint256 r = test % 10;
        uint256 id = test / 10000;
        uint256 s = ((test - (id * 10000)) - r) / 10;
        return (test, id, s, r);
    }
}