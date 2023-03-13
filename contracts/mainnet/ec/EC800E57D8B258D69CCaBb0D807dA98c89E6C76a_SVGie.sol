// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './interfaces/IERC165.sol';

/// @dev Implemetacion of the {IERC165} interface.
abstract contract ERC165 is IERC165 {

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ERC165.sol';
import './interfaces/IERC721.sol';
import "./interfaces/IERC721TokenReceiver.sol";
import './interfaces/extensions/IERC721Metadata.sol';

/** @title ERC-721-GNT - Non-Fungible Token Standard optimized for Gating 
 *         (Non-Transferable) only 1 per Wallet
 *  @notice Since it's Non-Transferable, approve, approveForAll, and transfers always throw
 *          ("Read Only NFT Registry" from https://eips.ethereum.org/EIPS/eip-721#rationale)
 *          None of these methods emit Events
 *  @dev By token gating, we optimize for 1 NFT per wallet (as a specific use case)
 *       NFT - Wallet is 1 to 1, so the address is used as tokenId
 */
contract ERC721TGNT is ERC165, IERC721, IERC721Metadata {

    /** A name for the NFTs in the contract
     */
    string private _name;

    /** An abbreviated symbol for the NFTs in the contract
     */
    string private _symbol;

    /** @dev Mapping from address to bool (tokenId IS the owner address)
     */
    mapping(address => bool) private _owners;

    /** @dev Error that is thrown whenever an address for Invalid NFTs is queried
     */
    error ZeroAddressQuery();

    /** @dev Error that is thrown whenever an Invalid NFTs is queried
     */
    error NonExistentTokenId(uint256 tokenId);

    /** @dev Error that is thrown whenever transfers or approvals are called
     */
    error TransferAndApprovalsDisabled();

    /** @dev Error that is thrown when addr already has 1 token
     *  @param addr The address that already owns 1 token
     */
    error AlreadyOwnsToken(address addr);

    /** @dev Error that is thrown when receiver address is a smart contract
     *       and doesn't implement onERC721Received correctly
     *  @param addr The address that already owns 1 token
     */
    error OnERC721ReceivedNotOk(address addr);


    /** @dev constructor
     *  @param name_ A descriptive name for a collection of NFTs in this contract
     *  @param symbol_ An abbreviated name for NFTs in this contract
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Override {IERC165-supportsInterface} to add the supported interfaceIds
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /** @notice A descriptive name for a collection of NFTs in this contract
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /** @notice An abbreviated name for NFTs in this contract
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /** @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     *  @dev Throws if `_tokenId` is not a valid NFT
     *       Empty by default, can be overridden in child contracts.
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        if (!_exists(_tokenId)) revert NonExistentTokenId(_tokenId);
        return "";
    }

    /** @notice Count all NFTs assigned to an owner, in this case, only 0 or 1
     *  @dev Throws {ZeroAddressQuery} when queried for 0x0 address
     *  @param _owner Address that the balance queried
     *  @return Number of NFTs owned (0 or 1)
     */
    function balanceOf(address _owner) public view virtual override returns (uint256) {
        if (_owner == address(0x0)) revert ZeroAddressQuery();
        if (_owners[_owner]) return 1;
        return 0;
    }

    /** @notice Finds the owner of an NFT
     *  @dev Throws {NonExistentToken} when `_tokenId`is invalid (not minted)
     *  @param _tokenId The identifier for an NFT
     *  @return The address of the owner of the NFT
     */
    function ownerOf(uint256 _tokenId) public view virtual override returns (address) {
        if (!_exists(_tokenId)) revert NonExistentTokenId(_tokenId);
        return (address(uint160(_tokenId)));
    }

    /** @notice Transfers ownership of an NFT from one address to another address
     *  @dev Throws always, (Non-Transferable token)
     *       Emits a {Transfer} event
     */
    function safeTransferFrom(address, address, uint256, bytes memory) public virtual override {
        revert TransferAndApprovalsDisabled();
    }

    /** @notice Transfers the ownership of an NFT from one address to another address
     *  @dev This works identically to the other function with an extra data parameter,
     *       except this function just sets data to "".
     */
    function safeTransferFrom(address, address, uint256) public virtual override {
        revert TransferAndApprovalsDisabled();
    }

    /** @notice Transfers ownership of an NFT from one address to another 
     *          -- CALLER IS RESPONSIBLE IF `_to` IS NOT CAPABLE OF
     *             RECEIVING NFTS (THEY MAY BE PERMANENTLY LOST)
     *  @dev Throws always, (Non-Transferable token)
     *       Emits a {Transfer} event
     *  Emits a {Transfer} event
     */
    function transferFrom(address, address, uint256) public virtual override {
        revert TransferAndApprovalsDisabled();
    }

    /** @notice Change or reaffirm the approved address for an NFT
     *  @dev Throws always, (Non-Transferable token)
     *       Emits a {Approval} event
     */
    function approve(address, uint256) public virtual override {
        revert TransferAndApprovalsDisabled();
    }

    /** @notice Enable or disable approval for a third party ("operator") to manage
     *   all of `msg.sender`'s assets
     *  @dev Throws always, (Non-Transferable token)
     *       Emits a {ApprovalForAll} event
    */
    function setApprovalForAll(address, bool) public virtual override {
        revert TransferAndApprovalsDisabled();
    }

    /** @notice Get the approved address for a single NFT
     *  @dev Throws if `_tokenId` is not a valid NFT.
     *  @param _tokenId The NFT to find the approved address for
     *  @return The zero address, because Approvals are disabled
     */
    function getApproved(uint256 _tokenId) public view virtual override returns (address) {
        if (!_exists(_tokenId)) revert NonExistentTokenId(_tokenId);
        return address(0x0);
    }

    /** @notice Query if an address is an authorized operator for another address
     *  @return False, because approvalForAll is disabled
     */
    function isApprovedForAll(address, address) public view virtual override returns (bool) {
        return false;
    }

    /* *** Internal Functions *** */

    /** @dev Returns if a certain _tokenId exists
     *  @param _tokenId Id of token to query
     *  @return bool true if token exists, false otherwise
     */
    function _exists(uint256 _tokenId) internal view virtual returns (bool) {
        if (uint160(_tokenId) == 0) return false;
        return _owners[address(uint160(_tokenId))];
    }

    /** @dev Mints and transfers a token to `_to`
     *       Throws {ZeroAddressQuery} if `_to` is the Zero address
     *       Throws {AlreadyOwnsToken}
     *       Emits a {Transfer} event, with zero address as `_from`,
     *       `_to` as `_to` and a `_to` as zero padded uint256 as `_tokenId`
     *  @param _to Address to mint the token to
     */
    function _safeMint(address _to) internal virtual {
        if (_to == address(0x0)) revert ZeroAddressQuery();
        if (_owners[_to]) revert AlreadyOwnsToken(_to);
        _owners[_to] = true;
        emit Transfer(address(0x0), _to, uint256(uint160(_to)));
        if (!_isOnERC721ReceivedOk(address(0x0), _to, uint256(uint160(_to)), '')) {
            revert OnERC721ReceivedNotOk(_to);
        }
    }

    /** @dev This is provided for OpenZeppelin's compatibility
     *       It has the same functionality as {_safeMint}
     *  @param _to Address to mint the token to
     *         2nd param is (uint256) IS IGNORED - It just mints
     *         to the Id: uint256(uint160(_to))
     */
    function _safeMint(address _to, uint256) internal virtual {
        _safeMint(_to);
    }

    /** @dev Burns or destroys an NFT with `_tokenId`
     *       Throws {NonExistentToken} when `_tokenId`is invalid (not minted)
     *       Emits a {Transfer} event, with msg.sender as `_from`, zero address
     *       as `_to`, and a zero padded uint256 as `_tokenId`
     *  @param _tokenId Id of the token to be burned
     */
    function _burn(uint256 _tokenId) internal virtual {
        if (!_exists(_tokenId)) revert NonExistentTokenId(_tokenId);

        delete _owners[address(uint160(_tokenId))];

        emit Transfer(msg.sender, address(0x0), uint256(uint160(_tokenId)));
    }

    /** @dev Function to be called on an address only when it is a smart contract
     *  @param _from address from the previous owner of the token
     *  @param _to address that received the token
     *  @param _tokenId Id of the token to be transferred
     *  @param data optional bytes to send in the function call
     */
    function _isOnERC721ReceivedOk(address _from, address _to, uint256 _tokenId, bytes memory data) private returns (bool) {
        // if `_to` is NOT a smart contract, return true
        if (_to.code.length == 0) return true;

        // `_to` is a smart contract, check that it implements onERC721Received correctly
        try IERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, data) returns (bytes4 retval) {
            return retval == IERC721TokenReceiver.onERC721Received.selector;
        } catch (bytes memory errorMessage) {
            // if we don't get a message, revert with custom error
            if (errorMessage.length == 0) revert OnERC721ReceivedNotOk(_to);
            
            // if we get a message, we revert with that message
            assembly {
                revert(add(32, errorMessage), mload(errorMessage))
            }
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IERC165.sol';

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 is IERC165 {

    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721TokenReceiver {
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
        bytes memory _data)
    external
    returns(bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
interface IERC721Metadata /* is ERC721 */ {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory _name);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory _symbol);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@7i7o/tokengate/src/ERC721TGNT.sol";
import {TokenURIDescriptor} from "./lib/TokenURIDescriptor.sol";

contract SVGie is ERC721TGNT {
    address public owner;
    uint256 public totalSupply;
    uint256 public price;
    bool public mintActive;

    error NotOwnerOf(uint256 tokenId);

    error OnlyOwner();

    constructor(uint256 mintPrice) ERC721TGNT("SVGie", "SVGie") {
        owner = msg.sender;
        price = mintPrice;
    }

    function safeMint(address _to) public payable {
        require(mintActive, "Mint is not active");
        require(msg.value >= price, "Value sent < Mint Price");
        totalSupply++;
        _safeMint(_to, uint256(uint160(_to)));
    }

    function teamMint(address _to) public {
        if (msg.sender != owner) revert OnlyOwner();
        totalSupply++;
        _safeMint(_to, uint256(uint160(_to)));
    }

    function burn(uint256 tokenId) public virtual {
        if (msg.sender != ownerOf(tokenId)) revert NotOwnerOf(tokenId);
        totalSupply--;
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721TGNT)
        returns (string memory)
    {
        require(_exists(tokenId), "SVGie: Non Existent TokenId");
        return
            TokenURIDescriptor.tokenURI(
                address(uint160(tokenId)),
                super.name(),
                super.symbol()
            );
    }

    function setOwner(address newOwner) public {
        if (msg.sender != owner) revert OnlyOwner();
        owner = newOwner;
    }

    function setPrice(uint256 mintPrice) public {
        if (msg.sender != owner) revert OnlyOwner();
        price = mintPrice;
    }

    function toggleMintActive() public {
        if (msg.sender != owner) revert OnlyOwner();
        if (!mintActive) mintActive = true;
        else mintActive = false;
    }

    function withdraw() public {
        uint256 amount = address(this).balance;
        // Revert if no funds
        require(amount > 0, "Balance is 0");
        // Withdraw funds.
        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, "Withdraw failed");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import { Base64 } from './Base64.sol';

string constant SVGa = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="8 8 32 32" width="300" height="300">'
                            '<radialGradient id="'; // C0 C1
string constant SVGb = '"><stop stop-color="#'; // C0
string constant SVGc = '" offset="0"></stop><stop stop-color="#'; // C1
string constant SVGd = '" offset="1"></stop></radialGradient>'
                        '<rect x="8" y="8" width="100%" height="100%" opacity="1" fill="white"></rect>'
                        '<rect x="8" y="8" width="100%" height="100%" opacity=".5" fill="url(#'; // C0 C1
string constant SVGe = ')"></rect><linearGradient id="'; // C2 C3 C2
string constant SVGf = '"><stop stop-color="#'; // C2
string constant SVGg = '" offset="0"></stop><stop stop-color="#'; // C3
string constant SVGh = '" offset=".5"></stop><stop stop-color="#'; // C2
string constant SVGi = '" offset="1"></stop></linearGradient><linearGradient id="'; // C3 C2 C3
string constant SVGj = '"><stop stop-color="#'; // C3
string constant SVGk = '" offset="0"></stop><stop stop-color="#'; // C2
string constant SVGl = '" offset=".5"></stop><stop stop-color="#'; // C3
string constant SVGm = '" offset="1"></stop></linearGradient><path fill="url(#'; // C2 C3 C2 
string constant SVGn = ')" stroke-width="0.1" stroke="url(#'; // C3 C2 C3
string constant SVGo = ')" d="'; // PATH
string constant SVGp = '"></path></svg>';

library TokenURIDescriptor {

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toHexString(
        address _addr
    )
    internal
    pure
    returns (string memory) {
        bytes memory buffer = new bytes(42);
        uint160 addr = uint160(_addr);
        buffer[0] = "0";
        buffer[1] = "x";
        buffer[41] = _HEX_SYMBOLS[addr & 0xf];
        for (uint256 i = 40; i > 1; i--) {
            addr >>= 4;
            buffer[i] = _HEX_SYMBOLS[addr & 0xf];
        }
        return string(buffer);
    }


    function getColors(
        address _addr
    )
    internal
    pure
    returns(string[4] memory) {
        uint256 kecc = uint(keccak256(abi.encodePacked(_addr)));
        string[4] memory s;
        bytes memory fixedColor = new bytes(8);
        kecc >>= 128;
        uint32 color;
        uint32 opacity;
        color = uint32(kecc & 0xffffffff);
        opacity = (uint32(color & 0xff) * 256) / 1024 + 191;
        fixedColor[7] = _HEX_SYMBOLS[opacity & 0xf];
        opacity >>= 4;
        fixedColor[6] = _HEX_SYMBOLS[opacity & 0xf];
        color >>= 8;
        fixedColor[5] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[4] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[3] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[2] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[1] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[0] = _HEX_SYMBOLS[color & 0xf];
        s[3] = string(fixedColor);
        fixedColor = new bytes(8);
        kecc >>= 32;
        color = uint32(kecc & 0xffffffff);
        opacity = (uint32(color & 0xff) * 256) / 1024 + 191;
        fixedColor[7] = _HEX_SYMBOLS[opacity & 0xf];
        opacity >>= 4;
        fixedColor[6] = _HEX_SYMBOLS[opacity & 0xf];
        color >>= 8;
        fixedColor[5] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[4] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[3] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[2] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[1] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[0] = _HEX_SYMBOLS[color & 0xf];
        s[2] = string(fixedColor);
        fixedColor = new bytes(8);
        kecc >>= 32;
        color = uint32(kecc & 0xffffffff);
        opacity = (uint32(color & 0xff) * 256) / 1024 + 191;
        fixedColor[7] = _HEX_SYMBOLS[opacity & 0xf];
        opacity >>= 4;
        fixedColor[6] = _HEX_SYMBOLS[opacity & 0xf];
        color >>= 8;
        fixedColor[5] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[4] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[3] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[2] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[1] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[0] = _HEX_SYMBOLS[color & 0xf];
        s[1] = string(fixedColor);
        fixedColor = new bytes(8);
        kecc >>= 32;
        color = uint32(kecc & 0xffffffff);
        opacity = (uint32(color & 0xff) * 256) / 1024 + 191;
        fixedColor[7] = _HEX_SYMBOLS[opacity & 0xf];
        opacity >>= 4;
        fixedColor[6] = _HEX_SYMBOLS[opacity & 0xf];
        color >>= 8;
        fixedColor[5] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[4] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[3] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[2] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[1] = _HEX_SYMBOLS[color & 0xf];
        color >>= 4;
        fixedColor[0] = _HEX_SYMBOLS[color & 0xf];
        s[0] = string(fixedColor);
        return s;
    }
    
    function getPath(
        address _addr
    )
    internal
    pure
    returns (string memory) {
        // 40 integers from each hex character of the address (+16 to avoid negatives later)
        uint8[40] memory c;
        uint160 addr = uint160(_addr);
        for (uint8 i = 40; i > 0; i--) {
            c[i-1] = uint8((addr & 0xf) + 16);
            addr >>= 4;
        }
        // An array of strings with the possible values of each integer
        string[49] memory n = [
        '0 ','1 ','2 ','3 ','4 ','5 ','6 ','7 ','8 ','9 ',
        '10 ','11 ','12 ','13 ','14 ','15 ','16 ','17 ','18 ','19 ',
        '20 ','21 ','22 ','23 ','24 ','25 ','26 ','27 ','28 ','29 ',
        '30 ','31 ','32 ','33 ','34 ','35 ','36 ','37 ','38 ','39 ',
        '40 ','41 ','42 ','43 ','44 ','45 ','46 ','47 ','48 '
        ];
        // The Path is created (here lies all the magic)
        string[12] memory o;
        o[0] = string.concat( 'M', n[c[0]], n[c[1]], 'C', n[c[2]], n[c[3]], n[c[4]], n[c[5]] , n[c[6]], n[c[7]] );
        o[1] = string.concat( 'S', n[c[8]], n[c[9]], n[c[10]], n[c[11]], 'S', n[c[12]], n[c[13]] , n[c[14]], n[c[15]] );
        o[2] = string.concat( 'S', n[c[16]], n[c[17]], n[c[18]], n[c[19]], 'S', n[c[20]], n[c[21]], n[c[22]], n[c[23]] );
        o[3] = string.concat( 'S', n[c[24]], n[c[25]], n[c[26]], n[c[27]], 'S', n[c[28]], n[c[29]] , n[c[30]], n[c[31]] );
        o[4] = string.concat( 'S', n[c[32]], n[c[33]], n[c[34]], n[c[35]], 'S', n[c[36]], n[c[37]] , n[c[38]], n[c[39]] );
        o[5] = string.concat( 'Q', n[2*c[38]-c[36]], n[2*c[39]-c[37]], n[c[0]], n[c[1]] );

        o[6] = string.concat( 'M', n[48-c[0]], n[c[1]], 'C', n[48-c[2]], n[c[3]], n[48-c[4]], n[c[5]] , n[48-c[6]], n[c[7]] );
        o[7] = string.concat( 'S', n[48-c[8]], n[c[9]], n[48-c[10]], n[c[11]], 'S', n[48-c[12]], n[c[13]], n[48-c[14]], n[c[15]] );
        o[8] = string.concat( 'S', n[48-c[16]], n[c[17]], n[48-c[18]], n[c[19]], 'S', n[48-c[20]], n[c[21]], n[48-c[22]], n[c[23]] );
        o[9] = string.concat( 'S', n[48-c[24]], n[c[25]], n[48-c[26]], n[c[27]], 'S', n[48-c[28]], n[c[29]] , n[48-c[30]], n[c[31]] );
        o[10] = string.concat( 'S', n[48-c[32]], n[c[33]], n[48-c[34]], n[c[35]], 'S', n[48-c[36]], n[c[37]] , n[48-c[38]], n[c[39]] );
        o[11] = string.concat( 'Q', n[48-(2*c[38]-c[36])], n[2*c[39]-c[37]], n[48-c[0]], n[c[1]], 'z' );

        string memory out = string.concat (o[0], o[1], o[2], o[3], o[4], o[5], o[6]);
        out = string.concat (out, o[7], o[8], o[9], o[10], o[11]);

        return out;
    }

    function getSVG(
        address _addr
    )
    internal
    pure
    returns (string memory) {
        string[4] memory c = getColors(_addr);
        string memory c01 = string.concat(c[0], c[1]);
        string memory c232 = string.concat(c[2], c[3], c[2]);
        string memory c323 = string.concat(c[3], c[2], c[3]);
        string memory path = getPath(_addr);
        string memory o = string.concat(SVGa, c01, SVGb, c[0], SVGc, c[1], SVGd, c01, SVGe);
        o = string.concat(o, c232, SVGf, c[2], SVGg, c[3], SVGh, c[2], SVGi);
        o = string.concat(o, c323, SVGj, c[3], SVGk, c[2], SVGl, c[3], SVGm);
        o = string.concat(o, c232, SVGn, c323, SVGo, path, SVGp);

        return o;
    }

    // function getEncodedSVG(address _addr, string calldata name, string calldata symbol) public pure returns (string memory) {
    function tokenURI(
        address _addr,
        string memory _name,
        string memory _symbol
    )
    internal
    pure
    returns (string memory) {

        string[9] memory json;
        
        json[0] = '{"name":"';
        json[1] = _name;
        json[2] = ' #';
        json[3] = toHexString(_addr);
        json[4] = '","symbol":"';
        json[5] = _symbol;
        json[6] = '","description":"Wallet SVG Representation","image": "data:image/svg+xml;base64,';
        json[7] = Base64.encode(bytes(getSVG(_addr)));
        json[8] = '"}';

        string memory output = string.concat(json[0], json[1], json[2], json[3], json[4], json[5], json[6], json[7], json[8]);

        return string.concat("data:application/json;base64,", Base64.encode(bytes(output)));

    }

}