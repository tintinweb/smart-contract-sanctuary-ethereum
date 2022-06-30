pragma solidity 0.6.4;
pragma experimental ABIEncoderV2;

import "./utils/Pausable.sol";
import "./utils/SafeMath.sol";
import "./utils/UpgradableOwnable.sol";
import "./interfaces/IDepositExecute.sol";
import "./interfaces/IBridge.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IERCHandler.sol";
import "./utils/VerifySignature.sol";

/**
    @title Facilitates deposits, creation and votiing of deposit proposals, and deposit executions.
 */
contract Bridge is
    Pausable,
    SafeMathContract,
    VerifySignature,
    UpgradableOwnable
{
    bytes8 public _chainID;
    uint256 public _fee;
    address public _backendSrvAddress;

    enum ProposalStatus {
        Inactive,
        Active,
        Passed,
        Executed,
        Cancelled
    }

    bytes32 public _nativeResourceID;

    // destinationChainID => number of deposits
    mapping(bytes8 => uint64) public _depositCounts;
    // resourceID => handler address
    mapping(bytes32 => address) public _resourceIDToHandlerAddress;
    // depositNonce => destinationChainID => bytes
    mapping(uint64 => mapping(bytes8 => bytes)) public _depositRecords;
    // destinationChainID + depositNonce => dataHash => bool
    mapping(bytes32 => mapping(bytes32 => bool)) public _executedProposals;

    mapping(address => bool) public handlers;

    address public _balancerAddress;

    event Deposit(
        bytes8 originChainID,
        bytes8 indexed destinationChainID,
        bytes32 indexed resourceID,
        uint64 indexed depositNonce,
        address depositor,
        address recipientAddress,
        address tokenAddress,
        uint256 amount,
        bytes32 dataHash
    );
    event ProposalEvent(
        bytes8 indexed originChainID,
        bytes8 indexed destinationChainID,
        address indexed recipientAddress,
        uint256 amount,
        uint64 depositNonce,
        ProposalStatus status,
        bytes32 resourceID,
        bytes32 dataHash
    );
    event ExtraFeeSupplied(
        bytes8 originChainID,
        bytes8 destinationChainID,
        uint64 depositNonce,
        bytes32 resourceID,
        address recipientAddress,
        uint256 amount
    );

    modifier onlyBackendSrv() {
        _onlyBackendSrv();
        _;
    }

    function _onlyBackendSrv() private view {
        require(
            _backendSrvAddress == msg.sender,
            "sender is not a backend service"
        );
    }

    modifier onlyHandler() {
        require(handlers[msg.sender], "sender is not a handler");
        _;
    }

    function setHandler(address _handler, bool value) external onlyBackendSrv {
        handlers[_handler] = value;
    }

    /**
        @notice Initializes Bridge, creates and grants {msg.sender} the admin role,
        Sets deposit fee
        @param chainID ID of chain the Bridge contract exists on.
     */
    function initialize(
        bytes8 chainID,
        uint256 fee,
        address initBackendSrvAddress,
        address initBalancerAddress_
    ) public {
        _chainID = chainID;
        _fee = fee;
        _backendSrvAddress = initBackendSrvAddress;
        _balancerAddress = initBalancerAddress_;
        ownableInit(msg.sender);
    }

    /**
        @notice sets new backend srv.
        @notice Only callable by an address that currently has the admin role.
        @param newBackendSrv Address of new backend srv.
     */
    function setBackendSrv(address newBackendSrv) external onlyBackendSrv {
        _backendSrvAddress = newBackendSrv;
    }

    /**
        @notice Pauses deposits, proposal creation and voting, and deposit executions.
        @notice Only callable by an address that currently has the admin role.
     */
    function adminPauseTransfers() external onlyOwner {
        _pause();
    }

    /**
        @notice Unpauses deposits, proposal creation and voting, and deposit executions.
        @notice Only callable by an address that currently has the admin role.
     */
    function adminUnpauseTransfers() external onlyOwner {
        _unpause();
    }

    /**
        @notice Sets a new resource for handler contracts that use the IERCHandler interface,
        and maps the {handlerAddress} to {resourceID} in {_resourceIDToHandlerAddress}.
        @notice Only callable by an address that currently has the admin role.
        @param handlerAddress Address of handler resource will be set for.
        @param resourceID ResourceID to be used when making deposits.
        @param tokenAddress Address of contract to be called when a deposit is made and a deposited is executed.
     */
    function setResource(
        address handlerAddress,
        bytes32 resourceID,
        address tokenAddress
    ) external onlyBackendSrv {
        _resourceIDToHandlerAddress[resourceID] = handlerAddress;
        IERCHandler handler = IERCHandler(handlerAddress);
        handler.setResource(resourceID, tokenAddress);
        handlers[handlerAddress] = true;
    }

    /**
        @notice sets resourceID for native token
        @dev can only be called through admin address
        @param resourceID resourceID for native token
     */
    function setNativeResourceID(bytes32 resourceID) external onlyBackendSrv {
        _nativeResourceID = resourceID;
    }

    /**
        @notice Sets a resource as burnable for handler contracts that use the IERCHandler interface.
        @notice Only callable by an address that currently has the admin role.
        @param handlerAddress Address of handler resource will be set for.
        @param tokenAddress Address of contract to be called when a deposit is made and a deposited is executed.
     */
    function setBurnable(address handlerAddress, address tokenAddress)
        external
        onlyBackendSrv
    {
        IERCHandler handler = IERCHandler(handlerAddress);
        handler.setBurnable(tokenAddress);
    }

    /**
        @notice Changes deposit fee.
        @notice Only callable by admin.
        @param newFee Value {_fee} will be updated to.
     */
    function changeFee(uint256 newFee) external onlyBackendSrv {
        require(_fee != newFee, "Current fee is equal to new fee");
        _fee = newFee;
    }

    function setBalancerAddress(address newBalancer) external onlyBackendSrv {
        _balancerAddress = newBalancer;
    }

    /**
        @notice Used to manually withdraw funds from ERC safes.
        @param handlerAddress Address of handler to withdraw from.
        @param tokenAddress Address of token to withdraw.
        @param recipient Address to withdraw tokens to.
        @param amountOrTokenID Either the amount of ERC20 tokens or the ERC721 token ID to withdraw.
     */
    function adminWithdraw(
        address handlerAddress,
        address tokenAddress,
        address recipient,
        uint256 amountOrTokenID
    ) external onlyOwner {
        IERCHandler handler = IERCHandler(handlerAddress);
        handler.withdraw(tokenAddress, recipient, amountOrTokenID);
    }

    /**
        @notice Used to approve spending tokens by another handler.
        @param resourceIDOwner ID of owner handler.
        @param resourceIDSpender ID of spender handler.
        @param amountOrTokenID Either the amount of ERC20 tokens or the ERC721 token ID to approve.
     */
    function approveSpending(
        bytes32 resourceIDOwner,
        bytes32 resourceIDSpender,
        uint256 amountOrTokenID
    ) external onlyBackendSrv {
        address handlerOwner = _resourceIDToHandlerAddress[resourceIDOwner];
        require(
            handlerOwner != address(0),
            "resourceIDOwner not mapped to handler"
        );

        address handlerSpender = _resourceIDToHandlerAddress[resourceIDSpender];
        require(
            handlerSpender != address(0),
            "resourceIDSpender not mapped to handler"
        );

        IERCHandler handler = IERCHandler(handlerOwner);
        handler.approve(resourceIDOwner, handlerSpender, amountOrTokenID);
    }

    /**
        @notice Initiates a transfer using a specified handler contract.
        @notice Only callable when Bridge is not paused.
        @param destinationChainID ID of chain deposit will be bridged to.
        @param resourceID ResourceID used to find address of handler to be used for deposit.
        @param amountToLA to be converted to LA with bridge swap.
        @notice Emits {Deposit} event.
     */
    function deposit(
        bytes8 destinationChainID,
        bytes32 resourceID,
        uint256 amount,
        address recipientAddress,
        uint256 amountToLA,
        bytes calldata signature,
        bytes calldata params
    ) external payable whenNotPaused {
        uint64 depositNonce = ++_depositCounts[destinationChainID];
        // bytes memory data =
        bytes32 dataHash = keccak256(
            abi.encode(resourceID, abi.encode(amount, recipientAddress))
        );
        _depositRecords[depositNonce][destinationChainID] = abi.encode(
            amount,
            recipientAddress
        );

        //to verify signer
        // bytes32 messageHash = createMesssageHash(
        //     amount,
        //     recipientAddress,
        //     destinationChainID
        // );
        require(
            verify(
                createMesssageHash(
                    amount,
                    recipientAddress,
                    destinationChainID
                ),
                _balancerAddress,
                signature
            ),
            "Invalid signature"
        );

        address tokenAddress = completeDeposit(
            destinationChainID,
            resourceID,
            amount,
            recipientAddress,
            amountToLA,
            depositNonce,
            params
        );

        if (amountToLA > 0) {
            emit ExtraFeeSupplied(
                _chainID,
                destinationChainID,
                depositNonce,
                resourceID,
                recipientAddress,
                amountToLA
            );
        }

        uint256 stackAmount = amount;

        emit Deposit(
            _chainID,
            destinationChainID,
            resourceID,
            depositNonce,
            msg.sender,
            recipientAddress,
            tokenAddress,
            stackAmount,
            dataHash
        );
    }

    function completeDeposit(
        bytes8 destinationChainID,
        bytes32 resourceID,
        uint256 amount,
        address recipientAddress,
        uint256 amountToLA,
        uint64 depositNonce,
        bytes memory params
    ) internal returns (address tokenAddress) {
        uint256 totalAmount = amount + amountToLA;
        if (getSourceResourceId(resourceID) == _nativeResourceID) {
            require(
                msg.value >= (totalAmount + _fee),
                "Incorrect fee/amount supplied"
            );

            tokenAddress = address(0);
        } else {
            require(msg.value >= _fee, "Incorrect fee supplied");

            address handler = _resourceIDToHandlerAddress[resourceID];
            require(handler != address(0), "resourceID not mapped to handler");

            tokenAddress = IDepositExecute(handler).deposit(
                resourceID,
                destinationChainID,
                depositNonce,
                msg.sender,
                recipientAddress,
                totalAmount,
                params
            );
        }
    }

    // Deposit for AAVE amTokens
    function internalDeposit(
        bytes8 destinationChainID,
        bytes32 resourceID,
        uint256 amount,
        address recipientAddress
    ) public whenNotPaused onlyHandler {
        uint64 depositNonce = ++_depositCounts[destinationChainID];
        bytes memory data = abi.encode(amount, recipientAddress);
        bytes32 dataHash = keccak256(abi.encode(resourceID, data));
        _depositRecords[depositNonce][destinationChainID] = data;

        address handler = _resourceIDToHandlerAddress[resourceID];
        address tokenAddress = IDepositExecute(handler)
            .getAddressFromResourceId(resourceID);

        emit Deposit(
            _chainID,
            destinationChainID,
            resourceID,
            depositNonce,
            msg.sender,
            recipientAddress,
            tokenAddress,
            amount,
            dataHash
        );
    }

    function depositNativeToken(bytes32 resourceID, uint256 amount)
        public
        payable
        whenNotPaused
        onlyHandler
    {
        if (msg.value == 0) {
            // send wrapped native tokens to handler
            address handler = _resourceIDToHandlerAddress[resourceID];
            address wTokenAddress = IDepositExecute(handler)
                .getAddressFromResourceId(resourceID);

            IWETH(wTokenAddress).deposit{value: amount}();
            IWETH(wTokenAddress).transfer(handler, amount);
        }
        // recieve funds
    }

    /**
        @notice Executes a deposit proposal that is considered passed using a specified handler contract.
        @notice Only callable by relayers when Bridge is not paused.
        @param destinationChainID ID of chain where proposal is executed.
        @param resourceID ResourceID to be used when making deposits.
        @param depositNonce ID of deposited generated by origin Bridge contract.
        @notice Proposal must not have executed before.
        @notice Emits {ProposalEvent} event with status {Executed}.
     */
    function executeProposal(
        bytes8 originChainID,
        bytes8 destinationChainID,
        uint64 depositNonce,
        bytes32 resourceID,
        address payable recipientAddress,
        uint256 amount,
        bytes calldata params
    ) external onlyBackendSrv whenNotPaused {
        bytes memory data = abi.encode(amount, recipientAddress);
        bytes32 nonceAndID = keccak256(
            abi.encode(depositNonce, originChainID, destinationChainID)
        );
        bytes32 dataHash = keccak256(abi.encode(resourceID, data));

        require(
            !_executedProposals[nonceAndID][dataHash],
            "proposal already executed"
        );
        require(destinationChainID == _chainID, "ChainID Incorrect");

        _executedProposals[nonceAndID][dataHash] = true;
        bytes32 srcResourceId = getSourceResourceId(resourceID);
        if (srcResourceId == _nativeResourceID) {
            recipientAddress.transfer(amount);
        } else {
            address handler = _resourceIDToHandlerAddress[resourceID];
            require(handler != address(0), "resourceID not mapped to handler");

            IDepositExecute depositHandler = IDepositExecute(handler);
            depositHandler.executeProposal(
                resourceID,
                recipientAddress,
                amount,
                params
            );
        }

        emit ProposalEvent(
            originChainID,
            destinationChainID,
            recipientAddress,
            amount,
            depositNonce,
            ProposalStatus.Executed,
            resourceID,
            dataHash
        );
    }

    /**
        @notice to be called if owner wants to collect fees
        @dev can only be called by owner
        @param amount will be trasnfered to owner if contract balace is higher or equal to amount
    */
    function adminCollectFees(address payable recipient, uint256 amount)
        external
        onlyOwner
    {
        uint256 amountToTransfer = amount < address(this).balance
            ? amount
            : address(this).balance;
        recipient.transfer(amountToTransfer);
    }

    /** 
        @notice to deposit native token to the contract
        @dev to be called by admin
    */
    function depositFunds() external payable onlyOwner {}

    function getSourceResourceId(bytes32 resourceID)
        internal
        returns (bytes32)
    {
        bytes4 swapIdentifier;
        bytes4 chainId;
        bytes12 destinationResourceId;
        bytes12 srcResourceId;

        assembly {
            swapIdentifier := resourceID
            chainId := shl(32, resourceID)
            destinationResourceId := shl(64, resourceID)
            srcResourceId := shl(160, resourceID)
        }
        bytes32[1] memory result = [bytes32(0)];
        assembly {
            mstore(add(result, 20), srcResourceId)
        }
        return result[0];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.4;

import "./ECDSA.sol";

contract VerifySignature {
    using ECDSA for bytes32;

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return _messageHash.toEthSignedMessageHash();
    }

    function verify(
        bytes32 _ethSignedMessageHash,
        address _signer,
        bytes memory _signature
    ) public pure returns (bool) {
        return getSigner(_ethSignedMessageHash, _signature) == _signer;
    }

    function getSigner(bytes32 messageHash, bytes memory signature)
        public
        pure
        returns (address)
    {
        return messageHash.recover(signature);
    }

    function createMesssageHash(
        uint256 amount,
        address recipient,
        bytes8 chainId
    ) public pure returns (bytes32) {
        bytes memory _message = message(amount, recipient, chainId);
        bytes32 msgHash = keccak256(_message);
        return msgHash;
    }

    function message(
        uint256 amount,
        address recipient,
        bytes8 chainId
    ) internal pure returns (bytes memory) {
        bytes memory _message = abi.encode(amount, recipient, chainId);
        return _message;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";

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
abstract contract UpgradableOwnable is Context {
    address private _owner;
    bool public _isInitialised;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
     function ownableInit(address owner) public {
       require(!_isInitialised);
        _owner = owner;
        _isInitialised = true;
        emit OwnershipTransferred(address(0), owner);
     }

     modifier isInitisalised() {
       require(_isInitialised);
       _;
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
        require(owner() == _msgSender(), "sender should be owner");
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
    function transferOwnership(address newOwner)
        public
        virtual
        onlyOwner
    {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * note that this is a stripped down version of open zeppelin's safemath
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
 */

contract SafeMathContract {

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) public pure returns (uint256) {
        return _sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function _sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This is a stripped down version of Open zeppelin's Pausable contract.
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/EnumerableSet.sol
 *
 */
contract Pausable {
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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _whenNotPaused();
        _;
    }

    function _whenNotPaused() private view {
        require(!_paused, "Pausable: paused");
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenPaused() {
        _whenPaused();
        _;
    }

    function _whenPaused() private view {
        require(_paused, "Pausable: not paused");
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
        emit Paused(msg.sender);
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
        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.4;

/**
 * @title Elliptic curve signature operations
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
 *
 * Source https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/79dd498b16b957399f84b9aa7e720f98f9eb83e3/contracts/cryptography/ECDSA.sol
 * This contract is copied here and renamed from the original to avoid clashes in the compiled artifacts
 * when the user imports a zos-lib contract (that transitively causes this contract to be compiled and added to the
 * build/artifacts folder) as well as the vanilla implementation from an openzeppelin version.
 */

library ECDSA {
    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param signature bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(hash, v, r, s);
        }
    }

    /**
     * toEthSignedMessageHash
     * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
     * and hash the result
     */
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
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

pragma solidity 0.6.4;

/**
    @title Interface to be used with handlers that support ERC20s and ERC721s.
 */
interface IERCHandler {
    /**
        @notice Correlates {resourceID} with {contractAddress}.
        @param resourceID ResourceID to be used when making deposits.
        @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
     */
    function setResource(bytes32 resourceID, address contractAddress) external;
    /**
        @notice Marks {contractAddress} as mintable/burnable.
        @param contractAddress Address of contract to be used when making or executing deposits.
     */
    function setBurnable(address contractAddress) external;
    /**
        @notice Used to manually release funds from ERC safes.
        @param tokenAddress Address of token contract to release.
        @param recipient Address to release tokens to.
        @param amountOrTokenID Either the amount of ERC20 tokens or the ERC721 token ID to release.
     */
    function withdraw(address tokenAddress, address recipient, uint256 amountOrTokenID) external;

    /**
        @notice Used to approve spending tokens.
        @param resourceID ResourceID to be used for approval.
        @param spender Spender address.
        @param amountOrTokenID Either the amount of ERC20 tokens or the ERC721 token ID to approve.
     */
    function approve(bytes32 resourceID, address spender, uint256 amountOrTokenID) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}

pragma solidity 0.6.4;

/**
    @title Interface for handler contracts that support deposits and deposit executions.
    @author ChainSafe Systems.
 */
interface IDepositExecute {
    /**
        @notice It is intended that deposit are made using the Bridge contract.
        @param destinationChainID Chain ID deposit is expected to be bridged to.
        @param depositNonce This value is generated as an ID by the Bridge contract.
        @param depositer Address of account making the deposit in the Bridge contract.
     */
    function deposit(
        bytes32 resourceID,
        bytes8 destinationChainID,
        uint64 depositNonce,
        address depositer,
        address recipientAddress,
        uint256 amount,
        bytes calldata params
    ) external returns (address);

    /**
        @notice It is intended that proposals are executed by the Bridge contract.
     */
    function executeProposal(bytes32 resourceID, address recipientAddress, uint256 amount, bytes calldata params) external;
    function getAddressFromResourceId(bytes32 resourceID) external view returns(address);
}

pragma solidity 0.6.4;

/**
    @title Interface for Bridge contract.
    @author ChainSafe Systems.
 */
interface IBridge {
    /**
        @notice Exposing getter for {_chainID} instead of forcing the use of call.
        @return uint8 The {_chainID} that is currently set for the Bridge contract.
     */
    function _chainID() external returns (uint8);

    function internalDeposit(bytes8 destinationChainID,bytes32 resourceID,uint256 amount,address recipientAddress) external;

    function depositNativeToken(bytes32 resourceID, uint256 amount) external payable;
}