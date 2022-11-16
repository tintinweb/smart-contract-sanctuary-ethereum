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

import './SummonUtils.sol';

contract Summon is SummonUtils {
    address public immutable owner;
    mapping(bytes => address) public storedTokens; // lender => (contract,tokenID) 

    constructor(address _owner) {
        owner = _owner;
    }

    
    function depositToken(
        address tokenAddress,
        uint256 tokenId
    ) public returns(bool success, bytes memory data) {
        bytes memory uniqToken = abi.encodePacked(tokenAddress, tokenId);
        storedTokens[uniqToken] = msg.sender;

        (success, data) = tokenAddress.call(abi.encodeWithSignature("transferFrom(address,address,uint256)",msg.sender,address(this),tokenId));
        require(success, "call failed");
    }
    

    function withdrawToken(
        address tokenAddress,
        uint256 tokenId
    ) public returns(bool success, bytes memory data) {
        bytes memory uniqToken = abi.encodePacked(tokenAddress, tokenId);
        require(storedTokens[uniqToken] == msg.sender, "withdrawer does not own token");

        (success, data) = tokenAddress.call(abi.encodeWithSignature("safeTransferFrom(address,address,uint256)",address(this),msg.sender,tokenId));
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Summon.sol";

contract SummonFactory {
  event SummonCreated(address summonAddress);
  Summon[] public SummonArray;

  function CreateNewSummon(address _owner) public {
    Summon summon = new Summon(_owner);
    SummonArray.push(summon);
    emit SummonCreated(address(summon));
  }

  //  function gfSetter(uint256 _greeterIndex, string memory _greeting) public {
  //    Greeter(address(GreeterArray[_greeterIndex])).setGreeting(_greeting);
  //  }

  //  function gfGetter(uint256 _greeterIndex) public view returns (string memory) {
  //   return Greeter(address(GreeterArray[_greeterIndex])).greet();
  //  }
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