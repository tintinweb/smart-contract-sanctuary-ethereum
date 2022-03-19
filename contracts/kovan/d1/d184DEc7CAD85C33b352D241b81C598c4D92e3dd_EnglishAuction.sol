// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface BEP20 {
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


    function approve(address spender, uint256 amount) external returns (bool);

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

interface BEP721 {
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external;

    function transferFrom(
        address,
        address,
        uint
    ) external;
    function balanceOf(
        address owner)
        external view 
        returns (uint256 balance);
    function updatePass(address user, uint amount) external;

}

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

/*
///                                ___                                
//                                (   )      .-.                      
//    .---.   ___  ___    .--.     | |_     ( __)   .--.    ___ .-.   
/    / .-, \ (   )(   )  /    \   (   __)   (''")  /    \  (   )   \  
/   (__) ; |  | |  | |  |  .-. ;   | |       | |  |  .-. ;  |  .-. .  
///   .'`  |  | |  | |  |  |(___)  | | ___   | |  | |  | |  | |  | |  
/    / .'| |  | |  | |  |  |       | |(   )  | |  | |  | |  | |  | |  
/   | /  | |  | |  | |  |  | ___   | | | |   | |  | |  | |  | |  | |  
/   ; |  ; |  | |  ; '  |  '(   )  | ' | |   | |  | '  | |  | |  | |  
/   ' `-'  |  ' `-'  /  '  `-' |   ' `-' ;   | |  '  `-' /  | |  | |  
/   `.__.'_.   '.__.'    `.__,'     `.__.   (___)  `.__.'  (___)(___) 

*/
contract EnglishAuction {
    // State Variables 
    address public owner;
    BEP721 public RewardNFT;
    BEP20 public HGB;
    uint public nftId;
    uint public AuctionNo = 1; 
    uint public requestID = 1;
    uint public buyerID = 1;
    uint public sellerID = 1;
    // Structs
    struct _auction{
        uint endAt;
        bool started;
        bool ended;
        uint highestBid;
        uint lowestbid;
        uint bidders;
    }
    struct bids{
        uint[] _bids;
    }
    
    //  Events 
    event NewAuctionCreated(uint endsAt);
    event Bid(address indexed sender,uint bidNumber ,uint amount);
    event Winner(address indexed bidder);
    event End(address indexed winner, uint amount);
    event Lost(address indexed Loser);
    // Mappings 
    mapping(uint => mapping (uint => address)) public userPerBidID;
    mapping(uint => _auction) public auction;
    mapping(address => mapping(uint => mapping(uint => bool))) internal _pass;
    mapping(address => mapping(uint => bids)) internal _noOfBidsPerPerson;
    mapping(address => mapping(uint => mapping(uint => uint))) internal _bidPerPerson;
        // for Auction
    mapping(uint => address) public request;
    mapping(address => bool)public grant;
    mapping(uint => uint) public RewardToken;
        // Market 
    mapping(uint => address) public buyer;
    mapping(uint => address) public seller;
    mapping(address => bool) public grantBuy;
    mapping(address => bool) public grantSell;
    mapping(uint => bool) public onSell;
    mapping (uint => uint ) public tokenPrice;
    // modifier 
    modifier onlyOwner(){
        require(msg.sender == owner,"Only Owner can run this function");
        _;
    }

    // constructor 
    constructor(
        address _HGB,
        address _RewardNFTAddress,
        address _owner
    )  {
        HGB = BEP20(_HGB);
        RewardNFT = BEP721(_RewardNFTAddress);
        owner = _owner;
    }


    //  Functions 

    receive() external payable {}
    fallback() external payable {}

    function createNewAuction(
        uint _endAt,
        uint _lowestbid,
        uint TokenID) 
        public onlyOwner 
        returns(bool){
            forceEnd();
            _auction storage a = auction[AuctionNo];
            AuctionNo+=1;
            (a.endAt=(_endAt+block.timestamp),a.started=true,a.ended=false,
            a.highestBid=0,a.bidders=0,a.lowestbid=_lowestbid);
            RewardToken[AuctionNo]=TokenID;
            RewardNFT.transferFrom(owner, address(this), TokenID);
            emit NewAuctionCreated(_endAt);
            return true;
    }

    function checkAuction(uint _auctionNumber)public view returns(uint,bool,bool,uint,uint){
        _auction storage a = auction[_auctionNumber];
        return(a.endAt,a.started,a.ended,a.highestBid,a.lowestbid);
    }

    function currentAuctionNumber() public view returns(uint){
        return AuctionNo;
    }

    function permissionFromOwner() public{  
        request[requestID] = msg.sender;
        requestID+=1;
    }

    function grantPermission(bool _action, uint _requestId) public onlyOwner{
        grant[request[_requestId]] = _action;
    }

    // complete Logic & tested 
    function bid(uint _price) external payable {
        _auction storage a = auction[AuctionNo];
        require(a.started == true , "Auction is not started yet");
        if (block.timestamp > a.endAt) {
            a.ended = true;
        }
        require(block.timestamp < a.endAt, "Auction is already Ended!");
        require(HGB.balanceOf(msg.sender) >= _price, "You must have HGB ");
        require(_price > a.highestBid,"please enter amount higher then Previous bid");
        a.lowestbid = _price;
        a.highestBid = _price;
        a.bidders = a.bidders + 1;
        bids storage b = _noOfBidsPerPerson[msg.sender][AuctionNo];
        b._bids.push(a.bidders) ;
        _bidPerPerson[msg.sender][AuctionNo][a.bidders] = _price;
        HGB.transferFrom(msg.sender,address(this), _price);
        userPerBidID[AuctionNo][a.bidders] = msg.sender;
        // // Top Bids Yet
        emit Bid(msg.sender,a.bidders,_price);
    }

    function winnerOfAuction(uint _AuctionNo) public view returns(address) {
        if(auction[_AuctionNo].ended == true){
            return userPerBidID[_AuctionNo][auction[_AuctionNo].bidders];
        }else{
            return address(0);
        }
    }

    // complete Logic & tested
    function checkBidsPerId(address _user) public view returns(uint[] memory){
        _auction storage a = auction[AuctionNo];
        bids storage b = _noOfBidsPerPerson[_user][AuctionNo];
        uint[] memory number = new uint[](a.bidders);
        for(uint i =0; i < b._bids.length; i++ ){
            number[i] =  b._bids[i];
        }
            return (number);        
    }

    function forceEnd()public onlyOwner{
        _auction storage a = auction[AuctionNo];
        a.endAt = block.timestamp;
        a.ended = true;
    }

    // complete Logic & tested 
    function withdrawReward(uint _auctionNo,uint bidId) external {
        _auction storage a = auction[_auctionNo];
        require(block.timestamp > a.endAt,"time is not up yet to claim or withdraw" );
        require(a.ended == true, "Auction is Not Ended yet !");
        // loser
        if(auction[_auctionNo].bidders < bidId){
            HGB.transferFrom(address(this), msg.sender,_bidPerPerson[msg.sender][_auctionNo][bidId] );
            emit Lost(msg.sender);
        }
        // Winner
        else if(auction[_auctionNo].bidders == bidId){
            RewardNFT.transferFrom(address(this), msg.sender,RewardToken[_auctionNo]);
            emit Winner(msg.sender);
        }
    }

    // Top Bids Yet Function
    function checkHighestBid(uint _auctionNo) public view returns (uint) {
        return (auction[_auctionNo].highestBid);   
    }

    function requestForBuy() external{
        buyer[buyerID] = msg.sender; 
    }
    function requestForSell() external {
        seller[sellerID] = msg.sender;
    }

    function approveBuyer(uint _buyerId , bool _grant) external onlyOwner{
        grantBuy[buyer[_buyerId]] = _grant;
    }
    function approveSeller(uint _sellerId , bool _grant) external onlyOwner{
        grantSell[seller[_sellerId]] = _grant;
    }

    function buy(uint _tokenID, uint _price) external{
        require(grantBuy[msg.sender] == true, "You are not allowed to buy");
        require(onSell[_tokenID] == true, "this Token is not on Sell");
        require(_price == tokenPrice[_tokenID], "Price is not valid");
        HGB.transferFrom( msg.sender, address(this), tokenPrice[_tokenID]);
        tokenPrice[_tokenID] = 0;
        RewardNFT.transferFrom(address(this), msg.sender,_tokenID);
    }
    function sell(uint _tokenID, uint _price) external{
        require(grantSell[msg.sender] == true, "You are not allowed to sell");
        onSell[_tokenID] = true;
        tokenPrice[_tokenID] = _price;
        RewardNFT.transferFrom(msg.sender, address(this), _tokenID);
    }

}