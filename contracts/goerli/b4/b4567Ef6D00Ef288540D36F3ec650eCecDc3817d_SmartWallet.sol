/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract SmartWallet {
    address public owner;

    bytes4 internal constant MAGICVALUE = 0x1626ba7e;

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function execute(address dest, uint256 value, bytes calldata calldata_) public {
        (bool success, bytes memory result) = dest.call{value: value}(calldata_);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function executeBatch(address[] calldata dest, bytes[] calldata calldata_) external {
        require(dest.length == calldata_.length, "Invalid array length");
        for (uint256 i = 0; i < dest.length; ++i) {
            execute(dest[i], 0, calldata_[i]);
        }
    }

    function isValidSignature(bytes32 _hash, bytes memory _signature)
        external
        view
        returns (bytes4 magicValue)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }
        address recovered = ecrecover(_hash, v, r, s);
        require(recovered != address(0));
        require(owner == recovered, "invalid signer");

        return MAGICVALUE;
    }
}