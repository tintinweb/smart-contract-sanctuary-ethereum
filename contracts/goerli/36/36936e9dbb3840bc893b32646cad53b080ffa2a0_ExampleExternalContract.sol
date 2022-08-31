/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract ExampleExternalContract {
    bool public completed;
    address public allowedCaller;

    constructor(address _allowedCaller) {
        allowedCaller = _allowedCaller;
    }

    modifier onlyCaller() {
        require(
            msg.sender == allowedCaller,
            "Only allowed caller can call this funciton."
        );
        _;
    }

    // Users have to deposit to the contract before they can stake
    receive() external payable {}

    function adminWithdraw(address payable _to, uint256 _amount)
        external
        onlyCaller
    {
        (bool sent, bytes memory data) = _to.call{value: _amount}("");
        require(sent, "Faliled to send funds to the address");
    }

    function complete() public payable {
        completed = true;
    }

    function setAllowedCaller(address _allowedCaller) external onlyCaller {
        allowedCaller = _allowedCaller;
    }

    function getAllowedCaller() public view returns (address) {
        return allowedCaller;
    }
}