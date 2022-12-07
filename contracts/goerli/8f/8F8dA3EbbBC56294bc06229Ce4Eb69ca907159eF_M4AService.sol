// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./NFTicket/contracts/interfaces/INFTServiceTypes.sol";
import "./NFTicket/contracts/interfaces/INFTicket.sol";
import "./NFTicket/contracts/interfaces/INFTicketProcessor.sol";
import "./NFTicket/contracts/libs/TransferHelper.sol";
import "./NFTicket/contracts/libs/SafeMath.sol";
import "./interfaces/IM4AService.sol";

contract M4AService is Initializable, AccessControlUpgradeable, IM4AService {
    using SafeMath for uint256;

    mapping(uint256 => TicketInfo) public TicketRecords;

    //openzeppelin access control role definitions
    bytes32 public constant MEMBER_ROLE = keccak256("MEMBER_ROLE");
    bytes32 public constant VEHICLE_ROLE = keccak256("VEHICLE_ROLE");
    bytes32 public constant VEHICLE_CONTROLLER =
        keccak256("VEHICLE_CONTROLLER");

    uint256 public pricePerCredit; //number of wei per credit
    uint256 public override creditsPerKm; //number of credits per km
    uint256 public minCredits; //number of credits to start a trip
    uint256 public maxCredits; //max number of credits on a ticket
    address public NFTicket; //NFTicket contract address
    address public NFTicketProcessor; //NFTicketProcessor contract address
    address public ERC20Address; //ERC20 token address
    uint32 public serviceDescriptor; //service descriptor hex string
    uint256 public serviceFee; //service fee for minting a ticket
    uint256 public resellerFee; //reseller fee for minting a ticket
    address public vehicleController; //vehicle controller contract address; registerVehicleController() must be called to set this address

    //initializer instead of constructor to be able to use openzeppelin upgradeable contracts
    function initialize(
        uint256 _pricePerCredit,
        uint256 _creditsPerKm,
        uint256 _minCredits,
        uint256 _maxCredits,
        address _erc20Token,
        address _nfticket,
        address _nfticketProcessor,
        uint32 _serviceDescriptor,
        uint256 _serviceFee,
        uint256 _resellerFee
    ) public initializer {
        pricePerCredit = _pricePerCredit;
        creditsPerKm = _creditsPerKm;
        minCredits = _minCredits;
        maxCredits = _maxCredits;
        NFTicket = _nfticket;
        NFTicketProcessor = _nfticketProcessor;
        ERC20Address = _erc20Token;
        serviceDescriptor = _serviceDescriptor;
        serviceFee = _serviceFee;
        resellerFee = _resellerFee;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /************************** start setter functions **************************/

    //Register vehicle controller contract address
    function registerVehicleController(
        address _vehicleController
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        vehicleController = _vehicleController;
        grantRole(VEHICLE_CONTROLLER, _vehicleController);
        _setRoleAdmin(VEHICLE_ROLE, VEHICLE_CONTROLLER);
    }

    function setPricePerCredit(
        uint256 _pricePerCredit
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        pricePerCredit = _pricePerCredit;
    }

    function setServiceDescriptor(
        uint32 _serviceDescriptor
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        serviceDescriptor = _serviceDescriptor;
    }

    function setServiceFee(
        uint256 _serviceFee
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        serviceFee = _serviceFee;
    }

    function setResellerFee(
        uint256 _resellerFee
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        resellerFee = _resellerFee;
    }

    function setCreditsPerKm(
        uint32 _creditsPerKm
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        creditsPerKm = _creditsPerKm;
    }

    function setMinCredits(
        uint32 _minCredits
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        minCredits = _minCredits;
    }

    function setMaxCredits(
        uint32 _maxCredits
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        maxCredits = _maxCredits;
    }

    /************************** End setter functions **************************/

    /************************** Start access control **************************/

    function makeDefaultAdmin(
        address account
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    function isDefaultAdmin(
        address account
    ) public view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    //Returns true if account is a member
    function isMember(address account) public view override returns (bool) {
        return hasRole(MEMBER_ROLE, account);
    }

    //Grant member role to an address
    function grantMemberRole(
        address account
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MEMBER_ROLE, account);
    }

    //Revoke member role from an address
    function revokeMemberRole(
        address account
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(isMember(account), "M4AService: account is not a member");
        revokeRole(MEMBER_ROLE, account);
    }

    //Return true if account is a vehicle
    function isVehicle(address account) public view override returns (bool) {
        return hasRole(VEHICLE_ROLE, account);
    }

    //Grant vehicle role to an address
    function grantVehicleRole(
        address account
    ) external override onlyRole(VEHICLE_CONTROLLER) {
        grantRole(VEHICLE_ROLE, account);
    }

    //Revoke vehicle role from an address
    function revokeVehicleRole(
        address account
    ) external override onlyRole(VEHICLE_CONTROLLER) {
        require(isVehicle(account), "M4AService: account is not a vehicle");
        revokeRole(VEHICLE_ROLE, account);
    }

    /************************** End access control **************************/

    //Returns the owner of the ticket
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return IERC721Upgradeable(NFTicket).ownerOf(tokenId);
    }

    //presentTicket() is used in two different ways:
    //1. msg.sender = user; The ticket is presented, when a member wants to start a trip.
    //The ticket is presented to the NFTicketProcessor and transferred to the vehicle.
    //2. msg.sender = vehicle; The the ticket is presented, when a vehicle wants to end a trip.
    //Calculations are made by the vehicle controller contract.
    //General usage information can be found in the sequence diagram.
    function presentTicket(
        uint256 tokenID,
        address presenter,
        uint256 credits,
        address ticketReceiver
    ) external override {
        //Check if msg.sender is a vehicle or msg.sender is a member or msg.sender is the vehicle controller
        require(
            (isVehicle(msg.sender) ||
                (isMember(msg.sender)) ||
                msg.sender == vehicleController),
            "M4AService: not authorized to present ticket"
        );

        checkTicket(tokenID, presenter);

        Ticket memory ticket = INFTicketProcessor(NFTicketProcessor)
            .presentTicket(
                tokenID,
                presenter,
                address(this),
                credits,
                ticketReceiver
            );

        emit ticketPresented(
            ticket.tokenID,
            presenter,
            ticketReceiver,
            credits,
            ticket.credits
        );
    }

    //Check if the msg.sender is the ticket owner & if the ticket has enough credits
    function checkTicket(
        uint256 tokenID,
        address presenter
    ) public view override returns (bool) {
        string memory _msg1 = "M4AService: user is not the owner of the ticket";
        string
            memory _msg2 = "M4AService: user has not enough credits to start a trip";

        require(
            msg.sender == ownerOf(tokenID) ||
                (msg.sender == vehicleController &&
                    presenter == ownerOf(tokenID) &&
                    isVehicle(presenter)),
            _msg1
        );
        require(
            (INFTicket(NFTicket).getTicketData(tokenID).credits >= minCredits),
            _msg2
        );
        return true;
    }

    //Get the number of BLXM tokens that the user has to pay to top up his ticket
    function getPriceForTopUp(
        uint256 tokenID
    ) public view override returns (uint256 numberOfBlxm) {
        uint256 currentCredits = INFTicket(NFTicket)
            .getTicketData(tokenID)
            .credits;
        numberOfBlxm = (maxCredits.sub(currentCredits)).mul(pricePerCredit);
        require(numberOfBlxm > 0, "M4AService: Ticket has already max credits");

        return numberOfBlxm; //in wei
    }

    //Top up the ticket with BLXM tokens
    function topUpTicket(
        uint256 tokenID
    )
        public
        override
        onlyRole(MEMBER_ROLE)
        returns (uint256 creditsForTopUp, uint256 chargedERC20)
    {
        creditsForTopUp = getPriceForTopUp(tokenID).div(pricePerCredit);
        chargedERC20 = getPriceForTopUp(tokenID);

        //transfer ERC20 tokens from user to contract
        IERC20Upgradeable(ERC20Address).transferFrom(
            msg.sender,
            address(this),
            chargedERC20
        );

        uint256 currentallowance = IERC20Upgradeable(ERC20Address).allowance(
            address(this),
            NFTicket
        );

        //Approve NFTicket contract to transfer BLXM tokens from M4ASerivce contract
        //Add chargedERC20 to current allowance
        IERC20Upgradeable(ERC20Address).approve(
            NFTicket,
            chargedERC20.add(currentallowance)
        );

        //Call topUpTicket function of NFTicket contract
        INFTicket(NFTicket).topUpTicket(
            tokenID,
            creditsForTopUp,
            ERC20Address,
            chargedERC20
        );

        emit topUpCreditsSuccessful(creditsForTopUp, chargedERC20);
        return (creditsForTopUp, chargedERC20);
    }

    //Buy a ticket with BLXM tokens and a defined number of credits
    //The minted ticket is transferred to the recipient
    //tokenURI is optional and can be "null"
    function buyM4ATicket(
        address recipient,
        uint256 credits,
        string memory _tokenURI
    ) public override onlyRole(MEMBER_ROLE) returns (uint256 newTicketID) {
        uint256 price = credits.mul(pricePerCredit);
        string memory _msg;
        _msg = "M4AService: customer ";

        _msg = string(
            abi.encodePacked(
                _msg,
                abi.encodePacked(
                    StringsUpgradeable.toString(uint256(uint160(msg.sender)))
                ),
                " allowance "
            )
        );
        string memory allowance = StringsUpgradeable.toString(
            IERC20Upgradeable(ERC20Address).allowance(msg.sender, address(this))
        );
        _msg = string(
            abi.encodePacked(_msg, allowance, " is insuffient for price=")
        );
        allowance = StringsUpgradeable.toString(price);
        _msg = string(abi.encodePacked(_msg, allowance));

        //Check customer allowance equal or more than the price in payload
        require(
            IERC20Upgradeable(ERC20Address).allowance(
                msg.sender,
                address(this)
            ) >= price,
            _msg
        );

        //Check customer ERC20 balance is equal or more than the price in payload
        require(
            IERC20Upgradeable(ERC20Address).balanceOf(msg.sender) >= price,
            "M4AService: customer token balance is insufficient."
        );

        TransferHelper.safeTransferFrom(
            ERC20Address,
            msg.sender,
            NFTicket,
            price
        );
        Ticket memory _t = Ticket({
            tokenID: 0,
            serviceProvider: address(this),
            serviceDescriptor: serviceDescriptor,
            issuedTo: recipient,
            certValue: 0,
            certValidFrom: 0,
            price: price,
            credits: credits,
            pricePerCredit: pricePerCredit,
            serviceFee: serviceFee,
            resellerFee: resellerFee,
            transactionFee: 0,
            tokenURI: _tokenURI
        });

        _t = INFTicket(NFTicket).mintNFTicket(recipient, _t);

        emit ticketIssued(newTicketID, _t, price);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../NFTicket/contracts/interfaces/INFTServiceTypes.sol";

interface IM4AService {
    function creditsPerKm() external returns (uint256);

    function registerVehicleController(address _vehicleController) external;

    function setPricePerCredit(uint256 _pricePerCredit) external;

    function setServiceDescriptor(uint32 _serviceDescriptor) external;

    function setServiceFee(uint256 _serviceFee) external;

    function setResellerFee(uint256 _resellerFee) external;

    function setCreditsPerKm(uint32 _creditsPerKm) external;

    function setMinCredits(uint32 _minCredits) external;

    function setMaxCredits(uint32 _maxCredits) external;

    function isMember(address account) external view returns (bool);

    function makeDefaultAdmin(address account) external;

    function isDefaultAdmin(address account) external view returns (bool);

    function ownerOf(uint256 tokenId) external view returns (address);

    function grantMemberRole(address account) external;

    function revokeMemberRole(address account) external;

    function isVehicle(address account) external view returns (bool);

    function grantVehicleRole(address account) external;

    function revokeVehicleRole(address account) external;

    function checkTicket(
        uint256 tokenID,
        address presenter
    ) external view returns (bool);

    function getPriceForTopUp(
        uint256 tokenID
    ) external view returns (uint256 numberOfBlxm);

    function presentTicket(
        uint256 tokenID,
        address presenter,
        uint256 credits,
        address ticketReceiver
    ) external;

    function topUpTicket(
        uint256 tokenID
    ) external returns (uint256 creditsAffordable, uint256 chargedERC20);

    function buyM4ATicket(
        address userAddress,
        uint256 credits,
        string memory _tokenURI
    ) external returns (uint256 newTicketID);

    event ticketIssued(uint256 indexed newTicketId, Ticket _t, uint256 price);

    event ticketPresented(
        uint256 tokenID,
        address from,
        address to,
        uint256 creditsPresented,
        uint256 creditsRemaining
    );
    event topUpCreditsSuccessful(uint256 creditsForTopUp, uint256 chargedERC20);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// First byte is Processing Mode: from here we derive the caluclation and account booking logic
// basic differentiator being Ticket or Certificate (of ownership)
// all tickets need lowest bit of first semi-byte set
// all certificates need lowest bit of first semi-byte set
// all checkin-checkout tickets need second-lowest bit of first-semi-byte set --> 0x03000000
// high bits for each byte or half.byte are categories, low bits are instances
uint32 constant IS_CERTIFICATE =    0x40000000; // 2nd highest bit of CERTT-half-byte = 1 - cannot use highest bit?
uint32 constant IS_TICKET =         0x08000000; // highest bit of ticket-halfbyte = 1
uint32 constant CHECKOUT_TICKET =   0x09000000; // highest bit of ticket-halfbyte = 1 AND lowest bit = 1
uint32 constant CASH_VOUCHER =      0x0A000000; // highest bit of ticket-halfbyte = 1 AND 2nd bit = 1

// company identifiers last 10 bbits, e.g. 1023 companies
uint32 constant BLOXMOVE =          0x00000200; // top of 10 bits for company identifiers
uint32 constant NRVERSE =           0x00000001;
uint32 constant MITTWEIDA =         0x00000002;
uint32 constant EQUOTA =            0x00000003;

// Industrial Category - byte2
uint32 constant THG =               0x80800000; //  CERTIFICATE & highest bit of category half-byte = 1
uint32 constant REC =               0x80400000; //  CERTIFICATE & 2nd highest bit of category half-byte = 1

// Last byte is company identifier 1-255
uint32 constant NRVERSE_REC =       0x80800001; // CERTIFICATE & REC & 0x00000001
uint32 constant eQUOTA_THG =        0x80400003; // CERTIFICATE & THG & 0x00000003
uint32 constant MITTWEIDA_M4A =     0x09000002; // CHECKOUT_TICKET & MITTWEIDA
uint32 constant BLOXMOVE_CO =       0x09000200;
uint32 constant BLOXMOVE_CV =       0x0A000200;
uint32 constant BLOXMOVE_CI =       0x08000200;
uint32 constant BLOXMOVE_NG =       0x09000201;
uint32 constant DutchMaaS =         0x09000003;
uint32 constant TIER_MW =           0x09000004;



/***********************************************
 *
 * generic schematizable data payload
 * allows for customization between reseller and
 * service operator while keeping NFTicket agnostic
 *
 ***********************************************/

enum eDataType {
    _UNDEF,
    _UINT,
    _UINT256,
    _USTRING
}

struct TicketInfo {
    uint256 ticketFee;
    bool ticketUsed;
}


/*
* TODO reconcile redundancies between Payload, BuyNFTicketParams and Ticket
*/
struct Ticket {
    uint256 tokenID;
    address serviceProvider; // the index to the map where we keep info about serviceProviders
    uint32  serviceDescriptor;
    address issuedTo;
    uint256 certValue;
    uint    certValidFrom; // value can be redeemedn after this time
    uint256 price;
    uint256 credits;        // [7]
    uint256 pricePerCredit;
    uint256 serviceFee;
    uint256 resellerFee;
    uint256 transactionFee;
    string tokenURI;
}

struct Payload {
    address recipient;
    string tokenURI;
    DataSchema schema;
    string[] data;
    string[] serializedTicket;  
    uint256 certValue;
    string uuid;
    uint256 credits;
    uint256 pricePerCredit;
    uint256 price;
    uint256 timestamp;
}

/**** END TODO reconcile */

struct DataSchema {
    string name;
    uint32 size;
    string[] keys;
    uint8[] keyTypes;
}

struct DataRecords {
    DataSchema _schema;
    string[] _data; // a one-dimensional array of length [_schema.size * <number of records> ]
}

struct ConsumedRecord {
    uint certId;
    string energyType;
    string location;
    uint amount;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./INFTServiceTypes.sol";   
/**
 * Interface of NFTicket
 */

 
interface INFTicket {
    function mintNFTicket(address recipient, Ticket memory _ticket)
        external
        payable 
        returns (Ticket memory);

    function updateServiceType(uint256 ticketID, uint32 serviceDescriptor)
        external
        returns(uint256 _sD);
    
    function withDrawCredits(uint256 _ticketID, address erc20Contract, uint256 credits, address sendTo)
        external;
        
    function withDrawERC20(uint256 _ticketID, address erc20Contract, uint256 amountERC20Tokens, address sendTo)
        external;
    function topUpTicket(uint256 tokenID, uint256 creditsAdded, address erc20Contract, uint256 numberERC20Tokens)
        external returns(uint256 creditsAffordable, uint256 chargedERC20);

    function registerServiceProvider(address serviceProvider, uint32 serviceDescriptor, address serviceProviderWallet) 
        external returns(uint16 status);
    function registerResellerServiceProvider(address serviceProvider, address reseller, address resellerWallet)
        external returns(uint16 status); 

    /*
    function consumeCredits(address serviceProvider, uint256 _tokenID, uint256 credits)
        external 
        returns(uint256 creditsConsumed, uint256 creditsRemain);
    */

    function getTransactionPoolSize() external view returns (uint256);

    function getServiceProviderPoolSize(address serviceProvider)
        external
        view
        returns (uint256 poolSize);

    function getTotalTicketPoolSize() 
        external 
        view 
        returns (uint256); 

    function getTicketData(uint256 _ticketID)
        external
        view
        returns (Ticket memory);

    function getTicketBalance(uint256 tokenID) 
        external 
        view 
        returns (uint256); 

    function getTreasuryOwner()
        external
        returns(address);
    
    function getTicketProcessor()
        external
        returns(address);
    
    
    event IncomingERC20(
        uint256 indexed tokenID,
        address indexed ERC20,
        uint256 amountERC20Tokens,
        address sender,
        address owner,
        uint32  indexed serviceDescriptor
    );

    event IncomingFunding(
        uint256 indexed tokenID,
        address indexed ERC20,
        address sender,
        address owner,
        uint256 creditsAdded,
        uint256 tokensAdded,
        uint32  indexed serviceDescriptor
    );

    event WithDrawCredits(
        uint256 indexed tokenID,
        address indexed erc20Contract,
        uint256 amountCredits,
        address indexed from,
        address to 
    );
    event WithDrawERC20(
        uint256 indexed tokenID,
        address indexed erc20Contract,
        uint256 amountERC20Tokens,
        address indexed from,
        address to 
    );

    event TicketSubmitted(
        address indexed _contract,
        uint256 indexed ticketID,
        uint256 indexed serviceType,
        uint256 deductedFee
    );
    event SplitRevenue(
        uint256 indexed newTicketID,
        uint256 value,
        uint256 serviceFee,
        uint256 resellerFee,
        uint256 transactionFee
    );
    event SchemaRegistered(string name, DataSchema schema);
    event ConsumedCredits(
        uint256 indexed _tID,
        uint256 creditsConsumed,
        uint256 creditsRemain
    );
    event RegisterServiceProvider(
        address indexed serviceProvideContract,
        uint32 indexed serviceDescriptor,
        uint16 status
    );
    event WrongSender(
        address sender,
        address expectedSender,
        string message
    );
    event InsufficientPayment(
        uint256 value,
        uint256 credits,
        uint256 pricePerCredit
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./INFTServiceTypes.sol";   

interface INFTicketProcessor {
    function refundTicketFeeToTicketOwner(uint256 tokenId, uint256 ticketFee)
        external;

    function presentTicket(
        uint256 tokenID,
        address presenter,
        address _serviceProvider,
        uint256 credits
    ) external returns (Ticket memory);

    function presentTicket(
        uint256 tokenID,
        address presenter,
        address _serviceProvider,
        uint256 credits,
        address ticketReceiver
    ) external returns (Ticket memory ticket);

    function topUpTicket(uint256 tokenID, uint32 serviceDescriptor, uint256 creditsAdded, address erc20Token, uint256 numberERC20Tokens) 
        external
        returns (uint256 credits); 

    event CreditsToService(
        uint256 ticketID,
        uint256 credits,
        uint256 value,
        address payer,
        address payee
    );

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.7;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferNative(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: NATIVE_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
        return mod(a, b, 'SafeMath: modulo by zero');
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

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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