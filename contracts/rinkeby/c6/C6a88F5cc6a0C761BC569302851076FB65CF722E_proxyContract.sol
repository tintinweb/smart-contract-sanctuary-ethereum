/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// 0.00122371 RinkebyETH
contract proxyContract {

    struct request {
        address _address;
        bytes _callData;
    }

    struct request2 {
        address _address;
        address _owner;
    }

    // balanceOf() -> tokenOfOwnerByIndex() -> tokenURI()
    function getNFTsByOwner(request2 memory reqs) public view returns (string[] memory) {
        bytes memory a = abi.encodeWithSignature("balanceOf(address)",reqs._owner);
        // bytes memory a = abi.encodeWithSignature("name()");
        (bool _success2, bytes memory data) = (reqs._address).staticcall(a);
        uint256 amount = abi.decode(data, (uint256));

        string[] memory results = new string[](amount);
        for (uint256 i = 0; i < amount; ++i) {

            a = abi.encodeWithSignature("tokenOfOwnerByIndex(address,uint256)",reqs._owner,i);
            (bool _success2, bytes memory data) = (reqs._address).staticcall(a);
            uint256 tokenId = abi.decode(data, (uint256));

            a = abi.encodeWithSignature("tokenURI(uint256)",tokenId);
            (bool _success3, bytes memory data3) = (reqs._address).staticcall(a);
            string memory tokenURI = abi.decode(data3, (string));

            results[i] = (tokenURI);

        }

        return results;
    }

    // 721
    // name() = abi.encodeWithSelector(bytes4(keccak256("name()"))) = 0x06fdde03
    // symbol() = abi.encodeWithSelector(bytes4(keccak256("symbol()"))) = 0x95d89b41
    // ownerOf(uint256)
    // tokenURI(uint256)
    // balanceOf(uint256)
    // totalSupply() = abi.encodeWithSelector(bytes4(keccak256("totalSupply()"))) = 0x18160ddd
    // tokenOfOwnerByIndex(address,uint256)
    // tokenByIndex(uint256)

    // 1155
    // balanceOf(address,uint256)
    // balanceOfBatch(address[],uint256[]) 
    // uri(uint256) 

    function callBatch(request[] memory reqs) public view returns (bytes[] memory) {

        uint256 totalRequests = reqs.length;
        bytes[] memory results = new bytes[](totalRequests);

        for (uint256 i = 0; i < totalRequests; ++i) {

            address destination = (reqs[i])._address;
            bytes memory callData = reqs[i]._callData;
        
            (bool _success2, bytes memory data) = destination.staticcall(callData);
            if (_success2) {
                results[i] = data;
            }else{
                results[i] = "";
            }
        }
        return results;
    }
}