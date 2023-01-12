/**
 *Submitted for verification at Etherscan.io on 2023-01-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title gasChargebackUserWallet
 * @dev Store user's tokens and allow transactions to be sent by this user 
 * without the user paying the transaction fee
 */
contract gasChargebackUserWallet {

    //the externally owned account (EOA) associated to this smart contract wallet
    //only metaTransactions signed by the _owner address can be processed by this contract
    address _walletOwner; 
    //the metaTransaction nonce, which is incremented in sequence after each metaTransaction has been processed
    uint256 _sequence;
    //the unique identifier of this blockchain
    uint256 _chainId; 
    //the externally owned account (EOA) that can package metaTransactions into a transaction and send to this contract
    address _relayer; 

    /**
     * @dev Emitted when a metaTransaction identified by `metaTransactionHash` has been processed. 
     * The `success` parameter indicates if the metaTransaction completed correctly (true) or not (false).
     */
    event MetaTransactionResults(bytes32 metaTransactionHash, bool success);

    /**
     * @dev Instantiates this smart contract wallet. On deployment, this contract needs to use the correct chainId. Also a designated relayer is assigned
     */
    constructor(address walletOwner_, address relayer_) {
        _chainId = block.chainid;
        _walletOwner = walletOwner_;
        _relayer = relayer_;
    }

    /**
     * @dev Processes the metaTransaction, if it was correctly signed by the owner of this smart contract wallet
     * @param to - the address that the metaTransaction is to be sent to
     * @param value - how much ETH to sent to the receiptent
     * @param data - any additional payload for the metaTransaction
     * @param gasLimit - the limit for gas that this metaTransaction can use. Required so that the relayer knows the maximum funds it will drain. 
     * @param signature - the signature of the full metaTransaction (chainId, sequence, to, value, data)
     */
    function forwardCall(address to, uint256 value, bytes calldata data, uint256 gasLimit, bytes calldata signature) public {
      
        //stop loops by other contracts back in to this function:
        require(msg.sender == _relayer, "Only the relayer can call this transaction"); 
        //NOTES: No need to pass in nonce as it is recorded in the contract
      
        //here the metaTransaction is rebuilt with a combination of stored variables and passed in data
        //Gaslimit is not included in the metaTransaction as it needs to be estimated after the user has signed the metaTransaction
        bytes32 metaTransactionHash = hash((metaTransactionMessage(_chainId, _sequence, to, value, data))); 
        
        //now perform the signature check and reverts if the signature does not come from the owner address 
        checkSignature(metaTransactionHash, signature, _walletOwner);

        // update the nonce so no metaTransaction can be replayed:
        _sequence += 1;

        //Now the metaTransaction is processed via the safeCall function, which triggers a low level smart contract call.
        //SafeCall, inspired by the Optimism bridge, is used in order to stop "gas bomb" and "griefing" attacks (more on these below)
        //Firstly, a gaslimit is required by this function in order to make sure that the metaTransaction does not use unexpected amounts of gas, which could drain the relayers funds (this is a griefing attack)
        //Secondly safeCall only returns success, which is used for logging. A separate log is needed as metaTransaction execution success should be separate from the standard transaction success
        //Thirdly, safeCall does not return returnedData from the smart contract invoke as (a) it wouldn't resemble running this metaTransaction as a normal smart contract invoke transaction (which does not return data - only smart contract to smart contract interactions allow for returnedData); 
        //and (b) this additionally avoids the possibility of a "gas bomb" attack (a malicious contract sending high amounts of data back to this contract to drain the relayers funds). Gas bomb attacks can actually work around the designated gasLimit of the low level call.
        bool success = safecall(to, gasLimit, value, data);

        //log the results of this meta
        emit MetaTransactionResults(metaTransactionHash, success);

    }

    /**
     * Finds the signer of the metaTransaction and reverts if this address is not this contract's owner
     * @param metaTransactionHash - the hash of the metaTransaction
     * @param metaTransactionSignature - the signature of the metaTransaction
     * @param signer - the expected signer address
     */
    function checkSignature(bytes32 metaTransactionHash, bytes memory metaTransactionSignature, address signer) public pure {
        //concat the transaction hash with a ethereum specific prefix in order to make sure that the signature was only used for this purpose
        bytes32 generatedhash = prefixed(metaTransactionHash); 
        if(recoverSigner(generatedhash, metaTransactionSignature) != signer){
            revert("MetaTransaction not signed by owner address");
        }

    }

    /**
     * Finds the signer of a message
     * @param message - the message
     * @param sig - the signed bytes
     * @return - the address of the signer
     */
    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    /**
     * Finds the v, r and s value of the signature
     * @param sig - the signed bytes
     * @return v - the signature's v value
     * @return r - the signature's r value
     * @return s - the signature's s value
     */
    function splitSignature(bytes memory sig) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(sig.length == 65);
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
    }

    /**
     * @notice Perform a low level call without copying any returndata
     *
     * @param _target   Address to call
     * @param _gas      Amount of gas to pass to the call
     * @param _value    Amount of value to pass to the call
     * @param _calldata Calldata to pass to the call
     */
    function safecall(
        address _target,
        uint256 _gas,
        uint256 _value,
        bytes memory _calldata
    ) internal returns (bool) {
        bool _success;
        assembly {
            _success := call(
                _gas, // gas
                _target, // recipient
                _value, // ether value
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
        }
        return _success;
    }

    /**
     * @dev builds a prefixed hash to mimic the behavior of eth_sign.
     * @param singleHash - the hash of the message
     * @return - hash of the message mimicing the signing
     */
    function prefixed(bytes32 singleHash) internal pure returns (bytes32) {
        //this is so that the signed message cannot be used in other applications
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", singleHash)); 
    }

    /**
     * @dev Returns the owner of the contract wallet
     */
    function owner() public view returns (address) {
        return _walletOwner;
    }

    /**
     * @dev Returns the sequence (nonce) of this contract wallet
     */
    function sequence() public view returns (uint256){
        return _sequence;
    }

    /**
     * @dev Returns the chainId of this contract wallet
     */
    function chainId() public view returns (uint256){
        return _chainId;
    }

    /**
     * @dev Returns the relayer of this contract wallet
     */
    function relayer() public view returns (address){
        return _relayer;
    }

    /**
     * @dev Returns the hash of a given message
     * @param message - what you have to hash
     */
    function hash(bytes memory message) public pure returns (bytes32){
        //returns a hash of a dummy metaTransaction
        return prefixed(keccak256(message)); 
    }

    /**
     * @dev Builds a metaTransaction with the given inputs
     * @param thisChainId - the unique id of the chain
     * @param thisSequence - the unique nonce in sequence style
     * @param to - the address that the metaTransaction is to be sent to
     * @param value - how much ETH to sent to the recipient
     * @param data - any additional payload for the metaTransaction
     */
    function metaTransactionMessage(uint256 thisChainId, uint256 thisSequence, address to, uint256 value, bytes calldata data) public pure returns (bytes memory){
        //returns a hash of a dummy metaTransaction
        return abi.encodePacked(thisChainId, thisSequence, to, value, data); 
    }

}