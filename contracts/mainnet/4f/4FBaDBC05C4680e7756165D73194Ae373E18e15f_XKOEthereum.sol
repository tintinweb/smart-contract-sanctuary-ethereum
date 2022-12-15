// SPDX-License-Identifier: MIT
//    _/      _/  _/    _/    _/_/
//     _/  _/    _/  _/    _/    _/
//      _/      _/_/      _/    _/
//   _/  _/    _/  _/    _/    _/
//_/      _/  _/    _/    _/_/
pragma solidity ^0.8.17;

import "./ERC20Capped.sol";
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
        return signer == ECDSA.recover(
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

/**
  * @dev Polygon > Ethereum bridge requirement
  */
interface IMintableERC20 is IERC20 {
    /**
     * @notice called by predicate contract to mint tokens while withdrawing
     * @dev Should be callable only by MintableERC20Predicate
     * Make sure minting is done only by this function
     * @param user user address for whom token is being minted
     * @param amount amount of token being minted
     */
    function mint(address user, uint256 amount) external;
}

/// @custom:security-contact [email protected]
contract XKOEthereum is ERC20Capped, AccessControl, ChainConstants, NativeMetaTransaction, ContextMixin, IMintableERC20 {
    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");
    address public predicateProxy;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) ERC20Capped(100000000000 * 10 ** decimals()) EIP712(name, ChainConstants.ERC712_VERSION) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    function _msgSender() internal override view returns (address sender) {
        return ContextMixin.msgSender();
    }

    function setPredicateProxy(address proxy) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if(hasRole(PREDICATE_ROLE, predicateProxy)){
            _revokeRole(PREDICATE_ROLE, predicateProxy);
        }
        predicateProxy = proxy;
        _grantRole(PREDICATE_ROLE, predicateProxy);
    }

    /**
     * @dev See {IMintableERC20-mint}.
     */
    function mint(address user, uint256 amount) external override onlyRole(PREDICATE_ROLE) {
        _mint(user, amount);
    }
}