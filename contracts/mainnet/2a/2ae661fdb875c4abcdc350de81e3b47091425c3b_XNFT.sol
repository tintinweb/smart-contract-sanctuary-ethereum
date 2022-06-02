// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./interface/IP2Controller.sol";
import "./interface/IXToken.sol";
import "./library/SafeERC20.sol";
import "./interface/IXAirDrop.sol";
import "./interface/IPunks.sol";
import "./interface/IWrappedPunks.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract XNFT is  IERC721ReceiverUpgradeable, IERC1155ReceiverUpgradeable, Initializable{
    using SafeMathUpgradeable for uint256;
    using SafeERC20 for IERC20;

    uint256 internal constant RATE_UPPER_LIMIT = 1e18;
    address internal constant ADDRESS_ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    enum OrderState{
        NOPLEDGE,
        PLEDGEING,
        LIQUIDITYING,
        NORMALWITHDRAW,
        LIQUIDITYWITHDRAW,
        REDEEMPROTECTION,
        LIQUIDITYEND
    }

    address public admin;
    address public pendingAdmin;

    bool internal _notEntered;

    IP2Controller public controller;

    struct Order{
        address pledger;
        address collection;
        uint256 tokenId;
        uint256 nftType;
        bool isWithdraw;
    }
    mapping (uint256 => Order) public allOrders;

    struct LiquidatedOrder{
        address liquidator;
        uint256 liquidatedPrice;
        address xToken;
        uint256 liquidatedStartTime;
        address auctionAccount;
        uint256 auctionPrice;
        bool isPledgeRedeem;
        address auctionWinner;
    }
    mapping(uint256 => LiquidatedOrder) public allLiquidatedOrder;

    struct CollectionNFT{
        bool isCollectionWhiteList;
        uint256 auctionDuration;
        uint256 redeemProtection;
        uint256 increasingMin;
    }
    mapping (address => CollectionNFT) public collectionWhiteList;
    uint256 public counter;

    uint256 public auctionDurationOverAll;
    uint256 public redeemProtectionOverAll;
    uint256 public increasingMinOverAll;

    uint256 public pledgerFineRate;
    uint256 public rewardFirstRate;
    uint256 public rewardLastRate;
    uint256 public compensatePledgerRate;

    uint256 public transferEthGasCost;

    mapping(uint256 => bool) public pausedMap;

    IXAirDrop public xAirDrop;

    mapping(address => uint256[]) public ordersMap;

    IPunks public punks;
    IWrappedPunks public wrappedPunks;
    address public userProxy;

    mapping(address => uint256) public addUpIncomeMap;

    event Pledge(address collection, uint256 tokenId, uint256 orderId, address indexed pledger);
    event WithDraw(address collection, uint256 tokenId, uint256 orderId, address indexed pledger, address indexed receiver);
    event PledgeAdvanceRedeem(address account, address xToken, uint256 orderId, uint256 amount);
    event AuctionNFT(uint256 orderId, address xToken, address account, uint256 amount, bool isProtection);
    event AirDrop(address xAirDrop, address msgSender, address receiver, address collection, uint256 tokenId);

    function initialize() external initializer {
        admin = msg.sender;
        _notEntered = true;
    }

    receive() external payable{}

    function pledgeAndBorrow(address _collection, uint256 _tokenId, uint256 _nftType, address xToken, uint256 borrowAmount) external nonReentrant {
        uint256 orderId = pledgeInternal(_collection, _tokenId, _nftType);
        IXToken(xToken).borrow(orderId, payable(msg.sender), borrowAmount);
    }

    function pledge(address _collection, uint256 _tokenId, uint256 _nftType) external nonReentrant{
        pledgeInternal(_collection, _tokenId, _nftType);
    }

    function pledge721(address _collection, uint256 _tokenId) external nonReentrant{
        pledgeInternal(_collection, _tokenId, 721);
    }

    function pledge1155(address _collection, uint256 _tokenId) external nonReentrant{
        pledgeInternal(_collection, _tokenId, 1155);
    }

    function pledgeInternal(address _collection, uint256 _tokenId, uint256 _nftType) internal whenNotPaused(1) returns(uint256){
        require(_nftType == 721 || _nftType == 1155, "don't support this nft type");
        if(_collection != address(punks)){
            transferNftInternal(msg.sender, address(this), _collection, _tokenId, _nftType);
        }else{
            _depositPunk(_tokenId);
            _collection = address(wrappedPunks);
        }
        require(collectionWhiteList[_collection].isCollectionWhiteList, "collection not insist");

        counter = counter.add(1);
        uint256 _orderId = counter;
        Order storage _order = allOrders[_orderId];
        _order.collection = _collection;
        _order.tokenId = _tokenId;
        _order.nftType = _nftType;
        _order.pledger = msg.sender;

        ordersMap[msg.sender].push(counter);

        emit Pledge(_collection, _tokenId, _orderId, msg.sender);
        return _orderId;
    }

    function auctionAllowed(address pledger, address auctioneer, address _collection, uint256 liquidatedStartTime, uint256 lastPrice, uint256 amount) internal view returns(bool){
        uint256 _auctionDuration;
        uint256 _redeemProtection;
        uint256 _increasingMin;
        CollectionNFT memory collectionNFT = collectionWhiteList[_collection];
        if(collectionNFT.auctionDuration != 0 && collectionNFT.redeemProtection != 0 && collectionNFT.increasingMin != 0){
            _auctionDuration = collectionNFT.auctionDuration;
            _redeemProtection = collectionNFT.redeemProtection;
            _increasingMin = collectionNFT.increasingMin;
        }else{
            _auctionDuration = auctionDurationOverAll;
            _redeemProtection = redeemProtectionOverAll;
            _increasingMin = increasingMinOverAll;
        }
        require(block.timestamp < liquidatedStartTime.add(_auctionDuration), "auction time has passed");
        if(pledger == auctioneer && block.timestamp < liquidatedStartTime.add(_redeemProtection)){
            return true;
        }else{
            require(amount >= lastPrice.add(lastPrice.mul(_increasingMin).div(1e18)), "do not meet the minimum mark up");
            return false;
        }
    }

    function auction(uint256 orderId, uint256 amount) payable external nonReentrant whenNotPaused(3){
        require(isOrderLiquidated(orderId), "this order is not a liquidation order");
        LiquidatedOrder storage liquidatedOrder = allLiquidatedOrder[orderId];
        require(liquidatedOrder.auctionWinner == address(0), "the order has been withdrawn");
        require(!liquidatedOrder.isPledgeRedeem, "redeemed by the pledgor");
        Order storage _order = allOrders[orderId];
        if(IXToken(liquidatedOrder.xToken).underlying() == ADDRESS_ETH){
            amount = msg.value;
        }
        uint256 price;
        if(liquidatedOrder.auctionAccount == address(0)){
            price = liquidatedOrder.liquidatedPrice;
        }else{
            price = liquidatedOrder.auctionPrice;
        }

        bool isPledger = auctionAllowed(_order.pledger, msg.sender, _order.collection, liquidatedOrder.liquidatedStartTime, price, amount);

        if(isPledger){
            uint256 fine = price.mul(pledgerFineRate).div(1e18);
            uint256 _amount = liquidatedOrder.liquidatedPrice.add(fine);
            doTransferIn(liquidatedOrder.xToken, payable(msg.sender), _amount);
            uint256 rewardFirst = fine.mul(rewardFirstRate).div(1e18);
            if(liquidatedOrder.auctionAccount != address(0)){
                doTransferOut(liquidatedOrder.xToken, payable(liquidatedOrder.liquidator), rewardFirst);
                uint256 rewardLast = fine.mul(rewardLastRate).div(1e18);
                doTransferOut(liquidatedOrder.xToken, payable(liquidatedOrder.auctionAccount), (rewardLast + liquidatedOrder.auctionPrice));

                addUpIncomeMap[liquidatedOrder.xToken] = addUpIncomeMap[liquidatedOrder.xToken] + (fine - rewardFirst - rewardLast);
            }else{
                doTransferOut(liquidatedOrder.xToken, payable(liquidatedOrder.liquidator), (liquidatedOrder.liquidatedPrice + rewardFirst));

                addUpIncomeMap[liquidatedOrder.xToken] = addUpIncomeMap[liquidatedOrder.xToken] + (fine - rewardFirst);
            }
            transferNftInternal(address(this), msg.sender, _order.collection, _order.tokenId, _order.nftType);
            _order.isWithdraw = true;
            liquidatedOrder.isPledgeRedeem = true;
            liquidatedOrder.auctionWinner = msg.sender;
            liquidatedOrder.auctionAccount = msg.sender;
            liquidatedOrder.auctionPrice = _amount;

            emit AuctionNFT(orderId, liquidatedOrder.xToken, msg.sender, amount, true);
            emit WithDraw(_order.collection, _order.tokenId, orderId, _order.pledger, msg.sender);
        }else{
            doTransferIn(liquidatedOrder.xToken, payable(msg.sender), amount);
            if(liquidatedOrder.auctionAccount == address(0)){
                doTransferOut(liquidatedOrder.xToken, payable(liquidatedOrder.liquidator), liquidatedOrder.liquidatedPrice);
            }else{
                doTransferOut(liquidatedOrder.xToken, payable(liquidatedOrder.auctionAccount), liquidatedOrder.auctionPrice);
            }

            liquidatedOrder.auctionAccount = msg.sender;
            liquidatedOrder.auctionPrice = amount;
            
            emit AuctionNFT(orderId, liquidatedOrder.xToken, msg.sender, amount, false);
        }
    }

    function withdrawNFT(uint256 orderId) external nonReentrant whenNotPaused(2){
        LiquidatedOrder storage liquidatedOrder = allLiquidatedOrder[orderId];
        Order storage _order = allOrders[orderId];
        if(isOrderLiquidated(orderId)){
            require(liquidatedOrder.auctionWinner == address(0), "the order has been withdrawn");
            require(!allLiquidatedOrder[orderId].isPledgeRedeem, "redeemed by the pledgor");
            CollectionNFT memory collectionNFT = collectionWhiteList[_order.collection];
            uint256 auctionDuration;
            if(collectionNFT.auctionDuration != 0){
                auctionDuration = collectionNFT.auctionDuration;
            }else{
                auctionDuration = auctionDurationOverAll;
            }
            require(block.timestamp > liquidatedOrder.liquidatedStartTime.add(auctionDuration), "the auction is not yet closed");
            require(msg.sender == liquidatedOrder.auctionAccount || (liquidatedOrder.auctionAccount == address(0) && msg.sender == liquidatedOrder.liquidator), "you can't extract NFT");
            transferNftInternal(address(this), msg.sender, _order.collection, _order.tokenId, _order.nftType);
            if(msg.sender == liquidatedOrder.auctionAccount && liquidatedOrder.auctionPrice != 0){
                uint256 profit = liquidatedOrder.auctionPrice.sub(liquidatedOrder.liquidatedPrice);
                uint256 compensatePledgerAmount = profit.mul(compensatePledgerRate).div(1e18);
                doTransferOut(liquidatedOrder.xToken, payable(_order.pledger), compensatePledgerAmount);
                uint256 liquidatorAmount = profit.mul(rewardFirstRate).div(1e18);
                doTransferOut(liquidatedOrder.xToken, payable(liquidatedOrder.liquidator), liquidatorAmount);

                addUpIncomeMap[liquidatedOrder.xToken] = addUpIncomeMap[liquidatedOrder.xToken] + (profit - compensatePledgerAmount - liquidatorAmount);
            }
            liquidatedOrder.auctionWinner = msg.sender;
        }else{
            require(!_order.isWithdraw, "the order has been drawn");
            require(_order.pledger != address(0) && msg.sender == _order.pledger, "withdraw auth failed");
            uint256 borrowBalance = controller.getOrderBorrowBalanceCurrent(orderId);
            require(borrowBalance == 0, "order has debt");
            transferNftInternal(address(this), _order.pledger, _order.collection, _order.tokenId, _order.nftType);
        }
        _order.isWithdraw = true;
        emit WithDraw(_order.collection, _order.tokenId, orderId, _order.pledger, msg.sender);
    }

    function getOrderDetail(uint256 orderId) external view returns(address collection, uint256 tokenId, address pledger){
        Order storage _order = allOrders[orderId];
        collection = _order.collection;
        tokenId = _order.tokenId;
        pledger = _order.pledger;
    }

    function notifyOrderLiquidated(address xToken, uint256 orderId, address liquidator, uint256 liquidatedPrice) external{
        require(msg.sender == address(controller), "auth failed");
        require(liquidatedPrice > 0, "invalid liquidate price");
        LiquidatedOrder storage liquidatedOrder = allLiquidatedOrder[orderId];
        require(liquidatedOrder.liquidator == address(0), "order has been liquidated");

        liquidatedOrder.liquidatedPrice = liquidatedPrice;
        liquidatedOrder.liquidator = liquidator;
        liquidatedOrder.xToken = xToken;
        liquidatedOrder.liquidatedStartTime = block.timestamp;

        Order storage order = allOrders[orderId];
        if(liquidator == order.pledger){
            liquidatedOrder.auctionWinner = liquidator;
            liquidatedOrder.isPledgeRedeem = true;
            order.isWithdraw = true;
            transferNftInternal(address(this), order.pledger, order.collection, order.tokenId, order.nftType);

            emit WithDraw(order.collection, order.tokenId, orderId, order.pledger, liquidatedOrder.auctionWinner);
        }
    }

    function notifyRepayBorrow(uint256 orderId) external{
        require(msg.sender == address(controller), "auth failed");
        require(!isOrderLiquidated(orderId), "withdrawal is not allowed for this order");
        Order storage _order = allOrders[orderId];
        require(tx.origin == _order.pledger, "you are not pledgor");
        require(!_order.isWithdraw, "the order has been drawn");
        transferNftInternal(address(this), _order.pledger, _order.collection, _order.tokenId, _order.nftType);
        _order.isWithdraw = true;

        emit WithDraw(_order.collection, _order.tokenId, orderId, _order.pledger, _order.pledger);
    }

    function isOrderLiquidated(uint256 orderId) public view returns(bool){
        LiquidatedOrder storage _order = allLiquidatedOrder[orderId];
        return ((_order.liquidatedPrice > 0) && (_order.liquidator != address(0)));
    }

    function doTransferIn(address xToken, address payable account, uint256 amount) internal{
        if(IXToken(xToken).underlying() != ADDRESS_ETH){
            require(msg.value == 0, "ERC20 don't accecpt ETH");
            uint256 balanceBefore = IERC20(IXToken(xToken).underlying()).balanceOf(address(this));
            IERC20(IXToken(xToken).underlying()).safeTransferFrom(account, address(this), amount);
            uint256 balanceAfter = IERC20(IXToken(xToken).underlying()).balanceOf(address(this));

            require(balanceAfter - balanceBefore == amount,"TransferIn amount not valid");
        }else{
            require(msg.value >= amount, "ETH value not enough");
            if (msg.value > amount){
                uint256 changeAmount = msg.value.sub(amount);
                (bool result, ) = account.call{value: changeAmount,gas: transferEthGasCost}("");
                require(result, "Transfer of ETH failed");
            }
        }
    }

    function doTransferOut(address xToken, address payable account, uint256 amount) internal{
        if(amount == 0) return;
        if (IXToken(xToken).underlying() != ADDRESS_ETH) {
            IERC20(IXToken(xToken).underlying()).safeTransfer(account, amount);
        } else {
            account.transfer(amount);
        }
    }

    function transferNftInternal(address _from, address _to, address _collection, uint256 _tokenId, uint256 _nftType) internal{
        require(_nftType == 721 || _nftType == 1155, "don't support this nft type");
        
        if (_nftType == 721) {
            IERC721Upgradeable(_collection).safeTransferFrom(_from, _to, _tokenId);
        }else if (_nftType == 1155){

            IERC1155Upgradeable(_collection).safeTransferFrom(
                    _from,
                    _to,
                    _tokenId,
                    1,
                    ""
                );
        }
    }

    function _depositPunk(uint256 punkIndex) internal{
        address owner = punks.punkIndexToAddress(punkIndex);
        require(owner == msg.sender, "not owner of punkIndex");
        punks.buyPunk(punkIndex);
        punks.transferPunk(userProxy, punkIndex);
        wrappedPunks.mint(punkIndex);
    }

    function getOrderState(uint256 orderId) external view returns(OrderState orderState){
        Order memory order = allOrders[orderId];
        LiquidatedOrder memory liquidatedOrder =  allLiquidatedOrder[orderId];
        if(order.pledger != address(0)){
            if(order.isWithdraw == false){
                if(liquidatedOrder.liquidator == address(0)){
                    orderState = OrderState.PLEDGEING;
                }else{
                    CollectionNFT memory collectionNFT = collectionWhiteList[order.collection];
                    uint256 auctionDuration;
                    uint256 redeemProtection;
                    if(collectionNFT.auctionDuration != 0){
                        auctionDuration = collectionNFT.auctionDuration;
                        redeemProtection = collectionNFT.redeemProtection;
                    }else{
                        auctionDuration = auctionDurationOverAll;
                        redeemProtection = redeemProtectionOverAll;
                    }
                    if(block.timestamp < liquidatedOrder.liquidatedStartTime.add(redeemProtection)){
                        orderState = OrderState.REDEEMPROTECTION;
                    }else if(block.timestamp < liquidatedOrder.liquidatedStartTime.add(auctionDuration)){
                        orderState = OrderState.LIQUIDITYING;
                    }else{
                        orderState = OrderState.LIQUIDITYEND;
                    }
                }
            }else{
                if(liquidatedOrder.auctionWinner == address(0)){
                    orderState = OrderState.NORMALWITHDRAW;
                }else{
                    orderState = OrderState.LIQUIDITYWITHDRAW;
                }
            }
            return orderState;
        }
        return OrderState.NOPLEDGE;
    }

    function airDrop(uint256 orderId, address airDropContract, uint256 ercType) public{
        require(address(xAirDrop) != address(0) && airDropContract != address(0), "no airdrop");
        Order memory order = allOrders[orderId];
        require(!order.isWithdraw, "order has been withdrawn");
        address receiver;
        if(isOrderLiquidated(orderId)){
            LiquidatedOrder memory liquidatedOrder =  allLiquidatedOrder[orderId];
            CollectionNFT memory collectionNFT = collectionWhiteList[order.collection];
            uint256 auctionDuration;
            if(collectionNFT.auctionDuration != 0){
                auctionDuration = collectionNFT.auctionDuration;
            }else{
                auctionDuration = auctionDurationOverAll;
            }
            if(block.timestamp > liquidatedOrder.liquidatedStartTime.add(auctionDuration)){
                if(liquidatedOrder.auctionAccount == address(0)){
                    receiver = liquidatedOrder.liquidator;
                }else{
                    receiver = liquidatedOrder.auctionAccount;
                }
            }else{
                receiver = order.pledger;
            }
        }else{
            receiver = order.pledger;
        }
        IERC721Upgradeable(order.collection).safeTransferFrom(address(this), address(xAirDrop), order.tokenId);
        xAirDrop.execution(order.collection, airDropContract, receiver, order.tokenId, ercType);
        IERC721Upgradeable(order.collection).safeTransferFrom(address(xAirDrop), address(this), order.tokenId);

        emit AirDrop(address(xAirDrop), msg.sender, receiver, order.collection, order.tokenId);
    }

    function batchAirDrop(uint256[] memory orderId, address airDropContract, uint256 ercType) external{
        for(uint256 i=0; i<orderId.length; i++){
            airDrop(orderId[i], airDropContract, ercType);
        }
    }

    function ordersBalancesOf(address account) external view returns(uint256){
        return ordersMap[account].length;
    }

    function ordersOfOwnerByIndex(address account, uint256 index) external view returns(uint256){
        require(index < ordersMap[account].length, "upper limit exceeded");
        return ordersMap[account][index];
    }

    function ordersOfOwnerOffset(address account, uint256 index, uint256 offset) external view returns(uint256[] memory orders){
        require(index + offset < ordersMap[account].length, "upper limit exceeded");
        orders = new uint256[](offset);
        uint256 count;
        for(uint256 i=index; i<index+offset; i++){
            orders[count] = ordersMap[account][i];
            count++;
        }
    }
    
    //================ receiver ================
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns(bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns(bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        return  interfaceId == 0x01ffc9a7 ||    // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
            interfaceId == 0x4e2312e0;     // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
    }

    //================ admin function ================
    function setCollectionlWhitList(address collection, bool flag, uint256 _auctionDuration, uint256 _redeemProtection, uint256 _increasingMin) external onlyAdmin{
        setCollectionlWhitListInternal(collection, flag, _auctionDuration, _redeemProtection, _increasingMin);
    }
    function setCollectionlWhitListInternal(address collection, bool flag, uint256 _auctionDuration, uint256 _redeemProtection, uint256 _increasingMin) internal{
        require(collection != address(0), "invalid collection");
        collectionWhiteList[collection].isCollectionWhiteList = flag;
        collectionWhiteList[collection].auctionDuration = _auctionDuration;
        collectionWhiteList[collection].redeemProtection = _redeemProtection;
        collectionWhiteList[collection].increasingMin = _increasingMin;
    }

    function batchAddCollectionlWhitList(address[] calldata collections, uint256[] calldata _auctionDuration, uint256[] calldata _redeemProtection, uint256[] calldata _increasingMin) external onlyAdmin{
        require(collections.length > 0, "invalid collections");
        require(collections.length == _auctionDuration.length,"collections and _auctionDuration len mismatch");
        require(_auctionDuration.length == _redeemProtection.length,"_redeemProtection and _auctionDuration len mismatch");
        require(_redeemProtection.length == _increasingMin.length,"_redeemProtection and _increasingMin len mismatch");
        for(uint256 i = 0; i < collections.length; i++){
            setCollectionlWhitListInternal(collections[i], true, _auctionDuration[i], _redeemProtection[i], _increasingMin[i]);
        }
    }

    function setPendingAdmin(address newPendingAdmin) external onlyAdmin{
        pendingAdmin = newPendingAdmin;
    }

    function acceptAdmin() external{
        require(msg.sender == pendingAdmin, "only pending admin could accept");
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    function setController(address _controller) external onlyAdmin{
        controller = IP2Controller(_controller);
    }

    function setPledgerFineRate(uint256 _pledgerFineRate) external onlyAdmin{
        require(_pledgerFineRate <= RATE_UPPER_LIMIT, "the upper limit cannot be exceeded");
        pledgerFineRate = _pledgerFineRate;
    }

    function setRewardFirstRate(uint256 _rewardFirstRate) external onlyAdmin{
        require((_rewardFirstRate + rewardLastRate) <= RATE_UPPER_LIMIT, "rewardLastRate the upper limit cannot be exceeded");
        require((_rewardFirstRate + compensatePledgerRate) <= RATE_UPPER_LIMIT, "compensatePledgerRate the upper limit cannot be exceeded");
        rewardFirstRate = _rewardFirstRate;
    }

    function setRewardLastRate(uint256 _rewardLastRate) external onlyAdmin{
        require((rewardFirstRate + _rewardLastRate) <= RATE_UPPER_LIMIT, "the upper limit cannot be exceeded");
        rewardLastRate = _rewardLastRate;
    }

    function setCompensatePledgerRate(uint256 _compensatePledgerRate) external onlyAdmin{
        require((_compensatePledgerRate + rewardFirstRate) <= RATE_UPPER_LIMIT, "the upper limit cannot be exceeded");
        compensatePledgerRate = _compensatePledgerRate;
    }

    function setAuctionDurationOverAll(uint256 _auctionDurationOverAll) external onlyAdmin{
        auctionDurationOverAll = _auctionDurationOverAll;
    }

    function setRedeemProtectionOverAll(uint256 _redeemProtectionOverAll) external onlyAdmin{
        redeemProtectionOverAll = _redeemProtectionOverAll;
    }

    function setIncreasingMinOverAll(uint256 _increasingMinOverAll) external onlyAdmin{
        increasingMinOverAll = _increasingMinOverAll;
    }

    function withdraw(address xToken, uint256 amount) external onlyAdmin{
        doTransferOut(xToken, payable(admin), amount);
    }

    function withdrawAuctionIncome(address xToken, uint256 amount) external onlyAdmin{
        require(amount <= addUpIncomeMap[xToken], "amount cannot be greater than the withdrawable income");
        doTransferOut(xToken, payable(admin), amount);
        addUpIncomeMap[xToken] -= amount;
    }

    function setTransferEthGasCost(uint256 _transferEthGasCost) external onlyAdmin {
        transferEthGasCost = _transferEthGasCost;
    }

    // 1 pledge, 2 withdraw, 3 auction
    function setPause(uint256 index, bool isPause) external onlyAdmin{
        pausedMap[index] = isPause;
    }

    function setXAirDrop(IXAirDrop _xAirDrop) external onlyAdmin{
        xAirDrop = _xAirDrop;
    }

    function claim(address airdop, bytes memory byteCode) external onlyAdmin{
        (bool result, ) = airdop.call(byteCode);
        require(result, "claim error");
    }

    function setPunks(IPunks _punks, IWrappedPunks _wrappedPunks) external onlyAdmin{
        punks = _punks;
        wrappedPunks = _wrappedPunks;
        wrappedPunks.registerProxy();
        userProxy = wrappedPunks.proxyInfo(address(this));
    }

    //================ modifier ================
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }

    modifier onlyAdmin(){
        require(msg.sender == admin, "admin auth");
        _;
    }

    modifier whenNotPaused(uint256 index) {
        require(!pausedMap[index], "Pausable: paused");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IP2Controller {

    function mintAllowed(address xToken, address minter, uint256 mintAmount) external;

    function mintVerify(address xToken, address account) external;

    function redeemAllowed(address xToken, address redeemer, uint256 redeemTokens, uint256 redeemAmount) external;

    function redeemVerify(address xToken, address redeemer) external;
    
    function borrowAllowed(address xToken, uint256 orderId, address borrower, uint256 borrowAmount) external;

    function borrowVerify(uint256 orderId, address xToken, address borrower) external;

    function repayBorrowAllowed(address xToken, uint256 orderId, address borrower, address payer, uint256 repayAmount) external;

    function repayBorrowVerify(address xToken, uint256 orderId, address borrower, address payer, uint256 repayAmount) external;

    function repayBorrowAndClaimVerify(address xToken, uint256 orderId) external;

    function liquidateBorrowAllowed(address xToken, uint256 orderId, address borrower, address liquidator) external;

    function liquidateBorrowVerify(address xToken, uint256 orderId, address borrower, address liquidator, uint256 repayAmount)external;
    
    function transferAllowed(address xToken, address src, address dst, uint256 transferTokens) external;

    function transferVerify(address xToken, address src, address dst) external;

    function getOrderBorrowBalanceCurrent(uint256 orderId) external returns(uint256);

    // admin function

    function addPool(address xToken, uint256 _borrowCap, uint256 _supplyCap) external;

    function addCollateral(address _collection, uint256 _collateralFactor, uint256 _liquidateFactor, address[] calldata _pools) external;

    function setPriceOracle(address _oracle) external;

    function setXNFT(address _xNFT) external;
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;
import "./IERC20.sol";
import "./IInterestRateModel.sol";

interface IXToken is IERC20 {

    function balanceOfUnderlying(address owner) external returns (uint256);

    function mint(uint256 amount) external payable;
    function redeem(uint256 redeemTokens) external;
    function redeemUnderlying(uint256 redeemAmounts) external;

    function borrow(uint256 orderId, address payable borrower, uint256 borrowAmount) external;
    function repayBorrow(uint256 orderId, address borrower, uint256 repayAmount) external payable;
    function liquidateBorrow(uint256 orderId, address borrower) external payable;

    function orderLiquidated(uint256 orderId) external view returns(bool, address, uint256); 

    function accrueInterest() external;

    function borrowBalanceCurrent(uint256 orderId) external returns (uint256);
    function borrowBalanceStored(uint256 orderId) external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);
    function exchangeRateStored() external view returns (uint256);

    function underlying() external view returns(address);
    function totalBorrows() external view returns(uint256);
    function totalCash() external view returns (uint256);
    function totalReserves() external view returns (uint256);

    /**admin function **/
    function setPendingAdmin(address payable newPendingAdmin) external;
    function acceptAdmin() external;
    function setReserveFactor(uint256 newReserveFactor) external;
    function reduceReserves(uint256 reduceAmount) external;
    function setInterestRateModel(IInterestRateModel newInterestRateModel) external;
    function setTransferEthGasCost(uint256 _transferEthGasCost) external;

    /**event */
    event Mint(address minter, uint256 mintAmount, uint256 mintTokens);
    event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);
    event Borrow(uint256 orderId, address borrower, uint256 borrowAmount, uint256 orderBorrows, uint256 totalBorrows);
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
    event NewAdmin(address oldAdmin, address newAdmin);
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../interface/IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

pragma solidity ^0.8.2;

interface IXAirDrop {

    function execution(address nftContract,  address airDropContract, address receiver, uint256 tokenIds, uint256 ercType) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^   0.8.2;

interface IPunks {
    
    function balanceOf(address account) external view returns (uint256);

    function punkIndexToAddress(uint256 punkIndex) external view returns (address owner);

    function buyPunk(uint256 punkIndex) external;

    function transferPunk(address to, uint256 punkIndex) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface IWrappedPunks is IERC721EnumerableUpgradeable {

    function punkContract() external view returns (address);

    function mint(uint256 punkIndex) external;

    function burn(uint256 punkIndex) external;

    function registerProxy() external;

    function proxyInfo(address user) external returns (address proxy);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
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

pragma solidity ^0.8.2;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function decimals() external view returns (uint8);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IInterestRateModel {

    function blocksPerYear() external view returns (uint256); 

    function isInterestRateModel() external returns(bool);

    function getBorrowRate(
        uint256 cash, 
        uint256 borrows, 
        uint256 reserves) external view returns (uint256);

    function getSupplyRate(
        uint256 cash, 
        uint256 borrows, 
        uint256 reserves, 
        uint256 reserveFactor) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    function abs(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a < b) {
            return b - a;
        }
        return a - b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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