//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CommiteeMoney is Ownable {
    uint256 public fixedDepositAmount = 0.01 ether;
    uint256 public totalAllowedParticipants = 10;
    uint256 public commiteeReward = 0.1 ether;
    uint256 public lastCommiteeOpenDate;
    address[] public commiteeMembers;
    mapping(address => uint256) memberToLastpayment;
    address[] public commiteeWinners;

    // Start comite by owner
    function startCommitee() external onlyOwner {
        require(commiteeMembers.length == 0, "Commitee already started");
        lastCommiteeOpenDate = block.timestamp;
    }

    // open comitee by owner using random hash
    function openCommitee()
        external
        onlyOwner
        returns (address winner, bool commiteeFinished)
    {
        require(
            commiteeMembers.length == totalAllowedParticipants,
            "Participants not enough"
        );
        require(hasEveryonePaid(), "Not everyone paid");
        // get random from not those who got last opened pay
        address[] memory notWonMembers = getNotWonMembers();
        uint256 randNumForNotWin = uint256(
            keccak256(abi.encodePacked(msg.sender, block.timestamp))
        ) % notWonMembers.length;

        address payable randomAddress = payable(
            notWonMembers[randNumForNotWin]
        );

        // pay that random and update that member received payment.
        randomAddress.transfer(commiteeReward);
        commiteeWinners.push(randomAddress);
        memberToLastpayment[randomAddress] = block.timestamp;
        // update last payment date
        lastCommiteeOpenDate = block.timestamp;
        if (commiteeWinners.length == totalAllowedParticipants) {
            clearCommitee();
            return (randomAddress, true);
        }
        return (randomAddress, false);
    }

    // Clear Commitee
    function clearCommitee() public onlyOwner {
        commiteeMembers = new address[](0);
        commiteeWinners = new address[](0);
        lastCommiteeOpenDate = block.timestamp;
    }

    // receive monetary payment from member
    function receivePayment() external payable {
        // if user paid then leave;
        require(hasPaid(msg.sender), "You already paid");
        require(msg.value <= fixedDepositAmount, "Payment is not enough");
        if (isUserInCommitee(msg.sender)) {
            _userPaymentReceived(msg.sender, msg.value);
        } else {
            require(
                commiteeMembers.length < totalAllowedParticipants,
                "Commitee is full"
            );
            _userPaymentReceived(msg.sender, msg.value);
            commiteeMembers.push(msg.sender);
        }
    }

    function _userPaymentReceived(address _sender, uint256 _amount) private {
        if (_amount > fixedDepositAmount) {
            payable(_sender).transfer(msg.value - fixedDepositAmount);
        }
        memberToLastpayment[msg.sender] = block.timestamp;
    }

    function hasPaid(address _member) public view returns (bool) {
        return memberToLastpayment[_member] > lastCommiteeOpenDate;
    }

    function isUserInCommitee(address _member) public view returns (bool) {
        for (uint256 i = 0; i < commiteeMembers.length; i++) {
            if (commiteeMembers[i] == _member) {
                return true;
            }
        }
        return false;
    }

    function hasEveryonePaid() public view returns (bool) {
        for (uint256 i = 0; i < commiteeMembers.length; i++) {
            if (!hasPaid(commiteeMembers[i])) {
                return false;
            }
        }
        return true;
    }

    function getNotWonMembers() public view returns (address[] memory) {
        address[] memory notWonMembers;
        uint256 counter = 0;
        for (uint256 i = 0; i < commiteeMembers.length; i++) {
            if (!hasWon(commiteeMembers[i])) {
                notWonMembers[counter] = commiteeMembers[i];
                counter++;
            }
        }
        return notWonMembers;
    }

    function hasWon(address _member) public view returns (bool) {
        for (uint256 i = 0; i < commiteeWinners.length; i++) {
            if (commiteeWinners[i] == _member) {
                return true;
            }
        }
        return false;
    }

    function balanceOf() public view returns (uint256) {
        return address(this).balance;
    }

    function setFixedDepositAmount(uint256 _amount) external onlyOwner {
        fixedDepositAmount = _amount;
    }

    function setCommiteeReward(uint256 _amount) external onlyOwner {
        commiteeReward = _amount;
    }

    function setAllowedParticipants(uint256 _amount) external onlyOwner {
        totalAllowedParticipants = _amount;
    }

    function destroyContract() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }
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