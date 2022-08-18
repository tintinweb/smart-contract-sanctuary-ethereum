/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0;


contract balancer_kovan_init {

    IVault balancerVault;
    IERC20 WEEN;
    IERC20 WETH;
    IERC20 WEEN_WETH_Vault;

    bytes32 poolID;

    
    constructor() {
        balancerVault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8); //balancer vault
        WEEN = IERC20(0xaFF4481D10270F50f203E0763e2597776068CBc5); // WEEN address
        WETH = IERC20(0xd0A1E359811322d97991E03f863a0C30C2cF029C); //WETH address
        WEEN_WETH_Vault = IERC20(0x89E72a2427D4143dc988B13F0D15ab59D07F3a67); //The Weighted vault address is also the BPT token address

        poolID = 0x89e72a2427d4143dc988b13f0d15ab59d07f3a67000200000000000000000a4a; //WEEN-WETH vault ID
    }


    function enterBalancerPool(uint256 amountInWEEN, uint256 amountInWETH) public {

        //Approve the balancer vault to take this amount of WEEN
        WEEN.approve(0xBA12222222228d8Ba445958a75a0704d566BF2C8, amountInWEEN);
        //Approve the balancer vault to take this amount of WETH
        WETH.approve(0xBA12222222228d8Ba445958a75a0704d566BF2C8, amountInWEEN);

        //Set the msg's value to 0
        //Pool ID is declared in the constructor
        //sender is msg.sender
        //recipient is msg.sender
        // Request Tuple Value:
            //Assets: addresses of the assets in the pool
                //First address is FEI, second address is WETH
                 address[] memory assetsInPool = new address[](2);
                    assetsInPool[0] = 0xaFF4481D10270F50f203E0763e2597776068CBc5; //WEEN
                    assetsInPool[1] = 0xd0A1E359811322d97991E03f863a0C30C2cF029C; //WETH
            //maxAmountIn: the amount of token to be put into the pool
                //First amount is the amount set by this functions arg
                //Second amount is null because no WETH is being deposited
                uint256[] memory amountsIn = new uint256[](2);
                    amountsIn[0] = amountInWEEN; 
                    amountsIn[1] = amountInWETH;
            //UserData:
                //using Init which is at an index of 0 in the weighted pool join type enum
                //
                uint256[] memory userDataIn = new uint256[](2);
                    userDataIn[0] = amountInWEEN;
                    userDataIn[1] = amountInWETH;

                bytes memory userData =  abi.encode(
                    ['0', 'userDataIn']
                );

            //fromInternalbalance: whether or not this join is an internal balancer thing or externally sourced
                //This transaction is an external ERC20 transaction 
                 bool fromInternalBalance =  false;

        JoinPoolRequest memory testrequest = JoinPoolRequest(assetsInPool, amountsIn, userData, fromInternalBalance);

        balancerVault.joinPool {value: 0 } (poolID, msg.sender, msg.sender, testrequest);
    }
    
}

    //The struct that needs to be passed to the JoinPool call
    struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }


/**
 * @dev Full external interface for the Vault core contract - no external or public methods exist in the contract that
 * don't override one of these declarations.
 */
interface IVault {
    

    /**
     * @dev Called by users to join a Pool, which transfers tokens from `sender` into the Pool's balance. This will
     * trigger custom Pool behavior, which will typically grant something in return to `recipient` - often tokenized
     * Pool shares.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
     * to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
     * these maximums.
     *
     * If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
     * this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead of the
     * WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
     * back to the caller (not the sender, which is important for relayers).
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
     * sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the final
     * `assets` array might not be sorted. Pools with no registered tokens cannot be joined.
     *
     * If `fromInternalBalance` is true, the caller's Internal Balance will be preferred: ERC20 transfers will only
     * be made for the difference between the requested amount and Internal Balance (if any). Note that ETH cannot be
     * withdrawn from Internal Balance: attempting to do so will trigger a revert.
     *
     * This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
     * directly to the Pool's contract, as is `recipient`.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;


    /**
     * @dev Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
     * trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
     * Pool shares. The amount of tokens that can be withdrawn is limited by the Pool's `cash` balance (see
     * `getPoolTokenInfo`).
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
     * token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
     * it just enforces these minimums.
     *
     * If exiting a Pool that holds WETH, it is possible to receive ETH directly: the Vault will do the unwrapping. To
     * enable this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead
     * of the WETH address. Note that it is not possible to combine ETH and WETH in the same exit.
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If receiving ETH however, the array must
     * be sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the
     * final `assets` array might not be sorted. Pools with no registered tokens cannot be exited.
     *
     * If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
     * an ERC20 transfer will be performed. Note that ETH cannot be deposited to Internal Balance: attempting to
     * do so will trigger a revert.
     *
     * `minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
     * `tokens` array. This array must match the Pool's registered tokens.
     *
     * This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
     * passed directly to the Pool's contract.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

}

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

   
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

    interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
    }

// Address Glossary:
// Hidden Hand balancer briber address: https://etherscan.io/address/0x7Cdf753b45AB0729bcFe33DC12401E55d28308A9
// Hidden Hand bribe vault: https://etherscan.io/address/0x9ddb2da7dd76612e0df237b89af2cf4413733212
// B-30FEI-70WETH-gauge address: https://etherscan.io/address/0x4f9463405f5bc7b4c1304222c1df76efbd81a407
// FEI address: https://etherscan.io/address/0x956F47F50A910163D8BF957Cf5846D573E7f87CA