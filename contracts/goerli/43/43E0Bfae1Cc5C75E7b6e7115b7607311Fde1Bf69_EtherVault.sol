/**
 *Submitted for verification at Etherscan.io on 2023-03-07
*/

// SPDX-License-Identifier:MIT
/*


███████████████  ██████████████ ██    ██ █████ ██    █    ██████████
██     ██   ██   ███     ██   ████    ████   █ ██    █    █    ██
█████  ██   ███████████  ██████ ██    ███████████    █    █    ██
██     ██   ██   ███     ██   ██ ██  ██ ██   ██ █    █    █    ██
█████████   ██   ██████████   ██  ████  ██   ██ ████  ████  █████

Darkerego, 2023 ~ Ethervault is a lightweight, gas effecient,
multisignature

["0x7612E93FF157d1973D0f95Be9E4f0bdF93BAf0DE",
"0xF738Be6972c384211Da31fCAb979F1F81CB1397E",
"0xE1cb8a4e283315b653D3369a09411DF32eDc60F6"]
*/

pragma solidity ^0.8.17;

contract EtherVault {

    struct Transaction{
        address dest;
        uint256 value;
        bytes data;
        uint numSigners;
    }
    /*
      @dev: gas optimized variable packing
    */
    uint8 mutex;
    uint8 public immutable threshold;
    uint32 public execNonce;
    uint32 public lastDay;
    uint256 public immutable dailyLimit;
    uint256 public spentToday;
    string errNotFound = "Tx Not Found";
    
    error Unauthorized(address caller);

    mapping (address => bool) isSigner;
    mapping (uint256 => Transaction) pendingTxs;
    mapping (uint => mapping (address => uint)) public confirmations;
    event ExecAction(string indexed action, address indexed from, uint256 txid);

    function checkSigner(address s) private view {
        /*
          @dev: Checks if sender is caller.
        */
        if(! isSigner[s] || mutex == 1){
                  revert Unauthorized(s);
       }
    }
   
    modifier protected {
        /*
          @dev: Restricted function access protection and reentrancy guards.
          Saves some gas by combining these checks.
        */
       checkSigner(msg.sender);
       mutex = 1;
       _;
       mutex = 0;

    }

    constructor(
        address[] memory _signers,
        uint8 _threshold,
        uint256 _dailyLimit
        ){
            /*
              @dev: When I wrote this, I never imagined having more than 128 
              signers. If for some reason you do, you may want to modify this code.
            */
        unchecked{ // save some gas
        uint8 slen = uint8(_signers.length);
        for (uint8 i = 0; i < slen; i++) {
            isSigner[_signers[i]] = true;
        }
      }
        (threshold, dailyLimit, spentToday, mutex) = (_threshold, _dailyLimit, 0, 0);
    }

    function alreadySigned(
        /*
          @dev: Checks to make sure that signer cannot sign multiple times.
        */
        uint txid,
        address owner
    ) private view returns(bool){
       if(confirmations[txid][owner] == 0){
           return false;
       }
       return true;
    }

    function execute(
        address r,
        uint256 v,
        bytes memory d
        ) internal {
       /*
         @dev: Gas efficient arbitrary call in assembly.
       */
        assembly {
            let success_ := call(gas(), r, v, add(d, 0x00), mload(d), 0x20, 0x0)
            let success := eq(success_, 0x1)
            if iszero(success) {
                revert(mload(d), add(d, 0x20))
            }
        }
    }


    function revokeSigner(
        /*
          @dev: Remove an authorized signer.
        */
        address _signerAddr
        ) external protected {
        if (isSigner[_signerAddr]) {
            delete isSigner[_signerAddr];
        }
    }

    function addSigner(
        /*
          @dev: Add an authorized signer.
        */
        address _signerAddr
        ) external protected {
        require(isSigner[_signerAddr] != true, "Duplicate_Signer");
        isSigner[_signerAddr] = true;
    }

    function revokeTx(
        /*
          @dev: Remove pending transaction from storage and cancel it.
        */
        uint256 txid
        ) external protected {
        require(pendingTxs[txid].dest != address(0), errNotFound);
        delete pendingTxs[txid];
    }

    function getTx(
        /*
        @dev: View function to get details about a pending TX. 
        After executing, data is cleared from storage, which is 
        why an event is emited for record keeping.
        */
        uint256 txid
    ) external view returns(Transaction memory) {
        return pendingTxs[txid];

    }

    function approveTx(
        /*
          @dev: Function to approve a pending tx. If the signature threshold 
          is met, the transaction will be executed in this same call. Reverts 
          if the caller is the same signer that initialized or already approved 
          the transaction.
        */
        uint256 txid
        ) external protected {
        Transaction memory _tx = pendingTxs[txid];
        if(! alreadySigned(txid, msg.sender)){
            require(_tx.dest != address(0), errNotFound);
            if(_tx.numSigners + 1 >= threshold){
                delete pendingTxs[txid];
                execNonce += 1;
                execute(_tx.dest, _tx.value, _tx.data);
                emit ExecAction("ExecuteTx", msgSender(), txid);
            } else {
                _tx.numSigners += 1;
                emit ExecAction("ApproveTx", msgSender(), txid);
            }
        } else {
            revert("Already_Signed");
        }
    }

    function signTx(uint txid, address signer) private {
        /*
          @dev: register a transaction confirmation.
        */
        confirmations[txid][signer] = 1;
        pendingTxs[txid].numSigners += 1;
    }

    function msgSender() private view returns(address){
        /*
          @dev: Returns sender of the current call.
        */
        return msg.sender;
    }

    function submitTx(
        /*
          @dev: Initiate a new transaction. Logic flow:
          (Note: to save gas, the nonce also doubles as the TXID.)
           1) First, check the "nonce"
           2) Next, check that we have balance to cover this transaction.
           3) Check if requested ethere value (in wei) is below our daily 
           allowance: 
             yes) The transaction will be executed here and value added to `spentToday`.
             no)  The transaction requires the approval of `threshold` signatories,
                  so it will be queued pending approval.
        */
        address recipient,
        uint256 value,
        bytes memory data,
        uint256 nonceTxid
        ) external payable protected {
        /*Nonce also is transaction Id*/
        if(nonceTxid <= execNonce||pendingTxs[nonceTxid].dest != address(0)){
            revert("Bad_Nonce");
        }
        // gas effecient balance call
        uint256 self;
        assembly {
            self :=selfbalance()
        }

        if(self < value){
            revert("Insufficient_Balance");
        }
        address s = msgSender();
        if (underLimit(value)) {
            // limit not reached
            execute(recipient, value, data);
            execNonce += 1;
            spentToday += value;
        } else {
            // requires approval from signatories -- not factored into daily allowance
            Transaction memory txObject = Transaction(recipient, value, data, 0);
            pendingTxs[nonceTxid] = (txObject);
            signTx(nonceTxid, s);
            emit ExecAction("SubmitTx", s, nonceTxid);

        }
    }

    function underLimit(uint _value) private returns (bool) {
        /*
          @dev: Function to determine whether or not a requested 
          transaction's value is over the daily allowance and 
          shall require additional confirmation or not. If it is 
          a different day from the last time this ran, reset the 
          allowance.
        */
        uint32 t = today();
        if (t > lastDay) {
            spentToday = 0;
            lastDay = t;
        }
        // check to see if there's enough left 
        if (spentToday + _value <= dailyLimit) {
            return true;
        }
            return false;
    }

    
    function today() private view returns (uint32) {
        /*
          @dev: Determines today's index.
        */
        return uint32(block.timestamp / 1 days);
    }

     /*
       @dev: Allow arbitrary deposits to contract.
     */ 

     receive() external payable {}

}