//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

error NotOwner();
error BlockTimedOutTransferingFundsToFallBack();
error CallFailed();
error TheGuyIsntDeadYetJeez();

contract Switch {
    // gas optimisation
    address public immutable fallbackAddress;
    address public immutable i_owner;

    uint256 public last_block;

    constructor(address _fallbackAddress) {
        fallbackAddress = _fallbackAddress;
        i_owner = msg.sender;
        last_block = block.number;
    }

    function still_alive() public onlyOwner {
        // check if more than 10 blocks have been mined since last call
        // YES: transfer funds to fallbackAddress
        // NO: change last_block to current block
        if (last_block + 10 < block.number) {
            (bool CallSuccess, ) = payable(fallbackAddress).call{
                value: address(this).balance
            }("");
            if (!CallSuccess) {
                revert CallFailed();
            }
            revert BlockTimedOutTransferingFundsToFallBack();
        }
        last_block = block.number;
    }

    function trigger() public {
        if (last_block + 10 < block.number) {
            (bool CallSuccess, ) = payable(fallbackAddress).call{
                value: address(this).balance
            }("");
            if (!CallSuccess) {
                revert CallFailed();
            }
            // revert BlockTimedOutTransferingFundsToFallBack();
            return;
        }
        revert TheGuyIsntDeadYetJeez();
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }

    receive() external payable {}
}