// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./IERC165.sol";
import "./IERC20.sol";

/**
 * @title Treasure
 * Based on code by OpenZeppelin AccessControl.sol
 */
contract Treasure is AccessControl {

    uint256 constant timestampMaxDiffInSeconds = 180;

    mapping(bytes32 => bool) private _hashUsedFlag;

    IERC20 private _acceptedToken;

    /**
     * @dev Initialize this contract. Acts as a constructor
    * @param acceptedToken_ - Address of the ERC20 accepted token
    */
    constructor(
        address acceptedToken_
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _acceptedToken = IERC20(acceptedToken_);
    }

    /**
    * @dev Function to withdraw tokens
   * @param _to The address that will receive the tokens.
   * @param _value The value of tokens to withdraw.
   * @param _timestamp The timestamp of withdraw.
   * @param _sig Signature.
   * @return A boolean that indicates if the operation was successful.
   */
    function withdraw(address _to, uint256 _value, uint256 _timestamp, bytes memory _sig)
    public returns (bool){

        require(
            (block.timestamp >= _timestamp) && (block.timestamp - _timestamp) <= timestampMaxDiffInSeconds,
            "timestamp is very different from the current time"
        );

        bytes32 hash = keccak256(abi.encodePacked(_to, _value, _timestamp));

        require(
            _hashUsedFlag[hash] == false,
            "timestamp is already used"
        );

        address msgSigner = recover(hash, _sig);
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msgSigner),
            "withdraw allowed only for users with admin role"
        );

        _hashUsedFlag[hash] = true;

        transfer(_to, _value);

        return true;
    }

    /**
    * @dev Function to transfer tokens
   * @param _to The address that will receive the tokens.
   * @param _value The amount of tokens to transfer.
   */
    function transfer(address _to, uint256 _value)
    public onlyRole(DEFAULT_ADMIN_ROLE) {

        _acceptedToken.transfer(_to, _value);
    }

    function recover(bytes32 hash, bytes memory sig) public pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        //Check the signature length
        if (sig.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }

}