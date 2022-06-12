/**
 *Submitted for verification at Etherscan.io on 2022-06-11
*/

// SPDX-License-Identifier: MIT

//  ▄▄▄▄▄▄  ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄ 
// █      ██       █       █       █       █   █       █       █
// █  ▄    █   ▄   █   ▄   █   ▄▄▄▄█   ▄▄▄▄█   █    ▄▄▄█  ▄▄▄▄▄█
// █ █ █   █  █ █  █  █ █  █  █  ▄▄█  █  ▄▄█   █   █▄▄▄█ █▄▄▄▄▄ 
// █ █▄█   █  █▄█  █  █▄█  █  █ █  █  █ █  █   █    ▄▄▄█▄▄▄▄▄  █
// █       █       █       █  █▄▄█ █  █▄▄█ █   █   █▄▄▄ ▄▄▄▄▄█ █
// █▄▄▄▄▄▄██▄▄▄▄▄▄▄█▄▄▄▄▄▄▄█▄▄▄▄▄▄▄█▄▄▄▄▄▄▄█▄▄▄█▄▄▄▄▄▄▄█▄▄▄▄▄▄▄█
//
//  ▄▄   ▄▄ ▄▄▄▄▄▄ ▄▄▄▄▄▄  ▄▄▄▄▄▄▄    ▄     ▄ ▄▄▄ ▄▄▄▄▄▄▄ ▄▄   ▄▄ 
// █  █▄█  █      █      ██       █  █ █ ▄ █ █   █       █  █ █  █
// █       █  ▄   █  ▄    █    ▄▄▄█  █ ██ ██ █   █▄     ▄█  █▄█  █
// █       █ █▄█  █ █ █   █   █▄▄▄   █       █   █ █   █ █       █
// █       █      █ █▄█   █    ▄▄▄█  █       █   █ █   █ █   ▄   █
// █ ██▄██ █  ▄   █       █   █▄▄▄   █   ▄   █   █ █   █ █  █ █  █
// █▄█   █▄█▄█ █▄▄█▄▄▄▄▄▄██▄▄▄▄▄▄▄█  █▄▄█ █▄▄█▄▄▄█ █▄▄▄█ █▄▄█ █▄▄█
//
//  ▄▄▄     ▄▄▄▄▄▄▄ ▄▄   ▄▄ ▄▄▄▄▄▄▄ 
// █   █   █       █  █ █  █       █
// █   █   █   ▄   █  █▄█  █    ▄▄▄█
// █   █   █  █ █  █       █   █▄▄▄ 
// █   █▄▄▄█  █▄█  █       █    ▄▄▄█
// █       █       ██     ██   █▄▄▄ 
// █▄▄▄▄▄▄▄█▄▄▄▄▄▄▄█ █▄▄▄█ █▄▄▄▄▄▄▄█
//

pragma solidity 0.8.10;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC1155Receiver is IERC165 {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC1155 is IERC165 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

library Strings {
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
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;
    IERC1155 internal dooggies;
    bool internal _isMintedOut = false;

    string private _name;

    string private _symbol;

    mapping(uint256 => address) internal _owners;
    mapping(address => uint256) internal _balances;
    mapping(uint => uint) internal idStakeLockTimes;
    mapping(uint => bool) internal OGDooggiesMintedNewNew;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_, address dooggiesContract) {
        _name = name_;
        _symbol = symbol_;
        dooggies = IERC1155(dooggiesContract);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) external view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        if(_isMintedOut == false && idStakeLockTimes[tokenId] != 0 && OGDooggiesMintedNewNew[tokenId] == false) {
            return address(this);
        }
        return owner;
    }

    function name() external view virtual override returns (string memory) {
        return _name;
    }

    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) external virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) external virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender || owner == address(this));
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        if(_isMintedOut == false) {
            require(idStakeLockTimes[tokenId] == 0 || OGDooggiesMintedNewNew[tokenId], "NFT Cant currently be sent cause its staked");
        }
        require(ERC721.ownerOf(tokenId) == from || from == address(this), "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
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

contract ERC721A is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
    }

    uint256 internal _currentIndex;
    string private _name;
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    function _startTokenId() internal view virtual returns (uint256) {
        return 1;
    }

    function totalSupply() public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
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

    function balanceOf(address owner) external view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr && curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
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
        revert OwnerQueryForNonexistentToken();
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
    }

    function name() external view virtual override returns (string memory) {
        return _name;
    }

    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    function approve(address to, uint256 tokenId) external override {
        address owner = ERC721A.ownerOf(tokenId);
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

    function setApprovalForAll(address operator, bool approved) external virtual override {
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
    ) external virtual override {
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
        return _startTokenId() <= tokenId && tokenId < _currentIndex;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }

    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (safe && to.isContract()) {
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

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
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

        emit Transfer(from, to, tokenId);
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
}

contract DooggiesSnack is ERC721A, Ownable {
    address private devOwner;
    address private whoCanMint;
    bool internal _revealed = false;
    bool internal mintEnabled = true;

    string private baseURIForNewNew = "ipfs://QmUtKHbiThL5FikUuUgvLrH7HdNzQ9KmfUtDsE6o3hUKTp";
    string private baseExt = "";

    constructor(address owner_, address whoCanMint_) ERC721A("DooggiesSnack", "DooggiesSnack") { // not the real name ;)
        devOwner = owner_;
        whoCanMint = whoCanMint_;
    }

    receive() external payable {
        (bool sent, ) = payable(owner()).call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }

    function mint(uint256 numberOfTokens, address user) external {
        require(mintEnabled, "Cant mint yet");
        require(whoCanMint == msg.sender, "You cant mint");
        require(
            numberOfTokens + totalSupply() <= 5000,
            "Not enough supply"
        );
        _safeMint(user, numberOfTokens);
    }

    function reveal(bool revealed, string calldata _baseURI) external {
        require(msg.sender == devOwner, "You are not the owner");
        _revealed = revealed;
        baseURIForNewNew = _baseURI;
    }

    function setExtension(string calldata _baseExt) external {
        require(msg.sender == devOwner, "You are not the owner");
        baseExt = _baseExt;
    }

    function updateOwner(address owner_) external {
        require(msg.sender == devOwner, "You are not the owner");
        require(owner_ != address(0));
        devOwner = owner_;
    }

    function toggleMint() external {
        require(msg.sender == devOwner, "You are not the owner");
        mintEnabled = !mintEnabled;
    }

    function isMintEnabled() external view returns (bool) {
        return mintEnabled;
    }

    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        override
        returns (string memory)
    {
        if (_revealed) {
            return string(abi.encodePacked(baseURIForNewNew, Strings.toString(tokenId), baseExt));
        } else {
            return string(abi.encodePacked(baseURIForNewNew));
        }
    }
}

contract WrapYourDooggies is ERC721, ReentrancyGuard, IERC721Receiver, IERC1155Receiver, Ownable {
    address private devOwner;
    bool private lockMintForever = false;
    uint private totalAmount = 0;

    uint constant private dayCount = 60 days;
    uint constant private mintOutLock = 365 days;
    uint private whenDidWeDeploy;

    string private baseURIForOGDooggies = "ipfs://QmSRPvb4E4oT8J73QoWGyvdFizWzpMkkSozAnCEMjT5K7G/";
    string private baseExt = "";

    DooggiesSnack dooggiesSnack; // Hmm you curious what this could be if youre a reader of the github???

    constructor(address dooggiesContract) ERC721("Dooggies", "Dooggies", dooggiesContract) {
        devOwner = address(0xf8c45B2375a574BecA18224C47353969C044a9EC);
        dooggiesSnack = new DooggiesSnack(devOwner, address(this));
        whenDidWeDeploy = block.timestamp;
    }

    receive() external payable {
        (bool sent, ) = payable(owner()).call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }

    function wrapMany(uint[] calldata tokenIds) nonReentrant external {
        require(
            dooggies.isApprovedForAll(msg.sender, address(this)),
            "You need approval"
        );
        require(tokenIds.length > 0, "Must have something");

        unchecked {
            uint count = tokenIds.length;
            uint[] memory qty = new uint[](count);
            for(uint i = 0; i < count; i++) {
                qty[i] = 1;
            }

            dooggies.safeBatchTransferFrom(msg.sender, address(this), tokenIds, qty, "");

            for(uint i = 0; i < count; i++) {
                require(address(this) == ownerOf(tokenIds[i]), "Bruh.. we dont own that");
                safeTransferFrom(address(this), msg.sender, tokenIds[i]);
            }
        }
    }

    function unwrapMany(uint[] calldata tokenIds) nonReentrant external {
        require(tokenIds.length > 0, "Must have something");
        unchecked {
            uint count = tokenIds.length;
            uint[] memory qty = new uint[](count);
            for(uint i = 0; i < count; i++) {
                require(msg.sender == ownerOf(tokenIds[i]), "Bruh.. you dont own that");
                safeTransferFrom(msg.sender, address(this), tokenIds[i]);
            }

            for(uint i = 0; i < count; i++) {
                qty[i] = 1;
            }

            dooggies.safeBatchTransferFrom(address(this), msg.sender, tokenIds, qty, "");
        }
    }

    function wrapManyAndStake(uint[] calldata tokenIds) nonReentrant external {
        require(
            dooggies.isApprovedForAll(msg.sender, address(this)),
            "You need approval"
        );
        require(tokenIds.length > 0, "Must have something");
        require(_isMintedOut == false, "Already minted out");

        unchecked {
            uint count = tokenIds.length;
            uint[] memory qty = new uint[](count);
            for(uint i = 0; i < count; i++) {
                qty[i] = 1;
            }

            dooggies.safeBatchTransferFrom(msg.sender, address(this), tokenIds, qty, "");

            for(uint i = 0; i < count; i++) {
                require(idStakeLockTimes[tokenIds[i]] == 0, "This is already staked");
                require(address(this) == ownerOf(tokenIds[i]), "Bruh.. we dont own that");
                require(OGDooggiesMintedNewNew[tokenIds[i]] == false, "Bruh.. this NFT can only stake once");
                _owners[tokenIds[i]] = msg.sender;
                idStakeLockTimes[tokenIds[i]] = block.timestamp;
                // lol so it shows up on Opensea xD
                // since we want to funnel people here on first wrap :)
                // This will put it in the users wallet on opensea but not allow
                // them to sell since they dont own the asset
                emit Transfer(msg.sender, address(this), tokenIds[i]);
            }
        }
    }

    function stakeMany(uint[] calldata tokenIds) nonReentrant external {
        require(tokenIds.length > 0, "Must have something");
        require(_isMintedOut == false, "Already minted out");
        unchecked {
            uint count = tokenIds.length;
            for(uint i = 0; i < count; i++) {
                require(msg.sender == ownerOf(tokenIds[i]), "Bruh.. you dont own that");
                safeTransferFrom(msg.sender, address(this), tokenIds[i]);
            }

            for(uint i = 0; i < count; i++) {
                require(idStakeLockTimes[tokenIds[i]] == 0, "This is already staked");
                require(address(this) == ownerOf(tokenIds[i]), "Bruh.. we dont own that");
                require(OGDooggiesMintedNewNew[tokenIds[i]] == false, "Bruh.. this NFT can only stake once");
                _owners[tokenIds[i]] = msg.sender;
                idStakeLockTimes[tokenIds[i]] = block.timestamp;
            }
        }
    }

    function unStakeMany(uint[] calldata tokenIds) nonReentrant external {
        require(tokenIds.length > 0, "Must have something");
        unchecked {
            uint count = tokenIds.length;

            for(uint i = 0; i < count; i++) {
                require(msg.sender == _owners[tokenIds[i]], "Bruh.. you dont own that");
                require(OGDooggiesMintedNewNew[tokenIds[i]] == false, "Bruh.. this NFT can only stake once");
                require(idStakeLockTimes[tokenIds[i]] != 0, "Bruh.. this is not staked");
                idStakeLockTimes[tokenIds[i]] = 0;
                safeTransferFrom(address(this), msg.sender, tokenIds[i]);
            }
        }
    }

    function zMintNewNew(uint[] calldata tokenIds) nonReentrant external {
        require(_isMintedOut == false, "Already minted out");
        unchecked {
            uint count = tokenIds.length;
            require(count >= 2, "You need at least two dooggies to mint");

            uint amountToMint = 0;
            uint8 localCounter = 0;
            for(uint i = 0; i < count; i++) {
                require(OGDooggiesMintedNewNew[tokenIds[i]] == false, "Bruh.. this NFT can only mint once.");
                require(msg.sender == _owners[tokenIds[i]], "Bruh.. you dont own that");
                if(block.timestamp - idStakeLockTimes[tokenIds[i]] >= dayCount) {
                    OGDooggiesMintedNewNew[tokenIds[i]] = true;
                    localCounter += 1;
                    if(localCounter >= 2) {
                        localCounter = 0;
                        amountToMint += 1;
                    }
                    safeTransferFrom(address(this), msg.sender, tokenIds[i]);
                }
            }
            require(amountToMint > 0, "Need to have some to mint");

            dooggiesSnack.mint(amountToMint, msg.sender);
        }
    }

    function zzMintOutMystery(uint amount) external {
        require(msg.sender == devOwner, "You are not the owner");
        
        // give people time to wrap for the mystery mint. 
        // they will always be able to wrap but not be able to mint out
        require(block.timestamp - whenDidWeDeploy >= mintOutLock);
        
        dooggiesSnack.mint(amount, msg.sender);

        if(dooggiesSnack.totalSupply() > 4999) {
            _isMintedOut = true;
        }
    }

    function zzLockMint() external {
        require(msg.sender == devOwner, "You are not the owner");
        require(lockMintForever == false, "Mint is already locked");
        lockMintForever = true;
    }

    function zzinitialise(uint256[] calldata tokenIds) external {
        require(lockMintForever == false, "You can no longer mint");
        require(msg.sender == devOwner, "You are not the owner");

        uint count = tokenIds.length;
        require(count > 0, "Must have something");
        _balances[address(this)] += count;

        emit Transfer(address(this), address(this), tokenIds[0]);

        unchecked {
            totalAmount += count;
        }

        // update the balances so that on wrapping the contract logic works
        for (uint256 i = 0; i < count; i++) {
            require(_owners[tokenIds[i]] == address(0), "You cant mint twice");
            _owners[tokenIds[i]] = address(this);
        }
    }

    function updateOwner(address owner_) external {
        require(msg.sender == devOwner, "You are not the owner");
        require(owner_ != address(0));
        devOwner = owner_;
    }

    function setExtension(string calldata _baseExt) external {
        require(msg.sender == devOwner, "You are not the owner");
        baseExt = _baseExt;
    }

    function onERC721Received(address, address, uint256, bytes calldata) pure external returns(bytes4) {
        return WrapYourDooggies.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) pure external returns (bytes4) {
        return WrapYourDooggies.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) pure external returns (bytes4) {
        return WrapYourDooggies.onERC1155BatchReceived.selector;
    }

    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURIForOGDooggies, Strings.toString(tokenId), baseExt)); 
    }

    function setURIOG(string calldata _baseURI) external {
        require(msg.sender == devOwner, "Step off brah");
        baseURIForOGDooggies = _baseURI;
    }

    function totalSupply() external view returns (uint256) {
        return totalAmount;
    }

    function newnewAddress() external view returns (address) {
        return address(dooggiesSnack);
    }

    function timeLeftForID(uint tokenID) external view returns (uint) {
        if((block.timestamp - idStakeLockTimes[tokenID]) < dayCount) {
            return dayCount - (block.timestamp - idStakeLockTimes[tokenID]);
        } else {
            return 0;
        }
    }

    function hasIDBeenMinted(uint tokenID) external view returns (bool) {
        return OGDooggiesMintedNewNew[tokenID];
    }

    function isStaked(uint tokenID) external view returns (bool) {
        return idStakeLockTimes[tokenID] != 0 && OGDooggiesMintedNewNew[tokenID] == false;
    }

    function isMintLocked() external view returns (bool) {
        return lockMintForever;
    }
}