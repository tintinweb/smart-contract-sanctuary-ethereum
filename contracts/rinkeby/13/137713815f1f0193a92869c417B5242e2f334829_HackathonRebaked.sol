//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./libraries/TransferHelper.sol";
import "./IHackathon.sol";
import "./AddressSet.sol";

contract HackathonRebaked is IHackathon, Ownable, ReentrancyGuard {

    // Add the library methods
    using AddressSet for AddressSet.Set;
    using SafeERC20 for IERC20;

    struct HackathonData {
        AddressSet.Set tokenSet; // set address token for hackathon
        mapping(address => uint256) totalMoneyDeposited; //  token address -> money
        mapping(address => uint256) totalMoneyDistributed; //  token address -> money
        mapping(string => uint256) resultCount; // prize id -> number of winner already received prize
        mapping(address => bool) isJoined; // user address -> bool
        mapping(string => Prize) prizeFor; // prize id -> prize
    }

    uint256 public fee = 5; // 5%
    uint256 public constant feeDenominator = 10000;
    uint256 public timeForWithdrawUnclaimed = 72 hours;
    address payable public adminReceiver;

    mapping(string => HackathonData) private hData; // hackathon id -> HackathonData
    mapping(string => Hackathon) public hackathon; // hackathon id -> hackathon

    modifier validLength(uint256 _a, uint256 _b, uint256 _c, uint256 _d) {
        require(_a == _b && _a == _c && _a == _d, "Invalid length");
        _;
    }

    modifier onlyHackathonOwner(string memory _hackathonId) {
        require(hackathon[_hackathonId].owner == _msgSender(), "Only owner");
        _;
    }

    modifier existHackathon(string memory _hackathonId) {
        require(bytes(hackathon[_hackathonId].id).length != 0, "Not exists");
        _;
    }

    constructor(address admin) {
        adminReceiver = payable(admin);
        transferOwnership(admin);
    }

    function addressToString(address _addr) public pure returns(string memory) 
    {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";
    
        bytes memory str = new bytes(51);
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

    // create a hackathon
    function createHackathon(
        CreateHackathonInput memory _createHackathonInput
    ) payable external override
    nonReentrant
    validLength(_createHackathonInput.arrId.length, _createHackathonInput.arrToken.length, _createHackathonInput.arrValue.length, _createHackathonInput.arrNumberOfReceiver.length)
    {
        require(bytes(hackathon[_createHackathonInput.hackathonId].id).length == 0, "Already exists");
        uint256 totalRewardETH;
        uint256 totalPrizeCount;
        for (uint256 index = 0; index < _createHackathonInput.arrId.length; index++) {
            require(_createHackathonInput.arrNumberOfReceiver[index] > 0, "Must have receiver");

            Prize memory tmpPrize = getPrizeInfo(_createHackathonInput.hackathonId, _createHackathonInput.arrId[index]);
            require(tmpPrize.value == 0, "Invalid Prize list");

            uint256 totalValue = _createHackathonInput.arrValue[index] * _createHackathonInput.arrNumberOfReceiver[index];
            if(_createHackathonInput.arrToken[index] != address(0)) {
                uint256 balanceBefore = IERC20(_createHackathonInput.arrToken[index]).balanceOf(address(this));
                
                IERC20(_createHackathonInput.arrToken[index]).safeTransferFrom(_msgSender(), address(this), totalValue);

                uint256 balanceAfter = IERC20(_createHackathonInput.arrToken[index]).balanceOf(address(this));
                require(balanceAfter - balanceBefore >= totalValue, string(abi.encodePacked("This token ", Strings.toHexString(uint256(uint160(_createHackathonInput.arrToken[index])), 20), " is not supported in this system. Please try to use another token.")));

                hData[_createHackathonInput.hackathonId].totalMoneyDeposited[_createHackathonInput.arrToken[index]] += totalValue;
            }
            else{
                totalRewardETH += totalValue;
            }
            
            // set prize for hackathon
            setPrizeInfo(_createHackathonInput.hackathonId, _createHackathonInput.arrId[index], _createHackathonInput.arrToken[index], _createHackathonInput.arrValue[index], _createHackathonInput.arrNumberOfReceiver[index]);

            // increase total prize count 
            totalPrizeCount += _createHackathonInput.arrNumberOfReceiver[index];

            // add token list for hackathon
            hData[_createHackathonInput.hackathonId].tokenSet.add(_createHackathonInput.arrToken[index]);
            
        }

        require(totalRewardETH == msg.value, "Invalid ETH Reward");
        if(msg.value > 0){
            hData[_createHackathonInput.hackathonId].totalMoneyDeposited[address(0)] += msg.value;
        }
    
        hackathon[_createHackathonInput.hackathonId].totalPrizeCountLeft = totalPrizeCount;
        hackathon[_createHackathonInput.hackathonId].id = _createHackathonInput.hackathonId;
        hackathon[_createHackathonInput.hackathonId].owner = payable(_msgSender());
        hackathon[_createHackathonInput.hackathonId].url = _createHackathonInput.url;
        emit Created(_createHackathonInput.hackathonId, _createHackathonInput.url, _msgSender(), _createHackathonInput.arrId, _createHackathonInput.arrToken, _createHackathonInput.arrValue, _createHackathonInput.arrNumberOfReceiver);
    }

    // Send prizes to user
    function sendPrizes(
        string memory _hackathonId,
        string[] memory _arrId,
        address[] memory _addressWinner,
        string[] memory _submitionId
    ) external override nonReentrant existHackathon(_hackathonId) onlyHackathonOwner(_hackathonId) {
        require(_arrId.length == _addressWinner.length && _arrId.length == _submitionId.length, "Invalid length");

        Hackathon memory tmpHackathon = getHackathonInfo(_hackathonId);
        
        require(_arrId.length <= tmpHackathon.totalPrizeCountLeft, "Invalid number of prizes distributed");
        require(tmpHackathon.closedAt == 0, "Hackathon was closed");

        Prize memory localPrize;

        for (uint16 index = 0; index < _arrId.length; index++) {
            address payable winnerAddress = payable(_addressWinner[index]);

            //check user already joined to hackathon
            require(getAlreadyJoined(_hackathonId, _addressWinner[index]), "Invalid winner");
            
            localPrize = getPrizeInfo(_hackathonId, _arrId[index]);
            require(localPrize.value > 0, "Should send crypto prizes");
            require(hData[_hackathonId].resultCount[_arrId[index]] < localPrize.numberOfReceiver, "Invalid number for prizes");

            // increase winner for that prize
            hData[_hackathonId].resultCount[_arrId[index]]++;

            // collect admin fee
            uint256 adminFee = localPrize.value * fee / 100;

            // increase total money distributed
            hData[_hackathonId].totalMoneyDistributed[localPrize.token] += localPrize.value;

            if(localPrize.token == address(0)){
                TransferHelper.safeTransfer(adminReceiver, adminFee);
                TransferHelper.safeTransfer(winnerAddress, localPrize.value - adminFee);
            }
            else{
                IERC20(localPrize.token).safeTransfer(adminReceiver, adminFee);
                IERC20(localPrize.token).safeTransfer(winnerAddress, localPrize.value - adminFee);
            }
        }
        //reduce total prize can send to winner
        hackathon[_hackathonId].totalPrizeCountLeft -= _arrId.length;
        emit DistributedPrizes(_hackathonId, _arrId, _addressWinner, _submitionId);
    }

    // close hackathon and let hackathon owner claimed their money back
    function close(string memory _hackathonId) external override onlyOwner existHackathon(_hackathonId) {
        Hackathon memory tmpHackathon = getHackathonInfo(_hackathonId);
        require(hackathon[_hackathonId].closedAt == 0, "Hackathon was closed");
        require(tmpHackathon.totalPrizeCountLeft > 0, "All prize was distributed");
        hackathon[_hackathonId].closedAt = block.timestamp;
        emit Close(_hackathonId);
    }

    function setAdminReceiver(address newReceiver) external override onlyOwner{
        require(newReceiver != address(0), "Invalid receiver");
        adminReceiver = payable(newReceiver);
        emit SetAdminReceiver(newReceiver);
    }

    // Withdraw unclaimed money from a hackathon
    function withdrawUnclaimed(string memory _hackathonId) external override nonReentrant existHackathon(_hackathonId) {
        Hackathon memory tmpHackathon = getHackathonInfo(_hackathonId);
        require(tmpHackathon.owner == _msgSender(), "Must be owner of this hackathon");
        require(!tmpHackathon.isWithdraw, "Already withdraw");
        require(tmpHackathon.closedAt > 0, "Hackathon was not closed");
        require(block.timestamp >= tmpHackathon.closedAt + timeForWithdrawUnclaimed, "Must wait");

        for (uint256 index = 0; index < hData[_hackathonId].tokenSet.length(); index++) {
            address tokenAddr = hData[_hackathonId].tokenSet.at(index);

            uint256 tmpValue = hData[_hackathonId].totalMoneyDeposited[tokenAddr] - hData[_hackathonId].totalMoneyDistributed[tokenAddr];
            if(tmpValue == 0) continue;
            
            if(tokenAddr == address(0)){
                TransferHelper.safeTransfer(tmpHackathon.owner, tmpValue);
            }
            else{
                IERC20(tokenAddr).safeTransfer(tmpHackathon.owner, tmpValue);
            }
        }

        hackathon[_hackathonId].isWithdraw = true;
        emit WithdrawUnclaimed(_hackathonId);
    }

        // Join to a hackathon
    function join(string memory _hackathonId) external override existHackathon(_hackathonId) {
        require(!getAlreadyJoined(_hackathonId, _msgSender()), "Already joined");
        hData[_hackathonId].isJoined[_msgSender()] = true;
        emit Joined(_hackathonId, _msgSender());
    }

    // Set fee of hackathon
    function setFee(uint256 _newFee) external override onlyOwner {
        require(fee != _newFee, "Must change to new value");
        require(_newFee >=0 && _newFee <=100, "Must between 0 and 100");
        fee = _newFee;
        emit SetFee(_newFee);
    }

    // Set time of withdraw unclaimed in hackathon
    function setTime(uint256 _newTime) external override onlyOwner {
        require(timeForWithdrawUnclaimed != _newTime, "Must change to new value");
        timeForWithdrawUnclaimed = _newTime;
        emit SetFee(_newTime);
    }

    // set data prize of hackathon
    function setPrizeInfo(string memory _hackathonId, string memory _prizeId, address _token, uint256 _value, uint16 _numberReceiver) private {
        hData[_hackathonId].prizeFor[_prizeId].token = _token;
        hData[_hackathonId].prizeFor[_prizeId].value = _value;
        hData[_hackathonId].prizeFor[_prizeId].numberOfReceiver = _numberReceiver;
    }

    // get is user already joined in a hackathon 
    function getAlreadyJoined(string memory _hackathonId, address _user) public override view returns(bool) {
        return hData[_hackathonId].isJoined[_user];
    }

    // get data prize of hackathon
    function getPrizeInfo(string memory _hackathonId, string memory _prizeId) public override view returns(Prize memory) {
        return hData[_hackathonId].prizeFor[_prizeId];
    }

    function getHackathonInfo(string memory _hackathonId) public override view returns(Hackathon memory) {
        return hackathon[_hackathonId];
    }

    function getTotalMoneyDeposited(string memory _hackathonId, address tokenAddress) external override view returns(uint256) {
        return hData[_hackathonId].totalMoneyDeposited[tokenAddress];
    }
    function getTotalMoneyDistributed(string memory _hackathonId, address tokenAddress) external override view returns(uint256) {
        return hData[_hackathonId].totalMoneyDistributed[tokenAddress];
    }
    function getResultCount(string memory _hackathonId, string memory pId) external override view returns(uint256) {
        return hData[_hackathonId].resultCount[pId];
    }
    function getIsJoined(string memory _hackathonId, address user) external override view returns(bool) {
        return hData[_hackathonId].isJoined[user];
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library TransferHelper {
    function safeTransfer(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: TRANSFER_FAILED");
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

interface IHackathon {
    struct Prize {
        address token;
        uint256 value;
        uint16 numberOfReceiver;
    }

    struct Hackathon {
        string id;
        string url;
        uint256 totalPrizeCountLeft;
        uint256 closedAt;
        address payable owner;
        bool isWithdraw;
    }

    event Created(
        string hackathonId,
        string url,
        address owner,
        string[] arrId,
        address[] arrToken,
        uint256[] arrValue,
        uint16[] arrNumberOfReceiver
    );
    event Joined(string hackathonId, address userAddress);
    event DistributedPrizes(
        string hackathonId,
        string[] arrId,
        address[] addressWinner,
        string[] submitionId
    );
    event SetFee(uint256 indexed newFee);
    event SetTime(uint256 indexed newTime);
    event SetAdminReceiver(address newReceiver);
    event WithdrawUnclaimed(string hackathonId);
    event Close(string hackathonId);

    function createHackathon(
        CreateHackathonInput memory createHackathonInput
    ) external payable;

    function withdrawUnclaimed(string memory hackathonId) external;

    function sendPrizes(
        string memory hackathonId,
        string[] memory arrId,
        address[] memory addressWinner,
        string[] memory submitionId
    ) external;

    function join(string memory hackathonId) external;

    function close(string memory hackathonId) external;

    function setFee(uint256 newFee) external;

    function setTime(uint256 newTime) external;

    function setAdminReceiver(address newReceiver) external;

    function getAlreadyJoined(string memory hackathonId, address user)
        external
        view
        returns (bool);

    function getPrizeInfo(string memory hackathonId, string memory _prizeId)
        external
        view
        returns (Prize memory);

    function getHackathonInfo(string memory hackathonId)
        external
        view
        returns (Hackathon memory);

    function getTotalMoneyDeposited(
        string memory hackathonId,
        address tokenAddress
    ) external view returns (uint256);

    function getTotalMoneyDistributed(
        string memory hackathonId,
        address tokenAddress
    ) external view returns (uint256);

    function getResultCount(string memory hackathonId, string memory pId)
        external
        view
        returns (uint256);

    function getIsJoined(string memory hackathonId, address user)
        external
        view
        returns (bool);
}

struct CreateHackathonInput {
    string hackathonId;
    string url;
    string[] arrId;
    address[] arrToken;
    uint256[] arrValue;
    uint16[] arrNumberOfReceiver;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

library AddressSet {

    struct Set {
        address[] values;
        mapping (address => bool) isIn;
    }

    function add(Set storage s, address addr) public {
        if (!s.isIn[addr]) {
            s.values.push(addr);
            s.isIn[addr] = true;
        }
    }

    function at(Set storage s, uint256 index) public view returns(address){
        return s.values[index];
    }

    function length(Set storage s) public view returns(uint256){
        return s.values.length;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}