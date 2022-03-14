// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;



interface IERC721 {
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
    // 
    event NewAuctionCreated(uint endsAt);
    event Bid(address indexed sender,uint bidNumber ,uint amount);
    event Winner(address indexed bidder);
    event End(address indexed winner, uint amount);
    event Lost(address indexed Loser);
    // State Variables 
    address payable public owner;
    IERC721 public NftMintPass;
    IERC721 public AuctionTicket;
    uint public nftId;
    uint public AuctionNo;
    // uint public passNumber = 1; 

    // // Top Bids Yet
    uint[] public topBidsYet;

    // Struct 
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
    
    mapping(uint => mapping (uint => address)) public auctionWinners;
    // Mappings
    mapping(uint => _auction) public auction;
    mapping(address => mapping(uint => mapping(uint => bool))) internal _pass;
    mapping(address => mapping(uint => bids)) internal _noOfBidsPerPerson;
    mapping(address => mapping(uint => mapping(uint => uint))) internal _bidPerPerson;

    // modifier 
    modifier onlyOwner(){
        require(msg.sender == owner,"Only Owner can run this function");
        _;
    }


    // Start and Pause function

    bool public StartandPause;

    function Start(uint _endAt) public onlyOwner {
        require(StartandPause == false, "Auction is not Pause");
        StartandPause = true;
        auction[AuctionNo].endAt = _endAt+block.timestamp;
    }

    function Pause() public onlyOwner  {
        require(StartandPause == true, "Auction is not Start");
        StartandPause = false;
        auction[AuctionNo].endAt = 0;
    }

    // constructor 
    constructor(
        address _RewardNFT,
        address _AuctionTicket,
        address payable _owner
    )  {
        NftMintPass = IERC721(_RewardNFT);
        AuctionTicket = IERC721(_AuctionTicket);
        owner = _owner;
        AuctionNo;
    }


    //  Functions 

    receive() external payable {}
    fallback() external payable {}

    function createNewAuction(
        uint _endAt,
        uint _lowestbid) public onlyOwner returns(bool){
        forceEnd();
        AuctionNo+=1;
        _auction storage a = auction[AuctionNo];
        (a.endAt=(_endAt+block.timestamp),a.started=true,a.ended=false,
        a.highestBid=0,a.bidders=0,a.lowestbid=_lowestbid);
        StartandPause = true;
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

    // complete Logic & tested 
    function bid() external payable {
        _auction storage a = auction[AuctionNo];
        require(a.started == true , "Auction is not started yet");
        require(StartandPause == true, "Auction is Pause yet");

        if (block.timestamp < a.endAt) {
            a.ended = true;
        }

        require(block.timestamp < a.endAt, "Auction is already Ended!");
        require(msg.value > a.lowestbid, "value must be higher then lowest");
        require(AuctionTicket.balanceOf(msg.sender) >= 1, "You must have Token ");
        require(msg.value > a.highestBid,"please enter amount higher then Previous bid");
        a.lowestbid = msg.value;
        a.highestBid = msg.value;
        a.bidders = a.bidders + 1;
        bids storage b = _noOfBidsPerPerson[msg.sender][AuctionNo];
        b._bids.push(a.bidders) ;
        _bidPerPerson[msg.sender][AuctionNo][a.bidders] = msg.value;
        (payable (address(this))).transfer(msg.value);

        auctionWinners[AuctionNo][a.bidders] = msg.sender;
        emit Bid(msg.sender,a.bidders,msg.value);

        // // Top Bids Yet
        topBidsYet.push( msg.value );
    }

    function winnersOfAuction(uint _AuctionNo) public view returns(address[] memory) {

        address[] memory Winners  = new address[](auction[_AuctionNo].bidders); 
        for (uint i = 0; i < Winners.length; i++) {
            Winners[i]  = (auctionWinners[_AuctionNo][i]);
        }
        return Winners;
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

        delete topBidsYet;
    }

    // complete Logic & tested 
    function withdrawReward(uint _auctionNo,uint bidId) external {
        _auction storage a = auction[_auctionNo];
        require(block.timestamp > a.endAt,"time is not up yet to claim or withdraw" );
        require(a.ended = true);

        if(_bidPerPerson[msg.sender][_auctionNo][bidId] > 0 ){
            if(a.bidders > 20){
                if( bidId <= (a.bidders-20) ){        
                    (payable(msg.sender)).transfer(_bidPerPerson[msg.sender][_auctionNo][bidId]);
                    _bidPerPerson[msg.sender][_auctionNo][bidId] = 0;
                    emit Lost(msg.sender);
                }else if( bidId > (a.bidders-20) ){   
                    (owner).transfer(_bidPerPerson[msg.sender][_auctionNo][bidId]);
                    passUpdate(msg.sender, _auctionNo, a.bidders);
                    _bidPerPerson[msg.sender][_auctionNo][bidId] = 0;
                    emit Winner(msg.sender);
                }
            }else if( a.bidders < 20 ){
                (owner).transfer(_bidPerPerson[msg.sender][_auctionNo][bidId]);
                passUpdate(msg.sender, _auctionNo, a.bidders);
                _bidPerPerson[msg.sender][_auctionNo][bidId] = 0;
                emit Winner(msg.sender);
            }
        }
             
    }

    function checkPass(address user, uint _AuctionNo, uint _bidders) public view returns (bool) {
        return (_pass[user][_AuctionNo][_bidders]);
    }

    // Top Bids Yet Function
    function checkTopBids() public view returns (uint[] memory) {
        return topBidsYet;
        
    }

    function passUpdate(address user, uint _auctionNo, uint _bidders) internal{
        _pass[user][_auctionNo][_bidders] = true;
        //passNumber++;
    }

}