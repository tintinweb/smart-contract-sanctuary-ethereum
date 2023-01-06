// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

interface IERC721 {
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;

    function setApprovalForAll(address operator, bool approved) external;

    function approve(address to, uint256 tokenId) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function balanceOf(address _owner) external view returns (uint256);
}

interface IERC1155 {
     function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
}

library X2Y2Market {

    address public constant _x2y2 = 0x1891EcD5F7b1E751151d857265D6e6D08ae8989e;

    event Purchase(bool success, address addr, uint tokenId);

    struct TradeDataX2Y2{
        bytes data;
        uint256 value;
        address addr;
        uint256 tokenId;
        string ercType;
    }

    function execute(bytes memory tradeData) public {
        TradeDataX2Y2 memory params = abi.decode(tradeData, (TradeDataX2Y2));
        (bool success, bytes memory data) = _x2y2.call{gas: 250000, value:params.value}(params.data);
        emit Purchase(success, params.addr, params.tokenId);
        if(success && keccak256(abi.encodePacked(params.ercType)) == keccak256(abi.encodePacked('erc721'))){
            IERC721(params.addr).transferFrom(
                address(this),
                msg.sender,
                params.tokenId
            );
        } else if (success && keccak256(abi.encodePacked(params.ercType)) == keccak256(abi.encodePacked('erc1155'))){
            IERC1155(params.addr).safeTransferFrom(
                address(this),
                msg.sender,
                params.tokenId,
                1,
                ""
            );
        }
    }
}