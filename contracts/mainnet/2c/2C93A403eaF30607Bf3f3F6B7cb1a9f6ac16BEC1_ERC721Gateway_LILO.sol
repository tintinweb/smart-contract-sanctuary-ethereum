// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

interface IAnycallV6Proxy {
    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID,
        uint256 _flags
    ) external payable;

    function executor() external view returns (address);
}

interface IExecutor {
    function context() external returns (address from, uint256 fromChainID, uint256 nonce);
}

contract Administrable {
    address public admin;
    address public pendingAdmin;
    event LogSetAdmin(address admin);
    event LogTransferAdmin(address oldadmin, address newadmin);
    event LogAcceptAdmin(address admin);

    function setAdmin(address admin_) internal {
        admin = admin_;
        emit LogSetAdmin(admin_);
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        address oldAdmin = pendingAdmin;
        pendingAdmin = newAdmin;
        emit LogTransferAdmin(oldAdmin, newAdmin);
    }

    function acceptAdmin() external {
        require(msg.sender == pendingAdmin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
        emit LogAcceptAdmin(admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
}

abstract contract AnyCallApp is Administrable {
    uint256 public flag; // 0: pay on dest chain, 2: pay on source chain
    address public anyCallProxy;

    mapping(uint256 => address) public peer;

    modifier onlyExecutor() {
        require(msg.sender == IAnycallV6Proxy(anyCallProxy).executor());
        _;
    }

    constructor (address anyCallProxy_, uint256 flag_) {
        anyCallProxy = anyCallProxy_;
        flag = flag_;
    }

    function setPeers(uint256[] memory chainIDs, address[] memory  peers) public onlyAdmin {
        for (uint i = 0; i < chainIDs.length; i++) {
            peer[chainIDs[i]] = peers[i];
        }
    }

    function setAnyCallProxy(address proxy) public onlyAdmin {
        anyCallProxy = proxy;
    }

    function _anyExecute(uint256 fromChainID, bytes calldata data) internal virtual returns (bool success, bytes memory result);

    function _anyFallback(bytes calldata data) internal virtual;

    function _anyCall(address _to, bytes memory _data, address _fallback, uint256 _toChainID) internal {
        if (flag == 2) {
            IAnycallV6Proxy(anyCallProxy).anyCall{value: msg.value}(_to, _data, _fallback, _toChainID, flag);
        } else {
            IAnycallV6Proxy(anyCallProxy).anyCall(_to, _data, _fallback, _toChainID, flag);
        }
    }

    function anyExecute(bytes calldata data) external onlyExecutor returns (bool success, bytes memory result) {
        (address callFrom, uint256 fromChainID,) = IExecutor(IAnycallV6Proxy(anyCallProxy).executor()).context();
        require(peer[fromChainID] == callFrom, "call not allowed");
        _anyExecute(fromChainID, data);
    }

    function anyFallback(address to, bytes calldata data) external onlyExecutor {
        (address callFrom, ,) = IExecutor(IAnycallV6Proxy(anyCallProxy).executor()).context();
        require(address(this) == callFrom, "call not allowed");
        _anyFallback(data);
    }
}

// interface of ERC20Gateway
interface IERC721Gateway {
    function token() external view returns (address);
    function Swapout(uint256 tokenId, address receiver, uint256 toChainID) external payable returns (uint256 swapoutSeq);
    function Swapout_no_fallback(uint256 tokenId, address receiver, uint256 toChainID) external payable returns (uint256 swapoutSeq);
}

abstract contract ERC721Gateway is IERC721Gateway, AnyCallApp {
    address override public token;
    uint256 public swapoutSeq;

    constructor (address anyCallProxy, uint256 flag, address token_) AnyCallApp(anyCallProxy, flag) {
        setAdmin(msg.sender);
        token = token_;
    }

    function _swapout(uint256 tokenId, uint256 chainID) internal virtual returns (bool, bytes memory);
    function _swapin(uint256 tokenId, address receiver, bytes memory extraMsg) internal virtual returns (bool);
    function _swapoutFallback(uint256 tokenId, address sender, uint256 swapoutSeq, bytes memory extraMsg) internal virtual returns (bool);

    event LogAnySwapOut(uint256 tokenId, address sender, address receiver, uint256 toChainID, uint256 swapoutSeq);

    function Swapout(uint256 tokenId, address receiver, uint256 destChainID) override external payable returns (uint256) {
        (bool ok, bytes memory extraMsg) = _swapout(tokenId, destChainID);
        require(ok);
        swapoutSeq++;
        bytes memory data = abi.encode(tokenId, msg.sender, receiver, swapoutSeq, extraMsg);
        _anyCall(peer[destChainID], data, address(this), destChainID);
        emit LogAnySwapOut(tokenId, msg.sender, receiver, destChainID, swapoutSeq);
        return swapoutSeq;
    }

    function Swapout_no_fallback(uint256 tokenId, address receiver, uint256 destChainID) override external payable returns (uint256) {
        (bool ok, bytes memory extraMsg) = _swapout(tokenId, destChainID);
        require(ok);
        swapoutSeq++;
        bytes memory data = abi.encode(tokenId, msg.sender, receiver, swapoutSeq, extraMsg);
        _anyCall(peer[destChainID], data, address(0), destChainID);
        emit LogAnySwapOut(tokenId, msg.sender, receiver, destChainID, swapoutSeq);
        return swapoutSeq;
    }

    function _anyExecute(uint256 fromChainID, bytes calldata data) internal override returns (bool success, bytes memory result) {
        (uint256 tokenId, , address receiver,,bytes memory extraMsg) = abi.decode(
            data,
            (uint256, address, address, uint256, bytes)
        );
        require(_swapin(tokenId, receiver, extraMsg));
    }

    function _anyFallback(bytes calldata data) internal override {
        (uint256 tokenId, address sender, , uint256 swapoutSeq, bytes memory extraMsg) = abi.decode(
            data,
            (uint256, address, address, uint256, bytes)
        );
        require(_swapoutFallback(tokenId, sender, swapoutSeq, extraMsg));
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function mint(address account, uint256 tokenId) external;
    function burn(uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IGatewayClient {
    function notifySwapoutFallback(bool refundSuccess, uint256 tokenId, uint256 swapoutSeq) external returns (bool);
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC721Gateway_LILO is ERC721Gateway, IERC721Receiver {
    using Address for address;
    // swapin cost 40000 gas on dest chain
    // suggest price = 40000 * dst gas price * dst gas token price / src gas token price + margin
    mapping(uint256 => uint256) public priceTable; // chainID -> price (wei)

    function setPrice(uint256 chainID, uint256 price) external onlyAdmin {
        priceTable[chainID] = price;
    }

    function withdrawFee(address to, uint256 amount) external onlyAdmin {
        require(to.code.length == 0);
        (bool success,) = to.call{value: amount}("");
        require(success);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) override external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    constructor (address anyCallProxy, address token) ERC721Gateway(anyCallProxy, 2, token) onlyAdmin {
    }

    function _swapout(uint256 tokenId, uint256 chainID) internal override virtual returns (bool, bytes memory) {
        require(msg.value >= priceTable[chainID]);
        try IERC721(token).safeTransferFrom(msg.sender, address(this), tokenId) {
            return (true, "");
        } catch {
            return (false, "");
        }
    }

    function _swapin(uint256 tokenId, address receiver, bytes memory extraMsg) internal override returns (bool) {
        try IERC721(token).safeTransferFrom(address(this), receiver, tokenId) {
            return true;
        } catch {
            return false;
        }
    }
    
    function _swapoutFallback(uint256 tokenId, address sender, uint256 swapoutSeq, bytes memory extraMsg) internal override returns (bool result) {
        try IERC721(token).safeTransferFrom(address(this), sender, tokenId)  {
            result = true;
        } catch {
            result = false;
        }
        if (sender.isContract()) {
            bytes memory _data = abi.encodeWithSelector(IGatewayClient.notifySwapoutFallback.selector, result, tokenId, swapoutSeq);
            sender.call(_data);
        }
        return result;
    }
}