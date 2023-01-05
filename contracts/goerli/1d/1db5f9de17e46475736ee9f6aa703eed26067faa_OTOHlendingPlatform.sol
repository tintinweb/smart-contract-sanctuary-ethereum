/**
 *Submitted for verification at Etherscan.io on 2023-01-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;

contract OTOHlendingPlatform {
    address payable treasuryAddress;
    uint256 debtorID;
    string testString;
    uint256 fundBalance;
    bool locked = false;

    constructor() {
        treasuryAddress = payable(msg.sender);
        accounts.ID = 1;
        accounts.accountMapping[0].debtorAddress = address(0);
        accounts.accountMapping[0].amountPaymentContracts = 1;
        accounts.accountMapping[0].status = "no loan setup";
        accounts.accountMapping[0].collateralOwner = address(0);
        accounts.accountMapping[0].collateralURL = "example.json";
        accounts.accountMapping[0].ident = 0;
    }

    function treasuryAddToFund() public payable {
        require(
            msg.sender == treasuryAddress,
            "you are not authorised to add to this fund"
        );
        if (msg.value > 0) {
            fundBalance += msg.value;
        }
    }

    struct Accounts {
        uint256 ID;
        mapping(uint256 => Agreement) accountMapping;
    }
    Accounts accounts;

    mapping(address => uint256) mappingID;

    struct Agreement {
        uint256 ident;
        string status;
        address debtorAddress;
        address investorAddress;
        uint256 amountPaymentContracts;
        uint256 startDate;
        address collateralOwner;
        string collateralURL;
    }

    function addDebtor(
        uint256 _amountPaymentContracts,
        string memory _collateralURL
    ) public {
        uint256 accountID = mappingID[msg.sender];
        require(_amountPaymentContracts > 0, "set to at least 1 loan");
        require(
            keccak256(abi.encodePacked(_collateralURL)) !=
                keccak256(abi.encodePacked("")),
            "collateral description needs content"
        );
        if (mappingID[msg.sender] != 0) {
            require(
                accounts.accountMapping[accountID].debtorAddress != msg.sender,
                "you already have registered with us and have not completed your loan"
            );
        }
        accounts.accountMapping[accounts.ID].debtorAddress = msg.sender;
        accounts
            .accountMapping[accounts.ID]
            .amountPaymentContracts = _amountPaymentContracts;
        accounts.accountMapping[accounts.ID].status = "available";
        accounts.accountMapping[accounts.ID].collateralOwner = msg.sender;
        accounts.accountMapping[accounts.ID].collateralURL = _collateralURL;
        accounts.accountMapping[accounts.ID].ident = accounts.ID;
        mappingID[msg.sender] = accounts.ID;
        accounts.ID++;
    }

    function calculateIdArraySize() private view returns (uint256) {
        uint256 counter;
        for (uint256 i = 0; i < accounts.ID; i++) {
            counter++;
        }
        return (counter);
    }

    function returnAvailableLoans()
        public
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            string[] memory,
            string[] memory
        )
    {
        uint256 counterResult = calculateIdArraySize();
        uint256[] memory IDArray = new uint256[](counterResult);
        uint256[] memory contractAmountArray = new uint256[](counterResult);
        string[] memory collateralURLArray = new string[](counterResult);
        string[] memory statusArray = new string[](counterResult);
        for (uint256 i = 0; i < accounts.ID; i++) {
            IDArray[i] = accounts.accountMapping[i].ident;
            contractAmountArray[i] = accounts
                .accountMapping[i]
                .amountPaymentContracts;
            collateralURLArray[i] = accounts.accountMapping[i].collateralURL;
            statusArray[i] = accounts.accountMapping[i].status;
        }
        return (IDArray, contractAmountArray, collateralURLArray, statusArray);
    }

    function purchase(uint256 _id) public payable {
        require(
            keccak256(abi.encodePacked(accounts.accountMapping[_id].status)) ==
                keccak256(abi.encodePacked("available")),
            "incorrect status"
        );
        require(
            msg.value ==
                (1 ether * accounts.accountMapping[_id].amountPaymentContracts),
            "incorrect payment amount"
        );
        require(
            msg.sender != accounts.accountMapping[_id].debtorAddress,
            "you can not purchase your own debt"
        );
        require(
            mappingID[msg.sender] == 0,
            "multiple purchases to the same address are not currently supported"
        );
        fundBalance += msg.value;
        accounts.accountMapping[_id].investorAddress = msg.sender;
        accounts.accountMapping[_id].status = "live";
        accounts.accountMapping[_id].startDate = block.timestamp;
        mappingID[msg.sender] = accounts.accountMapping[_id].ident;
        payDebtor(_id, msg.value);
    }

    function payDebtor(uint256 _id, uint256 _value) internal {
        fundBalance -= _value;
        payable(accounts.accountMapping[_id].debtorAddress).transfer(_value);
    }

    function accountReset(address _resetAddress) internal {
        mappingID[_resetAddress] = 0;
    }

    function claimYield() public {
        uint256 accountID = mappingID[msg.sender];
        require(
            msg.sender == accounts.accountMapping[accountID].investorAddress,
            "you do not own this account"
        );
        require(
            (fundBalance -
                (1.1 ether *
                    accounts
                        .accountMapping[accountID]
                        .amountPaymentContracts)) > 0,
            "can not claim yield at this time, please contact support"
        );
        require(
            block.timestamp >
                (accounts.accountMapping[accountID].startDate + 300 seconds),
            "below time threshold. check back in after the time is completed"
        );
        fundBalance -= (1.1 ether *
            accounts.accountMapping[accountID].amountPaymentContracts);
        fundBalance -= (0.02 ether *
            accounts.accountMapping[accountID].amountPaymentContracts);
        payable(accounts.accountMapping[accountID].investorAddress).transfer(
            (1.1 ether *
                accounts.accountMapping[accountID].amountPaymentContracts)
        );
        treasuryAddress.transfer(
            (0.02 ether *
                accounts.accountMapping[accountID].amountPaymentContracts)
        );
        accounts.accountMapping[accountID].status = "completed";
        accountReset(msg.sender);
    }

    function checkDebt() public returns (string memory) {
        uint256 accountID = mappingID[msg.sender];
        require(
            msg.sender == accounts.accountMapping[accountID].debtorAddress,
            "this is not your account"
        );
        if (
            block.timestamp >
            (accounts.accountMapping[accountID].startDate + 300 seconds)
        ) {
            accounts.accountMapping[accountID].status = "defaulted";
            accounts
                .accountMapping[accountID]
                .collateralOwner = treasuryAddress;
        }
        return (accounts.accountMapping[accountID].status);
    }

    function paybackDebt() public payable {
        uint256 accountID = mappingID[msg.sender];
        require(accounts.accountMapping[accountID].debtorAddress == msg.sender);
        require(
            msg.value ==
                (1.12 ether *
                    accounts.accountMapping[accountID].amountPaymentContracts),
            "incorrect payment amount"
        );
        fundBalance += msg.value;
        accounts.accountMapping[accountID].status = "repaid";
        accounts.accountMapping[accountID].collateralURL = "removed";
        accountReset(msg.sender);
    }

    function checkPaymentAmount() public view returns (uint256) {
        uint256 accountID = mappingID[msg.sender];
        require(
            msg.sender == accounts.accountMapping[accountID].debtorAddress,
            "this is not your account"
        );
        return (accounts.accountMapping[accountID].amountPaymentContracts *
            1.12 ether);
    }

    function checkLoanStatus()
        public
        view
        returns (
            string memory,
            string memory,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 accountID = mappingID[msg.sender];
        string memory returnCollateralURL = accounts
            .accountMapping[accountID]
            .collateralURL;
        uint256 returnIdent = accounts.accountMapping[accountID].ident;
        uint256 returnStartDate = accounts.accountMapping[accountID].startDate;
        uint256 returnPaymentContracts = accounts
            .accountMapping[accountID]
            .amountPaymentContracts;

        if (
            keccak256(
                abi.encodePacked(accounts.accountMapping[accountID].status)
            ) == keccak256(abi.encodePacked("live"))
        ) {
            if (
                block.timestamp >
                (accounts.accountMapping[accountID].startDate + 300 seconds)
            ) {
                return (
                    "loan is overdue",
                    returnCollateralURL,
                    returnIdent,
                    returnStartDate,
                    returnPaymentContracts
                );
            } else {
                return (
                    accounts.accountMapping[accountID].status,
                    returnCollateralURL,
                    returnIdent,
                    returnStartDate,
                    returnPaymentContracts
                );
            }
        }

        return (
            accounts.accountMapping[accountID].status,
            returnCollateralURL,
            returnIdent,
            returnStartDate,
            returnPaymentContracts
        );
    }

    function rebalanceFund(address payable _withdrawAddress, uint256 _amount)
        public
    {
        require(
            _amount > 0 && _amount <= fundBalance,
            "withdraw amount out of range"
        );
        require(msg.sender == treasuryAddress, "not authorised to withdraw");
        fundBalance -= _amount;
        _withdrawAddress.transfer(_amount);
    }
}