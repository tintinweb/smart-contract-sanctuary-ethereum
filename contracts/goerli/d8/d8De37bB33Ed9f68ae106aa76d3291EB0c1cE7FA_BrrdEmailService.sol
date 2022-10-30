// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract BrrdEmailService {
    struct Mail {
        address sender;
        address receiver;
        string message;
    }

    event NewEmail(bytes32 mailHash);

    mapping(address => bytes32) private address_to_username;
    mapping(bytes32 => address) private username_to_address;
    mapping(address => Mail[]) private sent;
    mapping(address => Mail[]) private received;

    address payable public owner;

    error userAlreadyExists();
    error addressAlreadyExists();
    error NotEnoughEther();

    constructor() {
        owner = payable(msg.sender);
    }

    modifier validateEmptyUsername(bytes32 _username) {
        require(_username != 0, "EMPTY_USERNAME");
        _;
    }

    modifier validateEmptyAddrr(address _addrr) {
        require(_addrr != address(0), "EMPTY_USERNAME");
        _;
    }

    function withdraw() external {
        require(msg.sender == owner, "OWNER_ONLY");
        owner.transfer(address(this).balance);
    }

    function addressToUsername(address _address)
        public
        view
        validateEmptyAddrr(_address)
        returns (bytes32)
    {
        require(_address != address(0));
        return (address_to_username[_address]);
    }

    function usernameToAddress(bytes32 username) public view returns (address) {
        require(username != 0);
        return (username_to_address[username]);
    }

    function buyUsername(bytes32 username)
        external
        payable
        validateEmptyUsername(username)
    {
        if (msg.value < 1 ether) revert NotEnoughEther();
        if (addressToUsername(msg.sender) != 0) revert addressAlreadyExists();
        if (usernameToAddress(username) != address(0))
            revert userAlreadyExists();
        address_to_username[msg.sender] = username;
        username_to_address[username] = msg.sender;
    }

    function sendEmail(address _address, string calldata _mailData) external {
        require(_address != address(0), "ZERO_ADDRESS");
        Mail memory mail = Mail(msg.sender, _address, _mailData);
        sent[msg.sender].push(mail);
        received[_address].push(mail);
        emit NewEmail(keccak256(bytes(_mailData)));
    }

    function emailsReceived() external view returns (Mail[] memory) {
        return (received[msg.sender]);
    }

    function emailsSent() external view returns (Mail[] memory) {
        return (sent[msg.sender]);
    }
}