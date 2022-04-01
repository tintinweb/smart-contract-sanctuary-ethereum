/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// Copyright (c) 2022 EverRise Pte Ltd. All rights reserved.
// EverRise licenses this file to you under the MIT license.
/*
 The EverRise token is the keystone in the EverRise Ecosytem of dApps
 and the overaching key that unlocks multi-blockchain unification via
 the EverBridge.

 On EverRise token transactions 6% buyback and business development fees are collected:

 * 4% for token Buyback from the market, with bought back tokens directly
      distributed as ve-staking rewards
 * 2% for Business Development (Development, Sustainability and Marketing)
  ________                              _______   __
 /        |                            /       \ /  |
 $$$$$$$$/__     __  ______    ______  $$$$$$$  |$$/   _______   ______  v3.14159265
 $$ |__  /  \   /  |/      \  /      \ $$ |__$$ |/  | /       | /      \
 $$    | $$  \ /$$//$$$$$$  |/$$$$$$  |$$    $$< $$ |/$$$$$$$/ /$$$$$$  |
 $$$$$/   $$  /$$/ $$    $$ |$$ |  $$/ $$$$$$$  |$$ |$$      \ $$    $$ |
 $$ |_____ $$ $$/  $$$$$$$$/ $$ |      $$ |  $$ |$$ | $$$$$$  |$$$$$$$$/
 $$       | $$$/   $$       |$$ |      $$ |  $$ |$$ |/     $$/ $$       |
 $$$$$$$$/   $/     $$$$$$$/ $$/       $$/   $$/ $$/ $$$$$$$/   $$$$$$$/ Magnum opus

 Learn more about EverRise and the EverRise Ecosystem of dApps and
 how our utilities and partners can help protect your investors
 and help your project grow: https://everrise.com
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

error NotContractAddress();             // 0xd9716e43
error NoSameBlockSandwichTrades();      // 0x5fe87cb3
error TransferTooLarge();               // 0x1b97a875
error AmountLargerThanUnlockedAmount(); // 0x170abf7c
error TokenNotStarted();                // 0xd87a63e0
error TokenAlreadyStarted();            // 0xe529091f
error SandwichTradesAreDisallowed();    // 0xe069ee1d
error AmountLargerThanAvailable();      // 0xbb296109
error StakeCanOnlyBeExtended();         // 0x73f7040a
error NotStakeContractRequesting();     // 0x2ace6531
error NotEnoughToCoverStakeFee();       // 0x627554ed
error NotZeroAddress();                 // 0x66385fa3
error CallerNotApproved();              // 0x4014f1a5
error InvalidAddress();                 // 0xe6c4247b
error CallerNotOwner();                 // 0x5cd83192
error NotZero();                        // 0x0295aa98
error LiquidityIsLocked();              // 0x6bac637f
error LiquidityAddOwnerOnly();          // 0x878d6363
error Overflow();                       // 0x35278d12
error WalletLocked();                   // 0xd550ed24
error LockTimeTooLong();                // 0xb660e89a
error LockTimeTooShort();               // 0x6badcecf
error NotLocked();                      // 0x1834e265
error AmountMustBeGreaterThanZero();    // 0x5e85ae73
error Expired();                        // 0x203d82d8
error InvalidSignature();               // 0x8baa579f
error AmountLargerThanAllowance();      // 0x9b144c57
error AmountOutOfRange();               // 0xc64200e9
error Unlocked();                       // 0x19aad371
error FailedEthSend();                  // 0xb5747cc7

// File: EverRise-v3/Interfaces/IERC2612-Permit.sol

pragma solidity 0.8.13;
interface IERC2612 {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
    function nonces(address owner) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// File: EverRise-v3/Interfaces/IERC173-Ownable.sol

interface IOwnable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function owner() external view returns (address);
    function transferOwnership(address newOwner) external;
}

// File: EverRise-v3/Abstract/Context.sol

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}


// File: EverRise-v3/Interfaces/IERC721-Nft.sol

interface IERC721 /* is ERC165 */ {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// File: EverRise-v3/Interfaces/InftEverRise.sol

struct StakingDetails {
    uint96 initialTokenAmount;    // Max 79 Bn tokens
    uint96 withdrawnAmount;       // Max 79 Bn tokens
    uint48 depositTime;           // 8 M years
    uint8 numOfMonths;            // Max 256 month period
    uint8 achievementClaimed;
    // 256 bits, 20000 gwei gas
    address stakerAddress;        // 160 bits (96 bits remaining)
    uint32 nftId;                 // Max 4 Bn nfts issued
    uint32 lookupIndex;           // Max 4 Bn active stakes
    uint24 stakerIndex;           // Max 16 M active stakes per wallet
    uint8 isActive;
    // 256 bits, 20000 gwei gas
} // Total 512 bits, 40000 gwei gas

interface InftEverRise is IERC721 {
    function voteEscrowedBalance(address account) external view returns (uint256);
    function unclaimedRewardsBalance(address account) external view returns (uint256);
    function totalAmountEscrowed() external view returns (uint256);
    function totalAmountVoteEscrowed() external view returns (uint256);
    function totalRewardsDistributed() external view returns (uint256);
    function totalRewardsUnclaimed() external view returns (uint256);

    function createRewards(uint256 tAmount) external;

    function getNftData(uint256 id) external view returns (StakingDetails memory);
    function enterStaking(address fromAddress, uint96 amount, uint8 numOfMonths) external returns (uint32 nftId);
    function leaveStaking(address fromAddress, uint256 id, bool overrideNotClaimed) external returns (uint96 amount);
    function earlyWithdraw(address fromAddress, uint256 id, uint96 amount) external returns (uint32 newNftId, uint96 penaltyAmount);
    function withdraw(address fromAddress, uint256 id, uint96 amount, bool overrideNotClaimed) external returns (uint32 newNftId);
    function bridgeStakeNftOut(address fromAddress, uint256 id) external returns (uint96 amount);
    function bridgeOrAirdropStakeNftIn(address toAddress, uint96 depositAmount, uint8 numOfMonths, uint48 depositTime, uint96 withdrawnAmount, uint96 rewards, bool achievementClaimed) external returns (uint32 nftId);
    function addStaker(address staker, uint256 nftId) external;
    function removeStaker(address staker, uint256 nftId) external;
    function reissueStakeNft(address staker, uint256 oldNftId, uint256 newNftId) external;
    function increaseStake(address staker, uint256 nftId, uint96 amount) external returns (uint32 newNftId, uint96 original, uint8 numOfMonths);
    function splitStake(uint256 id, uint96 amount) external payable returns (uint32 newNftId0, uint32 newNftId1);
    function claimAchievement(address staker, uint256 nftId) external returns (uint32 newNftId);
    function stakeCreateCost() external view returns (uint256);
    function approve(address owner, address _operator, uint256 nftId) external;
}
// File: EverRise-v3/Interfaces/IEverRiseWallet.sol

struct ApprovalChecks {
    // Prevent permits being reused (IERC2612)
    uint64 nonce;
    // Allow revoke all spenders/operators approvals in single txn
    uint32 nftCheck;
    uint32 tokenCheck;
    // Allow auto timeout on approvals
    uint16 autoRevokeNftHours;
    uint16 autoRevokeTokenHours;
    // Allow full wallet locking of all transfers
    uint48 unlockTimestamp;
}

struct Allowance {
    uint128 tokenAmount;
    uint32 nftCheck;
    uint32 tokenCheck;
    uint48 timestamp;
    uint8 nftApproval;
    uint8 tokenApproval;
}

interface IEverRiseWallet {
    event RevokeAllApprovals(address indexed account, bool tokens, bool nfts);
    event SetApprovalAutoTimeout(address indexed account, uint16 tokensHrs, uint16 nftsHrs);
    event LockWallet(address indexed account, address altAccount, uint256 length);
    event LockWalletExtend(address indexed account, uint256 length);
}
// File: EverRise-v3/Interfaces/IUniswap.sol

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r,bytes32 s) external;
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function nonces(address owner) external view returns (uint256);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function kLast() external view returns (uint256);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function MINIMUM_LIQUIDITY() external pure returns (uint256);
}

interface IUniswapV2Router01 {
    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline) external payable returns (uint256[] memory amounts);
    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable returns (uint256[] memory amounts);
    function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
    function removeLiquidity(address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns (uint256 amountA, uint256 amountB);
    function removeLiquidityETH(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external returns (uint256 amountToken, uint256 amountETH);
    function removeLiquidityWithPermit(address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint256 amountA, uint256 amountB);
    function removeLiquidityETHWithPermit(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint256 amountToken, uint256 amountETH);
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    function swapTokensForExactTokens(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    function swapTokensForExactETH(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountOut);
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountIn);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external returns (uint256 amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint256 amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline ) external;
}
// File: EverRise-v3/Abstract/ErrorNotZeroAddress.sol

contract Ownable is IOwnable, Context {
    address public owner;

    function _onlyOwner() private view {
        if (owner != _msgSender()) revert CallerNotOwner();
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    constructor() {
        address msgSender = _msgSender();
        owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    // Allow contract ownership and access to contract onlyOwner functions
    // to be locked using EverOwn with control gated by community vote.
    //
    // EverRise ($RISE) stakers become voting members of the
    // decentralized autonomous organization (DAO) that controls access
    // to the token contract via the EverRise Ecosystem dApp EverOwn
    function transferOwnership(address newOwner) external virtual onlyOwner {
        if (newOwner == address(0)) revert NotZeroAddress();

        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
// File: EverRise-v3/Abstract/EverRiseRoles.sol


abstract contract EverRiseRoles is Ownable {
    mapping (Role => mapping (address => bool)) public roles;

    enum Role 
    { 
        NotValidRole, 
        BuyBack, 
        NftBridge,
        Limits, 
        Liquidity, 
        Fees,
        Exchanges,
        CrossChainBuyback,
        Upgrader
    }

    event ControlAdded(address indexed controller, Role indexed role);
    event ControlRemoved(address indexed controller, Role indexed role);
    
    function _onlyController(Role role) private view {
        if (!roles[role][_msgSender()]) revert CallerNotApproved();
    }
    
    modifier onlyController(Role role) {
        _onlyController(role);
        _;
    }

    constructor() {
        address deployer = _msgSender();
        ownerRoles(deployer, true);
    }
    
    function transferOwnership(address newOwner) override external onlyOwner {
        if (newOwner == address(0)) revert NotZeroAddress();

        address previousOwner = owner;
        ownerRoles(previousOwner, false);
        ownerRoles(newOwner, true);

        owner = newOwner;

        emit OwnershipTransferred(previousOwner, newOwner);
    }

    function ownerRoles(address _owner, bool enable) private {
        roles[Role.BuyBack][_owner] = enable;
        roles[Role.NftBridge][_owner] = enable;
        roles[Role.Limits][_owner] = enable;
        roles[Role.Liquidity][_owner] = enable;
        roles[Role.Fees][_owner] = enable;
        roles[Role.Exchanges][_owner] = enable;
        roles[Role.CrossChainBuyback][_owner] = enable;
        roles[Role.Upgrader][_owner] = enable;
    }

    function addControlRole(address newController, Role role) external onlyOwner
    {
        if (role == Role.NotValidRole) revert NotZero();
        if (newController == address(0)) revert NotZeroAddress();

        roles[role][newController] = true;

        emit ControlAdded(newController, role);
    }

    function removeControlRole(address oldController, Role role) external onlyOwner
    {
        if (role == Role.NotValidRole) revert NotZero();
        if (oldController == address(0)) revert NotZeroAddress();

        roles[role][oldController] = false;

        emit ControlRemoved(oldController, role);
    }
}
// File: EverRise-v3/Abstract/EverRiseLib.sol

library EverRiseAddressNumberLib {
    function toUint96(uint256 value) internal pure returns (uint96) {
        if (value > type(uint96).max) revert Overflow();
        return uint96(value);
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    bytes private constant token0Selector =
        abi.encodeWithSelector(IUniswapV2Pair.token0.selector);
    bytes private constant token1Selector =
        abi.encodeWithSelector(IUniswapV2Pair.token1.selector);

    function pairTokens(address pair) internal view returns (address token0, address token1) {
        // Do not check if pair is not a contract to avoid warning in txn log
        if (!isContract(pair)) return (address(0), address(0)); 

        return (tokenLookup(pair, token0Selector), tokenLookup(pair, token1Selector));
    }

    function tokenLookup(address pair, bytes memory selector)
        private
        view
        returns (address)
    {
        (bool success, bytes memory data) = pair.staticcall(selector);

        if (success && data.length >= 32) {
            return abi.decode(data, (address));
        }
        
        return address(0);
    }

}

library EverRiseLib {
    function swapTokensForEth(
        IUniswapV2Router02 uniswapV2Router,
        uint256 tokenAmount
    ) external {
        address tokenAddress = address(this);
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = uniswapV2Router.WETH();

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            tokenAddress, // The contract
            block.timestamp
        );
    }

    function swapETHForTokensNoFee(
        IUniswapV2Router02 uniswapV2Router,
        address toAddress, 
        uint256 amount
    ) external {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        // make the swap
        uniswapV2Router.swapExactETHForTokens{
            value: amount
        }(
            0, // accept any amount of Tokens
            path,
            toAddress, // The contract
            block.timestamp
        );
    }
}
// File: EverRise-v3/Interfaces/IEverDrop.sol

interface IEverDrop {
    function mirgateV1V2Holder(address holder, uint96 amount) external returns(bool);
    function mirgateV2Staker(address toAddress, uint96 rewards, uint96 depositTokens, uint8 numOfMonths, uint48 depositTime, uint96 withdrawnAmount) external returns(uint256 nftId);
}
// File: EverRise-v3/Interfaces/IERC20-Token.sol

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transferFromWithPermit(address sender, address recipient, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
// File: EverRise-v3/Abstract/EverRiseWallet.sol

abstract contract EverRiseWallet is Context, IERC2612, IEverRiseWallet, IERC20Metadata {
    using EverRiseAddressNumberLib for address;

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 public constant DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    mapping (address => ApprovalChecks) internal _approvals;
    mapping (address => mapping (address => Allowance)) public allowances;
    //Lock related fields
    mapping(address => address) private _userUnlocks;

    function _walletLock(address fromAddress) internal view {
        if (_isWalletLocked(fromAddress)) revert WalletLocked();
    }

    modifier walletLock(address fromAddress) {
        _walletLock(fromAddress);
        _;
    }
    
    function _isWalletLocked(address fromAddress) internal view returns (bool) {
        return _approvals[fromAddress].unlockTimestamp > block.timestamp;
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        // Unique DOMAIN_SEPARATOR per user nbased on their current token check
        uint32 tokenCheck = _approvals[_msgSender()].tokenCheck;

        return keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                keccak256(abi.encodePacked(tokenCheck)),
                block.chainid,
                address(this)
            )
        );
    }

    function name() public virtual view returns (string memory);

    function nonces(address owner) external view returns (uint256) {
        return _approvals[owner].nonce;
    }

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal {
        if (operator == address(0)) revert NotZeroAddress();

        Allowance storage _allowance = allowances[owner][operator];
        ApprovalChecks storage _approval = _approvals[owner];
        if (approved) {

            uint16 autoRevokeNftHours = _approval.autoRevokeNftHours;
            uint48 timestamp = autoRevokeNftHours == 0 ? 
                type(uint48).max : // Don't timeout approval
                uint48(block.timestamp) + autoRevokeNftHours * 1 hours; // Timeout after user chosen period

            _allowance.nftCheck = _approval.nftCheck;
            _allowance.timestamp = timestamp;
            _allowance.nftApproval = 1;
        } else {
            unchecked {
                // nftCheck gets incremented, so set one behind approval
                _allowance.nftCheck = _approval.nftCheck - 1;
            }
            _allowance.nftApproval = 0;
        }
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        if (spender == address(0)) revert NotZeroAddress();
        if (deadline < block.timestamp) revert Expired();

        ApprovalChecks storage _approval = _approvals[owner];
        uint64 nonce = _approval.nonce;

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonce,
                        deadline
                    )
                )
            )
        );

        unchecked {
            // Nonces can wrap
            ++nonce;
        }

        _approval.nonce = nonce;
        
        if (v < 27) {
            v += 27;
        } else if (v > 30) {
            digest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", digest));
        }

        address recoveredAddress = ecrecover(digest, v, r, s);
        if (recoveredAddress == address(0) || recoveredAddress != owner) revert InvalidSignature();
        
        _approve(owner, spender, value, true);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(_msgSender(), spender, amount, true);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount,
        bool extend
    ) internal returns (bool) {
        if (owner == address(0)) revert NotZeroAddress();
        if (spender == address(0)) revert NotZeroAddress();

        if (amount > type(uint128).max) amount = type(uint128).max;

        ApprovalChecks storage _approval = _approvals[owner];
        Allowance storage _allowance = allowances[owner][spender];

        _allowance.tokenAmount = uint128(amount);
        _allowance.tokenCheck = _approval.tokenCheck;
        if (extend) {
            uint48 autoRevokeTokenHours = _approval.autoRevokeTokenHours;
            // Time extention approval
            _allowance.timestamp = autoRevokeTokenHours == 0 ? 
                type(uint48).max : // Don't timeout approval
                uint48(block.timestamp) + autoRevokeTokenHours * 1 hours; // Timeout after user chosen period
        }

        _allowance.tokenApproval = 1;
        
        emit Approval(owner, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        uint32 tokenCheck = _approvals[owner].tokenCheck;
        Allowance storage allowanceSettings = allowances[owner][spender];

        if (tokenCheck != allowanceSettings.tokenCheck ||
            block.timestamp > allowanceSettings.timestamp ||
            allowanceSettings.tokenApproval != 1)
        {
            return 0;
        }

        return allowanceSettings.tokenAmount;
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {

        _transfer(sender, recipient, amount);

        uint256 _allowance = allowance(sender, _msgSender());
        if (amount > _allowance) revert AmountLargerThanAllowance();
        unchecked {
            _allowance -= amount;
        }
        _approve(sender, _msgSender(), _allowance, false);
        return true;
    }

    function transferFromWithPermit(
        address sender,
        address recipient,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool) {
        permit(sender, _msgSender(), amount, deadline, v, r, s);

        return transferFrom(sender, recipient, amount);
    }

    function lockTokensAndNfts(address altAccount, uint48 length) external walletLock(_msgSender()) {
        if (altAccount == address(0)) revert NotZeroAddress();
        if (length / 1 days > 10 * 365 days) revert LockTimeTooLong();

        _approvals[_msgSender()].unlockTimestamp = uint48(block.timestamp) + length;
        _userUnlocks[_msgSender()] = altAccount;

        emit LockWallet(_msgSender(), altAccount, length);
    }

    function extendLockTokensAndNfts(uint48 length) external {
        if (length / 1 days > 10 * 365 days) revert LockTimeTooLong();
        uint48 currentLock = _approvals[_msgSender()].unlockTimestamp;

        if (currentLock < block.timestamp) revert Unlocked();

        uint48 newLock = uint48(block.timestamp) + length;
        if (currentLock > newLock) revert LockTimeTooShort();
        _approvals[_msgSender()].unlockTimestamp = newLock;

        emit LockWalletExtend(_msgSender(), length);
    }

    function unlockTokensAndNfts(address actualAccount) external {
        if (_userUnlocks[actualAccount] != _msgSender()) revert CallerNotApproved();
        uint48 currentLock = _approvals[_msgSender()].unlockTimestamp;

        if (currentLock < block.timestamp) revert Unlocked();

        _approvals[_msgSender()].unlockTimestamp = 1;
    }

    function revokeApprovals(bool tokens, bool nfts) external {
        address account = _msgSender();
        ApprovalChecks storage _approval = _approvals[account];

        unchecked {
            // Nonces can wrap
            if (nfts) {
                ++_approval.nftCheck;
            }
            if (tokens) {
                ++_approval.tokenCheck;
            }
        }

        emit RevokeAllApprovals(account, tokens, nfts);
    }

    function setAutoTimeout(uint16 tokensHrs, uint16 nftsHrs) external {
        address account = _msgSender();
        ApprovalChecks storage _approval = _approvals[account];

        _approval.autoRevokeNftHours = nftsHrs;
        _approval.autoRevokeTokenHours = tokensHrs;

        emit SetApprovalAutoTimeout(account, tokensHrs, nftsHrs);
    }

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function _isApprovedForAll(address account, address operator) internal view returns (bool) {
        uint32 nftCheck = _approvals[account].nftCheck;
        Allowance storage _allowance = allowances[account][operator];

        if (nftCheck != _allowance.nftCheck ||
            block.timestamp > _allowance.timestamp ||
            _allowance.nftApproval != 1)
        {
            return false;
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual;
}
// File: EverRise-v3/Interfaces/IEverRise.sol

interface IEverRise is IERC20Metadata {
    function totalBuyVolume() external view returns (uint256);
    function totalSellVolume() external view returns (uint256);
    function holders() external view returns (uint256);
    function uniswapV2Pair() external view returns (address);
    function transferStake(address fromAddress, address toAddress, uint96 amountToTransfer) external;
    function isWalletLocked(address fromAddress) external view returns (bool);
    function setApprovalForAll(address fromAddress, address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function isExcludedFromFee(address account) external view returns (bool);

    function approvals(address account) external view returns (ApprovalChecks memory);
}
// File: EverRise-v3/Abstract/EverRiseConfigurable.sol

abstract contract EverRiseConfigurable is EverRiseRoles, EverRiseWallet, IEverRise {
    using EverRiseAddressNumberLib for uint256;

    event BuyBackEnabledUpdated(bool enabled);
    event SwapEnabledUpdated(bool enabled);

    event ExcludeFromFeeUpdated(address account);
    event IncludeInFeeUpdated(address account);

    event LiquidityFeeUpdated(uint256 newValue);
    event TransactionCapUpdated(uint256 newValue);
    event MinStakeSizeUpdated(uint256 newValue);

    event BusinessDevelopmentDivisorUpdated(uint256 newValue);
    event MinTokensBeforeSwapUpdated(uint256 newValue);
    event BuybackMinAvailabilityUpdated(uint256 newValue);
    event MinBuybackAmountUpdated(uint256 newvalue);
    event MaxBuybackAmountUpdated(uint256 newvalue);

    event BuybackUpperLimitUpdated(uint256 newValue);
    event BuyBackTriggerTokenLimitUpdated(uint256 newValue);
    event BuybackBlocksUpdated(uint256 newValue);

    event BridgeVaultAddressUpdated(address indexed contractAddress);
    event BurnAddressUpdated(address indexed deadAddress);
    event OffChainBalanceExcluded(bool enable);
    event RouterAddressUpdated(address indexed newAddress);
    event BusinessDevelopmentAddressUpdated(address indexed newAddress);
    event StakingAddressUpdated(address indexed contractAddress);

    event LiquidityLocked(bool isLocked);
    event AutoBurnEnabled(bool enabled);
    event BurnableTokensZeroed();

    event ExchangeHotWalletAdded(address indexed exchangeHotWallet);
    event ExchangeHotWalletRemoved(address indexed exchangeHotWallet);
    event BuyBackTriggered();
    event BuyBackCrossChainTriggered();

    address payable public businessDevelopmentAddress =
        payable(0x24D8DAbebD6c0d5CcC88EC40D95Bf8eB64F0CF9E); // Business Development Address
    address public everBridgeVault;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    
    mapping (address => bool) internal _isExcludedFromFee;
    mapping (address => bool) internal _exchangeHotWallet;

    uint8 public constant decimals = 18;
    // Golden supply
    uint96 internal immutable _totalSupply = uint96(7_1_618_033_988 * 10**decimals);

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    // Fee and max txn are set by setTradingEnabled
    // to allow upgrading balances to arrange their wallets
    // and stake their assets before trading start

    uint256 public totalBuyVolume;
    uint256 public totalSellVolume;
    uint256 public transactionCap;
    uint96 public liquidityFee = 6;

    uint256 public businessDevelopmentDivisor = 2;

    uint96 internal _minimumTokensBeforeSwap = uint96(5 * 10**6 * 10**decimals);
    uint256 internal _buyBackUpperLimit = 10 * 10**18;
    uint256 internal _buyBackTriggerTokenLimit = 1 * 10**6 * 10**decimals;
    uint256 internal _buyBackMinAvailability = 1 * 10**18; //1 BNB

    uint256 internal _nextBuybackAmount;
    uint256 internal _latestBuybackBlock;
    uint256 internal _numberOfBlocks = 1000;
    uint256 internal _minBuybackAmount = 1 * 10**18 / (10**1);
    uint256 internal _maxBuybackAmount = 1 * 10**18;

    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.
    uint256 constant _FALSE = 1;
    uint256 constant _TRUE = 2;

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to modifiers will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 internal _inSwap = _FALSE;
    uint256 internal _swapEnabled = _FALSE;
    uint256 internal _buyBackEnabled = _FALSE;
    uint256 internal _liquidityLocked = _TRUE;
    uint256 internal _offchainBalanceExcluded = _FALSE;
    uint256 internal _autoBurn = _FALSE;
    uint256 internal _burnableTokens = 1;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    InftEverRise public stakeToken;

    function swapEnabled() external view returns (bool) {
        return _swapEnabled == _TRUE;
    }
    function offchainBalanceExcluded() external view returns (bool) {
        return _offchainBalanceExcluded == _TRUE;
    }
    function buyBackEnabled() external view returns (bool) {
        return _buyBackEnabled == _TRUE;
    }
    function liquidityLocked() external view returns (bool) {
        return _liquidityLocked == _TRUE;
    }
    function autoBurn() external view returns (bool) {
        return _autoBurn == _TRUE;
    }

    function setBurnableTokensZero() external onlyController(Role.Liquidity)  {
        // set to 1 rather than zero to save on gas
        _burnableTokens = 1;
        emit BurnableTokensZeroed();
    }
    function setBurnAddress(address _burnAddress) external onlyController(Role.Liquidity)  {
        // May be bridgable burn (so only send to actual burn address on one chain)
        burnAddress = _burnAddress;
        emit BurnAddressUpdated(_burnAddress);
    }

    function setOffchainBalanceExcluded(bool _enabled) external onlyOwner {
        _offchainBalanceExcluded = _enabled ? _TRUE : _FALSE;
        emit OffChainBalanceExcluded(_enabled);
    }

    function setLiquidityLock(bool _enabled) public onlyController(Role.Liquidity) {
        _liquidityLocked = _enabled ? _TRUE : _FALSE;
        emit LiquidityLocked(_enabled);
    }

    function setAutoBurn(bool _enabled) external onlyController(Role.Liquidity) {
        _autoBurn = _enabled ? _TRUE : _FALSE;
        emit AutoBurnEnabled(_enabled);
    }

    function excludeFromFee(address account) public onlyController(Role.Fees) {
        if (_isExcludedFromFee[account]) revert InvalidAddress();
        
        _isExcludedFromFee[account] = true;
        emit ExcludeFromFeeUpdated(account);
    }

    function addExchangeHotWallet(address account) external onlyController(Role.Exchanges) {
        _exchangeHotWallet[account] = true;
        emit ExchangeHotWalletAdded(account);
    }

    function removeExchangeHotWallet(address account) external onlyController(Role.Exchanges) {
        _exchangeHotWallet[account] = false;
        emit ExchangeHotWalletRemoved(account);
    }

    function isExchangeHotWallet(address account) public view returns(bool) {
        return _exchangeHotWallet[account];
    }

    function includeInFee(address account) external onlyController(Role.Fees) {
        if (!_isExcludedFromFee[account]) revert InvalidAddress();

        _isExcludedFromFee[account] = false;
        emit IncludeInFeeUpdated(account);
    }

    function setTransactionCap(uint256 txAmount) external onlyController(Role.Limits) {
        // Never under 0.001%
        if (txAmount < _totalSupply / 100_000) revert AmountOutOfRange();

        transactionCap = txAmount;
        emit TransactionCapUpdated(txAmount);
    }

    function setNumberOfBlocksForBuyback(uint256 value) external onlyController(Role.BuyBack){
        if (value < 100 || value > 1_000_000) revert AmountOutOfRange();
        _numberOfBlocks = value;
        emit BuybackBlocksUpdated(value);
    }

    function setBusinessDevelopmentDivisor(uint256 divisor) external onlyController(Role.Liquidity) {
        if (divisor > liquidityFee) revert AmountOutOfRange();

        businessDevelopmentDivisor = divisor;
        emit BusinessDevelopmentDivisorUpdated(divisor);
    }

    function setNumTokensSellToAddToLiquidity(uint96 minimumTokensBeforeSwap)
        external
        onlyController(Role.Liquidity)
    {
        if (minimumTokensBeforeSwap > 1_000_000_000) revert AmountOutOfRange();

        _minimumTokensBeforeSwap = uint96(minimumTokensBeforeSwap * (10**uint256(decimals)));
        emit MinTokensBeforeSwapUpdated(minimumTokensBeforeSwap);
    }

    function setBuybackUpperLimit(uint256 buyBackLimit, uint256 numOfDecimals)
        external
        onlyController(Role.BuyBack)
    {
        // Catch typos, if decimals are pre-added
        if (buyBackLimit > 1_000_000_000) revert AmountOutOfRange();

        _buyBackUpperLimit = buyBackLimit * (10**18) / (10**numOfDecimals);
        emit BuybackUpperLimitUpdated(_buyBackUpperLimit);
    }

    function setMinBuybackAmount(uint256 minAmount, uint256 numOfDecimals)
        external
        onlyController(Role.BuyBack)
    {
        // Catch typos, if decimals are pre-added
        if (minAmount > 1_000) revert AmountOutOfRange();

        _minBuybackAmount = minAmount * (10**18) / (10**numOfDecimals);
        emit MinBuybackAmountUpdated(minAmount);
    }

    function setMaxBuybackAmountUpdated(uint256 maxAmount, uint256 numOfDecimals)
        external
        onlyController(Role.BuyBack)
    {
        // Catch typos, if decimals are pre-added
        if (maxAmount > 1_000_000) revert AmountOutOfRange();

        _maxBuybackAmount = maxAmount * (10**18) / (10**numOfDecimals);
        emit MaxBuybackAmountUpdated(maxAmount);
    }

    function setBuybackTriggerTokenLimit(uint256 buyBackTriggerLimit)
        external
        onlyController(Role.BuyBack)
    {
        if (buyBackTriggerLimit > 100_000_000) revert AmountOutOfRange();
        
        _buyBackTriggerTokenLimit = buyBackTriggerLimit * (10**uint256(decimals));
        emit BuyBackTriggerTokenLimitUpdated(_buyBackTriggerTokenLimit);
    }

    function setBuybackMinAvailability(uint256 amount, uint256 numOfDecimals)
        external
        onlyController(Role.BuyBack)
    {
        if (amount > 100_000) revert AmountOutOfRange();

        _buyBackMinAvailability = amount * (10**18) / (10**numOfDecimals);
        emit BuybackMinAvailabilityUpdated(_buyBackMinAvailability);
    }

    function setBuyBackEnabled(bool _enabled) external onlyController(Role.BuyBack) {
        _buyBackEnabled = _enabled ? _TRUE : _FALSE;
        emit BuyBackEnabledUpdated(_enabled);
    }

    function setBusinessDevelopmentAddress(address newAddress)
        external
        onlyController(Role.Liquidity)
    {
        if (newAddress == address(0)) revert NotZeroAddress();

        businessDevelopmentAddress = payable(newAddress);
        emit BusinessDevelopmentAddressUpdated(newAddress);
    }

    function setEverBridgeVaultAddress(address contractAddress)
        external
        onlyOwner
    {
        
        excludeFromFee(contractAddress);
        
        everBridgeVault = contractAddress;
        emit BridgeVaultAddressUpdated(contractAddress);
    }

    function setStakingAddress(address contractAddress) external onlyOwner {
        stakeToken = InftEverRise(contractAddress);

        excludeFromFee(contractAddress);

        emit StakingAddressUpdated(contractAddress);
    }

    function setRouterAddress(address newAddress) external onlyController(Role.Liquidity) {
        if (newAddress == address(0)) revert NotZeroAddress();

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(newAddress); 
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(
            address(this),
            _uniswapV2Router.WETH()
        );

        uniswapV2Router = _uniswapV2Router;
        emit RouterAddressUpdated(newAddress);
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function setSwapEnabled(bool _enabled) external onlyOwner {
        _swapEnabled = _enabled ? _TRUE : _FALSE;
        emit SwapEnabledUpdated(_enabled);
    }

    function hasTokenStarted() public view returns (bool) {
        return transactionCap > 0;
    }

    function setLiquidityFeePercent(uint96 liquidityFeeRate) external onlyController(Role.Liquidity) {
        if (liquidityFeeRate > 10) revert AmountOutOfRange();
        liquidityFee = liquidityFeeRate;
        emit LiquidityFeeUpdated(liquidityFeeRate);
    }
}
// File: EverRise-v3/EverRise.sol

// Copyright (c) 2022 EverRise Pte Ltd. All rights reserved.
// EverRise licenses this file to you under the MIT license.
/*
 The EverRise token is the keystone in the EverRise Ecosytem of dApps
 and the overaching key that unlocks multi-blockchain unification via
 the EverBridge.

 On EverRise token txns 6% buyback and business development fees are collected
 * 4% for token Buyback from the market, 
     with bought back tokens directly distributed as ve-staking rewards
 * 2% for Business Development (Development, Sustainability and Marketing)

  ________                              _______   __
 /        |                            /       \ /  |
 $$$$$$$$/__     __  ______    ______  $$$$$$$  |$$/   _______   ______  v3.14159265
 $$ |__  /  \   /  |/      \  /      \ $$ |__$$ |/  | /       | /      \
 $$    | $$  \ /$$//$$$$$$  |/$$$$$$  |$$    $$< $$ |/$$$$$$$/ /$$$$$$  |
 $$$$$/   $$  /$$/ $$    $$ |$$ |  $$/ $$$$$$$  |$$ |$$      \ $$    $$ |
 $$ |_____ $$ $$/  $$$$$$$$/ $$ |      $$ |  $$ |$$ | $$$$$$  |$$$$$$$$/
 $$       | $$$/   $$       |$$ |      $$ |  $$ |$$ |/     $$/ $$       |
 $$$$$$$$/   $/     $$$$$$$/ $$/       $$/   $$/ $$/ $$$$$$$/   $$$$$$$/

 Learn more about EverRise and the EverRise Ecosystem of dApps and
 how our utilities and partners can help protect your investors
 and help your project grow: https://www.everrise.com
*/

// 2^96 is 79 * 10**10 * 10**18
struct TransferDetails {
    uint96 balance0;
    address to;

    uint96 balance1;
    address origin;

    uint32 blockNumber;
}

contract EverRise is EverRiseConfigurable, IEverDrop {
    using EverRiseAddressNumberLib for address;
    using EverRiseAddressNumberLib for uint256;

    event BuybackTokensWithETH(uint256 amountIn, uint256 amountOut);
    event ConvertTokensForETH(uint256 amountIn, uint256 amountOut);

    event TokenStarted();
    event RewardStakers(uint256 amount);
    event AutoBurn(uint256 amount);

    event StakingIncreased(address indexed from, uint256 amount, uint8 numberOfmonths);
    event StakingDecreased(address indexed from, uint256 amount);

    event RiseBridgedIn(address indexed contractAddress, address indexed to, uint256 amount);
    event RiseBridgedOut(address indexed contractAddress, address indexed from, uint256 amount);
    event NftBridgedIn(address indexed contractAddress, address indexed operator, address indexed to, uint256 id, uint256 value);
    event NftBridgedOut(address indexed contractAddress, address indexed operator, address indexed from, uint256 id, uint256 value);
    event TransferExternalTokens(address indexed tokenAddress, address indexed to, uint256 count);

    // Holder count
    uint256 private _holders;
    // Balance and locked (staked) balance
    mapping (address => uint96) private _tOwned;
    mapping (address => uint96) private _amountLocked;

    // Tracking for protections against sandwich trades
    // and rogue LP pairs
    mapping (address => uint256) private _lastTrade;
    TransferDetails private _lastTransfer;

    string public constant symbol = "RISE";
    function name() public override (EverRiseWallet, IERC20Metadata) pure returns (string memory) {
        return "EverRise";
    }

    modifier lockTheSwap() {
        require(_inSwap != _TRUE);
        _inSwap = _TRUE;
        _;
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _inSwap = _FALSE;
    }

    constructor(address routerAddress) {
        if (routerAddress == address(0)) revert NotZeroAddress();

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress);
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); //Pancakeswap router mainnet - BSC
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); //Testnet
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xa5e0829caced8ffdd4de3c43696c57f7d7a678ff); //Quickswap V2 router mainnet - Polygon
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506); //Sushiswap router mainnet - Polygon
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //Uniswap V2 router mainnet - ETH
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
  
        _isExcludedFromFee[owner] = true;
        _isExcludedFromFee[address(this)] = true;

        // Put all tokens in contract so we can airdrop
        _tOwned[address(this)] = _totalSupply;
        emit Transfer(address(0), address(this), _totalSupply);

        _holders = 1;
    }

    // Function to receive ETH when msg.data is be empty
    receive() external payable {}

    // Balances
    function isWalletLocked(address fromAddress) override (IEverRise) external view returns (bool) {
        return _isWalletLocked(fromAddress);
    }

    function holders() external view returns (uint256) {
        return _holders;
    }

    function getAmountLocked(address account) external view returns (uint256) {
        return _amountLocked[account];
    }

    function _balanceOf(address account) private view returns (uint256) {
        return _tOwned[account];
    }

    function bridgeVaultLockedBalance() external view returns (uint256) {
        return _balanceOf(everBridgeVault);
    }

    function balanceOf(address account) external view override returns (uint256) {
        // Bridge vault balances are on other chains
        if (account == everBridgeVault && _offchainBalanceExcluded == _TRUE) return 0;

        uint256 balance = _balanceOf(account);
        if (_inSwap != _TRUE &&
            _lastTransfer.blockNumber == uint32(block.number) &&
            account.isContract() &&
            !_isExcludedFromFee[account]
        ) {
            // Balance being checked is same address as last to in _transfer
            // check if likely same txn and a Liquidity Add
            _validateIfLiquidityChange(account, uint112(balance));
        }

        return balance;
    }

    // Transfers

    function approvals(address account) external view returns (ApprovalChecks memory) {
        return _approvals[account]; 
    }
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override walletLock(from) {
        if (from == address(0) || to == address(0)) revert NotZeroAddress();
        if (amount == 0) revert AmountMustBeGreaterThanZero();
        if (amount > (_balanceOf(from) - _amountLocked[from])) revert AmountLargerThanUnlockedAmount();

        bool isIgnoredAddress = _isExcludedFromFee[from] || _isExcludedFromFee[to];

        bool notInSwap = _inSwap != _TRUE;
        bool hasStarted = hasTokenStarted();
        address pair = uniswapV2Pair;
        bool isSell = to == pair;
        bool isBuy = from == pair;
        if (!isIgnoredAddress) {
            if (to == address(this)) revert NotContractAddress();
            if (amount > transactionCap) revert TransferTooLarge();
            if (!hasStarted) revert TokenNotStarted();
            if (notInSwap) {
                // Disallow multiple same source trades in same block
                if ((isSell || isBuy) && _lastTrade[tx.origin] == block.number) {
                    revert SandwichTradesAreDisallowed();
                }

                _lastTrade[tx.origin] = block.number;

                // Following block is for the contract to convert the tokens to ETH and do the buy back
                if (isSell && _swapEnabled == _TRUE) {
                    uint96 swapTokens = _minimumTokensBeforeSwap;
                    if (_balanceOf(address(this)) > swapTokens) {
                        // Greater than to always leave at least 1 token in contract
                        // reducing gas from switching from 0 to not-zero and not tracking
                        // token in holder count changes.
                        _convertTokens(swapTokens);
                    }

                    if (_buyback()) {
                        emit BuyBackTriggered();
                    }
                }
            }
        }

        if (hasStarted) {
            if (isBuy) {
                totalBuyVolume += amount;
            } else if (isSell) { 
                totalSellVolume += amount;
                if (amount > _buyBackTriggerTokenLimit) {
                    // Start at 1% of balance
                    uint256 amountToAdd = address(this).balance / 100;
                    uint256 maxToAdd = _buyBackUpperLimit / 100;
                    // Don't add more than the 1% of the upper limit
                    if (amountToAdd > maxToAdd) amountToAdd = maxToAdd;
                    // Add to next buyback
                    _nextBuybackAmount += amountToAdd;
                }
            }
        }

        // If any account belongs to _isExcludedFromFee account then remove the fee
        bool takeFee = true;
        if (isIgnoredAddress || isExchangeHotWallet(to)) {
            takeFee = false;
        }
        
        // For safety Liquidity Adds should only be done by an owner, 
        // and transfers to and from EverRise Ecosystem contracts
        // are not considered LP adds
        if (notInSwap) {
            if (isIgnoredAddress) {
                // Just set blocknumber to 1 to clear, to save gas on changing back
                _lastTransfer.blockNumber = 1;
            } else {
                // Not in a swap during a LP add, so record the transfer details
                _recordPotentialLiquidityChangeTransaction(to);
            }
        }

        _tokenTransfer(from, to, uint96(amount), takeFee);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint96 amount,
        bool takeFee
    ) private {
        uint96 fromAfter = _tOwned[sender] - amount;
        _tOwned[sender] = fromAfter;

        uint96 tLiquidity = takeFee ? amount * liquidityFee / (10**2) : 0;
        uint96 tTransferAmount = amount - tLiquidity;

        uint96 toBefore = _tOwned[recipient]; 
        _tOwned[recipient] = toBefore + tTransferAmount;

        if (tLiquidity > 0) {
            // Skip writing to save gas if unchanged
            _tOwned[address(this)] += tLiquidity;
        }

        _trackHolders(fromAfter, toBefore);
        if (sender == everBridgeVault) {
            emit RiseBridgedIn(everBridgeVault, recipient, amount);
        } else if (recipient == everBridgeVault) {
            emit RiseBridgedOut(everBridgeVault, sender, amount);
        }

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _lockedTokenTransfer(
        address sender,
        address recipient,
        uint96 amount
    ) private {
        // Do the locked token transfer
        _decreaseLockedAmount(sender, amount, false);
        uint96 fromAfter = _tOwned[sender] - amount;
        _tOwned[sender] = fromAfter;
        
        uint96 toBefore = _tOwned[recipient]; 
        _tOwned[recipient] = toBefore + amount;
        _increaseLockedAmount(recipient, amount);

        _trackHolders(fromAfter, toBefore);

        emit Transfer(sender, recipient, amount);
    }

    function _trackHolders(uint96 fromAfter, uint96 toBefore) private {
        uint256 startHolderCount = _holders;
        uint256 holderCount = startHolderCount;
        
        if (fromAfter == 0) --holderCount;
        if (toBefore == 0) ++holderCount;

        if (startHolderCount != holderCount) {
            // Skip writing to save gas if unchanged
            _holders = holderCount;
        }
    }

    // Buyback
    function crossChainBuyback() external onlyController(Role.CrossChainBuyback) {
        if (_buyback()) {
            emit BuyBackCrossChainTriggered();
        }

        // Is autoburn on?
        if (_autoBurn == _TRUE) {
            uint96 swapTokens = _minimumTokensBeforeSwap;
            // Have we collected enough tokens to burn?
            if (_burnableTokens > swapTokens) {
                unchecked {
                    // Just confirmed is valid above
                    _burnableTokens -= swapTokens;
                }
                // Burn the tokens
                _tokenTransfer(uniswapV2Pair, burnAddress, swapTokens, false);
                // Reset LP balances
                IUniswapV2Pair(uniswapV2Pair).sync();

                emit AutoBurn(swapTokens);
            }
        }
    }

    function _buyback() private returns (bool boughtBack) {
        if (_buyBackEnabled == _TRUE) {
            uint256 balance = address(this).balance;
            if (balance > _buyBackMinAvailability &&
                block.number > _latestBuybackBlock + _numberOfBlocks 
            ) {
                // Max of 10% of balance
                balance /= 10;
                uint256 buybackAmount = _nextBuybackAmount;
                if (buybackAmount > _maxBuybackAmount) {
                    buybackAmount = _maxBuybackAmount;
                }
                if (buybackAmount > balance) {
                    // Don't try to buyback more than is available.
                    buybackAmount = balance;
                }

                if (buybackAmount > 0) {
                    boughtBack = _buyBackTokens(buybackAmount);
                }
            }
        }
    }

    function _buyBackTokens(uint256 amount) private lockTheSwap returns (bool boughtBack) {
        _nextBuybackAmount = _minBuybackAmount; // reset the next buyback amount, set non-zero to save on future gas

        if (amount > 0) {
            uint256 tokensBefore = _balanceOf(address(stakeToken));
            EverRiseLib.swapETHForTokensNoFee(uniswapV2Router, address(stakeToken), amount);
            // Don't trust the return value; calculate it ourselves
            uint256 tokensReceived = _balanceOf(address(stakeToken)) - tokensBefore;

            emit BuybackTokensWithETH(amount, tokensReceived);
            _latestBuybackBlock = block.number;
            //Distribute the rewards to the staking pool
            _distributeStakingRewards(tokensReceived);

            boughtBack = true;
        }
    }
    
    // Non-EverSwap LP conversion
    function _convertTokens(uint256 tokenAmount) private lockTheSwap {
        uint256 initialETHBalance = address(this).balance;

        _approve(address(this), address(uniswapV2Router), tokenAmount, true);
        // Mark the tokens as available to burn
        _burnableTokens += uint96(tokenAmount);

        EverRiseLib.swapTokensForEth(uniswapV2Router, tokenAmount);

        uint256 transferredETHBalance = address(this).balance - initialETHBalance;
        emit ConvertTokensForETH(tokenAmount, transferredETHBalance);

        // Send split to Business Development address
        transferredETHBalance = transferredETHBalance * businessDevelopmentDivisor / liquidityFee;
        sendEthViaCall(businessDevelopmentAddress, transferredETHBalance);
    }

    // Staking

    function _distributeStakingRewards(uint256 amount) private {
        if (amount > 0) {
            stakeToken.createRewards(amount);

            emit RewardStakers(amount);
        }
    }
    
    function transferStake(address fromAddress, address toAddress, uint96 amountToTransfer) external walletLock(fromAddress) {
        if (_msgSender() != address(stakeToken)) revert NotStakeContractRequesting();

        _lockedTokenTransfer(fromAddress, toAddress, amountToTransfer);
    }

    function enterStaking(uint96 amount, uint8 numOfMonths) external payable walletLock(_msgSender()) {
        address staker = _msgSender();
        if (msg.value < stakeToken.stakeCreateCost()) revert NotEnoughToCoverStakeFee();

        uint32 nftId = stakeToken.enterStaking(staker, amount, numOfMonths);

        _lockAndAddStaker(staker, amount, numOfMonths, nftId);
    }

    function increaseStake(uint256 nftId, uint96 amount)
        external walletLock(_msgSender())
    {
        address staker = _msgSender();
        _increaseLockedAmount(staker, amount);

        uint8 numOfMonths;
        uint96 original;
        (, original, numOfMonths) = stakeToken.increaseStake(staker, nftId, amount);

        emit StakingDecreased(staker, original);
        emit StakingIncreased(staker, original + amount, numOfMonths);
    }

    function _increaseLockedAmount(address staker, uint96 amount) private {
        uint96 lockedAmount = _amountLocked[staker] + amount;
        if (lockedAmount > _balanceOf(staker)) revert AmountLargerThanUnlockedAmount();
        _amountLocked[staker] = lockedAmount;
        
        emit Transfer(staker, staker, amount);
    }

    function _decreaseLockedAmount(address staker, uint96 amount, bool emitEvent) private {
        _amountLocked[staker] -= amount;
        if (emitEvent) {
            emit StakingDecreased(staker, amount);
            emit Transfer(staker, staker, amount);
        }
    }

    function leaveStaking(uint256 nftId, bool overrideNotClaimed) external walletLock(_msgSender()) {
        address staker = _msgSender();

        uint96 amount = stakeToken.leaveStaking(staker, nftId, overrideNotClaimed);
        _decreaseLockedAmount(staker, amount, true);
        stakeToken.removeStaker(staker, nftId);
    }

    function earlyWithdraw(uint256 nftId, uint96 amount) external walletLock(_msgSender()) {
        address staker = _msgSender();

        (uint32 newNftId, uint96 penaltyAmount) = stakeToken.earlyWithdraw(staker, nftId, amount);
        _decreaseLockedAmount(staker, amount, true);
        
        if (penaltyAmount > 0) {
            _tokenTransfer(staker, address(stakeToken), penaltyAmount, false);
            _distributeStakingRewards(penaltyAmount);
        }

        stakeToken.reissueStakeNft(staker, nftId, newNftId);
    }

    function withdraw(uint256 nftId, uint96 amount, bool overrideNotClaimed) external walletLock(_msgSender()) {
        address staker = _msgSender();

        (uint32 newNftId) = stakeToken.withdraw(staker, nftId, amount, overrideNotClaimed);
        if (amount > 0) {
            _decreaseLockedAmount(staker, amount, true);
        }
        if (nftId != newNftId && newNftId != 0) {
            stakeToken.reissueStakeNft(staker, nftId, newNftId);
        }
    }

    function setApprovalForAll(address fromAddress, address operator, bool approved) external {
        if (_msgSender() != address(stakeToken)) revert NotStakeContractRequesting();

        _setApprovalForAll(fromAddress, operator, approved);
    }

    function isApprovedForAll(address account, address operator) external view returns (bool) {
        if (_msgSender() != address(stakeToken)) revert NotStakeContractRequesting();

        return _isApprovedForAll(account, operator);
    }
    
    // Nft bridging
    function approveNFTAndTokens(address bridgeAddress, uint256 nftId, uint256 tokenAmount) external {
        if (!roles[Role.NftBridge][bridgeAddress]) revert NotContractAddress();

        stakeToken.approve(_msgSender(), bridgeAddress, nftId);
        _approve(_msgSender(), bridgeAddress, tokenAmount, true);
    }

    function bridgeStakeNftOut(address fromAddress, uint256 nftId) external onlyController(Role.NftBridge) {
        if (stakeToken.getApproved(nftId) != _msgSender() && !stakeToken.isApprovedForAll(_msgSender(), fromAddress)) {
            revert CallerNotApproved();
        }
        
        _walletLock(fromAddress);

        uint96 amount = stakeToken.bridgeStakeNftOut(fromAddress, nftId);
        _decreaseLockedAmount(fromAddress, amount, true);
        // Send tokens to vault
        _tokenTransfer(fromAddress, everBridgeVault, amount, false);

        stakeToken.removeStaker(fromAddress, nftId);
        emit NftBridgedOut(address(this), everBridgeVault, fromAddress, nftId, amount);
    }

    function bridgeStakeNftIn(address toAddress, uint96 depositTokens, uint8 numOfMonths, uint48 depositTime, uint96 withdrawnAmount, bool achievementClaimed) external onlyController(Role.NftBridge) returns (uint256 nftId)
    {
        nftId = stakeToken.bridgeOrAirdropStakeNftIn(toAddress, depositTokens, numOfMonths, depositTime, withdrawnAmount, 0, achievementClaimed);

        uint96 amount = depositTokens - withdrawnAmount;
        //Send the tokens from Vault
        _tokenTransfer(everBridgeVault, toAddress, amount, false);

        _lockAndAddStaker(toAddress, amount, numOfMonths, nftId);

        emit NftBridgedIn(address(this), everBridgeVault, toAddress, nftId, amount);
    }

    function _lockAndAddStaker(address toAddress, uint96 amount, uint8 numOfMonths, uint256 nftId) private {
        _increaseLockedAmount(toAddress, amount);
        stakeToken.addStaker(toAddress, nftId);

        emit StakingIncreased(toAddress, amount, numOfMonths);
    }

    // Liquidity

    function _recordPotentialLiquidityChangeTransaction(address to) private {
        uint96 balance0 = uint96(_balanceOf(to));
        (address token0, address token1) = to.pairTokens();
        if (token1 == address(this)) {
            // Switch token so token1 is always other side of pair
            token1 = token0;
        } 
        
        if (token1 == address(0)) {
            // Not LP pair, just set blocknumber to 1 to clear, to save gas on changing back
            _lastTransfer.blockNumber = 1;
            return;
        }
        
        uint96 balance1 = uint96(IERC20(token1).balanceOf(to));

        _lastTransfer = TransferDetails({
            balance0: balance0,
            to: to,
            balance1: balance1,
            origin: tx.origin,
            blockNumber: uint32(block.number)
        });
    }

    // account must be recorded in _transfer and same block
    function _validateIfLiquidityChange(address account, uint112 balance0) private view {
        if (_lastTransfer.origin != tx.origin ||
            account != _lastTransfer.to) {
            // Not same txn, or not LP addETH
            return;
        }

        // Check if LP change using the data recorded in _transfer
        // May be same transaction as _transfer
        (address token0, address token1) = account.pairTokens();
        // Not LP pair
        if (token1 == address(0)) return;
        bool switchTokens;
        if (token1 == address(this)) {
            // Switch token so token1 is always other side of pair
            token1 = token0;
            switchTokens = true;
        } else if (token0 != address(this)) {
            // Not LP for this token
            return;
        }

        uint256 balance1 = IERC20(token1).balanceOf(account);
        // Test to see if this tx is part of a liquidity add
        if (balance0 > _lastTransfer.balance0 &&
            balance1 > _lastTransfer.balance1) {
            // Both pair balances have increased, this is a Liquidty Add
            // Will block addETH and where other token address sorts higher
            revert LiquidityAddOwnerOnly();
        }
    }

    // Admin

    function upgradeComplete() external onlyOwner {
        // Can only be called before start
        if (hasTokenStarted()) revert TokenAlreadyStarted();

        // We will keep one token always in contract
        // so we don't need to track it in holder changes
        _tokenTransfer(address(this), _msgSender(), _tOwned[address(this)] - 1, false);

        _buyBackEnabled = _TRUE;
        _swapEnabled = _TRUE;
        transactionCap = _totalSupply / 1000; // Max txn 0.1% of supply

        emit TokenStarted();
    }

    function sendEthViaCall(address payable to, uint256 amount) private {
        (bool sent, ) = to.call{value: amount}("");
        if (!sent) revert FailedEthSend();
    }

    function transferBalance(uint256 amount) external onlyOwner {
        sendEthViaCall(_msgSender(), amount);
    }

    function transferExternalTokens(address tokenAddress, address to, uint256 amount) external onlyOwner {
        if (tokenAddress == address(0)) revert NotZeroAddress();

        transferTokens(tokenAddress, to, amount);
    }

    function transferTokens(address tokenAddress, address to, uint256 amount) private {
        IERC20(tokenAddress).transfer(to, amount);

        emit TransferExternalTokens(tokenAddress, to, amount);
    }

    function mirgateV2Staker(address toAddress, uint96 rewards,uint96 depositTokens, uint8 numOfMonths, uint48 depositTime, uint96 withdrawnAmount) external onlyController(Role.Upgrader) returns(uint256 nftId)
    {
        nftId = stakeToken.bridgeOrAirdropStakeNftIn(toAddress, depositTokens, numOfMonths, depositTime, withdrawnAmount, rewards, false);

        uint96 amount = depositTokens - withdrawnAmount;

        _tokenTransfer(address(this), toAddress, amount, false);
        if (rewards > 0) {
            _tokenTransfer(address(this), address(stakeToken), rewards, false);
        }
        
        _lockAndAddStaker(toAddress, amount, numOfMonths, nftId);
    }

    function mirgateV1V2Holder(address holder, uint96 amount) external onlyController(Role.Upgrader) returns(bool) {
        _tokenTransfer(address(this), holder, amount, false);
        return true;
    }
}