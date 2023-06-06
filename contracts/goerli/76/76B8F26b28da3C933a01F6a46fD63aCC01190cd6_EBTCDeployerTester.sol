// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../EBTCDeployer.sol";

//import "../Governor.sol";
//import "../LiquidationLibrary.sol";
//import "../CdpManager.sol";
//import "../BorrowerOperations.sol";
//import "../SortedCdps.sol";
//import "../ActivePool.sol";
//import "../CollSurplusPool.sol";
//import "../HintHelpers.sol";
//import "../EBTCToken.sol";
//import "../FeeRecipient.sol";
//import "../PriceFeed.sol";

// tester imports
//import "./CDPManagerTester.sol";
//import "./BorrowerOperationsTester.sol";
//import "./testnet/PriceFeedTestnet.sol";
//import "./ActivePoolTester.sol";
//import "./EBTCTokenTester.sol";

contract EBTCDeployerTester is EBTCDeployer {
    // core contracts creation code
    //    bytes public authority_creationCode = type(Governor).creationCode;
    //    bytes public liquidationLibrary_creationCode = type(LiquidationLibrary).creationCode;
    //    bytes public cdpManager_creationCode = type(CdpManager).creationCode;
    //    bytes public borrowerOperations_creationCode = type(BorrowerOperations).creationCode;
    //    bytes public sortedCdps_creationCode = type(SortedCdps).creationCode;
    //    bytes public activePool_creationCode = type(ActivePool).creationCode;
    //    bytes public collSurplusPool_creationCode = type(CollSurplusPool).creationCode;
    //    bytes public hintHelpers_creationCode = type(HintHelpers).creationCode;
    //    bytes public ebtcToken_creationCode = type(EBTCToken).creationCode;
    //    bytes public feeRecipient_creationCode = type(FeeRecipient).creationCode;
    //    bytes public priceFeed_creationCode = type(PriceFeed).creationCode;

    // test contracts creation code
    //    bytes public cdpManagerTester_creationCode = type(CdpManagerTester).creationCode;
    //    bytes public borrowerOperationsTester_creationCode = type(BorrowerOperationsTester).creationCode;
    //    bytes public priceFeedTestnet_creationCode = type(PriceFeedTestnet).creationCode;
    //    bytes public activePoolTester_creationCode = type(ActivePoolTester).creationCode;
    //    bytes public ebtcTokenTester_creationCode = type(EBTCTokenTester).creationCode;

    function deployWithCreationCodeAndConstructorArgs(
        string memory _saltString,
        bytes memory creationCode,
        bytes memory constructionArgs
    ) external returns (address) {
        bytes memory _data = abi.encodePacked(creationCode, constructionArgs);
        return super.deploy(_saltString, _data);
    }

    function deployWithCreationCode(
        string memory _saltString,
        bytes memory creationCode
    ) external returns (address) {
        return super.deploy(_saltString, creationCode);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity 0.8.17;

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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

/**
  @title A library for deploying contracts EIP-3171 style.
  @author Agustin Aguilar <[email protected]>
*/
library Create3 {
    error ErrorCreatingProxy();
    error ErrorCreatingContract();
    error TargetAlreadyExists();

    /**
    @notice The bytecode for a contract that proxies the creation of another contract
    @dev If this code is deployed using CREATE2 it can be used to decouple `creationCode` from the child contract address

  0x67363d3d37363d34f03d5260086018f3:
      0x00  0x67  0x67XXXXXXXXXXXXXXXX  PUSH8 bytecode  0x363d3d37363d34f0
      0x01  0x3d  0x3d                  RETURNDATASIZE  0 0x363d3d37363d34f0
      0x02  0x52  0x52                  MSTORE
      0x03  0x60  0x6008                PUSH1 08        8
      0x04  0x60  0x6018                PUSH1 18        24 8
      0x05  0xf3  0xf3                  RETURN

  0x363d3d37363d34f0:
      0x00  0x36  0x36                  CALLDATASIZE    cds
      0x01  0x3d  0x3d                  RETURNDATASIZE  0 cds
      0x02  0x3d  0x3d                  RETURNDATASIZE  0 0 cds
      0x03  0x37  0x37                  CALLDATACOPY
      0x04  0x36  0x36                  CALLDATASIZE    cds
      0x05  0x3d  0x3d                  RETURNDATASIZE  0 cds
      0x06  0x34  0x34                  CALLVALUE       val 0 cds
      0x07  0xf0  0xf0                  CREATE          addr
  */

    bytes internal constant PROXY_CHILD_BYTECODE =
        hex"67_36_3d_3d_37_36_3d_34_f0_3d_52_60_08_60_18_f3";

    //                        KECCAK256_PROXY_CHILD_BYTECODE = keccak256(PROXY_CHILD_BYTECODE);
    bytes32 internal constant KECCAK256_PROXY_CHILD_BYTECODE =
        0x21c35dbe1b344a2488cf3321d6ce542f8e9f305544ff09e4993a62319a497c1f;

    /**
    @notice Returns the size of the code on a given address
    @param _addr Address that may or may not contain code
    @return size of the code on the given `_addr`
  */
    function codeSize(address _addr) internal view returns (uint256 size) {
        assembly {
            size := extcodesize(_addr)
        }
    }

    /**
    @notice Creates a new contract with given `_creationCode` and `_salt`
    @param _salt Salt of the contract creation, resulting address will be derivated from this value only
    @param _creationCode Creation code (constructor) of the contract to be deployed, this value doesn't affect the resulting address
    @return addr of the deployed contract, reverts on error
  */
    function create3(bytes32 _salt, bytes memory _creationCode) internal returns (address addr) {
        return create3(_salt, _creationCode, 0);
    }

    /**
    @notice Creates a new contract with given `_creationCode` and `_salt`
    @param _salt Salt of the contract creation, resulting address will be derivated from this value only
    @param _creationCode Creation code (constructor) of the contract to be deployed, this value doesn't affect the resulting address
    @param _value In WEI of ETH to be forwarded to child contract
    @return addr of the deployed contract, reverts on error
  */
    function create3(
        bytes32 _salt,
        bytes memory _creationCode,
        uint256 _value
    ) internal returns (address addr) {
        // Creation code
        bytes memory creationCode = PROXY_CHILD_BYTECODE;

        // Get target final address
        addr = addressOf(_salt);
        if (codeSize(addr) != 0) revert TargetAlreadyExists();

        // Create CREATE2 proxy
        address proxy;
        assembly {
            proxy := create2(0, add(creationCode, 32), mload(creationCode), _salt)
        }
        if (proxy == address(0)) revert ErrorCreatingProxy();

        // Call proxy with final init code
        (bool success, ) = proxy.call{value: _value}(_creationCode);
        if (!success || codeSize(addr) == 0) revert ErrorCreatingContract();
    }

    /**
    @notice Computes the resulting address of a contract deployed using address(this) and the given `_salt`
    @param _salt Salt of the contract creation, resulting address will be derivated from this value only
    @return addr of the deployed contract, reverts on error

    @dev The address creation formula is: keccak256(rlp([keccak256(0xff ++ address(this) ++ _salt ++ keccak256(childBytecode))[12:], 0x01]))
  */
    function addressOf(bytes32 _salt) internal view returns (address) {
        address proxy = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            address(this),
                            _salt,
                            KECCAK256_PROXY_CHILD_BYTECODE
                        )
                    )
                )
            )
        );

        return address(uint160(uint256(keccak256(abi.encodePacked(hex"d6_94", proxy, hex"01")))));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity 0.8.17;

import "./Context.sol";

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

pragma solidity 0.8.17;

import "./Dependencies/Create3.sol";
import "./Dependencies/Ownable.sol";

contract EBTCDeployer is Ownable {
    string public constant name = "eBTC Deployer";

    string public constant AUTHORITY = "ebtc.v1.authority";
    string public constant LIQUIDATION_LIBRARY = "ebtc.v1.liquidationLibrary";
    string public constant CDP_MANAGER = "ebtc.v1.cdpManager";
    string public constant BORROWER_OPERATIONS = "ebtc.v1.borrowerOperations";

    string public constant PRICE_FEED = "ebtc.v1.priceFeed";
    string public constant SORTED_CDPS = "ebtc.v1.sortedCdps";

    string public constant ACTIVE_POOL = "ebtc.v1.activePool";
    string public constant COLL_SURPLUS_POOL = "ebtc.v1.collSurplusPool";

    string public constant HINT_HELPERS = "ebtc.v1.hintHelpers";
    string public constant EBTC_TOKEN = "ebtc.v1.eBTCToken";
    string public constant FEE_RECIPIENT = "ebtc.v1.feeRecipient";
    string public constant MULTI_CDP_GETTER = "ebtc.v1.multiCdpGetter";

    event ContractDeployed(address indexed contractAddress, string contractName, bytes32 salt);

    struct EbtcAddresses {
        address authorityAddress;
        address liquidationLibraryAddress;
        address cdpManagerAddress;
        address borrowerOperationsAddress;
        address priceFeedAddress;
        address sortedCdpsAddress;
        address activePoolAddress;
        address collSurplusPoolAddress;
        address hintHelpersAddress;
        address ebtcTokenAddress;
        address feeRecipientAddress;
        address multiCdpGetterAddress;
    }

    /**
    @notice Helper method to return a set of future addresses for eBTC. Intended to be used in the order specified.
    
    @dev The order is as follows:
    0: authority
    1: liquidationLibrary
    2: cdpManager
    3: borrowerOperations
    4: priceFeed
    5; sortedCdps
    6: activePool
    7: collSurplusPool
    8: hintHelpers
    9: eBTCToken
    10: feeRecipient
    11: multiCdpGetter


     */
    function getFutureEbtcAddresses() public view returns (EbtcAddresses memory) {
        EbtcAddresses memory addresses = EbtcAddresses(
            Create3.addressOf(keccak256(abi.encodePacked(AUTHORITY))),
            Create3.addressOf(keccak256(abi.encodePacked(LIQUIDATION_LIBRARY))),
            Create3.addressOf(keccak256(abi.encodePacked(CDP_MANAGER))),
            Create3.addressOf(keccak256(abi.encodePacked(BORROWER_OPERATIONS))),
            Create3.addressOf(keccak256(abi.encodePacked(PRICE_FEED))),
            Create3.addressOf(keccak256(abi.encodePacked(SORTED_CDPS))),
            Create3.addressOf(keccak256(abi.encodePacked(ACTIVE_POOL))),
            Create3.addressOf(keccak256(abi.encodePacked(COLL_SURPLUS_POOL))),
            Create3.addressOf(keccak256(abi.encodePacked(HINT_HELPERS))),
            Create3.addressOf(keccak256(abi.encodePacked(EBTC_TOKEN))),
            Create3.addressOf(keccak256(abi.encodePacked(FEE_RECIPIENT))),
            Create3.addressOf(keccak256(abi.encodePacked(MULTI_CDP_GETTER)))
        );

        return addresses;
    }

    /**
        @notice Deploy a contract using salt in string format and arbitrary runtime code.
        @dev Intended use is: get the future eBTC addresses, then deploy the appropriate contract to each address via this method, building the constructor using the mapped addresses
        @dev no enforcment of bytecode at address as we can't know the runtime code in this contract due to space constraints
        @dev gated to given deployer EOA to ensure no interference with process, given proper actions by deployer
     */
    function deploy(
        string memory _saltString,
        bytes memory _creationCode
    ) public returns (address deployedAddress) {
        bytes32 _salt = keccak256(abi.encodePacked(_saltString));
        deployedAddress = Create3.create3(_salt, _creationCode);
        emit ContractDeployed(deployedAddress, _saltString, _salt);
    }

    function addressOf(string memory _saltString) external view returns (address) {
        bytes32 _salt = keccak256(abi.encodePacked(_saltString));
        return Create3.addressOf(_salt);
    }

    function addressOfSalt(bytes32 _salt) external view returns (address) {
        return Create3.addressOf(_salt);
    }

    /**
        @notice Create the creation code for a contract with the given runtime code.
        @dev credit: https://github.com/0xsequence/create3/blob/master/contracts/test_utils/Create3Imp.sol
     */
    function creationCodeFor(bytes memory _code) internal pure returns (bytes memory) {
        /*
      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN
      <CODE>
    */

        return
            abi.encodePacked(hex"63", uint32(_code.length), hex"80_60_0E_60_00_39_60_00_F3", _code);
    }
}