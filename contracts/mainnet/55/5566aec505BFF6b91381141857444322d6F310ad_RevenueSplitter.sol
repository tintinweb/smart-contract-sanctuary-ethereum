/**
 *Submitted for verification at Etherscan.io on 2023-03-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract RevenueSplitter {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    //@dev withdraws available balance
    function withdraw() external {
        require(msg.sender == owner, 'Unauthorized');
        address[8] memory receiverAddresses = [
        address(0x872CD12BD359E6ff8157486aFe62353214ee3Ef7),
        address(0x396189451aA809dB96beE90FEEc7E36dC007202d),
        address(0x83c05Ba7EAC77706eAd671abF2fc37Dbf971dE7E),
        address(0xBf6cACe24aa367942C6B9E4b24183F2c013750B0),
        address(0x3880C1b4F3AB213578cDF0297303B1c9deD826Ff),
        address(0xf87184Fc46A34BCb9DDA803e3cdFD576ba3719cd),
        address(0x75CA2E3180BCaee65017B297b41BD133934FEa16),
        address(0x6c93EF41D7854ED541e00eE035EBF43d5356E8D8)
        ];
        uint16[8] memory receiverPcts = [
            250,
            50,
            50,
            50,
            110,
            70,
            10,
            410
        ];
        uint256 denominator = 1000;
        uint256 balance = address(this).balance;
        for (uint256 i; i < receiverAddresses.length; i++) {
            payable(receiverAddresses[i]).transfer(receiverPcts[i] * balance / denominator);
        }
    }

    //@dev sets new owner who can withdraw
    function setOwner(address _newOwner) external {
        require(msg.sender == owner, 'Unauthorized');
        owner = _newOwner;
    }
}