// SPDX-License-Identifier: none

import "./interface/IERC1155.sol";
import "./interface/IERC1155Receiver.sol";
import "./interface/IERC1155MetadataURI.sol";

import "./library/Address.sol";
import "./library/Counters.sol";

import "./abstract/ERC165.sol";
import "./abstract/Managable.sol";
import "./abstract/Draft-EIP712.sol";

pragma solidity ^0.8.0;

contract JoypolisGSNNFT is Managable, ERC165, IERC1155, IERC1155MetadataURI, EIP712 {
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("safeTransferFromWithPermit(address from,address to,uint256 id,uint256 amount,uint256 nonce,uint256 deadline)");

    using Address for address;
    using Strings for uint256;
    using Counters for Counters.Counter;

    struct eventHappen{
        uint256 startEvent;
        uint256 endEvent;
    }

    mapping(address => Counters.Counter) private _nonces;
    mapping(uint256 => uint256) private _tokenEvent;
    mapping(uint256 => uint256[]) private _eventToken;
    mapping(uint256 => uint256) private _totalSupply;
    mapping(uint256 => uint256) private _maxSupply;
    mapping(uint256 => eventHappen) private _eventTime;
    mapping(uint256 => string) private _metadataHash;
    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    Counters.Counter private _lastEventId;
    uint256 private _lastIdExist;

    string private _name;
    string private _symbol;
    string private _uri;

    event EventToken(uint256 indexed eventId, uint256 tokenId, uint256 amount);

    constructor (
        address forwarder,
        string memory name_,
        string memory symbol_
    ) EIP712("JoypolisGSNNFT", "1") {
        _name = name_;
        _symbol = symbol_;
        _setURI("ipfs://");

        _setTrustedForwarder(forwarder);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }
    
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    function maxSupply(uint256 id) public view virtual returns (uint256) {
        return _maxSupply[id];
    }

    function tokenEvent(uint256 nftId) public view returns (uint256) {
        return _tokenEvent[nftId];
    }

    function eventToken(uint256 eventId) public view returns (uint256[] memory) {
        return _eventToken[eventId];
    }

    function eventTime(uint256 eventId) public view returns(eventHappen memory){
        return _eventTime[eventId];
    }

    function exists(uint256 id) public view virtual returns (bool) {
        return totalSupply(id) > 0;
    }

    function nextId() public view virtual returns (uint256 id) {
        return _lastIdExist;
    }

    function lastEventId() public view virtual returns (uint256) {
        return _lastEventId.current();
    }

    function baseURI() public view virtual returns (string memory) {
        return _uri;
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        require(
            exists(id),
            "JoypolisGSNNFT: this id is not minted"
        );
        return string(abi.encodePacked(_uri, _metadataHash[id]));
    }

    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "JoypolisGSNNFT: balance query for the zero address");
        return _balances[id][account];
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "JoypolisGSNNFT: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    function createEvent(
        uint256 start,
        uint256 end,
        uint256[] memory nftId,
        uint256[] memory eventSupplys,
        string[] memory hash
    ) public virtual onlyOwner {
        _lastEventId.increment();
        uint256 newEvent = _lastEventId.current();

        require(
            nftId.length == eventSupplys.length &&
            eventSupplys.length == hash.length,
            "JoypolisGSNNFT : nftId and eventSupplys lenght must same"
        );

        for(uint256 a; a < nftId.length; a++){
            require(
                tokenEvent(nftId[a]) == 0,
                "JoypolisGSNNFT: Some event id or nft id have been used on others"
            );

            _tokenEvent[nftId[a]] = newEvent;
            _eventToken[newEvent].push(nftId[a]);
            _maxSupply[nftId[a]] += eventSupplys[a];
            _metadataHash[nftId[a]] = hash[a];
        }

        _eventTime[newEvent] = eventHappen(
            start,
            end
        );
    }

    function addMetadataHash(
        uint256 id,
        string memory hash
    ) public virtual onlyOwner {
        _metadataHash[id] = hash;
    }

    function addBatchMetadataHash(
        uint256[] memory ids,
        string[] memory hashes
    ) public virtual onlyOwner {
        for(uint256 a; a < ids.length; a++){
            _metadataHash[ids[a]] = hashes[a];
        }
    }

    function addBatchMaxSupply(
        uint256[] memory ids,
        uint256[] memory amount
    ) public virtual onlyOwner {
        for(uint256 a; a < ids.length; a++){
            _maxSupply[ids[a]] += amount[a];
        }
    }

    function addMaxSupply(
        uint256 id,
        uint256 amount
    ) public virtual onlyOwner {
        _maxSupply[id] += amount;
    }

    function resetBatchMaxSupply(
        uint256[] memory ids
    ) public virtual onlyOwner {
        for(uint256 a; a < ids.length; a++){
            _maxSupply[ids[a]] = _totalSupply[ids[a]];
        }
    }

    function resetMaxSupply(
        uint256 id
    ) public virtual onlyOwner {
        _maxSupply[id] = _totalSupply[id];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "JoypolisGSNNFT: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "JoypolisGSNNFT: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }

    function mintEvent(
        address account,
        uint256 eventId,
        uint256 value
    ) public virtual onlyManager {
        uint256 getId = _getUnclaimed(eventId);
        eventHappen memory data = eventTime(eventId);

        require(
            block.timestamp >= data.startEvent &&
            block.timestamp <= data.endEvent,
            "GSNNFTPoapUntransferable: Cant minting before or after event date!"
        );
        require(
            (totalSupply(getId) + value) <= maxSupply(getId),
            "JoypolisGSNNFT: Max supply reached!"
        );

        _mint(account, getId, value, "");

        emit EventToken(eventId, getId, value);
    }

    function mint(
        address account,
        uint256 id,
        uint256 value
    ) public virtual onlyOwner {
        require(
            (totalSupply(id) + value) <= maxSupply(id),
            "JoypolisGSNNFT: Max supply reached!"
        );

        _mint(account, id, value, "");
    }

    function mintBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual onlyOwner {
        for(uint256 a; a < ids.length; a++){
            require(
                (totalSupply(ids[a]) + values[a]) < maxSupply(ids[a]),
                "JoypolisGSNNFT: Max supply reached!"
            );
        }

        _mintBatch(account, ids, values, "");
    }

    function safeTransferFromWithPermit(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        uint256 deadline,
        bytes memory data_,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(
            _verifySafeTransferFromWithPermit(
                from,to,id,amount,deadline,v,r,s
            ) == from,
            "JoypolisGSNNFT: You are not permitted, please check your signature"
        );
        _safeTransferFrom(from, to, id, amount, data_);
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
            "JoypolisGSNNFT: caller is not owner nor approved"
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
            "JoypolisGSNNFT: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function nonces(address owner) public view virtual returns (uint256) {
        return _nonces[owner].current();
    }

    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function _verifySafeTransferFromWithPermit(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private returns(address){
        require(block.timestamp <= deadline, "JoypolisGSNNFT: expired deadline");
        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, from, to, id, amount, _useNonce(from), deadline));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, v, r, s);

        return signer;
    }

    function _useNonce(address owner) private returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        require(to != address(0), "JoypolisGSNNFT: transfer to the zero address");

        address operator = _msgSender();

        _supplyCounter(from, to, _asSingletonArray(id), _asSingletonArray(amount));

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "JoypolisGSNNFT: insufficient balance for transfer");
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
    ) private {
        require(ids.length == amounts.length, "JoypolisGSNNFT: ids and amounts length mismatch");
        require(to != address(0), "JoypolisGSNNFT: transfer to the zero address");

        address operator = _msgSender();

        _supplyCounter(from, to, ids, amounts);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "JoypolisGSNNFT: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    function _setURI(string memory newuri) private {
        _uri = newuri;
    }

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        require(to != address(0), "JoypolisGSNNFT: mint to the zero address");

        address operator = _msgSender();

        _supplyCounter(address(0), to, _asSingletonArray(id), _asSingletonArray(amount));

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        require(to != address(0), "JoypolisGSNNFT: mint to the zero address");
        require(ids.length == amounts.length, "JoypolisGSNNFT: ids and amounts length mismatch");

        address operator = _msgSender();

        _supplyCounter(address(0), to, ids, amounts);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) private {
        require(from != address(0), "JoypolisGSNNFT: burn from the zero address");

        address operator = _msgSender();

        _supplyCounter(from, address(0), _asSingletonArray(id), _asSingletonArray(amount));

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "JoypolisGSNNFT: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) private {
        require(from != address(0), "JoypolisGSNNFT: burn from the zero address");
        require(ids.length == amounts.length, "JoypolisGSNNFT: ids and amounts length mismatch");

        address operator = _msgSender();

        _supplyCounter(from, address(0), ids, amounts);

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "JoypolisGSNNFT: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) private {
        require(owner != operator, "JoypolisGSNNFT: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

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
                    revert("JoypolisGSNNFT: ERC1155 rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("JoypolisGSNNFT: transfer to non ERC1155Receiver implementer");
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
                    revert("JoypolisGSNNFT: ERC1155 rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("JoypolisGSNNFT: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    function _supplyCounter(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) private {
        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];

                if(_lastIdExist < ids[i]){
                    _lastIdExist = ids[i];
                }
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] -= amounts[i];

                if(_lastIdExist < ids[i]){
                    _lastIdExist = ids[i];
                }
            }
        }
    }

    function _getUnclaimed(uint256 eventId) private view returns(uint256) {
        unchecked{
            uint256 biggest;

            uint256[] memory listNftEvent = eventToken(eventId);
            uint256[] memory remainingSupply = new uint256[](listNftEvent.length);

            for(uint256 a; a < listNftEvent.length; a++){
                remainingSupply[a] = maxSupply(listNftEvent[a]) - totalSupply(listNftEvent[a]);
            }
            

            if(listNftEvent.length > 1){
                for(uint256 b = 1; b < listNftEvent.length; b++){
                    if(remainingSupply[b - 1] >= remainingSupply[b]){
                        biggest = listNftEvent[b - 1];
                    }else{
                        biggest = listNftEvent[b];
                    }
                }
            }else{
                biggest = listNftEvent[0];
            }

            return biggest;
        }
    }
}

import "./IERC165.sol";

// SPDX-License-Identifier: none

pragma solidity ^0.8.0;

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

import "./IERC165.sol";

// SPDX-License-Identifier: none

pragma solidity ^0.8.0;

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

import "./IERC1155.sol";

// SPDX-License-Identifier: none

pragma solidity ^0.8.0;

interface IERC1155MetadataURI is IERC1155 {
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: none

pragma solidity ^0.8.0;

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

import "./../interface/IERC165.sol";

// SPDX-License-Identifier: none

pragma solidity ^0.8.0;

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

import "./BaseRelayRecipient.sol";

// SPDX-License-Identifier: none

pragma solidity ^0.8.0;

abstract contract Managable is BaseRelayRecipient {
    address private _owner;

    mapping (address => bool) private _manager;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ImplementManager(address indexed user, bool indexed status);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function isManager(address user) public view virtual returns (bool) {
        return _manager[user];
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Managable: caller is not the owner");
        _;
    }

    modifier onlyManager() {
        require(
            owner() == _msgSender() ||
            isManager(_msgSender()),
            "Managable: caller is not the Manager");
        _;
    }

    function setManager(address user, bool status) public virtual onlyOwner {
        _manager[user] = status;
        emit ImplementManager(user, status);
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Managable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "../library/ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: none

pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

import "./IRelayRecipient.sol";

// SPDX-License-Identifier: none

pragma solidity ^0.8.0;

abstract contract BaseRelayRecipient is IRelayRecipient {
    address private _trustedForwarder;
        string public override versionRecipient = "2.2.0";

    function trustedForwarder() public virtual view returns (address){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: none

pragma solidity ^0.8.0;

abstract contract IRelayRecipient {
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    function _msgSender() internal virtual view returns (address);

    function _msgData() internal virtual view returns (bytes calldata);

    function versionRecipient() external virtual view returns (string memory);
}

// SPDX-License-Identifier: none

pragma solidity ^0.8.0;

import "./Strings.sol";

library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: none

pragma solidity ^0.8.0;

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