/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

interface IERC20 {
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function balanceOf(address _account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from,address _to,uint256 _amount) external returns (bool);
}


interface ICFC {
    function addFees(uint256 _amount, bool _isCHD) external;
}



/**
 @title Token
 @dev base ERC20 to act as token underlying CHD and pool tokens
 */
contract Token{

    /*Storage*/
    string  private tokenName;
    string  private tokenSymbol;
    uint256 internal supply;//totalSupply
    mapping(address => uint) balance;
    mapping(address => mapping(address=>uint)) userAllowance;//allowance

    /*Events*/
    event Approval(address indexed _src, address indexed _dst, uint _amt);
    event Transfer(address indexed _src, address indexed _dst, uint _amt);

    /*Functions*/
    /**
     * @dev Constructor to initialize token
     * @param _name of token
     * @param _symbol of token
     */
    constructor(string memory _name, string memory _symbol){
        tokenName = _name;
        tokenSymbol = _symbol;
    }

    /**
     * @dev allows a user to approve a spender of their tokens
     * @param _spender address of party granting approval
     * @param _amount amount of tokens to allow spender access
     */
    function approve(address _spender, uint256 _amount) external returns (bool) {
        userAllowance[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /**
     * @dev function to transfer tokens
     * @param _to destination of tokens
     * @param _amount of tokens
     */
    function transfer(address _to, uint256 _amount) external returns (bool) {
        _move(msg.sender, _to, _amount);
        return true;
    }

    /**
     * @dev allows a party to transfer tokens from an approved address
     * @param _from address source of tokens 
     * @param _to address destination of tokens
     * @param _amount uint256 amount of tokens
     */
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool) {
        require(msg.sender == _from || _amount <= userAllowance[_from][msg.sender], "not approved");
        _move(_from,_to,_amount);
        if (msg.sender != _from) {
            userAllowance[_from][msg.sender] = userAllowance[_from][msg.sender] -  _amount;
            emit Approval(_from, msg.sender, userAllowance[_from][msg.sender]);
        }
        return true;
    }

    //Getters
    /**
     * @dev retrieves standard token allowance
     * @param _src user who owns tokens
     * @param _dst spender (destination) of these tokens
     * @return uint256 allowance
     */
    function allowance(address _src, address _dst) external view returns (uint256) {
        return userAllowance[_src][_dst];
    }

    /**
     * @dev retrieves balance of token holder
     * @param _user address of token holder
     * @return uint256 balance of tokens
     */
    function balanceOf(address _user) external view returns (uint256) {
        return balance[_user];
    }
    
    /**
     * @dev retrieves token number of decimals
     * @return uint8 number of decimals (18 standard)
     */
    function decimals() external pure returns(uint8) {
        return 18;
    }

    /**
     * @dev retrieves name of token
     * @return string token name
     */
    function name() external view returns (string memory) {
        return tokenName;
    }

    /**
     * @dev retrieves symbol of token
     * @return string token sybmol
     */
    function symbol() external view returns (string memory) {
        return tokenSymbol;
    }

    /**
     * @dev retrieves totalSupply of token
     * @return amount of token
     */
    function totalSupply() external view returns (uint256) {
        return supply;
    }

    /**Internal Functions */
    /**
     * @dev burns tokens
     * @param _from address to burn tokens from
     * @param _amount amount of token to burn
     */
    function _burn(address _from, uint256 _amount) internal {
        balance[_from] = balance[_from] - _amount;//will overflow if too big
        supply = supply - _amount;
        emit Transfer(_from, address(0), _amount);
    }
    
    /**
     * @dev mints tokens
     * @param _to address of recipient
     * @param _amount amount of token to send
     */
    function _mint(address _to,uint256 _amount) internal {
        balance[_to] = balance[_to] + _amount;
        supply = supply + _amount;
        emit Transfer(address(0), _to, _amount);
    }

    /**
     * @dev moves tokens from one address to another
     * @param _src address of sender
     * @param _dst address of recipient
     * @param _amount amount of token to send
     */
    function _move(address _src, address _dst, uint256 _amount) internal {
        balance[_src] = balance[_src] - _amount;//will overflow if too big
        balance[_dst] = balance[_dst] + _amount;
        emit Transfer(_src, _dst, _amount);
    }
}

/**
 @title Auction
 @dev charon incentive token (CIT), a token with an auction for minting
 */
contract Auction is Token{

    ICFC public charonFeeContract;
    IERC20 public bidToken;
    uint256 public auctionFrequency;//auction frequency in seconds
    uint256 public mintAmount;//mint amount CIT per auction round

    //bid variables
    uint256 public currentTopBid;
    uint256 public endDate;//end date of current auction round
    address public topBidder;

    //events
    event AuctionClosed(address _winner, uint256 _amount);
    event NewAuctionStarted(uint256 _endDate);
    event NewTopBid(address _bidder, uint256 _amount);


    /**
     * @dev starts the CIT token and auction (minting) mechanism
     * @param _bidToken token to be used 
     * @param _mintAmount amount of tokens to mint each auction
     * @param _auctionFrequency time between auctions (e.g. 86400 = daily)
     * @param _cfc address of charon fee contract for passing auction proceeds
     * @param _name string name of CIT token
     * @param _symbol string symbol of CIT token
     */
    constructor(address _bidToken,
                uint256 _mintAmount,
                uint256 _auctionFrequency,
                address _cfc,
                string memory _name,
                string memory _symbol) Token(_name,_symbol){
        bidToken = IERC20(_bidToken);
        mintAmount = _mintAmount;
        auctionFrequency = _auctionFrequency;
        charonFeeContract = ICFC(_cfc);
        endDate = block.timestamp + _auctionFrequency;
        _mint(msg.sender,_mintAmount);
    }

    /**
     * @dev allows a user to bid on the mintAmount of CIT tokens
     * @param _amount amount of your bid
     */
    function bid(uint256 _amount) external{
        require(block.timestamp < endDate, "auction must be ongoing");
        require(_amount > currentTopBid, "must be top bid");
        require(bidToken.transferFrom(msg.sender,address(this),_amount), "must get tokens");
        if(currentTopBid > 0){
            require(bidToken.transfer(topBidder,currentTopBid), "must send back tokens");
        }
        topBidder = msg.sender;
        currentTopBid = _amount;
        emit NewTopBid(msg.sender, _amount);
    }

    /**
     * @dev pays out the winner of the auction and starts a new one
     */
    function startNewAuction() external{
        require(block.timestamp >= endDate, "auction must be over");
        _mint(topBidder, mintAmount);
        if(currentTopBid > 0){
            bidToken.approve(address(charonFeeContract), currentTopBid);
            charonFeeContract.addFees(currentTopBid,false);
        }
        emit AuctionClosed(topBidder, currentTopBid);
        endDate = block.timestamp + auctionFrequency; // just restart it...
        topBidder = msg.sender;
        currentTopBid = 0;
        emit NewTopBid(msg.sender, 0);
    }
}