// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
    ) external ;
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */

interface IpropertyToken {
    function PropertysafeMint(address to, uint256 tokenId) external;

    function PropertyisApprovedOrOwner(address _spender , uint256 _tokenid) external view returns(bool);

    function transferFrom(address from,address to,uint256 tokenId) external;

    function PropertysetBaseUrl(uint256 tokenId, string memory baseURI) external;
     
}

interface IticketToken {
    function safeMint(address to, uint256 tokenId) external;
    
    function isApprovedOrOwner(address _spender , uint256 _tokenid) external view returns(bool);

    function transferFrom(address from,address to,uint256 tokenId) external;

     function setBaseUrl(uint256 tokenId, string memory baseURI) external;

}


contract RealEstate {

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    struct Property {
        uint256 id;
        address currentOwner;
        string fullName;
        string phoneNumber;
        uint256 price;
        string details;
        string houseAddress;
        string pictures;
        bool isAgency;
    }

    uint256 public propertyId;
    address public owner;

    IERC20 public USDT;
    IpropertyToken public propertyToken;
    IticketToken public ticketToken;
    
    mapping(uint256 => Property) public properties;
    mapping(uint256 => bool) public isPending;
    mapping(uint256 => bool) public isApproved;
    mapping(uint256 => bool) public isRejected;
    mapping(uint256 => string) public rejectedReason;
    mapping(uint256 => bool) public isTicketCreated;
    mapping(uint256 => bool) public isOnSell;
    mapping(uint256 => uint256) public tokenEndingTime;

    constructor(address _owner,address _usdt , address _propertyToken , address _ticket) {
        USDT = IERC20(_usdt);
        propertyToken = IpropertyToken(_propertyToken);
        ticketToken = IticketToken(_ticket);
        owner = _owner;
    }

    function addProperty( 
            string memory _fullName,
            string memory _phoneNumber,
            uint256 _price,
            string memory _details,
            string memory _houseAddress,
            string memory _picture,
            bool _isAgency
        ) public {
        propertyId++;
        properties[propertyId] = Property(
            propertyId,
            msg.sender,
            _fullName,
            _phoneNumber,
            _price,
            _details,
            _houseAddress,
            _picture,
            _isAgency
            );
        isPending[propertyId] = true;
    }  

    function approveProperty(uint256 _propertyId) public onlyOwner {
        propertyToken.PropertysafeMint(properties[_propertyId].currentOwner , _propertyId);
        isPending[_propertyId] = false;
        isApproved[_propertyId] = true;
    } 

    function rejectProperty(uint256 _propertyId , string memory _reason) public onlyOwner {
        rejectedReason[_propertyId] = _reason;
        isPending[_propertyId] = false;
        isRejected[_propertyId] = true;

        // properties[_propertyId] = Property(  0,address(0),"","",0,"","","",false);
        // delete properties[_propertyId];
    } 

    function updateProperty(
            uint256 _propertyId,
            string memory _fullName,
            string memory _phoneNumber,
            uint256 _price,
            string memory _details,
            string memory _houseAddress,
            string memory _picture
        ) public {

        require(msg.sender == properties[_propertyId].currentOwner,"you are not the owner of this property");
        properties[_propertyId] = Property(
            _propertyId,
            properties[_propertyId].currentOwner,
            _fullName,
            _phoneNumber,
            _price,
            _details,
            _houseAddress,
            _picture,
            true
            );
        isPending[_propertyId] = true;
        rejectedReason[_propertyId] = "";
        isRejected[_propertyId] = false;
    }  


    function createTicket(uint256 _propertyId , string memory _url) public {
        require(properties[_propertyId].currentOwner == msg.sender , "!owner");

        ticketToken.safeMint(properties[_propertyId].currentOwner , _propertyId);
        ticketToken.setBaseUrl(_propertyId , _url);

        isTicketCreated[_propertyId] = true;
        tokenEndingTime[_propertyId] = block.timestamp + 1209600; //  2 weeks
    }  
    

    function putOnSell(uint256 _propertyId) public {
        require(properties[_propertyId].currentOwner == msg.sender);
        require(isTicketCreated[_propertyId] , "Ticket Not Created");

        require(propertyToken.PropertyisApprovedOrOwner(address(this), _propertyId) , "Please Approve propertyToken to smart Contract Address");
        require(ticketToken.isApprovedOrOwner(address(this), _propertyId) , "Please Approve ticketToken to smart Contract Address");
        
        propertyToken.transferFrom(msg.sender,address(this), _propertyId);
        ticketToken.transferFrom(msg.sender,address(this), _propertyId);
        isOnSell[_propertyId] = true;

    }

}