// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./library/TransferHelper.sol";
import "./library/Ownable.sol";
import "./library/ReentrancyGuard.sol";
import "./interface/IERC20.sol";
import "./interface/IWahICO.sol";
import "./interface/OracleWrapper.sol";
import "./interface/WahICOEvents.sol";

contract WahICO is Ownable, ReentrancyGuard, IWahICO, WahICOEvents {
    uint256 public override firstRangeTokenPrice;
    uint256 public override secondRangeTokenPrice;
    uint256 public override thirdRangeTokenPrice;
    IERC20 public USDTInstance;
    IERC20 public tokenInstance;
    uint128 public override firstRangeLimit;
    uint128 public override secondRangeLimit;
    uint256 public override tokenDecimals;
    uint256 public USDTDecimals;
    address public receiverAddress;
    address public override tokenAddress;
    address public USDTaddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public ETHtoUSD = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    constructor(address _tokenAddress, address _receiverAddress) {
        tokenAddress = _tokenAddress;
        receiverAddress = _receiverAddress;
        tokenInstance = IERC20(tokenAddress);
        tokenDecimals = 10**tokenInstance.decimals();
        USDTInstance = IERC20(USDTaddress);
        USDTDecimals = 10**USDTInstance.decimals();
        firstRangeTokenPrice = 9900; // $99
        secondRangeTokenPrice = 9000; // $90
        thirdRangeTokenPrice = 8000; // $80
        firstRangeLimit = 50_000 * uint128(USDTDecimals);
        secondRangeLimit = 100_000 * uint128(USDTDecimals);
    }

    function buyToken(uint8 _type, uint256 amount)
        public
        payable
        override
        nonReentrant
    {
        require(tokenInstance.balanceOf(address(this)) > 0, "No tokens left!");
        uint256 buyAmount;
        if (_type == 1) {
            //for ETH
            buyAmount = msg.value;
        } else {
            // for USDT
            buyAmount = amount;
            require(
                USDTInstance.balanceOf(msg.sender) >= buyAmount,
                "Not enough USDT balance"
            );
            require(
                USDTInstance.allowance(msg.sender, address(this)) >= buyAmount,
                "Allowance for such balance not provided"
            );
        }

        require(buyAmount > 0, "Buy amount should be greater than 0");

        (uint256 tokenAmount, uint256 tokenPrice) = calculateTokens(
            _type,
            buyAmount
        );

        if (_type == 1) {
            TransferHelper.safeTransferETH(receiverAddress, msg.value);
        } else {
            TransferHelper.safeTransferFrom(
                USDTaddress,
                msg.sender,
                receiverAddress,
                buyAmount
            );
        }
        require(
            tokenInstance.balanceOf(address(this)) > tokenAmount,
            "Not enough tokens in contract"
        );
        TransferHelper.safeTransfer(tokenAddress, msg.sender, tokenAmount);

        emit amountBought(
            _type,
            msg.sender,
            buyAmount,
            tokenAmount,
            tokenPrice,
            uint32(block.timestamp)
        );
    }

    receive() external payable {
        payable(receiverAddress).transfer(msg.value);
    }

    function _getUSDTvalue(uint8 _type, uint256 _amount)
        internal
        view
        returns (uint256)
    {
        uint256 _finalUSDTvalue;

        if (_type == 1) {
            uint256 _amountToUSDT = ((OracleWrapper(ETHtoUSD).latestAnswer() *
                USDTDecimals) / 10**8);
            _finalUSDTvalue = (_amount * _amountToUSDT) / (10**18);
        } else {
            _finalUSDTvalue = _amount;
        }
        return _finalUSDTvalue;
    }

    function _getTokenPrice(uint256 amount) internal view returns (uint256) {
        //getting token price with respect to range of USDT
        // first range limit & second range limit is with USDT decimals
        if (amount > 0 && amount <= firstRangeLimit) {
            return firstRangeTokenPrice;
        } else if (amount > firstRangeLimit && amount <= secondRangeLimit) {
            return secondRangeTokenPrice;
        } else {
            return thirdRangeTokenPrice;
        }
    }

    function calculateTokens(uint8 _type, uint256 _amount)
        public
        view
        override
        returns (uint256, uint256)
    {
        uint256 amountInUSDT = _getUSDTvalue(_type, _amount);
        uint256 tokenPrice = _getTokenPrice(amountInUSDT);
        uint256 tokens = (amountInUSDT * 10**2 * tokenDecimals) / //10**2 set as general case for token price
            (tokenPrice * USDTDecimals);

        return (tokens, tokenPrice);
    }

    function getUnclaimedTokens() public onlyOwner nonReentrant {
        uint256 remainingContractBalance = IERC20(tokenAddress).balanceOf(
            address(this)
        );
        require(remainingContractBalance > 0, "All tokens claimed!");

        TransferHelper.safeTransfer(
            tokenAddress,
            receiverAddress,
            remainingContractBalance
        );
    }

    function setFirstRange(
        // range should be set along with USDT decimals
        uint128 _firstRange
    ) external onlyOwner {
        firstRangeLimit = _firstRange;
    }

    function setSecondRange(
        // range should be set along with USDT decimals
        uint128 _secondRange
    ) external onlyOwner {
        secondRangeLimit = _secondRange;
    }

    function setFirstRangeTokenPrice(uint256 _firstRangeTokenPrice)
        external
        onlyOwner
    {
        require(
            _firstRangeTokenPrice != firstRangeTokenPrice,
            "New token price is same as before"
        );

        firstRangeTokenPrice = _firstRangeTokenPrice;
    }

    function setSecondRangeTokenPrice(uint256 _secondRangeTokenPrice)
        external
        onlyOwner
    {
        require(
            _secondRangeTokenPrice != secondRangeTokenPrice,
            "New token price is same as before"
        );

        secondRangeTokenPrice = _secondRangeTokenPrice;
    }

    function setThirdRangeTokenPrice(uint256 _thirdRangeTokenPrice)
        external
        onlyOwner
    {
        require(
            _thirdRangeTokenPrice != thirdRangeTokenPrice,
            "New token price is same as before"
        );

        thirdRangeTokenPrice = _thirdRangeTokenPrice;
    }

    function setReceiverAddress(address _newReceiverAddress)
        external
        onlyOwner
    {
        require(
            _newReceiverAddress != address(0),
            "Zero address cannot be passed"
        );
        receiverAddress = _newReceiverAddress;
    }

    function setETHtoUSDaddress(address _ETHtoUSDaddress) external onlyOwner {
        require(
            _ETHtoUSDaddress != address(0),
            "Zero address cannot be passed"
        );
        ETHtoUSD = _ETHtoUSDaddress;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.7;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        _setOwner(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function _setOwner(address newOwner) internal {
        owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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
     * by making the `nonReentrant` function external, and make it call a
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
pragma solidity ^0.8.7;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

    function decimals() external view returns (uint256);
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IWahICO {
    function firstRangeTokenPrice() external view returns (uint256);

    function secondRangeTokenPrice() external view returns (uint256);

    function firstRangeLimit() external view returns (uint128);

    function secondRangeLimit() external view returns (uint128);

    function thirdRangeTokenPrice() external view returns (uint256);

    function tokenDecimals() external view returns (uint256);

    function tokenAddress() external view returns (address);

    function buyToken(uint8, uint256) external payable;

     function calculateTokens(uint8 _type, uint256 _amount)
        external
        returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface OracleWrapper {
    function latestAnswer() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface WahICOEvents {
    event amountBought(
        uint8 _type,
        address buyerAddress,
        uint256 buyAmount,
        uint256 tokenAmount,
        uint256 tokenPrice,
        uint256 timestamp
    );

}