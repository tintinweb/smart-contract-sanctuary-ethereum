// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// Flashbots currently enforces a gas used floor. As of August 2021, that value is 42,000 gas. Any transaction that consumes less than this floor is rejected by relay
// This contract enables testing Flashbots with a single, simple transaction that will consume transaction's gas limit, ensuring the bundle won't be rejected
// See: https://docs.flashbots.net/flashbots-auction/searchers/advanced/bundle-pricing

contract WasteGas {
    uint256 public count;

    receive() external payable {}

    function contractEth(uint256 priorityFee) external {
        uint256 gasUsed = mockService();

        uint256 fee = (block.basefee + priorityFee) * tx.gasprice * gasUsed;

        block.coinbase.call{value: fee}(new bytes(0));
    }

    function senderEth() external payable {
        mockService();

        block.coinbase.call{value: msg.value}(new bytes(0));
    }

    function mockService() internal returns (uint256 gasUsed) {
        uint256 gasBefore = gasleft();

        count += 1;

        while (gasUsed < 42_000) {
            gasUsed = gasBefore - gasleft();
        }

        return gasUsed;
    }
}