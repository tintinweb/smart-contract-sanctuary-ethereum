// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {SignatureDecomposer} from "./SignatureDecomposer.sol";

interface IDaiPermit {
    function nonces(address holder) external returns (uint256);
    function permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) external;
}

contract DaiPermitResolver is SignatureDecomposer {
    function resolvePermit(address token_, address from_, uint256 amount_, uint256 deadline_, bytes calldata signature_) external {
        require(amount_ == 0 || amount_ == type(uint256).max, "DP: amount should be zero or max");
        uint256 nonce = IDaiPermit(token_).nonces(from_);
        IDaiPermit(token_).permit(from_, msg.sender, nonce, deadline_, amount_ != 0, v(signature_), r(signature_), s(signature_));
        require(IDaiPermit(token_).nonces(from_) == nonce + 1, "DP: permit did not succeed");
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

abstract contract SignatureDecomposer {
    function r(bytes calldata sig_) internal pure returns (bytes32) { return bytes32(sig_[0:32]); }
    function s(bytes calldata sig_) internal pure returns (bytes32) { return bytes32(sig_[32:64]); }
    function v(bytes calldata sig_) internal pure returns (uint8) { return uint8(bytes1(sig_[64:65])); }
}