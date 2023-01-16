// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial ERC173 interface needed by internal functions
 */
interface IERC173Internal {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC173Internal } from '../IERC173Internal.sol';

interface IOwnableInternal is IERC173Internal {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOwnableInternal } from './IOwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

abstract contract OwnableInternal is IOwnableInternal {
    using OwnableStorage for OwnableStorage.Layout;

    modifier onlyOwner() {
        require(
            msg.sender == OwnableStorage.layout().owner,
            'Ownable: sender must be owner'
        );
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transferOwnership(address account) internal virtual {
        OwnableStorage.layout().setOwner(account);
        emit OwnershipTransferred(msg.sender, account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Ownable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setOwner(Layout storage l, address owner) internal {
        l.owner = owner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC165Storage {
    struct Layout {
        mapping(bytes4 => bool) supportedInterfaces;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC165');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function isSupportedInterface(Layout storage l, bytes4 interfaceId)
        internal
        view
        returns (bool)
    {
        return l.supportedInterfaces[interfaceId];
    }

    function setSupportedInterface(
        Layout storage l,
        bytes4 interfaceId,
        bool status
    ) internal {
        require(interfaceId != 0xffffffff, 'ERC165: invalid interface id');
        l.supportedInterfaces[interfaceId] = status;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { PausableStorage } from './PausableStorage.sol';

/**
 * @title Internal functions for Pausable security control module.
 */
abstract contract PausableInternal {
    using PausableStorage for PausableStorage.Layout;

    event Paused(address account);

    event Unpaused(address account);

    modifier whenNotPaused() {
        require(!_paused(), 'Pausable: paused');
        _;
    }

    modifier whenPaused() {
        require(_paused(), 'Pausable: not paused');
        _;
    }

    /**
     * @notice query the contracts paused state.
     * @return true if paused, false if unpaused.
     */
    function _paused() internal view virtual returns (bool) {
        return PausableStorage.layout().paused;
    }

    /**
     * @notice Triggers paused state, when contract is unpaused.
     */
    function _pause() internal virtual whenNotPaused {
        PausableStorage.layout().paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Triggers unpaused state, when contract is paused.
     */
    function _unpause() internal virtual whenPaused {
        PausableStorage.layout().paused = false;
        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library PausableStorage {
    struct Layout {
        bool paused;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Pausable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC1155 } from '../IERC1155.sol';
import { IERC1155Receiver } from '../IERC1155Receiver.sol';
import { IERC1155Base } from './IERC1155Base.sol';
import { ERC1155BaseInternal, ERC1155BaseStorage } from './ERC1155BaseInternal.sol';

/**
 * @title Base ERC1155 contract
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
abstract contract ERC1155Base is IERC1155Base, ERC1155BaseInternal {
    /**
     * @inheritdoc IERC1155
     */
    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        returns (uint256)
    {
        return _balanceOf(account, id);
    }

    /**
     * @inheritdoc IERC1155
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        require(
            accounts.length == ids.length,
            'ERC1155: accounts and ids length mismatch'
        );

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        uint256[] memory batchBalances = new uint256[](accounts.length);

        unchecked {
            for (uint256 i; i < accounts.length; i++) {
                require(
                    accounts[i] != address(0),
                    'ERC1155: batch balance query for the zero address'
                );
                batchBalances[i] = balances[ids[i]][accounts[i]];
            }
        }

        return batchBalances;
    }

    /**
     * @inheritdoc IERC1155
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        returns (bool)
    {
        return ERC1155BaseStorage.layout().operatorApprovals[account][operator];
    }

    /**
     * @inheritdoc IERC1155
     */
    function setApprovalForAll(address operator, bool status) public virtual {
        require(
            msg.sender != operator,
            'ERC1155: setting approval status for self'
        );
        ERC1155BaseStorage.layout().operatorApprovals[msg.sender][
            operator
        ] = status;
        emit ApprovalForAll(msg.sender, operator, status);
    }

    /**
     * @inheritdoc IERC1155
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            'ERC1155: caller is not owner nor approved'
        );
        _safeTransfer(msg.sender, from, to, id, amount, data);
    }

    /**
     * @inheritdoc IERC1155
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            'ERC1155: caller is not owner nor approved'
        );
        _safeTransferBatch(msg.sender, from, to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AddressUtils } from '../../../utils/AddressUtils.sol';
import { IERC1155Internal } from '../IERC1155Internal.sol';
import { IERC1155Receiver } from '../IERC1155Receiver.sol';
import { ERC1155BaseStorage } from './ERC1155BaseStorage.sol';

/**
 * @title Base ERC1155 internal functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
abstract contract ERC1155BaseInternal is IERC1155Internal {
    using AddressUtils for address;

    /**
     * @notice query the balance of given token held by given address
     * @param account address to query
     * @param id token to query
     * @return token balance
     */
    function _balanceOf(address account, uint256 id)
        internal
        view
        virtual
        returns (uint256)
    {
        require(
            account != address(0),
            'ERC1155: balance query for the zero address'
        );
        return ERC1155BaseStorage.layout().balances[id][account];
    }

    /**
     * @notice mint given quantity of tokens for given address
     * @dev ERC1155Receiver implementation is not checked
     * @param account beneficiary of minting
     * @param id token ID
     * @param amount quantity of tokens to mint
     * @param data data payload
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), 'ERC1155: mint to the zero address');

        _beforeTokenTransfer(
            msg.sender,
            address(0),
            account,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        ERC1155BaseStorage.layout().balances[id][account] += amount;

        emit TransferSingle(msg.sender, address(0), account, id, amount);
    }

    /**
     * @notice mint given quantity of tokens for given address
     * @param account beneficiary of minting
     * @param id token ID
     * @param amount quantity of tokens to mint
     * @param data data payload
     */
    function _safeMint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        _mint(account, id, amount, data);

        _doSafeTransferAcceptanceCheck(
            msg.sender,
            address(0),
            account,
            id,
            amount,
            data
        );
    }

    /**
     * @notice mint batch of tokens for given address
     * @dev ERC1155Receiver implementation is not checked
     * @param account beneficiary of minting
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to mint
     * @param data data payload
     */
    function _mintBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(account != address(0), 'ERC1155: mint to the zero address');
        require(
            ids.length == amounts.length,
            'ERC1155: ids and amounts length mismatch'
        );

        _beforeTokenTransfer(
            msg.sender,
            address(0),
            account,
            ids,
            amounts,
            data
        );

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        for (uint256 i; i < ids.length; ) {
            balances[ids[i]][account] += amounts[i];
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, address(0), account, ids, amounts);
    }

    /**
     * @notice mint batch of tokens for given address
     * @param account beneficiary of minting
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to mint
     * @param data data payload
     */
    function _safeMintBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        _mintBatch(account, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            msg.sender,
            address(0),
            account,
            ids,
            amounts,
            data
        );
    }

    /**
     * @notice burn given quantity of tokens held by given address
     * @param account holder of tokens to burn
     * @param id token ID
     * @param amount quantity of tokens to burn
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), 'ERC1155: burn from the zero address');

        _beforeTokenTransfer(
            msg.sender,
            account,
            address(0),
            _asSingletonArray(id),
            _asSingletonArray(amount),
            ''
        );

        mapping(address => uint256) storage balances = ERC1155BaseStorage
            .layout()
            .balances[id];

        unchecked {
            require(
                balances[account] >= amount,
                'ERC1155: burn amount exceeds balances'
            );
            balances[account] -= amount;
        }

        emit TransferSingle(msg.sender, account, address(0), id, amount);
    }

    /**
     * @notice burn given batch of tokens held by given address
     * @param account holder of tokens to burn
     * @param ids token IDs
     * @param amounts quantities of tokens to burn
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), 'ERC1155: burn from the zero address');
        require(
            ids.length == amounts.length,
            'ERC1155: ids and amounts length mismatch'
        );

        _beforeTokenTransfer(msg.sender, account, address(0), ids, amounts, '');

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        unchecked {
            for (uint256 i; i < ids.length; i++) {
                uint256 id = ids[i];
                require(
                    balances[id][account] >= amounts[i],
                    'ERC1155: burn amount exceeds balance'
                );
                balances[id][account] -= amounts[i];
            }
        }

        emit TransferBatch(msg.sender, account, address(0), ids, amounts);
    }

    /**
     * @notice transfer tokens between given addresses
     * @dev ERC1155Receiver implementation is not checked
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function _transfer(
        address operator,
        address sender,
        address recipient,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(
            recipient != address(0),
            'ERC1155: transfer to the zero address'
        );

        _beforeTokenTransfer(
            operator,
            sender,
            recipient,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        unchecked {
            uint256 senderBalance = balances[id][sender];
            require(
                senderBalance >= amount,
                'ERC1155: insufficient balances for transfer'
            );
            balances[id][sender] = senderBalance - amount;
        }

        balances[id][recipient] += amount;

        emit TransferSingle(operator, sender, recipient, id, amount);
    }

    /**
     * @notice transfer tokens between given addresses
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function _safeTransfer(
        address operator,
        address sender,
        address recipient,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        _transfer(operator, sender, recipient, id, amount, data);

        _doSafeTransferAcceptanceCheck(
            operator,
            sender,
            recipient,
            id,
            amount,
            data
        );
    }

    /**
     * @notice transfer batch of tokens between given addresses
     * @dev ERC1155Receiver implementation is not checked
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _transferBatch(
        address operator,
        address sender,
        address recipient,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(
            recipient != address(0),
            'ERC1155: transfer to the zero address'
        );
        require(
            ids.length == amounts.length,
            'ERC1155: ids and amounts length mismatch'
        );

        _beforeTokenTransfer(operator, sender, recipient, ids, amounts, data);

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        for (uint256 i; i < ids.length; ) {
            uint256 token = ids[i];
            uint256 amount = amounts[i];

            unchecked {
                uint256 senderBalance = balances[token][sender];

                require(
                    senderBalance >= amount,
                    'ERC1155: insufficient balances for transfer'
                );

                balances[token][sender] = senderBalance - amount;

                i++;
            }

            // balance increase cannot be unchecked because ERC1155Base neither tracks nor validates a totalSupply
            balances[token][recipient] += amount;
        }

        emit TransferBatch(operator, sender, recipient, ids, amounts);
    }

    /**
     * @notice transfer batch of tokens between given addresses
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _safeTransferBatch(
        address operator,
        address sender,
        address recipient,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        _transferBatch(operator, sender, recipient, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            sender,
            recipient,
            ids,
            amounts,
            data
        );
    }

    /**
     * @notice wrap given element in array of length 1
     * @param element element to wrap
     * @return singleton array
     */
    function _asSingletonArray(uint256 element)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;
        return array;
    }

    /**
     * @notice revert if applicable transfer recipient is not valid ERC1155Receiver
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
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
                require(
                    response == IERC1155Receiver.onERC1155Received.selector,
                    'ERC1155: ERC1155Receiver rejected tokens'
                );
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert('ERC1155: transfer to non ERC1155Receiver implementer');
            }
        }
    }

    /**
     * @notice revert if applicable transfer recipient is not valid ERC1155Receiver
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
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
                require(
                    response ==
                        IERC1155Receiver.onERC1155BatchReceived.selector,
                    'ERC1155: ERC1155Receiver rejected tokens'
                );
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert('ERC1155: transfer to non ERC1155Receiver implementer');
            }
        }
    }

    /**
     * @notice ERC1155 hook, called before all transfers including mint and burn
     * @dev function should be overridden and new implementation must call super
     * @dev called for both single and batch transfers
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC1155BaseStorage {
    struct Layout {
        mapping(uint256 => mapping(address => uint256)) balances;
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC1155Base');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC1155 } from '../IERC1155.sol';

/**
 * @title ERC1155 base interface
 */
interface IERC1155Base is IERC1155 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableSet } from '../../../utils/EnumerableSet.sol';
import { ERC1155BaseInternal } from '../base/ERC1155BaseInternal.sol';
import { IERC1155Enumerable } from './IERC1155Enumerable.sol';
import { ERC1155EnumerableInternal, ERC1155EnumerableStorage } from './ERC1155EnumerableInternal.sol';

/**
 * @title ERC1155 implementation including enumerable and aggregate functions
 */
abstract contract ERC1155Enumerable is
    IERC1155Enumerable,
    ERC1155EnumerableInternal
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @inheritdoc IERC1155Enumerable
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply(id);
    }

    /**
     * @inheritdoc IERC1155Enumerable
     */
    function totalHolders(uint256 id) public view virtual returns (uint256) {
        return _totalHolders(id);
    }

    /**
     * @inheritdoc IERC1155Enumerable
     */
    function accountsByToken(uint256 id)
        public
        view
        virtual
        returns (address[] memory)
    {
        return _accountsByToken(id);
    }

    /**
     * @inheritdoc IERC1155Enumerable
     */
    function tokensByAccount(address account)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        return _tokensByAccount(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableSet } from '../../../utils/EnumerableSet.sol';
import { ERC1155BaseInternal, ERC1155BaseStorage } from '../base/ERC1155BaseInternal.sol';
import { ERC1155EnumerableStorage } from './ERC1155EnumerableStorage.sol';

/**
 * @title ERC1155Enumerable internal functions
 */
abstract contract ERC1155EnumerableInternal is ERC1155BaseInternal {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @notice query total minted supply of given token
     * @param id token id to query
     * @return token supply
     */
    function _totalSupply(uint256 id) internal view virtual returns (uint256) {
        return ERC1155EnumerableStorage.layout().totalSupply[id];
    }

    /**
     * @notice query total number of holders for given token
     * @param id token id to query
     * @return quantity of holders
     */
    function _totalHolders(uint256 id) internal view virtual returns (uint256) {
        return ERC1155EnumerableStorage.layout().accountsByToken[id].length();
    }

    /**
     * @notice query holders of given token
     * @param id token id to query
     * @return list of holder addresses
     */
    function _accountsByToken(uint256 id)
        internal
        view
        virtual
        returns (address[] memory)
    {
        EnumerableSet.AddressSet storage accounts = ERC1155EnumerableStorage
            .layout()
            .accountsByToken[id];

        address[] memory addresses = new address[](accounts.length());

        unchecked {
            for (uint256 i; i < accounts.length(); i++) {
                addresses[i] = accounts.at(i);
            }
        }

        return addresses;
    }

    /**
     * @notice query tokens held by given address
     * @param account address to query
     * @return list of token ids
     */
    function _tokensByAccount(address account)
        internal
        view
        virtual
        returns (uint256[] memory)
    {
        EnumerableSet.UintSet storage tokens = ERC1155EnumerableStorage
            .layout()
            .tokensByAccount[account];

        uint256[] memory ids = new uint256[](tokens.length());

        unchecked {
            for (uint256 i; i < tokens.length(); i++) {
                ids[i] = tokens.at(i);
            }
        }

        return ids;
    }

    /**
     * @notice ERC1155 hook: update aggregate values
     * @inheritdoc ERC1155BaseInternal
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from != to) {
            ERC1155EnumerableStorage.Layout storage l = ERC1155EnumerableStorage
                .layout();
            mapping(uint256 => EnumerableSet.AddressSet)
                storage tokenAccounts = l.accountsByToken;
            EnumerableSet.UintSet storage fromTokens = l.tokensByAccount[from];
            EnumerableSet.UintSet storage toTokens = l.tokensByAccount[to];

            for (uint256 i; i < ids.length; ) {
                uint256 amount = amounts[i];

                if (amount > 0) {
                    uint256 id = ids[i];

                    if (from == address(0)) {
                        l.totalSupply[id] += amount;
                    } else if (_balanceOf(from, id) == amount) {
                        tokenAccounts[id].remove(from);
                        fromTokens.remove(id);
                    }

                    if (to == address(0)) {
                        l.totalSupply[id] -= amount;
                    } else if (_balanceOf(to, id) == 0) {
                        tokenAccounts[id].add(to);
                        toTokens.add(id);
                    }
                }

                unchecked {
                    i++;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableSet } from '../../../utils/EnumerableSet.sol';

library ERC1155EnumerableStorage {
    struct Layout {
        mapping(uint256 => uint256) totalSupply;
        mapping(uint256 => EnumerableSet.AddressSet) accountsByToken;
        mapping(address => EnumerableSet.UintSet) tokensByAccount;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC1155Enumerable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC1155Internal } from '../IERC1155Internal.sol';

/**
 * @title ERC1155 enumerable and aggregate function interface
 */
interface IERC1155Enumerable is IERC1155Internal {
    /**
     * @notice query total minted supply of given token
     * @param id token id to query
     * @return token supply
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @notice query total number of holders for given token
     * @param id token id to query
     * @return quantity of holders
     */
    function totalHolders(uint256 id) external view returns (uint256);

    /**
     * @notice query holders of given token
     * @param id token id to query
     * @return list of holder addresses
     */
    function accountsByToken(uint256 id)
        external
        view
        returns (address[] memory);

    /**
     * @notice query tokens held by given address
     * @param account address to query
     * @return list of token ids
     */
    function tokensByAccount(address account)
        external
        view
        returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC1155Internal } from './IERC1155Internal.sol';
import { IERC165 } from '../../introspection/IERC165.sol';

/**
 * @title ERC1155 interface
 * @dev see https://github.com/ethereum/EIPs/issues/1155
 */
interface IERC1155 is IERC1155Internal, IERC165 {
    /**
     * @notice query the balance of given token held by given address
     * @param account address to query
     * @param id token to query
     * @return token balance
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @notice query the balances of given tokens held by given addresses
     * @param accounts addresss to query
     * @param ids tokens to query
     * @return token balances
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /**
     * @notice grant approval to or revoke approval from given operator to spend held tokens
     * @param operator address whose approval status to update
     * @param status whether operator should be considered approved
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice transfer tokens between given addresses, checking for ERC1155Receiver implementation if applicable
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @notice transfer batch of tokens between given addresses, checking for ERC1155Receiver implementation if applicable
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to transfer
     * @param data data payload
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165 } from '../../introspection/IERC165.sol';

/**
 * @title Partial ERC1155 interface needed by internal functions
 */
interface IERC1155Internal {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165 } from '../../introspection/IERC165.sol';

/**
 * @title ERC1155 transfer receiver interface
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @notice validate receipt of ERC1155 transfer
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param id token ID received
     * @param value quantity of tokens received
     * @param data data payload
     * @return function's own selector if transfer is accepted
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @notice validate receipt of ERC1155 batch transfer
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param ids token IDs received
     * @param values quantities of tokens received
     * @param data data payload
     * @return function's own selector if transfer is accepted
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20Internal } from './IERC20Internal.sol';

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 is IERC20Internal {
    /**
     * @notice query the total minted token supply
     * @return token supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice query the token balance of given account
     * @param account address to query
     * @return token balance
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice query the allowance granted from given holder to given spender
     * @param holder approver of allowance
     * @param spender recipient of allowance
     * @return token allowance
     */
    function allowance(address holder, address spender)
        external
        view
        returns (uint256);

    /**
     * @notice grant approval to spender to spend tokens
     * @dev prefer ERC20Extended functions to avoid transaction-ordering vulnerability (see https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
     * @param spender recipient of allowance
     * @param amount quantity of tokens approved for spending
     * @return success status (always true; otherwise function should revert)
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice transfer tokens to given recipient
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @notice transfer tokens to given recipient on behalf of given holder
     * @param holder holder of tokens prior to transfer
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial ERC20 interface needed by internal functions
 */
interface IERC20Internal {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC20 metadata interface
 */
interface IERC20Metadata {
    /**
     * @notice return token name
     * @return token name
     */
    function name() external view returns (string memory);

    /**
     * @notice return token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice return token decimals, generally used only for display purposes
     * @return token decimals
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '../ERC20/IERC20.sol';
import { IERC4626Internal } from './IERC4626Internal.sol';

/**
 * @title ERC4626 interface
 * @dev see https://github.com/ethereum/EIPs/issues/4626
 */
interface IERC4626 is IERC4626Internal, IERC20 {
    /**
     * @notice get the address of the base token used for vault accountin purposes
     * @return base token address
     */
    function asset() external view returns (address);

    /**
     * @notice get the total quantity of the base asset currently managed by the vault
     * @return total managed asset amount
     */
    function totalAssets() external view returns (uint256);

    /**
     * @notice calculate the quantity of shares received in exchange for a given quantity of assets, not accounting for slippage
     * @param assetAmount quantity of assets to convert
     * @return shareAmount quantity of shares calculated
     */
    function convertToShares(uint256 assetAmount)
        external
        view
        returns (uint256 shareAmount);

    /**
     * @notice calculate the quantity of assets received in exchange for a given quantity of shares, not accounting for slippage
     * @param shareAmount quantity of shares to convert
     * @return assetAmount quantity of assets calculated
     */
    function convertToAssets(uint256 shareAmount)
        external
        view
        returns (uint256 assetAmount);

    /**
     * @notice calculate the maximum quantity of base assets which may be deposited on behalf of given receiver
     * @param receiver recipient of shares resulting from deposit
     * @return maxAssets maximum asset deposit amount
     */
    function maxDeposit(address receiver)
        external
        view
        returns (uint256 maxAssets);

    /**
     * @notice calculate the maximum quantity of shares which may be minted on behalf of given receiver
     * @param receiver recipient of shares resulting from deposit
     * @return maxShares maximum share mint amount
     */
    function maxMint(address receiver)
        external
        view
        returns (uint256 maxShares);

    /**
     * @notice calculate the maximum quantity of base assets which may be withdrawn by given holder
     * @param owner holder of shares to be redeemed
     * @return maxAssets maximum asset mint amount
     */
    function maxWithdraw(address owner)
        external
        view
        returns (uint256 maxAssets);

    /**
     * @notice calculate the maximum quantity of shares which may be redeemed by given holder
     * @param owner holder of shares to be redeemed
     * @return maxShares maximum share redeem amount
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @notice simulate a deposit of given quantity of assets
     * @param assetAmount quantity of assets to deposit
     * @return shareAmount quantity of shares to mint
     */
    function previewDeposit(uint256 assetAmount)
        external
        view
        returns (uint256 shareAmount);

    /**
     * @notice simulate a minting of given quantity of shares
     * @param shareAmount quantity of shares to mint
     * @return assetAmount quantity of assets to deposit
     */
    function previewMint(uint256 shareAmount)
        external
        view
        returns (uint256 assetAmount);

    /**
     * @notice simulate a withdrawal of given quantity of assets
     * @param assetAmount quantity of assets to withdraw
     * @return shareAmount quantity of shares to redeem
     */
    function previewWithdraw(uint256 assetAmount)
        external
        view
        returns (uint256 shareAmount);

    /**
     * @notice simulate a redemption of given quantity of shares
     * @param shareAmount quantity of shares to redeem
     * @return assetAmount quantity of assets to withdraw
     */
    function previewRedeem(uint256 shareAmount)
        external
        view
        returns (uint256 assetAmount);

    /**
     * @notice execute a deposit of assets on behalf of given address
     * @param assetAmount quantity of assets to deposit
     * @param receiver recipient of shares resulting from deposit
     * @return shareAmount quantity of shares to mint
     */
    function deposit(uint256 assetAmount, address receiver)
        external
        returns (uint256 shareAmount);

    /**
     * @notice execute a minting of shares on behalf of given address
     * @param shareAmount quantity of shares to mint
     * @param receiver recipient of shares resulting from deposit
     * @return assetAmount quantity of assets to deposit
     */
    function mint(uint256 shareAmount, address receiver)
        external
        returns (uint256 assetAmount);

    /**
     * @notice execute a withdrawal of assets on behalf of given address
     * @param assetAmount quantity of assets to withdraw
     * @param receiver recipient of assets resulting from withdrawal
     * @param owner holder of shares to be redeemed
     * @return shareAmount quantity of shares to redeem
     */
    function withdraw(
        uint256 assetAmount,
        address receiver,
        address owner
    ) external returns (uint256 shareAmount);

    /**
     * @notice execute a redemption of shares on behalf of given address
     * @param shareAmount quantity of shares to redeem
     * @param receiver recipient of assets resulting from withdrawal
     * @param owner holder of shares to be redeemed
     * @return assetAmount quantity of assets to withdraw
     */
    function redeem(
        uint256 shareAmount,
        address receiver,
        address owner
    ) external returns (uint256 assetAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial ERC4626 interface needed by internal functions
 */
interface IERC4626Internal {
    event Deposit(
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        require(success, 'AddressUtils: failed to send value');
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
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
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            'AddressUtils: insufficient balance for call'
        );
        return _functionCallWithValue(target, data, value, error);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        require(
            isContract(target),
            'AddressUtils: function call to non-contract'
        );

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, value);
    }

    function indexOf(AddressSet storage set, address value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(UintSet storage set, uint256 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            'EnumerableSet: index out of bounds'
        );
        return set._values[index];
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _indexOf(Set storage set, bytes32 value)
        private
        view
        returns (uint256)
    {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            unchecked {
                bytes32 last = set._values[set._values.length - 1];

                // move last value to now-vacant index

                set._values[valueIndex - 1] = last;
                set._indexes[last] = valueIndex;
            }
            // clear last index

            set._values.pop();
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Interface for the Multicall utility contract
 */
interface IMulticall {
    /**
     * @notice batch function calls to the contract and return the results of each
     * @param data array of function call data payloads
     * @return results array of function call results
     */
    function multicall(bytes[] calldata data)
        external
        returns (bytes[] memory results);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '../token/ERC20/IERC20.sol';
import { IERC20Metadata } from '../token/ERC20/metadata/IERC20Metadata.sol';

/**
 * @title WETH (Wrapped ETH) interface
 */
interface IWETH is IERC20, IERC20Metadata {
    /**
     * @notice convert ETH to WETH
     */
    function deposit() external payable;

    /**
     * @notice convert WETH to ETH
     * @dev if caller is a contract, it should have a fallback or receive function
     * @param amount quantity of WETH to convert, denominated in wei
     */
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IMulticall } from './IMulticall.sol';

/**
 * @title Utility contract for supporting processing of multiple function calls in a single transaction
 */
abstract contract Multicall is IMulticall {
    /**
     * @inheritdoc IMulticall
     */
    function multicall(bytes[] calldata data)
        external
        returns (bytes[] memory results)
    {
        results = new bytes[](data.length);

        unchecked {
            for (uint256 i; i < data.length; i++) {
                (bool success, bytes memory returndata) = address(this)
                    .delegatecall(data[i]);

                if (success) {
                    results[i] = returndata;
                } else {
                    assembly {
                        returndatacopy(0, 0, returndatasize())
                        revert(0, returndatasize())
                    }
                }
            }
        }

        return results;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ReentrancyGuardStorage } from './ReentrancyGuardStorage.sol';

/**
 * @title Utility contract for preventing reentrancy attacks
 */
abstract contract ReentrancyGuard {
    modifier nonReentrant() {
        ReentrancyGuardStorage.Layout storage l = ReentrancyGuardStorage
            .layout();
        require(l.status != 2, 'ReentrancyGuard: reentrant call');
        l.status = 2;
        _;
        l.status = 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ReentrancyGuardStorage {
    struct Layout {
        uint256 status;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ReentrancyGuard');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '../token/ERC20/IERC20.sol';
import { AddressUtils } from './AddressUtils.sol';

/**
 * @title Safe ERC20 interaction library
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library SafeERC20 {
    using AddressUtils for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev safeApprove (like approve) should only be called when setting an initial allowance or when resetting it to zero; otherwise prefer safeIncreaseAllowance and safeDecreaseAllowance
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeERC20: approve from non-zero to non-zero allowance'
        );

        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                'SafeERC20: decreased allowance below zero'
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    /**
     * @notice send transaction data and check validity of return value, if present
     * @param token ERC20 token interface
     * @param data transaction data
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            'SafeERC20: low-level call failed'
        );

        if (returndata.length > 0) {
            require(
                abi.decode(returndata, (bool)),
                'SafeERC20: ERC20 operation did not succeed'
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
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
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        require(value == 0, 'UintUtils: hex length insufficient');

        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/contracts/utils/EnumerableSet.sol";

import "../pricer/IPricer.sol";

import "../vendor/IExchangeHelper.sol";

import "./OrderBook.sol";

/**
 * @title Knox Dutch Auction Diamond Storage Library
 */

library AuctionStorage {
    using OrderBook for OrderBook.Index;

    struct InitAuction {
        uint64 epoch;
        uint64 expiry;
        int128 strike64x64;
        uint256 longTokenId;
        uint256 startTime;
        uint256 endTime;
    }

    enum Status {UNINITIALIZED, INITIALIZED, FINALIZED, PROCESSED, CANCELLED}

    struct Auction {
        // status of the auction
        Status status;
        // option expiration timestamp
        uint64 expiry;
        // option strike price
        int128 strike64x64;
        // auction max price
        int128 maxPrice64x64;
        // auction min price
        int128 minPrice64x64;
        // last price paid during the auction
        int128 lastPrice64x64;
        // auction start timestamp
        uint256 startTime;
        // auction end timestamp
        uint256 endTime;
        // auction processed timestamp
        uint256 processedTime;
        // total contracts available
        uint256 totalContracts;
        // total contracts sold
        uint256 totalContractsSold;
        // total unclaimed contracts
        uint256 totalUnclaimedContracts;
        // total premiums collected
        uint256 totalPremiums;
        // option long token id
        uint256 longTokenId;
    }

    struct Layout {
        // percent offset from delta strike
        int128 deltaOffset64x64;
        // minimum order size
        uint256 minSize;
        // mapping of auctions to epoch id (epoch id -> auction)
        mapping(uint64 => Auction) auctions;
        // mapping of order books to epoch id (epoch id -> order book)
        mapping(uint64 => OrderBook.Index) orderbooks;
        // mapping of unique order ids (uoids) to buyer addresses (buyer -> uoid)
        mapping(address => EnumerableSet.UintSet) uoids;
        // ExchangeHelper contract interface
        IExchangeHelper Exchange;
        // Pricer contract interface
        IPricer Pricer;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("knox.contracts.storage.Auction");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /************************************************
     *  VIEW
     ***********************************************/

    /**
     * @notice returns the auction parameters
     * @param epoch epoch id
     * @return auction parameters
     */
    function _getAuction(uint64 epoch) internal view returns (Auction memory) {
        return layout().auctions[epoch];
    }

    /**
     * @notice returns percent delta offset
     * @return percent delta offset as a 64x64 fixed point number
     */
    function _getDeltaOffset64x64() internal view returns (int128) {
        return layout().deltaOffset64x64;
    }

    /**
     * @notice returns the minimum order size
     * @return minimum order size
     */
    function _getMinSize() internal view returns (uint256) {
        return layout().minSize;
    }

    /**
     * @notice returns the order from the auction orderbook
     * @param epoch epoch id
     * @param orderId order id
     * @return order from auction orderbook
     */
    function _getOrderById(uint64 epoch, uint128 orderId)
        internal
        view
        returns (OrderBook.Data memory)
    {
        OrderBook.Index storage orderbook = layout().orderbooks[epoch];
        return orderbook._getOrderById(orderId);
    }

    /**
     * @notice returns the status of the auction
     * @param epoch epoch id
     * @return auction status
     */
    function _getStatus(uint64 epoch)
        internal
        view
        returns (AuctionStorage.Status)
    {
        return layout().auctions[epoch].status;
    }

    /**
     * @notice returns the stored total number of contracts that can be sold during the auction
     * returns 0 if the auction has not started
     * @param epoch epoch id
     * @return total number of contracts which may be sold
     */
    function _getTotalContracts(uint64 epoch) internal view returns (uint256) {
        return layout().auctions[epoch].totalContracts;
    }

    /**
     * @notice returns the total number of contracts sold
     * @param epoch epoch id
     * @return total number of contracts sold
     */
    function _getTotalContractsSold(uint64 epoch)
        internal
        view
        returns (uint256)
    {
        return layout().auctions[epoch].totalContractsSold;
    }

    /************************************************
     * HELPERS
     ***********************************************/

    /**
     * @notice calculates the unique order id
     * @param epoch epoch id
     * @param orderId order id
     * @return unique order id
     */
    function _formatUniqueOrderId(uint64 epoch, uint128 orderId)
        internal
        view
        returns (uint256)
    {
        // uses the first 8 bytes of the contract address to salt uoid
        bytes8 salt = bytes8(bytes20(address(this)));
        return
            (uint256(uint64(salt)) << 192) +
            (uint256(epoch) << 128) +
            uint256(orderId);
    }

    /**
     * @notice derives salt, epoch id, and order id from the unique order id
     * @param uoid unique order id
     * @return salt
     * @return epoch id
     * @return order id
     */
    function _parseUniqueOrderId(uint256 uoid)
        internal
        pure
        returns (
            bytes8,
            uint64,
            uint128
        )
    {
        uint64 salt;
        uint64 epoch;
        uint128 orderId;

        assembly {
            salt := shr(192, uoid)
            epoch := shr(128, uoid)
            orderId := uoid
        }

        return (bytes8(salt), epoch, orderId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/contracts/introspection/IERC165.sol";
import "@solidstate/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@solidstate/contracts/utils/IMulticall.sol";

import "../vendor/IExchangeHelper.sol";

import "./AuctionStorage.sol";
import "./IAuctionEvents.sol";

/**
 * @title Knox Auction Interface
 */

interface IAuction is IAuctionEvents, IERC165, IERC1155Receiver, IMulticall {
    /************************************************
     *  ADMIN
     ***********************************************/

    /**
     * @notice sets the percent offset from delta strike
     * @param newDeltaOffset64x64 new percent offset value as a 64x64 fixed point number
     */
    function setDeltaOffset64x64(int128 newDeltaOffset64x64) external;

    /**
     * @notice sets a new Exchange Helper contract
     * @param newExchangeHelper new Exchange Helper contract address
     */
    function setExchangeHelper(address newExchangeHelper) external;

    /**
     * @notice sets a new minimum order size
     * @param newMinSize new minimum order size
     */
    function setMinSize(uint256 newMinSize) external;

    /**
     * @notice sets the new pricer
     * @dev the pricer contract address must be set during the vault initialization
     * @param newPricer address of the new pricer
     */
    function setPricer(address newPricer) external;

    /************************************************
     *  INITIALIZE AUCTION
     ***********************************************/

    /**
     * @notice initializes a new auction
     * @param initAuction auction parameters
     */
    function initialize(AuctionStorage.InitAuction memory initAuction) external;

    /**
     * @notice sets the auction max/min prices
     * @param epoch epoch id
     */
    function setAuctionPrices(uint64 epoch) external;

    /************************************************
     *  PRICING
     ***********************************************/

    /**
     * @notice returns the last price paid during the auction
     * @param epoch epoch id
     * @return price as 64x64 fixed point number
     */
    function lastPrice64x64(uint64 epoch) external view returns (int128);

    /**
     * @notice calculates the current price using the price curve function
     * @param epoch epoch id
     * @return price as 64x64 fixed point number
     */
    function priceCurve64x64(uint64 epoch) external view returns (int128);

    /**
     * @notice returns the current price established by the price curve if the auction
     * is still ongoing, otherwise the last price paid is returned
     * @param epoch epoch id
     * @return price as 64x64 fixed point number
     */
    function clearingPrice64x64(uint64 epoch) external view returns (int128);

    /************************************************
     *  PURCHASE
     ***********************************************/

    /**
     * @notice adds an order specified by the price and size
     * @dev sent ETH will be wrapped as wETH, sender must approve contract
     * @param epoch epoch id
     * @param price64x64 max price as 64x64 fixed point number
     * @param size amount of contracts
     */
    function addLimitOrder(
        uint64 epoch,
        int128 price64x64,
        uint256 size
    ) external payable;

    /**
     * @notice swaps into the collateral asset and adds an order specified by the price and size
     * @dev sent ETH will be wrapped as wETH, sender must approve contract
     * @param s swap arguments
     * @param epoch epoch id
     * @param price64x64 max price as 64x64 fixed point number
     * @param size amount of contracts
     */
    function swapAndAddLimitOrder(
        IExchangeHelper.SwapArgs calldata s,
        uint64 epoch,
        int128 price64x64,
        uint256 size
    ) external payable;

    /**
     * @notice cancels an order
     * @dev sender must approve contract
     * @param epoch epoch id
     * @param orderId order id
     */
    function cancelLimitOrder(uint64 epoch, uint128 orderId) external;

    /**
     * @notice adds an order specified by size only
     * @dev sent ETH will be wrapped as wETH, sender must approve contract
     * @param epoch epoch id
     * @param size amount of contracts
     * @param maxCost max cost of buyer is willing to pay
     */
    function addMarketOrder(
        uint64 epoch,
        uint256 size,
        uint256 maxCost
    ) external payable;

    /**
     * @notice swaps into the collateral asset and adds an order specified by size only
     * @dev sent ETH will be wrapped as wETH, sender must approve contract
     * @param s swap arguments
     * @param epoch epoch id
     * @param size amount of contracts
     * @param maxCost max cost of buyer is willing to pay
     */
    function swapAndAddMarketOrder(
        IExchangeHelper.SwapArgs calldata s,
        uint64 epoch,
        uint256 size,
        uint256 maxCost
    ) external payable;

    /************************************************
     *  WITHDRAW
     ***********************************************/

    /**
     * @notice withdraws any amount(s) owed to the buyer (fill and/or refund)
     * @param epoch epoch id
     */
    function withdraw(uint64 epoch) external;

    /**
     * @notice calculates amount(s) owed to the buyer
     * @param epoch epoch id
     * @return amount refunded
     * @return amount filled
     */
    function previewWithdraw(uint64 epoch) external returns (uint256, uint256);

    /**
     * @notice calculates amount(s) owed to the buyer
     * @param epoch epoch id
     * @param buyer address of buyer
     * @return amount refunded
     * @return amount filled
     */
    function previewWithdraw(uint64 epoch, address buyer)
        external
        returns (uint256, uint256);

    /************************************************
     *  FINALIZE AUCTION
     ***********************************************/

    /**
     * @notice determines whether the auction has reached finality. the end criteria for the auction are
     * met if the auction has reached 100% utilization or the end time has been exceeded.
     * @param epoch epoch id
     */
    function finalizeAuction(uint64 epoch) external;

    /**
     * @notice transfers premiums and updates auction state
     * @param epoch epoch id
     * @return amount in premiums paid during auction
     * @return total number of contracts sold
     */
    function processAuction(uint64 epoch) external returns (uint256, uint256);

    /************************************************
     *  VIEW
     ***********************************************/

    /**
     * @notice returns the auction parameters
     * @param epoch epoch id
     * @return auction parameters
     */
    function getAuction(uint64 epoch)
        external
        view
        returns (AuctionStorage.Auction memory);

    /**
     * @notice returns percent delta offset
     * @return percent delta offset as a 64x64 fixed point number
     */
    function getDeltaOffset64x64() external view returns (int128);

    /**
     * @notice returns the minimum order size
     * @return minimum order size
     */
    function getMinSize() external view returns (uint256);

    /**
     * @notice returns the order from the auction orderbook
     * @param epoch epoch id
     * @param orderId order id
     * @return order from auction orderbook
     */
    function getOrderById(uint64 epoch, uint128 orderId)
        external
        view
        returns (OrderBook.Data memory);

    /**
     * @notice returns the status of the auction
     * @param epoch epoch id
     * @return auction status
     */
    function getStatus(uint64 epoch)
        external
        view
        returns (AuctionStorage.Status);

    /**
     * @notice returns the stored total number of contracts that can be sold during the auction
     * returns 0 if the auction has not started
     * @param epoch epoch id
     * @return total number of contracts which may be sold
     */
    function getTotalContracts(uint64 epoch) external view returns (uint256);

    /**
     * @notice returns the total number of contracts sold
     * @param epoch epoch id
     * @return total number of contracts sold
     */
    function getTotalContractsSold(uint64 epoch)
        external
        view
        returns (uint256);

    /**
     * @notice returns the active unique order ids
     * @param buyer address of buyer
     * @return array of unique order ids
     */
    function getUniqueOrderIds(address buyer)
        external
        view
        returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AuctionStorage.sol";

/**
 * @title Knox Auction Events Interface
 */

interface IAuctionEvents {
    /**
     * @notice emitted when the auction max/min prices have been set
     * @param epoch epoch id
     * @param strike64x64 strike price as a 64x64 fixed point number
     * @param offsetStrike64x64 offset strike price as a 64x64 fixed point number
     * @param spot64x64 spot price as a 64x64 fixed point number
     * @param maxPrice64x64 max price as a 64x64 fixed point number
     * @param minPrice64x64 min price as a 64x64 fixed point number
     */
    event AuctionPricesSet(
        uint64 indexed epoch,
        int128 strike64x64,
        int128 offsetStrike64x64,
        int128 spot64x64,
        int128 maxPrice64x64,
        int128 minPrice64x64
    );

    /**
     * @notice emitted when the exchange auction status is updated
     * @param epoch epoch id
     * @param status auction status
     */
    event AuctionStatusSet(uint64 indexed epoch, AuctionStorage.Status status);

    /**
     * @notice emitted when the delta offset is updated
     * @param oldDeltaOffset previous delta offset
     * @param newDeltaOffset new delta offset
     * @param caller address of admin
     */
    event DeltaOffsetSet(
        int128 oldDeltaOffset,
        int128 newDeltaOffset,
        address caller
    );

    /**
     * @notice emitted when the exchange helper contract address is updated
     * @param oldExchangeHelper previous exchange helper address
     * @param newExchangeHelper new exchange helper address
     * @param caller address of admin
     */
    event ExchangeHelperSet(
        address oldExchangeHelper,
        address newExchangeHelper,
        address caller
    );

    /**
     * @notice emitted when an external function reverts
     * @param message error message
     */
    event Log(string message);

    /**
     * @notice emitted when the minimum order size is updated
     * @param oldMinSize previous minimum order size
     * @param newMinSize new minimum order size
     * @param caller address of admin
     */
    event MinSizeSet(uint256 oldMinSize, uint256 newMinSize, address caller);

    /**
     * @notice emitted when a market or limit order has been placed
     * @param epoch epoch id
     * @param orderId order id
     * @param buyer address of buyer
     * @param price64x64 price paid as a 64x64 fixed point number
     * @param size quantity of options purchased
     * @param isLimitOrder true if order is a limit order
     */
    event OrderAdded(
        uint64 indexed epoch,
        uint128 orderId,
        address buyer,
        int128 price64x64,
        uint256 size,
        bool isLimitOrder
    );

    /**
     * @notice emitted when a limit order has been cancelled
     * @param epoch epoch id
     * @param orderId order id
     * @param buyer address of buyer
     */
    event OrderCanceled(uint64 indexed epoch, uint128 orderId, address buyer);

    /**
     * @notice emitted when an order (filled or unfilled) is withdrawn
     * @param epoch epoch id
     * @param buyer address of buyer
     * @param refund amount sent back to the buyer as a result of an overpayment
     * @param fill amount in long token contracts sent to the buyer
     */
    event OrderWithdrawn(
        uint64 indexed epoch,
        address buyer,
        uint256 refund,
        uint256 fill
    );

    /**
     * @notice emitted when the pricer contract address is updated
     * @param oldPricer previous pricer address
     * @param newPricer new pricer address
     * @param caller address of admin
     */
    event PricerSet(address oldPricer, address newPricer, address caller);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Knox Auction Order Book Library
 * @dev based on PiperMerriam's Grove v0.3
 * https://github.com/pipermerriam/ethereum-grove
 */

library OrderBook {
    struct Index {
        uint256 head;
        uint256 length;
        uint256 root;
        mapping(uint256 => Order) orders;
    }

    struct Order {
        Data data;
        uint256 parent;
        uint256 left;
        uint256 right;
        uint256 height;
    }

    struct Data {
        uint256 id;
        int128 price64x64;
        uint256 size;
        address buyer;
    }

    /// @dev Retrieve the highest bid in the order book.
    /// @param index The index that the order is part of.
    function _head(Index storage index) internal view returns (uint256) {
        return index.head;
    }

    /// @dev Retrieve the number of bids in the order book.
    /// @param index The index that the order is part of.
    function _length(Index storage index) internal view returns (uint256) {
        return index.length;
    }

    /// @dev Retrieve the id, price, size, and buyer for the order.
    /// @param index The index that the order is part of.
    /// @param id The id for the order to be looked up.
    function _getOrderById(Index storage index, uint256 id)
        internal
        view
        returns (Data memory)
    {
        return index.orders[id].data;
    }

    /// @dev Returns the previous bid in descending order.
    /// @param index The index that the order is part of.
    /// @param id The id for the order to be looked up.
    function _getPreviousOrder(Index storage index, uint256 id)
        internal
        view
        returns (uint256)
    {
        Order storage currentOrder = index.orders[id];

        if (currentOrder.data.id == 0) {
            // Unknown order, just return 0;
            return 0;
        }

        Order memory child;

        if (currentOrder.left != 0) {
            // Trace left to latest child in left tree.
            child = index.orders[currentOrder.left];

            while (child.right != 0) {
                child = index.orders[child.right];
            }
            return child.data.id;
        }

        if (currentOrder.parent != 0) {
            // Now we trace back up through parent relationships, looking
            // for a link where the child is the right child of it's
            // parent.
            Order storage parent = index.orders[currentOrder.parent];
            child = currentOrder;

            while (true) {
                if (parent.right == child.data.id) {
                    return parent.data.id;
                }

                if (parent.parent == 0) {
                    break;
                }
                child = parent;
                parent = index.orders[parent.parent];
            }
        }

        // This is the first order, and has no previous order.
        return 0;
    }

    /// @dev Returns the next bid in descending order.
    /// @param index The index that the order is part of.
    /// @param id The id for the order to be looked up.
    function _getNextOrder(Index storage index, uint256 id)
        internal
        view
        returns (uint256)
    {
        Order storage currentOrder = index.orders[id];

        if (currentOrder.data.id == 0) {
            // Unknown order, just return 0;
            return 0;
        }

        Order memory child;

        if (currentOrder.right != 0) {
            // Trace right to earliest child in right tree.
            child = index.orders[currentOrder.right];

            while (child.left != 0) {
                child = index.orders[child.left];
            }
            return child.data.id;
        }

        if (currentOrder.parent != 0) {
            // if the order is the left child of it's parent, then the
            // parent is the next one.
            Order storage parent = index.orders[currentOrder.parent];
            child = currentOrder;

            while (true) {
                if (parent.left == child.data.id) {
                    return parent.data.id;
                }

                if (parent.parent == 0) {
                    break;
                }
                child = parent;
                parent = index.orders[parent.parent];
            }

            // Now we need to trace all the way up checking to see if any parent is the
        }

        // This is the final order.
        return 0;
    }

    /// @dev Updates or Inserts the id into the index at its appropriate location based on the price provided.
    /// @param index The index that the order is part of.
    // / @param id The unique identifier of the data element the index order will represent.
    /// @param price64x64 The unit price specified by the buyer.
    /// @param size The size specified by the buyer.
    /// @param buyer The buyers wallet address.
    function _insert(
        Index storage index,
        int128 price64x64,
        uint256 size,
        address buyer
    ) internal returns (uint256) {
        index.length = index.length + 1;
        uint256 id = index.length;

        Data memory data = _getOrderById(index, index.head);

        int128 highestPricePaid = data.price64x64;

        if (index.head == 0 || price64x64 > highestPricePaid) {
            index.head = id;
        }

        if (index.orders[id].data.id == id) {
            // A order with this id already exists.  If the price is
            // the same, then just return early, otherwise, remove it
            // and reinsert it.
            if (index.orders[id].data.price64x64 == price64x64) {
                return id;
            }
            _remove(index, id);
        }

        uint256 previousOrderId = 0;

        if (index.root == 0) {
            index.root = id;
        }
        Order storage currentOrder = index.orders[index.root];

        // Do insertion
        while (true) {
            if (currentOrder.data.id == 0) {
                // This is a new unpopulated order.
                currentOrder.data.id = id;
                currentOrder.parent = previousOrderId;
                currentOrder.data.price64x64 = price64x64;
                currentOrder.data.size = size;
                currentOrder.data.buyer = buyer;
                break;
            }

            // Set the previous order id.
            previousOrderId = currentOrder.data.id;

            // The new order belongs in the right subtree
            if (price64x64 <= currentOrder.data.price64x64) {
                if (currentOrder.right == 0) {
                    currentOrder.right = id;
                }
                currentOrder = index.orders[currentOrder.right];
                continue;
            }

            // The new order belongs in the left subtree.
            if (currentOrder.left == 0) {
                currentOrder.left = id;
            }
            currentOrder = index.orders[currentOrder.left];
        }

        // Rebalance the tree
        _rebalanceTree(index, currentOrder.data.id);

        return id;
    }

    /// @dev Remove the order for the given unique identifier from the index.
    /// @param index The index that should be removed
    /// @param id The unique identifier of the data element to remove.
    function _remove(Index storage index, uint256 id) internal returns (bool) {
        if (id == index.head) {
            index.head = _getNextOrder(index, id);
        }

        Order storage replacementOrder;
        Order storage parent;
        Order storage child;
        uint256 rebalanceOrigin;

        Order storage orderToDelete = index.orders[id];

        if (orderToDelete.data.id != id) {
            // The id does not exist in the tree.
            return false;
        }

        if (orderToDelete.left != 0 || orderToDelete.right != 0) {
            // This order is not a leaf order and thus must replace itself in
            // it's tree by either the previous or next order.
            if (orderToDelete.left != 0) {
                // This order is guaranteed to not have a right child.
                replacementOrder = index.orders[
                    _getPreviousOrder(index, orderToDelete.data.id)
                ];
            } else {
                // This order is guaranteed to not have a left child.
                replacementOrder = index.orders[
                    _getNextOrder(index, orderToDelete.data.id)
                ];
            }
            // The replacementOrder is guaranteed to have a parent.
            parent = index.orders[replacementOrder.parent];

            // Keep note of the location that our tree rebalancing should
            // start at.
            rebalanceOrigin = replacementOrder.data.id;

            // Join the parent of the replacement order with any subtree of
            // the replacement order.  We can guarantee that the replacement
            // order has at most one subtree because of how getNextOrder and
            // getPreviousOrder are used.
            if (parent.left == replacementOrder.data.id) {
                parent.left = replacementOrder.right;
                if (replacementOrder.right != 0) {
                    child = index.orders[replacementOrder.right];
                    child.parent = parent.data.id;
                }
            }
            if (parent.right == replacementOrder.data.id) {
                parent.right = replacementOrder.left;
                if (replacementOrder.left != 0) {
                    child = index.orders[replacementOrder.left];
                    child.parent = parent.data.id;
                }
            }

            // Now we replace the orderToDelete with the replacementOrder.
            // This includes parent/child relationships for all of the
            // parent, the left child, and the right child.
            replacementOrder.parent = orderToDelete.parent;
            if (orderToDelete.parent != 0) {
                parent = index.orders[orderToDelete.parent];
                if (parent.left == orderToDelete.data.id) {
                    parent.left = replacementOrder.data.id;
                }
                if (parent.right == orderToDelete.data.id) {
                    parent.right = replacementOrder.data.id;
                }
            } else {
                // If the order we are deleting is the root order update the
                // index root order pointer.
                index.root = replacementOrder.data.id;
            }

            replacementOrder.left = orderToDelete.left;
            if (orderToDelete.left != 0) {
                child = index.orders[orderToDelete.left];
                child.parent = replacementOrder.data.id;
            }

            replacementOrder.right = orderToDelete.right;
            if (orderToDelete.right != 0) {
                child = index.orders[orderToDelete.right];
                child.parent = replacementOrder.data.id;
            }
        } else if (orderToDelete.parent != 0) {
            // The order being deleted is a leaf order so we only erase it's
            // parent linkage.
            parent = index.orders[orderToDelete.parent];

            if (parent.left == orderToDelete.data.id) {
                parent.left = 0;
            }
            if (parent.right == orderToDelete.data.id) {
                parent.right = 0;
            }

            // keep note of where the rebalancing should begin.
            rebalanceOrigin = parent.data.id;
        } else {
            // This is both a leaf order and the root order, so we need to
            // unset the root order pointer.
            index.root = 0;
        }

        // Now we zero out all of the fields on the orderToDelete.
        orderToDelete.data.id = 0;
        orderToDelete.data.price64x64 = 0;
        orderToDelete.data.size = 0;
        orderToDelete.data.buyer = 0x0000000000000000000000000000000000000000;
        orderToDelete.parent = 0;
        orderToDelete.left = 0;
        orderToDelete.right = 0;
        orderToDelete.height = 0;

        // Walk back up the tree rebalancing
        if (rebalanceOrigin != 0) {
            _rebalanceTree(index, rebalanceOrigin);
        }

        return true;
    }

    function _rebalanceTree(Index storage index, uint256 id) private {
        // Trace back up rebalancing the tree and updating heights as
        // needed..
        Order storage currentOrder = index.orders[id];

        while (true) {
            int256 balanceFactor =
                _getBalanceFactor(index, currentOrder.data.id);

            if (balanceFactor == 2) {
                // Right rotation (tree is heavy on the left)
                if (_getBalanceFactor(index, currentOrder.left) == -1) {
                    // The subtree is leaning right so it need to be
                    // rotated left before the current order is rotated
                    // right.
                    _rotateLeft(index, currentOrder.left);
                }
                _rotateRight(index, currentOrder.data.id);
            }

            if (balanceFactor == -2) {
                // Left rotation (tree is heavy on the right)
                if (_getBalanceFactor(index, currentOrder.right) == 1) {
                    // The subtree is leaning left so it need to be
                    // rotated right before the current order is rotated
                    // left.
                    _rotateRight(index, currentOrder.right);
                }
                _rotateLeft(index, currentOrder.data.id);
            }

            if ((-1 <= balanceFactor) && (balanceFactor <= 1)) {
                _updateOrderHeight(index, currentOrder.data.id);
            }

            if (currentOrder.parent == 0) {
                // Reached the root which may be new due to tree
                // rotation, so set it as the root and then break.
                break;
            }

            currentOrder = index.orders[currentOrder.parent];
        }
    }

    function _getBalanceFactor(Index storage index, uint256 id)
        private
        view
        returns (int256)
    {
        Order storage order = index.orders[id];
        return
            int256(index.orders[order.left].height) -
            int256(index.orders[order.right].height);
    }

    function _updateOrderHeight(Index storage index, uint256 id) private {
        Order storage order = index.orders[id];
        order.height =
            _max(
                index.orders[order.left].height,
                index.orders[order.right].height
            ) +
            1;
    }

    function _max(uint256 a, uint256 b) private pure returns (uint256) {
        if (a >= b) {
            return a;
        }
        return b;
    }

    function _rotateLeft(Index storage index, uint256 id) private {
        Order storage originalRoot = index.orders[id];

        if (originalRoot.right == 0) {
            // Cannot rotate left if there is no right originalRoot to rotate into
            // place.
            revert();
        }

        // The right child is the new root, so it gets the original
        // `originalRoot.parent` as it's parent.
        Order storage newRoot = index.orders[originalRoot.right];
        newRoot.parent = originalRoot.parent;

        // The original root needs to have it's right child nulled out.
        originalRoot.right = 0;

        if (originalRoot.parent != 0) {
            // If there is a parent order, it needs to now point downward at
            // the newRoot which is rotating into the place where `order` was.
            Order storage parent = index.orders[originalRoot.parent];

            // figure out if we're a left or right child and have the
            // parent point to the new order.
            if (parent.left == originalRoot.data.id) {
                parent.left = newRoot.data.id;
            }
            if (parent.right == originalRoot.data.id) {
                parent.right = newRoot.data.id;
            }
        }

        if (newRoot.left != 0) {
            // If the new root had a left child, that moves to be the
            // new right child of the original root order
            Order storage leftChild = index.orders[newRoot.left];
            originalRoot.right = leftChild.data.id;
            leftChild.parent = originalRoot.data.id;
        }

        // Update the newRoot's left order to point at the original order.
        originalRoot.parent = newRoot.data.id;
        newRoot.left = originalRoot.data.id;

        if (newRoot.parent == 0) {
            index.root = newRoot.data.id;
        }

        _updateOrderHeight(index, originalRoot.data.id);
        _updateOrderHeight(index, newRoot.data.id);
    }

    function _rotateRight(Index storage index, uint256 id) private {
        Order storage originalRoot = index.orders[id];

        if (originalRoot.left == 0) {
            // Cannot rotate right if there is no left order to rotate into
            // place.
            revert();
        }

        // The left child is taking the place of order, so we update it's
        // parent to be the original parent of the order.
        Order storage newRoot = index.orders[originalRoot.left];
        newRoot.parent = originalRoot.parent;

        // Null out the originalRoot.left
        originalRoot.left = 0;

        if (originalRoot.parent != 0) {
            // If the order has a parent, update the correct child to point
            // at the newRoot now.
            Order storage parent = index.orders[originalRoot.parent];

            if (parent.left == originalRoot.data.id) {
                parent.left = newRoot.data.id;
            }
            if (parent.right == originalRoot.data.id) {
                parent.right = newRoot.data.id;
            }
        }

        if (newRoot.right != 0) {
            Order storage rightChild = index.orders[newRoot.right];
            originalRoot.left = newRoot.right;
            rightChild.parent = originalRoot.data.id;
        }

        // Update the new root's right order to point to the original order.
        originalRoot.parent = newRoot.data.id;
        newRoot.right = originalRoot.data.id;

        if (newRoot.parent == 0) {
            index.root = newRoot.data.id;
        }

        // Recompute heights.
        _updateOrderHeight(index, originalRoot.data.id);
        _updateOrderHeight(index, newRoot.data.id);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title Knox Pricer Interface
 */

interface IPricer {
    /**
     * @notice gets the latest price of the underlying denominated in the base
     * @return price of underlying asset as 64x64 fixed point number
     */
    function latestAnswer64x64() external view returns (int128);

    /**
     * @notice calculates the time remaining until maturity
     * @param expiry the expiry date as UNIX timestamp
     * @return time remaining until maturity
     */
    function getTimeToMaturity64x64(uint64 expiry)
        external
        view
        returns (int128);

    /**
     * @notice gets the annualized volatility of the pool pair
     * @param spot64x64 spot price of the underlying as 64x64 fixed point number
     * @param strike64x64 strike price of the option as 64x64 fixed point number
     * @param timeToMaturity64x64 time remaining until maturity as a 64x64 fixed point number
     * @return annualized volatility as 64x64 fixed point number
     */
    function getAnnualizedVolatility64x64(
        int128 spot64x64,
        int128 strike64x64,
        int128 timeToMaturity64x64
    ) external view returns (int128);

    /**
     * @notice gets the option price using the Black-Scholes model
     * @param spot64x64 spot price of the underlying as 64x64 fixed point number
     * @param strike64x64 strike price of the option as 64x64 fixed point number
     * @param timeToMaturity64x64 time remaining until maturity as a 64x64 fixed point number
     * @param isCall option type, true if call option
     * @return price of the option denominated in the base as 64x64 fixed point number
     */
    function getBlackScholesPrice64x64(
        int128 spot64x64,
        int128 strike64x64,
        int128 timeToMaturity64x64,
        bool isCall
    ) external view returns (int128);

    /**
     * @notice calculates the delta strike price
     * @param isCall option type, true if call option
     * @param expiry the expiry date as UNIX timestamp
     * @param delta64x64 option delta as 64x64 fixed point number
     * @return delta strike price as 64x64 fixed point number
     */
    function getDeltaStrikePrice64x64(
        bool isCall,
        uint64 expiry,
        int128 delta64x64
    ) external view returns (int128);

    /**
     * @notice rounds a value to the floor or ceiling depending on option type
     * @param isCall option type, true if call option
     * @param n input value
     * @return rounded value as 64x64 fixed point number
     */
    function snapToGrid64x64(bool isCall, int128 n)
        external
        view
        returns (int128);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/contracts/introspection/IERC165.sol";
import "@solidstate/contracts/token/ERC1155/IERC1155.sol";
import "@solidstate/contracts/token/ERC1155/enumerable/IERC1155Enumerable.sol";
import "@solidstate/contracts/utils/IMulticall.sol";

import "../vendor/IExchangeHelper.sol";

import "./IQueueEvents.sol";

/**
 * @title Knox Queue Interface
 */

interface IQueue is
    IERC165,
    IERC1155,
    IERC1155Enumerable,
    IMulticall,
    IQueueEvents
{
    /************************************************
     *  ADMIN
     ***********************************************/

    /**
     * @notice sets a new max TVL for deposits
     * @param newMaxTVL is the new TVL limit for deposits
     */
    function setMaxTVL(uint256 newMaxTVL) external;

    /**
     * @notice sets a new Exchange Helper contract
     * @param newExchangeHelper is the new Exchange Helper contract address
     */
    function setExchangeHelper(address newExchangeHelper) external;

    /************************************************
     *  DEPOSIT
     ***********************************************/

    /**
     * @notice deposits collateral asset
     * @dev sent ETH will be wrapped as wETH, sender must approve contract
     * @param amount total collateral deposited
     */
    function deposit(uint256 amount) external payable;

    /**
     * @notice swaps into the collateral asset and deposits the proceeds
     * @dev sent ETH will be wrapped as wETH, sender must approve contract
     * @param s swap arguments
     */
    function swapAndDeposit(IExchangeHelper.SwapArgs calldata s)
        external
        payable;

    /************************************************
     *  CANCEL
     ***********************************************/

    /**
     * @notice cancels deposit, refunds collateral asset
     * @dev cancellation must be made within the same epoch as the deposit
     * @param amount total collateral which will be withdrawn
     */
    function cancel(uint256 amount) external;

    /************************************************
     *  REDEEM
     ***********************************************/

    /**
     * @notice exchanges claim token for vault shares
     * @param tokenId claim token id
     */
    function redeem(uint256 tokenId) external;

    /**
     * @notice exchanges claim token for vault shares
     * @param tokenId claim token id
     * @param receiver vault share recipient
     */
    function redeem(uint256 tokenId, address receiver) external;

    /**
     * @notice exchanges claim token for vault shares
     * @param tokenId claim token id
     * @param receiver vault share recipient
     * @param owner claim token holder
     */
    function redeem(
        uint256 tokenId,
        address receiver,
        address owner
    ) external;

    /**
     * @notice exchanges all claim tokens for vault shares
     */
    function redeemMax() external;

    /**
     * @notice exchanges all claim tokens for vault shares
     * @param receiver vault share recipient
     */
    function redeemMax(address receiver) external;

    /**
     * @notice exchanges all claim tokens for vault shares
     * @param receiver vault share recipient
     * @param owner claim token holder
     */
    function redeemMax(address receiver, address owner) external;

    /************************************************
     *  INITIALIZE EPOCH
     ***********************************************/

    /**
     * @notice transfers deposited collateral to vault, calculates the price per share
     */
    function processDeposits() external;

    /************************************************
     *  VIEW
     ***********************************************/

    /**
     * @notice returns the current claim token id
     * @return claim token id
     */
    function getCurrentTokenId() external view returns (uint256);

    /**
     * @notice returns the current epoch of the queue
     * @return epoch id
     */
    function getEpoch() external view returns (uint64);

    /**
     * @notice returns the max total value locked of the vault
     * @return max total value
     */
    function getMaxTVL() external view returns (uint256);

    /**
     * @notice returns the price per share for a given claim token id
     * @param tokenId claim token id
     * @return price per share
     */
    function getPricePerShare(uint256 tokenId) external view returns (uint256);

    /**
     * @notice returns unredeemed vault shares available for a given claim token
     * @param tokenId claim token id
     * @return unredeemed vault share amount
     */
    function previewUnredeemed(uint256 tokenId) external view returns (uint256);

    /**
     * @notice returns unredeemed vault shares available for a given claim token
     * @param tokenId claim token id
     * @param owner claim token holder
     * @return unredeemed vault share amount
     */
    function previewUnredeemed(uint256 tokenId, address owner)
        external
        view
        returns (uint256);

    /**
     * @notice returns unredeemed vault shares available for all claim tokens
     * @param owner claim token holder
     * @return unredeemed vault share amount
     */
    function previewMaxUnredeemed(address owner)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Knox Queue Events Interface
 */

interface IQueueEvents {
    /**
     * @notice emitted when a deposit is cancelled
     * @param epoch epoch id
     * @param depositer address of depositer
     * @param amount quantity of collateral assets removed from queue
     */
    event Cancel(uint64 indexed epoch, address depositer, uint256 amount);

    /**
     * @notice emitted when a deposit is made
     * @param epoch epoch id
     * @param depositer address of depositer
     * @param amount quantity of collateral assets added to queue
     */
    event Deposit(uint64 indexed epoch, address depositer, uint256 amount);

    /**
     * @notice emitted when the exchange helper contract address is updated
     * @param oldExchangeHelper previous exchange helper address
     * @param newExchangeHelper new exchange helper address
     * @param caller address of admin
     */
    event ExchangeHelperSet(
        address oldExchangeHelper,
        address newExchangeHelper,
        address caller
    );

    /**
     * @notice emitted when the max TVL is updated
     * @param epoch epoch id
     * @param oldMaxTVL previous max TVL amount
     * @param newMaxTVL new max TVL amount
     * @param caller address of admin
     */
    event MaxTVLSet(
        uint64 indexed epoch,
        uint256 oldMaxTVL,
        uint256 newMaxTVL,
        address caller
    );

    /**
     * @notice emitted when vault shares are redeemed
     * @param epoch epoch id
     * @param receiver address of receiver
     * @param depositer address of depositer
     * @param shares quantity of vault shares sent to receiver
     */
    event Redeem(
        uint64 indexed epoch,
        address receiver,
        address depositer,
        uint256 shares
    );

    /**
     * @notice emitted when the queued deposits are processed
     * @param epoch epoch id
     * @param deposits quantity of collateral assets processed
     * @param pricePerShare vault price per share calculated
     * @param shares quantity of vault shares sent to queue contract
     * @param claimTokenSupply quantity of claim tokens in supply
     */
    event ProcessQueuedDeposits(
        uint64 indexed epoch,
        uint256 deposits,
        uint256 pricePerShare,
        uint256 shares,
        uint256 claimTokenSupply
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/contracts/introspection/ERC165Storage.sol";
import "@solidstate/contracts/token/ERC1155/base/ERC1155Base.sol";
import "@solidstate/contracts/token/ERC1155/enumerable/ERC1155Enumerable.sol";
import "@solidstate/contracts/utils/Multicall.sol";
import "@solidstate/contracts/utils/ReentrancyGuard.sol";

import "./IQueue.sol";
import "./QueueInternal.sol";

/**
 * @title Knox Queue Contract
 * @dev deployed standalone and referenced by QueueProxy
 */

contract Queue is
    ERC1155Base,
    ERC1155Enumerable,
    IQueue,
    Multicall,
    QueueInternal,
    ReentrancyGuard
{
    using ERC165Storage for ERC165Storage.Layout;
    using QueueStorage for QueueStorage.Layout;
    using SafeERC20 for IERC20;

    constructor(
        bool isCall,
        address pool,
        address vault,
        address weth
    ) QueueInternal(isCall, pool, vault, weth) {}

    /************************************************
     *  SAFETY
     ***********************************************/

    /**
     * @notice pauses the vault during an emergency preventing deposits and borrowing.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice unpauses the vault during following an emergency allowing deposits and borrowing.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /************************************************
     *  ADMIN
     ***********************************************/

    /**
     * @inheritdoc IQueue
     */
    function setMaxTVL(uint256 newMaxTVL) external onlyOwner {
        QueueStorage.Layout storage l = QueueStorage.layout();
        require(newMaxTVL > 0, "value exceeds minimum");
        emit MaxTVLSet(l.epoch, l.maxTVL, newMaxTVL, msg.sender);
        l.maxTVL = newMaxTVL;
    }

    /**
     * @inheritdoc IQueue
     */
    function setExchangeHelper(address newExchangeHelper) external onlyOwner {
        QueueStorage.Layout storage l = QueueStorage.layout();
        require(newExchangeHelper != address(0), "address not provided");
        require(
            newExchangeHelper != address(l.Exchange),
            "new address equals old"
        );

        emit ExchangeHelperSet(
            address(l.Exchange),
            newExchangeHelper,
            msg.sender
        );

        l.Exchange = IExchangeHelper(newExchangeHelper);
    }

    /************************************************
     *  DEPOSIT
     ***********************************************/

    /**
     * @inheritdoc IQueue
     */
    function deposit(uint256 amount)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        QueueStorage.Layout storage l = QueueStorage.layout();
        uint256 credited = _wrapNativeToken(amount);
        // an approve() by the msg.sender is required beforehand
        ERC20.safeTransferFrom(msg.sender, address(this), amount - credited);
        _deposit(l, amount);
    }

    /**
     * @inheritdoc IQueue
     */
    function swapAndDeposit(IExchangeHelper.SwapArgs calldata s)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        QueueStorage.Layout storage l = QueueStorage.layout();
        uint256 credited = _swapForPoolTokens(l.Exchange, s, address(ERC20));
        _deposit(l, credited);
    }

    /************************************************
     *  CANCEL
     ***********************************************/

    /**
     * @inheritdoc IQueue
     */
    function cancel(uint256 amount) external nonReentrant {
        uint256 currentTokenId = QueueStorage._getCurrentTokenId();
        // burns the callers claim token
        _burn(msg.sender, currentTokenId, amount);
        // refunds the callers deposit
        ERC20.safeTransfer(msg.sender, amount);
        uint64 epoch = QueueStorage._getEpoch();
        emit Cancel(epoch, msg.sender, amount);
    }

    /************************************************
     *  REDEEM
     ***********************************************/

    /**
     * @inheritdoc IQueue
     */
    function redeem(uint256 tokenId) external nonReentrant {
        _redeem(tokenId, msg.sender, msg.sender);
    }

    /**
     * @inheritdoc IQueue
     */
    function redeem(uint256 tokenId, address receiver) external nonReentrant {
        _redeem(tokenId, receiver, msg.sender);
    }

    /**
     * @inheritdoc IQueue
     */
    function redeem(
        uint256 tokenId,
        address receiver,
        address owner
    ) external nonReentrant {
        require(
            owner == msg.sender || isApprovedForAll(owner, msg.sender),
            "ERC1155: caller is not owner nor approved"
        );

        _redeem(tokenId, receiver, owner);
    }

    /**
     * @inheritdoc IQueue
     */
    function redeemMax() external nonReentrant {
        _redeemMax(msg.sender, msg.sender);
    }

    function redeemMax(address receiver) external nonReentrant {
        _redeemMax(receiver, msg.sender);
    }

    /**
     * @inheritdoc IQueue
     */
    function redeemMax(address receiver, address owner) external nonReentrant {
        require(
            owner == msg.sender || isApprovedForAll(owner, msg.sender),
            "ERC1155: caller is not owner nor approved"
        );

        _redeemMax(receiver, owner);
    }

    /************************************************
     *  INITIALIZE EPOCH
     ***********************************************/

    /**
     * @inheritdoc IQueue
     */
    function processDeposits() external onlyVault {
        uint256 deposits = ERC20.balanceOf(address(this));
        ERC20.approve(address(Vault), deposits);
        // the queue deposits their entire balance into the vault at the end of each epoch
        uint256 shares = Vault.deposit(deposits, address(this));

        // the shares returned by the vault represent a pro-rata share of the vault tokens. these
        // shares are used to calculate a price-per-share based on the supply of claim tokens for
        // that epoch. the price-per-share is used as an exchange rate of claim tokens to vault
        // shares when a user withdraws or redeems.
        uint256 currentTokenId = QueueStorage._getCurrentTokenId();
        uint256 claimTokenSupply = _totalSupply(currentTokenId);
        uint256 pricePerShare = ONE_SHARE;

        if (shares <= 0) {
            pricePerShare = 0;
        } else if (claimTokenSupply > 0) {
            pricePerShare = (pricePerShare * shares) / claimTokenSupply;
        }

        QueueStorage.Layout storage l = QueueStorage.layout();

        // the price-per-share can be queried if the claim token id is provided
        l.pricePerShare[currentTokenId] = pricePerShare;

        // increment the epoch id
        l.epoch = l.epoch + 1;

        emit ProcessQueuedDeposits(
            l.epoch,
            deposits,
            pricePerShare,
            shares,
            claimTokenSupply
        );
    }

    /************************************************
     *  VIEW
     ***********************************************/

    /**
     * @inheritdoc IQueue
     */
    function getCurrentTokenId() external view returns (uint256) {
        return QueueStorage._getCurrentTokenId();
    }

    /**
     * @inheritdoc IQueue
     */
    function getEpoch() external view returns (uint64) {
        return QueueStorage._getEpoch();
    }

    /**
     * @inheritdoc IQueue
     */
    function getMaxTVL() external view returns (uint256) {
        return QueueStorage._getMaxTVL();
    }

    /**
     * @inheritdoc IQueue
     */
    function getPricePerShare(uint256 tokenId) external view returns (uint256) {
        return QueueStorage._getPricePerShare(tokenId);
    }

    /**
     * @inheritdoc IQueue
     */
    function previewUnredeemed(uint256 tokenId)
        external
        view
        returns (uint256)
    {
        return _previewUnredeemed(tokenId, msg.sender);
    }

    /**
     * @inheritdoc IQueue
     */
    function previewUnredeemed(uint256 tokenId, address owner)
        external
        view
        returns (uint256)
    {
        return _previewUnredeemed(tokenId, owner);
    }

    /**
     * @inheritdoc IQueue
     */
    function previewMaxUnredeemed(address owner)
        external
        view
        returns (uint256)
    {
        uint256 unredeemed;
        uint256[] memory tokenIds = _tokensByAccount(owner);

        for (uint256 i; i < tokenIds.length; i++) {
            unredeemed += _previewUnredeemed(tokenIds[i], owner);
        }

        return unredeemed;
    }

    /************************************************
     *  ERC165 SUPPORT
     ***********************************************/

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool)
    {
        return ERC165Storage.layout().isSupportedInterface(interfaceId);
    }

    /************************************************
     *  ERC1155 OVERRIDES
     ***********************************************/

    /**
     * @notice ERC1155 hook, called before all transfers including mint and burn
     * @dev function should be overridden and new implementation must call super
     * @dev called for both single and batch transfers
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
        override(QueueInternal, ERC1155BaseInternal, ERC1155EnumerableInternal)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/contracts/access/ownable/OwnableInternal.sol";
import "@solidstate/contracts/security/PausableInternal.sol";
import "@solidstate/contracts/token/ERC20/IERC20.sol";
import "@solidstate/contracts/token/ERC1155/base/ERC1155BaseInternal.sol";
import "@solidstate/contracts/token/ERC1155/enumerable/ERC1155EnumerableInternal.sol";
import "@solidstate/contracts/utils/IWETH.sol";
import "@solidstate/contracts/utils/SafeERC20.sol";

import "../vendor/IPremiaPool.sol";

import "../vault/IVault.sol";

import "./IQueueEvents.sol";
import "./QueueStorage.sol";

/**
 * @title Knox Queue Internal Contract
 */

contract QueueInternal is
    ERC1155BaseInternal,
    ERC1155EnumerableInternal,
    IQueueEvents,
    OwnableInternal,
    PausableInternal
{
    using QueueStorage for QueueStorage.Layout;
    using SafeERC20 for IERC20;
    using SafeERC20 for IWETH;

    uint256 internal constant ONE_SHARE = 10**18;

    IERC20 public immutable ERC20;
    IVault public immutable Vault;
    IWETH public immutable WETH;

    constructor(
        bool isCall,
        address pool,
        address vault,
        address weth
    ) {
        IPremiaPool.PoolSettings memory settings =
            IPremiaPool(pool).getPoolSettings();
        address asset = isCall ? settings.underlying : settings.base;

        ERC20 = IERC20(asset);
        Vault = IVault(vault);
        WETH = IWETH(weth);
    }

    /************************************************
     *  ACCESS CONTROL
     ***********************************************/

    /**
     * @dev Throws if called by any account other than the vault.
     */
    modifier onlyVault() {
        QueueStorage.Layout storage l = QueueStorage.layout();
        require(msg.sender == address(Vault), "!vault");
        _;
    }

    /************************************************
     *  DEPOSIT
     ***********************************************/

    /**
     * @notice validates the deposit, redeems claim tokens for vault shares and mints claim
     * tokens 1:1 for collateral deposited
     * @param l queue storage layout
     * @param amount total collateral deposited
     */
    function _deposit(QueueStorage.Layout storage l, uint256 amount) internal {
        require(amount > 0, "value exceeds minimum");

        // the maximum total value locked is the sum of collateral assets held in
        // the queue and the vault. if a deposit exceeds the max TVL, the transaction
        // should revert.
        uint256 totalWithDepositedAmount =
            Vault.totalAssets() + ERC20.balanceOf(address(this));
        require(totalWithDepositedAmount <= l.maxTVL, "maxTVL exceeded");

        // prior to making a new deposit, the vault will redeem all available claim tokens
        // in exchange for the pro-rata vault shares
        _redeemMax(msg.sender, msg.sender);

        uint256 currentTokenId = QueueStorage._getCurrentTokenId();

        // the queue mints claim tokens 1:1 with collateral deposited
        _mint(msg.sender, currentTokenId, amount, "");

        emit Deposit(l.epoch, msg.sender, amount);
    }

    /************************************************
     *  REDEEM
     ***********************************************/

    /**
     * @notice exchanges claim token for vault shares
     * @param tokenId claim token id
     * @param receiver vault share recipient
     * @param owner claim token holder
     */
    function _redeem(
        uint256 tokenId,
        address receiver,
        address owner
    ) internal {
        uint256 currentTokenId = QueueStorage._getCurrentTokenId();

        // claim tokens cannot be redeemed within the same epoch that they were minted
        require(
            tokenId != currentTokenId,
            "current claim token cannot be redeemed"
        );

        uint256 balance = _balanceOf(owner, tokenId);
        uint256 unredeemedShares = _previewUnredeemed(tokenId, owner);

        // burns claim tokens held by owner
        _burn(owner, tokenId, balance);
        // transfers unredeemed share amount to the receiver
        require(Vault.transfer(receiver, unredeemedShares), "transfer failed");

        uint64 epoch = QueueStorage._getEpoch();
        emit Redeem(epoch, receiver, owner, unredeemedShares);
    }

    /**
     * @notice exchanges all claim tokens for vault shares
     * @param receiver vault share recipient
     * @param owner claim token holder
     */
    function _redeemMax(address receiver, address owner) internal {
        uint256[] memory tokenIds = _tokensByAccount(owner);
        uint256 currentTokenId = QueueStorage._getCurrentTokenId();

        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (tokenId != currentTokenId) {
                _redeem(tokenId, receiver, owner);
            }
        }
    }

    /************************************************
     *  VIEW
     ***********************************************/

    /**
     * @notice calculates unredeemed vault shares available
     * @param tokenId claim token id
     * @param owner claim token holder
     * @return total unredeemed vault shares
     */
    function _previewUnredeemed(uint256 tokenId, address owner)
        internal
        view
        returns (uint256)
    {
        QueueStorage.Layout storage l = QueueStorage.layout();
        uint256 balance = _balanceOf(owner, tokenId);
        return (balance * l.pricePerShare[tokenId]) / ONE_SHARE;
    }

    /************************************************
     *  DEPOSIT HELPERS
     ***********************************************/

    /**
     * @notice wraps ETH sent to the contract and credits the amount, if the collateral asset
     * is not WETH, the transaction will revert
     * @param amount total collateral deposited
     * @return credited amount
     */
    function _wrapNativeToken(uint256 amount) internal returns (uint256) {
        uint256 credit;

        if (msg.value > 0) {
            require(address(ERC20) == address(WETH), "collateral != wETH");

            if (msg.value > amount) {
                // if the ETH amount is greater than the amount needed, it will be sent
                // back to the msg.sender
                unchecked {
                    (bool success, ) =
                        payable(msg.sender).call{value: msg.value - amount}("");

                    require(success, "ETH refund failed");

                    credit = amount;
                }
            } else {
                credit = msg.value;
            }

            WETH.deposit{value: credit}();
        }

        return credit;
    }

    /**
     * @notice pull token from user, send to exchangeHelper trigger a trade from
     * ExchangeHelper, and credits the amount
     * @param Exchange ExchangeHelper contract interface
     * @param s swap arguments
     * @param tokenOut token to swap for. should always equal to the collateral asset
     * @return credited amount
     */
    function _swapForPoolTokens(
        IExchangeHelper Exchange,
        IExchangeHelper.SwapArgs calldata s,
        address tokenOut
    ) internal returns (uint256) {
        if (msg.value > 0) {
            require(s.tokenIn == address(WETH), "tokenIn != wETH");
            WETH.deposit{value: msg.value}();
            WETH.safeTransfer(address(Exchange), msg.value);
        }

        if (s.amountInMax > 0) {
            IERC20(s.tokenIn).safeTransferFrom(
                msg.sender,
                address(Exchange),
                s.amountInMax
            );
        }

        uint256 amountCredited =
            Exchange.swapWithToken(
                s.tokenIn,
                tokenOut,
                s.amountInMax + msg.value,
                s.callee,
                s.allowanceTarget,
                s.data,
                s.refundAddress
            );

        require(
            amountCredited >= s.amountOutMin,
            "not enough output from trade"
        );

        return amountCredited;
    }

    /************************************************
     *  ERC1155 OVERRIDES
     ***********************************************/

    /**
     * @notice ERC1155 hook, called before all transfers including mint and burn
     * @dev function should be overridden and new implementation must call super
     * @dev called for both single and batch transfers
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
        override(ERC1155BaseInternal, ERC1155EnumerableInternal)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../vendor/IExchangeHelper.sol";

/**
 * @title Knox Queue Diamond Storage Library
 */

library QueueStorage {
    struct Layout {
        // epoch id
        uint64 epoch;
        // maximum total value locked
        uint256 maxTVL;
        // mapping of claim token id to price per share (claimTokenIds -> pricePerShare)
        mapping(uint256 => uint256) pricePerShare;
        // ExchangeHelper contract interface
        IExchangeHelper Exchange;
    }

    bytes32 internal constant LAYOUT_SLOT =
        keccak256("knox.contracts.storage.Queue");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = LAYOUT_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /************************************************
     *  VIEW
     ***********************************************/

    /**
     * @notice returns the current claim token id
     * @return claim token id
     */
    function _getCurrentTokenId() internal view returns (uint256) {
        return _formatClaimTokenId(_getEpoch());
    }

    /**
     * @notice returns the current epoch of the queue
     * @return epoch id
     */
    function _getEpoch() internal view returns (uint64) {
        return layout().epoch;
    }

    /**
     * @notice returns the max total value locked of the vault
     * @return max total value
     */
    function _getMaxTVL() internal view returns (uint256) {
        return layout().maxTVL;
    }

    /**
     * @notice returns the price per share for a given claim token id
     * @param tokenId claim token id
     * @return price per share
     */
    function _getPricePerShare(uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        return layout().pricePerShare[tokenId];
    }

    /************************************************
     * HELPERS
     ***********************************************/

    /**
     * @notice calculates claim token id for a given epoch
     * @param epoch weekly interval id
     * @return claim token id
     */
    function _formatClaimTokenId(uint64 epoch) internal view returns (uint256) {
        return (uint256(uint160(address(this))) << 64) + uint256(epoch);
    }

    /**
     * @notice derives queue address and epoch from claim token id
     * @param tokenId claim token id
     * @return address of queue
     * @return epoch id
     */
    function _parseClaimTokenId(uint256 tokenId)
        internal
        pure
        returns (address, uint64)
    {
        address queue;
        uint64 epoch;

        assembly {
            queue := shr(64, tokenId)
            epoch := tokenId
        }

        return (queue, epoch);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../vendor/IPremiaPool.sol";

import "./IVaultAdmin.sol";
import "./IVaultBase.sol";
import "./IVaultEvents.sol";
import "./IVaultView.sol";

/**
 * @title Knox Vault Interface
 */

interface IVault is IVaultAdmin, IVaultBase, IVaultEvents, IVaultView {
    /**
     * @notice gets the collateral asset ERC20 interface
     * @return ERC20 interface
     */
    function ERC20() external view returns (IERC20);

    /**
     * @notice gets the pool interface
     * @return pool interface
     */
    function Pool() external view returns (IPremiaPool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./VaultStorage.sol";

/**
 * @title Knox Vault Admin Interface
 */

interface IVaultAdmin {
    /************************************************
     *  ADMIN
     ***********************************************/

    /**
     * @notice sets the new auction
     * @dev the auction contract address must be set during the vault initialization
     * @param newAuction address of the new auction
     */
    function setAuction(address newAuction) external;

    /**
     * @notice sets the start and end offsets for the auction
     * @param newStartOffset new start offset
     * @param newEndOffset new end offset
     */
    function setAuctionWindowOffsets(
        uint256 newStartOffset,
        uint256 newEndOffset
    ) external;

    /**
     * @notice sets the option delta value
     * @param newDelta64x64 new option delta value as a 64x64 fixed point number
     */
    function setDelta64x64(int128 newDelta64x64) external;

    /**
     * @notice sets the new fee recipient
     * @param newFeeRecipient address of the new fee recipient
     */
    function setFeeRecipient(address newFeeRecipient) external;

    /**
     * @notice sets the new keeper
     * @param newKeeper address of the new keeper
     */
    function setKeeper(address newKeeper) external;

    /**
     * @notice sets the new pricer
     * @dev the pricer contract address must be set during the vault initialization
     * @param newPricer address of the new pricer
     */
    function setPricer(address newPricer) external;

    /**
     * @notice sets the new queue
     * @dev the queue contract address must be set during the vault initialization
     * @param newQueue address of the new queue
     */
    function setQueue(address newQueue) external;

    /**
     * @notice sets the performance fee for the vault
     * @param newPerformanceFee64x64 performance fee as a 64x64 fixed point number
     */
    function setPerformanceFee64x64(int128 newPerformanceFee64x64) external;

    /************************************************
     *  INITIALIZE AUCTION
     ***********************************************/

    /**
     * @notice sets the option parameters which will be sold, then initializes the auction
     */
    function initializeAuction() external;

    /************************************************
     *  INITIALIZE EPOCH
     ***********************************************/

    /**
     * @notice collects performance fee from epoch income, processes the queued deposits,
     * increments the epoch id, then sets the auction prices
     * @dev it assumed that an auction has already been initialized
     */
    function initializeEpoch() external;

    /************************************************
     *  PROCESS AUCTION
     ***********************************************/

    /**
     * @notice processes the auction when it has been finalized or cancelled
     * @dev it assumed that an auction has already been initialized and the auction prices
     * have been set
     */
    function processAuction() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/contracts/token/ERC20/metadata/IERC20Metadata.sol";
import "@solidstate/contracts/token/ERC4626/IERC4626.sol";
import "@solidstate/contracts/utils/IMulticall.sol";

/**
 * @title Knox Vault Base Interface
 * @dev includes ERC20Metadata and ERC4626 interfaces
 */

interface IVaultBase is IERC20Metadata, IERC4626, IMulticall {

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Knox Vault Events Interface
 */

interface IVaultEvents {
    /**
     * @notice emitted when the auction contract address is updated
     * @param epoch epoch id
     * @param oldAuction previous auction address
     * @param newAuction new auction address
     * @param caller address of admin
     */
    event AuctionSet(
        uint64 indexed epoch,
        address oldAuction,
        address newAuction,
        address caller
    );

    /**
     * @notice emitted when the is processed
     * @param epoch epoch id
     * @param totalCollateralUsed contracts sold, denominated in the collateral asset
     * @param totalContractsSold contracts sold during the auction
     * @param totalPremiums premiums earned during the auction
     */
    event AuctionProcessed(
        uint64 indexed epoch,
        uint256 totalCollateralUsed,
        uint256 totalContractsSold,
        uint256 totalPremiums
    );

    /**
     * @notice emitted when the auction offset window is updated
     * @param epoch epoch id
     * @param oldStartOffset previous start offset
     * @param newStartOffset new start offset
     * @param oldEndOffset previous end offset
     * @param newEndOffset new end offset
     * @param caller address of admin
     */
    event AuctionWindowOffsetsSet(
        uint64 indexed epoch,
        uint256 oldStartOffset,
        uint256 newStartOffset,
        uint256 oldEndOffset,
        uint256 newEndOffset,
        address caller
    );

    /**
     * @notice emitted when the option delta is updated
     * @param epoch epoch id
     * @param oldDelta previous option delta
     * @param newDelta new option delta
     * @param caller address of admin
     */
    event DeltaSet(
        uint64 indexed epoch,
        int128 oldDelta,
        int128 newDelta,
        address caller
    );

    /**
     * @notice emitted when a distribution is sent to a liquidity provider
     * @param epoch epoch id
     * @param collateralAmount quantity of collateral distributed to the receiver
     * @param shortContracts quantity of short contracts distributed to the receiver
     * @param receiver address of the receiver
     */
    event DistributionSent(
        uint64 indexed epoch,
        uint256 collateralAmount,
        uint256 shortContracts,
        address receiver
    );

    /**
     * @notice emitted when the fee recipient address is updated
     * @param epoch epoch id
     * @param oldFeeRecipient previous fee recipient address
     * @param newFeeRecipient new fee recipient address
     * @param caller address of admin
     */
    event FeeRecipientSet(
        uint64 indexed epoch,
        address oldFeeRecipient,
        address newFeeRecipient,
        address caller
    );

    /**
     * @notice emitted when the keeper address is updated
     * @param epoch epoch id
     * @param oldKeeper previous keeper address
     * @param newKeeper new keeper address
     * @param caller address of admin
     */
    event KeeperSet(
        uint64 indexed epoch,
        address oldKeeper,
        address newKeeper,
        address caller
    );

    /**
     * @notice emitted when an external function reverts
     * @param message error message
     */
    event Log(string message);

    /**
     * @notice emitted when option parameters are set
     * @param epoch epoch id
     * @param expiry expiration timestamp
     * @param strike64x64 strike price as a 64x64 fixed point number
     * @param longTokenId long token id
     * @param shortTokenId short token id
     */
    event OptionParametersSet(
        uint64 indexed epoch,
        uint64 expiry,
        int128 strike64x64,
        uint256 longTokenId,
        uint256 shortTokenId
    );

    /**
     * @notice emitted when the performance fee is collected
     * @param epoch epoch id
     * @param gain amount earned during the epoch
     * @param loss amount lost during the epoch
     * @param feeInCollateral fee from net income, denominated in the collateral asset
     */
    event PerformanceFeeCollected(
        uint64 indexed epoch,
        uint256 gain,
        uint256 loss,
        uint256 feeInCollateral
    );

    /**
     * @notice emitted when the performance fee is updated
     * @param epoch epoch id
     * @param oldPerformanceFee previous performance fee
     * @param newPerformanceFee new performance fee
     * @param caller address of admin
     */
    event PerformanceFeeSet(
        uint64 indexed epoch,
        int128 oldPerformanceFee,
        int128 newPerformanceFee,
        address caller
    );

    /**
     * @notice emitted when the pricer contract address is updated
     * @param epoch epoch id
     * @param oldPricer previous pricer address
     * @param newPricer new pricer address
     * @param caller address of admin
     */
    event PricerSet(
        uint64 indexed epoch,
        address oldPricer,
        address newPricer,
        address caller
    );

    /**
     * @notice emitted when the queue contract address is updated
     * @param epoch epoch id
     * @param oldQueue previous queue address
     * @param newQueue new queue address
     * @param caller address of admin
     */
    event QueueSet(
        uint64 indexed epoch,
        address oldQueue,
        address newQueue,
        address caller
    );

    /**
     * @notice emitted when the reserved liquidity is withdrawn from the pool
     * @param epoch epoch id
     * @param amount quantity of reserved liquidity removed from pool
     */
    event ReservedLiquidityWithdrawn(uint64 indexed epoch, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./VaultStorage.sol";

/**
 * @title Knox Vault View Interface
 */

interface IVaultView {
    /************************************************
     *  VIEW
     ***********************************************/

    /**
     * @notice returns the address of assigned actors
     * @return address of owner
     * @return address of fee recipient
     * @return address of keeper
     */
    function getActors()
        external
        view
        returns (
            address,
            address,
            address
        );

    /**
     * @notice returns the auction window offsets
     * @return start offset
     * @return end offset
     */
    function getAuctionWindowOffsets() external view returns (uint256, uint256);

    /**
     * @notice returns the address of connected services
     * @return address of Auction
     * @return address of Premia Pool
     * @return address of Pricer
     * @return address of Queue
     */
    function getConnections()
        external
        view
        returns (
            address,
            address,
            address,
            address
        );

    /**
     * @notice returns option delta
     * @return option delta as a 64x64 fixed point number
     */
    function getDelta64x64() external view returns (int128);

    /**
     * @notice returns the current epoch
     * @return current epoch id
     */
    function getEpoch() external view returns (uint64);

    /**
     * @notice returns the option by epoch id
     * @return option parameters
     */
    function getOption(uint64 epoch)
        external
        view
        returns (VaultStorage.Option memory);

    /**
     * @notice returns option type (call/put)
     * @return true if opton is a call
     */
    function getOptionType() external view returns (bool);

    /**
     * @notice returns performance fee
     * @return performance fee as a 64x64 fixed point number
     */
    function getPerformanceFee64x64() external view returns (int128);

    /**
     * @notice returns the total amount of collateral and short contracts to distribute
     * @param assetAmount quantity of assets to withdraw
     * @return distribution amount in collateral asset
     * @return distribution amount in the short contracts
     */
    function previewDistributions(uint256 assetAmount)
        external
        view
        returns (uint256, uint256);

    /**
     * @notice estimates the total reserved "active" collateral
     * @dev collateral is reserved from the auction to ensure the Vault has sufficent funds to
     * cover the APY fee
     * @return estimated amount of reserved "active" collateral
     */
    function previewReserves() external view returns (uint256);

    /**
     * @notice estimates the total number of contracts from the collateral and reserves held by the vault
     * @param strike64x64 strike price of the option as 64x64 fixed point number
     * @param collateral amount of collateral held by vault
     * @param reserves amount of reserves held by vault
     * @return estimated number of contracts
     */
    function previewTotalContracts(
        int128 strike64x64,
        uint256 collateral,
        uint256 reserves
    ) external view returns (uint256);

    /**
     * @notice calculates the total active vault by deducting the premiums from the ERC20 balance
     * @return total active collateral
     */
    function totalCollateral() external view returns (uint256);

    /**
     * @notice calculates the short position value denominated in the collateral asset
     * @return total short position in collateral amount
     */
    function totalShortAsCollateral() external view returns (uint256);

    /**
     * @notice returns the amount in short contracts underwitten by the vault
     * @return total short contracts
     */
    function totalShortAsContracts() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../auction/IAuction.sol";

import "../pricer/IPricer.sol";

import "../queue/IQueue.sol";

/**
 * @title Knox Vault Diamond Storage Library
 */

library VaultStorage {
    struct InitProxy {
        bool isCall;
        int128 delta64x64;
        int128 reserveRate64x64;
        int128 performanceFee64x64;
        string name;
        string symbol;
        address keeper;
        address feeRecipient;
        address pricer;
        address pool;
    }

    struct InitImpl {
        address auction;
        address queue;
        address pricer;
    }

    struct Option {
        // option expiration timestamp
        uint64 expiry;
        // option strike price
        int128 strike64x64;
        // option long token id
        uint256 longTokenId;
        // option short token id
        uint256 shortTokenId;
    }

    struct Layout {
        // base asset decimals
        uint8 baseDecimals;
        // underlying asset decimals
        uint8 underlyingDecimals;
        // option type, true if option is a call
        bool isCall;
        // auction processing flag, true if auction has been processed
        bool auctionProcessed;
        // vault option delta
        int128 delta64x64;
        // mapping of options to epoch id (epoch id -> option)
        mapping(uint64 => Option) options;
        // epoch id
        uint64 epoch;
        // auction start offset in seconds (startOffset = startTime - expiry)
        uint256 startOffset;
        // auction end offset in seconds (endOffset = endTime - expiry)
        uint256 endOffset;
        // auction start timestamp
        uint256 startTime;
        // total asset amount withdrawn during an epoch
        uint256 totalWithdrawals;
        // total asset amount not including premiums collected from the auction
        uint256 lastTotalAssets;
        // total premium collected during the auction
        uint256 totalPremium;
        // performance fee collected during epoch initialization
        uint256 fee;
        // percentage of asset to be held as reserves
        int128 reserveRate64x64;
        // percentage of fees taken from net income
        int128 performanceFee64x64;
        // fee recipient address
        address feeRecipient;
        // keeper bot address
        address keeper;
        // Auction contract interface
        IAuction Auction;
        // Queue contract interface
        IQueue Queue;
        // Pricer contract interface
        IPricer Pricer;
    }

    bytes32 internal constant LAYOUT_SLOT =
        keccak256("knox.contracts.storage.Vault");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = LAYOUT_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /************************************************
     *  VIEW
     ***********************************************/

    /**
     * @notice returns the current epoch
     * @return current epoch id
     */
    function _getEpoch() internal view returns (uint64) {
        return layout().epoch;
    }

    /**
     * @notice returns the option by epoch id
     * @return option parameters
     */
    function _getOption(uint64 epoch) internal view returns (Option memory) {
        return layout().options[epoch];
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

/**
 * @title Premia Exchange Helper
 * @dev deployed standalone and referenced by internal functions
 * @dev do NOT set approval to this contract!
 */
interface IExchangeHelper {
    struct SwapArgs {
        // token to pass in to swap
        address tokenIn;
        // amount of tokenIn to trade
        uint256 amountInMax;
        //min amount out to be used to purchase
        uint256 amountOutMin;
        // exchange address to call to execute the trade
        address callee;
        // address for which to set allowance for the trade
        address allowanceTarget;
        // data to execute the trade
        bytes data;
        // address to which refund excess tokens
        address refundAddress;
    }

    /**
     * @notice perform arbitrary swap transaction
     * @param sourceToken source token to pull into this address
     * @param targetToken target token to buy
     * @param pullAmount amount of source token to start the trade
     * @param callee exchange address to call to execute the trade.
     * @param allowanceTarget address for which to set allowance for the trade
     * @param data calldata to execute the trade
     * @param refundAddress address that un-used source token goes to
     * @return amountOut quantity of targetToken yielded by swap
     */
    function swapWithToken(
        address sourceToken,
        address targetToken,
        uint256 pullAmount,
        address callee,
        address allowanceTarget,
        bytes calldata data,
        address refundAddress
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPremiaPool {
    struct PoolSettings {
        address underlying;
        address base;
        address underlyingOracle;
        address baseOracle;
    }

    /**
     * @notice query holders of given token
     * @param id token id to query
     * @return list of holder addresses
     */
    function accountsByToken(uint256 id)
        external
        view
        returns (address[] memory);

    /**
     * @notice query the balance of given token held by given address
     * @param account address to query
     * @param id token to query
     * @return token balance
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @notice exercise option on behalf of holder
     * @param holder owner of long option tokens to exercise
     * @param longTokenId long option token id
     * @param contractSize quantity of tokens to exercise
     */
    function exerciseFrom(
        address holder,
        uint256 longTokenId,
        uint256 contractSize
    ) external;

    /**
     * @notice get fundamental pool attributes
     * @return structured PoolSettings
     */
    function getPoolSettings() external view returns (PoolSettings memory);

    /**
     * @notice get first oracle price update after timestamp. If no update has been registered yet,
     * return current price feed spot price
     * @param timestamp timestamp to query
     * @return spot64x64 64x64 fixed point representation of price
     */
    function getPriceAfter64x64(uint256 timestamp)
        external
        view
        returns (int128 spot64x64);

    /**
     * @notice process expired option, freeing liquidity and distributing profits
     * @param longTokenId long option token id
     * @param contractSize quantity of tokens to process
     */
    function processExpired(uint256 longTokenId, uint256 contractSize) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @notice set timestamp after which reinvestment is disabled
     * @param timestamp timestamp to begin divestment
     * @param isCallPool whether we set divestment timestamp for the call pool or put pool
     */
    function setDivestmentTimestamp(uint64 timestamp, bool isCallPool) external;

    /**
     * @notice query tokens held by given address
     * @param account address to query
     * @return list of token ids
     */
    function tokensByAccount(address account)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice force update of oracle price and pending deposit pool
     */
    function update() external;

    /**
     * @notice redeem pool share tokens for underlying asset
     * @param amount quantity of share tokens to redeem
     * @param isCallPool whether to deposit underlying in the call pool or base in the put pool
     */
    function withdraw(uint256 amount, bool isCallPool) external;

    /**
     * @notice write option without using liquidity from the pool on behalf of another address
     * @param underwriter underwriter of the option from who collateral will be deposited
     * @param longReceiver address who will receive the long token (Can be the underwriter)
     * @param maturity timestamp of option maturity
     * @param strike64x64 64x64 fixed point representation of strike price
     * @param contractSize quantity of option contract tokens to write
     * @param isCall whether this is a call or a put
     * @return longTokenId token id of the long call
     * @return shortTokenId token id of the short option
     */
    function writeFrom(
        address underwriter,
        address longReceiver,
        uint64 maturity,
        int128 strike64x64,
        uint256 contractSize,
        bool isCall
    ) external payable returns (uint256 longTokenId, uint256 shortTokenId);
}