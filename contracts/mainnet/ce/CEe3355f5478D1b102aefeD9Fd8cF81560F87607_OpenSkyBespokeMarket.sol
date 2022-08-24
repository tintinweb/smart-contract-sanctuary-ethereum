// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';

import '../dependencies/weth/IWETH.sol';
import '../libraries/math/PercentageMath.sol';
import '../libraries/math/WadRayMath.sol';
import '../libraries/math/MathUtils.sol';

import './libraries/BespokeTypes.sol';
import './libraries/BespokeLogic.sol';

import '../interfaces/IOpenSkySettings.sol';
import '../interfaces/IOpenSkyPool.sol';
import '../interfaces/IACLManager.sol';
import '../interfaces/IOpenSkyFlashClaimReceiver.sol';

import './interfaces/IOpenSkyBespokeLoanNFT.sol';
import './interfaces/IOpenSkyBespokeMarket.sol';
import './interfaces/IOpenSkyBespokeSettings.sol';

contract OpenSkyBespokeMarket is
    Context,
    Ownable,
    Pausable,
    ReentrancyGuard,
    ERC721Holder,
    ERC1155Holder,
    IOpenSkyBespokeMarket
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using PercentageMath for uint256;
    using WadRayMath for uint256;

    IOpenSkySettings public immutable SETTINGS;
    IOpenSkyBespokeSettings public immutable BESPOKE_SETTINGS;
    IWETH public immutable WETH;

    // ERC721 interfaceID
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    // ERC1155 interfaceID
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    mapping(address => uint256) public minNonce;
    mapping(address => mapping(uint256 => bool)) private _nonce;

    uint256 private _loanIdTracker;
    mapping(uint256 => BespokeTypes.LoanData) internal _loans;

    // nft address=> amount
    // tracking how many loans are ongoing for an nft
    mapping(address => uint256) public nftBorrowStat;

    constructor(
        address SETTINGS_,
        address BESPOKE_SETTINGS_,
        address WETH_
    ) Pausable() ReentrancyGuard() {
        SETTINGS = IOpenSkySettings(SETTINGS_);
        BESPOKE_SETTINGS = IOpenSkyBespokeSettings(BESPOKE_SETTINGS_);
        WETH = IWETH(WETH_);
    }

    /// @dev Only emergency admin can call functions marked by this modifier.
    modifier onlyEmergencyAdmin() {
        IACLManager ACLManager = IACLManager(SETTINGS.ACLManagerAddress());
        require(ACLManager.isEmergencyAdmin(_msgSender()), 'BM_ACL_ONLY_EMERGENCY_ADMIN_CAN_CALL');
        _;
    }

    modifier onlyAirdropOperator() {
        IACLManager ACLManager = IACLManager(SETTINGS.ACLManagerAddress());
        require(ACLManager.isAirdropOperator(_msgSender()), 'BM_ACL_ONLY_AIRDROP_OPERATOR_CAN_CALL');
        _;
    }

    modifier checkLoanExists(uint256 loanId) {
        require(_loans[loanId].reserveId > 0, 'BM_CHECK_LOAN_NOT_EXISTS');
        _;
    }

    /// @dev Pause pool for emergency case, can only be called by emergency admin.
    function pause() external onlyEmergencyAdmin {
        _pause();
    }

    /// @dev Unpause pool for emergency case, can only be called by emergency admin.
    function unpause() external onlyEmergencyAdmin {
        _unpause();
    }

    /// @notice Cancel all pending offers for a sender
    /// @param minNonce_ minimum user nonce
    function cancelAllBorrowOffersForSender(uint256 minNonce_) external {
        require(minNonce_ > minNonce[msg.sender], 'BM_CANCEL_NONCE_LOWER_THAN_CURRENT');
        require(minNonce_ < minNonce[msg.sender] + 500000, 'BM_CANCEL_CANNOT_CANCEL_MORE');
        minNonce[msg.sender] = minNonce_;

        emit CancelAllOffers(msg.sender, minNonce_);
    }

    /// @param offerNonces array of borrowOffer nonces
    function cancelMultipleBorrowOffers(uint256[] calldata offerNonces) external {
        require(offerNonces.length > 0, 'BM_CANCEL_CANNOT_BE_EMPTY');

        for (uint256 i = 0; i < offerNonces.length; i++) {
            require(offerNonces[i] >= minNonce[msg.sender], 'BM_CANCEL_NONCE_LOWER_THAN_CURRENT');
            _nonce[msg.sender][offerNonces[i]] = true;
        }

        emit CancelMultipleOffers(msg.sender, offerNonces);
    }

    function isValidNonce(address account, uint256 nonce) external view returns (bool) {
        return !_nonce[account][nonce] && nonce >= minNonce[account];
    }

    /// @notice take an borrowing offer using ERC20 include WETH
    function takeBorrowOffer(
        BespokeTypes.BorrowOffer memory offerData,
        uint256 supplyAmount,
        uint256 supplyDuration
    ) public override whenNotPaused nonReentrant {
        bytes32 offerHash = BespokeLogic.hashBorrowOffer(offerData);

        BespokeLogic.validateTakeBorrowOffer(
            _nonce,
            minNonce,
            offerData,
            offerHash,
            address(0),
            supplyAmount,
            supplyDuration,
            _getDomainSeparator(),
            BESPOKE_SETTINGS,
            SETTINGS
        );

        // prevents replay
        _nonce[offerData.borrower][offerData.nonce] = true;

        // transfer NFT
        _transferNFT(offerData.nftAddress, offerData.borrower, address(this), offerData.tokenId, offerData.tokenAmount);

        // oToken balance
        DataTypes.ReserveData memory reserve = IOpenSkyPool(SETTINGS.poolAddress()).getReserveData(offerData.reserveId);
        (uint256 oTokenToUse, uint256 inputAmount) = _calculateTokenToUse(
            offerData.reserveId,
            reserve.oTokenAddress,
            _msgSender(),
            supplyAmount
        );

        if (oTokenToUse > 0) {
            // transfer oToken from lender
            address oTokenAddress = IOpenSkyPool(SETTINGS.poolAddress())
                .getReserveData(offerData.reserveId)
                .oTokenAddress;
            IERC20(oTokenAddress).safeTransferFrom(_msgSender(), address(this), oTokenToUse);

            // withdraw underlying to borrower
            IOpenSkyPool(SETTINGS.poolAddress()).withdraw(offerData.reserveId, oTokenToUse, offerData.borrower);
        }

        if (inputAmount > 0) {
            IERC20(reserve.underlyingAsset).safeTransferFrom(_msgSender(), offerData.borrower, inputAmount);
        }

        uint256 loanId = _mintLoanNFT(offerData.borrower, _msgSender(), offerData.nftAddress);
        BespokeLogic.createLoan(_loans, offerData, loanId, supplyAmount, supplyDuration, BESPOKE_SETTINGS);

        emit TakeBorrowOffer(offerHash, loanId, _msgSender(), offerData.borrower, offerData.nonce);
    }

    /// @notice Take a borrow offer. Only for WETH reserve.
    /// @notice Consider using taker's oWETH balance first, then ETH if oWETH is not enough
    /// @notice Borrower will receive WETH
    function takeBorrowOfferETH(
        BespokeTypes.BorrowOffer memory offerData,
        uint256 supplyAmount,
        uint256 supplyDuration
    ) public payable override whenNotPaused nonReentrant {
        bytes32 offerHash = BespokeLogic.hashBorrowOffer(offerData);

        BespokeLogic.validateTakeBorrowOffer(
            _nonce,
            minNonce,
            offerData,
            offerHash,
            address(WETH),
            supplyAmount,
            supplyDuration,
            _getDomainSeparator(),
            BESPOKE_SETTINGS,
            SETTINGS
        );

        // prevents replay
        _nonce[offerData.borrower][offerData.nonce] = true;

        // transfer NFT
        _transferNFT(offerData.nftAddress, offerData.borrower, address(this), offerData.tokenId, offerData.tokenAmount);

        // oWeth balance
        address oTokenAddress = IOpenSkyPool(SETTINGS.poolAddress()).getReserveData(offerData.reserveId).oTokenAddress;
        (uint256 oTokenToUse, uint256 inputETH) = _calculateTokenToUse(
            offerData.reserveId,
            oTokenAddress,
            _msgSender(),
            supplyAmount
        );

        if (oTokenToUse > 0) {
            IERC20(oTokenAddress).safeTransferFrom(_msgSender(), address(this), oTokenToUse);
            // oWETH => WETH
            IOpenSkyPool(SETTINGS.poolAddress()).withdraw(offerData.reserveId, oTokenToUse, address(this));
        }
        if (inputETH > 0) {
            require(msg.value >= inputETH, 'BM_TAKE_BORROW_OFFER_ETH_INPUT_NOT_ENOUGH');
            // convert to WETH
            WETH.deposit{value: inputETH}();
        }

        // transfer WETH to borrower
        require(WETH.balanceOf(address(this)) >= supplyAmount, 'BM_TAKE_BORROW_OFFER_ETH_BALANCE_NOT_ENOUGH');
        WETH.transferFrom(address(this), offerData.borrower, supplyAmount);

        uint256 loanId = _mintLoanNFT(offerData.borrower, _msgSender(), offerData.nftAddress);
        BespokeLogic.createLoan(_loans, offerData, loanId, supplyAmount, supplyDuration, BESPOKE_SETTINGS);

        // refund remaining dust eth
        if (msg.value > inputETH) {
            uint256 refundAmount = msg.value - inputETH;
            _safeTransferETH(msg.sender, refundAmount);
        }

        emit TakeBorrowOfferETH(offerHash, loanId, _msgSender(), offerData.borrower, offerData.nonce);
    }

    /// @notice Only OpenSkyBorrowNFT owner can repay
    /// @notice Only OpenSkyLendNFT owner can recieve the payment
    /// @notice This function is not pausable for safety
    function repay(uint256 loanId) public override nonReentrant checkLoanExists(loanId) {
        BespokeTypes.LoanData memory loanData = getLoanData(loanId);
        require(
            loanData.status == BespokeTypes.LoanStatus.BORROWING || loanData.status == BespokeTypes.LoanStatus.OVERDUE,
            'BM_REPAY_STATUS_ERROR'
        );

        (address borrower, address lender) = _getLoanParties(loanId);
        require(_msgSender() == borrower, 'BM_REPAY_NOT_BORROW_NFT_OWNER');

        (uint256 repayTotal, uint256 lenderAmount, uint256 protocolFee) = _calculateRepayAmountAndProtocolFee(loanId);

        // repay oToken to lender
        address underlyingAsset = IOpenSkyPool(SETTINGS.poolAddress())
            .getReserveData(loanData.reserveId)
            .underlyingAsset;
        IERC20(underlyingAsset).safeTransferFrom(_msgSender(), address(this), repayTotal);
        IERC20(underlyingAsset).approve(SETTINGS.poolAddress(), lenderAmount);
        IOpenSkyPool(SETTINGS.poolAddress()).deposit(loanData.reserveId, lenderAmount, lender, 0);

        // dao vault
        if (protocolFee > 0) IERC20(underlyingAsset).safeTransfer(SETTINGS.daoVaultAddress(), protocolFee);

        // transfer nft back to borrower
        _transferNFT(loanData.nftAddress, address(this), borrower, loanData.tokenId, loanData.tokenAmount);

        _burnLoanNft(loanId, loanData.nftAddress);

        emit Repay(loanId, _msgSender());
    }

    /// @notice Only OpenSkyBorrowNFT owner can repay
    /// @notice Only OpenSkyLendNFT owner can recieve the payment
    /// @notice This function is not pausable for safety
    function repayETH(uint256 loanId) public payable override nonReentrant checkLoanExists(loanId) {
        BespokeTypes.LoanData memory loanData = getLoanData(loanId);
        address underlyingAsset = IOpenSkyPool(SETTINGS.poolAddress())
            .getReserveData(loanData.reserveId)
            .underlyingAsset;
        require(underlyingAsset == address(WETH), 'BM_REPAY_ETH_ASSET_NOT_MATCH');
        require(
            loanData.status == BespokeTypes.LoanStatus.BORROWING || loanData.status == BespokeTypes.LoanStatus.OVERDUE,
            'BM_REPAY_STATUS_ERROR'
        );

        (address borrower, address lender) = _getLoanParties(loanId);
        require(_msgSender() == borrower, 'BM_REPAY_NOT_BORROW_NFT_OWNER');

        (uint256 repayTotal, uint256 lenderAmount, uint256 protocolFee) = _calculateRepayAmountAndProtocolFee(loanId);

        require(msg.value >= repayTotal, 'BM_REPAY_ETH_INPUT_NOT_ENOUGH');

        // convert to weth
        WETH.deposit{value: repayTotal}();

        // transfer  to lender
        IERC20(underlyingAsset).approve(SETTINGS.poolAddress(), lenderAmount);
        IOpenSkyPool(SETTINGS.poolAddress()).deposit(loanData.reserveId, lenderAmount, lender, 0);

        // dao vault
        if (protocolFee > 0) IERC20(underlyingAsset).safeTransfer(SETTINGS.daoVaultAddress(), protocolFee);

        // transfer nft back to borrower
        _transferNFT(loanData.nftAddress, address(this), borrower, loanData.tokenId, loanData.tokenAmount);

        _burnLoanNft(loanId, loanData.nftAddress);

        // refund
        if (msg.value > repayTotal) _safeTransferETH(_msgSender(), msg.value - repayTotal);

        emit RepayETH(loanId, _msgSender());
    }

    /// @notice anyone can trigger but only OpenSkyLendNFT owner can receive collateral
    function foreclose(uint256 loanId) public override whenNotPaused nonReentrant checkLoanExists(loanId) {
        BespokeTypes.LoanData memory loanData = getLoanData(loanId);
        require(loanData.status == BespokeTypes.LoanStatus.LIQUIDATABLE, 'BM_FORECLOSE_STATUS_ERROR');

        (, address lender) = _getLoanParties(loanId);

        _transferNFT(loanData.nftAddress, address(this), lender, loanData.tokenId, loanData.tokenAmount);

        _burnLoanNft(loanId, loanData.nftAddress);

        emit Foreclose(loanId, _msgSender());
    }

    function getLoanData(uint256 loanId) public view override returns (BespokeTypes.LoanData memory) {
        BespokeTypes.LoanData memory loan = _loans[loanId];
        loan.status = getStatus(loanId);
        return loan;
    }

    function getStatus(uint256 loanId) public view override returns (BespokeTypes.LoanStatus) {
        BespokeTypes.LoanData memory loan = _loans[loanId];
        BespokeTypes.LoanStatus status = _loans[loanId].status;
        if (status == BespokeTypes.LoanStatus.BORROWING) {
            if (loan.liquidatableTime < block.timestamp) {
                status = BespokeTypes.LoanStatus.LIQUIDATABLE;
            } else if (loan.borrowOverdueTime < block.timestamp) {
                status = BespokeTypes.LoanStatus.OVERDUE;
            }
        }
        return status;
    }

    function getBorrowInterest(uint256 loanId) public view override returns (uint256) {
        BespokeTypes.LoanData memory loan = _loans[loanId];
        uint256 endTime = block.timestamp < loan.borrowOverdueTime ? loan.borrowOverdueTime : block.timestamp;
        return uint256(loan.interestPerSecond).rayMul(endTime.sub(loan.borrowBegin));
    }

    // @dev principal + fixed-price interest + extra interest(if overdue)
    function getBorrowBalance(uint256 loanId) public view override returns (uint256) {
        return _loans[loanId].amount.add(getBorrowInterest(loanId));
    }

    function getPenalty(uint256 loanId) public view override returns (uint256) {
        BespokeTypes.LoanData memory loan = getLoanData(loanId);
        uint256 penalty = 0;
        if (loan.status == BespokeTypes.LoanStatus.OVERDUE) {
            penalty = loan.amount.percentMul(BESPOKE_SETTINGS.overdueLoanFeeFactor());
        }
        return penalty;
    }

    function _calculateTokenToUse(
        uint256 reserveId,
        address oTokenAddress,
        address lender,
        uint256 supplyAmount
    ) internal view returns (uint256 oTokenToUse, uint256 inputAmount) {
        uint256 oTokenBalance = IERC20(oTokenAddress).balanceOf(lender);
        uint256 availableLiquidity = IOpenSkyPool(SETTINGS.poolAddress()).getAvailableLiquidity(reserveId);
        oTokenBalance = availableLiquidity > oTokenBalance ? oTokenBalance : availableLiquidity;
        oTokenToUse = oTokenBalance < supplyAmount ? oTokenBalance : supplyAmount;
        inputAmount = oTokenBalance < supplyAmount ? supplyAmount.sub(oTokenBalance) : 0;
    }

    function _calculateRepayAmountAndProtocolFee(uint256 loanId)
        internal
        view
        returns (
            uint256 total,
            uint256 lenderAmount,
            uint256 protocolFee
        )
    {
        uint256 penalty = getPenalty(loanId);
        total = getBorrowBalance(loanId).add(penalty);
        protocolFee = getBorrowInterest(loanId).add(penalty).percentMul(BESPOKE_SETTINGS.reserveFactor());
        lenderAmount = total.sub(protocolFee);
    }

    function _safeTransferETH(address recipient, uint256 amount) internal {
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'BM_ETH_TRANSFER_FAILED');
    }

    function _mintLoanNFT(
        address borrower,
        address lender,
        address relatedCollateralNft
    ) internal returns (uint256) {
        _loanIdTracker = _loanIdTracker + 1;
        uint256 tokenId = _loanIdTracker;

        IOpenSkyBespokeLoanNFT(BESPOKE_SETTINGS.borrowLoanAddress()).mint(tokenId, borrower);
        IOpenSkyBespokeLoanNFT(BESPOKE_SETTINGS.lendLoanAddress()).mint(tokenId, lender);

        nftBorrowStat[relatedCollateralNft] += 1;
        return tokenId;
    }

    function _burnLoanNft(uint256 tokenId, address relatedCollateralNft) internal {
        IOpenSkyBespokeLoanNFT(BESPOKE_SETTINGS.borrowLoanAddress()).burn(tokenId);
        IOpenSkyBespokeLoanNFT(BESPOKE_SETTINGS.lendLoanAddress()).burn(tokenId);
        nftBorrowStat[relatedCollateralNft] -= 1;
        delete _loans[tokenId];
    }

    function _getLoanParties(uint256 loanId) internal returns (address borrower, address lender) {
        lender = IERC721(BESPOKE_SETTINGS.lendLoanAddress()).ownerOf(loanId);
        borrower = IERC721(BESPOKE_SETTINGS.borrowLoanAddress()).ownerOf(loanId);
    }

    //
    /// @dev transfer ERC20 from the utility contract, for ERC20 recovery in case of stuck tokens due
    /// direct transfers to the contract address.
    /// @param token token to transfer
    /// @param to recipient of the transfer
    /// @param amount amount to send
    function emergencyTokenTransfer(
        address token,
        address to,
        uint256 amount
    ) external onlyEmergencyAdmin {
        IERC20(token).safeTransfer(to, amount);
    }

    /// @inheritdoc IOpenSkyBespokeMarket
    function flashClaim(
        address receiverAddress,
        uint256[] calldata loanIds,
        bytes calldata params
    ) external override {
        uint256 i;
        IOpenSkyFlashClaimReceiver receiver = IOpenSkyFlashClaimReceiver(receiverAddress);
        // !!!CAUTION: receiver contract may reentry mint, burn, flashClaim again

        // only loan owner can do flashClaim
        address[] memory nftAddresses = new address[](loanIds.length);
        uint256[] memory tokenIds = new uint256[](loanIds.length);
        for (i = 0; i < loanIds.length; i++) {
            require(
                IERC721(BESPOKE_SETTINGS.borrowLoanAddress()).ownerOf(loanIds[i]) == _msgSender(),
                'BM_FLASHCLAIM_CALLER_IS_NOT_OWNER'
            );
            BespokeTypes.LoanData memory loanData = getLoanData(loanIds[i]);
            require(loanData.status != BespokeTypes.LoanStatus.LIQUIDATABLE, 'BM_FLASHCLAIM_STATUS_ERROR');
            nftAddresses[i] = loanData.nftAddress;
            tokenIds[i] = loanData.tokenId;
        }

        // step 1: moving underlying asset forward to receiver contract
        for (i = 0; i < loanIds.length; i++) {
            IERC721(nftAddresses[i]).safeTransferFrom(address(this), receiverAddress, tokenIds[i]);
        }

        // setup 2: execute receiver contract, doing something like aidrop
        require(
            receiver.executeOperation(nftAddresses, tokenIds, _msgSender(), address(this), params),
            'BM_FLASHCLAIM_EXECUTOR_ERROR'
        );

        // setup 3: moving underlying asset backword from receiver contract
        for (i = 0; i < loanIds.length; i++) {
            IERC721(nftAddresses[i]).safeTransferFrom(receiverAddress, address(this), tokenIds[i]);
            emit FlashClaim(receiverAddress, _msgSender(), nftAddresses[i], tokenIds[i]);
        }
    }

    /// @inheritdoc IOpenSkyBespokeMarket
    function claimERC20Airdrop(
        address token,
        address to,
        uint256 amount
    ) external override onlyAirdropOperator {
        // make sure that params are checked in admin contract
        IERC20(token).safeTransfer(to, amount);
        emit ClaimERC20Airdrop(token, to, amount);
    }

    /// @inheritdoc IOpenSkyBespokeMarket
    function claimERC721Airdrop(
        address token,
        address to,
        uint256[] calldata ids
    ) external override onlyAirdropOperator {
        require(nftBorrowStat[token] == 0, 'BM_CLAIM_ERC721_AIRDROP_NOT_SUPPORTED');
        // make sure that params are checked in admin contract
        for (uint256 i = 0; i < ids.length; i++) {
            IERC721(token).safeTransferFrom(address(this), to, ids[i]);
        }
        emit ClaimERC721Airdrop(token, to, ids);
    }

    /// @inheritdoc IOpenSkyBespokeMarket
    function claimERC1155Airdrop(
        address token,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external override onlyAirdropOperator {
        require(nftBorrowStat[token] == 0, 'BM_CLAIM_ERC1155_AIRDROP_NOT_SUPPORTED');
        // make sure that params are checked in admin contract
        IERC1155(token).safeBatchTransferFrom(address(this), to, ids, amounts, data);
        emit ClaimERC1155Airdrop(token, to, ids, amounts, data);
    }

    function _transferNFT(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal {
        if (IERC165(collection).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721(collection).safeTransferFrom(from, to, tokenId);
        } else if (IERC165(collection).supportsInterface(INTERFACE_ID_ERC1155)) {
            IERC1155(collection).safeTransferFrom(from, to, tokenId, amount, '');
        } else {
            revert('BM_NFT_NOT_SUPPORTED');
        }
    }

    function _getDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f, // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                    0xf0cf7ce475272740cae17eb3cadd6d254800be81c53f84a2f273b99036471c62, // keccak256("OpenSkyBespokeMarket")
                    0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, // keccak256(bytes("1")) for versionId = 1
                    block.chainid,
                    address(this)
                )
            );
    }

    receive() external payable {
        revert('BM_RECEIVE_NOT_ALLOWED');
    }

    fallback() external payable {
        revert('BM_FALLBACK_NOT_ALLOWED');
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
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
}

pragma solidity 0.8.10;

interface IWETH {
    function balanceOf(address) external view returns (uint256);

    function deposit() external payable;

    function withdraw(uint256) external;

    function approve(address guy, uint256 wad) external returns (bool);

    function transfer(address dst, uint256 wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '../helpers/Errors.sol';

/**
 * @title PercentageMath library
 * @author Aave
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded half up
 **/

library PercentageMath {
  uint256 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
  uint256 constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;

  /**
   * @dev Executes a percentage multiplication
   * @param value The value of which the percentage needs to be calculated
   * @param percentage The percentage of the value to be calculated
   * @return The percentage of value
   **/
  function percentMul(uint256 value, uint256 percentage) internal pure returns (uint256) {
    if (value == 0 || percentage == 0) {
      return 0;
    }

    require(
      value <= (type(uint256).max - HALF_PERCENT) / percentage,
      Errors.MATH_MULTIPLICATION_OVERFLOW
    );

    return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR;
  }

  /**
   * @dev Executes a percentage division
   * @param value The value of which the percentage needs to be calculated
   * @param percentage The percentage of the value to be calculated
   * @return The value divided the percentage
   **/
  function percentDiv(uint256 value, uint256 percentage) internal pure returns (uint256) {
    require(percentage != 0, Errors.MATH_DIVISION_BY_ZERO);
    uint256 halfPercentage = percentage / 2;

    require(
      value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR,
      Errors.MATH_MULTIPLICATION_OVERFLOW
    );

    return (value * PERCENTAGE_FACTOR + halfPercentage) / percentage;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {Errors} from '../helpers/Errors.sol';

/**
 * @title WadRayMath library
 * @author Aave
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 **/

library WadRayMath {
    uint256 internal constant WAD = 1e18;
    uint256 internal constant halfWAD = WAD / 2;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant halfRAY = RAY / 2;

    uint256 internal constant WAD_RAY_RATIO = 1e9;

    /**
     * @return One ray, 1e27
     **/
    function ray() internal pure returns (uint256) {
        return RAY;
    }

    /**
     * @return One wad, 1e18
     **/

    function wad() internal pure returns (uint256) {
        return WAD;
    }

    /**
     * @return Half ray, 1e27/2
     **/
    function halfRay() internal pure returns (uint256) {
        return halfRAY;
    }

    /**
     * @return Half ray, 1e18/2
     **/
    function halfWad() internal pure returns (uint256) {
        return halfWAD;
    }

    /**
     * @dev Multiplies two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a*b, in wad
     **/
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        require(a <= (type(uint256).max - halfWAD) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

        return (a * b + halfWAD) / WAD;
    }

    /**
     * @dev Divides two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a/b, in wad
     **/
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
        uint256 halfB = b / 2;

        require(a <= (type(uint256).max - halfB) / WAD, Errors.MATH_MULTIPLICATION_OVERFLOW);

        return (a * WAD + halfB) / b;
    }

    /**
     * @dev Multiplies two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a*b, in ray
     **/
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        require(a <= (type(uint256).max - halfRAY) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

        return (a * b + halfRAY) / RAY;
    }

    /**
     * @dev Multiplies two ray, truncating the mantissa
     * @param a Ray
     * @param b Ray
     * @return The result of a*b, in ray
     **/
    function rayMulTruncate(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        return (a * b) / RAY;
    }

    /**
     * @dev Divides two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a/b, in ray
     **/
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
        uint256 halfB = b / 2;

        require(a <= (type(uint256).max - halfB) / RAY, Errors.MATH_MULTIPLICATION_OVERFLOW);

        return (a * RAY + halfB) / b;
    }

    /**
     * @dev Divides two ray, truncating the mantissa
     * @param a Ray
     * @param b Ray
     * @return The result of a/b, in ray
     **/
    function rayDivTruncate(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
        return (a * RAY) / b;
    }

    /**
     * @dev Casts ray down to wad
     * @param a Ray
     * @return a casted to wad, rounded half up to the nearest wad
     **/
    function rayToWad(uint256 a) internal pure returns (uint256) {
        uint256 halfRatio = WAD_RAY_RATIO / 2;
        uint256 result = halfRatio + a;
        require(result >= halfRatio, Errors.MATH_ADDITION_OVERFLOW);

        return result / WAD_RAY_RATIO;
    }

    /**
     * @dev Converts wad up to ray
     * @param a Wad
     * @return a converted in ray
     **/
    function wadToRay(uint256 a) internal pure returns (uint256) {
        uint256 result = a * WAD_RAY_RATIO;
        require(result / WAD_RAY_RATIO == a, Errors.MATH_MULTIPLICATION_OVERFLOW);
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {WadRayMath} from './WadRayMath.sol';

library MathUtils {
    using WadRayMath for uint256;

    /// @dev Ignoring leap years
    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    /**
     * @dev Function to calculate the interest accumulated using a linear interest rate formula
     * @param rate The interest rate, in ray
     * @param lastUpdateTimestamp The timestamp of the last update of the interest
     * @return The interest rate linearly accumulated during the timeDelta, in ray
     **/

    function calculateLinearInterest(uint256 rate, uint40 lastUpdateTimestamp) external view returns (uint256) {
        //solium-disable-next-line
        uint256 timeDifference = block.timestamp - (uint256(lastUpdateTimestamp));

        return (rate * timeDifference) / SECONDS_PER_YEAR + WadRayMath.ray();
    }

    function calculateBorrowInterest(
        uint256 borrowRate,
        uint256 amount,
        uint256 duration
    ) external pure returns (uint256) {
        return amount.rayMul(borrowRate.rayMul(duration).rayDiv(SECONDS_PER_YEAR));
    }

    function calculateBorrowInterestPerSecond(uint256 borrowRate, uint256 amount) external pure returns (uint256) {
        return amount.rayMul(borrowRate).rayDiv(SECONDS_PER_YEAR);
    }

    function calculateLoanSupplyRate(
        uint256 availableLiquidity,
        uint256 totalBorrows,
        uint256 borrowRate
    ) external pure returns (uint256 loanSupplyRate, uint256 utilizationRate) {
        utilizationRate = (totalBorrows == 0 && availableLiquidity == 0)
            ? 0
            : totalBorrows.rayDiv(availableLiquidity + totalBorrows);
        loanSupplyRate = utilizationRate.rayMul(borrowRate);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library BespokeTypes {
    struct BorrowOffer {
        uint256 reserveId;
        address nftAddress;
        uint256 tokenId;
        uint256 tokenAmount; // 1 for ERC721, 1+ for ERC1155
        address borrower;
        uint256 borrowAmountMin;
        uint256 borrowAmountMax;
        uint40 borrowDurationMin;
        uint40 borrowDurationMax;
        uint128 borrowRate;
        address currency;
        uint256 nonce;
        uint256 deadline;
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    struct LoanData {
        uint256 reserveId;
        address nftAddress;
        uint256 tokenId;
        uint256 tokenAmount; // 1 for ERC721, 1+ for ERC1155
        address borrower;
        uint256 amount;
        uint128 borrowRate;
        uint128 interestPerSecond;
        address currency;
        uint40 borrowDuration;
        // after take offer
        uint40 borrowBegin;
        uint40 borrowOverdueTime;
        uint40 liquidatableTime;
        address lender;
        LoanStatus status;
    }

    enum LoanStatus {
        NONE,
        BORROWING,
        OVERDUE,
        LIQUIDATABLE
    }

    struct WhitelistInfo {
        bool enabled;
        uint256 minBorrowDuration;
        uint256 maxBorrowDuration;
        uint256 overdueDuration;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

import '../../libraries/math/MathUtils.sol';
import '../../libraries/math/WadRayMath.sol';
import '../../interfaces/IOpenSkyPool.sol';
import '../../interfaces/IOpenSkySettings.sol';

import './BespokeTypes.sol';
import './SignatureChecker.sol';
import '../interfaces/IOpenSkyBespokeSettings.sol';

library BespokeLogic {
    using WadRayMath for uint256;
    using SafeMath for uint256;

    // keccak256("BorrowOffer(uint256 reserveId,address nftAddress,uint256 tokenId,uint256 tokenAmount,address borrower,uint256 borrowAmountMin,uint256 borrowAmountMax,uint40 borrowDurationMin,uint40 borrowDurationMax,uint128 borrowRate,address currency,uint256 nonce,uint256 deadline)")
    bytes32 internal constant BORROW_OFFER_HASH = 0xacdf87371514724eb8e74db090d21dbc2361a02a72e2facac480fe7964ae4feb;

    function hashBorrowOffer(BespokeTypes.BorrowOffer memory offerData) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    BORROW_OFFER_HASH,
                    offerData.reserveId,
                    offerData.nftAddress,
                    offerData.tokenId,
                    offerData.tokenAmount,
                    offerData.borrower,
                    offerData.borrowAmountMin,
                    offerData.borrowAmountMax,
                    offerData.borrowDurationMin,
                    offerData.borrowDurationMax,
                    offerData.borrowRate,
                    offerData.currency,
                    offerData.nonce,
                    offerData.deadline
                )
            );
    }

    function validateTakeBorrowOffer(
        mapping(address => mapping(uint256 => bool)) storage _nonce,
        mapping(address => uint256) storage minNonce,
        BespokeTypes.BorrowOffer memory offerData,
        bytes32 offerHash,
        address underlyingSpecified,
        uint256 supplyAmount,
        uint256 supplyDuration,
        bytes32 DOMAIN_SEPARATOR,
        IOpenSkyBespokeSettings BESPOKE_SETTINGS,
        IOpenSkySettings SETTINGS
    ) public {
        // check nonce
        require(
            !_nonce[offerData.borrower][offerData.nonce] && offerData.nonce >= minNonce[offerData.borrower],
            'BM_TAKE_BORROW_NONCE_INVALID'
        );

        address underlyingAsset = IOpenSkyPool(SETTINGS.poolAddress())
            .getReserveData(offerData.reserveId)
            .underlyingAsset;

        require(underlyingAsset == offerData.currency, 'BM_TAKE_BORROW_OFFER_ASSET_NOT_MATCH');

        if (underlyingSpecified != address(0))
            require(underlyingAsset == underlyingSpecified, 'BM_TAKE_BORROW_OFFER_ASSET_SPECIFIED_NOT_MATCH');

        require(BESPOKE_SETTINGS.isCurrencyWhitelisted(offerData.currency), 'BM_TAKE_BORROW_CURRENCY_NOT_IN_WHITELIST');

        require(
            !BESPOKE_SETTINGS.isWhitelistOn() || BESPOKE_SETTINGS.inWhitelist(offerData.nftAddress),
            'BM_TAKE_BORROW_NFT_NOT_IN_WHITELIST'
        );

        require(block.timestamp <= offerData.deadline, 'BM_TAKE_BORROW_SIGNING_EXPIRATION');

        (uint256 minBorrowDuration, uint256 maxBorrowDuration, ) = BESPOKE_SETTINGS.getBorrowDurationConfig(
            offerData.nftAddress
        );

        // check borrow duration
        require(
            offerData.borrowDurationMin <= offerData.borrowDurationMax &&
                offerData.borrowDurationMin >= minBorrowDuration &&
                offerData.borrowDurationMax <= maxBorrowDuration,
            'BM_TAKE_BORROW_OFFER_DURATION_NOT_ALLOWED'
        );

        require(
            supplyDuration > 0 &&
                supplyDuration >= offerData.borrowDurationMin &&
                supplyDuration <= offerData.borrowDurationMax,
            'BM_TAKE_BORROW_TAKER_DURATION_NOT_ALLOWED'
        );

        // check borrow amount
        require(
            offerData.borrowAmountMin > 0 && offerData.borrowAmountMin <= offerData.borrowAmountMax,
            'BM_TAKE_BORROW_OFFER_AMOUNT_NOT_ALLOWED'
        );

        require(
            supplyAmount >= offerData.borrowAmountMin && supplyAmount <= offerData.borrowAmountMax,
            'BM_TAKE_BORROW_SUPPLY_AMOUNT_NOT_ALLOWED'
        );
        require(
            SignatureChecker.verify(
                offerHash,
                offerData.borrower,
                offerData.v,
                offerData.r,
                offerData.s,
                DOMAIN_SEPARATOR
            ),
            'BM_TAKE_BORROW_SIGNATURE_INVALID'
        );
    }

    function createLoan(
        mapping(uint256 => BespokeTypes.LoanData) storage _loans,
        BespokeTypes.BorrowOffer memory offerData,
        uint256 loanId,
        uint256 supplyAmount,
        uint256 supplyDuration,
        IOpenSkyBespokeSettings BESPOKE_SETTINGS
    ) public {
        uint256 borrowRateRay = uint256(offerData.borrowRate).rayDiv(10000);
        (, , uint256 overdueDuration) = BESPOKE_SETTINGS.getBorrowDurationConfig(offerData.nftAddress);

        BespokeTypes.LoanData memory loan = BespokeTypes.LoanData({
            reserveId: offerData.reserveId,
            nftAddress: offerData.nftAddress,
            tokenId: offerData.tokenId,
            tokenAmount: offerData.tokenAmount,
            borrower: offerData.borrower,
            amount: supplyAmount,
            borrowRate: uint128(borrowRateRay),
            interestPerSecond: uint128(MathUtils.calculateBorrowInterestPerSecond(borrowRateRay, supplyAmount)),
            currency: offerData.currency,
            borrowDuration: uint40(supplyDuration),
            borrowBegin: uint40(block.timestamp),
            borrowOverdueTime: uint40(block.timestamp.add(supplyDuration)),
            liquidatableTime: uint40(block.timestamp.add(supplyDuration).add(overdueDuration)),
            lender: msg.sender,
            status: BespokeTypes.LoanStatus.BORROWING
        });

        _loans[loanId] = loan;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import '../libraries/types/DataTypes.sol';

interface IOpenSkySettings {
    event InitPoolAddress(address operator, address address_);
    event InitLoanAddress(address operator, address address_);
    event InitVaultFactoryAddress(address operator, address address_);
    event InitIncentiveControllerAddress(address operator, address address_);
    event InitWETHGatewayAddress(address operator, address address_);
    event InitPunkGatewayAddress(address operator, address address_);
    event InitDaoVaultAddress(address operator, address address_);

    event AddToWhitelist(address operator, uint256 reserveId, address nft);
    event RemoveFromWhitelist(address operator, uint256 reserveId, address nft);
    event SetReserveFactor(address operator, uint256 factor);
    event SetPrepaymentFeeFactor(address operator, uint256 factor);
    event SetOverdueLoanFeeFactor(address operator, uint256 factor);
    event SetMoneyMarketAddress(address operator, address address_);
    event SetTreasuryAddress(address operator, address address_);
    event SetACLManagerAddress(address operator, address address_);
    event SetLoanDescriptorAddress(address operator, address address_);
    event SetNftPriceOracleAddress(address operator, address address_);
    event SetInterestRateStrategyAddress(address operator, address address_);
    event AddLiquidator(address operator, address address_);
    event RemoveLiquidator(address operator, address address_);

    function poolAddress() external view returns (address);

    function loanAddress() external view returns (address);

    function vaultFactoryAddress() external view returns (address);

    function incentiveControllerAddress() external view returns (address);

    function wethGatewayAddress() external view returns (address);

    function punkGatewayAddress() external view returns (address);

    function inWhitelist(uint256 reserveId, address nft) external view returns (bool);

    function getWhitelistDetail(uint256 reserveId, address nft) external view returns (DataTypes.WhitelistInfo memory);

    function reserveFactor() external view returns (uint256); // treasury ratio

    function MAX_RESERVE_FACTOR() external view returns (uint256);

    function prepaymentFeeFactor() external view returns (uint256);

    function overdueLoanFeeFactor() external view returns (uint256);

    function moneyMarketAddress() external view returns (address);

    function treasuryAddress() external view returns (address);

    function daoVaultAddress() external view returns (address);

    function ACLManagerAddress() external view returns (address);

    function loanDescriptorAddress() external view returns (address);

    function nftPriceOracleAddress() external view returns (address);

    function interestRateStrategyAddress() external view returns (address);
    
    function isLiquidator(address liquidator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '../libraries/types/DataTypes.sol';

/**
 * @title IOpenSkyPool
 * @author OpenSky Labs
 * @notice Defines the basic interface for an OpenSky Pool.
 **/

interface IOpenSkyPool {
    /*
     * @dev Emitted on create()
     * @param reserveId The ID of the reserve
     * @param underlyingAsset The address of the underlying asset
     * @param oTokenAddress The address of the oToken
     * @param name The name to use for oToken
     * @param symbol The symbol to use for oToken
     * @param decimals The decimals of the oToken
     */
    event Create(
        uint256 indexed reserveId,
        address indexed underlyingAsset,
        address indexed oTokenAddress,
        string name,
        string symbol,
        uint8 decimals
    );

    /*
     * @dev Emitted on setTreasuryFactor()
     * @param reserveId The ID of the reserve
     * @param factor The new treasury factor of the reserve
     */
    event SetTreasuryFactor(uint256 indexed reserveId, uint256 factor);

    /*
     * @dev Emitted on setInterestModelAddress()
     * @param reserveId The ID of the reserve
     * @param interestModelAddress The address of the interest model contract
     */
    event SetInterestModelAddress(uint256 indexed reserveId, address interestModelAddress);

    /*
     * @dev Emitted on openMoneyMarket()
     * @param reserveId The ID of the reserve
     */
    event OpenMoneyMarket(uint256 reserveId);

    /*
     * @dev Emitted on closeMoneyMarket()
     * @param reserveId The ID of the reserve
     */
    event CloseMoneyMarket(uint256 reserveId);

    /*
     * @dev Emitted on deposit()
     * @param reserveId The ID of the reserve
     * @param onBehalfOf The address that will receive the oTokens
     * @param amount The amount of ETH to be deposited
     * @param referralCode integrators are assigned a referral code and can potentially receive rewards
     * 0 if the action is executed directly by the user, without any intermediaries
     */
    event Deposit(uint256 indexed reserveId, address indexed onBehalfOf, uint256 amount, uint256 referralCode);

    /*
     * @dev Emitted on withdraw()
     * @param reserveId The ID of the reserve
     * @param onBehalfOf The address that will receive assets withdrawed
     * @param amount The amount to be withdrawn
     */
    event Withdraw(uint256 indexed reserveId, address indexed onBehalfOf, uint256 amount);

    /*
     * @dev Emitted on borrow()
     * @param reserveId The ID of the reserve
     * @param user The address initiating the withdrawal(), owner of oTokens
     * @param onBehalfOf The address that will receive the ETH and the loan NFT
     * @param loanId The loan ID
     */
    event Borrow(
        uint256 indexed reserveId,
        address user,
        address indexed onBehalfOf,
        uint256 indexed loanId
    );

    /*
     * @dev Emitted on repay()
     * @param reserveId The ID of the reserve
     * @param repayer The address initiating the repayment()
     * @param onBehalfOf The address that will receive the pledged NFT
     * @param loanId The ID of the loan
     * @param repayAmount The borrow balance of the loan when it was repaid
     * @param penalty The penalty of the loan for either early or overdue repayment
     */
    event Repay(
        uint256 indexed reserveId,
        address repayer,
        address indexed onBehalfOf,
        uint256 indexed loanId,
        uint256 repayAmount,
        uint256 penalty
    );

    /*
     * @dev Emitted on extend()
     * @param reserveId The ID of the reserve
     * @param onBehalfOf The owner address of loan NFT
     * @param oldLoanId The ID of the old loan
     * @param newLoanId The ID of the new loan
     */
    event Extend(uint256 indexed reserveId, address indexed onBehalfOf, uint256 oldLoanId, uint256 newLoanId);

    /*
     * @dev Emitted on startLiquidation()
     * @param reserveId The ID of the reserve
     * @param loanId The ID of the loan
     * @param nftAddress The address of the NFT used as collateral
     * @param tokenId The ID of the NFT used as collateral
     * @param operator The address initiating startLiquidation()
     */
    event StartLiquidation(
        uint256 indexed reserveId,
        uint256 indexed loanId,
        address indexed nftAddress,
        uint256 tokenId,
        address operator
    );

    /*
     * @dev Emitted on endLiquidation()
     * @param reserveId The ID of the reserve
     * @param loanId The ID of the loan
     * @param nftAddress The address of the NFT used as collateral
     * @param tokenId The ID of the NFT used as collateral
     * @param operator
     * @param repayAmount The amount used to repay, must be equal to or greater than the borrowBalance, excess part will be shared by all the lenders
     * @param borrowBalance The borrow balance of the loan
     */
    event EndLiquidation(
        uint256 indexed reserveId,
        uint256 indexed loanId,
        address indexed nftAddress,
        uint256 tokenId,
        address operator,
        uint256 repayAmount,
        uint256 borrowBalance
    );

    /**
     * @notice Creates a reserve
     * @dev Only callable by the pool admin role
     * @param underlyingAsset The address of the underlying asset
     * @param name The name of the oToken
     * @param symbol The symbol for the oToken
     * @param decimals The decimals of the oToken
     **/
    function create(
        address underlyingAsset,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external;

    /**
     * @notice Updates the treasury factor of a reserve
     * @dev Only callable by the pool admin role
     * @param reserveId The ID of the reserve
     * @param factor The new treasury factor of the reserve
     **/
    function setTreasuryFactor(uint256 reserveId, uint256 factor) external;

    /**
     * @notice Updates the interest model address of a reserve
     * @dev Only callable by the pool admin role
     * @param reserveId The ID of the reserve
     * @param interestModelAddress The new address of the interest model contract
     **/
    function setInterestModelAddress(uint256 reserveId, address interestModelAddress) external;

    /**
     * @notice Open the money market
     * @dev Only callable by the emergency admin role
     * @param reserveId The ID of the reserve
     **/
    function openMoneyMarket(uint256 reserveId) external;

    /**
     * @notice Close the money market
     * @dev Only callable by the emergency admin role
     * @param reserveId The ID of the reserve
     **/
    function closeMoneyMarket(uint256 reserveId) external;

    /**
     * @dev Deposits ETH into the reserve.
     * @param reserveId The ID of the reserve
     * @param referralCode integrators are assigned a referral code and can potentially receive rewards
     **/
    function deposit(uint256 reserveId, uint256 amount, address onBehalfOf, uint256 referralCode) external;

    /**
     * @dev withdraws the ETH from reserve.
     * @param reserveId The ID of the reserve
     * @param amount amount of oETH to withdraw and receive native ETH
     **/
    function withdraw(uint256 reserveId, uint256 amount, address onBehalfOf) external;

    /**
     * @dev Borrows ETH from reserve using an NFT as collateral and will receive a loan NFT as receipt.
     * @param reserveId The ID of the reserve
     * @param amount amount of ETH user will borrow
     * @param duration The desired duration of the loan
     * @param nftAddress The collateral NFT address
     * @param tokenId The ID of the NFT
     * @param onBehalfOf address of the user who will receive ETH and loan NFT.
     **/
    function borrow(
        uint256 reserveId,
        uint256 amount,
        uint256 duration,
        address nftAddress,
        uint256 tokenId,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @dev Repays a loan, as a result the corresponding loan NFT owner will receive the collateralized NFT.
     * @param loanId The ID of the loan the user will repay
     */
    function repay(uint256 loanId) external returns (uint256);

    /**
     * @dev Extends creates a new loan and terminates the old loan.
     * @param loanId The loan ID to extend
     * @param amount The amount of ERC20 token the user will borrow in the new loan
     * @param duration The selected duration the user will borrow in the new loan
     * @param onBehalfOf The address will borrow in the new loan
     **/
    function extend(
        uint256 loanId,
        uint256 amount,
        uint256 duration,
        address onBehalfOf
    ) external returns (uint256, uint256);

    /**
     * @dev Starts liquidation for a loan when it's in LIQUIDATABLE status
     * @param loanId The ID of the loan which will be liquidated
     */
    function startLiquidation(uint256 loanId) external;

    /**
     * @dev Completes liquidation for a loan which will be repaid.
     * @param loanId The ID of the liquidated loan that will be repaid.
     * @param amount The amount of the token that will be repaid.
     */
    function endLiquidation(uint256 loanId, uint256 amount) external;

    /**
     * @dev Returns the state of the reserve
     * @param reserveId The ID of the reserve
     * @return The state of the reserve
     **/
    function getReserveData(uint256 reserveId) external view returns (DataTypes.ReserveData memory);

    /**
     * @dev Returns the normalized income of the reserve
     * @param reserveId The ID of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(uint256 reserveId) external view returns (uint256);

    /**
     * @dev Returns the remaining liquidity of the reserve
     * @param reserveId The ID of the reserve
     * @return The reserve's withdrawable balance
     */
    function getAvailableLiquidity(uint256 reserveId) external view returns (uint256);

    /**
     * @dev Returns the instantaneous borrow limit value of a special NFT
     * @param nftAddress The address of the NFT
     * @param tokenId The ID of the NFT
     * @return The NFT's borrow limit
     */
    function getBorrowLimitByOracle(
        uint256 reserveId,
        address nftAddress,
        uint256 tokenId
    ) external view returns (uint256);

    /**
     * @dev Returns the sum of all users borrow balances include borrow interest accrued
     * @param reserveId The ID of the reserve
     * @return The total borrow balance of the reserve
     */
    function getTotalBorrowBalance(uint256 reserveId) external view returns (uint256);

    /**
     * @dev Returns TVL (total value locked) of the reserve.
     * @param reserveId The ID of the reserve
     * @return The reserve's TVL
     */
    function getTVL(uint256 reserveId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IACLManager {
    function addEmergencyAdmin(address admin) external;
    
    function isEmergencyAdmin(address admin) external view returns (bool);
    
    function removeEmergencyAdmin(address admin) external;
    
    function addGovernance(address admin) external;
    
    function isGovernance(address admin) external view returns (bool);

    function removeGovernance(address admin) external;

    function addPoolAdmin(address admin) external;

    function isPoolAdmin(address admin) external view returns (bool);

    function removePoolAdmin(address admin) external;

    function addLiquidationOperator(address address_) external;

    function isLiquidationOperator(address address_) external view returns (bool);

    function removeLiquidationOperator(address address_) external;

    function addAirdropOperator(address address_) external;

    function isAirdropOperator(address address_) external view returns (bool);

    function removeAirdropOperator(address address_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IOpenSkyFlashClaimReceiver {
    function executeOperation(
        address[] calldata nftAddresses,
        uint256[] calldata tokenIds,
        address initiator,
        address operator,
        bytes calldata params
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '../libraries/BespokeTypes.sol';

interface IOpenSkyBespokeLoanNFT is IERC721 {
    event Mint(uint256 indexed tokenId, address indexed recipient);
    event Burn(uint256 tokenId);
    event SetLoanDescriptorAddress(address operator, address descriptorAddress);

    function mint(uint256 tokenId, address account) external;

    function burn(uint256 tokenId) external;

    function getLoanData(uint256 tokenId) external returns (BespokeTypes.LoanData memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '../libraries/BespokeTypes.sol';

interface IOpenSkyBespokeMarket {
    event CancelAllOffers(address indexed sender, uint256 nonce);

    event CancelMultipleOffers(address indexed sender, uint256[] nonces);

    event TakeBorrowOffer(
        bytes32 offerHash,
        uint256 indexed loanId,
        address indexed lender,
        address indexed borrower,
        uint256 nonce
    );

    event TakeBorrowOfferETH(
        bytes32 offerHash,
        uint256 indexed loanId,
        address indexed lender,
        address indexed borrower,
        uint256 nonce
    );

    event Repay(uint256 indexed loanId, address indexed borrower);

    event RepayETH(uint256 indexed loanId, address indexed borrower);

    event Foreclose(uint256 indexed loanId, address indexed lender);

    event FlashClaim(address indexed receiver, address sender, address indexed nftAddress, uint256 indexed tokenId);
    event ClaimERC20Airdrop(address indexed token, address indexed to, uint256 amount);
    event ClaimERC721Airdrop(address indexed token, address indexed to, uint256[] ids);
    event ClaimERC1155Airdrop(address indexed token, address indexed to, uint256[] ids, uint256[] amounts, bytes data);

    function takeBorrowOffer(
        BespokeTypes.BorrowOffer memory offerData,
        uint256 supplyAmount,
        uint256 supplyDuration
    ) external;

    function takeBorrowOfferETH(
        BespokeTypes.BorrowOffer memory offerData,
        uint256 supplyAmount,
        uint256 supplyDuration
    ) external payable;

    function repay(uint256 loanId) external;

    function repayETH(uint256 loanId) external payable;

    function foreclose(uint256 loanId) external;

    function cancelAllBorrowOffersForSender(uint256 minNonce_) external;

    function cancelMultipleBorrowOffers(uint256[] calldata offerNonces) external;

    function isValidNonce(address account, uint256 nonce) external view returns (bool);

    function getLoanData(uint256 loanId) external view returns (BespokeTypes.LoanData memory);

    function getStatus(uint256 loanId) external view returns (BespokeTypes.LoanStatus);

    function getBorrowInterest(uint256 loanId) external view returns (uint256);

    function getBorrowBalance(uint256 loanId) external view returns (uint256);

    function getPenalty(uint256 loanId) external view returns (uint256);

    /**
     * @notice Allows smart contracts to access the collateralized NFT within one transaction,
     * as long as the amount taken plus a fee is returned
     * @dev IMPORTANT There are security concerns for developers of flash loan receiver contracts that must be carefully considered
     * @param receiverAddress The address of the contract receiving the funds, implementing IFlashClaimReceiver interface
     * @param loanIds The ID of loan being flash-borrowed
     * @param params packed params to pass to the receiver as extra information
     **/
    function flashClaim(
        address receiverAddress,
        uint256[] calldata loanIds,
        bytes calldata params
    ) external;

    /**
     * @notice Claim the ERC20 token which has been airdropped to the loan contract
     * @param token The address of the airdropped token
     * @param to The address which will receive ERC20 token
     * @param amount The amount of the ERC20 token
     **/
    function claimERC20Airdrop(
        address token,
        address to,
        uint256 amount
    ) external;

    /**
     * @notice Claim the ERC721 token which has been airdropped to the loan contract
     * @param token The address of the airdropped token
     * @param to The address which will receive the ERC721 token
     * @param ids The ID of the ERC721 token
     **/
    function claimERC721Airdrop(
        address token,
        address to,
        uint256[] calldata ids
    ) external;

    /**
     * @notice Claim the ERC1155 token which has been airdropped to the loan contract
     * @param token The address of the airdropped token
     * @param to The address which will receive the ERC1155 tokens
     * @param ids The ID of the ERC1155 token
     * @param amounts The amount of the ERC1155 tokens
     * @param data packed params to pass to the receiver as extra information
     **/
    function claimERC1155Airdrop(
        address token,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import '../libraries/BespokeTypes.sol';

interface IOpenSkyBespokeSettings {
    event InitLoanAddress(address operator, address borrowLoanAddress, address lendLoanAddress);
    event InitMarketAddress(address operator, address address_);

    event SetReserveFactor(address operator, uint256 factor);
    event SetOverdueLoanFeeFactor(address operator, uint256 factor);

    event SetMinBorrowDuration(address operator, uint256 factor);
    event SetMaxBorrowDuration(address operator, uint256 factor);
    event SetOverdueDuration(address operator, uint256 factor);

    event OpenWhitelist(address operator);
    event CloseWhitelist(address operator);
    event AddToWhitelist(address operator, address nft);
    event RemoveFromWhitelist(address operator, address nft);

    event AddCurrency(address operator, address currency);
    event RemoveCurrency(address operator, address currency);

    function marketAddress() external view returns (address);

    function borrowLoanAddress() external view returns (address);

    function lendLoanAddress() external view returns (address);


    function minBorrowDuration() external view returns (uint256);

    function maxBorrowDuration() external view returns (uint256);

    function overdueDuration() external view returns (uint256);

    function reserveFactor() external view returns (uint256);

    function MAX_RESERVE_FACTOR() external view returns (uint256);

    function overdueLoanFeeFactor() external view returns (uint256);

    function isWhitelistOn() external view returns (bool);

    function inWhitelist(address nft) external view returns (bool);

    function getWhitelistDetail(address nft) external view returns (BespokeTypes.WhitelistInfo memory);

    function getBorrowDurationConfig(address nftAddress)
        external
        view
        returns (
            uint256 minBorrowDuration,
            uint256 maxBorrowDuration,
            uint256 overdueDuration
        );

    function isCurrencyWhitelisted(address currency) external view returns (bool);
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

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
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
pragma solidity 0.8.10;

library Errors {
    // common
    string public constant MATH_MULTIPLICATION_OVERFLOW = '100';
    string public constant MATH_ADDITION_OVERFLOW = '101';
    string public constant MATH_DIVISION_BY_ZERO = '102';

    string public constant ETH_TRANSFER_FAILED = '110';
    string public constant RECEIVE_NOT_ALLOWED = '111';
    string public constant FALLBACK_NOT_ALLOWED = '112';
    string public constant APPROVAL_FAILED = '113';

    // setting/factor
    string public constant SETTING_ZERO_ADDRESS_NOT_ALLOWED = '115';
    string public constant SETTING_RESERVE_FACTOR_NOT_ALLOWED = '116';
    string public constant SETTING_WHITELIST_INVALID_RESERVE_ID = '117';
    string public constant SETTING_WHITELIST_NFT_ADDRESS_IS_ZERO = '118';
    string public constant SETTING_WHITELIST_NFT_DURATION_OUT_OF_ORDER = '119';
    string public constant SETTING_WHITELIST_NFT_NAME_EMPTY = '120';
    string public constant SETTING_WHITELIST_NFT_SYMBOL_EMPTY = '121';
    string public constant SETTING_WHITELIST_NFT_LTV_NOT_ALLOWED = '122';

    // settings/acl
    string public constant ACL_ONLY_GOVERNANCE_CAN_CALL = '200';
    string public constant ACL_ONLY_EMERGENCY_ADMIN_CAN_CALL = '201';
    string public constant ACL_ONLY_POOL_ADMIN_CAN_CALL = '202';
    string public constant ACL_ONLY_LIQUIDATOR_CAN_CALL = '203';
    string public constant ACL_ONLY_AIRDROP_OPERATOR_CAN_CALL = '204';
    string public constant ACL_ONLY_POOL_CAN_CALL = '205';

    // lending & borrowing
    // reserve
    string public constant RESERVE_DOES_NOT_EXIST = '300';
    string public constant RESERVE_LIQUIDITY_INSUFFICIENT = '301';
    string public constant RESERVE_INDEX_OVERFLOW = '302';
    string public constant RESERVE_SWITCH_MONEY_MARKET_STATE_ERROR = '303';
    string public constant RESERVE_TREASURY_FACTOR_NOT_ALLOWED = '304';
    string public constant RESERVE_TOKEN_CAN_NOT_BE_CLAIMED = '305';

    // token
    string public constant AMOUNT_SCALED_IS_ZERO = '310';
    string public constant AMOUNT_TRANSFER_OVERFLOW = '311';

    //deposit
    string public constant DEPOSIT_AMOUNT_SHOULD_BE_BIGGER_THAN_ZERO = '320';

    // withdraw
    string public constant WITHDRAW_AMOUNT_NOT_ALLOWED = '321';
    string public constant WITHDRAW_LIQUIDITY_NOT_SUFFICIENT = '322';

    // borrow
    string public constant BORROW_DURATION_NOT_ALLOWED = '330';
    string public constant BORROW_AMOUNT_EXCEED_BORROW_LIMIT = '331';
    string public constant NFT_ADDRESS_IS_NOT_IN_WHITELIST = '332';

    // repay
    string public constant REPAY_STATUS_ERROR = '333';
    string public constant REPAY_MSG_VALUE_ERROR = '334';

    // extend
    string public constant EXTEND_STATUS_ERROR = '335';
    string public constant EXTEND_MSG_VALUE_ERROR = '336';

    // liquidate
    string public constant START_LIQUIDATION_STATUS_ERROR = '360';
    string public constant END_LIQUIDATION_STATUS_ERROR = '361';
    string public constant END_LIQUIDATION_AMOUNT_ERROR = '362';

    // loan
    string public constant LOAN_DOES_NOT_EXIST = '400';
    string public constant LOAN_SET_STATUS_ERROR = '401';
    string public constant LOAN_REPAYER_IS_NOT_OWNER = '402';
    string public constant LOAN_LIQUIDATING_STATUS_CAN_NOT_BE_UPDATED = '403';
    string public constant LOAN_CALLER_IS_NOT_OWNER = '404';
    string public constant LOAN_COLLATERAL_NFT_CAN_NOT_BE_CLAIMED = '405';

    string public constant FLASHCLAIM_EXECUTOR_ERROR = '410';
    string public constant FLASHCLAIM_STATUS_ERROR = '411';

    // money market
    string public constant MONEY_MARKET_DEPOSIT_AMOUNT_NOT_ALLOWED = '500';
    string public constant MONEY_MARKET_WITHDRAW_AMOUNT_NOT_ALLOWED = '501';
    string public constant MONEY_MARKET_APPROVAL_FAILED = '502';
    string public constant MONEY_MARKET_DELEGATE_CALL_ERROR = '503';
    string public constant MONEY_MARKET_REQUIRE_DELEGATE_CALL = '504';
    string public constant MONEY_MARKET_WITHDRAW_AMOUNT_NOT_MATCH = '505';

    // price oracle
    string public constant PRICE_ORACLE_HAS_NO_PRICE_FEED = '600';
    string public constant PRICE_ORACLE_INCORRECT_TIMESTAMP = '601';
    string public constant PRICE_ORACLE_PARAMS_ERROR = '602';
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {IERC1271} from '@openzeppelin/contracts/interfaces/IERC1271.sol';

/**
 * @title SignatureChecker
 * @notice This library allows verification of signatures for both EOAs and contracts.
 */
library SignatureChecker {
    /**
     * @notice Recovers the signer of a signature (for EOA)
     * @param hash the hash containing the signed mesage
     * @param v parameter (27 or 28). This prevents maleability since the public key recovery equation has two possible solutions.
     * @param r parameter
     * @param s parameter
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // https://ethereum.stackexchange.com/questions/83174/is-it-best-practice-to-check-signature-malleability-in-ecrecover
        // https://crypto.iacr.org/2019/affevents/wac/medias/Heninger-BiasedNonceSense.pdf
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            'BM_SIGNATURE_INVALID_S_PARAMETER'
        );

        require(v == 27 || v == 28, 'BM_SIGNATURE_INVALID_V_PARAMETER');

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), 'BM_SIGNATURE_INVALID_SIGNER');

        return signer;
    }

    /**
     * @notice Returns whether the signer matches the signed message
     * @param hash the hash containing the signed mesage
     * @param signer the signer address to confirm message validity
     * @param v parameter (27 or 28)
     * @param r parameter
     * @param s parameter
     * @param domainSeparator paramer to prevent signature being executed in other chains and environments
     * @return true --> if valid // false --> if invalid
     */
    function verify(
        bytes32 hash,
        address signer,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 domainSeparator
    ) internal view returns (bool) {
        // \x19\x01 is the standardized encoding prefix
        // https://eips.ethereum.org/EIPS/eip-712#specification
        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', domainSeparator, hash));
        if (Address.isContract(signer)) {
            // 0x1626ba7e is the interfaceId for signature contracts (see IERC1271)
            return IERC1271(signer).isValidSignature(digest, abi.encodePacked(r, s, v)) == 0x1626ba7e;
        } else {
            return recover(digest, v, r, s) == signer;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library DataTypes {
    struct ReserveData {
        uint256 reserveId;
        address underlyingAsset;
        address oTokenAddress;
        address moneyMarketAddress;
        uint128 lastSupplyIndex;
        uint256 borrowingInterestPerSecond;
        uint256 lastMoneyMarketBalance;
        uint40 lastUpdateTimestamp;
        uint256 totalBorrows;
        address interestModelAddress;
        uint256 treasuryFactor;
        bool isMoneyMarketOn;
    }

    struct LoanData {
        uint256 reserveId;
        address nftAddress;
        uint256 tokenId;
        address borrower;
        uint256 amount;
        uint128 borrowRate;
        uint128 interestPerSecond;
        uint40 borrowBegin;
        uint40 borrowDuration;
        uint40 borrowOverdueTime;
        uint40 liquidatableTime;
        uint40 extendableTime;
        uint40 borrowEnd;
        LoanStatus status;
    }

    enum LoanStatus {
        NONE,
        BORROWING,
        EXTENDABLE,
        OVERDUE,
        LIQUIDATABLE,
        LIQUIDATING
    }

    struct WhitelistInfo {
        bool enabled;
        string name;
        string symbol;
        uint256 LTV;
        uint256 minBorrowDuration;
        uint256 maxBorrowDuration;
        uint256 extendableDuration;
        uint256 overdueDuration;
    }
}

// SPDX-License-Identifier: MIT

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