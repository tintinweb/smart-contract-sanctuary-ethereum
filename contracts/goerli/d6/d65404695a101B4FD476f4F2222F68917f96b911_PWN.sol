// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.4;

import "./PWNVault.sol";
import "./PWNLOAN.sol";
import "@pwnfinance/multitoken/contracts/MultiToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PWN is Ownable {

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    PWNLOAN public LOAN;
    PWNVault public vault;

    /*----------------------------------------------------------*|
    |*  # EVENTS & ERRORS DEFINITIONS                           *|
    |*----------------------------------------------------------*/

    // No events nor error defined

    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR & FUNCTIONS                               *|
    |*----------------------------------------------------------*/

    /**
     * Constructor
     * @dev Establishes a connection with other pre-deployed components
     * @dev For the set up to work both PWNLOAN & PWNVault contracts have to called via `.setPWN(PWN.address)`
     * @param _PWNL Address of the PWNLOAN contract - defines LOAN tokens
     * @param _PWNV Address of the PWNVault contract - holds assets
     */
    constructor(
        address _PWNL,
        address _PWNV
    ) Ownable() {
        LOAN = PWNLOAN(_PWNL);
        vault = PWNVault(_PWNV);
    }

    /**
     * revokeOffer
     * @notice Lender can use this function to revoke their off-chain offers
     * @dev Can be called only from address that signed the offer
     * @param _offerHash Offer typed struct hash
     * @param _signature Offer typed struct signature
     * @return True if successful
     */
    function revokeOffer(
        bytes32 _offerHash,
        bytes calldata _signature
    ) external returns (bool) {
        LOAN.revokeOffer(_offerHash, _signature, msg.sender);

        return true;
    }

    /**
     * createLoan
     * @notice Borrower can accept existing signed off-chain offer
     * @dev A UI should do an off-chain balance check on the lender side to make sure the call won't throw
     * @dev Loan asset has to be an ERC20 token, otherwise will transaction fail
     * @param _offer Offer struct with plain offer data. See { PWNLOAN.sol }
     * @param _signature Offer typed struct signed by lender
     * @return True if successful
     */
    function createLoan(
        PWNLOAN.Offer memory _offer,
        bytes memory _signature
    ) external returns (bool) {
        LOAN.create(_offer, _signature, msg.sender);

        MultiToken.Asset memory collateral = MultiToken.Asset(
            _offer.collateralAddress,
            _offer.collateralCategory,
            _offer.collateralAmount,
            _offer.collateralId
        );

        MultiToken.Asset memory LoanAsset = MultiToken.Asset(
            _offer.loanAssetAddress,
            MultiToken.Category.ERC20,
            _offer.loanAmount,
            0
        );

        vault.pull(collateral, msg.sender);
        vault.pushFrom(LoanAsset, _offer.lender, msg.sender);

        return true;
    }

    /**
     * createFlexibleLoan
     * @notice Borrower can accept existing signed off-chain flexible offer
     * @dev A UI should do an off-chain balance check on the lender side to make sure the call won't throw
     * @dev LOAN asset has to be an ERC20 token, otherwise will transaction fail
     * @param _offer Flexible offer struct with plain flexible offer data. See { PWNLOAN.sol }
     * @param _offerValues Concrete values of a flexible offer set by borrower. See { PWNLOAN.sol }
     * @param _signature Flexible offer typed struct signed by lender
     * @return True if successful
     */
    function createFlexibleLoan(
        PWNLOAN.FlexibleOffer memory _offer,
        PWNLOAN.FlexibleOfferValues memory _offerValues,
        bytes memory _signature
    ) external returns (bool) {
        LOAN.createFlexible(_offer, _offerValues, _signature, msg.sender);

        MultiToken.Asset memory collateral = MultiToken.Asset(
            _offer.collateralAddress,
            _offer.collateralCategory,
            _offer.collateralAmount,
            _offerValues.collateralId
        );

        MultiToken.Asset memory LoanAsset = MultiToken.Asset(
            _offer.loanAssetAddress,
            MultiToken.Category.ERC20,
            _offerValues.loanAmount,
            0
        );

        vault.pull(collateral, msg.sender);
        vault.pushFrom(LoanAsset, _offer.lender, msg.sender);

        return true;
    }

    /**
     * repayLoan
     * @notice The borrower can pay back the loan through this function
     * @dev The function assumes the asset (and amount to be paid back) to be returned is approved for PWNVault
     * @dev The function assumes the borrower has the full amount to be paid back in their account
     * @param _loanId LOAN ID of the loan being paid back
     * @return True if successful
     */
    function repayLoan(uint256 _loanId) external returns (bool) {
        LOAN.repayLoan(_loanId);

        MultiToken.Asset memory LoanAsset = LOAN.getLoanAsset(_loanId);
        LoanAsset.amount = LOAN.getLoanRepayAmount(_loanId);

        vault.pull(LoanAsset, msg.sender);
        vault.push(LOAN.getCollateral(_loanId), LOAN.getBorrower(_loanId));

        return true;
    }

    /**
     * claimLoan
     * @dev The current LOAN owner can call this function if the loan is expired or paied back
     * @param _loanId LOAN ID of the loan to be claimed
     * @return True if successful
     */
    function claimLoan(uint256 _loanId) external returns (bool) {
        uint8 status = LOAN.getStatus(_loanId);

        LOAN.claim(_loanId, msg.sender);

        if (status == 3) {
            MultiToken.Asset memory LoanAsset = LOAN.getLoanAsset(_loanId);
            LoanAsset.amount = LOAN.getLoanRepayAmount(_loanId);

            vault.push(LoanAsset, msg.sender);
        } else if (status == 4) {
            vault.push(LOAN.getCollateral(_loanId), msg.sender);
        } else {
            revert("Invalid status code");
        }

        LOAN.burn(_loanId, msg.sender);

        return true;
    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.4;

import "@pwnfinance/multitoken/contracts/MultiToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

contract PWNVault is Ownable, IERC721Receiver, IERC1155Receiver {
    using MultiToken for MultiToken.Asset;

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    address public PWN;

    /*----------------------------------------------------------*|
    |*  # MODIFIERS                                             *|
    |*----------------------------------------------------------*/

    modifier onlyPWN() {
        require(msg.sender == PWN, "Caller is not the PWN");
        _;
    }

    /*----------------------------------------------------------*|
    |*  # EVENTS & ERRORS DEFINITIONS                           *|
    |*----------------------------------------------------------*/

    event VaultPull(MultiToken.Asset asset, address indexed origin);
    event VaultPush(MultiToken.Asset asset, address indexed beneficiary);
    event VaultPushFrom(MultiToken.Asset asset, address indexed origin, address indexed beneficiary);


    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR & FUNCTIONS                               *|
    |*----------------------------------------------------------*/

    /**
     * PWN Vault constructor
     * @dev this contract holds balances of all locked collateral & paid back loan prior to their rightful claims
     * @dev in order for the vault to work it has to have an association with the PWN logic via `.setPWN(PWN.address)`
     */
    constructor() Ownable() IERC1155Receiver() {
    }

    /**
     * pull
     * @dev function accessing an asset and pulling it INTO the vault
     * @dev the function assumes a prior token approval was made with the PWNVault.address to be approved
     * @param _asset An asset construct - for definition see { MultiToken.sol }
     * @return true if successful
     */
    function pull(MultiToken.Asset memory _asset, address _origin) external onlyPWN returns (bool) {
        _asset.transferAssetFrom(_origin, address(this));
        emit VaultPull(_asset, _origin);
        return true;
    }

    /**
     * push
     * @dev function pushing an asset FROM the vault, sending to a defined recipient
     * @dev this is used for claiming a paidback loan or defaulted collateral
     * @param _asset An asset construct - for definition see { MultiToken.sol }
     * @param _beneficiary An address of the recipient of the asset - is set in the PWN logic contract
     * @return true if successful
     */
    function push(MultiToken.Asset memory _asset, address _beneficiary) external onlyPWN returns (bool) {
        _asset.transferAsset(_beneficiary);
        emit VaultPush(_asset, _beneficiary);
        return true;
    }

    /**
     * pushFrom
     * @dev function pushing an asset FROM a lender, sending to a borrower
     * @dev this function assumes prior approval for the asset to be spend by the borrower address
     * @param _asset An asset construct - for definition see { MultiToken.sol }
     * @param _origin An address of the lender who is providing the loan asset
     * @param _beneficiary An address of the recipient of the asset - is set in the PWN logic contract
     * @return true if successful
     */
    function pushFrom(MultiToken.Asset memory _asset, address _origin, address _beneficiary) external onlyPWN returns (bool) {
        _asset.transferAssetFrom(_origin, _beneficiary);
        emit VaultPushFrom(_asset, _origin, _beneficiary);
        return true;
    }

    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * @return `IERC721Receiver.onERC721Received.selector` if transfer is allowed
     */
    function onERC721Received(
        address /*operator*/,
        address /*from*/,
        uint256 /*tokenId*/,
        bytes calldata /*data*/
    ) override external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
    
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     * To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address /*operator*/,
        address /*from*/,
        uint256 /*id*/,
        uint256 /*value*/,
        bytes calldata /*data*/
    ) override external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }
    
    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated. To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address /*operator*/,
        address /*from*/,
        uint256[] calldata /*ids*/,
        uint256[] calldata /*values*/,
        bytes calldata /*data*/
    ) override external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    /**
     * setPWN
     * @dev An essential setup function. Has to be called once PWN contract was deployed
     * @param _address Identifying the PWN contract
     */
    function setPWN(address _address) external onlyOwner {
        PWN = _address;
    }

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(Ownable).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == this.PWN.selector
                            ^ this.pull.selector
                            ^ this.push.selector
                            ^ this.pushFrom.selector
                            ^ this.setPWN.selector; // PWN Vault

    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.4;

import "@pwnfinance/multitoken/contracts/MultiToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract PWNLOAN is ERC1155, Ownable {

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    /**
     * Necessary msg.sender for all LOAN related manipulations
     */
    address public PWN;

    /**
     * Incremental LOAN ID counter
     */
    uint256 public id;

    /**
     * EIP-1271 valid signature magic value
     */
    bytes4 constant internal EIP1271_VALID_SIGNATURE = 0x1626ba7e;

    /**
     * EIP-712 offer struct type hash
     */
    bytes32 constant internal OFFER_TYPEHASH = keccak256(
        "Offer(address collateralAddress,uint8 collateralCategory,uint256 collateralAmount,uint256 collateralId,address loanAssetAddress,uint256 loanAmount,uint256 loanYield,uint32 duration,uint40 expiration,address lender,bytes32 nonce)"
    );

    /**
     * EIP-712 flexible offer struct type hash
     */
    bytes32 constant internal FLEXIBLE_OFFER_TYPEHASH = keccak256(
        "FlexibleOffer(address collateralAddress,uint8 collateralCategory,uint256 collateralAmount,bytes32 collateralIdsWhitelistMerkleRoot,address loanAssetAddress,uint256 loanAmountMax,uint256 loanAmountMin,uint256 loanYieldMax,uint32 durationMax,uint32 durationMin,uint40 expiration,address lender,bytes32 nonce)"
    );

    /**
     * Construct defining a LOAN which is an acronym for: ... (TODO)
     * @param status 0 == none/dead || 2 == running/accepted offer || 3 == paid back || 4 == expired
     * @param borrower Address of the borrower - stays the same for entire lifespan of the token
     * @param duration Loan duration in seconds
     * @param expiration Unix timestamp (in seconds) setting up the default deadline
     * @param collateral Asset used as a loan collateral. Consisting of another `Asset` struct defined in the MultiToken library
     * @param asset Asset to be borrowed by lender to borrower. Consisting of another `Asset` struct defined in the MultiToken library
     * @param loanRepayAmount Amount of LOAN asset to be repaid
     */
    struct LOAN {
        uint8 status;
        address borrower;
        uint32 duration;
        uint40 expiration;
        MultiToken.Asset collateral;
        MultiToken.Asset asset;
        uint256 loanRepayAmount;
    }

    /**
     * Construct defining an Offer
     * @param collateralAddress Address of an asset used as a collateral
     * @param collateralCategory Category of an asset used as a collateral (0 == ERC20, 1 == ERC721, 2 == ERC1155)
     * @param collateralAmount Amount of tokens used as a collateral, in case of ERC721 should be 1
     * @param collateralId Token id of an asset used as a collateral, in case of ERC20 should be 0
     * @param loanAssetAddress Address of an asset which is lended to borrower
     * @param loanAmount Amount of tokens which is offered as a loan to borrower
     * @param loanYield Amount of tokens which acts as a lenders loan interest. Borrower has to pay back borrowed amount + yield.
     * @param duration Loan duration in seconds
     * @param expiration Offer expiration timestamp in seconds
     * @param lender Address of a lender. This address has to sign an offer to be valid.
     * @param nonce Additional value to enable identical offers in time. Without it, it would be impossible to make again offer, which was once revoked.
     */
    struct Offer {
        address collateralAddress;
        MultiToken.Category collateralCategory;
        uint256 collateralAmount;
        uint256 collateralId;
        address loanAssetAddress;
        uint256 loanAmount;
        uint256 loanYield;
        uint32 duration;
        uint40 expiration;
        address lender;
        bytes32 nonce;
    }

    /**
     * Construct defining an Flexible offer
     * @param collateralAddress Address of an asset used as a collateral
     * @param collateralCategory Category of an asset used as a collateral (0 == ERC20, 1 == ERC721, 2 == ERC1155)
     * @param collateralAmount Amount of tokens used as a collateral, in case of ERC721 should be 1
     * @param collateralIdsWhitelistMerkleRoot Root of a merkle tree constructed on array of whitelisted collateral ids
     * @param loanAssetAddress Address of an asset which is lended to borrower
     * @param loanAmountMax Max amount of tokens which is offered as a loan to borrower
     * @param loanAmountMin Min amount of tokens which is offered as a loan to borrower
     * @param loanYieldMax Amount of tokens which acts as a lenders loan interest for max duration.
     * @param durationMax Max loan duration in seconds
     * @param durationMin Min loan duration in seconds
     * @param expiration Offer expiration timestamp in seconds
     * @param lender Address of a lender. This address has to sign a flexible offer to be valid.
     * @param nonce Additional value to enable identical offers in time. Without it, it would be impossible to make again offer, which was once revoked.
     */
    struct FlexibleOffer {
        address collateralAddress;
        MultiToken.Category collateralCategory;
        uint256 collateralAmount;
        bytes32 collateralIdsWhitelistMerkleRoot;
        address loanAssetAddress;
        uint256 loanAmountMax;
        uint256 loanAmountMin;
        uint256 loanYieldMax;
        uint32 durationMax;
        uint32 durationMin;
        uint40 expiration;
        address lender;
        bytes32 nonce;
    }

    /**
     * Construct defining an Flexible offer concrete values
     * @param collateralId Selected collateral id to be used as a collateral.
     * @param loanAmount Selected loan amount to be borrowed from lender.
     * @param duration Selected loan duration. Shorter duration reflexts into smaller loan yield for a lender.
     * @param merkleInclusionProof Proof of inclusion, that selected collateral id is whitelisted. This proof should create same hash as the merkle tree root given in flexible offer.
     */
    struct FlexibleOfferValues {
        uint256 collateralId;
        uint256 loanAmount;
        uint32 duration;
        bytes32[] merkleInclusionProof;
    }

    /**
     * Mapping of all LOAN data by loan id
     */
    mapping (uint256 => LOAN) public LOANs;

    /**
     * Mapping of revoked offers by offer struct typed hash
     */
    mapping (bytes32 => bool) public revokedOffers;

    /*----------------------------------------------------------*|
    |*  # EVENTS & ERRORS DEFINITIONS                           *|
    |*----------------------------------------------------------*/

    event LOANCreated(uint256 indexed loanId, address indexed lender, bytes32 indexed offerHash);
    event OfferRevoked(bytes32 indexed offerHash);
    event PaidBack(uint256 loanId);
    event LOANClaimed(uint256 loanId);

    /*----------------------------------------------------------*|
    |*  # MODIFIERS                                             *|
    |*----------------------------------------------------------*/

    modifier onlyPWN() {
        require(msg.sender == PWN, "Caller is not the PWN");
        _;
    }

    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR & FUNCTIONS                               *|
    |*----------------------------------------------------------*/

    /*
     * PWN LOAN constructor
     * @dev Creates the PWN LOAN token contract - ERC1155 with extra use case specific features
     * @dev Once the PWN contract is set, you'll have to call `this.setPWN(PWN.address)` for this contract to work
     * @param _uri Uri to be used for finding the token metadata
     */
    constructor(string memory _uri) ERC1155(_uri) Ownable() {

    }

    /**
     * All contracts of this section can only be called by the PWN contract itself - once set via `setPWN(PWN.address)`
     */

    /**
     * revokeOffer
     * @notice Revoke an offer
     * @dev Offer is revoked by lender or when offer is accepted by borrower to prevent accepting it twice
     * @param _offerHash Offer typed struct hash
     * @param _signature Offer typed struct signature
     * @param _sender Address of a message sender (lender)
     */
    function revokeOffer(
        bytes32 _offerHash,
        bytes calldata _signature,
        address _sender
    ) external onlyPWN {
        require(ECDSA.recover(_offerHash, _signature) == _sender, "Sender is not an offer signer");
        require(revokedOffers[_offerHash] == false, "Offer is already revoked or has been accepted");

        revokedOffers[_offerHash] = true;

        emit OfferRevoked(_offerHash);
    }

    /**
     * create
     * @notice Creates the PWN LOAN token - ERC1155 with extra use case specific features from simple offer
     * @dev Contract wallets need to implement EIP-1271 to validate signature on the contract behalf
     * @param _offer Offer struct holding plain offer data
     * @param _signature Offer typed struct signature signed by lender
     * @param _sender Address of a message sender (borrower)
     */
    function create(
        Offer memory _offer,
        bytes memory _signature,
        address _sender
    ) external onlyPWN {
        bytes32 offerHash = keccak256(abi.encodePacked(
            "\x19\x01", _eip712DomainSeparator(), hash(_offer)
        ));

        _checkValidSignature(_offer.lender, offerHash, _signature);
        _checkValidOffer(_offer.expiration, offerHash);

        revokedOffers[offerHash] = true;

        uint256 _id = ++id;

        LOAN storage loan = LOANs[_id];
        loan.status = 2;
        loan.borrower = _sender;
        loan.duration = _offer.duration;
        loan.expiration = uint40(block.timestamp) + _offer.duration;
        loan.collateral = MultiToken.Asset(
            _offer.collateralAddress,
            _offer.collateralCategory,
            _offer.collateralAmount,
            _offer.collateralId
        );
        loan.asset = MultiToken.Asset(
            _offer.loanAssetAddress,
            MultiToken.Category.ERC20,
            _offer.loanAmount,
            0
        );
        loan.loanRepayAmount = _offer.loanAmount + _offer.loanYield;

        _mint(_offer.lender, _id, 1, "");

        emit LOANCreated(_id, _offer.lender, offerHash);
    }

    /**
     * createFlexible
     * @notice Creates the PWN LOAN token - ERC1155 with extra use case specific features from flexible offer
     * @dev Contract wallets need to implement EIP-1271 to validate signature on the contract behalf
     * @param _offer Flexible offer struct holding plain flexible offer data
     * @param _offerValues Concrete values of a flexible offer set by borrower
     * @param _signature FlexibleOffer typed struct signature signed by lender
     * @param _sender Address of a message sender (borrower)
     */
    function createFlexible(
        FlexibleOffer memory _offer,
        FlexibleOfferValues memory _offerValues,
        bytes memory _signature,
        address _sender
    ) external onlyPWN {
        bytes32 offerHash = keccak256(abi.encodePacked(
            "\x19\x01", _eip712DomainSeparator(), hash(_offer)
        ));

        _checkValidSignature(_offer.lender, offerHash, _signature);
        _checkValidOffer(_offer.expiration, offerHash);

        // Flexible collateral id
        if (_offer.collateralIdsWhitelistMerkleRoot != bytes32(0x00)) {
            // Whitelisted collateral id
            bytes32 merkleTreeLeaf = keccak256(abi.encodePacked(_offerValues.collateralId));
            require(MerkleProof.verify(_offerValues.merkleInclusionProof, _offer.collateralIdsWhitelistMerkleRoot, merkleTreeLeaf), "Selected collateral id is not contained in whitelist");
        } // else: Any collateral id - collection offer

        // Flexible amount
        require(_offer.loanAmountMin <= _offerValues.loanAmount && _offerValues.loanAmount <= _offer.loanAmountMax, "Loan amount is not in offered range");

        // Flexible duration
        require(_offer.durationMin <= _offerValues.duration && _offerValues.duration <= _offer.durationMax, "Loan duration is not in offered range");

        revokedOffers[offerHash] = true;

        uint256 _id = ++id;

        LOAN storage loan = LOANs[_id];
        loan.status = 2;
        loan.borrower = _sender;
        loan.duration = _offerValues.duration;
        loan.expiration = uint40(block.timestamp) + _offerValues.duration;
        loan.collateral = MultiToken.Asset(
            _offer.collateralAddress,
            _offer.collateralCategory,
            _offer.collateralAmount,
            _offerValues.collateralId
        );
        loan.asset = MultiToken.Asset(
            _offer.loanAssetAddress,
            MultiToken.Category.ERC20,
            _offerValues.loanAmount,
            0
        );
        loan.loanRepayAmount = countLoanRepayAmount(
            _offerValues.loanAmount,
            _offerValues.duration,
            _offer.loanYieldMax,
            _offer.durationMax
        );

        _mint(_offer.lender, _id, 1, "");

        emit LOANCreated(_id, _offer.lender, offerHash);
    }

    /**
     * repayLoan
     * @notice Function to make proper state transition
     * @param _loanId ID of the LOAN which is paid back
     */
    function repayLoan(uint256 _loanId) external onlyPWN {
        require(getStatus(_loanId) == 2, "Loan is not running and cannot be paid back");

        LOANs[_loanId].status = 3;

        emit PaidBack(_loanId);
    }

    /**
     * claim
     * @notice Function that would set the LOAN to the dead state if the token is in paidBack or expired state
     * @param _loanId ID of the LOAN which is claimed
     * @param _owner Address of the LOAN token owner
     */
    function claim(
        uint256 _loanId,
        address _owner
    ) external onlyPWN {
        require(balanceOf(_owner, _loanId) == 1, "Caller is not the loan owner");
        require(getStatus(_loanId) >= 3, "Loan can't be claimed yet");

        LOANs[_loanId].status = 0;

        emit LOANClaimed(_loanId);
    }

    /**
     * burn
     * @notice Function that would burn the LOAN token if the token is in dead state
     * @param _loanId ID of the LOAN which is burned
     * @param _owner Address of the LOAN token owner
     */
    function burn(
        uint256 _loanId,
        address _owner
    ) external onlyPWN {
        require(balanceOf(_owner, _loanId) == 1, "Caller is not the loan owner");
        require(LOANs[_loanId].status == 0, "Loan can't be burned at this stage");

        delete LOANs[_loanId];
        _burn(_owner, _loanId, 1);
    }

    /**
     * countLoanRepayAmount
     * @notice Count a loan repay amount of flexible offer based on a loan amount and duration.
     * @notice The smaller the duration is, the smaller is the lenders yield.
     * @notice Loan repay amount is decreasing linearly from maximum duration and is fixing loans APR.
     * @param _loanAmount Selected amount of loan asset by borrower
     * @param _duration Selected loan duration by borrower
     * @param _loanYieldMax Yield for maximum loan duration set by lender in an offer
     * @param _durationMax Maximum loan duration set by lender in an offer
     */
    function countLoanRepayAmount(
        uint256 _loanAmount,
        uint32 _duration,
        uint256 _loanYieldMax,
        uint32 _durationMax
    ) public pure returns (uint256) {
        return _loanAmount + _loanYieldMax * _duration / _durationMax;
    }

    /*----------------------------------------------------------*|
    |*  ## VIEW FUNCTIONS                                       *|
    |*----------------------------------------------------------*/

    /**
     * getStatus
     * @dev used in contract calls & status checks and also in UI for elementary loan status categorization
     * @param _loanId LOAN ID checked for status
     * @return a status number
     */
    function getStatus(uint256 _loanId) public view returns (uint8) {
        if (LOANs[_loanId].expiration > 0 && LOANs[_loanId].expiration < block.timestamp && LOANs[_loanId].status != 3) {
            return 4;
        } else {
            return LOANs[_loanId].status;
        }
    }

    /**
     * getExpiration
     * @dev utility function to find out exact expiration time of a particular LOAN
     * @dev for simple status check use `this.getStatus(did)` if `status == 4` then LOAN has expired
     * @param _loanId LOAN ID to be checked
     * @return unix time stamp in seconds
     */
    function getExpiration(uint256 _loanId) external view returns (uint40) {
        return LOANs[_loanId].expiration;
    }

    /**
     * getDuration
     * @dev utility function to find out loan duration period of a particular LOAN
     * @param _loanId LOAN ID to be checked
     * @return loan duration period in seconds
     */
    function getDuration(uint256 _loanId) external view returns (uint32) {
        return LOANs[_loanId].duration;
    }

    /**
     * getBorrower
     * @dev utility function to find out a borrower address of a particular LOAN
     * @param _loanId LOAN ID to be checked
     * @return address of the borrower
     */
    function getBorrower(uint256 _loanId) external view returns (address) {
        return LOANs[_loanId].borrower;
    }

    /**
     * getCollateral
     * @dev utility function to find out collateral asset of a particular LOAN
     * @param _loanId LOAN ID to be checked
     * @return Asset construct - for definition see { MultiToken.sol }
     */
    function getCollateral(uint256 _loanId) external view returns (MultiToken.Asset memory) {
        return LOANs[_loanId].collateral;
    }

    /**
     * getLoanAsset
     * @dev utility function to find out loan asset of a particular LOAN
     * @param _loanId LOAN ID to be checked
     * @return Asset construct - for definition see { MultiToken.sol }
     */
    function getLoanAsset(uint256 _loanId) external view returns (MultiToken.Asset memory) {
        return LOANs[_loanId].asset;
    }

    /**
     * getLoanRepayAmount
     * @dev utility function to find out loan repay amount of a particular LOAN
     * @param _loanId LOAN ID to be checked
     * @return Amount of loan asset to be repaid
     */
    function getLoanRepayAmount(uint256 _loanId) external view returns (uint256) {
        return LOANs[_loanId].loanRepayAmount;
    }

    /**
     * isRevoked
     * @dev utility function to find out if offer is revoked
     * @param _offerHash Offer typed struct hash
     * @return True if offer is revoked
     */
    function isRevoked(bytes32 _offerHash) external view returns (bool) {
        return revokedOffers[_offerHash];
    }

    /*--------------------------------*|
    |*  ## SETUP FUNCTIONS            *|
    |*--------------------------------*/

    /**
     * setPWN
     * @dev An essential setup function. Has to be called once PWN contract was deployed
     * @param _address Identifying the PWN contract
     */
    function setPWN(address _address) external onlyOwner {
        PWN = _address;
    }

    /**
     * setUri
     * @dev An non-essential setup function. Can be called to adjust the LOAN token metadata URI
     * @param _newUri setting the new origin of LOAN metadata
     */
    function setUri(string memory _newUri) external onlyOwner {
        _setURI(_newUri);
    }

    /*--------------------------------*|
    |*  ## PRIVATE FUNCTIONS          *|
    |*--------------------------------*/

    /**
     * _eip712DomainSeparator
     * @notice Compose EIP712 domain separator
     * @dev Domain separator is composing to prevent repay attack in case of an Ethereum fork
     */
    function _eip712DomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes("PWN")),
            keccak256(bytes("1")),
            block.chainid,
            address(this)
        ));
    }

    /**
     * _checkValidSignature
     * @notice
     * @param _lender Address of a lender. This address has to sign an offer to be valid.
     * @param _offerHash Hash of an offer EIP-712 data struct
     * @param _signature Signed offer data
     */
    function _checkValidSignature(
        address _lender,
        bytes32 _offerHash,
        bytes memory _signature
    ) private view {
        if (_lender.code.length > 0) {
            require(IERC1271(_lender).isValidSignature(_offerHash, _signature) == EIP1271_VALID_SIGNATURE, "Signature on behalf of contract is invalid");
        } else {
            require(ECDSA.recover(_offerHash, _signature) == _lender, "Lender address didn't sign the offer");
        }
    }

    /**
     * _checkValidOffer
     * @notice
     * @param _expiration Offer expiration timestamp in seconds
     * @param _offerHash Hash of an offer EIP-712 data struct
     */
    function _checkValidOffer(
        uint40 _expiration,
        bytes32 _offerHash
    ) private view {
        require(_expiration == 0 || block.timestamp < _expiration, "Offer is expired");
        require(revokedOffers[_offerHash] == false, "Offer is revoked or has been accepted");
    }

    /**
     * hash offer
     * @notice Hash offer struct according to EIP-712
     * @param _offer Offer struct to be hashed
     * @return Offer struct hash
     */
    function hash(Offer memory _offer) private pure returns (bytes32) {
        return keccak256(abi.encode(
            OFFER_TYPEHASH,
            _offer.collateralAddress,
            _offer.collateralCategory,
            _offer.collateralAmount,
            _offer.collateralId,
            _offer.loanAssetAddress,
            _offer.loanAmount,
            _offer.loanYield,
            _offer.duration,
            _offer.expiration,
            _offer.lender,
            _offer.nonce
        ));
    }

    /**
     * hash offer
     * @notice Hash flexible offer struct according to EIP-712
     * @param _offer FlexibleOffer struct to be hashed
     * @return FlexibleOffer struct hash
     */
    function hash(FlexibleOffer memory _offer) private pure returns (bytes32) {
        // Need to divide encoding into smaller parts because of "Stack to deep" error

        bytes memory encodedOfferCollateralData = abi.encode(
            _offer.collateralAddress,
            _offer.collateralCategory,
            _offer.collateralAmount,
            _offer.collateralIdsWhitelistMerkleRoot
        );

        bytes memory encodedOfferLoanData = abi.encode(
            _offer.loanAssetAddress,
            _offer.loanAmountMax,
            _offer.loanAmountMin,
            _offer.loanYieldMax
        );

        bytes memory encodedOfferOtherData = abi.encode(
            _offer.durationMax,
            _offer.durationMin,
            _offer.expiration,
            _offer.lender,
            _offer.nonce
        );

        return keccak256(abi.encodePacked(
            FLEXIBLE_OFFER_TYPEHASH,
            encodedOfferCollateralData,
            encodedOfferLoanData,
            encodedOfferOtherData
        ));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

library MultiToken {

    /**
     * @title Category
     * @dev enum representation Asset category
     */
    enum Category {
        ERC20,
        ERC721,
        ERC1155
    }

    /**
     * @title Asset
     * @param assetAddress Address of the token contract defining the asset
     * @param category Corresponding asset category
     * @param amount Amount of fungible tokens or 0 -> 1
     * @param id TokenID of an NFT or 0
     */
    struct Asset {
        address assetAddress;
        Category category;
        uint256 amount;
        uint256 id;
    }

    /**
     * transferAsset
     * @dev wrapping function for transfer calls on various token interfaces
     * @param _asset Struct defining all necessary context of a token
     * @param _dest Destination address
     */
    function transferAsset(Asset memory _asset, address _dest) internal {
        if (_asset.category == Category.ERC20) {
            IERC20 token = IERC20(_asset.assetAddress);
            token.transfer(_dest, _asset.amount);

        } else if (_asset.category == Category.ERC721) {
            IERC721 token = IERC721(_asset.assetAddress);
            token.safeTransferFrom(address(this), _dest, _asset.id);

        } else if (_asset.category == Category.ERC1155) {
            IERC1155 token = IERC1155(_asset.assetAddress);
            if (_asset.amount == 0) {
                _asset.amount = 1;
            }
            token.safeTransferFrom(address(this), _dest, _asset.id, _asset.amount, "");

        } else {
            revert("MultiToken: Unsupported category");
        }
    }

    /**
     * transferAssetFrom
     * @dev wrapping function for transfer From calls on various token interfaces
     * @param _asset Struct defining all necessary context of a token
     * @param _source Account/address that provided the allowance
     * @param _dest Destination address
     */
    function transferAssetFrom(Asset memory _asset, address _source, address _dest) internal {
        if (_asset.category == Category.ERC20) {
            IERC20 token = IERC20(_asset.assetAddress);
            token.transferFrom(_source, _dest, _asset.amount);

        } else if (_asset.category == Category.ERC721) {
            IERC721 token = IERC721(_asset.assetAddress);
            token.safeTransferFrom(_source, _dest, _asset.id);

        } else if (_asset.category == Category.ERC1155) {
            IERC1155 token = IERC1155(_asset.assetAddress);
            if (_asset.amount == 0) {
                _asset.amount = 1;
            }
            token.safeTransferFrom(_source, _dest, _asset.id, _asset.amount, "");

        } else {
            revert("MultiToken: Unsupported category");
        }
    }

    /**
     * balanceOf
     * @dev wrapping function for checking balances on various token interfaces
     * @param _asset Struct defining all necessary context of a token
     * @param _target Target address to be checked
     */
    function balanceOf(Asset memory _asset, address _target) internal view returns (uint256) {
        if (_asset.category == Category.ERC20) {
            IERC20 token = IERC20(_asset.assetAddress);
            return token.balanceOf(_target);

        } else if (_asset.category == Category.ERC721) {
            IERC721 token = IERC721(_asset.assetAddress);
            if (token.ownerOf(_asset.id) == _target) {
                return 1;
            } else {
                return 0;
            }

        } else if (_asset.category == Category.ERC1155) {
            IERC1155 token = IERC1155(_asset.assetAddress);
            return token.balanceOf(_target, _asset.id);

        } else {
            revert("MultiToken: Unsupported category");
        }
    }

    /**
     * approveAsset
     * @dev wrapping function for approve calls on various token interfaces
     * @param _asset Struct defining all necessary context of a token
     * @param _target Target address to be checked
     */
    function approveAsset(Asset memory _asset, address _target) internal {
        if (_asset.category == Category.ERC20) {
            IERC20 token = IERC20(_asset.assetAddress);
            token.approve(_target, _asset.amount);

        } else if (_asset.category == Category.ERC721) {
            IERC721 token = IERC721(_asset.assetAddress);
            token.approve(_target, _asset.id);

        } else if (_asset.category == Category.ERC1155) {
            IERC1155 token = IERC1155(_asset.assetAddress);
            token.setApprovalForAll(_target, true);

        } else {
            revert("MultiToken: Unsupported category");
        }
    }

    /**
     * isValid
     * @dev checks that assets amount and id is valid in stated category
     * @dev this function don't check that stated category is indeed the category of a contract on a stated address
     * @param _asset Asset that is examined
     * @return True if assets amount and id is valid in stated category
     */
    function isValid(Asset memory _asset) internal pure returns (bool) {
        // ERC20 token has to have id set to 0
        if (_asset.category == Category.ERC20 && _asset.id != 0)
            return false;

        // ERC721 token has to have amount set to 1
        if (_asset.category == Category.ERC721 && _asset.amount != 1)
            return false;

        // Any categories have to have non-zero amount
        if (_asset.amount == 0)
            return false;

        return true;
    }

    /**
     * isSameAs
     * @dev compare two assets, ignoring their amounts
     * @param _asset First asset to examine
     * @param _otherAsset Second asset to examine
     * @return True if both structs represents the same asset
     */
    function isSameAs(Asset memory _asset, Asset memory _otherAsset) internal pure returns (bool) {
        return
            _asset.assetAddress == _otherAsset.assetAddress &&
            _asset.category == _otherAsset.category &&
            _asset.id == _otherAsset.id;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
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
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
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
        _setApprovalForAll(_msgSender(), operator, approved);
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
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
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
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
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
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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