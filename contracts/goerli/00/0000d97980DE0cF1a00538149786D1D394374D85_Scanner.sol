// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./base.sol";
import "./interface/IERC20.sol";
import "./interface/IERC721.sol";
import "./interface/IERC1155.sol";

contract Scanner is Base {

    function batchERC20Assets (address owner, address[] calldata tokens) external view returns (uint256[] memory) {
        uint256 tokenLength = tokens.length;
        uint256[] memory balances = new uint256[](tokenLength);
        for (uint256 i = 0; i < tokenLength; i++) {
            balances[i] = IERC20(tokens[i]).balanceOf(owner);
        }
        return balances;
    }

    function batchERC20Allowances (address owner, address spender, address[] calldata tokens) external view returns (uint256[] memory) {
        uint256 tokenLength = tokens.length;
        uint256[] memory allowances = new uint256[](tokenLength);
        for (uint256 i = 0; i < tokenLength; i++) {
            allowances[i] = IERC20(tokens[i]).allowance(owner, spender);
        }
        return allowances;
    }

    function batchERC721AssetsConcisely(address[] calldata owners, address[] calldata tokens) external view returns (uint256[][] memory) {
        uint256 tokenLength = tokens.length;
        uint256[][] memory assets = new uint256[][](tokenLength);
        for (uint256 i = 0; i < tokenLength; i++){
            assets[i] = erc721TokensOfOwnerConcisely(owners[i], tokens[i]);
        }
        return assets;
    }

    function batchERC721Assets(address[] calldata owners, address[] calldata tokens, uint256[] calldata startIds, uint256[] calldata endIds) external view returns (uint256[][] memory) {
        uint256 tokenLength = tokens.length;
        uint256[][] memory assets = new uint256[][](tokenLength);
        for (uint256 i = 0; i < tokenLength; i++){
            assets[i] = erc721TokensOfOwner(owners[i], tokens[i], startIds[i], endIds[i]);
        }
        return assets;
    }

    function batchCheckERC721Owner(address[] memory owners, address[] memory tokens, uint256[][] calldata idses) public view returns (bool[][] memory) {
        uint256 tokenLength = tokens.length;
        bool[][] memory isOwners = new bool[][](tokenLength);
        for (uint256 i = 0; i < tokenLength; i++){
            isOwners[i] = checkERC721Owner(owners[i], tokens[i], idses[i]);
        }
        return isOwners;
    }

    function checkERC721Owner(address owner_, address token_, uint256[] calldata ids) public view returns (bool[] memory) {
        uint256 idLength = ids.length;
        bool[] memory isOwner = new bool[](idLength);
        for (uint256 i = 0; i < idLength; i++) {
            (bool success, bytes memory returnBytes) = token_.staticcall(abi.encodeWithSignature("ownerOf(uint256)", i));
            if (success) {
                address _owner = abi.decode(returnBytes, (address));
                if (_owner == owner_) {
                    isOwner[i] = true;
                }
            }
        }
        return isOwner;
    }

    function batchERC1155Assets(address[] calldata owners, address[] calldata tokens, uint256[][] calldata idses) external view returns (uint256[][] memory) {
        uint256 tokenLength = tokens.length;
        uint256[][] memory assets = new uint256[][](tokenLength);
        for (uint256 i = 0; i < tokenLength; i++){
            assets[i] = erc1155TokensOfOwner(owners[i], tokens[i], idses[i]);
        }
        return assets;
    }

    function erc721TokensOfOwner(address owner, address token, uint256 startId, uint256 endId) public view returns (uint256[] memory) {
        uint256 tokenIdsIdx;
        uint256 tokenIdsLength = IERC721(token).balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenIdsLength);
        for (uint256 i = startId; i <= endId; i++) {
            (bool success, bytes memory returnBytes) = token.staticcall(abi.encodeWithSignature("ownerOf(uint256)", i));
            if (success) {
                address _owner = abi.decode(returnBytes, (address));
                if (_owner == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
        }
        uint256[] memory rets = new uint256[](tokenIdsIdx);
        for (uint256 i = 0; i < tokenIdsIdx; i++) {
            rets[i] = tokenIds[i];
        }
        return rets;
    }

    function erc721TokensOfOwnerConcisely(address owner, address token) public view returns (uint256[] memory) {
        (bool success, bytes memory returnBytes) = token.staticcall(abi.encodeWithSignature("totalSupply()"));
        uint256 total = 50000;
        if (success) {
            total = abi.decode(returnBytes, (uint256));
            total += 10;
        }
        return erc721TokensOfOwner(owner, token, 0, total);
    }

    function erc1155TokensOfOwner(address owner, address token, uint256[] calldata ids) public view returns (uint256[] memory) {
        uint256 tokenIdsLength = ids.length;
        uint256[] memory balances = new uint256[](tokenIdsLength);
        for (uint256 i = 0; i < tokenIdsLength; i++) {
            balances[i] = 0;
            (bool success, bytes memory returnBytes) = token.staticcall(abi.encodeWithSignature("balanceOf(address,uint256)", owner, ids[i]));
            if (success) {
                balances[i] = abi.decode(returnBytes, (uint256));
            }
        }
        return balances;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

interface IERC1155Receiver is IERC165 {

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

interface IERC1155 is IERC165 {

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./interface/IERC721Receiver.sol";
import "./interface/IERC1155Receiver.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Base is Context {
    mapping(address => bool) private _owners;
    constructor() {
        _addOwnership(_msgSender());
    }
    
    modifier onlyOwner() {
        require(owner(_msgSender()), "caller is not the owner");
        _;
    }

    function owner(address account) public view virtual returns (bool) {
        return _owners[account];
    }

    function _addOwnership(address newOwner) internal virtual {
        require(newOwner != address(0), "new owner is the zero address");
        _owners[newOwner] = true;
    }

    function addOwnership(address newOwner) public virtual onlyOwner {
        _addOwnership(newOwner);
    }

    function revertOwnership(address owner_) public virtual onlyOwner {
        require(owner(owner_), "not owner");
        _owners[owner_] = false;
    }

    function multiCall(bytes[] calldata data) payable external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = _functionDelegateCall(address(this), data[i], "low-level delegate call failed");
        }
        return results;
    }

    function multiStaticCall(address[] memory targets,bytes[] calldata data) view external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = functionStaticCall(targets[i], data[i], "low-level delegate call failed");
        }
        return results;
    }

    function sendValue(address payable recipient, uint256 amount) payable public virtual onlyOwner {
        require(address(this).balance >= amount, "insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "unable to send value, recipient may have reverted");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) public payable virtual onlyOwner returns (bytes memory) {
        require(address(this).balance >= value, "insufficient balance for call");
        require(isContract(target), "call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) public virtual view returns (bytes memory) {
        require(isContract(target), "static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function multiCallIgnoreRevert(bytes[] calldata data) payable external virtual returns (bool[] memory results) {
        results = new bool[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = _functionDelegateCallIgnoreRevert(address(this), data[i]);
        }
        return results;
    }

    function _functionDelegateCallIgnoreRevert(
        address target,
        bytes memory data
    ) internal virtual returns (bool) {
        require(isContract(target), "delegate call to non-contract");
        (bool success, ) = target.delegatecall(data);
        return success;
    }    

    function _functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal virtual returns (bytes memory) {
        require(isContract(target), "delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) public virtual onlyOwner returns (bytes memory) {
        return _functionDelegateCall(target, data, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    modifier notContract() {
        require(!isContract(msg.sender), "Contract not allowed");
        _;
    }

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    receive() external virtual payable {}

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure virtual returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure virtual returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure virtual returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }
}