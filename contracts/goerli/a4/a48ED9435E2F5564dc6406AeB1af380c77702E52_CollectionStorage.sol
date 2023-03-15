// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

import { StorageBase } from '../StorageBase.sol';

import { IGovernedProxy_New } from '../interfaces/IGovernedProxy_New.sol';

contract CollectionStorage is StorageBase {
    struct RoyaltyInfo {
        address receiver;
        uint96 fraction;
    }

    // name of the collection
    string private name;

    // symbol of the collection
    string private symbol;

    // baseURI of the collection
    string private baseURI;

    // collectionMoved is set to true after the collection has been moved to the
    // Energi blockchain, otherwise collectionMoved is set to false.
    bool private collectionMoved = false;

    // URI to a picture on IPFS (with a movementNotice) displayed by the tokenURI method
    // for all tokens after the collection has been moved to the Energi blockchain (collectionMoved == true);
    string private movementNoticeURI;

    // Total supply of the collection
    uint256 private totalSupply;

    // Array of tokenIds
    uint256[] private tokenIds;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private owners;

    // Mapping of owner address to array of owned tokenIds
    mapping(address => uint256[]) private tokenOfOwner;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private operatorApprovals;

    // Royalties for all tokenIds
    RoyaltyInfo private royaltyInfo;

    // Collection manager proxy address
    address private collectionManagerProxyAddress;

    // Collection manager helper proxy address
    address private collectionManagerHelperProxyAddress;

    modifier requireManager() {
        require(
            msg.sender ==
                address(
                    IGovernedProxy_New(address(uint160(collectionManagerProxyAddress)))
                        .implementation()
                ) ||
                msg.sender ==
                address(
                    IGovernedProxy_New(address(uint160(collectionManagerHelperProxyAddress)))
                        .implementation()
                ),
            'CollectionStorage: FORBIDDEN, not CollectionManager'
        );
        _;
    }

    constructor(
        address _collectionManagerProxyAddress,
        address _collectionManagerHelperProxyAddress,
        string memory _baseURI,
        string memory _name,
        string memory _symbol
    ) public {
        collectionManagerProxyAddress = _collectionManagerProxyAddress;
        collectionManagerHelperProxyAddress = _collectionManagerHelperProxyAddress;
        baseURI = _baseURI;
        name = _name;
        symbol = _symbol;
    }

    // Getter functions
    //
    function getName() external view returns (string memory _name) {
        _name = name;
    }

    function getSymbol() external view returns (string memory _symbol) {
        _symbol = symbol;
    }

    function getBaseURI() external view returns (string memory _baseURI) {
        _baseURI = baseURI;
    }

    function getCollectionMoved() external view returns (bool _collectionMoved) {
        _collectionMoved = collectionMoved;
    }

    function getMovementNoticeURI() external view returns (string memory _movementNoticeURI) {
        _movementNoticeURI = movementNoticeURI;
    }

    function getTotalSupply() external view returns (uint256 _totalSupply) {
        _totalSupply = totalSupply;
    }

    function getTokenIdsCount() external view returns (uint256 _tokenIdsCount) {
        _tokenIdsCount = tokenIds.length;
    }

    function getTokenIdByIndex(uint256 _index) external view returns (uint256 _tokenId) {
        _tokenId = tokenIds[_index];
    }

    function getOwner(uint256 tokenId) external view returns (address _owner) {
        _owner = owners[tokenId];
    }

    function getBalance(address _address) external view returns (uint256 _amount) {
        _amount = tokenOfOwner[_address].length;
    }

    function getTokenOfOwnerByIndex(
        address _owner,
        uint256 _index
    ) external view returns (uint256 _tokenId) {
        _tokenId = tokenOfOwner[_owner][_index];
    }

    function getTokenApproval(uint256 _tokenId) external view returns (address _address) {
        _address = tokenApprovals[_tokenId];
    }

    function getOperatorApproval(
        address _owner,
        address _operator
    ) external view returns (bool _approved) {
        _approved = operatorApprovals[_owner][_operator];
    }

    function getRoyaltyReceiver() external view returns (address _royaltyReceiver) {
        _royaltyReceiver = royaltyInfo.receiver;
    }

    function getRoyaltyFraction() external view returns (uint96 _royaltyFraction) {
        _royaltyFraction = royaltyInfo.fraction;
    }

    function getRoyaltyInfo()
        external
        view
        returns (address _royaltyReceiver, uint96 _royaltyFraction)
    {
        _royaltyReceiver = royaltyInfo.receiver;
        _royaltyFraction = royaltyInfo.fraction;
    }

    function getCollectionManagerProxyAddress()
        external
        view
        returns (address _collectionManagerProxyAddress)
    {
        _collectionManagerProxyAddress = collectionManagerProxyAddress;
    }

    function getCollectionManagerHelperProxyAddress()
        external
        view
        returns (address _collectionManagerHelperProxyAddress)
    {
        _collectionManagerHelperProxyAddress = collectionManagerHelperProxyAddress;
    }

    // Setter functions
    //
    function setName(string calldata _name) external requireManager {
        name = _name;
    }

    function setSymbol(string calldata _symbol) external requireManager {
        symbol = _symbol;
    }

    function setBaseURI(string calldata _baseURI) external requireManager {
        baseURI = _baseURI;
    }

    function setCollectionMoved(bool _collectionMoved) external requireManager {
        collectionMoved = _collectionMoved;
    }

    function setMovementNoticeURI(string calldata _movementNoticeURI) external requireManager {
        movementNoticeURI = _movementNoticeURI;
    }

    function setTotalSupply(uint256 _value) external requireManager {
        totalSupply = _value;
    }

    function setTokenIdByIndex(uint256 _tokenId, uint256 _index) external requireManager {
        tokenIds[_index] = _tokenId;
    }

    function pushTokenId(uint256 _tokenId) external requireManager {
        tokenIds.push(_tokenId);
    }

    function popTokenId() external requireManager {
        tokenIds.pop();
    }

    function setOwner(uint256 tokenId, address owner) external requireManager {
        owners[tokenId] = owner;
    }

    function setTokenOfOwnerByIndex(
        address _owner,
        uint256 _index,
        uint256 _tokenId
    ) external requireManager {
        tokenOfOwner[_owner][_index] = _tokenId;
    }

    function pushTokenOfOwner(address _owner, uint256 _tokenId) external requireManager {
        tokenOfOwner[_owner].push(_tokenId);
    }

    function popTokenOfOwner(address _owner) external requireManager {
        tokenOfOwner[_owner].pop();
    }

    function setTokenApproval(uint256 _tokenId, address _address) external requireManager {
        tokenApprovals[_tokenId] = _address;
    }

    function setOperatorApproval(
        address _owner,
        address _operator,
        bool _approved
    ) external requireManager {
        operatorApprovals[_owner][_operator] = _approved;
    }

    function setRoyaltyInfo(address receiver, uint96 fraction) external requireManager {
        royaltyInfo.receiver = receiver;
        royaltyInfo.fraction = fraction;
    }

    function setCollectionManagerProxyAddress(
        address _collectionManagerProxyAddress
    ) external requireManager {
        collectionManagerProxyAddress = _collectionManagerProxyAddress;
    }

    function setCollectionManagerHelperProxyAddress(
        address _collectionManagerHelperProxyAddress
    ) external requireManager {
        collectionManagerHelperProxyAddress = _collectionManagerHelperProxyAddress;
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

    function proposeUpgrade(
        IGovernedContract _newImplementation,
        uint256 _period
    ) external payable returns (IUpgradeProposal);

    function upgrade(IUpgradeProposal _proposal) external;

    function upgradeProposalImpl(
        IUpgradeProposal _proposal
    ) external view returns (IGovernedContract newImplementation);

    function listUpgradeProposals() external view returns (IUpgradeProposal[] memory);

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

import { IGovernedContract } from './interfaces/IGovernedContract.sol';

/**
 * Base for contract storage (SC-14).
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */

contract StorageBase {
    address payable internal owner;

    modifier requireOwner() {
        require(msg.sender == address(owner), 'StorageBase: Not owner!');
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function setOwner(IGovernedContract _newOwner) external requireOwner {
        owner = address(uint160(address(_newOwner)));
    }

    function kill() external requireOwner {
        selfdestruct(msg.sender);
    }
}