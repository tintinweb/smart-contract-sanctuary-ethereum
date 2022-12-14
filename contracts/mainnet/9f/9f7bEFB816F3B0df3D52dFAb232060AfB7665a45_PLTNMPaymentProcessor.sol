/*
Simple Prepaid Subscription Management Contract using ERC20
2022 Platinum Labs
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@&&&%%%%%%%%%%%###########((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@&&&&&&&&&&&&%%%%%%%%%%%%########@@@@@@@@@@@@@@@(((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@&&&&&&&&&&&%%%%%%%%%%%%%%###&@@@@@@@&&&&@@@@@@@@((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@&&&&&&&&&&&%%@@@@@@@@@@@@@@@@@@@&&&&&&&&&@@@@@@@@((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@&&&&&@@@@@&&&&&&&&&&&&(((((((((((((((((@@@@@@@@@@@@@@@@@@
@@@@@@@@@&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@&&&&&@@@@@@@@@&&&&&&&&&&&&&@(((((((((((((((((@@@@@@@@@@@@@@
@@@@@@@@&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@&&&&&@@@@@@@@@@@@@@@&&&&&&&&&&&&@@@@(((((((((((((((@@@@@@@@@@@
@@@@@@@@&&&&&&&@@@@@@@@@@@@@@@@@@@@@&&&&&@@@@@@@@@@@@@@@@@@@&&&&&&%%%%%%%@@@@(((((((((((((((@@@@@@@@
@@@@@@@@&&&&&&&@@@@@@@@@@@@@@&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@&&&&%%%%%%%%@@@@@(((((((((((((((@@@@@
@@@@@@@@@&&&&&&&@@@@@@@&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&%%%%%%%#@@@@(((((((((((((((@@@
@@@@@@@@@@&&&&&&&@@@@&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&########@@@@((((((((((((((@@
@@@@@@@@@@@&&&&&&&&@@@@&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%&########@@@@@@@((((((((((((((@
@@@@@@@@@@@@@@&&&&&&&@@@@@&&&&&&%%%%%%&@@@@@@@@@@@@@@@@@@@@@@@%%%%%########@@@@@@@@@@@((((((((((((((
@@@@@@@@@@@@@@@@&&&&&&&&@@@@%%%%%%%%%%%%%@@@@@@@@@@@@@@@@@@@#############@@@@@@@@@@@@@((((((((((((((
@@@@@@@@@@@@@@@@@@@&&&&&&&&@@@@%%%%%%%%%%%%@@@@@@@@@@@@@@%#########(((@@@@@@@@@@@@@@@(((((((((((((((
@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&@%%%##########@@@@@@@@@#####((((((((@@@@@@@@@@@@@@@(((((((((((((((((
@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&##########@@@@@((((((((((((@@@@@@@@@@@@@@%(((((((((((((((((((@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&%((((((((((((((((@@@@@@@@@@((((((((((((((((((((((((@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&%%%%%%%%%%%%%##########((((((((((((((((((((((((@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&%%%%%%%%%%%%%##########((((((((((((((((((&@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&%%%%%%%%%%%##########((((((((((((((@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function mint(address to, uint256 amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract PLTNMPaymentProcessor is Ownable {
    IERC20 public token;
    uint256 public cyclePrice;
    uint256 public cycleIntervalUntilValidForRenewal;
    uint256 public renewableTimeBeforeExpiry;
    address private pltnmDepositoryWallet;

    string public productName;

    mapping(address => uint256) public cycleRenewableTimeStamp;
    mapping(address => uint256) public expiryForAddress;

    constructor() {
        productName = "PLATINUM 30 DAY EXTENSION TOOL ACCESS ";
        cyclePrice = 160 * 10**18;
        cycleIntervalUntilValidForRenewal = 25 days;
        renewableTimeBeforeExpiry = 5 days;
        pltnmDepositoryWallet = msg.sender;
        token = IERC20(0xe83341b9D5Cc95f0E0D6b94Ed4820C0F191C51BA);
    }

    function setProductName(string memory _name) external onlyOwner {
        productName = _name;
    }

    function setTokenAddress(address _token) external onlyOwner {
        token = IERC20(_token);
    }

    function setDepositoryWallet(address _address) external onlyOwner {
        pltnmDepositoryWallet = _address;
    }

    function setCyclePrice(uint256 _price) external onlyOwner {
        cyclePrice = _price;
    }

    function setCycleInterVal(uint256 _interval) external onlyOwner {
        cycleIntervalUntilValidForRenewal = _interval;
    }

    function setTimeFromRenewableToExpiry(uint256 _renewableTimeToExpiry)
        external
        onlyOwner
    {
        renewableTimeBeforeExpiry = _renewableTimeToExpiry;
    }

    function getContractTotalSupply() external view returns (uint256) {
        return token.totalSupply();
    }

    function purchaseCycle() external {
        require(
            token.allowance(msg.sender, address(this)) > cyclePrice,
            "You have not approved the required amount on the token contract"
        );
        require(
            block.timestamp > cycleRenewableTimeStamp[msg.sender],
            "You have not yet reached renewal time"
        );
        require(
            token.balanceOf(msg.sender) > cyclePrice,
            "You do not have enough $PLTNM"
        );

        //burn the token
        token.transferFrom(msg.sender, pltnmDepositoryWallet, cyclePrice);

        if (expiryForAddress[msg.sender] < block.timestamp) {
            expiryForAddress[msg.sender] = block.timestamp;
        }

        if (expiryForAddress[msg.sender] == 0) {
            expiryForAddress[msg.sender] = block.timestamp;
        }

        if (cycleRenewableTimeStamp[msg.sender] < block.timestamp) {
            cycleRenewableTimeStamp[msg.sender] = block.timestamp;
        }

        if (cycleRenewableTimeStamp[msg.sender] == 0) {
            cycleRenewableTimeStamp[msg.sender] = block.timestamp;
        }

        cycleRenewableTimeStamp[
            msg.sender
        ] += cycleIntervalUntilValidForRenewal;
        expiryForAddress[msg.sender] =
            cycleRenewableTimeStamp[msg.sender] +
            renewableTimeBeforeExpiry;
    }

    //for third party control
    function purchaseCycleFor(address _address) external {
        require(
            token.allowance(_address, address(this)) > cyclePrice,
            "Address has not approved the required amount on the token contract"
        );
        require(
            block.timestamp > cycleRenewableTimeStamp[_address],
            "Address has not yet reached renewal time"
        );
        require(
            token.balanceOf(_address) > cyclePrice,
            "Address does not have enough $PLTNM"
        );

        //burn the token
        token.transferFrom(_address, pltnmDepositoryWallet, cyclePrice);

        if (expiryForAddress[_address] < block.timestamp) {
            expiryForAddress[_address] = block.timestamp;
        }

        if (expiryForAddress[_address] == 0) {
            expiryForAddress[_address] = block.timestamp;
        }

        if (cycleRenewableTimeStamp[_address] < block.timestamp) {
            cycleRenewableTimeStamp[_address] = block.timestamp;
        }

        if (cycleRenewableTimeStamp[_address] == 0) {
            cycleRenewableTimeStamp[_address] = block.timestamp;
        }

        cycleRenewableTimeStamp[_address] += cycleIntervalUntilValidForRenewal;
        expiryForAddress[_address] =
            cycleRenewableTimeStamp[_address] +
            renewableTimeBeforeExpiry;
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