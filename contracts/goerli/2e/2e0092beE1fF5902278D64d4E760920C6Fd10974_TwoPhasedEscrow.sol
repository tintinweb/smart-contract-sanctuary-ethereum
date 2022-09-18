// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//////////////////////////////////////////////////////////////////////////////////////
// @title   2-phased, password-protected escrow contract
// @version 1.0
// @author  H & K
// @dev     This contract is used to send non front-runnable link payments
//          to a recipient address. The recipient address can be arbitrary
//          and is only revealed after claiming the payment.
//          The claimer first locks a deposit for a 100 block timewindow, then
//          has to submit the recipient address and the password to claim the
//          deposit.
//          Sender also has option to withdraw funds at any time, as well as
//          setting a dynamic refundable deposit for the claimer to initate
//          the claim process, to protect against DoS attacks.
// @dev     more from the authors: 
//          https://hugomontenegro.com  https://konradurban.com
//          
//          UNSTOPPABLE APPS FTW!
//////////////////////////////////////////////////////////////////////////////////////
//⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
//
// . .",
//  /\\__//  .~    ~. ",
//  /~ ~ `./      .'",
// {.__,   \  {",
//   / [email protected] )  \\ ",
//   `-` '-' \     }",
//  .(   _(   )_  .'",
// '_ _ _.~---|",
//
//////////////////////////////////////////////////////////////////////////////////////

// imports
import "Strings.sol";

// import "Ownable.sol";

contract TwoPhasedEscrow {
    struct deposit {
        address sender;
        uint256 amount;
        uint256 blockNumber;
        address recipient;
        bytes32 hashedPassword;
        uint256 unlockDepositAmount;
    }

    deposit[] public deposits; // array of deposits

    // events
    event Deposit(
        address indexed sender,
        uint256 amount,
        uint256 depositIdx,
        uint256 unlockDepositAmount
    );
    event Withdraw(
        address indexed recipient,
        uint256 amount,
        uint256 depositIdx
    );

    // ETH B3rlin 2022 celebration event
    event Celebration(string message);

    // constructor
    constructor() {
        // ETH B3rlin 2022 celebration
        emit Celebration("ETH B3rlin 2022 <3");
    }

    // deposit ether to escrow with a hashed password & get deposit index
    function depositEther(bytes32 _hashedPassword, uint256 _unlockDepositAmount)
        public
        payable
        returns (uint256)
    {
        require(msg.value > 0, "deposit must be greater than 0");

        // store new deposit
        deposits.push(
            deposit(
                msg.sender,
                msg.value,
                0,
                address(0),
                _hashedPassword,
                _unlockDepositAmount
            )
        );
        emit Deposit(
            msg.sender,
            msg.value,
            deposits.length - 1,
            _unlockDepositAmount
        );
        return deposits.length - 1;
    }

    // sender can always withdraw deposited assets at any time
    function withdrawEtherSender(uint256 _depositIdx) public {
        require(
            deposits[_depositIdx].sender == msg.sender,
            "only sender can withdraw this deposit"
        );

        // transfer ether back to sender
        payable(msg.sender).transfer(deposits[_depositIdx].amount);
        emit Withdraw(msg.sender, deposits[_depositIdx].amount, _depositIdx);

        // delete deposit
        delete deposits[_depositIdx];
    }

    // claimer lock functionality. Sets the recipient address and opens a 100 block timewindow in which the claimer can withdraw the deposit.
    // Costs some ETH to prevent spamming and DoS attacks. Is later refunded to the sender.
    function openEtherDepositWindow(uint256 _depositIdx) public payable {
        require(
            msg.value >= deposits[_depositIdx].unlockDepositAmount,
            "not enough ETH sent to open deposit window"
        );
        // if the deposit has already been lockeed once, require the window to be over
        if (deposits[_depositIdx].blockNumber > 0) {
            require(
                block.number > deposits[_depositIdx].blockNumber + 100,
                "deposit window still open"
            );
        }

        // set recipient address
        deposits[_depositIdx].recipient = msg.sender;
        // refresh timewindow
        deposits[_depositIdx].blockNumber = block.number;
    }

    // Withdraw with Password functionality. Accepts a password and compares it to the hashed password.
    // If the password is correct, the deposit is transferred to the recipient address.
    function withdrawEtherPassword(uint256 _depositIdx, string memory _password)
        public
    {
        require(
            deposits[_depositIdx].recipient != address(0),
            "recipient address not set"
        );
        require(
            deposits[_depositIdx].blockNumber + 100 > block.number,
            "timewindow expired"
        );
        require(
            deposits[_depositIdx].hashedPassword ==
                keccak256(abi.encodePacked(_password)),
            "wrong password"
        );

        // transfer ether to recipient (plus 0.001 ETH refund)
        payable(deposits[_depositIdx].recipient).transfer(
            deposits[_depositIdx].amount +
                deposits[_depositIdx].unlockDepositAmount
        );
        emit Withdraw(
            deposits[_depositIdx].recipient,
            deposits[_depositIdx].amount,
            _depositIdx
        );

        // delete deposit so it can't be claimed again
        delete deposits[_depositIdx];
    }

    //// Some utility functions ////

    // get deposit info
    function getDeposit(uint256 _depositIdx)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            address,
            bytes32,
            uint256
        )
    {
        return (
            deposits[_depositIdx].sender,
            deposits[_depositIdx].amount,
            deposits[_depositIdx].blockNumber,
            deposits[_depositIdx].recipient,
            deposits[_depositIdx].hashedPassword,
            deposits[_depositIdx].unlockDepositAmount
        );
    }

    // get deposit count
    function getDepositCount() public view returns (uint256) {
        return deposits.length;
    }

    // count deposits for address
    function getEtherDepositsSent(address _sender)
        public
        view
        returns (uint256)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < deposits.length; i++) {
            if (deposits[i].sender == _sender) {
                count++;
            }
        }
        return count;
    }

    // view function to hash a string
    function hashString(string memory _string) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_string));
    }

    // @dev get the password hash for a deposit index
    function getPasswordHash(uint256 _depositIdx)
        public
        view
        returns (bytes32)
    {
        return deposits[_depositIdx].hashedPassword;
    }

    // @dev check if a string is the correct password for a deposit index
    function checkPassword(uint256 _depositIdx, string memory _password)
        public
        view
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(_password)) ==
            deposits[_depositIdx].hashedPassword;
    }

    // and that's all! Have a safe return trip home if you're leaving Berlin!
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