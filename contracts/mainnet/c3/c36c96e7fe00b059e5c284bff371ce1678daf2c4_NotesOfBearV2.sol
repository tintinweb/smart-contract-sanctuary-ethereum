/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

/**
 *Submitted for verification at Etherscan.io on 2022-08-05
 */

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

interface BearX_interface {
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

interface StakeIntreface {
    function stakeOf(address _address)
        external
        view
        returns (uint256[] memory ids);
}

// library Strings {
library StringsUpgradeable {
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

library AddressUpgradeable {
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
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
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
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

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

    function _revert(bytes memory returndata, string memory errorMessage)
        private
        pure
    {
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

abstract contract Initializable {
    uint8 private _initialized;

    bool private _initializing;

    event Initialized(uint8 version);

    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) ||
                (!AddressUpgradeable.isContract(address(this)) &&
                    _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    modifier reinitializer(uint8 version) {
        require(
            !_initializing && _initialized < version,
            "Initializable: contract is already initialized"
        );
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {}

    function __Context_init_unchained() internal onlyInitializing {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    uint256[50] private __gap;
}

interface IERC165Upgradeable {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {}

    function __ERC165_init_unchained() internal onlyInitializing {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    uint256[50] private __gap;
}

interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
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

interface IERC1155Upgradeable is IERC165Upgradeable {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

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

interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    function uri(uint256 id) external view returns (string memory);
}

contract ERC1155Upgradeable is
    Initializable,
    ContextUpgradeable,
    ERC165Upgradeable,
    IERC1155Upgradeable,
    IERC1155MetadataURIUpgradeable
{
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;
    string private postfix;
    mapping(uint256 => bool) public exists;
    mapping(uint256 => address) public minterAddress;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
        postfix = ".json";
    }

    function __ERC1155_init_unchained(string memory uri_)
        internal
        onlyInitializing
    {
        _setURI(uri_);
        postfix = ".json";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // function uri(uint256) public view virtual override returns (string memory) {
    //     return _uri;
    // }
    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            exists[tokenId],
            "ERC1155 Metadata: URI query for nonexistent token"
        );
        return
            bytes(_uri).length > 0
                ? string(abi.encodePacked(_uri, tokenId.toString(), postfix))
                : "";
    }

    function _setPostfix(string memory _ext) internal virtual {
        postfix = _ext;
    }

    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            account != address(0),
            "ERC1155: address zero is not a valid owner"
        );
        return _balances[id][account];
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(
            accounts.length == ids.length,
            "ERC1155: accounts and ids length mismatch"
        );

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        // require(
        //     from == _msgSender() || isApprovedForAll(from, _msgSender()),
        //     "ERC1155: caller is not token owner nor approved"
        // );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(
            fromBalance >= amount,
            "ERC1155: insufficient balance for transfer"
        );
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(
                fromBalance >= amount,
                "ERC1155: insufficient balance for transfer"
            );
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        // _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
        minterAddress[id] = to;
    }

    function _increaseSupply(uint256 tokenId, uint256 amount) internal virtual {
        require(
            exists[tokenId],
            "ERC1155 Metadata: URI query for nonexistent token"
        );
        // require(minterAddress[tokenId] == msg.sender, "Only owner");

        _balances[tokenId][address(this)] += amount;
        emit TransferSingle(
            msg.sender,
            address(0),
            address(this),
            tokenId,
            amount
        );
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
            minterAddress[ids[i]] = to;
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            ids,
            amounts,
            data
        );
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(
                fromBalance >= amount,
                "ERC1155: burn amount exceeds balance"
            );
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155ReceiverUpgradeable(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (
                    response !=
                    IERC1155ReceiverUpgradeable.onERC1155Received.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response !=
                    IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    uint256[47] private __gap;
}

contract NotesOfBearV2 is ERC1155Upgradeable {
    // Variables
    string name_;
    string symbol_;
    address public Owner;
    uint256 public totalSupply;
    bool public pause;
    uint256 public range;
    uint256 public dependent;
    string errMsg;

    BearX_interface public BearXContract;
    StakeIntreface public StakeXContract;

    mapping(uint256 => mapping(uint256 => bool)) public isClaimed;

    // Functions
    function initialize() public initializer {
        __ERC1155_init("https://nft0001.herokuapp.com/notes-of-bears/");
        Owner = msg.sender;
        name_ = "BearX Satchel";
        symbol_ = "BXS";
        range = 3700;
        dependent = 0;
        errMsg = "You need Notes Of Bear V";
        BearXContract = BearX_interface(
            0xE22e1e620dffb03065CD77dB0162249c0c91bf01
        );
        StakeXContract = StakeIntreface(
            0x871770E3e03bFAEFa3597056e540A1A9c9aC7f6b
        );
    }

    function MintNotes(uint256 amount) public onlyOwner checkSale {
        totalSupply++;
        _mint(address(this), totalSupply, amount, "");
        exists[totalSupply] = true;
    }

    function ownerClaim(uint256 CID, uint256 amount) public onlyOwner {
        require(exists[CID] == true, "ERC1155 query for nonexistent token");
        unchecked {
            require(amount <= balanceOf(address(this), CID), "MAX_REACHED");
        }

        _ownerClaim(CID, amount);
    }

    function _ownerClaim(uint256 CID, uint256 amount) internal onlyOwner {
        transferFrom(address(this), msg.sender, CID, amount, "0x");
    }

    function Claim(uint256[] memory c_ids, uint256[] memory h_ids)
        public
        checkSale
    {
        require(dependent == 0 || balanceOf(msg.sender, dependent) > 0, errMsg);
        for (uint256 i; i < c_ids.length; i++) {
            for (uint256 j; j < h_ids.length; j++) {
                _claim(c_ids[i], h_ids[j]);
            }
        }
    }

    function _claim(uint256 CID, uint256 HID) internal checkSale {
        require(exists[CID] == true, "ERC1155 query for nonexistent token");
        unchecked {
            require(
                HID <= range || (HID >= 1000000000000 && HID <= 1000000000006),
                "You can't claim"
            );
        }
        require(isClaimed[CID][HID] == false, "This item is already claimed");
        require(
            BearXContract.ownerOf(HID) == msg.sender,
            "You Don't Own This Item"
        );
        unchecked {
            require(1 <= balanceOf(address(this), CID), "MAX_REACHED");
        }

        transferFrom(address(this), msg.sender, CID, 1, "0x");

        isClaimed[CID][HID] = true;
    }

    function StakeClaim(uint256 CID, address _address) public {
        require(
            StakeXContract.stakeOf(_address).length > 0,
            "You have not staked any NFT"
        );
        uint256[] memory idList = StakeXContract.stakeOf(_address);

        for (uint256 i = 0; i < idList.length; i++) {
            _stakeClaim(CID, idList[i]);
        }
    }

    function _stakeClaim(uint256 CID, uint256 HID) internal checkSale {
        require(exists[CID] == true, "ERC1155 query for nonexistent token");
        // unchecked {
        //     require(
        //         HID <= range || (HID >= 1000000000000 && HID <= 1000000000006),
        //         "You can't claim"
        //     );
        // }
        unchecked {
            require(1 <= balanceOf(address(this), CID), "MAX_REACHED");
        }
        if (
            isClaimed[CID][HID] == false &&
            (HID <= range || (HID >= 1000000000000 && HID <= 1000000000006))
        ) {
            transferFrom(address(this), msg.sender, CID, 1, "0x");
            isClaimed[CID][HID] = true;
        }
    }

    /**
     * Here the amount you enter will add in the current balance of the specific token
     * for the minter address (Minter is one who have minted the token)
     * and this is onlyOwner function so call should be minter and owner.
     * 123 + 7 = 130
     **/
    function IncreaseSupply(uint256 tokenId, uint256 amount) public onlyOwner {
        _increaseSupply(tokenId, amount);
    }

    function BurnBatch(uint256[] memory ids, uint256[] memory amounts) public {
        _burnBatch(msg.sender, ids, amounts);
    }

    function PauseSale() public onlyOwner {
        require(!pause, "Sale is already paused.");
        pause = true;
    }

    function UnPauseSale() public onlyOwner {
        require(pause, "Sale is already un-paused.");
        pause = false;
    }

    function updateRange(uint256 __range) public onlyOwner {
        range = __range;
    }

    function setNewBearX(BearX_interface __address) public onlyOwner {
        BearXContract = __address;
    }

    function setNewStakeX(StakeIntreface __address) public onlyOwner {
        StakeXContract = __address;
    }

    function walletOfOwner(uint256[] memory ids)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory balances = new uint256[](ids.length);
        for (uint256 i; i < ids.length; i++) {
            balances[i] = balanceOf(msg.sender, ids[i]);
        }
        return balances;
    }

    function SetURI(string memory uri) public onlyOwner {
        _setURI(uri);
    }

    function setPostfix(string memory _ext) public onlyOwner {
        _setPostfix(_ext);
    }

    function SetDependent(uint256 num) public onlyOwner {
        dependent = num;
    }

    function SetErrMsg(string memory eMsg) public onlyOwner {
        errMsg = eMsg;
    }

    function transferOwnership(address _address) public onlyOwner {
        Owner = _address;
    }

    function name() public view returns (string memory) {
        return name_;
    }

    function symbol() public view returns (string memory) {
        return symbol_;
    }

    // Modifiers
    modifier checkSale() {
        require(!pause, "Sale is paused.");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == Owner, "Only Owner access");
        _;
    }
}