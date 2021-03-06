/**
 *Submitted for verification at Etherscan.io on 2021-06-06
*/

pragma solidity ^0.6.0;


contract Discount {
    address public owner;
    mapping(address => CustomServiceFee) public serviceFees;
    mapping(address => CustomServiceFee) public automaticFees;

    uint256 constant MAX_SERVICE_FEE = 400;

    struct CustomServiceFee {
        bool active;
        uint256 amount;
    }

    constructor() public {
        owner = msg.sender;
    }

    function isCustomFeeSet(address _user) public view returns (bool) {
        return serviceFees[_user].active;
    }

    function getCustomServiceFee(address _user) public view returns (uint256) {
        return serviceFees[_user].amount;
    }

    function setServiceFee(address _user, uint256 _fee) public {
        require(msg.sender == owner, "Only owner");
        require(_fee >= MAX_SERVICE_FEE || _fee == 0);

        serviceFees[_user] = CustomServiceFee({active: true, amount: _fee});
    }

    function disableServiceFee(address _user) public {
        require(msg.sender == owner, "Only owner");

        serviceFees[_user] = CustomServiceFee({active: false, amount: 0});
    }
    
    function isAutoFeeSet(address _user) public view returns (bool) {
        return automaticFees[_user].active;
    }

    function getAutoServiceFee(address _user) public view returns (uint256) {
        return automaticFees[_user].amount;
    }

    function setAutoServiceFee(address _user, uint256 _fee) public {
        require(msg.sender == owner, "Only owner");
        require(_fee >= MAX_SERVICE_FEE || _fee == 0);

        automaticFees[_user] = CustomServiceFee({active: true, amount: _fee});
    }

    function disableAutoServiceFee(address _user) public {
        require(msg.sender == owner, "Only owner");

        automaticFees[_user] = CustomServiceFee({active: false, amount: 0});
    }
}