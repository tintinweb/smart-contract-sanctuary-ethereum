/**
 *Submitted for verification at Etherscan.io on 2022-04-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;
    string private _name;
    string private _symbol;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);
}

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < ERC721.balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );
        return _ownedTokens[owner][index];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < ERC721Enumerable.totalSupply(),
            "ERC721Enumerable: global index out of bounds"
        );
        return _allTokens[index];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
        private
    {
        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}


contract mfContract is ERC721Enumerable, Ownable {
    using Strings for uint256;

    //   using SafeMath for uint256;

    constructor() ERC721("TBC TBC", "TBC") {
        setBaseURI("TBC-baseuri");
        setNotRevealedURI("TBC-NotRevealedUri");
    }

    string baseURI;
    string public notRevealedUri;
    string public baseExtension = ".json";

    //首次白名单价，二次白名单价，开售价
    uint256 public firstWlCost = 100000000000000000000; //100 matic
    uint256 public secondWlCost = 130000000000000000000;
    uint256 public finalCost = 160000000000000000000;

    //时间设定
// 5/25號15:00 1653462000
// 5/26號18:00 1653559200
// 5/27號21:00 1653656400
// 5/27號21:30 1653658200
// 5/28號21:30 1653744600
// 5/30號18:00 1653904800

    uint256[] public roundTime = [
        1653462000,
        1653559200,
        1653656400,
        1653658200,
        1653744600,
        1653904800
    ];

    //發行總數量：3888，预铸300，布署后无法修改
    uint256 public maxSupply = 6969;
    uint256 public adminKeep = 300;

    //不重复随机指数
    uint256[] public indices = new uint256[](maxSupply - adminKeep);
    uint256 public indicesNonce;

    //每个钱包地址最大mint量，可修改
    uint256 public maxMintAmount = 6;

    //记录每个钱包mint几个了（排除官方钱包0x5809426f4700e104976BDA3a3547f85C292f091A）
    mapping(address => uint256) public accountAmount;

    //收款钱包，可修改
    address public payoutAddress = 0x5809426f4700e104976BDA3a3547f85C292f091A;

    //每个阶段可以铸造
    uint256[] public roundLimits = [
        adminKeep,
        adminKeep + 600,
        adminKeep + 1200,
        maxSupply
    ];

    //邀请人记录
    mapping(address => uint256) public refList;

    //uint256 public revealTokenId = 0;

    //白名单清单
    mapping(address => uint256) public firstWhiteListedUsers;
    mapping(address => uint256) public secondWhiteListedUsers;

    //TBC都是正式布署时要改的

    //销毁NFT（只有管理员且拥有该NFT时可执行）
    function burn(uint256 tokenId) public onlyOwner {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Not approved to burn."
        );
        _burn(tokenId);
    }

    //取随机不重复值 + 前面要保留多少号
    function randomIndex() private returns (uint256) {
        uint256 totalSize = maxSupply - adminKeep - indicesNonce;
        uint256 index = uint256(
            keccak256(
                abi.encodePacked(
                    indicesNonce,
                    blockhash(block.number - 1),
                    msg.sender,
                    block.difficulty,
                    block.timestamp
                )
            )
        ) % totalSize;
        uint256 value = 0;
        if (indices[index] != 0) {
            value = indices[index];
        } else {
            value = index;
        }

        if (indices[totalSize - 1] == 0) {
            indices[index] = totalSize - 1;
        } else {
            indices[index] = indices[totalSize - 1];
        }
        indicesNonce++;
        return value + adminKeep + 1;
    }

    // internal显示baseURI（metadata位置）
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //检查该地址能不能铸造
    modifier isAllowed(address _address) {
        //如果已经铸造过就不能铸造了
        require(accountAmount[_address] == 0, "Eachone only mint once");
        //在第一份白名单中的检查时间
        if (firstWhiteListedUsers[_address] != 0) {
            require(
                block.timestamp >= roundTime[1] &&
                    block.timestamp <= roundTime[2],
                "Not yet for mint"
            );
        }

        //在第二份白名单中的检查时间
        if (secondWhiteListedUsers[_address] != 0) {
            require(
                block.timestamp >= roundTime[3] &&
                    block.timestamp <= roundTime[4],
                "Not yet for mint"
            );
        }
        //不在白名单中的检查时间
        if (
            firstWhiteListedUsers[_address] == 0 &&
            secondWhiteListedUsers[_address] == 0
        ) {
            require(block.timestamp >= roundTime[5], "Not yet on sale");
        }
        _;
    }

    //铸造
    function mint(uint256 _mintAmount, address _ref)
        public
        payable
        isAllowed(msg.sender)
    {
        uint256 supply = totalSupply();

        //检查输入数量大于0
        require(_mintAmount > 0, "MintAmount must be above 0");

        //检查该地址mint总量不能超过max
        require(
            _mintAmount <= maxMintAmount,
            "MintAmount must be below or equal to maxMintAmount"
        );

        //检查铸造量加上当前量不能超过总供量
        require(
            supply + _mintAmount <= maxSupply,
            "MintAmount is more then the MaxSupply"
        );

        //非管理员的数字量检查
        if (msg.sender != owner()) {
            //如果现在是第一批白名单时间
            if (
                block.timestamp >= roundTime[1] &&
                block.timestamp <= roundTime[2]
            ) {
                require(
                    supply + _mintAmount <= roundLimits[1],
                    "MintAmount must be less then preSale supply"
                );
                require(
                    msg.value >= firstWlCost * _mintAmount,
                    "Not enough ETH"
                );
            }

            //如果现在是第二批白名单时间
            if (
                block.timestamp >= roundTime[3] &&
                block.timestamp <= roundTime[4]
            ) {
                require(
                    supply + _mintAmount <= roundLimits[2],
                    "MintAmount must be less then preSale supply"
                );
                require(
                    msg.value >= secondWlCost * _mintAmount,
                    "Not enough ETH"
                );
            }
            //如果现在是开售时间
            if (block.timestamp >= roundTime[5]) {
                require(
                    supply + _mintAmount <= maxSupply,
                    "MintAmount must be less then total supply"
                );
                require(msg.value >= finalCost * _mintAmount, "Not enough ETH");
            }
        }

        //开始铸造
        for (uint256 i = 1; i <= _mintAmount; i++) {
            if (firstWhiteListedUsers[msg.sender] > 0) {
                firstWhiteListedUsers[msg.sender] -= 1;
            }
            if (secondWhiteListedUsers[msg.sender] > 0) {
                secondWhiteListedUsers[msg.sender] -= 1;
            }
            uint256 _id = randomIndex();
            _safeMint(msg.sender, _id);
        }

        //记录每个钱包地址铸造了几个，并限制之后不能铸造
        accountAmount[msg.sender] = _mintAmount;
        //记录邀请码完成多少交易
        refList[_ref] += msg.value;
    }

    //显示用户的NFT清单
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    //V取得metadata
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        //如果还没mint显示notRevealedUri
        if (tokenId <= 3888 && !_exists(tokenId)) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    //官方预铸，可指定给某个地址，数量受到adminKeep限制
    function mintForGiveaway(address _to, uint256 _mintAmount)
        public
        onlyOwner
    {
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= adminKeep);
        if (msg.sender == owner()) {
            for (uint256 i = 1; i <= _mintAmount; i++) {
                _safeMint(_to, supply + i);
            }
        }
    }

    //添加白名单
    function addUsersToFirstWhiteListedUsers(address[] calldata _addresses)
        public
        onlyOwner
    {
        require(_addresses.length > 0, "No white list address given");
        for (uint256 i = 0; i < _addresses.length; i++) {
            firstWhiteListedUsers[_addresses[i]] = 6;
        }
    }

    //添加第二轮白名单+检查有没有跟第一轮重复
    function addUsersToSecondWhiteListedUsers(address[] calldata _addresses)
        public
        onlyOwner
    {
        require(_addresses.length > 0, "No white list address given");
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (
                firstWhiteListedUsers[_addresses[i]] == 0 &&
                accountAmount[_addresses[i]] == 0
            ) {
                secondWhiteListedUsers[_addresses[i]] = 6;
            }
        }
    }

    // function setRevealTokenId(uint256 _revealTokenId) public onlyOwner {
    //     revealTokenId = _revealTokenId;
    // }

    //设定firstWlCost 首次白名单价格（wei）
    function setCostFirstWlCost(uint256 _newCost) public onlyOwner {
        firstWlCost = _newCost;
    }

    //secondWlCost
    function setCostSecondWlCost(uint256 _newCost) public onlyOwner {
        secondWlCost = _newCost;
    }

    //finalCost
    function setCostFinalCost(uint256 _newCost) public onlyOwner {
        finalCost = _newCost;
    }

    //设定四个时间点
    function setRoundTime(uint256 _roundTime, uint256 _roundIndex)
        public
        onlyOwner
    {
        require(
            _roundIndex < roundTime.length,
            "Round index should < rounds size"
        );
        roundTime[_roundIndex] = _roundTime;
    }

    //设定每一个阶段的数量
    function setRoundLimit(uint256 _roundLimit, uint256 _roundIndex)
        public
        onlyOwner
    {
        require(
            _roundIndex < roundLimits.length,
            "Round index should < rounds size"
        );
        roundLimits[_roundIndex] = _roundLimit;
    }

    //设定每个人最高可以铸造多少个
    function setMaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    //设定未mint出的metadata
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    //设定已mint出的metadata
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    //设定metadata副档名
    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    //修改收款人
    function setPayoutAddress(address _payoutAddress) public onlyOwner {
        payoutAddress = _payoutAddress;
    }

    //收款提出
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(payoutAddress).transfer(balance);
    }

    //一次发多个NFT给某一钱包
    function multiSendSpecTokenToAddress(address _to, uint256[] memory _ids)
        public
        returns (uint256)
    {
        uint256 i = 0;
        while (i < _ids.length) {
            if (ownerOf(_ids[i]) == msg.sender) {
                transferFrom(msg.sender, _to, _ids[i]);
            }
            i += 1;
        }
        return (i);
    }

    //一次发多个NFT给多个钱包
    function multiSendSpecTokenToSpecAddress(
        address[] memory _to,
        uint256[][] memory _ids
    ) public returns (uint256) {
        uint256 i = 0;
        while (i < _to.length) {
            multiSendSpecTokenToAddress(_to[i], _ids[i]);
            i += 1;
        }
        return (i);
    }
}