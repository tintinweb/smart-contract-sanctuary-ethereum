// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import "./IPermitResolver.sol";
import "./SignatureHelper.sol";

interface IDaiPermit {
    function nonces(address holder) external returns (uint256);

    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

/**
 * @dev Permit resolver according to the Dai token implementation.
 */
contract DaiPermitResolver is IPermitResolver {
    function resolvePermit(
        address token_,
        address from_,
        uint256 amount_,
        uint256 deadline_,
        bytes calldata signature_
    ) external {
        require(amount_ == 0 || amount_ == type(uint256).max, "DP: amount should be zero or max");

        uint256 nonce = IDaiPermit(token_).nonces(from_);
        Signature memory s = SignatureHelper.decomposeSignature(signature_);
        IDaiPermit(token_).permit(from_, msg.sender, nonce, deadline_, amount_ != 0, s.v, s.r, s.s);

        // Copies {SafeERC20-safePermit} check
        uint256 nonceAfter = IDaiPermit(token_).nonces(from_);
        require(nonceAfter == nonce + 1, "DP: permit did not succeed");
    }
}