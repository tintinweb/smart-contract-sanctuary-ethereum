pragma solidity ^0.5.8;

/** implement metatransactions.
 *
 * This contract stores a nonceTracker for every approving address. For success, the nonce passed in the sign data must corresponds
 *  to the actual nonce for approving address stored here. After the call, the nonce is incremented.
 *
 * 1. Entry point is method callViaProxyDelegated(address approvingAddress, address destinationAddress, bytes memory data, uint8 v, bytes32 r, bytes32 s)
 * Where:
 *    - approvingAddress: the signer of sign data. Then, the "approver" of this delegated call.
 *    - destinationAddress: contract address that will be called via call() method and passed data
 *    - data:  encoded data passed to destination in the delegated call. Must refer to an existing method of the destination contract.
 *    - v, r, s: parameters for sign verification. The signer must be approvingAddress for success.
 *
 * 2. callViaProxyDelegated verifies that the received sign is signed by approvingAddress. Here Applies some verifications, see the code below.
 * 3. If sign verification passes, then the call to the delegated is performed with this line of code:
 *          (bool success, bytes memory _returnData) = destination.call(data);
 *    - Here, destination is the smart contract that has the called method (Vault contract).
 *    - Is important that "data" is correct and corresponds to one of destination smart contrac methods and parameters (abi-encoded).
 * 4. If the delegated call ends with success, the function will return with success.
 * 5. If case of success, returned data is delegated call returned data.
 *
 *
 */

contract MetaTransactionsProvider {//is Ownable, is forwarder, SignatureVerifier {


    // nonce tracker mapping address to proxies/nonces
    //nonce must be queryed from this public method, and build the sign with it.
    mapping (address => uint) public nonceTracker;

	//Used in signature validation
	string public signPrefix = "Signed for MetaTransaction";

	constructor() public {
		nonceTracker[msg.sender]=0;
	}


	function () external payable { }



    /////////////////////////////////////////////////////////////////////////////////////////////
    // call via proxy from approvingAddress with meta-transaction
    function callViaProxyDelegated(
        address approvingAddress, address destinationAddress, bytes memory data,
        uint8 v, bytes32 r, bytes32 s
    )
        public  returns (bytes memory returnData)
    {

        require(
			isSignatureValid(
				approvingAddress,
				destinationAddress,
				v,r,s
			),
            "Permission denied."
        );
        nonceTracker[approvingAddress] += 1;

		//return bytes("0x0");
        return forwardCall(destinationAddress, data);
    }



    /////////////////////////////////////////////////////////////////////////////////////////////
    // Copied from Forwarder.sol for simplify purposes
        function forwardCall(address destination, bytes memory data)
		private returns (bytes memory returnData) {
            // solium-disable-next-line security/no-low-level-calls
            (bool success, bytes memory _returnData) = destination.call(data);
            require(success, "Call was not successful.");
            return _returnData;
        }
    //End of forwarder.sol



	/**
     * generates a prefixed hash of the address
     * We hash the following together:
     * - signPrefix
     * - address of this contract
     * - the recievers-address (MockVault in this example)
	 * - the nonce of the approvingAddress (who is the signer)
     */
    function prefixedHash(
        address approvingAddress, address receiver
    ) public view returns(bytes32) {
        bytes32 hash = keccak256(
			abi.encodePacked(
				signPrefix,
				address(this),
				receiver,
				nonceTracker[approvingAddress]
			)
        );
        return hash;
    }

    /**
     * validates if the signature is valid
     * by checking if the correct message was signed
     */
    function isSignatureValid(
        address approvingAddress,
		address receiver,
        uint8 v,
        bytes32 r,
        bytes32 s
        ) public view returns (bool correct) {
        bytes32 mustBeSigned = prefixedHash(approvingAddress,receiver);
        address calculatedSigner = ecrecover(
            mustBeSigned,
            v, r, s
        );

        return (approvingAddress == calculatedSigner);
    }

}