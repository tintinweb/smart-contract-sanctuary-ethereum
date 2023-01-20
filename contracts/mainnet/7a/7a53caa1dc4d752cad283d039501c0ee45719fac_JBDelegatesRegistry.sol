// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBDidPayData.sol';

/**
  @title
  Pay delegate

  @notice
  Delegate called after JBTerminal.pay(..) logic completion (if passed by the funding cycle datasource)

  @dev
  Adheres to:
  IERC165 for adequate interface integration
*/
interface IJBPayDelegate is IERC165 {
  /**
    @notice
    This function is called by JBPaymentTerminal.pay(..), after the execution of its logic

    @dev
    Critical business logic should be protected by an appropriate access control
    
    @param _data the data passed by the terminal, as a JBDidPayData struct:
                  address payer;
                  uint256 projectId;
                  uint256 currentFundingCycleConfiguration;
                  JBTokenAmount amount;
                  JBTokenAmount forwardedAmount;
                  uint256 projectTokenCount;
                  address beneficiary;
                  bool preferClaimedTokens;
                  string memo;
                  bytes metadata;
  */
  function didPay(JBDidPayData calldata _data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBDidRedeemData.sol';

/**
  @title
  Redemption delegate

  @notice
  Delegate called after JBTerminal.redeemTokensOf(..) logic completion (if passed by the funding cycle datasource)

  @dev
  Adheres to:
  IERC165 for adequate interface integration
*/
interface IJBRedemptionDelegate is IERC165 {
  /**
    @notice
    This function is called by JBPaymentTerminal.redeemTokensOf(..), after the execution of its logic

    @dev
    Critical business logic should be protected by an appropriate access control
    
    @param _data the data passed by the terminal, as a JBDidRedeemData struct:
                address holder;
                uint256 projectId;
                uint256 currentFundingCycleConfiguration;
                uint256 projectTokenCount;
                JBTokenAmount reclaimedAmount;
                JBTokenAmount forwardedAmount;
                address payable beneficiary;
                string memo;
                bytes metadata;
  */
  function didRedeem(JBDidRedeemData calldata _data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './JBTokenAmount.sol';

/** 
  @member payer The address from which the payment originated.
  @member projectId The ID of the project for which the payment was made.
  @member currentFundingCycleConfiguration The configuration of the funding cycle during which the payment is being made.
  @member amount The amount of the payment. Includes the token being paid, the value, the number of decimals included, and the currency of the amount.
  @member forwardedAmount The amount of the payment that is being sent to the delegate. Includes the token being paid, the value, the number of decimals included, and the currency of the amount.
  @member projectTokenCount The number of project tokens minted for the beneficiary.
  @member beneficiary The address to which the tokens were minted.
  @member preferClaimedTokens A flag indicating whether the request prefered to mint project tokens into the beneficiaries wallet rather than leaving them unclaimed. This is only possible if the project has an attached token contract.
  @member memo The memo that is being emitted alongside the payment.
  @member metadata Extra data to send to the delegate.
*/
struct JBDidPayData {
  address payer;
  uint256 projectId;
  uint256 currentFundingCycleConfiguration;
  JBTokenAmount amount;
  JBTokenAmount forwardedAmount;
  uint256 projectTokenCount;
  address beneficiary;
  bool preferClaimedTokens;
  string memo;
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './JBTokenAmount.sol';

/** 
  @member holder The holder of the tokens being redeemed.
  @member projectId The ID of the project with which the redeemed tokens are associated.
  @member currentFundingCycleConfiguration The configuration of the funding cycle during which the redemption is being made.
  @member projectTokenCount The number of project tokens being redeemed.
  @member reclaimedAmount The amount reclaimed from the treasury. Includes the token being reclaimed, the value, the number of decimals included, and the currency of the amount.
  @member forwardedAmount The amount of the payment that is being sent to the delegate. Includes the token being paid, the value, the number of decimals included, and the currency of the amount.
  @member beneficiary The address to which the reclaimed amount will be sent.
  @member memo The memo that is being emitted alongside the redemption.
  @member metadata Extra data to send to the delegate.
*/
struct JBDidRedeemData {
  address holder;
  uint256 projectId;
  uint256 currentFundingCycleConfiguration;
  uint256 projectTokenCount;
  JBTokenAmount reclaimedAmount;
  JBTokenAmount forwardedAmount;
  address payable beneficiary;
  string memo;
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* 
  @member token The token the payment was made in.
  @member value The amount of tokens that was paid, as a fixed point number.
  @member decimals The number of decimals included in the value fixed point number.
  @member currency The expected currency of the value.
**/
struct JBTokenAmount {
  address token;
  uint256 value;
  uint256 decimals;
  uint256 currency;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
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
interface IERC165 {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IJBPayDelegate } from '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPayDelegate.sol';
import { IJBRedemptionDelegate } from '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBRedemptionDelegate.sol';
import { ERC165Checker } from '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';

import { IJBDelegatesRegistry } from './interfaces/IJBDelegatesRegistry.sol';

/**
 * @title   JBDelegatesRegistry
 *
 * @notice  This contract is used to register deployers of Juicebox Delegates
 *          It is the deployer responsability to register their
 *          delegates in this registry and make sure the delegate implements IERC165
 *
 * @dev     Mostly for front-end integration purposes. The delegate address is computed
 *          from the deployer address and the nonce used to deploy the delegate.
 *      
 */
contract JBDelegatesRegistry is IJBDelegatesRegistry {
    //////////////////////////////////////////////////////////////
    //                                                          //
    //                   ERRORS & EVENTS                        //
    //                                                          //
    //////////////////////////////////////////////////////////////
    
    /**
     * @notice Throws if the delegate is not compatible with the Juicebox protocol (based on ERC165)
     */
    error JBDelegatesRegistry_incompatibleDelegate();

    /**
     * @notice Emitted when a deployed delegate is added
     */
    event DelegateAdded(address indexed _delegate, address indexed _deployer);

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                  PUBLIC STATE VARIABLES                  //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice         Track which deployer deployed a delegate, based on a
     *                 proactive deployer update
     * @custom:params  _delegate The address of the delegate
     * @custom:returns _deployer The address of the corresponding deployer
     */
    mapping(address => address) public override deployerOf;

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                     EXTERNAL METHODS                     //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice          Add a delegate to the registry (needs to implement erc165, a delegate type and deployed using create)
     * @param _deployer The address of the deployer of a given delegate
     * @param _nonce    The nonce used to deploy the delegate
     * @dev             frontend might retrieve the correct nonce, for both contract and eoa, using 
     *                  ethers provider.getTransactionCount(address) or web3js web3.eth.getTransactionCount just *before* the
     *                  delegate deployment (if adding a delegate at a later time, manual nonce counting might be needed)
     */
    function addDelegate(address _deployer, uint256 _nonce) external override {
        // Compute the _delegate address, as create1 deployed at _nonce
        address _delegate = _addressFrom(_deployer, _nonce);

        // Add the delegate based on the computed address
        _checkAndAddDelegate(_delegate, _deployer);
    }

    /**
     * @notice          Add a delegate to the registry (needs to implement erc165, a delegate type and deployed using create2)
     * @param _deployer The address of the contract deployer
     * @param _salt     An unique salt used to deploy the delegate
     * @param _bytecode The *deployment* bytecode used to deploy the delegate (ie including constructor and its arguments)
     * @dev             _salt is based on the delegate deployer own internal logic while the deployment bytecode can be retrieved in
     *                  the deployment transaction (off-chain) or via
     *                  abi.encodePacked(type(delegateContract).creationCode, abi.encode(constructorArguments)) (on-chain)
     */
    function addDelegateCreate2(address _deployer, bytes32 _salt, bytes calldata _bytecode) external override {
        // Compute the _delegate address, based on create2 salt and deployment bytecode
        address _delegate = address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xff),
            _deployer,
            _salt,
            keccak256(_bytecode)
        )))));

        // Add the delegate based on the computed address
        _checkAndAddDelegate(_delegate, _deployer);
    }

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                  INTERNAL FUNCTIONS                      //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function _checkAndAddDelegate(address _delegate, address _deployer) internal {
        // Check if the delegate declares implementing a pay or redemption delegate
        if(
            !(ERC165Checker.supportsInterface(_delegate, type(IJBPayDelegate).interfaceId)
            || ERC165Checker.supportsInterface(_delegate, type(IJBRedemptionDelegate).interfaceId))
        ) revert JBDelegatesRegistry_incompatibleDelegate();

        // If so, add it with the deployer
        deployerOf[_delegate] = _deployer;

        emit DelegateAdded(_delegate, _deployer);
    }

    /**
     * @notice          Compute the address of a contract deployed using create1, by an address at a given nonce
     * @param _origin   The address of the deployer
     * @param _nonce    The nonce used to deploy the contract
     * @dev             Taken from https://ethereum.stackexchange.com/a/87840/68134 - this wouldn't work for nonce > 2**32,
     *                  if someone do reach that nonce please: 1) ping us, because wow 2) use another deployer
     */
    function _addressFrom(address _origin, uint _nonce) internal pure returns (address _address) {
        bytes memory data;
        if(_nonce == 0x00)          data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), _origin, bytes1(0x80));
        else if(_nonce <= 0x7f)     data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), _origin, uint8(_nonce));
        else if(_nonce <= 0xff)     data = abi.encodePacked(bytes1(0xd7), bytes1(0x94), _origin, bytes1(0x81), uint8(_nonce));
        else if(_nonce <= 0xffff)   data = abi.encodePacked(bytes1(0xd8), bytes1(0x94), _origin, bytes1(0x82), uint16(_nonce));
        else if(_nonce <= 0xffffff) data = abi.encodePacked(bytes1(0xd9), bytes1(0x94), _origin, bytes1(0x83), uint24(_nonce));
        else                        data = abi.encodePacked(bytes1(0xda), bytes1(0x94), _origin, bytes1(0x84), uint32(_nonce));
        bytes32 hash = keccak256(data);
        assembly {
            mstore(0, hash)
            _address := mload(0)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBDelegatesRegistry {
    function deployerOf(address _delegate) external view returns (address _deployer);
    function addDelegate(address _deployer, uint256 _nonce) external;
    function addDelegateCreate2(address _deployer, bytes32 _salt, bytes calldata _bytecode) external;
}