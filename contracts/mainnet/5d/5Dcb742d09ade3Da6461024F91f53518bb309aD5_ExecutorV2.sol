// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract Adminable {
    event AdminUpdated(address sender, address oldAdmin, address admin);

    address public admin;

    modifier onlyAdmin() {
        require(admin == msg.sender, "only admin");
        _;
    }

    function updateAdmin(address admin_) external onlyAdmin {
        require(admin_ != address(0), "zero address");
        emit AdminUpdated(msg.sender, admin, admin_);
        admin = admin_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library ECDSA {
    function recover(
        bytes32 hash_,
        bytes memory signature_
    ) internal pure returns (address) {
        require(signature_.length == 65, "standart signature only");

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature_, 32))
            s := mload(add(signature_, 64))
            v := byte(0, mload(add(signature_, 96)))
        }

        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            revert("invalid signature 's' value");
        }
        if (v != 27 && v != 28) {
            revert("invalid signature 'v' value");
        }

        address signer = ecrecover(hash_, v, r, s);
        require(signer != address(0), "invalide signature");
        return signer;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Initializable.sol";
import "./Pausable.sol";
import "./ECDSA.sol";
import "./Mutex.sol";

contract ExecutorV2 is Initializable, Pausable, Mutex {
    uint16 public chainId;
    address public protocolSigner;
    mapping(bytes32 => uint256) public hashes;

    event SignerUpdated(address sender, address oldSigner, address signer);

    function init(
        address admin_,
        uint16 chainId_,
        address signer_
    ) external whenNotInitialized {
        require(admin_ != address(0), "zero address");
        require(signer_ != address(0), "zero address");
        admin = admin_;
        pauser = admin_;
        chainId = chainId_;
        protocolSigner = signer_;
        isInited = true;
    }

    function updateSigner(address signer_) external whenInitialized onlyAdmin {
        require(signer_ != address(0), "zero address");
        emit SignerUpdated(msg.sender, protocolSigner, signer_);
        protocolSigner = signer_;
    }

    function execute(
        uint16 callerChainId_,
        uint16 executionChainId_,
        uint256 nonce_,
        string calldata txHash_,
        address contract_,
        bytes calldata callData_,
        bytes calldata signature_
    ) external whenNotPaused whenInitialized mutex returns (bytes memory) {
        require(chainId == executionChainId_, "uncompatible chain");
        require(contract_ != address(0), "zero address");

        bytes32 data = keccak256(
            abi.encodePacked(
                callerChainId_,
                executionChainId_,
                nonce_,
                bytes(txHash_).length,
                txHash_,
                contract_,
                callData_.length,
                callData_
            )
        );

        require(hashes[data] == 0, "duplicate data");
        require(
            ECDSA.recover(
                keccak256(
                    abi.encodePacked("\x19Ethereum Signed Message:\n32", data)
                ),
                signature_
            ) == protocolSigner,
            "only protocol signer"
        );
        hashes[data] = block.number;

        (bool success_, bytes memory data_) = contract_.call(callData_);
        if (success_) {
            return data_;
        } else {
            if (data_.length > 0) {
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(data_)
                    revert(add(32, data_), returndata_size)
                }
            } else {
                revert("no error");
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract Initializable {
    bool internal isInited;

    modifier whenInitialized() {
        require(isInited, "not initialized");
        _;
    }

    modifier whenNotInitialized() {
        require(!isInited, "already initialized");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract Mutex {
    bool private _lock;

    modifier mutex() {
        require(!_lock, "mutex lock");
        _lock = true;
        _;
        _lock = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Adminable.sol";

abstract contract Pausable is Adminable {
    event Paused(address account);
    event Unpaused(address account);
    event PauserUpdated(address sender, address oldPauser, address pauser);

    bool public isPaused;
    address public pauser;

    constructor() {
        isPaused = false;
    }

    modifier whenNotPaused() {
        require(!isPaused, "paused");
        _;
    }

    modifier whenPaused() {
        require(isPaused, "not paused");
        _;
    }

    modifier onlyPauser() {
        require(pauser == msg.sender, "only pauser");
        _;
    }

    function pause() external whenNotPaused onlyPauser {
        isPaused = true;
        emit Paused(msg.sender);
    }

    function unpause() external whenPaused onlyPauser {
        isPaused = false;
        emit Unpaused(msg.sender);
    }

    function updatePauser(address pauser_) external onlyAdmin {
        require(pauser_ != address(0), "zero address");
        emit PauserUpdated(msg.sender, pauser, pauser_);
        pauser = pauser_;
    }
}