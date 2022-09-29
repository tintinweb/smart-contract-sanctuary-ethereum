// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall {
    function multicall(bytes[] calldata data) public payable returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}

contract TestMulticall is Multicall {
    function functionThatRevertsWithError(string memory error) external pure {
        revert(error);
    }

    struct Tuple {
        uint256 a;
        uint256 b;
    }

    function functionThatReturnsTuple(uint256 a, uint256 b) external pure returns (Tuple memory tuple) {
        tuple = Tuple({b: a, a: b});
    }

    uint256 public paid;

    function pays() external payable {
        paid += msg.value;
    }

    function returnSender() external view returns (address) {
        return msg.sender;
    }
}

contract SomeProxyAddress {

        event Finished(bool result);  

        function multicall(address[] calldata addresses, bytes[] calldata data) public payable returns (bytes[] memory results) {
                results = new bytes[](data.length);
                for (uint256 i = 0; i < data.length; i++) {
                    (bool success, bytes memory result) = addresses[i].delegatecall(data[i]);

                    emit Finished(success);

                    results[i] = result;
                }

        }
}