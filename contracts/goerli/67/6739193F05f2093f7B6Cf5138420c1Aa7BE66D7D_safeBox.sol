pragma solidity ^0.4.24;

contract safeBox {
    mapping(address => myContract) contracts;

    struct myContract {
        string files;
        string name;
        string Date;
        address owner;
        address[] Approver;
        string status;
    }

    function addSafeBox(
        string files,
        string name,
        string Date,
        address owner,
        address[] Approver,
        string status
    ) public {
        contracts[owner] = myContract(
            files,
            name,
            Date,
            owner,
            Approver,
            status
        );
    }

    function getSafeBox(address owner)
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
            contracts[owner].files,
            contracts[owner].name,
            contracts[owner].Date,
            contracts[owner].owner,
            contracts[owner].Approver,
            contracts[owner].status
        );
    }

    function updateSafeBox(
        address owner,
        string _status
    ) public {
        contracts[owner].status = _status;
    }
}