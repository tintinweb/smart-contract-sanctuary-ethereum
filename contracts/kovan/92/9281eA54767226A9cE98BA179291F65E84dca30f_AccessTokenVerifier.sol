// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "./IAccessTokenVerifier.sol";
import "./KeyInfrastructure.sol";

contract AccessTokenVerifier is IAccessTokenVerifier, KeyInfrastructure {
    bytes32 private constant EIP712DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    // solhint-disable max-line-length
    bytes32 private constant FUNCTIONCALL_TYPEHASH =
        keccak256("FunctionCall(bytes4 functionSignature,address target,address caller,bytes parameters)");

    // solhint-disable max-line-length
    bytes32 private constant TOKEN_TYPEHASH =
        keccak256(
            "AccessToken(uint256 expiry,FunctionCall functionCall)FunctionCall(bytes4 functionSignature,address target,address caller,bytes parameters)"
        );

    // solhint-disable var-name-mixedcase
    bytes32 public DOMAIN_SEPARATOR;

    constructor(address root) KeyInfrastructure(root) {
        DOMAIN_SEPARATOR = hash(
            EIP712Domain({
                name: "Ethereum Access Token",
                version: "1",
                chainId: block.chainid,
                verifyingContract: address(this)
            })
        );
    }

    function hash(EIP712Domain memory eip712Domain) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712DOMAIN_TYPEHASH,
                    keccak256(bytes(eip712Domain.name)),
                    keccak256(bytes(eip712Domain.version)),
                    eip712Domain.chainId,
                    eip712Domain.verifyingContract
                )
            );
    }

    function hash(FunctionCall memory call) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    FUNCTIONCALL_TYPEHASH,
                    call.functionSignature,
                    call.target,
                    call.caller,
                    keccak256(call.parameters)
                )
            );
    }

    function hash(AccessToken memory token) internal pure returns (bytes32) {
        return keccak256(abi.encode(TOKEN_TYPEHASH, token.expiry, hash(token.functionCall)));
    }

    function verify(
        AccessToken memory token,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view override returns (bool) {
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hash(token)));

        require(token.expiry > block.timestamp, "AccessToken: has expired");

        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("AccessToken: invalid signature s");
        }

        if (v != 27 && v != 28) {
            revert("AccessToken: invalid signature v");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(digest, v, r, s);
        if (signer == address(0)) {
            revert("AccessToken: invalid signature");
        }

        return signer == _issuer;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
}

// struct FunctionParam {
//     string typ; // explicit full solidity atomic type of the parameter
//     bytes value; // the byte formatted parameter value
// }

struct FunctionCall {
    // string name; // name of the function being called
    bytes4 functionSignature;
    address target;
    address caller;
    bytes parameters;
    // FunctionParam[] parameters; // array of input parameters to the function call
}

struct AccessToken {
    uint256 expiry;
    FunctionCall functionCall;
}

interface IAccessTokenVerifier {
    function verify(
        AccessToken memory token,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

contract KeyInfrastructure {
    address internal _root;
    address internal _intermediate;
    address payable internal _issuer;

    event IntermediateRotated(address newKey);
    event IssuerRotated(address newKey);

    modifier onlyRoot() {
        require(msg.sender == _root, "unauthorised: must be root");
        _;
    }

    modifier onlyIntermediate() {
        require(msg.sender == _intermediate, "unauthorised: must be intermediate");
        _;
    }

    modifier onlyIssuer() {
        require(msg.sender == _issuer, "not valid signer");
        _;
    }

    constructor(address root) {
        _root = root;
    }

    function rotateIntermediate(address newIntermediate) public onlyRoot {
        _intermediate = newIntermediate;
        emit IntermediateRotated(newIntermediate);
    }

    function rotateIssuer(address newIssuer) public onlyIntermediate {
        _issuer = payable(newIssuer);
        emit IssuerRotated(newIssuer);
    }

    function getRootKey() public view returns (address) {
        return _root;
    }

    function getIntermediateKey() public view returns (address) {
        return _intermediate;
    }

    function getIssuerKey() public view returns (address) {
        return _issuer;
    }
}