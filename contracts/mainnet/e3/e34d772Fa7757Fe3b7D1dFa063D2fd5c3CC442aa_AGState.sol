// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./interfaces/IAGStakeFull.sol";
import "./interfaces/IAlphaGangGenerative.sol";

contract AGState {
    IAGStake constant AGStake =
        IAGStake(0xdb7a1FFCB7beE3b161279c370383c0a3D0459865);
    IAlphaGangGenerative constant AlphaGangG2 =
        IAlphaGangGenerative(0x125808292F4Bb11Bf2D01b070d94E19490f7f4Dc);

    function stakedG2TokensOfOwner(address account)
        external
        view
        returns (uint256[] memory)
    {
        uint256 supply = AlphaGangG2.totalSupply();

        uint256 ownerStakedTokenCount = AGStake.ownerG2StakedCount(account);
        uint256[] memory tokens = new uint256[](ownerStakedTokenCount);

        uint256 index = 0;
        for (uint256 tokenId = 1; tokenId <= supply; tokenId++) {
            if (AGStake.vaultG2(account, tokenId) > 0) {
                tokens[index] = tokenId;
                index++;
            }
        }
        return tokens;
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IAGStake {
    event StakedG2(address owner, uint256[] tokenIds, uint256 timestamp);
    event UnstakedG2(address owner, uint256[] tokenIds, uint256 timestamp);
    event StakedOG(
        address owner,
        uint256[] tokenIds,
        uint256[] counts,
        uint256 timestamp
    );
    event StakedForMint(
        address owner,
        uint256[] tokenIds,
        uint256[] counts,
        uint256 timestamp
    );
    event UnstakedOG(
        address owner,
        uint256[] tokenIds,
        uint256[] counts,
        uint256 timestamp
    );
    event Claimed(address owner, uint256 amount, uint256 timestamp);

    function ogAllocation(address _owner)
        external
        view
        returns (uint256 _allocation);

    function vaultG2(address, uint256) external view returns (uint256);

    function stakeG2(uint256[] calldata tokenIds) external;

    function updateOGAllocation(address _owner, uint256 _count) external;

    function ownerG2StakedCount(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IAlphaGangGenerative {
    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address);

    function setApprovalForAll(address operator, bool approved) external;

    function totalSupply() external view returns (uint256);

    function SUPPLY_MAX() external view returns (uint256);

    function mintActive(uint8 mintType) external view returns (bool);

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory ownerTokens);
}