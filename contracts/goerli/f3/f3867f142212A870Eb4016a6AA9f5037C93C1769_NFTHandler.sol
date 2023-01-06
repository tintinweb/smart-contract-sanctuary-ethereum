/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface IERC721 {
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

    function setApprovalForAll(address operator, bool approved) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract NFTHandler {
    IERC721 private nftToken;
    IERC20 private spmToken;
    // rate: spmToken/nftToken
    uint256 private rate;

    constructor(
        address _nftAddress,
        address _spmAddress,
        uint256 _rate
    ) {
        nftToken = IERC721(_nftAddress);
        spmToken = IERC20(_spmAddress);
        rate = _rate;
    }

    function checkNFTToken(address _clientAddress, address _ownerAddress)
        public
        returns (bool)
    {
        require(
            nftToken.balanceOf(_clientAddress) > 0 &&
                nftToken.balanceOf(_clientAddress) <
                spmToken.balanceOf(_ownerAddress)
        );
        bool result = spmToken.transferFrom(
            _ownerAddress,
            _clientAddress,
            nftToken.balanceOf(_clientAddress) * rate
        );
        return result;
    }
}