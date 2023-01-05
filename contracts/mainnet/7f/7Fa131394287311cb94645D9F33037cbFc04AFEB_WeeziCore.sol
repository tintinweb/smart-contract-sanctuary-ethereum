// SPDX-License-Identifier: Unlicense
// Developed by EasyChain Blockchain Development Team (easychain.tech)
//
pragma solidity ^0.4.24;

import "../../contracts/lib/Ownable.sol";

contract WeeziCore is Ownable {
    // Address of Oracle
    //
    address public oracleAddress = 0x94568b630329555Ebc5b2aC8F16b10994422bB42;
    address public feeWalletAddress;
    // Signature expiration time
    //
    uint256 public signatureValidityDuractionSec = 3600;

    event SetOracleAddress(address oracleAddress);
    event SetFeeWalletAddress(address feeWalletAddress);

    function isValidSignatureDate(uint256 _timestamp)
        public
        view
        returns (bool)
    {
        return computeSignatureDateDelta(_timestamp) <= signatureValidityDuractionSec;
    }

    function computeSignatureDateDelta(uint256 _timestamp)
        public
        view
        returns (uint256)
    {
        uint256 timeDelta = 0;
        if (_timestamp >= block.timestamp) {
            timeDelta = _timestamp - block.timestamp;
        } else {
            timeDelta = block.timestamp - _timestamp;
        }
        return timeDelta;
    }

    // Validates oracle price signature
    //
    function isValidSignature(
        bytes32 _hash,
        bytes memory _signature
    ) public view returns (bool) {
        return recover(_hash, _signature) == oracleAddress;
    }

    // Validates oracle price signature
    //
    function recover(
        bytes32 _hash,
        bytes memory _signature
    ) public pure returns (address) {
        bytes32 signedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
        );
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        address signer = ecrecover(signedMessageHash, v, r, s);
        return signer;
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature
            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature
            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    function setSignatureValidityDurationSec(
        uint256 _signatureValidityDuractionSec
    ) public onlyOwner {
        require(_signatureValidityDuractionSec > 0);

        signatureValidityDuractionSec = _signatureValidityDuractionSec;
    }

    // Sets an address of Oracle
    // _oracleAddres - Oracle
    //
    function setOracleAddress(address _oracleAddres) public onlyOwner {
        oracleAddress = _oracleAddres;
        emit SetOracleAddress(_oracleAddres);
    }

    // Sets an address of Fee Wallet
    // _feeWalletAddress - Fee Wallet
    //
    function setFeeWalletAddress(address _feeWalletAddress) public onlyOwner {
        feeWalletAddress = _feeWalletAddress;
        emit SetFeeWalletAddress(_feeWalletAddress);
    }

    function getFeeWalletAddress() view public returns (address) {
        return feeWalletAddress;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity 0.4.24;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() public {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}