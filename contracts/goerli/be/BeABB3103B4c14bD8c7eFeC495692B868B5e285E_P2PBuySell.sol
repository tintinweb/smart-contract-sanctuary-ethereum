// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

//  Note:- This Contract Is Under Development

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract P2PBuySell is Ownable {
    event SellOrderCreated(
        address indexed sellerAddress,
        uint indexed sellOrderId,
        uint amount,
        string priceData
    );

    event SellOrderCreatedForBuyRequester(
        address indexed sellerAddress,
        address indexed buyRequester,
        uint indexed sellOrderId,
        uint amount,
        string priceData
    );

    event SellOrderCancelled(
        address indexed sellerAddress,
        uint indexed sellOrderId,
        uint unsoldTokens
    );

    event BuyRequestCreated(
        address indexed buyerAddress,
        address indexed sellerAddress,
        uint indexed buyRequestId,
        uint amount,
        uint expiryTime
    );

    event BuyRequestAccepted(
        address indexed buyerAddress,
        address indexed sellerAddress,
        uint indexed buyRequestId,
        uint sellOrderId
    );

    event FulfillBuyRequest(
        address indexed,
        address indexed sellerAddress,
        uint indexed buyRequestId,
        uint sellOrderId
    );

    event BuyRequestCancelled(
        address indexed buyerAddress,
        address indexed sellerAddress,
        uint indexed buyRequestId,
        uint sellOrderId
    );

    event ProfileStatusChanged(
        address indexed userAddress,
        ProfileStatus oldProfileStatus,
        ProfileStatus newProfileStatus
    );

    enum ProfileStatus {
        WhiteListed,
        Halt,
        BlackList
    }

    enum BuyRequestStatus {
        NotRequested,
        Requested,
        Completed,
        Dispute
    }

    struct User {
        uint[] sellOrdersCreated;
        uint[] buyRequestsCreated;
        uint[] buyRequestsReceived;
        ProfileStatus profileStatus;
    }

    struct SellOrder {
        address seller;
        address tokenToSell;
        address buyRequester;
        string priceData;
        uint totalTokensToSell;
        uint totalSoldTokens;
        uint totalUnsoldTokens;
        bool isSellOrderCancelled;
    }

    struct BuyRequest {
        address buyer;
        uint sellOrderId;
        uint tokenAmount;
        uint expiryTime;
        BuyRequestStatus requestStatus;
    }

    uint public totalSellOrders;
    uint public totalBuyRequests;
    uint public BUY_REQUEST_EXPIRY_TIME = 1 hours;
    uint public BUY_REQUEST_EXTEND_IN_TIMES = 2;

    mapping(address => User) private usersData;
    mapping(uint => BuyRequest) public buyRequests;
    mapping(uint => SellOrder) public sellOrders;

    modifier OnlyWhiteListedUser() {
        require(
            isWhiteListedUser(msg.sender) == true,
            "Caller Is Not WhiteListed, Only WhiteListed User Can Call This Method"
        );
        _;
    }

    modifier IsValidBuyRequestId(uint buyRequestId) {
        require(
            buyRequests[buyRequestId].buyer != address(0),
            "Invalid BuyRequestId, Please Make Sure That You Are Passing Valid BuyRequestId"
        );
        _;
    }

    modifier IsValidSellOrderId(uint sellOrderId) {
        require(
            sellOrders[sellOrderId].seller != address(0),
            "Invalid SellOrderId, Please Make Sure That You Are Passing Valid SellOrderId"
        );
        _;
    }

    modifier IsSellOrderCancelled(uint sellOrderId) {
        _;
    }

    modifier IsValidRange(uint startIndex, uint endIndex) {
        require(
            endIndex >= startIndex,
            "EndIndex Must Be Smaller Than StartIndex"
        );
        _;
    }

    /*********************************************************************************************************
     @notice This Method Is Used To Create Sell Order For Specific User Or BuyRequeter.
     @note Only That User Will Be Request For This Type Of Sell Order Whose Address Is Given As BuyRequester
     @param Check 'createSellOrder' Method's Comments
    **********************************************************************************************************/

    function createSellOrderForBuyRequester(
        IERC20 tokenToSell,
        address buyRequester,
        uint amount,
        string memory priceData
    ) external {
        require(
            buyRequester != address(0),
            "Buy Requester Address Should Not Zero Address"
        );
        uint sellOrderId = createSellOrder(
            tokenToSell,
            buyRequester,
            amount,
            priceData
        );
        emit SellOrderCreatedForBuyRequester(
            msg.sender,
            buyRequester,
            sellOrderId,
            amount,
            priceData
        );
    }

    /******************************************************************************************
     @notice This Method Is Used To Create Simple Sell Order.
     @note Anyone Can Create Buy Request For This Type Of Sell Order Of Any Amount
     @param Check 'createSellOrder' Method's Comments
    *******************************************************************************************/

    function createSimpleSellOrder(
        IERC20 tokenToSell,
        uint amount,
        string memory priceData
    ) external {
        uint sellOrderId = createSellOrder(
            tokenToSell,
            address(0),
            amount,
            priceData
        );
        emit SellOrderCreated(msg.sender, sellOrderId, amount, priceData);
    }

    /******************************************************************************************
     @notice This Method Creates Sell Order Or Lock Users Token In Contract
     @param tokenToSell, Address Of Token To Deposit. 
     @param buyRequester, Address Of Buy Requester.
     @param amount, Number Of Tokens To Deposit.
     @param priceData, Price Of Sell Order, 
     User Can Store Price Related Data By Passing String Data.
    *******************************************************************************************/
    function createSellOrder(
        IERC20 tokenToSell,
        address buyRequester,
        uint amount,
        string memory priceData
    ) private OnlyWhiteListedUser returns (uint) {
        address msgSender = msg.sender;
        require(
            tokenToSell.balanceOf(msgSender) >= amount,
            "Insufficient Balance, Please Decrease Token Amount"
        );
        require(
            tokenToSell.allowance(msgSender, address(this)) >= amount,
            "Insufficient Allowance, Please Provide Allowance To Contract"
        );
        require(
            buyRequester != msgSender,
            "Buy Requester Address Should Not Same As Sell Order Creator"
        );

        uint newSellOrderId = totalSellOrders;
        totalSellOrders++;
        usersData[msgSender].sellOrdersCreated.push(newSellOrderId);
        sellOrders[newSellOrderId] = SellOrder({
            seller: msgSender,
            tokenToSell: address(tokenToSell),
            buyRequester: buyRequester,
            priceData: priceData,
            totalTokensToSell: amount,
            totalSoldTokens: 0,
            totalUnsoldTokens: amount,
            isSellOrderCancelled: false
        });
        SafeERC20.safeTransferFrom(
            tokenToSell,
            msgSender,
            address(this),
            amount
        );

        return newSellOrderId;
    }

    /*********************************************************************************************
     @notice This Method Is Used To Cancel Sell Order Or Withdraw Locked Tokens From Contract.
     @param sellOrderId, Id Of Sell Order. 
    *********************************************************************************************/

    function cancelSellOrder(uint sellOrderId) external OnlyWhiteListedUser {
        SellOrder memory tempSellOrderData = sellOrders[sellOrderId];
        address msgSender = msg.sender;
        require(
            tempSellOrderData.seller == msgSender,
            "Only Seller Can Cancel Sell Order"
        );
        require(
            tempSellOrderData.isSellOrderCancelled == false,
            "Sell Order Is Already Cancelled"
        );

        sellOrders[sellOrderId].isSellOrderCancelled = true;
        sellOrders[sellOrderId].totalUnsoldTokens = 0;
        SafeERC20.safeTransfer(
            IERC20(tempSellOrderData.tokenToSell),
            msgSender,
            tempSellOrderData.totalUnsoldTokens
        );
        emit SellOrderCancelled(
            msgSender,
            sellOrderId,
            tempSellOrderData.totalUnsoldTokens
        );
    }

    /*********************************************************************************************************************
     @notice This Method Is Used To Create Buy Request For Buy Order,
     When Seller Creates Sell Order For Specific User Or For Buy Requester They Can Create Buy Request Using This Method
     @param Check 'createBuyRequest' Method's Commnets
    **********************************************************************************************************************/

    function createBuyRequestForBuyOrder(
        uint sellOrderId,
        bool shouldExtendTime
    ) external OnlyWhiteListedUser IsValidSellOrderId(sellOrderId) {
        SellOrder memory tempSellOrderData = sellOrders[sellOrderId];
        require(
            isWhiteListedUser(tempSellOrderData.seller) == true,
            "Seller Is Not WhiteListed, Seller Must Be WhiteListed"
        );
        require(
            tempSellOrderData.isSellOrderCancelled == false,
            "You Cannot Create Buy Request For Passed Sell Order Id Because Sell Order Is Cancelled"
        );
        require(
            msg.sender == tempSellOrderData.buyRequester,
            "Only Buy Requester Can Access This Method"
        );
        require(
            tempSellOrderData.totalUnsoldTokens != 0,
            "Buy Requester Have Already Requested For Token Buying"
        );
        createBuyRequest(
            sellOrderId,
            tempSellOrderData.totalTokensToSell,
            shouldExtendTime
        );
    }

    /*********************************************************************************************************************
     @notice This Method Is Used To Create Simple Buy Request,
     Any User Can Create Buy Request For Any Sell Order
     @param Check 'createBuyRequest' Method's Commnets
    **********************************************************************************************************************/

    function createSimpleBuyRequest(
        uint sellOrderId,
        uint amount,
        bool shouldExtendTime
    ) external OnlyWhiteListedUser IsValidSellOrderId(sellOrderId) {
        SellOrder memory tempSellOrderData = sellOrders[sellOrderId];
        require(
            isWhiteListedUser(tempSellOrderData.seller) == true,
            "Seller Is Not WhiteListed, Seller Must Be WhiteListed"
        );
        require(
            tempSellOrderData.isSellOrderCancelled == false,
            "You Cannot Create Buy Request For Passed Sell Order Id Because Sell Order Is Cancelled"
        );
        require(
            msg.sender != tempSellOrderData.seller,
            "Buyer Address And Seller Address Should Not Be Same"
        );
        require(
            tempSellOrderData.totalUnsoldTokens >= amount,
            "Insufficient Tokens To Sell, Please Decrease Token Amount"
        );
        createBuyRequest(sellOrderId, amount, shouldExtendTime);
    }

    /*****************************************************************************************************
     @notice This Method Creates Buy Request,
     @param sellOrderId, Id Of Sell Order.
     @param amount, Amount Of Token User Wants To Buy.
     @param shouldExtendTime, It Expects Bool Input,
      true --> For Extending Expiry Time.
      false --> For Not Extending Expiry Time.
    *****************************************************************************************************/

    function createBuyRequest(
        uint sellOrderId,
        uint amount,
        bool shouldExtendTime
    ) private {
        address msgSender = msg.sender;
        uint newBuyRequestId = totalBuyRequests;
        totalBuyRequests++;
        usersData[msgSender].buyRequestsCreated.push(newBuyRequestId);
        usersData[sellOrders[sellOrderId].seller].buyRequestsReceived.push(
            newBuyRequestId
        );
        sellOrders[sellOrderId].totalUnsoldTokens -= amount;
        sellOrders[sellOrderId].totalSoldTokens += amount;
        uint buyRequestExpiryTime;
        if (shouldExtendTime == true) {
            buyRequestExpiryTime =
                block.timestamp +
                (BUY_REQUEST_EXPIRY_TIME * BUY_REQUEST_EXTEND_IN_TIMES);
        } else {
            buyRequestExpiryTime = block.timestamp + BUY_REQUEST_EXPIRY_TIME;
        }
        buyRequests[newBuyRequestId] = BuyRequest({
            buyer: msgSender,
            sellOrderId: sellOrderId,
            tokenAmount: amount,
            expiryTime: buyRequestExpiryTime,
            requestStatus: BuyRequestStatus.Requested
        });
        emit BuyRequestCreated(
            msgSender,
            sellOrders[sellOrderId].seller,
            newBuyRequestId,
            amount,
            buyRequestExpiryTime
        );
    }

    /************************************************************************** 
     @notice This Method Is Used To Accept Buyers Buy Request, 
     When Seller Will Call This Method Tokens Will Transfer To Buyer Address.
     @param buyRequestIds, Ids (Array Of Ids) Of Buy Request.
    **************************************************************************/

    function acceptBuyRequest_Batch(uint[] memory buyRequestIds) external {
        uint totalIterations = buyRequestIds.length;
        for (uint i = 0; i < totalIterations; ) {
            acceptBuyRequest(buyRequestIds[i]);
            unchecked {
                i++;
            }
        }
    }

    function acceptBuyRequest(uint buyRequestId)
        public
        IsValidBuyRequestId(buyRequestId)
    {
        BuyRequest memory tempBuyRequestData = buyRequests[buyRequestId];
        require(
            sellOrders[tempBuyRequestData.sellOrderId].seller == msg.sender,
            "Only Seller Of Sell Order Can Access This Method"
        );
        require(
            isWhiteListedUser(tempBuyRequestData.buyer) == true,
            "Buyer Is Not WhiteListed, Buyer Must Be WhiteListed"
        );
        require(
            tempBuyRequestData.requestStatus == BuyRequestStatus.Requested,
            "Buy Request Status Must Be 'Request', Buy Request Status Is 'Completed' Or 'Dispute'"
        );
        buyRequests[buyRequestId].requestStatus = BuyRequestStatus.Completed;
        SafeERC20.safeTransfer(
            IERC20(sellOrders[tempBuyRequestData.sellOrderId].tokenToSell),
            tempBuyRequestData.buyer,
            tempBuyRequestData.tokenAmount
        );
        emit BuyRequestAccepted(
            tempBuyRequestData.buyer,
            msg.sender,
            buyRequestId,
            tempBuyRequestData.sellOrderId
        );
    }

    /************************************************************************** 
     @notice This Method Is Used To Fulfill Buyers Buy Request.
     @note Only Admin Of This Contract Can Access This Method.
     When Admin Will Call This Method, Tokens Will Transfer To Buyer Address.
     @param buyRequestIds, Ids (Array Of Ids) Of Buy Request.
    **************************************************************************/

    function fulfillBuyRequest_Batch(uint[] memory buyRequestsIds)
        external
        onlyOwner
    {
        uint totalIterations = buyRequestsIds.length;
        for (uint i = 0; i < totalIterations; ) {
            fulfillBuyRequest(buyRequestsIds[i]);
            unchecked {
                i++;
            }
        }
    }

    function fulfillBuyRequest(uint buyRequestId)
        private
        IsValidBuyRequestId(buyRequestId)
    {
        BuyRequest memory tempBuyRequestData = buyRequests[buyRequestId];
        require(
            isWhiteListedUser(tempBuyRequestData.buyer) == true,
            "Buyer Is Not WhiteListed, Buyer Must Be WhiteListed"
        );
        // require(
        //     tempBuyRequestData.expiryTime <= block.timestamp,
        //     "Admin Can Fulfill Buy Request After Buy Request Expiry Time"
        // );
        require(
            tempBuyRequestData.requestStatus == BuyRequestStatus.Requested,
            "Buy Request Status Must Be 'Request', Buy Request Status Is 'Completed' Or 'Dispute'"
        );
        buyRequests[buyRequestId].requestStatus = BuyRequestStatus.Dispute;

        SafeERC20.safeTransfer(
            IERC20(sellOrders[tempBuyRequestData.sellOrderId].tokenToSell),
            tempBuyRequestData.buyer,
            tempBuyRequestData.tokenAmount
        );
        emit FulfillBuyRequest(
            tempBuyRequestData.buyer,
            sellOrders[tempBuyRequestData.sellOrderId].seller,
            buyRequestId,
            tempBuyRequestData.sellOrderId
        );
    }

    /***************************************************************************************************
     @notice This Method Is Use To Cancel Buy Requests.
     @note Only Admin Of This Contract Can Access This Method.
     When Admin Will Call This Method, Tokens Of Seller Will Be Added To Unsold Tokens Of Sell Order.
     But If In Any Case Sell Order Is Cancelled So Tokens Will Be Transfered To Seller Address.
     @param buyRequestIds, Ids (Array Of Ids) Of Buy Request.
    ****************************************************************************************************/

    function cancelBuyRequest_Batch(uint[] memory buyRequestsIds)
        external
        onlyOwner
    {
        uint totalIterations = buyRequestsIds.length;
        for (uint i = 0; i < totalIterations; ) {
            cancelBuyRequest(buyRequestsIds[i]);
            unchecked {
                i++;
            }
        }
    }

    function cancelBuyRequest(uint buyRequestId)
        private
        IsValidBuyRequestId(buyRequestId)
    {
        BuyRequest memory tempBuyRequestData = buyRequests[buyRequestId];
        require(
            isWhiteListedUser(
                sellOrders[tempBuyRequestData.sellOrderId].seller
            ) == true,
            "Seller Is Not WhiteListed, Seller Must Be WhiteListed"
        );
        // require(
        //     tempBuyRequestData.expiryTime <= block.timestamp,
        //     "Buy Request Cannot Cancelled Before Buy Request Expiry Time"
        // );
        require(
            tempBuyRequestData.requestStatus == BuyRequestStatus.Requested,
            "Buy Request Status Must Be 'Request', Buy Request Status Is 'Completed' Or 'Dispute'"
        );

        buyRequests[buyRequestId].requestStatus = BuyRequestStatus.Dispute;
        if (
            sellOrders[tempBuyRequestData.sellOrderId].isSellOrderCancelled ==
            true ||
            sellOrders[tempBuyRequestData.sellOrderId].buyRequester !=
            address(0)
        ) {
            sellOrders[tempBuyRequestData.sellOrderId]
                .totalSoldTokens -= tempBuyRequestData.tokenAmount;
            SafeERC20.safeTransfer(
                IERC20(sellOrders[tempBuyRequestData.sellOrderId].tokenToSell),
                sellOrders[tempBuyRequestData.sellOrderId].seller,
                tempBuyRequestData.tokenAmount
            );
        } else {
            sellOrders[tempBuyRequestData.sellOrderId]
                .totalUnsoldTokens += tempBuyRequestData.tokenAmount;
            sellOrders[tempBuyRequestData.sellOrderId]
                .totalSoldTokens -= tempBuyRequestData.tokenAmount;
        }

        emit BuyRequestCancelled(
            tempBuyRequestData.buyer,
            sellOrders[tempBuyRequestData.sellOrderId].seller,
            buyRequestId,
            tempBuyRequestData.sellOrderId
        );
    }

    /********** Setter Functions **********/

    /******************************************************************************************************* 
     @notice This Method Is Used To Set User Profile Status,
     Only Owner Can Call This Method.
     @param userAddresses, Addresses (Array Of Addresses) of User's Whose Profile Status Has To Change.
     @param newProfileStatus, New Profile Status (Array Of Status) Of User's.
     Expected Values Of newProfileStatus:- 
     0 --> For Whitelist User.
     1 --> For Halt User Profile.
     2 --> For Blacklist User
    ********************************************************************************************************/

    function setUserProfileStatus_Batch(
        address[] memory userAddresses,
        ProfileStatus[] memory newProfileStatus
    ) external onlyOwner {
        require(
            userAddresses.length == newProfileStatus.length,
            "Invalid Inputs, Make Sure That You Are Passing Same Number Of UserAddresses And NewProfile"
        );
        uint totalIterations = userAddresses.length;

        for (uint i = 0; i < totalIterations; ) {
            ProfileStatus oldProfileStatus = usersData[userAddresses[i]]
                .profileStatus;
            usersData[userAddresses[i]].profileStatus = newProfileStatus[i];
            emit ProfileStatusChanged(
                userAddresses[i],
                oldProfileStatus,
                newProfileStatus[i]
            );
            unchecked {
                i++;
            }
        }
    }

    function setBuyRequestExpiryTime(uint newTime) external onlyOwner {
        BUY_REQUEST_EXPIRY_TIME = newTime;
    }

    function setBuyRequestExpiryTimeInTimes(uint newExtendInTimes)
        external
        onlyOwner
    {
        BUY_REQUEST_EXTEND_IN_TIMES = newExtendInTimes;
    }

    /********** View Functions **********/

    function isWhiteListedUser(address userAddress) public view returns (bool) {
        if (usersData[userAddress].profileStatus == ProfileStatus.WhiteListed) {
            return true;
        }
        return false;
    }

    function getUserSellOrderCreated(address userAddress)
        external
        view
        returns (uint[] memory)
    {
        return usersData[userAddress].sellOrdersCreated;
    }

    function getUserBuyRequestReceived(address userAddress)
        external
        view
        returns (uint[] memory)
    {
        return usersData[userAddress].buyRequestsReceived;
    }

    function getUserBuyRequestCreated(address userAddress)
        external
        view
        returns (uint[] memory)
    {
        return usersData[userAddress].buyRequestsCreated;
    }

    /*******************************************************************************************************
     @notice This Method Returns Array Of Sell Orders Id, Which Are Created By Specified User,
     It Is Usefull For User When User Just Have To Get Id's Of Some Sell Orders Created By Specified User.
     @note For Getting Data Or Items From An Array, 
     Range Based Getter Or View Methods Are Used For Getting Some Specific range Of Items,
     For Avoiding Whole Data Or Items Of An Array Range Is Specified.
     Example:- 
     Consider Array Is [1,2,3,4,5]
     And We Want Num 2,3
     So Here We Will Pass startIndex Value As 1 And endIndex Ad 2, 
     In This We Just Have To Pass Indexes Of Start Point And End Point.
     One Thing We Have To Remember Is That We Can Just Get Items In Sequencial Manner
     @param userAddress, Address Of User.
     @param startIndex, Start Index Of Array.
     @param endIndex, End Index Of Array.
    ********************************************************************************************************/

    function getUserSellOrderCreated_InRange(
        address userAddress,
        uint startIndex,
        uint endIndex
    ) external view IsValidRange(startIndex, endIndex) returns (uint[] memory) {
        uint[] memory tempUserSellOrders = usersData[userAddress]
            .sellOrdersCreated;
        require(
            endIndex < tempUserSellOrders.length,
            "EndIndex Must Be Smaller Than Total Data Items"
        );
        uint[] memory tempDataArr = new uint[]((endIndex - startIndex) + 1);
        uint j;
        for (uint i = startIndex; i <= endIndex; ) {
            tempDataArr[j] = tempUserSellOrders[i];
            unchecked {
                i++;
                j++;
            }
        }
        return tempDataArr;
    }

    /************************************************************************************************
     @notice This Method Returns Array Of Buy Requets Id, Which Are Received By Specified User.
     @params Check 'getUserSellOrderCreated_InRange' Method's Comments.
    *************************************************************************************************/

    function getUserBuyRequestReceived_InRange(
        address userAddress,
        uint startIndex,
        uint endIndex
    ) external view IsValidRange(startIndex, endIndex) returns (uint[] memory) {
        uint[] memory tempUserBuyRequestReceived = usersData[userAddress]
            .buyRequestsReceived;
        require(
            endIndex < tempUserBuyRequestReceived.length,
            "EndIndex Must Be Smaller Than Total Data Items"
        );
        uint[] memory tempDataArr = new uint[]((endIndex - startIndex) + 1);
        uint j;
        for (uint i = startIndex; i <= endIndex; ) {
            tempDataArr[j] = tempUserBuyRequestReceived[i];
            unchecked {
                i++;
                j++;
            }
        }
        return tempDataArr;
    }

    /*******************************************************************************************
     @notice This Method Returns Array Of Buy Requets Id, Which Are Created By Specified User.
     @params Check 'getUserSellOrderCreated_InRange' Method's Comments.
    ********************************************************************************************/

    function getUserBuyRequestCreated_InRange(
        address userAddress,
        uint startIndex,
        uint endIndex
    ) external view IsValidRange(startIndex, endIndex) returns (uint[] memory) {
        uint[] memory tempUserBuyRequestCreated = usersData[userAddress]
            .buyRequestsCreated;
        require(
            endIndex < tempUserBuyRequestCreated.length,
            "EndIndex Must Be Smaller Than Total Data Items"
        );
        uint[] memory tempDataArr = new uint[]((endIndex - startIndex) + 1);
        uint j;
        for (uint i = startIndex; i <= endIndex; ) {
            tempDataArr[j] = tempUserBuyRequestCreated[i];
            unchecked {
                i++;
                j++;
            }
        }
        return tempDataArr;
    }

    /*********************************************************************************************************************
     @notice This Method Returns Total Sell Orders, Total Buy Requests And Total Buy Requests Received By Specified User.
     @param userAddress, Address Of User.
    **********************************************************************************************************************/

    function getUserTotalActions(address userAddress)
        external
        view
        returns (
            uint userTotalSellOrders,
            uint userTotalBuyRequestsCreated,
            uint userTotalBuyRequestReceived
        )
    {
        userTotalSellOrders = usersData[userAddress].sellOrdersCreated.length;
        userTotalBuyRequestsCreated = usersData[userAddress]
            .buyRequestsCreated
            .length;
        userTotalBuyRequestReceived = usersData[userAddress]
            .buyRequestsReceived
            .length;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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