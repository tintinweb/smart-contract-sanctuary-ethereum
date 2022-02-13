/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.7;
pragma abicoder v2;

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager {
    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract MalTokenStakerHelper {
    address public constant MAL_token  = address(0x6619078Bdd8324E01E9a8D4b3d761b050E5ECF06);
    address public constant WETH_token = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public constant UNI_staker = address(0x1f98407aaB862CdDeF78Ed252D6f557aA5b0f00d);
    INonfungiblePositionManager public constant manager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    function isValidTokenId(uint256 tokenId) public view returns(bool result) {
        (
            ,
            ,
            address token0,
            address token1,
            uint24 fee,
            ,
            ,
            uint128 liquidity,
            ,
            ,
            ,
        ) = manager.positions(tokenId);
        if (token0 != MAL_token) return false;
        if (token1 != WETH_token) return false;
        if (fee != 3000) return false;
        if (liquidity == 0) return false;
        return true;
    }

    function findValidPositions(address owner, uint256 minPosition, uint256 maxPosition) public view returns (uint256[] memory validTokenIds) {
        uint256 ownerTokens = manager.balanceOf(owner);
        maxPosition = (maxPosition > 0 && ownerTokens < maxPosition) ? ownerTokens : maxPosition;
        uint256[] memory buf = new uint256[](maxPosition - maxPosition);
        uint256 tokensFound = 0;
        for(uint256 index = minPosition; index < maxPosition; ++index) {
            uint256 tokenId = manager.tokenOfOwnerByIndex(owner, index);
            if (!isValidTokenId(tokenId)) continue;
            buf[index - minPosition] = tokenId;
            tokensFound += 1;
        }
        validTokenIds = new uint256[](tokensFound);
        uint256 tokenPosition = 0;
        for(uint256 index = minPosition; index < maxPosition; ++index) {
            if (buf[index - minPosition] > 0) {
                validTokenIds[tokenPosition] = buf[index - minPosition];
                tokenPosition += 1;
            }
        }
    }
}