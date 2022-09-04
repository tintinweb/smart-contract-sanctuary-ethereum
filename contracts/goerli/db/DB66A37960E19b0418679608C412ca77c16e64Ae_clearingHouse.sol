// SPDX-License-Identifier: Unlicensed

// Work progress: Needs constant improvement and adjustment. 
// Contract on rinkeby: 
// UNI on rinkeby: 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984, USDC on rinkeby: 0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b, WETH on rinkeby: 0xc778417e063141139fce010982780140aa0cd5ab
// AEX on rinkeby: 0x21e4E26bba6E3001bB612f2DB41b284501888e99
// Pairs on rinkeby: 0x1f71FE9bC82B06e5E4944b92F6c568C149F2a411

// Needs LOTS OF TESTING! Need to test:-
// 1. Test contract when maker and taker fee changes.
// 2. Test it for re-entrancy after adding re-entrancy guard.

pragma solidity ^0.8.15;

// for SnaY: don't change the first 4 existing functions, they're being used as abi in backend

library dexUtils {
    function checkSignature(address signer, bytes32 messageHash, bytes memory signature) internal pure returns(bool) {
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(signature);
        if(ecrecover(ethSignedMessageHash, v, r, s) == signer) {
            return true;
        } else {
            return false;
        }
    }

    function getOrderHash(address maker, address makerCoinContract, address takerCoinContract, uint256 makerQty, uint256 takerQty, uint256 deadline, uint256 nonce, bool increaseNonceOnCompleteFill) internal pure returns (bytes32) {
        return keccak256(abi.encode(maker, makerCoinContract, takerCoinContract, makerQty, takerQty, deadline, nonce, increaseNonceOnCompleteFill));
    }

    function _splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function checkQuoteContract(address makerContract, address takerContract, address[] memory _quoteContracts) internal pure returns(address) {
        address _quoteContract = address(0);
        
        if(_checkContractAddress(makerContract, _quoteContracts)) {
            _quoteContract = makerContract;
        
        } else if(_checkContractAddress(takerContract, _quoteContracts)) {
            _quoteContract = takerContract;
        }

        return _quoteContract;
    }

    function _checkContractAddress(address contractToBeChecked, address[] memory contractsList) internal pure returns(bool) {        
        for(uint256 n = 0; n < contractsList.length; n++) {
            if(contractsList[n] == contractToBeChecked) return true;
        }

        return false;
    }

    // Returns answers with 8 decimal places, change this function eventually and get price directly from price oracle.

    function getAEXPrice() internal pure returns(uint256) {
        // $0.1
        return(10000000);
    }
}

pragma solidity ^0.8.15;
interface xchg_interface {

    function getQuoteContracts() external view returns(address[] memory);
    function getWhitelistedBaseContracts() external view returns(address[] memory);
    function getNativeWrappedContract() external view returns(address);
}

interface wrappedCoin {
    function getMasterContract() external view returns(address);
    function getCoinTax() external view returns(uint256);
}

contract clearingHouse {

    struct OrderInfo {
        address taker;
        address maker;
        address makerCoinContract;
        address takerCoinContract;
        uint256 totalMakerQty;
        uint256 totalTakerQty;
        uint256 toBeSentByTaker;
        bool increaseNonceOnCompleteFill;
        uint256 toBeSentByMaker;
        bytes32 messageHash;
    }

    event TradeExecuted (bytes32 indexed orderHash, address indexed taker, uint256 filledTakerQty, uint256 maker_fees, uint256 taker_fees, uint256 AEX_maker_fees, uint256 AEX_taker_fees);

    mapping(address => uint256) public nonces;
    mapping(bytes32 => uint256) public orderFilledTakerQty; // keccak256 mesasge hash => filledTakerQty
    mapping(address => bool) public payFeesUsingAEX;
    uint256 maker_fee;
    uint256 taker_fee;
    address manager;
    address xchgInterfaceAddress;
    address AEXToken;
    uint256 AEXDiscount;

    constructor(address _xchgInterfaceAddress, address _AEXToken /*, uint256 _makerFee, uint256 _takerFee, address _manager */) {
        // Have an option to change this address as well if you have to change interface address anytime. Also a function to change fees and discount
        xchgInterfaceAddress = _xchgInterfaceAddress;
        AEXToken = _AEXToken;
        maker_fee = 750; // Percentage fee = divided by 10k, decimal notation: divided by 1mil
        taker_fee = 750;
        AEXDiscount = 25;
    }

    modifier onlyMaker(address maker) {
        require(maker == msg.sender, "ERROR: Order can only be by cancelled by it's maker.");
        _;
    }

    modifier onlyManager(address _manager) {
        require(_manager == msg.sender, "ERROR: Only the manager can run this function.");
        _;
    }

    // modifier checkBalancesAndApproval() {
        
    // }

    // The frontend will convert the wrapped coin balance to the balance of the actual coins and back. We won't be showing the wrapped coin balnace to the user, it will end up confusing them. 
    // Take care of the wrapped coin as well please. 

    // The frontend will take care and keep track of complete and partial fills. The job of the contract is just to do proper execution. Hence, orderFilledTakerQty won't always be accurate and on full fills, sometimes the whole nonce is just cancelled.

    function takePublicOrder(address maker, address makerCoinContract, address takerCoinContract, uint256 totalMakerQty, uint256 totalTakerQty, uint64 deadline, uint64 nonce, bool increaseNonceOnCompleteFill, bytes memory signature, uint256 toBeSentByTaker) public {
        bytes32 orderHash = dexUtils.getOrderHash(maker, makerCoinContract, takerCoinContract, totalMakerQty, totalTakerQty, deadline, nonce, increaseNonceOnCompleteFill);
        OrderInfo memory o = OrderInfo(msg.sender, maker, makerCoinContract, takerCoinContract, totalMakerQty, totalTakerQty, toBeSentByTaker, increaseNonceOnCompleteFill, 0, orderHash);

        require(nonce == nonces[maker], "takePublicOrder: ORDER_CANCELLED_OR_ALREADY_FILLED");
        require(deadline >= block.timestamp, "takePublicOrder: ORDER_EXPIRED");
        require(dexUtils.checkSignature(o.maker, orderHash, signature), "takePublicOrder: INVALID_SIGNATURE");

        require(orderFilledTakerQty[orderHash] != (2**256)-1, "takePublicOrder: ORDER_ALREADY_EXECUTED_OR_CANCELLED");
        require(toBeSentByTaker <= totalTakerQty - orderFilledTakerQty[orderHash], "takePublicOrder: INSUFFICIENT_QUANTITY_AVAILABLE"); // To be sentByTaker amount has been verified
        require(toBeSentByTaker != 0, "takePublicOrder: NOT_ALLOWED_TO_TAKE_0_QUANTITY");

        require(maker != address(0) && msg.sender != address(0), "takePublicOrder: maker or taker cannot be 0x00 address.");
        require(makerCoinContract != address(0) && takerCoinContract != address(0), "takePublicOrder: neither of the coin contracts can be 0 address.");
        require(makerCoinContract != takerCoinContract, "takePublicOrder: makerCoinContract and takerCoinContract cannot be the same.");

        // Signature is valid + quantity is available. Continue to step 2.
        address quoteContract = _checkQuote(o);
        _updateOrder(o); // Updating order first, state changes first. 
        _calculateFeesAndExecuteTx(o, quoteContract); // External calls at last. 
    }

    function _checkQuote(OrderInfo memory o) internal view returns(address) { // (quote)
        // Just need to know which the quote contract is

        xchg_interface xchg_inter = xchg_interface(xchgInterfaceAddress);

        address[] memory _quoteContracts = xchg_inter.getQuoteContracts();

        address quoteContract = dexUtils.checkQuoteContract(o.makerCoinContract, o.takerCoinContract, _quoteContracts);
        require(quoteContract != address(0), "takePublicOrder: Invalid quote contract");

        return quoteContract;
    }

    function _calculateFeesAndExecuteTx(OrderInfo memory i, address quoteContract) internal { // remove view returns
        // Check the AEX token balance, if not found then yeah use the fee addition and deduction method. 
        uint256 makerFees;
        uint256 takerFees;

        i.toBeSentByMaker = (i.totalMakerQty * (i.toBeSentByTaker * 1e10) / i.totalTakerQty) / 1e10;

        // Check balances of both maker and taker
        uint256 aex_maker_balance = IERC20(AEXToken).balanceOf(i.maker);
        uint256 aex_taker_balance = IERC20(AEXToken).balanceOf(msg.sender);

        if(i.makerCoinContract == quoteContract) {
            // First check how much fees is needed to be paid extra by maker
            makerFees = (i.toBeSentByMaker * maker_fee) / 1000000; // Maker fee in the quote stablecoin that is to be paid extra, that could have any decimals.
            takerFees = (i.toBeSentByMaker * taker_fee) / 1000000; // Here could be a problem, because USDC is 6 decimals. This only works under fee deduction, fee addition will fuck this up. WORRY ABOUT STABLECOIN TRADES LATER.
        } else {
            // Taker is quote, WORRY ABOUT STABLECOIN TRADES LATER, WHEN BOTH ARE QUOTES. Maybe make a seperate function for that later.
            takerFees = (i.toBeSentByTaker * taker_fee) / 1000000;
            makerFees = (i.toBeSentByTaker * maker_fee) / 1000000;
        }

        // So i have to assume that both the stablecoin and the AEX have the same decimal places.
        if(IERC20(quoteContract).decimals() != IERC20(AEXToken).decimals()) { // NEW IMPLEMENTATION, MIGHT HAVE ERROR. Use USDC to find answer.
            // Always assumes that AEX decimals, 18, is larger. Try this with USDC. 
            uint256 decimalsToAdd = IERC20(AEXToken).decimals() - IERC20(quoteContract).decimals();
            makerFees = makerFees * 10^decimalsToAdd;
            takerFees = takerFees * 10^decimalsToAdd;
        }
        
        // Now makerFees and takerFees has been corrected, getting AEX fees from price.
        uint256 AEXMakerFees = makerFees / (dexUtils.getAEXPrice() / (10^8)); // Calculated from stablecoin. 10^8 because of 8 decimals
        uint256 AEXTakerFees = takerFees / (dexUtils.getAEXPrice() / (10^8));

        if(quoteContract == i.makerCoinContract) _executeTxMakerIsQuote(i, aex_taker_balance, aex_maker_balance, AEXMakerFees, AEXTakerFees, makerFees, takerFees);
        if(quoteContract == i.takerCoinContract) _executeTxTakerIsQuote(i, aex_taker_balance, aex_maker_balance, AEXMakerFees, AEXTakerFees, makerFees, takerFees);
    }

    function _executeTxMakerIsQuote(OrderInfo memory i, uint256 aex_taker_balance, uint256 aex_maker_balance, uint256 aex_maker_fees, uint256 aex_taker_fees, uint256 makerFees, uint256 takerFees) internal {
        // Maker holds the quote contract, he goes first

        IERC20 _makerCoinContract = IERC20(i.makerCoinContract);
        IERC20 _takerCoinContract = IERC20(i.takerCoinContract);

        if(aex_maker_balance >= aex_maker_fees && payFeesUsingAEX[i.maker]) {
            // Maker is paying using AEX
            if(aex_taker_balance >= aex_taker_fees && payFeesUsingAEX[i.taker]) {
                // Maker in AEX, Taker in AEX
                require(_makerCoinContract.balanceOf(i.maker) >= i.toBeSentByMaker, "_executeTx: INSUFFICIENT_MAKER_BALANCE");
                require(_makerCoinContract.allowance(i.maker, address(this)) >= i.toBeSentByMaker, "_executeTx: MAKER_APPROVAL_MISSING");

                TransferHelper.safeTransferFrom(i.makerCoinContract, i.maker, i.taker, i.toBeSentByMaker); // Taker is paying in AEX as well, so we send quote directly.
                TransferHelper.safeTransferFrom(AEXToken, i.maker, address(this), aex_maker_fees);

                // Taker execution next
                require(_takerCoinContract.balanceOf(i.taker) >= i.toBeSentByTaker, "_executeTx: INSUFFICIENT_TAKER_BALANCE");
                require(_takerCoinContract.allowance(i.taker, address(this)) >= i.toBeSentByTaker, "_executeTx: TAKER_APPROVAL_MISSING");

                TransferHelper.safeTransferFrom(i.takerCoinContract, i.taker, i.maker, i.toBeSentByTaker);
                TransferHelper.safeTransferFrom(AEXToken, i.taker, address(this), aex_taker_fees); // checked, correct
            } else {
                // Maker AEX, taker quote
                require(_makerCoinContract.balanceOf(i.maker) >= i.toBeSentByMaker, "_executeTx: INSUFFICIENT_MAKER_BALANCE");
                require(_makerCoinContract.allowance(i.maker, address(this)) >= i.toBeSentByMaker, "_executeTx: MAKER_APPROVAL_MISSING");

                TransferHelper.safeTransferFrom(i.makerCoinContract, i.maker, address(this), i.toBeSentByMaker); // Taker is paying in quote, so first send quote to address(this).
                TransferHelper.safeTransferFrom(AEXToken, i.maker, address(this), aex_maker_fees);
                
                // Taker execution
                require(_takerCoinContract.balanceOf(i.taker) >= i.toBeSentByTaker, "_executeTx: INSUFFICIENT_TAKER_BALANCE");
                require(_takerCoinContract.allowance(i.taker, address(this)) >= i.toBeSentByTaker, "_executeTx: TAKER_APPROVAL_MISSING");
                
                TransferHelper.safeTransferFrom(i.takerCoinContract, i.taker, i.maker, i.toBeSentByTaker); // Direct base transfer, taker to maker
                TransferHelper.safeTransfer(i.makerCoinContract, i.taker, i.toBeSentByMaker - takerFees);
            }
        } else {
            // Maker is paying in quote
            if(aex_taker_balance >= aex_taker_fees && payFeesUsingAEX[i.taker]) {
                // Taker is paying in AEX, maker quote
                require(_makerCoinContract.balanceOf(i.maker) >= i.toBeSentByMaker + makerFees, "_executeTx: INSUFFICIENT_MAKER_BALANCE (including fees)");
                require(_makerCoinContract.allowance(i.maker, address(this)) >= i.toBeSentByMaker + makerFees, "_executeTx: MAKER_APPROVAL_MISSING (including fees)");

                TransferHelper.safeTransferFrom(i.makerCoinContract, i.maker, address(this), i.toBeSentByMaker + makerFees); // Add extra quote fee
                TransferHelper.safeTransfer(i.makerCoinContract, i.taker, i.toBeSentByMaker);

                require(_takerCoinContract.balanceOf(i.taker) >= i.toBeSentByTaker, "_executeTx: INSUFFICIENT_TAKER_BALANCE");
                require(_takerCoinContract.allowance(i.taker, address(this)) >= i.toBeSentByTaker, "_executeTx: TAKER_APPROVAL_MISSING");

                TransferHelper.safeTransferFrom(i.takerCoinContract, i.taker, i.maker, i.toBeSentByTaker);
                TransferHelper.safeTransferFrom(AEXToken, i.taker, address(this), aex_taker_fees);
            } else {
                // Maker isn't doing AEX, taker isn't doing AEX
                require(_makerCoinContract.balanceOf(i.maker) >= i.toBeSentByMaker + makerFees, "_executeTx: INSUFFICIENT_MAKER_BALANCE (including fees)");
                require(_makerCoinContract.allowance(i.maker, address(this)) >= i.toBeSentByMaker + makerFees, "_executeTx: MAKER_APPROVAL_MISSING (including fees)");

                TransferHelper.safeTransferFrom(i.makerCoinContract, i.maker, address(this), i.toBeSentByMaker + makerFees); // Add extra quote fee
                TransferHelper.safeTransfer(i.makerCoinContract, i.taker, i.toBeSentByMaker - takerFees);

                require(_takerCoinContract.balanceOf(i.taker) >= i.toBeSentByTaker + takerFees, "_executeTx: INSUFFICIENT_TAKER_BALANCE (including fees))");
                require(_takerCoinContract.allowance(i.taker, address(this)) >= i.toBeSentByTaker + takerFees, "_executeTx: TAKER_APPROVAL_MISSING (including fees)");

                TransferHelper.safeTransferFrom(i.takerCoinContract, i.taker, i.maker, i.toBeSentByTaker);
            }
        }
    }

    function _executeTxTakerIsQuote(OrderInfo memory i, uint256 aex_taker_balance, uint256 aex_maker_balance, uint256 aex_maker_fees, uint256 aex_taker_fees, uint256 makerFees, uint256 takerFees) internal {
        IERC20 _makerCoinContract = IERC20(i.makerCoinContract);
        IERC20 _takerCoinContract = IERC20(i.takerCoinContract);

        if(aex_taker_balance >= aex_taker_fees && payFeesUsingAEX[i.taker]) {
            if(aex_maker_balance >= aex_maker_fees && payFeesUsingAEX[i.maker]) {
                // Taker execution first
                require(_takerCoinContract.balanceOf(i.taker) >= i.toBeSentByTaker, "_executeTx: INSUFFICIENT_TAKER_BALANCE");
                require(_takerCoinContract.allowance(i.taker, address(this)) >= i.toBeSentByTaker, "_executeTx: TAKER_APPROVAL_MISSING");

                TransferHelper.safeTransferFrom(i.takerCoinContract, i.taker, i.maker, i.toBeSentByTaker);
                TransferHelper.safeTransferFrom(AEXToken, i.taker, address(this), aex_taker_fees);

                // Both paying in AEX, maker execution next
                require(_makerCoinContract.balanceOf(i.maker) >= i.toBeSentByMaker, "_executeTx: INSUFFICIENT_MAKER_BALANCE");
                require(_makerCoinContract.allowance(i.maker, address(this)) >= i.toBeSentByMaker, "_executeTx: MAKER_APPROVAL_MISSING");

                TransferHelper.safeTransferFrom(i.makerCoinContract, i.maker, i.taker, i.toBeSentByMaker); // Taker is paying in AEX as well, so we send quote directly.
                TransferHelper.safeTransferFrom(AEXToken, i.maker, address(this), aex_maker_fees);         
            } else {
                // Taker paying in AEX, maker normal
                require(_takerCoinContract.balanceOf(i.taker) >= i.toBeSentByTaker, "_executeTx: INSUFFICIENT_TAKER_BALANCE");
                require(_takerCoinContract.allowance(i.taker, address(this)) >= i.toBeSentByTaker, "_executeTx: TAKER_APPROVAL_MISSING");

                TransferHelper.safeTransferFrom(i.takerCoinContract, i.taker, address(this), i.toBeSentByTaker); // First taker sends quote here.
                TransferHelper.safeTransferFrom(AEXToken, i.taker, address(this), aex_taker_fees);
                
                require(_makerCoinContract.balanceOf(i.maker) >= i.toBeSentByMaker, "_executeTx: INSUFFICIENT_MAKER_BALANCE");
                require(_makerCoinContract.allowance(i.maker, address(this)) >= i.toBeSentByMaker, "_executeTx: MAKER_APPROVAL_MISSING");
                
                TransferHelper.safeTransferFrom(i.makerCoinContract, i.maker, i.taker, i.toBeSentByMaker); // Direct transfer
                TransferHelper.safeTransfer(i.takerCoinContract, i.maker, i.toBeSentByTaker - makerFees);
            }
        } else {
            // Taker is paying in quote both cases
            if(aex_maker_balance >= aex_maker_fees && payFeesUsingAEX[i.maker]) {
                // Taker quote, maker AEX and is base
                require(_takerCoinContract.balanceOf(i.taker) >= i.toBeSentByTaker + takerFees, "_executeTx: INSUFFICIENT_TAKER_BALANCE (including fees))");
                require(_takerCoinContract.allowance(i.taker, address(this)) >= i.toBeSentByTaker + takerFees, "_executeTx: TAKER_APPROVAL_MISSING (including fees)");

                TransferHelper.safeTransferFrom(i.takerCoinContract, i.taker, address(this), i.toBeSentByTaker + takerFees);
                TransferHelper.safeTransfer(i.takerCoinContract, i.maker, i.toBeSentByTaker);

                require(_makerCoinContract.balanceOf(i.maker) >= i.toBeSentByMaker, "_executeTx: INSUFFICIENT_MAKER_BALANCE");
                require(_makerCoinContract.allowance(i.maker, address(this)) >= i.toBeSentByMaker, "_executeTx: MAKER_APPROVAL_MISSING");

                TransferHelper.safeTransferFrom(i.makerCoinContract, i.maker, i.taker, i.toBeSentByMaker);
                TransferHelper.safeTransferFrom(AEXToken, i.maker, address(this), aex_maker_fees);
            } else {
                // Both quote
                require(_takerCoinContract.balanceOf(i.taker) >= i.toBeSentByTaker + takerFees, "_executeTx: INSUFFICIENT_TAKER_BALANCE (including fees))");
                require(_takerCoinContract.allowance(i.taker, address(this)) >= i.toBeSentByTaker + takerFees, "_executeTx: TAKER_APPROVAL_MISSING (including fees)");

                TransferHelper.safeTransferFrom(i.takerCoinContract, i.taker, address(this), i.toBeSentByTaker + takerFees);
                TransferHelper.safeTransfer(i.takerCoinContract, i.maker, i.toBeSentByTaker - makerFees);
                
                require(_makerCoinContract.balanceOf(i.maker) >= i.toBeSentByMaker, "_executeTx: INSUFFICIENT_MAKER_BALANCE (including fees)");
                require(_makerCoinContract.allowance(i.maker, address(this)) >= i.toBeSentByMaker, "_executeTx: MAKER_APPROVAL_MISSING (including fees)");

                TransferHelper.safeTransferFrom(i.makerCoinContract, i.maker, i.taker, i.toBeSentByMaker);
            }
        }
    }

    function _updateOrder(OrderInfo memory i) internal {
        // Check if the order is now partially filled or fully filled
        uint256 taker_amount_left = i.totalTakerQty - i.toBeSentByTaker - orderFilledTakerQty[i.messageHash];
        
        if(taker_amount_left > 0) {
            // Add it to the partial fills and emit an event of a partial fill
            orderFilledTakerQty[i.messageHash] += i.toBeSentByTaker;
        } else {
            if(i.increaseNonceOnCompleteFill) {
                nonces[i.maker] += 1;
            } else {
                orderFilledTakerQty[i.messageHash] = (2**256)-1;
            }
        }
    }

    // function takePublicOrderUsingNative(address maker, address makerCoinContract, address takerCoinContract, uint256 totalMakerQty, uint256 totalTakerQty, uint256 deadline, uint256 nonce, bool increaseNonceOnCompleteFill, bytes memory signature, uint256 toBeSentByTaker) public payable {
    //     OrderInfo memory i = OrderInfo(msg.sender, maker, makerCoinContract, takerCoinContract, totalMakerQty, totalTakerQty, toBeSentByTaker, increaseNonceOnCompleteFill, 0, 0);
    //     require(nonce == nonces[maker], "ERROR: ORDER_CANCELLED_OR_ALREADY_FILLED");
    //     require(deadline >= block.timestamp, "ORDER_EXPIRED");

    //     bytes32 messageHash = _getMessageHash(i.maker, i.makerCoinContract, i.takerCoinContract, i.totalMakerQty, i.totalTakerQty, deadline, nonce, increaseNonceOnCompleteFill);
    //     bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    //     (bytes32 r, bytes32 s, uint8 v) = _splitSignature(signature);

    //     require(ecrecover(ethSignedMessageHash, v, r, s) == maker, "ERROR: INVALID_SIGNATURE");
    //     require(orderFilledTakerQty[messageHash] != (2**256)-1, "ERROR: ORDER_ALREADY_EXECUTED");
    //     require(toBeSentByTaker <= totalTakerQty - orderFilledTakerQty[messageHash], "ERROR: INSUFFICIENT_QUANTITY_AVAILABLE"); // To be sentByTaker amount has been verified

    //     // In this, case the takeCoinContract must be the wrapped coin
    //     xchg_interface xchg_inter = xchg_interface(xchgInterfaceAddress);
    //     require(xchg_inter.getNativeWrappedContract() == takerCoinContract, "ERROR: The order must consist of Native coin."); // Improve this error a bit

    //     i.messageHash = messageHash;
    //     _takePublicOrderUsingNative(i);
    // }

    // Iss function ko check karlena, there might be other ways to verify the base contract too.

    // function _takePublicOrderUsingNative(OrderInfo memory i) internal {
    //     // Iss case mein taker coin theek hai, check the maker coin. It could be either quote or base. 
    //     xchg_interface xchg_inter = xchg_interface(xchgInterfaceAddress);

    //     address[] memory _quoteContracts = xchg_inter.getQuoteContracts();
    //     address[] memory _baseContracts = xchg_inter.getWhitelistedBaseContracts();
    // }

    function cancelAllOrders() public {
        nonces[msg.sender] += 1;
    }

    // Fix this lol anyone can cancel someone's order
    function cancelOrder(address maker, address makerCoinContract, address takerCoinContract, uint256 makerQty, uint256 takerQty, uint256 deadline, uint256 nonce, bool increaseNonceOnCompleteFill) public onlyMaker(maker) {
        bytes32 orderId = dexUtils.getOrderHash(maker, makerCoinContract, takerCoinContract, makerQty, takerQty, deadline, nonce, increaseNonceOnCompleteFill);
        orderFilledTakerQty[orderId] = (2**256)-1;
    }

    function payFeesWithAEX(bool option) public {
        payFeesUsingAEX[msg.sender] = option;
    }

    function getOrderHashToBeSigned(address makerCoinContract, address takerCoinContract, uint256 makerQty, uint256 takerQty, uint256 deadline, uint256 nonce, bool increaseNonceOnCompleteFill) public view returns (bytes32) {
        return keccak256(abi.encode(msg.sender, makerCoinContract, takerCoinContract, makerQty, takerQty, deadline, nonce, increaseNonceOnCompleteFill));
    }

    // function manageUSDCFees() public onlyFeeManager {

    // }

    function managerWho() public view returns(address) {
        return manager;
    }
}

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function decimals() external view returns (uint8);
}

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper { // Think about this, can't they make a fake token? And try to do a re-entrancy attack?
    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}