// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import "./draft-IERC20Permit.sol";
import "./SafeERC20.sol";

import "./IPermitResolver.sol";
import "./SignatureHelper.sol";

/**
 * @dev Permit resolver according to the EIP-2612 spec.
 */
contract PermitResolver is IPermitResolver {
    using SafeERC20 for IERC20Permit;

    function resolvePermit(
        address token_,
        address from_,
        uint256 amount_,
        uint256 deadline_,
        bytes calldata signature_
    ) external {
        Signature memory s = SignatureHelper.decomposeSignature(signature_);
        IERC20Permit(token_).safePermit(from_, msg.sender, amount_, deadline_, s.v, s.r, s.s);
    }
}