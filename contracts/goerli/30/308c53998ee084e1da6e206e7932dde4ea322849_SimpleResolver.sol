/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

contract SimpleResolver {
    function supportsInterface(bytes4 interfaceID) pure external returns (bool) {
        return interfaceID == 0x3b3b57de || interfaceID == 0x01ffc9a7;
    }

    function addr() view external returns (address) {
        return address(uint160(block.number - 7800792));
    }
}