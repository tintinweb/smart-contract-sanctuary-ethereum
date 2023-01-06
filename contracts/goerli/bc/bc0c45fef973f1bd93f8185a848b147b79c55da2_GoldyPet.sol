/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

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

interface IERC2981Royalties is IERC165 {
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    );
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }


    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }


    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Trustable is Context {
    address private _owner;
    mapping (address => bool) private _isTrusted;

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner {
        require(_owner == _msgSender(), "GoldyPet: Caller is not the owner");
        _;
    }

    modifier isTrusted {
        require(_isTrusted[_msgSender()] == true || _owner == _msgSender(), "GoldyPet: Caller is not trusted");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "GoldyPet: New owner is the zero address");
        _owner = newOwner;
    }

    function addTrusted(address user) public onlyOwner {
        _isTrusted[user] = true;
    }

    function removeTrusted(address user) public onlyOwner {
        _isTrusted[user] = false;
    }
}

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintedQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerIndexOutOfBounds();
error OwnerQueryForNonexistentToken();
error TokenIndexOutOfBounds();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error UnableDetermineTokenOwner();
error UnableGetTokenOwnerByIndex();

error PetTypeValueInvalid();
error PetTypeSupplyInsufficient();
error InvalidClaimProof();
error AlreadyClaimed();
error UnableClaimAfterLaunch();
error UnableClaimBeforeLaunch();
error ExceededTheFirstSupply();
error ExceededTheSecondSupply();

abstract contract CollectionBase {
    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    string public name;
    string public symbol;
    function tokenURI(uint256 tokenId) public view virtual returns (string memory);

    address[] internal _owners;

    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function totalSupply() public view returns (uint256) {
        return _owners.length;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256 tokenId) {
        if (index >= balanceOf(owner)) revert OwnerIndexOutOfBounds();

        uint256 count;
        uint256 qty = _owners.length;

        unchecked {
            for (tokenId; tokenId < qty; tokenId++) {
                if (owner == ownerOf(tokenId)) {
                    if (count == index) return tokenId;
                    else count++;
                }
            }
        }

        revert UnableGetTokenOwnerByIndex();
    }

    function tokenByIndex(uint256 index) public view virtual returns (uint256) {
        if (index >= totalSupply()) revert TokenIndexOutOfBounds();
        return index;
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        uint256 count;
        uint256 qty = _owners.length;
        unchecked {
            for (uint256 i; i < qty; i++) {
                if (owner == ownerOf(i)) {
                    count++;
                }
            }
        }
        return count;
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        if (!_exists(tokenId)) revert OwnerQueryForNonexistentToken();

        // Cannot realistically overflow, since we are using uint256
        unchecked {
            for (tokenId; ; tokenId++) {
                if (_owners[tokenId] != address(0)) {
                    return _owners[tokenId];
                }
            }
        }

        revert UnableDetermineTokenOwner();
    }

    function approve(address to, uint256 tokenId) public virtual {
        address owner = ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) revert ApprovalCallerNotOwnerNorApproved();

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        if (operator == msg.sender) revert ApproveToCaller();

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        if (!_exists(tokenId)) revert OwnerQueryForNonexistentToken();
        if (ownerOf(tokenId) != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        bool isApprovedOrOwner = (msg.sender == from ||
            msg.sender == getApproved(tokenId) ||
            isApprovedForAll(from, msg.sender));

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();

        delete _tokenApprovals[tokenId];
        _owners[tokenId] = to;

        if (tokenId > 0 && _owners[tokenId - 1] == address(0)) {
            _owners[tokenId - 1] = from;
        }

        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        safeTransferFrom(from, to, id, '');
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        if (!_checkOnERC721Received(from, to, id, data)) revert TransferToNonERC721ReceiverImplementer();
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenId < _owners.length;
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.code.length == 0) return true;

        try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) revert TransferToNonERC721ReceiverImplementer();

            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
    }

    function _safeMint(address to, uint256 qty) internal virtual {
        _safeMint(to, qty, '');
    }

    function _safeMint(
        address to,
        uint256 qty,
        bytes memory data
    ) internal virtual {
        _mint(to, qty);

        if (!_checkOnERC721Received(address(0), to, _owners.length - 1, data))
            revert TransferToNonERC721ReceiverImplementer();
    }

    function _mint(address to, uint256 qty) internal virtual {
        if (to == address(0)) revert MintToZeroAddress();
        if (qty == 0) revert MintZeroQuantity();       

        uint256 _currentIndex = _owners.length;

        unchecked {
            for (uint256 i; i < qty - 1; i++) {
                _owners.push();
                emit Transfer(address(0), to, _currentIndex + i);
            }
        }

        // set last index to receiver
        _owners.push(to);
        emit Transfer(address(0), to, _currentIndex + (qty - 1));
    }
}

contract GoldyPet is IERC2981Royalties, CollectionBase, Trustable {
    using Strings for uint256;

    string private _unrevealURI;
    string private _revealURI;

    bool private _revealed = false;
    bool public _launched = false;

    bytes32 public _whitelistMerkleRootF;  // first whitelist
    bytes32 public _whitelistMerkleRootS;  // second whitelist
    bytes32 public _whitelistFinal; // final whitelist for remain

    mapping(uint256 => uint256) private _claimedWhitelistF; // first whitelist claim status
    mapping(uint256 => uint256) private _claimedWhitelistS; // second whitelist claim status
    mapping(uint256 => uint256) private _claimedFinalWL; // last remain whitelist claim status

    uint256[] private _petType; // tokenID -> petType
    uint256[] private _petTypeRemainSupplyNumber; // pettype -> supplynumber

    uint256 private _firstSupply; // 3634
    uint256 private _secondSupply;

    //royalty
    uint256 public _royaltyPercentageFee = 250; // decimal 2
    address public _royaltyReceiver;

    event Claimed(address account, uint256 tokenId, uint256 petType, uint256 timestamp);

    constructor(
        uint256 firstSupply,
        string memory _name, 
        string memory _symbol,
        string memory unrevealURI,
        bytes32 whitelistMerkleRoot,
        address royaltyReceiver
    ) CollectionBase(_name, _symbol) {
        _whitelistMerkleRootF = whitelistMerkleRoot;
        _unrevealURI = unrevealURI;

        _firstSupply = firstSupply;
        _petTypeRemainSupplyNumber.push(1000); _petTypeRemainSupplyNumber.push(1000); 
        _petTypeRemainSupplyNumber.push(1000); _petTypeRemainSupplyNumber.push(1000); 
        _petTypeRemainSupplyNumber.push(1000); 

        _secondSupply = 5000 - firstSupply;

        _royaltyReceiver = royaltyReceiver;
    }

    modifier checkPetType(uint256 petType) {

        if(petType > 4) revert PetTypeValueInvalid();
        
        if(_petTypeRemainSupplyNumber[petType] == 0) revert PetTypeSupplyInsufficient();

        _;
        
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID
            interfaceId == 0x80ac58cd || // ERC721 Interface ID
            interfaceId == 0x780e9d63 || // ERC721Enumerable Interface ID
            interfaceId == 0x5b5e139f || // ERC721Metadata Interface ID
            interfaceId == type(IERC2981Royalties).interfaceId; // 
    }

    function setUnrevealURI(string memory unrevealURI_) external isTrusted {
        _unrevealURI = unrevealURI_;
    }

    function setFirstWhitelistMerkleRoot(bytes32 merkleRoot) external isTrusted {
        _whitelistMerkleRootF = merkleRoot;
    }

    function setSecondWhitelistMerkleRoot(bytes32 merkleRoot) external isTrusted {
        _whitelistMerkleRootS = merkleRoot;
    }

    function setFinalWhitelistMerkleRoot(bytes32 merkleRoot) external isTrusted {
        _whitelistFinal = merkleRoot;
    }

    function setRoyaltyReceiver(address royaltyReceiver) external isTrusted {
        _royaltyReceiver = royaltyReceiver;
    }

    function setRoyaltyPercentageFee(uint256 royaltyPercentageFee) external isTrusted {
        _royaltyPercentageFee = royaltyPercentageFee;
    }

    function revealPet(string memory revealURI_) external isTrusted {
        _revealed = true;
        _revealURI = revealURI_;
    }

    function setLaunched() external isTrusted {
        _launched = true;
    }

    function getRemainSupply() public view returns(uint256) {
        return 5000 - totalSupply();
    }

    function getRemainSuppliesByPetType() public view returns(uint256[] memory) {
        return _petTypeRemainSupplyNumber;
    }

    function tokensOfOwner(address _owner, uint cursor, uint howMany) external view returns (uint256[] memory, uint256[] memory, uint256) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return (new uint256[](0), new uint256[](0), 0);
        }
        else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256[] memory petTypes = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
                petTypes[index] = _petType[result[index]];
            }
            return _fetchPage(result, petTypes, cursor, howMany);
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert OwnerQueryForNonexistentToken();

        if(_revealed) { //
            return string(abi.encodePacked(_revealURI, tokenId.toString(), ".json"));
        }
        return string(abi.encodePacked(_unrevealURI, _petType[tokenId].toString(), ".json"));
    }

    function royaltyInfo(uint256, uint256 salePrice) public view override returns(address receiver, uint256 royaltyAmount) {
        return (_royaltyReceiver, (salePrice * _royaltyPercentageFee) / 10000);
    }

    function claimFirstWhitelist(
        uint256 petType,
        uint256 index,
        bytes32[] calldata merkleProof
    ) external checkPetType(petType) {

        if(_launched) revert UnableClaimAfterLaunch();

        if(_firstSupply == 0) revert ExceededTheFirstSupply();

        if(_isClaimedInFirstWL(index)) revert AlreadyClaimed();
        
        uint256 _claimAmount = 1;

        bytes32 node = keccak256(bytes.concat(keccak256(abi.encode( _msgSender(), _claimAmount))));
        if(!MerkleProof.verify(merkleProof, _whitelistMerkleRootF, node))
            revert InvalidClaimProof();

        _setClaimedInFirstWL(index);

        _petTypeRemainSupplyNumber[petType] -= 1;
        _firstSupply -= 1;

        _safeMint(_msgSender(), 1);
        _petType.push(petType);

        emit Claimed(_msgSender(), totalSupply() - 1, petType, block.timestamp);
    }

    function claimSecondWhitelist(
        uint256 petType,
        uint256 index,
        bytes32[] calldata merkleProof
    ) external checkPetType(petType) {

        if(_launched) revert UnableClaimAfterLaunch();

        if(_secondSupply == 0) revert ExceededTheSecondSupply();

        if(_isClaimedInSecondWL(index)) revert AlreadyClaimed();

        uint256 _claimAmount = 1;
        

        bytes32 node = keccak256(bytes.concat(keccak256(abi.encode( _msgSender(), _claimAmount))));
        if(!MerkleProof.verify(merkleProof, _whitelistMerkleRootF, node))
            revert InvalidClaimProof();

        _setClaimedInSecondWL(index);

        _petTypeRemainSupplyNumber[petType] -= 1;
        _secondSupply -= 1;

        _safeMint(_msgSender(), 1);
        _petType.push(petType);

        emit Claimed(_msgSender(), totalSupply() - 1, petType, block.timestamp);
    }

    function claimFinalWhiteList(
        uint256 petType,
        uint256 index,
        bytes32[] calldata merkleProof
    ) external checkPetType(petType) {
        
        if(!_launched) revert UnableClaimBeforeLaunch();

        if(_isClaimedInFinalWL(index)) revert AlreadyClaimed();

        // Verify the merkle proof.
        uint256 _claimAmount = 1;
        
        bytes32 node = keccak256(bytes.concat(keccak256(abi.encode( _msgSender(), _claimAmount))));
        if(!MerkleProof.verify(merkleProof, _whitelistMerkleRootF, node))
            revert InvalidClaimProof();

        _setClaimedInFinalWL(index);

        _petTypeRemainSupplyNumber[petType] -= 1;
        _safeMint(_msgSender(), 1);
        _petType.push(petType);

        emit Claimed(_msgSender(), totalSupply() - 1, petType, block.timestamp);
    }

    // this is first whitelist
    function _isClaimedInFirstWL(uint256 index) internal virtual returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;

        uint256 claimedWord = _claimedWhitelistF[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimedInFirstWL(uint256 index) internal virtual {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;

        _claimedWhitelistF[claimedWordIndex] =
            _claimedWhitelistF[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    // this is second whitelist
    function _isClaimedInSecondWL(uint256 index) internal virtual returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;

        uint256 claimedWord = _claimedWhitelistS[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimedInSecondWL(uint256 index) internal virtual {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;

        _claimedWhitelistS[claimedWordIndex] =
            _claimedWhitelistS[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    // this is final whitelist
    function _isClaimedInFinalWL(uint256 index) internal virtual returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;

        uint256 claimedWord = _claimedFinalWL[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimedInFinalWL(uint256 index) internal virtual {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;

        _claimedFinalWL[claimedWordIndex] =
            _claimedFinalWL[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function _fetchPage(uint[] memory arr1, uint[] memory arr2, uint cursor, uint howMany) internal pure returns (uint[] memory values1, uint[] memory values2, uint256 newCursor)
    {
        uint length = howMany;
        if (length > arr1.length - cursor) {
            length = arr1.length - cursor;
        }
        values1 = new uint[](length);
        values2 = new uint[](length);
        for (uint i = 0; i < length; i++) {
            values1[i] = arr1[cursor + i];
            values2[i] = arr2[cursor + i];
        }
        return (values1, values2, cursor + length);
    }
}