/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// Copyright (c) 2022 EverRise Pte Ltd. All rights reserved.
// EverRise licenses this file to you under the MIT license.
/*
 EverRise Staking NFTs are containers of Vote Escrowed (ve)EverRise 
 weighted governance tokens. veRISE generates rewards from the 
 auto-buyback with a market driven yield curve, based on the transaction
 volume of EverRise trades and veEverRise sales.

 On sales of nftEverRise Staking NFTs a 10% royalty fee is collected:

 * 6% for token auto-buyback from the market, with bought back tokens
      directly distributed as ve-staking rewards
 * 4% for Business Development (Development, Sustainability and Marketing)

                           ________                              _______   __
                          /        |                            /       \ /  |
                          $$$$$$$$/__     __  ______    ______  $$$$$$$  |$$/   _______   ______  v3.14159265
                          $$ |__  /  \   /  |/      \  /      \ $$ |__$$ |/  | /       | /      \
                          $$    | $$  \ /$$//$$$$$$  |/$$$$$$  |$$    $$< $$ |/$$$$$$$/ /$$$$$$  |
 _______ _______ _______  $$$$$/   $$  /$$/ $$    $$ |$$ |  $$/ $$$$$$$  |$$ |$$      \ $$    $$ |
|    |  |    ___|_     _| $$ |_____ $$ $$/  $$$$$$$$/ $$ |      $$ |  $$ |$$ | $$$$$$  |$$$$$$$$/
|       |    ___| |   |   $$       | $$$/   $$       |$$ |      $$ |  $$ |$$ |/     $$/ $$       |
|__|____|___|     |___|   $$$$$$$$/   $/     $$$$$$$/ $$/       $$/   $$/ $$/ $$$$$$$/   $$$$$$$/ Magnum opus

Learn more about EverRise and the EverRise Ecosystem of dApps and
how our utilities and partners can help protect your investors
and help your project grow: https://everrise.com
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

error NotZeroAddress();                    // 0x66385fa3
error CallerNotApproved();                 // 0x4014f1a5
error InvalidAddress();                    // 0xe6c4247b
error CallerNotOwner();
error WalletLocked();                      // 0xd550ed24
error DoesNotExist();                      // 0xb0ce7591
error AmountMustBeGreaterThanZero();       // 0x5e85ae73
error AmountOutOfRange();                  // 0xc64200e9
error StakeStillLocked();                  // 0x7f6699f6
error NotStakerAddress();                  // 0x2a310a0c
error AmountLargerThanAvailable();         // 0xbb296109
error StakeCanOnlyBeExtended();            // 0x73f7040a
error ArrayLengthsMismatch();              // 0x3b800a46
error NotSetup();                          // 0xb09c99c0
error NotAllowedToCreateRewards();         // 0xfdc42f29
error NotAllowedToDeliverRewards();        // 0x69a3e246
error ERC721ReceiverReject();              // 0xfa34343f
error ERC721ReceiverNotImplemented();      // 0xa89c6c0d
error NotEnoughToCoverStakeFee();          // 0x627554ed
error AmountLargerThanAllowance();         // 0x9b144c57
error AchievementNotClaimed();             // 0x3834dd9c
error AchievementAlreadyClaimed();         // 0x2d5345f4
error AmountMustBeAnInteger();             // 0x743aec61
error BrokenStatusesDiffer();              // 0x097b027d
error AchievementClaimStatusesDiffer();    // 0x6524e8b0
error UnlockedStakesMustBeSametimePeriod();// 0x42e227b0
error CannotMergeLockedAndUnlockedStakes();// 0x9efeef2c
error StakeUnlocked();                     // 0x6717a455
error NoRewardsToClaim();                  // 0x73380d99
error NotTransferrable();                  // 0x54ee5151
error Overflow();                          // 0x35278d12
error MergeNotEnabled();                   // 0x

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

// File: EverRise-v3/Abstract/ERC173-Ownable.sol

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
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function transferFromWithPermit(address sender, address recipient, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
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

    function approvals(address operator) external view returns (ApprovalChecks memory);
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
} // Total 768 bits, 40000 gwei gas

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

// File: EverRise-v3/Abstract/virtualToken.sol

abstract contract virtualToken is Ownable, IERC20, IERC20Metadata {
    InftEverRise public veEverRise;

    uint8 public constant decimals = 18;
    string public name;
    string public symbol;
  
    constructor(string memory _name, string memory _symbol ) {
        name = _name;
        symbol = _symbol;
        veEverRise = InftEverRise(owner);
    }

    function transferFrom(address sender, address recipient, uint256 amount)
        external returns (bool) {
        
        if (_msgSender() != owner) { 
            notTransferrable();
        }

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function transfer(address, uint256) pure external returns (bool) {
        notTransferrable();
    }
    function allowance(address, address) pure external returns (uint256) {
        return 0;
    }
    function approve(address, uint256) pure external returns (bool) {
        notTransferrable();
    }
    function increaseAllowance(address, uint256) pure external returns (bool) {
        notTransferrable();
    }
    function decreaseAllowance(address, uint256) pure external returns (bool) {
        notTransferrable();
    }
    function transferFromWithPermit(address, address, uint256, uint256, uint8, bytes32, bytes32) pure external returns (bool) {
        notTransferrable();
    }

    function notTransferrable() pure private {
        revert NotTransferrable();
    }
}
// File: EverRise-v3/claimRISE.sol

// Copyright (c) 2022 EverRise Pte Ltd. All rights reserved.
// EverRise licenses this file to you under the MIT license.
/*
 Virtual token that allows unclaimed rewards from EverRise Staking NFTs
 and its Vote Escrowed (ve) EverRise to display in wallet balances.
                                    ________                              _______   __
                                   /        |                            /       \ /  |
                                   $$$$$$$$/__     __  ______    ______  $$$$$$$  |$$/   _______   ______  v3.14159265
                                   $$ |__  /  \   /  |/      \  /      \ $$ |__$$ |/  | /       | /      \
      ______      _____            $$    | $$  \ /$$//$$$$$$  |/$$$$$$  |$$    $$< $$ |/$$$$$$$/ /$$$$$$  |
_________  /_____ ___(_)______ ___ $$$$$/   $$  /$$/ $$    $$ |$$ |  $$/ $$$$$$$  |$$ |$$      \ $$    $$ |
_  ___/_  /_  __ `/_  /__  __ `__ \$$ |_____ $$ $$/  $$$$$$$$/ $$ |      $$ |  $$ |$$ | $$$$$$  |$$$$$$$$/
/ /__ _  / / /_/ /_  / _  / / / / /$$       | $$$/   $$       |$$ |      $$ |  $$ |$$ |/     $$/ $$       |
\___/ /_/  \__,_/ /_/  /_/ /_/ /_/ $$$$$$$$/   $/     $$$$$$$/ $$/       $$/   $$/ $$/ $$$$$$$/   $$$$$$$/

Learn more about EverRise and the EverRise Ecosystem of dApps and
how our utilities and partners can help protect your investors
and help your project grow: https://www.everrise.com
*/

contract claimRise is virtualToken("EverRise Rewards", "claimRISE") {
    function totalSupply() override external view returns (uint256) {
        return veEverRise.totalRewardsUnclaimed();
    }

    function balanceOf(address account) override external view returns (uint256) {
        if (account == owner) return 0;
        
        return veEverRise.unclaimedRewardsBalance(account);
    }
}
// File: EverRise-v3/veRISE.sol

// Copyright (c) 2022 EverRise Pte Ltd. All rights reserved.
// EverRise licenses this file to you under the MIT license.
/*
 Virtual token that allows the Vote Escrowed (ve) EverRise weigthed
 governance tokens from EverRise Staking NFTs to display in
 wallet balances.
 
             ________                              _______   __
            /        |                            /       \ /  |
            $$$$$$$$/__     __  ______    ______  $$$$$$$  |$$/   _______   ______  v3.14159265
            $$ |__  /  \   /  |/      \  /      \ $$ |__$$ |/  | /       | /      \
            $$    | $$  \ /$$//$$$$$$  |/$$$$$$  |$$    $$< $$ |/$$$$$$$/ /$$$$$$  |
__   _____  $$$$$/   $$  /$$/ $$    $$ |$$ |  $$/ $$$$$$$  |$$ |$$      \ $$    $$ |
\ \ / / _ \ $$ |_____ $$ $$/  $$$$$$$$/ $$ |      $$ |  $$ |$$ | $$$$$$  |$$$$$$$$/
 \ V /  __/ $$       | $$$/   $$       |$$ |      $$ |  $$ |$$ |/     $$/ $$       |
  \_/ \___| $$$$$$$$/   $/     $$$$$$$/ $$/       $$/   $$/ $$/ $$$$$$$/   $$$$$$$/

Learn more about EverRise and the EverRise Ecosystem of dApps and
how our utilities and partners can help protect your investors
and help your project grow: https://www.everrise.com
*/

contract veRise is virtualToken("Vote-escrowed EverRise", "veRISE") {
    function totalSupply() override external view returns (uint256) {
        return veEverRise.totalAmountVoteEscrowed();
    }

    function balanceOf(address account) override external view returns (uint256) {
        if (account == owner) return 0;

        return veEverRise.voteEscrowedBalance(account);
    }
}

// File: EverRise-v3/Interfaces/IEverRoyaltySplitter.sol

interface IEverRoyaltySplitter {
    event RoyaltiesSplit(uint256 value);
    event SplitUpdated(uint256 previous, uint256 current);
    event UniswapV2RouterSet(address indexed previous, address indexed current);
    event EverRiseEcosystemSet(address indexed previous, address indexed current);
    event EverRiseTokenSet(address indexed previous, address indexed current);
    event StableCoinSet(address indexed previous, address indexed current);

    function distribute() external;
}

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external view returns(bytes4);
}

interface IERC721Metadata /* is ERC721 */ {
    function name() external view returns (string memory _name);
    function symbol() external view returns (string memory _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

interface IERC721Enumerable /* is ERC721 */ {
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 _index) external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

// File: EverRise-v3/Interfaces/IEverRiseRenderer.sol

interface IOpenSeaCollectible {
    function contractURI() external view returns (string memory);
}

interface IEverRiseRenderer is IOpenSeaCollectible {
    event SetEverRiseNftStakes(address indexed addressStakes);
    event SetEverRiseRendererGlyph(address indexed addressGlyphs);
    
    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function everRiseNftStakes() external view returns (InftEverRise);
    function setEverRiseNftStakes(address contractAddress) external;
}

// File: EverRise-v3/Interfaces/IERC165-SupportsInterface.sol

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
// File: EverRise-v3/Abstract/ERC165-SupportsInterface.sol

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: EverRise-v3/Interfaces/IERC2981-Royalty.sol

interface IERC2981 is IERC165 {
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (
        address receiver,
        uint256 royaltyAmount
    );
}

// File: EverRise-v3/nftEverRise.sol

// Copyright (c) 2022 EverRise Pte Ltd. All rights reserved.
// EverRise licenses this file to you under the MIT license.
/*
 EverRise Staking NFTs are Vote Escrowed (ve) EverRise weigthed governance tokens
 which generate rewards with a market driven yield curve, based of the
 transaction volume of EverRise trades and veEverRise sales.

 On sales of veEverRise Staking NFTs a 10% royalty fee is collected
 * 6% for token Buyback from the market, 
     with bought back tokens directly distributed as ve-staking rewards
 * 4% for Business Development (Development, Sustainability and Marketing)

                           ________                              _______   __
                          /        |                            /       \ /  |
                          $$$$$$$$/__     __  ______    ______  $$$$$$$  |$$/   _______   ______  v3.14159265
                          $$ |__  /  \   /  |/      \  /      \ $$ |__$$ |/  | /       | /      \
                          $$    | $$  \ /$$//$$$$$$  |/$$$$$$  |$$    $$< $$ |/$$$$$$$/ /$$$$$$  |
 _______ _______ _______  $$$$$/   $$  /$$/ $$    $$ |$$ |  $$/ $$$$$$$  |$$ |$$      \ $$    $$ |
|    |  |    ___|_     _| $$ |_____ $$ $$/  $$$$$$$$/ $$ |      $$ |  $$ |$$ | $$$$$$  |$$$$$$$$/
|       |    ___| |   |   $$       | $$$/   $$       |$$ |      $$ |  $$ |$$ |/     $$/ $$       |
|__|____|___|     |___|   $$$$$$$$/   $/     $$$$$$$/ $$/       $$/   $$/ $$/ $$$$$$$/   $$$$$$$/

Learn more about EverRise and the EverRise Ecosystem of dApps and
how our utilities and partners can help protect your investors
and help your project grow: https://www.everrise.com
*/

contract EverRiseTokenOwned is Ownable {
    IEverRise public everRiseToken;

    event EverRiseTokenSet(address indexed tokenAddress);
    
    function _onlyEverRiseToken(address senderAddress) private view {
        if (address(everRiseToken) == address(0)) revert NotSetup();
        if (address(everRiseToken) != senderAddress) revert CallerNotApproved();
    }

    modifier onlyEverRiseToken() {
        _onlyEverRiseToken(_msgSender());
        _;
    }
}

struct IndividualAllowance {
    address operator;
    uint48 timestamp;
    uint32 nftCheck;
}

abstract contract nftEverRiseConfigurable is EverRiseTokenOwned, InftEverRise, ERC165, IERC2981, IERC721Metadata, IOpenSeaCollectible {
    event AddRewardCreator(address indexed _address);
    event RemoveRewardCreator(address indexed _address);
    event SetAchievementNfts(address indexed _address);
    event RoyaltyFeeUpdated(uint256 newValue);
    event RoyaltyAddressUpdated(address indexed contractAddress);
    event RendererAddressUpdated(address indexed contractAddress);
    event StakeCreateCostUpdated(uint256 newValue);
    event StakingParametersSet(uint256 withdrawPct, uint256 firstHalfPenality, uint256 secondHalfPenality, uint256 maxStakeMonths, bool mergeEnabled);
 
    IEverRiseRenderer public renderer;
    IEverRoyaltySplitter public royaltySplitter;
    uint256 public nftRoyaltySplit = 10;
    address public currentAchievementNfts;
    uint8 public maxEarlyWithdrawalPercent = 60;
    uint8 public firstHalfPenality = 25;
    uint8 public secondHalfPenality = 10;
    uint8 public maxStakeMonths = 36;
    uint256 public stakeCreateCost = 1 * 10**18 / (10**2);
    uint256 public mergeEnabled = _FALSE;

    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.
    uint256 constant _FALSE = 1;
    uint256 constant _TRUE = 2;

    mapping (address => bool) internal _canCreateRewards;

    function setEverRiseToken(address tokenAddress) external onlyOwner {
        if (tokenAddress == address(0)) revert NotZeroAddress();

        _removeAddressToCreate(address(everRiseToken));
        addAddressToCreate(tokenAddress);

        everRiseToken = IEverRise(tokenAddress);

        emit EverRiseTokenSet(tokenAddress);
    }

    function setStakeCreateCost(uint256 _stakeCreateCost, uint256 numOfDecimals)
        external onlyOwner
    {
        // Catch typos, if decimals are pre-added
        if (_stakeCreateCost > 1_000) revert AmountOutOfRange();

        stakeCreateCost = _stakeCreateCost * (10**18) / (10**numOfDecimals);
        emit StakeCreateCostUpdated(_stakeCreateCost);
    }
    
    function setAchievementNfts(address contractAddress) external onlyOwner() {
        if (contractAddress == address(0)) revert NotZeroAddress();

        currentAchievementNfts = contractAddress;

        emit SetAchievementNfts(contractAddress);
    }

    function addAddressToCreate(address account) public onlyOwner {
        if (account == address(0)) revert NotZeroAddress();

        _canCreateRewards[account] = true;
        emit AddRewardCreator(account);
    }

    function removeAddressToCreate(address account) external onlyOwner {
        if (account == address(0)) revert NotZeroAddress();

        _removeAddressToCreate(account);
    }

    function _removeAddressToCreate(address account) private {
        if (account != address(0)){
            _canCreateRewards[account] = false;
            emit RemoveRewardCreator(account);
        }
    }
    
    function setNftRoyaltyFeePercent(uint256 royaltySplitRate) external onlyOwner {
        if (royaltySplitRate > 10) revert AmountOutOfRange();
        nftRoyaltySplit = royaltySplitRate;

        emit RoyaltyFeeUpdated(royaltySplitRate);
    }

    function setRoyaltyAddress(address newAddress) external onlyOwner {
        if (newAddress == address(0)) revert NotZeroAddress();

        royaltySplitter = IEverRoyaltySplitter(newAddress);
        emit RoyaltyAddressUpdated(newAddress);
    }

    function setRendererAddress(address newAddress) external onlyOwner {
        if (newAddress == address(0)) revert NotZeroAddress();

        renderer = IEverRiseRenderer(newAddress);
        emit RendererAddressUpdated(newAddress);
    }

    function setStakingParameters(uint8 _withdrawPercent, uint8 _firstHalfPenality, uint8 _secondHalfPenality, uint8 _maxStakeMonths, bool _mergEnabled)
        external onlyOwner
    {
        if (_maxStakeMonths == 0 || _maxStakeMonths > 120) {
            revert AmountOutOfRange();
        }

        maxEarlyWithdrawalPercent = _withdrawPercent;
        firstHalfPenality = _firstHalfPenality;
        secondHalfPenality = _secondHalfPenality;
        maxStakeMonths = _maxStakeMonths;
        mergeEnabled = _mergEnabled ? _TRUE : _FALSE;

        emit StakingParametersSet(_withdrawPercent, _firstHalfPenality, _secondHalfPenality, _maxStakeMonths, _mergEnabled);
    }
}

contract nftEverRise is nftEverRiseConfigurable {
    string public constant name = "EverRise NFT Stakes";
    string public constant symbol = "nftRISE";

    uint256 public constant month = 30 days;

    uint256 private constant MAX = ~uint256(0);
    uint8 public constant decimals = 0;
    uint256 private constant totalStakeTokensSupply = 120_000_000 * 10**6 * 10**18;
    uint8 constant _FALSE8 = 1;
    uint8 constant _TRUE8 = 2;
    
    event RewardsWithdrawn(address indexed from, uint256 amount);
    event ExcludedFromRewards(address indexed _address);
    event IncludedToRewards(address indexed _address);

    mapping (address => bool) private _isExcludedFromReward;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => uint256) private _withdrawnRewards;
    mapping (uint256 => IndividualAllowance) private _individualApproval;

    address[] private _excludedList;

    uint256 private _rTotal = (MAX - (MAX % totalStakeTokensSupply));

    StakingDetails[] private _allStakeDetails;
    mapping (address => uint256[]) private _individualStakes;
    mapping (uint256 => uint256) private _stakeById;
    uint256[] private _freeStakes;
    mapping (address => uint256) public voteEscrowedBalance;
    uint256 public totalAmountEscrowed;
    uint256 public totalAmountVoteEscrowed;
    uint256 public totalRewardsDistributed;
    
    uint32 private nextNftId = 1;
    veRise public immutable veRiseToken;
    claimRise public immutable claimRiseToken;

    constructor() {
        veRiseToken = new veRise();
        claimRiseToken = new claimRise();

        _rOwned[address(this)] = _rTotal;
        
        excludeFromReward(address(this));

        _allStakeDetails.push(StakingDetails({
            initialTokenAmount: 0,
            withdrawnAmount: 0,
            depositTime: 0,
            numOfMonths: 1,
            achievementClaimed: 0,
            stakerAddress: address(0),
            nftId: 0,
            lookupIndex: 0,
            stakerIndex: 0,
            isActive: _FALSE8
        }));
    }
 
    function _walletLock(address fromAddress) private view {
        if (everRiseToken.isWalletLocked(fromAddress)) revert WalletLocked();
    }

    modifier walletLock(address fromAddress) {
        _walletLock(fromAddress);
        _;
    }

    function totalSupply() external view returns (uint256) {
        return _allStakeDetails.length - _freeStakes.length - 1;
    }

    function _onlyRewardCreator(address senderAddress) private view {
        if (!_canCreateRewards[senderAddress]) revert CallerNotApproved();
    }

    modifier onlyRewardCreator() {
        _onlyRewardCreator(_msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC165, IERC165) returns (bool) {
        return 
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function contractURI() external view returns (string memory) {
        return renderer.contractURI();
    }

    function tokenURI(uint256 nftId) external view returns (string memory) {
        return renderer.tokenURI(nftId);
    }
    
    function createRewards(uint256 amount) external onlyRewardCreator() {
        address sender = _msgSender();
        if (_isExcludedFromReward[sender]) revert NotAllowedToDeliverRewards();
        
        _transferFromExcluded(address(this), sender, amount);

        totalRewardsDistributed += amount;
        
        uint256 rAmount = amount * _getRate();
        _rOwned[sender] -= rAmount;
        _rTotal -= rAmount;

        claimRiseToken.transferFrom(address(0), address(this), amount);
    }

    function voteEscrowedAndRewards(address account) private view returns (uint256) {
        if (account == address(0)) revert NotZeroAddress();

        if (_isExcludedFromReward[account]) return _tOwned[account];
        return tokenFromRewards(_rOwned[account]);
    }

    function totalRewardsUnclaimed() external view returns (uint256) {
        return everRiseToken.balanceOf(address(this));
    }

    function isExcludedFromReward(address account) external view returns (bool) {
        if (account == address(0)) revert NotZeroAddress();

        return _isExcludedFromReward[account];
    }
    
    function rewardsFromToken(uint256 tAmount) external view returns(uint256) {
        if (tAmount > totalStakeTokensSupply) revert AmountOutOfRange();

        return tAmount * _getRate();
    }

    function tokenFromRewards(uint256 rAmount) public view returns(uint256) {
        if (rAmount > _rTotal) revert AmountOutOfRange();

        uint256 currentRate =  _getRate();
        return rAmount / currentRate;
    }
    
    function excludeFromReward(address account) public onlyOwner() {
        if (account == address(0)) revert NotZeroAddress();
        if (_isExcludedFromReward[account]) revert InvalidAddress();

        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromRewards(_rOwned[account]);
        }
        _isExcludedFromReward[account] = true;
        _excludedList.push(account);

        emit ExcludedFromRewards(account);
    }

    function includeInReward(address account) external onlyOwner() {
        if (account == address(0)) revert NotZeroAddress();
        if (!_isExcludedFromReward[account]) revert InvalidAddress();
          
        uint256 length = _excludedList.length;
        for (uint256 i = 0; i < length;) {
            if (_excludedList[i] == account) {
                _excludedList[i] = _excludedList[_excludedList.length - 1];
                _tOwned[account] = 0;
                _isExcludedFromReward[account] = false;
                _excludedList.pop();
                break;
            }
            unchecked {
                ++i;
            }
        }

        emit IncludedToRewards(account);
    }
    
    function _transfer(
        address sender,
        address recipient,
        uint256 amount,
        bool emitEvent
    ) private {
        if (sender == address(0)) revert NotZeroAddress();
        if (recipient == address(0)) revert NotZeroAddress();
        if (amount == 0) revert AmountMustBeGreaterThanZero();
        // One of the addresses has to be this contract
        if (sender != address(this) && recipient != address(this)) revert InvalidAddress();

        if (_isExcludedFromReward[sender]) {
            if (!_isExcludedFromReward[recipient]) {
                _transferFromExcluded(sender, recipient, amount);
            } else {
                _transferBothExcluded(sender, recipient, amount);
            }
        } else if (_isExcludedFromReward[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (emitEvent) {
            if (sender == address(this)) {
                veRiseToken.transferFrom(address(0), recipient, amount);
            }
            else if (recipient == address(this)) {
                veRiseToken.transferFrom(sender, address(0), amount);
            }
        }
    }
    
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        uint256 rAmount = tAmount * _getRate();
        _rOwned[sender] -= rAmount;
        _rOwned[recipient] += rAmount;
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 rAmount = tAmount * _getRate();
	    _rOwned[sender] -= rAmount;
        _tOwned[recipient] += tAmount;
        _rOwned[recipient] += rAmount;           
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 rAmount = tAmount * _getRate();
    	_tOwned[sender] -= tAmount;
        _rOwned[sender] -= rAmount;
        _rOwned[recipient] += rAmount;   
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 rAmount = tAmount * _getRate();
    	_tOwned[sender] -= tAmount;
        _rOwned[sender] -= rAmount;
        _tOwned[recipient] += tAmount;
        _rOwned[recipient] += rAmount;        
    }
    
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = totalStakeTokensSupply;      
        uint256 length = _excludedList.length;

        for (uint256 i = 0; i < length;) {
            if (_rOwned[_excludedList[i]] > rSupply || _tOwned[_excludedList[i]] > tSupply) {
                return (_rTotal, totalStakeTokensSupply);
            }
            rSupply -= _rOwned[_excludedList[i]];
            tSupply -= _tOwned[_excludedList[i]];
            
            unchecked {
                ++i;
            }
        }
        if (rSupply < (_rTotal / totalStakeTokensSupply)) return (_rTotal, totalStakeTokensSupply);
        return (rSupply, tSupply);
    }

    function getStakeIndex(uint256 nftId) private view returns (uint256 lookupIndex) {
        if (nftId == 0) revert DoesNotExist();
        lookupIndex = _stakeById[nftId];
        if (lookupIndex >= _allStakeDetails.length) revert DoesNotExist();
        if (_allStakeDetails[lookupIndex].isActive != _TRUE8) revert DoesNotExist();
    }

    function ownerOf(uint256 nftId) public view returns (address) {
        uint256 lookupIndex = getStakeIndex(nftId);
        StakingDetails storage stakeDetails = _allStakeDetails[lookupIndex];
        
        return stakeDetails.stakerAddress;
    }

    function _getStake(uint256 nftId, address staker) private view returns (uint256 lookupIndex, StakingDetails storage stakeDetails) {
        lookupIndex = getStakeIndex(nftId);
        stakeDetails = _allStakeDetails[lookupIndex];

        if (stakeDetails.stakerAddress != staker) revert NotStakerAddress();

        assert(nftId == stakeDetails.nftId);
    }

    function getStake(uint256 nftId, address staker) external view returns (StakingDetails memory stakeDetails) {
        (, stakeDetails) = _getStake(nftId, staker);
    }

    function getNftData(uint256 nftId) external view returns (StakingDetails memory) {
        uint256 lookupIndex = getStakeIndex(nftId);
        return _allStakeDetails[lookupIndex];
    }

    function balanceOf(address account) external view returns (uint256) {
        return _individualStakes[account].length;
    }
    
    function unclaimedRewardsBalance(address account) public view returns (uint256) {
        return voteEscrowedAndRewards(account) - voteEscrowedBalance[account];
    }

    function getTotalRewards(address account) external view returns (uint256) {
        return unclaimedRewardsBalance(account) + _withdrawnRewards[account];
    }
    
    function tokenOfOwnerByIndex(address _owner, uint256 index) external view returns (uint32) {
        uint256[] storage stakes = _individualStakes[_owner];
        if (index > stakes.length) revert AmountOutOfRange();
        uint256 lookupIndex = stakes[index];
        return _allStakeDetails[lookupIndex].nftId;
    }
    
    function enterStaking(address staker, uint96 amount, uint8 numOfMonths)
        external onlyEverRiseToken returns (uint32 nftId) {
        // Stake time period must be in valid range
        if (numOfMonths == 0 || 
            numOfMonths > maxStakeMonths || 
            (numOfMonths > 12 && (numOfMonths % 12) > 0)
        ) {
            revert AmountOutOfRange();
        }

        roundingCheck(amount, false);

        nftId = _createStake(staker, amount, 0, numOfMonths, uint48(block.timestamp), false);
     }
 
    // Rewards withdrawal doesn't need token lock check as is adding to locked wallet not removing
    function withdrawRewards() external {
        address staker = _msgSender();
        uint256 rewards = unclaimedRewardsBalance(staker);

        if (rewards == 0) revert NoRewardsToClaim();

        // Something to withdraw
        _withdrawnRewards[staker] += rewards;
        // Remove the veTokens for the rewards
        _transfer(staker, address(this), rewards, false);
        // Emit transfer
        claimRiseToken.transferFrom(staker, address(0), rewards);
        // Send RISE rewards
        require(everRiseToken.transfer(staker, rewards));

        emit RewardsWithdrawn(staker, rewards);
    }

    function checkNotLocked(uint256 depositTime, uint256 numOfMonths) private view {
        if (depositTime + (numOfMonths * month) > block.timestamp) {
            revert StakeStillLocked();
        }
    }

    function leaveStaking(address staker, uint256 nftId, bool overrideNotClaimed) external onlyEverRiseToken returns (uint96 amount) {
        (uint256 lookupIndex, StakingDetails storage stakeDetails) = _getStake(nftId, staker);

        checkNotLocked(stakeDetails.depositTime, stakeDetails.numOfMonths);

        if (!overrideNotClaimed && stakeDetails.achievementClaimed != _TRUE8) {
            revert AchievementNotClaimed();
        }
        
        amount = _removeStake(staker, nftId, lookupIndex, stakeDetails);
    }

    function withdraw(address staker, uint256 nftId, uint96 amount, bool overrideNotClaimed) external onlyEverRiseToken returns (uint32 newNftId) {
        (uint256 lookupIndex, StakingDetails storage stakeDetails) = _getStake(nftId, staker);

        checkNotLocked(stakeDetails.depositTime, stakeDetails.numOfMonths);

        if (!overrideNotClaimed && stakeDetails.achievementClaimed != _TRUE8) {
            revert AchievementNotClaimed();
        }

        uint96 remaining = stakeDetails.initialTokenAmount - stakeDetails.withdrawnAmount;
        if (amount > remaining) revert AmountLargerThanAvailable();
        roundingCheck(amount, true);

        bool reissueNft = false;
        if (amount > 0) {
            decreaseVeAmount(staker, amount, stakeDetails.numOfMonths, true);
            // Out of period, inital now becomes remaining
            remaining -= amount;
            reissueNft = true;
        }
        if (stakeDetails.initialTokenAmount != remaining) {
            // Out of period, zero out the withdrawal amount
            stakeDetails.initialTokenAmount = remaining;
            stakeDetails.withdrawnAmount = 0;
            reissueNft = true;
        }

        if (reissueNft) {
            if (remaining == 0) {
                _burnStake(staker, nftId, lookupIndex, stakeDetails);
                newNftId = 0;
            } else {
                newNftId = _reissueStakeNftId(nftId, lookupIndex);
                stakeDetails.nftId = newNftId;
            }
        } else {
            // Nothing changed, keep the same nft
            newNftId = uint32(nftId);
        }
    }

    function claimAchievement(address staker, uint256 nftId) external returns (uint32 newNftId) {
        if (_msgSender() != currentAchievementNfts) revert CallerNotApproved();

        (uint256 lookupIndex, StakingDetails storage stakeDetails) = _getStake(nftId, staker);

        checkNotLocked(stakeDetails.depositTime, stakeDetails.numOfMonths);

        // Can only claim once
        if (stakeDetails.achievementClaimed == _TRUE8) {
            revert AchievementAlreadyClaimed();
        }

        // Reset broken status if unlocked
        if (stakeDetails.withdrawnAmount > 0) {
            stakeDetails.initialTokenAmount -= stakeDetails.withdrawnAmount;
            stakeDetails.withdrawnAmount = 0;
        }

        // Mark claimed
        stakeDetails.achievementClaimed = _TRUE8;
        // Get new id
        newNftId = _reissueStakeNftId(nftId, lookupIndex);
        // Set new id
        stakeDetails.nftId = newNftId;
        // Emit burn and mint events
        _reissueStakeNft(staker, nftId, newNftId);
    }

    function getTime() external view returns (uint256) {
        // Used to workout UI time drift from blockchain
        return block.timestamp;
    }

    function checkLocked(uint48 depositTime, uint8 numOfMonths) private view {
        if (depositTime + (numOfMonths * month) < block.timestamp) {
            revert StakeUnlocked();
        }
    }

    function earlyWithdraw(address staker, uint256 nftId, uint96 amount) external onlyEverRiseToken returns (uint32 newNftId, uint96 penaltyAmount) {
        (uint256 lookupIndex, StakingDetails storage stakeDetails) = _getStake(nftId, staker);
        
        checkLocked(stakeDetails.depositTime, stakeDetails.numOfMonths);

        uint256 remaingEarlyWithdrawal = (stakeDetails.initialTokenAmount * maxEarlyWithdrawalPercent) / 100 - stakeDetails.withdrawnAmount;

        if (amount > remaingEarlyWithdrawal) {
            revert AmountLargerThanAvailable();
        }

        roundingCheck(amount, false);

        decreaseVeAmount(staker, amount, stakeDetails.numOfMonths, true);
        
        penaltyAmount = calculateTax(amount, stakeDetails.depositTime, stakeDetails.numOfMonths); // calculate early penalty tax

        stakeDetails.withdrawnAmount += uint96(amount); // update the withdrawl amount

        newNftId = _reissueStakeNftId(nftId, lookupIndex);
        stakeDetails.nftId = newNftId;
    }

    function increaseStake(address staker, uint256 nftId, uint96 amount)
        external onlyEverRiseToken returns (uint32 newNftId, uint96 original, uint8 numOfMonths)
    {
        (uint256 lookupIndex, StakingDetails storage stakeDetails) = _getStake(nftId, staker);

        checkLocked(stakeDetails.depositTime, stakeDetails.numOfMonths);

        roundingCheck(amount, false);
        numOfMonths = stakeDetails.numOfMonths;

        increaseVeAmount(staker, amount, numOfMonths, true);
        // Get current amount for main contract change event
        original = stakeDetails.initialTokenAmount - stakeDetails.withdrawnAmount;
        // Take amount off the withdrawnAmount, "repairing" the stake
        if (amount > stakeDetails.withdrawnAmount) {
            // Take withdrawn off amount
            amount -= stakeDetails.withdrawnAmount;
            // Clear withdrawn
            stakeDetails.withdrawnAmount = 0;
            // Add remaining to initial
            stakeDetails.initialTokenAmount += amount;
        } else {
            // Just reduce amount withdrawn
            stakeDetails.withdrawnAmount -= amount;
        }

        // Relock
        stakeDetails.depositTime = uint48(block.timestamp);

        newNftId =  _reissueStakeNftId(nftId, lookupIndex);
        stakeDetails.nftId = newNftId;
        _reissueStakeNft(staker, nftId, newNftId);
    }
    
    function extendStake(uint256 nftId, uint8 numOfMonths) external walletLock(_msgSender()) returns (uint32 newNftId) {
        address staker = _msgSender();
        (uint256 lookupIndex, StakingDetails storage stakeDetails) = _getStake(nftId, staker);
        
        checkLocked(stakeDetails.depositTime, stakeDetails.numOfMonths);

        if (stakeDetails.numOfMonths >= numOfMonths) revert StakeCanOnlyBeExtended();

        // Stake time period must be in valid range
        if (numOfMonths > maxStakeMonths || 
            (numOfMonths > 12 && (numOfMonths % 12) > 0)
        ) {
            revert AmountOutOfRange();
        }

        uint8 extraMonths = numOfMonths - stakeDetails.numOfMonths;
        uint96 amount = (stakeDetails.initialTokenAmount - stakeDetails.withdrawnAmount);
        
        increaseVeAmount(staker, amount, extraMonths, true);
        
        stakeDetails.numOfMonths = numOfMonths;
        // Relock
        stakeDetails.depositTime = uint48(block.timestamp);

        newNftId =  _reissueStakeNftId(nftId, lookupIndex);
        stakeDetails.nftId = newNftId;
        _reissueStakeNft(staker, nftId, newNftId);
    }

    function toUint96(uint256 value) internal pure returns (uint96) {
        if (value > type(uint96).max) revert Overflow();
        return uint96(value);
    }

    function splitStake(uint256 nftId, uint96 amount) external payable walletLock(_msgSender()) returns (uint32 newNftId0, uint32 newNftId1) {
        address staker = _msgSender();
        
        if (msg.value < stakeCreateCost) revert NotEnoughToCoverStakeFee();
        roundingCheck(amount, false);

        // Transfer everything, easier than transferring extras later
        payable(address(everRiseToken)).transfer(address(this).balance);

        (uint256 lookupIndex, StakingDetails storage stakeDetails) = _getStake(nftId, staker);

        uint256 remainingAmount = stakeDetails.initialTokenAmount - stakeDetails.withdrawnAmount;

        if (amount >= remainingAmount) revert AmountLargerThanAvailable();
  
        newNftId0 = _reissueStakeNftId(nftId, lookupIndex);
        // Update the existing stake
        uint96 transferredWithdrawnAmount = toUint96(stakeDetails.withdrawnAmount * uint256(amount) / stakeDetails.initialTokenAmount);

        stakeDetails.initialTokenAmount -= amount;
        stakeDetails.withdrawnAmount -= transferredWithdrawnAmount;
        stakeDetails.nftId = newNftId0;

        // Create new stake
        newNftId1 = _addSplitStake(
            staker, 
            amount, // initialTokenAmount
            transferredWithdrawnAmount, // withdrawnAmount
            stakeDetails.depositTime,        // depositTime
            stakeDetails.numOfMonths,
            stakeDetails.achievementClaimed == _TRUE8 // achievementClaimed
        );

        _reissueStakeNft(staker, nftId, newNftId0);
        emit Transfer(address(0), staker, newNftId1);
    }

    function roundingCheck(uint96 amount, bool allowZero) private pure {
        // Round to nearest unit
        uint96 roundedAmount = amount - (amount % uint96(10**18));

        if (amount != roundedAmount || (!allowZero && amount == 0)) revert AmountMustBeAnInteger();
    }

    function mergeStakes(uint256 nftId0, uint256 nftId1, bool overrideStatuses)
        external walletLock(_msgSender())
        returns (uint32 newNftId)
    {
        if (mergeEnabled != _TRUE) revert MergeNotEnabled();
        
        address staker = _msgSender();
        (uint256 lookupIndex0, StakingDetails storage stakeDetails0) = _getStake(nftId0, staker);
        (uint256 lookupIndex1, StakingDetails storage stakeDetails1) = _getStake(nftId1, staker);

        bool unlocked0 = stakeDetails0.depositTime + (stakeDetails0.numOfMonths * month) < block.timestamp;
        bool unlocked1 = stakeDetails1.depositTime + (stakeDetails1.numOfMonths * month) < block.timestamp;

        if (unlocked0 == unlocked1) {
            if (stakeDetails0.numOfMonths != stakeDetails1.numOfMonths) {
                revert UnlockedStakesMustBeSametimePeriod();
            }
            if (!overrideStatuses && stakeDetails0.achievementClaimed != stakeDetails1.achievementClaimed) {
                revert AchievementClaimStatusesDiffer();
            }
            
            // Reset broken status if unlocked
            if (stakeDetails0.withdrawnAmount > 0) {
                stakeDetails0.initialTokenAmount -= stakeDetails0.withdrawnAmount;
                stakeDetails0.withdrawnAmount = 0;
            }
            if (stakeDetails1.withdrawnAmount > 0) {
                stakeDetails1.initialTokenAmount -= stakeDetails1.withdrawnAmount;
                stakeDetails1.withdrawnAmount = 0;
            }
        } else if (unlocked0 != unlocked1) {
            revert CannotMergeLockedAndUnlockedStakes();
        } else {
            // Both locked
            if (!overrideStatuses && (stakeDetails0.withdrawnAmount > 0) != (stakeDetails1.withdrawnAmount > 0)) {
                revert BrokenStatusesDiffer();
            }
        }

        uint8 numOfMonths0 = stakeDetails0.numOfMonths;
        if (!unlocked0) {
            uint8 extraMonths = 0;
            uint96 amount = 0;
            // Must both be locked
            uint8 numOfMonths1 = stakeDetails1.numOfMonths;
            if (numOfMonths0 > numOfMonths1) {
                extraMonths = numOfMonths0 - numOfMonths1;
                amount = (stakeDetails1.initialTokenAmount - stakeDetails1.withdrawnAmount);
            } else if (numOfMonths0 < numOfMonths1) {
                extraMonths = numOfMonths1 - numOfMonths0;
                amount = (stakeDetails0.initialTokenAmount - stakeDetails0.withdrawnAmount);
                numOfMonths0 = numOfMonths1;
            }

            if (extraMonths > 0 && amount > 0) {
                // Give new tokens for time period
                increaseVeAmount(staker, amount, extraMonths, true);
            }
        }

        stakeDetails0.initialTokenAmount += stakeDetails1.initialTokenAmount;
        stakeDetails0.withdrawnAmount += stakeDetails1.withdrawnAmount;
        if (unlocked0) {
            // For unlocked, use higher of two deposit times
            // Can't "age" and nft by merging an older one in
            stakeDetails0.depositTime = stakeDetails0.depositTime > stakeDetails1.depositTime ?
                stakeDetails0.depositTime : stakeDetails1.depositTime;
        } else {
            // Re-lock starting now
            stakeDetails0.depositTime = uint48(block.timestamp);
        }

        stakeDetails0.numOfMonths = numOfMonths0;
        if (stakeDetails1.achievementClaimed == _TRUE8) {
            stakeDetails0.achievementClaimed = _TRUE8;
        }
        
        // Drop the second stake
        stakeDetails1.isActive = _FALSE8;
        uint24 stakerIndex = stakeDetails1.stakerIndex;
        _removeIndividualStake(staker, stakerIndex);
        // Clear the lookup for second
        _stakeById[nftId1] = 0;
        // Add to available data items
        _freeStakes.push(lookupIndex1);
        // Burn the second stake completely
        emit Transfer(staker, address(0), nftId1);

        // Renumber first stake
        newNftId = _reissueStakeNftId(nftId0, lookupIndex0);
        stakeDetails0.nftId = newNftId;
        _reissueStakeNft(staker, nftId0, newNftId);
    }

    function _addSplitStake(
        address staker, 
        uint96 initialTokenAmount,
        uint96 withdrawnAmount,
        uint48 depositTime,
        uint8 numOfMonths,
        bool achievementClaimed
    ) private returns (uint32 nftId) {
        uint256[] storage stakes = _individualStakes[staker];
        // Create new stake
        StakingDetails storage splitStakeDetails = _createStakeDetails(
            initialTokenAmount, // initialTokenAmount
            withdrawnAmount, // withdrawnAmount
            depositTime,        // depositTime
            numOfMonths,
            achievementClaimed, // achievementClaimed
            staker,
            uint24(stakes.length) // New staker's stake index
        );

        // Add new stake to individual's list
        stakes.push(splitStakeDetails.lookupIndex); 
        nftId = splitStakeDetails.nftId;
    }

    function bridgeStakeNftOut(address fromAddress, uint256 nftId) 
        external onlyEverRiseToken returns (uint96 amount)
    {
        (uint256 lookupIndex, StakingDetails storage stakeDetails) = _getStake(nftId, fromAddress);

        return _removeStake(fromAddress, nftId, lookupIndex, stakeDetails);
    }

    function bridgeOrAirdropStakeNftIn(address toAddress, uint96 depositAmount, uint8 numOfMonths, uint48 depositTime, uint96 withdrawnAmount, uint96 rewards, bool achievementClaimed) 
        external onlyEverRiseToken returns (uint32 nftId) {
            
        nftId = _createStake(toAddress, depositAmount, withdrawnAmount, numOfMonths, depositTime, achievementClaimed);
        if (rewards > 0) {
            _transfer(address(this), toAddress, rewards, false);
            // Emit event
            claimRiseToken.transferFrom(address(0), toAddress, rewards);
        }
    }

    function _createStakeDetails(
        uint96 initialTokenAmount,
        uint96 withdrawnAmount,
        uint48 depositTime,
        uint8 numOfMonths,
        bool achievementClaimed,
        address stakerAddress,
        uint24 stakerIndex
    ) private returns (StakingDetails storage stakeDetails) {
        uint256 index = _freeStakes.length;
        if (index > 0) {
            // Is an existing allocated StakingDetails
            // that we can reuse for cheaper gas
            index = _freeStakes[index - 1];
            _freeStakes.pop();
            stakeDetails = _allStakeDetails[index];
        } else {
            // None free, allocate a new StakingDetails
            index = _allStakeDetails.length;
            stakeDetails = _allStakeDetails.push();
        }

        // Set stake details
        stakeDetails.initialTokenAmount = initialTokenAmount;
        stakeDetails.withdrawnAmount = withdrawnAmount;
        stakeDetails.depositTime = depositTime;
        stakeDetails.numOfMonths = numOfMonths;
        stakeDetails.achievementClaimed = achievementClaimed ? _TRUE8 : _FALSE8;

        stakeDetails.stakerAddress = stakerAddress;
        stakeDetails.nftId = nextNftId;
        stakeDetails.lookupIndex = uint32(index);
        stakeDetails.stakerIndex = stakerIndex;
        stakeDetails.isActive = _TRUE8;

        // Set lookup
        _stakeById[nextNftId] = index;
        // Increase the next nft id
        ++nextNftId;
    }

    function _transferStake(address fromAddress, address toAddress, uint256 nftId) 
        private
    {
        (uint256 lookupIndex, StakingDetails storage stakeDetails) = _getStake(nftId, fromAddress);
        require(stakeDetails.withdrawnAmount == 0, "Broken, non-transferable");

        stakeDetails.stakerAddress = toAddress;
        // Full initial as withdrawn must be zero (above)
        uint96 amountToTransfer = stakeDetails.initialTokenAmount;

        uint8 numOfMonths = stakeDetails.numOfMonths;
        // Remove veTokens from sender (don't emit ve transfer event)
        decreaseVeAmount(fromAddress, amountToTransfer, numOfMonths, false);
        // Give veTokens to receiver (don't emit ve transfer event)
        increaseVeAmount(toAddress, amountToTransfer, numOfMonths, false);
        // Emit the ve transfer event
        veRiseToken.transferFrom(fromAddress, toAddress, amountToTransfer * numOfMonths);

        // Remove from previous owners list
        _removeIndividualStake(fromAddress, stakeDetails.stakerIndex);
        // Add to new owners list
        stakeDetails.stakerIndex = uint24(_individualStakes[toAddress].length);
        _individualStakes[toAddress].push(lookupIndex);

        everRiseToken.transferStake(fromAddress, toAddress, amountToTransfer);
    }

    function _removeIndividualStake(address staker, uint24 stakerIndex) private {
        uint256[] storage stakes = _individualStakes[staker];

        uint24 stakerLength = uint24(stakes.length);

        if (stakerLength >= stakerIndex + 1) {
            // Not last item, overwrite with last item from account stakes
            uint256 lastStakeIndex = stakes[stakerLength - 1];
            _allStakeDetails[lastStakeIndex].stakerIndex = stakerIndex;
            stakes[stakerIndex] = lastStakeIndex;
        }
        // Remove last item
        stakes.pop();
    }

    function _reissueStakeNftId(uint256 nftId, uint256 stakeIndex) private returns (uint32 newNftId) {
        // Burn the Stake NFT id
        _stakeById[nftId] = 0;
        // Reissue new Stake NFT id
        newNftId = nextNftId;
        _stakeById[newNftId] = stakeIndex;
        // Increase the next nft id
        ++nextNftId;
    }

    function increaseVeAmount(address staker, uint96 amount, uint8 numOfMonths, bool emitEvent) private {
        // Transfer vote escrowed tokens from contract to staker
        uint256 veTokens = amount * numOfMonths;
        totalAmountEscrowed += amount;
        totalAmountVoteEscrowed += veTokens;
        voteEscrowedBalance[staker] += veTokens; // increase the ve tokens amount
        _transfer(address(this), staker, veTokens, emitEvent);
    }

    function decreaseVeAmount(address staker, uint96 amount, uint8 numOfMonths, bool emitEvent) private {
        // Transfer vote escrowed tokens back to the contract
        uint256 veTokens = amount * numOfMonths;
        totalAmountEscrowed -= amount;
        totalAmountVoteEscrowed -= veTokens;
        voteEscrowedBalance[staker] -= veTokens; // decrease the ve tokens amount
        _transfer(staker, address(this), veTokens, emitEvent);
    }

    function _removeStake(address staker, uint256 nftId, uint256 lookupIndex, StakingDetails storage stakeDetails) private returns (uint96 amount) {        
        uint96 remainingAmount = stakeDetails.initialTokenAmount - stakeDetails.withdrawnAmount;

        decreaseVeAmount(staker, remainingAmount, stakeDetails.numOfMonths, true);

        _burnStake(staker, nftId, lookupIndex, stakeDetails);

        return remainingAmount;
    }

    function _burnStake(address staker, uint256 nftId, uint256 lookupIndex, StakingDetails storage stakeDetails) private {        
        stakeDetails.isActive = _FALSE8;

        uint24 stakerIndex = stakeDetails.stakerIndex;
        _removeIndividualStake(staker, stakerIndex);

        // Clear the lookup
        _stakeById[nftId] = 0;
        // Add to available data items
        _freeStakes.push(lookupIndex);
    }

    function _createStake(address staker, uint96 depositAmount, uint96 withdrawnAmount, uint8 numOfMonths, uint48 depositTime, bool achievementClaimed)
        private returns (uint32 nftId)
    {
        if (withdrawnAmount >= depositAmount) revert AmountOutOfRange();
        uint256[] storage stakes = _individualStakes[staker];

        // Create new stake
        StakingDetails storage stakeDetails = _createStakeDetails(
            depositAmount,   // initialTokenAmount
            withdrawnAmount, // withdrawnAmount
            depositTime,     // depositTime
            numOfMonths,
            achievementClaimed,           // achievementClaimed
            staker,
            uint24(stakes.length)   // New staker's stake index
        );

        // Add new stake to individual's list
        stakes.push(stakeDetails.lookupIndex);  
        
        uint96 remaining = depositAmount - withdrawnAmount;
        increaseVeAmount(staker, remaining, numOfMonths, true);

        // Mint new Stake NFT to staker
        nftId = stakeDetails.nftId;
    }

    function calculateTax(uint96 amount, uint256 depositTime, uint256 numOfMonths) public view returns (uint96) {
        return calculateTaxAt(amount, depositTime, numOfMonths, block.timestamp);
    }

    function calculateTaxAt(uint96 amount, uint256 depositTime, uint256 numOfMonths, uint256 timestamp) public view returns (uint96) {
        uint256 lockTime = depositTime + (numOfMonths * month);
        uint96 taxAmount = 0;

        if (timestamp < depositTime + (numOfMonths * month / 2)) {
            taxAmount = (amount * firstHalfPenality) / 100;
        } else if (timestamp < lockTime) {
            taxAmount = (amount * secondHalfPenality) / 100;
        }

        return taxAmount;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        if (_tokenId == 0) revert AmountMustBeGreaterThanZero();

        return (address(royaltySplitter), _salePrice / nftRoyaltySplit);
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
    function setApprovalForAll(address operator, bool approved) external {
        if (address(everRiseToken) == address(0)) revert NotSetup();

        address _owner = _msgSender();
        everRiseToken.setApprovalForAll(_owner, operator, approved);

        emit ApprovalForAll(_owner, operator, approved);
    }

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) public view returns (bool) {
        return everRiseToken.isApprovedForAll(account, operator);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external payable walletLock(_msgSender()) {
        address operator = _msgSender();
        _transferFrom(operator, from, to, tokenId);
        _doSafeERC721TransferAcceptanceCheck(operator, from, to, tokenId, data);
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId) external payable walletLock(_msgSender()) {
        address operator = _msgSender();
        _transferFrom(operator, from, to, tokenId);
        _doSafeERC721TransferAcceptanceCheck(operator, from, to, tokenId, new bytes(0));
    }

    function transferFrom(address from, address to, uint256 tokenId)
        external payable walletLock(_msgSender()) {
        address operator = _msgSender();
        _transferFrom(operator, from, to, tokenId);
    }
    
   function approve(address account, address _operator, uint256 nftId)
        external onlyEverRiseToken {
        _approve(account, _operator, nftId);
    }

    function approve(address _operator, uint256 nftId) external payable {
        _approve(_msgSender(), _operator, nftId);
    }

    function _approve(address account, address _operator, uint256 nftId) private {
        if (ownerOf(nftId) != account) revert NotStakerAddress();

        ApprovalChecks memory approvals = everRiseToken.approvals(account);

        _individualApproval[nftId] = IndividualAllowance({
            operator: _operator, 
            timestamp: approvals.autoRevokeNftHours == 0 ? 
                type(uint48).max : // Don't timeout approval
                uint48(block.timestamp) + approvals.autoRevokeNftHours * 1 hours, // Timeout after user chosen period,
            nftCheck: approvals.nftCheck
        });
    }

    function getApproved(uint256 nftId) external view returns (address) {
        getStakeIndex(nftId); // Reverts on not exist
        
        IndividualAllowance storage _allowance = _individualApproval[nftId];
        ApprovalChecks memory approvals = everRiseToken.approvals(ownerOf(nftId));

        if (block.timestamp > _allowance.timestamp ||
            approvals.nftCheck != _allowance.nftCheck)
        {
            return address(0);
        }

        return _allowance.operator;
    }

    function _isAddressApproved(address operator, uint256 nftId) private view returns (bool) {
        IndividualAllowance storage _allowance = _individualApproval[nftId];
        ApprovalChecks memory approvals = everRiseToken.approvals(ownerOf(nftId));

        if (_allowance.operator != operator ||
            block.timestamp > _allowance.timestamp ||
            approvals.nftCheck != _allowance.nftCheck)
        {
            return false;
        }

        return true;
    }

    function _transferFrom(
        address operator,
        address from,
        address to,
        uint256 nftId
    ) private {
        if (address(everRiseToken) == address(0)) revert NotSetup();
        if (from == address(0)) revert NotZeroAddress();
        if (to == address(0)) revert NotZeroAddress();
        if (operator != from && 
            !isApprovedForAll(from, operator) &&
            !_isAddressApproved(from, nftId)
        ) revert AmountLargerThanAllowance();

        // Clear any individual approvals
        delete _individualApproval[nftId];
        _transferStake(from, to, nftId);

        // Signal transfer complete
        emit Transfer(from, to, nftId);
    }

    function addStaker(address staker, uint256 nftId)
        external onlyEverRiseToken 
    {
        // Send event for new staking
        emit Transfer(address(0), staker, nftId);
    }

    function _doSafeERC721TransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) private view {
        if (isContract(to)) {
            try IERC721TokenReceiver(to).onERC721Received(operator, from, id, data) returns (bytes4 response) {
                if (response != IERC721TokenReceiver.onERC721Received.selector) {
                    revert ERC721ReceiverReject();
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert ERC721ReceiverNotImplemented();
            }
        }
    }

    function isContract(address account) private view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    function removeStaker(address staker, uint256 nftId)
        external onlyEverRiseToken 
    {
        // Send event for left staking
        emit Transfer(staker, address(0), nftId);
    }

    function reissueStakeNft(address staker, uint256 oldNftId, uint256 newNftId)
        external onlyEverRiseToken 
    {
        _reissueStakeNft(staker, oldNftId, newNftId);
    }

    function _reissueStakeNft(address staker, uint256 oldNftId, uint256 newNftId)
        private
    {
        // Burn old Stake NFT
        emit Transfer(staker, address(0), oldNftId);
        // Reissue new Stake NFT
        emit Transfer(address(0), staker, newNftId);
    }

    // Admin for trapped tokens

    function transferExternalTokens(address tokenAddress, address toAddress) external onlyOwner {
        if (tokenAddress == address(0)) revert NotZeroAddress();
        if (toAddress == address(0)) revert NotZeroAddress();
        if (IERC20(tokenAddress).balanceOf(address(this)) == 0) revert AmountLargerThanAvailable();

        require(IERC20(tokenAddress).transfer(toAddress, IERC20(tokenAddress).balanceOf(address(this))));
    }

    function transferToAddressETH(address payable receipient) external onlyOwner {
        if (receipient == address(0)) revert NotZeroAddress();

        receipient.transfer(address(this).balance);
    }
}