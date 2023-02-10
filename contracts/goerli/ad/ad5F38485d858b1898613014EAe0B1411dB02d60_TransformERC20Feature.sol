// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

interface IERC20TokenV06 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @dev send `value` token to `to` from `msg.sender`
    /// @param to The address of the recipient
    /// @param value The amount of token to be transferred
    /// @return True if transfer was successful
    function transfer(address to, uint256 value) external returns (bool);

    /// @dev send `value` token to `to` from `from` on the condition it is approved by `from`
    /// @param from The address of the sender
    /// @param to The address of the recipient
    /// @param value The amount of token to be transferred
    /// @return True if transfer was successful
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    /// @dev `msg.sender` approves `spender` to spend `value` tokens
    /// @param spender The address of the account able to transfer the tokens
    /// @param value The amount of wei to be approved for transfer
    /// @return Always true if the call has enough gas to complete execution
    function approve(address spender, uint256 value) external returns (bool);

    /// @dev Query total supply of token
    /// @return Total supply of token
    function totalSupply() external view returns (uint256);

    /// @dev Get the balance of `owner`.
    /// @param owner The address from which the balance will be retrieved
    /// @return Balance of owner
    function balanceOf(address owner) external view returns (uint256);

    /// @dev Get the allowance for `spender` to spend from `owner`.
    /// @param owner The address of the account owning tokens
    /// @param spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address owner, address spender) external view returns (uint256);

    /// @dev Get the number of decimals this token has.
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

import "./IERC20TokenV06.sol";

interface IEtherTokenV06 is IERC20TokenV06 {
    /// @dev Wrap ether.
    function deposit() external payable;

    /// @dev Unwrap ether.
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibBytesV06.sol";
import "./IERC20TokenV06.sol";

library LibERC20TokenV06 {
    bytes private constant DECIMALS_CALL_DATA = hex"313ce567";

    /// @dev Calls `IERC20TokenV06(token).approve()`.
    ///      Reverts if the return data is invalid or the call reverts.
    /// @param token The address of the token contract.
    /// @param spender The address that receives an allowance.
    /// @param allowance The allowance to set.
    function compatApprove(IERC20TokenV06 token, address spender, uint256 allowance) internal {
        bytes memory callData = abi.encodeWithSelector(token.approve.selector, spender, allowance);
        _callWithOptionalBooleanResult(address(token), callData);
    }

    /// @dev Calls `IERC20TokenV06(token).approve()` and sets the allowance to the
    ///      maximum if the current approval is not already >= an amount.
    ///      Reverts if the return data is invalid or the call reverts.
    /// @param token The address of the token contract.
    /// @param spender The address that receives an allowance.
    /// @param amount The minimum allowance needed.
    function approveIfBelow(IERC20TokenV06 token, address spender, uint256 amount) internal {
        if (token.allowance(address(this), spender) < amount) {
            compatApprove(token, spender, uint256(-1));
        }
    }

    /// @dev Calls `IERC20TokenV06(token).transfer()`.
    ///      Reverts if the return data is invalid or the call reverts.
    /// @param token The address of the token contract.
    /// @param to The address that receives the tokens
    /// @param amount Number of tokens to transfer.
    function compatTransfer(IERC20TokenV06 token, address to, uint256 amount) internal {
        bytes memory callData = abi.encodeWithSelector(token.transfer.selector, to, amount);
        _callWithOptionalBooleanResult(address(token), callData);
    }

    /// @dev Calls `IERC20TokenV06(token).transferFrom()`.
    ///      Reverts if the return data is invalid or the call reverts.
    /// @param token The address of the token contract.
    /// @param from The owner of the tokens.
    /// @param to The address that receives the tokens
    /// @param amount Number of tokens to transfer.
    function compatTransferFrom(IERC20TokenV06 token, address from, address to, uint256 amount) internal {
        bytes memory callData = abi.encodeWithSelector(token.transferFrom.selector, from, to, amount);
        _callWithOptionalBooleanResult(address(token), callData);
    }

    /// @dev Retrieves the number of decimals for a token.
    ///      Returns `18` if the call reverts.
    /// @param token The address of the token contract.
    /// @return tokenDecimals The number of decimals places for the token.
    function compatDecimals(IERC20TokenV06 token) internal view returns (uint8 tokenDecimals) {
        tokenDecimals = 18;
        (bool didSucceed, bytes memory resultData) = address(token).staticcall(DECIMALS_CALL_DATA);
        if (didSucceed && resultData.length >= 32) {
            tokenDecimals = uint8(LibBytesV06.readUint256(resultData, 0));
        }
    }

    /// @dev Retrieves the allowance for a token, owner, and spender.
    ///      Returns `0` if the call reverts.
    /// @param token The address of the token contract.
    /// @param owner The owner of the tokens.
    /// @param spender The address the spender.
    /// @return allowance_ The allowance for a token, owner, and spender.
    function compatAllowance(
        IERC20TokenV06 token,
        address owner,
        address spender
    ) internal view returns (uint256 allowance_) {
        (bool didSucceed, bytes memory resultData) = address(token).staticcall(
            abi.encodeWithSelector(token.allowance.selector, owner, spender)
        );
        if (didSucceed && resultData.length >= 32) {
            allowance_ = LibBytesV06.readUint256(resultData, 0);
        }
    }

    /// @dev Retrieves the balance for a token owner.
    ///      Returns `0` if the call reverts.
    /// @param token The address of the token contract.
    /// @param owner The owner of the tokens.
    /// @return balance The token balance of an owner.
    function compatBalanceOf(IERC20TokenV06 token, address owner) internal view returns (uint256 balance) {
        (bool didSucceed, bytes memory resultData) = address(token).staticcall(
            abi.encodeWithSelector(token.balanceOf.selector, owner)
        );
        if (didSucceed && resultData.length >= 32) {
            balance = LibBytesV06.readUint256(resultData, 0);
        }
    }

    /// @dev Executes a call on address `target` with calldata `callData`
    ///      and asserts that either nothing was returned or a single boolean
    ///      was returned equal to `true`.
    /// @param target The call target.
    /// @param callData The abi-encoded call data.
    function _callWithOptionalBooleanResult(address target, bytes memory callData) private {
        (bool didSucceed, bytes memory resultData) = target.call(callData);
        // Revert if the call reverted.
        if (!didSucceed) {
            LibRichErrorsV06.rrevert(resultData);
        }
        // If we get back 0 returndata, this may be a non-standard ERC-20 that
        // does not return a boolean. Check that it at least contains code.
        if (resultData.length == 0) {
            uint256 size;
            assembly {
                size := extcodesize(target)
            }
            require(size > 0, "invalid token address, contains no code");
            return;
        }
        // If we get back at least 32 bytes, we know the target address
        // contains code, and we assume it is a token that returned a boolean
        // success value, which must be true.
        if (resultData.length >= 32) {
            uint256 result = LibBytesV06.readUint256(resultData, 0);
            if (result == 1) {
                return;
            } else {
                LibRichErrorsV06.rrevert(resultData);
            }
        }
        // If 0 < returndatasize < 32, the target is a contract, but not a
        // valid token.
        LibRichErrorsV06.rrevert(resultData);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

import "./interfaces/IAuthorizableV06.sol";
import "./errors/LibRichErrorsV06.sol";
import "./errors/LibAuthorizableRichErrorsV06.sol";
import "./OwnableV06.sol";

contract AuthorizableV06 is OwnableV06, IAuthorizableV06 {
    /// @dev Only authorized addresses can invoke functions with this modifier.
    modifier onlyAuthorized() {
        _assertSenderIsAuthorized();
        _;
    }

    // @dev Whether an address is authorized to call privileged functions.
    // @param 0 Address to query.
    // @return 0 Whether the address is authorized.
    mapping(address => bool) public override authorized;
    // @dev Whether an address is authorized to call privileged functions.
    // @param 0 Index of authorized address.
    // @return 0 Authorized address.
    address[] public override authorities;

    /// @dev Initializes the `owner` address.
    constructor() public OwnableV06() {}

    /// @dev Authorizes an address.
    /// @param target Address to authorize.
    function addAuthorizedAddress(address target) external override onlyOwner {
        _addAuthorizedAddress(target);
    }

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    function removeAuthorizedAddress(address target) external override onlyOwner {
        if (!authorized[target]) {
            LibRichErrorsV06.rrevert(LibAuthorizableRichErrorsV06.TargetNotAuthorizedError(target));
        }
        for (uint256 i = 0; i < authorities.length; i++) {
            if (authorities[i] == target) {
                _removeAuthorizedAddressAtIndex(target, i);
                break;
            }
        }
    }

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    /// @param index Index of target in authorities array.
    function removeAuthorizedAddressAtIndex(address target, uint256 index) external override onlyOwner {
        _removeAuthorizedAddressAtIndex(target, index);
    }

    /// @dev Gets all authorized addresses.
    /// @return Array of authorized addresses.
    function getAuthorizedAddresses() external view override returns (address[] memory) {
        return authorities;
    }

    /// @dev Reverts if msg.sender is not authorized.
    function _assertSenderIsAuthorized() internal view {
        if (!authorized[msg.sender]) {
            LibRichErrorsV06.rrevert(LibAuthorizableRichErrorsV06.SenderNotAuthorizedError(msg.sender));
        }
    }

    /// @dev Authorizes an address.
    /// @param target Address to authorize.
    function _addAuthorizedAddress(address target) internal {
        // Ensure that the target is not the zero address.
        if (target == address(0)) {
            LibRichErrorsV06.rrevert(LibAuthorizableRichErrorsV06.ZeroCantBeAuthorizedError());
        }

        // Ensure that the target is not already authorized.
        if (authorized[target]) {
            LibRichErrorsV06.rrevert(LibAuthorizableRichErrorsV06.TargetAlreadyAuthorizedError(target));
        }

        authorized[target] = true;
        authorities.push(target);
        emit AuthorizedAddressAdded(target, msg.sender);
    }

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    /// @param index Index of target in authorities array.
    function _removeAuthorizedAddressAtIndex(address target, uint256 index) internal {
        if (!authorized[target]) {
            LibRichErrorsV06.rrevert(LibAuthorizableRichErrorsV06.TargetNotAuthorizedError(target));
        }
        if (index >= authorities.length) {
            LibRichErrorsV06.rrevert(LibAuthorizableRichErrorsV06.IndexOutOfBoundsError(index, authorities.length));
        }
        if (authorities[index] != target) {
            LibRichErrorsV06.rrevert(
                LibAuthorizableRichErrorsV06.AuthorizedAddressMismatchError(authorities[index], target)
            );
        }

        delete authorized[target];
        authorities[index] = authorities[authorities.length - 1];
        authorities.pop();
        emit AuthorizedAddressRemoved(target, msg.sender);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

library LibAuthorizableRichErrorsV06 {
    // bytes4(keccak256("AuthorizedAddressMismatchError(address,address)"))
    bytes4 internal constant AUTHORIZED_ADDRESS_MISMATCH_ERROR_SELECTOR = 0x140a84db;

    // bytes4(keccak256("IndexOutOfBoundsError(uint256,uint256)"))
    bytes4 internal constant INDEX_OUT_OF_BOUNDS_ERROR_SELECTOR = 0xe9f83771;

    // bytes4(keccak256("SenderNotAuthorizedError(address)"))
    bytes4 internal constant SENDER_NOT_AUTHORIZED_ERROR_SELECTOR = 0xb65a25b9;

    // bytes4(keccak256("TargetAlreadyAuthorizedError(address)"))
    bytes4 internal constant TARGET_ALREADY_AUTHORIZED_ERROR_SELECTOR = 0xde16f1a0;

    // bytes4(keccak256("TargetNotAuthorizedError(address)"))
    bytes4 internal constant TARGET_NOT_AUTHORIZED_ERROR_SELECTOR = 0xeb5108a2;

    // bytes4(keccak256("ZeroCantBeAuthorizedError()"))
    bytes internal constant ZERO_CANT_BE_AUTHORIZED_ERROR_BYTES = hex"57654fe4";

    function AuthorizedAddressMismatchError(address authorized, address target) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(AUTHORIZED_ADDRESS_MISMATCH_ERROR_SELECTOR, authorized, target);
    }

    function IndexOutOfBoundsError(uint256 index, uint256 length) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(INDEX_OUT_OF_BOUNDS_ERROR_SELECTOR, index, length);
    }

    function SenderNotAuthorizedError(address sender) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(SENDER_NOT_AUTHORIZED_ERROR_SELECTOR, sender);
    }

    function TargetAlreadyAuthorizedError(address target) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(TARGET_ALREADY_AUTHORIZED_ERROR_SELECTOR, target);
    }

    function TargetNotAuthorizedError(address target) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(TARGET_NOT_AUTHORIZED_ERROR_SELECTOR, target);
    }

    function ZeroCantBeAuthorizedError() internal pure returns (bytes memory) {
        return ZERO_CANT_BE_AUTHORIZED_ERROR_BYTES;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

library LibBytesRichErrorsV06 {
    enum InvalidByteOperationErrorCodes {
        FromLessThanOrEqualsToRequired,
        ToLessThanOrEqualsLengthRequired,
        LengthGreaterThanZeroRequired,
        LengthGreaterThanOrEqualsFourRequired,
        LengthGreaterThanOrEqualsTwentyRequired,
        LengthGreaterThanOrEqualsThirtyTwoRequired,
        LengthGreaterThanOrEqualsNestedBytesLengthRequired,
        DestinationLengthGreaterThanOrEqualSourceLengthRequired
    }

    // bytes4(keccak256("InvalidByteOperationError(uint8,uint256,uint256)"))
    bytes4 internal constant INVALID_BYTE_OPERATION_ERROR_SELECTOR = 0x28006595;

    function InvalidByteOperationError(
        InvalidByteOperationErrorCodes errorCode,
        uint256 offset,
        uint256 required
    ) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(INVALID_BYTE_OPERATION_ERROR_SELECTOR, errorCode, offset, required);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

library LibMathRichErrorsV06 {
    // bytes4(keccak256("DivisionByZeroError()"))
    bytes internal constant DIVISION_BY_ZERO_ERROR = hex"a791837c";

    // bytes4(keccak256("RoundingError(uint256,uint256,uint256)"))
    bytes4 internal constant ROUNDING_ERROR_SELECTOR = 0x339f3de2;

    function DivisionByZeroError() internal pure returns (bytes memory) {
        return DIVISION_BY_ZERO_ERROR;
    }

    function RoundingError(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(ROUNDING_ERROR_SELECTOR, numerator, denominator, target);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/
pragma solidity ^0.6.5;

library LibOwnableRichErrorsV06 {
    // bytes4(keccak256("OnlyOwnerError(address,address)"))
    bytes4 internal constant ONLY_OWNER_ERROR_SELECTOR = 0x1de45ad1;

    // bytes4(keccak256("TransferOwnerToZeroError()"))
    bytes internal constant TRANSFER_OWNER_TO_ZERO_ERROR_BYTES = hex"e69edc3e";

    function OnlyOwnerError(address sender, address owner) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(ONLY_OWNER_ERROR_SELECTOR, sender, owner);
    }

    function TransferOwnerToZeroError() internal pure returns (bytes memory) {
        return TRANSFER_OWNER_TO_ZERO_ERROR_BYTES;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

library LibRichErrorsV06 {
    // bytes4(keccak256("Error(string)"))
    bytes4 internal constant STANDARD_ERROR_SELECTOR = 0x08c379a0;

    /// @dev ABI encode a standard, string revert error payload.
    ///      This is the same payload that would be included by a `revert(string)`
    ///      solidity statement. It has the function signature `Error(string)`.
    /// @param message The error string.
    /// @return The ABI encoded error.
    function StandardError(string memory message) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(STANDARD_ERROR_SELECTOR, bytes(message));
    }

    /// @dev Reverts an encoded rich revert reason `errorData`.
    /// @param errorData ABI encoded error data.
    function rrevert(bytes memory errorData) internal pure {
        assembly {
            revert(add(errorData, 0x20), mload(errorData))
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

library LibSafeMathRichErrorsV06 {
    // bytes4(keccak256("Uint256BinOpError(uint8,uint256,uint256)"))
    bytes4 internal constant UINT256_BINOP_ERROR_SELECTOR = 0xe946c1bb;

    // bytes4(keccak256("Uint256DowncastError(uint8,uint256)"))
    bytes4 internal constant UINT256_DOWNCAST_ERROR_SELECTOR = 0xc996af7b;

    enum BinOpErrorCodes {
        ADDITION_OVERFLOW,
        MULTIPLICATION_OVERFLOW,
        SUBTRACTION_UNDERFLOW,
        DIVISION_BY_ZERO
    }

    enum DowncastErrorCodes {
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT32,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT64,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT96,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT128
    }

    function Uint256BinOpError(BinOpErrorCodes errorCode, uint256 a, uint256 b) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(UINT256_BINOP_ERROR_SELECTOR, errorCode, a, b);
    }

    function Uint256DowncastError(DowncastErrorCodes errorCode, uint256 a) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(UINT256_DOWNCAST_ERROR_SELECTOR, errorCode, a);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

import "./IOwnableV06.sol";

interface IAuthorizableV06 is IOwnableV06 {
    // Event logged when a new address is authorized.
    event AuthorizedAddressAdded(address indexed target, address indexed caller);

    // Event logged when a currently authorized address is unauthorized.
    event AuthorizedAddressRemoved(address indexed target, address indexed caller);

    /// @dev Authorizes an address.
    /// @param target Address to authorize.
    function addAuthorizedAddress(address target) external;

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    function removeAuthorizedAddress(address target) external;

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    /// @param index Index of target in authorities array.
    function removeAuthorizedAddressAtIndex(address target, uint256 index) external;

    /// @dev Gets all authorized addresses.
    /// @return authorizedAddresses Array of authorized addresses.
    function getAuthorizedAddresses() external view returns (address[] memory authorizedAddresses);

    /// @dev Whether an adderss is authorized to call privileged functions.
    /// @param addr Address to query.
    /// @return isAuthorized Whether the address is authorized.
    function authorized(address addr) external view returns (bool isAuthorized);

    /// @dev All addresseses authorized to call privileged functions.
    /// @param idx Index of authorized address.
    /// @return addr Authorized address.
    function authorities(uint256 idx) external view returns (address addr);
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

interface IOwnableV06 {
    /// @dev Emitted by Ownable when ownership is transferred.
    /// @param previousOwner The previous owner of the contract.
    /// @param newOwner The new owner of the contract.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @dev Transfers ownership of the contract to a new address.
    /// @param newOwner The address that will become the owner.
    function transferOwnership(address newOwner) external;

    /// @dev The owner of this contract.
    /// @return ownerAddress The owner address.
    function owner() external view returns (address ownerAddress);
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

import "./errors/LibBytesRichErrorsV06.sol";
import "./errors/LibRichErrorsV06.sol";

library LibBytesV06 {
    using LibBytesV06 for bytes;

    /// @dev Gets the memory address for a byte array.
    /// @param input Byte array to lookup.
    /// @return memoryAddress Memory address of byte array. This
    ///         points to the header of the byte array which contains
    ///         the length.
    function rawAddress(bytes memory input) internal pure returns (uint256 memoryAddress) {
        assembly {
            memoryAddress := input
        }
        return memoryAddress;
    }

    /// @dev Gets the memory address for the contents of a byte array.
    /// @param input Byte array to lookup.
    /// @return memoryAddress Memory address of the contents of the byte array.
    function contentAddress(bytes memory input) internal pure returns (uint256 memoryAddress) {
        assembly {
            memoryAddress := add(input, 32)
        }
        return memoryAddress;
    }

    /// @dev Copies `length` bytes from memory location `source` to `dest`.
    /// @param dest memory address to copy bytes to.
    /// @param source memory address to copy bytes from.
    /// @param length number of bytes to copy.
    function memCopy(uint256 dest, uint256 source, uint256 length) internal pure {
        if (length < 32) {
            // Handle a partial word by reading destination and masking
            // off the bits we are interested in.
            // This correctly handles overlap, zero lengths and source == dest
            assembly {
                let mask := sub(exp(256, sub(32, length)), 1)
                let s := and(mload(source), not(mask))
                let d := and(mload(dest), mask)
                mstore(dest, or(s, d))
            }
        } else {
            // Skip the O(length) loop when source == dest.
            if (source == dest) {
                return;
            }

            // For large copies we copy whole words at a time. The final
            // word is aligned to the end of the range (instead of after the
            // previous) to handle partial words. So a copy will look like this:
            //
            //  ####
            //      ####
            //          ####
            //            ####
            //
            // We handle overlap in the source and destination range by
            // changing the copying direction. This prevents us from
            // overwriting parts of source that we still need to copy.
            //
            // This correctly handles source == dest
            //
            if (source > dest) {
                assembly {
                    // We subtract 32 from `sEnd` and `dEnd` because it
                    // is easier to compare with in the loop, and these
                    // are also the addresses we need for copying the
                    // last bytes.
                    length := sub(length, 32)
                    let sEnd := add(source, length)
                    let dEnd := add(dest, length)

                    // Remember the last 32 bytes of source
                    // This needs to be done here and not after the loop
                    // because we may have overwritten the last bytes in
                    // source already due to overlap.
                    let last := mload(sEnd)

                    // Copy whole words front to back
                    // Note: the first check is always true,
                    // this could have been a do-while loop.
                    for {

                    } lt(source, sEnd) {

                    } {
                        mstore(dest, mload(source))
                        source := add(source, 32)
                        dest := add(dest, 32)
                    }

                    // Write the last 32 bytes
                    mstore(dEnd, last)
                }
            } else {
                assembly {
                    // We subtract 32 from `sEnd` and `dEnd` because those
                    // are the starting points when copying a word at the end.
                    length := sub(length, 32)
                    let sEnd := add(source, length)
                    let dEnd := add(dest, length)

                    // Remember the first 32 bytes of source
                    // This needs to be done here and not after the loop
                    // because we may have overwritten the first bytes in
                    // source already due to overlap.
                    let first := mload(source)

                    // Copy whole words back to front
                    // We use a signed comparisson here to allow dEnd to become
                    // negative (happens when source and dest < 32). Valid
                    // addresses in local memory will never be larger than
                    // 2**255, so they can be safely re-interpreted as signed.
                    // Note: the first check is always true,
                    // this could have been a do-while loop.
                    for {

                    } slt(dest, dEnd) {

                    } {
                        mstore(dEnd, mload(sEnd))
                        sEnd := sub(sEnd, 32)
                        dEnd := sub(dEnd, 32)
                    }

                    // Write the first 32 bytes
                    mstore(dest, first)
                }
            }
        }
    }

    /// @dev Returns a slices from a byte array.
    /// @param b The byte array to take a slice from.
    /// @param from The starting index for the slice (inclusive).
    /// @param to The final index for the slice (exclusive).
    /// @return result The slice containing bytes at indices [from, to)
    function slice(bytes memory b, uint256 from, uint256 to) internal pure returns (bytes memory result) {
        // Ensure that the from and to positions are valid positions for a slice within
        // the byte array that is being used.
        if (from > to) {
            LibRichErrorsV06.rrevert(
                LibBytesRichErrorsV06.InvalidByteOperationError(
                    LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.FromLessThanOrEqualsToRequired,
                    from,
                    to
                )
            );
        }
        if (to > b.length) {
            LibRichErrorsV06.rrevert(
                LibBytesRichErrorsV06.InvalidByteOperationError(
                    LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.ToLessThanOrEqualsLengthRequired,
                    to,
                    b.length
                )
            );
        }

        // Create a new bytes structure and copy contents
        result = new bytes(to - from);
        memCopy(result.contentAddress(), b.contentAddress() + from, result.length);
        return result;
    }

    /// @dev Returns a slice from a byte array without preserving the input.
    ///      When `from == 0`, the original array will match the slice.
    ///      In other cases its state will be corrupted.
    /// @param b The byte array to take a slice from. Will be destroyed in the process.
    /// @param from The starting index for the slice (inclusive).
    /// @param to The final index for the slice (exclusive).
    /// @return result The slice containing bytes at indices [from, to)
    function sliceDestructive(bytes memory b, uint256 from, uint256 to) internal pure returns (bytes memory result) {
        // Ensure that the from and to positions are valid positions for a slice within
        // the byte array that is being used.
        if (from > to) {
            LibRichErrorsV06.rrevert(
                LibBytesRichErrorsV06.InvalidByteOperationError(
                    LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.FromLessThanOrEqualsToRequired,
                    from,
                    to
                )
            );
        }
        if (to > b.length) {
            LibRichErrorsV06.rrevert(
                LibBytesRichErrorsV06.InvalidByteOperationError(
                    LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.ToLessThanOrEqualsLengthRequired,
                    to,
                    b.length
                )
            );
        }

        // Create a new bytes structure around [from, to) in-place.
        assembly {
            result := add(b, from)
            mstore(result, sub(to, from))
        }
        return result;
    }

    /// @dev Pops the last byte off of a byte array by modifying its length.
    /// @param b Byte array that will be modified.
    /// @return result The byte that was popped off.
    function popLastByte(bytes memory b) internal pure returns (bytes1 result) {
        if (b.length == 0) {
            LibRichErrorsV06.rrevert(
                LibBytesRichErrorsV06.InvalidByteOperationError(
                    LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.LengthGreaterThanZeroRequired,
                    b.length,
                    0
                )
            );
        }

        // Store last byte.
        result = b[b.length - 1];

        assembly {
            // Decrement length of byte array.
            let newLen := sub(mload(b), 1)
            mstore(b, newLen)
        }
        return result;
    }

    /// @dev Tests equality of two byte arrays.
    /// @param lhs First byte array to compare.
    /// @param rhs Second byte array to compare.
    /// @return equal True if arrays are the same. False otherwise.
    function equals(bytes memory lhs, bytes memory rhs) internal pure returns (bool equal) {
        // Keccak gas cost is 30 + numWords * 6. This is a cheap way to compare.
        // We early exit on unequal lengths, but keccak would also correctly
        // handle this.
        return lhs.length == rhs.length && keccak256(lhs) == keccak256(rhs);
    }

    /// @dev Reads an address from a position in a byte array.
    /// @param b Byte array containing an address.
    /// @param index Index in byte array of address.
    /// @return result address from byte array.
    function readAddress(bytes memory b, uint256 index) internal pure returns (address result) {
        if (b.length < index + 20) {
            LibRichErrorsV06.rrevert(
                LibBytesRichErrorsV06.InvalidByteOperationError(
                    LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsTwentyRequired,
                    b.length,
                    index + 20 // 20 is length of address
                )
            );
        }

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Read address from array memory
        assembly {
            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 20-byte mask to obtain address
            result := and(mload(add(b, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

    /// @dev Writes an address into a specific position in a byte array.
    /// @param b Byte array to insert address into.
    /// @param index Index in byte array of address.
    /// @param input Address to put into byte array.
    function writeAddress(bytes memory b, uint256 index, address input) internal pure {
        if (b.length < index + 20) {
            LibRichErrorsV06.rrevert(
                LibBytesRichErrorsV06.InvalidByteOperationError(
                    LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsTwentyRequired,
                    b.length,
                    index + 20 // 20 is length of address
                )
            );
        }

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Store address into array memory
        assembly {
            // The address occupies 20 bytes and mstore stores 32 bytes.
            // First fetch the 32-byte word where we'll be storing the address, then
            // apply a mask so we have only the bytes in the word that the address will not occupy.
            // Then combine these bytes with the address and store the 32 bytes back to memory with mstore.

            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 12-byte mask to obtain extra bytes occupying word of memory where we'll store the address
            let neighbors := and(
                mload(add(b, index)),
                0xffffffffffffffffffffffff0000000000000000000000000000000000000000
            )

            // Make sure input address is clean.
            // (Solidity does not guarantee this)
            input := and(input, 0xffffffffffffffffffffffffffffffffffffffff)

            // Store the neighbors and address into memory
            mstore(add(b, index), xor(input, neighbors))
        }
    }

    /// @dev Reads a bytes32 value from a position in a byte array.
    /// @param b Byte array containing a bytes32 value.
    /// @param index Index in byte array of bytes32 value.
    /// @return result bytes32 value from byte array.
    function readBytes32(bytes memory b, uint256 index) internal pure returns (bytes32 result) {
        if (b.length < index + 32) {
            LibRichErrorsV06.rrevert(
                LibBytesRichErrorsV06.InvalidByteOperationError(
                    LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsThirtyTwoRequired,
                    b.length,
                    index + 32
                )
            );
        }

        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        // Read the bytes32 from array memory
        assembly {
            result := mload(add(b, index))
        }
        return result;
    }

    /// @dev Writes a bytes32 into a specific position in a byte array.
    /// @param b Byte array to insert <input> into.
    /// @param index Index in byte array of <input>.
    /// @param input bytes32 to put into byte array.
    function writeBytes32(bytes memory b, uint256 index, bytes32 input) internal pure {
        if (b.length < index + 32) {
            LibRichErrorsV06.rrevert(
                LibBytesRichErrorsV06.InvalidByteOperationError(
                    LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsThirtyTwoRequired,
                    b.length,
                    index + 32
                )
            );
        }

        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        // Read the bytes32 from array memory
        assembly {
            mstore(add(b, index), input)
        }
    }

    /// @dev Reads a uint256 value from a position in a byte array.
    /// @param b Byte array containing a uint256 value.
    /// @param index Index in byte array of uint256 value.
    /// @return result uint256 value from byte array.
    function readUint256(bytes memory b, uint256 index) internal pure returns (uint256 result) {
        result = uint256(readBytes32(b, index));
        return result;
    }

    /// @dev Writes a uint256 into a specific position in a byte array.
    /// @param b Byte array to insert <input> into.
    /// @param index Index in byte array of <input>.
    /// @param input uint256 to put into byte array.
    function writeUint256(bytes memory b, uint256 index, uint256 input) internal pure {
        writeBytes32(b, index, bytes32(input));
    }

    /// @dev Reads an unpadded bytes4 value from a position in a byte array.
    /// @param b Byte array containing a bytes4 value.
    /// @param index Index in byte array of bytes4 value.
    /// @return result bytes4 value from byte array.
    function readBytes4(bytes memory b, uint256 index) internal pure returns (bytes4 result) {
        if (b.length < index + 4) {
            LibRichErrorsV06.rrevert(
                LibBytesRichErrorsV06.InvalidByteOperationError(
                    LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsFourRequired,
                    b.length,
                    index + 4
                )
            );
        }

        // Arrays are prefixed by a 32 byte length field
        index += 32;

        // Read the bytes4 from array memory
        assembly {
            result := mload(add(b, index))
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            result := and(result, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }

    /// @dev Writes a new length to a byte array.
    ///      Decreasing length will lead to removing the corresponding lower order bytes from the byte array.
    ///      Increasing length may lead to appending adjacent in-memory bytes to the end of the byte array.
    /// @param b Bytes array to write new length to.
    /// @param length New length of byte array.
    function writeLength(bytes memory b, uint256 length) internal pure {
        assembly {
            mstore(b, length)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

import "./LibSafeMathV06.sol";
import "./errors/LibRichErrorsV06.sol";
import "./errors/LibMathRichErrorsV06.sol";

library LibMathV06 {
    using LibSafeMathV06 for uint256;

    /// @dev Calculates partial value given a numerator and denominator rounded down.
    ///      Reverts if rounding error is >= 0.1%
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return partialAmount Partial value of target rounded down.
    function safeGetPartialAmountFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (uint256 partialAmount) {
        if (isRoundingErrorFloor(numerator, denominator, target)) {
            LibRichErrorsV06.rrevert(LibMathRichErrorsV06.RoundingError(numerator, denominator, target));
        }

        partialAmount = numerator.safeMul(target).safeDiv(denominator);
        return partialAmount;
    }

    /// @dev Calculates partial value given a numerator and denominator rounded down.
    ///      Reverts if rounding error is >= 0.1%
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return partialAmount Partial value of target rounded up.
    function safeGetPartialAmountCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (uint256 partialAmount) {
        if (isRoundingErrorCeil(numerator, denominator, target)) {
            LibRichErrorsV06.rrevert(LibMathRichErrorsV06.RoundingError(numerator, denominator, target));
        }

        // safeDiv computes `floor(a / b)`. We use the identity (a, b integer):
        //       ceil(a / b) = floor((a + b - 1) / b)
        // To implement `ceil(a / b)` using safeDiv.
        partialAmount = numerator.safeMul(target).safeAdd(denominator.safeSub(1)).safeDiv(denominator);

        return partialAmount;
    }

    /// @dev Calculates partial value given a numerator and denominator rounded down.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return partialAmount Partial value of target rounded down.
    function getPartialAmountFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (uint256 partialAmount) {
        partialAmount = numerator.safeMul(target).safeDiv(denominator);
        return partialAmount;
    }

    /// @dev Calculates partial value given a numerator and denominator rounded down.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return partialAmount Partial value of target rounded up.
    function getPartialAmountCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (uint256 partialAmount) {
        // safeDiv computes `floor(a / b)`. We use the identity (a, b integer):
        //       ceil(a / b) = floor((a + b - 1) / b)
        // To implement `ceil(a / b)` using safeDiv.
        partialAmount = numerator.safeMul(target).safeAdd(denominator.safeSub(1)).safeDiv(denominator);

        return partialAmount;
    }

    /// @dev Checks if rounding error >= 0.1% when rounding down.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to multiply with numerator/denominator.
    /// @return isError Rounding error is present.
    function isRoundingErrorFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (bool isError) {
        if (denominator == 0) {
            LibRichErrorsV06.rrevert(LibMathRichErrorsV06.DivisionByZeroError());
        }

        // The absolute rounding error is the difference between the rounded
        // value and the ideal value. The relative rounding error is the
        // absolute rounding error divided by the absolute value of the
        // ideal value. This is undefined when the ideal value is zero.
        //
        // The ideal value is `numerator * target / denominator`.
        // Let's call `numerator * target % denominator` the remainder.
        // The absolute error is `remainder / denominator`.
        //
        // When the ideal value is zero, we require the absolute error to
        // be zero. Fortunately, this is always the case. The ideal value is
        // zero iff `numerator == 0` and/or `target == 0`. In this case the
        // remainder and absolute error are also zero.
        if (target == 0 || numerator == 0) {
            return false;
        }

        // Otherwise, we want the relative rounding error to be strictly
        // less than 0.1%.
        // The relative error is `remainder / (numerator * target)`.
        // We want the relative error less than 1 / 1000:
        //        remainder / (numerator * denominator)  <  1 / 1000
        // or equivalently:
        //        1000 * remainder  <  numerator * target
        // so we have a rounding error iff:
        //        1000 * remainder  >=  numerator * target
        uint256 remainder = mulmod(target, numerator, denominator);
        isError = remainder.safeMul(1000) >= numerator.safeMul(target);
        return isError;
    }

    /// @dev Checks if rounding error >= 0.1% when rounding up.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to multiply with numerator/denominator.
    /// @return isError Rounding error is present.
    function isRoundingErrorCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (bool isError) {
        if (denominator == 0) {
            LibRichErrorsV06.rrevert(LibMathRichErrorsV06.DivisionByZeroError());
        }

        // See the comments in `isRoundingError`.
        if (target == 0 || numerator == 0) {
            // When either is zero, the ideal value and rounded value are zero
            // and there is no rounding error. (Although the relative error
            // is undefined.)
            return false;
        }
        // Compute remainder as before
        uint256 remainder = mulmod(target, numerator, denominator);
        remainder = denominator.safeSub(remainder) % denominator;
        isError = remainder.safeMul(1000) >= numerator.safeMul(target);
        return isError;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

import "./errors/LibRichErrorsV06.sol";
import "./errors/LibSafeMathRichErrorsV06.sol";

library LibSafeMathV06 {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        if (c / a != b) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.MULTIPLICATION_OVERFLOW,
                    a,
                    b
                )
            );
        }
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.DIVISION_BY_ZERO,
                    a,
                    b
                )
            );
        }
        uint256 c = a / b;
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b > a) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.SUBTRACTION_UNDERFLOW,
                    a,
                    b
                )
            );
        }
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        if (c < a) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.ADDITION_OVERFLOW,
                    a,
                    b
                )
            );
        }
        return c;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function safeMul128(uint128 a, uint128 b) internal pure returns (uint128) {
        if (a == 0) {
            return 0;
        }
        uint128 c = a * b;
        if (c / a != b) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.MULTIPLICATION_OVERFLOW,
                    a,
                    b
                )
            );
        }
        return c;
    }

    function safeDiv128(uint128 a, uint128 b) internal pure returns (uint128) {
        if (b == 0) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.DIVISION_BY_ZERO,
                    a,
                    b
                )
            );
        }
        uint128 c = a / b;
        return c;
    }

    function safeSub128(uint128 a, uint128 b) internal pure returns (uint128) {
        if (b > a) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.SUBTRACTION_UNDERFLOW,
                    a,
                    b
                )
            );
        }
        return a - b;
    }

    function safeAdd128(uint128 a, uint128 b) internal pure returns (uint128) {
        uint128 c = a + b;
        if (c < a) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.ADDITION_OVERFLOW,
                    a,
                    b
                )
            );
        }
        return c;
    }

    function max128(uint128 a, uint128 b) internal pure returns (uint128) {
        return a >= b ? a : b;
    }

    function min128(uint128 a, uint128 b) internal pure returns (uint128) {
        return a < b ? a : b;
    }

    function safeDowncastToUint128(uint256 a) internal pure returns (uint128) {
        if (a > type(uint128).max) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256DowncastError(
                    LibSafeMathRichErrorsV06.DowncastErrorCodes.VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT128,
                    a
                )
            );
        }
        return uint128(a);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

import "./interfaces/IOwnableV06.sol";
import "./errors/LibRichErrorsV06.sol";
import "./errors/LibOwnableRichErrorsV06.sol";

contract OwnableV06 is IOwnableV06 {
    /// @dev The owner of this contract.
    /// @return 0 The owner address.
    address public override owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        _assertSenderIsOwner();
        _;
    }

    /// @dev Change the owner of this contract.
    /// @param newOwner New owner address.
    function transferOwnership(address newOwner) public override onlyOwner {
        if (newOwner == address(0)) {
            LibRichErrorsV06.rrevert(LibOwnableRichErrorsV06.TransferOwnerToZeroError());
        } else {
            owner = newOwner;
            emit OwnershipTransferred(msg.sender, newOwner);
        }
    }

    function _assertSenderIsOwner() internal view {
        if (msg.sender != owner) {
            LibRichErrorsV06.rrevert(LibOwnableRichErrorsV06.OnlyOwnerError(msg.sender, owner));
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;

library LibCommonRichErrors {
    function OnlyCallableBySelfError(address sender) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(keccak256("OnlyCallableBySelfError(address)")), sender);
    }

    function IllegalReentrancyError(bytes4 selector, uint256 reentrancyFlags) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("IllegalReentrancyError(bytes4,uint256)")),
                selector,
                reentrancyFlags
            );
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;

library LibLiquidityProviderRichErrors {
    function LiquidityProviderIncompleteSellError(
        address providerAddress,
        address makerToken,
        address takerToken,
        uint256 sellAmount,
        uint256 boughtAmount,
        uint256 minBuyAmount
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(
                    keccak256("LiquidityProviderIncompleteSellError(address,address,address,uint256,uint256,uint256)")
                ),
                providerAddress,
                makerToken,
                takerToken,
                sellAmount,
                boughtAmount,
                minBuyAmount
            );
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;

library LibMetaTransactionsRichErrors {
    function InvalidMetaTransactionsArrayLengthsError(
        uint256 mtxCount,
        uint256 signatureCount
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("InvalidMetaTransactionsArrayLengthsError(uint256,uint256)")),
                mtxCount,
                signatureCount
            );
    }

    function MetaTransactionUnsupportedFunctionError(
        bytes32 mtxHash,
        bytes4 selector
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("MetaTransactionUnsupportedFunctionError(bytes32,bytes4)")),
                mtxHash,
                selector
            );
    }

    function MetaTransactionWrongSenderError(
        bytes32 mtxHash,
        address sender,
        address expectedSender
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("MetaTransactionWrongSenderError(bytes32,address,address)")),
                mtxHash,
                sender,
                expectedSender
            );
    }

    function MetaTransactionExpiredError(
        bytes32 mtxHash,
        uint256 time,
        uint256 expirationTime
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("MetaTransactionExpiredError(bytes32,uint256,uint256)")),
                mtxHash,
                time,
                expirationTime
            );
    }

    function MetaTransactionGasPriceError(
        bytes32 mtxHash,
        uint256 gasPrice,
        uint256 minGasPrice,
        uint256 maxGasPrice
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("MetaTransactionGasPriceError(bytes32,uint256,uint256,uint256)")),
                mtxHash,
                gasPrice,
                minGasPrice,
                maxGasPrice
            );
    }

    function MetaTransactionInsufficientEthError(
        bytes32 mtxHash,
        uint256 ethBalance,
        uint256 ethRequired
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("MetaTransactionInsufficientEthError(bytes32,uint256,uint256)")),
                mtxHash,
                ethBalance,
                ethRequired
            );
    }

    function MetaTransactionInvalidSignatureError(
        bytes32 mtxHash,
        bytes memory signature,
        bytes memory errData
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("MetaTransactionInvalidSignatureError(bytes32,bytes,bytes)")),
                mtxHash,
                signature,
                errData
            );
    }

    function MetaTransactionAlreadyExecutedError(
        bytes32 mtxHash,
        uint256 executedBlockNumber
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("MetaTransactionAlreadyExecutedError(bytes32,uint256)")),
                mtxHash,
                executedBlockNumber
            );
    }

    function MetaTransactionCallFailedError(
        bytes32 mtxHash,
        bytes memory callData,
        bytes memory returnData
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("MetaTransactionCallFailedError(bytes32,bytes,bytes)")),
                mtxHash,
                callData,
                returnData
            );
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;

library LibNativeOrdersRichErrors {
    function ProtocolFeeRefundFailed(address receiver, uint256 refundAmount) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("ProtocolFeeRefundFailed(address,uint256)")),
                receiver,
                refundAmount
            );
    }

    function OrderNotFillableByOriginError(
        bytes32 orderHash,
        address txOrigin,
        address orderTxOrigin
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("OrderNotFillableByOriginError(bytes32,address,address)")),
                orderHash,
                txOrigin,
                orderTxOrigin
            );
    }

    function OrderNotFillableError(bytes32 orderHash, uint8 orderStatus) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(bytes4(keccak256("OrderNotFillableError(bytes32,uint8)")), orderHash, orderStatus);
    }

    function OrderNotSignedByMakerError(
        bytes32 orderHash,
        address signer,
        address maker
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("OrderNotSignedByMakerError(bytes32,address,address)")),
                orderHash,
                signer,
                maker
            );
    }

    function InvalidSignerError(address maker, address signer) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(keccak256("InvalidSignerError(address,address)")), maker, signer);
    }

    function OrderNotFillableBySenderError(
        bytes32 orderHash,
        address sender,
        address orderSender
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("OrderNotFillableBySenderError(bytes32,address,address)")),
                orderHash,
                sender,
                orderSender
            );
    }

    function OrderNotFillableByTakerError(
        bytes32 orderHash,
        address taker,
        address orderTaker
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("OrderNotFillableByTakerError(bytes32,address,address)")),
                orderHash,
                taker,
                orderTaker
            );
    }

    function CancelSaltTooLowError(uint256 minValidSalt, uint256 oldMinValidSalt) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("CancelSaltTooLowError(uint256,uint256)")),
                minValidSalt,
                oldMinValidSalt
            );
    }

    function FillOrKillFailedError(
        bytes32 orderHash,
        uint256 takerTokenFilledAmount,
        uint256 takerTokenFillAmount
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("FillOrKillFailedError(bytes32,uint256,uint256)")),
                orderHash,
                takerTokenFilledAmount,
                takerTokenFillAmount
            );
    }

    function OnlyOrderMakerAllowed(
        bytes32 orderHash,
        address sender,
        address maker
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("OnlyOrderMakerAllowed(bytes32,address,address)")),
                orderHash,
                sender,
                maker
            );
    }

    function BatchFillIncompleteError(
        bytes32 orderHash,
        uint256 takerTokenFilledAmount,
        uint256 takerTokenFillAmount
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("BatchFillIncompleteError(bytes32,uint256,uint256)")),
                orderHash,
                takerTokenFilledAmount,
                takerTokenFillAmount
            );
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;

library LibNFTOrdersRichErrors {
    function OverspentEthError(uint256 ethSpent, uint256 ethAvailable) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(keccak256("OverspentEthError(uint256,uint256)")), ethSpent, ethAvailable);
    }

    function InsufficientEthError(uint256 ethAvailable, uint256 orderAmount) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("InsufficientEthError(uint256,uint256)")),
                ethAvailable,
                orderAmount
            );
    }

    function ERC721TokenMismatchError(address token1, address token2) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(keccak256("ERC721TokenMismatchError(address,address)")), token1, token2);
    }

    function ERC1155TokenMismatchError(address token1, address token2) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(keccak256("ERC1155TokenMismatchError(address,address)")), token1, token2);
    }

    function ERC20TokenMismatchError(address token1, address token2) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(keccak256("ERC20TokenMismatchError(address,address)")), token1, token2);
    }

    function NegativeSpreadError(uint256 sellOrderAmount, uint256 buyOrderAmount) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("NegativeSpreadError(uint256,uint256)")),
                sellOrderAmount,
                buyOrderAmount
            );
    }

    function SellOrderFeesExceedSpreadError(
        uint256 sellOrderFees,
        uint256 spread
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("SellOrderFeesExceedSpreadError(uint256,uint256)")),
                sellOrderFees,
                spread
            );
    }

    function OnlyTakerError(address sender, address taker) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(keccak256("OnlyTakerError(address,address)")), sender, taker);
    }

    function InvalidSignerError(address maker, address signer) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(keccak256("InvalidSignerError(address,address)")), maker, signer);
    }

    function OrderNotFillableError(
        address maker,
        uint256 nonce,
        uint8 orderStatus
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("OrderNotFillableError(address,uint256,uint8)")),
                maker,
                nonce,
                orderStatus
            );
    }

    function TokenIdMismatchError(uint256 tokenId, uint256 orderTokenId) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(bytes4(keccak256("TokenIdMismatchError(uint256,uint256)")), tokenId, orderTokenId);
    }

    function PropertyValidationFailedError(
        address propertyValidator,
        address token,
        uint256 tokenId,
        bytes memory propertyData,
        bytes memory errorData
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("PropertyValidationFailedError(address,address,uint256,bytes,bytes)")),
                propertyValidator,
                token,
                tokenId,
                propertyData,
                errorData
            );
    }

    function ExceedsRemainingOrderAmount(
        uint128 remainingOrderAmount,
        uint128 fillAmount
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("ExceedsRemainingOrderAmount(uint128,uint128)")),
                remainingOrderAmount,
                fillAmount
            );
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;

library LibOwnableRichErrors {
    function OnlyOwnerError(address sender, address owner) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(keccak256("OnlyOwnerError(address,address)")), sender, owner);
    }

    function TransferOwnerToZeroError() internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(keccak256("TransferOwnerToZeroError()")));
    }

    function MigrateCallFailedError(address target, bytes memory resultData) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(keccak256("MigrateCallFailedError(address,bytes)")), target, resultData);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;


library LibProxyRichErrors {

    // solhint-disable func-name-mixedcase

    function NotImplementedError(bytes4 selector)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("NotImplementedError(bytes4)")),
            selector
        );
    }

    function InvalidBootstrapCallerError(address actual, address expected)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InvalidBootstrapCallerError(address,address)")),
            actual,
            expected
        );
    }

    function InvalidDieCallerError(address actual, address expected)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InvalidDieCallerError(address,address)")),
            actual,
            expected
        );
    }

    function BootstrapCallFailedError(address target, bytes memory resultData)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("BootstrapCallFailedError(address,bytes)")),
            target,
            resultData
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;

library LibSignatureRichErrors {
    enum SignatureValidationErrorCodes {
        ALWAYS_INVALID,
        INVALID_LENGTH,
        UNSUPPORTED,
        ILLEGAL,
        WRONG_SIGNER,
        BAD_SIGNATURE_DATA
    }

    function SignatureValidationError(
        SignatureValidationErrorCodes code,
        bytes32 hash,
        address signerAddress,
        bytes memory signature
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("SignatureValidationError(uint8,bytes32,address,bytes)")),
                code,
                hash,
                signerAddress,
                signature
            );
    }

    function SignatureValidationError(
        SignatureValidationErrorCodes code,
        bytes32 hash
    ) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(keccak256("SignatureValidationError(uint8,bytes32)")), code, hash);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;

library LibSimpleFunctionRegistryRichErrors {
    function NotInRollbackHistoryError(bytes4 selector, address targetImpl) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("NotInRollbackHistoryError(bytes4,address)")),
                selector,
                targetImpl
            );
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;

library LibTransformERC20RichErrors {
    function InsufficientEthAttachedError(uint256 ethAttached, uint256 ethNeeded) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("InsufficientEthAttachedError(uint256,uint256)")),
                ethAttached,
                ethNeeded
            );
    }

    function IncompleteTransformERC20Error(
        address outputToken,
        uint256 outputTokenAmount,
        uint256 minOutputTokenAmount
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("IncompleteTransformERC20Error(address,uint256,uint256)")),
                outputToken,
                outputTokenAmount,
                minOutputTokenAmount
            );
    }

    function NegativeTransformERC20OutputError(
        address outputToken,
        uint256 outputTokenLostAmount
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("NegativeTransformERC20OutputError(address,uint256)")),
                outputToken,
                outputTokenLostAmount
            );
    }

    function TransformerFailedError(
        address transformer,
        bytes memory transformerData,
        bytes memory resultData
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("TransformerFailedError(address,bytes,bytes)")),
                transformer,
                transformerData,
                resultData
            );
    }

    // Common Transformer errors ///////////////////////////////////////////////

    function OnlyCallableByDeployerError(address caller, address deployer) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(bytes4(keccak256("OnlyCallableByDeployerError(address,address)")), caller, deployer);
    }

    function InvalidExecutionContextError(
        address actualContext,
        address expectedContext
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("InvalidExecutionContextError(address,address)")),
                actualContext,
                expectedContext
            );
    }

    enum InvalidTransformDataErrorCode {
        INVALID_TOKENS,
        INVALID_ARRAY_LENGTH
    }

    function InvalidTransformDataError(
        InvalidTransformDataErrorCode errorCode,
        bytes memory transformData
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("InvalidTransformDataError(uint8,bytes)")),
                errorCode,
                transformData
            );
    }

    // FillQuoteTransformer errors /////////////////////////////////////////////

    function IncompleteFillSellQuoteError(
        address sellToken,
        uint256 soldAmount,
        uint256 sellAmount
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("IncompleteFillSellQuoteError(address,uint256,uint256)")),
                sellToken,
                soldAmount,
                sellAmount
            );
    }

    function IncompleteFillBuyQuoteError(
        address buyToken,
        uint256 boughtAmount,
        uint256 buyAmount
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("IncompleteFillBuyQuoteError(address,uint256,uint256)")),
                buyToken,
                boughtAmount,
                buyAmount
            );
    }

    function InsufficientTakerTokenError(
        uint256 tokenBalance,
        uint256 tokensNeeded
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("InsufficientTakerTokenError(uint256,uint256)")),
                tokenBalance,
                tokensNeeded
            );
    }

    function InsufficientProtocolFeeError(uint256 ethBalance, uint256 ethNeeded) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("InsufficientProtocolFeeError(uint256,uint256)")),
                ethBalance,
                ethNeeded
            );
    }

    function InvalidERC20AssetDataError(bytes memory assetData) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(keccak256("InvalidERC20AssetDataError(bytes)")), assetData);
    }

    function InvalidTakerFeeTokenError(address token) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(keccak256("InvalidTakerFeeTokenError(address)")), token);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;

library LibWalletRichErrors {
    function WalletExecuteCallFailedError(
        address wallet,
        address callTarget,
        bytes memory callData,
        uint256 callValue,
        bytes memory errorData
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("WalletExecuteCallFailedError(address,address,bytes,uint256,bytes)")),
                wallet,
                callTarget,
                callData,
                callValue,
                errorData
            );
    }

    function WalletExecuteDelegateCallFailedError(
        address wallet,
        address callTarget,
        bytes memory callData,
        bytes memory errorData
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("WalletExecuteDelegateCallFailedError(address,address,bytes,bytes)")),
                wallet,
                callTarget,
                callData,
                errorData
            );
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IEtherTokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/AuthorizableV06.sol";
import "../vendor/v3/IStaking.sol";

/// @dev The collector contract for protocol fees
contract FeeCollector is AuthorizableV06 {
    /// @dev Allow ether transfers to the collector.
    receive() external payable {}

    constructor() public {
        _addAuthorizedAddress(msg.sender);
    }

    /// @dev   Approve the staking contract and join a pool. Only an authority
    ///        can call this.
    /// @param weth The WETH contract.
    /// @param staking The staking contract.
    /// @param poolId The pool ID this contract is collecting fees for.
    function initialize(IEtherTokenV06 weth, IStaking staking, bytes32 poolId) external onlyAuthorized {
        weth.approve(address(staking), type(uint256).max);
        staking.joinStakingPoolAsMaker(poolId);
    }

    /// @dev Convert all held ether to WETH. Only an authority can call this.
    /// @param weth The WETH contract.
    function convertToWeth(IEtherTokenV06 weth) external onlyAuthorized {
        if (address(this).balance > 0) {
            weth.deposit{value: address(this).balance}();
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IEtherTokenV06.sol";
import "../vendor/v3/IStaking.sol";
import "./FeeCollector.sol";
import "./LibFeeCollector.sol";

/// @dev A contract that manages `FeeCollector` contracts.
contract FeeCollectorController {
    /// @dev Hash of the fee collector init code.
    bytes32 public immutable FEE_COLLECTOR_INIT_CODE_HASH;
    /// @dev The WETH contract.
    IEtherTokenV06 private immutable WETH;
    /// @dev The staking contract.
    IStaking private immutable STAKING;

    constructor(IEtherTokenV06 weth, IStaking staking) public {
        FEE_COLLECTOR_INIT_CODE_HASH = keccak256(type(FeeCollector).creationCode);
        WETH = weth;
        STAKING = staking;
    }

    /// @dev Deploy (if needed) a `FeeCollector` contract for `poolId`
    ///      and wrap its ETH into WETH. Anyone may call this.
    /// @param poolId The pool ID associated with the staking pool.
    /// @return feeCollector The `FeeCollector` contract instance.
    function prepareFeeCollectorToPayFees(bytes32 poolId) external returns (FeeCollector feeCollector) {
        feeCollector = getFeeCollector(poolId);
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(feeCollector)
        }

        if (codeSize == 0) {
            // Create and initialize the contract if necessary.
            new FeeCollector{salt: bytes32(poolId)}();
            feeCollector.initialize(WETH, STAKING, poolId);
        }

        if (address(feeCollector).balance > 1) {
            feeCollector.convertToWeth(WETH);
        }

        return feeCollector;
    }

    /// @dev Get the `FeeCollector` contract for a given pool ID. The contract
    ///      will not actually exist until `prepareFeeCollectorToPayFees()`
    ///      has been called once.
    /// @param poolId The pool ID associated with the staking pool.
    /// @return feeCollector The `FeeCollector` contract instance.
    function getFeeCollector(bytes32 poolId) public view returns (FeeCollector feeCollector) {
        return
            FeeCollector(LibFeeCollector.getFeeCollectorAddress(address(this), FEE_COLLECTOR_INIT_CODE_HASH, poolId));
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-utils/contracts/src/v06/errors/LibOwnableRichErrorsV06.sol";
import "../errors/LibWalletRichErrors.sol";
import "./IFlashWallet.sol";

/// @dev A contract that can execute arbitrary calls from its owner.
contract FlashWallet is IFlashWallet {
    using LibRichErrorsV06 for bytes;

    /// @dev Store the owner/deployer as an immutable to make this contract stateless.
    address public immutable override owner;

    constructor() public {
        // The deployer is the owner.
        owner = msg.sender;
    }

    /// @dev Allows only the (immutable) owner to call a function.
    modifier onlyOwner() virtual {
        if (msg.sender != owner) {
            LibOwnableRichErrorsV06.OnlyOwnerError(msg.sender, owner).rrevert();
        }
        _;
    }

    /// @dev Execute an arbitrary call. Only an authority can call this.
    /// @param target The call target.
    /// @param callData The call data.
    /// @param value Ether to attach to the call.
    /// @return resultData The data returned by the call.
    function executeCall(
        address payable target,
        bytes calldata callData,
        uint256 value
    ) external payable override onlyOwner returns (bytes memory resultData) {
        bool success;
        (success, resultData) = target.call{value: value}(callData);
        if (!success) {
            LibWalletRichErrors
                .WalletExecuteCallFailedError(address(this), target, callData, value, resultData)
                .rrevert();
        }
    }

    /// @dev Execute an arbitrary delegatecall, in the context of this puppet.
    ///      Only an authority can call this.
    /// @param target The call target.
    /// @param callData The call data.
    /// @return resultData The data returned by the call.
    function executeDelegateCall(
        address payable target,
        bytes calldata callData
    ) external payable override onlyOwner returns (bytes memory resultData) {
        bool success;
        (success, resultData) = target.delegatecall(callData);
        if (!success) {
            LibWalletRichErrors
                .WalletExecuteDelegateCallFailedError(address(this), target, callData, resultData)
                .rrevert();
        }
    }

    /// @dev Allows this contract to receive ether.
    receive() external payable override {}

    /// @dev Signal support for receiving ERC1155 tokens.
    /// @param interfaceID The interface ID, as per ERC-165 rules.
    /// @return hasSupport `true` if this contract supports an ERC-165 interface.
    function supportsInterface(bytes4 interfaceID) external pure returns (bool hasSupport) {
        return
            interfaceID == this.supportsInterface.selector ||
            interfaceID == this.onERC1155Received.selector ^ this.onERC1155BatchReceived.selector ||
            interfaceID == this.tokenFallback.selector;
    }

    ///  @dev Allow this contract to receive ERC1155 tokens.
    ///  @return success  `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    function onERC1155Received(
        address, // operator,
        address, // from,
        uint256, // id,
        uint256, // value,
        bytes calldata //data
    ) external pure returns (bytes4 success) {
        return this.onERC1155Received.selector;
    }

    ///  @dev Allow this contract to receive ERC1155 tokens.
    ///  @return success  `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    function onERC1155BatchReceived(
        address, // operator,
        address, // from,
        uint256[] calldata, // ids,
        uint256[] calldata, // values,
        bytes calldata // data
    ) external pure returns (bytes4 success) {
        return this.onERC1155BatchReceived.selector;
    }

    /// @dev Allows this contract to receive ERC223 tokens.
    function tokenFallback(
        address, // from,
        uint256, // value,
        bytes calldata // value
    ) external pure {}
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/interfaces/IOwnableV06.sol";

/// @dev A contract that can execute arbitrary calls from its owner.
interface IFlashWallet {
    /// @dev Execute an arbitrary call. Only an authority can call this.
    /// @param target The call target.
    /// @param callData The call data.
    /// @param value Ether to attach to the call.
    /// @return resultData The data returned by the call.
    function executeCall(
        address payable target,
        bytes calldata callData,
        uint256 value
    ) external payable returns (bytes memory resultData);

    /// @dev Execute an arbitrary delegatecall, in the context of this puppet.
    ///      Only an authority can call this.
    /// @param target The call target.
    /// @param callData The call data.
    /// @return resultData The data returned by the call.
    function executeDelegateCall(
        address payable target,
        bytes calldata callData
    ) external payable returns (bytes memory resultData);

    /// @dev Allows the puppet to receive ETH.
    receive() external payable;

    /// @dev Fetch the immutable owner/deployer of this contract.
    /// @return owner_ The immutable owner/deployer/
    function owner() external view returns (address owner_);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "../vendor/ILiquidityProvider.sol";

interface ILiquidityProviderSandbox {
    /// @dev Calls `sellTokenForToken` on the given `provider` contract to
    ///      trigger a trade.
    /// @param provider The address of the on-chain liquidity provider.
    /// @param inputToken The token being sold.
    /// @param outputToken The token being bought.
    /// @param recipient The recipient of the bought tokens.
    /// @param minBuyAmount The minimum acceptable amount of `outputToken` to buy.
    /// @param auxiliaryData Auxiliary data supplied to the `provider` contract.
    function executeSellTokenForToken(
        ILiquidityProvider provider,
        IERC20TokenV06 inputToken,
        IERC20TokenV06 outputToken,
        address recipient,
        uint256 minBuyAmount,
        bytes calldata auxiliaryData
    ) external;

    /// @dev Calls `sellEthForToken` on the given `provider` contract to
    ///      trigger a trade.
    /// @param provider The address of the on-chain liquidity provider.
    /// @param outputToken The token being bought.
    /// @param recipient The recipient of the bought tokens.
    /// @param minBuyAmount The minimum acceptable amount of `outputToken` to buy.
    /// @param auxiliaryData Auxiliary data supplied to the `provider` contract.
    function executeSellEthForToken(
        ILiquidityProvider provider,
        IERC20TokenV06 outputToken,
        address recipient,
        uint256 minBuyAmount,
        bytes calldata auxiliaryData
    ) external;

    /// @dev Calls `sellTokenForEth` on the given `provider` contract to
    ///      trigger a trade.
    /// @param provider The address of the on-chain liquidity provider.
    /// @param inputToken The token being sold.
    /// @param recipient The recipient of the bought tokens.
    /// @param minBuyAmount The minimum acceptable amount of ETH to buy.
    /// @param auxiliaryData Auxiliary data supplied to the `provider` contract.
    function executeSellTokenForEth(
        ILiquidityProvider provider,
        IERC20TokenV06 inputToken,
        address recipient,
        uint256 minBuyAmount,
        bytes calldata auxiliaryData
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

/// @dev Helpers for computing `FeeCollector` contract addresses.
library LibFeeCollector {
    /// @dev Compute the CREATE2 address for a fee collector.
    /// @param controller The address of the `FeeCollectorController` contract.
    /// @param initCodeHash The init code hash of the `FeeCollector` contract.
    /// @param poolId The fee collector's pool ID.
    function getFeeCollectorAddress(
        address controller,
        bytes32 initCodeHash,
        bytes32 poolId
    ) internal pure returns (address payable feeCollectorAddress) {
        // Compute the CREATE2 address for the fee collector.
        return
            address(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            controller,
                            poolId, // pool ID is salt
                            initCodeHash
                        )
                    )
                )
            );
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-utils/contracts/src/v06/errors/LibOwnableRichErrorsV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "../vendor/ILiquidityProvider.sol";
import "../vendor/v3/IERC20Bridge.sol";
import "./ILiquidityProviderSandbox.sol";

/// @dev A permissionless contract through which the ZeroEx contract can
///      safely trigger a trade on an external `ILiquidityProvider` contract.
contract LiquidityProviderSandbox is ILiquidityProviderSandbox {
    using LibRichErrorsV06 for bytes;

    /// @dev Store the owner as an immutable.
    address public immutable owner;

    constructor(address owner_) public {
        owner = owner_;
    }

    /// @dev Allows only the (immutable) owner to call a function.
    modifier onlyOwner() virtual {
        if (msg.sender != owner) {
            LibOwnableRichErrorsV06.OnlyOwnerError(msg.sender, owner).rrevert();
        }
        _;
    }

    /// @dev Calls `sellTokenForToken` on the given `provider` contract to
    ///      trigger a trade.
    /// @param provider The address of the on-chain liquidity provider.
    /// @param inputToken The token being sold.
    /// @param outputToken The token being bought.
    /// @param recipient The recipient of the bought tokens.
    /// @param minBuyAmount The minimum acceptable amount of `outputToken` to buy.
    /// @param auxiliaryData Auxiliary data supplied to the `provider` contract.
    function executeSellTokenForToken(
        ILiquidityProvider provider,
        IERC20TokenV06 inputToken,
        IERC20TokenV06 outputToken,
        address recipient,
        uint256 minBuyAmount,
        bytes calldata auxiliaryData
    ) external override onlyOwner {
        provider.sellTokenForToken(inputToken, outputToken, recipient, minBuyAmount, auxiliaryData);
    }

    /// @dev Calls `sellEthForToken` on the given `provider` contract to
    ///      trigger a trade.
    /// @param provider The address of the on-chain liquidity provider.
    /// @param outputToken The token being bought.
    /// @param recipient The recipient of the bought tokens.
    /// @param minBuyAmount The minimum acceptable amount of `outputToken` to buy.
    /// @param auxiliaryData Auxiliary data supplied to the `provider` contract.
    function executeSellEthForToken(
        ILiquidityProvider provider,
        IERC20TokenV06 outputToken,
        address recipient,
        uint256 minBuyAmount,
        bytes calldata auxiliaryData
    ) external override onlyOwner {
        provider.sellEthForToken(outputToken, recipient, minBuyAmount, auxiliaryData);
    }

    /// @dev Calls `sellTokenForEth` on the given `provider` contract to
    ///      trigger a trade.
    /// @param provider The address of the on-chain liquidity provider.
    /// @param inputToken The token being sold.
    /// @param recipient The recipient of the bought tokens.
    /// @param minBuyAmount The minimum acceptable amount of ETH to buy.
    /// @param auxiliaryData Auxiliary data supplied to the `provider` contract.
    function executeSellTokenForEth(
        ILiquidityProvider provider,
        IERC20TokenV06 inputToken,
        address recipient,
        uint256 minBuyAmount,
        bytes calldata auxiliaryData
    ) external override onlyOwner {
        provider.sellTokenForEth(inputToken, payable(recipient), minBuyAmount, auxiliaryData);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/AuthorizableV06.sol";

/// @dev A contract with a `die()` function.
interface IKillable {
    function die(address payable ethRecipient) external;
}

/// @dev Deployer contract for ERC20 transformers.
///      Only authorities may call `deploy()` and `kill()`.
contract TransformerDeployer is AuthorizableV06 {
    /// @dev Emitted when a contract is deployed via `deploy()`.
    /// @param deployedAddress The address of the deployed contract.
    /// @param nonce The deployment nonce.
    /// @param sender The caller of `deploy()`.
    event Deployed(address deployedAddress, uint256 nonce, address sender);
    /// @dev Emitted when a contract is killed via `kill()`.
    /// @param target The address of the contract being killed..
    /// @param sender The caller of `kill()`.
    event Killed(address target, address sender);

    // @dev The current nonce of this contract.
    uint256 public nonce = 1;
    // @dev Mapping of deployed contract address to deployment nonce.
    mapping(address => uint256) public toDeploymentNonce;

    /// @dev Create this contract and register authorities.
    constructor(address[] memory initialAuthorities) public {
        for (uint256 i = 0; i < initialAuthorities.length; ++i) {
            _addAuthorizedAddress(initialAuthorities[i]);
        }
    }

    /// @dev Deploy a new contract. Only callable by an authority.
    ///      Any attached ETH will also be forwarded.
    function deploy(bytes memory bytecode) public payable onlyAuthorized returns (address deployedAddress) {
        uint256 deploymentNonce = nonce;
        nonce += 1;
        assembly {
            deployedAddress := create(callvalue(), add(bytecode, 32), mload(bytecode))
        }
        require(deployedAddress != address(0), "TransformerDeployer/DEPLOY_FAILED");
        toDeploymentNonce[deployedAddress] = deploymentNonce;
        emit Deployed(deployedAddress, deploymentNonce, msg.sender);
    }

    /// @dev Call `die()` on a contract. Only callable by an authority.
    /// @param target The target contract to call `die()` on.
    /// @param ethRecipient The Recipient of any ETH locked in `target`.
    function kill(IKillable target, address payable ethRecipient) public onlyAuthorized {
        target.die(ethRecipient);
        emit Killed(address(target), msg.sender);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibMathV06.sol";
import "../errors/LibNativeOrdersRichErrors.sol";
import "../fixins/FixinCommon.sol";
import "../fixins/FixinEIP712.sol";
import "../migrations/LibMigrate.sol";
import "./interfaces/IFeature.sol";
import "./interfaces/IBatchFillNativeOrdersFeature.sol";
import "./interfaces/INativeOrdersFeature.sol";
import "./libs/LibNativeOrder.sol";
import "./libs/LibSignature.sol";

/// @dev Feature for batch/market filling limit and RFQ orders.
contract BatchFillNativeOrdersFeature is IFeature, IBatchFillNativeOrdersFeature, FixinCommon, FixinEIP712 {
    using LibSafeMathV06 for uint128;
    using LibSafeMathV06 for uint256;
    using LibRichErrorsV06 for bytes;

    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "BatchFill";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 1, 0);

    constructor(address zeroExAddress) public FixinEIP712(zeroExAddress) {}

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external returns (bytes4 success) {
        _registerFeatureFunction(this.batchFillLimitOrders.selector);
        _registerFeatureFunction(this.batchFillRfqOrders.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @dev Fills multiple limit orders.
    /// @param orders Array of limit orders.
    /// @param signatures Array of signatures corresponding to each order.
    /// @param takerTokenFillAmounts Array of desired amounts to fill each order.
    /// @param revertIfIncomplete If true, reverts if this function fails to
    ///        fill the full fill amount for any individual order.
    /// @return takerTokenFilledAmounts Array of amounts filled, in taker token.
    /// @return makerTokenFilledAmounts Array of amounts filled, in maker token.
    function batchFillLimitOrders(
        LibNativeOrder.LimitOrder[] calldata orders,
        LibSignature.Signature[] calldata signatures,
        uint128[] calldata takerTokenFillAmounts,
        bool revertIfIncomplete
    )
        external
        payable
        override
        returns (uint128[] memory takerTokenFilledAmounts, uint128[] memory makerTokenFilledAmounts)
    {
        require(
            orders.length == signatures.length && orders.length == takerTokenFillAmounts.length,
            "BatchFillNativeOrdersFeature::batchFillLimitOrders/MISMATCHED_ARRAY_LENGTHS"
        );
        takerTokenFilledAmounts = new uint128[](orders.length);
        makerTokenFilledAmounts = new uint128[](orders.length);
        uint256 protocolFee = uint256(INativeOrdersFeature(address(this)).getProtocolFeeMultiplier()).safeMul(
            tx.gasprice
        );
        uint256 ethProtocolFeePaid;
        for (uint256 i = 0; i != orders.length; i++) {
            try
                INativeOrdersFeature(address(this))._fillLimitOrder(
                    orders[i],
                    signatures[i],
                    takerTokenFillAmounts[i],
                    msg.sender,
                    msg.sender
                )
            returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount) {
                // Update amounts filled.
                (takerTokenFilledAmounts[i], makerTokenFilledAmounts[i]) = (
                    takerTokenFilledAmount,
                    makerTokenFilledAmount
                );
                ethProtocolFeePaid = ethProtocolFeePaid.safeAdd(protocolFee);
            } catch {}

            if (revertIfIncomplete && takerTokenFilledAmounts[i] < takerTokenFillAmounts[i]) {
                bytes32 orderHash = _getEIP712Hash(LibNativeOrder.getLimitOrderStructHash(orders[i]));
                // Did not fill the amount requested.
                LibNativeOrdersRichErrors
                    .BatchFillIncompleteError(orderHash, takerTokenFilledAmounts[i], takerTokenFillAmounts[i])
                    .rrevert();
            }
        }
        LibNativeOrder.refundExcessProtocolFeeToSender(ethProtocolFeePaid);
    }

    /// @dev Fills multiple RFQ orders.
    /// @param orders Array of RFQ orders.
    /// @param signatures Array of signatures corresponding to each order.
    /// @param takerTokenFillAmounts Array of desired amounts to fill each order.
    /// @param revertIfIncomplete If true, reverts if this function fails to
    ///        fill the full fill amount for any individual order.
    /// @return takerTokenFilledAmounts Array of amounts filled, in taker token.
    /// @return makerTokenFilledAmounts Array of amounts filled, in maker token.
    function batchFillRfqOrders(
        LibNativeOrder.RfqOrder[] calldata orders,
        LibSignature.Signature[] calldata signatures,
        uint128[] calldata takerTokenFillAmounts,
        bool revertIfIncomplete
    ) external override returns (uint128[] memory takerTokenFilledAmounts, uint128[] memory makerTokenFilledAmounts) {
        require(
            orders.length == signatures.length && orders.length == takerTokenFillAmounts.length,
            "BatchFillNativeOrdersFeature::batchFillRfqOrders/MISMATCHED_ARRAY_LENGTHS"
        );
        takerTokenFilledAmounts = new uint128[](orders.length);
        makerTokenFilledAmounts = new uint128[](orders.length);
        for (uint256 i = 0; i != orders.length; i++) {
            try
                INativeOrdersFeature(address(this))._fillRfqOrder(
                    orders[i],
                    signatures[i],
                    takerTokenFillAmounts[i],
                    msg.sender,
                    false,
                    msg.sender
                )
            returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount) {
                // Update amounts filled.
                (takerTokenFilledAmounts[i], makerTokenFilledAmounts[i]) = (
                    takerTokenFilledAmount,
                    makerTokenFilledAmount
                );
            } catch {}

            if (revertIfIncomplete && takerTokenFilledAmounts[i] < takerTokenFillAmounts[i]) {
                // Did not fill the amount requested.
                bytes32 orderHash = _getEIP712Hash(LibNativeOrder.getRfqOrderStructHash(orders[i]));
                LibNativeOrdersRichErrors
                    .BatchFillIncompleteError(orderHash, takerTokenFilledAmounts[i], takerTokenFillAmounts[i])
                    .rrevert();
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "../migrations/LibBootstrap.sol";
import "../storage/LibProxyStorage.sol";
import "./interfaces/IBootstrapFeature.sol";


/// @dev Detachable `bootstrap()` feature.
contract BootstrapFeature is
    IBootstrapFeature
{
    // solhint-disable state-visibility,indent
    /// @dev The ZeroEx contract.
    ///      This has to be immutable to persist across delegatecalls.
    address immutable private _deployer;
    /// @dev The implementation address of this contract.
    ///      This has to be immutable to persist across delegatecalls.
    address immutable private _implementation;
    /// @dev The deployer.
    ///      This has to be immutable to persist across delegatecalls.
    address immutable private _bootstrapCaller;
    // solhint-enable state-visibility,indent

    using LibRichErrorsV06 for bytes;

    /// @dev Construct this contract and set the bootstrap migration contract.
    ///      After constructing this contract, `bootstrap()` should be called
    ///      to seed the initial feature set.
    /// @param bootstrapCaller The allowed caller of `bootstrap()`.
    constructor(address bootstrapCaller) public {
        _deployer = msg.sender;
        _implementation = address(this);
        _bootstrapCaller = bootstrapCaller;
    }

    /// @dev Bootstrap the initial feature set of this contract by delegatecalling
    ///      into `target`. Before exiting the `bootstrap()` function will
    ///      deregister itself from the proxy to prevent being called again.
    /// @param target The bootstrapper contract address.
    /// @param callData The call data to execute on `target`.
    function bootstrap(address target, bytes calldata callData) external override {
        // Only the bootstrap caller can call this function.
        if (msg.sender != _bootstrapCaller) {
            LibProxyRichErrors.InvalidBootstrapCallerError(
                msg.sender,
                _bootstrapCaller
            ).rrevert();
        }
        // Deregister.
        LibProxyStorage.getStorage().impls[this.bootstrap.selector] = address(0);
        // Self-destruct.
        BootstrapFeature(_implementation).die();
        // Call the bootstrapper.
        LibBootstrap.delegatecallBootstrapFunction(target, callData);
    }

    /// @dev Self-destructs this contract.
    ///      Can only be called by the deployer.
    function die() external {
        assert(address(this) == _implementation);
        if (msg.sender != _deployer) {
            LibProxyRichErrors.InvalidDieCallerError(msg.sender, _deployer).rrevert();
        }
        selfdestruct(msg.sender);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6;
pragma experimental ABIEncoderV2;

import "../fixins/FixinCommon.sol";
import "./interfaces/IFeature.sol";

/// @dev Implements the ERC165 `supportsInterface` function
contract ERC165Feature is IFeature, FixinCommon {
    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "ERC165";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 0);

    /// @dev Indicates whether the 0x Exchange Proxy implements a particular
    ///      ERC165 interface. This function should use at most 30,000 gas.
    /// @param interfaceId The interface identifier, as specified in ERC165.
    /// @return isSupported Whether the given interface is supported by the
    ///         0x Exchange Proxy.
    function supportInterface(bytes4 interfaceId) external pure returns (bool isSupported) {
        return
            interfaceId == 0x01ffc9a7 || // ERC-165 support
            interfaceId == 0x150b7a02 || // ERC-721 `ERC721TokenReceiver` support
            interfaceId == 0x4e2312e0; // ERC-1155 `ERC1155TokenReceiver` support
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "../migrations/LibMigrate.sol";
import "../fixins/FixinCommon.sol";
import "./interfaces/IFeature.sol";
import "./interfaces/IFundRecoveryFeature.sol";
import "../transformers/LibERC20Transformer.sol";

contract FundRecoveryFeature is IFeature, IFundRecoveryFeature, FixinCommon {
    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "FundRecoveryFeature";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 0);

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external returns (bytes4 success) {
        _registerFeatureFunction(this.transferTrappedTokensTo.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @dev Recovers ERC20 tokens or ETH from the 0x Exchange Proxy contract
    /// @param erc20 ERC20 Token Address. (You can also pass in `0xeeeee...` to indicate ETH)
    /// @param amountOut Amount of tokens to withdraw.
    /// @param recipientWallet Recipient wallet address.
    function transferTrappedTokensTo(
        IERC20TokenV06 erc20,
        uint256 amountOut,
        address payable recipientWallet
    ) external override onlyOwner {
        if (amountOut == uint256(-1)) {
            amountOut = LibERC20Transformer.getTokenBalanceOf(erc20, address(this));
        }
        LibERC20Transformer.transformerTransfer(erc20, recipientWallet, amountOut);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "../libs/LibNativeOrder.sol";
import "../libs/LibSignature.sol";

/// @dev Feature for batch/market filling limit and RFQ orders.
interface IBatchFillNativeOrdersFeature {
    /// @dev Fills multiple limit orders.
    /// @param orders Array of limit orders.
    /// @param signatures Array of signatures corresponding to each order.
    /// @param takerTokenFillAmounts Array of desired amounts to fill each order.
    /// @param revertIfIncomplete If true, reverts if this function fails to
    ///        fill the full fill amount for any individual order.
    /// @return takerTokenFilledAmounts Array of amounts filled, in taker token.
    /// @return makerTokenFilledAmounts Array of amounts filled, in maker token.
    function batchFillLimitOrders(
        LibNativeOrder.LimitOrder[] calldata orders,
        LibSignature.Signature[] calldata signatures,
        uint128[] calldata takerTokenFillAmounts,
        bool revertIfIncomplete
    ) external payable returns (uint128[] memory takerTokenFilledAmounts, uint128[] memory makerTokenFilledAmounts);

    /// @dev Fills multiple RFQ orders.
    /// @param orders Array of RFQ orders.
    /// @param signatures Array of signatures corresponding to each order.
    /// @param takerTokenFillAmounts Array of desired amounts to fill each order.
    /// @param revertIfIncomplete If true, reverts if this function fails to
    ///        fill the full fill amount for any individual order.
    /// @return takerTokenFilledAmounts Array of amounts filled, in taker token.
    /// @return makerTokenFilledAmounts Array of amounts filled, in maker token.
    function batchFillRfqOrders(
        LibNativeOrder.RfqOrder[] calldata orders,
        LibSignature.Signature[] calldata signatures,
        uint128[] calldata takerTokenFillAmounts,
        bool revertIfIncomplete
    ) external returns (uint128[] memory takerTokenFilledAmounts, uint128[] memory makerTokenFilledAmounts);
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;


/// @dev Detachable `bootstrap()` feature.
interface IBootstrapFeature {

    /// @dev Bootstrap the initial feature set of this contract by delegatecalling
    ///      into `target`. Before exiting the `bootstrap()` function will
    ///      deregister itself from the proxy to prevent being called again.
    /// @param target The bootstrapper contract address.
    /// @param callData The call data to execute on `target`.
    function bootstrap(address target, bytes calldata callData) external;
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "../libs/LibNFTOrder.sol";
import "../libs/LibSignature.sol";
import "../../vendor/IERC1155Token.sol";

/// @dev Feature for interacting with ERC1155 orders.
interface IERC1155OrdersFeature {
    /// @dev Emitted whenever an `ERC1155Order` is filled.
    /// @param direction Whether the order is selling or
    ///        buying the ERC1155 token.
    /// @param maker The maker of the order.
    /// @param taker The taker of the order.
    /// @param nonce The unique maker nonce in the order.
    /// @param erc20Token The address of the ERC20 token.
    /// @param erc20FillAmount The amount of ERC20 token filled.
    /// @param erc1155Token The address of the ERC1155 token.
    /// @param erc1155TokenId The ID of the ERC1155 asset.
    /// @param erc1155FillAmount The amount of ERC1155 asset filled.
    /// @param matcher Currently unused.
    event ERC1155OrderFilled(
        LibNFTOrder.TradeDirection direction,
        address maker,
        address taker,
        uint256 nonce,
        IERC20TokenV06 erc20Token,
        uint256 erc20FillAmount,
        IERC1155Token erc1155Token,
        uint256 erc1155TokenId,
        uint128 erc1155FillAmount,
        address matcher
    );

    /// @dev Emitted whenever an `ERC1155Order` is cancelled.
    /// @param maker The maker of the order.
    /// @param nonce The nonce of the order that was cancelled.
    event ERC1155OrderCancelled(address maker, uint256 nonce);

    /// @dev Emitted when an `ERC1155Order` is pre-signed.
    ///      Contains all the fields of the order.
    event ERC1155OrderPreSigned(
        LibNFTOrder.TradeDirection direction,
        address maker,
        address taker,
        uint256 expiry,
        uint256 nonce,
        IERC20TokenV06 erc20Token,
        uint256 erc20TokenAmount,
        LibNFTOrder.Fee[] fees,
        IERC1155Token erc1155Token,
        uint256 erc1155TokenId,
        LibNFTOrder.Property[] erc1155TokenProperties,
        uint128 erc1155TokenAmount
    );

    /// @dev Sells an ERC1155 asset to fill the given order.
    /// @param buyOrder The ERC1155 buy order.
    /// @param signature The order signature from the maker.
    /// @param erc1155TokenId The ID of the ERC1155 asset being
    ///        sold. If the given order specifies properties,
    ///        the asset must satisfy those properties. Otherwise,
    ///        it must equal the tokenId in the order.
    /// @param erc1155SellAmount The amount of the ERC1155 asset
    ///        to sell.
    /// @param unwrapNativeToken If this parameter is true and the
    ///        ERC20 token of the order is e.g. WETH, unwraps the
    ///        token before transferring it to the taker.
    /// @param callbackData If this parameter is non-zero, invokes
    ///        `zeroExERC1155OrderCallback` on `msg.sender` after
    ///        the ERC20 tokens have been transferred to `msg.sender`
    ///        but before transferring the ERC1155 asset to the buyer.
    function sellERC1155(
        LibNFTOrder.ERC1155Order calldata buyOrder,
        LibSignature.Signature calldata signature,
        uint256 erc1155TokenId,
        uint128 erc1155SellAmount,
        bool unwrapNativeToken,
        bytes calldata callbackData
    ) external;

    /// @dev Buys an ERC1155 asset by filling the given order.
    /// @param sellOrder The ERC1155 sell order.
    /// @param signature The order signature.
    /// @param erc1155BuyAmount The amount of the ERC1155 asset
    ///        to buy.
    /// @param callbackData If this parameter is non-zero, invokes
    ///        `zeroExERC1155OrderCallback` on `msg.sender` after
    ///        the ERC1155 asset has been transferred to `msg.sender`
    ///        but before transferring the ERC20 tokens to the seller.
    ///        Native tokens acquired during the callback can be used
    ///        to fill the order.
    function buyERC1155(
        LibNFTOrder.ERC1155Order calldata sellOrder,
        LibSignature.Signature calldata signature,
        uint128 erc1155BuyAmount,
        bytes calldata callbackData
    ) external payable;

    /// @dev Cancel a single ERC1155 order by its nonce. The caller
    ///      should be the maker of the order. Silently succeeds if
    ///      an order with the same nonce has already been filled or
    ///      cancelled.
    /// @param orderNonce The order nonce.
    function cancelERC1155Order(uint256 orderNonce) external;

    /// @dev Cancel multiple ERC1155 orders by their nonces. The caller
    ///      should be the maker of the orders. Silently succeeds if
    ///      an order with the same nonce has already been filled or
    ///      cancelled.
    /// @param orderNonces The order nonces.
    function batchCancelERC1155Orders(uint256[] calldata orderNonces) external;

    /// @dev Buys multiple ERC1155 assets by filling the
    ///      given orders.
    /// @param sellOrders The ERC1155 sell orders.
    /// @param signatures The order signatures.
    /// @param erc1155TokenAmounts The amounts of the ERC1155 assets
    ///        to buy for each order.
    /// @param callbackData The data (if any) to pass to the taker
    ///        callback for each order. Refer to the `callbackData`
    ///        parameter to for `buyERC1155`.
    /// @param revertIfIncomplete If true, reverts if this
    ///        function fails to fill any individual order.
    /// @return successes An array of booleans corresponding to whether
    ///         each order in `orders` was successfully filled.
    function batchBuyERC1155s(
        LibNFTOrder.ERC1155Order[] calldata sellOrders,
        LibSignature.Signature[] calldata signatures,
        uint128[] calldata erc1155TokenAmounts,
        bytes[] calldata callbackData,
        bool revertIfIncomplete
    ) external payable returns (bool[] memory successes);

    /// @dev Callback for the ERC1155 `safeTransferFrom` function.
    ///      This callback can be used to sell an ERC1155 asset if
    ///      a valid ERC1155 order, signature and `unwrapNativeToken`
    ///      are encoded in `data`. This allows takers to sell their
    ///      ERC1155 asset without first calling `setApprovalForAll`.
    /// @param operator The address which called `safeTransferFrom`.
    /// @param from The address which previously owned the token.
    /// @param tokenId The ID of the asset being transferred.
    /// @param value The amount being transferred.
    /// @param data Additional data with no specified format. If a
    ///        valid ERC1155 order, signature and `unwrapNativeToken`
    ///        are encoded in `data`, this function will try to fill
    ///        the order using the received asset.
    /// @return success The selector of this function (0xf23a6e61),
    ///         indicating that the callback succeeded.
    function onERC1155Received(
        address operator,
        address from,
        uint256 tokenId,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4 success);

    /// @dev Approves an ERC1155 order on-chain. After pre-signing
    ///      the order, the `PRESIGNED` signature type will become
    ///      valid for that order and signer.
    /// @param order An ERC1155 order.
    function preSignERC1155Order(LibNFTOrder.ERC1155Order calldata order) external;

    /// @dev Checks whether the given signature is valid for the
    ///      the given ERC1155 order. Reverts if not.
    /// @param order The ERC1155 order.
    /// @param signature The signature to validate.
    function validateERC1155OrderSignature(
        LibNFTOrder.ERC1155Order calldata order,
        LibSignature.Signature calldata signature
    ) external view;

    /// @dev If the given order is buying an ERC1155 asset, checks
    ///      whether or not the given token ID satisfies the required
    ///      properties specified in the order. If the order does not
    ///      specify any properties, this function instead checks
    ///      whether the given token ID matches the ID in the order.
    ///      Reverts if any checks fail, or if the order is selling
    ///      an ERC1155 asset.
    /// @param order The ERC1155 order.
    /// @param erc1155TokenId The ID of the ERC1155 asset.
    function validateERC1155OrderProperties(
        LibNFTOrder.ERC1155Order calldata order,
        uint256 erc1155TokenId
    ) external view;

    /// @dev Get the order info for an ERC1155 order.
    /// @param order The ERC1155 order.
    /// @return orderInfo Infor about the order.
    function getERC1155OrderInfo(
        LibNFTOrder.ERC1155Order calldata order
    ) external view returns (LibNFTOrder.OrderInfo memory orderInfo);

    /// @dev Get the EIP-712 hash of an ERC1155 order.
    /// @param order The ERC1155 order.
    /// @return orderHash The order hash.
    function getERC1155OrderHash(LibNFTOrder.ERC1155Order calldata order) external view returns (bytes32 orderHash);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6;
pragma experimental ABIEncoderV2;

/// @dev Implements the ERC165 `supportsInterface` function
interface IERC165Feature {
    /// @dev Indicates whether the 0x Exchange Proxy implements a particular
    ///      ERC165 interface. This function should use at most 30,000 gas.
    /// @param interfaceId The interface identifier, as specified in ERC165.
    /// @return isSupported Whether the given interface is supported by the
    ///         0x Exchange Proxy.
    function supportInterface(bytes4 interfaceId) external pure returns (bool isSupported);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "../libs/LibNFTOrder.sol";
import "../libs/LibSignature.sol";
import "../../vendor/IERC721Token.sol";

/// @dev Feature for interacting with ERC721 orders.
interface IERC721OrdersFeature {
    /// @dev Emitted whenever an `ERC721Order` is filled.
    /// @param direction Whether the order is selling or
    ///        buying the ERC721 token.
    /// @param maker The maker of the order.
    /// @param taker The taker of the order.
    /// @param nonce The unique maker nonce in the order.
    /// @param erc20Token The address of the ERC20 token.
    /// @param erc20TokenAmount The amount of ERC20 token
    ///        to sell or buy.
    /// @param erc721Token The address of the ERC721 token.
    /// @param erc721TokenId The ID of the ERC721 asset.
    /// @param matcher If this order was matched with another using `matchERC721Orders()`,
    ///                this will be the address of the caller. If not, this will be `address(0)`.
    event ERC721OrderFilled(
        LibNFTOrder.TradeDirection direction,
        address maker,
        address taker,
        uint256 nonce,
        IERC20TokenV06 erc20Token,
        uint256 erc20TokenAmount,
        IERC721Token erc721Token,
        uint256 erc721TokenId,
        address matcher
    );

    /// @dev Emitted whenever an `ERC721Order` is cancelled.
    /// @param maker The maker of the order.
    /// @param nonce The nonce of the order that was cancelled.
    event ERC721OrderCancelled(address maker, uint256 nonce);

    /// @dev Emitted when an `ERC721Order` is pre-signed.
    ///      Contains all the fields of the order.
    event ERC721OrderPreSigned(
        LibNFTOrder.TradeDirection direction,
        address maker,
        address taker,
        uint256 expiry,
        uint256 nonce,
        IERC20TokenV06 erc20Token,
        uint256 erc20TokenAmount,
        LibNFTOrder.Fee[] fees,
        IERC721Token erc721Token,
        uint256 erc721TokenId,
        LibNFTOrder.Property[] erc721TokenProperties
    );

    /// @dev Sells an ERC721 asset to fill the given order.
    /// @param buyOrder The ERC721 buy order.
    /// @param signature The order signature from the maker.
    /// @param erc721TokenId The ID of the ERC721 asset being
    ///        sold. If the given order specifies properties,
    ///        the asset must satisfy those properties. Otherwise,
    ///        it must equal the tokenId in the order.
    /// @param unwrapNativeToken If this parameter is true and the
    ///        ERC20 token of the order is e.g. WETH, unwraps the
    ///        token before transferring it to the taker.
    /// @param callbackData If this parameter is non-zero, invokes
    ///        `zeroExERC721OrderCallback` on `msg.sender` after
    ///        the ERC20 tokens have been transferred to `msg.sender`
    ///        but before transferring the ERC721 asset to the buyer.
    function sellERC721(
        LibNFTOrder.ERC721Order calldata buyOrder,
        LibSignature.Signature calldata signature,
        uint256 erc721TokenId,
        bool unwrapNativeToken,
        bytes calldata callbackData
    ) external;

    /// @dev Buys an ERC721 asset by filling the given order.
    /// @param sellOrder The ERC721 sell order.
    /// @param signature The order signature.
    /// @param callbackData If this parameter is non-zero, invokes
    ///        `zeroExERC721OrderCallback` on `msg.sender` after
    ///        the ERC721 asset has been transferred to `msg.sender`
    ///        but before transferring the ERC20 tokens to the seller.
    ///        Native tokens acquired during the callback can be used
    ///        to fill the order.
    function buyERC721(
        LibNFTOrder.ERC721Order calldata sellOrder,
        LibSignature.Signature calldata signature,
        bytes calldata callbackData
    ) external payable;

    /// @dev Cancel a single ERC721 order by its nonce. The caller
    ///      should be the maker of the order. Silently succeeds if
    ///      an order with the same nonce has already been filled or
    ///      cancelled.
    /// @param orderNonce The order nonce.
    function cancelERC721Order(uint256 orderNonce) external;

    /// @dev Cancel multiple ERC721 orders by their nonces. The caller
    ///      should be the maker of the orders. Silently succeeds if
    ///      an order with the same nonce has already been filled or
    ///      cancelled.
    /// @param orderNonces The order nonces.
    function batchCancelERC721Orders(uint256[] calldata orderNonces) external;

    /// @dev Buys multiple ERC721 assets by filling the
    ///      given orders.
    /// @param sellOrders The ERC721 sell orders.
    /// @param signatures The order signatures.
    /// @param callbackData The data (if any) to pass to the taker
    ///        callback for each order. Refer to the `callbackData`
    ///        parameter to for `buyERC721`.
    /// @param revertIfIncomplete If true, reverts if this
    ///        function fails to fill any individual order.
    /// @return successes An array of booleans corresponding to whether
    ///         each order in `orders` was successfully filled.
    function batchBuyERC721s(
        LibNFTOrder.ERC721Order[] calldata sellOrders,
        LibSignature.Signature[] calldata signatures,
        bytes[] calldata callbackData,
        bool revertIfIncomplete
    ) external payable returns (bool[] memory successes);

    /// @dev Matches a pair of complementary orders that have
    ///      a non-negative spread. Each order is filled at
    ///      their respective price, and the matcher receives
    ///      a profit denominated in the ERC20 token.
    /// @param sellOrder Order selling an ERC721 asset.
    /// @param buyOrder Order buying an ERC721 asset.
    /// @param sellOrderSignature Signature for the sell order.
    /// @param buyOrderSignature Signature for the buy order.
    /// @return profit The amount of profit earned by the caller
    ///         of this function (denominated in the ERC20 token
    ///         of the matched orders).
    function matchERC721Orders(
        LibNFTOrder.ERC721Order calldata sellOrder,
        LibNFTOrder.ERC721Order calldata buyOrder,
        LibSignature.Signature calldata sellOrderSignature,
        LibSignature.Signature calldata buyOrderSignature
    ) external returns (uint256 profit);

    /// @dev Matches pairs of complementary orders that have
    ///      non-negative spreads. Each order is filled at
    ///      their respective price, and the matcher receives
    ///      a profit denominated in the ERC20 token.
    /// @param sellOrders Orders selling ERC721 assets.
    /// @param buyOrders Orders buying ERC721 assets.
    /// @param sellOrderSignatures Signatures for the sell orders.
    /// @param buyOrderSignatures Signatures for the buy orders.
    /// @return profits The amount of profit earned by the caller
    ///         of this function for each pair of matched orders
    ///         (denominated in the ERC20 token of the order pair).
    /// @return successes An array of booleans corresponding to
    ///         whether each pair of orders was successfully matched.
    function batchMatchERC721Orders(
        LibNFTOrder.ERC721Order[] calldata sellOrders,
        LibNFTOrder.ERC721Order[] calldata buyOrders,
        LibSignature.Signature[] calldata sellOrderSignatures,
        LibSignature.Signature[] calldata buyOrderSignatures
    ) external returns (uint256[] memory profits, bool[] memory successes);

    /// @dev Callback for the ERC721 `safeTransferFrom` function.
    ///      This callback can be used to sell an ERC721 asset if
    ///      a valid ERC721 order, signature and `unwrapNativeToken`
    ///      are encoded in `data`. This allows takers to sell their
    ///      ERC721 asset without first calling `setApprovalForAll`.
    /// @param operator The address which called `safeTransferFrom`.
    /// @param from The address which previously owned the token.
    /// @param tokenId The ID of the asset being transferred.
    /// @param data Additional data with no specified format. If a
    ///        valid ERC721 order, signature and `unwrapNativeToken`
    ///        are encoded in `data`, this function will try to fill
    ///        the order using the received asset.
    /// @return success The selector of this function (0x150b7a02),
    ///         indicating that the callback succeeded.
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4 success);

    /// @dev Approves an ERC721 order on-chain. After pre-signing
    ///      the order, the `PRESIGNED` signature type will become
    ///      valid for that order and signer.
    /// @param order An ERC721 order.
    function preSignERC721Order(LibNFTOrder.ERC721Order calldata order) external;

    /// @dev Checks whether the given signature is valid for the
    ///      the given ERC721 order. Reverts if not.
    /// @param order The ERC721 order.
    /// @param signature The signature to validate.
    function validateERC721OrderSignature(
        LibNFTOrder.ERC721Order calldata order,
        LibSignature.Signature calldata signature
    ) external view;

    /// @dev If the given order is buying an ERC721 asset, checks
    ///      whether or not the given token ID satisfies the required
    ///      properties specified in the order. If the order does not
    ///      specify any properties, this function instead checks
    ///      whether the given token ID matches the ID in the order.
    ///      Reverts if any checks fail, or if the order is selling
    ///      an ERC721 asset.
    /// @param order The ERC721 order.
    /// @param erc721TokenId The ID of the ERC721 asset.
    function validateERC721OrderProperties(LibNFTOrder.ERC721Order calldata order, uint256 erc721TokenId) external view;

    /// @dev Get the current status of an ERC721 order.
    /// @param order The ERC721 order.
    /// @return status The status of the order.
    function getERC721OrderStatus(
        LibNFTOrder.ERC721Order calldata order
    ) external view returns (LibNFTOrder.OrderStatus status);

    /// @dev Get the EIP-712 hash of an ERC721 order.
    /// @param order The ERC721 order.
    /// @return orderHash The order hash.
    function getERC721OrderHash(LibNFTOrder.ERC721Order calldata order) external view returns (bytes32 orderHash);

    /// @dev Get the order status bit vector for the given
    ///      maker address and nonce range.
    /// @param maker The maker of the order.
    /// @param nonceRange Order status bit vectors are indexed
    ///        by maker address and the upper 248 bits of the
    ///        order nonce. We define `nonceRange` to be these
    ///        248 bits.
    /// @return bitVector The order status bit vector for the
    ///         given maker and nonce range.
    function getERC721OrderStatusBitVector(address maker, uint248 nonceRange) external view returns (uint256 bitVector);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

/// @dev Basic interface for a feature contract.
interface IFeature {
    /// @dev The name of this feature set.
    function FEATURE_NAME() external view returns (string memory name);

    /// @dev The version of this feature set.
    function FEATURE_VERSION() external view returns (uint256 version);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";

/// @dev Exchange Proxy Recovery Functions
interface IFundRecoveryFeature {
    /// @dev calledFrom FundRecoveryFeature.transferTrappedTokensTo() This will be delegatecalled
    /// in the context of the Exchange Proxy instance being used.
    /// @param erc20 ERC20 Token Address.
    /// @param amountOut Amount of tokens to withdraw.
    /// @param recipientWallet Recipient wallet address.
    function transferTrappedTokensTo(IERC20TokenV06 erc20, uint256 amountOut, address payable recipientWallet) external;
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "../../vendor/ILiquidityProvider.sol";

/// @dev Feature to swap directly with an on-chain liquidity provider.
interface ILiquidityProviderFeature {
    /// @dev Event for data pipeline.
    event LiquidityProviderSwap(
        IERC20TokenV06 inputToken,
        IERC20TokenV06 outputToken,
        uint256 inputTokenAmount,
        uint256 outputTokenAmount,
        ILiquidityProvider provider,
        address recipient
    );

    /// @dev Sells `sellAmount` of `inputToken` to the liquidity provider
    ///      at the given `provider` address.
    /// @param inputToken The token being sold.
    /// @param outputToken The token being bought.
    /// @param provider The address of the on-chain liquidity provider
    ///        to trade with.
    /// @param recipient The recipient of the bought tokens. If equal to
    ///        address(0), `msg.sender` is assumed to be the recipient.
    /// @param sellAmount The amount of `inputToken` to sell.
    /// @param minBuyAmount The minimum acceptable amount of `outputToken` to
    ///        buy. Reverts if this amount is not satisfied.
    /// @param auxiliaryData Auxiliary data supplied to the `provider` contract.
    /// @return boughtAmount The amount of `outputToken` bought.
    function sellToLiquidityProvider(
        IERC20TokenV06 inputToken,
        IERC20TokenV06 outputToken,
        ILiquidityProvider provider,
        address recipient,
        uint256 sellAmount,
        uint256 minBuyAmount,
        bytes calldata auxiliaryData
    ) external payable returns (uint256 boughtAmount);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "../libs/LibSignature.sol";

/// @dev Meta-transactions feature.
interface IMetaTransactionsFeature {
    /// @dev Describes an exchange proxy meta transaction.
    struct MetaTransactionData {
        // Signer of meta-transaction. On whose behalf to execute the MTX.
        address payable signer;
        // Required sender, or NULL for anyone.
        address sender;
        // Minimum gas price.
        uint256 minGasPrice;
        // Maximum gas price.
        uint256 maxGasPrice;
        // MTX is invalid after this time.
        uint256 expirationTimeSeconds;
        // Nonce to make this MTX unique.
        uint256 salt;
        // Encoded call data to a function on the exchange proxy.
        bytes callData;
        // Amount of ETH to attach to the call.
        uint256 value;
        // ERC20 fee `signer` pays `sender`.
        IERC20TokenV06 feeToken;
        // ERC20 fee amount.
        uint256 feeAmount;
    }

    /// @dev Emitted whenever a meta-transaction is executed via
    ///      `executeMetaTransaction()` or `executeMetaTransactions()`.
    /// @param hash The meta-transaction hash.
    /// @param selector The selector of the function being executed.
    /// @param signer Who to execute the meta-transaction on behalf of.
    /// @param sender Who executed the meta-transaction.
    event MetaTransactionExecuted(bytes32 hash, bytes4 indexed selector, address signer, address sender);

    /// @dev Execute a single meta-transaction.
    /// @param mtx The meta-transaction.
    /// @param signature The signature by `mtx.signer`.
    /// @return returnResult The ABI-encoded result of the underlying call.
    function executeMetaTransaction(
        MetaTransactionData calldata mtx,
        LibSignature.Signature calldata signature
    ) external payable returns (bytes memory returnResult);

    /// @dev Execute multiple meta-transactions.
    /// @param mtxs The meta-transactions.
    /// @param signatures The signature by each respective `mtx.signer`.
    /// @return returnResults The ABI-encoded results of the underlying calls.
    function batchExecuteMetaTransactions(
        MetaTransactionData[] calldata mtxs,
        LibSignature.Signature[] calldata signatures
    ) external payable returns (bytes[] memory returnResults);

    /// @dev Get the block at which a meta-transaction has been executed.
    /// @param mtx The meta-transaction.
    /// @return blockNumber The block height when the meta-transactioin was executed.
    function getMetaTransactionExecutedBlock(
        MetaTransactionData calldata mtx
    ) external view returns (uint256 blockNumber);

    /// @dev Get the block at which a meta-transaction hash has been executed.
    /// @param mtxHash The meta-transaction hash.
    /// @return blockNumber The block height when the meta-transactioin was executed.
    function getMetaTransactionHashExecutedBlock(bytes32 mtxHash) external view returns (uint256 blockNumber);

    /// @dev Get the EIP712 hash of a meta-transaction.
    /// @param mtx The meta-transaction.
    /// @return mtxHash The EIP712 hash of `mtx`.
    function getMetaTransactionHash(MetaTransactionData calldata mtx) external view returns (bytes32 mtxHash);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";

interface IMultiplexFeature {
    // Identifies the type of subcall.
    enum MultiplexSubcall {
        Invalid,
        RFQ,
        OTC,
        UniswapV2,
        UniswapV3,
        LiquidityProvider,
        TransformERC20,
        BatchSell,
        MultiHopSell
    }

    // Parameters for a batch sell.
    struct BatchSellParams {
        // The token being sold.
        IERC20TokenV06 inputToken;
        // The token being bought.
        IERC20TokenV06 outputToken;
        // The amount of `inputToken` to sell.
        uint256 sellAmount;
        // The nested calls to perform.
        BatchSellSubcall[] calls;
        // Whether to use the Exchange Proxy's balance
        // of input tokens.
        bool useSelfBalance;
        // The recipient of the bought output tokens.
        address recipient;
    }

    // Represents a constituent call of a batch sell.
    struct BatchSellSubcall {
        // The function to call.
        MultiplexSubcall id;
        // Amount of input token to sell. If the highest bit is 1,
        // this value represents a proportion of the total
        // `sellAmount` of the batch sell. See `_normalizeSellAmount`
        // for details.
        uint256 sellAmount;
        // ABI-encoded parameters needed to perform the call.
        bytes data;
    }

    // Parameters for a multi-hop sell.
    struct MultiHopSellParams {
        // The sell path, i.e.
        // tokens = [inputToken, hopToken1, ..., hopTokenN, outputToken]
        address[] tokens;
        // The amount of `tokens[0]` to sell.
        uint256 sellAmount;
        // The nested calls to perform.
        MultiHopSellSubcall[] calls;
        // Whether to use the Exchange Proxy's balance
        // of input tokens.
        bool useSelfBalance;
        // The recipient of the bought output tokens.
        address recipient;
    }

    // Represents a constituent call of a multi-hop sell.
    struct MultiHopSellSubcall {
        // The function to call.
        MultiplexSubcall id;
        // ABI-encoded parameters needed to perform the call.
        bytes data;
    }

    struct BatchSellState {
        // Tracks the amount of input token sold.
        uint256 soldAmount;
        // Tracks the amount of output token bought.
        uint256 boughtAmount;
    }

    struct MultiHopSellState {
        // This variable is used for the input and output amounts of
        // each hop. After the final hop, this will contain the output
        // amount of the multi-hop sell.
        uint256 outputTokenAmount;
        // For each hop in a multi-hop sell, `from` is the
        // address that holds the input tokens of the hop,
        // `to` is the address that receives the output tokens
        // of the hop.
        // See `_computeHopTarget` for details.
        address from;
        address to;
        // The index of the current hop in the multi-hop chain.
        uint256 hopIndex;
    }

    /// @dev Sells attached ETH for `outputToken` using the provided
    ///      calls.
    /// @param outputToken The token to buy.
    /// @param calls The calls to use to sell the attached ETH.
    /// @param minBuyAmount The minimum amount of `outputToken` that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of `outputToken` bought.
    function multiplexBatchSellEthForToken(
        IERC20TokenV06 outputToken,
        BatchSellSubcall[] calldata calls,
        uint256 minBuyAmount
    ) external payable returns (uint256 boughtAmount);

    /// @dev Sells `sellAmount` of the given `inputToken` for ETH
    ///      using the provided calls.
    /// @param inputToken The token to sell.
    /// @param calls The calls to use to sell the input tokens.
    /// @param sellAmount The amount of `inputToken` to sell.
    /// @param minBuyAmount The minimum amount of ETH that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of ETH bought.
    function multiplexBatchSellTokenForEth(
        IERC20TokenV06 inputToken,
        BatchSellSubcall[] calldata calls,
        uint256 sellAmount,
        uint256 minBuyAmount
    ) external returns (uint256 boughtAmount);

    /// @dev Sells `sellAmount` of the given `inputToken` for
    ///      `outputToken` using the provided calls.
    /// @param inputToken The token to sell.
    /// @param outputToken The token to buy.
    /// @param calls The calls to use to sell the input tokens.
    /// @param sellAmount The amount of `inputToken` to sell.
    /// @param minBuyAmount The minimum amount of `outputToken`
    ///        that must be bought for this function to not revert.
    /// @return boughtAmount The amount of `outputToken` bought.
    function multiplexBatchSellTokenForToken(
        IERC20TokenV06 inputToken,
        IERC20TokenV06 outputToken,
        BatchSellSubcall[] calldata calls,
        uint256 sellAmount,
        uint256 minBuyAmount
    ) external returns (uint256 boughtAmount);

    /// @dev Sells attached ETH via the given sequence of tokens
    ///      and calls. `tokens[0]` must be WETH.
    ///      The last token in `tokens` is the output token that
    ///      will ultimately be sent to `msg.sender`
    /// @param tokens The sequence of tokens to use for the sell,
    ///        i.e. `tokens[i]` will be sold for `tokens[i+1]` via
    ///        `calls[i]`.
    /// @param calls The sequence of calls to use for the sell.
    /// @param minBuyAmount The minimum amount of output tokens that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of output tokens bought.
    function multiplexMultiHopSellEthForToken(
        address[] calldata tokens,
        MultiHopSellSubcall[] calldata calls,
        uint256 minBuyAmount
    ) external payable returns (uint256 boughtAmount);

    /// @dev Sells `sellAmount` of the input token (`tokens[0]`)
    ///      for ETH via the given sequence of tokens and calls.
    ///      The last token in `tokens` must be WETH.
    /// @param tokens The sequence of tokens to use for the sell,
    ///        i.e. `tokens[i]` will be sold for `tokens[i+1]` via
    ///        `calls[i]`.
    /// @param calls The sequence of calls to use for the sell.
    /// @param minBuyAmount The minimum amount of ETH that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of ETH bought.
    function multiplexMultiHopSellTokenForEth(
        address[] calldata tokens,
        MultiHopSellSubcall[] calldata calls,
        uint256 sellAmount,
        uint256 minBuyAmount
    ) external returns (uint256 boughtAmount);

    /// @dev Sells `sellAmount` of the input token (`tokens[0]`)
    ///      via the given sequence of tokens and calls.
    ///      The last token in `tokens` is the output token that
    ///      will ultimately be sent to `msg.sender`
    /// @param tokens The sequence of tokens to use for the sell,
    ///        i.e. `tokens[i]` will be sold for `tokens[i+1]` via
    ///        `calls[i]`.
    /// @param calls The sequence of calls to use for the sell.
    /// @param minBuyAmount The minimum amount of output tokens that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of output tokens bought.
    function multiplexMultiHopSellTokenForToken(
        address[] calldata tokens,
        MultiHopSellSubcall[] calldata calls,
        uint256 sellAmount,
        uint256 minBuyAmount
    ) external returns (uint256 boughtAmount);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "../libs/LibSignature.sol";
import "../libs/LibNativeOrder.sol";

/// @dev Events emitted by NativeOrdersFeature.
interface INativeOrdersEvents {
    /// @dev Emitted whenever a `LimitOrder` is filled.
    /// @param orderHash The canonical hash of the order.
    /// @param maker The maker of the order.
    /// @param taker The taker of the order.
    /// @param feeRecipient Fee recipient of the order.
    /// @param takerTokenFilledAmount How much taker token was filled.
    /// @param makerTokenFilledAmount How much maker token was filled.
    /// @param protocolFeePaid How much protocol fee was paid.
    /// @param pool The fee pool associated with this order.
    event LimitOrderFilled(
        bytes32 orderHash,
        address maker,
        address taker,
        address feeRecipient,
        address makerToken,
        address takerToken,
        uint128 takerTokenFilledAmount,
        uint128 makerTokenFilledAmount,
        uint128 takerTokenFeeFilledAmount,
        uint256 protocolFeePaid,
        bytes32 pool
    );

    /// @dev Emitted whenever an `RfqOrder` is filled.
    /// @param orderHash The canonical hash of the order.
    /// @param maker The maker of the order.
    /// @param taker The taker of the order.
    /// @param takerTokenFilledAmount How much taker token was filled.
    /// @param makerTokenFilledAmount How much maker token was filled.
    /// @param pool The fee pool associated with this order.
    event RfqOrderFilled(
        bytes32 orderHash,
        address maker,
        address taker,
        address makerToken,
        address takerToken,
        uint128 takerTokenFilledAmount,
        uint128 makerTokenFilledAmount,
        bytes32 pool
    );

    /// @dev Emitted whenever a limit or RFQ order is cancelled.
    /// @param orderHash The canonical hash of the order.
    /// @param maker The order maker.
    event OrderCancelled(bytes32 orderHash, address maker);

    /// @dev Emitted whenever Limit orders are cancelled by pair by a maker.
    /// @param maker The maker of the order.
    /// @param makerToken The maker token in a pair for the orders cancelled.
    /// @param takerToken The taker token in a pair for the orders cancelled.
    /// @param minValidSalt The new minimum valid salt an order with this pair must
    ///        have.
    event PairCancelledLimitOrders(address maker, address makerToken, address takerToken, uint256 minValidSalt);

    /// @dev Emitted whenever RFQ orders are cancelled by pair by a maker.
    /// @param maker The maker of the order.
    /// @param makerToken The maker token in a pair for the orders cancelled.
    /// @param takerToken The taker token in a pair for the orders cancelled.
    /// @param minValidSalt The new minimum valid salt an order with this pair must
    ///        have.
    event PairCancelledRfqOrders(address maker, address makerToken, address takerToken, uint256 minValidSalt);

    /// @dev Emitted when new addresses are allowed or disallowed to fill
    ///      orders with a given txOrigin.
    /// @param origin The address doing the allowing.
    /// @param addrs The address being allowed/disallowed.
    /// @param allowed Indicates whether the address should be allowed.
    event RfqOrderOriginsAllowed(address origin, address[] addrs, bool allowed);

    /// @dev Emitted when new order signers are registered
    /// @param maker The maker address that is registering a designated signer.
    /// @param signer The address that will sign on behalf of maker.
    /// @param allowed Indicates whether the address should be allowed.
    event OrderSignerRegistered(address maker, address signer, bool allowed);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "../libs/LibSignature.sol";
import "../libs/LibNativeOrder.sol";
import "./INativeOrdersEvents.sol";

/// @dev Feature for interacting with limit orders.
interface INativeOrdersFeature is INativeOrdersEvents {
    /// @dev Transfers protocol fees from the `FeeCollector` pools into
    ///      the staking contract.
    /// @param poolIds Staking pool IDs
    function transferProtocolFeesForPools(bytes32[] calldata poolIds) external;

    /// @dev Fill a limit order. The taker and sender will be the caller.
    /// @param order The limit order. ETH protocol fees can be
    ///      attached to this call. Any unspent ETH will be refunded to
    ///      the caller.
    /// @param signature The order signature.
    /// @param takerTokenFillAmount Maximum taker token amount to fill this order with.
    /// @return takerTokenFilledAmount How much maker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function fillLimitOrder(
        LibNativeOrder.LimitOrder calldata order,
        LibSignature.Signature calldata signature,
        uint128 takerTokenFillAmount
    ) external payable returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount);

    /// @dev Fill an RFQ order for up to `takerTokenFillAmount` taker tokens.
    ///      The taker will be the caller.
    /// @param order The RFQ order.
    /// @param signature The order signature.
    /// @param takerTokenFillAmount Maximum taker token amount to fill this order with.
    /// @return takerTokenFilledAmount How much maker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function fillRfqOrder(
        LibNativeOrder.RfqOrder calldata order,
        LibSignature.Signature calldata signature,
        uint128 takerTokenFillAmount
    ) external returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount);

    /// @dev Fill an RFQ order for exactly `takerTokenFillAmount` taker tokens.
    ///      The taker will be the caller. ETH protocol fees can be
    ///      attached to this call. Any unspent ETH will be refunded to
    ///      the caller.
    /// @param order The limit order.
    /// @param signature The order signature.
    /// @param takerTokenFillAmount How much taker token to fill this order with.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function fillOrKillLimitOrder(
        LibNativeOrder.LimitOrder calldata order,
        LibSignature.Signature calldata signature,
        uint128 takerTokenFillAmount
    ) external payable returns (uint128 makerTokenFilledAmount);

    /// @dev Fill an RFQ order for exactly `takerTokenFillAmount` taker tokens.
    ///      The taker will be the caller.
    /// @param order The RFQ order.
    /// @param signature The order signature.
    /// @param takerTokenFillAmount How much taker token to fill this order with.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function fillOrKillRfqOrder(
        LibNativeOrder.RfqOrder calldata order,
        LibSignature.Signature calldata signature,
        uint128 takerTokenFillAmount
    ) external returns (uint128 makerTokenFilledAmount);

    /// @dev Fill a limit order. Internal variant. ETH protocol fees can be
    ///      attached to this call. Any unspent ETH will be refunded to
    ///      `msg.sender` (not `sender`).
    /// @param order The limit order.
    /// @param signature The order signature.
    /// @param takerTokenFillAmount Maximum taker token to fill this order with.
    /// @param taker The order taker.
    /// @param sender The order sender.
    /// @return takerTokenFilledAmount How much maker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function _fillLimitOrder(
        LibNativeOrder.LimitOrder calldata order,
        LibSignature.Signature calldata signature,
        uint128 takerTokenFillAmount,
        address taker,
        address sender
    ) external payable returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount);

    /// @dev Fill an RFQ order. Internal variant.
    /// @param order The RFQ order.
    /// @param signature The order signature.
    /// @param takerTokenFillAmount Maximum taker token to fill this order with.
    /// @param taker The order taker.
    /// @param useSelfBalance Whether to use the ExchangeProxy's transient
    ///        balance of taker tokens to fill the order.
    /// @param recipient The recipient of the maker tokens.
    /// @return takerTokenFilledAmount How much maker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function _fillRfqOrder(
        LibNativeOrder.RfqOrder calldata order,
        LibSignature.Signature calldata signature,
        uint128 takerTokenFillAmount,
        address taker,
        bool useSelfBalance,
        address recipient
    ) external returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount);

    /// @dev Cancel a single limit order. The caller must be the maker or a valid order signer.
    ///      Silently succeeds if the order has already been cancelled.
    /// @param order The limit order.
    function cancelLimitOrder(LibNativeOrder.LimitOrder calldata order) external;

    /// @dev Cancel a single RFQ order. The caller must be the maker or a valid order signer.
    ///      Silently succeeds if the order has already been cancelled.
    /// @param order The RFQ order.
    function cancelRfqOrder(LibNativeOrder.RfqOrder calldata order) external;

    /// @dev Mark what tx.origin addresses are allowed to fill an order that
    ///      specifies the message sender as its txOrigin.
    /// @param origins An array of origin addresses to update.
    /// @param allowed True to register, false to unregister.
    function registerAllowedRfqOrigins(address[] memory origins, bool allowed) external;

    /// @dev Cancel multiple limit orders. The caller must be the maker or a valid order signer.
    ///      Silently succeeds if the order has already been cancelled.
    /// @param orders The limit orders.
    function batchCancelLimitOrders(LibNativeOrder.LimitOrder[] calldata orders) external;

    /// @dev Cancel multiple RFQ orders. The caller must be the maker or a valid order signer.
    ///      Silently succeeds if the order has already been cancelled.
    /// @param orders The RFQ orders.
    function batchCancelRfqOrders(LibNativeOrder.RfqOrder[] calldata orders) external;

    /// @dev Cancel all limit orders for a given maker and pair with a salt less
    ///      than the value provided. The caller must be the maker. Subsequent
    ///      calls to this function with the same caller and pair require the
    ///      new salt to be >= the old salt.
    /// @param makerToken The maker token.
    /// @param takerToken The taker token.
    /// @param minValidSalt The new minimum valid salt.
    function cancelPairLimitOrders(IERC20TokenV06 makerToken, IERC20TokenV06 takerToken, uint256 minValidSalt) external;

    /// @dev Cancel all limit orders for a given maker and pair with a salt less
    ///      than the value provided. The caller must be a signer registered to the maker.
    ///      Subsequent calls to this function with the same maker and pair require the
    ///      new salt to be >= the old salt.
    /// @param maker The maker for which to cancel.
    /// @param makerToken The maker token.
    /// @param takerToken The taker token.
    /// @param minValidSalt The new minimum valid salt.
    function cancelPairLimitOrdersWithSigner(
        address maker,
        IERC20TokenV06 makerToken,
        IERC20TokenV06 takerToken,
        uint256 minValidSalt
    ) external;

    /// @dev Cancel all limit orders for a given maker and pairs with salts less
    ///      than the values provided. The caller must be the maker. Subsequent
    ///      calls to this function with the same caller and pair require the
    ///      new salt to be >= the old salt.
    /// @param makerTokens The maker tokens.
    /// @param takerTokens The taker tokens.
    /// @param minValidSalts The new minimum valid salts.
    function batchCancelPairLimitOrders(
        IERC20TokenV06[] calldata makerTokens,
        IERC20TokenV06[] calldata takerTokens,
        uint256[] calldata minValidSalts
    ) external;

    /// @dev Cancel all limit orders for a given maker and pairs with salts less
    ///      than the values provided. The caller must be a signer registered to the maker.
    ///      Subsequent calls to this function with the same maker and pair require the
    ///      new salt to be >= the old salt.
    /// @param maker The maker for which to cancel.
    /// @param makerTokens The maker tokens.
    /// @param takerTokens The taker tokens.
    /// @param minValidSalts The new minimum valid salts.
    function batchCancelPairLimitOrdersWithSigner(
        address maker,
        IERC20TokenV06[] memory makerTokens,
        IERC20TokenV06[] memory takerTokens,
        uint256[] memory minValidSalts
    ) external;

    /// @dev Cancel all RFQ orders for a given maker and pair with a salt less
    ///      than the value provided. The caller must be the maker. Subsequent
    ///      calls to this function with the same caller and pair require the
    ///      new salt to be >= the old salt.
    /// @param makerToken The maker token.
    /// @param takerToken The taker token.
    /// @param minValidSalt The new minimum valid salt.
    function cancelPairRfqOrders(IERC20TokenV06 makerToken, IERC20TokenV06 takerToken, uint256 minValidSalt) external;

    /// @dev Cancel all RFQ orders for a given maker and pair with a salt less
    ///      than the value provided. The caller must be a signer registered to the maker.
    ///      Subsequent calls to this function with the same maker and pair require the
    ///      new salt to be >= the old salt.
    /// @param maker The maker for which to cancel.
    /// @param makerToken The maker token.
    /// @param takerToken The taker token.
    /// @param minValidSalt The new minimum valid salt.
    function cancelPairRfqOrdersWithSigner(
        address maker,
        IERC20TokenV06 makerToken,
        IERC20TokenV06 takerToken,
        uint256 minValidSalt
    ) external;

    /// @dev Cancel all RFQ orders for a given maker and pairs with salts less
    ///      than the values provided. The caller must be the maker. Subsequent
    ///      calls to this function with the same caller and pair require the
    ///      new salt to be >= the old salt.
    /// @param makerTokens The maker tokens.
    /// @param takerTokens The taker tokens.
    /// @param minValidSalts The new minimum valid salts.
    function batchCancelPairRfqOrders(
        IERC20TokenV06[] calldata makerTokens,
        IERC20TokenV06[] calldata takerTokens,
        uint256[] calldata minValidSalts
    ) external;

    /// @dev Cancel all RFQ orders for a given maker and pairs with salts less
    ///      than the values provided. The caller must be a signer registered to the maker.
    ///      Subsequent calls to this function with the same maker and pair require the
    ///      new salt to be >= the old salt.
    /// @param maker The maker for which to cancel.
    /// @param makerTokens The maker tokens.
    /// @param takerTokens The taker tokens.
    /// @param minValidSalts The new minimum valid salts.
    function batchCancelPairRfqOrdersWithSigner(
        address maker,
        IERC20TokenV06[] memory makerTokens,
        IERC20TokenV06[] memory takerTokens,
        uint256[] memory minValidSalts
    ) external;

    /// @dev Get the order info for a limit order.
    /// @param order The limit order.
    /// @return orderInfo Info about the order.
    function getLimitOrderInfo(
        LibNativeOrder.LimitOrder calldata order
    ) external view returns (LibNativeOrder.OrderInfo memory orderInfo);

    /// @dev Get the order info for an RFQ order.
    /// @param order The RFQ order.
    /// @return orderInfo Info about the order.
    function getRfqOrderInfo(
        LibNativeOrder.RfqOrder calldata order
    ) external view returns (LibNativeOrder.OrderInfo memory orderInfo);

    /// @dev Get the canonical hash of a limit order.
    /// @param order The limit order.
    /// @return orderHash The order hash.
    function getLimitOrderHash(LibNativeOrder.LimitOrder calldata order) external view returns (bytes32 orderHash);

    /// @dev Get the canonical hash of an RFQ order.
    /// @param order The RFQ order.
    /// @return orderHash The order hash.
    function getRfqOrderHash(LibNativeOrder.RfqOrder calldata order) external view returns (bytes32 orderHash);

    /// @dev Get the protocol fee multiplier. This should be multiplied by the
    ///      gas price to arrive at the required protocol fee to fill a native order.
    /// @return multiplier The protocol fee multiplier.
    function getProtocolFeeMultiplier() external view returns (uint32 multiplier);

    /// @dev Get order info, fillable amount, and signature validity for a limit order.
    ///      Fillable amount is determined using balances and allowances of the maker.
    /// @param order The limit order.
    /// @param signature The order signature.
    /// @return orderInfo Info about the order.
    /// @return actualFillableTakerTokenAmount How much of the order is fillable
    ///         based on maker funds, in taker tokens.
    /// @return isSignatureValid Whether the signature is valid.
    function getLimitOrderRelevantState(
        LibNativeOrder.LimitOrder calldata order,
        LibSignature.Signature calldata signature
    )
        external
        view
        returns (
            LibNativeOrder.OrderInfo memory orderInfo,
            uint128 actualFillableTakerTokenAmount,
            bool isSignatureValid
        );

    /// @dev Get order info, fillable amount, and signature validity for an RFQ order.
    ///      Fillable amount is determined using balances and allowances of the maker.
    /// @param order The RFQ order.
    /// @param signature The order signature.
    /// @return orderInfo Info about the order.
    /// @return actualFillableTakerTokenAmount How much of the order is fillable
    ///         based on maker funds, in taker tokens.
    /// @return isSignatureValid Whether the signature is valid.
    function getRfqOrderRelevantState(
        LibNativeOrder.RfqOrder calldata order,
        LibSignature.Signature calldata signature
    )
        external
        view
        returns (
            LibNativeOrder.OrderInfo memory orderInfo,
            uint128 actualFillableTakerTokenAmount,
            bool isSignatureValid
        );

    /// @dev Batch version of `getLimitOrderRelevantState()`, without reverting.
    ///      Orders that would normally cause `getLimitOrderRelevantState()`
    ///      to revert will have empty results.
    /// @param orders The limit orders.
    /// @param signatures The order signatures.
    /// @return orderInfos Info about the orders.
    /// @return actualFillableTakerTokenAmounts How much of each order is fillable
    ///         based on maker funds, in taker tokens.
    /// @return isSignatureValids Whether each signature is valid for the order.
    function batchGetLimitOrderRelevantStates(
        LibNativeOrder.LimitOrder[] calldata orders,
        LibSignature.Signature[] calldata signatures
    )
        external
        view
        returns (
            LibNativeOrder.OrderInfo[] memory orderInfos,
            uint128[] memory actualFillableTakerTokenAmounts,
            bool[] memory isSignatureValids
        );

    /// @dev Batch version of `getRfqOrderRelevantState()`, without reverting.
    ///      Orders that would normally cause `getRfqOrderRelevantState()`
    ///      to revert will have empty results.
    /// @param orders The RFQ orders.
    /// @param signatures The order signatures.
    /// @return orderInfos Info about the orders.
    /// @return actualFillableTakerTokenAmounts How much of each order is fillable
    ///         based on maker funds, in taker tokens.
    /// @return isSignatureValids Whether each signature is valid for the order.
    function batchGetRfqOrderRelevantStates(
        LibNativeOrder.RfqOrder[] calldata orders,
        LibSignature.Signature[] calldata signatures
    )
        external
        view
        returns (
            LibNativeOrder.OrderInfo[] memory orderInfos,
            uint128[] memory actualFillableTakerTokenAmounts,
            bool[] memory isSignatureValids
        );

    /// @dev Register a signer who can sign on behalf of msg.sender
    ///      This allows one to sign on behalf of a contract that calls this function
    /// @param signer The address from which you plan to generate signatures
    /// @param allowed True to register, false to unregister.
    function registerAllowedOrderSigner(address signer, bool allowed) external;

    /// @dev checks if a given address is registered to sign on behalf of a maker address
    /// @param maker The maker address encoded in an order (can be a contract)
    /// @param signer The address that is providing a signature
    function isValidOrderSigner(address maker, address signer) external view returns (bool isAllowed);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "../libs/LibNativeOrder.sol";
import "../libs/LibSignature.sol";

/// @dev Feature for interacting with OTC orders.
interface IOtcOrdersFeature {
    /// @dev Emitted whenever an `OtcOrder` is filled.
    /// @param orderHash The canonical hash of the order.
    /// @param maker The maker of the order.
    /// @param taker The taker of the order.
    /// @param makerTokenFilledAmount How much maker token was filled.
    /// @param takerTokenFilledAmount How much taker token was filled.
    event OtcOrderFilled(
        bytes32 orderHash,
        address maker,
        address taker,
        address makerToken,
        address takerToken,
        uint128 makerTokenFilledAmount,
        uint128 takerTokenFilledAmount
    );

    /// @dev Fill an OTC order for up to `takerTokenFillAmount` taker tokens.
    /// @param order The OTC order.
    /// @param makerSignature The order signature from the maker.
    /// @param takerTokenFillAmount Maximum taker token amount to fill this
    ///        order with.
    /// @return takerTokenFilledAmount How much taker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function fillOtcOrder(
        LibNativeOrder.OtcOrder calldata order,
        LibSignature.Signature calldata makerSignature,
        uint128 takerTokenFillAmount
    ) external returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount);

    /// @dev Fill an OTC order for up to `takerTokenFillAmount` taker tokens.
    ///      Unwraps bought WETH into ETH before sending it to
    ///      the taker.
    /// @param order The OTC order.
    /// @param makerSignature The order signature from the maker.
    /// @param takerTokenFillAmount Maximum taker token amount to fill this
    ///        order with.
    /// @return takerTokenFilledAmount How much taker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function fillOtcOrderForEth(
        LibNativeOrder.OtcOrder calldata order,
        LibSignature.Signature calldata makerSignature,
        uint128 takerTokenFillAmount
    ) external returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount);

    /// @dev Fill an OTC order whose taker token is WETH for up
    ///      to `msg.value`.
    /// @param order The OTC order.
    /// @param makerSignature The order signature from the maker.
    /// @return takerTokenFilledAmount How much taker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function fillOtcOrderWithEth(
        LibNativeOrder.OtcOrder calldata order,
        LibSignature.Signature calldata makerSignature
    ) external payable returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount);

    /// @dev Fully fill an OTC order. "Meta-transaction" variant,
    ///      requires order to be signed by both maker and taker.
    /// @param order The OTC order.
    /// @param makerSignature The order signature from the maker.
    /// @param takerSignature The order signature from the taker.
    function fillTakerSignedOtcOrder(
        LibNativeOrder.OtcOrder calldata order,
        LibSignature.Signature calldata makerSignature,
        LibSignature.Signature calldata takerSignature
    ) external;

    /// @dev Fully fill an OTC order. "Meta-transaction" variant,
    ///      requires order to be signed by both maker and taker.
    ///      Unwraps bought WETH into ETH before sending it to
    ///      the taker.
    /// @param order The OTC order.
    /// @param makerSignature The order signature from the maker.
    /// @param takerSignature The order signature from the taker.
    function fillTakerSignedOtcOrderForEth(
        LibNativeOrder.OtcOrder calldata order,
        LibSignature.Signature calldata makerSignature,
        LibSignature.Signature calldata takerSignature
    ) external;

    /// @dev Fills multiple taker-signed OTC orders.
    /// @param orders Array of OTC orders.
    /// @param makerSignatures Array of maker signatures for each order.
    /// @param takerSignatures Array of taker signatures for each order.
    /// @param unwrapWeth Array of booleans representing whether or not
    ///        to unwrap bought WETH into ETH for each order. Should be set
    ///        to false if the maker token is not WETH.
    /// @return successes Array of booleans representing whether or not
    ///         each order in `orders` was filled successfully.
    function batchFillTakerSignedOtcOrders(
        LibNativeOrder.OtcOrder[] calldata orders,
        LibSignature.Signature[] calldata makerSignatures,
        LibSignature.Signature[] calldata takerSignatures,
        bool[] calldata unwrapWeth
    ) external returns (bool[] memory successes);

    /// @dev Fill an OTC order for up to `takerTokenFillAmount` taker tokens.
    ///      Internal variant.
    /// @param order The OTC order.
    /// @param makerSignature The order signature from the maker.
    /// @param takerTokenFillAmount Maximum taker token amount to fill this
    ///        order with.
    /// @param taker The address to fill the order in the context of.
    /// @param useSelfBalance Whether to use the Exchange Proxy's balance
    ///        of input tokens.
    /// @param recipient The recipient of the bought maker tokens.
    /// @return takerTokenFilledAmount How much taker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function _fillOtcOrder(
        LibNativeOrder.OtcOrder calldata order,
        LibSignature.Signature calldata makerSignature,
        uint128 takerTokenFillAmount,
        address taker,
        bool useSelfBalance,
        address recipient
    ) external returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount);

    /// @dev Get the order info for an OTC order.
    /// @param order The OTC order.
    /// @return orderInfo Info about the order.
    function getOtcOrderInfo(
        LibNativeOrder.OtcOrder calldata order
    ) external view returns (LibNativeOrder.OtcOrderInfo memory orderInfo);

    /// @dev Get the canonical hash of an OTC order.
    /// @param order The OTC order.
    /// @return orderHash The order hash.
    function getOtcOrderHash(LibNativeOrder.OtcOrder calldata order) external view returns (bytes32 orderHash);

    /// @dev Get the last nonce used for a particular
    ///      tx.origin address and nonce bucket.
    /// @param txOrigin The address.
    /// @param nonceBucket The nonce bucket index.
    /// @return lastNonce The last nonce value used.
    function lastOtcTxOriginNonce(address txOrigin, uint64 nonceBucket) external view returns (uint128 lastNonce);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/interfaces/IOwnableV06.sol";

/// @dev Owner management and migration features.
interface IOwnableFeature is IOwnableV06 {
    /// @dev Emitted when `migrate()` is called.
    /// @param caller The caller of `migrate()`.
    /// @param migrator The migration contract.
    /// @param newOwner The address of the new owner.
    event Migrated(address caller, address migrator, address newOwner);

    /// @dev Execute a migration function in the context of the ZeroEx contract.
    ///      The result of the function being called should be the magic bytes
    ///      0x2c64c5ef (`keccack('MIGRATE_SUCCESS')`). Only callable by the owner.
    ///      The owner will be temporarily set to `address(this)` inside the call.
    ///      Before returning, the owner will be set to `newOwner`.
    /// @param target The migrator contract address.
    /// @param newOwner The address of the new owner.
    /// @param data The call data.
    function migrate(address target, bytes calldata data, address newOwner) external;
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";

/// @dev VIP PancakeSwap (and forks) fill functions.
interface IPancakeSwapFeature {
    enum ProtocolFork {
        PancakeSwap,
        PancakeSwapV2,
        BakerySwap,
        SushiSwap,
        ApeSwap,
        CafeSwap,
        CheeseSwap,
        JulSwap
    }

    /// @dev Efficiently sell directly to PancakeSwap (and forks).
    /// @param tokens Sell path.
    /// @param sellAmount of `tokens[0]` Amount to sell.
    /// @param minBuyAmount Minimum amount of `tokens[-1]` to buy.
    /// @param fork The protocol fork to use.
    /// @return buyAmount Amount of `tokens[-1]` bought.
    function sellToPancakeSwap(
        IERC20TokenV06[] calldata tokens,
        uint256 sellAmount,
        uint256 minBuyAmount,
        ProtocolFork fork
    ) external payable returns (uint256 buyAmount);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

/// @dev Basic registry management features.
interface ISimpleFunctionRegistryFeature {
    /// @dev A function implementation was updated via `extend()` or `rollback()`.
    /// @param selector The function selector.
    /// @param oldImpl The implementation contract address being replaced.
    /// @param newImpl The replacement implementation contract address.
    event ProxyFunctionUpdated(bytes4 indexed selector, address oldImpl, address newImpl);

    /// @dev Roll back to a prior implementation of a function.
    /// @param selector The function selector.
    /// @param targetImpl The address of an older implementation of the function.
    function rollback(bytes4 selector, address targetImpl) external;

    /// @dev Register or replace a function.
    /// @param selector The function selector.
    /// @param impl The implementation contract for the function.
    function extend(bytes4 selector, address impl) external;

    /// @dev Retrieve the length of the rollback history for a function.
    /// @param selector The function selector.
    /// @return rollbackLength The number of items in the rollback history for
    ///         the function.
    function getRollbackLength(bytes4 selector) external view returns (uint256 rollbackLength);

    /// @dev Retrieve an entry in the rollback history for a function.
    /// @param selector The function selector.
    /// @param idx The index in the rollback history.
    /// @return impl An implementation address for the function at
    ///         index `idx`.
    function getRollbackEntryAtIndex(bytes4 selector, uint256 idx) external view returns (address impl);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";

/// @dev Feature that allows spending token allowances.
interface ITokenSpenderFeature {
    /// @dev Transfers ERC20 tokens from `owner` to `to`.
    ///      Only callable from within.
    /// @param token The token to spend.
    /// @param owner The owner of the tokens.
    /// @param to The recipient of the tokens.
    /// @param amount The amount of `token` to transfer.
    function _spendERC20Tokens(IERC20TokenV06 token, address owner, address to, uint256 amount) external;

    /// @dev Gets the maximum amount of an ERC20 token `token` that can be
    ///      pulled from `owner`.
    /// @param token The token to spend.
    /// @param owner The owner of the tokens.
    /// @return amount The amount of tokens that can be pulled.
    function getSpendableERC20BalanceOf(IERC20TokenV06 token, address owner) external view returns (uint256 amount);

    /// @dev Get the address of the allowance target.
    /// @return target The target of token allowances.
    function getAllowanceTarget() external view returns (address target);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "../../transformers/IERC20Transformer.sol";
import "../../external/IFlashWallet.sol";

/// @dev Feature to composably transform between ERC20 tokens.
interface ITransformERC20Feature {
    /// @dev Defines a transformation to run in `transformERC20()`.
    struct Transformation {
        // The deployment nonce for the transformer.
        // The address of the transformer contract will be derived from this
        // value.
        uint32 deploymentNonce;
        // Arbitrary data to pass to the transformer.
        bytes data;
    }

    /// @dev Arguments for `_transformERC20()`.
    struct TransformERC20Args {
        // The taker address.
        address payable taker;
        // The token being provided by the taker.
        // If `0xeee...`, ETH is implied and should be provided with the call.`
        IERC20TokenV06 inputToken;
        // The token to be acquired by the taker.
        // `0xeee...` implies ETH.
        IERC20TokenV06 outputToken;
        // The amount of `inputToken` to take from the taker.
        // If set to `uint256(-1)`, the entire spendable balance of the taker
        // will be solt.
        uint256 inputTokenAmount;
        // The minimum amount of `outputToken` the taker
        // must receive for the entire transformation to succeed. If set to zero,
        // the minimum output token transfer will not be asserted.
        uint256 minOutputTokenAmount;
        // The transformations to execute on the token balance(s)
        // in sequence.
        Transformation[] transformations;
        // Whether to use the Exchange Proxy's balance of `inputToken`.
        bool useSelfBalance;
        // The recipient of the bought `outputToken`.
        address payable recipient;
    }

    /// @dev Raised upon a successful `transformERC20`.
    /// @param taker The taker (caller) address.
    /// @param inputToken The token being provided by the taker.
    ///        If `0xeee...`, ETH is implied and should be provided with the call.`
    /// @param outputToken The token to be acquired by the taker.
    ///        `0xeee...` implies ETH.
    /// @param inputTokenAmount The amount of `inputToken` to take from the taker.
    /// @param outputTokenAmount The amount of `outputToken` received by the taker.
    event TransformedERC20(
        address indexed taker,
        address inputToken,
        address outputToken,
        uint256 inputTokenAmount,
        uint256 outputTokenAmount
    );

    /// @dev Raised when `setTransformerDeployer()` is called.
    /// @param transformerDeployer The new deployer address.
    event TransformerDeployerUpdated(address transformerDeployer);

    /// @dev Raised when `setQuoteSigner()` is called.
    /// @param quoteSigner The new quote signer.
    event QuoteSignerUpdated(address quoteSigner);

    /// @dev Replace the allowed deployer for transformers.
    ///      Only callable by the owner.
    /// @param transformerDeployer The address of the new trusted deployer
    ///        for transformers.
    function setTransformerDeployer(address transformerDeployer) external;

    /// @dev Replace the optional signer for `transformERC20()` calldata.
    ///      Only callable by the owner.
    /// @param quoteSigner The address of the new calldata signer.
    function setQuoteSigner(address quoteSigner) external;

    /// @dev Deploy a new flash wallet instance and replace the current one with it.
    ///      Useful if we somehow break the current wallet instance.
    ///       Only callable by the owner.
    /// @return wallet The new wallet instance.
    function createTransformWallet() external returns (IFlashWallet wallet);

    /// @dev Executes a series of transformations to convert an ERC20 `inputToken`
    ///      to an ERC20 `outputToken`.
    /// @param inputToken The token being provided by the sender.
    ///        If `0xeee...`, ETH is implied and should be provided with the call.`
    /// @param outputToken The token to be acquired by the sender.
    ///        `0xeee...` implies ETH.
    /// @param inputTokenAmount The amount of `inputToken` to take from the sender.
    /// @param minOutputTokenAmount The minimum amount of `outputToken` the sender
    ///        must receive for the entire transformation to succeed.
    /// @param transformations The transformations to execute on the token balance(s)
    ///        in sequence.
    /// @return outputTokenAmount The amount of `outputToken` received by the sender.
    function transformERC20(
        IERC20TokenV06 inputToken,
        IERC20TokenV06 outputToken,
        uint256 inputTokenAmount,
        uint256 minOutputTokenAmount,
        Transformation[] calldata transformations
    ) external payable returns (uint256 outputTokenAmount);

    /// @dev Internal version of `transformERC20()`. Only callable from within.
    /// @param args A `TransformERC20Args` struct.
    /// @return outputTokenAmount The amount of `outputToken` received by the taker.
    function _transformERC20(TransformERC20Args calldata args) external payable returns (uint256 outputTokenAmount);

    /// @dev Return the current wallet instance that will serve as the execution
    ///      context for transformations.
    /// @return wallet The wallet instance.
    function getTransformWallet() external view returns (IFlashWallet wallet);

    /// @dev Return the allowed deployer for transformers.
    /// @return deployer The transform deployer address.
    function getTransformerDeployer() external view returns (address deployer);

    /// @dev Return the optional signer for `transformERC20()` calldata.
    /// @return signer The transform deployer address.
    function getQuoteSigner() external view returns (address signer);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";

/// @dev VIP uniswap fill functions.
interface IUniswapFeature {
    /// @dev Efficiently sell directly to uniswap/sushiswap.
    /// @param tokens Sell path.
    /// @param sellAmount of `tokens[0]` Amount to sell.
    /// @param minBuyAmount Minimum amount of `tokens[-1]` to buy.
    /// @param isSushi Use sushiswap if true.
    /// @return buyAmount Amount of `tokens[-1]` bought.
    function sellToUniswap(
        IERC20TokenV06[] calldata tokens,
        uint256 sellAmount,
        uint256 minBuyAmount,
        bool isSushi
    ) external payable returns (uint256 buyAmount);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";

/// @dev VIP uniswap v3 fill functions.
interface IUniswapV3Feature {
    /// @dev Sell attached ETH directly against uniswap v3.
    /// @param encodedPath Uniswap-encoded path, where the first token is WETH.
    /// @param minBuyAmount Minimum amount of the last token in the path to buy.
    /// @param recipient The recipient of the bought tokens. Can be zero for sender.
    /// @return buyAmount Amount of the last token in the path bought.
    function sellEthForTokenToUniswapV3(
        bytes memory encodedPath,
        uint256 minBuyAmount,
        address recipient
    ) external payable returns (uint256 buyAmount);

    /// @dev Sell a token for ETH directly against uniswap v3.
    /// @param encodedPath Uniswap-encoded path, where the last token is WETH.
    /// @param sellAmount amount of the first token in the path to sell.
    /// @param minBuyAmount Minimum amount of ETH to buy.
    /// @param recipient The recipient of the bought tokens. Can be zero for sender.
    /// @return buyAmount Amount of ETH bought.
    function sellTokenForEthToUniswapV3(
        bytes memory encodedPath,
        uint256 sellAmount,
        uint256 minBuyAmount,
        address payable recipient
    ) external returns (uint256 buyAmount);

    /// @dev Sell a token for another token directly against uniswap v3.
    /// @param encodedPath Uniswap-encoded path.
    /// @param sellAmount amount of the first token in the path to sell.
    /// @param minBuyAmount Minimum amount of the last token in the path to buy.
    /// @param recipient The recipient of the bought tokens. Can be zero for sender.
    /// @return buyAmount Amount of the last token in the path bought.
    function sellTokenForTokenToUniswapV3(
        bytes memory encodedPath,
        uint256 sellAmount,
        uint256 minBuyAmount,
        address recipient
    ) external returns (uint256 buyAmount);

    /// @dev Sell a token for another token directly against uniswap v3.
    ///      Private variant, uses tokens held by `address(this)`.
    /// @param encodedPath Uniswap-encoded path.
    /// @param sellAmount amount of the first token in the path to sell.
    /// @param minBuyAmount Minimum amount of the last token in the path to buy.
    /// @param recipient The recipient of the bought tokens. Can be zero for sender.
    /// @return buyAmount Amount of the last token in the path bought.
    function _sellHeldTokenForTokenToUniswapV3(
        bytes memory encodedPath,
        uint256 sellAmount,
        uint256 minBuyAmount,
        address recipient
    ) external returns (uint256 buyAmount);

    /// @dev The UniswapV3 pool swap callback which pays the funds requested
    ///      by the caller/pool to the pool. Can only be called by a valid
    ///      UniswapV3 pool.
    /// @param amount0Delta Token0 amount owed.
    /// @param amount1Delta Token1 amount owed.
    /// @param data Arbitrary data forwarded from swap() caller. An ABI-encoded
    ///        struct of: inputToken, outputToken, fee, payer
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external;
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../../errors/LibNativeOrdersRichErrors.sol";

/// @dev A library for common native order operations.
library LibNativeOrder {
    using LibSafeMathV06 for uint256;
    using LibRichErrorsV06 for bytes;

    enum OrderStatus {
        INVALID,
        FILLABLE,
        FILLED,
        CANCELLED,
        EXPIRED
    }

    /// @dev A standard OTC or OO limit order.
    struct LimitOrder {
        IERC20TokenV06 makerToken;
        IERC20TokenV06 takerToken;
        uint128 makerAmount;
        uint128 takerAmount;
        uint128 takerTokenFeeAmount;
        address maker;
        address taker;
        address sender;
        address feeRecipient;
        bytes32 pool;
        uint64 expiry;
        uint256 salt;
    }

    /// @dev An RFQ limit order.
    struct RfqOrder {
        IERC20TokenV06 makerToken;
        IERC20TokenV06 takerToken;
        uint128 makerAmount;
        uint128 takerAmount;
        address maker;
        address taker;
        address txOrigin;
        bytes32 pool;
        uint64 expiry;
        uint256 salt;
    }

    /// @dev An OTC limit order.
    struct OtcOrder {
        IERC20TokenV06 makerToken;
        IERC20TokenV06 takerToken;
        uint128 makerAmount;
        uint128 takerAmount;
        address maker;
        address taker;
        address txOrigin;
        uint256 expiryAndNonce; // [uint64 expiry, uint64 nonceBucket, uint128 nonce]
    }

    /// @dev Info on a limit or RFQ order.
    struct OrderInfo {
        bytes32 orderHash;
        OrderStatus status;
        uint128 takerTokenFilledAmount;
    }

    /// @dev Info on an OTC order.
    struct OtcOrderInfo {
        bytes32 orderHash;
        OrderStatus status;
    }

    uint256 private constant UINT_128_MASK = (1 << 128) - 1;
    uint256 private constant UINT_64_MASK = (1 << 64) - 1;
    uint256 private constant ADDRESS_MASK = (1 << 160) - 1;

    // The type hash for limit orders, which is:
    // keccak256(abi.encodePacked(
    //     "LimitOrder(",
    //       "address makerToken,",
    //       "address takerToken,",
    //       "uint128 makerAmount,",
    //       "uint128 takerAmount,",
    //       "uint128 takerTokenFeeAmount,",
    //       "address maker,",
    //       "address taker,",
    //       "address sender,",
    //       "address feeRecipient,",
    //       "bytes32 pool,",
    //       "uint64 expiry,",
    //       "uint256 salt"
    //     ")"
    // ))
    uint256 private constant _LIMIT_ORDER_TYPEHASH = 0xce918627cb55462ddbb85e73de69a8b322f2bc88f4507c52fcad6d4c33c29d49;

    // The type hash for RFQ orders, which is:
    // keccak256(abi.encodePacked(
    //     "RfqOrder(",
    //       "address makerToken,",
    //       "address takerToken,",
    //       "uint128 makerAmount,",
    //       "uint128 takerAmount,",
    //       "address maker,",
    //       "address taker,",
    //       "address txOrigin,",
    //       "bytes32 pool,",
    //       "uint64 expiry,",
    //       "uint256 salt"
    //     ")"
    // ))
    uint256 private constant _RFQ_ORDER_TYPEHASH = 0xe593d3fdfa8b60e5e17a1b2204662ecbe15c23f2084b9ad5bae40359540a7da9;

    // The type hash for OTC orders, which is:
    // keccak256(abi.encodePacked(
    //     "OtcOrder(",
    //       "address makerToken,",
    //       "address takerToken,",
    //       "uint128 makerAmount,",
    //       "uint128 takerAmount,",
    //       "address maker,",
    //       "address taker,",
    //       "address txOrigin,",
    //       "uint256 expiryAndNonce"
    //     ")"
    // ))
    uint256 private constant _OTC_ORDER_TYPEHASH = 0x2f754524de756ae72459efbe1ec88c19a745639821de528ac3fb88f9e65e35c8;

    /// @dev Get the struct hash of a limit order.
    /// @param order The limit order.
    /// @return structHash The struct hash of the order.
    function getLimitOrderStructHash(LimitOrder memory order) internal pure returns (bytes32 structHash) {
        // The struct hash is:
        // keccak256(abi.encode(
        //   TYPE_HASH,
        //   order.makerToken,
        //   order.takerToken,
        //   order.makerAmount,
        //   order.takerAmount,
        //   order.takerTokenFeeAmount,
        //   order.maker,
        //   order.taker,
        //   order.sender,
        //   order.feeRecipient,
        //   order.pool,
        //   order.expiry,
        //   order.salt,
        // ))
        assembly {
            let mem := mload(0x40)
            mstore(mem, _LIMIT_ORDER_TYPEHASH)
            // order.makerToken;
            mstore(add(mem, 0x20), and(ADDRESS_MASK, mload(order)))
            // order.takerToken;
            mstore(add(mem, 0x40), and(ADDRESS_MASK, mload(add(order, 0x20))))
            // order.makerAmount;
            mstore(add(mem, 0x60), and(UINT_128_MASK, mload(add(order, 0x40))))
            // order.takerAmount;
            mstore(add(mem, 0x80), and(UINT_128_MASK, mload(add(order, 0x60))))
            // order.takerTokenFeeAmount;
            mstore(add(mem, 0xA0), and(UINT_128_MASK, mload(add(order, 0x80))))
            // order.maker;
            mstore(add(mem, 0xC0), and(ADDRESS_MASK, mload(add(order, 0xA0))))
            // order.taker;
            mstore(add(mem, 0xE0), and(ADDRESS_MASK, mload(add(order, 0xC0))))
            // order.sender;
            mstore(add(mem, 0x100), and(ADDRESS_MASK, mload(add(order, 0xE0))))
            // order.feeRecipient;
            mstore(add(mem, 0x120), and(ADDRESS_MASK, mload(add(order, 0x100))))
            // order.pool;
            mstore(add(mem, 0x140), mload(add(order, 0x120)))
            // order.expiry;
            mstore(add(mem, 0x160), and(UINT_64_MASK, mload(add(order, 0x140))))
            // order.salt;
            mstore(add(mem, 0x180), mload(add(order, 0x160)))
            structHash := keccak256(mem, 0x1A0)
        }
    }

    /// @dev Get the struct hash of a RFQ order.
    /// @param order The RFQ order.
    /// @return structHash The struct hash of the order.
    function getRfqOrderStructHash(RfqOrder memory order) internal pure returns (bytes32 structHash) {
        // The struct hash is:
        // keccak256(abi.encode(
        //   TYPE_HASH,
        //   order.makerToken,
        //   order.takerToken,
        //   order.makerAmount,
        //   order.takerAmount,
        //   order.maker,
        //   order.taker,
        //   order.txOrigin,
        //   order.pool,
        //   order.expiry,
        //   order.salt,
        // ))
        assembly {
            let mem := mload(0x40)
            mstore(mem, _RFQ_ORDER_TYPEHASH)
            // order.makerToken;
            mstore(add(mem, 0x20), and(ADDRESS_MASK, mload(order)))
            // order.takerToken;
            mstore(add(mem, 0x40), and(ADDRESS_MASK, mload(add(order, 0x20))))
            // order.makerAmount;
            mstore(add(mem, 0x60), and(UINT_128_MASK, mload(add(order, 0x40))))
            // order.takerAmount;
            mstore(add(mem, 0x80), and(UINT_128_MASK, mload(add(order, 0x60))))
            // order.maker;
            mstore(add(mem, 0xA0), and(ADDRESS_MASK, mload(add(order, 0x80))))
            // order.taker;
            mstore(add(mem, 0xC0), and(ADDRESS_MASK, mload(add(order, 0xA0))))
            // order.txOrigin;
            mstore(add(mem, 0xE0), and(ADDRESS_MASK, mload(add(order, 0xC0))))
            // order.pool;
            mstore(add(mem, 0x100), mload(add(order, 0xE0)))
            // order.expiry;
            mstore(add(mem, 0x120), and(UINT_64_MASK, mload(add(order, 0x100))))
            // order.salt;
            mstore(add(mem, 0x140), mload(add(order, 0x120)))
            structHash := keccak256(mem, 0x160)
        }
    }

    /// @dev Get the struct hash of an OTC order.
    /// @param order The OTC order.
    /// @return structHash The struct hash of the order.
    function getOtcOrderStructHash(OtcOrder memory order) internal pure returns (bytes32 structHash) {
        // The struct hash is:
        // keccak256(abi.encode(
        //   TYPE_HASH,
        //   order.makerToken,
        //   order.takerToken,
        //   order.makerAmount,
        //   order.takerAmount,
        //   order.maker,
        //   order.taker,
        //   order.txOrigin,
        //   order.expiryAndNonce,
        // ))
        assembly {
            let mem := mload(0x40)
            mstore(mem, _OTC_ORDER_TYPEHASH)
            // order.makerToken;
            mstore(add(mem, 0x20), and(ADDRESS_MASK, mload(order)))
            // order.takerToken;
            mstore(add(mem, 0x40), and(ADDRESS_MASK, mload(add(order, 0x20))))
            // order.makerAmount;
            mstore(add(mem, 0x60), and(UINT_128_MASK, mload(add(order, 0x40))))
            // order.takerAmount;
            mstore(add(mem, 0x80), and(UINT_128_MASK, mload(add(order, 0x60))))
            // order.maker;
            mstore(add(mem, 0xA0), and(ADDRESS_MASK, mload(add(order, 0x80))))
            // order.taker;
            mstore(add(mem, 0xC0), and(ADDRESS_MASK, mload(add(order, 0xA0))))
            // order.txOrigin;
            mstore(add(mem, 0xE0), and(ADDRESS_MASK, mload(add(order, 0xC0))))
            // order.expiryAndNonce;
            mstore(add(mem, 0x100), mload(add(order, 0xE0)))
            structHash := keccak256(mem, 0x120)
        }
    }

    /// @dev Refund any leftover protocol fees in `msg.value` to `msg.sender`.
    /// @param ethProtocolFeePaid How much ETH was paid in protocol fees.
    function refundExcessProtocolFeeToSender(uint256 ethProtocolFeePaid) internal {
        if (msg.value > ethProtocolFeePaid && msg.sender != address(this)) {
            uint256 refundAmount = msg.value.safeSub(ethProtocolFeePaid);
            (bool success, ) = msg.sender.call{value: refundAmount}("");
            if (!success) {
                LibNativeOrdersRichErrors.ProtocolFeeRefundFailed(msg.sender, refundAmount).rrevert();
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "../../vendor/IERC1155Token.sol";
import "../../vendor/IERC721Token.sol";
import "../../vendor/IPropertyValidator.sol";

/// @dev A library for common NFT order operations.
library LibNFTOrder {
    enum OrderStatus {
        INVALID,
        FILLABLE,
        UNFILLABLE,
        EXPIRED
    }

    enum TradeDirection {
        SELL_NFT,
        BUY_NFT
    }

    struct Property {
        IPropertyValidator propertyValidator;
        bytes propertyData;
    }

    struct Fee {
        address recipient;
        uint256 amount;
        bytes feeData;
    }

    // "Base struct" for ERC721Order and ERC1155, used
    // by the abstract contract `NFTOrders`.
    struct NFTOrder {
        TradeDirection direction;
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20TokenV06 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address nft;
        uint256 nftId;
        Property[] nftProperties;
    }

    // All fields align with those of NFTOrder
    struct ERC721Order {
        TradeDirection direction;
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20TokenV06 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        IERC721Token erc721Token;
        uint256 erc721TokenId;
        Property[] erc721TokenProperties;
    }

    // All fields except `erc1155TokenAmount` align
    // with those of NFTOrder
    struct ERC1155Order {
        TradeDirection direction;
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20TokenV06 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        IERC1155Token erc1155Token;
        uint256 erc1155TokenId;
        Property[] erc1155TokenProperties;
        // End of fields shared with NFTOrder
        uint128 erc1155TokenAmount;
    }

    struct OrderInfo {
        bytes32 orderHash;
        OrderStatus status;
        // `orderAmount` is 1 for all ERC721Orders, and
        // `erc1155TokenAmount` for ERC1155Orders.
        uint128 orderAmount;
        // The remaining amount of the ERC721/ERC1155 asset
        // that can be filled for the order.
        uint128 remainingAmount;
    }

    // The type hash for ERC721 orders, which is:
    // keccak256(abi.encodePacked(
    //     "ERC721Order(",
    //       "uint8 direction,",
    //       "address maker,",
    //       "address taker,",
    //       "uint256 expiry,",
    //       "uint256 nonce,",
    //       "address erc20Token,",
    //       "uint256 erc20TokenAmount,",
    //       "Fee[] fees,",
    //       "address erc721Token,",
    //       "uint256 erc721TokenId,",
    //       "Property[] erc721TokenProperties",
    //     ")",
    //     "Fee(",
    //       "address recipient,",
    //       "uint256 amount,",
    //       "bytes feeData",
    //     ")",
    //     "Property(",
    //       "address propertyValidator,",
    //       "bytes propertyData",
    //     ")"
    // ))
    uint256 private constant _ERC_721_ORDER_TYPEHASH =
        0x2de32b2b090da7d8ab83ca4c85ba2eb6957bc7f6c50cb4ae1995e87560d808ed;

    // The type hash for ERC1155 orders, which is:
    // keccak256(abi.encodePacked(
    //     "ERC1155Order(",
    //       "uint8 direction,",
    //       "address maker,",
    //       "address taker,",
    //       "uint256 expiry,",
    //       "uint256 nonce,",
    //       "address erc20Token,",
    //       "uint256 erc20TokenAmount,",
    //       "Fee[] fees,",
    //       "address erc1155Token,",
    //       "uint256 erc1155TokenId,",
    //       "Property[] erc1155TokenProperties,",
    //       "uint128 erc1155TokenAmount",
    //     ")",
    //     "Fee(",
    //       "address recipient,",
    //       "uint256 amount,",
    //       "bytes feeData",
    //     ")",
    //     "Property(",
    //       "address propertyValidator,",
    //       "bytes propertyData",
    //     ")"
    // ))
    uint256 private constant _ERC_1155_ORDER_TYPEHASH =
        0x930490b1bcedd2e5139e22c761fafd52e533960197c2283f3922c7fd8c880be9;

    // keccak256(abi.encodePacked(
    //     "Fee(",
    //       "address recipient,",
    //       "uint256 amount,",
    //       "bytes feeData",
    //     ")"
    // ))
    uint256 private constant _FEE_TYPEHASH = 0xe68c29f1b4e8cce0bbcac76eb1334bdc1dc1f293a517c90e9e532340e1e94115;

    // keccak256(abi.encodePacked(
    //     "Property(",
    //       "address propertyValidator,",
    //       "bytes propertyData",
    //     ")"
    // ))
    uint256 private constant _PROPERTY_TYPEHASH = 0x6292cf854241cb36887e639065eca63b3af9f7f70270cebeda4c29b6d3bc65e8;

    // keccak256("");
    bytes32 private constant _EMPTY_ARRAY_KECCAK256 =
        0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    // keccak256(abi.encodePacked(keccak256(abi.encode(
    //     _PROPERTY_TYPEHASH,
    //     address(0),
    //     keccak256("")
    // ))));
    bytes32 private constant _NULL_PROPERTY_STRUCT_HASH =
        0x720ee400a9024f6a49768142c339bf09d2dd9056ab52d20fbe7165faba6e142d;

    uint256 private constant ADDRESS_MASK = (1 << 160) - 1;

    // ERC721Order and NFTOrder fields are aligned, so
    // we can safely cast an ERC721Order to an NFTOrder.
    function asNFTOrder(ERC721Order memory erc721Order) internal pure returns (NFTOrder memory nftOrder) {
        assembly {
            nftOrder := erc721Order
        }
    }

    // ERC1155Order and NFTOrder fields are aligned with
    // the exception of the last field `erc1155TokenAmount`
    // in ERC1155Order, so we can safely cast an ERC1155Order
    // to an NFTOrder.
    function asNFTOrder(ERC1155Order memory erc1155Order) internal pure returns (NFTOrder memory nftOrder) {
        assembly {
            nftOrder := erc1155Order
        }
    }

    // ERC721Order and NFTOrder fields are aligned, so
    // we can safely cast an MFTOrder to an ERC721Order.
    function asERC721Order(NFTOrder memory nftOrder) internal pure returns (ERC721Order memory erc721Order) {
        assembly {
            erc721Order := nftOrder
        }
    }

    // NOTE: This is only safe if `nftOrder` was previously
    // cast from an `ERC1155Order` and the original
    // `erc1155TokenAmount` memory word has not been corrupted!
    function asERC1155Order(NFTOrder memory nftOrder) internal pure returns (ERC1155Order memory erc1155Order) {
        assembly {
            erc1155Order := nftOrder
        }
    }

    /// @dev Get the struct hash of an ERC721 order.
    /// @param order The ERC721 order.
    /// @return structHash The struct hash of the order.
    function getERC721OrderStructHash(ERC721Order memory order) internal pure returns (bytes32 structHash) {
        bytes32 propertiesHash = _propertiesHash(order.erc721TokenProperties);
        bytes32 feesHash = _feesHash(order.fees);

        // Hash in place, equivalent to:
        // return keccak256(abi.encode(
        //     _ERC_721_ORDER_TYPEHASH,
        //     order.direction,
        //     order.maker,
        //     order.taker,
        //     order.expiry,
        //     order.nonce,
        //     order.erc20Token,
        //     order.erc20TokenAmount,
        //     feesHash,
        //     order.erc721Token,
        //     order.erc721TokenId,
        //     propertiesHash
        // ));
        assembly {
            if lt(order, 32) {
                invalid()
            } // Don't underflow memory.

            let typeHashPos := sub(order, 32) // order - 32
            let feesHashPos := add(order, 224) // order + (32 * 7)
            let propertiesHashPos := add(order, 320) // order + (32 * 10)

            let typeHashMemBefore := mload(typeHashPos)
            let feeHashMemBefore := mload(feesHashPos)
            let propertiesHashMemBefore := mload(propertiesHashPos)

            mstore(typeHashPos, _ERC_721_ORDER_TYPEHASH)
            mstore(feesHashPos, feesHash)
            mstore(propertiesHashPos, propertiesHash)
            structHash := keccak256(typeHashPos, 384 /* 32 * 12 */)

            mstore(typeHashPos, typeHashMemBefore)
            mstore(feesHashPos, feeHashMemBefore)
            mstore(propertiesHashPos, propertiesHashMemBefore)
        }
        return structHash;
    }

    /// @dev Get the struct hash of an ERC1155 order.
    /// @param order The ERC1155 order.
    /// @return structHash The struct hash of the order.
    function getERC1155OrderStructHash(ERC1155Order memory order) internal pure returns (bytes32 structHash) {
        bytes32 propertiesHash = _propertiesHash(order.erc1155TokenProperties);
        bytes32 feesHash = _feesHash(order.fees);

        // Hash in place, equivalent to:
        // return keccak256(abi.encode(
        //     _ERC_1155_ORDER_TYPEHASH,
        //     order.direction,
        //     order.maker,
        //     order.taker,
        //     order.expiry,
        //     order.nonce,
        //     order.erc20Token,
        //     order.erc20TokenAmount,
        //     feesHash,
        //     order.erc1155Token,
        //     order.erc1155TokenId,
        //     propertiesHash,
        //     order.erc1155TokenAmount
        // ));
        assembly {
            if lt(order, 32) {
                invalid()
            } // Don't underflow memory.

            let typeHashPos := sub(order, 32) // order - 32
            let feesHashPos := add(order, 224) // order + (32 * 7)
            let propertiesHashPos := add(order, 320) // order + (32 * 10)

            let typeHashMemBefore := mload(typeHashPos)
            let feesHashMemBefore := mload(feesHashPos)
            let propertiesHashMemBefore := mload(propertiesHashPos)

            mstore(typeHashPos, _ERC_1155_ORDER_TYPEHASH)
            mstore(feesHashPos, feesHash)
            mstore(propertiesHashPos, propertiesHash)
            structHash := keccak256(typeHashPos, 416 /* 32 * 12 */)

            mstore(typeHashPos, typeHashMemBefore)
            mstore(feesHashPos, feesHashMemBefore)
            mstore(propertiesHashPos, propertiesHashMemBefore)
        }
        return structHash;
    }

    // Hashes the `properties` array as part of computing the
    // EIP-712 hash of an `ERC721Order` or `ERC1155Order`.
    function _propertiesHash(Property[] memory properties) private pure returns (bytes32 propertiesHash) {
        uint256 numProperties = properties.length;
        // We give `properties.length == 0` and `properties.length == 1`
        // special treatment because we expect these to be the most common.
        if (numProperties == 0) {
            propertiesHash = _EMPTY_ARRAY_KECCAK256;
        } else if (numProperties == 1) {
            Property memory property = properties[0];
            if (address(property.propertyValidator) == address(0) && property.propertyData.length == 0) {
                propertiesHash = _NULL_PROPERTY_STRUCT_HASH;
            } else {
                // propertiesHash = keccak256(abi.encodePacked(keccak256(abi.encode(
                //     _PROPERTY_TYPEHASH,
                //     properties[0].propertyValidator,
                //     keccak256(properties[0].propertyData)
                // ))));
                bytes32 dataHash = keccak256(property.propertyData);
                assembly {
                    // Load free memory pointer
                    let mem := mload(64)
                    mstore(mem, _PROPERTY_TYPEHASH)
                    // property.propertyValidator
                    mstore(add(mem, 32), and(ADDRESS_MASK, mload(property)))
                    // keccak256(property.propertyData)
                    mstore(add(mem, 64), dataHash)
                    mstore(mem, keccak256(mem, 96))
                    propertiesHash := keccak256(mem, 32)
                }
            }
        } else {
            bytes32[] memory propertyStructHashArray = new bytes32[](numProperties);
            for (uint256 i = 0; i < numProperties; i++) {
                propertyStructHashArray[i] = keccak256(
                    abi.encode(
                        _PROPERTY_TYPEHASH,
                        properties[i].propertyValidator,
                        keccak256(properties[i].propertyData)
                    )
                );
            }
            assembly {
                propertiesHash := keccak256(add(propertyStructHashArray, 32), mul(numProperties, 32))
            }
        }
    }

    // Hashes the `fees` array as part of computing the
    // EIP-712 hash of an `ERC721Order` or `ERC1155Order`.
    function _feesHash(Fee[] memory fees) private pure returns (bytes32 feesHash) {
        uint256 numFees = fees.length;
        // We give `fees.length == 0` and `fees.length == 1`
        // special treatment because we expect these to be the most common.
        if (numFees == 0) {
            feesHash = _EMPTY_ARRAY_KECCAK256;
        } else if (numFees == 1) {
            // feesHash = keccak256(abi.encodePacked(keccak256(abi.encode(
            //     _FEE_TYPEHASH,
            //     fees[0].recipient,
            //     fees[0].amount,
            //     keccak256(fees[0].feeData)
            // ))));
            Fee memory fee = fees[0];
            bytes32 dataHash = keccak256(fee.feeData);
            assembly {
                // Load free memory pointer
                let mem := mload(64)
                mstore(mem, _FEE_TYPEHASH)
                // fee.recipient
                mstore(add(mem, 32), and(ADDRESS_MASK, mload(fee)))
                // fee.amount
                mstore(add(mem, 64), mload(add(fee, 32)))
                // keccak256(fee.feeData)
                mstore(add(mem, 96), dataHash)
                mstore(mem, keccak256(mem, 128))
                feesHash := keccak256(mem, 32)
            }
        } else {
            bytes32[] memory feeStructHashArray = new bytes32[](numFees);
            for (uint256 i = 0; i < numFees; i++) {
                feeStructHashArray[i] = keccak256(
                    abi.encode(_FEE_TYPEHASH, fees[i].recipient, fees[i].amount, keccak256(fees[i].feeData))
                );
            }
            assembly {
                feesHash := keccak256(add(feeStructHashArray, 32), mul(numFees, 32))
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "../../errors/LibSignatureRichErrors.sol";

/// @dev A library for validating signatures.
library LibSignature {
    using LibRichErrorsV06 for bytes;

    // '\x19Ethereum Signed Message:\n32\x00\x00\x00\x00' in a word.
    uint256 private constant ETH_SIGN_HASH_PREFIX = 0x19457468657265756d205369676e6564204d6573736167653a0a333200000000;
    /// @dev Exclusive upper limit on ECDSA signatures 'R' values.
    ///      The valid range is given by fig (282) of the yellow paper.
    uint256 private constant ECDSA_SIGNATURE_R_LIMIT =
        uint256(0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141);
    /// @dev Exclusive upper limit on ECDSA signatures 'S' values.
    ///      The valid range is given by fig (283) of the yellow paper.
    uint256 private constant ECDSA_SIGNATURE_S_LIMIT = ECDSA_SIGNATURE_R_LIMIT / 2 + 1;

    /// @dev Allowed signature types.
    enum SignatureType {
        ILLEGAL,
        INVALID,
        EIP712,
        ETHSIGN,
        PRESIGNED
    }

    /// @dev Encoded EC signature.
    struct Signature {
        // How to validate the signature.
        SignatureType signatureType;
        // EC Signature data.
        uint8 v;
        // EC Signature data.
        bytes32 r;
        // EC Signature data.
        bytes32 s;
    }

    /// @dev Retrieve the signer of a signature.
    ///      Throws if the signature can't be validated.
    /// @param hash The hash that was signed.
    /// @param signature The signature.
    /// @return recovered The recovered signer address.
    function getSignerOfHash(bytes32 hash, Signature memory signature) internal pure returns (address recovered) {
        // Ensure this is a signature type that can be validated against a hash.
        _validateHashCompatibleSignature(hash, signature);

        if (signature.signatureType == SignatureType.EIP712) {
            // Signed using EIP712
            recovered = ecrecover(hash, signature.v, signature.r, signature.s);
        } else if (signature.signatureType == SignatureType.ETHSIGN) {
            // Signed using `eth_sign`
            // Need to hash `hash` with "\x19Ethereum Signed Message:\n32" prefix
            // in packed encoding.
            bytes32 ethSignHash;
            assembly {
                // Use scratch space
                mstore(0, ETH_SIGN_HASH_PREFIX) // length of 28 bytes
                mstore(28, hash) // length of 32 bytes
                ethSignHash := keccak256(0, 60)
            }
            recovered = ecrecover(ethSignHash, signature.v, signature.r, signature.s);
        }
        // `recovered` can be null if the signature values are out of range.
        if (recovered == address(0)) {
            LibSignatureRichErrors
                .SignatureValidationError(LibSignatureRichErrors.SignatureValidationErrorCodes.BAD_SIGNATURE_DATA, hash)
                .rrevert();
        }
    }

    /// @dev Validates that a signature is compatible with a hash signee.
    /// @param hash The hash that was signed.
    /// @param signature The signature.
    function _validateHashCompatibleSignature(bytes32 hash, Signature memory signature) private pure {
        // Ensure the r and s are within malleability limits.
        if (uint256(signature.r) >= ECDSA_SIGNATURE_R_LIMIT || uint256(signature.s) >= ECDSA_SIGNATURE_S_LIMIT) {
            LibSignatureRichErrors
                .SignatureValidationError(LibSignatureRichErrors.SignatureValidationErrorCodes.BAD_SIGNATURE_DATA, hash)
                .rrevert();
        }

        // Always illegal signature.
        if (signature.signatureType == SignatureType.ILLEGAL) {
            LibSignatureRichErrors
                .SignatureValidationError(LibSignatureRichErrors.SignatureValidationErrorCodes.ILLEGAL, hash)
                .rrevert();
        }

        // Always invalid.
        if (signature.signatureType == SignatureType.INVALID) {
            LibSignatureRichErrors
                .SignatureValidationError(LibSignatureRichErrors.SignatureValidationErrorCodes.ALWAYS_INVALID, hash)
                .rrevert();
        }

        // If a feature supports pre-signing, it wouldn't use
        // `getSignerOfHash` on a pre-signed order.
        if (signature.signatureType == SignatureType.PRESIGNED) {
            LibSignatureRichErrors
                .SignatureValidationError(LibSignatureRichErrors.SignatureValidationErrorCodes.UNSUPPORTED, hash)
                .rrevert();
        }

        // Solidity should check that the signature type is within enum range for us
        // when abi-decoding.
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "../errors/LibLiquidityProviderRichErrors.sol";
import "../external/ILiquidityProviderSandbox.sol";
import "../external/LiquidityProviderSandbox.sol";
import "../fixins/FixinCommon.sol";
import "../fixins/FixinTokenSpender.sol";
import "../migrations/LibMigrate.sol";
import "../transformers/LibERC20Transformer.sol";
import "./interfaces/IFeature.sol";
import "./interfaces/ILiquidityProviderFeature.sol";

contract LiquidityProviderFeature is IFeature, ILiquidityProviderFeature, FixinCommon, FixinTokenSpender {
    using LibSafeMathV06 for uint256;
    using LibRichErrorsV06 for bytes;

    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "LiquidityProviderFeature";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 4);

    /// @dev The sandbox contract address.
    ILiquidityProviderSandbox public immutable sandbox;

    constructor(LiquidityProviderSandbox sandbox_) public FixinCommon() {
        sandbox = sandbox_;
    }

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external returns (bytes4 success) {
        _registerFeatureFunction(this.sellToLiquidityProvider.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @dev Sells `sellAmount` of `inputToken` to the liquidity provider
    ///      at the given `provider` address.
    /// @param inputToken The token being sold.
    /// @param outputToken The token being bought.
    /// @param provider The address of the on-chain liquidity provider
    ///        to trade with.
    /// @param recipient The recipient of the bought tokens. If equal to
    ///        address(0), `msg.sender` is assumed to be the recipient.
    /// @param sellAmount The amount of `inputToken` to sell.
    /// @param minBuyAmount The minimum acceptable amount of `outputToken` to
    ///        buy. Reverts if this amount is not satisfied.
    /// @param auxiliaryData Auxiliary data supplied to the `provider` contract.
    /// @return boughtAmount The amount of `outputToken` bought.
    function sellToLiquidityProvider(
        IERC20TokenV06 inputToken,
        IERC20TokenV06 outputToken,
        ILiquidityProvider provider,
        address recipient,
        uint256 sellAmount,
        uint256 minBuyAmount,
        bytes calldata auxiliaryData
    ) external payable override returns (uint256 boughtAmount) {
        if (recipient == address(0)) {
            recipient = msg.sender;
        }

        // Forward all attached ETH to the provider.
        if (msg.value > 0) {
            payable(address(provider)).transfer(msg.value);
        }

        if (!LibERC20Transformer.isTokenETH(inputToken)) {
            // Transfer input ERC20 tokens to the provider.
            _transferERC20TokensFrom(inputToken, msg.sender, address(provider), sellAmount);
        }

        if (LibERC20Transformer.isTokenETH(inputToken)) {
            uint256 balanceBefore = outputToken.balanceOf(recipient);
            sandbox.executeSellEthForToken(provider, outputToken, recipient, minBuyAmount, auxiliaryData);
            boughtAmount = IERC20TokenV06(outputToken).balanceOf(recipient).safeSub(balanceBefore);
        } else if (LibERC20Transformer.isTokenETH(outputToken)) {
            uint256 balanceBefore = recipient.balance;
            sandbox.executeSellTokenForEth(provider, inputToken, recipient, minBuyAmount, auxiliaryData);
            boughtAmount = recipient.balance.safeSub(balanceBefore);
        } else {
            uint256 balanceBefore = outputToken.balanceOf(recipient);
            sandbox.executeSellTokenForToken(provider, inputToken, outputToken, recipient, minBuyAmount, auxiliaryData);
            boughtAmount = outputToken.balanceOf(recipient).safeSub(balanceBefore);
        }

        if (boughtAmount < minBuyAmount) {
            LibLiquidityProviderRichErrors
                .LiquidityProviderIncompleteSellError(
                    address(provider),
                    address(outputToken),
                    address(inputToken),
                    sellAmount,
                    boughtAmount,
                    minBuyAmount
                )
                .rrevert();
        }

        emit LiquidityProviderSwap(inputToken, outputToken, sellAmount, boughtAmount, provider, recipient);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibBytesV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../errors/LibMetaTransactionsRichErrors.sol";
import "../fixins/FixinCommon.sol";
import "../fixins/FixinReentrancyGuard.sol";
import "../fixins/FixinTokenSpender.sol";
import "../fixins/FixinEIP712.sol";
import "../migrations/LibMigrate.sol";
import "../storage/LibMetaTransactionsStorage.sol";
import "./interfaces/IFeature.sol";
import "./interfaces/IMetaTransactionsFeature.sol";
import "./interfaces/INativeOrdersFeature.sol";
import "./interfaces/ITransformERC20Feature.sol";
import "./libs/LibSignature.sol";

/// @dev MetaTransactions feature.
contract MetaTransactionsFeature is
    IFeature,
    IMetaTransactionsFeature,
    FixinCommon,
    FixinReentrancyGuard,
    FixinEIP712,
    FixinTokenSpender
{
    using LibBytesV06 for bytes;
    using LibRichErrorsV06 for bytes;

    /// @dev Describes the state of a meta transaction.
    struct ExecuteState {
        // Sender of the meta-transaction.
        address sender;
        // Hash of the meta-transaction data.
        bytes32 hash;
        // The meta-transaction data.
        MetaTransactionData mtx;
        // The meta-transaction signature (by `mtx.signer`).
        LibSignature.Signature signature;
        // The selector of the function being called.
        bytes4 selector;
        // The ETH balance of this contract before performing the call.
        uint256 selfBalance;
        // The block number at which the meta-transaction was executed.
        uint256 executedBlockNumber;
    }

    /// @dev Arguments for a `TransformERC20.transformERC20()` call.
    struct ExternalTransformERC20Args {
        IERC20TokenV06 inputToken;
        IERC20TokenV06 outputToken;
        uint256 inputTokenAmount;
        uint256 minOutputTokenAmount;
        ITransformERC20Feature.Transformation[] transformations;
    }

    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "MetaTransactions";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 2, 1);
    /// @dev EIP712 typehash of the `MetaTransactionData` struct.
    bytes32 public immutable MTX_EIP712_TYPEHASH =
        keccak256(
            "MetaTransactionData("
            "address signer,"
            "address sender,"
            "uint256 minGasPrice,"
            "uint256 maxGasPrice,"
            "uint256 expirationTimeSeconds,"
            "uint256 salt,"
            "bytes callData,"
            "uint256 value,"
            "address feeToken,"
            "uint256 feeAmount"
            ")"
        );

    /// @dev Refunds up to `msg.value` leftover ETH at the end of the call.
    modifier refundsAttachedEth() {
        _;
        uint256 remainingBalance = LibSafeMathV06.min256(msg.value, address(this).balance);
        if (remainingBalance > 0) {
            msg.sender.transfer(remainingBalance);
        }
    }

    /// @dev Ensures that the ETH balance of `this` does not go below the
    ///      initial ETH balance before the call (excluding ETH attached to the call).
    modifier doesNotReduceEthBalance() {
        uint256 initialBalance = address(this).balance - msg.value;
        _;
        require(initialBalance <= address(this).balance, "MetaTransactionsFeature/ETH_LEAK");
    }

    constructor(address zeroExAddress) public FixinCommon() FixinEIP712(zeroExAddress) {}

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external returns (bytes4 success) {
        _registerFeatureFunction(this.executeMetaTransaction.selector);
        _registerFeatureFunction(this.batchExecuteMetaTransactions.selector);
        _registerFeatureFunction(this.getMetaTransactionExecutedBlock.selector);
        _registerFeatureFunction(this.getMetaTransactionHashExecutedBlock.selector);
        _registerFeatureFunction(this.getMetaTransactionHash.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @dev Execute a single meta-transaction.
    /// @param mtx The meta-transaction.
    /// @param signature The signature by `mtx.signer`.
    /// @return returnResult The ABI-encoded result of the underlying call.
    function executeMetaTransaction(
        MetaTransactionData memory mtx,
        LibSignature.Signature memory signature
    )
        public
        payable
        override
        nonReentrant(REENTRANCY_MTX)
        doesNotReduceEthBalance
        refundsAttachedEth
        returns (bytes memory returnResult)
    {
        ExecuteState memory state;
        state.sender = msg.sender;
        state.mtx = mtx;
        state.hash = getMetaTransactionHash(mtx);
        state.signature = signature;

        returnResult = _executeMetaTransactionPrivate(state);
    }

    /// @dev Execute multiple meta-transactions.
    /// @param mtxs The meta-transactions.
    /// @param signatures The signature by each respective `mtx.signer`.
    /// @return returnResults The ABI-encoded results of the underlying calls.
    function batchExecuteMetaTransactions(
        MetaTransactionData[] memory mtxs,
        LibSignature.Signature[] memory signatures
    )
        public
        payable
        override
        nonReentrant(REENTRANCY_MTX)
        doesNotReduceEthBalance
        refundsAttachedEth
        returns (bytes[] memory returnResults)
    {
        if (mtxs.length != signatures.length) {
            LibMetaTransactionsRichErrors
                .InvalidMetaTransactionsArrayLengthsError(mtxs.length, signatures.length)
                .rrevert();
        }
        returnResults = new bytes[](mtxs.length);
        for (uint256 i = 0; i < mtxs.length; ++i) {
            ExecuteState memory state;
            state.sender = msg.sender;
            state.mtx = mtxs[i];
            state.hash = getMetaTransactionHash(mtxs[i]);
            state.signature = signatures[i];

            returnResults[i] = _executeMetaTransactionPrivate(state);
        }
    }

    /// @dev Get the block at which a meta-transaction has been executed.
    /// @param mtx The meta-transaction.
    /// @return blockNumber The block height when the meta-transactioin was executed.
    function getMetaTransactionExecutedBlock(
        MetaTransactionData memory mtx
    ) public view override returns (uint256 blockNumber) {
        return getMetaTransactionHashExecutedBlock(getMetaTransactionHash(mtx));
    }

    /// @dev Get the block at which a meta-transaction hash has been executed.
    /// @param mtxHash The meta-transaction hash.
    /// @return blockNumber The block height when the meta-transactioin was executed.
    function getMetaTransactionHashExecutedBlock(bytes32 mtxHash) public view override returns (uint256 blockNumber) {
        return LibMetaTransactionsStorage.getStorage().mtxHashToExecutedBlockNumber[mtxHash];
    }

    /// @dev Get the EIP712 hash of a meta-transaction.
    /// @param mtx The meta-transaction.
    /// @return mtxHash The EIP712 hash of `mtx`.
    function getMetaTransactionHash(MetaTransactionData memory mtx) public view override returns (bytes32 mtxHash) {
        return
            _getEIP712Hash(
                keccak256(
                    abi.encode(
                        MTX_EIP712_TYPEHASH,
                        mtx.signer,
                        mtx.sender,
                        mtx.minGasPrice,
                        mtx.maxGasPrice,
                        mtx.expirationTimeSeconds,
                        mtx.salt,
                        keccak256(mtx.callData),
                        mtx.value,
                        mtx.feeToken,
                        mtx.feeAmount
                    )
                )
            );
    }

    /// @dev Execute a meta-transaction by `sender`. Low-level, hidden variant.
    /// @param state The `ExecuteState` for this metatransaction, with `sender`,
    ///              `hash`, `mtx`, and `signature` fields filled.
    /// @return returnResult The ABI-encoded result of the underlying call.
    function _executeMetaTransactionPrivate(ExecuteState memory state) private returns (bytes memory returnResult) {
        _validateMetaTransaction(state);

        // Mark the transaction executed by storing the block at which it was executed.
        // Currently the block number just indicates that the mtx was executed and
        // serves no other purpose from within this contract.
        LibMetaTransactionsStorage.getStorage().mtxHashToExecutedBlockNumber[state.hash] = block.number;

        // Pay the fee to the sender.
        if (state.mtx.feeAmount > 0) {
            _transferERC20TokensFrom(state.mtx.feeToken, state.mtx.signer, state.sender, state.mtx.feeAmount);
        }

        // Execute the call based on the selector.
        state.selector = state.mtx.callData.readBytes4(0);
        if (state.selector == ITransformERC20Feature.transformERC20.selector) {
            returnResult = _executeTransformERC20Call(state);
        } else if (state.selector == INativeOrdersFeature.fillLimitOrder.selector) {
            returnResult = _executeFillLimitOrderCall(state);
        } else if (state.selector == INativeOrdersFeature.fillRfqOrder.selector) {
            returnResult = _executeFillRfqOrderCall(state);
        } else {
            LibMetaTransactionsRichErrors.MetaTransactionUnsupportedFunctionError(state.hash, state.selector).rrevert();
        }
        emit MetaTransactionExecuted(state.hash, state.selector, state.mtx.signer, state.mtx.sender);
    }

    /// @dev Validate that a meta-transaction is executable.
    function _validateMetaTransaction(ExecuteState memory state) private view {
        // Must be from the required sender, if set.
        if (state.mtx.sender != address(0) && state.mtx.sender != state.sender) {
            LibMetaTransactionsRichErrors
                .MetaTransactionWrongSenderError(state.hash, state.sender, state.mtx.sender)
                .rrevert();
        }
        // Must not be expired.
        if (state.mtx.expirationTimeSeconds <= block.timestamp) {
            LibMetaTransactionsRichErrors
                .MetaTransactionExpiredError(state.hash, block.timestamp, state.mtx.expirationTimeSeconds)
                .rrevert();
        }
        // Must have a valid gas price.
        if (state.mtx.minGasPrice > tx.gasprice || state.mtx.maxGasPrice < tx.gasprice) {
            LibMetaTransactionsRichErrors
                .MetaTransactionGasPriceError(state.hash, tx.gasprice, state.mtx.minGasPrice, state.mtx.maxGasPrice)
                .rrevert();
        }
        // Must have enough ETH.
        state.selfBalance = address(this).balance;
        if (state.mtx.value > state.selfBalance) {
            LibMetaTransactionsRichErrors
                .MetaTransactionInsufficientEthError(state.hash, state.selfBalance, state.mtx.value)
                .rrevert();
        }

        if (LibSignature.getSignerOfHash(state.hash, state.signature) != state.mtx.signer) {
            LibSignatureRichErrors
                .SignatureValidationError(
                    LibSignatureRichErrors.SignatureValidationErrorCodes.WRONG_SIGNER,
                    state.hash,
                    state.mtx.signer,
                    // TODO: Remove this field from SignatureValidationError
                    //       when rich reverts are part of the protocol repo.
                    ""
                )
                .rrevert();
        }
        // Transaction must not have been already executed.
        state.executedBlockNumber = LibMetaTransactionsStorage.getStorage().mtxHashToExecutedBlockNumber[state.hash];
        if (state.executedBlockNumber != 0) {
            LibMetaTransactionsRichErrors
                .MetaTransactionAlreadyExecutedError(state.hash, state.executedBlockNumber)
                .rrevert();
        }
    }

    /// @dev Execute a `ITransformERC20Feature.transformERC20()` meta-transaction call
    ///      by decoding the call args and translating the call to the internal
    ///      `ITransformERC20Feature._transformERC20()` variant, where we can override
    ///      the taker address.
    function _executeTransformERC20Call(ExecuteState memory state) private returns (bytes memory returnResult) {
        // HACK(dorothy-zbornak): `abi.decode()` with the individual args
        // will cause a stack overflow. But we can prefix the call data with an
        // offset to transform it into the encoding for the equivalent single struct arg,
        // since decoding a single struct arg consumes far less stack space than
        // decoding multiple struct args.

        // Where the encoding for multiple args (with the selector ommitted)
        // would typically look like:
        // | argument                 |  offset |
        // |--------------------------|---------|
        // | inputToken               |       0 |
        // | outputToken              |      32 |
        // | inputTokenAmount         |      64 |
        // | minOutputTokenAmount     |      96 |
        // | transformations (offset) |     128 | = 32
        // | transformations (data)   |     160 |

        // We will ABI-decode a single struct arg copy with the layout:
        // | argument                 |  offset |
        // |--------------------------|---------|
        // | (arg 1 offset)           |       0 | = 32
        // | inputToken               |      32 |
        // | outputToken              |      64 |
        // | inputTokenAmount         |      96 |
        // | minOutputTokenAmount     |     128 |
        // | transformations (offset) |     160 | = 32
        // | transformations (data)   |     192 |

        ExternalTransformERC20Args memory args;
        {
            bytes memory encodedStructArgs = new bytes(state.mtx.callData.length - 4 + 32);
            // Copy the args data from the original, after the new struct offset prefix.
            bytes memory fromCallData = state.mtx.callData;
            assert(fromCallData.length >= 160);
            uint256 fromMem;
            uint256 toMem;
            assembly {
                // Prefix the calldata with a struct offset,
                // which points to just one word over.
                mstore(add(encodedStructArgs, 32), 32)
                // Copy everything after the selector.
                fromMem := add(fromCallData, 36)
                // Start copying after the struct offset.
                toMem := add(encodedStructArgs, 64)
            }
            LibBytesV06.memCopy(toMem, fromMem, fromCallData.length - 4);
            // Decode call args for `ITransformERC20Feature.transformERC20()` as a struct.
            args = abi.decode(encodedStructArgs, (ExternalTransformERC20Args));
        }
        // Call `ITransformERC20Feature._transformERC20()` (internal variant).
        return
            _callSelf(
                state.hash,
                abi.encodeWithSelector(
                    ITransformERC20Feature._transformERC20.selector,
                    ITransformERC20Feature.TransformERC20Args({
                        taker: state.mtx.signer, // taker is mtx signer
                        inputToken: args.inputToken,
                        outputToken: args.outputToken,
                        inputTokenAmount: args.inputTokenAmount,
                        minOutputTokenAmount: args.minOutputTokenAmount,
                        transformations: args.transformations,
                        useSelfBalance: false,
                        recipient: state.mtx.signer
                    })
                ),
                state.mtx.value
            );
    }

    /// @dev Extract arguments from call data by copying everything after the
    ///      4-byte selector into a new byte array.
    /// @param callData The call data from which arguments are to be extracted.
    /// @return args The extracted arguments as a byte array.
    function _extractArgumentsFromCallData(bytes memory callData) private pure returns (bytes memory args) {
        args = new bytes(callData.length - 4);
        uint256 fromMem;
        uint256 toMem;

        assembly {
            fromMem := add(callData, 36) // skip length and 4-byte selector
            toMem := add(args, 32) // write after length prefix
        }

        LibBytesV06.memCopy(toMem, fromMem, args.length);

        return args;
    }

    /// @dev Execute a `INativeOrdersFeature.fillLimitOrder()` meta-transaction call
    ///      by decoding the call args and translating the call to the internal
    ///      `INativeOrdersFeature._fillLimitOrder()` variant, where we can override
    ///      the taker address.
    function _executeFillLimitOrderCall(ExecuteState memory state) private returns (bytes memory returnResult) {
        LibNativeOrder.LimitOrder memory order;
        LibSignature.Signature memory signature;
        uint128 takerTokenFillAmount;

        bytes memory args = _extractArgumentsFromCallData(state.mtx.callData);
        (order, signature, takerTokenFillAmount) = abi.decode(
            args,
            (LibNativeOrder.LimitOrder, LibSignature.Signature, uint128)
        );

        return
            _callSelf(
                state.hash,
                abi.encodeWithSelector(
                    INativeOrdersFeature._fillLimitOrder.selector,
                    order,
                    signature,
                    takerTokenFillAmount,
                    state.mtx.signer, // taker is mtx signer
                    msg.sender
                ),
                state.mtx.value
            );
    }

    /// @dev Execute a `INativeOrdersFeature.fillRfqOrder()` meta-transaction call
    ///      by decoding the call args and translating the call to the internal
    ///      `INativeOrdersFeature._fillRfqOrder()` variant, where we can overrideunimpleme
    ///      the taker address.
    function _executeFillRfqOrderCall(ExecuteState memory state) private returns (bytes memory returnResult) {
        LibNativeOrder.RfqOrder memory order;
        LibSignature.Signature memory signature;
        uint128 takerTokenFillAmount;

        bytes memory args = _extractArgumentsFromCallData(state.mtx.callData);
        (order, signature, takerTokenFillAmount) = abi.decode(
            args,
            (LibNativeOrder.RfqOrder, LibSignature.Signature, uint128)
        );

        return
            _callSelf(
                state.hash,
                abi.encodeWithSelector(
                    INativeOrdersFeature._fillRfqOrder.selector,
                    order,
                    signature,
                    takerTokenFillAmount,
                    state.mtx.signer, // taker is mtx signer
                    false,
                    state.mtx.signer
                ),
                state.mtx.value
            );
    }

    /// @dev Make an arbitrary internal, meta-transaction call.
    ///      Warning: Do not let unadulterated `callData` into this function.
    function _callSelf(bytes32 hash, bytes memory callData, uint256 value) private returns (bytes memory returnResult) {
        bool success;
        (success, returnResult) = address(this).call{value: value}(callData);
        if (!success) {
            LibMetaTransactionsRichErrors.MetaTransactionCallFailedError(hash, callData, returnResult).rrevert();
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IEtherTokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../../external/ILiquidityProviderSandbox.sol";
import "../../fixins/FixinCommon.sol";
import "../../fixins/FixinEIP712.sol";
import "../../migrations/LibMigrate.sol";
import "../interfaces/IFeature.sol";
import "../interfaces/IMultiplexFeature.sol";
import "./MultiplexLiquidityProvider.sol";
import "./MultiplexOtc.sol";
import "./MultiplexRfq.sol";
import "./MultiplexTransformERC20.sol";
import "./MultiplexUniswapV2.sol";
import "./MultiplexUniswapV3.sol";

/// @dev This feature enables efficient batch and multi-hop trades
///      using different liquidity sources.
contract MultiplexFeature is
    IFeature,
    IMultiplexFeature,
    FixinCommon,
    MultiplexLiquidityProvider,
    MultiplexOtc,
    MultiplexRfq,
    MultiplexTransformERC20,
    MultiplexUniswapV2,
    MultiplexUniswapV3
{
    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "MultiplexFeature";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(2, 0, 0);
    /// @dev The highest bit of a uint256 value.
    uint256 private constant HIGH_BIT = 2 ** 255;
    /// @dev Mask of the lower 255 bits of a uint256 value.
    uint256 private constant LOWER_255_BITS = HIGH_BIT - 1;

    /// @dev The WETH token contract.
    IEtherTokenV06 private immutable WETH;

    constructor(
        address zeroExAddress,
        IEtherTokenV06 weth,
        ILiquidityProviderSandbox sandbox,
        address uniswapFactory,
        address sushiswapFactory,
        bytes32 uniswapPairInitCodeHash,
        bytes32 sushiswapPairInitCodeHash
    )
        public
        FixinEIP712(zeroExAddress)
        MultiplexLiquidityProvider(sandbox)
        MultiplexUniswapV2(uniswapFactory, sushiswapFactory, uniswapPairInitCodeHash, sushiswapPairInitCodeHash)
    {
        WETH = weth;
    }

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external returns (bytes4 success) {
        _registerFeatureFunction(this.multiplexBatchSellEthForToken.selector);
        _registerFeatureFunction(this.multiplexBatchSellTokenForEth.selector);
        _registerFeatureFunction(this.multiplexBatchSellTokenForToken.selector);
        _registerFeatureFunction(this.multiplexMultiHopSellEthForToken.selector);
        _registerFeatureFunction(this.multiplexMultiHopSellTokenForEth.selector);
        _registerFeatureFunction(this.multiplexMultiHopSellTokenForToken.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @dev Sells attached ETH for `outputToken` using the provided
    ///      calls.
    /// @param outputToken The token to buy.
    /// @param calls The calls to use to sell the attached ETH.
    /// @param minBuyAmount The minimum amount of `outputToken` that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of `outputToken` bought.
    function multiplexBatchSellEthForToken(
        IERC20TokenV06 outputToken,
        BatchSellSubcall[] memory calls,
        uint256 minBuyAmount
    ) public payable override returns (uint256 boughtAmount) {
        // Wrap ETH.
        WETH.deposit{value: msg.value}();
        // WETH is now held by this contract,
        // so `useSelfBalance` is true.
        return
            _multiplexBatchSell(
                BatchSellParams({
                    inputToken: WETH,
                    outputToken: outputToken,
                    sellAmount: msg.value,
                    calls: calls,
                    useSelfBalance: true,
                    recipient: msg.sender
                }),
                minBuyAmount
            );
    }

    /// @dev Sells `sellAmount` of the given `inputToken` for ETH
    ///      using the provided calls.
    /// @param inputToken The token to sell.
    /// @param calls The calls to use to sell the input tokens.
    /// @param sellAmount The amount of `inputToken` to sell.
    /// @param minBuyAmount The minimum amount of ETH that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of ETH bought.
    function multiplexBatchSellTokenForEth(
        IERC20TokenV06 inputToken,
        BatchSellSubcall[] memory calls,
        uint256 sellAmount,
        uint256 minBuyAmount
    ) public override returns (uint256 boughtAmount) {
        // The outputToken is implicitly WETH. The `recipient`
        // of the WETH is set to  this contract, since we
        // must unwrap the WETH and transfer the resulting ETH.
        boughtAmount = _multiplexBatchSell(
            BatchSellParams({
                inputToken: inputToken,
                outputToken: WETH,
                sellAmount: sellAmount,
                calls: calls,
                useSelfBalance: false,
                recipient: address(this)
            }),
            minBuyAmount
        );
        // Unwrap WETH.
        WETH.withdraw(boughtAmount);
        // Transfer ETH to `msg.sender`.
        _transferEth(msg.sender, boughtAmount);
    }

    /// @dev Sells `sellAmount` of the given `inputToken` for
    ///      `outputToken` using the provided calls.
    /// @param inputToken The token to sell.
    /// @param outputToken The token to buy.
    /// @param calls The calls to use to sell the input tokens.
    /// @param sellAmount The amount of `inputToken` to sell.
    /// @param minBuyAmount The minimum amount of `outputToken`
    ///        that must be bought for this function to not revert.
    /// @return boughtAmount The amount of `outputToken` bought.
    function multiplexBatchSellTokenForToken(
        IERC20TokenV06 inputToken,
        IERC20TokenV06 outputToken,
        BatchSellSubcall[] memory calls,
        uint256 sellAmount,
        uint256 minBuyAmount
    ) public override returns (uint256 boughtAmount) {
        return
            _multiplexBatchSell(
                BatchSellParams({
                    inputToken: inputToken,
                    outputToken: outputToken,
                    sellAmount: sellAmount,
                    calls: calls,
                    useSelfBalance: false,
                    recipient: msg.sender
                }),
                minBuyAmount
            );
    }

    /// @dev Executes a batch sell and checks that at least
    ///      `minBuyAmount` of `outputToken` was bought.
    /// @param params Batch sell parameters.
    /// @param minBuyAmount The minimum amount of `outputToken` that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of `outputToken` bought.
    function _multiplexBatchSell(
        BatchSellParams memory params,
        uint256 minBuyAmount
    ) private returns (uint256 boughtAmount) {
        // Cache the recipient's initial balance of the output token.
        uint256 balanceBefore = params.outputToken.balanceOf(params.recipient);
        // Execute the batch sell.
        BatchSellState memory state = _executeBatchSell(params);
        // Compute the change in balance of the output token.
        uint256 balanceDelta = params.outputToken.balanceOf(params.recipient).safeSub(balanceBefore);
        // Use the minimum of the balanceDelta and the returned bought
        // amount in case of weird tokens and whatnot.
        boughtAmount = LibSafeMathV06.min256(balanceDelta, state.boughtAmount);
        // Enforce `minBuyAmount`.
        require(boughtAmount >= minBuyAmount, "MultiplexFeature::_multiplexBatchSell/UNDERBOUGHT");
    }

    /// @dev Sells attached ETH via the given sequence of tokens
    ///      and calls. `tokens[0]` must be WETH.
    ///      The last token in `tokens` is the output token that
    ///      will ultimately be sent to `msg.sender`
    /// @param tokens The sequence of tokens to use for the sell,
    ///        i.e. `tokens[i]` will be sold for `tokens[i+1]` via
    ///        `calls[i]`.
    /// @param calls The sequence of calls to use for the sell.
    /// @param minBuyAmount The minimum amount of output tokens that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of output tokens bought.
    function multiplexMultiHopSellEthForToken(
        address[] memory tokens,
        MultiHopSellSubcall[] memory calls,
        uint256 minBuyAmount
    ) public payable override returns (uint256 boughtAmount) {
        // First token must be WETH.
        require(tokens[0] == address(WETH), "MultiplexFeature::multiplexMultiHopSellEthForToken/NOT_WETH");
        // Wrap ETH.
        WETH.deposit{value: msg.value}();
        // WETH is now held by this contract,
        // so `useSelfBalance` is true.
        return
            _multiplexMultiHopSell(
                MultiHopSellParams({
                    tokens: tokens,
                    sellAmount: msg.value,
                    calls: calls,
                    useSelfBalance: true,
                    recipient: msg.sender
                }),
                minBuyAmount
            );
    }

    /// @dev Sells `sellAmount` of the input token (`tokens[0]`)
    ///      for ETH via the given sequence of tokens and calls.
    ///      The last token in `tokens` must be WETH.
    /// @param tokens The sequence of tokens to use for the sell,
    ///        i.e. `tokens[i]` will be sold for `tokens[i+1]` via
    ///        `calls[i]`.
    /// @param calls The sequence of calls to use for the sell.
    /// @param sellAmount The amount of `inputToken` to sell.
    /// @param minBuyAmount The minimum amount of ETH that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of ETH bought.
    function multiplexMultiHopSellTokenForEth(
        address[] memory tokens,
        MultiHopSellSubcall[] memory calls,
        uint256 sellAmount,
        uint256 minBuyAmount
    ) public override returns (uint256 boughtAmount) {
        // Last token must be WETH.
        require(
            tokens[tokens.length - 1] == address(WETH),
            "MultiplexFeature::multiplexMultiHopSellTokenForEth/NOT_WETH"
        );
        // The `recipient of the WETH is set to  this contract, since
        // we must unwrap the WETH and transfer the resulting ETH.
        boughtAmount = _multiplexMultiHopSell(
            MultiHopSellParams({
                tokens: tokens,
                sellAmount: sellAmount,
                calls: calls,
                useSelfBalance: false,
                recipient: address(this)
            }),
            minBuyAmount
        );
        // Unwrap WETH.
        WETH.withdraw(boughtAmount);
        // Transfer ETH to `msg.sender`.
        _transferEth(msg.sender, boughtAmount);
    }

    /// @dev Sells `sellAmount` of the input token (`tokens[0]`)
    ///      via the given sequence of tokens and calls.
    ///      The last token in `tokens` is the output token that
    ///      will ultimately be sent to `msg.sender`
    /// @param tokens The sequence of tokens to use for the sell,
    ///        i.e. `tokens[i]` will be sold for `tokens[i+1]` via
    ///        `calls[i]`.
    /// @param calls The sequence of calls to use for the sell.
    /// @param sellAmount The amount of `inputToken` to sell.
    /// @param minBuyAmount The minimum amount of output tokens that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of output tokens bought.
    function multiplexMultiHopSellTokenForToken(
        address[] memory tokens,
        MultiHopSellSubcall[] memory calls,
        uint256 sellAmount,
        uint256 minBuyAmount
    ) public override returns (uint256 boughtAmount) {
        return
            _multiplexMultiHopSell(
                MultiHopSellParams({
                    tokens: tokens,
                    sellAmount: sellAmount,
                    calls: calls,
                    useSelfBalance: false,
                    recipient: msg.sender
                }),
                minBuyAmount
            );
    }

    /// @dev Executes a multi-hop sell and checks that at least
    ///      `minBuyAmount` of output tokens were bought.
    /// @param params Multi-hop sell parameters.
    /// @param minBuyAmount The minimum amount of output tokens that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of output tokens bought.
    function _multiplexMultiHopSell(
        MultiHopSellParams memory params,
        uint256 minBuyAmount
    ) private returns (uint256 boughtAmount) {
        // There should be one call/hop between every two tokens
        // in the path.
        // tokens[0]––calls[0]––>tokens[1]––...––calls[n-1]––>tokens[n]
        require(
            params.tokens.length == params.calls.length + 1,
            "MultiplexFeature::_multiplexMultiHopSell/MISMATCHED_ARRAY_LENGTHS"
        );
        // The output token is the last token in the path.
        IERC20TokenV06 outputToken = IERC20TokenV06(params.tokens[params.tokens.length - 1]);
        // Cache the recipient's balance of the output token.
        uint256 balanceBefore = outputToken.balanceOf(params.recipient);
        // Execute the multi-hop sell.
        MultiHopSellState memory state = _executeMultiHopSell(params);
        // Compute the change in balance of the output token.
        uint256 balanceDelta = outputToken.balanceOf(params.recipient).safeSub(balanceBefore);
        // Use the minimum of the balanceDelta and the returned bought
        // amount in case of weird tokens and whatnot.
        boughtAmount = LibSafeMathV06.min256(balanceDelta, state.outputTokenAmount);
        // Enforce `minBuyAmount`.
        require(boughtAmount >= minBuyAmount, "MultiplexFeature::_multiplexMultiHopSell/UNDERBOUGHT");
    }

    /// @dev Iterates through the constituent calls of a batch
    ///      sell and executes each one, until the full amount
    //       has been sold.
    /// @param params Batch sell parameters.
    /// @return state A struct containing the amounts of `inputToken`
    ///         sold and `outputToken` bought.
    function _executeBatchSell(BatchSellParams memory params) private returns (BatchSellState memory state) {
        // Iterate through the calls and execute each one
        // until the full amount has been sold.
        for (uint256 i = 0; i != params.calls.length; i++) {
            // Check if we've hit our target.
            if (state.soldAmount >= params.sellAmount) {
                break;
            }
            BatchSellSubcall memory subcall = params.calls[i];
            // Compute the input token amount.
            uint256 inputTokenAmount = _normalizeSellAmount(subcall.sellAmount, params.sellAmount, state.soldAmount);
            if (subcall.id == MultiplexSubcall.RFQ) {
                _batchSellRfqOrder(state, params, subcall.data, inputTokenAmount);
            } else if (subcall.id == MultiplexSubcall.OTC) {
                _batchSellOtcOrder(state, params, subcall.data, inputTokenAmount);
            } else if (subcall.id == MultiplexSubcall.UniswapV2) {
                _batchSellUniswapV2(state, params, subcall.data, inputTokenAmount);
            } else if (subcall.id == MultiplexSubcall.UniswapV3) {
                _batchSellUniswapV3(state, params, subcall.data, inputTokenAmount);
            } else if (subcall.id == MultiplexSubcall.LiquidityProvider) {
                _batchSellLiquidityProvider(state, params, subcall.data, inputTokenAmount);
            } else if (subcall.id == MultiplexSubcall.TransformERC20) {
                _batchSellTransformERC20(state, params, subcall.data, inputTokenAmount);
            } else if (subcall.id == MultiplexSubcall.MultiHopSell) {
                _nestedMultiHopSell(state, params, subcall.data, inputTokenAmount);
            } else {
                revert("MultiplexFeature::_executeBatchSell/INVALID_SUBCALL");
            }
        }
        require(state.soldAmount == params.sellAmount, "MultiplexFeature::_executeBatchSell/INCORRECT_AMOUNT_SOLD");
    }

    // This function executes a sequence of fills "hopping" through the
    // path of tokens given by `params.tokens`.
    function _executeMultiHopSell(MultiHopSellParams memory params) private returns (MultiHopSellState memory state) {
        // This variable is used for the input and output amounts of
        // each hop. After the final hop, this will contain the output
        // amount of the multi-hop fill.
        state.outputTokenAmount = params.sellAmount;
        // The first call may expect the input tokens to be held by
        // `msg.sender`, `address(this)`, or some other address.
        // Compute the expected address and transfer the input tokens
        // there if necessary.
        state.from = _computeHopTarget(params, 0);
        // If the input tokens are currently held by `msg.sender` but
        // the first hop expects them elsewhere, perform a `transferFrom`.
        if (!params.useSelfBalance && state.from != msg.sender) {
            _transferERC20TokensFrom(IERC20TokenV06(params.tokens[0]), msg.sender, state.from, params.sellAmount);
        }
        // If the input tokens are currently held by `address(this)` but
        // the first hop expects them elsewhere, perform a `transfer`.
        if (params.useSelfBalance && state.from != address(this)) {
            _transferERC20Tokens(IERC20TokenV06(params.tokens[0]), state.from, params.sellAmount);
        }
        // Iterate through the calls and execute each one.
        for (state.hopIndex = 0; state.hopIndex != params.calls.length; state.hopIndex++) {
            MultiHopSellSubcall memory subcall = params.calls[state.hopIndex];
            // Compute the recipient of the tokens that will be
            // bought by the current hop.
            state.to = _computeHopTarget(params, state.hopIndex + 1);

            if (subcall.id == MultiplexSubcall.UniswapV2) {
                _multiHopSellUniswapV2(state, params, subcall.data);
            } else if (subcall.id == MultiplexSubcall.UniswapV3) {
                _multiHopSellUniswapV3(state, subcall.data);
            } else if (subcall.id == MultiplexSubcall.LiquidityProvider) {
                _multiHopSellLiquidityProvider(state, params, subcall.data);
            } else if (subcall.id == MultiplexSubcall.BatchSell) {
                _nestedBatchSell(state, params, subcall.data);
            } else {
                revert("MultiplexFeature::_executeMultiHopSell/INVALID_SUBCALL");
            }
            // The recipient of the current hop will be the source
            // of tokens for the next hop.
            state.from = state.to;
        }
    }

    function _nestedMultiHopSell(
        IMultiplexFeature.BatchSellState memory state,
        IMultiplexFeature.BatchSellParams memory params,
        bytes memory data,
        uint256 sellAmount
    ) private {
        MultiHopSellParams memory multiHopParams;
        // Decode the tokens and calls for the nested
        // multi-hop sell.
        (multiHopParams.tokens, multiHopParams.calls) = abi.decode(data, (address[], MultiHopSellSubcall[]));
        multiHopParams.sellAmount = sellAmount;
        // If the batch sell is using input tokens held by
        // `address(this)`, then so should the nested
        // multi-hop sell.
        multiHopParams.useSelfBalance = params.useSelfBalance;
        // Likewise, the recipient of the multi-hop sell is
        // equal to the recipient of its containing batch sell.
        multiHopParams.recipient = params.recipient;
        // Execute the nested multi-hop sell.
        uint256 outputTokenAmount = _executeMultiHopSell(multiHopParams).outputTokenAmount;
        // Increment the sold and bought amounts.
        state.soldAmount = state.soldAmount.safeAdd(sellAmount);
        state.boughtAmount = state.boughtAmount.safeAdd(outputTokenAmount);
    }

    function _nestedBatchSell(
        IMultiplexFeature.MultiHopSellState memory state,
        IMultiplexFeature.MultiHopSellParams memory params,
        bytes memory data
    ) private {
        BatchSellParams memory batchSellParams;
        // Decode the calls for the nested batch sell.
        batchSellParams.calls = abi.decode(data, (BatchSellSubcall[]));
        // The input and output tokens of the batch
        // sell are the current and next tokens in
        // `params.tokens`, respectively.
        batchSellParams.inputToken = IERC20TokenV06(params.tokens[state.hopIndex]);
        batchSellParams.outputToken = IERC20TokenV06(params.tokens[state.hopIndex + 1]);
        // The `sellAmount` for the batch sell is the
        // `outputTokenAmount` from the previous hop.
        batchSellParams.sellAmount = state.outputTokenAmount;
        // If the nested batch sell is the first hop
        // and `useSelfBalance` for the containing multi-
        // hop sell is false, the nested batch sell should
        // pull tokens from `msg.sender` (so  `batchSellParams.useSelfBalance`
        // should be false). Otherwise `batchSellParams.useSelfBalance`
        // should be true.
        batchSellParams.useSelfBalance = state.hopIndex > 0 || params.useSelfBalance;
        // `state.to` has been populated with the address
        // that should receive the output tokens of the
        // batch sell.
        batchSellParams.recipient = state.to;
        // Execute the nested batch sell.
        state.outputTokenAmount = _executeBatchSell(batchSellParams).boughtAmount;
    }

    // This function computes the "target" address of hop index `i` within
    // a multi-hop sell.
    // If `i == 0`, the target is the address which should hold the input
    // tokens prior to executing `calls[0]`. Otherwise, it is the address
    // that should receive `tokens[i]` upon executing `calls[i-1]`.
    function _computeHopTarget(MultiHopSellParams memory params, uint256 i) private view returns (address target) {
        if (i == params.calls.length) {
            // The last call should send the output tokens to the
            // multi-hop sell recipient.
            target = params.recipient;
        } else {
            MultiHopSellSubcall memory subcall = params.calls[i];
            if (subcall.id == MultiplexSubcall.UniswapV2) {
                // UniswapV2 (and Sushiswap) allow tokens to be
                // transferred into the pair contract before `swap`
                // is called, so we compute the pair contract's address.
                (address[] memory tokens, bool isSushi) = abi.decode(subcall.data, (address[], bool));
                target = _computeUniswapPairAddress(tokens[0], tokens[1], isSushi);
            } else if (subcall.id == MultiplexSubcall.LiquidityProvider) {
                // Similar to UniswapV2, LiquidityProvider contracts
                // allow tokens to be transferred in before the swap
                // is executed, so we the target is the address encoded
                // in the subcall data.
                (target, ) = abi.decode(subcall.data, (address, bytes));
            } else if (subcall.id == MultiplexSubcall.UniswapV3 || subcall.id == MultiplexSubcall.BatchSell) {
                // UniswapV3 uses a callback to pull in the tokens being
                // sold to it. The callback implemented in `UniswapV3Feature`
                // can either:
                // - call `transferFrom` to move tokens from `msg.sender` to the
                //   UniswapV3 pool, or
                // - call `transfer` to move tokens from `address(this)` to the
                //   UniswapV3 pool.
                // A nested batch sell is similar, in that it can either:
                // - use tokens from `msg.sender`, or
                // - use tokens held by `address(this)`.

                // Suppose UniswapV3/BatchSell is the first call in the multi-hop
                // path. The input tokens are either held by `msg.sender`,
                // or in the case of `multiplexMultiHopSellEthForToken` WETH is
                // held by `address(this)`. The target is set accordingly.

                // If this is _not_ the first call in the multi-hop path, we
                // are dealing with an "intermediate" token in the multi-hop path,
                // which `msg.sender` may not have an allowance set for. Thus
                // target must be set to `address(this)` for `i > 0`.
                if (i == 0 && !params.useSelfBalance) {
                    target = msg.sender;
                } else {
                    target = address(this);
                }
            } else {
                revert("MultiplexFeature::_computeHopTarget/INVALID_SUBCALL");
            }
        }
        require(target != address(0), "MultiplexFeature::_computeHopTarget/TARGET_IS_NULL");
    }

    // If `rawAmount` encodes a proportion of `totalSellAmount`, this function
    // converts it to an absolute quantity. Caps the normalized amount to
    // the remaining sell amount (`totalSellAmount - soldAmount`).
    function _normalizeSellAmount(
        uint256 rawAmount,
        uint256 totalSellAmount,
        uint256 soldAmount
    ) private pure returns (uint256 normalized) {
        if ((rawAmount & HIGH_BIT) == HIGH_BIT) {
            // If the high bit of `rawAmount` is set then the lower 255 bits
            // specify a fraction of `totalSellAmount`.
            return
                LibSafeMathV06.min256(
                    (totalSellAmount * LibSafeMathV06.min256(rawAmount & LOWER_255_BITS, 1e18)) / 1e18,
                    totalSellAmount.safeSub(soldAmount)
                );
        } else {
            return LibSafeMathV06.min256(rawAmount, totalSellAmount.safeSub(soldAmount));
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../../external/ILiquidityProviderSandbox.sol";
import "../../fixins/FixinCommon.sol";
import "../../fixins/FixinTokenSpender.sol";
import "../../vendor/ILiquidityProvider.sol";
import "../interfaces/IMultiplexFeature.sol";

abstract contract MultiplexLiquidityProvider is FixinCommon, FixinTokenSpender {
    using LibERC20TokenV06 for IERC20TokenV06;
    using LibSafeMathV06 for uint256;

    // Same event fired by LiquidityProviderFeature
    event LiquidityProviderSwap(
        address inputToken,
        address outputToken,
        uint256 inputTokenAmount,
        uint256 outputTokenAmount,
        address provider,
        address recipient
    );

    /// @dev The sandbox contract address.
    ILiquidityProviderSandbox private immutable SANDBOX;

    constructor(ILiquidityProviderSandbox sandbox) internal {
        SANDBOX = sandbox;
    }

    // A payable external function that we can delegatecall to
    // swallow reverts and roll back the input token transfer.
    function _batchSellLiquidityProviderExternal(
        IMultiplexFeature.BatchSellParams calldata params,
        bytes calldata wrappedCallData,
        uint256 sellAmount
    ) external payable returns (uint256 boughtAmount) {
        // Revert if not a delegatecall.
        require(
            address(this) != _implementation,
            "MultiplexLiquidityProvider::_batchSellLiquidityProviderExternal/ONLY_DELEGATECALL"
        );

        // Decode the provider address and auxiliary data.
        (address provider, bytes memory auxiliaryData) = abi.decode(wrappedCallData, (address, bytes));

        if (params.useSelfBalance) {
            // If `useSelfBalance` is true, use the input tokens
            // held by `address(this)`.
            _transferERC20Tokens(params.inputToken, provider, sellAmount);
        } else {
            // Otherwise, transfer the input tokens from `msg.sender`.
            _transferERC20TokensFrom(params.inputToken, msg.sender, provider, sellAmount);
        }
        // Cache the recipient's balance of the output token.
        uint256 balanceBefore = params.outputToken.balanceOf(params.recipient);
        // Execute the swap.
        SANDBOX.executeSellTokenForToken(
            ILiquidityProvider(provider),
            params.inputToken,
            params.outputToken,
            params.recipient,
            0,
            auxiliaryData
        );
        // Compute amount of output token received by the
        // recipient.
        boughtAmount = params.outputToken.balanceOf(params.recipient).safeSub(balanceBefore);

        emit LiquidityProviderSwap(
            address(params.inputToken),
            address(params.outputToken),
            sellAmount,
            boughtAmount,
            provider,
            params.recipient
        );
    }

    function _batchSellLiquidityProvider(
        IMultiplexFeature.BatchSellState memory state,
        IMultiplexFeature.BatchSellParams memory params,
        bytes memory wrappedCallData,
        uint256 sellAmount
    ) internal {
        // Swallow reverts
        (bool success, bytes memory resultData) = _implementation.delegatecall(
            abi.encodeWithSelector(
                this._batchSellLiquidityProviderExternal.selector,
                params,
                wrappedCallData,
                sellAmount
            )
        );
        if (success) {
            // Decode the output token amount on success.
            uint256 boughtAmount = abi.decode(resultData, (uint256));
            // Increment the sold and bought amounts.
            state.soldAmount = state.soldAmount.safeAdd(sellAmount);
            state.boughtAmount = state.boughtAmount.safeAdd(boughtAmount);
        }
    }

    // This function is called after tokens have already been transferred
    // into the liquidity provider contract (in the previous hop).
    function _multiHopSellLiquidityProvider(
        IMultiplexFeature.MultiHopSellState memory state,
        IMultiplexFeature.MultiHopSellParams memory params,
        bytes memory wrappedCallData
    ) internal {
        IERC20TokenV06 inputToken = IERC20TokenV06(params.tokens[state.hopIndex]);
        IERC20TokenV06 outputToken = IERC20TokenV06(params.tokens[state.hopIndex + 1]);
        // Decode the provider address and auxiliary data.
        (address provider, bytes memory auxiliaryData) = abi.decode(wrappedCallData, (address, bytes));
        // Cache the recipient's balance of the output token.
        uint256 balanceBefore = outputToken.balanceOf(state.to);
        // Execute the swap.
        SANDBOX.executeSellTokenForToken(
            ILiquidityProvider(provider),
            inputToken,
            outputToken,
            state.to,
            0,
            auxiliaryData
        );
        // The previous `ouputTokenAmount` was effectively the
        // input amount for this call. Cache the value before
        // overwriting it with the new output token amount so
        // that both the input and ouput amounts can be in the
        // `LiquidityProviderSwap` event.
        uint256 sellAmount = state.outputTokenAmount;
        // Compute amount of output token received by the
        // recipient.
        state.outputTokenAmount = outputToken.balanceOf(state.to).safeSub(balanceBefore);

        emit LiquidityProviderSwap(
            address(inputToken),
            address(outputToken),
            sellAmount,
            state.outputTokenAmount,
            provider,
            state.to
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../../fixins/FixinEIP712.sol";
import "../interfaces/IMultiplexFeature.sol";
import "../interfaces/IOtcOrdersFeature.sol";
import "../libs/LibNativeOrder.sol";

abstract contract MultiplexOtc is FixinEIP712 {
    using LibSafeMathV06 for uint256;

    event ExpiredOtcOrder(bytes32 orderHash, address maker, uint64 expiry);

    function _batchSellOtcOrder(
        IMultiplexFeature.BatchSellState memory state,
        IMultiplexFeature.BatchSellParams memory params,
        bytes memory wrappedCallData,
        uint256 sellAmount
    ) internal {
        // Decode the Otc order and signature.
        (LibNativeOrder.OtcOrder memory order, LibSignature.Signature memory signature) = abi.decode(
            wrappedCallData,
            (LibNativeOrder.OtcOrder, LibSignature.Signature)
        );
        // Validate tokens.
        require(
            order.takerToken == params.inputToken && order.makerToken == params.outputToken,
            "MultiplexOtc::_batchSellOtcOrder/OTC_ORDER_INVALID_TOKENS"
        );
        // Pre-emptively check if the order is expired.
        uint64 expiry = uint64(order.expiryAndNonce >> 192);
        if (expiry <= uint64(block.timestamp)) {
            bytes32 orderHash = _getEIP712Hash(LibNativeOrder.getOtcOrderStructHash(order));
            emit ExpiredOtcOrder(orderHash, order.maker, expiry);
            return;
        }
        // Try filling the Otc order. Swallows reverts.
        try
            IOtcOrdersFeature(address(this))._fillOtcOrder(
                order,
                signature,
                sellAmount.safeDowncastToUint128(),
                msg.sender,
                params.useSelfBalance,
                params.recipient
            )
        returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount) {
            // Increment the sold and bought amounts.
            state.soldAmount = state.soldAmount.safeAdd(takerTokenFilledAmount);
            state.boughtAmount = state.boughtAmount.safeAdd(makerTokenFilledAmount);
        } catch {}
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../../fixins/FixinEIP712.sol";
import "../interfaces/IMultiplexFeature.sol";
import "../interfaces/INativeOrdersFeature.sol";
import "../libs/LibNativeOrder.sol";

abstract contract MultiplexRfq is FixinEIP712 {
    using LibSafeMathV06 for uint256;

    event ExpiredRfqOrder(bytes32 orderHash, address maker, uint64 expiry);

    function _batchSellRfqOrder(
        IMultiplexFeature.BatchSellState memory state,
        IMultiplexFeature.BatchSellParams memory params,
        bytes memory wrappedCallData,
        uint256 sellAmount
    ) internal {
        // Decode the RFQ order and signature.
        (LibNativeOrder.RfqOrder memory order, LibSignature.Signature memory signature) = abi.decode(
            wrappedCallData,
            (LibNativeOrder.RfqOrder, LibSignature.Signature)
        );
        // Pre-emptively check if the order is expired.
        if (order.expiry <= uint64(block.timestamp)) {
            bytes32 orderHash = _getEIP712Hash(LibNativeOrder.getRfqOrderStructHash(order));
            emit ExpiredRfqOrder(orderHash, order.maker, order.expiry);
            return;
        }
        // Validate tokens.
        require(
            order.takerToken == params.inputToken && order.makerToken == params.outputToken,
            "MultiplexRfq::_batchSellRfqOrder/RFQ_ORDER_INVALID_TOKENS"
        );
        // Try filling the RFQ order. Swallows reverts.
        try
            INativeOrdersFeature(address(this))._fillRfqOrder(
                order,
                signature,
                sellAmount.safeDowncastToUint128(),
                msg.sender,
                params.useSelfBalance,
                params.recipient
            )
        returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount) {
            // Increment the sold and bought amounts.
            state.soldAmount = state.soldAmount.safeAdd(takerTokenFilledAmount);
            state.boughtAmount = state.boughtAmount.safeAdd(makerTokenFilledAmount);
        } catch {}
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../interfaces/IMultiplexFeature.sol";
import "../interfaces/ITransformERC20Feature.sol";

abstract contract MultiplexTransformERC20 {
    using LibSafeMathV06 for uint256;

    function _batchSellTransformERC20(
        IMultiplexFeature.BatchSellState memory state,
        IMultiplexFeature.BatchSellParams memory params,
        bytes memory wrappedCallData,
        uint256 sellAmount
    ) internal {
        ITransformERC20Feature.TransformERC20Args memory args;
        // We want the TransformedERC20 event to have
        // `msg.sender` as the taker.
        args.taker = msg.sender;
        args.inputToken = params.inputToken;
        args.outputToken = params.outputToken;
        args.inputTokenAmount = sellAmount;
        args.minOutputTokenAmount = 0;
        args.useSelfBalance = params.useSelfBalance;
        args.recipient = payable(params.recipient);
        (args.transformations) = abi.decode(wrappedCallData, (ITransformERC20Feature.Transformation[]));
        // Execute the transformations and swallow reverts.
        try ITransformERC20Feature(address(this))._transformERC20(args) returns (uint256 outputTokenAmount) {
            // Increment the sold and bought amounts.
            state.soldAmount = state.soldAmount.safeAdd(sellAmount);
            state.boughtAmount = state.boughtAmount.safeAdd(outputTokenAmount);
        } catch {}
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../../fixins/FixinCommon.sol";
import "../../fixins/FixinTokenSpender.sol";
import "../../vendor/IUniswapV2Pair.sol";
import "../interfaces/IMultiplexFeature.sol";

abstract contract MultiplexUniswapV2 is FixinCommon, FixinTokenSpender {
    using LibSafeMathV06 for uint256;

    // address of the UniswapV2Factory contract.
    address private immutable UNISWAP_FACTORY;
    // address of the (Sushiswap) UniswapV2Factory contract.
    address private immutable SUSHISWAP_FACTORY;
    // Init code hash of the UniswapV2Pair contract.
    bytes32 private immutable UNISWAP_PAIR_INIT_CODE_HASH;
    // Init code hash of the (Sushiswap) UniswapV2Pair contract.
    bytes32 private immutable SUSHISWAP_PAIR_INIT_CODE_HASH;

    constructor(
        address uniswapFactory,
        address sushiswapFactory,
        bytes32 uniswapPairInitCodeHash,
        bytes32 sushiswapPairInitCodeHash
    ) internal {
        UNISWAP_FACTORY = uniswapFactory;
        SUSHISWAP_FACTORY = sushiswapFactory;
        UNISWAP_PAIR_INIT_CODE_HASH = uniswapPairInitCodeHash;
        SUSHISWAP_PAIR_INIT_CODE_HASH = sushiswapPairInitCodeHash;
    }

    // A payable external function that we can delegatecall to
    // swallow reverts and roll back the input token transfer.
    function _batchSellUniswapV2External(
        IMultiplexFeature.BatchSellParams calldata params,
        bytes calldata wrappedCallData,
        uint256 sellAmount
    ) external payable returns (uint256 boughtAmount) {
        // Revert is not a delegatecall.
        require(
            address(this) != _implementation,
            "MultiplexLiquidityProvider::_batchSellUniswapV2External/ONLY_DELEGATECALL"
        );

        (address[] memory tokens, bool isSushi) = abi.decode(wrappedCallData, (address[], bool));
        // Validate tokens
        require(
            tokens.length >= 2 &&
                tokens[0] == address(params.inputToken) &&
                tokens[tokens.length - 1] == address(params.outputToken),
            "MultiplexUniswapV2::_batchSellUniswapV2/INVALID_TOKENS"
        );
        // Compute the address of the first Uniswap pair
        // contract that will execute a swap.
        address firstPairAddress = _computeUniswapPairAddress(tokens[0], tokens[1], isSushi);
        // `_sellToUniswapV2` assumes the input tokens have been
        // transferred into the pair contract before it is called,
        // so we transfer the tokens in now (either from `msg.sender`
        // or using the Exchange Proxy's balance).
        if (params.useSelfBalance) {
            _transferERC20Tokens(IERC20TokenV06(tokens[0]), firstPairAddress, sellAmount);
        } else {
            _transferERC20TokensFrom(IERC20TokenV06(tokens[0]), msg.sender, firstPairAddress, sellAmount);
        }
        // Execute the Uniswap/Sushiswap trade.
        return _sellToUniswapV2(tokens, sellAmount, isSushi, firstPairAddress, params.recipient);
    }

    function _batchSellUniswapV2(
        IMultiplexFeature.BatchSellState memory state,
        IMultiplexFeature.BatchSellParams memory params,
        bytes memory wrappedCallData,
        uint256 sellAmount
    ) internal {
        // Swallow reverts
        (bool success, bytes memory resultData) = _implementation.delegatecall(
            abi.encodeWithSelector(this._batchSellUniswapV2External.selector, params, wrappedCallData, sellAmount)
        );
        if (success) {
            // Decode the output token amount on success.
            uint256 boughtAmount = abi.decode(resultData, (uint256));
            // Increment the sold and bought amounts.
            state.soldAmount = state.soldAmount.safeAdd(sellAmount);
            state.boughtAmount = state.boughtAmount.safeAdd(boughtAmount);
        }
    }

    function _multiHopSellUniswapV2(
        IMultiplexFeature.MultiHopSellState memory state,
        IMultiplexFeature.MultiHopSellParams memory params,
        bytes memory wrappedCallData
    ) internal {
        (address[] memory tokens, bool isSushi) = abi.decode(wrappedCallData, (address[], bool));
        // Validate the tokens
        require(
            tokens.length >= 2 &&
                tokens[0] == params.tokens[state.hopIndex] &&
                tokens[tokens.length - 1] == params.tokens[state.hopIndex + 1],
            "MultiplexUniswapV2::_multiHopSellUniswapV2/INVALID_TOKENS"
        );
        // Execute the Uniswap/Sushiswap trade.
        state.outputTokenAmount = _sellToUniswapV2(tokens, state.outputTokenAmount, isSushi, state.from, state.to);
    }

    function _sellToUniswapV2(
        address[] memory tokens,
        uint256 sellAmount,
        bool isSushi,
        address pairAddress,
        address recipient
    ) private returns (uint256 outputTokenAmount) {
        // Iterate through `tokens` perform a swap against the Uniswap
        // pair contract for each `(tokens[i], tokens[i+1])`.
        for (uint256 i = 0; i < tokens.length - 1; i++) {
            (address inputToken, address outputToken) = (tokens[i], tokens[i + 1]);
            // Compute the output token amount
            outputTokenAmount = _computeUniswapOutputAmount(pairAddress, inputToken, outputToken, sellAmount);
            (uint256 amount0Out, uint256 amount1Out) = inputToken < outputToken
                ? (uint256(0), outputTokenAmount)
                : (outputTokenAmount, uint256(0));
            // The Uniswap pair contract will transfer the output tokens to
            // the next pair contract if there is one, otherwise transfer to
            // `recipient`.
            address to = i < tokens.length - 2
                ? _computeUniswapPairAddress(outputToken, tokens[i + 2], isSushi)
                : recipient;
            // Execute the swap.
            IUniswapV2Pair(pairAddress).swap(amount0Out, amount1Out, to, new bytes(0));
            // To avoid recomputing the pair address of the next pair, store
            // `to` in `pairAddress`.
            pairAddress = to;
            // The outputTokenAmount
            sellAmount = outputTokenAmount;
        }
    }

    // Computes the Uniswap/Sushiswap pair contract address for the
    // given tokens.
    function _computeUniswapPairAddress(
        address tokenA,
        address tokenB,
        bool isSushi
    ) internal view returns (address pairAddress) {
        // Tokens are lexicographically sorted in the Uniswap contract.
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        if (isSushi) {
            // Use the Sushiswap factory address and codehash
            return
                address(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                hex"ff",
                                SUSHISWAP_FACTORY,
                                keccak256(abi.encodePacked(token0, token1)),
                                SUSHISWAP_PAIR_INIT_CODE_HASH
                            )
                        )
                    )
                );
        } else {
            // Use the Uniswap factory address and codehash
            return
                address(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                hex"ff",
                                UNISWAP_FACTORY,
                                keccak256(abi.encodePacked(token0, token1)),
                                UNISWAP_PAIR_INIT_CODE_HASH
                            )
                        )
                    )
                );
        }
    }

    // Computes the the amount of output token that would be bought
    // from Uniswap/Sushiswap given the input amount.
    function _computeUniswapOutputAmount(
        address pairAddress,
        address inputToken,
        address outputToken,
        uint256 inputAmount
    ) private view returns (uint256 outputAmount) {
        // Input amount should be non-zero.
        require(inputAmount > 0, "MultiplexUniswapV2::_computeUniswapOutputAmount/INSUFFICIENT_INPUT_AMOUNT");
        // Query the reserves of the pair contract.
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairAddress).getReserves();
        // Reserves must be non-zero.
        require(reserve0 > 0 && reserve1 > 0, "MultiplexUniswapV2::_computeUniswapOutputAmount/INSUFFICIENT_LIQUIDITY");
        // Tokens are lexicographically sorted in the Uniswap contract.
        (uint256 inputReserve, uint256 outputReserve) = inputToken < outputToken
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
        // Compute the output amount.
        uint256 inputAmountWithFee = inputAmount.safeMul(997);
        uint256 numerator = inputAmountWithFee.safeMul(outputReserve);
        uint256 denominator = inputReserve.safeMul(1000).safeAdd(inputAmountWithFee);
        return numerator / denominator;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../../fixins/FixinTokenSpender.sol";
import "../interfaces/IMultiplexFeature.sol";
import "../interfaces/IUniswapV3Feature.sol";

abstract contract MultiplexUniswapV3 is FixinTokenSpender {
    using LibSafeMathV06 for uint256;

    function _batchSellUniswapV3(
        IMultiplexFeature.BatchSellState memory state,
        IMultiplexFeature.BatchSellParams memory params,
        bytes memory wrappedCallData,
        uint256 sellAmount
    ) internal {
        bool success;
        bytes memory resultData;
        if (params.useSelfBalance) {
            // If the tokens are held by `address(this)`, we call
            // the `onlySelf` variant `_sellHeldTokenForTokenToUniswapV3`,
            // which uses the Exchange Proxy's balance of input token.
            (success, resultData) = address(this).call(
                abi.encodeWithSelector(
                    IUniswapV3Feature._sellHeldTokenForTokenToUniswapV3.selector,
                    wrappedCallData,
                    sellAmount,
                    0,
                    params.recipient
                )
            );
        } else {
            // Otherwise, we self-delegatecall the normal variant
            // `sellTokenForTokenToUniswapV3`, which pulls the input token
            // from `msg.sender`.
            (success, resultData) = address(this).delegatecall(
                abi.encodeWithSelector(
                    IUniswapV3Feature.sellTokenForTokenToUniswapV3.selector,
                    wrappedCallData,
                    sellAmount,
                    0,
                    params.recipient
                )
            );
        }
        if (success) {
            // Decode the output token amount on success.
            uint256 outputTokenAmount = abi.decode(resultData, (uint256));
            // Increment the sold and bought amounts.
            state.soldAmount = state.soldAmount.safeAdd(sellAmount);
            state.boughtAmount = state.boughtAmount.safeAdd(outputTokenAmount);
        }
    }

    function _multiHopSellUniswapV3(
        IMultiplexFeature.MultiHopSellState memory state,
        bytes memory wrappedCallData
    ) internal {
        bool success;
        bytes memory resultData;
        if (state.from == address(this)) {
            // If the tokens are held by `address(this)`, we call
            // the `onlySelf` variant `_sellHeldTokenForTokenToUniswapV3`,
            // which uses the Exchange Proxy's balance of input token.
            (success, resultData) = address(this).call(
                abi.encodeWithSelector(
                    IUniswapV3Feature._sellHeldTokenForTokenToUniswapV3.selector,
                    wrappedCallData,
                    state.outputTokenAmount,
                    0,
                    state.to
                )
            );
        } else {
            // Otherwise, we self-delegatecall the normal variant
            // `sellTokenForTokenToUniswapV3`, which pulls the input token
            // from `msg.sender`.
            (success, resultData) = address(this).delegatecall(
                abi.encodeWithSelector(
                    IUniswapV3Feature.sellTokenForTokenToUniswapV3.selector,
                    wrappedCallData,
                    state.outputTokenAmount,
                    0,
                    state.to
                )
            );
        }
        if (success) {
            // Decode the output token amount on success.
            state.outputTokenAmount = abi.decode(resultData, (uint256));
        } else {
            revert("MultiplexUniswapV3::_multiHopSellUniswapV3/SWAP_FAILED");
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "../../errors/LibNativeOrdersRichErrors.sol";
import "../../storage/LibNativeOrdersStorage.sol";
import "../interfaces/INativeOrdersEvents.sol";
import "../libs/LibSignature.sol";
import "../libs/LibNativeOrder.sol";
import "./NativeOrdersInfo.sol";

/// @dev Feature for cancelling limit and RFQ orders.
abstract contract NativeOrdersCancellation is INativeOrdersEvents, NativeOrdersInfo {
    using LibRichErrorsV06 for bytes;

    /// @dev Highest bit of a uint256, used to flag cancelled orders.
    uint256 private constant HIGH_BIT = 1 << 255;

    constructor(address zeroExAddress) internal NativeOrdersInfo(zeroExAddress) {}

    /// @dev Cancel a single limit order. The caller must be the maker or a valid order signer.
    ///      Silently succeeds if the order has already been cancelled.
    /// @param order The limit order.
    function cancelLimitOrder(LibNativeOrder.LimitOrder memory order) public {
        bytes32 orderHash = getLimitOrderHash(order);
        if (msg.sender != order.maker && !isValidOrderSigner(order.maker, msg.sender)) {
            LibNativeOrdersRichErrors.OnlyOrderMakerAllowed(orderHash, msg.sender, order.maker).rrevert();
        }
        _cancelOrderHash(orderHash, order.maker);
    }

    /// @dev Cancel a single RFQ order. The caller must be the maker or a valid order signer.
    ///      Silently succeeds if the order has already been cancelled.
    /// @param order The RFQ order.
    function cancelRfqOrder(LibNativeOrder.RfqOrder memory order) public {
        bytes32 orderHash = getRfqOrderHash(order);
        if (msg.sender != order.maker && !isValidOrderSigner(order.maker, msg.sender)) {
            LibNativeOrdersRichErrors.OnlyOrderMakerAllowed(orderHash, msg.sender, order.maker).rrevert();
        }
        _cancelOrderHash(orderHash, order.maker);
    }

    /// @dev Cancel multiple limit orders. The caller must be the maker or a valid order signer.
    ///      Silently succeeds if the order has already been cancelled.
    /// @param orders The limit orders.
    function batchCancelLimitOrders(LibNativeOrder.LimitOrder[] memory orders) public {
        for (uint256 i = 0; i < orders.length; ++i) {
            cancelLimitOrder(orders[i]);
        }
    }

    /// @dev Cancel multiple RFQ orders. The caller must be the maker or a valid order signer.
    ///      Silently succeeds if the order has already been cancelled.
    /// @param orders The RFQ orders.
    function batchCancelRfqOrders(LibNativeOrder.RfqOrder[] memory orders) public {
        for (uint256 i = 0; i < orders.length; ++i) {
            cancelRfqOrder(orders[i]);
        }
    }

    /// @dev Cancel all limit orders for a given maker and pair with a salt less
    ///      than the value provided. The caller must be the maker. Subsequent
    ///      calls to this function with the same caller and pair require the
    ///      new salt to be >= the old salt.
    /// @param makerToken The maker token.
    /// @param takerToken The taker token.
    /// @param minValidSalt The new minimum valid salt.
    function cancelPairLimitOrders(IERC20TokenV06 makerToken, IERC20TokenV06 takerToken, uint256 minValidSalt) public {
        _cancelPairLimitOrders(msg.sender, makerToken, takerToken, minValidSalt);
    }

    /// @dev Cancel all limit orders for a given maker and pair with a salt less
    ///      than the value provided. The caller must be a signer registered to the maker.
    ///      Subsequent calls to this function with the same caller and pair require the
    ///      new salt to be >= the old salt.
    /// @param maker the maker for whom the msg.sender is the signer.
    /// @param makerToken The maker token.
    /// @param takerToken The taker token.
    /// @param minValidSalt The new minimum valid salt.
    function cancelPairLimitOrdersWithSigner(
        address maker,
        IERC20TokenV06 makerToken,
        IERC20TokenV06 takerToken,
        uint256 minValidSalt
    ) public {
        // verify that the signer is authorized for the maker
        if (!isValidOrderSigner(maker, msg.sender)) {
            LibNativeOrdersRichErrors.InvalidSignerError(maker, msg.sender).rrevert();
        }

        _cancelPairLimitOrders(maker, makerToken, takerToken, minValidSalt);
    }

    /// @dev Cancel all limit orders for a given maker and pair with a salt less
    ///      than the value provided. The caller must be the maker. Subsequent
    ///      calls to this function with the same caller and pair require the
    ///      new salt to be >= the old salt.
    /// @param makerTokens The maker tokens.
    /// @param takerTokens The taker tokens.
    /// @param minValidSalts The new minimum valid salts.
    function batchCancelPairLimitOrders(
        IERC20TokenV06[] memory makerTokens,
        IERC20TokenV06[] memory takerTokens,
        uint256[] memory minValidSalts
    ) public {
        require(
            makerTokens.length == takerTokens.length && makerTokens.length == minValidSalts.length,
            "NativeOrdersFeature/MISMATCHED_PAIR_ORDERS_ARRAY_LENGTHS"
        );

        for (uint256 i = 0; i < makerTokens.length; ++i) {
            _cancelPairLimitOrders(msg.sender, makerTokens[i], takerTokens[i], minValidSalts[i]);
        }
    }

    /// @dev Cancel all limit orders for a given maker and pair with a salt less
    ///      than the value provided. The caller must be a signer registered to the maker.
    ///      Subsequent calls to this function with the same caller and pair require the
    ///      new salt to be >= the old salt.
    /// @param maker the maker for whom the msg.sender is the signer.
    /// @param makerTokens The maker tokens.
    /// @param takerTokens The taker tokens.
    /// @param minValidSalts The new minimum valid salts.
    function batchCancelPairLimitOrdersWithSigner(
        address maker,
        IERC20TokenV06[] memory makerTokens,
        IERC20TokenV06[] memory takerTokens,
        uint256[] memory minValidSalts
    ) public {
        require(
            makerTokens.length == takerTokens.length && makerTokens.length == minValidSalts.length,
            "NativeOrdersFeature/MISMATCHED_PAIR_ORDERS_ARRAY_LENGTHS"
        );

        if (!isValidOrderSigner(maker, msg.sender)) {
            LibNativeOrdersRichErrors.InvalidSignerError(maker, msg.sender).rrevert();
        }

        for (uint256 i = 0; i < makerTokens.length; ++i) {
            _cancelPairLimitOrders(maker, makerTokens[i], takerTokens[i], minValidSalts[i]);
        }
    }

    /// @dev Cancel all RFQ orders for a given maker and pair with a salt less
    ///      than the value provided. The caller must be the maker. Subsequent
    ///      calls to this function with the same caller and pair require the
    ///      new salt to be >= the old salt.
    /// @param makerToken The maker token.
    /// @param takerToken The taker token.
    /// @param minValidSalt The new minimum valid salt.
    function cancelPairRfqOrders(IERC20TokenV06 makerToken, IERC20TokenV06 takerToken, uint256 minValidSalt) public {
        _cancelPairRfqOrders(msg.sender, makerToken, takerToken, minValidSalt);
    }

    /// @dev Cancel all RFQ orders for a given maker and pair with a salt less
    ///      than the value provided. The caller must be a signer registered to the maker.
    ///      Subsequent calls to this function with the same caller and pair require the
    ///      new salt to be >= the old salt.
    /// @param maker the maker for whom the msg.sender is the signer.
    /// @param makerToken The maker token.
    /// @param takerToken The taker token.
    /// @param minValidSalt The new minimum valid salt.
    function cancelPairRfqOrdersWithSigner(
        address maker,
        IERC20TokenV06 makerToken,
        IERC20TokenV06 takerToken,
        uint256 minValidSalt
    ) public {
        if (!isValidOrderSigner(maker, msg.sender)) {
            LibNativeOrdersRichErrors.InvalidSignerError(maker, msg.sender).rrevert();
        }

        _cancelPairRfqOrders(maker, makerToken, takerToken, minValidSalt);
    }

    /// @dev Cancel all RFQ orders for a given maker and pair with a salt less
    ///      than the value provided. The caller must be the maker. Subsequent
    ///      calls to this function with the same caller and pair require the
    ///      new salt to be >= the old salt.
    /// @param makerTokens The maker tokens.
    /// @param takerTokens The taker tokens.
    /// @param minValidSalts The new minimum valid salts.
    function batchCancelPairRfqOrders(
        IERC20TokenV06[] memory makerTokens,
        IERC20TokenV06[] memory takerTokens,
        uint256[] memory minValidSalts
    ) public {
        require(
            makerTokens.length == takerTokens.length && makerTokens.length == minValidSalts.length,
            "NativeOrdersFeature/MISMATCHED_PAIR_ORDERS_ARRAY_LENGTHS"
        );

        for (uint256 i = 0; i < makerTokens.length; ++i) {
            _cancelPairRfqOrders(msg.sender, makerTokens[i], takerTokens[i], minValidSalts[i]);
        }
    }

    /// @dev Cancel all RFQ orders for a given maker and pairs with salts less
    ///      than the values provided. The caller must be a signer registered to the maker.
    ///      Subsequent calls to this function with the same caller and pair require the
    ///      new salt to be >= the old salt.
    /// @param maker the maker for whom the msg.sender is the signer.
    /// @param makerTokens The maker tokens.
    /// @param takerTokens The taker tokens.
    /// @param minValidSalts The new minimum valid salts.
    function batchCancelPairRfqOrdersWithSigner(
        address maker,
        IERC20TokenV06[] memory makerTokens,
        IERC20TokenV06[] memory takerTokens,
        uint256[] memory minValidSalts
    ) public {
        require(
            makerTokens.length == takerTokens.length && makerTokens.length == minValidSalts.length,
            "NativeOrdersFeature/MISMATCHED_PAIR_ORDERS_ARRAY_LENGTHS"
        );

        if (!isValidOrderSigner(maker, msg.sender)) {
            LibNativeOrdersRichErrors.InvalidSignerError(maker, msg.sender).rrevert();
        }

        for (uint256 i = 0; i < makerTokens.length; ++i) {
            _cancelPairRfqOrders(maker, makerTokens[i], takerTokens[i], minValidSalts[i]);
        }
    }

    /// @dev Cancel a limit or RFQ order directly by its order hash.
    /// @param orderHash The order's order hash.
    /// @param maker The order's maker.
    function _cancelOrderHash(bytes32 orderHash, address maker) private {
        LibNativeOrdersStorage.Storage storage stor = LibNativeOrdersStorage.getStorage();
        // Set the high bit on the raw taker token fill amount to indicate
        // a cancel. It's OK to cancel twice.
        stor.orderHashToTakerTokenFilledAmount[orderHash] |= HIGH_BIT;

        emit OrderCancelled(orderHash, maker);
    }

    /// @dev Cancel all RFQ orders for a given maker and pair with a salt less
    ///      than the value provided.
    /// @param maker The target maker address
    /// @param makerToken The maker token.
    /// @param takerToken The taker token.
    /// @param minValidSalt The new minimum valid salt.
    function _cancelPairRfqOrders(
        address maker,
        IERC20TokenV06 makerToken,
        IERC20TokenV06 takerToken,
        uint256 minValidSalt
    ) private {
        LibNativeOrdersStorage.Storage storage stor = LibNativeOrdersStorage.getStorage();

        uint256 oldMinValidSalt = stor.rfqOrdersMakerToMakerTokenToTakerTokenToMinValidOrderSalt[maker][
            address(makerToken)
        ][address(takerToken)];

        // New min salt must >= the old one.
        if (oldMinValidSalt > minValidSalt) {
            LibNativeOrdersRichErrors.CancelSaltTooLowError(minValidSalt, oldMinValidSalt).rrevert();
        }

        stor.rfqOrdersMakerToMakerTokenToTakerTokenToMinValidOrderSalt[maker][address(makerToken)][
            address(takerToken)
        ] = minValidSalt;

        emit PairCancelledRfqOrders(maker, address(makerToken), address(takerToken), minValidSalt);
    }

    /// @dev Cancel all limit orders for a given maker and pair with a salt less
    ///      than the value provided.
    /// @param maker The target maker address
    /// @param makerToken The maker token.
    /// @param takerToken The taker token.
    /// @param minValidSalt The new minimum valid salt.
    function _cancelPairLimitOrders(
        address maker,
        IERC20TokenV06 makerToken,
        IERC20TokenV06 takerToken,
        uint256 minValidSalt
    ) private {
        LibNativeOrdersStorage.Storage storage stor = LibNativeOrdersStorage.getStorage();

        uint256 oldMinValidSalt = stor.limitOrdersMakerToMakerTokenToTakerTokenToMinValidOrderSalt[maker][
            address(makerToken)
        ][address(takerToken)];

        // New min salt must >= the old one.
        if (oldMinValidSalt > minValidSalt) {
            LibNativeOrdersRichErrors.CancelSaltTooLowError(minValidSalt, oldMinValidSalt).rrevert();
        }

        stor.limitOrdersMakerToMakerTokenToTakerTokenToMinValidOrderSalt[maker][address(makerToken)][
            address(takerToken)
        ] = minValidSalt;

        emit PairCancelledLimitOrders(maker, address(makerToken), address(takerToken), minValidSalt);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibMathV06.sol";
import "../../fixins/FixinEIP712.sol";
import "../../fixins/FixinTokenSpender.sol";
import "../../storage/LibNativeOrdersStorage.sol";
import "../libs/LibSignature.sol";
import "../libs/LibNativeOrder.sol";

/// @dev Feature for getting info about limit and RFQ orders.
abstract contract NativeOrdersInfo is FixinEIP712, FixinTokenSpender {
    using LibSafeMathV06 for uint256;
    using LibRichErrorsV06 for bytes;

    // @dev Params for `_getActualFillableTakerTokenAmount()`.
    struct GetActualFillableTakerTokenAmountParams {
        address maker;
        IERC20TokenV06 makerToken;
        uint128 orderMakerAmount;
        uint128 orderTakerAmount;
        LibNativeOrder.OrderInfo orderInfo;
    }

    /// @dev Highest bit of a uint256, used to flag cancelled orders.
    uint256 private constant HIGH_BIT = 1 << 255;

    constructor(address zeroExAddress) internal FixinEIP712(zeroExAddress) {}

    /// @dev Get the order info for a limit order.
    /// @param order The limit order.
    /// @return orderInfo Info about the order.
    function getLimitOrderInfo(
        LibNativeOrder.LimitOrder memory order
    ) public view returns (LibNativeOrder.OrderInfo memory orderInfo) {
        // Recover maker and compute order hash.
        orderInfo.orderHash = getLimitOrderHash(order);
        uint256 minValidSalt = LibNativeOrdersStorage
            .getStorage()
            .limitOrdersMakerToMakerTokenToTakerTokenToMinValidOrderSalt[order.maker][address(order.makerToken)][
                address(order.takerToken)
            ];
        _populateCommonOrderInfoFields(orderInfo, order.takerAmount, order.expiry, order.salt, minValidSalt);
    }

    /// @dev Get the order info for an RFQ order.
    /// @param order The RFQ order.
    /// @return orderInfo Info about the order.
    function getRfqOrderInfo(
        LibNativeOrder.RfqOrder memory order
    ) public view returns (LibNativeOrder.OrderInfo memory orderInfo) {
        // Recover maker and compute order hash.
        orderInfo.orderHash = getRfqOrderHash(order);
        uint256 minValidSalt = LibNativeOrdersStorage
            .getStorage()
            .rfqOrdersMakerToMakerTokenToTakerTokenToMinValidOrderSalt[order.maker][address(order.makerToken)][
                address(order.takerToken)
            ];
        _populateCommonOrderInfoFields(orderInfo, order.takerAmount, order.expiry, order.salt, minValidSalt);

        // Check for missing txOrigin.
        if (order.txOrigin == address(0)) {
            orderInfo.status = LibNativeOrder.OrderStatus.INVALID;
        }
    }

    /// @dev Get the canonical hash of a limit order.
    /// @param order The limit order.
    /// @return orderHash The order hash.
    function getLimitOrderHash(LibNativeOrder.LimitOrder memory order) public view returns (bytes32 orderHash) {
        return _getEIP712Hash(LibNativeOrder.getLimitOrderStructHash(order));
    }

    /// @dev Get the canonical hash of an RFQ order.
    /// @param order The RFQ order.
    /// @return orderHash The order hash.
    function getRfqOrderHash(LibNativeOrder.RfqOrder memory order) public view returns (bytes32 orderHash) {
        return _getEIP712Hash(LibNativeOrder.getRfqOrderStructHash(order));
    }

    /// @dev Get order info, fillable amount, and signature validity for a limit order.
    ///      Fillable amount is determined using balances and allowances of the maker.
    /// @param order The limit order.
    /// @param signature The order signature.
    /// @return orderInfo Info about the order.
    /// @return actualFillableTakerTokenAmount How much of the order is fillable
    ///         based on maker funds, in taker tokens.
    /// @return isSignatureValid Whether the signature is valid.
    function getLimitOrderRelevantState(
        LibNativeOrder.LimitOrder memory order,
        LibSignature.Signature calldata signature
    )
        public
        view
        returns (
            LibNativeOrder.OrderInfo memory orderInfo,
            uint128 actualFillableTakerTokenAmount,
            bool isSignatureValid
        )
    {
        orderInfo = getLimitOrderInfo(order);
        actualFillableTakerTokenAmount = _getActualFillableTakerTokenAmount(
            GetActualFillableTakerTokenAmountParams({
                maker: order.maker,
                makerToken: order.makerToken,
                orderMakerAmount: order.makerAmount,
                orderTakerAmount: order.takerAmount,
                orderInfo: orderInfo
            })
        );
        address signerOfHash = LibSignature.getSignerOfHash(orderInfo.orderHash, signature);
        isSignatureValid = (order.maker == signerOfHash) || isValidOrderSigner(order.maker, signerOfHash);
    }

    /// @dev Get order info, fillable amount, and signature validity for an RFQ order.
    ///      Fillable amount is determined using balances and allowances of the maker.
    /// @param order The RFQ order.
    /// @param signature The order signature.
    /// @return orderInfo Info about the order.
    /// @return actualFillableTakerTokenAmount How much of the order is fillable
    ///         based on maker funds, in taker tokens.
    /// @return isSignatureValid Whether the signature is valid.
    function getRfqOrderRelevantState(
        LibNativeOrder.RfqOrder memory order,
        LibSignature.Signature memory signature
    )
        public
        view
        returns (
            LibNativeOrder.OrderInfo memory orderInfo,
            uint128 actualFillableTakerTokenAmount,
            bool isSignatureValid
        )
    {
        orderInfo = getRfqOrderInfo(order);
        actualFillableTakerTokenAmount = _getActualFillableTakerTokenAmount(
            GetActualFillableTakerTokenAmountParams({
                maker: order.maker,
                makerToken: order.makerToken,
                orderMakerAmount: order.makerAmount,
                orderTakerAmount: order.takerAmount,
                orderInfo: orderInfo
            })
        );
        address signerOfHash = LibSignature.getSignerOfHash(orderInfo.orderHash, signature);
        isSignatureValid = (order.maker == signerOfHash) || isValidOrderSigner(order.maker, signerOfHash);
    }

    /// @dev Batch version of `getLimitOrderRelevantState()`, without reverting.
    ///      Orders that would normally cause `getLimitOrderRelevantState()`
    ///      to revert will have empty results.
    /// @param orders The limit orders.
    /// @param signatures The order signatures.
    /// @return orderInfos Info about the orders.
    /// @return actualFillableTakerTokenAmounts How much of each order is fillable
    ///         based on maker funds, in taker tokens.
    /// @return isSignatureValids Whether each signature is valid for the order.
    function batchGetLimitOrderRelevantStates(
        LibNativeOrder.LimitOrder[] calldata orders,
        LibSignature.Signature[] calldata signatures
    )
        external
        view
        returns (
            LibNativeOrder.OrderInfo[] memory orderInfos,
            uint128[] memory actualFillableTakerTokenAmounts,
            bool[] memory isSignatureValids
        )
    {
        require(orders.length == signatures.length, "NativeOrdersFeature/MISMATCHED_ARRAY_LENGTHS");
        orderInfos = new LibNativeOrder.OrderInfo[](orders.length);
        actualFillableTakerTokenAmounts = new uint128[](orders.length);
        isSignatureValids = new bool[](orders.length);
        for (uint256 i = 0; i < orders.length; ++i) {
            try this.getLimitOrderRelevantState(orders[i], signatures[i]) returns (
                LibNativeOrder.OrderInfo memory orderInfo,
                uint128 actualFillableTakerTokenAmount,
                bool isSignatureValid
            ) {
                orderInfos[i] = orderInfo;
                actualFillableTakerTokenAmounts[i] = actualFillableTakerTokenAmount;
                isSignatureValids[i] = isSignatureValid;
            } catch {}
        }
    }

    /// @dev Batch version of `getRfqOrderRelevantState()`, without reverting.
    ///      Orders that would normally cause `getRfqOrderRelevantState()`
    ///      to revert will have empty results.
    /// @param orders The RFQ orders.
    /// @param signatures The order signatures.
    /// @return orderInfos Info about the orders.
    /// @return actualFillableTakerTokenAmounts How much of each order is fillable
    ///         based on maker funds, in taker tokens.
    /// @return isSignatureValids Whether each signature is valid for the order.
    function batchGetRfqOrderRelevantStates(
        LibNativeOrder.RfqOrder[] calldata orders,
        LibSignature.Signature[] calldata signatures
    )
        external
        view
        returns (
            LibNativeOrder.OrderInfo[] memory orderInfos,
            uint128[] memory actualFillableTakerTokenAmounts,
            bool[] memory isSignatureValids
        )
    {
        require(orders.length == signatures.length, "NativeOrdersFeature/MISMATCHED_ARRAY_LENGTHS");
        orderInfos = new LibNativeOrder.OrderInfo[](orders.length);
        actualFillableTakerTokenAmounts = new uint128[](orders.length);
        isSignatureValids = new bool[](orders.length);
        for (uint256 i = 0; i < orders.length; ++i) {
            try this.getRfqOrderRelevantState(orders[i], signatures[i]) returns (
                LibNativeOrder.OrderInfo memory orderInfo,
                uint128 actualFillableTakerTokenAmount,
                bool isSignatureValid
            ) {
                orderInfos[i] = orderInfo;
                actualFillableTakerTokenAmounts[i] = actualFillableTakerTokenAmount;
                isSignatureValids[i] = isSignatureValid;
            } catch {}
        }
    }

    /// @dev Populate `status` and `takerTokenFilledAmount` fields in
    ///      `orderInfo`, which use the same code path for both limit and
    ///      RFQ orders.
    /// @param orderInfo `OrderInfo` with `orderHash` and `maker` filled.
    /// @param takerAmount The order's taker token amount..
    /// @param expiry The order's expiry.
    /// @param salt The order's salt.
    /// @param salt The minimum valid salt for the maker and pair combination.
    function _populateCommonOrderInfoFields(
        LibNativeOrder.OrderInfo memory orderInfo,
        uint128 takerAmount,
        uint64 expiry,
        uint256 salt,
        uint256 minValidSalt
    ) private view {
        LibNativeOrdersStorage.Storage storage stor = LibNativeOrdersStorage.getStorage();

        // Get the filled and direct cancel state.
        {
            // The high bit of the raw taker token filled amount will be set
            // if the order was cancelled.
            uint256 rawTakerTokenFilledAmount = stor.orderHashToTakerTokenFilledAmount[orderInfo.orderHash];
            orderInfo.takerTokenFilledAmount = uint128(rawTakerTokenFilledAmount);
            if (orderInfo.takerTokenFilledAmount >= takerAmount) {
                orderInfo.status = LibNativeOrder.OrderStatus.FILLED;
                return;
            }
            if (rawTakerTokenFilledAmount & HIGH_BIT != 0) {
                orderInfo.status = LibNativeOrder.OrderStatus.CANCELLED;
                return;
            }
        }

        // Check for expiration.
        if (expiry <= uint64(block.timestamp)) {
            orderInfo.status = LibNativeOrder.OrderStatus.EXPIRED;
            return;
        }

        // Check if the order was cancelled by salt.
        if (minValidSalt > salt) {
            orderInfo.status = LibNativeOrder.OrderStatus.CANCELLED;
            return;
        }
        orderInfo.status = LibNativeOrder.OrderStatus.FILLABLE;
    }

    /// @dev Calculate the actual fillable taker token amount of an order
    ///      based on maker allowance and balances.
    function _getActualFillableTakerTokenAmount(
        GetActualFillableTakerTokenAmountParams memory params
    ) private view returns (uint128 actualFillableTakerTokenAmount) {
        if (params.orderMakerAmount == 0 || params.orderTakerAmount == 0) {
            // Empty order.
            return 0;
        }
        if (params.orderInfo.status != LibNativeOrder.OrderStatus.FILLABLE) {
            // Not fillable.
            return 0;
        }

        // Get the fillable maker amount based on the order quantities and
        // previously filled amount
        uint256 fillableMakerTokenAmount = LibMathV06.getPartialAmountFloor(
            uint256(params.orderTakerAmount - params.orderInfo.takerTokenFilledAmount),
            uint256(params.orderTakerAmount),
            uint256(params.orderMakerAmount)
        );
        // Clamp it to the amount of maker tokens we can spend on behalf of the
        // maker.
        fillableMakerTokenAmount = LibSafeMathV06.min256(
            fillableMakerTokenAmount,
            _getSpendableERC20BalanceOf(params.makerToken, params.maker)
        );
        // Convert to taker token amount.
        return
            LibMathV06
                .getPartialAmountCeil(
                    fillableMakerTokenAmount,
                    uint256(params.orderMakerAmount),
                    uint256(params.orderTakerAmount)
                )
                .safeDowncastToUint128();
    }

    /// @dev checks if a given address is registered to sign on behalf of a maker address
    /// @param maker The maker address encoded in an order (can be a contract)
    /// @param signer The address that is providing a signature
    function isValidOrderSigner(address maker, address signer) public view returns (bool isValid) {
        // returns false if it the mapping doesn't exist
        return LibNativeOrdersStorage.getStorage().orderSignerRegistry[maker][signer];
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IEtherTokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../../fixins/FixinProtocolFees.sol";
import "../../errors/LibNativeOrdersRichErrors.sol";
import "../../vendor/v3/IStaking.sol";

/// @dev Mixin for protocol fee utility functions.
abstract contract NativeOrdersProtocolFees is FixinProtocolFees {
    using LibSafeMathV06 for uint256;
    using LibRichErrorsV06 for bytes;

    constructor(
        IEtherTokenV06 weth,
        IStaking staking,
        FeeCollectorController feeCollectorController,
        uint32 protocolFeeMultiplier
    ) internal FixinProtocolFees(weth, staking, feeCollectorController, protocolFeeMultiplier) {}

    /// @dev Transfers protocol fees from the `FeeCollector` pools into
    ///      the staking contract.
    /// @param poolIds Staking pool IDs
    function transferProtocolFeesForPools(bytes32[] calldata poolIds) external {
        for (uint256 i = 0; i < poolIds.length; ++i) {
            _transferFeesForPool(poolIds[i]);
        }
    }

    /// @dev Get the protocol fee multiplier. This should be multiplied by the
    ///      gas price to arrive at the required protocol fee to fill a native order.
    /// @return multiplier The protocol fee multiplier.
    function getProtocolFeeMultiplier() external view returns (uint32 multiplier) {
        return PROTOCOL_FEE_MULTIPLIER;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IEtherTokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibMathV06.sol";
import "../../errors/LibNativeOrdersRichErrors.sol";
import "../../fixins/FixinCommon.sol";
import "../../storage/LibNativeOrdersStorage.sol";
import "../../vendor/v3/IStaking.sol";
import "../interfaces/INativeOrdersEvents.sol";
import "../libs/LibSignature.sol";
import "../libs/LibNativeOrder.sol";
import "./NativeOrdersCancellation.sol";
import "./NativeOrdersProtocolFees.sol";

/// @dev Mixin for settling limit and RFQ orders.
abstract contract NativeOrdersSettlement is
    INativeOrdersEvents,
    NativeOrdersCancellation,
    NativeOrdersProtocolFees,
    FixinCommon
{
    using LibSafeMathV06 for uint128;
    using LibRichErrorsV06 for bytes;

    /// @dev Params for `_settleOrder()`.
    struct SettleOrderInfo {
        // Order hash.
        bytes32 orderHash;
        // Maker of the order.
        address maker;
        // The address holding the taker tokens.
        address payer;
        // Recipient of the maker tokens.
        address recipient;
        // Maker token.
        IERC20TokenV06 makerToken;
        // Taker token.
        IERC20TokenV06 takerToken;
        // Maker token amount.
        uint128 makerAmount;
        // Taker token amount.
        uint128 takerAmount;
        // Maximum taker token amount to fill.
        uint128 takerTokenFillAmount;
        // How much taker token amount has already been filled in this order.
        uint128 takerTokenFilledAmount;
    }

    /// @dev Params for `_fillLimitOrderPrivate()`
    struct FillLimitOrderPrivateParams {
        // The limit order.
        LibNativeOrder.LimitOrder order;
        // The order signature.
        LibSignature.Signature signature;
        // Maximum taker token to fill this order with.
        uint128 takerTokenFillAmount;
        // The order taker.
        address taker;
        // The order sender.
        address sender;
    }

    /// @dev Params for `_fillRfqOrderPrivate()`
    struct FillRfqOrderPrivateParams {
        LibNativeOrder.RfqOrder order;
        // The order signature.
        LibSignature.Signature signature;
        // Maximum taker token to fill this order with.
        uint128 takerTokenFillAmount;
        // The order taker.
        address taker;
        // Whether to use the Exchange Proxy's balance
        // of taker tokens.
        bool useSelfBalance;
        // The recipient of the maker tokens.
        address recipient;
    }

    // @dev Fill results returned by `_fillLimitOrderPrivate()` and
    ///     `_fillRfqOrderPrivate()`.
    struct FillNativeOrderResults {
        uint256 ethProtocolFeePaid;
        uint128 takerTokenFilledAmount;
        uint128 makerTokenFilledAmount;
        uint128 takerTokenFeeFilledAmount;
    }

    constructor(
        address zeroExAddress,
        IEtherTokenV06 weth,
        IStaking staking,
        FeeCollectorController feeCollectorController,
        uint32 protocolFeeMultiplier
    )
        public
        NativeOrdersCancellation(zeroExAddress)
        NativeOrdersProtocolFees(weth, staking, feeCollectorController, protocolFeeMultiplier)
    {}

    /// @dev Fill a limit order. The taker and sender will be the caller.
    /// @param order The limit order. ETH protocol fees can be
    ///      attached to this call. Any unspent ETH will be refunded to
    ///      the caller.
    /// @param signature The order signature.
    /// @param takerTokenFillAmount Maximum taker token amount to fill this order with.
    /// @return takerTokenFilledAmount How much maker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function fillLimitOrder(
        LibNativeOrder.LimitOrder memory order,
        LibSignature.Signature memory signature,
        uint128 takerTokenFillAmount
    ) public payable returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount) {
        FillNativeOrderResults memory results = _fillLimitOrderPrivate(
            FillLimitOrderPrivateParams({
                order: order,
                signature: signature,
                takerTokenFillAmount: takerTokenFillAmount,
                taker: msg.sender,
                sender: msg.sender
            })
        );
        LibNativeOrder.refundExcessProtocolFeeToSender(results.ethProtocolFeePaid);
        (takerTokenFilledAmount, makerTokenFilledAmount) = (
            results.takerTokenFilledAmount,
            results.makerTokenFilledAmount
        );
    }

    /// @dev Fill an RFQ order for up to `takerTokenFillAmount` taker tokens.
    ///      The taker will be the caller. ETH should be attached to pay the
    ///      protocol fee.
    /// @param order The RFQ order.
    /// @param signature The order signature.
    /// @param takerTokenFillAmount Maximum taker token amount to fill this order with.
    /// @return takerTokenFilledAmount How much maker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function fillRfqOrder(
        LibNativeOrder.RfqOrder memory order,
        LibSignature.Signature memory signature,
        uint128 takerTokenFillAmount
    ) public returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount) {
        FillNativeOrderResults memory results = _fillRfqOrderPrivate(
            FillRfqOrderPrivateParams({
                order: order,
                signature: signature,
                takerTokenFillAmount: takerTokenFillAmount,
                taker: msg.sender,
                useSelfBalance: false,
                recipient: msg.sender
            })
        );
        (takerTokenFilledAmount, makerTokenFilledAmount) = (
            results.takerTokenFilledAmount,
            results.makerTokenFilledAmount
        );
    }

    /// @dev Fill an RFQ order for exactly `takerTokenFillAmount` taker tokens.
    ///      The taker will be the caller. ETH protocol fees can be
    ///      attached to this call. Any unspent ETH will be refunded to
    ///      the caller.
    /// @param order The limit order.
    /// @param signature The order signature.
    /// @param takerTokenFillAmount How much taker token to fill this order with.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function fillOrKillLimitOrder(
        LibNativeOrder.LimitOrder memory order,
        LibSignature.Signature memory signature,
        uint128 takerTokenFillAmount
    ) public payable returns (uint128 makerTokenFilledAmount) {
        FillNativeOrderResults memory results = _fillLimitOrderPrivate(
            FillLimitOrderPrivateParams({
                order: order,
                signature: signature,
                takerTokenFillAmount: takerTokenFillAmount,
                taker: msg.sender,
                sender: msg.sender
            })
        );
        // Must have filled exactly the amount requested.
        if (results.takerTokenFilledAmount < takerTokenFillAmount) {
            LibNativeOrdersRichErrors
                .FillOrKillFailedError(getLimitOrderHash(order), results.takerTokenFilledAmount, takerTokenFillAmount)
                .rrevert();
        }
        LibNativeOrder.refundExcessProtocolFeeToSender(results.ethProtocolFeePaid);
        makerTokenFilledAmount = results.makerTokenFilledAmount;
    }

    /// @dev Fill an RFQ order for exactly `takerTokenFillAmount` taker tokens.
    ///      The taker will be the caller. ETH protocol fees can be
    ///      attached to this call. Any unspent ETH will be refunded to
    ///      the caller.
    /// @param order The RFQ order.
    /// @param signature The order signature.
    /// @param takerTokenFillAmount How much taker token to fill this order with.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function fillOrKillRfqOrder(
        LibNativeOrder.RfqOrder memory order,
        LibSignature.Signature memory signature,
        uint128 takerTokenFillAmount
    ) public returns (uint128 makerTokenFilledAmount) {
        FillNativeOrderResults memory results = _fillRfqOrderPrivate(
            FillRfqOrderPrivateParams({
                order: order,
                signature: signature,
                takerTokenFillAmount: takerTokenFillAmount,
                taker: msg.sender,
                useSelfBalance: false,
                recipient: msg.sender
            })
        );
        // Must have filled exactly the amount requested.
        if (results.takerTokenFilledAmount < takerTokenFillAmount) {
            LibNativeOrdersRichErrors
                .FillOrKillFailedError(getRfqOrderHash(order), results.takerTokenFilledAmount, takerTokenFillAmount)
                .rrevert();
        }
        makerTokenFilledAmount = results.makerTokenFilledAmount;
    }

    /// @dev Fill a limit order. Internal variant. ETH protocol fees can be
    ///      attached to this call.
    /// @param order The limit order.
    /// @param signature The order signature.
    /// @param takerTokenFillAmount Maximum taker token to fill this order with.
    /// @param taker The order taker.
    /// @param sender The order sender.
    /// @return takerTokenFilledAmount How much maker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function _fillLimitOrder(
        LibNativeOrder.LimitOrder memory order,
        LibSignature.Signature memory signature,
        uint128 takerTokenFillAmount,
        address taker,
        address sender
    ) public payable virtual onlySelf returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount) {
        FillNativeOrderResults memory results = _fillLimitOrderPrivate(
            FillLimitOrderPrivateParams(order, signature, takerTokenFillAmount, taker, sender)
        );
        (takerTokenFilledAmount, makerTokenFilledAmount) = (
            results.takerTokenFilledAmount,
            results.makerTokenFilledAmount
        );
    }

    /// @dev Fill an RFQ order. Internal variant.
    /// @param order The RFQ order.
    /// @param signature The order signature.
    /// @param takerTokenFillAmount Maximum taker token to fill this order with.
    /// @param taker The order taker.
    /// @param useSelfBalance Whether to use the ExchangeProxy's transient
    ///        balance of taker tokens to fill the order.
    /// @param recipient The recipient of the maker tokens.
    /// @return takerTokenFilledAmount How much maker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function _fillRfqOrder(
        LibNativeOrder.RfqOrder memory order,
        LibSignature.Signature memory signature,
        uint128 takerTokenFillAmount,
        address taker,
        bool useSelfBalance,
        address recipient
    ) public virtual onlySelf returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount) {
        FillNativeOrderResults memory results = _fillRfqOrderPrivate(
            FillRfqOrderPrivateParams(order, signature, takerTokenFillAmount, taker, useSelfBalance, recipient)
        );
        (takerTokenFilledAmount, makerTokenFilledAmount) = (
            results.takerTokenFilledAmount,
            results.makerTokenFilledAmount
        );
    }

    /// @dev Mark what tx.origin addresses are allowed to fill an order that
    ///      specifies the message sender as its txOrigin.
    /// @param origins An array of origin addresses to update.
    /// @param allowed True to register, false to unregister.
    function registerAllowedRfqOrigins(address[] memory origins, bool allowed) external {
        require(msg.sender == tx.origin, "NativeOrdersFeature/NO_CONTRACT_ORIGINS");

        LibNativeOrdersStorage.Storage storage stor = LibNativeOrdersStorage.getStorage();

        for (uint256 i = 0; i < origins.length; i++) {
            stor.originRegistry[msg.sender][origins[i]] = allowed;
        }

        emit RfqOrderOriginsAllowed(msg.sender, origins, allowed);
    }

    /// @dev Fill a limit order. Private variant. Does not refund protocol fees.
    /// @param params Function params.
    /// @return results Results of the fill.
    function _fillLimitOrderPrivate(
        FillLimitOrderPrivateParams memory params
    ) private returns (FillNativeOrderResults memory results) {
        LibNativeOrder.OrderInfo memory orderInfo = getLimitOrderInfo(params.order);

        // Must be fillable.
        if (orderInfo.status != LibNativeOrder.OrderStatus.FILLABLE) {
            LibNativeOrdersRichErrors.OrderNotFillableError(orderInfo.orderHash, uint8(orderInfo.status)).rrevert();
        }

        // Must be fillable by the taker.
        if (params.order.taker != address(0) && params.order.taker != params.taker) {
            LibNativeOrdersRichErrors
                .OrderNotFillableByTakerError(orderInfo.orderHash, params.taker, params.order.taker)
                .rrevert();
        }

        // Must be fillable by the sender.
        if (params.order.sender != address(0) && params.order.sender != params.sender) {
            LibNativeOrdersRichErrors
                .OrderNotFillableBySenderError(orderInfo.orderHash, params.sender, params.order.sender)
                .rrevert();
        }

        // Signature must be valid for the order.
        {
            address signer = LibSignature.getSignerOfHash(orderInfo.orderHash, params.signature);
            if (signer != params.order.maker && !isValidOrderSigner(params.order.maker, signer)) {
                LibNativeOrdersRichErrors
                    .OrderNotSignedByMakerError(orderInfo.orderHash, signer, params.order.maker)
                    .rrevert();
            }
        }

        // Pay the protocol fee.
        results.ethProtocolFeePaid = _collectProtocolFee(params.order.pool);

        // Settle between the maker and taker.
        (results.takerTokenFilledAmount, results.makerTokenFilledAmount) = _settleOrder(
            SettleOrderInfo({
                orderHash: orderInfo.orderHash,
                maker: params.order.maker,
                payer: params.taker,
                recipient: params.taker,
                makerToken: IERC20TokenV06(params.order.makerToken),
                takerToken: IERC20TokenV06(params.order.takerToken),
                makerAmount: params.order.makerAmount,
                takerAmount: params.order.takerAmount,
                takerTokenFillAmount: params.takerTokenFillAmount,
                takerTokenFilledAmount: orderInfo.takerTokenFilledAmount
            })
        );

        // Pay the fee recipient.
        if (params.order.takerTokenFeeAmount > 0) {
            results.takerTokenFeeFilledAmount = uint128(
                LibMathV06.getPartialAmountFloor(
                    results.takerTokenFilledAmount,
                    params.order.takerAmount,
                    params.order.takerTokenFeeAmount
                )
            );
            _transferERC20TokensFrom(
                params.order.takerToken,
                params.taker,
                params.order.feeRecipient,
                uint256(results.takerTokenFeeFilledAmount)
            );
        }

        emit LimitOrderFilled(
            orderInfo.orderHash,
            params.order.maker,
            params.taker,
            params.order.feeRecipient,
            address(params.order.makerToken),
            address(params.order.takerToken),
            results.takerTokenFilledAmount,
            results.makerTokenFilledAmount,
            results.takerTokenFeeFilledAmount,
            results.ethProtocolFeePaid,
            params.order.pool
        );
    }

    /// @dev Fill an RFQ order. Private variant.
    /// @param params Function params.
    /// @return results Results of the fill.
    function _fillRfqOrderPrivate(
        FillRfqOrderPrivateParams memory params
    ) private returns (FillNativeOrderResults memory results) {
        LibNativeOrder.OrderInfo memory orderInfo = getRfqOrderInfo(params.order);

        // Must be fillable.
        if (orderInfo.status != LibNativeOrder.OrderStatus.FILLABLE) {
            LibNativeOrdersRichErrors.OrderNotFillableError(orderInfo.orderHash, uint8(orderInfo.status)).rrevert();
        }

        {
            LibNativeOrdersStorage.Storage storage stor = LibNativeOrdersStorage.getStorage();

            // Must be fillable by the tx.origin.
            if (params.order.txOrigin != tx.origin && !stor.originRegistry[params.order.txOrigin][tx.origin]) {
                LibNativeOrdersRichErrors
                    .OrderNotFillableByOriginError(orderInfo.orderHash, tx.origin, params.order.txOrigin)
                    .rrevert();
            }
        }

        // Must be fillable by the taker.
        if (params.order.taker != address(0) && params.order.taker != params.taker) {
            LibNativeOrdersRichErrors
                .OrderNotFillableByTakerError(orderInfo.orderHash, params.taker, params.order.taker)
                .rrevert();
        }

        // Signature must be valid for the order.
        {
            address signer = LibSignature.getSignerOfHash(orderInfo.orderHash, params.signature);
            if (signer != params.order.maker && !isValidOrderSigner(params.order.maker, signer)) {
                LibNativeOrdersRichErrors
                    .OrderNotSignedByMakerError(orderInfo.orderHash, signer, params.order.maker)
                    .rrevert();
            }
        }

        // Settle between the maker and taker.
        (results.takerTokenFilledAmount, results.makerTokenFilledAmount) = _settleOrder(
            SettleOrderInfo({
                orderHash: orderInfo.orderHash,
                maker: params.order.maker,
                payer: params.useSelfBalance ? address(this) : params.taker,
                recipient: params.recipient,
                makerToken: IERC20TokenV06(params.order.makerToken),
                takerToken: IERC20TokenV06(params.order.takerToken),
                makerAmount: params.order.makerAmount,
                takerAmount: params.order.takerAmount,
                takerTokenFillAmount: params.takerTokenFillAmount,
                takerTokenFilledAmount: orderInfo.takerTokenFilledAmount
            })
        );

        emit RfqOrderFilled(
            orderInfo.orderHash,
            params.order.maker,
            params.taker,
            address(params.order.makerToken),
            address(params.order.takerToken),
            results.takerTokenFilledAmount,
            results.makerTokenFilledAmount,
            params.order.pool
        );
    }

    /// @dev Settle the trade between an order's maker and taker.
    /// @param settleInfo Information needed to execute the settlement.
    /// @return takerTokenFilledAmount How much taker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function _settleOrder(
        SettleOrderInfo memory settleInfo
    ) private returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount) {
        // Clamp the taker token fill amount to the fillable amount.
        takerTokenFilledAmount = LibSafeMathV06.min128(
            settleInfo.takerTokenFillAmount,
            settleInfo.takerAmount.safeSub128(settleInfo.takerTokenFilledAmount)
        );
        // Compute the maker token amount.
        // This should never overflow because the values are all clamped to
        // (2^128-1).
        makerTokenFilledAmount = uint128(
            LibMathV06.getPartialAmountFloor(
                uint256(takerTokenFilledAmount),
                uint256(settleInfo.takerAmount),
                uint256(settleInfo.makerAmount)
            )
        );

        if (takerTokenFilledAmount == 0 || makerTokenFilledAmount == 0) {
            // Nothing to do.
            return (0, 0);
        }

        // Update filled state for the order.
        // solhint-disable-next-line max-line-length
        LibNativeOrdersStorage.getStorage().orderHashToTakerTokenFilledAmount[settleInfo.orderHash] = settleInfo // function if the order is cancelled. // OK to overwrite the whole word because we shouldn't get to this
            .takerTokenFilledAmount
            .safeAdd128(takerTokenFilledAmount);

        if (settleInfo.payer == address(this)) {
            // Transfer this -> maker.
            _transferERC20Tokens(settleInfo.takerToken, settleInfo.maker, takerTokenFilledAmount);
        } else {
            // Transfer taker -> maker.
            _transferERC20TokensFrom(settleInfo.takerToken, settleInfo.payer, settleInfo.maker, takerTokenFilledAmount);
        }

        // Transfer maker -> recipient.
        _transferERC20TokensFrom(settleInfo.makerToken, settleInfo.maker, settleInfo.recipient, makerTokenFilledAmount);
    }

    /// @dev register a signer who can sign on behalf of msg.sender
    /// @param signer The address from which you plan to generate signatures
    /// @param allowed True to register, false to unregister.
    function registerAllowedOrderSigner(address signer, bool allowed) external {
        LibNativeOrdersStorage.Storage storage stor = LibNativeOrdersStorage.getStorage();

        stor.orderSignerRegistry[msg.sender][signer] = allowed;

        emit OrderSignerRegistered(msg.sender, signer, allowed);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "../migrations/LibMigrate.sol";
import "./interfaces/IFeature.sol";
import "./interfaces/INativeOrdersFeature.sol";
import "./native_orders/NativeOrdersSettlement.sol";

/// @dev Feature for interacting with limit and RFQ orders.
contract NativeOrdersFeature is IFeature, NativeOrdersSettlement {
    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "LimitOrders";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 3, 0);

    constructor(
        address zeroExAddress,
        IEtherTokenV06 weth,
        IStaking staking,
        FeeCollectorController feeCollectorController,
        uint32 protocolFeeMultiplier
    ) public NativeOrdersSettlement(zeroExAddress, weth, staking, feeCollectorController, protocolFeeMultiplier) {}

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external returns (bytes4 success) {
        _registerFeatureFunction(this.transferProtocolFeesForPools.selector);
        _registerFeatureFunction(this.fillLimitOrder.selector);
        _registerFeatureFunction(this.fillRfqOrder.selector);
        _registerFeatureFunction(this.fillOrKillLimitOrder.selector);
        _registerFeatureFunction(this.fillOrKillRfqOrder.selector);
        _registerFeatureFunction(this._fillLimitOrder.selector);
        _registerFeatureFunction(this._fillRfqOrder.selector);
        _registerFeatureFunction(this.cancelLimitOrder.selector);
        _registerFeatureFunction(this.cancelRfqOrder.selector);
        _registerFeatureFunction(this.batchCancelLimitOrders.selector);
        _registerFeatureFunction(this.batchCancelRfqOrders.selector);
        _registerFeatureFunction(this.cancelPairLimitOrders.selector);
        _registerFeatureFunction(this.cancelPairLimitOrdersWithSigner.selector);
        _registerFeatureFunction(this.batchCancelPairLimitOrders.selector);
        _registerFeatureFunction(this.batchCancelPairLimitOrdersWithSigner.selector);
        _registerFeatureFunction(this.cancelPairRfqOrders.selector);
        _registerFeatureFunction(this.cancelPairRfqOrdersWithSigner.selector);
        _registerFeatureFunction(this.batchCancelPairRfqOrders.selector);
        _registerFeatureFunction(this.batchCancelPairRfqOrdersWithSigner.selector);
        _registerFeatureFunction(this.getLimitOrderInfo.selector);
        _registerFeatureFunction(this.getRfqOrderInfo.selector);
        _registerFeatureFunction(this.getLimitOrderHash.selector);
        _registerFeatureFunction(this.getRfqOrderHash.selector);
        _registerFeatureFunction(this.getProtocolFeeMultiplier.selector);
        _registerFeatureFunction(this.registerAllowedRfqOrigins.selector);
        _registerFeatureFunction(this.getLimitOrderRelevantState.selector);
        _registerFeatureFunction(this.getRfqOrderRelevantState.selector);
        _registerFeatureFunction(this.batchGetLimitOrderRelevantStates.selector);
        _registerFeatureFunction(this.batchGetRfqOrderRelevantStates.selector);
        _registerFeatureFunction(this.registerAllowedOrderSigner.selector);
        _registerFeatureFunction(this.isValidOrderSigner.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IEtherTokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../../fixins/FixinERC1155Spender.sol";
import "../../migrations/LibMigrate.sol";
import "../../storage/LibERC1155OrdersStorage.sol";
import "../interfaces/IFeature.sol";
import "../interfaces/IERC1155OrdersFeature.sol";
import "../libs/LibNFTOrder.sol";
import "../libs/LibSignature.sol";
import "./NFTOrders.sol";

/// @dev Feature for interacting with ERC1155 orders.
contract ERC1155OrdersFeature is IFeature, IERC1155OrdersFeature, FixinERC1155Spender, NFTOrders {
    using LibSafeMathV06 for uint256;
    using LibSafeMathV06 for uint128;
    using LibNFTOrder for LibNFTOrder.ERC1155Order;
    using LibNFTOrder for LibNFTOrder.NFTOrder;

    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "ERC1155Orders";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 0);

    /// @dev The magic return value indicating the success of a `onERC1155Received`.
    bytes4 private constant ERC1155_RECEIVED_MAGIC_BYTES = this.onERC1155Received.selector;

    constructor(address zeroExAddress, IEtherTokenV06 weth) public NFTOrders(zeroExAddress, weth) {}

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external returns (bytes4 success) {
        _registerFeatureFunction(this.sellERC1155.selector);
        _registerFeatureFunction(this.buyERC1155.selector);
        _registerFeatureFunction(this.cancelERC1155Order.selector);
        _registerFeatureFunction(this.batchBuyERC1155s.selector);
        _registerFeatureFunction(this.onERC1155Received.selector);
        _registerFeatureFunction(this.preSignERC1155Order.selector);
        _registerFeatureFunction(this.validateERC1155OrderSignature.selector);
        _registerFeatureFunction(this.validateERC1155OrderProperties.selector);
        _registerFeatureFunction(this.getERC1155OrderInfo.selector);
        _registerFeatureFunction(this.getERC1155OrderHash.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @dev Sells an ERC1155 asset to fill the given order.
    /// @param buyOrder The ERC1155 buy order.
    /// @param signature The order signature from the maker.
    /// @param erc1155TokenId The ID of the ERC1155 asset being
    ///        sold. If the given order specifies properties,
    ///        the asset must satisfy those properties. Otherwise,
    ///        it must equal the tokenId in the order.
    /// @param erc1155SellAmount The amount of the ERC1155 asset
    ///        to sell.
    /// @param unwrapNativeToken If this parameter is true and the
    ///        ERC20 token of the order is e.g. WETH, unwraps the
    ///        token before transferring it to the taker.
    /// @param callbackData If this parameter is non-zero, invokes
    ///        `zeroExERC1155OrderCallback` on `msg.sender` after
    ///        the ERC20 tokens have been transferred to `msg.sender`
    ///        but before transferring the ERC1155 asset to the buyer.
    function sellERC1155(
        LibNFTOrder.ERC1155Order memory buyOrder,
        LibSignature.Signature memory signature,
        uint256 erc1155TokenId,
        uint128 erc1155SellAmount,
        bool unwrapNativeToken,
        bytes memory callbackData
    ) public override {
        _sellERC1155(
            buyOrder,
            signature,
            SellParams(
                erc1155SellAmount,
                erc1155TokenId,
                unwrapNativeToken,
                msg.sender, // taker
                msg.sender, // owner
                callbackData
            )
        );
    }

    /// @dev Buys an ERC1155 asset by filling the given order.
    /// @param sellOrder The ERC1155 sell order.
    /// @param signature The order signature.
    /// @param erc1155BuyAmount The amount of the ERC1155 asset
    ///        to buy.
    /// @param callbackData If this parameter is non-zero, invokes
    ///        `zeroExERC1155OrderCallback` on `msg.sender` after
    ///        the ERC1155 asset has been transferred to `msg.sender`
    ///        but before transferring the ERC20 tokens to the seller.
    ///        Native tokens acquired during the callback can be used
    ///        to fill the order.
    function buyERC1155(
        LibNFTOrder.ERC1155Order memory sellOrder,
        LibSignature.Signature memory signature,
        uint128 erc1155BuyAmount,
        bytes memory callbackData
    ) public payable override {
        uint256 ethBalanceBefore = address(this).balance.safeSub(msg.value);
        _buyERC1155(sellOrder, signature, BuyParams(erc1155BuyAmount, msg.value, callbackData));
        uint256 ethBalanceAfter = address(this).balance;
        // Cannot use pre-existing ETH balance
        if (ethBalanceAfter < ethBalanceBefore) {
            LibNFTOrdersRichErrors
                .OverspentEthError(ethBalanceBefore - ethBalanceAfter + msg.value, msg.value)
                .rrevert();
        }
        // Refund
        _transferEth(msg.sender, ethBalanceAfter - ethBalanceBefore);
    }

    /// @dev Cancel a single ERC1155 order by its nonce. The caller
    ///      should be the maker of the order. Silently succeeds if
    ///      an order with the same nonce has already been filled or
    ///      cancelled.
    /// @param orderNonce The order nonce.
    function cancelERC1155Order(uint256 orderNonce) public override {
        // The bitvector is indexed by the lower 8 bits of the nonce.
        uint256 flag = 1 << (orderNonce & 255);
        // Update order cancellation bit vector to indicate that the order
        // has been cancelled/filled by setting the designated bit to 1.
        LibERC1155OrdersStorage.getStorage().orderCancellationByMaker[msg.sender][uint248(orderNonce >> 8)] |= flag;

        emit ERC1155OrderCancelled(msg.sender, orderNonce);
    }

    /// @dev Cancel multiple ERC1155 orders by their nonces. The caller
    ///      should be the maker of the orders. Silently succeeds if
    ///      an order with the same nonce has already been filled or
    ///      cancelled.
    /// @param orderNonces The order nonces.
    function batchCancelERC1155Orders(uint256[] calldata orderNonces) external override {
        for (uint256 i = 0; i < orderNonces.length; i++) {
            cancelERC1155Order(orderNonces[i]);
        }
    }

    /// @dev Buys multiple ERC1155 assets by filling the
    ///      given orders.
    /// @param sellOrders The ERC1155 sell orders.
    /// @param signatures The order signatures.
    /// @param erc1155FillAmounts The amounts of the ERC1155 assets
    ///        to buy for each order.
    /// @param callbackData The data (if any) to pass to the taker
    ///        callback for each order. Refer to the `callbackData`
    ///        parameter to for `buyERC1155`.
    /// @param revertIfIncomplete If true, reverts if this
    ///        function fails to fill any individual order.
    /// @return successes An array of booleans corresponding to whether
    ///         each order in `orders` was successfully filled.
    function batchBuyERC1155s(
        LibNFTOrder.ERC1155Order[] memory sellOrders,
        LibSignature.Signature[] memory signatures,
        uint128[] calldata erc1155FillAmounts,
        bytes[] memory callbackData,
        bool revertIfIncomplete
    ) public payable override returns (bool[] memory successes) {
        require(
            sellOrders.length == signatures.length &&
                sellOrders.length == erc1155FillAmounts.length &&
                sellOrders.length == callbackData.length,
            "ERC1155OrdersFeature::batchBuyERC1155s/ARRAY_LENGTH_MISMATCH"
        );
        successes = new bool[](sellOrders.length);

        uint256 ethBalanceBefore = address(this).balance.safeSub(msg.value);
        if (revertIfIncomplete) {
            for (uint256 i = 0; i < sellOrders.length; i++) {
                // Will revert if _buyERC1155 reverts.
                _buyERC1155(
                    sellOrders[i],
                    signatures[i],
                    BuyParams(
                        erc1155FillAmounts[i],
                        address(this).balance.safeSub(ethBalanceBefore), // Remaining ETH available
                        callbackData[i]
                    )
                );
                successes[i] = true;
            }
        } else {
            for (uint256 i = 0; i < sellOrders.length; i++) {
                // Delegatecall `_buyERC1155` to catch swallow reverts while
                // preserving execution context.
                // Note that `_buyERC1155` is a public function but should _not_
                // be registered in the Exchange Proxy.
                (successes[i], ) = _implementation.delegatecall(
                    abi.encodeWithSelector(
                        this._buyERC1155.selector,
                        sellOrders[i],
                        signatures[i],
                        BuyParams(
                            erc1155FillAmounts[i],
                            address(this).balance.safeSub(ethBalanceBefore), // Remaining ETH available
                            callbackData[i]
                        )
                    )
                );
            }
        }

        // Cannot use pre-existing ETH balance
        uint256 ethBalanceAfter = address(this).balance;
        if (ethBalanceAfter < ethBalanceBefore) {
            LibNFTOrdersRichErrors
                .OverspentEthError(msg.value + (ethBalanceBefore - ethBalanceAfter), msg.value)
                .rrevert();
        }

        // Refund
        _transferEth(msg.sender, ethBalanceAfter - ethBalanceBefore);
    }

    /// @dev Callback for the ERC1155 `safeTransferFrom` function.
    ///      This callback can be used to sell an ERC1155 asset if
    ///      a valid ERC1155 order, signature and `unwrapNativeToken`
    ///      are encoded in `data`. This allows takers to sell their
    ///      ERC1155 asset without first calling `setApprovalForAll`.
    /// @param operator The address which called `safeTransferFrom`.
    /// @param tokenId The ID of the asset being transferred.
    /// @param value The amount being transferred.
    /// @param data Additional data with no specified format. If a
    ///        valid ERC1155 order, signature and `unwrapNativeToken`
    ///        are encoded in `data`, this function will try to fill
    ///        the order using the received asset.
    /// @return success The selector of this function (0xf23a6e61),
    ///         indicating that the callback succeeded.
    function onERC1155Received(
        address operator,
        address /* from */,
        uint256 tokenId,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4 success) {
        // Decode the order, signature, and `unwrapNativeToken` from
        // `data`. If `data` does not encode such parameters, this
        // will throw.
        (
            LibNFTOrder.ERC1155Order memory buyOrder,
            LibSignature.Signature memory signature,
            bool unwrapNativeToken
        ) = abi.decode(data, (LibNFTOrder.ERC1155Order, LibSignature.Signature, bool));

        // `onERC1155Received` is called by the ERC1155 token contract.
        // Check that it matches the ERC1155 token in the order.
        if (msg.sender != address(buyOrder.erc1155Token)) {
            LibNFTOrdersRichErrors.ERC1155TokenMismatchError(msg.sender, address(buyOrder.erc1155Token)).rrevert();
        }

        _sellERC1155(
            buyOrder,
            signature,
            SellParams(
                value.safeDowncastToUint128(),
                tokenId,
                unwrapNativeToken,
                operator, // taker
                address(this), // owner (we hold the NFT currently)
                new bytes(0) // No taker callback
            )
        );

        return ERC1155_RECEIVED_MAGIC_BYTES;
    }

    /// @dev Approves an ERC1155 order on-chain. After pre-signing
    ///      the order, the `PRESIGNED` signature type will become
    ///      valid for that order and signer.
    /// @param order An ERC1155 order.
    function preSignERC1155Order(LibNFTOrder.ERC1155Order memory order) public override {
        require(order.maker == msg.sender, "ERC1155OrdersFeature::preSignERC1155Order/MAKER_MISMATCH");
        bytes32 orderHash = getERC1155OrderHash(order);

        LibERC1155OrdersStorage.Storage storage stor = LibERC1155OrdersStorage.getStorage();
        // Set `preSigned` to true on the order state variable
        // to indicate that the order has been pre-signed.
        stor.orderState[orderHash].preSigned = true;

        emit ERC1155OrderPreSigned(
            order.direction,
            order.maker,
            order.taker,
            order.expiry,
            order.nonce,
            order.erc20Token,
            order.erc20TokenAmount,
            order.fees,
            order.erc1155Token,
            order.erc1155TokenId,
            order.erc1155TokenProperties,
            order.erc1155TokenAmount
        );
    }

    // Core settlement logic for selling an ERC1155 asset.
    // Used by `sellERC1155` and `onERC1155Received`.
    function _sellERC1155(
        LibNFTOrder.ERC1155Order memory buyOrder,
        LibSignature.Signature memory signature,
        SellParams memory params
    ) private {
        uint256 erc20FillAmount = _sellNFT(buyOrder.asNFTOrder(), signature, params);

        emit ERC1155OrderFilled(
            buyOrder.direction,
            buyOrder.maker,
            params.taker,
            buyOrder.nonce,
            buyOrder.erc20Token,
            erc20FillAmount,
            buyOrder.erc1155Token,
            params.tokenId,
            params.sellAmount,
            address(0)
        );
    }

    // Core settlement logic for buying an ERC1155 asset.
    // Used by `buyERC1155` and `batchBuyERC1155s`.
    function _buyERC1155(
        LibNFTOrder.ERC1155Order memory sellOrder,
        LibSignature.Signature memory signature,
        BuyParams memory params
    ) public payable {
        uint256 erc20FillAmount = _buyNFT(sellOrder.asNFTOrder(), signature, params);

        emit ERC1155OrderFilled(
            sellOrder.direction,
            sellOrder.maker,
            msg.sender,
            sellOrder.nonce,
            sellOrder.erc20Token,
            erc20FillAmount,
            sellOrder.erc1155Token,
            sellOrder.erc1155TokenId,
            params.buyAmount,
            address(0)
        );
    }

    /// @dev Checks whether the given signature is valid for the
    ///      the given ERC1155 order. Reverts if not.
    /// @param order The ERC1155 order.
    /// @param signature The signature to validate.
    function validateERC1155OrderSignature(
        LibNFTOrder.ERC1155Order memory order,
        LibSignature.Signature memory signature
    ) public view override {
        bytes32 orderHash = getERC1155OrderHash(order);
        _validateOrderSignature(orderHash, signature, order.maker);
    }

    /// @dev Validates that the given signature is valid for the
    ///      given maker and order hash. Reverts if the signature
    ///      is not valid.
    /// @param orderHash The hash of the order that was signed.
    /// @param signature The signature to check.
    /// @param maker The maker of the order.
    function _validateOrderSignature(
        bytes32 orderHash,
        LibSignature.Signature memory signature,
        address maker
    ) internal view override {
        if (signature.signatureType == LibSignature.SignatureType.PRESIGNED) {
            // Check if order hash has been pre-signed by the maker.
            bool isPreSigned = LibERC1155OrdersStorage.getStorage().orderState[orderHash].preSigned;
            if (!isPreSigned) {
                LibNFTOrdersRichErrors.InvalidSignerError(maker, address(0)).rrevert();
            }
        } else {
            address signer = LibSignature.getSignerOfHash(orderHash, signature);
            if (signer != maker) {
                LibNFTOrdersRichErrors.InvalidSignerError(maker, signer).rrevert();
            }
        }
    }

    /// @dev Transfers an NFT asset.
    /// @param token The address of the NFT contract.
    /// @param from The address currently holding the asset.
    /// @param to The address to transfer the asset to.
    /// @param tokenId The ID of the asset to transfer.
    /// @param amount The amount of the asset to transfer. Always
    ///        1 for ERC721 assets.
    function _transferNFTAssetFrom(
        address token,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal override {
        _transferERC1155AssetFrom(IERC1155Token(token), from, to, tokenId, amount);
    }

    /// @dev Updates storage to indicate that the given order
    ///      has been filled by the given amount.
    /// @param orderHash The hash of `order`.
    /// @param fillAmount The amount (denominated in the NFT asset)
    ///        that the order has been filled by.
    function _updateOrderState(
        LibNFTOrder.NFTOrder memory /* order */,
        bytes32 orderHash,
        uint128 fillAmount
    ) internal override {
        LibERC1155OrdersStorage.Storage storage stor = LibERC1155OrdersStorage.getStorage();
        uint128 filledAmount = stor.orderState[orderHash].filledAmount;
        // Filled amount should never overflow 128 bits
        assert(filledAmount + fillAmount > filledAmount);
        stor.orderState[orderHash].filledAmount = filledAmount + fillAmount;
    }

    /// @dev If the given order is buying an ERC1155 asset, checks
    ///      whether or not the given token ID satisfies the required
    ///      properties specified in the order. If the order does not
    ///      specify any properties, this function instead checks
    ///      whether the given token ID matches the ID in the order.
    ///      Reverts if any checks fail, or if the order is selling
    ///      an ERC1155 asset.
    /// @param order The ERC1155 order.
    /// @param erc1155TokenId The ID of the ERC1155 asset.
    function validateERC1155OrderProperties(
        LibNFTOrder.ERC1155Order memory order,
        uint256 erc1155TokenId
    ) public view override {
        _validateOrderProperties(order.asNFTOrder(), erc1155TokenId);
    }

    /// @dev Get the order info for an ERC1155 order.
    /// @param order The ERC1155 order.
    /// @return orderInfo Info about the order.
    function getERC1155OrderInfo(
        LibNFTOrder.ERC1155Order memory order
    ) public view override returns (LibNFTOrder.OrderInfo memory orderInfo) {
        orderInfo.orderAmount = order.erc1155TokenAmount;
        orderInfo.orderHash = getERC1155OrderHash(order);

        // Only buy orders with `erc1155TokenId` == 0 can be property
        // orders.
        if (
            order.erc1155TokenProperties.length > 0 &&
            (order.direction != LibNFTOrder.TradeDirection.BUY_NFT || order.erc1155TokenId != 0)
        ) {
            orderInfo.status = LibNFTOrder.OrderStatus.INVALID;
            return orderInfo;
        }

        // Buy orders cannot use ETH as the ERC20 token, since ETH cannot be
        // transferred from the buyer by a contract.
        if (
            order.direction == LibNFTOrder.TradeDirection.BUY_NFT && address(order.erc20Token) == NATIVE_TOKEN_ADDRESS
        ) {
            orderInfo.status = LibNFTOrder.OrderStatus.INVALID;
            return orderInfo;
        }

        // Check for expiry.
        if (order.expiry <= block.timestamp) {
            orderInfo.status = LibNFTOrder.OrderStatus.EXPIRED;
            return orderInfo;
        }

        {
            LibERC1155OrdersStorage.Storage storage stor = LibERC1155OrdersStorage.getStorage();

            LibERC1155OrdersStorage.OrderState storage orderState = stor.orderState[orderInfo.orderHash];
            orderInfo.remainingAmount = order.erc1155TokenAmount.safeSub128(orderState.filledAmount);

            // `orderCancellationByMaker` is indexed by maker and nonce.
            uint256 orderCancellationBitVector = stor.orderCancellationByMaker[order.maker][uint248(order.nonce >> 8)];
            // The bitvector is indexed by the lower 8 bits of the nonce.
            uint256 flag = 1 << (order.nonce & 255);

            if (orderInfo.remainingAmount == 0 || orderCancellationBitVector & flag != 0) {
                orderInfo.status = LibNFTOrder.OrderStatus.UNFILLABLE;
                return orderInfo;
            }
        }

        // Otherwise, the order is fillable.
        orderInfo.status = LibNFTOrder.OrderStatus.FILLABLE;
    }

    /// @dev Get the order info for an NFT order.
    /// @param order The NFT order.
    /// @return orderInfo Info about the order.
    function _getOrderInfo(
        LibNFTOrder.NFTOrder memory order
    ) internal view override returns (LibNFTOrder.OrderInfo memory orderInfo) {
        return getERC1155OrderInfo(order.asERC1155Order());
    }

    /// @dev Get the EIP-712 hash of an ERC1155 order.
    /// @param order The ERC1155 order.
    /// @return orderHash The order hash.
    function getERC1155OrderHash(
        LibNFTOrder.ERC1155Order memory order
    ) public view override returns (bytes32 orderHash) {
        return _getEIP712Hash(LibNFTOrder.getERC1155OrderStructHash(order));
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IEtherTokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../../fixins/FixinERC721Spender.sol";
import "../../migrations/LibMigrate.sol";
import "../../storage/LibERC721OrdersStorage.sol";
import "../interfaces/IFeature.sol";
import "../interfaces/IERC721OrdersFeature.sol";
import "../libs/LibNFTOrder.sol";
import "../libs/LibSignature.sol";
import "./NFTOrders.sol";

/// @dev Feature for interacting with ERC721 orders.
contract ERC721OrdersFeature is IFeature, IERC721OrdersFeature, FixinERC721Spender, NFTOrders {
    using LibSafeMathV06 for uint256;
    using LibNFTOrder for LibNFTOrder.ERC721Order;
    using LibNFTOrder for LibNFTOrder.NFTOrder;

    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "ERC721Orders";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 0);

    /// @dev The magic return value indicating the success of a `onERC721Received`.
    bytes4 private constant ERC721_RECEIVED_MAGIC_BYTES = this.onERC721Received.selector;

    constructor(address zeroExAddress, IEtherTokenV06 weth) public NFTOrders(zeroExAddress, weth) {}

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external returns (bytes4 success) {
        _registerFeatureFunction(this.sellERC721.selector);
        _registerFeatureFunction(this.buyERC721.selector);
        _registerFeatureFunction(this.cancelERC721Order.selector);
        _registerFeatureFunction(this.batchBuyERC721s.selector);
        _registerFeatureFunction(this.matchERC721Orders.selector);
        _registerFeatureFunction(this.batchMatchERC721Orders.selector);
        _registerFeatureFunction(this.onERC721Received.selector);
        _registerFeatureFunction(this.preSignERC721Order.selector);
        _registerFeatureFunction(this.validateERC721OrderSignature.selector);
        _registerFeatureFunction(this.validateERC721OrderProperties.selector);
        _registerFeatureFunction(this.getERC721OrderStatus.selector);
        _registerFeatureFunction(this.getERC721OrderHash.selector);
        _registerFeatureFunction(this.getERC721OrderStatusBitVector.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @dev Sells an ERC721 asset to fill the given order.
    /// @param buyOrder The ERC721 buy order.
    /// @param signature The order signature from the maker.
    /// @param erc721TokenId The ID of the ERC721 asset being
    ///        sold. If the given order specifies properties,
    ///        the asset must satisfy those properties. Otherwise,
    ///        it must equal the tokenId in the order.
    /// @param unwrapNativeToken If this parameter is true and the
    ///        ERC20 token of the order is e.g. WETH, unwraps the
    ///        token before transferring it to the taker.
    /// @param callbackData If this parameter is non-zero, invokes
    ///        `zeroExERC721OrderCallback` on `msg.sender` after
    ///        the ERC20 tokens have been transferred to `msg.sender`
    ///        but before transferring the ERC721 asset to the buyer.
    function sellERC721(
        LibNFTOrder.ERC721Order memory buyOrder,
        LibSignature.Signature memory signature,
        uint256 erc721TokenId,
        bool unwrapNativeToken,
        bytes memory callbackData
    ) public override {
        _sellERC721(
            buyOrder,
            signature,
            erc721TokenId,
            unwrapNativeToken,
            msg.sender, // taker
            msg.sender, // owner
            callbackData
        );
    }

    /// @dev Buys an ERC721 asset by filling the given order.
    /// @param sellOrder The ERC721 sell order.
    /// @param signature The order signature.
    /// @param callbackData If this parameter is non-zero, invokes
    ///        `zeroExERC721OrderCallback` on `msg.sender` after
    ///        the ERC721 asset has been transferred to `msg.sender`
    ///        but before transferring the ERC20 tokens to the seller.
    ///        Native tokens acquired during the callback can be used
    ///        to fill the order.
    function buyERC721(
        LibNFTOrder.ERC721Order memory sellOrder,
        LibSignature.Signature memory signature,
        bytes memory callbackData
    ) public payable override {
        uint256 ethBalanceBefore = address(this).balance.safeSub(msg.value);
        _buyERC721(sellOrder, signature, msg.value, callbackData);
        uint256 ethBalanceAfter = address(this).balance;
        // Cannot use pre-existing ETH balance
        if (ethBalanceAfter < ethBalanceBefore) {
            LibNFTOrdersRichErrors
                .OverspentEthError(msg.value + (ethBalanceBefore - ethBalanceAfter), msg.value)
                .rrevert();
        }
        // Refund
        _transferEth(msg.sender, ethBalanceAfter - ethBalanceBefore);
    }

    /// @dev Cancel a single ERC721 order by its nonce. The caller
    ///      should be the maker of the order. Silently succeeds if
    ///      an order with the same nonce has already been filled or
    ///      cancelled.
    /// @param orderNonce The order nonce.
    function cancelERC721Order(uint256 orderNonce) public override {
        // Mark order as cancelled
        _setOrderStatusBit(msg.sender, orderNonce);
        emit ERC721OrderCancelled(msg.sender, orderNonce);
    }

    /// @dev Cancel multiple ERC721 orders by their nonces. The caller
    ///      should be the maker of the orders. Silently succeeds if
    ///      an order with the same nonce has already been filled or
    ///      cancelled.
    /// @param orderNonces The order nonces.
    function batchCancelERC721Orders(uint256[] calldata orderNonces) external override {
        for (uint256 i = 0; i < orderNonces.length; i++) {
            cancelERC721Order(orderNonces[i]);
        }
    }

    /// @dev Buys multiple ERC721 assets by filling the
    ///      given orders.
    /// @param sellOrders The ERC721 sell orders.
    /// @param signatures The order signatures.
    /// @param revertIfIncomplete If true, reverts if this
    ///        function fails to fill any individual order.
    /// @param callbackData The data (if any) to pass to the taker
    ///        callback for each order. Refer to the `callbackData`
    ///        parameter to for `buyERC721`.
    /// @return successes An array of booleans corresponding to whether
    ///         each order in `orders` was successfully filled.
    function batchBuyERC721s(
        LibNFTOrder.ERC721Order[] memory sellOrders,
        LibSignature.Signature[] memory signatures,
        bytes[] memory callbackData,
        bool revertIfIncomplete
    ) public payable override returns (bool[] memory successes) {
        require(
            sellOrders.length == signatures.length && sellOrders.length == callbackData.length,
            "ERC721OrdersFeature::batchBuyERC721s/ARRAY_LENGTH_MISMATCH"
        );
        successes = new bool[](sellOrders.length);

        uint256 ethBalanceBefore = address(this).balance.safeSub(msg.value);
        if (revertIfIncomplete) {
            for (uint256 i = 0; i < sellOrders.length; i++) {
                // Will revert if _buyERC721 reverts.
                _buyERC721(
                    sellOrders[i],
                    signatures[i],
                    address(this).balance.safeSub(ethBalanceBefore),
                    callbackData[i]
                );
                successes[i] = true;
            }
        } else {
            for (uint256 i = 0; i < sellOrders.length; i++) {
                // Delegatecall `_buyERC721` to swallow reverts while
                // preserving execution context.
                // Note that `_buyERC721` is a public function but should _not_
                // be registered in the Exchange Proxy.
                (successes[i], ) = _implementation.delegatecall(
                    abi.encodeWithSelector(
                        this._buyERC721.selector,
                        sellOrders[i],
                        signatures[i],
                        address(this).balance.safeSub(ethBalanceBefore), // Remaining ETH available
                        callbackData[i]
                    )
                );
            }
        }

        // Cannot use pre-existing ETH balance
        uint256 ethBalanceAfter = address(this).balance;
        if (ethBalanceAfter < ethBalanceBefore) {
            LibNFTOrdersRichErrors
                .OverspentEthError(msg.value + (ethBalanceBefore - ethBalanceAfter), msg.value)
                .rrevert();
        }

        // Refund
        _transferEth(msg.sender, ethBalanceAfter - ethBalanceBefore);
    }

    /// @dev Matches a pair of complementary orders that have
    ///      a non-negative spread. Each order is filled at
    ///      their respective price, and the matcher receives
    ///      a profit denominated in the ERC20 token.
    /// @param sellOrder Order selling an ERC721 asset.
    /// @param buyOrder Order buying an ERC721 asset.
    /// @param sellOrderSignature Signature for the sell order.
    /// @param buyOrderSignature Signature for the buy order.
    /// @return profit The amount of profit earned by the caller
    ///         of this function (denominated in the ERC20 token
    ///         of the matched orders).
    function matchERC721Orders(
        LibNFTOrder.ERC721Order memory sellOrder,
        LibNFTOrder.ERC721Order memory buyOrder,
        LibSignature.Signature memory sellOrderSignature,
        LibSignature.Signature memory buyOrderSignature
    ) public override returns (uint256 profit) {
        // The ERC721 tokens must match
        if (sellOrder.erc721Token != buyOrder.erc721Token) {
            LibNFTOrdersRichErrors
                .ERC721TokenMismatchError(address(sellOrder.erc721Token), address(buyOrder.erc721Token))
                .rrevert();
        }

        LibNFTOrder.NFTOrder memory sellNFTOrder = sellOrder.asNFTOrder();
        LibNFTOrder.NFTOrder memory buyNFTOrder = buyOrder.asNFTOrder();

        {
            LibNFTOrder.OrderInfo memory sellOrderInfo = _getOrderInfo(sellNFTOrder);
            LibNFTOrder.OrderInfo memory buyOrderInfo = _getOrderInfo(buyNFTOrder);

            _validateSellOrder(sellNFTOrder, sellOrderSignature, sellOrderInfo, buyOrder.maker);
            _validateBuyOrder(buyNFTOrder, buyOrderSignature, buyOrderInfo, sellOrder.maker, sellOrder.erc721TokenId);

            // Mark both orders as filled.
            _updateOrderState(sellNFTOrder, sellOrderInfo.orderHash, 1);
            _updateOrderState(buyNFTOrder, buyOrderInfo.orderHash, 1);
        }

        // The buyer must be willing to pay at least the amount that the
        // seller is asking.
        if (buyOrder.erc20TokenAmount < sellOrder.erc20TokenAmount) {
            LibNFTOrdersRichErrors.NegativeSpreadError(sellOrder.erc20TokenAmount, buyOrder.erc20TokenAmount).rrevert();
        }

        // The difference in ERC20 token amounts is the spread.
        uint256 spread = buyOrder.erc20TokenAmount - sellOrder.erc20TokenAmount;

        // Transfer the ERC721 asset from seller to buyer.
        _transferERC721AssetFrom(sellOrder.erc721Token, sellOrder.maker, buyOrder.maker, sellOrder.erc721TokenId);

        // Handle the ERC20 side of the order:
        if (address(sellOrder.erc20Token) == NATIVE_TOKEN_ADDRESS && buyOrder.erc20Token == WETH) {
            // The sell order specifies ETH, while the buy order specifies WETH.
            // The orders are still compatible with one another, but we'll have
            // to unwrap the WETH on behalf of the buyer.

            // Step 1: Transfer WETH from the buyer to the EP.
            //         Note that we transfer `buyOrder.erc20TokenAmount`, which
            //         is the amount the buyer signaled they are willing to pay
            //         for the ERC721 asset, which may be more than the seller's
            //         ask.
            _transferERC20TokensFrom(WETH, buyOrder.maker, address(this), buyOrder.erc20TokenAmount);
            // Step 2: Unwrap the WETH into ETH. We unwrap the entire
            //         `buyOrder.erc20TokenAmount`.
            //         The ETH will be used for three purposes:
            //         - To pay the seller
            //         - To pay fees for the sell order
            //         - Any remaining ETH will be sent to
            //           `msg.sender` as profit.
            WETH.withdraw(buyOrder.erc20TokenAmount);

            // Step 3: Pay the seller (in ETH).
            _transferEth(payable(sellOrder.maker), sellOrder.erc20TokenAmount);

            // Step 4: Pay fees for the buy order. Note that these are paid
            //         in _WETH_ by the _buyer_. By signing the buy order, the
            //         buyer signals that they are willing to spend a total
            //         of `erc20TokenAmount` _plus_ fees, all denominated in
            //         the `erc20Token`, which in this case is WETH.
            _payFees(
                buyNFTOrder,
                buyOrder.maker, // payer
                1, // fillAmount
                1, // orderAmount
                false // useNativeToken
            );

            // Step 5: Pay fees for the sell order. The `erc20Token` of the
            //         sell order is ETH, so the fees are paid out in ETH.
            //         There should be `spread` wei of ETH remaining in the
            //         EP at this point, which we will use ETH to pay the
            //         sell order fees.
            uint256 sellOrderFees = _payFees(
                sellNFTOrder,
                address(this), // payer
                1, // fillAmount
                1, // orderAmount
                true // useNativeToken
            );

            // Step 6: The spread must be enough to cover the sell order fees.
            //         If not, either `_payFees` will have reverted, or we
            //         have spent ETH that was in the EP before this
            //         `matchERC721Orders` call, which we disallow.
            if (spread < sellOrderFees) {
                LibNFTOrdersRichErrors.SellOrderFeesExceedSpreadError(sellOrderFees, spread).rrevert();
            }
            // Step 7: The spread less the sell order fees is the amount of ETH
            //         remaining in the EP that can be sent to `msg.sender` as
            //         the profit from matching these two orders.
            profit = spread - sellOrderFees;
            if (profit > 0) {
                _transferEth(msg.sender, profit);
            }
        } else {
            // ERC20 tokens must match
            if (sellOrder.erc20Token != buyOrder.erc20Token) {
                LibNFTOrdersRichErrors
                    .ERC20TokenMismatchError(address(sellOrder.erc20Token), address(buyOrder.erc20Token))
                    .rrevert();
            }

            // Step 1: Transfer the ERC20 token from the buyer to the seller.
            //         Note that we transfer `sellOrder.erc20TokenAmount`, which
            //         is at most `buyOrder.erc20TokenAmount`.
            _transferERC20TokensFrom(buyOrder.erc20Token, buyOrder.maker, sellOrder.maker, sellOrder.erc20TokenAmount);

            // Step 2: Pay fees for the buy order. Note that these are paid
            //         by the buyer. By signing the buy order, the buyer signals
            //         that they are willing to spend a total of
            //         `buyOrder.erc20TokenAmount` _plus_ `buyOrder.fees`.
            _payFees(
                buyNFTOrder,
                buyOrder.maker, // payer
                1, // fillAmount
                1, // orderAmount
                false // useNativeToken
            );

            // Step 3: Pay fees for the sell order. These are paid by the buyer
            //         as well. After paying these fees, we may have taken more
            //         from the buyer than they agreed to in the buy order. If
            //         so, we revert in the following step.
            uint256 sellOrderFees = _payFees(
                sellNFTOrder,
                buyOrder.maker, // payer
                1, // fillAmount
                1, // orderAmount
                false // useNativeToken
            );

            // Step 4: The spread must be enough to cover the sell order fees.
            //         If not, `_payFees` will have taken more tokens from the
            //         buyer than they had agreed to in the buy order, in which
            //         case we revert here.
            if (spread < sellOrderFees) {
                LibNFTOrdersRichErrors.SellOrderFeesExceedSpreadError(sellOrderFees, spread).rrevert();
            }

            // Step 5: We calculate the profit as:
            //         profit = buyOrder.erc20TokenAmount - sellOrder.erc20TokenAmount - sellOrderFees
            //                = spread - sellOrderFees
            //         I.e. the buyer would've been willing to pay up to `profit`
            //         more to buy the asset, so instead that amount is sent to
            //         `msg.sender` as the profit from matching these two orders.
            profit = spread - sellOrderFees;
            if (profit > 0) {
                _transferERC20TokensFrom(buyOrder.erc20Token, buyOrder.maker, msg.sender, profit);
            }
        }

        emit ERC721OrderFilled(
            sellOrder.direction,
            sellOrder.maker,
            buyOrder.maker, // taker
            sellOrder.nonce,
            sellOrder.erc20Token,
            sellOrder.erc20TokenAmount,
            sellOrder.erc721Token,
            sellOrder.erc721TokenId,
            msg.sender
        );

        emit ERC721OrderFilled(
            buyOrder.direction,
            buyOrder.maker,
            sellOrder.maker, // taker
            buyOrder.nonce,
            buyOrder.erc20Token,
            buyOrder.erc20TokenAmount,
            buyOrder.erc721Token,
            sellOrder.erc721TokenId,
            msg.sender
        );
    }

    /// @dev Matches pairs of complementary orders that have
    ///      non-negative spreads. Each order is filled at
    ///      their respective price, and the matcher receives
    ///      a profit denominated in the ERC20 token.
    /// @param sellOrders Orders selling ERC721 assets.
    /// @param buyOrders Orders buying ERC721 assets.
    /// @param sellOrderSignatures Signatures for the sell orders.
    /// @param buyOrderSignatures Signatures for the buy orders.
    /// @return profits The amount of profit earned by the caller
    ///         of this function for each pair of matched orders
    ///         (denominated in the ERC20 token of the order pair).
    /// @return successes An array of booleans corresponding to
    ///         whether each pair of orders was successfully matched.
    function batchMatchERC721Orders(
        LibNFTOrder.ERC721Order[] memory sellOrders,
        LibNFTOrder.ERC721Order[] memory buyOrders,
        LibSignature.Signature[] memory sellOrderSignatures,
        LibSignature.Signature[] memory buyOrderSignatures
    ) public override returns (uint256[] memory profits, bool[] memory successes) {
        require(
            sellOrders.length == buyOrders.length &&
                sellOrderSignatures.length == buyOrderSignatures.length &&
                sellOrders.length == sellOrderSignatures.length,
            "ERC721OrdersFeature::batchMatchERC721Orders/ARRAY_LENGTH_MISMATCH"
        );
        profits = new uint256[](sellOrders.length);
        successes = new bool[](sellOrders.length);

        for (uint256 i = 0; i < sellOrders.length; i++) {
            bytes memory returnData;
            // Delegatecall `matchERC721Orders` to catch reverts while
            // preserving execution context.
            (successes[i], returnData) = _implementation.delegatecall(
                abi.encodeWithSelector(
                    this.matchERC721Orders.selector,
                    sellOrders[i],
                    buyOrders[i],
                    sellOrderSignatures[i],
                    buyOrderSignatures[i]
                )
            );
            if (successes[i]) {
                // If the matching succeeded, record the profit.
                uint256 profit = abi.decode(returnData, (uint256));
                profits[i] = profit;
            }
        }
    }

    /// @dev Callback for the ERC721 `safeTransferFrom` function.
    ///      This callback can be used to sell an ERC721 asset if
    ///      a valid ERC721 order, signature and `unwrapNativeToken`
    ///      are encoded in `data`. This allows takers to sell their
    ///      ERC721 asset without first calling `setApprovalForAll`.
    /// @param operator The address which called `safeTransferFrom`.
    /// @param tokenId The ID of the asset being transferred.
    /// @param data Additional data with no specified format. If a
    ///        valid ERC721 order, signature and `unwrapNativeToken`
    ///        are encoded in `data`, this function will try to fill
    ///        the order using the received asset.
    /// @return success The selector of this function (0x150b7a02),
    ///         indicating that the callback succeeded.
    function onERC721Received(
        address operator,
        address /* from */,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4 success) {
        // Decode the order, signature, and `unwrapNativeToken` from
        // `data`. If `data` does not encode such parameters, this
        // will throw.
        (LibNFTOrder.ERC721Order memory buyOrder, LibSignature.Signature memory signature, bool unwrapNativeToken) = abi
            .decode(data, (LibNFTOrder.ERC721Order, LibSignature.Signature, bool));

        // `onERC721Received` is called by the ERC721 token contract.
        // Check that it matches the ERC721 token in the order.
        if (msg.sender != address(buyOrder.erc721Token)) {
            LibNFTOrdersRichErrors.ERC721TokenMismatchError(msg.sender, address(buyOrder.erc721Token)).rrevert();
        }

        _sellERC721(
            buyOrder,
            signature,
            tokenId,
            unwrapNativeToken,
            operator, // taker
            address(this), // owner (we hold the NFT currently)
            new bytes(0) // No taker callback
        );

        return ERC721_RECEIVED_MAGIC_BYTES;
    }

    /// @dev Approves an ERC721 order on-chain. After pre-signing
    ///      the order, the `PRESIGNED` signature type will become
    ///      valid for that order and signer.
    /// @param order An ERC721 order.
    function preSignERC721Order(LibNFTOrder.ERC721Order memory order) public override {
        require(order.maker == msg.sender, "ERC721OrdersFeature::preSignERC721Order/ONLY_MAKER");
        bytes32 orderHash = getERC721OrderHash(order);
        LibERC721OrdersStorage.getStorage().preSigned[orderHash] = true;

        emit ERC721OrderPreSigned(
            order.direction,
            order.maker,
            order.taker,
            order.expiry,
            order.nonce,
            order.erc20Token,
            order.erc20TokenAmount,
            order.fees,
            order.erc721Token,
            order.erc721TokenId,
            order.erc721TokenProperties
        );
    }

    // Core settlement logic for selling an ERC721 asset.
    // Used by `sellERC721` and `onERC721Received`.
    function _sellERC721(
        LibNFTOrder.ERC721Order memory buyOrder,
        LibSignature.Signature memory signature,
        uint256 erc721TokenId,
        bool unwrapNativeToken,
        address taker,
        address currentNftOwner,
        bytes memory takerCallbackData
    ) private {
        _sellNFT(
            buyOrder.asNFTOrder(),
            signature,
            SellParams(
                1, // sell amount
                erc721TokenId,
                unwrapNativeToken,
                taker,
                currentNftOwner,
                takerCallbackData
            )
        );

        emit ERC721OrderFilled(
            buyOrder.direction,
            buyOrder.maker,
            taker,
            buyOrder.nonce,
            buyOrder.erc20Token,
            buyOrder.erc20TokenAmount,
            buyOrder.erc721Token,
            erc721TokenId,
            address(0)
        );
    }

    // Core settlement logic for buying an ERC721 asset.
    // Used by `buyERC721` and `batchBuyERC721s`.
    function _buyERC721(
        LibNFTOrder.ERC721Order memory sellOrder,
        LibSignature.Signature memory signature,
        uint256 ethAvailable,
        bytes memory takerCallbackData
    ) public payable {
        _buyNFT(
            sellOrder.asNFTOrder(),
            signature,
            BuyParams(
                1, // buy amount
                ethAvailable,
                takerCallbackData
            )
        );

        emit ERC721OrderFilled(
            sellOrder.direction,
            sellOrder.maker,
            msg.sender,
            sellOrder.nonce,
            sellOrder.erc20Token,
            sellOrder.erc20TokenAmount,
            sellOrder.erc721Token,
            sellOrder.erc721TokenId,
            address(0)
        );
    }

    /// @dev Checks whether the given signature is valid for the
    ///      the given ERC721 order. Reverts if not.
    /// @param order The ERC721 order.
    /// @param signature The signature to validate.
    function validateERC721OrderSignature(
        LibNFTOrder.ERC721Order memory order,
        LibSignature.Signature memory signature
    ) public view override {
        bytes32 orderHash = getERC721OrderHash(order);
        _validateOrderSignature(orderHash, signature, order.maker);
    }

    /// @dev Validates that the given signature is valid for the
    ///      given maker and order hash. Reverts if the signature
    ///      is not valid.
    /// @param orderHash The hash of the order that was signed.
    /// @param signature The signature to check.
    /// @param maker The maker of the order.
    function _validateOrderSignature(
        bytes32 orderHash,
        LibSignature.Signature memory signature,
        address maker
    ) internal view override {
        if (signature.signatureType == LibSignature.SignatureType.PRESIGNED) {
            // Check if order hash has been pre-signed by the maker.
            bool isPreSigned = LibERC721OrdersStorage.getStorage().preSigned[orderHash];
            if (!isPreSigned) {
                LibNFTOrdersRichErrors.InvalidSignerError(maker, address(0)).rrevert();
            }
        } else {
            address signer = LibSignature.getSignerOfHash(orderHash, signature);
            if (signer != maker) {
                LibNFTOrdersRichErrors.InvalidSignerError(maker, signer).rrevert();
            }
        }
    }

    /// @dev Transfers an NFT asset.
    /// @param token The address of the NFT contract.
    /// @param from The address currently holding the asset.
    /// @param to The address to transfer the asset to.
    /// @param tokenId The ID of the asset to transfer.
    /// @param amount The amount of the asset to transfer. Always
    ///        1 for ERC721 assets.
    function _transferNFTAssetFrom(
        address token,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal override {
        assert(amount == 1);
        _transferERC721AssetFrom(IERC721Token(token), from, to, tokenId);
    }

    /// @dev Updates storage to indicate that the given order
    ///      has been filled by the given amount.
    /// @param order The order that has been filled.
    /// @param fillAmount The amount (denominated in the NFT asset)
    ///        that the order has been filled by.
    function _updateOrderState(
        LibNFTOrder.NFTOrder memory order,
        bytes32 /* orderHash */,
        uint128 fillAmount
    ) internal override {
        assert(fillAmount == 1);
        _setOrderStatusBit(order.maker, order.nonce);
    }

    function _setOrderStatusBit(address maker, uint256 nonce) private {
        // The bitvector is indexed by the lower 8 bits of the nonce.
        uint256 flag = 1 << (nonce & 255);
        // Update order status bit vector to indicate that the given order
        // has been cancelled/filled by setting the designated bit to 1.
        LibERC721OrdersStorage.getStorage().orderStatusByMaker[maker][uint248(nonce >> 8)] |= flag;
    }

    /// @dev If the given order is buying an ERC721 asset, checks
    ///      whether or not the given token ID satisfies the required
    ///      properties specified in the order. If the order does not
    ///      specify any properties, this function instead checks
    ///      whether the given token ID matches the ID in the order.
    ///      Reverts if any checks fail, or if the order is selling
    ///      an ERC721 asset.
    /// @param order The ERC721 order.
    /// @param erc721TokenId The ID of the ERC721 asset.
    function validateERC721OrderProperties(
        LibNFTOrder.ERC721Order memory order,
        uint256 erc721TokenId
    ) public view override {
        _validateOrderProperties(order.asNFTOrder(), erc721TokenId);
    }

    /// @dev Get the current status of an ERC721 order.
    /// @param order The ERC721 order.
    /// @return status The status of the order.
    function getERC721OrderStatus(
        LibNFTOrder.ERC721Order memory order
    ) public view override returns (LibNFTOrder.OrderStatus status) {
        // Only buy orders with `erc721TokenId` == 0 can be property
        // orders.
        if (
            order.erc721TokenProperties.length > 0 &&
            (order.direction != LibNFTOrder.TradeDirection.BUY_NFT || order.erc721TokenId != 0)
        ) {
            return LibNFTOrder.OrderStatus.INVALID;
        }

        // Buy orders cannot use ETH as the ERC20 token, since ETH cannot be
        // transferred from the buyer by a contract.
        if (
            order.direction == LibNFTOrder.TradeDirection.BUY_NFT && address(order.erc20Token) == NATIVE_TOKEN_ADDRESS
        ) {
            return LibNFTOrder.OrderStatus.INVALID;
        }

        // Check for expiry.
        if (order.expiry <= block.timestamp) {
            return LibNFTOrder.OrderStatus.EXPIRED;
        }

        // Check `orderStatusByMaker` state variable to see if the order
        // has been cancelled or previously filled.
        LibERC721OrdersStorage.Storage storage stor = LibERC721OrdersStorage.getStorage();
        // `orderStatusByMaker` is indexed by maker and nonce.
        uint256 orderStatusBitVector = stor.orderStatusByMaker[order.maker][uint248(order.nonce >> 8)];
        // The bitvector is indexed by the lower 8 bits of the nonce.
        uint256 flag = 1 << (order.nonce & 255);
        // If the designated bit is set, the order has been cancelled or
        // previously filled, so it is now unfillable.
        if (orderStatusBitVector & flag != 0) {
            return LibNFTOrder.OrderStatus.UNFILLABLE;
        }

        // Otherwise, the order is fillable.
        return LibNFTOrder.OrderStatus.FILLABLE;
    }

    /// @dev Get the order info for an NFT order.
    /// @param order The NFT order.
    /// @return orderInfo Info about the order.
    function _getOrderInfo(
        LibNFTOrder.NFTOrder memory order
    ) internal view override returns (LibNFTOrder.OrderInfo memory orderInfo) {
        LibNFTOrder.ERC721Order memory erc721Order = order.asERC721Order();
        orderInfo.orderHash = getERC721OrderHash(erc721Order);
        orderInfo.status = getERC721OrderStatus(erc721Order);
        orderInfo.orderAmount = 1;
        orderInfo.remainingAmount = orderInfo.status == LibNFTOrder.OrderStatus.FILLABLE ? 1 : 0;
    }

    /// @dev Get the EIP-712 hash of an ERC721 order.
    /// @param order The ERC721 order.
    /// @return orderHash The order hash.
    function getERC721OrderHash(LibNFTOrder.ERC721Order memory order) public view override returns (bytes32 orderHash) {
        return _getEIP712Hash(LibNFTOrder.getERC721OrderStructHash(order));
    }

    /// @dev Get the order status bit vector for the given
    ///      maker address and nonce range.
    /// @param maker The maker of the order.
    /// @param nonceRange Order status bit vectors are indexed
    ///        by maker address and the upper 248 bits of the
    ///        order nonce. We define `nonceRange` to be these
    ///        248 bits.
    /// @return bitVector The order status bit vector for the
    ///         given maker and nonce range.
    function getERC721OrderStatusBitVector(
        address maker,
        uint248 nonceRange
    ) external view override returns (uint256 bitVector) {
        LibERC721OrdersStorage.Storage storage stor = LibERC721OrdersStorage.getStorage();
        return stor.orderStatusByMaker[maker][nonceRange];
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IEtherTokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibMathV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../../errors/LibNFTOrdersRichErrors.sol";
import "../../fixins/FixinCommon.sol";
import "../../fixins/FixinEIP712.sol";
import "../../fixins/FixinTokenSpender.sol";
import "../../migrations/LibMigrate.sol";
import "../../vendor/IFeeRecipient.sol";
import "../../vendor/ITakerCallback.sol";
import "../libs/LibSignature.sol";
import "../libs/LibNFTOrder.sol";

/// @dev Abstract base contract inherited by ERC721OrdersFeature and NFTOrders
abstract contract NFTOrders is FixinCommon, FixinEIP712, FixinTokenSpender {
    using LibSafeMathV06 for uint256;

    /// @dev Native token pseudo-address.
    address internal constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    /// @dev The WETH token contract.
    IEtherTokenV06 internal immutable WETH;

    /// @dev The magic return value indicating the success of a `receiveZeroExFeeCallback`.
    bytes4 private constant FEE_CALLBACK_MAGIC_BYTES = IFeeRecipient.receiveZeroExFeeCallback.selector;
    /// @dev The magic return value indicating the success of a `zeroExTakerCallback`.
    bytes4 private constant TAKER_CALLBACK_MAGIC_BYTES = ITakerCallback.zeroExTakerCallback.selector;

    constructor(address zeroExAddress, IEtherTokenV06 weth) public FixinEIP712(zeroExAddress) {
        WETH = weth;
    }

    struct SellParams {
        uint128 sellAmount;
        uint256 tokenId;
        bool unwrapNativeToken;
        address taker;
        address currentNftOwner;
        bytes takerCallbackData;
    }

    struct BuyParams {
        uint128 buyAmount;
        uint256 ethAvailable;
        bytes takerCallbackData;
    }

    // Core settlement logic for selling an NFT asset.
    function _sellNFT(
        LibNFTOrder.NFTOrder memory buyOrder,
        LibSignature.Signature memory signature,
        SellParams memory params
    ) internal returns (uint256 erc20FillAmount) {
        LibNFTOrder.OrderInfo memory orderInfo = _getOrderInfo(buyOrder);
        // Check that the order can be filled.
        _validateBuyOrder(buyOrder, signature, orderInfo, params.taker, params.tokenId);

        if (params.sellAmount > orderInfo.remainingAmount) {
            LibNFTOrdersRichErrors.ExceedsRemainingOrderAmount(orderInfo.remainingAmount, params.sellAmount).rrevert();
        }

        _updateOrderState(buyOrder, orderInfo.orderHash, params.sellAmount);

        if (params.sellAmount == orderInfo.orderAmount) {
            erc20FillAmount = buyOrder.erc20TokenAmount;
        } else {
            // Rounding favors the order maker.
            erc20FillAmount = LibMathV06.getPartialAmountFloor(
                params.sellAmount,
                orderInfo.orderAmount,
                buyOrder.erc20TokenAmount
            );
        }

        if (params.unwrapNativeToken) {
            // The ERC20 token must be WETH for it to be unwrapped.
            if (buyOrder.erc20Token != WETH) {
                LibNFTOrdersRichErrors.ERC20TokenMismatchError(address(buyOrder.erc20Token), address(WETH)).rrevert();
            }
            // Transfer the WETH from the maker to the Exchange Proxy
            // so we can unwrap it before sending it to the seller.
            // TODO: Probably safe to just use WETH.transferFrom for some
            //       small gas savings
            _transferERC20TokensFrom(WETH, buyOrder.maker, address(this), erc20FillAmount);
            // Unwrap WETH into ETH.
            WETH.withdraw(erc20FillAmount);
            // Send ETH to the seller.
            _transferEth(payable(params.taker), erc20FillAmount);
        } else {
            // Transfer the ERC20 token from the buyer to the seller.
            _transferERC20TokensFrom(buyOrder.erc20Token, buyOrder.maker, params.taker, erc20FillAmount);
        }

        if (params.takerCallbackData.length > 0) {
            require(params.taker != address(this), "NFTOrders::_sellNFT/CANNOT_CALLBACK_SELF");
            // Invoke the callback
            bytes4 callbackResult = ITakerCallback(params.taker).zeroExTakerCallback(
                orderInfo.orderHash,
                params.takerCallbackData
            );
            // Check for the magic success bytes
            require(callbackResult == TAKER_CALLBACK_MAGIC_BYTES, "NFTOrders::_sellNFT/CALLBACK_FAILED");
        }

        // Transfer the NFT asset to the buyer.
        // If this function is called from the
        // `onNFTReceived` callback the Exchange Proxy
        // holds the asset. Otherwise, transfer it from
        // the seller.
        _transferNFTAssetFrom(buyOrder.nft, params.currentNftOwner, buyOrder.maker, params.tokenId, params.sellAmount);

        // The buyer pays the order fees.
        _payFees(buyOrder, buyOrder.maker, params.sellAmount, orderInfo.orderAmount, false);
    }

    // Core settlement logic for buying an NFT asset.
    function _buyNFT(
        LibNFTOrder.NFTOrder memory sellOrder,
        LibSignature.Signature memory signature,
        BuyParams memory params
    ) internal returns (uint256 erc20FillAmount) {
        LibNFTOrder.OrderInfo memory orderInfo = _getOrderInfo(sellOrder);
        // Check that the order can be filled.
        _validateSellOrder(sellOrder, signature, orderInfo, msg.sender);

        if (params.buyAmount > orderInfo.remainingAmount) {
            LibNFTOrdersRichErrors.ExceedsRemainingOrderAmount(orderInfo.remainingAmount, params.buyAmount).rrevert();
        }

        _updateOrderState(sellOrder, orderInfo.orderHash, params.buyAmount);

        if (params.buyAmount == orderInfo.orderAmount) {
            erc20FillAmount = sellOrder.erc20TokenAmount;
        } else {
            // Rounding favors the order maker.
            erc20FillAmount = LibMathV06.getPartialAmountCeil(
                params.buyAmount,
                orderInfo.orderAmount,
                sellOrder.erc20TokenAmount
            );
        }

        // Transfer the NFT asset to the buyer (`msg.sender`).
        _transferNFTAssetFrom(sellOrder.nft, sellOrder.maker, msg.sender, sellOrder.nftId, params.buyAmount);

        uint256 ethAvailable = params.ethAvailable;
        if (params.takerCallbackData.length > 0) {
            require(msg.sender != address(this), "NFTOrders::_buyNFT/CANNOT_CALLBACK_SELF");
            uint256 ethBalanceBeforeCallback = address(this).balance;
            // Invoke the callback
            bytes4 callbackResult = ITakerCallback(msg.sender).zeroExTakerCallback(
                orderInfo.orderHash,
                params.takerCallbackData
            );
            // Update `ethAvailable` with amount acquired during
            // the callback
            ethAvailable = ethAvailable.safeAdd(address(this).balance.safeSub(ethBalanceBeforeCallback));
            // Check for the magic success bytes
            require(callbackResult == TAKER_CALLBACK_MAGIC_BYTES, "NFTOrders::_buyNFT/CALLBACK_FAILED");
        }

        if (address(sellOrder.erc20Token) == NATIVE_TOKEN_ADDRESS) {
            // Transfer ETH to the seller.
            _transferEth(payable(sellOrder.maker), erc20FillAmount);
            // Fees are paid from the EP's current balance of ETH.
            _payEthFees(sellOrder, params.buyAmount, orderInfo.orderAmount, erc20FillAmount, ethAvailable);
        } else if (sellOrder.erc20Token == WETH) {
            // If there is enough ETH available, fill the WETH order
            // (including fees) using that ETH.
            // Otherwise, transfer WETH from the taker.
            if (ethAvailable >= erc20FillAmount) {
                // Wrap ETH.
                WETH.deposit{value: erc20FillAmount}();
                // TODO: Probably safe to just use WETH.transfer for some
                //       small gas savings
                // Transfer WETH to the seller.
                _transferERC20Tokens(WETH, sellOrder.maker, erc20FillAmount);
                // Fees are paid from the EP's current balance of ETH.
                _payEthFees(sellOrder, params.buyAmount, orderInfo.orderAmount, erc20FillAmount, ethAvailable);
            } else {
                // Transfer WETH from the buyer to the seller.
                _transferERC20TokensFrom(sellOrder.erc20Token, msg.sender, sellOrder.maker, erc20FillAmount);
                // The buyer pays fees using WETH.
                _payFees(sellOrder, msg.sender, params.buyAmount, orderInfo.orderAmount, false);
            }
        } else {
            // Transfer ERC20 token from the buyer to the seller.
            _transferERC20TokensFrom(sellOrder.erc20Token, msg.sender, sellOrder.maker, erc20FillAmount);
            // The buyer pays fees.
            _payFees(sellOrder, msg.sender, params.buyAmount, orderInfo.orderAmount, false);
        }
    }

    function _validateSellOrder(
        LibNFTOrder.NFTOrder memory sellOrder,
        LibSignature.Signature memory signature,
        LibNFTOrder.OrderInfo memory orderInfo,
        address taker
    ) internal view {
        // Order must be selling the NFT asset.
        require(
            sellOrder.direction == LibNFTOrder.TradeDirection.SELL_NFT,
            "NFTOrders::_validateSellOrder/WRONG_TRADE_DIRECTION"
        );
        // Taker must match the order taker, if one is specified.
        if (sellOrder.taker != address(0) && sellOrder.taker != taker) {
            LibNFTOrdersRichErrors.OnlyTakerError(taker, sellOrder.taker).rrevert();
        }
        // Check that the order is valid and has not expired, been cancelled,
        // or been filled.
        if (orderInfo.status != LibNFTOrder.OrderStatus.FILLABLE) {
            LibNFTOrdersRichErrors
                .OrderNotFillableError(sellOrder.maker, sellOrder.nonce, uint8(orderInfo.status))
                .rrevert();
        }

        // Check the signature.
        _validateOrderSignature(orderInfo.orderHash, signature, sellOrder.maker);
    }

    function _validateBuyOrder(
        LibNFTOrder.NFTOrder memory buyOrder,
        LibSignature.Signature memory signature,
        LibNFTOrder.OrderInfo memory orderInfo,
        address taker,
        uint256 tokenId
    ) internal view {
        // Order must be buying the NFT asset.
        require(
            buyOrder.direction == LibNFTOrder.TradeDirection.BUY_NFT,
            "NFTOrders::_validateBuyOrder/WRONG_TRADE_DIRECTION"
        );
        // The ERC20 token cannot be ETH.
        require(
            address(buyOrder.erc20Token) != NATIVE_TOKEN_ADDRESS,
            "NFTOrders::_validateBuyOrder/NATIVE_TOKEN_NOT_ALLOWED"
        );
        // Taker must match the order taker, if one is specified.
        if (buyOrder.taker != address(0) && buyOrder.taker != taker) {
            LibNFTOrdersRichErrors.OnlyTakerError(taker, buyOrder.taker).rrevert();
        }
        // Check that the order is valid and has not expired, been cancelled,
        // or been filled.
        if (orderInfo.status != LibNFTOrder.OrderStatus.FILLABLE) {
            LibNFTOrdersRichErrors
                .OrderNotFillableError(buyOrder.maker, buyOrder.nonce, uint8(orderInfo.status))
                .rrevert();
        }
        // Check that the asset with the given token ID satisfies the properties
        // specified by the order.
        _validateOrderProperties(buyOrder, tokenId);
        // Check the signature.
        _validateOrderSignature(orderInfo.orderHash, signature, buyOrder.maker);
    }

    function _payEthFees(
        LibNFTOrder.NFTOrder memory order,
        uint128 fillAmount,
        uint128 orderAmount,
        uint256 ethSpent,
        uint256 ethAvailable
    ) private {
        // Pay fees using ETH.
        uint256 ethFees = _payFees(order, address(this), fillAmount, orderAmount, true);
        // Update amount of ETH spent.
        ethSpent = ethSpent.safeAdd(ethFees);
        if (ethSpent > ethAvailable) {
            LibNFTOrdersRichErrors.OverspentEthError(ethSpent, ethAvailable).rrevert();
        }
    }

    function _payFees(
        LibNFTOrder.NFTOrder memory order,
        address payer,
        uint128 fillAmount,
        uint128 orderAmount,
        bool useNativeToken
    ) internal returns (uint256 totalFeesPaid) {
        // Make assertions about ETH case
        if (useNativeToken) {
            assert(payer == address(this));
            assert(order.erc20Token == WETH || address(order.erc20Token) == NATIVE_TOKEN_ADDRESS);
        }

        for (uint256 i = 0; i < order.fees.length; i++) {
            LibNFTOrder.Fee memory fee = order.fees[i];

            require(fee.recipient != address(this), "NFTOrders::_payFees/RECIPIENT_CANNOT_BE_EXCHANGE_PROXY");

            uint256 feeFillAmount;
            if (fillAmount == orderAmount) {
                feeFillAmount = fee.amount;
            } else {
                // Round against the fee recipient
                feeFillAmount = LibMathV06.getPartialAmountFloor(fillAmount, orderAmount, fee.amount);
            }
            if (feeFillAmount == 0) {
                continue;
            }

            if (useNativeToken) {
                // Transfer ETH to the fee recipient.
                _transferEth(payable(fee.recipient), feeFillAmount);
            } else {
                // Transfer ERC20 token from payer to recipient.
                _transferERC20TokensFrom(order.erc20Token, payer, fee.recipient, feeFillAmount);
            }
            // Note that the fee callback is _not_ called if zero
            // `feeData` is provided. If `feeData` is provided, we assume
            // the fee recipient is a contract that implements the
            // `IFeeRecipient` interface.
            if (fee.feeData.length > 0) {
                // Invoke the callback
                bytes4 callbackResult = IFeeRecipient(fee.recipient).receiveZeroExFeeCallback(
                    useNativeToken ? NATIVE_TOKEN_ADDRESS : address(order.erc20Token),
                    feeFillAmount,
                    fee.feeData
                );
                // Check for the magic success bytes
                require(callbackResult == FEE_CALLBACK_MAGIC_BYTES, "NFTOrders::_payFees/CALLBACK_FAILED");
            }
            // Sum the fees paid
            totalFeesPaid = totalFeesPaid.safeAdd(feeFillAmount);
        }
    }

    /// @dev If the given order is buying an NFT asset, checks
    ///      whether or not the given token ID satisfies the required
    ///      properties specified in the order. If the order does not
    ///      specify any properties, this function instead checks
    ///      whether the given token ID matches the ID in the order.
    ///      Reverts if any checks fail, or if the order is selling
    ///      an NFT asset.
    /// @param order The NFT order.
    /// @param tokenId The ID of the NFT asset.
    function _validateOrderProperties(LibNFTOrder.NFTOrder memory order, uint256 tokenId) internal view {
        // Order must be buying an NFT asset to have properties.
        require(
            order.direction == LibNFTOrder.TradeDirection.BUY_NFT,
            "NFTOrders::_validateOrderProperties/WRONG_TRADE_DIRECTION"
        );

        // If no properties are specified, check that the given
        // `tokenId` matches the one specified in the order.
        if (order.nftProperties.length == 0) {
            if (tokenId != order.nftId) {
                LibNFTOrdersRichErrors.TokenIdMismatchError(tokenId, order.nftId).rrevert();
            }
        } else {
            // Validate each property
            for (uint256 i = 0; i < order.nftProperties.length; i++) {
                LibNFTOrder.Property memory property = order.nftProperties[i];
                // `address(0)` is interpreted as a no-op. Any token ID
                // will satisfy a property with `propertyValidator == address(0)`.
                if (address(property.propertyValidator) == address(0)) {
                    continue;
                }

                // Call the property validator and throw a descriptive error
                // if the call reverts.
                try property.propertyValidator.validateProperty(order.nft, tokenId, property.propertyData) {} catch (
                    bytes memory errorData
                ) {
                    LibNFTOrdersRichErrors
                        .PropertyValidationFailedError(
                            address(property.propertyValidator),
                            order.nft,
                            tokenId,
                            property.propertyData,
                            errorData
                        )
                        .rrevert();
                }
            }
        }
    }

    /// @dev Validates that the given signature is valid for the
    ///      given maker and order hash. Reverts if the signature
    ///      is not valid.
    /// @param orderHash The hash of the order that was signed.
    /// @param signature The signature to check.
    /// @param maker The maker of the order.
    function _validateOrderSignature(
        bytes32 orderHash,
        LibSignature.Signature memory signature,
        address maker
    ) internal view virtual;

    /// @dev Transfers an NFT asset.
    /// @param token The address of the NFT contract.
    /// @param from The address currently holding the asset.
    /// @param to The address to transfer the asset to.
    /// @param tokenId The ID of the asset to transfer.
    /// @param amount The amount of the asset to transfer. Always
    ///        1 for ERC721 assets.
    function _transferNFTAssetFrom(
        address token,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal virtual;

    /// @dev Updates storage to indicate that the given order
    ///      has been filled by the given amount.
    /// @param order The order that has been filled.
    /// @param orderHash The hash of `order`.
    /// @param fillAmount The amount (denominated in the NFT asset)
    ///        that the order has been filled by.
    function _updateOrderState(
        LibNFTOrder.NFTOrder memory order,
        bytes32 orderHash,
        uint128 fillAmount
    ) internal virtual;

    /// @dev Get the order info for an NFT order.
    /// @param order The NFT order.
    /// @return orderInfo Info about the order.
    function _getOrderInfo(
        LibNFTOrder.NFTOrder memory order
    ) internal view virtual returns (LibNFTOrder.OrderInfo memory orderInfo);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IEtherTokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibMathV06.sol";
import "../errors/LibNativeOrdersRichErrors.sol";
import "../fixins/FixinCommon.sol";
import "../fixins/FixinEIP712.sol";
import "../fixins/FixinTokenSpender.sol";
import "../migrations/LibMigrate.sol";
import "../storage/LibNativeOrdersStorage.sol";
import "../storage/LibOtcOrdersStorage.sol";
import "./interfaces/IFeature.sol";
import "./interfaces/IOtcOrdersFeature.sol";
import "./libs/LibNativeOrder.sol";
import "./libs/LibSignature.sol";

/// @dev Feature for interacting with OTC orders.
contract OtcOrdersFeature is IFeature, IOtcOrdersFeature, FixinCommon, FixinEIP712, FixinTokenSpender {
    using LibSafeMathV06 for uint256;
    using LibSafeMathV06 for uint128;

    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "OtcOrders";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 0);
    /// @dev ETH pseudo-token address.
    address private constant ETH_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    /// @dev The WETH token contract.
    IEtherTokenV06 private immutable WETH;

    constructor(address zeroExAddress, IEtherTokenV06 weth) public FixinEIP712(zeroExAddress) {
        WETH = weth;
    }

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external returns (bytes4 success) {
        _registerFeatureFunction(this.fillOtcOrder.selector);
        _registerFeatureFunction(this.fillOtcOrderForEth.selector);
        _registerFeatureFunction(this.fillOtcOrderWithEth.selector);
        _registerFeatureFunction(this.fillTakerSignedOtcOrderForEth.selector);
        _registerFeatureFunction(this.fillTakerSignedOtcOrder.selector);
        _registerFeatureFunction(this.batchFillTakerSignedOtcOrders.selector);
        _registerFeatureFunction(this._fillOtcOrder.selector);
        _registerFeatureFunction(this.getOtcOrderInfo.selector);
        _registerFeatureFunction(this.getOtcOrderHash.selector);
        _registerFeatureFunction(this.lastOtcTxOriginNonce.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @dev Fill an OTC order for up to `takerTokenFillAmount` taker tokens.
    /// @param order The OTC order.
    /// @param makerSignature The order signature from the maker.
    /// @param takerTokenFillAmount Maximum taker token amount to fill this
    ///        order with.
    /// @return takerTokenFilledAmount How much taker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function fillOtcOrder(
        LibNativeOrder.OtcOrder memory order,
        LibSignature.Signature memory makerSignature,
        uint128 takerTokenFillAmount
    ) public override returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount) {
        LibNativeOrder.OtcOrderInfo memory orderInfo = getOtcOrderInfo(order);
        _validateOtcOrder(order, orderInfo, makerSignature, msg.sender);
        (takerTokenFilledAmount, makerTokenFilledAmount) = _settleOtcOrder(
            order,
            takerTokenFillAmount,
            msg.sender,
            msg.sender
        );

        emit OtcOrderFilled(
            orderInfo.orderHash,
            order.maker,
            msg.sender,
            address(order.makerToken),
            address(order.takerToken),
            makerTokenFilledAmount,
            takerTokenFilledAmount
        );
    }

    /// @dev Fill an OTC order for up to `takerTokenFillAmount` taker tokens.
    ///      Unwraps bought WETH into ETH. before sending it to
    ///      the taker.
    /// @param order The OTC order.
    /// @param makerSignature The order signature from the maker.
    /// @param takerTokenFillAmount Maximum taker token amount to fill this
    ///        order with.
    /// @return takerTokenFilledAmount How much taker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function fillOtcOrderForEth(
        LibNativeOrder.OtcOrder memory order,
        LibSignature.Signature memory makerSignature,
        uint128 takerTokenFillAmount
    ) public override returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount) {
        require(order.makerToken == WETH, "OtcOrdersFeature::fillOtcOrderForEth/MAKER_TOKEN_NOT_WETH");
        LibNativeOrder.OtcOrderInfo memory orderInfo = getOtcOrderInfo(order);
        _validateOtcOrder(order, orderInfo, makerSignature, msg.sender);
        (takerTokenFilledAmount, makerTokenFilledAmount) = _settleOtcOrder(
            order,
            takerTokenFillAmount,
            msg.sender,
            address(this)
        );
        // Unwrap WETH
        WETH.withdraw(makerTokenFilledAmount);
        // Transfer ETH to taker
        _transferEth(msg.sender, makerTokenFilledAmount);

        emit OtcOrderFilled(
            orderInfo.orderHash,
            order.maker,
            msg.sender,
            address(order.makerToken),
            address(order.takerToken),
            makerTokenFilledAmount,
            takerTokenFilledAmount
        );
    }

    /// @dev Fill an OTC order whose taker token is WETH for up
    ///      to `msg.value`.
    /// @param order The OTC order.
    /// @param makerSignature The order signature from the maker.
    /// @return takerTokenFilledAmount How much taker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function fillOtcOrderWithEth(
        LibNativeOrder.OtcOrder memory order,
        LibSignature.Signature memory makerSignature
    ) public payable override returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount) {
        if (order.takerToken == WETH) {
            // Wrap ETH
            WETH.deposit{value: msg.value}();
        } else {
            require(
                address(order.takerToken) == ETH_TOKEN_ADDRESS,
                "OtcOrdersFeature::fillOtcOrderWithEth/INVALID_TAKER_TOKEN"
            );
        }

        LibNativeOrder.OtcOrderInfo memory orderInfo = getOtcOrderInfo(order);
        _validateOtcOrder(order, orderInfo, makerSignature, msg.sender);

        (takerTokenFilledAmount, makerTokenFilledAmount) = _settleOtcOrder(
            order,
            msg.value.safeDowncastToUint128(),
            address(this),
            msg.sender
        );
        if (takerTokenFilledAmount < msg.value) {
            uint256 refundAmount = msg.value - uint256(takerTokenFilledAmount);
            if (order.takerToken == WETH) {
                WETH.withdraw(refundAmount);
            }
            // Refund unused ETH
            _transferEth(msg.sender, refundAmount);
        }

        emit OtcOrderFilled(
            orderInfo.orderHash,
            order.maker,
            msg.sender,
            address(order.makerToken),
            address(order.takerToken),
            makerTokenFilledAmount,
            takerTokenFilledAmount
        );
    }

    /// @dev Fully fill an OTC order. "Meta-transaction" variant,
    ///      requires order to be signed by both maker and taker.
    /// @param order The OTC order.
    /// @param makerSignature The order signature from the maker.
    /// @param takerSignature The order signature from the taker.
    function fillTakerSignedOtcOrder(
        LibNativeOrder.OtcOrder memory order,
        LibSignature.Signature memory makerSignature,
        LibSignature.Signature memory takerSignature
    ) public override {
        LibNativeOrder.OtcOrderInfo memory orderInfo = getOtcOrderInfo(order);
        address taker = LibSignature.getSignerOfHash(orderInfo.orderHash, takerSignature);

        _validateOtcOrder(order, orderInfo, makerSignature, taker);
        _settleOtcOrder(order, order.takerAmount, taker, taker);

        emit OtcOrderFilled(
            orderInfo.orderHash,
            order.maker,
            taker,
            address(order.makerToken),
            address(order.takerToken),
            order.makerAmount,
            order.takerAmount
        );
    }

    /// @dev Fully fill an OTC order. "Meta-transaction" variant,
    ///      requires order to be signed by both maker and taker.
    ///      Unwraps bought WETH into ETH. before sending it to
    ///      the taker.
    /// @param order The OTC order.
    /// @param makerSignature The order signature from the maker.
    /// @param takerSignature The order signature from the taker.
    function fillTakerSignedOtcOrderForEth(
        LibNativeOrder.OtcOrder memory order,
        LibSignature.Signature memory makerSignature,
        LibSignature.Signature memory takerSignature
    ) public override {
        require(order.makerToken == WETH, "OtcOrdersFeature::fillTakerSignedOtcOrder/MAKER_TOKEN_NOT_WETH");
        LibNativeOrder.OtcOrderInfo memory orderInfo = getOtcOrderInfo(order);
        address taker = LibSignature.getSignerOfHash(orderInfo.orderHash, takerSignature);

        _validateOtcOrder(order, orderInfo, makerSignature, taker);
        _settleOtcOrder(order, order.takerAmount, taker, address(this));
        // Unwrap WETH
        WETH.withdraw(order.makerAmount);
        // Transfer ETH to taker
        _transferEth(payable(taker), order.makerAmount);

        emit OtcOrderFilled(
            orderInfo.orderHash,
            order.maker,
            taker,
            address(order.makerToken),
            address(order.takerToken),
            order.makerAmount,
            order.takerAmount
        );
    }

    /// @dev Fills multiple taker-signed OTC orders.
    /// @param orders Array of OTC orders.
    /// @param makerSignatures Array of maker signatures for each order.
    /// @param takerSignatures Array of taker signatures for each order.
    /// @param unwrapWeth Array of booleans representing whether or not
    ///        to unwrap bought WETH into ETH for each order. Should be set
    ///        to false if the maker token is not WETH.
    /// @return successes Array of booleans representing whether or not
    ///         each order in `orders` was filled successfully.
    function batchFillTakerSignedOtcOrders(
        LibNativeOrder.OtcOrder[] memory orders,
        LibSignature.Signature[] memory makerSignatures,
        LibSignature.Signature[] memory takerSignatures,
        bool[] memory unwrapWeth
    ) public override returns (bool[] memory successes) {
        require(
            orders.length == makerSignatures.length &&
                orders.length == takerSignatures.length &&
                orders.length == unwrapWeth.length,
            "OtcOrdersFeature::batchFillTakerSignedOtcOrders/MISMATCHED_ARRAY_LENGTHS"
        );
        successes = new bool[](orders.length);
        for (uint256 i = 0; i != orders.length; i++) {
            bytes4 fnSelector = unwrapWeth[i]
                ? this.fillTakerSignedOtcOrderForEth.selector
                : this.fillTakerSignedOtcOrder.selector;
            // Swallow reverts
            (successes[i], ) = _implementation.delegatecall(
                abi.encodeWithSelector(fnSelector, orders[i], makerSignatures[i], takerSignatures[i])
            );
        }
    }

    /// @dev Fill an OTC order for up to `takerTokenFillAmount` taker tokens.
    ///      Internal variant.
    /// @param order The OTC order.
    /// @param makerSignature The order signature from the maker.
    /// @param takerTokenFillAmount Maximum taker token amount to fill this
    ///        order with.
    /// @param taker The address to fill the order in the context of.
    /// @param useSelfBalance Whether to use the Exchange Proxy's balance
    ///        of input tokens.
    /// @param recipient The recipient of the bought maker tokens.
    /// @return takerTokenFilledAmount How much taker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function _fillOtcOrder(
        LibNativeOrder.OtcOrder memory order,
        LibSignature.Signature memory makerSignature,
        uint128 takerTokenFillAmount,
        address taker,
        bool useSelfBalance,
        address recipient
    ) public override onlySelf returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount) {
        LibNativeOrder.OtcOrderInfo memory orderInfo = getOtcOrderInfo(order);
        _validateOtcOrder(order, orderInfo, makerSignature, taker);
        (takerTokenFilledAmount, makerTokenFilledAmount) = _settleOtcOrder(
            order,
            takerTokenFillAmount,
            useSelfBalance ? address(this) : taker,
            recipient
        );

        emit OtcOrderFilled(
            orderInfo.orderHash,
            order.maker,
            taker,
            address(order.makerToken),
            address(order.takerToken),
            makerTokenFilledAmount,
            takerTokenFilledAmount
        );
    }

    /// @dev Validates an OTC order, reverting if the order cannot be
    ///      filled by the given taker.
    /// @param order The OTC order.
    /// @param orderInfo Info on the order.
    /// @param makerSignature The order signature from the maker.
    /// @param taker The order taker.
    function _validateOtcOrder(
        LibNativeOrder.OtcOrder memory order,
        LibNativeOrder.OtcOrderInfo memory orderInfo,
        LibSignature.Signature memory makerSignature,
        address taker
    ) private view {
        // Must be fillable.
        if (orderInfo.status != LibNativeOrder.OrderStatus.FILLABLE) {
            LibNativeOrdersRichErrors.OrderNotFillableError(orderInfo.orderHash, uint8(orderInfo.status)).rrevert();
        }

        // Must be a valid taker for the order.
        if (order.taker != address(0) && order.taker != taker) {
            LibNativeOrdersRichErrors.OrderNotFillableByTakerError(orderInfo.orderHash, taker, order.taker).rrevert();
        }

        LibNativeOrdersStorage.Storage storage stor = LibNativeOrdersStorage.getStorage();

        // Must be fillable by the tx.origin.
        if (order.txOrigin != tx.origin && !stor.originRegistry[order.txOrigin][tx.origin]) {
            LibNativeOrdersRichErrors
                .OrderNotFillableByOriginError(orderInfo.orderHash, tx.origin, order.txOrigin)
                .rrevert();
        }

        // Maker signature must be valid for the order.
        address makerSigner = LibSignature.getSignerOfHash(orderInfo.orderHash, makerSignature);
        if (makerSigner != order.maker && !stor.orderSignerRegistry[order.maker][makerSigner]) {
            LibNativeOrdersRichErrors
                .OrderNotSignedByMakerError(orderInfo.orderHash, makerSigner, order.maker)
                .rrevert();
        }
    }

    /// @dev Settle the trade between an OTC order's maker and taker.
    /// @param order The OTC order.
    /// @param takerTokenFillAmount Maximum taker token amount to fill this
    ///        order with.
    /// @param payer The address holding the taker tokens.
    /// @param recipient The recipient of the maker tokens.
    /// @return takerTokenFilledAmount How much taker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function _settleOtcOrder(
        LibNativeOrder.OtcOrder memory order,
        uint128 takerTokenFillAmount,
        address payer,
        address recipient
    ) private returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount) {
        {
            // Unpack nonce fields
            uint64 nonceBucket = uint64(order.expiryAndNonce >> 128);
            uint128 nonce = uint128(order.expiryAndNonce);
            // Update tx origin nonce for the order
            LibOtcOrdersStorage.getStorage().txOriginNonces[order.txOrigin][nonceBucket] = nonce;
        }

        if (takerTokenFillAmount == order.takerAmount) {
            takerTokenFilledAmount = order.takerAmount;
            makerTokenFilledAmount = order.makerAmount;
        } else {
            // Clamp the taker token fill amount to the fillable amount.
            takerTokenFilledAmount = LibSafeMathV06.min128(takerTokenFillAmount, order.takerAmount);
            // Compute the maker token amount.
            // This should never overflow because the values are all clamped to
            // (2^128-1).
            makerTokenFilledAmount = uint128(
                LibMathV06.getPartialAmountFloor(
                    uint256(takerTokenFilledAmount),
                    uint256(order.takerAmount),
                    uint256(order.makerAmount)
                )
            );
        }

        if (payer == address(this)) {
            if (address(order.takerToken) == ETH_TOKEN_ADDRESS) {
                // Transfer ETH to the maker.
                payable(order.maker).transfer(takerTokenFilledAmount);
            } else {
                // Transfer this -> maker.
                _transferERC20Tokens(order.takerToken, order.maker, takerTokenFilledAmount);
            }
        } else {
            // Transfer taker -> maker
            _transferERC20TokensFrom(order.takerToken, payer, order.maker, takerTokenFilledAmount);
        }
        // Transfer maker -> recipient.
        _transferERC20TokensFrom(order.makerToken, order.maker, recipient, makerTokenFilledAmount);
    }

    /// @dev Get the order info for an OTC order.
    /// @param order The OTC order.
    /// @return orderInfo Info about the order.
    function getOtcOrderInfo(
        LibNativeOrder.OtcOrder memory order
    ) public view override returns (LibNativeOrder.OtcOrderInfo memory orderInfo) {
        // compute order hash.
        orderInfo.orderHash = getOtcOrderHash(order);

        LibOtcOrdersStorage.Storage storage stor = LibOtcOrdersStorage.getStorage();

        // Unpack expiry and nonce fields
        uint64 expiry = uint64(order.expiryAndNonce >> 192);
        uint64 nonceBucket = uint64(order.expiryAndNonce >> 128);
        uint128 nonce = uint128(order.expiryAndNonce);

        // check tx origin nonce
        uint128 lastNonce = stor.txOriginNonces[order.txOrigin][nonceBucket];
        if (nonce <= lastNonce) {
            orderInfo.status = LibNativeOrder.OrderStatus.INVALID;
            return orderInfo;
        }

        // Check for expiration.
        if (expiry <= uint64(block.timestamp)) {
            orderInfo.status = LibNativeOrder.OrderStatus.EXPIRED;
            return orderInfo;
        }

        orderInfo.status = LibNativeOrder.OrderStatus.FILLABLE;
        return orderInfo;
    }

    /// @dev Get the canonical hash of an OTC order.
    /// @param order The OTC order.
    /// @return orderHash The order hash.
    function getOtcOrderHash(LibNativeOrder.OtcOrder memory order) public view override returns (bytes32 orderHash) {
        return _getEIP712Hash(LibNativeOrder.getOtcOrderStructHash(order));
    }

    /// @dev Get the last nonce used for a particular
    ///      tx.origin address and nonce bucket.
    /// @param txOrigin The address.
    /// @param nonceBucket The nonce bucket index.
    /// @return lastNonce The last nonce value used.
    function lastOtcTxOriginNonce(
        address txOrigin,
        uint64 nonceBucket
    ) public view override returns (uint128 lastNonce) {
        LibOtcOrdersStorage.Storage storage stor = LibOtcOrdersStorage.getStorage();
        return stor.txOriginNonces[txOrigin][nonceBucket];
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "../fixins/FixinCommon.sol";
import "../errors/LibOwnableRichErrors.sol";
import "../storage/LibOwnableStorage.sol";
import "../migrations/LibBootstrap.sol";
import "../migrations/LibMigrate.sol";
import "./interfaces/IFeature.sol";
import "./interfaces/IOwnableFeature.sol";
import "./SimpleFunctionRegistryFeature.sol";

/// @dev Owner management features.
contract OwnableFeature is IFeature, IOwnableFeature, FixinCommon {
    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "Ownable";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 0);

    using LibRichErrorsV06 for bytes;

    /// @dev Initializes this feature. The intial owner will be set to this (ZeroEx)
    ///      to allow the bootstrappers to call `extend()`. Ownership should be
    ///      transferred to the real owner by the bootstrapper after
    ///      bootstrapping is complete.
    /// @return success Magic bytes if successful.
    function bootstrap() external returns (bytes4 success) {
        // Set the owner to ourselves to allow bootstrappers to call `extend()`.
        LibOwnableStorage.getStorage().owner = address(this);

        // Register feature functions.
        SimpleFunctionRegistryFeature(address(this))._extendSelf(this.transferOwnership.selector, _implementation);
        SimpleFunctionRegistryFeature(address(this))._extendSelf(this.owner.selector, _implementation);
        SimpleFunctionRegistryFeature(address(this))._extendSelf(this.migrate.selector, _implementation);
        return LibBootstrap.BOOTSTRAP_SUCCESS;
    }

    /// @dev Change the owner of this contract.
    ///      Only directly callable by the owner.
    /// @param newOwner New owner address.
    function transferOwnership(address newOwner) external override onlyOwner {
        LibOwnableStorage.Storage storage proxyStor = LibOwnableStorage.getStorage();

        if (newOwner == address(0)) {
            LibOwnableRichErrors.TransferOwnerToZeroError().rrevert();
        } else {
            proxyStor.owner = newOwner;
            emit OwnershipTransferred(msg.sender, newOwner);
        }
    }

    /// @dev Execute a migration function in the context of the ZeroEx contract.
    ///      The result of the function being called should be the magic bytes
    ///      0x2c64c5ef (`keccack('MIGRATE_SUCCESS')`). Only callable by the owner.
    ///      Temporarily sets the owner to ourselves so we can perform admin functions.
    ///      Before returning, the owner will be set to `newOwner`.
    /// @param target The migrator contract address.
    /// @param data The call data.
    /// @param newOwner The address of the new owner.
    function migrate(address target, bytes calldata data, address newOwner) external override onlyOwner {
        if (newOwner == address(0)) {
            LibOwnableRichErrors.TransferOwnerToZeroError().rrevert();
        }

        LibOwnableStorage.Storage storage stor = LibOwnableStorage.getStorage();
        // The owner will be temporarily set to `address(this)` inside the call.
        stor.owner = address(this);

        // Perform the migration.
        LibMigrate.delegatecallMigrateFunction(target, data);

        // Update the owner.
        stor.owner = newOwner;

        emit Migrated(msg.sender, target, newOwner);
    }

    /// @dev Get the owner of this contract.
    /// @return owner_ The owner of this contract.
    function owner() external view override returns (address owner_) {
        return LibOwnableStorage.getStorage().owner;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IEtherTokenV06.sol";
import "../migrations/LibMigrate.sol";
import "../fixins/FixinCommon.sol";
import "./interfaces/IFeature.sol";
import "./interfaces/IPancakeSwapFeature.sol";

/// @dev VIP pancake fill functions.
contract PancakeSwapFeature is IFeature, IPancakeSwapFeature, FixinCommon {
    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "PancakeSwapFeature";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 2);
    /// @dev WBNB contract.
    IEtherTokenV06 private immutable WBNB;

    // 0xFF + address of the PancakeSwap factory contract.
    uint256 private constant FF_PANCAKESWAP_FACTORY =
        0xffbcfccbde45ce874adcb698cc183debcf179528120000000000000000000000;
    // 0xFF + address of the PancakeSwapV2 factory contract.
    uint256 private constant FF_PANCAKESWAPV2_FACTORY =
        0xffca143ce32fe78f1f7019d7d551a6402fc5350c730000000000000000000000;
    // 0xFF + address of the BakerySwap factory contract.
    uint256 private constant FF_BAKERYSWAP_FACTORY = 0xff01bf7c66c6bd861915cdaae475042d3c4bae16a70000000000000000000000;
    // 0xFF + address of the SushiSwap factory contract.
    uint256 private constant FF_SUSHISWAP_FACTORY = 0xffc35DADB65012eC5796536bD9864eD8773aBc74C40000000000000000000000;
    // 0xFF + address of the ApeSwap factory contract.
    uint256 private constant FF_APESWAP_FACTORY = 0xff0841bd0b734e4f5853f0dd8d7ea041c241fb0da60000000000000000000000;
    // 0xFF + address of the CafeSwap factory contract.
    uint256 private constant FF_CAFESWAP_FACTORY = 0xff3e708fdbe3ada63fc94f8f61811196f1302137ad0000000000000000000000;
    // 0xFF + address of the CheeseSwap factory contract.
    uint256 private constant FF_CHEESESWAP_FACTORY = 0xffdd538e4fd1b69b7863e1f741213276a6cf1efb3b0000000000000000000000;
    // 0xFF + address of the JulSwap factory contract.
    uint256 private constant FF_JULSWAP_FACTORY = 0xff553990f2cba90272390f62c5bdb1681ffc8996750000000000000000000000;

    // Init code hash of the PancakeSwap pair contract.
    uint256 private constant PANCAKESWAP_PAIR_INIT_CODE_HASH =
        0xd0d4c4cd0848c93cb4fd1f498d7013ee6bfb25783ea21593d5834f5d250ece66;
    // Init code hash of the PancakeSwapV2 pair contract.
    uint256 private constant PANCAKESWAPV2_PAIR_INIT_CODE_HASH =
        0x00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5;
    // Init code hash of the BakerySwap pair contract.
    uint256 private constant BAKERYSWAP_PAIR_INIT_CODE_HASH =
        0xe2e87433120e32c4738a7d8f3271f3d872cbe16241d67537139158d90bac61d3;
    // Init code hash of the SushiSwap pair contract.
    uint256 private constant SUSHISWAP_PAIR_INIT_CODE_HASH =
        0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303;
    // Init code hash of the ApeSwap pair contract.
    uint256 private constant APESWAP_PAIR_INIT_CODE_HASH =
        0xf4ccce374816856d11f00e4069e7cada164065686fbef53c6167a63ec2fd8c5b;
    // Init code hash of the CafeSwap pair contract.
    uint256 private constant CAFESWAP_PAIR_INIT_CODE_HASH =
        0x90bcdb5d0bf0e8db3852b0b7d7e05cc8f7c6eb6d511213c5ba02d1d1dbeda8d3;
    // Init code hash of the CheeseSwap pair contract.
    uint256 private constant CHEESESWAP_PAIR_INIT_CODE_HASH =
        0xf52c5189a89e7ca2ef4f19f2798e3900fba7a316de7cef6c5a9446621ba86286;
    // Init code hash of the JulSwap pair contract.
    uint256 private constant JULSWAP_PAIR_INIT_CODE_HASH =
        0xb1e98e21a5335633815a8cfb3b580071c2e4561c50afd57a8746def9ed890b18;

    // Mask of the lower 20 bytes of a bytes32.
    uint256 private constant ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    // BNB pseudo-token address.
    uint256 private constant ETH_TOKEN_ADDRESS_32 = 0x000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;
    // Maximum token quantity that can be swapped against the PancakeSwapPair contract.
    uint256 private constant MAX_SWAP_AMOUNT = 2 ** 112;

    // bytes4(keccak256("executeCall(address,bytes)"))
    uint256 private constant ALLOWANCE_TARGET_EXECUTE_CALL_SELECTOR_32 =
        0xbca8c7b500000000000000000000000000000000000000000000000000000000;
    // bytes4(keccak256("getReserves()"))
    uint256 private constant PANCAKESWAP_PAIR_RESERVES_CALL_SELECTOR_32 =
        0x0902f1ac00000000000000000000000000000000000000000000000000000000;
    // bytes4(keccak256("swap(uint256,uint256,address,bytes)"))
    uint256 private constant PANCAKESWAP_PAIR_SWAP_CALL_SELECTOR_32 =
        0x022c0d9f00000000000000000000000000000000000000000000000000000000;
    // bytes4(keccak256("swap(uint256,uint256,address)"))
    uint256 private constant BAKERYSWAP_PAIR_SWAP_CALL_SELECTOR_32 =
        0x6d9a640a00000000000000000000000000000000000000000000000000000000;
    // bytes4(keccak256("transferFrom(address,address,uint256)"))
    uint256 private constant TRANSFER_FROM_CALL_SELECTOR_32 =
        0x23b872dd00000000000000000000000000000000000000000000000000000000;
    // bytes4(keccak256("allowance(address,address)"))
    uint256 private constant ALLOWANCE_CALL_SELECTOR_32 =
        0xdd62ed3e00000000000000000000000000000000000000000000000000000000;
    // bytes4(keccak256("withdraw(uint256)"))
    uint256 private constant WETH_WITHDRAW_CALL_SELECTOR_32 =
        0x2e1a7d4d00000000000000000000000000000000000000000000000000000000;
    // bytes4(keccak256("deposit()"))
    uint256 private constant WETH_DEPOSIT_CALL_SELECTOR_32 =
        0xd0e30db000000000000000000000000000000000000000000000000000000000;
    // bytes4(keccak256("transfer(address,uint256)"))
    uint256 private constant ERC20_TRANSFER_CALL_SELECTOR_32 =
        0xa9059cbb00000000000000000000000000000000000000000000000000000000;

    /// @dev Construct this contract.
    /// @param wbnb The WBNB contract.
    constructor(IEtherTokenV06 wbnb) public {
        WBNB = wbnb;
    }

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external returns (bytes4 success) {
        _registerFeatureFunction(this.sellToPancakeSwap.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @dev Efficiently sell directly to pancake/BakerySwap/SushiSwap.
    /// @param tokens Sell path.
    /// @param sellAmount of `tokens[0]` Amount to sell.
    /// @param minBuyAmount Minimum amount of `tokens[-1]` to buy.
    /// @param fork The protocol fork to use.
    /// @return buyAmount Amount of `tokens[-1]` bought.
    function sellToPancakeSwap(
        IERC20TokenV06[] calldata tokens,
        uint256 sellAmount,
        uint256 minBuyAmount,
        ProtocolFork fork
    ) external payable override returns (uint256 buyAmount) {
        require(tokens.length > 1, "PancakeSwapFeature/InvalidTokensLength");
        {
            // Load immutables onto the stack.
            IEtherTokenV06 wbnb = WBNB;

            // Store some vars in memory to get around stack limits.
            assembly {
                // calldataload(mload(0xA00)) == first element of `tokens` array
                mstore(0xA00, add(calldataload(0x04), 0x24))
                // mload(0xA20) == fork
                mstore(0xA20, fork)
                // mload(0xA40) == WBNB
                mstore(0xA40, wbnb)
            }
        }

        assembly {
            // numPairs == tokens.length - 1
            let numPairs := sub(calldataload(add(calldataload(0x04), 0x4)), 1)
            // We use the previous buy amount as the sell amount for the next
            // pair in a path. So for the first swap we want to set it to `sellAmount`.
            buyAmount := sellAmount
            let buyToken
            let nextPair := 0

            for {
                let i := 0
            } lt(i, numPairs) {
                i := add(i, 1)
            } {
                // sellToken = tokens[i]
                let sellToken := loadTokenAddress(i)
                // buyToken = tokens[i+1]
                buyToken := loadTokenAddress(add(i, 1))
                // The canonical ordering of this token pair.
                let pairOrder := lt(normalizeToken(sellToken), normalizeToken(buyToken))

                // Compute the pair address if it hasn't already been computed
                // from the last iteration.
                let pair := nextPair
                if iszero(pair) {
                    pair := computePairAddress(sellToken, buyToken)
                    nextPair := 0
                }

                if iszero(i) {
                    // This is the first token in the path.
                    switch eq(sellToken, ETH_TOKEN_ADDRESS_32)
                    case 0 {
                        // Not selling BNB. Selling an ERC20 instead.
                        // Make sure BNB was not attached to the call.
                        if gt(callvalue(), 0) {
                            revert(0, 0)
                        }
                        // For the first pair we need to transfer sellTokens into the
                        // pair contract.
                        moveTakerTokensTo(sellToken, pair, sellAmount)
                    }
                    default {
                        // If selling BNB, we need to wrap it to WBNB and transfer to the
                        // pair contract.
                        if iszero(eq(callvalue(), sellAmount)) {
                            revert(0, 0)
                        }
                        sellToken := mload(0xA40) // Re-assign to WBNB
                        // Call `WBNB.deposit{value: sellAmount}()`
                        mstore(0xB00, WETH_DEPOSIT_CALL_SELECTOR_32)
                        if iszero(call(gas(), sellToken, sellAmount, 0xB00, 0x4, 0x00, 0x0)) {
                            bubbleRevert()
                        }
                        // Call `WBNB.transfer(pair, sellAmount)`
                        mstore(0xB00, ERC20_TRANSFER_CALL_SELECTOR_32)
                        mstore(0xB04, pair)
                        mstore(0xB24, sellAmount)
                        if iszero(call(gas(), sellToken, 0, 0xB00, 0x44, 0x00, 0x0)) {
                            bubbleRevert()
                        }
                    }
                    // No need to check results, if deposit/transfers failed the PancakeSwapPair will
                    // reject our trade (or it may succeed if somehow the reserve was out of sync)
                    // this is fine for the taker.
                }

                // Call pair.getReserves(), store the results at `0xC00`
                mstore(0xB00, PANCAKESWAP_PAIR_RESERVES_CALL_SELECTOR_32)
                if iszero(staticcall(gas(), pair, 0xB00, 0x4, 0xC00, 0x40)) {
                    bubbleRevert()
                }
                // Revert if the pair contract does not return at least two words.
                if lt(returndatasize(), 0x40) {
                    mstore(0, pair)
                    revert(0, 32)
                }

                // Sell amount for this hop is the previous buy amount.
                let pairSellAmount := buyAmount
                // Compute the buy amount based on the pair reserves.
                {
                    let sellReserve
                    let buyReserve
                    switch iszero(pairOrder)
                    case 0 {
                        // Transpose if pair order is different.
                        sellReserve := mload(0xC00)
                        buyReserve := mload(0xC20)
                    }
                    default {
                        sellReserve := mload(0xC20)
                        buyReserve := mload(0xC00)
                    }
                    // Ensure that the sellAmount is < 2¹¹².
                    if gt(pairSellAmount, MAX_SWAP_AMOUNT) {
                        revert(0, 0)
                    }
                    // Pairs are in the range (0, 2¹¹²) so this shouldn't overflow.
                    // buyAmount = (pairSellAmount * 997 * buyReserve) /
                    //     (pairSellAmount * 997 + sellReserve * 1000);
                    let sellAmountWithFee := mul(pairSellAmount, 997)
                    buyAmount := div(mul(sellAmountWithFee, buyReserve), add(sellAmountWithFee, mul(sellReserve, 1000)))
                }

                let receiver
                // Is this the last pair contract?
                switch eq(add(i, 1), numPairs)
                case 0 {
                    // Not the last pair contract, so forward bought tokens to
                    // the next pair contract.
                    nextPair := computePairAddress(buyToken, loadTokenAddress(add(i, 2)))
                    receiver := nextPair
                }
                default {
                    // The last pair contract.
                    // Forward directly to taker UNLESS they want BNB back.
                    switch eq(buyToken, ETH_TOKEN_ADDRESS_32)
                    case 0 {
                        receiver := caller()
                    }
                    default {
                        receiver := address()
                    }
                }

                // Call pair.swap()
                switch mload(0xA20) // fork
                case 2 {
                    mstore(0xB00, BAKERYSWAP_PAIR_SWAP_CALL_SELECTOR_32)
                }
                default {
                    mstore(0xB00, PANCAKESWAP_PAIR_SWAP_CALL_SELECTOR_32)
                }
                switch pairOrder
                case 0 {
                    mstore(0xB04, buyAmount)
                    mstore(0xB24, 0)
                }
                default {
                    mstore(0xB04, 0)
                    mstore(0xB24, buyAmount)
                }
                mstore(0xB44, receiver)
                mstore(0xB64, 0x80)
                mstore(0xB84, 0)
                if iszero(call(gas(), pair, 0, 0xB00, 0xA4, 0, 0)) {
                    bubbleRevert()
                }
            } // End for-loop.

            // If buying BNB, unwrap the WBNB first
            if eq(buyToken, ETH_TOKEN_ADDRESS_32) {
                // Call `WBNB.withdraw(buyAmount)`
                mstore(0xB00, WETH_WITHDRAW_CALL_SELECTOR_32)
                mstore(0xB04, buyAmount)
                if iszero(call(gas(), mload(0xA40), 0, 0xB00, 0x24, 0x00, 0x0)) {
                    bubbleRevert()
                }
                // Transfer BNB to the caller.
                if iszero(call(gas(), caller(), buyAmount, 0xB00, 0x0, 0x00, 0x0)) {
                    bubbleRevert()
                }
            }

            // Functions ///////////////////////////////////////////////////////

            // Load a token address from the `tokens` calldata argument.
            function loadTokenAddress(idx) -> addr {
                addr := and(ADDRESS_MASK, calldataload(add(mload(0xA00), mul(idx, 0x20))))
            }

            // Convert BNB pseudo-token addresses to WBNB.
            function normalizeToken(token) -> normalized {
                normalized := token
                // Translate BNB pseudo-tokens to WBNB.
                if eq(token, ETH_TOKEN_ADDRESS_32) {
                    normalized := mload(0xA40)
                }
            }

            // Compute the address of the PancakeSwapPair contract given two
            // tokens.
            function computePairAddress(tokenA, tokenB) -> pair {
                // Convert BNB pseudo-token addresses to WBNB.
                tokenA := normalizeToken(tokenA)
                tokenB := normalizeToken(tokenB)
                // There is one contract for every combination of tokens,
                // which is deployed using CREATE2.
                // The derivation of this address is given by:
                //   address(keccak256(abi.encodePacked(
                //       bytes(0xFF),
                //       address(PANCAKESWAP_FACTORY_ADDRESS),
                //       keccak256(abi.encodePacked(
                //           tokenA < tokenB ? tokenA : tokenB,
                //           tokenA < tokenB ? tokenB : tokenA,
                //       )),
                //       bytes32(PANCAKESWAP_PAIR_INIT_CODE_HASH),
                //   )));

                // Compute the salt (the hash of the sorted tokens).
                // Tokens are written in reverse memory order to packed encode
                // them as two 20-byte values in a 40-byte chunk of memory
                // starting at 0xB0C.
                switch lt(tokenA, tokenB)
                case 0 {
                    mstore(0xB14, tokenA)
                    mstore(0xB00, tokenB)
                }
                default {
                    mstore(0xB14, tokenB)
                    mstore(0xB00, tokenA)
                }
                let salt := keccak256(0xB0C, 0x28)
                // Compute the pair address by hashing all the components together.
                switch mload(0xA20) // fork
                case 0 {
                    mstore(0xB00, FF_PANCAKESWAP_FACTORY)
                    mstore(0xB15, salt)
                    mstore(0xB35, PANCAKESWAP_PAIR_INIT_CODE_HASH)
                }
                case 1 {
                    mstore(0xB00, FF_PANCAKESWAPV2_FACTORY)
                    mstore(0xB15, salt)
                    mstore(0xB35, PANCAKESWAPV2_PAIR_INIT_CODE_HASH)
                }
                case 2 {
                    mstore(0xB00, FF_BAKERYSWAP_FACTORY)
                    mstore(0xB15, salt)
                    mstore(0xB35, BAKERYSWAP_PAIR_INIT_CODE_HASH)
                }
                case 3 {
                    mstore(0xB00, FF_SUSHISWAP_FACTORY)
                    mstore(0xB15, salt)
                    mstore(0xB35, SUSHISWAP_PAIR_INIT_CODE_HASH)
                }
                case 4 {
                    mstore(0xB00, FF_APESWAP_FACTORY)
                    mstore(0xB15, salt)
                    mstore(0xB35, APESWAP_PAIR_INIT_CODE_HASH)
                }
                case 5 {
                    mstore(0xB00, FF_CAFESWAP_FACTORY)
                    mstore(0xB15, salt)
                    mstore(0xB35, CAFESWAP_PAIR_INIT_CODE_HASH)
                }
                case 6 {
                    mstore(0xB00, FF_CHEESESWAP_FACTORY)
                    mstore(0xB15, salt)
                    mstore(0xB35, CHEESESWAP_PAIR_INIT_CODE_HASH)
                }
                default {
                    mstore(0xB00, FF_JULSWAP_FACTORY)
                    mstore(0xB15, salt)
                    mstore(0xB35, JULSWAP_PAIR_INIT_CODE_HASH)
                }
                pair := and(ADDRESS_MASK, keccak256(0xB00, 0x55))
            }

            // Revert with the return data from the most recent call.
            function bubbleRevert() {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }

            // Move `amount` tokens from the taker/caller to `to`.
            function moveTakerTokensTo(token, to, amount) {
                // Perform a `transferFrom()`
                mstore(0xB00, TRANSFER_FROM_CALL_SELECTOR_32)
                mstore(0xB04, caller())
                mstore(0xB24, to)
                mstore(0xB44, amount)

                let success := call(
                    gas(),
                    token,
                    0,
                    0xB00,
                    0x64,
                    0xC00,
                    // Copy only the first 32 bytes of return data. We
                    // only care about reading a boolean in the success
                    // case. We will use returndatacopy() in the failure case.
                    0x20
                )

                let rdsize := returndatasize()

                // Check for ERC20 success. ERC20 tokens should
                // return a boolean, but some return nothing or
                // extra data. We accept 0-length return data as
                // success, or at least 32 bytes that starts with
                // a 32-byte boolean true.
                success := and(
                    success, // call itself succeeded
                    or(
                        iszero(rdsize), // no return data, or
                        and(
                            iszero(lt(rdsize, 32)), // at least 32 bytes
                            eq(mload(0xC00), 1) // starts with uint256(1)
                        )
                    )
                )

                if iszero(success) {
                    // Revert with the data returned from the transferFrom call.
                    returndatacopy(0, 0, rdsize)
                    revert(0, rdsize)
                }
            }
        }

        // Revert if we bought too little.
        require(buyAmount >= minBuyAmount, "PancakeSwapFeature/UnderBought");
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "../fixins/FixinCommon.sol";
import "../storage/LibProxyStorage.sol";
import "../storage/LibSimpleFunctionRegistryStorage.sol";
import "../errors/LibSimpleFunctionRegistryRichErrors.sol";
import "../migrations/LibBootstrap.sol";
import "./interfaces/IFeature.sol";
import "./interfaces/ISimpleFunctionRegistryFeature.sol";

/// @dev Basic registry management features.
contract SimpleFunctionRegistryFeature is IFeature, ISimpleFunctionRegistryFeature, FixinCommon {
    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "SimpleFunctionRegistry";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 0);

    using LibRichErrorsV06 for bytes;

    /// @dev Initializes this feature, registering its own functions.
    /// @return success Magic bytes if successful.
    function bootstrap() external returns (bytes4 success) {
        // Register the registration functions (inception vibes).
        _extend(this.extend.selector, _implementation);
        _extend(this._extendSelf.selector, _implementation);
        // Register the rollback function.
        _extend(this.rollback.selector, _implementation);
        // Register getters.
        _extend(this.getRollbackLength.selector, _implementation);
        _extend(this.getRollbackEntryAtIndex.selector, _implementation);
        return LibBootstrap.BOOTSTRAP_SUCCESS;
    }

    /// @dev Roll back to a prior implementation of a function.
    ///      Only directly callable by an authority.
    /// @param selector The function selector.
    /// @param targetImpl The address of an older implementation of the function.
    function rollback(bytes4 selector, address targetImpl) external override onlyOwner {
        (
            LibSimpleFunctionRegistryStorage.Storage storage stor,
            LibProxyStorage.Storage storage proxyStor
        ) = _getStorages();

        address currentImpl = proxyStor.impls[selector];
        if (currentImpl == targetImpl) {
            // Do nothing if already at targetImpl.
            return;
        }
        // Walk history backwards until we find the target implementation.
        address[] storage history = stor.implHistory[selector];
        uint256 i = history.length;
        for (; i > 0; --i) {
            address impl = history[i - 1];
            history.pop();
            if (impl == targetImpl) {
                break;
            }
        }
        if (i == 0) {
            LibSimpleFunctionRegistryRichErrors.NotInRollbackHistoryError(selector, targetImpl).rrevert();
        }
        proxyStor.impls[selector] = targetImpl;
        emit ProxyFunctionUpdated(selector, currentImpl, targetImpl);
    }

    /// @dev Register or replace a function.
    ///      Only directly callable by an authority.
    /// @param selector The function selector.
    /// @param impl The implementation contract for the function.
    function extend(bytes4 selector, address impl) external override onlyOwner {
        _extend(selector, impl);
    }

    /// @dev Register or replace a function.
    ///      Only callable from within.
    ///      This function is only used during the bootstrap process and
    ///      should be deregistered by the deployer after bootstrapping is
    ///      complete.
    /// @param selector The function selector.
    /// @param impl The implementation contract for the function.
    function _extendSelf(bytes4 selector, address impl) external onlySelf {
        _extend(selector, impl);
    }

    /// @dev Retrieve the length of the rollback history for a function.
    /// @param selector The function selector.
    /// @return rollbackLength The number of items in the rollback history for
    ///         the function.
    function getRollbackLength(bytes4 selector) external view override returns (uint256 rollbackLength) {
        return LibSimpleFunctionRegistryStorage.getStorage().implHistory[selector].length;
    }

    /// @dev Retrieve an entry in the rollback history for a function.
    /// @param selector The function selector.
    /// @param idx The index in the rollback history.
    /// @return impl An implementation address for the function at
    ///         index `idx`.
    function getRollbackEntryAtIndex(bytes4 selector, uint256 idx) external view override returns (address impl) {
        return LibSimpleFunctionRegistryStorage.getStorage().implHistory[selector][idx];
    }

    /// @dev Register or replace a function.
    /// @param selector The function selector.
    /// @param impl The implementation contract for the function.
    function _extend(bytes4 selector, address impl) private {
        (
            LibSimpleFunctionRegistryStorage.Storage storage stor,
            LibProxyStorage.Storage storage proxyStor
        ) = _getStorages();

        address oldImpl = proxyStor.impls[selector];
        address[] storage history = stor.implHistory[selector];
        history.push(oldImpl);
        proxyStor.impls[selector] = impl;
        emit ProxyFunctionUpdated(selector, oldImpl, impl);
    }

    /// @dev Get the storage buckets for this feature and the proxy.
    /// @return stor Storage bucket for this feature.
    /// @return proxyStor age bucket for the proxy.
    function _getStorages()
        private
        pure
        returns (LibSimpleFunctionRegistryStorage.Storage storage stor, LibProxyStorage.Storage storage proxyStor)
    {
        return (LibSimpleFunctionRegistryStorage.getStorage(), LibProxyStorage.getStorage());
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibBytesV06.sol";
import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../errors/LibTransformERC20RichErrors.sol";
import "../fixins/FixinCommon.sol";
import "../fixins/FixinTokenSpender.sol";
import "../migrations/LibMigrate.sol";
import "../external/IFlashWallet.sol";
import "../external/FlashWallet.sol";
import "../storage/LibTransformERC20Storage.sol";
import "../transformers/IERC20Transformer.sol";
import "../transformers/LibERC20Transformer.sol";
import "./interfaces/IFeature.sol";
import "./interfaces/ITransformERC20Feature.sol";

/// @dev Feature to composably transform between ERC20 tokens.
contract TransformERC20Feature is IFeature, ITransformERC20Feature, FixinCommon, FixinTokenSpender {
    using LibSafeMathV06 for uint256;
    using LibRichErrorsV06 for bytes;

    /// @dev Stack vars for `_transformERC20Private()`.
    struct TransformERC20PrivateState {
        IFlashWallet wallet;
        address transformerDeployer;
        uint256 recipientOutputTokenBalanceBefore;
        uint256 recipientOutputTokenBalanceAfter;
    }

    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "TransformERC20";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 4, 0);

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @param transformerDeployer The trusted deployer for transformers.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate(address transformerDeployer) external returns (bytes4 success) {
        _registerFeatureFunction(this.getTransformerDeployer.selector);
        _registerFeatureFunction(this.createTransformWallet.selector);
        _registerFeatureFunction(this.getTransformWallet.selector);
        _registerFeatureFunction(this.setTransformerDeployer.selector);
        _registerFeatureFunction(this.setQuoteSigner.selector);
        _registerFeatureFunction(this.getQuoteSigner.selector);
        _registerFeatureFunction(this.transformERC20.selector);
        _registerFeatureFunction(this._transformERC20.selector);
        if (this.getTransformWallet() == IFlashWallet(address(0))) {
            // Create the transform wallet if it doesn't exist.
            this.createTransformWallet();
        }
        LibTransformERC20Storage.getStorage().transformerDeployer = transformerDeployer;
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @dev Replace the allowed deployer for transformers.
    ///      Only callable by the owner.
    /// @param transformerDeployer The address of the trusted deployer for transformers.
    function setTransformerDeployer(address transformerDeployer) external override onlyOwner {
        LibTransformERC20Storage.getStorage().transformerDeployer = transformerDeployer;
        emit TransformerDeployerUpdated(transformerDeployer);
    }

    /// @dev Replace the optional signer for `transformERC20()` calldata.
    ///      Only callable by the owner.
    /// @param quoteSigner The address of the new calldata signer.
    function setQuoteSigner(address quoteSigner) external override onlyOwner {
        LibTransformERC20Storage.getStorage().quoteSigner = quoteSigner;
        emit QuoteSignerUpdated(quoteSigner);
    }

    /// @dev Return the allowed deployer for transformers.
    /// @return deployer The transform deployer address.
    function getTransformerDeployer() public view override returns (address deployer) {
        return LibTransformERC20Storage.getStorage().transformerDeployer;
    }

    /// @dev Return the optional signer for `transformERC20()` calldata.
    /// @return signer The signer address.
    function getQuoteSigner() public view override returns (address signer) {
        return LibTransformERC20Storage.getStorage().quoteSigner;
    }

    /// @dev Deploy a new wallet instance and replace the current one with it.
    ///      Useful if we somehow break the current wallet instance.
    ///      Only callable by the owner.
    /// @return wallet The new wallet instance.
    function createTransformWallet() public override onlyOwner returns (IFlashWallet wallet) {
        wallet = new FlashWallet();
        LibTransformERC20Storage.getStorage().wallet = wallet;
    }

    /// @dev Executes a series of transformations to convert an ERC20 `inputToken`
    ///      to an ERC20 `outputToken`.
    /// @param inputToken The token being provided by the sender.
    ///        If `0xeee...`, ETH is implied and should be provided with the call.`
    /// @param outputToken The token to be acquired by the sender.
    ///        `0xeee...` implies ETH.
    /// @param inputTokenAmount The amount of `inputToken` to take from the sender.
    ///        If set to `uint256(-1)`, the entire spendable balance of the taker
    ///        will be solt.
    /// @param minOutputTokenAmount The minimum amount of `outputToken` the sender
    ///        must receive for the entire transformation to succeed. If set to zero,
    ///        the minimum output token transfer will not be asserted.
    /// @param transformations The transformations to execute on the token balance(s)
    ///        in sequence.
    /// @return outputTokenAmount The amount of `outputToken` received by the sender.
    function transformERC20(
        IERC20TokenV06 inputToken,
        IERC20TokenV06 outputToken,
        uint256 inputTokenAmount,
        uint256 minOutputTokenAmount,
        Transformation[] memory transformations
    ) public payable override returns (uint256 outputTokenAmount) {
        return
            _transformERC20Private(
                TransformERC20Args({
                    taker: msg.sender,
                    inputToken: inputToken,
                    outputToken: outputToken,
                    inputTokenAmount: inputTokenAmount,
                    minOutputTokenAmount: minOutputTokenAmount,
                    transformations: transformations,
                    useSelfBalance: false,
                    recipient: msg.sender
                })
            );
    }

    /// @dev Internal version of `transformERC20()`. Only callable from within.
    /// @param args A `TransformERC20Args` struct.
    /// @return outputTokenAmount The amount of `outputToken` received by the taker.
    function _transformERC20(
        TransformERC20Args memory args
    ) public payable virtual override onlySelf returns (uint256 outputTokenAmount) {
        return _transformERC20Private(args);
    }

    /// @dev Private version of `transformERC20()`.
    /// @param args A `TransformERC20Args` struct.
    /// @return outputTokenAmount The amount of `outputToken` received by the taker.
    function _transformERC20Private(TransformERC20Args memory args) private returns (uint256 outputTokenAmount) {
        // If the input token amount is -1 and we are not selling ETH,
        // transform the taker's entire spendable balance.
        if (!args.useSelfBalance && args.inputTokenAmount == uint256(-1)) {
            if (LibERC20Transformer.isTokenETH(args.inputToken)) {
                // We can't pull more ETH from the taker, so we just set the
                // input token amount to the value attached to the call.
                args.inputTokenAmount = msg.value;
            } else {
                args.inputTokenAmount = _getSpendableERC20BalanceOf(args.inputToken, args.taker);
            }
        }

        TransformERC20PrivateState memory state;
        state.wallet = getTransformWallet();
        state.transformerDeployer = getTransformerDeployer();

        // Remember the initial output token balance of the recipient.
        state.recipientOutputTokenBalanceBefore = LibERC20Transformer.getTokenBalanceOf(
            args.outputToken,
            args.recipient
        );

        // Pull input tokens from the taker to the wallet and transfer attached ETH.
        _transferInputTokensAndAttachedEth(args, address(state.wallet));

        {
            // Perform transformations.
            for (uint256 i = 0; i < args.transformations.length; ++i) {
                _executeTransformation(
                    state.wallet,
                    args.transformations[i],
                    state.transformerDeployer,
                    args.recipient
                );
            }
            // Transfer output tokens from wallet to recipient
            outputTokenAmount = _executeOutputTokenTransfer(args.outputToken, state.wallet, args.recipient);
        }

        // Compute how much output token has been transferred to the recipient.
        state.recipientOutputTokenBalanceAfter = LibERC20Transformer.getTokenBalanceOf(
            args.outputToken,
            args.recipient
        );
        if (state.recipientOutputTokenBalanceAfter < state.recipientOutputTokenBalanceBefore) {
            LibTransformERC20RichErrors
                .NegativeTransformERC20OutputError(
                    address(args.outputToken),
                    state.recipientOutputTokenBalanceBefore - state.recipientOutputTokenBalanceAfter
                )
                .rrevert();
        }
        outputTokenAmount = LibSafeMathV06.min256(
            outputTokenAmount,
            state.recipientOutputTokenBalanceAfter.safeSub(state.recipientOutputTokenBalanceBefore)
        );
        // Ensure enough output token has been sent to the taker.
        if (outputTokenAmount < args.minOutputTokenAmount) {
            LibTransformERC20RichErrors
                .IncompleteTransformERC20Error(address(args.outputToken), outputTokenAmount, args.minOutputTokenAmount)
                .rrevert();
        }

        // Emit an event.
        emit TransformedERC20(
            args.taker,
            address(args.inputToken),
            address(args.outputToken),
            args.inputTokenAmount,
            outputTokenAmount
        );
    }

    /// @dev Return the current wallet instance that will serve as the execution
    ///      context for transformations.
    /// @return wallet The wallet instance.
    function getTransformWallet() public view override returns (IFlashWallet wallet) {
        return LibTransformERC20Storage.getStorage().wallet;
    }

    /// @dev Transfer input tokens and any attached ETH to `to`
    /// @param args A `TransformERC20Args` struct.
    /// @param to The recipient of tokens and ETH.
    function _transferInputTokensAndAttachedEth(TransformERC20Args memory args, address payable to) private {
        if (LibERC20Transformer.isTokenETH(args.inputToken) && msg.value < args.inputTokenAmount) {
            // Token is ETH, so the caller must attach enough ETH to the call.
            LibTransformERC20RichErrors.InsufficientEthAttachedError(msg.value, args.inputTokenAmount).rrevert();
        }

        // Transfer any attached ETH.
        if (msg.value != 0) {
            to.transfer(msg.value);
        }

        // Transfer input tokens.
        if (!LibERC20Transformer.isTokenETH(args.inputToken)) {
            if (args.useSelfBalance) {
                // Use EP balance input token.
                _transferERC20Tokens(args.inputToken, to, args.inputTokenAmount);
            } else {
                // Pull ERC20 tokens from taker.
                _transferERC20TokensFrom(args.inputToken, args.taker, to, args.inputTokenAmount);
            }
        }
    }

    /// @dev Executs a transformer in the context of `wallet`.
    /// @param wallet The wallet instance.
    /// @param transformation The transformation.
    /// @param transformerDeployer The address of the transformer deployer.
    /// @param recipient The recipient address.
    function _executeTransformation(
        IFlashWallet wallet,
        Transformation memory transformation,
        address transformerDeployer,
        address payable recipient
    ) private {
        // Derive the transformer address from the deployment nonce.
        address payable transformer = LibERC20Transformer.getDeployedAddress(
            transformerDeployer,
            transformation.deploymentNonce
        );
        // Call `transformer.transform()` as the wallet.
        bytes memory resultData = wallet.executeDelegateCall(
            // The call target.
            transformer,
            // Call data.
            abi.encodeWithSelector(
                IERC20Transformer.transform.selector,
                IERC20Transformer.TransformContext({
                    sender: msg.sender,
                    recipient: recipient,
                    data: transformation.data
                })
            )
        );
        // Ensure the transformer returned the magic bytes.
        if (resultData.length != 32 || abi.decode(resultData, (bytes4)) != LibERC20Transformer.TRANSFORMER_SUCCESS) {
            LibTransformERC20RichErrors.TransformerFailedError(transformer, transformation.data, resultData).rrevert();
        }
    }

    function _executeOutputTokenTransfer(
        IERC20TokenV06 outputToken,
        IFlashWallet wallet,
        address payable recipient
    ) private returns (uint256 transferAmount) {
        transferAmount = LibERC20Transformer.getTokenBalanceOf(outputToken, address(wallet));
        if (LibERC20Transformer.isTokenETH(outputToken)) {
            wallet.executeCall(recipient, "", transferAmount);
        } else {
            bytes memory resultData = wallet.executeCall(
                payable(address(outputToken)),
                abi.encodeWithSelector(IERC20TokenV06.transfer.selector, recipient, transferAmount),
                0
            );
            if (resultData.length == 0) {
                // If we get back 0 returndata, this may be a non-standard ERC-20 that
                // does not return a boolean. Check that it at least contains code.
                uint256 size;
                assembly {
                    size := extcodesize(outputToken)
                }
                require(size > 0, "invalid token address, contains no code");
            } else if (resultData.length >= 32) {
                // If we get back at least 32 bytes, we know the target address
                // contains code, and we assume it is a token that returned a boolean
                // success value, which must be true.
                uint256 result = LibBytesV06.readUint256(resultData, 0);
                if (result != 1) {
                    LibRichErrorsV06.rrevert(resultData);
                }
            } else {
                // If 0 < returndatasize < 32, the target is a contract, but not a
                // valid token.
                LibRichErrorsV06.rrevert(resultData);
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IEtherTokenV06.sol";
import "../migrations/LibMigrate.sol";
import "../fixins/FixinCommon.sol";
import "./interfaces/IFeature.sol";
import "./interfaces/IUniswapFeature.sol";

/// @dev VIP uniswap fill functions.
contract UniswapFeature is IFeature, IUniswapFeature, FixinCommon {
    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "UniswapFeature";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 1, 2);
    /// @dev WETH contract.
    IEtherTokenV06 private immutable WETH;

    // 0xFF + address of the UniswapV2Factory contract.
    uint256 private constant FF_UNISWAP_FACTORY = 0xFF5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f0000000000000000000000;
    // 0xFF + address of the (Sushiswap) UniswapV2Factory contract.
    uint256 private constant FF_SUSHISWAP_FACTORY = 0xFFC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac0000000000000000000000;
    // Init code hash of the UniswapV2Pair contract.
    uint256 private constant UNISWAP_PAIR_INIT_CODE_HASH =
        0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f;
    // Init code hash of the (Sushiswap) UniswapV2Pair contract.
    uint256 private constant SUSHISWAP_PAIR_INIT_CODE_HASH =
        0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303;
    // Mask of the lower 20 bytes of a bytes32.
    uint256 private constant ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    // ETH pseudo-token address.
    uint256 private constant ETH_TOKEN_ADDRESS_32 = 0x000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;
    // Maximum token quantity that can be swapped against the UniswapV2Pair contract.
    uint256 private constant MAX_SWAP_AMOUNT = 2 ** 112;

    // bytes4(keccak256("executeCall(address,bytes)"))
    uint256 private constant ALLOWANCE_TARGET_EXECUTE_CALL_SELECTOR_32 =
        0xbca8c7b500000000000000000000000000000000000000000000000000000000;
    // bytes4(keccak256("getReserves()"))
    uint256 private constant UNISWAP_PAIR_RESERVES_CALL_SELECTOR_32 =
        0x0902f1ac00000000000000000000000000000000000000000000000000000000;
    // bytes4(keccak256("swap(uint256,uint256,address,bytes)"))
    uint256 private constant UNISWAP_PAIR_SWAP_CALL_SELECTOR_32 =
        0x022c0d9f00000000000000000000000000000000000000000000000000000000;
    // bytes4(keccak256("transferFrom(address,address,uint256)"))
    uint256 private constant TRANSFER_FROM_CALL_SELECTOR_32 =
        0x23b872dd00000000000000000000000000000000000000000000000000000000;
    // bytes4(keccak256("allowance(address,address)"))
    uint256 private constant ALLOWANCE_CALL_SELECTOR_32 =
        0xdd62ed3e00000000000000000000000000000000000000000000000000000000;
    // bytes4(keccak256("withdraw(uint256)"))
    uint256 private constant WETH_WITHDRAW_CALL_SELECTOR_32 =
        0x2e1a7d4d00000000000000000000000000000000000000000000000000000000;
    // bytes4(keccak256("deposit()"))
    uint256 private constant WETH_DEPOSIT_CALL_SELECTOR_32 =
        0xd0e30db000000000000000000000000000000000000000000000000000000000;
    // bytes4(keccak256("transfer(address,uint256)"))
    uint256 private constant ERC20_TRANSFER_CALL_SELECTOR_32 =
        0xa9059cbb00000000000000000000000000000000000000000000000000000000;

    /// @dev Construct this contract.
    /// @param weth The WETH contract.
    constructor(IEtherTokenV06 weth) public {
        WETH = weth;
    }

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external returns (bytes4 success) {
        _registerFeatureFunction(this.sellToUniswap.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @dev Efficiently sell directly to uniswap/sushiswap.
    /// @param tokens Sell path.
    /// @param sellAmount of `tokens[0]` Amount to sell.
    /// @param minBuyAmount Minimum amount of `tokens[-1]` to buy.
    /// @param isSushi Use sushiswap if true.
    /// @return buyAmount Amount of `tokens[-1]` bought.
    function sellToUniswap(
        IERC20TokenV06[] calldata tokens,
        uint256 sellAmount,
        uint256 minBuyAmount,
        bool isSushi
    ) external payable override returns (uint256 buyAmount) {
        require(tokens.length > 1, "UniswapFeature/InvalidTokensLength");
        {
            // Load immutables onto the stack.
            IEtherTokenV06 weth = WETH;

            // Store some vars in memory to get around stack limits.
            assembly {
                // calldataload(mload(0xA00)) == first element of `tokens` array
                mstore(0xA00, add(calldataload(0x04), 0x24))
                // mload(0xA20) == isSushi
                mstore(0xA20, isSushi)
                // mload(0xA40) == WETH
                mstore(0xA40, weth)
            }
        }

        assembly {
            // numPairs == tokens.length - 1
            let numPairs := sub(calldataload(add(calldataload(0x04), 0x4)), 1)
            // We use the previous buy amount as the sell amount for the next
            // pair in a path. So for the first swap we want to set it to `sellAmount`.
            buyAmount := sellAmount
            let buyToken
            let nextPair := 0

            for {
                let i := 0
            } lt(i, numPairs) {
                i := add(i, 1)
            } {
                // sellToken = tokens[i]
                let sellToken := loadTokenAddress(i)
                // buyToken = tokens[i+1]
                buyToken := loadTokenAddress(add(i, 1))
                // The canonical ordering of this token pair.
                let pairOrder := lt(normalizeToken(sellToken), normalizeToken(buyToken))

                // Compute the pair address if it hasn't already been computed
                // from the last iteration.
                let pair := nextPair
                if iszero(pair) {
                    pair := computePairAddress(sellToken, buyToken)
                    nextPair := 0
                }

                if iszero(i) {
                    // This is the first token in the path.
                    switch eq(sellToken, ETH_TOKEN_ADDRESS_32)
                    case 0 {
                        // Not selling ETH. Selling an ERC20 instead.
                        // Make sure ETH was not attached to the call.
                        if gt(callvalue(), 0) {
                            revert(0, 0)
                        }
                        // For the first pair we need to transfer sellTokens into the
                        // pair contract.
                        moveTakerTokensTo(sellToken, pair, sellAmount)
                    }
                    default {
                        // If selling ETH, we need to wrap it to WETH and transfer to the
                        // pair contract.
                        if iszero(eq(callvalue(), sellAmount)) {
                            revert(0, 0)
                        }
                        sellToken := mload(0xA40) // Re-assign to WETH
                        // Call `WETH.deposit{value: sellAmount}()`
                        mstore(0xB00, WETH_DEPOSIT_CALL_SELECTOR_32)
                        if iszero(call(gas(), sellToken, sellAmount, 0xB00, 0x4, 0x00, 0x0)) {
                            bubbleRevert()
                        }
                        // Call `WETH.transfer(pair, sellAmount)`
                        mstore(0xB00, ERC20_TRANSFER_CALL_SELECTOR_32)
                        mstore(0xB04, pair)
                        mstore(0xB24, sellAmount)
                        if iszero(call(gas(), sellToken, 0, 0xB00, 0x44, 0x00, 0x0)) {
                            bubbleRevert()
                        }
                    }
                    // No need to check results, if deposit/transfers failed the UniswapV2Pair will
                    // reject our trade (or it may succeed if somehow the reserve was out of sync)
                    // this is fine for the taker.
                }

                // Call pair.getReserves(), store the results at `0xC00`
                mstore(0xB00, UNISWAP_PAIR_RESERVES_CALL_SELECTOR_32)
                if iszero(staticcall(gas(), pair, 0xB00, 0x4, 0xC00, 0x40)) {
                    bubbleRevert()
                }
                // Revert if the pair contract does not return at least two words.
                if lt(returndatasize(), 0x40) {
                    revert(0, 0)
                }

                // Sell amount for this hop is the previous buy amount.
                let pairSellAmount := buyAmount
                // Compute the buy amount based on the pair reserves.
                {
                    let sellReserve
                    let buyReserve
                    switch iszero(pairOrder)
                    case 0 {
                        // Transpose if pair order is different.
                        sellReserve := mload(0xC00)
                        buyReserve := mload(0xC20)
                    }
                    default {
                        sellReserve := mload(0xC20)
                        buyReserve := mload(0xC00)
                    }
                    // Ensure that the sellAmount is < 2¹¹².
                    if gt(pairSellAmount, MAX_SWAP_AMOUNT) {
                        revert(0, 0)
                    }
                    // Pairs are in the range (0, 2¹¹²) so this shouldn't overflow.
                    // buyAmount = (pairSellAmount * 997 * buyReserve) /
                    //     (pairSellAmount * 997 + sellReserve * 1000);
                    let sellAmountWithFee := mul(pairSellAmount, 997)
                    buyAmount := div(mul(sellAmountWithFee, buyReserve), add(sellAmountWithFee, mul(sellReserve, 1000)))
                }

                let receiver
                // Is this the last pair contract?
                switch eq(add(i, 1), numPairs)
                case 0 {
                    // Not the last pair contract, so forward bought tokens to
                    // the next pair contract.
                    nextPair := computePairAddress(buyToken, loadTokenAddress(add(i, 2)))
                    receiver := nextPair
                }
                default {
                    // The last pair contract.
                    // Forward directly to taker UNLESS they want ETH back.
                    switch eq(buyToken, ETH_TOKEN_ADDRESS_32)
                    case 0 {
                        receiver := caller()
                    }
                    default {
                        receiver := address()
                    }
                }

                // Call pair.swap()
                mstore(0xB00, UNISWAP_PAIR_SWAP_CALL_SELECTOR_32)
                switch pairOrder
                case 0 {
                    mstore(0xB04, buyAmount)
                    mstore(0xB24, 0)
                }
                default {
                    mstore(0xB04, 0)
                    mstore(0xB24, buyAmount)
                }
                mstore(0xB44, receiver)
                mstore(0xB64, 0x80)
                mstore(0xB84, 0)
                if iszero(call(gas(), pair, 0, 0xB00, 0xA4, 0, 0)) {
                    bubbleRevert()
                }
            } // End for-loop.

            // If buying ETH, unwrap the WETH first
            if eq(buyToken, ETH_TOKEN_ADDRESS_32) {
                // Call `WETH.withdraw(buyAmount)`
                mstore(0xB00, WETH_WITHDRAW_CALL_SELECTOR_32)
                mstore(0xB04, buyAmount)
                if iszero(call(gas(), mload(0xA40), 0, 0xB00, 0x24, 0x00, 0x0)) {
                    bubbleRevert()
                }
                // Transfer ETH to the caller.
                if iszero(call(gas(), caller(), buyAmount, 0xB00, 0x0, 0x00, 0x0)) {
                    bubbleRevert()
                }
            }

            // Functions ///////////////////////////////////////////////////////

            // Load a token address from the `tokens` calldata argument.
            function loadTokenAddress(idx) -> addr {
                addr := and(ADDRESS_MASK, calldataload(add(mload(0xA00), mul(idx, 0x20))))
            }

            // Convert ETH pseudo-token addresses to WETH.
            function normalizeToken(token) -> normalized {
                normalized := token
                // Translate ETH pseudo-tokens to WETH.
                if eq(token, ETH_TOKEN_ADDRESS_32) {
                    normalized := mload(0xA40)
                }
            }

            // Compute the address of the UniswapV2Pair contract given two
            // tokens.
            function computePairAddress(tokenA, tokenB) -> pair {
                // Convert ETH pseudo-token addresses to WETH.
                tokenA := normalizeToken(tokenA)
                tokenB := normalizeToken(tokenB)
                // There is one contract for every combination of tokens,
                // which is deployed using CREATE2.
                // The derivation of this address is given by:
                //   address(keccak256(abi.encodePacked(
                //       bytes(0xFF),
                //       address(UNISWAP_FACTORY_ADDRESS),
                //       keccak256(abi.encodePacked(
                //           tokenA < tokenB ? tokenA : tokenB,
                //           tokenA < tokenB ? tokenB : tokenA,
                //       )),
                //       bytes32(UNISWAP_PAIR_INIT_CODE_HASH),
                //   )));

                // Compute the salt (the hash of the sorted tokens).
                // Tokens are written in reverse memory order to packed encode
                // them as two 20-byte values in a 40-byte chunk of memory
                // starting at 0xB0C.
                switch lt(tokenA, tokenB)
                case 0 {
                    mstore(0xB14, tokenA)
                    mstore(0xB00, tokenB)
                }
                default {
                    mstore(0xB14, tokenB)
                    mstore(0xB00, tokenA)
                }
                let salt := keccak256(0xB0C, 0x28)
                // Compute the pair address by hashing all the components together.
                switch mload(0xA20) // isSushi
                case 0 {
                    mstore(0xB00, FF_UNISWAP_FACTORY)
                    mstore(0xB15, salt)
                    mstore(0xB35, UNISWAP_PAIR_INIT_CODE_HASH)
                }
                default {
                    mstore(0xB00, FF_SUSHISWAP_FACTORY)
                    mstore(0xB15, salt)
                    mstore(0xB35, SUSHISWAP_PAIR_INIT_CODE_HASH)
                }
                pair := and(ADDRESS_MASK, keccak256(0xB00, 0x55))
            }

            // Revert with the return data from the most recent call.
            function bubbleRevert() {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }

            // Move `amount` tokens from the taker/caller to `to`.
            function moveTakerTokensTo(token, to, amount) {
                // Perform a `transferFrom()`
                mstore(0xB00, TRANSFER_FROM_CALL_SELECTOR_32)
                mstore(0xB04, caller())
                mstore(0xB24, to)
                mstore(0xB44, amount)

                let success := call(
                    gas(),
                    token,
                    0,
                    0xB00,
                    0x64,
                    0xC00,
                    // Copy only the first 32 bytes of return data. We
                    // only care about reading a boolean in the success
                    // case. We will use returndatacopy() in the failure case.
                    0x20
                )

                let rdsize := returndatasize()

                // Check for ERC20 success. ERC20 tokens should
                // return a boolean, but some return nothing or
                // extra data. We accept 0-length return data as
                // success, or at least 32 bytes that starts with
                // a 32-byte boolean true.
                success := and(
                    success, // call itself succeeded
                    or(
                        iszero(rdsize), // no return data, or
                        and(
                            iszero(lt(rdsize, 32)), // at least 32 bytes
                            eq(mload(0xC00), 1) // starts with uint256(1)
                        )
                    )
                )

                if iszero(success) {
                    // Revert with the data returned from the transferFrom call.
                    returndatacopy(0, 0, rdsize)
                    revert(0, rdsize)
                }
            }
        }

        // Revert if we bought too little.
        // TODO: replace with rich revert?
        require(buyAmount >= minBuyAmount, "UniswapFeature/UnderBought");
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IEtherTokenV06.sol";
import "../vendor/IUniswapV3Pool.sol";
import "../migrations/LibMigrate.sol";
import "../fixins/FixinCommon.sol";
import "../fixins/FixinTokenSpender.sol";
import "./interfaces/IFeature.sol";
import "./interfaces/IUniswapV3Feature.sol";

/// @dev VIP uniswap fill functions.
contract UniswapV3Feature is IFeature, IUniswapV3Feature, FixinCommon, FixinTokenSpender {
    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "UniswapV3Feature";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 1, 0);
    /// @dev WETH contract.
    IEtherTokenV06 private immutable WETH;
    /// @dev UniswapV3 Factory contract address prepended with '0xff' and left-aligned.
    bytes32 private immutable UNI_FF_FACTORY_ADDRESS;
    /// @dev UniswapV3 pool init code hash.
    bytes32 private immutable UNI_POOL_INIT_CODE_HASH;
    /// @dev Minimum size of an encoded swap path:
    ///      sizeof(address(inputToken) | uint24(fee) | address(outputToken))
    uint256 private constant SINGLE_HOP_PATH_SIZE = 20 + 3 + 20;
    /// @dev How many bytes to skip ahead in an encoded path to start at the next hop:
    ///      sizeof(address(inputToken) | uint24(fee))
    uint256 private constant PATH_SKIP_HOP_SIZE = 20 + 3;
    /// @dev The size of the swap callback data.
    uint256 private constant SWAP_CALLBACK_DATA_SIZE = 128;
    /// @dev Minimum tick price sqrt ratio.
    uint160 internal constant MIN_PRICE_SQRT_RATIO = 4295128739;
    /// @dev Minimum tick price sqrt ratio.
    uint160 internal constant MAX_PRICE_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
    /// @dev Mask of lower 20 bytes.
    uint256 private constant ADDRESS_MASK = 0x00ffffffffffffffffffffffffffffffffffffffff;
    /// @dev Mask of lower 3 bytes.
    uint256 private constant UINT24_MASK = 0xffffff;

    /// @dev Construct this contract.
    /// @param weth The WETH contract.
    /// @param uniFactory The UniswapV3 factory contract.
    /// @param poolInitCodeHash The UniswapV3 pool init code hash.
    constructor(IEtherTokenV06 weth, address uniFactory, bytes32 poolInitCodeHash) public {
        WETH = weth;
        UNI_FF_FACTORY_ADDRESS = bytes32((uint256(0xff) << 248) | (uint256(uniFactory) << 88));
        UNI_POOL_INIT_CODE_HASH = poolInitCodeHash;
    }

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external returns (bytes4 success) {
        _registerFeatureFunction(this.sellEthForTokenToUniswapV3.selector);
        _registerFeatureFunction(this.sellTokenForEthToUniswapV3.selector);
        _registerFeatureFunction(this.sellTokenForTokenToUniswapV3.selector);
        _registerFeatureFunction(this._sellHeldTokenForTokenToUniswapV3.selector);
        _registerFeatureFunction(this.uniswapV3SwapCallback.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @dev Sell attached ETH directly against uniswap v3.
    /// @param encodedPath Uniswap-encoded path, where the first token is WETH.
    /// @param recipient The recipient of the bought tokens. Can be zero for sender.
    /// @param minBuyAmount Minimum amount of the last token in the path to buy.
    /// @return buyAmount Amount of the last token in the path bought.
    function sellEthForTokenToUniswapV3(
        bytes memory encodedPath,
        uint256 minBuyAmount,
        address recipient
    ) public payable override returns (uint256 buyAmount) {
        // Wrap ETH.
        WETH.deposit{value: msg.value}();
        return
            _swap(
                encodedPath,
                msg.value,
                minBuyAmount,
                address(this), // we are payer because we hold the WETH
                _normalizeRecipient(recipient)
            );
    }

    /// @dev Sell a token for ETH directly against uniswap v3.
    /// @param encodedPath Uniswap-encoded path, where the last token is WETH.
    /// @param sellAmount amount of the first token in the path to sell.
    /// @param minBuyAmount Minimum amount of ETH to buy.
    /// @param recipient The recipient of the bought tokens. Can be zero for sender.
    /// @return buyAmount Amount of ETH bought.
    function sellTokenForEthToUniswapV3(
        bytes memory encodedPath,
        uint256 sellAmount,
        uint256 minBuyAmount,
        address payable recipient
    ) public override returns (uint256 buyAmount) {
        buyAmount = _swap(
            encodedPath,
            sellAmount,
            minBuyAmount,
            msg.sender,
            address(this) // we are recipient because we need to unwrap WETH
        );
        WETH.withdraw(buyAmount);
        // Transfer ETH to recipient.
        (bool success, bytes memory revertData) = _normalizeRecipient(recipient).call{value: buyAmount}("");
        if (!success) {
            revertData.rrevert();
        }
    }

    /// @dev Sell a token for another token directly against uniswap v3.
    /// @param encodedPath Uniswap-encoded path.
    /// @param sellAmount amount of the first token in the path to sell.
    /// @param minBuyAmount Minimum amount of the last token in the path to buy.
    /// @param recipient The recipient of the bought tokens. Can be zero for sender.
    /// @return buyAmount Amount of the last token in the path bought.
    function sellTokenForTokenToUniswapV3(
        bytes memory encodedPath,
        uint256 sellAmount,
        uint256 minBuyAmount,
        address recipient
    ) public override returns (uint256 buyAmount) {
        buyAmount = _swap(encodedPath, sellAmount, minBuyAmount, msg.sender, _normalizeRecipient(recipient));
    }

    /// @dev Sell a token for another token directly against uniswap v3.
    ///      Private variant, uses tokens held by `address(this)`.
    /// @param encodedPath Uniswap-encoded path.
    /// @param sellAmount amount of the first token in the path to sell.
    /// @param minBuyAmount Minimum amount of the last token in the path to buy.
    /// @param recipient The recipient of the bought tokens. Can be zero for sender.
    /// @return buyAmount Amount of the last token in the path bought.
    function _sellHeldTokenForTokenToUniswapV3(
        bytes memory encodedPath,
        uint256 sellAmount,
        uint256 minBuyAmount,
        address recipient
    ) public override onlySelf returns (uint256 buyAmount) {
        buyAmount = _swap(encodedPath, sellAmount, minBuyAmount, address(this), _normalizeRecipient(recipient));
    }

    /// @dev The UniswapV3 pool swap callback which pays the funds requested
    ///      by the caller/pool to the pool. Can only be called by a valid
    ///      UniswapV3 pool.
    /// @param amount0Delta Token0 amount owed.
    /// @param amount1Delta Token1 amount owed.
    /// @param data Arbitrary data forwarded from swap() caller. An ABI-encoded
    ///        struct of: inputToken, outputToken, fee, payer
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external override {
        IERC20TokenV06 token0;
        IERC20TokenV06 token1;
        address payer;
        {
            uint24 fee;
            // Decode the data.
            require(data.length == SWAP_CALLBACK_DATA_SIZE, "UniswapFeature/INVALID_SWAP_CALLBACK_DATA");
            assembly {
                let p := add(36, calldataload(68))
                token0 := calldataload(p)
                token1 := calldataload(add(p, 32))
                fee := calldataload(add(p, 64))
                payer := calldataload(add(p, 96))
            }
            (token0, token1) = token0 < token1 ? (token0, token1) : (token1, token0);
            // Only a valid pool contract can call this function.
            require(
                msg.sender == address(_toPool(token0, fee, token1)),
                "UniswapV3Feature/INVALID_SWAP_CALLBACK_CALLER"
            );
        }
        // Pay the amount owed to the pool.
        if (amount0Delta > 0) {
            _pay(token0, payer, msg.sender, uint256(amount0Delta));
        } else if (amount1Delta > 0) {
            _pay(token1, payer, msg.sender, uint256(amount1Delta));
        } else {
            revert("UniswapV3Feature/INVALID_SWAP_AMOUNTS");
        }
    }

    // Executes successive swaps along an encoded uniswap path.
    function _swap(
        bytes memory encodedPath,
        uint256 sellAmount,
        uint256 minBuyAmount,
        address payer,
        address recipient
    ) private returns (uint256 buyAmount) {
        if (sellAmount != 0) {
            require(sellAmount <= uint256(type(int256).max), "UniswapV3Feature/SELL_AMOUNT_OVERFLOW");

            // Perform a swap for each hop in the path.
            bytes memory swapCallbackData = new bytes(SWAP_CALLBACK_DATA_SIZE);
            while (true) {
                bool isPathMultiHop = _isPathMultiHop(encodedPath);
                bool zeroForOne;
                IUniswapV3Pool pool;
                {
                    (IERC20TokenV06 inputToken, uint24 fee, IERC20TokenV06 outputToken) = _decodeFirstPoolInfoFromPath(
                        encodedPath
                    );
                    pool = _toPool(inputToken, fee, outputToken);
                    zeroForOne = inputToken < outputToken;
                    _updateSwapCallbackData(swapCallbackData, inputToken, outputToken, fee, payer);
                }
                (int256 amount0, int256 amount1) = pool.swap(
                    // Intermediate tokens go to this contract.
                    isPathMultiHop ? address(this) : recipient,
                    zeroForOne,
                    int256(sellAmount),
                    zeroForOne ? MIN_PRICE_SQRT_RATIO + 1 : MAX_PRICE_SQRT_RATIO - 1,
                    swapCallbackData
                );
                {
                    int256 _buyAmount = -(zeroForOne ? amount1 : amount0);
                    require(_buyAmount >= 0, "UniswapV3Feature/INVALID_BUY_AMOUNT");
                    buyAmount = uint256(_buyAmount);
                }
                if (!isPathMultiHop) {
                    // Done.
                    break;
                }
                // Continue with next hop.
                payer = address(this); // Subsequent hops are paid for by us.
                sellAmount = buyAmount;
                // Skip to next hop along path.
                encodedPath = _shiftHopFromPathInPlace(encodedPath);
            }
        }
        require(minBuyAmount <= buyAmount, "UniswapV3Feature/UNDERBOUGHT");
    }

    // Pay tokens from `payer` to `to`, using `transferFrom()` if
    // `payer` != this contract.
    function _pay(IERC20TokenV06 token, address payer, address to, uint256 amount) private {
        if (payer != address(this)) {
            _transferERC20TokensFrom(token, payer, to, amount);
        } else {
            _transferERC20Tokens(token, to, amount);
        }
    }

    // Update `swapCallbackData` in place with new values.
    function _updateSwapCallbackData(
        bytes memory swapCallbackData,
        IERC20TokenV06 inputToken,
        IERC20TokenV06 outputToken,
        uint24 fee,
        address payer
    ) private pure {
        assembly {
            let p := add(swapCallbackData, 32)
            mstore(p, inputToken)
            mstore(add(p, 32), outputToken)
            mstore(add(p, 64), and(UINT24_MASK, fee))
            mstore(add(p, 96), and(ADDRESS_MASK, payer))
        }
    }

    // Compute the pool address given two tokens and a fee.
    function _toPool(
        IERC20TokenV06 inputToken,
        uint24 fee,
        IERC20TokenV06 outputToken
    ) private view returns (IUniswapV3Pool pool) {
        // address(keccak256(abi.encodePacked(
        //     hex"ff",
        //     UNI_FACTORY_ADDRESS,
        //     keccak256(abi.encode(inputToken, outputToken, fee)),
        //     UNI_POOL_INIT_CODE_HASH
        // )))
        bytes32 ffFactoryAddress = UNI_FF_FACTORY_ADDRESS;
        bytes32 poolInitCodeHash = UNI_POOL_INIT_CODE_HASH;
        (IERC20TokenV06 token0, IERC20TokenV06 token1) = inputToken < outputToken
            ? (inputToken, outputToken)
            : (outputToken, inputToken);
        assembly {
            let s := mload(0x40)
            let p := s
            mstore(p, ffFactoryAddress)
            p := add(p, 21)
            // Compute the inner hash in-place
            mstore(p, token0)
            mstore(add(p, 32), token1)
            mstore(add(p, 64), and(UINT24_MASK, fee))
            mstore(p, keccak256(p, 96))
            p := add(p, 32)
            mstore(p, poolInitCodeHash)
            pool := and(ADDRESS_MASK, keccak256(s, 85))
        }
    }

    // Return whether or not an encoded uniswap path contains more than one hop.
    function _isPathMultiHop(bytes memory encodedPath) private pure returns (bool isMultiHop) {
        return encodedPath.length > SINGLE_HOP_PATH_SIZE;
    }

    // Return the first input token, output token, and fee of an encoded uniswap path.
    function _decodeFirstPoolInfoFromPath(
        bytes memory encodedPath
    ) private pure returns (IERC20TokenV06 inputToken, uint24 fee, IERC20TokenV06 outputToken) {
        require(encodedPath.length >= SINGLE_HOP_PATH_SIZE, "UniswapV3Feature/BAD_PATH_ENCODING");
        assembly {
            let p := add(encodedPath, 32)
            inputToken := shr(96, mload(p))
            p := add(p, 20)
            fee := shr(232, mload(p))
            p := add(p, 3)
            outputToken := shr(96, mload(p))
        }
    }

    // Skip past the first hop of an encoded uniswap path in-place.
    function _shiftHopFromPathInPlace(bytes memory encodedPath) private pure returns (bytes memory shiftedEncodedPath) {
        require(encodedPath.length >= PATH_SKIP_HOP_SIZE, "UniswapV3Feature/BAD_PATH_ENCODING");
        uint256 shiftSize = PATH_SKIP_HOP_SIZE;
        uint256 newSize = encodedPath.length - shiftSize;
        assembly {
            shiftedEncodedPath := add(encodedPath, shiftSize)
            mstore(shiftedEncodedPath, newSize)
        }
    }

    // Convert null address values to msg.sender.
    function _normalizeRecipient(address recipient) private view returns (address payable normalizedRecipient) {
        return recipient == address(0) ? msg.sender : payable(recipient);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "../errors/LibCommonRichErrors.sol";
import "../errors/LibOwnableRichErrors.sol";
import "../features/interfaces/IOwnableFeature.sol";
import "../features/interfaces/ISimpleFunctionRegistryFeature.sol";

/// @dev Common feature utilities.
abstract contract FixinCommon {
    using LibRichErrorsV06 for bytes;

    /// @dev The implementation address of this feature.
    address internal immutable _implementation;

    /// @dev The caller must be this contract.
    modifier onlySelf() virtual {
        if (msg.sender != address(this)) {
            LibCommonRichErrors.OnlyCallableBySelfError(msg.sender).rrevert();
        }
        _;
    }

    /// @dev The caller of this function must be the owner.
    modifier onlyOwner() virtual {
        {
            address owner = IOwnableFeature(address(this)).owner();
            if (msg.sender != owner) {
                LibOwnableRichErrors.OnlyOwnerError(msg.sender, owner).rrevert();
            }
        }
        _;
    }

    constructor() internal {
        // Remember this feature's original address.
        _implementation = address(this);
    }

    /// @dev Registers a function implemented by this feature at `_implementation`.
    ///      Can and should only be called within a `migrate()`.
    /// @param selector The selector of the function whose implementation
    ///        is at `_implementation`.
    function _registerFeatureFunction(bytes4 selector) internal {
        ISimpleFunctionRegistryFeature(address(this)).extend(selector, _implementation);
    }

    /// @dev Encode a feature version as a `uint256`.
    /// @param major The major version number of the feature.
    /// @param minor The minor version number of the feature.
    /// @param revision The revision number of the feature.
    /// @return encodedVersion The encoded version number.
    function _encodeVersion(
        uint32 major,
        uint32 minor,
        uint32 revision
    ) internal pure returns (uint256 encodedVersion) {
        return (uint256(major) << 64) | (uint256(minor) << 32) | uint256(revision);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "../errors/LibCommonRichErrors.sol";
import "../errors/LibOwnableRichErrors.sol";

/// @dev EIP712 helpers for features.
abstract contract FixinEIP712 {
    /// @dev The domain hash separator for the entire exchange proxy.
    bytes32 public immutable EIP712_DOMAIN_SEPARATOR;

    constructor(address zeroExAddress) internal {
        // Compute `EIP712_DOMAIN_SEPARATOR`
        {
            uint256 chainId;
            assembly {
                chainId := chainid()
            }
            EIP712_DOMAIN_SEPARATOR = keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain("
                        "string name,"
                        "string version,"
                        "uint256 chainId,"
                        "address verifyingContract"
                        ")"
                    ),
                    keccak256("ZeroEx"),
                    keccak256("1.0.0"),
                    chainId,
                    zeroExAddress
                )
            );
        }
    }

    function _getEIP712Hash(bytes32 structHash) internal view returns (bytes32 eip712Hash) {
        return keccak256(abi.encodePacked(hex"1901", EIP712_DOMAIN_SEPARATOR, structHash));
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../vendor/IERC1155Token.sol";

/// @dev Helpers for moving ERC1155 assets around.
abstract contract FixinERC1155Spender {
    // Mask of the lower 20 bytes of a bytes32.
    uint256 private constant ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;

    /// @dev Transfers an ERC1155 asset from `owner` to `to`.
    /// @param token The address of the ERC1155 token contract.
    /// @param owner The owner of the asset.
    /// @param to The recipient of the asset.
    /// @param tokenId The token ID of the asset to transfer.
    /// @param amount The amount of the asset to transfer.
    function _transferERC1155AssetFrom(
        IERC1155Token token,
        address owner,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal {
        require(address(token) != address(this), "FixinERC1155Spender/CANNOT_INVOKE_SELF");

        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for safeTransferFrom(address,address,uint256,uint256,bytes)
            mstore(ptr, 0xf242432a00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), and(owner, ADDRESS_MASK))
            mstore(add(ptr, 0x24), and(to, ADDRESS_MASK))
            mstore(add(ptr, 0x44), tokenId)
            mstore(add(ptr, 0x64), amount)
            mstore(add(ptr, 0x84), 0xa0)
            mstore(add(ptr, 0xa4), 0)

            let success := call(gas(), and(token, ADDRESS_MASK), 0, ptr, 0xc4, 0, 0)

            if iszero(success) {
                let rdsize := returndatasize()
                returndatacopy(ptr, 0, rdsize)
                revert(ptr, rdsize)
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../vendor/IERC721Token.sol";

/// @dev Helpers for moving ERC721 assets around.
abstract contract FixinERC721Spender {
    // Mask of the lower 20 bytes of a bytes32.
    uint256 private constant ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;

    /// @dev Transfers an ERC721 asset from `owner` to `to`.
    /// @param token The address of the ERC721 token contract.
    /// @param owner The owner of the asset.
    /// @param to The recipient of the asset.
    /// @param tokenId The token ID of the asset to transfer.
    function _transferERC721AssetFrom(IERC721Token token, address owner, address to, uint256 tokenId) internal {
        require(address(token) != address(this), "FixinERC721Spender/CANNOT_INVOKE_SELF");

        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for transferFrom(address,address,uint256)
            mstore(ptr, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), and(owner, ADDRESS_MASK))
            mstore(add(ptr, 0x24), and(to, ADDRESS_MASK))
            mstore(add(ptr, 0x44), tokenId)

            let success := call(gas(), and(token, ADDRESS_MASK), 0, ptr, 0x64, 0, 0)

            if iszero(success) {
                let rdsize := returndatasize()
                returndatacopy(ptr, 0, rdsize)
                revert(ptr, rdsize)
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IEtherTokenV06.sol";
import "../external/FeeCollector.sol";
import "../external/FeeCollectorController.sol";
import "../external/LibFeeCollector.sol";
import "../vendor/v3/IStaking.sol";

/// @dev Helpers for collecting protocol fees.
abstract contract FixinProtocolFees {
    /// @dev The protocol fee multiplier.
    uint32 public immutable PROTOCOL_FEE_MULTIPLIER;
    /// @dev The `FeeCollectorController` contract.
    FeeCollectorController private immutable FEE_COLLECTOR_CONTROLLER;
    /// @dev Hash of the fee collector init code.
    bytes32 private immutable FEE_COLLECTOR_INIT_CODE_HASH;
    /// @dev The WETH token contract.
    IEtherTokenV06 private immutable WETH;
    /// @dev The staking contract.
    IStaking private immutable STAKING;

    constructor(
        IEtherTokenV06 weth,
        IStaking staking,
        FeeCollectorController feeCollectorController,
        uint32 protocolFeeMultiplier
    ) internal {
        FEE_COLLECTOR_CONTROLLER = feeCollectorController;
        FEE_COLLECTOR_INIT_CODE_HASH = feeCollectorController.FEE_COLLECTOR_INIT_CODE_HASH();
        WETH = weth;
        STAKING = staking;
        PROTOCOL_FEE_MULTIPLIER = protocolFeeMultiplier;
    }

    /// @dev   Collect the specified protocol fee in ETH.
    ///        The fee is stored in a per-pool fee collector contract.
    /// @param poolId The pool ID for which a fee is being collected.
    /// @return ethProtocolFeePaid How much protocol fee was collected in ETH.
    function _collectProtocolFee(bytes32 poolId) internal returns (uint256 ethProtocolFeePaid) {
        uint256 protocolFeePaid = _getSingleProtocolFee();
        if (protocolFeePaid == 0) {
            // Nothing to do.
            return 0;
        }
        FeeCollector feeCollector = _getFeeCollector(poolId);
        (bool success, ) = address(feeCollector).call{value: protocolFeePaid}("");
        require(success, "FixinProtocolFees/ETHER_TRANSFER_FALIED");
        return protocolFeePaid;
    }

    /// @dev Transfer fees for a given pool to the staking contract.
    /// @param poolId Identifies the pool whose fees are being paid.
    function _transferFeesForPool(bytes32 poolId) internal {
        // This will create a FeeCollector contract (if necessary) and wrap
        // fees for the pool ID.
        FeeCollector feeCollector = FEE_COLLECTOR_CONTROLLER.prepareFeeCollectorToPayFees(poolId);
        // All fees in the fee collector should be in WETH now.
        uint256 bal = WETH.balanceOf(address(feeCollector));
        if (bal > 1) {
            // Leave 1 wei behind to avoid high SSTORE cost of zero-->non-zero.
            STAKING.payProtocolFee(address(feeCollector), address(feeCollector), bal - 1);
        }
    }

    /// @dev Compute the CREATE2 address for a fee collector.
    /// @param poolId The fee collector's pool ID.
    function _getFeeCollector(bytes32 poolId) internal view returns (FeeCollector) {
        return
            FeeCollector(
                LibFeeCollector.getFeeCollectorAddress(
                    address(FEE_COLLECTOR_CONTROLLER),
                    FEE_COLLECTOR_INIT_CODE_HASH,
                    poolId
                )
            );
    }

    /// @dev Get the cost of a single protocol fee.
    /// @return protocolFeeAmount The protocol fee amount, in ETH/WETH.
    function _getSingleProtocolFee() internal view returns (uint256 protocolFeeAmount) {
        return uint256(PROTOCOL_FEE_MULTIPLIER) * tx.gasprice;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/LibBytesV06.sol";
import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "../errors/LibCommonRichErrors.sol";
import "../storage/LibReentrancyGuardStorage.sol";

/// @dev Common feature utilities.
abstract contract FixinReentrancyGuard {
    using LibRichErrorsV06 for bytes;
    using LibBytesV06 for bytes;

    // Combinable reentrancy flags.
    /// @dev Reentrancy guard flag for meta-transaction functions.
    uint256 internal constant REENTRANCY_MTX = 0x1;

    /// @dev Cannot reenter a function with the same reentrancy guard flags.
    modifier nonReentrant(uint256 reentrancyFlags) virtual {
        LibReentrancyGuardStorage.Storage storage stor = LibReentrancyGuardStorage.getStorage();
        {
            uint256 currentFlags = stor.reentrancyFlags;
            // Revert if any bits in `reentrancyFlags` has already been set.
            if ((currentFlags & reentrancyFlags) != 0) {
                LibCommonRichErrors.IllegalReentrancyError(msg.data.readBytes4(0), reentrancyFlags).rrevert();
            }
            // Update reentrancy flags.
            stor.reentrancyFlags = currentFlags | reentrancyFlags;
        }

        _;

        // Clear reentrancy flags.
        stor.reentrancyFlags = stor.reentrancyFlags & (~reentrancyFlags);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";

/// @dev Helpers for moving tokens around.
abstract contract FixinTokenSpender {
    // Mask of the lower 20 bytes of a bytes32.
    uint256 private constant ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;

    /// @dev Transfers ERC20 tokens from `owner` to `to`.
    /// @param token The token to spend.
    /// @param owner The owner of the tokens.
    /// @param to The recipient of the tokens.
    /// @param amount The amount of `token` to transfer.
    function _transferERC20TokensFrom(IERC20TokenV06 token, address owner, address to, uint256 amount) internal {
        require(address(token) != address(this), "FixinTokenSpender/CANNOT_INVOKE_SELF");

        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for transferFrom(address,address,uint256)
            mstore(ptr, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), and(owner, ADDRESS_MASK))
            mstore(add(ptr, 0x24), and(to, ADDRESS_MASK))
            mstore(add(ptr, 0x44), amount)

            let success := call(gas(), and(token, ADDRESS_MASK), 0, ptr, 0x64, ptr, 32)

            let rdsize := returndatasize()

            // Check for ERC20 success. ERC20 tokens should return a boolean,
            // but some don't. We accept 0-length return data as success, or at
            // least 32 bytes that starts with a 32-byte boolean true.
            success := and(
                success, // call itself succeeded
                or(
                    iszero(rdsize), // no return data, or
                    and(
                        iszero(lt(rdsize, 32)), // at least 32 bytes
                        eq(mload(ptr), 1) // starts with uint256(1)
                    )
                )
            )

            if iszero(success) {
                returndatacopy(ptr, 0, rdsize)
                revert(ptr, rdsize)
            }
        }
    }

    /// @dev Transfers ERC20 tokens from ourselves to `to`.
    /// @param token The token to spend.
    /// @param to The recipient of the tokens.
    /// @param amount The amount of `token` to transfer.
    function _transferERC20Tokens(IERC20TokenV06 token, address to, uint256 amount) internal {
        require(address(token) != address(this), "FixinTokenSpender/CANNOT_INVOKE_SELF");

        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for transfer(address,uint256)
            mstore(ptr, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), and(to, ADDRESS_MASK))
            mstore(add(ptr, 0x24), amount)

            let success := call(gas(), and(token, ADDRESS_MASK), 0, ptr, 0x44, ptr, 32)

            let rdsize := returndatasize()

            // Check for ERC20 success. ERC20 tokens should return a boolean,
            // but some don't. We accept 0-length return data as success, or at
            // least 32 bytes that starts with a 32-byte boolean true.
            success := and(
                success, // call itself succeeded
                or(
                    iszero(rdsize), // no return data, or
                    and(
                        iszero(lt(rdsize, 32)), // at least 32 bytes
                        eq(mload(ptr), 1) // starts with uint256(1)
                    )
                )
            )

            if iszero(success) {
                returndatacopy(ptr, 0, rdsize)
                revert(ptr, rdsize)
            }
        }
    }

    /// @dev Transfers some amount of ETH to the given recipient and
    ///      reverts if the transfer fails.
    /// @param recipient The recipient of the ETH.
    /// @param amount The amount of ETH to transfer.
    function _transferEth(address payable recipient, uint256 amount) internal {
        if (amount > 0) {
            (bool success, ) = recipient.call{value: amount}("");
            require(success, "FixinTokenSpender::_transferEth/TRANSFER_FAILED");
        }
    }

    /// @dev Gets the maximum amount of an ERC20 token `token` that can be
    ///      pulled from `owner` by this address.
    /// @param token The token to spend.
    /// @param owner The owner of the tokens.
    /// @return amount The amount of tokens that can be pulled.
    function _getSpendableERC20BalanceOf(IERC20TokenV06 token, address owner) internal view returns (uint256) {
        return LibSafeMathV06.min256(token.allowance(owner, address(this)), token.balanceOf(owner));
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./features/interfaces/IOwnableFeature.sol";
import "./features/interfaces/ISimpleFunctionRegistryFeature.sol";
import "./features/interfaces/ITokenSpenderFeature.sol";
import "./features/interfaces/ITransformERC20Feature.sol";
import "./features/interfaces/IMetaTransactionsFeature.sol";
import "./features/interfaces/IUniswapFeature.sol";
import "./features/interfaces/IUniswapV3Feature.sol";
import "./features/interfaces/IPancakeSwapFeature.sol";
import "./features/interfaces/ILiquidityProviderFeature.sol";
import "./features/interfaces/INativeOrdersFeature.sol";
import "./features/interfaces/IBatchFillNativeOrdersFeature.sol";
import "./features/interfaces/IMultiplexFeature.sol";
import "./features/interfaces/IOtcOrdersFeature.sol";
import "./features/interfaces/IFundRecoveryFeature.sol";
import "./features/interfaces/IERC721OrdersFeature.sol";
import "./features/interfaces/IERC1155OrdersFeature.sol";
import "./features/interfaces/IERC165Feature.sol";

/// @dev Interface for a fully featured Exchange Proxy.
interface IZeroEx is
    IOwnableFeature,
    ISimpleFunctionRegistryFeature,
    ITransformERC20Feature,
    IMetaTransactionsFeature,
    IUniswapFeature,
    IUniswapV3Feature,
    IPancakeSwapFeature,
    ILiquidityProviderFeature,
    INativeOrdersFeature,
    IBatchFillNativeOrdersFeature,
    IMultiplexFeature,
    IOtcOrdersFeature,
    IFundRecoveryFeature,
    IERC721OrdersFeature,
    IERC1155OrdersFeature,
    IERC165Feature
{
    /// @dev Fallback for just receiving ether.
    receive() external payable;
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../transformers/LibERC20Transformer.sol";
import "../vendor/ILiquidityProvider.sol";

contract CurveLiquidityProvider is ILiquidityProvider {
    using LibERC20TokenV06 for IERC20TokenV06;
    using LibSafeMathV06 for uint256;
    using LibRichErrorsV06 for bytes;

    struct CurveData {
        address curveAddress;
        bytes4 exchangeFunctionSelector;
        int128 fromCoinIdx;
        int128 toCoinIdx;
    }

    /// @dev This contract must be payable because takers can transfer funds
    ///      in prior to calling the swap function.
    receive() external payable {}

    /// @dev Trades `inputToken` for `outputToken`. The amount of `inputToken`
    ///      to sell must be transferred to the contract prior to calling this
    ///      function to trigger the trade.
    /// @param inputToken The token being sold.
    /// @param outputToken The token being bought.
    /// @param recipient The recipient of the bought tokens.
    /// @param minBuyAmount The minimum acceptable amount of `outputToken` to buy.
    /// @param auxiliaryData Arbitrary auxiliary data supplied to the contract.
    /// @return boughtAmount The amount of `outputToken` bought.
    function sellTokenForToken(
        IERC20TokenV06 inputToken,
        IERC20TokenV06 outputToken,
        address recipient,
        uint256 minBuyAmount,
        bytes calldata auxiliaryData
    ) external override returns (uint256 boughtAmount) {
        require(
            !LibERC20Transformer.isTokenETH(inputToken) && !LibERC20Transformer.isTokenETH(outputToken),
            "CurveLiquidityProvider/INVALID_ARGS"
        );
        boughtAmount = _executeSwap(
            inputToken,
            outputToken,
            minBuyAmount,
            abi.decode(auxiliaryData, (CurveData)),
            recipient
        );
        // Every pool contract currently checks this but why not.
        require(boughtAmount >= minBuyAmount, "CurveLiquidityProvider/UNDERBOUGHT");
        outputToken.compatTransfer(recipient, boughtAmount);
    }

    /// @dev Trades ETH for token. ETH must either be attached to this function
    ///      call or sent to the contract prior to calling this function to
    ///      trigger the trade.
    /// @param outputToken The token being bought.
    /// @param recipient The recipient of the bought tokens.
    /// @param minBuyAmount The minimum acceptable amount of `outputToken` to buy.
    /// @param auxiliaryData Arbitrary auxiliary data supplied to the contract.
    /// @return boughtAmount The amount of `outputToken` bought.
    function sellEthForToken(
        IERC20TokenV06 outputToken,
        address recipient,
        uint256 minBuyAmount,
        bytes calldata auxiliaryData
    ) external payable override returns (uint256 boughtAmount) {
        require(!LibERC20Transformer.isTokenETH(outputToken), "CurveLiquidityProvider/INVALID_ARGS");
        boughtAmount = _executeSwap(
            LibERC20Transformer.ETH_TOKEN,
            outputToken,
            minBuyAmount,
            abi.decode(auxiliaryData, (CurveData)),
            recipient
        );
        // Every pool contract currently checks this but why not.
        require(boughtAmount >= minBuyAmount, "CurveLiquidityProvider/UNDERBOUGHT");
        outputToken.compatTransfer(recipient, boughtAmount);
    }

    /// @dev Trades token for ETH. The token must be sent to the contract prior
    ///      to calling this function to trigger the trade.
    /// @param inputToken The token being sold.
    /// @param recipient The recipient of the bought tokens.
    /// @param minBuyAmount The minimum acceptable amount of ETH to buy.
    /// @param auxiliaryData Arbitrary auxiliary data supplied to the contract.
    /// @return boughtAmount The amount of ETH bought.
    function sellTokenForEth(
        IERC20TokenV06 inputToken,
        address payable recipient,
        uint256 minBuyAmount,
        bytes calldata auxiliaryData
    ) external override returns (uint256 boughtAmount) {
        require(!LibERC20Transformer.isTokenETH(inputToken), "CurveLiquidityProvider/INVALID_ARGS");
        boughtAmount = _executeSwap(
            inputToken,
            LibERC20Transformer.ETH_TOKEN,
            minBuyAmount,
            abi.decode(auxiliaryData, (CurveData)),
            recipient
        );
        // Every pool contract currently checks this but why not.
        require(boughtAmount >= minBuyAmount, "CurveLiquidityProvider/UNDERBOUGHT");
        recipient.transfer(boughtAmount);
    }

    /// @dev Quotes the amount of `outputToken` that would be obtained by
    ///      selling `sellAmount` of `inputToken`.
    function getSellQuote(
        IERC20TokenV06 /* inputToken */,
        IERC20TokenV06 /* outputToken */,
        uint256 /* sellAmount */
    ) external view override returns (uint256) {
        revert("CurveLiquidityProvider/NOT_IMPLEMENTED");
    }

    /// @dev Perform the swap against the curve pool. Handles any combination of
    ///      tokens
    function _executeSwap(
        IERC20TokenV06 inputToken,
        IERC20TokenV06 outputToken,
        uint256 minBuyAmount,
        CurveData memory data,
        address recipient // Only used to log event.
    ) private returns (uint256 boughtAmount) {
        uint256 sellAmount = LibERC20Transformer.getTokenBalanceOf(inputToken, address(this));
        if (!LibERC20Transformer.isTokenETH(inputToken)) {
            inputToken.approveIfBelow(data.curveAddress, sellAmount);
        }

        (bool success, bytes memory resultData) = data.curveAddress.call{
            value: LibERC20Transformer.isTokenETH(inputToken) ? sellAmount : 0
        }(
            abi.encodeWithSelector(
                data.exchangeFunctionSelector,
                data.fromCoinIdx,
                data.toCoinIdx,
                // dx
                sellAmount,
                // min dy
                minBuyAmount
            )
        );
        if (!success) {
            resultData.rrevert();
        }
        if (resultData.length == 32) {
            // Pool returned a boughtAmount
            boughtAmount = abi.decode(resultData, (uint256));
        } else {
            // Not all pool contracts return a `boughtAmount`, so we return
            // our balance of the output token if it wasn't returned.
            boughtAmount = LibERC20Transformer.getTokenBalanceOf(outputToken, address(this));
        }

        emit LiquidityProviderFill(
            inputToken,
            outputToken,
            sellAmount,
            boughtAmount,
            bytes32("Curve"),
            address(data.curveAddress),
            msg.sender,
            recipient
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IEtherTokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../transformers/LibERC20Transformer.sol";
import "../vendor/ILiquidityProvider.sol";
import "../vendor/IMooniswapPool.sol";

contract MooniswapLiquidityProvider is ILiquidityProvider {
    using LibERC20TokenV06 for IERC20TokenV06;
    using LibSafeMathV06 for uint256;
    using LibRichErrorsV06 for bytes;

    IEtherTokenV06 private immutable WETH;

    constructor(IEtherTokenV06 weth) public {
        WETH = weth;
    }

    /// @dev This contract must be payable because takers can transfer funds
    ///      in prior to calling the swap function.
    receive() external payable {}

    /// @dev Trades `inputToken` for `outputToken`. The amount of `inputToken`
    ///      to sell must be transferred to the contract prior to calling this
    ///      function to trigger the trade.
    /// @param inputToken The token being sold.
    /// @param outputToken The token being bought.
    /// @param recipient The recipient of the bought tokens.
    /// @param minBuyAmount The minimum acceptable amount of `outputToken` to buy.
    /// @param auxiliaryData Arbitrary auxiliary data supplied to the contract.
    /// @return boughtAmount The amount of `outputToken` bought.
    function sellTokenForToken(
        IERC20TokenV06 inputToken,
        IERC20TokenV06 outputToken,
        address recipient,
        uint256 minBuyAmount,
        bytes calldata auxiliaryData
    ) external override returns (uint256 boughtAmount) {
        require(
            !LibERC20Transformer.isTokenETH(inputToken) &&
                !LibERC20Transformer.isTokenETH(outputToken) &&
                inputToken != outputToken,
            "MooniswapLiquidityProvider/INVALID_ARGS"
        );
        boughtAmount = _executeSwap(
            inputToken,
            outputToken,
            minBuyAmount,
            abi.decode(auxiliaryData, (IMooniswapPool)),
            recipient
        );
        outputToken.compatTransfer(recipient, boughtAmount);
    }

    /// @dev Trades ETH for token. ETH must either be attached to this function
    ///      call or sent to the contract prior to calling this function to
    ///      trigger the trade.
    /// @param outputToken The token being bought.
    /// @param recipient The recipient of the bought tokens.
    /// @param minBuyAmount The minimum acceptable amount of `outputToken` to buy.
    /// @param auxiliaryData Arbitrary auxiliary data supplied to the contract.
    /// @return boughtAmount The amount of `outputToken` bought.
    function sellEthForToken(
        IERC20TokenV06 outputToken,
        address recipient,
        uint256 minBuyAmount,
        bytes calldata auxiliaryData
    ) external payable override returns (uint256 boughtAmount) {
        require(!LibERC20Transformer.isTokenETH(outputToken), "MooniswapLiquidityProvider/INVALID_ARGS");
        boughtAmount = _executeSwap(
            LibERC20Transformer.ETH_TOKEN,
            outputToken,
            minBuyAmount,
            abi.decode(auxiliaryData, (IMooniswapPool)),
            recipient
        );
        outputToken.compatTransfer(recipient, boughtAmount);
    }

    /// @dev Trades token for ETH. The token must be sent to the contract prior
    ///      to calling this function to trigger the trade.
    /// @param inputToken The token being sold.
    /// @param recipient The recipient of the bought tokens.
    /// @param minBuyAmount The minimum acceptable amount of ETH to buy.
    /// @param auxiliaryData Arbitrary auxiliary data supplied to the contract.
    /// @return boughtAmount The amount of ETH bought.
    function sellTokenForEth(
        IERC20TokenV06 inputToken,
        address payable recipient,
        uint256 minBuyAmount,
        bytes calldata auxiliaryData
    ) external override returns (uint256 boughtAmount) {
        require(!LibERC20Transformer.isTokenETH(inputToken), "MooniswapLiquidityProvider/INVALID_ARGS");
        boughtAmount = _executeSwap(
            inputToken,
            LibERC20Transformer.ETH_TOKEN,
            minBuyAmount,
            abi.decode(auxiliaryData, (IMooniswapPool)),
            recipient
        );
        recipient.call{value: boughtAmount}("");
    }

    /// @dev Quotes the amount of `outputToken` that would be obtained by
    ///      selling `sellAmount` of `inputToken`.
    function getSellQuote(
        IERC20TokenV06 /* inputToken */,
        IERC20TokenV06 /* outputToken */,
        uint256 /* sellAmount */
    ) external view override returns (uint256) {
        revert("MooniswapLiquidityProvider/NOT_IMPLEMENTED");
    }

    /// @dev Perform the swap against the curve pool. Handles any combination of
    ///      tokens
    function _executeSwap(
        IERC20TokenV06 inputToken,
        IERC20TokenV06 outputToken,
        uint256 minBuyAmount,
        IMooniswapPool pool,
        address recipient // Only used to log event
    ) private returns (uint256 boughtAmount) {
        uint256 sellAmount = LibERC20Transformer.getTokenBalanceOf(inputToken, address(this));
        uint256 ethValue = 0;
        if (inputToken == WETH) {
            // Selling WETH. Unwrap to ETH.
            require(!_isTokenEthLike(outputToken), "MooniswapLiquidityProvider/ETH_TO_ETH");
            WETH.withdraw(sellAmount);
            ethValue = sellAmount;
        } else if (LibERC20Transformer.isTokenETH(inputToken)) {
            // Selling ETH directly.
            ethValue = sellAmount;
            require(!_isTokenEthLike(outputToken), "MooniswapLiquidityProvider/ETH_TO_ETH");
        } else {
            // Selling a regular ERC20.
            require(inputToken != outputToken, "MooniswapLiquidityProvider/SAME_TOKEN");
            inputToken.approveIfBelow(address(pool), sellAmount);
        }

        boughtAmount = pool.swap{value: ethValue}(
            _isTokenEthLike(inputToken) ? IERC20TokenV06(0) : inputToken,
            _isTokenEthLike(outputToken) ? IERC20TokenV06(0) : outputToken,
            sellAmount,
            minBuyAmount,
            address(0)
        );

        if (outputToken == WETH) {
            WETH.deposit{value: boughtAmount}();
        }

        emit LiquidityProviderFill(
            inputToken,
            outputToken,
            sellAmount,
            boughtAmount,
            bytes32("Mooniswap"),
            address(pool),
            msg.sender,
            recipient
        );
    }

    /// @dev Check if a token is ETH or WETH.
    function _isTokenEthLike(IERC20TokenV06 token) private view returns (bool isEthOrWeth) {
        return LibERC20Transformer.isTokenETH(token) || token == WETH;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "../ZeroEx.sol";
import "../features/interfaces/IOwnableFeature.sol";
import "../features/TransformERC20Feature.sol";
import "../features/MetaTransactionsFeature.sol";
import "../features/NativeOrdersFeature.sol";
import "../features/OtcOrdersFeature.sol";
import "./InitialMigration.sol";

/// @dev A contract for deploying and configuring the full ZeroEx contract.
contract FullMigration {
    /// @dev Features to add the the proxy contract.
    struct Features {
        SimpleFunctionRegistryFeature registry;
        OwnableFeature ownable;
        TransformERC20Feature transformERC20;
        MetaTransactionsFeature metaTransactions;
        NativeOrdersFeature nativeOrders;
        OtcOrdersFeature otcOrders;
    }

    /// @dev Parameters needed to initialize features.
    struct MigrateOpts {
        address transformerDeployer;
    }

    /// @dev The allowed caller of `initializeZeroEx()`.
    address public immutable initializeCaller;
    /// @dev The initial migration contract.
    InitialMigration private _initialMigration;

    /// @dev Instantiate this contract and set the allowed caller of `initializeZeroEx()`
    ///      to `initializeCaller`.
    /// @param initializeCaller_ The allowed caller of `initializeZeroEx()`.
    constructor(address payable initializeCaller_) public {
        initializeCaller = initializeCaller_;
        // Create an initial migration contract with this contract set to the
        // allowed `initializeCaller`.
        _initialMigration = new InitialMigration(address(this));
    }

    /// @dev Retrieve the bootstrapper address to use when constructing `ZeroEx`.
    /// @return bootstrapper The bootstrapper address.
    function getBootstrapper() external view returns (address bootstrapper) {
        return address(_initialMigration);
    }

    /// @dev Initialize the `ZeroEx` contract with the full feature set,
    ///      transfer ownership to `owner`, then self-destruct.
    /// @param owner The owner of the contract.
    /// @param zeroEx The instance of the ZeroEx contract. ZeroEx should
    ///        been constructed with this contract as the bootstrapper.
    /// @param features Features to add to the proxy.
    /// @return _zeroEx The configured ZeroEx contract. Same as the `zeroEx` parameter.
    /// @param migrateOpts Parameters needed to initialize features.
    function migrateZeroEx(
        address payable owner,
        ZeroEx zeroEx,
        Features memory features,
        MigrateOpts memory migrateOpts
    ) public returns (ZeroEx _zeroEx) {
        require(msg.sender == initializeCaller, "FullMigration/INVALID_SENDER");

        // Perform the initial migration with the owner set to this contract.
        _initialMigration.initializeZeroEx(
            address(uint160(address(this))),
            zeroEx,
            InitialMigration.BootstrapFeatures({registry: features.registry, ownable: features.ownable})
        );

        // Add features.
        _addFeatures(zeroEx, features, migrateOpts);

        // Transfer ownership to the real owner.
        IOwnableFeature(address(zeroEx)).transferOwnership(owner);

        // Self-destruct.
        this.die(owner);

        return zeroEx;
    }

    /// @dev Destroy this contract. Only callable from ourselves (from `initializeZeroEx()`).
    /// @param ethRecipient Receiver of any ETH in this contract.
    function die(address payable ethRecipient) external virtual {
        require(msg.sender == address(this), "FullMigration/INVALID_SENDER");
        // This contract should not hold any funds but we send
        // them to the ethRecipient just in case.
        selfdestruct(ethRecipient);
    }

    /// @dev Deploy and register features to the ZeroEx contract.
    /// @param zeroEx The bootstrapped ZeroEx contract.
    /// @param features Features to add to the proxy.
    /// @param migrateOpts Parameters needed to initialize features.
    function _addFeatures(ZeroEx zeroEx, Features memory features, MigrateOpts memory migrateOpts) private {
        IOwnableFeature ownable = IOwnableFeature(address(zeroEx));
        // TransformERC20Feature
        {
            // Register the feature.
            ownable.migrate(
                address(features.transformERC20),
                abi.encodeWithSelector(TransformERC20Feature.migrate.selector, migrateOpts.transformerDeployer),
                address(this)
            );
        }
        // MetaTransactionsFeature
        {
            // Register the feature.
            ownable.migrate(
                address(features.metaTransactions),
                abi.encodeWithSelector(MetaTransactionsFeature.migrate.selector),
                address(this)
            );
        }
        // NativeOrdersFeature
        {
            // Register the feature.
            ownable.migrate(
                address(features.nativeOrders),
                abi.encodeWithSelector(NativeOrdersFeature.migrate.selector),
                address(this)
            );
        }
        // OtcOrdersFeature
        {
            // Register the feature.
            ownable.migrate(
                address(features.otcOrders),
                abi.encodeWithSelector(OtcOrdersFeature.migrate.selector),
                address(this)
            );
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "../ZeroEx.sol";
import "../features/interfaces/IBootstrapFeature.sol";
import "../features/SimpleFunctionRegistryFeature.sol";
import "../features/OwnableFeature.sol";
import "./LibBootstrap.sol";

/// @dev A contract for deploying and configuring a minimal ZeroEx contract.
contract InitialMigration {
    /// @dev Features to bootstrap into the the proxy contract.
    struct BootstrapFeatures {
        SimpleFunctionRegistryFeature registry;
        OwnableFeature ownable;
    }

    /// @dev The allowed caller of `initializeZeroEx()`. In production, this would be
    ///      the governor.
    address public immutable initializeCaller;
    /// @dev The real address of this contract.
    address private immutable _implementation;

    /// @dev Instantiate this contract and set the allowed caller of `initializeZeroEx()`
    ///      to `initializeCaller_`.
    /// @param initializeCaller_ The allowed caller of `initializeZeroEx()`.
    constructor(address initializeCaller_) public {
        initializeCaller = initializeCaller_;
        _implementation = address(this);
    }

    /// @dev Initialize the `ZeroEx` contract with the minimum feature set,
    ///      transfers ownership to `owner`, then self-destructs.
    ///      Only callable by `initializeCaller` set in the contstructor.
    /// @param owner The owner of the contract.
    /// @param zeroEx The instance of the ZeroEx contract. ZeroEx should
    ///        been constructed with this contract as the bootstrapper.
    /// @param features Features to bootstrap into the proxy.
    /// @return _zeroEx The configured ZeroEx contract. Same as the `zeroEx` parameter.
    function initializeZeroEx(
        address payable owner,
        ZeroEx zeroEx,
        BootstrapFeatures memory features
    ) public virtual returns (ZeroEx _zeroEx) {
        // Must be called by the allowed initializeCaller.
        require(msg.sender == initializeCaller, "InitialMigration/INVALID_SENDER");

        // Bootstrap the initial feature set.
        IBootstrapFeature(address(zeroEx)).bootstrap(
            address(this),
            abi.encodeWithSelector(this.bootstrap.selector, owner, features)
        );

        // Self-destruct. This contract should not hold any funds but we send
        // them to the owner just in case.
        this.die(owner);

        return zeroEx;
    }

    /// @dev Sets up the initial state of the `ZeroEx` contract.
    ///      The `ZeroEx` contract will delegatecall into this function.
    /// @param owner The new owner of the ZeroEx contract.
    /// @param features Features to bootstrap into the proxy.
    /// @return success Magic bytes if successful.
    function bootstrap(address owner, BootstrapFeatures memory features) public virtual returns (bytes4 success) {
        // Deploy and migrate the initial features.
        // Order matters here.

        // Initialize Registry.
        LibBootstrap.delegatecallBootstrapFunction(
            address(features.registry),
            abi.encodeWithSelector(SimpleFunctionRegistryFeature.bootstrap.selector)
        );

        // Initialize OwnableFeature.
        LibBootstrap.delegatecallBootstrapFunction(
            address(features.ownable),
            abi.encodeWithSelector(OwnableFeature.bootstrap.selector)
        );

        // De-register `SimpleFunctionRegistryFeature._extendSelf`.
        SimpleFunctionRegistryFeature(address(this)).rollback(
            SimpleFunctionRegistryFeature._extendSelf.selector,
            address(0)
        );

        // Transfer ownership to the real owner.
        OwnableFeature(address(this)).transferOwnership(owner);

        success = LibBootstrap.BOOTSTRAP_SUCCESS;
    }

    /// @dev Self-destructs this contract. Only callable by this contract.
    /// @param ethRecipient Who to transfer outstanding ETH to.
    function die(address payable ethRecipient) public virtual {
        require(msg.sender == _implementation, "InitialMigration/INVALID_SENDER");
        selfdestruct(ethRecipient);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "../errors/LibProxyRichErrors.sol";


library LibBootstrap {

    /// @dev Magic bytes returned by the bootstrapper to indicate success.
    ///      This is `keccack('BOOTSTRAP_SUCCESS')`.
    bytes4 internal constant BOOTSTRAP_SUCCESS = 0xd150751b;

    using LibRichErrorsV06 for bytes;

    /// @dev Perform a delegatecall and ensure it returns the magic bytes.
    /// @param target The call target.
    /// @param data The call data.
    function delegatecallBootstrapFunction(
        address target,
        bytes memory data
    )
        internal
    {
        (bool success, bytes memory resultData) = target.delegatecall(data);
        if (!success ||
            resultData.length != 32 ||
            abi.decode(resultData, (bytes4)) != BOOTSTRAP_SUCCESS)
        {
            LibProxyRichErrors.BootstrapCallFailedError(target, resultData).rrevert();
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "../errors/LibOwnableRichErrors.sol";

library LibMigrate {
    /// @dev Magic bytes returned by a migrator to indicate success.
    ///      This is `keccack('MIGRATE_SUCCESS')`.
    bytes4 internal constant MIGRATE_SUCCESS = 0x2c64c5ef;

    using LibRichErrorsV06 for bytes;

    /// @dev Perform a delegatecall and ensure it returns the magic bytes.
    /// @param target The call target.
    /// @param data The call data.
    function delegatecallMigrateFunction(address target, bytes memory data) internal {
        (bool success, bytes memory resultData) = target.delegatecall(data);
        if (!success || resultData.length != 32 || abi.decode(resultData, (bytes4)) != MIGRATE_SUCCESS) {
            LibOwnableRichErrors.MigrateCallFailedError(target, resultData).rrevert();
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6;
pragma experimental ABIEncoderV2;

import "./LibStorage.sol";

/// @dev Storage helpers for `ERC1155OrdersFeature`.
library LibERC1155OrdersStorage {
    struct OrderState {
        // The amount (denominated in the ERC1155 asset)
        // that the order has been filled by.
        uint128 filledAmount;
        // Whether the order has been pre-signed.
        bool preSigned;
    }

    /// @dev Storage bucket for this feature.
    struct Storage {
        // Mapping from order hash to order state:
        mapping(bytes32 => OrderState) orderState;
        // maker => nonce range => order cancellation bit vector
        mapping(address => mapping(uint248 => uint256)) orderCancellationByMaker;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.getStorageSlot(LibStorage.StorageId.ERC1155Orders);
        // Dip into assembly to change the slot pointed to by the local variable `stor`.
        // solhint-disable-next-line max-line-length
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly {
            stor_slot := storageSlot
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6;
pragma experimental ABIEncoderV2;

import "./LibStorage.sol";

/// @dev Storage helpers for `ERC721OrdersFeature`.
library LibERC721OrdersStorage {
    /// @dev Storage bucket for this feature.
    struct Storage {
        // maker => nonce range => order status bit vector
        mapping(address => mapping(uint248 => uint256)) orderStatusByMaker;
        // order hash => isSigned
        mapping(bytes32 => bool) preSigned;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.getStorageSlot(LibStorage.StorageId.ERC721Orders);
        // Dip into assembly to change the slot pointed to by the local variable `stor`.
        // solhint-disable-next-line max-line-length
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly {
            stor_slot := storageSlot
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./LibStorage.sol";

/// @dev Storage helpers for the `MetaTransactions` feature.
library LibMetaTransactionsStorage {
    /// @dev Storage bucket for this feature.
    struct Storage {
        // The block number when a hash was executed.
        mapping(bytes32 => uint256) mtxHashToExecutedBlockNumber;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.getStorageSlot(LibStorage.StorageId.MetaTransactions);
        // Dip into assembly to change the slot pointed to by the local variable `stor`.
        // solhint-disable-next-line max-line-length
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly {
            stor_slot := storageSlot
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./LibStorage.sol";

/// @dev Storage helpers for `NativeOrdersFeature`.
library LibNativeOrdersStorage {
    /// @dev Storage bucket for this feature.
    struct Storage {
        // How much taker token has been filled in order.
        // The lower `uint128` is the taker token fill amount.
        // The high bit will be `1` if the order was directly cancelled.
        mapping(bytes32 => uint256) orderHashToTakerTokenFilledAmount;
        // The minimum valid order salt for a given maker and order pair (maker, taker) for limit orders.
        // solhint-disable-next-line max-line-length
        mapping(address => mapping(address => mapping(address => uint256))) limitOrdersMakerToMakerTokenToTakerTokenToMinValidOrderSalt;
        // The minimum valid order salt for a given maker and order pair (maker, taker) for RFQ orders.
        // solhint-disable-next-line max-line-length
        mapping(address => mapping(address => mapping(address => uint256))) rfqOrdersMakerToMakerTokenToTakerTokenToMinValidOrderSalt;
        // For a given order origin, which tx.origin addresses are allowed to fill the order.
        mapping(address => mapping(address => bool)) originRegistry;
        // For a given maker address, which addresses are allowed to
        // sign on its behalf.
        mapping(address => mapping(address => bool)) orderSignerRegistry;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.getStorageSlot(LibStorage.StorageId.NativeOrders);
        // Dip into assembly to change the slot pointed to by the local variable `stor`.
        // solhint-disable-next-line max-line-length
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly {
            stor_slot := storageSlot
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./LibStorage.sol";

/// @dev Storage helpers for `OtcOrdersFeature`.
library LibOtcOrdersStorage {
    /// @dev Storage bucket for this feature.
    struct Storage {
        // tx origin => nonce buckets => min nonce
        mapping(address => mapping(uint64 => uint128)) txOriginNonces;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.getStorageSlot(LibStorage.StorageId.OtcOrders);
        // Dip into assembly to change the slot pointed to by the local variable `stor`.
        // solhint-disable-next-line max-line-length
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly {
            stor_slot := storageSlot
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./LibStorage.sol";

/// @dev Storage helpers for the `Ownable` feature.
library LibOwnableStorage {
    /// @dev Storage bucket for this feature.
    struct Storage {
        // The owner of this contract.
        address owner;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.getStorageSlot(LibStorage.StorageId.Ownable);
        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // solhint-disable-next-line max-line-length
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly {
            stor_slot := storageSlot
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./LibStorage.sol";


/// @dev Storage helpers for the proxy contract.
library LibProxyStorage {

    /// @dev Storage bucket for proxy contract.
    struct Storage {
        // Mapping of function selector -> function implementation
        mapping(bytes4 => address) impls;
        // The owner of the proxy contract.
        address owner;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.getStorageSlot(
            LibStorage.StorageId.Proxy
        );
        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly { stor_slot := storageSlot }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./LibStorage.sol";
import "../external/IFlashWallet.sol";

/// @dev Storage helpers for the `FixinReentrancyGuard` mixin.
library LibReentrancyGuardStorage {
    /// @dev Storage bucket for this feature.
    struct Storage {
        // Reentrancy flags set whenever a non-reentrant function is entered and cleared when it is exited.
        uint256 reentrancyFlags;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.getStorageSlot(LibStorage.StorageId.ReentrancyGuard);
        // Dip into assembly to change the slot pointed to by the local variable `stor`.
        // solhint-disable-next-line max-line-length
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly {
            stor_slot := storageSlot
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./LibStorage.sol";

/// @dev Storage helpers for the `SimpleFunctionRegistry` feature.
library LibSimpleFunctionRegistryStorage {
    /// @dev Storage bucket for this feature.
    struct Storage {
        // Mapping of function selector -> implementation history.
        mapping(bytes4 => address[]) implHistory;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.getStorageSlot(LibStorage.StorageId.SimpleFunctionRegistry);
        // Dip into assembly to change the slot pointed to by the local variable `stor`.
        // solhint-disable-next-line max-line-length
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly {
            stor_slot := storageSlot
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6;
pragma experimental ABIEncoderV2;

/// @dev Common storage helpers
library LibStorage {
    /// @dev What to bit-shift a storage ID by to get its slot.
    /// This gives us a maximum of 2**128 inline fields in each bucket.
    uint256 private constant STORAGE_SLOT_EXP = 128;

    /// @dev Storage IDs for feature storage buckets.
    /// WARNING: APPEND-ONLY.
    enum StorageId {
        Proxy,
        SimpleFunctionRegistry,
        Ownable,
        TokenSpender,
        TransformERC20,
        MetaTransactions,
        ReentrancyGuard,
        NativeOrders,
        OtcOrders,
        ERC721Orders,
        ERC1155Orders
    }

    /// @dev Get the storage slot given a storage ID. We assign unique, well-spaced slots to storage bucket variables
    /// to ensure they do not overlap.
    // solhint-disable-next-line max-line-length
    /// See: https://solidity.readthedocs.io/en/v0.6.6/assembly.html#access-to-external-variables-functions-and-libraries
    /// @param storageId An entry in `StorageId`
    /// @return slot The storage slot.
    function getStorageSlot(StorageId storageId) internal pure returns (uint256 slot) {
        // This should never overflow with a reasonable `STORAGE_SLOT_EXP`
        // because Solidity will do a range check on `storageId` during the cast.
        return (uint256(storageId) + 1) << STORAGE_SLOT_EXP;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./LibStorage.sol";
import "../external/IFlashWallet.sol";

/// @dev Storage helpers for the `TransformERC20` feature.
library LibTransformERC20Storage {
    /// @dev Storage bucket for this feature.
    struct Storage {
        // The current wallet instance.
        IFlashWallet wallet;
        // The transformer deployer address.
        address transformerDeployer;
        // The optional signer for `transformERC20()` calldata.
        address quoteSigner;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.getStorageSlot(LibStorage.StorageId.TransformERC20);
        // Dip into assembly to change the slot pointed to by the local variable `stor`.
        // solhint-disable-next-line max-line-length
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly {
            stor_slot := storageSlot
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "../errors/LibTransformERC20RichErrors.sol";
import "./Transformer.sol";
import "./LibERC20Transformer.sol";

/// @dev A transformer that transfers tokens to arbitrary addresses.
contract AffiliateFeeTransformer is Transformer {
    using LibRichErrorsV06 for bytes;
    using LibSafeMathV06 for uint256;
    using LibERC20Transformer for IERC20TokenV06;

    /// @dev Information for a single fee.
    struct TokenFee {
        // The token to transfer to `recipient`.
        IERC20TokenV06 token;
        // Amount of each `token` to transfer to `recipient`.
        // If `amount == uint256(-1)`, the entire balance of `token` will be
        // transferred.
        uint256 amount;
        // Recipient of `token`.
        address payable recipient;
    }

    uint256 private constant MAX_UINT256 = uint256(-1);

    /// @dev Transfers tokens to recipients.
    /// @param context Context information.
    /// @return success The success bytes (`LibERC20Transformer.TRANSFORMER_SUCCESS`).
    function transform(TransformContext calldata context) external override returns (bytes4 success) {
        TokenFee[] memory fees = abi.decode(context.data, (TokenFee[]));

        // Transfer tokens to recipients.
        for (uint256 i = 0; i < fees.length; ++i) {
            uint256 amount = fees[i].amount;
            if (amount == MAX_UINT256) {
                amount = LibERC20Transformer.getTokenBalanceOf(fees[i].token, address(this));
            }
            if (amount != 0) {
                fees[i].token.unsafeTransformerTransfer(fees[i].recipient, amount);
            }
        }

        return LibERC20Transformer.TRANSFORMER_SUCCESS;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6;
pragma experimental ABIEncoderV2;

import "./IBridgeAdapter.sol";

abstract contract AbstractBridgeAdapter is IBridgeAdapter {
    constructor(uint256 expectedChainId, string memory expectedChainName) public {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        // Allow testing on Ganache
        if (chainId != expectedChainId && chainId != 1337) {
            revert(string(abi.encodePacked(expectedChainName, "BridgeAdapter.constructor: wrong chain ID")));
        }
    }

    function isSupportedSource(bytes32 source) external override returns (bool isSupported) {
        BridgeOrder memory placeholderOrder;
        placeholderOrder.source = source;
        IERC20TokenV06 placeholderToken = IERC20TokenV06(address(0));

        (, isSupported) = _trade(placeholderOrder, placeholderToken, placeholderToken, 0, true);
    }

    function trade(
        BridgeOrder memory order,
        IERC20TokenV06 sellToken,
        IERC20TokenV06 buyToken,
        uint256 sellAmount
    ) public override returns (uint256 boughtAmount) {
        (boughtAmount, ) = _trade(order, sellToken, buyToken, sellAmount, false);
    }

    function _trade(
        BridgeOrder memory order,
        IERC20TokenV06 sellToken,
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bool dryRun
    ) internal virtual returns (uint256 boughtAmount, bool supportedSource);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./AbstractBridgeAdapter.sol";
import "./BridgeProtocols.sol";
import "./mixins/MixinAaveV3.sol";
import "./mixins/MixinBalancerV2Batch.sol";
import "./mixins/MixinCurve.sol";
import "./mixins/MixinCurveV2.sol";
import "./mixins/MixinDodoV2.sol";
import "./mixins/MixinKyberDmm.sol";
import "./mixins/MixinGMX.sol";
import "./mixins/MixinNerve.sol";
import "./mixins/MixinUniswapV3.sol";
import "./mixins/MixinUniswapV2.sol";
import "./mixins/MixinWOOFi.sol";
import "./mixins/MixinZeroExBridge.sol";

contract ArbitrumBridgeAdapter is
    AbstractBridgeAdapter(42161, "Arbitrum"),
    MixinAaveV3,
    MixinBalancerV2Batch,
    MixinCurve,
    MixinCurveV2,
    MixinDodoV2,
    MixinKyberDmm,
    MixinGMX,
    MixinNerve,
    MixinUniswapV3,
    MixinUniswapV2,
    MixinWOOFi,
    MixinZeroExBridge
{
    constructor(IEtherTokenV06 weth) public MixinCurve(weth) MixinAaveV3(true) {}

    function _trade(
        BridgeOrder memory order,
        IERC20TokenV06 sellToken,
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bool dryRun
    ) internal override returns (uint256 boughtAmount, bool supportedSource) {
        uint128 protocolId = uint128(uint256(order.source) >> 128);
        if (protocolId == BridgeProtocols.BALANCERV2BATCH) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeBalancerV2Batch(sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.CURVE) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeCurve(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.CURVEV2) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeCurveV2(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.DODOV2) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeDodoV2(sellToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.KYBERDMM) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeKyberDmm(buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.UNISWAPV3) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeUniswapV3(sellToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.UNISWAPV2) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeUniswapV2(buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.GMX) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeGMX(buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.NERVE) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeNerve(sellToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.UNKNOWN) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeZeroExBridge(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.AAVEV3) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeAaveV3(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.WOOFI) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeWOOFi(sellToken, buyToken, sellAmount, order.bridgeData);
        }

        emit BridgeFill(order.source, sellToken, buyToken, sellAmount, boughtAmount);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./AbstractBridgeAdapter.sol";
import "./BridgeProtocols.sol";
import "./mixins/MixinAaveV3.sol";
import "./mixins/MixinCurve.sol";
import "./mixins/MixinCurveV2.sol";
import "./mixins/MixinGMX.sol";
import "./mixins/MixinKyberDmm.sol";
import "./mixins/MixinAaveV2.sol";
import "./mixins/MixinNerve.sol";
import "./mixins/MixinPlatypus.sol";
import "./mixins/MixinUniswapV2.sol";
import "./mixins/MixinWOOFi.sol";
import "./mixins/MixinZeroExBridge.sol";

contract AvalancheBridgeAdapter is
    AbstractBridgeAdapter(43114, "Avalanche"),
    MixinAaveV3,
    MixinCurve,
    MixinCurveV2,
    MixinGMX,
    MixinKyberDmm,
    MixinAaveV2,
    MixinNerve,
    MixinPlatypus,
    MixinUniswapV2,
    MixinWOOFi,
    MixinZeroExBridge
{
    constructor(IEtherTokenV06 weth) public MixinCurve(weth) MixinAaveV3(false) {}

    function _trade(
        BridgeOrder memory order,
        IERC20TokenV06 sellToken,
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bool dryRun
    ) internal override returns (uint256 boughtAmount, bool supportedSource) {
        uint128 protocolId = uint128(uint256(order.source) >> 128);
        if (protocolId == BridgeProtocols.CURVE) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeCurve(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.CURVEV2) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeCurveV2(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.UNISWAPV2) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeUniswapV2(buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.NERVE) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeNerve(sellToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.KYBERDMM) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeKyberDmm(buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.AAVEV2) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeAaveV2(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.GMX) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeGMX(buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.PLATYPUS) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradePlatypus(buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.WOOFI) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeWOOFi(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.UNKNOWN) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeZeroExBridge(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.AAVEV3) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeAaveV3(sellToken, buyToken, sellAmount, order.bridgeData);
        }

        emit BridgeFill(order.source, sellToken, buyToken, sellAmount, boughtAmount);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";

library BridgeProtocols {
    // A incrementally increasing, append-only list of protocol IDs.
    // We don't use an enum so solidity doesn't throw when we pass in a
    // new protocol ID that hasn't been rolled up yet.
    uint128 internal constant UNKNOWN = 0;
    uint128 internal constant CURVE = 1;
    uint128 internal constant UNISWAPV2 = 2;
    uint128 internal constant UNISWAP = 3;
    uint128 internal constant BALANCER = 4;
    uint128 internal constant KYBER = 5; // Not used: deprecated.
    uint128 internal constant MOONISWAP = 6;
    uint128 internal constant MSTABLE = 7;
    uint128 internal constant OASIS = 8; // Not used: deprecated.
    uint128 internal constant SHELL = 9;
    uint128 internal constant DODO = 10;
    uint128 internal constant DODOV2 = 11;
    uint128 internal constant CRYPTOCOM = 12;
    uint128 internal constant BANCOR = 13;
    uint128 internal constant COFIX = 14; // Not used: deprecated.
    uint128 internal constant NERVE = 15;
    uint128 internal constant MAKERPSM = 16;
    uint128 internal constant BALANCERV2 = 17;
    uint128 internal constant UNISWAPV3 = 18;
    uint128 internal constant KYBERDMM = 19;
    uint128 internal constant CURVEV2 = 20;
    uint128 internal constant LIDO = 21;
    uint128 internal constant CLIPPER = 22; // Not used: Clipper is now using PLP interface
    uint128 internal constant AAVEV2 = 23;
    uint128 internal constant COMPOUND = 24;
    uint128 internal constant BALANCERV2BATCH = 25;
    uint128 internal constant GMX = 26;
    uint128 internal constant PLATYPUS = 27;
    uint128 internal constant BANCORV3 = 28;
    uint128 internal constant SOLIDLY = 29;
    uint128 internal constant SYNTHETIX = 30;
    uint128 internal constant WOOFI = 31;
    uint128 internal constant AAVEV3 = 32;
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./AbstractBridgeAdapter.sol";
import "./BridgeProtocols.sol";
import "./mixins/MixinCurve.sol";
import "./mixins/MixinDodo.sol";
import "./mixins/MixinDodoV2.sol";
import "./mixins/MixinKyberDmm.sol";
import "./mixins/MixinMooniswap.sol";
import "./mixins/MixinNerve.sol";
import "./mixins/MixinUniswapV2.sol";
import "./mixins/MixinWOOFi.sol";
import "./mixins/MixinZeroExBridge.sol";

contract BSCBridgeAdapter is
    AbstractBridgeAdapter(56, "BSC"),
    MixinCurve,
    MixinDodo,
    MixinDodoV2,
    MixinKyberDmm,
    MixinMooniswap,
    MixinNerve,
    MixinUniswapV2,
    MixinWOOFi,
    MixinZeroExBridge
{
    constructor(IEtherTokenV06 weth) public MixinCurve(weth) MixinMooniswap(weth) {}

    function _trade(
        BridgeOrder memory order,
        IERC20TokenV06 sellToken,
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bool dryRun
    ) internal override returns (uint256 boughtAmount, bool supportedSource) {
        uint128 protocolId = uint128(uint256(order.source) >> 128);
        if (protocolId == BridgeProtocols.CURVE) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeCurve(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.UNISWAPV2) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeUniswapV2(buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.MOONISWAP) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeMooniswap(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.DODO) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeDodo(sellToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.DODOV2) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeDodoV2(sellToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.NERVE) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeNerve(sellToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.KYBERDMM) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeKyberDmm(buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.WOOFI) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeWOOFi(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.UNKNOWN) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeZeroExBridge(sellToken, buyToken, sellAmount, order.bridgeData);
        }

        emit BridgeFill(order.source, sellToken, buyToken, sellAmount, boughtAmount);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./AbstractBridgeAdapter.sol";
import "./BridgeProtocols.sol";
import "./mixins/MixinNerve.sol";
import "./mixins/MixinUniswapV2.sol";
import "./mixins/MixinZeroExBridge.sol";

contract CeloBridgeAdapter is AbstractBridgeAdapter(42220, "Celo"), MixinNerve, MixinUniswapV2, MixinZeroExBridge {
    constructor(address _weth) public {}

    function _trade(
        BridgeOrder memory order,
        IERC20TokenV06 sellToken,
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bool dryRun
    ) internal override returns (uint256 boughtAmount, bool supportedSource) {
        uint128 protocolId = uint128(uint256(order.source) >> 128);
        if (protocolId == BridgeProtocols.UNISWAPV2) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeUniswapV2(buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.NERVE) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeNerve(sellToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.UNKNOWN) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeZeroExBridge(sellToken, buyToken, sellAmount, order.bridgeData);
        }

        emit BridgeFill(order.source, sellToken, buyToken, sellAmount, boughtAmount);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./AbstractBridgeAdapter.sol";
import "./BridgeProtocols.sol";
import "./mixins/MixinAaveV2.sol";
import "./mixins/MixinBalancer.sol";
import "./mixins/MixinBalancerV2Batch.sol";
import "./mixins/MixinBancor.sol";
import "./mixins/MixinBancorV3.sol";
import "./mixins/MixinCompound.sol";
import "./mixins/MixinCurve.sol";
import "./mixins/MixinCurveV2.sol";
import "./mixins/MixinCryptoCom.sol";
import "./mixins/MixinDodo.sol";
import "./mixins/MixinDodoV2.sol";
import "./mixins/MixinKyberDmm.sol";
import "./mixins/MixinLido.sol";
import "./mixins/MixinMakerPSM.sol";
import "./mixins/MixinMStable.sol";
import "./mixins/MixinNerve.sol";
import "./mixins/MixinShell.sol";
import "./mixins/MixinSynthetix.sol";
import "./mixins/MixinUniswap.sol";
import "./mixins/MixinUniswapV2.sol";
import "./mixins/MixinUniswapV3.sol";
import "./mixins/MixinZeroExBridge.sol";

contract EthereumBridgeAdapter is
    AbstractBridgeAdapter(1, "Ethereum"),
    MixinAaveV2,
    MixinBalancer,
    MixinBalancerV2Batch,
    MixinBancor,
    MixinBancorV3,
    MixinCompound,
    MixinCurve,
    MixinCurveV2,
    MixinCryptoCom,
    MixinDodo,
    MixinDodoV2,
    MixinKyberDmm,
    MixinLido,
    MixinMakerPSM,
    MixinMStable,
    MixinNerve,
    MixinShell,
    MixinSynthetix,
    MixinUniswap,
    MixinUniswapV2,
    MixinUniswapV3,
    MixinZeroExBridge
{
    constructor(
        IEtherTokenV06 weth
    )
        public
        MixinBancor(weth)
        MixinBancorV3(weth)
        MixinCompound(weth)
        MixinCurve(weth)
        MixinLido(weth)
        MixinUniswap(weth)
    {}

    function _trade(
        BridgeOrder memory order,
        IERC20TokenV06 sellToken,
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bool dryRun
    ) internal override returns (uint256 boughtAmount, bool supportedSource) {
        uint128 protocolId = uint128(uint256(order.source) >> 128);
        if (protocolId == BridgeProtocols.CURVE) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeCurve(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.CURVEV2) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeCurveV2(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.UNISWAPV3) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeUniswapV3(sellToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.UNISWAPV2) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeUniswapV2(buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.UNISWAP) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeUniswap(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.BALANCER) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeBalancer(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.BALANCERV2BATCH) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeBalancerV2Batch(sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.MAKERPSM) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeMakerPsm(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.MSTABLE) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeMStable(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.SHELL) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeShell(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.DODO) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeDodo(sellToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.DODOV2) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeDodoV2(sellToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.CRYPTOCOM) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeCryptoCom(buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.BANCOR) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeBancor(buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.NERVE) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeNerve(sellToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.KYBERDMM) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeKyberDmm(buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.LIDO) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeLido(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.AAVEV2) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeAaveV2(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.COMPOUND) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeCompound(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.BANCORV3) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeBancorV3(buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.SYNTHETIX) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeSynthetix(sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.UNKNOWN) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeZeroExBridge(sellToken, buyToken, sellAmount, order.bridgeData);
        }

        emit BridgeFill(order.source, sellToken, buyToken, sellAmount, boughtAmount);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./AbstractBridgeAdapter.sol";
import "./BridgeProtocols.sol";
import "./mixins/MixinBalancerV2Batch.sol";
import "./mixins/MixinCurve.sol";
import "./mixins/MixinCurveV2.sol";
import "./mixins/MixinNerve.sol";
import "./mixins/MixinUniswapV2.sol";
import "./mixins/MixinWOOFi.sol";
import "./mixins/MixinZeroExBridge.sol";

contract FantomBridgeAdapter is
    AbstractBridgeAdapter(250, "Fantom"),
    MixinBalancerV2Batch,
    MixinCurve,
    MixinCurveV2,
    MixinNerve,
    MixinUniswapV2,
    MixinWOOFi,
    MixinZeroExBridge
{
    constructor(IEtherTokenV06 weth) public MixinCurve(weth) {}

    function _trade(
        BridgeOrder memory order,
        IERC20TokenV06 sellToken,
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bool dryRun
    ) internal override returns (uint256 boughtAmount, bool supportedSource) {
        uint128 protocolId = uint128(uint256(order.source) >> 128);
        if (protocolId == BridgeProtocols.CURVE) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeCurve(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.CURVEV2) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeCurveV2(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.UNISWAPV2) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeUniswapV2(buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.BALANCERV2BATCH) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeBalancerV2Batch(sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.NERVE) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeNerve(sellToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.WOOFI) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeWOOFi(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.UNKNOWN) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeZeroExBridge(sellToken, buyToken, sellAmount, order.bridgeData);
        }

        emit BridgeFill(order.source, sellToken, buyToken, sellAmount, boughtAmount);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";

interface IBridgeAdapter {
    struct BridgeOrder {
        // Upper 16 bytes: uint128 protocol ID (right-aligned)
        // Lower 16 bytes: ASCII source name (left-aligned)
        bytes32 source;
        uint256 takerTokenAmount;
        uint256 makerTokenAmount;
        bytes bridgeData;
    }

    /// @dev Emitted when tokens are swapped with an external source.
    /// @param source A unique ID for the source, where the upper 16 bytes
    ///        encodes the (right-aligned) uint128 protocol ID and the
    ///        lower 16 bytes encodes an ASCII source name.
    /// @param inputToken The token the bridge is converting from.
    /// @param outputToken The token the bridge is converting to.
    /// @param inputTokenAmount Amount of input token sold.
    /// @param outputTokenAmount Amount of output token bought.
    event BridgeFill(
        bytes32 source,
        IERC20TokenV06 inputToken,
        IERC20TokenV06 outputToken,
        uint256 inputTokenAmount,
        uint256 outputTokenAmount
    );

    function isSupportedSource(bytes32 source) external returns (bool isSupported);

    function trade(
        BridgeOrder calldata order,
        IERC20TokenV06 sellToken,
        IERC20TokenV06 buyToken,
        uint256 sellAmount
    ) external returns (uint256 boughtAmount);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";

// Minimal Aave V2 LendingPool interface
interface ILendingPool {
    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}

contract MixinAaveV2 {
    using LibERC20TokenV06 for IERC20TokenV06;

    function _tradeAaveV2(
        IERC20TokenV06 sellToken,
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) internal returns (uint256) {
        (ILendingPool lendingPool, address aToken) = abi.decode(bridgeData, (ILendingPool, address));

        sellToken.approveIfBelow(address(lendingPool), sellAmount);

        if (address(buyToken) == aToken) {
            lendingPool.deposit(address(sellToken), sellAmount, address(this), 0);
            // 1:1 mapping token -> aToken and have the same number of decimals as the underlying token
            return sellAmount;
        } else if (address(sellToken) == aToken) {
            return lendingPool.withdraw(address(buyToken), sellAmount, address(this));
        }

        revert("MixinAaveV2/UNSUPPORTED_TOKEN_PAIR");
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";

// Minimal Aave V3 Pool interface
interface IPool {
    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    /**
     * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to The address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}

// Minimal Aave V3 L2Pool interface
interface IL2Pool {
    /**
     * @notice Calldata efficient wrapper of the supply function on behalf of the caller
     * @param args Arguments for the supply function packed in one bytes32
     *    96 bits       16 bits         128 bits      16 bits
     * | 0-padding | referralCode | shortenedAmount | assetId |
     * @dev the shortenedAmount is cast to 256 bits at decode time, if type(uint128).max the value will be expanded to
     * type(uint256).max
     * @dev assetId is the index of the asset in the reservesList.
     */
    function supply(bytes32 args) external;

    /**
     * @notice Calldata efficient wrapper of the withdraw function, withdrawing to the caller
     * @param args Arguments for the withdraw function packed in one bytes32
     *    112 bits       128 bits      16 bits
     * | 0-padding | shortenedAmount | assetId |
     * @dev the shortenedAmount is cast to 256 bits at decode time, if type(uint128).max the value will be expanded to
     * type(uint256).max
     * @dev assetId is the index of the asset in the reservesList.
     */
    function withdraw(bytes32 args) external;
}

contract MixinAaveV3 {
    using LibERC20TokenV06 for IERC20TokenV06;

    bool private immutable _isL2;

    constructor(bool isL2) public {
        _isL2 = isL2;
    }

    function _tradeAaveV3(
        IERC20TokenV06 sellToken,
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) internal returns (uint256) {
        if (_isL2) {
            (IL2Pool pool, address aToken, bytes32 l2Params) = abi.decode(bridgeData, (IL2Pool, address, bytes32));

            sellToken.approveIfBelow(address(pool), sellAmount);

            if (address(buyToken) == aToken) {
                pool.supply(l2Params);
                // 1:1 mapping token --> aToken and have the same number of decimals as the underlying token
                return sellAmount;
            } else if (address(sellToken) == aToken) {
                pool.withdraw(l2Params);
                return sellAmount;
            }

            revert("MixinAaveV3/UNSUPPORTED_TOKEN_PAIR");
        }
        (IPool pool, address aToken, ) = abi.decode(bridgeData, (IPool, address, bytes32));

        sellToken.approveIfBelow(address(pool), sellAmount);

        if (address(buyToken) == aToken) {
            pool.supply(address(sellToken), sellAmount, address(this), 0);
            // 1:1 mapping token -> aToken and have the same number of decimals as the underlying token
            return sellAmount;
        } else if (address(sellToken) == aToken) {
            return pool.withdraw(address(buyToken), sellAmount, address(this));
        }

        revert("MixinAaveV3/UNSUPPORTED_TOKEN_PAIR");
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;

import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";

interface IBalancerPool {
    /// @dev Sell `tokenAmountIn` of `tokenIn` and receive `tokenOut`.
    /// @param tokenIn The token being sold
    /// @param tokenAmountIn The amount of `tokenIn` to sell.
    /// @param tokenOut The token being bought.
    /// @param minAmountOut The minimum amount of `tokenOut` to buy.
    /// @param maxPrice The maximum value for `spotPriceAfter`.
    /// @return tokenAmountOut The amount of `tokenOut` bought.
    /// @return spotPriceAfter The new marginal spot price of the given
    ///         token pair for this pool.
    function swapExactAmountIn(
        IERC20TokenV06 tokenIn,
        uint256 tokenAmountIn,
        IERC20TokenV06 tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);
}

contract MixinBalancer {
    using LibERC20TokenV06 for IERC20TokenV06;

    function _tradeBalancer(
        IERC20TokenV06 sellToken,
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) internal returns (uint256 boughtAmount) {
        // Decode the bridge data.
        IBalancerPool pool = abi.decode(bridgeData, (IBalancerPool));
        sellToken.approveIfBelow(address(pool), sellAmount);
        // Sell all of this contract's `sellToken` token balance.
        (boughtAmount, ) = pool.swapExactAmountIn(
            sellToken, // tokenIn
            sellAmount, // tokenAmountIn
            buyToken, // tokenOut
            1, // minAmountOut
            uint256(-1) // maxPrice
        );
        return boughtAmount;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";

interface IBalancerV2BatchSwapVault {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] calldata swaps,
        IERC20TokenV06[] calldata assets,
        FundManagement calldata funds,
        int256[] calldata limits,
        uint256 deadline
    ) external returns (int256[] memory amounts);
}

contract MixinBalancerV2Batch {
    using LibERC20TokenV06 for IERC20TokenV06;

    struct BalancerV2BatchBridgeData {
        IBalancerV2BatchSwapVault vault;
        IBalancerV2BatchSwapVault.BatchSwapStep[] swapSteps;
        IERC20TokenV06[] assets;
    }

    function _tradeBalancerV2Batch(
        uint256 sellAmount,
        bytes memory bridgeData
    ) internal returns (uint256 boughtAmount) {
        // Decode the bridge data.
        (
            IBalancerV2BatchSwapVault vault,
            IBalancerV2BatchSwapVault.BatchSwapStep[] memory swapSteps,
            address[] memory assets_
        ) = abi.decode(bridgeData, (IBalancerV2BatchSwapVault, IBalancerV2BatchSwapVault.BatchSwapStep[], address[]));
        IERC20TokenV06[] memory assets;
        assembly {
            assets := assets_
        }

        // Grant an allowance to the exchange to spend `fromTokenAddress` token.
        assets[0].approveIfBelow(address(vault), sellAmount);

        swapSteps[0].amount = sellAmount;
        int256[] memory limits = new int256[](assets.length);
        for (uint256 i = 0; i < limits.length; ++i) {
            limits[i] = type(int256).max;
        }

        int256[] memory amounts = vault.batchSwap(
            IBalancerV2BatchSwapVault.SwapKind.GIVEN_IN,
            swapSteps,
            assets,
            IBalancerV2BatchSwapVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: payable(address(this)),
                toInternalBalance: false
            }),
            limits,
            block.timestamp + 1
        );
        require(amounts[amounts.length - 1] <= 0, "Unexpected BalancerV2Batch output");
        return uint256(amounts[amounts.length - 1] * -1);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IEtherTokenV06.sol";
import "../IBridgeAdapter.sol";

interface IBancorNetwork {
    function convertByPath(
        IERC20TokenV06[] calldata _path,
        uint256 _amount,
        uint256 _minReturn,
        address _beneficiary,
        address _affiliateAccount,
        uint256 _affiliateFee
    ) external payable returns (uint256);
}

contract MixinBancor {
    /// @dev Bancor ETH pseudo-address.
    IERC20TokenV06 public constant BANCOR_ETH_ADDRESS = IERC20TokenV06(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    IEtherTokenV06 private immutable WETH;

    constructor(IEtherTokenV06 weth) public {
        WETH = weth;
    }

    function _tradeBancor(
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) internal returns (uint256 boughtAmount) {
        // Decode the bridge data.
        IBancorNetwork bancorNetworkAddress;
        IERC20TokenV06[] memory path;
        {
            address[] memory _path;
            (bancorNetworkAddress, _path) = abi.decode(bridgeData, (IBancorNetwork, address[]));
            // To get around `abi.decode()` not supporting interface array types.
            assembly {
                path := _path
            }
        }

        require(path.length >= 2, "MixinBancor/PATH_LENGTH_MUST_BE_AT_LEAST_TWO");
        require(
            path[path.length - 1] == buyToken || (path[path.length - 1] == BANCOR_ETH_ADDRESS && buyToken == WETH),
            "MixinBancor/LAST_ELEMENT_OF_PATH_MUST_MATCH_OUTPUT_TOKEN"
        );

        uint256 payableAmount = 0;
        // If it's ETH in the path then withdraw from WETH
        // The Bancor path will have ETH as the 0xeee address
        // Bancor expects to be paid in ETH not WETH
        if (path[0] == BANCOR_ETH_ADDRESS) {
            WETH.withdraw(sellAmount);
            payableAmount = sellAmount;
        } else {
            // Grant an allowance to the Bancor Network.
            LibERC20TokenV06.approveIfBelow(path[0], address(bancorNetworkAddress), sellAmount);
        }

        // Convert the tokens
        boughtAmount = bancorNetworkAddress.convertByPath{value: payableAmount}(
            path, // path originating with source token and terminating in destination token
            sellAmount, // amount of source token to trade
            1, // minimum amount of destination token expected to receive
            address(this), // beneficiary
            address(0), // affiliateAccount; no fee paid
            0 // affiliateFee; no fee paid
        );
        if (path[path.length - 1] == BANCOR_ETH_ADDRESS) {
            WETH.deposit{value: boughtAmount}();
        }

        return boughtAmount;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IEtherTokenV06.sol";

/*
    BancorV3
*/
interface IBancorV3 {
    /**
     * @dev performs a trade by providing the source amount and returns the target amount and the associated fee
     *
     * requirements:
     *
     * - the caller must be the network contract
     */
    function tradeBySourceAmount(
        address sourceToken,
        address targetToken,
        uint256 sourceAmount,
        uint256 minReturnAmount,
        uint256 deadline,
        address beneficiary
    ) external payable returns (uint256 amount);
}

contract MixinBancorV3 {
    using LibERC20TokenV06 for IERC20TokenV06;

    IERC20TokenV06 public constant BANCORV3_ETH_ADDRESS = IERC20TokenV06(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    IEtherTokenV06 private immutable WETH;

    constructor(IEtherTokenV06 weth) public {
        WETH = weth;
    }

    function _tradeBancorV3(
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) internal returns (uint256 amountOut) {
        IBancorV3 router;
        IERC20TokenV06[] memory path;
        address[] memory _path;
        uint256 payableAmount = 0;

        {
            (router, _path) = abi.decode(bridgeData, (IBancorV3, address[]));
            // To get around `abi.decode()` not supporting interface array types.
            assembly {
                path := _path
            }
        }

        require(path.length >= 2, "MixinBancorV3/PATH_LENGTH_MUST_BE_AT_LEAST_TWO");
        require(path[path.length - 1] == buyToken, "MixinBancorV3/LAST_ELEMENT_OF_PATH_MUST_MATCH_OUTPUT_TOKEN");

        //swap WETH->ETH as Bancor only deals in ETH
        if (_path[0] == address(WETH)) {
            //withdraw the sell amount of WETH for ETH
            WETH.withdraw(sellAmount);
            payableAmount = sellAmount;
            // set _path[0] to the ETH address if WETH is our buy token
            _path[0] = address(BANCORV3_ETH_ADDRESS);
        } else {
            // Grant the BancorV3 router an allowance to sell the first token.
            path[0].approveIfBelow(address(router), sellAmount);
        }

        // if we are buying WETH we need to swap to ETH and deposit into WETH after the swap
        if (_path[1] == address(WETH)) {
            _path[1] = address(BANCORV3_ETH_ADDRESS);
        }

        uint256 amountOut = router.tradeBySourceAmount{value: payableAmount}(
            _path[0],
            _path[1],
            // Sell all tokens we hold.
            sellAmount,
            // Minimum buy amount.
            1,
            //deadline
            block.timestamp + 1,
            // address of the mixin
            address(this)
        );

        // if we want to return WETH deposit the ETH amount we sold
        if (buyToken == WETH) {
            WETH.deposit{value: amountOut}();
        }

        return amountOut;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IEtherTokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";

/// @dev Minimal CToken interface
interface ICToken {
    /// @dev deposits specified amount underlying tokens and mints cToken for the sender
    /// @param mintAmountInUnderlying amount of underlying tokens to deposit to mint cTokens
    /// @return status code of whether the mint was successful or not
    function mint(uint256 mintAmountInUnderlying) external returns (uint256);

    /// @dev redeems specified amount of cTokens and returns the underlying token to the sender
    /// @param redeemTokensInCtokens amount of cTokens to redeem for underlying collateral
    /// @return status code of whether the redemption was successful or not
    function redeem(uint256 redeemTokensInCtokens) external returns (uint256);
}

/// @dev Minimal CEther interface
interface ICEther {
    /// @dev deposits the amount of Ether sent as value and return mints cEther for the sender
    function mint() external payable;

    /// @dev redeems specified amount of cETH and returns the underlying ether to the sender
    /// @dev redeemTokensInCEther amount of cETH to redeem for underlying ether
    /// @return status code of whether the redemption was successful or not
    function redeem(uint256 redeemTokensInCEther) external returns (uint256);
}

contract MixinCompound {
    using LibERC20TokenV06 for IERC20TokenV06;
    using LibSafeMathV06 for uint256;

    IEtherTokenV06 private immutable WETH;

    constructor(IEtherTokenV06 weth) public {
        WETH = weth;
    }

    uint256 private constant COMPOUND_SUCCESS_CODE = 0;

    function _tradeCompound(
        IERC20TokenV06 sellToken,
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) internal returns (uint256) {
        address cTokenAddress = abi.decode(bridgeData, (address));
        uint256 beforeBalance = buyToken.balanceOf(address(this));

        if (address(buyToken) == cTokenAddress) {
            if (address(sellToken) == address(WETH)) {
                // ETH/WETH -> cETH
                ICEther cETH = ICEther(cTokenAddress);
                // Compound expects ETH to be sent with mint call
                WETH.withdraw(sellAmount);
                // NOTE: cETH mint will revert on failure instead of returning a status code
                cETH.mint{value: sellAmount}();
            } else {
                sellToken.approveIfBelow(cTokenAddress, sellAmount);
                // Token -> cToken
                ICToken cToken = ICToken(cTokenAddress);
                require(cToken.mint(sellAmount) == COMPOUND_SUCCESS_CODE, "MixinCompound/FAILED_TO_MINT_CTOKEN");
            }
        } else if (address(sellToken) == cTokenAddress) {
            if (address(buyToken) == address(WETH)) {
                // cETH -> ETH/WETH
                uint256 etherBalanceBefore = address(this).balance;
                ICEther cETH = ICEther(cTokenAddress);
                require(cETH.redeem(sellAmount) == COMPOUND_SUCCESS_CODE, "MixinCompound/FAILED_TO_REDEEM_CETHER");
                uint256 etherBalanceAfter = address(this).balance;
                uint256 receivedEtherBalance = etherBalanceAfter.safeSub(etherBalanceBefore);
                WETH.deposit{value: receivedEtherBalance}();
            } else {
                ICToken cToken = ICToken(cTokenAddress);
                require(cToken.redeem(sellAmount) == COMPOUND_SUCCESS_CODE, "MixinCompound/FAILED_TO_REDEEM_CTOKEN");
            }
        }

        return buyToken.balanceOf(address(this)).safeSub(beforeBalance);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "./MixinUniswapV2.sol";

contract MixinCryptoCom {
    using LibERC20TokenV06 for IERC20TokenV06;

    function _tradeCryptoCom(
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) internal returns (uint256 boughtAmount) {
        IUniswapV2Router02 router;
        IERC20TokenV06[] memory path;
        {
            address[] memory _path;
            (router, _path) = abi.decode(bridgeData, (IUniswapV2Router02, address[]));
            // To get around `abi.decode()` not supporting interface array types.
            assembly {
                path := _path
            }
        }

        require(path.length >= 2, "MixinCryptoCom/PATH_LENGTH_MUST_BE_AT_LEAST_TWO");
        require(path[path.length - 1] == buyToken, "MixinCryptoCom/LAST_ELEMENT_OF_PATH_MUST_MATCH_OUTPUT_TOKEN");
        // Grant the CryptoCom router an allowance to sell the first token.
        path[0].approveIfBelow(address(router), sellAmount);

        uint256[] memory amounts = router.swapExactTokensForTokens(
            // Sell all tokens we hold.
            sellAmount,
            // Minimum buy amount.
            1,
            // Convert to `buyToken` along this path.
            path,
            // Recipient is `this`.
            address(this),
            // Expires after this block.
            block.timestamp
        );
        return amounts[amounts.length - 1];
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IEtherTokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";

contract MixinCurve {
    using LibERC20TokenV06 for IERC20TokenV06;
    using LibSafeMathV06 for uint256;
    using LibRichErrorsV06 for bytes;

    /// @dev Mainnet address of the WETH contract.
    IEtherTokenV06 private immutable WETH;

    constructor(IEtherTokenV06 weth) public {
        WETH = weth;
    }

    struct CurveBridgeData {
        address curveAddress;
        bytes4 exchangeFunctionSelector;
        int128 fromCoinIdx;
        int128 toCoinIdx;
    }

    function _tradeCurve(
        IERC20TokenV06 sellToken,
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) internal returns (uint256 boughtAmount) {
        // Decode the bridge data to get the Curve metadata.
        CurveBridgeData memory data = abi.decode(bridgeData, (CurveBridgeData));
        uint256 payableAmount;
        if (sellToken == WETH) {
            payableAmount = sellAmount;
            WETH.withdraw(sellAmount);
        } else {
            sellToken.approveIfBelow(data.curveAddress, sellAmount);
        }

        uint256 beforeBalance = buyToken.balanceOf(address(this));
        (bool success, bytes memory resultData) = data.curveAddress.call{value: payableAmount}(
            abi.encodeWithSelector(
                data.exchangeFunctionSelector,
                data.fromCoinIdx,
                data.toCoinIdx,
                // dx
                sellAmount,
                // min dy
                1
            )
        );
        if (!success) {
            resultData.rrevert();
        }

        if (buyToken == WETH) {
            boughtAmount = address(this).balance;
            WETH.deposit{value: boughtAmount}();
        }

        return buyToken.balanceOf(address(this)).safeSub(beforeBalance);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";

contract MixinCurveV2 {
    using LibERC20TokenV06 for IERC20TokenV06;
    using LibSafeMathV06 for uint256;
    using LibRichErrorsV06 for bytes;

    struct CurveBridgeDataV2 {
        address curveAddress;
        bytes4 exchangeFunctionSelector;
        int128 fromCoinIdx;
        int128 toCoinIdx;
    }

    function _tradeCurveV2(
        IERC20TokenV06 sellToken,
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) internal returns (uint256 boughtAmount) {
        // Decode the bridge data to get the Curve metadata.
        CurveBridgeDataV2 memory data = abi.decode(bridgeData, (CurveBridgeDataV2));
        sellToken.approveIfBelow(data.curveAddress, sellAmount);

        uint256 beforeBalance = buyToken.balanceOf(address(this));
        (bool success, bytes memory resultData) = data.curveAddress.call(
            abi.encodeWithSelector(
                data.exchangeFunctionSelector,
                data.fromCoinIdx,
                data.toCoinIdx,
                // dx
                sellAmount,
                // min dy
                1
            )
        );
        if (!success) {
            resultData.rrevert();
        }

        return buyToken.balanceOf(address(this)).safeSub(beforeBalance);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "../IBridgeAdapter.sol";

interface IDODO {
    function sellBaseToken(uint256 amount, uint256 minReceiveQuote, bytes calldata data) external returns (uint256);

    function buyBaseToken(uint256 amount, uint256 maxPayQuote, bytes calldata data) external returns (uint256);
}

interface IDODOHelper {
    function querySellQuoteToken(IDODO dodo, uint256 amount) external view returns (uint256);
}

contract MixinDodo {
    using LibERC20TokenV06 for IERC20TokenV06;

    function _tradeDodo(
        IERC20TokenV06 sellToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) internal returns (uint256 boughtAmount) {
        (IDODOHelper helper, IDODO pool, bool isSellBase) = abi.decode(bridgeData, (IDODOHelper, IDODO, bool));

        // Grant the Dodo pool contract an allowance to sell the first token.
        sellToken.approveIfBelow(address(pool), sellAmount);

        if (isSellBase) {
            // Sell the Base token directly against the contract
            boughtAmount = pool.sellBaseToken(
                // amount to sell
                sellAmount,
                // min receive amount
                1,
                new bytes(0)
            );
        } else {
            // Need to re-calculate the sell quote amount into buyBase
            boughtAmount = helper.querySellQuoteToken(pool, sellAmount);
            pool.buyBaseToken(
                // amount to buy
                boughtAmount,
                // max pay amount
                sellAmount,
                new bytes(0)
            );
        }

        return boughtAmount;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "../IBridgeAdapter.sol";

interface IDODOV2 {
    function sellBase(address recipient) external returns (uint256);

    function sellQuote(address recipient) external returns (uint256);
}

contract MixinDodoV2 {
    using LibERC20TokenV06 for IERC20TokenV06;

    function _tradeDodoV2(
        IERC20TokenV06 sellToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) internal returns (uint256 boughtAmount) {
        (IDODOV2 pool, bool isSellBase) = abi.decode(bridgeData, (IDODOV2, bool));

        // Transfer the tokens into the pool
        sellToken.compatTransfer(address(pool), sellAmount);

        boughtAmount = isSellBase ? pool.sellBase(address(this)) : pool.sellQuote(address(this));
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../IBridgeAdapter.sol";

/*
    UniswapV2
*/
interface IGmxRouter {
    /// @dev Swaps an exact amount of input tokens for as many output tokens as possible, along the route determined by
    /// the path. The first element of path is the input token, the last is the output token, and any intermediate
    /// elements represent intermediate pairs to trade through (if, for example, a direct pair does not exist).
    /// @param _path An array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses
    /// must exist and have liquidity.
    /// @param _amountIn The amount of input tokens to send.
    /// @param _minOut The minimum amount of output tokens that must be received for the transaction not to revert.
    /// @param _receiver Recipient of the output tokens.
    function swap(address[] calldata _path, uint256 _amountIn, uint256 _minOut, address _receiver) external;
}

contract MixinGMX {
    using LibERC20TokenV06 for IERC20TokenV06;
    using LibSafeMathV06 for uint256;

    function _tradeGMX(
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) public returns (uint256 boughtAmount) {
        address _router;
        address reader;
        address vault;
        address[] memory _path;
        IGmxRouter router;
        IERC20TokenV06[] memory path;

        {
            //decode the bridge data
            (_router, reader, vault, _path) = abi.decode(bridgeData, (address, address, address, address[]));
            // To get around `abi.decode()` not supporting interface array types.
            assembly {
                path := _path
            }
        }

        require(path.length >= 2, "MixinGMX/PATH_LENGTH_MUST_BE_AT_LEAST_TWO");
        require(path[path.length - 1] == buyToken, "MixinGMX/LAST_ELEMENT_OF_PATH_MUST_MATCH_OUTPUT_TOKEN");

        //connect to the GMX router
        router = IGmxRouter(_router);

        // Grant the GMX router an allowance to sell the first token.
        path[0].approveIfBelow(address(router), sellAmount);

        //track the balance to know how much we bought
        uint256 beforeBalance = buyToken.balanceOf(address(this));
        router.swap(
            // Convert to `buyToken` along this path.
            _path,
            // Sell all tokens we hold.
            sellAmount,
            // Minimum buy amount.
            0,
            // Recipient is `this`.
            address(this)
        );

        //calculate the difference in balance from preswap->postswap to find how many tokens out
        boughtAmount = buyToken.balanceOf(address(this)).safeSub(beforeBalance);

        return boughtAmount;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2021 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "../IBridgeAdapter.sol";

/*
    KyberDmm Router
*/
interface IKyberDmmRouter {
    /// @dev Swaps an exact amount of input tokens for as many output tokens as possible, along the route determined by
    /// the path. The first element of path is the input token, the last is the output token, and any intermediate
    /// elements represent intermediate pairs to trade through (if, for example, a direct pair does not exist).
    /// @param amountIn The amount of input tokens to send.
    /// @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert.
    /// @param pools An array of pool addresses. pools.length must be >= 1.
    /// @param path An array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses
    /// must exist and have liquidity.
    /// @param to Recipient of the output tokens.
    /// @param deadline Unix timestamp after which the transaction will revert.
    /// @return amounts The input token amount and all subsequent output token amounts.
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata pools,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract MixinKyberDmm {
    using LibERC20TokenV06 for IERC20TokenV06;

    function _tradeKyberDmm(
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) internal returns (uint256 boughtAmount) {
        address router;
        address[] memory pools;
        address[] memory path;
        (router, pools, path) = abi.decode(bridgeData, (address, address[], address[]));

        require(pools.length >= 1, "MixinKyberDmm/POOLS_LENGTH_MUST_BE_AT_LEAST_ONE");
        require(path.length == pools.length + 1, "MixinKyberDmm/ARRAY_LENGTH_MISMATCH");
        require(
            path[path.length - 1] == address(buyToken),
            "MixinKyberDmm/LAST_ELEMENT_OF_PATH_MUST_MATCH_OUTPUT_TOKEN"
        );
        // Grant the KyberDmm router an allowance to sell the first token.
        IERC20TokenV06(path[0]).approveIfBelow(address(router), sellAmount);

        uint256[] memory amounts = IKyberDmmRouter(router).swapExactTokensForTokens(
            // Sell all tokens we hold.
            sellAmount,
            // Minimum buy amount.
            1,
            pools,
            // Convert to `buyToken` along this path.
            path,
            // Recipient is `this`.
            address(this),
            // Expires after this block.
            block.timestamp
        );
        return amounts[amounts.length - 1];
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IEtherTokenV06.sol";

/// @dev Minimal interface for minting StETH
interface IStETH {
    /// @dev Adds eth to the pool
    /// @param _referral optional address for referrals
    /// @return StETH Amount of shares generated
    function submit(address _referral) external payable returns (uint256 StETH);

    /// @dev Retrieve the current pooled ETH representation of the shares amount
    /// @param _sharesAmount amount of shares
    /// @return amount of pooled ETH represented by the shares amount
    function getPooledEthByShares(uint256 _sharesAmount) external view returns (uint256);
}

/// @dev Minimal interface for wrapping/unwrapping stETH.
interface IWstETH {
    /**
     * @notice Exchanges stETH to wstETH
     * @param _stETHAmount amount of stETH to wrap in exchange for wstETH
     * @dev Requirements:
     *  - `_stETHAmount` must be non-zero
     *  - msg.sender must approve at least `_stETHAmount` stETH to this
     *    contract.
     *  - msg.sender must have at least `_stETHAmount` of stETH.
     * User should first approve _stETHAmount to the WstETH contract
     * @return Amount of wstETH user receives after wrap
     */
    function wrap(uint256 _stETHAmount) external returns (uint256);

    /**
     * @notice Exchanges wstETH to stETH
     * @param _wstETHAmount amount of wstETH to uwrap in exchange for stETH
     * @dev Requirements:
     *  - `_wstETHAmount` must be non-zero
     *  - msg.sender must have at least `_wstETHAmount` wstETH.
     * @return Amount of stETH user receives after unwrap
     */
    function unwrap(uint256 _wstETHAmount) external returns (uint256);
}

contract MixinLido {
    using LibERC20TokenV06 for IERC20TokenV06;
    using LibERC20TokenV06 for IEtherTokenV06;

    IEtherTokenV06 private immutable WETH;

    constructor(IEtherTokenV06 weth) public {
        WETH = weth;
    }

    function _tradeLido(
        IERC20TokenV06 sellToken,
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) internal returns (uint256 boughtAmount) {
        if (address(sellToken) == address(WETH)) {
            return _tradeStETH(buyToken, sellAmount, bridgeData);
        }

        return _tradeWstETH(sellToken, buyToken, sellAmount, bridgeData);
    }

    function _tradeStETH(
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) private returns (uint256 boughtAmount) {
        IStETH stETH = abi.decode(bridgeData, (IStETH));
        if (address(buyToken) == address(stETH)) {
            WETH.withdraw(sellAmount);
            return stETH.getPooledEthByShares(stETH.submit{value: sellAmount}(address(0)));
        }

        revert("MixinLido/UNSUPPORTED_TOKEN_PAIR");
    }

    function _tradeWstETH(
        IERC20TokenV06 sellToken,
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) private returns (uint256 boughtAmount) {
        (IEtherTokenV06 stETH, IWstETH wstETH) = abi.decode(bridgeData, (IEtherTokenV06, IWstETH));
        if (address(sellToken) == address(stETH) && address(buyToken) == address(wstETH)) {
            sellToken.approveIfBelow(address(wstETH), sellAmount);
            return wstETH.wrap(sellAmount);
        }
        if (address(sellToken) == address(wstETH) && address(buyToken) == address(stETH)) {
            return wstETH.unwrap(sellAmount);
        }

        revert("MixinLido/UNSUPPORTED_TOKEN_PAIR");
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";

interface IPSM {
    // @dev Get the fee for selling USDC to DAI in PSM
    // @return tin toll in [wad]
    function tin() external view returns (uint256);

    // @dev Get the fee for selling DAI to USDC in PSM
    // @return tout toll out [wad]
    function tout() external view returns (uint256);

    // @dev Get the address of the PSM state Vat
    // @return address of the Vat
    function vat() external view returns (address);

    // @dev Get the address of the underlying vault powering PSM
    // @return address of gemJoin contract
    function gemJoin() external view returns (address);

    // @dev Sell USDC for DAI
    // @param usr The address of the account trading USDC for DAI.
    // @param gemAmt The amount of USDC to sell in USDC base units
    function sellGem(address usr, uint256 gemAmt) external;

    // @dev Buy USDC for DAI
    // @param usr The address of the account trading DAI for USDC
    // @param gemAmt The amount of USDC to buy in USDC base units
    function buyGem(address usr, uint256 gemAmt) external;
}

contract MixinMakerPSM {
    using LibERC20TokenV06 for IERC20TokenV06;
    using LibSafeMathV06 for uint256;

    struct MakerPsmBridgeData {
        address psmAddress;
        address gemTokenAddres;
    }

    // Maker units
    // wad: fixed point decimal with 18 decimals (for basic quantities, e.g. balances)
    uint256 private constant WAD = 10 ** 18;
    // ray: fixed point decimal with 27 decimals (for precise quantites, e.g. ratios)
    uint256 private constant RAY = 10 ** 27;
    // rad: fixed point decimal with 45 decimals (result of integer multiplication with a wad and a ray)
    uint256 private constant RAD = 10 ** 45;

    // See https://github.com/makerdao/dss/blob/master/DEVELOPING.md

    function _tradeMakerPsm(
        IERC20TokenV06 sellToken,
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) internal returns (uint256 boughtAmount) {
        // Decode the bridge data.
        MakerPsmBridgeData memory data = abi.decode(bridgeData, (MakerPsmBridgeData));
        uint256 beforeBalance = buyToken.balanceOf(address(this));

        IPSM psm = IPSM(data.psmAddress);

        if (address(sellToken) == data.gemTokenAddres) {
            sellToken.approveIfBelow(psm.gemJoin(), sellAmount);

            psm.sellGem(address(this), sellAmount);
        } else if (address(buyToken) == data.gemTokenAddres) {
            uint256 feeDivisor = WAD.safeAdd(psm.tout()); // eg. 1.001 * 10 ** 18 with 0.1% fee [tout is in wad];
            uint256 buyTokenBaseUnit = uint256(10) ** uint256(buyToken.decimals());
            uint256 gemAmount = sellAmount.safeMul(buyTokenBaseUnit).safeDiv(feeDivisor);

            sellToken.approveIfBelow(data.psmAddress, sellAmount);
            psm.buyGem(address(this), gemAmount);
        }

        return buyToken.balanceOf(address(this)).safeSub(beforeBalance);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IEtherTokenV06.sol";
import "../IBridgeAdapter.sol";

/// @dev Moooniswap pool interface.
interface IMooniswapPool {
    function swap(
        IERC20TokenV06 sellToken,
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        uint256 minBoughtAmount,
        address referrer
    ) external payable returns (uint256 boughtAmount);
}

/// @dev BridgeAdapter mixin for mooniswap.
contract MixinMooniswap {
    using LibERC20TokenV06 for IERC20TokenV06;
    using LibERC20TokenV06 for IEtherTokenV06;

    /// @dev WETH token.
    IEtherTokenV06 private immutable WETH;

    constructor(IEtherTokenV06 weth) public {
        WETH = weth;
    }

    function _tradeMooniswap(
        IERC20TokenV06 sellToken,
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) internal returns (uint256 boughtAmount) {
        IMooniswapPool pool = abi.decode(bridgeData, (IMooniswapPool));

        // Convert WETH to ETH.
        uint256 ethValue = 0;
        if (sellToken == WETH) {
            WETH.withdraw(sellAmount);
            ethValue = sellAmount;
        } else {
            // Grant the pool an allowance.
            sellToken.approveIfBelow(address(pool), sellAmount);
        }

        boughtAmount = pool.swap{value: ethValue}(
            sellToken == WETH ? IERC20TokenV06(0) : sellToken,
            buyToken == WETH ? IERC20TokenV06(0) : buyToken,
            sellAmount,
            1,
            address(0)
        );

        // Wrap ETH to WETH.
        if (buyToken == WETH) {
            WETH.deposit{value: boughtAmount}();
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "../IBridgeAdapter.sol";

interface IMStable {
    function swap(
        IERC20TokenV06 sellToken,
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        uint256 minBoughtAmount,
        address recipient
    ) external returns (uint256 boughtAmount);
}

contract MixinMStable {
    using LibERC20TokenV06 for IERC20TokenV06;

    function _tradeMStable(
        IERC20TokenV06 sellToken,
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) internal returns (uint256 boughtAmount) {
        IMStable mstable = abi.decode(bridgeData, (IMStable));

        // Grant an allowance to the exchange to spend `sellToken` token.
        sellToken.approveIfBelow(address(mstable), sellAmount);

        boughtAmount = mstable.swap(
            sellToken,
            buyToken,
            sellAmount,
            // Minimum buy amount.
            1,
            address(this)
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";

contract MixinNerve {
    using LibERC20TokenV06 for IERC20TokenV06;
    using LibSafeMathV06 for uint256;
    using LibRichErrorsV06 for bytes;

    struct NerveBridgeData {
        address pool;
        bytes4 exchangeFunctionSelector;
        int128 fromCoinIdx;
        int128 toCoinIdx;
    }

    function _tradeNerve(
        IERC20TokenV06 sellToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) internal returns (uint256 boughtAmount) {
        // Basically a Curve fork but the swap option has a deadline

        // Decode the bridge data to get the Curve metadata.
        NerveBridgeData memory data = abi.decode(bridgeData, (NerveBridgeData));
        sellToken.approveIfBelow(data.pool, sellAmount);
        (bool success, bytes memory resultData) = data.pool.call(
            abi.encodeWithSelector(
                data.exchangeFunctionSelector,
                data.fromCoinIdx,
                data.toCoinIdx,
                // dx
                sellAmount,
                // min dy
                1,
                // deadline
                block.timestamp
            )
        );
        if (!success) {
            resultData.rrevert();
        }
        return abi.decode(resultData, (uint256));
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";

interface IPlatypusRouter {
    function swapTokensForTokens(
        address[] calldata tokenPath,
        address[] calldata poolPath,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut, uint256 haircut);
}

contract MixinPlatypus {
    using LibERC20TokenV06 for IERC20TokenV06;
    using LibSafeMathV06 for uint256;

    function _tradePlatypus(
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) public returns (uint256 boughtAmount) {
        IPlatypusRouter router;
        address _router;
        address[] memory _pool;
        IERC20TokenV06[] memory path;
        address[] memory _path;

        {
            (_router, _pool, _path) = abi.decode(bridgeData, (address, address[], address[]));

            // To get around `abi.decode()` not supporting interface array types.
            assembly {
                path := _path
            }
        }

        //connect to the ptp router
        router = IPlatypusRouter(_router);

        require(path.length >= 2, "MixinPlatypus/PATH_LENGTH_MUST_BE_AT_LEAST_TWO");
        require(path[path.length - 1] == buyToken, "MixinPlatypus/LAST_ELEMENT_OF_PATH_MUST_MATCH_OUTPUT_TOKEN");
        // Grant the Platypus router an allowance to sell the first token.
        path[0].approveIfBelow(address(router), sellAmount);

        //keep track of the previous balance to confirm amount out
        uint256 beforeBalance = buyToken.balanceOf(address(this));

        router.swapTokensForTokens(
            // Convert to `buyToken` along this path.
            _path,
            // pool to swap on
            _pool,
            // Sell all tokens we hold.
            sellAmount,
            // Minimum buy amount.
            0,
            // Recipient is `this`.
            address(this),
            block.timestamp + 1
        );
        //calculate the buy amount from the tokens we recieved
        boughtAmount = buyToken.balanceOf(address(this)).safeSub(beforeBalance);
        return boughtAmount;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";

interface IShell {
    function originSwap(
        IERC20TokenV06 from,
        IERC20TokenV06 to,
        uint256 fromAmount,
        uint256 minTargetAmount,
        uint256 deadline
    ) external returns (uint256 toAmount);
}

contract MixinShell {
    using LibERC20TokenV06 for IERC20TokenV06;

    function _tradeShell(
        IERC20TokenV06 sellToken,
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) internal returns (uint256 boughtAmount) {
        IShell pool = abi.decode(bridgeData, (IShell));

        // Grant the Shell contract an allowance to sell the first token.
        IERC20TokenV06(sellToken).approveIfBelow(address(pool), sellAmount);

        boughtAmount = pool.originSwap(
            sellToken,
            buyToken,
            // Sell all tokens we hold.
            sellAmount,
            // Minimum buy amount.
            1,
            // deadline
            block.timestamp + 1
        );
        return boughtAmount;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";

interface ISolidlyRouter {
    function swapExactTokensForTokensSimple(
        uint256 amountIn,
        uint256 amountOutMin,
        address tokenFrom,
        address tokenTo,
        bool stable,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract MixinSolidly {
    using LibERC20TokenV06 for IERC20TokenV06;

    function _tradeSolidly(
        IERC20TokenV06 sellToken,
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) internal returns (uint256 boughtAmount) {
        (ISolidlyRouter router, bool stable) = abi.decode(bridgeData, (ISolidlyRouter, bool));
        sellToken.approveIfBelow(address(router), sellAmount);

        boughtAmount = router.swapExactTokensForTokensSimple(
            sellAmount,
            0,
            address(sellToken),
            address(buyToken),
            stable,
            address(this),
            block.timestamp + 1
        )[1];
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

interface ISynthetix {
    // Ethereum Mainnet
    function exchangeAtomically(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        bytes32 trackingCode,
        uint256 minAmount
    ) external returns (uint256 amountReceived);

    // Optimism
    function exchangeWithTracking(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        address rewardAddress,
        bytes32 trackingCode
    ) external returns (uint256 amountReceived);
}

contract MixinSynthetix {
    // solhint-disable-next-line const-name-snakecase
    address private constant rewardAddress = 0x5C80239D97E1eB216b5c3D8fBa5DE5Be5d38e4C9;
    // solhint-disable-next-line const-name-snakecase
    bytes32 constant trackingCode = 0x3058000000000000000000000000000000000000000000000000000000000000;

    function _tradeSynthetix(uint256 sellAmount, bytes memory bridgeData) public returns (uint256 boughtAmount) {
        (ISynthetix synthetix, bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) = abi.decode(
            bridgeData,
            (ISynthetix, bytes32, bytes32)
        );

        boughtAmount = exchange(synthetix, sourceCurrencyKey, destinationCurrencyKey, sellAmount);
    }

    function exchange(
        ISynthetix synthetix,
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey,
        uint256 sellAmount
    ) internal returns (uint256 boughtAmount) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        if (chainId == 1) {
            boughtAmount = synthetix.exchangeAtomically(
                sourceCurrencyKey,
                sellAmount,
                destinationCurrencyKey,
                trackingCode,
                0
            );
        } else {
            boughtAmount = synthetix.exchangeWithTracking(
                sourceCurrencyKey,
                sellAmount,
                destinationCurrencyKey,
                rewardAddress,
                trackingCode
            );
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IEtherTokenV06.sol";
import "../IBridgeAdapter.sol";

interface IUniswapExchangeFactory {
    /// @dev Get the exchange for a token.
    /// @param token The token contract.
    function getExchange(IERC20TokenV06 token) external view returns (IUniswapExchange exchange);
}

interface IUniswapExchange {
    /// @dev Buys at least `minTokensBought` tokens with ETH and transfer them
    ///      to `recipient`.
    /// @param minTokensBought The minimum number of tokens to buy.
    /// @param deadline Time when this order expires.
    /// @param recipient Who to transfer the tokens to.
    /// @return tokensBought Amount of tokens bought.
    function ethToTokenTransferInput(
        uint256 minTokensBought,
        uint256 deadline,
        address recipient
    ) external payable returns (uint256 tokensBought);

    /// @dev Buys at least `minEthBought` ETH with tokens.
    /// @param tokensSold Amount of tokens to sell.
    /// @param minEthBought The minimum amount of ETH to buy.
    /// @param deadline Time when this order expires.
    /// @return ethBought Amount of tokens bought.
    function tokenToEthSwapInput(
        uint256 tokensSold,
        uint256 minEthBought,
        uint256 deadline
    ) external returns (uint256 ethBought);

    /// @dev Buys at least `minTokensBought` tokens with the exchange token
    ///      and transfer them to `recipient`.
    /// @param tokensSold Amount of tokens to sell.
    /// @param minTokensBought The minimum number of tokens to buy.
    /// @param minEthBought The minimum amount of intermediate ETH to buy.
    /// @param deadline Time when this order expires.
    /// @param recipient Who to transfer the tokens to.
    /// @param buyToken The token being bought.
    /// @return tokensBought Amount of tokens bought.
    function tokenToTokenTransferInput(
        uint256 tokensSold,
        uint256 minTokensBought,
        uint256 minEthBought,
        uint256 deadline,
        address recipient,
        IERC20TokenV06 buyToken
    ) external returns (uint256 tokensBought);

    /// @dev Buys at least `minTokensBought` tokens with the exchange token.
    /// @param tokensSold Amount of tokens to sell.
    /// @param minTokensBought The minimum number of tokens to buy.
    /// @param minEthBought The minimum amount of intermediate ETH to buy.
    /// @param deadline Time when this order expires.
    /// @param buyToken The token being bought.
    /// @return tokensBought Amount of tokens bought.
    function tokenToTokenSwapInput(
        uint256 tokensSold,
        uint256 minTokensBought,
        uint256 minEthBought,
        uint256 deadline,
        IERC20TokenV06 buyToken
    ) external returns (uint256 tokensBought);
}

contract MixinUniswap {
    using LibERC20TokenV06 for IERC20TokenV06;

    /// @dev Mainnet address of the WETH contract.
    IEtherTokenV06 private immutable WETH;

    constructor(IEtherTokenV06 weth) public {
        WETH = weth;
    }

    //·solhint-disable-next-line·function-max-lines
    function _tradeUniswap(
        IERC20TokenV06 sellToken,
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) internal returns (uint256 boughtAmount) {
        IUniswapExchangeFactory exchangeFactory = abi.decode(bridgeData, (IUniswapExchangeFactory));

        // Get the exchange for the token pair.
        IUniswapExchange exchange = _getUniswapExchangeForTokenPair(exchangeFactory, sellToken, buyToken);

        // Convert from WETH to a token.
        if (sellToken == WETH) {
            // Unwrap the WETH.
            WETH.withdraw(sellAmount);
            // Buy as much of `buyToken` token with ETH as possible
            boughtAmount = exchange.ethToTokenTransferInput{value: sellAmount}(
                // Minimum buy amount.
                1,
                // Expires after this block.
                block.timestamp,
                // Recipient is `this`.
                address(this)
            );

            // Convert from a token to WETH.
        } else if (buyToken == WETH) {
            // Grant the exchange an allowance.
            sellToken.approveIfBelow(address(exchange), sellAmount);
            // Buy as much ETH with `sellToken` token as possible.
            boughtAmount = exchange.tokenToEthSwapInput(
                // Sell all tokens we hold.
                sellAmount,
                // Minimum buy amount.
                1,
                // Expires after this block.
                block.timestamp
            );
            // Wrap the ETH.
            WETH.deposit{value: boughtAmount}();
            // Convert from one token to another.
        } else {
            // Grant the exchange an allowance.
            sellToken.approveIfBelow(address(exchange), sellAmount);
            // Buy as much `buyToken` token with `sellToken` token
            boughtAmount = exchange.tokenToTokenSwapInput(
                // Sell all tokens we hold.
                sellAmount,
                // Minimum buy amount.
                1,
                // Must buy at least 1 intermediate wei of ETH.
                1,
                // Expires after this block.
                block.timestamp,
                // Convert to `buyToken`.
                buyToken
            );
        }

        return boughtAmount;
    }

    /// @dev Retrieves the uniswap exchange for a given token pair.
    ///      In the case of a WETH-token exchange, this will be the non-WETH token.
    ///      In th ecase of a token-token exchange, this will be the first token.
    /// @param exchangeFactory The exchange factory.
    /// @param sellToken The address of the token we are converting from.
    /// @param buyToken The address of the token we are converting to.
    /// @return exchange The uniswap exchange.
    function _getUniswapExchangeForTokenPair(
        IUniswapExchangeFactory exchangeFactory,
        IERC20TokenV06 sellToken,
        IERC20TokenV06 buyToken
    ) private view returns (IUniswapExchange exchange) {
        // Whichever isn't WETH is the exchange token.
        exchange = sellToken == WETH ? exchangeFactory.getExchange(buyToken) : exchangeFactory.getExchange(sellToken);
        require(address(exchange) != address(0), "MixinUniswap/NO_EXCHANGE");
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "../IBridgeAdapter.sol";

/*
    UniswapV2
*/
interface IUniswapV2Router02 {
    /// @dev Swaps an exact amount of input tokens for as many output tokens as possible, along the route determined by
    /// the path. The first element of path is the input token, the last is the output token, and any intermediate
    /// elements represent intermediate pairs to trade through (if, for example, a direct pair does not exist).
    /// @param amountIn The amount of input tokens to send.
    /// @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert.
    /// @param path An array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses
    /// must exist and have liquidity.
    /// @param to Recipient of the output tokens.
    /// @param deadline Unix timestamp after which the transaction will revert.
    /// @return amounts The input token amount and all subsequent output token amounts.
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        IERC20TokenV06[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract MixinUniswapV2 {
    using LibERC20TokenV06 for IERC20TokenV06;

    function _tradeUniswapV2(
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) internal returns (uint256 boughtAmount) {
        IUniswapV2Router02 router;
        IERC20TokenV06[] memory path;
        {
            address[] memory _path;
            (router, _path) = abi.decode(bridgeData, (IUniswapV2Router02, address[]));
            // To get around `abi.decode()` not supporting interface array types.
            assembly {
                path := _path
            }
        }

        require(path.length >= 2, "MixinUniswapV2/PATH_LENGTH_MUST_BE_AT_LEAST_TWO");
        require(path[path.length - 1] == buyToken, "MixinUniswapV2/LAST_ELEMENT_OF_PATH_MUST_MATCH_OUTPUT_TOKEN");
        // Grant the Uniswap router an allowance to sell the first token.
        path[0].approveIfBelow(address(router), sellAmount);

        uint256[] memory amounts = router.swapExactTokensForTokens(
            // Sell all tokens we hold.
            sellAmount,
            // Minimum buy amount.
            1,
            // Convert to `buyToken` along this path.
            path,
            // Recipient is `this`.
            address(this),
            // Expires after this block.
            block.timestamp
        );
        return amounts[amounts.length - 1];
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "../IBridgeAdapter.sol";

interface IUniswapV3Router {
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams memory params) external payable returns (uint256 amountOut);
}

contract MixinUniswapV3 {
    using LibERC20TokenV06 for IERC20TokenV06;

    function _tradeUniswapV3(
        IERC20TokenV06 sellToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) internal returns (uint256 boughtAmount) {
        (IUniswapV3Router router, bytes memory path) = abi.decode(bridgeData, (IUniswapV3Router, bytes));

        // Grant the Uniswap router an allowance to sell the sell token.
        sellToken.approveIfBelow(address(router), sellAmount);

        boughtAmount = router.exactInput(
            IUniswapV3Router.ExactInputParams({
                path: path,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: sellAmount,
                amountOutMinimum: 1
            })
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IEtherTokenV06.sol";
import "../IBridgeAdapter.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";

/// @dev WooFI pool interface.
interface IWooPP {
    /// @notice Swap `fromToken` to `toToken`.
    /// @param fromToken the from token
    /// @param toToken the to token
    /// @param fromAmount the amount of `fromToken` to swap
    /// @param minToAmount the minimum amount of `toToken` to receive
    /// @param to the destination address
    /// @param rebateTo the rebate address (optional, can be 0)
    /// @return realToAmount the amount of toToken to receive
    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minToAmount,
        address to,
        address rebateTo
    ) external payable returns (uint256 realToAmount);
}

contract MixinWOOFi {
    using LibERC20TokenV06 for IERC20TokenV06;
    using LibERC20TokenV06 for IEtherTokenV06;
    using LibSafeMathV06 for uint256;

    // solhint-disable-next-line const-name-snakecase
    address constant rebateAddress = 0xBfdcBB4C05843163F491C24f9c0019c510786304;

    function _tradeWOOFi(
        IERC20TokenV06 sellToken,
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) public returns (uint256 boughtAmount) {
        IWooPP _router = abi.decode(bridgeData, (IWooPP));
        uint256 beforeBalance = buyToken.balanceOf(address(this));

        sellToken.approveIfBelow(address(_router), sellAmount);

        boughtAmount = _router.swap(address(sellToken), address(buyToken), sellAmount, 0, address(this), rebateAddress);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;

import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../../../vendor/ILiquidityProvider.sol";

contract MixinZeroExBridge {
    using LibERC20TokenV06 for IERC20TokenV06;
    using LibSafeMathV06 for uint256;

    function _tradeZeroExBridge(
        IERC20TokenV06 sellToken,
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) internal returns (uint256 boughtAmount) {
        (ILiquidityProvider provider, bytes memory lpData) = abi.decode(bridgeData, (ILiquidityProvider, bytes));
        // Trade the good old fashioned way
        sellToken.compatTransfer(address(provider), sellAmount);
        boughtAmount = provider.sellTokenForToken(
            sellToken,
            buyToken,
            address(this), // recipient
            1, // minBuyAmount
            lpData
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./AbstractBridgeAdapter.sol";
import "./BridgeProtocols.sol";
import "./mixins/MixinAaveV3.sol";
import "./mixins/MixinBalancerV2Batch.sol";
import "./mixins/MixinCurve.sol";
import "./mixins/MixinCurveV2.sol";
import "./mixins/MixinNerve.sol";
import "./mixins/MixinSolidly.sol";
import "./mixins/MixinSynthetix.sol";
import "./mixins/MixinUniswapV3.sol";
import "./mixins/MixinWOOFi.sol";
import "./mixins/MixinZeroExBridge.sol";

contract OptimismBridgeAdapter is
    AbstractBridgeAdapter(10, "Optimism"),
    MixinAaveV3,
    MixinBalancerV2Batch,
    MixinCurve,
    MixinCurveV2,
    MixinNerve,
    MixinSynthetix,
    MixinUniswapV3,
    MixinSolidly,
    MixinWOOFi,
    MixinZeroExBridge
{
    constructor(IEtherTokenV06 weth) public MixinCurve(weth) MixinAaveV3(true) {}

    /* solhint-disable function-max-lines */
    function _trade(
        BridgeOrder memory order,
        IERC20TokenV06 sellToken,
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bool dryRun
    ) internal override returns (uint256 boughtAmount, bool supportedSource) {
        uint128 protocolId = uint128(uint256(order.source) >> 128);
        if (protocolId == BridgeProtocols.CURVE) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeCurve(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.CURVEV2) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeCurveV2(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.UNISWAPV3) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeUniswapV3(sellToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.NERVE) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeNerve(sellToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.SOLIDLY) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeSolidly(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.SYNTHETIX) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeSynthetix(sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.UNKNOWN) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeZeroExBridge(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.BALANCERV2BATCH) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeBalancerV2Batch(sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.AAVEV3) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeAaveV3(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.WOOFI) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeWOOFi(sellToken, buyToken, sellAmount, order.bridgeData);
        }

        emit BridgeFill(order.source, sellToken, buyToken, sellAmount, boughtAmount);
    }
    /* solhint-enable function-max-lines */
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./AbstractBridgeAdapter.sol";
import "./BridgeProtocols.sol";
import "./mixins/MixinAaveV3.sol";
import "./mixins/MixinAaveV2.sol";
import "./mixins/MixinBalancerV2Batch.sol";
import "./mixins/MixinCurve.sol";
import "./mixins/MixinCurveV2.sol";
import "./mixins/MixinDodo.sol";
import "./mixins/MixinDodoV2.sol";
import "./mixins/MixinKyberDmm.sol";
import "./mixins/MixinMStable.sol";
import "./mixins/MixinNerve.sol";
import "./mixins/MixinSolidly.sol";
import "./mixins/MixinUniswapV2.sol";
import "./mixins/MixinUniswapV3.sol";
import "./mixins/MixinWOOFi.sol";
import "./mixins/MixinZeroExBridge.sol";

contract PolygonBridgeAdapter is
    AbstractBridgeAdapter(137, "Polygon"),
    MixinAaveV3,
    MixinAaveV2,
    MixinBalancerV2Batch,
    MixinCurve,
    MixinCurveV2,
    MixinDodo,
    MixinDodoV2,
    MixinKyberDmm,
    MixinMStable,
    MixinNerve,
    MixinUniswapV2,
    MixinUniswapV3,
    MixinSolidly,
    MixinWOOFi,
    MixinZeroExBridge
{
    constructor(IEtherTokenV06 weth) public MixinCurve(weth) MixinAaveV3(false) {}

    function _trade(
        BridgeOrder memory order,
        IERC20TokenV06 sellToken,
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        bool dryRun
    ) internal override returns (uint256 boughtAmount, bool supportedSource) {
        uint128 protocolId = uint128(uint256(order.source) >> 128);
        if (protocolId == BridgeProtocols.CURVE) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeCurve(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.CURVEV2) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeCurveV2(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.UNISWAPV3) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeUniswapV3(sellToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.UNISWAPV2) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeUniswapV2(buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.BALANCERV2BATCH) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeBalancerV2Batch(sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.MSTABLE) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeMStable(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.DODO) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeDodo(sellToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.DODOV2) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeDodoV2(sellToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.NERVE) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeNerve(sellToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.KYBERDMM) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeKyberDmm(buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.AAVEV2) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeAaveV2(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.SOLIDLY) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeSolidly(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.WOOFI) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeWOOFi(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.UNKNOWN) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeZeroExBridge(sellToken, buyToken, sellAmount, order.bridgeData);
        } else if (protocolId == BridgeProtocols.AAVEV3) {
            if (dryRun) {
                return (0, true);
            }
            boughtAmount = _tradeAaveV3(sellToken, buyToken, sellAmount, order.bridgeData);
        }

        emit BridgeFill(order.source, sellToken, buyToken, sellAmount, boughtAmount);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibMathV06.sol";
import "../errors/LibTransformERC20RichErrors.sol";
import "../features/interfaces/INativeOrdersFeature.sol";
import "../features/libs/LibNativeOrder.sol";
import "./bridges/IBridgeAdapter.sol";
import "./Transformer.sol";
import "./LibERC20Transformer.sol";
import "../IZeroEx.sol";

/// @dev A transformer that fills an ERC20 market sell/buy quote.
///      This transformer shortcuts bridge orders and fills them directly
contract FillQuoteTransformer is Transformer {
    using LibERC20TokenV06 for IERC20TokenV06;
    using LibERC20Transformer for IERC20TokenV06;
    using LibSafeMathV06 for uint256;
    using LibSafeMathV06 for uint128;
    using LibRichErrorsV06 for bytes;

    /// @dev Whether we are performing a market sell or buy.
    enum Side {
        Sell,
        Buy
    }

    enum OrderType {
        Bridge,
        Limit,
        Rfq,
        Otc
    }

    struct LimitOrderInfo {
        LibNativeOrder.LimitOrder order;
        LibSignature.Signature signature;
        // Maximum taker token amount of this limit order to fill.
        uint256 maxTakerTokenFillAmount;
    }

    struct RfqOrderInfo {
        LibNativeOrder.RfqOrder order;
        LibSignature.Signature signature;
        // Maximum taker token amount of this limit order to fill.
        uint256 maxTakerTokenFillAmount;
    }

    struct OtcOrderInfo {
        LibNativeOrder.OtcOrder order;
        LibSignature.Signature signature;
        // Maximum taker token amount of this limit order to fill.
        uint256 maxTakerTokenFillAmount;
    }

    /// @dev Transform data to ABI-encode and pass into `transform()`.
    struct TransformData {
        // Whether we are performing a market sell or buy.
        Side side;
        // The token being sold.
        // This should be an actual token, not the ETH pseudo-token.
        IERC20TokenV06 sellToken;
        // The token being bought.
        // This should be an actual token, not the ETH pseudo-token.
        IERC20TokenV06 buyToken;
        // External liquidity bridge orders. Sorted by fill sequence.
        IBridgeAdapter.BridgeOrder[] bridgeOrders;
        // Native limit orders. Sorted by fill sequence.
        LimitOrderInfo[] limitOrders;
        // Native RFQ orders. Sorted by fill sequence.
        RfqOrderInfo[] rfqOrders;
        // The sequence to fill the orders in. Each item will fill the next
        // order of that type in either `bridgeOrders`, `limitOrders`,
        // or `rfqOrders.`
        OrderType[] fillSequence;
        // Amount of `sellToken` to sell or `buyToken` to buy.
        // For sells, setting the high-bit indicates that
        // `sellAmount & LOW_BITS` should be treated as a `1e18` fraction of
        // the current balance of `sellToken`, where
        // `1e18+ == 100%` and `0.5e18 == 50%`, etc.
        uint256 fillAmount;
        // Who to transfer unused protocol fees to.
        // May be a valid address or one of:
        // `address(0)`: Stay in flash wallet.
        // `address(1)`: Send to the taker.
        // `address(2)`: Send to the sender (caller of `transformERC20()`).
        address payable refundReceiver;
        // Otc orders. Sorted by fill sequence.
        OtcOrderInfo[] otcOrders;
    }

    struct FillOrderResults {
        // The amount of taker tokens sold, according to balance checks.
        uint256 takerTokenSoldAmount;
        // The amount of maker tokens sold, according to balance checks.
        uint256 makerTokenBoughtAmount;
        // The amount of protocol fee paid.
        uint256 protocolFeePaid;
    }

    /// @dev Intermediate state variables to get around stack limits.
    struct FillState {
        uint256 ethRemaining;
        uint256 boughtAmount;
        uint256 soldAmount;
        uint256 protocolFee;
        uint256 takerTokenBalanceRemaining;
        uint256[4] currentIndices;
        OrderType currentOrderType;
    }

    /// @dev Emitted when a trade is skipped due to a lack of funds
    ///      to pay the 0x Protocol fee.
    /// @param orderHash The hash of the order that was skipped.
    event ProtocolFeeUnfunded(bytes32 orderHash);

    /// @dev The highest bit of a uint256 value.
    uint256 private constant HIGH_BIT = 2 ** 255;
    /// @dev Mask of the lower 255 bits of a uint256 value.
    uint256 private constant LOWER_255_BITS = HIGH_BIT - 1;
    /// @dev If `refundReceiver` is set to this address, unpsent
    ///      protocol fees will be sent to the transform recipient.
    address private constant REFUND_RECEIVER_RECIPIENT = address(1);
    /// @dev If `refundReceiver` is set to this address, unpsent
    ///      protocol fees will be sent to the sender.
    address private constant REFUND_RECEIVER_SENDER = address(2);

    /// @dev The BridgeAdapter address
    IBridgeAdapter public immutable bridgeAdapter;

    /// @dev The exchange proxy contract.
    IZeroEx public immutable zeroEx;

    /// @dev Create this contract.
    /// @param bridgeAdapter_ The bridge adapter contract.
    /// @param zeroEx_ The Exchange Proxy contract.
    constructor(IBridgeAdapter bridgeAdapter_, IZeroEx zeroEx_) public Transformer() {
        bridgeAdapter = bridgeAdapter_;
        zeroEx = zeroEx_;
    }

    /// @dev Sell this contract's entire balance of of `sellToken` in exchange
    ///      for `buyToken` by filling `orders`. Protocol fees should be attached
    ///      to this call. `buyToken` and excess ETH will be transferred back to the caller.
    /// @param context Context information.
    /// @return magicBytes The success bytes (`LibERC20Transformer.TRANSFORMER_SUCCESS`).
    /* solhint-disable function-max-lines */
    function transform(TransformContext calldata context) external override returns (bytes4 magicBytes) {
        TransformData memory data = abi.decode(context.data, (TransformData));
        FillState memory state;

        // Validate data fields.
        if (data.sellToken.isTokenETH() || data.buyToken.isTokenETH()) {
            LibTransformERC20RichErrors
                .InvalidTransformDataError(
                    LibTransformERC20RichErrors.InvalidTransformDataErrorCode.INVALID_TOKENS,
                    context.data
                )
                .rrevert();
        }

        if (
            data.bridgeOrders.length + data.limitOrders.length + data.rfqOrders.length + data.otcOrders.length !=
            data.fillSequence.length
        ) {
            LibTransformERC20RichErrors
                .InvalidTransformDataError(
                    LibTransformERC20RichErrors.InvalidTransformDataErrorCode.INVALID_ARRAY_LENGTH,
                    context.data
                )
                .rrevert();
        }

        state.takerTokenBalanceRemaining = data.sellToken.getTokenBalanceOf(address(this));
        if (data.side == Side.Sell) {
            data.fillAmount = _normalizeFillAmount(data.fillAmount, state.takerTokenBalanceRemaining);
        }

        // Approve the exchange proxy to spend our sell tokens if native orders
        // are present.
        if (data.limitOrders.length + data.rfqOrders.length + data.otcOrders.length != 0) {
            data.sellToken.approveIfBelow(address(zeroEx), data.fillAmount);
            // Compute the protocol fee if a limit order is present.
            if (data.limitOrders.length != 0) {
                state.protocolFee = uint256(zeroEx.getProtocolFeeMultiplier()).safeMul(tx.gasprice);
            }
        }

        state.ethRemaining = address(this).balance;

        // Fill the orders.
        for (uint256 i = 0; i < data.fillSequence.length; ++i) {
            // Check if we've hit our targets.
            if (data.side == Side.Sell) {
                // Market sell check.
                if (state.soldAmount >= data.fillAmount) {
                    break;
                }
            } else {
                // Market buy check.
                if (state.boughtAmount >= data.fillAmount) {
                    break;
                }
            }

            state.currentOrderType = OrderType(data.fillSequence[i]);
            uint256 orderIndex = state.currentIndices[uint256(state.currentOrderType)];
            // Fill the order.
            FillOrderResults memory results;
            if (state.currentOrderType == OrderType.Bridge) {
                results = _fillBridgeOrder(data.bridgeOrders[orderIndex], data, state);
            } else if (state.currentOrderType == OrderType.Limit) {
                results = _fillLimitOrder(data.limitOrders[orderIndex], data, state);
            } else if (state.currentOrderType == OrderType.Rfq) {
                results = _fillRfqOrder(data.rfqOrders[orderIndex], data, state);
            } else if (state.currentOrderType == OrderType.Otc) {
                results = _fillOtcOrder(data.otcOrders[orderIndex], data, state);
            } else {
                revert("INVALID_ORDER_TYPE");
            }

            // Accumulate totals.
            state.soldAmount = state.soldAmount.safeAdd(results.takerTokenSoldAmount);
            state.boughtAmount = state.boughtAmount.safeAdd(results.makerTokenBoughtAmount);
            state.ethRemaining = state.ethRemaining.safeSub(results.protocolFeePaid);
            state.takerTokenBalanceRemaining = state.takerTokenBalanceRemaining.safeSub(results.takerTokenSoldAmount);
            state.currentIndices[uint256(state.currentOrderType)]++;
        }

        // Ensure we hit our targets.
        if (data.side == Side.Sell) {
            // Market sell check.
            if (state.soldAmount < data.fillAmount) {
                LibTransformERC20RichErrors
                    .IncompleteFillSellQuoteError(address(data.sellToken), state.soldAmount, data.fillAmount)
                    .rrevert();
            }
        } else {
            // Market buy check.
            if (state.boughtAmount < data.fillAmount) {
                LibTransformERC20RichErrors
                    .IncompleteFillBuyQuoteError(address(data.buyToken), state.boughtAmount, data.fillAmount)
                    .rrevert();
            }
        }

        // Refund unspent protocol fees.
        if (state.ethRemaining > 0 && data.refundReceiver != address(0)) {
            bool transferSuccess;
            if (data.refundReceiver == REFUND_RECEIVER_RECIPIENT) {
                (transferSuccess, ) = context.recipient.call{value: state.ethRemaining}("");
            } else if (data.refundReceiver == REFUND_RECEIVER_SENDER) {
                (transferSuccess, ) = context.sender.call{value: state.ethRemaining}("");
            } else {
                (transferSuccess, ) = data.refundReceiver.call{value: state.ethRemaining}("");
            }
            require(transferSuccess, "FillQuoteTransformer/ETHER_TRANSFER_FALIED");
        }
        return LibERC20Transformer.TRANSFORMER_SUCCESS;
    }

    /* solhint-enable function-max-lines */

    // Fill a single bridge order.
    function _fillBridgeOrder(
        IBridgeAdapter.BridgeOrder memory order,
        TransformData memory data,
        FillState memory state
    ) private returns (FillOrderResults memory results) {
        uint256 takerTokenFillAmount = _computeTakerTokenFillAmount(
            data,
            state,
            order.takerTokenAmount,
            order.makerTokenAmount,
            0
        );

        (bool success, bytes memory resultData) = address(bridgeAdapter).delegatecall(
            abi.encodeWithSelector(
                IBridgeAdapter.trade.selector,
                order,
                data.sellToken,
                data.buyToken,
                takerTokenFillAmount
            )
        );
        if (success) {
            results.makerTokenBoughtAmount = abi.decode(resultData, (uint256));
            results.takerTokenSoldAmount = takerTokenFillAmount;
        }
    }

    // Fill a single limit order.
    function _fillLimitOrder(
        LimitOrderInfo memory orderInfo,
        TransformData memory data,
        FillState memory state
    ) private returns (FillOrderResults memory results) {
        uint256 takerTokenFillAmount = LibSafeMathV06.min256(
            _computeTakerTokenFillAmount(
                data,
                state,
                orderInfo.order.takerAmount,
                orderInfo.order.makerAmount,
                orderInfo.order.takerTokenFeeAmount
            ),
            orderInfo.maxTakerTokenFillAmount
        );

        // Emit an event if we do not have sufficient ETH to cover the protocol fee.
        if (state.ethRemaining < state.protocolFee) {
            bytes32 orderHash = zeroEx.getLimitOrderHash(orderInfo.order);
            emit ProtocolFeeUnfunded(orderHash);
            return results; // Empty results.
        }

        try
            zeroEx.fillLimitOrder{value: state.protocolFee}(
                orderInfo.order,
                orderInfo.signature,
                takerTokenFillAmount.safeDowncastToUint128()
            )
        returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount) {
            if (orderInfo.order.takerTokenFeeAmount > 0) {
                takerTokenFilledAmount = takerTokenFilledAmount.safeAdd128(
                    LibMathV06
                        .getPartialAmountFloor(
                            takerTokenFilledAmount,
                            orderInfo.order.takerAmount,
                            orderInfo.order.takerTokenFeeAmount
                        )
                        .safeDowncastToUint128()
                );
            }
            results.takerTokenSoldAmount = takerTokenFilledAmount;
            results.makerTokenBoughtAmount = makerTokenFilledAmount;
            results.protocolFeePaid = state.protocolFee;
        } catch {}
    }

    // Fill a single RFQ order.
    function _fillRfqOrder(
        RfqOrderInfo memory orderInfo,
        TransformData memory data,
        FillState memory state
    ) private returns (FillOrderResults memory results) {
        uint256 takerTokenFillAmount = LibSafeMathV06.min256(
            _computeTakerTokenFillAmount(data, state, orderInfo.order.takerAmount, orderInfo.order.makerAmount, 0),
            orderInfo.maxTakerTokenFillAmount
        );

        try
            zeroEx.fillRfqOrder(orderInfo.order, orderInfo.signature, takerTokenFillAmount.safeDowncastToUint128())
        returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount) {
            results.takerTokenSoldAmount = takerTokenFilledAmount;
            results.makerTokenBoughtAmount = makerTokenFilledAmount;
        } catch {}
    }

    // Fill a single OTC order.
    function _fillOtcOrder(
        OtcOrderInfo memory orderInfo,
        TransformData memory data,
        FillState memory state
    ) private returns (FillOrderResults memory results) {
        uint256 takerTokenFillAmount = LibSafeMathV06.min256(
            _computeTakerTokenFillAmount(data, state, orderInfo.order.takerAmount, orderInfo.order.makerAmount, 0),
            orderInfo.maxTakerTokenFillAmount
        );
        try
            zeroEx.fillOtcOrder(orderInfo.order, orderInfo.signature, takerTokenFillAmount.safeDowncastToUint128())
        returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount) {
            results.takerTokenSoldAmount = takerTokenFilledAmount;
            results.makerTokenBoughtAmount = makerTokenFilledAmount;
        } catch {
            revert("FillQuoteTransformer/OTC_ORDER_FILL_FAILED");
        }
    }

    // Compute the next taker token fill amount of a generic order.
    function _computeTakerTokenFillAmount(
        TransformData memory data,
        FillState memory state,
        uint256 orderTakerAmount,
        uint256 orderMakerAmount,
        uint256 orderTakerTokenFeeAmount
    ) private pure returns (uint256 takerTokenFillAmount) {
        if (data.side == Side.Sell) {
            takerTokenFillAmount = data.fillAmount.safeSub(state.soldAmount);
            if (orderTakerTokenFeeAmount != 0) {
                takerTokenFillAmount = LibMathV06.getPartialAmountCeil(
                    takerTokenFillAmount,
                    orderTakerAmount.safeAdd(orderTakerTokenFeeAmount),
                    orderTakerAmount
                );
            }
        } else {
            // Buy
            takerTokenFillAmount = LibMathV06.getPartialAmountCeil(
                data.fillAmount.safeSub(state.boughtAmount),
                orderMakerAmount,
                orderTakerAmount
            );
        }
        return
            LibSafeMathV06.min256(
                LibSafeMathV06.min256(takerTokenFillAmount, orderTakerAmount),
                state.takerTokenBalanceRemaining
            );
    }

    // Convert possible proportional values to absolute quantities.
    function _normalizeFillAmount(uint256 rawAmount, uint256 balance) private pure returns (uint256 normalized) {
        if ((rawAmount & HIGH_BIT) == HIGH_BIT) {
            // If the high bit of `rawAmount` is set then the lower 255 bits
            // specify a fraction of `balance`.
            return
                LibSafeMathV06.min256(
                    (balance * LibSafeMathV06.min256(rawAmount & LOWER_255_BITS, 1e18)) / 1e18,
                    balance
                );
        }
        return rawAmount;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";

/// @dev A transformation callback used in `TransformERC20.transformERC20()`.
interface IERC20Transformer {
    /// @dev Context information to pass into `transform()` by `TransformERC20.transformERC20()`.
    struct TransformContext {
        // The caller of `TransformERC20.transformERC20()`.
        address payable sender;
        // The recipient address, which may be distinct from `sender` e.g. in
        // meta-transactions.
        address payable recipient;
        // Arbitrary data to pass to the transformer.
        bytes data;
    }

    /// @dev Called from `TransformERC20.transformERC20()`. This will be
    ///      delegatecalled in the context of the FlashWallet instance being used.
    /// @param context Context information.
    /// @return success The success bytes (`LibERC20Transformer.TRANSFORMER_SUCCESS`).
    function transform(TransformContext calldata context) external returns (bytes4 success);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";

library LibERC20Transformer {
    using LibERC20TokenV06 for IERC20TokenV06;

    /// @dev ETH pseudo-token address.
    address internal constant ETH_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    /// @dev ETH pseudo-token.
    IERC20TokenV06 internal constant ETH_TOKEN = IERC20TokenV06(ETH_TOKEN_ADDRESS);
    /// @dev Return value indicating success in `IERC20Transformer.transform()`.
    ///      This is just `keccak256('TRANSFORMER_SUCCESS')`.
    bytes4 internal constant TRANSFORMER_SUCCESS = 0x13c9929e;

    /// @dev Transfer ERC20 tokens and ETH. Since it relies on `transfer` it may run out of gas when
    /// the `recipient` is a smart contract wallet. See `unsafeTransformerTransfer` for smart contract
    /// compatible transfer.
    /// @param token An ERC20 or the ETH pseudo-token address (`ETH_TOKEN_ADDRESS`).
    /// @param to The recipient.
    /// @param amount The transfer amount.
    function transformerTransfer(IERC20TokenV06 token, address payable to, uint256 amount) internal {
        if (isTokenETH(token)) {
            to.transfer(amount);
        } else {
            token.compatTransfer(to, amount);
        }
    }

    /// @dev Transfer ERC20 tokens and ETH. For ETH transfer. It's not safe from re-entrancy attacks and the
    /// caller is responsible for gurading against a potential re-entrancy attack.
    /// @param token An ERC20 or the ETH pseudo-token address (`ETH_TOKEN_ADDRESS`).
    /// @param to The recipient.
    /// @param amount The transfer amount.
    function unsafeTransformerTransfer(IERC20TokenV06 token, address payable to, uint256 amount) internal {
        if (isTokenETH(token)) {
            (bool sent, ) = to.call{value: amount}("");
            require(sent, "LibERC20Transformer/FAILED_TO_SEND_ETHER");
        } else {
            token.compatTransfer(to, amount);
        }
    }

    /// @dev Check if a token is the ETH pseudo-token.
    /// @param token The token to check.
    /// @return isETH `true` if the token is the ETH pseudo-token.
    function isTokenETH(IERC20TokenV06 token) internal pure returns (bool isETH) {
        return address(token) == ETH_TOKEN_ADDRESS;
    }

    /// @dev Check the balance of an ERC20 token or ETH.
    /// @param token An ERC20 or the ETH pseudo-token address (`ETH_TOKEN_ADDRESS`).
    /// @param owner Holder of the tokens.
    /// @return tokenBalance The balance of `owner`.
    function getTokenBalanceOf(IERC20TokenV06 token, address owner) internal view returns (uint256 tokenBalance) {
        if (isTokenETH(token)) {
            return owner.balance;
        }
        return token.balanceOf(owner);
    }

    /// @dev RLP-encode a 32-bit or less account nonce.
    /// @param nonce A positive integer in the range 0 <= nonce < 2^32.
    /// @return rlpNonce The RLP encoding.
    function rlpEncodeNonce(uint32 nonce) internal pure returns (bytes memory rlpNonce) {
        // See https://github.com/ethereum/wiki/wiki/RLP for RLP encoding rules.
        if (nonce == 0) {
            rlpNonce = new bytes(1);
            rlpNonce[0] = 0x80;
        } else if (nonce < 0x80) {
            rlpNonce = new bytes(1);
            rlpNonce[0] = bytes1(uint8(nonce));
        } else if (nonce <= 0xFF) {
            rlpNonce = new bytes(2);
            rlpNonce[0] = 0x81;
            rlpNonce[1] = bytes1(uint8(nonce));
        } else if (nonce <= 0xFFFF) {
            rlpNonce = new bytes(3);
            rlpNonce[0] = 0x82;
            rlpNonce[1] = bytes1(uint8((nonce & 0xFF00) >> 8));
            rlpNonce[2] = bytes1(uint8(nonce));
        } else if (nonce <= 0xFFFFFF) {
            rlpNonce = new bytes(4);
            rlpNonce[0] = 0x83;
            rlpNonce[1] = bytes1(uint8((nonce & 0xFF0000) >> 16));
            rlpNonce[2] = bytes1(uint8((nonce & 0xFF00) >> 8));
            rlpNonce[3] = bytes1(uint8(nonce));
        } else {
            rlpNonce = new bytes(5);
            rlpNonce[0] = 0x84;
            rlpNonce[1] = bytes1(uint8((nonce & 0xFF000000) >> 24));
            rlpNonce[2] = bytes1(uint8((nonce & 0xFF0000) >> 16));
            rlpNonce[3] = bytes1(uint8((nonce & 0xFF00) >> 8));
            rlpNonce[4] = bytes1(uint8(nonce));
        }
    }

    /// @dev Compute the expected deployment address by `deployer` at
    ///      the nonce given by `deploymentNonce`.
    /// @param deployer The address of the deployer.
    /// @param deploymentNonce The nonce that the deployer had when deploying
    ///        a contract.
    /// @return deploymentAddress The deployment address.
    function getDeployedAddress(
        address deployer,
        uint32 deploymentNonce
    ) internal pure returns (address payable deploymentAddress) {
        // The address of if a deployed contract is the lower 20 bytes of the
        // hash of the RLP-encoded deployer's account address + account nonce.
        // See: https://ethereum.stackexchange.com/questions/760/how-is-the-address-of-an-ethereum-contract-computed
        bytes memory rlpNonce = rlpEncodeNonce(deploymentNonce);
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                bytes1(uint8(0xC0 + 21 + rlpNonce.length)),
                                bytes1(uint8(0x80 + 20)),
                                deployer,
                                rlpNonce
                            )
                        )
                    )
                )
            );
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./Transformer.sol";
import "./LibERC20Transformer.sol";

/// @dev A transformer that just emits an event with an arbitrary byte payload.
contract LogMetadataTransformer is Transformer {
    event TransformerMetadata(address sender, address taker, bytes data);

    /// @dev Maximum uint256 value.
    uint256 private constant MAX_UINT256 = uint256(-1);

    /// @dev Emits an event.
    /// @param context Context information.
    /// @return success The success bytes (`LibERC20Transformer.TRANSFORMER_SUCCESS`).
    function transform(TransformContext calldata context) external override returns (bytes4 success) {
        emit TransformerMetadata(context.sender, context.recipient, context.data);
        return LibERC20Transformer.TRANSFORMER_SUCCESS;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "../errors/LibTransformERC20RichErrors.sol";
import "./Transformer.sol";
import "./LibERC20Transformer.sol";

/// @dev A transformer that transfers tokens to the taker.
contract PayTakerTransformer is Transformer {
    using LibRichErrorsV06 for bytes;
    using LibSafeMathV06 for uint256;
    using LibERC20Transformer for IERC20TokenV06;

    /// @dev Transform data to ABI-encode and pass into `transform()`.
    struct TransformData {
        // The tokens to transfer to the taker.
        IERC20TokenV06[] tokens;
        // Amount of each token in `tokens` to transfer to the taker.
        // `uint(-1)` will transfer the entire balance.
        uint256[] amounts;
    }

    /// @dev Maximum uint256 value.
    uint256 private constant MAX_UINT256 = uint256(-1);

    /// @dev Create this contract.
    constructor() public Transformer() {}

    /// @dev Forwards tokens to the taker.
    /// @param context Context information.
    /// @return success The success bytes (`LibERC20Transformer.TRANSFORMER_SUCCESS`).
    function transform(TransformContext calldata context) external override returns (bytes4 success) {
        TransformData memory data = abi.decode(context.data, (TransformData));

        // Transfer tokens directly to the taker.
        for (uint256 i = 0; i < data.tokens.length; ++i) {
            // The `amounts` array can be shorter than the `tokens` array.
            // Missing elements are treated as `uint256(-1)`.
            uint256 amount = data.amounts.length > i ? data.amounts[i] : uint256(-1);
            if (amount == MAX_UINT256) {
                amount = data.tokens[i].getTokenBalanceOf(address(this));
            }
            if (amount != 0) {
                data.tokens[i].unsafeTransformerTransfer(context.recipient, amount);
            }
        }
        return LibERC20Transformer.TRANSFORMER_SUCCESS;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "../errors/LibTransformERC20RichErrors.sol";
import "./Transformer.sol";
import "./LibERC20Transformer.sol";

/// @dev A transformer that transfers tokens to arbitrary addresses.
contract PositiveSlippageFeeTransformer is Transformer {
    using LibRichErrorsV06 for bytes;
    using LibSafeMathV06 for uint256;
    using LibERC20Transformer for IERC20TokenV06;

    /// @dev Information for a single fee.
    struct TokenFee {
        // The token to transfer to `recipient`.
        IERC20TokenV06 token;
        // Amount of each `token` to transfer to `recipient`.
        uint256 bestCaseAmount;
        // Recipient of `token`.
        address payable recipient;
    }

    /// @dev Transfers tokens to recipients.
    /// @param context Context information.
    /// @return success The success bytes (`LibERC20Transformer.TRANSFORMER_SUCCESS`).
    function transform(TransformContext calldata context) external override returns (bytes4 success) {
        TokenFee memory fee = abi.decode(context.data, (TokenFee));

        uint256 transformerAmount = LibERC20Transformer.getTokenBalanceOf(fee.token, address(this));
        if (transformerAmount > fee.bestCaseAmount) {
            uint256 positiveSlippageAmount = transformerAmount - fee.bestCaseAmount;
            fee.token.unsafeTransformerTransfer(fee.recipient, positiveSlippageAmount);
        }

        return LibERC20Transformer.TRANSFORMER_SUCCESS;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "../errors/LibTransformERC20RichErrors.sol";
import "./IERC20Transformer.sol";

/// @dev Abstract base class for transformers.
abstract contract Transformer is IERC20Transformer {
    using LibRichErrorsV06 for bytes;

    /// @dev The address of the deployer.
    address public immutable deployer;
    /// @dev The original address of this contract.
    address internal immutable _implementation;

    /// @dev Create this contract.
    constructor() public {
        deployer = msg.sender;
        _implementation = address(this);
    }

    /// @dev Destruct this contract. Only callable by the deployer and will not
    ///      succeed in the context of a delegatecall (from another contract).
    /// @param ethRecipient The recipient of ETH held in this contract.
    function die(address payable ethRecipient) external virtual {
        // Only the deployer can call this.
        if (msg.sender != deployer) {
            LibTransformERC20RichErrors.OnlyCallableByDeployerError(msg.sender, deployer).rrevert();
        }
        // Must be executing our own context.
        if (address(this) != _implementation) {
            LibTransformERC20RichErrors.InvalidExecutionContextError(address(this), _implementation).rrevert();
        }
        selfdestruct(ethRecipient);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IEtherTokenV06.sol";
import "../errors/LibTransformERC20RichErrors.sol";
import "./Transformer.sol";
import "./LibERC20Transformer.sol";

/// @dev A transformer that wraps or unwraps WETH.
contract WethTransformer is Transformer {
    using LibRichErrorsV06 for bytes;
    using LibSafeMathV06 for uint256;
    using LibERC20Transformer for IERC20TokenV06;

    /// @dev Transform data to ABI-encode and pass into `transform()`.
    struct TransformData {
        // The token to wrap/unwrap. Must be either ETH or WETH.
        IERC20TokenV06 token;
        // Amount of `token` to wrap or unwrap.
        // `uint(-1)` will unwrap the entire balance.
        uint256 amount;
    }

    /// @dev The WETH contract address.
    IEtherTokenV06 public immutable weth;
    /// @dev Maximum uint256 value.
    uint256 private constant MAX_UINT256 = uint256(-1);

    /// @dev Construct the transformer and store the WETH address in an immutable.
    /// @param weth_ The weth token.
    constructor(IEtherTokenV06 weth_) public Transformer() {
        weth = weth_;
    }

    /// @dev Wraps and unwraps WETH.
    /// @param context Context information.
    /// @return success The success bytes (`LibERC20Transformer.TRANSFORMER_SUCCESS`).
    function transform(TransformContext calldata context) external override returns (bytes4 success) {
        TransformData memory data = abi.decode(context.data, (TransformData));
        if (!data.token.isTokenETH() && data.token != weth) {
            LibTransformERC20RichErrors
                .InvalidTransformDataError(
                    LibTransformERC20RichErrors.InvalidTransformDataErrorCode.INVALID_TOKENS,
                    context.data
                )
                .rrevert();
        }

        uint256 amount = data.amount;
        if (amount == MAX_UINT256) {
            amount = data.token.getTokenBalanceOf(address(this));
        }

        if (amount != 0) {
            if (data.token.isTokenETH()) {
                // Wrap ETH.
                weth.deposit{value: amount}();
            } else {
                // Unwrap WETH.
                weth.withdraw(amount);
            }
        }
        return LibERC20Transformer.TRANSFORMER_SUCCESS;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6;
pragma experimental ABIEncoderV2;

interface IERC1155Token {
    /// @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred,
    ///      including zero value transfers as well as minting or burning.
    /// Operator will always be msg.sender.
    /// Either event from address `0x0` signifies a minting operation.
    /// An event to address `0x0` signifies a burning or melting operation.
    /// The total value transferred from address 0x0 minus the total value transferred to 0x0 may
    /// be used by clients and exchanges to be added to the "circulating supply" for a given token ID.
    /// To define a token ID with no initial balance, the contract SHOULD emit the TransferSingle event
    /// from `0x0` to `0x0`, with the token creator as `_operator`.
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /// @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred,
    ///      including zero value transfers as well as minting or burning.
    ///Operator will always be msg.sender.
    /// Either event from address `0x0` signifies a minting operation.
    /// An event to address `0x0` signifies a burning or melting operation.
    /// The total value transferred from address 0x0 minus the total value transferred to 0x0 may
    /// be used by clients and exchanges to be added to the "circulating supply" for a given token ID.
    /// To define multiple token IDs with no initial balance, this SHOULD emit the TransferBatch event
    /// from `0x0` to `0x0`, with the token creator as `_operator`.
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /// @dev MUST emit when an approval is updated.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /// @dev MUST emit when the URI is updated for a token ID.
    /// URIs are defined in RFC 3986.
    /// The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata JSON Schema".
    event URI(string value, uint256 indexed id);

    /// @notice Transfers value amount of an _id from the _from address to the _to address specified.
    /// @dev MUST emit TransferSingle event on success.
    /// Caller must be approved to manage the _from account's tokens (see isApprovedForAll).
    /// MUST throw if `_to` is the zero address.
    /// MUST throw if balance of sender for token `_id` is lower than the `_value` sent.
    /// MUST throw on any other error.
    /// When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0).
    /// If so, it MUST call `onERC1155Received` on `_to` and revert if the return value
    /// is not `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`.
    /// @param from    Source address
    /// @param to      Target address
    /// @param id      ID of the token type
    /// @param value   Transfer amount
    /// @param data    Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data) external;

    /// @notice Send multiple types of Tokens from a 3rd party in one transfer (with safety call).
    /// @dev MUST emit TransferBatch event on success.
    /// Caller must be approved to manage the _from account's tokens (see isApprovedForAll).
    /// MUST throw if `_to` is the zero address.
    /// MUST throw if length of `_ids` is not the same as length of `_values`.
    ///  MUST throw if any of the balance of sender for token `_ids` is lower than the respective `_values` sent.
    /// MUST throw on any other error.
    /// When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0).
    /// If so, it MUST call `onERC1155BatchReceived` on `_to` and revert if the return value
    /// is not `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`.
    /// @param from    Source addresses
    /// @param to      Target addresses
    /// @param ids     IDs of each token type
    /// @param values  Transfer amounts per token type
    /// @param data    Additional data with no specified format, sent in call to `_to`
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;

    /// @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
    /// @dev MUST emit the ApprovalForAll event on success.
    /// @param operator  Address to add to the set of authorized operators
    /// @param approved  True if the operator is approved, false to revoke approval
    function setApprovalForAll(address operator, bool approved) external;

    /// @notice Queries the approval status of an operator for a given owner.
    /// @param owner        The owner of the Tokens
    /// @param operator     Address of authorized operator
    /// @return isApproved  True if the operator is approved, false if not
    function isApprovedForAll(address owner, address operator) external view returns (bool isApproved);

    /// @notice Get the balance of an account's Tokens.
    /// @param owner     The address of the token holder
    /// @param id        ID of the Token
    /// @return balance  The _owner's balance of the Token type requested
    function balanceOf(address owner, uint256 id) external view returns (uint256 balance);

    /// @notice Get the balance of multiple account/token pairs
    /// @param owners      The addresses of the token holders
    /// @param ids         ID of the Tokens
    /// @return balances_  The _owner's balance of the Token types requested
    function balanceOfBatch(
        address[] calldata owners,
        uint256[] calldata ids
    ) external view returns (uint256[] memory balances_);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6;

interface IERC721Token {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///      This event emits when NFTs are created (`from` == 0) and destroyed
    ///      (`to` == 0). Exception: during contract creation, any number of NFTs
    ///      may be created and assigned without emitting Transfer. At the time of
    ///      any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///      reaffirmed. The zero address indicates there is no approved address.
    ///      When a Transfer event emits, this also indicates that the approved
    ///      address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///      The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///      perator, or the approved address for this NFT. Throws if `_from` is
    ///      not the current owner. Throws if `_to` is the zero address. Throws if
    ///      `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///      checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///      `onERC721Received` on `_to` and throws if the return value is not
    ///      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param _data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///      except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///      Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///      operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///         all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///      multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///      function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///         TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///         THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///      operator, or the approved address for this NFT. Throws if `_from` is
    ///      not the current owner. Throws if `_to` is the zero address. Throws if
    ///      `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///      about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6;
pragma experimental ABIEncoderV2;

interface IFeeRecipient {
    /// @dev A callback function invoked in the ERC721Feature for each ERC721
    ///      order fee that get paid. Integrators can make use of this callback
    ///      to implement arbitrary fee-handling logic, e.g. splitting the fee
    ///      between multiple parties.
    /// @param tokenAddress The address of the token in which the received fee is
    ///        denominated. `0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE` indicates
    ///        that the fee was paid in the native token (e.g. ETH).
    /// @param amount The amount of the given token received.
    /// @param feeData Arbitrary data encoded in the `Fee` used by this callback.
    /// @return success The selector of this function (0x0190805e),
    ///         indicating that the callback succeeded.
    function receiveZeroExFeeCallback(
        address tokenAddress,
        uint256 amount,
        bytes calldata feeData
    ) external returns (bytes4 success);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";

interface ILiquidityProvider {
    /// @dev An optional event an LP can emit for each fill against a source.
    /// @param inputToken The input token.
    /// @param outputToken The output token.
    /// @param inputTokenAmount How much input token was sold.
    /// @param outputTokenAmount How much output token was bought.
    /// @param sourceId A bytes32 encoded ascii source ID. E.g., `bytes32('Curve')`/
    /// @param sourceAddress An optional address associated with the source (e.g, a curve pool).
    /// @param sourceId A bytes32 encoded ascii source ID. E.g., `bytes32('Curve')`/
    /// @param sourceAddress An optional address associated with the source (e.g, a curve pool).
    /// @param sender The caller of the LP.
    /// @param recipient The recipient of the output tokens.
    event LiquidityProviderFill(
        IERC20TokenV06 inputToken,
        IERC20TokenV06 outputToken,
        uint256 inputTokenAmount,
        uint256 outputTokenAmount,
        bytes32 sourceId,
        address sourceAddress,
        address sender,
        address recipient
    );

    /// @dev Trades `inputToken` for `outputToken`. The amount of `inputToken`
    ///      to sell must be transferred to the contract prior to calling this
    ///      function to trigger the trade.
    /// @param inputToken The token being sold.
    /// @param outputToken The token being bought.
    /// @param recipient The recipient of the bought tokens.
    /// @param minBuyAmount The minimum acceptable amount of `outputToken` to buy.
    /// @param auxiliaryData Arbitrary auxiliary data supplied to the contract.
    /// @return boughtAmount The amount of `outputToken` bought.
    function sellTokenForToken(
        IERC20TokenV06 inputToken,
        IERC20TokenV06 outputToken,
        address recipient,
        uint256 minBuyAmount,
        bytes calldata auxiliaryData
    ) external returns (uint256 boughtAmount);

    /// @dev Trades ETH for token. ETH must either be attached to this function
    ///      call or sent to the contract prior to calling this function to
    ///      trigger the trade.
    /// @param outputToken The token being bought.
    /// @param recipient The recipient of the bought tokens.
    /// @param minBuyAmount The minimum acceptable amount of `outputToken` to buy.
    /// @param auxiliaryData Arbitrary auxiliary data supplied to the contract.
    /// @return boughtAmount The amount of `outputToken` bought.
    function sellEthForToken(
        IERC20TokenV06 outputToken,
        address recipient,
        uint256 minBuyAmount,
        bytes calldata auxiliaryData
    ) external payable returns (uint256 boughtAmount);

    /// @dev Trades token for ETH. The token must be sent to the contract prior
    ///      to calling this function to trigger the trade.
    /// @param inputToken The token being sold.
    /// @param recipient The recipient of the bought tokens.
    /// @param minBuyAmount The minimum acceptable amount of ETH to buy.
    /// @param auxiliaryData Arbitrary auxiliary data supplied to the contract.
    /// @return boughtAmount The amount of ETH bought.
    function sellTokenForEth(
        IERC20TokenV06 inputToken,
        address payable recipient,
        uint256 minBuyAmount,
        bytes calldata auxiliaryData
    ) external returns (uint256 boughtAmount);

    /// @dev Quotes the amount of `outputToken` that would be obtained by
    ///      selling `sellAmount` of `inputToken`.
    /// @param inputToken Address of the taker token (what to sell). Use
    ///        the wETH address if selling ETH.
    /// @param outputToken Address of the maker token (what to buy). Use
    ///        the wETH address if buying ETH.
    /// @param sellAmount Amount of `inputToken` to sell.
    /// @return outputTokenAmount Amount of `outputToken` that would be obtained.
    function getSellQuote(
        IERC20TokenV06 inputToken,
        IERC20TokenV06 outputToken,
        uint256 sellAmount
    ) external view returns (uint256 outputTokenAmount);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IEtherTokenV06.sol";

/// @dev Moooniswap pool interface.
interface IMooniswapPool {
    function swap(
        IERC20TokenV06 sellToken,
        IERC20TokenV06 buyToken,
        uint256 sellAmount,
        uint256 minBoughtAmount,
        address referrer
    ) external payable returns (uint256 boughtAmount);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6;
pragma experimental ABIEncoderV2;

interface IPropertyValidator {
    /// @dev Checks that the given ERC721/ERC1155 asset satisfies the properties encoded in `propertyData`.
    ///      Should revert if the asset does not satisfy the specified properties.
    /// @param tokenAddress The ERC721/ERC1155 token contract address.
    /// @param tokenId The ERC721/ERC1155 tokenId of the asset to check.
    /// @param propertyData Encoded properties or auxiliary data needed to perform the check.
    function validateProperty(address tokenAddress, uint256 tokenId, bytes calldata propertyData) external view;
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6;
pragma experimental ABIEncoderV2;

interface ITakerCallback {
    /// @dev A taker callback function invoked in ERC721OrdersFeature and
    ///      ERC1155OrdersFeature between the maker -> taker transfer and
    ///      the taker -> maker transfer.
    /// @param orderHash The hash of the order being filled when this
    ///        callback is invoked.
    /// @param callbackData Arbitrary data used by this callback.
    /// @return success The selector of this function,
    ///         indicating that the callback succeeded.
    function zeroExTakerCallback(bytes32 orderHash, bytes calldata callbackData) external returns (bytes4 success);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.12;

interface IUniswapV2Pair {
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.12;

interface IUniswapV3Pool {
    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive),
    /// or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;

interface IERC20Bridge {
    /// @dev Emitted when a trade occurs.
    /// @param inputToken The token the bridge is converting from.
    /// @param outputToken The token the bridge is converting to.
    /// @param inputTokenAmount Amount of input token.
    /// @param outputTokenAmount Amount of output token.
    /// @param from The `from` address in `bridgeTransferFrom()`
    /// @param to The `to` address in `bridgeTransferFrom()`
    event ERC20BridgeTransfer(
        address inputToken,
        address outputToken,
        uint256 inputTokenAmount,
        uint256 outputTokenAmount,
        address from,
        address to
    );

    /// @dev Transfers `amount` of the ERC20 `tokenAddress` from `from` to `to`.
    /// @param tokenAddress The address of the ERC20 token to transfer.
    /// @param from Address to transfer asset from.
    /// @param to Address to transfer asset to.
    /// @param amount Amount of asset to transfer.
    /// @param bridgeData Arbitrary asset data needed by the bridge contract.
    /// @return success The magic bytes `0xdc1600f3` if successful.
    function bridgeTransferFrom(
        address tokenAddress,
        address from,
        address to,
        uint256 amount,
        bytes calldata bridgeData
    ) external returns (bytes4 success);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;

interface IStaking {
    function joinStakingPoolAsMaker(bytes32) external;

    function payProtocolFee(address, address, uint256) external payable;
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/LibBytesV06.sol";
import "./migrations/LibBootstrap.sol";
import "./features/BootstrapFeature.sol";
import "./storage/LibProxyStorage.sol";
import "./errors/LibProxyRichErrors.sol";


/// @dev An extensible proxy contract that serves as a universal entry point for
///      interacting with the 0x protocol.
contract ZeroEx {
    // solhint-disable separate-by-one-line-in-contract,indent,var-name-mixedcase
    using LibBytesV06 for bytes;

    /// @dev Construct this contract and register the `BootstrapFeature` feature.
    ///      After constructing this contract, `bootstrap()` should be called
    ///      by `bootstrap()` to seed the initial feature set.
    /// @param bootstrapper Who can call `bootstrap()`.
    constructor(address bootstrapper) public {
        // Temporarily create and register the bootstrap feature.
        // It will deregister itself after `bootstrap()` has been called.
        BootstrapFeature bootstrap = new BootstrapFeature(bootstrapper);
        LibProxyStorage.getStorage().impls[bootstrap.bootstrap.selector] =
            address(bootstrap);
    }

    // solhint-disable state-visibility

    /// @dev Forwards calls to the appropriate implementation contract.
    fallback() external payable {
        bytes4 selector = msg.data.readBytes4(0);
        address impl = getFunctionImplementation(selector);
        if (impl == address(0)) {
            _revertWithData(LibProxyRichErrors.NotImplementedError(selector));
        }

        (bool success, bytes memory resultData) = impl.delegatecall(msg.data);
        if (!success) {
            _revertWithData(resultData);
        }
        _returnWithData(resultData);
    }

    /// @dev Fallback for just receiving ether.
    receive() external payable {}

    // solhint-enable state-visibility

    /// @dev Get the implementation contract of a registered function.
    /// @param selector The function selector.
    /// @return impl The implementation contract address.
    function getFunctionImplementation(bytes4 selector)
        public
        view
        returns (address impl)
    {
        return LibProxyStorage.getStorage().impls[selector];
    }

    /// @dev Revert with arbitrary bytes.
    /// @param data Revert data.
    function _revertWithData(bytes memory data) private pure {
        assembly { revert(add(data, 32), mload(data)) }
    }

    /// @dev Return with arbitrary bytes.
    /// @param data Return data.
    function _returnWithData(bytes memory data) private pure {
        assembly { return(add(data, 32), mload(data)) }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./features/BootstrapFeature.sol";
import "./storage/LibProxyStorage.sol";

/// @dev An extensible proxy contract that serves as a universal entry point for
///      interacting with the 0x protocol. Optimized version of ZeroEx.
contract ZeroExOptimized {
    /// @dev Construct this contract and register the `BootstrapFeature` feature.
    ///      After constructing this contract, `bootstrap()` should be called
    ///      by `bootstrap()` to seed the initial feature set.
    /// @param bootstrapper Who can call `bootstrap()`.
    constructor(address bootstrapper) public {
        // Temporarily create and register the bootstrap feature.
        // It will deregister itself after `bootstrap()` has been called.
        BootstrapFeature bootstrap = new BootstrapFeature(bootstrapper);
        LibProxyStorage.getStorage().impls[bootstrap.bootstrap.selector] = address(bootstrap);
    }

    /// @dev Forwards calls to the appropriate implementation contract.
    fallback() external payable {
        // This is used in assembly below as impls_slot.
        mapping(bytes4 => address) storage impls = LibProxyStorage.getStorage().impls;

        assembly {
            let cdlen := calldatasize()

            // equivalent of receive() external payable {}
            if iszero(cdlen) {
                return(0, 0)
            }

            // Store at 0x40, to leave 0x00-0x3F for slot calculation below.
            calldatacopy(0x40, 0, cdlen)
            let selector := and(mload(0x40), 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)

            // Slot for impls[selector] is keccak256(selector . impls_slot).
            mstore(0, selector)
            mstore(0x20, impls_slot)
            let slot := keccak256(0, 0x40)

            let delegate := sload(slot)
            if iszero(delegate) {
                // Revert with:
                // abi.encodeWithSelector(
                //   bytes4(keccak256("NotImplementedError(bytes4)")),
                //   selector)
                mstore(0, 0x734e6e1c00000000000000000000000000000000000000000000000000000000)
                mstore(4, selector)
                revert(0, 0x24)
            }

            let success := delegatecall(gas(), delegate, 0x40, cdlen, 0, 0)
            let rdlen := returndatasize()
            returndatacopy(0, 0, rdlen)
            if success {
                return(0, rdlen)
            }
            revert(0, rdlen)
        }
    }
}