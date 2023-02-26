/**
 *Submitted for verification at Etherscan.io on 2023-02-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.0;

contract RetirementManager {
    address public owner;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public keepAlive;
    mapping(address => mapping(address => uint256)) public beneficiaries;

    uint256 public retirementAge;
    uint256 public retirementPayDay;

    event BeneficiariesUpdated(
        address indexed account,
        address[] beneficiaries,
        uint256[] distributionPercentages
    );

    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0.");
        balances[msg.sender] += msg.value;
        keepAlive[msg.sender] = block.timestamp + 30 days;
    }

    function withdraw(uint256 amount) public {
        require(amount <= balances[msg.sender], "Insufficient balance.");
        require(
            block.timestamp < keepAlive[msg.sender],
            "You need to be alive to withdraw your funds."
        );
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function requestHeritage() public {
        require(
            block.timestamp >= keepAlive[msg.sender],
            "You need to be deceased to request your heritage."
        );
        for (uint256 i = 0; i < getBeneficiariesCount(msg.sender); i++) {
            address beneficiary = getBeneficiaryAtIndex(msg.sender, i);
            uint256 percentage = beneficiaries[msg.sender][beneficiary];
            uint256 amount = (balances[msg.sender] * percentage) / 100;
            payable(beneficiary).transfer(amount);
        }
        balances[msg.sender] = 0;
    }

    function setBeneficiaries(
        address[] memory _beneficiaries,
        uint256[] memory _distributionPercentages
    ) public onlyOwner {
        require(
            _beneficiaries.length == _distributionPercentages.length,
            "Lengths of beneficiaries and distributionPercentages arrays do not match."
        );
        uint256 totalPercentage = 0;
        for (uint256 i = 0; i < _distributionPercentages.length; i++) {
            totalPercentage += _distributionPercentages[i];
        }
        require(totalPercentage == 100, "Percentages must add up to 100.");
        setBeneficiariesForAccount(
            msg.sender,
            _beneficiaries,
            _distributionPercentages
        );
    }

    function setRetirementAge(uint256 _retirementAge) public onlyOwner {
        retirementAge = _retirementAge;
    }

    function setRetirementPayDay(uint256 _retirementPayDay) public onlyOwner {
        retirementPayDay = _retirementPayDay;
    }

    function setKeepAlive(uint256 secondsToLive) public {
        keepAlive[msg.sender] = block.timestamp + secondsToLive;
    }

    function emergencyWithdrawal() public onlyOwner {
        for (uint256 i = 0; i < getBeneficiariesCount(msg.sender); i++) {
            address beneficiary = getBeneficiaryAtIndex(msg.sender, i);
            uint256 percentage = beneficiaries[msg.sender][beneficiary];
            uint256 amount = (balances[msg.sender] * percentage) / 100;
            payable(beneficiary).transfer(amount);
        }
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficient contract balance.");
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(balance);
    }

    function setBeneficiariesForAccount(
        address account,
        address[] memory _beneficiaries,
        uint256[] memory _distributionPercentages
    ) internal {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            beneficiaries[account][
                _beneficiaries[i]
            ] = _distributionPercentages[i];
        }
        emit BeneficiariesUpdated(
            account,
            _beneficiaries,
            _distributionPercentages
        );
    }

    function getBeneficiaryAtIndex(address account, uint256 index)
        public
        view
        returns (address)
    {
        require(index < getBeneficiariesCount(account), "Index out of range.");
        uint256 i = 0;
        address[] memory keys = getBeneficiaryKeys(account);
        for (i = 0; i < keys.length; i++) {
            if (i == index) {
                return keys[i];
            }
        }
        return address(0);
    }

    function getBeneficiaryKeys(address account)
        public
        view
        returns (address[] memory)
    {
        uint256 i = 0;
        address[] memory keys = new address[](getBeneficiariesCount(account));
        for (i = 0; i < keys.length; i++) {
            keys[i] = address(0);
        }
        i = 0;
        for (i = 0; i < keys.length; i++) {
            keys[i] = getBeneficiaryKeyAtIndex(account, i);
        }
        return keys;
    }

    function getBeneficiaryKeyAtIndex(address account, uint256 index)
        public
        view
        returns (address)
    {
        uint256 i = 0;
        address[] memory keys = getBeneficiaryKeys(account);
        for (i = 0; i < keys.length; i++) {
            if (i == index) {
                return keys[i];
            }
        }
        return address(0);
    }

    function getBeneficiariesCount(address account)
        public
        view
        returns (uint256)
    {
        uint256 count = 0;
        address[] memory keys = getBeneficiaryKeys(account);
        uint256 i = 0;
        for (i = 0; i < keys.length; i++) {
            if (keys[i] != address(0)) {
                count++;
            }
        }
        return count;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }
}