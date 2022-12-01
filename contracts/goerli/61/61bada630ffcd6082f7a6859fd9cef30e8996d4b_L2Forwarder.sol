/**
 *Submitted for verification at Etherscan.io on 2022-12-01
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IFactRegistry {
    function isValid(bytes32 fact) external view returns (bool);
}

interface IL1_to_L2_Forwarder {
    function sendMessageToL2(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload
    ) external payable returns (bytes32);
}


contract L2Forwarder {
    IFactRegistry public factRegistry;
    IL1_to_L2_Forwarder public l1_to_l2_forwarder;
    uint256 l2Selector = 352040181584456735608515580760888541466059565068553383579463728554843487745; //deposit()
    constructor(address _factRegistry, address _l1_to_l2_forwarder) {
        factRegistry = IFactRegistry(_factRegistry);
        l1_to_l2_forwarder = IL1_to_L2_Forwarder(_l1_to_l2_forwarder);
    }

    function forward(bytes32 fact, uint256 targetL2Address) external payable {
        
        bool status = factRegistry.isValid(fact);
        uint256[] memory payload = new uint256[](2);
        payload[0] = uint256(fact);
        payload[1] = status ? 1 : 0;

        l1_to_l2_forwarder.sendMessageToL2{value: msg.value}(targetL2Address, l2Selector, payload);
    }

}