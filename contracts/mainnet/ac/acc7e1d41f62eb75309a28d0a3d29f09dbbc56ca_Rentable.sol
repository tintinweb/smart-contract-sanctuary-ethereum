// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

// Inheritance
import {IRentable} from "./interfaces/IRentable.sol";
import {IRentableAdminEvents} from "./interfaces/IRentableAdminEvents.sol";
import {IRentableHooks} from "./interfaces/IRentableHooks.sol";
import {IORentableHooks} from "./interfaces/IORentableHooks.sol";
import {IWRentableHooks} from "./interfaces/IWRentableHooks.sol";
import {BaseSecurityInitializable} from "./security/BaseSecurityInitializable.sol";
import {RentableStorageV1} from "./RentableStorageV1.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

// Libraries
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

// References
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import {IERC721ReadOnlyProxy} from "./interfaces/IERC721ReadOnlyProxy.sol";
import {IERC721ExistExtension} from "./interfaces/IERC721ExistExtension.sol";
import {ICollectionLibrary} from "./collections/ICollectionLibrary.sol";

import {IWalletFactory} from "./wallet/IWalletFactory.sol";
import {SimpleWallet} from "./wallet/SimpleWallet.sol";
import {RentableTypes} from "./RentableTypes.sol";

/// @title Rentable main contract
/// @author Rentable Team <[email protected]>
/// @custom:security Rentable Security Team <[email protected]>
/// @notice Main entry point to interact with Rentable protocol
contract Rentable is
    IRentable,
    IRentableAdminEvents,
    IORentableHooks,
    IWRentableHooks,
    BaseSecurityInitializable,
    ReentrancyGuardUpgradeable,
    RentableStorageV1
{
    /* ========== LIBRARIES ========== */

    using Address for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ========== MODIFIERS ========== */

    /// @dev Prevents calling a function from anyone except the owner
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    modifier onlyOTokenOwner(address tokenAddress, uint256 tokenId) {
        _getExistingORentableCheckOwnership(tokenAddress, tokenId, msg.sender);
        _;
    }

    /// @dev Prevents calling a function from anyone except respective OToken
    /// @param tokenAddress wrapped token address
    modifier onlyOToken(address tokenAddress) {
        require(
            msg.sender == _orentables[tokenAddress],
            "Only proper ORentables allowed"
        );
        _;
    }

    /// @dev Prevents calling a function from anyone except respective WToken
    /// @param tokenAddress wrapped token address
    modifier onlyWToken(address tokenAddress) {
        require(
            msg.sender == _wrentables[tokenAddress],
            "Only proper WRentables allowed"
        );
        _;
    }

    /// @dev Prevents calling a function from anyone except respective OToken or WToken
    /// @param tokenAddress wrapped token address
    modifier onlyOTokenOrWToken(address tokenAddress) {
        require(
            msg.sender == _orentables[tokenAddress] ||
                msg.sender == _wrentables[tokenAddress],
            "Only w/o tokens are authorized"
        );
        _;
    }

    /// @dev Prevents calling a library when not set for the respective wrapped token
    /// @param tokenAddress wrapped token address
    // slither-disable-next-line incorrect-modifier
    modifier skipIfLibraryNotSet(address tokenAddress) {
        if (_libraries[tokenAddress] != address(0)) {
            _;
        }
    }

    /* ========== CONSTRUCTOR ========== */

    /// @dev Instatiate Rentable
    /// @param governance address for governance role
    /// @param operator address for operator role
    constructor(address governance, address operator) {
        _initialize(governance, operator);
    }

    /* ---------- INITIALIZER ---------- */

    /// @dev Initialize Rentable (to be used with proxies)
    /// @param governance address for governance role
    /// @param operator address for operator role
    function initialize(address governance, address operator) external {
        _initialize(governance, operator);
    }

    /// @dev For internal usage in the initializer external method
    /// @param governance address for governance role
    /// @param operator address for operator role
    function _initialize(address governance, address operator)
        internal
        initializer
    {
        __BaseSecurityInitializable_init(governance, operator);
        __ReentrancyGuard_init();
    }

    /* ========== SETTERS ========== */

    /// @dev Associate the event hooks library to the specific wrapped token
    /// @param tokenAddress wrapped token address
    /// @param libraryAddress library address
    function setLibrary(address tokenAddress, address libraryAddress)
        external
        onlyGovernance
    {
        address previousValue = _libraries[tokenAddress];

        _libraries[tokenAddress] = libraryAddress;

        emit LibraryChanged(tokenAddress, previousValue, libraryAddress);
    }

    /// @dev Associate the otoken to the specific wrapped token
    /// @param tokenAddress wrapped token address
    /// @param oRentable otoken address
    function setORentable(address tokenAddress, address oRentable)
        external
        onlyGovernance
    {
        address previousValue = _orentables[tokenAddress];

        _orentables[tokenAddress] = oRentable;

        emit ORentableChanged(tokenAddress, previousValue, oRentable);
    }

    /// @dev Associate the otoken to the specific wrapped token
    /// @param tokenAddress wrapped token address
    /// @param wRentable otoken address
    function setWRentable(address tokenAddress, address wRentable)
        external
        onlyGovernance
    {
        address previousValue = _wrentables[tokenAddress];

        _wrentables[tokenAddress] = wRentable;

        emit WRentableChanged(tokenAddress, previousValue, wRentable);
    }

    /// @dev Set wallet factory
    /// @param walletFactory wallet factory address
    function setWalletFactory(address walletFactory) external onlyGovernance {
        require(walletFactory != address(0), "Wallet Factory cannot be 0");

        address previousWalletFactory = walletFactory;

        _walletFactory = walletFactory;

        emit WalletFactoryChanged(previousWalletFactory, walletFactory);
    }

    /// @dev Set fee (percentage)
    /// @param newFee fee in 1e4 units (e.g. 100% = 10000)
    function setFee(uint16 newFee) external onlyGovernance {
        require(newFee <= BASE_FEE, "Fee greater than max value");

        uint16 previousFee = _fee;

        _fee = newFee;

        emit FeeChanged(previousFee, newFee);
    }

    /// @dev Set fee collector address
    /// @param newFeeCollector fee collector address
    function setFeeCollector(address payable newFeeCollector)
        external
        onlyGovernance
    {
        require(newFeeCollector != address(0), "FeeCollector cannot be null");

        address previousFeeCollector = _feeCollector;

        _feeCollector = newFeeCollector;

        emit FeeCollectorChanged(previousFeeCollector, newFeeCollector);
    }

    /// @dev Enable payment token (ERC20)
    /// @param paymentToken payment token address
    function enablePaymentToken(address paymentToken) external onlyGovernance {
        uint8 previousStatus = _paymentTokenAllowlist[paymentToken];

        _paymentTokenAllowlist[paymentToken] = ERC20_TOKEN;

        emit PaymentTokenAllowListChanged(
            paymentToken,
            previousStatus,
            ERC20_TOKEN
        );
    }

    /// @dev Enable payment token (ERC1155)
    /// @param paymentToken payment token address
    function enable1155PaymentToken(address paymentToken)
        external
        onlyGovernance
    {
        uint8 previousStatus = _paymentTokenAllowlist[paymentToken];

        _paymentTokenAllowlist[paymentToken] = ERC1155_TOKEN;

        emit PaymentTokenAllowListChanged(
            paymentToken,
            previousStatus,
            ERC1155_TOKEN
        );
    }

    /// @dev Disable payment token (ERC1155)
    /// @param paymentToken payment token address
    function disablePaymentToken(address paymentToken) external onlyGovernance {
        uint8 previousStatus = _paymentTokenAllowlist[paymentToken];

        _paymentTokenAllowlist[paymentToken] = NOT_ALLOWED_TOKEN;

        emit PaymentTokenAllowListChanged(
            paymentToken,
            previousStatus,
            NOT_ALLOWED_TOKEN
        );
    }

    /// @dev Toggle o/w token to call on-behalf a selector on the wrapped token
    /// @param caller o/w token address
    /// @param selector selector bytes on the target wrapped token
    /// @param enabled true to enable, false to disable
    function enableProxyCall(
        address caller,
        bytes4 selector,
        bool enabled
    ) external onlyGovernance {
        bool previousStatus = _proxyAllowList[caller][selector];

        _proxyAllowList[caller][selector] = enabled;

        emit ProxyCallAllowListChanged(
            caller,
            selector,
            previousStatus,
            enabled
        );
    }

    /* ========== VIEWS ========== */

    /* ---------- Internal ---------- */

    /// @dev Get and check (reverting) otoken exist for a specific token
    /// @param tokenAddress wrapped token address
    /// @return oRentable otoken instance
    function _getExistingORentable(address tokenAddress)
        internal
        view
        returns (address oRentable)
    {
        oRentable = _orentables[tokenAddress];
        require(oRentable != address(0), "Token currently not supported");
    }

    /// @dev Get and check (reverting) otoken user ownership
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @param user user to verify ownership
    /// @return oRentable otoken instance
    function _getExistingORentableCheckOwnership(
        address tokenAddress,
        uint256 tokenId,
        address user
    ) internal view returns (address oRentable) {
        oRentable = _getExistingORentable(tokenAddress);

        require(
            IERC721Upgradeable(oRentable).ownerOf(tokenId) == user,
            "The token must be yours"
        );
    }

    /// @dev Show rental validity
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @return true if is expired, false otw
    function _isExpired(address tokenAddress, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        // slither-disable-next-line timestamp
        return block.timestamp >= (_expiresAt[tokenAddress][tokenId]);
    }

    /* ---------- Public ---------- */

    /// @notice Get library address for the specific wrapped token
    /// @param tokenAddress wrapped token address
    /// @return library address
    function getLibrary(address tokenAddress) external view returns (address) {
        return _libraries[tokenAddress];
    }

    /// @notice Get OToken address associated to the specific wrapped token
    /// @param tokenAddress wrapped token address
    /// @return OToken address
    function getORentable(address tokenAddress)
        external
        view
        returns (address)
    {
        return _orentables[tokenAddress];
    }

    /// @notice Get WToken address associated to the specific wrapped token
    /// @param tokenAddress wrapped token address
    /// @return WToken address
    function getWRentable(address tokenAddress)
        external
        view
        returns (address)
    {
        return _wrentables[tokenAddress];
    }

    /// @notice Get wallet factory address
    /// @return wallet factory address
    function getWalletFactory() external view returns (address) {
        return _walletFactory;
    }

    /// @notice Show current protocol fee
    /// @return protocol fee in 1e4 units, e.g. 100 = 1%
    function getFee() external view returns (uint16) {
        return _fee;
    }

    /// @notice Get protocol fee collector
    /// @return protocol fee collector address
    function getFeeCollector() external view returns (address payable) {
        return _feeCollector;
    }

    /// @notice Show a token is enabled as payment token
    /// @param paymentTokenAddress payment token address
    /// @return status, see RentableStorageV1 for values
    function getPaymentTokenAllowlist(address paymentTokenAddress)
        external
        view
        returns (uint8)
    {
        return _paymentTokenAllowlist[paymentTokenAddress];
    }

    /// @notice Show O/W Token can invoke selector on respective wrapped token
    /// @param caller O/W Token address
    /// @param selector function selector to invoke
    /// @return a bool representing enabled or not
    function isEnabledProxyCall(address caller, bytes4 selector)
        external
        view
        returns (bool)
    {
        return _proxyAllowList[caller][selector];
    }

    /// @inheritdoc IRentable
    function userWallet(address user)
        external
        view
        override
        returns (address payable)
    {
        return _wallets[user];
    }

    /// @inheritdoc IRentable
    function rentalConditions(address tokenAddress, uint256 tokenId)
        external
        view
        override
        returns (RentableTypes.RentalConditions memory)
    {
        return _rentalConditions[tokenAddress][tokenId];
    }

    /// @inheritdoc IRentable
    function expiresAt(address tokenAddress, uint256 tokenId)
        external
        view
        override
        returns (uint256)
    {
        return _expiresAt[tokenAddress][tokenId];
    }

    /// @inheritdoc IRentable
    function isExpired(address tokenAddress, uint256 tokenId)
        external
        view
        override
        returns (bool)
    {
        return _isExpired(tokenAddress, tokenId);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /* ---------- Internal ---------- */

    /// @dev Create user wallet address
    /// @param user user address
    /// @return wallet address
    function _createWalletForUser(address user)
        internal
        returns (address payable wallet)
    {
        // slither-disable-next-line reentrancy-benign
        wallet = IWalletFactory(_walletFactory).createWallet(
            address(this),
            user
        );

        require(
            wallet != address(0),
            "Wallet Factory is not returning a valid wallet address"
        );

        _wallets[user] = wallet;

        // slither-disable-next-line reentrancy-events
        emit WalletCreated(user, wallet);

        return wallet;
    }

    /// @dev Get user wallet address (create if not exist)
    /// @param user user address
    /// @return wallet address
    function _getOrCreateWalletForUser(address user)
        internal
        returns (address payable wallet)
    {
        wallet = _wallets[user];

        if (wallet == address(0)) {
            wallet = _createWalletForUser(user);
        }

        return wallet;
    }

    /// @dev Deposit only a wrapped token and mint respective OToken
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @param to user to mint
    function _deposit(
        address tokenAddress,
        uint256 tokenId,
        address to
    ) internal {
        address oRentable = _getExistingORentable(tokenAddress);

        require(
            IERC721Upgradeable(tokenAddress).ownerOf(tokenId) == address(this),
            "Token not deposited"
        );

        IERC721ReadOnlyProxy(oRentable).mint(to, tokenId);

        _postDeposit(tokenAddress, tokenId, to);

        emit Deposit(to, tokenAddress, tokenId);
    }

    /// @dev Deposit and list a wrapped token
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @param to user to mint
    /// @param rc rental conditions see RentableTypes.RentalConditions
    function _depositAndList(
        address tokenAddress,
        uint256 tokenId,
        address to,
        RentableTypes.RentalConditions memory rc
    ) internal {
        _deposit(tokenAddress, tokenId, to);

        _createOrUpdateRentalConditions(to, tokenAddress, tokenId, rc);
    }

    /// @dev Set rental conditions for a wrapped token
    /// @param user who is changing the conditions
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @param rc rental conditions see RentableTypes.RentalConditions
    function _createOrUpdateRentalConditions(
        address user,
        address tokenAddress,
        uint256 tokenId,
        RentableTypes.RentalConditions memory rc
    ) internal {
        require(
            _paymentTokenAllowlist[rc.paymentTokenAddress] != NOT_ALLOWED_TOKEN,
            "Not supported payment token"
        );

        require(
            rc.minTimeDuration <= rc.maxTimeDuration,
            "Minimum duration cannot be greater than maximum"
        );

        _rentalConditions[tokenAddress][tokenId] = rc;

        _postList(
            tokenAddress,
            tokenId,
            user,
            rc.minTimeDuration,
            rc.maxTimeDuration,
            rc.pricePerSecond
        );

        emit UpdateRentalConditions(
            tokenAddress,
            tokenId,
            rc.paymentTokenAddress,
            rc.paymentTokenId,
            rc.minTimeDuration,
            rc.maxTimeDuration,
            rc.pricePerSecond,
            rc.privateRenter
        );
    }

    /// @dev Cancel rental conditions for a wrapped token
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    function _deleteRentalConditions(address tokenAddress, uint256 tokenId)
        internal
    {
        // save gas instead of dropping all the structure
        (_rentalConditions[tokenAddress][tokenId]).maxTimeDuration = 0;
    }

    /// @dev Expire explicitely rental and update data structures for a specific wrapped token
    /// @param currentUserHolder (optional) current user holder address
    /// @param oTokenOwner (optional) otoken owner address
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @param skipExistCheck assume or not wtoken id exists (gas optimization)
    /// @return currentlyRented true if rental is not expired
    // slither-disable-next-line calls-loop
    function _expireRental(
        address currentUserHolder,
        address oTokenOwner,
        address tokenAddress,
        uint256 tokenId,
        bool skipExistCheck
    ) internal returns (bool currentlyRented) {
        if (
            skipExistCheck ||
            IERC721ExistExtension(_wrentables[tokenAddress]).exists(tokenId)
        ) {
            if (_isExpired(tokenAddress, tokenId)) {
                address currentRentee = oTokenOwner == address(0)
                    ? IERC721Upgradeable(_orentables[tokenAddress]).ownerOf(
                        tokenId
                    )
                    : oTokenOwner;

                // recover asset from renter smart wallet to rentable contracts
                address wRentable = _wrentables[tokenAddress];
                // cannot be 0x0 because transferFrom avoid it
                address renter = currentUserHolder == address(0)
                    ? IERC721ExistExtension(wRentable).ownerOf(tokenId, true)
                    : currentUserHolder;
                address payable renterWallet = _wallets[renter];
                // slither-disable-next-line unused-return
                SimpleWallet(renterWallet).execute(
                    tokenAddress,
                    0,
                    abi.encodeWithSelector(
                        IERC721Upgradeable.transferFrom.selector, // we don't want to trigger onERC721Receiver
                        renterWallet,
                        address(this),
                        tokenId
                    ),
                    false
                );

                // burn
                IERC721ReadOnlyProxy(_wrentables[tokenAddress]).burn(tokenId);

                // post
                _postExpireRental(tokenAddress, tokenId, currentRentee);
                emit RentEnds(tokenAddress, tokenId);
            } else {
                currentlyRented = true;
            }
        }

        return currentlyRented;
    }

    /// @dev Execute custom logic after deposit via wrapped token library
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @param user depositor
    function _postDeposit(
        address tokenAddress,
        uint256 tokenId,
        address user
    ) internal skipIfLibraryNotSet(tokenAddress) {
        // slither-disable-next-line unused-return
        _libraries[tokenAddress].functionDelegateCall(
            abi.encodeWithSelector(
                ICollectionLibrary.postDeposit.selector,
                tokenAddress,
                tokenId,
                user
            ),
            ""
        );
    }

    /// @dev Execute custom logic after listing via wrapped token library
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @param user lister
    /// @param maxTimeDuration max duration allowed for the rental
    /// @param pricePerSecond price per second in payment token units
    function _postList(
        address tokenAddress,
        uint256 tokenId,
        address user,
        uint256 minTimeDuration,
        uint256 maxTimeDuration,
        uint256 pricePerSecond
    ) internal skipIfLibraryNotSet(tokenAddress) {
        // slither-disable-next-line unused-return
        _libraries[tokenAddress].functionDelegateCall(
            abi.encodeWithSelector(
                ICollectionLibrary.postList.selector,
                tokenAddress,
                tokenId,
                user,
                minTimeDuration,
                maxTimeDuration,
                pricePerSecond
            ),
            ""
        );
    }

    /// @dev Execute custom logic after rent via wrapped token library
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @param duration rental duration
    /// @param from rentee
    /// @param to renter
    /// @param toWallet receiver wallet
    function _postRent(
        address tokenAddress,
        uint256 tokenId,
        uint256 duration,
        address from,
        address to,
        address toWallet
    ) internal skipIfLibraryNotSet(tokenAddress) {
        // slither-disable-next-line unused-return
        _libraries[tokenAddress].functionDelegateCall(
            abi.encodeWithSelector(
                ICollectionLibrary.postRent.selector,
                tokenAddress,
                tokenId,
                duration,
                from,
                to,
                toWallet
            ),
            ""
        );
    }

    /// @dev Execute custom logic after rent expires via wrapped token library
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @param from rentee
    // slither-disable-next-line calls-loop
    function _postExpireRental(
        address tokenAddress,
        uint256 tokenId,
        address from
    ) internal skipIfLibraryNotSet(tokenAddress) {
        // slither-disable-next-line unused-return
        _libraries[tokenAddress].functionDelegateCall(
            abi.encodeWithSelector(
                ICollectionLibrary.postExpireRental.selector,
                tokenAddress,
                tokenId,
                from
            ),
            ""
        );
    }

    /* ---------- Public ---------- */

    /// @inheritdoc IRentable
    function createWalletForUser(address user)
        external
        override
        returns (address payable wallet)
    {
        require(
            user != address(0),
            "Cannot create a smart wallet for the void"
        );

        require(_wallets[user] == address(0), "Wallet already existing");

        return _createWalletForUser(user);
    }

    /// @inheritdoc IRentable
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override whenNotPaused nonReentrant returns (bytes4) {
        if (data.length == 0) {
            _deposit(msg.sender, tokenId, from);
        } else {
            _depositAndList(
                msg.sender,
                tokenId,
                from,
                abi.decode(data, (RentableTypes.RentalConditions))
            );
        }

        return this.onERC721Received.selector;
    }

    /// @inheritdoc IRentable
    function withdraw(address tokenAddress, uint256 tokenId)
        external
        override
        whenNotPaused
        nonReentrant
    {
        address user = msg.sender;
        address oRentable = _getExistingORentableCheckOwnership(
            tokenAddress,
            tokenId,
            user
        );

        require(
            !_expireRental(address(0), user, tokenAddress, tokenId, false),
            "Current rent still pending"
        );

        _deleteRentalConditions(tokenAddress, tokenId);

        IERC721ReadOnlyProxy(oRentable).burn(tokenId);

        IERC721Upgradeable(tokenAddress).safeTransferFrom(
            address(this),
            user,
            tokenId
        );

        emit Withdraw(tokenAddress, tokenId);
    }

    /// @inheritdoc IRentable
    function createOrUpdateRentalConditions(
        address tokenAddress,
        uint256 tokenId,
        RentableTypes.RentalConditions calldata rc
    ) external override whenNotPaused onlyOTokenOwner(tokenAddress, tokenId) {
        _createOrUpdateRentalConditions(msg.sender, tokenAddress, tokenId, rc);
    }

    /// @inheritdoc IRentable
    function deleteRentalConditions(address tokenAddress, uint256 tokenId)
        external
        override
        whenNotPaused
        onlyOTokenOwner(tokenAddress, tokenId)
    {
        _deleteRentalConditions(tokenAddress, tokenId);
    }

    /// @inheritdoc IRentable
    function rent(
        address tokenAddress,
        uint256 tokenId,
        uint256 duration
    ) external payable override whenNotPaused nonReentrant {
        // 1. check token is deposited and available for rental
        address oRentable = _getExistingORentable(tokenAddress);
        address payable rentee = payable(
            IERC721Upgradeable(oRentable).ownerOf(tokenId)
        );

        RentableTypes.RentalConditions memory rcs = _rentalConditions[
            tokenAddress
        ][tokenId];
        require(rcs.maxTimeDuration > 0, "Not available");

        require(
            !_expireRental(address(0), rentee, tokenAddress, tokenId, false),
            "Current rent still pending"
        );

        // 2. validate renter offer with rentee conditions
        require(duration > 0, "Duration cannot be zero");

        require(
            duration >= rcs.minTimeDuration,
            "Duration lower than conditions"
        );

        require(
            duration <= rcs.maxTimeDuration,
            "Duration greater than conditions"
        );

        require(
            rcs.privateRenter == address(0) || rcs.privateRenter == msg.sender,
            "Rental reserved for another user"
        );

        // 3. mint wtoken
        uint256 eta = block.timestamp + duration;
        _expiresAt[tokenAddress][tokenId] = eta;
        IERC721ReadOnlyProxy(_wrentables[tokenAddress]).mint(
            msg.sender,
            tokenId
        );

        // 4. transfer token to the renter smart wallet
        address renterWallet = _getOrCreateWalletForUser(msg.sender);
        IERC721Upgradeable(tokenAddress).safeTransferFrom(
            address(this),
            renterWallet,
            tokenId,
            ""
        );

        // 5. fees distribution
        // gross due amount
        uint256 paymentQty = rcs.pricePerSecond * duration;
        // protocol and rentee fees calc
        uint256 feesForFeeCollector = (paymentQty * _fee) / BASE_FEE;
        uint256 feesForRentee = paymentQty - feesForFeeCollector;

        if (rcs.paymentTokenAddress == address(0)) {
            require(msg.value >= paymentQty, "Not enough funds");
            if (feesForFeeCollector > 0) {
                Address.sendValue(_feeCollector, feesForFeeCollector);
            }

            Address.sendValue(rentee, feesForRentee);

            // refund eventual remaining
            if (msg.value > paymentQty) {
                Address.sendValue(payable(msg.sender), msg.value - paymentQty);
            }
        } else if (
            _paymentTokenAllowlist[rcs.paymentTokenAddress] == ERC20_TOKEN
        ) {
            if (feesForFeeCollector > 0) {
                IERC20Upgradeable(rcs.paymentTokenAddress).safeTransferFrom(
                    msg.sender,
                    _feeCollector,
                    feesForFeeCollector
                );
            }

            IERC20Upgradeable(rcs.paymentTokenAddress).safeTransferFrom(
                msg.sender,
                rentee,
                feesForRentee
            );
        } else {
            if (feesForFeeCollector > 0) {
                IERC1155Upgradeable(rcs.paymentTokenAddress).safeTransferFrom(
                    msg.sender,
                    _feeCollector,
                    rcs.paymentTokenId,
                    feesForFeeCollector,
                    ""
                );
            }

            IERC1155Upgradeable(rcs.paymentTokenAddress).safeTransferFrom(
                msg.sender,
                rentee,
                rcs.paymentTokenId,
                feesForRentee,
                ""
            );
        }

        // 6. after rent custom logic
        _postRent(
            tokenAddress,
            tokenId,
            duration,
            rentee,
            msg.sender,
            renterWallet
        );

        emit Rent(
            rentee,
            msg.sender,
            tokenAddress,
            tokenId,
            rcs.paymentTokenAddress,
            rcs.paymentTokenId,
            eta
        );
    }

    /// @inheritdoc IRentable
    function expireRental(address tokenAddress, uint256 tokenId)
        external
        override
        whenNotPaused
        returns (bool currentlyRented)
    {
        return
            _expireRental(address(0), address(0), tokenAddress, tokenId, false);
    }

    /// @notice Batch expireRental
    /// @param tokenAddresses array of wrapped token addresses
    /// @param tokenIds array of wrapped token id
    function expireRentals(
        address[] calldata tokenAddresses,
        uint256[] calldata tokenIds
    ) external whenNotPaused {
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            _expireRental(
                address(0),
                address(0),
                tokenAddresses[i],
                tokenIds[i],
                false
            );
        }
    }

    /* ---------- Public Permissioned ---------- */

    /// @inheritdoc IORentableHooks
    function afterOTokenTransfer(
        address tokenAddress,
        address from,
        address to,
        uint256 tokenId
    ) external override whenNotPaused onlyOToken(tokenAddress) {
        bool rented = _expireRental(
            address(0),
            from,
            tokenAddress,
            tokenId,
            false
        );

        address lib = _libraries[tokenAddress];
        if (lib != address(0)) {
            address wRentable = _wrentables[tokenAddress];
            address currentRenterWallet = IERC721ExistExtension(wRentable)
                .exists(tokenId)
                ? _wallets[IERC721Upgradeable(wRentable).ownerOf(tokenId)]
                : address(0);
            // slither-disable-next-line unused-return
            lib.functionDelegateCall(
                abi.encodeWithSelector(
                    ICollectionLibrary.postOTokenTransfer.selector,
                    tokenAddress,
                    tokenId,
                    from,
                    to,
                    currentRenterWallet,
                    rented
                ),
                ""
            );
        }
    }

    /// @inheritdoc IWRentableHooks
    function afterWTokenTransfer(
        address tokenAddress,
        address from,
        address to,
        uint256 tokenId
    ) external override whenNotPaused onlyWToken(tokenAddress) {
        // we need to pass from as current holder in the expire func
        // otw in the case is expired, wewould try to fetch from the recipient wallet
        // which doesn't hold it
        // could be better to check for expire in a preWTokenTransfer

        bool currentlyRented = _expireRental(
            from,
            address(0),
            tokenAddress,
            tokenId,
            true
        );

        if (currentlyRented) {
            // move to the recipient smart wallet
            address payable fromWallet = _wallets[from];
            // slither-disable-next-line unused-return
            SimpleWallet(fromWallet).execute(
                tokenAddress,
                0,
                abi.encodeWithSignature(
                    "safeTransferFrom(address,address,uint256)",
                    fromWallet,
                    _getOrCreateWalletForUser(to),
                    tokenId
                ),
                false
            );

            // execute lib code
            address lib = _libraries[tokenAddress];
            if (lib != address(0)) {
                // slither-disable-next-line unused-return
                lib.functionDelegateCall(
                    abi.encodeWithSelector(
                        ICollectionLibrary.postWTokenTransfer.selector,
                        tokenAddress,
                        tokenId,
                        from,
                        to,
                        _wallets[to]
                    ),
                    ""
                );
            }
        }
    }

    /// @inheritdoc IRentableHooks
    function proxyCall(
        address to,
        bytes4 selector,
        bytes memory data
    )
        external
        payable
        override
        whenNotPaused
        onlyOTokenOrWToken(to) // this implicitly checks `to` is the associated wrapped token
        returns (bytes memory)
    {
        require(
            _proxyAllowList[msg.sender][selector],
            "Proxy call unauthorized"
        );

        return
            to.functionCallWithValue(
                bytes.concat(selector, data),
                msg.value,
                ""
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

// Inheritance
import {IERC721ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import {IRentableEvents} from "./IRentableEvents.sol";

// References
import {RentableTypes} from "../RentableTypes.sol";

/// @title Rentable protocol user interface
/// @author Rentable Team <[email protected]>
/// @custom:security Rentable Security Team <[email protected]>
interface IRentable is IRentableEvents, IERC721ReceiverUpgradeable {
    /* ========== VIEWS ========== */

    /// @notice Get wallet for user
    /// @param user user address
    /// @return wallet address
    function userWallet(address user) external view returns (address payable);

    /// @notice Show current rental conditions for a specific wrapped token
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @return rental conditions, see RentableTypes.RentalConditions for fields
    function rentalConditions(address tokenAddress, uint256 tokenId)
        external
        view
        returns (RentableTypes.RentalConditions memory);

    /// @notice Show rental expiration time for a specific wrapped token
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @return expiration timestamp
    function expiresAt(address tokenAddress, uint256 tokenId)
        external
        view
        returns (uint256);

    /// @dev Show rental validity
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @return true if is expired, false otw
    function isExpired(address tokenAddress, uint256 tokenId)
        external
        view
        returns (bool);

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice Create user wallet address
    /// @param user user address
    /// @return wallet address
    function createWalletForUser(address user)
        external
        returns (address payable wallet);

    /// @notice Entry point for deposits used by wrapped token safeTransferFrom
    /// @param from depositor
    /// @param tokenId wrapped token id
    /// @param data (optional) abi encoded RentableTypes.RentalConditions rental conditions for listing
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4);

    /// @notice Withdraw and unwrap deposited token
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    function withdraw(address tokenAddress, uint256 tokenId) external;

    /// @notice Manage rental conditions and listing
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @param rc rental conditions see RentableTypes.RentalConditions
    function createOrUpdateRentalConditions(
        address tokenAddress,
        uint256 tokenId,
        RentableTypes.RentalConditions calldata rc
    ) external;

    /// @notice De-list a wrapped token
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    function deleteRentalConditions(address tokenAddress, uint256 tokenId)
        external;

    /// @notice Rent a wrapped token
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @param duration duration in seconds
    function rent(
        address tokenAddress,
        uint256 tokenId,
        uint256 duration
    ) external payable;

    /// @notice Trigger on-chain rental expire for expired rentals
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    function expireRental(address tokenAddress, uint256 tokenId)
        external
        returns (bool currentlyRented);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

/// @title Rentable protocol admin events
/// @author Rentable Team <[email protected]>
/// @custom:security Rentable Security Team <[email protected]>
interface IRentableAdminEvents {
    /* ========== EVENTS ========== */

    /// @notice Emitted on library change
    /// @param tokenAddress respective token address
    /// @param previousValue previous library address
    /// @param newValue new library address
    event LibraryChanged(
        address indexed tokenAddress,
        address indexed previousValue,
        address indexed newValue
    );

    /// @notice Emitted on ORentable change
    /// @param tokenAddress respective token address
    /// @param previousValue previous orentable address
    /// @param newValue new orentable address
    event ORentableChanged(
        address indexed tokenAddress,
        address indexed previousValue,
        address indexed newValue
    );

    /// @notice Emitted on WRentable change
    /// @param tokenAddress respective token address
    /// @param previousValue previous wrentable address
    /// @param newValue new wrentable address
    event WRentableChanged(
        address indexed tokenAddress,
        address indexed previousValue,
        address indexed newValue
    );

    /// @notice Emitted on WalletFactory change
    /// @param previousWalletFactory previous wallet factory address
    /// @param newWalletFactory new wallet factory address
    event WalletFactoryChanged(
        address indexed previousWalletFactory,
        address indexed newWalletFactory
    );

    /// @notice Emitted on fee change
    /// @param previousFee previous fee
    /// @param newFee new fee
    event FeeChanged(uint16 indexed previousFee, uint16 indexed newFee);

    /// @notice Emitted on fee collector change
    /// @param previousFeeCollector previous fee
    /// @param newFeeCollector new fee
    event FeeCollectorChanged(
        address indexed previousFeeCollector,
        address indexed newFeeCollector
    );

    /// @notice Emitted on payment token allowlist change
    /// @param paymentToken payment token address
    /// @param previousStatus previous allowlist status
    /// @param newStatus new allowlist status
    event PaymentTokenAllowListChanged(
        address indexed paymentToken,
        uint8 indexed previousStatus,
        uint8 indexed newStatus
    );

    /// @notice Emitted on proxy call allowlist change
    /// @param caller o/w token address
    /// @param selector selector bytes on the target wrapped token
    /// @param previousStatus previous status
    /// @param newStatus new status
    event ProxyCallAllowListChanged(
        address indexed caller,
        bytes4 selector,
        bool previousStatus,
        bool newStatus
    );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

/// @title Rentable Shared Hooks
/// @author Rentable Team <[email protected]>
/// @custom:security Rentable Security Team <[email protected]>
interface IRentableHooks {
    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @dev Implementer will execute the call on the wrapped token
    /// @param to wrapped token address
    /// @param selector function selector on the target
    /// @param data function data
    function proxyCall(
        address to,
        bytes4 selector,
        bytes memory data
    ) external payable returns (bytes memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

// Inheritance
import {IRentableHooks} from "./IRentableHooks.sol";

/// @title OToken Rentable Hooks
/// @author Rentable Team <[email protected]>
/// @custom:security Rentable Security Team <[email protected]>
interface IORentableHooks is IRentableHooks {
    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @dev Notify the implementer about a token transfer
    /// @param tokenAddress wrapped token address
    /// @param from sender
    /// @param to receiver
    /// @param tokenId wrapped token id
    function afterOTokenTransfer(
        address tokenAddress,
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

// Inheritance
import {IRentableHooks} from "./IRentableHooks.sol";

/// @title WToken Rentable Hooks
/// @author Rentable Team <[email protected]>
/// @custom:security Rentable Security Team <[email protected]>
interface IWRentableHooks is IRentableHooks {
    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @dev Notify the implementer about a token transfer
    /// @param tokenAddress wrapped token address
    /// @param from sender
    /// @param to receiver
    /// @param tokenId wrapped token id
    function afterWTokenTransfer(
        address tokenAddress,
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

// Inheritance

import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// Libraries
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

// References
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

/// @title Base contract for Rentable
/// @author Rentable Team <[email protected]>
/// @custom:security Rentable Security Team <[email protected]>
/// @notice Implement simple security helpers for safe operations
contract BaseSecurityInitializable is Initializable, PausableUpgradeable {
    ///  Base security:
    ///  1. establish simple two-roles contract, _governance and _operator.
    ///  Operator can be changed only by _governance. Governance update needs acceptance.
    ///  2. can be paused by _operator or _governance via SCRAM()
    ///  3. only _governance can recover from pause via unpause
    ///  4. only _governance can withdraw in emergency
    ///  5. only _governance execute any tx in emergency

    /* ========== LIBRARIES ========== */
    using Address for address;

    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ========== CONSTANTS ========== */
    address private constant ETHER = address(0);

    /* ========== STATE VARIABLES ========== */
    // current governance address
    address private _governance;
    // new governance address awaiting to be confirmed
    address private _pendingGovernance;
    // operator address
    address private _operator;

    /* ========== MODIFIERS ========== */

    /// @dev Prevents calling a function from anyone except governance
    modifier onlyGovernance() {
        require(msg.sender == _governance, "Only Governance");
        _;
    }

    /// @dev Prevents calling a function from anyone except governance or operator
    modifier onlyOperatorOrGovernance() {
        require(
            msg.sender == _operator || msg.sender == _governance,
            "Only Operator or Governance"
        );
        _;
    }

    /* ========== EVENTS ========== */

    /// @notice Emitted on operator change
    /// @param previousOperator previous operator address
    /// @param newOperator new operator address
    event OperatorTransferred(
        address indexed previousOperator,
        address indexed newOperator
    );

    /// @notice Emitted on governance change proposal
    /// @param currentGovernance current governance address
    /// @param proposedGovernance new proposed governance address
    event GovernanceProposed(
        address indexed currentGovernance,
        address indexed proposedGovernance
    );

    /// @notice Emitted on governance change
    /// @param previousGovernance previous governance address
    /// @param newGovernance new governance address
    event GovernanceTransferred(
        address indexed previousGovernance,
        address indexed newGovernance
    );

    /* ========== CONSTRUCTOR ========== */

    /* ---------- INITIALIZER ---------- */

    /// @dev For internal usage in the child initializers
    /// @param governance address for governance role
    /// @param operator address for operator role
    // slither-disable-next-line naming-convention
    function __BaseSecurityInitializable_init(
        address governance,
        address operator
    ) internal onlyInitializing {
        __Pausable_init();

        require(governance != address(0), "Governance cannot be null");

        _governance = governance;
        _operator = operator;
    }

    /* ========== SETTERS ========== */

    /// @notice Propose new governance
    /// @param proposedGovernance governance address
    function setGovernance(address proposedGovernance) external onlyGovernance {
        // enable to cancel a proposal setting proposedGovernance to 0
        // slither-disable-next-line missing-zero-check
        _pendingGovernance = proposedGovernance;

        emit GovernanceProposed(_governance, proposedGovernance);
    }

    /// @notice Accept proposed governance
    function acceptGovernance() external {
        require(msg.sender == _pendingGovernance, "Only Proposed Governance");

        address previousGovernance = _governance;
        _governance = _pendingGovernance;
        _pendingGovernance = address(0);

        emit GovernanceTransferred(previousGovernance, _governance);
    }

    /// @notice Set operator
    /// @param newOperator new operator address
    function setOperator(address newOperator) external onlyGovernance {
        address previousOperator = _operator;

        // governance can disable operator role
        // slither-disable-next-line missing-zero-check
        _operator = newOperator;

        emit OperatorTransferred(previousOperator, newOperator);
    }

    /* ========== VIEWS ========== */

    /// @notice Shows current governance
    /// @return governance address
    // slither-disable-next-line external-function
    function getGovernance() public view returns (address) {
        return _governance;
    }

    /// @notice Shows upcoming governance
    /// @return upcoming pending governance address
    // slither-disable-next-line external-function
    function getPendingGovernance() public view returns (address) {
        return _pendingGovernance;
    }

    /// @notice Shows current operator
    /// @return governance operator
    // slither-disable-next-line external-function
    function getOperator() public view returns (address) {
        return _operator;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice Pause all operations
    // slither-disable-next-line naming-convention
    function SCRAM() external onlyOperatorOrGovernance {
        _pause();
    }

    /// @notice Returns to normal state
    function unpause() external onlyGovernance {
        _unpause();
    }

    /// @notice Withdraw asset ERC20 or ETH
    /// @param assetAddress Asset to be withdrawn
    function emergencyWithdrawERC20ETH(address assetAddress)
        external
        whenPaused
        onlyGovernance
    {
        uint256 assetBalance;
        if (assetAddress == ETHER) {
            address self = address(this);
            assetBalance = self.balance;
            payable(msg.sender).transfer(assetBalance);
        } else {
            assetBalance = IERC20Upgradeable(assetAddress).balanceOf(
                address(this)
            );
            IERC20Upgradeable(assetAddress).safeTransfer(
                msg.sender,
                assetBalance
            );
        }
    }

    /// @notice Batch withdraw asset ERC721
    /// @param assetAddress token address
    /// @param tokenIds array of token ids
    function emergencyBatchWithdrawERC721(
        address assetAddress,
        uint256[] calldata tokenIds,
        bool notSafe
    ) external whenPaused onlyGovernance {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (notSafe) {
                // slither-disable-next-line calls-loop
                IERC721Upgradeable(assetAddress).transferFrom(
                    address(this),
                    msg.sender,
                    tokenIds[i]
                );
            } else {
                // slither-disable-next-line calls-loop
                IERC721Upgradeable(assetAddress).safeTransferFrom(
                    address(this),
                    msg.sender,
                    tokenIds[i]
                );
            }
        }
    }

    /// @notice Batch withdraw asset ERC1155
    /// @param assetAddress token address
    /// @param tokenIds array of token ids
    function emergencyBatchWithdrawERC1155(
        address assetAddress,
        uint256[] calldata tokenIds
    ) external whenPaused onlyGovernance {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            // slither-disable-next-line calls-loop
            uint256 assetBalance = IERC1155Upgradeable(assetAddress).balanceOf(
                address(this),
                tokenIds[i]
            );

            // slither-disable-next-line calls-loop
            IERC1155Upgradeable(assetAddress).safeTransferFrom(
                address(this),
                msg.sender,
                tokenIds[i],
                assetBalance,
                ""
            );
        }
    }

    /// @notice Execute any tx in emergency
    /// @param to target
    /// @param value ether value
    /// @param data function+data
    /// @param isDelegateCall true will execute a delegate call, false a call
    function emergencyExecute(
        address to,
        uint256 value,
        bytes memory data,
        bool isDelegateCall
    )
        external
        payable
        whenPaused
        onlyGovernance
        returns (bytes memory returnData)
    {
        if (isDelegateCall) {
            returnData = to.functionDelegateCall(data, "");
        } else {
            returnData = to.functionCallWithValue(data, value, "");
        }
    }

    // Reserved storage space to allow for layout changes in the future.
    // slither-disable-next-line unused-state
    uint256[50] private _gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

// References
import {IERC721ReadOnlyProxy} from "./interfaces/IERC721ReadOnlyProxy.sol";
import {RentableTypes} from "./RentableTypes.sol";

/// @title Rentable Storage contract
/// @author Rentable Team <[email protected]>
/// @custom:security Rentable Security Team <[email protected]>
contract RentableStorageV1 {
    /* ========== CONSTANTS ========== */

    // paymentTokenAllowlist possible values
    // used during fee distribution
    uint8 internal constant NOT_ALLOWED_TOKEN = 0;
    uint8 internal constant ERC20_TOKEN = 1;
    uint8 internal constant ERC1155_TOKEN = 2;

    // percentage protocol fee, min 0.01%
    uint16 internal constant BASE_FEE = 10000;

    /* ========== STATE VARIABLES ========== */

    // (token address, token id) => rental conditions mapping
    // slither-disable-next-line naming-convention
    mapping(address => mapping(uint256 => RentableTypes.RentalConditions))
        internal _rentalConditions;

    // (token address, token id) => rental expiration mapping
    // slither-disable-next-line naming-convention
    mapping(address => mapping(uint256 => uint256)) internal _expiresAt;

    // token address => o/w token mapping
    // slither-disable-next-line naming-convention,similar-names
    mapping(address => address) internal _orentables;
    // slither-disable-next-line naming-convention,similar-names
    mapping(address => address) internal _wrentables;

    // token address => library mapping, for custom logic execution
    // slither-disable-next-line naming-convention
    mapping(address => address) internal _libraries;

    // allowed payment tokens, see fee distribution in Rentable-rent
    // slither-disable-next-line naming-convention
    mapping(address => uint8) internal _paymentTokenAllowlist;

    // enabled selectors for target, see Rentable-proxyCall
    // slither-disable-next-line naming-convention
    mapping(address => mapping(bytes4 => bool)) internal _proxyAllowList;

    // user wallet factory
    // slither-disable-next-line naming-convention
    address internal _walletFactory;

    // user => wallet mapping, for account abstraction
    // slither-disable-next-line naming-convention
    mapping(address => address payable) internal _wallets;

    // protocol fee
    // slither-disable-next-line naming-convention
    uint16 internal _fee;
    // protocol fee collector
    // slither-disable-next-line naming-convention
    address payable internal _feeCollector;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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

pragma solidity >=0.8.7;

/// @title ERC721 Proxy Interface
/// @author Rentable Team <[email protected]>
/// @custom:security Rentable Security Team <[email protected]>
/// @notice O/W token interface used by Rentable main contract
interface IERC721ReadOnlyProxy {
    /* ========== VIEWS ========== */

    /// @notice Get wrapped token address
    /// @return wrapped token address
    function getWrapped() external view returns (address);

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice Mint a token
    /// @param to receiver
    /// @param tokenId token id
    function mint(address to, uint256 tokenId) external;

    /// @notice Burn a token
    /// @param tokenId token id
    function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

/// @title ERC721 extension with exist function public
/// @author Rentable Team <[email protected]>
/// @custom:security Rentable Security Team <[email protected]>
interface IERC721ExistExtension {
    /* ========== VIEWS ========== */
    /// @notice Verify a specific token id exist
    /// @param tokenId token id
    /// @return true for existing token, false otw
    function exists(uint256 tokenId) external view returns (bool);

    /// @notice Check ownership eventually skipping expire check
    /// @param tokenId token id
    /// @param skipExpirationCheck when true, return current owner skipping expire check
    /// @return owner address
    function ownerOf(uint256 tokenId, bool skipExpirationCheck)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

/// @title Collection library interface
/// @author Rentable Team <[email protected]>
/// @custom:security Rentable Security Team <[email protected]>
/// @notice Implementer can realize custom logic for specific collections attaching to these hooks
interface ICollectionLibrary {
    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice Called after a deposit
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @param user depositor
    function postDeposit(
        address tokenAddress,
        uint256 tokenId,
        address user
    ) external;

    /// @notice Called after a listing
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @param user lister
    /// @param maxTimeDuration max duration allowed for the rental
    /// @param pricePerSecond price per second in payment token units
    function postList(
        address tokenAddress,
        uint256 tokenId,
        address user,
        uint256 minTimeDuration,
        uint256 maxTimeDuration,
        uint256 pricePerSecond
    ) external;

    /// @notice Called after a rent
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @param duration rental duration
    /// @param from rentee
    /// @param to renter
    /// @param toWallet renter wallet
    function postRent(
        address tokenAddress,
        uint256 tokenId,
        uint256 duration,
        address from,
        address to,
        address payable toWallet
    ) external payable;

    /// @notice Called after expiration settlement on-chain
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @param from rentee
    function postExpireRental(
        address tokenAddress,
        uint256 tokenId,
        address from
    ) external payable;

    /// @notice Called after WToken transfer
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @param from sender
    /// @param to receiver
    /// @param toWallet receiver wallet
    function postWTokenTransfer(
        address tokenAddress,
        uint256 tokenId,
        address from,
        address to,
        address payable toWallet
    ) external;

    /// @notice Called after OToken transfer
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @param from sender
    /// @param to receiver
    /// @param currentRenterWallet current renter wallet
    /// @param rented true when a rental is in place, false otw
    function postOTokenTransfer(
        address tokenAddress,
        uint256 tokenId,
        address from,
        address to,
        address payable currentRenterWallet,
        bool rented
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

/// @title Rentable wallet factory interface
/// @author Rentable Team <[email protected]>
/// @custom:security Rentable Security Team <[email protected]>
/// @notice Wallet factory interface
interface IWalletFactory {
    /// @notice Create a new wallet
    /// @param owner address for owner role
    /// @param user address for user role
    /// @return wallet newly created
    function createWallet(address owner, address user)
        external
        returns (address payable wallet);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

// Inheritance
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC721HolderUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import {ERC1155HolderUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";

// References
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/// @title Rentable account abstraction
/// @author Rentable Team <[email protected]>
/// @custom:security Rentable Security Team <[email protected]>
/// @notice Account Abstraction
contract SimpleWallet is
    Initializable,
    OwnableUpgradeable,
    ERC721HolderUpgradeable,
    ERC1155HolderUpgradeable
{
    /* ========== LIBRARIES ========== */

    using ECDSA for bytes32;
    using Address for address;

    /* ========== CONSTANTS ========== */

    bytes4 private constant ERC1271_IS_VALID_SIGNATURE =
        bytes4(keccak256("isValidSignature(bytes32,bytes)"));

    /* ========== STATE VARIABLES ========== */

    // current owner for the content
    address private _user;

    /* ========== CONSTRUCTOR ========== */

    /// @dev Instatiate SimpleWallet
    /// @param owner address for owner role
    /// @param user address for user role
    constructor(address owner, address user) {
        _initialize(owner, user);
    }

    /* ---------- INITIALIZER ---------- */

    /// @notice Initializer for the wallet
    /// @param owner address for owner role
    /// @param user address for user role
    function initialize(address owner, address user) external {
        _initialize(owner, user);
    }

    /// @dev Internal intializer for the wallet
    /// @param owner address for owner role
    /// @param user address for user role
    function _initialize(address owner, address user) internal initializer {
        require(owner != address(0), "Owner cannot be null");

        __Ownable_init();
        _transferOwnership(owner);
        __ERC721Holder_init();
        __ERC1155Holder_init();

        _setUser(user);
    }

    /* ========== SETTERS ========== */

    /* ---------- Internal ---------- */

    /// @dev Set current user for the wallet
    /// @param user user address
    function _setUser(address user) internal {
        // it's ok to se to 0x0, disabling signatures
        // slither-disable-next-line missing-zero-check
        _user = user;
    }

    /* ---------- Public ---------- */

    /// @notice Set current user for the wallet
    /// @param user user address
    function setUser(address user) external onlyOwner {
        _setUser(user);
    }

    /* ========== VIEWS ========== */

    /// @notice Set current user for the wallet
    /// @return user address
    function getUser() external view returns (address user) {
        return _user;
    }

    /// @notice Implementation of EIP 1271.
    /// Should return whether the signature provided is valid for the provided data.
    /// @param msgHash Hash of a message signed on the behalf of address(this)
    /// @param signature Signature byte array associated with _msgHash
    function isValidSignature(bytes32 msgHash, bytes memory signature)
        external
        view
        returns (bytes4)
    {
        // For the first implementation
        // we won't recursively check if user is smart wallet too
        // we assume user is an EOA
        address signer = msgHash.recover(signature);
        require(_user == signer, "Invalid signer");
        return ERC1271_IS_VALID_SIGNATURE;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice Execute any tx
    /// @param to target
    /// @param value ether value
    /// @param data function+data
    /// @param isDelegateCall true will execute a delegate call, false a call
    function execute(
        address to,
        uint256 value,
        bytes memory data,
        bool isDelegateCall
    ) external payable onlyOwner returns (bytes memory returnData) {
        if (isDelegateCall) {
            returnData = to.functionDelegateCall(data, "");
        } else {
            returnData = to.functionCallWithValue(data, value, "");
        }
    }

    /// @notice Withdraw ETH
    /// @param amount amount to withdraw
    function withdrawETH(uint256 amount) external onlyOwner {
        Address.sendValue(payable(msg.sender), amount);
    }

    /// @notice Can receive ETH
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

/// @title Rentable Types
/// @author Rentable Team <[email protected]>
/// @custom:security Rentable Security Team <[email protected]>
library RentableTypes {
    struct RentalConditions {
        uint256 minTimeDuration; // min duration allowed for the rental
        uint256 maxTimeDuration; // max duration allowed for the rental
        uint256 pricePerSecond; // price per second in payment token units
        uint256 paymentTokenId; // payment token id allowed for the rental (0 for ETH and ERC20)
        address paymentTokenAddress; // payment token address allowed for the rental
        address privateRenter; // restrict rent only to this address
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

pragma solidity >=0.8.7;

/// @title Rentable protocol events
/// @author Rentable Team <[email protected]>
/// @custom:security Rentable Security Team <[email protected]>
interface IRentableEvents {
    /* ========== EVENTS ========== */

    /// @notice Emitted on smart wallet created for user
    /// @param user user address
    /// @param walletAddress smart wallet address
    event WalletCreated(address indexed user, address indexed walletAddress);

    /// @notice Emitted on token deposit
    /// @param who depositor
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    event Deposit(
        address indexed who,
        address indexed tokenAddress,
        uint256 indexed tokenId
    );

    /// @notice Emitted on withdrawal
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    event Withdraw(address indexed tokenAddress, uint256 indexed tokenId);

    /// @notice Emitted on rental conditions changes
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @param paymentTokenAddress payment token address allowed for the rental
    /// @param paymentTokenId payment token id allowed for the rental (0 for ETH and ERC20)
    /// @param maxTimeDuration max duration allowed for the rental
    /// @param pricePerSecond price per second in payment token units
    /// @param privateRenter rental allowed only for this renter
    event UpdateRentalConditions(
        address indexed tokenAddress,
        uint256 indexed tokenId,
        address paymentTokenAddress,
        uint256 paymentTokenId,
        uint256 minTimeDuration,
        uint256 maxTimeDuration,
        uint256 pricePerSecond,
        address privateRenter
    );

    /// @notice Emitted on a successful rent
    /// @param from rentee
    /// @param to renter
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @param paymentTokenAddress payment token address allowed for the rental
    /// @param paymentTokenId payment token id allowed for the rental (0 for ETH and ERC20)
    /// @param expiresAt rental expiration time
    event Rent(
        address from,
        address indexed to,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        address paymentTokenAddress,
        uint256 paymentTokenId,
        uint256 expiresAt
    );

    /// @notice Emitted on expiration settlement on-chain
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    event RentEnds(address indexed tokenAddress, uint256 indexed tokenId);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

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
    function __ERC721Holder_init() internal onlyInitializing {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal onlyInitializing {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
        __ERC1155Holder_init_unchained();
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

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
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }
    uint256[50] private __gap;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}