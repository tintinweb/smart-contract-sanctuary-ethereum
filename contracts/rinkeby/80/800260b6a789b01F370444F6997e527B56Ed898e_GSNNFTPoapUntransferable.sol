// SPDX-License-Identifier: none

import "./interface/IERC1155.sol";
import "./interface/IERC1155Receiver.sol";
import "./interface/IERC1155MetadataURI.sol";

import "./library/Address.sol";

import "./abstract/ERC165.sol";
import "./abstract/Managable.sol";

pragma solidity ^0.8.0;

contract GSNNFTPoapUntransferable is Managable, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    mapping(uint256 => uint256) private _tokenEvent;
    mapping(uint256 => uint256) private _eventToken;
    mapping(uint256 => uint256) private _totalSupply;
    mapping(uint256 => uint256) private _eventSupply;
    mapping(uint256 => eventHappen) private _eventTime;
    mapping(uint256 => string) private _metadataHash;
    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    struct eventHappen{
        uint256 startEvent;
        uint256 endEvent;
    }

    uint256 private _lastIdExist;

    string private _name;
    string private _symbol;
    string private _uri;

    event EventToken(uint256 indexed eventId, uint256 tokenId, uint256 amount);

    constructor (
        address forwarder_,
        string memory name_,
        string memory symbol_
    ) {
        _name = name_;
        _symbol = symbol_;
        _setURI("ipfs://");

        _setTrustedForwarder(forwarder_);
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

    function eventSupply(uint256 id) public view virtual returns (uint256) {
        return _eventSupply[id];
    }

    function exists(uint256 id) public view virtual returns (bool) {
        return totalSupply(id) > 0;
    }

    function nextId() public view virtual returns (uint256 id) {
        return _lastIdExist;
    }

    function tokenEvent(uint256 nftId) public view returns (uint256) {
        return _tokenEvent[nftId];
    }

    function eventToken(uint256 eventId) public view returns (uint256) {
        return _eventToken[eventId];
    }

    function eventTime(uint256 eventId) public view returns(eventHappen memory){
        return _eventTime[eventId];
    }

    function baseURI() public view virtual returns (string memory) {
        return _uri;
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        require(
            exists(id),
            "GSNNFTPoapUntransferable: this id is not minted"
        );
        return string(abi.encodePacked(_uri, _metadataHash[id]));
    }

    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "GSNNFTPoapUntransferable: balance query for the zero address");
        return _balances[id][account];
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "GSNNFTPoapUntransferable: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    function createEvent(
        uint256 start,
        uint256 end,
        uint256 eventId,
        uint256 nftId,
        uint256 eventSupplys,
        string memory hash
    ) public virtual onlyOwner {
        require(
            tokenEvent(nftId) == 0 && eventToken(eventId) == 0,
            "GSNNFTPoapUntransferable: Some event id or nft id have been used on others"
        );

        _tokenEvent[nftId] = eventId;
        _eventToken[eventId] = nftId;
        _eventSupply[nftId] += eventSupplys;
        _eventTime[eventId] = eventHappen(
            start,
            end
        );
        _metadataHash[nftId] = hash;
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        keccak256(
            abi.encodePacked(operator, approved)
        );
        revert(
            "GSNNFTPoapUntransferable: This NFT is not transactionable"
        );
    }

    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function mint(
        address account,
        uint256 eventId,
        uint256 value
    ) public virtual onlyManager {
        uint256 getNftId = tokenEvent(eventId);
        eventHappen memory data = eventTime(eventId);

        require(
            block.timestamp >= data.startEvent &&
            block.timestamp <= data.endEvent,
            "GSNNFTPoapUntransferable: Cant minting before or after event date!"
        );
        require(
            (totalSupply(getNftId) + value) < eventSupply(getNftId),
            "GSNNFTPoapUntransferable: Max supply reached!"
        );

        _mint(account, getNftId, value, "");

        emit EventToken(eventId, getNftId, value);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        keccak256(
            abi.encodePacked(
                from,
                to,
                id,
                amount,
                data
            )
        );
        revert(
            "GSNNFTPoapUntransferable: This NFT is not transactionable"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        keccak256(
            abi.encodePacked(
                from,
                to,
                ids,
                amounts,
                data
            )
        );
        revert(
            "GSNNFTPoapUntransferable: This NFT is not transactionable"
        );
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
        require(to != address(0), "GSNNFTPoapUntransferable: mint to the zero address");

        address operator = _msgSender();

        _supplyCounter(address(0), to, _asSingletonArray(id), _asSingletonArray(amount));

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
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
                    revert("GSNNFTPoapUntransferable: ERC1155 rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("GSNNFTPoapUntransferable: transfer to non ERC1155Receiver implementer");
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