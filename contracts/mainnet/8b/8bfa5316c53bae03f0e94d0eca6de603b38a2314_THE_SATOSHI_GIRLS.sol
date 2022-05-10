/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

pragma solidity 0.8.7;

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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
            if (returndata.length > 0) {
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
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}
interface IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}
interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
}
interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
error URIQueryForNonexistentToken();
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using Address for address;
    using Strings for uint256;

    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
    }

    struct AddressData {
        uint128 balance;
        uint128 numberMinted;
    }

    uint256 internal _currentIndex;
    string private _name;
    string private _symbol;
    mapping(uint256 => TokenOwnership) internal _ownerships;
    mapping(address => AddressData) private _addressData;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function totalSupply() public view override returns (uint256) {
        return _currentIndex;
    }
    function tokenByIndex(uint256 index)
        public
        view
        override
        returns (uint256)
    {
        if (index >= totalSupply()) revert TokenIndexOutOfBounds();
        return index;
    }
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        override
        returns (uint256 a)
    {
        if (index >= balanceOf(owner)) revert OwnerIndexOutOfBounds();
        uint256 numMintedSoFar = totalSupply();
        uint256 tokenIdsIdx;
        address currOwnershipAddr;
        unchecked {
            for (uint256 i; i < numMintedSoFar; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }
        assert(false);
    }
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    function _numberMinted(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert MintedQueryForZeroAddress();
        return uint256(_addressData[owner].numberMinted);
    }
    function ownershipOf(uint256 tokenId)
        internal
        view
        returns (TokenOwnership memory)
    {
        if (!_exists(tokenId)) revert OwnerQueryForNonexistentToken();

        unchecked {
            for (uint256 curr = tokenId; curr >= 0; curr--) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (ownership.addr != address(0)) {
                    return ownership;
                }
            }
        }

        revert UnableDetermineTokenOwner();
    }
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return ownershipOf(tokenId).addr;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ""))
                : "";
    }
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender()))
            revert ApprovalCallerNotOwnerNorApproved();

        _approve(to, tokenId, owner);
    }
    function getApproved(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address operator, bool approved)
        public
        override
    {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
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
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, _data))
            revert TransferToNonERC721ReceiverImplementer();
    }
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < _currentIndex;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, "");
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
        unchecked {
            _addressData[to].balance += uint128(quantity);
            _addressData[to].numberMinted += uint128(quantity);
            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);
            uint256 updatedIndex = startTokenId;
            for (uint256 i; i < quantity; i++) {
                emit Transfer(address(0), to, updatedIndex);
                if (
                    safe &&
                    !_checkOnERC721Received(address(0), to, updatedIndex, _data)
                ) {
                    revert TransferToNonERC721ReceiverImplementer();
                }
                updatedIndex++;
            }
            _currentIndex = updatedIndex;
        }

        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);
        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            getApproved(tokenId) == _msgSender() ||
            isApprovedForAll(prevOwnership.addr, _msgSender()));
        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();
        _approve(address(0), tokenId, prevOwnership.addr);
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;
            _ownerships[tokenId].addr = to;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                if (_exists(nextTokenId)) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership
                        .startTimestamp;
                }
            }
        }
        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0)
                    revert TransferToNonERC721ReceiverImplementer();
                else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
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
library MerkleProof {
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }
    function processProof(bytes32[] memory proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b)
        private
        pure
        returns (bytes32 value)
    {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
contract THE_SATOSHI_GIRLS is ERC721A, Ownable {
    using Strings for uint256;

    constructor(string memory baseuri, bytes32 finalPreviousCollectionRootHash, bytes32 finalPreSaleRootHash)
        ERC721A("THE SATOSHI GIRLS", "TSG")
    {
        _baseURI1 = baseuri;
        PreSaleRootHash = finalPreSaleRootHash;
        PreviousCollectionRootHash = finalPreviousCollectionRootHash;
    }

    uint256 public  maxSupply                   = 5000;
    uint256 public  reserved                    = 100;
    
    uint256 public  publicSalePrice             = 0.06 ether;
    uint256 public  preSalePrice                = 0.04 ether;

    uint256 public  preSaleMaxQuantity          = 1500;

    uint256 public  maxPerWallet                = 5;

    bool public     isPreviousCollectionPaused  = true;
    bool public     isPreSalePaused             = true;
    bool public     isPublicSalePaused          = true;
    
    string public   _baseURI1;
    bytes32 private PreSaleRootHash;
    bytes32 private PreviousCollectionRootHash;

    struct userAddress {
        address userAddress;
        uint256 counter;
    }

    mapping(address => userAddress) public _PublicSaleAddresses;
    mapping(address => bool) public _PublicSaleAddressExist;

    mapping(address => userAddress) public _PreSaleAddresses;
    mapping(address => bool) public _PreSaleAddressExist;

    mapping(address => userAddress) public _PreviousCollectionAddresses;
    mapping(address => bool) public _PreviousCollectionAddressExist;

    // Flip Previous Collection, Whitelist And Public Mint Pause Status 
    function flipPreviousCollectionPauseStatus() public onlyOwner {
        isPreviousCollectionPaused = !isPreviousCollectionPaused;
    }
    function flipPreSalePauseStatus() public onlyOwner {
        isPreSalePaused = !isPreSalePaused;
    }
    function flipPublicSalePauseStatus() public onlyOwner {
        isPublicSalePaused = !isPublicSalePaused;
    }

    // setting merkle root hashes
    function setPreSaleRootHash(bytes32 _rootHash) public onlyOwner {
        PreSaleRootHash = _rootHash;
    }
    function setPreviousCollectionRootHash(bytes32 _rootHash) public onlyOwner {
        PreviousCollectionRootHash = _rootHash;
    }

    // Setter And Getter base URI Functions
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _baseURI1 = _newBaseURI;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURI1;
    }

    // Get Public And Whitelist Price
    function getPublicPrice(uint256 _quantity) public view returns (uint256) {
        return _quantity * publicSalePrice;
    }
    function getPreSalePrice(uint256 _quantity) public view returns (uint256) {
        return _quantity * preSalePrice;
    }

    // Reserved, Previous Collection, Pre Sale, Free And Normal Mint Functions
    function mintReservedTokens(uint256 quantity) public onlyOwner {
        require(quantity <= reserved, "All reserve tokens have bene minted");
        reserved -= quantity;
        _safeMint(msg.sender, quantity);
    }
    function PreviousCollectionWhiteListMint(bytes32[] calldata _merkleProof, uint256 chosenAmount, uint256 maxPreviousCollectionMintLimit) public payable {
        if (_PreviousCollectionAddressExist[msg.sender] == false) {
            _PreviousCollectionAddresses[msg.sender] = userAddress({
                userAddress: msg.sender,
                counter: 0
            });
            _PreviousCollectionAddressExist[msg.sender] = true;
        }
        require(isPreviousCollectionPaused == false, "Previous Collection Mint Is Not ACtive Right Now");
        require(chosenAmount > 0, "Number Of Tokens Can Not Be Less Than Or Equal To 0");
        require(_PreviousCollectionAddresses[msg.sender].counter + chosenAmount <= maxPreviousCollectionMintLimit, "Max Previous Collection Mint Limit reached");
        require(totalSupply() + chosenAmount <= maxSupply - reserved, "Presale Limit Reached");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, PreSaleRootHash, leaf), "Invalid Proof");

        _safeMint(msg.sender, chosenAmount);
        _PreviousCollectionAddresses[msg.sender].counter += chosenAmount;
    }
    function whiteListMint(bytes32[] calldata _merkleProof, uint256 chosenAmount) public payable {
        if (_PreSaleAddressExist[msg.sender] == false) {
            _PreSaleAddresses[msg.sender] = userAddress({
                userAddress: msg.sender,
                counter: 0
            });
            _PreSaleAddressExist[msg.sender] = true;
        }
        require(isPreSalePaused == false, "Whitelist Mint Is Not Active Right Now");
        require(chosenAmount > 0, "Number Of Tokens Can Not Be Less Than Or Equal To 0");
        require(_PreSaleAddresses[msg.sender].counter + chosenAmount <= preSaleMaxQuantity, "Quantity Must Be Lesser Than Max Presale Supply");
        require(_PreSaleAddresses[msg.sender].counter + chosenAmount <= maxPerWallet, "Max limit per wallet reached");
        require(totalSupply() + chosenAmount <= maxSupply - reserved, "Presale Limit Reached");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, PreSaleRootHash, leaf), "Invalid Proof");
        require(preSalePrice * chosenAmount == msg.value, "Sent Ether Value Is Incorrect");

        _safeMint(msg.sender, chosenAmount);
        _PreSaleAddresses[msg.sender].counter += chosenAmount;
    }
    function mint(uint256 chosenAmount) public payable {
        if (_PublicSaleAddressExist[msg.sender] == false) {
            _PublicSaleAddresses[msg.sender] = userAddress({
                userAddress: msg.sender,
                counter: 0
            });
            _PublicSaleAddressExist[msg.sender] = true;
        }
        require( isPublicSalePaused == false, "Public Mint Is Not ACtive Right Now" );
        require( chosenAmount > 0,"Number Of Tokens Can Not Be Less Than Or Equal To 0" );
        require(_PreSaleAddresses[msg.sender].counter + chosenAmount <= maxPerWallet, "Max limit per wallet reached");
        require( totalSupply() + chosenAmount <= maxSupply - reserved, "All Tokens Have Been Minted" );
        require( publicSalePrice * chosenAmount == msg.value, "Sent Ether Value Is Incorrect" );
        _safeMint(msg.sender, chosenAmount);
        _PublicSaleAddresses[msg.sender].counter += chosenAmount;
    }
    function freeMint(uint quantity) public payable onlyOwner {
        require(totalSupply() + quantity <= (maxSupply - reserved), "QUANTITY MUST BE LESS THEN MAX SUPPLY");
        for (uint i = 0; i < quantity; i++) {
            _safeMint(msg.sender, quantity);
        }
    }

    // Withdraw function
    function withdraw() public onlyOwner {
        uint totalBalance   = address(this).balance;
        payable(msg.sender).transfer(totalBalance);
    }
}