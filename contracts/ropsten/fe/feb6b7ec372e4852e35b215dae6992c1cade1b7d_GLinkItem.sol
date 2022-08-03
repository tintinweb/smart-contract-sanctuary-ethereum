// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./Ownable.sol";
//import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";

//contract GLinkErc1155ContractTemplate is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {
contract GLinkItem is ERC1155, Ownable, ERC1155Supply {
    constructor() ERC1155("GLinkItem","GLI","http://xxxxx.com/") {}

    mapping(address => bool) private _mintWhiteList;
    mapping(address => uint256) private _whiteListMintMinId;
    mapping(address => uint256) private _whiteListMintMaxId;

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount/*, bytes memory data*/) public {
        address minter = _msgSender();
        require(
            minter == owner() || isInWhiteList(minter),
            "ERC1155: caller is not owner nor approved"
        );
        if (minter != owner())
        {
            require(
                id < _whiteListMintMinId[minter] || id > _whiteListMintMaxId[minter],
                "ERC1155: caller is not approved"
            );               
        }
        _mint(account, id, amount, "");
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts/*, bytes memory data*/) public {
        address minter = _msgSender();
        require(
            minter == owner() || isInWhiteList(minter),
            "ERC1155: caller is not owner nor approved"
        );

        if (minter != owner())
        {
            for (uint256 i = 0; i < ids.length; i++) {
                require(
                    ids[i] < _whiteListMintMinId[minter] || ids[i] > _whiteListMintMaxId[minter],
                    "ERC1155: caller is not approved"
                );  
            }
             
        }

        _mintBatch(to, ids, amounts, "");
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

    function isInWhiteList(address account) private view returns (bool) {
        return _mintWhiteList[account];
    }

    //授权mint白名单
    function setMintWhiteList(address account,uint256 min,uint256 max) 
        public  
        onlyOwner
    {
        require(
            min <= 0 || min > max,
            "ERC1155: id segment setting error"
        );
        _mintWhiteList[account] = true;
        _whiteListMintMinId[account] = min;
        _whiteListMintMaxId[account] = max;
    }

    //取消授权mint白名单
    function cancelMintWhiteList(address account) 
        public  
        onlyOwner
    {
        _mintWhiteList[account] = false;
    }

    //查看某个地址的白名单信息
    function lookWhiterInfo(address account) public onlyOwner view returns (uint256,uint256)  {
        if (isInWhiteList(account))
        {
            return (_whiteListMintMinId[account],_whiteListMintMaxId[account]);
        }
        return (0,0);
    }
}