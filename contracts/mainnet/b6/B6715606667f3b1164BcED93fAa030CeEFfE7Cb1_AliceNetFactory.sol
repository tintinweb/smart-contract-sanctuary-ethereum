// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;
import "contracts/utils/DeterministicAddress.sol";
import "contracts/Proxy.sol";
import "contracts/libraries/factory/AliceNetFactoryBase.sol";

/// @custom:salt AliceNetFactory
contract AliceNetFactory is AliceNetFactoryBase {
    /**
     * @dev The constructor encodes the proxy deploy byte code with the _UNIVERSAL_DEPLOY_CODE at the
     * head and the factory address at the tail, and deploys the proxy byte code using create OpCode.
     * The result of this deployment will be a contract with the proxy contract deployment bytecode with
     * its constructor at the head, runtime code in the body and constructor args at the tail. The
     * constructor then sets proxyTemplate_ state var to the deployed proxy template address the deploy
     * account will be set as the first owner of the factory.
     */
    constructor() AliceNetFactoryBase() {}

    /**
     * @dev callAny allows EOA to call function impersonating the factory address
     * @param target_: the address of the contract to be called
     * @param value_: value in WEIs to send together the call
     * @param cdata_: Hex encoded state with function signature + arguments of the target function to be called
     */
    function callAny(
        address target_,
        uint256 value_,
        bytes calldata cdata_
    ) public payable onlyOwner {
        bytes memory cdata = cdata_;
        _callAny(target_, value_, cdata);
        _returnAvailableData();
    }

    /**
     * @dev deployCreate allows the owner to deploy raw contracts through the factory using
     * non-deterministic address generation (create OpCode)
     * @param deployCode_ Hex encoded state with the deployment code of the contract to be deployed +
     * constructors' args (if any)
     * @return contractAddr the deployed contract address
     */
    function deployCreate(bytes calldata deployCode_)
        public
        onlyOwner
        returns (address contractAddr)
    {
        return _deployCreate(deployCode_);
    }

    /**
     * @dev deployCreate2 allows the owner to deploy contracts with deterministic address
     * through the factory
     * @param value_ endowment value in WEIS for the created contract
     * @param salt_ salt used to determine the final determinist address for the deployed contract
     * @param deployCode_ Hex encoded state with the deployment code of the contract to be deployed +
     * constructors' args (if any)
     * @return contractAddr the deployed contract address
     */
    function deployCreate2(
        uint256 value_,
        bytes32 salt_,
        bytes calldata deployCode_
    ) public payable onlyOwner returns (address contractAddr) {
        contractAddr = _deployCreate2(value_, salt_, deployCode_);
    }

    /**
     * @dev deployProxy deploys a proxy contract with upgradable logic. See Proxy.sol contract.
     * @param salt_ salt used to determine the final determinist address for the deployed contract
     */
    function deployProxy(bytes32 salt_) public onlyOwner returns (address contractAddr) {
        contractAddr = _deployProxy(salt_);
    }

    /**
     * @dev deployStatic finishes the deployment started with the deployTemplate of a contract with
     * determinist address. This function call any initialize() function in the deployed contract
     * in case the arguments are provided. Should be called after deployTemplate.
     * @param salt_ salt used to determine the final determinist address for the deployed contract
     * @param initCallData_ Hex encoded initialization function signature + parameters to initialize the deployed contract
     * @return contractAddr the address of the deployed template contract
     */
    function deployStatic(bytes32 salt_, bytes calldata initCallData_)
        public
        onlyOwner
        returns (address contractAddr)
    {
        contractAddr = _deployStatic(salt_, initCallData_);
    }

    /**
     * @dev deployTemplate deploys a template contract with the universal code copy constructor that
     * deploys the contract+constructorArgs defined in the deployCode_ as the contracts runtime code.
     * @param deployCode_ Hex encoded state with the deploymentCode + (constructor args appended if any)
     * @return contractAddr the address of the deployed template contract
     */
    function deployTemplate(bytes calldata deployCode_)
        public
        onlyOwner
        returns (address contractAddr)
    {
        contractAddr = _deployTemplate(deployCode_);
    }

    /**
     * @dev initializeContract allows the owner/delegator to initialize contracts deployed via factory
     * @param contract_ address of the contract that will be initialized
     * @param initCallData_ Hex encoded initialization function signature + parameters to initialize the
     * deployed contract
     */
    function initializeContract(address contract_, bytes calldata initCallData_) public onlyOwner {
        _initializeContract(contract_, initCallData_);
    }

    /**
     * @dev multiCall allows EOA to make multiple function calls within a single transaction
     * impersonating the factory
     * @param cdata_: array of hex encoded state with the function calls (function signature + arguments)
     */
    function multiCall(MultiCallArgs[] calldata cdata_) public onlyOwner {
        _multiCall(cdata_);
    }

    /**
     * @dev upgradeProxy updates the implementation/logic address of an already deployed proxy contract.
     * @param salt_ salt used to determine the final determinist address for the deployed proxy contract
     * @param newImpl_ address of the new contract that contains the new implementation logic
     * @param initCallData_ Hex encoded initialization function signature + parameters to initialize the
     * new implementation contract
     */
    function upgradeProxy(
        bytes32 salt_,
        address newImpl_,
        bytes calldata initCallData_
    ) public onlyOwner {
        _upgradeProxy(salt_, newImpl_, initCallData_);
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

abstract contract DeterministicAddress {
    function getMetamorphicContractAddress(bytes32 _salt, address _factory)
        public
        pure
        returns (address)
    {
        // byte code for metamorphic contract
        // 6020363636335afa1536363636515af43d36363e3d36f3
        bytes32 metamorphicContractBytecodeHash_ = 0x1c0bf703a3415cada9785e89e9d70314c3111ae7d8e04f33bb42eb1d264088be;
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                hex"ff",
                                _factory,
                                _salt,
                                metamorphicContractBytecodeHash_
                            )
                        )
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";

/**
 *@notice RUN OPTIMIZER OFF
 */
/**
 * @notice Proxy is a delegatecall reverse proxy implementation
 * the forwarding address is stored at the slot location of not(0)
 * if not(0) has a value stored in it that is of the form 0Xca11c0de15dead10cced0000< address >
 * the proxy may no longer be upgraded using the internal mechanism. This does not prevent the implementation
 * from upgrading the proxy by changing this slot.
 * The proxy may be directly upgraded ( if the lock is not set )
 * by calling the proxy from the factory address using the format
 * abi.encodeWithSelector(0xca11c0de, <address>);
 * All other calls will be proxied through to the implementation.
 * The implementation can not be locked using the internal upgrade mechanism due to the fact that the internal
 * mechanism zeros out the higher order bits. Therefore, the implementation itself must carry the locking mechanism that sets
 * the higher order bits to lock the upgrade capability of the proxy.
 */
contract Proxy {
    address private immutable _factory;

    constructor() {
        _factory = msg.sender;
    }

    receive() external payable {
        _fallback();
    }

    fallback() external payable {
        _fallback();
    }

    function getImplementationAddress() public view returns (address) {
        assembly {
            mstore(
                0x00,
                and(
                    sload(not(0x00)),
                    0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff
                )
            )
            return(0x00, 0x20)
        }
    }

    function _fallback() internal {
        // make local copy of factory since immutables
        // are not accessable in assembly as of yet
        address factory = _factory;
        assembly {
            // admin is the builtin logic to change the implementation
            function admin() {
                // this is an assignment to implementation
                let newImpl := shr(96, shl(96, calldataload(0x04)))
                if eq(shr(160, sload(not(0x00))), 0xca11c0de15dead10cced0000) {
                    mstore(0x00, "imploc")
                    revert(0x00, 0x20)
                }
                // store address into slot
                sstore(not(0x00), newImpl)
                stop()
            }

            // passthrough is the passthrough logic to delegate to the implementation
            function passthrough() {
                // load free memory pointer
                let _ptr := mload(0x40)
                // allocate memory proportionate to calldata
                mstore(0x40, add(_ptr, calldatasize()))
                // copy calldata into memory
                calldatacopy(_ptr, 0x00, calldatasize())
                let ret := delegatecall(gas(), sload(not(0x00)), _ptr, calldatasize(), 0x00, 0x00)
                returndatacopy(_ptr, 0x00, returndatasize())
                if iszero(ret) {
                    revert(_ptr, returndatasize())
                }
                return(_ptr, returndatasize())
            }

            // if caller is factory,
            // and has 0xca11c0de<address> as calldata
            // run admin logic and return
            if eq(caller(), factory) {
                if eq(calldatasize(), 0x24) {
                    if eq(shr(224, calldataload(0x00)), 0xca11c0de) {
                        admin()
                    }
                }
            }
            // admin logic was not run so fallthrough to delegatecall
            passthrough()
        }
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;
import "contracts/Proxy.sol";
import "contracts/utils/DeterministicAddress.sol";
import "contracts/libraries/proxy/ProxyUpgrader.sol";
import "contracts/interfaces/IProxy.sol";
import "contracts/libraries/errors/AliceNetFactoryBaseErrors.sol";

abstract contract AliceNetFactoryBase is DeterministicAddress, ProxyUpgrader {
    struct MultiCallArgs {
        address target;
        uint256 value;
        bytes data;
    }
    /**
    @dev owner role for privileged access to functions
    */
    address private _owner;

    /**
    @dev array to store list of contract salts
    */
    bytes32[] private _contracts;

    /**
    @dev slot for storing implementation address
    */
    address private _implementation;

    address private immutable _proxyTemplate;

    bytes8 private constant _UNIVERSAL_DEPLOY_CODE = 0x38585839386009f3;

    /**
     *@dev events that notify of contract deployment
     */
    event Deployed(bytes32 salt, address contractAddr);
    event DeployedTemplate(address contractAddr);
    event DeployedStatic(address contractAddr);
    event DeployedRaw(address contractAddr);
    event DeployedProxy(address contractAddr);

    // modifier restricts caller to owner or self via multicall
    modifier onlyOwner() {
        _requireAuth(msg.sender == address(this) || msg.sender == owner());
        _;
    }

    /**
     * @dev The constructor encodes the proxy deploy byte code with the _UNIVERSAL_DEPLOY_CODE at the
     * head and the factory address at the tail, and deploys the proxy byte code using create OpCode.
     * The result of this deployment will be a contract with the proxy contract deployment bytecode with
     * its constructor at the head, runtime code in the body and constructor args at the tail. The
     * constructor then sets proxyTemplate_ state var to the deployed proxy template address the deploy
     * account will be set as the first owner of the factory.
     */
    constructor() {
        bytes memory proxyDeployCode = abi.encodePacked(
            //8 byte code copy constructor code
            _UNIVERSAL_DEPLOY_CODE,
            type(Proxy).creationCode,
            bytes32(uint256(uint160(address(this))))
        );
        //variable to store the address created from create(the location of the proxy template contract)
        address addr;
        assembly {
            //deploys the proxy template contract
            addr := create(0, add(proxyDeployCode, 0x20), mload(proxyDeployCode))
            if iszero(addr) {
                //if contract creation fails, we want to return any err messages
                returndatacopy(0x00, 0x00, returndatasize())
                //revert and return errors
                revert(0x00, returndatasize())
            }
        }
        //State var that stores the proxyTemplate address
        _proxyTemplate = addr;
        //State var that stores the _owner address
        _owner = msg.sender;
    }

    // solhint-disable payable-fallback
    /**
     * @dev fallback function returns the address of the most recent deployment of a template
     */
    fallback() external {
        assembly {
            mstore(returndatasize(), sload(_implementation.slot))
            return(returndatasize(), 0x20)
        }
    }

    /**
     * @dev Sets a new implementation address
     * @param newImplementationAddress_: address of the contract with the new implementation
     */
    function setImplementation(address newImplementationAddress_) public onlyOwner {
        _implementation = newImplementationAddress_;
    }

    /**
     * @dev Sets the new owner
     * @param newOwner_: address of the new owner
     */
    function setOwner(address newOwner_) public onlyOwner {
        _owner = newOwner_;
    }

    /**
     * @dev lookup allows anyone interacting with the contract to get the address of contract specified
     * by its name_
     * @param salt_: Custom NatSpec tag @custom:salt at the top of the contract solidity file
     */
    function lookup(bytes32 salt_) public view returns (address addr) {
        addr = getMetamorphicContractAddress(salt_, address(this));
    }

    /**
     * @dev getImplementation is public getter function for the _owner account address
     */
    function getImplementation() public view returns (address) {
        return _implementation;
    }

    /**
     * @dev owner is public getter function for the _owner account address
     * @return owner_ address of the owner account
     */
    function owner() public view returns (address owner_) {
        owner_ = _owner;
    }

    /**
     * @dev contracts is public getter that gets the array of salts associated with all the contracts
     * deployed with this factory
     * @return contracts_ the array of salts associated with all the contracts deployed with this
     * factory
     */
    function contracts() public view returns (bytes32[] memory contracts_) {
        contracts_ = _contracts;
    }

    /**
     * @dev getNumContracts getter function for retrieving the total number of contracts
     * deployed with this factory
     * @return the length of the contract array
     */
    function getNumContracts() public view returns (uint256) {
        return _contracts.length;
    }

    /**
     * @dev _callAny allows EOA to call function impersonating the factory address
     * @param target_: the address of the contract to be called
     * @param value_: value in WEIs to send together the call
     * @param cdata_: Hex encoded data with function signature + arguments of the target function to be called
     */
    function _callAny(
        address target_,
        uint256 value_,
        bytes memory cdata_
    ) internal {
        assembly {
            let size := mload(cdata_)
            let ptr := add(0x20, cdata_)
            if iszero(call(gas(), target_, value_, ptr, size, 0x00, 0x00)) {
                returndatacopy(0x00, 0x00, returndatasize())
                revert(0x00, returndatasize())
            }
        }
    }

    /**
     * @dev _deployCreate allows the owner to deploy raw contracts through the factory using
     * non-deterministic address generation (create OpCode)
     * @param deployCode_ Hex encoded data with the deployment code of the contract to be deployed +
     * constructors' args (if any)
     * @return contractAddr the deployed contract address
     */
    function _deployCreate(bytes calldata deployCode_) internal returns (address contractAddr) {
        assembly {
            //get the next free pointer
            let basePtr := mload(0x40)
            let ptr := basePtr

            //copies the initialization code of the implementation contract
            calldatacopy(ptr, deployCode_.offset, deployCode_.length)

            //Move the ptr to the end of the code in memory
            ptr := add(ptr, deployCode_.length)

            contractAddr := create(0, basePtr, sub(ptr, basePtr))
        }
        _codeSizeZeroRevert((_extCodeSize(contractAddr) != 0));
        emit DeployedRaw(contractAddr);
        return contractAddr;
    }

    /**
     * @dev _deployCreate2 allows the owner to deploy contracts with deterministic address through the
     * factory
     * @param value_ endowment value in WEIS for the created contract
     * @param salt_ salt used to determine the final determinist address for the deployed contract
     * @param deployCode_ Hex encoded data with the deployment code of the contract to be deployed +
     * constructors' args (if any)
     * @return contractAddr the deployed contract address
     */
    function _deployCreate2(
        uint256 value_,
        bytes32 salt_,
        bytes calldata deployCode_
    ) internal returns (address contractAddr) {
        assembly {
            //get the next free pointer
            let basePtr := mload(0x40)
            let ptr := basePtr

            //copies the initialization code of the implementation contract
            calldatacopy(ptr, deployCode_.offset, deployCode_.length)

            //Move the ptr to the end of the code in memory
            ptr := add(ptr, deployCode_.length)

            contractAddr := create2(value_, basePtr, sub(ptr, basePtr), salt_)
        }
        _codeSizeZeroRevert(uint160(contractAddr) != 0);
        //record the contract salt to the _contracts array for lookup
        _contracts.push(salt_);
        emit DeployedRaw(contractAddr);
        return contractAddr;
    }

    /**
     * @dev _deployProxy deploys a proxy contract with upgradable logic. See Proxy.sol contract.
     * @param salt_ salt used to determine the final determinist address for the deployed contract
     */
    function _deployProxy(bytes32 salt_) internal returns (address contractAddr) {
        address proxyTemplate = _proxyTemplate;
        assembly {
            // store proxy template address as implementation,
            sstore(_implementation.slot, proxyTemplate)
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            // put metamorphic code as initCode
            // push1 20
            mstore(ptr, shl(72, 0x6020363636335afa1536363636515af43d36363e3d36f3))
            contractAddr := create2(0, ptr, 0x17, salt_)
        }
        _codeSizeZeroRevert((_extCodeSize(contractAddr) != 0));
        // record the contract salt to the contracts array
        _contracts.push(salt_);
        emit DeployedProxy(contractAddr);
        return contractAddr;
    }

    /**
     * @dev _deployStatic finishes the deployment started with the deployTemplate of a contract with
     * determinist address. This function call any initialize() function in the deployed contract
     * in case the arguments are provided. Should be called after deployTemplate.
     * @param salt_ salt used to determine the final determinist address for the deployed contract
     * @param initCallData_ Hex encoded initialization function signature + parameters to initialize the deployed contract
     * @return contractAddr the address of the deployed template contract
     */
    function _deployStatic(bytes32 salt_, bytes calldata initCallData_)
        internal
        returns (address contractAddr)
    {
        assembly {
            // store proxy template address as implementation,
            //sstore(_implementation.slot, _impl)
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            // put metamorphic code as initcode
            /*
                00 60 PUSH1     20
                02 36 CALLDATASIZE          20
                03 36 CALLDATASIZE          0 | 20
                04 36 CALLDATASIZE          0 | 0 | 20
                05 33 CALLER                0 | 0 | 0 | 20
                06 5a GAS                   CALLER | 0 | 0 | 0 | 20
                07 fa STATICCALL            GAS | CALLER | 0 | 0 | 0 | 20
                08 15 ISZERO                tmeplateaddress
                09 36 CALLDATASIZE          0
                0a 36 CALLDATASIZE          0 | 0
                0b 36 CALLDATASIZE          0 | 0 | 0
                0c 36 CALLDATASIZE          0 | 0 | 0 | 0
                0d 51 MLOAD                 0 | 0 | 0 | 0 | 0
                0e 5a GAS                   address | 0 | 0 | 0 | 0
                0f f4 DELEGATECALL          GAS | address | 0 | 0 | 0 | 0
                10 3d RETURNDATASIZE
                11 36 CALLDATASIZE          RETURNDATASIZE
                12 36 CALLDATASIZE
                13 3e RETURNDATACOPY
                14 3d RETURNDATASIZE
                15 36 CALLDATASIZE
                16 f3 RETURN
            */
            mstore(ptr, shl(72, 0x6020363636335afa1536363636515af43d36363e3d36f3))
            contractAddr := create2(0, ptr, 0x17, salt_)
            //if the returndatasize is not 0 revert with the error message
            if iszero(iszero(returndatasize())) {
                returndatacopy(0x00, 0x00, returndatasize())
                revert(0, returndatasize())
            }
            //if contractAddr or code size at contractAddr is 0 revert with deploy fail message
            if or(iszero(contractAddr), iszero(extcodesize(contractAddr))) {
                mstore(0, "Static deploy failed")
                revert(0, 0x20)
            }
        }
        if (initCallData_.length > 0) {
            _initializeContract(contractAddr, initCallData_);
        }
        _codeSizeZeroRevert((_extCodeSize(contractAddr) != 0));
        _contracts.push(salt_);
        emit DeployedStatic(contractAddr);
        return contractAddr;
    }

    /**
     * @dev _deployTemplate deploys a template contract with the universal code copy constructor that
     * deploys the contract+constructorArgs defined in the deployCode_ as the contracts runtime code.
     * @param deployCode_ Hex encoded data with the deploymentCode + (constructor args appended if any)
     * @return contractAddr the address of the deployed template contract
     */
    function _deployTemplate(bytes calldata deployCode_) internal returns (address contractAddr) {
        assembly {
            //get the next free pointer
            let basePtr := mload(0x40)
            mstore(0x40, add(basePtr, add(deployCode_.length, 0x28)))
            let ptr := basePtr
            //codesize, pc,  pc, codecopy, codesize, push1 09, return push2 <codesize> 56 5b
            /*
            00 38 codesize
            01 58 pc            codesize
            02 58 pc            01 | codesize
            03 39 codecopy      02 | 01 | codesize
            04 38 codesize
            05 60 push1 09      codesize
            07 f3 return        09 | codesize
             */
            mstore(ptr, hex"38585839386009f3")
            //0x38585839386009f3
            ptr := add(ptr, 0x08)
            //copy the initialization code of the implementation contract
            calldatacopy(ptr, deployCode_.offset, deployCode_.length)
            // Move the ptr to the end of the code in memory
            ptr := add(ptr, deployCode_.length)
            contractAddr := create(0, basePtr, sub(ptr, basePtr))
        }
        _codeSizeZeroRevert((_extCodeSize(contractAddr) != 0));
        emit DeployedTemplate(contractAddr);
        _implementation = contractAddr;
        return contractAddr;
    }

    /**
     * @dev _initializeContract allows the owner/delegator to initialize contracts deployed via factory
     * @param contract_ address of the contract that will be initialized
     * @param initCallData_ Hex encoded initialization function signature + parameters to initialize the
     * deployed contract
     */
    function _initializeContract(address contract_, bytes calldata initCallData_) internal {
        assembly {
            if iszero(iszero(initCallData_.length)) {
                let ptr := mload(0x40)
                mstore(0x40, add(initCallData_.length, ptr))
                calldatacopy(ptr, initCallData_.offset, initCallData_.length)
                if iszero(call(gas(), contract_, 0, ptr, initCallData_.length, 0x00, 0x00)) {
                    ptr := mload(0x40)
                    mstore(0x40, add(returndatasize(), ptr))
                    returndatacopy(ptr, 0x00, returndatasize())
                    revert(ptr, returndatasize())
                }
            }
        }
    }

    /**
     * @dev _multiCall allows EOA to make multiple function calls within a single transaction
     * impersonating the factory
     * @param cdata_: array of abi encoded data with the function calls (function signature + arguments)
     */
    function _multiCall(MultiCallArgs[] calldata cdata_) internal {
        for (uint256 i = 0; i < cdata_.length; i++) {
            _callAny(cdata_[i].target, cdata_[i].value, cdata_[i].data);
        }
        _returnAvailableData();
    }

    /**
     * @dev _upgradeProxy updates the implementation/logic address of an already deployed proxy contract.
     * @param salt_ salt used to determine the final determinist address for the deployed proxy contract
     * @param newImpl_ address of the new contract that contains the new implementation logic
     * @param initCallData_ Hex encoded initialization function signature + parameters to initialize the
     * new implementation contract
     */
    function _upgradeProxy(
        bytes32 salt_,
        address newImpl_,
        bytes calldata initCallData_
    ) internal {
        address proxy = DeterministicAddress.getMetamorphicContractAddress(salt_, address(this));
        __upgrade(proxy, newImpl_);
        assert(IProxy(proxy).getImplementationAddress() == newImpl_);
        _initializeContract(proxy, initCallData_);
    }

    /**
     * @dev Aux function to return the external code size
     */
    function _extCodeSize(address target_) internal view returns (uint256 size) {
        assembly {
            size := extcodesize(target_)
        }
        return size;
    }

    /**
     * @dev Aux function to get the return data size
     */
    function _returnAvailableData() internal pure {
        assembly {
            returndatacopy(0x00, 0x00, returndatasize())
            return(0x00, returndatasize())
        }
    }

    /**
     * @dev _requireAuth reverts if false and returns unauthorized error message
     * @param isOk_ boolean false to cause revert
     */
    function _requireAuth(bool isOk_) internal pure {
        if (!isOk_) {
            revert AliceNetFactoryBaseErrors.Unauthorized();
        }
    }

    /**
     * @dev _codeSizeZeroRevert reverts if false and returns csize0 error message
     * @param isOk_ boolean false to cause revert
     */
    function _codeSizeZeroRevert(bool isOk_) internal pure {
        if (!isOk_) {
            revert AliceNetFactoryBaseErrors.CodeSizeZero();
        }
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

abstract contract ProxyUpgrader {
    function __upgrade(address _proxy, address _newImpl) internal {
        bytes memory cdata = abi.encodeWithSelector(0xca11c0de, _newImpl);
        assembly {
            if iszero(call(gas(), _proxy, 0, add(cdata, 0x20), mload(cdata), 0x00, 0x00)) {
                let ptr := mload(0x40)
                mstore(0x40, add(ptr, returndatasize()))
                returndatacopy(ptr, 0x00, returndatasize())
                revert(ptr, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IProxy {
    function getImplementationAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library AliceNetFactoryBaseErrors {
    error Unauthorized();
    error CodeSizeZero();
}