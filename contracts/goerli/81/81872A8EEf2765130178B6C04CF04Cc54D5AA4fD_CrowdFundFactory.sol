// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./CrowdFund.sol";
import "./ICrowdFund.sol";

contract CrowdFundFactory {
    address[] factoryAddresses;
    event Deployed(address fundAddress);

    function deploy(string calldata _name, uint _target, address _beneficiary) external returns(address _crowdFund) {
        bytes memory bytecode = type(CrowdFund).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(block.timestamp));

        assembly {
            _crowdFund := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(_crowdFund)) {
                revert(0, 0)
            }
        }

        ICrowdFund(_crowdFund).createCrowdFund(_name, _target, _beneficiary);
        factoryAddresses.push(_crowdFund);

        emit Deployed(_crowdFund);
    }

    function returnClonedAddress() external view returns(address[] memory) {
        return factoryAddresses;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ICrowdFund.sol";

contract CrowdFund is ICrowdFund {
    address manager;
    string public name;
    uint public targetAmount;
    address beneficiary;

    struct DonatedInfo {
        uint amount;
        uint time;
    }

    mapping(address => DonatedInfo) fundDonationList;

    event CreateCrowdFund(address indexed _benef, uint indexed _targ, string indexed name);
    event Donate(address indexed donor, uint indexed amount, uint indexed time);
    event withdrawFund(address indexed _benef, uint indexed amount);

    constructor() {
        manager = msg.sender;
    }

    modifier onlyOwner {
        require(manager == msg.sender, "You are not permitted to perform this operation!");
        _;
    }

    function createCrowdFund(string calldata _name, uint _target, address _beneficiary) external onlyOwner {
        require(_beneficiary != address(0), "Fund raising cannot be done for address zero");
        name = _name;
        targetAmount = _target * 1e18;
        beneficiary = _beneficiary;

        emit CreateCrowdFund(_beneficiary, _target, _name);
    }

    function withdraw() external onlyOwner {

        uint amount = address(this).balance;
        require(amount >= targetAmount, "CrowdFunding is not complete yet!");
        (bool sent, ) = payable(beneficiary).call{value: amount}("");
        require(sent, "Unable to send token");

        emit withdrawFund(beneficiary, amount);
    }

    function donateFund() external payable {
        address giver = msg.sender;
        uint _amount = msg.value;
        require(_amount > 0, "Amount should be greater than zero!");
        
        DonatedInfo storage _info = fundDonationList[giver];
        _info.amount += _amount;
        _info.time = block.timestamp;

        emit Donate(giver, _amount, block.timestamp);
    }

    function amountDonated(address _donor) external view returns(uint) {
        return fundDonationList[_donor].amount;
    }

    function getContractBalance() external view onlyOwner returns(uint) {
        return address(this).balance;
    }

    receive() external payable {}

    fallback() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ICrowdFund {
    function createCrowdFund(string calldata _name, uint _targ, address _ben) external;

    function withdraw() external;

    function donateFund() external payable;

    function amountDonated(address _donor) external view returns(uint);

    function getContractBalance() external view returns(uint);
}