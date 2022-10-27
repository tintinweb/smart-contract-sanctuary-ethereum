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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import './token/Base64.sol';
import './token/Proxy.sol';
import './token/ERC721Enumerable.sol';
import "./interfaces/dydx/DydxFlashloanBase.sol";
import "./interfaces/dydx/ICallee.sol";
import "./interfaces/nftfi/INftfiLoan.sol";
import "./interfaces/nftfi/LoanData.sol";
import "./interfaces/IWETH.sol";
import './utils/TokenLogic.sol';

contract Refinance is ERC721Enumerable, Vault, DydxFlashloanBase {
  using Base64 for *;
  using Strings for uint256;

  address constant NFTFiLoan = 0xf896527c49b44aAb3Cf22aE356Fa3AF8E331F280;
  address constant SOLO = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;
  address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  struct RefinanceData {
    uint256 tokenId;
    uint32 loanId;
    address[4] tokens; // [0] - borrowCToken, [1] - borrowUnderlying(0x00 is eth), [2] - supplyCToken, [3] - supplyUnderlying
    uint256[] supplyTokenIds;
  }

  bool public initialized;

  mapping(uint256 => TokenLogic) public proxies;

  address public tokenLogic;
  RefinanceData refinanceData;

  function initialize(address _tokenLogic) external onlyOwner {
    require(!initialized);
    initialized = true;

    name = 'Drops Refinance';
    symbol = 'DROPSRFN';

    tokenLogic = _tokenLogic;
  }

  function setTokenLogic(address _tokenLogic) external onlyOwner {
    tokenLogic = _tokenLogic;
  }

  function mint() public returns(uint256) {
    uint256 tokenId = totalSupply + 1;
    Proxy proxy = new Proxy();
    proxy.setImplementation(tokenLogic);
    proxies[tokenId] = TokenLogic(payable(proxy));
    _mint(msg.sender, tokenId);
    return tokenId;
  }

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    require(ownerOf[tokenId] != address(0), 'tokenURI: Non-existent token');

    string memory attributes = string(
      abi.encodePacked('[{"trait_type":"Author","value":"Drops DAO"}]')
    );

    return
      string(
        abi.encodePacked(
          'data:application/json;base64,',
          Base64.encode(
            abi.encodePacked(
              '{"name":"',
              string(abi.encodePacked('Drops Refinance', ' #', tokenId.toString())),
              '","description":"',
              'This NFT represents refinancing position at Drops protocol',
              '","image":"',
              'https://ambassador.mypinata.cloud/ipfs/Qmf1z56YX8dPJKmC6VfQioxJrBFKPX3x9aMC2bbSqTcar5',
              '","attributes":',
              attributes,
              '}'
            )
          )
        )
      );
  }

  function refinance(
    uint256 tokenId,
    uint32 loanId,
    address[4] calldata tokens,
    uint256[] calldata supplyTokenIds
  ) external {
    require(refinanceData.tokenId == 0, 'Invalid entrance');
    require(ownerOf[tokenId] == msg.sender, 'Invalid access');
    require(refinanceData.loanId == 0, 'Invalid loanId');

    if (tokenId == 0) {
      tokenId = mint();
    } else {
      require(ownerOf[tokenId] == msg.sender, 'Invalid access');
    }

    refinanceData.tokenId = tokenId;
    refinanceData.loanId = loanId;
    refinanceData.tokens = tokens;
    refinanceData.supplyTokenIds = supplyTokenIds;

    ISoloMargin solo = ISoloMargin(SOLO);

    INftfiLoan nftfiLoan = INftfiLoan(NFTFiLoan);
    uint payOffAmount = nftfiLoan.getPayoffAmount(loanId);

    address borrowToken;
    if (refinanceData.tokens[1] == address(0)) {
      borrowToken = WETH;
    } else {
      borrowToken = refinanceData.tokens[1];
    }

    // Get marketId from token address
    /*
    0	WETH
    1	SAI
    2	USDC
    3	DAI
    */
    uint marketId = _getMarketIdFromTokenAddress(SOLO, borrowToken);

    // Calculate repay amount (_amount + (2 wei))
    uint repayAmount = _getRepaymentAmountInternal(payOffAmount);

    /*
    1. Withdraw
    2. Call callFunction()
    3. Deposit back
    */

    Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

    operations[0] = _getWithdrawAction(marketId, payOffAmount);
    operations[1] = _getCallAction(abi.encodePacked(bytes1(0x00)));
    operations[2] = _getDepositAction(marketId, repayAmount);

    Account.Info[] memory accountInfos = new Account.Info[](1);
    accountInfos[0] = _getAccountInfo();
    solo.operate(accountInfos, operations);
  }

  function callFunction(
      address sender,
      Account.Info memory account,
      bytes memory data
  ) public {
    require(msg.sender == SOLO, "!dydx solo");
    require(sender == address(this), "!this contract");

    INftfiLoan nftfiLoan = INftfiLoan(NFTFiLoan);
    uint payOffAmount = nftfiLoan.getPayoffAmount(refinanceData.loanId);

    LoanData.LoanTerms memory term = nftfiLoan.loanIdToLoan(refinanceData.loanId);
    require(address(term.loanERC20Denomination) != address(0), "invalid loan");

    IERC20(term.loanERC20Denomination).approve(NFTFiLoan, payOffAmount);

    nftfiLoan.payBackLoan(refinanceData.loanId);
    require(IERC721(term.nftCollateralContract).ownerOf(term.nftCollateralId) == term.borrower, "invalid paybackloan");

    IERC721(term.nftCollateralContract).safeTransferFrom(
        term.borrower,
        address(this),
        term.nftCollateralId
    );

    ICERC721 supplyCToken = ICERC721(refinanceData.tokens[2]);
    IToken supplyUnderlying = IToken(refinanceData.tokens[3]);

    // Check ApprovalForAll
    if (!supplyUnderlying.isApprovedForAll(address(this), refinanceData.tokens[2])) {
      supplyUnderlying.setApprovalForAll(refinanceData.tokens[2], true);
    }

    // Supply Tokens
    supplyCToken.mints(refinanceData.supplyTokenIds);

    // Transfer cTokens
    TokenLogic proxy = proxies[refinanceData.tokenId];
    proxy.enterMarkets(supplyCToken);
    for (uint256 i = 0; i < refinanceData.supplyTokenIds.length; i++) {
      supplyCToken.transfer(address(proxy), 0);
    }

    // Borrow ETH, calculate repay amount (_amount + (2 wei))
    uint repayAmount = _getRepaymentAmountInternal(payOffAmount);

    proxy.borrowETH(refinanceData.tokens[0], repayAmount);

    // no need send to dydx here, it will be repaid automatically
    // // Repay ETH
    // payable(msg.sender).transfer(repayAmount);
    IWETH(term.loanERC20Denomination).deposit{value: repayAmount}();
    IERC20(term.loanERC20Denomination).approve(SOLO, repayAmount);

    delete refinanceData.tokenId;
    delete refinanceData.loanId;
  }

  function claimNFTs(
    uint256 tokenId,
    address cToken,
    uint256[] calldata redeemTokenIndexes
  ) external {
    require(ownerOf[tokenId] == msg.sender, 'Invalid access');

    TokenLogic proxy = proxies[tokenId];
    proxy.claimNFTs(cToken, redeemTokenIndexes, msg.sender);
  }

  function claimCTokens(
    uint256 tokenId,
    address cToken,
    uint256 amount
  ) external {
    require(ownerOf[tokenId] == msg.sender, 'Invalid access');

    TokenLogic proxy = proxies[tokenId];
    proxy.claimCTokens(cToken, amount, msg.sender);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IComptroller {
  function enterMarkets(address[] memory cTokens) external returns (uint256[] memory);
}

interface ICEther {
  function borrow(uint256 borrowAmount) external returns (uint256);
}

interface ICERC721 {
  function mints(uint256[] calldata tokenIds) external returns (uint256[] memory);

  function transfer(address dst, uint256 amount) external returns (bool);

  function userTokens(address user, uint256 index) external view returns (uint256);

  function redeems(uint256[] calldata redeemTokenIds) external returns (uint256[] memory);

  function underlying() external view returns (address);

  function comptroller() external view returns (IComptroller);
}

interface IUnderlying {
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ICToken.sol';

interface ITokenLogic {
  // Enter Markets
  function enterMarkets(ICERC721 cToken) external returns(uint256[] memory);

  // Borrow ETH
  function borrowETH(address cToken, uint256 amount) external;

  // Claim NFTs
  function claimNFTs(
    address cToken,
    uint256[] calldata redeemTokenIndexes,
    address to
  ) external;

  // Claim cToken
  function claimCTokens(
    address cToken,
    uint256 amount,
    address to
  ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8;

interface IWETH {
    function deposit() external payable;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ISoloMargin.sol";

contract DydxFlashloanBase {
  using SafeMath for uint;

  // -- Internal Helper functions -- //

  function _getMarketIdFromTokenAddress(address _solo, address token)
    internal
    view
    returns (uint)
  {
    ISoloMargin solo = ISoloMargin(_solo);

    uint numMarkets = solo.getNumMarkets();

    address curToken;
    for (uint i = 0; i < numMarkets; i++) {
      curToken = solo.getMarketTokenAddress(i);

      if (curToken == token) {
        return i;
      }
    }

    revert("No marketId found for provided token");
  }

  function _getRepaymentAmountInternal(uint amount) internal pure returns (uint) {
    // Needs to be overcollateralize
    // Needs to provide +2 wei to be safe
    return amount.add(2);
  }

  function _getAccountInfo() internal view returns (Account.Info memory) {
    return Account.Info({owner: address(this), number: 1});
  }

  function _getWithdrawAction(uint marketId, uint amount)
    internal
    view
    returns (Actions.ActionArgs memory)
  {
    return
      Actions.ActionArgs({
        actionType: Actions.ActionType.Withdraw,
        accountId: 0,
        amount: Types.AssetAmount({
          sign: false,
          denomination: Types.AssetDenomination.Wei,
          ref: Types.AssetReference.Delta,
          value: amount
        }),
        primaryMarketId: marketId,
        secondaryMarketId: 0,
        otherAddress: address(this),
        otherAccountId: 0,
        data: ""
      });
  }

  function _getCallAction(bytes memory data)
    internal
    view
    returns (Actions.ActionArgs memory)
  {
    return
      Actions.ActionArgs({
        actionType: Actions.ActionType.Call,
        accountId: 0,
        amount: Types.AssetAmount({
          sign: false,
          denomination: Types.AssetDenomination.Wei,
          ref: Types.AssetReference.Delta,
          value: 0
        }),
        primaryMarketId: 0,
        secondaryMarketId: 0,
        otherAddress: address(this),
        otherAccountId: 0,
        data: data
      });
  }

  function _getDepositAction(uint marketId, uint amount)
    internal
    view
    returns (Actions.ActionArgs memory)
  {
    return
      Actions.ActionArgs({
        actionType: Actions.ActionType.Deposit,
        accountId: 0,
        amount: Types.AssetAmount({
          sign: true,
          denomination: Types.AssetDenomination.Wei,
          ref: Types.AssetReference.Delta,
          value: amount
        }),
        primaryMarketId: marketId,
        secondaryMarketId: 0,
        otherAddress: address(this),
        otherAccountId: 0,
        data: ""
      });
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;
pragma experimental ABIEncoderV2;

import {Account} from "./ISoloMargin.sol";

/**
 * @title ICallee
 * @author dYdX
 *
 * Interface that Callees for Solo must implement in order to ingest data.
 */
interface ICallee {
  // ============ Public Functions ============

  /**
   * Allows users to send this contract arbitrary data.
   *
   * @param  sender       The msg.sender to Solo
   * @param  accountInfo  The account from which the data is being sent
   * @param  data         Arbitrary data given by the sender
   */
  function callFunction(
    address sender,
    Account.Info calldata accountInfo,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;
pragma experimental ABIEncoderV2;

library Account {
  enum Status {
    Normal,
    Liquid,
    Vapor
  }
  struct Info {
    address owner; // The address that owns the account
    uint number; // A nonce that allows a single address to control many accounts
  }
  struct accStorage {
    mapping(uint => Types.Par) balances; // Mapping from marketId to principal
    Status status;
  }
}

library Actions {
  enum ActionType {
    Deposit, // supply tokens
    Withdraw, // borrow tokens
    Transfer, // transfer balance between accounts
    Buy, // buy an amount of some token (publicly)
    Sell, // sell an amount of some token (publicly)
    Trade, // trade tokens against another account
    Liquidate, // liquidate an undercollateralized or expiring account
    Vaporize, // use excess tokens to zero-out a completely negative account
    Call // send arbitrary data to an address
  }

  enum AccountLayout {
    OnePrimary,
    TwoPrimary,
    PrimaryAndSecondary
  }

  enum MarketLayout {
    ZeroMarkets,
    OneMarket,
    TwoMarkets
  }

  struct ActionArgs {
    ActionType actionType;
    uint accountId;
    Types.AssetAmount amount;
    uint primaryMarketId;
    uint secondaryMarketId;
    address otherAddress;
    uint otherAccountId;
    bytes data;
  }

  struct DepositArgs {
    Types.AssetAmount amount;
    Account.Info account;
    uint market;
    address from;
  }

  struct WithdrawArgs {
    Types.AssetAmount amount;
    Account.Info account;
    uint market;
    address to;
  }

  struct TransferArgs {
    Types.AssetAmount amount;
    Account.Info accountOne;
    Account.Info accountTwo;
    uint market;
  }

  struct BuyArgs {
    Types.AssetAmount amount;
    Account.Info account;
    uint makerMarket;
    uint takerMarket;
    address exchangeWrapper;
    bytes orderData;
  }

  struct SellArgs {
    Types.AssetAmount amount;
    Account.Info account;
    uint takerMarket;
    uint makerMarket;
    address exchangeWrapper;
    bytes orderData;
  }

  struct TradeArgs {
    Types.AssetAmount amount;
    Account.Info takerAccount;
    Account.Info makerAccount;
    uint inputMarket;
    uint outputMarket;
    address autoTrader;
    bytes tradeData;
  }

  struct LiquidateArgs {
    Types.AssetAmount amount;
    Account.Info solidAccount;
    Account.Info liquidAccount;
    uint owedMarket;
    uint heldMarket;
  }

  struct VaporizeArgs {
    Types.AssetAmount amount;
    Account.Info solidAccount;
    Account.Info vaporAccount;
    uint owedMarket;
    uint heldMarket;
  }

  struct CallArgs {
    Account.Info account;
    address callee;
    bytes data;
  }
}

library Decimal {
  struct D256 {
    uint value;
  }
}

library Interest {
  struct Rate {
    uint value;
  }

  struct Index {
    uint96 borrow;
    uint96 supply;
    uint32 lastUpdate;
  }
}

library Monetary {
  struct Price {
    uint value;
  }
  struct Value {
    uint value;
  }
}

library Storage {
  // All information necessary for tracking a market
  struct Market {
    // Contract address of the associated ERC20 token
    address token;
    // Total aggregated supply and borrow amount of the entire market
    Types.TotalPar totalPar;
    // Interest index of the market
    Interest.Index index;
    // Contract address of the price oracle for this market
    address priceOracle;
    // Contract address of the interest setter for this market
    address interestSetter;
    // Multiplier on the marginRatio for this market
    Decimal.D256 marginPremium;
    // Multiplier on the liquidationSpread for this market
    Decimal.D256 spreadPremium;
    // Whether additional borrows are allowed for this market
    bool isClosing;
  }

  // The global risk parameters that govern the health and security of the system
  struct RiskParams {
    // Required ratio of over-collateralization
    Decimal.D256 marginRatio;
    // Percentage penalty incurred by liquidated accounts
    Decimal.D256 liquidationSpread;
    // Percentage of the borrower's interest fee that gets passed to the suppliers
    Decimal.D256 earningsRate;
    // The minimum absolute borrow value of an account
    // There must be sufficient incentivize to liquidate undercollateralized accounts
    Monetary.Value minBorrowedValue;
  }

  // The maximum RiskParam values that can be set
  struct RiskLimits {
    uint64 marginRatioMax;
    uint64 liquidationSpreadMax;
    uint64 earningsRateMax;
    uint64 marginPremiumMax;
    uint64 spreadPremiumMax;
    uint128 minBorrowedValueMax;
  }

  // The entire storage state of Solo
  struct State {
    // number of markets
    uint numMarkets;
    // marketId => Market
    mapping(uint => Market) markets;
    // owner => account number => Account
    mapping(address => mapping(uint => Account.accStorage)) accounts;
    // Addresses that can control other users accounts
    mapping(address => mapping(address => bool)) operators;
    // Addresses that can control all users accounts
    mapping(address => bool) globalOperators;
    // mutable risk parameters of the system
    RiskParams riskParams;
    // immutable risk limits of the system
    RiskLimits riskLimits;
  }
}

library Types {
  enum AssetDenomination {
    Wei, // the amount is denominated in wei
    Par // the amount is denominated in par
  }

  enum AssetReference {
    Delta, // the amount is given as a delta from the current value
    Target // the amount is given as an exact number to end up at
  }

  struct AssetAmount {
    bool sign; // true if positive
    AssetDenomination denomination;
    AssetReference ref;
    uint value;
  }

  struct TotalPar {
    uint128 borrow;
    uint128 supply;
  }

  struct Par {
    bool sign; // true if positive
    uint128 value;
  }

  struct Wei {
    bool sign; // true if positive
    uint value;
  }
}

interface ISoloMargin {
  struct OperatorArg {
    address operator;
    bool trusted;
  }

  function ownerSetSpreadPremium(uint marketId, Decimal.D256 calldata spreadPremium)
    external;

  function getIsGlobalOperator(address operator) external view returns (bool);

  function getMarketTokenAddress(uint marketId) external view returns (address);

  function ownerSetInterestSetter(uint marketId, address interestSetter) external;

  function getAccountValues(Account.Info calldata account)
    external
    view
    returns (Monetary.Value memory, Monetary.Value memory);

  function getMarketPriceOracle(uint marketId) external view returns (address);

  function getMarketInterestSetter(uint marketId) external view returns (address);

  function getMarketSpreadPremium(uint marketId)
    external
    view
    returns (Decimal.D256 memory);

  function getNumMarkets() external view returns (uint);

  function ownerWithdrawUnsupportedTokens(address token, address recipient)
    external
    returns (uint);

  function ownerSetMinBorrowedValue(Monetary.Value calldata minBorrowedValue) external;

  function ownerSetLiquidationSpread(Decimal.D256 calldata spread) external;

  function ownerSetEarningsRate(Decimal.D256 calldata earningsRate) external;

  function getIsLocalOperator(address _owner, address operator)
    external
    view
    returns (bool);

  function getAccountPar(Account.Info calldata account, uint marketId)
    external
    view
    returns (Types.Par memory);

  function ownerSetMarginPremium(uint marketId, Decimal.D256 calldata marginPremium)
    external;

  function getMarginRatio() external view returns (Decimal.D256 memory);

  function getMarketCurrentIndex(uint marketId)
    external
    view
    returns (Interest.Index memory);

  function getMarketIsClosing(uint marketId) external view returns (bool);

  function getRiskParams() external view returns (Storage.RiskParams memory);

  function getAccountBalances(Account.Info calldata account)
    external
    view
    returns (
      address[] memory,
      Types.Par[] memory,
      Types.Wei[] memory
    );

  function renounceOwnership() external;

  function getMinBorrowedValue() external view returns (Monetary.Value memory);

  function setOperators(OperatorArg[] calldata args) external;

  function getMarketPrice(uint marketId) external view returns (address);

  function owner() external view returns (address);

  function isOwner() external view returns (bool);

  function ownerWithdrawExcessTokens(uint marketId, address recipient)
    external
    returns (uint);

  function ownerAddMarket(
    address token,
    address priceOracle,
    address interestSetter,
    Decimal.D256 calldata marginPremium,
    Decimal.D256 calldata spreadPremium
  ) external;

  function operate(
    Account.Info[] calldata accounts,
    Actions.ActionArgs[] calldata actions
  ) external;

  function getMarketWithInfo(uint marketId)
    external
    view
    returns (
      Storage.Market memory,
      Interest.Index memory,
      Monetary.Price memory,
      Interest.Rate memory
    );

  function ownerSetMarginRatio(Decimal.D256 calldata ratio) external;

  function getLiquidationSpread() external view returns (Decimal.D256 memory);

  function getAccountWei(Account.Info calldata account, uint marketId)
    external
    view
    returns (Types.Wei memory);

  function getMarketTotalPar(uint marketId)
    external
    view
    returns (Types.TotalPar memory);

  function getLiquidationSpreadForPair(uint heldMarketId, uint owedMarketId)
    external
    view
    returns (Decimal.D256 memory);

  function getNumExcessTokens(uint marketId) external view returns (Types.Wei memory);

  function getMarketCachedIndex(uint marketId)
    external
    view
    returns (Interest.Index memory);

  function getAccountStatus(Account.Info calldata account)
    external
    view
    returns (uint8);

  function getEarningsRate() external view returns (Decimal.D256 memory);

  function ownerSetPriceOracle(uint marketId, address priceOracle) external;

  function getRiskLimits() external view returns (Storage.RiskLimits memory);

  function getMarket(uint marketId) external view returns (Storage.Market memory);

  function ownerSetIsClosing(uint marketId, bool isClosing) external;

  function ownerSetGlobalOperator(address operator, bool approved) external;

  function transferOwnership(address newOwner) external;

  function getAdjustedAccountValues(Account.Info calldata account)
    external
    view
    returns (Monetary.Value memory, Monetary.Value memory);

  function getMarketMarginPremium(uint marketId)
    external
    view
    returns (Decimal.D256 memory);

  function getMarketInterestRate(uint marketId)
    external
    view
    returns (Interest.Rate memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

/**
 * @title  DirectLoanFixed
 * @author NFTfi
 * @notice Main contract for NFTfi Direct Loans Fixed Type. This contract manages the ability to create NFT-backed
 * peer-to-peer loans of type Fixed (agreed to be a fixed-repayment loan) where the borrower pays the
 * maximumRepaymentAmount regardless of whether they repay early or not.
 *
 * There are two ways to commence an NFT-backed loan:
 *
 * a. The borrower accepts a lender's offer by calling `acceptOffer`.
 *   1. the borrower calls nftContract.approveAll(NFTfi), approving the NFTfi contract to move their NFT's on their
 * be1alf.
 *   2. the lender calls erc20Contract.approve(NFTfi), allowing NFTfi to move the lender's ERC20 tokens on their
 * behalf.
 *   3. the lender signs an off-chain message, proposing its offer terms.
 *   4. the borrower calls `acceptOffer` to accept these terms and enter into the loan. The NFT is stored in
 * the contract, the borrower receives the loan principal in the specified ERC20 currency, the lender receives an
 * NFTfi promissory note (in ERC721 form) that represents the rights to either the principal-plus-interest, or the
 * underlying NFT collateral if the borrower does not pay back in time, and the borrower receives obligation receipt
 * (in ERC721 form) that gives them the right to pay back the loan and get the collateral back.
 *
 * b. The lender accepts a borrowe's binding terms by calling `acceptListing`.
 *   1. the borrower calls nftContract.approveAll(NFTfi), approving the NFTfi contract to move their NFT's on their
 * be1alf.
 *   2. the lender calls erc20Contract.approve(NFTfi), allowing NFTfi to move the lender's ERC20 tokens on their
 * behalf.
 *   3. the borrower signs an off-chain message, proposing its binding terms.
 *   4. the lender calls `acceptListing` with an offer matching the binding terms and enter into the loan. The NFT is
 * stored in the contract, the borrower receives the loan principal in the specified ERC20 currency, the lender
 * receives an NFTfi promissory note (in ERC721 form) that represents the rights to either the principal-plus-interest,
 * or the underlying NFT collateral if the borrower does not pay back in time, and the borrower receives obligation
 * receipt (in ERC721 form) that gives them the right to pay back the loan and get the collateral back.
 *
 * The lender can freely transfer and trade this ERC721 promissory note as they wish, with the knowledge that
 * transferring the ERC721 promissory note tranfsers the rights to principal-plus-interest and/or collateral, and that
 * they will no longer have a claim on the loan. The ERC721 promissory note itself represents that claim.
 *
 * The borrower can freely transfer and trade this ERC721 obligaiton receipt as they wish, with the knowledge that
 * transferring the ERC721 obligaiton receipt tranfsers the rights right to pay back the loan and get the collateral
 * back.
 *
 *
 * A loan may end in one of two ways:
 * - First, a borrower may call NFTfi.payBackLoan() and pay back the loan plus interest at any time, in which case they
 * receive their NFT back in the same transaction.
 * - Second, if the loan's duration has passed and the loan has not been paid back yet, a lender can call
 * NFTfi.liquidateOverdueLoan(), in which case they receive the underlying NFT collateral and forfeit the rights to the
 * principal-plus-interest, which the borrower now keeps.
 */

import "./LoanData.sol";

interface INftfiLoan is LoanData {
    event LoanStarted(
        uint32 indexed loanId,
        address indexed borrower,
        address indexed lender,
        LoanTerms loanTerms,
        LoanExtras loanExtras
    );

    function acceptOffer(
        Offer memory _offer,
        Signature memory _signature,
        BorrowerSettings memory _borrowerSettings
    ) external;

    function payBackLoan(uint32 _loanId) external;

    function liquidateOverdueLoan(uint32 _loanId) external;

    function getPayoffAmount(uint32 _loanId) external view returns (uint256);

    function loanIdToLoan(uint32) external view returns (LoanTerms memory);

    function loanRepaidOrLiquidated(uint32) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8;

/**
 * @title  LoanData
 * @author NFTfi
 * @notice An interface containg the main Loan struct shared by Direct Loans types.
 */
interface LoanData {
    /* ********** */
    /* DATA TYPES */
    /* ********** */

    /**
     * @notice The main Loan Terms struct. This data is saved upon loan creation.
     *
     * @param loanERC20Denomination - The address of the ERC20 contract of the currency being used as principal/interest
     * for this loan.
     * @param loanPrincipalAmount - The original sum of money transferred from lender to borrower at the beginning of
     * the loan, measured in loanERC20Denomination's smallest units.
     * @param maximumRepaymentAmount - The maximum amount of money that the borrower would be required to retrieve their
     * collateral, measured in the smallest units of the ERC20 currency used for the loan. The borrower will always have
     * to pay this amount to retrieve their collateral, regardless of whether they repay early.
     * @param nftCollateralContract - The address of the the NFT collateral contract.
     * @param nftCollateralWrapper - The NFTfi wrapper of the NFT collateral contract.
     * @param nftCollateralId - The ID within the NFTCollateralContract for the NFT being used as collateral for this
     * loan. The NFT is stored within this contract during the duration of the loan.
     * @param loanStartTime - The block.timestamp when the loan first began (measured in seconds).
     * @param loanDuration - The amount of time (measured in seconds) that can elapse before the lender can liquidate
     * the loan and seize the underlying collateral NFT.
     * @param loanInterestRateForDurationInBasisPoints - This is the interest rate (measured in basis points, e.g.
     * hundreths of a percent) for the loan, that must be repaid pro-rata by the borrower at the conclusion of the loan
     * or risk seizure of their nft collateral. Note if the type of the loan is fixed then this value  is not used and
     * is irrelevant so it should be set to 0.
     * @param loanAdminFeeInBasisPoints - The percent (measured in basis points) of the interest earned that will be
     * taken as a fee by the contract admins when the loan is repaid. The fee is stored in the loan struct to prevent an
     * attack where the contract admins could adjust the fee right before a loan is repaid, and take all of the interest
     * earned.
     * @param borrower
     */
    struct LoanTerms {
        uint256 loanPrincipalAmount;
        uint256 maximumRepaymentAmount;
        uint256 nftCollateralId;
        address loanERC20Denomination;
        uint32 loanDuration;
        uint16 loanInterestRateForDurationInBasisPoints;
        uint16 loanAdminFeeInBasisPoints;
        address nftCollateralWrapper;
        uint64 loanStartTime;
        address nftCollateralContract;
        address borrower;
    }

    /**
     * @notice Some extra Loan's settings struct. This data is saved upon loan creation.
     * We need this to avoid stack too deep errors.
     *
     * @param revenueSharePartner - The address of the partner that will receive the revenue share.
     * @param revenueShareInBasisPoints - The percent (measured in basis points) of the admin fee amount that will be
     * taken as a revenue share for a t
     * @param referralFeeInBasisPoints - The percent (measured in basis points) of the loan principal amount that will
     * be taken as a fee to pay to the referrer, 0 if the lender is not paying referral fee.he partner, at the moment
     * the loan is begun.
     */
    struct LoanExtras {
        address revenueSharePartner;
        uint16 revenueShareInBasisPoints;
        uint16 referralFeeInBasisPoints;
    }

    /**
     * @notice The offer made by the lender. Used as parameter on both acceptOffer (initiated by the borrower) and
     * acceptListing (initiated by the lender).
     *
     * @param loanERC20Denomination - The address of the ERC20 contract of the currency being used as principal/interest
     * for this loan.
     * @param loanPrincipalAmount - The original sum of money transferred from lender to borrower at the beginning of
     * the loan, measured in loanERC20Denomination's smallest units.
     * @param maximumRepaymentAmount - The maximum amount of money that the borrower would be required to retrieve their
     *  collateral, measured in the smallest units of the ERC20 currency used for the loan. The borrower will always
     * have to pay this amount to retrieve their collateral, regardless of whether they repay early.
     * @param nftCollateralContract - The address of the ERC721 contract of the NFT collateral.
     * @param nftCollateralId - The ID within the NFTCollateralContract for the NFT being used as collateral for this
     * loan. The NFT is stored within this contract during the duration of the loan.
     * @param referrer - The address of the referrer who found the lender matching the listing, Zero address to signal
     * this there is no referrer.
     * @param loanDuration - The amount of time (measured in seconds) that can elapse before the lender can liquidate
     * the loan and seize the underlying collateral NFT.
     * @param loanAdminFeeInBasisPoints - The percent (measured in basis points) of the interest earned that will be
     * taken as a fee by the contract admins when the loan is repaid. The fee is stored in the loan struct to prevent an
     * attack where the contract admins could adjust the fee right before a loan is repaid, and take all of the interest
     * earned.
     */
    struct Offer {
        uint256 loanPrincipalAmount;
        uint256 maximumRepaymentAmount;
        uint256 nftCollateralId;
        address nftCollateralContract;
        uint32 loanDuration;
        uint16 loanAdminFeeInBasisPoints;
        address loanERC20Denomination;
        address referrer;
    }

    /**
     * @notice Signature related params. Used as parameter on both acceptOffer (containing borrower signature) and
     * acceptListing (containing lender signature).
     *
     * @param signer - The address of the signer. The borrower for `acceptOffer` the lender for `acceptListing`.
     * @param nonce - The nonce referred here is not the same as an Ethereum account's nonce.
     * We are referring instead to a nonce that is used by the lender or the borrower when they are first signing
     * off-chain NFTfi orders. These nonce can be any uint256 value that the user has not previously used to sign an
     * off-chain order. Each nonce can be used at most once per user within NFTfi, regardless of whether they are the
     * lender or the borrower in that situation. This serves two purposes:
     * - First, it prevents replay attacks where an attacker would submit a user's off-chain order more than once.
     * - Second, it allows a user to cancel an off-chain order by calling NFTfi.cancelLoanCommitmentBeforeLoanHasBegun()
     * , which marks the nonce as used and prevents any future loan from using the user's off-chain order that contains
     * that nonce.
     * @param expiry - Date when the signature expires
     * @param signature - The ECDSA signature of the borrower or the lender, obtained off-chain ahead of time, signing
     * the following combination of parameters:
     * - Borrower
     *   - ListingTerms.loanERC20Denomination,
     *   - ListingTerms.minLoanPrincipalAmount,
     *   - ListingTerms.maxLoanPrincipalAmount,
     *   - ListingTerms.nftCollateralContract,
     *   - ListingTerms.nftCollateralId,
     *   - ListingTerms.revenueSharePartner,
     *   - ListingTerms.minLoanDuration,
     *   - ListingTerms.maxLoanDuration,
     *   - ListingTerms.maxInterestRateForDurationInBasisPoints,
     *   - ListingTerms.referralFeeInBasisPoints,
     *   - Signature.signer,
     *   - Signature.nonce,
     *   - Signature.expiry,
     *   - address of the loan type contract
     *   - chainId
     * - Lender:
     *   - Offer.loanERC20Denomination
     *   - Offer.loanPrincipalAmount
     *   - Offer.maximumRepaymentAmount
     *   - Offer.nftCollateralContract
     *   - Offer.nftCollateralId
     *   - Offer.referrer
     *   - Offer.loanDuration
     *   - Offer.loanAdminFeeInBasisPoints
     *   - Signature.signer,
     *   - Signature.nonce,
     *   - Signature.expiry,
     *   - address of the loan type contract
     *   - chainId
     */
    struct Signature {
        uint256 nonce;
        uint256 expiry;
        address signer;
        bytes signature;
    }

    /**
     * @notice Some extra parameters that the borrower needs to set when accepting an offer.
     *
     * @param revenueSharePartner - The address of the partner that will receive the revenue share.
     * @param referralFeeInBasisPoints - The percent (measured in basis points) of the loan principal amount that will
     * be taken as a fee to pay to the referrer, 0 if the lender is not paying referral fee.
     */
    struct BorrowerSettings {
        address revenueSharePartner;
        uint16 referralFeeInBasisPoints;
    }

    /**
     * @notice Terms the borrower set off-chain and is willing to accept automatically when fulfiled by a lender's
     * offer.
     *
     * @param loanERC20Denomination - The address of the ERC20 contract of the currency being used as principal/interest
     * for this loan.
     * @param minLoanPrincipalAmount - The minumum sum of money transferred from lender to borrower at the beginning of
     * the loan, measured in loanERC20Denomination's smallest units.
     * @param maxLoanPrincipalAmount - The  sum of money transferred from lender to borrower at the beginning of
     * the loan, measured in loanERC20Denomination's smallest units.
     * @param maximumRepaymentAmount - The maximum amount of money that the borrower would be required to retrieve their
     * collateral, measured in the smallest units of the ERC20 currency used for the loan. The borrower will always have
     * to pay this amount to retrieve their collateral, regardless of whether they repay early.
     * @param nftCollateralContract - The address of the ERC721 contract of the NFT collateral.
     * @param nftCollateralId - The ID within the NFTCollateralContract for the NFT being used as collateral for this
     * loan. The NFT is stored within this contract during the duration of the loan.
     * @param revenueSharePartner - The address of the partner that will receive the revenue share.
     * @param minLoanDuration - The minumum amount of time (measured in seconds) that can elapse before the lender can
     * liquidate the loan and seize the underlying collateral NFT.
     * @param maxLoanDuration - The maximum amount of time (measured in seconds) that can elapse before the lender can
     * liquidate the loan and seize the underlying collateral NFT.
     * @param maxInterestRateForDurationInBasisPoints - This is maximum the interest rate (measured in basis points,
     * e.g. hundreths of a percent) for the loan.
     * @param referralFeeInBasisPoints - The percent (measured in basis points) of the loan principal amount that will
     * be taken as a fee to pay to the referrer, 0 if the lender is not paying referral fee.
     */
    struct ListingTerms {
        uint256 minLoanPrincipalAmount;
        uint256 maxLoanPrincipalAmount;
        uint256 nftCollateralId;
        address nftCollateralContract;
        uint32 minLoanDuration;
        uint32 maxLoanDuration;
        uint16 maxInterestRateForDurationInBasisPoints;
        uint16 referralFeeInBasisPoints;
        address revenueSharePartner;
        address loanERC20Denomination;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Base64 {
  string private constant base64stdchars =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

  function encode(bytes memory data) internal pure returns (string memory) {
    if (data.length == 0) return '';

    // load the table into memory
    string memory table = base64stdchars;

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((data.length + 2) / 3);

    // add some extra buffer at the end required for the writing
    string memory result = new string(encodedLen + 32);

    assembly {
      // set the actual output length
      mstore(result, encodedLen)

      // prepare the lookup table
      let tablePtr := add(table, 1)

      // input ptr
      let dataPtr := data
      let endPtr := add(dataPtr, mload(data))

      // result ptr, jump over length
      let resultPtr := add(result, 32)

      // run over the input, 3 bytes at a time
      for {

      } lt(dataPtr, endPtr) {

      } {
        dataPtr := add(dataPtr, 3)

        // read 3 bytes
        let input := mload(dataPtr)

        // write 4 characters
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
        resultPtr := add(resultPtr, 1)
      }

      // padding with '='
      switch mod(mload(data), 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }
    }

    return result;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
  /**
   * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
   * by `operator` from `from`, this function is called.
   *
   * It must return its Solidity selector to confirm the token transfer.
   * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
   *
   * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
   */
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4);
}

/// @notice Modern and gas efficient ERC-721 + ERC-20/EIP-2612-like implementation,
/// including the MetaData, and partially, Enumerable extensions.
contract ERC721 {
  /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

  event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);

  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

  address implementation_;
  address admin;

  string public name;
  string public symbol;

  /*///////////////////////////////////////////////////////////////
                             ERC-721 STORAGE
    //////////////////////////////////////////////////////////////*/

  mapping(address => uint256) public balanceOf;

  mapping(uint256 => address) public ownerOf;

  mapping(uint256 => address) public getApproved;

  mapping(address => mapping(address => bool)) public isApprovedForAll;

  /*///////////////////////////////////////////////////////////////
                             OWNER FUNCTION
    //////////////////////////////////////////////////////////////*/

  modifier onlyOwner() {
    require(msg.sender == admin);
    _;
  }

  function owner() external view returns (address) {
    return admin;
  }

  function transferOwnership(address newOwner) external onlyOwner {
    admin = newOwner;

    emit OwnershipTransferred(msg.sender, newOwner);
  }

  /*///////////////////////////////////////////////////////////////
                              ERC-20-LIKE LOGIC
    //////////////////////////////////////////////////////////////*/

  function transfer(address to, uint256 tokenId) external {
    require(msg.sender == ownerOf[tokenId], "NOT_OWNER");

    _transfer(msg.sender, to, tokenId);
  }

  /*///////////////////////////////////////////////////////////////
                              ERC-721 LOGIC
    //////////////////////////////////////////////////////////////*/

  function supportsInterface(bytes4 interfaceId) external pure returns (bool supported) {
    // supported = interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f || interfaceId == 0x2a55205a;
    supported = true;
  }

  function approve(address spender, uint256 tokenId) external {
    address owner_ = ownerOf[tokenId];

    require(msg.sender == owner_ || isApprovedForAll[owner_][msg.sender], "NOT_APPROVED");

    getApproved[tokenId] = spender;

    emit Approval(owner_, spender, tokenId);
  }

  function setApprovalForAll(address operator, bool approved) external {
    isApprovedForAll[msg.sender][operator] = approved;

    emit ApprovalForAll(msg.sender, operator, approved);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual {
    require(
      msg.sender == from || msg.sender == getApproved[tokenId] || isApprovedForAll[from][msg.sender],
      "NOT_APPROVED"
    );

    _transfer(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external {
    safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public {
    transferFrom(from, to, tokenId);

    if (to.code.length != 0) {
      try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
        require(retval == IERC721Receiver.onERC721Received.selector);
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721: transfer to non ERC721Receiver implementer");
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    }
  }

  /*///////////////////////////////////////////////////////////////
                          INTERNAL UTILS
    //////////////////////////////////////////////////////////////*/

  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal {
    require(ownerOf[tokenId] == from);
    _beforeTokenTransfer(from, to, tokenId);

    balanceOf[from]--;
    balanceOf[to]++;

    delete getApproved[tokenId];

    ownerOf[tokenId] = to;
    emit Transfer(from, to, tokenId);

    _afterTokenTransfer(from, to, tokenId);
  }

  function _mint(address to, uint256 tokenId) internal {
    require(ownerOf[tokenId] == address(0), "ALREADY_MINTED");
    _beforeTokenTransfer(address(0), to, tokenId);

    // This is safe because the sum of all user
    // balances can't exceed type(uint256).max!
    unchecked {
      balanceOf[to]++;
    }

    ownerOf[tokenId] = to;

    emit Transfer(address(0), to, tokenId);

    _afterTokenTransfer(address(0), to, tokenId);
  }

  function _burn(uint256 tokenId) internal {
    address owner_ = ownerOf[tokenId];

    require(owner_ != address(0), "NOT_MINTED");
    _beforeTokenTransfer(owner_, address(0), tokenId);

    balanceOf[owner_]--;

    delete ownerOf[tokenId];

    emit Transfer(owner_, address(0), tokenId);

    _afterTokenTransfer(owner_, address(0), tokenId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "./ERC721.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721 {
  // Mapping from owner to list of owned token IDs
  mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) private _ownedTokensIndex;

  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   */
  uint256 public totalSupply;

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {
    require(index < balanceOf[owner], "ERC721Enumerable: owner index out of bounds");
    return _ownedTokens[owner][index];
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting
   * and burning.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, ``from``'s `tokenId` will be burned.
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId);

    if (from == address(0)) {
      totalSupply++;
    } else if (from != to) {
      _removeTokenFromOwnerEnumeration(from, tokenId);
    }
    if (to == address(0)) {
      totalSupply--;
    } else if (to != from) {
      _addTokenToOwnerEnumeration(to, tokenId);
    }
  }

  /**
   * @dev Private function to add a token to this extension's ownership-tracking data structures.
   * @param to address representing the new owner of the given token ID
   * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
    uint256 length = balanceOf[to];
    _ownedTokens[to][length] = tokenId;
    _ownedTokensIndex[tokenId] = length;
  }

  /**
   * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
   * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
   * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
   * This has O(1) time complexity, but alters the order of the _ownedTokens array.
   * @param from address representing the previous owner of the given token ID
   * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
    // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
    // then delete the last slot (swap and pop).

    uint256 lastTokenIndex = balanceOf[from] - 1;
    uint256 tokenIndex = _ownedTokensIndex[tokenId];

    // When the token to delete is the last token, the swap operation is unnecessary
    if (tokenIndex != lastTokenIndex) {
      uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

      _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
      _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
    }

    // This also deletes the contents at the last position of the array
    delete _ownedTokensIndex[tokenId];
    delete _ownedTokens[from][lastTokenIndex];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ProxyData.sol';

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
contract Proxy is ProxyData {
  receive() external payable {}

  function setImplementation(address newImpl) public {
    require(msg.sender == admin);
    implementation_ = newImpl;
  }

  function implementation() public view returns (address impl) {
    impl = implementation_;
  }

  /**
   * @dev Delegates the current call to `implementation`.
   *
   * This function does not return to its internall call site, it will return directly to the external caller.
   */
  function _delegate(address implementation__) internal virtual {
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas(), implementation__, 0, calldatasize(), 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())

      switch result
      // delegatecall returns 0 on error.
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  /**
   * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
   * and {_fallback} should delegate.
   */
  function _implementation() internal view returns (address) {
    return implementation_;
  }

  /**
   * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
   * function in the contract matches the call data.
   */
  fallback() external payable virtual {
    _delegate(_implementation());
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ProxyData {
  address implementation_;
  address public admin;

  constructor() {
    admin = msg.sender;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../utils/Vault.sol';
import '../interfaces/ITokenLogic.sol';
import '../interfaces/ICToken.sol';

contract TokenLogic is Vault, ITokenLogic {
  address implementation_;
  address public admin;

  modifier onlyOwner() {
    require(msg.sender == admin);
    _;
  }

  // Enter Markets
  function enterMarkets(ICERC721 supplyCToken) external override returns(uint256[] memory) {
    address[] memory cTokens = new address[](1);
    cTokens[0] = address(supplyCToken);
    return supplyCToken.comptroller().enterMarkets(cTokens);
  }

  // Borrow ETH
  function borrowETH(address cToken, uint256 amount) external override onlyOwner {
    ICEther(cToken).borrow(amount);
    payable(admin).transfer(amount);
  }

  // Claim NFT
  function claimNFTs(
    address cToken,
    uint256[] calldata redeemTokenIndexes,
    address to
  ) external override onlyOwner {
    uint256 amount = redeemTokenIndexes.length;
    uint256[] memory tokenIds = new uint256[](amount);

    ICERC721 supplyCToken = ICERC721(cToken);
    address _this = address(this);
    for (uint256 i = 0; i < amount; i++) {
      tokenIds[i] = supplyCToken.userTokens(_this, redeemTokenIndexes[i]);
    }

    supplyCToken.redeems(redeemTokenIndexes);

    IUnderlying underlying = IUnderlying(supplyCToken.underlying());
    for (uint256 i = 0; i < amount; i++) {
      underlying.transferFrom(_this, to, tokenIds[i]);
    }
  }

  // Claim cToken
  function claimCTokens(
    address cToken,
    uint256 amount,
    address to
  ) external override onlyOwner {
    ICERC721 supplyCToken = ICERC721(cToken);
    for (uint256 i = 0; i < amount; i++) {
      supplyCToken.transfer(to, 0);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IToken {
  function balanceOf(address account) external view returns (uint256);

  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) external payable;

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) external;

  function isApprovedForAll(address owner, address spender) external view returns (bool);

  function setApprovalForAll(address operator, bool approved) external;
}

contract Vault {
  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes calldata
  ) public virtual returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] calldata,
    uint256[] calldata,
    bytes calldata
  ) public virtual returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external virtual returns (bytes4) {
    return 0x150b7a02;
  }

  // Used by ERC721BasicToken.sol
  function onERC721Received(
    address,
    uint256,
    bytes calldata
  ) external virtual returns (bytes4) {
    return 0xf0b9e5ba;
  }

  receive() external payable {}
}