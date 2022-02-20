/**
 *Submitted for verification at Etherscan.io on 2022-02-19
*/

/**
 *Submitted for verification at Etherscan.io on 2021-02-16
*/

pragma solidity ^0.4.21;

contract TonyDongs {
        address owner;

        struct CoinInfo {
                uint256 price;
                uint256 supply;
                uint256 lastUpdateTimestamp;
                string symbol;
        }

        mapping(string => CoinInfo) tonyDongs;

        event newCoinInfo(
                string name,
                string symbol,
                uint256 price,
                uint256 supply,
                uint256 lastUpdateTimestamp
        );
    
        constructor() public {
                owner = msg.sender;
        }

        function changeOwner(address newOwner) public {
                require(msg.sender == owner);
                owner = newOwner;
        }
    
        function updateCoinInfo(string name, string symbol, uint256 newPrice, uint256 newSupply, uint256 newTimestamp) public {
                require(msg.sender == owner);
                tonyDongs[name] = (CoinInfo(newPrice, newSupply, newTimestamp, symbol));
                emit newCoinInfo(name, symbol, newPrice, newSupply, newTimestamp);
        }
    
        function getCoinInfo(string name) public view returns (uint256, uint256, uint256, string) {
                return (
                        tonyDongs[name].price,
                        tonyDongs[name].supply,
                        tonyDongs[name].lastUpdateTimestamp,
                        tonyDongs[name].symbol
                );
        }
}