// SPDX-License-Identifier: MIT
//  _/      _/  _/    _/    _/_/
//   _/  _/    _/  _/    _/    _/
//     _/      _/_/      _/    _/
//   _/  _/    _/  _/    _/    _/
// _/      _/  _/    _/    _/_/
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Snapshot.sol";
import "./AccessControl.sol";
import "./Context.sol";
import "./Counters.sol";
import "./EIP712.sol";

contract ChainConstants {
    string constant public ERC712_VERSION = "1";
}

abstract contract NativeMetaTransaction is EIP712 {
    using Counters for Counters.Counter;

    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );

    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );

    mapping(address => Counters.Counter) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
        nonce: nonces[userAddress].current(),
        from: userAddress,
        functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress].increment();

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );

        require(success, "Function call not successful");

        return returnData;
    }

    function _hashMetaTransaction(MetaTransaction memory metaTx) internal pure returns (bytes32) {
        return
        keccak256(
            abi.encode(
                META_TRANSACTION_TYPEHASH,
                metaTx.nonce,
                metaTx.from,
                keccak256(metaTx.functionSignature)
            )
        );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user].current();
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
        signer ==
        ECDSA.recover(
            _hashTypedDataV4(_hashMetaTransaction(metaTx)),
            sigV,
            sigR,
            sigS
        );
    }
}

abstract contract ContextMixin {
    function msgSender() internal view returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
            // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                mload(add(array, index)),
                0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

/// @custom:security-contact [email protected]
contract XKO is ERC20, ERC20Snapshot, AccessControl, ChainConstants, NativeMetaTransaction, ContextMixin {
    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");

    constructor(string memory name, string memory symbol) ERC20(name, symbol) EIP712(name, ChainConstants.ERC712_VERSION) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SNAPSHOT_ROLE, msg.sender);
        _mint(msg.sender, 100000000000 * 10 ** decimals());
    }

    function _msgSender() internal override view returns (address sender) {
        return ContextMixin.msgSender();
    }

    function snapshot() public onlyRole(SNAPSHOT_ROLE) {
        _snapshot();
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Snapshot) {
        super._beforeTokenTransfer(from, to, amount);
    }
}