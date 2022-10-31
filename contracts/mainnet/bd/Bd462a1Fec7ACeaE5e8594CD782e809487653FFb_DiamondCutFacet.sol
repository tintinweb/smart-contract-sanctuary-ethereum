// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import {VoteProposalLib} from "../libraries/VotingStatusLib.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";


// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

contract DiamondCutFacet is IDiamondCut {
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
    ) external override {
        VoteProposalLib.enforceOnlyPartners(msg.sender);
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
    }
}

// SPDX-License-Identifier: BSL
pragma solidity ^0.8.17;

/**
*   [BSL License]
*   @title Library of the Proxy Contract
*   @notice Proxy contracts use variables from this libriary. 
*   @dev The proxy uses Diamond Pattern for modularity. Relevant code was borrowed from  
    Nick Mudge.    
*   @author Ismailov Altynbek <[email protected]>
*/

library VoteProposalLib {
    bytes32 constant VT_STORAGE_POSITION =
        keccak256("waverimplementation.VoteTracking.Lib"); //Storing position of the variables

    struct VoteProposal {
        uint24 id;
        address proposer;
        uint8 voteType;
        uint256 tokenVoteQuantity;
        string voteProposalText;
        uint8 voteStatus;
        uint256 voteends;
        address receiver;
        address tokenID;
        uint256 amount;
        uint8 votersLeft;
    }

    event VoteStatus(
        uint24 indexed id,
        address sender,
        uint8 voteStatus,
        uint256 timestamp
    );

    struct VoteTracking {
        uint8 familyMembers;
        MarriageStatus marriageStatus;
        uint24 voteid; //Tracking voting proposals by VOTEID
        address proposer;
        address proposed;
        address payable addressWaveContract;
        uint nonce;
        uint256 threshold;
        uint256 id;
        uint256 cmFee;
        uint256 marryDate;
        uint256 policyDays;
        uint256 setDeadline;
        uint256 divideShare;
        address [] subAccounts; //an Array of Subaccounts; 
        mapping(address => bool) hasAccess; //Addresses that are alowed to use Proxy contract
        mapping(uint24 => VoteProposal) voteProposalAttributes; //Storage of voting proposals
        mapping(uint24 => mapping(address => bool)) votingStatus; // Tracking whether address has voted for particular voteid
        mapping(uint24 => uint256) numTokenFor; //Number of tokens voted for the proposal
        mapping(uint24 => uint256) numTokenAgainst; //Number of tokens voted against the proposal
        mapping (uint => uint) indexBook; //Keeping track of indexes 
        mapping(uint => address) addressBook; //To keep Addresses inside
        mapping(address => uint) subAccountIndex;//To keep track of subAccounts
        mapping(bytes32 => uint256) signedMessages;
        mapping(address => mapping(bytes32 => uint256)) approvedHashes;
    }

    function VoteTrackingStorage()
        internal
        pure
        returns (VoteTracking storage vt)
    {
        bytes32 position = VT_STORAGE_POSITION;
        assembly {
            vt.slot := position
        }
    }

    error ALREADY_VOTED();

    function enforceNotVoted(uint24 _voteid, address msgSender_) internal view {
        if (VoteTrackingStorage().votingStatus[_voteid][msgSender_] == true) {
            revert ALREADY_VOTED();
        }
    }

    error VOTE_IS_CLOSED();

    function enforceProposedStatus(uint24 _voteid) internal view {
        if (
            VoteTrackingStorage().voteProposalAttributes[_voteid].voteStatus !=
            1
        ) {
            revert VOTE_IS_CLOSED();
        }
    }

    error VOTE_IS_NOT_PASSED();

    function enforceAcceptedStatus(uint24 _voteid) internal view {
        if (
            VoteTrackingStorage().voteProposalAttributes[_voteid].voteStatus !=
            2 &&
            VoteTrackingStorage().voteProposalAttributes[_voteid].voteStatus !=
            7
        ) {
            revert VOTE_IS_NOT_PASSED();
        }
    }

    error VOTE_PROPOSER_ONLY();

    function enforceOnlyProposer(uint24 _voteid, address msgSender_)
        internal
        view
    {
        if (
            VoteTrackingStorage().voteProposalAttributes[_voteid].proposer !=
            msgSender_
        ) {
            revert VOTE_PROPOSER_ONLY();
        }
    }

    error DEADLINE_NOT_PASSED();

    function enforceDeadlinePassed(uint24 _voteid) internal view {
        if (
            VoteTrackingStorage().voteProposalAttributes[_voteid].voteends >
            block.timestamp
        ) {
            revert DEADLINE_NOT_PASSED();
        }
    }

    /* Enum Statuses of the Marriage*/
    enum MarriageStatus {
        Proposed,
        Declined,
        Cancelled,
        Married,
        Divorced
    }

    /* Listening to whether ETH has been received/sent from the contract*/
    event AddStake(
        address indexed from,
        address indexed to,
        uint256 timestamp,
        uint256 amount
    );

    error USER_HAS_NO_ACCESS(address user);

    function enforceUserHasAccess(address msgSender_) internal view {
        if (VoteTrackingStorage().hasAccess[msgSender_] != true) {
            revert USER_HAS_NO_ACCESS(msgSender_);
        }
    }

    error USER_IS_NOT_PARTNER(address user);

    function enforceOnlyPartners(address msgSender_) internal view {
       
        if (
            VoteTrackingStorage().proposed != msgSender_ &&
            VoteTrackingStorage().proposer != msgSender_
        ) {
            revert USER_IS_NOT_PARTNER(msgSender_);
        } 
    }

    error CANNOT_USE_PARTNERS_ADDRESS();

    function enforceNotPartnerAddr(address _member) internal view {
        if (
            VoteTrackingStorage().proposed == _member &&
            VoteTrackingStorage().proposer == _member
        ) {
            revert CANNOT_USE_PARTNERS_ADDRESS();
        }
    }

    error CANNOT_PERFORM_WHEN_PARTNERSHIP_IS_ACTIVE();

    function enforceNotYetMarried() internal view {
        if (
            VoteTrackingStorage().marriageStatus != MarriageStatus.Proposed &&
            VoteTrackingStorage().marriageStatus != MarriageStatus.Declined
        ) {
            revert CANNOT_PERFORM_WHEN_PARTNERSHIP_IS_ACTIVE();
        }
    }

    error PARNERSHIP_IS_NOT_ESTABLISHED();

    function enforceMarried() internal view {
        if (VoteTrackingStorage().marriageStatus != MarriageStatus.Married) {
            revert PARNERSHIP_IS_NOT_ESTABLISHED();
        }
    }

    error PARNERSHIP_IS_DISSOLUTED();

    function enforceNotDivorced() internal view {
        if (VoteTrackingStorage().marriageStatus == MarriageStatus.Divorced) {
            revert PARNERSHIP_IS_DISSOLUTED();
        }
    }

    error PARTNERSHIP_IS_NOT_DISSOLUTED();

    function enforceDivorced() internal view {
        if (VoteTrackingStorage().marriageStatus != MarriageStatus.Divorced) {
            revert PARTNERSHIP_IS_NOT_DISSOLUTED();
        }
    }

    error CONTRACT_NOT_AUTHORIZED(address contractAddress);

    function enforceContractHasAccess() internal view {
        if (msg.sender != VoteTrackingStorage().addressWaveContract) {
            revert CONTRACT_NOT_AUTHORIZED(msg.sender);
        }
    }

    error COULD_NOT_PROCESS(address _to, uint256 amount);

    /**
     * @notice Internal function to process payments.
     * @dev call method is used to keep process gas limit higher than 2300. Amount of 0 will be skipped,
     * @param _to Address that will be reveiving payment
     * @param _amount the amount of payment
     */

    function processtxn(address payable _to, uint256 _amount) internal {
        if (_amount > 0) {
            (bool success, ) = _to.call{value: _amount}("");
            if (!success) {
                revert COULD_NOT_PROCESS(_to, _amount);
            }
            emit AddStake(address(this), _to, block.timestamp, _amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

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
pragma solidity >=0.8.0 <0.9.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndSelectorPosition {
        address facetAddress;
        uint16 selectorPosition;
    }
    //event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);
    struct DiamondStorage {
        // function selector => facet address and selector position in selectors array
        mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
        bytes4[] selectors;
        mapping(bytes4 => bool) supportedInterfaces;
        mapping(address => bool) connectedApps;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    error DIAMOND_ACTION_NOT_FOUND();
     // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            DiamondStorage storage ds = diamondStorage();
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
                ds.connectedApps[_diamondCut[facetIndex].facetAddress] = true;
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                ds.connectedApps[ds.facetAddressAndSelectorPosition[_diamondCut[facetIndex].functionSelectors[0]].facetAddress] = false;
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert DIAMOND_ACTION_NOT_FOUND();
            }
        }
        //emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }
    error FUNCTION_SELECTORS_CANNOT_BE_EMPTY();
    error FACET_ADDRESS_CANNOT_BE_EMPTY();
    error FACET_ALREADY_EXISTS();
    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_functionSelectors.length == 0) {revert FUNCTION_SELECTORS_CANNOT_BE_EMPTY();}
      
        DiamondStorage storage ds = diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);
        if (_facetAddress == address(0)) {revert FACET_ADDRESS_CANNOT_BE_EMPTY();}
        enforceHasContractCode(_facetAddress,"");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            if (oldFacetAddress != address(0)) {revert FACET_ALREADY_EXISTS();}
            ds.facetAddressAndSelectorPosition[selector] = FacetAddressAndSelectorPosition(_facetAddress, selectorCount);
            ds.selectors.push(selector);
            selectorCount++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_functionSelectors.length == 0) {revert FUNCTION_SELECTORS_CANNOT_BE_EMPTY();}
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        if (_facetAddress != address(0)) {revert FACET_ALREADY_EXISTS();}
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetAddressAndSelectorPosition memory oldFacetAddressAndSelectorPosition = ds.facetAddressAndSelectorPosition[selector];
            if (oldFacetAddressAndSelectorPosition.facetAddress == address(0)) {revert FACET_ADDRESS_CANNOT_BE_EMPTY();}
            // can't remove immutable functions -- functions defined directly in the diamond
            require(oldFacetAddressAndSelectorPosition.facetAddress != address(this));
            // replace selector with last selector
            selectorCount--;
            if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
                ds.facetAddressAndSelectorPosition[lastSelector].selectorPosition = oldFacetAddressAndSelectorPosition.selectorPosition;
            }
            // delete last selector
            ds.selectors.pop();
            delete ds.facetAddressAndSelectorPosition[selector];
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0);
        } else {
            require(_calldata.length > 0);
            if (_init != address(this)) {
                enforceHasContractCode(_init,"");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert();
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}