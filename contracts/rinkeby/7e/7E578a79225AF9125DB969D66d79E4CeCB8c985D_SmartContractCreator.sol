// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
//import "AggregatorV3Interface.sol";
import "Ownable.sol";
import "NewContract.sol";

contract SmartContractCreator is Ownable {
    address[] internal contracts;
    string[] internal contractname;
    address public Contractowner;
    mapping(address => address) public ContractToAdmin;
    mapping(address => uint256) public ContractToDate;
    mapping(string => address) public NameToAddress;

    constructor() public {
        Contractowner = msg.sender;
    }

    NewContract public newcontract;

    function CreateContract(address _contractadmin, string memory _contractname)
        public
        onlyOwner
    {
        bool test_value = false;
        for (uint256 i; i < contractname.length; i++) {
            if (
                keccak256(abi.encodePacked(contractname[i])) ==
                keccak256(abi.encodePacked(_contractname))
            ) {
                test_value = true;
            }
        }
        require(test_value == false, "Contract name is already exist!");
        newcontract = new NewContract(_contractadmin);
        contracts.push(address(newcontract));
        ContractToAdmin[address(newcontract)] = _contractadmin;
        ContractToDate[address(newcontract)] = now;
        contractname.push(_contractname);
    }

    function retrieve_owner() public view returns (address) {
        return Contractowner;
    }

    function retrieve_contracts_address()
        public
        view
        returns (address[] memory)
    {
        return contracts;
    }

    function retrieve_contracts_names() public view returns (string[] memory) {
        return contractname;
    }

    function retrieve_name_to_add(string memory _con_add)
        public
        view
        returns (address)
    {
        return NameToAddress[_con_add];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract NewContract {
    enum CSTATES {
        CONTRACTING,
        PROCESSING,
        CANCELED,
        DONE
    }
    CSTATES public current_contract_state;
    address public ContractAdmin;
    address public CustomerAddress;
    address public ProducerAddress;
    address public CustomerBankAddress;
    address public ProducerBankAddress;
    address public InspectionAddress;
    address public ShipperAddress;
    address public CustomsClearanceAddress;

    constructor(address _contractadmin) public {
        ContractAdmin = _contractadmin;
        current_contract_state = CSTATES.CONTRACTING;
    }

    function set_Addresses(
        address _CustomerAddress,
        address _ProducerAddress,
        address _CustomerBankAddress,
        address _ProducerBankAddress,
        address _InspectionAddress
    ) public {
        require(
            msg.sender == ContractAdmin,
            "You don't have permision to set the addresses!"
        );
        require(CustomerAddress == address(0), "CustomerAddress already set!");
        require(ProducerAddress == address(0), "ProducerAddress already set!");
        require(
            CustomerBankAddress == address(0),
            "CustomerBankAddress already set!"
        );
        require(
            ProducerBankAddress == address(0),
            "ProducerBankAddress already set!"
        );
        require(
            InspectionAddress == address(0),
            "InspectionAddress already set!"
        );
        ///////////////////////////////////////////////////////////////////////////////
        require(
            _CustomerAddress != address(0),
            "CustomerAddress couldn't be 0!"
        );
        require(
            _ProducerAddress != address(0),
            "ProducerAddress couldn't be 0!"
        );
        require(
            _CustomerBankAddress != address(0),
            "CustomerBankAddress couldn't be 0!"
        );
        require(
            _ProducerBankAddress != address(0),
            "ProducerBankAddress couldn't be 0!"
        );
        require(
            _InspectionAddress != address(0),
            "InspectionAddress couldn't be 0!"
        );
        ///////////////////////////////////////////////////////////////////////////////
        CustomerAddress = _CustomerAddress;
        ProducerAddress = _ProducerAddress;
        CustomerBankAddress = _CustomerBankAddress;
        ProducerBankAddress = _ProducerBankAddress;
        InspectionAddress = _InspectionAddress;
    }

    function set_ShipperAddress(address _ShipperAddress) public {
        require(
            msg.sender == ContractAdmin,
            "You don't have permision to set the shipper's address!"
        );
        require(
            ShipperAddress == address(0),
            "Customer's address already set!"
        );
        require(
            _ShipperAddress != address(0),
            "Customer's address already set!"
        );
        require(_ShipperAddress != address(0), "ShipperAddress couldn't be 0!");
        ShipperAddress = _ShipperAddress;
    }
}