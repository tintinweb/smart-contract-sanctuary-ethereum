/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// File: contracts\interface\IAdapter.sol

pragma solidity ^0.8.2;

interface IAdapter {

    function getByteCodeERC20(address nftContract, string memory method, address airDropContract, address account, uint256 tokenId) external returns(bytes memory);

    function getByteCodeERC721(address nftContract, string memory method, address airDropContract, address account, uint256 tokenId) external returns(bytes memory);

    function getByteCodeERC1155(address nftContract, string memory method, address airDropContract, address account, uint256 tokenId) external returns(bytes memory);

}

// File: contracts\airdropAdapter\Adapter.sol

pragma solidity ^0.8.2;


contract APEAdapter is IAdapter{

    address constant public Azuki = address(0xED5AF388653567Af2F388E6224dC7C4b3241C544);
    address constant public Doodles = address(0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e);

    function getByteCodeERC20(address nftContract, string memory method, address airDropContract, address account, uint256 tokenId) external pure override returns(bytes memory bytecode){
        bytecode = abi.encodeWithSignature(method);
        return bytecode;
    }

    function getByteCodeERC721(address nftContract, string memory method, address airDropContract, address account, uint256 tokenId) external pure override returns(bytes memory bytecode){
        if(nftContract == Azuki){
            uint256[] memory azukiTokenIds = new uint256[](1);
            azukiTokenIds[0] = tokenId;
            bytecode = abi.encodeWithSignature(method, azukiTokenIds);
        }else{
            bytecode = abi.encodeWithSignature(method);
        }
        return bytecode;
    }

    function getByteCodeERC1155(address nftContract, string memory method, address airDropContract, address account, uint256 tokenId) external pure override returns(bytes memory bytecode){
        return bytecode;
    }
}