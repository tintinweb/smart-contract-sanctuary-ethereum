// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./interfaces/IETHRegistrarController.sol";

contract NamehashController {
    address immutable treasury;
    IETHRegistrarController immutable ensController;

    constructor(address _treasury, address _ensController) {
        treasury = _treasury;
        ensController = IETHRegistrarController(_ensController);
    }

    function register(
        string memory name,
        address owner,
        uint256 duration,
        bytes32 secret,
        address resolver,
        address addr
    ) public payable {
        // register in ENS
        ensController.register(name, owner, duration, secret, resolver, addr);
    }

    function withdraw() public {
        // withdraw to treasury
        payable(treasury).transfer(address(this).balance);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IETHRegistrarController {
    function register(
        string memory name,
        address owner,
        uint256 duration,
        bytes32 secret,
        address resolver,
        address addr
    ) external payable;

    function renew(string calldata, uint256) external payable;
}