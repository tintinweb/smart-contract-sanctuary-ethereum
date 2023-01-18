// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "../libraries/OwnableWithdrawable.sol";
import "../libraries/TransferHelper.sol";

contract AntfarmSale is OwnableWithdrawable {
    // Initial: just deployed, owner needs to start public sale
    // Public: any investor can deposit ETH
    // Success: sale reached the softcap, owner can withdraw ETH deposited
    // Cancel: sale didn't reach the softcap, anyone can withdraw
    // Final: if success, users can claim their ATF
    enum Status {
        Initial,
        Public,
        Success,
        Cancel,
        Final
    }

    // Default value is the first element listed in
    // definition of the type, in this case "Initial"
    Status public status;

    address public immutable antfarmToken;

    uint256 public constant ATF_TO_SELL = 3_000_000 * 10**18;

    // Sale caps, Ether
    uint256 public immutable softcap;
    uint256 public immutable hardcap;

    uint256 public totalAmount;

    uint256 public startTime;

    // Var states balances and whitelist
    mapping(address => uint256) public investedAmount;

    error IncorrectStatus();
    error AmountNotAllowed();
    error SoftcapNotReached();
    error SoftcapReached();
    error CantCancelYet();

    constructor(
        address _antfarmToken,
        uint256 _softcap,
        uint256 _hardcap
    ) {
        require(_antfarmToken != address(0), "ZERO_ADDRESS");
        require(_softcap > 0 && _hardcap > 0, "CAPS_NULL");

        antfarmToken = _antfarmToken;
        softcap = _softcap;
        hardcap = _hardcap;

        startTime = block.timestamp;
    }

    modifier isStatus(Status _status) {
        if (status != _status) revert IncorrectStatus();
        _;
    }

    function startPublicSale() external onlyOwner isStatus(Status.Initial) {
        status = Status.Public;
    }

    function investPublic() external payable isStatus(Status.Public) {
        if (msg.value + totalAmount >= hardcap) revert AmountNotAllowed();

        investedAmount[msg.sender] += msg.value;
        totalAmount += msg.value;
    }

    function setSuccess() external onlyOwner isStatus(Status.Public) {
        if (totalAmount < softcap) revert SoftcapNotReached();
        status = Status.Success;
    }

    function setCancel() external onlyOwner isStatus(Status.Public) {
        if (totalAmount > softcap) revert SoftcapReached();
        status = Status.Cancel;
    }

    function publicSetCancel() external isStatus(Status.Public) {
        if (totalAmount > softcap) revert SoftcapReached();
        if (startTime + 4 weeks > block.timestamp) revert CantCancelYet();
        status = Status.Cancel;
    }

    function withdrawEth() external isStatus(Status.Cancel) {
        uint256 amountInvested = investedAmount[msg.sender];
        investedAmount[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amountInvested}("");
        require(success, "Transfer failed.");
    }

    function claimEther() external onlyOwner isStatus(Status.Success) {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setFinal() external onlyOwner isStatus(Status.Success) {
        status = Status.Final;
    }

    function claimTokens() external isStatus(Status.Final) {
        uint256 amount = investedAmount[msg.sender];
        investedAmount[msg.sender] = 0;
        TransferHelper.safeTransfer(
            antfarmToken,
            msg.sender,
            (ATF_TO_SELL * amount) / totalAmount
        );
    }

    fallback() external payable {
        revert();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/TransferHelper.sol";
import "../interfaces/IERC20.sol";

contract OwnableWithdrawable is Ownable {
    function withdrawToken(address _token, uint256 _amount) external onlyOwner {
        TransferHelper.safeTransfer(_token, owner(), _amount);
    }

    function withdrawTotalTokenBalance(address _token) external onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        TransferHelper.safeTransfer(_token, owner(), amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes("approve(address,uint256)")));
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
        // bytes4(keccak256(bytes("transfer(address,uint256)")));
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
        // bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
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
pragma solidity =0.8.10;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
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