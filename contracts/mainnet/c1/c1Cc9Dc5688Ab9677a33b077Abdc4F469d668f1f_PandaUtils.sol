pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface ERC721 {
    function balanceOf(address) external view returns (uint);

    function ownerOf(uint) external view returns (address);

    function send(uint16 _dstChainId, bytes calldata _toAddress, uint _tokenId, address _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;
}

contract PandaUtils {
    ERC721 public pandas;

    constructor(ERC721 _pandas) {
        pandas = _pandas;
    }

    function viewBalance(address nft, address holder) external view returns (uint) {
        return ERC721(nft).balanceOf(holder);
    }

    function sendBatch(uint16 _dstChainId, bytes calldata _toAddress, uint[] memory _tokenIds, address _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable {
        uint msgVal = msg.value / _tokenIds.length;
        for (uint i = 0; i < _tokenIds.length; i++) {
            require(pandas.ownerOf(_tokenIds[i]) == msg.sender, "caller is not the owner");
            pandas.send{value: msgVal}(_dstChainId, _toAddress, _tokenIds[i], _refundAddress, _zroPaymentAddress, _adapterParams);
        }
    }

    //if collection size is too large. receiving context deadline exceeded (ie. arbitrum)
    function viewOwnedIdsBatch(address nft, address holder, uint startTokenId, uint endTokenId) external view returns (uint[] memory returnData) {
        uint balance = ERC721(nft).balanceOf(holder);
        returnData = new uint[](balance);
        uint pos = 0;
        for (uint i = startTokenId; i <= endTokenId; i++) {
            try ERC721(nft).ownerOf(i) returns (address owner) {
                if (owner == holder) {
                    returnData[pos] = i;
                    pos++;
                }
                if (pos >= balance) {
                    i = endTokenId + 1;
                }
            } catch {}
        }
    }

    function viewOwnedIds(address nft, address holder, uint supply) external view returns (uint[] memory returnData) {
        uint balance = ERC721(nft).balanceOf(holder);
        returnData = new uint[](balance);
        uint pos = 0;
        for (uint i = 0; i < supply; i++) {
            try ERC721(nft).ownerOf(i) returns (address owner) {
                if (owner == holder) {
                    returnData[pos] = i;
                    pos++;
                }
                if (pos >= balance) {
                    i = supply;
                }
            } catch {}
        }
    }
}