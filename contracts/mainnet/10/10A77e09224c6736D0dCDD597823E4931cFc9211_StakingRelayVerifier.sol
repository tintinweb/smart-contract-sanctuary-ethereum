// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;


/// @title Staking Relay Verifier
/// @author https://github.com/broxus
contract StakingRelayVerifier {
    event RelayAddressVerified(uint160 eth_addr, int8 workchain_id, uint256 addr_body);
    
    function verify_relay_staker_address(int8 workchain_id, uint256 address_body) external {
        emit RelayAddressVerified(uint160(msg.sender), workchain_id, address_body);
    }
}