pragma solidity ^0.4.24;

contract safeBox {
    mapping(string => myContract) contracts;

    struct myContract {
        string safeBoxId;
        string files;
        string name;
        string Date;
        address owner;
        address[] Approver;
        string status;
    }

    function addSafeBox(
        string safeBoxId,
        string files,
        string name,
        string Date,
        address owner,
        address[] Approver,
        string status
    ) public {
        contracts[safeBoxId] = myContract(
            safeBoxId,
            files,
            name,
            Date,
            owner,
            Approver,
            status
        );
    }

    function getSafeBox(string safeBoxId)
        public
        view
        returns (
            string memory,
            string memory,
            string memory,
            address,
            address[],
            string memory
        )
    {
        return (
            contracts[safeBoxId].files,
            contracts[safeBoxId].name,
            contracts[safeBoxId].Date,
            contracts[safeBoxId].owner,
            contracts[safeBoxId].Approver,
            contracts[safeBoxId].status
        );
    }

    function updateSafeBox(
        string safeBoxId,
        string _status
    ) public {
        contracts[safeBoxId].status = _status;
    }
}