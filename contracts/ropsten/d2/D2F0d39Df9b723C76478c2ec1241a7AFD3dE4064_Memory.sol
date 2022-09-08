pragma solidity >=0.8.0;

contract Memory {
    function send(bytes memory sigs) external view returns (bytes memory) {
        bytes memory result;

        assembly {
            result := add(sigs, 0x20)
        }

        return result;
    }
}