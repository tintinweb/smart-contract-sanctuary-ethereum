// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract EtherDistribution {

    /// Constant member variables
    uint256 public constant PERCENTAGE100 = 100000;

    /// Private variables
    address[] private _distributionAddresses;
    uint32[] private _distributionSharePercentages;

    /// Events
    event Received(address, uint);

    /// Constructor
    constructor(address[] memory distributionAddresses_,
                uint32[] memory distributionSharePercentages_) {

        require(distributionAddresses_.length == distributionSharePercentages_.length, 
            'Error: addresses size shall be equal to the share percentages size');
    
        uint256 sum = 0;
        for (uint8 i = 0; i < distributionSharePercentages_.length; ++i) {
            sum += distributionSharePercentages_[i];
            require(PERCENTAGE100 >= distributionSharePercentages_[i],
                                'Error: immediateReleasePercentage must be less than or equal to 100000');
        }
        require(PERCENTAGE100 == sum, 'Error: Sum of distribution share percentages must be 100000');

        _distributionAddresses = distributionAddresses_;
        _distributionSharePercentages = distributionSharePercentages_;
    }

    function getDistributionAddresses() view external returns(address[] memory) {
        return _distributionAddresses;
    }

    function getDistributionSharePercentages() view external returns(uint32[] memory) {
        return _distributionSharePercentages;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);

        uint256 sum = 0;
        uint256 value = 0;
        bool sent;
        bytes memory data;

        for (uint8 i = 0; i < _distributionSharePercentages.length - 1; ++i) {
            value = msg.value * _distributionSharePercentages[i] / PERCENTAGE100;
            sum += value;

            (sent, data) = _distributionAddresses[i].call{
                value: value
            }("");
            require(sent, "Failed to send Ether");
        }

        (sent, data) = _distributionAddresses[_distributionAddresses.length - 1].call{
                value: msg.value - sum
            }("");
        require(sent, "Failed to send Ether");
    }
}