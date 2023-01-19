// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "@openzeppelin/utils/cryptography/ECDSA.sol";
import "@openzeppelin/utils/Address.sol";
import "@solmate/auth/Owned.sol";
import "@solmate/tokens/ERC20.sol";
import "@solmate/tokens/ERC721.sol";
import "@solmate/utils/FixedPointMathLib.sol";
import "@solmate/utils/ReentrancyGuard.sol";
import "@solmate/utils/SafeTransferLib.sol";
import "../../interfaces/IController.sol";
import "../../interfaces/ILoanLiquidator.sol";
import "../../interfaces/IVaultLoanValidator.sol";
import "../../interfaces/loans/ILoan.sol";
import "../../interfaces/IVaultFactory.sol";
import "../Vault.sol";
import "../utils/Hash.sol";

/// @title Single Source Loan
/// @author Florida St
/// @notice Loan that allows borrowers to take capital from one single vault
///         at a single point in time.
contract SingleSourceLoan is
    ERC721,
    ERC721TokenReceiver,
    ILoan,
    Owned,
    ReentrancyGuard
{
    using ECDSA for bytes32;
    using FixedPointMathLib for uint88;
    using Hash for LoanOffer;
    using Hash for FullSaleOrder;
    using SafeTransferLib for ERC20;

    uint256 liquidationAuctionDuration = 3 days;

    IVaultFactory private _vaultFactory;
    string baseURI = "";

    /// @notice Used in compliance with EIP712
    uint256 internal immutable INITIAL_CHAIN_ID;
    bytes32 public immutable INITIAL_DOMAIN_SEPARATOR;

    uint256 public override getTotalLoansIssued;
    mapping(uint256 => Loan) private _loans;

    /// @notice Used for validate off chain maker orders / canceling one
    mapping(address => mapping(uint256 => bool))
        public isOfferCancelledOrExecuted;
    /// @notice Used for validating off chain maker orders / canceling all
    mapping(address => uint256) public vaultMinOfferId;

    mapping(address => mapping(uint256 => bool))
        public isOrderCancelledOrExecuted;

    mapping(address => uint256) public userMinOrderId;

    ILoanLiquidator private _loanLiquidator;

    error LiquidatorOnlyError(address _liquidator);

    error CancelledOfferError(address _vaultAddress, uint256 _offerId);

    error ExpiredOfferError(uint32 _expirationTime);

    error UnauthorizedError(address _authorized);

    error LowOfferIdError(
        address _vaultAddress,
        uint256 _newMinOfferId,
        uint256 _minOfferId
    );

    error LoanNotFoundError(uint256 _loanId);

    error CannotLiquidateError();

    error LoanNotDueError(uint32 _expirationTime);

    error NullBorrowerError();

    error ZeroDurationError();

    error ZeroInterestError();

    error InvalidSignatureError();

    error NotMintedError(uint256 _id);

    error ClosedVaultError(address _vault);

    error SaleOrderCancelled(uint256 _orderId);

    error ExecuteSaleOnlyForVaultsError(address _notVault);

    error LowMinOrderIdError(uint256 _currentMin);

    error ExpiredLoanError();

    event LoanEmitted(
        address _lender,
        address _borrower,
        uint256 _loanId,
        address _nftCollateralAddress,
        uint256 _nftCollateralTokenId,
        address _principalAddress,
        uint88 _principalAmount,
        uint88 _totalInterest,
        uint32 _startTime,
        uint32 _duration,
        uint16 _managerPerformanceFeeBps
    );

    event OfferCancelled(address _vaultAddress, uint256 _offerId);

    event AllOffersCancelled(address _vaultAddress, uint256 _minOfferId);

    event LoanRepayed(
        uint256 _loanId,
        address _nftCollateralAddress,
        uint256 _nftCollateralTokenId,
        address _principalAddress,
        uint88 _principalAmount,
        uint88 _totalRepayment
    );

    event LiquidateLoan(uint256 _loanId, address _liquidator);

    event LoanLiquidated(uint256 _loanId, uint256 _repayment);

    event OrderCancelled(address _user, uint256 _orderId);

    event AllOrdersCancelled(address _user, uint256 _minOrderId);

    modifier onlyLiquidator() {
        if (msg.sender != address(_loanLiquidator)) {
            revert LiquidatorOnlyError(address(_loanLiquidator));
        }
        _;
    }

    constructor(address vaultFactory, address loanLiquidator)
        ERC721("FLORIDA_SINGLE_SOURCE_LOAN", "FSSL")
        Owned(msg.sender)
    {
        _vaultFactory = IVaultFactory(vaultFactory);
        _loanLiquidator = ILoanLiquidator(loanLiquidator);

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();
    }

    function updateLiquidationContract(ILoanLiquidator loanLiquidator)
        external
        onlyOwner
    {
        _loanLiquidator = loanLiquidator;
    }

    function updateLiquidationAuctionDuration(uint256 _newDuration)
        external
        onlyOwner
    {
        liquidationAuctionDuration = _newDuration;
    }

    function emitLoanFromContract(LoanOffer memory _loanOffer)
        external
        override
        returns (uint256)
    {
        Vault vault = Vault(_loanOffer.vaultAddress);

        address vaultControllerAddress = vault.getController();
        IController controller = IController(vaultControllerAddress);
        controller.validateOffer(_loanOffer);

        return _emitLoan(vault, _loanOffer);
    }

    function emitLoanWithSignature(
        LoanOffer calldata _loanOffer,
        bytes calldata _lenderOfferSignature
    ) external override returns (uint256) {
        address vaultAddress = _loanOffer.vaultAddress;
        uint256 offerId = _loanOffer.offerId;
        if (
            isOfferCancelledOrExecuted[vaultAddress][offerId] ||
            (offerId < vaultMinOfferId[vaultAddress])
        ) {
            revert CancelledOfferError(vaultAddress, offerId);
        }
        if (block.timestamp > _loanOffer.expirationTime) {
            revert ExpiredOfferError(_loanOffer.expirationTime);
        }

        Vault vault = Vault(vaultAddress);
        _checkSignatureLoanOffer(
            _loanOffer,
            _lenderOfferSignature,
            vault.getController()
        );

        return _emitLoan(vault, _loanOffer);
    }

    function executeSale(
        SaleOrder calldata _order,
        SaleSide calldata _buyer,
        SaleSide calldata _seller,
        bytes calldata _buyerSignature,
        bytes calldata _sellerSignature
    ) external nonReentrant {
        uint256 loanId = _order.loanId;
        address maybeVault = _ownerOf[loanId];

        if (!_vaultFactory.vaultExists(maybeVault)) {
            revert ExecuteSaleOnlyForVaultsError(maybeVault);
        }

        address seller = _seller.participant;
        address controller = Vault(maybeVault).getController();
        if (controller != seller) {
            revert UnauthorizedError(controller);
        }

        Loan storage loan = _loans[loanId];

        if (loan.borrower == address(0)) {
            revert LoanNotFoundError(loanId);
        }

        _validateSell(
            loan,
            FullSaleOrder(_order, _seller),
            maybeVault,
            _sellerSignature
        );

        _validateBuy(FullSaleOrder(_order, _buyer), _buyerSignature);

        ERC20(_order.asset).safeTransferFrom(
            _buyer.participant,
            maybeVault,
            _order.amount
        );

        _transferAfterSale(maybeVault, _buyer.participant, loanId);

        Vault(maybeVault).processRepayment(
            loanId,
            loan.principalAmount,
            _order.amount
        );
    }

    function cancelOffer(address _vaultAddress, uint256 _offerId) external {
        address controller = Vault(_vaultAddress).getController();
        if (msg.sender != controller) {
            revert UnauthorizedError(controller);
        }

        isOfferCancelledOrExecuted[_vaultAddress][_offerId] = true;

        emit OfferCancelled(_vaultAddress, _offerId);
    }

    function cancelOffers(address _vaultAddress, uint256[] calldata _offerIds)
        external
    {
        address controller = Vault(_vaultAddress).getController();
        if (msg.sender != controller) {
            revert UnauthorizedError(controller);
        }

        uint256 total = _offerIds.length;
        for (uint256 i = 0; i < total; ) {
            uint256 offerId = _offerIds[i];
            isOfferCancelledOrExecuted[_vaultAddress][offerId] = true;

            emit OfferCancelled(_vaultAddress, offerId);
            unchecked {
                ++i;
            }
        }
    }

    function cancelAllOffers(address _vaultAddress, uint256 _minOfferId)
        external
    {
        address controller = Vault(_vaultAddress).getController();
        if (msg.sender != controller) {
            revert UnauthorizedError(controller);
        }

        uint256 currentMinOfferId = vaultMinOfferId[_vaultAddress];
        if (currentMinOfferId > _minOfferId) {
            revert LowOfferIdError(
                _vaultAddress,
                _minOfferId,
                currentMinOfferId
            );
        }
        vaultMinOfferId[_vaultAddress] = _minOfferId;

        emit AllOffersCancelled(_vaultAddress, _minOfferId);
    }

    function cancelOrder(uint256 _orderId) external {
        address user = msg.sender;
        isOrderCancelledOrExecuted[user][_orderId] = true;

        emit OrderCancelled(user, _orderId);
    }

    function cancelOrders(uint256[] calldata _orderIds) external {
        address user = msg.sender;
        uint256 total = _orderIds.length;
        for (uint256 i = 0; i < total; ) {
            uint256 orderId = _orderIds[i];
            isOrderCancelledOrExecuted[user][orderId] = true;

            emit OrderCancelled(user, orderId);
            unchecked {
                ++i;
            }
        }
    }

    function cancelAllOrders(uint256 _minOrderId) external {
        address user = msg.sender;
        uint256 currentMinOrderId = userMinOrderId[user];
        if (_minOrderId < currentMinOrderId) {
            revert LowMinOrderIdError(currentMinOrderId);
        }

        userMinOrderId[user] = _minOrderId;

        emit AllOrdersCancelled(user, _minOrderId);
    }

    function repayLoan(address _collateralTo, uint256 _loanId)
        external
        override
        nonReentrant
    {
        Loan storage loan = _loans[_loanId];
        if (loan.borrower == address(0)) {
            revert LoanNotFoundError(_loanId);
        }

        if (msg.sender != loan.borrower) {
            revert UnauthorizedError(loan.borrower);
        }

        if (block.timestamp > loan.startTime + loan.duration) {
            revert ExpiredLoanError();
        }

        address lender = _ownerOf[_loanId];
        uint88 totalRepayment = uint88(
            loan.principalAmount +
                loan.totalInterest.mulDivUp(
                    uint88(block.timestamp) - uint88(loan.startTime),
                    uint88(loan.duration)
                )
        );

        ERC20(loan.principalAddress).safeTransferFrom(
            msg.sender,
            lender,
            totalRepayment
        );
        ERC721(loan.nftCollateralAddress).safeTransferFrom(
            address(this),
            _collateralTo,
            loan.nftCollateralTokenId
        );
        if (_vaultFactory.vaultExists(lender)) {
            Vault(lender).processRepayment(
                _loanId,
                loan.principalAmount,
                totalRepayment
            );
        }

        delete _loans[_loanId];
        _burn(_loanId);

        emit LoanRepayed(
            _loanId,
            loan.nftCollateralAddress,
            loan.nftCollateralTokenId,
            loan.principalAddress,
            loan.principalAmount,
            totalRepayment
        );
    }

    function liquidateLoan(uint256 _loanId) external override nonReentrant {
        Loan memory loan = _loans[_loanId];
        uint32 expirationTime = loan.startTime + loan.duration;
        ERC721 collateralCollection = ERC721(loan.nftCollateralAddress);

        if (
            collateralCollection.ownerOf(loan.nftCollateralTokenId) !=
            address(this)
        ) {
            revert CannotLiquidateError();
        }

        if (expirationTime > block.timestamp) {
            revert LoanNotDueError(expirationTime);
        }

        collateralCollection.safeTransferFrom(
            address(this),
            address(_loanLiquidator),
            loan.nftCollateralTokenId
        );
        _loanLiquidator.liquidateLoan(
            _loanId,
            loan.nftCollateralAddress,
            loan.nftCollateralTokenId,
            loan.principalAddress,
            _ownerOf[_loanId],
            abi.encode(liquidationAuctionDuration)
        );

        emit LiquidateLoan(_loanId, address(_loanLiquidator));
    }

    function loanLiquidated(uint256 _loanId, uint256 _repayment)
        external
        override
        nonReentrant
        onlyLiquidator
    {
        Loan storage loan = _loans[_loanId];
        address lender = _ownerOf[_loanId];
        if (_vaultFactory.vaultExists(lender)) {
            Vault(lender).processRepayment(
                _loanId,
                loan.principalAmount,
                _repayment
            );
        }

        delete _loans[_loanId];
        _burn(_loanId);

        emit LoanLiquidated(_loanId, _repayment);
    }

    function getLoan(uint256 _loanId) external view returns (Loan memory) {
        return _loans[_loanId];
    }

    function tokenURI(uint256 _id)
        public
        view
        override
        returns (string memory)
    {
        if (_ownerOf[_id] == address(0)) {
            revert NotMintedError(_id);
        }

        return string(abi.encodePacked(baseURI, _id));
    }

    function setBaseURI(string memory _baseURI) external override onlyOwner {
        baseURI = _baseURI;
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return
            block.chainid == INITIAL_CHAIN_ID
                ? INITIAL_DOMAIN_SEPARATOR
                : _computeDomainSeparator();
    }

    function _emitLoan(Vault _vault, LoanOffer memory _loanOffer)
        private
        nonReentrant
        returns (uint256)
    {
        address _vaultLoanValidator = _vaultFactory.getVaultLoanValidator(
            address(_vault)
        );
        IVaultLoanValidator(_vaultLoanValidator).validateOffer(_loanOffer);
        if (_vault.getVaultState() == IVault.VaultState.CLOSED) {
            revert ClosedVaultError(address(_vault));
        }

        if (_loanOffer.borrower == address(0)) {
            revert NullBorrowerError();
        }
        if (_loanOffer.duration == 0) {
            revert ZeroDurationError();
        }
        if (_loanOffer.totalInterest == 0) {
            revert ZeroInterestError();
        }

        address vaultAddress = address(_vault);
        Loan memory _loan = Loan(
            _loanOffer.borrower,
            _loanOffer.nftCollateralAddress,
            _loanOffer.nftCollateralTokenId,
            _loanOffer.principalAddress,
            _loanOffer.principalAmount,
            _loanOffer.totalInterest,
            uint32(block.timestamp),
            _loanOffer.duration,
            _loanOffer.managerPerformanceFeeBps
        );

        ERC721(_loan.nftCollateralAddress).safeTransferFrom(
            _loan.borrower,
            address(this),
            _loan.nftCollateralTokenId
        );
        ERC20(_loan.principalAddress).safeTransferFrom(
            vaultAddress,
            _loan.borrower,
            _loan.principalAmount
        );

        uint256 totalLoansIssued = getTotalLoansIssued + 1;
        getTotalLoansIssued = totalLoansIssued;

        _loans[totalLoansIssued] = _loan;
        isOfferCancelledOrExecuted[vaultAddress][_loanOffer.offerId] = true;
        _safeMint(
            vaultAddress,
            totalLoansIssued,
            abi.encode(_loan.principalAmount)
        );

        emit LoanEmitted(
            vaultAddress,
            _loan.borrower,
            totalLoansIssued,
            _loan.nftCollateralAddress,
            _loan.nftCollateralTokenId,
            _loan.principalAddress,
            _loan.principalAmount,
            _loan.totalInterest,
            _loan.startTime,
            _loan.duration,
            _loan.managerPerformanceFeeBps
        );
        return totalLoansIssued;
    }

    function _validateSell(
        Loan memory _loan,
        FullSaleOrder memory _order,
        address _sellerVault,
        bytes calldata _sellerSignature
    ) private view {
        uint256 sellerOrderId = _order.side.orderId;
        address controller = _order.side.participant;
        if (
            isOrderCancelledOrExecuted[controller][sellerOrderId] ||
            userMinOrderId[controller] > sellerOrderId
        ) {
            revert SaleOrderCancelled(sellerOrderId);
        }

        address _vaultLoanValidator = _vaultFactory.getVaultLoanValidator(
            _sellerVault
        );
        IVaultLoanValidator(_vaultLoanValidator).validateSell(
            _loan,
            _order,
            _sellerVault
        );
        if (Address.isContract(controller)) {
            IController(controller).validateSell(_loan, _order);
        } else {
            _checkSignatureSaleOrder(_order, _sellerSignature);
        }
    }

    function _validateBuy(
        FullSaleOrder memory _order,
        bytes calldata _buyerSignature
    ) private view {
        address buyer = _order.side.participant;
        uint256 buyerOrderId = _order.side.orderId;
        if (
            isOrderCancelledOrExecuted[buyer][buyerOrderId] ||
            userMinOrderId[buyer] > buyerOrderId
        ) {
            revert SaleOrderCancelled(buyerOrderId);
        }
        _checkSignatureSaleOrder(_order, _buyerSignature);
    }

    function _transferAfterSale(
        address _from,
        address _to,
        uint256 _id
    ) private {
        unchecked {
            _balanceOf[_from]--;
            _balanceOf[_to]++;
        }

        _ownerOf[_id] = _to;

        delete getApproved[_id];

        emit Transfer(_from, _to, _id);
    }

    function _checkSignatureLoanOffer(
        LoanOffer memory _loanOffer,
        bytes calldata _lenderOfferSignature,
        address _controller
    ) private view {
        bytes32 offerHash = _hashOffer(_loanOffer);
        bytes32 signedMessage = offerHash.toEthSignedMessageHash();

        if (signedMessage.recover(_lenderOfferSignature) != _controller) {
            revert InvalidSignatureError();
        }
    }

    function _hashOffer(LoanOffer memory _loanOffer)
        private
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    _loanOffer.hash()
                )
            );
    }

    function _checkSignatureSaleOrder(
        FullSaleOrder memory _order,
        bytes calldata _signature
    ) private view {
        bytes32 orderHash = _hashSaleOrder(_order);
        bytes32 signedMessage = orderHash.toEthSignedMessageHash();

        if (signedMessage.recover(_signature) != _order.side.participant) {
            revert InvalidSignatureError();
        }
    }

    function _hashSaleOrder(FullSaleOrder memory _saleOrder)
        private
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    _saleOrder.hash()
                )
            );
    }

    function _computeDomainSeparator() private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

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
        InvalidSignatureV // Deprecated in v4.8
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
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
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
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
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
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
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
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "./loans/ILoan.sol";

/// @title Automated Controller for Vaults
/// @author Florida St
/// @notice Emits and validates loans for a given vault.
interface IController {
    function validateOffer(ILoan.LoanOffer calldata _loanOffer) external;

    function validateSell(
        ILoan.Loan memory _loan,
        ILoan.FullSaleOrder memory _order
    ) external view;

    function getOffer(
        address _nftAddress,
        uint256 _tokenId,
        uint32 _duration,
        address _borrower
    ) external returns (ILoan.LoanOffer memory);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

/// @title Liquidates Collateral for Defaulted Loans
/// @author Florida St
/// @notice It liquidates collateral corresponding to defaulted loans
///         and sends back the proceeds to the vault.
interface ILoanLiquidator {
    /// @notice Given a loan, it takes posession of the NFT and liquidates it.
    ///         Then, it sends back the proceeds to the vault.
    function liquidateLoan(
        uint256 _loanId,
        address _contract,
        uint256 _tokenId,
        address _asset,
        address _vaultAddress,
        bytes memory _extraPayload
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "../interfaces/loans/ILoan.sol";

/// @title Vault Loan Validator
/// @author Florida St
/// @notice Validates a given offer complies with a Vault's constraints.
interface IVaultLoanValidator {
    function addVault(address _vault, bytes calldata _validatorParameters)
        external;

    function upgradeVault(
        address _vault,
        address _oldValidator,
        bytes calldata _newParameters
    ) external;

    function getAcceptedLoans() external view returns (address[] memory);

    function isLoanAccepted(address _loanAddress) external view returns (bool);

    function validateOffer(ILoan.LoanOffer calldata _loanOffer) external view;

    function validateSell(
        ILoan.Loan memory _loan,
        ILoan.FullSaleOrder memory _order,
        address _sellerVault
    ) external view;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

/// @title Interface for Loans.
/// @author Florida St
/// @notice Loans define the terms / dynamics and are issued by vaults.
interface ILoan {
    enum LoanStatus {
        NOT_FOUND,
        OUTSTANDING,
        IN_LIQUIDATION
    }

    struct SaleOrder {
        uint256 loanId;
        address asset;
        uint88 amount;
    }

    struct SaleSide {
        address participant;
        uint256 orderId;
    }

    struct FullSaleOrder {
        SaleOrder order;
        SaleSide side;
    }

    /// @notice Created when a loan is issued.
    struct Loan {
        address borrower;
        address nftCollateralAddress;
        uint256 nftCollateralTokenId;
        address principalAddress;
        uint88 principalAmount;
        uint88 totalInterest;
        uint32 startTime;
        uint32 duration;
        uint16 managerPerformanceFeeBps;
    }

    /// @notice Borrowers receive offers that are then validated.
    struct LoanOffer {
        uint256 offerId;
        address vaultAddress;
        address borrower;
        address nftCollateralAddress;
        uint256 nftCollateralTokenId;
        address principalAddress;
        uint88 principalAmount;
        uint88 totalInterest;
        uint32 expirationTime;
        uint32 duration;
        uint16 managerPerformanceFeeBps;
    }

    function getTotalLoansIssued() external view returns (uint256);

    function setBaseURI(string memory _baseURI) external;

    /// @notice Called when the controller for the vault is a smart contract.
    function emitLoanFromContract(LoanOffer memory _loanOffer)
        external
        returns (uint256);

    /// @notice Called when the controller for the vault is an EOA.
    function emitLoanWithSignature(
        LoanOffer memory _loanOffer,
        bytes calldata _lenderOfferSignature
    ) external returns (uint256);

    function executeSale(
        SaleOrder calldata _order,
        SaleSide calldata _buyer,
        SaleSide calldata _seller,
        bytes calldata _buyerSignature,
        bytes calldata _sellerSignature
    ) external;

    /// @notice Called by the borrower when repaying the loan.
    function repayLoan(address _collateralTo, uint256 _loanId) external;

    /// @notice Starts the liquidation process. Can be called by anyone.
    function liquidateLoan(uint256 _loanId) external;

    /// @notice Called by the liquidation contract once a liquidation is done for accounting.
    function loanLiquidated(uint256 _loanId, uint256 _repayment) external;

    /// @notice Cancel offers (they are off chain)
    function cancelOffer(address _vaultAddress, uint256 _offerId) external;

    /// @notice Cancell all offers with offerId < _minOfferId
    function cancelAllOffers(address _vaultAddress, uint256 _minOfferId)
        external;

    /// @notice Cancel one order (off chain as well)
    function cancelOrder(uint256 _orderId) external;

    /// @notice Cancel multiple specific orders
    function cancelOrders(uint256[] calldata _orderIds) external;

    /// @notice Cancell all orders with orderId < _minOrderId
    function cancelAllOrders(uint256 _minOrderId) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "../lib/Vault.sol";

/// @title Vault Factory
/// @author Florida St
/// @notice Deploys and keeps track of existing vaults
interface IVaultFactory {
    struct ProtocolFeeData {
        address protocolAddress;
        uint16 feeBps;
    }

    function vaultExists(address _maybeVault) external returns (bool);

    function deploy(
        Vault.Parameters calldata _vaultParameters,
        bytes calldata _validatorParameters
    ) external returns (address);

    function closeVault(address _vault) external;

    function getProtocolFeeData() external returns (ProtocolFeeData memory);

    function setProtocolFeeData(ProtocolFeeData calldata _data) external;

    function upgradeVaultLoanValidator(
        address _vaultAddress,
        bytes calldata _newParameters
    ) external;

    function getVaultLoanValidator(address _vault)
        external
        view
        returns (address);

    function removeAcceptedLoan(address _vault, address _loan) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "@openzeppelin/utils/structs/EnumerableSet.sol";
import "@solmate/mixins/ERC4626.sol";
import "@solmate/tokens/ERC721.sol";
import "@solmate/utils/FixedPointMathLib.sol";
import "@solmate/utils/ReentrancyGuard.sol";
import "@solmate/utils/SafeTransferLib.sol";
import "../interfaces/loans/ILoan.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IVaultFactory.sol";
import "./VaultLoanValidator.sol";

// TODO: When vault shut down, add redeem for user to get remaining (rounding)

contract Vault is ERC4626, ERC721TokenReceiver, IVault, ReentrancyGuard {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for ERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Parameters {
        uint64 maxDuration;
        address managerFeeRecipient;
        uint16 managerPerformanceFeeBps;
        address controller;
        uint48 redemptionTimeWindow;
        uint48 redemptionFrequency;
        uint256 maxCapacity;
        address[] originalAcceptedLoans;
        ERC20 asset;
        string name;
        string symbol;
    }

    // TODO: Update types
    uint256 public immutable override getStartTime;
    address public override getController;
    address public override getManagerFeeRecipient;
    uint16 public override getManagerPerformanceFeeBps;
    uint256 public override getFeesAccrued;
    uint256 public override getRedemptionFrequency;
    uint256 public override getRedemptionTimeWindowSize;
    uint256 public getMaxCapacity;
    bool public override isClosed;

    EnumerableSet.AddressSet private _acceptedLoans;

    uint256 public totalOutstanding;
    uint256 public totalPendingPool;
    mapping(uint256 => uint256) public pendingClaimPool;

    address private _vaultFactory;

    uint256 private _lastRedemptionPeriod;
    mapping(address => uint256) private _lastLoanIssued;

    uint256 private _totalAssetsPendingWithdrawal;
    mapping(uint256 => uint256) private _totalSharesSnapshot;
    mapping(uint256 => uint256) private _totalSharesPendingWithdrawal;
    mapping(uint256 => mapping(address => uint256))
        private _sharesPendingWithdrawal;

    event ClaimedManagerFees(uint256 _amount);

    event ProcessedRepayment(
        uint256 _loanId,
        uint256 _principal,
        uint256 _received,
        uint256 _protocolFee
    );

    event Claimed(address _user, uint256 _amount);

    event AcceptedLoan(address _loan);

    event RemovedLoan(address _loan);

    error UnauthorizedError(address _authorized);

    error OnlyLoanCallableError();

    error InvalidStateError();

    error OnlyManagerCallableError(address _expected);

    error MaxCapacityExceededError();

    error RemainingSharesError();

    error ZeroAssetsError();

    /// @notice Redemption Frequency must be higher than Max Duration + Liquidation Window
    constructor(Parameters memory parameters)
        ERC4626(parameters.asset, parameters.name, parameters.symbol)
    {
        getStartTime = block.timestamp;
        getManagerFeeRecipient = parameters.managerFeeRecipient;
        getController = parameters.controller;
        getManagerPerformanceFeeBps = parameters.managerPerformanceFeeBps;
        getRedemptionFrequency = parameters.redemptionFrequency;
        getRedemptionTimeWindowSize = parameters.redemptionTimeWindow;
        getMaxCapacity = parameters.maxCapacity;
        uint256 totalAcceptedLoans = parameters.originalAcceptedLoans.length;
        _vaultFactory = msg.sender;
        for (uint256 i = 0; i < totalAcceptedLoans; ) {
            address acceptedLoan = parameters.originalAcceptedLoans[i];
            _acceptedLoans.add(acceptedLoan);
            parameters.asset.safeApprove(acceptedLoan, type(uint256).max);
            unchecked {
                ++i;
            }
        }
    }

    modifier onlyLoanCallable() {
        if (!_acceptedLoans.contains(msg.sender)) {
            revert OnlyLoanCallableError();
        }
        _;
    }

    modifier onlyVaultFactory() {
        if (msg.sender != _vaultFactory) {
            revert UnauthorizedError(_vaultFactory);
        }
        _;
    }

    function addAcceptedLoans(address[] memory _loans)
        external
        onlyVaultFactory
    {
        uint256 total = _loans.length;
        for (uint256 i; i < total; ) {
            address thisLoan = _loans[i];
            if (!_acceptedLoans.contains(thisLoan)) {
                _acceptedLoans.add(thisLoan);
                asset.safeApprove(thisLoan, type(uint256).max);
            }
            unchecked {
                ++i;
            }
        }
    }

    function removeAcceptedLoan(address _loan) external onlyVaultFactory {
        _acceptedLoans.remove(_loan);
        asset.safeApprove(_loan, 0);
    }

    function closeVault(address _closer) external onlyVaultFactory {
        address controller = getController;
        if (_closer != controller) {
            revert UnauthorizedError(controller);
        }
        if (!_updateAndGetRedemptionState()) {
            revert InvalidStateError();
        }

        isClosed = true;
    }

    function withdrawRemainingFundsAndDestroy(address _claimer) external {
        address controller = getController;
        address recipient = getManagerFeeRecipient;
        if (_claimer != controller) {
            revert UnauthorizedError(controller);
        }

        if (totalSupply > 0) {
            revert RemainingSharesError();
        }
        asset.safeTransfer(recipient, totalAssets());
        selfdestruct(payable(recipient));
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override returns (uint256 shares) {
        if (!_updateAndGetRedemptionState()) {
            revert InvalidStateError();
        }
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max)
                allowance[owner][msg.sender] = allowed - shares;
        }

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        _afterWithdrawal(receiver, shares);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override returns (uint256 assets) {
        if (!_updateAndGetRedemptionState()) {
            revert InvalidStateError();
        }
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max)
                allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        if ((assets = previewRedeem(shares)) == 0) {
            revert ZeroAssetsError();
        }

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        _afterWithdrawal(receiver, shares);
    }

    function deposit(uint256 assets, address receiver)
        public
        override
        returns (uint256 shares)
    {
        if (assets + totalAssets() > getMaxCapacity) {
            revert MaxCapacityExceededError();
        }
        if (_updateAndGetRedemptionState()) {
            revert InvalidStateError();
        }
        shares = ERC4626.deposit(assets, receiver);
    }

    function mint(uint256 shares, address receiver)
        public
        override
        returns (uint256 assets)
    {
        if (_updateAndGetRedemptionState()) {
            revert InvalidStateError();
        }
        assets = ERC4626.mint(shares, receiver);
        if (assets + totalAssets() > getMaxCapacity) {
            revert MaxCapacityExceededError();
        }
    }

    function claimManagerFees() external nonReentrant {
        address recipient = getManagerFeeRecipient;
        if (msg.sender != recipient) {
            revert OnlyManagerCallableError(recipient);
        }
        uint256 amount = getFeesAccrued;
        getFeesAccrued = 0;
        asset.safeTransfer(recipient, amount);

        emit ClaimedManagerFees(amount);
    }

    function processRepayment(
        uint256 _loanId,
        uint256 _principal,
        uint256 _received
    ) external onlyLoanCallable {
        _updateAndGetRedemptionState();
        IVaultFactory.ProtocolFeeData memory protocolFeeData = IVaultFactory(
            _vaultFactory
        ).getProtocolFeeData();
        uint256 fee;
        uint256 poolAmount;
        uint256 protocolFee;
        unchecked {
            if (_received > _principal) {
                fee = (_received - _principal).mulDivDown(
                    getManagerPerformanceFeeBps,
                    10000
                );
                if (protocolFeeData.feeBps > 0) {
                    protocolFee = (_received - _principal).mulDivDown(
                        protocolFeeData.feeBps,
                        10000
                    );
                    asset.safeTransfer(
                        protocolFeeData.protocolAddress,
                        protocolFee
                    );
                }
            } else {
                fee = 0;
                protocolFee = 0;
            }
            poolAmount = _received - fee - protocolFee;
        }
        getFeesAccrued += fee;
        if (
            isClosed ||
            (_loanId < _lastLoanIssued[msg.sender] &&
                _totalSharesPendingWithdrawal[_lastRedemptionPeriod] > 0)
        ) {
            uint256 claimedPool = poolAmount.mulDivDown(
                _totalSharesPendingWithdrawal[_lastRedemptionPeriod],
                _totalSharesSnapshot[_lastRedemptionPeriod]
            );
            pendingClaimPool[_lastRedemptionPeriod] += claimedPool;
            totalPendingPool += claimedPool;
        }

        totalOutstanding -= _principal;

        emit ProcessedRepayment(_loanId, _principal, _received, protocolFee);
    }

    function totalAssets() public view override returns (uint256) {
        return
            asset.balanceOf(address(this)) - totalPendingPool - getFeesAccrued;
    }

    function previewDeposit(uint256 assets)
        public
        view
        override
        returns (uint256)
    {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return
            supply == 0
                ? assets
                : assets.mulDivDown(supply, totalAssets() + totalOutstanding);
    }

    function previewMint(uint256 shares)
        public
        view
        override
        returns (uint256)
    {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return
            supply == 0
                ? shares
                : shares.mulDivUp(totalAssets() + totalOutstanding, supply);
    }

    function getClaimable(uint256 _redemptionPeriod, address _userAddress)
        external
        view
        override
        returns (uint256)
    {
        return _getClaimable(_redemptionPeriod, _userAddress);
    }

    function claim(uint256 _redemptionPeriod) external override nonReentrant {
        address user = msg.sender;
        uint256 totalClaimable = _getClaimable(_redemptionPeriod, user);
        _sharesPendingWithdrawal[_redemptionPeriod][user] = 0;
        totalPendingPool -= totalClaimable;
        pendingClaimPool[_redemptionPeriod] -= totalClaimable;
        asset.safeTransfer(user, totalClaimable);

        emit Claimed(user, totalClaimable);
    }

    function claimMultiplePeriods(uint256[] calldata _redemptionPeriods)
        external
        override
        nonReentrant
    {
        address user = msg.sender;
        uint256 periods = _redemptionPeriods.length;
        uint256 totalClaimable = 0;
        for (uint256 i = 0; i < periods; ) {
            uint256 redemptionPeriod = _redemptionPeriods[i];
            totalClaimable += _getClaimable(redemptionPeriod, user);
            _sharesPendingWithdrawal[redemptionPeriod][user] = 0;
            totalPendingPool -= totalClaimable;
            pendingClaimPool[redemptionPeriod] -= totalClaimable;
        }
        asset.safeTransfer(user, totalClaimable);
    }

    function getVaultState() external view returns (IVault.VaultState) {
        if (isClosed) {
            return IVault.VaultState.CLOSED;
        }
        uint256 _startTime = getStartTime;
        uint256 _redemptionFrequency = getRedemptionFrequency;
        uint256 _currentTimestamp = block.timestamp;
        uint256 _startLastRedemptionPeriod = ((_currentTimestamp - _startTime) /
            _redemptionFrequency) *
            _redemptionFrequency +
            _startTime;
        return
            (_currentTimestamp <
                _startLastRedemptionPeriod + getRedemptionTimeWindowSize) &&
                (_startLastRedemptionPeriod != _startTime)
                ? IVault.VaultState.PROCESSING_REDEMPTIONS
                : IVault.VaultState.ACTIVE;
    }

    function getLastRedemptionPeriod() external view returns (uint256) {
        if (isClosed) {
            return _lastRedemptionPeriod;
        }
        uint256 _startTime = getStartTime;
        uint256 _redemptionFrequency = getRedemptionFrequency;
        return
            ((block.timestamp - _startTime) / _redemptionFrequency) *
            _redemptionFrequency +
            _startTime;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata data
    ) external override onlyLoanCallable returns (bytes4) {
        uint88 amount = abi.decode(data, (uint88));
        totalOutstanding += amount;
        return ERC721TokenReceiver.onERC721Received.selector;
    }

    function _getClaimable(uint256 _redemptionPeriod, address _userAddress)
        private
        view
        returns (uint256)
    {
        return
            pendingClaimPool[_redemptionPeriod].mulDivDown(
                _sharesPendingWithdrawal[_redemptionPeriod][_userAddress],
                _totalSharesPendingWithdrawal[_redemptionPeriod]
            );
    }

    function _updateAndGetRedemptionState() private returns (bool) {
        if (isClosed) {
            return true;
        }
        uint256 _startTime = getStartTime;
        uint256 _redemptionFrequency = getRedemptionFrequency;
        uint256 _startLastRedemptionPeriod = ((block.timestamp - _startTime) /
            _redemptionFrequency) *
            _redemptionFrequency +
            _startTime;
        if (_startLastRedemptionPeriod != _lastRedemptionPeriod) {
            _totalSharesSnapshot[_startLastRedemptionPeriod] = totalSupply;
            _lastRedemptionPeriod = _startLastRedemptionPeriod;
            uint256 totalLoans = _acceptedLoans.length();
            for (uint256 i = 0; i < totalLoans; ) {
                address loanAddress = _acceptedLoans.at(i);
                _lastLoanIssued[loanAddress] =
                    ILoan(loanAddress).getTotalLoansIssued() +
                    1;
                unchecked {
                    ++i;
                }
            }
        }
        return
            (block.timestamp <
                _startLastRedemptionPeriod + getRedemptionTimeWindowSize) &&
            _startLastRedemptionPeriod != _startTime;
    }

    function _afterWithdrawal(address _receiver, uint256 _shares) private {
        uint256 totalAssetsSnapshot = totalAssets() +
            pendingClaimPool[_lastRedemptionPeriod];
        uint256 movedToPending = _shares.mulDivDown(
            totalAssetsSnapshot,
            _totalSharesSnapshot[_lastRedemptionPeriod]
        );
        totalPendingPool += movedToPending;
        pendingClaimPool[_lastRedemptionPeriod] += movedToPending;
        _totalSharesPendingWithdrawal[_lastRedemptionPeriod] += _shares;
        _sharesPendingWithdrawal[_lastRedemptionPeriod][_receiver] += _shares;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "../../interfaces/loans/ILoan.sol";

library Hash {
    //keccak256("LoanOffer(uint256 offerId,address vaultAddress,address borrower,address nftCollateralAddress,uint256 nftCollateralTokenId,address principalAddress,uint88 principalAmount,uint88 totalInterest,uint32 expirationTime,uint32 duration,uint16 managerPerformanceFeeBps)")
    bytes32 private constant _LOAN_OFFER_HASH =
        0x0239ecaba4519edefd80c0e67c73344c135bb065941c40f62b172441aa6e4417;

    // keccack256("FullSaleOrder(SaleOrder order,SaleSide side)SaleOrder(uint256 loanId,address asset,uint88 amount)SaleSide(address participant,uint256 orderId)")
    bytes32 private constant _SALE_ORDER_HASH =
        0x2b4414adf8604917197fb6bf4b4279e906703355d02be6f1f91db1a6af06240f;

    function hash(ILoan.LoanOffer memory _loanOffer)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    _LOAN_OFFER_HASH,
                    _loanOffer.offerId,
                    _loanOffer.vaultAddress,
                    _loanOffer.borrower,
                    _loanOffer.nftCollateralAddress,
                    _loanOffer.nftCollateralTokenId,
                    _loanOffer.principalAddress,
                    _loanOffer.principalAmount,
                    _loanOffer.totalInterest,
                    _loanOffer.expirationTime,
                    _loanOffer.duration,
                    _loanOffer.managerPerformanceFeeBps
                )
            );
    }

    function hash(ILoan.FullSaleOrder memory _saleOrder)
        internal
        pure
        returns (bytes32)
    {
        ILoan.SaleOrder memory order = _saleOrder.order;
        ILoan.SaleSide memory side = _saleOrder.side;
        return
            keccak256(
                abi.encode(
                    _SALE_ORDER_HASH,
                    order.loanId,
                    order.asset,
                    order.amount,
                    side.participant,
                    side.orderId
                )
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
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
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

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
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
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
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
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
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
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
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
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
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";
import {SafeTransferLib} from "../utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "../utils/FixedPointMathLib.sol";

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/mixins/ERC4626.sol)
abstract contract ERC4626 is ERC20 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC20 public immutable asset;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol, _asset.decimals()) {
        asset = _asset;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual returns (uint256 shares) {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view virtual returns (uint256);

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf[owner]);
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function beforeWithdraw(uint256 assets, uint256 shares) internal virtual {}

    function afterDeposit(uint256 assets, uint256 shares) internal virtual {}
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "./loans/ILoan.sol";

/// @title Vault
/// @author Florida St
/// @notice Each vault is created and managed by an underwriter, takes capital
///         from LPs, and issues loans to borrowers.
interface IVault {
    enum VaultState {
        ACTIVE,
        PROCESSING_REDEMPTIONS,
        CLOSED
    }

    /// @notice Called by the underwriter to shutdown a vault
    function closeVault(address _closer) external;

    /// @notice Whether this vault is still active
    function isClosed() external returns (bool);

    /// @notice Vault's deployment time
    function getStartTime() external returns (uint256);

    /// @notice The vault's underwriter address
    function getManagerFeeRecipient() external returns (address);

    /// @notice Fees accrued by the underwriter (gains * performance fee)
    function getFeesAccrued() external returns (uint256);

    /// @notice Address of the controller (can be a contract or EOA)
    function getController() external returns (address);

    function getManagerPerformanceFeeBps() external returns (uint16);

    /// @notice Size for each redepmtion window
    function getRedemptionTimeWindowSize() external returns (uint256);

    /// @notice Frequency for redemptions
    function getRedemptionFrequency() external returns (uint256);

    /// @notice Add accepted loans when upgrading the validator
    function addAcceptedLoans(address[] memory _loans) external;

    /// @notice Only used for emergency. It shouldn't be necessary to get rid of
    ///         previous loans.
    function removeAcceptedLoan(address _loan) external;

    /// @notice Call when a loan is repaid or liquidated
    function processRepayment(
        uint256 _loanId,
        uint256 _principal,
        uint256 _received
    ) external;

    /// @notice Returns the beginning of the last redemption window
    function getLastRedemptionPeriod() external view returns (uint256);

    /// @notice Returns the vault state
    function getVaultState() external view returns (IVault.VaultState);

    /// @notice Return how much is claimable by an address for a given redemption period
    function getClaimable(uint256 _redemptionPeriod, address _userAddress)
        external
        view
        returns (uint256);

    /// @notice Claim assets for `msg.sender` for a given redemption period
    function claim(uint256 _redemptionPeriod) external;

    /// @notice Claim assets for `msg.sender` for multiple redemption periods
    function claimMultiplePeriods(uint256[] calldata _redemptionPeriods)
        external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "@solmate/auth/Owned.sol";
import "@solmate/utils/FixedPointMathLib.sol";
import "@openzeppelin/utils/structs/EnumerableSet.sol";
import "./Vault.sol";
import "../interfaces/IOracle.sol";
import "../interfaces/loans/ILoan.sol";
import "../interfaces/IVaultLoanValidator.sol";
import "./utils/ValidatorHelpers.sol";

contract VaultLoanValidator is IVaultLoanValidator, Owned {
    using ValidatorHelpers for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using FixedPointMathLib for uint128;

    enum ValidatorType {
        NFT_PACKED_LIST,
        NFT_BIT_VECTOR,
        FULL_COLLECTION,
        ORACLE
    }

    struct GenericValidator {
        ValidatorType validatorType;
        bytes arguments;
    }

    struct CollectionMaxLTV {
        address collection;
        uint88 maxLTV;
    }

    struct BaseVaultParameters {
        uint64 maxDuration;
        uint16 managerPerformanceFeeBps;
    }

    address private _vaultFactory;

    mapping(address => bytes) private _vaultGenericValidators;

    mapping(address => BaseVaultParameters) private _baseVaultParameters;

    address[] private _collectionPackedList;
    bytes[] private _tokenIdPackedList;

    address[] private _collectionBitVector;
    bytes[] private _tokenIdBitVector;

    EnumerableSet.AddressSet private _fullCollections;

    IOracle private _oracle;
    uint128 private _delayTolerance = 12 hours;
    CollectionMaxLTV[] private _collectionMaxLTVArray;

    mapping(address => uint88) _collectionMaxLTV; // 10000 precision

    EnumerableSet.AddressSet private _acceptedLoans;

    error ValidatorWithNoLoansError();

    error VaultNotExistError(address _vault);

    error OracleNotSetError();

    error UnauthorizedError(address _authorized);

    error TokenListAlreadySetError();

    error InvalidManagerFeeError(uint16 _expected);

    error MaxDurationExceededError(uint64 _expected);

    error InvalidAssetError(address _expected);

    error ArrayLengthNotMatchedError();

    error TokenIdNotFoundError(uint256 _tokenId);

    error InvalidLTVError(uint88 _expected);

    error StaleOracleError(uint128 _updatedTimestamp, uint128 _delayTolerance);

    modifier onlyVaultFactory() {
        if (msg.sender != _vaultFactory) {
            revert UnauthorizedError(_vaultFactory);
        }
        _;
    }

    constructor(address vaultFactory, address[] memory acceptedLoans)
        Owned(msg.sender)
    {
        _vaultFactory = vaultFactory;
        uint256 total = acceptedLoans.length;
        if (total == 0) {
            revert ValidatorWithNoLoansError();
        }
        for (uint256 i; i < total; ) {
            _acceptedLoans.add(acceptedLoans[i]);
            unchecked {
                i++;
            }
        }
    }

    function addVault(address _vault, bytes calldata _validatorParameters)
        external
        onlyVaultFactory
    {
        _addVault(_vault, _validatorParameters);
    }

    function upgradeVault(
        address _vault,
        address,
        bytes calldata _parameters
    ) external onlyVaultFactory {
        _addVault(_vault, _parameters);
    }

    function getAcceptedLoans() external view returns (address[] memory) {
        return _acceptedLoans.values();
    }

    function isLoanAccepted(address _loanAddress) external view returns (bool) {
        return _acceptedLoans.contains(_loanAddress);
    }

    function validateOffer(ILoan.LoanOffer calldata _loanOffer) external view {
        address _vault = _loanOffer.vaultAddress;
        BaseVaultParameters storage baseParams = _baseVaultParameters[_vault];
        if (baseParams.maxDuration == 0) {
            revert VaultNotExistError(_vault);
        }

        if (
            _loanOffer.managerPerformanceFeeBps !=
            baseParams.managerPerformanceFeeBps
        ) {
            revert InvalidManagerFeeError(baseParams.managerPerformanceFeeBps);
        }
        if (_loanOffer.duration > baseParams.maxDuration) {
            revert MaxDurationExceededError(baseParams.maxDuration);
        }

        address asset = address(Vault(_vault).asset());
        if (asset != _loanOffer.principalAddress) {
            revert InvalidAssetError(asset);
        }

        _checkOfferGenericValidators(
            abi.decode(_vaultGenericValidators[_vault], (GenericValidator[])),
            _loanOffer
        );
    }

    function _checkOfferGenericValidators(
        GenericValidator[] memory _validators,
        ILoan.LoanOffer memory _loanOffer
    ) private view {
        uint256 totalValidators = _validators.length;
        for (uint256 i = 0; i < totalValidators; ) {
            ValidatorType thisType = _validators[i].validatorType;
            bytes memory encodedArguments = _validators[i].arguments;
            if (thisType == ValidatorType.NFT_PACKED_LIST) {
                (
                    uint64 bytesPerTokenId,
                    address[] memory collections,
                    bytes[] memory tokenIds
                ) = abi.decode(encodedArguments, (uint64, address[], bytes[]));
                _validateNFTPackedList(
                    bytesPerTokenId,
                    collections,
                    tokenIds,
                    _loanOffer.nftCollateralAddress,
                    _loanOffer.nftCollateralTokenId
                );
            } else if (thisType == ValidatorType.NFT_BIT_VECTOR) {
                (address[] memory collections, bytes[] memory tokenIds) = abi
                    .decode(encodedArguments, (address[], bytes[]));
                _validateNFTBitVector(
                    collections,
                    tokenIds,
                    _loanOffer.nftCollateralAddress,
                    _loanOffer.nftCollateralTokenId
                );
            } else if (thisType == ValidatorType.FULL_COLLECTION) {
                address[] memory collections = abi.decode(
                    encodedArguments,
                    (address[])
                );
                _validateNFTFullCollection(
                    collections,
                    _loanOffer.nftCollateralAddress,
                    _loanOffer.nftCollateralTokenId
                );
            } else if (thisType == ValidatorType.ORACLE) {
                CollectionMaxLTV[] memory collectionMaxLTV = abi.decode(
                    encodedArguments,
                    (CollectionMaxLTV[])
                );
                _validateMaxCollectionLTV(
                    collectionMaxLTV,
                    _loanOffer.nftCollateralAddress,
                    _loanOffer.nftCollateralTokenId,
                    _loanOffer.principalAddress,
                    _loanOffer.principalAmount
                );
            }
            unchecked {
                ++i;
            }
        }
    }

    function validateSell(
        ILoan.Loan memory _loan,
        ILoan.FullSaleOrder memory _order,
        address _sellerVault
    ) external view {
        address asset = address(Vault(_sellerVault).asset());
        if (asset != _order.order.asset) {
            revert InvalidAssetError(asset);
        }
    }

    function getMaxDuration(address _vault) external view returns (uint64) {
        BaseVaultParameters storage params = _baseVaultParameters[_vault];
        if (params.maxDuration == 0) {
            revert VaultNotExistError(_vault);
        }
        return params.maxDuration;
    }

    function getManagerPerformanceFeeBps(address _vault)
        external
        view
        returns (uint16)
    {
        BaseVaultParameters storage params = _baseVaultParameters[_vault];
        if (params.maxDuration == 0) {
            revert VaultNotExistError(_vault);
        }
        return params.managerPerformanceFeeBps;
    }

    function getGenericValidators(address _vault)
        external
        view
        returns (GenericValidator[] memory)
    {
        return
            abi.decode(_vaultGenericValidators[_vault], (GenericValidator[]));
    }

    function getOracleAddress() external view returns (address) {
        return address(_oracle);
    }

    function getDelayTolerance() external view returns (uint128) {
        return _delayTolerance;
    }

    function updateOracle(address _newOracle) external onlyOwner {
        _oracle = IOracle(_newOracle);
    }

    function updateDelayTolerance(uint128 _newDelayTolerance)
        external
        onlyOwner
    {
        _delayTolerance = _newDelayTolerance;
    }

    function _verifyValidators(GenericValidator[] memory validators)
        private
        pure
    {
        bool mutuallyExclusive = false;
        uint256 totalValidators = validators.length;
        for (uint256 i = 0; i < totalValidators; ) {
            ValidatorType thisType = validators[i].validatorType;
            bytes memory encodedArguments = validators[i].arguments;
            if (thisType == ValidatorType.NFT_PACKED_LIST) {
                (
                    uint64 bytesPerTokenId,
                    address[] memory collections,
                    bytes[] memory tokenIds
                ) = abi.decode(encodedArguments, (uint64, address[], bytes[]));
                if (bytesPerTokenId == 0) {
                    revert ValidatorHelpers.InvalidBytesPerTokenIdError(0);
                }
                if (collections.length != tokenIds.length) {
                    revert ArrayLengthNotMatchedError();
                }
                if (mutuallyExclusive) {
                    revert TokenListAlreadySetError();
                }
                mutuallyExclusive = true;
            } else if (thisType == ValidatorType.NFT_BIT_VECTOR) {
                (address[] memory collections, bytes[] memory tokenIds) = abi
                    .decode(encodedArguments, (address[], bytes[]));
                if (collections.length != tokenIds.length) {
                    revert ArrayLengthNotMatchedError();
                }
                if (mutuallyExclusive) {
                    revert TokenListAlreadySetError();
                }
                mutuallyExclusive = true;
            } else if (thisType == ValidatorType.FULL_COLLECTION) {
                if (mutuallyExclusive) {
                    revert TokenListAlreadySetError();
                }
                mutuallyExclusive = true;
            }
            unchecked {
                ++i;
            }
        }
    }

    function _validateNFTPackedList(
        uint64 bytesPerTokenId,
        address[] memory collections,
        bytes[] memory tokenIdLists,
        address _collateralAddress,
        uint256 _tokenId
    ) private pure {
        bool found = false;
        for (uint256 i = 0; i < collections.length; ) {
            if (collections[i] == _collateralAddress) {
                _tokenId.validateTokenIdPackedList(
                    bytesPerTokenId,
                    tokenIdLists[i]
                );
                found = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
        if (!found) {
            revert TokenIdNotFoundError(_tokenId);
        }
    }

    function _validateNFTBitVector(
        address[] memory collections,
        bytes[] memory tokenIdVectors,
        address _collateralAddress,
        uint256 _tokenId
    ) private pure {
        bool found = false;
        for (uint256 i = 0; i < collections.length; ) {
            if (collections[i] == _collateralAddress) {
                _tokenId.validateNFTBitVector(tokenIdVectors[i]);
                found = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
        if (!found) {
            revert TokenIdNotFoundError(_tokenId);
        }
    }

    function _validateNFTFullCollection(
        address[] memory collections,
        address _collateralAddress,
        uint256 _tokenId
    ) private pure {
        uint256 total = collections.length;
        bool found = false;
        for (uint256 i; i < total; ) {
            if (collections[i] == _collateralAddress) {
                found = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
        if (!found) {
            revert TokenIdNotFoundError(_tokenId);
        }
    }

    function _validateMaxCollectionLTV(
        CollectionMaxLTV[] memory collectionMaxLTVs,
        address _collateralAddress,
        uint256 _tokenId,
        address _token,
        uint88 _amount
    ) private view {
        if (address(_oracle) == address(0)) {
            revert OracleNotSetError();
        }
        IOracle.PriceUpdate memory priceUpdate = _oracle.getPrice(
            _collateralAddress,
            _tokenId,
            _token
        );

        uint88 maxLTV = 0;
        uint256 total = collectionMaxLTVs.length;
        for (uint256 i; i < total; ) {
            CollectionMaxLTV memory thisMaxLTV = collectionMaxLTVs[i];
            if (thisMaxLTV.collection == _collateralAddress) {
                maxLTV = thisMaxLTV.maxLTV;
            }
            unchecked {
                ++i;
            }
        }
        if (maxLTV == 0) {
            revert InvalidLTVError(maxLTV);
        }

        if (
            (priceUpdate.price <= 0) ||
            (_amount >= priceUpdate.price.mulDivDown(maxLTV, 10000))
        ) {
            revert InvalidLTVError(maxLTV);
        }
        if (block.timestamp - priceUpdate.updatedTimestamp >= _delayTolerance) {
            revert StaleOracleError(
                priceUpdate.updatedTimestamp,
                _delayTolerance
            );
        }
    }

    function _addVault(address _vault, bytes calldata _validatorParameters)
        private
    {
        (
            uint64 maxDuration,
            uint16 managerPerformanceFeeBps,
            GenericValidator[] memory validators
        ) = abi.decode(
                _validatorParameters,
                (uint64, uint16, GenericValidator[])
            );
        _baseVaultParameters[_vault] = BaseVaultParameters(
            maxDuration,
            managerPerformanceFeeBps
        );
        _verifyValidators(validators);
        _vaultGenericValidators[_vault] = abi.encode(validators);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

/// @title Oracles
/// @author Florida St
/// @notice It retrieves prices for a given NFT in a specific currency.
interface IOracle {
    struct PriceUpdate {
        uint128 price;
        uint128 updatedTimestamp;
    }

    function getPrice(
        address _nftAddress,
        uint256 _tokenId,
        address _asset
    ) external view returns (PriceUpdate memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// TODO: Give credit

library ValidatorHelpers {

    error InvalidBytesPerTokenIdError(uint64 _bytesPerTokenId);

    error TokenIdNotFoundError(uint256 _tokenId);

    error BitVectorLengthExceededError(uint256 _tokenId);

    function validateTokenIdPackedList(
        uint256 _tokenId,
        uint64 _bytesPerTokenId,
        bytes memory _tokenIdList
    ) internal pure {
        if (
            _bytesPerTokenId == 0 || _bytesPerTokenId > 32
        ) {
            revert InvalidBytesPerTokenIdError(_bytesPerTokenId);
        }

        // Masks the lower `bytesPerTokenId` bytes of a word
        // So if `bytesPerTokenId` == 1, then bitmask = 0xff
        //    if `bytesPerTokenId` == 2, then bitmask = 0xffff, etc.
        uint256 bitMask = ~(type(uint256).max << (_bytesPerTokenId << 3));
        assembly {
            // Binary search for given token id

            let left := 1
            // right = number of tokenIds in the list
            let right := div(mload(_tokenIdList), _bytesPerTokenId)

            // while(left < right)
            for {} lt(left, right) {} {
                // mid = (left + right) / 2
                let mid := shr(1, add(left, right))
                // more or less equivalent to:
                // value = list[index]
                let offset := add(_tokenIdList, mul(mid, _bytesPerTokenId))
                let value := and(mload(offset), bitMask)
                // if (value < tokenId) {
                //     left = mid + 1;
                //     continue;
                // }
                if lt(value, _tokenId) {
                    left := add(mid, 1)
                    continue
                }
                // if (value > tokenId) {
                //     right = mid;
                //     continue;
                // }
                if gt(value, _tokenId) {
                    right := mid
                    continue
                }
                // if (value == tokenId) { return; }
                stop()
            }
            // At this point left == right; check if list[left] == tokenId
            let offset := add(_tokenIdList, mul(left, _bytesPerTokenId))
            let value := and(mload(offset), bitMask)
            if eq(value, _tokenId) {
                stop()
            }
        }
        revert TokenIdNotFoundError(_tokenId);
    }

    function validateNFTBitVector(uint256 _tokenId, bytes memory _bitVector)
        internal 
        pure
    {
        // tokenId < propertyData.length * 8
        if (_tokenId >= _bitVector.length << 3) {
            revert BitVectorLengthExceededError(_tokenId);
        }
        // Bit corresponding to tokenId must be set
        if (!(uint8(_bitVector[_tokenId >> 3]) & (0x80 >> (_tokenId & 7)) != 0)) {
           revert TokenIdNotFoundError(_tokenId);
        }
    }
}