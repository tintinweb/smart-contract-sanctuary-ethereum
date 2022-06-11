/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

pragma solidity 0.5.11;

contract EventLog {
    address private owner;
    mapping(address => mapping(uint256 => uint256)) public _nonce; //Key identity -> (Key Id -> Value: uint))
    event Log(
        uint256 signatureId,
        uint256 indexed id,
        string log,
        address sender
    );

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function setLog(
        uint256 signatureId,
        uint256 id,
        string memory log
    ) public isOwner {
        _setLog(signatureId, id, log, msg.sender);
    }

    function setLogContent(
        uint256 signatureId,
        uint256 id,
        string memory log,
        address from,
        bytes memory sig,
        bytes memory friendlyHash
    ) public isOwner {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0),
                this,
                _nonce[from][id],
                from,
                "setLogContent",
                signatureId,
                id,
                log,
                friendlyHash
            )
        );
        address signer = checkSignature(from, sig, hash, id);
        _setLog(signatureId, id, log, signer);
    }

    function _setLog(
        uint256 signatureId,
        uint256 id,
        string memory log,
        address sender
    ) private {
        emit Log(signatureId, id, log, sender);
    }

    function checkSignature(
        address identity,
        bytes memory sig,
        bytes32 hash,
        uint256 id
    ) internal returns (address) {
        address signer = ecrecovery(hash, sig);
        require(signer == identity, "signer <> identity");
        _nonce[signer][id]++;
        return signer;
    }

    function ecrecovery(bytes32 hash, bytes memory sig)
        internal
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65) {
            return address(0);
        }

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := and(mload(add(sig, 65)), 255)
        }

        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        return ecrecover(hash, v, r, s);
    }
}