// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC20Detailed.sol";

contract TokenSale is Ownable {
    mapping(string => IERC20Detailed) public symbolToToken; // points symbol to token interface
    mapping(string => uint256) public pricePerToken; // WEI price of buy token per sale token

    mapping(string => mapping(address => uint256)) public refundables;
    mapping(address => bool) public canRefund;

    uint256 public ethWeiPricePerToken = 1 ether;

    IERC20Detailed public saleToken;

    event Bought(
        address indexed buyer,
        string indexed usedCommodity,
        uint256 amountInWei
    );

    constructor(address saleTokenAddress) {
        saleToken = IERC20Detailed(saleTokenAddress);
    }

    function buyWithTokens(string memory symbol, uint256 amount) external {
        require(pricePerToken[symbol] > 0, "Token not found");
        IERC20Detailed chosenToken = symbolToToken[symbol];
        uint256 perPrice = pricePerToken[symbol];
        uint256 requiredPayment = perPrice * amount;
        require(
            chosenToken.allowance(msg.sender, address(this)) >= requiredPayment,
            "Not enough allowance given to contract"
        );

        uint256 sentAmount = amount * 10**saleToken.decimals();
        refundables[symbol][msg.sender] = requiredPayment;
        emit Bought(msg.sender, symbol, sentAmount);
        bool success;
        success = chosenToken.transferFrom(
            msg.sender,
            address(this),
            requiredPayment
        );
        require(success, "ERC-20 transfer failed");
        success = saleToken.transfer(msg.sender, sentAmount);
        require(success, "ERC-20 transfer failed");
    }

    function buyWithEth(uint256 amount) external payable {
        uint256 requiredPayment = amount * ethWeiPricePerToken;
        require(msg.value >= requiredPayment, "Not enough ETH value sent");
        uint256 sentAmount = amount * 10**saleToken.decimals();
        refundables["ETH"][msg.sender] = requiredPayment;
        bool success;
        emit Bought(msg.sender, "ETH", sentAmount);
        success = saleToken.transfer(msg.sender, sentAmount);
        require(success, "ERC-20 transfer failed");
    }

    function refund(string memory symbol) external payable returns (bool) {
        require(canRefund[msg.sender], "You are not allowed to refund");
        require(
            refundables[symbol][msg.sender] > 0,
            "No funds found for caller"
        );
        uint256 funds = refundables[symbol][msg.sender];

        if (compareTwoStrings(symbol, "ETH")) {
            refundables[symbol][msg.sender] = 0;
            payable(msg.sender).transfer(funds);
            uint256 boughtTokens = (funds * 10**saleToken.decimals()) /
                ethWeiPricePerToken;
            bool success = saleToken.transferFrom(
                msg.sender,
                address(this),
                boughtTokens
            );
            require(
                success,
                "Failed to receive sale tokens, might be related to allowance"
            );
            return true;
        }

        refundables[symbol][msg.sender] = 0;
        bool _success = symbolToToken[symbol].transfer(msg.sender, funds);
        require(_success, "Failed to send funds");
        uint256 _boughtTokens = (funds * 10**saleToken.decimals()) /
            pricePerToken[symbol];
        _success = saleToken.transferFrom(
            msg.sender,
            address(this),
            _boughtTokens
        );
        require(
            _success,
            "Failed to receive sale tokens, might be related to allowance"
        );
        return true;
    }

    // OWNER FUNCTIONS
    function addNewToken(
        address tokenAddress,
        string memory tokenSymbol,
        uint256 pricePerTkn
    ) external onlyOwner {
        require(pricePerTkn > 0, "Price per token must be more than zero");
        symbolToToken[tokenSymbol] = IERC20Detailed(tokenAddress);
        pricePerToken[tokenSymbol] = pricePerTkn;
    }

    function removeToken(string memory tokenSymbol) external onlyOwner {
        pricePerToken[tokenSymbol] = 0;
    }

    function setSaleToken(address newSaleToken) external onlyOwner {
        saleToken = IERC20Detailed(newSaleToken);
    }

    function setEthPricePerToken(uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Price per token must be more than zero");
        ethWeiPricePerToken = newPrice;
    }

    function withdrawFunds(string memory symbol)
        external
        payable
        onlyOwner
        returns (bool)
    {
        if (compareTwoStrings(symbol, "ETH")) {
            payable(msg.sender).transfer(address(this).balance);
            return true;
        }

        require(pricePerToken[symbol] > 0, "Token not found");
        IERC20Detailed chosenToken = symbolToToken[symbol];
        uint256 balance = chosenToken.balanceOf(address(this));
        bool success = chosenToken.transfer(msg.sender, balance);
        require(success, "ERC-20 transfer failed");
        return true;
    }

    function toggleRefund(address refunder) external onlyOwner {
        canRefund[refunder] = !canRefund[refunder];
    }

    // Internal functions
    function compareTwoStrings(string memory s1, string memory s2)
        internal
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IERC20Detailed {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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