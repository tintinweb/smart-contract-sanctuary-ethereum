//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./SmartWallet.sol";

contract Factory {
    event Created(
        address _contract
    );

    mapping(address => bool) public contracts;

    function call(
        address _owner,
        uint256 _nonce,
        address[] memory _logicContractAddress,
        bytes[] memory _payload,
        uint256[] memory _value,
        uint256 _timeout,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public {
        address addr = getSmartWalletAddress(_owner, _nonce);
        if (addr.code.length == 0) {
            contracts[address(addr)] = true;
            emit Created(address(addr));
            new SmartWallet{salt: keccak256(abi.encode(_owner, _nonce))}(_owner);
        }

        SmartWallet(payable(addr)).call(_logicContractAddress, _payload, _value, _timeout, _v, _r, _s);
    }

    function getSmartWalletAddress(address _owner, uint256 _nonce) public view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), keccak256(abi.encode(_owner, _nonce)), keccak256(getBytecode(_owner)))
        );

        return address(uint160(uint(hash)));
    }

    function getBytecode(address _owner) public view returns (bytes memory) {
        return abi.encodePacked(type(SmartWallet).creationCode, abi.encode(_owner));
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SmartWallet is ReentrancyGuard {
    uint256 public nonce;
    address public owner;

    event CallEvent(
        uint256 _nonce,
        bytes _returnData
    );

    constructor(address _owner) {
        owner = _owner;
    }

    receive() external payable {}

    function call(
        address[] memory _logicContractAddress,
        bytes[] memory _payload,
        uint256[] memory _value,
        uint256 _timeout,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public nonReentrant {
        require(_timeout > block.number, "Transaction timed out");
        bytes32 hash = keccak256(abi.encode(address(this), nonce, _logicContractAddress, _payload, _value, _timeout));
        require(verifySig(owner, hash, _v, _r, _s), "Incorrect sig");

        for (uint8 i = 0; i < _logicContractAddress.length; i++) {
            nonce++;
            bytes memory returnData = functionCallWithValue(_logicContractAddress[i], _payload[i], _value[i]);
            emit CallEvent(nonce - 1, returnData);
        }
    }

    function verifySig(
        address _signer,
        bytes32 _theHash,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) private pure returns (bool) {
        return _signer == ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _theHash)), _v, _r, _s);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert();
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}