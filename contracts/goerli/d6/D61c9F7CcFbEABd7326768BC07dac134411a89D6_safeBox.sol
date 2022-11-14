pragma solidity ^0.4.24;

contract safeBox {
    mapping(string => myContract) contracts;

    struct myContract {
        string contractId;
        string Amount;
        address Transfer;
        address Beneficiary;
        string Date;
        address[] Approver;
        string status;
    }

    function addContract(
        string contractId,
        string Amount,
        address Transfer,
        address Beneficiary,
        string Date,
        address[] Approver,
        string status
    ) public {
        contracts[contractId] = myContract(
            contractId,
            Amount,
            Transfer,
            Beneficiary,
            Date,
            Approver,
            status
        );
    }

    function getContract(address _userId, string contractId)
        public
        view
        returns (
            string memory,
            string memory,
            address,
            address,
            string memory,
            address[],
            string memory
        )
    {
        require(
            keccak256(abi.encodePacked(contracts[contractId].Transfer)) ==
                keccak256(abi.encodePacked(_userId)),
            'User not found!'
        );
        return (
            contracts[contractId].contractId,
            contracts[contractId].Amount,
            contracts[contractId].Transfer,
            contracts[contractId].Beneficiary,
            contracts[contractId].Date,
            contracts[contractId].Approver,
            contracts[contractId].status
        );
    }

    function changeStatus(
        string _contractId,
        string _status
    ) public {
        contracts[_contractId].status = _status;
    }
}