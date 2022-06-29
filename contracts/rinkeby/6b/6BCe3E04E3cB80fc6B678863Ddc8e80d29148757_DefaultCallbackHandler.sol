// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "../interfaces/ERC1155TokenReceiver.sol";
import "../interfaces/ERC721TokenReceiver.sol";
import "../interfaces/ERC777TokensRecipient.sol";
import "../interfaces/IERC165.sol";

/// @title Default Callback Handler - returns true for known token callbacks
contract DefaultCallbackHandler is ERC1155TokenReceiver, ERC777TokensRecipient, ERC721TokenReceiver, IERC165 {
    string public constant NAME = "Default Callback Handler";
    string public constant VERSION = "1.0.0";

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0xbc197c81;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0x150b7a02;
    }

    function tokensReceived(
        address,
        address,
        address,
        uint256,
        bytes calldata,
        bytes calldata
    ) external pure override {
        // We implement this for completeness, doesn't really have any value
    }

    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return
            interfaceId == type(ERC1155TokenReceiver).interfaceId ||
            interfaceId == type(ERC721TokenReceiver).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/
interface ERC1155TokenReceiver {
    /** 
    @notice 处理单个 ERC1155 令牌类型的接收。 
    @dev 符合 ERC1155 的智能合约必须在余额更新后的“safeTransferFrom”结束时在代币接收者合约上调用此函数。
    如果该函数接受传输，则必须返回 `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`（即 0xf23a6e61）。
    如果拒绝传输，该函数必须恢复。返回除规定的 keccak256 生成值之外的任何其他值必须导致调用者恢复事务。 
    @param _operator 发起传输的地址（即 msg.sender） 
    @param _from 之前拥有代币的地址 
    @param _id 正在传输的代币的 ID 
    @param _value 正在传输的代币数量 
    @param _data 附加数据没有指定格式 
    @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` 
    */
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4);

    /** 
    @notice 处理多个 ERC1155 令牌类型的接收。 
    @dev 符合 ERC1155 的智能合约必须在余额更新后的“safeBatchTransferFrom”结束时在代币接收者合约上调用此函数。
    如果此函数接受传输，则必须返回 `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`（即 0xbc197c81）。
    如果拒绝传输，该函数必须恢复。返回除规定的 keccak256 生成值之外的任何其他值必须导致调用者恢复事务。 
    @param _operator 发起批量传输的地址（即 msg.sender） 
    @param _from 先前拥有令牌的地址 
    @param _ids 包含正在传输的每个令牌的 id 的数组（顺序和长度必须匹配 _values 数组） 
    @param _values包含正在传输的每个令牌数量的数组（顺序和长度必须与 _ids 数组匹配）
    @param _data 没有指定格式的附加数据 
    @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes )"))` 
    */
    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface ERC721TokenReceiver {
    /// @notice 处理 NFT 的收据
    /// @dev ERC721 智能合约在“转移”之后在接收者上调用此函数。此 函数可能会抛出以恢复和拒绝传输。魔术值以外的返回必须导致事务被还原。
    /// 注意：合约地址始终是消息发送者。
    /// @param _operator 调用 `safeTransferFrom` 函数的地址
    /// @param _from 先前拥有令牌的地址
    /// @param _tokenId 正在传输的 NFT 标识符
    /// @param _data 没有附加数据指定格式
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))` 除非抛出。
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

interface ERC777TokensRecipient {
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @notice More details at https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol
interface IERC165 {
    /**
    * @dev 如果此合约实现了由 `interfaceId` 定义的接口，则返回 true。
    * 
    * 此函数调用必须使用少于 30 000 个气体。 
    */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}