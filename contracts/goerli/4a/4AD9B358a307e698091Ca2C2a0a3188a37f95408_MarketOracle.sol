// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

// Binary Oracle
interface IOracle {
    function checkResult(
        bytes16 marketId,
        bytes16 propositionId
    ) external view returns (bool);

    function getResult(bytes16 marketId) external view returns (bytes16);

    function setResult(
        bytes16 marketId,
        bytes16 propositionId,
        bytes32 sig
    ) external;

    event ResultSet(bytes16 marketId, bytes16 propositionId);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "./IOracle.sol";
import "./SignatureLib.sol";

contract MarketOracle is IOracle {
    mapping(bytes16 => bytes16) private _results;
    address private immutable _owner;

    constructor() {
        _owner = msg.sender;
    }

    function checkResult(
        bytes16 marketId,
        bytes16 propositionId
    ) external view returns (bool) {
        require(
            propositionId != bytes16(0),
            "getBinaryResult: Invalid propositionId"
        );
        return _results[marketId] == propositionId;
    }

    function getResult(bytes16 marketId) external view returns (bytes16) {
        require(
            marketId != bytes16(0),
            "getBinaryResult: Invalid propositionId"
        );
        return _results[marketId];
    }

    function setResult(
        bytes16 marketId,
        bytes16 propositionId,
        bytes32 sig
    ) external {
        require(
            propositionId != bytes16(0),
            "setBinaryResult: Invalid propositionId"
        );
        require(
            _results[marketId] == bytes16(0),
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