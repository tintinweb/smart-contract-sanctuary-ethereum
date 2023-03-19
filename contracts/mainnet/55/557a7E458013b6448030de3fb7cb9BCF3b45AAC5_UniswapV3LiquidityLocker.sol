// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import "./interfaces/INonfungiblePositionManager.sol";
import "./libraries/Position.sol";

contract UniswapV3LiquidityLocker {
    using Position for Position.Info;

    mapping(uint256 => Position.Info) public lockedLiquidityPositions;

    INonfungiblePositionManager private _uniswapNFPositionManager;
    uint128 private constant MAX_UINT128 = type(uint128).max;

    event PositionUpdated(Position.Info position);
    event FeeClaimed(uint256 tokenId);
    event TokenUnlocked(uint256 tokenId);

    constructor() {
        _uniswapNFPositionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    }

    function lockLPToken(Position.Info calldata params) external {
        _uniswapNFPositionManager.transferFrom(msg.sender, address(this), params.tokenId);

        params.isPositionValid();

        lockedLiquidityPositions[params.tokenId] = params;

        emit PositionUpdated(params);
    }

    function claimLPFee(uint256 tokenId) external returns (uint256 amount0, uint256 amount1) {
        Position.Info memory llPosition = lockedLiquidityPositions[tokenId];

        llPosition.isTokenIdValid(tokenId);
        llPosition.isFeeClaimAllowed();

        (amount0, amount1) = _uniswapNFPositionManager.collect(
            INonfungiblePositionManager.CollectParams(tokenId, llPosition.feeReciever, MAX_UINT128, MAX_UINT128)
        );

        emit FeeClaimed(tokenId);
    }

    function updateOwner(uint256 tokenId, address owner) external {
        Position.Info storage llPosition = lockedLiquidityPositions[tokenId];

        llPosition.isTokenIdValid(tokenId);
        llPosition.isOwner();

        llPosition.owner = owner;

        emit PositionUpdated(llPosition);
    }

    function updateFeeReciever(uint256 tokenId, address feeReciever) external {
        Position.Info storage llPosition = lockedLiquidityPositions[tokenId];

        llPosition.isTokenIdValid(tokenId);
        llPosition.isOwner();

        llPosition.feeReciever = feeReciever;

        emit PositionUpdated(llPosition);
    }

    function renounceBeneficiaryUpdate(uint256 tokenId) external {
        Position.Info storage llPosition = lockedLiquidityPositions[tokenId];

        llPosition.isTokenIdValid(tokenId);
        llPosition.isOwner();

        llPosition.allowBeneficiaryUpdate = false;

        emit PositionUpdated(llPosition);
    }

    function unlockToken(uint256 tokenId) external {
        Position.Info memory llPosition = lockedLiquidityPositions[tokenId];

        llPosition.isTokenIdValid(tokenId);
        llPosition.isTokenUnlocked();

        _uniswapNFPositionManager.transferFrom(address(this), llPosition.owner, tokenId);

        delete lockedLiquidityPositions[tokenId];

        emit TokenUnlocked(tokenId);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.19;
pragma abicoder v2;

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager {
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
    function transferFrom(address from, address to, uint256 tokenId) external;

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

library Position {
    struct Info {
        uint256 tokenId;
        // duration in which fees can't be claimed
        uint256 cliff;
        // start timestamp
        uint256 start;
        // total lock duration
        uint256 duration;
        // allow fees to be claimed at feeReciever address
        bool allowFeeClaim;
        // allow owner to transfer ownership or update feeReciever
        bool allowBeneficiaryUpdate;
        // address to receive earned fees
        address feeReciever;
        // owner of the position
        address owner;
    }

    function isPositionValid(Info memory self) internal view {
        require(self.owner != address(0), "ULL::OWNER_ZERO_ADDRESS");
        require(self.duration >= self.cliff, "ULL::CLIFF_GT_DURATION");
        require(self.duration > 0, "ULL::INVALID_DURATION");
        require((self.start + self.duration) > block.timestamp, "ULL::INVALID_ENDING_TIME");
    }

    function isOwner(Info memory self) internal view {
        require(self.owner == msg.sender && self.allowBeneficiaryUpdate, "ULL::NOT_AUTHORIZED");
    }

    function isTokenIdValid(Info memory self, uint256 tokenId) internal pure {
        require(self.tokenId == tokenId, "ULL::INVALID_TOKEN_ID");
    }

    function isTokenUnlocked(Info memory self) internal view {
        require((self.start + self.duration) < block.timestamp, "ULL::NOT_UNLOCKED");
    }

    function isFeeClaimAllowed(Info memory self) internal view {
        require(self.allowFeeClaim, "ULL::FEE_CLAIM_NOT_ALLOWED");
        require((self.start + self.cliff) < block.timestamp, "ULL::CLIFF_NOT_ENDED");
    }
}