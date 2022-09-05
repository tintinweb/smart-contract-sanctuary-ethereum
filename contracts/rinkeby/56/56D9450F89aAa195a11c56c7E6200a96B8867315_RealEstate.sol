// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// __________                    .___.__               _________         _____   __
// \______   \_____  __  _  __ __| _/|__|  ____       /   _____/  ____ _/ ____\_/  |_
//  |    |  _/\__  \ \ \/ \/ // __ | |  |_/ ___\      \_____  \  /  _ \\   __\ \   __\
//  |    |   \ / __ \_\     // /_/ | |  |\  \___      /        \(  <_> )|  |    |  |
//  |______  /(____  / \/\_/ \____ | |__| \___  >    /_______  / \____/ |__|    |__|
//         \/      \/             \/          \/             \/
// BawdicSoft.com

import "./interfaces/IUSDT.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/ITT721.sol";
import "./interfaces/INFTilityExchange.sol";
import "./access/Ownable.sol";

import "./openzepplin/contracts/security/Pausable.sol";
import "./openzepplin/contracts/utils/Counters.sol";
import "./openzepplin/contracts/utils/math/SafeMath.sol";
import "./openzepplin/contracts/token/ERC20/IERC20.sol";

contract RealEstate is Pausable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _propertyIdCounter;

    uint256 public sellerAgencyFee = 3; //in persent
    uint256 public sellerIndividualFee = 6; //in persent
    uint256 public TicketTokenPrice = 5000000000; //fixed price

    IUSDT public immutable USDT;
    ITT721 public immutable TICKET_TOKEN;
    IERC721 public immutable PROPERTY_TOKEN;

    IERC20 public NNT;
    INFTilityExchange private ExchangeHandler;

    constructor(
        address _USDT,
        address _NNT,
        address _TICKET_TOKEN,
        address _PROPERTY_TOKEN,
        address _EXCHANGE_HANDLER
    ) {
        USDT = IUSDT(_USDT);
        NNT = IERC20(_NNT);
        TICKET_TOKEN = ITT721(_TICKET_TOKEN);
        PROPERTY_TOKEN = IERC721(_PROPERTY_TOKEN);
        ExchangeHandler = INFTilityExchange(_EXCHANGE_HANDLER);
    }

    enum Tokens {
        USDT,
        NNT
    }

    /*************************************************
     *                      modifier
     **************************************************/

    modifier onlyOwner(uint256 _propertyId) {
        require(properties[_propertyId].currentOwner == _msgSender(), "!Owner");
        _;
    }

    /*************************************************
     *                      Struct
     **************************************************/

    struct _property {
        uint256 id;
        uint256 price;
        uint256 amountP;
        uint256 folioNumber;
        bool isAgency;
        string fullName;
        string phoneNumber;
        string details;
        string houseAddress;
        string pictures;
        address currentOwner;
    }

    struct _buyerInfo {
        address buyerAddress;
        string fullName;
        string phoneNumber;
    }

    /*************************************************
     *                      Mapping
     **************************************************/

    mapping(uint256 => _property) public properties;
    mapping(uint256 => bool) public isPending;
    mapping(uint256 => bool) public isApproved;
    mapping(uint256 => bool) public isRejected;
    mapping(uint256 => string) public rejectedReason;
    mapping(uint256 => bool) public isTicketCreated;
    mapping(uint256 => bool) public isOnSell;

    mapping(uint256 => _buyerInfo) public buyerInfo;
    mapping(uint256 => bool) public PropertyPricePaid;
    mapping(uint256 => bool) public DealAccepted;
    mapping(uint256 => bool) public DealRejected;
    mapping(uint256 => string) public DealRejectedReason;

    /*************************************************
     *                  view function
     **************************************************/

    function PropertyID() public view returns (uint256 _propertyId) {
        _propertyId = _propertyIdCounter.current();
    }

    function getRejectedReasons(uint256 _propertyId)
        public
        view
        returns (string memory Reasons)
    {
        Reasons = rejectedReason[_propertyId];
    }

    function getProperties(uint256 _propertyId) public view returns (
            uint256 id, uint256 _price, uint256 _folioNumber, bool _isAgency,
            string memory _fullName, string memory _phoneNumber, string memory _details, 
            string memory _houseAddress, string memory _pictures, address _currentOwner
        )
    {
        id = properties[_propertyId].id;
        _price = properties[_propertyId].price;
        _folioNumber = properties[_propertyId].folioNumber;
        _isAgency = properties[_propertyId].isAgency;
        _fullName = properties[_propertyId].fullName;
        _phoneNumber = properties[_propertyId].phoneNumber;
        _details = properties[_propertyId].details;
        _houseAddress = properties[_propertyId].houseAddress;
        _pictures = properties[_propertyId].pictures;
        _currentOwner = properties[_propertyId].currentOwner;
    }

    function getPropertyDetails(uint256 _propertyId)
        public
        view
        returns (
            bool _isTicketRequestedForSell,
            bool _isPending,
            bool _isApproved,
            bool _isRejected,
            bool _isTicketCreated,
            bool _isOnSell,
            string memory _rejectedReason,
            bool _DealAccepted,
            bool _DealRejected,
            string memory _DealRejectedReason
        )
    {
        _isTicketRequestedForSell = isTicketRequestForSell[_propertyId];
        _isPending = isPending[_propertyId];
        _isApproved = isApproved[_propertyId];
        _isRejected = isRejected[_propertyId];
        _isTicketCreated = isTicketCreated[_propertyId];
        _isOnSell = isOnSell[_propertyId];
        _rejectedReason = rejectedReason[_propertyId];
        _DealAccepted = DealAccepted[_propertyId];
        _DealRejected = DealRejected[_propertyId];
        _DealRejectedReason = DealRejectedReason[_propertyId];
    }

    function getBuyerInfo(uint256 _propertyId)
        public
        view
        returns (
            address _buyerAddress,
            string memory _fullName,
            string memory _phoneNumber,
            uint256 _endAt,
            uint256 _now
        )
    {
        _buyerAddress = buyerInfo[_propertyId].buyerAddress;
        _fullName = buyerInfo[_propertyId].fullName;
        _phoneNumber = buyerInfo[_propertyId].phoneNumber;
        _endAt = TICKET_TOKEN.TokenTransferTimestamp(properties[_propertyId].folioNumber).add(1209600);
        _now = block.timestamp;
    }

    /*************************************************
     *                  addProperty
     **************************************************/

    mapping(uint256 => uint256) public property2percentlegalcut;

    function addProperty(
        uint256 _price, uint256 _folioNumber, bool _isAgency, string memory _fullName,
        string memory _phoneNumber, string memory _details, string memory _houseAddress, string memory _pictures
    ) public {
        _propertyIdCounter.increment();
        uint256 propertyId = _propertyIdCounter.current();

        // adding 2% fee for platform buyer have to pay this.
        uint256 percent2 = (_price * 2) / 100;

        properties[propertyId] = _property (
            propertyId, _price, percent2, _folioNumber, _isAgency,
            _fullName, _phoneNumber, _details, _houseAddress,
            _pictures, _msgSender()
        );

        isPending[propertyId] = true;
    }

    function updateProperty(
        uint256 _propertyId, uint256 _price, bool _isAgency, string memory _fullName,
        string memory _phoneNumber, string memory _details, string memory _houseAddress, string memory _pictures
    ) public onlyOwner(_propertyId) {
        require(!isOnSell[_propertyId], "Property was OnSell");

        // adding 2% fee for platform buyer have to pay this.
        uint256 percent2 = (_price * 2) / 100;

        properties[_propertyId] = _property(
            _propertyId, (_price + percent2), _price, properties[_propertyId].folioNumber, _isAgency,
            _fullName, _phoneNumber, _details, _houseAddress, _pictures,
            _msgSender()
        );

        isPending[_propertyId] = true;
        isRejected[_propertyId] = false;
    }

    /*************************************************
     *            approve or reject Property
     **************************************************/

    function approveProperty(uint256 _propertyId) public onlyAgency {
        require(!isRejected[_propertyId], "Already Rejected");

        PROPERTY_TOKEN.safeMint(
            properties[_propertyId].currentOwner,
            properties[_propertyId].folioNumber
        );

        isPending[_propertyId] = false;
        isApproved[_propertyId] = true;
    }

    function rejectProperty(uint256 _propertyId, string memory _reason)
        public
        onlyAgency
    {
        require(!isApproved[_propertyId], "Already Approved");

        rejectedReason[_propertyId] = _reason;
        isPending[_propertyId] = false;
        isRejected[_propertyId] = true;
    }

    /*************************************************
     *             Request for Ticket
     **************************************************/

    mapping(uint256 => bool) public isTicketRequestForSell;
    mapping(uint256 => string) public MetaHashForProperty;

    function requestForTicket( uint256 _propertyId, string memory _metaHashForProperty) 
    public onlyOwner(_propertyId) {
        require(isApproved[_propertyId], "!Approved");
        require(!isTicketRequestForSell[_propertyId], "!Request");

        MetaHashForProperty[_propertyId] = _metaHashForProperty;

        burnTimer[properties[_propertyId].folioNumber] = burnTime;

        PROPERTY_TOKEN.transferFrom(
            msg.sender,
            address(this),
            properties[_propertyId].folioNumber
        );
        
        isTicketRequestForSell[_propertyId] = true;
    }

    /*************************************************
     *                   createTicket
     **************************************************/

    function createTicket(uint256 _propertyId) public onlyAgency {
        require(isTicketRequestForSell[_propertyId], "!isTicketRequestForSell");

        uint256 _folioNumber = properties[_propertyId].folioNumber;

        TICKET_TOKEN.safeMint(
            // properties[_propertyId].currentOwner,
            msg.sender,
            _folioNumber
        );

        TICKET_TOKEN.setBaseUrl(_folioNumber, MetaHashForProperty[_propertyId]);
        TICKET_TOKEN.approveToSmartContract(address(this), _folioNumber);

        isTicketRequestForSell[_propertyId] = false;
        isTicketCreated[_propertyId] = true;
        isOnSell[_propertyId] = true;
    }

    /*************************************************
     *                     buy functions
     **************************************************/

    function buyTicketToken(uint256 _propertyId, uint256 amount_, Tokens token_) public {

        require(isOnSell[_propertyId], "not on sell");

        uint256 _folioNumber = properties[_propertyId].folioNumber;
        require( TICKET_TOKEN.ownerOf(_folioNumber) == agency(), "!owner property token" );
        require( PROPERTY_TOKEN.ownerOf(_folioNumber) == address(this), "!owner property token" );

        if (token_ == Tokens.USDT) {

            require(TicketTokenPrice == amount_, "not valid usdt");
            require( USDT.allowance(msg.sender, address(this)) >= amount_, "!approved usdt" );

            USDT.transferFrom(_msgSender(), agency(), amount_.mul(80).div(100));
            USDT.transferFrom( _msgSender(), properties[_propertyId].currentOwner, amount_.mul(20).div(100) );

        }

        if (token_ == Tokens.NNT) {
            uint256 TicketTokenPrice_ = ExchangeHandler.priceCalculatorUSDTtoNNT(TicketTokenPrice);

            require(TicketTokenPrice_ == amount_, "not valid NNT");
            require( NNT.allowance(msg.sender, address(this)) >= amount_, "!approved NNT" );

            NNT.transferFrom(_msgSender(), agency(), amount_.mul(80).div(100));
            NNT.transferFrom( _msgSender(), properties[_propertyId].currentOwner, amount_.mul(20).div(100) );

        }

        TICKET_TOKEN.safeTransferFrom(agency(), _msgSender(), _folioNumber);

        isOnSell[_propertyId] = false;
    }

    mapping(uint256 => Tokens) public paidIn;

    function buyPropertyToken( uint256 _propertyId, string memory fullName, string memory phoneNumber, uint256 amount_, Tokens token_) public {

        require(TICKET_TOKEN.ownerOf(properties[_propertyId].folioNumber) == _msgSender(), "!Owner" );
        require(
            TICKET_TOKEN.TokenTransferTimestamp(properties[_propertyId].folioNumber)
            .add(burnTimer[properties[_propertyId].folioNumber]) >=
                block.timestamp,
            "timeout"
        );

        if (token_ == Tokens.USDT) {
            paidIn[_propertyId] = token_;

            require(properties[_propertyId].price == amount_, "not valid usdt");

            USDT.transferFrom( _msgSender(), address(this), properties[_propertyId].price );

            PropertyPricePaid[_propertyId] = true;
            isOnSell[_propertyId] = false;

            buyerInfo[_propertyId] = _buyerInfo( msg.sender, fullName, phoneNumber );
        }

        if (token_ == Tokens.NNT) {
            paidIn[_propertyId] = token_;

            uint256 PriceExchange_ = ExchangeHandler.priceCalculatorUSDTtoNNT(properties[_propertyId].price);
            require(PriceExchange_ == amount_, "not valid NNT");

            NNT.transferFrom( _msgSender(), address(this), PriceExchange_);

            PropertyPricePaid[_propertyId] = true;
            isOnSell[_propertyId] = false;

            buyerInfo[_propertyId] = _buyerInfo( msg.sender, fullName, phoneNumber );
        }
    }

    /*************************************************
     *              accept deal functions
     *************************************************/

    function acceptingDeal(uint256 _propertyId) public onlyAgency {
        require(PropertyPricePaid[_propertyId], "!paid");
        require(!DealAccepted[_propertyId], "Deal Already Accepted");
        

        if (properties[_propertyId].isAgency == true) {

            if (paidIn[_propertyId] == Tokens.USDT) {

                uint256 _fee = (properties[_propertyId].price * (sellerAgencyFee)) / 100;
                _fee = properties[_propertyId].amountP + _fee;
                uint256 _transferPropertyOwner = properties[_propertyId].price - _fee;

                USDT.transfer(agency(), _fee);
                USDT.transfer( properties[_propertyId].currentOwner, _transferPropertyOwner );

            } else if (paidIn[_propertyId] == Tokens.NNT) {
                
                uint256 _fee = (properties[_propertyId].price * (sellerAgencyFee)) / 100;
                _fee = properties[_propertyId].amountP + _fee;
                uint256 _transferPropertyOwner = properties[_propertyId].price - _fee;

                _fee = ExchangeHandler.priceCalculatorUSDTtoNNT(_fee);
                _transferPropertyOwner = ExchangeHandler.priceCalculatorUSDTtoNNT(_transferPropertyOwner);

                NNT.transfer(agency(), _fee);
                NNT.transfer( properties[_propertyId].currentOwner, _transferPropertyOwner );

            }

        } else {

           if (paidIn[_propertyId] == Tokens.USDT) {

                uint256 _fee = (properties[_propertyId].price * (sellerIndividualFee)) / 100;
                _fee = properties[_propertyId].amountP + _fee;
                uint256 _propertyOwnerEth = properties[_propertyId].price - _fee;

                USDT.transfer(agency(), _fee);
                USDT.transfer( properties[_propertyId].currentOwner, _propertyOwnerEth );

            } else if (paidIn[_propertyId] == Tokens.NNT) {

                uint256 _fee = (properties[_propertyId].price * (sellerIndividualFee)) / 100;
                _fee = properties[_propertyId].amountP + _fee;
                uint256 _propertyOwnerEth = properties[_propertyId].price - _fee;

                _fee = ExchangeHandler.priceCalculatorUSDTtoNNT(_fee);
                _propertyOwnerEth = ExchangeHandler.priceCalculatorUSDTtoNNT(_propertyOwnerEth);
                
                NNT.transfer(agency(), _fee);
                NNT.transfer( properties[_propertyId].currentOwner, _propertyOwnerEth );

            }
        }

        PROPERTY_TOKEN.safeTransferFrom(
            address(this),
            buyerInfo[_propertyId].buyerAddress,
            properties[_propertyId].folioNumber
        );

        TICKET_TOKEN.burn(properties[_propertyId].folioNumber);

        properties[_propertyId].currentOwner = buyerInfo[_propertyId].buyerAddress;
        properties[_propertyId].fullName = buyerInfo[_propertyId].fullName;
        properties[_propertyId].phoneNumber = buyerInfo[_propertyId].phoneNumber;

        DealAccepted[_propertyId] = true;
    }


    // not using this function for now
    function rejectDeal(uint256 _propertyId, string memory _rejectedDealReason) public onlyAgency {
        USDT.transfer(
            buyerInfo[_propertyId].buyerAddress,
            properties[_propertyId].price
        );
        PropertyPricePaid[_propertyId] = false;
        DealRejected[_propertyId] = true;
        DealRejectedReason[_propertyId] = _rejectedDealReason;
    }

    /*************************************************
     *                   Extra functions
     **************************************************/

    function changeAgencyFee(uint256 _fee) public onlyAgency {
        sellerAgencyFee = _fee;
    }

    function changeSellerIndividualFee(uint256 _fee) public onlyAgency {
        sellerIndividualFee = _fee;
    }

    function changeTicketTokenPrice(uint256 _ticketPrice) public onlyAgency {
        TicketTokenPrice = _ticketPrice;
    }

    uint256 public burnTime = 1209600;
    mapping(uint256 => uint256) public burnTimer;

    function changeBurnTimer(uint256 _propertyId, uint256 _burnTime) public onlyAgency {
        burnTimer[properties[_propertyId].folioNumber] = _burnTime;
    }

    function changeDefaultBurnTime(uint256 _time) public onlyAgency {
        burnTime = _time;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev Interface of the IUSDT standard as defined in the EIP.
 */
interface IUSDT {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint);


    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address who) external view returns (uint);


    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint value) external;


    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint);


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
    function approve(address spender, uint value) external;

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint value) external;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    

    function safeMint(address to, uint256 tokenId) external;
    
    function isApprovedOrOwner(address _spender , uint256 _tokenid) external view returns(bool);

    function setBaseUrl(uint256 tokenId, string memory baseURI) external;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface ITT721 {
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    

    function safeMint(address to, uint256 tokenId) external;
    
    function isApprovedOrOwner(address _spender , uint256 _tokenid) external view returns(bool);

    function setBaseUrl(uint256 tokenId, string memory baseURI) external;

    function TokenTransferTimestamp(uint256 tokenId) external view returns (uint);

    function burn(uint256 tokenId) external;

    function approveToSmartContract(address to, uint tokenId) external;


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// __________                    .___.__               _________         _____   __    
// \______   \_____  __  _  __ __| _/|__|  ____       /   _____/  ____ _/ ____\_/  |_  
//  |    |  _/\__  \ \ \/ \/ // __ | |  |_/ ___\      \_____  \  /  _ \\   __\ \   __\ 
//  |    |   \ / __ \_\     // /_/ | |  |\  \___      /        \(  <_> )|  |    |  |   
//  |______  /(____  / \/\_/ \____ | |__| \___  >    /_______  / \____/ |__|    |__|   
//         \/      \/             \/          \/             \/                        

interface INFTilityExchange {

    function price() external view returns(uint);

    function NFTilityToken() external view returns(address);

    function USDT() external view returns(address);

    function priceCalculatorUSDTtoNNT(uint USDT_) external view returns(uint NNT_);

    function priceCalculatorNNTtoUSDT(uint NNT_) external view returns(uint USDT_);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./../openzepplin/contracts/utils/Context.sol";

abstract contract Ownable is Context {

    address private _agency;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() {
        _transferOwnership(_msgSender());
    }


    function agency() public view virtual returns (address) {
        return _agency;
    }


    modifier onlyAgency() {
        require(agency() == _msgSender(), "!Agency");
        _;
    }


    function renounceOwnership() public virtual onlyAgency {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyAgency {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _agency;
        _agency = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
        emit Paused(_msgSender());
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
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
library SafeMath {
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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