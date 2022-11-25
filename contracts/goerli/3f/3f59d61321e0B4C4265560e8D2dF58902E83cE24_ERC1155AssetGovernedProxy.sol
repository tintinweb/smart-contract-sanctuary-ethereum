// SPDX-License-Identifier: MIT

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.5.16;

import { NonReentrant } from './NonReentrant.sol';

import { IERC1155Asset } from './interfaces/IERC1155Asset.sol';
import { IGovernedProxy } from './interfaces/IGovernedProxy.sol';
import { ISporkRegistry } from './interfaces/ISporkRegistry.sol';
import { IGovernedProxy } from './interfaces/IGovernedProxy.sol';
import { IUpgradeProposal } from './interfaces/IUpgradeProposal.sol';
import { IGovernedContract } from './interfaces/IGovernedContract.sol';

/**
 * SC-9: This contract has no chance of being updated. It must be stupid simple.
 *
 * If another upgrade logic is required in the future - it can be done as proxy stage II.
 */
contract ERC1155AssetGovernedProxy is NonReentrant, IGovernedContract, IGovernedProxy {
    bool public initialized = false;
    IGovernedContract public implementation;
    IGovernedProxy public spork_proxy;
    mapping(address => IGovernedContract) public upgrade_proposals;
    IUpgradeProposal[] public upgrade_proposal_list;

    modifier senderOrigin() {
        // Internal calls are expected to use implementation directly.
        // That's due to use of call() instead of delegatecall() on purpose.
        // solium-disable-next-line security/no-tx-origin
        require(
            tx.origin == msg.sender,
            'ERC1155AssetGovernedProxy::senderOrigin: Only direct calls are allowed!'
        );
        _;
    }

    modifier onlyImplementation() {
        require(
            msg.sender == address(implementation),
            'ERC1155AssetGovernedProxy::onlyImplementation: Only calls from implementation are allowed!'
        );
        _;
    }

    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _value
    );

    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _values
    );

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    event URI(string _value, uint256 indexed _id);

    // ERC1155 standard functions

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes calldata _data
    ) external {
        IERC1155Asset(address(uint160(address(implementation)))).implSafeTransferFrom(
            msg.sender,
            _from,
            _to,
            _id,
            _amount,
            _data
        );
        emit TransferSingle(msg.sender, _from, _to, _id, _amount);
    }

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external {
        IERC1155Asset(address(uint160(address(implementation)))).implSafeBatchTransferFrom(
            msg.sender,
            _from,
            _to,
            _ids,
            _amounts,
            _data
        );
        emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
    }

    function balanceOf(address _owner, uint256 _id) external view returns (uint256) {
        return IERC1155Asset(address(uint160(address(implementation)))).balanceOf(_owner, _id);
    }

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        returns (uint256[] memory)
    {
        return
            IERC1155Asset(address(uint160(address(implementation)))).balanceOfBatch(_owners, _ids);
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        IERC1155Asset(address(uint160(address(implementation)))).implSetApprovalForAll(
            msg.sender,
            _operator,
            _approved
        );
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return
            IERC1155Asset(address(uint160(address(implementation)))).isApprovedForAll(
                _owner,
                _operator
            );
    }

    // Additional features

    function mint(
        address _account,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external payable noReentry {
        IERC1155Asset(address(uint160(address(implementation)))).implMint.value(msg.value)(
            msg.sender,
            _account,
            _id,
            _value,
            _data
        );
        emit TransferSingle(msg.sender, address(0), _account, _id, _value);
    }

    function mintBatch(
        address _account,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external payable noReentry {
        IERC1155Asset(address(uint160(address(implementation)))).implMintBatch.value(msg.value)(
            msg.sender,
            _account,
            _ids,
            _values,
            _data
        );
        emit TransferBatch(msg.sender, address(0), _account, _ids, _values);
    }

    function burn(
        address _account,
        uint256 _id,
        uint256 _value
    ) external {
        IERC1155Asset(address(uint160(address(implementation)))).implBurn(
            msg.sender,
            _account,
            _id,
            _value
        );
        emit TransferSingle(msg.sender, _account, address(0), _id, _value);
    }

    function burnBatch(
        address _account,
        uint256[] calldata _ids,
        uint256[] calldata _values
    ) external {
        IERC1155Asset(address(uint160(address(implementation)))).implBurnBatch(
            msg.sender,
            _account,
            _ids,
            _values
        );
        emit TransferBatch(msg.sender, _account, address(0), _ids, _values);
    }

    function eRC1155AssetOwner() external view returns (address) {
        return IERC1155Asset(address(uint160(address(implementation)))).eRC1155AssetOwner();
    }

    function eRC1155AssetMinter() external view returns (address) {
        return IERC1155Asset(address(uint160(address(implementation)))).eRC1155AssetMinter();
    }

    function baseUri() external view returns (string memory) {
        return IERC1155Asset(address(uint160(address(implementation)))).baseUri();
    }

    function totalSupply(uint256 _id) external view returns (uint256) {
        return IERC1155Asset(address(uint160(address(implementation)))).totalSupply(_id);
    }

    function supportsInterface(bytes4 _interfaceId) external view returns (bool) {
        return
            IERC1155Asset(address(uint160(address(implementation)))).supportsInterface(
                _interfaceId
            );
    }

    function creator(uint256 _id) external view returns (address) {
        return IERC1155Asset(address(uint160(address(implementation)))).creator(_id);
    }

    function feeDenominator() external view returns (uint96) {
        return IERC1155Asset(address(uint160(address(implementation)))).feeDenominator();
    }

    // Features related to ERC2981 Royalties Standard

    function royaltyInfo(uint256 _id, uint256 _salePrice) external view returns (address, uint256) {
        return
            IERC1155Asset(address(uint160(address(implementation)))).royaltyInfo(_id, _salePrice);
    }

    function setTokenRoyalty(
        uint256 _id,
        address _beneficiary,
        uint96 _feeNumerator
    ) external {
        IERC1155Asset(address(uint160(address(implementation)))).implSetTokenRoyalty(
            msg.sender,
            _id,
            _beneficiary,
            _feeNumerator
        );
    }

    function resetTokenRoyalty(uint256 _id) external {
        IERC1155Asset(address(uint160(address(implementation)))).implResetTokenRoyalty(
            msg.sender,
            _id
        );
    }

    /** SECURITY FUNCTIONS: prevent on-behalf-of calls **/

    function implSafeTransferFrom(
        address,
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure {
        revert('Good try');
    }

    function implSafeBatchTransferFrom(
        address,
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure {
        revert('Good try');
    }

    function implSetApprovalForAll(
        address,
        address,
        bool
    ) external pure {
        revert('Good try');
    }

    function implMint(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure {
        revert('Good try');
    }

    function implMintBatch(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure {
        revert('Good try');
    }

    function implBurn(
        address,
        address,
        uint256,
        uint256
    ) external pure {
        revert('Good try');
    }

    function implBurnBatch(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata
    ) external pure {
        revert('Good try');
    }

    function implSetTokenRoyalty(
        address,
        uint256,
        address,
        uint96
    ) external pure {
        revert('Good try');
    }

    function implResetTokenRoyalty(address, uint256) external pure {
        revert('Good try');
    }

    // Governance functions

    function initialize(address _impl) external {
        if (!initialized) {
            initialized = true;
            implementation = IGovernedContract(_impl);
        }
    }

    function setSporkProxy(address payable _sporkProxy) external onlyImplementation {
        spork_proxy = IGovernedProxy(_sporkProxy);
    }

    /**
     * Pre-create a new contract first.
     * Then propose upgrade based on that.
     */
    function proposeUpgrade(IGovernedContract _newImplementation, uint256 _period)
        external
        payable
        senderOrigin
        noReentry
        returns (IUpgradeProposal)
    {
        require(
            _newImplementation != implementation,
            'ERC1155AssetGovernedProxy::proposeUpgrade: Already active!'
        );
        require(
            _newImplementation.proxy() == address(this),
            'ERC1155AssetGovernedProxy::proposeUpgrade: Wrong proxy!'
        );

        ISporkRegistry spork_reg = ISporkRegistry(address(spork_proxy.implementation()));
        IUpgradeProposal proposal = spork_reg.createUpgradeProposal.value(msg.value)(
            _newImplementation,
            _period,
            msg.sender
        );

        upgrade_proposals[address(proposal)] = _newImplementation;
        upgrade_proposal_list.push(proposal);

        emit UpgradeProposal(_newImplementation, proposal);

        return proposal;
    }

    /**
     * Once proposal is accepted, anyone can activate that.
     */
    function upgrade(IUpgradeProposal _proposal) external noReentry {
        IGovernedContract newImplementation = upgrade_proposals[address(_proposal)];
        require(
            newImplementation != implementation,
            'ERC1155AssetGovernedProxy::upgrade: Already active!'
        );
        // in case it changes in the flight
        require(
            address(newImplementation) != address(0),
            'ERC1155AssetGovernedProxy::upgrade: Not registered!'
        );
        require(_proposal.isAccepted(), 'ERC1155AssetGovernedProxy::upgrade: Not accepted!');

        IGovernedContract oldImplementation = implementation;

        newImplementation.migrate(oldImplementation);
        implementation = newImplementation;
        oldImplementation.destroy(newImplementation);

        // SECURITY: prevent downgrade attack
        _cleanupProposal(_proposal);

        // Return fee ASAP
        _proposal.destroy();

        emit Upgraded(newImplementation, _proposal);
    }

    /**
     * Map proposal to implementation
     */
    function upgradeProposalImpl(IUpgradeProposal _proposal)
        external
        view
        returns (IGovernedContract newImplementation)
    {
        newImplementation = upgrade_proposals[address(_proposal)];
    }

    /**
     * Lists all available upgrades
     */
    function listUpgradeProposals() external view returns (IUpgradeProposal[] memory proposals) {
        uint256 len = upgrade_proposal_list.length;
        proposals = new IUpgradeProposal[](len);

        for (uint256 i = 0; i < len; ++i) {
            proposals[i] = upgrade_proposal_list[i];
        }

        return proposals;
    }

    /**
     * Once proposal is reject, anyone can start collect procedure.
     */
    function collectUpgradeProposal(IUpgradeProposal _proposal) external noReentry {
        IGovernedContract newImplementation = upgrade_proposals[address(_proposal)];
        require(
            address(newImplementation) != address(0),
            'ERC1155AssetGovernedProxy::collectUpgradeProposal: Not registered!'
        );
        _proposal.collect();
        delete upgrade_proposals[address(_proposal)];

        _cleanupProposal(_proposal);
    }

    function _cleanupProposal(IUpgradeProposal _proposal) internal {
        delete upgrade_proposals[address(_proposal)];

        uint256 len = upgrade_proposal_list.length;
        for (uint256 i = 0; i < len; ++i) {
            if (upgrade_proposal_list[i] == _proposal) {
                upgrade_proposal_list[i] = upgrade_proposal_list[len - 1];
                upgrade_proposal_list.pop();
                break;
            }
        }
    }

    // This function is called by implementation to transfer the minting fee
    function receiveETH() external payable {}

    function safeTransferETH(address to, uint256 amount) external noReentry onlyImplementation {
        (bool success, bytes memory data) = to.call.value(amount)('');
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'ERC1155AssetGovernedProxy::safeTransferETH: failed to transfer ETH'
        );
    }

    /**
     * Related to above
     */
    function proxy() external view returns (address) {
        return address(this);
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function migrate(IGovernedContract) external {
        revert('ERC1155AssetGovernedProxy::migrate: Good try');
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function destroy(IGovernedContract) external {
        revert('ERC1155AssetGovernedProxy::destroy: Good try');
    }

    /**
     * Proxy all other calls to implementation.
     */
    function() external payable senderOrigin {
        // SECURITY: senderOrigin() modifier is mandatory

        // A dummy delegatecall opcode in the fallback function is necessary for
        // block explorers to pick up the Energi proxy-implementation pattern
        if (false) {
            (bool success, bytes memory data) = address(0).delegatecall(
                abi.encodeWithSignature('')
            );
            require(
                success && !success && data.length == 0 && data.length != 0,
                'ERC1155AssetGovernedProxy: delegatecall cannot be used'
            );
        }

        IGovernedContract implementation_m = implementation;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)

            let res := call(sub(gas, 10000), implementation_m, callvalue, ptr, calldatasize, 0, 0)
            // NOTE: returndatasize should allow repeatable calls
            //       what should save one opcode.
            returndatacopy(ptr, 0, returndatasize)

            switch res
            case 0 {
                revert(ptr, returndatasize)
            }
            default {
                return(ptr, returndatasize)
            }
        }
    }
}

// SPDX-License-Identifier: MIT

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.5.16;

import { IProposal } from './IProposal.sol';
import { IGovernedContract } from './IGovernedContract.sol';

/**
 * Interface of UpgradeProposal
 */
contract IUpgradeProposal is IProposal {
    function implementation() external view returns (IGovernedContract);
}

// SPDX-License-Identifier: MIT

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.5.16;

import { IGovernedContract } from './IGovernedContract.sol';
import { IUpgradeProposal } from './IUpgradeProposal.sol';

interface ISporkRegistry {
    function createUpgradeProposal(
        IGovernedContract _impl,
        uint256 _period,
        address payable _fee_payer
    ) external payable returns (IUpgradeProposal);

    function consensusGasLimits() external view returns (uint256 callGas, uint256 xferGas);
}

// SPDX-License-Identifier: MIT

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

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

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.5.16;
//pragma experimental SMTChecker;

import { IGovernedContract } from './IGovernedContract.sol';
import { IUpgradeProposal } from './IUpgradeProposal.sol';

/**
 * Genesis version of IGovernedProxy interface.
 *
 * Base Consensus interface for upgradable contracts proxy.
 * Unlike common approach, the implementation is NOT expected to be
 * called through delegatecall() to minimize risks of shared storage.
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */
interface IGovernedProxy {
    event UpgradeProposal(IGovernedContract indexed implementation, IUpgradeProposal proposal);

    event Upgraded(IGovernedContract indexed implementation, IUpgradeProposal proposal);

    function implementation() external view returns (IGovernedContract);

    function initialize(address _impl) external;

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

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.5.16;

/**
 * Genesis version of GovernedContract interface.
 *
 * Base Consensus interface for upgradable contracts.
 * Unlike common approach, the implementation is NOT expected to be
 * called through delegatecall() to minimize risks of shared storage.
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */

interface IGovernedContract {
    // Return actual proxy address for secure validation
    function proxy() external view returns (address);

    // It must check that the caller is the proxy
    // and copy all required data from the old address.
    function migrate(IGovernedContract _oldImplementation) external;

    // It must check that the caller is the proxy
    // and self destruct to the new address.
    function destroy(IGovernedContract _newImplementation) external;

    // function () external payable; // This line (from original Energi IGovernedContract) is commented because it
    // makes truffle migrations fail
}

// SPDX-License-Identifier: MIT

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.5.16;

import { IUpgradeProposal } from './IUpgradeProposal.sol';
import { IGovernedContract } from './IGovernedContract.sol';

interface IERC1155Asset {
    function implMint(
        address caller,
        address account,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external payable;

    function implMintBatch(
        address caller,
        address account,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external payable;

    function implBurn(
        address caller,
        address account,
        uint256 id,
        uint256 value
    ) external;

    function implBurnBatch(
        address caller,
        address account,
        uint256[] calldata ids,
        uint256[] calldata values
    ) external;

    function implSetTokenRoyalty(
        address caller,
        uint256 id,
        address beneficiary,
        uint96 feeNumerator
    ) external;

    function implResetTokenRoyalty(address caller, uint256 id) external;

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);

    function feeDenominator() external view returns (uint96);

    function eRC1155AssetOwner() external view returns (address);

    function eRC1155AssetMinter() external view returns (address);

    function creator(uint256 id) external view returns (address);

    // inherited from GovernedERC1155
    function implSafeTransferFrom(
        address spender,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function implSafeBatchTransferFrom(
        address spender,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function implSetApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) external;

    function baseUri() external view returns (string memory);

    function totalSupply(uint256 id) external view returns (uint256);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function setBaseUri(string calldata _newbaseUri) external;
}

// SPDX-License-Identifier: MIT

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

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