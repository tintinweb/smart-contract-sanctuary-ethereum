/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
} interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
} abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
} abstract contract Ownable is Context {
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
} contract PhantomPreSale is Ownable {
    using SafeMath for uint256;

    struct UserPreSaleInfo {
        uint256 purchased; //PTM
        uint256 depositAmount; // DAI
    }

    uint256 private constant PRICE = 0.008e9; // PTM token price is 0.008 DAI
    uint256 private constant MAX_BUY = 1000e9; // Max Amout Of Dai user can use for buy
    uint256 private constant MIN_BUY = 250e9; // Min Amount of Dai user can use for buy
    uint256 private constant BUY_PRICE = 1e9; //  1 PTM is equal to 1 FTM

    uint256 private constant PRE_SALE_START = 1648491613; // Presale start date
    uint256 private constant PRE_SALE_END = 1711650013; // Presale end date

    address public treasuryWallet = 0xE37EA092a715E873a0f9Df001b2675f52D88A68A; //Treasury Wallet Address

    mapping(address => UserPreSaleInfo) public userPreSaleInfo; // mapping of UserpresaleInfo struct

    IERC20 public PTM; // PTM Token address
    IERC20 public DAI; // DAI Token address

    bool public preSaleEnd = false; // presle end or not

    event Deposited(address indexed depositor, uint256 indexed amount); //Depoist Event
    event Claimed(address indexed recipient, uint256 payout); // Redemeed

    constructor(IERC20 _PTM, IERC20 _DAI) {
        PTM = _PTM;
        DAI = _DAI;
    }

    function changeTreasuryWallet(address walletAdress) public onlyOwner {
        treasuryWallet = walletAdress;
    }

    function endPreSale(bool value) public onlyOwner {
        preSaleEnd = value;
    }

    function depositAmount(uint256 amount) public {
        require(
            block.timestamp >= PRE_SALE_START &&
                block.timestamp <= PRE_SALE_END,
            "INVALID TIME"
        ); //check dates
        require(!preSaleEnd, "PRESALE END");
        UserPreSaleInfo storage user = userPreSaleInfo[msg.sender];

        user.depositAmount = user.depositAmount.add(amount);
        require(
            amount >= MIN_BUY && user.depositAmount <= MAX_BUY,
            "INVALID AMOUNT"
        );

        uint256 ptmAmount = amount.div(PRICE);
        user.purchased = user.purchased.add(ptmAmount);

        DAI.transferFrom(msg.sender, treasuryWallet, ptmAmount);
        emit Deposited(msg.sender, amount);
    }

    function claim() public {
        require(
            block.timestamp > PRE_SALE_END || preSaleEnd,
            "PRESALE NOT FINISHED"
        ); //check presale end or not
        UserPreSaleInfo storage user = userPreSaleInfo[msg.sender];

        require(user.purchased > 0, "LOW BALANCE");
        uint256 amount = user.purchased;
        user.purchased = 0;
        user.depositAmount = 0;
        PTM.transfer(msg.sender, amount *10**9);
        emit Claimed(msg.sender, amount *10**9);
    }
}