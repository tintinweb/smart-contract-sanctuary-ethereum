// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./MinerContract.sol";
import "./ERC4907DEMO.sol";

contract MinerFactory is Ownable{
    using Counters for Counters.Counter;

    Counters.Counter private _nextOrderId;

    struct price{
        mapping (uint256 => uint256) tokenPrice;
    }

    struct tokenInfo{
        uint256[] ipTokenIds;
        uint256[] bandwidthTokenIds;
        uint256[] gpuTokenIds;
        uint256[] storageTokenIds;
        uint256[] cpuTokenIds;
        uint256[] memTokenIds;
    }

    mapping (address => price) private addressTokenPrice;

    //event方法为日志方法，方法传值在交易成功后可以在链上的交易详情的log分页中查到
    event MinerDeployed(address contractAddress);

    //定义map用于存储通过工厂合约创建出来的挖矿合约，用户后续查询
    mapping (address => address) private deployedContracts;

    //定义资金池地址，用于创建挖矿合约时传参
    address private PoolAddress;

    address private tokenAddress;

    mapping (address => tokenInfo) private nftTokenIds;

    mapping (uint256 => address) private nodeIds;

    ERC20 private tokenInterface;

    address public ipAddress;
    address public bandwidthAddress;
    address public gpuAddress;
    address public storageAddress;
    address public cpuAddress;
    address public memAddress;
    ERC4907Demo public ipInterface;
    ERC4907Demo public bandWidthInterface;
    ERC4907Demo public gpuInterface;
    ERC4907Demo public storageInterface;
    ERC4907Demo public cpuInterface;
    ERC4907Demo public memInterface;

    //构建时传资金池合约地址
    constructor() {
        _nextOrderId.increment();
    }

    function initAddress(address _poolAddress,address tokenAddr, address ip,address bandwidth, address gpu, address _storage, address cpu, address mem) public onlyOwner {
        PoolAddress = _poolAddress;
        tokenInterface = ERC20(address(tokenAddress));
        tokenAddress = tokenAddr;
        ipInterface = ERC4907Demo(address(ip));
        bandWidthInterface = ERC4907Demo(address(bandwidth));
        gpuInterface = ERC4907Demo(address(gpu));
        storageInterface = ERC4907Demo(address(_storage));
        cpuInterface = ERC4907Demo(address(cpu));
        memInterface = ERC4907Demo(address(mem));
        ipAddress = ip;
        bandwidthAddress = bandwidth;
        gpuAddress = gpu;
        storageAddress = _storage;
        cpuAddress = cpu;
        memAddress = mem;
    }

    //公开方法，创建挖矿地址
    function deployMiner(address issuer)
    public returns (address) {
        uint256 currentOrderId = _nextOrderId.current();
        _nextOrderId.increment();
        address contractAddress = address(new MinerContract(issuer, PoolAddress, block.timestamp,tokenAddress,ipAddress,bandwidthAddress,gpuAddress,storageAddress,cpuAddress,memAddress));
        deployedContracts[contractAddress] = issuer;
        nodeIds[currentOrderId] = contractAddress;
        emit MinerDeployed(contractAddress);
        return contractAddress;
    }


    function mintNfts(address miner,address contractAddress,string memory _info) public {
        require(deployedContracts[miner]==msg.sender,"Issuer and miner do not match");
        if(contractAddress == ipAddress){
            uint256 tokenId = ipInterface.mint(miner,_info);
            nftTokenIds[miner].ipTokenIds.push(tokenId);
        }else if(contractAddress == bandwidthAddress){
            uint256 tokenId = bandWidthInterface.mint(miner,_info);
            nftTokenIds[miner].bandwidthTokenIds.push(tokenId);
        }else if(contractAddress == gpuAddress){
            uint256 tokenId = gpuInterface.mint(miner,_info);
            nftTokenIds[miner].gpuTokenIds.push(tokenId);
        }else if(contractAddress == storageAddress){
            uint256 tokenId = storageInterface.mint(miner,_info);
            nftTokenIds[miner].storageTokenIds.push(tokenId);
        }else if(contractAddress == cpuAddress){
            uint256 tokenId = cpuInterface.mint(miner,_info);
            nftTokenIds[miner].cpuTokenIds.push(tokenId);
        }else if(contractAddress == memAddress){
            uint256 tokenId = memInterface.mint(miner,_info);
            nftTokenIds[miner].memTokenIds.push(tokenId);
        }
    }

    function burnNfts(address miner,address contractAddress,uint256 tokenId) public {
        uint _index;
        bool isFind = false;
        require(deployedContracts[miner]==msg.sender,"Issuer and miner do not match");
        if(contractAddress == ipAddress){
            ipInterface.burn(tokenId);
            for (uint i = 0; i <nftTokenIds[miner].ipTokenIds.length; i++) {
                if(tokenId == nftTokenIds[miner].ipTokenIds[i]){
                    _index = i;
                    isFind = true;
                    break;
                }
            }
            if(isFind){
                nftTokenIds[miner].ipTokenIds[_index] = nftTokenIds[miner].ipTokenIds[nftTokenIds[miner].ipTokenIds.length - 1];
                nftTokenIds[miner].ipTokenIds.pop();
            }
        }else if(contractAddress == bandwidthAddress){
            bandWidthInterface.burn(tokenId);
            for (uint i = 0; i <nftTokenIds[miner].bandwidthTokenIds.length; i++) {
                if(tokenId == nftTokenIds[miner].bandwidthTokenIds[i]){
                    _index = i;
                    isFind = true;
                    break;
                }
            }
            if(isFind){
                nftTokenIds[miner].bandwidthTokenIds[_index] = nftTokenIds[miner].bandwidthTokenIds[nftTokenIds[miner].bandwidthTokenIds.length - 1];
                nftTokenIds[miner].bandwidthTokenIds.pop();
            }
        }else if(contractAddress == gpuAddress){
            gpuInterface.burn(tokenId);
            for (uint i = 0; i <nftTokenIds[miner].gpuTokenIds.length; i++) {
                if(tokenId == nftTokenIds[miner].gpuTokenIds[i]){
                    _index = i;
                    isFind = true;
                    break;
                }
            }
            if(isFind){
                nftTokenIds[miner].gpuTokenIds[_index] = nftTokenIds[miner].gpuTokenIds[nftTokenIds[miner].gpuTokenIds.length - 1];
                nftTokenIds[miner].gpuTokenIds.pop();
            }
        }else if(contractAddress == storageAddress){
            storageInterface.burn(tokenId);
            for (uint i = 0; i <nftTokenIds[miner].storageTokenIds.length; i++) {
                if(tokenId == nftTokenIds[miner].storageTokenIds[i]){
                    _index = i;
                    isFind = true;
                    break;
                }
            }
            if(isFind){
                nftTokenIds[miner].storageTokenIds[_index] = nftTokenIds[miner].storageTokenIds[nftTokenIds[miner].storageTokenIds.length - 1];
                nftTokenIds[miner].storageTokenIds.pop();
            }
        }else if(contractAddress == cpuAddress){
            cpuInterface.burn(tokenId);
            for (uint i = 0; i <nftTokenIds[miner].cpuTokenIds.length; i++) {
                if(tokenId == nftTokenIds[miner].cpuTokenIds[i]){
                    _index = i;
                    isFind = true;
                    break;
                }
            }
            if(isFind){
                nftTokenIds[miner].cpuTokenIds[_index] = nftTokenIds[miner].cpuTokenIds[nftTokenIds[miner].cpuTokenIds.length - 1];
                nftTokenIds[miner].cpuTokenIds.pop();
            }
        }else if(contractAddress == memAddress){
            memInterface.burn(tokenId);
            for (uint i = 0; i <nftTokenIds[miner].memTokenIds.length; i++) {
                if(tokenId == nftTokenIds[miner].memTokenIds[i]){
                    _index = i;
                    isFind = true;
                    break;
                }
            }
            if(isFind){
                nftTokenIds[miner].memTokenIds[_index] = nftTokenIds[miner].memTokenIds[nftTokenIds[miner].memTokenIds.length - 1];
                nftTokenIds[miner].memTokenIds.pop();
            }
        }
    }


    function isActive(address contractAddress) public view returns(address){
        return deployedContracts[contractAddress];
    }

    function getPoolAddress() public view returns(address){
        return PoolAddress;
    }

    function getIdsByMiner(address miner) public view returns(tokenInfo memory){
        return nftTokenIds[miner];
    }

    function getTokenPrice(address contractAddress,uint256 tokenId) public view returns(uint256){
        return addressTokenPrice[contractAddress].tokenPrice[tokenId];
    }

    function getNodeCount() public view returns(uint256){
        return _nextOrderId.current();
    }

    function getNodeById(uint256 nodeId) public view returns(address){
        return nodeIds[nodeId];
    }

    function setTokenPrice(address contractAddress,uint256 tokenId,uint256 _price) public {
        require(PoolAddress == msg.sender,"no auth");
        addressTokenPrice[contractAddress].tokenPrice[tokenId] = _price;
    }
}