// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ChainlinkClient.sol";

/**
 * Request testnet LINK and ETH here: https://faucets.chain.link/
 * Find information on LINK Token Contracts and get the latest ETH and LINK faucets here: https://docs.chain.link/docs/link-token-contracts/
 */

/**
 * THIS IS AN EXAMPLE CONTRACT WHICH USES HARDCODED VALUES FOR CLARITY.
 * PLEASE DO NOT USE THIS CODE IN PRODUCTION.
 */
contract SC3 is ChainlinkClient {
    using Chainlink for Chainlink.Request;
  
    uint256 public volume;
    
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    
    /**
     * Network: Rinkeby
     * Oracle: 0xF59646024204a733E1E4f66B303c9eF4f68324cC (Chainlink Devrel   
     * Node)
     * Job ID: 6a92925dbb0e48e9b375b1deac4751c0
     * Fee: 0.1 LINK
     */

     /**
     * Network: Kovan
     * Oracle: 0xA1d76ABD287d87d6E1d92262F7D53Cbe4f290505 (Chainlink Devrel   
     * Node)
     * Job ID: fc3ea215bb9e44e088107b29bb495e2d
     * Fee: 0.1 LINK
     */

    constructor() {
        setPublicChainlinkToken();
        oracle = 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8;
        jobId = "d5270d1c311941d0b08bead21fea7747";
        fee = 0.1 * 10 ** 18; // (Varies by network and job)
    }
    
    /**
     * Create a Chainlink request to retrieve API response, find the target
     * data, then multiply by 1000000000000000000 (to remove decimal places from data).
     */
    function requestVolumeData() public returns (bytes32 requestId) 
    {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        
        request.add("get", "https://eodhistoricaldata.com/api/real-time/TEF.MC?api_token=5bddbb6db45b91.96585960&fmt=json");
      
        request.add("path", "close");
        
        return sendChainlinkRequestTo(oracle, request, fee);
    }
    
    /**
     * Receive the response in the form of uint256
     */ 
    function fulfill(bytes32 _requestId, uint256 _volume) public recordChainlinkFulfillment(_requestId)
    {
        volume = _volume;
    }

    // function withdrawLink() external {} - Implement a withdraw function to avoid locking your LINK in the contract
}