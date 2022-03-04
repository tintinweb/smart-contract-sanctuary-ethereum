//SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./Ownable.sol";

interface i0N1 {
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
    function transferFrom(address from, address to, uint256 id) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

interface iWRAP {
    function burnWRAP(uint tokenId) external;
    function mintWRAP(address to, uint tokenId, uint stake) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface iNAN0 {
    function rollNAN0(uint tokenId) external;
    function mintNAN0(address to, uint tokenId) external;
    function exist(uint tokenId) external view returns (bool);
    function ownerOf(uint tokenId) external view returns (address);
    function transferFrom(address from, address to, uint id) external;
}

interface iM0N1 {
    function mintM0N1(uint amount) external;
    function transfer(address to, uint amount) external;
    function balanceOf(address account) external view returns (uint);
    function transferFromContract(address from, address to, uint amount) external;
    function allowance(address owner, address spender) external view returns (uint);
}

/// @title Nanohub
/// @author jolan.eth
contract Nanohub is Ownable {
    /// CONTRACTS
    iM0N1 _M0N1;
    iNAN0 _NAN0;
    i0N1 _0N1;
    iWRAP _WRAP;

    /// STAKING VARS
    mapping (uint => GenesisStake) public stakingGenesisRegistry;
    struct GenesisStake { address owner; uint blockNumber; }

    mapping (uint => SuitedStake) public stakingSuitedRegistry;
    struct SuitedStake { address owner; uint blockNumber; }

    // UTILITY VARS
    bool public ACTIVE = false;
    uint public stakingRatio;
    uint public initialClaimRatio;
    mapping (uint => bool) public initialClaimRegistry;

    // SUIT VARS
    uint public rollPrice;
    mapping (uint => uint) recallPrice;

    constructor(address ONI, address NAN0, address WRAP, address M0N1) {
        _0N1 = i0N1(ONI);
        _M0N1 = iM0N1(M0N1);
        _NAN0 = iNAN0(NAN0);
        _WRAP = iWRAP(WRAP);
    }

    receive() external payable {}
    function onERC721Received(address, address, uint, bytes memory)
    public virtual returns (bytes4) { return this.onERC721Received.selector; }

    function setDefault() public onlyOwner {
        require(!ACTIVE, "error active");
        _M0N1.mintM0N1(777777);
        initialClaimRatio = 3;
        stakingRatio = 2;
        rollPrice = 3;
        ACTIVE = true;
    }

    /// INITIAL CLAIM FUNCTIONS
    function claimInitialM0N1(uint tokenId) public {
        require(!initialClaimRegistry[tokenId], "error claimed");
        require(msg.sender == _0N1.ownerOf(tokenId), "error owner");
        initialClaimRegistry[tokenId] = true;

        _M0N1.transfer(msg.sender, initialClaimRatio);
    }

    function batchClaimInitialM0N1() public {
        uint i = 0;
        uint amount = 0;
        uint balance = _0N1.balanceOf(msg.sender);
        while (i < balance) {
            uint tokenId = _0N1.tokenOfOwnerByIndex(msg.sender, i);
            if (msg.sender == _0N1.ownerOf(tokenId))
                if (!initialClaimRegistry[tokenId]) {
                    initialClaimRegistry[tokenId] = true;
                    amount += initialClaimRatio;
                }
            i++;
        }
        
        require (amount > 0, "error claimed");
        _M0N1.transfer(msg.sender, amount);
    }

    function getAllAvailableM0N1ToClaim(address owner) public view returns (uint) {
        uint i = 0;
        uint amount = 0;
        uint balance = _0N1.balanceOf(owner);
        while (i < balance) {
            uint tokenId = _0N1.tokenOfOwnerByIndex(owner, i);
            if (owner == _0N1.ownerOf(tokenId))
                if (!initialClaimRegistry[tokenId])
                    amount += initialClaimRatio;
            i++;
        }

        return amount;
    }

    /// SUITS FUNCTIONS
    function mintNAN0(uint tokenId) public {
        require(msg.sender == _0N1.ownerOf(tokenId), "error owner");
        require(!_NAN0.exist(tokenId), "error exist");
        require(rollPrice <= _M0N1.balanceOf(msg.sender), "error price");

        _M0N1.transferFromContract(msg.sender, address(this), rollPrice);
        _NAN0.mintNAN0(msg.sender, tokenId);
    }

    function rollNAN0(uint tokenId) public {
        require(msg.sender == _NAN0.ownerOf(tokenId), "error owner");
        require(_NAN0.exist(tokenId), "error exist");
        require(rollPrice <= _M0N1.balanceOf(msg.sender), "error price");

        _M0N1.transferFromContract(msg.sender, address(this), rollPrice);
        _NAN0.rollNAN0(tokenId);
    }

    function recallNAN0(uint tokenId) public {
        require(_NAN0.exist(tokenId), "error exist");
        require(msg.sender != _NAN0.ownerOf(tokenId), "error owner");
        require(msg.sender == _0N1.ownerOf(tokenId), "error owner");
        require(stakingSuitedRegistry[tokenId].owner != address(0), "error staked");
        require(recallPrice[tokenId] <= _M0N1.balanceOf(msg.sender), "error price");

        address suitOwner = _NAN0.ownerOf(tokenId);
        _M0N1.transferFromContract(msg.sender, suitOwner, recallPrice[tokenId]);
        _NAN0.transferFrom(suitOwner, msg.sender, tokenId);
    }

    function transferNAN0(address to, uint tokenId) public {
        require(msg.sender == _NAN0.ownerOf(tokenId), "error owner");
        require(_NAN0.exist(tokenId), "error exist");

        _NAN0.transferFrom(msg.sender, to, tokenId);
    }

    /// SUITED STAKING FUNCTIONS
    function wrapSuited(uint tokenId) public {
        require(msg.sender == _0N1.ownerOf(tokenId), "error owner");
        require(msg.sender == _NAN0.ownerOf(tokenId), "error owner");
        require(_0N1.isApprovedForAll(msg.sender, address(this)), "error approvance");

        stakingSuitedRegistry[tokenId] = SuitedStake(msg.sender, block.number);

        _0N1.transferFrom(msg.sender, address(this), tokenId);
        _NAN0.transferFrom(msg.sender, address(this), tokenId);
        _WRAP.mintWRAP(msg.sender, tokenId, 1);
    }

    function unwrapSuited(uint tokenId)
    public {
        withdrawSuitedM0N1(tokenId);
        delete stakingSuitedRegistry[tokenId];

        _0N1.transferFrom(address(this), msg.sender, tokenId);
        _NAN0.transferFrom(address(this), msg.sender, tokenId);
        _WRAP.burnWRAP(tokenId);
    }
    
    function withdrawSuitedM0N1(uint tokenId)
    public {
        SuitedStake storage Entry = stakingSuitedRegistry[tokenId];
        uint amount = 2 * ((block.number - Entry.blockNumber) / stakingRatio);
        
        require(msg.sender == Entry.owner, "error owner");
        
        _M0N1.transfer(msg.sender, amount);
        Entry.blockNumber = block.number;
    }

    function earnedSuitedM0N1(uint tokenId)
    public view returns (uint) {
        SuitedStake storage Entry = stakingSuitedRegistry[tokenId];
        return 2 * ((block.number - Entry.blockNumber) / stakingRatio);
    }

    /// GENESIS STAKING FUNCTIONS
    function wrapGenesis(uint tokenId)
    public {
        require(msg.sender == _0N1.ownerOf(tokenId), "error owner");
        require(_0N1.isApprovedForAll(msg.sender, address(this)), "error approvance");

        stakingGenesisRegistry[tokenId] = GenesisStake(msg.sender, block.number);

        _0N1.transferFrom(msg.sender, address(this), tokenId);
        _WRAP.mintWRAP(msg.sender, tokenId, 0);
    }

    function unwrapGenesis(uint tokenId)
    public {
        require(msg.sender == _WRAP.ownerOf(tokenId), "error owner");
        withdrawGenesisM0N1(tokenId);
        delete stakingGenesisRegistry[tokenId];

        _0N1.transferFrom(address(this), msg.sender, tokenId);
        _WRAP.burnWRAP(tokenId);
    }
    
    function withdrawGenesisM0N1(uint tokenId)
    public {
        GenesisStake storage Entry = stakingGenesisRegistry[tokenId];
        uint amount = 1 * ((block.number - Entry.blockNumber) / stakingRatio);
        
        require(msg.sender == Entry.owner, "error owner");
        
        _M0N1.transfer(msg.sender, amount);
        Entry.blockNumber = block.number;
    }

    function earnedGenesisM0N1(uint tokenId)
    public view returns (uint) {
        GenesisStake storage Entry = stakingGenesisRegistry[tokenId];
        return 1 * ((block.number - Entry.blockNumber) / stakingRatio);
    }
}