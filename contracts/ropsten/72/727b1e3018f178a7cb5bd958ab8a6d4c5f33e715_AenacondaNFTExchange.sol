/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

    interface IERC165 {
        function supportsInterface(bytes4 interfaceId) external view returns (bool);
    }

    interface IERC20 {
        function totalSupply() external view returns (uint256);
        function balanceOf(address who) external view returns (uint256);
        function allowance(address owner, address spender)external view returns (uint256);
        function transfer(address to, uint256 value) external returns (bool);
        function approve(address spender, uint256 value)external returns (bool);
        function transferFrom(address from, address to, uint256 value) external returns (bool);

        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner, address indexed spender, uint256 value);
    }

    interface IERC721 is IERC165 {
        function balanceOf(address owner) external returns (uint256 balance);
        function ownerOf(uint256 tokenId) external view returns (address owner);
        function safeTransferFrom(address from, address to, uint256 tokenId) external;
        function transferFrom(address from, address to, uint256 tokenId) external;
        function approve(address to, uint256 tokenId) external;
        function getApproved(uint256 tokenId) external view returns (address operator);
        function setApprovalForAll(address operator, bool _approved) external;
        function isApprovedForAll(address owner, address operator) external view returns (bool);
        function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
        function userappove(address from,address to,uint256 tokenId) external;
        function createrof(uint256 tokenId) external view returns(address);
        function royalty(uint256 tokenId) external view returns(uint256);

        event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
        event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
        event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    }

    interface IERC1155 is IERC165 {

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);


    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address from, address to, bool _approved, uint256 _id, uint256 _value) external returns(bool);

    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function creatoR(uint256 tokenId) external view returns(address);

    function royalty(uint256 tokenId) external view returns(uint256);

}
    
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
    * @dev Returns the address of the current owner.
    */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
    * @dev Leaves the contract without owner. It will not be possible to call
    * `onlyOwner` functions anymore. Can only be called by the current owner.
    *
    * NOTE: Renouncing ownership will leave the contract without an owner,
    * thereby removing any functionality that is only available to the owner.
    */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
    * @dev Transfers ownership of the contract to a new account (`newOwner`).
    * Can only be called by the current owner.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library Address {
        function isContract(address account) internal view returns (bool) {
            uint256 size;
            assembly {
                size := extcodesize(account)
            }
            return size > 0;
        }
    }

contract AenacondaNFTExchange is Ownable{
    using SafeMath for uint256;
    using Address for address;

    mapping(uint256=> mapping(uint256=>bool)) public AuctionStatus;
    mapping(string=>address)public payment;
    mapping(uint256=> mapping(uint256 => uint256)) public sellCount;
    mapping(uint256 => mapping(uint256 => Sell)) public seller;
    mapping(uint256 => mapping(uint256 => Auction)) public auctions;
    mapping(uint256 => uint256) public sellBidPrice;
    mapping(uint256 => uint256) public soldFor;
    mapping(uint256 => uint256) private balance;
    
    struct Sell{
            uint256 index;
            address creater;
            address buyer;
            uint256 tokenId;
            uint256 value;
            uint256 total_value;
            bool status;
            uint256 price;
            string paymentType;
            address payment;
    }

    struct Auction {
        uint256 index;
        address beneficiary;
        uint auctionStart;
        uint auctionEnd;
        uint256 tokenId;
        uint256 value;
        address highestBidder;
        uint highestBid;
        bool open;
        uint256 reserve;
        string  _name;
        address auctioncreater;
        address payment;
    }
    mapping(uint256 => uint256) public sellcount;
    mapping(uint256 => uint256)public auctionCount;
    uint256 public commissionRate;

    struct Localvariables{
        uint256 tokenId;
        uint256 value;
        uint256 auctionid;
        uint256 amount;
        uint256 sellcount;
    }

    address public admin;

    event Sale(uint256 indexed tokenId,uint256 _value,address indexed from, address indexed to, uint256 value);
    event Commission(uint256 indexed tokenId, address indexed to, uint256 value, uint256 rate, uint256 royality, uint256 total);
    event AuctionEnded(address winner, uint amount);
    event Refund(address bidder, uint amount);
    event AuctionClosed(uint256 tokenId);
    event onsell(uint256 tokenid, uint256 sellid, address seller);

    event onAuctioncreate(uint256 auctioncount, address beneficiary, uint256 auctionStart, uint256 auctionEnd, uint256 reservePrice);
    event HighestBidIncreased(address indexed bidder, uint amount, uint256 tokenId);

    constructor(string memory paymentName, address tokenAddress, uint256 _commisionRate){
        admin = msg.sender;
        commissionRate = _commisionRate;
        addpayment(paymentName, tokenAddress);
    }

    function addpayment(string memory paymentName, address tokenAddress)public onlyOwner returns(bool){
        require(payment[paymentName] == address(0x0), "a");
        require(tokenAddress != address(0x0), "b");
        payment[paymentName] = tokenAddress;
        return true; 
    }

    //function for sell
    function sell(uint256 tokenId, uint256 _value, uint256 price, string memory paymenttype, uint256 tokenType, address addressofNFT) public returns (bool){
        sellcount[tokenType] = sellcount[tokenType] + 1;
        uint256 a = sellcount[tokenType];

        require(price > 0);
        require(payment[paymenttype] != address(0));
        // require(!auctions[tokenType][tokenId][a].open);
        require(canSell(tokenId,_value, msg.sender, tokenType, addressofNFT),"g");

        // sellcount[tokenType] = sellcount[tokenType] + 1;

        seller[tokenType][a].index = a;
        seller[tokenType][a].tokenId = tokenId;
        seller[tokenType][a].status = true;
        seller[tokenType][a].price = price;
        seller[tokenType][a].paymentType = paymenttype;
        seller[tokenType][a].payment = payment[paymenttype];

        if(tokenType == 721){
            IERC721 token = IERC721(addressofNFT);
            require(token.ownerOf(tokenId) == msg.sender && _value == 0, "c");
            require(token.getApproved(tokenId) == address(this),"d");
            seller[tokenType][a].creater = token.ownerOf(tokenId);
            AuctionStatus[721][tokenId] = true;
            emit onsell(tokenId, a, seller[tokenType][a].creater);
            return true;
        }

        else{
            IERC1155 token = IERC1155(addressofNFT);
            require(tokenType == 1155,"asa");
            require(_value >=1,"daa");
            require(token.balanceOf(msg.sender,tokenId) >= _value, "f");
            require(token.isApprovedForAll(msg.sender,address(this)),"i");
            seller[tokenType][a].value = _value;
            seller[tokenType][a].total_value = _value;
            seller[tokenType][a].creater = msg.sender;
            emit onsell(tokenId, a, seller[tokenType][a].creater);
            return false;
        }

    }
    
    function buy(uint256 _sellcount,uint256 _tokenId, uint256 _tokenType, address addressofNFT,uint256 _value) public returns(bool){
        
        uint256 amount4;
        uint256 amount4owner;
        address owner;
        address creator;
        uint256 royality4creater;
        uint256 price = seller[_tokenType][_sellcount].price;
        uint256 f = _tokenId;
        uint256 s = _sellcount;
        IERC20 erc20 = IERC20(seller[_tokenType][s].payment);

        if(_tokenType == 721){
            require(_value==0);
            require(AuctionStatus[721][_tokenId]);
            require(seller[_tokenType][s].status, "j");
            require(erc20.allowance(msg.sender, address(this)) >= price, "o" );
            IERC721 token = IERC721(addressofNFT);
            erc20.transferFrom(msg.sender, address(this), price);

            uint256 royaltyrate = token.royalty(f);
            creator = token.createrof(f);
            royality4creater = (price).mul(royaltyrate).div(100);
            erc20.transfer(creator, royality4creater);

            owner = token.ownerOf(f);
            require(msg.sender != owner, "m");
            token.transferFrom(owner, msg.sender, f);
            amount4 =  (price).mul(commissionRate).div(100);
            amount4owner =  (price).sub(amount4.add(royality4creater));            
            
            
            erc20.transfer(seller[721][s].creater, amount4owner);
            
            AuctionStatus[721][f]= false;
            seller[721][s].status = false;
            seller[721][s].buyer = msg.sender;

            emit Sale(f,0, owner, msg.sender, price);
            emit Commission(f, owner, price, commissionRate, royality4creater, (price).mul(commissionRate).div(100));
            return true;
        }
        
        else{
            require(_tokenType == 1155);
            buy1155( s, f,  addressofNFT, _value);
            return true;
        }
        
    }
    
    function buy1155(uint256 _sellcount,uint256 _tokenId, address addressofNFT,uint256 _value)internal {
        
        uint256 s = _sellcount;
        uint256 f = _tokenId;
        uint256 h = _sellcount;
        uint256 v = _value;
        IERC1155 token = IERC1155(addressofNFT);
        IERC20 erc20 = IERC20(seller[1155][_sellcount].payment);
        address owner = seller[1155][s].creater;
        uint256 reming = seller[1155][s].value;
       
        require(reming >= _value,"n");
        require(msg.sender!=owner, "m");
        
        uint256 price4value = (seller[1155][s].price).mul(v);
        erc20.transferFrom(msg.sender, address(this),  price4value);

        address creator = token.creatoR(f);
        uint256 royaltyrate = token.royalty(f);
        uint256 royality4creater = (price4value).mul(royaltyrate).div(100);
        erc20.transfer(creator, royality4creater);
    
        token.safeTransferFrom(owner, msg.sender, f, v);
        uint256 amount4 =  (price4value).mul(commissionRate).div(100);
        uint256 amount4owner =  (price4value).sub(amount4.add(royality4creater));

        require(erc20.allowance(msg.sender, address(this)) >= price4value, "t" );

        erc20.transfer(owner, amount4owner);

        if(reming.sub(_value)==0){
            seller[1155][h].status = false;
            seller[1155][h].buyer = msg.sender;
        }
        seller[1155][h].value = reming.sub(v);
        
        emit Sale(f,v, owner, msg.sender, price4value);
        emit Commission(f, owner, price4value, commissionRate, royality4creater, amount4);
    }

    function createAuction(uint256 _tokenId, uint256 _value, uint56 closetime, uint256 _reservePrice, string memory _paymenttype, uint256 tokenType, address addressofNFT) public returns(bool){
        auctionCount[tokenType] = auctionCount[tokenType] + 1;
        uint256 f = _tokenId;
        uint256 a = auctionCount[tokenType];

        uint256 _startingTime = block.timestamp;
        uint256 _closingTime = _startingTime + closetime *  (1 minutes);

        require(payment[_paymenttype]!=address(0),"x");
        require(sellBidPrice[_tokenId]==0, "z");
        require(canSell(_tokenId,_value, msg.sender, tokenType, addressofNFT),"A");
        
        if(tokenType == 721){
            IERC721 token = IERC721(addressofNFT);
            require(token.ownerOf(_tokenId)==msg.sender, "uem");
            require(!AuctionStatus[721][_tokenId]);
            
            auctions[tokenType][a] = Auction({
                            index: a,
                            beneficiary: msg.sender,
                            auctionStart: _startingTime,
                            auctionEnd: _closingTime,
                            reserve: _reservePrice,
                            open: true,
                            value: 0,
                            highestBidder:address(0),
                            highestBid:0,
                            auctioncreater: msg.sender,
                            tokenId:_tokenId,
                            _name: _paymenttype,
                            payment: payment[_paymenttype]
                        });

            AuctionStatus[721][_tokenId] =true; 
            require(token.getApproved(_tokenId) == address(this),"y");
            emit onAuctioncreate(a, auctions[721][a].beneficiary, auctions[721][a].auctionStart, auctions[721][a].auctionEnd, auctions[721][a].reserve);
            return true;
        }
        else{
            require(tokenType == 1155);
            IERC1155 token = IERC1155(addressofNFT);

            require(token.balanceOf(msg.sender, f) >=_value, "B");
            
            auctions[1155][a] = Auction({
                            index: a,
                            beneficiary: msg.sender,
                            auctionStart: _startingTime,
                            auctionEnd: _closingTime,
                            reserve: _reservePrice.mul(_value),
                            open: true,
                            value: _value,
                            highestBidder:address(0),
                            highestBid:0,
                            auctioncreater: msg.sender,
                            tokenId: _tokenId,
                            _name: _paymenttype,
                            payment: payment[_paymenttype]
                        });

            AuctionStatus[tokenType][a] = true;
            require(token.isApprovedForAll(msg.sender,address(this)),"E");

            emit onAuctioncreate(a, auctions[1155][a].beneficiary, auctions[1155][a].auctionStart, auctions[1155][a].auctionEnd, auctions[1155][a].reserve);
            return true;
            }
    }

    function auctionFinalize(uint256 tokenId,uint256 _auctioncount,uint256 tokenType, address addressofNFT) public returns(bool){
        Localvariables memory localvariables;
        localvariables.tokenId = tokenId;
        localvariables.auctionid = _auctioncount;
        
        if(tokenType == 721){
            IERC721 token = IERC721(addressofNFT);
            require(msg.sender == auctions[721][_auctioncount].auctioncreater);
            require(token.getApproved(tokenId) == address(this),"G");
            require(AuctionStatus[tokenType][tokenId]);
            require(canFinalize(tokenId,_auctioncount, tokenType));
            require(auctions[721][_auctioncount].open, "H");
            require(block.timestamp >= auctions[721][_auctioncount].auctionEnd, "I");
            
            

            address highestBidder = auctions[721][_auctioncount].highestBidder;

            uint256 amount4admin = auctions[721][localvariables.auctionid].highestBid.mul(commissionRate).div(100);
            uint256 amount4owner = auctions[721][localvariables.auctionid].highestBid.sub(amount4admin);
            
            IERC20 c = IERC20(auctions[721][_auctioncount].payment);

            c.transfer(auctions[721][localvariables.auctionid].beneficiary, amount4owner);

            emit Sale(localvariables.tokenId, 0,auctions[721][localvariables.auctionid].beneficiary, highestBidder, auctions[721][localvariables.auctionid].highestBid);
            emit Commission(localvariables.tokenId, auctions[721][localvariables.auctionid].beneficiary, auctions[721][localvariables.auctionid].highestBid, commissionRate, amount4owner, amount4admin);

            emit AuctionEnded(auctions[721][localvariables.auctionid].highestBidder, auctions[721][localvariables.auctionid].highestBid);

            token.transferFrom(token.ownerOf(localvariables.tokenId), highestBidder, auctions[721][localvariables.auctionid].tokenId);

            soldFor[localvariables.tokenId] = auctions[721][localvariables.auctionid].highestBid;
            // payment_type[_auctionID] = address(0);
            AuctionStatus[tokenType][localvariables.tokenId]= false;
            auctions[721][localvariables.auctionid].open = false;

            return true;
        }
        else{
            return ineraction(tokenId, _auctioncount, tokenType,  addressofNFT);
            
        }
            
    }
    function ineraction(uint256 tokenId,uint256 _auctioncount,uint256 tokenType, address addressofNFT)internal returns(bool){
        require(tokenType == 1155);
        uint256 a = tokenId;
        uint256 b = _auctioncount;
        IERC1155 token = IERC1155(addressofNFT);
        require(auctions[1155][_auctioncount].auctioncreater == msg.sender);
        require(auctions[tokenType][_auctioncount].open, "K");
        
        require(block.timestamp >= auctions[1155][_auctioncount].auctionEnd, "L");

        // transfer the ownership of token to the highest bidder
        address highestBidder = auctions[1155][_auctioncount].highestBidder;
        // address creator = token.creatoR(tokenId);
        // uint256 royaltyrate = token.royalty(tokenId);

        uint256 amount4admin = auctions[1155][b].highestBid.mul(commissionRate).div(100);
        
        uint256 amount4owner = auctions[1155][b].highestBid.sub(amount4admin);
        
        IERC20 c = IERC20(auctions[1155][b].payment);
        c.transfer(auctions[1155][b].beneficiary, amount4owner);
        
        uint256 v = auctions[1155][b].value;
        require(token.isApprovedForAll(auctions[1155][b].auctioncreater,address(this)),"N");
        token.safeTransferFrom(auctions[1155][b].auctioncreater, highestBidder,a, v);
        auctions[1155][_auctioncount].open = false;
        emit Sale(_auctioncount,auctions[1155][b].value ,auctions[1155][b].beneficiary, highestBidder, auctions[1155][b].highestBid);
        emit Commission(b, auctions[1155][b].beneficiary, auctions[1155][b].highestBid, commissionRate, amount4admin, amount4admin);
        emit AuctionEnded(auctions[1155][b].highestBidder, auctions[1155][b].highestBid);
        
        return true;
    }
    //bid
    function bid(uint256 tokenId,uint256 _auctioncount, uint256 price, uint256 tokenType, address addressofNFT) public returns(bool) {
    
        require(block.timestamp <= auctions[tokenType][_auctioncount].auctionEnd, "X");
        require(canBid(tokenId,_auctioncount, tokenType, addressofNFT));
        require(!msg.sender.isContract(), "Y");
        require(auctions[tokenType][_auctioncount].open, "Z");
        require(block.timestamp >= auctions[tokenType][_auctioncount].auctionStart, "S");
        require(block.timestamp <= auctions[tokenType][_auctioncount].auctionEnd, "T");
        require(price > auctions[tokenType][_auctioncount].highestBid,"U");
        require(auctions[tokenType][_auctioncount].open,"v");
        require(auctions[tokenType][_auctioncount].auctioncreater != msg.sender,"not auctioncreater");
        
        if(tokenType == 721){
            require(price >= auctions[721][_auctioncount].reserve, "J");
            IERC721 token = IERC721(addressofNFT);
            IERC20 erc20 = IERC20(auctions[tokenType][_auctioncount].payment);
            uint256 d = tokenId;
            uint256 _a = _auctioncount;
            address owner = token.ownerOf(tokenId);
            require(token.getApproved(tokenId) == address(this),"R");
            require(msg.sender!=owner, "V");
            require(erc20.balanceOf(msg.sender) >= price, "O");
            require(erc20.allowance(msg.sender, address(this)) >= price, "W");
            erc20.transferFrom(msg.sender, address(this), price);
            
            uint256 royaltyrate = token.royalty(tokenId);
            address creator = token.createrof(tokenId);
            uint256 royality4creater = (price).mul(royaltyrate).div(100);
            erc20.transfer(creator, royality4creater);

            if (auctions[tokenType][_auctioncount].highestBid>0) {
                erc20.transfer(auctions[tokenType][_a].highestBidder, auctions[tokenType][_a].highestBid);
                emit Refund(auctions[tokenType][_auctioncount].highestBidder,auctions[tokenType][_a].highestBid);
            }

            auctions[tokenType][_auctioncount].highestBidder = msg.sender;
            auctions[tokenType][_auctioncount].highestBid = price.sub(royality4creater);

            emit HighestBidIncreased(msg.sender, price, d);
            return true;
        }
        else{
            require(tokenType == 1155);
            require(price > auctions[1155][_auctioncount].reserve, "J");
            IERC1155 token = IERC1155(addressofNFT);
            uint256 f = tokenId;
            uint256 a = _auctioncount;
            address owner = auctions[tokenType][_auctioncount].beneficiary;
            require(msg.sender!=owner, "dd");
            // 1155 contract appovel
            require(token.isApprovedForAll(owner,address(this)),"ee");
            
            IERC20 erc20 = IERC20(auctions[tokenType][_auctioncount].payment);
            require(erc20.balanceOf(msg.sender) >= price, "O");
            require(erc20.allowance(msg.sender, address(this)) >= price, "ff");
            erc20.transferFrom(msg.sender, address(this), price);

            address creator = token.creatoR(f);
            uint256 royaltyrate = token.royalty(f);
            uint256 royality4creater = (price).mul(royaltyrate).div(100);
            erc20.transfer(creator, royality4creater);


            if (auctions[tokenType][_auctioncount].highestBid>0) {
                erc20.transfer(auctions[tokenType][a].highestBidder, auctions[tokenType][a].highestBid);
                emit Refund(auctions[tokenType][_auctioncount].highestBidder, auctions[tokenType][a].highestBid);
            }

            auctions[tokenType][_auctioncount].highestBidder = msg.sender;
            auctions[tokenType][_auctioncount].highestBid = price.sub(royality4creater);

            emit HighestBidIncreased(msg.sender, price, _auctioncount);
            return true;
            }
    }
                    

    

    //can sell
    function canSell(uint256 tokenId,uint256 _value,address _from, uint256 tokenType, address addressofNFT)public view returns (bool){
        uint256 sellcountT = sellcount[tokenType];
        uint256 auctioncounT = auctionCount[tokenType];
        if(tokenType == 721){
            require(!AuctionStatus[tokenType][tokenId]);
            return true;
        }

        else{
            require(tokenType == 1155);
            IERC1155 token = IERC1155(addressofNFT);
            uint256 value;
            uint256 f = token.balanceOf(msg.sender,tokenId);
            for(uint256 i=0; i< auctioncounT; i++){
                if(auctions[1155][i+1].open && auctions[1155][i+1].tokenId ==tokenId  && auctions[1155][i+1].beneficiary == _from){
                value += auctions[1155][i+1].value;
                }
            }
            for(uint256 i=0; i< sellcountT; i++){
                if(seller[tokenType][i+1].status && seller[tokenType][i+1].creater == _from && seller[tokenType][i+1].tokenId == tokenId){
                    value +=  seller[tokenType][i+1].value;
                }
            }
            
            if(f >= value+_value){
                return true;
            }
            else{
                return false;
            }
        }
    }

    function canBid(uint256 tokenId,uint256 _auctioncount, uint256 tokenType, address addressofNFT) public view returns (bool) {
        require(!address(msg.sender).isContract() && 
                auctions[tokenType][_auctioncount].open && 
                block.timestamp >= auctions[tokenType][_auctioncount].auctionStart &&
                block.timestamp <= auctions[tokenType][_auctioncount].auctionEnd, "gg");

        if(tokenType == 721){
            IERC721 token = IERC721(addressofNFT);
            require(AuctionStatus[tokenType][tokenId]);
            
            if ( 
                token.getApproved(tokenId) == address(this)
            ) {
                return true;
            } else {
                return false;
            }
        }

        else{
            require(tokenType == 1155);
            IERC1155 token = IERC1155(addressofNFT);
            address owner = auctions[1155][_auctioncount].beneficiary;
            if (token.isApprovedForAll(owner,address(this)))
                {
                    return true;
                } else {
                    return false;
            }
        }
        
    }

    function canFinalize(uint256 tokenId,uint256 _auctioncount, uint256 tokenType) public view returns (bool) {    
        require(auctions[tokenType][_auctioncount].tokenId == tokenId);
        if (auctions[tokenType][_auctioncount].open && 
            block.timestamp >= auctions[tokenType][_auctioncount].auctionEnd
            ) {
                return true;
            } else {
                return false;
            }
    }
   

    function removeAuction(uint56 _auctioncount,  uint256 tokenType) public returns(bool success){

        // auction has to be opened
        uint256 tokenId = auctions[tokenType][_auctioncount].tokenId;
        require(auctions[tokenType][_auctioncount].open, "hh");
        require(auctions[tokenType][_auctioncount].beneficiary == msg.sender);
        IERC20 erc20 = IERC20(auctions[tokenType][_auctioncount].payment);
        // return the funds to the previous bidder, if there is one
        if (auctions[tokenType][_auctioncount].highestBid>0) {
            erc20.transfer(auctions[tokenType][_auctioncount].highestBidder, auctions[tokenType][_auctioncount].highestBid);
            emit Refund(auctions[tokenType][_auctioncount].highestBidder, auctions[tokenType][_auctioncount].highestBid);
        }
        if(tokenType == 721){
            AuctionStatus[721][tokenId] = false;
        }
        auctions[tokenType][_auctioncount].open = false;
        emit AuctionClosed(_auctioncount);
        return true;
    }

    function removeSell(uint256 tokenId,uint256 _sellcount, uint256 tokenType) public returns(bool success){
        // is on sale
        require(seller[tokenType][_sellcount].status);
        require(seller[tokenType][_sellcount].creater == msg.sender || msg.sender == owner(),"is not created");
        seller[tokenType][_sellcount].status = false;
        if(tokenType ==721){
            require(AuctionStatus[721][tokenId],"nfs");
            AuctionStatus[721][tokenId] = false;
        }
        seller[tokenType][_sellcount].status = false;
        return true;
    }

    function withdrawToken(string memory paymentType, address _address) public onlyOwner returns(bool){
        IERC20 erc20 = IERC20(payment[paymentType]);
        erc20.transfer(_address, erc20.balanceOf(address(this)));
        return true;
    }
    function getdata(uint256 tokenType)public view returns(uint256[] memory,uint256[] memory){
        uint256 s;
        uint256 _a;
        
        for(uint256 i=0;i<sellcount[tokenType];i++){
            if(seller[tokenType][i+1].status){
                s=s+1;
            }
        }
        for(uint256 i=0;i<auctionCount[tokenType];i++){
            if(auctions[tokenType][i+1].open){
                _a = _a+1;
            }
        }
        uint256[] memory a = new uint256[](s) ;
        uint256[] memory b = new uint256[](_a);
        for(uint256 i=0;i<sellcount[tokenType];i++){
            if(seller[tokenType][i+1].status){
                a[s-1] = seller[tokenType][i+1].index;
            }
        }
        for(uint256 i=0;i<auctionCount[tokenType];i++){
            if(auctions[tokenType][i+1].open){
                b[_a-1] = auctions[tokenType][i+1].index;
                
            }
        }
        return (a,b);
    }
}