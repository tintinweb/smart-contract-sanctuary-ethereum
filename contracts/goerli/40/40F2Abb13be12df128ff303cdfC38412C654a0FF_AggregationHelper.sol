// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./UserOperation.sol";

interface IAccount {

    /**
     * Validate user's signature and nonce
     * the entryPoint will make the call to the recipient only if this validation call returns successfully.
     *
     * @dev Must validate caller is the entryPoint.
     *      Must validate the signature and nonce
     * @param userOp the operation that is about to be executed.
     * @param userOpHash hash of the user's request data. can be used as the basis for signature.
     * @param aggregator the aggregator used to validate the signature. NULL for non-aggregated signature accounts.
     * @param missingAccountFunds missing funds on the account's deposit in the entrypoint.
     *      This is the minimum amount to transfer to the sender(entryPoint) to be able to make the call.
     *      The excess is left as a deposit in the entrypoint, for future calls.
     *      can be withdrawn anytime using "entryPoint.withdrawTo()"
     *      In case there is a paymaster in the request (or the current deposit is high enough), this value will be zero.
     * @return deadline the last block timestamp this operation is valid, or zero if it is valid indefinitely.
     *      Note that the validation code cannot use block.timestamp (or block.number) directly.
     */
    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, address aggregator, uint256 missingAccountFunds)
    external returns (uint256 deadline);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./UserOperation.sol";
import "./IAccount.sol";
import "./IAggregator.sol";

/**
 * Aggregated account, that support IAggregator.
 * - the validateUserOp will be called only after the aggregator validated this account (with all other accounts of this aggregator).
 * - the validateUserOp MUST valiate the aggregator parameter, and MAY ignore the userOp.signature field.
 */
interface IAggregatedAccount is IAccount {

    /**
     * return the address of the signature aggregator the account supports.
     */
    function getAggregator() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./UserOperation.sol";

/**
 * Aggregated Signatures validator.
 */
interface IAggregator {

    /**
     * validate aggregated signature.
     * revert if the aggregated signature does not match the given list of operations.
     */
    function validateSignatures(UserOperation[] calldata userOps, bytes calldata signature) external view;

    /**
     * validate signature of a single userOp
     * This method is called by EntryPoint.simulateUserOperation() if the account has an aggregator.
     * First it validates the signature over the userOp. then it return data to be used when creating the handleOps:
     * @param userOp the userOperation received from the user.
     * @return sigForUserOp the value to put into the signature field of the userOp when calling handleOps.
     *    (usually empty, unless account and aggregator support some kind of "multisig"
     */
    function validateUserOpSignature(UserOperation calldata userOp)
    external view returns (bytes memory sigForUserOp);

    /**
     * aggregate multiple signatures into a single value.
     * This method is called off-chain to calculate the signature to pass with handleOps()
     * bundler MAY use optimized custom code perform this aggregation
     * @param userOps array of UserOperations to collect the signatures from.
     * @return aggregatesSignature the aggregated signature
     */
    function aggregateSignatures(UserOperation[] calldata userOps) external view returns (bytes memory aggregatesSignature);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable no-inline-assembly */

    /**
     * User Operation struct
     * @param sender the sender account of this request
     * @param nonce unique value the sender uses to verify it is not a replay.
     * @param initCode if set, the account contract will be created by this constructor
     * @param callData the method call to execute on this account.
     * @param verificationGasLimit gas used for validateUserOp and validatePaymasterUserOp
     * @param preVerificationGas gas not calculated by the handleOps method, but added to the gas paid. Covers batch overhead.
     * @param maxFeePerGas same as EIP-1559 gas parameter
     * @param maxPriorityFeePerGas same as EIP-1559 gas parameter
     * @param paymasterAndData if set, this field hold the paymaster address and "paymaster-specific-data". the paymaster will pay for the transaction instead of the sender
     * @param signature sender-verified signature over the entire request, the EntryPoint address and the chain ID.
     */
    struct UserOperation {

        address sender;
        uint256 nonce;
        bytes initCode;
        bytes callData;
        uint256 callGasLimit;
        uint256 verificationGasLimit;
        uint256 preVerificationGas;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
        bytes paymasterAndData;
        bytes signature;
    }

library UserOperationLib {

    function getSender(UserOperation calldata userOp) internal pure returns (address) {
        address data;
        //read sender from userOp, which is first userOp member (saves 800 gas...)
        assembly {data := calldataload(userOp)}
        return address(uint160(data));
    }

    //relayer/miner might submit the TX with higher priorityFee, but the user should not
    // pay above what he signed for.
    function gasPrice(UserOperation calldata userOp) internal view returns (uint256) {
    unchecked {
        uint256 maxFeePerGas = userOp.maxFeePerGas;
        uint256 maxPriorityFeePerGas = userOp.maxPriorityFeePerGas;
        if (maxFeePerGas == maxPriorityFeePerGas) {
            //legacy mode (for networks that don't support basefee opcode)
            return maxFeePerGas;
        }
        return min(maxFeePerGas, maxPriorityFeePerGas + block.basefee);
    }
    }

    function pack(UserOperation calldata userOp) internal pure returns (bytes memory ret) {
        //lighter signature scheme. must match UserOp.ts#packUserOp
        bytes calldata sig = userOp.signature;
        // copy directly the userOp from calldata up to (but not including) the signature.
        // this encoding depends on the ABI encoding of calldata, but is much lighter to copy
        // than referencing each field separately.
        assembly {
            let ofs := userOp
            let len := sub(sub(sig.offset, ofs), 32)
            ret := mload(0x40)
            mstore(0x40, add(ret, add(len, 32)))
            mstore(ret, len)
            calldatacopy(add(ret, 32), ofs, len)
        }
    }

    function hash(UserOperation calldata userOp) internal pure returns (bytes32) {
        return keccak256(pack(userOp));
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import "@account-abstraction/contracts/interfaces/IAggregator.sol";
import "@account-abstraction/contracts/interfaces/IAggregatedAccount.sol";
import "@account-abstraction/contracts/interfaces/IAccount.sol";
import "solidity-string-utils/StringUtils.sol";

contract AggregationHelper {
  error NotAggregatedAccount();

  struct UserOpsPerAggregator {
    UserOperation[] userOps;
    IAggregator aggregator;
    bytes signature;
  }

  function getAggregator(UserOperation calldata op)
    public
    view
    returns (address aggregator)
  {
    if (op.sender.code.length == 0) {
      return address(0x1337); // mark of unexisting wallet
    }
    try IAggregatedAccount(op.sender).getAggregator() returns (
        address agg
      ) {
        aggregator = agg;
      } catch {
        revert NotAggregatedAccount();
      }
  }

  function getAggregators(UserOperation[] calldata ops)
    public
    view
    returns (address[] memory aggregators)
  {
    uint256 opsLen = ops.length;
    aggregators = new address[](ops.length);
    for (uint256 i = 0; i < opsLen; ++i) {
      address aggregator = getAggregator(ops[i]);
      aggregators[i] = aggregator;
    }
  }

  function aggregateOps(UserOpsPerAggregator[] memory opas)
    external
    view
    returns (UserOpsPerAggregator[] memory)
  {
    uint256 opasLen = opas.length;
    for (uint256 i = 0; i < opasLen; ++i) {
      UserOpsPerAggregator memory opa = opas[i];
      UserOperation[] memory ops = opa.userOps;
      IAggregator aggregator = opa.aggregator;
      opa.signature = aggregator.aggregateSignatures(ops);
    }
    return opas;
  }
}

// SPDX-License-Identifier:MIT
pragma solidity >=0.5.0;
/**
 * add to your contract:
 *  using StringUtils for *;
 */
library StringUtils {

    function concat( string memory str, string memory title, string memory a) internal pure returns (string memory) {
        return string(abi.encodePacked(str,title,a));
    }

    function concat( string memory str, string memory a) internal pure returns (string memory) {
        return string(abi.encodePacked(str,a));
    }

    function concat( string memory str, string memory title, address a) internal pure returns (string memory) {
        return string(abi.encodePacked(str, title, toString(a)));
    }

    function concat( string memory str, address a) internal pure returns (string memory) {
        return string(abi.encodePacked(str, toString(a)));
    }

    function concat( string memory str, string memory title, uint a) internal pure returns (string memory) {
        return string(abi.encodePacked(str, title, toString(a)));
    }

    function concat( string memory str, string memory title, int a) internal pure returns (string memory) {
        return string(abi.encodePacked(str, title, toString(a)));
    }

    function concat( string memory str, uint a) internal pure returns (string memory) {
        return string(abi.encodePacked(str, toString(a)));
    }

    function concat( string memory str, int a) internal pure returns (string memory) {
        return string(abi.encodePacked(str, toString(a)));
    }

    function concat( string memory str, string memory title, bytes32 a) internal pure returns (string memory) {
        return string(abi.encodePacked(str, title, toString(a)));
    }

    function concat( string memory str, bytes32 a) internal pure returns (string memory) {
        return string(abi.encodePacked(str, toString(a)));
    }

    function toString(address _addr) internal pure returns (string memory) {
        bytes32 value = bytes32(bytes20(uint160(_addr)));
        return toString(value, 20);
    }

    function toString(bytes32 b) internal pure returns (string memory) {
        return toString(b, 32);
    }

    function toString(bytes32 value, uint nbytes) internal pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(nbytes*2+2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < nbytes; i++) {
            uint8 chr = uint8(value[i]);
            str[2+i*2] = alphabet[uint(uint8(chr >> 4))];
            str[3+i*2] = alphabet[uint(uint8(chr & 0x0f))];
        }
        return string(str);
    }

    function toString(bool _i) internal pure returns (string memory _uintAsString) {
        return _i ? "true" : "false";
    }

    function toString(int _i) internal pure returns (string memory _uintAsString) {
        if (_i>0) return toString(uint(_i));
        return concat("-", toString(uint(-_i)));
    }

    function toString(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            bstr[--k] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}