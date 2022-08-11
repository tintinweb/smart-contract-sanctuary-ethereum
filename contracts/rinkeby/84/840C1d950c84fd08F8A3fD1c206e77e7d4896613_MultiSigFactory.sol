// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
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
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

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
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

import "./MultiSigWallet.sol";

contract MultiSigFactory {
    MultiSigWallet[] public multiSigs;
    mapping(address => bool) existsMultiSig;

  event Create(
    uint indexed contractId,
    address indexed contractAddress,
    address creator,
    address[] owners,
    uint signaturesRequired
  );

    event Create2Event(
        uint256 indexed contractId,
        string name,
        address indexed contractAddress,
        address creator,
        address[] owners,
        uint256 signaturesRequired
    );


    event Owners(
        address indexed contractAddress,
        address[] owners,
        uint256 indexed signaturesRequired
    );


  constructor() {}

  modifier onlyRegistered() {
    require(existsMultiSig[msg.sender], "caller not registered to use logger");
    _;
  }

  function emitOwners(
    address _contractAddress,
    address[] memory _owners,
    uint256 _signaturesRequired
  ) external onlyRegistered {
    emit Owners(_contractAddress, _owners, _signaturesRequired);
  }

  function create(
    uint256 _chainId,
    address[] memory _owners,
    uint _signaturesRequired
  ) public payable {
    uint id = numberOfMultiSigs();

    address payable addr;
    uint256 salt = 1;
    bytes memory contractBytecode = "0x60806040526040516200190438038062001904833981016040819052620000269162000285565b81600081116200007d5760405162461bcd60e51b815260206004820152601e60248201527f4d757374206265206e6f6e2d7a65726f2073696773207265717569726564000060448201526064015b60405180910390fd5b600080546001600160a01b0319166001600160a01b03841617815560038490555b845181101562000256576000858281518110620000cb57634e487b7160e01b600052603260045260246000fd5b6020026020010151905060006001600160a01b0316816001600160a01b031614156200013a5760405162461bcd60e51b815260206004820152601960248201527f636f6e7374727563746f723a207a65726f206164647265737300000000000000604482015260640162000074565b6001600160a01b03811660009081526001602052604090205460ff1615620001a55760405162461bcd60e51b815260206004820152601d60248201527f636f6e7374727563746f723a206f776e6572206e6f7420756e69717565000000604482015260640162000074565b6001600160a01b038116600081815260016020818152604092839020805460ff1916831781556002805493840190557f405787fa12a823e0f2b7631cc41b3ba8828b3321ca811111fa75cd3aa3bb5ace90920180546001600160a01b031916851790559054915160ff909216151582527ffe545f48304051c4029eb2da9927daa59da0414b4b084fdceaf2955b609b899e910160405180910390a250806200024d8162000383565b9150506200009e565b50505060059290925550620003c19050565b80516001600160a01b03811681146200028057600080fd5b919050565b600080600080608085870312156200029b578384fd5b8451602080870151919550906001600160401b0380821115620002bc578586fd5b818801915088601f830112620002d0578586fd5b815181811115620002e557620002e5620003ab565b8060051b604051601f19603f830116810181811085821117156200030d576200030d620003ab565b604052828152858101935084860182860187018d10156200032c57898afd5b8995505b838610156200035957620003448162000268565b85526001959095019493860193860162000330565b5080985050505050505060408501519150620003786060860162000268565b905092959194509250565b6000600019821415620003a457634e487b7160e01b81526011600452602481fd5b5060010190565b634e487b7160e01b600052604160045260246000fd5b61153380620003d16000396000f3fe6080604052600436106100a05760003560e01c8063545a4a3c11610064578063545a4a3c146101c557806365af1bed146101f35780639a8a059214610213578063affed0e014610229578063ce757d291461023f578063d1fbffa01461025557600080fd5b8063025e7c27146100e657806319045a25146101235780632f54bf6e146101435780633034a742146101835780633bad5426146101a557600080fd5b366100e1576040805134815247602082015233917f90890809c654f11d6e72a28fa60149770a0d11ec6c92319d6ceb2bb0a4ea1a15910160405180910390a2005b600080fd5b3480156100f257600080fd5b506101066101013660046111d7565b610282565b6040516001600160a01b0390911681526020015b60405180910390f35b34801561012f57600080fd5b5061010661013e366004611192565b6102ac565b34801561014f57600080fd5b5061017361015e366004611049565b60016020526000908152604090205460ff1681565b604051901515815260200161011a565b34801561018f57600080fd5b506101a361019e3660046111d7565b610316565b005b3480156101b157600080fd5b506101a36101c0366004611167565b610365565b3480156101d157600080fd5b506101e56101e03660046111ef565b6104db565b60405190815260200161011a565b3480156101ff57600080fd5b506101a361020e366004611167565b61051a565b34801561021f57600080fd5b506101e560055481565b34801561023557600080fd5b506101e560045481565b34801561024b57600080fd5b506101e560035481565b34801561026157600080fd5b50610275610270366004611065565b6106b6565b60405161011a91906113aa565b6002818154811061029257600080fd5b6000918252602090912001546001600160a01b0316905081565b600061030f82610309856040517f19457468657265756d205369676e6564204d6573736167653a0a3332000000006020820152603c8101829052600090605c01604051602081830303815290604052805190602001209050919050565b906109b6565b9392505050565b33301461033e5760405162461bcd60e51b8152600401610335906113bd565b60405180910390fd5b806000811161035f5760405162461bcd60e51b8152600401610335906113df565b50600355565b3330146103845760405162461bcd60e51b8152600401610335906113bd565b80600081116103a55760405162461bcd60e51b8152600401610335906113df565b6001600160a01b03831660009081526001602052604090205460ff1661040d5760405162461bcd60e51b815260206004820152601760248201527f72656d6f76655369676e65723a206e6f74206f776e65720000000000000000006044820152606401610335565b610416836109da565b60038290556001600160a01b03831660008181526001602090815260409182902054915160ff909216151582527ffe545f48304051c4029eb2da9927daa59da0414b4b084fdceaf2955b609b899e91015b60405180910390a2600054604051632fb7d0a560e21b81526001600160a01b039091169063bedf4294906104a49030906002908790600401611345565b600060405180830381600087803b1580156104be57600080fd5b505af11580156104d2573d6000803e3d6000fd5b50505050505050565b600030600554868686866040516020016104fa9695949392919061127c565b604051602081830303815290604052805190602001209050949350505050565b3330146105395760405162461bcd60e51b8152600401610335906113bd565b806000811161055a5760405162461bcd60e51b8152600401610335906113df565b6001600160a01b0383166105b05760405162461bcd60e51b815260206004820152601760248201527f6164645369676e65723a207a65726f20616464726573730000000000000000006044820152606401610335565b6001600160a01b03831660009081526001602052604090205460ff16156106195760405162461bcd60e51b815260206004820152601b60248201527f6164645369676e65723a206f776e6572206e6f7420756e6971756500000000006044820152606401610335565b6001600160a01b038316600081815260016020818152604092839020805460ff1916831781556002805493840190557f405787fa12a823e0f2b7631cc41b3ba8828b3321ca811111fa75cd3aa3bb5ace90920180546001600160a01b0319168517905560038690559054915160ff909216151582527ffe545f48304051c4029eb2da9927daa59da0414b4b084fdceaf2955b609b899e9101610467565b3360009081526001602052604090205460609060ff166107045760405162461bcd60e51b81526020600482015260096024820152682737ba1037bbb732b960b91b6044820152606401610335565b60006107146004548787876104db565b600480549192506000610726836114a1565b919050555060008060005b855181101561083557600061076d8588848151811061076057634e487b7160e01b600052603260045260246000fd5b60200260200101516102ac565b9050826001600160a01b0316816001600160a01b0316116107ee5760405162461bcd60e51b815260206004820152603560248201527f657865637574655472616e73616374696f6e3a206475706c6963617465206f7260448201527420756e6f726465726564207369676e61747572657360581b6064820152608401610335565b6001600160a01b038116600090815260016020526040902054909250829060ff1615610822578361081e816114a1565b9450505b508061082d816114a1565b915050610731565b506003548210156108a05760405162461bcd60e51b815260206004820152602f60248201527f657865637574655472616e73616374696f6e3a206e6f7420656e6f756768207660448201526e616c6964207369676e61747572657360881b6064820152608401610335565b600080896001600160a01b031689896040516108bc91906112d7565b60006040518083038185875af1925050503d80600081146108f9576040519150601f19603f3d011682016040523d82523d6000602084013e6108fe565b606091505b5091509150816109505760405162461bcd60e51b815260206004820152601d60248201527f657865637574655472616e73616374696f6e3a207478206661696c65640000006044820152606401610335565b336001600160a01b03167f9053e9ec105157fac8c9308d63e6b22be5f50fe915a3e567419b624311a02d748b8b8b600160045461098d9190611447565b8a876040516109a1969594939291906112f3565b60405180910390a29998505050505050505050565b60008060006109c58585610c4e565b915091506109d281610cbe565b509392505050565b6001600160a01b0381166000908152600160205260408120805460ff19169055600254908167ffffffffffffffff811115610a2557634e487b7160e01b600052604160045260246000fd5b604051908082528060200260200182016040528015610a4e578160200160208202803683370190505b5090506000610a5e600184611447565b90505b836001600160a01b031660028281548110610a8c57634e487b7160e01b600052603260045260246000fd5b6000918252602090912001546001600160a01b031614610b6b5760028181548110610ac757634e487b7160e01b600052603260045260246000fd5b9060005260206000200160009054906101000a90046001600160a01b0316828281518110610b0557634e487b7160e01b600052603260045260246000fd5b60200260200101906001600160a01b031690816001600160a01b0316815250506002805480610b4457634e487b7160e01b600052603160045260246000fd5b600082815260209020810160001990810180546001600160a01b0319169055019055610c36565b6002805480610b8a57634e487b7160e01b600052603160045260246000fd5b600082815260209020810160001990810180546001600160a01b0319169055019055805b610bb9600185611447565b811015610c2f576002838281518110610be257634e487b7160e01b600052603260045260246000fd5b60209081029190910181015182546001810184556000938452919092200180546001600160a01b0319166001600160a01b0390921691909117905580610c27816114a1565b915050610bae565b5050505050565b80610c408161148a565b915050610a61565b50505050565b600080825160411415610c855760208301516040840151606085015160001a610c7987828585610ec2565b94509450505050610cb7565b825160401415610caf5760208301516040840151610ca4868383610faf565b935093505050610cb7565b506000905060025b9250929050565b6000816004811115610ce057634e487b7160e01b600052602160045260246000fd5b1415610ce95750565b6001816004811115610d0b57634e487b7160e01b600052602160045260246000fd5b1415610d595760405162461bcd60e51b815260206004820152601860248201527f45434453413a20696e76616c6964207369676e617475726500000000000000006044820152606401610335565b6002816004811115610d7b57634e487b7160e01b600052602160045260246000fd5b1415610dc95760405162461bcd60e51b815260206004820152601f60248201527f45434453413a20696e76616c6964207369676e6174757265206c656e677468006044820152606401610335565b6003816004811115610deb57634e487b7160e01b600052602160045260246000fd5b1415610e445760405162461bcd60e51b815260206004820152602260248201527f45434453413a20696e76616c6964207369676e6174757265202773272076616c604482015261756560f01b6064820152608401610335565b6004816004811115610e6657634e487b7160e01b600052602160045260246000fd5b1415610ebf5760405162461bcd60e51b815260206004820152602260248201527f45434453413a20696e76616c6964207369676e6174757265202776272076616c604482015261756560f01b6064820152608401610335565b50565b6000807f7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0831115610ef95750600090506003610fa6565b8460ff16601b14158015610f1157508460ff16601c14155b15610f225750600090506004610fa6565b6040805160008082526020820180845289905260ff881692820192909252606081018690526080810185905260019060a0016020604051602081039080840390855afa158015610f76573d6000803e3d6000fd5b5050604051601f1901519150506001600160a01b038116610f9f57600060019250925050610fa6565b9150600090505b94509492505050565b6000806001600160ff1b03831660ff84901c601b01610fd087828885610ec2565b935093505050935093915050565b600082601f830112610fee578081fd5b813567ffffffffffffffff811115611008576110086114d2565b61101b601f8201601f1916602001611416565b81815284602083860101111561102f578283fd5b816020850160208301379081016020019190915292915050565b60006020828403121561105a578081fd5b813561030f816114e8565b6000806000806080858703121561107a578283fd5b8435611085816114e8565b93506020858101359350604086013567ffffffffffffffff808211156110a9578485fd5b6110b589838a01610fde565b945060608801359150808211156110ca578384fd5b818801915088601f8301126110dd578384fd5b8135818111156110ef576110ef6114d2565b8060051b6110fe858201611416565b8281528581019085870183870188018e1015611118578889fd5b8893505b848410156111555780358681111561113257898afd5b6111408f8a838b0101610fde565b8452506001939093019291870191870161111c565b50999c989b5096995050505050505050565b60008060408385031215611179578182fd5b8235611184816114e8565b946020939093013593505050565b600080604083850312156111a4578182fd5b82359150602083013567ffffffffffffffff8111156111c1578182fd5b6111cd85828601610fde565b9150509250929050565b6000602082840312156111e8578081fd5b5035919050565b60008060008060808587031215611204578384fd5b843593506020850135611216816114e8565b925060408501359150606085013567ffffffffffffffff811115611238578182fd5b61124487828801610fde565b91505092959194509250565b6000815180845261126881602086016020860161145e565b601f01601f19169290920160200192915050565b60006bffffffffffffffffffffffff19808960601b168352876014840152866034840152808660601b1660548401525083606883015282516112c581608885016020870161145e565b91909101608801979650505050505050565b600082516112e981846020870161145e565b9190910192915050565b60018060a01b038716815285602082015260c06040820152600061131a60c0830187611250565b85606084015284608084015282810360a08401526113388185611250565b9998505050505050505050565b60006060820160018060a01b03808716845260206060818601528287548085526080870191508886528286209450855b81811015611393578554851683526001958601959284019201611375565b505080945050505050826040830152949350505050565b60208152600061030f6020830184611250565b6020808252600890820152672737ba1029b2b63360c11b604082015260600190565b6020808252601e908201527f4d757374206265206e6f6e2d7a65726f20736967732072657175697265640000604082015260600190565b604051601f8201601f1916810167ffffffffffffffff8111828210171561143f5761143f6114d2565b604052919050565b600082821015611459576114596114bc565b500390565b60005b83811015611479578181015183820152602001611461565b83811115610c485750506000910152565b600081611499576114996114bc565b506000190190565b60006000198214156114b5576114b56114bc565b5060010190565b634e487b7160e01b600052601160045260246000fd5b634e487b7160e01b600052604160045260246000fd5b6001600160a01b0381168114610ebf57600080fdfea2646970667358221220130a1dbeeabb9f56f72ca2bd92b075191e2abed435b346a03b2929caf5ee573464736f6c63430008040033";

    contractBytecode = abi.encodePacked(contractBytecode, abi.encode(_chainId, _owners, _signaturesRequired, address(this)));

    assembly {
        addr := create2(0, add(contractBytecode, 0x20), mload(contractBytecode), salt)

        if iszero(extcodesize(addr)) {
            revert(0, 0)
        }
    }


    //MultiSigWallet multiSig = (new MultiSigWallet){value: msg.value}(_chainId, _owners, _signaturesRequired, address(this));
    MultiSigWallet multiSig = MultiSigWallet(addr);

    multiSigs.push(multiSig);
    existsMultiSig[address(multiSig)] = true;

    emit Create(id, address(multiSig), msg.sender, _owners, _signaturesRequired);
    emit Owners(address(multiSig), _owners, _signaturesRequired);
  }

  function numberOfMultiSigs() public view returns(uint) {
    return multiSigs.length;
  }

  function getMultiSig(uint256 _index)
    public
    view
    returns (
      address multiSigAddress,
      uint signaturesRequired,
      uint balance
    ) {
      MultiSigWallet multiSig = multiSigs[_index];
      return (address(multiSig), multiSig.signaturesRequired(), address(multiSig).balance);
    }

// naim create2 implimentation
    function create2(
        uint256 _chainId,
        address[] memory _owners,
        uint256 _signaturesRequired,
        bytes32 _salt,
        string memory _name
    ) public payable {
        uint256 id = numberOfMultiSigs();

        /**----------------------
         * create2 implementation
         * ---------------------*/
        address multiSig_address = payable(
            Create2.deploy(
                msg.value,
                _salt,
                abi.encodePacked(
                    type(MultiSigWallet).creationCode,
                    abi.encode(_name, address(this))
                )
            )
        );

        MultiSigWallet multiSig = MultiSigWallet(payable(multiSig_address));

        /**----------------------
         * init remaining values
         * ---------------------*/
        multiSig.init(_chainId, _owners, _signaturesRequired);

        multiSigs.push(multiSig);
        existsMultiSig[address(multiSig_address)] = true;

        emit Create2Event(
            id,
            _name,
            address(multiSig),
            msg.sender,
            _owners,
            _signaturesRequired
        );
        emit Owners(address(multiSig), _owners, _signaturesRequired);
    }

    /**----------------------
     * get a computed address 
     * ---------------------*/
    function computedAddress(bytes32 _salt, string memory _name)
        public
        view
        returns (address)
    {
        bytes32 bytecodeHash = keccak256(
            abi.encodePacked(
                type(MultiSigWallet).creationCode,
                abi.encode(_name, address(this))
            )
        );
        address computed_address = Create2.computeAddress(_salt, bytecodeHash);

        return computed_address;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// never forget the OG simple sig wallet: https://github.com/christianlundkvist/simple-multisig/blob/master/contracts/SimpleMultiSig.sol

pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./MultiSigFactory.sol";

contract MultiSigWallet {
    using ECDSA for bytes32;
    MultiSigFactory private multiSigFactory;
    uint256 public factoryVersion = 1; // <---- set the factory version for backword compatiblity for future contract updates

    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event ExecuteTransaction(
        address indexed owner,
        address payable to,
        uint256 value,
        bytes data,
        uint256 nonce,
        bytes32 hash,
        bytes result
    );
    event Owner(address indexed owner, bool added);

    mapping(address => bool) public isOwner;

    address[] public owners;

    uint256 public signaturesRequired;
    uint256 public nonce;
    uint256 public chainId;
    string public name;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not owner");
        _;
    }

    modifier onlySelf() {
        require(msg.sender == address(this), "Not Self");
        _;
    }

    modifier requireNonZeroSignatures(uint256 _signaturesRequired) {
        require(_signaturesRequired > 0, "Must be non-zero sigs required");
        _;
    }
    modifier onlyFactory() {
        require(msg.sender == address(multiSigFactory));
        _;
    }

    // constructor(
    //     uint256 _chainId,
    //     address[] memory _owners,
    //     uint256 _signaturesRequired,
    //     address _factory,
    //     string memory _name
    // ) payable requireNonZeroSignatures(_signaturesRequired) {
    //     multiSigFactory = MultiSigFactory(_factory);
    //     signaturesRequired = _signaturesRequired;
    //     for (uint256 i = 0; i < _owners.length; i++) {
    //         address owner = _owners[i];

    //         require(owner != address(0), "constructor: zero address");
    //         require(!isOwner[owner], "constructor: owner not unique");

    //         isOwner[owner] = true;
    //         owners.push(owner);

    //         emit Owner(owner, isOwner[owner]);
    //     }

    //     chainId = _chainId;
    //     name = _name;
    // }

    constructor(string memory _name, address _factory) payable {
        name = _name;
        multiSigFactory = MultiSigFactory(_factory);
    }

    function init(
        uint256 _chainId,
        address[] memory _owners,
        uint256 _signaturesRequired
    ) public payable onlyFactory {
        signaturesRequired = _signaturesRequired;
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "constructor: zero address");
            require(!isOwner[owner], "constructor: owner not unique");

            isOwner[owner] = true;
            owners.push(owner);

            emit Owner(owner, isOwner[owner]);
        }

        chainId = _chainId;
    }

    function addSigner(address newSigner, uint256 newSignaturesRequired)
        public
        onlySelf
        requireNonZeroSignatures(newSignaturesRequired)
    {
        require(newSigner != address(0), "addSigner: zero address");
        require(!isOwner[newSigner], "addSigner: owner not unique");

        isOwner[newSigner] = true;
        owners.push(newSigner);
        signaturesRequired = newSignaturesRequired;

        emit Owner(newSigner, isOwner[newSigner]);
        multiSigFactory.emitOwners(
            address(this),
            owners,
            newSignaturesRequired
        );
    }

    function removeSigner(address oldSigner, uint256 newSignaturesRequired)
        public
        onlySelf
        requireNonZeroSignatures(newSignaturesRequired)
    {
        require(isOwner[oldSigner], "removeSigner: not owner");

        _removeOwner(oldSigner);
        signaturesRequired = newSignaturesRequired;

        emit Owner(oldSigner, isOwner[oldSigner]);
        multiSigFactory.emitOwners(
            address(this),
            owners,
            newSignaturesRequired
        );
    }

    function _removeOwner(address _oldSigner) private {
        isOwner[_oldSigner] = false;
        uint256 ownersLength = owners.length;
        address[] memory poppedOwners = new address[](owners.length);
        for (uint256 i = ownersLength - 1; i >= 0; i--) {
            if (owners[i] != _oldSigner) {
                poppedOwners[i] = owners[i];
                owners.pop();
            } else {
                owners.pop();
                for (uint256 j = i; j < ownersLength - 1; j++) {
                    owners.push(poppedOwners[j + 1]); // shout out to moltam89!! https://github.com/austintgriffith/maas/pull/2/commits/e981c5fa5b4d25a1f0946471b876f9a002a9a82b
                }
                return;
            }
        }
    }

    function updateSignaturesRequired(uint256 newSignaturesRequired)
        public
        onlySelf
        requireNonZeroSignatures(newSignaturesRequired)
    {
        signaturesRequired = newSignaturesRequired;
    }

    function executeTransaction(
        address payable to,
        uint256 value,
        bytes memory data,
        bytes[] memory signatures
    ) public onlyOwner returns (bytes memory) {
        bytes32 _hash = getTransactionHash(nonce, to, value, data);

        nonce++;

        uint256 validSignatures;
        address duplicateGuard;
        for (uint256 i = 0; i < signatures.length; i++) {
            address recovered = recover(_hash, signatures[i]);
            require(
                recovered > duplicateGuard,
                "executeTransaction: duplicate or unordered signatures"
            );
            duplicateGuard = recovered;

            if (isOwner[recovered]) {
                validSignatures++;
            }
        }

        require(
            validSignatures >= signaturesRequired,
            "executeTransaction: not enough valid signatures"
        );

        (bool success, bytes memory result) = to.call{value: value}(data);
        require(success, "executeTransaction: tx failed");

        emit ExecuteTransaction(
            msg.sender,
            to,
            value,
            data,
            nonce - 1,
            _hash,
            result
        );
        return result;
    }

    function getTransactionHash(
        uint256 _nonce,
        address to,
        uint256 value,
        bytes memory data
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    address(this),
                    chainId,
                    _nonce,
                    to,
                    value,
                    data
                )
            );
    }

    function recover(bytes32 _hash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        return _hash.toEthSignedMessageHash().recover(_signature);
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function numberOfOwners() public view returns (uint256) {
        return owners.length;
    }
}