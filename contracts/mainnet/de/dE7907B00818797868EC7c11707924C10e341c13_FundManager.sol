// SPDX-License-Identifier: MIT

// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddxxxxddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxdol:;,''....'',;:lodxxxxxxxxxxxxxxxxxxxxxdlc;,''....'',;:codxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxdc;'.                .';ldxxxxxxxxxxxxxxdl;'.                ..;cdxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxdl;.                        .;ldxxxxxxxxxo;.                        .;ldxxxxxxxxxxxxxx
// xxxxxxxxxxxxxl,.                            .,lxxxxxxo;.                            .'ldxxxxxxxxxxxx
// xxxxxxxxxxxo;.                                .,lddo;.                                .;oxxxxxxxxxxx
// xxxxxxxxxxo'                                    ....                                    'lxxxxxxxxxx
// xxxxxxxxxl'                             .                   .                            .lxxxxxxxxx
// xxxxxxxxo,                             'c,.              .,c'                             'oxxxxxxxx
// xxxxxxxxc.                             .lxl,.          .,ldo.                             .:xxxxxxxx
// xxxxxxxd,                              .:xxxl,.      .,ldxxc.                              'oxxxxxxx
// xxxxxxxo'                               ,dxxxxl,.  .,ldxxxd;                               .lxxxxxxx
// xxxxxxxo.                               .oxxxxxxl::ldxxxxxo'                               .lxxxxxxx
// xxxxxxxd,                               .cxxxxxxxxxxxxxxxxl.                               'oxxxxxxx
// xxxxxxxx:.           ..                  ;xxxxxxxxxxxxxxxx:                  ..            ;dxxxxxxx
// xxxxxxxxo'           ''                  'oxxxxxxxxxxxxxxd,                  .'           .lxxxxxxxx
// xxxxxxxxxc.          ;,                  .lxxxxxxxxxxxxxxo.                  ';.         .cxxxxxxxxx
// xxxxxxxxxxc.        .c,                  .:xxxxxxxxxxxxxxc.                  'c.        .cdxxxxxxxxx
// xxxxxxxxxxxl'       'l,       ..          ,dxxxxxxxxxxxxd;          ..       'l,       'lxxxxxxxxxxx
// xxxxxxxxxxxxd:.     ;o,       .'          .oxxxxxxxxxxxxo'          ..       'o:.    .:dxxxxxxxxxxxx
// xxxxxxxxxxxxxxd:.  .cd,       .;.         .cxxxxxxxxxxxxl.         .,'       'ol.  .:oxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxo:.,od,       .:.          ;xxxxxxxxxxxx:          .:'       'oo,.:oxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxdodd,       .l,          'dxxxxxxxxxxd,          'l'       'oxodxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxd;       .l:.         .lxxxxxxxxxxo.          :o'       ,dxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxd:.     .ol.         .:xxxxxxxxxxc.         .co'     .:oxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxd:.   .oo'          ;dxxxxxxxxd;          .oo'   .:oxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxo:. .od;          'oxxxxxxxxo'          ,do' .:oxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxd::oxc.         .cxxxxxxxxl.         .:xd::oxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxl.          ;xxxxxxxx:.         .lxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd;          'dxxxxxxd,          ,dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd:.        .lxxxxxxo.        .:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd:.      .cxxxxxxc.      .:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo:.     ;dxxxxd;     .:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd:.   'oxxxxo'   .:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo:. .cxxxxl. .:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo:'cxxxxc,:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddxxxxddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
//
// MEGAMI https://www.megami.io/

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Implementation of the Fund Manager contract that allows funds to split to contributors.
 */
contract FundManager is Ownable {

    /**
     * @dev 100% in bases point
     */
    uint256 private constant HUNDRED_PERCENT_IN_BASIS_POINTS = 10000;
    
    /**
     * @dev Struct managing the receivers and their share (percentage basis points).
     */
    struct FundReceiver { 
        address payable receiver;
        uint96 sharePercentageBasisPoints;
    }
    /**
     * @dev Receivers whom FundManager are sending funds through withdraw function to.
     */
    FundReceiver[] private _fundReceivers;

    /**
     * @dev For receiving fund in case someone try to send it.
     */
    receive() external payable {}

    /**
     * @dev Register new receivers and their share.
     * @param receivers The list of new receivers and their share.
     */
    function setFeeReceivers(FundReceiver[] calldata receivers) external onlyOwner {
        uint256 receiversLength = receivers.length;
        require(receiversLength > 0, "at least one receiver is necessary");
        require(receiversLength <= 50, "too many receivers");
        uint256 totalPercentageBasisPoints = 0;
        delete _fundReceivers;
        for(uint256 i = 0; i < receiversLength;) {
            require(receivers[i].receiver != address(0), "receiver address can't be null");
            require(receivers[i].sharePercentageBasisPoints != 0, "share percentage basis points can't be 0");
            _fundReceivers.push(FundReceiver(receivers[i].receiver, receivers[i].sharePercentageBasisPoints));

            totalPercentageBasisPoints += receivers[i].sharePercentageBasisPoints;

            unchecked { ++i; }
        }
        require(totalPercentageBasisPoints == HUNDRED_PERCENT_IN_BASIS_POINTS, "total share percentage basis point isn't 10000");
    }

    /**
     * @dev Return the list of fee receivers
     */
    function getFeeReceivers() external view returns (FundReceiver[] memory) {
        return _fundReceivers;
    }

    /**
     * @dev Send funds to registered receivers based on their share.
     *      If there is remainders, they are sent to the receiver registered at first (index 0).
     */
    function withdraw() external onlyOwner {
        require(_fundReceivers.length != 0, "receivers haven't been specified yet");

        uint256 sendingAmount = address(this).balance;
        uint256 receiversLength = _fundReceivers.length;
        if(receiversLength > 1) {
            for(uint256 i = 1; i < receiversLength;) {
                uint256 transferAmount = (sendingAmount * _fundReceivers[i].sharePercentageBasisPoints) / HUNDRED_PERCENT_IN_BASIS_POINTS;
                (bool sent, ) = _fundReceivers[i].receiver.call{value: transferAmount}("");
                require(sent, "transfer failed");
                unchecked { ++i; }
            }
        }

        // Remainder is sent to the first receiver
        (bool sentRemainder, ) = _fundReceivers[0].receiver.call{value: address(this).balance}("");
        require(sentRemainder, "transfer failed");
    }

    /**
     * @dev Allow owner to send funds directly to recipient. This is for emergency purpose and use regular withdraw.
     * @param recipient The address of the recipinet.
     */
    function emergencyWithdraw(address recipient) external onlyOwner {
        require(recipient != address(0), "recipient shouldn't be 0");

        (bool sent, ) = recipient.call{value: address(this).balance}("");
        require(sent, "failed to withdraw");
    }

    /**
     * @dev ERC20s should not be sent to this contract, but if someone does, it's nice to be able to recover them.
     *      Copied from ForgottenRunesWarriorsGuild. Thank you dotta ;)
     * @param token IERC20 the token address
     * @param amount uint256 the amount to send
     */
    function forwardERC20s(IERC20 token, uint256 amount) public onlyOwner {
        token.transfer(msg.sender, amount);
    }

    /**
     * @dev Do nothing for disable renouncing ownership.
     */ 
    function renounceOwnership() public override onlyOwner {}     
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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