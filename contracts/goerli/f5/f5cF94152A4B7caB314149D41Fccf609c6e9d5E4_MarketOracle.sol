// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

// Binary Oracle
interface IOracle {
    function checkResult(
        bytes32 marketId,
        bytes32 propositionId
    ) external view returns (bool);

    function getResult(bytes32 marketId) external view returns (bytes32);

    function setResult(
        bytes32 marketId,
        bytes32 propositionId,
        bytes32 sig
    ) external;

    event ResultSet(bytes32 marketId, bytes32 propositionId);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "./IOracle.sol";
import "./SignatureLib.sol";

contract MarketOracle is IOracle {
    mapping(bytes32 => bytes32) private _results;
    address private immutable _owner;

    constructor() {
        _owner = msg.sender;
    }

    function checkResult(
        bytes32 marketId,
        bytes32 propositionId
    ) external view returns (bool) {
        require(
            propositionId !=
                0x0000000000000000000000000000000000000000000000000000000000000000,
            "getBinaryResult: Invalid propositionId"
        );
        return _results[marketId] == propositionId;
    }

    function getResult(bytes32 marketId) external view returns (bytes32) {
        require(
            marketId !=
                0x0000000000000000000000000000000000000000000000000000000000000000,
            "getBinaryResult: Invalid propositionId"
        );
        return _results[marketId];
    }

    function setResult(
        bytes32 marketId,
        bytes32 propositionId,
        bytes32 sig
    ) external {
        require(
            propositionId !=
                0x0000000000000000000000000000000000000000000000000000000000000000,
            "setBinaryResult: Invalid propositionId"
        );
        require(
            _results[marketId] ==
                0x0000000000000000000000000000000000000000000000000000000000000000,
            "setBinaryResult: Result already set"
        );
        _results[marketId] = propositionId;

        emit ResultSet(marketId, propositionId);
    }

    modifier onlyMarketOwner(
        bytes32 messageHash,
        SignatureLib.Signature memory sig
    ) {
        require(
            SignatureLib.recoverSigner(messageHash, sig) == _owner,
            "onlyMarketOwner: Invalid signature"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

library SignatureLib {
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function recoverSigner(
        bytes32 message,
        Signature memory signature
    ) public pure returns (address) {
        bytes32 prefixedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", message)
        );
        return ecrecover(prefixedHash, signature.v, signature.r, signature.s);
    }
}