/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.12;

interface IPriceGate {

    /// @notice This function should return how much ether or tokens the minter must pay to mint an NFT
    function getCost(uint) external view returns (uint ethCost);

    /// @notice This function is called by MerkleIdentity when minting an NFT. It is where funds get collected.
    function passThruGate(uint, address) external payable;
}

/// @title A factory pattern for the simplest price gates, what's the price and who does it go to?
/// @author metapriest, adrian.wachel, marek.babiarz, radoslaw.gorecki
/// @notice This contract has a management key that can add new gates
/// @dev Note passing thru the gate forwards all gas, so beneficiary can be a contract, possibly malicious
contract FixedPricePassThruGate is IPriceGate {

    // this represents a single gate
    struct Gate {
        uint ethCost;  // how much does it cost to pass thru it
        address beneficiary;  // who gets the eth that is paid
    }

    // count the gates
    uint public numGates;
    // array-like map of gate structs
    mapping (uint => Gate) public gates;

    error NotEnoughETH(address from, uint price, uint paid);
    error TransferETHFailed(address from, address to, uint amount);

    /// @notice This adds a price gate to the list of available price gates
    /// @dev Anyone can call this, adding gates that don't get connected to merkleIndex isn't useful
    /// @param _ethCost amount of ether required to pass thru the gate
    /// @param _beneficiary who receives the ether
    function addGate(uint _ethCost, address _beneficiary) external {
        // prefix operator increments then evaluates, first gate is at index 1
        Gate storage gate = gates[++numGates];
        gate.ethCost = _ethCost;
        gate.beneficiary = _beneficiary;
    }

    /// @notice Get the cost of passing thru this gate
    /// @param index which gate are we talking about?
    /// @return _ethCost the amount of ether required to pass thru this gate
    function getCost(uint index) override external view returns (uint) {
        return gates[index].ethCost;
    }

    /// @notice Pass thru this gate, should be called by MerkleIndex
    /// @dev This can be called by anyone, devs can call it to test it on mainnet
    /// @param index which gate are we passing thru?
    function passThruGate(uint index, address sender) override external payable {
        Gate memory gate = gates[index];
        if (msg.value < gate.ethCost) {
            revert NotEnoughETH(sender, gate.ethCost, msg.value);
        }

        // pass thru ether
        if (msg.value > 0) {
            // use .call so we can send to contracts, for example gnosis safe, re-entrance is not a threat here
            (bool sent,) = gate.beneficiary.call{value: gate.ethCost}("");
            if (sent == false) {
                revert TransferETHFailed(address(this), gate.beneficiary, gate.ethCost);
            }

            uint leftover = msg.value - gate.ethCost;
            if (leftover > 0) {
                (bool sent2,) = sender.call{value: leftover}("");
                if (sent2 == false) {
                    revert TransferETHFailed(address(this), sender, leftover);
                }
            }
        }
    }
}