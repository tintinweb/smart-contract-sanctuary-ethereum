//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./library/TokenInfoLib.sol";
import "./library/TokenExchangeLib.sol";
import "./Executor.sol";
import "./Validator.sol";
import { 
  ItemType, 
  OrderType 
} from "./library/Enumerators.sol";


/**
 * @title Flipeet
 * @author Ebube UD
 * @author Precious Kosisochukwu
 */

contract Flipeet is Ownable, Executor, Validator {
    using SafeMath for uint;
   
    address public defaultFeeReciever;

    /**
    * @dev - The connectors mapping holds a binding of the nft token address to its connector.
     */
    mapping(address => bool) connectors;

    /**
    * @dev - Protocol fee mapping
    */
    mapping(uint256 => uint256) public ProtocolFees;

    /**
    * @dev - Connector mapping holding the standard proxy for different standard
    *
    * 1 - ERC20
    * 2 - ERC721
    * 3 - ERC1155
    * 4 - CRYPTOPUNKS
    */
    mapping(uint256 => address) public standardToConnector;


     /**
     * @dev Emitted when `connector` has been updated for a `standard`
     */
    event TokenStandardUpdate(
      uint256 standard,
      address connector
     );

    /**
    * @dev -  Emitted when tokens has been exchanged between peers `peerA and peerB` by an `executor`
    *         executor is in this context the sender of the transaction.
    */
    event TokenExchange(
      TokenExchangeLib.
      TokenTransferObject peerA, 
      TokenExchangeLib.
      TokenTransferObject peerB,
      address executor
    );

    /**
    * @dev - Emitted when the exchange transaction has been executated between `peerA and peerB` by the `signer'
    */
    event TransactionExecuted(
      address signer, 
      address peerA, 
      address peerB
    );

    /**
    * @dev - Emitted when the `protocol fee` has been updated
    */
    event ProtocolFeeChanged(
      uint oldValue,
      uint newValue
    );

    /**
    * @dev - Emitted when the `protocol fee reciever` has been updated
    */
    event DefaultFeeRecieverChanged(
      address oldFeeReciever, 
      address newFeeReciever
    );

    /**
    * @dev - Emitted when native transfer occurs
    *        This context, when a withdrawal is made from the protocol
    */
    event Transfer(address _to, 
      uint _amount, 
      uint _balance
    );
    

    /**
     * @dev External function to add standard conector proxy. 
     *
     * @param _standard    The token standard to add connector proxy
     * @param _connector   The address of the proxy connector
     *
     * Emits {TokenStandardUpdate} event
     */
    function addStandardConnector(uint256 _standard, address _connector) 
    external onlyOwner {
       connectors[_connector] = true;
       standardToConnector[_standard] = _connector;
       emit TokenStandardUpdate(_standard, _connector);
    }


     /**
     * @dev -  External function to remove standard connector proxy.
     *          This function is only privillage to the admin or 
     *          owner of the contract.
     *
     * @param _standard  -  The token standard to add connector proxy
     *
     * Emits {TokenStandardUpdate} event
     */
    function removeStandardConnector(uint256 _standard)
    external onlyOwner {
        address connector = standardToConnector[_standard];
        connectors[connector] = false;
        standardToConnector[_standard] = address(0);
        emit TokenStandardUpdate(_standard, address(0));
    }

    /**
    * @dev - Public function for checking connector proxy address.
    *
    * @param _connector - address of the connector proxy
    */
    function isConnector(address _connector)
    public view returns (bool){
        return connectors[_connector];
    }
  
    /**
    * @dev - External function for setting protocol fee
    *        This fee varies across different order Type.
    *        This function is only privillage to the 
    *        admin or owner of the contract.
    *
    * @param _orderType   - defines the order for the protocol fee,
    *                       order can be reference from the 
    *                       enumerator.
    * @param _protocolFee - refers to the protocol fee percentage for
    *                       the order type
    *
    * Emits { ProtocolFeeChanged } event
    */
    function setProtocolFee(uint256 _orderType, uint256 _protocolFee)
     external onlyOwner {
      uint oldProtocolFee = ProtocolFees[_orderType];
      ProtocolFees[_orderType] = _protocolFee;
      emit ProtocolFeeChanged(oldProtocolFee, _protocolFee);
    }


    /**
    * @dev - External function for setting `fee reciever`, this
    *        function is only privillage to the admin or owner 
    *        of the contract.
    *
    * #mits { DefaultFeeRecieverChanged } event
    */
    function setDefaultFeeReciever(address payable _newDefaultReciever)
    external onlyOwner {
      emit DefaultFeeRecieverChanged(defaultFeeReciever, _newDefaultReciever);
      defaultFeeReciever = _newDefaultReciever;
    }
    
    /**
    * @dev -  External function that performs the exchange of asset
    *         between to peers ie: the buyer and the seller
    *
    * @notice - this function should only be called by either the 
    *           parties.

    * @param peerA - object containing the seller and the assets
    *                to be exchanged
    * @param peerB - object containing the buyer and the assets
    *                to be exchanged
    *
    * Emits {TokenExchanged and TransactionExecuted } events
    */
    function executeTransfer(
      TokenExchangeLib.TokenTransferObject calldata peerA, 
      TokenExchangeLib.TokenTransferObject calldata peerB
      ) nonReentrant external payable {
        //Verify the Seller's Signature
        require(verifySignature(peerA), "Recovered address of Seller is different from Signer");

        // Verify the Buyer's Signature
        require(verifySignature(peerB), "Recovered address of Buyer is different from Signer");

        //validate that they match on both transfer objects
        validateOrder(peerA, peerB);

        // Transfer seller's assets to the buyer
        doTransfer(peerA);

        // Transfer buyer's assets to the seller
        doTransfer(peerB);       
       
        //Emit an event
        emit TokenExchange(peerA, peerB, msg.sender);
        emit TransactionExecuted(msg.sender, peerA.from, peerB.from);
    }

    /**
    * @dev - Perform asset check and select transfer for asset type
    *
    *
    */
    function doTransfer(
    TokenExchangeLib.TokenTransferObject calldata peer
    ) private {

        //check the standards and select the connectors for each of them.
        for(uint i = 0; i<peer.releasingTokens.length; i++) {
          
          TokenInfoLib.TokenInfo memory tokenInfo = peer.releasingTokens[i];
          if(tokenInfo.tStandard == uint(ItemType.NATIVE)){
            // transfer native token
            _transferEth(payable(peer.to), tokenInfo.quantity);
          }
          else {
            // Derive the connector proxy for the standard
            address connector = standardToConnector[tokenInfo.tStandard];

            // Transfer asset with the connector proxy
            _transferWithConnector(connector, tokenInfo.tAddress, peer.from, peer.to, tokenInfo.tId, tokenInfo.quantity);
          }
        }
    }


    function getBalance() external onlyOwner view returns(uint256){
      return address(this).balance;
    }

    function withdraw() external onlyOwner {
      uint amount = address(this).balance;
      _transferEth(payable(defaultFeeReciever), amount);
      emit Transfer(defaultFeeReciever, amount, address(this).balance);
    }

    /// @notice Returns the chain id of the current blockchain.
    /// @dev This is used to workaround an issue with ganache returning different values from the on-chain chainid() function and
    ///  the eth_chainId RPC method. See https://github.com/protocol/nft-website/issues/121 for context.
    function getChainID() external view returns (uint256) {
      uint256 id;
      assembly {
          id := chainid()
      }
      return id;
    }

  }

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library TokenInfoLib {
    bytes32 public constant TYPE_HASH = keccak256("TokenInfo(uint256 tId,address tAddress,uint256 tStandard,uint256 quantity)");

   struct TokenInfo { 
        uint256 tId;
        address tAddress;
        uint256 tStandard;
        uint256 quantity;
    }

    function hash(TokenInfo memory info) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                TYPE_HASH, 
                info.tId, 
                info.tAddress, 
                info.tStandard, 
                info.quantity
            )
        );
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./TokenInfoLib.sol";

library TokenExchangeLib {
    bytes32 public constant TYPE_HASH = keccak256("TokenTransferObject(address from,address to,TokenInfo[] releasingTokens,TokenInfo[] receivingTokens)TokenInfo(uint256 tId,address tAddress,uint256 tStandard,uint256 quantity)");


    struct TokenTransferObject{
        address from;
        address to;
        TokenInfoLib.TokenInfo[] releasingTokens;
        TokenInfoLib.TokenInfo[] receivingTokens;
        bytes signature;
    }


    function hash(TokenTransferObject memory data) internal pure returns (bytes32) {
        bytes32[] memory releasingTokensBytes = new bytes32[](data.releasingTokens.length);
        for (uint i = 0; i < data.releasingTokens.length; i++) {
            releasingTokensBytes[i] = TokenInfoLib.hash(data.releasingTokens[i]);
        }

        bytes32[] memory receivingTokensBytes = new bytes32[](data.receivingTokens.length);
        for (uint i = 0; i < data.receivingTokens.length; i++) {
            receivingTokensBytes[i] = TokenInfoLib.hash(data.receivingTokens[i]);
        }

        return keccak256(
            abi.encode(
                TYPE_HASH,
                data.from,
                data.to,
                keccak256(abi.encodePacked(releasingTokensBytes)),
                keccak256(abi.encodePacked(receivingTokensBytes))
            )
        );    
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

/**
 * @title Executor
 * @author Ebube UD
 * @author Precious Kosisochukwu
 */

 contract Executor is ReentrancyGuard{



    function _transferEth(address payable _recipient, uint _amount) internal {
      (bool success, ) = _recipient.call{ value : _amount }("");
      require(success, "Transfer failed.");
    }

    /**
     * @dev Transfers `quantity` of tokens of  id `tokenId` from `from` to `to`.
     *
     * Emits a {TransferComplete} event.
     */
    function _transferWithConnector(
      address _connector,
      address _token, 
      address _from, 
      address _to, 
      uint256 _tokenId, 
      uint256 _quantity
    )
    internal returns (bytes memory response){
           bytes memory data = abi.encodeWithSignature(
              "transfer(address,address,address,uint256,uint256)",
              address(_token),
              address(_from),
              address(_to),
              uint256(_tokenId),
              uint256(_quantity)
            ); 

            /*
            *   Assembly code to delegate call to standard proxies
            */
            assembly {
              let succeeded := delegatecall(
                gas(), 
                _connector, 
                add(data, 0x20),
                mload(data)
                , 0
                , 0
              )

              let size := returndatasize()
              response := mload(0x40)
              mstore(0x40, 
                add(response, 
                  and(
                    add(
                      add(size, 0x20),
                       0x1f
                      ),
                    not(0x1f)
                  )
                )
              )
              mstore(response, size)
              returndatacopy(
                add(response, 0x20), 
                0, 
                size
              )
              
              switch iszero(succeeded)
                  case 1 {
                      // throw if delegatecall failed
                      returndatacopy(0x00, 0x00, size)
                      revert(0x00, size)
                  }
            }
    }
 }

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "./library/TokenExchangeLib.sol";


/**
 * @title Validator
 * @author Ebube UD
 * @author Precious Kosisochukwu
 */


contract Validator is EIP712{

    string private constant SIGNING_DOMAIN = "Flipeet-Transaction";
    string private constant SIGNATURE_VERSION = "1";


    constructor() EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {}


    function _verify(TokenExchangeLib.TokenTransferObject calldata data) internal view returns (address) {
      bytes32 digest = _hashTypedDataV4(TokenExchangeLib.hash(data));
      return ECDSA.recover(digest, data.signature);
    }    

    function verifySignature(
    TokenExchangeLib.TokenTransferObject calldata peer
    )
    internal view returns(bool isValid){
       //Verify the Sellers Signature
        address recoveredAddress = _verify(peer);
        isValid = recoveredAddress == peer.from;
    }

    function validateOrder(
        TokenExchangeLib.TokenTransferObject calldata peerA, 
        TokenExchangeLib.TokenTransferObject calldata peerB
    ) internal pure  returns (bool){
    
        // Validate peer address pairs
        require(
            (peerA.from == peerB.to)
            && 
            (peerA.to == peerB.from),
            "Invalid address pairing"
        );

        require(
            (peerA.receivingTokens.length == peerB.releasingTokens.length) 
            && 
            (peerA.releasingTokens.length == peerB.receivingTokens.length),
            "Asset validation failed"
        );

        for(uint i = 0; i < peerA.receivingTokens.length; i++){
            require(
                peerA.receivingTokens[i].tId == peerB.releasingTokens[i].tId,
                "Asset validation failed"
            );

            require(
                peerA.receivingTokens[i].tStandard == peerB.releasingTokens[i].tStandard,
                "Asset validation failed"
            );

            require(
                peerA.receivingTokens[i].tAddress == peerB.releasingTokens[i].tAddress,
                "Asset validation failed"
            );

            require(
                peerA.receivingTokens[i].quantity == peerB.releasingTokens[i].quantity,
                "Asset validation failed"
            );

             require(
                peerB.receivingTokens[i].tId == peerA.releasingTokens[i].tId,
                "Asset validation failed"
            );

            require(
                peerB.receivingTokens[i].tStandard == peerA.releasingTokens[i].tStandard,
                "Asset validation failed"
            );

            require(
                peerB.receivingTokens[i].tAddress == peerA.releasingTokens[i].tAddress,
                "Asset validation failed"
            );

            require(
                peerB.receivingTokens[i].quantity == peerA.releasingTokens[i].quantity,
                "Asset validation failed"
            );
        }    

        return true;
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

 enum ItemType {
       // 0: no partial fills, anyone can execute
      NATIVE, 

      // 1: ERC20 items (ERC777 and ERC20 analogues could also technically work)
      ERC20, 

      // 2: ERC721 items
      ERC721, 

      // 3: ERC1155 items
      ERC1155, 

      // 4: CRYPTOPUNKS items
      CRYPTOPUNKS
}

enum OrderType {
      
      // 0: Trading `NFT` with `NFT`
      NFT_TO_NFT,

      // 1: Trading `NFT` with `FT`
      NFT_TO_FT,

      // 2: Trading witH only `FT`
      FT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}