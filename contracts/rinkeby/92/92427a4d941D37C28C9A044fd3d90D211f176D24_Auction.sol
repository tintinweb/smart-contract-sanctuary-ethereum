/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

pragma solidity >=0.8.9;


interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

interface IERC1155MetadataURI is IERC1155 {

    function uri(uint256 id) external view returns (string memory);
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;


    mapping(uint256 => mapping(address => uint256)) private _balances;


    mapping(address => mapping(address => bool)) private _operatorApprovals;


    string private _uri;


    constructor(string memory uri_) {
        _setURI(uri_);
    }


    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }


    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }


    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }


    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }


    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }


    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }


    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }


    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
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

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }


    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }


    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }


    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }


    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }


    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }


    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }


    function _beforeTokenTransfer(
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
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
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
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
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
        uint256 tokenId
    ) external;


    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;


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

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721Metadata is IERC721 {

    function name() external view returns (string memory);


    function symbol() external view returns (string memory);


    function tokenURI(uint256 tokenId) external view returns (string memory);
}

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

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;


    string private _name;


    string private _symbol;


    mapping(uint256 => address) private _owners;


    mapping(address => uint256) private _balances;


    mapping(uint256 => address) private _tokenApprovals;


    mapping(address => mapping(address => bool)) private _operatorApprovals;


    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }


    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }


    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }


    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }


    function name() public view virtual override returns (string memory) {
        return _name;
    }


    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }


    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }


    function approve(address to, uint256 tokenId) public virtual override {
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


    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

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
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }


    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }


    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);


        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }


    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);


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


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);


    function symbol() external view returns (string memory);


    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;


    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }


    function name() public view virtual override returns (string memory) {
        return _name;
    }


    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }


    function decimals() public view virtual override returns (uint8) {
        return 18;
    }


    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }


    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }


    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }


    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }


    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }


    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}


    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor() {
        _setOwner(_msgSender());
    }


    function owner() public view virtual returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface VariablesTypes {
    enum lotType {
        None,
        FixedPrice,
        Auction,
        Exchange
    }

    struct collectionInfo{
        uint256 commission;
        address owner;
    }

    struct lotInfo {
        lotStart creationInfo;
        lotType selling;
        uint256 sellStart;
        currency price;
        auctionInfo auction;
        bool offered;
        bool isERC1155;
        bool openForOffers;
    }

    struct lotStart {
        address owner;
        address contractAddress;
        uint256 id;
        uint256 amount;
        uint256 Added;
    }

    struct auctionInfo {
        uint256 startAuction;
        uint256 endAuction;
        uint256 step;
        uint256 nextStep;
        address lastBid;
    }

    struct currency {
        address contractAddress;
        uint256 sellerPrice;
        uint256 buyerPrice;
    }

    struct offer {
        address owner;
        uint256 lotID;
        uint256[] lotsOffer;
        currency price;
    }

    struct returnInfo {
        address user;
        uint256 amount;
    }
}

contract NFTMarketplace is Ownable, VariablesTypes {
    uint256 public marketCommission;
    uint256 public offerCommission;

    address public marketWallet;
    Auction auctionContract;

    lotInfo[] public lots;
    offer[] public offers;

    mapping(address => uint256[]) public lotOwner;
    mapping(address => uint256[]) public offerOwner;
    mapping(uint256 => uint256[]) public lotOffers;
    mapping(address => bool) public NFT_Collections;
    mapping(address => mapping(address => bool)) public NFT_ERC20_Supports;
    mapping(address => collectionInfo) public collections;

    event AddNFT(
        address user,
        address contractAddress,
        uint256 NFT_ID,
        uint256 lotID,
        uint256 datetime,
        uint256 amount,
        uint256 typeOfLot
    );
    event SellNFT(
        address indexed user,
        uint256 indexed lotID,
        uint256 indexed startDate,
        uint256 amount,
        uint256 price,
        address tokenAddress,
        bool openForOffer
    );
    event BuyNFT(
        address indexed user,
        uint256 indexed lotID,
        uint256 indexed datetime,
        uint256 amount
    );
    event GetBack(
        uint256 indexed lotID,
        uint256 indexed datetime,
        uint256 amount
    );
    event MakeOffer(
        address indexed user,
        uint256 indexed lotID,
        uint256 indexed offerID,
        address tokenAddress,
        uint256 tokenAmount,
        uint256[] itemLotIds,
        uint256 tokenValue
    );
    event ChoosedOffer(
        uint256 indexed lotID,
        uint256 indexed offerID,
        uint256 indexed datetime
    );
    event RevertedOffer(
        uint256 indexed lotID,
        uint256 indexed offerID,
        uint256 indexed datetime
    );
    event ExchangeNFT(
        uint256 indexed startDate,
        uint256 indexed lotID,
        address indexed owner,
        uint256 amount
    );

    modifier checkContract(address contractAddress) {
        require(Address.isContract(contractAddress), "1");
        _;
    }

    constructor(
        uint256 commission,
        uint256 commissionOffer,
        address wallet
    ) {
        setMarketCommission(commission);
        setOfferCommission(commissionOffer);
        setWallet(wallet);
    }

    function setAuctionContract(address contractAddress) external onlyOwner {
        auctionContract = Auction(contractAddress);
    }

    function setCollectionCommission(address contractNFT, uint256 commission)
        external
        onlyOwner
    {
        require(NFT_Collections[contractNFT] == true && collections[contractNFT].owner != address(0x0), "2");
        collections[contractNFT].commission = commission;
    }

    function setCollectionOwner(address contractAddress, address owner)
        external
        onlyOwner
    {
        require(
            NFT_Collections[contractAddress] == true && owner != address(0x0),
            "2"
        );
        collections[contractAddress].owner = owner;
    }

    function auctionLot(uint256 lotID, VariablesTypes.lotInfo memory lot)
        external
    {
        require(
            msg.sender == address(auctionContract),
            "3"
        );
        lots[lotID] = lot;
    }


    function setMarketCommission(uint256 commission) public onlyOwner {
        require(commission <= 1000, "4");
        marketCommission = commission;
    }


    function setOfferCommission(uint256 comission) public onlyOwner {
        offerCommission = comission;
    }

    function calculateCommission(uint256 price, address collectionCommission)
        internal
        view
        returns (uint256)
    {
        return
            price -
            (price *
                (collections[collectionCommission].commission +
                    marketCommission)) /
            1000;
    }


    function setWallet(address newWallet) public onlyOwner {
        require(
            newWallet != address(0x0) && newWallet != marketWallet,
            "5"
        );
        marketWallet = newWallet;
    }


    function setNFT_Collection(address contractAddress, bool canTransfer)
        external
        onlyOwner
        checkContract(contractAddress)
    {
        NFT_Collections[contractAddress] = canTransfer;
        ERC1155(contractAddress).setApprovalForAll(
            address(auctionContract),
            true
        );
    }


    function setERC20_Support(
        address NFT_Address,
        address[] memory ERC20_Address,
        bool[] memory canTransfer
    ) external onlyOwner checkContract(NFT_Address) {
        for (uint256 i = 0; i < ERC20_Address.length; i++) {
            require(Address.isContract(ERC20_Address[i]), "1");
            ERC20(ERC20_Address[i]).name();
            ERC20(ERC20_Address[i]).symbol();
            NFT_ERC20_Supports[NFT_Address][ERC20_Address[i]] = canTransfer[i];
        }
    }

    function sendNFT(
        address contractAddress,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data,
        bool isERC1155
    ) internal {
        if (isERC1155 == true) {
            ERC1155 NFT_Contract = ERC1155(contractAddress);
            NFT_Contract.safeTransferFrom(from, to, id, value, data);
        } else {
            ERC721 NFT_Contract = ERC721(contractAddress);
            NFT_Contract.safeTransferFrom(from, to, id, data);
        }
    }

    function calculateMarket(uint256 price, uint256 commission)
        internal
        pure
        returns (uint256)
    {
        return (price * commission) / 1000;
    }

    function sendCrypto(
        lotInfo memory lot,
        uint256 sellerPrice,
        uint256 buyerPrice
    ) internal {
        payable(lot.creationInfo.owner).transfer(sellerPrice);
        if (marketCommission > 0) {
            payable(marketWallet).transfer(
                calculateMarket(buyerPrice, marketCommission)
            );
        }
        if (collections[lot.creationInfo.contractAddress].commission > 0) {
            payable(collections[lot.creationInfo.contractAddress].owner)
                .transfer(
                    calculateMarket(
                        buyerPrice,
                        collections[lot.creationInfo.contractAddress].commission
                    )
                );
        }
    }

    function sendERC20(
        address contractAddress,
        address from,
        address to,
        uint256 amount
    ) internal {
        ERC20 tokenContract = ERC20(contractAddress);
        tokenContract.transferFrom(from, to, amount);
    }

    function getNextStep(uint256 lotID) external view returns (uint256) {
        return lots[lotID].auction.nextStep;
    }


    function add(
        address contractAddress,
        uint256 id,
        uint256 value,
        bool isERC1155,
        lotType typeOfLot,
        bytes memory data
    ) public {
        require(value > 0 && contractAddress != address(0x0), "6");
        if(ERC1155(contractAddress).isApprovedForAll(contractAddress, address(auctionContract))){
            ERC1155(contractAddress).setApprovalForAll(
                address(auctionContract),
                true
            );
        }
        if (isERC1155 == true) {
            sendNFT(
                contractAddress,
                msg.sender,
                address(this),
                id,
                value,
                data,
                isERC1155
            );
            lots.push(
                lotInfo(
                    lotStart(
                        msg.sender,
                        contractAddress,
                        id,
                        value,
                        block.timestamp
                    ),
                    lotType.None,
                    0,
                    currency(address(0x0), 0, 0),
                    auctionInfo(0, 0, 0, 0, address(0x0)),
                    false,
                    isERC1155,
                    false
                )
            );
            emit AddNFT(
                msg.sender,
                contractAddress,
                id,
                lots.length - 1,
                block.timestamp,
                value,
                uint256(typeOfLot)
            );
        } else {
            sendNFT(
                contractAddress,
                msg.sender,
                address(this),
                id,
                value,
                data,
                isERC1155
            );
            lots.push(
                lotInfo(
                    lotStart(
                        msg.sender,
                        contractAddress,
                        id,
                        1,
                        block.timestamp
                    ),
                    lotType.None,
                    0,
                    currency(address(0x0), 0, 0),
                    auctionInfo(0, 0, 0, 0, address(0x0)),
                    false,
                    isERC1155,
                    false
                )
            );
            emit AddNFT(
                msg.sender,
                contractAddress,
                id,
                lots.length - 1,
                block.timestamp,
                1,
                uint256(typeOfLot)
            );
        }
        lotOwner[msg.sender].push(lots.length - 1);
    }


    function NFT_Sale(
        address contractAddress,
        uint256 id,
        uint256 value,
        bool isERC1155,
        uint256 startDate,
        address tokenAddress,
        uint256 price,
        bool openForOffers,
        bytes memory data
    ) external {
        add(contractAddress, id, value, isERC1155, lotType.FixedPrice, data);
        uint256 lotID = lots.length - 1;
        sell(lotID, tokenAddress, price, openForOffers, startDate);
    }


    function NFT_Offer(
        address[] memory contractAddress,
        uint256[] memory id,
        uint256[] memory value,
        bool[] memory isERC1155,
        uint256 lot,
        address tokenAddress,
        uint256 amount,
        bytes memory data
    ) external payable {
        uint256[] memory lotIDs = new uint256[](contractAddress.length);
        for (uint256 i = 0; i < contractAddress.length; i++) {
            add(
                contractAddress[i],
                id[i],
                value[i],
                isERC1155[i],
                lotType.Exchange,
                data
            );
            lotIDs[i] = lots.length - 1;
        }
        makeOffer(lot, lotIDs, tokenAddress, amount);
    }

    function exchangeSell(uint256 index, uint256 date, lotType lot, bool openToOffer) internal {
            lots[index].sellStart = date;
            lots[index].selling = lot;
            lots[index].openForOffers = openToOffer;
    }


    function sell(
        uint256 index,
        address contractAddress,
        uint256 price,
        bool openForOffers,
        uint256 date
    ) public {
        require(
            lots[index].creationInfo.owner == msg.sender &&
                lots[index].offered == false &&
                lots[index].selling == lotType.None,
            "7"
        );
        require(
            NFT_ERC20_Supports[lots[index].creationInfo.contractAddress][
                contractAddress
            ] ==
                true ||
                contractAddress == address(0x0),
            "8"
        );

        if(date < block.timestamp){
            date = block.timestamp;
        }

        require(date - block.timestamp <= 2692000, "18");

        if (price == 0) {
            exchangeSell(index, date, lotType.Exchange, true);
            emit ExchangeNFT(
                date,
                index,
                msg.sender,
                lots[index].creationInfo.amount
            );
        } else {
            lots[index].price.sellerPrice = calculateCommission(
                price,
                lots[index].creationInfo.contractAddress
            );
            exchangeSell(index, date, lotType.FixedPrice, openForOffers);
            lots[index].price.buyerPrice = price;
            lots[index].price.contractAddress = contractAddress;
            emit SellNFT(
                msg.sender,
                index,
                date,
                lots[index].creationInfo.amount,
                price,
                contractAddress,
                openForOffers
            );
        }
    }

    function getBack(uint256 index, bytes memory data) external {
        returnNFT(index, data);
    }


    function returnNFT(uint256 index, bytes memory data) internal {
        lotInfo memory lot = lots[index];
        require(lot.creationInfo.owner == msg.sender && lot.selling != lotType.Auction, "9");
        delete lots[index];
        sendNFT(
            lot.creationInfo.contractAddress,
            address(this),
            lot.creationInfo.owner,
            lot.creationInfo.id,
            lot.creationInfo.amount,
            data,
            lot.isERC1155
        );
        emit GetBack(
            index,
            block.timestamp,
            lots[index].creationInfo.amount
        );
    }


    function buy(uint256 index, bytes memory data) external payable {
        lotInfo memory lot = lots[index];
        require(
            lot.selling == lotType.FixedPrice &&
                lot.sellStart <= block.timestamp,
            "10"
        );
        delete lots[index];
        if (lot.price.contractAddress == address(0)) {

            require(msg.value == lot.price.buyerPrice, "11");
            sendCrypto(lot, lot.price.sellerPrice, lot.price.buyerPrice);
        } else {

            ERC20 tokenContract = ERC20(lot.price.contractAddress);
            tokenContract.transferFrom(
                msg.sender,
                lot.creationInfo.owner,
                lot.price.sellerPrice
            );
            if (marketCommission > 0) {
                tokenContract.transferFrom(
                    msg.sender,
                    marketWallet,
                    calculateMarket(lot.price.buyerPrice, marketCommission)
                );
            }
            if (collections[lot.creationInfo.contractAddress].commission > 0) {
                tokenContract.transferFrom(
                    msg.sender,
                    collections[lot.creationInfo.contractAddress].owner,
                    calculateMarket(
                        lot.price.buyerPrice,
                        collections[lot.creationInfo.contractAddress].commission
                    )
                );
            }
        }
        sendNFT(
            lot.creationInfo.contractAddress,
            address(this),
            msg.sender,
            lot.creationInfo.id,
            lot.creationInfo.amount,
            data,
            lot.isERC1155
        );
        emit BuyNFT(
            msg.sender,
            index,
            block.timestamp,
            lots[index].creationInfo.amount
        );
    }


    function makeOffer(
        uint256 index,
        uint256[] memory lotIndex,
        address tokenAddress,
        uint256 amount
    ) public payable {
        uint256 cryptoValue = msg.value;

        require(
            lots[index].creationInfo.contractAddress != address(0x0) &&
            lots[index].selling != lotType.None &&
            lots[index].selling != lotType.Auction &&
            lots[index].openForOffers == true,
            "12"
        );
        require(
            NFT_ERC20_Supports[lots[index].creationInfo.contractAddress][
            tokenAddress
            ] ==
            true ||
            tokenAddress == address(0x0),
            "8"
        );
        if (amount > 0) {
            if (lotIndex.length == 0) {

                require(
                    amount > 0 && msg.value == 0,
                    "13"
                );
                sendERC20(tokenAddress, msg.sender, address(this), amount);
                offers.push(
                    offer(
                        msg.sender,
                        index,
                        lotIndex,
                        currency(
                            tokenAddress,
                            calculateCommission(
                                amount,
                                lots[index].creationInfo.contractAddress
                            ),
                            amount
                        )
                    )
                );
            } else {
                for (uint256 i = 0; i < lotIndex.length; i++) {
                    require(
                        lots[lotIndex[i]].creationInfo.owner == msg.sender &&
                        lotIndex[i] != index &&
                        lots[lotIndex[i]].offered == false,
                        "14"
                    );
                    lots[lotIndex[i]].offered = true;
                }
                if (tokenAddress != address(0)) {

                    require(
                        amount > 0 && msg.value == offerCommission,
                        "15"
                    );
                    sendERC20(tokenAddress, msg.sender, address(this), amount);
                    offers.push(
                        offer(
                            msg.sender,
                            index,
                            lotIndex,
                            currency(
                                tokenAddress,
                                calculateCommission(
                                    amount,
                                    lots[index].creationInfo.contractAddress
                                ),
                                amount
                            )
                        )
                    );
                }
            }
        } else {
            require(
                tokenAddress == address(0x0),
                "17"
            );
            if(lotIndex.length != 0) {
                for (uint256 i = 0; i < lotIndex.length; i++) {
                    require(
                        lots[lotIndex[i]].creationInfo.owner == msg.sender &&
                        lotIndex[i] != index &&
                        lots[lotIndex[i]].offered == false,
                        "14"
                    );
                    lots[lotIndex[i]].offered = true;
                }

                if(msg.value == offerCommission) {

                    cryptoValue = msg.value - offerCommission;
                    offers.push(
                        offer(
                            msg.sender,
                            index,
                            lotIndex,
                            currency(address(0), 0, 0)
                        )
                    );
                } else {

                    cryptoValue = msg.value - offerCommission;
                    offers.push(
                        offer(
                            msg.sender,
                            index,
                            lotIndex,
                            currency(
                                address(0),
                                calculateCommission(
                                    msg.value - offerCommission,
                                    lots[index].creationInfo.contractAddress
                                ),
                                msg.value
                            )
                        )
                    );
                }
            }else {

                offers.push(
                    offer(
                        msg.sender,
                        index,
                        lotIndex,
                        currency(
                            address(0),
                            calculateCommission(
                                msg.value,
                                lots[index].creationInfo.contractAddress
                            ),
                            msg.value
                        )
                    )
                );
            }
        }
        offerOwner[msg.sender].push(offers.length - 1);
        lotOffers[index].push(offers.length - 1);
        emit MakeOffer(
            msg.sender,
            index,
            offers.length - 1,
            tokenAddress,
            amount,
            lotIndex,
            cryptoValue);
    }


    function cancelOffer(uint256 index) external {
        require(
            offers[index].owner == msg.sender,
            "9"
        );
        offer memory localOffer = offers[index];
        delete offers[index];
        if (localOffer.price.contractAddress == address(0)) {
            if (localOffer.price.buyerPrice == 0) {
                payable(localOffer.owner).transfer(offerCommission);
            } else {
                payable(localOffer.owner).transfer(localOffer.price.buyerPrice);
            }
        } else {
            payable(localOffer.owner).transfer(offerCommission);
            ERC20 tokenContract = ERC20(localOffer.price.contractAddress);
            tokenContract.transfer(
                localOffer.owner,
                localOffer.price.buyerPrice
            );
        }
        if (localOffer.lotsOffer.length != 0) {
            for (uint256 i = 0; i < localOffer.lotsOffer.length; i++) {
                returnNFT(localOffer.lotsOffer[i], "");
            }
        }
        emit RevertedOffer(localOffer.lotID, index, block.timestamp);
    }


    function chooseOffer(
        uint256 lotID,
        uint256 offerID,
        bytes memory data
    ) external {
        require(
            lots[lotID].creationInfo.owner == msg.sender &&
                offers[offerID].lotID == lotID,
            "9"
        );
        lotInfo memory lot = lots[lotID];
        delete lots[lotID];
        sendNFT(
            lot.creationInfo.contractAddress,
            address(this),
            offers[offerID].owner,
            lot.creationInfo.id,
            lot.creationInfo.amount,
            data,
            lot.isERC1155
        );
        offer memory userOffer = offers[offerID];
        delete offers[offerID];
        if (userOffer.lotsOffer.length != 0) {

            for (uint256 i = 0; i < userOffer.lotsOffer.length; i++) {
                lotInfo memory offerLot = lots[userOffer.lotsOffer[i]];
                delete lots[userOffer.lotsOffer[i]];
                sendNFT(
                    offerLot.creationInfo.contractAddress,
                    address(this),
                    lot.creationInfo.owner,
                    offerLot.creationInfo.id,
                    offerLot.creationInfo.amount,
                    data,
                    offerLot.isERC1155
                );
            }
        }
        if (userOffer.price.contractAddress == address(0)) {

            if (userOffer.price.sellerPrice != 0) {
                sendCrypto(
                    lot,
                    userOffer.price.sellerPrice,
                    userOffer.price.buyerPrice
                );
            } else {
                payable(marketWallet).transfer(offerCommission);
            }
        } else {

            ERC20 tokenContract = ERC20(userOffer.price.contractAddress);
            tokenContract.transfer(
                lot.creationInfo.owner,
                userOffer.price.sellerPrice
            );
            if (marketCommission > 0) {
                tokenContract.transfer(
                    marketWallet,
                    calculateMarket(
                        userOffer.price.buyerPrice,
                        marketCommission
                    )
                );
            }
            if (collections[lot.creationInfo.contractAddress].commission > 0) {
                tokenContract.transfer(
                    collections[lot.creationInfo.contractAddress].owner,
                    calculateMarket(
                        userOffer.price.buyerPrice,
                        collections[lot.creationInfo.contractAddress].commission
                    )
                );
            }
        }
        emit ChoosedOffer(lotID, offerID, block.timestamp);
    }

    function getLotsOffers(uint256 indexes)
        external
        view
        returns (uint256[] memory getLot)
    {
        getLot = lotOffers[indexes];
    }

    function getLots(uint256 indexes)
        external
        view
        returns (lotInfo memory getLot)
    {
        getLot = lots[indexes];
    }

    function getLotsLength() external view returns (uint256 length) {
        length = lots.length;
    }


    function getInfo(address user)
        external
        view
        returns (uint256[] memory userLots, uint256[] memory userOffers)
    {
        userLots = lotOwner[user];
        userOffers = offerOwner[user];
    }


    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        require(
            NFT_Collections[msg.sender] == true,
            "2"
        );
        if (operator != address(this)) {
            if (operator == address(auctionContract)) {
                lots.push(
                    lotInfo(
                        lotStart(from, msg.sender, id, value, block.timestamp),
                        lotType.None,
                        0,
                        currency(address(0), 0, 0),
                        auctionInfo(0, 0, 0, 0, address(0)),
                        false,
                        true,
                        false
                    )
                );
                lotOwner[from].push(lots.length - 1);
                emit AddNFT(
                    from,
                    msg.sender,
                    id,
                    lots.length - 1,
                    block.timestamp,
                    value,
                    uint256(lotType.None)
                );
            } else {
                revert("Use our site");
            }
        }
        return 0xf23a6e61;
    }


    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) public virtual returns (bytes4) {
        require(
            NFT_Collections[msg.sender] == true,
            "2"
        );
        if (operator != address(this)) {
            if (operator == address(auctionContract)) {
                lots.push(
                    lotInfo(
                        lotStart(from, msg.sender, id, 1, block.timestamp),
                        lotType.None,
                        0,
                        currency(address(0), 0, 0),
                        auctionInfo(0, 0, 0, 0, address(0)),
                        false,
                        false,
                        false
                    )
                );
                lotOwner[from].push(lots.length - 1);
                emit AddNFT(
                    from,
                    msg.sender,
                    id,
                    lots.length - 1,
                    block.timestamp,
                    1,
                    uint256(lotType.None)
                );
            } else {
                revert("Use our site!");
            }
        }
        return 0x150b7a02;
    }
















}

contract Auction is VariablesTypes {
    NFTMarketplace public marketplace;

    constructor(address market) {
        marketplace = NFTMarketplace(market);
    }

    event AuctionStart(
        uint256 indexed startDate,
        uint256 indexed id,
        address indexed owner,
        uint256 priceInitial,
        uint256 priceStepPercent,
        uint256 deadline,
        address tokenAddress
    );
    event BidMaked(
        uint256 indexed dateTime,
        uint256 indexed lotID,
        address indexed user,
        uint256 amount
    );
    event AuctionEnd(
        uint256 indexed dateTime,
        uint256 indexed lotID,
        uint256 amount,
        bool isCanceled
    );

    function time() external view returns (uint256) {
        return block.timestamp;
    }

    function createAuction(
        address contractAddress,
        uint256 id,
        uint256 value,
        bool isERC1155,
        uint256 startDate,
        uint256 endDate,
        uint256 step,
        address tokenAddress,
        uint256 amount,
        bytes memory data
    ) external {
        if (isERC1155 == true) {
            ERC1155 NFT_Contract = ERC1155(contractAddress);
            NFT_Contract.safeTransferFrom(msg.sender, address(marketplace), id, value, data);
        } else {
            ERC721 NFT_Contract = ERC721(contractAddress);
            NFT_Contract.safeTransferFrom(msg.sender, address(marketplace), id, data);
        }
        uint256 lotID = marketplace.getLotsLength() - 1;
        startAuction(lotID, startDate, endDate, step, tokenAddress, amount);
    }


    function startAuction(
        uint256 lotID,
        uint256 startDate,
        uint256 endDate,
        uint256 step,
        address tokenAddress,
        uint256 amount
    ) public {
        lotInfo memory lot;
        (
            lot.creationInfo,
            lot.selling,
            lot.sellStart,
            lot.price,
            lot.auction,
            lot.offered,
            lot.isERC1155,
            lot.openForOffers
        ) = marketplace.lots(lotID);
        require(
            lot.creationInfo.owner == msg.sender && lot.selling == lotType.None && step <= 1000 && amount > 0,
            "You are not owner or too big a step or start price 0"
        );
        require(
            startDate < endDate,
            "Not correct start or end date"
        );

        if(startDate < block.timestamp){
            startDate = block.timestamp;
        }

        require(startDate - block.timestamp <= 2692000 && endDate - startDate <= 7998000, "18");
        require(
            marketplace.NFT_ERC20_Supports(
                lot.creationInfo.contractAddress,
                tokenAddress
            ) ==
                true ||
                tokenAddress == address(0x0),
            "Not supported ERC20 tokens"
        );
        lot.selling = lotType.Auction;
        lot.auction = auctionInfo(
            startDate,
            endDate,
            step,
            amount,
            address(0x0)
        );
        if (tokenAddress == address(0x0)) {
            lot.price = currency(address(0x0), 0, 0);
        } else {
            lot.price = currency(tokenAddress, 0, 0);
        }
        marketplace.auctionLot(lotID, lot);
        emit AuctionStart(
            startDate,
            lotID,
            msg.sender,
            amount,
            step,
            endDate,
            tokenAddress
        );
    }


    function makeBid(uint256 lotID, uint256 amount) external payable {
        lotInfo memory lot;
        (
            lot.creationInfo,
            lot.selling,
            lot.sellStart,
            lot.price,
            lot.auction,
            lot.offered,
            lot.isERC1155,
            lot.openForOffers
        ) = marketplace.lots(lotID);
        require(
            lot.auction.endAuction > block.timestamp &&
                lot.auction.startAuction <= block.timestamp && lot.selling == lotType.Auction,
            "Lot not on auction"
        );
        if (lot.price.contractAddress == address(0x0)) {
            if (lot.auction.lastBid != msg.sender) {
                require(
                    msg.value >= lot.auction.nextStep,
                    "Not enought payment"
                );
                lot.auction.nextStep =
                    msg.value +
                    (msg.value * lot.auction.step) /
                    1000;
                if (lot.price.sellerPrice != 0) {
                    payable(lot.auction.lastBid).transfer(lot.price.buyerPrice);
                }
                lot.price = currency(
                    address(0x0),
                    msg.value -
                        (msg.value * marketplace.marketCommission()) /
                        1000,
                    msg.value
                );
                lot.auction.lastBid = msg.sender;
            } else {
                uint256 newPrice = lot.price.buyerPrice + msg.value;
                lot.price = currency(
                    address(0x0),
                    newPrice -
                        (newPrice * marketplace.marketCommission()) /
                        1000,
                    newPrice
                );
                lot.auction.nextStep =
                    newPrice +
                    (newPrice * lot.auction.step) /
                    1000;
            }
        } else {
            require(amount > 0, "You send 0 tokens!");
            ERC20 tokenContract = ERC20(lot.price.contractAddress);
            tokenContract.transferFrom(msg.sender, address(this), amount);
            if (lot.auction.lastBid != msg.sender) {
                require(amount >= lot.auction.nextStep, "Not enought payment");
                if (lot.price.sellerPrice != 0) {
                    tokenContract.transfer(
                        lot.auction.lastBid,
                        lot.price.buyerPrice
                    );
                }
                lot.price.buyerPrice = amount;
                lot.price.sellerPrice =
                    amount -
                    (amount * marketplace.marketCommission()) /
                    1000;
                lot.auction.nextStep =
                    amount +
                    (amount * lot.auction.step) /
                    1000;
                lot.auction.lastBid = msg.sender;
            } else {
                uint256 newPrice = lot.price.buyerPrice + amount;
                lot.price.buyerPrice = newPrice;
                lot.price.sellerPrice =
                    newPrice -
                    (newPrice * marketplace.marketCommission()) /
                    1000;
                lot.auction.nextStep =
                    newPrice +
                    (newPrice * lot.auction.step) /
                    1000;
            }
        }
        marketplace.auctionLot(lotID, lot);
        emit BidMaked(block.timestamp, lotID, msg.sender, msg.value != 0 ? msg.value : amount);
    }


    function endAuction(uint256 lotID, bytes memory data) external {
        lotInfo memory lot;
        (
            lot.creationInfo,
            lot.selling,
            lot.sellStart,
            lot.price,
            lot.auction,
            lot.offered,
            lot.isERC1155,
            lot.openForOffers
        ) = marketplace.lots(lotID);
        require(lot.auction.endAuction <= block.timestamp && lot.selling == lotType.Auction, "Auction not ended");
        address marketWallet = marketplace.marketWallet();
        if (lot.isERC1155 == true) {
            ERC1155 nft_contract = ERC1155(lot.creationInfo.contractAddress);
            if (lot.price.sellerPrice == 0) {
                nft_contract.safeTransferFrom(
                    address(marketplace),
                    lot.creationInfo.owner,
                    lot.creationInfo.id,
                    lot.creationInfo.amount,
                    data
                );
            } else {
                nft_contract.safeTransferFrom(
                    address(marketplace),
                    lot.auction.lastBid,
                    lot.creationInfo.id,
                    lot.creationInfo.amount,
                    data
                );
            }
        } else {
            ERC721 nft_contract = ERC721(lot.creationInfo.contractAddress);
            if (lot.price.sellerPrice == 0) {
                nft_contract.safeTransferFrom(
                    address(marketplace),
                    lot.creationInfo.owner,
                    lot.creationInfo.id,
                    data
                );
            } else {
                nft_contract.safeTransferFrom(
                    address(marketplace),
                    lot.auction.lastBid,
                    lot.creationInfo.id,
                    data
                );
            }
        }
        if (lot.price.sellerPrice != 0) {
            (uint256 commission, address owner) = marketplace.collections(
                lot.creationInfo.contractAddress
            );
            uint256 marketCommission = marketplace.marketCommission();
            if (lot.price.contractAddress == address(0x0)) {
                payable(lot.creationInfo.owner).transfer(lot.price.sellerPrice);
                if (marketCommission > 0) {
                    payable(marketplace.marketWallet()).transfer(
                        (lot.price.buyerPrice * marketCommission) / 1000
                    );
                }
                if (commission > 0) {
                    payable(owner).transfer(
                        (lot.price.buyerPrice * commission) / 1000
                    );
                }
            } else {
                ERC20 tokenContract = ERC20(lot.price.contractAddress);
                tokenContract.transfer(
                    lot.creationInfo.owner,
                    lot.price.sellerPrice
                );
                if (marketCommission > 0) {
                    tokenContract.transfer(
                        marketWallet,
                        (lot.price.buyerPrice *
                            marketplace.marketCommission()) / 1000
                    );
                }
                if (commission > 0) {
                    tokenContract.transfer(
                        owner,
                        (lot.price.buyerPrice * commission) / 1000
                    );
                }
            }
        }
        delete lot;
        marketplace.auctionLot(lotID, lot);
        emit AuctionEnd(block.timestamp, lotID, lot.creationInfo.amount, false);
    }

    function finishAuction(uint256 lotID, bytes memory data) external {
        lotInfo memory lot;
        (
            lot.creationInfo,
            lot.selling,
            lot.sellStart,
            lot.price,
            lot.auction,
            lot.offered,
            lot.isERC1155,
            lot.openForOffers
        ) = marketplace.lots(lotID);
        require(lot.price.sellerPrice == 0 && lot.selling == lotType.Auction, "Lot have bid");
        if (lot.isERC1155 == true) {
            ERC1155 nft_contract = ERC1155(lot.creationInfo.contractAddress);
            nft_contract.safeTransferFrom(
                address(marketplace),
                lot.creationInfo.owner,
                lot.creationInfo.id,
                lot.creationInfo.amount,
                data
            );
        } else {
            ERC721 nft_contract = ERC721(lot.creationInfo.contractAddress);
            nft_contract.safeTransferFrom(
                address(marketplace),
                lot.creationInfo.owner,
                lot.creationInfo.id,
                data
            );
        }
        delete lot;
        marketplace.auctionLot(lotID, lot);
        emit AuctionEnd(block.timestamp, lotID, lot.creationInfo.amount, true);
    }
}