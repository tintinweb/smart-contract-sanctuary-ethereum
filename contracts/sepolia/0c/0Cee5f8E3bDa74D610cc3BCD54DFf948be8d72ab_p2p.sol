/**
 *Submitted for verification at Etherscan.io on 2023-06-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface USD {
    function balanceOf(address account) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract p2p {
    USD public USDc;
    USD public USDt;
    address owner;
    bytes32 public constant P2P_ADMIN = keccak256("P2P_ADMIN");
    uint saleOrderRegistryCount;

    struct SellOrderDetails {
        uint sellOrderId;
        address sellerAddress;
        string  tokenId;
        uint256 availableTokens;
        string exchangeToken;
        uint pricePerToken;
    }
    // mapping(uint => uint) public sellOrderMap;
    // mapping(address => sellOrderMap) public addressMap;
    mapping(uint => SellOrderDetails) sellOrderMap;

    constructor() {
        owner = msg.sender;
    }

    function postSellOrder(
        address sellerAddress,
        string memory tokenId,
        uint availableTokens,
        string memory exchangeToken,
        uint pricePerToken
    ) public returns(uint) {
        uint orderId =saleOrderRegistryCount;
        // amount should be > 0

        // transfer USDC to this contract
       //
         USDc.transferFrom(sellerAddress, address(this), availableTokens );

        // update staking balance
        
        sellOrderMap[saleOrderRegistryCount] = SellOrderDetails(saleOrderRegistryCount,
        sellerAddress,
            tokenId,
            availableTokens,
            exchangeToken,
            pricePerToken
        );
        saleOrderRegistryCount++;
return orderId;
    
    }


function getSellOrders() public view returns (SellOrderDetails[] memory){
     SellOrderDetails[] memory ret = new SellOrderDetails[](saleOrderRegistryCount);
    for (uint i = 0; i < saleOrderRegistryCount; i++) {
        ret[i] = sellOrderMap[i];
    }
    return ret;

}
    function approveDeposit(address spender, uint256 amount) public {
        
        USDc.approve(spender, amount);

        
    }

    // Unstaking Tokens (Withdraw)
    function withdrawSellOrder(uint sellOrderId) public {
        sellOrderMap[sellOrderId].availableTokens=0;

     
    }

    function setTokenAddress(
        address _usdcTokenAddres,
        address _usdtTokenAddres
    ) public onlyOwner {
        USDc = USD(_usdcTokenAddres);
        USDt = USD(_usdtTokenAddres);
    }


    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");

        _;
    }
}