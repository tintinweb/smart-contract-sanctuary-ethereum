/**
 *Submitted for verification at Etherscan.io on 2023-02-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

abstract contract Pausable {
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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
        emit Paused(msg.sender);
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
        emit Unpaused(msg.sender);
    }
}


interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IFeeFreeChecker {
    function isFeeFree(address _buyer, address _seller, address _broker, address _token, uint256 _amount) external view returns(bool);
}


contract Descrow is Pausable {

    address payable public owner;
    uint16 constant public percentDivider = 1000;

    uint256 public totalAgent;


    mapping(address=>bool) public Admin;
    mapping(address=>bool) public blackListedUser;

    mapping(address => uint256) public adminCut;

    uint256 public _escrowIds;
    mapping(uint256 => Escrow) public idToEscrow;
    mapping(address => uint256) public addressToEscrowCount;
    mapping(address => mapping(uint256 => uint256)) public addressToEscrowIndexes;

    mapping(address => broker) public Agent;
    mapping(uint256 => address) public AgentID;

    mapping(address => mapping(address => BrokerTokenComission)) public tokenComissionInfo;

    uint256 public brokerCutfromTotalCut;

    uint256[4] public fees = [40,30,20,10];
    
    mapping(address => TokenInfo) public supportedTokenInfos;
    address[] public supportedTokens;
    address public feeFreeChecker;

    constructor(address payable _owner, uint256 brokerCutVal, address _feeFreeChecker) {
        owner = _owner; // Address of contract owner
        brokerCutfromTotalCut = brokerCutVal;
        feeFreeChecker = _feeFreeChecker;
    }

    enum EscrowState {
        PENDING,
        AWAITING_DELIVERY,
        DISPUTED,
        COMPLETED,
        REFUNDED
    }

    struct Escrow {
        uint256 id;
        address token;
        address payable buyer;
        address payable seller;
        address payable broker;
        uint256 payAmount;
        uint256 realAmount;
        uint256 fee;
        uint256 createdAt;
        uint256 expireAt;
        uint256 clearAt;
        EscrowState state;
    }

    struct TokenInfo {
        bool hasAdded;
        bool enabled;
        address tokenAddress;
        uint256[4] escrowAmountCap;
        uint256 balance;
    }

    struct broker{
        uint256 no_escrow_created;
        bool status;
        bool alreadyExist;
    }

    struct BrokerTokenComission{
        uint256 commisionEarned;
        uint256 commisionClaimed;
    }


    event EscrowCreated(
        uint256 indexed escrowId,
        address token,
        address buyer,
        address seller,
        address broker,
        uint256 indexed payAmount,
        uint256 realAmount,
        uint256 indexed fee,
        EscrowState state
    );

    event EscrowUpdated(
        uint256 indexed escrowId,
        address buyer,
        address seller,
        address broker,
        uint256 payAmount,
        uint256 realAmount,
        uint256 fee,
        EscrowState indexed state
    );

    modifier onlyowner() {
        require(owner == msg.sender, "only owner");
        _;
    }

    // Custom Code Area Begins
    modifier onlyBuyer(uint256 escrowId) {
        require(
            idToEscrow[escrowId].buyer == msg.sender,
            "Only Buyer Can Access"
        );
        _;
    }

    modifier onlySeller(uint256 escrowId) {
        require(
            idToEscrow[escrowId].seller == msg.sender,
            "Only Seller Can Access"
        );
        _;
    }

    modifier onlyOwnerOrAdmin(){
        require(owner == msg.sender || Admin[msg.sender],"Only Owner and Admin can perform this action");
        _;
    }

    modifier notBuyer(uint256 escrowId) {
        require(
            idToEscrow[escrowId].seller == msg.sender || owner == msg.sender,
            "Only seller or Owner can perform this action"
        );
        _;
    }

    function getFee(address _buyer, address _seller, address _broker, address _token, uint256 _amount) public view returns(uint256){
        if(feeFreeChecker != address(0) && IFeeFreeChecker(feeFreeChecker).isFeeFree(_buyer, _seller, _broker, _token, _amount)){
            return 0;
        }
        return getFeeByTokenInfo(supportedTokenInfos[_token], _amount);
    }

    function getFee2(address _buyer, address _seller, address _broker, TokenInfo storage _tokenInfo, uint256 _amount) internal view returns(uint256){
        if(feeFreeChecker != address(0) && IFeeFreeChecker(feeFreeChecker).isFeeFree(_buyer, _seller, _broker, _tokenInfo.tokenAddress, _amount)){
            return 0;
        }
        return getFeeByTokenInfo(_tokenInfo, _amount);
    }

    function getFeeByTokenInfo(TokenInfo storage _tokenInfo, uint256 _amount) internal view returns(uint256){
        for(uint256 i = _tokenInfo.escrowAmountCap.length - 1; i >= 0; i--){
            if(_amount >= _tokenInfo.escrowAmountCap[i]){
                return fees[i] * _amount / percentDivider;
            }
        }
        revert("Invalid Amount");
    }

    function newEscrow(
        address _token,
        address _seller,
        uint256 _expireIn,
        uint256 _amount
    ) public whenNotPaused payable {
        require(blackListedUser[_seller] == false && blackListedUser[msg.sender] == false,"Buyer or seller is blacklisted");
        TokenInfo storage tokenInfo = supportedTokenInfos[_token];
        require(tokenInfo.enabled, "Token not enabled");
        require(
            _amount >= tokenInfo.escrowAmountCap[0],
            "Escrow must be larger then minimum amount"
        );
        uint256 receivedAmount = _amount;
        if(_token == address(0)){
            require(msg.value == _amount,"Pass same  val");
        }
        else{
            receivedAmount = receiveToken(IERC20(_token), msg.sender, _amount);
        }

        uint256 fee = getFee2(msg.sender, _seller, address(0), tokenInfo, _amount);
        require(receivedAmount >= fee, "Fee is larger then amount");
        uint256 realAmount = receivedAmount - fee;
        
        _escrowIds++;
        uint256 curId = _escrowIds;
        idToEscrow[curId] = Escrow(
            curId,
            _token,
            payable(msg.sender),
            payable(_seller),
            payable(address(0)),
            _amount,
            realAmount,
            fee,
            block.timestamp,
            _expireIn,
            0,
            EscrowState.AWAITING_DELIVERY
        );

        tokenInfo.balance += receivedAmount;

        addressToEscrowCount[msg.sender] = addressToEscrowCount[msg.sender] + 1;
        addressToEscrowIndexes[msg.sender][
            addressToEscrowCount[msg.sender]
        ] = curId;
        addressToEscrowCount[_seller] = addressToEscrowCount[_seller] + 1;
        addressToEscrowIndexes[_seller][addressToEscrowCount[_seller]] = curId;

        emit EscrowCreated(
            curId,
            _token,
            msg.sender,
            _seller,
            address(0),
            _amount,
            realAmount,
            fee,
            EscrowState.AWAITING_DELIVERY
        );
    }


    function newEscrowByAgent(
        address _token,
        address _seller,
        address _buyer,
        uint256 _expireIn,
        uint256 _amount
    ) public whenNotPaused payable {
        require(Agent[msg.sender].status== true,"Agent if block or not approved yet");
        require(blackListedUser[_seller] == false && blackListedUser[_buyer] == false,"Buyer or seller is blacklisted");
        TokenInfo storage tokenInfo = supportedTokenInfos[_token];
        require(tokenInfo.enabled, "Token not enabled");
        require(
            _amount >= tokenInfo.escrowAmountCap[0],
            "Escrow must be larger then minimum amount"
        );


        uint256 fee = getFee2(_buyer, _seller, msg.sender, tokenInfo, _amount);

        _escrowIds++;
        uint256 curId = _escrowIds;
        idToEscrow[curId] = Escrow(
            curId,
            _token,
            payable(_buyer),
            payable(_seller),
            payable(msg.sender),
            _amount,
            0,
            fee,
            block.timestamp,
            _expireIn,
            0,
            EscrowState.PENDING
        );

        addressToEscrowCount[msg.sender] = addressToEscrowCount[msg.sender] + 1;
        addressToEscrowIndexes[msg.sender][
            addressToEscrowCount[msg.sender]
        ] = curId;
        addressToEscrowCount[_seller] = addressToEscrowCount[_seller] + 1;
        addressToEscrowIndexes[_seller][addressToEscrowCount[_seller]] = curId;
        addressToEscrowCount[_buyer] = addressToEscrowCount[_buyer] + 1;
        addressToEscrowIndexes[_buyer][addressToEscrowCount[_buyer]] = curId;

        emit EscrowCreated(
            curId,
            _token,
            _buyer,
            _seller,
            msg.sender,
            _amount,
            0,
            fee,
            EscrowState.PENDING
        );
    }

    function escrowFunded(uint256 _escrowId)
        public
        payable
        onlyBuyer(_escrowId)
    {
        Escrow storage escrow = idToEscrow[_escrowId];
        require(escrow.state == EscrowState.PENDING,
                "Already Procesed Escrow");
        
        uint256 receivedAmount = escrow.payAmount;

        if(escrow.token == address(0)){
            require(msg.value == escrow.payAmount, "Minimum Required");
        }
        else{
            receivedAmount = receiveToken(IERC20(escrow.token), msg.sender, escrow.payAmount);
        }

        require(receivedAmount >= escrow.fee, "Fee is larger then amount");
        uint256 realAmount = receivedAmount - escrow.fee;
        escrow.realAmount = realAmount;

        supportedTokenInfos[escrow.token].balance += receivedAmount;

        escrow.state = EscrowState.AWAITING_DELIVERY;

        emit EscrowUpdated(
            _escrowId,
            escrow.buyer,
            escrow.seller,
            escrow.broker,
            escrow.payAmount,
            realAmount,
            escrow.fee,
            EscrowState.AWAITING_DELIVERY
        );
    }

    function deliver(uint256 _escrowId)
        public
        onlyBuyer(_escrowId)
    {
        Escrow storage escrow = idToEscrow[_escrowId];
        require(
            escrow.state == EscrowState.AWAITING_DELIVERY,
            "You can't deliver this escrow. Already updated before"
        );
        
        deliverInternal(escrow);
    }

    function makeDisputedEscrow(uint256 _escrowId) public payable{
        Escrow storage escrow = idToEscrow[_escrowId];
        require(
            escrow.state == EscrowState.AWAITING_DELIVERY,
            "You can't make dispute this escrow. Already updated before"
        );
        require(escrow.buyer == msg.sender || 
                escrow.seller == msg.sender ||
                escrow.broker == msg.sender,"Not Authorized");

        escrow.state = EscrowState.DISPUTED;

        emit EscrowUpdated(
            _escrowId,
            escrow.buyer,
            escrow.seller,
            escrow.broker,
            escrow.payAmount,
            escrow.realAmount,
            escrow.fee,
            EscrowState.DISPUTED
        );
    }

    function solveDisputebyRefund(uint256 _escrowId) public onlyOwnerOrAdmin{
        Escrow storage escrow = idToEscrow[_escrowId];
        require(
            escrow.state == EscrowState.DISPUTED,
            "Not Disputed"
        );
        
        refundInternal(escrow);
    }

    function solveDisputebyPayingSeller(uint256 _escrowId ) public onlyOwnerOrAdmin{
        Escrow storage escrow = idToEscrow[_escrowId];
        require(
            escrow.state == EscrowState.DISPUTED,
            "Not Disputed"
        );
        
        deliverInternal(escrow);
    }

    function deliverInternal(Escrow storage escrow) internal {
        localTransfer(escrow.token, escrow.seller, escrow.realAmount);

        if(escrow.broker != address(0)){
            uint256 tempBrokerCut = escrow.fee * brokerCutfromTotalCut / percentDivider;
            uint256 tempAdminCut = escrow.fee - tempBrokerCut;
            adminCut[escrow.token] += tempAdminCut;
            tokenComissionInfo[escrow.broker][escrow.token].commisionEarned += tempBrokerCut;
        }
        else{
            adminCut[escrow.token] += escrow.fee;
        }

        escrow.clearAt = block.timestamp;
        escrow.state = EscrowState.COMPLETED;
        supportedTokenInfos[escrow.token].balance -= escrow.realAmount;

        emit EscrowUpdated(
            escrow.id,
            escrow.buyer,
            escrow.seller,
            escrow.broker,
            escrow.payAmount,
            escrow.realAmount,
            escrow.fee,
            EscrowState.COMPLETED
        );
    }

    function refundInternal(Escrow storage escrow) internal {
        uint256 refundAmount = escrow.realAmount + escrow.fee;
        localTransfer(escrow.token, escrow.buyer, refundAmount);
        
        escrow.clearAt = block.timestamp;
        escrow.state = EscrowState.REFUNDED;

        supportedTokenInfos[escrow.token].balance -= refundAmount;

        emit EscrowUpdated(
            escrow.id,
            escrow.buyer,
            escrow.seller,
            escrow.broker,
            escrow.payAmount,
            escrow.realAmount,
            escrow.fee,
            EscrowState.REFUNDED
        );
    }

    function refund(uint256 _escrowId) public onlySeller(_escrowId) {
        Escrow storage escrow = idToEscrow[_escrowId];
        
        require(
            escrow.state == EscrowState.AWAITING_DELIVERY,
            "Can't refund this escrow. Already updated before"
        );
        
        refundInternal(escrow);
    }

    /* Returns escrows based on roles */
    function fetchMyEscrows() public view returns (Escrow[] memory) {
        if (owner == msg.sender) {
            uint256 totalItemCount = _escrowIds;
            Escrow[] memory items = new Escrow[](totalItemCount);
            for (uint256 i = 0; i < totalItemCount; i++) {
                items[i] = idToEscrow[i + 1];
            }
            return items;
        } else {
            // if signer is not owner
            Escrow[] memory items = new Escrow[](
                addressToEscrowCount[msg.sender]
            );
            for (uint256 i = 0; i < addressToEscrowCount[msg.sender]; i++) {
                items[i] = idToEscrow[
                    addressToEscrowIndexes[msg.sender][i + 1]
                ];
            }
            return items;
        }
    }

    function fetchEscrowsPaginated(uint256 cursor, uint256 perPageCount)
        public
        view
        returns (
            Escrow[] memory data,
            uint256 totalItemCount,
            bool hasNextPage,
            uint256 nextCursor
        )
    {
        uint256 length = perPageCount;
        if (owner == msg.sender) {
            uint256 totalCount = _escrowIds;
            bool nextPage = true;
            if (length > totalCount - cursor) {
                length = totalCount - cursor;
                nextPage = false;
            } else if (length == (totalCount - cursor)) {
                nextPage = false;
            }
            Escrow[] memory items = new Escrow[](length);
            for (uint256 i = 0; i < length; i++) {
                items[i] = idToEscrow[cursor + i + 1];
            }
            return (items, totalCount, nextPage, (cursor + length));
        } else {
            bool nextPage = true;
            if (length > addressToEscrowCount[msg.sender] - cursor) {
                length = addressToEscrowCount[msg.sender] - cursor;
                nextPage = false;
            } else if (length == (addressToEscrowCount[msg.sender] - cursor)) {
                nextPage = false;
            }
            Escrow[] memory items = new Escrow[](length);
            for (uint256 i = 0; i < length; i++) {
                items[i] = idToEscrow[
                    addressToEscrowIndexes[msg.sender][cursor + i + 1]
                ];
            }
            return (
                items,
                addressToEscrowCount[msg.sender],
                nextPage,
                (cursor + length)
            );
        }
    }

    function claimAdminFee(address _token) public onlyOwnerOrAdmin {
        uint256 amount = adminCut[_token];
        require(amount > 0, "admin fee balance is 0");
        localTransfer(_token, owner, amount);
        adminCut[_token]= 0;
        supportedTokenInfos[_token].balance -= amount;
    }

    function claimBrokerCut(address _token) public {
        require(blackListedUser[msg.sender] == false,"addrress is blacklisted");

        BrokerTokenComission storage comission = tokenComissionInfo[msg.sender][_token];
        uint256 amount = comission.commisionEarned;
        require(amount > 0, "broker fee balance is 0");
        
        localTransfer(_token, msg.sender, amount);
        
        comission.commisionClaimed += amount;
        comission.commisionEarned = 0;
        supportedTokenInfos[_token].balance -= amount;
    }

    function fetchEscrow(uint256 escrowId) public view returns (Escrow memory) {
        return idToEscrow[escrowId];
    }

    function fetchEscrowBatch(uint256[] memory escrowIds)
        public
        view
        returns (Escrow[] memory)
    {
        Escrow[] memory items = new Escrow[](escrowIds.length);
        for (uint256 i = 0; i < escrowIds.length; i++) {
            items[i] = idToEscrow[escrowIds[i]];
        }
        return items;
    }

    function fetchLatestEscrows(uint256 count)
        public
        view
        returns (Escrow[] memory)
    {
        uint256 totalItemCount = _escrowIds;
        uint256 length = count;
        if (length > totalItemCount) {
            length = totalItemCount;
        }
        Escrow[] memory items = new Escrow[](length);
        for (uint256 i = 0; i < length; i++) {
            items[i] = idToEscrow[totalItemCount - i];
        }
        return items;
    }

    function transferOwnership(address _newOwner) public onlyowner {
        owner = payable(_newOwner);
    }

    function pause() public onlyowner {
        _pause();
    }

    function unpause() public onlyowner {
        _unpause();
    }

    function fetchSupportedTokensCount() public view returns (uint256) {
        return supportedTokens.length;
    }

    function fetchSupportedTokenInfos() public view returns (TokenInfo[] memory) {
        TokenInfo[] memory items = new TokenInfo[](supportedTokens.length);
        for (uint256 i = 0; i < supportedTokens.length; i++) {
            items[i] = supportedTokenInfos[supportedTokens[i]];
        }
        return items;
    }
    
    function addSupportedToken(
        address token,
        uint256 first,
        uint256 second,
        uint256 third,
        uint256 fourth
    ) external onlyowner {
        
        TokenInfo storage info = supportedTokenInfos[token];

        require(!info.hasAdded, "Token already supported");
        info.hasAdded = true;
        info.tokenAddress = token;
        supportedTokens.push(token);
        updateSupportedToken(token, true, first, second, third, fourth);
    }

    function updateSupportedToken(
        address token,
        bool enabled,
        uint256 first,
        uint256 second,
        uint256 third,
        uint256 fourth
    ) public onlyowner {
        TokenInfo storage info = supportedTokenInfos[token];
        require(info.hasAdded, "Token not supported");

        info.enabled = enabled;
        info.escrowAmountCap[0] = first;
        info.escrowAmountCap[1] = second;
        info.escrowAmountCap[2] = third;
        info.escrowAmountCap[3] = fourth;
    }

    function setFeesOnCaping(
        uint256 first,
        uint256 second,
        uint256 third,
        uint256 fourth
    ) public onlyowner {
        require(first <= percentDivider,"Can't set more then 100");
        require(second <= percentDivider,"Can't set more then 100");
        require(third <= percentDivider,"Can't set more then 100");
        require(fourth <= percentDivider,"Can't set more then 100");
        fees[0] = first;
        fees[1] = second;
        fees[2] = third;
        fees[3] = fourth;
    }

    function updateAdmin(address _address) public onlyowner
    {
        Admin[_address] = true;
    }
    
    function removeAdmin(address _address)public onlyowner
    {
        Admin[_address] = false;
    }

    function addBlacklistAddress(address _address) 
        public onlyOwnerOrAdmin
    {
        require(msg.sender == owner || Admin[_address], "not owner and admin");
        if(Agent[_address].alreadyExist == true){
            Agent[_address].status == false;
        }
        blackListedUser[_address] = true;
    }
    
    function removeBlacklistAddress(address _address)public onlyOwnerOrAdmin
    {
        blackListedUser[_address] = false;
    }

    function setFeeFreeChecker(address _feeFreeChecker) public onlyowner
    {
        feeFreeChecker = _feeFreeChecker;
    }

    function rescueBNB() public onlyowner {
        uint256 balance = address(this).balance;
        TokenInfo storage info = supportedTokenInfos[address(0)];
        balance -= info.balance;
        require(balance > 0, "does not have any balance");
        payable(msg.sender).transfer(balance);
    }

    function rescueToken(address addr, uint256 amount) public onlyowner {
        uint256 balance = IERC20(addr).balanceOf(address(this));
        TokenInfo storage info = supportedTokenInfos[address(0)];
        balance -= info.balance;
        require(balance >= amount, "does not have enough balance");
        IERC20(addr).transfer(msg.sender, amount);
    }

    function newBrokerAddRequest() public payable{
        require(Agent[msg.sender].alreadyExist == false, "Agent Alredy Exist");
        AgentID[totalAgent] = msg.sender;
        totalAgent++;

        Agent[msg.sender] = broker(
            0,
            false,
            true
        );
    }

    function approveOrUnblockBroker(address addr) public onlyOwnerOrAdmin{
        Agent[addr].status = true;
    }

    function blockBroker(address addr) public onlyOwnerOrAdmin{
        Agent[addr].status = false;
    }

    function changeBrokerCut(uint256 val) public onlyOwnerOrAdmin{
        brokerCutfromTotalCut = val;
    }

    function directBrokerAddByAdmin(address addr) public onlyOwnerOrAdmin{
        require(Agent[addr].alreadyExist == false, "Agent Alredy Exist");
        AgentID[totalAgent] = msg.sender;
        totalAgent++;

        Agent[addr] = broker(
            0,
            true,
            true
        );
    }

    function localTransfer(address tokenAddr, address to, uint256 amount) internal {
        if(tokenAddr == address(0)){
            payable(to).transfer(amount);
        }
        else{
            IERC20(tokenAddr).transfer(to,amount);
        }
    }

    function receiveToken(IERC20 tokenAddr, address from, uint256 amount) internal returns (uint256) {
        uint balance = tokenAddr.balanceOf(address(this));
        tokenAddr.transferFrom(from, address(this), amount);
        uint newBalance = tokenAddr.balanceOf(address(this));
        return newBalance - balance;
    }


    // important to receive native    
    receive() payable external {}
}