//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract PiggyBankFactory {
    mapping(address => address[]) private addressToPiggyBanks;

    function createTimePiggyBank(
        address _owner,
        string memory _desc,
        uint64 _endTime
    ) public returns (address) {
        address newTimePiggyBank = address(new TimePiggyBank(_owner, _desc, _endTime));
        addressToPiggyBanks[_owner].push(newTimePiggyBank);
        return newTimePiggyBank;
    }


    function createAmmountPiggyBank(
        address _owner,
        string memory _desc,
        uint256 _targetAmmount
    ) public returns (address) {
        address newAmmountPiggyBank = address(new AmmountPiggyBank(_owner, _desc, _targetAmmount));
        addressToPiggyBanks[_owner].push(newAmmountPiggyBank);
        return newAmmountPiggyBank;
    }

    function getPiggyBanksByAddress(address _address) public view returns (address[] memory) {
        return addressToPiggyBanks[_address];
    }
}

abstract contract PiggyBank {
    address public owner;
    bool public isOver;
    string public desc;

    constructor(address _owner, string memory _desc) {
        owner = _owner;
        desc = _desc;
    }

    function deposit() public payable {
        require(!isOver, "This piggy bank in over!");
    }

    function withdraw() public {
        require(msg.sender == owner, "You are not an owner!");
        require(isWithdrawAvailable(), "You can't do withdraw yet");
        payable(owner).transfer(address(this).balance);
        isOver = true;
    }

    function isWithdrawAvailable() public view virtual returns (bool) {}
}

contract TimePiggyBank is PiggyBank {
    uint64 public endTime;

    constructor(
        address _owner,
        string memory _desc,
        uint64 _endTime
    ) PiggyBank(_owner, _desc) {
        endTime = _endTime;
    }

    function isWithdrawAvailable() public view override returns (bool) {
        return endTime < block.timestamp;
    }
}

contract AmmountPiggyBank is PiggyBank {
    uint256 public targetAmmount;

    constructor(
        address _owner,
        string memory _desc,
        uint256 _targetAmmount
    ) PiggyBank(_owner, _desc) {
        targetAmmount = _targetAmmount;
    }

    function isWithdrawAvailable() public view override returns (bool) {
        return targetAmmount < address(this).balance;
    }
}