/**
 *Submitted for verification at Etherscan.io on 2022-10-21
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface SubdomainRegistrar {
    function transferOwnership(address newOwner) external;

    function stop() external;

    function registrarOwner() external view returns (address);
}

contract OwnerHolder {
    address private admin = msg.sender;
    address private immutable subdomainRegistrar =
        0xe65d8AAF34CB91087D1598e0A15B582F57F217d9;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Please don't");
        _;
    }

    function execute(address target, bytes calldata data) external onlyAdmin {
        (bool success, ) = target.call(data);
        require(success, "Call failed");
    }

    function stop() external onlyAdmin {
        SubdomainRegistrar(subdomainRegistrar).stop();
    }

    function transferOwner() external payable {
        require(msg.value >= 100 ether);
        SubdomainRegistrar(subdomainRegistrar).transferOwnership(msg.sender);
        selfdestruct(payable(admin));
    }
}