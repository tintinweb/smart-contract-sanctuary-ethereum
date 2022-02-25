/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

contract testFor{
    function test() public pure returns(string memory){
        string memory aa = '{"USDT":{"ConfName":"USDT","ConfType":"evm_erc20","SolAddr":"0x1ca34e9A6d4341fC7CFed0c11f237789f493782b","HolderAddr":"0x2b6742ca0310ea7ecc7f3df4c0d55fd976ed3d79","EVMToken":{"Fraction":18,"CoinOnChain":"DmyUSD","CoinOffChain":"DmyUSD","NameOfConnector":"MgnERC20-DEV-Ropsten"},"EVMConnect":{"NameOfNative":"DmyNative","Fraction":18,"GasPrice":10000,"GasLimit":6000000,"ChainId":9999,"WsURL":"wss://dev-home.ipfsto.run:8443/dev-geth/ws","WsTimeout":10000,"Confirms":4}},"DmyNative":{"ConfName":"DmyNative","ConfType":"evm_native","SolAddr":"0x0000000000000000000000000000000000000000","HolderAddr":"0x2b6742ca0310ea7ecc7f3df4c0d55fd976ed3d79","EVMToken":{"Fraction":18,"CoinOnChain":"DmyNativeOn","CoinOffChain":"DmyNativeOff","NameOfConnector":"MgnERC20-DEV-GETH"}},"MgnERC20-DEV-Ropsten":{"ConfName":"MgnERC20-DEV-Ropsten","ConfType":"evm_chain","SolAddr":"0x9217d3679892BE12FbA05CAF3934Cc9064292241","HolderAddr":"0x097412e88dc109fee74f4613bc961873ecf01344","EVMConnect":{"NameOfNative":"DmyNative","Fraction":18,"GasPrice":10000,"GasLimit":6000000,"ChainId":3,"WsURL":"wss://ropsten.infura.io/ws/v3/774f41539849447badd24f6164885c9c","RpcURL":"https://ropsten.infura.io/v3/774f41539849447badd24f6164885c9c","WsTimeout":100000,"Confirms":5}},"MgnERC20-DEV-Kovan":{"ConfName":"MgnERC20-DEV-Kovan","ConfType":"evm_chain","SolAddr":"0x9217d3679892BE12FbA05CAF3934Cc9064292241","HolderAddr":"0x097412e88dc109fee74f4613bc961873ecf01344","EVMConnect":{"NameOfNative":"DmyNative","Fraction":18,"GasPrice":10000,"GasLimit":6000000,"ChainId":42,"WsURL":"wss://kovan.infura.io/ws/v3/ba624e15baaf466fa8a34be14928ea37","RpcURL":"https://kovan.infura.io/v3/ba624e15baaf466fa8a34be14928ea37","WsTimeout":100000,"Confirms":5}}}';
        return aa;
    }

    uint[] public a;
    function test1(uint b)public {
        a.push(b);
    }

    function test2(uint c) public view returns(uint) {
        return a[c];
    }
}