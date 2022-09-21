// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BloomTreasure {
    address private DAI;
    address private USDC;
    address private USDT;
    IERC20 private dai;
    IERC20 private usdc;
    IERC20 private usdt;
    struct Token {
        uint256 balance;
        address[] payers;
    }
    struct Treasure {
        Token eth;
        Token dai;
        Token usdt;
        Token usdc;
    }
    string[] private tokens = ["ETH", "DAI", "USDC", "USDT"];
    address[] private owners;
    uint256 private percentage = 10000000000000000;
    Treasure treasure;

    constructor(
        address[] memory _owners,
        address _dai,
        address _usdc,
        address _usdt
    ) {
        //Set an array of owners that can withdraw the balance
        owners = _owners;
        DAI = _dai;
        dai = IERC20(DAI);
        USDT = _usdt;
        usdt = IERC20(USDT);
        USDC = _usdc;
        usdc = IERC20(USDC);
    }

    function addOwner(address newOwner) public {
        bool isOwner = checkOwnership(owners, msg.sender);
        if (!isOwner) {
            revert("You are not an owner");
        } else {
            owners.push(newOwner);
        }
    }

    function amIAnOwner(address addressToCheck) public view returns (bool) {
        //Check if the caller is an owner
        bool ownership = checkOwnership(owners, addressToCheck);
        return ownership;
    }

    function calculateFee(uint256 amount) public view returns (uint256) {
        return (amount * percentage) / 100000000000000000000;
    }

    function fundTreasureWithETH(address sender) external payable {
        treasure.eth.balance += msg.value;
        treasure.eth.payers.push(sender);
    }

    function fundTreasureWithToken(
        string memory token,
        uint256 amount,
        address funder
    ) public {
        if (compareStrings(token, "DAI")) {
            require(
                dai.transferFrom(funder, address(this), amount),
                "Fee payment failed"
            );
            require(dai.approve(address(this), amount), "DAI approval failed");
            treasure.dai.balance += amount;
            treasure.dai.payers.push(msg.sender);
        }
        if (compareStrings(token, "USDC")) {
            require(
                usdc.transferFrom(funder, address(this), amount),
                "Fee payment failed"
            );
            require(
                usdc.approve(address(this), amount),
                "USDC approval failed"
            );
            treasure.usdc.balance += amount;
            treasure.usdc.payers.push(msg.sender);
        }
        if (compareStrings(token, "USDT")) {
            require(
                usdt.transferFrom(funder, address(this), amount),
                "Fee payment failed"
            );
            require(
                usdt.approve(address(this), amount),
                "USDT approval failed"
            );
            treasure.usdt.balance += amount;
            treasure.usdt.payers.push(msg.sender);
        }
    }

    function getPublicBalanceOfETH() public view returns (uint256) {
        return treasure.eth.balance;
    }

    function getPublicBalanceOfDAI() public view returns (uint256) {
        return treasure.dai.balance;
    }

    function getPublicBalanceOfUSDT() public view returns (uint256) {
        return treasure.usdt.balance;
    }

    function getPublicBalanceOfUSDC() public view returns (uint256) {
        return treasure.usdc.balance;
    }

    function withdraw(string memory tokenToRetrieve, uint256 amountToRetrieve)
        public
    {
        bool isOwner = false;
        isOwner = checkOwnership(owners, msg.sender);
        require(isOwner, "You are not an owner");
        if (compareStrings(tokenToRetrieve, "ETH")) {
            require(
                amountToRetrieve < treasure.eth.balance,
                "Not enough ETH in the treasure"
            );
            payable(msg.sender).transfer(amountToRetrieve);
            treasure.eth.balance -= amountToRetrieve;
        }
        if (compareStrings(tokenToRetrieve, "DAI")) {
            require(
                amountToRetrieve < treasure.dai.balance,
                "Not enough DAI in the treasure"
            );
            require(
                dai.transferFrom(address(this), msg.sender, amountToRetrieve),
                "DAI transfer failed"
            );
            require(
                dai.approve(address(this), amountToRetrieve),
                "DAI approve failed"
            );
            treasure.dai.balance -= amountToRetrieve;
        }
        if (compareStrings(tokenToRetrieve, "USDC")) {
            require(
                amountToRetrieve < treasure.usdc.balance,
                "Not enough USDC in the treasure"
            );
            require(
                usdc.transferFrom(address(this), msg.sender, amountToRetrieve),
                "USDC transfer failed"
            );
            require(
                usdc.approve(address(this), amountToRetrieve),
                "USDC approve failed"
            );
            treasure.usdc.balance -= amountToRetrieve;
        }
        if (compareStrings(tokenToRetrieve, "USDT")) {
            require(
                amountToRetrieve < treasure.usdt.balance,
                "Not enough USDT in the treasure"
            );
            require(
                usdt.transferFrom(address(this), msg.sender, amountToRetrieve),
                "USDT transfer failed"
            );
            require(
                usdt.approve(address(this), amountToRetrieve),
                "USDT approve failed"
            );
            treasure.usdt.balance -= amountToRetrieve;
        }
    }

    function checkOwnership(address[] memory _owners, address sender)
        internal
        pure
        returns (bool)
    {
        bool isOwner = false;
        for (uint256 j = 0; j < _owners.length; j++) {
            if (_owners[j] == sender) {
                isOwner = true;
            }
        }
        return isOwner;
    }

    function compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
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