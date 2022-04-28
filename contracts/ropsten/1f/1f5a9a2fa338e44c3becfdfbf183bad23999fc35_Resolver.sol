/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

pragma solidity 0.6.8;

contract Resolver {
    address owner;
    constructor() public {
        owner = msg.sender;
    } 

    function resolve() external payable {
        address challenge = 0x98882Ab0D07E6F9f0f1D3ef28623C3FF7E7e9445;
        bytes32 targetHash = 0xdb81b4d58595fbbbb592d3661a34cdca14d7ab379441400cbfa1b78bc447c365;
        require(msg.value == 1 ether);
        for (uint8 i=0; i<255; ++i) {
            if (keccak256(abi.encodePacked(i)) == targetHash) {
              challenge.call{value: msg.value, gas: gasleft()}(abi.encodeWithSignature("guess(uint8)", i));
            }
        }
    }

    function withdraw() external {
        require(msg.sender == owner);
         msg.sender.transfer(address(this).balance);
    }
}