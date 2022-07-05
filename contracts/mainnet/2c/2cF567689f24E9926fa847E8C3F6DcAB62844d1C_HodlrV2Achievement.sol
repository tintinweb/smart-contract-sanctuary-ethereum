/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

// Copyright (c) 2022 EverRise Pte Ltd. All rights reserved.
// EverRise licenses this file to you under the MIT license.

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

// Copyright (c) 2022 EverRise Pte Ltd. All rights reserved.
// EverRise licenses this file to you under the MIT license.

error NotZeroAddress();    // 0x66385fa3
error CallerNotApproved(); // 0x4014f1a5
error InvalidAddress();    // 0xe6c4247b

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

interface IOwnable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function owner() external view returns (address);
    function transferOwnership(address newOwner) external;
}

error CallerNotOwner();
error UseEverOwn();

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
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner == address(0)) revert NotZeroAddress();

        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
// Copyright (c) 2022 EverRise Pte Ltd. All rights reserved.
// EverRise licenses this file to you under the MIT license.

error FailedEthSend();

contract NativeCoinSender {
    function sendEthViaCall(address payable to, uint256 amount) internal {
        (bool sent, ) = to.call{value: amount}("");
        if (!sent) revert FailedEthSend();
    }
}
// Copyright (c) 2022 EverRise Pte Ltd. All rights reserved.
// EverRise licenses this file to you under the MIT license.

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
// Copyright (c) 2022 EverRise Pte Ltd. All rights reserved.
// EverRise licenses this file to you under the MIT license.

interface IMementoRise is IOwnable {
    function royaltyAddress() external view returns(address payable);
    function mint(address to, uint256 tokenId, uint256 amount) external;
    function mintFee(uint16 typeId) external returns (uint256);
    function setBaseUriForType(uint16 nftType, string calldata baseUri) external;
    function setAllowedCreateFrom(uint16 nftType, address contractAddress) external;
    function setAllowedCreateTo(uint16 nftType, address contractAddress) external;
    function setAllowedTransumtateSingleTo(uint16 nftType, address contractAddress) external;
    function setAllowedTransumtateMultipleTo(uint16 nftType, address contractAddress) external;
}

abstract contract MementoRecipe is NativeCoinSender, Ownable {
    IMementoRise public mementoRise = IMementoRise(0x1C57a5eE9C5A90C9a5e31B5265175e0642b943b1);
    IEverRise public everRiseToken = IEverRise(0xC17c30e98541188614dF99239cABD40280810cA3);

    event EverRiseTokenSet(address indexed tokenAddress);
    event MementoRiseSet(address indexed nftAddress);
    
    modifier onlyMementoRise() {
        require(_msgSender() == address(mementoRise), "Invalid requestor");
        _;
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

address constant EverRiseV3Address = 0xC17c30e98541188614dF99239cABD40280810cA3;
address constant EverRiseV2Address = 0x0cD022ddE27169b20895e0e2B2B8A33B25e63579;
address constant EverRiseV2Address_AVAX = 0xC3A8d300333BFfE3ddF6166F2Bc84E6d38351BED;
address constant riseFeeAddress = 0x0BFc8f6374028f1a61Ae3019E5C845F461575381;

contract HodlrV2Achievement is MementoRecipe {
    IERC20 immutable public everRiseV2;
    IEverRise immutable public everRiseV3 = IEverRise(EverRiseV3Address);
    mapping (address => bool) public processedClaim;
    uint256 tokenId;
    uint256 riseFee = 1000 * 10**18;
    event RiseFeeUpdated(uint256 riseFee);

    constructor() {
        everRiseV2 = block.chainid == 43114 ? 
            IERC20(EverRiseV2Address_AVAX) :
            IERC20(EverRiseV2Address);
        tokenId = 3 + (getChain() << 16);
        
        transferOwnership(mementoRise.owner());
    }

    function claimHodlrV2Achievement()
        external payable
    {
        address account = _msgSender();

        require(everRiseV2.balanceOf(account) > 0, "Not holding RISE v2");
        require(!processedClaim[account], "Already claimed");

        processedClaim[account] = true;
        everRiseV3.transferFrom(account, riseFeeAddress, riseFee);
        handleMintFee(mementoRise.mintFee(uint16(tokenId & 0xffff)), 1);
        mementoRise.mint(account, tokenId, 1);
    }

    function setRiseFee(uint256 riseAmount) external onlyOwner {
        riseFee = riseAmount;
        emit RiseFeeUpdated(riseFee);
    }

    function getRiseFee() external view returns (uint256 _riseFee){
        return riseFee;
    }

    function hasClaimed(address _account) public view returns (bool canClaim, bool claimed){
        claimed = processedClaim[_account];
        uint256 balance = everRiseV2.balanceOf(_account);
        return (balance > 0, claimed);
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