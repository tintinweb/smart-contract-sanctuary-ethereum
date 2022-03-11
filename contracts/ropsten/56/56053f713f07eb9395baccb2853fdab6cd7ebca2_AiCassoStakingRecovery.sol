// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './Ownable.sol';
import './Strings.sol';
import './IAiCasso.sol';
import './IERC721Enumerable.sol';
import './IAiCassoNFTStaking.sol';
import './ERC721Receiver.sol';


contract AiCassoStakingRecovery is Ownable, ERC721Receiver {
    using Strings for uint256;

    address public immutable AiCassoNFT;
    address public immutable AiCassoNFTStaking;

    mapping(address => uint256) private recovered;
    mapping(address => uint256) private to_recovered;

    constructor (
        address _AiCassoNFT,
        address _AiCassoNFTStaking
    ) {
        require( _AiCassoNFT != address(0) );
        AiCassoNFT = _AiCassoNFT;
        require( _AiCassoNFTStaking != address(0) );
        AiCassoNFTStaking = _AiCassoNFTStaking;
    }


    function prepare(uint256 numberOfTokens) external {
        uint256 _balance = IAiCassoNFTStaking( AiCassoNFTStaking ).balanceOf(msg.sender);
        require(numberOfTokens <= _balance);
        uint256 _available = _balance - recovered[msg.sender];
        require(numberOfTokens <= _available, "you dont have available nft on stake contract");
        require(address(this).balance >= (numberOfTokens * 0.01 ether), "need more avax on balance recovery contract");

        recovered[msg.sender] += numberOfTokens;
        to_recovered[msg.sender] += numberOfTokens;

        if (numberOfTokens <= 10) {
            IAiCasso( AiCassoNFT ).purchase{value: numberOfTokens * 0.01 ether}(numberOfTokens);
        } else {

            uint256 loops = numberOfTokens / 10;
            uint256 other = (loops * 10) - numberOfTokens;

            require((loops * 10) + other == numberOfTokens, "loop fail");

            for (uint256 i = 0; i < loops; i++) {
                IAiCasso( AiCassoNFT ).purchase{value: 0.10 ether}(10);
            }

            if (other > 0) {
                IAiCasso( AiCassoNFT ).purchase{value: other * 0.01 ether}(other);
            }

        }

    }


    function recovery() external {
        uint256 numberOfTokens = to_recovered[msg.sender];
        require(numberOfTokens > 0);
        require(IERC721( AiCassoNFT ).balanceOf(address(this)) >= numberOfTokens, "error purchase tokens");

        to_recovered[msg.sender] = 0;

        uint[] memory _tokenIds = new uint[](numberOfTokens);
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _tokenIds[i] = IERC721Enumerable( AiCassoNFT ).tokenOfOwnerByIndex(msg.sender, i);
        }

        for (uint256 i = 0; i < numberOfTokens; i++) {
            IERC721( AiCassoNFT ).safeTransferFrom(address(this), msg.sender, _tokenIds[i]);
        }
    }

    function deposit() external onlyOwner payable { }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function available(address user) external view returns (uint256) {
        return IAiCassoNFTStaking( AiCassoNFTStaking ).balanceOf(user) - recovered[user];
    }

    function availableUnStake(address user) external view returns (uint256) {
        return to_recovered[user];
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return _ERC721_RECEIVED;
    }
}