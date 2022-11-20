pragma solidity ^0.4.24;

contract safeBox {
    mapping(uint256 => myContract) contracts;

    struct myContract {
        uint256 safeBoxId;
        string files;
        string name;
        string Date;
        address owner;
        address[] Approver;
        string status;
    }

    function addSafeBox(
        uint256 safeBoxId,
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

    function getSafeBox(uint256 safeBoxId)
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
        uint256 safeBoxId,
        string _status
    ) public {
        contracts[safeBoxId].status = _status;
    }
}