pragma solidity ^0.5.0;
import "./SafeMath.sol";

interface IRBAC {
    /**
     * @param _account account to check roleContract
     * @param _role uint(enum) => uint8 0: SUPER_ADMIN, 1: NOTARY
     * @return bool
     */
    function hasRole(address _account, uint8 _role)
        external
        view
        returns (bool);
}

/**
 * @title RealEstate
 * @dev Real estate management and transaction
 */

contract RealEstate {
    using SafeMath for uint256;
    // ------------------------------ Variables ------------------------------
    address private owner; // owner, who deploy this smart contract
    IRBAC roleContract; // reference to contract RoleBasedAcl
    // number of certificate (token id)
    uint256 public certificateCount;
    // State of certificate
    enum State {PENDDING, ACTIVATED, IN_TRANSACTION} //sate of token. 0: PENDING - 1: ACTIVATE - 2: IN_TRANSACTION

    // mapping token to owners
    mapping(uint256 => address[]) tokenToOwners;
    // mapping token to owner approved (activate || sell)
    mapping(uint256 => address[]) tokenToApprovals;
    // mapping token to state of token
    mapping(uint256 => State) public tokenToState; // Default: 0 => 'PENDDING'
    // mapping token to notary
    mapping(uint256 => address) public tokenToNotary;
    // mapping token to certificate
    mapping(uint256 => string) public tokenToCert;

    // ------------------------------ Events ------------------------------
    /// @dev Emits when a new certificate created.
    event NewCertificate(
        uint256 idCertificate,
        address[] owners,
        address notary
    );

    /// @dev This emits when ownership of any NFTs changes by any mechanism
    event Transfer(
        address[] oldOwner,
        address[] newOwner,
        uint256 idCertificate
    );

    /// @dev Emits when the owner activate certificate (PENDDING => ACTIVATED)
    event Activate(uint256 idCertificate, address owner, State state);

    constructor(IRBAC _roleContract) public {
        // Initialize roleContract
        roleContract = _roleContract;
        owner = msg.sender;
    }

    // ------------------------------ Modifiers ------------------------------

    modifier onlyPending(uint256 _id) {
        require(
            tokenToState[_id] == State.PENDDING,
            "RealEstate: Require state is PENDDING"
        );
        _;
    }

    modifier onlyActivated(uint256 _id) {
        require(
            tokenToState[_id] == State.ACTIVATED,
            "RealEstate: Require state is ACTIVATED"
        );
        _;
    }

    modifier onlyInTransaction(uint256 _id) {
        require(
            tokenToState[_id] == State.IN_TRANSACTION,
            "RealEstate: Require state is iN_TRANSACTION"
        );
        _;
    }

    modifier onlyOwnerOf(uint256 _id) {
        require(
            _checkExitInArray(tokenToOwners[_id], msg.sender),
            "RealEstate: You're not owner of certificate"
        );
        _;
    }

    // ------------------------------ View functions ------------------------------

    /**
     * @notice Get the owner of a certificate
     * @param _id The identifier of the certificate
     * @return The list address of the owners of the certificate
     */
    function getOwnersOf(uint256 _id) public view returns (address[] memory) {
        return tokenToOwners[_id];
    }

    /**
     * @notice Get the owner approved for (sell || activate) depending on state of certificate
     * @param _id id of certificate
     * @return The list address of the owners approved
     */
    function getOwnerApproved(uint256 _id)
        public
        view
        returns (address[] memory)
    {
        return tokenToApprovals[_id];
    }

    // ------------------------------ Core public functions ------------------------------

    /**
     * @notice Set role base acl contract address
     * @dev only owner can change this contract address
     */
    function setRoleContractAddress(IRBAC _contractAddress) public {
        require(owner == msg.sender, "RealEstate: Require owner");
        roleContract = _contractAddress;
    }

    /**
     * @notice create a new certificate with a struct
     * @dev Require role notary and list owner does not contain msg.sender
     */
    function createCertificate(
        string memory _certificate,
        address[] memory _owners
    ) public {
        require(
            roleContract.hasRole(msg.sender, 1),
            "RealEstate: Require notary"
        );
        // require owner not to be notary(msg.sender)
        require(
            !_checkExitInArray(_owners, msg.sender),
            "RealEstate: You are not allowed to create your own property"
        );
        certificateCount = certificateCount.add(1);
        tokenToCert[certificateCount] = _certificate;
        tokenToOwners[certificateCount] = _owners;
        tokenToNotary[certificateCount] = msg.sender;
        emit NewCertificate(certificateCount, _owners, msg.sender);
    }

    /**
     * @notice Activate certificate (PENDDING => ACTIVATED)
     * @dev Require msg.sender is owner of certification and msg.sender has not activated
     * Change state of certificate if all owner has activated
     */
    function activate(uint256 _id) public onlyOwnerOf(_id) onlyPending(_id) {
        require(
            !_checkExitInArray(tokenToApprovals[_id], msg.sender),
            "RealEstate: Account already approved"
        );
        // store msg.sender to list approved
        tokenToApprovals[_id].push(msg.sender);
        // if all owner approved => set state of certificate to 'ACTIVATED'
        if (tokenToApprovals[_id].length == tokenToOwners[_id].length) {
            tokenToState[_id] = State.ACTIVATED;
            // set user approve to null
            delete tokenToApprovals[_id];
        }
        emit Activate(_id, msg.sender, tokenToState[_id]);
    }

    function transferOwnership(
        uint256 _idCertificate,
        address[] calldata _newOwners
    ) external onlyInTransaction(_idCertificate) {
        // require deposit before => accept deposit => change state to IN_TRANSACTION
        // first owner is representative of owners of certificate
        require(
            _newOwners.length > 0,
            "RealEstate(transfer): require one owner at least"
        );
        address[] memory currentOwners = tokenToOwners[_idCertificate];
        address representativeOwners = currentOwners[0];
        // called in Transaction Contract => mean: msg.sender = TransactionContract
        // using tx.origin will be the account that initiated the chain of contract calls
        // or using msg.sender as the reliable input
        require(
            (tx.origin == representativeOwners),
            "RealEstate(transfer): Require representative of owner of cert"
        );
        tokenToOwners[_idCertificate] = _newOwners;
        emit Transfer(currentOwners, _newOwners, _idCertificate);
    }

    /**
     * @notice Check state of certificate is 'ACTIVATED'
     * @param _id identifier of certificate
     * @return bool
     */
    function isActivated(uint256 _id) public view returns (bool) {
        return tokenToState[_id] == State.ACTIVATED;
    }

    function getOwnersOfCert(uint256 _idCertificate)
        external
        view
        returns (address[] memory)
    {
        return tokenToOwners[_idCertificate];
    }

    // get representative of owners of certificate (owners[0])
    function getRepresentativeOfOwners(uint256 _idCertificate)
        external
        view
        returns (address)
    {
        return tokenToOwners[_idCertificate][0];
    }

    function getStateOfCert(uint256 _idCertificate)
        external
        view
        returns (State)
    {
        return tokenToState[_idCertificate];
    }

    function setStateOfCertInTransaction(uint256 _idCertificate) external {
        tokenToState[_idCertificate] = State.IN_TRANSACTION;
    }

    function setStateOfCertOutTransaction(uint256 _idCertificate) external {
        tokenToState[_idCertificate] = State.ACTIVATED;
    }

    // ------------------------------ Helper functions (internal functions) ------------------------------

    /**
     * @notice Check list address inclue single address
     * @param _array list address
     * @param _user	address want to check
     * @return bool
     */
    function _checkExitInArray(address[] memory _array, address _user)
        internal
        pure
        returns (bool)
    {
        uint256 _arrayLength = _array.length;
        for (uint8 i = 0; i < _arrayLength; i++) {
            if (_user == _array[i]) {
                return true;
            }
        }
        return false;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}