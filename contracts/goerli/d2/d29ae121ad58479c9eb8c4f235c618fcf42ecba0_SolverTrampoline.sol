// SPDX-License-Identifier: LGPL-3.0-or-newer
pragma solidity =0.8.17;

interface IAuthenticator {
    function isSolver(address) external view returns (bool);
}

interface ISettlement {
    function authenticator() external view returns (IAuthenticator);
}

contract SolverTrampoline {
    error Unauthorized();

    ISettlement public immutable settlement;
    IAuthenticator public immutable authenticator;

    uint256 public nonce;

    constructor(ISettlement _settlement) {
        settlement = _settlement;
        authenticator = _settlement.authenticator();
    }

    function settle(bytes memory solution, bytes32 r, bytes32 s, uint8 v) external {
        bytes32 message = solutionMessage(solution, nonce++);
        address solver = ecrecover(message, v, r, s);
        if (solver == address(0) || !authenticator.isSolver(solver)) {
            revert Unauthorized();
        }

        (bool success, bytes memory data) = address(settlement).call(solution);
        if (!success) {
            assembly {
                revert(add(data, 32), mload(data))
            }
        }
    }

    function domainSeparator() public view returns (bytes32) {
        return keccak256(abi.encode(
            keccak256("EIP712Domain(uint256 chainId,address verifyingContract)"),
            block.chainid,
            address(this)
        ));
    }

    function solutionMessage(bytes memory solution) external view returns (bytes32) {
        return solutionMessage(solution, nonce);
    }

    function solutionMessage(bytes memory solution, uint256 _nonce) private view returns (bytes32) {
        return keccak256(abi.encodePacked(
            hex"1901",
            domainSeparator(),
            keccak256(abi.encode(
                keccak256("Solution(bytes solution,uint256 nonce)"),
                keccak256(solution),
                _nonce
            ))
        ));
    }
}