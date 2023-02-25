// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.5.16;

import { NonReentrant } from '../NonReentrant.sol';

import { IERC20 }  from '../interfaces/IERC20.sol';
import { IGovernedProxy_New } from '../interfaces/IGovernedProxy_New.sol';
import { IERC721Manager } from '../interfaces/IERC721Manager.sol';
import { ICollectionProxy } from './ICollectionProxy.sol';

/**
 * SC-9: This contract has no chance of being updated. It must be stupid simple.
 *
 * If another upgrade logic is required in the future - it can be done as proxy stage II.
 */
contract CollectionProxy is NonReentrant, ICollectionProxy {
//test
    address public collectionManagerProxy;

    modifier senderOrigin() {
        // Internal calls are expected to use implementation directly.
        // That's due to use of call() instead of delegatecall() on purpose.
        // solium-disable-next-line security/no-tx-origin
        require(
            tx.origin == msg.sender,
            'CollectionProxy::senderOrigin: FORBIDDEN, not a direct call'
        );
        _;
    }

    function collectionManager() private view returns (address _collectionManager) {
        _collectionManager = address(
            IGovernedProxy_New(address(uint160(collectionManagerProxy))).implementation()
        );
    }

    modifier requireManager() {
        require(
            msg.sender == collectionManager(),
            'CollectionProxy::requireManager: FORBIDDEN, not CollectionManager'
        );
        _;
    }

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    constructor(address _collectionManagerProxy) public {
        collectionManagerProxy = _collectionManagerProxy;
    }

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    function emitTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external requireManager {
        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    function emitApproval(
        address owner,
        address approved,
        uint256 tokenId
    ) external requireManager {
        emit Approval(owner, approved, tokenId);
    }

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    function emitApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) external requireManager {
        emit ApprovalForAll(owner, operator, approved);
    }

    function safeTransferERC20From(
        address token,
        address from,
        address to,
        uint256 value
    ) external noReentry requireManager {
        require(
            IERC20(token).transferFrom(from, to, value),
            'CollectionProxy: safe transferFrom of ERC20 token failed'
        );
    }

    function safeMint(address to, uint256 quantity, bool payWithWETH) external payable {
        IERC721Manager(collectionManager()).safeMint.value(msg.value)(
            address(this),
            msg.sender,
            to,
            quantity,
            payWithWETH
        );
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) external {
        IERC721Manager(collectionManager()).burn(
            address(this),
            msg.sender,
            tokenId
        );
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) external {
        IERC721Manager(collectionManager()).approve(
            address(this),
            msg.sender,
            to,
            tokenId
        );
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) external {
        IERC721Manager(collectionManager()).setApprovalForAll(
            address(this),
            msg.sender,
            operator,
            approved
        );
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        IERC721Manager(collectionManager()).transferFrom(
            address(this),
            msg.sender,
            from,
            to,
            tokenId
        );
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata _data
    ) external {
        IERC721Manager(collectionManager()).safeTransferFrom(
            address(this),
            msg.sender,
            from,
            to,
            tokenId,
            _data
        );
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        IERC721Manager(collectionManager()).safeTransferFrom(
            address(this),
            msg.sender,
            from,
            to,
            tokenId,
            ''
        );
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return IERC721Manager(collectionManager()).royaltyInfo(address(this), tokenId, salePrice);
    }

    function balanceOf(address user) external view returns (uint256) {
        return IERC721Manager(collectionManager()).balanceOf(address(this), user);
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return IERC721Manager(collectionManager()).ownerOf(address(this), tokenId);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId) {
        return IERC721Manager(collectionManager()).tokenOfOwnerByIndex(address(this), owner, index);
    }

    function totalSupply() external view returns (uint256) {
        return IERC721Manager(collectionManager()).totalSupply(address(this));
    }

    function getApproved(uint256 tokenId) external view returns (address) {
        return IERC721Manager(collectionManager()).getApproved(address(this), tokenId);
    }

    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return IERC721Manager(collectionManager()).isApprovedForAll(address(this), owner, operator);
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return IERC721Manager(collectionManager()).tokenURI(address(this), tokenId);
    }

    function name() external view returns (string memory) {
        return IERC721Manager(collectionManager()).name(address(this));
    }

    function symbol() external view returns (string memory) {
        return IERC721Manager(collectionManager()).symbol(address(this));
    }

    // SECURITY: This is to prevent on-behalf-of calls through the fallback function
    function safeMint(
        address,
        address,
        address,
        uint256,
        bool
    ) external pure {
        revert('Good try');
    }

    // SECURITY: This is to prevent on-behalf-of calls through the fallback function
    function burn(
        address,
        address,
        uint256
    ) external pure {
        revert('Good try');
    }

    // SECURITY: This is to prevent on-behalf-of calls through the fallback function
    function approve(
        address,
        address,
        address,
        uint256
    ) external pure {
        revert('Good try');
    }

    // SECURITY: This is to prevent on-behalf-of calls through the fallback function
    function setApprovalForAll(
        address,
        address,
        address,
        bool
    ) external pure {
        revert('Good try');
    }

    // SECURITY: This is to prevent on-behalf-of calls through the fallback function
    function transferFrom(
        address,
        address,
        address,
        address,
        uint256
    ) external pure {
        revert('Good try');
    }

    // SECURITY: This is to prevent on-behalf-of calls through the fallback function
    function safeTransferFrom(
        address,
        address,
        address,
        address,
        uint256,
        bytes calldata
    ) external pure {
        revert('Good try');
    }

    // Proxy all other calls to CollectionManager.
    function() external payable senderOrigin {
        // SECURITY: senderOrigin() modifier is mandatory

        address _collectionManager = collectionManager();

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())

            let res := call(
                sub(gas(), 10000),
                _collectionManager,
                callvalue(),
                ptr,
                calldatasize(),
                0,
                0
            )
            // NOTE: returndatasize should allow repeatable calls
            //       what should save one opcode.
            returndatacopy(ptr, 0, returndatasize())

            switch res
            case 0 {
                revert(ptr, returndatasize())
            }
            default {
                return(ptr, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

import { IProposal } from './IProposal.sol';
import { IGovernedContract } from './IGovernedContract.sol';

contract IUpgradeProposal is IProposal {
    function impl() external view returns (IGovernedContract);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

interface IProposal {
    function parent() external view returns (address);

    function created_block() external view returns (uint256);

    function deadline() external view returns (uint256);

    function fee_payer() external view returns (address payable);

    function fee_amount() external view returns (uint256);

    function accepted_weight() external view returns (uint256);

    function rejected_weight() external view returns (uint256);

    function total_weight() external view returns (uint256);

    function quorum_weight() external view returns (uint256);

    function isFinished() external view returns (bool);

    function isAccepted() external view returns (bool);

    function withdraw() external;

    function destroy() external;

    function collect() external;

    function voteAccept() external;

    function voteReject() external;

    function setFee() external payable;

    function canVote(address owner) external view returns (bool);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

import { IGovernedContract } from './IGovernedContract.sol';
import { IUpgradeProposal } from './IUpgradeProposal.sol';

interface IGovernedProxy_New {
    event UpgradeProposal(IGovernedContract indexed implementation, IUpgradeProposal proposal);

    event Upgraded(IGovernedContract indexed implementation, IUpgradeProposal proposal);

    function spork_proxy() external view returns (address);

    function impl() external view returns (address);

    function implementation() external view returns (address);

    function proposeUpgrade(IGovernedContract _newImplementation, uint256 _period)
        external
        payable
        returns (IUpgradeProposal);

    function upgrade(IUpgradeProposal _proposal) external;

    function upgradeProposalImpl(IUpgradeProposal _proposal)
        external
        view
        returns (IGovernedContract newImplementation);

    function listUpgradeProposals() external view returns (IUpgradeProposal[] memory proposals);

    function collectUpgradeProposal(IUpgradeProposal _proposal) external;

    function() external payable;
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

interface IGovernedContract {
    // Return actual proxy address for secure validation
    function proxy() external view returns (address);

    // It must check that the caller is the proxy
    // and copy all required data from the old address.
    function migrate(IGovernedContract _oldImpl) external;

    // It must check that the caller is the proxy
    // and self destruct to the new address.
    function destroy(IGovernedContract _newImpl) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

interface IERC721Manager {
    function safeMint(
        address collectionProxy,
        address minter,
        address to,
        uint256 quantity,
        bool payWithWETH
    ) external payable;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function balanceOf(address collectionProxy, address owner) external view returns (uint256);

    function tokenOfOwnerByIndex(address collectionProxy, address owner, uint256 index) external view returns (uint256 tokenId);

    function tokenByIndex(address collectionProxy, uint256 index) external view returns (uint256 tokenId);

    function totalSupply(address collectionProxy) external view returns (uint256);

    function ownerOf(address collectionProxy, uint256 tokenId) external view returns (address);

    function name(address collectionProxy) external view returns (string memory);

    function symbol(address collectionProxy) external view returns (string memory);

    function baseURI(address collectionProxy) external view returns (string memory);

    function tokenURI(address collectionProxy, uint256 tokenId)
    external
    view
    returns (string memory);

    function getApproved(address collectionProxy, uint256 tokenId) external view returns (address);

    function isApprovedForAll(
        address collectionProxy,
        address owner,
        address operator
    ) external view returns (bool);

    function burn(
        address collectionProxy,
        address burner,
        uint256 tokenId
    ) external;

    function approve(
        address collectionProxy,
        address msgSender,
        address spender,
        uint256 tokenId
    ) external;

    function transferFrom(
        address collectionProxy,
        address spender,
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address collectionProxy,
        address spender,
        address from,
        address to,
        uint256 tokenId,
        bytes calldata _data
    ) external;

    function setApprovalForAll(
        address collectionProxy,
        address owner,
        address operator,
        bool approved
    ) external;

    function royaltyInfo(
        address collectionProxy,
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address, uint256);

    function exists(address collectionProxy, uint256 tokenId) external view returns (bool);

    function getCollectionStorage(address collectionProxy)
    external
    view
    returns (address _collectionStorage);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

interface ICollectionProxy {
    function safeTransferERC20From(
        address token,
        address from,
        address to,
        uint256 value
    ) external;

    function safeMint(address to, uint256 quantity, bool payWithWETH) external payable;

    function burn(uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool approved) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata _data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address);

    function balanceOf(address user) external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function totalSupply() external view returns (uint256);

    function getApproved(uint256 tokenId) external view returns (address);

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

/**
 * A little helper to protect contract from being re-entrant in state
 * modifying functions.
 */

contract NonReentrant {
    uint256 private entry_guard;

    modifier noReentry() {
        require(entry_guard == 0, 'NonReentrant: Reentry');
        entry_guard = 1;
        _;
        entry_guard = 0;
    }
}