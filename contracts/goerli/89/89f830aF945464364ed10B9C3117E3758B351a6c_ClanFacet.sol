// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

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

pragma solidity ^0.8.8;

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
                'ERC1155: burn amount exceeds balance'
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

pragma solidity ^0.8.8;

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

pragma solidity ^0.8.8;

import { IERC1155 } from '../IERC1155.sol';

/**
 * @title ERC1155 base interface
 */
interface IERC1155Base is IERC1155 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

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

pragma solidity ^0.8.8;

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

pragma solidity ^0.8.8;

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

pragma solidity ^0.8.8;

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

pragma solidity ^0.8.8;

import { IERC1155Base } from './base/IERC1155Base.sol';
import { IERC1155Enumerable } from './enumerable/IERC1155Enumerable.sol';
import { IERC1155Metadata } from './metadata/IERC1155Metadata.sol';

interface ISolidStateERC1155 is
    IERC1155Base,
    IERC1155Enumerable,
    IERC1155Metadata
{}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155MetadataInternal } from './IERC1155MetadataInternal.sol';

/**
 * @title ERC1155Metadata interface
 */
interface IERC1155Metadata is IERC1155MetadataInternal {
    /**
     * @notice get generated URI for given token
     * @return token URI
     */
    function uri(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC1155Metadata interface needed by internal functions
 */
interface IERC1155MetadataInternal {
    event URI(string value, uint256 indexed tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

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

pragma solidity ^0.8.8;

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

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import { Clan, ClanRole } from "../../Meta/DataStructures.sol";

import { IClan } from "../Clan/IClan.sol";
import { ClanStorage } from "../Clan/ClanStorage.sol";
import { ClanInternal } from "../Clan/ClanInternal.sol";
import { ItemsModifiers } from "../Items/ItemsModifiers.sol";
import { MetaModifiers } from "../../Meta/MetaModifiers.sol";
import { ClanGettersExternal } from "../Clan/ClanGetters.sol";

uint constant ONE_HOUR_IN_SECONDS = 60 * 60;

contract ClanFacet is
  IClan,
  ItemsModifiers,
  MetaModifiers,
  ClanGettersExternal,
  ClanInternal
{

//Creation, Abandonment and Role Change
  function createClan(uint256 knightId, string calldata clanName)
    external
    ifOwnsItem(knightId)
    ifIsKnight(knightId)
    ifNotInClan(knightId)
    ifIsNotOnClanActivityCooldown(knightId)
    ifNotClanNameTaken(clanName)
    ifIsClanNameCorrectLength(clanName)
  {
    _createClan(knightId, clanName);
  }

  function setClanRole(uint256 clanId, uint256 knightId, ClanRole newRole, uint256 callerId)
    external
    ifOwnsItem(_clanLeader(clanId))
    ifIsKnight(knightId)
    ifIsInClan(knightId, clanId)
  {
    ClanRole callerRole = _roleInClan(callerId);
    ClanRole knightRole = _roleInClan(knightId);
    if (newRole == ClanRole.OWNER && callerRole == ClanRole.OWNER) {
      _setClanRole(clanId, callerId, ClanRole.ADMIN);
      _setClanRole(clanId, knightId, ClanRole.OWNER);
      ClanStorage.state().clan[clanId].leader = knightId;
    } else if (uint8(callerRole) > uint8(knightRole) && uint8(callerRole) > uint8(newRole)) {
      _setClanRole(clanId, knightId, newRole);
    } else {
      revert ClanFacet_CantAssignNewRoleToThisCharacter(clanId, knightId, newRole, callerId);
    }
  }

  function setClanName(uint256 clanId, string calldata newClanName)
    external
    ifOwnsItem(_clanLeader(clanId))
    ifNotClanNameTaken(newClanName)
    ifIsClanNameCorrectLength(newClanName)
  {
    _setClanName(clanId, newClanName);
  }

// Clan stakes and leveling
  function onStake(address benefactor, uint256 clanId, uint256 amount)
    external
  //onlySBT
    ifClanExists(clanId)
  { _onStake(benefactor, clanId, amount); }

  function onWithdraw(address benefactor, uint256 clanId, uint256 amount)
    external
  //onlySBT
  { _onWithdraw(benefactor, clanId, amount); }

//Join, Leave and Invite Proposals
  //ONLY knight supposed call the join function
  function joinClan(uint256 knightId, uint256 clanId)
    external
    ifIsKnight(knightId)
    ifOwnsItem(knightId)
    ifIsNotOnClanActivityCooldown(knightId)
    ifNotInClan(knightId)
    ifClanExists(clanId)
    ifNoJoinProposalPending(knightId)
  { _join(knightId, clanId); }

  function withdrawJoinClan(uint256 knightId, uint256 clanId)
    external
    ifIsKnight(knightId)
    ifOwnsItem(knightId)
  {
    if(_clanJoinProposal(knightId) == clanId)
    {
      _withdrawJoin(knightId, clanId);
    } else {
      revert ClanFacet_NoJoinProposal(knightId, clanId);
    }
  }

  function leaveClan(uint256 knightId, uint256 clanId)
    external
    ifIsKnight(knightId)
    ifIsInClan(knightId, clanId)
    ifOwnsItem(knightId)
    ifNotClanOwner(knightId)
  { 
    _kick(knightId, clanId);
    emit ClanKnightLeft(clanId, knightId);
  }

  function kickFromClan(uint256 knightId, uint256 clanId, uint256 callerId)
    external
    ifIsKnight(knightId)
    ifIsInClan(knightId, clanId)
    ifNotOnClanKickCooldown(callerId)
  {
    ClanRole callerRole = _roleInClan(knightId);
    ClanRole knightRole = _roleInClan(knightId);

    if(
      //Owner can kick anyone besides himself
      callerRole == ClanRole.OWNER && knightRole != ClanRole.OWNER ||
      //Admin can kick anyone below himself
      callerRole == ClanRole.ADMIN && (knightRole == ClanRole.MOD || knightRole == ClanRole.NONE) ||
      //Moderator can only kick ordinary members
      callerRole == ClanRole.MOD && knightRole == ClanRole.NONE)
    {
      _kick(knightId, clanId);
      //Moderators go on one hour cooldown after kick
      if (callerRole == ClanRole.MOD) {
        ClanStorage.state().clanKickCooldown[callerId] = ONE_HOUR_IN_SECONDS;
      }
    } else { 
      revert ClanFacet_CantKickThisMember(knightId, clanId, callerId); 
    }
    emit ClanKnightKicked(clanId, knightId, callerId);
  }

  function approveJoinClan(uint256 knightId, uint256 clanId, uint256 callerId)
    external
    ifIsKnight(knightId)
    ifOwnsItem(callerId)
    ifIsBelowMaxMembers(clanId)
  {
    ClanRole callerRole = _roleInClan(callerId);
    if(_clanJoinProposal(knightId) != clanId) {
      revert ClanFacet_NoJoinProposal(knightId, clanId);
    }
    if(callerRole != ClanRole.OWNER && callerRole !=  ClanRole.ADMIN) {
      revert ClanFacet_InsufficientRolePriveleges(callerId);
    }
    _approveJoinClan(knightId, clanId);
    _setClanRole(clanId, knightId, ClanRole.PRIVATE);
    emit ClanJoinProposalAccepted(clanId, knightId, callerId);
  }

  function dismissJoinClan(uint256 knightId, uint256 clanId, uint256 callerId)
    external
    ifIsKnight(knightId)
    ifOwnsItem(callerId)
  {
    ClanRole callerRole = _roleInClan(callerId);
    if(_clanJoinProposal(knightId) != clanId) {
      revert ClanFacet_NoJoinProposal(knightId, clanId);
    }
    if(callerRole != ClanRole.OWNER && callerRole !=  ClanRole.ADMIN) {
      revert ClanFacet_InsufficientRolePriveleges(callerId);
    }
    _dismissJoinClan(knightId, clanId);
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import { Clan, ClanRole } from "../../Meta/DataStructures.sol";
import { ClanStorage } from "../Clan/ClanStorage.sol";
import { IClanGetters } from "../Clan/IClan.sol";

abstract contract ClanGetters {
  function _clanInfo(uint clanId) internal view returns(Clan memory) {
    return ClanStorage.state().clan[clanId];
  }

  function _clanLeader(uint clanId) internal view returns(uint256) {
    return ClanStorage.state().clan[clanId].leader;
  }

  function _clanTotalMembers(uint clanId) internal view returns(uint) {
    return ClanStorage.state().clan[clanId].totalMembers;
  }
  
  function _clanStake(uint clanId) internal view returns(uint256) {
    return ClanStorage.state().clan[clanId].stake;
  }

  function _clanLevel(uint clanId) internal view returns(uint) {
    return ClanStorage.state().clan[clanId].level;
  }

  function _clanLevel2(uint256 clanId) internal view returns(uint) {
    uint256 stake = _clanStake(clanId);
    uint[] memory thresholds = ClanStorage.state().levelThresholds;
    uint maxLevel = thresholds.length;
    uint newLevel = 0;
    while(stake > thresholds[newLevel] && newLevel < maxLevel) {
      newLevel++;
    }
    return newLevel;
  }

  function _stakeOf(address benefactor, uint clanId) internal view returns(uint256) {
    return ClanStorage.state().stake[benefactor][clanId];
  }

  function _clanLevelThreshold(uint level) internal view returns (uint) {
    return ClanStorage.state().levelThresholds[level];
  }

  function _clanMaxLevel() internal view returns (uint) {
    return ClanStorage.state().levelThresholds.length;
  }

  function _clansInTotal() internal view returns(uint256) {
    return ClanStorage.state().clansInTotal;
  }

  function _clanActivityCooldown(uint256 knightId) internal view returns(uint256) {
    return ClanStorage.state().clanActivityCooldown[knightId];
  }

  function _clanJoinProposal(uint256 knightId) internal view returns(uint256) {
    return ClanStorage.state().joinProposal[knightId];
  }

  function _roleInClan(uint256 knightId) internal view returns(ClanRole) {
    return ClanStorage.state().roleInClan[knightId];
  }

  function _clanMaxMembers(uint256 clanId) internal view returns(uint) {
    return ClanStorage.state().maxMembers[_clanLevel(clanId)];
  }

  function _clanKickCooldown(uint256 knightId) internal view returns(uint) {
    return ClanStorage.state().clanKickCooldown[knightId];
  }

  function _clanName(uint256 clanId) internal view returns(string memory) {
    return ClanStorage.state().clanName[clanId];
  }

  function _clanNameTaken(string calldata clanName) internal view returns(bool) {
    return ClanStorage.state().clanNameTaken[clanName];
  }
}

abstract contract ClanGettersExternal is IClanGetters, ClanGetters {
  function getClanLeader(uint clanId) external view returns(uint256) {
    return _clanLeader(clanId);
  }

  function getClanRole(uint knightId) external view returns(ClanRole) {
    return _roleInClan(knightId);
  }

  function getClanTotalMembers(uint clanId) external view returns(uint) {
    return _clanTotalMembers(clanId);
  }
  
  function getClanStake(uint clanId) external view returns(uint256) {
    return _clanStake(clanId);
  }

  function getClanLevel(uint clanId) external view returns(uint) {
    return _clanLevel(clanId);
  }

  function getStakeOf(address benefactor, uint clanId) external view returns(uint256) {
    return _stakeOf(benefactor, clanId);
  }

  function getClanLevelThreshold(uint level) external view returns(uint) {
    return _clanLevelThreshold(level);
  }

  function getClanMaxLevel() external view returns(uint) {
    return _clanMaxLevel();
  }

  function getClanJoinProposal(uint256 knightId) external view returns(uint256) {
    return _clanJoinProposal(knightId);
  }

  function getClanInfo(uint clanId) external view returns(uint256, uint256, uint256, uint256) {
    return (
      _clanLeader(clanId),
      _clanTotalMembers(clanId),
      _clanStake(clanId),
      _clanLevel(clanId)
    );
  }

  function getClanKnightInfo(uint knightId) external view returns(uint256, uint256, ClanRole, uint256) {
    return (
      _clanJoinProposal(knightId),
      _clanActivityCooldown(knightId),
      _roleInClan(knightId),
      _clanKickCooldown(knightId)
    );
  }

  function getClanName(uint256 clanId) external view returns(string memory) {
    return _clanName(clanId);
  }

  function getClanNameTaken(string calldata clanName) external view returns(bool) {
    return _clanNameTaken(clanName);
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { Clan, ClanRole } from "../../Meta/DataStructures.sol";

import { IClanEvents, IClanErrors } from "../Clan/IClan.sol";
import { ClanStorage } from "../Clan/ClanStorage.sol";
import { KnightStorage } from "../Knight/KnightStorage.sol";
import { KnightModifiers } from "../Knight/KnightModifiers.sol";
import { ClanGetters } from "../Clan/ClanGetters.sol";
import { ClanModifiers } from "../Clan/ClanModifiers.sol";
import { ItemsModifiers } from "../Items/ItemsModifiers.sol";

uint constant TWO_DAYS_IN_SECONDS = 2 * 24 * 60 * 60;

abstract contract ClanInternal is 
  IClanEvents,
  IClanErrors,
  ClanGetters,
  ClanModifiers,
  KnightModifiers,
  ItemsModifiers
{
//Creation, Abandonment and Leader Change
  function _createClan(uint256 knightId, string calldata clanName) internal returns(uint clanId) {
    ClanStorage.state().clansInTotal++;
    clanId = _clansInTotal();
    ClanStorage.state().clan[clanId] = Clan(knightId, 0, 0, 0);
    emit ClanCreated(clanId, knightId);
    _setClanName(clanId, clanName);
    _approveJoinClan(knightId, clanId);
    _setClanRole(clanId, knightId, ClanRole.OWNER);
  }

  function _abandon(uint256 clanId) internal {
    uint256 leaderId = _clanLeader(clanId);
    KnightStorage.state().knight[leaderId].inClan = 0;
    ClanStorage.state().clan[clanId].leader = 0;
    emit ClanAbandoned(clanId, leaderId);
  }

  function _setClanRole(uint256 clanId, uint256 knightId, ClanRole newClanRole) internal {
    ClanStorage.state().roleInClan[knightId] = newClanRole;
    if (newClanRole == ClanRole.OWNER || newClanRole == ClanRole.ADMIN) {
      ClanStorage.state().clanKickCooldown[knightId] = 0;
    }
    emit ClanNewRole(clanId, knightId, newClanRole);
  }

  function _setClanName(uint256 clanId, string calldata newClanName) internal {
    ClanStorage.state().clanName[clanId] = newClanName;
    emit ClanNewName(clanId, newClanName);
  }

// Clan stakes and leveling
  function _onStake(address benefactor, uint256 clanId, uint256 amount) internal {
    ClanStorage.state().stake[benefactor][clanId] += amount;
    ClanStorage.state().clan[clanId].stake += amount;
    _leveling(clanId);

    emit ClanStakeAdded(benefactor, clanId, amount);
  }

  function _onWithdraw(address benefactor, uint256 clanId, uint256 amount) internal {
    uint256 stake = _stakeOf(benefactor, clanId);
    if (stake < amount) {
      revert ClanFacet_InsufficientStake({
        stakeAvalible: stake,
        withdrawAmount: amount
      });
    }
    
    ClanStorage.state().stake[benefactor][clanId] -= amount;
    ClanStorage.state().clan[clanId].stake -= amount;
    _leveling(clanId);

    emit ClanStakeWithdrawn(benefactor, clanId, amount);
  }

  //Calculate clan level based on stake
  function _leveling(uint256 clanId) private {
    uint currentLevel = _clanLevel(clanId);
    uint256 stake = _clanStake(clanId);
    uint[] memory thresholds = ClanStorage.state().levelThresholds;
    uint maxLevel = thresholds.length;
    uint newLevel = 0;
    while (stake > thresholds[newLevel] && newLevel < maxLevel) {
      newLevel++;
    }
    if (currentLevel < newLevel) {
      ClanStorage.state().clan[clanId].level = newLevel;
      emit ClanLeveledUp(clanId, newLevel);
    } else if (currentLevel > newLevel) {
      ClanStorage.state().clan[clanId].level = newLevel;
      emit ClanLeveledDown(clanId, newLevel);
    }
  }

//Join, Leave and Invite Proposals
  function _join(uint256 knightId, uint256 clanId) internal {
    ClanStorage.state().joinProposal[knightId] = clanId;
    emit ClanJoinProposalSent(clanId, knightId);
  }

  function _withdrawJoin(uint256 knightId, uint256 clanId) internal {
    ClanStorage.state().joinProposal[knightId] = 0;
    emit ClanJoinProposalWithdrawn(clanId, knightId);
  }

  function _kick(uint256 knightId, uint256 clanId) internal {
    _setClanRole(clanId, knightId, ClanRole.NONE);
    ClanStorage.state().clan[clanId].totalMembers--;
    KnightStorage.state().knight[knightId].inClan = 0;
    ClanStorage.state().clanActivityCooldown[knightId] = block.timestamp + TWO_DAYS_IN_SECONDS;
    emit ClanKnightQuit(clanId, knightId);
  }

  function _approveJoinClan(uint256 knightId, uint256 clanId) internal {
    ClanStorage.state().clan[clanId].totalMembers++;
    KnightStorage.state().knight[knightId].inClan = clanId;
    ClanStorage.state().joinProposal[knightId] = 0;
    emit ClanKnightJoined(clanId, knightId);
  }

  function _dismissJoinClan(uint256 knightId, uint256 clanId) internal {
    ClanStorage.state().joinProposal[knightId] = 0;
    emit ClanJoinProposalDismissed(clanId, knightId);
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import { Clan, ClanRole } from "../../Meta/DataStructures.sol";
import { ClanStorage } from "../Clan/ClanStorage.sol";
import { IClanErrors } from "../Clan/IClan.sol";
import { ClanGetters } from "../Clan/ClanGetters.sol";

abstract contract ClanModifiers is IClanErrors, ClanGetters {
  function clanExists(uint256 clanId) internal view returns(bool) {
    return ClanStorage.state().clan[clanId].leader != 0;
  }

  modifier ifClanExists(uint256 clanId) {
    if(!clanExists(clanId)) {
      revert ClanModifiers_ClanDoesntExist(clanId);
    }
    _;
  }

  function isClanLeader(uint256 knightId, uint256 clanId) internal view returns(bool) {
    return ClanStorage.state().clan[clanId].leader == knightId;
  }

  modifier ifIsClanLeader(uint256 knightId, uint clanId) {
    if(!isClanLeader(knightId, clanId)) {
      revert ClanModifiers_KnightIsNotClanLeader(knightId, clanId);
    }
    _;
  }

  function isNotClanLeader(uint256 knightId, uint256 clanId) internal view returns(bool) {
    return ClanStorage.state().clan[clanId].leader != knightId;
  }

  modifier ifIsNotClanLeader(uint256 knightId, uint clanId) {
    if(!isNotClanLeader(knightId, clanId)) {
      revert ClanModifiers_KnightIsClanLeader(knightId, clanId);
    }
    _;
  }

  function isOnClanActivityCooldown(uint256 knightId) internal view returns(bool) {
    return _clanActivityCooldown(knightId) > block.timestamp;
  }

  modifier ifIsNotOnClanActivityCooldown(uint256 knightId) {
    if (isOnClanActivityCooldown(knightId)) {
      revert ClanModifiers_KnightOnClanActivityCooldown(knightId);
    }
    _;
  }

  function isJoinProposalPending(uint256 knightId) internal view returns(bool) {
    return _clanJoinProposal(knightId) != 0;
  }

  modifier ifNoJoinProposalPending(uint256 knightId) {
    uint clanId = _clanJoinProposal(knightId);
    if (clanId != 0) {
      revert ClanModifiers_JoinProposalToSomeClanExists(knightId, clanId);
    }
    _;
  }

  function isClanOwner(uint256 knightId) internal view returns(bool) {
    return _roleInClan(knightId) == ClanRole.OWNER;
  }

  modifier ifNotClanOwner(uint knightId) {
    if (isClanOwner(knightId)) {
      revert ClanModifiers_ClanOwnersCantCallThis(knightId);
    }
    _;
  }

  function isClanAdmin(uint256 knightId) internal view returns(bool) {
    return _roleInClan(knightId) == ClanRole.ADMIN;
  }

  function isClanMod(uint256 knightId) internal view returns(bool) {
    return _roleInClan(knightId) == ClanRole.MOD;
  }

  function isBelowMaxMembers(uint256 clanId) internal view returns(bool) {
    return _clanTotalMembers(clanId) < _clanMaxMembers(clanId);
  }

  modifier ifIsBelowMaxMembers(uint256 clanId) {
    if (!isBelowMaxMembers(clanId)) {
      revert ClanModifiers_AboveMaxMembers(clanId);
    }
    _;
  }

  function isOnClanKickCooldown(uint knightId) internal view returns(bool) {
    return _clanKickCooldown(knightId) < block.timestamp;
  }

  modifier ifNotOnClanKickCooldown(uint knightId) {
    if (isOnClanKickCooldown(knightId)) {
      revert ClanModifiers_KickingMembersOnCooldownForThisKnight(knightId);
    }
    _;
  }

  modifier ifNotClanNameTaken(string calldata clanName) {
    if(_clanNameTaken(clanName)) {
      revert ClanModifiers_ClanNameTaken(clanName);
    }
    _;
  }

  modifier ifIsClanNameCorrectLength(string calldata clanName) {
    //This is NOT a correct way to calculate string length, should change it later
    if(bytes(clanName).length < 1 || bytes(clanName).length > 30) {
      revert ClanModifiers_ClanNameWrongLength(clanName);
    }
    _;
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import { Clan, ClanRole } from "../../Meta/DataStructures.sol";

library ClanStorage {
  struct State {
    uint[] levelThresholds;
    uint[] maxMembers;
    // clanId => Clan
    mapping(uint256 => Clan) clan;
    // knightId => id of clan where join proposal is sent
    mapping (uint256 => uint256) joinProposal;
    // address => clanId => amount
    mapping (address => mapping (uint => uint256)) stake;
    
    uint256 clansInTotal;
    
    //Knight => end of cooldown
    mapping(uint256 => uint256) clanActivityCooldown;
    //Knight => clan join proposal sent
    mapping(uint256 => bool) joinProposalPending;
    //Kinight => Role in clan
    mapping(uint256 => ClanRole) roleInClan;
    //Knight => kick cooldown duration
    mapping(uint256 => uint) clanKickCooldown;
    //Clan => name of said clan
    mapping(uint256 => string) clanName;
    //Clan name => taken or not
    mapping(string => bool) clanNameTaken;
  }

  bytes32 internal constant STORAGE_SLOT = keccak256("Clan.storage");

  function state() internal pure returns (State storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { ClanRole } from "../../Meta/DataStructures.sol";

interface IClanEvents {
  event ClanCreated(uint clanId, uint256 knightId);
  event ClanAbandoned(uint clanId, uint256 knightId);
  event ClanNewRole(uint clanId, uint256 knightId, ClanRole newRole);
  event ClanNewName(uint256 clanId, string newClanName);

  event ClanStakeAdded(address benefactor, uint clanId, uint amount);
  event ClanStakeWithdrawn(address benefactor, uint clanId, uint amount);
  event ClanLeveledUp(uint clanId, uint newLevel);
  event ClanLeveledDown(uint clanId, uint newLevel);

  event ClanJoinProposalSent(uint clanId, uint256 knightId);
  event ClanJoinProposalWithdrawn(uint clanId, uint256 knightId);
  event ClanJoinProposalAccepted(uint clanId, uint256 knightId, uint256 callerId);
  event ClanJoinProposalDismissed(uint clanId, uint256 knightId);
  event ClanKnightKicked(uint clanId, uint256 knightId, uint256 callerId);
  event ClanKnightLeft(uint clanId, uint256 knightId);
  event ClanKnightQuit(uint clanId, uint256 knightId);
  event ClanKnightJoined(uint clanId, uint256 knightId);
}

interface IClanErrors {
  error ClanModifiers_ClanDoesntExist(uint256 clanId);
  error ClanModifiers_KnightIsNotClanLeader(uint256 knightId, uint256 clanId);
  error ClanModifiers_KnightIsClanLeader(uint256 knightId, uint256 clanId);
  error ClanModifiers_KnightInSomeClan(uint256 knightId, uint256 clanId);
  error ClanModifiers_KnightOnClanActivityCooldown(uint256 knightId);
  error ClanModifiers_KnightNotInThisClan(uint256 knightId, uint256 clanId);
  error ClanModifiers_AboveMaxMembers(uint256 clanId);
  error ClanModifiers_JoinProposalToSomeClanExists(uint256 knightId, uint256 clanId);
  error ClanModifiers_KickingMembersOnCooldownForThisKnight(uint256 knightId);
  error ClanModifiers_ClanOwnersCantCallThis(uint256 knightId);
  error ClanModifiers_ClanNameTaken(string clanName);
  error ClanModifiers_ClanNameWrongLength(string clanName);

  error ClanFacet_InsufficientStake(uint256 stakeAvalible, uint256 withdrawAmount);
  error ClanFacet_CantJoinAlreadyInClan(uint256 knightId, uint256 clanId);
  error ClanFacet_NoProposalOrNotClanLeader(uint256 knightId, uint256 clanId);
  error ClanFacet_CantKickThisMember(uint256 knightId, uint256 clanId, uint256 kickerId);
  error ClanFacet_CantJoinOtherClanWhileBeingAClanLeader(uint256 knightId, uint256 clanId, uint256 kickerId);
  error ClanFacet_CantAssignNewRoleToThisCharacter(uint256 clanId, uint256 knightId, ClanRole newRole, uint256 callerId);
  error ClanFacet_NoJoinProposal(uint256 knightId, uint256 clanId);
  error ClanFacet_InsufficientRolePriveleges(uint256 callerId);
}

interface IClanGetters {
  function getClanLeader(uint clanId) external view returns(uint256);

  function getClanRole(uint knightId) external view returns(ClanRole);

  function getClanTotalMembers(uint clanId) external view returns(uint);
  
  function getClanStake(uint clanId) external view returns(uint256);

  function getClanLevel(uint clanId) external view returns(uint);

  function getStakeOf(address benefactor, uint clanId) external view returns(uint256);

  function getClanLevelThreshold(uint level) external view returns(uint);

  function getClanMaxLevel() external view returns(uint);

  function getClanJoinProposal(uint256 knightId) external view returns(uint256);

  function getClanInfo(uint clanId) external view returns(uint256, uint256, uint256, uint256);

  function getClanKnightInfo(uint knightId) external view returns(uint256, uint256, ClanRole, uint256);
  
  function getClanName(uint256 clanId) external view returns(string memory);
}

interface IClan is IClanGetters, IClanEvents, IClanErrors {
  function createClan(uint256 knightId, string calldata clanName) external;

  function setClanRole(uint256 clanId, uint256 knightId, ClanRole newRole, uint256 callerId) external;

  function setClanName(uint256 clanId, string calldata newClanName) external;

// Clan stakes and leveling
  function onStake(address benefactor, uint256 clanId, uint256 amount) external;

  function onWithdraw(address benefactor, uint256 clanId, uint256 amount) external;

//Join, Leave and Invite Proposals
  function joinClan(uint256 knightId, uint256 clanId) external;

  function withdrawJoinClan(uint256 knightId, uint256 clanId) external;

  function approveJoinClan(uint256 knightId, uint256 clanId, uint256 callerId) external;

  function dismissJoinClan(uint256 knightId, uint256 clanId, uint256 callerId) external;
  
  function kickFromClan(uint256 knightId, uint256 clanId, uint256 callerId) external;

  function leaveClan(uint256 knightId, uint256 clanId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ISolidStateERC1155 } from "@solidstate/contracts/token/ERC1155/ISolidStateERC1155.sol";

interface IItemsEvents {}

interface IItemsErrors {
  error ItemsModifiers_DontOwnThisItem(uint256 itemId);
}

interface IItemsGetters {}

interface IItems is ISolidStateERC1155, IItemsEvents, IItemsErrors, IItemsGetters {}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { ERC1155BaseInternal } from "@solidstate/contracts/token/ERC1155/base/ERC1155BaseInternal.sol";
import { IItemsErrors } from "../Items/IItems.sol";

abstract contract ItemsModifiers is ERC1155BaseInternal, IItemsErrors {
  function ownsItem(uint256 itemId) internal view returns(bool) {
    return _balanceOf(msg.sender, itemId) > 0;
  }

  modifier ifOwnsItem(uint256 itemId) {
    if(!ownsItem(itemId)) {
      revert ItemsModifiers_DontOwnThisItem(itemId);
    }
    _;
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { Coin, Pool, Knight } from "../../Meta/DataStructures.sol";

interface IKnightEvents {
  event KnightMinted (uint knightId, address wallet, Pool c, Coin p);
  event KnightBurned (uint knightId, address wallet, Pool c, Coin p);
}

interface IKnightErrors {
  error KnightFacet_InsufficientFunds(uint256 avalible, uint256 required);
  error KnightFacet_AbandonLeaderRoleBeforeBurning(uint256 knightId, uint256 clanId);

  error KnightModifiers_WrongKnightId(uint256 wrongId);
  error KnightModifiers_KnightNotInAnyClan(uint256 knightId);
  error KnightModifiers_KnightNotInClan(uint256 knightId, uint256 wrongClanId, uint256 correctClanId);
  error KnightModifiers_KnightInSomeClan(uint256 knightId, uint256 clanId);
}

interface IKnightGetters {
  function getKnightInfo(uint256 knightId) external view returns(Knight memory);

  function getKnightPool(uint256 knightId) external view returns(Pool);

  function getKnightCoin(uint256 knightId) external view returns(Coin);

  function getKnightOwner(uint256 knightId) external view returns(address);

  function getKnightClan(uint256 knightId) external view returns(uint256);

  function getKnightPrice(Coin coin) external view returns (uint256);

  //returns amount of minted knights for a particular coin & pool
  function getKnightsMinted(Pool pool, Coin coin) external view returns (uint256);

  //returns amount of minted knights for any coin in a particular pool
  function getKnightsMintedOfPool(Pool pool) external view returns (uint256 knightsMintedTotal);

  //returns amount of minted knights for any pool in a particular coin
  function getKnightsMintedOfCoin(Coin coin) external view returns (uint256);

  //returns a total amount of minted knights
  function getKnightsMintedTotal() external view returns (uint256);

  //returns amount of burned knights for a particular coin & pool
  function getKnightsBurned(Pool pool, Coin coin) external view returns (uint256);

  //returns amount of burned knights for any coin in a particular pool
  function getKnightsBurnedOfPool(Pool pool) external view returns (uint256 knightsBurnedTotal);

  //returns amount of burned knights for any pool in a particular coin
  function getKnightsBurnedOfCoin(Coin coin) external view returns (uint256);

  //returns a total amount of burned knights
  function getKnightsBurnedTotal() external view returns (uint256);

  function getTotalKnightSupply() external view returns (uint256);

  function getPoolAndCoinCompatibility(Pool p, Coin c) external view returns (bool);
}

interface IKnight is IKnightEvents, IKnightErrors, IKnightGetters {
  function mintKnight(Pool p, Coin c) external;

  function burnKnight (uint256 knightId) external;
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import { Coin, Pool, Knight } from "../../Meta/DataStructures.sol";

import { IKnightGetters } from "../Knight/IKnight.sol";

import { KnightStorage } from "../Knight/KnightStorage.sol";
import { MetaStorage } from "../../Meta/MetaStorage.sol";


abstract contract KnightGetters {
  function _knightInfo(uint256 knightId) internal view virtual returns(Knight memory) {
    return KnightStorage.state().knight[knightId];
  }

  function _knightCoin(uint256 knightId) internal view virtual returns(Coin) {
    return KnightStorage.state().knight[knightId].coin;
  }

  function _knightPool(uint256 knightId) internal view virtual returns(Pool) {
    return KnightStorage.state().knight[knightId].pool;
  }

  function _knightOwner(uint256 knightId) internal view virtual returns(address) {
    return KnightStorage.state().knight[knightId].owner;
  }

  function _knightClan(uint256 knightId) internal view virtual returns(uint256) {
    return KnightStorage.state().knight[knightId].inClan;
  }

  function _knightPrice(Coin coin) internal view virtual returns (uint256) {
    return KnightStorage.state().knightPrice[coin];
  }

  //returns amount of minted knights for a particular coin & pool
  function _knightsMinted(Pool pool, Coin coin) internal view virtual returns (uint256) {
    return KnightStorage.state().knightsMinted[pool][coin];
  }

  //returns amount of minted knights for any coin in a particular pool
  function _knightsMintedOfPool(Pool pool) internal view virtual returns (uint256 minted) {
    for (uint8 coin = 1; coin < uint8(type(Coin).max) + 1; coin++) {
      minted += _knightsMinted(pool, Coin(coin));
    }
  }

  //returns amount of minted knights for any pool in a particular coin
  function _knightsMintedOfCoin(Coin coin) internal view virtual returns (uint256 minted) {
    for (uint8 pool = 1; pool < uint8(type(Pool).max) + 1; pool++) {
      minted += _knightsMinted(Pool(pool), coin);
    }
  }

  //returns a total amount of minted knights
  function _knightsMintedTotal() internal view virtual returns (uint256 minted) {
    for (uint8 pool = 1; pool < uint8(type(Pool).max) + 1; pool++) {
      minted += _knightsMintedOfPool(Pool(pool));
    }
  }

  //returns amount of burned knights for a particular coin & pool
  function _knightsBurned(Pool pool, Coin coin) internal view virtual returns (uint256) {
    return KnightStorage.state().knightsBurned[pool][coin];
  }

  //returns amount of burned knights for any coin in a particular pool
  function _knightsBurnedOfPool(Pool pool) internal view virtual returns (uint256 burned) {
    for (uint8 coin = 1; coin < uint8(type(Coin).max) + 1; coin++) {
      burned += _knightsBurned(pool, Coin(coin));
    }
  }

  //returns amount of burned knights for any pool in a particular coin
  function _knightsBurnedOfCoin(Coin coin) internal view virtual returns (uint256 burned) {
    for (uint8 pool = 1; pool < uint8(type(Pool).max) + 1; pool++) {
      burned += _knightsBurned(Pool(pool), coin);
    }
  }

  //returns a total amount of burned knights
  function _knightsBurnedTotal() internal view virtual returns (uint256 burned) {
    for (uint8 pool = 1; pool < uint8(type(Pool).max) + 1; pool++) {
      burned += _knightsBurnedOfPool(Pool(pool));
    }
  }

  function _totalKnightSupply() internal view virtual returns (uint256) {
    return _knightsMintedTotal() - _knightsBurnedTotal();
  }
}

abstract contract KnightGettersExternal is IKnightGetters, KnightGetters {
  function getKnightInfo(uint256 knightId) external view returns(Knight memory) {
    return _knightInfo(knightId);
  }

  function getKnightCoin(uint256 knightId) external view returns(Coin) {
    return _knightCoin(knightId);
  }

  function getKnightPool(uint256 knightId) external view returns(Pool) {
    return _knightPool(knightId);
  }

  function getKnightOwner(uint256 knightId) external view returns(address) {
    return _knightOwner(knightId);
  }

  function getKnightClan(uint256 knightId) external view returns(uint256) {
    return _knightClan(knightId);
  }

  function getKnightPrice(Coin coin) external view returns (uint256) {
    return _knightPrice(coin);
  }

  //returns amount of minted knights for a particular coin & pool
  function getKnightsMinted(Pool pool, Coin coin) external view returns (uint256) {
    return _knightsMinted(pool, coin);
  }

  //returns amount of minted knights for any coin in a particular pool
  function getKnightsMintedOfPool(Pool pool) external view returns (uint256 knightsMintedTotal) {
    return _knightsMintedOfPool(pool);
  }

  //returns amount of minted knights for any pool in a particular coin
  function getKnightsMintedOfCoin(Coin coin) external view returns (uint256) {
    return _knightsMintedOfCoin(coin);
  }

  //returns a total amount of minted knights
  function getKnightsMintedTotal() external view returns (uint256) {
    return _knightsMintedTotal();
  }

  //returns amount of burned knights for a particular coin & pool
  function getKnightsBurned(Pool pool, Coin coin) external view returns (uint256) {
    return _knightsBurned(pool, coin);
  }

  //returns amount of burned knights for any coin in a particular pool
  function getKnightsBurnedOfPool(Pool pool) external view returns (uint256 knightsBurnedTotal) {
    return _knightsBurnedOfPool(pool);
  }

  //returns amount of burned knights for any pool in a particular coin
  function getKnightsBurnedOfCoin(Coin coin) external view returns (uint256) {
    return _knightsBurnedOfCoin(coin);
  }

  //returns a total amount of burned knights
  function getKnightsBurnedTotal() external view returns (uint256) {
    return _knightsBurnedTotal();
  }

  function getTotalKnightSupply() external view returns (uint256) {
    return _totalKnightSupply();
  }

  function getPoolAndCoinCompatibility(Pool p, Coin c) external view returns (bool) {
    return MetaStorage.state().compatible[p][c];
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import { KnightGetters } from "./KnightGetters.sol";
import { IKnightErrors } from "./IKnight.sol";

abstract contract KnightModifiers is IKnightErrors, KnightGetters {

  function isKnight(uint256 knightId) internal view virtual returns(bool) {
    return knightId >= type(uint256).max - _knightsMintedTotal();
  }
  
  modifier ifIsKnight(uint256 knightId) {
    if(!isKnight(knightId)) {
      revert KnightModifiers_WrongKnightId(knightId);
    }
    _;
  }

  function isInAnyClan(uint256 knightId) internal view virtual returns(bool) {
    return _knightClan(knightId) != 0;
  }

  modifier ifIsInAnyClan(uint256 knightId) {
    if(!isInAnyClan(knightId)) {
      revert KnightModifiers_KnightNotInAnyClan(knightId);
    }
    _;
  }

  function isInClan(uint256 knightId, uint256 clanId) internal view virtual returns(bool) {
    return _knightClan(knightId) == clanId;
  }

  modifier ifIsInClan(uint256 knightId, uint256 clanId) {
    uint256 knightClan = _knightClan(knightId);
    if(knightClan != clanId) {
      revert KnightModifiers_KnightNotInClan({
        knightId: knightId,
        wrongClanId: clanId,
        correctClanId: knightClan
      });
    }
    _;
  }

  function notInClan(uint256 knightId) internal view virtual returns(bool) {
    return _knightClan(knightId) == 0;
  }

  modifier ifNotInClan(uint256 knightId) {
    uint256 clanId = _knightClan(knightId);
    if (clanId != 0) {
      revert KnightModifiers_KnightInSomeClan(knightId, clanId);
    }
    _;
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import { Pool, Coin, Knight } from "../../Meta/DataStructures.sol";

library KnightStorage {
  struct State {
    mapping(uint256 => Knight) knight;
    mapping(Coin => uint256) knightPrice;
    mapping(Pool => mapping(Coin => uint256)) knightsMinted;
    mapping(Pool => mapping(Coin => uint256)) knightsBurned;
  }

  bytes32 internal constant STORAGE_SLOT = keccak256("Knight.storage");

  function state() internal pure returns (State storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

enum Pool { NONE, TEST, AAVE }

enum Coin { NONE, TEST, USDT, USDC, EURS }

struct Knight {
  Pool pool;
  Coin coin;
  address owner;
  uint256 inClan;
}

enum gearSlot { NONE, WEAPON, SHIELD, HELMET, ARMOR, PANTS, SLEEVES, GLOVES, BOOTS, JEWELRY, CLOAK }

struct Clan {
  uint256 leader;
  uint256 stake;
  uint totalMembers;
  uint level;
}

enum Role { NONE, ADMIN }

enum ClanRole { NONE, PRIVATE, MOD, ADMIN, OWNER }

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import { Coin, Pool } from "../Meta/DataStructures.sol";
import { MetaStorage } from "../Meta/MetaStorage.sol";

abstract contract MetaModifiers {
  error InvalidPool(Pool pool);
  
  function isVaildPool(Pool pool) internal view virtual returns(bool) {
    return pool != Pool.NONE ? true : false;
  }

  modifier ifIsVaildPool(Pool pool) {
    if (!isVaildPool(pool)) {
      revert InvalidPool(pool);
    }
    _;
  }

  error InvalidCoin(Coin coin);

  function isValidCoin(Coin coin) internal view virtual returns(bool) {
    return coin != Coin.NONE ? true : false;
  }

  modifier ifIsValidCoin(Coin coin) {
    if (!isValidCoin(coin)) {
      revert InvalidCoin(coin);
    }
    _;
  }

  error IncompatiblePoolCoin(Pool pool, Coin coin);

  function isCompatible(Pool pool, Coin coin) internal view virtual returns(bool) {
    return MetaStorage.state().compatible[pool][coin];
  }

  modifier ifIsCompatible(Pool pool, Coin coin) {
    if (!isCompatible(pool, coin)) {
      revert IncompatiblePoolCoin(pool, coin);
    }
    _;
  }

  error CallerNotSBV();

  function isSBV() internal view virtual returns(bool) {
    return MetaStorage.state().SBV == msg.sender;
  }

  modifier ifIsSBV {
    if (!isSBV()) {
      revert CallerNotSBV();
    }
    _;
  }

  error CallerNotSBT();

  function isSBT() internal view virtual returns(bool) {
    return MetaStorage.state().SBT == msg.sender;
  }

  modifier ifIsSBT {
    if (!isSBT()) {
      revert CallerNotSBT();
    }
    _;
  }

  error CallerNotSBD();

  function isSBD() internal view virtual returns(bool) {
    return address(this) == msg.sender;
  }

  modifier ifIsSBD {
    if (!isSBD()) {
      revert CallerNotSBD();
    }
    _;
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import { Coin, Pool } from "../Meta/DataStructures.sol";

library MetaStorage {
  struct State {
    // StableBattle EIP20 Token address
    address SBT;
    // StableBattle EIP721 Village address
    address SBV;

    mapping (Pool => address) pool;
    mapping (Coin => address) coin;
    mapping (Coin => address) acoin;
    mapping (Pool => mapping (Coin => bool)) compatible;
  }

  bytes32 internal constant STORAGE_SLOT = keccak256("Meta.storage");

  function state() internal pure returns (State storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}