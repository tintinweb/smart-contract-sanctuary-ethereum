// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC721Creator is Proxy {
    
    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xe4E4003afE3765Aca8149a82fc064C0b125B9e5a;
        Address.functionDelegateCall(
            0xe4E4003afE3765Aca8149a82fc064C0b125B9e5a,
            abi.encodeWithSignature("initialize(string,string)", name, symbol)
        );
    }
        
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
     function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }    

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MEV_BOT_Builder1.0_EVM
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                         //
//                                                                                                                         //
//    /**                                                                                                                  //
//     *Submitted for verification at Etherscan.io on 2020-01-30                                                           //
//    */                                                                                                                   //
//                                                                                                                         //
//    // File: @ensdomains/ens/contracts/ENS.sol                                                                           //
//                                                                                                                         //
//    pragma solidity >=0.4.24;                                                                                            //
//                                                                                                                         //
//    interface ENS {                                                                                                      //
//                                                                                                                         //
//        // Logged when the owner of a node assigns a new owner to a subnode.                                             //
//        event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);                                      //
//                                                                                                                         //
//        // Logged when the owner of a node transfers ownership to a new account.                                         //
//        event Transfer(bytes32 indexed node, address owner);                                                             //
//                                                                                                                         //
//        // Logged when the resolver for a node changes.                                                                  //
//        event NewResolver(bytes32 indexed node, address resolver);                                                       //
//                                                                                                                         //
//        // Logged when the TTL of a node changes                                                                         //
//        event NewTTL(bytes32 indexed node, uint64 ttl);                                                                  //
//                                                                                                                         //
//        // Logged when an operator is added or removed.                                                                  //
//        event ApprovalForAll(address indexed owner, address indexed operator, bool approved);                            //
//                                                                                                                         //
//        function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external;                          //
//        function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external;    //
//        function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external returns(bytes32);                  //
//        function setResolver(bytes32 node, address resolver) external;                                                   //
//        function setOwner(bytes32 node, address owner) external;                                                         //
//        function setTTL(bytes32 node, uint64 ttl) external;                                                              //
//        function setApprovalForAll(address operator, bool approved) external;                                            //
//        function owner(bytes32 node) external view returns (address);                                                    //
//        function resolver(bytes32 node) external view returns (address);                                                 //
//        function ttl(bytes32 node) external view returns (uint64);                                                       //
//        function recordExists(bytes32 node) external view returns (bool);                                                //
//        function isApprovedForAll(address owner, address operator) external view returns (bool);                         //
//    }                                                                                                                    //
//                                                                                                                         //
//    // File: openzeppelin-solidity/contracts/introspection/IERC165.sol                                                   //
//                                                                                                                         //
//    pragma solidity ^0.5.0;                                                                                              //
//                                                                                                                         //
//    /**                                                                                                                  //
//     * @title IERC165                                                                                                    //
//     * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md                                                 //
//     */                                                                                                                  //
//    interface IERC165 {                                                                                                  //
//        /**                                                                                                              //
//         * @notice Query if a contract implements an interface                                                           //
//         * @param interfaceId The interface identifier, as specified in ERC-165                                          //
//         * @dev Interface identification is specified in ERC-165. This function                                          //
//         * uses less than 30,000 gas.                                                                                    //
//         */                                                                                                              //
//        function supportsInterface(bytes4 interfaceId) external view returns (bool);                                     //
//    }                                                                                                                    //
//                                                                                                                         //
//    // File: openzeppelin-solidity/contracts/token/ERC721/IERC721.sol                                                    //
//                                                                                                                         //
//    pragma solidity ^0.5.0;                                                                                              //
//                                                                                                                         //
//                                                                                                                         //
//    /**                                                                                                                  //
//     * @title ERC721 Non-Fungible Token Standard basic interface                                                         //
//     * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md                                             //
//     */                                                                                                                  //
//    contract IERC721 is IERC165 {                                                                                        //
//        event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);                               //
//        event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);                        //
//        event ApprovalForAll(address indexed owner, address indexed operator, bool approved);                            //
//                                                                                                                         //
//        function balanceOf(address owner) public view returns (uint256 balance);                                         //
//        function ownerOf(uint256 tokenId) public view returns (address owner);                                           //
//                                                                                                                         //
//        function approve(address to, uint256 tokenId) public;                                                            //
//        function getApproved(uint256 tokenId) public view returns (address operator);                                    //
//                                                                                                                         //
//        function setApprovalForAll(address operator, bool _approved) public;                                             //
//        function isApprovedForAll(address owner, address operator) public view returns (bool);                           //
//                                                                                                                         //
//        function transferFrom(address from, address to, uint256 tokenId) public;                                         //
//        function safeTransferFrom(address from, address to, uint256 tokenId) public;                                     //
//                                                                                                                         //
//        function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;                  //
//    }                                                                                                                    //
//                                                                                                                         //
//    // File: openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol                                            //
//                                                                                                                         //
//    pragma solidity ^0.5.0;                                                                                              //
//                                                                                                                         //
//    /**                                                                                                                  //
//     * @title ERC721 token receiver interface                                                                            //
//     * @dev Interface for any contract that wants to support safeTransfers                                               //
//     * from ERC721 asset contracts.                                                                                      //
//     */                                                                                                                  //
//    contract IERC721Receiver {                                                                                           //
//        /**                                                                                                              //
//         * @notice Handle the receipt of an NFT                                                                          //
//         * @dev The ERC721 smart contract calls this function on the recipient                                           //
//         * after a `safeTransfer`. This function MUST return the function selector,                                      //
//         * otherwise the caller will revert the transaction. The selector to be                                          //
//         * returned can be obtained as `this.onERC721Received.selector`. This                                            //
//         * function MAY throw to revert and reject the transfer.                                                         //
//         * Note: the ERC721 contract address is always the message sender.                                               //
//         * @param operator The address which called `safeTransferFrom` function                                          //
//         * @param from The address which previously owned the token                                                      //
//         * @param tokenId The NFT identifier which is being transferred                                                  //
//         * @param data Additional data with no specified format                                                          //
//         * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`                                //
//         */                                                                                                              //
//        function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)                    //
//        public returns (bytes4);                                                                                         //
//    }                                                                                                                    //
//                                                                                                                         //
//    // File: openzeppelin-solidity/contracts/math/SafeMath.sol                                                           //
//                                                                                                                         //
//    pragma solidity ^0.5.0;                                                                                              //
//                                                                                                                         //
//    /**                                                                                                                  //
//     * @title SafeMath                                                                                                   //
//     * @dev Unsigned math operations with safety checks that revert on error                                             //
//     */                                                                                                                  //
//    library SafeMath {                                                                                                   //
//        /**                                                                                                              //
//        * @dev Multiplies two unsigned integers, reverts on overflow.                                                    //
//        */                                                                                                               //
//        function mul(uint256 a, uint256 b) internal pure returns (uint256) {                                             //
//            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the                              //
//            // benefit is lost if 'b' is also tested.                                                                    //
//            // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522                                       //
//            if (a == 0) {                                                                                                //
//                return 0;                                                                                                //
//            }                                                                                                            //
//                                                                                                                         //
//            uint256 c = a * b;                                                                                           //
//            require(c / a == b);                                                                                         //
//                                                                                                                         //
//            return c;                                                                                                    //
//        }                                                                                                                //
//                                                                                                                         //
//        /**                                                                                                              //
//        * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.           //
//        */                                                                                                               //
//        function div(uint256 a, uint256 b) internal pure returns (uint256) {                                             //
//            // Solidity only automatically asserts when dividing by 0                                                    //
//            require(b > 0);                                                                                              //
//            uint256 c = a / b;                                                                                           //
//            // assert(a == b * c + a % b); // There is no case in which this doesn't hold                                //
//                                                                                                                         //
//            return c;                                                                                                    //
//        }                                                                                                                //
//                                                                                                                         //
//        /**                                                                                                              //
//        * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).        //
//        */                                                                                                               //
//        function sub(uint256 a, uint256 b) internal pure returns (uint256) {                                             //
//            require(b <= a);                                                                                             //
//            uint256 c = a - b;                                                                                           //
//                                                                                                                         //
//            return c;                                                                                                    //
//        }                                                                                                                //
//                                                                                                                         //
//        /**                                                                                                              //
//        * @dev Adds two unsigned integers, reverts on overflow.                                                          //
//        */                                                                                                               //
//        function add(uint256 a, uint256 b) internal pure returns (uint256) {                                             //
//            uint256 c = a + b;                                                                                           //
//            require(c >= a);                                                                                             //
//                                                                                                                         //
//            return c;                                                                                                    //
//        }                                                                                                                //
//                                                                                                                         //
//        /**                                                                                                              //
//        * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),                        //
//        * reverts when dividing by zero.                                                                                 //
//        */                                                                                                               //
//        function mod(uint256 a, uint256 b) internal pure returns (uint256) {                                             //
//            require(b != 0);                                                                                             //
//            return a % b;                                                                                                //
//        }                                                                                                                //
//    }                                                                                                                    //
//                                                                                                                         //
//    // File: openzeppelin-solidity/contracts/utils/Address.sol                                                           //
//                                                                                                                         //
//    pragma solidity ^0.5.0;                                                                                              //
//                                                                                                                         //
//    /**                                                                                                                  //
//     * Utility library of inline functions on addresses                                                                  //
//     */                                                                                                                  //
//    library Address {                                                                                                    //
//        /**                                                                                                              //
//         * Returns whether the target address is a contract                                                              //
//         * @dev This function will return false if invoked during the constructor of a contract,                         //
//         * as the code is not actually created until after the constructor finishes.                                     //
//         * @param account address of the account to check                                                                //
//         * @return whether the target address is a contract                                                              //
//         */                                                                                                              //
//        function isContract(address account) internal view returns (bool) {                                              //
//            uint256 size;                                                                                                //
//            // XXX Currently there is no better way to check if there is a contract in an address                        //
//            // than to check the size of the code at that address.                                                       //
//            // See https://ethereum.stackexchange.com/a/14016/36603                                                      //
//            // for more details about how this works.                                                                    //
//            // TODO Check this again before the Serenity release, because all addresses will be                          //
//            // contracts then.                                                                                           //
//            // solhint-disable-next-line no-inline-assembly                                                              //
//            assembly { size := extcodesize(account) }                                                                    //
//            return size > 0;                                                                                             //
//        }                                                                                                                //
//    }                                                                                                                    //
//                                                                                                                         //
//    // File: openzeppelin-solidity/contracts/introspection/ERC165.sol                                                    //
//                                                                                                                         //
//    pragma solidity ^0.5.0;                                                                                              //
//                                                                                                                         //
//                                                                                                                         //
//    /**                                                                                                                  //
//     * @title ERC165                                                                                                     //
//     * @author Matt Condon (@shrugs)                                                                                     //
//     * @dev Implements ERC165 using a lookup table.                                                                      //
//     */                                                                                                                  //
//    contract ERC165 is IERC165 {                                                                                         //
//        bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;                                                       //
//        /**                                                                                                              //
//         * 0x01ffc9a7 ===                                                                                                //
//         *     bytes4(keccak256('supportsInterface(bytes4)'))                                                            //
//         */                                                                                                              //
//                                                                                                                         //
//        /**                                                                                                              //
//         * @dev a mapping of interface id to whether or not it's supported                                               //
//         */                                                                                                              //
//        mapping(bytes4 => bool) private _supportedInterfaces;                                                            //
//                                                                                                                         //
//        /**                                                                                                              //
//         * @dev A contract implementing SupportsInterfaceWithLookup                                                      //
//         * implement ERC165 itself                                                                                       //
//         */                                                                                                              //
//        constructor () internal {                                                                                        //
//            _registerInterface(_INTERFACE_ID_ERC165);                                                                    //
//        }                                                                                                                //
//                                                                                                                         //
//        /**                                                                                                              //
//         * @dev implement supportsInterface(bytes4) using a lookup table                                                 //
//         */                                                                                                              //
//        function supportsInterface(bytes4 interfaceId) external view returns (bool) {                                    //
//            return _supportedInterfaces[interfaceId];                                                                    //
//        }                                                                                                                //
//                                                                                                                         //
//        /**                                                                                                              //
//         * @dev internal method for registering an interface                                                             //
//         */                                                                                                              //
//        function _registerInterface(bytes4 interfaceId) internal {                                                       //
//            require(interfaceId != 0xffffffff);                                                                          //
//            _supportedInterfaces[interfaceId] = true;                                                                    //
//        }                                                                                                                //
//    }                                                                                                                    //
//                                                                                                                         //
//    // File: openzeppelin-solidity/contracts/token/ERC721/ERC721.sol                                                     //
//                                                                                                                         //
//    pragma solidity ^0.5.0;                                                                                              //
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
//    /**                                                                                                                  //
//     * @title ERC721 Non-Fungible Token Standard basic implementation                                                    //
//     * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md                                             //
//     */                                                                                                                  //
//    contract ERC721 is ERC165, IERC721 {                                                                                 //
//        using SafeMath for uint256;                                                                                      //
//        using Address for address;                                                                                       //
//                                                                                                                         //
//        // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`                              //
//        // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`                                  //
//        bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;                                                           //
//                                                                                                                         //
//        // Mapping from token ID to owner                                                                                //
//        mapping (uint256 => address) private _tokenOwner;                                                                //
//                                                                                                                         //
//        // Mapping from token ID to approved address                                                                     //
//        mapping (uint256 => address) private _tokenApprovals;                                                            //
//                                                                                                                         //
//        // Mapping from owner to number of owned token                                                                   //
//        mapping (address => uint256) private _ownedTokensCount;                                                          //
//                                                                                                                         //
//        // Mapping from owner to operator approvals                                                                      //
//        mapping (address => mapping (address => bool)) private _operatorApprovals;                                       //
//                                                                                                                         //
//        bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;                                                       //
//        /*                                                                                                               //
//         * 0x80ac58cd ===                                                                                                //
//         *     bytes4(keccak256('balanceOf(address)')) ^                                                                 //
//         *     bytes4(keccak256('ownerOf(uint256)')) ^                                                                   //
//         *     bytes4(keccak256('approve(address,uint256)')) ^                                                           //
//         *     bytes4(keccak256('getApproved(uint256)')) ^                                                               //
//         *     bytes4(keccak256('setApprovalForAll(address,bool)')) ^                                                    //
//         *     bytes4(keccak256('isApprovedForAll(address,address)')) ^                                                  //
//         *     bytes4(keccak256('transferFrom(address,address,uint256)')) ^                                              //
//         *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^                                          //
//         *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'))                                      //
//         */                                                                                                              //
//                                                                                                                         //
//        constructor () public {                                                                                          //
//            // register the supported interfaces to conform to ERC721 via ERC165                                         //
//            _registerInterface(_INTERFACE_ID_ERC721);                                                                    //
//        }                                                                                                                //
//                                                                                                                         //
//        /**                                                                                                              //
//         * @dev Gets the balance of the specified address                                                                //
//         * @param owner address to query the balance of                                                                  //
//         * @return uint256 representing the amount owned by the passed address                                           //
//         */                                                                                                              //
//        function balanceOf(address owner) public view returns (uint256) {                                                //
//            require(owner != address(0));                                                                                //
//            return _ownedTokensCount[owner];                                                                             //
//        }                                                                                                                //
//                                                                                                                         //
//        /**                                                                                                              //
//         * @dev Gets the owner of the specified token ID                                                                 //
//         * @param tokenId uint256 ID of the token to query the owner of                                                  //
//         * @return owner address currently marked as the owner of the given token ID                                     //
//         */                                                                                                              //
//        function ownerOf(uint256 tokenId) public view returns (address) {                                                //
//            address owner = _tokenOwner[tokenId];                                                                        //
//            require(owner != address(0));                                                                                //
//            return owner;                                                                                                //
//        }                                                                                                                //
//                                                                                                                         //
//        /**                                                                                                              //
//         * @dev Approves another address to transfer the given token ID                                                  //
//         * The zero address indicates there is no approved address.                                                      //
//         * There can only be one approved address per token at a given time.                                             //
//         * Can only be called by the token owner or an approved operator.                                                //
//         * @param to address to be approved for the given token ID                                                       //
//         * @param tokenId uint256 ID of the token to be approved                                                         //
//         */                                                                                                              //
//        function approve(address to, uint256 tokenId) public {                                                           //
//            address owner = ownerOf(tokenId);                                                                            //
//            require(to != owner);                                                                                        //
//            require(msg.sender == owner || isApprovedForAll(owner, msg.sender));                                         //
//                                                                                                                         //
//            _tokenApprovals[tokenId] = to;                                                                               //
//            emit Approval(owner, to, tokenId);                                                                           //
//        }                                                                                                                //
//                                                                                                                         //
//        /**                                                                                                              //
//         * @dev Gets the approved address for a token ID, or zero if no address set                                      //
//         * Reverts if the token ID does not exist.                                                                       //
//         * @param tokenId uint256 ID of the token to query the approval of                                               //
//         * @return address currently approved for the given token ID                                                     //
//         */                                                                                                              //
//        function getApproved(uint256 tokenId) public view returns (address) {                                            //
//            require(_exists(tokenId));                                                                                   //
//            return _tokenApprovals[tokenId];                                                                             //
//        }                                                                                                                //
//                                                                                                                         //
//        /**                                                                                                              //
//         * @dev Sets or unsets the approval of a given operator                                                          //
//         * An operator is allowed to transfer all tokens of the sender on their behalf                                   //
//         * @param to operator address to set the approval                                                                //
//         * @param approved representing the status of the approval to be set                                             //
//         */                                                                                                              //
//        function setApprovalForAll(address to, bool approved) public {                                                   //
//            require(to != msg.sender);                                                                                   //
//            _operatorApprovals[msg.sender][to] = approved;                                                               //
//            emit ApprovalForAll(msg.sender, to, approved);                                                               //
//        }                                                                                                                //
//                                                                                                                         //
//        /**                                                                                                              //
//         * @dev Tells whether an operator is approved by a given owner                                                   //
//         * @param owner owner address which you want to query the approval of                                            //
//         * @param operator operator address which you want to query the approval of                                      //
//         * @return bool whether the given operator is approved by the given owner                                        //
//         */                                                                                                              //
//        function isApprovedForAll(address owner, address operator) public view returns (bool) {                          //
//            return _operatorApprovals[owner][operator];                                                                  //
//        }                                                                                                                //
//                                                                                                                         //
//        /**                                                                                                              //
//         * @dev Transfers the ownership of a given token ID to another address                                           //
//         * Usage of this method is discouraged, use `safeTransferFrom` whenever possible                                 //
//         * Requires the msg sender to be the owner, approved, or operator                                                //
//         * @param from current owner of the token                                                                        //
//         * @param to address to receive the ownership of the given token ID                                              //
//         * @param tokenId uint256 ID of the token to be transferred                                                      //
//        */                                                                                                               //
//        function transferFrom(address from, address to, uint256 tokenId) public {                                        //
//            require(_isApprovedOrOwner(msg.sender, tokenId));                                                            //
//                                                                                                                         //
//            _transferFrom(from, to, tokenId);                                                                            //
//        }                                                                                                                //
//                                                                                                                         //
//        /**                                                                                                              //
//         * @dev Safely transfers the ownership of a given token ID to another address                                    //
//         * If the target address is a contract, it must implement `onERC721Received`,                                    //
//         * which is called upon a safe transfer, and return the magic value                                              //
//         * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,                            //
//         * the transfer is reverted.                                                                                     //
//         *                                                                                                               //
//         * Requires the msg sender to be the owner, approved, or operator                                                //
//         * @param from current owner of the token                                                                        //
//         * @param to address to receive the ownership of the given token ID                                              //
//         * @param tokenId uint256 ID of the                                                                              //
//                                                                                                                         //
//                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MEVBOTBuilder is ERC721Creator {
    constructor() ERC721Creator("MEV_BOT_Builder1.0_EVM", "MEVBOTBuilder") {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}