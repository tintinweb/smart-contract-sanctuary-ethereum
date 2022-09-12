// SPDX-License-Identifier: MIT

/*********************************************************
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░  .░░░░░░░░░░░░░░░░░░░░░░░░.  ҹ░░░░░░░░░░░░*
*░░░░░░░░░░░░░  ∴░░░░░░░░░░░░░░░░░░`   ░░․  ░░∴   (░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º   ҹ  ░   (░░░░░░░░*
*░░░░░⁕  .░░░░░░░░░░░░░░░░░░░░░░░     ⁕..    .∴,    ⁕░░░░*
*░░░░░░  ∴░░░░░░░░░░░░░░░░░░░░░░░ҹ ,(º⁕ҹ     ․∴ҹ⁕(. ⁕░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º`  ․░  ⁕,   ░░░░░░░░*
*░░░░░,  .░░░░░░░░░░░░░░░░░░░░░░░░░`  ,░░⁕  ∴░░   `░░░░░░*
*░░░░░░⁕º░░░░░░░░░░░░░░⁕   ҹ░░░░░░░░░░░░░,  %░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░ҹ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░ҹ   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░º(░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*********************************************************/

pragma solidity ^0.8.6;

import "@solidstate/contracts/introspection/ERC165Storage.sol";

import {ERC5050, Action, Object, Address, Strings} from "./ERC5050/ERC5050.sol";
import {LibERC721AUpgradeable} from './ERC721A/LibERC721AUpgradeable.sol';
import {ERC5050Storage} from "./ERC5050/ERC5050Storage.sol";
import { IERC5050Sender, IERC5050Receiver } from "../interfaces/IERC5050.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import { CallProtection } from "./shared/Access/CallProtection.sol";
import "../../coin/ISpellsCoin.sol";

import {SpellsCastStorage} from "./SpellsCastStorage.sol";
import {SpellsStorage} from "./SpellsStorage.sol";

contract SpellsActionFacet is ERC5050, CallProtection {
    using SpellsCastStorage for SpellsCastStorage.Storage;
    using ERC165Storage for ERC165Storage.Layout;
    using Address for address;

    function initializeSpellsActionFacet(address _spellsCoin) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        SpellsCastStorage.Storage storage es = SpellsCastStorage.getStorage();

        require(msg.sender == ds.contractOwner, "Must own the contract.");

        es.spellsCoin = ISpellsCoin(_spellsCoin);
        es.spellsCoinMultiplier = 1e10 gwei; // 10 tokens per mint unit
        es.tyClaimThreshold = 64;
        es.tyjackpot = 2000 * es.spellsCoinMultiplier;
        es.tyfirstSolveBonus = 1000 * es.spellsCoinMultiplier;

        ERC165Storage.Layout storage erc165 = ERC165Storage.layout();
        erc165.setSupportedInterface(type(IERC5050Sender).interfaceId, true);
        erc165.setSupportedInterface(type(IERC5050Receiver).interfaceId, true);
        _registerAction("cast");
    }

    /// @dev Claim your $DUST from the TYJACKPOT after `tyClaimThreshold` reached.
    function MISCHIEF_MANAGED(address _contract) external {
        SpellsCastStorage.Storage storage es = SpellsCastStorage.getStorage();
        require(!es.tys[_contract], "already claimed");
        require(_contract != address(0), "empty address");
        require(
            es.contractCasts[_contract] >= es.tyClaimThreshold,
            "not enough spells cast on contract"
        );
        // Verify caller is contract owner
        (bool success, bytes memory returnData) = _contract.staticcall(
            abi.encodeWithSignature("owner()")
        );
        require(success, "owner() failed");
        address owner = abi.decode(returnData, (address));
        require(msg.sender == owner, "sender is not owner");

        uint256 amount = es.tyjackpot + es.tyfirstSolveBonus;
        if (es.tyfirstSolveBonus != 0) {
            es.tyfirstSolveBonus = 0;
        }
        es.tyjackpot = (es.tyjackpot / 20) * 19;
        es.tys[_contract] = true;
        es.spellsCoin.mint(msg.sender, amount);
    }
    
    /// @dev Set the claim threshold for TYJACKPOT.
    function setTYClaimThreshold(uint256 _tyClaimThreshold) external protectedCall {
        SpellsCastStorage.getStorage().tyClaimThreshold = _tyClaimThreshold;
    }
    
    function setProxyRegistry(address registry) external protectedCall  {
        ERC5050Storage.setProxyRegistry(registry);
    }

    function compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        if (bytes(a).length != bytes(b).length) {
            return false;
        }
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    /// @dev Mine `spellsCoinMultiplier` $DUST to `from` and `to`, each up to 2x initial spellsCoin 
    ///     amount.
    function _mineSpellsCoin(uint256 from, uint256 to) private {
        SpellsCastStorage.Storage storage es = SpellsCastStorage.getStorage();
        uint256 limit = SpellsStorage.mineOpCap(to);
        bool toMaxed = es.tokenSpellsCoinMined[to] >= limit;
        limit = SpellsStorage.mineOpCap(from);
        bool fromMaxed = es.tokenSpellsCoinMined[from] >= limit;
        require(!toMaxed || !fromMaxed, "Spells: both tokens fully mined");
        if (!fromMaxed) {
            es.spellsCoin.mint(address(this), from, es.spellsCoinMultiplier);
            ++es.tokenSpellsCoinMined[from];
        }
        if (!toMaxed) {
            es.spellsCoin.mint(address(this), to, es.spellsCoinMultiplier);
            ++es.tokenSpellsCoinMined[to];
        }
    }

    /// @dev Send ERC-5050 action.
    function sendAction(Action memory action)
        public
        payable
        override
        onlySendableAction(action)
    {
        require(
            LibERC721AUpgradeable.ownerOf(action.from._tokenId) == action.user,
            "Spells: sender does not own token"
        );
        if (
            action.to._address != address(this) &&
            action.to._address.isContract()
        ) {
            ++SpellsCastStorage.getStorage().contractCasts[action.to._address];
        }
        return _sendAction(action);
    }

    /// @dev Wraps `sendAction()` for spell casting.
    function cast(
        uint256 tokenId,
        address to,
        uint256 toTokenId,
        bytes memory data
    ) external payable {
        sendAction(
            Action(
                SpellsCastStorage.CAST_SELECTOR(),
                msg.sender,
                Object(address(this), tokenId),
                Object(to, toTokenId),
                address(0),
                data
            )
        );
    }

    function onActionReceived(Action calldata action, uint256 _nonce)
        external
        payable
        override
        onlyReceivableAction(action, _nonce)
    {
        require(action.to._tokenId > 0, "Spells: cast to zero token");
        if (action.from._address == address(this)) {
            require(action.from._tokenId > 0, "Spells: cast from zero token");
            require(
                action.user != LibERC721AUpgradeable.ownerOf(action.to._tokenId),
                "Spells: Must be held by different wallets"
            );
            _mineSpellsCoin(action.from._tokenId, action.to._tokenId);
        }
        _onActionReceived(action, _nonce);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // owner of the contract
        address contractOwner;
        // treasury address
        address treasury;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    
    event TreasuryTransferred(
        address indexed previousTreasury,
        address indexed newTreasury
    );

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }
    
    function setTreasury(address _treasury) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousTreasury = ds.treasury;
        ds.treasury = _treasury;
        emit TreasuryTransferred(previousTreasury, _treasury);
    }

    function treasury() internal view returns (address treasury_) {
        treasury_ = diamondStorage().treasury;
        if(treasury_ == address(0)) {
            treasury_ = contractOwner();
        }
    }

    function enforceIsContractOwner() internal view {
        require(
            msg.sender == diamondStorage().contractOwner,
            "LibDiamond: Must be contract owner"
        );
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress == address(0),
                "LibDiamondCut: Can't add function that already exists"
            );
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(
            _facetAddress == address(0),
            "LibDiamondCut: Remove facet address must be address(0)"
        );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress)
        internal
    {
        enforceHasContractCode(
            _facetAddress,
            "LibDiamondCut: New facet has no code"
        );
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds
            .facetAddresses
            .length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
            _selector
        );
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Can't remove function that doesn't exist"
        );
        // an immutable function is a function defined directly in a diamond
        require(
            _facetAddress != address(this),
            "LibDiamondCut: Can't remove immutable function"
        );
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                    selectorPosition
                ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "LibDiamondCut: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "LibDiamondCut: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                enforceHasContractCode(
                    _init,
                    "LibDiamondCut: _init address has no code"
                );
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/// @title ERC-5050 Proxy Registry
///  Note: the ERC-165 identifier for this interface is 0x01ffc9a7
interface IERC5050RegistryClient {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Query if an address implements an interface and through which contract.
    /// @param _addr Address being queried for the implementer of an interface.
    /// (If '_addr' is the zero address then 'msg.sender' is assumed.)
    /// @param _interfaceHash Keccak256 hash of the name of the interface as a string.
    /// E.g., 'web3.utils.keccak256("ERC777TokensRecipient")' for the 'ERC777TokensRecipient' interface.
    /// @return The address of the contract which implements the interface '_interfaceHash' for '_addr'
    /// or '0' if '_addr' did not register an implementer for this interface.
    function getInterfaceImplementer(address _addr, bytes32 _interfaceHash) external view returns (address);

    /// @notice Get the manager of an address.
    /// @param _addr Address for which to return the manager.
    /// @return Address of the manager for a given address.
    function getManager(address _addr) external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/**********************************************************\
* Author: hypervisor <[email protected]> (https://twitter.com/0xalxi)
* EIP-5050 Token Interaction Standard: https://eips.ethereum.org/EIPS/eip-5050
*
* Implementation of an interactive token protocol.
/**********************************************************/

/// @title ERC-5050 Token Interaction Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-xxx
interface IERC5050Sender {
    /// @notice Send an action to the target address
    /// @dev The action's `fromContract` is automatically set to `address(this)`,
    /// and the `from` parameter is set to `msg.sender`.
    /// @param action The action to send
    function sendAction(Action memory action) external payable;

    /// @notice Check if an action is valid based on its hash and nonce
    /// @dev When an action passes through all three possible contracts
    /// (`fromContract`, `to`, and `state`) the `state` contract validates the
    /// action with the initating `fromContract` using a nonced action hash.
    /// This hash is calculated and saved to storage on the `fromContract` before
    /// action handling is initiated. The `state` contract calculates the hash
    /// and verifies it and nonce with the `fromContract`.
    /// @param _hash The hash to validate
    /// @param _nonce The nonce to validate
    function isValid(bytes32 _hash, uint256 _nonce) external returns (bool);

    /// @notice Retrieve list of actions that can be sent.
    /// @dev Intended for use by off-chain applications to query compatible contracts.
    function sendableActions() external view returns (string[] memory);

    /// @notice Change or reaffirm the approved address for an action
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the `_account`, or an authorized
    ///  operator of the `_account`.
    /// @param _account The account of the account-action pair to approve
    /// @param _action The action of the account-action pair to approve
    /// @param _approved The new approved account-action controller
    function approveForAction(
        address _account,
        bytes4 _action,
        address _approved
    ) external returns (bool);

    /// @notice Enable or disable approval for a third party ("operator") to conduct
    ///  all actions on behalf of `msg.sender`
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAllActions(address _operator, bool _approved)
        external;

    /// @notice Get the approved address for an account-action pair
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _account The account of the account-action to find the approved address for
    /// @param _action The action of the account-action to find the approved address for
    /// @return The approved address for this account-action, or the zero address if
    ///  there is none
    function getApprovedForAction(address _account, bytes4 _action)
        external
        view
        returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _account The address on whose behalf actions are performed
    /// @param _operator The address that acts on behalf of the account
    /// @return True if `_operator` is an approved operator for `_account`, false otherwise
    function isApprovedForAllActions(address _account, address _operator)
        external
        view
        returns (bool);

    /// @dev This emits when an action is sent (`sendAction()`)
    event SendAction(
        bytes4 indexed name,
        address _from,
        address indexed _fromContract,
        uint256 _tokenId,
        address indexed _to,
        uint256 _toTokenId,
        address _state,
        bytes _data
    );

    /// @dev This emits when the approved address for an account-action pair
    ///  is changed or reaffirmed. The zero address indicates there is no
    ///  approved address.
    event ApprovalForAction(
        address indexed _account,
        bytes4 indexed _action,
        address indexed _approved
    );

    /// @dev This emits when an operator is enabled or disabled for an account.
    ///  The operator can conduct all actions on behalf of the account.
    event ApprovalForAllActions(
        address indexed _account,
        address indexed _operator,
        bool _approved
    );
}

interface IERC5050Receiver {
    /// @notice Handle an action
    /// @dev Both the `to` contract and `state` contract are called via
    /// `onActionReceived()`.
    /// @param action The action to handle
    function onActionReceived(Action calldata action, uint256 _nonce)
        external
        payable;

    /// @notice Retrieve list of actions that can be received.
    /// @dev Intended for use by off-chain applications to query compatible contracts.
    function receivableActions() external view returns (string[] memory);

    /// @dev This emits when a valid action is received.
    event ActionReceived(
        bytes4 indexed name,
        address _from,
        address indexed _fromContract,
        uint256 _tokenId,
        address indexed _to,
        uint256 _toTokenId,
        address _state,
        bytes _data
    );
}

/// @title ERC-5050 Token Interaction Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-xxx
interface IERC5050{
    /// @notice Send an action to the target address
    /// @dev The action's `fromContract` is automatically set to `address(this)`,
    /// and the `from` parameter is set to `msg.sender`.
    /// @param action The action to send
    function sendAction(Action memory action) external payable;

    /// @notice Check if an action is valid based on its hash and nonce
    /// @dev When an action passes through all three possible contracts
    /// (`fromContract`, `to`, and `state`) the `state` contract validates the
    /// action with the initating `fromContract` using a nonced action hash.
    /// This hash is calculated and saved to storage on the `fromContract` before
    /// action handling is initiated. The `state` contract calculates the hash
    /// and verifies it and nonce with the `fromContract`.
    /// @param _hash The hash to validate
    /// @param _nonce The nonce to validate
    function isValid(bytes32 _hash, uint256 _nonce) external returns (bool);

    /// @notice Retrieve list of actions that can be sent.
    /// @dev Intended for use by off-chain applications to query compatible contracts.
    function sendableActions() external view returns (string[] memory);

    /// @notice Change or reaffirm the approved address for an action
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the `_account`, or an authorized
    ///  operator of the `_account`.
    /// @param _account The account of the account-action pair to approve
    /// @param _action The action of the account-action pair to approve
    /// @param _approved The new approved account-action controller
    function approveForAction(
        address _account,
        bytes4 _action,
        address _approved
    ) external returns (bool);

    /// @notice Enable or disable approval for a third party ("operator") to conduct
    ///  all actions on behalf of `msg.sender`
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAllActions(address _operator, bool _approved)
        external;

    /// @notice Get the approved address for an account-action pair
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _account The account of the account-action to find the approved address for
    /// @param _action The action of the account-action to find the approved address for
    /// @return The approved address for this account-action, or the zero address if
    ///  there is none
    function getApprovedForAction(address _account, bytes4 _action)
        external
        view
        returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _account The address on whose behalf actions are performed
    /// @param _operator The address that acts on behalf of the account
    /// @return True if `_operator` is an approved operator for `_account`, false otherwise
    function isApprovedForAllActions(address _account, address _operator)
        external
        view
        returns (bool);

    /// @dev This emits when an action is sent (`sendAction()`)
    event SendAction(
        bytes4 indexed name,
        address _from,
        address indexed _fromContract,
        uint256 _tokenId,
        address indexed _to,
        uint256 _toTokenId,
        address _state,
        bytes _data
    );

    /// @dev This emits when the approved address for an account-action pair
    ///  is changed or reaffirmed. The zero address indicates there is no
    ///  approved address.
    event ApprovalForAction(
        address indexed _account,
        bytes4 indexed _action,
        address indexed _approved
    );

    /// @dev This emits when an operator is enabled or disabled for an account.
    ///  The operator can conduct all actions on behalf of the account.
    event ApprovalForAllActions(
        address indexed _account,
        address indexed _operator,
        bool _approved
    );
    
    /// @notice Handle an action
    /// @dev Both the `to` contract and `state` contract are called via
    /// `onActionReceived()`.
    /// @param action The action to handle
    function onActionReceived(Action calldata action, uint256 _nonce)
        external
        payable;

    /// @notice Retrieve list of actions that can be received.
    /// @dev Intended for use by off-chain applications to query compatible contracts.
    function receivableActions() external view returns (string[] memory);

    /// @dev This emits when a valid action is received.
    event ActionReceived(
        bytes4 indexed name,
        address _from,
        address indexed _fromContract,
        uint256 _tokenId,
        address indexed _to,
        uint256 _toTokenId,
        address _state,
        bytes _data
    );
}

/// @param _address The address of the interactive object
/// @param tokenId The token that is interacting (optional)
struct Object {
    address _address;
    uint256 _tokenId;
}

/// @param name The name of the action
/// @param user The address of the sender
/// @param from The initiating object
/// @param to The receiving object
/// @param state The state contract
/// @param data Additional data with no specified format
struct Action {
    bytes4 selector;
    address user;
    Object from;
    Object to;
    address state;
    bytes data;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/*******************************************************************\
* Author: Hypervisor <[email protected]> (https://twitter.com/0xalxi)
* EIP-5050 Metaverse Protocol: https://eips.ethereum.org/EIPS/eip-5050
*
* Implementation of a metaverse protocol.
/*******************************************************************/

pragma solidity ^0.8.0;

/// @title EIP-5050 Action Controller
interface IControllable {
    
    /// @notice Enable or disable approval for a third party ("controller") to force
    ///  handling of a given action without performing EIP-5050 validity checks.
    /// @dev Emits the ControllerApproval event. The contract MUST allow
    ///  an unbounded number of controllers per action.
    /// @param _controller Address to add to the set of authorized controllers
    /// @param _action Selector of the action for which the controller is approved / disapproved
    /// @param _approved True if the controller is approved, false to revoke approval
    function setControllerApproval(address _controller, bytes4 _action, bool _approved)
        external;

    /// @notice Enable or disable approval for a third party ("controller") to force
    ///  action handling without performing EIP-5050 validity checks. 
    /// @dev Emits the ControllerApproval event. The contract MUST allow
    ///  an unbounded number of controllers per action.
    /// @param _controller Address to add to the set of authorized controllers
    /// @param _approved True if the controller is approved, false to revoke approval
    function setControllerApprovalForAll(address _controller, bool _approved)
        external;

    /// @notice Query if an address is an authorized controller for a given action.
    /// @param _controller The trusted third party address that can force action handling
    /// @param _action The action selector to query against
    /// @return True if `_controller` is an approved operator for `_account`, false otherwise
    function isApprovedController(address _controller, bytes4 _action)
        external
        view
        returns (bool);
    
    /// @dev This emits when a controller is enabled or disabled for the given
    ///  action. The controller can force `action` handling on the emitting contract, 
    ///  bypassing the standard EIP-5050 validity checks.
    event ControllerApproval(
        address indexed _controller,
        bytes4 indexed _action,
        bool _approved
    );
    
    /// @dev This emits when a controller is enabled or disabled for all actions.
    ///  Disabling all action approval for a controller does not override explicit action
    ///  action approvals. Controller's approved for all actions can force action handling 
    ///  on the emitting contract for any action.
    event ControllerApprovalForAll(
        address indexed _controller,
        bool _approved
    );
}

// SPDX-License-Identifier: MIT

/*********************************************************
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░  .░░░░░░░░░░░░░░░░░░░░░░░░.  ҹ░░░░░░░░░░░░*
*░░░░░░░░░░░░░  ∴░░░░░░░░░░░░░░░░░░`   ░░․  ░░∴   (░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º   ҹ  ░   (░░░░░░░░*
*░░░░░⁕  .░░░░░░░░░░░░░░░░░░░░░░░     ⁕..    .∴,    ⁕░░░░*
*░░░░░░  ∴░░░░░░░░░░░░░░░░░░░░░░░ҹ ,(º⁕ҹ     ․∴ҹ⁕(. ⁕░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º`  ․░  ⁕,   ░░░░░░░░*
*░░░░░,  .░░░░░░░░░░░░░░░░░░░░░░░░░`  ,░░⁕  ∴░░   `░░░░░░*
*░░░░░░⁕º░░░░░░░░░░░░░░⁕   ҹ░░░░░░░░░░░░░,  %░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░ҹ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░ҹ   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░º(░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*********************************************************/

pragma solidity ^0.8.6;

import "../../../libraries/LibDiamond.sol";

contract CallProtection {
    modifier protectedCall() {
        require(
            msg.sender == LibDiamond.diamondStorage().contractOwner ||
                msg.sender == address(this),
            "NOT_ALLOWED"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT

/*********************************************************
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░  .░░░░░░░░░░░░░░░░░░░░░░░░.  ҹ░░░░░░░░░░░░*
*░░░░░░░░░░░░░  ∴░░░░░░░░░░░░░░░░░░`   ░░․  ░░∴   (░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º   ҹ  ░   (░░░░░░░░*
*░░░░░⁕  .░░░░░░░░░░░░░░░░░░░░░░░     ⁕..    .∴,    ⁕░░░░*
*░░░░░░  ∴░░░░░░░░░░░░░░░░░░░░░░░ҹ ,(º⁕ҹ     ․∴ҹ⁕(. ⁕░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º`  ․░  ⁕,   ░░░░░░░░*
*░░░░░,  .░░░░░░░░░░░░░░░░░░░░░░░░░`  ,░░⁕  ∴░░   `░░░░░░*
*░░░░░░⁕º░░░░░░░░░░░░░░⁕   ҹ░░░░░░░░░░░░░,  %░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░ҹ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░ҹ   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░º(░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*********************************************************/

pragma solidity ^0.8.6;

library SpellsStorage {
    bytes32 constant SPELLS_TOKEN_STORAGE_POSITION =
        keccak256("spells.token.storage.location");

    // Minting sale state
    enum SaleState {
        CLOSED,
        PRESALE,
        OPEN,
        ETERNAL
    }

    struct Storage {
        uint256 seedMintPrice;
        // Token supply
        uint256 seedSupply;
        // Mint key limit counter
        mapping(address => uint256) mintCounts;
        // Token minting state
        SaleState saleState;
        // Spell gate
        address spellGate;
        // Godspell (founders)
        address godspell;
        // Spell random seeds
        mapping(uint256 => uint256) tokenSeed;
        // Last seed value
        uint256 seed;
        // Eternal mint start time
        uint256 eternalStartTime;
    }

    function getStorage() internal pure returns (Storage storage es) {
        bytes32 position = SPELLS_TOKEN_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
    
    function tokenSeed(uint256 _tokenId) internal view returns (uint256) {
        return getStorage().tokenSeed[_tokenId];
    }
    
    function initialSpellsCoinOf(uint256 _tokenId) internal view returns (uint256) {
        uint256 greatness = getStorage().tokenSeed[_tokenId] % 21;
        return greatness / 4 + 1;
    }
    
    function mineOpCap(uint256 _tokenId) internal view returns (uint256) {
        uint256 initial = initialSpellsCoinOf(_tokenId);
        return initial * 2;
    }
}

// SPDX-License-Identifier: MIT

/*********************************************************
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░  .░░░░░░░░░░░░░░░░░░░░░░░░.  ҹ░░░░░░░░░░░░*
*░░░░░░░░░░░░░  ∴░░░░░░░░░░░░░░░░░░`   ░░․  ░░∴   (░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º   ҹ  ░   (░░░░░░░░*
*░░░░░⁕  .░░░░░░░░░░░░░░░░░░░░░░░     ⁕..    .∴,    ⁕░░░░*
*░░░░░░  ∴░░░░░░░░░░░░░░░░░░░░░░░ҹ ,(º⁕ҹ     ․∴ҹ⁕(. ⁕░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º`  ․░  ⁕,   ░░░░░░░░*
*░░░░░,  .░░░░░░░░░░░░░░░░░░░░░░░░░`  ,░░⁕  ∴░░   `░░░░░░*
*░░░░░░⁕º░░░░░░░░░░░░░░⁕   ҹ░░░░░░░░░░░░░,  %░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░ҹ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░ҹ   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░º(░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*********************************************************/

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../../coin/ISpellsCoin.sol";

library SpellsCastStorage {
    bytes32 constant SPELLS_CAST_STORAGE_POSITION =
        keccak256("spells.cast.storage.location");

    bytes4 public constant _CAST_SELECTOR = bytes4(keccak256("cast"));

    struct Storage {
        ISpellsCoin spellsCoin;
        mapping(uint256 => uint256) tokenSpellsCoinMined;
        mapping(address => uint256) contractCastings;
        mapping(uint256 => uint256) factions;
        uint256 spellsCoinMultiplier;
        mapping(address => uint256) contractCasts;
        mapping(address => bool) tys;
        uint256 tyClaimThreshold;
        uint256 tyjackpot;
        uint256 tyfirstSolveBonus;
    }

    function getStorage() internal pure returns (Storage storage es) {
        bytes32 position = SPELLS_CAST_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
    
    function CAST_SELECTOR() internal pure returns (bytes4) {
        return _CAST_SELECTOR;
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function initialSpellsCoinOf(uint256 seed) internal pure returns (uint256) {
        uint256 rand = random(Strings.toString(seed));
        uint256 greatness = rand % 21;
        return greatness / 4 + 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721AStorage.sol";

library LibERC721AUpgradeable {
    
    using ERC721AStorage for ERC721AStorage.Layout;
    
    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;
    
    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;
    
    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();
    
    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();
    
    function name() internal view returns (string memory) {
        return ERC721AStorage.layout()._name;
    }
    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) internal view returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }
    
    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return ERC721AStorage.layout()._packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }
    
    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal pure returns (uint256) {
        /// 0-index reserved for public wild-card token.
        return 1;
    }

     /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) internal view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < ERC721AStorage.layout()._currentIndex) {
                    uint256 packed = ERC721AStorage.layout()._packedOwnerships[curr];
                    // If not burned.
                    if (packed & _BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an initialized ownership slot
                        // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                        // before an unintialized ownership slot
                        // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                        // Hence, `curr` will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed will be zero.
                        while (packed == 0) {
                            packed = ERC721AStorage.layout()._packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }
    
    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() internal view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return ERC721AStorage.layout()._currentIndex - ERC721AStorage.layout()._burnCounter - _startTokenId();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

library ERC721AStorage {
    // Bypass for a `--via-ir` bug (https://github.com/chiru-labs/ERC721A/pull/364).
    struct TokenApprovalRef {
        address value;
    }

    struct Layout {
        // =============================================================
        //                            STORAGE
        // =============================================================

        // The next token ID to be minted.
        uint256 _currentIndex;
        // The number of tokens burned.
        uint256 _burnCounter;
        // Token name
        string _name;
        // Token symbol
        string _symbol;
        // Mapping from token ID to ownership details
        // An empty struct value does not necessarily mean the token is unowned.
        // See {_packedOwnershipOf} implementation for details.
        //
        // Bits Layout:
        // - [0..159]   `addr`
        // - [160..223] `startTimestamp`
        // - [224]      `burned`
        // - [225]      `nextInitialized`
        // - [232..255] `extraData`
        mapping(uint256 => uint256) _packedOwnerships;
        // Mapping owner address to address data.
        //
        // Bits Layout:
        // - [0..63]    `balance`
        // - [64..127]  `numberMinted`
        // - [128..191] `numberBurned`
        // - [192..255] `aux`
        mapping(address => uint256) _packedAddressData;
        // Mapping from token ID to approved address.
        mapping(uint256 => ERC721AStorage.TokenApprovalRef) _tokenApprovals;
        // Mapping from owner to operator approvals
        mapping(address => mapping(address => bool)) _operatorApprovals;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('ERC721A.contracts.storage.ERC721A');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

/*********************************************************
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░  .░░░░░░░░░░░░░░░░░░░░░░░░.  ҹ░░░░░░░░░░░░*
*░░░░░░░░░░░░░  ∴░░░░░░░░░░░░░░░░░░`   ░░․  ░░∴   (░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º   ҹ  ░   (░░░░░░░░*
*░░░░░⁕  .░░░░░░░░░░░░░░░░░░░░░░░     ⁕..    .∴,    ⁕░░░░*
*░░░░░░  ∴░░░░░░░░░░░░░░░░░░░░░░░ҹ ,(º⁕ҹ     ․∴ҹ⁕(. ⁕░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º`  ․░  ⁕,   ░░░░░░░░*
*░░░░░,  .░░░░░░░░░░░░░░░░░░░░░░░░░`  ,░░⁕  ∴░░   `░░░░░░*
*░░░░░░⁕º░░░░░░░░░░░░░░⁕   ҹ░░░░░░░░░░░░░,  %░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░ҹ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░ҹ   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░º(░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*********************************************************/

pragma solidity ^0.8.6;

/**********************************************************************\
* Author: Hypervisor <[email protected]> (https://twitter.com/0xalxi)
* EIP-5050 Metaverse Protocol: https://eips.ethereum.org/EIPS/eip-5050
/**********************************************************************/

import {Action} from "../../interfaces/IERC5050.sol";
import {IERC5050Receiver, IERC5050Sender} from "../../interfaces/IERC5050.sol";
import {IERC5050RegistryClient} from "../../interfaces/IERC5050RegistryClient.sol";
import {ActionsSet} from "../../../common/ActionsSet.sol";

library ERC5050Storage {
    using ActionsSet for ActionsSet.Set;

    bytes32 constant ERC_5050_STORAGE_POSITION =
        keccak256("erc5050.storage.location");

    struct Layout {
        uint256 nonce;
        bytes32 _hash;
        IERC5050RegistryClient proxy;
        ActionsSet.Set _sendableActions;
        ActionsSet.Set _receivableActions;
        mapping(address => mapping(bytes4 => address)) actionApprovals;
        mapping(address => mapping(address => bool)) operatorApprovals;
        mapping(address => mapping(bytes4 => bool)) _actionControllers;
        mapping(address => bool) _universalControllers;
        uint256 senderLock;
        uint256 receiverLock;
    }

    function layout() internal pure returns (Layout storage es) {
        bytes32 position = ERC_5050_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
    
    function getReceiverManager(address _addr) internal view returns (address) {
        if(address(layout().proxy) == address(0)){
            return _addr;
        }
        return layout().proxy.getInterfaceImplementer(_addr, type(IERC5050Receiver).interfaceId);
    }
    
    function getSenderManager(address _addr) internal view returns (address) {
        if(address(layout().proxy) == address(0)){
            return _addr;
        }
        return layout().proxy.getInterfaceImplementer(_addr, type(IERC5050Sender).interfaceId);
    }
    
    function setProxyRegistry(address _addr) internal {
        layout().proxy = IERC5050RegistryClient(_addr);
    }

    function _validate(Layout storage l, Action memory action)
        internal
    {
        ++l.nonce;
        l._hash = bytes32(
            keccak256(
                abi.encodePacked(
                    action.selector,
                    action.user,
                    action.from._address,
                    action.from._tokenId,
                    action.to._address,
                    action.to._tokenId,
                    action.state,
                    action.data,
                    l.nonce
                )
            )
        );
    }
    
    function isValid(Layout storage l, bytes32 actionHash, uint256 nonce)
        internal
        view
        returns (bool)
    {
        return actionHash == l._hash && nonce == l.nonce;
    }
}

// SPDX-License-Identifier: MIT

/*********************************************************
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░  .░░░░░░░░░░░░░░░░░░░░░░░░.  ҹ░░░░░░░░░░░░*
*░░░░░░░░░░░░░  ∴░░░░░░░░░░░░░░░░░░`   ░░․  ░░∴   (░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º   ҹ  ░   (░░░░░░░░*
*░░░░░⁕  .░░░░░░░░░░░░░░░░░░░░░░░     ⁕..    .∴,    ⁕░░░░*
*░░░░░░  ∴░░░░░░░░░░░░░░░░░░░░░░░ҹ ,(º⁕ҹ     ․∴ҹ⁕(. ⁕░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º`  ․░  ⁕,   ░░░░░░░░*
*░░░░░,  .░░░░░░░░░░░░░░░░░░░░░░░░░`  ,░░⁕  ∴░░   `░░░░░░*
*░░░░░░⁕º░░░░░░░░░░░░░░⁕   ҹ░░░░░░░░░░░░░,  %░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░ҹ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░ҹ   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░º(░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*********************************************************/

pragma solidity ^0.8.6;

/*******************************************************************\
* Author: Hypervisor <[email protected]> (https://twitter.com/0xalxi)
* EIP-5050 Metaverse Protocol: https://eips.ethereum.org/EIPS/eip-5050
*
* Implementation of a metaverse protocol.
/*******************************************************************/

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {ERC5050Storage} from "./ERC5050Storage.sol";
import {IERC5050Sender, IERC5050Receiver, Action, Object} from "../../interfaces/IERC5050.sol";
import {IControllable} from "../../interfaces/IControllable.sol";
import {ActionsSet} from "../../../common/ActionsSet.sol";

contract ERC5050 is IERC5050Sender, IERC5050Receiver, IControllable {
    using ERC5050Storage for ERC5050Storage.Layout;
    using Address for address;
    using ActionsSet for ActionsSet.Set;
    
    error ZeroAddressDestination();
    error TransferToNonERC5050ReceiverImplementer();
    
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    function sendAction(Action memory action)
        external
        payable
        virtual
        override(IERC5050Sender)
    {
        _sendAction(action);
    }

    function _sendAction(Action memory action) internal {
        if (!_isApprovedController(msg.sender, action.selector)) {
            action.from._address = address(this);
            bool toIsContract = action.to._address.isContract();
            bool stateIsContract = action.state.isContract();
            address next;
            if (toIsContract) {
                next = action.to._address;
            } else if (stateIsContract) {
                next = action.state;
            }
            if (toIsContract && stateIsContract) {
                ERC5050Storage.layout()._validate(action);
            }
            if (next.isContract()) {
                next = ERC5050Storage.getReceiverManager(next);
                if(next == address(0)) revert ZeroAddressDestination();
                try
                    IERC5050Receiver(next).onActionReceived{value: msg.value}(
                        action,
                        ERC5050Storage.layout().nonce
                    )
                {} catch Error(string memory err) {
                    revert(err);
                } catch (bytes memory reason) {
                    if (reason.length == 0) {
                        revert TransferToNonERC5050ReceiverImplementer();
                    } else {
                        assembly {
                            revert(add(32, reason), mload(reason))
                        }
                    }
                }
            }
        }
        emit SendAction(
            action.selector,
            action.user,
            action.from._address,
            action.from._tokenId,
            action.to._address,
            action.to._tokenId,
            action.state,
            action.data
        );
    }
    
    function isValid(bytes32 actionHash, uint256 nonce)
        external
        view
        override(IERC5050Sender)
        returns (bool)
    {
        return ERC5050Storage.layout().isValid(actionHash, nonce);
    }
    
    modifier onlySendableAction(Action memory action) {
        if (_isApprovedController(msg.sender, action.selector)) {
            return;
        }
        ERC5050Storage.Layout storage store = ERC5050Storage.layout();
        require(store.senderLock != _ENTERED, "ERC5050: no re-entrancy");
        require(
            store._sendableActions.contains(action.selector),
            "ERC5050: invalid action"
        );
        require(
            _isApprovedOrSelf(action.user, action.selector),
            "ERC5050: unapproved sender"
        );
        require(
            action.from._address == address(this) ||
                ERC5050Storage.getSenderManager(action.from._address) == address(this),
            "ERC5050: invalid from address"
        );
        store.senderLock = _ENTERED;
        _;
        store.senderLock = _NOT_ENTERED;
    }
    
    function _isApprovedOrSelf(address account, bytes4 action)
        internal
        view
        returns (bool)
    {
        return (msg.sender == account ||
            isApprovedForAllActions(account, msg.sender) ||
            getApprovedForAction(account, action) == msg.sender);
    }

    modifier onlyReceivableAction(Action calldata action, uint256 nonce) {
        if (_isApprovedController(msg.sender, action.selector)) {
            return;
        }
        require(
            action.to._address == address(this),
            "ERC5050: invalid receiver"
        );
        ERC5050Storage.Layout storage store = ERC5050Storage.layout();
        require(store.receiverLock != _ENTERED, "ERC5050: no re-entrancy");
        require(
            store._receivableActions.contains(action.selector),
            "ERC5050: invalid action"
        );
        require(
            action.from._address == address(0) ||
                action.from._address == msg.sender,
            "ERC5050: invalid sender"
        );
        require(
            (action.from._address != address(0) && action.user == tx.origin) ||
                action.user == msg.sender,
            "ERC5050: invalid sender"
        );
        store.receiverLock = _ENTERED;
        _;
        store.receiverLock = _NOT_ENTERED;
    }

    function onActionReceived(Action calldata action, uint256 nonce)
        external
        payable
        virtual
        override(IERC5050Receiver)
        onlyReceivableAction(action, nonce)
    {
        _onActionReceived(action, nonce);
    }

    function _onActionReceived(Action calldata action, uint256 nonce)
        internal
        virtual
    {
        if (!_isApprovedController(msg.sender, action.selector)) {
            if (action.state != address(0)) {
                require(action.state.isContract(), "ERC5050: invalid state");
                try
                    IERC5050Receiver(action.state).onActionReceived{
                        value: msg.value
                    }(action, nonce)
                {} catch (bytes memory reason) {
                    if (reason.length == 0) {
                        revert("ERC5050: call to non ERC5050Receiver");
                    } else {
                        assembly {
                            revert(add(32, reason), mload(reason))
                        }
                    }
                }
            }
        }
        emit ActionReceived(
            action.selector,
            action.user,
            action.from._address,
            action.from._tokenId,
            action.to._address,
            action.to._tokenId,
            action.state,
            action.data
        );
    }
    
    function approveForAction(
        address _account,
        bytes4 _action,
        address _approved
    ) public virtual override(IERC5050Sender) returns (bool) {
        require(_approved != _account, "ERC5050: approve to caller");

        require(
            msg.sender == _account ||
                isApprovedForAllActions(_account, msg.sender),
            "ERC5050: approve caller is not account nor approved for all"
        );

        ERC5050Storage.layout().actionApprovals[_account][_action] = _approved;
        emit ApprovalForAction(_account, _action, _approved);

        return true;
    }

    function setApprovalForAllActions(address _operator, bool _approved)
        public
        virtual
        override(IERC5050Sender)
    {
        require(msg.sender != _operator, "ERC5050: approve to caller");

        ERC5050Storage.layout().operatorApprovals[msg.sender][_operator] = _approved;

        emit ApprovalForAllActions(msg.sender, _operator, _approved);
    }

    function getApprovedForAction(address _account, bytes4 _action)
        public
        view
        override(IERC5050Sender)
        returns (address)
    {
        return ERC5050Storage.layout().actionApprovals[_account][_action];
    }

    function isApprovedForAllActions(address _account, address _operator)
        public
        view
        override(IERC5050Sender)
        returns (bool)
    {
        return ERC5050Storage.layout().operatorApprovals[_account][_operator];
    }

    function setControllerApproval(address _controller, bytes4 _action, bool _approved)
        external
        virtual
        override(IControllable)
    {
        ERC5050Storage.layout()._actionControllers[_controller][_action] = _approved;
        emit ControllerApproval(
            _controller,
            _action,
            _approved
        );
    }
    
    function setControllerApprovalForAll(address _controller, bool _approved)
        external
        virtual
        override(IControllable)
    {
        ERC5050Storage.layout()._universalControllers[_controller] = _approved;
        emit ControllerApprovalForAll(
            _controller,
            _approved
        );
    }

    function isApprovedController(address _controller, bytes4 _action)
        external
        view
        override(IControllable)
        returns (bool)
    {
        return _isApprovedController(_controller, _action);
    }

    function _isApprovedController(address _controller, bytes4 _action)
        internal
        view
        returns (bool)
    {
        ERC5050Storage.Layout storage store = ERC5050Storage.layout();
        if (store._universalControllers[_controller]) {
            return true;
        }
        return store._actionControllers[_controller][_action];
    }
    
    function receivableActions() external view override(IERC5050Receiver) returns (string[] memory) {
        return ERC5050Storage.layout()._receivableActions.names();
    }
    
    function sendableActions() external view override(IERC5050Sender) returns (string[] memory) {
        return ERC5050Storage.layout()._receivableActions.names();
    }
    
    function _registerAction(string memory action) internal {
        ERC5050Storage.layout()._receivableActions.add(action);
        ERC5050Storage.layout()._sendableActions.add(action);
    }
    
    function _registerReceivable(string memory action) internal {
        ERC5050Storage.layout()._receivableActions.add(action);
    }
    
    function _registerSendable(string memory action) internal {
        ERC5050Storage.layout()._sendableActions.add(action);
    }
}

// SPDX-License-Identifier: MIT
// Barely modified version of OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.6;

library ActionsSet {
    struct Set {
        // Storage of action names
        string[] _names;
        // Storage of action selectors
        bytes4[] _selectors;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes4 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Set storage set, string memory name) internal returns (bool) {
        bytes4 selector = bytes4(keccak256(bytes(name)));
        if (!contains(set, selector)) {
            set._selectors.push(selector);
            set._names.push(name);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[selector] = set._selectors.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Set storage set, bytes4 value) internal returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _selectors array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._selectors.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes4 lastValue = set._selectors[lastIndex];

                // Move the last value to the index where the value to delete is
                set._selectors[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._selectors.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Set storage set, bytes4 value)
        internal
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(Set storage set) internal view returns (uint256) {
        return set._selectors.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Set storage set, uint256 index) internal view returns (bytes4) {
        return set._selectors[index];
    }

    /**
     * @dev Return the entire set of action names
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function names(Set storage set) internal view returns (string[] memory) {
        return set._names;
    }
    
    /**
     * @dev Return the entire set of action selectors
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function selectors(Set storage set) internal view returns (bytes4[] memory) {
        return set._selectors;
    }
    
    
}

// SPDX-License-Identifier: MIT

/*********************************************************
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░  .░░░░░░░░░░░░░░░░░░░░░░░░.  ҹ░░░░░░░░░░░░*
*░░░░░░░░░░░░░  ∴░░░░░░░░░░░░░░░░░░`   ░░․  ░░∴   (░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º   ҹ  ░   (░░░░░░░░*
*░░░░░⁕  .░░░░░░░░░░░░░░░░░░░░░░░     ⁕..    .∴,    ⁕░░░░*
*░░░░░░  ∴░░░░░░░░░░░░░░░░░░░░░░░ҹ ,(º⁕ҹ     ․∴ҹ⁕(. ⁕░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º`  ․░  ⁕,   ░░░░░░░░*
*░░░░░,  .░░░░░░░░░░░░░░░░░░░░░░░░░`  ,░░⁕  ∴░░   `░░░░░░*
*░░░░░░⁕º░░░░░░░░░░░░░░⁕   ҹ░░░░░░░░░░░░░,  %░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░ҹ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░ҹ   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░º(░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*********************************************************/

pragma solidity ^0.8.6;

import "./ERC20X/IERC20X.sol";

interface ISpellsCoin is IERC20X {
    function mint(
        address _contract,
        uint256 tokenId,
        uint256 amount
    ) external;

    function mint(address account, uint256 amount) external;

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

/*********************************************************
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░  .░░░░░░░░░░░░░░░░░░░░░░░░.  ҹ░░░░░░░░░░░░*
*░░░░░░░░░░░░░  ∴░░░░░░░░░░░░░░░░░░`   ░░․  ░░∴   (░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º   ҹ  ░   (░░░░░░░░*
*░░░░░⁕  .░░░░░░░░░░░░░░░░░░░░░░░     ⁕..    .∴,    ⁕░░░░*
*░░░░░░  ∴░░░░░░░░░░░░░░░░░░░░░░░ҹ ,(º⁕ҹ     ․∴ҹ⁕(. ⁕░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º`  ․░  ⁕,   ░░░░░░░░*
*░░░░░,  .░░░░░░░░░░░░░░░░░░░░░░░░░`  ,░░⁕  ∴░░   `░░░░░░*
*░░░░░░⁕º░░░░░░░░░░░░░░⁕   ҹ░░░░░░░░░░░░░,  %░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░ҹ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░ҹ   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░º(░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*********************************************************/

pragma solidity ^0.8.6;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20X is IERC20 {
    function totalTokenHeldSupply() external view returns (uint256);

    function balanceOf(address _contract, uint256 tokenId)
        external
        view
        returns (uint256);

    function nonce(address _contract, uint256 tokenId)
        external
        view
        returns (uint256);

    function transfer(
        address _contract,
        uint256 tokenId,
        uint256 amount
    ) external returns (bool);

    function transfer(
        address _contract,
        uint256 tokenId,
        address to,
        uint256 amount
    ) external returns (bool);

    function transfer(
        address _contract,
        uint256 tokenId,
        address toContract,
        uint256 toTokenId,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address from,
        address toContract,
        uint256 toTokenId,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address _contract,
        uint256 tokenId,
        address to,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address _contract,
        uint256 tokenId,
        address toContract,
        uint256 toTokenId,
        uint256 amount
    ) external returns (bool);

    function approve(
        address _contract,
        uint256 tokenId,
        address spender,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address _contract,
        uint256 tokenId,
        address spender
    ) external view returns (uint256);

    function allowance(
        address tokenOwner,
        address _contract,
        uint256 tokenId,
        address spender
    ) external view returns (uint256);

    function increaseAllowance(
        address _contract,
        uint256 tokenId,
        address spender,
        uint256 addedValue
    ) external returns (bool);

    function decreaseAllowance(
        address _contract,
        uint256 tokenId,
        address spender,
        uint256 subtractedValue
    ) external returns (bool);

    function signedTransferFrom(
        DynamicAddress memory from,
        DynamicAddress memory to,
        uint256 amount,
        uint256 nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event XTransfer(
        address indexed from,
        uint256 fromTokenId,
        address indexed to,
        uint256 toTokenId,
        uint256 value
    );

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event XApproval(
        address indexed _contract,
        uint256 tokenId,
        address indexed spender,
        uint256 value
    );
}

/// @param _address The address of the entity
/// @param _tokenId The token of the object (optional)
/// @param _useZeroToken Treat tokenId 0 as a token (default: ignore tokenId 0)
struct DynamicAddress {
    address _address;
    uint256 _tokenId;
    bool _useZeroToken;
}

library DynamicAddressLib {
    using Address for address;
    
    function isToken(DynamicAddress memory _address) internal view returns (bool) {
        return (_address._address.isContract() && (_address._tokenId > 0 || _address._useZeroToken));
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
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity ^0.8.0;

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