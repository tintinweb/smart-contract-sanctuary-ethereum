// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./Ownable.sol";
//import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";

//contract GLinkErc1155ContractTemplate is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {
contract GLinkItem is ERC1155, Ownable, ERC1155Supply {
    constructor() ERC1155("GLinkItemTest4","GLIT4","http://xxxxx.com/") {}

    //白名单
    mapping(address => bool) private _mintWhiteList;
    //token系列的归属地址
    mapping(uint256 => address) private _tokenSeriesOwnership;
    //某一地址下拥有系列计数
    mapping(address => uint256) private _seriesCount;
    //某一地址下拥有系列
    mapping(address => mapping(uint256 => uint256)) private _seriesForAddress;
    //系列nft对应的已投放数量
    mapping(uint256 => uint256) private _seriesNftNum;
    //系列nft对应的总投放数量
    mapping(uint256 => uint256) private _seriesNftMaxNum;

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount/*, bytes memory data*/) public {
        address minter = _msgSender();
        require(
            minter == owner() || isInWhiteList(minter),
            "ERC1155: caller is not owner nor approved"
        );
        require(
            _tokenSeriesOwnership[id] == minter,
            "ERC1155: caller no permission"
        );
        require(
            (_seriesNftMaxNum[id] - _seriesNftNum[id]) >= amount,
            "ERC1155: casting quantity exceeds the maximum"
        );
        _mint(account, id, amount, "");
        _seriesNftNum[id] += amount;
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts/*, bytes memory data*/) public {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        address minter = _msgSender();
        require(
            minter == owner() || isInWhiteList(minter),
            "ERC1155: caller is not owner nor approved"
        );
        for (uint256 i = 0; i < ids.length; i++) {
            require(
                _tokenSeriesOwnership[ids[i]] == minter,
                "ERC1155: caller no permission"
            ); 
            require(
                (_seriesNftMaxNum[ids[i]] - _seriesNftNum[ids[i]]) >= amounts[i],
                "ERC1155: casting quantity exceeds the maximum"
            );
            for (uint256 j = 0; j < ids.length; j++)
            {
                if (i != j)
                {
                    require(ids[i] != ids[j],"ERC1155: ids error");                    
                }         
            }
        }
        _mintBatch(to, ids, amounts, "");
        for (uint256 i = 0; i < ids.length; i++) {
            _seriesNftNum[ids[i]] += amounts[i];
        }
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    //参数account：要查询的持有者地址（查官方售卖剩余的话传官方持有者地址）
    //参数id：要查询的nft的id
    //返回两个参数，第一个是余额，第二个是uri，uri是个json文件，物品信息描述图片链接等都在uri里，需要平台解析该uri获取到的json文件
    function itemInfo(address account, uint256 id) public view returns (uint256,string memory) {
        return (super.balanceOf(account,id),super.uri(id));
    }

    //查看是否是白名单
    function isInWhiteList(address account) public view returns (bool) {
        return _mintWhiteList[account];
    }

    //授权mint白名单
    function setMintWhiteList(address account) 
        public  
        onlyOwner
    {
        _mintWhiteList[account] = true;
    }

    //取消授权mint白名单
    function cancelMintWhiteList(address account) 
        public  
        onlyOwner
    {
        _mintWhiteList[account] = false;
    }

    //创造nft系列
    function createSeries(uint256 id, uint256 amount) public {
        address creater = _msgSender();
        require(
            creater == owner() || isInWhiteList(creater),
            "ERC1155: caller is not owner nor approved"
        );        
        require(
            _tokenSeriesOwnership[id] == address(0),
            "ERC1155: this series already exists"
        );
        require(
            amount > 0,
            "ERC1155: quantity must be greater than 0"
        );

        _seriesNftMaxNum[id] = amount;
        _seriesNftNum[id] = 0;
        _tokenSeriesOwnership[id] = creater;
        _seriesCount[creater] += 1;
        _seriesForAddress[creater][_seriesCount[creater]] = id;
        
    }

    //批量创造nft系列
    function createSeriesBatch(uint256[] memory ids, uint256[] memory amounts) public {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        address creater = _msgSender();
        require(
            creater == owner() || isInWhiteList(creater),
            "ERC1155: caller is not owner nor approved"
        );
        for (uint256 i = 0; i < ids.length; i++) {
            require(
                _tokenSeriesOwnership[ids[i]] == address(0),
                "ERC1155: one series already exists"
            ); 
            require(
                amounts[i] > 0,
                "ERC1155: quantity must be greater than 0"
            );
            for (uint256 j = 0; j < ids.length; j++){
                if (i != j){
                    require(ids[i] != ids[j],"ERC1155: ids error");                    
                }         
            }
        }
        uint256 count = _seriesCount[creater];
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            _seriesNftMaxNum[id] = amounts[i];
            _seriesNftNum[id] = 0;
            _tokenSeriesOwnership[id] = creater;
            count += 1;
            _seriesForAddress[creater][count] = id;
        }
        _seriesCount[creater] = count;
    }
    //获取某系列NFT已铸造数量
    function getSeriesNftNum(uint256 id) public view returns (uint256) {
        return _seriesNftNum[id];
    }
    //获取某系列NFT最大铸造数量
    function getSeriesNftMaxNum(uint256 id) public view returns (uint256) {
        return _seriesNftMaxNum[id];
    }
    //获取某地址已经添加的nft系列
    function getSeriesForAddress(address account) public view returns (uint256[] memory) {
        require(_seriesCount[account] != 0, "ERC1155: no series were created at this address");

        uint256[] memory ids = new uint256[](_seriesCount[account]);

        for (uint256 i = 1; i <= _seriesCount[account]; i++)
        {
            ids[i-1] = _seriesForAddress[account][i];
        }

        return ids;
    }

}