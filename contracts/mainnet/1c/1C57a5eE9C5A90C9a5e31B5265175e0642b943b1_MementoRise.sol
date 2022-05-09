/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

// Copyright (c) 2022 EverRise Pte Ltd. All rights reserved.
// EverRise licenses this file to you under the MIT license.
/*
 EverRise Memento NFTs are awards for completing EverRise staking terms,
 participating in events and winning challenges.

  ___________      ________                              _______   __
 '._==_==_=_.'    /        |                            /       \ /  |
 .-\:      /-.   $$$$$$$$/__     __  ______    ______  $$$$$$$  |$$/   _______   ______  v3.14159265
| (|:.     |) |  $$ |__  /  \   /  |/      \  /      \ $$ |__$$ |/  | /       | /      \
 '-|:.     |-'   $$    | $$  \ /$$//$$$$$$  |/$$$$$$  |$$    $$< $$ |/$$$$$$$/ /$$$$$$  |
   \::.    /     $$$$$/   $$  /$$/ $$    $$ |$$ |  $$/ $$$$$$$  |$$ |$$      \ $$    $$ |
    '::. .'      $$ |_____ $$ $$/  $$$$$$$$/ $$ |      $$ |  $$ |$$ | $$$$$$  |$$$$$$$$/
      ) (        $$       | $$$/   $$       |$$ |      $$ |  $$ |$$ |/     $$/ $$       |
    _.' '._      $$$$$$$$/   $/     $$$$$$$/ $$/       $$/   $$/ $$/ $$$$$$$/   $$$$$$$/ Magnum opus
   `"""""""`     

Learn more about EverRise and the EverRise Ecosystem of dApps and
how our utilities and partners can help protect your investors
and help your project grow: https://everrise.com
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

error NotSetup();                          // 0xb09c99c0
error WalletLocked();                      // 0xd550ed24
error FailedEthSend();                     // 0xb5747cc7
error NotZeroAddress();                    // 0x66385fa3
error CallerNotApproved();                 // 0x4014f1a5
error InvalidAddress();                    // 0xe6c4247b
error CallerNotOwner();                    // 0x5cd83192
error AmountMustBeGreaterThanZero();       // 0x5e85ae73
error AmountOutOfRange();                  // 0xc64200e9

address constant EverMigrateAddress = 0x429CA183C5f4B43F09D70580C5365a6D21ccCd47;
address constant EverRiseV1Address_BSC = 0xC7D43F2B51F44f09fBB8a691a0451E8FFCF36c0a;
address constant EverRiseV1Address_ETH = 0x8A2D988Fe2E8c6716cbCeF1B33Df626C692F7B98;
address constant EverRiseV2Address = 0x0cD022ddE27169b20895e0e2B2B8A33B25e63579;
address constant EverRiseV2Address_AVAX = 0xC3A8d300333BFfE3ddF6166F2Bc84E6d38351BED;
address constant EverRiseV3Address = 0xC17c30e98541188614dF99239cABD40280810cA3;
address constant nftRiseV3Address = 0x23cD2E6b283754Fd2340a75732f9DdBb5d11807e;

// Testnet
// address constant EverRiseV3Address = 0x1665E2b184F352d226A882281f69ccf361349CC6;
//address constant nftRiseV3Address = 0x0D3770c2318F84E33d0B0efEc8EfD2086683F0b2;
//address constant EverRiseV3Address = 0x639631Ac62abE60c4F67278f80ca3291047eFc1B;
// address constant nftRiseV3Address = 0x617cBE19e7A74dF4fb58eFE5830586c3466CC091;

address constant mintFeeAddress = 0xc3b7FfA7611C45C1245a1923065442BC94Af9757;
address constant royaltyFeeAddress = 0x0BFc8f6374028f1a61Ae3019E5C845F461575381;
bytes constant ipfsAddress = "ipfs://bafybeidj6gy62qkgwi6ww32iw2khbjcusf3xefvi2gugykdfau54mvux54/metaOutput/";

interface ICreateRecipe {
    function createTo(address account, uint256 toTokenId, uint256 toAmount) external;
}

// File: memeRISE/ITransmuteRecipe.sol

interface ITransmuteSingleRecipe {
    function transmuteSingleTo(
        address account,
        uint256 toToken,
        uint256 toAmount,
        uint256[] calldata fromIds,
        uint256[] calldata fromAmounts)
    external;
}

interface ITransmuteMultipleRecipe {
    function transmuteMultipleTo(
        address account,
        uint256[] calldata toTokenIds,
        uint256[] calldata toAmounts,
        uint256[] calldata fromIds,
        uint256[] calldata fromAmounts)
    external;
}

// File: memeRISE/Abstract/nativeCoinSender.sol

contract NativeCoinSender {
    function sendEthViaCall(address payable to, uint256 amount) internal {
        (bool sent, ) = to.call{value: amount}("");
        if (!sent) revert FailedEthSend();
    }
}

// File: memeRISE/Interfaces/IEverRoyaltySplitter.sol

interface IEverRoyaltySplitter {
    event RoyaltiesSplit(uint256 value);
    event SplitUpdated(uint256 previous, uint256 current);
    event UniswapV2RouterSet(address indexed previous, address indexed current);
    event EverRiseEcosystemSet(address indexed previous, address indexed current);
    event EverRiseTokenSet(address indexed previous, address indexed current);
    event StableCoinSet(address indexed previous, address indexed current);

    function distribute() external;
}

// File: memeRISE/Interfaces/IERC173-Ownable.sol

interface IOwnable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function owner() external view returns (address);
    function transferOwnership(address newOwner) external;
}

// File: memeRISE/Abstract/Context.sol

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

// File: memeRISE/Abstract/ERC173-Ownable.sol

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

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner == address(0)) revert NotZeroAddress();

        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// File: memeRISE/Interfaces/IERC20-Token.sol

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

// File: memeRISE/Interfaces/IEverRise.sol

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

// File: memeRISE/Interfaces/IERC165-SupportsInterface.sol

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: memeRISE/Abstract/ERC165-SupportsInterface.sol

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: memeRISE/Interfaces/IERC2981-Royalty.sol

interface IERC2981 is IERC165 {
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (
        address receiver,
        uint256 royaltyAmount
    );
}

// File: memeRISE/Abstract/royaltyHandler.sol

abstract contract royaltyHandler is IERC2981, Ownable {
    event RoyaltyFeeUpdated(uint256 newValue);
    event RoyaltyAddressUpdated(address indexed contractAddress);

    IEverRoyaltySplitter public royaltySplitter;
    uint256 public defaultRoyaltySplit = 5;

    function setDefaultNftRoyaltyFeePercent(uint256 royaltySplitRate) external onlyOwner {
        if (royaltySplitRate > 10) revert AmountOutOfRange();
        defaultRoyaltySplit = royaltySplitRate;

        emit RoyaltyFeeUpdated(royaltySplitRate);
    }

    function setRoyaltyAddress(address newAddress) external onlyOwner {
        if (newAddress == address(0)) revert NotZeroAddress();

        _setRoyaltyAddress(newAddress);
    }

    function _setRoyaltyAddress(address newAddress) internal {
        royaltySplitter = IEverRoyaltySplitter(newAddress);
        emit RoyaltyAddressUpdated(newAddress);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        if (_tokenId == 0) revert AmountMustBeGreaterThanZero();

        return (address(royaltySplitter), _salePrice / defaultRoyaltySplit);
    }
}

// File: memeRISE/Interfaces/IMementoRise.sol

interface IMementoRise {
    function royaltyAddress() external view returns(address payable);
    function mint(address to, uint256 tokenId, uint256 amount) external;
    function mintFee(uint16 typeId) external returns (uint256);
}

// File: memeRISE/mementoRecipe.sol

abstract contract MementoRecipe is NativeCoinSender, Ownable {
    IMementoRise public mementoRise;
    IEverRise public everRiseToken = IEverRise(EverRiseV3Address);

    event EverRiseTokenSet(address indexed tokenAddress);
    event MementoRiseSet(address indexed nftAddress);
    
    modifier onlyMementoRise() {
        require(_msgSender() == address(mementoRise), "Invalid requestor");
        _;
    }

    constructor(address _mementoRise) {
        setMementoRise(_mementoRise);
    }

    function setEverRiseToken(address tokenAddress) external onlyOwner {
        if (tokenAddress == address(0)) revert NotZeroAddress();
        
        everRiseToken = IEverRise(tokenAddress);

        emit EverRiseTokenSet(tokenAddress);
    }

    function setMementoRise(address nftAddress) public onlyOwner {
        if (nftAddress == address(0)) revert NotZeroAddress();

        mementoRise = IMementoRise(nftAddress);

        emit MementoRiseSet(nftAddress);
    }

    function krakenMintFee(uint256 baseFee, uint256 quantity) internal {
        distributeMintFee(payable(address(everRiseToken)), baseFee, quantity);
    }

    function handleMintFee(uint256 baseFee, uint256 quantity) internal {
        distributeMintFee(mementoRise.royaltyAddress(), baseFee, quantity);
    }

    function distributeMintFee(address payable receiver, uint256 baseFee, uint256 quantity) private {
        uint256 _mintFee = baseFee * quantity;
        require(_mintFee == 0 || msg.value >= _mintFee, "Mint fee not covered");

        uint256 _balance = address(this).balance;
        if (_balance > 0) {
            // Transfer everything, easier than transferring extras later
            sendEthViaCall(receiver, _balance);
        }
    }
}

// File: memeRISE/Interfaces/IERC1155-MultiToken.sol

interface IERC1155 is IERC165 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

interface IERC1155Receiver is IERC165 {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external view returns (bytes4);
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external view returns (bytes4);
}

interface IERC1155MetadataURI {
    function uri(uint256 id) external view returns (string memory);
}

// File: memeRISE/mementoRise.sol

// Copyright (c) 2022 EverRise Pte Ltd. All rights reserved.
// EverRise licenses this file to you under the MIT license.
/*
 EverRise Memento NFTs are awards for completing EverRise staking terms,
 participating in events and winning challenges.

  ___________      ________                              _______   __
 '._==_==_=_.'    /        |                            /       \ /  |
 .-\:      /-.   $$$$$$$$/__     __  ______    ______  $$$$$$$  |$$/   _______   ______  v3.14159265
| (|:.     |) |  $$ |__  /  \   /  |/      \  /      \ $$ |__$$ |/  | /       | /      \
 '-|:.     |-'   $$    | $$  \ /$$//$$$$$$  |/$$$$$$  |$$    $$< $$ |/$$$$$$$/ /$$$$$$  |
   \::.    /     $$$$$/   $$  /$$/ $$    $$ |$$ |  $$/ $$$$$$$  |$$ |$$      \ $$    $$ |
    '::. .'      $$ |_____ $$ $$/  $$$$$$$$/ $$ |      $$ |  $$ |$$ | $$$$$$  |$$$$$$$$/
      ) (        $$       | $$$/   $$       |$$ |      $$ |  $$ |$$ |/     $$/ $$       |
    _.' '._      $$$$$$$$/   $/     $$$$$$$/ $$/       $$/   $$/ $$/ $$$$$$$/   $$$$$$$/ Magnum opus
   `"""""""`     

Learn more about EverRise and the EverRise Ecosystem of dApps and
how our utilities and partners can help protect your investors
and help your project grow: https://everrise.com
*/

interface IOpenSeaCollectible {
    function contractURI() external view returns (string memory);
}

abstract contract EverRiseTokenManaged is Ownable {
    IEverRise public everRiseToken;

    function setEverRiseToken(address tokenAddress) public onlyOwner {
        if (tokenAddress == address(0)) revert NotZeroAddress();

        everRiseToken = IEverRise(tokenAddress);

        emit EverRiseTokenSet(tokenAddress);
    }

    event EverRiseTokenSet(address indexed tokenAddress);
}

interface IEverMigrate {
    function userTransaction(address sourceToken, address userAddress, uint256 position) external view returns (uint256, uint256, uint32);
}

enum Animal
{
    Plankton, 
    Seahorse, 
    Starfish, 
    Swordfish, 
    Stingray, 
    Dolphin, 
    Narwhal, 
    Shark, 
    Orca, 
    Whale, 
    Megalodon, 
    Kraken
}

contract MigrationV1V2Achievement is MementoRecipe {
    mapping (uint256 => bool) public processedTxn;
    mapping (address => uint16) public claimedReward;

    IEverMigrate public migrate = IEverMigrate(EverMigrateAddress);
    address immutable public everRiseV1;

    constructor(address _mementoRise) MementoRecipe(_mementoRise) {
        everRiseV1 = block.chainid == 1 ? 
            EverRiseV1Address_ETH :
            EverRiseV1Address_BSC;
    }

    function claimMigrationAchievement(uint256 tokenId, uint256 txnPosition)
        external payable
    {
        address from = _msgSender();
        (uint256 amount,, uint256 txnId) = migrate.userTransaction(everRiseV1, from, txnPosition);

        require(txnId > 0, "Invalid txn");
        require(!processedTxn[txnId], "Already claimed txn");
        processedTxn[txnId] = true;

        handleMintFee(mementoRise.mintFee(uint16(tokenId & 0xffff)), 1);

        Animal animal = Animal(tokenId >> 16);
        require(amount > getMinAmount(animal), "Not enough");

        uint16 flag = uint16(1 << uint8(animal));
        uint16 flags = claimedReward[from];

        require(flags & flag == 0, "Already claimed level");
        claimedReward[from] = flags | flag;

        mementoRise.mint(from, tokenId, 1);
    }

    function getMinAmount(Animal animal) private pure returns (uint256) {
        // 'Plankton', threshold: 1000 }
        if (animal == Animal.Plankton) {
            return (1_000 - 1) * 10**4 * 10**9;
        }
        // 'Seahorse', threshold: 10000 },
        if (animal == Animal.Seahorse) {
            return (10_000 - 1) * 10**4 * 10**9;
        }
        // 'Starfish', threshold: 50000 },
        if (animal == Animal.Starfish) {
            return (50_000 - 1) * 10**4 * 10**9;
        }
        // 'SwordFish', threshold: 100000 },
        if (animal == Animal.Swordfish) {
            return (100_000 - 1) * 10**4 * 10**9;
        }
        // 'Stingray', threshold: 500000 },
        if (animal == Animal.Stingray) {
            return (500_000 - 1) * 10**4 * 10**9;
        }
        // 'Dolphin', threshold: 1000000 },
        if (animal == Animal.Dolphin) {
            return (1_000_000 - 1) * 10**4 * 10**9;
        }
        // 'Narwhal', threshold: 5000000 },
        if (animal == Animal.Narwhal) {
            return (5_000_000 - 1) * 10**4 * 10**9;
        }
        // 'Shark', threshold: 10000000 },
        if (animal == Animal.Shark) {
            return (10_000_000 - 1) * 10**4 * 10**9;
        }
        // 'Orca', threshold: 25000000 },
        if (animal == Animal.Orca) {
            return (25_000_000 - 1) * 10**4 * 10**9;
        }
        // 'Whale', threshold: 50000000 },
        if (animal == Animal.Whale) {
            return (50_000_000 - 1) * 10**4 * 10**9;
        }
        // 'Megalodon', threshold: 100000000 },
        if (animal == Animal.Megalodon) {
            return (100_000_000 - 1) * 10**4 * 10**9;
        }
        // 'Kraken' threshold: 250000000
        if (animal == Animal.Kraken) {
            return (250_000_000 - 1) * 10**4 * 10**9;
        }

        require(false, "Unknown level");
        return (250_000_000_000 - 1) * 10**4 * 10**9;
    }
}

contract HolderV2Achievement is MementoRecipe, ICreateRecipe {
    IERC20 immutable public everRiseV2;
    mapping (address => bool) public processedClaim;

    constructor(address _mementoRise) MementoRecipe(_mementoRise) {
        everRiseV2 = block.chainid == 43114 ? 
            IERC20(EverRiseV2Address_AVAX) :
            IERC20(EverRiseV2Address);
    }

    function createTo(address account, uint256 toTokenId, uint256 toAmount)
        external onlyMementoRise
    {
        require(toTokenId == 3, "Nft doesn't exist");
        require(toAmount == 1, "Can only claim one per chain");

        require(everRiseV2.balanceOf(account) > 0, "Not holding RISE v2");
        require(!processedClaim[account], "Already claimed");

        processedClaim[account] = true;
    }
}

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

interface InftEverRise {
    function getNftData(uint256 id) external view returns (StakingDetails memory);
    function claimAchievement(address staker, uint256 nftId) external returns (uint32 newNftId);
}

contract StakingAchievement is MementoRecipe {
    InftEverRise public nftRise;

    constructor(address _mementoRise) MementoRecipe(_mementoRise) {
        nftRise = InftEverRise(nftRiseV3Address);
    }

    function _walletLock(address fromAddress) private view {
        if (everRiseToken.isWalletLocked(fromAddress)) revert WalletLocked();
    }

    modifier walletLock(address fromAddress) {
        _walletLock(fromAddress);
        _;
    }

    function getTokenId(uint256 chainId, uint256 animalId, uint256 months) public pure returns (uint256) {
        require(chainId <= type(uint8).max, "Chain out of range");
        require(animalId <= type(uint8).max, "AnimalId out of range");
        require(months <= type(uint8).max, "Months out of range");

        uint256 generatedTokenId = 1;

        generatedTokenId += chainId << 16;
        generatedTokenId += animalId << 24;
        generatedTokenId += months << 32;

        return generatedTokenId;
    }

    function claimStakingAchievement(uint256 tokenId, uint256 stakeNftId) external payable walletLock(_msgSender()) {
        address from = _msgSender();

        krakenMintFee(mementoRise.mintFee(uint16(tokenId & 0xffff)), 1);
        uint32 newNftId = nftRise.claimAchievement(from, stakeNftId);

        StakingDetails memory stakeDetails = nftRise.getNftData(newNftId);

        uint256 generatedTokenId = 1;

        generatedTokenId += getChain() << 16;
        generatedTokenId += getAnimal(stakeDetails.initialTokenAmount) << 24;
        generatedTokenId += getMaterial(stakeDetails.numOfMonths) << 32;

        require(generatedTokenId == tokenId, "Incorrect nft requested");

        mementoRise.mint(from, tokenId, 1);
    }

    function getMaterial(uint256 months) private pure returns (uint256) {
        if (months > 0 && months <= 12) return months;
        if (months == 24) return 14;
        if (months == 36) return 15;

        require(false, "Invalid time");
        return 0;
    }
    
    function getAnimal(uint256 threshold) private pure returns (uint256) {
      // 'Kraken' threshold: 250000000
      if (threshold > (250_000_000 - 1) * 10**18) {
          return 11;
      }
      // 'Megalodon', threshold: 100000000 },
      if (threshold > (100_000_000 - 1) * 10**18) {
          return 10;
      }
      // 'Whale', threshold: 50000000 },
      if (threshold > (50_000_000 - 1) * 10**18) {
           return 9;
      }
      // 'Orca', threshold: 25000000 },
      if (threshold > (25_000_000 - 1) * 10**18) {
          return 8;
      }
      // 'Shark', threshold: 10000000 },
      if (threshold > (10_000_000 - 1) * 10**18) {
          return 7;
      }
      // 'Narwhal', threshold: 5000000 },
      if (threshold > (5_000_000 - 1) * 10**18) {
          return 6;
      }
      // 'Dolphin', threshold: 1000000 },
      if (threshold > (1_000_000 - 1) * 10**18) {
          return 5;
      }
      // 'Stingray', threshold: 500000 },
      if (threshold > (500_000 - 1) * 10**18) {
          return 4;
      }
      // 'Swordfish', threshold: 100000 },
      if (threshold > (100_000 - 1) * 10**18) {
          return 3;
      }
      // 'Starfish', threshold: 50000 },
      if (threshold > (50_000 - 1) * 10**18) {
          return 2;
      }
      // 'Seahorse', threshold: 10000 },
      if (threshold > (10_000 - 1) * 10**18) {
          return 1;
      }
      // 'Plankton', threshold: 1000 }
      if (threshold > (1_000 - 1) * 10**18) {
          return 0;
      }
      // Smaller
      require(false, "Too small");
      return 0;
    }

    function getChain() private view returns (uint256) {
        uint256 chainId = block.chainid;
        if (chainId == 1 || chainId == 3 || chainId == 4 || chainId == 5 || chainId == 42) // Ethereum 
            return 4;
        if (chainId == 56 || chainId == 97) // BNB
            return 2;
        if (chainId == 137 || chainId == 80001) // Polygon
            return 3;
        if (chainId == 250 || chainId == 4002) // Fantom 
            return 1;
        if (chainId == 43114 || chainId == 43113) // Avalanche
            return 0;

      require(false, "Unknown chain");
      return 0;
    }
}

type BalanceKey is uint256;
type BalanceAmount is uint256;

library AmountLib {
    function add(BalanceAmount b, uint256 value) internal pure returns (BalanceAmount) {
        require(value < type(uint240).max, "Out of range");

        uint256 amountPos = BalanceAmount.unwrap(b);
        uint240 amount = uint240(amountPos >> 16);
        uint16 position = uint16(amountPos & 0xffff);

        amount += uint240(value);
        amountPos = (uint256(amount) << 16) | position;

        return BalanceAmount.wrap(amountPos);
    }

    function subtract(BalanceAmount b, uint256 value) internal pure returns (BalanceAmount) {
        require(value < type(uint240).max, "Out of range");

        uint256 amountPos = BalanceAmount.unwrap(b);
        uint240 amount = uint240(amountPos >> 16);
        uint16 position = uint16(amountPos & 0xffff);

        require (amount >= value, "Balance too low");

        unchecked {
            amount -= uint240(value);
        }
        amountPos = (uint256(amount) << 16) | position;

        return BalanceAmount.wrap(amountPos);
    }

    function Amount(BalanceAmount b) internal pure returns (uint256 value) {
        uint256 amountPos = BalanceAmount.unwrap(b);
        return uint240(amountPos >> 16);
    }
    
    function getPosition(BalanceAmount b) internal pure returns (uint16) {
        uint256 amountPos = BalanceAmount.unwrap(b);
        return uint16(amountPos & 0xffff);
    }

    function setPosition(BalanceAmount b, uint16 position) internal pure returns (BalanceAmount) {
        uint256 amountPos = BalanceAmount.unwrap(b);
        uint240 amount = uint240(amountPos >> 16);

        return BalanceAmount.wrap((uint256(amount) << 16) | position);
    }
}

contract MementoRise is EverRiseTokenManaged, royaltyHandler, NativeCoinSender, ERC165, IERC1155, IMementoRise, IERC1155MetadataURI, IOpenSeaCollectible {
    using AmountLib for BalanceAmount; 

    event BaseUriForTypeSet(uint16 indexed nftType, string uri);
    event NftBridgeSet(address bridge);
    event NftBridgedIn(address indexed contractAddress, address indexed operator, address indexed to, uint256 id, uint256 amount);
    event NftsBridgedIn(address indexed contractAddress, address indexed operator, address indexed to, uint256[] ids, uint256[] amounts);
    event NftBridgedOut(address indexed contractAddress, address indexed operator, address indexed from, uint256 id, uint256 amount);
    event NftsBridgedOut(address indexed contractAddress, address indexed operator, address indexed from, uint256[] ids, uint256[] amounts);
    
    event TransferExternalTokens(address indexed tokenAddress, address indexed to, uint256 count);
    event SetMintFee(uint16 typeId, uint256 fee);
    event SetTransmuteFee(uint16 typeId, uint256 fee);
    event SetMintFeeDefault(uint256 fee);
    event SetTransmuteFeeDefault(uint256 fee);

    event SetAllowedCreateTo(uint16 nftType, address contractAddress);
    event SetAllowedCreateFrom(uint16 nftType, address contractAddress);
    event SetAllowedTransumtateSingleTo(uint16 nftType, address contractAddress);
    event SetAllowedTransumtateMultipleTo(uint16 nftType, address contractAddress);

    address public nftBridge;
    uint256 public defaultCreateFee;
    uint256 public defaultTransmuteFee;

    mapping (uint16 => uint256) private _mintFee;
    mapping (uint16 => uint256) private _transmuteFee;

    mapping (uint16 => ICreateRecipe) public allowedCreateTo;
    mapping (uint16 => ITransmuteSingleRecipe) public allowedTransumtateSingleTo;
    mapping (uint16 => ITransmuteMultipleRecipe) public allowedTransumtateMultipleTo;
    mapping (uint16 => address) public allowedCreateFrom;
    mapping (uint16 => bytes) public baseUris;

    mapping (BalanceKey => BalanceAmount) private _balanceOf;
    mapping (address => uint96[]) public tokensHeld;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    StakingAchievement public stakingAchievement;
    MigrationV1V2Achievement public migrationV1V2Achievement;
    HolderV2Achievement public holderV2Achievement;

    constructor(address _owner) {
        _setRoyaltyAddress(royaltyFeeAddress);
        
        StakingAchievement _stakingAchievement = new StakingAchievement(address(this));
        MigrationV1V2Achievement _migrationV1V2Achievement = new MigrationV1V2Achievement(address(this));
        HolderV2Achievement _holderV2Achievement = new HolderV2Achievement(address(this));

        stakingAchievement = _stakingAchievement;
        migrationV1V2Achievement = _migrationV1V2Achievement;
        holderV2Achievement = _holderV2Achievement;

        allowedCreateFrom[1] = address(_stakingAchievement);
        allowedCreateFrom[2] = address(_migrationV1V2Achievement);
        allowedCreateTo[3] = _holderV2Achievement;
        uint256 _defaultCreateFee = getDefaultCreateFee();
        defaultCreateFee = _defaultCreateFee;
        uint256 _defaultTransmuteFee = _defaultCreateFee * 5 / 2; // x2.5
        defaultTransmuteFee = _defaultTransmuteFee;

        emit SetMintFeeDefault(_defaultCreateFee);
        emit SetTransmuteFeeDefault(_defaultTransmuteFee);

        setEverRiseToken(EverRiseV3Address);
        transferOwnership(_owner);
        _stakingAchievement.transferOwnership(_owner);
        _migrationV1V2Achievement.transferOwnership(_owner);
        _holderV2Achievement.transferOwnership(_owner);

        bytes memory _uri = ipfsAddress;
        baseUris[1] = _uri;
        baseUris[2] = _uri;
        baseUris[3] = _uri;

        emit TransferSingle(address(this), address(0), address(0), 4295098369, 0);
        emit TransferSingle(address(this), address(0), address(0), 2, 0);
        emit TransferSingle(address(this), address(0), address(0), 3, 0);
    }

    function name() external pure returns (string memory) {
        return "EverRise Mementos";
    }

    function symbol() external pure returns (string memory) {
        return "memeRISE";
    }

    function decimals() external pure returns (uint8) {
        return 0;
    }

    uint256 public totalSupply;

    function setMintFee(uint16 typeId, uint256 fee) external onlyOwner {
        _mintFee[typeId] = fee;

        emit SetMintFee(typeId, fee);
    }

    function setTransmuteFee(uint16 typeId, uint256 fee) external onlyOwner {
        _transmuteFee[typeId] = fee;

        emit SetTransmuteFee(typeId, fee);
    }

    function setMintFeeDefault(uint256 fee) external onlyOwner {
        defaultCreateFee = fee;

        emit SetMintFeeDefault(fee);
    }

    function setTransmuteFeeDefault(uint256 fee) external onlyOwner {
        defaultTransmuteFee = fee;

        emit SetTransmuteFeeDefault(fee);
    }

    function mintFee(uint16 typeId) public view returns (uint256) {
        uint256 fee = _mintFee[typeId];

        if (fee == 0) return defaultCreateFee;

        return fee;
    }

    function transmuteFee(uint16 typeId) public view returns (uint256) {
        uint256 fee = _transmuteFee[typeId];

        if (fee == 0) return defaultTransmuteFee;

        return fee;
    }

    function getDefaultCreateFee() private view returns (uint256) {
        uint256 chainId = block.chainid;
        if (chainId == 1) // Ethereum 
            return 10000000000000000; // 0.01
        if (chainId == 56) // BNB
            return 10000000000000000; // 0.01
        if (chainId == 137) // Polygon
            return 3000000000000000000; // 3
        if (chainId == 250) // Fantom 
            return 3000000000000000000; // 3
        if (chainId == 43114) // Avalanche
            return 50000000000000000; // 0.05

        return 3000000000000000000;
    }

    function setNftBridge(address _bridge) external onlyOwner {
        nftBridge = _bridge;

        emit NftBridgeSet(nftBridge);
    }

    function setBaseUriForType(uint16 nftType, string calldata baseUri) external onlyOwner {
        baseUris[nftType] = bytes(baseUri);

        emit BaseUriForTypeSet(nftType, baseUri);
    }

    function setAllowedCreateTo(uint16 nftType, address contractAddress) external onlyOwner {
        allowedCreateTo[nftType] = ICreateRecipe(contractAddress);

        emit SetAllowedCreateTo(nftType, contractAddress);
    }

    function setAllowedCreateFrom(uint16 nftType, address contractAddress) external onlyOwner {
        allowedCreateFrom[nftType] = contractAddress;

        emit SetAllowedCreateFrom(nftType, contractAddress);
    }

    function setAllowedTransumtateSingleTo(uint16 nftType, address contractAddress) external onlyOwner {
        allowedTransumtateSingleTo[nftType] = ITransmuteSingleRecipe(contractAddress);

        emit SetAllowedTransumtateSingleTo(nftType, contractAddress);
    }

    function setAllowedTransumtateMultipleTo(uint16 nftType, address contractAddress) external onlyOwner {
        allowedTransumtateMultipleTo[nftType] = ITransmuteMultipleRecipe(contractAddress);

        emit SetAllowedTransumtateMultipleTo(nftType, contractAddress);
    }

    function royaltyAddress() external view returns (address payable) {
        return payable(address(royaltySplitter));
    }

    function tokenURI(uint256 id) external view returns (string memory) {
        return uri(id);
    }

    function uri(uint256 id) public view returns (string memory) {
        uint16 nftType = uint16(id & 0xffff);
        bytes memory baseUri = baseUris[nftType];

        require(baseUri.length > 0, "Uri not set");

        return string(abi.encodePacked(baseUri, uint2hexstr(id), ".json"));
    }

    function uint2hexstr(uint i) public pure returns (string memory) {
        uint mask = 15;
        bytes memory bstr = new bytes(64);
        uint k = 64;
        while (k > 0) {
            uint curr = (i & mask);
            bstr[--k] = curr > 9 ?
                bytes1(uint8(55 + curr)) :
                bytes1(uint8(48 + curr)); // 55 = 65 - 10
            i = i >> 4;
        }
        return string(bstr);
    }

    function contractURI() external view returns (string memory) {
        return string(
                abi.encodePacked("https://data.everrise.com/data/memerise-",
                toString(block.chainid),
                ".json")
        );
    }

    function _walletLock(address fromAddress) private view {
        if (everRiseToken.isWalletLocked(fromAddress)) revert WalletLocked();
    }

    modifier walletLock(address fromAddress) {
        _walletLock(fromAddress);
        _;
    }

    function handleMintFee(uint256 baseFee, uint256 quantity) internal {
        uint256 totalFee = baseFee * quantity;
        require(totalFee == 0 || msg.value >= totalFee, "Mint fee not covered");

        uint256 _balance = address(this).balance;
        if (_balance > 0) {
            // Transfer everything, easier than transferring extras later
            sendEthViaCall(payable(address(royaltySplitter)), _balance);
        }
    }

    function toBalanceKey(address account, uint256 tokenId) private pure returns (BalanceKey) {
        if (tokenId > type(uint96).max) revert AmountOutOfRange();

        uint256 key = uint256(uint160(account)) << 96 | uint96(tokenId);
        return BalanceKey.wrap(key);
    }

    function balanceOf(address account, uint256 tokenId) view public returns (uint256) {
        if (account == address(0)) revert NotZeroAddress();

        return _balanceOf[toBalanceKey(account, tokenId)].Amount();
    }
    
    function mint(address to, uint256 tokenId, uint256 amount) external {
        address requestor = _msgSender();
        uint16 nftType = uint16(tokenId & 0xffff);
        require(allowedCreateFrom[nftType] == requestor, "Requestor not allowed to mint that type");

        // Mint new tokens
        AddBalance(to, tokenId, amount);
        emit TransferSingle(to, address(0), to, tokenId, amount);
    }
    
    function create(uint256 tokenId, uint256 amount) external payable {
        uint16 nftType = uint16(tokenId & 0xffff);
        ICreateRecipe creator = allowedCreateTo[nftType];

        if (address(creator) == address(0)) revert NotSetup();

        handleMintFee(mintFee(nftType), amount);

        address from = _msgSender();
        creator.createTo(from, tokenId, amount);

        // Mint new tokens
        AddBalance(from, tokenId, amount);
        emit TransferSingle(from, address(0), from, tokenId, amount);
    }

    function getAllTokensHeld(address account) external view returns (uint96[] memory tokenIds, uint256[] memory amounts) {
        uint96[] storage refTokenIds = tokensHeld[account];
        uint256 tokenIdsLength = refTokenIds.length;

        if (tokenIdsLength < 2) {
            // Position 0 is skipped
            tokenIds = new uint96[](0);
            amounts = new uint256[](0);
            return (tokenIds, amounts);
        }

        uint256 length = tokenIdsLength - 1;
        uint256 position;
        tokenIds = new uint96[](length);
        amounts = new uint256[](length);
        for (uint256 i = 1; i < tokenIdsLength;) {
            unchecked {
                position = i - 1;
            }
            uint96 tokenId = refTokenIds[i];
            tokenIds[position] = tokenId;
            amounts[position] = _balanceOf[toBalanceKey(account, tokenId)].Amount();

            unchecked {
                ++i;
            }
        }
    }

    function AddBalance(address account, uint256 tokenId, uint256 amount) private {
        require(tokenId < type(uint96).max, "Out of range");

        BalanceKey key = toBalanceKey(account, tokenId);
        BalanceAmount currentBalance = _balanceOf[key];
        if (currentBalance.getPosition() > 0) {
            // Simple add
            _balanceOf[key] = currentBalance.add(amount);
        } else {
            uint96[] storage refTokenIds = tokensHeld[account];
            uint256 length = refTokenIds.length;
            if (length == 0) {
                // Add empty zero item
                refTokenIds.push();
                refTokenIds.push(uint96(tokenId));
                _balanceOf[key] = BalanceAmount.wrap((uint256(amount) << 16) | 1);
            } else {
                require(length < type(uint16).max, "Too many types");
                uint16 position = uint16(length);

                refTokenIds.push(uint96(tokenId));
                _balanceOf[key] = BalanceAmount.wrap((uint256(amount) << 16) | position);
            }
        }

        totalSupply += amount;
    }

    function SubtractBalance(address account, uint256 tokenId, uint256 amount) private {
        require(tokenId < type(uint96).max, "Out of range");

        BalanceKey key = toBalanceKey(account, tokenId);
        BalanceAmount currentBalance = _balanceOf[key];

        uint16 position = currentBalance.getPosition();
        require (position > 0, "Non-existance");

        currentBalance = currentBalance.subtract(amount);

        if (currentBalance.Amount() > 0) {
            // Simple decrement
            _balanceOf[key] = currentBalance;
        } else {
            _balanceOf[key] = BalanceAmount.wrap(0);
            // Remove from position array
            uint96[] storage refTokenIds = tokensHeld[account];
            uint256 length = refTokenIds.length;
            require (length > 1, "Token List");

            uint256 last = length - 1;
            if (position < last) {
                uint96 lastTokenId = refTokenIds[last];
                
                key = toBalanceKey(account, lastTokenId);
                currentBalance = _balanceOf[key];

                _balanceOf[key] = currentBalance.setPosition(position);
                refTokenIds[position] = lastTokenId;
            }
            
            refTokenIds.pop();
        }

        totalSupply -= amount;
    }

    function transmuteMultiple(uint256[] calldata toTokenIds, uint256[] calldata toAmounts, uint256[] calldata fromIds, uint256[] calldata fromAmounts) external payable walletLock(_msgSender()) {
        uint256 fromIdsLength = fromIds.length;
        require(fromIdsLength > 0, "No input tokens");
        require(fromIdsLength == fromAmounts.length, "Input: ids and amounts length mismatch");
        uint256 toTokenIdsLength = toTokenIds.length;
        require(toTokenIdsLength > 0, "No output tokens");
        require(toTokenIdsLength == toAmounts.length, "Output: ids and amounts length mismatch");
        
        uint16 nftType = uint16(toTokenIds[0] & 0xffff);

        uint256 totalAmount;
        for (uint256 i = 0; i < toTokenIdsLength; i++) {
            uint256 toTokenId = toTokenIds[i];
            require(nftType == uint16(toTokenId & 0xffff), "Not same type outputs");
            uint256 toAmount = toAmounts[i];
            require(toAmount > 0, "No zero outputs");
            totalAmount += toAmount;
        }

        ITransmuteMultipleRecipe transmutator = allowedTransumtateMultipleTo[nftType];
        if (address(transmutator) == address(0)) revert NotSetup();

        handleMintFee(transmuteFee(nftType), totalAmount);

        _transmuteMultiple(transmutator, toTokenIds, toAmounts, fromIds, fromAmounts);
    }

    function _transmuteMultiple(ITransmuteMultipleRecipe transmutator, uint256[] calldata toTokenIds, uint256[] calldata toAmounts, uint256[] calldata fromIds, uint256[] calldata fromAmounts) private {
        address from = _msgSender();
        transmutator.transmuteMultipleTo(from, toTokenIds, toAmounts, fromIds, fromAmounts);

        // Burn passed in tokens
        uint256 idsLength = fromIds.length;
        for (uint256 i = 0; i < idsLength; i++) {
            uint256 fromId = fromIds[i];
            uint256 fromAmount = fromAmounts[i];

            SubtractBalance(from, fromId, fromAmount);
        }

        emit TransferBatch(from, from, address(0), fromIds, fromAmounts);

        // Mint new tokens
        idsLength = toTokenIds.length;
        for (uint256 i = 0; i < idsLength; i++) {
            uint256 toTokenId = toTokenIds[i];
            uint256 toAmount = toAmounts[i];

            AddBalance(from, toTokenId, toAmount);
        }

        emit TransferBatch(from, address(0), from, toTokenIds, toAmounts);
    }

    function transmuteSingle(uint256 toTokenId, uint256 toAmount, uint256[] calldata fromIds, uint256[] calldata fromAmounts) external payable walletLock(_msgSender()) {
        uint256 fromIdsLength = fromIds.length;
        require(fromIdsLength == fromAmounts.length, "ERC1155: ids and amounts length mismatch");
        require(toAmount > 0, "No zero output");
        
        uint16 nftType = uint16(toTokenId & 0xffff);
        ITransmuteSingleRecipe transmutator = allowedTransumtateSingleTo[nftType];
        if (address(transmutator) == address(0)) revert NotSetup();

        handleMintFee(transmuteFee(nftType), toAmount);

        address from = _msgSender();
        transmutator.transmuteSingleTo(from, toTokenId, toAmount, fromIds, fromAmounts);

        // Burn passed in tokens
        for (uint256 i = 0; i < fromIdsLength; i++) {
            uint256 tokenId = fromIds[i];
            uint256 amount = fromAmounts[i];

            SubtractBalance(from, tokenId, amount);
        }

        emit TransferBatch(from, from, address(0), fromIds, fromAmounts);

        // Mint new tokens
        AddBalance(from, toTokenId, toAmount);
        emit TransferSingle(from, address(0), from, toTokenId, toAmount);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC165, IERC165) returns (bool) {
        return 
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory)
    {
        uint256 accountsLength = accounts.length;
        require(accountsLength == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accountsLength);

        for (uint256 i = 0; i < accountsLength; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    // Approval

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) private {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    // Transfer

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external walletLock(from) {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external walletLock(from) {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function _safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) private {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        SubtractBalance(from, id, amount);
        AddBalance(to, id, amount);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    function _safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) private {
        uint256 idsLength = ids.length;
        require(idsLength == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        for (uint256 i = 0; i < idsLength; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            SubtractBalance(from, id, amount);
            AddBalance(to, id, amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    // Hook checks

    function _doSafeBatchTransferAcceptanceCheck(address operator, address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) private view {
        if (isContract(to)) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeTransferAcceptanceCheck(address operator, address from, address to, uint256 id, uint256 amount, bytes calldata data) private view {
        if (isContract(to)) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    // Bridge functions

    function bridgeNftOut(address from, uint256 id, uint256 amount) external {
        address operator = _msgSender();
        require(operator == nftBridge, "Only bridge");
        _walletLock(from);

        if (isApprovedForAll(from, operator)) {
            revert CallerNotApproved();
        }

        SubtractBalance(from, id, amount);

        emit TransferSingle(operator, from, address(0), id, amount);
        emit NftBridgedOut(address(this), nftBridge, from, id, amount);
    }

    function bridgeNftsOut(address from, uint256[] calldata ids, uint256[] calldata amounts) external {
        address operator = _msgSender();
        require(operator == nftBridge, "Only bridge");
        _walletLock(from);

        if (isApprovedForAll(from, operator)) {
            revert CallerNotApproved();
        }
        uint256 idsLength = ids.length;
        require(idsLength == amounts.length, "ERC1155: ids and amounts length mismatch");

        for (uint256 i = 0; i < idsLength; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            SubtractBalance(from, id, amount);
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
        emit NftsBridgedOut(address(this), nftBridge, from, ids, amounts);
    }

    function bridgeNftIn(address to, uint256 id, uint256 amount) external {
        address operator = _msgSender();
        require(operator == nftBridge, "Only bridge");

        AddBalance(to, id, amount);

        emit TransferSingle(operator, address(0), to, id, amount);
        emit NftBridgedIn(address(this), nftBridge, to, id, amount);
    }

    function bridgeNftsIn(address to, uint256[] calldata ids, uint256[] calldata amounts) external {
        address operator = _msgSender();
        require(operator == nftBridge, "Only bridge");
        uint256 idsLength = ids.length;
        require(idsLength == amounts.length, "ERC1155: ids and amounts length mismatch");

        for (uint256 i = 0; i < idsLength; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            
            AddBalance(to, id, amount);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);
        emit NftsBridgedIn(address(this), nftBridge, to, ids, amounts);
    }

    // Utility functions

    function isContract(address account) private view returns (bool) {
        return account.code.length > 0;
    }

    function toString(uint256 value) private pure returns (bytes memory output)
    {
        if (value == 0)
        {
            return "0";
        }
        uint256 remaining = value;
        uint256 length;
        while (remaining != 0)
        {
            length++;
            remaining /= 10;
        }
        output = new bytes(length);
        uint256 position = length;
        remaining = value;
        while (remaining != 0)
        {
            output[--position] = bytes1(uint8(48 + remaining % 10));
            remaining /= 10;
        }
    }

    // Remove trapped tokens

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
}