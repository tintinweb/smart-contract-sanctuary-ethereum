// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title SeenConstants
 *
 * @notice Constants used by the Seen.Haus contract ecosystem.
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract SeenConstants {

    // Endpoint will serve dynamic metadata composed of ticket and ticketed item's info
    string internal constant ESCROW_TICKET_URI = "https://api.seen.haus/ticket/metadata/";

    // Access Control Roles
    bytes32 internal constant ADMIN = keccak256("ADMIN");                   // Deployer and any other admins as needed
    bytes32 internal constant SELLER = keccak256("SELLER");                 // Approved sellers amd Seen.Haus reps
    bytes32 internal constant MINTER = keccak256("MINTER");                 // Approved artists and Seen.Haus reps
    bytes32 internal constant ESCROW_AGENT = keccak256("ESCROW_AGENT");     // Seen.Haus Physical Item Escrow Agent
    bytes32 internal constant MARKET_HANDLER = keccak256("MARKET_HANDLER"); // Market Handler contracts
    bytes32 internal constant UPGRADER = keccak256("UPGRADER");             // Performs contract upgrades
    bytes32 internal constant MULTISIG = keccak256("MULTISIG");             // Admin role of MARKET_HANDLER & UPGRADER

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../interfaces/IMarketController.sol";
import "../../interfaces/IMarketHandler.sol";
import "../../interfaces/ISeenHausNFT.sol";
import "../../domain/SeenConstants.sol";
import "../../interfaces/IERC2981.sol";
import "../../domain/SeenTypes.sol";
import "./MarketHandlerLib.sol";

/**
 * @title MarketHandlerBase
 *
 * @notice Provides base functionality for common actions taken by market handlers.
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
abstract contract MarketHandlerBase is IMarketHandler, SeenTypes, SeenConstants {

    /**
     * @dev Modifier that checks that the caller has a specific role.
     *
     * Reverts if caller doesn't have role.
     *
     * See: {AccessController.hasRole}
     */
    modifier onlyRole(bytes32 _role) {
        DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();
        require(ds.accessController.hasRole(_role, msg.sender), "Caller doesn't have role");
        _;
    }

    /**
     * @dev Modifier that checks that the caller has a specific role or is a consignor.
     *
     * Reverts if caller doesn't have role or is not consignor.
     *
     * See: {AccessController.hasRole}
     */
    modifier onlyRoleOrConsignor(bytes32 _role, uint256 _consignmentId) {
        DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();
        require(ds.accessController.hasRole(_role, msg.sender) || getMarketController().getConsignor(_consignmentId) == msg.sender, "Caller doesn't have role or is not consignor");
        _;
    }

    /**
     * @dev Function that checks that the caller has a specific role.
     *
     * Reverts if caller doesn't have role.
     *
     * See: {AccessController.hasRole}
     */
    function checkHasRole(address _address, bytes32 _role) internal view returns (bool) {
        DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();
        return ds.accessController.hasRole(_role, _address);
    }

    /**
     * @notice Gets the address of the Seen.Haus MarketController contract.
     *
     * @return marketController - the address of the MarketController contract
     */
    function getMarketController()
    internal
    view
    returns(IMarketController marketController)
    {
        return IMarketController(address(this));
    }

    /**
     * @notice Sets the audience for a consignment at sale or auction.
     *
     * Emits an AudienceChanged event.
     *
     * @param _consignmentId - the id of the consignment
     * @param _audience - the new audience for the consignment
     */
    function setAudience(uint256 _consignmentId, Audience _audience)
    internal
    {
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();

        // Set the new audience
        mhs.audiences[_consignmentId] = _audience;

        // Notify listeners of state change
        emit AudienceChanged(_consignmentId, _audience);

    }

    /**
     * @notice Check if the caller is a Staker.
     *
     * @return status - true if caller's xSEEN ERC-20 balance is non-zero.
     */
    function isStaker()
    internal
    view
    returns (bool status)
    {
        IMarketController marketController = getMarketController();
        status = IERC20Upgradeable(marketController.getStaking()).balanceOf(msg.sender) > 0;
    }

    /**
     * @notice Check if the caller is a VIP Staker.
     *
     * See {MarketController:vipStakerAmount}
     *
     * @return status - true if caller's xSEEN ERC-20 balance is at least equal to the VIP Staker Amount.
     */
    function isVipStaker()
    internal
    view
    returns (bool status)
    {
        IMarketController marketController = getMarketController();
        status = IERC20Upgradeable(marketController.getStaking()).balanceOf(msg.sender) >= marketController.getVipStakerAmount();
    }

    /**
     * @notice Modifier that checks that caller is in consignment's audience
     *
     * Reverts if user is not in consignment's audience
     */
    modifier onlyAudienceMember(uint256 _consignmentId) {
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();
        Audience audience = mhs.audiences[_consignmentId];
        if (audience != Audience.Open) {
            if (audience == Audience.Staker) {
                require(isStaker());
            } else if (audience == Audience.VipStaker) {
                require(isVipStaker());
            }
        }
        _;
    }

    /**
     * @dev Modifier that checks that the caller is the consignor
     *
     * Reverts if caller isn't the consignor
     *
     * See: {MarketController.getConsignor}
     */
    modifier onlyConsignor(uint256 _consignmentId) {

        // Make sure the caller is the consignor
        require(getMarketController().getConsignor(_consignmentId) == msg.sender, "Caller is not consignor");
        _;
    }

    /**
     * @notice Get a percentage of a given amount.
     *
     * N.B. Represent ercentage values are stored
     * as unsigned integers, the result of multiplying the given percentage by 100:
     * e.g, 1.75% = 175, 100% = 10000
     *
     * @param _amount - the amount to return a percentage of
     * @param _percentage - the percentage value represented as above
     */
    function getPercentageOf(uint256 _amount, uint16 _percentage)
    internal
    pure
    returns (uint256 share)
    {
        share = _amount * _percentage / 10000;
    }

    /**
     * @notice Deduct and pay royalties on sold secondary market consignments.
     *
     * Does nothing is this is a primary market sale.
     *
     * If the consigned item's contract supports NFT Royalty Standard EIP-2981,
     * it is queried for the expected royalty amount and recipient.
     *
     * Deducts royalty and pays to recipient:
     * - entire expected amount, if below or equal to the marketplace's maximum royalty percentage
     * - the marketplace's maximum royalty percentage See: {MarketController.maxRoyaltyPercentage}
     *
     * Emits a RoyaltyDisbursed event with the amount actually paid.
     *
     * @param _consignment - the consigned item
     * @param _grossSale - the gross sale amount
     *
     * @return net - the net amount of the sale after the royalty has been paid
     */
    function deductRoyalties(Consignment memory _consignment, uint256 _grossSale)
    internal
    returns (uint256 net)
    {
        // Only pay royalties on secondary market sales
        uint256 royaltyAmount = 0;
        if (_consignment.market == Market.Secondary) {
            // Determine if NFT contract supports NFT Royalty Standard EIP-2981
            try IERC165Upgradeable(_consignment.tokenAddress).supportsInterface(type(IERC2981).interfaceId) returns (bool supported) {

                // If so, find out the who to pay and how much
                if (supported) {

                    // Get the MarketController
                    IMarketController marketController = getMarketController();

                    // Get the royalty recipient and expected payment
                    (address recipient, uint256 expected) = IERC2981(_consignment.tokenAddress).royaltyInfo(_consignment.tokenId, _grossSale);

                    // Determine the max royalty we will pay
                    uint256 maxRoyalty = getPercentageOf(_grossSale, marketController.getMaxRoyaltyPercentage());

                    // If a royalty is expected...
                    if (expected > 0) {

                        // Lets pay, but only up to our platform policy maximum
                        royaltyAmount = (expected <= maxRoyalty) ? expected : maxRoyalty;
                        sendValueOrCreditAccount(payable(recipient), royaltyAmount);

                        // Notify listeners of payment
                        emit RoyaltyDisbursed(_consignment.id, recipient, royaltyAmount);
                    }

                }

            // Any case where the check for interface support fails can be ignored
            } catch Error(string memory) {
            } catch (bytes memory) {
            }

        }

        // Return the net amount after royalty deduction
        net = _grossSale - royaltyAmount;
    }

    /**
     * @notice Deduct and pay escrow agent fees on sold physical secondary market consignments.
     *
     * Does nothing if this is a primary market sale.
     *
     * Deducts escrow agent fee and pays to consignor
     * - entire expected amount
     *
     * Emits a EscrowAgentFeeDisbursed event with the amount actually paid.
     *
     * @param _consignment - the consigned item
     * @param _grossSale - the gross sale amount
     * @param _netAfterRoyalties - the funds left to be distributed
     *
     * @return net - the net amount of the sale after the royalty has been paid
     */
    function deductEscrowAgentFee(Consignment memory _consignment, uint256 _grossSale, uint256 _netAfterRoyalties)
    internal
    returns (uint256 net)
    {
        // Only pay royalties on secondary market sales
        uint256 escrowAgentFeeAmount = 0;
        if (_consignment.market == Market.Secondary) {
            // Get the MarketController
            IMarketController marketController = getMarketController();
            address consignor = marketController.getConsignor(_consignment.id);
            if(consignor != _consignment.seller) {
                uint16 escrowAgentBasisPoints = marketController.getEscrowAgentFeeBasisPoints(consignor);
                if(escrowAgentBasisPoints > 0) {
                    // Determine if consignment is physical
                    address nft = marketController.getNft();
                    if (nft == _consignment.tokenAddress && ISeenHausNFT(nft).isPhysical(_consignment.tokenId)) {
                        // Consignor is not seller, consigner has a positive escrowAgentBasisPoints value, consignment is of a physical item
                        // Therefore, pay consignor the escrow agent fees
                        escrowAgentFeeAmount = getPercentageOf(_grossSale, escrowAgentBasisPoints);

                        // If escrow agent fee is expected...
                        if (escrowAgentFeeAmount > 0) {
                            require(escrowAgentFeeAmount <= _netAfterRoyalties, "escrowAgentFeeAmount exceeds remaining funds");
                            sendValueOrCreditAccount(payable(consignor), escrowAgentFeeAmount);
                            // Notify listeners of payment
                            emit EscrowAgentFeeDisbursed(_consignment.id, consignor, escrowAgentFeeAmount);
                        }
                    }
                }
            }
        }

        // Return the net amount after royalty deduction
        net = _netAfterRoyalties - escrowAgentFeeAmount;
    }

    /**
     * @notice Deduct and pay fee on a sold consignment.
     *
     * Deducts marketplace fee and pays:
     * - Half to the staking contract
     * - Half to the multisig contract
     *
     * Emits a FeeDisbursed event for staking payment.
     * Emits a FeeDisbursed event for multisig payment.
     *
     * @param _consignment - the consigned item
     * @param _grossSale - the gross sale amount
     * @param _netAmount - the net amount after royalties (total remaining to be distributed as part of payout process)
     *
     * @return payout - the payout amount for the seller
     */
    function deductFee(Consignment memory _consignment, uint256 _grossSale, uint256 _netAmount)
    internal
    returns (uint256 payout)
    {
        // Get the MarketController
        IMarketController marketController = getMarketController();

        // With the net after royalties, calculate and split
        // the auction fee between SEEN staking and multisig,
        uint256 feeAmount;
        if(_consignment.customFeePercentageBasisPoints > 0) {
            feeAmount = getPercentageOf(_grossSale, _consignment.customFeePercentageBasisPoints);
        } else {
            feeAmount = getPercentageOf(_grossSale, marketController.getFeePercentage(_consignment.market));
        }
        require(feeAmount <= _netAmount, "feeAmount exceeds remaining funds");
        uint256 splitStaking = feeAmount / 2;
        uint256 splitMultisig = feeAmount - splitStaking;
        address payable staking = marketController.getStaking();
        address payable multisig = marketController.getMultisig();
        sendValueOrCreditAccount(staking, splitStaking);
        sendValueOrCreditAccount(multisig, splitMultisig);

        // Return the seller payout amount after fee deduction
        payout = _netAmount - feeAmount;

        // Notify listeners of payment
        emit FeeDisbursed(_consignment.id, staking, splitStaking);
        emit FeeDisbursed(_consignment.id, multisig, splitMultisig);
    }

    /**
     * @notice Disburse funds for a sale or auction, primary or secondary.
     *
     * Disburses funds in this order
     * - Pays any necessary royalties first. See {deductRoyalties}
     * - Deducts and distributes marketplace fee. See {deductFee}
     * - Pays the remaining amount to the seller.
     *
     * Emits a PayoutDisbursed event on success.
     *
     * @param _consignmentId - the id of the consignment being sold
     * @param _saleAmount - the gross sale amount
     */
    function disburseFunds(uint256 _consignmentId, uint256 _saleAmount)
    internal
    {
        // Get the MarketController
        IMarketController marketController = getMarketController();

        // Get consignment
        SeenTypes.Consignment memory consignment = marketController.getConsignment(_consignmentId);

        // Pay royalties if needed
        uint256 netAfterRoyalties = deductRoyalties(consignment, _saleAmount);

        // Pay escrow agent fees if needed
        uint256 netAfterEscrowAgentFees = deductEscrowAgentFee(consignment, _saleAmount, netAfterRoyalties);

        // Pay marketplace fee
        uint256 payout = deductFee(consignment, _saleAmount, netAfterEscrowAgentFees);

        // Pay seller
        sendValueOrCreditAccount(consignment.seller, payout);

        // Notify listeners of payment
        emit PayoutDisbursed(_consignmentId, consignment.seller, payout);
    }

    /**
     * @notice Attempts an ETH transfer, else adds a pull-able credit
     *
     * In cases where ETH is unable to be transferred to a particular address
     * either due to malicious agents or bugs in receiver addresses
     * the payout process should not fail for all parties involved 
     * (or funds can become stuck for benevolent parties)
     *
     * @param _recipient - the recipient of the transfer
     * @param _value - the transfer value
     */
    function sendValueOrCreditAccount(address payable _recipient, uint256 _value)
    internal
    {
        // Attempt to send funds to recipient
        require(address(this).balance >= _value);
        (bool success, ) = _recipient.call{value: _value}("");
        if(!success) {
            // Credit the account
            MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();
            mhs.addressToEthCredit[_recipient] += _value;
            emit EthCredited(_recipient, _value);
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IMarketConfig.sol";
import "./IMarketConfigAdditional.sol";
import "./IMarketClerk.sol";

/**
 * @title IMarketController
 *
 * @notice Manages configuration and consignments used by the Seen.Haus contract suite.
 *
 * The ERC-165 identifier for this interface is: 0xbb8dba77
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
interface IMarketController is IMarketClerk, IMarketConfig, IMarketConfigAdditional {}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../domain/SeenTypes.sol";

/**
 * @title IMarketHandler
 *
 * @notice Provides no functions, only common events to market handler facets.
 *
 * No ERC-165 identifier for this interface, not checked or supported.
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
interface IMarketHandler {

    // Events
    event RoyaltyDisbursed(uint256 indexed consignmentId, address indexed recipient, uint256 amount);
    event EscrowAgentFeeDisbursed(uint256 indexed consignmentId, address indexed recipient, uint256 amount);
    event FeeDisbursed(uint256 indexed consignmentId, address indexed recipient, uint256 amount);
    event PayoutDisbursed(uint256 indexed consignmentId, address indexed recipient, uint256 amount);
    event AudienceChanged(uint256 indexed consignmentId, SeenTypes.Audience indexed audience);
    event EthCredited(address indexed recipient, uint256 amount);

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "../domain/SeenTypes.sol";
import "./IERC2981.sol";

/**
 * @title ISeenHausNFT
 *
 * @notice This is the interface for the Seen.Haus ERC-1155 NFT contract.
 *
 * The ERC-165 identifier for this interface is: 0x34d6028b
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
*/
interface ISeenHausNFT is IERC2981, IERC1155Upgradeable {

    /**
     * @notice The nextToken getter
     * @dev does not increment counter
     */
    function getNextToken() external view returns (uint256 nextToken);

    /**
     * @notice Get the info about a given token.
     *
     * @param _tokenId - the id of the token to check
     * @return tokenInfo - the info about the token. See: {SeenTypes.Token}
     */
    function getTokenInfo(uint256 _tokenId) external view returns (SeenTypes.Token memory tokenInfo);

    /**
     * @notice Check if a given token id corresponds to a physical lot.
     *
     * @param _tokenId - the id of the token to check
     * @return physical - true if the item corresponds to a physical lot
     */
    function isPhysical(uint256 _tokenId) external returns (bool);

    /**
     * @notice Mint a given supply of a token, marking it as physical.
     *
     * Entire supply must be minted at once.
     * More cannot be minted later for the same token id.
     * Can only be called by an address with the ESCROW_AGENT role.
     * Token supply is sent to the caller.
     *
     * @param _supply - the supply of the token
     * @param _creator - the creator of the NFT (where the royalties will go)
     * @param _tokenURI - the URI of the token metadata
     *
     * @return consignment - the registered primary market consignment of the newly minted token
     */
    function mintPhysical(
        uint256 _supply,
        address payable _creator,
        string memory _tokenURI,
        uint16 _royaltyPercentage
    )
    external
    returns(SeenTypes.Consignment memory consignment);

    /**
     * @notice Mint a given supply of a token.
     *
     * Entire supply must be minted at once.
     * More cannot be minted later for the same token id.
     * Can only be called by an address with the MINTER role.
     * Token supply is sent to the caller's address.
     *
     * @param _supply - the supply of the token
     * @param _creator - the creator of the NFT (where the royalties will go)
     * @param _tokenURI - the URI of the token metadata
     *
     * @return consignment - the registered primary market consignment of the newly minted token
     */
    function mintDigital(
        uint256 _supply,
        address payable _creator,
        string memory _tokenURI,
        uint16 _royaltyPercentage
    )
    external
    returns(SeenTypes.Consignment memory consignment);

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external;

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external;

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

/**
 * @title IERC2981 interface
 *
 * @notice NFT Royalty Standard.
 *
 * See https://eips.ethereum.org/EIPS/eip-2981
 */
interface IERC2981 is IERC165Upgradeable {

    /**
     * @notice Determine how much royalty is owed (if any) and to whom.
     * @param _tokenId - the NFT asset queried for royalty information
     * @param _salePrice - the sale price of the NFT asset specified by _tokenId
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for _salePrice
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external
    view
    returns (
        address receiver,
        uint256 royaltyAmount
    );

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title SeenTypes
 *
 * @notice Enums and structs used by the Seen.Haus contract ecosystem.
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract SeenTypes {

    enum Market {
        Primary,
        Secondary
    }

    enum MarketHandler {
        Unhandled,
        Auction,
        Sale
    }

    enum Clock {
        Live,
        Trigger
    }

    enum Audience {
        Open,
        Staker,
        VipStaker
    }

    enum Outcome {
        Pending,
        Closed,
        Canceled
    }

    enum State {
        Pending,
        Running,
        Ended
    }

    enum Ticketer {
        Default,
        Lots,
        Items
    }

    struct Token {
        address payable creator;
        uint16 royaltyPercentage;
        bool isPhysical;
        uint256 id;
        uint256 supply;
        string uri;
    }

    struct Consignment {
        Market market;
        MarketHandler marketHandler;
        address payable seller;
        address tokenAddress;
        uint256 tokenId;
        uint256 supply;
        uint256 id;
        bool multiToken;
        bool released;
        uint256 releasedSupply;
        uint16 customFeePercentageBasisPoints;
        uint256 pendingPayout;
    }

    struct Auction {
        address payable buyer;
        uint256 consignmentId;
        uint256 start;
        uint256 duration;
        uint256 reserve;
        uint256 bid;
        Clock clock;
        State state;
        Outcome outcome;
    }

    struct Sale {
        uint256 consignmentId;
        uint256 start;
        uint256 price;
        uint256 perTxCap;
        State state;
        Outcome outcome;
    }

    struct EscrowTicket {
        uint256 amount;
        uint256 consignmentId;
        uint256 id;
        string itemURI;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/IMarketController.sol";
import "../../domain/SeenTypes.sol";
import "../diamond/DiamondLib.sol";

/**
 * @title MarketHandlerLib
 *
 * @dev Provides access to the the MarketHandler Storage and Intitializer slots for MarketHandler facets
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
library MarketHandlerLib {

    bytes32 constant MARKET_HANDLER_STORAGE_POSITION = keccak256("seen.haus.market.handler.storage");
    bytes32 constant MARKET_HANDLER_INITIALIZERS_POSITION = keccak256("seen.haus.market.handler.initializers");

    struct MarketHandlerStorage {

        // map a consignment id to an audience
        mapping(uint256 => SeenTypes.Audience) audiences;

        //s map a consignment id to a sale
        mapping(uint256 => SeenTypes.Sale) sales;

        // @dev map a consignment id to an auction
        mapping(uint256 => SeenTypes.Auction) auctions;

        // map an address to ETH credit available to withdraw
        mapping(address => uint256) addressToEthCredit;

    }

    struct MarketHandlerInitializers {

        // AuctionBuilderFacet initialization state
        bool auctionBuilderFacet;

        // AuctionRunnerFacet initialization state
        bool auctionRunnerFacet;

        // AuctionEnderFacet initialization state
        bool auctionEnderFacet;

        // SaleBuilderFacet initialization state
        bool saleBuilderFacet;

        // SaleRunnerFacet initialization state
        bool saleRunnerFacet;

        // SaleRunnerFacet initialization state
        bool saleEnderFacet;

        // EthCreditFacet initialization state
        bool ethCreditRecoveryFacet;

    }

    function marketHandlerStorage() internal pure returns (MarketHandlerStorage storage mhs) {
        bytes32 position = MARKET_HANDLER_STORAGE_POSITION;
        assembly {
            mhs.slot := position
        }
    }

    function marketHandlerInitializers() internal pure returns (MarketHandlerInitializers storage mhi) {
        bytes32 position = MARKET_HANDLER_INITIALIZERS_POSITION;
        assembly {
            mhi.slot := position
        }
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../domain/SeenTypes.sol";

/**
 * @title IMarketController
 *
 * @notice Manages configuration and consignments used by the Seen.Haus contract suite.
 * @dev Contributes its events and functions to the IMarketController interface
 *
 * The ERC-165 identifier for this interface is: 0x57f9f26d
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
interface IMarketConfig {

    /// Events
    event NFTAddressChanged(address indexed nft);
    event EscrowTicketerAddressChanged(address indexed escrowTicketer, SeenTypes.Ticketer indexed ticketerType);
    event StakingAddressChanged(address indexed staking);
    event MultisigAddressChanged(address indexed multisig);
    event VipStakerAmountChanged(uint256 indexed vipStakerAmount);
    event PrimaryFeePercentageChanged(uint16 indexed feePercentage);
    event SecondaryFeePercentageChanged(uint16 indexed feePercentage);
    event MaxRoyaltyPercentageChanged(uint16 indexed maxRoyaltyPercentage);
    event OutBidPercentageChanged(uint16 indexed outBidPercentage);
    event DefaultTicketerTypeChanged(SeenTypes.Ticketer indexed ticketerType);

    /**
     * @notice Sets the address of the xSEEN ERC-20 staking contract.
     *
     * Emits a NFTAddressChanged event.
     *
     * @param _nft - the address of the nft contract
     */
    function setNft(address _nft) external;

    /**
     * @notice The nft getter
     */
    function getNft() external view returns (address);

    /**
     * @notice Sets the address of the Seen.Haus lots-based escrow ticketer contract.
     *
     * Emits a EscrowTicketerAddressChanged event.
     *
     * @param _lotsTicketer - the address of the items-based escrow ticketer contract
     */
    function setLotsTicketer(address _lotsTicketer) external;

    /**
     * @notice The lots-based escrow ticketer getter
     */
    function getLotsTicketer() external view returns (address);

    /**
     * @notice Sets the address of the Seen.Haus items-based escrow ticketer contract.
     *
     * Emits a EscrowTicketerAddressChanged event.
     *
     * @param _itemsTicketer - the address of the items-based escrow ticketer contract
     */
    function setItemsTicketer(address _itemsTicketer) external;

    /**
     * @notice The items-based escrow ticketer getter
     */
    function getItemsTicketer() external view returns (address);

    /**
     * @notice Sets the address of the xSEEN ERC-20 staking contract.
     *
     * Emits a StakingAddressChanged event.
     *
     * @param _staking - the address of the staking contract
     */
    function setStaking(address payable _staking) external;

    /**
     * @notice The staking getter
     */
    function getStaking() external view returns (address payable);

    /**
     * @notice Sets the address of the Seen.Haus multi-sig wallet.
     *
     * Emits a MultisigAddressChanged event.
     *
     * @param _multisig - the address of the multi-sig wallet
     */
    function setMultisig(address payable _multisig) external;

    /**
     * @notice The multisig getter
     */
    function getMultisig() external view returns (address payable);

    /**
     * @notice Sets the VIP staker amount.
     *
     * Emits a VipStakerAmountChanged event.
     *
     * @param _vipStakerAmount - the minimum amount of xSEEN ERC-20 a caller must hold to participate in VIP events
     */
    function setVipStakerAmount(uint256 _vipStakerAmount) external;

    /**
     * @notice The vipStakerAmount getter
     */
    function getVipStakerAmount() external view returns (uint256);

    /**
     * @notice Sets the marketplace fee percentage.
     * Emits a PrimaryFeePercentageChanged event.
     *
     * @param _primaryFeePercentage - the percentage that will be taken as a fee from the net of a Seen.Haus primary sale or auction
     *
     * N.B. Represent percentage value as an unsigned int by multiplying the percentage by 100:
     * e.g, 1.75% = 175, 100% = 10000
     */
    function setPrimaryFeePercentage(uint16 _primaryFeePercentage) external;

    /**
     * @notice Sets the marketplace fee percentage.
     * Emits a SecondaryFeePercentageChanged event.
     *
     * @param _secondaryFeePercentage - the percentage that will be taken as a fee from the net of a Seen.Haus secondary sale or auction (after royalties)
     *
     * N.B. Represent percentage value as an unsigned int by multiplying the percentage by 100:
     * e.g, 1.75% = 175, 100% = 10000
     */
    function setSecondaryFeePercentage(uint16 _secondaryFeePercentage) external;

    /**
     * @notice The primaryFeePercentage and secondaryFeePercentage getter
     */
    function getFeePercentage(SeenTypes.Market _market) external view returns (uint16);

    /**
     * @notice Sets the external marketplace maximum royalty percentage.
     *
     * Emits a MaxRoyaltyPercentageChanged event.
     *
     * @param _maxRoyaltyPercentage - the maximum percentage of a Seen.Haus sale or auction that will be paid as a royalty
     */
    function setMaxRoyaltyPercentage(uint16 _maxRoyaltyPercentage) external;

    /**
     * @notice The maxRoyaltyPercentage getter
     */
    function getMaxRoyaltyPercentage() external view returns (uint16);

    /**
     * @notice Sets the marketplace auction outbid percentage.
     *
     * Emits a OutBidPercentageChanged event.
     *
     * @param _outBidPercentage - the minimum percentage a Seen.Haus auction bid must be above the previous bid to prevail
     */
    function setOutBidPercentage(uint16 _outBidPercentage) external;

    /**
     * @notice The outBidPercentage getter
     */
    function getOutBidPercentage() external view returns (uint16);

    /**
     * @notice Sets the default escrow ticketer type.
     *
     * Emits a DefaultTicketerTypeChanged event.
     *
     * Reverts if _ticketerType is Ticketer.Default
     * Reverts if _ticketerType is already the defaultTicketerType
     *
     * @param _ticketerType - the new default escrow ticketer type.
     */
    function setDefaultTicketerType(SeenTypes.Ticketer _ticketerType) external;

    /**
     * @notice The defaultTicketerType getter
     */
    function getDefaultTicketerType() external view returns (SeenTypes.Ticketer);

    /**
     * @notice Get the Escrow Ticketer to be used for a given consignment
     *
     * If a specific ticketer has not been set for the consignment,
     * the default escrow ticketer will be returned.
     *
     * @param _consignmentId - the id of the consignment
     * @return ticketer = the address of the escrow ticketer to use
     */
    function getEscrowTicketer(uint256 _consignmentId) external view returns (address ticketer);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../domain/SeenTypes.sol";

/**
 * @title IMarketController
 *
 * @notice Manages configuration and consignments used by the Seen.Haus contract suite.
 * @dev Contributes its events and functions to the IMarketController interface
 *
 * The ERC-165 identifier for this interface is: 0x57f9f26d
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
interface IMarketConfigAdditional {

    /// Events
    event AllowExternalTokensOnSecondaryChanged(bool indexed status);
    event EscrowAgentFeeChanged(address indexed escrowAgent, uint16 fee);
    
    /**
     * @notice Sets whether or not external tokens can be listed on secondary market
     *
     * Emits an AllowExternalTokensOnSecondaryChanged event.
     *
     * @param _status - boolean of whether or not external tokens are allowed
     */
    function setAllowExternalTokensOnSecondary(bool _status) external;

    /**
     * @notice The allowExternalTokensOnSecondary getter
     */
    function getAllowExternalTokensOnSecondary() external view returns (bool status);

        /**
     * @notice The escrow agent fee getter
     */
    function getEscrowAgentFeeBasisPoints(address _escrowAgentAddress) external view returns (uint16);

    /**
     * @notice The escrow agent fee setter
     */
    function setEscrowAgentFeeBasisPoints(address _escrowAgentAddress, uint16 _basisPoints) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "../domain/SeenTypes.sol";

/**
 * @title IMarketClerk
 *
 * @notice Manages consignments for the Seen.Haus contract suite.
 *
 * The ERC-165 identifier for this interface is: 0xec74481a
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
interface IMarketClerk is IERC1155ReceiverUpgradeable, IERC721ReceiverUpgradeable {

    /// Events
    event ConsignmentTicketerChanged(uint256 indexed consignmentId, SeenTypes.Ticketer indexed ticketerType);
    event ConsignmentFeeChanged(uint256 indexed consignmentId, uint16 customConsignmentFee);
    event ConsignmentPendingPayoutSet(uint256 indexed consignmentId, uint256 amount);
    event ConsignmentRegistered(address indexed consignor, address indexed seller, SeenTypes.Consignment consignment);
    event ConsignmentMarketed(address indexed consignor, address indexed seller, uint256 indexed consignmentId);
    event ConsignmentReleased(uint256 indexed consignmentId, uint256 amount, address releasedTo);

    /**
     * @notice The nextConsignment getter
     */
    function getNextConsignment() external view returns (uint256);

    /**
     * @notice The consignment getter
     */
    function getConsignment(uint256 _consignmentId) external view returns (SeenTypes.Consignment memory);

    /**
     * @notice Get the remaining supply of the given consignment.
     *
     * @param _consignmentId - the id of the consignment
     * @return uint256 - the remaining supply held by the MarketController
     */
    function getUnreleasedSupply(uint256 _consignmentId) external view returns(uint256);

    /**
     * @notice Get the consignor of the given consignment
     *
     * @param _consignmentId - the id of the consignment
     * @return  address - consigner's address
     */
    function getConsignor(uint256 _consignmentId) external view returns(address);

    /**
     * @notice Registers a new consignment for sale or auction.
     *
     * Emits a ConsignmentRegistered event.
     *
     * @param _market - the market for the consignment. See {SeenTypes.Market}
     * @param _consignor - the address executing the consignment transaction
     * @param _seller - the seller of the consignment
     * @param _tokenAddress - the contract address issuing the NFT behind the consignment
     * @param _tokenId - the id of the token being consigned
     * @param _supply - the amount of the token being consigned
     *
     * @return Consignment - the registered consignment
     */
    function registerConsignment(
        SeenTypes.Market _market,
        address _consignor,
        address payable _seller,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _supply
    )
    external
    returns(SeenTypes.Consignment memory);

    /**
      * @notice Update consignment to indicate it has been marketed
      *
      * Emits a ConsignmentMarketed event.
      *
      * Reverts if consignment has already been marketed.
      * A consignment is considered as marketed if it has a marketHandler other than Unhandled. See: {SeenTypes.MarketHandler}
      *
      * @param _consignmentId - the id of the consignment
      */
    function marketConsignment(uint256 _consignmentId, SeenTypes.MarketHandler _marketHandler) external;

    /**
     * @notice Release the consigned item to a given address
     *
     * Emits a ConsignmentReleased event.
     *
     * Reverts if caller is does not have MARKET_HANDLER role.
     *
     * @param _consignmentId - the id of the consignment
     * @param _amount - the amount of the consigned supply to release
     * @param _releaseTo - the address to transfer the consigned token balance to
     */
    function releaseConsignment(uint256 _consignmentId, uint256 _amount, address _releaseTo) external;

    /**
     * @notice Clears the pending payout value of a consignment
     *
     * Emits a ConsignmentPayoutSet event.
     *
     * Reverts if:
     *  - caller is does not have MARKET_HANDLER role.
     *  - consignment doesn't exist
     *
     * @param _consignmentId - the id of the consignment
     * @param _amount - the amount of that the consignment's pendingPayout must be set to
     */
    function setConsignmentPendingPayout(uint256 _consignmentId, uint256 _amount) external;

    /**
     * @notice Set the type of Escrow Ticketer to be used for a consignment
     *
     * Default escrow ticketer is Ticketer.Lots. This only needs to be called
     * if overriding to Ticketer.Items for a given consignment.
     *
     * Emits a ConsignmentTicketerSet event.
     * Reverts if consignment is not registered.
     *
     * @param _consignmentId - the id of the consignment
     * @param _ticketerType - the type of ticketer to use. See: {SeenTypes.Ticketer}
     */
    function setConsignmentTicketer(uint256 _consignmentId, SeenTypes.Ticketer _ticketerType) external;

    /**
     * @notice Set a custom fee percentage on a consignment (e.g. for "official" SEEN x Artist drops)
     *
     * Default escrow ticketer is Ticketer.Lots. This only needs to be called
     * if overriding to Ticketer.Items for a given consignment.
     *
     * Emits a ConsignmentFeeChanged event.
     *
     * Reverts if consignment doesn't exist     *
     *
     * @param _consignmentId - the id of the consignment
     * @param _customFeePercentageBasisPoints - the custom fee percentage basis points to use
     *
     * N.B. _customFeePercentageBasisPoints percentage value as an unsigned int by multiplying the percentage by 100:
     * e.g, 1.75% = 175, 100% = 10000
     */
    function setConsignmentCustomFee(uint256 _consignmentId, uint16 _customFeePercentageBasisPoints) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
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

import { IAccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import { IDiamondCut } from "../../interfaces/IDiamondCut.sol";

/**
 * @title DiamondLib
 *
 * @notice Diamond storage slot and supported interfaces
 *
 * @notice Based on Nick Mudge's gas-optimized diamond-2 reference,
 * with modifications to support role-based access and management of
 * supported interfaces.
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

    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

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

        // The Seen.Haus AccessController
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

// SPDX-License-Identifier: MIT

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

    enum FacetCutAction {Add, Replace, Remove}

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

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "../../../interfaces/IEscrowTicketer.sol";
import "../../../interfaces/ISeenHausNFT.sol";
import "../../../interfaces/ISaleRunner.sol";
import "../MarketHandlerBase.sol";

/**
 * @title SaleRunnerFacet
 *
 * @notice Handles the operation of Seen.Haus sales.
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract SaleRunnerFacet is ISaleRunner, MarketHandlerBase {

    // Threshold to auction extension window
    uint256 constant extensionWindow = 15 minutes;

    /**
     * @dev Modifier to protect initializer function from being invoked twice.
     */
    modifier onlyUnInitialized()
    {
        MarketHandlerLib.MarketHandlerInitializers storage mhi = MarketHandlerLib.marketHandlerInitializers();
        require(!mhi.saleRunnerFacet, "already initialized");
        mhi.saleRunnerFacet = true;
        _;
    }

    /**
     * @notice Facet Initializer
     *
     * Register supported interfaces
     */
    function initialize()
    public
    onlyUnInitialized
    {
        DiamondLib.addSupportedInterface(type(ISaleRunner).interfaceId);
    }

    /**
     * @notice Change the audience for a sale.
     *
     * Reverts if:
     *  - Caller does not have ADMIN role
     *  - Auction doesn't exist or has already been settled
     *
     * @param _consignmentId - the id of the consignment being sold
     * @param _audience - the new audience for the sale
     */
    function changeSaleAudience(uint256 _consignmentId, Audience _audience)
    external
    override
    onlyRole(ADMIN)
    {
        // Get Market Handler Storage slot
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();

        // Get consignment (reverting if not valid)
        Consignment memory consignment = getMarketController().getConsignment(_consignmentId);

        // Make sure the sale exists and hasn't been settled
        Sale storage sale = mhs.sales[consignment.id];
        require((sale.state != State.Ended) && (sale.start != 0), "already settled or non-existent");

        // Set the new audience for the consignment
        setAudience(_consignmentId, _audience);

    }

    /**
     * @notice Buy some amount of the remaining supply of the lot for sale.
     *
     * Ownership of the purchased inventory is transferred to the buyer.
     * The buyer's payment will be held for disbursement when sale is settled.
     *
     * Reverts if:
     *  - Caller is not in audience
     *  - Sale doesn't exist or hasn't started
     *  - Caller is a contract
     *  - The per-transaction buy limit is exceeded
     *  - Payment doesn't cover the order price
     *
     * Emits a Purchase event.
     * May emit a SaleStarted event, on the first purchase.
     *
     * @param _consignmentId - id of the consignment being sold
     * @param _amount - the amount of the remaining supply to buy
     */
    function buy(uint256 _consignmentId, uint256 _amount)
    external
    override
    payable
    onlyAudienceMember(_consignmentId)
    {
        // Get Market Handler Storage slot
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();

        // Get the consignment
        Consignment memory consignment = getMarketController().getConsignment(_consignmentId);

        // Make sure we can accept the buy order & that the sale exists
        Sale storage sale = mhs.sales[_consignmentId];
        require((block.timestamp >= sale.start) && (sale.start != 0), "Sale hasn't started or non-existent");
        require(_amount <= sale.perTxCap, "Per tx limit exceeded");
        require(msg.value == sale.price * _amount, "Value doesn't cover price");

        // If this was the first successful purchase...
        if (sale.state == State.Pending) {

            // First buy updates sale state to Running
            sale.state = State.Running;

            // Notify listeners of state change
            emit SaleStarted(_consignmentId);

        }

        uint256 pendingPayoutValue = consignment.pendingPayout + msg.value;
        getMarketController().setConsignmentPendingPayout(consignment.id, pendingPayoutValue);

        // Determine if consignment is physical
        address nft = getMarketController().getNft();
        if (nft == consignment.tokenAddress && ISeenHausNFT(nft).isPhysical(consignment.tokenId)) {

            // Issue an escrow ticket to the buyer
            address escrowTicketer = getMarketController().getEscrowTicketer(_consignmentId);
            IEscrowTicketer(escrowTicketer).issueTicket(_consignmentId, _amount, payable(msg.sender));

        } else {

            // Release the purchased amount of the consigned token supply to buyer
            getMarketController().releaseConsignment(_consignmentId, _amount, msg.sender);

        }

        // Announce the purchase
        emit Purchase(consignment.id, msg.sender, _amount, msg.value);

        // Track the sale info against the token itself
        emit TokenHistoryTracker(consignment.tokenAddress, consignment.tokenId, msg.sender, msg.value, _amount, consignment.id);
    }

    /**
     * @notice Claim a pending payout on an ongoing sale without closing/cancelling
     *
     * Funds are disbursed as normal. See: {MarketHandlerBase.disburseFunds}
     *
     * Reverts if:
     * - Sale doesn't exist or hasn't started
     * - There is no pending payout
     * - Called by any address other than seller
     * - The sale is sold out (in which case closeSale should be called)
     *
     * Does not emit its own event, but disburseFunds emits an event
     *
     * @param _consignmentId - id of the consignment being sold
     */
    function claimPendingPayout(uint256 _consignmentId)
    external
    override
    {
        // Get Market Handler Storage slot
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();

        // Get consignment
        Consignment memory consignment = getMarketController().getConsignment(_consignmentId);

        // Ensure that there is a pending payout & that caller is the seller
        require((consignment.pendingPayout > 0) && (consignment.seller == msg.sender));

        // Ensure that the sale has not yet sold out
        require((consignment.supply - consignment.releasedSupply) > 0, "sold out - use closeSale");

        // Make sure the sale exists and is running
        Sale storage sale = mhs.sales[_consignmentId];
        require((sale.state == State.Running) && (sale.start != 0), "Sale hasn't started or non-existent");

        // Distribute the funds (handles royalties, staking, multisig, and seller)
        getMarketController().setConsignmentPendingPayout(consignment.id, 0);
        disburseFunds(_consignmentId, consignment.pendingPayout);

    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../domain/SeenTypes.sol";

/**
 * @title IEscrowTicketer
 *
 * @notice Manages the issue and claim of escrow tickets.
 *
 * The ERC-165 identifier for this interface is: 0x73811679
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
interface IEscrowTicketer {

    event TicketIssued(uint256 ticketId, uint256 indexed consignmentId, address indexed buyer, uint256 amount);
    event TicketClaimed(uint256 ticketId, address indexed claimant, uint256 amount);

    /**
     * @notice The nextTicket getter
     */
    function getNextTicket() external view returns (uint256);

    /**
     * @notice Get info about the ticket
     */
    function getTicket(uint256 _ticketId) external view returns (SeenTypes.EscrowTicket memory);

    /**
     * @notice Get how many claims can be made using tickets (does not change after ticket burns)
     */
    function getTicketClaimableCount(uint256 _consignmentId) external view returns (uint256);

    /**
     * @notice Gets the URI for the ticket metadata
     *
     * This method normalizes how you get the URI,
     * since ERC721 and ERC1155 differ in approach
     *
     * @param _ticketId - the token id of the ticket
     */
    function getTicketURI(uint256 _ticketId) external view returns (string memory);

    /**
     * Issue an escrow ticket to the buyer
     *
     * For physical consignments, Seen.Haus must hold the items in escrow
     * until the buyer(s) claim them.
     *
     * When a buyer wins an auction or makes a purchase in a sale, the market
     * handler contract they interacted with will call this method to issue an
     * escrow ticket, which is an NFT that can be sold, transferred, or claimed.
     *
     * @param _consignmentId - the id of the consignment being sold
     * @param _amount - the amount of the given token to escrow
     * @param _buyer - the buyer of the escrowed item(s) to whom the ticket is issued
     */
    function issueTicket(uint256 _consignmentId, uint256 _amount, address payable _buyer) external;

    /**
     * Claim the holder's escrowed items associated with the ticket.
     *
     * @param _ticketId - the ticket representing the escrowed items
     */
    function claim(uint256 _ticketId) external;

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../domain/SeenTypes.sol";
import "./IMarketHandler.sol";

/**
 * @title ISaleRunner
 *
 * @notice Handles the operation of Seen.Haus sales.
 *
 * The ERC-165 identifier for this interface is: 0xe1bf15c5
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
interface ISaleRunner is IMarketHandler {

    // Events
    event SaleStarted(uint256 indexed consignmentId);
    event Purchase(uint256 indexed consignmentId, address indexed buyer, uint256 amount, uint256 value);
    event TokenHistoryTracker(address indexed tokenAddress, uint256 indexed tokenId, address indexed buyer, uint256 value, uint256 amount, uint256 consignmentId);

    /**
     * @notice Change the audience for a sale.
     *
     * Reverts if:
     *  - Caller does not have ADMIN role
     *  - Auction doesn't exist or has already been settled
     *
     * @param _consignmentId - the id of the consignment being sold
     * @param _audience - the new audience for the sale
     */
    function changeSaleAudience(uint256 _consignmentId, SeenTypes.Audience _audience) external;

    /**
     * @notice Buy some amount of the remaining supply of the lot for sale.
     *
     * Ownership of the purchased inventory is transferred to the buyer.
     * The buyer's payment will be held for disbursement when sale is settled.
     *
     * Reverts if:
     *  - Caller is not in audience
     *  - Sale doesn't exist or hasn't started
     *  - Caller is a contract
     *  - The per-transaction buy limit is exceeded
     *  - Payment doesn't cover the order price
     *
     * Emits a Purchase event.
     * May emit a SaleStarted event, on the first purchase.
     *
     * @param _consignmentId - id of the consignment being sold
     * @param _amount - the amount of the remaining supply to buy
     */
    function buy(uint256 _consignmentId, uint256 _amount) external payable;

    /**
     * @notice Claim a pending payout on an ongoing sale without closing/cancelling
     *
     * Funds are disbursed as normal. See: {MarketHandlerBase.disburseFunds}
     *
     * Reverts if:
     * - Sale doesn't exist or hasn't started
     * - There is no pending payout
     * - Called by any address other than seller
     * - The sale is sold out (in which case closeSale should be called)
     *
     * Does not emit its own event, but disburseFunds emits an event
     *
     * @param _consignmentId - id of the consignment being sold
     */
    function claimPendingPayout(uint256 _consignmentId) external;

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

import "../interfaces/IAuctionBuilder.sol";
import "../interfaces/IAuctionHandler.sol";
import "../interfaces/IAuctionRunner.sol";
import "../interfaces/IAuctionEnder.sol";
import "../interfaces/IDiamondCut.sol";
import "../interfaces/IDiamondLoupe.sol";
import "../interfaces/IERC2981.sol";
import "../interfaces/IEscrowTicketer.sol";
import "../interfaces/IMarketClerk.sol";
import "../interfaces/IMarketClientProxy.sol";
import "../interfaces/IMarketConfig.sol";
import "../interfaces/IMarketConfigAdditional.sol";
import "../interfaces/IMarketController.sol";
import "../interfaces/IMarketHandler.sol";
import "../interfaces/ISaleBuilder.sol";
import "../interfaces/ISaleHandler.sol";
import "../interfaces/ISaleRunner.sol";
import "../interfaces/ISaleEnder.sol";
import "../interfaces/ISeenHausNFT.sol";
import "../interfaces/IEthCreditRecovery.sol";

/**
 * @title Interface Info
 *
 * @notice Allows us to read/verify the interface ids supported by the Seen.Haus
 * contract suite.
 *
 * When you need to add a new interface and find out what its ERC165 interfaceId is,
 * Add it to this contract, and add a unit test for it, which will fail, telling you
 * the actual interface id. Then update the supported-interfaces.js file with the id
 * of the new interface. This way, should an interface change, say adding a new method,
 * the InterfaceInfoTest.js test suite will fail, reminding you to update the interface
 * id in the constants file.
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract InterfaceInfo {

    function getIAuctionBuilder()
    public pure
    returns(bytes4 id) {
        id = type(IAuctionBuilder).interfaceId;
    }

    function getIAuctionHandler()
    public pure
    returns(bytes4 id) {
        id = type(IAuctionBuilder).interfaceId ^ type(IAuctionRunner).interfaceId;
    }

    function getIAuctionRunner()
    public pure
    returns(bytes4 id) {
        id = type(IAuctionRunner).interfaceId;
    }

    function getIAuctionEnder()
    public pure
    returns(bytes4 id) {
        id = type(IAuctionEnder).interfaceId;
    }

    function getIEthCreditRecovery()
    public pure
    returns(bytes4 id) {
        id = type(IEthCreditRecovery).interfaceId;
    }

    function getIDiamondCut()
    public pure
    returns(bytes4 id) {
        id = type(IDiamondCut).interfaceId;
    }

    function getIDiamondLoupe()
    public pure
    returns(bytes4 id) {
        id = type(IDiamondLoupe).interfaceId;
    }

    function getIEscrowTicketer()
    public pure
    returns(bytes4 id) {
        id = type(IEscrowTicketer).interfaceId;
    }

    function getIMarketClientProxy()
    public pure
    returns(bytes4 id) {
        id = type(IMarketClientProxy).interfaceId;
    }

    function getIMarketClerk()
    public pure
    returns(bytes4 id) {
        id = type(IMarketClerk).interfaceId;
    }

    function getIMarketConfig()
    public pure
    returns(bytes4 id) {
        id = type(IMarketConfig).interfaceId;
    }

    function getIMarketConfigAdditional()
    public pure
    returns(bytes4 id) {
        id = type(IMarketConfigAdditional).interfaceId;
    }

    function getIMarketController()
    public pure
    returns(bytes4 id) {
        id = type(IMarketConfig).interfaceId ^ type(IMarketClerk).interfaceId;
    }

    function getISaleBuilder()
    public pure
    returns(bytes4 id) {
        id = type(ISaleBuilder).interfaceId;
    }

    function getISaleHandler()
    public pure
    returns(bytes4 id) {
        id = type(ISaleBuilder).interfaceId ^ type(ISaleRunner).interfaceId;
    }

    function getISaleRunner()
    public pure
    returns(bytes4 id) {
        id = type(ISaleRunner).interfaceId;
    }

    function getISaleEnder()
    public pure
    returns(bytes4 id) {
        id = type(ISaleEnder).interfaceId;
    }

    function getISeenHausNFT()
    public pure
    returns(bytes4 id) {
        id = type(ISeenHausNFT).interfaceId;
    }

    function getIERC1155Receiver()
    public pure
    returns(bytes4 id) {
        id = type(IERC1155ReceiverUpgradeable).interfaceId;
    }

    function getIERC721Receiver()
    public pure
    returns(bytes4 id) {
        id = type(IERC721ReceiverUpgradeable).interfaceId;
    }

    function getIERC2981()
    public pure
    returns(bytes4 id) {
        id = type(IERC2981).interfaceId;
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../domain/SeenTypes.sol";
import "./IMarketHandler.sol";

/**
 * @title IAuctionBuilder
 *
 * @notice Handles the creation of Seen.Haus auctions.
 *
 * The ERC-165 identifier for this interface is: 0xb147a90b
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
interface IAuctionBuilder is IMarketHandler {

    // Events
    event AuctionPending(address indexed consignor, address indexed seller, SeenTypes.Auction auction);

    /**
     * @notice The auction getter
     */
    function getAuction(uint256 _consignmentId) external view returns (SeenTypes.Auction memory);

    /**
     * @notice Create a new primary market auction. (English style)
     *
     * Emits an AuctionPending event
     *
     * Reverts if:
     *  - Consignment doesn't exist
     *  - Consignment has already been marketed
     *  - Auction already exists for consignment
     *  - Start time is in the past
     *
     * @param _consignmentId - the id of the consignment being sold
     * @param _start - the scheduled start time of the auction
     * @param _duration - the scheduled duration of the auction
     * @param _reserve - the reserve price of the auction
     * @param _audience - the initial audience that can participate. See {SeenTypes.Audience}
     * @param _clock - the type of clock used for the auction. See {SeenTypes.Clock}
     */
    function createPrimaryAuction (
        uint256 _consignmentId,
        uint256 _start,
        uint256 _duration,
        uint256 _reserve,
        SeenTypes.Audience _audience,
        SeenTypes.Clock _clock
    ) external;

    /**
     * @notice Create a new secondary market auction
     *
     * Emits an AuctionPending event.
     *
     * Reverts if:
     *  - Contract no approved to transfer seller's tokens
     *  - Seller doesn't own the token balance to be auctioned
     *  - Start time is in the past
     *
     * @param _seller - the current owner of the consignment
     * @param _tokenAddress - the contract address issuing the NFT behind the consignment
     * @param _tokenId - the id of the token being consigned
     * @param _start - the scheduled start time of the auction
     * @param _duration - the scheduled duration of the auction
     * @param _reserve - the reserve price of the auction
     * @param _audience - the initial audience that can participate. See {SeenTypes.Audience}
     * @param _clock - the type of clock used for the auction. See {SeenTypes.Clock}
     */
    function createSecondaryAuction (
        address payable _seller,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _start,
        uint256 _duration,
        uint256 _reserve,
        SeenTypes.Audience _audience,
        SeenTypes.Clock _clock
    ) external;

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../domain/SeenTypes.sol";
import "./IMarketHandler.sol";
import "./IAuctionBuilder.sol";
import "./IAuctionRunner.sol";
import "./IAuctionEnder.sol";


/**
 * @title IAuctionHandler
 *
 * @notice Handles the creation, running, and disposition of Seen.Haus auctions.
 *
 * The ERC-165 identifier for this interface is: 0xa8190853
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
interface IAuctionHandler is IAuctionBuilder, IAuctionRunner, IAuctionEnder {

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../domain/SeenTypes.sol";
import "./IMarketHandler.sol";

/**
 * @title IAuctionRunner
 *
 * @notice Handles the operation of Seen.Haus auctions.
 *
 * The ERC-165 identifier for this interface is: 0x195ea158
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
interface IAuctionRunner is IMarketHandler {

    // Events
    event AuctionStarted(uint256 indexed consignmentId);
    event AuctionExtended(uint256 indexed consignmentId);
    event BidAccepted(uint256 indexed consignmentId, address indexed buyer, uint256 bid);
    event BidReturned(uint256 indexed consignmentId, address indexed buyer, uint256 bid);

    /**
     * @notice Change the audience for a auction.
     *
     * Reverts if:
     *  - Caller does not have ADMIN role
     *  - Auction doesn't exist or has already been settled
     *
     * @param _consignmentId - the id of the consignment being sold
     * @param _audience - the new audience for the auction
     */
    function changeAuctionAudience(uint256 _consignmentId, SeenTypes.Audience _audience) external;

    /**
     * @notice Bid on an active auction.
     *
     * If successful, the bidder's payment will be held and accepted as the standing bid.
     *
     * Reverts if:
     *  - Caller is not in audience
     *  - Caller is a contract
     *  - Auction doesn't exist or hasn't started
     *  - Auction timer has elapsed
     *  - Bid is below the reserve price
     *  - Bid is less than the outbid percentage above the standing bid, if one exists
     *
     * Emits a BidAccepted event on success.
     * May emit a AuctionStarted event, on the first bid.
     * May emit a AuctionExtended event, on bids placed in the last 15 minutes
     *
     * @param _consignmentId - the id of the consignment being sold
     */
    function bid(uint256 _consignmentId) external payable;

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../domain/SeenTypes.sol";
import "./IMarketHandler.sol";

/**
 * @title IAuctionEnder
 *
 * @notice Handles the operation of Seen.Haus auctions.
 *
 * The ERC-165 identifier for this interface is: 0xb5db7fa6
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
interface IAuctionEnder is IMarketHandler {

    // Events
    event AuctionEnded(uint256 indexed consignmentId, SeenTypes.Outcome indexed outcome);
    event CanceledAuctionBidReturned(uint256 indexed consignmentId, address indexed buyer, uint256 indexed bid);
    event TokenHistoryTracker(address indexed tokenAddress, uint256 indexed tokenId, address indexed buyer, uint256 value, uint256 amount, uint256 consignmentId);

    /**
     * @notice Close out a successfully completed auction.
     *
     * Funds are disbursed as normal. See {MarketHandlerBase.disburseFunds}
     *
     * Reverts if:
     *  - Auction doesn't exist
     *  - Auction timer has not yet elapsed
     *  - Auction has not yet started
     *  - Auction has already been settled
     *  - Bids have been placed
     *
     * Emits a AuctionEnded event on success.
     *
     * @param _consignmentId - the id of the consignment being sold
     */
    function closeAuction(uint256 _consignmentId) external;

    /**
     * @notice Cancel an auction that hasn't ended yet.
     *
     * If there is a standing bid, it is returned to the bidder.
     * Consigned inventory will be transferred back to the seller.
     *
     * Reverts if:
     *  - Caller does not have ADMIN role
     *  - Auction doesn't exist
     *  - Auction has already been settled
     *
     * Emits a AuctionEnded event on success.
     *
     * @param _consignmentId - the id of the consignment being sold
     */
    function cancelAuction(uint256 _consignmentId) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IDiamondLoupe
 *
 * @notice Diamond Facet inspection
 *
 * Reference Implementation  : https://github.com/mudgen/diamond-2-hardhat
 * EIP-2535 Diamond Standard : https://eips.ethereum.org/EIPS/eip-2535
 *
 * The ERC-165 identifier for this interface is: 0x48e2b093
 *
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 */
interface IDiamondLoupe {

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IAccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import { IMarketController } from "./IMarketController.sol";

/**
 * @title IMarketClientProxy
 *
 * @notice Allows upgrading the implementation, market controller, and access controller
 * of a MarketClientProxy
 *
 * The ERC-165 identifier for this interface is: 0x9bc69c79
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
interface IMarketClientProxy {

    // Events
    event Upgraded(address indexed implementation);
    event MarketControllerAddressChanged(address indexed marketController);
    event AccessControllerAddressChanged(address indexed accessController);

    /**
     * @dev Set the implementation address
     */
    function setImplementation(address _implementation) external;

    /**
     * @dev Get the implementation address
     */
    function getImplementation() external view returns (address);

    /**
     * @notice Set the Seen.Haus AccessController
     *
     * Emits an AccessControllerAddressChanged event.
     *
     * @param _accessController - the Seen.Haus AccessController address
     */
    function setAccessController(address _accessController) external;

    /**
     * @notice Gets the address of the Seen.Haus AccessController contract.
     *
     * @return the address of the AccessController contract
     */
    function getAccessController() external view returns (IAccessControlUpgradeable);

    /**
     * @notice Set the Seen.Haus MarketController
     *
     * Emits an MarketControllerAddressChanged event.
     *
     * @param _marketController - the Seen.Haus MarketController address
     */
    function setMarketController(address _marketController) external;

    /**
     * @notice Gets the address of the Seen.Haus MarketController contract.
     *
     * @return the address of the MarketController contract
     */
    function getMarketController() external view returns(IMarketController);

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../domain/SeenTypes.sol";
import "./IMarketHandler.sol";

/**
 * @title ISaleBuilder
 *
 * @notice Handles the creation of Seen.Haus sales.
 *
 * The ERC-165 identifier for this interface is: 0x4811411a
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
interface ISaleBuilder is IMarketHandler {

    // Events
    event SalePending(address indexed consignor, address indexed seller, SeenTypes.Sale sale);

    /**
     * @notice The sale getter
     */
    function getSale(uint256 _consignmentId) external view returns (SeenTypes.Sale memory);

    /**
     * @notice Create a new sale.
     *
     * For some lot size of one ERC-1155 token.
     *
     * Ownership of the consigned inventory is transferred to this contract
     * for the duration of the sale.
     *
     * Reverts if:
     *  - Sale exists for consignment
     *  - Consignment has already been marketed
     *  - Sale start is zero
     *
     * Emits a SalePending event.
     *
     * @param _consignmentId - id of the consignment being sold
     * @param _start - the scheduled start time of the sale
     * @param _price - the price of each item in the lot
     * @param _perTxCap - the maximum amount that can be bought in a single transaction
     * @param _audience - the initial audience that can participate. See {SeenTypes.Audience}
     */
    function createPrimarySale (
        uint256 _consignmentId,
        uint256 _start,
        uint256 _price,
        uint256 _perTxCap,
        SeenTypes.Audience _audience
    ) external;

    /**
     * @notice Create a new sale.
     *
     * For some lot size of one ERC-1155 token.
     *
     * Ownership of the consigned inventory is transferred to this contract
     * for the duration of the sale.
     *
     * Reverts if:
     *  - Sale exists for consignment
     *  - Sale start is zero
     *  - This contract isn't approved to transfer seller's tokens
     *
     * Emits a SalePending event.
     *
     * @param _seller - the current owner of the consignment
     * @param _tokenAddress - the contract address issuing the NFT behind the consignment
     * @param _tokenId - the id of the token being consigned
     * @param _start - the scheduled start time of the sale
     * @param _supply - the supply of the given consigned token being sold
     * @param _price - the price of each item in the lot
     * @param _perTxCap - the maximum amount that can be bought in a single transaction
     * @param _audience - the initial audience that can participate. See {SeenTypes.Audience}
     */
    function createSecondarySale (
        address payable _seller,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _start,
        uint256 _supply,
        uint256 _price,
        uint256 _perTxCap,
        SeenTypes.Audience _audience
    ) external;

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/ISaleBuilder.sol";
import "../interfaces/ISaleRunner.sol";
import "../interfaces/ISaleEnder.sol";

/**
 * @title ISaleHandler
 *
 * @notice Handles the creation, running, and disposition of Seen.Haus sales.
 *
 * The ERC-165 identifier for this interface is: 0xa9ae54df
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
interface ISaleHandler is ISaleBuilder, ISaleRunner, ISaleEnder {}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../domain/SeenTypes.sol";
import "./IMarketHandler.sol";

/**
 * @title ISaleEnder
 *
 * @notice Handles the finalization of Seen.Haus sales.
 *
 * The ERC-165 identifier for this interface is: 0x19b68d56
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
interface ISaleEnder is IMarketHandler {

    // Events
    event SaleEnded(uint256 indexed consignmentId, SeenTypes.Outcome indexed outcome);

    /**
     * @notice Close out a successfully completed sale.
     *
     * Funds are disbursed as normal. See: {MarketHandlerBase.disburseFunds}
     *
     * Reverts if:
     * - Sale doesn't exist or hasn't started
     * - There is remaining inventory
     *
     * Emits a SaleEnded event.
     *
     * @param _consignmentId - id of the consignment being sold
     */
    function closeSale(uint256 _consignmentId) external;

    /**
     * @notice Cancel a sale that has remaining inventory.
     *
     * Remaining tokens are returned to seller. If there have been any purchases,
     * the funds are distributed normally.
     *
     * Reverts if:
     * - Caller doesn't have ADMIN role
     * - Sale doesn't exist or has already been settled
     *
     * Emits a SaleEnded event
     *
     * @param _consignmentId - id of the consignment being sold
     */
    function cancelSale(uint256 _consignmentId) external;

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title IEthCreditRecovery
 *
 * @notice Handles the operation of Seen.Haus auctions.
 *
 * The ERC-165 identifier for this interface is: 0x78a6c477
 *
 */
interface IEthCreditRecovery {

    // Events
    event EthCreditRecovered(address indexed creditAddress, uint256 amount);
    event EthCreditFallbackRecovered(address indexed creditAddress, uint256 amount, address indexed admin, address indexed multisig);
    
    /**
     * @notice Enables recovery of any ETH credit to an account which has credits
     *
     * See: {MarketHandlerBase.sendValueOrCreditAccount}
     *
     * Credits are not specific to auctions (i.e. any sale credits would be distributed by this function too)
     *
     * Reverts if:
     * - Account has no ETH credits
     * - ETH cannot be sent to creditted account
     *
     * @param _recipient - address to distribute credits for
     */
    function recoverEthCredits(address _recipient) external;

    /**
     * @notice Enables admin recovery of any ETH credit for an account which has credits but can't recover the ETH via distributeEthCredits
     *
     * In rare cases, `_originalRecipient` may be unable to start receiving ETH again
     * therefore any ETH credits would get stuck
     *
     * See: {MarketHandlerBase.sendValueOrCreditAccount} & {EthCreditFacet.distributeEthCredits}
     *
     * Reverts if:
     * - Account has no ETH credits
     * - ETH cannot be sent to creditted account
     *
     * @param _originalRecipient - the account with unrecoverable (via distributeEthCredits) ETH credits
     */
    function fallbackRecoverEthCredit(address _originalRecipient) external;

    /**
     * @notice returns the pending ETH credits for a recipient
     *
     * @param _recipient - the account to check ETH credits for
     */
    function availableCredits(address _recipient) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/IAuctionRunner.sol";
import "../interfaces/IEthCreditRecovery.sol";

/**
 * @title FallbackRevert
 *
 * @notice Can bid on an auction but will revert on ETH transfers (e.g. bid return on outbid)
 *
 */
contract FallbackRevert {

    bool public revertOnReceive;

    constructor() {
      revertOnReceive = true;
    }

    function setShouldRevert(bool _shouldRevert) external {
      revertOnReceive = _shouldRevert;
    }

    function bidOnAuction(address _marketDiamond, uint256 _consignmentId) external payable {
      IAuctionRunner auction = IAuctionRunner(_marketDiamond);
      auction.bid{value: msg.value}(_consignmentId);
    }

    fallback() external payable {
      if(revertOnReceive) {
        require(msg.value <= 0, "reverting");
      }
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "../../../interfaces/IEscrowTicketer.sol";
import "../../../interfaces/IAuctionRunner.sol";
import "../../../interfaces/ISeenHausNFT.sol";
import "../MarketHandlerBase.sol";

/**
 * @title AuctionOperatorFacet
 *
 * @notice Handles the operation of Seen.Haus auctions.
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract AuctionRunnerFacet is IAuctionRunner, MarketHandlerBase {

    // Threshold to auction extension window
    uint256 constant public extensionWindow = 15 minutes;

    /**
     * @dev Modifier to protect initializer function from being invoked twice.
     */
    modifier onlyUnInitialized()
    {

        MarketHandlerLib.MarketHandlerInitializers storage mhi = MarketHandlerLib.marketHandlerInitializers();
        require(!mhi.auctionRunnerFacet, "Initializer: contract is already initialized");
        mhi.auctionRunnerFacet = true;
        _;
    }

    /**
     * @notice Facet Initializer
     *
     * Register supported interfaces
     */
    function initialize()
    public
    onlyUnInitialized
    {
        DiamondLib.addSupportedInterface(type(IAuctionRunner).interfaceId);
    }

    /**
     * @notice Change the audience for a auction.
     *
     * Reverts if:
     *  - Caller does not have ADMIN role
     *  - Auction doesn't exist or has already been settled
     *
     * @param _consignmentId - the id of the consignment being sold
     * @param _audience - the new audience for the auction
     */
    function changeAuctionAudience(uint256 _consignmentId, Audience _audience)
    external
    override
    onlyRole(ADMIN)
    {
        // Get Market Handler Storage struct
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();

        // Get consignment (reverting if not valid)
        Consignment memory consignment = getMarketController().getConsignment(_consignmentId);

        // Make sure the auction exists and hasn't been settled
        Auction storage auction = mhs.auctions[consignment.id];
        require(auction.start != 0, "Auction does not exist");
        require(auction.state != State.Ended, "Auction has already been settled");

        // Set the new audience for the consignment
        setAudience(consignment.id, _audience);

    }

    /**
     * @notice Bid on an active auction.
     *
     * If successful, the bidder's payment will be held and accepted as the standing bid.
     *
     * Reverts if:
     *  - Caller is not in audience
     *  - Caller is a contract
     *  - Auction doesn't exist or hasn't started
     *  - Auction timer has elapsed
     *  - Bid is below the reserve price
     *  - Bid is less than the outbid percentage above the standing bid, if one exists
     *
     * Emits a BidAccepted event on success.
     * May emit a AuctionStarted event, on the first bid.
     * May emit a AuctionExtended event, on bids placed in the last 15 minutes
     *
     * @param _consignmentId - the id of the consignment being sold
     */
    function bid(uint256 _consignmentId)
    external
    override
    payable
    onlyAudienceMember(_consignmentId)
    {
        // Get Market Handler Storage slot
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();

        // Get the consignment (reverting if consignment doesn't exist)
        Consignment memory consignment = getMarketController().getConsignment(_consignmentId);

        // Make sure the auction exists
        Auction memory auction = mhs.auctions[consignment.id];
        require(auction.start != 0, "Auction does not exist");

        // Determine time after which no more bids will be accepted
        uint256 endTime = auction.start + auction.duration;

        // Make sure we can accept the caller's bid
        require(block.timestamp >= auction.start, "Auction hasn't started");
        if ((auction.state != State.Pending) || (auction.clock != Clock.Trigger)) {
            require(block.timestamp <= endTime, "Auction timer has elapsed");
        }
        require(msg.value >= auction.reserve, "Bid below reserve price");

        // Store current required refund values in memory
        uint256 previousBid = auction.bid;
        address payable previousBidder = payable(auction.buyer);

        // Record the new bid
        auction.bid = msg.value;
        auction.buyer = payable(msg.sender);
        getMarketController().setConsignmentPendingPayout(consignment.id, msg.value);

        // If this was the first successful bid...
        if (auction.state == State.Pending) {

            // First bid updates auction state to Running
            auction.state = State.Running;

            // For auctions where clock is triggered by first bid, update start time
            if (auction.clock == Clock.Trigger) {

                // Set start time
                auction.start = block.timestamp;

            }

            // Notify listeners of state change
            emit AuctionStarted(consignment.id);

        } else {

            // Should not apply to first bid
            // For bids placed within the extension window
            // Extend the duration so that auction still lasts for the length of the extension window
            if ((block.timestamp + extensionWindow) >= endTime) {
                auction.duration += (extensionWindow - (endTime - block.timestamp));
                emit AuctionExtended(_consignmentId);
            }

        }

        mhs.auctions[_consignmentId] = auction;

        // If a standing bid exists:
        // - Be sure new bid outbids previous
        // - Give back the previous bidder's money
        if (previousBid > 0) {
            require(msg.value >= (previousBid + getPercentageOf(previousBid, getMarketController().getOutBidPercentage())), "Bid too small");
            sendValueOrCreditAccount(previousBidder, previousBid);
            emit BidReturned(consignment.id, previousBidder, previousBid);
        }

        // Announce the bid
        emit BidAccepted(_consignmentId, auction.buyer, auction.bid);

    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "../../../interfaces/IEscrowTicketer.sol";
import "../../../interfaces/ISeenHausNFT.sol";
import "../../../interfaces/ISaleEnder.sol";
import "../MarketHandlerBase.sol";

/**
 * @title SaleEnderFacet
 *
 * @notice Handles the operation of Seen.Haus sales.
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract SaleEnderFacet is ISaleEnder, MarketHandlerBase {

    // Threshold to auction extension window
    uint256 constant extensionWindow = 15 minutes;

    /**
     * @dev Modifier to protect initializer function from being invoked twice.
     */
    modifier onlyUnInitialized()
    {
        MarketHandlerLib.MarketHandlerInitializers storage mhi = MarketHandlerLib.marketHandlerInitializers();
        require(!mhi.saleEnderFacet, "Initializer: contract is already initialized");
        mhi.saleEnderFacet = true;
        _;
    }

    /**
     * @notice Facet Initializer
     *
     * Register supported interfaces
     */
    function initialize()
    public
    onlyUnInitialized
    {
        DiamondLib.addSupportedInterface(type(ISaleEnder).interfaceId);
    }

    /**
     * @notice Close out a successfully completed sale.
     *
     * Funds are disbursed as normal. See: {MarketHandlerBase.disburseFunds}
     *
     * Reverts if:
     * - Sale doesn't exist or hasn't started
     * - There is remaining inventory (remaining supply in case of digital, remaining tickets in the case of physical)
     *
     * Emits a SaleEnded event.
     *
     * @param _consignmentId - id of the consignment being sold
     */
    function closeSale(uint256 _consignmentId)
    external
    override
    {
        // Get Market Handler Storage slot
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();

        // Get consignment
        Consignment memory consignment = getMarketController().getConsignment(_consignmentId);

        // Make sure the sale exists and can be closed normally
        Sale storage sale = mhs.sales[_consignmentId];
        require(sale.start != 0, "Sale does not exist");
        require(sale.state == State.Running, "Sale isn't currently running");

        // Determine if consignment is physical
        address nft = getMarketController().getNft();
        if (nft == consignment.tokenAddress && ISeenHausNFT(nft).isPhysical(consignment.tokenId)) {

            // Check how many total claims are possible against issued tickets
            address escrowTicketer = getMarketController().getEscrowTicketer(_consignmentId);
            uint256 totalTicketClaimsIssued = IEscrowTicketer(escrowTicketer).getTicketClaimableCount(_consignmentId);

            // Ensure that sale is sold out before allowing closure
            require((consignment.supply - totalTicketClaimsIssued) == 0, "Sale cannot be closed with remaining inventory");

        } else {

            // Ensure that sale is sold out before allowing closure
            require((consignment.supply - consignment.releasedSupply) == 0, "Sale cannot be closed with remaining inventory");   

        }

        // Mark sale as settled
        sale.state = State.Ended;
        sale.outcome = Outcome.Closed;

        // Distribute the funds (handles royalties, staking, multisig, and seller)
        // First nullify pending payout in case of re-entrancy
        getMarketController().setConsignmentPendingPayout(consignment.id, 0);
        disburseFunds(_consignmentId, consignment.pendingPayout);

        // Notify listeners about state change
        emit SaleEnded(_consignmentId, sale.outcome);

    }

    /**
     * @notice Cancel a sale that has remaining inventory.
     *
     * Remaining tokens are returned to seller. If there have been any purchases,
     * the funds are distributed normally.
     *
     * Reverts if:
     * - Caller doesn't have ADMIN role
     * - Sale doesn't exist or has already been settled
     *
     * Emits a SaleEnded event
     *
     * @param _consignmentId - id of the consignment being sold
     */
    function cancelSale(uint256 _consignmentId)
    external
    override
    onlyRoleOrConsignor(ADMIN, _consignmentId)
    {
        // Get Market Handler Storage slot
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();

        // Get the consignment
        Consignment memory consignment = getMarketController().getConsignment(_consignmentId);

        // Make sure the sale exists and can canceled
        Sale storage sale = mhs.sales[_consignmentId];
        require(sale.start != 0, "Sale does not exist");
        require(sale.state != State.Ended, "Sale has already been settled");

        // Mark sale as settled
        sale.state = State.Ended;
        sale.outcome = Outcome.Canceled;

        // Determine the amount sold and remaining
        // uint256 remaining = getMarketController().getUnreleasedSupply(_consignmentId);
        // uint256 sold = consignment.supply - remaining;

        uint256 sold;
        uint256 remaining;
        // Determine if consignment is physical
        address nft = getMarketController().getNft();
        if (nft == consignment.tokenAddress && ISeenHausNFT(nft).isPhysical(consignment.tokenId)) {

            // Check how many total claims are possible against issued tickets
            address escrowTicketer = getMarketController().getEscrowTicketer(_consignmentId);
            uint256 totalTicketClaimsIssued = IEscrowTicketer(escrowTicketer).getTicketClaimableCount(_consignmentId);

            // Derive sold & remaining counts
            sold = totalTicketClaimsIssued;
            remaining = consignment.supply - totalTicketClaimsIssued;

        } else {

            // Derive sold & remaining counts
            sold = consignment.releasedSupply;
            remaining = consignment.supply - consignment.releasedSupply;

        }

        // Disburse the funds for the sold items
        if (sold > 0) {
            // First nullify pending payout in case of re-entrancy
            getMarketController().setConsignmentPendingPayout(consignment.id, 0);
            disburseFunds(_consignmentId, consignment.pendingPayout);
        }

        if (remaining > 0) {

            // Transfer the remaining supply back to the seller (for physicals: excludes NFTs that have tickets issued for them)
            getMarketController().releaseConsignment(_consignmentId, remaining, consignment.seller);

        }

        // Notify listeners about state change
        emit SaleEnded(_consignmentId, sale.outcome);

    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "../../../interfaces/IEscrowTicketer.sol";
import "../../../interfaces/ISaleBuilder.sol";
import "../../../interfaces/ISaleHandler.sol";
import "../../../interfaces/ISaleRunner.sol";
import "../../../interfaces/ISeenHausNFT.sol";
import "../MarketHandlerBase.sol";

/**
 * @title SaleBuilderFacet
 *
 * @notice Handles the operation of Seen.Haus sales.
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract SaleBuilderFacet is ISaleBuilder, MarketHandlerBase {

    /**
     * @dev Modifier to protect initializer function from being invoked twice.
     */
    modifier onlyUnInitialized()
    {
        MarketHandlerLib.MarketHandlerInitializers storage mhi = MarketHandlerLib.marketHandlerInitializers();
        require(!mhi.saleBuilderFacet, "Initializer: contract is already initialized");
        mhi.saleBuilderFacet = true;
        _;
    }

    /**
     * @notice Facet Initializer
     *
     * Register supported interfaces
     */
    function initialize()
    public
    onlyUnInitialized
    {
        DiamondLib.addSupportedInterface(type(ISaleBuilder).interfaceId);  // when combined with ISaleRunner ...
        DiamondLib.addSupportedInterface(type(ISaleBuilder).interfaceId ^ type(ISaleRunner).interfaceId); // ... supports ISaleHandler
    }

    /**
     * @notice The sale getter
     */
    function getSale(uint256 _consignmentId)
    external
    override
    view
    returns (Sale memory)
    {
        // Get Market Handler Storage struct
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();

        // Return sale
        return mhs.sales[_consignmentId];
    }

    /**
     * @notice Create a new sale.
     *
     * For some lot size of one ERC-1155 token.
     *
     * Ownership of the consigned inventory is transferred to this contract
     * for the duration of the sale.
     *
     * Reverts if:
     *  - Sale start is zero
     *  - Sale exists for consignment
     *  - Consignment has already been marketed
     *
     * Emits a SalePending event.
     *
     * @param _consignmentId - id of the consignment being sold
     * @param _start - the scheduled start time of the sale
     * @param _price - the price of each item in the lot
     * @param _perTxCap - the maximum amount that can be bought in a single transaction
     * @param _audience - the initial audience that can participate. See {SeenTypes.Audience}
     */
    function createPrimarySale (
        uint256 _consignmentId,
        uint256 _start,
        uint256 _price,
        uint256 _perTxCap,
        Audience _audience
    )
    external
    override
    onlyRole(SELLER)
    onlyConsignor(_consignmentId)
    {
        require(_start > 0, "_start may not be zero");

        // Get Market Handler Storage slot
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();

        // Fetch the consignment
        Consignment memory consignment = getMarketController().getConsignment(_consignmentId);

        // Make sure the consignment hasn't been marketed
        require(consignment.marketHandler == MarketHandler.Unhandled, "Consignment has already been marketed");

        // Get the storage location for the sale
        Sale storage sale = mhs.sales[consignment.id];

        // Make sure sale doesn't exist (start would always be non-zero on an actual sale)
        require(sale.start == 0, "Sale exists");

        // Set up the sale
        setAudience(_consignmentId, _audience);
        sale.consignmentId = _consignmentId;
        sale.start = _start;
        sale.price = _price;
        sale.perTxCap = _perTxCap;
        sale.state = State.Pending;
        sale.outcome = Outcome.Pending;

        // Notify MarketController the consignment has been marketed
        getMarketController().marketConsignment(consignment.id, MarketHandler.Sale);

        // Notify listeners of state change
        emit SalePending(msg.sender, consignment.seller, sale);
    }

    /**
     * @notice Create a new sale.
     *
     * For some lot size of one ERC-1155 token.
     *
     * Ownership of the consigned inventory is transferred to this contract
     * for the duration of the sale.
     *
     * Reverts if:
     *  - Sale start is zero
     *  - Supply is zero
     *  - Sale exists for consignment
     *  - This contract isn't approved to transfer seller's tokens
     *  - Token contract does not implement either IERC1155 or IERC721
     *
     * Emits a SalePending event.
     *
     * @param _seller - the address that procedes of the sale should go to
     * @param _tokenAddress - the contract address issuing the NFT behind the consignment
     * @param _tokenId - the id of the token being consigned
     * @param _start - the scheduled start time of the sale
     * @param _supply - the supply of the given consigned token being sold
     * @param _price - the price of each item in the lot
     * @param _perTxCap - the maximum amount that can be bought in a single transaction
     * @param _audience - the initial audience that can participate. See {SeenTypes.Audience}
     */
    function createSecondarySale (
        address payable _seller,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _start,
        uint256 _supply,
        uint256 _price,
        uint256 _perTxCap,
        Audience _audience
    )
    external
    override
    {
        // Make sure sale start is not set to zero
        require(_start > 0, "_start may not be zero");

        // Get Market Handler Storage slot
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();

        // Get the MarketController
        IMarketController marketController = getMarketController();

        // Determine if consignment is physical
        address nft = marketController.getNft();
        if (nft == _tokenAddress && ISeenHausNFT(nft).isPhysical(_tokenId)) {
            // Is physical NFT, require that msg.sender has ESCROW_AGENT role
            require(checkHasRole(msg.sender, ESCROW_AGENT), "Physical NFT secondary listings require ESCROW_AGENT role");
        } else if (nft != _tokenAddress) {
            // Is external NFT, require that listing external NFTs is enabled
            bool isEnabled = marketController.getAllowExternalTokensOnSecondary();
            require(isEnabled, "Listing external tokens is not currently enabled");
        }

        // Make sure supply is non-zero
        require (_supply > 0, "Supply must be non-zero");

        // Make sure this contract is approved to transfer the token
        // N.B. The following will work because isApprovedForAll has the same signature on both IERC721 and IERC1155
        require(IERC1155Upgradeable(_tokenAddress).isApprovedForAll(msg.sender, address(this)), "Not approved to transfer seller's tokens");

        // To register the consignment, tokens must first be in MarketController's possession
        if (IERC165Upgradeable(_tokenAddress).supportsInterface(type(IERC1155Upgradeable).interfaceId)) {

            // Ensure seller owns sufficient supply of token
            require(IERC1155Upgradeable(_tokenAddress).balanceOf(msg.sender, _tokenId) >= _supply, "Seller has insufficient balance of token");

            // Transfer supply to MarketController
            IERC1155Upgradeable(_tokenAddress).safeTransferFrom(
                msg.sender,
                address(getMarketController()),
                _tokenId,
                _supply,
                new bytes(0x0)
            );

        } else {

            require(_supply == 1, "ERC721 listings must use a supply of 1");

            // Token must be a single token NFT
            require(IERC165Upgradeable(_tokenAddress).supportsInterface(type(IERC721Upgradeable).interfaceId), "Invalid token type");

            // Transfer tokenId to MarketController
            IERC721Upgradeable(_tokenAddress).safeTransferFrom(
                msg.sender,
                address(getMarketController()),
                _tokenId
            );

        }

        // Register consignment
        Consignment memory consignment = getMarketController().registerConsignment(Market.Secondary, msg.sender, _seller, _tokenAddress, _tokenId, _supply);
        // Secondaries are marketed directly after registration
        getMarketController().marketConsignment(consignment.id, MarketHandler.Sale);

        // Set up the sale
        setAudience(consignment.id, _audience);
        Sale storage sale = mhs.sales[consignment.id];
        sale.consignmentId = consignment.id;
        sale.start = _start;
        sale.price = _price;
        sale.perTxCap = _perTxCap;
        sale.state = State.Pending;
        sale.outcome = Outcome.Pending;

        // Notify listeners of state change
        emit SalePending(msg.sender, consignment.seller, sale);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "../../../interfaces/IAuctionHandler.sol";
import "../../../interfaces/IAuctionBuilder.sol";
import "../../../interfaces/IAuctionRunner.sol";
import "../../../interfaces/ISeenHausNFT.sol";
import "../MarketHandlerBase.sol";

/**
 * @title AuctionBuilderFacet
 *
 * @notice Handles the creation of Seen.Haus auctions.
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract AuctionBuilderFacet is IAuctionBuilder, MarketHandlerBase {

    // Threshold to auction extension window
    uint256 constant extensionWindow = 15 minutes;

    /**
     * @dev Modifier to protect initializer function from being invoked twice.
     */
    modifier onlyUnInitialized()
    {
        MarketHandlerLib.MarketHandlerInitializers storage mhi = MarketHandlerLib.marketHandlerInitializers();
        require(!mhi.auctionBuilderFacet, "Initializer: contract is already initialized");
        mhi.auctionBuilderFacet = true;
        _;
    }

    /**
     * @notice Facet Initializer
     *
     * Register supported interfaces
     */
    function initialize()
    public
    onlyUnInitialized
    {
        DiamondLib.addSupportedInterface(type(IAuctionBuilder).interfaceId);   // when combined with IAuctionRunner ...
        DiamondLib.addSupportedInterface(type(IAuctionBuilder).interfaceId ^ type(IAuctionRunner).interfaceId);  // ... supports IAuctionHandler
    }

    /**
     * @notice The auction getter
     */
    function getAuction(uint256 _consignmentId)
    external
    view
    override
    returns (Auction memory)
    {

        // Get Market Handler Storage struct
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();

        // Return the auction
        return mhs.auctions[_consignmentId];
    }

    /**
     * @notice Create a new primary market auction. (English style)
     *
     * Emits an AuctionPending event
     *
     * Reverts if:
     *  - Consignment doesn't exist
     *  - Consignment has already been marketed
     *  - Consignment has a supply other than 1
     *  - Auction already exists for consignment
     *  - Duration is less than 15 minutes
     *
     * @param _consignmentId - the id of the consignment being sold
     * @param _start - the scheduled start time of the auction
     * @param _duration - the scheduled duration of the auction
     * @param _reserve - the reserve price of the auction
     * @param _audience - the initial audience that can participate. See {SeenTypes.Audience}
     * @param _clock - the type of clock used for the auction. See {SeenTypes.Clock}
     */
    function createPrimaryAuction (
        uint256 _consignmentId,
        uint256 _start,
        uint256 _duration,
        uint256 _reserve,
        Audience _audience,
        Clock _clock
    )
    external
    override
    onlyRole(SELLER)
    onlyConsignor(_consignmentId)
    {
        require(_duration >= extensionWindow, "Duration must be equal to or longer than 15 minutes");

        // Get Market Handler Storage struct
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();

        // Get the consignment (reverting if consignment doesn't exist)
        Consignment memory consignment = getMarketController().getConsignment(_consignmentId);

        // For auctions, ensure that the consignment supply is 1 (we don't facilitate a single auction for multiple tokens)
        require(consignment.supply == 1, "Auctions can only be made with consignments that have a supply of 1");

        // Make sure the consignment hasn't been marketed
        require(consignment.marketHandler == MarketHandler.Unhandled, "Consignment has already been marketed");

        // Get the storage location for the auction
        Auction storage auction = mhs.auctions[consignment.id];

        // Make sure auction doesn't exist (start would always be non-zero on an actual auction)
        require(auction.start == 0, "Auction exists");

        // Make sure start time isn't in the past if the clock type is not trigger type
        // It doesn't matter if the start is in the past if clock type is trigger type
        // Because when the first bid comes in, that gets set to the start time anyway
        if(_clock != Clock.Trigger) {
            require(_start >= block.timestamp, "Non-trigger clock type requires start time in future");
        } else {
            require(_start > 0, "Start time must be more than zero");
        }

        // Set up the auction
        setAudience(_consignmentId, _audience);
        auction.consignmentId = consignment.id;
        auction.start = _start;
        auction.duration = _duration;
        auction.reserve = _reserve;
        auction.clock = _clock;
        auction.state = State.Pending;
        auction.outcome = Outcome.Pending;

        // Notify MarketController the consignment has been marketed
        getMarketController().marketConsignment(consignment.id, MarketHandler.Auction);

        // Notify listeners of state change
        emit AuctionPending(msg.sender, consignment.seller, auction);
    }

    /**
     * @notice Create a new secondary market auction
     *
     * Emits an AuctionPending event.
     *
     * Reverts if:
     *  - This contract not approved to transfer seller's tokens
     *  - Seller doesn't own the asset(s) to be auctioned
     *  - Token contract does not implement either IERC1155 or IERC721
     *  - Duration is less than 15 minutes
     *
     * @param _seller - the address that proceeds of the auction should go to
     * @param _tokenAddress - the contract address issuing the NFT behind the consignment
     * @param _tokenId - the id of the token being consigned
     * @param _start - the scheduled start time of the auction
     * @param _duration - the scheduled duration of the auction
     * @param _reserve - the reserve price of the auction
     * @param _audience - the initial audience that can participate. See {SeenTypes.Audience}
     * @param _clock - the type of clock used for the auction. See {SeenTypes.Clock}
     */
    function createSecondaryAuction (
        address payable _seller,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _start,
        uint256 _duration,
        uint256 _reserve,
        Audience _audience,
        Clock _clock
    )
    external
    override
    {
        require(_duration >= extensionWindow, "Duration must be equal to or longer than 15 minutes");

        // Get Market Handler Storage struct
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();

        // Get the MarketController
        IMarketController marketController = getMarketController();

        // Determine if consignment is physical
        address nft = marketController.getNft();
        if (nft == _tokenAddress && ISeenHausNFT(nft).isPhysical(_tokenId)) {
            // Is physical NFT, require that msg.sender has ESCROW_AGENT role
            require(checkHasRole(msg.sender, ESCROW_AGENT), "Physical NFT secondary listings require ESCROW_AGENT role");
        } else if (nft != _tokenAddress) {
            // Is external NFT, require that listing external NFTs is enabled
            require(marketController.getAllowExternalTokensOnSecondary(), "Listing external tokens is not currently enabled");
        }

        // Make sure start time isn't in the past if the clock type is not trigger type
        // It doesn't matter if the start is in the past if clock type is trigger type
        // Because when the first bid comes in, that gets set to the start time anyway
        if(_clock != Clock.Trigger) {
            require(_start >= block.timestamp, "Non-trigger clock type requires start time in future");
        } else {
            require(_start > 0, "Start time must be more than zero");
        }

        // Make sure this contract is approved to transfer the token
        // N.B. The following will work because isApprovedForAll has the same signature on both IERC721 and IERC1155
        require(IERC1155Upgradeable(_tokenAddress).isApprovedForAll(msg.sender, address(this)), "Not approved to transfer seller's tokens");

        // To register the consignment, tokens must first be in MarketController's possession
        if (IERC165Upgradeable(_tokenAddress).supportsInterface(type(IERC1155Upgradeable).interfaceId)) {

            // Ensure seller a positive number of tokens
            require(IERC1155Upgradeable(_tokenAddress).balanceOf(msg.sender, _tokenId) > 0, "Seller has zero balance of consigned token");

            // Transfer supply to MarketController
            IERC1155Upgradeable(_tokenAddress).safeTransferFrom(
                msg.sender,
                address(getMarketController()),
                _tokenId,
                1, // Supply is always 1 for auction
                new bytes(0x0)
            );

        } else {

            // Token must be a single token NFT
            require(IERC165Upgradeable(_tokenAddress).supportsInterface(type(IERC721Upgradeable).interfaceId), "Invalid token type");

            // Transfer tokenId to MarketController
            IERC721Upgradeable(_tokenAddress).safeTransferFrom(
                msg.sender,
                address(getMarketController()),
                _tokenId
            );

        }

        // Register consignment
        Consignment memory consignment = getMarketController().registerConsignment(Market.Secondary, msg.sender, _seller, _tokenAddress, _tokenId, 1);
        // Secondaries are marketed directly after registration
        getMarketController().marketConsignment(consignment.id, MarketHandler.Auction);

        // Set up the auction
        setAudience(consignment.id, _audience);
        Auction storage auction = mhs.auctions[consignment.id];
        auction.consignmentId = consignment.id;
        auction.start = _start;
        auction.duration = _duration;
        auction.reserve = _reserve;
        auction.clock = _clock;
        auction.state = State.Pending;
        auction.outcome = Outcome.Pending;

        // Notify listeners of state change
        emit AuctionPending(msg.sender, consignment.seller, auction);

    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../domain/SeenTypes.sol";

/**
 * @title TestFacetLib
 *
 * @dev A library to test diamond storage
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
library TestFacetLib {

    bytes32 constant TEST_FACET_STORAGE_POSITION = keccak256("diamond.test.facet.storage");

    struct TestFacetStorage {

        // a test address
        address testAddress;

        // facet initialization state
        bool initialized;

    }

    function testFacetStorage() internal pure returns (TestFacetStorage storage tfs) {
        bytes32 position = TEST_FACET_STORAGE_POSITION;
        assembly {
            tfs.slot := position
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AddressUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import { TestFacetLib } from "./TestFacetLib.sol";

/**
 * @title Test3Facet
 *
 * @notice Contract for testing initializeable facets and diamond storage
 *
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract Test3Facet {
    
    modifier onlyUnInitialized() {
        TestFacetLib.TestFacetStorage storage tfs = TestFacetLib.testFacetStorage();
        require(!tfs.initialized, "Initializer: contract is already initialized");
        tfs.initialized = true;
        _;
    }

    function initialize(address _testAddress) public onlyUnInitialized {
        // for testing revert with reason
        require(!AddressUpgradeable.isContract(_testAddress), "Address cannot be a contract");

        // For testing no reason reverts
        require(_testAddress != address(msg.sender));

        TestFacetLib.TestFacetStorage storage tfs = TestFacetLib.testFacetStorage();
        tfs.testAddress = _testAddress;
    }

    function isInitialized() public view returns (bool) {
        TestFacetLib.TestFacetStorage storage tfs = TestFacetLib.testFacetStorage();
        return tfs.initialized;
    }

    function getTestAddress() external view returns (address) {
        TestFacetLib.TestFacetStorage storage tfs = TestFacetLib.testFacetStorage();
        return tfs.testAddress;
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "../../../interfaces/IEscrowTicketer.sol";
import "../../../interfaces/IAuctionEnder.sol";
import "../../../interfaces/ISeenHausNFT.sol";
import "../MarketHandlerBase.sol";

/**
 * @title AuctionEnderFacet
 *
 * @notice Handles the operation of Seen.Haus auctions.
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract AuctionEnderFacet is IAuctionEnder, MarketHandlerBase {

    // Threshold to auction extension window
    uint256 constant extensionWindow = 15 minutes;

    /**
     * @dev Modifier to protect initializer function from being invoked twice.
     */
    modifier onlyUnInitialized()
    {

        MarketHandlerLib.MarketHandlerInitializers storage mhi = MarketHandlerLib.marketHandlerInitializers();
        require(!mhi.auctionEnderFacet, "Initializer: contract is already initialized");
        mhi.auctionEnderFacet = true;
        _;
    }

    /**
     * @notice Facet Initializer
     *
     * Register supported interfaces
     */
    function initialize()
    public
    onlyUnInitialized
    {
        DiamondLib.addSupportedInterface(type(IAuctionEnder).interfaceId);
    }

    /**
     * @notice Close out a successfully completed auction.
     *
     * Funds are disbursed as normal. See {MarketHandlerBase.disburseFunds}
     *
     * Reverts if:
     *  - Auction doesn't exist
     *  - Auction timer has not yet elapsed
     *  - Auction has not yet started
     *  - Auction has already been settled
     *  - Bids have been placed
     *
     * Emits a AuctionEnded event on success.
     *
     * @param _consignmentId - the id of the consignment being sold
     */
    function closeAuction(uint256 _consignmentId)
    external
    override
    {
        // Get Market Handler Storage slot
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();

        // Get the consignment (reverting if consignment doesn't exist)
        Consignment memory consignment = getMarketController().getConsignment(_consignmentId);

        // Make sure the auction exists
        Auction storage auction = mhs.auctions[_consignmentId];
        require(auction.start != 0, "Auction does not exist");

        // Make sure timer has elapsed
        uint256 endTime = auction.start + auction.duration;
        require(block.timestamp > endTime, "Auction end time not yet reached");

        // Make sure auction hasn't been settled
        require(auction.outcome == Outcome.Pending, "Auction has already been settled");

        // Make sure it there was at least one bid
        require(auction.buyer != address(0), "No bids have been placed");

        // Mark auction as settled
        auction.state = State.Ended;
        auction.outcome = Outcome.Closed;

        // Distribute the funds (pay royalties, staking, multisig, and seller)
        getMarketController().setConsignmentPendingPayout(consignment.id, 0);
        disburseFunds(_consignmentId, consignment.pendingPayout);

        // Determine if consignment is physical
        address nft = getMarketController().getNft();
        if (nft == consignment.tokenAddress && ISeenHausNFT(nft).isPhysical(consignment.tokenId)) {

            // For physicals, issue an escrow ticket to the buyer
            address escrowTicketer = getMarketController().getEscrowTicketer(_consignmentId);
            IEscrowTicketer(escrowTicketer).issueTicket(_consignmentId, 1, auction.buyer);

        } else {

            // Release the purchased amount of the consigned token supply to buyer
            getMarketController().releaseConsignment(_consignmentId, 1, auction.buyer);

        }

        // Notify listeners about state change
        emit AuctionEnded(consignment.id, auction.outcome);

        // Track the winning bid info against the token itself
        emit TokenHistoryTracker(consignment.tokenAddress, consignment.tokenId, auction.buyer, auction.bid, consignment.supply, consignment.id);

    }    

    /**
     * @notice Cancel an auction
     *
     * If there is a standing bid, it is returned to the bidder.
     * Consigned inventory will be transferred back to the seller.
     *
     * Reverts if:
     *  - Caller does not have ADMIN role or is not consignor
     *  - Auction doesn't exist
     *  - Auction has already been settled
     *
     * Emits a AuctionEnded event on success.
     *
     * @param _consignmentId - the id of the consignment being sold
     */
    function cancelAuction(uint256 _consignmentId)
    external
    override
    onlyRoleOrConsignor(ADMIN, _consignmentId)
    {
        // Get Market Handler Storage slot
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();

        // Get the consignment (reverting if consignment doesn't exist)
        Consignment memory consignment = getMarketController().getConsignment(_consignmentId);

        // Make sure auction exists
        Auction storage auction = mhs.auctions[_consignmentId];
        require(auction.start != 0, "Auction does not exist");

        // Make sure auction hasn't been settled
        require(auction.state != State.Ended, "Auction has already been settled");

        // Mark auction as settled
        auction.state = State.Ended;
        auction.outcome = Outcome.Canceled;

        getMarketController().setConsignmentPendingPayout(consignment.id, 0);

        // Give back the previous bidder's money
        if (auction.bid > 0) {
            sendValueOrCreditAccount(auction.buyer, auction.bid);
            emit CanceledAuctionBidReturned(_consignmentId, auction.buyer, auction.bid);
        }

        // Release the consigned token supply to seller
        getMarketController().releaseConsignment(_consignmentId, 1, consignment.seller);

        // Notify listeners about state change
        emit AuctionEnded(_consignmentId, auction.outcome);

    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "../../../interfaces/IEscrowTicketer.sol";
import "../../../interfaces/ISeenHausNFT.sol";
import "../../../util/StringUtils.sol";
import "../MarketClientBase.sol";
import "./LotsTicketerStorage.sol";

/**
 * @title LotsTicketer
 *
 * @notice An escrow ticketer contract implemented with ERC-721.
 *
 * Holders of this ticket have the right to transfer or claim a
 * given number of a physical consignment, escrowed by Seen.Haus.
 *
 * Since this is an ERC721 implementation, the holder must
 * claim, sell, or transfer the entire lot of the ticketed
 * items at once.
 *
 * N.B.: This contract disincentivizes whale behavior, e.g., a person
 * scooping up a bunch of the available items in a multi-edition
 * sale must flip or claim them all at once, not individually.
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract LotsTicketer is LotsTicketerStorage, IEscrowTicketer, MarketClientBase, StringUtils, ERC721Upgradeable {

    /**
     * @notice Initializer
     */
    function initialize() external {
        __ERC721_init(NAME, SYMBOL);
    }

    /**
     * @notice The getNextTicket getter
     * @dev does not increment counter
     */
    function getNextTicket()
    external
    view
    override
    returns (uint256)
    {
        return nextTicket;
    }

    /**
     * @notice Get info about the ticket
     */
    function getTicket(uint256 ticketId)
    external
    view
    override
    returns (EscrowTicket memory)
    {
        require(_exists(ticketId), "Ticket does not exist");
        return tickets[ticketId];
    }

    /**
     * @notice Get how many claims can be made using tickets (does not change after ticket burns)
     */
    function getTicketClaimableCount(uint256 _consignmentId)
    external
    view
    override
    returns (uint256)
    {
        return consignmentIdToTicketClaimableCount[_consignmentId];
    }

    /**
     * @notice Gets the URI for the ticket metadata
     *
     * IEscrowTicketer method that normalizes how you get the URI,
     * since ERC721 and ERC1155 differ in approach.
     *
     * @param _ticketId - the token id of the ticket
     */
    function getTicketURI(uint256 _ticketId)
    external
    pure
    override
    returns (string memory)
    {
        return tokenURI(_ticketId);
    }

    /**
     * @notice Get the token URI
     *
     * This method is overrides the Open Zeppelin version, returning
     * a unique endpoint address on the seen.haus site for each token id.
     *
     * ex: tokenId = 12
     * https://seen.haus/ticket/metadata/lots-ticketer/12
     *
     * Tickets are transient and will be burned when claimed to obtain
     * proof of ownership NFTs with their metadata on IPFS as usual.
     *
     * Endpoint should serve metadata with fixed name, description,
     * and image, identifying it as a Seen.Haus Escrow Ticket, and
     * adding these fields, in OpenSea attributes format:
     *
     *  - ticketId
     *  - consignmentId
     *  - tokenAddress
     *  - tokenId
     *  - supply
     *
     * @param _tokenId - the ticket's token id
     * @return tokenURI - the URI for the given token id's metadata
     */
    function tokenURI(uint256 _tokenId)
    public
    pure
    override
    returns (string memory)
    {
        return strConcat(_baseURI(), uintToStr(_tokenId));
    }

    /**
     * @dev Base URI for computing {tokenURI}.
     */
    function _baseURI()
    internal
    pure
    override
    returns (string memory)
    {
        return strConcat(ESCROW_TICKET_URI, "lots-ticketer/");
    }

    /**
     * Mint an escrow ticket
     *
     * @param _consignmentId - the id of the consignment being sold
     * @param _amount - the amount of the given token to escrow
     * @param _buyer - the buyer of the escrowed item(s) to whom the ticket is issued
     */
    function issueTicket(uint256 _consignmentId, uint256 _amount, address payable _buyer)
    external
    override
    onlyRole(MARKET_HANDLER)
    {
        // Get the MarketController
        IMarketController marketController = getMarketController();

        // Fetch consignment (reverting if consignment doesn't exist)
        Consignment memory consignment = marketController.getConsignment(_consignmentId);

        // Make sure amount is non-zero
        require(_amount > 0, "Token amount cannot be zero.");

        consignmentIdToTicketClaimableCount[_consignmentId] += _amount;

        // Make sure that there can't be more tickets issued than the maximum possible consignment allocation
        require(consignmentIdToTicketClaimableCount[_consignmentId] <= consignment.supply, "Can't issue more tickets than max possible allowed consignment");

        // Get the ticketed token
        Token memory token = ISeenHausNFT(consignment.tokenAddress).getTokenInfo(consignment.tokenId);

        // Create and store escrow ticket
        uint256 ticketId = nextTicket++;
        EscrowTicket storage ticket = tickets[ticketId];
        ticket.amount = _amount;
        ticket.consignmentId = _consignmentId;
        ticket.id = ticketId;
        ticket.itemURI = token.uri;

        // Mint the ticket and send to the buyer
        _mint(_buyer, ticketId);

        // Notify listeners about state change
        emit TicketIssued(ticketId, _consignmentId, _buyer, _amount);
    }

    /**
      * Claim the escrowed items associated with the ticket.
      *
      * @param _ticketId - the ticket representing the escrowed items
      */
    function claim(uint256 _ticketId)
    external
    override
    {
        require(_exists(_ticketId), "Invalid ticket id");
        require(ownerOf(_ticketId) == msg.sender, "Caller not ticket holder");

        // Get the MarketController
        IMarketController marketController = getMarketController();

        // Get the ticket
        EscrowTicket memory ticket = tickets[_ticketId];

        // Burn the ticket
        _burn(_ticketId);
        delete tickets[_ticketId];

        // Release the consignment to claimant
        marketController.releaseConsignment(ticket.consignmentId, ticket.amount, msg.sender);

        // Notify listeners of state change
        emit TicketClaimed(_ticketId, msg.sender, ticket.amount);

    }

    /**
     * @notice Implementation of the {IERC165} interface.
     *
     * N.B. This method is inherited from several parents and
     * the compiler cannot decide which to use. Thus, they must
     * be overridden here.
     *
     * if you just call super.supportsInterface, it chooses
     * 'the most derived contract'. But that's not good for this
     * particular function because you may inherit from several
     * IERC165 contracts, and all concrete ones need to be allowed
     * to respond.
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721Upgradeable)
    returns (bool)
    {
        return (
            interfaceId == type(IEscrowTicketer).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    uint256[44] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title String Utils
 *
 * Functions for converting numbers to strings and concatenating strings.
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract StringUtils {

    /**
     * @notice Convert a `uint` value to a `string`
     * via OraclizeAPI - MIT licence
     * https://github.com/provable-things/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol#L896
     * @param _i the `uint` value to be converted
     * @return result the `string` representation of the given `uint` value
     */
    function uintToStr(uint _i)
    public pure
    returns (string memory result) {
        unchecked {
            if (_i == 0) {
                return "0";
            }
            uint j = _i;
            uint len;
            while (j != 0) {
                len++;
                j /= 10;
            }
            bytes memory bstr = new bytes(len);
            uint k = len - 1;
            while (_i != 0) {
                bstr[k--] = bytes1(uint8(48 + _i % 10));
                _i /= 10;
            }
            result = string(bstr);
        }
    }

    /**
     * @notice Concatenate two strings
     * @param _a the first string
     * @param _b the second string
     * @return result the concatenation of `_a` and `_b`
     */
    function strConcat(string memory _a, string memory _b)
    public pure
    returns(string memory result) {
        result = string(abi.encodePacked(bytes(_a), bytes(_b)));
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../../interfaces/IMarketController.sol";
import "../../domain/SeenConstants.sol";
import "../../domain/SeenTypes.sol";
import "./MarketClientLib.sol";


/**
 * @title MarketClientBase
 *
 * @notice Extended by Seen.Haus contracts that need to communicate with the
 * MarketController, but are NOT facets of the MarketDiamond.
 *
 * Market client contracts include SeenHausNFT, ItemsTicketer, and LotsTicketer
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
abstract contract MarketClientBase is SeenTypes, SeenConstants {

    /**
     * @dev Modifier that checks that the caller has a specific role.
     *
     * Reverts if caller doesn't have role.
     *
     * See: {AccessController.hasRole}
     */
    modifier onlyRole(bytes32 role) {
        require(MarketClientLib.hasRole(role), "Caller doesn't have role");
        _;
    }

    /**
     * @notice Get the MarketController from the MarketClientProxy's storage
     *
     * @return IMarketController address
     */
    function getMarketController()
    internal
    pure
    returns (IMarketController)
    {
        MarketClientLib.ProxyStorage memory ps = MarketClientLib.proxyStorage();
        return ps.marketController;
    }

    /**
     * @notice Get a percentage of a given amount.
     *
     * N.B. Represent ercentage values are stored
     * as unsigned integers, the result of multiplying the given percentage by 100:
     * e.g, 1.75% = 175, 100% = 10000
     *
     * @param _amount - the amount to return a percentage of
     * @param _percentage - the percentage value represented as above
     */
    function getPercentageOf(uint256 _amount, uint16 _percentage)
    internal
    pure
    returns (uint256 share)
    {
        share = _amount * _percentage / 10000;
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../../../domain/SeenTypes.sol";

/**
 * @title LotsTicketerStorage
 * @notice Splits storage away from the logic in LotsTicketer.sol for maintainability
 */
contract LotsTicketerStorage is SeenTypes {

    // Ticket ID => Ticket
    mapping (uint256 => EscrowTicket) internal tickets;

    // Consignment ID => Ticket Claimable Count (does not change after ticket burns)
    mapping (uint256 => uint256) internal consignmentIdToTicketClaimableCount;

    /// @dev Next ticket number
    uint256 internal nextTicket;

    string public constant NAME = "Seen.Haus Escrowed Lot Ticket";
    string public constant SYMBOL = "ESCROW_TICKET";

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "../../interfaces/IMarketController.sol";

/**
 * @title MarketClientLib
 *
 * Maintains the implementation address and the access and market controller addresses.
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
library MarketClientLib {

    struct ProxyStorage {

        // The Seen.Haus AccessController address
        IAccessControlUpgradeable accessController;

        // The Seen.Haus MarketController address
        IMarketController marketController;

        // The implementation address
        address implementation;
    }

    /**
     * @dev Storage slot with the address of the Seen.Haus AccessController
     * This is obviously not a standard EIP-1967 slot.
     */
    bytes32 internal constant PROXY_SLOT = keccak256('Seen.Haus.MarketClientProxy');

    /**
     * @notice Get the Proxy storage slot
     *
     * @return ps - Proxy storage slot cast to ProxyStorage
     */
    function proxyStorage() internal pure returns (ProxyStorage storage ps) {
        bytes32 position = PROXY_SLOT;
        assembly {
            ps.slot := position
        }
    }

    /**
     * @dev Checks that the caller has a specific role.
     *
     * Reverts if caller doesn't have role.
     *
     * See: {AccessController.hasRole}
     */
    function hasRole(bytes32 role) internal view returns (bool) {
        ProxyStorage storage ps = proxyStorage();
        return ps.accessController.hasRole(role, msg.sender);
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "../../../interfaces/IEscrowTicketer.sol";
import "../../../interfaces/ISeenHausNFT.sol";
import "../../../util/StringUtils.sol";
import "../MarketClientBase.sol";
import "./ItemsTicketerStorage.sol";

/**
 * @title ItemsTicketer
 *
 * @notice An IEscrowTicketer contract implemented with ERC-1155.
 *
 * Holders of this style of ticket have the right to transfer or
 * claim a given number of a physical consignment, escrowed by
 * Seen.Haus.
 *
 * Since this is an ERC155 implementation, the holder can
 * sell / transfer part or all of the balance of their ticketed
 * items rather than claim them all.
 *
 * N.B.: This contract supports piece-level reseller behavior,
 * e.g., an entity scooping up a bunch of the available items
 * in a multi-edition sale with the purpose of flipping each
 * item individually to make maximum profit.
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract ItemsTicketer is ItemsTicketerStorage, StringUtils, IEscrowTicketer, MarketClientBase, ERC1155Upgradeable {

    /**
     * @notice Initializer
     */
    function initialize()
    public {
        __ERC1155_init(ESCROW_TICKET_URI);
    }

    /**
     * @notice The getNextTicket getter
     * @dev does not increment counter
     */
    function getNextTicket()
    external
    view
    override
    returns (uint256)
    {
        return nextTicket;
    }

    /**
     * @notice Get info about the ticket
     */
    function getTicket(uint256 _ticketId)
    external
    view
    override
    returns (EscrowTicket memory)
    {
        require(_ticketId < nextTicket, "Ticket does not exist");
        return tickets[_ticketId];
    }

    /**
     * @notice Get how many claims can be made using tickets (does not change after ticket burns)
     */
    function getTicketClaimableCount(uint256 _consignmentId)
    external
    view
    override
    returns (uint256)
    {
        return consignmentIdToTicketClaimableCount[_consignmentId];
    }

    /**
     * @notice Gets the URI for the ticket metadata
     *
     * IEscrowTicketer method that normalizes how you get the URI,
     * since ERC721 and ERC1155 differ in approach.
     *
     * @param _ticketId - the token id of the ticket
     */
    function getTicketURI(uint256 _ticketId)
    external
    pure
    override
    returns (string memory)
    {
        return uri(_ticketId);
    }

    /**
     * @notice Get the token URI
     *
     * ex: tokenId = 12
     * https://seen.haus/ticket/metadata/items-ticketer/12
     *
     * @param _tokenId - the ticket's token id
     * @return tokenURI - the URI for the given token id's metadata
     */
    function uri(uint256 _tokenId)
    public
    pure
    override
    returns (string memory)
    {
        string memory base = strConcat(ESCROW_TICKET_URI,  "items-ticketer/");
        return strConcat(base, uintToStr(_tokenId));
    }

    /**
     * Issue an escrow ticket to the buyer
     *
     * For physical consignments, Seen.Haus must hold the items in escrow
     * until the buyer(s) claim them.
     *
     * When a buyer wins an auction or makes a purchase in a sale, the market
     * handler contract they interacted with will call this method to issue an
     * escrow ticket, which is an NFT that can be sold, transferred, or claimed.
     *
     * Reverts if token amount hasn't already been transferred to this contract
     *
     * @param _consignmentId - the id of the consignment being sold
     * @param _amount - the amount of the given token to escrow
     * @param _buyer - the buyer of the escrowed item(s) to whom the ticket is issued
     */
    function issueTicket(uint256 _consignmentId, uint256 _amount, address payable _buyer)
    external
    override
    onlyRole(MARKET_HANDLER)
    {
        // Get the MarketController
        IMarketController marketController = getMarketController();

        // Fetch consignment (reverting if consignment doesn't exist)
        Consignment memory consignment = marketController.getConsignment(_consignmentId);

        // Make sure amount is non-zero
        require(_amount > 0, "Token amount cannot be zero.");

        consignmentIdToTicketClaimableCount[_consignmentId] += _amount;

        // Make sure that there can't be more tickets issued than the maximum possible consignment allocation
        require(consignmentIdToTicketClaimableCount[_consignmentId] <= consignment.supply, "Can't issue more tickets than max possible allowed for consignment");

        // Get the ticketed token
        Token memory token = ISeenHausNFT(consignment.tokenAddress).getTokenInfo(consignment.tokenId);

        // Create and store escrow ticket
        uint256 ticketId = nextTicket++;
        EscrowTicket storage ticket = tickets[ticketId];
        ticket.amount = _amount;
        ticket.consignmentId = _consignmentId;
        ticket.id = ticketId;
        ticket.itemURI = token.uri;

        // Mint escrow ticket and send to buyer
        _mint(_buyer, ticketId, _amount, new bytes(0x0));

        // Notify listeners about state change
        emit TicketIssued(ticketId, _consignmentId, _buyer, _amount);

    }

    /**
     * Claim escrowed items associated with the ticket.
     *
     * @param _ticketId - the ticket representing the escrowed item(s)
     */
    function claim(uint256 _ticketId) external override
    {
        // Get the MarketController
        IMarketController marketController = getMarketController();

        // Make sure the ticket exists
        EscrowTicket memory ticket = tickets[_ticketId];
        require(ticket.id == _ticketId, "Ticket does not exist");

        uint256 amount = balanceOf(msg.sender, _ticketId);
        require(amount > 0, "Caller has no balance for this ticket");

        // Burn the caller's balance
        _burn(msg.sender, _ticketId, amount);

        // Reduce the ticket's amount by the claim amount
        ticket.amount -= amount;

        // When entire supply is claimed and burned, delete the ticket structure
        if (ticket.amount == 0) {
            delete tickets[_ticketId];
        } else {
            tickets[_ticketId] = ticket;
        }

        // Release the consignment to claimant
        marketController.releaseConsignment(ticket.consignmentId, amount, msg.sender);

        // Notify listeners of state change
        emit TicketClaimed(_ticketId, msg.sender, amount);

    }

    /**
     * @notice Implementation of the {IERC165} interface.
     *
     * N.B. This method is inherited from several parents and
     * the compiler cannot decide which to use. Thus, they must
     * be overridden here.
     *
     * if you just call super.supportsInterface, it chooses
     * 'the most derived contract'. But that's not good for this
     * particular function because you may inherit from several
     * IERC165 contracts, and all concrete ones need to be allowed
     * to respond.
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC1155Upgradeable)
    returns (bool)
    {
        return (
            interfaceId == type(IEscrowTicketer).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal initializer {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
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

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
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

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
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
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
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
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
    uint256[47] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../../../domain/SeenTypes.sol";

/**
 * @title ItemsTicketerStorage
 * @notice Splits storage away from the logic in ItemsTicketer.sol for maintainability
 *
 */
contract ItemsTicketerStorage is SeenTypes {

    // Ticket ID => Ticket
    mapping (uint256 => EscrowTicket) internal tickets;
    
    // Consignment ID => Ticket Claimable Count (does not change after ticket burns)
    mapping (uint256 => uint256) internal consignmentIdToTicketClaimableCount;

    /// @dev Next ticket number
    uint256 internal nextTicket;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "../interfaces/IERC2981.sol";

/**
 * @title Foreign1155
 *
 * @notice Mock ERC-(1155/2981) NFT for Unit Testing
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract Foreign1155 is IERC2981, ERC1155Upgradeable {

    mapping(uint256 => address) public creators;
    mapping(uint256 => uint256) public royaltyPercentage;

    /**
     * Mint a Sample NFT
     * @param _creator - the address that will own the token and get royalties
     * @param _tokenId - the token ID to mint an amount of
     * @param _amount - the amount of tokens to mint
     * @param _royaltyPercentage - the percentage of royalty expected on secondary market sales
     */
    function mint(address _creator, uint256 _tokenId, uint256 _amount, uint256 _royaltyPercentage) public {
        creators[_tokenId] = _creator;
        royaltyPercentage[_tokenId] = _royaltyPercentage;
        _mint(_creator, _tokenId, _amount, "");
    }

    /**
     * @notice Get royalty info for a token
     *
     * For a given token id and sale price, how much should be sent to whom as royalty
     *
     * @param _tokenId - the NFT asset queried for royalty information
     * @param _salePrice - the sale price of the NFT asset specified by _tokenId
     *
     * @return _receiver - address of who should be sent the royalty payment
     * @return _royaltyAmount - the royalty payment amount for _value sale price
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external view override
    returns (address _receiver, uint256 _royaltyAmount)
    {
        address creator = creators[_tokenId];
        uint256 percentage = royaltyPercentage[_tokenId];
        _receiver = creator;
        _royaltyAmount = _salePrice * percentage / 10000;
    }

    /**
     * @notice Implementation of the {IERC165} interface.
     *
     * N.B. This method is inherited from several parents and
     * the compiler cannot decide which to use. Thus, they must
     * be overridden here.
     *
     * if you just call super.supportsInterface, it chooses
     * 'the most derived contract'. But that's not good for this
     * particular function because you may inherit from several
     * IERC165 contracts, and all concrete ones need to be allowed
     * to respond.
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(IERC165Upgradeable, ERC1155Upgradeable)
    returns (bool)
    {
        return (
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "../interfaces/IERC2981.sol";

/**
 * @title Foreign721
 *
 * @notice Mock ERC-(721/2981) NFT for Unit Testing
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract Foreign721 is IERC2981, ERC721Upgradeable {

    string public constant TOKEN_NAME = "Foreign721";
    string public constant TOKEN_SYMBOL = "721Test";

    mapping(uint256 => address) public creators;
    mapping(uint256 => uint256) public royaltyPercentage;

    /**
     * @notice Get royalty info for a token
     *
     * For a given token id and sale price, how much should be sent to whom as royalty
     *
     * @param _tokenId - the NFT asset queried for royalty information
     * @param _salePrice - the sale price of the NFT asset specified by _tokenId
     *
     * @return _receiver - address of who should be sent the royalty payment
     * @return _royaltyAmount - the royalty payment amount for _value sale price
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external view override
    returns (address _receiver, uint256 _royaltyAmount)
    {
        address creator = creators[_tokenId];
        uint256 percentage = royaltyPercentage[_tokenId];
        _receiver = creator;
        _royaltyAmount = _salePrice * percentage / 10000;
    }

    /**
     * Mint a Sample NFT
     * @param _creator - the address that will own the token and get royalties
     * @param _tokenId - the token ID to mint
     * @param _royaltyPercentage - the percentage of royalty expected on secondary market sales
     */
    function mint(address _creator, uint256 _tokenId, uint256 _royaltyPercentage) public {
        creators[_tokenId] = _creator;
        royaltyPercentage[_tokenId] = _royaltyPercentage;
        _mint(_creator, _tokenId);
    }

    /**
     * @notice Implementation of the {IERC165} interface.
     *
     * N.B. This method is inherited from several parents and
     * the compiler cannot decide which to use. Thus, they must
     * be overridden here.
     *
     * if you just call super.supportsInterface, it chooses
     * 'the most derived contract'. But that's not good for this
     * particular function because you may inherit from several
     * IERC165 contracts, and all concrete ones need to be allowed
     * to respond.
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(IERC165Upgradeable, ERC721Upgradeable)
    returns (bool)
    {
        return (
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal initializer {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../../../interfaces/IMarketController.sol";
import "../../../interfaces/IMarketConfig.sol";
import "../../../interfaces/IMarketClerk.sol";
import "../../diamond/DiamondLib.sol";
import "../MarketControllerBase.sol";
import "../MarketControllerLib.sol";

/**
 * @title MarketConfigFacet
 *
 * @notice Provides centralized management of various market-related settings.
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract MarketConfigFacet is IMarketConfig, MarketControllerBase {

    /**
     * @dev Modifier to protect initializer function from being invoked twice.
     */
    modifier onlyUnInitialized()
    {
        MarketControllerLib.MarketControllerInitializers storage mci = MarketControllerLib.marketControllerInitializers();
        require(!mci.configFacet, "Initializer: contract is already initialized");
        mci.configFacet = true;
        _;
    }

    /**
     * @notice Facet Initializer
     *
     * @param _staking - Seen.Haus staking contract
     * @param _multisig - Seen.Haus multi-sig wallet
     * @param _vipStakerAmount - the minimum amount of xSEEN ERC-20 a caller must hold to participate in VIP events
     * @param _primaryFeePercentage - percentage that will be taken as a fee from the net of a Seen.Haus primary sale or auction
     * @param _secondaryFeePercentage - percentage that will be taken as a fee from the net of a Seen.Haus secondary sale or auction (after royalties)
     * @param _maxRoyaltyPercentage - maximum percentage of a Seen.Haus sale or auction that will be paid as a royalty
     * @param _outBidPercentage - minimum percentage a Seen.Haus auction bid must be above the previous bid to prevail
     * @param _defaultTicketerType - which ticketer type to use if none has been specified for a given consignment
     */
    function initialize(
        address payable _staking,
        address payable _multisig,
        uint256 _vipStakerAmount,
        uint16 _primaryFeePercentage,
        uint16 _secondaryFeePercentage,
        uint16 _maxRoyaltyPercentage,
        uint16 _outBidPercentage,
        Ticketer _defaultTicketerType
    )
    public
    onlyUnInitialized
    {
        // Register supported interfaces
        DiamondLib.addSupportedInterface(type(IMarketConfig).interfaceId);  // when combined with IMarketClerk ...
        DiamondLib.addSupportedInterface(type(IMarketConfig).interfaceId ^ type(IMarketClerk).interfaceId); // ... supports IMarketController

        // Initialize market config params
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        mcs.staking = _staking;
        mcs.multisig = _multisig;
        mcs.vipStakerAmount = _vipStakerAmount;
        mcs.primaryFeePercentage = _primaryFeePercentage;
        mcs.secondaryFeePercentage = _secondaryFeePercentage;
        mcs.maxRoyaltyPercentage = _maxRoyaltyPercentage;
        mcs.outBidPercentage = _outBidPercentage;
        mcs.defaultTicketerType = _defaultTicketerType;
    }

    /**
     * @notice Sets the address of the SEEN NFT contract.
     *
     * Emits a NFTAddressChanged event.
     *
     * @param _nft - the address of the nft contract
     */
    function setNft(address _nft)
    external
    override
    onlyRole(MULTISIG)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        mcs.nft = _nft;
        emit NFTAddressChanged(_nft);
    }

    /**
     * @notice The nft getter
     */
    function getNft()
    external
    override
    view
    returns (address)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        return mcs.nft;
    }

    /**
     * @notice Sets the address of the Seen.Haus lots-based escrow ticketer contract.
     *
     * Emits a EscrowTicketerAddressChanged event.
     *
     * @param _lotsTicketer - the address of the lots-based escrow ticketer contract
     */
    function setLotsTicketer(address _lotsTicketer)
    external
    override
    onlyRole(MULTISIG)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        mcs.lotsTicketer = _lotsTicketer;
        emit EscrowTicketerAddressChanged(mcs.lotsTicketer, Ticketer.Lots);
    }

    /**
     * @notice The lots-based escrow ticketer getter
     */
    function getLotsTicketer()
    external
    override
    view
    returns (address)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        return mcs.lotsTicketer;
    }

    /**
     * @notice Sets the address of the Seen.Haus items-based escrow ticketer contract.
     *
     * Emits a EscrowTicketerAddressChanged event.
     *
     * @param _itemsTicketer - the address of the items-based escrow ticketer contract
     */
    function setItemsTicketer(address _itemsTicketer)
    external
    override
    onlyRole(MULTISIG)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        mcs.itemsTicketer = _itemsTicketer;
        emit EscrowTicketerAddressChanged(mcs.itemsTicketer, Ticketer.Items);
    }

    /**
     * @notice The items-based ticketer getter
     */
    function getItemsTicketer()
    external
    override
    view
    returns (address)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        return mcs.itemsTicketer;
    }

    /**
     * @notice Sets the address of the xSEEN ERC-20 staking contract.
     *
     * Emits a StakingAddressChanged event.
     *
     * @param _staking - the address of the staking contract
     */
    function setStaking(address payable _staking)
    external
    override
    onlyRole(MULTISIG)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        mcs.staking = _staking;
        emit StakingAddressChanged(mcs.staking);
    }

    /**
     * @notice The staking getter
     */
    function getStaking()
    external
    override
    view
    returns (address payable)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        return mcs.staking;
    }

    /**
     * @notice Sets the address of the Seen.Haus multi-sig wallet.
     *
     * Emits a MultisigAddressChanged event.
     *
     * @param _multisig - the address of the multi-sig wallet
     */
    function setMultisig(address payable _multisig)
    external
    override
    onlyRole(MULTISIG)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        mcs.multisig = _multisig;
        emit MultisigAddressChanged(mcs.multisig);
    }

    /**
     * @notice The multisig getter
     */
    function getMultisig()
    external
    override
    view
    returns (address payable)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        return mcs.multisig;
    }

    /**
     * @notice Sets the VIP staker amount.
     *
     * Emits a VipStakerAmountChanged event.
     *
     * @param _vipStakerAmount - the minimum amount of xSEEN ERC-20 a caller must hold to participate in VIP events
     */
    function setVipStakerAmount(uint256 _vipStakerAmount)
    external
    override
    onlyRole(MULTISIG)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        mcs.vipStakerAmount = _vipStakerAmount;
        emit VipStakerAmountChanged(mcs.vipStakerAmount);
    }

    /**
     * @notice The vipStakerAmount getter
     */
    function getVipStakerAmount()
    external
    override
    view
    returns (uint256)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        return mcs.vipStakerAmount;
    }

    /**
     * @notice Sets the marketplace fee percentage.
     * Emits a PrimaryFeePercentageChanged event.
     *
     * @param _primaryFeePercentage - the percentage that will be taken as a fee from the net of a Seen.Haus primary sale or auction
     *
     * N.B. Represent percentage value as an unsigned int by multiplying the percentage by 100:
     * e.g, 1.75% = 175, 100% = 10000
     */
    function setPrimaryFeePercentage(uint16 _primaryFeePercentage)
    external
    override
    onlyRole(MULTISIG)
    {
        require(_primaryFeePercentage > 0 && _primaryFeePercentage <= 10000,
            "Percentage representation must be between 1 and 10000");
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        mcs.primaryFeePercentage = _primaryFeePercentage;
        emit PrimaryFeePercentageChanged(mcs.primaryFeePercentage);
    }

    /**
     * @notice Sets the marketplace fee percentage.
     * Emits a FeePercentageChanged event.
     *
     * @param _secondaryFeePercentage - the percentage that will be taken as a fee from the net of a Seen.Haus secondary sale or auction (after royalties)
     *
     * N.B. Represent percentage value as an unsigned int by multiplying the percentage by 100:
     * e.g, 1.75% = 175, 100% = 10000
     */
    function setSecondaryFeePercentage(uint16 _secondaryFeePercentage)
    external
    override
    onlyRole(MULTISIG)
    {
        require(_secondaryFeePercentage > 0 && _secondaryFeePercentage <= 10000,
            "Percentage representation must be between 1 and 10000");
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        mcs.secondaryFeePercentage = _secondaryFeePercentage;
        emit SecondaryFeePercentageChanged(mcs.secondaryFeePercentage);
    }

    /**
     * @notice The primaryFeePercentage and secondaryFeePercentage getter
     */
    function getFeePercentage(Market _market)
    external
    override
    view
    returns (uint16)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        if(_market == Market.Primary) {
            return mcs.primaryFeePercentage;
        } else {
            return mcs.secondaryFeePercentage;
        }
    }

    /**
     * @notice Sets the maximum royalty percentage the marketplace will pay.
     *
     * Emits a MaxRoyaltyPercentageChanged event.
     *
     * @param _maxRoyaltyPercentage - the maximum percentage of a Seen.Haus sale or auction that will be paid as a royalty
     *
     * N.B. Represent percentage value as an unsigned int by multiplying the percentage by 100:
     * e.g, 1.75% = 175, 100% = 10000
     */
    function setMaxRoyaltyPercentage(uint16 _maxRoyaltyPercentage)
    external
    override
    onlyRole(MULTISIG)
    {
        require(_maxRoyaltyPercentage > 0 && _maxRoyaltyPercentage <= 10000,
            "Percentage representation must be between 1 and 10000");
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        mcs.maxRoyaltyPercentage = _maxRoyaltyPercentage;
        emit MaxRoyaltyPercentageChanged(mcs.maxRoyaltyPercentage);
    }

    /**
     * @notice The maxRoyaltyPercentage getter
     */
    function getMaxRoyaltyPercentage()
    external
    override
    view
    returns (uint16)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        return mcs.maxRoyaltyPercentage;
    }

    /**
     * @notice Sets the marketplace auction outbid percentage.
     *
     * Emits a OutBidPercentageChanged event.
     *
     * @param _outBidPercentage - the minimum percentage a Seen.Haus auction bid must be above the previous bid to prevail
     *
     * N.B. Represent percentage value as an unsigned int by multiplying the percentage by 100:
     * e.g, 1.75% = 175, 100% = 10000
     */
    function setOutBidPercentage(uint16 _outBidPercentage)
    external
    override
    onlyRole(ADMIN)
    {
        require(_outBidPercentage > 0 && _outBidPercentage <= 10000,
            "Percentage representation must be between 1 and 10000");
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        mcs.outBidPercentage = _outBidPercentage;
        emit OutBidPercentageChanged(mcs.outBidPercentage);
    }

    /**
     * @notice The outBidPercentage getter
     */
    function getOutBidPercentage()
    external
    override
    view
    returns (uint16)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        return mcs.outBidPercentage;
    }

    /**
     * @notice Sets the default escrow ticketer type.
     *
     * Emits a DefaultTicketerTypeChanged event.
     *
     * Reverts if _ticketerType is Ticketer.Default
     * Reverts if _ticketerType is already the defaultTicketerType
     *
     * @param _ticketerType - the new default escrow ticketer type.
     */
    function setDefaultTicketerType(Ticketer _ticketerType)
    external
    override
    onlyRole(ADMIN)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        require(_ticketerType != Ticketer.Default, "Invalid ticketer type.");
        require(_ticketerType != mcs.defaultTicketerType, "Type is already default.");
        mcs.defaultTicketerType = _ticketerType;
        emit DefaultTicketerTypeChanged(mcs.defaultTicketerType);
    }

    /**
     * @notice The defaultTicketerType getter
     */
    function getDefaultTicketerType()
    external
    override
    view
    returns (Ticketer)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        return mcs.defaultTicketerType;
    }

    /**
     * @notice Get the Escrow Ticketer to be used for a given consignment
     *
     * If a specific ticketer has not been set for the consignment,
     * the default escrow ticketer will be returned.
     *
     * Reverts if consignment doesn't exist
     *     *
     * @param _consignmentId - the id of the consignment
     * @return ticketer = the address of the escrow ticketer to use
     */
    function getEscrowTicketer(uint256 _consignmentId)
    external
    override
    view
    consignmentExists(_consignmentId)
    returns (address)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        Ticketer specified = mcs.consignmentTicketers[_consignmentId];
        Ticketer ticketerType = (specified == Ticketer.Default) ? mcs.defaultTicketerType : specified;
        return (ticketerType == Ticketer.Lots) ? mcs.lotsTicketer : mcs.itemsTicketer;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./MarketControllerLib.sol";
import "../diamond/DiamondLib.sol";
import "../../domain/SeenTypes.sol";
import "../../domain/SeenConstants.sol";

/**
 * @title MarketControllerBase
 *
 * @notice Provides domain and common modifiers to MarketController facets
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
abstract contract MarketControllerBase is SeenTypes, SeenConstants {

    /**
     * @dev Modifier that checks that the consignment exists
     *
     * Reverts if the consignment does not exist
     */
    modifier consignmentExists(uint256 _consignmentId) {

        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();

        // Make sure the consignment exists
        require(_consignmentId < mcs.nextConsignment, "Consignment does not exist");
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
        require(ds.accessController.hasRole(_role, msg.sender), "Caller doesn't have role");
        _;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../domain/SeenTypes.sol";

/**
 * @title MarketControllerLib
 *
 * @dev Provides access to the the MarketController Storage and Intializer slots for MarketController facets
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
library MarketControllerLib {

    bytes32 constant MARKET_CONTROLLER_STORAGE_POSITION = keccak256("seen.haus.market.controller.storage");
    bytes32 constant MARKET_CONTROLLER_INITIALIZERS_POSITION = keccak256("seen.haus.market.controller.initializers");

    struct MarketControllerStorage {

        // the address of the Seen.Haus NFT contract
        address nft;

        // the address of the xSEEN ERC-20 Seen.Haus staking contract
        address payable staking;

        // the address of the Seen.Haus multi-sig wallet
        address payable multisig;

        // address of the Seen.Haus lots-based escrow ticketing contract
        address lotsTicketer;

        // address of the Seen.Haus items-based escrow ticketing contract
        address itemsTicketer;

        // the default escrow ticketer type to use for physical consignments unless overridden with setConsignmentTicketer
        SeenTypes.Ticketer defaultTicketerType;

        // the minimum amount of xSEEN ERC-20 a caller must hold to participate in VIP events
        uint256 vipStakerAmount;

        // the percentage that will be taken as a fee from the net of a Seen.Haus sale or auction
        uint16 primaryFeePercentage;         // 1.75% = 175, 100% = 10000

        // the percentage that will be taken as a fee from the net of a Seen.Haus sale or auction (after royalties)
        uint16 secondaryFeePercentage;         // 1.75% = 175, 100% = 10000

        // the maximum percentage of a Seen.Haus sale or auction that will be paid as a royalty
        uint16 maxRoyaltyPercentage;  // 1.75% = 175, 100% = 10000

        // the minimum percentage a Seen.Haus auction bid must be above the previous bid to prevail
        uint16 outBidPercentage;      // 1.75% = 175, 100% = 10000

        // next consignment id
        uint256 nextConsignment;

        // whether or not external NFTs can be sold via secondary market
        bool allowExternalTokensOnSecondary;

        // consignment id => consignment
        mapping(uint256 => SeenTypes.Consignment) consignments;

        // consignmentId to consignor address
        mapping(uint256 => address) consignors;

        // consignment id => ticketer type
        mapping(uint256 => SeenTypes.Ticketer) consignmentTicketers;

        // escrow agent address => feeBasisPoints
        mapping(address => uint16) escrowAgentToFeeBasisPoints;

    }

    struct MarketControllerInitializers {

        // MarketConfigFacet initialization state
        bool configFacet;

        // MarketConfigFacet initialization state
        bool configAdditionalFacet;

        // MarketClerkFacet initialization state
        bool clerkFacet;

    }

    function marketControllerStorage() internal pure returns (MarketControllerStorage storage mcs) {
        bytes32 position = MARKET_CONTROLLER_STORAGE_POSITION;
        assembly {
            mcs.slot := position
        }
    }

    function marketControllerInitializers() internal pure returns (MarketControllerInitializers storage mci) {
        bytes32 position = MARKET_CONTROLLER_INITIALIZERS_POSITION;
        assembly {
            mci.slot := position
        }
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../../../interfaces/IMarketController.sol";
import "../../../interfaces/IMarketConfigAdditional.sol";
import "../../../interfaces/IMarketClerk.sol";
import "../../diamond/DiamondLib.sol";
import "../MarketControllerBase.sol";
import "../MarketControllerLib.sol";

/**
 * @title MarketConfigFacet
 *
 * @notice Provides centralized management of various market-related settings.
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract MarketConfigAdditionalFacet is IMarketConfigAdditional, MarketControllerBase {

    /**
     * @dev Modifier to protect initializer function from being invoked twice.
     */
    modifier onlyUnInitialized()
    {
        MarketControllerLib.MarketControllerInitializers storage mci = MarketControllerLib.marketControllerInitializers();
        require(!mci.configAdditionalFacet, "Initializer: contract is already initialized");
        mci.configAdditionalFacet = true;
        _;
    }

    /**
     * @notice Facet Initializer
     *
     * @param _allowExternalTokensOnSecondary - whether or not external tokens are allowed to be sold via secondary market
     */
    function initialize(
      bool _allowExternalTokensOnSecondary
    )
    public
    onlyUnInitialized
    {
        // Register supported interfaces
        DiamondLib.addSupportedInterface(type(IMarketConfigAdditional).interfaceId);  // when combined with IMarketClerk ...
        DiamondLib.addSupportedInterface(type(IMarketConfigAdditional).interfaceId ^ type(IMarketClerk).interfaceId); // ... supports IMarketController

        // Initialize market config params
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        mcs.allowExternalTokensOnSecondary = _allowExternalTokensOnSecondary;
    }

    /**
     * @notice Sets whether or not external tokens can be listed on secondary market
     *
     * Emits an AllowExternalTokensOnSecondaryChanged event.
     *
     * @param _status - boolean of whether or not external tokens are allowed
     */
    function setAllowExternalTokensOnSecondary(bool _status)
    external
    override
    onlyRole(MULTISIG)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        require(_status != mcs.allowExternalTokensOnSecondary, "Already set to requested status.");
        mcs.allowExternalTokensOnSecondary = _status;
        emit AllowExternalTokensOnSecondaryChanged(mcs.allowExternalTokensOnSecondary);
    }

    /**
     * @notice The allowExternalTokensOnSecondary getter
     */
    function getAllowExternalTokensOnSecondary()
    external
    override
    view
    returns (bool)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        return mcs.allowExternalTokensOnSecondary;
    }

    /**
     * @notice The escrow agent fee getter
     *
     * Returns zero if no escrow agent fee is set
     *
     * @param _escrowAgentAddress - the address of the escrow agent
     * @return uint256 - escrow agent fee in basis points
     */
    function getEscrowAgentFeeBasisPoints(address _escrowAgentAddress)
    public
    override
    view
    returns (uint16)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        return mcs.escrowAgentToFeeBasisPoints[_escrowAgentAddress];
    }

    /**
     * @notice The escrow agent fee setter
     *
     * Reverts if:
     * - _basisPoints are more than 5000 (50%)
     *
     * @param _escrowAgentAddress - the address of the escrow agent
     * @param _basisPoints - the escrow agent's fee in basis points
     */
    function setEscrowAgentFeeBasisPoints(address _escrowAgentAddress, uint16 _basisPoints)
    external
    override
    onlyRole(MULTISIG)
    {
        // Ensure the consignment exists, has not been released and that basis points don't exceed 5000 (50%)
        require(_basisPoints <= 5000, "_basisPoints over 5000");
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        mcs.escrowAgentToFeeBasisPoints[_escrowAgentAddress] = _basisPoints;
        emit EscrowAgentFeeChanged(_escrowAgentAddress, _basisPoints);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IAccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import { IMarketClientProxy } from "../../interfaces/IMarketClientProxy.sol";
import { IMarketController } from "../../interfaces/IMarketController.sol";
import { SeenConstants } from "../../domain/SeenConstants.sol";
import { MarketClientLib } from "./MarketClientLib.sol";
import { Proxy } from "./Proxy.sol";

/**
 * @title MarketClientProxy
 *
 * @notice Delegates calls to a market client implementation contract,
 * such that functions on it execute in the context (address, storage)
 * of this proxy, allowing the implementation contract to be upgraded
 * without losing the accumulated state data.
 *
 * Market clients are the contracts in the system that communicate with
 * the MarketController as clients of the MarketDiamond rather than acting
 * as facets of the MarketDiamond. They include SeenHausNFT, ItemsTicketer,
 * and LotsTicketer.
 *
 * Each Market Client contract will be deployed behind its own proxy for
 * future upgradability.
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract MarketClientProxy is IMarketClientProxy, SeenConstants, Proxy {

    /**
 * @dev Modifier that checks that the caller has a specific role.
 *
 * Reverts if caller doesn't have role.
 *
 * See: {AccessController.hasRole}
 */
    modifier onlyRole(bytes32 role) {
        require(MarketClientLib.hasRole(role), "Caller doesn't have role");
        _;
    }

    constructor(
        address _accessController,
        address _marketController,
        address _impl
    ) {

        // Get the ProxyStorage struct
        MarketClientLib.ProxyStorage storage ps = MarketClientLib.proxyStorage();

        // Store the AccessController address
        ps.accessController = IAccessControlUpgradeable(_accessController);

        // Store the MarketController address
        ps.marketController = IMarketController(_marketController);

        // Store the implementation address
        ps.implementation = _impl;

    }

    /**
     * @dev Returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation()
    internal
    view
    override
    returns (address) {

        // Get the ProxyStorage struct
        MarketClientLib.ProxyStorage storage ps = MarketClientLib.proxyStorage();

        // Return the current implementation address
        return ps.implementation;

    }

    /**
     * @dev Set the implementation address
     */
    function setImplementation(address _impl)
    external
    onlyRole(UPGRADER)
    override
    {
        // Get the ProxyStorage struct
        MarketClientLib.ProxyStorage storage ps = MarketClientLib.proxyStorage();

        // Store the implementation address
        ps.implementation = _impl;

        // Notify listeners about state change
        emit Upgraded(_impl);

    }

    /**
     * @dev Get the implementation address
     */
    function getImplementation()
    external
    view
    override
    returns (address) {
        return _implementation();
    }

    /**
     * @notice Set the Seen.Haus AccessController
     *
     * Emits an AccessControllerAddressChanged event.
     *
     * @param _accessController - the Seen.Haus AccessController address
     */
    function setAccessController(address _accessController)
    external
    onlyRole(UPGRADER)
    override
    {
        // Get the ProxyStorage struct
        MarketClientLib.ProxyStorage storage ps = MarketClientLib.proxyStorage();

        // Store the AccessController address
        ps.accessController = IAccessControlUpgradeable(_accessController);

        // Notify listeners about state change
        emit AccessControllerAddressChanged(_accessController);
    }

    /**
     * @notice Gets the address of the Seen.Haus AccessController contract.
     *
     * @return the address of the AccessController contract
     */
    function getAccessController()
    public
    view
    override
    returns(IAccessControlUpgradeable)
    {
        // Get the ProxyStorage struct
        MarketClientLib.ProxyStorage storage ps = MarketClientLib.proxyStorage();

        // Return the current AccessController address
        return ps.accessController;
    }

    /**
     * @notice Set the Seen.Haus MarketController
     *
     * Emits an MarketControllerAddressChanged event.
     *
     * @param _marketController - the Seen.Haus MarketController address
     */
    function setMarketController(address _marketController)
    external
    onlyRole(UPGRADER)
    override
    {
        // Get the ProxyStorage struct
        MarketClientLib.ProxyStorage storage ps = MarketClientLib.proxyStorage();

        // Store the MarketController address
        ps.marketController = IMarketController(_marketController);

        // Notify listeners about state change
        emit MarketControllerAddressChanged(_marketController);
    }

    /**
     * @notice Gets the address of the Seen.Haus MarketController contract.
     *
     * @return the address of the MarketController contract
     */
    function getMarketController()
    public
    override
    view
    returns(IMarketController)
    {
        // Get the ProxyStorage struct
        MarketClientLib.ProxyStorage storage ps = MarketClientLib.proxyStorage();

        // Return the current MarketController address
        return ps.marketController;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IAccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import { IDiamondLoupe } from "../../interfaces/IDiamondLoupe.sol";
import { IDiamondCut } from "../../interfaces/IDiamondCut.sol";
import { DiamondLib } from "./DiamondLib.sol";
import { JewelerLib } from "./JewelerLib.sol";

/**
 * @title MarketDiamond
 *
 * @notice Based on Nick Mudge's gas-optimized diamond-2 reference,
 * with modifications to support role-based access and management of
 * supported interfaces.
 *
 * Reference Implementation  : https://github.com/mudgen/diamond-2-hardhat
 * EIP-2535 Diamond Standard : https://eips.ethereum.org/EIPS/eip-2535
 *
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract MarketDiamond {

    /**
     * @notice Constructor
     *
     * - Store the access controller
     * - Make the initial facet cuts
     * - Declare support for interfaces
     *
     * @param _accessController - the Seen.Haus AccessController
     * @param _facetCuts - the initial facet cuts to make
     * @param _interfaceIds - the initially supported ERC-165 interface ids
     */
    constructor(
        IAccessControlUpgradeable _accessController,
        IDiamondCut.FacetCut[] memory _facetCuts,
        bytes4[] memory _interfaceIds
    ) {

        // Get the DiamondStorage struct
        DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();

        // Set the AccessController instance
        ds.accessController = _accessController;

        // Cut the diamond with the given facets
        JewelerLib.diamondCut(_facetCuts, address(0), new bytes(0));

        // Add supported interfaces
        if (_interfaceIds.length > 0) {
            for (uint8 x = 0; x < _interfaceIds.length; x++) {
                DiamondLib.addSupportedInterface(_interfaceIds[x]);
            }
        }

    }

    /**
     * @notice Onboard implementation of ERC-165 interface detection standard.
     *
     * @param _interfaceId - the sighash of the given interface
     */
    function supportsInterface(bytes4 _interfaceId) external view returns (bool) {

        // Get the DiamondStorage struct
        return DiamondLib.supportsInterface(_interfaceId) ;

    }

    /**
     * Fallback function. Called when the specified function doesn't exist
     *
     * Find facet for function that is called and execute the
     * function if a facet is found and returns any value.
     */
    fallback() external payable {

        // Get the DiamondStorage struct
        DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();

        // Make sure the function exists
        address facet = address(bytes20(ds.facets[msg.sig]));
        require(facet != address(0), "Diamond: Function does not exist");

        // Invoke the function with delagatecall
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }

    }

    /// Contract can receive ETH
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { DiamondLib } from "./DiamondLib.sol";
import { IDiamondCut } from "../../interfaces/IDiamondCut.sol";

/**
 * @title JewelerLib
 *
 * @notice Facet management functions
 *
 * Based on Nick Mudge's gas-optimized diamond-2 reference.
 * Reference Implementation  : https://github.com/mudgen/diamond-2-hardhat
 * EIP-2535 Diamond Standard : https://eips.ethereum.org/EIPS/eip-2535
 *
 * N.B. The original `LibDiamond` contract used single-owner security scheme,
 * but this one uses role-based access via the Seen.Haus AccessController.
 *
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */

library JewelerLib {

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    bytes32 internal constant CLEAR_ADDRESS_MASK = bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 internal constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    /**
     * @notice Cut facets of the Diamond
     *
     * Add/replace/remove any number of function selectors
     *
     * If populated, _calldata is executed with delegatecall on _init
     *
     * @param _facetCuts Contains the facet addresses and function selectors
     * @param _init The address of the contract or facet to execute _calldata
     * @param _calldata A function call, including function selector and arguments
     */
    function diamondCut(
        IDiamondCut.FacetCut[] memory _facetCuts,
        address _init,
        bytes memory _calldata
    ) internal {

        // Get the diamond storage slot
        DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();

        // Determine how many existing selectors we have
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;

        // Check if last selector slot is full
        // N.B.: selectorCount & 7 is a gas-efficient equivalent to selectorCount % 8
        if (selectorCount & 7 > 0) {

            // get last selectorSlot
            // N.B.: selectorCount >> 3 is a gas-efficient equivalent to selectorCount / 8
            selectorSlot = ds.selectorSlots[selectorCount >> 3];

        }

        // Cut the facets
        for (uint256 facetIndex; facetIndex < _facetCuts.length; facetIndex++) {
            (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _facetCuts[facetIndex].facetAddress,
                _facetCuts[facetIndex].action,
                _facetCuts[facetIndex].functionSelectors
            );
        }

        // Update the selector count if it changed
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }

        // Update last selector slot
        // N.B.: selectorCount & 7 is a gas-efficient equivalent to selectorCount % 8
        if (selectorCount & 7 > 0) {

            // N.B.: selectorCount >> 3 is a gas-efficient equivalent to selectorCount / 8
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;

        }

        // Notify listeners of state change
        emit DiamondCut(_facetCuts, _init, _calldata);

        // Initialize the facet
        initializeDiamondCut(_init, _calldata);
    }

    /**
     * @notice Maintain the selectors in a FacetCut
     *
     * N.B. This method is unbelievably long and dense.
     * It hails from the diamond-2 reference and works
     * under test.
     *
     * I've added comments to try and reason about it
     * - CLH
     *
     * @param _selectorCount - the current selectorCount
     * @param _selectorSlot - the selector slot
     * @param _newFacetAddress - the facet address of the new or replacement function
     * @param _action - the action to perform. See: {IDiamondCut.FacetCutAction}
     * @param _selectors - the selectors to modify
     */
    function addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        address _newFacetAddress,
        IDiamondCut.FacetCutAction _action,
        bytes4[] memory _selectors
    ) internal returns (uint256, bytes32) {

        // Make sure there are some selectors to work with
        DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();
        require(_selectors.length > 0, "LibDiamondCut: No selectors in facet to cut");

        // Add a selector
        if (_action == IDiamondCut.FacetCutAction.Add) {

            // Make sure facet being added has code
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Add facet has no code");

            // Iterate selectors
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {

                // Make sure function doesn't already exist
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                require(address(bytes20(oldFacet)) == address(0), "LibDiamondCut: Can't add function that already exists");

                // add facet for selector
                ds.facets[selector] = bytes20(_newFacetAddress) | bytes32(_selectorCount);
                uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;

                // clear selector position in slot and add selector
                _selectorSlot = (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) | (bytes32(selector) >> selectorInSlotPosition);

                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    ds.selectorSlots[_selectorCount >> 3] = _selectorSlot;
                    _selectorSlot = 0;
                }

                // Increment selector count
                _selectorCount++;
            }

        // Replace a selector
        } else if (_action == IDiamondCut.FacetCutAction.Replace) {

            // Make sure replacement facet has code
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Replace facet has no code");

            // Iterate selectors
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {

                // Make sure function doesn't already exist
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));

                // only useful if immutable functions exist
                require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
                require(oldFacetAddress != _newFacetAddress, "LibDiamondCut: Can't replace function with same function");
                require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");

                // replace old facet address
                ds.facets[selector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(_newFacetAddress);

            }

        // Remove a selector
        } else if (_action == IDiamondCut.FacetCutAction.Remove) {

            // Make sure facet address is zero address
            require(_newFacetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");

            // Get the selector slot count and index to selector in slot
            uint256 selectorSlotCount = _selectorCount >> 3;
            uint256 selectorInSlotIndex = _selectorCount & 7;

            // Iterate selectors
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {

                // Get previous selector slot, wrapping around to last from zero
                if (_selectorSlot == 0) {
                    selectorSlotCount--;
                    _selectorSlot = ds.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;

                // Remove selector, swapping in with last selector in last slot
                // N.B. adding a block here prevents stack too deep error
                {
                    // get selector and facet, making sure it exists
                    bytes4 selector = _selectors[selectorIndex];
                    bytes32 oldFacet = ds.facets[selector];
                    require(address(bytes20(oldFacet)) != address(0), "LibDiamondCut: Can't remove function that doesn't exist");

                    // only useful if immutable functions exist
                    require(address(bytes20(oldFacet)) != address(this), "LibDiamondCut: Can't remove immutable function");

                    // replace selector with last selector in ds.facets
                    // gets the last selector
                    lastSelector = bytes4(_selectorSlot << (selectorInSlotIndex << 5));
                    if (lastSelector != selector) {
                        // update last selector slot position info
                        ds.facets[lastSelector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(ds.facets[lastSelector]);
                    }
                    delete ds.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }

                // Update selector slot if count changed
                if (oldSelectorsSlotCount != selectorSlotCount) {

                    bytes32 oldSelectorSlot = ds.selectorSlots[oldSelectorsSlotCount];

                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);

                    // update storage with the modified slot
                    ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;

                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    _selectorSlot =
                        (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }

                // delete selector
                if (selectorInSlotIndex == 0) {
                    delete ds.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }
            }

            // Update selector count
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;

        }

        // return updated selector count and selector slot for
        return (_selectorCount, _selectorSlot);
    }

    /**
     * @notice Call a facet's initializer
     *
     * @param _init - the address of the facet to be initialized
     * @param _calldata - the
     */
    function initializeDiamondCut(address _init, bytes memory _calldata) internal {

        // If _init is not populated, then _calldata must also be unpopulated
        if (_init == address(0)) {

            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");

        } else {

            // Revert if _calldata is not populated
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");

            // Make sure address to be initialized has code
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }

            // If _init and _calldata are populated, call initializer
            (bool success, bytes memory error) = _init.delegatecall(_calldata);

            // Handle result
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

    /**
     * @notice make sure the given address has code
     *
     * Reverts if address has no contract code
     *
     * @param _contract - the contract to check
     * @param _errorMessage - the revert reason to throw
     */
    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { SeenConstants } from "../../../domain/SeenConstants.sol";
import { IDiamondCut } from "../../../interfaces/IDiamondCut.sol";
import { DiamondLib } from "../DiamondLib.sol";
import { JewelerLib } from "../JewelerLib.sol";

/**
 * @title DiamondCutFacet
 *
 * @notice DiamondCut facet based on Nick Mudge's gas-optimized diamond-2 reference.
 * Reference Implementation  : https://github.com/mudgen/diamond-2-hardhat
 * EIP-2535 Diamond Standard : https://eips.ethereum.org/EIPS/eip-2535
 *
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract DiamondCutFacet is SeenConstants, IDiamondCut {

    /**
     * @notice Cut facets of the Diamond
     *
     * Add/replace/remove any number of function selectors
     *
     * If populated, _calldata is executed with delegatecall on _init
     *
     * Reverts if caller does not have UPGRADER role
     *
     * @param _facetCuts Contains the facet addresses and function selectors
     * @param _init The address of the contract or facet to execute _calldata
     * @param _calldata A function call, including function selector and arguments
     */
    function diamondCut(FacetCut[] calldata _facetCuts, address _init, bytes calldata _calldata)
    external
    override
    {
        // Get the diamond storage slot
        DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();

        // Ensure the caller has the UPGRADER role
        require(ds.accessController.hasRole(UPGRADER, msg.sender), "Caller must have UPGRADER role");

        // Make the cuts
        JewelerLib.diamondCut(_facetCuts, _init, _calldata);

    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IDiamondLoupe } from "../../../interfaces/IDiamondLoupe.sol";
import { DiamondLib } from  "../DiamondLib.sol";

/**
 * @title DiamondLoupeFacet
 *
 * @notice DiamondCut facet based on Nick Mudge's gas-optimized diamond-2 reference.
 * Reference Implementation  : https://github.com/mudgen/diamond-2-hardhat
 * EIP-2535 Diamond Standard : https://eips.ethereum.org/EIPS/eip-2535
 *
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 */
contract DiamondLoupeFacet is IDiamondLoupe {

    /**
     *  @notice Gets all facets and their selectors.
     *  @return facets_ Facet
     */
    function facets() external override view returns (Facet[] memory facets_) {
        DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();
        facets_ = new Facet[](ds.selectorCount);
        uint8[] memory numFacetSelectors = new uint8[](ds.selectorCount);
        uint256 numFacets;
        uint256 selectorIndex;
        // loop through function selectors
        for (uint256 slotIndex; selectorIndex < ds.selectorCount; slotIndex++) {
            bytes32 slot = ds.selectorSlots[slotIndex];
            for (uint256 selectorSlotIndex; selectorSlotIndex < 8; selectorSlotIndex++) {
                selectorIndex++;
                if (selectorIndex > ds.selectorCount) {
                    break;
                }
                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                address facetAddress_ = address(bytes20(ds.facets[selector]));
                bool continueLoop = false;
                for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                    if (facets_[facetIndex].facetAddress == facetAddress_) {
                        facets_[facetIndex].functionSelectors[numFacetSelectors[facetIndex]] = selector;
                        // probably will never have more than 256 functions from one facet contract
                        require(numFacetSelectors[facetIndex] < 255);
                        numFacetSelectors[facetIndex]++;
                        continueLoop = true;
                        break;
                    }
                }
                if (continueLoop) {
                    continueLoop = false;
                    continue;
                }
                facets_[numFacets].facetAddress = facetAddress_;
                facets_[numFacets].functionSelectors = new bytes4[](ds.selectorCount);
                facets_[numFacets].functionSelectors[0] = selector;
                numFacetSelectors[numFacets] = 1;
                numFacets++;
            }
        }
        for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
            uint256 numSelectors = numFacetSelectors[facetIndex];
            bytes4[] memory selectors = facets_[facetIndex].functionSelectors;
            // setting the number of selectors
            assembly {
                mstore(selectors, numSelectors)
            }
        }
        // setting the number of facets
        assembly {
            mstore(facets_, numFacets)
        }
    }

    /**
     * @notice Gets all the function selectors supported by a specific facet.
     * @param _facet The facet address.
     * @return facetFunctionSelectors_ The selectors associated with a facet address.
     */
    function facetFunctionSelectors(address _facet) external override view returns (bytes4[] memory facetFunctionSelectors_) {
        DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();
        uint256 numSelectors;
        facetFunctionSelectors_ = new bytes4[](ds.selectorCount);
        uint256 selectorIndex;
        // loop through function selectors
        for (uint256 slotIndex; selectorIndex < ds.selectorCount; slotIndex++) {
            bytes32 slot = ds.selectorSlots[slotIndex];
            for (uint256 selectorSlotIndex; selectorSlotIndex < 8; selectorSlotIndex++) {
                selectorIndex++;
                if (selectorIndex > ds.selectorCount) {
                    break;
                }
                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                address facet = address(bytes20(ds.facets[selector]));
                if (_facet == facet) {
                    facetFunctionSelectors_[numSelectors] = selector;
                    numSelectors++;
                }
            }
        }
        // Set the number of selectors in the array
        assembly {
            mstore(facetFunctionSelectors_, numSelectors)
        }
    }

    /**
     * @notice Get all the facet addresses used by a diamond
     * @return facetAddresses_
     */
    function facetAddresses() external override view returns (address[] memory facetAddresses_) {
        DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();
        facetAddresses_ = new address[](ds.selectorCount);
        uint256 numFacets;
        uint256 selectorIndex;
        // loop through function selectors
        for (uint256 slotIndex; selectorIndex < ds.selectorCount; slotIndex++) {
            bytes32 slot = ds.selectorSlots[slotIndex];
            for (uint256 selectorSlotIndex; selectorSlotIndex < 8; selectorSlotIndex++) {
                selectorIndex++;
                if (selectorIndex > ds.selectorCount) {
                    break;
                }
                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                address facetAddress_ = address(bytes20(ds.facets[selector]));
                bool continueLoop = false;
                for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                    if (facetAddress_ == facetAddresses_[facetIndex]) {
                        continueLoop = true;
                        break;
                    }
                }
                if (continueLoop) {
                    continueLoop = false;
                    continue;
                }
                facetAddresses_[numFacets] = facetAddress_;
                numFacets++;
            }
        }
        // Set the number of facet addresses in the array
        assembly {
            mstore(facetAddresses_, numFacets)
        }
    }

    /**
     * @notice Gets the facet that supports the given selector.
     *
     * @dev If facet is not found return address(0).
     * @param _functionSelector The function selector.
     * @return facetAddress_ The facet address.
     */
    function facetAddress(bytes4 _functionSelector) external override view returns (address facetAddress_) {
        DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();
        facetAddress_ = address(bytes20(ds.facets[_functionSelector]));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
    }

    function __ERC1155Receiver_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "../../../interfaces/IMarketClerk.sol";
import "../../diamond/DiamondLib.sol";
import "../MarketControllerBase.sol";
import "../MarketControllerLib.sol";

/**
 * @title MarketClerkFacet
 *
 * @notice Manages consignments for the Seen.Haus contract suite.
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract MarketClerkFacet is IMarketClerk, MarketControllerBase, ERC1155HolderUpgradeable, ERC721HolderUpgradeable {

    /**
     * @dev Modifier to protect initializer function from being invoked twice.
     */
    modifier onlyUnInitialized() {
        MarketControllerLib.MarketControllerInitializers storage mci = MarketControllerLib.marketControllerInitializers();
        require(!mci.clerkFacet, "Initializer: contract is already initialized");
        mci.clerkFacet = true;
        _;
    }

    /**
     * @notice Facet Initializer
     *
     * Register IMarketClerk,
     */
    function initialize()
    public
    onlyUnInitialized
    {
        DiamondLib.addSupportedInterface(type(IMarketClerk).interfaceId);
        DiamondLib.addSupportedInterface(type(IERC1155ReceiverUpgradeable).interfaceId);
        DiamondLib.addSupportedInterface(type(IERC721ReceiverUpgradeable).interfaceId);
    }

    /**
     * @notice The nextConsignment getter
     * @dev does not increment counter
     */
    function getNextConsignment()
    external
    override
    view
    returns (uint256)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        return mcs.nextConsignment;
    }

    /**
     * @notice The consignment getter
     *
     * Reverts if consignment doesn't exist
     *
     * @param _consignmentId - the id of the consignment
     * @return consignment - the consignment struct
     */
    function getConsignment(uint256 _consignmentId)
    public
    override
    view
    consignmentExists(_consignmentId)
    returns (Consignment memory consignment)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        consignment = mcs.consignments[_consignmentId];
    }

    /**
     * @notice Get the remaining supply of the given consignment.
     *
     * Reverts if consignment doesn't exist
     *
     * @param _consignmentId - the id of the consignment
     * @return  uint256 - the remaining supply held by the MarketController
     */
    function getUnreleasedSupply(uint256 _consignmentId)
    public
    override
    view
    consignmentExists(_consignmentId)
    returns(uint256)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        Consignment storage consignment = mcs.consignments[_consignmentId];
        return consignment.supply - consignment.releasedSupply;
    }

    /**
     * @notice Get the consignor of the given consignment
     *
     * Reverts if consignment doesn't exist
     *
     * @param _consignmentId - the id of the consignment
     * @return  address - the consignor's address
     */
    function getConsignor(uint256 _consignmentId)
    public
    override
    view
    consignmentExists(_consignmentId)
    returns(address)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        return mcs.consignors[_consignmentId];
    }

    /**
     * @notice Registers a new consignment for sale or auction.
     *
     * Emits a ConsignmentRegistered event.
     *
     * Reverts if:
     *  - Token is multi-token and supply hasn't been transferred to this contract
     *  - Token is not multi-token and contract doesn't implement ERC-721
     *  - Token is not multi-token and this contract is not owner of tokenId
     *  - Token is not multi-token and the supply is not 1
     *
     * @param _market - the market for the consignment. See {SeenTypes.Market}
     * @param _consignor - the address executing the consignment transaction
     * @param _seller - the seller of the consignment
     * @param _tokenAddress - the contract address issuing the NFT behind the consignment
     * @param _tokenId - the id of the token being consigned
     * @param _supply - the amount of the token being consigned
     *
     * @return consignment - the registered consignment
     */
    function registerConsignment(
        Market _market,
        address _consignor,
        address payable _seller,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _supply
    )
    external
    override
    onlyRole(MARKET_HANDLER)
    returns (Consignment memory consignment)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();

        // Check whether this is a multi token NFT
        bool multiToken = IERC165Upgradeable(_tokenAddress).supportsInterface(type(IERC1155Upgradeable).interfaceId);

        // Ensure consigned asset has been transferred to this this contract
        if (multiToken)  {

            // Ensure this contract has a balance of this token which is at least the value of the supply of the consignment
            // WARNING: In the case of a multiToken, do not rely on this as being a guarantee that the creator of this consignment has transferred a _supply of this token to this contract
            // This is not guaranteed, as in the context of a secondary market, somebody else might have transferred a value equal or greater than _supply to this contract
            // THEREFORE: ALWAYS MAKE SURE THAT THE SUPPLY OF CONSIGNMENT REGISTRATION IS TRANSFERRED TO THIS CONTRACT BEFORE CALLING registerConsignment
            require( IERC1155Upgradeable(_tokenAddress).balanceOf(address(this), _tokenId) >= _supply, "MarketController must own token" );

        } else {

            // Token must be a single token NFT
            require(IERC165Upgradeable(_tokenAddress).supportsInterface(type(IERC721Upgradeable).interfaceId), "Invalid token type");

            // Ensure the consigned token has been transferred to this contract & that supply = 1
            // Rolled into a single require due to contract size
            require((IERC721Upgradeable(_tokenAddress).ownerOf(_tokenId) == (address(this))) && (_supply == 1), "MarketController must own token & supply must be 1");

        }

        // Get the id for the new consignment and increment counter
        uint256 id = mcs.nextConsignment++;

        // Create and store the consignment
        consignment = Consignment(
            _market,
            MarketHandler.Unhandled,
            _seller,
            _tokenAddress,
            _tokenId,
            _supply,
            id,
            multiToken,
            false,
            0,
            0,
            0
        );
        mcs.consignments[id] = consignment;

        // Associate the consignor
        mcs.consignors[id] = _consignor;

        // Notify listeners of state change
        emit ConsignmentRegistered(_consignor, _seller, consignment);
    }

    /**
     * @notice Update consignment to indicate it has been marketed
     *
     * Emits a ConsignmentMarketed event.
     *
     * Reverts if:
     *  - _marketHandler of value Unhandled is passed into this function. See {SeenTypes.MarketHandler}.
     *  - consignment has already been marketed (has a marketHandler other than Unhandled). See {SeenTypes.MarketHandler}.
     *
     * @param _consignmentId - the id of the consignment
     */
    function marketConsignment(uint256 _consignmentId, MarketHandler _marketHandler)
    external
    override
    onlyRole(MARKET_HANDLER)
    consignmentExists(_consignmentId)
    {
        require(_marketHandler != MarketHandler.Unhandled, "requires valid handler");

        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();

        // Get the consignment into memory
        Consignment storage consignment = mcs.consignments[_consignmentId];

        // A consignment can only be marketed once, should currently be Unhandled
        require(consignment.marketHandler == MarketHandler.Unhandled, "Consignment already marketed");

        // Update the consignment
        consignment.marketHandler = _marketHandler;

        // Consignor address
        address consignor = mcs.consignors[_consignmentId];

        // Notify listeners of state change
        emit ConsignmentMarketed(consignor, consignment.seller, consignment.id);
    }

    /**
     * @notice Release an amount of the consigned token balance to a given address
     *
     * Emits a ConsignmentReleased event.
     *
     * Reverts if:
     *  - caller is does not have MARKET_HANDLER role.
     *  - consignment doesn't exist
     *  - consignment has already been released
     *  - consignment is multi-token and supply is not adequate
     *
     * @param _consignmentId - the id of the consignment
     * @param _amount - the amount of the consigned supply (must be 1 for ERC721 tokens)
     * @param _releaseTo - the address to transfer the consigned token balance to
     */
    function releaseConsignment(uint256 _consignmentId, uint256 _amount, address _releaseTo)
    external
    override
    onlyRole(MARKET_HANDLER)
    consignmentExists(_consignmentId)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();

        // Get the consignment into memory
        Consignment storage consignment = mcs.consignments[_consignmentId];

        // Ensure the consignment has not been released
        require(!consignment.released, "Consigned token already released");

        // Handle transfer, marking of consignment
        if (consignment.multiToken) {

            // Get the current remaining consignment supply
            uint256 remainingSupply = consignment.supply - consignment.releasedSupply;

            // Safety check
            require(_amount <= remainingSupply, "Attempting to release more than is available to consignment");

            // Mark the consignment when the entire consignment supply has been released
            if (remainingSupply == _amount) consignment.released = true;
            consignment.releasedSupply = consignment.releasedSupply + _amount;

            // Transfer a balance of the token from the MarketController to the recipient
            IERC1155Upgradeable(consignment.tokenAddress).safeTransferFrom(
                address(this),
                _releaseTo,
                consignment.tokenId,
                _amount,
                new bytes(0x0)
            );

        } else {

            // Mark the single-token consignment released
            consignment.released = true;
            consignment.releasedSupply = consignment.releasedSupply + _amount;

            // Transfer the token from the MarketController to the recipient
            IERC721Upgradeable(consignment.tokenAddress).safeTransferFrom(
                address(this),
                _releaseTo,
                consignment.tokenId
            );

        }

        // Notify watchers about state change
        emit ConsignmentReleased(consignment.id, _amount, _releaseTo);

    }

    /**
     * @notice Clears the pending payout value of a consignment
     *
     * Emits a ConsignmentPayoutSet event.
     *
     * Reverts if:
     *  - caller is does not have MARKET_HANDLER role.
     *  - consignment doesn't exist
     *
     * @param _consignmentId - the id of the consignment
     * @param _amount - the amount of that the consignment's pendingPayout must be set to
     */
    function setConsignmentPendingPayout(uint256 _consignmentId, uint256 _amount)
    external
    override
    onlyRole(MARKET_HANDLER)
    consignmentExists(_consignmentId)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();

        // Get the consignment into memory
        Consignment storage consignment = mcs.consignments[_consignmentId];

        // Update pending payout
        consignment.pendingPayout = _amount;

        // Notify watchers about state change
        emit ConsignmentPendingPayoutSet(consignment.id, _amount);

    }

    /**
     * @notice Set the type of Escrow Ticketer to be used for a consignment
     *
     * Default escrow ticketer is Ticketer.Lots. This only needs to be called
     * if overriding to Ticketer.Items for a given consignment.
     *
     * Emits a ConsignmentTicketerSet event.
     *
     * Reverts if consignment doesn't exist     *
     *
     * @param _consignmentId - the id of the consignment
     * @param _ticketerType - the type of ticketer to use. See: {SeenTypes.Ticketer}
     */
    function setConsignmentTicketer(uint256 _consignmentId, Ticketer _ticketerType)
    external
    override
    onlyRole(ESCROW_AGENT)
    consignmentExists(_consignmentId)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();

        // Set the ticketer for the consignment if not different
        if (_ticketerType != mcs.consignmentTicketers[_consignmentId]) {

            // Set the ticketer for the consignment
            mcs.consignmentTicketers[_consignmentId] = _ticketerType;

            // Notify listeners of state change
            emit ConsignmentTicketerChanged(_consignmentId, _ticketerType);

        }
    }

    /**
     * @notice Set a custom fee percentage on a consignment (e.g. for "official" SEEN x Artist drops)
     *
     * Default escrow ticketer is Ticketer.Lots. This only needs to be called
     * if overriding to Ticketer.Items for a given consignment.
     *
     * Emits a ConsignmentFeeChanged event.
     *
     * Reverts if:
     * - consignment doesn't exist
     * - _customFeePercentageBasisPoints is more than 10000
     *
     * @param _consignmentId - the id of the consignment
     * @param _customFeePercentageBasisPoints - the custom fee percentage basis points to use
     *
     * N.B. _customFeePercentageBasisPoints percentage value as an unsigned int by multiplying the percentage by 100:
     * e.g, 1.75% = 175, 100% = 10000
     */
    function setConsignmentCustomFee(uint256 _consignmentId, uint16 _customFeePercentageBasisPoints)
    external
    override
    onlyRole(ADMIN)
    {

        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();

        // Get the consignment into memory
        Consignment storage consignment = mcs.consignments[_consignmentId];

        // Ensure the consignment exists, has not been released and that basis points don't exceed 10000
        // Rolled into one require due to contract size being near max
        require(!consignment.released && (_customFeePercentageBasisPoints <= 10000) && (_consignmentId < mcs.nextConsignment), "Consignment released or nonexistent, or basisPoints over 10000");

        consignment.customFeePercentageBasisPoints = _customFeePercentageBasisPoints;

        emit ConsignmentFeeChanged(consignment.id, _customFeePercentageBasisPoints);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
        __ERC1155Holder_init_unchained();
    }

    function __ERC1155Holder_init_unchained() internal initializer {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../../domain/SeenConstants.sol";

/**
 * @title AccessController
 *
 * @notice Implements centralized role-based access for Seen.Haus contracts.
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract AccessController is AccessControlUpgradeable, SeenConstants  {

    /**
     * @notice Constructor
     *
     * Grants ADMIN role to deployer.
     * Sets ADMIN as role admin for all other roles.
     */
    constructor() {
        _setupRole(MULTISIG, msg.sender); // Renounce role and grant to multisig once initial setup is complete
        _setRoleAdmin(MULTISIG, ADMIN); // Shift role admin to MULTISIG once initial setup is complete
        _setupRole(ADMIN, msg.sender);
        _setRoleAdmin(ADMIN, ADMIN);
        _setRoleAdmin(SELLER, ADMIN);
        _setRoleAdmin(MINTER, ADMIN);
        _setRoleAdmin(ESCROW_AGENT, ADMIN);
        _setRoleAdmin(MARKET_HANDLER, ADMIN);
        _setRoleAdmin(UPGRADER, ADMIN);
    }

    function shiftRoleAdmin(bytes32 role, bytes32 adminRole) external onlyRole(getRoleAdmin(role)) {
        _setRoleAdmin(role, adminRole);
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "../../../interfaces/ISeenHausNFT.sol";
import "../../../interfaces/IERC2981.sol";
import "../MarketClientBase.sol";
import "./SeenHausNFTStorage.sol";

/**
 * @title SeenHausNFT
 * @notice This is the Seen.Haus ERC-1155 NFT contract.
 *
 * Key features:
 * - Supports the ERC-2981 NFT Royalty Standard
 * - Tracks the original creator of each token.
 * - Tracks which tokens have a physical part
 * - Logically capped token supplies; a token's supply cannot be increased after minting.
 * - Only ESCROW_AGENT-roled addresses can mint physical NFTs.
 * - Only MINTER-roled addresses can mint digital NFTs, e.g., Seen.Haus staff, approved artists.
 * - Newly minted NFTs are automatically transferred to the MarketController and consigned
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract SeenHausNFT is SeenHausNFTStorage, ISeenHausNFT, MarketClientBase, ERC1155Upgradeable {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @notice Initializer
     */
    function initialize(address _initOwner)
    public {
        __ERC1155_init("");
        _transferOwnership(_initOwner);
    }

    /**
     * @notice The nextToken getter
     * @dev does not increment counter
     */
    function getNextToken()
    external view override
    returns (uint256)
    {
        return nextToken;
    }

    /**
     * @notice Get the info about a given token.
     *
     * @param _tokenId - the id of the token to check
     * @return tokenInfo - the info about the token. See: {SeenTypes.Token}
     */
    function getTokenInfo(uint256 _tokenId)
    external view override
    returns (Token memory tokenInfo)
    {
        return tokens[_tokenId];
    }

    /**
     * @notice Check if a given token id corresponds to a physical lot.
     *
     * @param _tokenId - the id of the token to check
     */
    function isPhysical(uint256 _tokenId)
    public view override
    returns (bool) {
        Token memory token = tokens[_tokenId];
        return token.isPhysical;
    }

    /**
     * @notice Mint a given supply of a token, optionally flagging as physical.
     *
     * Token supply is sent to the MarketController.
     *
     * @param _supply - the supply of the token
     * @param _creator - the creator of the NFT (where the royalties will go)
     * @param _tokenURI - the URI of the token metadata
     * @param _royaltyPercentage - the percentage of royalty expected on secondary market sales
     * @param _isPhysical - whether the NFT should be flagged as physical or not
     */
    function mint(uint256 _supply, address payable _creator, string memory _tokenURI, uint16 _royaltyPercentage, bool _isPhysical)
    internal
    returns(Consignment memory consignment)
    {
        // Get the MarketController
        IMarketController marketController = getMarketController();

        // Make sure royalty percentage is acceptable
        require(_royaltyPercentage <= marketController.getMaxRoyaltyPercentage(), "Royalty percentage exceeds marketplace maximum");

        // Get the next token id
        uint256 tokenId = nextToken++;

        // Store the token info
        Token storage token = tokens[tokenId];
        token.id = tokenId;
        token.uri = _tokenURI;
        token.supply = _supply;
        token.creator = _creator;
        token.isPhysical = _isPhysical;
        token.royaltyPercentage = _royaltyPercentage;

        // Mint the token, sending it to the MarketController
        _mint(address(marketController), tokenId, _supply, new bytes(0x0));

        // Consign the token for the primary market
        consignment = marketController.registerConsignment(Market.Primary, msg.sender, _creator, address(this), tokenId, _supply);
    }

    /**
     * @notice Mint a given supply of a token, marking it as physical.
     *
     * Entire supply must be minted at once.
     * More cannot be minted later for the same token id.
     * Can only be called by an address with the ESCROW_AGENT role.
     * Token supply is sent to the MarketController.
     *
     * @param _supply - the supply of the token
     * @param _creator - the creator of the NFT (where the royalties will go)
     * @param _tokenURI - the URI of the token metadata
     * @param _royaltyPercentage - the percentage of royalty expected on secondary market sales
     *
     * N.B. Represent percentage value as an unsigned int by multiplying the percentage by 100:
     * e.g, 1.75% = 175, 100% = 10000
     *
     * @return consignment - the registered primary market consignment of the newly minted token
     */
    function mintPhysical(uint256 _supply, address payable _creator, string memory _tokenURI, uint16 _royaltyPercentage)
    external override
    onlyRole(ESCROW_AGENT)
    returns(Consignment memory consignment)
    {
        // Mint the token, flagging it as physical, consigning to the MarketController
        return mint(_supply, _creator, _tokenURI, _royaltyPercentage, true);
    }

    /**
     * @notice Mint a given supply of a token.
     *
     * Entire supply must be minted at once.
     * More cannot be minted later for the same token id.
     * Can only be called by an address with the MINTER role.
     * Token supply is sent to the caller's address.
     *
     * @param _supply - the supply of the token
     * @param _creator - the creator of the NFT (where the royalties will go)
     * @param _tokenURI - the URI of the token metadata
     * @param _royaltyPercentage - the percentage of royalty expected on secondary market sales
     *
     * N.B. Represent percentage value as an unsigned int by multiplying the percentage by 100:
     * e.g, 1.75% = 175, 100% = 10000
     *
     * @return consignment - the registered primary market consignment of the newly minted token
     */
    function mintDigital(uint256 _supply, address payable _creator, string memory _tokenURI, uint16 _royaltyPercentage)
    external override
    onlyRole(MINTER)
    returns(Consignment memory consignment)
    {
        // Mint the token, consigning to the MarketController
        return mint(_supply, _creator, _tokenURI, _royaltyPercentage, false);
    }

    /**
     * @notice Get royalty info for a token
     *
     * For a given token id and sale price, how much should be sent to whom as royalty
     *
     * @param _tokenId - the NFT asset queried for royalty information
     * @param _salePrice - the sale price of the NFT asset specified by _tokenId
     *
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for _value sale price
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external view override
    returns (address receiver, uint256 royaltyAmount)
    {
        Token storage token = tokens[_tokenId];
        receiver = token.creator;
        royaltyAmount = getPercentageOf(_salePrice, token.royaltyPercentage);
    }

    /**
     * @notice Implementation of the {IERC165} interface.
     *
     * N.B. This method is inherited from several parents and
     * the compiler cannot decide which to use. Thus, they must
     * be overridden here.
     *
     * if you just call super.supportsInterface, it chooses
     * 'the most derived contract'. But that's not good for this
     * particular function because you may inherit from several
     * IERC165 contracts, and all concrete ones need to be allowed
     * to respond.
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC1155Upgradeable, IERC165Upgradeable)
    returns (bool)
    {
        return (
            interfaceId == type(ISeenHausNFT).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }

    /**
     * @notice Get the token URI
     *
     * This method is overrides the Open Zeppelin version, returning
     * a unique stored metadata URI for each token rather than a
     * replaceable baseURI template, since the latter is not compatible
     * with IPFS hashes.
     *
     * @param _tokenId - id of the token to get the URI for
     */
    function uri(uint256 _tokenId)
    public view override
    returns (string memory)
    {
        Token storage token = tokens[_tokenId];
        return token.uri;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public override onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../../../domain/SeenTypes.sol";

/**
 * @title SeenHausNFTStorage
 * @notice Splits storage away from the logic in SeenHausNFT.sol for maintainability
 */
contract SeenHausNFTStorage is SeenTypes {

  address internal _owner;

  /// @dev token id => Token struct
  mapping (uint256 => Token) internal tokens;

  // Next token number
  uint256 internal nextToken;

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/IEscrowTicketer.sol";

/**
 * @title ItemsTicketerClaimHelper
 *
 * @notice Helps run batches of claims against the ItemsTicketer in one transaction instead of having to run individual claims
 *
 */
contract ItemsTicketerClaimHelper {

  function claim(uint256[] memory _ticketIds, address _itemsTicketer) external {
    
    // IEscrowTicketer itemsTicketer = IEscrowTicketer(_itemsTicketer);

    for(uint256 i = 0; i < _ticketIds.length; i++) {
      // itemsTicketer.claim(_ticketIds[i]);
      (bool success, bytes memory result) = _itemsTicketer.delegatecall(abi.encodeWithSignature("claim(uint256 _ticketId)", _ticketIds[i]));
      if(!success) {
        revert("Claim unsuccessful");
      }
    }

  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { TestFacetLib } from "./TestFacetLib.sol";

/**
 * @title Test2FacetUpgrade
 *
 * @notice Contract for testing Diamond operations
 *
 * This facet contains a single function intended to replace a function
 * originally supplied to the Diamond by TestFacet2.
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract Test2FacetUpgrade {

    function test2Func13() external pure returns (string memory) {return "json";}

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../../../interfaces/IEthCreditRecovery.sol";
import "../MarketHandlerBase.sol";

/**
 * @title EthCreditFacet
 *
 * @notice Handles distribution of any available ETH credits (from reverted attempts to distribute funds)
 */
contract EthCreditRecoveryFacet is IEthCreditRecovery, MarketHandlerBase {

    /**
     * @dev Modifier to protect initializer function from being invoked twice.
     */
    modifier onlyUnInitialized()
    {

        MarketHandlerLib.MarketHandlerInitializers storage mhi = MarketHandlerLib.marketHandlerInitializers();
        require(!mhi.ethCreditRecoveryFacet, "Initializer: contract is already initialized");
        mhi.ethCreditRecoveryFacet = true;
        _;
    }

    /**
     * @notice Facet Initializer
     *
     * Register supported interfaces
     */
    function initialize()
    public
    onlyUnInitialized
    {
        DiamondLib.addSupportedInterface(type(IEthCreditRecovery).interfaceId);
    }

    /**
     * @notice Enables recovery of any ETH credit to an account which has credits
     *
     * Doesn't require that the caller of this function is the same address as the `_recipient`
     * as it is likely that `_recipient` may not be able to call this function if an ETH transfer to `_recipient` reverted
     *
     * See: {MarketHandlerBase.sendValueOrCreditAccount}
     *
     * Reverts if:
     * - Account has no ETH credits
     * - ETH cannot be sent to creditted account
     *
     * @param _recipient - id of the consignment being sold
     */
    function recoverEthCredits(address _recipient)
    external
    override
    {
        // Get Market Handler Storage slot
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();
        
        // Make sure there is enough ETH in contract & that credit exists
        uint256 ethCredit = mhs.addressToEthCredit[_recipient];
        require(address(this).balance >= ethCredit, "Address: insufficient balance");
        require(ethCredit > 0, "No ETH credits");

        // Set to zero in case of reentrancy
        mhs.addressToEthCredit[_recipient] = 0;

        (bool success, ) = _recipient.call{value: ethCredit}("");
        require(success, "Failed to disburse ETH credits");
        
        // Emit
        emit EthCreditRecovered(_recipient, ethCredit);
    }

    /**
     * @notice Enables MULTISIG recovery of any ETH credit for an account which has credits but can't recover the ETH via distributeEthCredits
     *
     * In rare cases, `_originalRecipient` may be unable to start receiving ETH again
     * therefore any ETH credits would get stuck
     *
     * See: {MarketHandlerBase.sendValueOrCreditAccount} & {EthCreditFacet.distributeEthCredits}
     *
     * Reverts if:
     * - Account has no ETH credits
     * - ETH cannot be sent to creditted account
     *
     * @param _originalRecipient - the account with unrecoverable (via distributeEthCredits) ETH credits
     */
    function fallbackRecoverEthCredit(address _originalRecipient)
    external
    override
    onlyRole(MULTISIG)
    {
        // Get Market Handler Storage slot
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();
        
        // Make sure there is enough ETH in contract & that credit exists
        uint256 ethCredit = mhs.addressToEthCredit[_originalRecipient];
        require(ethCredit > 0, "No ETH credits");
        require(address(this).balance >= ethCredit, "Address: insufficient balance");

        // Set to zero in case of reentrancy
        mhs.addressToEthCredit[_originalRecipient] = 0;
        
        // Send funds to MultiSig
        IMarketController marketController = getMarketController(); 
        address payable multisig = marketController.getMultisig();

        (bool success, ) = multisig.call{value: ethCredit}("");
        require(success, "Failed to disburse ETH credits");
        
        // Emit
        emit EthCreditFallbackRecovered(_originalRecipient, ethCredit, msg.sender, multisig);
    }

    /**
     * @notice returns the pending ETH credits for a recipient
     *
     * @param _recipient - the account to check ETH credits for
     */
    function availableCredits(address _recipient)
    external
    view
    override
    returns (uint256) {
        // Get Market Handler Storage slot
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();
        return mhs.addressToEthCredit[_recipient];
    }

}