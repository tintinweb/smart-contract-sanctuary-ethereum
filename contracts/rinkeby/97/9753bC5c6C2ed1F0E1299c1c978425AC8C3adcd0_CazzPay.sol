// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IERC20.sol";
import "./interfaces/ICazzPayToken.sol";
import "../Ownable/MultiOwnable.sol";
import "./CazzPayOracle/CazzPayOracle.sol";

contract CazzPay is MultiOwnable, CazzPayOracle {
    ////////////////////////
    // LIBRARY AUGS
    ////////////////////////
    using Counters for Counters.Counter;

    ////////////////////////
    // STORAGE
    ////////////////////////
    IUniswapV2Factory public immutable factoryContract;
    IUniswapV2Router02 public immutable routerContract;
    ICazzPayToken public immutable czpContract;
    IERC20 public immutable wethContract;
    uint16 public paymentTransferFeesPerc; // This would be charged from seller when receiving payments; this number would be divided by 10000 before usage; e.g, for 0.01%, this value should be 1.
    Counters.Counter internal _cazzPayTransactionId;
    address[] internal _allPairsWithCzpAndOtherToken;

    ////////////////////////
    // MODIFIERS
    ////////////////////////
    modifier withinDeadline(uint256 _deadline) {
        require(block.timestamp <= _deadline, "DEADLINE CROSSED");
        _;
    }

    ////////////////////////
    // EVENTS
    ////////////////////////
    event CreatedPairWithCzpAndOtherToken(
        address indexed pairAddr,
        address indexed otherTokenContractAddr
    );

    event AddedLiquidityToCzpAndOtherTokenPair(
        address indexed otherTokenContractAddr,
        address indexed liquidityProviderAddr,
        uint256 czpAmtAdded,
        uint256 otherTokenAmtAdded,
        uint256 liquidityTokensMinted
    );

    event WithdrawnLiquidityFromCzpAndOtherTokenPair(
        address indexed otherTokenContractAddr,
        address indexed liquidityProviderAddr,
        uint256 czpAmtWithdrawn,
        uint256 otherTokenAmtWithdrawn,
        uint256 liquidityTokensSubmitted
    );

    event BoughtWithCrypto(
        address indexed payerWalletAddr,
        string recipientAccountId,
        uint256 indexed cazzPayTransactionId,
        address tokenUsedForPurchaseContractAddr,
        uint256 tokenAmtUsedForPurchased,
        uint256 fiatAmountPaid, /* Atomic */
        uint256 fiatAmountToPayToSeller /* Atomic */
    );

    event TokensSwapped(
        address indexed inputTokenContractAddr,
        address indexed outputTokenContractAddr,
        uint256 inputTokenAmt,
        uint256 outputTokenAmt
    );

    event SellerInfo(string sellerId, string email, string name);

    event PurchaseConfirmed(uint256 indexed cazzPayTransactionId);

    ////////////////////////
    // FUNCTIONS
    ////////////////////////

    /**
    @param _factoryContractAddr Address of the factory contract
    @param _routerContractAddr Address of the router contract
    @param _czpContractAddr Address of CZP contract
    @param _paymentTransferFeesPerc This would be charged from seller when receiving payments; this number would be divided by 10000 before usage; e.g, for 0.01%, this value should be 1.
    @param _approvedPriceFeedSigner Authorised signer to provide price feeds
     */
    constructor(
        IUniswapV2Factory _factoryContractAddr,
        IUniswapV2Router02 _routerContractAddr,
        ICazzPayToken _czpContractAddr,
        address _wethContractAddr,
        uint16 _paymentTransferFeesPerc,
        address _approvedPriceFeedSigner
    ) public CazzPayOracle(_approvedPriceFeedSigner) {
        factoryContract = _factoryContractAddr;
        routerContract = _routerContractAddr;
        wethContract = IERC20(_wethContractAddr);
        czpContract = _czpContractAddr;
        paymentTransferFeesPerc = _paymentTransferFeesPerc;
    }

    /**
    @notice Sets a new fees percentage for transfer
    @param _newPaymentTransferFeesPerc This would be charged from seller when receiving payments; this number would be divided by 10000 before usage; e.g, for 0.01%, this value should be 1.
     */
    function setPaymentTransferFeesPerc(uint16 _newPaymentTransferFeesPerc)
        external
        onlyOwners
    {
        paymentTransferFeesPerc = _newPaymentTransferFeesPerc;
    }

    /**
    @notice Creates a pair with $CZP and another token
    @param _otherTokenContractAddr Contract address of the other token to form pool with
    @return pairAddr Address of the pair created
    */
    function createPairWithCzpAndOtherToken(address _otherTokenContractAddr)
        external
        returns (address pairAddr)
    {
        pairAddr = factoryContract.createPair(
            address(czpContract),
            _otherTokenContractAddr
        );
        require(pairAddr != address(0), "PAIR NOT CREATED");
        _allPairsWithCzpAndOtherToken.push(pairAddr);
        emit CreatedPairWithCzpAndOtherToken(pairAddr, _otherTokenContractAddr);
    }

    /**
    @notice Creates a pair with $CZP and ETH
    @return pairAddr Address of the pair created
    */
    function createPairWithCzpAndEth()
        external
        payable
        returns (address pairAddr)
    {
        pairAddr = factoryContract.createPair(
            address(czpContract),
            address(wethContract)
        );
        require(pairAddr != address(0), "PAIR NOT CREATED");
        _allPairsWithCzpAndOtherToken.push(pairAddr);
        emit CreatedPairWithCzpAndOtherToken(pairAddr, address(wethContract));
    }

    /**
    @notice Fetches the pair address of a CZP-OtherToken pool
    @param _otherTokenContractAddr Address of the other token contract
    @return poolAddr Address of the pool
     */
    function getCzpAndOtherTokenPairAddr(address _otherTokenContractAddr)
        public
        view
        returns (address poolAddr)
    {
        return
            factoryContract.getPair(
                address(czpContract),
                _otherTokenContractAddr
            );
    }

    /**
    @notice Gets all Pairs with CZP
    @return pairAddrsWithCzpAndOtherToken List of all pairs that contains CZP
     */
    function getAllPairsWithCzpAndOtherToken()
        public
        view
        returns (address[] memory pairAddrsWithCzpAndOtherToken)
    {
        return _allPairsWithCzpAndOtherToken;
    }

    /**
    @notice Manually adds pair addresses to this contract's storage
    @notice Only owners can call this
    @param _pairAddrsToManuallyAdd Array of pair addresses to add
     */
    function manuallyAddPairWithCzpAndOtherToken(
        address[] calldata _pairAddrsToManuallyAdd
    ) external onlyOwners {
        for (uint256 i = 0; i < _pairAddrsToManuallyAdd.length; i++) {
            _allPairsWithCzpAndOtherToken.push(_pairAddrsToManuallyAdd[i]);
        }
    }

    /**
    @notice Adds liquidity to a CZP-OtherToken pair
    @notice Caller must approve this contract to spend the required tokens BEFORE calling this
    @notice Unused CZP and OtherToken are refunded
    @param _otherTokenContractAddr Address of the other token contract
    @param _czpAmtToDeposit Amount of CZP to deposit
    @param _otherTokenAmtToDeposit Amount of other token to deposit
    @param _czpMinAmtToDeposit Minimum amount of CZP to deposit
    @param _otherTokenMinAmtToDeposit Minimum amount of other token to deposit
    @param _deadline Deadline (unix secs) to execute this
    @return czpAmtAdded Amount of CZP added
    @return otherTokenAmtAdded Amount of other token added
    @return liquidityTokensMinted Amount of LP tokens minted to caller
    @dev Emits event AddedLiquidityToCzpAndOtherTokenPair(address indexed otherTokenContractAddr, address indexed liquidityProviderAddr, uint256 czpAmtAdded, uint256 otherTokenAmtAdded, uint256 liquidityTokensMinted);
     */
    function addLiquidityToCzpAndOtherTokenPair(
        address _otherTokenContractAddr,
        uint256 _czpAmtToDeposit,
        uint256 _otherTokenAmtToDeposit,
        uint256 _czpMinAmtToDeposit,
        uint256 _otherTokenMinAmtToDeposit,
        uint256 _deadline
    )
        external
        returns (
            uint256 czpAmtAdded,
            uint256 otherTokenAmtAdded,
            uint256 liquidityTokensMinted
        )
    {
        // Check if pair exist. If not, the proceeding code would add it, so add it now to our list
        address pairAddr = factoryContract.getPair(
            address(czpContract),
            _otherTokenContractAddr
        );
        bool isNewPair = pairAddr == address(0);

        // Transfer tokens to this contract
        czpContract.transferFrom(msg.sender, address(this), _czpAmtToDeposit);
        IERC20(_otherTokenContractAddr).transferFrom(
            msg.sender,
            address(this),
            _otherTokenAmtToDeposit
        );

        // Approve router to spend tokens
        czpContract.approve(address(routerContract), _czpAmtToDeposit);
        IERC20(_otherTokenContractAddr).approve(
            address(routerContract),
            _otherTokenAmtToDeposit
        );

        // Add liquidity with tokens
        (
            czpAmtAdded,
            otherTokenAmtAdded,
            liquidityTokensMinted
        ) = routerContract.addLiquidity(
            address(czpContract),
            _otherTokenContractAddr,
            _czpAmtToDeposit,
            _otherTokenAmtToDeposit,
            _czpMinAmtToDeposit,
            _otherTokenMinAmtToDeposit,
            msg.sender,
            _deadline
        );

        // Refund remaining tokens
        if (czpAmtAdded < _czpAmtToDeposit) {
            czpContract.approve(address(routerContract), 0);
            czpContract.transfer(msg.sender, _czpAmtToDeposit - czpAmtAdded);
        }

        if (otherTokenAmtAdded < _otherTokenAmtToDeposit) {
            IERC20(_otherTokenContractAddr).approve(address(routerContract), 0);
            IERC20(_otherTokenContractAddr).transfer(
                msg.sender,
                _otherTokenAmtToDeposit - otherTokenAmtAdded
            );
        }

        // Add pair to list if this is aa newly created pair
        if (isNewPair) {
            _allPairsWithCzpAndOtherToken.push(
                factoryContract.getPair(
                    address(czpContract),
                    _otherTokenContractAddr
                )
            );
        }

        // Fire event
        emit AddedLiquidityToCzpAndOtherTokenPair(
            _otherTokenContractAddr,
            msg.sender,
            czpAmtAdded,
            otherTokenAmtAdded,
            liquidityTokensMinted
        );
    }

    /**
    @notice Adds liquidity to a CZP-OtherToken pair
    @notice Caller must approve this contract to spend the required tokens BEFORE calling this
    @notice Caller must also provide ETH; treated as ETH to deposit
    @notice Unused CZP and ETH are refunded
    @param _czpAmtToDeposit Amount of CZP to deposit
    @param _czpMinAmtToDeposit Minimum amount of CZP to deposit
    @param _ethMinAmtToDeposit Minimum amount of ETH to deposit
    @param _deadline Deadline (unix secs) to execute this
    @return czpAmtAdded Amount of CZP added
    @return ethAmtAdded Amount of ETH added
    @return liquidityTokensMinted Amount of LP tokens minted to caller
    @dev Emits event AddedLiquidityToCzpAndOtherTokenPair(address indexed otherTokenContractAddr, address indexed liquidityProviderAddr, uint256 czpAmtAdded, uint256 otherTokenAmtAdded, uint256 liquidityTokensMinted);
     */
    function addLiquidityToCzpAndEthPair(
        uint256 _czpAmtToDeposit,
        uint256 _czpMinAmtToDeposit,
        uint256 _ethMinAmtToDeposit,
        uint256 _deadline
    )
        external
        payable
        returns (
            uint256 czpAmtAdded,
            uint256 ethAmtAdded,
            uint256 liquidityTokensMinted
        )
    {
        // Check if pair exist. If not, the proceeding code would add it, so add it now to our list
        address pairAddr = factoryContract.getPair(
            address(czpContract),
            address(wethContract)
        );
        bool isNewPair = pairAddr == address(0);

        // Transfer CZP to this contract
        czpContract.transferFrom(msg.sender, address(this), _czpAmtToDeposit);

        // Approve router to spend CZP
        czpContract.approve(address(routerContract), _czpAmtToDeposit);

        // Add liquidity with CZP and ETH
        (czpAmtAdded, ethAmtAdded, liquidityTokensMinted) = routerContract
            .addLiquidityETH{value: msg.value}(
            address(czpContract),
            _czpAmtToDeposit,
            _czpMinAmtToDeposit,
            _ethMinAmtToDeposit,
            msg.sender,
            _deadline
        );

        // Refund remaining CZP
        if (czpAmtAdded < _czpAmtToDeposit) {
            czpContract.approve(address(routerContract), 0);
            czpContract.transfer(msg.sender, _czpAmtToDeposit - czpAmtAdded);
        }

        // Add pair to list if this is aa newly created pair
        if (isNewPair) {
            _allPairsWithCzpAndOtherToken.push(
                factoryContract.getPair(
                    address(czpContract),
                    address(wethContract)
                )
            );
        }

        // Fire event
        emit AddedLiquidityToCzpAndOtherTokenPair(
            address(wethContract),
            msg.sender,
            czpAmtAdded,
            ethAmtAdded,
            liquidityTokensMinted
        );
    }

    /**
    @notice Removes liquidity from a CZP-OtherToken pair
    @notice Caller must approve this contract to spend the required LP-tokens BEFORE calling this
    @param _otherTokenContractAddr Other token's contract address
    @param _liquidityToWithdraw Amount of liquidity to withdraw
    @param _minCzpToReceive Minimum amount of CZP to receieve
    @param _minOtherTokenToReceive Minimum amount of other tokens to receieve
    @param _deadline Deadline (unix secs) to execute this
    @dev Emits event WithdrawnLiquidityFromCzpAndOtherTokenPair(address indexed otherTokenContractAddr, address indexed liquidityProviderAddr, uint256 czpAmtWithdrawn, uint256 otherTokenAmtWithdrawn, uint256 liquidityTokensSubmitted);
     */
    function withdrawLiquidityForCzpAndOtherToken(
        address _otherTokenContractAddr,
        uint256 _liquidityToWithdraw,
        uint256 _minCzpToReceive,
        uint256 _minOtherTokenToReceive,
        uint256 _deadline
    ) external returns (uint256 czpReceived, uint256 otherTokenReceived) {
        // Check if pair exists
        address pairAddr = factoryContract.getPair(
            address(czpContract),
            _otherTokenContractAddr
        );
        require(pairAddr != address(0), "PAIR DOES NOT EXIST");

        // Transfer LP token to this contract
        IUniswapV2Pair(pairAddr).transferFrom(
            msg.sender,
            address(this),
            _liquidityToWithdraw
        );

        // Approve router to spend LP token
        IUniswapV2Pair(pairAddr).approve(
            address(routerContract),
            _liquidityToWithdraw
        );

        // Withdraw liquidity
        (czpReceived, otherTokenReceived) = routerContract.removeLiquidity(
            address(czpContract),
            _otherTokenContractAddr,
            _liquidityToWithdraw,
            _minCzpToReceive,
            _minOtherTokenToReceive,
            msg.sender,
            _deadline
        );

        // Fire event
        emit WithdrawnLiquidityFromCzpAndOtherTokenPair(
            _otherTokenContractAddr,
            msg.sender,
            czpReceived,
            otherTokenReceived,
            _liquidityToWithdraw
        );
    }

    /**
    @notice Removes liquidity from a CZP-OtherToken pair
    @notice Caller must approve this contract to spend the required LP-tokens BEFORE calling this
    @param _liquidityToWithdraw Amount of liquidity to withdraw
    @param _minCzpToReceive Minimum amount of CZP to receieve
    @param _minEthToReceive Minimum amount of ETH to receieve
    @param _deadline Deadline (unix secs) to execute this
    @dev Emits event WithdrawnLiquidityFromCzpAndOtherTokenPair(address indexed otherTokenContractAddr, address indexed liquidityProviderAddr, uint256 czpAmtWithdrawn, uint256 otherTokenAmtWithdrawn, uint256 liquidityTokensSubmitted);
     */
    function withdrawLiquidityForCzpAndEth(
        uint256 _liquidityToWithdraw,
        uint256 _minCzpToReceive,
        uint256 _minEthToReceive,
        uint256 _deadline
    ) external returns (uint256 czpReceived, uint256 ethReceived) {
        // Check if pair exists
        address pairAddr = factoryContract.getPair(
            address(czpContract),
            address(wethContract)
        );
        require(pairAddr != address(0), "PAIR DOES NOT EXIST");

        // Transfer LP token to this contract
        IUniswapV2Pair(pairAddr).transferFrom(
            msg.sender,
            address(this),
            _liquidityToWithdraw
        );

        // Approve router to spend LP token
        IUniswapV2Pair(pairAddr).approve(
            address(routerContract),
            _liquidityToWithdraw
        );

        // Withdraw liquidity
        (czpReceived, ethReceived) = routerContract.removeLiquidityETH(
            address(czpContract),
            _liquidityToWithdraw,
            _minCzpToReceive,
            _minEthToReceive,
            msg.sender,
            _deadline
        );

        // Fire event
        emit WithdrawnLiquidityFromCzpAndOtherTokenPair(
            address(wethContract),
            msg.sender,
            czpReceived,
            ethReceived,
            _liquidityToWithdraw
        );
    }

    /**
    @notice Called by buyer to pay to seller. Any extra tokens are refunded. Since this is a purchase, a payment transfer fee is charged IN ADDITION to the swapping fees
    @notice Caller must approve this contract to spend the input tokens BEFORE calling this
    @param _recipientAccountId The account id of recipient (for indexing)
    @param _otherTokenContractAddr Address of the token to use for purchase
    @param _otherTokenMaxAmtToPayWith Max amount of the 'other token' to use for purchase
    @param _fiatAmtToPay Fiat to transfer to seller; MUST BE ATOMIC WITH 18 decimals
    @param _deadline Deadline (unix secs) to execute this transaction
    @return otherTokenAmtUsed Amount of 'other token' used
    @return fiatAmountPaid Amount of FIAT paid to seller (with fees deducted); Atomic
    @dev Fires event BoughtWithCrypto(address payerWalletAddr, string recipientAccountId, uint256 cazzPayTransactionId, address tokenUsedForPurchaseContractAddr, uint256 tokenAmtUsedForPurchased, uint256 fiatAmountPaid);
     */
    function buyWithCryptoToken(
        string calldata _recipientAccountId,
        address _otherTokenContractAddr,
        uint256 _otherTokenMaxAmtToPayWith,
        uint256 _fiatAmtToPay,
        uint256 _deadline
    ) external returns (uint256 otherTokenAmtUsed, uint256 fiatAmountPaid) {
        // If 'other token' is czp, no swap is needed, else swap needed
        if (_otherTokenContractAddr == address(czpContract)) {
            // Check if tokens are enough
            require(
                _fiatAmtToPay < _otherTokenMaxAmtToPayWith,
                "INSUFFICIENT MAX AMOUNT"
            );

            // Transfer token to this contract
            czpContract.transferFrom(msg.sender, address(this), _fiatAmtToPay);

            // Calculate fee deducted amount
            uint256 fiatAmtToPayWithFeesDeducted = _calculateAmtWithFeesDeducted(
                    _fiatAmtToPay
                );

            // Burn CZP to simulate FIAT
            czpContract.burn(fiatAmtToPayWithFeesDeducted);

            // Increment transaction ID count
            _cazzPayTransactionId.increment();

            // Emit event
            emit BoughtWithCrypto(
                msg.sender,
                _recipientAccountId,
                _cazzPayTransactionId.current(),
                _otherTokenContractAddr,
                _fiatAmtToPay,
                _fiatAmtToPay,
                fiatAmtToPayWithFeesDeducted
            );

            // Return
            return (_fiatAmtToPay, fiatAmtToPayWithFeesDeducted);
        } else {
            // If 'other token' is not CZP, swapping is needed

            // Check to see if Pair exists
            require(
                factoryContract.getPair(
                    address(czpContract),
                    _otherTokenContractAddr
                ) != address(0),
                "PAIR DOES NOT EXIST"
            );

            // Transfer tokens to this contract
            IERC20(_otherTokenContractAddr).transferFrom(
                msg.sender,
                address(this),
                _otherTokenMaxAmtToPayWith
            );

            // Approve router to spend tokens
            IERC20(_otherTokenContractAddr).approve(
                address(routerContract),
                _otherTokenMaxAmtToPayWith
            );

            // Swap tokens
            address[] memory swapPath = new address[](2);
            swapPath[0] = _otherTokenContractAddr;
            swapPath[1] = address(czpContract);
            uint256[] memory amounts = routerContract.swapTokensForExactTokens(
                _fiatAmtToPay,
                _otherTokenMaxAmtToPayWith,
                swapPath,
                address(this),
                _deadline
            );
            otherTokenAmtUsed = amounts[0];

            // Calculate fee deducted amount
            uint256 fiatAmtToPayWithFeesDeducted = _calculateAmtWithFeesDeducted(
                    _fiatAmtToPay
                );

            // Burn CZP to simulate FIAT
            czpContract.burn(fiatAmtToPayWithFeesDeducted);

            // Refund unused tokens
            if (otherTokenAmtUsed < _otherTokenMaxAmtToPayWith) {
                IERC20(_otherTokenContractAddr).approve(
                    address(routerContract),
                    0
                );
                IERC20(_otherTokenContractAddr).transfer(
                    msg.sender,
                    _otherTokenMaxAmtToPayWith - otherTokenAmtUsed
                );
            }

            // Increment transaction ID count
            _cazzPayTransactionId.increment();

            // Emit event
            emit BoughtWithCrypto(
                msg.sender,
                _recipientAccountId,
                _cazzPayTransactionId.current(),
                _otherTokenContractAddr,
                otherTokenAmtUsed,
                _fiatAmtToPay,
                fiatAmtToPayWithFeesDeducted
            );

            // Return
            return (otherTokenAmtUsed, fiatAmtToPayWithFeesDeducted);
        }
    }

    /**
    @notice Called by buyer to pay to seller. Any extra eth is refunded. Since this is a purchase, a payment transfer fee is charged IN ADDITION to the swapping fees
    @dev msg.value is treated as ethMaxAmtToPayWith
    @param _recipientAccountId The account id of recipient (for indexing)
    @param _fiatAmtToPay Fiat to transfer to seller; MUST BE ATOMIC WITH 18 decimals
    @param _deadline Deadline (unix secs) to execute this transaction
    @return ethAmtUsed Amount of ETH used
    @return fiatAmountPaid Amount of FIAT paid to seller (with fees deducted); Atomic
    @dev Fires event BoughtWithCrypto(address payerWalletAddr, string recipientAccountId, uint256 cazzPayTransactionId, address tokenUsedForPurchaseContractAddr, uint256 tokenAmtUsedForPurchased, uint256 fiatAmountPaid);
     */
    function buyWithEth(
        string calldata _recipientAccountId,
        uint256 _fiatAmtToPay,
        uint256 _deadline
    ) external payable returns (uint256 ethAmtUsed, uint256 fiatAmountPaid) {
        // Check to see if Pair exists
        require(
            factoryContract.getPair(
                address(czpContract),
                address(wethContract)
            ) != address(0),
            "PAIR DOES NOT EXIST"
        );

        // Swap tokens
        address[] memory swapPath = new address[](2);
        swapPath[0] = address(wethContract);
        swapPath[1] = address(czpContract);
        uint256[] memory amounts = routerContract.swapETHForExactTokens{
            value: msg.value
        }(_fiatAmtToPay, swapPath, address(this), _deadline);
        ethAmtUsed = amounts[0];

        // Calculate fee deducted amount
        uint256 fiatAmtToPayWithFeesDeducted = _calculateAmtWithFeesDeducted(
            _fiatAmtToPay
        );

        // Burn CZP to simulate FIAT
        czpContract.burn(fiatAmtToPayWithFeesDeducted);

        // Increment transaction ID count
        _cazzPayTransactionId.increment();

        // Refund unused ETH
        if (ethAmtUsed < msg.value) {
            (bool success, ) = payable(msg.sender).call{
                value: msg.value - ethAmtUsed
            }("");
            require(success, "CALLER NOT REFUNDED");
        }

        // Emit event
        emit BoughtWithCrypto(
            msg.sender,
            _recipientAccountId,
            _cazzPayTransactionId.current(),
            address(wethContract),
            ethAmtUsed,
            _fiatAmtToPay,
            fiatAmtToPayWithFeesDeducted
        );

        // Return
        return (ethAmtUsed, fiatAmtToPayWithFeesDeducted);
    }

    /**
    @notice Function to swap tokens; swaps exact amount of Other tokens for maximum CZP tokens
    @notice Caller must approve this contract to spend the input tokens BEFORE calling this
    @param _otherTokenContractAddr Address of the Other token contract
    @param _otherTokenAmt Exact Other tokens amount
    @param _czpMinAmt Minimum output CZP to receive
    @param _deadline Deadline (unix secs) to execute this transaction
    @return otherTokenAmtUsed Other token amount used for swapping
    @return czpAmtReceived Amount of CZP received after swapping
    @dev Fires event event TokensSwapped(address inputTokenContractAddr, address outputTokenContractAddr, uint256 inputTokenAmt, uint256 outputTokenAmt);
     */
    function swapOtherTokensForCzp(
        address _otherTokenContractAddr,
        uint256 _otherTokenAmt,
        uint256 _czpMinAmt,
        uint256 _deadline
    ) external returns (uint256 otherTokenAmtUsed, uint256 czpAmtReceived) {
        return
            _swapTokens(
                _otherTokenContractAddr,
                address(czpContract),
                _otherTokenAmt,
                _czpMinAmt,
                _deadline
            );
    }

    /**
    @notice Function to swap tokens; swaps exact amount of Other tokens for maximum CZP tokens
    @notice Caller must approve this contract to spend the input tokens BEFORE calling this
    @param _otherTokenContractAddr Address of the Other token contract
    @param _czpAmt Exact CZP tokens amount
    @param _otherTokenMinAmt Minimum Other tokens to receive
    @param _deadline Deadline (unix secs) to execute this transaction
    @return czpAmtUsed Other token amount used for swapping
    @return otherTokenAmtReceived Amount of other tokens received after swapping
    @dev Fires event event TokensSwapped(address inputTokenContractAddr, address outputTokenContractAddr, uint256 inputTokenAmt, uint256 outputTokenAmt);
     */
    function swapCzpForOtherTokens(
        address _otherTokenContractAddr,
        uint256 _czpAmt,
        uint256 _otherTokenMinAmt,
        uint256 _deadline
    ) external returns (uint256 czpAmtUsed, uint256 otherTokenAmtReceived) {
        return
            _swapTokens(
                address(czpContract),
                _otherTokenContractAddr,
                _czpAmt,
                _otherTokenMinAmt,
                _deadline
            );
    }

    ///////////////////////////
    // INTERNAL FUNCTIONS
    ///////////////////////////

    /**
    @notice Calculates the amount after deducting fees from it
    @param _totalAmt Total amount to deduct fees from
    @return totalAmtWithFeesDeducted Amount after fees would be deducted
     */
    function _calculateAmtWithFeesDeducted(uint256 _totalAmt)
        internal
        view
        returns (uint256 totalAmtWithFeesDeducted)
    {
        totalAmtWithFeesDeducted =
            _totalAmt -
            ((_totalAmt * paymentTransferFeesPerc) / 10000);
        return totalAmtWithFeesDeducted;
    }

    /**
    @notice Function to swap tokens; swaps exact amount of input tokens for maximum output tokens
    @notice Caller must approve this contract to spend the input tokens BEFORE calling this
    @param _inputTokenContractAddr Address of the input token contract
    @param _outputTokenContractAddr Address of the output token contract
    @param _inputTokenAmt Exact input tokens amount
    @param _outputTokenMinAmt Minimum output tokens to receive
    @param _deadline Deadline (unix secs) to execute this transaction
    @return inputTokenAmtUsed Input token amount used for swapping
    @return outputTokenAmtReceived Amount of output token received after swapping
     */
    function _swapTokens(
        address _inputTokenContractAddr,
        address _outputTokenContractAddr,
        uint256 _inputTokenAmt,
        uint256 _outputTokenMinAmt,
        uint256 _deadline
    )
        internal
        returns (uint256 inputTokenAmtUsed, uint256 outputTokenAmtReceived)
    {
        // Transfer input tokens to this contract
        IERC20(_inputTokenContractAddr).transferFrom(
            msg.sender,
            address(this),
            _inputTokenAmt
        );

        // Approve router to spend the input tokens
        IERC20(_inputTokenContractAddr).approve(
            address(routerContract),
            _inputTokenAmt
        );

        // Perform token swap
        address[] memory swapPath = new address[](2);
        swapPath[0] = _inputTokenContractAddr;
        swapPath[1] = _outputTokenContractAddr;
        uint256[] memory amounts = routerContract.swapExactTokensForTokens(
            _inputTokenAmt,
            _outputTokenMinAmt,
            swapPath,
            msg.sender,
            _deadline
        );
        inputTokenAmtUsed = amounts[0];
        outputTokenAmtReceived = amounts[1];

        // Emit event
        emit TokensSwapped(
            _inputTokenContractAddr,
            _outputTokenContractAddr,
            inputTokenAmtUsed,
            outputTokenAmtReceived
        );
    }

    /**
    @notice Used to emit events containing Seller info. These events can be indexed to get a list of sellers.
    @notice Can only be called by an owner
    @param _sellerId Any string id representing the seller; must be unique between sellers
    @param _email Email of the seller
    @param _name Name of the seller
     */
    function storeSellerInfo(
        string calldata _sellerId,
        string calldata _email,
        string calldata _name
    ) external onlyOwners {
        emit SellerInfo(_sellerId, _email, _name);
    }

    /**
    @notice Call this (via an owner) to confirm a purchase
    @notice This confirmation is to prevent double-spending, because the event emitted in this function gives the client a way to index events and find out if this transaction id is already verified, thus recognising double-spending attempts.
    @notice Can only be called by owners
    @param _cazzPayTransactionIdToConfirm CazzPayTransactionId to set as confirmed
     */
    function setPurchaseConfirmation(uint256 _cazzPayTransactionIdToConfirm)
        external
        onlyOwners
    {
        require(
            _cazzPayTransactionIdToConfirm <= _cazzPayTransactionId.current(),
            "TRANSACTION NEVER HAPPENED"
        );
        emit PurchaseConfirmed(_cazzPayTransactionIdToConfirm);
    }

    /**
    @notice Receive method, to allow other contracts to safely send ETH to this contract
     */
    receive() external payable {}

    /**
    @notice This withdraws all balance to a mentioned wallet
     */
    function withdraw(address payable _withdrawToAddr) external onlyOwners {
        // Transfer all ETH
        (bool successEth, ) = _withdrawToAddr.call{
            value: address(this).balance
        }("");
        require(successEth, "ETH WITHDRAW FAILED");

        // Transfer all $CZP
        uint256 balanceCzp = czpContract.balanceOf(address(this));
        bool successCzp = czpContract.transfer(_withdrawToAddr, balanceCzp);
        require(successCzp, "CZP WITHDRAW FAILED");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@uniswap/v2-core/contracts/interfaces/IERC20.sol";

interface ICazzPayToken is IERC20 {
    // @summary Mints specified amount of $CZP to an address
    // @notice Only callable by an owner
    // @dev MAKE SURE TO CALL THIS ALONG WITH FIAT TRANSFER
    // @param _mintTo Address to mint to
    // @param _amtToMint Amount of tokens to mint
    function mintTokens(address _mintTo, uint256 _amtToMint) external;

    // @notice Burns tokens owned by msg.sender
    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";

contract MultiOwnable {
    // Add the library methods
    using EnumerableSet for EnumerableSet.AddressSet;

    // Stores array of owners
    EnumerableSet.AddressSet private _owners;

    // Modifier
    modifier onlyOwners() {
        require(_owners.contains(msg.sender), "NOT OWNER");
        _;
    }

    // Constructor
    constructor() public {
        _owners.add(msg.sender);
    }

    // @summary Adds an owner
    // @notice Only callable by an existing owner
    // @param _newOwner Address of the new owner
    function addOwner(address _newOwner) external onlyOwners {
        _addOwner(_newOwner);
    }

    // @summary Removes an owner
    // @notice Only callable by an existing owner
    // @param _ownerToRemove Address of the new owner
    function removeOwner(address _ownerToRemove) external onlyOwners {
        _removeOwner(_ownerToRemove);
    }

    // @summary Checks to see if an address is an owner
    // @param _ownerToVerify Address of the owner to verify
    // @returns True, if the address is an owner, else false
    function isOwner(address _ownerToVerify) public view returns (bool) {
        return _owners.contains(_ownerToVerify);
    }

    /////////////////////////////
    // Internal mirror functions
    /////////////////////////////

    function _addOwner(address _newOwner) internal {
        _owners.add(_newOwner);
    }

    function _removeOwner(address _ownerToRemove) internal {
        _owners.remove(_ownerToRemove);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "./ECDSA.sol";
import "@uniswap/v2-core/contracts/interfaces/IERC20.sol";
import "../../Ownable/MultiOwnable.sol";

contract CazzPayOracle is MultiOwnable {
    ////////////////////////////
    // STORAGE
    ////////////////////////////
    address public approvedPriceFeedSigner;

    ////////////////////////////
    // FUNCTIONS
    ////////////////////////////

    /**
    @notice Constructor for contract
    @param _approvedPriceFeedSigner Authorised signer to provide price feeds
     */
    constructor(address _approvedPriceFeedSigner) public {
        approvedPriceFeedSigner = _approvedPriceFeedSigner;
    }

    /**
    @notice Function to change authorised signer to provide price feeds
    @param _newApprovedPriceFeedSigner Authorised signer to provide price feeds
     */
    function setApprovedPriceFeedSigner(address _newApprovedPriceFeedSigner)
        public
        onlyOwners
    {
        approvedPriceFeedSigner = _newApprovedPriceFeedSigner;
    }

    /**
    @notice Function to get price of a token in $CZP (atomic)
    @dev Make sure to call this as specified here: https://github.com/redstone-finance/redstone-evm-connector#2-updating-the-interface
    @param _tokenSymbol Symbol of the ERC20 token to know the price of
    @return priceOfTokenInCzp Price of the token, in $CZP (or $USD), in atomic form (10^18 = 1 $CZP)
     */
    function getPriceOfTokenInCzpWithTokenSymbol(string memory _tokenSymbol)
        public
        view
        returns (uint256)
    {
        return (getPriceFromMsg(_stringToBytes32(_tokenSymbol)) * (10**10));
    }

    /**
    @notice Function to get price of a token in $CZP (atomic)
    @dev Make sure to call this as specified here: https://github.com/redstone-finance/redstone-evm-connector#2-updating-the-interface
    @param _tokenContractAddr Address of the ERC20 token contract to know the price of
    @return priceOfTokenInCzp Price of the token, in $CZP (or $USD), in atomic form (10^18 = 1 $CZP)
     */
    function getPriceOfTokenInCzpWithTokenAddress(address _tokenContractAddr)
        public
        view
        returns (uint256)
    {
        return (getPriceFromMsg(
            _stringToBytes32(IERC20(_tokenContractAddr).symbol())
        ) * (10**10));
    }

    ////////////////////////////
    // OVERRIDE FUNCTIONS
    ////////////////////////////

    /**
    @dev Checks to see if the signer of the received price feed is authorised
     */
    function isSignerAuthorized(address _receivedSigner)
        public
        view
        returns (bool)
    {
        return _receivedSigner == approvedPriceFeedSigner; // Redstone Demo signer
    }

    ////////////////////////////
    // INTERNAL FUNCTIONS
    ////////////////////////////

    /**
    @dev Converts a string to bytes32
    @return result Bytes32 form of the input string
     */
    function _stringToBytes32(string memory source)
        internal
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    //////////////////////////////////////////////////////
    // PriceAware.sol, from 'redstone-evm-connector'
    //////////////////////////////////////////////////////
    using ECDSA for bytes32;

    uint256 private constant _MAX_DATA_TIMESTAMP_DELAY = 3 * 60; // 3 minutes
    uint256 private constant _MAX_BLOCK_TIMESTAMP_DELAY = 15; // 15 seconds

    /* ========== VIRTUAL FUNCTIONS (MAY BE OVERRIDEN IN CHILD CONTRACTS) ========== */

    function getMaxDataTimestampDelay() public pure returns (uint256) {
        return _MAX_DATA_TIMESTAMP_DELAY;
    }

    function getMaxBlockTimestampDelay() public pure returns (uint256) {
        return _MAX_BLOCK_TIMESTAMP_DELAY;
    }

    function isTimestampValid(uint256 _receivedTimestamp)
        public
        view
        virtual
        returns (bool)
    {
        // Getting data timestamp from future seems quite unlikely
        // But we've already spent too much time with different cases
        // Where block.timestamp was less than dataPackage.timestamp.
        // Some blockchains may case this problem as well.
        // That's why we add MAX_BLOCK_TIMESTAMP_DELAY
        // and allow data "from future" but with a small delay
        require(
            (block.timestamp + getMaxBlockTimestampDelay()) >
                _receivedTimestamp,
            "Data with future timestamps is not allowed"
        );

        return
            block.timestamp < _receivedTimestamp ||
            block.timestamp - _receivedTimestamp < getMaxDataTimestampDelay();
    }

    /* ========== FUNCTIONS WITH IMPLEMENTATION (CAN NOT BE OVERRIDEN) ========== */

    function getPriceFromMsg(bytes32 symbol) internal view returns (uint256) {
        bytes32[] memory symbols = new bytes32[](1);
        symbols[0] = symbol;
        return getPricesFromMsg(symbols)[0];
    }

    function getPricesFromMsg(bytes32[] memory symbols)
        internal
        view
        returns (uint256[] memory)
    {
        // The structure of calldata witn n - data items:
        // The data that is signed (symbols, values, timestamp) are inside the {} brackets
        // [origina_call_data| ?]{[[symbol | 32][value | 32] | n times][timestamp | 32]}[size | 1][signature | 65]

        // 1. First we extract dataSize - the number of data items (symbol,value pairs) in the message
        uint8 dataSize; //Number of data entries
        assembly {
            // Calldataload loads slots of 32 bytes
            // The last 65 bytes are for signature
            // We load the previous 32 bytes and automatically take the 2 least significant ones (casting to uint16)
            dataSize := calldataload(sub(calldatasize(), 97))
        }

        // 2. We calculate the size of signable message expressed in bytes
        // ((symbolLen(32) + valueLen(32)) * dataSize + timeStamp length
        uint16 messageLength = uint16(dataSize) * 64 + 32; //Length of data message in bytes

        // 3. We extract the signableMessage

        // (That's the high level equivalent 2k gas more expensive)
        // bytes memory rawData = msg.data.slice(msg.data.length - messageLength - 65, messageLength);

        bytes memory signableMessage;
        assembly {
            signableMessage := mload(0x40)
            mstore(signableMessage, messageLength)
            // The starting point is callDataSize minus length of data(messageLength), signature(65) and size(1) = 66
            calldatacopy(
                add(signableMessage, 0x20),
                sub(calldatasize(), add(messageLength, 66)),
                messageLength
            )
            mstore(0x40, add(signableMessage, 0x20))
        }

        // 4. We first hash the raw message and then hash it again with the prefix
        // Following the https://github.com/ethereum/eips/issues/191 standard
        bytes32 hash = keccak256(signableMessage);
        bytes32 hashWithPrefix = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );

        // 5. We extract the off-chain signature from calldata

        // (That's the high level equivalent 2k gas more expensive)
        // bytes memory signature = msg.data.slice(msg.data.length - 65, 65);
        bytes memory signature;
        assembly {
            signature := mload(0x40)
            mstore(signature, 65)
            calldatacopy(add(signature, 0x20), sub(calldatasize(), 65), 65)
            mstore(0x40, add(signature, 0x20))
        }

        // 6. We verify the off-chain signature against on-chain hashed data

        address signer = hashWithPrefix.recover(signature);
        require(isSignerAuthorized(signer), "Signer not authorized");

        // 7. We extract timestamp from callData

        uint256 dataTimestamp;
        assembly {
            // Calldataload loads slots of 32 bytes
            // The last 65 bytes are for signature + 1 for data size
            // We load the previous 32 bytes
            dataTimestamp := calldataload(sub(calldatasize(), 98))
        }

        // 8. We validate timestamp
        require(isTimestampValid(dataTimestamp), "Data timestamp is invalid");

        return _readFromCallData(symbols, uint256(dataSize), messageLength);
    }

    function _readFromCallData(
        bytes32[] memory symbols,
        uint256 dataSize,
        uint16 messageLength
    ) private pure returns (uint256[] memory) {
        uint256[] memory values;
        uint256 i;
        uint256 j;
        uint256 readyAssets;
        bytes32 currentSymbol;

        // We iterate directly through call data to extract the values for symbols
        assembly {
            let start := sub(calldatasize(), add(messageLength, 66))

            values := msize()
            mstore(values, mload(symbols))
            mstore(0x40, add(add(values, 0x20), mul(mload(symbols), 0x20)))

            for {
                i := 0
            } lt(i, dataSize) {
                i := add(i, 1)
            } {
                currentSymbol := calldataload(add(start, mul(i, 64)))

                for {
                    j := 0
                } lt(j, mload(symbols)) {
                    j := add(j, 1)
                } {
                    if eq(
                        mload(add(add(symbols, 32), mul(j, 32))),
                        currentSymbol
                    ) {
                        mstore(
                            add(add(values, 32), mul(j, 32)),
                            calldataload(add(add(start, mul(i, 64)), 32))
                        )
                        readyAssets := add(readyAssets, 1)
                    }

                    if eq(readyAssets, mload(symbols)) {
                        i := dataSize
                    }
                }
            }
        }

        return (values);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
     * @dev Returns the number of values on the set. O(1).
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
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
    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(
                    vs,
                    0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                )
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
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
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, structHash)
            );
    }
}