// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./Ownable.sol";

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
        if (success) return returndata;
        else {
            if (returndata.length > 0)
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            else revert(errorMessage);
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

interface IERC1155 is IERC165 {
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

interface IERC1155MetadataURI is IERC1155 {
    function uri(uint256 id) external view returns (string memory);
}

contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;
    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    string private _uri;

    constructor(string memory uri_) {
        _setURI(uri_);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
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
            "ERC1155: balance query for the zero address"
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

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
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
        _doSafeTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            id,
            amount,
            data
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
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
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
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
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
}

contract Race is ERC1155, Ownable {
    struct Reward {
        string name;
        string metadata_uri;
        uint totalSupply;
        uint availableSupply;
        mapping(address => uint) balances;
        address[] winners;
    }
    Reward[] public rewards;
    string public baseMetadataURI;
    string public name;
    address[] public participants;
    uint public startTime;
    string[] public rewardNames;
    mapping(string => uint) public rewardNametoId;
    mapping(string => uint) public rewardNameToAvailableSupply;

    constructor(
        string memory _raceName,
        string memory _base_metatadata_uri,
        string[] memory _rewardNames,
        string[] memory _rewardURIs,
        uint[] memory _rewardAmounts,
        address[] memory _participants,
        uint _startTime
    ) ERC1155(_base_metatadata_uri) {
        create(
            _raceName,
            _base_metatadata_uri,
            _rewardNames,
            _rewardURIs,
            _rewardAmounts,
            _participants,
            _startTime
        );
    }

    function create(
        string memory _raceName,
        string memory _base_metatadata_uri,
        string[] memory _rewardNames,
        string[] memory _rewardURIs,
        uint[] memory _rewardAmounts,
        address[] memory _participants,
        uint _startTime
    ) public {
        rewardNames = _rewardNames;
        createMapping(_rewardNames, _rewardURIs, _rewardAmounts);
        setURI(_base_metatadata_uri);
        baseMetadataURI = _base_metatadata_uri;
        name = _raceName;
        startTime = _startTime;
        addParticipants(_participants);
        transferOwnership(msg.sender);
    }

    function createMapping(
        string[] memory _rewardNames,
        string[] memory _metatadata_uri,
        uint[] memory _rewardAmounts
    ) private {
        for (uint id = 0; id < _rewardNames.length; id++) {
            Reward storage newReward = rewards.push();
            newReward.name = _rewardNames[id];
            newReward.metadata_uri = _metatadata_uri[id];
            newReward.totalSupply = _rewardAmounts[id];
            newReward.availableSupply = _rewardAmounts[id];
            rewardNametoId[_rewardNames[id]] = id;
        }
    }

    function addParticipants(address[] memory _participants) public onlyOwner {
        for (uint i = 0; i < _participants.length; i++) {
            bool uniqueEntry = true;
            for (uint j = 0; j < participants.length; j++)
                if (_participants[i] == participants[j]) {
                    uniqueEntry = false;
                    break;
                }
            if (uniqueEntry) participants.push(_participants[i]);
        }
    }

    function addNewRewards(
        string[] memory _rewardNames,
        string[] memory _rewardURIs,
        uint[] memory _rewardAmounts
    ) public onlyOwner {
        for (uint i = 0; i < _rewardNames.length; i++) {
            bool uniqueEntry = true;
            for (uint j = 0; j < rewards.length; j++)
                if (
                    keccak256(abi.encodePacked(_rewardNames[i])) ==
                    keccak256(abi.encodePacked(rewards[j].name)) ||
                    keccak256(abi.encodePacked(_rewardURIs[i])) ==
                    keccak256(abi.encodePacked(rewards[j].metadata_uri))
                ) {
                    uniqueEntry = false;
                    break;
                }
            if (uniqueEntry)
                createMapping(_rewardNames, _rewardURIs, _rewardAmounts);
        }
    }

    function uri(uint256 _rewardId)
        public
        view
        override
        returns (string memory)
    {
        bytes memory _metadata_uri = bytes(rewards[_rewardId].metadata_uri);
        if (_metadata_uri.length == 0) return rewards[_rewardId].metadata_uri;
        return
            string(
                abi.encodePacked(
                    baseMetadataURI,
                    Strings.toString(_rewardId),
                    ".json"
                )
            );
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function publishReward(
        uint _rewardId,
        address[] memory _winners,
        uint[] memory amounts
    ) public onlyOwner {
        for (uint i = 0; i < _winners.length; i++) {
            bool alienWinner = true;
            for (uint j = 0; j < participants.length; j++) {
                if (_winners[i] == participants[j]) {
                    alienWinner = false;
                    break;
                }
            }
            if (alienWinner) continue;
            require(
                rewards[_rewardId].availableSupply >= amounts[i],
                string(
                    abi.encodePacked(
                        "Cannot mint more than the available supply: Available Supply = ",
                        Strings.toString(rewards[_rewardId].availableSupply),
                        ", requested = ",
                        Strings.toString(amounts[i]),
                        ", to = ",
                        Strings.toHexString(uint(uint160(_winners[i]))),
                        ", reward = ",
                        rewards[_rewardId].name
                    )
                )
            );
            rewards[_rewardId].balances[_winners[i]] = amounts[i];
            rewards[_rewardId].winners.push(_winners[i]);
            rewards[_rewardId].availableSupply =
                rewards[_rewardId].totalSupply -
                amounts[i];
        }
    }

    function mint(
        address account,
        uint _rewardId,
        uint256 amount
    ) public returns (uint) {
        require(
            rewards[_rewardId].balances[account] > 0,
            "This account hasn't won this reward"
        );
        require(
            rewards[_rewardId].balances[account] == amount,
            string(
                abi.encodePacked(
                    Strings.toHexString(uint(uint160(account))),
                    " is allowed to mint ",
                    Strings.toString(rewards[_rewardId].balances[account]),
                    " ",
                    rewards[_rewardId].name
                )
            )
        );
        _mint(account, _rewardId, amount, "");
        rewards[_rewardId].balances[account] = 0;
        return _rewardId;
    }

    function mintBatch(
        address to,
        uint256[] memory _rewardIds,
        uint256[] memory amounts,
        bytes memory data
    ) public {
        require(msg.sender == to, "Only the reward owner can mint");
        _mintBatch(to, _rewardIds, amounts, data);
    }

    function getRewardDetails(uint _rewardId)
        public
        view
        returns (
            address _contract,
            string memory _name,
            string memory _metatadata_uri,
            uint _totalSupply,
            uint _availableSupply,
            address[] memory _winners,
            uint[] memory
        )
    {
        _winners = rewards[_rewardId].winners;
        uint[] memory _amounts = new uint[](_winners.length);
        for (uint i = 0; i < _winners.length; i++)
            _amounts[i] = rewards[_rewardId].balances[_winners[i]];
        return (
            address(this),
            rewards[_rewardId].name,
            uri(_rewardId),
            rewards[_rewardId].totalSupply,
            rewards[_rewardId].availableSupply,
            _winners,
            _amounts
        );
    }
}