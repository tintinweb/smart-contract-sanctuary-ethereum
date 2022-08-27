//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IPML {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract PixelsMetaverseLandPawnshop {
    uint256 private _price = 1;
    address public pml;
    address public owner;
    
    modifier lock() {
        require(_price == 1, "LOCKED");
        _price = 102_400_000_000_000_000;
        _;
        _price = 1;
    }

    constructor(address _owner) payable {
        owner = _owner;
    }

    function setPML(address _pml) public {
        require(owner == msg.sender);
        require(pml == address(0));
        pml = _pml;
    }

    function _safeTransferETH(address to, uint256 value) private {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
        //payable(to).transfer(value);
    }

    function redeem(address to, uint256[] memory ids) external lock {
        uint256 len = ids.length;
        for (uint256 i; i < len; ) {
            IPML(pml).transferFrom(msg.sender, address(this), ids[i]);
            unchecked {
                ++i;
            }
        }
        uint256 total;
        unchecked {
            total = len * 10**17;
        }
        _safeTransferETH(to, total);
    }

    function claim(address to, uint256[] memory ids) external payable lock {
        uint256 len = ids.length;
        uint256 total;
        unchecked {
            total = _price * len;
        }
        require(msg.value == total, "The quantity needed is inconsistent with the quantity transferred");
        for (uint256 i; i < len; ) {
            IPML(pml).transferFrom(address(this), to, ids[i]);
            unchecked {
                ++i;
            }
        }
    }

    function withdraw() external lock {
        // require(
        //     block.timestamp > 1665110837,
        //     "You don't have permission to do it"
        // );
        _safeTransferETH(owner, address(this).balance);
    }

    receive() external payable {}
}