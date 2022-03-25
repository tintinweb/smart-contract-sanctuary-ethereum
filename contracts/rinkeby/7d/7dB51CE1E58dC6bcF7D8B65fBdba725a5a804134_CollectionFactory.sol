/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

pragma solidity 0.5.16;

// File: ../../interfaces/IGovernedContract.sol
// Copyright 2022 Energi Core
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
interface IGovernedContract {
    // Return actual proxy address for secure validation
    function proxy() external view returns(address);
    // It must check that the caller is the proxy
    // and copy all required data from the old address.
    function migrate(IGovernedContract _oldImpl) external;
    // It must check that the caller is the proxy
    // and self destruct to the new address.
    function destroy(IGovernedContract _newImpl) external;
}
// File: ../../GovernedContract.sol
// Copyright 2022 Energi Core
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
/**
 * Genesis version of GovernedContract common base.
 *
 * Base Consensus interface for upgradable contracts.
 * Unlike common approach, the implementation is NOT expected to be
 * called through delegatecall() to minimize risks of shared storage.
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */
contract GovernedContract is IGovernedContract {
    address public proxy;
    constructor(address _proxy) public {
        proxy = _proxy;
    }
    modifier requireProxy {
        require (msg.sender == proxy, 'Governed Contract: Not proxy');
        _;
    }
    function getProxy() internal view returns(address _proxy) {
        _proxy = proxy;
    }
    // Function overridden in child contract
    function migrate(IGovernedContract _oldImpl) external requireProxy {
        _migrate(_oldImpl);
    }
    // Function overridden in child contract
    function destroy(IGovernedContract _newImpl) external requireProxy {
        _destroy(_newImpl);
    }
    // solium-disable-next-line no-empty-blocks
    function _migrate(IGovernedContract) internal {}
    function _destroy(IGovernedContract _newImpl) internal {
        selfdestruct(address(uint160(address(_newImpl))));
    }
    function _callerAddress()
        internal view
        returns (address payable)
    {
        if (msg.sender == proxy) {
            // This is guarantee of the GovernedProxy
            // solium-disable-next-line security/no-tx-origin
            return tx.origin;
        } else {
            return msg.sender;
        }
    }
}
// File: ../../NonReentrant.sol
// Copyright 2022 Energi Core
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
/**
 * A little helper to protect contract from being re-entrant in state
 * modifying functions.
 */
contract NonReentrant {
    uint private entry_guard;
    modifier noReentry {
        require (entry_guard == 0, "NonReentrant: Reentry");
        entry_guard = 1;
        _;
        entry_guard = 0;
    }
}
// File: ../../interfaces/IProposal.sol
// Copyright 2022 Energi Core
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
interface IProposal {
    function parent() external view returns(address);
    function created_block() external view returns(uint);
    function deadline() external view returns(uint);
    function fee_payer() external view returns(address payable);
    function fee_amount() external view returns(uint);
    function accepted_weight() external view returns(uint);
    function rejected_weight() external view returns(uint);
    function total_weight() external view returns(uint);
    function quorum_weight() external view returns(uint);
    function isFinished() external view returns(bool);
    function isAccepted() external view returns(bool);
    function withdraw() external;
    function destroy() external;
    function collect() external;
    function voteAccept() external;
    function voteReject() external;
    function setFee() external payable;
    function canVote(address owner) external view returns(bool);
}
// File: ../../interfaces/IUpgradeProposal.sol
// Copyright 2022 Energi Core
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
contract IUpgradeProposal is IProposal {
    function implementation() external view returns(IGovernedContract);
}
// File: ../../interfaces/IGovernedProxy.sol
// Copyright 2022 Energi Core
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
interface IGovernedProxy {
  event UpgradeProposal(IGovernedContract indexed implementation, IUpgradeProposal proposal);
  event Upgraded(IGovernedContract indexed implementation, IUpgradeProposal proposal);
  function spork_proxy() external view returns(address);
  function implementation() external view returns(IGovernedContract);
  function proposeUpgrade(IGovernedContract _newImplementation, uint _period) external payable returns(IUpgradeProposal);
  function upgrade(IUpgradeProposal _proposal) external;
  function upgradeProposalImpl(IUpgradeProposal _proposal) external view returns(IGovernedContract newImplementation);
  function listUpgradeProposals() external view returns(IUpgradeProposal[] memory proposals);
  function collectUpgradeProposal(IUpgradeProposal _proposal) external;
  function () external payable;
}
// File: ../../interfaces/ISporkRegistry.sol
// Copyright 2022 Energi Core
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
interface ISporkRegistry {
    function createUpgradeProposal(
        IGovernedContract _implementation,
        uint _period,
        address payable _fee_payer
    )
        external payable
        returns (IUpgradeProposal);
    function consensusGasLimits()
        external view
        returns(uint callGas, uint xferGas);  
}
// File: CollectionFactoryGovernedProxy.sol
// Copyright 2022 The Energi Core Authors
// This file is part of Energi Core.
//
// Energi Core is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Energi Core is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Energi Core. If not, see <http://www.gnu.org/licenses/>.
// Energi Governance system is the fundamental part of Energi Core.
// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.
/**
 * SC-9: This contract has no chance of being updated. It must be stupid simple.
 *
 * If another upgrade logic is required in the future - it can be done as proxy stage II.
 */
contract CollectionFactoryGovernedProxy is
    NonReentrant,
    IGovernedContract,
    IGovernedProxy
{
    modifier senderOrigin {
        // Internal calls are expected to use implementation directly.
        // That's due to use of call() instead of delegatecall() on purpose.
        // solium-disable-next-line security/no-tx-origin
        require(
            tx.origin == msg.sender,
            'CollectionFactoryGovernedProxy: Only direct calls are allowed!'
        );
        _;
    }
    modifier onlyImpl {
        require(
            msg.sender == address(implementation),
            'CollectionFactoryGovernedProxy: Only calls from implementation are allowed!'
        );
        _;
    }
    IGovernedContract public implementation;
    IGovernedProxy public spork_proxy;
    mapping(address => IGovernedContract) public upgrade_proposals;
    IUpgradeProposal[] public upgrade_proposal_list;
    event CollectionCreated(
        address collectionProxyAddress,
        address collectionStorageAddress,
        string baseURI,
        string name,
        string symbol,
        uint collectionLength
    );
    constructor(address _implementation) public {
        implementation = IGovernedContract(_implementation);
    }
    function setSporkProxy(address payable _sporkProxy) external onlyImpl {
        spork_proxy = IGovernedProxy(_sporkProxy);
    }
    // Emit CollectionCreated event
    function emitCollectionCreated(
        address collectionProxyAddress,
        address collectionStorageAddress,
        string calldata baseURI,
        string calldata name,
        string calldata symbol,
        uint collectionLength
    ) external onlyImpl {
        emit CollectionCreated(
            collectionProxyAddress,
            collectionStorageAddress,
            baseURI,
            name,
            symbol,
            collectionLength
        );
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
            'CollectionGovernedProxy: Already active!'
        );
        require(
            _newImplementation.proxy() == address(this),
            'CollectionFactoryGovernedProxy: Wrong proxy!'
        );
        ISporkRegistry spork_reg = ISporkRegistry(address(spork_proxy.implementation()));
        IUpgradeProposal proposal =
            spork_reg.createUpgradeProposal.value(msg.value)(
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
            'CollectionFactoryGovernedProxy: Already active!'
        );
        // in case it changes in the flight
        require(
            address(newImplementation) != address(0),
            'CollectionFactoryGovernedProxy: Not registered!'
        );
        require(
            _proposal.isAccepted(),
            'CollectionFactoryGovernedProxy: Not accepted!'
        );
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
    function listUpgradeProposals()
        external
        view
        returns (IUpgradeProposal[] memory proposals)
    {
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
    function collectUpgradeProposal(IUpgradeProposal _proposal)
        external
        noReentry
    {
        IGovernedContract newImplementation = upgrade_proposals[address(_proposal)];
        require(
            address(newImplementation) != address(0),
            'CollectionFactoryGovernedProxy: Not registered!'
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
        revert('CollectionFactoryGovernedProxy: Good try');
    }
    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function destroy(IGovernedContract) external {
        revert('CollectionFactoryGovernedProxy: Good try');
    }
    /**
     * Proxy all other calls to implementation.
     */
    function() external payable senderOrigin {
        // SECURITY: senderOrigin() modifier is mandatory
        // A dummy delegatecall opcode in the fallback function is necessary for 
        // block explorers to pick up the Energi proxy-implementation pattern
        if(false){
            (bool success, bytes memory data) = 
                address(0).delegatecall(abi.encodeWithSignature(""));
            require(
                success && !success && data.length == 0 && data.length != 0,
                'CollectionFactoryGovernedProxy: delegatecall cannot to be used'
            );
        }
        IGovernedContract implementation_m = implementation;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let res := call(
                sub(gas, 10000),
                implementation_m,
                callvalue,
                ptr,
                calldatasize,
                0,
                0
            )
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
// File: CollectionFactoryAutoProxy.sol
// Copyright 2022 Energi Core
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
// Energi Governance system is the fundamental part of Energi Core.
// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.
/**
 * CollectionFactoryAutoProxy is a version of GovernedContract which deploys its own proxy.
 * This is useful to avoid a circular dependency between GovernedContract and GovernedProxy
 * wherein they need each other's address in the constructor.
 * If you want a new governed contract to create a proxy, pass address(0) when deploying
 * otherwise, you can pass a proxy address like in normal GovernedContract
 */
contract CollectionFactoryAutoProxy is GovernedContract {
    constructor(
        address _proxy,
        address _implementation
    ) public GovernedContract(_proxy) {
        if (_proxy == address(0)) {
            _proxy = address(
                new CollectionFactoryGovernedProxy(_implementation)
            );
        }
        proxy = _proxy;
    }
}
// File: ../../StorageBase.sol
// Copyright 2022 Energi Core
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
/**
 * Base for contract storage (SC-14).
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */
contract StorageBase {
    address payable internal owner;
    modifier requireOwner {
        require (msg.sender == address(owner), 'StorageBase: Not owner!');
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
// File: ../collectionStorage/CollectionStorage.sol
// Copyright 2022 Energi Core
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
contract CollectionStorage is StorageBase {
    // Struct specifying a whitelisted smart contract address and the number of NFTs
    // that can be minted by a user that holds an NFT from this whitelisted smart contract
    struct SmartContractsWhitelistAllowance {
        address smartContract;
        uint8 allowance;
    }
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }
    // default royalty payment for all tokenIds
    RoyaltyInfo private defaultRoyaltyInfo;
    // royalty payment for individual tokenIds
    mapping(uint256 => RoyaltyInfo) private tokenRoyaltyInfo;
    // feeDenominator for royalty calculation
    uint96 feeDenominator = 10000;
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
    // totalSupply of the collection
    uint private totalSupply;
    // price in ETH that has to be paid for every minted NFT
    uint private PRICE_PER_NFT;
    // number of NFTs left to mint by users that hold NFTs from whitelisted smart contracts
    uint private REMAINING_WHITELIST_SMART_CONTRACT_ALLOWANCE;
    // maximum number of NFTs that can be minted per address during the public mint phase
    uint public MAX_PUBLIC_MINT_PER_ADDRESS;
    // maximum supply of NFTs in this collection
    uint public MAX_SUPPLY;
    // start block when the whitelist mint phase is enabled
    uint private blockStartWhitelistPhase;
    // end block when the whitelist mint phase is disabled
    uint private blockEndWhitelistPhase;
    // start block when the public mint phase is enabled
    uint private blockStartPublicPhase;
    // end block when the public mint phase is disabled
    uint private blockEndPublicPhase;
    // collection manager proxy address
    address private collectionManagerProxyAddress;
    // Mapping from token ID to owner address
    mapping(uint => address) private owners;
    // Mapping owner address to token count
    mapping(address => uint) private balances;
    // Mapping from token ID to approved address
    mapping(uint => address) private tokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private operatorApprovals;
    // Mapping from whitelisted user address to allowances
    mapping(address => uint8) private userAddressAllowancesWhitelist;
    // Array holding the whitelisted smart contract addresses and their allowances
    SmartContractsWhitelistAllowance[] private smartContractsAddressesAllowancesWhitelist;
    modifier requireManager {
        require(
            msg.sender == address(IGovernedProxy(address(uint160(collectionManagerProxyAddress))).implementation()),
            'CollectionStorage: FORBIDDEN, not CollectionManager'
        );
        _;
    }
    constructor(
        address _collectionManagerProxyAddress,
        string memory _baseURI,
        string memory _name,
        string memory _symbol,
        address _receiver,
        uint96 _royaltyFraction
    ) public {
        collectionManagerProxyAddress = _collectionManagerProxyAddress;
        baseURI = _baseURI;
        name = _name;
        symbol = _symbol;
        defaultRoyaltyInfo = RoyaltyInfo(_receiver, _royaltyFraction);
    }
    function getFeeDenominator() external view returns (uint96 _feeDenominator) {
        _feeDenominator = feeDenominator;
    }
    function getRoyaltyReceiver(uint tokenId) external view returns (address _royaltyReceiver) {
        _royaltyReceiver = tokenRoyaltyInfo[tokenId].receiver;
    }
    function getRoyaltyFraction(uint tokenId) external view returns (uint96 _royaltyFraction) {
         _royaltyFraction = tokenRoyaltyInfo[tokenId].royaltyFraction;
    }
    function getRoyaltyInfo(uint tokenId) external view returns (address _royaltyReceiver, uint96 _royaltyFraction) {
        _royaltyReceiver = tokenRoyaltyInfo[tokenId].receiver;
        _royaltyFraction = tokenRoyaltyInfo[tokenId].royaltyFraction;
    }
    function getDefaultRoyaltyReceiver() external view returns (address _defaultRoyaltyReceiver) {
        _defaultRoyaltyReceiver = defaultRoyaltyInfo.receiver;
    }
    function getDefaultRoyaltyFraction() external view returns (uint96 _defaultRoyaltyFraction) {
         _defaultRoyaltyFraction = defaultRoyaltyInfo.royaltyFraction;
    }
    function getDefaultRoyaltyInfo() external view returns (address _defaultRoyaltyReceiver, uint96 _defaultRoyaltyFraction) {
        _defaultRoyaltyReceiver = defaultRoyaltyInfo.receiver;
        _defaultRoyaltyFraction = defaultRoyaltyInfo.royaltyFraction;
    }
    function getCollectionManagerProxyAddress() external view returns(address _collectionManagerProxyAddress) {
        _collectionManagerProxyAddress = collectionManagerProxyAddress;
    }
    function getMovementNoticeURI() external view returns(string memory _movementNoticeURI) {
        _movementNoticeURI = movementNoticeURI;
    }
    function getCollectionMoved() external view returns(bool _collectionMoved) {
        _collectionMoved = collectionMoved;
    }
    function getPRICE_PER_NFT() external view returns(uint _PRICE_PER_NFT) {
        _PRICE_PER_NFT = PRICE_PER_NFT;
    }
    function getREMAINING_WHITELIST_SMART_CONTRACT_ALLOWANCE()
        external
        view
        returns(uint _REMAINING_WHITELIST_SMART_CONTRACT_ALLOWANCE)
    {
        _REMAINING_WHITELIST_SMART_CONTRACT_ALLOWANCE = REMAINING_WHITELIST_SMART_CONTRACT_ALLOWANCE;
    }
    function getMAX_PUBLIC_MINT_PER_ADDRESS() external view returns(uint _MAX_PUBLIC_MINT_PER_ADDRESS) {
        _MAX_PUBLIC_MINT_PER_ADDRESS = MAX_PUBLIC_MINT_PER_ADDRESS;
    }
    function getMAX_SUPPLY() external view returns(uint _MAX_SUPPLY) {
        _MAX_SUPPLY = MAX_SUPPLY;
    }
    function getBlockStartWhitelistPhase() external view returns(uint _blockStartWhitelistPhase) {
        _blockStartWhitelistPhase = blockStartWhitelistPhase;
    }
    function getBlockEndWhitelistPhase() external view returns(uint _blockEndWhitelistPhase) {
        _blockEndWhitelistPhase = blockEndWhitelistPhase;
    }
    function getBlockStartPublicPhase() external view returns(uint _blockStartPublicPhase) {
        _blockStartPublicPhase = blockStartPublicPhase;
    }
    function getBlockEndPublicPhase() external view returns(uint _blockEndPublicPhase) {
        _blockEndPublicPhase = blockEndPublicPhase;
    }
    function getTotalSupply() external view returns(uint _totalSupply) {
        _totalSupply = totalSupply;
    }
    function getSmartContractsWhitelistCount() external view returns(uint _count) {
        _count = smartContractsAddressesAllowancesWhitelist.length;
    }
    function getUserAddressWhitelistAllowance(address _address) external view returns(uint _allowance) {
        _allowance = userAddressAllowancesWhitelist[_address];
    }
    function getWhitelistedSmartContractAddressByIndex(uint _index)
        external
        view
        returns(address _smartContract)
    {
        _smartContract = smartContractsAddressesAllowancesWhitelist[_index].smartContract;
    }
    function getWhitelistedSmartContractAllowanceByIndex(uint _index)
        external
        view
        returns(uint8 _allowance)
    {
        _allowance = smartContractsAddressesAllowancesWhitelist[_index].allowance;
    }
    function getWhitelistedSmartContractsAddressAndAllowanceByIndex(uint _index)
        external
        view
        returns(address _smartContract, uint8 _allowance)
    {
        _smartContract = smartContractsAddressesAllowancesWhitelist[_index].smartContract;
        _allowance = smartContractsAddressesAllowancesWhitelist[_index].allowance;
    }
    function getOperatorApproval(address _owner, address _operator)
        external
        view
        returns(bool _approved)
    {
        _approved = operatorApprovals[_owner][_operator];
    }
    function getBalance(address _address) external view returns(uint _amount) {
        _amount = balances[_address];
    }
    function getTokenApproval(uint _tokenId) external view returns(address _address) {
        _address = tokenApprovals[_tokenId];
    }
    function getOwner(uint tokenId) external view returns(address _owner) {
        _owner = owners[tokenId];
    }
    function getName() external view returns(string memory _name) {
        _name = name;
    }
    function getSymbol() external view returns(string memory _symbol) {
        _symbol = symbol;
    }
    function getBaseURI() external view returns(string memory _baseURI) {
        _baseURI = baseURI;
    }
    function setDefaultRoyaltyInfo(address receiver, uint96 royaltyFraction) external requireManager {
        defaultRoyaltyInfo.receiver = receiver;
        defaultRoyaltyInfo.royaltyFraction = royaltyFraction;
    }
    function setRoyaltyInfo(uint tokenId, address receiver, uint96 royaltyFraction) external requireManager {
        tokenRoyaltyInfo[tokenId].receiver = receiver;
        tokenRoyaltyInfo[tokenId].royaltyFraction = royaltyFraction;
    }
    function setFeeDenominator(uint96 value) external requireManager {
        feeDenominator = value;
    }
    function setPRICE_PER_NFT(uint _value) external requireManager {
        PRICE_PER_NFT = _value;
    }
    function setREMAINING_WHITELIST_SMART_CONTRACT_ALLOWANCE(uint _value) external requireManager {
        REMAINING_WHITELIST_SMART_CONTRACT_ALLOWANCE = _value;
    }
    function setMAX_PUBLIC_MINT_PER_ADDRESS(uint _value) external requireManager {
        MAX_PUBLIC_MINT_PER_ADDRESS = _value;
    }
    function setMAX_SUPPLY(uint _value) external requireManager {
        MAX_SUPPLY = _value;
    }
    function setWhitelistPhase(uint _blockStartWhitelistPhase, uint _blockEndWhitelistPhase)
        external
        requireManager
    {
        blockStartWhitelistPhase = _blockStartWhitelistPhase;
        blockEndWhitelistPhase = _blockEndWhitelistPhase;
    }
    function setPublicPhase(uint _blockStartPublicPhase, uint _blockEndPublicPhase) external requireManager {
        blockStartPublicPhase = _blockStartPublicPhase;
        blockEndPublicPhase = _blockEndPublicPhase;
    }
    function setTotalSupply(uint _value) external requireManager {
        totalSupply = _value;
    }
    function setUserAddressWhitelistAllowance(address _address, uint8 _allowedMints) external requireManager {
        userAddressAllowancesWhitelist[_address] = _allowedMints;
    }
    function setSmartContractsWhitelistAllowance(uint _index, address _smartContract, uint8 _allowedMints)
        external
        requireManager
    {
        smartContractsAddressesAllowancesWhitelist[_index].smartContract = _smartContract;
        smartContractsAddressesAllowancesWhitelist[_index].allowance = _allowedMints;
    }
    function setWhitelistedSmartContractAddressByIndex(uint _index, address _smartContract)
        external
        requireManager
    {
        smartContractsAddressesAllowancesWhitelist[_index].smartContract = _smartContract;
    }
    function setWhitelistedSmartContractAllowanceByIndex(uint _index, uint8 _allowedMints)
        external
        requireManager
    {
        smartContractsAddressesAllowancesWhitelist[_index].allowance = _allowedMints;
    }
    function pushSmartContractsAddressesAllowancesWhitelist(address _smartContract, uint8 _allowedMints)
        external
        requireManager
    {
        smartContractsAddressesAllowancesWhitelist.push(SmartContractsWhitelistAllowance({
	    smartContract : _smartContract,
            allowance : _allowedMints
        }));
    }
    function popSmartContractsAddressesAllowancesWhitelist() external requireManager {
        smartContractsAddressesAllowancesWhitelist.pop();
    }
    function setName(string calldata _name) external requireManager {
        name = _name;
    }
    function setSymbol(string calldata _symbol) external requireManager {
        symbol = _symbol;
    }
    function setBaseURI(string calldata _baseURI) external requireManager {
        baseURI = _baseURI;
    }
    function setBalance(address _address, uint _amount) external requireManager {
        balances[_address] = _amount;
    }
    function setOwner(uint tokenId, address owner) external requireManager {
        owners[tokenId] = owner;
    }
    function setTokenApproval(uint _tokenId, address _address) external requireManager {
        tokenApprovals[_tokenId] = _address;
    }
    function setOperatorApproval(address _owner, address _operator, bool _approved) external requireManager {
        operatorApprovals[_owner][_operator] = _approved;
    }
    function setCollectionMoved(bool _collectionMoved) external requireManager {
        collectionMoved = _collectionMoved;
    }
    function setCollectionManagerProxyAddress(address _collectionManagerProxyAddress) external requireManager {
        collectionManagerProxyAddress = _collectionManagerProxyAddress;
    }
    function setMovementNoticeURI(string calldata _movementNoticeURI) external requireManager {
        movementNoticeURI = _movementNoticeURI;
    }
}
// File: ../../interfaces/IERC721Manager.sol
// Copyright 2022 Energi Core
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
interface IERC721Manager  {
    function owner() external view returns (address);
    function safeMint(
        address collectionProxy,
        address msgSender,
        address to,
        uint tokenId
    ) external payable;
    function setApprovalForAll(
        address collectionProxy,
        address ownerToken,
        address operator,
        bool approved
    ) external;
    function transferFrom(
        address collectionProxy,
        address msgSender,
        address from,
        address to,
        uint256 tokenId
    ) external;
    function safeTransferFrom(
        address collectionProxy,
        address msgSender,
        address from,
        address to,
        uint256 tokenId,
        bytes calldata _data
    ) external;
    function royaltyInfo(address collectionProxy, uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address, uint256);
    function approve(address collectionProxy, address msgSender, address to, uint256 tokenId) external;
    function burn(address collectionProxy, address msgSender, uint256 tokenId) external;
    function getApproved(address collectionProxy, uint256 tokenId) external view returns (address);
    function balanceOf(address collectionProxy, address user) external view returns (uint256);
    function ownerOf(address collectionProxy, uint256 tokenId) external view returns (address);
    function isApprovedForAll(address collectionProxy, address ownerToken, address operator) external view returns (bool);
    function tokenURI(address collectionProxy, uint256 tokenId) external view returns (string memory);
    function name(address collectionProxy) external view returns (string memory);
    function symbol(address collectionProxy) external view returns (string memory);
}
// File: ../collectionProxy/ICollectionProxy.sol
// Copyright 2022 Energi Core
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
interface ICollectionProxy {
    function safeMint(address to, uint numberOfTokens) external payable;
    function burn(uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata _data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address user) external view returns (uint256);
    function getApproved(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}
// File: ../collectionProxy/CollectionProxy.sol
// Copyright 2022 The Energi Core Authors
// This file is part of Energi Core.
//
// Energi Core is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Energi Core is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Energi Core. If not, see <http://www.gnu.org/licenses/>.
// Energi Governance system is the fundamental part of Energi Core.
// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.
/**
 * SC-9: This contract has no chance of being updated. It must be stupid simple.
 *
 * If another upgrade logic is required in the future - it can be done as proxy stage II.
 */
contract CollectionProxy is NonReentrant, ICollectionProxy {
    address public collectionManagerProxy;
    modifier senderOrigin {
        // Internal calls are expected to use implementation directly.
        // That's due to use of call() instead of delegatecall() on purpose.
        // solium-disable-next-line security/no-tx-origin
        require(
            tx.origin == msg.sender,
            'CollectionProxy::senderOrigin: FORBIDDEN, not a direct call'
        );
        _;
    }
    function collectionManager() private view returns(address _collectionManager) {
        _collectionManager = address(IGovernedProxy(address(uint160(collectionManagerProxy))).implementation());
    }
    modifier requireManager {
        require(msg.sender == collectionManager(), 'CollectionProxy::requireManager: FORBIDDEN, not CollectionManager');
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
    function emitTransfer(address from, address to, uint256 tokenId)
        external
        requireManager
    {
       emit Transfer(from, to, tokenId);
    }
    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    function emitApproval(address owner, address approved, uint256 tokenId)
        external
        requireManager
    {
       emit Approval(owner, approved, tokenId);
    }
    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    function emitApprovalForAll(address owner, address operator, bool approved)
        external
        requireManager
    {
       emit ApprovalForAll(owner, operator,approved);
    }
    function safeMint(address to, uint numberOfTokens)
        external
        payable
    {
        IERC721Manager(address(uint160(address(collectionManager())))).safeMint.value(msg.value)(
	        address(this),
	        msg.sender,
	        to,
	        numberOfTokens
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
        IERC721Manager(address(uint160(address(collectionManager())))).burn(address(this), msg.sender, tokenId);
    }
    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) external {
        IERC721Manager(address(uint160(address(collectionManager())))).approve(address(this), msg.sender, to, tokenId);
    }
    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) external {
        IERC721Manager(address(uint160(address(collectionManager())))).setApprovalForAll(
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
        IERC721Manager(address(uint160(address(collectionManager())))).transferFrom(
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
        IERC721Manager(address(uint160(address(collectionManager())))).safeTransferFrom(
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
        IERC721Manager(address(uint160(address(collectionManager())))).safeTransferFrom(
            address(this),
            msg.sender,
            from,
            to,
            tokenId,
            ''
        );
    }
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        return IERC721Manager(collectionManager()).royaltyInfo(address(this), tokenId, salePrice);
    }
    function ownerOf(uint256 tokenId) external view returns (address) {
        return IERC721Manager(collectionManager()).ownerOf(address(this), tokenId);
    }
    function balanceOf(address user) external view returns (uint256) {
        return IERC721Manager(collectionManager()).balanceOf(address(this), user);
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
    function owner() external view returns (address) {
       return IERC721Manager(collectionManager()).owner();
    }
    // Proxy all other calls to CollectionManager.
    function ()
        external
        payable
        senderOrigin
    {
        // SECURITY: senderOrigin() modifier is mandatory
        address _collectionManager = collectionManager();
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let res := call(sub(gas(), 10000), _collectionManager, callvalue(), ptr, calldatasize(), 0, 0)
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
// File: ../../Ownable.sol
// Copyright 2022 Energi Core
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }
  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require (msg.sender == owner, "Ownable: Not owner");
    _;
  }
  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require (newOwner != address(0), "Ownable: Zero address not allowed");
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}
// File: IFactoryGovernedProxy.sol
// Copyright 2022 Energi Core
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
// Energi Governance system is the fundamental part of Energi Core.
// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.
interface IFactoryGovernedProxy {
    event CollectionCreated(
	address collectionProxyAddress,
	address collectionStorageAddress,
	string baseURI,
	string name,
	string symbol,
	uint collectionLength
    );
    function emitCollectionCreated(
	address collectionProxyAddress,
	address collectionStorageAddress,
	string calldata baseURI,
	string calldata name,
	string calldata symbol,
	uint collectionLength
    ) external;
    function setSporkProxy(address payable _sporkProxy) external;
}
// File: ../../interfaces/ICollectionManager.sol
// Copyright 2022 Energi Core
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
interface ICollectionManager {
    function register(address _collectionProxy, address _collectionStorage) external;
}
// File: ../../interfaces/IStorageBase.sol
// Copyright 2022 Energi Core
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
interface IStorageBase {
    function setOwner(address _newOwner) external;
}
// File: ICollectionFactory.sol
// Copyright 2022 Energi Core
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
interface ICollectionFactory {
    function deploy(
        string calldata baseURI,
        string calldata name,
        string calldata symbol,
        address receiver,
        uint96 royaltyFraction
    ) external;
    function getCollectionProxyAddress(uint256 _i) external view returns (address);
    function getCollectionManagerProxy() external view returns (address);
}
// File: CollectionFactory.sol
// Copyright 2022 Energi Core
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
contract CollectionFactoryStorage is StorageBase {
    address private collectionManagerProxy;
    address[] private collectionProxyAddresses;
    constructor(address _collectionManagerProxy) public {
        collectionManagerProxy = _collectionManagerProxy;
    }
    function getCollectionManagerProxy() external view returns (address) {
        return collectionManagerProxy;
    }
    function getCollectionProxyAddress(uint256 _i) external view returns (address) {
        return collectionProxyAddresses[_i];
    }
    function getCollectionProxyAddressesLength() external view returns (uint256) {
        return collectionProxyAddresses.length;
    }
    function pushCollectionProxyAddress(address collectionProxyAddress) external requireOwner {
        collectionProxyAddresses.push(collectionProxyAddress);
    }
    function popCollectionProxyAddress() external requireOwner {
        collectionProxyAddresses.pop();
    }
    function setCollectionProxyAddresses(uint256 _i, address collectionProxyAddress) external requireOwner {
        collectionProxyAddresses[_i] = collectionProxyAddress;
    }
    function setCollectionManagerProxy(address _collectionManagerProxy) external requireOwner {
        collectionManagerProxy = _collectionManagerProxy;
    }
}
contract CollectionFactory is
    Ownable,
    NonReentrant,
    CollectionFactoryAutoProxy,
    ICollectionFactory
{
    bool public initialized = false;
    CollectionFactoryStorage public _storage;
    constructor(
        address _proxy
    )
        public
        CollectionFactoryAutoProxy(_proxy, address(this))
    {
    }
    function setSporkProxy(address payable _sporkProxy) public onlyOwner {
        IFactoryGovernedProxy(proxy).setSporkProxy(_sporkProxy);
    }
    // Initialize contract. This function can only be called once
    function initialize(address _collectionManagerProxy) external onlyOwner {
        require(!initialized, 'CollectionFactory: already initialized');
        _storage = new CollectionFactoryStorage(_collectionManagerProxy);
        initialized = true;
    }
    // This function is called in order to upgrade to a new CollectionFactory implementation
    function destroy(IGovernedContract _newImpl) external requireProxy {
        IStorageBase(address(_storage)).setOwner(address(_newImpl));
        // Self destruct
        _destroy(_newImpl);
    }
    // This function (placeholder) would be called on the new implementation if necessary for the upgrade
    function migrate(IGovernedContract _oldImpl) external requireProxy {
        _migrate(_oldImpl);
    }
    function collectionManagerImpl() private view returns(address _collectionManagerImpl) {
        _collectionManagerImpl = address(IGovernedProxy(address(uint160(_storage.getCollectionManagerProxy()))).implementation());
    }
    // permissioned functions
    function deploy(
        string calldata baseURI,
        string calldata name,
        string calldata symbol,
        address receiver,
        uint96 royaltyFraction
    ) external onlyOwner {
        address collectionStorageAddress = address(new CollectionStorage(
            _storage.getCollectionManagerProxy(),
            baseURI,
            name,
            symbol,
            receiver,
            royaltyFraction
            )
        );
        address collectionProxyAddress;
        // Deploy CollectionProxy via CREATE2
        bytes memory bytecode = abi.encodePacked(
            type(CollectionProxy).creationCode,
            abi.encode(
                _storage.getCollectionManagerProxy()
            )
        );
        bytes32 salt = keccak256(abi.encode(_storage.getCollectionProxyAddressesLength() + 1));
        assembly {
            collectionProxyAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        // Register CollectionProxy, and CollectionStorage into CollectionManager
        ICollectionManager(collectionManagerImpl()).register(collectionProxyAddress, collectionStorageAddress);
        _storage.pushCollectionProxyAddress(collectionProxyAddress);
        // Emit collection creation event
        IFactoryGovernedProxy(address(uint160(proxy))).emitCollectionCreated(
            collectionProxyAddress,
            collectionStorageAddress,
            baseURI,
            name,
            symbol,
            _storage.getCollectionProxyAddressesLength()
        );
    }
    function getCollectionProxyAddress(uint256 _i) external view returns (address) {
        return _storage.getCollectionProxyAddress(_i);
    }
    function getCollectionManagerProxy() external view returns (address) {
        return _storage.getCollectionManagerProxy();
    }
}