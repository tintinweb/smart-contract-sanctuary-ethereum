// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.9;
pragma abicoder v2;

import { TransactionData, Action, TokenAmount, Fee, AbsoluteTokenAmount, AmountType } from "../shared/Structs.sol";
import { ERC20 } from "../shared/ERC20.sol";
import { SafeERC20 } from "../shared/SafeERC20.sol";
import { ChiToken } from "../interfaces/ChiToken.sol";
import { SignatureVerifier } from "./SignatureVerifier.sol";
import { Ownable } from "./Ownable.sol";
import { Core } from "./Core.sol";

contract Router is SignatureVerifier("Zerion Router v1.1"), Ownable {
    using SafeERC20 for ERC20;

    address internal immutable core_;

    address internal constant CHI = 0x0000000000004946c0e9F43F4Dee607b0eF1fA1c;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 internal constant DELIMITER = 1e18; // 100%
    uint256 internal constant FEE_LIMIT = 1e16; // 1%

    event Executed(address indexed account, uint256 indexed share, address indexed beneficiary);
    event TokenTransfer(address indexed token, address indexed account, uint256 indexed amount);

    /**
     * @dev The amount used as second parameter of freeFromUpTo() function
     * is the solution of the following equation:
     * 21000 + calldataCost + executionCost + constBurnCost + n * perTokenBurnCost =
     * 2 * (24000 * n + otherRefunds)
     * Here,
     *     calldataCost = 7 * msg.data.length
     *     executionCost = 21000 + gasStart - gasleft()
     *     constBurnCost = 25171
     *     perTokenBurnCost = 6148
     *     otherRefunds = 0
     */
    modifier useCHI() {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 7 * msg.data.length;
        ChiToken(CHI).freeFromUpTo(msg.sender, (gasSpent + 25171) / 41852);
    }

    constructor(address payable core) {
        require(core != address(0), "R: empty core");

        core_ = core;
    }

    /**
     * @notice Returns tokens mistakenly sent to this contract.
     * @dev Can be called only by this contract's owner.
     */
    function returnLostTokens(address token, address payable beneficiary) external onlyOwner {
        if (token == ETH) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = beneficiary.call{ value: address(this).balance }(new bytes(0));
            require(success, "R: bad beneficiary");
        } else {
            ERC20(token).safeTransfer(beneficiary, ERC20(token).balanceOf(address(this)), "R");
        }
    }

    /**
     * @return Address of the Core contract used.
     */
    function getCore() external view returns (address) {
        return core_;
    }

    /**
     * @notice Executes actions and returns tokens to account.
     * Uses CHI tokens previously approved by the msg.sender.
     * @param data TransactionData struct with the following elements:
     *     - actions Array of actions to be executed.
     *     - inputs Array of tokens to be taken from the signer of this data.
     *     - fee Fee struct with fee details.
     *     - requiredOutputs Array of requirements for the returned tokens.
     *     - account Address of the account that will receive the returned tokens.
     *     - salt Number that makes this data unique.
     * @param signature EIP712-compatible signature of data.
     * @return Array of AbsoluteTokenAmount structs with the returned tokens.
     * @dev This function uses CHI token to refund some gas.
     */
    function executeWithCHI(TransactionData memory data, bytes memory signature)
        public
        payable
        useCHI
        returns (AbsoluteTokenAmount[] memory)
    {
        return execute(data, signature);
    }

    /**
     * @notice Executes actions and returns tokens to account.
     * Uses CHI tokens previously approved by the msg.sender.
     * @param actions Array of actions to be executed.
     * @param inputs Array of tokens to be taken from the msg.sender.
     * @param fee Fee struct with fee details.
     * @param requiredOutputs Array of requirements for the returned tokens.
     * @return Array of AbsoluteTokenAmount structs with the returned tokens.
     * @dev This function uses CHI token to refund some gas.
     */
    function executeWithCHI(
        Action[] memory actions,
        TokenAmount[] memory inputs,
        Fee memory fee,
        AbsoluteTokenAmount[] memory requiredOutputs
    ) public payable useCHI returns (AbsoluteTokenAmount[] memory) {
        return execute(actions, inputs, fee, requiredOutputs);
    }

    /**
     * @notice Executes actions and returns tokens to account.
     * @param data TransactionData struct with the following elements:
     *     - actions Array of actions to be executed.
     *     - inputs Array of tokens to be taken from the signer of this data.
     *     - fee Fee struct with fee details.
     *     - requiredOutputs Array of requirements for the returned tokens.
     *     - account Address of the account that will receive the returned tokens.
     *     - salt Number that makes this data unique.
     * @param signature EIP712-compatible signature of data.
     * @return Array of AbsoluteTokenAmount structs with the returned tokens.
     */
    function execute(TransactionData memory data, bytes memory signature)
        public
        payable
        returns (AbsoluteTokenAmount[] memory)
    {
        bytes32 hashedData = hashData(data);
        require(
            data.account == getAccountFromSignature(hashedData, signature),
            "R: wrong account"
        );

        markHashUsed(hashedData, data.account);

        return
            _execute(
                data.actions,
                data.inputs,
                data.fee,
                data.requiredOutputs,
                payable(data.account)
            );
    }

    /**
     * @notice Executes actions and returns tokens to account.
     * @param actions Array of actions to be executed.
     * @param inputs Array of tokens to be taken from the msg.sender.
     * @param fee Fee struct with fee details.
     * @param requiredOutputs Array of requirements for the returned tokens.
     * @return Array of AbsoluteTokenAmount structs with the returned tokens.
     */
    function execute(
        Action[] memory actions,
        TokenAmount[] memory inputs,
        Fee memory fee,
        AbsoluteTokenAmount[] memory requiredOutputs
    ) public payable returns (AbsoluteTokenAmount[] memory) {
        return _execute(actions, inputs, fee, requiredOutputs, payable(msg.sender));
    }

    /**
     * @dev Executes actions and returns tokens to account.
     * @param actions Array of actions to be executed.
     * @param inputs Array of tokens to be taken from the account address.
     * @param fee Fee struct with fee details.
     * @param requiredOutputs Array of requirements for the returned tokens.
     * @param account Address of the account that will receive the returned tokens.
     * @return Array of AbsoluteTokenAmount structs with the returned tokens.
     */
    function _execute(
        Action[] memory actions,
        TokenAmount[] memory inputs,
        Fee memory fee,
        AbsoluteTokenAmount[] memory requiredOutputs,
        address payable account
    ) internal returns (AbsoluteTokenAmount[] memory) {
        // Transfer tokens to Core contract, handle fees (if any), and add these tokens to outputs
        transferTokens(inputs, fee, account);
        AbsoluteTokenAmount[] memory modifiedOutputs = modifyOutputs(requiredOutputs, inputs);

        // Call Core contract with all provided ETH, actions, expected outputs and account address
        AbsoluteTokenAmount[] memory actualOutputs = Core(payable(core_)).executeActions(
            actions,
            modifiedOutputs,
            account
        );

        // Emit event so one could track account and fees of this tx.
        emit Executed(account, fee.share, fee.beneficiary);

        // Return tokens' addresses and amounts that were returned to the account address
        return actualOutputs;
    }

    /**
     * @dev Transfers tokens from account address to the core_ contract
     * and takes fees if needed.
     * @param inputs Array of tokens to be taken from the account address.
     * @param fee Fee struct with fee details.
     * @param account Address of the account tokens will be transferred from.
     */
    function transferTokens(
        TokenAmount[] memory inputs,
        Fee memory fee,
        address account
    ) internal {
        address token;
        uint256 absoluteAmount;
        uint256 feeAmount;
        uint256 length = inputs.length;

        if (fee.share > 0) {
            require(fee.beneficiary != address(0), "R: bad beneficiary");
            require(fee.share <= FEE_LIMIT, "R: bad fee");
        }

        for (uint256 i = 0; i < length; i++) {
            token = inputs[i].token;
            absoluteAmount = getAbsoluteAmount(inputs[i], account);
            require(absoluteAmount > 0, "R: zero amount");

            feeAmount = mul(absoluteAmount, fee.share) / DELIMITER;

            if (feeAmount > 0) {
                ERC20(token).safeTransferFrom(account, fee.beneficiary, feeAmount, "R[1]");
            }

            ERC20(token).safeTransferFrom(account, core_, absoluteAmount - feeAmount, "R[2]");
            emit TokenTransfer(token, account, absoluteAmount - feeAmount);
        }

        if (msg.value > 0) {
            feeAmount = mul(msg.value, fee.share) / DELIMITER;

            if (feeAmount > 0) {
                // solhint-disable-next-line avoid-low-level-calls
                (bool success1, ) = fee.beneficiary.call{ value: feeAmount }(new bytes(0));
                require(success1, "ETH transfer to beneficiary failed");
            }

            // solhint-disable-next-line avoid-low-level-calls
            (bool success2, ) = core_.call{ value: msg.value - feeAmount }(new bytes(0));
            require(success2, "ETH transfer to Core failed");
            emit TokenTransfer(ETH, account, msg.value - feeAmount);
        }
    }

    /**
     * @dev Returns the absolute token amount given the TokenAmount struct.
     * @param tokenAmount TokenAmount struct with token address, amount, and amount type.
     * @param account Address of the account absolute token amount will be calculated for.
     * @return Absolute token amount.
     */
    function getAbsoluteAmount(TokenAmount memory tokenAmount, address account)
        internal
        view
        returns (uint256)
    {
        address token = tokenAmount.token;
        AmountType amountType = tokenAmount.amountType;
        uint256 amount = tokenAmount.amount;

        require(
            amountType == AmountType.Relative || amountType == AmountType.Absolute,
            "R: bad amount type"
        );

        if (amountType == AmountType.Relative) {
            require(amount <= DELIMITER, "R: bad amount");
            if (amount == DELIMITER) {
                return ERC20(token).balanceOf(account);
            } else {
                return mul(ERC20(token).balanceOf(account), amount) / DELIMITER;
            }
        } else {
            return amount;
        }
    }

    /**
     * @dev Appends tokens from inputs to the requiredOutputs list.
     * @return Array of AbsoluteTokenAmount structs with the resulting tokens.
     */
    function modifyOutputs(
        AbsoluteTokenAmount[] memory requiredOutputs,
        TokenAmount[] memory inputs
    ) internal view returns (AbsoluteTokenAmount[] memory) {
        uint256 ethInput = msg.value > 0 ? 1 : 0;
        AbsoluteTokenAmount[] memory modifiedOutputs = new AbsoluteTokenAmount[](
            requiredOutputs.length + inputs.length + ethInput
        );

        for (uint256 i = 0; i < requiredOutputs.length; i++) {
            modifiedOutputs[i] = requiredOutputs[i];
        }

        for (uint256 i = 0; i < inputs.length; i++) {
            modifiedOutputs[requiredOutputs.length + i] = AbsoluteTokenAmount({
                token: inputs[i].token,
                amount: 0
            });
        }

        if (ethInput > 0) {
            modifiedOutputs[requiredOutputs.length + inputs.length] = AbsoluteTokenAmount({
                token: ETH,
                amount: 0
            });
        }

        return modifiedOutputs;
    }

    /**
     * @dev Safe multiplication operation.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "R: mul overflow");

        return c;
    }
}

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.9;
pragma abicoder v2;

// The struct consists of TokenBalanceMeta structs for
// (base) token and its underlying tokens (if any).
struct FullTokenBalance {
    TokenBalanceMeta base;
    TokenBalanceMeta[] underlying;
}

// The struct consists of TokenBalance struct
// with token address and absolute amount
// and ERC20Metadata struct with ERC20-style metadata.
// NOTE: 0xEeee...EEeE address is used for ETH.
struct TokenBalanceMeta {
    TokenBalance tokenBalance;
    ERC20Metadata erc20metadata;
}

// The struct consists of ERC20-style token metadata.
struct ERC20Metadata {
    string name;
    string symbol;
    uint8 decimals;
}

// The struct consists of protocol adapter's name
// and array of TokenBalance structs
// with token addresses and absolute amounts.
struct AdapterBalance {
    bytes32 protocolAdapterName;
    TokenBalance[] tokenBalances;
}

// The struct consists of token address
// and its absolute amount (may be negative).
// 0xEeee...EEeE is used for Ether
struct TokenBalance {
    address token;
    int256 amount;
}

// The struct consists of token address,
// and price per full share (1e18).
// 0xEeee...EEeE is used for Ether
struct Component {
    address token;
    int256 rate;
}

//=============================== Interactive Adapters Structs ====================================

// The struct consists of array of actions, array of inputs,
// fee, array of required outputs, account,
// and salt parameter used to protect users from double spends.
struct TransactionData {
    Action[] actions;
    TokenAmount[] inputs;
    Fee fee;
    AbsoluteTokenAmount[] requiredOutputs;
    address account;
    uint256 salt;
}

// The struct consists of name of the protocol adapter,
// action type, array of token amounts,
// and some additional data (depends on the protocol).
struct Action {
    bytes32 protocolAdapterName;
    ActionType actionType;
    TokenAmount[] tokenAmounts;
    bytes data;
}

// The struct consists of token address
// its amount and amount type.
// 0xEeee...EEeE is used for Ether
struct TokenAmount {
    address token;
    uint256 amount;
    AmountType amountType;
}

// The struct consists of fee share
// and beneficiary address.
struct Fee {
    uint256 share;
    address beneficiary;
}

// The struct consists of token address
// and its absolute amount.
// 0xEeee...EEeE is used for Ether
struct AbsoluteTokenAmount {
    address token;
    uint256 amount;
}

enum ActionType {
    None,
    Deposit,
    Withdraw
}

enum AmountType {
    None,
    Relative,
    Absolute
}

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.9;

import "./ERC20.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token contract
 * returns false). Tokens that return no value (and instead revert or throw on failure)
 * are also supported, non-reverting calls are assumed to be successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    function safeTransfer(
        ERC20 token,
        address to,
        uint256 value,
        string memory location
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value),
            "transfer",
            location
        );
    }

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 value,
        string memory location
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value),
            "transferFrom",
            location
        );
    }

    function safeApprove(
        ERC20 token,
        address spender,
        uint256 value,
        string memory location
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            string(abi.encodePacked("SafeERC20: bad approve call from ", location))
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value),
            "approve",
            location
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract),
     * relaxing the requirement on the return value: the return value is optional
     * (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     * @param location Location of the call (for debug).
     */
    function callOptionalReturn(
        ERC20 token,
        bytes memory data,
        string memory functionName,
        string memory location
    ) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking
        // mechanism, since we're implementing it ourselves.

        // We implement two-steps call as callee is a contract is a responsibility of a caller.
        //  1. The call itself is made, and success asserted
        //  2. The return value is decoded, which in turn checks the size of the returned data.

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(
            success,
            string(abi.encodePacked("SafeERC20: ", functionName, " failed in ", location))
        );

        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                string(
                    abi.encodePacked("SafeERC20: ", functionName, " returned false in ", location)
                )
            );
        }
    }
}

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.9;
pragma abicoder v2;

/**
 * @notice Library helps to convert different types to strings.
 * @author Igor Sobolev <[email protected]>
 */
library Helpers {
    /**
     * @dev Internal function to convert bytes32 to string and trim zeroes.
     */
    function toString(bytes32 data) internal pure returns (string memory) {
        uint256 counter = 0;
        for (uint256 i = 0; i < 32; i++) {
            if (data[i] != bytes1(0)) {
                counter++;
            }
        }

        bytes memory result = new bytes(counter);
        counter = 0;
        for (uint256 i = 0; i < 32; i++) {
            if (data[i] != bytes1(0)) {
                result[counter] = data[i];
                counter++;
            }
        }

        return string(result);
    }

    /**
     * @dev Internal function to convert uint256 to string.
     */
    function toString(uint256 data) internal pure returns (string memory) {
        if (data == uint256(0)) {
            return "0";
        }

        uint256 length = 0;

        uint256 dataCopy = data;
        while (dataCopy != 0) {
            length++;
            dataCopy /= 10;
        }

        bytes memory result = new bytes(length);
        dataCopy = data;

        // Here, we have on-purpose underflow cause we need case `i = 0` to be included in the loop
        for (uint256 i = length - 1; i < length; i--) {
            result[i] = bytes1(uint8(48 + (dataCopy % 10)));
            dataCopy /= 10;
        }

        return string(result);
    }

    /**
     * @dev Internal function to convert address to string.
     */
    function toString(address data) internal pure returns (string memory) {
        bytes memory bytesData = abi.encodePacked(data);

        bytes memory result = new bytes(42);
        result[0] = "0";
        result[1] = "x";

        for (uint256 i = 0; i < 20; i++) {
            result[i * 2 + 2] = char(bytesData[i] >> 4); // First char of byte
            result[i * 2 + 3] = char(bytesData[i] & 0x0f); // Second char of byte
        }

        return string(result);
    }

    function char(bytes1 byteChar) internal pure returns (bytes1) {
        uint8 uintChar = uint8(byteChar);
        return uintChar < 10 ? bytes1(uintChar + 48) : bytes1(uintChar + 87);
    }
}

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.9;
pragma abicoder v2;

interface ERC20 {
    function approve(address, uint256) external returns (bool);

    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);
}

// File is downloaded from
// openzeppelin-contracts/v3.2.1-solc-0.7/contracts/cryptography/ECDSA.sol
// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("ECDSA: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECDSA: invalid signature 'v' value");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }
}

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.9;

/**
 * @dev ChiToken contract interface.
 * The ChiToken contract is available here
 * github.com/1inch-exchange/chi/blob/master/contracts/ChiToken.sol.
 */
interface ChiToken {
    function freeFromUpTo(address, uint256) external;
}

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.9;
pragma abicoder v2;

import { ProtocolAdapter } from "../adapters/ProtocolAdapter.sol";
import { TokenAmount, AmountType } from "../shared/Structs.sol";
import { ERC20 } from "../shared/ERC20.sol";

/**
 * @title Base contract for interactive protocol adapters.
 * @dev deposit() and withdraw() functions MUST be implemented
 * as well as all the functions from ProtocolAdapter abstract contract.
 * @author Igor Sobolev <[email protected]>
 */
abstract contract InteractiveAdapter is ProtocolAdapter {
    uint256 internal constant DELIMITER = 1e18;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @dev The function must deposit assets to the protocol.
     * @return MUST return assets to be sent back to the `msg.sender`.
     */
    function deposit(TokenAmount[] calldata tokenAmounts, bytes calldata data)
        external
        payable
        virtual
        returns (address[] memory);

    /**
     * @dev The function must withdraw assets from the protocol.
     * @return MUST return assets to be sent back to the `msg.sender`.
     */
    function withdraw(TokenAmount[] calldata tokenAmounts, bytes calldata data)
        external
        payable
        virtual
        returns (address[] memory);

    function getAbsoluteAmountDeposit(TokenAmount calldata tokenAmount)
        internal
        view
        virtual
        returns (uint256)
    {
        address token = tokenAmount.token;
        uint256 amount = tokenAmount.amount;
        AmountType amountType = tokenAmount.amountType;

        require(
            amountType == AmountType.Relative || amountType == AmountType.Absolute,
            "IA: bad amount type"
        );
        if (amountType == AmountType.Relative) {
            require(amount <= DELIMITER, "IA: bad amount");

            uint256 balance;
            if (token == ETH) {
                balance = address(this).balance;
            } else {
                balance = ERC20(token).balanceOf(address(this));
            }

            if (amount == DELIMITER) {
                return balance;
            } else {
                return mul(balance, amount) / DELIMITER;
            }
        } else {
            return amount;
        }
    }

    function getAbsoluteAmountWithdraw(TokenAmount calldata tokenAmount)
        internal
        virtual
        returns (uint256)
    {
        address token = tokenAmount.token;
        uint256 amount = tokenAmount.amount;
        AmountType amountType = tokenAmount.amountType;

        require(
            amountType == AmountType.Relative || amountType == AmountType.Absolute,
            "IA: bad amount type"
        );
        if (amountType == AmountType.Relative) {
            require(amount <= DELIMITER, "IA: bad amount");

            int256 balanceSigned = getBalance(token, address(this));
            uint256 balance = balanceSigned > 0 ? uint256(balanceSigned) : uint256(-balanceSigned);
            if (amount == DELIMITER) {
                return balance;
            } else {
                return mul(balance, amount) / DELIMITER;
            }
        } else {
            return amount;
        }
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "IA: mul overflow");

        return c;
    }
}

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.9;
pragma abicoder v2;

import { TransactionData, Action, AbsoluteTokenAmount, Fee, TokenAmount } from "../shared/Structs.sol";
import { ECDSA } from "../shared/ECDSA.sol";

contract SignatureVerifier {
    mapping(bytes32 => mapping(address => bool)) internal isHashUsed_;

    bytes32 internal immutable nameHash_;

    bytes32 internal constant DOMAIN_SEPARATOR_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "EIP712Domain(",
                "string name,",
                "uint256 chainId,",
                "address verifyingContract",
                ")"
            )
        );
    bytes32 internal constant TX_DATA_TYPEHASH =
        keccak256(
            abi.encodePacked(
                TX_DATA_ENCODED_TYPE,
                ABSOLUTE_TOKEN_AMOUNT_ENCODED_TYPE,
                ACTION_ENCODED_TYPE,
                FEE_ENCODED_TYPE,
                TOKEN_AMOUNT_ENCODED_TYPE
            )
        );
    bytes32 internal constant ABSOLUTE_TOKEN_AMOUNT_TYPEHASH =
        keccak256(ABSOLUTE_TOKEN_AMOUNT_ENCODED_TYPE);
    bytes32 internal constant ACTION_TYPEHASH =
        keccak256(abi.encodePacked(ACTION_ENCODED_TYPE, TOKEN_AMOUNT_ENCODED_TYPE));
    bytes32 internal constant FEE_TYPEHASH = keccak256(FEE_ENCODED_TYPE);
    bytes32 internal constant TOKEN_AMOUNT_TYPEHASH = keccak256(TOKEN_AMOUNT_ENCODED_TYPE);

    bytes internal constant TX_DATA_ENCODED_TYPE =
        abi.encodePacked(
            "TransactionData(",
            "Action[] actions,",
            "TokenAmount[] inputs,",
            "Fee fee,",
            "AbsoluteTokenAmount[] requiredOutputs,",
            "address account,",
            "uint256 salt",
            ")"
        );
    bytes internal constant ABSOLUTE_TOKEN_AMOUNT_ENCODED_TYPE =
        abi.encodePacked("AbsoluteTokenAmount(", "address token,", "uint256 amount", ")");
    bytes internal constant ACTION_ENCODED_TYPE =
        abi.encodePacked(
            "Action(",
            "bytes32 protocolAdapterName,",
            "uint8 actionType,",
            "TokenAmount[] tokenAmounts,",
            "bytes data",
            ")"
        );
    bytes internal constant FEE_ENCODED_TYPE =
        abi.encodePacked("Fee(", "uint256 share,", "address beneficiary", ")");
    bytes internal constant TOKEN_AMOUNT_ENCODED_TYPE =
        abi.encodePacked(
            "TokenAmount(",
            "address token,",
            "uint256 amount,",
            "uint8 amountType",
            ")"
        );

    constructor(string memory name) {
        nameHash_ = keccak256(abi.encodePacked(name));
    }

    /**
     * @param hashBytes Hash to be checked.
     * @param account Address of the hash will be checked for.
     * @return True if hash has already been used by this account address.
     */
    function isHashUsed(bytes32 hashBytes, address account) public view returns (bool) {
        return isHashUsed_[hashBytes][account];
    }

    /**
     * @param hashedData Hash to be checked.
     * @param signature EIP-712 signature.
     * @return Account that signed the hashed data.
     */
    function getAccountFromSignature(bytes32 hashedData, bytes memory signature)
        public
        pure
        returns (address payable)
    {
        return payable(ECDSA.recover(hashedData, signature));
    }

    /**
     * @param data TransactionData struct to be hashed.
     * @return TransactionData struct hashed with domainSeparator.
     */
    function hashData(TransactionData memory data) public view returns (bytes32) {
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_SEPARATOR_TYPEHASH, nameHash_, getChainId(), address(this))
        );

        return
            keccak256(abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator, hash(data)));
    }

    /**
     * @dev Marks hash as used by the given account.
     * @param hashBytes Hash to be marked is used.
     * @param account Account using the hash.
     */
    function markHashUsed(bytes32 hashBytes, address account) internal {
        require(!isHashUsed_[hashBytes][account], "SV: used hash!");
        isHashUsed_[hashBytes][account] = true;
    }

    /**
     * @param data TransactionData struct to be hashed.
     * @return Hashed TransactionData struct.
     */
    function hash(TransactionData memory data) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    TX_DATA_TYPEHASH,
                    hash(data.actions),
                    hash(data.inputs),
                    hash(data.fee),
                    hash(data.requiredOutputs),
                    data.account,
                    data.salt
                )
            );
    }

    /**
     * @dev Hashes Action structs list.
     * @param actions Action structs list to be hashed.
     * @return Hashed Action structs list.
     */
    function hash(Action[] memory actions) internal pure returns (bytes32) {
        bytes memory actionsData = new bytes(0);

        uint256 length = actions.length;
        for (uint256 i = 0; i < length; i++) {
            actionsData = abi.encodePacked(
                actionsData,
                keccak256(
                    abi.encode(
                        ACTION_TYPEHASH,
                        actions[i].protocolAdapterName,
                        actions[i].actionType,
                        hash(actions[i].tokenAmounts),
                        keccak256(actions[i].data)
                    )
                )
            );
        }

        return keccak256(actionsData);
    }

    /**
     * @dev Hashes TokenAmount structs list.
     * @param tokenAmounts TokenAmount structs list to be hashed.
     * @return Hashed TokenAmount structs list.
     */
    function hash(TokenAmount[] memory tokenAmounts) internal pure returns (bytes32) {
        bytes memory tokenAmountsData = new bytes(0);

        uint256 length = tokenAmounts.length;
        for (uint256 i = 0; i < length; i++) {
            tokenAmountsData = abi.encodePacked(
                tokenAmountsData,
                keccak256(
                    abi.encode(
                        TOKEN_AMOUNT_TYPEHASH,
                        tokenAmounts[i].token,
                        tokenAmounts[i].amount,
                        tokenAmounts[i].amountType
                    )
                )
            );
        }

        return keccak256(tokenAmountsData);
    }

    /**
     * @dev Hashes Fee struct.
     * @param fee Fee struct to be hashed.
     * @return Hashed Fee struct.
     */
    function hash(Fee memory fee) internal pure returns (bytes32) {
        return keccak256(abi.encode(FEE_TYPEHASH, fee.share, fee.beneficiary));
    }

    /**
     * @dev Hashes AbsoluteTokenAmount structs list.
     * @param absoluteTokenAmounts AbsoluteTokenAmount structs list to be hashed.
     * @return Hashed AbsoluteTokenAmount structs list.
     */
    function hash(AbsoluteTokenAmount[] memory absoluteTokenAmounts)
        internal
        pure
        returns (bytes32)
    {
        bytes memory absoluteTokenAmountsData = new bytes(0);

        uint256 length = absoluteTokenAmounts.length;
        for (uint256 i = 0; i < length; i++) {
            absoluteTokenAmountsData = abi.encodePacked(
                absoluteTokenAmountsData,
                keccak256(
                    abi.encode(
                        ABSOLUTE_TOKEN_AMOUNT_TYPEHASH,
                        absoluteTokenAmounts[i].token,
                        absoluteTokenAmounts[i].amount
                    )
                )
            );
        }

        return keccak256(absoluteTokenAmountsData);
    }

    /**
     * @return Current chain ID.
     */
    function getChainId() internal view returns (uint256) {
        uint256 chainId;

        assembly {
            chainId := chainid()
        }

        return chainId;
    }
}

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.9;
pragma abicoder v2;

abstract contract ReentrancyGuard {
    uint256 internal constant UNLOCKED = 1;
    uint256 internal constant LOCKED = 2;

    uint256 internal guard_;

    modifier nonReentrant() {
        require(guard_ == UNLOCKED, "RG: locked");

        guard_ = LOCKED;

        _;

        guard_ = UNLOCKED;
    }

    constructor() {
        guard_ = UNLOCKED;
    }
}

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.9;
pragma abicoder v2;

import { AdapterBalance, TokenBalance } from "../shared/Structs.sol";
import { ERC20 } from "../shared/ERC20.sol";
import { Ownable } from "./Ownable.sol";
import { ProtocolAdapterManager } from "./ProtocolAdapterManager.sol";
import { ProtocolAdapter } from "../adapters/ProtocolAdapter.sol";

/**
 * @title Registry for protocol adapters.
 * @notice getBalances() function implements the main functionality.
 * @author Igor Sobolev <[email protected]>
 */
contract ProtocolAdapterRegistry is Ownable, ProtocolAdapterManager {
    /**
     * @param account Address of the account.
     * @return AdapterBalance array by the given account.
     * @notice Zero values are filtered out!
     */
    function getBalances(address account) external returns (AdapterBalance[] memory) {
        AdapterBalance[] memory adapterBalances = getAdapterBalances(
            getProtocolAdapterNames(),
            account
        );

        (
            uint256 nonZeroAdapterBalancesNumber,
            uint256[] memory nonZeroTokenBalancesNumbers
        ) = getNonZeroAdapterBalancesAndTokenBalancesNumbers(adapterBalances);

        return
            getNonZeroAdapterBalances(
                adapterBalances,
                nonZeroAdapterBalancesNumber,
                nonZeroTokenBalancesNumbers
            );
    }

    /**
     * @param protocolAdapterNames Array of the protocol adapters' names.
     * @param account Address of the account.
     * @return AdapterBalance array by the given parameters.
     */
    function getAdapterBalances(bytes32[] memory protocolAdapterNames, address account)
        public
        returns (AdapterBalance[] memory)
    {
        uint256 length = protocolAdapterNames.length;
        AdapterBalance[] memory adapterBalances = new AdapterBalance[](length);

        for (uint256 i = 0; i < length; i++) {
            adapterBalances[i] = getAdapterBalance(
                protocolAdapterNames[i],
                getSupportedTokens(protocolAdapterNames[i]),
                account
            );
        }

        return adapterBalances;
    }

    /**
     * @param protocolAdapterName Protocol adapter's Name.
     * @param tokens Array of tokens' addresses.
     * @param account Address of the account.
     * @return AdapterBalance array by the given parameters.
     */
    function getAdapterBalance(
        bytes32 protocolAdapterName,
        address[] memory tokens,
        address account
    ) public returns (AdapterBalance memory) {
        address adapter = getProtocolAdapterAddress(protocolAdapterName);
        require(adapter != address(0), "AR: bad protocolAdapterName");

        uint256 length = tokens.length;
        TokenBalance[] memory tokenBalances = new TokenBalance[](tokens.length);

        for (uint256 i = 0; i < length; i++) {
            try ProtocolAdapter(adapter).getBalance(tokens[i], account) returns (int256 amount) {
                tokenBalances[i] = TokenBalance({ token: tokens[i], amount: amount });
            } catch {
                tokenBalances[i] = TokenBalance({ token: tokens[i], amount: 0 });
            }
        }

        return
            AdapterBalance({
                protocolAdapterName: protocolAdapterName,
                tokenBalances: tokenBalances
            });
    }

    /**
     * @param adapterBalances List of AdapterBalance structs.
     * @return Numbers of non-empty AdapterBalance and non-zero TokenBalance structs.
     */
    function getNonZeroAdapterBalancesAndTokenBalancesNumbers(
        AdapterBalance[] memory adapterBalances
    ) internal pure returns (uint256, uint256[] memory) {
        uint256 length = adapterBalances.length;
        uint256 nonZeroAdapterBalancesNumber = 0;
        uint256[] memory nonZeroTokenBalancesNumbers = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            nonZeroTokenBalancesNumbers[i] = getNonZeroTokenBalancesNumber(
                adapterBalances[i].tokenBalances
            );

            if (nonZeroTokenBalancesNumbers[i] > 0) {
                nonZeroAdapterBalancesNumber++;
            }
        }

        return (nonZeroAdapterBalancesNumber, nonZeroTokenBalancesNumbers);
    }

    /**
     * @param tokenBalances List of TokenBalance structs.
     * @return Number of non-zero TokenBalance structs.
     */
    function getNonZeroTokenBalancesNumber(TokenBalance[] memory tokenBalances)
        internal
        pure
        returns (uint256)
    {
        uint256 length = tokenBalances.length;
        uint256 nonZeroTokenBalancesNumber = 0;

        for (uint256 i = 0; i < length; i++) {
            if (tokenBalances[i].amount > 0) {
                nonZeroTokenBalancesNumber++;
            }
        }

        return nonZeroTokenBalancesNumber;
    }

    /**
     * @param adapterBalances List of AdapterBalance structs.
     * @param nonZeroAdapterBalancesNumber Number of non-empty AdapterBalance structs.
     * @param nonZeroTokenBalancesNumbers List of non-zero TokenBalance structs numbers.
     * @return Non-empty AdapterBalance structs with non-zero TokenBalance structs.
     */
    function getNonZeroAdapterBalances(
        AdapterBalance[] memory adapterBalances,
        uint256 nonZeroAdapterBalancesNumber,
        uint256[] memory nonZeroTokenBalancesNumbers
    ) internal pure returns (AdapterBalance[] memory) {
        AdapterBalance[] memory nonZeroAdapterBalances = new AdapterBalance[](
            nonZeroAdapterBalancesNumber
        );
        uint256 length = adapterBalances.length;
        uint256 counter = 0;

        for (uint256 i = 0; i < length; i++) {
            if (nonZeroTokenBalancesNumbers[i] == 0) {
                continue;
            }

            nonZeroAdapterBalances[counter] = AdapterBalance({
                protocolAdapterName: adapterBalances[i].protocolAdapterName,
                tokenBalances: getNonZeroTokenBalances(
                    adapterBalances[i].tokenBalances,
                    nonZeroTokenBalancesNumbers[i]
                )
            });

            counter++;
        }

        return nonZeroAdapterBalances;
    }

    /**
     * @param tokenBalances List of TokenBalance structs.
     * @param nonZeroTokenBalancesNumber Number of non-zero TokenBalance structs.
     * @return Non-zero TokenBalance structs.
     */
    function getNonZeroTokenBalances(
        TokenBalance[] memory tokenBalances,
        uint256 nonZeroTokenBalancesNumber
    ) internal pure returns (TokenBalance[] memory) {
        TokenBalance[] memory nonZeroTokenBalances = new TokenBalance[](
            nonZeroTokenBalancesNumber
        );
        uint256 length = tokenBalances.length;
        uint256 counter = 0;

        for (uint256 i = 0; i < length; i++) {
            if (tokenBalances[i].amount == 0) {
                continue;
            }

            nonZeroTokenBalances[counter] = tokenBalances[i];

            counter++;
        }

        return nonZeroTokenBalances;
    }
}

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.9;
pragma abicoder v2;

import { Ownable } from "./Ownable.sol";

/**
 * @title ProtocolAdapterRegistry part responsible for protocol adapters management.
 * @dev Base contract for ProtocolAdapterRegistry.
 * @author Igor Sobolev <[email protected]>
 */
abstract contract ProtocolAdapterManager is Ownable {
    // Protocol adapters' names
    bytes32[] private _protocolAdapterNames;
    // Protocol adapter's name => protocol adapter's address
    mapping(bytes32 => address) private _protocolAdapterAddress;
    // protocol adapter's name => protocol adapter's supported tokens
    mapping(bytes32 => address[]) private _protocolAdapterSupportedTokens;

    /**
     * @notice Adds protocol adapters.
     * The function is callable only by the owner.
     * @param newProtocolAdapterNames Array of the new protocol adapters' names.
     * @param newProtocolAdapterAddresses Array of the new protocol adapters' addresses.
     * @param newSupportedTokens Array of the new protocol adapters' supported tokens.
     */
    function addProtocolAdapters(
        bytes32[] calldata newProtocolAdapterNames,
        address[] calldata newProtocolAdapterAddresses,
        address[][] calldata newSupportedTokens
    ) external onlyOwner {
        validateInput(newProtocolAdapterNames, newProtocolAdapterAddresses, newSupportedTokens);
        uint256 length = newProtocolAdapterNames.length;

        for (uint256 i = 0; i < length; i++) {
            addProtocolAdapter(
                newProtocolAdapterNames[i],
                newProtocolAdapterAddresses[i],
                newSupportedTokens[i]
            );
        }
    }

    /**
     * @notice Removes protocol adapters.
     * The function is callable only by the owner.
     * @param protocolAdapterNames Array of the protocol adapters' names.
     */
    function removeProtocolAdapters(bytes32[] calldata protocolAdapterNames) external onlyOwner {
        validateInput(protocolAdapterNames);
        uint256 length = protocolAdapterNames.length;

        for (uint256 i = 0; i < length; i++) {
            removeProtocolAdapter(protocolAdapterNames[i]);
        }
    }

    /**
     * @notice Updates protocol adapters.
     * The function is callable only by the owner.
     * @param protocolAdapterNames Array of the protocol adapters' names.
     * @param newProtocolAdapterAddresses Array of the protocol adapters' new addresses.
     * @param newSupportedTokens Array of the protocol adapters' new supported tokens.
     */
    function updateProtocolAdapters(
        bytes32[] calldata protocolAdapterNames,
        address[] calldata newProtocolAdapterAddresses,
        address[][] calldata newSupportedTokens
    ) external onlyOwner {
        validateInput(protocolAdapterNames, newProtocolAdapterAddresses, newSupportedTokens);
        uint256 length = protocolAdapterNames.length;

        for (uint256 i = 0; i < length; i++) {
            updateProtocolAdapter(
                protocolAdapterNames[i],
                newProtocolAdapterAddresses[i],
                newSupportedTokens[i]
            );
        }
    }

    /**
     * @return Array of protocol adapters' names.
     */
    function getProtocolAdapterNames() public view returns (bytes32[] memory) {
        return _protocolAdapterNames;
    }

    /**
     * @param protocolAdapterName Name of the protocol adapter.
     * @return Address of protocol adapter.
     */
    function getProtocolAdapterAddress(bytes32 protocolAdapterName) public view returns (address) {
        return _protocolAdapterAddress[protocolAdapterName];
    }

    /**
     * @param protocolAdapterName Name of the protocol adapter.
     * @return Array of protocol adapter's supported tokens.
     */
    function getSupportedTokens(bytes32 protocolAdapterName)
        public
        view
        returns (address[] memory)
    {
        return _protocolAdapterSupportedTokens[protocolAdapterName];
    }

    /**
     * @dev Adds a protocol adapter.
     * @param newProtocolAdapterName New protocol adapter's protocolAdapterName.
     * @param newProtocolAdapterAddress New protocol adapter's address.
     * @param newSupportedTokens Array of the new protocol adapter's supported tokens.
     * Empty array is always allowed.
     */
    function addProtocolAdapter(
        bytes32 newProtocolAdapterName,
        address newProtocolAdapterAddress,
        address[] calldata newSupportedTokens
    ) internal {
        require(newProtocolAdapterAddress != address(0), "PAM: zero[1]");
        require(_protocolAdapterAddress[newProtocolAdapterName] == address(0), "PAM: exists");

        _protocolAdapterNames.push(newProtocolAdapterName);
        _protocolAdapterAddress[newProtocolAdapterName] = newProtocolAdapterAddress;
        _protocolAdapterSupportedTokens[newProtocolAdapterName] = newSupportedTokens;
    }

    /**
     * @dev Removes a protocol adapter.
     * @param protocolAdapterName Protocol adapter's protocolAdapterName.
     */
    function removeProtocolAdapter(bytes32 protocolAdapterName) internal {
        require(
            _protocolAdapterAddress[protocolAdapterName] != address(0),
            "PAM: does not exist[1]"
        );

        uint256 length = _protocolAdapterNames.length;
        uint256 index = 0;
        while (_protocolAdapterNames[index] != protocolAdapterName) {
            index++;
        }

        if (index != length - 1) {
            _protocolAdapterNames[index] = _protocolAdapterNames[length - 1];
        }

        _protocolAdapterNames.pop();

        delete _protocolAdapterAddress[protocolAdapterName];
        delete _protocolAdapterSupportedTokens[protocolAdapterName];
    }

    /**
     * @dev Updates a protocol adapter.
     * @param protocolAdapterName Protocol adapter's protocolAdapterName.
     * @param newProtocolAdapterAddress Protocol adapter's new address.
     * @param newSupportedTokens Array of the protocol adapter's new supported tokens.
     * Empty array is always allowed.
     */
    function updateProtocolAdapter(
        bytes32 protocolAdapterName,
        address newProtocolAdapterAddress,
        address[] calldata newSupportedTokens
    ) internal {
        address oldProtocolAdapterAddress = _protocolAdapterAddress[protocolAdapterName];
        require(oldProtocolAdapterAddress != address(0), "PAM: does not exist[2]");
        require(newProtocolAdapterAddress != address(0), "PAM: zero[2]");

        if (oldProtocolAdapterAddress == newProtocolAdapterAddress) {
            _protocolAdapterSupportedTokens[protocolAdapterName] = newSupportedTokens;
        } else {
            _protocolAdapterAddress[protocolAdapterName] = newProtocolAdapterAddress;
            _protocolAdapterSupportedTokens[protocolAdapterName] = newSupportedTokens;
        }
    }

    /**
     * @dev Checks that arrays' lengths are equal and non-zero.
     * @param protocolAdapterNames Array of protocol adapters' names.
     * @param protocolAdapterAddresses Array of protocol adapters' addresses.
     * @param supportedTokens Array of protocol adapters' supported tokens.
     */
    function validateInput(
        bytes32[] calldata protocolAdapterNames,
        address[] calldata protocolAdapterAddresses,
        address[][] calldata supportedTokens
    ) internal pure {
        validateInput(protocolAdapterNames);
        uint256 length = protocolAdapterNames.length;
        require(length == protocolAdapterAddresses.length, "PAM: lengths differ[1]");
        require(length == supportedTokens.length, "PAM: lengths differ[2]");
    }

    /**
     * @dev Checks that array's length is non-zero.
     * @param protocolAdapterNames Array of protocol adapters' names.
     */
    function validateInput(bytes32[] calldata protocolAdapterNames) internal pure {
        require(protocolAdapterNames.length != 0, "PAM: empty");
    }
}

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.9;
pragma abicoder v2;

abstract contract Ownable {
    modifier onlyOwner() {
        require(msg.sender == owner_, "O: only owner");
        _;
    }

    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner_, "O: only pending owner");
        _;
    }

    address private owner_;
    address private pendingOwner_;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @notice Initializes owner variable with msg.sender address.
     */
    constructor() {
        owner_ = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @notice Sets pending owner to the desired address.
     * The function is callable only by the owner.
     */
    function proposeOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "O: empty newOwner");
        require(newOwner != owner_, "O: equal to owner_");
        require(newOwner != pendingOwner_, "O: equal to pendingOwner_");
        pendingOwner_ = newOwner;
    }

    /**
     * @notice Transfers ownership to the pending owner.
     * The function is callable only by the pending owner.
     */
    function acceptOwnership() external onlyPendingOwner {
        emit OwnershipTransferred(owner_, msg.sender);
        owner_ = msg.sender;
        delete pendingOwner_;
    }

    /**
     * @return Owner of the contract.
     */
    function owner() external view returns (address) {
        return owner_;
    }

    /**
     * @return Pending owner of the contract.
     */
    function pendingOwner() external view returns (address) {
        return pendingOwner_;
    }
}

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.9;
pragma abicoder v2;

import { Action, TokenAmount, AbsoluteTokenAmount, ActionType, AmountType } from "../shared/Structs.sol";
import { InteractiveAdapter } from "../interactiveAdapters/InteractiveAdapter.sol";
import { ERC20 } from "../shared/ERC20.sol";
import { ProtocolAdapterRegistry } from "./ProtocolAdapterRegistry.sol";
import { SafeERC20 } from "../shared/SafeERC20.sol";
import { Helpers } from "../shared/Helpers.sol";
import { ReentrancyGuard } from "./ReentrancyGuard.sol";

/**
 * @title Main contract executing actions.
 */
contract Core is ReentrancyGuard {
    using SafeERC20 for ERC20;
    using Helpers for uint256;
    using Helpers for address;

    address internal immutable protocolAdapterRegistry_;

    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    event ExecutedAction(
        bytes32 indexed protocolAdapterName,
        ActionType indexed actionType,
        TokenAmount[] tokenAmounts,
        bytes data
    );

    constructor(address protocolAdapterRegistry) {
        require(protocolAdapterRegistry != address(0), "C: empty protocolAdapterRegistry");

        protocolAdapterRegistry_ = protocolAdapterRegistry;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    /**
     * @notice Executes actions and returns tokens to account.
     * @param actions Array with actions to be executed.
     * @param requiredOutputs Array with required amounts for the returned tokens.
     * @param account Address that will receive all the resulting funds.
     * @return Array with actual amounts of the returned tokens.
     */
    function executeActions(
        Action[] calldata actions,
        AbsoluteTokenAmount[] calldata requiredOutputs,
        address payable account
    ) external payable nonReentrant returns (AbsoluteTokenAmount[] memory) {
        require(account != address(0), "C: empty account");
        address[][] memory tokensToBeWithdrawn = new address[][](actions.length);

        for (uint256 i = 0; i < actions.length; i++) {
            tokensToBeWithdrawn[i] = executeAction(actions[i]);
            emit ExecutedAction(
                actions[i].protocolAdapterName,
                actions[i].actionType,
                actions[i].tokenAmounts,
                actions[i].data
            );
        }

        return returnTokens(requiredOutputs, tokensToBeWithdrawn, account);
    }

    /**
     * @notice Execute one action via external call.
     * @param action Action struct.
     * @dev Can be called only by this contract.
     * This function is used to create cross-protocol adapters.
     */
    function executeExternal(Action calldata action) external returns (address[] memory) {
        require(msg.sender == address(this), "C: only address(this)");
        return executeAction(action);
    }

    /**
     * @return Address of the ProtocolAdapterRegistry contract used.
     */
    function getProtocolAdapterRegistry() external view returns (address) {
        return protocolAdapterRegistry_;
    }

    /**
     * @notice Executes one action and returns the list of tokens to be returned.
     * @param action Action struct with with action to be executed.
     * @return List of tokens addresses to be returned by the action.
     */
    function executeAction(Action calldata action) internal returns (address[] memory) {
        address adapter = ProtocolAdapterRegistry(protocolAdapterRegistry_)
            .getProtocolAdapterAddress(action.protocolAdapterName);
        require(adapter != address(0), "C: bad name");
        require(
            action.actionType == ActionType.Deposit || action.actionType == ActionType.Withdraw,
            "C: bad action type"
        );
        bytes4 selector;
        if (action.actionType == ActionType.Deposit) {
            selector = InteractiveAdapter(adapter).deposit.selector;
        } else {
            selector = InteractiveAdapter(adapter).withdraw.selector;
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = adapter.delegatecall(
            abi.encodeWithSelector(selector, action.tokenAmounts, action.data)
        );

        // assembly revert opcode is used here as `returnData`
        // is already bytes array generated by the callee's revert()
        // solhint-disable-next-line no-inline-assembly
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 32), returndatasize())
            }
        }

        return abi.decode(returnData, (address[]));
    }

    /**
     * @notice Returns tokens to the account used as function parameter.
     * @param requiredOutputs Array with required amounts for the returned tokens.
     * @param tokensToBeWithdrawn Array with the tokens returned by the adapters.
     * @param account Address that will receive all the resulting funds.
     * @return Array with actual amounts of the returned tokens.
     */
    function returnTokens(
        AbsoluteTokenAmount[] calldata requiredOutputs,
        address[][] memory tokensToBeWithdrawn,
        address payable account
    ) internal returns (AbsoluteTokenAmount[] memory) {
        uint256 length = requiredOutputs.length;
        uint256 lengthNested;
        address token;
        AbsoluteTokenAmount[] memory actualOutputs = new AbsoluteTokenAmount[](length);

        for (uint256 i = 0; i < length; i++) {
            token = requiredOutputs[i].token;
            actualOutputs[i] = AbsoluteTokenAmount({
                token: token,
                amount: checkRequirementAndTransfer(token, requiredOutputs[i].amount, account)
            });
        }

        length = tokensToBeWithdrawn.length;
        for (uint256 i = 0; i < length; i++) {
            lengthNested = tokensToBeWithdrawn[i].length;
            for (uint256 j = 0; j < lengthNested; j++) {
                checkRequirementAndTransfer(tokensToBeWithdrawn[i][j], 0, account);
            }
        }

        return actualOutputs;
    }

    /**
     * @notice Checks the requirement for the given token and (in case the check passes)
     * transfers tokens to the account used as function parameter.
     * @param token Address of the returned token.
     * @param requiredAmount Required amount for the returned token.
     * @param account Address that will receive the returned token.
     * @return Actual amount of the returned token.
     */
    function checkRequirementAndTransfer(
        address token,
        uint256 requiredAmount,
        address account
    ) internal returns (uint256) {
        uint256 actualAmount;
        if (token == ETH) {
            actualAmount = address(this).balance;
        } else {
            actualAmount = ERC20(token).balanceOf(address(this));
        }

        require(
            actualAmount >= requiredAmount,
            string(
                abi.encodePacked(
                    "C: ",
                    actualAmount.toString(),
                    " is less than ",
                    requiredAmount.toString(),
                    " for ",
                    token.toString()
                )
            )
        );

        if (actualAmount > 0) {
            if (token == ETH) {
                // solhint-disable-next-line avoid-low-level-calls
                (bool success, ) = account.call{ value: actualAmount }(new bytes(0));
                require(success, "ETH transfer to account failed");
            } else {
                ERC20(token).safeTransfer(account, actualAmount, "C");
            }
        }

        return actualAmount;
    }
}

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.9;
pragma abicoder v2;

/**
 * @title Protocol adapter abstract contract.
 * @dev adapterType(), tokenType(), and getBalance() functions MUST be implemented.
 * @author Igor Sobolev <[email protected]>
 */
abstract contract ProtocolAdapter {
    /**
     * @dev MUST return amount and type of the given token
     * locked on the protocol by the given account.
     */
    function getBalance(address token, address account) public virtual returns (int256);
}