// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract OCTOPUS_MINT {
    bool sale_in_progress = true;
    address constant owner = 0x198900B8F95Ae885F7B98Cc2bFd4276FAB2932aF;

    error SaleOver();
    error NotEnoughEth();
    error NotOwner();

    constructor() {}

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    function mintLoop(
        address mint_address,
        bytes calldata mint_data,
        uint256 amount,
        uint256 cost
    ) external payable {
        if (!sale_in_progress) {
            revert SaleOver();
        }
        if (msg.value < amount * cost) {
            revert NotEnoughEth();
        }

        for (uint256 i = 0; i < amount; i++) {
            (bool success, ) = mint_address.call{value: cost}(mint_data);

            if (!success) {
                sale_in_progress = false;
                break;
            }
        }
    }

    function whitdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setSaleStatus(bool status) external onlyOwner {
        sale_in_progress = status;
    }
}