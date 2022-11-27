// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "../interfaces/ERC1155TokenReceiver.sol";
import "../interfaces/ERC721TokenReceiver.sol";
import "../interfaces/ERC777TokensRecipient.sol";
import "../interfaces/IERC165.sol";

/// @title Default Callback Handler - returns true for known token callbacks
/// @author Richard Meissner - <[email protected]>
contract DefaultCallbackHandler is ERC1155TokenReceiver, ERC777TokensRecipient, ERC721TokenReceiver, IERC165 {
    string public constant NAME = "Default Callback Handler";
    string public constant VERSION = "1.0.0";

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0xbc197c81;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0x150b7a02;
    }

    function tokensReceived(
        address,
        address,
        address,
        uint256,
        bytes calldata,
        bytes calldata
    ) external pure override {
        // We implement this for completeness, doesn't really have any value
    }

    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return
            interfaceId == type(ERC1155TokenReceiver).interfaceId ||
            interfaceId == type(ERC721TokenReceiver).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/
interface ERC1155TokenReceiver {
    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.        
        This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _id        The ID of the token being transferred
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.        
        This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _ids       An array containing ids of each token being transferred (order and length must match _values array)
        @param _values    An array containing amounts of each token being transferred (order and length must match _ids array)
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface ERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

interface ERC777TokensRecipient {
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @notice More details at https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './GnosisSafe/handler/DefaultCallbackHandler.sol';


contract SummonUtils is DefaultCallbackHandler {

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
           r := mload(add(sig, 32))
           s := mload(add(sig, 64))
           v := byte(0, mload(add(sig, 96)))
       }
   }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
       public
       pure
       returns (address)
   {
       (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

       return ecrecover(_ethSignedMessageHash, v, r, s);
   }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './SummonUtils.sol';

contract Summon is SummonUtils {
  address public owner;
  address public SummonManager;
  // mapping(bytes => address) public storedTokens; // lender => (contract,tokenID) 

  // constructor(address _owner ) {
  //     owner = _owner;
  //     SummonFactory = msg.sender;
  // }



function init(address _owner) external {
    require(owner == address(0) && SummonManager == address(0));
    owner = _owner;
    SummonManager = msg.sender;
}




  function safeWithdraw(address tokenAddress, uint256 tokenId, address lender) public returns(bool success, bytes memory data) {
    require(msg.sender == SummonManager, "can only be called by Summon Manager");
    (success, data) = tokenAddress.call(abi.encodeWithSignature("safeTransferFrom(address,address,uint256)",address(this),lender,tokenId));
    require(success, "call failed");
  }


  function isValidSignature(
    bytes32 _hash,
    bytes calldata _signature
  ) external view returns (bytes4) {
   // Validate signatures
   if ((recoverSigner(_hash, _signature)) == owner) {
     return 0x1626ba7e;
   } else {
     return 0xffffffff;
   }
  }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./SummonV2.sol";

contract SummonV2Manager {
  event SummonCreated(address indexed owner, address indexed summonAddress);
  event TokenLendedFrom(address indexed lender, address indexed summon, address tokenAddress, uint tokenId);
  event TokenWithdrawnTo(address indexed lender, address indexed summon, address tokenAddress, uint tokenId);
  // event TokenDeposit(address _summon, address tokenAddress, )
  mapping(address => address) public OwnerToSummonAddress;
  mapping(address => address) public SummonAddressToOwner;
  mapping(bytes => address) public EncodedTokenToSummon; // map from token => summon
  mapping(bytes => address) public EncodedTokenToLender; // map from token => lender
  address public immutable singleton;

  constructor(address _singleton) {
    singleton = _singleton;
  }

  function CreateNewSummon(address _owner) public returns(address) {
    require(OwnerToSummonAddress[_owner] == address(0), "address already has a Summon");

    address summon = Clones.clone(singleton);
    Summon(summon).init(_owner);



    OwnerToSummonAddress[_owner] = address(summon);
    SummonAddressToOwner[address(summon)] = _owner;
    emit SummonCreated(_owner, address(summon));

    return summon;
  }

  function getEncodedToken(address tokenAddress, uint tokenId) public pure returns(bytes memory encodedToken) {
    return abi.encode(tokenAddress, tokenId);
  }


  function getDecodedToken(bytes calldata _encodedToken) public pure returns(address tokenAddress, uint tokenId) {
    (tokenAddress, tokenId) = abi.decode(_encodedToken, (address, uint));
    return (tokenAddress, tokenId);
  }




  // to be called by lender <-- hahah not anymore
   function lendTokenToBorrower(address borrower, address tokenAddress, uint256 tokenId) public returns(bool success, bytes memory data) {
    OwnerToSummonAddress[borrower] == address(0) && OwnerToSummonAddress[borrower] == this.CreateNewSummon(borrower);

    address borrowerSummon = OwnerToSummonAddress[borrower];
    require(borrowerSummon != address(0), "something went wrong"); // remove this line in the future maybe
    
    bytes memory encodedToken = abi.encode(tokenAddress, tokenId);
    
    // do state changes that say this summon has this token
    EncodedTokenToSummon[encodedToken] = borrowerSummon;
    EncodedTokenToLender[encodedToken] = msg.sender;

    // move token to that summon
    (success, data) = tokenAddress.call(abi.encodeWithSignature("safeTransferFrom(address,address,uint256)",address(msg.sender),borrowerSummon,tokenId));
    emit TokenLendedFrom(address(msg.sender), borrowerSummon, tokenAddress, tokenId);
    require(success, "call failed");
   }

  // to be called by lender <--- haha not anymore
   function withdrawTokenFromSummon(address tokenAddress, uint tokenId) public returns(bool success, bytes memory data) {
    bytes memory _encodedToken = abi.encode(tokenAddress, tokenId);
    address summonAddress = EncodedTokenToSummon[_encodedToken];
    require(EncodedTokenToLender[_encodedToken] == msg.sender || SummonAddressToOwner[summonAddress] == msg.sender, "caller must be lender or summon owner");

    EncodedTokenToSummon[_encodedToken] = address(0);
    EncodedTokenToLender[_encodedToken] = address(0);

    (success, data) = Summon(summonAddress).safeWithdraw(tokenAddress, tokenId, msg.sender);
    
    emit TokenWithdrawnTo(address(msg.sender), summonAddress, tokenAddress, tokenId);
    require(success, "calls call failed");
   }



}

// previously the summon contract itself managed everything, but howwould things changed if the summon factory manged everything?
// the summon factory itself would have to have transfer power. ok thats fine. 
// the summon factory would have to deposit every token to the specific summon address, and store state about where every token is stored.
// on withdraw, the summon factory would have permissions to call a new function: safeWithdraw on the summon in question. safeWithdraw could ONLY be called by the Summon
// Factory, and would transfer the token from the summon address to the lender address


// oooh this would also allow lending tokens to a