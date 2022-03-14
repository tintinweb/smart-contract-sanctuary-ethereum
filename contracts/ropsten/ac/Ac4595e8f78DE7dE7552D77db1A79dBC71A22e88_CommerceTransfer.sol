/*
Задача #9
Библиотеки. Подключить к своему контракту библиотеку для работы с адресами: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol.
Разработать логику, которая используют следующиие функции из этой библиотеки: isContract(), sendValue()
*/

pragma solidity ^0.8.12;

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";
import "./Address.sol";
import "./Safemath.sol";

contract CommerceTransfer {
    using SafeMath for uint;
    using Address for address;
    using Address for address payable; 

    event Transfer(address indexed from, uint256 indexed depositTime, uint256 amount);

    address payable private owner;

    receive() external payable {}
    fallback() external {}

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOnwer {
        require(msg.sender == owner, "You are not a contract owner");
        _;
    }

    mapping(address => Organization) public organizations;
    struct Organization {
        string orgName;
        address orgOwner;
        address orgAddress;
        uint orgBalance;
        bool reg;
    }

    function regOrganization(string memory nameOrganization, address addrOrganization) public {

        require(addrOrganization.isContract(), "Address is not a contract"); // создать организацию можно только имея контракт

        require(organizations[msg.sender].reg == false, "You already have an organization");
        organizations[msg.sender].orgOwner = msg.sender;
        organizations[msg.sender].orgAddress = addrOrganization;
        organizations[msg.sender].orgName = nameOrganization;
        organizations[msg.sender].reg = true;
    }

    function depositToOrg() public payable {
        if (organizations[msg.sender].reg == false) {
            revert("Register first");
        }
        organizations[msg.sender].orgBalance = organizations[msg.sender].orgBalance.add(msg.value);
    }

    function transferToOtherOrg(address payable recipient, uint256 amount) public {

        require(recipient.isContract(), "You can only send it to a contract"); // отправить можно только на контракт
        
        require(organizations[msg.sender].orgBalance >= amount, "Not enough funds");

        recipient.sendValue(amount); // используем функцию из библиотеки для отправки средств

        organizations[msg.sender].orgBalance = organizations[msg.sender].orgBalance.sub(amount);
        emit Transfer(organizations[msg.sender].orgAddress, block.timestamp, amount);
    }
}

contract CompanyOne {
    address payable private owner;
    event depositInfo(address sender, uint amount);
    event withdrawInfo(uint time, uint amount);

    receive() external payable {}
    fallback() external {}

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOnwer {
        require(msg.sender == owner, "You are not a contract owner");
        _;
    }

    function deposit() public payable {
        emit depositInfo(msg.sender, msg.value);
    }

    function withdraw(uint amount) external onlyOnwer {
        require(address(this).balance >= amount, "Not enough funds");
        owner.transfer(amount);
        emit withdrawInfo(block.timestamp, amount);
    }

    function customSend(address payable recipient, uint256 amount) public onlyOnwer {
        require(address(this).balance >= amount, "Not enough funds");
        recipient.send(amount);
    }

    function getBalance() public view onlyOnwer returns (uint) {
        return address(this).balance;
    }
}

contract CompanyTwo {
    address payable private owner;
    event depositInfo(address sender, uint amount);
    event withdrawInfo(uint time, uint amount);

    receive() external payable {}
    fallback() external {}

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOnwer {
        require(msg.sender == owner, "You are not a contract owner");
        _;
    }

    function deposit() public payable {
        emit depositInfo(msg.sender, msg.value);
    }

    function withdraw(uint amount) external onlyOnwer {
        require(address(this).balance >= amount, "Not enough funds");
        owner.transfer(amount);
        emit withdrawInfo(block.timestamp, amount);
    }

    function customSend(address payable recipient, uint256 amount) public onlyOnwer {
        require(address(this).balance >= amount, "Not enough funds");
        recipient.send(amount);
    }

    function getBalance() public view onlyOnwer returns (uint) {
        return address(this).balance;
    }
}