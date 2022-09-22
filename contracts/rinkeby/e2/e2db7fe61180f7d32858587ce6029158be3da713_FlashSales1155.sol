// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IERC1155.sol";

contract FlashSales1155 is Ownable, ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    using Address for address payable;
    using Address for address;

    uint private _saleIdCounter = 1;
    bool private _onlyInitOnce;

    struct FlashSale {
        // The sale setter
        address seller;
        // Address of ERC1155 token to sell
        address tokenAddress;
        // Id of ERC1155 token to sell
        uint id;
        // Remaining amount of ERC1155 token in this sale
        uint remainingAmount;
        // ERC20 address of token for payment
        address payTokenAddress;
        // Price of token to pay
        uint price;
        // Address of receiver
        address receiver;
        // Max number of ERC1155 token could be bought from an address
        uint purchaseLimitation;
        uint startTime;
        uint endTime;
        // Whether the sale is available
        bool isAvailable;
    }

    // Payment whitelist for the address of ERC20
    mapping(address => bool) private _paymentWhitelist;

    // Whitelist to set sale
    mapping(address => bool) private _whitelist;

    // Mapping from sale id to FlashSale info
    mapping(uint => FlashSale) private _flashSales;

    // Mapping from sale ID to mapping(address => how many tokens have bought)
    mapping(uint => mapping(address => uint)) _flashSaleIdToPurchaseRecord;

    address public serverAddress;
    // sale ID -> server hash
    mapping(bytes32 => uint)  serverHashMap;

    event PaymentWhitelistChange(address erc20Addr, bool jurisdiction);
    event SetWhitelist(address memberAddr, bool jurisdiction);
    event SetFlashSale(uint saleId, address flashSaleSetter, address tokenAddress, uint id, uint remainingAmount,
        address payTokenAddress, uint price, address receiver, uint purchaseLimitation, uint startTime,
        uint endTime);
    event UpdateFlashSale(uint saleId, address operator, address newTokenAddress, uint newId, uint newRemainingAmount,
        address newPayTokenAddress, uint newPrice, address newReceiver, uint newPurchaseLimitation, uint newStartTime,
        uint newEndTime);
    event CancelFlashSale(uint saleId, address operator);
    event FlashSaleExpired(uint saleId, address operator);
    event Purchase(uint saleId, address buyer, address tokenAddress, uint id, uint amount, address payTokenAddress,
        uint totalPayment);
    event MainCoin(uint totalPayment);
    event EmergencyWithdraw(address token, address to, uint256 amount);


    modifier onlyWhitelist() {
        require(_whitelist[msg.sender],
            "the caller isn't in the whitelist");
        _;
    }

    modifier onlyPaymentWhitelist(address erc20Addr) {
        require(_paymentWhitelist[erc20Addr],
            "the pay token address isn't in the whitelist");
        _;
    }

    function init(address _newOwner) public {
        require(!_onlyInitOnce, "already initialized");

        _transferOwnership(_newOwner);
        _onlyInitOnce = true;
    }

    /**
     * @dev External function to set flash sale by the member in whitelist.
     * @param tokenAddress address Address of ERC1155 token contract
     * @param id uint Id of ERC1155 token to sell
     * @param amount uint Amount of target ERC1155 token to sell
     * @param payTokenAddress address ERC20 address of token for payment
     * @param price uint Price of each ERC1155 token
     * @param receiver address Address of the receiver to gain the payment
     * @param purchaseLimitation uint Max number of ERC1155 token could be bought from an address
     * @param startTime uint Timestamp of the beginning of flash sale activity
     * @param duration uint The duration of this flash sale activity
     */
    function setFlashSale(
        address tokenAddress,
        uint id,
        uint amount,
        address payTokenAddress,
        uint price,
        address receiver,
        uint purchaseLimitation,
        uint startTime,
        uint duration
    )
    external
    nonReentrant
    onlyWhitelist
    onlyPaymentWhitelist(payTokenAddress)
    {
        // 1. check the validity of params
        _checkFlashSaleParams(msg.sender, tokenAddress, id, amount, price, purchaseLimitation, startTime);

        // 2.  build flash sale
        uint endTime;
        if (duration != 0) {
            endTime = startTime.add(duration);
        }

        FlashSale memory flashSale = FlashSale({
        seller : msg.sender,
        tokenAddress : tokenAddress,
        id : id,
        remainingAmount : amount,
        payTokenAddress : payTokenAddress,
        price : price,
        receiver : receiver,
        purchaseLimitation : purchaseLimitation,
        startTime : startTime,
        endTime : endTime,
        isAvailable : true
        });

        // 3. store flash sale
        uint currentSaleId = _saleIdCounter;
        _saleIdCounter = _saleIdCounter.add(1);
        _flashSales[currentSaleId] = flashSale;
        emit SetFlashSale(currentSaleId, flashSale.seller, flashSale.tokenAddress, flashSale.id,
            flashSale.remainingAmount, flashSale.payTokenAddress, flashSale.price, flashSale.receiver,
            flashSale.purchaseLimitation, flashSale.startTime, flashSale.endTime);
    }

    /**
     * @dev External function to update the existing flash sale by its setter in whitelist.
     * @param saleId uint The target id of flash sale to update
     * @param newTokenAddress address New Address of ERC1155 token contract
     * @param newId uint New id of ERC1155 token to sell
     * @param newAmount uint New amount of target ERC1155 token to sell
     * @param newPayTokenAddress address New ERC20 address of token for payment
     * @param newPrice uint New price of each ERC1155 token
     * @param newReceiver address New address of the receiver to gain the payment
     * @param newPurchaseLimitation uint New max number of ERC1155 token could be bought from an address
     * @param newStartTime uint New timestamp of the beginning of flash sale activity
     * @param newDuration uint New duration of this flash sale activity
     */
    function updateFlashSale(
        uint saleId,
        address newTokenAddress,
        uint newId,
        uint newAmount,
        address newPayTokenAddress,
        uint newPrice,
        address newReceiver,
        uint newPurchaseLimitation,
        uint newStartTime,
        uint newDuration
    )
    external
    nonReentrant
    onlyWhitelist
    onlyPaymentWhitelist(newPayTokenAddress)
    {
        FlashSale memory flashSale = getFlashSale(saleId);
        // 1. make sure that the flash sale doesn't start
        require(
            flashSale.startTime > now,
            "it's not allowed to update the flash sale after the start of it"
        );
        require(
            flashSale.isAvailable,
            "the flash sale has been cancelled"
        );
        require(
            flashSale.seller == msg.sender,
            "the flash sale can only be updated by its setter"
        );

        // 2. check the validity of params to update
        _checkFlashSaleParams(msg.sender, newTokenAddress, newId, newAmount, newPrice, newPurchaseLimitation,
            newStartTime);

        // 3. update flash sale
        uint endTime;
        if (newDuration != 0) {
            endTime = newStartTime.add(newDuration);
        }

        flashSale.tokenAddress = newTokenAddress;
        flashSale.id = newId;
        flashSale.remainingAmount = newAmount;
        flashSale.payTokenAddress = newPayTokenAddress;
        flashSale.price = newPrice;
        flashSale.receiver = newReceiver;
        flashSale.purchaseLimitation = newPurchaseLimitation;
        flashSale.startTime = newStartTime;
        flashSale.endTime = endTime;
        _flashSales[saleId] = flashSale;
        emit  UpdateFlashSale(saleId, flashSale.seller, flashSale.tokenAddress, flashSale.id, flashSale.remainingAmount,
            flashSale.payTokenAddress, flashSale.price, flashSale.receiver, flashSale.purchaseLimitation,
            flashSale.startTime, flashSale.endTime);
    }

    /**
     * @dev External function to cancel the existing flash sale by its setter in whitelist.
     * @param saleId uint The target id of flash sale to be cancelled
     */
    function cancelFlashSale(uint saleId) external onlyWhitelist {
        FlashSale memory flashSale = getFlashSale(saleId);
        require(
            flashSale.isAvailable,
            "the flash sale isn't available"
        );
        require(
            flashSale.seller == msg.sender,
            "the flash sale can only be cancelled by its setter"
        );

        _flashSales[saleId].isAvailable = false;
        emit CancelFlashSale(saleId, msg.sender);
    }

    function setServerAddress(address targetAddress) public onlyOwner {
        serverAddress = targetAddress;
    }

    /**
      * @dev External function to purchase ERC1155 from the target sale by anyone.
      * @param saleId uint The target id of flash sale to purchase
      * @param amount uint The amount of target ERC1155 to purchase
      */
    function purchase(uint saleId, uint amount, bytes32 hash,uint8 v, bytes32 r, bytes32 s) external payable nonReentrant {
        require(ecrecover(hash, v, r, s) == serverAddress,"verify server sign failed");
        // we have set saleIDCounter initial value to 1 to prevent when saleID = 0 from can not being purchased
        require(serverHashMap[hash] != saleId,"sign hash repeat");

        serverHashMap[hash] = saleId;

        FlashSale memory flashSale = getFlashSale(saleId);
        // 1. check the validity
        require(
            amount > 0,
            "amount should be > 0"
        );
        require(
            flashSale.isAvailable,
            "the flash sale isn't available"
        );
        require(
            flashSale.seller != msg.sender,
            "the setter can't make a purchase from its own flash sale"
        );
        uint currentTime = now;
        require(
            currentTime >= flashSale.startTime,
            "the flash sale doesn't start"
        );
        // 2. check whether the end time arrives
        if (flashSale.endTime != 0 && flashSale.endTime <= currentTime) {
            // the flash sale has been set an end time and expired
            _flashSales[saleId].isAvailable = false;
            emit FlashSaleExpired(saleId, msg.sender);
            return;
        }

        // 3. check whether the amount of token rest in flash sale is sufficient for this trade
        require(amount <= flashSale.remainingAmount,
            "insufficient amount of token for this trade");
        // 4. check the purchase record of the buyer
        uint newPurchaseRecord = _flashSaleIdToPurchaseRecord[saleId][msg.sender].add(amount);
        require(newPurchaseRecord <= flashSale.purchaseLimitation,
            "total amount to purchase exceeds the limitation of an address");

        // 5. pay the receiver
        _flashSaleIdToPurchaseRecord[saleId][msg.sender] = newPurchaseRecord;
        uint totalPayment = flashSale.price.mul(amount);

        if(flashSale.payTokenAddress!= address(0)){
            IERC20(flashSale.payTokenAddress).safeTransferFrom(msg.sender, flashSale.receiver, totalPayment);
        } else {
            require(msg.value >= totalPayment, "amount should be > totalPayment");
            emit MainCoin(totalPayment);
            payable(flashSale.receiver).transfer(totalPayment);
        }

        // 6. transfer ERC1155 tokens to buyer
        uint newRemainingAmount = flashSale.remainingAmount.sub(amount);
        _flashSales[saleId].remainingAmount = newRemainingAmount;
        if (newRemainingAmount == 0) {
            _flashSales[saleId].isAvailable = false;
        }

        IERC1155(flashSale.tokenAddress).safeTransferFrom(flashSale.seller, msg.sender, flashSale.id, amount, "");
        emit Purchase(saleId, msg.sender, flashSale.tokenAddress, flashSale.id, amount, flashSale.payTokenAddress,
            totalPayment);
    }
    function withdraw(address token, address to, uint256 amount) external onlyOwner {
        if (token.isContract()) {
            IERC20(token).safeTransfer(to, amount);
        } else {
            payable(to).sendValue(amount);
        }
        emit EmergencyWithdraw(token, to, amount);
    }
    /**
     * @dev Public function to set the whitelist of setting flash sale only by the owner.
     * @param memberAddr address Address of member to be added or removed
     * @param jurisdiction bool In or out of the whitelist
     */
    function setWhitelist(address memberAddr, bool jurisdiction) external onlyOwner {
        _whitelist[memberAddr] = jurisdiction;
        emit SetWhitelist(memberAddr, jurisdiction);
    }

    /**
     * @dev Public function to set the payment whitelist only by the owner.
     * @param erc20Addr address Address of erc20 for paying
     * @param jurisdiction bool In or out of the whitelist
     */
    function setPaymentWhitelist(address erc20Addr, bool jurisdiction) public onlyOwner {
        _paymentWhitelist[erc20Addr] = jurisdiction;
        emit PaymentWhitelistChange(erc20Addr, jurisdiction);
    }

    /**
     * @dev Public function to query whether the target erc20 address is in the payment whitelist.
     * @param erc20Addr address Target address of erc20 to query about
     */
    function getPaymentWhitelist(address erc20Addr) public view returns (bool){
        return _paymentWhitelist[erc20Addr];
    }

    /**
     * @dev Public function to query whether the target member address is in the whitelist.
     * @param memberAddr address Target address of member to query about
     */
    function getWhitelist(address memberAddr) public view returns (bool){
        return _whitelist[memberAddr];
    }

    /**
     * @dev Public function to query the flash sale by sale Id.
     * @param saleId uint Target sale Id of flash sale to query about
     */
    function getFlashSale(uint saleId) public view returns (FlashSale memory flashSale){
        flashSale = _flashSales[saleId];
        require(flashSale.seller != address(0), "the target flash sale doesn't exist");
    }

    function getCurrentSaleId() public view returns (uint256) {
        return _saleIdCounter;
    }

    /**
     * @dev Public function to query the purchase record of the amount that an address has bought.
     * @param saleId uint Target sale Id of flash sale to query about
     * @param buyer address Target address to query the record with
     */
    function getFlashSalePurchaseRecord(uint saleId, address buyer) public view returns (uint){
        // check whether the flash sale Id exists
        getFlashSale(saleId);
        return _flashSaleIdToPurchaseRecord[saleId][buyer];
    }


    function _checkFlashSaleParams(
        address saleSetter,
        address tokenAddress,
        uint id,
        uint amount,
        uint price,
        uint purchaseLimitation,
        uint startTime
    )
    private
    view
    {
        // check whether the sale setter has the target tokens && approval
        IERC1155 tokenAddressCached = IERC1155(tokenAddress);
        require(
            tokenAddressCached.balanceOf(saleSetter, id) >= amount,
            "insufficient amount of ERC1155"
        );
        require(
            tokenAddressCached.isApprovedForAll(saleSetter, address(this)),
            "the contract hasn't been approved for ERC1155 transferring"
        );
        require(amount > 0, "the amount must be > 0");
        require(price >= 0, "the price must be > 0");
        require(startTime >= now, "startTime must be >= now");
        require(purchaseLimitation > 0, "purchaseLimitation must be > 0");
        require(purchaseLimitation <= amount, "purchaseLimitation must be <= amount");
    }
}