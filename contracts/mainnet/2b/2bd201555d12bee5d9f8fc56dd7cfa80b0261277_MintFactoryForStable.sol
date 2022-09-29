/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// 仓库地址:https://github.com/yulin19970210/contract

interface IERC721 {
    function totalSupply() external view returns (uint);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function mint(uint256 amount) external payable;

    function Mint(uint256 amount) external payable;

    function freeMint() external payable;

    function freeMint(uint256 amount) external payable;

    function mintFree() external payable;

    function mintFree(uint256 amount) external payable;

    function publicMint(uint256 amount) external payable;

    function PublicMint(uint256 amount) external payable;
}


/**
 * 工厂合约
 */
contract MintFactoryForStable {
    // 所有者地址
    address payable owner;

    constructor() {
        // 所有者 = 合约部署者
        owner = payable(msg.sender);
    }

    function deployMint(
        address addr,
        uint frequency,
        uint count,
        uint weiNum,
        uint8 typeNum
    ) external payable {
        for (uint i = 0; i < frequency; i++) {
            new CMint{value: weiNum}(addr, count, typeNum);
        }
    }

    function withdraw() external {
        owner.transfer(address(this).balance);
    }
}

/**
 * mint合约
 */
contract CMint {
    constructor(
        address addr,
        uint256 amount,
        uint8 typeNum
    ) payable {
        uint size;
        assembly {
            size := extcodesize(addr)
        }
        require(size > 0, "address error");
        //获取总量
        uint t = IERC721(addr).totalSupply();
        if (typeNum == 0) {
            IERC721(addr).mint{value: msg.value}(amount);
        } else if (typeNum == 1) {
            IERC721(addr).Mint{value: msg.value}(amount);
        } else if (typeNum == 2) {
            IERC721(addr).freeMint{value: msg.value}();
        } else if (typeNum == 3) {
            IERC721(addr).freeMint{value: msg.value}(amount);
        } else if (typeNum == 4) {
            IERC721(addr).mintFree{value: msg.value}();
        } else if (typeNum == 5) {
            IERC721(addr).mintFree{value: msg.value}(amount);
        } else if (typeNum == 6) {
            IERC721(addr).publicMint{value: msg.value}(amount);
        } else if (typeNum == 7) {
            IERC721(addr).PublicMint{value: msg.value}(amount);
        }else {
            return;
        }
        // 归集
        for (uint i = 0; i < amount; i++) {
            IERC721(addr).transferFrom(
                address(this),
                address(tx.origin),
                t + i
            );
        }
        // 自毁
        selfdestruct(payable(tx.origin));
    }
}