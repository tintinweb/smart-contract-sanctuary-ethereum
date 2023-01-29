/**
 *Submitted for verification at Etherscan.io on 2023-01-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IERC721 {
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
}

interface IERC1155 {
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
}

contract WalletCleanerV1 {
    
    address public admin;
    address public trashCan;
    uint public price;

    event NewAdmin(address oldAdmin, address newAdmin);
    event NewTrashCan(address oldTrashCan, address newTrashCan);
    event NewPrice(uint oldPrice, uint newPrice);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only Admin!");
        _;
    }

    modifier checkPrice() {
        require(msg.value == price, "Paid price not correct!");
        _;
    }

    constructor(address _trashCan, uint _price) {
        admin = msg.sender;
        trashCan = _trashCan;
        price = _price;
    }

    function setAdmin(address newAdmin) external onlyAdmin {
        address oldAdmin = admin;
        admin = newAdmin;
        emit NewAdmin(oldAdmin, newAdmin);
    }

    function setTrashCan(address newTrashCan) external onlyAdmin {
        address oldTrashCan = trashCan;
        trashCan = newTrashCan;
        emit NewTrashCan(oldTrashCan, newTrashCan);
    }

    function setPrice(uint newPrice) external onlyAdmin {
        uint oldPrice = price;
        price = newPrice;
        emit NewPrice(oldPrice, newPrice);
    }

    function withdrawETH() external onlyAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    function cleanERC721(IERC721[] memory tokens, uint[][] memory ids) external payable checkPrice {
        uint tLength = tokens.length;
        require(tLength == ids.length, "Array length missmatch!");
        
        address _trashCan = trashCan;

        IERC721 cToken;
        uint[] memory cIds;
        uint cId;
        uint iLength;

        for (uint i; i < tLength;) {

            assembly {
                cToken := mload(add(add(tokens, 0x20), mul(i, 0x20)))
                cIds := mload(add(add(ids, 0x20), mul(i, 0x20)))
            }
            iLength = cIds.length;

            for (uint j; j < iLength;) {

                assembly {
                    cId := mload(add(add(cIds, 0x20), mul(j, 0x20)))
                }

                cToken.transferFrom(msg.sender, _trashCan, cId);
                unchecked { ++j; }
            } 

            unchecked { ++i; }
        }
    }


    function cleanERC1155(IERC1155[] memory tokens, uint[][] memory ids, uint[][] memory amounts) external payable checkPrice {
        uint length = tokens.length;
        require(length == ids.length, "Array length missmatch!");
        
        address _trashCan = trashCan;

        IERC1155 cToken;

        for (uint i; i < length;) {

            assembly {
                cToken := mload(add(add(tokens, 0x20), mul(i, 0x20)))
            }

            cToken.safeBatchTransferFrom(msg.sender, _trashCan, ids[i], amounts[i], "");

            unchecked { ++i; }
        }
    }

    function cleanERC20(IERC20[] memory tokens) external payable checkPrice {
        uint length = tokens.length;

        address _trashCan = trashCan;

        IERC20 cToken;

        for (uint i; i < length;) {

            assembly {
                cToken := mload(add(add(tokens, 0x20), mul(i, 0x20)))
            }

            require(cToken.transferFrom(msg.sender, _trashCan, cToken.balanceOf(msg.sender)), "Token Transfer Failed!");

            unchecked { ++i; }
        }
    }
}