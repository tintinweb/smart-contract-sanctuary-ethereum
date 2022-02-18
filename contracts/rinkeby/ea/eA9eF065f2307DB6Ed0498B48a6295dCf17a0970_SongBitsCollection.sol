// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

import "./interfaces/IParams.sol";
import "./interfaces/ICollection.sol";
import "./interfaces/IERC721Receiver.sol";

import "./utils/Ownable.sol";
import "./utils/Pausable.sol";

import "./utils/Strings.sol";
import "./utils/Address.sol";

contract SongBitsCollection is Ownable, Pausable, ICollection {
    using Address for address;
    using Strings for uint256;

    mapping(uint256 => Metadata) public metadata;

    string private _name;
    string private _symbol;

    address private _manager;

    uint256 private _totalSupply;

    mapping(uint256 => uint256) private _nftToMetadata;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(uint256 => uint256)) private _bitsBalances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(IParams.CollectionParams memory params, address manager_) {
        _name = params._name;
        _symbol = params._symbol;

        _manager = manager_;

        _transferOwnership(msg.sender);
    }

    modifier onlyTokenOwner(uint256 _tokenId) {
        require(_owners[_tokenId] == msg.sender);
        _;
    }

    modifier onlyOwnerOrManager() {
        require(
            (owner() == _msgSender() || _manager == _msgSender()),
            "Ownable: caller is not the owner"
        );
        _;
    }

    function isOwnerOrManager(address _address) internal view returns (bool) {
        if (owner() == _address || _manager == _address) {
            return true;
        }

        return false;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC721).interfaceId;
    }

    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "SongBitsCollection: balance query for the zero address"
        );
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "SongBitsCollection: owner query for nonexistent token"
        );
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function getMetadata(uint256 tokenId)
        public
        view
        override
        returns (Metadata memory)
    {
        return metadata[tokenId];
    }

    function setManager(address manager_) public onlyOwnerOrManager {
        _manager = manager_;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return metadata[_nftToMetadata[tokenId]].uri;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = SongBitsCollection.ownerOf(tokenId);
        require(to != owner, "SongBitsCollection: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "SongBitsCollection: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "SongBitsCollection: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
        onlyOwner
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function setCost(uint256 _cost, uint256 _tokenId)
        public
        onlyTokenOwner(_tokenId)
    {
        metadata[_tokenId].cost = _cost;
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
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "SongBitsCollection: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "SongBitsCollection: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    function preMint(
        address artist,
        uint256 _id,
        uint256 _duration,
        uint256 _cost,
        string memory uri
    ) public onlyOwnerOrManager {
        createMetadata(artist, _id, _duration, _duration, _cost, uri);
    }

    function preMintBatch(
        address artist,
        uint256[] memory _ids,
        uint256[] memory _durations,
        uint256[] memory _costs,
        string[] memory uris_
    ) public onlyOwnerOrManager {
        for (uint256 i = 0; i < _durations.length; i++) {
            createMetadata(
                artist,
                _ids[i],
                _durations[i],
                _durations[i],
                _costs[i],
                uris_[i]
            );
        }
    }

    function mint(
        uint256 _metadataId,
        address _to,
        uint256 bits
    ) public override onlyOwnerOrManager {
        uint256 _id = totalSupply() + 1;
        _safeMint(_to, _id, "");
        _bitsBalances[_to][_metadataId] = bits;
        metadata[_metadataId].totalBought += bits;
        _nftToMetadata[_id] = _metadataId;
    }

    function mintBatch(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _bits
    ) public onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            mint(_ids[i], _to, _bits[i]);
        }
    }

    function createMetadata(
        address artist,
        uint256 tokenId,
        uint256 duration,
        uint256 parentId,
        uint256 cost,
        string memory uri
    ) public override onlyOwnerOrManager {
        metadata[tokenId] = Metadata(
            artist,
            address(0),
            duration,
            parentId,
            0,
            cost,
            uri
        );
    }

    function calculatePartCost(uint256 _tokenId, uint256 _bits)
        public
        view
        returns (uint256 partCost)
    {
        Metadata memory _metadata = getMetadata(_tokenId);

        partCost = (_bits * _metadata.duration) / _metadata.cost;
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "SongBitsCollection: transfer to non ERC721Receiver implementer"
        );
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "SongBitsCollection: operator query for nonexistent token"
        );
        address owner = SongBitsCollection.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "SongBitsCollection: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(
            to != address(0),
            "SongBitsCollection: mint to the zero address"
        );
        require(!_exists(tokenId), "SongBitsCollection: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;
        _totalSupply += 1;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual onlyOwner whenNotPaused {
        address owner = SongBitsCollection.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];
        _totalSupply -= 1;

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual whenNotPaused {
        require(
            SongBitsCollection.ownerOf(tokenId) == from,
            "SongBitsCollection: transfer of token that is not own"
        );
        require(
            to != address(0),
            "SongBitsCollection: transfer to the zero address"
        );

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(SongBitsCollection.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "SongBitsCollection: approve to caller");
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
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "SongBitsCollection: transfer to non ERC721Receiver implementer"
                    );
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

interface IParams {
    struct CollectionParams {
        string _name;
        string _symbol;
    }

    struct Fees {
        uint256 _singbitFeePercent;
        uint256 _artistResaleFeePrecent;
        uint256 _artistPrimaryFeePrecent;
        uint256 _fanFeePercent;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

import "./IERC721.sol";
import "./IMetadata.sol";

interface ICollection is IERC721, IMetadata {
    event Mint(address _to, uint256 _duration, uint256 _cost, string uri);

    function totalSupply() external view returns (uint256);

    function getMetadata(uint256 tokenId)
        external
        view
        returns (Metadata memory);

    function mint(
        uint256 _id,
        address _to,
        uint256 bits
    ) external;

    function createMetadata(
        address artist,
        uint256 tokenId,
        uint256 duration,
        uint256 parentId,
        uint256 cost,
        string memory uri
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

import "./Context.sol";

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

import "./Context.sol";

abstract contract Pausable is Context {
    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

import "./IERC165.sol";

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

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

interface IMetadata {
    struct Metadata {
        address artist;
        address owner;
        uint256 duration;
        uint256 parentId;
        uint256 totalBought;
        uint256 cost;
        string uri;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}