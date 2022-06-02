/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract ArgentAccount {
    address public signer;
    string public version = "0.1.0";

    modifier onlySigner() {
        require(
            msg.sender == signer || msg.sender == address(this),
            "argent/only-signer"
        );
        _;
    }

    function initialize(address _signer) external {
        require(signer == address(0), "argent/already-init");
        signer = _signer;
    }

    function execute(address to, bytes calldata data) external onlySigner {
        _call(to, data);
    }

    function _call(address to, bytes memory data) internal {
        (bool success, bytes memory result) = to.call(data);
        if (!success) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                revert(result, add(result, 32))
            }
        }
    }
}