// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Top3Donators is Ownable {
    //the mapping itself holds all data which interacted and spend eth -> need to check, erc721 maybe already has this
    mapping(address => uint256) s_mappedSpentAmount;

    struct donators {
        address donatorAddress;
        uint256 donatorValue;
    }

    event topDonatorsUpdate(donators[3] newTop3Donators);
    event donated(address, uint256);
    event balanceWithdrawn(address, uint256);
    event donationStateChanged(bool);

    bool private s_donationState;
    string private s_contractName;

    donators[3] s_topDonators;

    constructor(string memory _contractName) {
        s_contractName = _contractName;
    }

    function name() public view returns (string memory) {
        return s_contractName;
    }

    function donate() public payable {
        require(s_donationState, "donations are disabled");
        require(msg.value >= 1e15, "amount to low, spend at least 0.001eth");
        uint256 lengthTopDonators = s_topDonators.length; //gas reducing by linking it here and not checking .length multiple times
        //check if address already exists
        if (s_mappedSpentAmount[msg.sender] != 0) {
            //already interacted and send value, so we need to sum up
            s_mappedSpentAmount[msg.sender] += msg.value;

            //search if already exists in top3
            uint256 foundIndexOfDonator = 0;
            for (
                foundIndexOfDonator;
                foundIndexOfDonator < lengthTopDonators;
                ++foundIndexOfDonator
            ) {
                if (
                    s_topDonators[foundIndexOfDonator].donatorAddress ==
                    msg.sender
                ) {
                    //found under top3
                    break;
                }
            }
            if (foundIndexOfDonator < lengthTopDonators) {
                //update existing
                s_topDonators[foundIndexOfDonator]
                    .donatorValue = s_mappedSpentAmount[msg.sender];
                //update needs to lead to reorganizing
                if (msg.sender != s_topDonators[0].donatorAddress) {
                    //reorganisation only needed if updated one is not on top place
                    reorganizeDonators();
                }
                return;
            }
        } else {
            s_mappedSpentAmount[msg.sender] = msg.value;
        }

        //check if new spend amount is in the range of the first 3
        if (
            s_mappedSpentAmount[msg.sender] > s_topDonators[0].donatorValue ||
            s_mappedSpentAmount[msg.sender] > s_topDonators[1].donatorValue ||
            s_mappedSpentAmount[msg.sender] > s_topDonators[2].donatorValue
        ) {
            addNewHighestDonator();
        }
        emit donated(msg.sender, msg.value);
    }

    function reorganizeDonators() private {
        donators memory tmp;

        //find highest value
        for (uint256 j = 0; j < 2; j++) {
            //there can only be one who does not fit in the sequence, so we can archive this by if and else if
            if (s_topDonators[2].donatorValue > s_topDonators[0].donatorValue) {
                tmp = s_topDonators[0];
                s_topDonators[0] = s_topDonators[2];
                s_topDonators[2] = tmp;
            }
            if (s_topDonators[2].donatorValue > s_topDonators[1].donatorValue) {
                tmp = s_topDonators[1];
                s_topDonators[1] = s_topDonators[2];
                s_topDonators[2] = tmp;
            }
            if (s_topDonators[1].donatorValue > s_topDonators[0].donatorValue) {
                tmp = s_topDonators[0];
                s_topDonators[0] = s_topDonators[1];
                s_topDonators[1] = tmp;
            }
        }

        emit topDonatorsUpdate(s_topDonators);
    }

    function addNewHighestDonator() private {
        //check what rank needs to be updated, first come first serve, if you spend as much as nr1 you wont become nr1
        if (s_mappedSpentAmount[msg.sender] > s_topDonators[0].donatorValue) {
            //sender not in list yet, reorder all, [2] gets kicked out
            s_topDonators[2].donatorValue = s_topDonators[1].donatorValue;
            s_topDonators[2].donatorAddress = s_topDonators[1].donatorAddress;

            s_topDonators[1].donatorValue = s_topDonators[0].donatorValue;
            s_topDonators[1].donatorAddress = s_topDonators[0].donatorAddress;

            s_topDonators[0].donatorValue = s_mappedSpentAmount[msg.sender];
            s_topDonators[0].donatorAddress = msg.sender;
        } else if (
            s_mappedSpentAmount[msg.sender] > s_topDonators[1].donatorValue
        ) {
            s_topDonators[2].donatorValue = s_topDonators[1].donatorValue;
            s_topDonators[2].donatorAddress = s_topDonators[1].donatorAddress;

            s_topDonators[1].donatorValue = s_mappedSpentAmount[msg.sender];
            s_topDonators[1].donatorAddress = msg.sender;
        } else if (
            s_mappedSpentAmount[msg.sender] > s_topDonators[2].donatorValue
        ) {
            s_topDonators[2].donatorValue = s_mappedSpentAmount[msg.sender];
            s_topDonators[2].donatorAddress = msg.sender;
        }

        emit topDonatorsUpdate(s_topDonators);
    }

    function getHighestDonators() public view returns (donators[3] memory) {
        return (s_topDonators);
    }

    function getMySpendAmount() public view returns (uint256) {
        return s_mappedSpentAmount[msg.sender];
    }

    function getDonationState() public view returns (bool) {
        return s_donationState;
    }

    function getSpendAmountOfGivenAddress(address _walletAddress)
        public
        view
        returns (uint256)
    {
        require(_walletAddress != address(0), "null address given");
        return (s_mappedSpentAmount[_walletAddress]);
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "contract balance=0");
        emit balanceWithdrawn(msg.sender, address(this).balance);
        payable(msg.sender).transfer(address(this).balance);
    }

    function getBalance() public view returns (uint256) {
        return (address(this).balance);
    }

    function setDonationState(bool _state) public onlyOwner {
        s_donationState = _state;
        emit donationStateChanged(_state);
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