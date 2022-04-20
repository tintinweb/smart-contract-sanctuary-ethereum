//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
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
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
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

abstract contract ReentrancyGuard {
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
     * by making the `nonReentrant` function external, and make it call a
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

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
        require(_owner == _msgSender(), "HtcNftSeries2: Caller is not the owner");
        _;
    }

    modifier isTrusted {
        require(_isTrusted[_msgSender()] == true || _owner == _msgSender(), "HtcNftSeries2: Caller is not trusted");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "HtcNftSeries2: New owner is the zero address");
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
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerQueryForNonexistentToken();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

contract ERC721 is Context, ERC165, IERC721 {
    using Address for address;

    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
        bool burned;
    }

    struct AddressData {
        uint64 balance;
        uint64 numberMinted;
        uint64 numberBurned;
        uint64 aux;
    }

    uint256 internal _currentIndex;
    uint256 internal _burnCounter;

    mapping(uint256 => TokenOwnership) internal _ownerships;
    mapping(address => AddressData) private _addressData;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;   

    constructor() {
        _currentIndex = _startTokenId();
    }

    function _startTokenId() internal view virtual returns (uint256) {
        return 1;
    }

    function totalSupply() public view returns (uint256) {
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    function _totalMinted() internal view returns (uint256) {
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    function _currentTokenId() internal view returns (uint256) {
        return _currentIndex;
    }

    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    function _getAux(address owner) internal view returns (uint64) {
        return _addressData[owner].aux;
    }

    function _setAux(address owner, uint64 aux) internal {
        _addressData[owner].aux = aux;
    }

    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;
        unchecked {
            if (_startTokenId() <= curr && curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }

        revert OwnerQueryForNonexistentToken();
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex && !_ownerships[tokenId].burned;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        uint256 startTokenId = _currentIndex;

        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex != end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex != end);
            }
            _currentIndex = updatedIndex;
        }

        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            do {
                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex != end);

            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        _approve(address(0), tokenId, from);

        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSender() == from ||
                isApprovedForAll(from, _msgSender()) ||
                getApproved(tokenId) == _msgSender());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        _approve(address(0), tokenId, from);

        unchecked {
            AddressData storage addressData = _addressData[from];
            addressData.balance -= 1;
            addressData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

contract HtcNftSeries2 is IERC721Metadata, ERC721, Trustable, ReentrancyGuard {
    using Strings for uint256;

    string private _name;
    string private _symbol;

    string private _baseURI;
    mapping(uint256 => string) private _tokenURIs;

    address private _teamAirdropWallet;
    /*
    Mint Step
    1: Team Batch & Airdrop  ,  Founder WL @ 0.05ETH (500)
    2: Public Sale Pre-Integration @ 0.1ETH
    3: Public Sale Post-Integration @ 0.2ETH
    */
    uint256 private _mintStep = 1;
    uint256 private _nftSeriesTotalSupply = 5000;

    mapping(uint256 => uint256) private _claimedHtcBuyers;

    uint256 public _teamBatchSupplyRemain;  // 500

    uint256 public _airdropCount = 100;
    bytes32 public _airdropMerkleRoot; // should be generated in backend

    mapping(address => bool) private _additionFounderWL;
    mapping(address => bool) private _mintedAddFounderWL;

    mapping(uint256 => uint256) private _mintedFounderWL;
    uint256 public _founderWLSupplyRemain;  // 500
    bytes32 public _whitelistMerkleRoot;

    mapping(uint256 => uint256) private _mintPrices;

    string public _uriAddParam;

    event TeamBatchMint(address teamAirdropWallet, uint256 startTokenId, uint256 batchCount, uint256 timestamp);
    event Claimed(address account, uint256 tokenId, uint256 timestamp);
    event MintItem(address account, uint256 tokenId, uint256 mintAmount, uint256 timestamp);

    constructor(
        string memory name_, 
        string memory symbol_,
        address teamAirdropWallet,
        bytes32 airdropMerkleRoot,
        bytes32 whitelistMerkleRoot,
        uint256 teamBatchSupplyRemain,
        uint256 founderWLSupplyRemain
    ) {
        _name = name_;
        _symbol = symbol_;

        //set TeamAirdropWallet address
        _teamAirdropWallet = teamAirdropWallet;
        //set AirdropMerkleRoot
        _airdropMerkleRoot = airdropMerkleRoot;
        

        _teamBatchSupplyRemain = teamBatchSupplyRemain; // 300
        _founderWLSupplyRemain = founderWLSupplyRemain; // 500

        _whitelistMerkleRoot = whitelistMerkleRoot;


        _mintPrices[1] = 0.05 ether;
        _mintPrices[2] = 0.1 ether;
        _mintPrices[3] = 0.2 ether;

        _uriAddParam = ".json";
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function getMintStep() public view isTrusted returns (uint256) {
        return _mintStep;
    }

    function getTeamAirdropWallet() public view isTrusted returns(address) {
        return _teamAirdropWallet;
    }
    
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "HtcNftSeries2: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        if (bytes(base).length == 0 || bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        return string(abi.encodePacked(base, tokenId.toString(), _uriAddParam)); 
    }

    function calculatePrice() public view returns (uint256) {
        return _mintPrices[_mintStep];
    }

    function setBaseURI(string memory baseURI_) public isTrusted {
        _setBaseURI(baseURI_);
    }

    function setTeamBatchSupplyRemain(uint256 teamBatchSupplyRemain) public isTrusted {
        _teamBatchSupplyRemain = teamBatchSupplyRemain;
    }
    
    function setFounderWLSupplyRemain(uint256 founderWLSupplyRemain) public isTrusted {
        _founderWLSupplyRemain = founderWLSupplyRemain;
    }

    function setTokenUriAddParam(string memory tokenUriAddParam) public isTrusted {
        _uriAddParam = tokenUriAddParam;
    }

    function setTokenURI(uint256 tokenId, string memory tokenURI_) public isTrusted {
        require(_exists(tokenId), "HtcNftSeries2: This token is not minted");
        _setTokenURI(tokenId, tokenURI_);
    }

    function setMintStep(uint256 mintStep) public isTrusted {
        _mintStep = mintStep;
    }

    function setMintingPrice(uint256 mintStep, uint256 price) public isTrusted {
        _mintPrices[mintStep] = price;
    }

    function setTeamAirdropWallet(address newTeamAirdropWallet) external isTrusted {
        require(newTeamAirdropWallet != address(0x0), "HtcNftSeries2: INVALID_NEW_TEAM_AIRDROP_WALLET");
        _teamAirdropWallet = newTeamAirdropWallet;
    }

    function setAirdropMerkleRoot(bytes32 merkleRoot) public isTrusted {
        _airdropMerkleRoot = merkleRoot;
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) public isTrusted {
        _whitelistMerkleRoot = merkleRoot;
    }

    function addFounderWhiteList(address[] calldata addr) external isTrusted {
        for(uint256 i = 0; i < addr.length; i ++) {
            _additionFounderWL[addr[i]] = true;
        }
    }

    function teamBatchMint(uint256 batchCount) external isTrusted {
        require(_mintStep == 1, "HtcNftSeries2: Team batch mint is not possible for now");
        require(_teamBatchSupplyRemain > 0, "HtcNftSeries2: Team batch mint has already done");
        require(batchCount > 0 && batchCount <= _teamBatchSupplyRemain, "HtcNftSeries2: Batch count is not valid");

        uint256 _startTokenId = _currentTokenId();

        _safeMint(_teamAirdropWallet, batchCount);
        _teamBatchSupplyRemain = _teamBatchSupplyRemain - batchCount;
        
        emit TeamBatchMint(_teamAirdropWallet, _startTokenId, batchCount, block.timestamp);
    }
    
    function claim(
        uint256 index,
        bytes32[] calldata merkleProof
    ) external {
        require(_airdropCount > 0, "HtcNftSeries2: Claim is not possible");
        require(!_isClaimed(index), "HtcNftSeries2: You've already claimed");

        uint256 _airdropAmount = 1;

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, _msgSender(), _airdropAmount));
        require(
            MerkleProof.verify(merkleProof, _airdropMerkleRoot, node),
            "HtcNftSeries2: Invalid claim proof"
        );

        // Mark Claimed
        _setClaimed(index);

        _airdropCount = _airdropCount - 1; 

        uint256 _startTokenId = _currentTokenId();

        _safeMint(_msgSender(), 1);

        //_currentTokenId()
        emit Claimed(_msgSender(), _startTokenId, block.timestamp);
    } 

    function mintItem(
        uint256 mintAmount, uint256 index, bytes32[] calldata merkleProof
    ) public payable nonReentrant {
        if(_mintStep == 1) {
            require(mintAmount == 1, "HtcNftSeries2: You can only mint 1 item");
        }
        else { // _mintStep: 2,3
            require(mintAmount >= 1 && mintAmount <= 10, "HtcNftSeries2: Mint amount is not valid");
        }

        uint256 _startTokenId = _currentTokenId();
        require(_startTokenId + mintAmount <= _nftSeriesTotalSupply + 1, "HtcNftSeries2: Exceeds than total supply");
     
        require(msg.value >= calculatePrice() * mintAmount, "HtcNftSeries2: Mint price is not enough");

        if(_mintStep == 1) { //Founder WL @ 0.05ETH (500)
            _canFounderWLMint(index, merkleProof);
            _safeMint(_msgSender(), 1);
        }
        else { // _mintStep: 2,3
            _safeMint(_msgSender(), mintAmount);
        }

        emit MintItem(_msgSender(), _startTokenId, mintAmount, block.timestamp);
    }

    function withdrawMintFunding(address addr) external isTrusted { //tested
      (bool sent, ) = addr.call{ value: address(this).balance }("");
      require(sent, "Failed to withdraw ETH !");
    }

    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    function _setTokenURI(uint256 tokenId, string memory tokenURI_) internal virtual {
        _tokenURIs[tokenId] = tokenURI_;
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    function _isClaimed(uint256 index) internal virtual returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = _claimedHtcBuyers[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);

        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) internal virtual {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        _claimedHtcBuyers[claimedWordIndex] =
            _claimedHtcBuyers[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function _isMinted(uint256 index) internal virtual returns (bool) {
        uint256 mintedWordIndex = index / 256;
        uint256 mintedBitIndex = index % 256;
        uint256 mintedWord = _mintedFounderWL[mintedWordIndex];
        uint256 mask = (1 << mintedBitIndex);

        return mintedWord & mask == mask;
    }

    function _setMinted(uint256 index) internal virtual {
        uint256 mintedWordIndex = index / 256;
        uint256 mintedBitIndex = index % 256;

        _mintedFounderWL[mintedWordIndex] =
            _mintedFounderWL[mintedWordIndex] |
            (1 << mintedBitIndex);       
    }

    function _canFounderWLMint(uint256 index, bytes32[] memory merkleProof) internal virtual {    
        require(_founderWLSupplyRemain > 0, "HtcNftSeries2: Exceeds than Founder Whitelist supply");
        
        if(_additionFounderWL[_msgSender()]) {
            require(!_mintedAddFounderWL[_msgSender()], "HtcNftSeries2: You've already minted FounderWL NFT");

            // Mark Minted
            _mintedAddFounderWL[_msgSender()] = true;
        }
        else {
            require(merkleProof.length > 0, "HtcNftSeries2: You are not in Founder Whitelist");
            require(!_isMinted(index), "HtcNftSeries2: You've already minted FounderWL NFT");

            uint256 _mintAmount = 1;
            // Verify the merkle proof. 
            bytes32 node = keccak256(abi.encodePacked(index, _msgSender(), _mintAmount));
            require(
                MerkleProof.verify(merkleProof, _whitelistMerkleRoot, node),
                "HtcNftSeries2: Invalid FounderWL mint proof"
            );

            // Mark Minted
            _setMinted(index);
        }

        _founderWLSupplyRemain = _founderWLSupplyRemain - 1;
    }
}