// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./interfaces/IGate.sol";
import "./UsingHelpers.sol";

/**
 * @notice Gate contract between Boson router for conditional commits
 *
 * Enables conditional commit, where the user must be a
 * holder of a specific token, which can be either ERC20,
 * ERC721, or ERC1155
 */


interface Token {
    function balanceOf(address account) external view returns (uint256); //ERC-721 and ERC-20
    function ownerOf(uint256 _tokenId) external view returns (address); //ERC-721
}

interface MultiToken {
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

contract Gate is IGate, Ownable, Pausable {

    enum TokenType {FUNGIBLE_TOKEN, NONFUNGIBLE_TOKEN, MULTI_TOKEN} // ERC20, ERC721, ERC1155

    event LogConditionalContractSet(
        address indexed _conditionalToken,
        TokenType indexed _conditionalTokenType,
        address indexed _triggeredBy
    );

    event LogBosonRouterSet(
        address indexed _bosonRouter,
        address indexed _triggeredBy
    );

    event LogVoucherSetRegistered(
        uint256 indexed _tokenIdSupply,
        uint256 indexed _conditionalTokenId,
        Condition _condition,
        uint256 threshold
    );

    event LogUserVoucherDeactivated(
        address indexed _user,
        uint256 indexed _tokenIdSupply
    );

    mapping(uint256 => ConditionalCommitInfo) private voucherSetToConditionalCommit;
    mapping(address => mapping(uint256 => bool)) private isDeactivated; // user => voucherSet => bool

    TokenType private conditionalTokenType;
    address private conditionalTokenContract;
    address private bosonRouterAddress;
  
    /**
     * @notice Constructor
     * @param _bosonRouterAddress - address of the associated BosonRouter contract instance
     * @param _conditionalToken - address of the conditional token
     * @param _conditionalTokenType - the type of the conditional token
     */
    constructor(
        address _bosonRouterAddress,
        address _conditionalToken,
        TokenType _conditionalTokenType
    )
    notZeroAddress(_conditionalToken)
    notZeroAddress(_bosonRouterAddress)
    {
        bosonRouterAddress = _bosonRouterAddress;
        conditionalTokenContract = _conditionalToken;
        conditionalTokenType = _conditionalTokenType;

        emit LogBosonRouterSet(_bosonRouterAddress, msg.sender);
        emit LogConditionalContractSet(_conditionalToken, _conditionalTokenType, msg.sender);
    }

    modifier onlyFromRouter() {
        require(msg.sender == bosonRouterAddress, "UNAUTHORIZED_BR"); 
        _;
    }

    modifier onlyRouterOrOwner() {
        require(msg.sender == bosonRouterAddress || msg.sender == owner(), "UNAUTHORIZED_O_BR"); 
        _;
    }

    /**
     * @notice  Checking if a non-zero address is provided, otherwise reverts.
     */
    modifier notZeroAddress(address _tokenAddress) {
        require(_tokenAddress != address(0), "0A"); //zero address
        _;
    }

    /**
     * @notice Get the token ID and Condition associated with the supply token ID (voucherSetID)
     * @param _tokenIdSupply an ID of a supply token (ERC-1155) [voucherSetID]
     * @return conditional token ID if one is associated with a voucher set. Zero could be a valid token ID
     * @return condition that will be checked when a user commits using a conditional token
     * @return threshold that may be checked when a user commits using a conditional token
     */
    function getConditionalCommitInfo(uint256 _tokenIdSupply) external view returns (uint256, Condition, uint256) {
        ConditionalCommitInfo storage conditionalCommitInfo = voucherSetToConditionalCommit[_tokenIdSupply];
        return (
            conditionalCommitInfo.conditionalTokenId,
            conditionalCommitInfo.condition,
            conditionalCommitInfo.threshold
        );
    }

    /**
     * @notice Sets the contract, where gate contract checks if user holds conditional token
     * @param _conditionalToken address of a conditional token contract
     * @param _conditionalTokenType type of token
     */
    function setConditionalTokenContract(
        address _conditionalToken,
        TokenType _conditionalTokenType
    ) external onlyOwner notZeroAddress(_conditionalToken) whenPaused {
        conditionalTokenContract = _conditionalToken;
        conditionalTokenType = _conditionalTokenType;
        emit LogConditionalContractSet(_conditionalToken, _conditionalTokenType, msg.sender);
    }

    /**
     * @notice Gets the contract address, where gate contract checks if user holds conditional token
     * @return address of conditional token contract
     * @return type of conditional token contract
     */
    function getConditionalTokenContract() external view returns (address, TokenType) {
        return (
            conditionalTokenContract,
            conditionalTokenType
        );
    }

    /**
     * @notice Sets the Boson router contract address, from which deactivate is accepted
     * @param _bosonRouterAddress address of the boson router contract
     */
    function setBosonRouterAddress(address _bosonRouterAddress)
        external
        onlyOwner
        notZeroAddress(_bosonRouterAddress)
        whenPaused
    {
        bosonRouterAddress = _bosonRouterAddress;
        emit LogBosonRouterSet(_bosonRouterAddress, msg.sender);
    }

    /**
     * @notice Registers connection between setID and specific MultiToken tokenID
     *
     * Not necessary if the conditional token is not MultiToken (i.e, ERC1155)
     *
     * @param _tokenIdSupply an ID of a supply token (ERC-1155) [voucherSetID]
     * @param _conditionalCommitInfo struct that contains data pertaining to conditional commit:
     *
     * uint256 conditionalTokenId - Id of the conditional token, ownership of which is a condition for committing to redeem a voucher
     * in the voucher set created by this function.
     *
     * uint256 threshold - the number that the balance of a tokenId must be greater than or equal to. Not used for OWNERSHIP condition
     *
     * Condition condition - condition that will be checked when a user commits using a conditional token
     *
     * address gateAddress - address of a gate contract that will handle the interaction between the BosonRouter contract and the conditional token,
     * ownership of which is a condition for committing to redeem a voucher in the voucher set created by this function.
     *
     * bool registerConditionalCommit - indicates whether Gate.registerVoucherSetId should be called. Gate.registerVoucherSetId can also be called separately
     */
    function registerVoucherSetId(uint256 _tokenIdSupply, ConditionalCommitInfo calldata _conditionalCommitInfo)
        external
        override
        whenNotPaused
        onlyRouterOrOwner
    {
        require(_tokenIdSupply != 0, "INVALID_TOKEN_SUPPLY");
        
        
        if(_conditionalCommitInfo.condition == Condition.OWNERSHIP) {
            require(conditionalTokenType == TokenType.NONFUNGIBLE_TOKEN, "CONDITION_NOT_AVAILABLE_FOR_TOKEN_TYPE");
        } else {
            require(_conditionalCommitInfo.threshold != 0, "INVALID_THRESHOLD");
        }

        voucherSetToConditionalCommit[_tokenIdSupply] = _conditionalCommitInfo;

        emit LogVoucherSetRegistered(_tokenIdSupply, _conditionalCommitInfo.conditionalTokenId, _conditionalCommitInfo.condition, _conditionalCommitInfo.threshold);
    }

    /**
     * @notice Checks if user possesses the required conditional token for given voucher set
     * @param _user user address
     * @param _tokenIdSupply an ID of a supply token (ERC-1155) [voucherSetID]
     * @return true if user possesses conditional token, and the token is not deactivated
     */
    function check(address _user, uint256 _tokenIdSupply)
        external
        view
        override
        returns (bool)
    {
       ConditionalCommitInfo memory conditionalCommitInfo = voucherSetToConditionalCommit[_tokenIdSupply];

        if(conditionalCommitInfo.condition == Condition.NOT_SET) {
            return false;
        }

        return conditionalCommitInfo.condition == Condition.OWNERSHIP
                ? checkOwnership(_user, _tokenIdSupply, conditionalCommitInfo.conditionalTokenId)
                : checkBalance(_user, _tokenIdSupply, conditionalCommitInfo.conditionalTokenId, conditionalCommitInfo.threshold);


    }

    /**
     * @notice Stores information that certain user already claimed
     * @param _user user address
     * @param _tokenIdSupply an ID of a supply token (ERC-1155) [voucherSetID]
     */
    function deactivate(address _user, uint256 _tokenIdSupply)
        external
        override
        whenNotPaused
        onlyFromRouter
    {
        isDeactivated[_user][_tokenIdSupply] = true;

        emit LogUserVoucherDeactivated(_user, _tokenIdSupply);
    }

    /**
     * @notice Pause register and deactivate
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the contract and allows register and deactivate
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Checks if user possesses the required balance of the conditional token for given voucher set
     * @param _user user address
     * @param _tokenIdSupply an ID of a supply token (ERC-1155) [voucherSetID]
     * @param _conditionalTokenId an ID of a conditional token
     * @param _threshold the number that the balance must be greater than or equal to
     * @return true if user possesses conditional token, and the token is not deactivated
     */
    function checkBalance(address _user, uint256 _tokenIdSupply, uint256 _conditionalTokenId, uint256 _threshold)
        internal
        view
        returns (bool)
    {
        return
            !isDeactivated[_user][_tokenIdSupply] &&
            ((conditionalTokenType == TokenType.MULTI_TOKEN)
                ? MultiToken(conditionalTokenContract).balanceOf(_user, _conditionalTokenId)
                : Token(conditionalTokenContract).balanceOf(_user)
            ) >= _threshold;
    }

     /**
     * @notice Checks if user owns a specific token Id. Only for ERC-721 tokens
     * @param _user user address
     * @param _tokenIdSupply an ID of a supply token (ERC-1155) [voucherSetID]
     * @param _conditionalTokenId an ID of a conditional token
     * @return true if user possesses conditional token, and the token is not deactivated
     */
    function checkOwnership(address _user, uint256 _tokenIdSupply, uint256 _conditionalTokenId)
        internal
        view
        returns (bool)
    {
        return
            !isDeactivated[_user][_tokenIdSupply] &&
            (Token(conditionalTokenContract).ownerOf(_conditionalTokenId) == _user);
         
    }
        

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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

pragma solidity ^0.7.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
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
        emit Paused(_msgSender());
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
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity 0.7.6;
pragma abicoder v2;

import "./../UsingHelpers.sol";

interface IGate {
    /**
     * @notice Registers connection between setID and tokenID
     * @param _tokenIdSupply an ID of a supply token (ERC-1155)
     * @param _conditionalCommitInfo struct that contains data pertaining to conditional commit:
     *
     * uint256 conditionalTokenId - Id of the conditional token, ownership of which is a condition for committing to redeem a voucher
     * in the voucher set created by this function.
     *
     * uint256 threshold - the number that the balance of a tokenId must be greater than or equal to. Not used for OWNERSHIP condition
     *
     * Condition condition - condition that will be checked when a user commits using a conditional token
     *
     * address gateAddress - address of a gate contract that will handle the interaction between the BosonRouter contract and the conditional token,
     * ownership of which is a condition for committing to redeem a voucher in the voucher set created by this function.
     *
     * bool registerConditionalCommit - indicates whether Gate.registerVoucherSetId should be called. Gate.registerVoucherSetId can also be called separately
     */
    function registerVoucherSetId(
        uint256 _tokenIdSupply,
        ConditionalCommitInfo calldata _conditionalCommitInfo
    ) external;

    /**
     * @notice Checks if user possesses the required conditional token for given voucher set
     * @param _user user address
     * @param _tokenIdSupply an ID of a supply token (ERC-1155) [voucherSetID]
     * @return true if user possesses conditional token, and the token is not deactivated
     */
    function check(address _user, uint256 _tokenIdSupply)
        external
        view
        returns (bool);

    /**
     * @notice Stores information that certain user already claimed
     * @param _user user address
     * @param _tokenIdSupply an ID of a supply token (ERC-1155) [voucherSetID]
     */
    function deactivate(address _user, uint256 _tokenIdSupply) external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity 0.7.6;

// Those are the payment methods we are using throughout the system.
// Depending on how to user choose to interact with it's funds we store the method, so we could distribute its tokens afterwise
enum PaymentMethod {
    ETHETH,
    ETHTKN,
    TKNETH,
    TKNTKN
}

enum Entity {ISSUER, HOLDER, POOL}

enum VoucherState {FINAL, CANCEL_FAULT, COMPLAIN, EXPIRE, REFUND, REDEEM, COMMIT}
/*  Status of the voucher in 8 bits:
    [6:COMMITTED] [5:REDEEMED] [4:REFUNDED] [3:EXPIRED] [2:COMPLAINED] [1:CANCELORFAULT] [0:FINAL]
*/

enum Condition {NOT_SET, BALANCE, OWNERSHIP} //Describes what kind of condition must be met for a conditional commit

struct ConditionalCommitInfo {
    uint256 conditionalTokenId;
    uint256 threshold;
    Condition condition;
    address gateAddress;
    bool registerConditionalCommit;
}

uint8 constant ONE = 1;

struct VoucherDetails {
    uint256 tokenIdSupply;
    uint256 tokenIdVoucher;
    address issuer;
    address holder;
    uint256 price;
    uint256 depositSe;
    uint256 depositBu;
    PaymentMethod paymentMethod;
    VoucherStatus currStatus;
}

struct VoucherStatus {
    address seller;
    uint8 status;
    bool isPaymentReleased;
    bool isDepositsReleased;
    DepositsReleased depositReleased;
    uint256 complainPeriodStart;
    uint256 cancelFaultPeriodStart;
}

struct DepositsReleased {
    uint8 status;
    uint248 releasedAmount;
}

/**
    * @notice Based on its lifecycle, voucher can have many different statuses. Checks whether a voucher is in Committed state.
    * @param _status current status of a voucher.
    */
function isStateCommitted(uint8 _status) pure returns (bool) {
    return _status == determineStatus(0, VoucherState.COMMIT);
}

/**
    * @notice Based on its lifecycle, voucher can have many different statuses. Checks whether a voucher is in RedemptionSigned state.
    * @param _status current status of a voucher.
    */
function isStateRedemptionSigned(uint8 _status)
    pure
    returns (bool)
{
    return _status == determineStatus(determineStatus(0, VoucherState.COMMIT), VoucherState.REDEEM);
}

/**
    * @notice Based on its lifecycle, voucher can have many different statuses. Checks whether a voucher is in Refunded state.
    * @param _status current status of a voucher.
    */
function isStateRefunded(uint8 _status) pure returns (bool) {
    return _status == determineStatus(determineStatus(0, VoucherState.COMMIT), VoucherState.REFUND);
}

/**
    * @notice Based on its lifecycle, voucher can have many different statuses. Checks whether a voucher is in Expired state.
    * @param _status current status of a voucher.
    */
function isStateExpired(uint8 _status) pure returns (bool) {
    return _status == determineStatus(determineStatus(0, VoucherState.COMMIT), VoucherState.EXPIRE);
}

/**
    * @notice Based on its lifecycle, voucher can have many different statuses. Checks the current status a voucher is at.
    * @param _status current status of a voucher.
    * @param _idx status to compare.
    */
function isStatus(uint8 _status, VoucherState _idx) pure returns (bool) {
    return (_status >> uint8(_idx)) & ONE == 1;
}

/**
    * @notice Set voucher status.
    * @param _status previous status.
    * @param _changeIdx next status.
    */
function determineStatus(uint8 _status, VoucherState _changeIdx)
    pure
    returns (uint8)
{
    return _status | (ONE << uint8(_changeIdx));
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