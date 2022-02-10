/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

pragma solidity ^0.4.24;

contract custodyn {
    address private owner;
    mapping(address => user) users;
    mapping(string => myContract) contracts;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    struct user {
        address userId;
        string name;
        string lastname;
        string password;
        string email;
        string privateKey;
        bool isExist;
    }
    struct myContract {
        string contractId;
        string Amount;
        address Transfer;
        address Beneficiary;
        string Date;
        address Approver;
        string status;
    }

    function register(
        address userId,
        string memory name,
        string memory lastname,
        string password,
        string email,
        string privatekey
    ) public onlyOwner {
        require(
            users[userId].isExist == false,
            'user details already registered and cannot be altered'
        );
        users[userId] = user(userId, name, lastname, password, email, privatekey, true);
    }

    function getuserDetails(address userId, string password)
        public
        view
        onlyOwner
        returns (
            address,
            string memory,
            string memory,
            string memory,
            string memory
        )
    {
        require(
            keccak256(abi.encodePacked(users[userId].password)) ==
                keccak256(abi.encodePacked(password))
        );
        return (
            users[userId].userId,
            users[userId].name,
            users[userId].lastname,
            users[userId].password,
            users[userId].email
        );
    }

    function getPrivateKey(address userId, string memory email)
        public
        view
        onlyOwner
        returns (string)
    {
        require(users[userId].isExist == true, 'User not found!');
        require(
            keccak256(abi.encodePacked(users[userId].email)) == keccak256(abi.encodePacked(email)),
            'User not found!'
        );
        return users[userId].privateKey;
    }

    function changePassword(
        address userId,
        string memory email,
        string memory oldPassword,
        string memory newPassword
    ) public {
        require(users[userId].isExist == true, 'User not found!');
        require(
            keccak256(abi.encodePacked(users[userId].email)) == keccak256(abi.encodePacked(email)),
            'User not found!'
        );
        require(
            keccak256(abi.encodePacked(users[userId].password)) ==
                keccak256(abi.encodePacked(oldPassword)),
            'Password not correct!'
        );
        users[userId].password = newPassword;
    }

    function resetPassword(
        address userId,
        string email,
        string password
    ) public onlyOwner {
        require(users[userId].isExist == true, 'User not found!');
        require(
            keccak256(abi.encodePacked(users[userId].email)) == keccak256(abi.encodePacked(email)),
            'User not found!'
        );
        users[userId].password = password;
    }

    function addContract(
        string contractId,
        string Amount,
        address Transfer,
        address Beneficiary,
        string Date,
        address Approver,
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
            address,
            string memory
        )
    {
        require(users[_userId].isExist == true, 'User not found!');
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
        address _userId,
        string _contractId,
        string _status
    ) public {
        require(users[_userId].isExist == true, 'User not found!');
        require(
            keccak256(abi.encodePacked(contracts[_contractId].Transfer)) ==
                keccak256(abi.encodePacked(_userId)),
            'User not found!'
        );
        require(
            keccak256(abi.encodePacked(contracts[_contractId].contractId)) ==
                keccak256(abi.encodePacked(_contractId)),
            'User not found!'
        );

        contracts[_contractId].status = _status;
    }
}