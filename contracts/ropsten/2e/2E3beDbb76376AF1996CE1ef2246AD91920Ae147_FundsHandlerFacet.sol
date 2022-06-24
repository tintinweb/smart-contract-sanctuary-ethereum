// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {IBosonFundsHandler} from "../../interfaces/handlers/IBosonFundsHandler.sol";
import {DiamondLib} from "../../diamond/DiamondLib.sol";
import {ProtocolBase} from "../bases/ProtocolBase.sol";
import {ProtocolLib} from "../libs/ProtocolLib.sol";
import {FundsLib} from "../libs/FundsLib.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title FundsHandlerFacet
 *
 * @notice Handles custody and withdrawal of buyer and seller funds
 */
contract FundsHandlerFacet is IBosonFundsHandler, ProtocolBase {

    /**
     * @notice Facet Initializer
     */
    function initialize()
    public
    onlyUnInitialized(type(IBosonFundsHandler).interfaceId)
    {
        DiamondLib.addSupportedInterface(type(IBosonFundsHandler).interfaceId);
    }

    /**
     * @notice Receives funds from the caller and stores it to the seller id, so they can be used during the commitToOffer
     *
     * Reverts if:
     * - seller id does not exist
     * - it receives some native currency (e.g. ETH), but token address is not zero
     * - it receives some native currency (e.g. ETH), and the amount does not match msg.value
     * - if contract at token address does not support erc20 function transferFrom
     * - if calling transferFrom on token fails for some reason (e.g. protocol is not approved to transfer)
     *
     * @param _sellerId - id of the seller that will be credited
     * @param _tokenAddress - contract address of token that is being deposited (0 for native currency)
     * @param _amount - amount to be credited
     */
    function depositFunds(uint256 _sellerId, address _tokenAddress, uint256 _amount) external payable override {
        //Check Seller exists in sellers mapping
        (bool exists, ) = fetchSeller(_sellerId);

        //Seller must exist
        require(exists, NO_SUCH_SELLER);

        if (msg.value != 0) {
            // receiving native currency
            require(_tokenAddress == address(0), NATIVE_WRONG_ADDRESS);
            require(_amount == msg.value, NATIVE_WRONG_AMOUNT);
        } else {
            // transfer tokens from the caller
            FundsLib.transferFundsToProtocol(_tokenAddress, _amount, msgSender());
        }

        // increase available funds
        FundsLib.increaseAvailableFunds(_sellerId, _tokenAddress, _amount);

        emit FundsDeposited(_sellerId, msgSender(), _tokenAddress, _amount);              
    }
    
    /**
     * @notice For a given seller or buyer id it returns the information about the funds that can use as a sellerDeposit and/or be withdrawn
     *
     * @param _entityId - seller or buyer id to check
     * @return availableFunds - list of token addresses, token names and amount that can be used as a seller deposit or be withdrawn
     */
    function getAvailableFunds(uint256 _entityId) external view override returns (Funds[] memory availableFunds) {
        // get list of token addresses for the entity
        address[] memory tokenList = protocolLookups().tokenList[_entityId];
        availableFunds = new Funds[](tokenList.length);

        for (uint i = 0; i < tokenList.length; i++) {
            address tokenAddress = tokenList[i];
            string memory tokenName;
            
            if (tokenAddress == address(0)) {
                // it tokenAddress is 0, it represents the native currency
                tokenName = NATIVE_CURRENCY;
            } else {
                // try to get token name
                try IERC20Metadata(tokenAddress).name() returns (string memory name) {
                    tokenName = name;
                } catch {
                    tokenName = TOKEN_NAME_UNSPECIFIED;
                }
            }

            // retrieve available amount from the stroage
            uint availableAmount = protocolLookups().availableFunds[_entityId][tokenAddress];

            // add entry to the return variable
            availableFunds[i] = Funds(tokenAddress, tokenName, availableAmount);
        }
    }

    /**
     * @notice Withdraw the specified funds
     *
     * Reverts if:
     * - caller is not associated with the entity id
     * - token list length does not match amount list length
     * - token list length exceeds the maximum allowed number of tokens
     * - caller tries to withdraw more that they have in available funds
     * - there is nothing to withdraw
     * - transfer of funds is not succesful
     *
     * @param _entityId - seller or buyer id
     * @param _tokenList - list of contract addresses of tokens that are being withdrawn
     * @param _tokenAmounts - list of amounts to be withdrawn, corresponding to tokens in tokenList
     */
    function withdrawFunds(uint256 _entityId, address[] calldata _tokenList, uint256[] calldata _tokenAmounts) external override {
        // address that will receive the funds
        address payable destinationAddress;

        // first check if the caller is a buyer
        (bool exists, uint callerId) = getBuyerIdByWallet(msgSender());
        if(exists && callerId == _entityId) {
            // caller is a buyer
           destinationAddress = payable(msgSender());
        } else {
            // check if the caller is a clerk
            (exists, callerId) = getSellerIdByClerk(msgSender());
            if(exists && callerId == _entityId) {
                // caller is a clerk. In this case funds are transferred to the treasury address
                (, Seller storage seller) = fetchSeller(callerId);
                destinationAddress = seller.treasury;
            } else {
                // in this branch, caller is neither buyer or clerk or does not match the _entityId 
                revert(NOT_AUTHORIZED);
            }
        }
    
        withdrawFundsInternal(destinationAddress, _entityId, _tokenList, _tokenAmounts);
    }

    /**
     * @notice Withdraw the protocol fees
     *
     * Reverts if:
     * - caller does not have the FEE_COLLECTOR role
     * - token list length does not match amount list length
     * - token list length exceeds the maximum allowed number of tokens
     * - caller tries to withdraw more that they have in available funds
     * - there is nothing to withdraw
     * - transfer of funds is not succesful
     *
     * @param _tokenList - list of contract addresses of tokens that are being withdrawn
     * @param _tokenAmounts - list of amounts to be withdrawn, corresponding to tokens in tokenList
     */
    function withdrawProtocolFees(address[] calldata _tokenList, uint256[] calldata _tokenAmounts) external override onlyRole(FEE_COLLECTOR) {
        // withdraw the funds
        withdrawFundsInternal(payable(msg.sender), 0, _tokenList, _tokenAmounts);
    }

    /**
     * @notice Withdraw the specified funds
     *
     * Reverts if:
     * - caller is not associated with the entity id
     * - token list length does not match amount list length
     * - token list length exceeds the maximum allowed number of tokens
     * - caller tries to withdraw more that they have in available funds
     * - there is nothing to withdraw
     * - transfer of funds is not succesful
     *
     * @param _destinationAddress - wallet that will receive funds
     * @param _entityId - seller or buyer id
     * @param _tokenList - list of contract addresses of tokens that are being withdrawn
     * @param _tokenAmounts - list of amounts to be withdrawn, corresponding to tokens in tokenList
     */
    function withdrawFundsInternal(address payable _destinationAddress, uint256 _entityId, address[] calldata _tokenList, uint256[] calldata _tokenAmounts) internal {
            
        // make sure that the data is complete
        require(_tokenList.length == _tokenAmounts.length, TOKEN_AMOUNT_MISMATCH);

        // limit maximum number of tokens to avoid running into block gas limit in a loop
        uint maxTokensPerWithdrawal = protocolLimits().maxTokensPerWithdrawal;
        require(_tokenList.length <= maxTokensPerWithdrawal, TOO_MANY_TOKENS);

        // two possible options: withdraw all, or withdraw only specified tokens and amounts
        if (_tokenList.length == 0) {
            // withdraw everything
            
            // get list of all user's tokens
            address[] memory tokenList = protocolLookups().tokenList[_entityId];

            // make sure that at least something will be withdrawn
            require(tokenList.length != 0, NOTHING_TO_WITHDRAW);
            
            // make sure that tokenList is not too long
            uint len = maxTokensPerWithdrawal <= tokenList.length ? maxTokensPerWithdrawal : tokenList.length;

            for (uint i = 0; i < len; i++) {
                // get available fnds from storage
                uint256 availableFunds = protocolLookups().availableFunds[_entityId][tokenList[i]];
                FundsLib.transferFundsFromProtocol(_entityId, tokenList[i], _destinationAddress, availableFunds); 
            }
        } else {
            for (uint i = 0; i < _tokenList.length; i++) {
                // make sure that at least something will be withdrawn
                require(_tokenAmounts[i] > 0, NOTHING_TO_WITHDRAW);                
                FundsLib.transferFundsFromProtocol(_entityId, _tokenList[i], _destinationAddress, _tokenAmounts[i]); 
            }
        }
    }
    
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {BosonTypes} from "../../domain/BosonTypes.sol";
import {IBosonFundsEvents} from "../events/IBosonFundsEvents.sol";
import {IBosonFundsLibEvents} from "../events/IBosonFundsEvents.sol";

/**
 * @title IBosonFundsHandler
 *
 * @notice Handles custody and withdrawal of buyer and seller funds within the protocol.
 *
 * The ERC-165 identifier for this interface is: 0x18834247
 */
interface IBosonFundsHandler is IBosonFundsEvents, IBosonFundsLibEvents {

    /**
     * @notice Receives funds from the caller and stores it to the seller id, so they can be used during the commitToOffer
     *
     * Reverts if:
     * - seller id does not exist
     * - it receives some native currency (e.g. ETH), but token address is not zero
     * - it receives some native currency (e.g. ETH), and the amount does not match msg.value
     * - if contract at token address does not support erc20 function transferFrom
     * - if calling transferFrom on token fails for some reason (e.g. protocol is not approved to transfer)
     *
     * @param _sellerId - id of the seller that will be credited
     * @param _tokenAddress - contract address of token that is being deposited (0 for native currency)
     * @param _amount - amount to be credited
     */
     function depositFunds(uint256 _sellerId, address _tokenAddress, uint256 _amount) external payable;

    /**
     * @notice For a given seller or buyer id it returns the information about the funds that can use as a sellerDeposit and/or be withdrawn
     *
     * @param _entityId - seller or buyer id to check
     * @return availableFunds - list of token addresses, token names and amount that can be used as a seller deposit or be withdrawn
     */
    function getAvailableFunds(uint256 _entityId) external view returns (BosonTypes.Funds[] memory availableFunds);

    /**
     * @notice Withdraw the specified funds
     *
     * Reverts if:
     * - caller is not associated with the entity id
     * - token list length does not match amount list length
     * - token list length exceeds the maximum allowed number of tokens
     * - caller tries to withdraw more that they have in available funds
     * - there is nothing to withdraw
     * - transfer of funds is not succesful
     *
     * @param _entityId - seller or buyer id
     * @param _tokenList - list of contract addresses of tokens that are being withdrawn
     * @param _tokenAmounts - list of amounts to be withdrawn, corresponding to tokens in tokenList
     */
    function withdrawFunds(uint256 _entityId, address[] calldata _tokenList, uint256[] calldata _tokenAmounts) external;

    /**
     * @notice Withdraw the protocol fees
     *
     * Reverts if:
     * - caller does not have the FEE_COLLECTOR role
     * - token list length does not match amount list length
     * - token list length exceeds the maximum allowed number of tokens
     * - caller tries to withdraw more that they have in available funds
     * - there is nothing to withdraw
     * - transfer of funds is not succesful
     *
     * @param _tokenList - list of contract addresses of tokens that are being withdrawn
     * @param _tokenAmounts - list of amounts to be withdrawn, corresponding to tokens in tokenList
     */
    function withdrawProtocolFees(address[] calldata _tokenList, uint256[] calldata _tokenAmounts) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IAccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import { IDiamondCut } from "../interfaces/diamond/IDiamondCut.sol";

/**
 * @title DiamondLib
 *
 * @notice Diamond storage slot and supported interfaces
 *
 * @notice Based on Nick Mudge's gas-optimized diamond-2 reference,
 * with modifications to support role-based access and management of
 * supported interfaces. Also added copious code comments throughout.
 *
 * Reference Implementation  : https://github.com/mudgen/diamond-2-hardhat
 * EIP-2535 Diamond Standard : https://eips.ethereum.org/EIPS/eip-2535
 *
 * N.B. Facet management functions from original `DiamondLib` were refactor/extracted
 * to JewelerLib, since business facets also use this library for access control and
 * managing supported interfaces.
 *
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
library DiamondLib {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {
        // maps function selectors to the facets that execute the functions.
        // and maps the selectors to their position in the selectorSlots array.
        // func selector => address facet, selector position
        mapping(bytes4 => bytes32) facets;
        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint256 => bytes32) selectorSlots;
        // The number of function selectors in selectorSlots
        uint16 selectorCount;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // The Boson Protocol AccessController
        IAccessControlUpgradeable accessController;
    }

    /**
     * @notice Get the Diamond storage slot
     *
     * @return ds - Diamond storage slot cast to DiamondStorage
     */
    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /**
     * @notice Add a supported interface to the Diamond
     *
     * @param _interfaceId - the interface to add
     */
    function addSupportedInterface(bytes4 _interfaceId) internal {
        // Get the DiamondStorage struct
        DiamondStorage storage ds = diamondStorage();

        // Flag the interfaces as supported
        ds.supportedInterfaces[_interfaceId] = true;
    }

    /**
     * @notice Implementation of ERC-165 interface detection standard.
     *
     * @param _interfaceId - the sighash of the given interface
     */
    function supportsInterface(bytes4 _interfaceId) internal view returns (bool) {
        // Get the DiamondStorage struct
        DiamondStorage storage ds = diamondStorage();

        // Return the value
        return ds.supportedInterfaces[_interfaceId] || false;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {ProtocolLib} from "../libs/ProtocolLib.sol";
import {DiamondLib} from "../../diamond/DiamondLib.sol";
import {BosonTypes} from "../../domain/BosonTypes.sol";
import {BosonConstants} from "../../domain/BosonConstants.sol";

/**
 * @title ProtocolBase
 *
 * @notice Provides domain and common modifiers to Protocol facets
 */
abstract contract ProtocolBase is BosonTypes, BosonConstants {
    /**
     * @dev Modifier to protect initializer function from being invoked twice.
     */
    modifier onlyUnInitialized(bytes4 interfaceId) {
        ProtocolLib.ProtocolInitializers storage pi = protocolInitializers();
        require(!pi.initializedInterfaces[interfaceId], ALREADY_INITIALIZED);
        pi.initializedInterfaces[interfaceId] = true;
        _;
    }

    /**
     * @dev Modifier that checks that an offer exists
     *
     * Reverts if the offer does not exist
     */
    modifier offerExists(uint256 _offerId) {
        // Make sure the offer exists TODO: remove me, not used and not the way to check
        require(_offerId > 0 && _offerId < protocolCounters().nextOfferId, "Offer does not exist");
        _;
    }

    /**
     * @dev Modifier that checks that the caller has a specific role.
     *
     * Reverts if caller doesn't have role.
     *
     * See: {AccessController.hasRole}
     */
    modifier onlyRole(bytes32 _role) {
        DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();
        require(ds.accessController.hasRole(_role, msg.sender), ACCESS_DENIED);
        _;
    }

    /**
     * @dev Get the Protocol Addresses slot
     *
     * @return pa the Protocol Addresses slot
     */
    function protocolAddresses() internal pure returns (ProtocolLib.ProtocolAddresses storage pa) {
        pa = ProtocolLib.protocolAddresses();
    }

    /**
     * @dev Get the Protocol Limits slot
     *
     * @return pl the Protocol Limits slot
     */
    function protocolLimits() internal pure returns (ProtocolLib.ProtocolLimits storage pl) {
        pl = ProtocolLib.protocolLimits();
    }

    /**
     * @dev Get the Protocol Entities slot
     *
     * @return pe the Protocol Entities slot
     */
    function protocolEntities() internal pure returns (ProtocolLib.ProtocolEntities storage pe) {
        pe = ProtocolLib.protocolEntities();
    }

    /**
     * @dev Get the Protocol Lookups slot
     *
     * @return pl the Protocol Lookups slot
     */
    function protocolLookups() internal pure returns (ProtocolLib.ProtocolLookups storage pl) {
        pl = ProtocolLib.protocolLookups();
    }

     /**
     * @dev Get the Protocol Fees slot
     *
     * @return pf the Protocol Fees slot
     */
    function protocolFees() internal pure returns (ProtocolLib.ProtocolFees storage pf) {
        pf = ProtocolLib.protocolFees();
    }

    /**
     * @dev Get the Protocol Counters slot
     *
     * @return pc the Protocol Counters slot
     */
    function protocolCounters() internal pure returns (ProtocolLib.ProtocolCounters storage pc) {
        pc = ProtocolLib.protocolCounters();
    }

    /**
     * @dev Get the Protocol meta-transactions storage slot
     *
     * @return pmti the Protocol meta-transactions storage slot
     */
    function protocolMetaTxInfo() internal pure returns (ProtocolLib.ProtocolMetaTxInfo storage pmti) {
        pmti = ProtocolLib.protocolMetaTxInfo();
    }

    /**
     * @dev Get the Protocol Initializers slot
     *
     * @return pi the Protocol Initializers slot
     */
    function protocolInitializers() internal pure returns (ProtocolLib.ProtocolInitializers storage pi) {
        pi = ProtocolLib.protocolInitializers();
    }

    /**
     * @notice Gets a seller Id from storage by operator address
     *
     * @param _operator - the operator address of the seller
     * @return exists - whether the seller Id exists
     * @return sellerId  - the seller Id
     */
    function getSellerIdByOperator(address _operator) internal view returns (bool exists, uint256 sellerId) {
        // Get the seller Id
        sellerId = protocolLookups().sellerIdByOperator[_operator];

        // Determine existence
        exists = (sellerId > 0);
    }

    /**
     * @notice Gets a seller Id from storage by admin address
     *
     * @param _admin - the admin address of the seller
     * @return exists - whether the seller Id exists
     * @return sellerId  - the seller Id
     */
    function getSellerIdByAdmin(address _admin) internal view returns (bool exists, uint256 sellerId) {
        // Get the seller Id
        sellerId = protocolLookups().sellerIdByAdmin[_admin];

        // Determine existence
        exists = (sellerId > 0);
    }

    /**
     * @notice Gets a seller Id from storage by clerk address
     *
     * @param _clerk - the clerk address of the seller
     * @return exists - whether the seller Id exists
     * @return sellerId  - the seller Id
     */
    function getSellerIdByClerk(address _clerk) internal view returns (bool exists, uint256 sellerId) {
        // Get the seller Id
        sellerId = protocolLookups().sellerIdByClerk[_clerk];

        // Determine existence
        exists = (sellerId > 0);
    }

    /**
     * @notice Gets a buyer id from storage by wallet address
     *
     * @param _wallet - the wallet address of the buyer
     * @return exists - whether the buyer Id exists
     * @return buyerId  - the buyer Id
     */
    function getBuyerIdByWallet(address _wallet) internal view returns (bool exists, uint256 buyerId) {
        // Get the buyer Id
        buyerId = protocolLookups().buyerIdByWallet[_wallet];

        // Determine existence
        exists = (buyerId > 0);
    }

    /**
     * @notice Gets a group id from storage by offer id
     *
     * @param _offerId - the offer id
     * @return exists - whether the group id exists
     * @return groupId  - the group id.
     */
    function getGroupIdByOffer(uint256 _offerId) internal view returns (bool exists, uint256 groupId) {
        // Get the group Id
        groupId = protocolLookups().groupIdByOffer[_offerId];

        // Determine existence
        exists = (groupId > 0);
    }

    /**
     * @notice Fetches a given seller from storage by id
     *
     * @param _sellerId - the id of the seller
     * @return exists - whether the seller exists
     * @return seller - the seller details. See {BosonTypes.Seller}
     */
    function fetchSeller(uint256 _sellerId) internal view returns (bool exists, Seller storage seller) {
        // Get the seller's slot
        seller = protocolEntities().sellers[_sellerId];

        // Determine existence
        exists = (_sellerId > 0 && seller.id == _sellerId);
    }

    /**
     * @notice Fetches a given buyer from storage by id
     *
     * @param _buyerId - the id of the buyer
     * @return exists - whether the buyer exists
     * @return buyer - the buyer details. See {BosonTypes.Buyer}
     */
    function fetchBuyer(uint256 _buyerId) internal view returns (bool exists, BosonTypes.Buyer storage buyer) {
        // Get the buyer's slot
        buyer = protocolEntities().buyers[_buyerId];

        // Determine existence
        exists = (_buyerId > 0 && buyer.id == _buyerId);
    }

    /**
     * @notice Fetches a given dispute resolver from storage by id
     *
     * @param _disputeResolverId - the id of the dispute resolver
     * @return exists - whether the dispute resolver exists
     * @return disputeResolver - the dispute resolver details. See {BosonTypes.DisputeResolver}
     */
    function fetchDisputeResolver(uint256 _disputeResolverId) internal view returns (bool exists, BosonTypes.DisputeResolver storage disputeResolver) {
        // Get the dispute resolver's slot
        disputeResolver = protocolEntities().disputeResolvers[_disputeResolverId];

        // Determine existence
        exists = (_disputeResolverId > 0 && disputeResolver.id == _disputeResolverId);
    }

    /**
     * @notice Fetches a given offer from storage by id
     *
     * @param _offerId - the id of the offer
     * @return exists - whether the offer exists
     * @return offer - the offer details. See {BosonTypes.Offer}
     */
    function fetchOffer(uint256 _offerId) internal view returns (bool exists, Offer storage offer) {
        // Get the offer's slot
        offer = protocolEntities().offers[_offerId];

        // Determine existence
        exists = (_offerId > 0 && offer.id == _offerId);
    }

    /**
     * @notice Fetches the offer dates from storage by offer id
     *
     * @param _offerId - the id of the offer
     * @return offerDates - the offer dates details. See {BosonTypes.OfferDates}
     */
    function fetchOfferDates(uint256 _offerId) internal view returns (BosonTypes.OfferDates storage offerDates) {
        // Get the offerDates's slot
        offerDates = protocolEntities().offerDates[_offerId];
    }

    /**
     * @notice Fetches the offer durations from storage by offer id
     *
     * @param _offerId - the id of the offer
     * @return offerDurations - the offer durations details. See {BosonTypes.OfferDurations}
     */
    function fetchOfferDurations(uint256 _offerId) internal view returns (BosonTypes.OfferDurations storage offerDurations) {
        // Get the offer's slot
        offerDurations = protocolEntities().offerDurations[_offerId];
    }

    /**
     * @notice Fetches a given group from storage by id
     *
     * @param _groupId - the id of the group
     * @return exists - whether the group exists
     * @return group - the group details. See {BosonTypes.Group}
     */
    function fetchGroup(uint256 _groupId) internal view returns (bool exists, Group storage group) {
        // Get the group's slot
        group = protocolEntities().groups[_groupId];

        // Determine existence
        exists = (_groupId > 0 && group.id == _groupId);
    }

    /**
     * @notice Fetches a given exchange from storage by id
     *
     * @param _exchangeId - the id of the exchange
     * @return exists - whether the exchange exists
     * @return exchange - the exchange details. See {BosonTypes.Exchange}
     */
    function fetchExchange(uint256 _exchangeId)
        internal
        view
        returns (bool exists, Exchange storage exchange)
    {
        // Get the exchange's slot
        exchange = protocolEntities().exchanges[_exchangeId];

        // Determine existence
        exists = (_exchangeId > 0 && exchange.id == _exchangeId);
    }

    /**
     * @notice Fetches a given dispute from storage by exchange id
     *
     * @param _exchangeId - the id of the exchange associated with the dispute
     * @return exists - whether the dispute exists
     * @return dispute - the dispute details. See {BosonTypes.Dispute}
     */
    function fetchDispute(uint256 _exchangeId)
    internal
    view
    returns (bool exists, Dispute storage dispute, DisputeDates storage disputeDates)
    {
        // Get the dispute's slot
        dispute = protocolEntities().disputes[_exchangeId];

        // Get the disputeDates's slot
        disputeDates = protocolEntities().disputeDates[_exchangeId];

        // Determine existence
        exists = (_exchangeId > 0 && dispute.exchangeId == _exchangeId);
    
    }

    /**
     * @notice Fetches a given twin from storage by id
     *
     * @param _twinId - the id of the twin
     * @return exists - whether the twin exists
     * @return twin - the twin details. See {BosonTypes.Twin}
     */
    function fetchTwin(uint256 _twinId) internal view returns (bool exists, Twin storage twin) {
        // Get the twin's slot
        twin = protocolEntities().twins[_twinId];
 
        // Determine existence
        exists = (_twinId > 0 && twin.id == _twinId);
    }

    /**
     * @notice Fetches a given bundle from storage by id
     *
     * @param _bundleId - the id of the bundle
     * @return exists - whether the bundle exists
     * @return bundle - the bundle details. See {BosonTypes.Bundle}
     */
    function fetchBundle(uint256 _bundleId) internal view returns (bool exists, Bundle storage bundle) {
        // Get the bundle's slot
        bundle = protocolEntities().bundles[_bundleId];

        // Determine existence
        exists = (_bundleId > 0 && bundle.id == _bundleId);
    }

    /**
     * @notice Gets offer from protocol storage, makes sure it exist and not voided
     *
     * Reverts if:
     * - Offer does not exist
     * - Offer already voided
     * - Caller is not the seller
     *
     *  @param _offerId - the id of the offer to check
     */
    function getValidOffer(uint256 _offerId) internal view returns (Offer storage offer) {
        bool exists;
        Seller storage seller;

        // Get offer
        (exists, offer) = fetchOffer(_offerId);

        // Offer must already exist
        require(exists, NO_SUCH_OFFER);

        // Offer must not already be voided
        require(!offer.voided, OFFER_HAS_BEEN_VOIDED);

        // Get seller, we assume seller exists if offer exists
        (, seller) = fetchSeller(offer.sellerId);

        // Caller must be seller's operator address
        require(seller.operator == msg.sender, NOT_OPERATOR);
    }

    /**
     * @notice Gets the bundle id for a given offer id.
     *
     * @param _offerId - the offer Id.
     * @return exists - whether the bundle Id exists
     * @return bundleId  - the bundle Id.
     */
    function fetchBundleIdByOffer(uint256 _offerId) internal view returns (bool exists, uint256 bundleId) {
        // Get the bundle Id
        bundleId = protocolLookups().bundleIdByOffer[_offerId];

        // Determine existence
        exists = (bundleId > 0);
    }

    /**
     * @notice Gets the bundle ids for a given twin id.
     *
     * @param _twinId - the twin Id.
     * @return exists - whether the bundle Ids exist
     * @return bundleIds  - the bundle Ids.
     */
    function fetchBundleIdsByTwin(uint256 _twinId) internal view returns (bool exists, uint256[] memory bundleIds) {
        // Get the bundle Ids
        bundleIds = protocolLookups().bundleIdsByTwin[_twinId];

        // Determine existence
        exists = (bundleIds.length > 0);
    }

    /**
     * @notice Gets the exchange ids for a given offer id.
     *
     * @param _offerId - the offer Id.
     * @return exists - whether the exchange Ids exist
     * @return exchangeIds  - the exchange Ids.
     */
    function getExchangeIdsByOffer(uint256 _offerId) internal view returns (bool exists, uint256[] memory exchangeIds) {
        // Get the exchange Ids
        exchangeIds = protocolLookups().exchangeIdsByOffer[_offerId];

        // Determine existence
        exists = (exchangeIds.length > 0);
    }

    /**
     * @notice Make sure the caller is buyer associated with the exchange
     *
     * Reverts if
     * - caller is not the buyer associated with exchange
     *
     * @param _currentBuyer - id of current buyer associated with the exchange
     */
    function checkBuyer(uint256 _currentBuyer)
    internal
    view
    {
        // Get the caller's buyer account id
        uint256 buyerId;
        (, buyerId) = getBuyerIdByWallet(msgSender());

        // Must be the buyer associated with the exchange (which is always voucher holder)
        require(buyerId == _currentBuyer, NOT_VOUCHER_HOLDER);
    }

    /**
     * @notice Get a valid exchange
     *
     * Reverts if
     * - Exchange does not exist
     * - Exchange is not in the expected state
     *
     * @param _exchangeId - the id of the exchange to complete
     * @param _expectedState - the state the exchange should be in
     * @return exchange - the exchange
     */
    function getValidExchange(uint256 _exchangeId, ExchangeState _expectedState)
    internal
    view
    returns(Exchange storage exchange)
    {
        // Get the exchange
        bool exchangeExists;
        (exchangeExists, exchange) = fetchExchange(_exchangeId);

        // Make sure the exchange exists
        require(exchangeExists, NO_SUCH_EXCHANGE);

        // Make sure the exchange is in expected state
        require(exchange.state == _expectedState, INVALID_STATE);
    }

    /**
     * @notice Get the current sender address from storage.
     */
    function getCurrentSenderAddress() internal view returns (address) {
        return ProtocolLib.protocolMetaTxInfo().currentSenderAddress;
    }

    /**
     * @notice Returns the current sender address.
     */
    function msgSender() internal view returns (address) {
        bool isItAMetaTransaction = ProtocolLib.protocolMetaTxInfo().isMetaTransaction;

        // Get sender from the storage if this is a meta transaction
        if (isItAMetaTransaction) {
            return getCurrentSenderAddress();
        } else {
            return msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { BosonTypes } from "../../domain/BosonTypes.sol";

/**
 * @title ProtocolLib
 *
 * @dev Provides access to the Protocol Storage, Counters, and Initializer slots for Facets
 */
library ProtocolLib {
    bytes32 internal constant PROTOCOL_ADDRESSES_POSITION = keccak256("boson.protocol.addresses");
    bytes32 internal constant PROTOCOL_LIMITS_POSITION = keccak256("boson.protocol.limits");
    bytes32 internal constant PROTOCOL_ENTITIES_POSITION = keccak256("boson.protocol.entities");
    bytes32 internal constant PROTOCOL_LOOKUPS_POSITION = keccak256("boson.protocol.lookups");
    bytes32 internal constant PROTOCOL_FEES_POSITION = keccak256("boson.protocol.fees");
    bytes32 internal constant PROTOCOL_COUNTERS_POSITION = keccak256("boson.protocol.counters");
    bytes32 internal constant PROTOCOL_INITIALIZERS_POSITION = keccak256("boson.protocol.initializers");
    bytes32 internal constant PROTOCOL_META_TX_POSITION = keccak256("boson.protocol.metaTransactionsStorage");

    // Protocol addresses storage
    struct ProtocolAddresses {
        // Address of the Boson Protocol treasury
        address payable treasuryAddress;
        // Address of the Boson Token (ERC-20 contract)
        address payable tokenAddress;
        // Address of the Boson Protocol Voucher proxy
        address voucherAddress;
    }

    // Protocol limits storage
    struct ProtocolLimits {
        // limit how many offers can be added to the group
        uint16 maxOffersPerGroup;
        // limit how many offers can be added to the bundle
        uint16 maxOffersPerBundle;
        // limit how many twins can be added to the bundle
        uint16 maxTwinsPerBundle;
        // limit how many offers can be processed in single batch transaction
        uint16 maxOffersPerBatch;
        // limit how many different tokens can be withdrawn in a single transaction
        uint16 maxTokensPerWithdrawal;
    }

    // Protocol fees storage
    struct ProtocolFees {
        // Percentage that will be taken as a fee from the net of a Boson Protocol exchange
        uint16 percentage; // 1.75% = 175, 100% = 10000
        // Flat fee taken for exchanges in $BOSON
        uint256 flatBoson;
    }

    // Protocol entities storage
    struct ProtocolEntities {
        // offer id => offer
        mapping(uint256 => BosonTypes.Offer) offers;
        // offer id => offer dates
        mapping(uint256 => BosonTypes.OfferDates) offerDates;
        // offer id => offer durations
        mapping(uint256 => BosonTypes.OfferDurations) offerDurations;
        // exchange id => exchange
        mapping(uint256 => BosonTypes.Exchange) exchanges;
        // exchange id => dispute
        mapping(uint256 => BosonTypes.Dispute) disputes;
        // exchange id => dispute dates
        mapping(uint256 => BosonTypes.DisputeDates) disputeDates;
        // seller id => seller
        mapping(uint256 => BosonTypes.Seller) sellers;
        // buyer id => buyer
        mapping(uint256 => BosonTypes.Buyer) buyers;
        // buyer id => dispute resolver
        mapping(uint256 => BosonTypes.DisputeResolver) disputeResolvers;
        // group id => group
        mapping(uint256 => BosonTypes.Group) groups;
        // bundle id => bundle
        mapping(uint256 => BosonTypes.Bundle) bundles;
        // twin id => twin
        mapping(uint256 => BosonTypes.Twin) twins;
    }

    // Protocol lookups storage
    struct ProtocolLookups {
        // offer id => exchange ids
        mapping(uint256 => uint256[]) exchangeIdsByOffer;
        // offer id => bundle id
        mapping(uint256 => uint256) bundleIdByOffer;
        // twin id => bundle ids
        mapping(uint256 => uint256[]) bundleIdsByTwin;
        // offer id => group id
        mapping(uint256 => uint256) groupIdByOffer;
        //seller operator address => sellerId
        mapping(address => uint256) sellerIdByOperator;
        //seller admin address => sellerId
        mapping(address => uint256) sellerIdByAdmin;
        //seller clerk address => sellerId
        mapping(address => uint256) sellerIdByClerk;
        //buyer wallet address => buyerId
        mapping(address => uint256) buyerIdByWallet;
        //dispute resolver wallet address => disputeResolverId
        mapping(address => uint256) disputeResolverIdByWallet;
        // seller/buyer id => token address => amount
        mapping(uint256 => mapping(address => uint256)) availableFunds;
        // seller/buyer id => all tokens with balance > 0
        mapping(uint256 => address[]) tokenList;
    }

    // Incrementing ID counters
    struct ProtocolCounters {
        // Next account id
        uint256 nextAccountId;
        // Next offer id
        uint256 nextOfferId;
        // Next exchange id
        uint256 nextExchangeId;
        // Next twin id
        uint256 nextTwinId;
        // Next group id
        uint256 nextGroupId;
        // Next twin id
        uint256 nextBundleId;
    }

    // Storage related to Meta Transactions
    struct ProtocolMetaTxInfo {
        // The current sender address associated with the transaction
        address currentSenderAddress;
        // A flag that tells us whether the current transaction is a meta-transaction or a regular transaction.
        bool isMetaTransaction;
        // The domain Separator of the protocol
        bytes32 domainSeparator;
        // nonce => existance of nonce in the mapping
        mapping(uint256 => bool) usedNonce;
    }

    // Individual facet initialization states
    struct ProtocolInitializers {
        // interface id => initialized?
        mapping(bytes4 => bool) initializedInterfaces;
    }

    /**
     * @dev Get the protocol addresses slot
     *
     * @return pa the protocol addresses slot
     */
    function protocolAddresses() internal pure returns (ProtocolAddresses storage pa) {
        bytes32 position = PROTOCOL_ADDRESSES_POSITION;
        assembly {
            pa.slot := position
        }
    }

    /**
     * @dev Get the protocol limits slot
     *
     * @return pl the protocol limits slot
     */
    function protocolLimits() internal pure returns (ProtocolLimits storage pl) {
        bytes32 position = PROTOCOL_LIMITS_POSITION;
        assembly {
            pl.slot := position
        }
    }

    /**
     * @dev Get the protocol entities slot
     *
     * @return pe the protocol entities slot
     */
    function protocolEntities() internal pure returns (ProtocolEntities storage pe) {
        bytes32 position = PROTOCOL_ENTITIES_POSITION;
        assembly {
            pe.slot := position
        }
    }

    /**
     * @dev Get the protocol lookups slot
     *
     * @return pl the protocol lookups slot
     */
    function protocolLookups() internal pure returns (ProtocolLookups storage pl) {
        bytes32 position = PROTOCOL_LOOKUPS_POSITION; 
        assembly {
            pl.slot := position
        }
    }

    /**
     * @dev Get the protocol fees slot
     *
     * @return pf the protocol fees slot
     */
    function protocolFees() internal pure returns (ProtocolFees storage pf) {
        bytes32 position = PROTOCOL_FEES_POSITION;
        assembly {
            pf.slot := position
        }
    }

    /**
     * @dev Get the protocol counters slot
     *
     * @return pc the protocol counters slot
     */
    function protocolCounters() internal pure returns (ProtocolCounters storage pc) {
        bytes32 position = PROTOCOL_COUNTERS_POSITION;
        assembly {
            pc.slot := position
        }
    }

    /**
     * @dev Get the protocol meta-transactions storage slot
     *
     * @return pmti the protocol meta-transactions storage slot
     */
    function protocolMetaTxInfo() internal pure returns (ProtocolMetaTxInfo storage pmti) {
        bytes32 position = PROTOCOL_META_TX_POSITION;
        assembly {
            pmti.slot := position
        }
    }

    /**
     * @dev Get the protocol initializers slot
     *
     * @return pi the the protocol initializers slot
     */
    function protocolInitializers() internal pure returns (ProtocolInitializers storage pi) {
        bytes32 position = PROTOCOL_INITIALIZERS_POSITION;
        assembly {
            pi.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {NATIVE_NOT_ALLOWED, TOKEN_TRANSFER_FAILED, INSUFFICIENT_VALUE_SENT, INSUFFICIENT_AVAILABLE_FUNDS} from "../../domain/BosonConstants.sol";
import {BosonTypes} from "../../domain/BosonTypes.sol";
import {ProtocolLib} from "../libs/ProtocolLib.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title FundsLib
 *
 * @dev 
 */
library FundsLib {
    event FundsEncumbered(uint256 indexed entityId, address indexed exchangeToken, uint256 amount, address indexed executedBy);
    event FundsReleased(uint256 indexed exchangeId, uint256 indexed entityId, address indexed exchangeToken, uint256 amount, address executedBy);
    event ProtocolFeeCollected(uint256 indexed exchangeId, address indexed exchangeToken, uint256 amount, address indexed executedBy);
    event FundsWithdrawn(uint256 indexed sellerId, address indexed withdrawnTo, address indexed tokenAddress, uint256 amount, address executedBy); 
    
    /**
     * @notice Takes in the offer id and buyer id and encumbers buyer's and seller's funds during the commitToOffer
     *
     * Reverts if:
     * - offer price is in native token and buyer caller does not send enough
     * - offer price is in some ERC20 token and caller also send native currency
     * - if contract at token address does not support erc20 function transferFrom
     * - if calling transferFrom on token fails for some reason (e.g. protocol is not approved to transfer)
     * - if seller has less funds available than sellerDeposit
     *
     * @param _offerId - id of the offer with the details
     * @param _buyerId - id of the buyer
     * @param _msgSender - sender of the transaction
     */
    function encumberFunds(uint256 _offerId, uint256 _buyerId, address _msgSender) internal {
        // Load protocol entities storage
        ProtocolLib.ProtocolEntities storage pe = ProtocolLib.protocolEntities();

        // fetch offer to get the exchange token, price and seller 
        // this will be called only from commitToOffer so we expect that exchange actually exist
        BosonTypes.Offer storage offer = pe.offers[_offerId];
        address exchangeToken = offer.exchangeToken;
        uint256 price = offer.price;

        // validate buyer inputs
        if (exchangeToken == address(0)) {
            // if transfer is in the native currency, msg.value must match offer price
            require(msg.value == price, INSUFFICIENT_VALUE_SENT);
        } else {
            // when price is in an erc20 token, transferring the native currency is not allowed
            require(msg.value == 0, NATIVE_NOT_ALLOWED);

            // if transfer is in ERC20 token, try to transfer the amount from buyer to the protocol
            transferFundsToProtocol(exchangeToken, price, _msgSender);
        }

        // decrease available funds
        uint256 sellerId = offer.sellerId;
        uint256 sellerDeposit = offer.sellerDeposit;
        decreaseAvailableFunds(sellerId, exchangeToken, sellerDeposit);

        // notify external observers
        emit FundsEncumbered(_buyerId, exchangeToken, price, msg.sender);
        emit FundsEncumbered(sellerId, exchangeToken, sellerDeposit, msg.sender);
    }

    /**
     * @notice Takes in the exchange id and releases the funds to buyer and seller, depending on the state of the exchange.
     * It is called only from finalizeExchange and ?? finalizeDispute ?? // TODO: update description whne dispute functions are done
     *
     * @param _exchangeId - exchange id
     */
    function releaseFunds(uint256 _exchangeId) internal {
        // Load protocol entities storage
        ProtocolLib.ProtocolEntities storage pe = ProtocolLib.protocolEntities();

        // Get the exchange and its state
        // Since this should be called only from certain functions from exchangeHandler and disputeHandler
        // exhange must exist and be in a completed state, so that's not checked explicitly
        BosonTypes.Exchange storage exchange = pe.exchanges[_exchangeId];
        BosonTypes.ExchangeState exchangeState = exchange.state;

        // Get offer from storage to get the details about sellerDeposit, price, sellerId, exchangeToken and buyerCancelPenalty
        BosonTypes.Offer storage offer = pe.offers[exchange.offerId];
        uint256 sellerDeposit = offer.sellerDeposit;
        uint256 price = offer.price;

        // sum of price and sellerDeposit occurs multiple times
        uint256 pot = price + sellerDeposit;


        // calculate the payoffs depending on state exchange is in
        uint256 sellerPayoff;
        uint256 buyerPayoff;
        uint256 protocolFee;

        if (exchangeState == BosonTypes.ExchangeState.Completed) {
            // COMPLETED
            protocolFee = offer.protocolFee;
            // buyerPayoff is 0
            sellerPayoff = pot - protocolFee;
        } else if (exchangeState == BosonTypes.ExchangeState.Revoked) {
            // REVOKED
            // sellerPayoff is 0
            buyerPayoff = pot;
        } else if (exchangeState == BosonTypes.ExchangeState.Canceled) {
            // CANCELED
            uint256 buyerCancelPenalty = offer.buyerCancelPenalty;
            sellerPayoff = sellerDeposit + buyerCancelPenalty;
            buyerPayoff = price - buyerCancelPenalty;
        } else  {
            // DISPUTED
            // get the information about the dispute, which must exist
            BosonTypes.Dispute storage dispute = pe.disputes[_exchangeId];
            BosonTypes.DisputeState disputeState = dispute.state;

            if (disputeState == BosonTypes.DisputeState.Retracted) {
                // RETRACTED - same as "COMPLETED"
                protocolFee = offer.protocolFee;
                // buyerPayoff is 0
                sellerPayoff = pot - protocolFee;
            } else if (disputeState == BosonTypes.DisputeState.Refused) {
                // REFUSED
                // sellerPayoff is 0
                buyerPayoff = pot;
            } else {
                // RESOLVED or DECIDED
                buyerPayoff = pot * dispute.buyerPercent/10000;
                sellerPayoff = pot - buyerPayoff;
            }           
        }  

        // Store payoffs to availablefunds and notify the external observers
        address exchangeToken = offer.exchangeToken;
        uint256 sellerId = offer.sellerId;
        uint256 buyerId = exchange.buyerId;
        if (sellerPayoff > 0) {
            increaseAvailableFunds(sellerId, exchangeToken, sellerPayoff);
            emit FundsReleased(_exchangeId, buyerId, exchangeToken, buyerPayoff, msg.sender);
        } 
        if (buyerPayoff > 0) {
            increaseAvailableFunds(buyerId, exchangeToken, buyerPayoff);
            emit FundsReleased(_exchangeId, sellerId, exchangeToken, sellerPayoff, msg.sender);
        }
        if (protocolFee > 0) {
            increaseAvailableFunds(0, exchangeToken, protocolFee);
            emit ProtocolFeeCollected(_exchangeId, exchangeToken, protocolFee, msg.sender);
        }        
    }

    /**
     * @notice Tries to transfer tokens from the caller to the protocol
     *
     * Reverts if:
     * - contract at token address does not support erc20 function transferFrom
     * - calling transferFrom on token fails for some reason (e.g. protocol is not approved to transfer)
     *
     * @param _tokenAddress - address of the token to be transferred
     * @param _amount - amount to be transferred
     * @param _msgSender - sender of the transaction
     */
    function transferFundsToProtocol(address _tokenAddress, uint256 _amount, address _msgSender) internal {
        // transfer ERC20 tokens from the caller
        try IERC20(_tokenAddress).transferFrom(_msgSender, address(this), _amount)  {
        } catch (bytes memory error) {
            string memory reason = error.length == 0 ? TOKEN_TRANSFER_FAILED : string(error);
            revert(reason);
        }
    }

    /**
     * @notice Tries to transfer native currency or tokens from the protocol to the recepient
     *
     * Reverts if:
     * - transfer of native currency is not successulf (i.e. recepient is a contract which reverted)
     * - contract at token address does not support erc20 function transfer
     * - available funds is less than amount to be decreased
     *
     * @param _tokenAddress - address of the token to be transferred
     * @param _to - address of the recepient
     * @param _amount - amount to be transferred
     */
    function transferFundsFromProtocol(uint256 _entityId, address _tokenAddress, address payable _to, uint256 _amount) internal {
        // first decrease the amount to prevent the reentrancy attack
        FundsLib.decreaseAvailableFunds(_entityId, _tokenAddress, _amount); 

        // try to transfer the funds
        if (_tokenAddress == address(0)) {
            // transfer native currency
            (bool success, ) = _to.call{value: _amount}("");
            require(success, TOKEN_TRANSFER_FAILED);
        } else {
            try IERC20(_tokenAddress).transfer(_to, _amount)  {
            } catch (bytes memory error) {
                string memory reason = error.length == 0 ? TOKEN_TRANSFER_FAILED : string(error);
                revert(reason);
            }
        }

        // notify the external observers
        emit FundsWithdrawn(_entityId, _to, _tokenAddress, _amount, msg.sender);    
    }

    /**
     * @notice Increases the amount, available to withdraw or use as a seller deposit
     *
     * @param _entityId - seller or buyer id, or 0 for protocol
     * @param _tokenAddress - funds contract address or zero address for native currency
     * @param _amount - amount to be credited
     */

    function increaseAvailableFunds(uint256 _entityId, address _tokenAddress, uint256 _amount) internal {
        ProtocolLib.ProtocolLookups storage pl = ProtocolLib.protocolLookups();

        // if the current amount of token is 0, the token address must be added to the token list
        if (pl.availableFunds[_entityId][_tokenAddress] == 0) {
            pl.tokenList[_entityId].push(_tokenAddress);
        }

        // update the available funds
        pl.availableFunds[_entityId][_tokenAddress] += _amount;
    }

    /**
     * @notice Decreases the amount, available to withdraw or use as a seller deposit
     *
     * Reverts if:
     * - available funds is less than amount to be decreased
     *
     * @param _entityId - seller or buyer id, or 0 for protocol
     * @param _tokenAddress - funds contract address or zero address for native currency
     * @param _amount - amount to be taken away
     */
    function decreaseAvailableFunds(uint256 _entityId, address _tokenAddress, uint256 _amount) internal {
        ProtocolLib.ProtocolLookups storage pl = ProtocolLib.protocolLookups();

        // get available fnds from storage
        uint256 availableFunds = pl.availableFunds[_entityId][_tokenAddress];

        // make sure that seller has enough funds in the pool and reduce the available funds
        require(availableFunds >= _amount, INSUFFICIENT_AVAILABLE_FUNDS);
        pl.availableFunds[_entityId][_tokenAddress] = availableFunds - _amount;

        // if availableFunds are totally emptied, the token address is removed from the seller's tokenList
        if (availableFunds == _amount) {
            uint len = pl.tokenList[_entityId].length;
            for (uint i = 0; i < len; i++) {
                if (pl.tokenList[_entityId][i] == _tokenAddress) {
                    pl.tokenList[_entityId][i] = pl.tokenList[_entityId][len-1];
                    pl.tokenList[_entityId].pop();
                    break;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title BosonTypes
 *
 * @notice Enums and structs used by the Boson Protocol contract ecosystem.
 */

contract BosonTypes {
    enum EvaluationMethod {
        None,
        AboveThreshold,
        SpecificToken
    }

    enum ExchangeState {
        Committed,
        Revoked,
        Canceled,
        Redeemed,
        Completed,
        Disputed
    }

    enum DisputeState {
        Resolving,
        Retracted,
        Resolved,
        Escalated,
        Decided,
        Refused
    }

    enum TokenType {
        FungibleToken,
        NonFungibleToken,
        MultiToken
    } // ERC20, ERC721, ERC1155

    struct Seller {
        uint256 id;
        address operator;
        address admin;
        address clerk;
        address payable treasury;
        bool active;
    }

    struct Buyer {
        uint256 id;
        address payable wallet;
        bool active;
    }

    struct DisputeResolver {
        uint256 id;
        address payable wallet;
        bool active;
    }

    struct Offer {
        uint256 id;
        uint256 sellerId;
        uint256 price;
        uint256 sellerDeposit;
        uint256 protocolFee;
        uint256 buyerCancelPenalty;
        uint256 quantityAvailable;
        address exchangeToken;
        uint256 disputeResolverId;
        string metadataUri;
        string metadataHash;
        bool voided;
    }

    struct OfferDates {
        uint256 validFrom;
        uint256 validUntil;
        uint256 voucherRedeemableFrom;
        uint256 voucherRedeemableUntil;
    }

    struct OfferDurations {
        uint256 fulfillmentPeriod;
        uint256 voucherValid;
        uint256 resolutionPeriod;
    }

    struct Group {
        uint256 id;
        uint256 sellerId;
        uint256[] offerIds;
        Condition condition;
    }

    struct Condition {
        EvaluationMethod method;
        address tokenAddress;
        uint256 tokenId;
        uint256 threshold;
    }

    struct Exchange {
        uint256 id;
        uint256 offerId;
        uint256 buyerId;
        uint256 finalizedDate;
        Voucher voucher;
        ExchangeState state;
    }

    struct Voucher {
        uint256 committedDate;
        uint256 validUntilDate;
        uint256 redeemedDate;
        bool expired;
    }

    struct Dispute {
        uint256 exchangeId;
        string complaint;
        DisputeState state;
        uint256 buyerPercent;
    }

    struct DisputeDates {
        uint256 disputed;
        uint256 escalated;
        uint256 finalized;
        uint256 timeout;
    }

    struct Receipt {
        Offer offer;
        Exchange exchange;
        Dispute dispute;
    }

    struct Twin {
        uint256 id;
        uint256 sellerId;
        uint256 supplyAvailable; // ERC-1155 / ERC-20
        uint256[] supplyIds; // ERC-721
        uint256 tokenId; // ERC-1155
        address tokenAddress; // all
        TokenType tokenType;
    }

    struct Bundle {
        uint256 id;
        uint256 sellerId;
        uint256[] offerIds;
        uint256[] twinIds;
    }

    struct Funds {
        address tokenAddress;
        string tokenName;
        uint256 availableAmount;
    }

    struct MetaTransaction {
        uint256 nonce;
        address from;
        address contractAddress;
        string functionName;
        bytes functionSignature;
    }

    struct MetaTxCommitToOffer {
        uint256 nonce;
        address from;
        address contractAddress;
        string functionName;
        MetaTxOfferDetails offerDetails;
    }

    struct MetaTxOfferDetails {
        address buyer;
        uint256 offerId;
    }

    struct MetaTxExchange {
        uint256 nonce;
        address from;
        address contractAddress;
        string functionName;
        MetaTxExchangeDetails exchangeDetails;
    }

    struct MetaTxExchangeDetails {
        uint256 exchangeId;
    }

    struct MetaTxFund {
        uint256 nonce;
        address from;
        address contractAddress;
        string functionName;
        MetaTxFundDetails fundDetails;
    }

    struct MetaTxFundDetails {
        uint256 entityId;
        address[] tokenList;
        uint256[] tokenAmounts;
    }

    struct MetaTxDispute {
        uint256 nonce;
        address from;
        address contractAddress;
        string functionName;
        MetaTxDisputeDetails disputeDetails;
    }

    struct MetaTxDisputeDetails {
        uint256 exchangeId;
        string complaint;
    }

    struct MetaTxDisputeResolution {
        uint256 nonce;
        address from;
        address contractAddress;
        string functionName;
        MetaTxDisputeResolutionDetails disputeResolutionDetails;
    }

    struct MetaTxDisputeResolutionDetails {
        uint256 exchangeId;
        uint256 buyerPercent;
        bytes32 sigR;
        bytes32 sigS;
        uint8 sigV;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {BosonTypes} from "../../domain/BosonTypes.sol";

/**
 * @title IBosonFundsEvents
 *
 * @notice Events related to management of funds within the protocol.
 */
interface IBosonFundsEvents {
    event FundsDeposited(uint256 indexed sellerId, address indexed executedBy, address indexed tokenAddress, uint256 amount);  
}

interface IBosonFundsLibEvents {
    event FundsEncumbered(uint256 indexed entityId, address indexed exchangeToken, uint256 amount, address indexed executedBy);  
    event FundsReleased(uint256 indexed exchangeId, uint256 indexed entityId, address indexed exchangeToken, uint256 amount, address executedBy);
    event ProtocolFeeCollected(uint256 indexed exchangeId, address indexed exchangeToken, uint256 amount, address indexed executedBy);
    event FundsWithdrawn(uint256 indexed sellerId, address indexed withdrawnTo, address indexed tokenAddress, uint256 amount, address executedBy);  
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IDiamondCut
 *
 * @notice Diamond Facet management
 *
 * Reference Implementation  : https://github.com/mudgen/diamond-2-hardhat
 * EIP-2535 Diamond Standard : https://eips.ethereum.org/EIPS/eip-2535
 *
 * The ERC-165 identifier for this interface is: 0x1f931c1c
 *
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 */
interface IDiamondCut {
    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /**
     * @notice Add/replace/remove any number of functions and
     * optionally execute a function with delegatecall
     *
     * _calldata is executed with delegatecall on _init
     *
     * @param _diamondCut Contains the facet addresses and function selectors
     * @param _init The address of the contract or facet to execute _calldata
     * @param _calldata A function call, including function selector and arguments
     */
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title BosonConstants
 *
 * @notice Constants used by the Boson Protocol contract ecosystem.
 */
contract BosonConstants {
    // Access Control Roles
    bytes32 internal constant ADMIN = keccak256("ADMIN"); // Role Admin
    bytes32 internal constant PROTOCOL = keccak256("PROTOCOL"); // Role for facets of the ProtocolDiamond
    bytes32 internal constant CLIENT = keccak256("CLIENT"); // Role for clients of the ProtocolDiamond
    bytes32 internal constant UPGRADER = keccak256("UPGRADER"); // Role for performing contract and config upgrades
    bytes32 internal constant FEE_COLLECTOR = keccak256("FEE_COLLECTOR"); // Role for collecting fees from the protocol

    // Revert Reasons: General
    string internal constant INVALID_ADDRESS = "Invalid address";
    string internal constant INVALID_STATE = "Invalid state";
    string internal constant ARRAY_LENGTH_MISMATCH = "Array length mismatch";

    // Revert Reasons: Facet initializer related
    string internal constant ALREADY_INITIALIZED = "Already initialized";

    // Revert Reasons: Access related
    string internal constant ACCESS_DENIED = "Access denied, caller doesn't have role";
    string internal constant NOT_OPERATOR = "Not seller's operator";
    string internal constant NOT_ADMIN = "Not seller's admin";
    string internal constant NOT_BUYER_OR_SELLER = "Not buyer or seller";
    string internal constant NOT_VOUCHER_HOLDER = "Not current voucher holder";
    string internal constant NOT_BUYER_WALLET = "Not buyer's wallet address";
    string internal constant NOT_DISPUTE_RESOLVER_WALLET = "Not dispute resolver's wallet address";

    // Revert Reasons: Account-related
    string internal constant NO_SUCH_SELLER = "No such seller";
    string internal constant MUST_BE_ACTIVE = "Account must be active";
    string internal constant SELLER_ADDRESS_MUST_BE_UNIQUE = "Seller address cannot be assigned to another seller Id";
    string internal constant BUYER_ADDRESS_MUST_BE_UNIQUE = "Buyer address cannot be assigned to another buyer Id";
    string internal constant DISPUTE_RESOLVER_ADDRESS_MUST_BE_UNIQUE =
        "Dispute Resolver address cannot be assigned to another dispute resolver Id";
    string internal constant NO_SUCH_BUYER = "No such buyer";
    string internal constant WALLET_OWNS_VOUCHERS = "Wallet address owns vouchers";
    string internal constant NO_SUCH_DISPUTE_RESOLVER = "No such dispute resolver";

    // Revert Reasons: Offer related
    string internal constant NO_SUCH_OFFER = "No such offer";
    string internal constant OFFER_PERIOD_INVALID = "Offer period invalid";
    string internal constant OFFER_PENALTY_INVALID = "Offer penalty invalid";
    string internal constant OFFER_MUST_BE_ACTIVE = "Offer must be active";
    string internal constant OFFER_NOT_UPDATEABLE = "Offer not updateable";
    string internal constant OFFER_MUST_BE_UNIQUE = "Offer must be unique to a group";
    string internal constant OFFER_HAS_BEEN_VOIDED = "Offer has been voided";
    string internal constant OFFER_HAS_EXPIRED = "Offer has expired";
    string internal constant OFFER_NOT_AVAILABLE = "Offer is not yet available";
    string internal constant OFFER_SOLD_OUT = "Offer has sold out";
    string internal constant EXCHANGE_FOR_OFFER_EXISTS = "Exchange for offer exists";
    string internal constant AMBIGUOUS_VOUCHER_EXPIRY =
        "Exactly one of voucherRedeemableUntil and voucherValid must be non zero";
    string internal constant REDEMPTION_PERIOD_INVALID = "Redemption period invalid";
    string internal constant INVALID_FULFILLMENT_PERIOD = "Invalid fulfillemnt period";
    string internal constant INVALID_DISPUTE_DURATION = "Invalid dispute duration";
    string internal constant INVALID_DISPUTE_RESOLVER = "Invalid dispute resolver";
    string internal constant INVALID_QUANTITY_AVAILABLE = "Invalid quantity available";

    // Revert Reasons: Group related
    string internal constant NO_SUCH_GROUP = "No such offer";
    string internal constant OFFER_NOT_IN_GROUP = "Offer not part of the group";
    string internal constant TOO_MANY_OFFERS = "Exceeded maximum offers in a single transaction";
    string internal constant NOTHING_UPDATED = "Nothing updated";
    string internal constant INVALID_CONDITION_PARAMETERS = "Invalid condition parameters";

    // Revert Reasons: Exchange related
    string internal constant NO_SUCH_EXCHANGE = "No such exchange";
    string internal constant FULFILLMENT_PERIOD_NOT_ELAPSED = "Fulfillment period has not yet elapsed";
    string internal constant VOUCHER_NOT_REDEEMABLE = "Voucher not yet valid or already expired";
    string internal constant VOUCHER_STILL_VALID = "Voucher still valid";
    string internal constant VOUCHER_HAS_EXPIRED = "Voucher has expired";

    // Revert Reasons: Twin related
    string internal constant NO_SUCH_TWIN = "No such twin";
    string internal constant NO_TRANSFER_APPROVED = "No transfer approved";
    string internal constant TWIN_TRANSFER_FAILED = "Twin could not be transferred";
    string internal constant UNSUPPORTED_TOKEN = "Unsupported token";
    string internal constant TWIN_HAS_BUNDLES = "Twin has bundles";

    // Revert Reasons: Bundle related
    string internal constant NO_SUCH_BUNDLE = "No such bundle";
    string internal constant TWIN_NOT_IN_BUNDLE = "Twin not part of the bundle";
    string internal constant OFFER_NOT_IN_BUNDLE = "Offer not part of the bundle";
    string internal constant TOO_MANY_TWINS = "Exceeded maximum twins in a single transaction";
    string internal constant TWIN_ALREADY_EXISTS_IN_SAME_BUNDLE = "Twin already exists in the same bundle";
    string internal constant BUNDLE_OFFER_MUST_BE_UNIQUE = "Offer must be unique to a bundle";
    string internal constant EXCHANGE_FOR_BUNDLED_OFFERS_EXISTS = "Exchange for the bundled offers exists";

    // Revert Reasons: Funds related
    string internal constant NATIVE_WRONG_ADDRESS = "Native token address must be 0";
    string internal constant NATIVE_WRONG_AMOUNT = "Transferred value must match amount";
    string internal constant TOKEN_NAME_UNSPECIFIED = "Token name unspecified";
    string internal constant NATIVE_CURRENCY = "Native currency";
    string internal constant TOO_MANY_TOKENS = "Too many tokens";
    string internal constant TOKEN_AMOUNT_MISMATCH = "Number of amounts should match number of tokens";
    string internal constant NOTHING_TO_WITHDRAW = "Nothing to withdraw";
    string internal constant NOT_AUTHORIZED = "Not authorized to withdraw";

    // Revert Reasons: Meta-Transactions related
    string internal constant NONCE_USED_ALREADY = "Nonce used already";
    string internal constant FUNCTION_CALL_NOT_SUCCESSFUL = "Function call not successful";
    string internal constant INVALID_FUNCTION_SIGNATURE =
        "functionSignature can not be of executeMetaTransaction method";
    string internal constant SIGNER_AND_SIGNATURE_DO_NOT_MATCH = "Signer and signature do not match";
    string internal constant INVALID_FUNCTION_NAME = "Invalid function name";

    // Revert Reasons: Dispute related
    string internal constant COMPLAINT_MISSING = "Complaint missing";
    string internal constant FULFILLMENT_PERIOD_HAS_ELAPSED = "Fulfillment period has already elapsed";
    string internal constant DISPUTE_HAS_EXPIRED = "Dispute has expired";
    string internal constant INVALID_BUYER_PERCENT = "Invalid buyer percent";
    string internal constant DISPUTE_STILL_VALID = "Dispute still valid";
    string internal constant INVALID_DISPUTE_TIMEOUT = "Invalid dispute timeout";

    // Revert Reasons: Config related
    string internal constant PROTOCOL_FEE_PERCENTAGE_INVALID = "Percentage representation must be less than 10000";
}

// TODO: Refactor to use file level constants throughout or use custom Errors
// Libraries cannot inherit BosonConstants, therefore these revert reasons are defined on the file level
string constant TOKEN_TRANSFER_FAILED = "Token transfer failed";
string constant INSUFFICIENT_VALUE_SENT = "Insufficient value sent";
string constant INSUFFICIENT_AVAILABLE_FUNDS = "Insufficient available funds";
string constant NATIVE_NOT_ALLOWED = "Transfer of native currency not allowed";
string constant INVALID_SIGNATURE = "Invalid signature";