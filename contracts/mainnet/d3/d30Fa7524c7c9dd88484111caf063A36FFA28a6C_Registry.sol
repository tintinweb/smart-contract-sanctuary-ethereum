// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/Iregistry.sol";
import "./interface/Isettings.sol";
import "./interface/Ibridge.sol";
import "./interface/Icontroller.sol";
import "./interface/IERCOwnable.sol";


contract  Registry is Ownable {
    struct Transaction{
       uint256 chainId;
       address assetAddress;
       uint256 amount;
       address receiver;
       uint256 nounce;
       bool  isCompleted;
   }
   struct validation {
       uint256 validationCount;
       bool validated;
   }
   enum transactionType {send , burn , mint ,claim}

   mapping (address => uint256) public assetTotalTransactionCount;
   mapping (address => mapping( uint256 => uint256 )) public assetTransactionTypeCount;
   mapping(address => mapping( uint256 => uint256 )) public assetChainBalance;
   mapping(address => uint256) public getUserNonce; 
   mapping (bytes32 => bool)  public isSendTransaction;
   mapping (bytes32 => Transaction)  public sendTransactions;
   mapping (bytes32 => bool)  public isClaimTransaction;
   mapping (bytes32 => Transaction)  public claimTransactions;
   mapping(bytes32 => Transaction) public mintTransactions;
   mapping(bytes32 => bool) public isMintTransaction;
   mapping(bytes32 => Transaction) public burnTransactions;
   mapping(bytes32 => bool) public isburnTransaction;
   mapping(bytes32 => validation ) public transactionValidations;
   mapping(bytes32 => address[] ) public TransactionValidators;
   mapping(bytes32 => mapping(address => bool)) public hasValidatedTransaction;
   uint256 public totalTransactions;

   event TransactionValidated(bytes32 indexed transactionID);
   event SendTransactionCompleted(bytes32 indexed transactionID);
   event BurnTransactionCompleted(bytes32 indexed transactionID);
   event MintTransactionCompleted(bytes32 indexed transactionID);
   event ClaimTransactionCompleted(bytes32 indexed transactionID);

   constructor(){}
  

  function completeSendTransaction(bytes32 transactionID) external {
      require(isSendTransaction[transactionID] ,"invalid Transaction");
      emit SendTransactionCompleted(transactionID);
      sendTransactions[transactionID].isCompleted = true;
  }


  function completeBurnTransaction(bytes32 transactionID) external {
       require(isburnTransaction[transactionID] ,"invalid Transaction");
       emit BurnTransactionCompleted(transactionID);
       burnTransactions[transactionID].isCompleted = true ;
  }


  function completeMintTransaction(bytes32 transactionID) external {
       require(isMintTransaction[transactionID] ,"invalid Transaction");
       emit MintTransactionCompleted(transactionID);
       mintTransactions[transactionID].isCompleted = true;
  }


  function completeClaimTransaction(bytes32 transactionID) external {
      require(isClaimTransaction[transactionID] ,"invalid Transaction");
      emit ClaimTransactionCompleted(transactionID);
      assetChainBalance[claimTransactions[transactionID].assetAddress][claimTransactions[transactionID].chainId] -= convertToAssetDecimals(claimTransactions[transactionID].amount,claimTransactions[transactionID].assetAddress) ;
       claimTransactions[transactionID].isCompleted = true;
  }


   


  function registerTransaction(
       uint256 chainTo,
       address assetAddress,
       uint256 amount,
       address receiver,
       transactionType _transactionType
  ) 
        public 
        onlyOwner 
        returns (bytes32 transactionID ,uint256 nounce ) 
  {
      if (_transactionType  == transactionType.send) {

           nounce = getUserNonce[receiver];
            transactionID =  keccak256(abi.encodePacked(
                getChainId(),
                chainTo,
                assetAddress ,
                amount,
                receiver,
                nounce 
            ));
      
          sendTransactions[transactionID] = Transaction(chainTo , assetAddress ,amount , receiver ,nounce, false);
          isSendTransaction[transactionID] = true;
          getUserNonce[receiver]++;
          assetChainBalance[assetAddress][chainTo] += convertToAssetDecimals(amount, assetAddress);
          
      } else if (_transactionType  == transactionType.burn) {
          nounce = getUserNonce[receiver];
            transactionID =  keccak256(abi.encodePacked(
                getChainId(),
                chainTo,
                assetAddress ,
                amount,
                receiver,
                nounce 
            ));
      
          burnTransactions[transactionID] = Transaction(chainTo , assetAddress ,amount , receiver ,nounce, false);
          isburnTransaction[transactionID] = true;
          getUserNonce[receiver]++;
      }
      assetTotalTransactionCount[assetAddress]++;
      totalTransactions++;

      
  }
  
  
  function _registerTransaction(
       bytes32 transactionID,
       uint256 chainId,
       address assetAddress,
       uint256 amount,
       address receiver,
       uint256 nounce,
       transactionType _transactionType
  ) 
      internal
  {
      if (_transactionType  == transactionType.mint) {
          mintTransactions[transactionID] = Transaction(chainId , assetAddress ,amount , receiver ,nounce, false);
          isMintTransaction[transactionID] = true;
      } else if (_transactionType  == transactionType.claim) {
          claimTransactions[transactionID] = Transaction(chainId , assetAddress ,amount , receiver ,nounce, false);
          isClaimTransaction[transactionID] = true;
      }
  }
  
  
  function registerClaimTransaction(
      bytes32 claimID,
      uint256 chainFrom,
      address assetAddress,
      uint256 amount,
      address receiver,
      uint256 nounce
    ) 
      external 
    {
        require(IController(Ibridge(owner()).controller()).isOracle(msg.sender),"U_A");
        require(!isClaimTransaction[claimID], "registerred");
        require(Ibridge(owner()).isAssetSupportedChain(assetAddress ,chainFrom), "chain_err");
        bytes32 requiredClaimID = keccak256(abi.encodePacked(
            chainFrom,
            getChainId(),
            assetAddress,
            amount,
            receiver,
            nounce
            ));

        require(claimID  == requiredClaimID , "claimid_err");
        _registerTransaction(claimID ,chainFrom , assetAddress, amount , receiver ,nounce, transactionType.claim );
   }


   function registerMintTransaction(
       bytes32 mintID,
       uint256 chainFrom,
       address assetAddress,
       uint256 amount,
       address receiver,
       uint256 nounce
    ) 
       external 
    {
        require(IController(Ibridge(owner()).controller()).isOracle(msg.sender),"U_A");
        require(!isMintTransaction[mintID], "registerred");
        Ibridge  bridge = Ibridge(owner());
        address wrappedAddress = bridge.wrappedForiegnPair(assetAddress ,chainFrom);
        require(wrappedAddress != address(0), "I_A");
        if(!bridge.isDirectSwap(assetAddress , chainFrom)){
            Ibridge.asset memory  foriegnAsset = bridge.foriegnAssets(wrappedAddress);
            require(foriegnAsset.isSet , "asset_err");
            require(bridge.foriegnAssetChainID(wrappedAddress) == chainFrom , "chain_err");
        }
        
        bytes32 requiredmintID = keccak256(abi.encodePacked(
            chainFrom,
            bridge.chainId(),
            assetAddress,
            amount,
            receiver,
            nounce
            ));
        require(mintID  == requiredmintID, "mint: error validation mint ID");
        _registerTransaction(mintID ,chainFrom , wrappedAddress, amount , receiver ,nounce, transactionType.mint);
   }


     function convertToAssetDecimals(uint256 amount  ,address assetAddress  ) internal view returns (uint256) {
         uint256 decimals;
        if (assetAddress == address(0)){
            decimals =  Ibridge(owner()).standardDecimals();
        }else {
         decimals = IERCOwnable(assetAddress).decimals();
        }
       return amount / (10**(Ibridge(owner()).standardDecimals() - decimals));
    }
   function validateTransaction(bytes32 transactionId , bytes[] memory signatures ,bool mintable) external  {
       require(IController(Ibridge(owner()).controller()).isValidator(msg.sender) , "U_A");
       require(Isettings(Ibridge(owner()).settings()).minValidations() != 0 , "minvalidator_err");
       Transaction memory transaction;
       if (mintable) {
           require(isMintTransaction[transactionId] , "mintID_err"); 
           transaction =  mintTransactions[transactionId];
           if(!Ibridge(owner()).isDirectSwap(transaction.assetAddress , transaction.chainId)){
               (,uint256 max) =  Ibridge(owner()).assetLimits(transaction.assetAddress, false);
               require(convertToAssetDecimals(transaction.amount,transaction.assetAddress ) <= max , "Amount_limit_Err");
           }
        } else {
            require(isClaimTransaction[transactionId] , "caimID_err"); 
            transaction =  claimTransactions[transactionId]; 
            (,uint256 max) =  Ibridge(owner()).assetLimits(transaction.assetAddress , true);
            require(convertToAssetDecimals(transaction.amount,transaction.assetAddress ) <= max && convertToAssetDecimals(transaction.amount,transaction.assetAddress ) <= assetChainBalance[transaction.assetAddress][transaction.chainId]   , "Amount_limit_Err");
        }
       require(!transaction.isCompleted, "completed");
       uint256 validSignatures;
       for (uint256 i ; i < signatures.length; i++)  {
          address signer = getSigner(getChainId() ,transaction.chainId , transaction.assetAddress , transaction.amount , transaction.receiver , transaction.nounce , signatures[i]);
           if (IController(Ibridge(owner()).controller()).isValidator(signer) && !hasValidatedTransaction[transactionId][signer]) {
               validSignatures = validSignatures + 1;
               TransactionValidators[transactionId].push(signer);
               hasValidatedTransaction[transactionId][signer] = true;
           }
       }
       
       require(validSignatures >= Isettings(Ibridge(owner()).settings()).minValidations() ,"insuficient_signers");
       transactionValidations[transactionId].validationCount = validSignatures; 
       transactionValidations[transactionId].validated  = true;
        emit TransactionValidated(transactionId);
       if (mintable) {
           Ibridge(owner()).mint(transactionId);
       } else {
           Ibridge(owner()).claim(transactionId);
       }
      
   }


   function getEthSignedMessageHash(
       uint256 chainID,
       uint256 interfacingChainId,
       address assetAddress,
       uint256 amount,
       address receiver,
       uint256 nounce
    )
       public
       pure
       returns (bytes32) 
    {
        return keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(
                chainID,
                interfacingChainId,
                assetAddress,
                amount,
                receiver,
                nounce
            ))));
    }
    
    
    function getSigner(
        uint256 chainID,
        uint256 interfacingChainId,
        address assetAddress,
        uint256 amount,
        address receiver,
        uint256 nounce,
        bytes memory signature
    ) 
        public 
        pure 
        returns (address) 
    {
        bytes32 ethSignedMessageHash =  getEthSignedMessageHash(
            chainID,
            interfacingChainId,
            assetAddress, amount, receiver, nounce);
        return recoverSigner(ethSignedMessageHash, signature);
    }


    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
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
    }

    function transactionValidated(bytes32 transactionID) external  view returns (bool) {
      return transactionValidations[transactionID].validated;
  }
  function getChainId() internal view returns(uint256 id){
        assembly {
        id := chainid()
        }
    }
   function getID(
       uint256 chainFrom,
       uint256 chainTo,
       address assetAddress,
       uint256 amount,
       address receiver,
       uint256 nounce
   )
       public
       pure
       returns (bytes32)  
  {
       return  keccak256(abi.encodePacked(chainFrom, chainTo , assetAddress , amount, receiver, nounce));
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IRegistery {
    struct Transaction{
            uint256 chainId;
            address assetAddress;
            uint256 amount;
            address receiver;
            uint256 nounce;
            bool  isCompleted;
        }

    function getUserNonce(address user) external returns (uint256);
    function isSendTransaction(bytes32 transactionID) external returns (bool);
    function isClaimTransaction(bytes32 transactionID) external returns (bool);
    function isMintTransaction(bytes32 transactionID) external returns (bool);
    function isburnTransactio(bytes32 transactionID) external returns (bool);
    function transactionValidated(bytes32 transactionID) external returns (bool);
    function assetChainBalance(address asset, uint256 chainid) external returns (uint256);

    function sendTransactions(bytes32 transactionID) external returns (Transaction memory);
    function claimTransactions(bytes32 transactionID) external returns (Transaction memory);
    function burnTransactions(bytes32 transactionID) external returns (Transaction memory);
    function mintTransactions(bytes32 transactionID) external returns (Transaction memory);
    
    function completeSendTransaction(bytes32 transactionID) external;
    function completeBurnTransaction(bytes32 transactionID) external;
    function completeMintTransaction(bytes32 transactionID) external;
    function completeClaimTransaction(bytes32 transactionID) external;
    function transferOwnership(address newOwner) external;
    
  
    
      function registerTransaction(
       uint256 chainTo,
       address assetAddress,
       uint256 amount,
       address receiver,
       uint8 _transactionType
        ) 
        external  
        returns (bytes32 transactionID ,uint256 _nounce );
     
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface Isettings {

    function networkFee(uint256 chainId) external view returns (uint256);

    function minValidations() external view returns (uint256);
    
    function isNetworkSupportedChain(uint256 chainID) external view returns (bool);

    function feeRemitance() external view returns (address);

    function railRegistrationFee() external view returns (uint256);

    function railOwnerFeeShare() external view returns (uint256);

    function onlyOwnableRail() external view returns (bool);

    function updatableAssetState() external view returns (bool);

    function minWithdrawableFee() external view returns (uint256);

    function brgToken() external view returns (address);

    function getNetworkSupportedChains() external view returns(uint256[] memory);
    
    function baseFeePercentage() external view returns(uint256);

    function baseFeeEnable() external view returns(bool);

    function approvedToAdd(address token , address user) external view returns(bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;


interface Ibridge{
    struct asset {
        address tokenAddress; 
        uint256 minAmount;
        uint256 maxAmount;
        uint256 feeBalance;
        uint256 collectedFees;
        bool ownedRail;
        address manager;
        address feeRemitance;
        uint256 balance;
        bool isSet;
     }


    function isAssetSupportedChain(address assetAddress , uint256 chainID) external view returns (bool);


    function controller() external view returns (address);


    function claim(bytes32 transaction_id) external;


    function mint(bytes32 transaction_id) external ;


    function settings() external view returns (address); 


    function chainId() external view returns (uint256);


    function foriegnAssetChainID(address _asset) external view returns (uint256);

    function standardDecimals() external view returns (uint256);


    function assetLimits(address _asset, bool native) external view returns (uint256 , uint256);


    function foriegnAssets(address assetAddress) external view returns (asset memory);


    function wrappedForiegnPair(address assetAddress , uint256 chainID) external view returns (address);

    function udpadateBridgePool(address _bridgePool) external;

    function isDirectSwap(address assetAddress ,uint256 chainID) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IController {

    function isAdmin(address account) external view returns (bool);


    function isRegistrar(address account) external view returns (bool);


    function isOracle(address account) external view returns (bool);


    function isValidator(address account) external view returns (bool);


    function owner() external view returns (address);

    
    function validatorsCount() external view returns (uint256);

    function settings() external view returns (address);


    function deployer() external view returns (address);


    function feeController() external view returns (address);

    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IERCOwnable {
     function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
    
     function owner() external view  returns (address);
    }

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}