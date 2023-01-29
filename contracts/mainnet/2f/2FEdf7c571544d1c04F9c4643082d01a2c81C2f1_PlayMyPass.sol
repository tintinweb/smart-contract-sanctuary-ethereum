// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./lib/IDelegationRegistry.sol";
import "./lib/IBAYCSewerPass.sol";

contract PlayMyPass is IERC721Receiver {

    struct PassData {
        uint16 passId;
        address passOwner;
        uint40 purchasePrice; // stored in GWEI
        uint32 hourlyRentalPrice; // stored in GWEI
        bool purchaseAllowed;
        bool rentalAllowed;
        bool boredPass; // for view functions, not stored in state
        bool dogPass; // for view functions, not stored in state
    }

    struct PassRental {
        uint16 passId;
        address renter;
        uint32 rentalEnd;
        uint32 hourlyRentalPrice;
        bool cannotExtend;
        bool boredPass; // for view functions, not stored in state
        bool dogPass; // for view functions, not stored in state
    }

    /// @dev Thrown when an ERC721 that is not the SewerPass tries to call onERC721Received
    error OnlySewerPass();
    /// @dev Thrown when someone attempts to deposit, withdraw or update a pass they do not own
    error NotPassOwner();
    /// @dev Thrown when attempting to rent or purchase and a pass owner has disabled rent/purchase
    error PassNotAvailable();
    /// @dev Thrown when attempting to rent or purchase and the pass is already rented, or withdraw a pass that is currently rented
    error PassCurrentlyRented();
    /// @dev Thrown when attempting to rent or purchase and msg.value is insufficent
    error InsufficientPayment();
    /// @dev Thrown when a caller that is not the deployer tries to call the rescueToken function
    error OnlyDeployer();
    /// @dev Thrown when the deployer tries to "rescue" the sponsored token
    error CannotRescueOwnedToken();
    /// @dev Thrown when renter tries to rent past max time
    error SewersClosing();
    /// @dev Thrown when attempting to set a pass for rental or sale at 0 cost
    error MustHaveValue();
    
    PassData private CLEAR_PASS;
	
    address constant public SEWER_PASS = 0x764AeebcF425d56800eF2c84F2578689415a2DAa;
    IDelegationRegistry delegateCash = IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);
    mapping(uint256 => PassData) public passData;
    mapping(uint256 => PassRental) public rentalData;
	
	uint256 constant public SEWERS_CLOSING = 1675814400; //February 8th, 12:00AM GMT, give pass owners time to get pass back in wallet & play before score freeze
    address constant public FEE_SPLITTER = 0xDa6058Bc88947004126089a8a5018c0121432379; //TODO: Update fee splitter address
    uint256 public constant FEE = 10;
    
    /// @dev store the deployer in case someone sends tokens to the contract without using safeTransferFrom
    address immutable DEPLOYER;
    
    constructor() {
        // set the deployer
        DEPLOYER = msg.sender;
    }


    /**
     * @notice Rents a Sewer Pass or extends rental for current renter
     * @param passId the sewer pass token ID being rented
     * @param rentalHours number of hours to rent the sewer pass for
     */
    function rentPass(uint256 passId, uint256 rentalHours) external payable {
        PassData memory pd = passData[passId];
        if(!pd.rentalAllowed) { revert PassNotAvailable(); } // revert if pass rental is disabled
        PassRental memory pr = rentalData[passId]; // load current rental data
        pr.passId = uint16(passId); //add passId to rental data, used later in UI functions

        if(pr.rentalEnd < block.timestamp) { // prior rental has expired
            if(pr.renter != msg.sender) { // new rental
                if(pr.renter != address(0)) { //revoke prior renter access if it exists
                    delegateCash.delegateForToken(pr.renter, SEWER_PASS, passId, false);
                }
                delegateCash.delegateForToken(msg.sender, SEWER_PASS, passId, true);
            }
            pr.renter = msg.sender; // set renter
            pr.rentalEnd = uint32(block.timestamp + rentalHours * 1 hours); // set rental end
        } else { // current rental still active
            if(pr.renter == msg.sender) { // extend rental
                pr.rentalEnd += uint32(rentalHours * 1 hours);
            } else { // deny rental
                revert PassCurrentlyRented();
            }
        }
        if(pr.rentalEnd > SEWERS_CLOSING) { revert SewersClosing(); }

        processRentalPayment(pd.passOwner, uint256(pd.hourlyRentalPrice), rentalHours); // pay pass owner
        rentalData[passId] = pr; // update state
    }



    /**
     * @notice Allows current renter for rented pass, or anyone for non-rented pass, to purchase a pass that the owner has set for sale
     * @param passId the sewer pass token ID being purchased
     */
    function purchasePass(uint256 passId) external payable {
        PassData memory pd = passData[passId];
        if(!pd.purchaseAllowed) { revert PassNotAvailable(); } // revert if pass purchase is disabled
        PassRental memory pr = rentalData[passId]; // load current rental data

        if(pr.renter != msg.sender && pr.rentalEnd > block.timestamp) { revert PassCurrentlyRented(); } // if currently rented, only current renter can purchase
        if(pr.renter != address(0)) { //clean up delegations
            delegateCash.delegateForToken(pr.renter, SEWER_PASS, passId, false);
        }

        processPurchasePayment(pd.passOwner, uint256(pd.purchasePrice)); // pay pass owner
        passData[passId] = CLEAR_PASS; // clean up state
        IERC721(SEWER_PASS).safeTransferFrom(address(this), msg.sender, passId); // transfer pass to purchaser
    }



    /**
     * @notice Internal function, converts calculates rental price, converts price from GWEI to WEI, checks payment amount, issues refund if necessary and sends payment to pass owner
     * @param passOwner the address of the pass holder to send payment to
     * @param hourlyRentalPrice the hourly rental price in GWEI for the sewer pass
     * @param rentalHours number of hours to rent the sewer pass for
     */
    function processRentalPayment(address passOwner, uint256 hourlyRentalPrice, uint256 rentalHours) internal {
        uint256 rentalCost = hourlyRentalPrice * rentalHours * 1 gwei; // calculate cost, convert gwei to wei
        refundIfOver(rentalCost);
        payPassOwner(passOwner, rentalCost);
    }

    /**
     * @notice Internal function, converts purchase price from GWEI to WEI, checks payment amount, issues refund if necessary and sends payment to pass owner
     * @param passOwner the address of the pass holder to send payment to
     * @param purchasePrice the purchase price for the sewer pass in GWEI
     */
    function processPurchasePayment(address passOwner, uint256 purchasePrice) internal {
        purchasePrice = purchasePrice * 1 gwei; //convert gwei to wei
        refundIfOver(purchasePrice);
        payPassOwner(passOwner, purchasePrice);
    }

    /**
     * @notice Send rental and purchase payments to pass owner, subtracts 10% FEE
     * @param passOwner the address of the pass holder to send payment to
     * @param price the total cost for the transaction
     */
    function payPassOwner(address passOwner, uint256 price) internal {
        uint256 providerFee = price * FEE / 100;
        uint256 payment = price - providerFee;
        (bool sent, ) = payable(passOwner).call{value: payment}("");
        require(sent);
        (sent, ) = payable(FEE_SPLITTER).call{value: providerFee}("");
        require(sent); 
    }

    /**
     * @notice Refund for overpayment on rental and purchases
     * @param price cost of the transaction
     */
    function refundIfOver(uint256 price) private {
        if(msg.value < price) { revert InsufficientPayment(); }
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    /**
     * @notice Withdraws sewer passes from contract, sewer pass cannot be withdrawn if actively rented
     * @param passIds the tokenIds of sewer passes to withdraw from the rental contract
     */
    function withdrawPasses(uint256[] calldata passIds) external {
        address passOwner;
        for(uint256 i = 0;i < passIds.length;i++) {
            if(!isOwnerOrDelegate(msg.sender, passIds[i])) { revert NotPassOwner(); } // revert if msg.sender is not the owner of the pass or delegate
            if(rentalData[passIds[i]].rentalEnd >= block.timestamp) { revert PassCurrentlyRented(); } // revert if pass is currently on rent
            passOwner = passData[passIds[i]].passOwner;
            passData[passIds[i]] = CLEAR_PASS; // clean up state
            IERC721(SEWER_PASS).safeTransferFrom(address(this), passOwner, passIds[i]); // transfer pass back to owner
        }
    }

    /**
     * @notice Deposits passes to PlayMyPass and sets parameters
     * @param passIds array of sewer pass IDs to deposit to the rental contract, pass owner must setApprovalForAll on Sewer Pass to the rental contract
     * @param purchaseAllowed set if the pass is available for purchase
     * @param purchasePrice set the purchase price for the pass, price is in GWEI
     * @param hourlyRentalPrice set the hourly rental price for the pass, price is in GWEI
     */
    function depositPasses(uint256[] calldata passIds, bool[] calldata purchaseAllowed, uint40[] calldata purchasePrice, uint32[] calldata hourlyRentalPrice) external {
        require(passIds.length == purchaseAllowed.length 
            && purchaseAllowed.length == purchasePrice.length
            && purchasePrice.length == hourlyRentalPrice.length);

        PassData memory pd;
        pd.passOwner = msg.sender;
        pd.rentalAllowed = true;

        for(uint256 i = 0;i < passIds.length;i++) {
            if(IERC721(SEWER_PASS).ownerOf(passIds[i]) != msg.sender) { revert NotPassOwner(); } // revert if msg.sender is not the pass owner
            if(purchaseAllowed[i] && purchasePrice[i] == 0) { revert MustHaveValue(); } // revert if purchase is allowed but price is zero
            if(hourlyRentalPrice[i] == 0) { revert MustHaveValue(); } // revert if rental price is zero

            pd.passId = uint16(passIds[i]);
            pd.purchaseAllowed = purchaseAllowed[i];
            pd.purchasePrice = purchasePrice[i];
            pd.hourlyRentalPrice = hourlyRentalPrice[i];

            passData[passIds[i]] = pd; // store pass rental parameters
            IERC721(SEWER_PASS).safeTransferFrom(msg.sender, address(this), passIds[i]); // transfer pass to rental contract
        }
    }


    /**
     * @notice Updates pass rental/purchase parameters
     * @param passIds array of sewer pass IDs to update rental parameters
     * @param purchaseAllowed set if the pass is available for purchase
     * @param rentalAllowed set if the pass is available for rent
     * @param purchasePrice set the purchase price for the pass, price is in GWEI
     * @param hourlyRentalPrice set the hourly rental price for the pass, price is in GWEI
     */
    function updatePasses(uint256[] calldata passIds, bool[] calldata purchaseAllowed, bool[] calldata rentalAllowed, uint40[] calldata purchasePrice, uint32[] calldata hourlyRentalPrice) external {
        require(passIds.length == rentalAllowed.length 
            && rentalAllowed.length == purchaseAllowed.length
            && purchaseAllowed.length == purchasePrice.length
            && purchasePrice.length == hourlyRentalPrice.length);
        
        PassData memory pd;
        for(uint256 i = 0;i < passIds.length;i++) {
            pd = passData[passIds[i]];

            if(!isOwnerOrDelegate(msg.sender, passIds[i])) { revert NotPassOwner(); } // revert if msg.sender is not the owner or delegate for the sewer pass
            if(purchaseAllowed[i] && purchasePrice[i] == 0) { revert MustHaveValue(); } // revert if purchase is allowed but price is zero
            if(rentalAllowed[i] && hourlyRentalPrice[i] == 0) { revert MustHaveValue(); } // revert if rental is allowed but price is zero

            pd.purchaseAllowed = purchaseAllowed[i];
            pd.rentalAllowed = rentalAllowed[i];
            pd.purchasePrice = purchasePrice[i];
            pd.hourlyRentalPrice = hourlyRentalPrice[i];

            passData[passIds[i]] = pd;
        }
    }



    /**
     * @notice Receives sewer pass
                If transfer was not initiated by PlayMyPass contract, sets default values that do not allow purchase or rental
                Hot wallet delegate may update parameters after the pass is deposited by owner
     * @param operator account that initiated the safeTransferFrom
     * @param from account that owns the sewer pass and is transferring it into the rental contract
     * @param tokenId the tokenId for the sewer pass
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata) external returns (bytes4) {
        if(msg.sender != SEWER_PASS) { revert OnlySewerPass(); }
        if(operator != address(this)) { // if safeTransferFrom was not initiated by rental contract, store default parameters which do not allow for purchase or rental
            PassData memory pd;
            pd.passId = uint16(tokenId);
            pd.passOwner = from;
            passData[tokenId] = pd;
        }
        return IERC721Receiver.onERC721Received.selector;
    }



    /**
     * @notice Withdraws fees collected
     */
    function withdraw() external {
        payable(FEE_SPLITTER).transfer(address(this).balance);
    }
    

    /**
     * @notice Returns an array of sewer pass tokens for specified address
     * @param owner the account to get a list of sewer pass tokenIds for
     */
    function sewerpassTokenIds(address owner) external view returns(uint256[] memory tokenIds) {
        uint256 balance = IERC721(SEWER_PASS).balanceOf(owner);
        tokenIds = new uint256[](balance);
        for(uint256 tokenIndex = 0;tokenIndex < balance;tokenIndex++) {
            tokenIds[tokenIndex] = IERC721Enumerable(SEWER_PASS).tokenOfOwnerByIndex(owner, tokenIndex);
        }
    }

    /**
     * @notice Returns an array of sewer passes that are currently available to rent
     */
    function availableToRent() external view returns(PassData[] memory passes) {
        PassData[] memory tmpPasses = new PassData[](1000);
        uint256[] memory tmpTokenIds = this.sewerpassTokenIds(address(this));
        uint256 tmpIndex = 0;
        uint256 passTier;

        for(uint256 index = 0;index < tmpTokenIds.length;index++) {
            if((passData[tmpTokenIds[index]].rentalAllowed || passData[tmpTokenIds[index]].purchaseAllowed) && rentalData[tmpTokenIds[index]].rentalEnd < block.timestamp) {
                tmpPasses[tmpIndex] = passData[tmpTokenIds[index]];
                (passTier,,) = IBAYCSewerPass(SEWER_PASS).getMintDataByTokenId(tmpTokenIds[index]);
                tmpPasses[tmpIndex].boredPass = (passTier > 2);
                tmpPasses[tmpIndex].dogPass = (passTier % 2 == 0);
                tmpIndex++;
            }
        }

        passes = new PassData[](tmpIndex);
        for(uint256 index = 0;index < tmpIndex;index++) {
            passes[index] = tmpPasses[index];
        }
    }

    /**
     * @notice Returns an array of active passes owned by address
     * @param owner the account to list sewer passes deposited to the rental contract
     */
    function myPassesForRent(address owner) external view returns(PassData[] memory passes) {
        PassData[] memory tmpPasses = new PassData[](1000);
        uint256[] memory tmpTokenIds = this.sewerpassTokenIds(address(this));
        uint256 tmpIndex = 0;
        uint256 passTier;

        for(uint256 index = 0;index < tmpTokenIds.length;index++) {
            if(isOwnerOrDelegate(owner, tmpTokenIds[index])) {
                tmpPasses[tmpIndex] = passData[tmpTokenIds[index]];
                (passTier,,) = IBAYCSewerPass(SEWER_PASS).getMintDataByTokenId(tmpTokenIds[index]);
                tmpPasses[tmpIndex].boredPass = (passTier > 2);
                tmpPasses[tmpIndex].dogPass = (passTier % 2 == 0);
                tmpIndex++;
            }
        }

        passes = new PassData[](tmpIndex);
        for(uint256 index = 0;index < tmpIndex;index++) {
            passes[index] = tmpPasses[index];
        }
    }

    /**
     * @notice Returns an array of active pass rentals, includes cost to extend rental and if it can be extended
     * @param owner the address to check 
     */
    function myPassesRented(address owner) external view returns(PassRental[] memory rentals) {
        PassRental[] memory tmpRentals = new PassRental[](1000);
        uint256[] memory tmpTokenIds = this.sewerpassTokenIds(address(this));
        uint256 tmpIndex = 0;
        uint256 passTier;

        for(uint256 index = 0;index < tmpTokenIds.length;index++) {
            if(rentalData[tmpTokenIds[index]].rentalEnd >= block.timestamp && isOwnerOrDelegate(owner, tmpTokenIds[index])) {
                tmpRentals[tmpIndex] = rentalData[tmpTokenIds[index]];
                tmpRentals[tmpIndex].hourlyRentalPrice = passData[tmpTokenIds[index]].hourlyRentalPrice;
                tmpRentals[tmpIndex].cannotExtend = !passData[tmpTokenIds[index]].rentalAllowed;
                (passTier,,) = IBAYCSewerPass(SEWER_PASS).getMintDataByTokenId(tmpTokenIds[index]);
                tmpRentals[tmpIndex].boredPass = (passTier > 2);
                tmpRentals[tmpIndex].dogPass = (passTier % 2 == 0);
                tmpIndex++;
            }
        }

        rentals = new PassRental[](tmpIndex);
        for(uint256 index = 0;index < tmpIndex;index++) {
            rentals[index] = tmpRentals[index];
        }
    }

    /**
     * @notice Returns an array of active pass rentals, includes cost to extend rental and if it can be extended
     * @param renter the address to check for active rentals
     */
    function myRentals(address renter) external view returns(PassRental[] memory rentals) {
        PassRental[] memory tmpRentals = new PassRental[](1000);
        uint256[] memory tmpTokenIds = this.sewerpassTokenIds(address(this));
        uint256 tmpIndex = 0;
        uint256 passTier;

        for(uint256 index = 0;index < tmpTokenIds.length;index++) {
            if(rentalData[tmpTokenIds[index]].rentalEnd >= block.timestamp && rentalData[tmpTokenIds[index]].renter == renter) {
                tmpRentals[tmpIndex] = rentalData[tmpTokenIds[index]];
                tmpRentals[tmpIndex].hourlyRentalPrice = passData[tmpTokenIds[index]].hourlyRentalPrice;
                tmpRentals[tmpIndex].cannotExtend = !passData[tmpTokenIds[index]].rentalAllowed;
                (passTier,,) = IBAYCSewerPass(SEWER_PASS).getMintDataByTokenId(tmpTokenIds[index]);
                tmpRentals[tmpIndex].boredPass = (passTier > 2);
                tmpRentals[tmpIndex].dogPass = (passTier % 2 == 0);
                tmpIndex++;
            }
        }

        rentals = new PassRental[](tmpIndex);
        for(uint256 index = 0;index < tmpIndex;index++) {
            rentals[index] = tmpRentals[index];
        }
    }

    
    /**
     * @notice check to see if operator is owner or delegate via delegate cash
     * @param operator the address of the account to check for access
     * @param passId the tokenId of the sewer pass
     */
    function isOwnerOrDelegate(
        address operator,
        uint256 passId
    ) internal view returns (bool) {
        address tokenOwner = passData[passId].passOwner;

        return (operator == tokenOwner ||
            delegateCash.checkDelegateForToken(
                    operator,
                    tokenOwner,
                    SEWER_PASS,
                    passId
                ));
    }

    /**
     * @notice Rescue tokens that were sent to this contract without using safeTransferFrom. Only callable by the
     *         deployer, and disallows the deployer from removing the sponsored token.
               Borrowed from emo.eth Dookey4All
     */
    function rescueToken(address tokenAddress, bool erc20, uint256 id) external {
        // restrict to deployer
        if (msg.sender != DEPLOYER) {
            revert OnlyDeployer();
        }
        if (erc20) {
            // transfer entire ERC20 balance to the deployer
            IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
        } else {
            // allow rescuing sewer pass tokens, but not the sponsored token
            // sewer pass tokens which are *not* the sponsored token can be transferred using normal transferFrom
            // but the onERC721Received callback will not be invoked to register them as the sponsored token, so they
            // cannot be withdrawn otherwise
            if (tokenAddress == address(SEWER_PASS) && passData[id].passOwner != address(0)) {
                revert CannotRescueOwnedToken();
            }
            // transfer the token to the deployer
            IERC721(tokenAddress).transferFrom(address(this), msg.sender, id);
        }
        // no need to cover ERC1155 since they only implement safeTransferFrom, and this contract will reject them all
        // same with ether as there are no payable methods; those who selfdestruct, etc funds should expect to lose them
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBAYCSewerPass {
    function getMintDataByTokenId(uint256 tokenId) external view returns (uint256 tier, uint256 apeTokenId, uint256 dogTokenId);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

/**
 * @title An immutable registry contract to be deployed as a standalone primitive
 * @dev See EIP-5639, new project launches can read previous cold wallet -> hot wallet delegations
 * from here and integrate those permissions into their flow
 */
interface IDelegationRegistry {
    /// @notice Delegation type
    enum DelegationType {
        NONE,
        ALL,
        CONTRACT,
        TOKEN
    }

    /// @notice Info about a single delegation, used for onchain enumeration
    struct DelegationInfo {
        DelegationType type_;
        address vault;
        address delegate;
        address contract_;
        uint256 tokenId;
    }

    /// @notice Info about a single contract-level delegation
    struct ContractDelegation {
        address contract_;
        address delegate;
    }

    /// @notice Info about a single token-level delegation
    struct TokenDelegation {
        address contract_;
        uint256 tokenId;
        address delegate;
    }

    /// @notice Emitted when a user delegates their entire wallet
    event DelegateForAll(address vault, address delegate, bool value);

    /// @notice Emitted when a user delegates a specific contract
    event DelegateForContract(address vault, address delegate, address contract_, bool value);

    /// @notice Emitted when a user delegates a specific token
    event DelegateForToken(address vault, address delegate, address contract_, uint256 tokenId, bool value);

    /// @notice Emitted when a user revokes all delegations
    event RevokeAllDelegates(address vault);

    /// @notice Emitted when a user revoes all delegations for a given delegate
    event RevokeDelegate(address vault, address delegate);

    /**
     * -----------  WRITE -----------
     */

    /**
     * @notice Allow the delegate to act on your behalf for all contracts
     * @param delegate The hotwallet to act on your behalf
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForAll(address delegate, bool value) external;

    /**
     * @notice Allow the delegate to act on your behalf for a specific contract
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForContract(address delegate, address contract_, bool value) external;

    /**
     * @notice Allow the delegate to act on your behalf for a specific token
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param tokenId The token id for the token you're delegating
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForToken(address delegate, address contract_, uint256 tokenId, bool value) external;

    /**
     * @notice Revoke all delegates
     */
    function revokeAllDelegates() external;

    /**
     * @notice Revoke a specific delegate for all their permissions
     * @param delegate The hotwallet to revoke
     */
    function revokeDelegate(address delegate) external;

    /**
     * @notice Remove yourself as a delegate for a specific vault
     * @param vault The vault which delegated to the msg.sender, and should be removed
     */
    function revokeSelf(address vault) external;

    /**
     * -----------  READ -----------
     */

    /**
     * @notice Returns all active delegations a given delegate is able to claim on behalf of
     * @param delegate The delegate that you would like to retrieve delegations for
     * @return info Array of DelegationInfo structs
     */
    function getDelegationsByDelegate(address delegate) external view returns (DelegationInfo[] memory);

    /**
     * @notice Returns an array of wallet-level delegates for a given vault
     * @param vault The cold wallet who issued the delegation
     * @return addresses Array of wallet-level delegates for a given vault
     */
    function getDelegatesForAll(address vault) external view returns (address[] memory);

    /**
     * @notice Returns an array of contract-level delegates for a given vault and contract
     * @param vault The cold wallet who issued the delegation
     * @param contract_ The address for the contract you're delegating
     * @return addresses Array of contract-level delegates for a given vault and contract
     */
    function getDelegatesForContract(address vault, address contract_) external view returns (address[] memory);

    /**
     * @notice Returns an array of contract-level delegates for a given vault's token
     * @param vault The cold wallet who issued the delegation
     * @param contract_ The address for the contract holding the token
     * @param tokenId The token id for the token you're delegating
     * @return addresses Array of contract-level delegates for a given vault's token
     */
    function getDelegatesForToken(address vault, address contract_, uint256 tokenId)
        external
        view
        returns (address[] memory);

    /**
     * @notice Returns all contract-level delegations for a given vault
     * @param vault The cold wallet who issued the delegations
     * @return delegations Array of ContractDelegation structs
     */
    function getContractLevelDelegations(address vault)
        external
        view
        returns (ContractDelegation[] memory delegations);

    /**
     * @notice Returns all token-level delegations for a given vault
     * @param vault The cold wallet who issued the delegations
     * @return delegations Array of TokenDelegation structs
     */
    function getTokenLevelDelegations(address vault) external view returns (TokenDelegation[] memory delegations);

    /**
     * @notice Returns true if the address is delegated to act on the entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForAll(address delegate, address vault) external view returns (bool);

    /**
     * @notice Returns true if the address is delegated to act on your behalf for a token contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForContract(address delegate, address vault, address contract_)
        external
        view
        returns (bool);

    /**
     * @notice Returns true if the address is delegated to act on your behalf for a specific token, the token's contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param tokenId The token id for the token you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForToken(address delegate, address vault, address contract_, uint256 tokenId)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
interface IERC165 {
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