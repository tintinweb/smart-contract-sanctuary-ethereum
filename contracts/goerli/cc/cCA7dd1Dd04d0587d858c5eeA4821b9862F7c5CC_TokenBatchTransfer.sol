pragma solidity ^0.8.0;

import {SafeMath} from "../libraries/helpers/SafeMath.sol";
import {TransferHelper} from "../libraries/helpers/TransferHelper.sol";
import {IERC20} from "../libraries/openzeppelin/token/ERC20/IERC20.sol";

contract TokenBatchTransfer {

    using TransferHelper for address;
    using TransferHelper for IERC20;
    using SafeMath for uint256;

    event BatchTransfer(address  token, uint256 total);
    event TokenWithdrawn(address token, address operator, address to, uint256 total);
    event TokenSent(address from, address to, uint256 value);
    
    address public owner;
    uint256 public txFee = 0 ether;

    function initialize() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    function setTxFee(uint256 _fee) onlyOwner public {
        txFee = _fee;
    }

    function withdrawETH(address _to) external onlyOwner {
        require(_to != address(0), "invalid amount");

        uint256 _balance = address(this).balance;
        address(_to).safeTransferETH(_balance);
        
        emit TokenWithdrawn(0x0000000000000000000000000000000000000000, msg.sender, _to, _balance);
    }

    function withdrawToken(address _tokenAddress, address _to) external onlyOwner {
        require(_to != address(0), "invalid amount");

        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(_to, balance);

        emit TokenWithdrawn(_tokenAddress, msg.sender, _to, balance);
    }

    function ethSend(address[] memory _to, uint256[] memory _value) internal {
        uint256 remainingValue = msg.value;
        require(_to.length == _value.length, "invalid array");
        require(_to.length <= 255, "invalid array");

        for (uint8 i = 0; i < _to.length; i++) {
            remainingValue = remainingValue.sub(_value[i]);
            address(_to[i]).safeTransferETH(_value[i]);
            emit TokenSent(msg.sender, _to[i], _value[i]);
        }
        require(remainingValue >= txFee, "invalid amount");

        emit BatchTransfer(0x0000000000000000000000000000000000000000, msg.value);
    }

    function tokenSend(address _tokenAddress, address[] memory _to, uint256[] memory _value) internal {
        uint sendValue = msg.value;
        require(sendValue >= txFee, "invalid amount");

        uint256 sendAmount = 0;
        require(_to.length == _value.length, "invalid array");
        require(_to.length <= 255, "invalid array");

        IERC20 token = IERC20(_tokenAddress);
        for (uint8 i = 0; i < _to.length; i++) {
            sendAmount = sendAmount.add(_value[i]);
            token.safeTransferFrom(msg.sender, _to[i], _value[i]);
            emit TokenSent(msg.sender, _to[i], _value[i]);
        }
        emit BatchTransfer(_tokenAddress, sendAmount);
    }

    function batchTransfer(address[] memory _to, uint256[] memory _value) payable public {
        ethSend(_to, _value);
    }

    function batchTransferToken(address _tokenAddress, address[] memory _to, uint256[] memory _value) payable public {
        tokenSend(_tokenAddress, _to, _value);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import {IERC20} from "./../openzeppelin/token/ERC20/IERC20.sol";
import {IERC721} from "./../openzeppelin/token/ERC721/IERC721.sol";
import {IWETH} from "./../../interfaces/IWETH.sol";

library TransferHelper {
    // for ERC20
    function balanceOf(address token, address addr)
        internal
        view
        returns (uint256)
    {
        return IERC20(token).balanceOf(addr);
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)'))) -> 0xa9059cbb
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)'))) -> 0x23b872dd
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransferFrom: transfer failed"
        );
    }

    // for ETH or WETH transfer
    function safeTransferETH(address to, uint256 value) internal {
        // Here increase the gas limit a reasonable amount above the default, and try
        // to send ETH to the recipient.
        // NOTE: This might allow the recipient to attempt a limited reentrancy attack.
        (bool success, ) = address(to).call{value: value, gas: 30000}("");
        require(success, "TransferHelper: Sending ETH failed");
    }

    function balanceOfETH(address addr) internal view returns (uint256) {
        return addr.balance;
    }

    function safeTransferETHOrWETH(
        address weth,
        address to,
        uint256 value
    ) internal {
        // Here increase the gas limit a reasonable amount above the default, and try
        // to send ETH to the recipient.
        // NOTE: This might allow the recipient to attempt a limited reentrancy attack.
        (bool success, ) = address(to).call{value: value, gas: 30000}("");
        if (!success) {
            // can claim ETH via the WETH contract (similar to escrow).
            IWETH(weth).deposit{value: value}();
            safeTransfer(IERC20(weth), to, value);
            // At this point, the recipient can unwrap WETH.
        }
    }

    function swapAndTransferWETH(
        address weth,
        address to,
        uint256 value
    ) internal {
        // can claim ETH via the WETH contract (similar to escrow).
        IWETH(weth).deposit{value: value}();
        safeTransfer(IERC20(weth), to, value);
    }

    // Will attempt to transfer ETH, but will transfer WETH instead if it fails.
    function swapETH2WETH(address weth, uint256 value) internal {
        if (value > 0) {
            IWETH(weth).deposit{value: value}();
        }
    }

    function swapWETH2ETH(address weth, uint256 value) internal {
        if (value > 0) {
            IWETH(weth).withdraw(value);
        }
    }

    // Will attempt to transfer ETH, but will transfer WETH instead if it fails.
    function sendWETH2ETH(
        address weth,
        address to,
        uint256 value
    ) internal {
        if (value > 0) {
            IWETH(weth).withdraw(value);
            safeTransferETHOrWETH(weth, to, value);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    /**
     * @dev Raises `a` to the `b`th power, throws on overflow.
     */
    function pow(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a**b;
        assert(c >= a);
        return c;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {

    function deposit() external payable;

    function withdraw(uint) external;

    function approve(address, uint) external returns(bool);

    function transfer(address, uint) external returns(bool);

    function transferFrom(address, address, uint) external returns(bool);

    function balanceOf(address) external view returns(uint);

}