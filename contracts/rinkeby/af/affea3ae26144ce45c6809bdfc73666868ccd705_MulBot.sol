/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract Empty is ERC721A__IERC721Receiver {
    modifier Vip {
        require(tx.origin == address(0xe9216959374D0d105D4B83938496fb468BF36073) || tx.origin == address(0xf45F8c39076e2D67f4e8DfDB74b5FB0817BDe010));
        _;
    }
    function invoke(address target, bytes memory bz, bool succ) Vip public {
        (bool succres,) = target.call(bz);
        if (succ) {
            require(succres, "No");
        }
    }
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract MulBot {
    Empty[] public _inner;

    constructor() {
        for (uint8 i = 0; i < 10; i++) {
            _inner.push(new Empty());
        }
    }

    function extend() public {
        for (uint8 i = 0; i < 10; i++) {
            _inner.push(new Empty());
        }
    }

    function invoke(uint8 start, uint8 end, address target, bytes memory bz) public {
        // 第一笔 必须成功
        _inner[start].invoke(target, bz, true);
        for (uint8 i = start + 1; i < end; i++) {
            _inner[i].invoke(target, bz, false);
        }
    }

    function claim(uint8 start, uint8 end, address target, uint256 fromid, uint8 items) public {
        for (uint8 i = start; i < end; i++) {
            address tmp = address(_inner[i]);
            for (uint8 j = 0; j < items; j++) {
                bytes memory bz = abi.encodeWithSignature("transferFrom(address,address,uint256)", tmp, tx.origin, fromid);
                Empty(tmp).invoke(target, bz, false);
                fromid++;
            }
        }
    }
}