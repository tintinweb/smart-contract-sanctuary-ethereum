// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";
import {ILandNFT} from "./interfaces/ILandNft.sol";

import "./interfaces/ILandBank.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IUniswapV2Pair.sol";

error InsufficientRio();
error InsufficientEthBalance();
error InvalidLand();
error coolDown();
error FailedTransfer();

contract LandBank is ReentrancyGuard {
    // RIO token address
    address private constant RIO_TOKEN =
        0xf21661D0D1d76d3ECb8e1B9F1c923DBfffAe4097;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant UNISWAP_V2_PAIR =
        0x0b85B3000BEf3E26e01428D1b525A532eA7513b8;

    address public owner;
    address public landNft;
    address public devFund;
    address private constant UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // uint256 public landPrice;

    mapping(uint256 => uint256) timelapse;

    event LandSold(
        address _seller,
        uint256[] landId,
        uint256 amount,
        uint256 at
    );

    event LandBought(
        address _buyer,
        uint256[] landId,
        uint256 amount,
        uint256 at
    );

    constructor(address _devFund, address _landNft) {
        require(
            _devFund != address(0) && _landNft != address(0),
            "can't set zero address"
        );
        devFund = _devFund;
        landNft = _landNft;
    }

    /**
    @notice msg.sender can buy land directly from LandBank contract
    @param _tokenIds array of land user would like to buy
    todo getPrice for landNFT allow , how the price is determined 
    */
    function buyLandFromBank(uint256[] memory _tokenIds)
        external
        payable
        nonReentrant
    {
        uint256 numberOfPx = _tokenIds.length;
        uint256 amountToSend = numberOfPx * getPrice();
        uint256 i;
        for (i; i < _tokenIds.length; i++) {
            if (timelapse[_tokenIds[i]] + 5 days > block.timestamp) {
                revert coolDown();
            }
        }
        // Approve the Uniswap Router contract
        address[] memory path = new address[](2);
        path[0] = address(RIO_TOKEN);
        path[1] = address(WETH);
        if (msg.value == 0) {
            if (IERC20(RIO_TOKEN).balanceOf(msg.sender) < amountToSend) {
                revert InsufficientRio();
            }
            // Transfer the amount of RIO to the contract
            bool success = IERC20(RIO_TOKEN).transferFrom(
                msg.sender,
                address(this),
                amountToSend
            );
            if (!success) {
                revert FailedTransfer();
            }
            uint256 amountIn = (amountToSend * 10) / 100;
            uint256 amountOutMin = getAmountOutMin(amountIn, path);
            IERC20(RIO_TOKEN).approve(UNISWAP_V2_ROUTER, amountIn);
            IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForETH(
                amountIn,
                amountOutMin,
                path,
                devFund,
                block.timestamp
            );
        } else if (
            msg.value > 0 || IERC20(RIO_TOKEN).balanceOf(msg.sender) == 0
        ) {
            uint256 minAmount = getAmountOutMin(amountToSend, path);
            if (msg.value < minAmount) {
                revert InsufficientEthBalance();
            }
            // 10% of funds are sent to the dev address
            payable(devFund).transfer(msg.value / 10);
            // swap rest of funds 90 % to RIO token
            uint256 amountIn = (msg.value * 9) / 10;
            address[] memory new_path = new address[](2);
            new_path[0] = address(WETH);
            new_path[1] = address(RIO_TOKEN);
            uint256 amountOutMin = getAmountOutMin(amountIn, path);
            IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactETHForTokens{
                value: amountIn
            }(amountOutMin, new_path, address(this), block.timestamp);
        }

        for (uint256 j; j < numberOfPx; j++) {
            ILandNFT(landNft).safeTransferFrom(
                address(this),
                msg.sender,
                _tokenIds[j]
            );
            timelapse[_tokenIds[j]] = block.timestamp;
        }

        emit LandBought(msg.sender, _tokenIds, amountToSend, block.timestamp);
    }

    /**
    @notice msg.sender can buy land directly from LandBank contract
    @param _tokenIds array of land user would like to buy
    todo getPrice for landNFT allow , how the price is determined 
    */
    function sellLandToBank(uint256[] memory _tokenIds) external nonReentrant {
        uint256 numberOfPx = _tokenIds.length;
        uint256 amountToSend;
        uint256 i;
        unchecked {
            amountToSend = getPrice() * numberOfPx;
        }

        for (i; i < numberOfPx; i++) {
            ILandNFT(landNft).transferFrom(
                msg.sender,
                address(this),
                _tokenIds[i]
            );
            timelapse[_tokenIds[i]] = block.timestamp;
        }
        IERC20(RIO_TOKEN).transfer(msg.sender, amountToSend);
        emit LandSold(msg.sender, _tokenIds, amountToSend, block.timestamp);
    }

    function getAmountOutMin(uint256 _amountIn, address[] memory path)
        public
        view
        returns (uint256)
    {
        uint256[] memory amountOutMins = IUniswapV2Router(UNISWAP_V2_ROUTER)
            .getAmountsOut(_amountIn, path);
        return amountOutMins[path.length - 1];
    }

    /**
     * getPrice function determines the price landBank value for pixel
     * price = total LandBank Holding / Number of pixel circulating
     */
    function getPrice() public returns (uint256) {
        uint256 holding = IERC20(RIO_TOKEN).balanceOf(address(this));
        uint256 PIXEL_SUPPLY = ILandNFT(landNft).totalTileNum();
        uint256 landPrice;
        unchecked {
            landPrice = ((holding / PIXEL_SUPPLY) * 12) / 10;
        }
        return landPrice;
    }

    receive() external payable {}
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

// we can use openzeppelin interface
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ILandNFT is IERC721 {
    struct Coordonate {
        uint256 lat;
        uint256 long;
    }

    struct Pixel {
        Coordonate a;
        Coordonate b;
        Coordonate c;
        Coordonate d;
    }

    function admin() external returns (address);

    function WETH() external returns (address);

    function RIO_TOKEN() external returns (address);

    function commissionRate() external returns (uint256);

    function totalTileNum() external returns (uint64);

    function devFund() external returns (address);

    function firstOwners(uint256 tokenId) external returns (address);

    function getLength(uint256 index) external view returns (uint256 len);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

interface ILandBank {
    function withdraw(address _beneficiary, uint256 _amount) external;

    function sellLandToBank(address _seller, uint256 _tokenId) external;

    function buyLandFromBank(address _buyer, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IUniswapV2Router {
    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        //the minimum amount of tokens we want out of the trade
        uint256 amountOutMin,
        //list of token addresses we are going to trade in.  this is necessary to calculate amounts
        address[] calldata path,
        //this is the address we are going to send the output tokens to
        address to,
        //the last time that the trade is valid for
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        //amount of tokens we are sending in
        uint256 amountIn,
        //the minimum amount of tokens we want out of the trade
        uint256 amountOutMin,
        //list of token addresses we are going to trade in.  this is necessary to calculate amounts
        address[] calldata path,
        //this is the address we are going to send the output tokens to
        address to,
        //the last time that the trade is valid for
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

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

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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