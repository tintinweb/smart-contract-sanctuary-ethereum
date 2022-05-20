/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// 接口合约
interface IERC721 {
    // 铸造方法
    function mint(
        uint256 _category,
        bytes memory _data,
        bytes memory _signature
    ) external;

    // 发送方法
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);
}

// 铸造合约
contract ERC721Mint {
    // 构造函数(nft合约地址, 归集地址)
    constructor() payable {
        // 获取总量
        // IERC721(tokenAddress).mint(countItem, dataItem, signature);
        // // 归集
        // IERC721(tokenAddress).safeTransferFrom(
        //     address(this),
        //     ownerInfo,
        //     countItem,
        //     1,
        //     "0x"
        // );
        // // 自毁(收款地址,归集地址)
        // selfdestruct(payable(ownerInfo));
    }

    function mintInfo(  address tokenAddress,
        uint256 countItem,
        bytes memory dataItem,
        bytes memory signature,
        address ownerInfo)
       public
    {
            // 获取总量
        IERC721(tokenAddress).mint(countItem, dataItem, signature);
        // 归集
        IERC721(tokenAddress).safeTransferFrom(
            address(this),
            ownerInfo,
            countItem,
            1,
            "0x"
        );
        selfdestruct(payable(ownerInfo));
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

}

// 工厂合约
contract BatchMint {
    // 所有者地址
    address public owner;
    address public cc;

    constructor() {
        // 所有者 = 合约部署者
        owner = msg.sender;
    }

    // 部署方法,(NFT合约地址,抢购数量)
    function deploy(
        bytes32[] memory saltArr,
        address tokenAddress,
        uint256[] memory countArr,
        bytes[] memory dataArr,
        bytes[] memory signatureArr,
        address sendAddress
    ) public {
        require(msg.sender == owner, "not owner");
        // 用抢购数量进行循环
        for (uint256 i; i < saltArr.length; i++) {
            // 部署合约(抢购总价)(NFT合约地址,所有者地址)
            ERC721Mint c = new ERC721Mint{salt: saltArr[i]}();
            cc = address(c);
            c.mintInfo(tokenAddress,countArr[i],
                dataArr[i],
                signatureArr[i],
                sendAddress);
        }
    }

    function getAddress(
        bytes32 salt
    ) public view returns (address) {
        address predictedAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            salt,
                            keccak256(
                                abi.encodePacked(
                                    type(ERC721Mint).creationCode
                                )
                            )
                        )
                    )
                )
            )
        );

        return predictedAddress;
    }

    function balanceOf(address tokenAddress,address searchAddress, uint256 id)
        external
        view
        returns (uint256)
    {
        uint256 count = IERC721(tokenAddress).balanceOf(searchAddress, id);
        return count;
    }

}