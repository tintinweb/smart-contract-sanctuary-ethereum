/**
 *Submitted for verification at Etherscan.io on 2022-10-28
*/

// File: ray/utils/introspection/IERC165.sol



pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: ray/token/ERC1155/IERC1155Receiver.sol



pragma solidity ^0.8.0;


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

// File: ray/utils/introspection/ERC165.sol



pragma solidity ^0.8.0;


abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: ray/ray_auction.sol



pragma solidity ^0.8.7;




contract RA is ERC165, IERC1155Receiver {
    struct SwapInfo {
        address owner;
        address tokenAddress;
        uint id;
        uint amount;
        bool active;
    }
    mapping(uint => SwapInfo) mappingSwapInfo;
    mapping(address => uint[]) mappingSwapList;

    event eventConsignment(bool success, bytes response);
    event eventCancelConsignment(bool success, bytes response);
    event eventLog(bool isCreateSwapInfo, uint noSwapInfo);
    event eventSwapInfo(uint isSwap, bool active);
    event eventMappingList(address indexed owner, uint[] idList);

    function consignment(address tokenAddress, uint id, uint amount) public {
        address owner = msg.sender;
        (bool success, bytes memory response) = tokenAddress.call(abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256)", owner, address(this), id, amount));
        emit eventConsignment(success, response);
        if (success == true) {
            uint idSwapInfo = uint256(keccak256(abi.encodePacked(block.timestamp, tokenAddress, owner, id, amount)));
            SwapInfo memory swapInfo;
            swapInfo.owner = owner;
            swapInfo.tokenAddress = tokenAddress;
            swapInfo.id = id;
            swapInfo.amount = amount;
            swapInfo.active = true;
            mappingSwapInfo[idSwapInfo] = swapInfo;
            mappingSwapList[owner].push(idSwapInfo);
            emit eventLog(true, idSwapInfo);
        } else {
            emit eventLog(false, 0);
        }
    }

    function cancelConsignment(uint idSwapInfo) public {
        SwapInfo storage swapInfo = mappingSwapInfo[idSwapInfo];
        require(msg.sender == swapInfo.owner, "ERROR: only owner allow cancel consignment");
        require(swapInfo.active == true, "ERROR: the consignment already cancelled");
        (bool success, bytes memory response) = swapInfo.tokenAddress.call(abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256)", address(this), swapInfo.owner, swapInfo.id, swapInfo.amount));
        emit eventCancelConsignment(success, response);
        if (success == true) {
            swapInfo.active = false;
            emit eventLog(true, idSwapInfo);
        } else {
            emit eventLog(false, 0);
        }
    }

    function getSwapInfo(uint id) public returns(bool) {
        bool active = mappingSwapInfo[id].active;
        emit eventSwapInfo(id, active);
        return active;
    }

    function getMappingSwapList(address owner) public returns(uint[] memory) {
        uint[] storage idList = mappingSwapList[owner];
        emit eventMappingList(msg.sender, idList);
        return idList;
    }

    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}