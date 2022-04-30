/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract SmallSwap {
    uint32 totalShares;  // Stores the total amount of share issued for the pool
    uint32 totalToken1;  // Stores the amount of Token1 locked in the pool
    uint32 totalToken2;  // Stores the amount of Token2 locked in the pool
    uint32 K;            // Algorithmic constant used to determine price (K = totalToken1 * totalToken2)

    uint32 constant PRECISION = 100000;  // Precision of 6 decimal places

    mapping(address => uint32) shares;  // Stores the share holding of each provider

    mapping(address => uint32) token1Balance;  // Stores the available balance of user outside of the AMM
    mapping(address => uint32) token2Balance;

    // Ensures that the _qty is non-zero and the user has enough balance
    modifier validAmountCheck(mapping(address => uint32) storage _balance, uint32 _qty) {
        require(_qty > 0, "Amount cannot be zero!");
        require(_qty <= _balance[msg.sender], "Insufficient amount");
        _;
    }

    // Restricts withdraw, swap feature till liquidity is added to the pool
    modifier activePool() {
        require(totalShares > 0, "Zero Liquidity");
        _;
    }

    // Returns the balance of the user
    function getMyHoldings() external view returns(uint32 amountToken1, uint32 amountToken2, uint32 myShare) {
        amountToken1 = token1Balance[msg.sender];
        amountToken2 = token2Balance[msg.sender];
        myShare = shares[msg.sender];
    }

    // Returns the total amount of tokens locked in the pool and the total shares issued corresponding to it
    function getPoolDetails() external view returns(uint32, uint32, uint32) {
        return (totalToken1, totalToken2, totalShares);
    }

    // Sends free token(s) to the invoker
    function faucet(uint32 _amountToken1, uint32 _amountToken2) external {
        token1Balance[msg.sender] = token1Balance[msg.sender] += _amountToken1;
        token2Balance[msg.sender] = token2Balance[msg.sender] += _amountToken2;
    }

    // Adding new liquidity in the pool
    // Returns the amount of share issued for locking given assets
    function provide(uint32 _amountToken1, uint32 _amountToken2) external validAmountCheck(token1Balance, _amountToken1) validAmountCheck(token2Balance, _amountToken2) returns(uint32 share) {
        if(totalShares == 0) { // Genesis liquidity is issued 100 Shares
            share = 100*PRECISION;
        } else{
            uint32 share1 = (totalShares*_amountToken1) / totalToken1;
            uint32 share2 = (totalShares*_amountToken2) / totalToken2;
            require(share1 == share2, "Equivalent value of tokens not provided...");
            share = share1;
        }

        require(share > 0, "Asset value less than threshold for contribution!");
        token1Balance[msg.sender] -= _amountToken1;
        token2Balance[msg.sender] -= _amountToken2;

        totalToken1 += _amountToken1;
        totalToken2 += _amountToken2;
        K = totalToken1*totalToken2;

        totalShares += share;
        shares[msg.sender] += share;
    }

    // Returns amount of Token1 required when providing liquidity with _amountToken2 quantity of Token2
    function getEquivalentToken1Estimate(uint32 _amountToken2) public view activePool returns(uint32 reqToken1) {
        reqToken1 = (totalToken1*_amountToken2) / totalToken2;
    }

    // Returns amount of Token2 required when providing liquidity with _amountToken1 quantity of Token1
    function getEquivalentToken2Estimate(uint32 _amountToken1) public view activePool returns(uint32 reqToken2) {
        (reqToken2 = totalToken2*_amountToken1) / totalToken1;
    }

    // Returns the estimate of Token1 & Token2 that will be released on burning given _share
    function getWithdrawEstimate(uint32 _share) public view activePool returns(uint32 amountToken1, uint32 amountToken2) {
        require(_share <= totalShares, "Share should be less than totalShare");
        amountToken1 = (_share * totalToken1) / totalShares;
        amountToken2 = (_share * totalToken2) / totalShares;
    }

    // Removes liquidity from the pool and releases corresponding Token1 & Token2 to the withdrawer
    function withdraw(uint32 _share) external activePool validAmountCheck(shares, _share) returns(uint32 amountToken1, uint32 amountToken2) {
        (amountToken1, amountToken2) = getWithdrawEstimate(_share);
        
        shares[msg.sender] -= _share;
        totalShares -= _share;

        totalToken1 -= amountToken1;
        totalToken2 -= amountToken2;
        K = (totalToken1 * totalToken2);

        token1Balance[msg.sender] += amountToken1;
        token2Balance[msg.sender] += amountToken2;
    }

    // Returns the amount of Token2 that the user will get when swapping a given amount of Token1 for Token2
    function getSwapToken1Estimate(uint32 _amountToken1) public view activePool returns(uint32 amountToken2) {
        uint32 token1After = totalToken1 + _amountToken1;
        uint32 token2After = K / token1After;
        amountToken2 = totalToken2 - token2After;

        // To ensure that Token2's pool is not completely depleted leading to inf:0 ratio
        if(amountToken2 == totalToken2) amountToken2--;
    }

    // Returns the amount of Token1 that the user should swap to get _amountToken2 in return
    function getSwapToken1EstimateGivenToken2(uint32 _amountToken2) public view activePool returns(uint32 amountToken1) {
        require(_amountToken2 < totalToken2, "Insufficient pool balance");
        uint32 token2After = totalToken2 - _amountToken2;
        uint32 token1After = K / token2After;
        amountToken1 = token1After - totalToken1;
    }

    // Swaps given amount of Token1 to Token2 using algorithmic price determination
    function swapToken1(uint32 _amountToken1) external activePool validAmountCheck(token1Balance, _amountToken1) returns(uint32 amountToken2) {
        amountToken2 = getSwapToken1Estimate(_amountToken1);

        token1Balance[msg.sender] -= _amountToken1;
        totalToken1 += _amountToken1;
        totalToken2 -= amountToken2;
        token2Balance[msg.sender] += amountToken2;
    }

    // Returns the amount of Token2 that the user will get when swapping a given amount of Token1 for Token2
function getSwapToken2Estimate(uint32 _amountToken2) public view activePool returns(uint32 amountToken1) {
    uint32 token2After = totalToken2 + _amountToken2;
    uint32 token1After = K / token2After;
    amountToken1 = totalToken1 - token1After;

    // To ensure that Token1's pool is not completely depleted leading to inf:0 ratio
    if(amountToken1 == totalToken1) amountToken1--;
}

// Returns the amount of Token2 that the user should swap to get _amountToken1 in return
function getSwapToken2EstimateGivenToken1(uint32 _amountToken1) public view activePool returns(uint32 amountToken2) {
    require(_amountToken1 < totalToken1, "Insufficient pool balance");
    uint32 token1After = totalToken1 - _amountToken1;
    uint32 token2After = K / token1After;
    amountToken2 = token2After - totalToken2;
}

    // Swaps given amount of Token2 to Token1 using algorithmic price determination
    function swapToken2(uint32 _amountToken2) external activePool validAmountCheck(token2Balance, _amountToken2) returns(uint32 amountToken1) {
        amountToken1 = getSwapToken2Estimate(_amountToken2);

        token2Balance[msg.sender] -= _amountToken2;
        totalToken2 += _amountToken2;
        totalToken1 -= amountToken1;
        token1Balance[msg.sender] += amountToken1;
    }



}