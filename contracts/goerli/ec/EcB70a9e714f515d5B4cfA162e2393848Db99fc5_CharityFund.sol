/**
 *Submitted for verification at Etherscan.io on 2022-06-11
*/

// SPDX-License-Identifier: MIT
// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/CharityOrganization.sol


pragma solidity ^0.8.13;



contract CharityOrganization is Ownable {
    string public organizationName;
    string public organizationDescription;
    address public organizationManager;
    uint256 public minimumDonation;
    uint256 public numberOfRequests;
    address[] public donators;
    mapping(address => bool) IsAlreadyDonator;
    mapping(address => address) tokenToPriceFeed;

    constructor(
        address _organizationManager,
        string memory _organizationName,
        string memory _organizationDescription,
        uint256 _minimumDonation
    ) {
        organizationManager = _organizationManager;
        organizationName = _organizationName;
        organizationDescription = _organizationDescription;
        minimumDonation = _minimumDonation;
    }

    function organizationDetails()
        public
        view
        returns (
            string memory,
            string memory,
            uint256
        )
    {
        return (organizationName, organizationDescription, minimumDonation);
    }

    function setPriceFeedContract(address _token, address _priceFeed)
        public
        onlyOwner
    {
        tokenToPriceFeed[_token] = _priceFeed;
    }

    // This function accepts the donation only in ether
    function donate(uint256 _amount) public payable {
        require(
            _amount >= minimumDonation,
            "Donation Amount is less than the minimum Amount"
        );
        // Check if the donator already donated to this organization?
        // If not then insert this donator's address in the "donators" list
        if (IsAlreadyDonator[msg.sender] == false) {
            IsAlreadyDonator[msg.sender] = true;
            donators.push(address(msg.sender));
        }
    }

    function getTokenValue(address _token)
        public
        view
        returns (uint256, uint256)
    {
        address priceFeedAddress = tokenToPriceFeed[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price), decimals);
    }
}
// File: contracts/CharityFund.sol


pragma solidity ^0.8.13;


contract CharityFund {
    CharityOrganization[] public organizations;
    address owner;
    uint256 numberOfRequests;
    constructor() {
        owner = msg.sender;
    }

    event organizationAdded(
        address indexed sender,
        CharityOrganization organization,
        string organizationName,
        string organizationDescription
    );
    event organizationRemoved(
        address indexed sender,
        CharityOrganization organization
    );


    function addOrganization(
        string memory _organizationName,
        string memory _organizationDescription,
        uint256 _minimumContribution
    ) public {
        CharityOrganization organization = new CharityOrganization(
            msg.sender,
            _organizationName,
            _organizationDescription,
            _minimumContribution
        );
        organizations.push(organization);
        emit organizationAdded(
            msg.sender,
            organization,
            _organizationName,
            _organizationDescription
        );
    }

    function deleteOrganization(
        CharityOrganization _organization
    ) public {
        for (uint i=0; i<organizations.length; i++) {
            if (organizations[i] == _organization) {
                organizations[i] = organizations[organizations.length - 1];
                organizations.pop();
            }
        }
        emit organizationRemoved(
            msg.sender,
            _organization
        );
    }
}