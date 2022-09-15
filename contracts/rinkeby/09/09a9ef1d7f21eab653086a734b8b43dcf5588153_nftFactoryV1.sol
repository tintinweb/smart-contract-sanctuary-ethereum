/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >0.8.0;

//没有完美的方法在合约种判断minted ID
//amountPerTime每次call的数量，转移用
//offset id偏移，一般为0
//如果mint过程中有burn的情况，那么totalSupply 需要加 offset才能计算出正确的tokenId

interface erc20 {
    function transfer(address recipient, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function claim() external;
}

interface nft {
    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;

    function approve(address _approved, uint256 _tokenId) external payable;

    function setApprovalForAll(address _operator, bool _approved) external;

    function getApproved(uint256 _tokenId) external view returns (address);

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);

    function totalSupply() external view returns (uint256);
}

contract nftFactoryV1 {
    address public _owner;
    mapping(address => bool) private whitelist;
    bool private isValidate = false;

    constructor() {
        _owner = msg.sender;
        whitelist[msg.sender] = true;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }
    modifier onlyWhitelist(address user) {
        if (isValidate) {
            require(whitelist[user]);
        }
        _;
    }

    receive() external payable {}

    fallback() external payable {}

    function registWhitelist(address user, bool valid) external onlyOwner {
        whitelist[user] = valid;
    }

    function setValidate(bool valid) external onlyOwner {
        isValidate = valid;
    }

    function isWhitelist(address user) external view returns (bool) {
        return whitelist[user];
    }

    function withdrawETH(address _recipient) external onlyOwner {
        payable(_recipient).transfer(address(this).balance);
    }

    function withdrawERC20(address _recipient, address erc20address)
        external
        onlyOwner
    {
        uint256 balance = erc20(erc20address).balanceOf(address(this));
        erc20(erc20address).transfer(_recipient, balance);
    }

    function selfDestruct(address _recipient) external onlyOwner {
        selfdestruct(payable(_recipient));
    }

    function batchTransfrom(
        uint256[] memory tokens,
        uint256[] memory schemas,
        address[] memory contracts,
        uint256[] memory amounts,
        address to
    ) public virtual onlyWhitelist(msg.sender) {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (schemas[i] == 1) {
                require(
                    this.CheckERC721Require(
                        contracts[i],
                        msg.sender,
                        tokens[i]
                    ),
                    "validate error"
                );
                this.ERC721TransferFrom(
                    contracts[i],
                    msg.sender,
                    to,
                    tokens[i]
                );
            } else {
                require(
                    this.CheckERC1155Require(
                        contracts[i],
                        msg.sender,
                        tokens[i],
                        amounts[i]
                    ),
                    "validate error"
                );
                this.ERC1155TransferFrom(
                    contracts[i],
                    msg.sender,
                    to,
                    tokens[i],
                    amounts[i]
                );
            }
        }
    }

    function ERC721TransferFrom(
        address addr,
        address _sender,
        address to,
        uint256 tokenId
    ) public virtual {
        ERC721 fountain = ERC721(addr);
        fountain.transferFrom(_sender, to, tokenId);
    }

    function ERC1155TransferFrom(
        address addr,
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) public virtual {
        ERC1155 fountain = ERC1155(addr);
        fountain.safeTransferFrom(from, to, id, amount, "0x");
    }

    function CheckERC721Require(
        address addr,
        address _sender,
        uint256 tokenId
    ) public view returns (bool) {
        ERC721 fountain = ERC721(addr);
        address ownerAddr = fountain.ownerOf(tokenId);
        bool isOwner = _sender == ownerAddr;
        bool result = fountain.isApprovedForAll(_sender, address(this));
        return result && isOwner;
    }

    function CheckERC1155Require(
        address addr,
        address _sender,
        uint256 tokenId,
        uint256 amount
    ) public view returns (bool) {
        ERC1155 fountain = ERC1155(addr);
        uint256 balance = fountain.balanceOf(_sender, tokenId);
        bool isEnough = balance >= amount;
        bool result = fountain.isApprovedForAll(_sender, address(this));
        return result && isEnough;
    }

    /**********************************************mint 不带地址 */

    //所有minter都mint至自己1个或amount个
    //mint()
    //mint(uint256 amount)
    //16进制打法s
    function dataCallSelf(
        address contra,
        bytes memory data,
        uint256 times,
        uint256 amountPerTime,
        uint256 offset
    ) external payable onlyWhitelist(msg.sender) {
        uint256 _value = msg.value / times;
        uint256 tokenId = nft(contra).totalSupply() + offset;
        for (uint256 i = 0; i < times; ++i) {
            try
                new nftMintData{value: _value}(
                    contra,
                    data,
                    amountPerTime,
                    tokenId
                )
            {
                tokenId += amountPerTime;
            } catch {
                break;
            }
        }
    }

    function dataCallSupply(
        address contra,
        bytes memory data,
        uint256 times,
        uint256 amountPerTime,
        uint256 totalSupply
    ) external payable onlyWhitelist(msg.sender) {
        uint256 _value = msg.value / times;
        uint256 tokenId;
        for (uint256 i = 1; i < totalSupply + 1; i++) {
            try nft(contra).ownerOf(i) {} catch {
                tokenId = i;
                break;
            }
        }
        for (uint256 i = 0; i < times; ++i) {
            try
                new nftMintData{value: _value}(
                    contra,
                    data,
                    amountPerTime,
                    tokenId
                )
            {
                tokenId += amountPerTime;
            } catch {
                break;
            }
        }
    }

    //所有minter都mint至自己默认1个
    //mint()
    //普通函数版
    function functionCallSelf(
        address contra,
        string calldata fun,
        uint256 times,
        uint256 offset
    ) external payable onlyWhitelist(msg.sender) {
        uint256 _value = msg.value / times;
        uint256 tokenId = nft(contra).totalSupply() + offset;
        bytes memory data = abi.encodeWithSignature(fun);
        for (uint256 i = 0; i < times; ++i) {
            try new nftMintData{value: _value}(contra, data, 1, tokenId) {
                ++tokenId;
            } catch {
                break;
            }
        }
    }

    //所有minter都mint至自己 amount个
    //mint(uint256 amount)
    //普通函数版
    function functionCallSelfWithAmount(
        address contra,
        string calldata fun,
        uint256 amountPerTime,
        uint256 times,
        uint256 offset
    ) external payable onlyWhitelist(msg.sender) {
        uint256 _value = msg.value / times;
        uint256 tokenId = nft(contra).totalSupply() + offset;
        bytes memory data = abi.encodeWithSignature(fun, amountPerTime);
        for (uint256 i = 0; i < times; ++i) {
            try
                new nftMintData{value: _value}(
                    contra,
                    data,
                    amountPerTime,
                    tokenId
                )
            {
                tokenId += amountPerTime;
            } catch {
                break;
            }
        }
    }

    /**********************************************mint 不带地址 */

    /**********************************************mint 带地址 */

    //mint(address to) 所有minter都mint至同一个地址默认1 个
    //A->X 1
    //B->X 1
    //C->X 1
    //16进制版
    function dataCallToOne1(
        address contra,
        bytes memory data,
        uint256 times
    ) external payable onlyWhitelist(msg.sender) {
        uint256 _value = msg.value / times;
        for (uint256 i = 0; i < times; ++i) {
            try new nftMintToData{value: _value}(contra, data) {} catch {
                break;
            }
        }
    }

    //mint(address to) 所有minter都mint至同一个地址默认1 个
    //A->X 1
    //B->X 1
    //C->X 1
    //普通函数版
    function dataCallToOne2(
        address contra,
        string calldata fun,
        address to,
        uint256 times
    ) external payable onlyWhitelist(msg.sender) {
        uint256 _value = msg.value / times;
        bytes memory data = abi.encodeWithSignature(fun, to);
        for (uint256 i = 0; i < times; ++i) {
            try new nftMintToData{value: _value}(contra, data) {} catch {
                break;
            }
        }
    }

    //mint(address self) 所有minter都mint至minter自己默认1 个
    //A->A->X 1
    //B->B->X 1
    //C->C->X 1
    //To 地址不一样所以无16进制版 只有普通函数
    function functionCallToSelf(
        address contra,
        string calldata fun,
        uint256 times,
        uint256 offset
    ) external payable onlyWhitelist(msg.sender) {
        uint256 _value = msg.value / times;
        uint256 tokenId = nft(contra).totalSupply() + offset;
        for (uint256 i = 0; i < times; ++i) {
            try new nftMintToSelf{value: _value}(contra, fun, 1, tokenId) {
                ++tokenId;
            } catch {
                break;
            }
        }
    }
}

/**********************************************mint 带地址 */

contract nftBase {
    modifier selfDestruct() {
        _;
        selfdestruct(payable(address(msg.sender)));
    }

    receive() external payable {}

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    //contra :操作的合约
    //data ： call data
    //owner : minter合约地址
    //amount : 当前 data 中 mint 的数量
    //startId : 启示tokenId
    function nftCallAndTransfer(
        address contra,
        bytes memory data,
        address owner,
        uint256 amount,
        uint256 startId
    ) internal {
        (bool rt, ) = payable(contra).call{value: msg.value}(data);
        require(rt);
        for (uint256 i = 0; i < amount; ++i) {
            nft(contra).transferFrom(owner, tx.origin, startId + i);
        }
    }
}

contract nftMintData is nftBase {
    constructor(
        address contra,
        bytes memory data,
        uint256 amount,
        uint256 startId
    ) payable selfDestruct {
        nftCallAndTransfer(contra, data, address(this), amount, startId);
    }
}

//直接mint至指定address
contract nftMintToData is nftBase {
    constructor(address contra, bytes memory data) payable selfDestruct {
        (bool rt, ) = payable(contra).call{value: msg.value}(data);
        require(rt);
    }
}

//mintto(address self)
contract nftMintToSelf is nftBase {
    constructor(
        address contra,
        string memory fun,
        uint256 amount,
        uint256 startId
    ) payable selfDestruct {
        nftCallAndTransfer(
            contra,
            abi.encodeWithSignature(fun, address(this)),
            address(this),
            amount,
            startId
        );
    }
}

contract ERC1155 {
    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        returns (uint256)
    {}

    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        returns (bool)
    {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {}
}

contract ERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {}

    function ownerOf(uint256 tokenId) public view virtual returns (address) {}

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        returns (bool)
    {}
}