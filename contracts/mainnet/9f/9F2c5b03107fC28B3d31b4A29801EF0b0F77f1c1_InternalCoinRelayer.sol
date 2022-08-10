/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

pragma solidity 0.6.7;

abstract contract SAFEEngineLike {
    function transferInternalCoins(address,address,uint256) virtual external;
    function coinBalance(address) virtual public view returns (uint256);
}
abstract contract SystemCoinLike {
    function balanceOf(address) virtual public view returns (uint256);
}
abstract contract CoinJoinLike {
    function systemCoin() virtual public view returns (address);
    function join(address, uint256) virtual external;
}

contract InternalCoinRelayer {
    // --- Params ---
    address         public targetAddress;

    SAFEEngineLike  public safeEngine;
    SystemCoinLike  public systemCoin;
    CoinJoinLike    public coinJoin;

    constructor(address targetAddress_, address safeEngine_, address coinJoin_) public {
        require(targetAddress_ != address(0), "InternalCoinRelayer/null-target");
        require(safeEngine_ != address(0), "InternalCoinRelayer/null-safe-engine");
        require(coinJoin_ != address(0), "InternalCoinRelayer/null-coin-join");

        targetAddress = targetAddress_;
        safeEngine    = SAFEEngineLike(safeEngine_);
        coinJoin      = CoinJoinLike(coinJoin_);
        systemCoin    = SystemCoinLike(coinJoin.systemCoin());
    }

    /**
     * @notice Join all ERC20 system coins that the contract has inside the SAFEEngine
     */
    function joinAllCoins() internal {
        if (systemCoin.balanceOf(address(this)) > 0) {
          coinJoin.join(address(this), systemCoin.balanceOf(address(this)));
        }
    }

    /**
     * @notice Transfer coins to an address
     * @param rad Amount of internal system coins to transfer (a number with 45 decimals)
     */
    function giveFunds(uint256 rad) external {
        require(targetAddress != address(0), "InternalCoinRelayer/null-target");

        joinAllCoins();
        require(safeEngine.coinBalance(address(this)) >= rad, "InternalCoinRelayer/not-enough-funds");

        safeEngine.transferInternalCoins(address(this), targetAddress, rad);
    }
}