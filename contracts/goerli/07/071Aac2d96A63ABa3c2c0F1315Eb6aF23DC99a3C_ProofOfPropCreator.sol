// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";
import "Ownable.sol";
import "ProofOfProp.sol";

contract ProofOfPropCreator is Ownable {
    
    mapping(address => address[]) public addressToContract;
    ProofOfProp[] private certificatesStorageArray;

    uint256 public usdEntryFee; // variable storing minimum fee
    AggregatorV3Interface internal ethUsdPriceFeed;

    constructor(address _priceFeedAddress) {
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress); // Assignment of price feed variable
        usdEntryFee = 50 * (10**18);
    }

    // ---------------------------------------------------------------------------------------------------
    // NI: ToDo -> To be removed after testing on production example.
    mapping(address => uint256) private addressToAmountFunded; // MO
    // NI: ToDo -> To be removed after testing on production example.
    address[] private propClients; // MO

    // NI: ToDo -> To be removed after testing on production example.
    // MO: created fund function, moved require from addCertificate => disabled as requested
    // function fund() public payable {
    //     require(
    //         msg.value >= getMinimumFee(),
    //         "You need to pay more ETH to create certificate!"
    //     );
    //     addressToAmountFunded[msg.sender] += msg.value;
    //     propClients.push(msg.sender);
    // }
    // ---------------------------------------------------------------------------------------------------

    // Client Needs to pay us in order to use "addCertificate" function.
    function addCertificate(
        string memory _certificate,
        string memory _date,
        string memory _title,
        address _address,
        string memory _name,
        string memory _additional,
        string memory _hash
    ) public payable {
        // ToDo :
        // To use this function client has to pay >= minimumFee.
        // Money All Clients pay should be stored on ProofOfPropCreator Contract, so as owners of that Contract can withdraw it.
        require(msg.value >= getMinimumFee(), "Not Enough ETH, you have to pay to create certificate!");
        ProofOfProp certificateStorage = new ProofOfProp(
            _certificate,
            _date,
            _title,
            _address,
            _name,
            _additional,
            _hash
        );
        // Below adding new Certificate(Contract) to array, which contains all certificates ever created by all clients.
        certificatesStorageArray.push(certificateStorage);
        // Below is mapping Client address with all Certificates(Contracts) he deployed (tracking all certificates, which given Client is owner of).
        addressToContract[msg.sender].push(address(certificateStorage));
        //return address(certificateStorage); // MO: to read deployed POP
    }

    // NI: function that returns last certificate
    function getLastCertificate() public view onlyOwner returns (address) {
        uint256 lastIndex = certificatesStorageArray.length - 1;
        return address(certificatesStorageArray[lastIndex]);
    }

    // NI: Below Function Allows Client To Check All Certificate(Contracts) He Owns.
    function getCertificatesYouOwn(address _yourAddress)
        public
        view
        returns (address[] memory)
    {
        return addressToContract[_yourAddress];
    }

    // NI: Below Function Defines Minimal Fee To Use addCertificate() function.
    function getMinimumFee() public view onlyOwner returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData(); // Takes this from AggregatorV3 latestRoundData
        uint256 adjustedPrice = uint256(price) * 10**10; // adjustedPrice has to be expressed with 18 decimals. From Chainlink pricefeed, we know ETH/USD has 8 decimals, so we need to multiply by 10^10
        uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice; // We cannot return decimals, hence we need to express 50$ with 50 * 10*18 / 2000 (adjusted price of ETH)
        return costToEnter; // for testing
    }

    // MO: testing purpose - read balance during development. REMOVE IN PRODUCTION VERSION!!!
    // NI: ToDo: Add onlyOwner parameter, so we as owners can check balance of our creator contract
    function showBalance() public view onlyOwner returns (uint256) {
        uint256 POPbalance = address(this).balance;
        return POPbalance;
    }

    // ToDo: Below function allows us as Owners of this contract to withdraw money gathered on this contract.
    // ToDo: Add onlyOwner parameter
    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // NI: Function Created For Test's Purposes
    function arrayLengthGetter() public view onlyOwner returns (uint, uint) {
        uint cert_array = certificatesStorageArray.length;
        uint clients_array = propClients.length;
        return (cert_array, clients_array);
    }

    // NI: Function to change owner of certificate
    function transferOwnership(address current_owner, address new_owner, address cert_address) public payable {
        
        require(current_owner == msg.sender, "You Are Not Owner Of This Certificate!");
        require(msg.value >= getMinimumFee(), "Not Enough ETH, you have to pay to create certificate!");
        
        address[] memory current_owner_certs = getCertificatesYouOwn(current_owner);
        
        delete(addressToContract[current_owner]);
        
        for (uint i=0; i < current_owner_certs.length; i++){
            if (current_owner_certs[i] == cert_address){
                addressToContract[new_owner].push(cert_address);
            }
            if (current_owner_certs[i] != cert_address){
                addressToContract[current_owner].push(current_owner_certs[i]);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";

contract ProofOfProp is Ownable {

    struct UserParameters {
        string certificate_ref; // generated by our system
        string registration_date; // read data from time of creation from python
        string title; // user input
        address user_address; // This should be read from address, which paid fee
        string user_name; // user input
        string additional_owner; // user input
        string user_file_hash; // hash generated and based on file chosen by user
    }

    UserParameters[] public users;

    constructor(
        string memory _certificate,
        string memory _date,
        string memory _title,
        address _address,
        string memory _name,
        string memory _additional,
        string memory _hash) {
            users.push(
                UserParameters(
                    _certificate,
                    _date,
                    _title,
                    _address,
                    _name,
                    _additional,
                    _hash
                )
            );
    }
}