/*

          
            .oooooo.   oooo    oooo ooooooooo.     .oooooo.     
           d8P'  `Y8b  `888   .8P'  `888   `Y88.  d8P'  `Y8b    
          888      888  888  d8'     888   .d88' 888            
          888      888  88888[       888ooo88P'  888            
          888      888  888`88b.     888         888            
          `88b    d88'  888  `88b.   888         `88b    ooo    
           `Y8bood8P'  o888o  o888o o888o         `Y8bood8P'    
          
          
            .oooooo.      .oooooo.   ooooo        oooooooooo.   
           d8P'  `Y8b    d8P'  `Y8b  `888'        `888'   `Y8b  
          888           888      888  888          888      888 
          888           888      888  888          888      888 
          888     ooooo 888      888  888          888      888 
          `88.    .88'  `88b    d88'  888       o  888     d88' 
           `Y8bood8P'    `Y8bood8P'  o888ooooood8 o888bood8P'   
          
           
          
           𝙰𝙽 𝙴𝚇𝚃𝙴𝙽𝚂𝙸𝙾𝙽 𝚃𝙾 𝙾𝙺𝙿𝙲 𝙶𝙰𝙻𝙻𝙴𝚁𝚈 𝙰𝚁𝚃𝚆𝙾𝚁𝙺 #𝟼𝟿: "𝙰𝙸𝚁𝙳𝚁𝙾𝙿"

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.14;

import "solmate/tokens/ERC20.sol";
import "solmate/auth/Owned.sol";
import "./interfaces/IOKPC.sol";
import "./interfaces/IOKPCMarketplace.sol";

/** 
@title OKPC Gold
@author shahruz.eth
*/

contract OKPCGold is Owned, ERC20 {
    // @dev Core OKPC contract
    IOKPC public immutable OKPC;

    // @dev Claim config
    uint256 public constant OKPC_CLAIM_MAX = 1_024;
    uint256 public constant AIRDROP_CLAIM = 10_000;

    // @dev Screen staking config
    uint256 public SCREEN_STAKING_INTERVAL = 64 days;
    uint256 public SCREEN_STAKING_REWARD = 256;

    // @dev Claim registry
    bool public CLAIMABLE;
    struct OKPCClaim {
        bool okpcClaimed;
        bool artworkClaimed;
        uint128 stakingLastClaimed;
    }
    mapping(uint256 => OKPCClaim) public okpcClaims;
    error ClaimNotOpen();
    error NoOKGLDClaimable();

    // @dev Modifiers
    modifier ifClaimable() {
        if (!CLAIMABLE) revert ClaimNotOpen();
        _;
    }

    // @dev Constructor
    constructor(IOKPC okpcAddress)
        Owned(msg.sender)
        ERC20("OKPC GOLD", "OKGLD", 18)
    {
        OKPC = okpcAddress;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  CLAIM ALL                                 */
    /* -------------------------------------------------------------------------- */

    // @notice Claim all eligible OKGLD for an OKPC.
    // @param pcId An OKPC tokenId. Reverts if the token is not owned by the caller.
    function claim(uint256 pcId) external ifClaimable {
        if (OKPC.ownerOf(pcId) != msg.sender) revert NoOKGLDClaimable();
        uint256 amount;
        amount += _claimForOKPC(pcId);
        amount += _claimForArtwork(pcId);
        amount += _claimForScreenStaking(pcId);
        if (amount == 0) revert NoOKGLDClaimable();
        _mint(msg.sender, amount * 10**decimals);
    }

    // @notice Claim all eligible OKGLD for a set of OKPCs.
    // @param pcIds An array of OKPC tokenIds. Tokens not owned by the caller are skipped.
    function claim(uint256[] calldata pcIds) external ifClaimable {
        uint256 amount;
        for (uint256 i; i < pcIds.length; i++)
            if (OKPC.ownerOf(pcIds[i]) == msg.sender) {
                amount += _claimForOKPC(pcIds[i]);
                amount += _claimForArtwork(pcIds[i]);
                amount += _claimForScreenStaking(pcIds[i]);
            }
        if (amount == 0) revert NoOKGLDClaimable();
        _mint(msg.sender, amount * 10**decimals);
    }

    // @notice Calculate the total amount of OKGLD an OKPC is eligible to claim.
    // @param pcId An OKPC tokenId.
    function claimableAmount(uint256 pcId)
        public
        view
        returns (uint256 amount)
    {
        return
            claimableAmountForOKPC(pcId) +
            claimableAmountForArtwork(pcId) +
            claimableAmountForScreenStaking(pcId);
    }

    // @notice Calculate the total amount of OKGLD a set of OKPCs are eligible to claim.
    // @param pcIds An array of OKPC tokenIds.
    function claimableAmount(uint256[] calldata pcIds)
        public
        view
        returns (uint256 amount)
    {
        for (uint256 i; i < pcIds.length; i++)
            amount += claimableAmount(pcIds[i]);
    }

    /* -------------------------------------------------------------------------- */
    /*                                 OKPC CLAIM                                 */
    /* -------------------------------------------------------------------------- */

    // @notice Claim OKGLD for an OKPC, based on its clock speed and amount of art collected.
    // @param pcId An OKPC tokenId. Reverts if the token is not owned by the caller.
    function claimForOKPC(uint256 pcId) external ifClaimable {
        if (OKPC.ownerOf(pcId) != msg.sender) revert NoOKGLDClaimable();
        uint256 amount = _claimForOKPC(pcId);
        if (amount == 0) revert NoOKGLDClaimable();
        _mint(msg.sender, amount * 10**decimals);
    }

    // @notice Claim OKGLD for a set of OKPCs, based on their clock speeds and amounts of art collected.
    // @param pcIds An array of OKPC tokenIds. Tokens not owned by the caller are skipped.
    function claimForOKPC(uint256[] calldata pcIds) external ifClaimable {
        uint256 amount;
        for (uint256 i; i < pcIds.length; i++)
            if (OKPC.ownerOf(pcIds[i]) == msg.sender)
                amount += _claimForOKPC(pcIds[i]);
        if (amount == 0) revert NoOKGLDClaimable();
        _mint(msg.sender, amount * 10**decimals);
    }

    // @dev Calculate the amount of OKGLD an OKPC is eligible to claim, based on its clock speed and amount of art collected.
    // @dev Register the claimed OKPC using its tokenId to lock future claims.
    function _claimForOKPC(uint256 pcId) private returns (uint256 amount) {
        amount = claimableAmountForOKPC(pcId);
        if (amount > 0) okpcClaims[pcId].okpcClaimed = true;
    }

    // @notice Calculate the amount of OKGLD an OKPC is eligible to claim, based on its clock speed and amount of art collected.
    // @param pcId An OKPC tokenId.
    function claimableAmountForOKPC(uint256 pcId)
        public
        view
        returns (uint256 amount)
    {
        return claimableAmountForOKPC(pcId, 0);
    }

    // @notice Calculate the amount of OKGLD a set of OKPCs is eligible to claim, based on its clock speed and amount of art collected.
    // @param pcIds An array of OKPC tokenIds.
    function claimableAmountForOKPC(uint256[] calldata pcIds)
        public
        view
        returns (uint256 amount)
    {
        for (uint256 i; i < pcIds.length; i++)
            amount += claimableAmountForOKPC(pcIds[i], 0);
    }

    // @notice Calculate the projected amount of OKGLD a set of OKPCs will be eligible to claim after a specified number of blocks, based on their clock speeds and amount of art collected.
    // @param pcIds An array of OKPC tokenIds.
    // @param afterBlocks An optional number of blocks to skip ahead for projected clock speed scores.
    function claimableAmountForOKPC(
        uint256[] calldata pcIds,
        uint256 afterBlocks
    ) public view returns (uint256 amount) {
        for (uint256 i; i < pcIds.length; i++)
            amount += claimableAmountForOKPC(pcIds[i], afterBlocks);
    }

    // @notice Calculate the projected amount of OKGLD an OKPC will be eligible to claim after a specified number of blocks, based on its clock speed and amount of art collected.
    // @param pcId An OKPC tokenId.
    // @param afterBlocks An optional number of blocks to skip ahead for projected clock speed scores.
    function claimableAmountForOKPC(uint256 pcId, uint256 afterBlocks)
        public
        view
        returns (uint256 amount)
    {
        if (okpcClaims[pcId].okpcClaimed == false) {
            uint256 artCount = OKPC.artCountForOKPC(pcId);
            uint256 total = (clockSpeedProjected(pcId, afterBlocks) / 2) *
                2**(artCount > 3 ? 3 : artCount);
            amount = total > OKPC_CLAIM_MAX ? OKPC_CLAIM_MAX : total;
        }
    }

    // @notice Calculate the projected clock speed of an OKPC after a specified number of blocks.
    // @param pcId An OKPC tokenId.
    // @param afterBlocks A number of blocks to skip ahead.
    function clockSpeedProjected(uint256 pcId, uint256 afterBlocks)
        public
        view
        returns (uint256)
    {
        (uint256 savedSpeed, uint256 lastBlock, , ) = OKPC.clockSpeedData(pcId);
        if (lastBlock == 0) return 1;
        uint256 delta = block.number + afterBlocks - lastBlock;
        uint256 multiplier = delta / 200_000;
        uint256 clockSpeedMaxMultiplier = OKPC.clockSpeedMaxMultiplier();
        if (multiplier > clockSpeedMaxMultiplier)
            multiplier = clockSpeedMaxMultiplier;
        uint256 total = savedSpeed + ((delta * (multiplier + 1)) / 10_000);
        if (total < 1) total = 1;
        return total;
    }

    // @notice Calculate the projected clock speed of a set of OKPCs after a specified number of blocks.
    // @param pcIds An array of OKPC tokenIds.
    // @param afterBlocks A number of blocks to skip ahead.
    function clockSpeedProjected(uint256[] calldata pcIds, uint256 afterBlocks)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](pcIds.length);
        for (uint256 i; i < pcIds.length; i++)
            result[i] = clockSpeedProjected(pcIds[i], afterBlocks);
        return result;
    }

    /* -------------------------------------------------------------------------- */
    /*                                ARTWORK CLAIM                               */
    /* -------------------------------------------------------------------------- */

    // @notice Claim OKGLD for an OKPC that has collected the AIRDROP artwork from the Gallery.
    // @param pcId An OKPC tokenId. Reverts if the token is not owned by the caller.
    function claimForArtwork(uint256 pcId) external ifClaimable {
        if (OKPC.ownerOf(pcId) != msg.sender) revert NoOKGLDClaimable();
        uint256 amount = _claimForArtwork(pcId);
        if (amount == 0) revert NoOKGLDClaimable();
        _mint(msg.sender, amount * 10**decimals);
    }

    // @notice Claim OKGLD for a set of OKPCs that have collected the AIRDROP artwork from the Gallery.
    // @param pcIds An array of OKPC tokenIds. Tokens not owned by the caller are skipped.
    function claimForArtwork(uint256[] calldata pcIds) external ifClaimable {
        uint256 amount;
        for (uint256 i; i < pcIds.length; i++)
            if (OKPC.ownerOf(pcIds[i]) == msg.sender)
                amount += _claimForArtwork(pcIds[i]);
        if (amount == 0) revert NoOKGLDClaimable();
        _mint(msg.sender, amount * 10**decimals);
    }

    // @dev Calculate the amount of OKGLD an OKPC is eligible to claim, based on collecting the AIRDROP artwork from the Gallery.
    // @dev Register the artwork claim using its tokenId to lock future claims.
    function _claimForArtwork(uint256 pcId) private returns (uint256 amount) {
        amount = claimableAmountForArtwork(pcId);
        if (amount > 0) okpcClaims[pcId].artworkClaimed = true;
    }

    // @notice Calculate the amount of OKGLD an OKPC is eligible to claim, based on collecting the AIRDROP artwork from the Gallery.
    // @param pcId An OKPC tokenId.
    function claimableAmountForArtwork(uint256 pcId)
        public
        view
        returns (uint256 amount)
    {
        if (
            okpcClaims[pcId].artworkClaimed == false &&
            OKPC.artCollectedByOKPC(pcId, 69)
        ) {
            if (
                OKPC.marketplaceAddress() == address(0) ||
                IOKPCMarketplace(OKPC.marketplaceAddress()).didMint(pcId, 69)
            ) amount = AIRDROP_CLAIM;
        }
    }

    // @notice Calculate the amount of OKGLD a set of OKPCs is eligible to claim, based on collecting the AIRDROP artwork from the Gallery.
    // @param pcId An array of OKPC tokenIds.
    function claimableAmountForArtwork(uint256[] calldata pcIds)
        public
        view
        returns (uint256 amount)
    {
        for (uint256 i; i < pcIds.length; i++)
            amount += claimableAmountForArtwork(pcIds[i]);
    }

    /* -------------------------------------------------------------------------- */
    /*                               SCREEN STAKING                               */
    /* -------------------------------------------------------------------------- */

    // @notice Claim OKGLD for an OKPC that is continuously displaying the AIRDROP artwork from the Gallery.
    // @param pcId An OKPC tokenId. Reverts if the token is not owned by the caller.
    function claimForScreenStaking(uint256 pcId) external ifClaimable {
        if (OKPC.ownerOf(pcId) != msg.sender) revert NoOKGLDClaimable();
        uint256 amount = _claimForScreenStaking(pcId);
        if (amount == 0) revert NoOKGLDClaimable();
        _mint(msg.sender, amount * 10**decimals);
    }

    // @notice Claim OKGLD for a set of OKPCs that are continuously displaying the AIRDROP artwork from the Gallery.
    // @param pcIds A set of OKPC tokenIds. Tokens not owned by the caller are skipped.
    function claimForScreenStaking(uint256[] calldata pcIds)
        external
        ifClaimable
    {
        uint256 amount;
        for (uint256 i; i < pcIds.length; i++)
            if (OKPC.ownerOf(pcIds[i]) == msg.sender)
                amount += _claimForScreenStaking(pcIds[i]);
        if (amount == 0) revert NoOKGLDClaimable();
        _mint(msg.sender, amount * 10**decimals);
    }

    // @dev Calculate the amount of OKGLD an OKPC is eligible to claim, based on continuously displaying the AIRDROP artwork from the Gallery.
    // @dev Register the screen staking claim to reset the clock.
    function _claimForScreenStaking(uint256 pcId)
        private
        returns (uint256 amount)
    {
        amount = claimableAmountForScreenStaking(pcId);
        if (amount > 0)
            okpcClaims[pcId].stakingLastClaimed = uint128(block.timestamp);
    }

    // @notice Calculate the amount of OKGLD an OKPC is eligible to claim, based on continuously displaying the AIRDROP artwork from the Gallery.
    // @param pcId An OKPC tokenId.
    function claimableAmountForScreenStaking(uint256 pcId)
        public
        view
        returns (uint256 amount)
    {
        return claimableAmountForScreenStaking(pcId, 0);
    }

    // @notice Calculate the amount of OKGLD a set of OKPCs is eligible to claim, based on continuously displaying the AIRDROP artwork from the Gallery.
    // @param pcIds An array of OKPC tokenIds.
    function claimableAmountForScreenStaking(uint256[] calldata pcIds)
        public
        view
        returns (uint256 amount)
    {
        for (uint256 i; i < pcIds.length; i++)
            amount += claimableAmountForScreenStaking(pcIds[i]);
    }

    // @notice Calculate the projected amount of OKGLD an OKPC will be eligible to claim after a specified number of seconds, based on continuously displaying the AIRDROP artwork from the Gallery.
    // @param pcId An OKPC tokenId.
    // @param afterTime An optional number of seconds to skip ahead for projected screen staking rewards.
    function claimableAmountForScreenStaking(uint256 pcId, uint256 afterTime)
        public
        view
        returns (uint256 amount)
    {
        if (OKPC.activeArtForOKPC(pcId) != 69) return 0;
        (, , , uint256 artLastChanged) = OKPC.clockSpeedData(pcId);
        uint256 previous = (
            okpcClaims[pcId].stakingLastClaimed > artLastChanged
                ? okpcClaims[pcId].stakingLastClaimed
                : artLastChanged
        );
        if (block.timestamp + afterTime >= previous + SCREEN_STAKING_INTERVAL)
            amount =
                SCREEN_STAKING_REWARD *
                ((block.timestamp + afterTime - previous) /
                    SCREEN_STAKING_INTERVAL);
    }

    // @notice Calculate the projected amount of OKGLD a set of OKPCs will be eligible to claim after a specified number of seconds, based on continuously displaying the AIRDROP artwork from the Gallery.
    // @param pcIds An array of OKPC tokenIds.
    // @param afterTime An optional number of seconds to skip ahead for projected screen staking rewards.
    function claimableAmountForScreenStaking(
        uint256[] calldata pcIds,
        uint256 afterTime
    ) public view returns (uint256 amount) {
        for (uint256 i; i < pcIds.length; i++)
            amount += claimableAmountForScreenStaking(pcIds[i], afterTime);
    }

    /* -------------------------------------------------------------------------- */
    /*                               TOKEN FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */

    // @notice Burn tokens and decrease the totalSupply.
    // @param amount An amount of tokens to burn.
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /* -------------------------------------------------------------------------- */
    /*                                    OWNER                                   */
    /* -------------------------------------------------------------------------- */

    // @notice Turn the ability to claim on or off. Owner only.
    function setClaimable(bool claimable) external onlyOwner {
        CLAIMABLE = claimable;
    }

    // @notice Adjust the screen staking configuration. Owner only.
    function setScreenStakingConfig(
        uint256 screenStakingInterval,
        uint256 screenStakingReward
    ) external onlyOwner {
        SCREEN_STAKING_INTERVAL = screenStakingInterval;
        SCREEN_STAKING_REWARD = screenStakingReward;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

interface IOKPC {
    function marketplaceAddress() external view returns (address);

    function owner() external view returns (address);

    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function artCountForOKPC(uint256) external view returns (uint256);

    function clockSpeed(uint256) external view returns (uint256);

    function clockSpeedMaxMultiplier() external view returns (uint256);

    function clockSpeedData(uint256 pcId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function activeArtForOKPC(uint256 pcId) external view returns (uint256);

    function artCollectedByOKPC(uint256 pcId, uint256 artId)
        external
        view
        returns (bool);

    function setMarketplaceAddress(address marketplaceAddress) external;

    function transferArt(
        uint256 fromOKPC,
        uint256 toOKPC,
        uint256 artId
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

interface IOKPCMarketplace {
    function didMint(uint256 pcId, uint256 artId) external view returns (bool);
}