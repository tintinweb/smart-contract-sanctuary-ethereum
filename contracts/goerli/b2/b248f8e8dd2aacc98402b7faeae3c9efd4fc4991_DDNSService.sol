/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

pragma solidity >=0.4.22 <0.6.0;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract DDNSService is Ownable {
  /** USINGS */
  using SafeMath for uint256;

  /** STRUCTS */
  struct DomainDetails {
    bytes name;
    bytes12 topLevel;
    address owner;
    bytes15 ip;
    uint256 expires;
  }

  struct Receipt {
    uint256 amountPaidWei;
    uint256 timestamp;
    uint256 expires;
  }

  /** CONSTANTS */
  uint256 public constant DOMAIN_NAME_COST = 1 ether;
  uint256 public constant DOMAIN_NAME_COST_SHORT_ADDITION = 1 ether;
  uint256 public constant DOMAIN_EXPIRATION_DATE = 365 days;
  uint8 public constant DOMAIN_NAME_MIN_LENGTH = 5;
  uint8 public constant DOMAIN_NAME_EXPENSIVE_LENGTH = 8;
  uint8 public constant TOP_LEVEL_DOMAIN_MIN_LENGTH = 1;
  bytes1 public constant BYTES_DEFAULT_VALUE = bytes1(0x00);

  /** STATE VARIABLES */
  mapping(bytes32 => DomainDetails) public domainNames;
  mapping(address => bytes32[]) public paymentReceipts;
  mapping(bytes32 => Receipt) public receiptDetails;

  /**
   * MODIFIERS
   */
  modifier isAvailable(bytes memory domain, bytes12 topLevel) {
    bytes32 domainHash = getDomainHash(domain, topLevel);
    require(
      domainNames[domainHash].expires < block.timestamp,
      'Domain name is not available.'
    );
    _;
  }

  modifier collectDomainNamePayment(bytes memory domain) {
    uint256 domainPrice = getPrice(domain);
    require(msg.value >= domainPrice, 'Insufficient amount.');
    _;
  }

  modifier isDomainOwner(bytes memory domain, bytes12 topLevel) {
    bytes32 domainHash = getDomainHash(domain, topLevel);
    require(
      domainNames[domainHash].owner == msg.sender,
      'You are not the owner of this domain.'
    );
    _;
  }

  modifier isDomainNameLengthAllowed(bytes memory domain) {
    require(
      domain.length >= DOMAIN_NAME_MIN_LENGTH,
      'Domain name is too short.'
    );
    _;
  }

  modifier isTopLevelLengthAllowed(bytes12 topLevel) {
    require(
      topLevel.length >= TOP_LEVEL_DOMAIN_MIN_LENGTH,
      'The provided TLD is too short.'
    );
    _;
  }

  /**
   *  EVENTS
   */
  event LogDomainNameRegistered(
    uint256 indexed timestamp,
    bytes domainName,
    bytes12 topLevel
  );

  event LogDomainNameRenewed(
    uint256 indexed timestamp,
    bytes domainName,
    bytes12 topLevel,
    address indexed owner
  );

  event LogDomainNameEdited(
    uint256 indexed timestamp,
    bytes domainName,
    bytes12 topLevel,
    bytes15 newIp
  );

  event LogDomainNameTransferred(
    uint256 indexed timestamp,
    bytes domainName,
    bytes12 topLevel,
    address indexed owner,
    address newOwner
  );

  event LogPurchaseChangeReturned(
    uint256 indexed timestamp,
    address indexed _owner,
    uint256 amount
  );

  event LogReceipt(
    uint256 indexed timestamp,
    bytes domainName,
    uint256 amountInWei,
    uint256 expires
  );

  /**
   * @dev - Constructor of the contract
   */
  constructor() public {}

  /*
   * @dev - function to register domain name
   * @param domain - domain name to be registered
   * @param topLevel - domain top level (TLD)
   * @param ip - the ip of the host
   */
  function register(
    bytes memory domain,
    bytes12 topLevel,
    bytes15 ip
  )
    public
    payable
    isDomainNameLengthAllowed(domain)
    isTopLevelLengthAllowed(topLevel)
    isAvailable(domain, topLevel)
    collectDomainNamePayment(domain)
  {
    // calculate the domain hash
    bytes32 domainHash = getDomainHash(domain, topLevel);

    // create a new domain entry with the provided fn parameters
    DomainDetails memory newDomain = DomainDetails({
      name: domain,
      topLevel: topLevel,
      owner: msg.sender,
      ip: ip,
      expires: block.timestamp + DOMAIN_EXPIRATION_DATE
    });

    // save the domain to the storage
    domainNames[domainHash] = newDomain;

    // create an receipt entry for this domain purchase
    Receipt memory newReceipt = Receipt({
      amountPaidWei: DOMAIN_NAME_COST,
      timestamp: block.timestamp,
      expires: block.timestamp + DOMAIN_EXPIRATION_DATE
    });

    // calculate the receipt hash/key
    bytes32 receiptKey = getReceiptKey(domain, topLevel);

    // save the receipt key for this `msg.sender` in storage
    paymentReceipts[msg.sender].push(receiptKey);

    // save the receipt entry/details in storage
    receiptDetails[receiptKey] = newReceipt;

    // log receipt issuance
    emit LogReceipt(
      block.timestamp,
      domain,
      DOMAIN_NAME_COST,
      block.timestamp + DOMAIN_EXPIRATION_DATE
    );

    // log domain name registered
    emit LogDomainNameRegistered(block.timestamp, domain, topLevel);
  }

  /*
   * @dev - function to extend domain expiration date
   * @param domain - domain name to be registered
   * @param topLevel - top level
   */
  function renewDomainName(bytes memory domain, bytes12 topLevel)
    public
    payable
    isDomainOwner(domain, topLevel)
    collectDomainNamePayment(domain)
  {
    // calculate the domain hash
    bytes32 domainHash = getDomainHash(domain, topLevel);

    // add 365 days (1 year) to the domain expiration date
    domainNames[domainHash].expires += 365 days;

    // create a receipt entity
    Receipt memory newReceipt = Receipt({
      amountPaidWei: DOMAIN_NAME_COST,
      timestamp: block.timestamp,
      expires: block.timestamp + DOMAIN_EXPIRATION_DATE
    });

    // calculate the receipt key for this domain
    bytes32 receiptKey = getReceiptKey(domain, topLevel);

    // save the receipt id for this msg.sender
    paymentReceipts[msg.sender].push(receiptKey);

    // store the receipt details in storage
    receiptDetails[receiptKey] = newReceipt;

    // log domain name Renewed
    emit LogDomainNameRenewed(block.timestamp, domain, topLevel, msg.sender);

    // log receipt issuance
    emit LogReceipt(
      block.timestamp,
      domain,
      DOMAIN_NAME_COST,
      block.timestamp + DOMAIN_EXPIRATION_DATE
    );
  }

  /*
   * @dev - function to edit domain name
   * @param domain - the domain name to be editted
   * @param topLevel - tld of the domain
   * @param newIp - the new ip for the domain
   */
  function edit(
    bytes memory domain,
    bytes12 topLevel,
    bytes15 newIp
  ) public isDomainOwner(domain, topLevel) {
    // calculate the domain hash - unique id
    bytes32 domainHash = getDomainHash(domain, topLevel);

    // update the new ip
    domainNames[domainHash].ip = newIp;

    // log change
    emit LogDomainNameEdited(block.timestamp, domain, topLevel, newIp);
  }

  /*
   * @dev - Transfer domain ownership
   * @param domain - name of the domain
   * @param topLevel - tld of the domain
   * @param newOwner - address of the new owner
   */
  function transferDomain(
    bytes memory domain,
    bytes12 topLevel,
    address newOwner
  ) public isDomainOwner(domain, topLevel) {
    // prevent assigning domain ownership to the 0x0 address
    require(newOwner != address(0));

    // calculate the hash of the current domain
    bytes32 domainHash = getDomainHash(domain, topLevel);

    // assign the new owner of the domain
    domainNames[domainHash].owner = newOwner;

    // log the transfer of ownership
    emit LogDomainNameTransferred(
      block.timestamp,
      domain,
      topLevel,
      msg.sender,
      newOwner
    );
  }

  /*
   * @dev - Get ip of domain
   * @param domain
   * @param topLevel
   */
  function getIP(bytes memory domain, bytes12 topLevel)
    public
    view
    returns (bytes15)
  {
    // calculate the hash of the domain
    bytes32 domainHash = getDomainHash(domain, topLevel);

    // return the ip property of the domain from storage
    return domainNames[domainHash].ip;
  }

  /*
   * @dev - Get price of domain
   * @param domain
   */
  function getPrice(bytes memory domain) public pure returns (uint256) {
    // check if the domain name fits in the expensive or cheap categroy
    if (domain.length < DOMAIN_NAME_EXPENSIVE_LENGTH) {
      // if the domain is too short - its more expensive
      return DOMAIN_NAME_COST + DOMAIN_NAME_COST_SHORT_ADDITION;
    }

    // otherwise return the regular price
    return DOMAIN_NAME_COST;
  }

  /**
   * @dev - Get receipt list for the msg.sender
   */
  function getReceiptList() public view returns (bytes32[] memory) {
    return paymentReceipts[msg.sender];
  }

  /*
   * @dev - Get single receipt
   * @param receiptKey
   */
  function getReceipt(bytes32 receiptKey)
    public
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    return (
      receiptDetails[receiptKey].amountPaidWei,
      receiptDetails[receiptKey].timestamp,
      receiptDetails[receiptKey].expires
    );
  }

  /*
   * @dev - Get (domain name + top level) hash used for unique identifier
   * @param domain
   * @param topLevel
   * @return domainHash
   */
  function getDomainHash(bytes memory domain, bytes12 topLevel)
    public
    pure
    returns (bytes32)
  {
    // @dev - tightly pack parameters in struct for keccak256
    return keccak256(abi.encodePacked(domain, topLevel));
  }

  /*
   * @dev - Get recepit key hash - unique identifier
   * @param domain
   * @param topLevel
   * @return receiptKey
   */
  function getReceiptKey(bytes memory domain, bytes12 topLevel)
    public
    view
    returns (bytes32)
  {
    // @dev - tightly pack parameters in struct for keccak256
    return
      keccak256(
        abi.encodePacked(domain, topLevel, msg.sender, block.timestamp)
      );
  }

  /**
   * @dev - Withdraw function
   */
  function withdraw() public onlyOwner {
    msg.sender.transfer(address(this).balance);
  }
}